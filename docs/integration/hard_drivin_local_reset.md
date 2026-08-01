# Driver Sound local-processor reset source and interlock

This note separates the populated A044427 Rev-A reset source from an FPGA-only
release interlock for the optional lane-valid local SRAM. Neither block changes
the portable TMS32010 reset contract or the board's independent `/320RES` DSP
control.

## Physical reset and halt sources

A044427 uses separate 7406 open-collector devices and separate 4.7 kΩ pull-ups
for local MC68000 HALT pin 17 and RESET pin 18. Both 7406 inputs are, however,
driven by the same LS00 output. Stable Boolean behavior is therefore identical
while the two physical pin paths remain separately observable:

```text
ls123_a_n       = /MRES && /SRES
one_shot_active = !LS123_/Q
RESET_n         = SOUND.RESET_n && LS123_/Q
HALT_n          = SOUND.RESET_n && LS123_/Q
```

`/MRES` and decoded `/SRES` enter LS08 `10S`; its output drives active-low A
of the first LS123 half at `100N`, while B and asynchronous clear use pulled-
high `PR3`. A falling A edge therefore starts Q high and `/Q` low; a later
falling edge retriggers it only after the device's documented trigger-inhibit
interval. C43 is 10 µF and R79 is 47 kΩ. The `/Q` output and pulled-up
active-low `SOUND.RESET` test node enter LS00 `40S`; two 7406 sections then
drive the separate HALT and RESET branches [atari-driver-sound-board-schematic,
drawing A044427 Rev A, sheet 2 of 10, PDF pp. 3-4]. TI documents the
active-low-A, high-B trigger, retriggering, overriding clear, and for
`Cext >= 1 µF` the typical equation `tw = 0.33 * RT * Cext`
[ti-sn74ls123-datasheet-sdls043, printed pp. 1-2 and 8-9]. Substitution gives
about 155.1 ms nominal. TI also states that subsequent pulses beginning before
`0.22 * Cext(pF)` ns after the first trigger are ignored; 10 µF therefore
implies about 2.2 ms of typical trigger inhibit
[ti-sn74ls123-datasheet-sdls043, printed p. 2]. These are not guaranteed board
intervals: the TI equation is typical application data, and installed
capacitor tolerance, aging, supply/temperature variation, and propagation
delay have not been qualified. **Confidence: VERIFIED_PRIMARY for
connectivity, Boolean polarity, and nominal calculation; UNKNOWN for a
production-board pulse-width range and power-up transient.**

Motorola requires RESET and HALT to be asserted together for a proper external
MC68000 reset and specifies separate minimum durations for initial and later
reset [motorola-m68000-users-manual-ninth, §5.5, printed p. 5-29, PDF p. 75].
The common board logic satisfies the paired stable-state requirement, while
the two output devices and pins remain distinct electrical paths. Pinned MAME
instead pulses only the local CPU RESET line immediately from
`hd68k_snd_reset_w`; it models neither the LS123 interval nor the paired HALT
path [mame-harddriv-audio-030fefc, `hd68k_snd_reset_w`]. This secondary timing
abstraction is isolated as `SC-035`.

## Upstream `/MRES` and `/SRES`

SP-327 sheet 7 shows main-board LS244 `210N` permanently enabled. It copies
system `/RESET` without inversion to expansion-bus `/MRES` at J7-49. The same
sheet copies `/RVAS` to `/ERVAS` at J7-28, `/EXTBUS` to `/EXTB` at J7-23, the
main read/write direction, and address bits through A20. SP-327 sheet 4 makes
`/EXTBUS` the active-low LS138 Y4 output for `/AS=0` and `A23:A21=100` and
generates `/RVAS` through its 8 MHz bus-control flip-flop chain
[atari-hard-drivin-schematic-package-sp327, sheets 4 and 7, PDF pp. 5 and 8].
The package shows `/RESET` as a main-CPU input and RUN-indicator input, but the
reviewed sheets do not establish its original driving source. That remaining
system-level origin is `OQ-036`.

A044427 sheet 1 reconstructs `/SRES` with LS32 gates and LS138 `20P`:

```text
/EXTBUS = 0 when /AS=0 and A23:A21=100
G2B     = /EXTB OR /ERVAS
G2A     = EA20 OR EA19 OR EA17 OR EA16
G1      = EA18
C:B:A   = main_read_not_write : EA15 : EA14
/SRES   = Y3
```

Therefore stable `/SRES` assertion requires a write, `/AS=0`, `/RVAS=0`, and
`A23:A14=1000010011`. Address bits A13:A0 and both byte strobes are absent
from the logic cone. The physical byte-address mirror is consequently
`0x84c000` through `0x84ffff`, not just one canonical word
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 1 of 10,
PDF pp. 1-2; ti-sn74ls138-datasheet, printed pp. 1-2]. Pinned MAME installs
`hd68k_snd_reset_w` only at `0x84c000..0x84c001`; `SC-036` records this
secondary decode contraction.

