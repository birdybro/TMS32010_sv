# Instruction-set research index

TI's revision-B summary lists 60 instructions. This list establishes research
scope only; it does not claim that the machine-readable database, model, or
RTL implements them
[ti-tms32010-users-guide-spru001b, §3.4.2, Table 3-2, printed pp. 3-5–3-7
(PDF pp. 55–57)]. **Confidence: VERIFIED_PRIMARY.**

| Family | Mnemonics |
|---|---|
| accumulator arithmetic/logic/load/store | `ABS ADD ADDH ADDS AND LAC LACK OR SACH SACL SUB SUBC SUBH SUBS XOR ZAC ZALH ZALS` |
| auxiliary register/data page | `LAR LARK LARP LDP LDPK MAR SAR` |
| branch/call/return | `B BANZ BGEZ BGZ BIOZ BLEZ BLZ BNZ BV BZ CALA CALL RET` |
| T/P/multiply | `APAC LT LTA LTD MPY MPYK PAC SPAC` |
| control/status/stack | `DINT EINT LST NOP POP PUSH ROVM SOVM SST` |
| I/O and memory transfer | `DMOV IN OUT TBLR TBLW` |

OCR in the scans sometimes renders `LAR` as `LAA`, `MPY` as `MPV`, and
`DMOV` as `OMOV`. These are transcription artifacts, not aliases accepted
without corroboration. The individual instruction headings and assembly
examples use `LAR`, `MPY`, and `DMOV`.

## Implementation order

Each family enters the qualification boundary only after:

1. individual instruction pages and encoding diagrams are transcribed;
2. independent hand-coded opcode fixtures exist;
3. reference-model effects and boundary tests pass;
4. RTL behavior, cycle count, and bus trace tests pass;
5. all confidence and unresolved fields are updated in the ISA database.

Reserved encodings will trap until authoritative behavior is established.

## Qualified `DINT`/`EINT` functional slice

`DINT` and `EINT` are implied, one-word, one-cycle instructions with exact
fixed encodings `0x7f81` and `0x7f82`. `DINT` writes one to `INTM`, disabling
maskable interrupt service immediately after DINT executes. `EINT` writes zero
to `INTM`, enabling maskable interrupts subject to the service deferral below.
Neither instruction changes an already latched interrupt request
[ti-tms32010-users-guide-spru001b, §2.4.1 and `DINT`/`EINT`, printed
pp. 2-18–2-19 and 3-27/3-29 (PDF pp. 42–43, 77, and 79);
ti-first-generation-users-guide-1987, `DINT`/`EINT`, printed pp. 4-32 and
4-34 (PDF pp. 113 and 115)]. **Confidence: VERIFIED_PRIMARY.**

Although `EINT` clears the architectural `INTM` bit when it executes, TI says
interrupt service remains inhibited until the following instruction
completes. This permits an interrupt handler to execute `EINT` followed by
`RET`; TI also warns against placing EINT immediately before a branch. The
model and RTL now qualify the exact words, `INTM` state effects, one-cycle
retirement, state preservation, program-only transaction, clock-enable hold,
reset-established mask, masked pending-request persistence, EINT's
previously-disabled following-instruction service delay, and vector entry.
Tests also prove that an EINT executed while already enabled does not add a
second deferral. The warning against placing EINT before branch remains a
software restriction; the current two-cycle-branch arrival test does not
constitute an exhaustive fetch/execute pipeline proof (`OQ-004`).

## Qualified `LST` functional slice

`LST` is a one-word, one-cycle instruction with opcode family `0x7b` and the
common direct/indirect data-address field. It reads a 16-bit internal data
word, loads `OV=word[15]`, `OVM=word[14]`, `ARP=word[8]`, and `DP=word[0]`,
and leaves `INTM` unchanged. Other source bits have no architectural effect.
Direct form uses the pre-instruction `DP`, so a load that changes DP does not
redirect its own read
[ti-tms32010-users-guide-spru001b, §2.2.3 and `LST`, printed
pp. 2-14–2-15 and 3-38 (PDF pp. 38–39 and 88);
ti-tms32010-assembly-guide-spru002b, `LST`, printed p. 3-38 (PDF p. 59);
ti-first-generation-users-guide-1987, `LST`, printed p. 4-43
(PDF p. 124)]. **Confidence: VERIFIED_PRIMARY.**

Indirect form reads through the pre-instruction ARP and applies any
increment/decrement to that old selected AR. The original-part sources
provide an optional encoded next-ARP field while also loading ARP from the
memory word, but do not state which wins. Later TI TMS320C25 documentation
explicitly says the encoded next ARP is ignored for LST; pinned MAME
independently does the same. The current model and RTL therefore give the
memory word final precedence and label only that ordering PROVISIONAL for the
original TMS32010 under `OQ-015`/`SC-009`
[ti-tms320c25-users-guide-spru012-1986, `LST`, printed p. 4-75
(PDF p. 170); mame-tms320c1x-core-030fefc,
`tms320c1x_device_base::lst`, lines 594–604].

Hand fixtures cover direct page endpoints and indirect increment/decrement
forms. Model tests exhaust all 16 combinations of the four loaded fields
under both old INTM values, force source bit 13 opposite to INTM, and verify
state preservation, address ordering, and trap-before-effects. Directed RTL,
native-phase, and seeded differential tests cover the same architectural and
logical-transaction boundary. This evidence does not qualify `SST`, whose
reserved output bit 1 remains blocked by conflicting TI diagrams under
`OQ-003`/`SC-008`.

## Qualified `SUBC` legal-scheduling slice

`SUBC` is a one-word, one-cycle common-address instruction with opcode family
`0x64`. Let `old` be the 32-bit ACC value, `word` the zero-extended 16-bit
internal-RAM operand, and
`trial = wrap32(old - (word << 15))`. When `trial` is nonnegative as a signed
32-bit value, ACC receives `wrap32((trial << 1) + 1)`; otherwise ACC receives
`wrap32(old << 1)`. This is the one-bit conditional divide step: the low
inserted bit is the next quotient bit. Direct and indirect address selection
and AR/ARP post-modification use the common rules
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `SUBC`, printed
pp. 3-2–3-3 and 3-61 (PDF pp. 52–53 and 111);
ti-tms32010-assembly-guide-spru002b, `SUBC`, printed p. 3-61
(PDF p. 82)]. **Confidence: VERIFIED_PRIMARY for the encoding, operand
extension/shift, conditional ACC result, addressing, one-word size, and
one-cycle total.**

TI's worked division places 65 in ACC and 7 in data memory; 16 SUBC steps
produce `0x00020009`, representing remainder 2 and quotient 9. Both original
guides warn that the instruction immediately following SUBC cannot use ACC.
The model, RTL, native-phase, and differential tests therefore insert an
ACC-free NOP after every multi-step SUBC sequence. The temporary sequential
implementation exposes the result at the SUBC retirement boundary as an
implementation convenience, but assigns no silicon behavior to a program
that violates TI's scheduling rule; exact availability remains `OQ-017`
[ti-tms32010-assembly-guide-spru002b, §4.6, printed pp. 4-5–4-7
(PDF pp. 98–100); ti-first-generation-users-guide-1987, `SUBC` and §5.7.2,
printed pp. 4-67–4-68 and 5-37 (PDF pp. 148–149 and 194)].

The later first-generation TI guide says SUBC affects sticky `OV`, is not
affected by `OVM`, and never saturates. The original per-instruction pages
omit the flag sentence, although SPRU001B's generic accumulator-status rule
says arithmetic overflow sets `OV`. The current model and RTL provisionally
associate OV with signed overflow of the intermediate subtraction and leave
the final shift unsaturated regardless of OVM. This stage selection is
explicitly PROVISIONAL under `OQ-018`/`SC-010`; ordinary positive division
vectors do not depend on it. Directed model/RTL tests isolate an
intermediate-only overflow, which sets sticky OV, from a final-shift-only
overflow, which provisionally leaves OV clear
[ti-tms32010-users-guide-spru001b, §2.2.2.1 and `SUBC`, printed pp. 2-5 and
3-61 (PDF pp. 29 and 111); ti-first-generation-users-guide-1987, `SUBC`,
printed p. 4-67 (PDF p. 148)]. **Confidence: CORROBORATED that SUBC affects
OV and ignores OVM; PROVISIONAL for the exact overflow-producing stage.**

## Qualified `BANZ` control-flow slice

