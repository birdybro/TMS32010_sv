# Hard Drivin' Driver Sound local 68000 memory decode

## Scope and evidence boundary

This document traces the local MC68000 ROM, high-bank, DSP-program-path, and
local-RAM controls on Atari Driver Sound drawing A044427 Rev A. It describes
the physical Boolean decode and populated memory address projections needed by
TM-327's synthetic local program-ROM/program-RAM diagnostics. It does not
provide a 68000 core, copyrighted ROM, memory storage, DTACK generator,
electrical timing closure, or open-bus value.

Atari's schematic is the wiring authority. TI component data sheets establish
the LS138 active-low one-of-eight decode and ALS32 positive-OR functions. The
pinned MAME map is kept as a secondary software-oriented comparison
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets 3-5 of 10,
PDF pp. 5-10; ti-sn74ls138-datasheet, printed pp. 1-2;
ti-sn74als32-datasheet-sdas113b, printed p. 1;
mame-harddriv-audio-030fefc, `driversnd_68k_map` and the associated
`hdsnd68k_320*` handlers].

## Low-half ROM gate and populated address

ALS32 `30R` drives both EPROM `/CE` pins with:

```text
/ROMCE = A23 OR /AS
```

The two drawn `27256D20` devices at `70N` and `45N` supply `D15:D8` and
`D7:D0`. They share `/CE` and `/OE`, so a selected read drives a complete
sixteen-bit word; `/UDS` and `/LDS` do not gate either EPROM output. CPU
`A1:A15` reach the devices' fifteen address inputs. CPU `A16` reaches only the
`E1/E2` option at pin 1, which the populated 27256 symbol identifies as VPP.

Consequences for the drawn 27256 population are:

- every asserted `/AS` cycle with `A23=0` selects the ROM pair;
- `A22:A16` are absent from the populated word address;
- the physical 64 KiB image repeats throughout `0x000000-0x7fffff`; and
- the storage word address is `A15:A1`.

The exact installed `E1/E2` strap and any later larger-EPROM board population
remain `OQ-034`. The RTL therefore exports only the verified populated-27256
address and explicitly does not implement a larger-EPROM mode. **Confidence:
VERIFIED_PRIMARY for the Rev-A drawing and populated-device projection;
UNKNOWN for production strap/variant coverage.**

## High-bank LS138

LS138 `30P` is enabled by `A23=1`, asserted `/AS`, and its grounded second
active-low enable. Its select inputs are `A16:A14`. For the conventional
`0xffxxxx` page, the reachable outputs are:

| `A16:A14` | active-low output | canonical range | downstream role |
|---:|---|---|---|
| `100` | Y4 `/RVF` | `0xff0000-0xff3fff` | low mailbox/control/read bank |
| `101` | Y5 | `0xff4000-0xff7fff` | qualified DSP program/direct-I/O path |
| `110` | Y6 | `0xff8000-0xffbfff` | qualified communication RAM |
| `111` | Y7 `/RAM` | `0xffc000-0xffffff` | local 68000 SRAM |

`A22:A17` do not reach `30P`, so each row has 64 physical high-half aliases.
Y5 and Y6 pass through ALS32 `95L` with `/RVAS`, producing `/320RAM` and
`/320COM`. Y7 drives the local SRAM `/CS1` pins directly; their `/CS2` pins
receive pulled-high `PR3`. This is an address-selection distinction, not an
arbitrary wait mechanism. **Confidence: VERIFIED_PRIMARY.**

## Y5 program/direct-I/O subdecode

The 16 KiB Y5 bank is not one undifferentiated program-RAM alias. Sheet 5
generates four buffered controls, and sheet 4 passes them through LS244 `80L`
only while `/320RAM` is selected:

```text
/NRCE  = NOT(RVAS AND NOT A13)
/NPWE  = NOT(RVA AND /RWNB AND A13)
/NPDEN = NOT(RVAS AND RWNB AND A13)
```

Here `/RWNB=NOT RWN`, `RWNB=RWN`, and `RVAS` is the active-high complement of
`/RVAS`. Therefore:

- `0xff4000-0xff5fff` (`A13=0`) selects the 4K-by-16 DSP program RAM, using
  host `A12:A1` as its word address;
- `0xff6000-0xff7fff` (`A13=1`) sends a write pulse as `/PWE` or a held read
  enable as `/PDEN` into the TMS-side physical address/I/O decode; and
- neither upper/lower host data strobe enters these whole-word program/direct-
  I/O controls.

The final direct-I/O target still depends on the TMS-side `RA` decode. In
particular, this section does not claim that every upper-half address is a
verified eight-way I/O alias merely because MAME masks its handler offset with
seven. **Confidence: VERIFIED_PRIMARY for the raw controls and canonical
split; direct-I/O alias behavior outside canonical low offsets is not yet
qualified.**

## Local SRAM and byte lanes

The two `6264D15` devices at `85N` and `60N` supply the upper and lower bytes.
They share CPU `A1:A13`, `/RAM`, and `/RWNB`, forming 8K sixteen-bit words at
the canonical `0xffc000-0xffffff` range. ALS32 `30R` produces:

```text
/RWS = RWN OR /RVAS
/WEU = /UDS OR /RWS
/WEL = /LDS OR /RWS
```

`/RWNB=NOT RWN` drives both `/OE` pins. A selected read consequently drives
all `D15:D0`, independent of `/UDS` and `/LDS`; a write can update the upper
and lower 6264 slices independently. CPU `A22:A14` do not reach the SRAM word
address, although Y7 must still be selected. **Confidence: VERIFIED_PRIMARY
for Boolean controls, address projection, and lane wiring; no SRAM AC timing
claim is made.**

## MAME comparison

Pinned MAME declares canonical windows at `0x000000-0x01ffff`,
`0xff0000-0xff3fff`, `0xff4000-0xff5fff`, `0xff6000-0xff7fff`,
`0xff8000-0xffbfff`, and `0xffc000-0xffffff`. Its Hard Drivin' sets load one
`0x8000`-byte even EPROM and one `0x8000`-byte odd EPROM into a `0x20000`-byte
region. The 64 KiB populated payload corroborates the two drawn 27256 devices,
but the emulator's 128 KiB declared ROM window and omission of the broad
`A23=0`/high-bank aliases do not reproduce the physical gates. Its direct-I/O
handlers also use `offset & 7`, which is not by itself proof of every physical
upper-Y5 alias. These differences are recorded as `SC-034`; canonical
software behavior remains useful but cannot replace the schematic decode.

## RTL, verification, and synthesis

`rtl/wrappers/hard_drivin_sound_local_memory_decode.sv` is a storage-free
combinational transcription. It exposes all eight raw LS138 outputs, ROM and
local-RAM selects, `/320RAM` and `/320COM`, the Y5 program/direct-I/O
controls, local byte write enables, complete-word read masks, and exact
populated ROM/program/local-RAM word-address projections.

`tb_hard_drivin_sound_local_memory_decode` exhausts 131,072 combinations of
both `/AS` states, both `RVA` states, both `/RVAS` states, both `A23` values,
all 64 ignored `A22:A17` aliases, all eight `A16:A14` banks, both values of
subdecode `A13`, both transfer directions, and all four
`/UDS`/`/LDS` combinations. Directed projections
separately verify ignored ROM and SRAM address bits. The test assigns no
memory contents or open-bus value.

Yosys 0.67+111 reports 56 abstract combinational cells, 17 retained checks,
no memory or latch, and zero structural problems. This evidence qualifies the
Boolean decode only; it is not a raw-pin bridge, SRAM/EPROM model, Cyclone V
fit, or electrical timing result.
