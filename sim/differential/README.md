# Differential verification

The current differential boundary compares the independent Python model with
the partial SystemVerilog core over a deterministic mixed stream of the
41 supported one-cycle instructions. A focused BANZ trace adds the first
two-cycle instruction and checks both branch outcomes; a focused B trace
checks unconditional two-cycle control flow. A family trace checks taken and
untaken cases for all six accumulator conditions; a BV trace checks its
taken-path OV clear and untaken path. A BIOZ differential checks both raw
active-low input levels, and a CALL trace checks nested return-address pushes.
The tests check
pre-execution PC/opcode,
post-execution PC, accumulator, T, P, overflow flag/mode, retirement, illegal
indication, and cumulative
architectural cycles. The expanded slice also compares both auxiliary
registers, all four stack levels, and the ARP/DP/INTM status fields.
`ADD`/`ADDH`/`ADDS`/`AND`/`DMOV`/`LAC`/`LAR`/`LDP`/`LST`/`LT`/`LTA`/`LTD`/`MPY`/`OR`/`SACL`/`SACH`/`SAR`/`SST`/`SUB`/`SUBC`/`SUBH`/`SUBS`/
`XOR`/`ZALH`/`ZALS` streams use identical deterministic 144-word RAM images
and cover valid
direct/indirect addresses, reads, writes, shifts, and auxiliary-register
post-modification. The test compares every final RAM word after 512
instructions.
Direct and indirect `MAR` cases additionally verify AR/ARP modification while
both logical data-transaction strobes remain inactive.
LDP cases compare its logical reads, DP result, and indirect post-modification.
LT cases compare its logical reads, full-width T result, and indirect
post-modification.
LTA cases additionally compare previous-P accumulation, OV/OVM outcomes, and
the simultaneous T result through the same address/update path.
LTD cases additionally compare the source read, distinct next-address write,
unchanged copied data, simultaneous T/ACC results, OV/OVM outcomes, and final
RAM contents.
DMOV cases compare the same source/destination transaction topology and final
RAM without the LTD T-register or accumulator effects.
MPY cases compare logical reads, signed P results, the most-negative hardware
exception, and indirect post-modification.
MPYK cases compare signed immediate endpoints and P results while requiring
no logical data-memory transaction.
PAC cases compare the full-width ACC result with unchanged P and inactive
logical data-memory strobes.
APAC cases compare full-width addition, sticky OV, OVM-controlled wrap or
saturation, unchanged P, and inactive logical data-memory strobes.
SPAC cases compare full-width subtraction with the same status/result policy,
unchanged P, and inactive logical data-memory strobes.
ABS cases compare signed magnitude results, OVM-selected most-negative
behavior, preserved OV, and inactive logical data-memory strobes.
SST cases compare forced-page direct destinations, old-ARP indirect capture,
post-update AR/ARP state, exact packed status including reserved bit 1,
logical writes, one-cycle totals, and final RAM.
DINT/EINT cases compare exact fixed words, one-cycle `INTM` set/clear effects,
and inactive logical data-memory strobes. No interrupt request or entry is
modeled on either side.
LST cases compare logical reads, all loaded status fields, preserved INTM,
old-address and counter-update ordering, and memory-word ARP precedence over
an encoded next ARP. That last comparison is provisional original-part
behavior under `OQ-015`, not independent proof from two implementations using
the same policy.
SUBC cases are followed by NOP, compare both conditional ACC paths, logical
reads and address updates, and include 16 seeded-random direct/indirect pairs.
Both sides use the same provisional intermediate-overflow policy, so this is
consistency evidence, not independent proof of `OQ-017` or `OQ-018`.
SUBH cases compare high-half-aligned source subtraction, low-half retention,
sticky OV/OVM outcomes, logical reads, and common indirect address updates.
ADDH cases compare modulo high-half addition, unconditional low-half and
OV/OVM preservation across signed boundaries, logical reads, and common
indirect updates. This is consistency evidence for the CORROBORATED
`SC-017`/`OQ-011` policy, not physical-silicon verification.

The focused TBLR/TBLW differential chains a table read and self-modifying
table write. It compares opcode, discarded-prefetch, table-transfer, and
repeated-following program addresses; per-cycle retirement; MEN/write
direction and write data; cumulative cycles; RAM and program-memory results;
PC; and all four stack levels.

The focused BANZ trace compares logical program transaction addresses
`PC,PC+1`, per-cycle retirement, cumulative cycle count, branch/fallthrough
PC, and low-nine-bit counter results for taken and untaken cases. The model
steps at instruction boundaries while the RTL exposes both machine cycles, so
the comparison deliberately aligns state only at the second-cycle commit.

The focused B trace applies the same boundary alignment to two successive
branches, checking opcode/target transaction addresses, skipped fall-through
words, retirement, cycles, target PCs, and preserved accumulator state.

The accumulator-branch trace chains all six mnemonics through one taken and
one untaken case each. It compares every opcode/target program transaction,
skipped words, per-cycle retirement, cumulative cycles, PC, and ACC at every
instruction commit. Zero, positive-one, and negative-one setup values
distinguish every predicate.

The focused BV trace loads OV from an internal status word, executes a taken
BV that clears OV, then an untaken BV. It compares both program transactions
per branch, per-cycle OV, retirement, PC, and cumulative cycles.

The focused BIOZ differential runs once with BIO low and once with BIO high.
It compares both mandatory program reads, second-cycle retirement, target or
fallthrough PC, and cumulative cycles. Separate native tests change the pin
between its two samples to verify non-latched ownership.

The focused CALL differential chains two calls and a target NOP. It compares
both opcode/target reads, no first-cycle retirement, cumulative cycles, target
PC, and `[top, level_1, level_2, bottom]` stack state at each instruction
commit.

The ROM-free MAME adapter generates a strict debugger `trace` action, parses
PC/ACC/P/T/AR/STR/stack boundary state, normalizes MAME's bottom-to-top stack
array into the project's top-first convention, and compares model post-state
N with MAME pre-state N+1. Seven synthetic regressions verify parsing, width
and format rejection, status extraction, stack ordering, mandatory
following-row alignment, exact row counts, interrupt-pseudo-step rejection,
strict model state widths/types, safe command generation, mismatch
diagnostics, and successful CLI operation. The adapter records the exact
pinned source commit and separately hashes the installed
`0.287 (mame0287-dirty)` package binary. It does not claim that binary is a
build of the pinned commit. An actual Hard Drivin' trace remains unrun because
no authorized ROM set is present. See `tools/reference/README.md` and
`artifacts/mame_oracle.md`.

The 512-instruction stream is model/RTL functional evidence only. The focused
B/BANZ/BIOZ/BV/CALL/family/IN/OUT/TBLR/TBLW differentials supply logical
per-cycle evidence; their separate native phase tests supply the physical
subphase relationship. Neither result nor the MAME architectural-boundary
adapter qualifies the remaining pipeline or pin timing.

Failing seeds must be preserved as regression fixtures when randomized
coverage expands.