`BANZ` is exact opcode word `0xf400`, followed by a second word whose low
12 bits are the absolute program-memory target. Both taken and untaken paths
consume two words and two machine cycles. The old low nine bits of the
auxiliary register selected by `ARP` are tested before modification. When
nonzero, PC receives the target; when zero, PC advances past both words. In
both cases `AR[8:0]` is decremented modulo 512 and `AR[15:9]` is unchanged.
No accumulator, product, T, data RAM, or status bit changes
[ti-tms32010-users-guide-spru001b, §§2.4.1 and 2.6.1, Table 3-2, and `BANZ`,
printed pp. 2-9–2-10, 2-13, 3-6, and 3-16
(PDF pp. 33–34, 37, 56, and 66);
ti-tms32010-assembly-guide-spru002b, `BANZ` and §4.4, printed pp. 3-16 and
4-3 (PDF pp. 37 and 85)]. **Confidence: VERIFIED_PRIMARY.**

The source-derived explicit-pipeline mapping separates the opcode-prefetch
boundary from BANZ's two execution intervals. Execution cycle 1 reads the
following target word at PC+1 and uses the old counter to select the next
fetch: target when nonzero or PC+2 when zero. Execution cycle 2 fetches that
selected instruction; only at its completion does BANZ decrement the
counter, retire, and capture the fetched word without executing it. Directed
model, core, legacy native-phase, and explicit-pipeline tests cover both
outcomes, test-before-decrement, upper-bit preservation, low-nine-bit wrap,
selected-fetch clock-enable hold, both selected addresses, and deferred target
effects. **Confidence: VERIFIED_PRIMARY for the component facts and normal
read phases; INFERRED for the combined explicit-pipeline mapping.**

The later SPRU013 `BANZ` example prints zero becoming `0xffff`, contrary to
both the original guide and SPRU013's own §3.4.5 statement that only the low
nine counter bits change. The implementation follows the original-part
`0x01ff` result; see `SC-011`. Pinned MAME agrees functionally on the counter
but charges the second cycle only when taken, contrary to TI's unconditional
two-cycle listing; see `SC-012`. MAME timing is not used as proof.

## Qualified `B` control-flow slice

`B` is exact opcode word `0xf900`, followed by a canonical word whose low
12 bits are an absolute program-memory target. It consumes two words and two
machine cycles unconditionally. The second word is loaded into PC; ACC, T, P,
both auxiliary registers, stack, data RAM, and status remain unchanged
[ti-tms32010-users-guide-spru001b, Table 3-2 and `B`, printed pp. 3-6 and
3-15 (PDF pp. 56 and 65);
ti-tms32010-assembly-guide-spru002b, `B`, printed p. 3-15 (PDF p. 36);
ti-first-generation-users-guide-1987, Table 4-2 and `B`, printed pp. 4-10 and
4-20 (PDF pp. 89 and 101)]. **Confidence: VERIFIED_PRIMARY.**

The source-derived explicit-pipeline mapping places `0xf900` in execute
ownership at opcode-prefetch completion, reads its target operand at PC+1
during execution cycle 1, and fetches the redirected target instruction
during execution cycle 2. B retires and captures—but does not execute—that
target only at the second interval's completion. Directed model, RTL,
native-phase, and differential tests cover two successive branches, skipped
fall-through words, PC wrap on the operand fetch, architectural-state
preservation, a clock-enable stall in the target phase, and trap-before-effects
for a noncanonical target word. Pinned MAME independently corroborates the PC
load and fixed two-cycle total
[mame-tms320c1x-core-030fefc, `tms320c1x_device_base::br`, lines 402–405,
and opcode table line 842]. **Confidence: VERIFIED_PRIMARY for behavior and
numeric timing; INFERRED for the combined explicit-pipeline mapping;
CORROBORATED by independent emulator code.**

## Qualified accumulator-conditional branch slice

Six exact two-word instructions test the full 32-bit ACC:

| Mnemonic | Opcode | Taken predicate |
|---|---:|---|
| `BLZ` | `0xfa00` | signed ACC < 0 |
| `BLEZ` | `0xfb00` | signed ACC <= 0 |
| `BGZ` | `0xfc00` | signed ACC > 0 |
| `BGEZ` | `0xfd00` | signed ACC >= 0 |
| `BNZ` | `0xfe00` | ACC != 0 |
| `BZ` | `0xff00` | ACC == 0 |

Each exact opcode is followed by a canonical 12-bit absolute target. Taken
loads that target into PC; untaken advances to opcode PC+2. Both outcomes
consume two words and two cycles, and no ACC, T, P, AR, stack, RAM, or status
state changes
[ti-tms32010-users-guide-spru001b, Table 3-2 and individual descriptions,
printed pp. 3-6, 3-17–3-18, 3-20–3-22, and 3-24
(PDF pp. 56, 67–68, 70–72, and 74);
ti-tms32010-assembly-guide-spru002b, individual descriptions, printed
pp. 3-17–3-18, 3-20–3-22, and 3-24
(PDF pp. 38–39, 41–43, and 45)]. **Confidence: VERIFIED_PRIMARY.**

Directed model tests exercise every predicate at zero, positive one, negative
one, maximum positive, and most-negative ACC. RTL tests cover both outcomes
for every mnemonic, second-cycle stalls, preserved ACC, no data transaction,
and malformed target trap-before-effects. Native-phase and differential tests
verify opcode/target reads and target/fallthrough address selection. Pinned
MAME corroborates every predicate but shortens untaken paths; the project does
not copy that timing abstraction (`SC-013`).

The source-derived explicit-pipeline mapping places each exact opcode in
execute ownership at opcode-prefetch completion, reads the nonexecutable
canonical operand at PC+1 during execution cycle 1, and selects execution
cycle 2's instruction fetch from the unchanged full 32-bit ACC. The branch
retires and captures—but does not execute—that word only when the selected
fetch completes. A directed matrix covers every predicate in both directions,
selected-fetch stalls on both outcomes, ACC preservation, effect deferral,
and malformed-operand parking. **Confidence: INFERRED for the combined
execute-interval mapping; VERIFIED_SIMULATION for the implementation.**

## Qualified branch-on-overflow slice

`BV` is exact opcode `0xf500` followed by a canonical 12-bit absolute target.
If `OV=1`, PC receives the target and `OV` clears. If `OV=0`, PC advances to
opcode PC+2 and OV remains clear. Both outcomes consume two words and two
cycles; ACC, T, P, OVM, ARs, ARP, DP, stack, and internal RAM are unchanged
[ti-tms32010-users-guide-spru001b, Table 3-2 and `BV`, printed pp. 3-6 and
3-23 (PDF pp. 56 and 73);
ti-tms32010-assembly-guide-spru002b, `BV`, printed p. 3-23 (PDF p. 44);
ti-first-generation-users-guide-1987, `BV`, printed p. 4-28
(PDF p. 109)]. **Confidence: VERIFIED_PRIMARY.**

Directed model and RTL tests cover taken/untaken selection, taken-path OV
clear, untaken clear preservation, two program transactions, target-phase
stall, non-PC state preservation, and malformed-target trap-before-clear.
Native-phase and differential tests place the clear at the taken target-word
retirement boundary. Pinned MAME agrees on status behavior but shortens the
untaken path; `SC-014` preserves that timing disagreement.

The source-derived explicit-pipeline mapping places `0xf500` in execute
ownership at opcode-prefetch completion, reads its nonexecutable canonical
operand at PC+1 during execution cycle 1, and selects execution cycle 2's
instruction fetch from old sticky OV. BV retires and captures—but does not
execute—that word only when the selected fetch completes; a taken BV clears
OV at that same boundary, while an untaken BV preserves clear OV. A directed
test covers both outcomes, stalls both selected paths, proves no early OV
mutation or selected-instruction effect, and parks a malformed operand before
clear. **Confidence: VERIFIED_PRIMARY for the component facts; INFERRED for
the combined execute-interval mapping; VERIFIED_SIMULATION for the
implementation.**

## Qualified branch-on-I/O-status slice

`BIOZ` is exact opcode `0xf600` followed by a canonical 12-bit absolute
target. The physical BIO pin is active low: a low sampled input loads the
target, while a high input advances to opcode PC+2. Both outcomes consume two
words and two cycles, and no programmer-visible state other than PC changes
[ti-tms32010-users-guide-spru001b, §2.9, Table 3-2, and `BIOZ`, printed
pp. 2-18, 3-6, and 3-19 (PDF pp. 42, 56, and 69);
ti-tms32010-assembly-guide-spru002b, `BIOZ`, printed p. 3-19 (PDF p. 40);
ti-first-generation-users-guide-1987, `BIOZ`, printed p. 4-24
(PDF p. 105)]. **Confidence: VERIFIED_PRIMARY.**

TI states that BIO is sampled every machine cycle and is not latched; its AC
table requires setup before falling `CLKOUT`. Consequently the live level at
the target-word falling sample owns the selection, not the level observed
when the opcode was recognized. Legacy RTL and native-phase tests reverse BIO
in both directions between those samples and verify this ownership; the
explicit pipeline maps the same target-word sample to operand completion.
Malformed target words trap before the pin predicate is applied. Pinned MAME
corroborates the active condition through its abstract callback, but shortens
the untaken path; `SC-015` records that disagreement.

