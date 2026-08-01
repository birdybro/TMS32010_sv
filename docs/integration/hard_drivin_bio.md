# Hard Drivin' Driver Sound BIO generator

## Scope

This document qualifies the digital A044427 Rev-A path from the board's
1 MHz clock through the TMS32010 active-low `BIO` pin. It separates the
primary-documented divider and flip-flop relationships from FPGA clock-enable
adaptation, physical power-up phase, and the event-oriented MAME abstraction.

## Divide-by-50 source

A044427 sheet 2 cascades LS161 counters 95R and 100S. Both receive the board
1 MHz clock. The first stage has both count enables high; its RCO drives both
enables of the second stage. The second RCO drives the D input of LS74 50S and,
through LS04 80S, drives the active-low LOAD inputs of both counters
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 2 of 10,
PDF p. 4].

The parallel inputs shown on that sheet are:

| counter | D | C | B | A | preload nibble |
|---|---:|---:|---:|---:|---:|
| 100S, high | 1 | 1 | 0 | 0 | `0xc` |
| 95R, low | 1 | 1 | 1 | 0 | `0xe` |

TI defines LS161 as a four-bit binary counter triggered on the rising clock
edge. Low LOAD synchronously transfers D:C:B:A regardless of enables. RCO is
high when ENT and all four Q outputs are high, and supports synchronous
cascading [ti-sn74ls161a-datasheet-sdls060, description and logic symbols,
printed pp. 1–2; LS161A logic diagram, printed p. 7]. Consequently the pair
counts `0xce` through `0xff`; terminal `0xff` makes LOAD low and the next
1 MHz rising edge reloads `0xce`. This is an exact divide by 50.

LS74 50S samples the pre-edge terminal indication on that same rising edge.
Its complementary output is `/320BIO`, so the reload edge makes `/320BIO=0`;
the following 1 MHz edge samples a nonterminal count and restores
`/320BIO=1`. The resulting source is a one-1-MHz-period active-low pulse every
50 periods: nominally 1 microsecond low at 20 kHz
[atari-driver-sound-board-schematic, sheet 2 of 10, PDF p. 4;
ti-sn74ls74a-datasheet-sdls119, function table and positive-edge behavior,
printed p. 1]. **Confidence: VERIFIED_PRIMARY for the digital sequence and
nominal cadence.**

## Reset and phase

The two LS161 CLR inputs are tied to pulled-high `PR5`; they do not receive
board `/RESET`. `/RESET` clears only LS74 50S, forcing `/320BIO` inactive-high
while the counters continue to advance. Therefore reset neither loads `0xce`
nor establishes the divide-by-50 phase. After an unknown physical power-up
state, the first terminal/reload event self-establishes the documented phase;
the latency of that first event and its position relative to reset release are
not specified by the drawing [atari-driver-sound-board-schematic, sheets 1–2
of 10, PDF pp. 2 and 4]. This is tracked as `OQ-028` rather than assigning a
convenient reset count.

## CLKOUT resampling

A044427 sheet 4 connects `/320BIO` to D of LS74 70S and clocks it from DSP
`CLKOUT`. Q is `/BIOS`, which reaches active-low TMS32010 `BIO` pin 9. Both
asynchronous controls of 70S use pulled-high `PR5`, so board reset does not
directly initialize this resampler [atari-driver-sound-board-schematic,
drawing A044427 Rev A, sheets 1 and 4 of 10, PDF pp. 2 and 8]. The board's
20 MHz DSP clock makes nominal `CLKOUT` 5 MHz, while the 1 MHz source derives
from the separate 16 MHz board oscillator [atari-driver-sound-board-schematic,
sheets 1–2 and 4 of 10, PDF pp. 2, 4, and 7–8;
ti-tms32010-users-guide-spru001b, Appendix A Clock Characteristics and Timing,
printed p. 11 (PDF p. 367)].

The resampler therefore exposes only a CLKOUT-edge sample of the source pulse.
The two crystals are independent. The drawing supplies no deterministic phase
or metastability result for a source transition inside the LS74 setup/hold
window; such a coincidence remains `OQ-028`. This does not change BIOZ's
qualified architectural rule: the processor branches when its raw active-low
BIO input is low at the instruction's sampling boundary.

## FPGA boundary and verification

`rtl/wrappers/hard_drivin_sound_bio_generator.sv` represents the two physical
clock domains as `one_mhz_rise_i` and `clkout_rise_i` enables under one FPGA
clock. It creates no generated or gated clock. The enables are contractually
noncoincident until a future wrapper defines an explicit same-edge policy from
stronger evidence. A caller supplies deterministic FPGA counter bits and a
separate validity bit; an unqualified seed becomes phase-valid only at the
first model `0xff`-to-`0xce` reload. That validity qualifies the recurring
documented sequence, not alignment to an unavailable physical board. Raw-source
and resampled-pin validity are also exported so initialization convenience
cannot be mistaken for known physical power-up state.

The standalone regression checks all fifty qualified divider states, exact
one-period source assertion, five nominal CLKOUT samples per pulse, source and
resampler latency, continued counting during reset, reset release without
phase replacement, and self-qualification from all 256 explicitly invalid
deterministic seed values.
Pre-technology Yosys reports 52 cells, seven retained checks, no memory or
latch, and zero structural problems. This is logical FPGA evidence, not an
electrical setup/hold or metastability result.

The module is connected to `hard_drivin_sound_mister` as an explicit opt-in
path. The external platform-independent raw BIO input remains the default
when `use_board_bio_i=0`. A caller supplies only the 1 MHz rising-edge enable;
the board top derives the modeled CLKOUT rising-edge enable from the core's
actual phase advance. The generator's noncoincident-enable assertion makes a
1 MHz event on that same FPGA clock an invalid integration schedule rather
than silently choosing the unresolved physical coincidence result. Board
`/RESET` remains a distinct input from processor `/320RES`.

Counter, raw-source, sampled-pin, and selected-pin validity remain observable.
Selecting the board path before it becomes qualified does not stall the DSP or
claim a physical startup value; `selected_bio_valid_o=0` discloses that state.
The integrated regression holds the external BIO sentinel high, generates and
samples a qualified low board BIO, selects it, and proves that `BIOZ` takes the
target before the next sampled release. Pre-technology synthesis of the full
partial board top reports 2,408 abstract cells, 154 retained checks, three
memories, and zero structural problems. The top still requires an external
1 MHz clock-enable source and does not resolve `OQ-028` electrical phase or
metastability behavior.

## Secondary emulator behavior

Pinned MAME defines `BIO_FREQUENCY=1000000/50` and 250 nominal DSP cycles per
event, corroborating the 20 kHz cadence. Its callback advances the CPU cycle
budget to the next event whenever BIO is queried and returns asserted; it does
not represent `/320BIO` pulse width, LS74 70S sampling, deassertion, reset
phase, or asynchronous clock relationship [mame-harddriv-audio-030fefc,
`BIO_FREQUENCY`, `CYCLES_PER_BIO`, and `hdsnddsp_get_bio`]. This abstraction is
recorded as `SC-028` and is not a pin-level oracle.
