# Opcode map status

The canonical machine-readable map is `docs/generated/tms32010_isa.yaml`.
Its initial five-instruction executable boundary is intentionally partial
while scan encodings are checked against individual instruction pages and
independent assembly listings. The database separately enumerates all 60
documented mnemonics so missing coverage remains machine-visible.

## Hand-transcribed initial encodings

| Mnemonic | Match | Mask | Words | Cycles | Primary evidence |
|---|---:|---:|---:|---:|---|
| `LACK K` | `0x7e00` | `0xff00` | 1 | 1 | individual `LACK` page, printed p. 3-32 |
| `NOP` | `0x7f80` | `0xffff` | 1 | 1 | Table 3-2, printed p. 3-7 |
| `ZAC` | `0x7f89` | `0xffff` | 1 | 1 | Table 3-2, printed p. 3-5 |
| `ROVM` | `0x7f8a` | `0xffff` | 1 | 1 | Table 3-2, printed p. 3-7 |
| `SOVM` | `0x7f8b` | `0xffff` | 1 | 1 | Table 3-2, printed p. 3-7 |

Source: [ti-tms32010-users-guide-spru001b, §3.4.2 and individual instruction
descriptions, printed pp. 3-5–3-7, 3-32 (PDF pp. 55–57, 82)].
**Confidence: VERIFIED_PRIMARY.**

TI states that `LACK` loads the unsigned eight-bit operand right-justified and
zeros the upper 24 accumulator bits. The historical assembler silently
truncated longer values; the project-local assembler will instead diagnose
out-of-range input unless an explicit compatibility option is introduced
[ti-tms32010-users-guide-spru001b, `LACK`, printed p. 3-32 (PDF p. 82)].

No claim is yet made about unlisted bit patterns. A complete 65,536-word
decode audit is an acceptance criterion of `ISA-001`.
