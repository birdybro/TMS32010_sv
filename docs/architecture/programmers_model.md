# Programmer's model

## Register inventory

| State | Width | Documented role | Reset/power-up evidence | Confidence |
|---|---:|---|---|---|
| `PC` | 12 | next program address | reset clears to 0 | VERIFIED_PRIMARY |
| `ACC` | 32 | ALU operand/result with guard half | unspecified here | VERIFIED_PRIMARY |
| `P` | 32 | signed multiplier product | unspecified here | VERIFIED_PRIMARY |
| `T` | 16 | multiplier operand | unspecified here | VERIFIED_PRIMARY |
| `AR0`, `AR1` | 16 each | indirect address/counter registers | unspecified here | VERIFIED_PRIMARY |
| `ARP` | 1 | selects active auxiliary register | status bit; reset value unresolved | VERIFIED_PRIMARY |
| `DP` | 1 | selects direct-address data page | status bit; reset value unresolved | VERIFIED_PRIMARY |
| `OV` | 1 | sticky arithmetic overflow | reset behavior unresolved (`OQ-012`) | VERIFIED_PRIMARY for role; UNKNOWN for reset |
| `OVM` | 1 | saturation enable | unchanged by reset | VERIFIED_PRIMARY |
| `INTM` | 1 | interrupt mask | set by reset and `DINT` | VERIFIED_PRIMARY |
| stack | 4 × 12 | PC return stack | contents unspecified | VERIFIED_PRIMARY |

Sources: [ti-tms32010-users-guide-spru001b, §§2.1–2.5, Figures 2-1–2-12,
printed pp. 2-1–2-19 (PDF pp. 25–43)].

Unknown values remain unknown in the architectural specification. Tests may
seed them explicitly. The software reference model may use deterministic
constructor defaults for reproducibility, but those defaults are not physical
reset claims. The RTL's separate `initialize_i` test/FPGA control establishes
the same deterministic modeled state, while physical reset leaves unlisted
state without an assigned reset value; retention is provisional under
`OQ-012`.

Project traces and RTL diagnostics order the four stack entries as
`[top, level_1, level_2, bottom]`. A push inserts the new 12-bit value at
`top`, moves the former top through level 1 toward the bottom, and discards
the former bottom. A pop copies the old top out before shifting deeper entries
toward the top and duplicating the old bottom. Directed model tests now cover
both transformations, including repeated over-push and over-pop behavior.
These names describe the documented stack order without assigning
undocumented physical register indices
[ti-tms32010-users-guide-spru001b, §§2.6.1–2.6.2, printed pp. 2-13–2-14
(PDF pp. 37–38)]. **Confidence: VERIFIED_PRIMARY.**

## Status register

The status register consists of exactly five architecturally described bits:
`OV`, `OVM`, `INTM`, `ARP`, and `DP`. The 16-bit value transferred by `LST`
and `SST` is a status *word representation*, not evidence for eleven
additional writable status bits. `LST` loads all status-register fields
except `INTM`; interrupt masking is controlled by reset, `DINT`, `EINT`, and
interrupt entry
[ti-tms32010-users-guide-spru001b, §2.2.3 and Figure 2-7, printed
pp. 2-14–2-15 (PDF pp. 38–39)]. **Confidence: VERIFIED_PRIMARY.**

| Word bit(s) | SST output | LST input effect | Evidence confidence |
|---|---|---|---|
| 15 | `OV` | replaces `OV` | VERIFIED_PRIMARY |
| 14 | `OVM` | replaces `OVM` | VERIFIED_PRIMARY |
| 13 | `INTM` | ignored; `INTM` is preserved | VERIFIED_PRIMARY |
| 12:9 | `1111` | ignored | VERIFIED_PRIMARY |
| 8 | `ARP` | replaces `ARP` | VERIFIED_PRIMARY |
| 7:2 | `111111` | ignored | VERIFIED_PRIMARY |
| 1 | project writes `1`; reserved/don't-care to software | ignored | CORROBORATED output, VERIFIED_PRIMARY input irrelevance |
| 0 | `DP` | replaces `DP` | VERIFIED_PRIMARY |

