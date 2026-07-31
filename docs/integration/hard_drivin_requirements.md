# Atari Hard Drivin' Driver Sound Board requirements

## Qualification status

This is an initial schematic-led integration inventory. No copyrighted ROM is
included, and no game execution is yet qualified. Board facts are separated
from emulator observations and inferences.

## Board identity and processor

The reviewed document is Atari drawing A044427, Driver Sound schematic,
revision A title blocks, ten logical sheets split across twenty PDF pages.
Sheet 4 labels the DSP `TMS32010`, connects a 20 MHz crystal with two 10 pF
capacitors, and straps `MC/MP` for microprocessor operation
[atari-driver-sound-board-schematic, drawing A044427, sheet 4 of 10, PDF
pp. 7–8]. **Confidence: VERIFIED_PRIMARY.**

At 20 MHz input the TMS32010 machine cycle is nominally four input clocks, or
5 MHz/200 ns. This is inside the TMS32010-20's specified 48.78–150 ns
master-period envelope and does not create a board-level wait mechanism
[ti-tms32010-users-guide-spru001b, Appendix A data sheet, Clock
Characteristics and Timing, printed p. 11 (PDF p. 367)]. **Confidence:
VERIFIED_PRIMARY.**

## Memory and host path

The DSP exposes `TA0..TA11`, `TD0..TD15`, `/MEN`, `/DEN`, and `/TWE` to board
logic. The drawings show four 20-pin `8168D45`-labeled SRAM slices. Every
slice receives `RA0..RA11` and contributes four `TD` bits, establishing a
4K-by-16 asynchronous program RAM. Two LS244 pairs select either
`TA11..TA0` or host `A12..A1` onto `RA11..RA0`; paired LS245 devices connect
host `D15..D0` to `TD15..TD0`
[atari-driver-sound-board-schematic, drawing A044427, sheets 3–5 of 10, PDF
pp. 5–10]. **Confidence: VERIFIED_PRIMARY for organization and wiring; the
manufacturer suffix and complete SRAM AC limits have not been independently
qualified.**

### Program-RAM ownership is a firmware protocol

The drawing contains no mutual-exclusion arbiter. LS259 output `/320RES`
drives the TMS32010 reset pin and, through an inverter, the active-low enables
of the TMS-side address/control LS244s. The DSP path is therefore enabled when
`/320RES` is released high. Separately, host decode `/320RAM` directly enables
the host address/control LS244s and host-data LS245s when low. Neither enable
gates the other [atari-driver-sound-board-schematic, drawing A044427 Rev A,
sheet 3 of 10, PDF pp. 5–6; sheet 4 of 10, PDF pp. 7–8].

| `/320RES` | `/320RAM` | TMS path | host path | electrical meaning |
|---:|---:|---|---|---|
| 0 | 1 | disabled | disabled | DSP held reset, no host RAM access |
| 0 | 0 | disabled | enabled | legal host program-RAM access |
| 1 | 1 | enabled | disabled | legal DSP execution |
| 1 | 0 | enabled | enabled | invalid driver contention, not arbitration |

This proves that the board contract requires the 68000 to hold `/320RES` low
while accessing the DSP program-RAM window. It does not establish that every
firmware revision obeys the protocol or the exact release delay; those remain
`OQ-021`. A digital wrapper should assert or report the invalid fourth row,
not assign it undocumented read/write priority. The project-local
`hard_drivin_sound_bus_decode` exposes exactly that ownership conflict and an
exhaustive test covers all four combinations.

MAME maps DSP program words `0x000`–`0xfff` to shared sound DSP RAM and
allows host reads/writes of the same storage at `0xff4000`–`0xff5fff` without
checking DSP reset. Its latch bit drives an inverted HALT input rather than
the physical reset-qualified buffer network
[mame-harddriv-audio-030fefc, `hdsnd68k_320ram_r`,
`hdsnd68k_320ram_w`, `driversnd_dsp_program_map`, host map, and device
configuration]. **Confidence: CORROBORATED for address/storage intent; this
is an explicit timing/ownership abstraction under `SC-020`.**

## I/O map

The following working map comes from the current MAME integration and must be
checked signal-by-signal against schematic sheets 5–7:

| DSP port | Direction | Working function | Confidence |
|---:|---|---|---|
| 0 | read | serial sound ROM data | CORROBORATED |
| 0 | write | 12-bit DAC latch from `TD15..TD4` | VERIFIED_PRIMARY for raw code; signed-audio interpretation unresolved |
| 1 | read | host communication RAM | CORROBORATED |
| 2 | read | compare path, incompletely emulated | PROVISIONAL |
| 3 | write | communication-port control | CORROBORATED |
| 4 | write | mute control | CORROBORATED |
| 5 | write | generate 68000 IRQ | CORROBORATED |
| 6–7 | write | sound ROM address/select | CORROBORATED |

