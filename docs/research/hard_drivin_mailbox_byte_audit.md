# Driver Sound mailbox byte-write audit

## Result

The original MC68000 makes the value captured by either unqualified A044427
mailbox latch pair deterministic for every legal word or byte write:

| MC68000 transfer | asserted strobe | value present on `D15:D0` | word captured by both LS374s |
|---|---|---|---|
| word | `/UDS` and `/LDS` | original 16-bit word | original 16-bit word |
| upper byte | `/UDS` | selected byte on both bus halves | `{2{D15:D8}}` |
| lower byte | `/LDS` | selected byte on both bus halves | `{2{D7:D0}}` |

Motorola marks the duplicated-byte behavior as belonging to the “current implementation.”
This conclusion therefore applies to the original MC68000s
drawn on the Atari boards; it is not a generic promise for later 68k-family
or soft-core replacements [motorola-m68000-users-manual-ninth, Table 3-1 and
its footnote, printed pp. 3-5 through 3-6].

Atari does not byte-qualify either mailbox capture clock. A044427 generates
`/MAINWR` locally and clocks both main-to-sound LS374s from it. The local
sound CPU similarly clocks both sound-to-main LS374s from one `/SOUNDWR`.
Consequently, both directions capture `{byte, byte}` on a byte transfer.
This is **VERIFIED_PRIMARY for the documented original-MC68000 bus value and
the Rev-A latch wiring**. It remains **UNKNOWN whether any authorized game
firmware uses byte writes and for the exact flag result when one asynchronous
write-preset releases at the opposite bus's read-clock edge**.

## Main-system write decode

A044427 does not receive `/MAINWR` as an opaque connector signal. LS138 `20P`
generates it on Y0 from:

- selectors `ERWN`, `EA15`, and `EA14`;
- expansion selection through `/EXTB` and `/ERVAS`;
- asserted `EA18`; and
- deasserted `EA20`, `EA19`, `EA17`, and `EA16`.

Together with SP-327's main-board expansion selection this places the physical
main write alias at `0x840000..0x843fff`. The same LS138 produces `/MAINRD` on
Y4 for reads, `/MAINSTAT` on Y5, and `/SRES` on Y3. The main CPU's `/WEU` and
`/WEL` are buffered onto J7 as `/EWEU` and `/EWEL`, but neither signal enters
LS138 `20P` or the LS374 capture clocks. The complete expansion data bus is
also carried to the sound board [atari-driver-sound-board-schematic, drawing
A044427 Rev A, sheets 1-2 of 10, PDF pp. 1-4;
atari-hard-drivin-schematic-package-sp327, SP-327 sheets 4 and 7, PDF pp. 5
and 8].

This resolves the former “unknown upstream `/MAINWR`” premise. The byte
strobes exist at the connector but the mailbox does not use them.

## Local sound-CPU write decode

A044427 sheet 3 derives `/WEU` and `/WEL` from the local MC68000's UDS/LDS and
R/W signals. Its host-target decode instead produces one `/SOUNDWR`; sheet 2
routes that single net to both LS374 clock inputs and the `SOUNDFLAG` preset.
No byte enable qualifies either latch. The same original-MC68000 duplicated-
byte rule therefore applies on this side [atari-driver-sound-board-schematic,
drawing A044427 Rev A, sheets 2-3 of 10, PDF pp. 3-6].

Pinned MAME's `hdsnd68k_data_w` uses `COMBINE_DATA`, retaining the unselected
byte in emulator state. That is observably different from `{byte, byte}` and
is preserved as `SC-031`; it is not evidence against the primary bus and
latch documentation [mame-harddriv-audio-030fefc,
`hdsnd68k_data_w`].

## Pending-flag collision boundary

Each LS74 flag uses the active-low write strobe as asynchronous preset and the
opposite active-low read strobe as a clock that captures grounded D. TI's
function table makes the ordinary overlap less ambiguous than previously
recorded:

- while preset remains low and clear remains high, Q is high regardless of
  the clock, so a read edge fully inside an asserted write sets the flag;
- write preset and board-reset clear simultaneously low is an invalid
  asynchronous-control combination; and
- the reviewed data sheet gives no recovery/removal constraint or digital
  result for a read edge at write-preset release.

The main and local MC68000 buses are independent, so near-coincident release
and read edges are physically possible even though the software handshake is
intended to avoid them. The same-clock FPGA callback continues to mark a
coincident write/read completion invalid. That is a conservative abstraction
of the unresolved release-edge case, not a claim that every temporal overlap
is unknown or that physical Q becomes zero [ti-sn74ls74a-datasheet-sdls119,
function table and asynchronous-control description, printed pp. 1-3].

## FPGA implementation and verification

`rtl/wrappers/hard_drivin_mc68000_write_word.sv` is a combinational,
board-integration adapter. It preserves word transfers, duplicates either
selected byte, rejects the no-strobe state, and reports whether a valid
transfer was a byte transfer. The local timed `/SOUNDWR` path in
`hard_drivin_sound_mister` uses the adapter. Its existing
`host_timing_partial_sound_write_o` signal now means “accepted physical byte
write observed,” not “write rejected.”

The external main-system callback remains a complete captured-word contract;
it does not yet expose main-bus byte strobes. A future original-MC68000 main
bridge should reuse the same adapter before asserting that callback. A bridge
for a substitute 68k core must either demonstrate the original duplicated
inactive-lane contract or synthesize it explicitly.

`tb_hard_drivin_mc68000_write_word` exhausts all 65,536 data words in word,
upper-byte, and lower-byte modes and checks the no-strobe state. The integrated
board regression checks accepted upper byte `0xab -> 0xabab` and lower byte
`0x34 -> 0x3434`, flag set/read-clear, physical strobe reporting, and callback
isolation. The board-routing BMC proves both symbolic byte orientations and
reaches both covers.

Yosys 0.67+111 reports 39 mapped cells with three retained checks and zero
structural problems for the standalone adapter. The integrated pre-technology
hierarchy reports 3,773 abstract cells, 409 retained checks, six memories, and
zero structural problems. These results qualify only the synchronous FPGA
logic; they are not physical MC68000, LS374, LS74, or CDC timing closure.

## Remaining closure work

1. Audit authorized main and sound program images for actual byte accesses to
   both mailbox aliases without committing ROM-derived content.
2. If collision ordering matters to software, capture `/MAINWR`, `/SOUNDRD`,
   `/SOUNDWR`, `/MAINRD`, reset, and both flag outputs on an identified board,
   including the release-edge neighborhood.
3. Preserve device identity in substitute-CPU qualification; duplicated
   inactive byte lanes are not assumed from the 68k ISA alone.
4. Keep `OQ-031` partially open for firmware use and the exact near-coincident
   asynchronous release/read-clock edge.