The source-derived explicit-pipeline mapping places `0xf600` in execute
ownership at opcode-prefetch completion, reads its nonexecutable canonical
operand at PC+1 during execution cycle 1, and samples live BIO at that
operand boundary to select execution cycle 2's instruction fetch. BIOZ
retires and captures—but does not execute—that word only when the selected
fetch completes. The implementation retains the decision rather than the raw
pin after operand completion. A directed test changes BIO during an operand
stall, changes it again after selection, stalls both paths, proves the
selected address and ownership stable, defers fetched-instruction effects,
and parks a malformed operand. **Confidence: VERIFIED_PRIMARY for the
component facts and BIO sample boundary; INFERRED for the combined
execute-interval mapping; VERIFIED_SIMULATION for the implementation.**

## Qualified direct-call slice

`CALL` is exact opcode `0xf800` followed by a canonical 12-bit absolute target.
It pushes opcode-PC+2 onto the four-level, 12-bit return stack, shifting old
entries one level deeper and discarding the old bottom, then loads the target
into PC. It is two words and two cycles. ACC, T, P, all status bits, both ARs,
and internal RAM remain unchanged; stack overflow is not detected
[ti-tms32010-users-guide-spru001b, §§2.6.1–2.6.2, Table 3-2, and `CALL`,
printed pp. 2-13–2-14, 3-6, and 3-26 (PDF pp. 37–38, 56, and 76);
ti-tms32010-assembly-guide-spru002b, `CALL`, printed p. 3-26 (PDF p. 47);
ti-first-generation-users-guide-1987, `CALL`, printed p. 4-31
(PDF p. 112)]. **Confidence: VERIFIED_PRIMARY.**

The legacy native sequence reads the opcode at PC and target at PC+1 as two
normal program reads. The explicit pipeline separately maps opcode prefetch
into ownership, PC+1 operand fetch into execution cycle 1, and the selected
target-instruction fetch into execution cycle 2. CALL pushes only when that
selected word is captured and CALL retires; this is an architectural commit
boundary, not a claim about an undocumented internal write subphase. Directed
tests cover nested calls, stack shifting, operand and target stalls, deferred
target effects, state preservation, and malformed-target trap-before-push.
Legacy tests additionally cover five nested calls, old-bottom discard, and
target/return-address wrap. Pinned MAME independently agrees on the push,
target, and fixed two-cycle total. **Confidence: VERIFIED_PRIMARY for
instruction effects and component facts; INFERRED for the combined
execute-interval mapping; VERIFIED_SIMULATION for both implementations.**

## Qualified `CALA` architectural/model slice

`CALA` is exact opcode `0x7f8c`, one word, and two cycles. It pushes wrapped
opcode-PC+1 onto the top of the four-level, 12-bit stack, shifts older entries
one level deeper while discarding the old bottom, and loads PC from
`ACC[11:0]`. ACC and all other non-PC, non-stack architectural state remain
unchanged
[ti-tms32010-users-guide-spru001b, §2.6.1, Table 3-2, and `CALA`, printed
pp. 2-13, 3-6, and 3-25 (PDF pp. 37, 56, and 75);
ti-tms32010-assembly-guide-spru002b, `CALA` and §4.7, printed pp. 3-25 and
4-7 (PDF pp. 46 and 100); ti-first-generation-users-guide-1987, Table 4-2
and `CALA`, printed pp. 4-10 and 4-30 (PDF pp. 89 and 111)].
**Confidence: VERIFIED_PRIMARY for opcode, architectural effects, word count,
and cycle total.**

The independent model, assembler, and disassembler implement only those
facts. Directed tests cover accumulator upper-bit exclusion, PC+1 wrap,
nested calls, old-bottom loss, preserved state, exact implied-word round
trips, two-cycle totals, and a logical trace containing only the known opcode
fetch. Pinned MAME independently corroborates the push, accumulator-derived
target, and fixed two-cycle total
[mame-tms320c1x-core-030fefc, `cala()` and `s_opcode_7F`, lines 501–505 and
849]. **Confidence: CORROBORATED for functional behavior and total.**

The instruction pages do not identify CALA's external address or `MEN`
behavior in the second cycle. RTL/native and differential support therefore
remain deferred under `OQ-007`; no sequential prefetch or idle phase is
invented. **Confidence: UNKNOWN for the second external cycle.**

## Qualified `RET` architectural/model slice

`RET` is exact opcode `0x7f8d`, one word, and two cycles. It loads PC from
the old top of the four-level, 12-bit stack, then pops the stack: old level 1
becomes top, old level 2 becomes level 1, and the old bottom is duplicated
into level 2 and bottom. It does not change ACC, T, P, either AR, or any status
bit
[ti-tms32010-users-guide-spru001b, §2.6.2, Table 3-2, and `RET`, printed
pp. 2-14, 3-6, and 3-51 (PDF pp. 38, 56, and 101);
ti-tms32010-assembly-guide-spru002b, `RET`, printed p. 3-51 (PDF p. 72);
ti-first-generation-users-guide-1987, Table 4-2 and `RET`, printed
pp. 4-10 and 4-57 (PDF pp. 89 and 138)]. **Confidence: VERIFIED_PRIMARY for
opcode, architectural effects, and cycle total.**

The instruction-boundary model, assembler, and disassembler implement those
facts. A directed model test also places `RET` immediately after `EINT` with
an already-pending request: RET completes and selects the saved PC before
the next interrupt-entry dummy step. This is the use explicitly described
by TI in §2.9
[ti-tms32010-users-guide-spru001b, §2.9, printed pp. 2-18–2-19
(PDF pp. 42–43)]. **Confidence: VERIFIED_PRIMARY.**

Pinned MAME independently applies its stack-pop helper to PC and assigns a
fixed two-cycle total. Its helper retains the old bottom while shifting the
three higher entries, which is equivalent to bottom duplication in the
project's top-first representation. This corroborates functional behavior
only; MAME does not expose the second pin-level program cycle
[mame-tms320c1x-core-030fefc, `POP_STACK()`/`ret()` and `s_opcode_7F`,
lines 222–228, 676–679, and 849]. **Confidence: CORROBORATED.**

The instruction pages do not identify the external address or `MEN` behavior
of RET's second cycle. A discarded sequential prefetch follows naturally
from TI's general pipeline description, but is only a hypothesis, not an
instruction-specific timing statement. The RTL and native phase wrapper
therefore still reject RET, and the model reports only the known opcode fetch
while counting both documented cycles. `OQ-007` remains open for that
external sequence. **Confidence: UNKNOWN for the second external cycle.**

## Qualified `IN`/`OUT` I/O slice

`IN` and `OUT` are one-word, two-cycle common-address instructions. Their
exact first-word layouts are:

```text
IN   01000 ppp i ccccccc
OUT  01001 ppp i ccccccc
```

`ppp` selects external port 0 through 7. With `i=0`, `ccccccc` is the direct
seven-bit data-memory address and pre-instruction DP supplies bit 7. With
`i=1`, the field uses the same old-ARP/old-AR address selection, low-nine-bit
post-increment/decrement, optional next-ARP, and reserved-control rules as the
other common-address instructions. The old selected address is used for the
transfer before either AR or ARP changes
[ti-tms32010-users-guide-spru001b, `IN`/`OUT`, printed pp. 3-30 and 3-47
(PDF pp. 80 and 97); ti-tms32010-assembly-guide-spru002b, `IN`/`OUT`,
printed pp. 3-30 and 3-47 (PDF pp. 51 and 68)].
**Confidence: VERIFIED_PRIMARY.**

`IN` samples all 16 external input bits from the selected port and writes
them unchanged to the selected internal-RAM word. `OUT` reads all 16 bits of
the selected internal-RAM word and drives them unchanged to the selected
output port. Neither instruction changes ACC, T, P, OV, OVM, DP, stack, or
INTM; indirect forms can change the selected AR and ARP as encoded. Each
advances PC by one word
[ti-first-generation-users-guide-1987, `IN`/`OUT`, printed pp. 4-35 and
4-52 (PDF pp. 116 and 133)]. **Confidence: VERIFIED_PRIMARY.**

Cycle 1 is the opcode program read under active-low `MEN`. Cycle 2 drives
`A11..A3=0` and the port on `PA2..PA0`; `IN` asserts active-low `DEN` and
samples input at the falling-`CLKOUT` boundary, whereas `OUT` asserts
active-low `WE` with output data valid through that boundary. The following
program read begins at opcode PC+1. `MEN`, `DEN`, and `WE` remain mutually
exclusive
[ti-tms32010-users-guide-spru001b, Table 3-2 and Appendix A IN/OUT timing,
printed p. 3-6 and data-sheet pp. 17–18 (PDF pp. 56 and 373–374)].
**Confidence: VERIFIED_PRIMARY.**

