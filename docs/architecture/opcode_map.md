# Opcode map status

The canonical machine-readable map is `docs/generated/tms32010_isa.yaml`.
Its current model/tool boundary represents all sixty documented mnemonics,
while the database remains explicitly incomplete until every unmatched word
has an authoritative reserved/undocumented classification and all RTL/timing
criteria pass.

## Exhaustive 16-bit classification

The database and `tools.generators.opcode_audit` now partition all 65,536
words without assigning behavior to unsupported encodings. The generated
count table is [tms32010_opcode_audit.md](../generated/tms32010_opcode_audit.md)
and is checked by `make docs`.

| Classification | Count | Evidence boundary |
|---|---:|---|
| `DOCUMENTED_LEGAL` | 21,895 | Exactly one supported instruction entry accepts the word and all field constraints. |
| `PRIMARY_RESERVED_INDIRECT_FIELD` | 10,976 | A documented indirect data-address pattern sets bit 6, 2, or 1, which TI explicitly says is reserved and must be zero. |
| `UNRESOLVED_SIMULTANEOUS_UPDATE` | 372 | Reserved bits and every other enumerated field are legal, but both AR increment and decrement are set; the combination remains `OQ-010`. |
| `DOCUMENTED_PATTERN_MISMATCH` | 3,637 | The word is inside a documented pattern envelope but violates a fixed/enumerated field, such as a nonzero branch-opcode low byte, an unsupported SACH shift, or an out-of-range direct SST field. TI does not call this whole class reserved. |
| `PRIMARY_UNLISTED_ENCODING` | 28,656 | No qualified instruction or declared pattern envelope covers the word, and TI's explicitly complete original instruction-set summary lists no instruction for it. This says nothing about silicon behavior. |

TI explicitly reserves indirect-format bits 6, 2, and 1 and directs software
to program them to zero
[ti-tms32010-users-guide-spru001b, §3.3.2, printed p. 3-2
(PDF p. 52)]. The instruction summary and individual encoding diagrams define
the legal pattern fields but do not provide a blanket statement that every
unlisted 16-bit word is a reserved opcode
[ti-tms32010-users-guide-spru001b, §3.4.2 and individual instruction
descriptions, printed pp. 3-5–3-71 (PDF pp. 55–121)]. **Confidence:
VERIFIED_PRIMARY for the legal decoder and explicitly reserved indirect bits;
UNKNOWN for execution of every other unsupported word.**

The eleven two-word branches have explicit `0xff00` audit envelopes because
their primary encoding diagrams fix the low opcode byte to zero and place the
12-bit target in the following program word. A word such as `0xf401` is thus a
documented-pattern mismatch for BANZ, not a legal BANZ alias and not silently
called reserved. Fixed-control gaps such as `0x7f83` are
`PRIMARY_UNLISTED_ENCODING` because adjacency to DINT/EINT supplies no
instruction pattern or behavior.

SPRU001B §3.4 explicitly calls Table 3-2 the “complete instruction set
summary,” and §3.4.3 says every instruction in that summary is described in
the following pages. SPRU013 independently uses the same completeness wording
for the first-generation family
[ti-tms32010-users-guide-spru001b, §§3.4 and 3.4.3, printed pp. 3-3 and 3-8
(PDF pp. 53 and 58); ti-first-generation-users-guide-1987, §§4.2 and 4.3,
printed pp. 4-6 and 4-11 (PDF pp. 85 and 92)]. This supports
`PRIMARY_UNLISTED_ENCODING` as a documentation fact. It does not turn an
unlisted word into an explicitly reserved encoding or establish whether
silicon aliases, traps, or performs some undocumented operation.

This partition improves provenance and test generation, but
`reserved_encoding_audit_complete` remains false because 28,656 words are
primary-unlisted rather than explicitly reserved and `OQ-010` remains open.
Classification priority is legal,
explicitly reserved indirect bit, otherwise-legal simultaneous update,
documented-pattern mismatch, then primary-unlisted. Thus a word that sets a
primary-reserved bit retains that strongest label even if another field also
mismatches. The architectural model and RTL still
trap unsupported words as a conservative implementation policy; that trap is
not represented as original-silicon behavior.

