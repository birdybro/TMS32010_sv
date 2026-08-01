# Hard Drivin' Driver Sound 68000 host-control latch

## Scope

This document qualifies A044427 Rev-A LS259 `80R`, its low host-address
selection, and the immediately related `/IRQCLR` decode. It does not implement
the complete 68000 bus, `/RVAS` generation, DTACK timing, ROM/RAM map, byte
lanes, speech hardware, or firmware sequencing. The FPGA adapter accepts an
explicit decoded completion pulse so those unimplemented electrical details
remain outside its evidence boundary.

## Low host control decode

LS138 `30N` is enabled by `/RVAS`; its select inputs are `RWN`, `A13`, and
`A12`. The active-low outputs therefore select one read or write function in
each 4 KiB quadrant of the board's valid host-I/O region
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 3 of 10,
PDF pp. 5–6]:

| `RWN` | `A13:A12` | selected strobe |
|---:|---:|---|
| 0 | `00` | `/SOUNDWR` |
| 0 | `01` | `/LATCHES` |
| 0 | `10` | `/SPEECH` |
| 0 | `11` | `/IRQCLR` |
| 1 | `00` | `/SOUNDRD` |
| 1 | `01` | `/320PORT` |
| 1 | `10` | `/SWITCHES` |
| 1 | `11` | `/READSTAT` |

Thus `/LATCHES` is a host write decode and `/IRQCLR` is a distinct host write
decode. `/IRQCLR` does not modify LS259 `80R`; it clocks grounded D into the
separate 320IRQ LS74 as documented in `hard_drivin_sound_control.md`.
**Confidence: VERIFIED_PRIMARY.**

Pinned MAME independently maps these quadrants at `0xff0000` through
`0xff3fff` and uses separate latch-write and IRQ-clear handlers
[mame-harddriv-audio-030fefc, `driversnd_68k_map`,
`hdsnd68k_latches_w`, and `hdsnd68k_irqclr_w`]. This corroborates the
software-visible region assignment but is not host pin-timing evidence.

## Address-encoded LS259 write

Within a `/LATCHES` access, A044427 connects host `A3:A1` to LS259 select
inputs S2:S0 and connects host `A4` to D. Host data `D15:D0` does not enter the
latch. While active-low G is asserted, TI specifies that the selected output
follows D and all unselected outputs retain their previous states; returning G
inactive stores the selected value. Active-low CLR asynchronously drives all
outputs low [atari-driver-sound-board-schematic, drawing A044427 Rev A,
sheet 3 of 10, PDF pp. 5–6; ti-sn74ls259b-datasheet-sdls086, description and
function/latch-selection tables, printed pp. 1–2]. **Confidence:
VERIFIED_PRIMARY.**

The raw latch map is:

| output | net / drawn load | board-reset value |
|---:|---|---:|
| Q0 | `SPWR` | 0 |
| Q1 | `/SPRES` | 0 |
| Q2 | `SPRATE` | 0 |
| Q3 | `CRAMEN`; inverter also produces `/CRAMEN` | 0 |
| Q4 | `/320RES`; inverter also produces `320RES` | 0 |
| Q5 | no connected net found | 0 |
| Q6 | no connected net found | 0 |
| Q7 | resistor/LED sink path | 0 |

Board `/RESET` connects directly to CLR, so after a recognized reset all eight
raw Q values are known low. In particular, `CRAMEN=0` grants the DSP its
read-only communication-RAM path and `/320RES=0` asserts TMS32010 reset and
disables its program-RAM buffers. Before board reset or a write, physical
power-up values are not claimed.

Pinned MAME implements the same address-encoded write: low three word-offset
bits select Q and the next offset bit supplies the value; handler data is
ignored. Its Q3 callback represents CRAMEN. Its Q4 callback drives an inverted
DSP HALT line rather than the physical reset/buffer network, so `SC-020` still
governs program-RAM ownership and reset timing
[mame-harddriv-audio-030fefc, `hdsnd68k_latches_w`, `cram_enable_w`, and
LS259 device configuration].

## Standalone FPGA adapter

`rtl/wrappers/hard_drivin_sound_host_control.sv` accepts
`latch_write_commit_i` plus `latch_address_i={A4,A3,A2,A1}`. On that same-clock
completion it updates exactly Q selected by A3:A1 to A4. It exposes all eight
raw Q bits and a separate validity bit for each:

- `initialize_i` supplies deterministic FPGA zeros with validity clear;
- sampled `board_reset_n_i=0` clears all Q bits and qualifies every bit;
- a decoded write qualifies only the selected bit; and
- address/data changes without a completion have no effect.

This commit-pulse model deliberately does not reproduce the physical LS259's
level-sensitive interval or propagation delay. It is a same-clock integration
convention suitable for a later host bridge.

`hard_drivin_sound_mister` now instantiates the adapter behind
`use_host_control_i`. The default false setting preserves external
`dsp_reset_n_i` and `communication_host_enable_i` callbacks and treats them as
valid by contract. The opt-in setting selects raw Q4 and Q3 respectively and
exports validity for both selected controls. An invalid deterministic FPGA
initialization bit is therefore never silently promoted to known physical
state. `/IRQCLR` remains the distinct `host_irq_clear_commit_i` callback; the
LS259 write cannot clear `320IRQ`.

## Verification and synthesis

`tb_hard_drivin_sound_host_control` checks all eight selections with both A4
values, per-bit validity, uncommitted changes, complete alternating patterns,
board-reset qualification, and reset-over-write priority. Six retained RTL
checks assert selected-bit update, unselected-bit preservation, validity, and
reset behavior.

The board-top test uses opposite-valued external sentinels while opted in,
applies board reset, loads synthetic program and communication words under Q4
and Q3 ownership, hands both memories to the DSP, executes two instructions,
reasserts Q4 reset, and reads the preserved communication word back under Q3.
This verifies the selection and handoff convention, not a 68000 address or
DTACK waveform.

Yosys 0.67+111 reports 53 abstract cells, six retained checks, no memory or
latch, and zero structural problems. This is portable structural evidence,
not a Cyclone V fit, a physical LS259 timing model, or a complete 68000 bus.