SPRU001B Figure 2-7, the original `LST` page, and the original `SST` page all
draw ones in positions 12:9 and 7:2. The two original instruction pages also
draw bit 1 as one, but Figure 2-7 alone marks that position don't-care. Later
SPRU013 figures disagree between zero, reserved, and a worked value of one;
`SC-008` therefore isolates bit 1 as the only unresolved stored-value
confidence boundary. No reserved position is modeled as writable state.

For `LST`, source bits 15, 14, 8, and 0 replace `OV`, `OVM`, `ARP`, and `DP`;
source bit 13 does not alter `INTM`, and source bits 12:9 and 7:1 have no
architectural effect. Direct address resolution uses the old `DP`. Indirect
address and counter selection use the old `ARP`. Original-part manuals expose
both a memory-sourced ARP and optional next-ARP encoding without declaring
their precedence. Current model/RTL gives the memory word final precedence,
as later TI TMS320C25 documentation states and pinned MAME independently
corroborates; this is PROVISIONAL for the TMS32010 under `OQ-015`
[ti-tms32010-users-guide-spru001b, `LST`, printed p. 3-38 (PDF p. 88);
ti-tms32010-assembly-guide-spru002b, `LST`, printed p. 3-38 (PDF p. 59);
ti-tms320c25-users-guide-spru012-1986, `LST`, printed p. 4-75
(PDF p. 170)]. **Confidence: VERIFIED_PRIMARY for status fields, address
ordering, and one-cycle result; PROVISIONAL for next-ARP precedence.**

`SST` stores `OV:OVM:INTM:1111:ARP:1111111:DP`. The ten non-field positions
12:9 and 7:2 are unambiguously one in the original guide; bit 1 is the sole
conflicting position retained under `SC-008`/`OQ-003`. Direct SST ignores DP and
forces original-part page 1, so its legal direct offsets 0–15 select physical
RAM locations `0x80`–`0x8f`. Indirect SST captures the word—including the old
ARP—at the old selected-AR address, then applies the ordinary AR and optional
ARP post-modifications. The output bit at position 1 remains architecturally
reserved but is stored as one: both original instruction pages draw one,
later TI prose
says SST reads reserved bits as ones, both TI worked representations set it,
and pinned MAME independently forces mask `0x1efe`. `SC-008`/`OQ-003` preserve
the source conflict and physical-evidence boundary. **Confidence:
VERIFIED_PRIMARY for defined fields, forced-page/direct and indirect address
rules, one-cycle behavior, bits 12:9 and 7:2 being one, and all ignored LST
positions; CORROBORATED for reserved bit 1 and
pre-update-status ordering.**

`ABS` interprets the complete accumulator as signed two's-complement. It
leaves nonnegative values unchanged and negates ordinary negative values.
For `0x80000000`, OVM clear retains that wrapped value and OVM set selects
`0x7fffffff`. Prior `OV` is preserved; `SC-007`/`OQ-013` records the primary
instruction-format rule, the C14/E14 variant difference, and independent MAME
corroboration. **Confidence: VERIFIED_PRIMARY for the result and OVM
selection; CORROBORATED for OV preservation.**

`ADDH` adds the complete selected 16-bit word to `ACC[31:16]` modulo 2^16
and always preserves `ACC[15:0]`. On the original part, incoming `OV` is
preserved and `OVM` has no effect. That status conclusion follows SPRU013's
instruction-format rule and original ADDH page omission, reinforced by the
later C14/E14 variant explicitly adding OV/OVM behavior; it has not been
measured on original silicon
[ti-tms32010-users-guide-spru001b, `ADDH`, printed p. 3-11 (PDF p. 61);
ti-first-generation-users-guide-1987, §4.3 and `ADDH`, printed pp. 4-11–4-16
(PDF pp. 92–97); ti-tms320c14-e14-users-guide-1988, `ADDH`, printed p. 4-16
(PDF p. 123); `SC-017`/`OQ-011`]. **Confidence: VERIFIED_PRIMARY for
ordinary result, low-half preservation, and timing; CORROBORATED for OV
preservation and OVM independence.**

