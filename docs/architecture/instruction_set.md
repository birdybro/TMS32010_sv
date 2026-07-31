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