A separate one-step symbolic RTL proof exhausts all 65,536 input words against
a compact documented-family and canonical-field predicate. It proves the
partial decoder's exact 21,893-word valid boundary, including CALA/RET and
continued rejection of the two model/tool-only PUSH/POP words, and checks
meaningful operand-field projections. Nine covers reach legal, reserved,
simultaneous-update, pattern-mismatch, primary-unlisted, model-only, and MPYK
boundaries independently [`formal/tms32010_decode.sby`]. This is decoder
implementation evidence: the database/fixtures remain the opcode authority,
and no unsupported-word silicon behavior is assigned.

## Hand-transcribed initial encodings

| Mnemonic | Match | Mask | Words | Cycles | Primary evidence |
|---|---:|---:|---:|---:|---|
| `LACK K` | `0x7e00` | `0xff00` | 1 | 1 | individual `LACK` page, printed p. 3-32 |
| `LARK AR,K` | `0x7000` | `0xfe00` | 1 | 1 | individual `LARK` page, printed p. 3-34 |
| `LARP K` | `0x6880` | `0xfffe` | 1 | 1 | individual `LARP` page, printed p. 3-35 |
| `MAR dma` | `0x6800` | `0xff00` plus alias/addressing constraints | 1 | 1 | individual `MAR` page, printed p. 3-42 |
| `LDP dma` | `0x6f00` | `0xff00` plus addressing constraints | 1 | 1 | individual `LDP` page, printed p. 3-36 |
| `LDPK K` | `0x6e00` | `0xfffe` | 1 | 1 | individual `LDPK` page, printed p. 3-37 |
| `DMOV dma` | `0x6900` | `0xff00` plus addressing constraints | 1 | 1 | individual `DMOV` page, printed p. 3-28 |
| `LT dma` | `0x6a00` | `0xff00` plus addressing constraints | 1 | 1 | individual `LT` page, printed p. 3-39 |
| `LTD dma` | `0x6b00` | `0xff00` plus addressing constraints | 1 | 1 | individual `LTD` page, printed p. 3-41 |
| `LTA dma` | `0x6c00` | `0xff00` plus addressing constraints | 1 | 1 | individual `LTA` page, printed p. 3-40 |
| `MPY dma` | `0x6d00` | `0xff00` plus addressing constraints | 1 | 1 | individual `MPY` page, printed p. 3-43 |
| `MPYK K` | `0x8000` | `0xe000` | 1 | 1 | individual `MPYK` page, printed p. 3-44 |
| `PAC` | `0x7f8e` | `0xffff` | 1 | 1 | individual `PAC` page, printed p. 3-48 |
| `APAC` | `0x7f8f` | `0xffff` | 1 | 1 | individual `APAC` page, printed p. 3-14 |
| `SPAC` | `0x7f90` | `0xffff` | 1 | 1 | individual `SPAC` page, printed p. 3-58 |
| `NOP` | `0x7f80` | `0xffff` | 1 | 1 | Table 3-2, printed p. 3-7 |
| `ZAC` | `0x7f89` | `0xffff` | 1 | 1 | Table 3-2, printed p. 3-5 |
| `ROVM` | `0x7f8a` | `0xffff` | 1 | 1 | Table 3-2, printed p. 3-7 |
| `SOVM` | `0x7f8b` | `0xffff` | 1 | 1 | Table 3-2, printed p. 3-7 |
| `DINT` | `0x7f81` | `0xffff` | 1 | 1 | individual `DINT` page, printed p. 3-27 |
| `EINT` | `0x7f82` | `0xffff` | 1 | 1 | individual `EINT` page, printed p. 3-29 |
| `CALA` | `0x7f8c` | `0xffff` | 1 | 2 | individual `CALA` page, printed p. 3-25 |
| `RET` | `0x7f8d` | `0xffff` | 1 | 2 | individual `RET` page, printed p. 3-51 |
| `POP` | `0x7f9d` | `0xffff` | 1 | 2 | individual `POP` page, printed p. 3-49 |
| `PUSH` | `0x7f9c` | `0xffff` | 1 | 2 | individual `PUSH` page, printed p. 3-50 |
| `LST dma` | `0x7b00` | `0xff00` plus addressing constraints | 1 | 1 | individual `LST` page, printed p. 3-38 |
| `SST dma` | `0x7c00` | `0xff00` plus forced-page/direct and indirect constraints | 1 | 1 | individual `SST` page, printed p. 3-59 |
| `LAC dma,s` | `0x2000` | `0xf000` plus addressing constraints | 1 | 1 | individual `LAC` page, printed p. 3-31 |
| `LAR AR,dma` | `0x3800` | `0xfe00` plus addressing constraints | 1 | 1 | individual `LAR` page, printed p. 3-33 |
| `IN dma,PA` | `0x4000` | `0xf800` plus addressing constraints | 1 | 2 | individual `IN` page, printed p. 3-30 |
| `OUT dma,PA` | `0x4800` | `0xf800` plus addressing constraints | 1 | 2 | individual `OUT` page, printed p. 3-47 |
| `TBLR dma` | `0x6700` | `0xff00` plus addressing constraints | 1 | 3 | individual `TBLR` pages, printed pp. 3-64–3-65 |
| `TBLW dma` | `0x7d00` | `0xff00` plus addressing constraints | 1 | 3 | individual `TBLW` pages, printed pp. 3-66–3-67 |
| `SAR AR,dma` | `0x3000` | `0xfe00` plus addressing constraints | 1 | 1 | individual `SAR` pages, printed pp. 3-55–3-56 |
| `SACL dma` | `0x5000` | `0xff00` plus addressing constraints | 1 | 1 | individual `SACL` page, printed p. 3-54 |
| `SACH dma,s` | `0x5800` | `0xf800` plus legal-shift/addressing constraints | 1 | 1 | individual `SACH` page, printed p. 3-53 |
| `ADD dma,s` | `0x0000` | `0xf000` plus addressing constraints | 1 | 1 | individual `ADD` page, printed p. 3-10 |
| `SUB dma,s` | `0x1000` | `0xf000` plus addressing constraints | 1 | 1 | individual `SUB` page, printed p. 3-60 |
| `ADDH dma` | `0x6000` | `0xff00` plus addressing constraints | 1 | 1 | individual `ADDH` page, printed p. 3-11 |
| `ADDS dma` | `0x6100` | `0xff00` plus addressing constraints | 1 | 1 | individual `ADDS` page, printed p. 3-12 |
| `SUBH dma` | `0x6200` | `0xff00` plus addressing constraints | 1 | 1 | individual `SUBH` page, printed p. 3-62 |
| `SUBS dma` | `0x6300` | `0xff00` plus addressing constraints | 1 | 1 | individual `SUBS` page, printed p. 3-63 |
| `SUBC dma` | `0x6400` | `0xff00` plus addressing constraints | 1 | 1 | individual `SUBC` page, printed p. 3-61 |
| `XOR dma` | `0x7800` | `0xff00` plus addressing constraints | 1 | 1 | individual `XOR` page, printed p. 3-68 |
| `AND dma` | `0x7900` | `0xff00` plus addressing constraints | 1 | 1 | individual `AND` page, printed p. 3-13 |
| `OR dma` | `0x7a00` | `0xff00` plus addressing constraints | 1 | 1 | individual `OR` page, printed p. 3-46 |
| `ZALH dma` | `0x6500` | `0xff00` plus addressing constraints | 1 | 1 | individual `ZALH` page, printed p. 3-70 |
| `ZALS dma` | `0x6600` | `0xff00` plus addressing constraints | 1 | 1 | individual `ZALS` page, printed p. 3-71 |
| `BANZ pma` | `0xf400` | `0xffff`; target is following 12-bit word | 2 | 2 | individual `BANZ` page, printed p. 3-16 |
| `BV pma` | `0xf500` | `0xffff`; target is following 12-bit word | 2 | 2 | individual `BV` page, printed p. 3-23 |
| `BIOZ pma` | `0xf600` | `0xffff`; target is following 12-bit word | 2 | 2 | individual `BIOZ` page, printed p. 3-19 |
| `CALL pma` | `0xf800` | `0xffff`; target is following 12-bit word | 2 | 2 | individual `CALL` page, printed p. 3-26 |
| `B pma` | `0xf900` | `0xffff`; target is following 12-bit word | 2 | 2 | individual `B` page, printed p. 3-15 |
| `BLZ pma` | `0xfa00` | `0xffff`; target is following 12-bit word | 2 | 2 | individual `BLZ` page, printed p. 3-21 |
| `BLEZ pma` | `0xfb00` | `0xffff`; target is following 12-bit word | 2 | 2 | individual `BLEZ` page, printed p. 3-20 |
| `BGZ pma` | `0xfc00` | `0xffff`; target is following 12-bit word | 2 | 2 | individual `BGZ` page, printed p. 3-18 |
| `BGEZ pma` | `0xfd00` | `0xffff`; target is following 12-bit word | 2 | 2 | individual `BGEZ` page, printed p. 3-17 |
| `BNZ pma` | `0xfe00` | `0xffff`; target is following 12-bit word | 2 | 2 | individual `BNZ` page, printed p. 3-22 |
| `BZ pma` | `0xff00` | `0xffff`; target is following 12-bit word | 2 | 2 | individual `BZ` page, printed p. 3-24 |

