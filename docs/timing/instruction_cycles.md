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

TI's explicit I/O and table figures place the current instruction's opcode
prefetch before the numbered execution intervals. Thus a two-cycle `IN`
spans opcode-prefetch completion to next-instruction-prefetch completion via
one intervening port transfer, while a three-cycle `TBLR` spans the
corresponding boundary via dummy, table-transfer, and repeated-prefetch
intervals. The legacy phase wrapper preserves those external transactions and
numeric totals but attaches retirement to fetch samples without a distinct
execute slot. Only the sequential one-cycle subset, exact
`B`/`BANZ`/`BV`/`BIOZ`/`CALL`, the six accumulator branches, exact
`IN`/`OUT`, and exact `TBLR`/`TBLW` currently have explicit fetch/execute
ownership
[ti-tms32010-users-guide-spru001b, §2.1.1 and Figures 2-2, 2-9, and 2-10,
printed pp. 2-3 and 2-16–2-17 (PDF pp. 27 and 40–41)].
**Confidence: VERIFIED_PRIMARY for source cycle labels; VERIFIED_SIMULATION
for the stated implementation scope.**

The individual `PUSH` and `POP` pages independently confirm two cycles, one
word, and `(PC)+1 -> PC`. TI's general pin table says `MEN` is active on every
machine cycle unless `WE` or `DEN` is active; neither exception belongs to
PUSH/POP. This rules out labeling their extra interval an ordinary inactive
bus cycle, but it does not identify its address or whether its word is
discarded, repeated, or consumed. Directed model tests assert the two-cycle
totals and exact stack results transcribed in
`docs/architecture/instruction_set.md`. Those tests deliberately report only
the known opcode fetch; no native program-bus sequence is claimed under
`OQ-016`/`SC-018`
[ti-tms32010-users-guide-spru001b, `POP`/`PUSH`, printed pp. 3-49–3-50
(PDF pp. 99–100), and Table 2-4, printed p. 2-21 (PDF p. 45);
ti-first-generation-users-guide-1987, §3.6.1 and `POP`/`PUSH`, printed
pp. 3-22–3-23 and 4-55–4-56 (PDF pp. 51–52 and 136–137)]. **Confidence:
VERIFIED_PRIMARY for the numeric cycle count and every-cycle `MEN`
constraint; UNKNOWN for address and fetched-word ownership.**

A contemporary TI patent independently states the same every-state external
program-read rule, but its disclosed instruction table omits accumulator
PUSH/POP. It therefore adds no missing program address or word ownership
[ti-dsp-microcomputer-patent-us4577282a, patent cols. 5-6 and 34-36 (PDF
pp. 29 and 43-44)].

The original-device EVM rejects an address breakpoint at the word following
PUSH/POP, while its breakpoint RAM observes the TMS32010 program-address bus
directly. This corroborates `N+1` visibility during the multicycle context but
does not locate it in either interval, count repetitions, or reveal a later
address [ti-tms32010-evm-users-guide-spru005a, SB note 7, printed p. 3-58
(PDF p. 99), and §9.3, printed pp. 9-2 through 9-3 (PDF pp. 179-180)].

The individual `CALA` page likewise establishes a one-word/two-cycle total,
opcode-PC+1 stack push, and `ACC[11:0]` target. Directed model/RTL tests assert
that total and state transition while the logical model reports only the known
opcode fetch. The explicit pipeline implements ADR-0003's discarded `PC+1`
then selected-target read, derived for CALA from TI's general pipeline,
PC-addressing, every-cycle `/MEN`, and analogous TBL redirect facts. Tests stall both reads,
prove nonexecution and retirement-only stack mutation, and cover active-low
interrupt arrival in either interval. That combined mapping remains
`INFERRED` under `OQ-007`/`SC-037`
[ti-tms32010-users-guide-spru001b, `CALA`, printed p. 3-25 (PDF p. 75)].
**Confidence: VERIFIED_PRIMARY for the numeric cycle count and state effects;
INFERRED for the combined address/fetch sequence; UNKNOWN for physical
confirmation.**

US4577282A explicitly discloses the same discarded-sequential-then-target
sequence for RET in a related TI embodiment. RET ownership is consequently
CORROBORATED, while the production TMS32010's exact pin sequence remains
unverified [ti-dsp-microcomputer-patent-us4577282a, patent cols. 17-18 (PDF
p. 35), Figure 3u].

