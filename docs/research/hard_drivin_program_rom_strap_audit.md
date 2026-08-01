# Driver Sound local program-ROM strap audit

## Result

A044427 Rev A implements a real 27256/27512 capacity option, but the reviewed
Atari publications do not establish the fitted link or EPROM capacity for each
Sound PCB assembly.

The drawing connects both program-EPROM pin-1 nodes to one of two alternative
links: `E1` reaches `+5 V`, and `E2` reaches local-MC68000 `A16`. It draws a
`27256D20` at `70N` for `D15:D8` and another at `45N` for `D7:D0`. A
contemporaneous AMD family data sheet identifies pin 1 as `VPP` on its 32Kx8
27256 and as the highest address input `A15` on its 64Kx8 27512; its 27256
read table requires `VPP=VCC`. Therefore:

- `E1` is the electrically required choice for the drawing's 27256
  configuration, producing a 64 KiB interleaved image addressed by CPU
  `A15:A1`;
- `E2` is the intended 27512 choice, producing a 128 KiB interleaved image
  addressed by CPU `A16:A1`; and
- fitting both links would short CPU `A16` to `+5 V` and is not a legal
  configuration.

This is **VERIFIED_PRIMARY for the option topology and device-family
requirements**. Atari TM-356 additionally makes E2 the prescribed
Race Drivin' deluxe-cockpit field-upgrade configuration on an identified
`A046491-02` assembly. Actual factory population, other variants, correct
field execution, and EPROM manufacturer/capacity on a surviving board remain
**UNKNOWN**. The schematic symbols and installation instruction are not a
physical inspection.

## Primary circuit and device evidence

ALS32 `30R` makes `/ROMCE=A23 OR /AS` for both byte lanes. The EPROMs share
`/CE` and `/OE`; `70N` drives host `D15:D8` and contains even byte addresses,
while `45N` drives `D7:D0` and contains odd byte addresses. CPU `A1:A15`
reach the fifteen ordinary address inputs on both parts. The common pin-1 net
is the sole capacity option [atari-driver-sound-board-schematic, drawing
A044427 Rev A, sheet 3 of 10, PDF pp. 5-6].

AMD's May-1986 8-Bit EPROM Family table gives these compatible 28-pin
assignments:

| device | organization | pin 1 | complete two-lane board image | CPU address bits |
|---|---:|---|---:|---|
| Am27256 | 32Kx8 | `VPP` | 64 KiB | `A15:A1` |
| Am27512 | 64Kx8 | `A15` | 128 KiB | `A16:A1` |

For an Am27256 read, the mode table explicitly requires `VPP=VCC`; for an
Am27512 read, pin 1 participates as an address input. AMD is not evidence of
the installed vendor—the Atari drawing does not name one—but it is
contemporaneous manufacturer evidence for the documented device classes and
pin-compatible option [amd-bipolar-mos-memories-databook-1986, publication
08005 Rev A, printed pp. 6-15 through 6-21, PDF pp. 821-827].

## Assembly evidence boundary

TM-327 and TM-329 identify the Hard Drivin' Sound PCB Assembly as
`A046491-01`. TM-351 identifies the Race Drivin' cockpit Sound PCB Assembly as
`A046491-02`. None of those reviewed parts sections contains the Sound PCB
component BOM, E1/E2 option table, or installed program-EPROM type. The board
schematic is drawing `A044427`, while cabinet documents label the external
block `044427-XX`; an assembly suffix cannot be converted into a strap value
without an assembly drawing, BOM, ECO, or physical evidence
[atari-hard-drivin-manual-tm327-third, printed pp. 4-4 to 4-5, PDF pp. 78-79;
atari-hard-drivin-compact-manual-tm329-second, printed p. 4-3, PDF p. 67;
atari-race-drivin-cockpit-manual-tm351-second, printed p. 4-5, PDF p. 79].

TM-356 closes one narrower field configuration. Figure 1-3 identifies
`A046491-02`, while Figure 1-7 installs Race Drivin' program parts
`136077-1032` at `70N` and `136077-1033` at `45N` and explicitly says to move
the jumper to `E2`. The same figure does not characterize unused program-ROM
halves, and pinned MAME still declares only `0x8000` bytes per lane. Thus it
proves the prescribed E2 upgrade but not complete device contents or every
production assembly [atari-race-drivin-upgrade-kit-tm356-first, Figure 1-3
and Figure 1-7, printed pp. 1-5 and 1-10, PDF pp. 13 and 18].

## Pinned MAME inventory