Hand fixtures cover all port-field extremes and direct/indirect forms.
Directed model and RTL tests cover both directions, DP addressing,
old-address/post-update ordering, reserved controls, unresolved-address
trap-before-effects, exact two-cycle totals, and clock-enable stalls. A
native waveform test asserts phase-zero address setup, `DEN`-only and
`WE`-only active phases, live input sampling, stable output data, strobe
mutual exclusion, and resumption at the prefetched PC. A focused
model/RTL differential compares cycle totals, RAM effects, AR/ARP state, and
each I/O transaction. Pinned MAME independently agrees on data direction,
common addressing, port selection, and two-cycle table entries; it remains a
functional corroborator, not pin-timing proof
[mame-tms320c1x-core-030fefc, `in_p()`/`out_p()` and opcode table,
lines 530–535, 654–659, and 818–825]. **Confidence: CORROBORATED.**

## Qualified `TBLR`/`TBLW`

`TBLR` (`0x67xx`) and `TBLW` (`0x7dxx`) use the common direct/indirect
internal-data address field. The old DP-selected direct address or old
ARP-selected AR address owns the transfer; indirect AR/ARP modification
occurs only after the table access. `TBLR` copies the program word at
`ACC[11:0]` into the selected internal-RAM word. `TBLW` copies that RAM word
unchanged to program space at `ACC[11:0]`. ACC, T, P, OV, OVM, DP, and INTM
are unchanged
[ti-tms32010-users-guide-spru001b, `TBLR`/`TBLW`, printed pp. 3-64–3-67
(PDF pp. 114–117); ti-tms32010-assembly-guide-spru002b, `TBLR`/`TBLW`,
printed pp. 3-64–3-67 (PDF pp. 85–88)]. **Confidence: VERIFIED_PRIMARY.**

Both are one-word, three-cycle instructions. Cycle 1 reads the opcode under
`MEN`; cycle 2 reads the following instruction address under `MEN` but
discards the word; cycle 3 drives `ACC[11:0]` and either reads under `MEN`
for TBLR or writes under `WE` for TBLW. The following normal program cycle
then fetches the discarded address again. The temporary documented
PC-to-stack, ACC-to-PC, and stack-to-PC sequence has a visible final stack
effect: the old bottom is lost, the old level-2 value is duplicated into the
bottom, and the upper three entries remain unchanged
[ti-tms32010-users-guide-spru001b, §2.8.2, Figure 2-10, and
`TBLR`/`TBLW`, printed pp. 2-17 and 3-64–3-67
(PDF pp. 41 and 114–117); ti-first-generation-users-guide-1987,
`TBLR`/`TBLW`, printed pp. 4-71–4-72 (PDF pp. 152–153)].
**Confidence: VERIFIED_PRIMARY.**

Directed model, RTL, native-phase, and differential tests cover both
directions, all three cycles, the repeated following address, program-memory
mutation, direct and indirect RAM addressing, AR/ARP post-modification,
clock-enable stalls, mutually exclusive `MEN`/`WE`, and the stack-bottom
transformation. Unresolved data addresses trap before the discarded prefetch
or stack effect under the project's provisional `OQ-002` policy. Pinned MAME
independently agrees on data direction, three-cycle totals, and the final
stack-bottom duplication, but is not used as pin-timing proof
[mame-tms320c1x-core-030fefc, table handlers and opcode table, lines
761–772 and 823–826]. **Confidence: CORROBORATED.**

## Model/tool-qualified, RTL-deferred `PUSH`/`POP`

`PUSH` is exact word `0x7f9c`; it copies `ACC[11:0]` to the top of the
four-level, 12-bit hardware stack after shifting each old entry one level
deeper. The former bottom entry is discarded and ACC remains unchanged.
`POP` is exact word `0x7f9d`; it zero-extends the old top entry into ACC,
shifts each deeper entry one level upward, and duplicates the old bottom entry
into the new bottom. Thus repeated over-pops eventually fill all four levels
with the previous bottom value; no overflow/underflow indication exists.
Neither instruction description identifies a status-register effect.
Both instructions are one word and two cycles, and ordinary PC sequencing
advances by one word
[ti-tms32010-users-guide-spru001b, §§2.6.1–2.6.2 and `POP`/`PUSH`, printed
pp. 2-13–2-14 and 3-49–3-50 (PDF pp. 37–38 and 99–100);
ti-tms32010-assembly-guide-spru002b, `POP`/`PUSH`, printed pp. 3-49–3-50
(PDF pp. 70–71); ti-first-generation-users-guide-1987, §3.6.1 and
`POP`/`PUSH`, printed pp. 3-23–3-24 and 4-55–4-56
(PDF pp. 52–53 and 136–137)]. **Confidence: VERIFIED_PRIMARY for encodings,
state transformations, overflow/underflow behavior, word count, and cycle
count.**

The canonical database and independent hand fixtures now include both exact
words. Directed model tests cover low-12-bit PUSH, old-bottom discard,
zero-extending POP, old-bottom duplication, PC wrap, state preservation, and
repeated overflow/underflow behavior. Assembler/disassembler tests cover exact
implied-word round trips. The model counts the primary-defined two cycles but
reports only the known opcode fetch in its logical transaction trace.

No located original-part waveform states the external program address and
`MEN` behavior during the extra cycle of these single-word instructions.
The IN/OUT figures demonstrate that some two-cycle instructions insert an
external transfer between instruction and next-instruction prefetches, but
that does not establish the bus-idle or prefetch behavior of an internal
stack operation. `PUSH` and `POP` therefore remain outside the RTL/native and
differential qualification boundary until `OQ-016` is resolved sufficiently
to implement their two-cycle sequencer without fabricating observable timing.

## Deferred `ABS` research

`ABS` is an implied one-word, one-cycle instruction encoded as `0x7f88`. If
`ACC` is nonnegative it is unchanged; if negative it is replaced by its
two's-complement negation. The most-negative input is special: with `OVM=0`,
`ABS(0x80000000)` remains `0x80000000`; with `OVM=1`, it saturates to
`0x7fffffff`
[ti-tms32010-users-guide-spru001b, `ABS`, printed p. 3-9 (PDF p. 59);
ti-first-generation-users-guide-1987, `ABS`, printed p. 4-14 (PDF p. 95)].
**Confidence: VERIFIED_PRIMARY for encoding, result, OVM selection, word
count, and cycle count.**

Neither original-part page states whether the unrepresentable negation sets
sticky `OV`. The TMS320C14/E14 variant guide explicitly says ABS affects OV,
while the pinned MAME handler leaves OV unchanged. Because software can
observe that distinction, the project does not select either behavior.
`ABS` is therefore absent from the supported database, opcode fixtures,
assembler/disassembler, model, and RTL pending `SC-007`/`OQ-013`.
**Confidence: UNKNOWN for original-TMS32010 OV behavior.**

## Qualified `LAC` research slice

`LAC` accepts direct or indirect internal-data addressing and a left shift
from 0 through 15. The selected 16-bit RAM word is sign-extended to 32 bits
and then shifted left; low bits are zero-filled. The instruction writes `ACC`
without changing `OV` or applying `OVM`, and is one word and one cycle
[ti-tms32010-users-guide-spru001b, §2.2.4.1 and `LAC`, printed pp. 2-6 and
3-31 (PDF pp. 30 and 81)]. **Confidence: VERIFIED_PRIMARY.**

For indirect addressing, the memory read uses the selected auxiliary
register's low eight bits before any update. Auto-increment/decrement and an
optional ARP replacement occur after the access. The update is a circular
nine-bit operation on `AR[8:0]`; `AR[15:9]` is unchanged
[ti-tms32010-users-guide-spru001b, §§2.3.1.1, 2.4.1, printed pp. 2-8–2-10
(PDF pp. 32–34)]. **Confidence: VERIFIED_PRIMARY.**

Indirect control bits 6, 2, and 1 are documented reserved and must be zero.
The manual defines separate increment and decrement bits but does not define
their simultaneous assertion; that encoding is rejected and tracked as
`OQ-010`. When ARP-preserve bit 3 is one, bit 0 is architecturally ignored.
The disassembler renders the noncanonical bit-0-one alias as `.word` so
binary round trips remain exact.

## Qualified `LAR` research slice

