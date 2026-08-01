# Hard Drivin' Driver Sound port-2 compare path

## Status and scope

A044427 Rev A decodes TMS32010 input port 2 as `/CMPRD`, but the reviewed
production drawing does not establish a valid sixteen-bit compare response.
The only compare bit routed toward the processor is `CMPOUT` to `TDI15`, and
the complete microphone/comparator sheet that would generate `CMPOUT` is
explicitly marked `THIS SHEET NOT LOADED.` The electrical values seen on
`TDI15` and the otherwise undriven `TDI14:TDI0` during a production-board
port-2 read remain `UNKNOWN` under `OQ-029`.

This result deliberately does not turn MAME's zero-return handler into board
behavior. It qualifies which hardware is drawn, which hardware was omitted,
and the safe FPGA boundary; it does not implement an analog microphone path or
claim a physical open-bus value.

## Decode and processor-data path

On A044427 sheet 5, LS139 `95K` receives `/PDEN` and `RA1:RA0`. Its active-low
Y2 output is `/CMPRD`, so a physical input read at port 2 selects that strobe
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 5 of 10,
PDF pp. 9–10]. **Confidence: VERIFIED_PRIMARY.**

On sheet 3, the second half of LS244 `10H` uses `/CMPRD` as its active-low
output enable. Input pin 11 is `CMPOUT`, and corresponding output pin 9 is
connected to `TDI15`. The other three inputs in that half, pins 13, 15, and
17, are tied to `PR2`, but their outputs at pins 7, 5, and 3 are not connected
to TDI signals. Consequently, this selected target visibly drives only
`TDI15`; it supplies no drawn source for `TDI14:TDI0`
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 3 of 10,
PDF pp. 5–6; ti-snx4ls24x-datasheet, SNx4LS244 logic/function table, printed
pp. 11–13]. **Confidence: VERIFIED_PRIMARY for the shown connectivity.**

Every accepted input read also clocks the shared sound-address LS191 chain on
the trailing `/PDEN` edge. Port 2 therefore advances `SA15:SA0` once even
though the data value is unqualified. This remains independent of the
compare circuit's population and is already implemented in the shared-address
adapter [atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets
4–6 of 10, PDF pp. 7–12; ti-sn74ls191-datasheet-sdls072, printed pp. 1–4].
**Confidence: VERIFIED_PRIMARY.**

## Optional microphone comparator

Sheet 8 draws an optional microphone amplifier/filter. `MICFIL` is AC-coupled,
biases a TL084 stage about 2.5 V, and reaches LM311 `105C` pin 3. `DACOUT`
reaches pin 2. The LM311 collector output at pin 7 is named `CMPOUT` and is
pulled to +5 V through `R11`, 1 kΩ
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 8 of 10,
PDF pp. 15–16].

TI identifies LM311 pin 2 as noninverting `IN+`, pin 3 as inverting `IN-`, and
pin 7 as the collector output. Its output stage is an open-collector NPN
pull-down: within the qualified input range, an inverting input above the
noninverting input sinks the output low; the opposite relation leaves the
collector high impedance for the external pull-up
[ti-lm311-datasheet-slcs007k, Pin Configuration and Functions, printed p. 3;
§§8.3–8.4 and 9.2.2.1, printed pp. 11 and 13]. That describes the optional
circuit's intended comparator polarity only.

The title-block half of the same Atari sheet states `THIS SHEET NOT LOADED.`
Therefore the microphone chain, LM311, and `R11` pull-up are not production
Rev-A population evidence. In particular, the drawing supplies no justified
default for the unpopulated `CMPOUT` net at the still-drawn LS244 input.
**Confidence: VERIFIED_PRIMARY for the Rev-A nonpopulation; UNKNOWN for the
physical value read at port 2.**

## MAME boundary and current FPGA contract

Pinned MAME maps port 2 to `hdsnddsp_compare_r`, logs the access, and returns
the complete word `0x0000`. It does not model `CMPOUT`, the partial `TDI15`
buffer, the unpopulated option, or the shared-address increment
[mame-harddriv-audio-030fefc, `hdsnddsp_compare_r` and
`driversnd_dsp_io_map`]. The zero is an emulator stub, not physical proof;
`SC-029` records that conflict. Its missing port-2 increment remains the
separate `SC-024` abstraction.

`hard_drivin_sound_mister` consequently leaves port 2 on the explicit external
`io_read_data_i`/`io_ready_i` callback. A board integration may supply a
variant-specific result, stall/report an unavailable target, or later add an
opt-in populated comparator adapter after its bit-fill and analog contract are
qualified. It must not hardwire zero and describe that as Rev-A behavior.
No new RTL is warranted by the present evidence.

The ROM-free smoke fixture supplies an explicit synthetic zero through that
external callback so the instruction and global address-increment path remain
deterministic. That value is only a project test sentinel matching the pinned
MAME oracle; it is not an expected A044427 production read.
