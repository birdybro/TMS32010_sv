# Opcode map status

The canonical machine-readable map is `docs/generated/tms32010_isa.yaml`.
Its initial nine-instruction model/tool boundary is intentionally partial
while scan encodings are checked against individual instruction pages and
independent assembly listings. The database separately enumerates all 60
documented mnemonics so missing coverage remains machine-visible.

## Hand-transcribed initial encodings

| Mnemonic | Match | Mask | Words | Cycles | Primary evidence |
|---|---:|---:|---:|---:|---|
| `LACK K` | `0x7e00` | `0xff00` | 1 | 1 | individual `LACK` page, printed p. 3-32 |
| `LARK AR,K` | `0x7000` | `0xfe00` | 1 | 1 | individual `LARK` page, printed p. 3-34 |
| `LARP K` | `0x6880` | `0xfffe` | 1 | 1 | individual `LARP` page, printed p. 3-35 |
| `LDPK K` | `0x6e00` | `0xfffe` | 1 | 1 | individual `LDPK` page, printed p. 3-37 |
| `NOP` | `0x7f80` | `0xffff` | 1 | 1 | Table 3-2, printed p. 3-7 |
| `ZAC` | `0x7f89` | `0xffff` | 1 | 1 | Table 3-2, printed p. 3-5 |
| `ROVM` | `0x7f8a` | `0xffff` | 1 | 1 | Table 3-2, printed p. 3-7 |
| `SOVM` | `0x7f8b` | `0xffff` | 1 | 1 | Table 3-2, printed p. 3-7 |
| `LAC dma,s` | `0x2000` | `0xf000` plus addressing constraints | 1 | 1 | individual `LAC` page, printed p. 3-31 |

Source: [ti-tms32010-users-guide-spru001b, §3.4.2 and individual instruction
descriptions, printed pp. 3-5–3-7, 3-32, 3-34–3-35, and 3-37 (PDF
pp. 55–57, 82, 84–85, and 87)].
**Confidence: VERIFIED_PRIMARY.**

TI states that `LACK` loads the unsigned eight-bit operand right-justified and
zeros the upper 24 accumulator bits. The historical assembler silently
truncated longer values; the project-local assembler will instead diagnose
out-of-range input unless an explicit compatibility option is introduced
[ti-tms32010-users-guide-spru001b, `LACK`, printed p. 3-32 (PDF p. 82)].

`LARK` zero-extends its eight-bit constant into the selected 16-bit auxiliary
register. `LARP` and `LDPK` load one-bit constants into the status register's
ARP and DP fields respectively
[ti-tms32010-users-guide-spru001b, individual instruction descriptions,
printed pp. 3-34–3-35 and 3-37 (PDF pp. 84–85 and 87)].

`LAC` uses bits 11:8 for the shift, bit 7 for direct/indirect selection, and
bits 6:0 for either the direct address or indirect control. For indirect
words, bits 6, 2, and 1 must be zero. The database also rejects simultaneous
increment and decrement pending `OQ-010`; it accepts either value of ignored
bit 0 when bit 3 requests ARP preservation
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `LAC`, printed
pp. 3-2–3-3 and 3-31 (PDF pp. 52–53 and 81)].
**Confidence: VERIFIED_PRIMARY except the rejected simultaneous-update case,
which is UNKNOWN.**

No claim is yet made about unlisted bit patterns. A complete 65,536-word
decode audit is an acceptance criterion of `ISA-001`.