`LAR` loads all 16 bits of the selected internal data-memory word into AR0 or
AR1. Bits 10:9 of its three-bit auxiliary-register field are zero and bit 8
selects AR0/AR1, giving base words `0x3800` and `0x3900`; bit 7 and bits 6:0
use the common direct/indirect address form. The instruction is one word and
one cycle and does not modify the accumulator or arithmetic overflow state
[ti-tms32010-users-guide-spru001b, `LAR`, printed p. 3-33 (PDF p. 83);
ti-first-generation-users-guide-1987, `LAR`, printed p. 4-38
(PDF p. 119)]. **Confidence: VERIFIED_PRIMARY.**

An indirect LAR first reads through the AR selected by the old ARP. If the
destination is that same AR, TI explicitly says auto-increment/decrement does
not modify the newly loaded value. If the destination is the other AR, the
selected address AR receives the normal nine-bit post-access update. A
requested next ARP is still applied in either case. This ordering is covered
by directed model and RTL tests, including both same-AR suppression and
different-AR modification. Reserved indirect controls and the lossless
noncanonical preserve-bit policy remain linked to `OQ-010`
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `LAR`, printed
pp. 3-2–3-3 and 3-33 (PDF pp. 52–53 and 83)].
**Confidence: VERIFIED_PRIMARY; OQ-010 remains for simultaneous update bits.**

## Qualified `SAR` research slice

`SAR` stores all 16 bits of AR0 or AR1 into the selected internal data-memory
word. Bits 10:9 of its three-bit auxiliary-register field are zero and bit 8
selects AR0/AR1, giving base words `0x3000` and `0x3100`; bit 7 and bits 6:0
use the common direct/indirect address form. The instruction is one word and
one cycle and does not modify the accumulator or arithmetic overflow state
[ti-tms32010-users-guide-spru001b, `SAR`, printed pp. 3-55–3-56
(PDF pp. 105–106); ti-first-generation-users-guide-1987, `SAR`, printed
pp. 4-61–4-62 (PDF pp. 142–143)]. **Confidence: VERIFIED_PRIMARY.**

SAR's indirect auto-modification order is an explicit architectural special
case. The old selected-AR value supplies the memory address. If the designated
source is that same AR, TI's examples show that `*+` stores the incremented
value and `*-` stores the decremented value at the old address. If the source
is the other AR, that source is stored unchanged while the selected address AR
receives the normal nine-bit update. A requested next ARP is then applied.
Directed model/RTL tests cover same-source increment and decrement, other-source
modification, old-address selection, and ARP replacement/preservation.
Reserved indirect controls remain linked to `OQ-010`
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `SAR`, printed
pp. 3-2–3-3 and 3-55–3-56 (PDF pp. 52–53 and 105–106)].
**Confidence: VERIFIED_PRIMARY; OQ-010 remains for simultaneous update bits.**

## Qualified `MAR` research slice

`MAR` fixes bits 15:8 to `0x68`; bit 7 and bits 6:0 carry the common
direct/indirect field. It is one word and one cycle. In direct form, all 128
address-field values are explicitly documented as no-operations: DP and data
RAM are not consulted. In indirect form, the instruction increments,
decrements, or preserves the AR selected by the old ARP, then optionally
replaces ARP. It does not read or write the memory location nominally selected
by that AR and has no accumulator or arithmetic-status effect
[ti-tms32010-users-guide-spru001b, `MAR`, printed p. 3-42 (PDF p. 92);
ti-first-generation-users-guide-1987, `MAR`, printed pp. 4-47–4-48
(PDF pp. 128–129)]. **Confidence: VERIFIED_PRIMARY.**

TI identifies `MAR *,0` and `MAR *,1` as the same encodings and behavior as
`LARP 0` and `LARP 1`. The database therefore keeps words `0x6880` and
`0x6881` under their canonical `LARP` decode and assigns MAR the other 138
currently qualified words. Directed tests cover both aliases, direct NOP
behavior, absence of logical data transactions, low-nine-bit counter wrap,
ARP replacement/preservation, and rejection of reserved controls
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `MAR`, printed
pp. 3-2–3-3 and 3-42 (PDF pp. 52–53 and 92);
ti-tms32010-assembly-guide-spru002b, `MAR`, printed p. 3-42
(PDF p. 63)]. **Confidence: VERIFIED_PRIMARY; OQ-010 remains for simultaneous
update bits.**

## Qualified `LDP` research slice

`LDP` fixes bits 15:8 to `0x6f`; bit 7 and bits 6:0 use the common
direct/indirect data-address field. It reads the selected 16-bit internal RAM
word and copies only bit 0 into the one-bit data-page pointer. Source bits
15:1 are ignored. The instruction is one word and one cycle and does not
modify the accumulator, `OV`, or `OVM`
[ti-tms32010-users-guide-spru001b, `LDP`, printed p. 3-36 (PDF p. 86);
ti-first-generation-users-guide-1987, `LDP`, printed p. 4-41
(PDF p. 122)]. **Confidence: VERIFIED_PRIMARY.**

Direct addressing uses the old DP value to select page 0 or page 1 for the
read; the source LSB then becomes the new DP value. Indirect addressing reads
through the AR selected by the old ARP before applying the ordinary optional
nine-bit AR increment/decrement and next-ARP replacement. Directed model and
RTL tests cover both source-bit values, old-DP address ordering, indirect
update ordering, and unresolved address trapping. Reserved indirect controls
and the noncanonical preserve-bit policy remain linked to `OQ-010`
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `LDP`, printed
pp. 3-2–3-3 and 3-36 (PDF pp. 52–53 and 86);
ti-tms32010-assembly-guide-spru002b, `LDP`, printed p. 3-36
(PDF p. 57)]. **Confidence: VERIFIED_PRIMARY; OQ-010 remains for simultaneous
update bits.**

## Qualified `LT` research slice

`LT` fixes bits 15:8 to `0x6a`; bit 7 and bits 6:0 use the common
direct/indirect data-address field. It copies all 16 bits of the selected
internal RAM word into the T register without sign extension or shifting. The
instruction is one word and one cycle and does not modify `ACC`, `OV`, `OVM`,
or DP
[ti-tms32010-users-guide-spru001b, `LT`, printed p. 3-39 (PDF p. 89);
ti-first-generation-users-guide-1987, `LT`, printed p. 4-44
(PDF p. 125)]. **Confidence: VERIFIED_PRIMARY.**

Direct addressing resolves the source through the old DP. Indirect addressing
reads through the AR selected by the old ARP, then applies the ordinary
optional nine-bit AR increment/decrement and next-ARP replacement. Directed
model and RTL tests cover zero and nonzero full-width values, direct page-one
selection, pre-modification indirect reads, counter wrap, ARP replacement,
one-cycle retirement, and unresolved-address trapping
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `LT`, printed
pp. 3-2–3-3 and 3-39 (PDF pp. 52–53 and 89);
ti-tms32010-assembly-guide-spru002b, `LT`, printed p. 3-39
(PDF p. 60)]. **Confidence: VERIFIED_PRIMARY; OQ-010 remains for simultaneous
update bits.**

## Qualified `DMOV` functional slice

`DMOV` fixes bits 15:8 to `0x69`; bit 7 and bits 6:0 use the common
direct/indirect data-address field. In one word and one cycle, it copies the
complete selected 16-bit internal RAM word unchanged to the next higher
data-memory address and leaves the source unchanged. TI's worked example
starts with RAM[8]=`0x0043` and RAM[9]=`0x0002`; afterward both locations hold
`0x0043`
[ti-tms32010-users-guide-spru001b, `DMOV`, printed p. 3-28 (PDF p. 78);
ti-tms32010-assembly-guide-spru002b, `DMOV`, printed p. 3-28 (PDF p. 49)].
**Confidence: VERIFIED_PRIMARY.**

The instruction changes neither ACC nor the arithmetic datapath state. The
first-generation guide describes DMOV as the data-move subset of LTD; its
execution list changes only the normal PC and destination memory word. Model
and RTL tests therefore require T, P, ACC, OV, OVM, and DP to remain unchanged
[ti-first-generation-users-guide-1987, §3.4.3 and `DMOV`, printed
pp. 3-13 and 4-33 (PDF pp. 42 and 114)]. **Confidence: VERIFIED_PRIMARY.**

Direct addressing resolves the source through the old DP. Indirect addressing
uses the AR selected by the old ARP and applies the common optional nine-bit
AR increment/decrement and ARP replacement after capturing the source.
Directed tests cover TI's example, both pages, the 127-to-128 page crossing,
old-AR ordering, state preservation, one-cycle retirement, distinct logical
read/write addresses, and reserved controls. A source of `0x8f` implies an
undocumented destination `0x90`; the current partial implementation traps
before any state or RAM effect under `OQ-002`/`OQ-014`. Simultaneous indirect
increment/decrement remains rejected under `OQ-010`.

## Qualified `LTA` functional slice

