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