## Qualified timing tests

Unless explicitly identified as an explicit-pipeline test below, the
multicycle tests use `tms32010_phase_slice`. They qualify numeric totals,
ordered transactions, stalls, and architectural effects in that legacy
retirement-mapped wrapper; they do not independently qualify TI's overlapped
execute-slot ownership.

The current native-phase integration tests observe one complete four-subphase
program-read cycle for every one-cycle instruction in the partial RTL subset,
then check retirement on the falling-edge
sample boundary. Directed `ADD`,
`ABS`, `ADDH`, `ADDS`, `AND`, `DMOV`, `LAC`, `LAR`, `OR`, `SACL`, `SACH`, `SAR`, `SST`, `SUB`, `SUBH`, `SUBS`, `XOR`,
`ZALH`, and `ZALS` RTL tests separately check one architectural cycle for
direct and indirect cases, including every documented SACH shift, positive
and negative ADD/SUB/SUBH saturation, ADDS/SUBS overflow-mode outcomes, and every
logic upper-half effect. This qualifies the documented
one-cycle totals only inside the current sequential subset; it does not
qualify general fetch/execute overlap or any unimplemented instruction.
Directed ABS tests separately assert one program fetch, no data or I/O
transaction, and exactly one architectural cycle for ordinary and
most-negative values under both OVM modes.
Directed ADDH tests assert one program fetch plus one concurrent logical
internal-RAM read, exactly one architectural cycle, both high-half wrap
directions, unconditional low-half preservation, every incoming OV/OVM
combination, stalls, and common direct/indirect updates. The cycle and normal
read relationship are primary-verified; status behavior remains
CORROBORATED under `SC-017`/`OQ-011`.
Directed SST tests assert exactly one program fetch and one concurrent logical
internal-RAM write, with no external data/I/O phase, for forced-page direct
and indirect post-update forms. The explicit-pipeline offset stream includes
SST and ADDH as its fortieth and forty-first one-cycle operation families.
Directed MAR tests additionally assert one-cycle direct-NOP and indirect
AR/ARP-update cases with no data-memory transaction. Directed LDP tests assert
one-cycle direct/indirect reads, source-bit transfer, and AR/ARP update ordering.
Directed LT tests assert one-cycle full-word reads into T and the same
pre-modification address and post-modification AR/ARP ordering.
Directed DMOV tests assert the one-cycle source-preserving copy to the next
internal-RAM address, distinct source/write diagnostics, page crossing,
unrelated-state preservation, and trap-before-effects at an unresolved
destination. That last result is only the current PROVISIONAL implementation
boundary: the original-NMOS probe in
`docs/research/ram_boundary_experiment.md` must determine the `0x8f`-to-`0x90`
physical outcome before it can enter a timing claim (`OQ-014`, `SC-038`).
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
stable state during clock-enable stalls. Interrupt tests additionally assert
that a pending request made eligible by EINT allows exactly its following
instruction to retire before the dummy return-PC read. A redundant EINT while
already enabled does not add another protection interval, matching TI's
“previously disabled” qualification. MPY and MPYK in the protected slot each
extend service until one further instruction retires. The model and RTL agree
on EINT, protected instruction, one non-retiring entry cycle, and vector word
state; the native program addresses agree with Figure 2-12. These assertions
qualify the retirement-mapped partial core, not a complete overlapped
fetch/execute pipeline (`OQ-004`).
A 32-case directed core matrix additionally samples a one-cycle request at
each represented machine cycle of B, BANZ, BV, BIOZ, CALL, the six
accumulator-condition branches, IN, OUT, TBLR, and TBLW. It asserts that each
instruction reaches its documented two- or three-cycle retirement before
deferral, then permits one protected instruction and performs the dummy/vector
sequence. This exhausts the currently modeled multicycle machine-cycle
boundaries. A matching explicit-pipeline matrix checks those 32 execution
intervals with family-specific MEN/DEN/WE ownership, no midinstruction entry,
one protected retirement, dummy discard, stack entry, acknowledge state, and
vector capture. A separate native test drives
a held-low INT beginning in each of the four modeled subphases and proves the
digital phase engine changes pending state only at the enabled falling
boundary, including across a phase-2 stall. It does not model the 50 ns pin
setup aperture or a physical asynchronous synchronizer.
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