`SUBH` subtracts the selected 16-bit word aligned to `ACC[31:16]`. Ordinary
and OVM-clear wrapped results preserve `ACC[15:0]`; signed overflow sets
sticky `OV`, and OVM-enabled overflow replaces the complete ACC with the
documented positive or negative endpoint. The apparent tension between
“low-order bits unaffected” and full-accumulator saturation is resolved in
`SC-016`
[ti-tms32010-users-guide-spru001b, `SUBH`, printed p. 3-62 (PDF p. 112);
ti-first-generation-users-guide-1987, §3.5.2 and `SUBH`, printed
pp. 3-19–3-20 and 4-69 (PDF pp. 48–49 and 150)].
**Confidence: VERIFIED_PRIMARY.**

`SUBC` is documented as affecting `OV` and as ignoring `OVM`, so its result
never saturates. The located original and later TI instruction descriptions
do not identify which internal subtraction/shift stage produces OV. The
current model and RTL provisionally set sticky OV on signed overflow in the
intermediate `ACC - (unsigned_data << 15)` subtraction and leave a previously
set OV high. This is `OQ-018`, not a verified original-silicon claim
[ti-first-generation-users-guide-1987, `SUBC`, printed pp. 4-67–4-68
(PDF pp. 148–149); ti-tms32010-users-guide-spru001b, §2.2.2.1 and `SUBC`,
printed pp. 2-5 and 3-61 (PDF pp. 29 and 111)]. **Confidence:
VERIFIED_PRIMARY for affected status and OVM independence; PROVISIONAL for
the overflow stage.**

Related-embodiment patent circuitry supports the intermediate-stage choice,
while pinned IKA32010 assigns its flag to the delayed final result and pinned
MAME's intermediate check is ineffective. The project therefore retains the
reversible policy and supplies a two-vector original-device probe rather than
promoting it to verified silicon behavior; see
`docs/research/subc_pipeline_experiment.md`
[ti-dsp-microcomputer-patent-us4577282a, patent cols. 21-24 (PDF pp. 37-38),
Figure 5c].

The qualified functional slice writes `INTM=1` for exact opcode `DINT`
(`0x7f81`) and `INTM=0` for exact opcode `EINT` (`0x7f82`). DINT takes effect
immediately. EINT's architectural bit write is immediate, but interrupt
service remains inhibited until the following instruction completes when it
enables a previously disabled pending request. Current model/RTL tests verify
the bit writes, latched active-low request, required deferral, multiply
deferral, return-PC stack push, vector-2 selection, entry masking, and pending
clear. The model reports the non-instruction entry boundary as mnemonic
`INTERRUPT` with one `interrupt_dummy_fetch` transaction so single stepping
does not pretend the discarded word executed
[ti-tms32010-users-guide-spru001b, §2.4.1 and `DINT`/`EINT`, printed
pp. 2-18–2-19 and 3-27/3-29 (PDF pp. 42–43, 77, and 79)].
**Confidence: VERIFIED_PRIMARY for those architectural effects and the tested
fetch order; VERIFIED_SIMULATION for the basic protected/discard/vector
ownership path and MPY/MPYK protected-slot extension. The complete
multicycle-arrival matrix remains `OQ-004`.**

## Addressing

Direct operands concatenate `DP` with the instruction's seven-bit `D` field.
Page 0 spans addresses 0–127; only addresses 128–143 are implemented on page
1 in the original TMS32010. Access outside the physical 144-word internal RAM
requires explicit primary-source resolution before a model or RTL behavior is
assigned
[ti-tms32010-users-guide-spru001b, §§2.1.1, 3.3, printed pp. 2-3,
3-1–3-3 (PDF pp. 27, 51–53)]. **Confidence: VERIFIED_PRIMARY.**

