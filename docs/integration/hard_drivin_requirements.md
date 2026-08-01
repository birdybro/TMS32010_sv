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

### 68000 low-I/O and control latch

Within the valid host-I/O region, LS138 `30N` decodes `RWN` plus `A13:A12`
into four write strobes and four read strobes. The write quadrants are
`/SOUNDWR`, `/LATCHES`, `/SPEECH`, and `/IRQCLR`; the matching read quadrants
are `/SOUNDRD`, `/320PORT`, `/SWITCHES`, and `/READSTAT`. During a
`/LATCHES` write, LS259 `80R` takes its selected bit from `A3:A1` and its new
value from `A4`; host `D15:D0` does not participate. Board `/RESET` clears all
eight Q outputs. Q3 is `CRAMEN` and Q4 is `/320RES`
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 3 of 10,
PDF pp. 5–6; ti-sn74ls259b-datasheet-sdls086, printed pp. 1–2].
**Confidence: VERIFIED_PRIMARY.**

`hard_drivin_sound_host_control` now implements that isolated address-encoded
latch update behind an explicit decoded completion pulse. It exposes every raw
Q bit and per-bit validity, passes all eight selections/both values/reset and
retention tests, and synthesizes to 53 cells with six retained checks. The
board top can select Q4/Q3 behind an explicit opt-in, exports selected-control
validity, and passes a synthetic program/communication-RAM handoff while
opposite-valued external callbacks are ignored. `/RVAS`, DTACK, the full 68000
memory map, and physical host timing remain separate acceptance work. Complete
details are in `docs/integration/hard_drivin_host_control.md`.

The four host read targets do not all drive a complete word. `/SOUNDRD`
drives `D15:D0`; `/320PORT` drives only `D15:D8` from the TMS port-3 latch;
`/SWITCHES` and `/READSTAT` each drive only `D15:D12`. Undriven lanes remain
`OQ-030`, so the FPGA boundary uses driven/valid masks instead of silently
filling a verified word. The complete trace is in
`docs/integration/hard_drivin_host_reads.md`.

The standalone storage-free `hard_drivin_sound_switches` mapper preserves the
non-inverting order `{J3-11,J3-9,J3-8,J3-7}` on host `D15:D12`, fixed driven
mask `0xf000`, and independent raw-input validity. All 256 value/validity
combinations pass; Yosys reports 10 cells and six retained checks. No
connector function or idle level is assigned under `OQ-032`. Pinned MAME's
swapped `/320PORT`/`/SWITCHES` handler names and two zero stubs remain isolated
as `SC-033`; a future selector must follow Atari LS138 `30N`.

The standalone `hard_drivin_sound_read_status` mapper now preserves the exact
`MAINFLAG`, `SOUNDFLAG`, `SOUND.TEST`, and active-low `/TIRDY` order in
`D15:D12`, with independent source validity and fixed driven mask `0xf000`.
Its deterministic low twelve carrier bits remain outside that mask. Exhaustive
simulation covers every source/value-validity combination; Yosys reports 23
cells and eight retained checks. Pinned MAME's fixed test/ready/low-lane values
remain a separate secondary abstraction under `SC-032`. The board top now
connects the live mailbox flags and retains raw external `SOUND.TEST` and
`/TIRDY` inputs; no complete-word/open-bus policy is implied.

Two pairs of LS374s separately exchange complete 16-bit words between the
main system and the local sound 68000. LS74 `20S` asynchronously sets
`MAINFLAG` on `/MAINWR` and `SOUNDFLAG` on `/SOUNDWR`; the trailing edges of
`/SOUNDRD` and `/MAINRD` clear the respective flags by clocking grounded D.
Board reset clears only the flags, not either word latch. The standalone
`hard_drivin_sound_mailboxes` callback exhaustively verifies nominal
whole-word exchange and explicitly invalidates unsourced coincident set/clear
conditions. Byte-write behavior remains `SC-031`/`OQ-031`, and the adapter is
now board-top connected only through explicit whole-word completion callbacks.
Both retained words, data validity, flag validity, conflicts, and raw
`/READSTAT` masks remain visible. This is not a 68000 or main-system bus. See
`docs/integration/hard_drivin_host_mailboxes.md`.

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