Directed legacy `TBLR`/`TBLW` tests assert three sampled transactions before
retirement: opcode prefetch, discarded PC+1 prefetch, and transfer at
`ACC[11:0]` under `MEN` or `WE`; they then assert that the next transaction
returns to PC+1. This gives the required three-period spacing between the
opcode-prefetch and repeated-next-prefetch boundaries. The current wrapper
applies retirement, indirect AR/ARP updates, RAM effects, and final
stack-bottom duplication at the table-transfer sample rather than retaining
an explicit execute slot through the repeated prefetch. Tests stall both the
discarded-prefetch and table phases, while differential tests compare the
ordered program addresses, direction, numeric total, RAM, stack, and TBLW
program mutation.

The explicit-pipeline test retains the table opcode through all three
execution intervals. The first PC+1 fetch is nonexecutable, the transfer
interval owns TBLR MEN or TBLW WE at `ACC[11:0]`, and the repeated PC+1 MEN
read completes the instruction and fills the execute slot. TBLR RAM,
indirect AR/ARP, stack-bottom, and retirement effects are deferred to that
last boundary. Each interval is independently stalled; a self-modifying TBLW
case overwrites PC+1 during the transfer and proves that the repeated new word,
not the discarded old word, is later executed
[ti-tms32010-users-guide-spru001b, §2.8.2, Table 3-2, Figure 2-10, and
`TBLR`/`TBLW`, printed pp. 2-17, 3-7, and 3-64–3-67
(PDF pp. 41, 57, and 114–117)]. **Confidence: VERIFIED_PRIMARY for source
transactions and numeric total; VERIFIED_SIMULATION for legacy bus order and
explicit pipeline ownership.**

The same direct TBLR ordering has bounded integrated-pipeline evidence through
40 formal steps with arbitrary clock-enable stalls. Assertions cover the
discarded PC+1 MEN read, ACC-addressed MEN transfer, logical RAM commit,
repeated PC+1 MEN read, and subsequent LAC consumption; the complete fixed
path reaches cover step 34. This first bound does not itself generalize to
TBLW, indirect addressing, interrupt arrival, or arbitrary instruction context
[`formal/tms32010_pipeline_table.sby`, `formal/README.md`].

A second 40-step harness covers one direct self-modifying TBLW sequence at
step 35. Under an explicitly modeled enabled phase-3 program-memory commit,
it asserts that the discarded old PC+1 word survives until the exact WE
boundary, the replacement word is written once, and the repeated PC+1 MEN
read captures and later executes only that replacement. This complements but
does not widen the direct TBLR bound to indirect addressing, arbitrary memory
timing, or arbitrary instruction contexts
[`formal/tms32010_pipeline_table_write.sby`, `formal/README.md`].

Legacy `BANZ` tests assert the opcode and operand transactions on both taken
and untaken paths. The explicit-pipeline test separately primes `0xf400`,
keeps BANZ in the execute slot during its nonexecutable PC+1 operand fetch,
and uses the old selected `AR[8:0]` to choose the execution-cycle-2 fetch at
target or PC+2. BANZ decrements only when that selected fetch completes,
retires, and captures the fetched instruction. The test covers both
conditions, modulo-512 wrap with upper-bit preservation, no early decrement
or fetched-instruction effect, a selected-fetch stall, and malformed-operand
parking
[ti-tms32010-users-guide-spru001b, Table 3-2 and `BANZ`, printed pp. 3-6 and
3-16 (PDF pp. 56 and 66)]. **Confidence: VERIFIED_PRIMARY for component
facts; INFERRED for their combined interval mapping; VERIFIED_SIMULATION for
the implementation.**

The explicit-pipeline `B` test primes exact opcode `0xf900`, keeps B in the
execute slot while the canonical PC+1 operand is fetched during execution
cycle 1, redirects and fetches the target instruction during execution cycle
2, and retires B only as that target word enters the execute slot. The target
instruction's effects occur during the following fetch. The test stalls the
target fetch, proves no early target effect, and parks a malformed operand
before any unsupported speculative address. Legacy tests retain additional
operand-PC wrap, successive-branch, state-preservation, and skipped-fallthrough
coverage
[ti-tms32010-users-guide-spru001b, §2.1.1 and Figure 2-2, Table 3-2, and
`B`, printed pp. 2-3, 3-6, and 3-15 (PDF pp. 27, 56, and 65)].
**Confidence: VERIFIED_PRIMARY for component facts; INFERRED for their
combined B interval mapping; VERIFIED_SIMULATION for the implementation.**