`LTA` fixes bits 15:8 to `0x6c`; bit 7 and bits 6:0 use the common
direct/indirect data-address field. In one word and one cycle it loads all 16
selected RAM bits into T while adding the complete previous 32-bit P value to
ACC. P is unchanged. TI's worked example starts with RAM[24]=`0x0062`,
T=`0x0003`, P=`0x0000000f`, and ACC=`0x00000005`; afterward T is `0x0062`
and ACC is `0x00000014`
[ti-tms32010-users-guide-spru001b, `LTA`, printed p. 3-40 (PDF p. 90);
ti-tms32010-assembly-guide-spru002b, `LTA`, printed p. 3-40 (PDF p. 61)].
**Confidence: VERIFIED_PRIMARY.**

The ACC-plus-P operation affects sticky `OV` and is affected by `OVM`. With
OVM clear, signed overflow stores the wrapped 32-bit result; with OVM set it
stores the appropriate signed endpoint. Loading T is independent of that
result selection
[ti-first-generation-users-guide-1987, §3.5.2 and `LTA`, printed
pp. 3-19–3-20 and 4-45 (PDF pp. 48–49 and 126)].
**Confidence: VERIFIED_PRIMARY.**

Direct addressing resolves the source through the old DP. Indirect addressing
reads through the AR selected by the old ARP, loads T and accumulates P, then
applies the ordinary optional nine-bit AR increment/decrement and next-ARP
replacement. Directed model and RTL tests cover TI's example, page-one and
indirect reads, counter/ARP ordering, both overflow directions, OVM wrap and
saturation, sticky OV, unchanged P, one-cycle retirement, reserved controls,
and trap-before-either parallel effect on an unresolved address. Native-phase
and seeded differential tests cover the internal read beside a normal program
fetch. If LTA follows MPY or MPYK, its completion is the end of that multiply
instruction's documented interrupt-deferral window. The generic interrupt
sequencer now recognizes that retirement boundary, although a targeted
arrival matrix for every possible following instruction remains under
`CTRL-002`. Simultaneous indirect update controls remain under `OQ-010`.

## Qualified `LTD` functional slice

`LTD` fixes bits 15:8 to `0x6b`; bit 7 and bits 6:0 use the common
direct/indirect data-address field. In one word and one cycle it performs
three parallel operations: the selected 16-bit internal RAM word loads T, the
unchanged previous 32-bit P value is added to ACC, and the selected word is
copied unchanged to the next higher data-memory address. The source word and
P remain unchanged. TI's worked example starts with RAM[24]=`0x0062`,
RAM[25]=`0x0000`, T=`0x0003`, P=`0x0000000f`, and ACC=`0x00000005`;
afterward RAM[24] remains `0x0062`, RAM[25] and T are `0x0062`, and ACC is
`0x00000014`
[ti-tms32010-users-guide-spru001b, `LTD`, printed p. 3-41 (PDF p. 91);
ti-tms32010-assembly-guide-spru002b, `LTD`, printed p. 3-41 (PDF p. 62)].
**Confidence: VERIFIED_PRIMARY.**

The ACC-plus-P path affects sticky `OV` and is affected by `OVM`, with the
same wrapped or signed-endpoint saturated results as APAC/LTA. The data move
is a source read followed logically by a write of that captured value to
`source+1`; it is independent of the optional indirect AR modification.
Indirect addressing therefore selects the source with the old AR/ARP, moves
to the numerically next data address, and only then exposes the ordinary
nine-bit AR and optional ARP post-update at the architectural boundary
[ti-first-generation-users-guide-1987, §§3.4.3, 3.5.2 and `LTD`, printed
pp. 3-13, 3-19–3-20, and 4-46 (PDF pp. 42, 48–49, and 127)].
**Confidence: VERIFIED_PRIMARY.**

The original documentation does not define a move whose next-higher
destination is outside the 144-word RAM. The current partial model and RTL
therefore trap before changing T, ACC, RAM, AR, or ARP when either the source
or destination is unresolved. This is an explicit implementation boundary,
not a hardware-behavior claim (`OQ-002`, `OQ-014`). Simultaneous indirect
increment/decrement remains rejected under `OQ-010`; the generic sequencer
recognizes LTD retirement as a possible end of multiply deferral, but no
per-instruction interrupt-arrival matrix is yet claimed.

## Qualified `MPY` functional slice

`MPY` fixes bits 15:8 to `0x6d`; bit 7 and bits 6:0 use the common
direct/indirect data-address field. It treats both the 16-bit T register and
the selected internal RAM word as signed two's-complement operands and
replaces the 32-bit P register with their product. It is one word and one
cycle and does not modify T, ACC, `OV`, or `OVM`
[ti-tms32010-users-guide-spru001b, §§2.2 and `MPY`, printed pp. 2-9 and
3-43 (PDF pp. 33 and 93); ti-first-generation-users-guide-1987, `MPY`,
printed p. 4-49 (PDF p. 130)]. **Confidence: VERIFIED_PRIMARY.**

The original multiplier has one documented arithmetic exception. When both
operands are `0x8000`, the mathematical signed product would be
`0x40000000`, but the TMS32010 produces `0xc0000000`. Directed model and RTL
tests require that exact result in addition to zero, sign, extrema, direct,
indirect, page-one, and counter-update cases. The pinned MAME implementation
independently corroborates the exception, but is not its authority
[mame-tms320c1x-core-030fefc, `tms320c1x_device_base::mpy`, lines 631-635].
**Confidence: VERIFIED_PRIMARY; CORROBORATED by the secondary oracle.**

Direct addressing resolves the data operand through the old DP. Indirect
addressing reads through the AR selected by the old ARP before the ordinary
nine-bit AR update and optional next-ARP replacement. Reserved controls and
the simultaneous-update uncertainty follow `OQ-010`. TI also specifies that
interrupt service is inhibited until the instruction following `MPY`
completes. Directed model and RTL interrupt tests place MPYK in an already
protected slot, require one more instruction to retire, and then observe the
dummy return-PC fetch and vector entry. MPY and MPYK share the same explicit
deferral predicate in RTL; broader randomized arrival coverage remains part
of `CTRL-002`
[ti-tms32010-users-guide-spru001b, `MPY`, printed p. 3-43 (PDF p. 93)].
**Confidence: VERIFIED_PRIMARY for the rule and directed RTL boundary.**

## Qualified `MPYK` functional slice

`MPYK` fixes bits 15:13 to `100`; bits 12:0 hold a signed immediate in the
inclusive range -4096 through 4095. The immediate is sign-extended, multiplied
by signed 16-bit T, and the 32-bit product replaces P. The instruction is one
word and one cycle, preserves T, ACC, `OV`, and `OVM`, and performs no
data-memory transaction
[ti-tms32010-users-guide-spru001b, `MPYK`, printed p. 3-44 (PDF p. 94);
ti-tms32010-assembly-guide-spru002b, `MPYK`, printed p. 3-44 (PDF p. 65);
ti-first-generation-users-guide-1987, §3.5.3 and `MPYK`, printed pp. 3-21 and
4-50 (PDF pp. 50 and 131)]. **Confidence: VERIFIED_PRIMARY.**

Directed model and RTL tests reproduce TI's `7 * -9 = -63` example and cover
both immediate endpoints, zero, both T sign extremes, state preservation, one
cycle, and absence of a logical data access. Because a 13-bit immediate cannot
equal signed 16-bit `0x8000`, MPYK cannot invoke MPY's documented
`0x8000`-by-`0x8000` hardware exception. The pinned MAME implementation
independently corroborates sign extension of bits 12:0, but is not the
architectural authority
[mame-tms320c1x-core-030fefc, `tms320c1x_device_base::mpyk`, lines 638-641].
**Confidence: VERIFIED_PRIMARY; CORROBORATED by the secondary oracle.**

TI applies the same interrupt-protection rule to MPYK as MPY: interrupt service
is inhibited until the following instruction executes. The functional result,
program-only transaction, cycle count, one-following-instruction deferral,
dummy entry, and vector selection have directed model/RTL checks
[ti-tms32010-users-guide-spru001b, `MPYK`, printed p. 3-44 (PDF p. 94)].
**Confidence: VERIFIED_PRIMARY.**

## Qualified `PAC` functional slice

`PAC` is the implied fixed word `0x7f8e`. It copies the complete 32-bit P
register into ACC without a shift or arithmetic operation and leaves P
unchanged. The instruction is one word and one cycle. The individual
instruction pages list only PC advance and P-to-ACC transfer, so PAC does not
modify `OV` or apply `OVM` saturation. It performs no data-memory transaction
[ti-tms32010-users-guide-spru001b, `PAC`, printed p. 3-48 (PDF p. 98);
ti-tms32010-assembly-guide-spru002b, `PAC`, printed p. 3-48 (PDF p. 69);
ti-first-generation-users-guide-1987, `PAC`, printed p. 4-54
(PDF p. 135)]. **Confidence: VERIFIED_PRIMARY.**

