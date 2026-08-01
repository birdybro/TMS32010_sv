# Driver Sound local-processor reset interlock

This note defines an FPGA-only release interlock for the optional lane-valid
local SRAM. It does not change the portable TMS32010 reset contract, replace
the board's `/320RES` latch, or claim that physical 6264 SRAM has reset state.

## Physical reset and halt sources

A044427 Rev A drives the local MC68000 RESET pin 18 from the board `/RESET`
path. Its HALT pin 17 is a separate pulled-up, open-collector path associated
with the sound-control logic; the two pins must not be collapsed into one
architectural board net [atari-driver-sound-board-schematic, drawing A044427
Rev A, sheet 2 of 10, PDF pp. 3-4]. Motorola requires RESET and HALT to be
asserted together for a proper external MC68000 reset
[motorola-m68000-users-manual-ninth, §5.5, printed p. 5-29, PDF p. 75]. **Confidence:
VERIFIED_PRIMARY.**

The existing board wrapper already receives `board_reset_n_i`. It now also
accepts `local_processor_halt_n_i` as an explicit callback for the independent
HALT circuit. Neither input is synthesized from a guessed firmware or cabinet
state.

## FPGA policy

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

RESET and HALT remain separately observable after the policy gate. A raw
HALT-only request does not become a reset, and a raw reset does not invent the
board's HALT state. A future local-MC68000 wrapper must still supply the
qualified HALT callback, obey Motorola's initial/subsequent pulse-duration
requirements, and synchronize deassertion if it introduces another clock
domain. Pin-level propagation and the complete physical HALT circuit remain
outside this same-clock wrapper under `OQ-035`.

## Evidence

The standalone test exhausts all 32 combinations of initialization, raw RESET,
raw HALT, storage selection, and readiness. The board regression additionally
shows initialization clamping both outputs, external-storage pass-through,
independent raw RESET/HALT assertions, internal-storage blocking during the
real sequential scrub, and release only after validity address `0x1fff`
completes. The one-step formal harness proves
the complete Boolean contract and reaches external pass-through, scrub block,
ready release, and raw reset/halt assertion covers.

Standalone Yosys reports 13 cells and seven retained checks with no storage,
latch, or structural problem. The board hierarchy retains six memories and
reports 3,603 abstract cells and 384 checks before technology mapping. Neither
result is an MC68000 reset-duration, raw-pin CDC, Cyclone V fit, or TimeQuest
qualification.
