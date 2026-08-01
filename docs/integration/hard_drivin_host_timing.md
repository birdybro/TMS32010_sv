# Hard Drivin' Driver Sound 68000 host-cycle timing

## Scope

This document transcribes the A044427 Rev-A logic that turns the local sound
68000 address strobe into `RVA`, `/DTACK`, and the held active-low `/RVAS`
selection window. It also traces the `/RVF` high-address qualification that
was omitted from the earlier low-I/O summaries. It defines the electrical
behavior a future FPGA host bridge must preserve; it does not yet add a raw
68000-pin adapter or choose a clock-domain-crossing implementation.

The board drawing is authoritative for wiring. Motorola's M68000 manual is
used only to interpret the processor bus states and sampling edges. Atari's
operator manual supplies diagnostic-software evidence, not logic timing
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets 1-3 of 10,
PDF pp. 1-6; motorola-m68000-users-manual-ninth, §§4.1.1, 5.7, 5.8, and the
MC68000 timing table on printed pp. 10-24 through 10-26].

## Clock and pull-up context

The local MC68000 at `65P` receives the board `8MHZ` net on its clock pin.
The same net clocks the second half of F74 `40R`; an F04 inversion of that net
clocks F74 `50S` on each falling `8MHZ` edge. `PR3`, `PR4`, and `PR5` are
individual 1 kOhm pull-up nets from sheet 1, not board-reset phases. Thus the
three F74 halves in this path have no board `/RESET` connection
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets 1-3 of 10,
PDF pp. 1-6]. **Confidence: VERIFIED_PRIMARY.**

The lack of a clear input means physical power-up state must not be inferred
from a future deterministic FPGA initialization. A bridge may initialize to
the idle state as an explicit platform convention, but must document that
divergence and must not call it measured board behavior.

## Pin-level logic transcription

The following equations describe normal operation with the `PR3`-`PR5`
pull-ups high. `AS` below is the positive form made by inverting the
processor's active-low `/AS` pin.

| net/state | A044427 implementation | logical behavior |
|---|---|---|
| `as_seen` | first half of F74 `40R`; `D=PR4=1`, rising-edge clock=`AS`, active-low clear=`/RVA` | `/AS` assertion sets it; the later `RVA` assertion clears it |
| `RVA` | second half of F74 `40R`; `D=as_seen`, rising-edge clock=`8MHZ` | one complete 8 MHz period beginning at the first rising edge after `/AS` asserts |
| `/VPA` | LS20 `70R` from `FC2`, `FC1`, `FC0`, and `AS` | low only for an asserted CPU-space access with `FC2:FC0=111` |
| `/DTACK` | LS20 `70R` from two pulled-high `PR5` inputs, `/VPA`, and `RVA` | `not (/VPA and RVA)` |
| `dtack_seen` | F74 `50S`; `D=/DTACK`, clocked by inverted `8MHZ` | samples `/DTACK` on each falling 8 MHz edge |
| `/RVAS` | positive AND, LS08 `10S`, from `dtack_seen` and `/RVA` | active low from `RVA` assertion until the falling-edge sample after `RVA` deasserts |
| `RVAS` | F04 `30S` inversion of `/RVAS` | active-high complement used elsewhere on the board |
| `/RWS` | ALS32 `30R` OR of `/RVAS` and `RWN` | active low only for a write during the `/RVAS` interval |
| `/WEU` | ALS32 `30R` OR of `/UDS` and `/RWS` | upper-byte write enable |
| `/WEL` | ALS32 `30R` OR of `/LDS` and `/RWS` | lower-byte write enable |

The component reference `LS08` is important: the drawing uses a
De-Morgan/active-low gate symbol, but the populated part is a positive AND.
Therefore the idle values `dtack_seen=1` and `/RVA=1` produce `/RVAS=1`, not
an asserted select. **Confidence: VERIFIED_PRIMARY for the wiring and Boolean
functions.** Propagation delays are deliberately excluded from these Boolean
equations.

## `/RVF` address qualification

LS138 `30P` is enabled by `A23=1`, `/AS=0`, and a grounded second active-low
enable. It decodes `A16:A14`; its active-low Y4 output is `/RVF`. Thus `/RVF`
is active when:

```text
/AS = 0, A23 = 1, and A16:A14 = 3'b100
```