Source: [ti-tms32010-users-guide-spru001b, §3.4.2 and individual instruction
descriptions, printed pp. 3-5–3-7, 3-10, 3-12–3-18, 3-20–3-29,
3-31–3-44, 3-46, 3-48–3-51, 3-53–3-56, 3-58–3-68, and
3-70–3-71 (PDF pp. 55–57, 60, 62–68, 70–79, 81–94, 96, 98–101,
103–118, and 120–121)].
**Confidence: VERIFIED_PRIMARY.**

`IN` and `OUT` fix bits 15:11 to `01000` and `01001`, respectively. Bits
10:8 select port 0–7; bit 7 and bits 6:0 retain the qualified common
direct/indirect data-address form. The same reserved indirect controls and
simultaneous-increment/decrement policy therefore apply. IN transfers the
selected external port to internal data memory; OUT transfers internal data
memory to the selected port. Both are one word and two cycles
[ti-tms32010-users-guide-spru001b, Table 3-2 and `IN`/`OUT`, printed
pp. 3-6, 3-30, and 3-47 (PDF pp. 56, 80, and 97);
ti-tms32010-assembly-guide-spru002b, `IN`/`OUT`, printed pp. 3-30 and 3-47
(PDF pp. 51 and 68)]. **Confidence: VERIFIED_PRIMARY except the rejected
simultaneous-update case, which is UNKNOWN under `OQ-010`.**

