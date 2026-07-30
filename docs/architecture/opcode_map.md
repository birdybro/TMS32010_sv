# Opcode map status

The canonical machine-readable map is `docs/generated/tms32010_isa.yaml`.
Its initial eighteen-instruction model/tool boundary is intentionally partial
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
| `SACL dma` | `0x5000` | `0xff00` plus addressing constraints | 1 | 1 | individual `SACL` page, printed p. 3-54 |
| `SACH dma,s` | `0x5800` | `0xf800` plus legal-shift/addressing constraints | 1 | 1 | individual `SACH` page, printed p. 3-53 |
| `ADD dma,s` | `0x0000` | `0xf000` plus addressing constraints | 1 | 1 | individual `ADD` page, printed p. 3-10 |
| `ADDS dma` | `0x6100` | `0xff00` plus addressing constraints | 1 | 1 | individual `ADDS` page, printed p. 3-12 |
| `XOR dma` | `0x7800` | `0xff00` plus addressing constraints | 1 | 1 | individual `XOR` page, printed p. 3-68 |
| `AND dma` | `0x7900` | `0xff00` plus addressing constraints | 1 | 1 | individual `AND` page, printed p. 3-13 |
| `OR dma` | `0x7a00` | `0xff00` plus addressing constraints | 1 | 1 | individual `OR` page, printed p. 3-46 |
| `ZALH dma` | `0x6500` | `0xff00` plus addressing constraints | 1 | 1 | individual `ZALH` page, printed p. 3-70 |
| `ZALS dma` | `0x6600` | `0xff00` plus addressing constraints | 1 | 1 | individual `ZALS` page, printed p. 3-71 |

Source: [ti-tms32010-users-guide-spru001b, §3.4.2 and individual instruction
descriptions, printed pp. 3-5–3-7, 3-10, 3-12–3-13, 3-32, 3-34–3-35, 3-37,
3-46, 3-53–3-54, 3-68, and 3-70–3-71 (PDF pp. 55–57, 60, 62–63, 82, 84–85,
87, 96, 103–104, 118, and 120–121)].
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

`SACL` fixes bits 15:8 to `0x50`; bit 7 selects direct or indirect addressing,
and bits 6:0 carry the address/control field. Its indirect legality constraints
are the same as `LAC`. The instruction copies `ACC[15:0]` without a shift; the
assembly-level zero preceding a next ARP is a syntax placeholder and encodes
no shift bits
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `SACL`, printed
pp. 3-2–3-3 and 3-54 (PDF pp. 52–53 and 104)].
**Confidence: VERIFIED_PRIMARY except the rejected simultaneous-update case,
which is UNKNOWN.**

`SACH` fixes bits 15:11 to `01011`; bits 10:8 encode the literal shift count,
but TI permits only 0, 1, and 4. Bit 7 and bits 6:0 retain the common
direct/indirect address form. Current decode rejects the other five shift-field
values and applies the same reserved indirect-control policy as `LAC`/`SACL`
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `SACH`, printed
pp. 3-2–3-3 and 3-53 (PDF pp. 52–53 and 103)].
**Confidence: VERIFIED_PRIMARY except the simultaneous-update case, which is
UNKNOWN.**

`ZALH` and `ZALS` fix bits 15:8 to `0x65` and `0x66`, respectively. Bit 7
selects direct/indirect addressing and bits 6:0 use the same common
address/control encoding as `LAC`, `SACL`, and `SACH`. No shift field is
present. The current decoder applies the same reserved-control and
noncanonical-alias policy to both families
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `ZALH`/`ZALS`, printed
pp. 3-2–3-3 and 3-70–3-71 (PDF pp. 52–53 and 120–121)].
**Confidence: VERIFIED_PRIMARY except the simultaneous-update case, which is
UNKNOWN.**

`ADDS` fixes bits 15:8 to `0x61`; bit 7 and bits 6:0 use the common
direct/indirect address form. Its assembly syntax has no shift placeholder:
an optional next ARP directly follows an indirect operand. The decoder applies
the same reserved-control and noncanonical-alias policy as the other qualified
data instructions
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `ADDS`, printed
pp. 3-2–3-3 and 3-12 (PDF pp. 52–53 and 62)].
**Confidence: VERIFIED_PRIMARY except the simultaneous-update case, which is
UNKNOWN.**

`ADD` fixes bits 15:12 to zero; bits 11:8 encode every shift from 0 through
15, and bit 7 plus bits 6:0 use the common direct/indirect address form. Its
assembly syntax and conservative legality/alias policy match `LAC`
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `ADD`, printed
pp. 3-2–3-3 and 3-10 (PDF pp. 52–53 and 60)].
**Confidence: VERIFIED_PRIMARY except the simultaneous-update case, which is
UNKNOWN.**

`XOR`, `AND`, and `OR` fix bits 15:8 to `0x78`, `0x79`, and `0x7a`,
respectively. Each uses the same no-shift common direct/indirect address form
and conservative legality/alias policy as `ADDS`
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `AND`/`OR`/`XOR`,
printed pp. 3-2–3-3, 3-13, 3-46, and 3-68 (PDF pp. 52–53, 63, 96, and
118)]. **Confidence: VERIFIED_PRIMARY except the simultaneous-update case,
which is UNKNOWN.**

No claim is yet made about unlisted bit patterns. A complete 65,536-word
decode audit is an acceptance criterion of `ISA-001`.