Directed model and RTL tests copy zero, sign boundaries, all-ones, and the
original multiplier's `0xc0000000` exception result. They also require P, T,
address state, RAM, and both arithmetic-status bits to remain unchanged,
assert one-cycle retirement, and reject adjacent unsupported fixed words.
Native-phase and seeded differential tests verify the ordinary program fetch
and inactive logical data-memory strobes. When PAC follows MPY or MPYK, its
completion is also the end of the multiply instruction's documented interrupt
deferral window. The generic sequencer recognizes that retirement shape, but
the PAC instruction tests themselves are not an exhaustive interrupt-arrival
matrix.

## Qualified `APAC` functional slice

`APAC` is the implied fixed word `0x7f8f`. It performs a full-width two's
complement addition `(ACC) + (P) -> ACC`, leaves P unchanged, and is one word
and one cycle. TI's worked example adds P=64 to ACC=32 to produce ACC=96
[ti-tms32010-users-guide-spru001b, `APAC`, printed p. 3-14 (PDF p. 64);
ti-tms32010-assembly-guide-spru002b, `APAC`, printed p. 3-14 (PDF p. 35)].
**Confidence: VERIFIED_PRIMARY.**

Signed overflow sets sticky `OV`. With `OVM=0`, the wrapped 32-bit result is
stored; with `OVM=1`, positive overflow stores `0x7fffffff` and negative
overflow stores `0x80000000`. A nonoverflowing APAC does not clear an already
set `OV`
[ti-tms32010-users-guide-spru001b, §§2.2.1.1–2.2.2.1, printed pp. 2-4–2-5
(PDF pp. 28–29); ti-first-generation-users-guide-1987, §3.5.2 and `APAC`,
printed pp. 3-19–3-20 and 4-19 (PDF pp. 48–49 and 100)].
**Confidence: VERIFIED_PRIMARY.**

Directed model and RTL tests cover TI's worked example, both signed-overflow
directions, OVM-clear wrapping, OVM-set saturation, sticky-OV preservation,
unchanged P/T/address state, one-cycle retirement, exact fixed-word decode,
and absence of a logical data-memory transaction. Native-phase and seeded
differential tests cover the ordinary program fetch and randomized arithmetic
states. As with PAC, an APAC immediately after MPY or MPYK reaches the
documented interrupt-deferral boundary. The generic sequencer handles that
retirement, while APAC-specific interrupt arrival combinations remain future
`CTRL-002` coverage.

## Qualified `SPAC` functional slice

`SPAC` is the implied fixed word `0x7f90`. It performs full-width two's
complement subtraction `(ACC) - (P) -> ACC`, leaves P unchanged, and is one
word and one cycle. TI's worked example subtracts P=36 from ACC=60 to produce
ACC=24
[ti-tms32010-users-guide-spru001b, `SPAC`, printed p. 3-58 (PDF p. 108);
ti-tms32010-assembly-guide-spru002b, `SPAC`, printed p. 3-58 (PDF p. 79)].
**Confidence: VERIFIED_PRIMARY.**

Signed overflow sets sticky `OV`. With `OVM=0`, the wrapped 32-bit result is
stored; with `OVM=1`, positive overflow stores `0x7fffffff` and negative
overflow stores `0x80000000`. P is always treated as a signed 32-bit operand,
and a nonoverflowing SPAC does not clear an already set `OV`
[ti-tms32010-users-guide-spru001b, §§2.2.1.1–2.2.2.1, printed pp. 2-4–2-5
(PDF pp. 28–29); ti-first-generation-users-guide-1987, §3.5.2 and `SPAC`,
printed pp. 3-19–3-20 and 4-64 (PDF pp. 48–49 and 145)].
**Confidence: VERIFIED_PRIMARY.**

Directed model and RTL tests cover TI's worked example, both signed-overflow
directions, OVM-clear wrapping, OVM-set endpoint saturation, sticky-OV
preservation, unchanged P/T/address state, one-cycle retirement, exact
fixed-word decode, and absence of a logical data-memory transaction.
Native-phase and seeded differential tests cover the ordinary program fetch
and randomized arithmetic states. A SPAC immediately after MPY or MPYK
reaches the documented interrupt-deferral boundary. The generic sequencer
handles that retirement, while SPAC-specific interrupt arrival combinations
remain future `CTRL-002` coverage.

## Qualified `SACL` research slice

`SACL` stores `ACC[15:0]` unchanged into the selected internal data-memory
word. It does not shift, modify `ACC`, or affect overflow status. The
instruction is one word and one cycle
[ti-tms32010-users-guide-spru001b, §2.2.2 and `SACL`, printed pp. 2-4 and
3-54 (PDF pp. 28 and 104)]. **Confidence: VERIFIED_PRIMARY.**

Its direct/indirect address selection and post-access auxiliary-register
controls have the same form described above for `LAC`. The memory write uses
the old selected-AR address before optional increment/decrement and ARP
replacement. TI specifies no shift for SACL, but its assembler syntax requires
an explicit zero placeholder when a next ARP follows, for example
`SACL *+,0,1`
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `SACL`, printed
pp. 3-2–3-3 and 3-54 (PDF pp. 52–53 and 104)].
**Confidence: VERIFIED_PRIMARY.**

Reserved indirect controls, simultaneous increment/decrement, and the
noncanonical ARP-preserve alias follow the same conservative policies as
`LAC`; they remain linked to `OQ-010`.

## Qualified `SACH` research slice

`SACH` copies the entire 32-bit accumulator into its dedicated output shifter,
left-shifts by exactly 0, 1, or 4, and stores shifted bits 31:16 in the selected
internal data-memory word. Bits shifted above bit 31 are discarded; bits
crossing from the original low accumulator half enter the stored word. The
accumulator itself and overflow status are unchanged
[ti-tms32010-users-guide-spru001b, §2.2.4.2 and `SACH`, printed pp. 2-7 and
3-53 (PDF pp. 31 and 103)]. **Confidence: VERIFIED_PRIMARY.**

For example, TI shows `0xA34B78CD` stored with shift 4 as `0x34B7`, and its
instruction page separately shows the 0/1/4 restriction and one-word,
one-cycle timing. The opcode's three-bit shift field is therefore accepted
only for values 0, 1, and 4. Encodings 2, 3, 5, 6, and 7 trap; they are not
treated as aliases or no-ops.

Direct/indirect address selection and post-access auxiliary-register controls
match `LAC` and `SACL`. The write uses the old selected-AR address before any
optional nine-bit increment/decrement and ARP replacement
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `SACH`, printed
pp. 3-2–3-3 and 3-53 (PDF pp. 52–53 and 103)].
**Confidence: VERIFIED_PRIMARY; OQ-010 remains for simultaneous update bits.**

## Qualified `ZALH` and `ZALS` research slice

`ZALH` reads the selected 16-bit internal data word into `ACC[31:16]` and
clears `ACC[15:0]`. `ZALS` reads the word into `ACC[15:0]` and clears
`ACC[31:16]`; the source is therefore zero-extended even when its sign bit is
one. Neither instruction changes overflow status. Both are one word and one
cycle
[ti-tms32010-users-guide-spru001b, `ZALH` and `ZALS`, printed pp. 3-70–3-71
(PDF pp. 120–121)]. **Confidence: VERIFIED_PRIMARY.**

Both instructions use the common direct/indirect data-address field without a
shift operand. The indirect read occurs at the old selected-AR address before
the optional nine-bit counter update and ARP replacement. Reserved indirect
controls, simultaneous increment/decrement, and noncanonical ARP-preserve
aliases follow the same conservative policy as `LAC`, `SACL`, and `SACH`
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `ZALH`/`ZALS`, printed
pp. 3-2–3-3 and 3-70–3-71 (PDF pp. 52–53 and 120–121)].
**Confidence: VERIFIED_PRIMARY; OQ-010 remains for simultaneous update bits.**

## Qualified `ADDS` research slice

`ADDS` treats the selected 16-bit data word as an unsigned value, adds its
zero-extended value to the full 32-bit accumulator, and stores the 32-bit
result. Unlike `ADD dma,0`, it never sign-extends a source whose bit 15 is one.
It is one word and one cycle
[ti-tms32010-users-guide-spru001b, `ADDS`, printed p. 3-12 (PDF p. 62);
ti-first-generation-users-guide-1987, `ADDS`, printed p. 4-17 (PDF p. 98)].
**Confidence: VERIFIED_PRIMARY.**