`TBLR` and `TBLW` fix bits 15:8 to `0x67` and `0x7d`. Their low byte is the
same qualified common direct/indirect data-address field, so each contributes
140 legal encodings and rejects the same reserved indirect controls. Both
instructions are one word and three cycles; the program-space address comes
from `ACC[11:0]` during execution rather than from an opcode field
[ti-tms32010-users-guide-spru001b, Table 3-2 and `TBLR`/`TBLW`, printed
pp. 3-7 and 3-64–3-67 (PDF pp. 57 and 114–117);
ti-tms32010-assembly-guide-spru002b, `TBLR`/`TBLW`, printed pp. 3-64–3-67
(PDF pp. 85–88)]. **Confidence: VERIFIED_PRIMARY except the rejected
simultaneous-update case, which is UNKNOWN under `OQ-010`.**

`LST` fixes bits 15:8 to `0x7b`; its low byte uses the common qualified
direct/indirect address field. Its encoding, operands, one-word size, and
one-cycle timing are primary-verified. Indirect next-ARP precedence is an
execution-order ambiguity rather than a decode ambiguity and remains
PROVISIONAL under `OQ-015`
[ti-tms32010-users-guide-spru001b, `LST`, printed p. 3-38 (PDF p. 88);
ti-tms32010-assembly-guide-spru002b, `LST`, printed p. 3-38 (PDF p. 59)].

