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

The current native-phase integration tests observe one complete four-subphase
program-read cycle for every one-cycle instruction in the
fifty-two-instruction subset, then check retirement on the falling-edge
sample boundary. Directed `ADD`,
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

Directed `SUBC` tests assert its documented one-cycle total, both conditional
ACC paths, logical data read, and 16 legally spaced iterations of TI's
65-divided-by-7 example. Every iteration is followed by NOP because TI says
the next instruction cannot use ACC. Exact result availability for a
violating schedule and the arithmetic stage responsible for OV remain
`OQ-017`/`OQ-018`; the one-cycle assertion does not resolve them.

Directed `TBLR`/`TBLW` tests assert exactly three complete machine cycles.
Cycle 1 samples the opcode, cycle 2 reads and discards PC+1, and cycle 3
transfers at `ACC[11:0]` under `MEN` or `WE`. Retirement, indirect AR/ARP
updates, RAM effects, and final stack-bottom duplication occur only at the
third sample; the next cycle returns to PC+1. Native tests stall both the
discarded-prefetch and table phases, while differential tests compare the
three program addresses, direction, cycle total, RAM, stack, and TBLW program
mutation
[ti-tms32010-users-guide-spru001b, §2.8.2, Table 3-2, Figure 2-10, and
`TBLR`/`TBLW`, printed pp. 2-17, 3-7, and 3-64–3-67
(PDF pp. 41, 57, and 114–117)]. **Confidence: VERIFIED_PRIMARY.**

Directed `BANZ` tests assert two complete program-read cycles on both taken
and untaken paths. Cycle 1 samples `0xf400`; cycle 2 samples the target word
at PC+1; retirement occurs only at the second sample, with cycle count
increased by two and the next bus address equal to target or PC+2. Tests also
hold the clock enable during cycle 2 and require every pending state and
native pin to remain stable
[ti-tms32010-users-guide-spru001b, Table 3-2 and `BANZ`, printed pp. 3-6 and
3-16 (PDF pp. 56 and 66)]. **Confidence: VERIFIED_PRIMARY.**

Directed `B` tests assert two complete program-read cycles: cycle 1 samples
exact opcode `0xf900`, cycle 2 samples the canonical target at PC+1, and the
second sample retires with PC and the next bus address set to that target.
Tests cover a second-cycle clock-enable hold, operand-fetch PC wrap, successive
branches, state preservation, skipped fall-through words, and
trap-before-effects for a noncanonical target
[ti-tms32010-users-guide-spru001b, Table 3-2 and `B`, printed pp. 3-6 and
3-15 (PDF pp. 56 and 65)]. **Confidence: VERIFIED_PRIMARY.**

Directed `BGEZ`/`BGZ`/`BLEZ`/`BLZ`/`BNZ`/`BZ` tests assert the same two
complete program reads and second-sample retirement for both predicate
outcomes. The RTL matrix distinguishes zero, positive, and negative ACC for
every mnemonic; the model additionally covers maximum-positive and
most-negative boundaries. Native tests assert the ordinary `MEN` target phase
and clock-enable stability for every taken and untaken case
[ti-tms32010-users-guide-spru001b, Table 3-2 and individual branch pages,
printed pp. 3-6, 3-17–3-18, 3-20–3-22, and 3-24
(PDF pp. 56, 67–68, 70–72, and 74)]. **Confidence: VERIFIED_PRIMARY.**

Directed `BV` tests assert two complete program reads for OV set and clear,
with OV stable through the opcode cycle and any target-phase stall. A taken
BV clears OV only at second-sample retirement; an untaken BV retains clear OV
and still consumes that sample. Malformed target words trap before the clear
[ti-tms32010-users-guide-spru001b, Table 3-2 and `BV`, printed pp. 3-6 and
3-23 (PDF pp. 56 and 73)]. **Confidence: VERIFIED_PRIMARY.**

Directed `BIOZ` tests assert two complete program reads for BIO low and high.
The opcode cycle never retires. The target-word sample uses the live,
active-low BIO level, selects target or PC+2, and retires after exactly two
cycles. Tests reverse BIO between opcode and target samples in both directions
and stall the active target phase, guarding TI's every-cycle, not-latched
sampling rule. Malformed target words trap before applying the pin predicate
[ti-tms32010-users-guide-spru001b, §2.9, Table 3-2, `BIOZ`, and Appendix A
BIO timing, printed pp. 2-18, 3-6, 3-19, and data-sheet 20
(PDF pp. 42, 56, 69, and 376)]. **Confidence: VERIFIED_PRIMARY.**

Directed `CALL` tests assert the opcode and canonical target as two complete
program reads, no stack mutation at the opcode sample, and one
opcode-PC+2 push at target-word retirement. Native tests hold an active target
phase under clock enable; directed state tests cover five nested calls,
old-bottom discard, return-address wrap, state preservation, and malformed
target trap-before-push
[ti-tms32010-users-guide-spru001b, §§2.6.1–2.6.2, Table 3-2, and `CALL`,
printed pp. 2-13–2-14, 3-6, and 3-26
(PDF pp. 37–38, 56, and 76)]. **Confidence: VERIFIED_PRIMARY.**

Directed `IN`/`OUT` tests assert one opcode `MEN` cycle followed by exactly
one port cycle. The opcode sample advances PC without retirement. The second
sample performs the selected `DEN` input or `WE` output transaction, commits
the internal RAM effect and any common indirect AR/ARP update, increments the
cycle total to two, and retires. Native tests cover address setup, all three
mutually exclusive strobes, a stalled active phase, live input data, stable
output data, and resumption at opcode PC+1. Model/RTL differential traces
compare both logical cycles and the I/O transaction data
[ti-tms32010-users-guide-spru001b, Table 3-2, `IN`/`OUT`, and Appendix A
IN/OUT timing, printed pp. 3-6, 3-30, 3-47, and data-sheet pp. 17–18
(PDF pp. 56, 80, 97, and 373–374)]. **Confidence: VERIFIED_PRIMARY.**

## Open timing dimensions

- taken/untaken timing and immediate-word ordering for branch/call families
  other than the now-qualified B, BANZ, BIOZ, BV, CALL, and accumulator-condition
  sequences;
- interaction of program fetch with internal data RAM beyond the qualified
  one-cycle `ADD`/`ADDS`/`AND`/`DMOV`/`LAC`/`LAR`/`LDP`/`LST`/`LT`/`LTA`/`LTD`/`MPY`/`OR`/`SUB`/`SUBC`/`SUBS`/`XOR`/`ZALH`/
  `ZALS` reads and `SACL`/`SACH`/`SAR` writes, plus the qualified second-cycle
  `IN` write and `OUT` read;
- table-operation discarded fetch order;
- interrupt entry latency, recognition boundary, and MPY/MPYK's documented
  one-following-instruction deferral;
- board-level phase stretching in the absence of a READY pin.

These map to `OQ-001`, `OQ-004`, and `OQ-007`. Reset-to-first-fetch timing is
resolved and tested through both the standalone native phase engine and the
partial sequential integration.
