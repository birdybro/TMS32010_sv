# Hard Drivin' DAC code and MAME-lineage audit

## Result

This audit narrows `OQ-020` but does not close it.

Atari drawing A044427 Rev A and AMD's Am6012 documentation establish a
straight-binary physical converter input and a positive-reference,
single-ended current-to-voltage path. The drawing contains no digital MSB
inverter. Historical MAME source establishes a different fact: MAME has
interpreted the TMS32010 output word as signed two's-complement audio since
its first located Hard Drivin' sound implementation in MAME 0.62 (2002).
The statement that the schematic inverts the MSB appeared only during a 2016
DAC-framework migration that preserved that older software interpretation.
It is therefore not independent hardware corroboration.

The raw FPGA latch remains `TD15:TD4`. Selecting a signed PCM conversion still
requires a production-board ECO/different revision, an authorized firmware
trace tied to analog output, or a physical capture. **Confidence:
VERIFIED_PRIMARY for the Rev-A electrical path; CORROBORATED for the
continuity of MAME's signed software interpretation; UNKNOWN for shipped-board
equivalence and intended game sample coding.** MAME's lower-precedence
software behavior does not override ADR-0001.

## Rev-A digital and analog path

A044427 sheet 7 clocks `TD15:TD4` into the true outputs of LS374 latches
`75E`/`90E`. In particular, `TD15` enters `75E` pin 18 and true output pin 19
drives Am6012 `B1` pin 1. AMD defines `B1` as the MSB and `B12` as the LSB.
The straight-binary table assigns zero `IOUT` to code `0x000` and increasing
current to increasing code. Its two's-complement configurations explicitly
require an inverter at `B1`
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 7, PDF
pp. 13-14; amd-analog-communications-databook-1983, Am6012 data sheet,
printed pp. 3-17 and 3-22 (PDF pp. 95 and 100)].

The reference and first output stage are also unambiguous on the drawing:

- `+5 V` reaches `VREF(+)` through `R12=1 kOhm` and `R13=4.7 kOhm`;
- `VREF(-)` returns to ground through `R14=5.6 kOhm`;
- complementary current output pin 19 is grounded;
- `IOUT` pin 18 drives the inverting input of TL084B `105D`;
- `R15=2.2 kOhm` and `C13=47 pF` form its feedback path; and
- the resulting `DACOUT` is AC-coupled through `C26=1 uF` into `DF IN`.

This is the manufacturer's positive-reference/straight-binary connection,
followed by whole-signal analog inversion and AC coupling. It is not the
manufacturer's symmetric two's-complement circuit and does not complement a
single digital bit
[amd-analog-communications-databook-1983, Am6012 code table and positive
reference connection, printed pp. 3-22 and 3-29 (PDF pp. 100 and 106);
atari-driver-sound-board-schematic, sheet 7, PDF pp. 13-14].

## Ideal nominal transfer

Using AMD's ideal relation

```text
IREF = 5 V / (1.0 kOhm + 4.7 kOhm)
IOUT = 4 * IREF * code / 4096
DACOUT = -2.2 kOhm * IOUT
```

gives the following nominal points:

| DSP word | physical code | ideal `IOUT` | ideal first-stage `DACOUT` | pinned-MAME mapper code |
|---:|---:|---:|---:|---:|
| `0x0000` | `0x000` | 0 mA | 0 V | `0x800` |
| `0x7ff0` | `0x7ff` | 1.753529 mA | -3.857765 V | `0xfff` |
| `0x8000` | `0x800` | 1.754386 mA | -3.859649 V | `0x000` |
| `0xfff0` | `0xfff` | 3.507915 mA | -7.717414 V | `0x7ff` |

These are **INFERRED ideal calculations**, not measurements. They ignore
resistor tolerance, reference bias, Am6012 error, op-amp behavior, loading,
and the later filter. They demonstrate only code topology: physical codes
`0x7ff` and `0x800` are separated by one LSB, whereas MAME's transformed
mapper codes jump from `0xfff` to `0x000` at that raw boundary.

`tools/trace/hard_drivin_dac_codes.py` reproduces the table and accepts any
captured 16-bit output words:

```sh
python3 -m tools.trace.hard_drivin_dac_codes 0000 7ff0 8000 fff0
```

The calculation does not decide sample encoding. Rev-A is compatible with an
offset/straight-binary waveform whose quiescent region is near physical code
`0x800`; AC coupling removes its DC component. A normal two's-complement
waveform would instead require an MSB inversion before the shown converter to
cross zero without a full-scale wrap. Whether game firmware emits either form
is not established by the drawing.

## MAME lineage

### MAME 0.62 introduction

The historic MAME 0.61 tag has no Hard Drivin' sound file or DSP DAC handler.
The MAME 0.62 tag adds `src/sndhrdw/harddriv.c`, and its changes file credits
Hard Drivin' sound support to Aaron Giles. The first handler passes
`data XOR 0x8000` to `DAC_signed_data_16_w`; the generic DAC function then
subtracts `0x8000`. Algebraically, the pair interprets the unchanged 16-bit
DSP word as a two's-complement sample:

```text
emulator sample = (data XOR 0x8000) - 0x8000 = signed16(data)
```

There is no schematic-inversion comment in that source
[historic-mame-harddriv-audio-062, lines 330-335;
historic-mame-dac-core-062, lines 59-68;
historic-mame-whatsnew-062, improved-sound list, line 37].

The initial GitHub import of MAME 0.121 in 2007 retains the same handler. This
shows continuity of a software sample-format decision; it supplies no new
electrical evidence.

### 2016 AM6012 migration

Commit `36944269bd6fe1fb47822a2112c524b13c4b27f2` changes the generic signed
16-bit DAC to an AM6012 abstraction, discards `TD3:TD0`, retains the sign-bit
XOR as `(data >> 4) XOR 0x800`, and adds the first located comment claiming
that the schematic inverts the MSB. The same commit drives the emulator DAC
with symmetric positive and negative references, whereas Rev-A uses a
positive reference, grounded complementary output, inverting current stage,
and subsequent AC coupling
[mame-harddriv-audio-36944269, `hdsnddsp_dac_w` and `harddriv_snd`
configuration].

The commit message says only that DACs were being documented and cites no
Atari ECO, alternate drawing, board capture, or firmware analysis. The code
change is fully explained as a resolution-correct migration of the pre-2002
signed interpretation. Its newly added schematic comment cannot therefore be
treated as an independent observation.

Pinned current MAME retains the same twelve-bit XOR and feeds an unsigned
AM6012 mapper whose default range is normalized bipolar output
[mame-harddriv-audio-030fefc; mame-dac-core-030fefc;
mame-dac-header-030fefc]. MAME remains a useful audible/functional oracle, but
its model is not a pin-level transcription of Rev-A.

## Board-revision and ECO search

Lawful searches on 2026-07-31 covered exact `A044427`, `A046491`, Driver Sound
board, Am6012, MSB inversion, revision, ECO, Hard Drivin', and Race Drivin'
terms; the current MAME path and commit history; historical MAME tags from
0.60 through 0.121; Atari manual/schematic indexes; and available board-photo
indexes. They located no authenticated alternate Driver Sound electrical
drawing, ECO, rework notice, or assembly record that inserts an MSB inverter.

Jed Margolin's first-person index says Hard Drivin' and Race Drivin' used the
same Sound Board, while noting uncertainty about additional Race Drivin' ROM
population. It links only the already pinned Rev-A electrical drawing
[hard-drivin-schematics-index-margolin, Driver Sound Board section]. Community
pages use assembly identifier `A046491`; no primary assembly drawing tying
that identifier to a DAC rework was located, so it remains a search lead, not
electrical evidence.

Negative search results mean only that no such source was found by these
routes. They do not prove that no production rework or alternate revision
existed.

## Decisive physical capture

TM-327 already supplies safe built-in stimuli: `320 DAC Ramp` ramps the DAC,
and `320 DAC Ones` writes walking ones through the DAC latch; both explicitly
require an oscilloscope [atari-hard-drivin-manual-tm327-third, Sound Board
diagnostics, printed p. 2-20 (PDF p. 33)]. On a documented original board:

1. Photograph both board sides, every wire/rework, assembly/revision text,
   device markings, and ROM labels; hash the raw photographs.
2. During `320 DAC Ones`, capture `/DACL`, TMS32010 `TD15`, `75E` D pin 18,
   `75E` Q pin 19, and Am6012 `B1` pin 1. This directly tests the missing-MSB
   inverter hypothesis.
3. During `320 DAC Ramp`, capture all twelve latch outputs, Am6012 `IOUT`,
   TL084B `105D` output `DACOUT`, and both sides of `C26`. Preserve analyzer
   files, scope calibration, probe loading, and supply/reference voltages.
4. With legally supplied game ROMs, capture raw port-0 writes and simultaneous
   `DACOUT`/post-`C26` waveforms. Compare offset-binary and two's-complement
   continuity without changing expected data to fit either hypothesis.
5. Repeat on a second production board before generalizing beyond one
   assembly.

Walking-ones evidence can prove or reject an actual MSB inversion. The ramp
can prove code monotonicity and analog polarity. Neither alone identifies the
normal-game sample convention; that requires the authorized game trace or an
Atari software/source statement.

## Implementation policy

- Keep `hard_drivin_sound_dac_latch.sv` at the verified physical boundary:
  raw `data[15:4]` only.
- Keep MAME's value separately named as an oracle/sample-rendering
  interpretation.
- Do not place either conversion in the generic TMS32010 core.
- A future audio renderer may offer explicit raw/offset/two's-complement
  modes, but its default must not be called production-accurate until this
  conflict is resolved.
- `OQ-020` remains `RESEARCHING/CONFLICT`; no RTL or model behavior changes
  from this audit.