Address bits `A22:A17` are not inputs to this decoder, so the physical board
has aliases beyond the conventional firmware address. This fact must remain
visible in a pin-compatible bridge even if a higher-level integration wrapper
chooses a narrower canonical range.

The low-I/O LS138 `30N` has three enables: pulled-high `PR3` on G1, `/RVF` on
G2A, and `/RVAS` on G2B. It is therefore incorrect to qualify its outputs from
`/RVAS` alone. Its select inputs are the double-inverted `RWNB` value followed
by `A13` and `A12`, yielding:

| `RWN` | `A13:A12` | active output |
|---:|---:|---|
| 0 | `00` | `/SOUNDWR` |
| 0 | `01` | `/LATCHES` |
| 0 | `10` | `/SPEECH` |
| 0 | `11` | `/IRQCLR` |
| 1 | `00` | `/SOUNDRD` |
| 1 | `01` | `/320PORT` |
| 1 | `10` | `/SWITCHES` |
| 1 | `11` | `/READSTAT` |

[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 3 of 10,
zones D5-D6 through B1-B6, PDF pp. 5-6; ti-sn74ls138-datasheet, function
table and selected-output behavior]. **Confidence: VERIFIED_PRIMARY.**

## Normal zero-wait read timeline

Motorola divides a standard MC68000 cycle into eight half-clock states. `/AS`
asserts after the rising edge entering S2; `/DTACK` is first accepted at the
falling edge at the end of S4; read data is latched at the falling edge
entering S7. Combining those primary-defined processor edges with A044427
produces this logical sequence:

| processor boundary | board transition | externally relevant result |
|---|---|---|
| rising edge entering S2 | the MC68000 begins asserting `/AS`; F04 `30S` then clocks `as_seen=1` | address and read strobes remain stable |
| falling edge entering S3 | no F74 state needed by the decode changes | no select yet |
| rising edge entering S4 | F74 `40R` samples `as_seen=1`, asserts `RVA`, and asynchronously clears `as_seen` through `/RVA` | `/DTACK` asserts for a non-CPU-space access; `/RVAS` asserts and the qualified target begins driving read data |
| falling edge entering S5 | the MC68000 recognizes `/DTACK`; F74 `50S` samples `/DTACK=0` | `dtack_seen=0` keeps `/RVAS` asserted after the `RVA` pulse |
| rising edge entering S6 | F74 `40R` samples cleared `as_seen=0`, deasserting `RVA` and `/DTACK` | `/RVAS` remains asserted because `dtack_seen=0` |
| falling edge entering S7 | the MC68000 latches read data and begins negating `/AS` and `/UDS`/`/LDS`; F74 `50S` samples `/DTACK=1` | `/RVAS` deasserts after the sampling edge, ending the read-target drive interval |

This explains why A044427 has both `RVA` and the separate `50S` hold stage:
the short `RVA` pulse produces a timely acknowledgement, while `/RVAS`
continues through the later read-data sampling edge. The same held interval
feeds write decode; `/WEU` and `/WEL` additionally respect `/UDS` and `/LDS`.
**Confidence: VERIFIED_PRIMARY for the edge relationships and bus-state
definitions; INFERRED from their composition for the named zero-wait intent.**

## No board-level wait-state retry

The synchronizer has no READY input. Once `RVA` asserts, `/RVA` clears
`as_seen`; after the following rising edge, `RVA` cannot reassert merely
because the processor continues holding `/AS` low. Motorola specifies that a
missed `/DTACK` setup at the S4 sampling edge inserts wait states, but A044427
does not generate another acknowledgement pulse during that held transaction.
The board logic therefore depends on the original electrical path meeting the
zero-wait sample. A future FPGA bridge must have read data ready for the fixed
S7 boundary and must not add arbitrary callback backpressure while describing
itself as faithful A044427 timing.

The MC68000 table specifies a 5 ns asynchronous-input setup at the relevant
grades and permits clock-relative `/DTACK` deassertion, but this repository has
not yet closed the complete F04/F74/LS20/LS08 propagation, loading, voltage,
and board-trace budget. The logical sequence is qualified; its nanosecond
margin remains `OQ-033`. **Confidence: UNKNOWN for complete electrical timing
closure.**

## CPU-space cycles

