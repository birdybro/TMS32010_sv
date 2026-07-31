# Differential verification

The current differential boundary compares the independent Python model with
the partial SystemVerilog core over a deterministic mixed stream of the
37 supported one-cycle instructions. A focused BANZ trace adds the first
two-cycle instruction and checks both branch outcomes; a focused B trace
checks unconditional two-cycle control flow. A family trace checks taken and
untaken cases for all six accumulator conditions; a BV trace checks its
taken-path OV clear and untaken path. The tests check
pre-execution PC/opcode,
post-execution PC, accumulator, T, P, overflow flag/mode, retirement, illegal
indication, and cumulative
architectural cycles. The expanded slice also compares both auxiliary
registers and the ARP/DP/INTM status fields.
`ADD`/`ADDS`/`AND`/`DMOV`/`LAC`/`LAR`/`LDP`/`LST`/`LT`/`LTA`/`LTD`/`MPY`/`OR`/`SACL`/`SACH`/`SAR`/`SUB`/`SUBC`/`SUBS`/
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

The 512-instruction stream is model/RTL functional evidence only. The focused
B/BANZ/BV/family differentials supply logical per-cycle evidence; their separate native
phase test supplies the physical subphase relationship. Neither result
qualifies the remaining pipeline. MAME comparison is not yet implemented.

Failing seeds must be preserved as regression fixtures when randomized
coverage expands.
