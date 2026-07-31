# Differential verification

The current differential boundary compares the independent Python model with
the partial SystemVerilog core over a deterministic mixed stream of the
twenty-nine supported instructions. It checks pre-execution PC/opcode,
post-execution PC, accumulator, T, P, overflow flag/mode, retirement, illegal
indication, and cumulative
architectural cycles. The expanded slice also compares both auxiliary
registers and the ARP/DP status fields.
`ADD`/`ADDS`/`AND`/`LAC`/`LAR`/`LDP`/`LT`/`MPY`/`OR`/`SACL`/`SACH`/`SAR`/`SUB`/`SUBS`/
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
MPY cases compare logical reads, signed P results, the most-negative hardware
exception, and indirect post-modification.
MPYK cases compare signed immediate endpoints and P results while requiring
no logical data-memory transaction.
PAC cases compare the full-width ACC result with unchanged P and inactive
logical data-memory strobes.
APAC cases compare full-width addition, sticky OV, OVM-controlled wrap or
saturation, unchanged P, and inactive logical data-memory strobes.

This is model/RTL functional evidence only. Both sides currently use a logical
instruction-boundary program interface, so the test supplies no pin-phase or
cycle-accuracy evidence. MAME comparison is not yet implemented.

Failing seeds must be preserved as regression fixtures when randomized
coverage expands.
