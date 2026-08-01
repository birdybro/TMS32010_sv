# Hard Drivin' Driver Sound output-control path

## Scope

This document qualifies only the digital A044427 Rev-A state reached through
TMS32010 output ports 4 and 5. It does not infer a loaded analog mute function,
implement a 68000 bus decoder, or reproduce bipolar pin propagation delays.

## Port 4 `/MCLK` and the raw `MUTE` net

The output LS138 selects active-low `/MCLK` at output Y4 for native writes to
address/port 4. `/MCLK` drives the clock of one half of LS74 location 100H;
`TD0` drives D, active-low clear is `/320RES`, preset is inactive through
pulled-high `PR1`, Q is unconnected, and complementary output `/Q` is the net
named `MUTE` [atari-driver-sound-board-schematic, drawing A044427 Rev A,
sheet 5 of 10, PDF p. 9].

TI specifies the LS74 as positive-edge triggered: with preset and clear high,
D transfers to Q on the rising clock edge, while a low clear forces Q low and
`/Q` high independently of D and clock [ti-sn74ls74a-datasheet-sdls119,
description and function table, printed p. 1]. The active-low decoder pulse
therefore captures when `/MCLK` returns high at transfer completion. The raw
board relationship is:

| event | LS74 Q | physical `MUTE` net (`/Q`) |
|---|---:|---:|
| `/320RES=0` | 0 | 1 |
| completed port-4 write with `TD0=0` | 0 | 1 |
| completed port-4 write with `TD0=1` | 1 | 0 |

Only `TD0` participates; `TD15:TD1` have no connection to this latch. This
digital state is **VERIFIED_PRIMARY**.

The only `MUTE` consumer found in the ten-sheet production drawing is a 4066B
analog-switch option enclosed by a box marked `NOT LOADED` on sheet 7
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 7 of 10,
PDF p. 14]. Pinned MAME comments that D0=1 mutes DAC audio, but its handler only
logs and changes no emulated state [mame-harddriv-audio-030fefc,
`hdsnddsp_mute_w`]. That name-level interpretation is unresolved as `SC-027`
and `OQ-027`; FPGA logic may expose the raw complementary net but must not gate
audio and call the result verified production hardware.

## Port 5 `/68IRQ` and `320IRQ`

The same output LS138 selects active-low `/68IRQ` at Y5 for native writes to
address/port 5. `/68IRQ` connects to the active-low preset of the other LS74 at
100H. Its D input is grounded, Q is `320IRQ`, active-low clear is `/320RES`, and
active-low host decode `/IRQCLR` drives its positive-edge clock
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 5 of 10,
PDF p. 9]. Consequently:

- any port-5 write asserts `320IRQ=1` independently of `TD15:TD0` through the
  asynchronous preset;
- `/320RES=0` forces `320IRQ=0`;
- after `/68IRQ` is inactive, the rising edge at the end of `/IRQCLR` clocks
  grounded D and clears `320IRQ`.

These behaviors follow TI's preset/clear and positive-edge function table
[ti-sn74ls74a-datasheet-sdls119, printed p. 1] and are
**VERIFIED_PRIMARY**. A044427 sheet 3 decodes `/IRQCLR` from a 68000-side
access; implementing its complete address/strobe timing belongs in the future
host bridge [atari-driver-sound-board-schematic, sheet 3 of 10, PDF p. 6].

Two open-collector LS06 stages driven by `320IRQ` pull the 68000 `IPL1` and
`IPL0` pins low, while `IPL2` remains pulled high through `PR3`
[atari-driver-sound-board-schematic, sheet 2 of 10, PDF p. 4]. Pinned MAME
independently represents the asserted latch as sound-CPU input line 3 and maps
the clear handler at `0xff3000`–`0xff3fff` [mame-harddriv-audio-030fefc,
`update_68k_interrupts`, `hdsnd68k_irqclr_w`, and `driversnd_68k_map`]. The raw
pin wiring is **VERIFIED_PRIMARY**; the numeric 68000 interrupt-level label is
**CORROBORATED** here because a Motorola interrupt-encoding primary source has
not yet been cataloged.

## FPGA boundary

`rtl/wrappers/hard_drivin_sound_output_control.sv` models these two LS74 halves
in the board clock domain. It exports the raw `MUTE` net and active-high
`320IRQ` state. A completed port-4 transaction captures complement `TD0` and
emits one commit pulse. A port-5 write request sets the IRQ state as soon as the
physical request is visible; a same-clock host-clear commit clears it only when
the set request is inactive. Set priority therefore matches active preset over
the normal clock path. FPGA initialization and sampled reset are digital
integration conventions; this is not a pin-delay model. The clear boundary is
named `host_irq_clear_commit_i` so a future 68000 bridge can supply the
qualified `/IRQCLR` completion without embedding host decode in this module.

## Verification evidence

`sim/bus/tb_hard_drivin_sound_output_control.sv` exhausts all 65,536 possible
port-4 data words and all 65,536 possible port-5 data words. It also checks
reset, no-commit retention, isolation from every other port, data-independent
IRQ assertion, host clear, and set-over-clear priority. The integrated
`hard_drivin_sound_mister` smoke holds the external ready callback low for both
ports, proving that the internally connected targets still complete: port 4
captures raw `MUTE=0`, port 5 asserts `320IRQ`, the explicit host callback
clears the IRQ, and processor reset restores raw `MUTE=1`.

Pre-technology Yosys reports 33 abstract cells, four retained checks, no
memory or latch, and zero structural problems for the standalone module. This
is digital structural evidence only, not electrical LS74 timing, a loaded mute
path, or 68000-bus qualification.
