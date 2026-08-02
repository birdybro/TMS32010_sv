# TMS32010 architecture research baseline

## Status and citation convention

This is a cited research baseline, not yet a complete implementation
specification. `VERIFIED_PRIMARY` means the statement is explicit in a
first-party source; it does not mean the corresponding RTL or timing test
exists. Open items are linked to `docs/research/open_questions.md`.

Citation keys resolve through `docs/references/manifest.yaml`:

- `ti-tms32010-users-guide-spru001b`: TI, *TMS32010 User's Guide*,
  revision B, March 1985.
- `ti-first-generation-users-guide-1987`: TI, *First-Generation TMS320
  User's Guide*, 1987.
- `atari-driver-sound-board-schematic`: Atari drawing A044427 Driver Sound
  Board schematics.
- `mame-*`: MAME commit
  `030fefcbd14e47c01ec9d67655be90f64a1dc8ab`, used only as an independent
  secondary reference.

## Device identity and scope

The target is the original ROMless NMOS TMS32010 in microprocessor mode:
144 words of on-chip data RAM and up to 4096 words of external program
memory. The 1987 family guide separately identifies the TMS320C10 as a CMOS
part and the C15/E15 as 256-word-RAM parts. Object-code or pin compatibility
does not prove identical undocumented behavior or electrical timing
[ti-tms32010-users-guide-spru001b, §2.1.1, printed pp. 2-1–2-3 (PDF
pp. 25–27); ti-first-generation-users-guide-1987, §1.1, printed
pp. 1-2–1-4]. **Confidence: VERIFIED_PRIMARY.**

The default core will not expose on-chip program ROM, expanded C15 RAM, C17
serial peripherals, or later-family instructions. Variant parameterization is
deferred until the base part is objectively qualified.

Primary publications expose several original-NMOS speed-grade names and a
sequence of revised data sheets, but no located source maps those labels or
the package tracking/date field to a silicon-mask revision. Later 1989 product
tables omit the earlier NMOS -14/-25 listings without calling the change a
functional revision. Publication revision, speed grade, package/temperature
suffix, tracking/date string, lot, ROM sibling, and later CMOS device identity
therefore remain separate provenance dimensions; none selects architectural
RTL behavior. `SC-043`, `OQ-008`, and
`docs/research/device_revision_audit.md` preserve the exact timeline and
physical-specimen requirements. **Confidence: VERIFIED_PRIMARY for the
publication/product-list distinction; UNKNOWN for mask identities or
behavioral differences.**

## Data path

The programmer-visible data path comprises a 32-bit accumulator and ALU, a
16-bit T register, a signed 16-by-16 parallel multiplier with 32-bit P
register, two 16-bit auxiliary registers, a one-bit auxiliary-register
pointer, and a data-page bit. A barrel shifter aligns data-memory operands
before the ALU; a separate output shifter supports accumulator stores
[ti-tms32010-users-guide-spru001b, §2.1 and Figures 2-1/2-2, printed
pp. 2-1–2-7 (PDF pp. 25–31)]. **Confidence: VERIFIED_PRIMARY.**

The portable RTL represents this input path as a standalone combinational
16-to-32-bit signed shifter. A one-step symbolic proof leaves all 16 data bits
and all four count bits arbitrary, builds an independent bit-index reference,
and checks every 0-through-15 shift without relying on instruction decode
[`formal/tms32010_input_shifter.sby`]. This is exhaustive RTL relation
evidence, not proof of addressing, ALU effects, instruction timing, or the
original physical barrel-shifter implementation.

The portable RTL represents SACH's separate output path as a combinational
ACC-to-word shifter for the only primary-documented counts, zero, one, and
four [ti-tms32010-users-guide-spru001b, §2.2.4.2, printed p. 2-16
(PDF p. 40), and SACH, printed p. 3-53 (PDF p. 103)]. Only ACC[31:12] can
reach the stored high word at those counts, so the
module's narrowed input is an implementation convenience rather than a claim
about the original physical shifter. Its one-step symbolic harness leaves the
full 32-bit ACC and three-bit field arbitrary and constructs every stored bit
from an independent source index [`formal/tms32010_output_shifter.sby`]. It
therefore also proves that ACC[11:0] cannot affect the result. The local zero
result for the five invalid fields is fail-closed implementation policy; the
architectural decoder rejects those fields, and no original-silicon behavior
is assigned to them. This relation evidence does not prove SACH addressing,
write timing, or bus ownership.