`PUSH` and `POP` are primary-transcribed exact words `0x7f9c` and `0x7f9d`.
Each is one word and two cycles with no operand fields. Both are now in the
machine-readable model/tool list and independent hand-fixture boundary. Their
per-cycle program address and fetched-word ownership are still not established
under `OQ-016`; TI's general pin rule does establish active `MEN` in both
non-I/O cycles, but model/tool decode and state qualification do not imply
RTL/native timing qualification
[ti-tms32010-users-guide-spru001b, `POP`/`PUSH`, printed pp. 3-49–3-50
(PDF pp. 99–100); ti-first-generation-users-guide-1987, `POP`/`PUSH`,
printed pp. 4-55–4-56 (PDF pp. 136–137)].
**Confidence: VERIFIED_PRIMARY for encoding, size, cycle total, and the
every-cycle `MEN` constraint; UNKNOWN for program-address/fetched-word
ownership.**

`CALA` is primary-transcribed exact word `0x7f8c`, with no operand field. It
is one word and two cycles, pushes opcode-PC+1, and selects the program
address in `ACC[11:0]`. It is in the model/tool and independent hand-fixture
boundary, but its second native program-bus cycle remains unknown under
`OQ-007`
[ti-tms32010-users-guide-spru001b, `CALA`, printed p. 3-25 (PDF p. 75);
ti-tms32010-assembly-guide-spru002b, `CALA`, printed p. 3-25 (PDF p. 46)].
**Confidence: VERIFIED_PRIMARY for encoding, size, state effects, and cycle
total; UNKNOWN for the second-cycle external subphases.**

`DINT` and `EINT` are exact adjacent fixed words `0x7f81` and `0x7f82`,
respectively. They have no variable operand bits or aliases. The next word
`0x7f83` remains outside the qualified map and traps; no behavior is inferred
from adjacency
[ti-tms32010-users-guide-spru001b, `DINT` and `EINT`, printed pp. 3-27 and
3-29 (PDF pp. 77 and 79); ti-first-generation-users-guide-1987, `DINT` and
`EINT`, printed pp. 4-32 and 4-34 (PDF pp. 113 and 115)].
**Confidence: VERIFIED_PRIMARY.**

`DMOV` fixes bits 15:8 to `0x69`; bit 7 and bits 6:0 retain the common
qualified direct/indirect address field. Its execution-time destination is
`source+1`, not another opcode field. Reserved indirect controls remain
rejected rather than aliased
[ti-tms32010-users-guide-spru001b, `DMOV`, printed p. 3-28 (PDF p. 78);
ti-tms32010-assembly-guide-spru002b, `DMOV`, printed p. 3-28 (PDF p. 49)].
**Confidence: VERIFIED_PRIMARY.**

`LTA` fixes bits 15:8 to `0x6c`; bit 7 and bits 6:0 retain the same qualified
direct/indirect address-field constraints as LT. Reserved indirect fields are
rejected rather than aliased
[ti-tms32010-users-guide-spru001b, `LTA`, printed p. 3-40 (PDF p. 90);
ti-tms32010-assembly-guide-spru002b, `LTA`, printed p. 3-40 (PDF p. 61)].
**Confidence: VERIFIED_PRIMARY.**