The host program path uses `A12:A1` as the 4K word address and connects all
sixteen `D15:D0` bits through two LS245 devices. The host-side LS244 drives the
single `/RAMCE` and `/RAMWR` controls. The 68000 `/UDS` and `/LDS` signals are
used elsewhere on the drawing but do not enter this program-RAM control path
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets 3–4 of 10,
PDF pp. 5–8]. **Confidence: VERIFIED_PRIMARY for the shown whole-word path.**
The electrical result of an attempted byte write and whether production
firmware ever performs one remain `SC-022`/`OQ-022`; a wrapper must not silently
call byte-preserving merge behavior verified hardware.

### Same-clock FPGA storage adaptation

`hard_drivin_sound_program_ram` implements the 4,096-by-16 storage without
vendor primitives. It instantiates the qualified decoder, grants the host only
for `/320RES=0,/320RAM=0`, grants the TMS only for
`/320RES=1,/320RAM=1`, and acknowledges neither side in the invalid overlap.
Host and TMS write inputs commit only on explicit caller-supplied pulses. A
single selected-address synchronous read port supplies registered data and a
ready indication. Adapter initialization clears only response-valid state;
it deliberately does not initialize or erase program words.

Synchronous read latency, ready, and commit signals are FPGA integration
conventions around the physical asynchronous SRAM, not reconstructed board
pins. All 4,096 words are loaded through the host port and read back through
the TMS port in `tb_hard_drivin_sound_program_ram`; the same test covers
reset retention, safe handoff, high-address TBLW storage, low-eight I/O alias,
and rejected conflicting writes. Yosys 0.67+111 retains one 4,096-by-16
`$mem_v2` with one registered read port and one merged write port. This is
**VERIFIED_SIMULATION** and a portable-synthesis structural result, not a
Quartus block-RAM mapping, 68000 bridge, or complete board timing claim.

`hard_drivin_sound_mister` now joins this storage to the generic synchronous
callback wrapper. It separates FPGA initialization from physical `/320RES`,
routes physical I/O readiness back to a low-address TBLW, and exports one
phase-3 commit pulse for both ordinary I/O and that alias. Its RTL test executes
the project-authored smoke program after host loading, then executes a focused
low-TBLW program and reads the unchanged target RAM word back through the host.
A second focused sequence proves address-zero TBLW uses the internal DAC
target's always-ready contract, captures data word `0x00a5` as raw code `0x00a`,
retains the documented five-cycle total, and leaves program word zero unchanged.
See `docs/integration/hard_drivin_mister_wrapper.md` for the interface contract.
**Confidence: VERIFIED_SIMULATION; not a 68000 or peripheral implementation.**

MAME maps DSP program words `0x000`–`0xfff` to shared sound DSP RAM and
allows host reads/writes of the same storage at `0xff4000`–`0xff5fff` without
checking DSP reset. Its latch bit drives an inverted HALT input rather than
the physical reset-qualified buffer network
[mame-harddriv-audio-030fefc, `hdsnd68k_320ram_r`,
`hdsnd68k_320ram_w`, `driversnd_dsp_program_map`, host map, and device
configuration]. **Confidence: CORROBORATED for address/storage intent; this
is an explicit timing/ownership abstraction under `SC-020`.**

## I/O map

The following map separates functions visible in the Rev-A drawing from
secondary adapter behavior:

| DSP port | Direction | Working function | Confidence |
|---:|---|---|---|
| 0 | read | parallel sample-ROM byte, signed and shifted left 7 | VERIFIED_PRIMARY |
| 0 | write | 12-bit DAC latch from `TD15..TD4` | VERIFIED_PRIMARY for raw code; signed-audio interpretation unresolved |
| 1 | read | 512-word host communication RAM at shared `SA8:SA0` | VERIFIED_PRIMARY |
| 2 | read | optional microphone/DAC comparator; Rev-A source sheet not loaded; only `CMPOUT` reaches `TDI15` | UNKNOWN (`OQ-029`) |
| 3 | write | LS374 captures `TD7:TD0`; host `/320PORT` drives it on `D15:D8` | VERIFIED_PRIMARY (`OQ-023` resolved) |
| 4 | write | LS74 captures TD0; raw `MUTE=/Q=!TD0`; only drawn consumer not loaded | VERIFIED_PRIMARY for raw state; effective mute UNKNOWN |
| 5 | write | data-independent LS74 preset asserts latched `320IRQ` | VERIFIED_PRIMARY |
| 6 | write | low-nibble sample-ROM block latch | VERIFIED_PRIMARY |
| 7 | write | 16-bit shared sound-address counter load | VERIFIED_PRIMARY |

Sources: [atari-driver-sound-board-schematic, drawing A044427, sheets 4–7,
PDF pp. 7–14; mame-harddriv-audio-030fefc, `driversnd_dsp_io_map` and handlers].

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

### Communication RAM and shared sound address

Port 1 is a read-only DSP view of two HM6116 devices configured as 512 by 16
words. Host latch `CRAMEN` selects ownership: low enables the `SA8:SA0`
address path and port-1 CRD-to-TDI buffer; high enables host `A9:A1`, data,
and read/write controls while disabling the DSP buffer. The latch clears low
on board reset. This is complementary ownership, not the unarbitrated program-
RAM topology
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets 3 and 5 of
10, PDF pp. 5-6 and 9-10; ti-sn74ls259b-datasheet-sdls086, printed pp. 1-4].
**Confidence: VERIFIED_PRIMARY.**

Four LS191 counters provide `SA15:SA0`. Port 7 asynchronously loads all sixteen
bits. The counter clocks on the trailing low-to-high `/PDEN` edge after every
input-port read and counts upward; port 6 separately latches the low four data
bits as sample-ROM block selection. Thus even a port-2 compare read increments
the physical counter. Pinned MAME increments only its port-0 and port-1
handlers and returns communication RAM to the DSP regardless of `CRAMEN`.
Those abstractions are isolated as `SC-023` and `SC-024`
[atari-driver-sound-board-schematic, sheet 6 of 10, PDF pp. 11-12;
ti-sn74ls191-datasheet-sdls072, printed pp. 1-4;
mame-harddriv-audio-030fefc, communication/ROM/compare handlers].

Port 3 clocks `TD7:TD0` into LS374 `50L`; `/320PORT` enables its outputs onto
host `D15:D8`. The earlier no-consumer hypothesis is closed by sheet 4 under
`OQ-023`. Pinned MAME logs the write and returns zero from the host read, so
its incomplete stub is isolated as `SC-030`. Host `D7:D0` remain electrically
unqualified under `OQ-030`. Complete wiring and the masked FPGA boundary are
in `docs/integration/hard_drivin_host_reads.md`.

The standalone `hard_drivin_sound_communication_path` now implements the
qualified 512-word storage/ownership boundary and shared address/block state.
Its exhaustive simulation covers all 512 words plus the global port-2 read
increment, wrap, validity, ownership, and port-3 address-control-isolation
cases; its
pre-technology Yosys target retains one memory with zero structural problems.
The processor/program-RAM board top now routes port 1 to this path, preloads a
synthetic word through the whole-word host callback, and verifies execution,
global read increments, and reset retention. A 68000 host latch/bus adapter,
sample-ROM data callback, and physical timing remain acceptance work.

### Parallel sample ROM