Arithmetic uses two's-complement values. The ALU is 32 bits wide. A
data-memory operand is sign-extended before a documented left shift of 0–15
places; zeros enter at the low end. Instructions that suppress sign extension
are called out individually. Logical operations act on the upper accumulator
half as a zero operand and combine the selected 16-bit RAM word with
`ACC[15:0]`. Consequently `AND` clears `ACC[31:16]`, while `OR` and `XOR`
preserve it; all three place their logical result in `ACC[15:0]` and cannot
overflow
[ti-tms32010-users-guide-spru001b, `AND`, `OR`, and `XOR`, printed
pp. 3-13, 3-46, and 3-68 (PDF pp. 63, 96, and 118);
ti-first-generation-users-guide-1987, §3.5.2, printed pp. 3-19–3-20
(PDF pp. 48–49)]. **Confidence: VERIFIED_PRIMARY.**

The overflow flag `OV` is sticky until `BV` or a status load clears it. With
overflow mode `OVM` set, positive and negative overflows clamp to
`0x7fff_ffff` and `0x8000_0000`, respectively. With `OVM` clear, the wrapped
overflow result is loaded without saturation and `OV` is still set. The older
SPRU001B paragraph contains one contradictory sentence, but its following
explanation and the later TI SPRU013 architecture and `ROVM` descriptions
unambiguously establish the latter behavior
[ti-tms32010-users-guide-spru001b, §2.2.1.1, printed p. 2-4 (PDF p. 28);
ti-first-generation-users-guide-1987, §3.5.2 and `ROVM`, printed pp. 3-20 and
4-58 (PDF pp. 49 and 139); `SC-001`]. **Confidence: CORROBORATED for the
resolved contradiction; VERIFIED_PRIMARY for sticky `OV` and saturation
endpoints.**

## Control path

The PC is 12 bits. A four-level, 12-bit hardware stack supports branches,
calls, returns, interrupts, `PUSH`, and `POP`. Stack overflow discards the
deepest value; popping beyond the bottom propagates the bottom value upward
[ti-tms32010-users-guide-spru001b, §§2.6.1–2.6.2, printed pp. 2-13–2-14
(PDF pp. 37–38)]. **Confidence: VERIFIED_PRIMARY.**

The portable `tms32010_stack` block expresses that four-word state change as
a combinational relation: push inserts a new top and discards the old bottom;
pop promotes the three lower entries and duplicates the old bottom. Its table
mode expresses only the documented *final* TBLR/TBLW relation, in which the
old level-2 entry replaces the old bottom after the temporary PC push/pop; it
does not expose or assign visibility to the temporary internal state
[ti-tms32010-users-guide-spru001b, §2.6.2 and `POP`/`PUSH`/`TBLR`/`TBLW`,
printed pp. 2-14, 3-50–3-52, and 3-65–3-68 (PDF pp. 38, 99–101, and
114–117)]. **Confidence: VERIFIED_PRIMARY for the architectural relations;
implementation policy for rejecting simultaneous operation controls and
holding state.** The caller continues to own every commit boundary and
external cycle. In particular, the primitive does not resolve `PUSH`/`POP`
program-bus ownership under `OQ-016`.

A depth-80 composed-pipeline proof now reaches the same final table relation
from four distinct CALL-created stack words: fixed indirect TBLR preserves
`{TOS,L1,L2}` and replaces the old bottom with old L2 only at the repeated-
prefetch boundary. The complete transfer/following-LAC path reaches cover step
74 [`formal/tms32010_pipeline_table_indirect_stack.sby`]. This is bounded
evidence for one fixed path, not visibility of the temporary internal stack
state or a general stack/pipeline proof.

