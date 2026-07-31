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
logic. The drawings show a 4K-word-wide program-memory path made from four
four-bit RAM slices and host-side arbitration/access circuitry
[atari-driver-sound-board-schematic, drawing A044427, sheets 3–5 of 10, PDF
pp. 5–10]. **Confidence: VERIFIED_PRIMARY for topology; exact RAM part-number
and arbitration phase transcription pending.**

MAME maps DSP program words `0x000`–`0xfff` to shared sound DSP RAM and
models the TMS data map as the device's internal RAM
[mame-harddriv-audio-030fefc, `sounddsp_program_map` and device
configuration]. **Confidence: CORROBORATED; emulator map is not pin-timing
proof.**

## I/O map

The following working map comes from the current MAME integration and must be
checked signal-by-signal against schematic sheets 5–7:

| DSP port | Direction | Working function | Confidence |
|---:|---|---|---|
| 0 | read | serial sound ROM data | CORROBORATED |
| 0 | write | 12-bit DAC latch from `TD4..TD15` | primary wiring / secondary transform |
| 1 | read | host communication RAM | CORROBORATED |
| 2 | read | compare path, incompletely emulated | PROVISIONAL |
| 3 | write | communication-port control | CORROBORATED |
| 4 | write | mute control | CORROBORATED |
| 5 | write | generate 68000 IRQ | CORROBORATED |
| 6–7 | write | sound ROM address/select | CORROBORATED |

Sources: [atari-driver-sound-board-schematic, drawing A044427, sheets 5–7,
PDF pp. 9–14; mame-harddriv-audio-030fefc, `sounddsp_io_map` and handlers].

Sheet 7 shows `TD4..TD15` feeding latch/DAC logic; the low four DSP data bits
are not DAC samples. MAME models a right shift by four and an inverted sign
bit. The exact inversion and scale will be promoted to VERIFIED_PRIMARY only
after the analog sheet net polarities are fully transcribed.

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

The fixture also records the pinned MAME adapter's derived DAC value and
sound-ROM bank/address fields, but it does not implement them in the processor
model or promote them to hardware facts. In particular, port 2 remains
PROVISIONAL because the pinned handler returns zero without modeling the
compare circuit. This is **VERIFIED_SIMULATION for the project-local
model/tool workflow, CORROBORATED for the MAME-facing port roles, and not a
physical board or game-ROM qualification.**

The future non-ROM qualification sequence is:

1. synthetic reset and address-0 fetch with schematic clock/reset ratios
   (generic wrapper evidence exists; board-specific reset/halt control remains);
2. synthetic 4K shared-program-RAM arbitration;
3. host/DSP communication-memory handshake;
4. BIO pulse/poll behavior;
5. synthetic writes through every decoded I/O port and DAC trace (model-level
   raw-port smoke complete; board adapter and primary DAC polarity remain);
6. optional user-supplied ROM hash validation and MAME-aligned execution
   trace.

User ROMs remain outside Git and the CI environment.