Indirect addressing uses the low eight bits of the AR selected by `ARP`, then
performs the encoded post-modification. The instruction may increment,
decrement, preserve, or update `ARP`. Reserved indirect-mode bits must be zero.
The memory access uses the pre-modification address
[ti-tms32010-users-guide-spru001b, §3.3 and Figure 3-1, printed pp. 3-1–3-3
(PDF pp. 51–53)]. **Confidence: VERIFIED_PRIMARY.**

Auto-increment and auto-decrement modify the low nine bits as a circular
counter, not the whole 16-bit register: incrementing `AR[8:0]=0x1ff` produces
zero and decrementing zero produces `0x1ff`, while `AR[15:9]` is unchanged
[ti-tms32010-users-guide-spru001b, §2.4.1 and Figure 2-3, printed
pp. 2-9–2-10 (PDF pp. 33–34)]. **Confidence: VERIFIED_PRIMARY.**

`IN` and `OUT` combine that same direct/indirect internal-data address with a
separate three-bit port number. `IN` samples all 16 external data bits from
the selected port and writes them unchanged to the old resolved internal-RAM
address. `OUT` reads the old resolved internal-RAM address and drives all 16
bits unchanged to the selected port. Either instruction applies the encoded
indirect AR/ARP update only after using the old address. The port appears on
physical address pins A2–A0 during the second machine cycle; A11–A3 are zero,
so it is an eight-port I/O space rather than an extension of internal data
memory
[ti-tms32010-users-guide-spru001b, `IN`/`OUT` and Appendix A I/O timing,
printed pp. 3-30 and 3-47 plus data-sheet pp. 17–18
(PDF pp. 80, 97, and 373–374)]. **Confidence: VERIFIED_PRIMARY.**

## Program sequencing

Program address 0 is the reset entry and address 2 is the interrupt vector.
Absolute branches carry their 12-bit target in the second program word.
`CALA` obtains the target from the low 12 accumulator bits and pushes
opcode-PC+1 before selecting that target. It is one word and two cycles.
The explicit pipeline implements ADR-0003's discarded-`PC+1` then target-fetch
mapping at `INFERRED` confidence. Directed tests prove both external reads,
stall retention, discarded-word nonexecution, retirement-only stack/PC
effects, and interrupt deferral across either interval; original-pin
confirmation remains open under `OQ-007`/`SC-037`
[ti-tms32010-users-guide-spru001b, §2.6.1 and `CALA`, printed pp. 2-13 and
3-25 (PDF pp. 37 and 75)]. **Confidence: VERIFIED_PRIMARY for architectural
effects and cycle total; INFERRED for the combined fetch mapping; UNKNOWN for
physical confirmation.**

Direct `CALL` carries its target in the following program word, pushes
opcode-PC+2 as the return address, and then loads the target into PC. A full
stack silently discards the old bottom level
[ti-tms32010-users-guide-spru001b, Table 3-2 and `CALL`, printed pp. 3-6 and
3-26 (PDF pp. 56 and 76)]. **Confidence: VERIFIED_PRIMARY.**

`RET` loads PC from the old top and pops the four-level stack, duplicating
the old bottom into the vacated bottom level. It is one word and two cycles
[ti-tms32010-users-guide-spru001b, §2.6.2 and `RET`, printed pp. 2-14 and
3-51 (PDF pp. 38 and 101); ti-first-generation-users-guide-1987, `RET`,
printed p. 4-57 (PDF p. 138)]. **Confidence: VERIFIED_PRIMARY for
programmer-visible effects and cycle total. ADR-0003 gives RET the same
reversible discarded-`PC+1` then old-TOS-target mapping as CALA at `INFERRED`
confidence. The same directed bus/stall/interrupt qualification applies;
physical confirmation remains `OQ-007`/`SC-037`.**