Sources: [atari-driver-sound-board-schematic, drawing A044427, sheets 5–7,
PDF pp. 9–14; mame-harddriv-audio-030fefc, `sounddsp_io_map` and handlers].

The A044427 output decode uses the physical bus, not the CPU's logical
instruction class. Three LS27 groups and an ALS11 generate `PORT` when
`TA11:TA3` are all zero. The program-RAM enable is
`/RAMEN = /MEN AND (/TWE OR PORT)`: MEN reads select program RAM at every
address; a WE write selects program RAM only when `PORT` is false. The write
LS138 instead selects one of ports 0–7 when `PORT` is true. With TI's
mutually-exclusive MEN/DEN/WE pin contract, the resulting board targets are:

| active TMS strobe | address | A044427 target |
|---|---:|---|
| `/MEN` | any `0x000`–`0xfff` | program-RAM read |
| `/DEN` | `0x000`–`0x007` | input port 0–7 |
| `/TWE` | `0x000`–`0x007` | output port 0–7 |
| `/TWE` | `0x008`–`0xfff` | program-RAM write |

Consequently, a TBLW whose accumulator address is `0x000`–`0x007` is
electrically decoded exactly like OUT and does not write program RAM. The
generic CPU correctly retains logical `program_write_o` versus `io_write_o`
ownership for reusable integrations, but the Hard Drivin' adapter must derive
the physical target from native address/MEN/DEN/WE. Pinned MAME instead keeps
program and I/O address spaces separate, so it does not reproduce this alias
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 5 of 10,
PDF p. 9; mame-harddriv-audio-030fefc, separate program and I/O maps]. This is
`SC-021`. **Confidence: VERIFIED_PRIMARY for the Rev-A decode; documented
secondary-source mismatch.**

### DAC path

Sheet 7 shows `/DACL` clocking two LS374 latches. Their outputs connect
`TD15` through `TD4` directly to Am6012 inputs `B1` through `B12`,
respectively. Thus a port-0 write presents the raw 12-bit DAC code
`TD15:TD4`; `TD3:TD0` do not enter the converter. There is no inverter or
complementary LS374 output between `TD15` and `B1`
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 7 of 10,
PDF p. 13]. The AMD data book identifies `B1` as the MSB and `B12` as the LSB
and describes increasing straight-binary input code as increasing `IOUT`
[amd-analog-communications-databook-1983, Am6012 data sheet, printed
pp. 3-17 and 3-22 (PDF pp. 95 and 100); application note, printed p. 3-27
(PDF p. 104)]. **Confidence: VERIFIED_PRIMARY for the latch and digital code
mapping.**

The board grounds complementary output pin 19 and applies `IOUT` pin 18 to
the inverting input of TL084B `105D`, with `R15`/`C13` in feedback. That
establishes an inverted first-stage transimpedance voltage for the positive
reference network, followed by the separately drawn analog filter and
AC-coupling path [atari-driver-sound-board-schematic, drawing A044427 Rev A,
sheet 7 of 10, PDF pp. 13-14]. Analog voltage inversion is not equivalent to
complementing only the digital MSB.

Pinned MAME instead computes `(data >> 4) XOR 0x800` before writing its
12-bit unsigned AM6012 abstraction. Since that abstraction maps an unsigned
code across its normalized output range, the XOR interprets the DSP word's
high twelve bits as two's-complement audio; it is not a transcription of the
shown pin wiring [mame-harddriv-audio-030fefc, `hdsnddsp_dac_w` and device
configuration; mame-dac-header-030fefc, AM6012 declaration;
mame-dac-core-030fefc, unsigned mapper and default output range]. This
disagreement is `SC-019`/`OQ-020`. A board adapter may expose raw
`data[15:4]`, but must not label the XOR as verified physical behavior until
an ECO, another board revision, original firmware trace, or hardware
measurement resolves the coding.

## Reset, BIO, and interrupt

The board supplies `/320RES` to DSP pin 4. MAME starts the DSP halted and
associates host latch control with reset/halt release. That emulator mechanism
is useful for trace comparison but does not establish physical reset-pin phase
timing [atari-driver-sound-board-schematic, drawing A044427, sheet 4 of 10,
PDF p. 7; mame-harddriv-audio-030fefc, device reset and device
configuration]. **Confidence: primary wiring VERIFIED_PRIMARY; reset timing
PROVISIONAL pending a complete board-control trace.**