The portable `tms32010_auxiliary_counter` block expresses the documented AR
post-modification arithmetic as a combinational relation. Hold preserves all
16 bits. Exclusive increment or decrement wraps only `AR[8:0]` modulo 512 and
preserves `AR[15:9]` [ti-tms32010-users-guide-spru001b, §2.4.1 and Figure
2-3, printed pp. 2-9–2-10 (PDF pp. 33–34)]. **Confidence:
VERIFIED_PRIMARY for hold and each exclusive update.** The caller still owns
old-ARP selection, pre-update address use, ARP replacement, LAR suppression,
SAR stored-result ordering, and every retirement boundary. Both controls set
is invalid, holds locally, and raises a validity result as fail-closed
implementation policy; it is not a claim about original silicon and remains
UNKNOWN under `OQ-010`/`SC-040`.

The processor fetches an instruction while executing the preceding
instruction. Multiword and multicycle operations disturb this overlap in
documented ways; those phase sequences are not yet fully transcribed
[ti-tms32010-users-guide-spru001b, §§2.1, 3.4.2, printed pp. 2-1, 3-5–3-7
(PDF pp. 25, 55–57)]. **Confidence: VERIFIED_PRIMARY for overlap and listed
cycle counts; UNKNOWN for the complete phase-level matrix.**

## Physical clock envelope

The original TMS32010-20 accepts either a 6.7–20.5 MHz crystal or an external
master clock. For the external-clock option, TI requires a 48.78–150 ns
master-clock period and a high/low pulse duration within 47.5–52.5% of that
period. `CLKOUT` is four master-clock periods, so the corresponding specified
machine-cycle envelope is 195.12–600 ns. These are timing requirements over
recommended operating conditions, not nominal suggestions
[ti-tms32010-users-guide-spru001b, §2.12 and Appendix A data sheet, Clock
Characteristics and Timing, printed pp. 2-20 and data-sheet pp. 10–11 (PDF
pp. 44 and 366–367)]. **Confidence: VERIFIED_PRIMARY.**

Consequently a physical device may be slowed only while every input-clock
period and pulse width remains inside that envelope. A stopped clock or an
arbitrarily extended high/low phase is outside TI's specified conditions;
there is no native transaction-by-transaction wait handshake. The RTL
`clock_enable_i` pause remains a platform emulation feature and must not be
used as a pin-compatible electrical claim. TI does not separately characterize
dynamic frequency modulation between otherwise conforming periods.

## Reset baseline

`RS` is active low and must remain low for at least five complete `CLKOUT`
machine cycles (twenty crystal/input-clock periods).
After the current machine cycle completes, reset synchronously clears the PC,
sets the interrupt mask, clears the interrupt flag, and drives `MEN`, `DEN`,
and `WE` inactive high while the data bus is high impedance. Reset does not
change `OVM`. Other register reset/power-up values are not specified by this
pass and must not be invented
[ti-tms32010-users-guide-spru001b, §2.11, printed p. 2-19 (PDF p. 43)].
**Confidence: VERIFIED_PRIMARY.**

Appendix A resolves the external first-fetch sequence: after reset release,
normal operation resumes after one complete processor cycle and reads address
0 followed by address 1. The current wrapper offers a separate explicit
FPGA/test initialization input that establishes deterministic modeled state;
it is not physical `RS` behavior and does not initialize RAM. Physical reset
assigns no value to unlisted RTL state, so it retains prior FPGA state as a
conservative implementation policy pending `OQ-012`, not as a verified
physical-device claim
[ti-tms32010-users-guide-spru001b, Appendix A reset timing, printed data-sheet
p. 19 (PDF p. 375)]. **Confidence: VERIFIED_PRIMARY.**

SPRU005A adds contemporary development-system evidence without closing the
production omission: its `EX` and `RUN` descriptions say a warm EVM RESET
saves every TMS32010 register except PC, and its register menu enumerates ACC,
T, P, both ARs, OV/OVM, DP/ARP, and stack. The same guide also warns that the
uncontrolled halt clears registers and may corrupt memory without documenting
the monitor's save-before-clear mechanism. This **CORROBORATES** register
recoverability in the EVM workflow but does not assign the original reset
network. `SC-042` and the complementary BIO-selected before/after fixtures in
`docs/research/reset_retention_experiment.md` preserve that boundary
[ti-tms32010-evm-users-guide-spru005a, Section 2.3.10.2, Table 3-2, and
`EX`/`RUN`, printed pp. 2-28-2-29, 3-4-3-5, 3-27-3-28, and 3-56-3-57
(PDF pp. 39-40, 45-46, 68-69, and 97-98)].