The later TI guide explicitly states that ADDS affects sticky `OV` and is
affected by `OVM`. Signed 32-bit overflow sets `OV`; `OVM=0` retains the
wrapped result, while `OVM=1` saturates it. Because the ADDS operand is always
nonnegative, only positive saturation can arise from this instruction
[ti-first-generation-users-guide-1987, §§3.5.2 and `ADDS`, printed pp. 3-20
and 4-17 (PDF pp. 49 and 98)]. The older guide's contradictory `OVM=0`
sentence is resolved in `SC-001`. **Confidence: CORROBORATED for the resolved
wording; VERIFIED_PRIMARY for ADDS status applicability.**

Direct/indirect address selection and post-access controls use the common
data-address form. The read uses the old selected-AR address before an optional
nine-bit counter update and ARP replacement. The current conservative
reserved-control and alias policies remain linked to `OQ-010`.

`ADDH` is intentionally not in this qualification boundary. Its ordinary
high-half addition is documented, but original-part sources omit whether
`OV`/`OVM` applies, while a C14/E14 variant guide and MAME apply overflow with
unresolved saturation details. See `SC-006` and `OQ-011`.

## Qualified `ADD` research slice

`ADD` sign-extends the selected 16-bit internal RAM word to 32 bits, shifts it
left by the encoded count from 0 through 15, adds that value to the full
32-bit accumulator, and stores the result. Low bits introduced by the shift
are zero; the sign-extended high bits enter the ALU
[ti-tms32010-users-guide-spru001b, §2.2.4.1 and `ADD`, printed pp. 2-6 and
3-10 (PDF pp. 30 and 60); ti-first-generation-users-guide-1987, §§3.5.1 and
`ADD`, printed pp. 3-18 and 4-15 (PDF pp. 47 and 96)].
**Confidence: VERIFIED_PRIMARY.**

Signed 32-bit overflow sets sticky `OV`. With `OVM=0`, the wrapped result is
loaded; with `OVM=1`, positive and negative overflow saturate to
`0x7fffffff` and `0x80000000`, respectively. The individual ADD page defines
the arithmetic but does not repeat the status sentence; these effects come
from the original guide's general accumulator overflow sections and the later
TI ALU/accumulator section
[ti-tms32010-users-guide-spru001b, §§2.2.1.1–2.2.2.1, printed
pp. 2-4–2-5 (PDF pp. 28–29); ti-first-generation-users-guide-1987, §3.5.2,
printed p. 3-20 (PDF p. 49)]. This is documented general hardware behavior,
not a per-instruction-page inference. **Confidence: VERIFIED_PRIMARY.**

ADD occupies one word and one cycle. Its common direct/indirect address,
old-AR read, optional nine-bit update, ARP replacement, reserved-control
rejection, and noncanonical alias policy match `LAC`. `ADDH` remains excluded
under `SC-006`/`OQ-011`.

## Qualified `SUB` research slice

`SUB` sign-extends the selected 16-bit internal RAM word to 32 bits, shifts it
left by the encoded count from 0 through 15, subtracts that value from the
full 32-bit accumulator, and stores the result. Low bits introduced by the
shift are zero-filled
[ti-tms32010-users-guide-spru001b, §2.2.4.1 and `SUB`, printed pp. 2-6 and
3-60 (PDF pp. 30 and 110); ti-first-generation-users-guide-1987, §§3.5.1 and
`SUB`, printed pp. 3-18 and 4-66 (PDF pp. 47 and 147)].
**Confidence: VERIFIED_PRIMARY.**

The later TI instruction page explicitly states that `SUB` affects sticky
`OV` and is affected by `OVM`. General ALU rules establish wrapped results
when `OVM=0` and positive/negative saturation at `0x7fffffff`/`0x80000000`
when `OVM=1`
[ti-first-generation-users-guide-1987, §§3.5.2 and `SUB`, printed pp. 3-20
and 4-66 (PDF pp. 49 and 147)]. **Confidence: VERIFIED_PRIMARY.**

`SUB` occupies one word and one cycle. Its common direct/indirect addressing,
old-AR read ordering, optional nine-bit counter update, ARP replacement,
reserved-control rejection, and noncanonical alias policy match `ADD` and
`LAC`. `SUBH` and `SUBS` are separate encodings.

## Qualified `SUBH` research slice

`SUBH` is the common-address opcode family `0x62xx`. It subtracts the complete
16-bit data-word pattern aligned to accumulator bits 31:16, equivalent to
`ACC - (dma × 2^16)`. The original instruction page establishes one word,
one cycle, direct/indirect addressing, and the unchanged low half for the
ordinary result; its worked example changes high word `0x0017` to `0x0012`
after subtracting data word `0x0005`
[ti-tms32010-users-guide-spru001b, `SUBH`, printed p. 3-62 (PDF p. 112);
ti-tms32010-assembly-guide-spru002b, `SUBH`, printed p. 3-62
(PDF p. 83)]. **Confidence: VERIFIED_PRIMARY.**

The later TI family page explicitly says SUBH affects sticky `OV` and is
affected by `OVM`. Its common ALU section says any OVM-enabled accumulator
overflow replaces the complete accumulator with `0x7fffffff` or
`0x80000000`. Accordingly, a nonoverflowing or OVM-clear wrapped SUBH result
retains `ACC[15:0]`, while an OVM-enabled overflow replaces all 32 bits with
the documented signed endpoint
[ti-first-generation-users-guide-1987, §3.5.2 and `SUBH`, printed
pp. 3-19–3-20 and 4-69 (PDF pp. 48–49 and 150)]. The wording tension and
resolution are recorded as `SC-016`. **Confidence: VERIFIED_PRIMARY.**

Directed model and RTL tests cover the TI example, both source sign-bit
patterns, low-half preservation, sticky OV, positive and negative overflow,
OVM-clear wrap, full-accumulator endpoint saturation, direct page 1, old-AR
indirect reads, low-nine-bit post-update, ARP replacement, unresolved-address
trap, one-cycle retirement, and logical/native data-read visibility. The
512-instruction seeded model/RTL trace adds deterministic direct and indirect
SUBH cases. Pinned MAME independently aligns the source by 16 and applies its
common signed-subtraction overflow path
[mame-tms320c1x-core-030fefc, `subh()`, lines 745–750].
**Confidence: CORROBORATED for implementation behavior.**

## Qualified `SUBS` research slice

`SUBS` suppresses sign extension and subtracts the selected 16-bit internal
RAM word as an unsigned value from the signed 32-bit accumulator. It has no
shift operand. TI's original example subtracts `0xf003` from `0x0000f105` to
produce `0x00000102`, directly distinguishing this behavior from
sign-extending `SUB`
[ti-tms32010-users-guide-spru001b, `SUBS`, printed p. 3-63 (PDF p. 113);
ti-first-generation-users-guide-1987, `SUBS`, printed p. 4-70
(PDF p. 151)]. **Confidence: VERIFIED_PRIMARY.**

The later TI page explicitly states that `SUBS` affects sticky `OV` and is
affected by `OVM`. `OVM=0` retains the wrapped result; `OVM=1` saturates an
overflowing result. Because its zero-extended subtrahend is nonnegative, SUBS
can cross only the negative signed endpoint, so positive overflow is
unreachable
[ti-first-generation-users-guide-1987, §§3.5.2 and `SUBS`, printed
pp. 3-20 and 4-70 (PDF pp. 49 and 151)]. **Confidence: VERIFIED_PRIMARY.**

`SUBS` is one word and one cycle. It uses the no-shift common direct/indirect
address form and the same old-AR access, optional nine-bit update, ARP
replacement, reserved-control rejection, and lossless alias policy as
`ADDS`.

## Qualified `AND`, `OR`, and `XOR` research slice

Each logic instruction reads a common-addressed 16-bit internal RAM word and
combines it with `ACC[15:0]`. `AND` writes
`ACC = {16'h0000, ACC[15:0] & dma}`. `OR` and `XOR` instead preserve
`ACC[31:16]` and replace only the low half with their respective result. No
source is sign-extended or shifted
[ti-tms32010-users-guide-spru001b, `AND`, `OR`, and `XOR`, printed
pp. 3-13, 3-46, and 3-68 (PDF pp. 63, 96, and 118);
ti-first-generation-users-guide-1987, §3.5.2 and `AND`/`OR`/`XOR`, printed
pp. 3-19–3-20, 4-18, 4-52, and 4-73 (PDF pp. 48–49, 99, 133, and 154)].
**Confidence: VERIFIED_PRIMARY.**

TI states that logical operations cannot overflow. The three operations leave
both sticky `OV` and `OVM` unchanged and each occupies one word and one cycle.
Their direct/indirect address selection, old-AR read ordering, optional
nine-bit counter update, ARP replacement, reserved-control rejection, and
noncanonical preserve alias policy match the other qualified common-address
operations. **Confidence: VERIFIED_PRIMARY; OQ-010 remains for simultaneous
update bits.**