### TMS32010 interrupt input

The active-low TMS32010 `INT` pin 5 connects to net `PR1` on sheet 4. Sheet 1
pulls `PR1` to +5 V through `R26`, 1 kΩ. A complete text/net-name search of
the ten-sheet production drawing found no loaded active driver: subsequent
uses are logic inputs, and the only switching network attached to `PR1` is in
a boxed `NOT LOADED` option on sheet 7. The production Rev-A board therefore
holds DSP `INT` inactive-high through a resistor; it is not a direct rail
strap [atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 1 of
10, PDF pp. 1–2; sheet 4 of 10, PDF p. 7; sheet 7 of 10, PDF p. 14].
**Confidence: VERIFIED_PRIMARY for the reviewed production Rev-A drawing.**

This resolves `OQ-005` for A044427 Rev A. A Hard Drivin'-specific wrapper
should default the DSP interrupt input high while retaining an overridable
external input for board variants and diagnostics. This does not relax the
generic core's interrupt requirements.

The similarly named `320IRQ` is a different net. It participates in the
sound-board 68000 interrupt path and does not connect to the TMS32010 `INT`
pin [atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 2 of
10, PDF pp. 3–4; sheet 5 of 10, PDF p. 9].
**Confidence: VERIFIED_PRIMARY.**

### BIO path

Sheet 2 generates `/320BIO` from 1 MHz counter/divider logic and an LS74
flip-flop cleared by `/RESET`. Sheet 4 applies `/320BIO` to the D input of
LS74 `70S`, clocks that flip-flop with the TMS32010 `CLKOUT`, and routes its Q
output `/BIOS` to active-low DSP `BIO` pin 9. The resynchronizer's asynchronous
controls use pulled-high net `PR5` and are inactive in the production
configuration [atari-driver-sound-board-schematic, drawing A044427 Rev A,
sheet 1 of 10, PDF p. 2; sheet 2 of 10, PDF p. 4; sheet 4 of 10, PDF
pp. 7–8]. **Confidence: VERIFIED_PRIMARY for connectivity and clock source;
the complete divider state sequence is not yet transcribed.**

Pinned MAME independently models this as a periodic BIO event derived from a
1 MHz divided-by-50 rate and binds only that callback to the DSP pin. It does
not configure a DSP interrupt source. MAME's callback advances an
instruction-cycle budget rather than reproducing the LS74/`CLKOUT` waveform,
so it corroborates function and approximate cadence only
[mame-harddriv-audio-030fefc, `BIO_FREQUENCY`,
`hdsnddsp_get_bio`, and device configuration].
**Confidence: CORROBORATED; not pin-timing proof.**

## Integration acceptance path

### ROM-free smoke evidence

`sim/programs/hard_drivin_smoke/` now supplies the first project-authored
synthetic program for this path. It performs raw writes to ports 0, 3, 4, 5,
6, and 7; reads synthetic host, sound-ROM, and compare values from ports 1,
0, and 2; and takes a BIOZ branch under asserted active-low BIO. Its committed
fixture fixes the assembled words, every logical program/I/O transaction,
the skipped sentinel address, all RAM/output results, and a 22-cycle total.

The fixture separately records the primary-backed physical DAC input code,
the pinned MAME adapter's different derived DAC value, and sound-ROM
bank/address fields. It does not implement either DAC interpretation in the
processor model or use MAME to promote hardware facts. In particular, port 2
remains PROVISIONAL because the pinned handler returns zero without modeling
the compare circuit. This is **VERIFIED_SIMULATION for the project-local
model/tool workflow, CORROBORATED for the MAME-facing port roles, and not a
physical board or game-ROM qualification.**

The future non-ROM qualification sequence is:

1. synthetic reset and address-0 fetch with schematic clock/reset ratios
   (generic wrapper evidence exists; board-specific reset/halt control remains);
2. synthetic 4K shared-program-RAM ownership and host-load sequence (decode
   truth table complete; storage/reset-release wrapper remains);
3. host/DSP communication-memory handshake;
4. BIO pulse/poll behavior;
5. synthetic writes through every decoded I/O port and DAC trace (model-level
   raw-port smoke and primary digital-code mapping complete; signed-audio
   interpretation remains under `OQ-020`);
6. optional user-supplied ROM hash validation and MAME-aligned execution
   trace.

User ROMs remain outside Git and the CI environment.
