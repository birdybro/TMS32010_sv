# Driver Sound sample-ROM population audit

## Result

A044427 Rev A establishes a sparse twelve-block physical address space; the
socket rows are not packed automatically. Atari's October-1990 Race Drivin'
deluxe-cockpit upgrade instructions then provide primary field-installation
evidence for one later configuration:

- the existing A-row sample set retains block positions 0-3, with
  `136052-3125` required at `45A`/block 2 when it is not already present; and
- new Race Drivin' sample `136077-1017` is installed at `45C`, which the
  schematic decodes as `/SR8`/block 8.

Pinned MAME instead appends the `45C` image directly after blocks 0-3 at
region offset `0x40000`, so its port-6 value 4 reaches those bytes. That is not
the physical socket order and is recorded as `SC-044`. No primary source
reviewed here assigns a ROM to block 4/`20A` for the kit.

This is **VERIFIED_PRIMARY for the A044427 socket/block matrix and the TM-356
upgrade locations**. It remains **UNKNOWN for every factory assembly and for
the electrical value of an absent selection**. Installation instructions are
authoritative for the field procedure they describe, not proof that every
surviving `A046491-02` board was upgraded correctly or left unmodified.

## Primary socket/block matrix

A044427 sheet 6 connects one 64K-byte socket to each active-low select. The
complete C row is marked `NOT LOADED` on the Rev-A drawing:

| block-latch value | decoded select | socket | Rev-A drawing population |
|---:|---|---|---|
| 0 | `/SR0` | `65A` | drawn |
| 1 | `/SR1` | `55A` | drawn |
| 2 | `/SR2` | `45A` | drawn |
| 3 | `/SR3` | `30A` | drawn |
| 4 | `/SR4` | `20A` | drawn |
| 5 | `/SR5` | `5A` | drawn |
| 6 | `/SR6` | `65C` | `NOT LOADED` row |
| 7 | `/SR7` | `55C` | `NOT LOADED` row |
| 8 | `/SR8` | `45C` | `NOT LOADED` row |
| 9 | `/SR9` | `30C` | `NOT LOADED` row |
| 10 | `/SR10` | `20C` | `NOT LOADED` row |
| 11 | `/SR11` | `5C` | `NOT LOADED` row |
| 12-15 | none | none | no connected LS138 output |

Every socket receives `SA15:SA0`; there is no concatenated or fall-through
address from one socket to the next [atari-driver-sound-board-schematic,
drawing A044427 Rev A, sheets 5-6 of 10, PDF pp. 9-12].

The row-wide `NOT LOADED` notation describes the Rev-A drawing population.
It is not a prohibition on later field population: TM-356 explicitly adds
`45C` on an upgrade board.

## Race Drivin' deluxe-cockpit upgrade evidence

TM-356 Figure 1-3 identifies the kit's Driver Sound assembly as
`A046491-02`. Its EPROM-installation section says the software-update devices
are supplied in the kit and Figure 1-7 places the Driver Sound parts as
follows:

| socket | Atari part | role established here |
|---|---|---|
| `70N` | `136077-1032` | local-68000 program upper/even lane |
| `45N` | `136077-1033` | local-68000 program lower/odd lane |
| `45A` | `136052-3125` | required sample replacement if not already present |
| `45C` | `136077-1017` | newly installed Race Drivin' sample block 8 |

The same figure instructs the technician to move the program-ROM jumper to
`E2`. This provides primary field-configuration evidence for `OQ-034`, but it
does not establish the unused halves of MAME's shorter program-lane dumps.
The figure also distinguishes a 256K/512K selection at an unlabeled board
option. The reviewed schematic and installation text do not identify that
option's complete circuit, so no extra sample-ROM address behavior is inferred
from the callout [atari-race-drivin-upgrade-kit-tm356-first, printed
pp. 1-5, 1-6, and 1-10, PDF pp. 13, 14, and 18].

## Pinned MAME comparison

The pinned declarations use a packed byte region rather than twelve physical
slots:

| software family | packed offsets | physical filename labels |
|---|---|---|
| Hard Drivin' | `0x00000-0x3ffff` | `65A`, `55A`, `45A`, `30A` |
| Hard Drivin' Compact | `0x00000-0x3ffff` | same, with `3125.45A` at block 2 |
| Race Drivin' | `0x00000-0x4ffff` | same first four plus `1017.45C` at offset `0x40000` |

The port-6 handler forms `(data & 15) << 16`, so MAME offset `0x40000` is
logical block 4. A044427 plus TM-356 instead make `45C` logical block 8. The
nearby MAME comment `10*128k` also disagrees with the declared `0x50000` region
and five `0x10000`-byte loads; it supplies no alternate wiring evidence
[mame-harddriv-driver-030fefc, Hard Drivin', Hard Drivin' Compact, and Race
Drivin' `serialroms` declarations; mame-harddriv-audio-030fefc,
`hdsnddsp_soundaddr_w` and `hdsnddsp_rom_r`].

An authorized DSP trace can now distinguish the mappings without publishing
content: record every port-6 write and following port-0 read. A Race Drivin'
access to the added device should select block 8 under the primary wiring. A
block-4 trace would require a documented board decode change, firmware/image
mismatch, or emulator-specific workaround before it could override the two
primary sources.

## Authorized image inventory

The repository helper accepts explicit physical sockets, not packed offsets:

```sh
python3 -m tools.reference.hard_drivin_sample_roms \
  --socket 65A=/authorized/path/136052-1123.bin \
  --socket 45C=/authorized/path/136077-1017.bin \
  --pretty
```

It accepts exactly 64 KiB per supplied socket, hashes each file, maps sockets
to the twelve-bit wrapper presence mask, and reports blocks 12-15 as
undecoded. It never prints bytes, downloads, executes, or disassembles game
content. Because a file is not a board inspection, every report leaves
`physical_population_proven` false.

## Physical and firmware closure

1. Record cabinet, game/version, conversion-kit history, Sound PCB assembly
   and bare-board revision, serial number, both board faces, socket labels,
   jumpers, rework, and empty sockets.
2. Verify `45A`, `20A`, and `45C` continuity to `/SR2`, `/SR4`, and `/SR8`
   respectively on the identified powered-off board before generalizing the
   Rev-A drawing to another revision.
3. Read installed sample devices twice with a trusted programmer, record
   device markings/tool/version/hashes, then run the socket-based helper.
4. With authorized program images, trace port-6 block writes and port-0 reads
   without committing ROM-derived disassembly or sample bytes.
5. If an absent-block electrical value matters, capture `SD14:SD7` and
   `TDI15:TDI7` while deliberately selecting one verified empty socket. A
   stable zero, one, retained, or noisy value must be reported as a measured
   board-specific result, not a schematic guarantee.

## Implementation policy

- Keep `sound_rom_present_i[11:0]` sparse and physical. For the documented
  Race Drivin' upgrade, `45C` sets bit 8, never bit 4.
- Do not compact supplied images by file count or MAME region offset.
- Do not make a Race Drivin' population the generic Hard Drivin' default.
- Continue to reject absent and undecoded selections without acknowledging a
  byte. No open-bus value is established.
- Keep all authorized images, traces, and generated reports outside Git.
- `OQ-026` remains `PARTIALLY_RESOLVED_PRIMARY`; exact factory/variant
  population and absent-bus behavior remain open.