A044427 does not draw a serial shifter. Port 6 latches `SCD:SCA`; two LS138s
select one of `/SR0` through `/SR11`, and the selected byte-wide ROM is
addressed directly by `SA15:SA0`. Blocks 12-15 have no connected select.
The ROM byte `SD14:SD7` reaches TMS input bits as a signed left shift:
`TDI15=SD14`, `TDI14:TDI7=SD14:SD7`, and `TDI6:TDI0=0`
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets 5-6 of 10,
PDF pp. 9-12; ti-sn74ls138-datasheet, printed pp. 1-2;
ti-snx4ls24x-datasheet, printed pp. 11-13]. **Confidence: VERIFIED_PRIMARY.**

Pinned MAME's byte/block address composition agrees with the board topology,
but its unsigned `byte << 7` omits the duplicated sign bit at TDI15. `SC-026`
records the conflict, and `OQ-026` tracks unpopulated-block behavior and exact
population by revision. Complete details and FPGA requirements are in
`docs/integration/hard_drivin_sound_rom.md`.

The storage-free FPGA adapter now accepts an explicit twelve-bit population
mask and authorized byte callback, reports every invalid or absent selection,
and forms the physical signed-left-seven port-0 word. Its exhaustive test spans
all blocks, all 65,536 byte addresses, all 256 byte values, validity, presence,
stall, and target-isolation cases. The board top routes port 0 internally and
holds block 3/address `0x3457` stable through a delayed synthetic `0xd5`
response. This is VERIFIED_SIMULATION for the schematic-derived digital
mapping, not a ROM-content, open-bus, or physical-access-time claim.

### Port-2 compare path

Port 2 decodes `/CMPRD` and enables one half of LS244 `10H`, but that target
connects only `CMPOUT` to `TDI15`; it does not drive `TDI14:TDI0`. Sheet 8
draws `CMPOUT` from an LM311 comparing filtered microphone audio against
`DACOUT`, with a 1 kΩ open-collector pull-up, and then explicitly states
`THIS SHEET NOT LOADED.` A production Rev-A read word is therefore not
qualified by the schematic. Pinned MAME's full-word zero is an emulator stub,
not a board default (`SC-029`/`OQ-029`). The wrapper correctly retains an
external port-2 callback rather than internalizing zero. Complete topology,
component polarity, population evidence, and FPGA guidance are in
`docs/integration/hard_drivin_compare.md`.

Every accepted port-2 input read still increments the shared sound-address
counter because `/PDEN`, not an individual handler, clocks the LS191 chain.
That separately verified side effect remains implemented under `SC-024`.
**Confidence: VERIFIED_PRIMARY for decode, connectivity, nonpopulation, and
counter side effect; UNKNOWN for the physical sixteen-bit response.**

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

`rtl/wrappers/hard_drivin_sound_dac_latch.sv` now implements only that safe
digital boundary. A committed port-0 write captures `io_write_data[15:4]`,
sets explicit validity, and emits one same-clock `dac_commit_o` pulse. It has
no processor-reset input because the drawn LS374 path has no clear; only
FPGA-specific `initialize_i` resets its validity. The standalone test exhausts
all 65,536 input words, proves every low-nibble alias, isolates ports 1-7 and
input-side commits, and checks retention without a commit. Yosys reports
14 cells, two retained checks, and no memory/latch or structural problem.

`hard_drivin_sound_mister` acknowledges the physical port-0 output latch
without using external callback readiness and exposes the uncomplemented raw
code to downstream audio logic. The integrated smoke commits `0xf230` once as
`0xf23`; it does not emit MAME's `0x723`. This is VERIFIED_SIMULATION for the
primary-backed digital latch only, not the analog voltage, sample encoding, or
sound reproduction.

### Port-4 MUTE state and port-5 68000 interrupt