`LTD` fixes bits 15:8 to `0x6b` and uses the same qualified address field.
The data-move destination is an execution-time `source+1`, not another opcode
field. Reserved indirect controls remain rejected rather than aliased
[ti-tms32010-users-guide-spru001b, `LTD`, printed p. 3-41 (PDF p. 91);
ti-tms32010-assembly-guide-spru002b, `LTD`, printed p. 3-41 (PDF p. 62)].
**Confidence: VERIFIED_PRIMARY.**

`APAC` is the exact fixed word `0x7f8f`. No operand fields or aliases are
defined, so neighboring fixed words remain unsupported unless separately
qualified
[ti-tms32010-users-guide-spru001b, `APAC`, printed p. 3-14 (PDF p. 64);
ti-tms32010-assembly-guide-spru002b, `APAC`, printed p. 3-14 (PDF p. 35)].
**Confidence: VERIFIED_PRIMARY.**

`SPAC` is the exact fixed word `0x7f90`. It has no operand fields or aliases;
adjacent words remain unsupported unless independently qualified
[ti-tms32010-users-guide-spru001b, `SPAC`, printed p. 3-58 (PDF p. 108);
ti-tms32010-assembly-guide-spru002b, `SPAC`, printed p. 3-58 (PDF p. 79)].
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

`MAR` fixes bits 15:8 to `0x68`. Direct words `0x6800`–`0x687f` are
documented NOP forms even though they carry an address field. Legal indirect
forms apply only the common AR/ARP update controls and never access the
nominal RAM word. Words `0x6880` and `0x6881` remain canonical `LARP 0/1`
decodes because TI defines `MAR *,0/1` as exact LARP aliases. The remaining
reserved indirect fields follow the existing conservative `OQ-010` policy
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `MAR`, printed
pp. 3-2–3-3 and 3-42 (PDF pp. 52–53 and 92)].
**Confidence: VERIFIED_PRIMARY except the simultaneous-update case, which is
UNKNOWN.**

`LDP` fixes bits 15:8 to `0x6f`; bit 7 and bits 6:0 use the common
direct/indirect data-address field. Its indirect legality constraints and
lossless noncanonical-preserve policy match the qualified no-shift data
instructions. The selected word's bit 0 replaces DP after address resolution
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `LDP`, printed
pp. 3-2–3-3 and 3-36 (PDF pp. 52–53 and 86)].
**Confidence: VERIFIED_PRIMARY except the simultaneous-update case, which is
UNKNOWN.**

`LT` fixes bits 15:8 to `0x6a`; bit 7 and bits 6:0 use the same constrained
common address form as LDP. Every legal word transfers the complete selected
16-bit RAM word into T. The decoder rejects reserved indirect controls and
simultaneous increment/decrement under the same `OQ-010` policy
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `LT`, printed
pp. 3-2–3-3 and 3-39 (PDF pp. 52–53 and 89)].
**Confidence: VERIFIED_PRIMARY except the simultaneous-update case, which is
UNKNOWN.**

`LAC` uses bits 11:8 for the shift, bit 7 for direct/indirect selection, and
bits 6:0 for either the direct address or indirect control. For indirect
words, bits 6, 2, and 1 must be zero. The database also rejects simultaneous
increment and decrement pending `OQ-010`; it accepts either value of ignored
bit 0 when bit 3 requests ARP preservation
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `LAC`, printed
pp. 3-2–3-3 and 3-31 (PDF pp. 52–53 and 81)].
**Confidence: VERIFIED_PRIMARY except the rejected simultaneous-update case,
which is UNKNOWN.**