A dedicated actual-core test now establishes nonzero ACC, T, P, AR0/AR1,
ARP, DP, stack, OV, and OVM state before reset. It verifies the documented PC,
interrupt-mask/flag, and inactive-transaction effects, proves that reset has
priority over the core clock enable, and checks the explicitly labeled
provisional retention policy, including internal RAM. A 10-step bounded proof
independently checks the exposed register/control transition relation and
reaches a nonzero-ACC/OVM reset cover at step 5. These are implementation
checks at an already-recognized reset boundary; they do not establish unknown
original-silicon register values or replace the separate native phase test
[`sim/unit/tb_reset.sv`, `formal/tms32010_reset.sby`,
`sim/bus/tb_program_bus_phase.sv`].

The native program-bus phase engine has a separate 40-step bounded proof. It
keeps logical reset, clock enable, program-read qualification, and next
address arbitrary while proving phase progression, boundary-only reset
recognition, inactive address-zero state, the complete release-wait cycle,
first-read activation, `MEN` qualification, and stall behavior. A nonvacuity
cover holds reset for five complete cycles and reaches the address-1 sample at
step 34. This proves only the repository's digital phase mapping; it does not
establish physical setup/hold compliance or any TI-unlisted architectural
reset value [`formal/tms32010_program_bus_reset.sby`].
**Source confidence: VERIFIED_PRIMARY; implementation evidence: bounded
formal at the stated bound; VERIFIED_HARDWARE is not claimed.**

## Current qualification boundary