Pinned MAME is secondary population evidence, not a solder-link record. Its
current declarations contain these distinct program-image families:

| software family | 70N/even file | 45N/odd file | bytes per lane | implication |
|---|---|---|---:|---|
| Hard Drivin' cockpit releases | `136052-1122.70n` | `136052-1121.45n` | `0x8000` | 27256-sized |
| Hard Drivin' compact releases | `136052-3122.70n` | `136052-3121.45n` | `0x8000` | 27256-sized |
| Race Drivin' releases | `136077-1032.70n` | `136077-1033.45n` | `0x8000` | 27256-sized |
| Race Drivin' Panorama prototype | `rdps1032.bin` | `rdps1033.bin` | `0x10000` | 27512-sized declaration |

The released-set declarations corroborate a 64 KiB combined payload. They do
not prove E1 on a physical board because a dump file records contents, not
continuity or a fitted link. The Panorama prototype declaration is evidence
that a 128 KiB Driver Sound image existed in the emulator corpus and makes the
E2 option operationally relevant. It does not name a Sound PCB assembly
revision or prove that either 64 KiB lane has distinct upper/lower halves.
MAME's Race Drivin' Compact board-layout comment locates
`136077-1032`/`1033` at 70N/45N but likewise records no E1/E2 population
[mame-harddriv-driver-030fefc, Driver Sound PCB layout comment and Hard
Drivin', Hard Drivin' Compact, Race Drivin', and `racedrivpan` soundcpu ROM
declarations]. **Confidence: CORROBORATED for declared file names and sizes;
UNKNOWN for their physical strap/assembly mapping.**

## Authorized image audit

An authorized user can inspect locally held lane images without placing them
in the repository:

```sh
python3 -m tools.reference.hard_drivin_program_roms \
  --upper-even /authorized/path/70n.bin \
  --lower-odd /authorized/path/45n.bin \
  --pretty
```

The tool accepts only `0x8000`- or `0x10000`-byte lanes, verifies matching
sizes, emits SHA-256 hashes, produces a hash of the correctly interleaved
image, and compares the two 32 KiB halves of each 64 KiB lane. It neither
prints ROM bytes nor downloads, executes, or disassembles game content.

- Distinct halves in either 64 KiB lane prove that CPU `A16` is
  information-bearing for that image and that E2 is required to execute all
  of it.
- Equal halves do not distinguish a deliberately repeated 27512 from a 64 KiB
  readout of a mirrored 27256.
- A 32 KiB lane is merely 27256-sized. It does not prove E1 on a board.

The report consequently always leaves `physical_strap_proven` false.

## Physical closure procedure

1. Record cabinet/game, Sound PCB assembly label (`A046491-01` or `-02`), bare
   PCB/drawing revision, serial number, ROM labels, socket positions, rework,
   and both board faces in uncropped photographs.
2. With power removed and both EPROMs removed, photograph E1/E2 closely and
   measure continuity from their common node to EPROM pin 1, `+5 V`, CPU
   `A16`, and ground. Confirm that exactly one link is fitted.
3. Identify each EPROM's complete manufacturer/device marking before using
   its exact data sheet. Do not infer capacity from an Atari paper label.
4. Read each device twice in a trusted programmer, retain tool/version and raw
   hashes, and require identical reads before running the repository analyzer.
5. If safe and necessary, capture CPU `A16`, both EPROM pin-1 nodes, `/CE`,
   `/OE`, and data lanes during controlled reads on both sides of byte address
   `0x010000`. Do not probe a powered UV-EPROM socket without suitable ESD and
   short-circuit precautions.
6. Repeat on independently sourced `-01` and `-02` assemblies before
   generalizing a production population rule.

## Implementation policy

- Retain the current `A15:A1` ROM callback as the A044427 drawn-27256 default
  needed by released Hard Drivin' integration.
- Treat TM-356's E2 requirement as an explicit Race Drivin' upgrade-wrapper
  configuration, never as a silent change to the Hard Drivin' default.
- Do not describe the RTL signal name `populated_rom_word_address_o` as proof
  of a physically inspected population; it is a legacy name for the drawing's
  27256 address projection.
- Do not add a silent A16 address bit. A future 27512 mode must be an explicit
  board-wrapper selection, have a 16-bit word address, and be tested for both
  E1/64-KiB mirroring and E2/128-KiB distinct-half cases.
- Keep authorized images and generated reports untracked.
- `OQ-034` remains `PARTIALLY_RESOLVED_PRIMARY`. No RTL behavior changes are
  justified by this research cycle.
