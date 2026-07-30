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

## Qualified timing tests

The current native-phase integration test observes one complete four-subphase
program-read cycle for every instruction in the twenty-two-instruction subset,
then checks retirement on the falling-edge sample boundary. Directed `ADD`,
`ADDS`, `AND`, `LAC`, `LAR`, `OR`, `SACL`, `SACH`, `SAR`, `SUB`, `SUBS`, `XOR`,
`ZALH`, and `ZALS` RTL tests separately check one architectural cycle for
direct and indirect cases, including every documented SACH shift, positive
and negative ADD/SUB saturation, ADDS/SUBS overflow-mode outcomes, and every
logic upper-half effect. This qualifies the documented
one-cycle totals only inside the current sequential subset; it does not
qualify general fetch/execute overlap or any unimplemented instruction.

## Open timing dimensions

- whether taken and untaken conditions have identical two-cycle totals;
- exact immediate-word fetch ordering for branch and call;
- interaction of program fetch with internal data RAM beyond the qualified
  one-cycle `ADD`/`ADDS`/`AND`/`LAC`/`LAR`/`OR`/`SUB`/`SUBS`/`XOR`/`ZALH`/
  `ZALS` reads and `SACL`/`SACH`/`SAR` writes;
- table-operation discarded fetch order;
- interrupt entry latency and recognition boundary;
- board-level phase stretching in the absence of a READY pin.

These map to `OQ-001`, `OQ-004`, and `OQ-007`. Reset-to-first-fetch timing is
resolved and tested through both the standalone native phase engine and the
partial sequential integration.
