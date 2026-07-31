# Instruction-cycle matrix

## Primary summary

The revision-B instruction summary supplies the following family-level
baseline [ti-tms32010-users-guide-spru001b, Table 3-2, printed pp. 3-5–3-7
(PDF pp. 55–57)]. **Confidence: VERIFIED_PRIMARY.**

| Cycles | Words | Instructions |
|---:|---:|---|
| 1 | 1 | accumulator, auxiliary, T/P/multiply, status/control, and data-memory operations except rows below |
| 2 | 2 | `B BANZ BGEZ BGZ BIOZ BLEZ BLZ BNZ BV BZ CALL` |
| 2 | 1 | `CALA RET PUSH POP IN OUT` |
| 3 | 1 | `TBLR TBLW` |

This is evidence for architectural cycle totals, not yet for pin-level
subphases. Every individual row, addressing mode, conditional outcome, and bus
trace still needs an automated assertion before `TIMING-001` can complete.

The individual `PUSH` and `POP` pages independently confirm two cycles and one
word. Their exact stack results are transcribed in
`docs/architecture/instruction_set.md`, but no automated cycle assertion is
claimed because the native program-bus behavior of the extra internal cycle
remains unresolved under `OQ-016`
[ti-tms32010-users-guide-spru001b, `POP`/`PUSH`, printed pp. 3-49–3-50
(PDF pp. 99–100)]. **Confidence: VERIFIED_PRIMARY for the numeric cycle
count; UNKNOWN for the second-cycle external subphases.**

## Qualified timing tests

The current native-phase integration test observes one complete four-subphase
program-read cycle for every instruction in the thirty-six-instruction subset,
then checks retirement on the falling-edge sample boundary. Directed `ADD`,
`ADDS`, `AND`, `DMOV`, `LAC`, `LAR`, `OR`, `SACL`, `SACH`, `SAR`, `SUB`, `SUBS`, `XOR`,
`ZALH`, and `ZALS` RTL tests separately check one architectural cycle for
direct and indirect cases, including every documented SACH shift, positive
and negative ADD/SUB saturation, ADDS/SUBS overflow-mode outcomes, and every
logic upper-half effect. This qualifies the documented
one-cycle totals only inside the current sequential subset; it does not
qualify general fetch/execute overlap or any unimplemented instruction.
Directed MAR tests additionally assert one-cycle direct-NOP and indirect
AR/ARP-update cases with no data-memory transaction. Directed LDP tests assert
one-cycle direct/indirect reads, source-bit transfer, and AR/ARP update ordering.
Directed LT tests assert one-cycle full-word reads into T and the same
pre-modification address and post-modification AR/ARP ordering.
Directed DMOV tests assert the one-cycle source-preserving copy to the next
internal-RAM address, distinct source/write diagnostics, page crossing,
unrelated-state preservation, and trap-before-effects at an unresolved
destination.
Directed LTA tests assert the same one-cycle T load and address ordering while
also checking previous-P accumulation, both overflow directions, both OVM
result modes, sticky OV, and unchanged P.
Directed LTD tests add the simultaneous unchanged-word copy to the next
internal-RAM address, separate source/write diagnostics, page crossing,
trap-before-effects at an unresolved destination, and both overflow/OVM result
directions while retaining the documented one-cycle total.
Directed MPY tests assert one-cycle signed products, including the documented
most-negative exception, with the same old-address/post-update ordering.
Directed MPYK tests assert one-cycle signed products across both 13-bit
immediate endpoints and no data-memory transaction.
Directed PAC tests assert a one-cycle full-width P-to-ACC transfer with P and
arithmetic status preserved and no data-memory transaction.
Directed APAC tests assert one-cycle full-width P-plus-ACC arithmetic,
positive/negative overflow, both OVM wrap/saturation modes, sticky OV, P
preservation, and no data-memory transaction.
Directed SPAC tests assert the corresponding one-cycle full-width ACC-minus-P
arithmetic, both overflow directions and OVM result modes, sticky OV, P
preservation, and no data-memory transaction.
Directed `DINT`/`EINT` tests assert exact fixed decode, one-cycle retirement,
program-only transactions, immediate `INTM` state effects, reset masking, and
stable state during clock-enable stalls. The native-phase integration also
retires a following NOP with `INTM` clear before DINT restores it. Because no
pending-interrupt recognition or vector entry exists, this is not evidence
for EINT's documented following-instruction service delay or interrupt entry
latency; both remain under `CTRL-002`/`OQ-004`.
Directed `LST` tests assert one-cycle direct/indirect reads, old-DP and
old-ARP address selection, post-read nine-bit counter updates, `INTM`
preservation, all four loaded status fields, clock-enable hold, and
trap-before-effects at an unresolved address. Native-phase integration
observes its internal read beside the ordinary program fetch. The encoded
next-ARP versus memory-sourced ARP precedence is PROVISIONAL under `OQ-015`.

## Open timing dimensions

- whether taken and untaken conditions have identical two-cycle totals;
- exact immediate-word fetch ordering for branch and call;
- interaction of program fetch with internal data RAM beyond the qualified
  one-cycle `ADD`/`ADDS`/`AND`/`DMOV`/`LAC`/`LAR`/`LDP`/`LST`/`LT`/`LTA`/`LTD`/`MPY`/`OR`/`SUB`/`SUBS`/`XOR`/`ZALH`/
  `ZALS` reads and `SACL`/`SACH`/`SAR` writes;
- table-operation discarded fetch order;
- interrupt entry latency, recognition boundary, and MPY/MPYK's documented
  one-following-instruction deferral;
- board-level phase stretching in the absence of a READY pin.

These map to `OQ-001`, `OQ-004`, and `OQ-007`. Reset-to-first-fetch timing is
resolved and tested through both the standalone native phase engine and the
partial sequential integration.
