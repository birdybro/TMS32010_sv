# Differential verification

The current differential boundary compares the independent Python model with
the partial SystemVerilog core over a deterministic mixed stream of the nine
supported instructions. It checks pre-execution PC/opcode, post-execution PC,
accumulator, overflow mode, retirement, illegal indication, and cumulative
architectural cycles. The expanded slice also compares both auxiliary
registers and the ARP/DP status fields. `LAC` streams use identical
deterministic 144-word RAM images and cover valid direct/indirect addresses,
shifts, and auxiliary-register post-modification.

This is model/RTL functional evidence only. Both sides currently use a logical
instruction-boundary program interface, so the test supplies no pin-phase or
cycle-accuracy evidence. MAME comparison is not yet implemented.

Failing seeds must be preserved as regression fixtures when randomized
coverage expands.
