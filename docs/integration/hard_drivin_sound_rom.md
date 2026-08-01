# Hard Drivin' sound-ROM path

## Scope and terminology

This document transcribes the A044427 Rev-A path from the port-6 block latch
and shared sound-address counters through the sample ROMs and the TMS32010
port-0 input buffers. Despite the `serialroms` name in pinned MAME and older
project shorthand, the reviewed board path is not a serial shifter. It selects
one parallel byte-wide ROM position, applies `SA15:SA0` directly as its address,
and buffers the resulting byte into an aligned 16-bit TMS input word.

No game ROM data is distributed or required for the wiring qualification.

## Block and byte address

Port 6 clocks `TD3:TD0` into LS374 `100C`; its outputs are `SCD:SCA`. The
output decode names this active-low clock `/SBLOCK`, so the LS374's documented
positive-edge behavior captures the nibble on the trailing edge of a physical
port-6 write. The drawing provides no clear input to this latch
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 5 of 10,
PDF p. 9; ti-sn74ls374-datasheet-sdls165b, description and pinout, printed
pp. 1-3]. **Confidence: VERIFIED_PRIMARY.**

`SCC:SCA` drive the select inputs of LS138 devices `95A` and `95C`. `SCD=0`
enables `95A`, whose active-low outputs select `/SR0` through `/SR7`; `SCD=1`
enables `95C`, of which only outputs `/SR8` through `/SR11` are connected.
Blocks 12-15 therefore select no drawn ROM. TI's component data sheet confirms
the active-high/active-low enable combination and one-active-low-output decode
[atari-driver-sound-board-schematic, sheet 5 of 10, PDF p. 9;
ti-sn74ls138-datasheet, description and function table, printed pp. 1-2].
**Confidence: VERIFIED_PRIMARY.**

Every drawn ROM receives all sixteen `SA15:SA0` lines and exposes eight data
outputs named `SD14:SD7`; output enable is grounded active while the decoded
`/SRn` drives chip enable. The circuit therefore defines a 64K-byte address
window per selected block and up to twelve sparse block positions:

| blocks | sockets in increasing block order | Rev-A drawing note |
|---|---|---|
| 0-5 | `65A`, `55A`, `45A`, `30A`, `20A`, `5A` | drawn |
| 6-11 | `65C`, `55C`, `45C`, `30C`, `20C`, `5C` | complete row `NOT LOADED` |
| 12-15 | none | no connected select |