For `FC2:FC0=111` with `/AS` active, `/VPA` goes low and prevents `/DTACK`
from asserting even while `RVA` pulses. Motorola defines VPA as the M6800
peripheral/interrupt-acknowledge path sampled at S4. This is separate from the
ordinary board acknowledgement described above. A future adapter must not
assert its normal `/DTACK` merely because the `RVA` sequencer is active.
**Confidence: VERIFIED_PRIMARY.**

## FPGA implementation boundary

A faithful portable adapter may represent the two physical clock edges with
explicit `host_8mhz_rise_enable` and `host_8mhz_fall_enable` events on a faster
FPGA clock. It must also:

- represent `/AS` assertion as a distinct event after the S2 rising edge;
- reject or explicitly define coincident assertion/rising-edge scheduling;
- preserve the `RVA`, `dtack_seen`, and `/RVAS` sequence above;
- qualify low-I/O selection with both `/RVF` and `/RVAS`;
- hold selected read data through the S7 falling edge;
- emit write/read side-effect completion only at the selected strobe's
  trailing edge;
- keep any deterministic idle initialization labeled as an FPGA convention;
- provide no arbitrary ready/wait input in a board-faithful mode; and
- leave incomplete read lanes under the mask/open-bus policy of `OQ-030`.

If a MiSTer system uses a separately clocked 68000 core, the boundary requires
an explicit CDC or a common-clock enable contract. This document does not
choose between them.

## Standalone logical adapter

`rtl/wrappers/hard_drivin_sound_host_timing.sv` implements the qualified
same-clock boundary. It accepts mutually exclusive 8 MHz rising/falling
enables plus distinct `/AS` assertion and deassertion events. On assertion it
captures the complete stable `A23:A1`, function code, `RWN`, `/UDS`, and
`/LDS`. It then exposes:

- `RVA`, `/VPA`, `/DTACK`, `/RVAS`, and `/RVF` logical levels;
- global `/RWS`, `/WEU`, and `/WEL` write qualification;
- exact active-high one-hot LS138 `30N` target visibility;
- read/write selection and `A13:A12` quadrant state;
- pre-edge S7 completion events for same-clock stateful consumers plus
  one-clock registered ordinary/read/write trace pulses;
- retained `/UDS` and `/LDS` state for completion policy;
- the full captured address so high aliases are not discarded by the timing
  boundary; and
- the captured R/W direction so downstream memory decode does not consult a
  live bus input after `/AS` assertion.

The module has no READY input. A normal completion occurs only after F74 `50S`
has sampled low `/DTACK`, `RVA` has deasserted, and the following falling-edge
enable represents S7. CPU-space cycles hold `/VPA` active and never emit that
ordinary completion. `/AS` deassertion remains a distinct event so the model
can represent processor propagation after the S7 edge and the longer external
VPA-owned sequence. `initialize_i` chooses idle `RVA=0`,
`dtack_seen=1`, and no active cycle solely as a deterministic FPGA convention.
**Confidence: VERIFIED_SIMULATION for this logical same-clock adaptation;
not physical power-up or nanosecond timing evidence.**

## Opt-in board-top composition

`hard_drivin_sound_mister` instantiates the timing adapter behind
`use_host_timing_i`. With that input false, every pre-existing explicit
low-read, local-mailbox, host-control, and IRQ-clear callback remains the
selected interface. With it true, the board top instead:

- drives the masked low-read selector from the qualified S4-through-S7 read
  target and raw `A13:A12` quadrant;
- clears `MAINFLAG` on the S7 `/SOUNDRD` completion event;
- captures local-host write data and sets `SOUNDFLAG` on an S7 `/SOUNDWR`
  event only when both `/UDS` and `/LDS` are active;
- routes S7 `/LATCHES` to the existing address-encoded LS259 adapter using
  captured `A4:A1`, independently of host data and byte strobes;
- routes S7 `/IRQCLR` to the existing 320IRQ clear callback; and
- exposes an S7 `/SPEECH` trace pulse without assigning an unimplemented
  speech-device side effect.

The full-word `/SOUNDWR` restriction is an explicit FPGA interface policy at
the `OQ-031` boundary. A partial-byte access emits
`host_timing_partial_sound_write_o` and cannot silently enter the whole-word
mailbox callback; this does not claim that the physical LS374 pair ignores or
merges such a cycle. The main-system side of both mailboxes remains on its
separate external callbacks. Read data remains accompanied by exact driven
and valid masks, so the bridge still assigns no `OQ-030` open-bus value.
**Confidence: VERIFIED_SIMULATION for same-clock composition; UNKNOWN for
raw-pin CDC, partial-byte physical behavior, and electrical timing.**

