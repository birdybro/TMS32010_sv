# Hard Drivin' Driver Sound main/sound mailboxes

## Scope

This document traces the two 16-bit word latches and their pending flags on
Atari drawing A044427 Rev A. They exchange data between the external main
system and the board's local 68000 sound CPU; they are not TMS32010 registers.
The TMS port-3 latch is a separate path documented in
`hard_drivin_host_reads.md`.

The implemented boundary accepts same-clock transaction-completion pulses. It
does not yet implement the main-system bridge, local 68000 `/RVAS` decode,
DTACK, byte-lane policy, interrupt-level connection, or physical strobe width.

## Primary wiring

The two physical directions are symmetric
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 2 of 10,
PDF pp. 3–4; ti-sn74ls374-datasheet-sdls165b, description, pinout, and
positive-edge behavior, printed pp. 1–3]:

| direction | latch inputs | capture edge | read output | data reset |
|---|---|---|---|---|
| main system to sound CPU | `ED15:ED0` into LS374 `10L`/`10N` | trailing positive edge of active-low `/MAINWR` | `/SOUNDRD` enables all local `D15:D0` | none drawn |
| sound CPU to main system | local `D15:D0` into LS374 `20L`/`20N` | trailing positive edge of active-low `/SOUNDWR` | `/MAINRD` enables all `ED15:ED0` | none drawn |

Each write clocks a complete 16-bit word into two octal edge-triggered
latches. Neither data-latch pair has a clear or board-reset connection, so
board reset cannot qualify or clear its stored word. **Confidence:
VERIFIED_PRIMARY for the nominal whole-word wiring and absence of a reset
connection; UNKNOWN for physical power-up contents.**

The two halves of LS74 `20S` implement the handshake
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 2 of 10,
PDF pp. 3–4; ti-sn74ls74a-datasheet-sdls119, description and function table,
printed pp. 1–3]:

| flag | asynchronous set | synchronous clear | board reset |
|---|---|---|---|
| `MAINFLAG` | active-low `/MAINWR` drives preset | trailing edge of active-low `/SOUNDRD` clocks grounded D | active-low clear |
| `SOUNDFLAG` | active-low `/SOUNDWR` drives preset | trailing edge of active-low `/MAINRD` clocks grounded D | active-low clear |

Nominally, a write makes the associated flag high and the opposite-side read
makes it low. `/READSTAT` exposes raw `MAINFLAG` and `SOUNDFLAG` on local host
bits 15 and 14, respectively. `MAINFLAG` also participates in the local 68000
interrupt network; that interrupt adaptation remains outside this standalone
module. **Confidence: VERIFIED_PRIMARY for wiring, polarity, and nominal
sequence.**

## Conditions the drawing does not resolve

The LS74 data sheet does not establish a usable result for simultaneous
asynchronous preset and clear. It also does not define a priority when the
write-driven preset overlaps the positive read-clock edge that would clock
zero. A same-clock FPGA adapter can observe these as coincident completion
pulses even though their exact physical overlap depends on unrelated bus
timing.

`hard_drivin_sound_mailboxes` therefore captures the independently clocked
word but emits a zero flag carrier with flag validity false in either case:

- a direction's write and opposite-side read complete together; or
- a direction's write completes while board reset asserts the flag clear.

The module reports each condition on a separate conflict output. A later
nonconflicting write, read, or reset requalifies the affected flag. This is a
conservative digital interface policy, not a claim that physical Q becomes
zero. **Confidence: UNKNOWN for physical coincidence behavior;
VERIFIED_SIMULATION for the explicit invalid-state policy.**

The local sound-CPU decode clocks both LS374 devices with one `/SOUNDWR` and
does not draw UDS/LDS at this latch. `/MAINWR` enters through the board
connector, so its upstream byte qualification is not established here.
Pinned MAME merges local sound-CPU byte writes, which is convenient software
behavior but not proof of the latch pins. `OQ-031` and `SC-031` preserve this
boundary. The FPGA callback is intentionally whole-word only.

## Secondary behavioral comparison

Pinned MAME independently corroborates the nominal software handshake:

- `hd68k_snd_data_w` schedules a complete main-to-sound word and sets
  `m_mainflag`;
- `hdsnd68k_data_r` returns that word and clears `m_mainflag`;
- `hdsnd68k_data_w` updates the sound-to-main word and sets `m_soundflag`;
- `hd68k_snd_data_r` returns that word and clears `m_soundflag`; and
- the modeled board reset clears both flags.

It models logical handler calls rather than LS374/LS74 strobe edges and uses
`COMBINE_DATA` for a local sound-CPU write
[mame-harddriv-audio-030fefc, `hd68k_snd_data_r`, `delayed_68k_w`,
`hd68k_snd_data_w`, `hdsnd68k_data_r`, `hdsnd68k_data_w`, and
`hd68k_snd_reset_w`]. **Confidence: CORROBORATED for the ordinary
software-visible handshake; not physical timing evidence.**

## FPGA boundary

`rtl/wrappers/hard_drivin_sound_mailboxes.sv` exposes each direction as:

- a whole-word write-completion pulse and 16-bit write data;
- an opposite-side read-completion pulse;
- retained 16-bit data plus independent data validity;
- retained pending flag plus independent flag validity; and
- a combinational flag-conflict indication.

`initialize_i` creates deterministic zero carriers with all validity false.
Board reset clears and qualifies the flags but deliberately preserves both
data latches.

## Board-top integration

`hard_drivin_sound_mister` instantiates the standalone adapter behind four
explicit decoded-completion callbacks: main-system write/read and local
sound-CPU write/read. Each write callback accepts one complete word; each read
callback clears only the opposite-side pending flag. The top exports both
retained words, both data-valid bits, both flags, both flag-valid bits, and
both conflict indications without assigning byte-lane or collision behavior.

The integrated flags directly feed `hard_drivin_sound_read_status`, so raw
`MAINFLAG` and `SOUNDFLAG` appear only on status bits 15 and 14 when their
individual validity is true. `SOUND.TEST` and `/TIRDY` remain external raw
inputs. No callback is described as `/RVAS`, UDS/LDS, DTACK, or a physical
strobe edge; the complete 68000 and main-system bridges remain outside the
top. **Confidence: VERIFIED_SIMULATION for the same-clock integration;
UNKNOWN for the physical bus boundaries retained by `OQ-031`.**

## Verification and synthesis

`tb_hard_drivin_sound_mailboxes` exhausts all 65,536 words in both directions,
giving 131,072 nominal write/read transitions. It checks full-word capture,
flag set and read-clear, data persistence, board-reset independence,
deterministic initialization, both simultaneous write/read conflicts, both
reset/write conflicts, and later flag requalification. Ten retained RTL checks
independently cover exact data/state transitions and the rule that an
invalid flag carrier cannot be high.

Standalone Yosys reports 259 abstract cells, ten retained checks, no memory or
latch, and zero structural problems. This is a pre-technology synthesis smoke,
not 68000 bus timing or a Cyclone V fit.

The integrated board regression additionally verifies nominal traffic in
both directions, exact flag-to-status mapping, both coincident write/read
conflicts, independent flag invalidity and requalification, raw peripheral
validity masks, and board-reset flag clear with both word latches retained.
The complete board hierarchy reports 2,644 abstract cells, 194 retained
checks, three memories, and zero structural problems. It is not a 68000 bus
or Cyclone V timing qualification.
