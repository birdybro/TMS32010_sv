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
and reset-established mask. They do not yet recognize or vector a pending
interrupt, so the following-instruction service delay and warning remain
unimplemented timing requirements under `CTRL-002`/`OQ-004`, not silently
collapsed into ordinary boundary recognition.

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

The qualified program sequence reads the opcode at PC in cycle 1 and the
following target word at PC+1 in cycle 2. The next normal read is the target
when the old counter was nonzero or PC+2 when it was zero. This follows TI's
mandatory two-word/two-cycle definition, its statement that program memory is
always addressed by PC, and its explicit final-PC cases. Directed model, RTL,
and native-phase tests cover both outcomes, test-before-decrement, upper-bit
preservation, low-nine-bit wrap, clock-enable hold in the operand cycle, and
both program addresses. **Confidence: VERIFIED_PRIMARY for logical address
order and normal-read phases.**

The later SPRU013 `BANZ` example prints zero becoming `0xffff`, contrary to
both the original guide and SPRU013's own §3.4.5 statement that only the low
nine counter bits change. The implementation follows the original-part
`0x01ff` result; see `SC-011`. Pinned MAME agrees functionally on the counter
but charges the second cycle only when taken, contrary to TI's unconditional
two-cycle listing; see `SC-012`. MAME timing is not used as proof.

## Researched, RTL-deferred `PUSH`/`POP`

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

No located original-part waveform states the external program address and
`MEN` behavior during the extra cycle of these single-word instructions.
The IN/OUT figures demonstrate that some two-cycle instructions insert an
external transfer between instruction and next-instruction prefetches, but
that does not establish the bus-idle or prefetch behavior of an internal
stack operation. `PUSH` and `POP` therefore remain outside the qualified
database/model/tool/RTL boundary until `OQ-016` is resolved sufficiently to
implement their two-cycle sequencer without fabricating observable timing.

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
instruction's documented interrupt-deferral window; actual interrupt
recognition remains unimplemented under `CTRL-002`. Simultaneous indirect
update controls remain under `OQ-010`.

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
increment/decrement remains rejected under `OQ-010`; multiply-following
interrupt recognition remains deferred to `CTRL-002`.

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
completes. The functional multiply and one-cycle program/data transaction are
verified, but actual interrupt deferral is not: the current core has no
interrupt entry engine. That gap remains part of `CTRL-002` and prevents this
slice from being complete interrupt evidence
[ti-tms32010-users-guide-spru001b, `MPY`, printed p. 3-43 (PDF p. 93)].
**Confidence: VERIFIED_PRIMARY for the rule; not yet verified in RTL.**

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
program-only transaction, and cycle count are verified, but interrupt
deferral remains unimplemented under `CTRL-002`
[ti-tms32010-users-guide-spru001b, `MPYK`, printed p. 3-44 (PDF p. 94)].
**Confidence: VERIFIED_PRIMARY for the rule; not yet verified in RTL.**

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
deferral window; recognizing a pending interrupt at that boundary remains
unimplemented under `CTRL-002`, so these PAC tests are not interrupt-timing
evidence.

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
documented interrupt-deferral boundary; interrupt recognition at that point
remains outside current evidence under `CTRL-002`.

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
reaches the documented interrupt-deferral boundary; recognition at that point
remains outside current evidence under `CTRL-002`.

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
`LAC`. `SUBH` and `SUBS` are separate encodings and are not implied by this
qualification boundary.

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