`hard_drivin_main_sound_reset_decode` implements this storage-free
combinational boundary. Its address port contains only `A23:A14`, making the
physical lower-bit alias explicit. Raw `/AS`, `/RVAS`, address, and direction
must already obey a platform's same-clock or CDC policy; the block does not
reconstruct the main-board 8 MHz bus sequencer. **Confidence: VERIFIED_PRIMARY
for connectivity, address mirror, direction, and logical qualifiers;
VERIFIED_SIMULATION/FORMAL for the combinational RTL; UNKNOWN for propagation
margin, the original system `/RESET` source, and raw-pin CDC.**

## Digital one-shot boundary

`hard_drivin_sound_local_reset_source` reconstructs the verified logical
source without real-time or analog RTL. It:

- samples falling edges of `/MRES && /SRES` on `clk_i`;
- loads `MONOSTABLE_HOLD_TICKS` on an accepted trigger;
- loads `MONOSTABLE_RETRIGGER_INHIBIT_TICKS` concurrently, reports falling
  edges during that interval as ignored, and accepts a later falling edge only
  when the inhibit counter was already zero at the sampling edge;
- decrements only on explicit `hold_tick_i`, with no generated clock;
- combines the active interval with raw `SOUND.RESET_n`; and
- emits equal logical HALT and RESET requests plus hold/trigger diagnostics.

`initialize_i` seeds one full hold as an explicit deterministic FPGA startup
convention. Inputs and the tick must already be synchronous to `clk_i`; a
future pin-facing wrapper must add CDC logic. The parameters default to one
hold tick and one inhibit tick, not 155 ms and 2.2 ms. A platform must select
a tick period and counts whose products implement its documented nominal and
tolerance policy. Because this is a discrete model, a falling edge sampled on
the edge that consumes the final inhibit tick is conservatively ignored; the
next sampled falling edge is eligible. The standalone block is
not yet selected inside `hard_drivin_sound_mister`, because that top has no
qualified real-time tick or raw `/MRES`/`/SRES` CDC boundary. **Confidence:
VERIFIED_SIMULATION/FORMAL for the tick-domain reconstruction; implementation
convenience for deterministic startup; not analog or pin-timing equivalence.**

## FPGA storage-release policy

The physical SRAM pair has no READY input and no reset connection. The
optional `hard_drivin_sound_local_ram` therefore leaves its two data arrays
unreset and spends exactly 8,192 `clk_i` edges clearing only validity metadata.
If that storage is selected, a local processor must not start fixed-cycle Y7
accesses before the scrub finishes.

`hard_drivin_sound_local_reset_interlock` defines:

```text
platform_release_permitted =
  !initialize && (!use_internal_local_ram || local_ram_storage_ready)

local_processor_reset_n = board_reset_n && platform_release_permitted
local_processor_halt_n  = raw_halt_n   && platform_release_permitted
```

`local_processor_release_blocked` is true only when both raw RESET and HALT
sources request release but FPGA initialization or the selected internal-SRAM
scrub denies it. If external local storage is selected, its readiness is not
silently coupled to the internal metadata controller. **Confidence:
VERIFIED_SIMULATION for the FPGA policy; this is implementation convenience,
not physical-board behavior.**

The existing board wrapper continues to receive `board_reset_n_i` and
`local_processor_halt_n_i` separately. This keeps the physical pin paths
observable and permits external-board substitution even though the populated
Rev-A source drives them with the same stable logic. A future local-MC68000
wrapper may select the qualified common source, but must still obey the chosen
68000 core's reset interface and synchronize assertion/deassertion if it
introduces another clock domain. Pin-level propagation, RC tolerance, and
power-up behavior remain outside this same-clock wrapper under `OQ-035`.

## Evidence

The one-shot test covers deterministic startup, exact six-tick release,
paused tick retention, direct `SOUND.RESET`, `/MRES`, `/SRES`, held-low input,
an early ignored retrigger, and an accepted post-inhibit retrigger. A 10-step
BMC proves independent reference hold/inhibit counters and paired-output
equations; a 14-step cover run reaches release, both accepted trigger sources,
an ignored trigger, and direct test reset. Default-parameter Yosys reports 28
cells and seven retained checks with no memory, latch, or generated clock.

The main-side decode test exhausts all 1,024 values of `A23:A14` across all
eight `/AS`/`/RVAS`/direction combinations (8,192 cases), then checks the
canonical and top-mirror projections explicitly. A one-step proof covers an
asserted canonical write, read isolation, inactive `/RVAS`, and a nonexternal
address. Yosys reports 16 cells and four retained checks with no memory or
latch.

The interlock test exhausts all 32 combinations of initialization, raw RESET,
raw HALT, storage selection, and readiness. The board regression additionally
shows initialization clamping both outputs, external-storage pass-through,
independent raw RESET/HALT assertions, internal-storage blocking during the
real sequential scrub, and release only after validity address `0x1fff`
completes. The one-step formal harness proves the complete Boolean contract
and reaches external pass-through, scrub block, ready release, and raw
reset/halt assertion covers.

Interlock Yosys reports 13 cells and seven retained checks with no storage,
latch, or structural problem. The board hierarchy retains six memories and
reports 3,603 abstract cells and 384 checks before technology mapping. Neither
result, and neither one-shot result, is an MC68000 raw-pin CDC, production RC
tolerance, Cyclone V fit, or TimeQuest qualification.
