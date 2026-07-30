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