The explicit-pipeline `BGEZ`/`BGZ`/`BLEZ`/`BLZ`/`BNZ`/`BZ` matrix primes each
exact opcode, retains it through the nonexecutable PC+1 operand fetch in
execution cycle 1, and uses the unchanged full 32-bit ACC to select execution
cycle 2's instruction fetch at target or PC+2. Only completion of that fetch
retires the branch and captures the fetched word. Every predicate is covered
in both directions with zero, positive, or negative ACC; the model
additionally covers maximum-positive and most-negative boundaries. The
pipeline test stalls both selected paths, proves ACC and execute ownership
stable, defers the fetched instruction's effect, and parks a malformed
operand. Legacy tests retain the additional native transaction matrix
[ti-tms32010-users-guide-spru001b, Table 3-2 and individual branch pages,
printed pp. 3-6, 3-17–3-18, 3-20–3-22, and 3-24
(PDF pp. 56, 67–68, 70–72, and 74)]. **Confidence: VERIFIED_PRIMARY for
component facts; INFERRED for the combined interval mapping;
VERIFIED_SIMULATION for the implementation and legacy ordering.**

Legacy `BV` tests assert two complete program reads for OV set and clear. The
explicit-pipeline test separately primes exact opcode `0xf500`, retains BV
through the nonexecutable PC+1 operand fetch in execution cycle 1, and uses
old sticky OV to select execution cycle 2's instruction fetch at target or
PC+2. Only completion of that fetch retires BV, captures the fetched word,
and clears OV on the taken path. Both selected paths are stalled in directed
cases, proving stable OV and execute ownership, deferred fetched-instruction
effects, and malformed-operand parking before clear
[ti-tms32010-users-guide-spru001b, Table 3-2 and `BV`, printed pp. 3-6 and
3-23 (PDF pp. 56 and 73)]. **Confidence: VERIFIED_PRIMARY for component
facts; INFERRED for the combined interval mapping; VERIFIED_SIMULATION for
the implementation and legacy ordering.**

Legacy `BIOZ` tests assert two complete program reads for BIO low and high
and reverse the raw pin between opcode and target-word samples. The
explicit-pipeline test separately primes exact opcode `0xf600`, retains BIOZ
through the nonexecutable PC+1 operand fetch in execution cycle 1, and samples
live active-low BIO at that boundary to select execution cycle 2's instruction
fetch at target or PC+2. Only completion of that fetch retires BIOZ and
captures the fetched word. The test presents the opposite opcode-prefetch
level, changes BIO during an operand stall, reverses it again after selection,
stalls both selected paths, and proves stable address/ownership, deferred
effects, and malformed-operand parking before selection
[ti-tms32010-users-guide-spru001b, §2.9, Table 3-2, `BIOZ`, and Appendix A
BIO timing, printed pp. 2-18, 3-6, 3-19, and data-sheet 20
(PDF pp. 42, 56, 69, and 376)]. **Confidence: VERIFIED_PRIMARY for component
facts and the pin sample; INFERRED for the combined interval mapping;
VERIFIED_SIMULATION for the implementation and legacy ordering.**

Legacy `CALL` tests assert opcode and canonical target as two complete program
reads, no stack mutation at opcode sample, and one opcode-PC+2 push at
target-word retirement. The explicit-pipeline test retains CALL through the
nonexecutable operand fetch in execution cycle 1 and selected-target fetch in
execution cycle 2. Operand and target stalls preserve the complete stack and
non-stack state; selected-target capture alone retires CALL, pushes the return
address, and captures without executing that target word. A nested CALL checks
stack shifting, and malformed operands park before mutation. Legacy state
tests additionally cover five nested calls, old-bottom discard, and
return-address wrap
[ti-tms32010-users-guide-spru001b, §§2.6.1–2.6.2, Table 3-2, and `CALL`,
printed pp. 2-13–2-14, 3-6, and 3-26
(PDF pp. 37–38, 56, and 76)]. **Confidence: VERIFIED_PRIMARY for component
facts; INFERRED for the combined execute-interval mapping;
VERIFIED_SIMULATION for explicit and legacy implementations.**