A044427 and TI's SDLS119 LS74 data sheet establish both location-100H halves.
Port 4 captures `TD0` and exports complementary `/Q` as the raw `MUTE` net;
`/320RES` forces that net high. The sole drawn analog consumer is explicitly
`NOT LOADED`, so no effective audio mute is implemented. Port 5 asynchronously
presets active-high `320IRQ` without using write data; `/IRQCLR` clocks grounded
D to clear it and `/320RES` also clears it. The standalone FPGA adapter
exhausts all 65,536 data words for both paths, reset, clear, simultaneous
set/clear priority, other ports, and missing commits. Yosys reports 33 cells
with four retained checks and zero structural problems. Complete evidence and
the `SC-027`/`OQ-027` mute ambiguity are in
`docs/integration/hard_drivin_sound_control.md`.

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

Sheet 2 cascades two LS161 binary counters preloaded to `0xce`; they count
through `0xff`, synchronously reload, and drive an LS74 to create a
one-1-MHz-period active-low `/320BIO` pulse every 50 periods. `/RESET` clears
that source LS74 but does not clear or load the counters. Sheet 4 applies
`/320BIO` to D of LS74 `70S`, clocks it with TMS32010 `CLKOUT`, and routes Q as
`/BIOS` to active-low DSP `BIO` pin 9. The resampler's asynchronous controls
use pulled-high `PR5` [atari-driver-sound-board-schematic, drawing A044427 Rev
A, sheets 1–2 and 4 of 10, PDF pp. 2, 4, and 7–8;
ti-sn74ls161a-datasheet-sdls060, printed pp. 1–2 and 7;
ti-sn74ls74a-datasheet-sdls119, printed p. 1]. **Confidence:
VERIFIED_PRIMARY for connectivity, divide-by-50 sequence, source pulse width,
and nominal cadence; physical power-up/reset-release phase remains UNKNOWN.**

Pinned MAME independently models this as a periodic BIO event derived from a
1 MHz divided-by-50 rate and binds only that callback to the DSP pin. It does
not configure a DSP interrupt source. MAME's callback advances an
instruction-cycle budget rather than reproducing the LS74/`CLKOUT` waveform,
so it corroborates function and approximate cadence only
[mame-harddriv-audio-030fefc, `BIO_FREQUENCY`,
`hdsnddsp_get_bio`, and device configuration].
**Confidence: CORROBORATED; not pin-timing proof.**

The complete primary transcription, `SC-028` MAME abstraction boundary,
`OQ-028` independent-clock ambiguity, validity-aware standalone RTL, and
directed verification are in `docs/integration/hard_drivin_bio.md`.

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
bank/address fields. The processor model records the raw output word, and the
board RTL now captures only the primary-backed raw DAC code; neither interprets
it as audio or uses MAME to promote hardware facts. In particular, the harness
supplies zero through the external port-2 callback only to obtain a
deterministic test; A044427 Rev A does not establish that physical read word.
This is **VERIFIED_SIMULATION for the project-local
model/tool workflow, CORROBORATED for the MAME-facing port roles, and not a
physical board or game-ROM qualification.**

The future non-ROM qualification sequence is:

1. synthetic reset and address-0 fetch with schematic clock/reset ratios
   (complete in the same-clock board wrapper; exact 68000 latch timing remains);
2. synthetic 4K shared-program-RAM ownership and host-load sequence (complete
   in both the standalone adapter and processor-connected RTL wrapper;
   host-bus timing remains);
3. host/DSP communication-memory handshake (complete for the same-clock
   whole-word callback and synthetic processor execution; 68000 bus/latch
   timing remains);
4. BIO pulse/poll behavior;
5. synthetic writes through every decoded I/O port and DAC trace (model-level
   raw-port smoke and primary digital-code mapping complete; signed-audio
   interpretation remains under `OQ-020`);
6. optional user-supplied ROM hash validation and MAME-aligned execution
   trace.

User ROMs remain outside Git and the CI environment.