`LAR` fixes bits 15:11 to `00111` and bits 10:9 to zero; bit 8 selects AR0 or
AR1. Bit 7 and bits 6:0 use the common address form. The decoder rejects
three-bit auxiliary-register values 2–7 and applies the same conservative
indirect-control and alias policy as LAC. When the destination is the
currently selected address AR, the documented special case suppresses
postincrement/postdecrement of the loaded word
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `LAR`, printed
pp. 3-2–3-3 and 3-33 (PDF pp. 52–53 and 83)].
**Confidence: VERIFIED_PRIMARY except the simultaneous-update case, which is
UNKNOWN.**

`SAR` fixes bits 15:11 to `00110`; its auxiliary-register and common-address
fields parallel LAR, with base words `0x3000` and `0x3100`. Its exceptional
ordering differs from LAR: the old selected AR supplies the address, but when
that AR is also the designated source, auto-increment/decrement changes the
value written at that old address
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `SAR`, printed
pp. 3-2–3-3 and 3-55–3-56 (PDF pp. 52–53 and 105–106)].
**Confidence: VERIFIED_PRIMARY except the simultaneous-update case, which is
UNKNOWN.**

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

`SUBS` fixes bits 15:8 to `0x63`; bit 7 and bits 6:0 use the same no-shift
common address form, conservative legality constraints, and alias policy as
`ADDS`
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `SUBS`, printed
pp. 3-2–3-3 and 3-63 (PDF pp. 52–53 and 113)].
**Confidence: VERIFIED_PRIMARY except the simultaneous-update case, which is
UNKNOWN.**

`SUBC` fixes bits 15:8 to `0x64`; bit 7 and bits 6:0 use the same no-shift
common address form and conservative legality/alias policy. Its opcode,
addressing, one-word size, and one-cycle total are primary-verified. The
supported execution boundary is narrower: tests obey TI's requirement that
the following instruction not use ACC, while result availability after a
violation and the exact overflow-producing arithmetic stage remain
`OQ-017`/`OQ-018`
[ti-tms32010-users-guide-spru001b, `SUBC`, printed p. 3-61 (PDF p. 111);
ti-tms32010-assembly-guide-spru002b, `SUBC`, printed p. 3-61 (PDF p. 82)].
**Confidence: VERIFIED_PRIMARY for decode, operands, and timing; PROVISIONAL
for the two execution details named above.**

`BANZ` is the exact first word `0xf400`. The following word contains four
documented zero bits above the 12-bit absolute program address. It is an
operand word, not a separately decoded opcode. The assembler always emits the
canonical zero upper nibble; model and RTL deliberately trap noncanonical
operand words because silicon behavior for those undocumented bits is not
claimed
[ti-tms32010-users-guide-spru001b, `BANZ`, printed p. 3-16 (PDF p. 66);
ti-tms32010-assembly-guide-spru002b, `BANZ`, printed p. 3-16 (PDF p. 37)].
**Confidence: VERIFIED_PRIMARY for the canonical two-word encoding; UNKNOWN
for nonzero upper target-word bits.**

`BLZ`, `BLEZ`, `BGZ`, `BGEZ`, `BNZ`, and `BZ` are exact first words
`0xfa00` through `0xff00` in the listed semantic order. Every following word
uses the same canonical 12-bit absolute-program-address form. No low-byte
operand bits or opcode aliases are defined, so adjacent words with a nonzero
low byte remain unsupported rather than inheriting a condition
[ti-tms32010-users-guide-spru001b, conditional branch descriptions, printed
pp. 3-17–3-18, 3-20–3-22, and 3-24
(PDF pp. 67–68, 70–72, and 74);
ti-tms32010-assembly-guide-spru002b, same descriptions, printed pp. 3-17–3-18,
3-20–3-22, and 3-24 (PDF pp. 38–39, 41–43, and 45)].
**Confidence: VERIFIED_PRIMARY for canonical two-word encodings; UNKNOWN for
nonzero upper target-word bits.**