TM-356 provides primary field-upgrade evidence beyond the Rev-A drawing. Its
Figure 1-7 installs `136052-3125` at `45A`/block 2 when needed and adds
`136077-1017` at `45C`/block 8 on the identified `A046491-02` Driver Sound
assembly. Pinned MAME declares the same physical filenames, but packs the
`45C` file at logical offset `0x40000`/block 4. This is `SC-044`, not an
alternate board map [atari-driver-sound-board-schematic, sheet 6 of 10, PDF
pp. 11-12; atari-race-drivin-upgrade-kit-tm356-first, Figure 1-3 and Figure
1-7, printed pp. 1-5 and 1-10, PDF pp. 13 and 18;
mame-harddriv-driver-030fefc, Hard Drivin', Hard Drivin' Compact, and Race
Drivin' `serialroms` regions].

**Confidence: VERIFIED_PRIMARY for board capacity/wiring and the documented
Race Drivin' upgrade sockets; CORROBORATED for MAME's four-file Hard Drivin'
declarations; UNKNOWN for every factory/variant population.** The complete
matrix, conflict, authorized inventory, and closure procedure are in
`docs/research/hard_drivin_sample_rom_population_audit.md`. An absent-socket
read remains `OQ-026`.

## TMS input-word mapping

With port 0 selected, active-low `/SROM` enables LS244 `35E` and `20H`. The
eight ROM bits are defined here as `rom_byte[7:0] = SD14:SD7`. The drawing
wires them as follows:

| TMS input bits | Board source |
|---|---|
| `TDI15` | `SD14` / `rom_byte[7]` |
| `TDI14:TDI7` | `SD14:SD7` / `rom_byte[7:0]` |
| `TDI6:TDI0` | ground |

Thus the physical input word is:

```text
{{2{rom_byte[7]}}, rom_byte[6:0], 7'b0000000}
```

This is a signed eight-bit sample shifted left seven places, including the
duplicated sign bit at `TDI15`. The LS244 is a non-inverting buffer when its
active-low enable is asserted and otherwise presents high impedance
[atari-driver-sound-board-schematic, sheet 5 of 10, PDF p. 9;
ti-snx4ls24x-datasheet, detailed description and Table 3, printed pp. 11-13].
**Confidence: VERIFIED_PRIMARY.**

Pinned MAME instead returns an unsigned `uint8_t` region byte shifted left by
seven. It therefore matches bytes 0x00-0x7f but leaves bit 15 clear for bytes
0x80-0xff, contrary to the duplicated `SD14` wire. For example, physical byte
`0x80` maps to `0xc000`, while the pinned handler returns `0x4000`. This is the
secondary-source conflict `SC-026`; board RTL must follow the schematic.

## Address side effects and invalid selections

The ROM sees the pre-increment `SA15:SA0` value during a port-0 read. The
trailing `/PDEN` edge then advances all four LS191 counters exactly once, as
already established in `hard_drivin_communication_ram.md`. Port 6 changes only
the separate block latch, and port 7 loads only the sixteen-bit address.

When blocks 12-15 or an unpopulated `/SRn` position are selected, no ROM drives
`SD14:SD7`. The LS244 data inputs then have no defined value in the reviewed
drawing. Pinned MAME's out-of-region zero is a protective software convention,
not verified hardware behavior. A digital adapter must report or hold an
invalid/unpopulated selection unless its integration configuration explicitly
declares that block present.

Do not compact sparse C-row sockets. In particular, physical `45C` is block 8,
not the next packed block after the four Hard Drivin' images.

## FPGA adaptation requirements

A same-clock FPGA adapter may expose a byte-wide ROM callback or infer storage
behind the board wrapper. It must:

1. accept explicit block-presence metadata and never infer that every one of
   the sixteen nibble values is populated;
2. address a present block with the pre-increment `sound_address[15:0]`;
3. return `{{2{byte[7]}}, byte[6:0], 7'b0}` to processor port 0;
4. acknowledge only a present, valid block/address response;
5. rely on the shared physical I/O commit pulse to increment the address once,
   rather than maintaining a second offset;
6. preserve explicit block/address validity across processor reset according
   to the already qualified board state; and
7. keep copyrighted ROM images outside the repository and accept only authorized user-supplied data.

These are digital wiring requirements, not ROM access-time, LS244 propagation,
or complete MiSTer memory-system timing claims.

Authorized integrations can derive a sparse presence mask without committing
content by running `python3 -m tools.reference.hard_drivin_sample_roms` with
one or more `--socket SOCKET=PATH` arguments. The tool accepts only the exact
64-KiB block size, emits hashes and physical block numbers, and never treats a
provided file as proof of an installed device.

## Implemented FPGA boundary

`rtl/wrappers/hard_drivin_sound_rom_path.sv` is a storage-free combinational
adapter implementing the requirements above. `sound_rom_present_i[11:0]`
declares only the positions supplied by an authorized integration. A valid
processor port-0 read exposes the exact block/address byte callback and waits
for `sound_rom_byte_ready_i`; an uncleared address, uncleared block latch,
block 12-15, or declared-absent block raises
`sound_rom_selection_invalid_o` and is never acknowledged. The adapter does
not guess an open-bus value.

The standalone directed test exercises all sixteen nibble selections, every
one of the 65,536 pre-increment addresses, all 256 byte values, presence and
validity combinations, response stalls, and non-port-0 isolation. Yosys
0.67+111 reports 18 abstract combinational cells including three retained
checks, no memory, no latch, and zero structural problems.

`hard_drivin_sound_mister` now uses this adapter for processor port 0 and the
communication path for port 1; its generic external I/O read response cannot
override either target. The integrated ROM-free smoke holds a block-3/address-
`0x3457` callback unready for three clocks, returns byte `0xd5` as physical
word `0xea80`, commits exactly once, and then advances the shared address. No
Atari sample byte or game ROM is present: `0xd5` is project-authored synthetic
test data.