The executable model and local assembler/disassembler support all 60
documented mnemonics:
`ABS`, `ADD`, `ADDH`, `ADDS`, `AND`, `APAC`, `B`, `BANZ`,
`BGEZ`, `BGZ`, `BIOZ`, `BLEZ`, `BLZ`, `BNZ`, `BV`, `BZ`, `CALA`, `CALL`, `DINT`,
`DMOV`, `EINT`, `IN`, `LAC`, `LACK`, `LAR`, `LARK`, `LARP`, `LDP`, `LDPK`,
`LST`, `LT`, `LTA`, `LTD`, `MAR`, `MPY`, `MPYK`, `NOP`, `OR`, `OUT`, `PAC`,
`POP`, `PUSH`, `RET`, `ROVM`, `SACL`, `SACH`, `SAR`, `SOVM`, `SPAC`, `SST`, `SUB`, `SUBC`, `SUBH`, `SUBS`,
`TBLR`, `TBLW`, `XOR`, `ZAC`, `ZALH`, and `ZALS`. RTL and seeded
differential support the same set except POP and PUSH, for 58 shared
mnemonics. CALA/RET effects and totals are primary-qualified; their explicit
bus ownership uses ADR-0003's reversible mapping, CORROBORATED for RET by a
related contemporary TI patent and still `INFERRED` for CALA. PUSH/POP external
address ownership remains unresolved under `OQ-016`. The 26 common-address data/table instructions plus SST's
forced-page direct form have independent
fixtures plus directed and
seeded tests for direct/indirect address selection, reads or writes,
accumulator behavior, and nine-bit counter updates. SACH additionally verifies
all three documented output shifts and rejects all five other field values.
ABS has an exact fixed encoding and program-only one-cycle boundary; directed
model/RTL tests cover zero, positive, ordinary negative, and most-negative
values in both OVM modes while preserving incoming OV. Result, OVM selection,
and timing are `VERIFIED_PRIMARY`; original-part OV preservation is
`CORROBORATED` by SPRU013's instruction-format rule, the original ABS page's
absence of status annotations, the later C14/E14 variant's explicit status
annotation, and pinned MAME (`SC-007`/resolved `OQ-013`).
ADDH performs a modulo-2^16 addition of the selected word into ACC[31:16]
while preserving ACC[15:0]. The original-family instruction-format contract
lists neither OV nor OVM, whereas the later C14/E14 variant explicitly adds
both. Model/RTL boundary matrices therefore preserve incoming OV and ignore
OVM at `CORROBORATED` confidence under `SC-017`/resolved `OQ-011`; original-
silicon boundary measurement is still required to upgrade that confidence.
The exact fixed `DINT`/`EINT` words set and clear `INTM` in one program-only
cycle while preserving unrelated exposed state. The partial model and RTL now
also latch active-low requests while masked, apply EINT's
previously-disabled following-instruction deferral and MPY/MPYK's protection,
dummy-fetch the return PC, push it, mask and clear the request, and select
vector 2. Directed native testing verifies the Figure 2-12 external address
order, and the explicit pipeline qualifies its basic protected-word/
discarded-N+2/vector ownership plus MPY/MPYK extension through one additional
instruction. The existing core/explicit matrices plus four CALA/RET explicit
cases cover all 36 represented request-arrival intervals across 17 supported
multicycle families. PUSH/POP second-cycle sequencing, physical confirmation
of ADR-0003, and provisional DINT-at-final-boundary ordering
remain outside a cycle-accuracy claim under
`OQ-004`/`OQ-007`/`OQ-016`/`OQ-019`.
Later mixed-family SPRU013 also conflicts with original Figure 2-12 by
dummy-fetching N+1 rather than executing it and by requiring external NMOS
interrupt synchronization. `SC-039` preserves that conflict; the stable DINT
race probe has no expected silicon result.
PUSH and POP have primary-cited model/tool state and two-cycle evidence, but
their second native program cycles and all RTL/differential behavior remain
outside the qualified boundary under `OQ-016`.
`LST` reads through the common address path and replaces `OV`, `OVM`, `ARP`,
and `DP` from bits 15, 14, 8, and 0 while preserving `INTM`. The original
manuals' status-restore contract and `LST *,1` worked result admit opposing
same-instruction precedence readings. Later TI/MAME implement memory-wins,
while pinned IKA implements encoded-field-wins; the current memory-word policy
remains PROVISIONAL under `OQ-015`/`SC-009` pending the stable original-NMOS
probe.
The portable `tms32010_status_word` block now centralizes only the
primary-defined SST packing and LST field extraction. Address ownership,
`INTM` preservation, update precedence, and commit timing stay outside that
relation, so its exhaustive one-step proof does not resolve the provisional
next-ARP behavior.
ZALH and ZALS verify high-half placement and low-half zero extension,
respectively. ADDS verifies unsigned operands, sticky overflow, wrapped
`OVM=0` results, and positive `OVM=1` saturation. AND, OR, and XOR verify the
documented low-half result, their distinct upper-half effects, and unchanged
`OV`/`OVM`. ADD verifies signed source extension, all shift-field bounds,
sticky overflow, wrapped results, and both OVM saturation endpoints. SUB
verifies the corresponding signed subtraction, shift, sticky-overflow, wrap,
and saturation cases.
SUBS verifies unsigned-source subtraction, sticky overflow, negative wrap,
and negative saturation without importing SUB's sign extension.
SUBC verifies TI's conditional subtract/divide recurrence, unsigned
16-bit divisor alignment at bit 15, both conditional result paths, and the
documented 65-divided-by-7 example. The test stream inserts an ACC-free
instruction after every SUBC as TI requires. The partial implementation
commits ACC at the SUBC retirement boundary and sets sticky OV from signed
overflow in the intermediate subtraction; those two details are explicitly
PROVISIONAL under `OQ-017`/`OQ-018` rather than silicon timing claims.
A contemporary TI patent corroborates a related Q4/Q1/Q2 intermediate path,
following-state Q3 accumulator shift, and earlier ALU-derived status path,
but differs in its two-state count. The stable physical probes in
`docs/research/subc_pipeline_experiment.md` therefore narrow rather than
resolve those claims.
LAR verifies 16-bit loads to either auxiliary register, including suppression
of an indirect counter update when the destination also supplied the address.
SAR verifies 16-bit stores from either auxiliary register, including its
post-modified-value store when the source also supplied the old address.
MAR verifies direct no-operation forms and indirect AR/ARP modification
without a logical or physical data-memory access; its two LARP alias words
retain canonical LARP decode. Unresolved addresses trap rather than alias.
LDP reads through the old DP or selected AR, transfers source bit 0 to DP, and
then applies the ordinary indirect AR/ARP post-update.
LT reads through the same address path, transfers all 16 source bits to T, and
then applies the ordinary indirect AR/ARP post-update.
LTA uses that same read/update path while simultaneously adding the previous
32-bit P value to ACC with sticky signed overflow and OVM-controlled wrap or
endpoint saturation; P is unchanged.
LTD performs the same T load and previous-P accumulation while copying the
unchanged source word to the next higher internal-RAM location. Its source
address is resolved before the common indirect AR/ARP post-update. Tests expose
both logical addresses and require the read and write in the same one-cycle
retirement. Source `0x8f` would select an unimplemented destination `0x90`;
the current trap-before-effects policy is provisional under `OQ-014`, not a
claim about physical decode behavior. A related TI patent supplies only an
ordinary adjacent-column mechanism and internally inconsistent capacity
statements; stable DMOV/LTD physical-probe images now define the original-NMOS
clear/scan/register experiment needed to resolve the edge (`SC-038`).
DMOV is the copy-only subset of that transfer: it reads the selected source
through the same old-address/common-post-update path and writes the unchanged
word to `source+1`, but does not load T or change ACC, P, OV, OVM, or DP.
The same provisional `0x8f`-to-`0x90` endpoint policy applies under OQ-014.
MPY signed-multiplies T by the selected 16-bit data word into P through that
same address/update path. Its documented `0x8000`-by-`0x8000` result is
`0xc0000000`, and directed tests preserve that physical multiplier exception.
A one-step symbolic proof additionally checks all 2^32 operand pairs against
an explicitly sign-extended mathematical product, proving that this pair is
the only departure, and checks commutativity plus zero/unity identities
[`formal/tms32010_multiplier.sby`]. This is exhaustive combinational RTL
evidence, not physical multiplier or technology-mapped timing evidence.
MPYK instead sign-extends its signed 13-bit program-word constant, multiplies
it by T into P, and performs no data-memory access.
PAC copies all 32 P bits into ACC without changing P or arithmetic status and
also performs no data-memory access.
APAC adds all 32 P bits to ACC, leaves P unchanged, applies sticky signed
overflow and OVM-controlled wrap or endpoint saturation, and performs no
data-memory access.
SPAC subtracts all 32 P bits from ACC with the same P preservation,
sticky-overflow, OVM result, and program-only transaction rules.
The portable RTL shares one signed 32-bit add/subtract primitive across these
P-accumulation operations, `ADD`, `SUB`, and `SUBH`; ADDS, ADDH, SUBS, and
SUBC remain separate because their documented operand/status rules differ. A
one-step symbolic proof leaves both 32-bit operands, operation direction, and
OVM arbitrary and compares wrap, overflow, and saturation against an
independently sign-extended 33-bit result
[`formal/tms32010_accumulator.sby`]. This is exhaustive combinational RTL
evidence, not instruction sequencing, source selection, sticky-OV, or
physical timing evidence.
TI's separate rule deferring interrupt service through the instruction after
MPY or MPYK is now tested in the model and RTL, including the case where the
multiply itself occupies the already-pipelined protected slot.
IN and OUT each execute as an opcode read followed by a distinct I/O cycle.
TBLR and TBLW execute as an opcode read, a discarded PC+1 read, and an
ACC-addressed program-space transfer before repeating PC+1. The explicit
pipeline retains table ownership through that repeated fetch and commits its
internal-RAM, indirect-update, stack-bottom, and retirement effects only
there; a self-modifying TBLW case verifies that the discarded old word never
executes.
This is partial RTL support only.
The sequential native-phase wrapper covers qualified normal program reads,
two-cycle control flow, I/O cycles, and table-transfer reads/writes.
Current evidence does not constitute instruction completeness or cycle
accuracy.