Directed model/RTL tests assert RET's two-cycle total, old-TOS PC load, complete
four-level pop with old-bottom duplication, and EINT protection through RET
before pending interrupt reentry
[ti-tms32010-users-guide-spru001b, §§2.6.2 and 2.9, Table 3-2, and `RET`,
printed pp. 2-14, 2-18–2-19, 3-6, and 3-51
(PDF pp. 38, 42–43, 56, and 101)]. The primary instruction pages do not
identify the address or `MEN` behavior of the second cycle. ADR-0003 therefore
maps execution cycle 1 to a discarded `PC+1` read and cycle 2 to the old-TOS
target read at `INFERRED` confidence. Explicit bus tests stall both intervals,
defer pop/PC/retirement until target capture, prevent discarded-word execution,
and cover active-low interrupt arrival at either boundary. Architectural
differential and a 24-step bounded core proof check the same two-cycle commit
sequence while the logical model trace intentionally reports only the opcode
fetch. **Confidence: VERIFIED_PRIMARY for the numeric cycle total and
architectural boundary; INFERRED for the external address sequence; UNKNOWN
for physical confirmation under `OQ-007`.**

Directed legacy `IN`/`OUT` tests assert an opcode `MEN` transaction followed
by exactly one port transaction, then resumption at opcode PC+1. The opcode
sample advances PC without retirement. The port sample performs the selected
`DEN` input or `WE` output transaction, commits the internal RAM effect and
any common indirect AR/ARP update, increments the numeric total to two, and
retires in the legacy wrapper. Native tests cover address setup, all three
mutually exclusive strobes, a stalled active phase, live input data, stable
output data, and the following prefetch address. Model/RTL differential
traces compare both logical transactions and the I/O data.

The explicit pipeline maps Figure 2-9 directly after the opcode prefetch:
execution cycle 1 owns the mutually exclusive DEN/WE transfer, and execution
cycle 2 owns the executable PC+1 prefetch under MEN. IN samples its live word
at the cycle-1 falling boundary; OUT holds its selected word through that
boundary. IN/OUT remains the execute owner and does not retire until the
cycle-2 boundary captures PC+1. Directed assertions independently stall both
intervals, require two total cycle-count increments, reject early RAM/AR/ARP
mutation and following-word effects, and park invalid data addresses before a
native strobe
[ti-tms32010-users-guide-spru001b, §2.8.1, Figure 2-9, Table 3-2,
`IN`/`OUT`, and Appendix A IN/OUT timing, printed pp. 2-15–2-16, 3-6, 3-30,
3-47, and data-sheet pp. 17–18
(PDF pp. 39–40, 56, 80, 97, and 373–374)]. **Confidence:
VERIFIED_PRIMARY for the waveform, total, and interval ownership;
VERIFIED_SIMULATION for explicit and legacy implementations.**

## Open timing dimensions

- taken/untaken timing and immediate-word ordering for branch/call families
  other than the now-qualified B, BANZ, BIOZ, BV, CALL, and
  accumulator-condition sequences;
- interaction of program fetch with internal data RAM beyond the qualified
  one-cycle `ADD`/`ADDS`/`AND`/`DMOV`/`LAC`/`LAR`/`LDP`/`LST`/`LT`/`LTA`/`LTD`/`MPY`/`OR`/`SUB`/`SUBC`/`SUBS`/`XOR`/`ZALH`/
  `ZALS` reads and `SACL`/`SACH`/`SAR` writes, plus the qualified second-cycle
  `IN` write and `OUT` read;
- unsupported PUSH/POP arrival sequencing, physical confirmation of
  ADR-0003 CALA/RET ownership, physical interrupt
  setup/synchronizer behavior, and the provisional DINT-at-final-boundary
  ordering (`OQ-004`, `OQ-007`, `OQ-016`, `OQ-019`); the basic Figure 2-12
  protected/dummy/vector path, MPY/MPYK protected-slot extension, table
  repeated-prefetch ownership, all 32 represented matrix intervals, and all
  four CALA/RET explicit intervals are qualified;
- electrical wrapper constraints for the primary-resolved 48.78–150 ns
  TMS32010-20 master-clock and 47.5–52.5% pulse envelope.

These map to `OQ-004` and `OQ-007`; `OQ-001` is resolved against arbitrary
physical clock stretching. Reset-to-first-fetch timing is
resolved and tested through both the standalone native phase engine and the
partial sequential integration.
