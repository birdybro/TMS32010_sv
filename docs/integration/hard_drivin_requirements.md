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
5 MHz/200 ns [ti-tms32010-users-guide-spru001b, Appendix A clock
characteristics]. **Confidence: VERIFIED_PRIMARY.**

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

The board supplies `/320RES` and external BIO synchronizer logic. MAME starts
the DSP halted and associates host latch control with reset/halt release; it
also generates periodic BIO behavior. These emulator mechanisms are useful
for trace comparison but do not establish real pin phase timing
[atari-driver-sound-board-schematic, drawing A044427, sheets 4–5, PDF
pp. 7–10; mame-harddriv-audio-030fefc, device configuration and BIO
callback]. **Confidence: primary wiring VERIFIED_PRIMARY, behavioral timing
PROVISIONAL.**

The schematic net entering DSP `INT` appears as `PR1`; whether this is a
fixed rail remains `OQ-005`. No Hard Drivin' wrapper interrupt behavior will
be invented until resolved.

## Integration acceptance path

The future non-ROM qualification sequence is:

1. synthetic reset and address-0 fetch with schematic clock/reset ratios;
2. synthetic 4K shared-program-RAM arbitration;
3. host/DSP communication-memory handshake;
4. BIO pulse/poll behavior;
5. synthetic writes through every decoded I/O port and DAC trace;
6. optional user-supplied ROM hash validation and MAME-aligned execution
   trace.

User ROMs remain outside Git and the CI environment.