`BV` is exact first word `0xf500`. Its following word has the same canonical
12-bit absolute-program-address form. No low-byte opcode field is defined, so
`0xf501` through `0xf5ff` remain unsupported
[ti-tms32010-users-guide-spru001b, `BV`, printed p. 3-23 (PDF p. 73);
ti-tms32010-assembly-guide-spru002b, `BV`, printed p. 3-23 (PDF p. 44)].
**Confidence: VERIFIED_PRIMARY for the canonical two-word encoding; UNKNOWN
for nonzero upper target-word bits.**

`BIOZ` is exact first word `0xf600`, with the same canonical following-word
12-bit absolute target. The opcode contains no low-byte field, so `0xf601`
through `0xf6ff` remain unsupported
[ti-tms32010-users-guide-spru001b, `BIOZ`, printed p. 3-19 (PDF p. 69);
ti-tms32010-assembly-guide-spru002b, `BIOZ`, printed p. 3-19 (PDF p. 40)].
**Confidence: VERIFIED_PRIMARY for the canonical two-word encoding; UNKNOWN
for nonzero upper target-word bits.**

`CALL` is exact first word `0xf800`, followed by the same canonical 12-bit
absolute target form. The opcode has no low-byte field, so `0xf801` through
`0xf8ff` remain unsupported
[ti-tms32010-users-guide-spru001b, `CALL`, printed p. 3-26 (PDF p. 76);
ti-tms32010-assembly-guide-spru002b, `CALL`, printed p. 3-26 (PDF p. 47)].
**Confidence: VERIFIED_PRIMARY for the canonical two-word encoding; UNKNOWN
for nonzero upper target-word bits.**

`RET` is the exact fixed word `0x7f8d`; there are no operands or opcode
aliases. Its one-word, two-cycle format is independent of the unresolved
second external bus cycle
[ti-tms32010-users-guide-spru001b, `RET`, printed p. 3-51 (PDF p. 101);
ti-tms32010-assembly-guide-spru002b, `RET`, printed p. 3-51 (PDF p. 72)].
**Confidence: VERIFIED_PRIMARY for encoding, word count, and cycle total.**

`B` is the exact first word `0xf900`. Its following word has the same
documented canonical 12-bit absolute-program-address form as BANZ. The
operand word is not separately decoded. The assembler emits a zero upper
nibble, while model and RTL trap noncanonical operand words rather than claim
behavior for undocumented bits
[ti-tms32010-users-guide-spru001b, `B`, printed p. 3-15 (PDF p. 65);
ti-tms32010-assembly-guide-spru002b, `B`, printed p. 3-15 (PDF p. 36)].
**Confidence: VERIFIED_PRIMARY for the canonical two-word encoding; UNKNOWN
for nonzero upper target-word bits.**

`ADD` fixes bits 15:12 to zero; bits 11:8 encode every shift from 0 through
15, and bit 7 plus bits 6:0 use the common direct/indirect address form. Its
assembly syntax and conservative legality/alias policy match `LAC`
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `ADD`, printed
pp. 3-2–3-3 and 3-10 (PDF pp. 52–53 and 60)].
**Confidence: VERIFIED_PRIMARY except the simultaneous-update case, which is
UNKNOWN.**

`SUB` fixes bits 15:12 to one; bits 11:8 encode every shift from 0 through
15, and bit 7 plus bits 6:0 use the same common direct/indirect address form,
syntax, conservative legality constraints, and lossless alias policy as
`ADD`
[ti-tms32010-users-guide-spru001b, §§3.3.1–3.3.4 and `SUB`, printed
pp. 3-2–3-3 and 3-60 (PDF pp. 52–53 and 110)].
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

## Qualified exact `ABS` encoding

`ABS` is the exact word `0x7f88`. It is represented in the machine-readable
database and independent hand fixture and has no operand fields or aliases
[ti-tms32010-users-guide-spru001b, `ABS`, printed p. 3-9 (PDF p. 59)].
**Confidence: VERIFIED_PRIMARY for encoding; `SC-007`/`OQ-013` scope the
CORROBORATED original-part OV-preservation behavior.**