## Verification and synthesis

`tb_hard_drivin_sound_host_timing` exhausts all 64 combinations of physically
ignored `A22:A17`, both `A23` values, all eight `A16:A14` selections, both
read/write directions, and all four `A13:A12` quadrants: 8,192 complete
ordinary transactions. Every transaction checks `/RVF`, exact one-hot target
order, S4 acknowledgement/select assertion, S5 hold capture, S6 `RVA` and
`/DTACK` release with continued `/RVAS`, S7 completion/release, and qualified
read/write pulses. Directed cases additionally check all `/UDS`/`/LDS`
combinations, CPU-space `/VPA` suppression, delayed `/AS` release, absence of
a held-`/AS` retry, and deterministic mid-cycle FPGA reinitialization.

`formal/hard_drivin_sound_host_timing.sby` adds a 16-step bounded check with
arbitrary captured address/control values and arbitrary stalls. Its explicit
same-clock assumptions require mutually exclusive alternating phase edges,
idle-only `/AS` assertion, ordinary release at/after completion, and VPA
release only after the complete `RVA`/falling-edge settle sequence. Assertions
check exact external decode/strobe/completion equations, captured-state
stability, VPA suppression, registered pulse delay, and absence of a held-`/AS`
retry. Whole-word read/write covers reach step 8; the fully settled VPA cover
reaches step 9. This does not prove raw-pin CDC or electrical timing.

Twenty-four retained assertions cover legal event combinations, exact Boolean
outputs and pre-edge completion events, target uniqueness, state capture,
rising/falling transition state, ordinary completion qualification, and
`/AS` release ownership. Yosys 0.67+111 reports 142 abstract cells, 24 checks,
no inferred latch or memory,
and zero structural problems. This is pre-technology portable synthesis, not
a Cyclone V fit or `OQ-033` electrical closure.

The integrated board regression runs all four timed read quadrants and all
four timed write quadrants. It checks masked read data through S6, exact S7
`/SOUNDRD`, whole-word `/SOUNDWR`, `/LATCHES`, and `/IRQCLR` effects,
external-callback isolation while opted in, explicit partial-mailbox
rejection, and visible side-effect-free `/SPEECH` completion. It now also
checks fixed-cycle ROM/local-SRAM callbacks, byte-specific local-SRAM commits,
the optional lane-valid SRAM's internal/external callback isolation,
lower-Y5 program-RAM storage, upper-Y5 direct-I/O S6 timing and isolation, and
Y6 communication-RAM storage under CRAMEN. Integrated Yosys retains six
memories and reports 3,809 abstract cells, 406 checks, and zero structural
problems.

`formal/hard_drivin_sound_host_routing.sby` adds a 12-step bounded composition
check over the complete current board hierarchy with DSP execution paused.
One symbolic transaction selects `/SOUNDRD`, complete or partial
`/SOUNDWR`, `/LATCHES`, `/SPEECH`, or `/IRQCLR`; word data, LS259 address
bits, and the partial-write byte orientation remain symbolic, while
contradictory external callback sentinels prove timing-mode isolation.
Assertions cover exact pre-completion read data/masks,
S7 mailbox effects, partial-write rejection, address-coded latch state,
side-effect-free speech visibility, IRQ-clear routing, and no early state
change. Seven covers span all six classes plus both partial-byte orientations
and reach solver step 10 after the registered effects are visible. This fixed
common-clock event sequence does not prove raw-pin CDC,
arbitrary event spacing, physical collision/byte behavior, or electrical
timing.

## Diagnostic-software evidence

Atari TM-327's Sound Board menu says the local 68000 tests the program ROM,
program RAM, and TMS32010 program RAM, while the TMS32010 tests communication
RAM. It also lists synthetic `320` exercises for a sine sweep, tune, IRQ,
DAC ramp, walking DAC ones, and increasing sound-block latch addresses
[atari-hard-drivin-manual-tm327-third, printed pp. 2-18 through 2-20, PDF
pp. 31-33]. These are valuable future integration-test targets and corroborate
the documented ownership split. They do not specify `/DTACK` or `/RVAS`
timing. **Confidence: VERIFIED_PRIMARY for the published diagnostic roles;
not timing evidence.**
