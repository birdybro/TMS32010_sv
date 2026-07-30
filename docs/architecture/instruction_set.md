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
