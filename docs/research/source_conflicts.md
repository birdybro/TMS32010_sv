# Source conflicts and transcription hazards

## SC-001 — Overflow-mode prose

- **Sources:** TI SPRU001B §2.1.2, printed pp. 2-3–2-5.
- **Conflict:** one sentence in the scan/OCR says the accumulator is
  unmodified on overflow when `OVM=0`, while the following explanation says
  the overflowed result is loaded; normal two's-complement wrap is also
  implied by instruction examples.
- **Resolution:** the detailed paragraph immediately following the disputed
  sentence says the overflowed result is loaded without modification. TI
  SPRU013 §3.5.2, printed p. 3-20, and its `ROVM` page, printed p. 4-58,
  repeat that behavior unambiguously: `OVM=0` retains the wrapped result and
  sets `OV`; `OVM=1` saturates while also setting `OV`.
- **Current treatment:** resolved for arithmetic implementation. Retain this
  record because the original revision-B sentence remains erroneous.
- **Confidence:** CORROBORATED for the resolution across TI revisions;
  VERIFIED_PRIMARY for the saturation endpoints and sticky `OV`.

## SC-002 — Hard Drivin' device identity

- **Primary hardware evidence:** Atari drawing A044427 sheet 4 labels the
  physical device `TMS32010` and shows a 20 MHz crystal.
- **Secondary software evidence:** current MAME configures its `TMS320C10`
  device type at 20 MHz, although surrounding comments call the slave a
  TMS32010.
- **Current treatment:** implement the original TMS32010. MAME's C10 model is
  a functional oracle only; disagreements are not automatically resolved in
  its favor.
- **Confidence:** VERIFIED_PRIMARY for the board label, CORROBORATED for
  object-code compatibility, UNKNOWN for undocumented NMOS/CMOS differences.

## SC-003 — Scan OCR mnemonic corruption

SPRU001B OCR renders `LAR`/`MPY`/`DMOV` as `LAA`/`MPV`/`OMOV` in parts of
Table 3-2. Individual instruction headings, examples, and other TI documents
use the former spellings. Database transcription must use page images rather
than raw OCR. **Treatment: resolved as OCR artifacts; VERIFIED_PRIMARY.**

## SC-004 — Presumed wait states versus actual pinout

The requested qualification includes READY/wait-state behavior, but the
original TMS32010 40-pin interface has no READY/WAIT pin in SPRU001B. A
wrapper-level phase pause is useful but cannot be labeled a native protocol.
The original TMS32010-20 external-clock table resolves the physical boundary:
48.78–150 ns master-clock periods, 47.5–52.5% pulse duration, and four input
periods per `CLKOUT` machine cycle. Thus bounded slowing is specified, while
an arbitrary or indefinite phase stop is not
[ti-tms32010-users-guide-spru001b, §2.12 and Appendix A data sheet, Clock
Characteristics and Timing, printed pp. 2-20 and data-sheet pp. 10–11 (PDF
pp. 44 and 366–367)]. **Treatment: resolved under
`OQ-001`; keep FPGA phase pause explicitly platform-only. Confidence:
VERIFIED_PRIMARY for the clock envelope.**

## SC-005 — Data-page-one upper bound

SPRU001B §2.3.1.2 prints page 1 as locations 128–144, which would contain 17
words. The same guide repeatedly specifies 144 total words and a 16-word
second page, establishing implemented locations 128–143. **Treatment:** model
only 0–143; keep address 144 and all higher eight-bit addresses unresolved
under `OQ-002` rather than interpreting the inconsistent endpoint as storage.
**Confidence:** VERIFIED_PRIMARY for the 144-word capacity; UNKNOWN for the
electrical result of an out-of-range access.

## SC-006 — ADDH overflow wording

- **Original-part sources:** TI SPRU001B `ADDH`, printed p. 3-11, gives the
  high-half addition and says it is useful for 32-bit arithmetic, but does not
  state whether `OV` or `OVM` applies. TI SPRU013 `ADDH`, printed p. 4-16,
  repeats that omission.
- **Variant source:** TI SPRU032A for the TMS320C14/E14 explicitly says
  `ADDH` affects `OV` and is affected by `OVM`, while still saying the low
  accumulator half is unaffected.
- **Secondary source:** the pinned MAME implementation applies high-half
  overflow and saturation but comments that this is an inference because the
  manual omitted it.
- **Current treatment:** superseded by the expanded evidence and resolution in
  `SC-017`/`OQ-011`. The implemented original-part behavior is modulo
  high-half addition with low-half/OV preservation and no OVM effect.
- **Confidence:** CORROBORATED for original-part OV/OVM behavior;
  VERIFIED_PRIMARY for ordinary transfer and low-half preservation.

## SC-007 — ABS overflow-flag omission

- **Original-part sources:** TI SPRU001B `ABS`, printed p. 3-9 (PDF p. 59),
  and SPRU013 `ABS`, printed p. 4-14 (PDF p. 95), both define opcode
  `0x7f88`, the ordinary absolute-value result, the OVM-dependent
  `ABS(0x80000000)` result, and one-cycle timing. Neither page states whether
  that boundary case sets sticky `OV`.
- **Instruction-format rule:** SPRU013 §4.3, printed pp. 4-11 through 4-13
  (PDF pp. 92-94), says affected status bits are listed in each instruction's
  `Execution` block. The ABS page lists no affected status bit. Other
  arithmetic pages in the same guide explicitly list `Affects OV` when it
  applies.
- **Variant source:** TI SPRU032A for the TMS320C14/E14, `ABS`, printed
  p. 4-14 (PDF p. 121), explicitly states that ABS affects `OV` and is
  affected by `OVM`. This is evidence about a later variant, not proof of the
  original NMOS part.
- **Secondary source:** pinned MAME commit
  `030fefcbd14e47c01ec9d67655be90f64a1dc8ab` implements negation and OVM
  saturation in `tms320c1x.cpp:341`, but its handler never writes `OV`.
- **Resolution:** Treat the C14/E14 annotation as a documented variant
  difference. For the original TMS32010, ABS preserves prior `OV`; the
  instruction-format rule supplies primary textual evidence and MAME supplies
  structurally independent corroboration. Directed tests cover both incoming
  OV values at `0x80000000`, with both OVM modes.
- **Current treatment:** `ABS` is supported by the database, hand fixture,
  assembler/disassembler, independent model, RTL, native phase wrapper, and
  seeded differential regression. `OQ-013` retains the evidence boundary.
- **Confidence:** VERIFIED_PRIMARY for encoding, accumulator result, OVM
  result selection, word count, and cycle count; CORROBORATED for
  original-TMS32010 `OV` preservation.

## SC-008 — SST reserved bit 1

- **Uncontested positions:** SPRU001B Figure 2-7 and the original `LST` and
  `SST` instruction pages all draw stored-word bits 12:9 and 7:2 as ones.
  They identify only five architectural status fields. `LST` consumes bits
  15, 14, 8, and 0 while preserving `INTM`, so no other source position is
  writable hidden status. These positions are VERIFIED_PRIMARY and are not
  part of the conflict.
- **Original-part sources:** TI SPRU001B Figure 2-7, printed p. 2-15 (PDF
  p. 39), marks stored status-word bit 1 as “don't care.” Its individual
  `LST` and `SST` pages, printed pp. 3-38 and 3-59 (PDF pp. 88 and 109),
  explicitly draw that position as one.
- **Later family source:** TI SPRU013 §3.6.3, printed pp. 3-24–3-26 (PDF
  pp. 53–55), says reserved status bits read as logic ones through SST, but
  Figure 3-13 draws bit 1 as zero. Its `LST` input drawing at printed p. 4-43
  also shows zero, while the `SST` page at printed p. 4-65 labels bit 1
  reserved and its worked result `0x5efe` sets it. LST ignores that source
  position, so its zero does not define the SST output.
- **Independent oracle:** pinned MAME commit
  `030fefcbd14e47c01ec9d67655be90f64a1dc8ab` forces status mask `0x1efe`,
  including bit 1, and passes that status word into `sst()` before its common
  indirect address helper updates AR/ARP.
- **Resolution:** implement bit 1 as one. The original instruction page, later
  TI architecture prose, both TI worked representations, and the structurally
  independent oracle agree on the deterministic value. Figure 2-7 still
  establishes that software must treat the bit as don't-care/reserved, and no
  physical-mask claim is made. Directed tests assert the stored one for every
  combination of the five defined status fields.
- **Current treatment:** `SST` is qualified in the database, hand fixture,
  assembler/disassembler, independent model, RTL, native phase stream, and
  seeded differential. `OQ-003` retains the evidence boundary.
- **Confidence:** VERIFIED_PRIMARY for the five defined fields, bits 12:9 and
  7:2 being stored as ones, LST ignoring all other source positions, address
  modes, opcode, one-cycle timing, and the fact that bit 1 is reserved;
  CORROBORATED for deterministic stored bit 1 and pre-update-status ordering.

## SC-009 — LST next-ARP precedence

- **Original-part status contract:** SPRU001B and SPRU002B `LST`, printed
  p. 3-38, and SPRU013 `LST`, printed p. 4-43, expose an optional indirect
  next-ARP operand while stating that the addressed word loads status,
  including `ARP` from data bit 8.
- **Original-part worked result:** all three pages use `LARP 0; LST *,1` and
  say the AR0-addressed word replaces status while `ARP` becomes one. No data
  word is given. Read as a demonstration of the explicit operand, the example
  supports encoded-field precedence; read as an omitted assumption that word
  bit 8 is also one, it is compatible with memory-word precedence. The
  ordinary indirect-addressing section says bit 0 loads ARP after the current
  instruction and states no LST exception. Thus the primary text is
  internally ambiguous rather than simply silent.
- **Variant clarification:** TI SPRU012 `LST`, printed p. 4-75, explicitly
  says the next-ARP field is ignored and the memory word supplies `ARP`.
- **Related TI embodiment:** US4577282A says its generic indirect-control bit
  loads encoded ARP after the current instruction and separately says LST
  restores status, but supplies no same-instruction priority. It preserves the
  competing hypotheses and cannot override production documentation.
- **Independent memory-wins oracle:** pinned MAME commit
  `030fefcbd14e47c01ec9d67655be90f64a1dc8ab` suppresses the ordinary
  next-ARP update in its `lst()` handler before loading the status word.
- **Independent encoded-wins implementation:** pinned IKA32010 commit
  `51bc1f05a2a08a61c8815a9643d08a42e99779c6` uses the instruction field for
  indirect LST and data bit 8 only for direct LST, matching the literal worked
  example while opposing MAME and the later C25 guide.
- **Current treatment:** the model and RTL will ignore LST's encoded next-ARP
  field and load `ARP` from source bit 8. This is a targeted, tested
  provisional original-part behavior under `OQ-015`, not a claim that later
  C25 behavior proves the NMOS TMS32010. The exact two-direction capture in
  `docs/research/lst_arp_precedence_experiment.md` is required before changing
  or upgrading that policy. Its strict classifier preserves memory-word,
  encoded-field, both mixed-direction, and arbitrary other sequences and
  validates exact source/listing/image, decoded-trace, raw/photo, and named
  single-specimen provenance. `acceptance_complete` remains false; synthetic
  classifier fixtures and complete bookkeeping do not resolve the conflict or
  prove cross-specimen invariance.
- **Confidence:** VERIFIED_PRIMARY that both write sources are documented and
  the worked result says ARP becomes one; PROVISIONAL for original-silicon
  precedence. Later TI plus MAME corroborate memory-wins, while the original
  literal example plus IKA corroborate encoded-wins.

## SC-010 — SUBC overflow stage and dependent-instruction hazard

- **Original-part sources:** SPRU001B and SPRU002B `SUBC`, printed p. 3-61,
  define a 32-bit conditional subtract followed by a one-bit left shift and
  warn that the next instruction cannot use ACC. They do not state which
  arithmetic stage drives `OV` or the result of violating the scheduling
  rule. SPRU001B §2.2.2.1 says accumulator arithmetic overflow sets sticky
  `OV`.
- **Later family source:** SPRU013 `SUBC`, printed p. 4-67, explicitly says
  the instruction affects `OV`, ignores `OVM`, and never saturates, but still
  does not identify the flag-producing stage.
- **Related TI embodiment:** US4577282A stages the unshifted ALU result through
  Q4/Q1/Q2 and performs the quotient shift in an accumulator-local path at Q3
  of a following non-ALU/NOP state. Its status input comes from the earlier
  ALU/carry path. This explains the dependency prohibition and supports an
  intermediate-overflow hypothesis, but the patent calls SUBC two-state while
  the production guides call it one cycle. It is **CORROBORATED
  RELATED-EMBODIMENT**, not original-part proof
  [ti-dsp-microcomputer-patent-us4577282a, patent cols. 13-14 and 21-24 (PDF
  pp. 33 and 37-38), Figure 5c].
- **Independent oracle:** pinned MAME commit
  `030fefcbd14e47c01ec9d67655be90f64a1dc8ab` computes the documented
  conditional result immediately. Its handler appears intended to detect
  signed overflow of the intermediate subtraction, but the present Boolean
  expression compares the old accumulator with an unchanged accumulator and
  therefore cannot set `OV`
  [mame-tms320c1x-core-030fefc, `subc()`, lines 732–742].
- **Conflicting FPGA implementation:** pinned IKA32010 retains a `prev_subc`
  stage, loads final ACC on the next FPGA cycle, and derives V from that later
  shifted/add result. It corroborates delayed availability but supports the
  opposite overflow-stage hypothesis; it cannot settle original silicon.
- **Current treatment:** the model and RTL provisionally set sticky `OV` on
  signed overflow of the intermediate subtract, ignore `OVM`, and never
  saturate. Directed tests distinguish intermediate-only and final-shift-only
  overflow vectors and label that boundary provisional.
  Tests place an ACC-free instruction after every SUBC; behavior of a
  violating dependent sequence is not claimed. Stable assembler fixtures now
  provide an original-device dependency probe and a two-vector physical probe
  that isolates the overflow stages; neither has a captured result. Their
  strict classifiers bind exact source/listing/image, decoded trace, test
  context, and a complete `OQ-008` record to one named specimen while leaving
  `acceptance_complete=false`. Stable unanticipated dependency words and all
  four overflow pairs remain retainable; provenance completeness chooses no
  result and proves no cross-specimen invariance. See
  `docs/research/subc_pipeline_experiment.md`, `OQ-017`, and `OQ-018`.
- **Confidence:** VERIFIED_PRIMARY for encoding, conditional ACC transform,
  scheduling prohibition, word count, and cycle count; PROVISIONAL for the
  overflow-producing stage; UNKNOWN for a prohibited dependent sequence.

## SC-011 — BANZ zero-counter example

- **Original-part source:** SPRU001B §2.4.1 says auxiliary-register automatic
  modification affects only bits 8:0 as a circular counter. Its `BANZ` page
  likewise says the test and decrement use the low nine bits and illustrates
  `0x0000` becoming `0x01ff`.
- **Later family source:** SPRU013 §3.4.5 independently says bits 15:9 are
  unaffected and decrementing a zero low-nine-bit field produces `0x01ff`.
  However, that guide's `BANZ` example prints full-register zero becoming
  `0xffff`, contradicting its own architecture section.
- **Independent oracle:** pinned MAME commit
  `030fefcbd14e47c01ec9d67655be90f64a1dc8ab` preserves `AR[15:9]` and
  decrements only `AR[8:0]`
  [mame-tms320c1x-core-030fefc, `banz()`, lines 407–417].
- **Current treatment:** follow the original TMS32010 guide and the consistent
  architecture descriptions: BANZ decrements modulo 512 and preserves the
  upper seven bits. Treat the later `0xffff` example as a documentation error,
  not as evidence of a variant-wide decrement.
- **Confidence:** VERIFIED_PRIMARY for original-TMS32010 nine-bit behavior;
  CORROBORATED by the later architecture section and independent emulator.

## SC-012 — MAME BANZ untaken cycle abstraction

- **Primary sources:** SPRU001B Table 3-2 and the individual `BANZ` page list
  two words and two cycles without a taken/untaken exception. The following
  word contains the 12-bit target, and the PC either loads it or advances past
  it.
- **Independent oracle:** pinned MAME gives BANZ a one-cycle base cost, reads
  the following target and charges one additional cycle only on the taken
  path, and merely increments PC on the untaken path
  [mame-tms320c1x-core-030fefc, `banz()`, lines 407–417; opcode table and
  `add_branch_cycle()`, lines 841–857].
- **Current treatment:** the project follows TI's unconditional two-cycle
  total and performs the second program read on both paths. MAME remains a
  functional oracle for the condition and modulo-512 decrement, but its BANZ
  timing is not a cycle or pin oracle.
- **Confidence:** VERIFIED_PRIMARY for the project timing; documented
  secondary-source disagreement.

## SC-013 — MAME accumulator-branch untaken cycle abstraction

- **Primary sources:** SPRU001B Table 3-2 and the individual `BGEZ`, `BGZ`,
  `BLEZ`, `BLZ`, `BNZ`, and `BZ` pages define every instruction as two words
  and two cycles without a taken/untaken exception. Each operation either
  loads the following word's target or advances PC past both words.
- **Independent oracle:** pinned MAME gives each family member a one-cycle
  base cost, reads the target and charges an additional branch cycle only when
  the predicate is true, and merely increments PC when false
  [mame-tms320c1x-core-030fefc, predicate handlers, lines 420–500; opcode
  table and `add_branch_cycle()`, lines 841–857].
- **Current treatment:** follow TI's unconditional two-word/two-cycle total
  and perform the second normal program read on both paths. MAME corroborates
  the signed/zero predicates but is not used as a timing oracle for untaken
  paths. The explicit pipeline therefore retains branch ownership through a
  nonexecutable operand fetch and the condition-selected instruction fetch on
  both outcomes; this combined interval mapping remains labeled INFERRED.
- **Confidence:** VERIFIED_PRIMARY for project timing and predicates;
  documented secondary-source timing disagreement.

## SC-014 — MAME BV untaken cycle abstraction

- **Primary sources:** SPRU001B Table 3-2 and the `BV` instruction page define
  `BV` as two words and two cycles without a taken/untaken exception. The
  operation advances PC past both words when OV is clear; when OV is set it
  loads the following target and clears OV.
- **Independent oracle:** pinned MAME tests and clears OV consistently with
  TI, but reads the target and charges its additional branch cycle only when
  OV is set [mame-tms320c1x-core-030fefc, `bv()`, lines 480–489; opcode table
  and `add_branch_cycle()`, lines 841 and 855–857].
- **Current treatment:** follow TI's unconditional two-word/two-cycle total
  and perform the second normal program read on both paths. MAME corroborates
  the predicate and taken-path clear but is not used as an untaken timing
  oracle. The explicit pipeline holds BV ownership through the nonexecutable
  operand and condition-selected instruction fetch in both outcomes. It
  samples old OV for selection and clears OV only when a taken BV retires;
  this combined interval mapping remains labeled INFERRED.
- **Confidence:** VERIFIED_PRIMARY for project behavior and timing;
  documented secondary-source timing disagreement.

## SC-015 — MAME BIOZ untaken cycle abstraction

- **Primary sources:** SPRU001B Table 3-2 and the `BIOZ` page define two words
  and two cycles without a pin-level exception. Section 2.9 says BIO is
  sampled every cycle and is not latched; Appendix A places setup before
  falling `CLKOUT`.
- **Independent oracle:** pinned MAME invokes a BIO callback and branches when
  that abstract line is asserted, but reads the target and charges the
  additional branch cycle only on the taken path
  [mame-tms320c1x-core-030fefc, `bioz()`, lines 440–448; opcode table and
  `add_branch_cycle()`, lines 841 and 855–857].
- **Current treatment:** expose the physical active-low level, sample it at
  the second falling-edge target-word boundary, and perform that normal read
  in both outcomes. MAME corroborates the functional branch condition only;
  its callback assertion convention is not physical pin polarity evidence.
  The explicit pipeline maps that target-word/operand boundary to execution
  cycle 1, uses the sampled level to select cycle 2's instruction fetch, and
  retains only the decision through later pin changes or stalls. This
  combined interval mapping remains labeled INFERRED.
- **Confidence:** VERIFIED_PRIMARY for project behavior and timing;
  documented secondary-source timing disagreement.

## SC-016 — SUBH low-half wording and full-accumulator saturation

- **Original instruction page:** SPRU001B `SUBH`, printed p. 3-62 (PDF
  p. 112), defines `ACC - (dma × 2^16)` and its ordinary worked result but
  does not state status behavior. SPRU013 `SUBH`, printed p. 4-69 (PDF
  p. 150), explicitly says the low 16 accumulator bits are unaffected while
  also saying the instruction affects `OV` and is affected by `OVM`.
- **General primary rule:** SPRU013 §3.5.2, printed pp. 3-19–3-20 (PDF
  pp. 48–49), defines OVM-enabled overflow as loading the complete accumulator
  with `0x7fffffff` or `0x80000000`.
- **Resolution:** low-half preservation applies to the ordinary arithmetic
  result and to an OVM-clear wrapped result because the aligned subtrahend has
  zero low bits. OVM-enabled overflow is the explicitly documented exception:
  it replaces all 32 accumulator bits with the signed endpoint.
- **Independent oracle:** pinned MAME aligns the data word by 16 and applies
  its common full-accumulator signed-subtraction overflow and saturation path
  [mame-tms320c1x-core-030fefc, `CALCULATE_SUB_OVERFLOW()` and `subh()`,
  lines 212–220 and 745–750].
- **Current treatment:** model and RTL assert low-half preservation on
  ordinary/wrapped results and complete endpoint replacement under OVM.
- **Confidence:** VERIFIED_PRIMARY for the resolved rule; CORROBORATED by the
  independent emulator.

## SC-017 — Original ADDH status omission versus later overflow behavior

- **Original-family sources:** SPRU001B `ADDH`, printed p. 3-11 (PDF p. 61),
  defines `ACC + (dma × 2^16)` in one word and one cycle but lists no status
  effect. SPRU013 `ADDH`, printed p. 4-16 (PDF p. 97), repeats that execution
  expression, explicitly says `ACC[15:0]` is unaffected, and likewise lists
  neither `OV` nor `OVM`.
- **Instruction-format rule:** SPRU013 §4.3, printed pp. 4-11–4-13 (PDF
  pp. 92–94), says an instruction's Execution block gives conditional status-
  mode effects and lists affected status bits. The ADDH omission is therefore
  evidence, not merely absent prose.
- **Variant source:** SPRU032A `ADDH`, printed p. 4-16 (PDF p. 123), adds the
  explicit sentence “Affects OV; affected by OVM.” The C14/E14 is not the
  original NMOS TMS32010, so this is recorded as a variant difference rather
  than silently backported.
- **Independent implementations:** pinned MAME explicitly comments that the
  manual does not mention overflow for ADDH, then implements sticky OV and
  high-half-only saturation because newer generations support it
  [mame-tms320c1x-core-030fefc, lines 349–379]. IKA32010 commit
  `51bc1f05a2a08a61c8815a9643d08a42e99779c6` instead sends the shifted word
  through its common 32-bit saturating ALU, which can replace the low half.
  Their disagreement confirms that neither is independent hardware proof.
- **Resolution:** on the original TMS32010, add the 16-bit data pattern to
  `ACC[31:16]` modulo 2^16, preserve `ACC[15:0]` for every input, preserve the
  incoming sticky `OV`, and ignore `OVM`. This follows the original-family
  per-instruction contract and treats the explicit C14/E14 status sentence as
  an added variant behavior. Directed tests retain both competing overflow
  directions under both OVM values and both incoming OV values.
- **Current treatment:** ADDH may enter the database, tools, model, and RTL at
  CORROBORATED confidence. Documentation must continue to say the signed-
  boundary behavior has not been measured on original silicon.
- **Confidence:** VERIFIED_PRIMARY for encoding, ordinary arithmetic,
  low-half preservation, word count, and cycle count; CORROBORATED for
  original-part OV preservation and OVM independence.

## SC-018 — PUSH/POP every-cycle MEN versus secondary idle interval

- **Original-part pin contract:** SPRU001B Table 2-4, printed p. 2-21 (PDF
  p. 45), says active-low `MEN` occurs on every machine cycle except when
  `WE` or `DEN` is active. The individual PUSH/POP definitions contain no
  I/O transfer, and each is one word/two cycles
  [ti-tms32010-users-guide-spru001b, `POP`/`PUSH`, printed pp. 3-49–3-50
  (PDF pp. 99–100)].
- **Later primary architecture description:** SPRU013 says program memory is
  always addressed by PC and that PC contains the address of the next
  instruction to execute. Its PUSH/POP Execution blocks each state
  `(PC)+1 -> PC`, but neither supplies a per-cycle waveform
  [ti-first-generation-users-guide-1987, §3.6.1, Figure 3-12, and
  `POP`/`PUSH`, printed pp. 3-22–3-23 and 4-55–4-56 (PDF pp. 51–52 and
  136–137)].
- **Original-device EVM evidence:** TI's EVM monitor rejects an address
  breakpoint at the word immediately after PUSH or POP. Its hardware uses the
  TMS32010 program-address bus to index a 4K-by-1 breakpoint RAM, substitutes
  NOP data on a match, and captures the processor address. This corroborates
  external visibility of `N+1` during the multicycle context, but the manual
  gives neither `MEN` qualification nor the following address
  [ti-tms32010-evm-users-guide-spru005a, SB note 7, printed p. 3-58 (PDF
  p. 99), and §9.3, printed pp. 9-2 through 9-3 (PDF pp. 179-180)].
- **Independent FPGA implementation:** pinned IKA32010 commit
  `51bc1f05a2a08a61c8815a9643d08a42e99779c6` requests `BUSCTRL_STOP` and
  holds PC during PUSH/POP microcycle zero, then requests `OPCODE_READ` from
  PC during microcycle one [ika32010-rtl-51bc1f0, lines 690–731].
- **Contemporary TI background:** US4577282A independently describes an
  every-state active-low external program read clock except when `DEN-` or
  `WE-` is active,
  but its disclosed Table A contains only subroutine-stack CALLA/RET controls
  and omits the production accumulator PUSH/POP instructions. It therefore
  reinforces the general strobe constraint without supplying either missing
  address [ti-dsp-microcomputer-patent-us4577282a, patent cols. 5-6 and
  34-36 (PDF pp. 29 and 43-44)].
- **Contemporary TI simulator boundary:** the 1982 simulator guide
  distinguishes instruction acquisition from program-ROM read breakpoints
  and separately counts clock cycles, but its 256-state trace displays only
  PC, ACC, AR0, and AR1. It contains no PUSH/POP trace or external signal
  phase, so it cannot resolve this conflict
  [ti-tms32010-simulator-users-guide-1982, §§2.6.7–2.6.8, §§2.13–2.14, and
  §2.20, printed pp. 19, 39–40, and 43 (PDF pp. 21, 41–42, and 45)].
- **Conflict:** the secondary implementation supplies a useful PC-hold
  hypothesis but suppresses the first program transaction that the primary
  every-cycle `MEN` wording requires. Replacing that idle with an active
  discarded read is plausible, but would still invent the address/validity
  relationship without a waveform.
- **Current treatment:** do not copy either external sequence into the RTL.
  Preserve H1 inactive, H2 repeated/discarded `N+1`, and H3 advancing
  prefetch as separately measurable hypotheses. The EVM clue is consistent
  with all three because each exposes `N+1` at some point. The synthetic
  fixture and original-device capture criteria are in
  `docs/research/push_pop_bus_experiment.md`; see `OQ-016`. The strict
  `tools.trace.push_pop_capture` classifier now makes those observations
  reproducible, preserves conflicting/unknown sequences, rejects any image
  other than the exact 16-byte fixture, and binds the decoded trace to an
  `OQ-008` single-specimen provenance record. Synthetic classifier tests are
  not evidence for any native sequence, and `acceptance_complete` stays false.
- **MAME functional check:** the ROM-free `make mame-synthetic` workflow runs
  a separate combined stack/computed-control fixture in MAME's Hard Drivin'
  TMS320C10 device. Ten model steps match eleven debugger boundary states,
  including both PUSH/POP transforms and a complete CALA/RET path. MAME's
  trace contains no `/MEN`, program-address subcycle, or pin-phase data, so it
  corroborates neither IKA's idle interval nor either active-read hypothesis.
- **Confidence:** VERIFIED_PRIMARY for two cycles, general `MEN` behavior,
  and the architectural state transform; UNKNOWN for the exact address and
  fetched-word ownership of each cycle.

## SC-019 — Hard Drivin' DAC direct wiring versus MAME MSB complement

- **Primary board evidence:** Atari A044427 Rev A sheet 7 clocks `TD15:TD4`
  into LS374 latches on `/DACL` and directly connects their true outputs to
  Am6012 `B1:B12`. `TD15` reaches `B1` without an inverter, and `TD3:TD0`
  have no DAC connection [atari-driver-sound-board-schematic, sheet 7 of 10,
  PDF p. 13].
- **Primary component evidence:** AMD identifies `B1` as MSB and `B12` as LSB;
  its straight-binary table gives zero `IOUT` at all-zero code and increasing
  `IOUT` as code increases. The two's-complement rows explicitly require an
  inverter at `B1` [amd-analog-communications-databook-1983, Am6012 data
  sheet, printed pp. 3-17 and 3-22 (PDF pp. 95 and 100), and application
  note, printed p. 3-27 (PDF p. 104)].
- **Analog boundary:** the board grounds the complementary current output and
  uses a positive reference from +5 V through 1 kOhm plus 4.7 kOhm. `IOUT`
  enters an inverting TL084 transimpedance stage with 2.2 kOhm feedback, and
  its `DACOUT` is AC-coupled through 1 uF `C26` into `DF IN`. This is a
  monotonic, unipolar current path followed by whole-signal analog inversion
  and DC removal; it does not complement only digital bit 11
  [atari-driver-sound-board-schematic, sheet 7 of 10, PDF pp. 13-14;
  amd-analog-communications-databook-1983, positive-reference connection,
  printed p. 3-29 (PDF p. 106)].
- **Secondary disagreement:** pinned MAME's `hdsnddsp_dac_w` extracts bits
  15:4 and XORs `0x800`, commenting that the schematic inverts the MSB. Its
  AM6012 device is an unsigned-mapped 12-bit DAC with a default bipolar
  normalized output range, so this operation interprets the raw high twelve
  bits as two's-complement audio rather than reproducing the shown digital
  nets [mame-harddriv-audio-030fefc; mame-dac-header-030fefc;
  mame-dac-core-030fefc].
- **Secondary lineage:** the XOR is not derived by the 2016 comment. The first
  located MAME Hard Drivin' sound support in MAME 0.62 (2002) already passes
  `data XOR 0x8000` to a generic signed-16-bit DAC function that subtracts
  `0x8000`, thereby interpreting the original DSP word as signed. It contains
  no schematic-inversion comment. Commit
  `36944269bd6fe1fb47822a2112c524b13c4b27f2` migrates that older behavior to
  a twelve-bit AM6012 abstraction, adds the schematic claim, and at that time
  supplies symmetric positive/negative emulator references unlike Rev-A. No
  alternate drawing, ECO, or capture is cited
  [historic-mame-harddriv-audio-062, lines 330-335;
  historic-mame-dac-core-062, lines 59-68;
  historic-mame-whatsnew-062, improved-sound list;
  mame-harddriv-audio-36944269].
- **Competing hypotheses:** the Rev-A drawing is accurate and original
  firmware emits the required straight/offset-binary code; a shipped board
  carried an unrecorded ECO or different latch path; or MAME's conversion is
  an emulator-side approximation/error. The present sources do not
  distinguish them.
- **Current treatment:** preserve the primary-backed raw code `data[15:4]` and
  keep MAME's XOR only as a separately named oracle expectation. Do not put
  the XOR into the generic CPU or call it physical behavior. The ideal
  transfer, exact MAME history, negative ECO search, and decisive
  walking-ones/ramp/game-trace captures are in
  `docs/research/hard_drivin_dac_code_audit.md`; see `OQ-020`.
- **Confidence:** VERIFIED_PRIMARY for the Rev-A raw digital mapping and
  positive-reference/first-stage/AC-coupling topology; CORROBORATED for the
  continuity of MAME's signed software interpretation; UNKNOWN for the
  intended game PCM mapping and production-board equivalence beyond that
  drawing.

## SC-020 — Physical reset-qualified RAM ownership versus MAME shared RAM

- **Primary board evidence:** A044427 LS259 bit 4 is `/320RES`. Its inversion
  enables the TMS-side address/control LS244s only after reset release;
  independent active-low `/320RAM` enables the host address/control buffers
  and host-data LS245s. No gate prevents both sets from driving together
  [atari-driver-sound-board-schematic, sheets 3–4 of 10, PDF pp. 5–8].
- **Required hardware protocol:** legal host program-RAM access holds
  `/320RES=0` and `/320RAM=0`; legal DSP execution uses `/320RES=1` and
  `/320RAM=1`. `/320RES=1` with `/320RAM=0` is electrical contention, not a
  defined priority case.
- **Secondary abstraction:** pinned MAME exposes the 4K-word shared array to
  host handlers at all times and maps latch bit 4 to an inverted HALT line.
  It neither gates host access on reset nor models the address/control buffer
  overlap [mame-harddriv-audio-030fefc, host RAM handlers, address maps, and
  device configuration].
- **Current treatment:** the board decoder reports simultaneous ownership.
  A future storage wrapper must require reset during host access or document a
  protective FPGA arbitration policy as an implementation divergence. See
  `OQ-021` for the unverified firmware sequence.
- **Confidence:** VERIFIED_PRIMARY for Rev-A wiring and the invalid overlap;
  UNKNOWN for firmware compliance and exact handoff timing.

## SC-021 — Low-address TBLW board alias versus split MAME address spaces

- **Primary board evidence:** A044427 generates `PORT` when `TA11:TA3=0` and
  implements `/RAMEN = /MEN AND (/TWE OR PORT)`. Its LS138 write decoder is
  enabled by `PORT` and `/PWE`. Because TMS32010 MEN, DEN, and WE are mutually
  exclusive, WE at address `0x000`–`0x007` selects the corresponding output
  port and suppresses program RAM, regardless of whether the executing
  instruction was OUT or TBLW [atari-driver-sound-board-schematic, sheet 5
  of 10, PDF p. 9; ti-tms32010-users-guide-spru001b, Table 2-4 and §2.8.2].
- **Secondary abstraction:** pinned MAME assigns TBLW through the CPU program
  space and OUT through a separate I/O space. Its board maps therefore retain
  a low-address TBLW as a program-RAM write rather than applying the external
  decode [mame-harddriv-audio-030fefc, `driversnd_dsp_program_map` and
  `driversnd_dsp_io_map`].
- **Current treatment:** the reusable CPU continues to expose both logical
  qualifiers, but `hard_drivin_sound_bus_decode` follows native
  address/MEN/DEN/WE and diverts low-address WE to I/O. An exhaustive 4,096-
  address test protects this board-specific rule.
- **Confidence:** VERIFIED_PRIMARY for A044427 Rev A; documented
  secondary-source mismatch.

## SC-022 — Unqualified program RAM versus byte-combined MAME writes

- **Primary board evidence:** A044427 connects host `A12:A1` to RAM
  `RA11:RA0`, connects all `D15:D0` through two LS245 devices, and supplies a
  single `/RAMWR` to all four 4-bit SRAM slices. The drawing's `/UDS` and
  `/LDS` logic serves other memory, not the DSP program-RAM controls
  [atari-driver-sound-board-schematic, sheets 3–4 of 10, PDF pp. 5–8].
- **Primary CPU evidence:** original-MC68000 Table 3-1 says a byte write drives
  the selected byte on both `D15:D8` and `D7:D0`. All four unqualified SRAM
  slices therefore capture `{byte, byte}`; a word write preserves its two
  independent bytes. The manual limits this inactive-lane behavior to the
  current implementation rather than all future devices
  [motorola-m68000-users-manual-ninth, Table 3-1 and footnote, printed pp.
  3-5 through 3-6].
- **Secondary abstraction:** pinned MAME's host handler accepts `mem_mask` and
  uses `COMBINE_DATA`, retaining whichever byte lane was not selected
  [mame-harddriv-audio-030fefc, `hdsnd68k_320ram_w` and host address map].
- **Conflict:** MAME retains the unselected byte, while the physical original-
  MC68000 bus and common `/RAMWR` require every slice to receive the selected
  byte.
- **Current treatment:** the timing-derived lower-Y5 path uses
  `hard_drivin_mc68000_write_word` before the complete-word storage callback.
  The external callback remains an already captured word contract. `OQ-022`
  tracks firmware access widths and electrical/substitute-CPU qualification.
- **Confidence:** VERIFIED_PRIMARY for Rev-A word and original-MC68000 byte
  capture; CONFLICT for MAME's merge; UNKNOWN for firmware byte-write use and
  later/substitute-68k inactive lanes.

## SC-023 — CRAMEN ownership versus unconditional MAME DSP reads

- **Primary board evidence:** `CRAMEN=0` enables `SA8:SA0`, forces the two
  HM6116 devices into read mode, and permits the CRD-to-TDI buffer only during
  decoded input port 1. `CRAMEN=1` instead enables host `A9:A1`, `/RWNB`,
  `/320COM`, and `/RWS`, while disabling that DSP data buffer
  [atari-driver-sound-board-schematic, sheets 3 and 5 of 10, PDF pp. 5-6 and
  9-10].
- **Secondary abstraction:** pinned MAME gates host communication-RAM handlers
  on `m_cramen`, but `hdsnddsp_comram_r` always returns the array word and
  increments its software offset [mame-harddriv-audio-030fefc,
  `cram_enable_w`, host COM handlers, and DSP COM handler].
- **Conflict:** MAME permits simultaneous logical visibility that the physical
  buffer selection does not provide. The value on TDI during an out-of-
  contract DSP read in host mode is not established.
- **Current treatment:** the current FPGA storage grants one side from CRAMEN and
  holds or reports a DSP port-1 read while the host owns the RAM. See
  `OQ-025` for firmware discipline.
- **Confidence:** VERIFIED_PRIMARY for Rev-A ownership; CORROBORATED for the
  secondary abstraction; UNKNOWN for out-of-contract TDI data.

## SC-024 — Global input-read address increment versus selective MAME increment

- **Primary board evidence:** all four sound-address LS191 clock inputs share
  `/PDEN`; their up/down inputs are grounded, and their cascade enables use
  ripple carry. `/PDEN` is the physical input-read strobe, so every completed
  input-port read produces the low-to-high counting edge
  [atari-driver-sound-board-schematic, sheets 4-6 of 10, PDF pp. 7-12;
  ti-sn74ls191-datasheet-sdls072, printed pp. 1-4].
- **Secondary abstraction:** pinned MAME increments `m_sound_rom_offs` in its
  port-0 sound-ROM and port-1 communication-RAM handlers, but not in the port-2
  compare handler [mame-harddriv-audio-030fefc, DSP I/O handlers and map].
- **Current treatment:** board RTL must increment after every accepted physical
  input read, including port 2. MAME remains a functional oracle only where
  its handler models that side effect.
- **Confidence:** VERIFIED_PRIMARY for the Rev-A counter clocking;
  documented secondary-source abstraction.

## SC-025 — Unqualified communication RAM versus byte-combined MAME writes

- **Primary board evidence:** host `D15:D0` reaches two HM6116 devices through
  LS245 transceivers, and one `/CRWE` controls both devices. Host byte enables
  `/HEU` and `/HEL` do not enter this path
  [atari-driver-sound-board-schematic, sheets 3 and 5 of 10, PDF pp. 5-6 and
  9-10].
- **Primary CPU evidence:** original-MC68000 Table 3-1 says a byte write drives
  the selected byte on both `D15:D8` and `D7:D0`. Both unqualified HM6116
  banks therefore capture `{byte, byte}`; a word write preserves its two
  independent bytes. The manual limits this inactive-lane behavior to the
  current implementation rather than all future devices
  [motorola-m68000-users-manual-ninth, Table 3-1 and footnote, printed pp.
  3-5 through 3-6].
- **Secondary abstraction:** pinned MAME accepts `mem_mask` and applies
  `COMBINE_DATA` in `hdsnd68k_320com_w`.
- **Conflict:** MAME retains the unselected byte, while the physical original-
  MC68000 bus and common `/CRWE` require both banks to receive the selected
  byte.
- **Current treatment:** the timing-derived Y6 path uses
  `hard_drivin_mc68000_write_word` before the complete-word storage callback.
  The external callback remains an already captured word contract. `OQ-024`
  tracks firmware access widths and electrical/substitute-CPU qualification.
- **Confidence:** VERIFIED_PRIMARY for Rev-A word and original-MC68000 byte
  capture; CONFLICT for MAME's merge; UNKNOWN for firmware byte-write use and
  later/substitute-68k inactive lanes.

## SC-026 — Sound-ROM sign extension versus unsigned MAME shift

- **Primary board evidence:** A044427 buffers ROM `SD14` to both `TDI15` and
  `TDI14`, maps `SD13:SD7` to `TDI13:TDI7`, and grounds `TDI6:TDI0` during a
  port-0 `/SROM` read. Defining the eight ROM bits as `SD14:SD7`, the returned
  word is `{{2{byte[7]}}, byte[6:0], 7'b0}`
  [atari-driver-sound-board-schematic, sheet 5 of 10, PDF p. 9;
  ti-snx4ls24x-datasheet, printed pp. 11-13].
- **Secondary abstraction:** pinned MAME stores the ROM region as `uint8_t`
  and returns `m_sound_rom[m_sound_rom_offs++] << 7`. The unsigned promotion
  leaves bit 15 clear even when byte bit 7 is one
  [mame-harddriv-header-030fefc, `m_sound_rom`; mame-harddriv-audio-030fefc,
  `hdsnddsp_rom_r`].
- **Conflict:** bytes below `0x80` agree, but byte `0x80` is physical word
  `0xc000` versus MAME word `0x4000`, and byte `0xff` is physical `0xff80`
  versus MAME `0x7f80`.
- **Current treatment:** board adapters must implement the duplicated sign
  bit and keep MAME's unsigned shift only as a named secondary-oracle
  difference. Invalid/unpopulated block behavior remains `OQ-026`.
- **Confidence:** VERIFIED_PRIMARY for Rev-A wiring; documented
  secondary-source mismatch.

## SC-027 — Raw complementary MUTE net versus secondary semantic label

- **Primary board evidence:** port-4 `/MCLK` clocks `TD0` into LS74 100H and
  the complementary `/Q` output, not Q, is named `MUTE`. Active `/320RES`
  clears Q and therefore drives the raw `MUTE` net high. The only drawn analog
  consumer is inside a sheet-7 option explicitly marked `NOT LOADED`
  [atari-driver-sound-board-schematic, sheets 5 and 7 of 10, PDF pp. 9 and 14;
  ti-sn74ls74a-datasheet-sdls119, printed p. 1].
- **Secondary interpretation:** pinned MAME comments `mute DAC audio, D0=1`,
  but the handler only logs its input and neither stores a mute state nor gates
  audio [mame-harddriv-audio-030fefc, `hdsnddsp_mute_w`].
- **Ambiguity:** D0=1 makes the physical net named `MUTE` low on Rev A. The
  production drawing supplies no loaded consumer that establishes whether the
  name is active-low, whether the MAME comment describes another revision, or
  whether the comment is only a software convention.
- **Current treatment:** expose the primary-defined raw complementary net and
  do not apply it to audio. See `OQ-027`.
- **Confidence:** VERIFIED_PRIMARY for the LS74 state and unloaded Rev-A
  consumer; UNKNOWN for effective mute semantics on any populated variant.

## SC-028 — Physical periodic BIO waveform versus MAME query event

- **Primary board evidence:** cascaded LS161 counters synchronously preload
  `0xce`, count through `0xff`, and drive LS74 50S to produce one
  active-low 1 MHz period every 50 periods. Separate LS74 70S samples that
  source using TMS32010 CLKOUT. `/RESET` clears only 50S; the counters and 70S
  have inactive pulled-high controls [atari-driver-sound-board-schematic,
  sheets 1–2 and 4 of 10, PDF pp. 2, 4, and 8;
  ti-sn74ls161a-datasheet-sdls060, printed pp. 1–2 and 7;
  ti-sn74ls74a-datasheet-sdls119, printed p. 1].
- **Secondary abstraction:** pinned MAME derives a 20 kHz event and 250 DSP
  cycles, but on a BIO query it advances the instruction budget to the event
  and returns asserted. It models no low-pulse width, deassertion, reset phase,
  CLKOUT sampling, or independent-clock alignment [mame-harddriv-audio-030fefc,
  `BIO_FREQUENCY`, `CYCLES_PER_BIO`, and `hdsnddsp_get_bio`].
- **Current treatment:** use MAME only to corroborate divide-by-50 cadence.
  Preserve the primary level waveform and resampler as distinct FPGA state;
  retain physical startup/coincident-edge uncertainty under `OQ-028`.
- **Confidence:** VERIFIED_PRIMARY for board logic and nominal waveform;
  documented secondary implementation-convenience difference.

## SC-029 — Unpopulated partial compare path versus MAME zero word

- **Primary board evidence:** `/CMPRD` enables the second half of LS244 `10H`.
  `CMPOUT` at input pin 11 reaches only `TDI15` at output pin 9; the other
  three outputs in that buffer half are unconnected, and no compare target
  drives `TDI14:TDI0`. The optional microphone/LM311 sheet that would source
  `CMPOUT`, including its 1 kΩ output pull-up, is explicitly marked
  `THIS SHEET NOT LOADED.`
  [atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets 3, 5,
  and 8 of 10, PDF pp. 5–6, 9–10, and 15–16;
  ti-snx4ls24x-datasheet, printed pp. 11–13;
  ti-lm311-datasheet-slcs007k, printed pp. 3, 11, and 13].
- **Secondary abstraction:** pinned MAME's `hdsnddsp_compare_r` logs the port-2
  read and returns the full word `0x0000`; it models neither the partial TDI
  wiring nor the unpopulated source [mame-harddriv-audio-030fefc,
  `hdsnddsp_compare_r` and `driversnd_dsp_io_map`].
- **Conflict:** MAME supplies a deterministic word where the production
  drawing establishes no qualified digital result. Its zero cannot prove the
  value of the floating/unqualified `CMPOUT` input or of `TDI14:TDI0`.
- **Current treatment:** retain an explicit external data/ready callback for
  port 2. The ROM-free smoke deliberately supplies zero as a named synthetic
  oracle sentinel, not as physical board behavior. See `OQ-029` and
  `docs/integration/hard_drivin_compare.md`. Port-2 sound-address increment is
  independently primary-verified under `SC-024`.
- **Confidence:** VERIFIED_PRIMARY for the shown path and explicit Rev-A
  nonpopulation; CORROBORATED for MAME's software behavior; UNKNOWN for the
  physical read word.

## SC-030 — Populated `/CPORT` host latch versus MAME zero stub

- **Primary board evidence:** A044427 LS374 `50L` connects `TD7:TD0` to its
  inputs, clocks from `/CPORT`, and drives its true outputs onto host
  `D15:D8` while `/320PORT` is active. No clear input is drawn, and this target
  does not drive host `D7:D0`
  [atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 4 of 10,
  PDF pp. 7–8; ti-sn74ls374-datasheet-sdls165b, printed pp. 1–3].
- **Secondary abstraction:** pinned MAME calls port 3 `COM port TD0-7`, but
  its DSP write handler only logs the value and its 68000 `/320PORT` read
  handler always returns `0x0000`
  [mame-harddriv-audio-030fefc, `hdsnddsp_comport_w` and
  `hdsnd68k_320port_r`].
- **Conflict:** the secondary zero stub discards a populated physical latch.
  It also supplies a complete low byte that the selected Rev-A target does not
  drive.
- **Current treatment:** `hard_drivin_sound_320_port_latch` captures the low
  TMS byte, reports only host `D15:D8` as driven, and keeps captured-data
  validity separate from its deterministic FPGA filler. See `OQ-030` and
  `docs/integration/hard_drivin_host_reads.md`.
- **Confidence:** VERIFIED_PRIMARY for the populated byte path;
  CORROBORATED for the names in MAME; UNKNOWN for physical host `D7:D0` and
  latch power-up data.

## SC-031 — Physical whole-word mailboxes versus byte-merged emulator state

- **Primary board evidence:** A044427 clocks main-system `ED15:ED0` into
  LS374 `10L`/`10N` with one `/MAINWR`, and local sound-CPU `D15:D0` into
  LS374 `20L`/`20N` with one `/SOUNDWR`. Neither latch pair has reset. LS74
  `20S` presets the corresponding flag from that write and clocks grounded D
  from the opposite read strobe
  [atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 2 of 10,
  PDF pp. 3–4; ti-sn74ls374-datasheet-sdls165b, printed pp. 1–3;
  ti-sn74ls74a-datasheet-sdls119, printed pp. 1–3].
- **Primary main-decode evidence:** A044427 LS138 `20P` generates `/MAINWR`
  locally on Y0 from `ERWN`, `EA15:EA14`, and the expansion qualifiers. This
  is the physical `0x840000..0x843fff` write alias. SP-327 generates the main
  MC68000 byte enables and exports them as `/EWEU` and `/EWEL` on J7, but
  A044427 uses neither at LS138 `20P` nor either LS374 clock
  [atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets 1–2 of
  10, PDF pp. 1–4; atari-hard-drivin-schematic-package-sp327, SP-327 sheets
  4 and 7, PDF pp. 5 and 8]. Local `/SOUNDWR` is similarly not qualified by
  `/WEU` or `/WEL`.
- **Primary CPU evidence:** original-MC68000 Table 3-1 says a selected byte is
  driven on both halves of `D15:D0` in the current implementation. Therefore
  either physical mailbox captures `{byte, byte}` on a byte transfer and the
  original word on a word transfer. The footnote warns that future devices
  need not retain this inactive-lane behavior
  [motorola-m68000-users-manual-ninth, Table 3-1 and footnote, printed pp.
  3-5 through 3-6].
- **Secondary abstraction:** pinned MAME uses `COMBINE_DATA` and a `mem_mask`
  for local sound-CPU writes to `m_sounddata`; its main-side write schedules a
  complete word. Handler calls clear the flags without modeling physical
  strobe edges [mame-harddriv-audio-030fefc, `hd68k_snd_data_w`,
  `hdsnd68k_data_w`, `hd68k_snd_data_r`, and `hdsnd68k_data_r`].
- **Conflict and remaining ambiguity:** MAME preserves the unselected byte,
  while primary hardware sources require `{byte, byte}` on the original
  MC68000. The LS74 function table establishes that asynchronous preset
  dominates a read-clock edge while preset remains asserted. It declares
  simultaneous low preset and reset clear invalid, but the reviewed data
  sheet does not define the exact result when write-preset releases at the
  opposite bus's read-clock edge. Firmware use of byte writes is also not yet
  audited from authorized program images.
- **Current treatment:** `hard_drivin_mc68000_write_word` implements the
  original word/duplicated-byte contract and the timed local `/SOUNDWR` path
  accepts either byte orientation. The external main callback still expects
  an already captured complete word. `hard_drivin_sound_mailboxes` marks a
  same-callback write/read coincidence or reset/write conflict invalid as a
  conservative abstraction of the unresolved edge case; it does not claim
  every physical overlap is unknown. See
  `docs/research/hard_drivin_mailbox_byte_audit.md`.
- **Confidence:** VERIFIED_PRIMARY for original-MC68000 word/byte bus values,
  both mailbox latch paths, nominal flags, and asserted-preset dominance;
  CORROBORATED for MAME's normal software handshake; CONFLICT for MAME's byte
  merge; UNKNOWN for firmware byte-write use and the exact preset-release/
  read-clock edge.

## SC-032 — Live `/READSTAT` inputs versus fixed emulator constants

- **Primary board evidence:** While `/READSTAT` is active, A044427 LS244 `10K`
  drives `MAINFLAG`, `SOUNDFLAG`, raw pulled-up `SOUND.TEST`, and raw active-low
  `/TIRDY` onto host `D15:D12`. This target has no drawn source for `D11:D0`
  [atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 2 of 10,
  PDF pp. 3–4].
- **Secondary abstraction:** pinned MAME returns the two live software flags,
  forces bit 13 high, forces bit 12 low, and returns zero in `D11:D0`
  [mame-harddriv-audio-030fefc, `hdsnd68k_status_r`].
- **Conflict:** MAME's fixed test/ready values do not reproduce live board
  inputs, and its complete low-lane zeros do not prove the partially driven
  physical bus.
- **Current treatment:** `hard_drivin_sound_read_status` accepts all four raw
  sources with independent validity, reports only `D15:D12` as driven, and
  clamps invalid/filler carrier bits to zero without assigning them physical
  meaning. A future host bridge must select its own explicit open-bus policy;
  see `OQ-030`.
- **Confidence:** VERIFIED_PRIMARY for the raw high-nibble mapping;
  CORROBORATED only for MAME's software-visible flag positions; UNKNOWN for
  the complete physical word outside the driven lanes.

## SC-033 — Rev-A `/320PORT`/`/SWITCHES` quadrants versus swapped MAME stubs

- **Primary board evidence:** With the read-select input active, A044427
  LS138 `30N` decodes `A13:A12=01` to `/320PORT` and `10` to `/SWITCHES`.
  `/320PORT` enables LS374 `50L` onto `D15:D8`; `/SWITCHES` enables the first
  half of non-inverting LS244 `10H`, mapping `J3-11`, `J3-9`, `J3-8`, and
  `J3-7` to `D15:D12`
  [atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets 3–4 of
  10, PDF pp. 5–8; ti-snx4ls24x-datasheet, printed pp. 11–13].
- **Secondary abstraction:** pinned MAME maps `hdsnd68k_switches_r` at
  `0xff1000` and `hdsnd68k_320port_r` at `0xff2000`, the opposite named
  order. Both handlers only log and return complete zero words
  [mame-harddriv-audio-030fefc, `driversnd_68k_map`,
  `hdsnd68k_switches_r`, and `hdsnd68k_320port_r`].
- **Conflict:** the handler names disagree with the physical read-quadrant
  wiring, and both stubs omit raw connector/latch sources plus the selected
  targets' undriven lanes. Their equal zero results conceal the swap.
- **Cabinet cross-check:** SP-327 Hard Drivin' cockpit and SP-360 Race Drivin'
  compact main wiring both draw the `044427-XX` Sound PCB's ordinary external
  harness groups but no J3 harness or cabinet device. A044427 ties J3-1/J3-2
  to ground but puts only 1 kOhm series resistors and capacitive shunts on the
  four signal pins; it has no DC input pull. TI defines LS244 driven-input
  thresholds and currents, not an open-input result. MAME's zero is therefore
  neither a documented cabinet switch value nor a qualified disconnected
  level [atari-hard-drivin-schematic-package-sp327, sheet 1, PDF p. 2;
  atari-race-drivin-compact-schematic-package-sp360, sheet 1, PDF p. 2;
  atari-driver-sound-board-schematic, sheet 3, PDF pp. 5-6;
  ti-snx4ls24x-datasheet, printed pp. 4-5].
- **Current treatment:** host-read selection follows LS138 `30N`.
  `hard_drivin_sound_320_port_latch` and
  `hard_drivin_sound_switches` remain distinct masked source adapters, and
  `hard_drivin_sound_host_read_mux` composes them in the physical order. A
  platform reproducing either reviewed cabinet leaves the J3 source-valid
  nibble clear; no emulator zero, floating-TTL tendency, or handler order is
  promoted into the board wrapper. See `OQ-030`, `OQ-032`, and
  `docs/research/hard_drivin_switch_input_audit.md`.
- **Confidence:** VERIFIED_PRIMARY for the physical decode and lane maps;
  VERIFIED_PRIMARY for absence from the two reviewed cabinet wiring diagrams
  and for the no-discrete-pull input network; CORROBORATED for the pinned
  emulator's recorded software abstraction; UNKNOWN for physical open-input
  values, other assembly revisions, and undriven host lanes.

## SC-034 — Physical local-68000 aliases versus canonical emulator windows

- **Primary board evidence:** A044427 drives both drawn `27256D20` EPROM `/CE`
  pins from `A23 OR /AS` and addresses their ordinary pins only from CPU
  `A1:A15`. LS138 `30P` decodes high-bank `A16:A14` only while `A23=1` and
  `/AS=0`; `A22:A17` are absent. The Y5 bank is then split by `A13` into
  program-RAM controls and direct TMS `/PWE`/`/PDEN` controls
  [atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets 3-5 of
  10, PDF pp. 5-10; ti-sn74ls138-datasheet, printed pp. 1-2;
  ti-sn74als32-datasheet-sdas113b, printed p. 1].
- **Secondary abstraction:** pinned MAME declares ROM only at
  `0x000000-0x01ffff` and six canonical high windows from `0xff0000` through
  `0xffffff`. Released Hard Drivin' and Race Drivin' sets load one
  `0x8000`-byte file in each EPROM lane. The Race Drivin' Panorama prototype
  instead loads `0x10000` bytes per lane, while direct-TMS-I/O handlers mask
  their offset with seven
  [mame-harddriv-audio-030fefc, `driversnd_68k_map`,
  `hdsnd68k_320ports_r`, `hdsnd68k_320ports_w`, and Hard Drivin' soundcpu
  ROM declarations; mame-harddriv-driver-030fefc, released-set and
  `racedrivpan` soundcpu declarations].
- **Conflict:** the released sets' 64 KiB payloads corroborate the drawing's
  two-27256 configuration, but a generic 128 KiB emulator region does not
  reproduce that configuration's A16 mirror. The Panorama prototype may use
  the larger capacity, but its declaration does not qualify physical E2.
  MAME also omits the broad physical `A23=0` and `A22:A17` aliases.
  For upper-Y5 I/O, MAME applies `offset & 7` to both directions. Physical
  LS139 95K instead ignores `RA11:RA2` and aliases every read modulo four;
  physical write predecode `PORT` requires `RA11:RA3=0`, so noncanonical
  writes select no LS138 100K output at all.
- **EPROM-option refinement:** A044427 makes `E1` the +5-V link and `E2` the
  CPU-A16 link to both EPROM pin-1 nodes. Contemporaneous AMD family data
  makes E1 the required 27256-read configuration and E2 the intended 27512
  highest-address configuration. The Panorama declaration shows that the
  larger image case is operationally relevant, but it neither identifies an
  `A046491-01`/`-02` population nor proves distinct 32 KiB halves. See
  `docs/research/hard_drivin_program_rom_strap_audit.md`
  [atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 3 of 10,
  PDF pp. 5-6; amd-bipolar-mos-memories-databook-1986, printed pp. 6-15
  through 6-21, PDF pp. 821-827].
- **Current treatment:** the storage-free board decoder exposes raw selects,
  the exact drawing-default word addresses, and the Y5 control split. The separate
  direct-I/O adapter implements the primary downstream asymmetry, masks
  undriven read lanes, and reports noncanonical writes without aliasing them.
  Higher-level software maps may retain canonical windows, but cannot describe
  omitted aliases or padding as pin-equivalent. See `OQ-034`,
  `docs/integration/hard_drivin_local_memory.md`, and
  `docs/integration/hard_drivin_direct_io.md`.
- **Confidence:** VERIFIED_PRIMARY for the Rev-A decode and E1/E2 electrical
  meaning; CORROBORATED for canonical software ranges and declared image
  sizes; UNKNOWN for installed jumper, image-half uniqueness, and assembly
  variants.

## SC-035 — Physical paired RC reset hold versus instantaneous emulator reset

- **Primary board evidence:** A044427 LS08 `10S` combines `/MRES` and decoded
  `/SRES` into the active-low A trigger of LS123 `100N`. With B and clear high,
  C43=10 µF, and R79=47 kΩ, `/Q` remains low after a falling trigger. The `/Q`
  signal and active-low `SOUND.RESET` test input feed LS00 `40S`; separate 7406
  open-collector outputs and pull-ups then drive local MC68000 HALT and RESET
  with equal stable logic [atari-driver-sound-board-schematic, drawing A044427
  Rev A, sheet 2 of 10, PDF pp. 3-4]. TI identifies the part as retriggerable
  and gives the typical `Cext >= 1 µF` equation, yielding about 155.1 ms
  nominal. It also states that retrigger pulses beginning before
  `0.22 * Cext(pF)` ns are ignored, yielding about 2.2 ms with C43
  [ti-sn74ls123-datasheet-sdls043, printed pp. 1-2 and 8-9].
- **Secondary abstraction:** pinned MAME's `hd68k_snd_reset_w` asserts and then
  immediately clears only `INPUT_LINE_RESET`; it does not drive HALT or model
  the monostable interval [mame-harddriv-audio-030fefc,
  `hd68k_snd_reset_w`].
- **Conflict:** the emulator preserves a functional request to restart the
  local CPU but omits two electrically observable properties: paired HALT and
  a long RC-defined hold. It therefore cannot qualify reset pin timing.
- **Current treatment:** `hard_drivin_sound_local_reset_source` models the
  verified falling-edge/direct-reset Boolean behavior and the documented early
  retrigger-inhibit rule in an explicit caller-calibrated tick domain. Its
  deterministic initial hold is labeled an FPGA convention. It remains
  separate from the board top and the SRAM-scrub interlock until `OQ-035`
  resolves timebase, tolerance, and CDC policy.
- **Confidence:** VERIFIED_PRIMARY for the populated Rev-A connectivity and
  nominal typical calculation; CORROBORATED for MAME's functional restart
  intent; UNKNOWN for production pulse limits and power-up behavior.

## SC-036 — Physical `/SRES` mirror versus canonical emulator word

- **Primary decode evidence:** SP-327 sheet 4 makes `/EXTBUS` active for
  `/AS=0` and `A23:A21=100`; sheet 7 buffers it to `/EXTB` with `/RVAS`, R/W,
  and address. A044427 sheet 1 enables LS138 `20P` only when `/EXTB=0`,
  `/ERVAS=0`, `EA18=1`, and `EA20=EA19=EA17=EA16=0`; Y3 then selects write
  direction with `EA15:EA14=11`. Neither A13:A0 nor UDS/LDS participates
  [atari-hard-drivin-schematic-package-sp327, sheets 4 and 7, PDF pp. 5 and 8;
  atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 1 of 10,
  PDF pp. 1-2]. The resulting physical write mirror is
  `0x84c000..0x84ffff`.
- **Secondary abstraction:** pinned MAME installs `hd68k_snd_reset_w` only at
  `0x84c000..0x84c001` [mame-harddriv-driver-030fefc,
  `init_driver_sound`].
- **Conflict:** the canonical software word agrees, but the emulator does not
  expose the lower-address-bit aliases created by the TTL decode.
- **Current treatment:** `hard_drivin_main_sound_reset_decode` implements the
  complete primary-backed high-address/control equation and omits A13:A0 from
  its interface. Directed compositions now connect it to the independently
  qualified `/RVAS0`/`RVA`/`/RVAS` timing and complete `/DTACK` equation, but
  no raw-pin main-board wrapper or local one-shot connection is claimed until
  CDC and electrical timing are qualified.
- **Confidence:** VERIFIED_PRIMARY for the physical address/control decode;
  CORROBORATED for software use of the canonical word; UNKNOWN for whether
  shipped firmware ever accesses an alias.

## SC-037 — CALA/RET every-cycle MEN versus secondary idle interval

- **Primary constraints:** SPRU001B defines `CALA` and `RET` as one-word,
  two-cycle instructions. Program memory is PC-addressed, Figure 2-2 requires
  overlapped prefetch, and Table 2-4 says `/MEN` is active on every machine
  cycle except a `WE` or `DEN` interval. Neither instruction uses those
  exception strobes. Figure 2-10 independently demonstrates a discarded
  sequential fetch before a one-word multicycle program redirect
  [ti-tms32010-users-guide-spru001b, §§2.1.1, 2.4.2, 2.8.2, Table 2-4,
  and `CALA`/`RET`, printed pp. 2-3, 2-10, 2-17, 2-21, 3-25, and 3-51
  (PDF pp. 27, 34, 41, 45, 75, and 101)].
- **Independent implementation:** pinned IKA32010 performs stack/PC mutation
  with `BUSCTRL_STOP` in its first CALA/RET microcycle, then requests an
  opcode read at the selected target in its second. Its bus controller holds
  `/MEN`, `/DEN`, and `/WE` inactive throughout `BUSCTRL_STOP`
  [ika32010-rtl-51bc1f0, `IKA32010.sv`, lines 166-228 and 1401-1461].
- **Contemporary TI RET timing:** US4577282A's related embodiment explicitly
  discards the sequential S1 fetch, pops the old stack top into PC in Q3/S1,
  fetches from that return address during Q4/S1-Q1/S2, and begins decoding the
  return word at Q3/S2. The same source restates the every-state external read
  rule. This is direct corroboration of ADR-0003's RET ordering, but the patent
  is architectural background rather than an original-part production
  specification [ti-dsp-microcomputer-patent-us4577282a, patent cols. 5-6 and
  17-18 (PDF pp. 29 and 35), Figure 3u].
- **Conflict:** the idle interval is not compatible with the original TI
  every-cycle `/MEN` rule. The primary sources still do not state whether
  cycle 1 reads/discards `PC+1` or repeats the already selected target.
- **Current treatment:** ADR-0003 chooses `PC+1` discard followed by selected
  target fetch as a reversible implementation mapping. It is CORROBORATED for
  RET by the related TI patent and remains INFERRED for CALA from the primary
  TBL analogy. No original-part physical timing claim is made. MAME's
  functional handlers and fixed totals cannot arbitrate because its
  instruction hook exposes no bus subcycles.
- **Confidence:** VERIFIED_PRIMARY for the state transform, two-cycle total,
  and active `/MEN` in both intervals; CORROBORATED for RET and INFERRED for
  CALA `PC+1`-then-target ownership; UNKNOWN for original-silicon
  confirmation.

## SC-038 — Original 144-word RAM versus boundary descriptions

- **Production capacity evidence:** SPRU001B says the original data RAM has
  144 words. SPRU002B's LDP and LDPK descriptions and the later first-
  generation guide define the original part's page 1 as locations 128-143,
  which combines with page 0 to produce exactly 144 words
  [ti-tms32010-users-guide-spru001b, Section 2.3, printed p. 2-7 (PDF p. 31);
  ti-tms32010-assembly-guide-spru002b, `LDP`/`LDPK`, printed pp. 3-36-3-37
  (PDF pp. 57-58); ti-first-generation-users-guide-1987, Sections 3.4.1 and
  3.4.6, printed pp. 3-10 and 3-19 (PDF pp. 39 and 48)].
- **Primary outlier:** SPRU001B's immediately following direct-address table
  prints page 1 as 128-144. Together with page 0's 128 words, that would be 145
  locations and conflicts with the surrounding capacity statement
  [ti-tms32010-users-guide-spru001b, Section 2.3.1.2, printed p. 2-8
  (PDF p. 32)].
- **Related-embodiment inconsistency:** US4577282A describes a 1-of-144 row
  decoder and 1-of-2 column decoder while saying eight bits suffice, then
  describes 144 physical row lines plus an even/odd word select. Its ordinary
  RAM-move description complements the column bit and increments the row for
  an odd source, but never defines the final row or an absent select
  [ti-dsp-microcomputer-patent-us4577282a, patent cols. 17-18 and 25-26
  (PDF pp. 35 and 39), Figures 5i-5j].
- **Independent implementations:** pinned MAME maps the TMS320C10 data space
  only through `0x8f` but asks its memory framework to write `m_memaccess+1`;
  pinned IKA32010 instead allocates 256 words and writes `0x8f` to `0x90`
  [mame-tms320c1x-core-030fefc, `tms320c10_ram`, `dmov`, and `ltd`;
  ika32010-rtl-51bc1f0, `IKA32010_ram`, lines 1909-1937].
- **Current treatment:** valid original storage is `0x00`-`0x8f`; `0x90` is
  not inferred from the outlier. Model/RTL reject the boundary move before all
  effects as a PROVISIONAL safety policy. The clear/scan/register experiment
  in `docs/research/ram_boundary_experiment.md` is required before assigning
  physical suppression, hidden storage, aliasing, corruption, or parallel LTD
  effects. Its paired normalizer preserves all 144 valid words, the diagnostic
  word, and every captured register field even when they vary or contradict
  the conservative implementation. `review_ready` qualifies only the fixed
  baseline package; varied history/sentinels and raw engineering review remain
  mandatory before this conflict can advance.
- **Confidence:** VERIFIED_PRIMARY for the 144-word implemented range;
  UNKNOWN for every access beyond it and for the boundary move outcome.

## SC-039 — Original versus later-family interrupt pipeline boundary

- **Original production guide:** SPRU001B Figure 2-12 shows fetches N, N+1,
  dummy N+2, and vector 2 aligned with execution of N, N+1, a dummy slot, and
  vector 2. Its Figure 2-11 places a synchronization flip-flop inside the
  simplified TMS32010 boundary and gates interrupt-active with enabled INTM
  [ti-tms32010-users-guide-spru001b, Section 2.10 and Figures 2-11-2-12,
  printed pp. 2-18-2-19 (PDF pp. 42-43)].
- **Original internal polarity typo:** prose on printed page 2-19 says a set
  INTM validates interrupt-active, contradicting Figure 2-11's enabled
  complement, its zero-enabled legend, and the same page's statement that
  DINT sets INTM to disable interrupts. Later SPRU013 correctly states that
  active becomes valid at INTM zero. The project treats the isolated word as
  a polarity error; it supplies no DINT/grant priority evidence
  [ti-tms32010-users-guide-spru001b, Section 2.10, printed p. 2-19 (PDF p. 43);
  ti-first-generation-users-guide-1987, Section 3.8, printed p. 3-31 (PDF
  p. 60)].
- **Later mixed-family guide:** SPRU013 Figure 3-20 instead shows fetch N,
  dummy N+1, and vector 2 aligned with execute N, dummy, and vector 2. Its
  Section 3.8 says asynchronous NMOS TMS32010 INT needs external
  synchronization and labels Figure 3-19's internal circuitry as CMOS-family
  behavior. Original SPRU001B Section 2.14 independently recommends the same
  external CLKOUT-clocked conditioning despite its simplified internal Sync
  FF. The DINT page says masking begins immediately after DINT executes
  [ti-tms32010-users-guide-spru001b, Section 2.14 and Figure 2-17, printed
  p. 2-24 (PDF p. 48); ti-first-generation-users-guide-1987, Section 3.8,
  Figures 3-19-3-20, and
  `DINT`, printed pp. 3-31-3-34 and 4-32 (PDF pp. 60-63 and 113)].
- **Conflict:** the later sequence does not execute N+1 before service and
  therefore cannot answer the original Figure 2-12 case where N+1 is DINT.
  That trace discrepancy could reflect a correction, a CMOS-family
  generalization, or multiple recognition apertures; no located erratum
  identifies which. External synchronization for asynchronous NMOS input is
  not disputed: both guides require or recommend it.
- **Independent implementations:** pinned MAME has no overlapping N/N+1
  fetch/execute state and cannot express the race. Pinned IKA32010 evaluates
  an old-mask `int_rq` while DINT sets the mask at the same FPGA edge, yielding
  entry-wins when the request is already active. Neither resolves production
  silicon.
- **Current treatment:** SPRU001B remains the original-device timing authority
  for qualified normal entry. DINT cancellation at its protected N+1 boundary
  remains PROVISIONAL, and internal analog synchronization is not claimed.
  `docs/research/dint_interrupt_race_experiment.md` defines the stable
  original-NMOS pulse/address/stacked-PC capture required to resolve `OQ-019`
  and further constrain `OQ-004`. The strict
  `tools.trace.dint_interrupt_capture` classifier retains all three candidate
  sequences and any unanticipated port words, recomputes the published pulse
  constraints, and validates provenance. It now binds exact source/listing/
  image, decoded trace, calibrations, and a complete `OQ-008` record to one
  named specimen while leaving `acceptance_complete=false`; synthetic
  classifier fixtures and complete bookkeeping do not resolve this conflict
  or prove cross-specimen invariance.
- **Confidence:** VERIFIED_PRIMARY that the two TI publications differ;
  CORROBORATED_PRIMARY for external asynchronous conditioning; UNKNOWN for
  original-silicon DINT priority beyond published setup/pulse requirements.

## SC-040 — Unsupported simultaneous AR update versus modeled preservation

- **Original-part boundary:** SPRU001B and SPRU002B define indirect bit 5 as
  increment and bit 4 as decrement, expose only preserve/`*+`/`*-` source
  forms, and do not define both bits set. Unlike bits 6, 2, and 1, they do not
  call this combination reserved
  [ti-tms32010-users-guide-spru001b, Section 3.3.2, printed p. 3-2
  (PDF p. 52); ti-tms32010-assembly-guide-spru002b, Section 3.3.2, printed
  p. 3-2 (PDF p. 23)].
- **Later TI prohibition:** the TMS320C1x programmer's reference card included
  with SPRU013 explicitly says INC and DEC cannot both be one. It establishes
  an unsupported later-family source form, not original forced-word execution
  [ti-first-generation-users-guide-1987, TMS320C1x Programmer's Reference
  Card, unnumbered card page (PDF p. 402)].
- **Related TI embodiment:** US4577282A describes separate increment and
  decrement counter controls but assumes the decrement path occurs “instead
  of” increment. It neither defines both active nor proves production decode
  exclusion [ti-dsp-microcomputer-patent-us4577282a, patent cols. 27-28
  (PDF p. 40)].
- **Independent implementations:** pinned MAME increments then decrements a
  temporary value, producing no net low-nine-bit change, while its
  disassembler renders the mode `??`. Pinned IKA forwards both raw controls
  into a `2'b11` case that explicitly preserves the register. Their agreement
  is a candidate hypothesis without original-device provenance
  [mame-tms320c1x-core-030fefc, `UPDATE_AR`, lines 240-248;
  mame-tms320c1x-disassembler-030fefc, lines 33-34;
  ika32010-rtl-51bc1f0, `IKA32010.sv`, lines 290-328].
- **Current treatment:** all 372 words remain outside the legal decoder and
  trap before effects in the model/RTL. This is an explicit fail-closed
  project policy, not a physical trap claim. The exact two-boundary raw-word
  capture in `docs/research/simultaneous_ar_update_experiment.md` assigns no
  expected silicon sequence and is required before implementing a result. Its
  strict classifier preserves all three complete priority candidates, any
  other complete sequence, and three partial noncompletion stages. Only a
  stable complete candidate with exact image/anchor/provenance checks can be
  `review_ready`. The package now binds exact source/listing/decoded trace and
  a complete `OQ-008` record to one named specimen while always leaving
  `acceptance_complete=false`; even that package status cannot change this
  conflict without engineering review of the raw physical evidence or prove
  cross-specimen invariance.
- **Confidence:** VERIFIED_PRIMARY that later C1x software prohibits the
  combination; CORROBORATED that MAME and IKA choose no net update; UNKNOWN
  for original NMOS execution, timing, and stability.

## SC-041 — Eight-bit data-address reach versus 144-word storage

- **Original production boundary:** SPRU001B says all non-immediate operands
  reside in exactly 144 on-chip words. Its direct form nevertheless
  concatenates DP and seven operand bits, and its indirect form supplies all
  eight low AR bits. Neither form defines a failed or absent select
  [ti-tms32010-users-guide-spru001b, Sections 2.3-2.3.1.2, printed
  pp. 2-7-2-8 (PDF pp. 31-32)].
- **Exact implemented map:** SPRU002B and SPRU013 identify page 0 as
  `0x00`-`0x7f` and the original TMS32010 page 1 as `0x80`-`0x8f`. The
  isolated SPRU001B `128-144` endpoint error remains `SC-005`/`SC-038`; it
  cannot explain the other 111 absent eight-bit selects
  [ti-tms32010-assembly-guide-spru002b, `LDP`/`LDPK`, printed
  pp. 3-36-3-37 (PDF pp. 57-58); ti-first-generation-users-guide-1987,
  Sections 3.4.1 and 3.4.4, Figure 3-5, printed pp. 3-10 and 3-13
  (PDF pp. 39 and 42)].
- **Related physical evidence:** US4577282A exposes an eight-bit related RAM
  address and row/column decode, but its capacity statements are internally
  inconsistent and do not define an unselected row, alias, precharge value,
  or write disturbance. The indexed TMS320M10 decap lead was unavailable with
  HTTP 429 and its visible description concerns ROM extraction; it supplies
  no production RAM decode evidence.
- **Independent implementation conflict:** pinned MAME maps only
  `0x00`-`0x8f` in its eight-bit data space, leaving the rest to framework
  unmapped-space policy. Pinned IKA32010 instantiates 256 initialized words.
  Neither choice is original-device evidence
  [mame-tms320c1x-core-030fefc, `tms320c10_ram`, lines 40-49, and data-space
  configuration, lines 64-68; ika32010-rtl-51bc1f0, `IKA32010_ram`, lines
  1909-1937].
- **Current treatment:** model/RTL trap before effects; the standalone RAM's
  invalid-read zero is diagnostic policy only. The read-only controlled-
  history sweep must run before either directional unique-sentinel write
  sweep in `docs/research/ram_invalid_decode_experiment.md`. None has an
  expected absent-region result. A strict stage-1 classifier now preserves
  both raw values and a descriptive relationship for every absent address,
  requires the complete reset/cold-power package, and permits variable results
  to reach review. It always leaves overall acceptance incomplete until the
  ordered destructive stages, any targeted follow-up, raw review, and another
  specimen are complete. The paired stage-2 normalizer now preserves every
  valid disturbance and direction-specific address/sentinel/readback tuple.
  It requires a pinned stage-1 report plus an explicit order declaration while
  disclosing that those records do not independently prove physical chronology.
- **Confidence:** VERIFIED_PRIMARY for `0x00`-`0x8f` implemented storage;
  UNKNOWN for original NMOS reads, writes, retirement, aliasing, disturbance,
  electrical stability, and mask invariance across `0x90`-`0xff`.

## SC-042 — Production reset omissions versus EVM warm-save behavior

- **Production-device boundary:** SPRU001B Section 2.11 assigns PC/address
  clear, inactive external controls, a tristated data bus, `INTM=1`, cleared
  interrupt flag, and unchanged OVM. It does not assign ACC, T, P, AR0/AR1,
  ARP, DP, stack, or OV
  [ti-tms32010-users-guide-spru001b, Sections 2.6.1 and 2.11, printed
  pp. 2-13 and 2-19 (PDF pp. 37 and 43)].
- **Contemporary TI workflow evidence:** SPRU005A's `EX` and `RUN` commands
  say an EVM warm RESET saves every TMS32010 register except PC. Its register
  menu includes all of the unlisted state above. The same guide's warm-reset
  overview warns that the uncontrolled halt clears internal registers and may
  corrupt memory, but does not publish whether saving precedes clearing or
  which instructions perform the save
  [ti-tms32010-evm-users-guide-spru005a, Section 2.3.10.2, Table 3-2, and
  `EX`/`RUN`, printed pp. 2-28-2-29, 3-4-3-5, 3-27-3-28, and 3-56-3-57
  (PDF pp. 39-40, 45-46, 68-69, and 97-98)].
- **Related-embodiment distinction:** US4577282A attributes address and
  temporary-register clearing to a ROM reset routine and separately says RAM
  is not cleared. It therefore cannot turn software initialization into a
  hardware-reset value [ti-dsp-microcomputer-patent-us4577282a, patent
  columns 5-6 (PDF p. 29)].
- **Independent policy conflict:** pinned MAME uses a mixed reset policy that
  resets ACC and selected status bits, forces OVM set contrary to SPRU001B,
  and leaves T/P/AR/stack untouched after device start. Pinned IKA retains OVM
  but clears multiple unlisted registers. Neither is original-device proof.
- **Current treatment:** the model/RTL retains every unlisted register and
  labels that choice PROVISIONAL. The two complementary BIO-selected
  before/restore/reset/after images and exact capture protocol in
  `docs/research/reset_retention_experiment.md` are required before upgrading
  original-silicon confidence. A strict paired normalizer now checks the exact
  images, BIO/RS timing, the nine clock/hold combinations, reset bus contract,
  every field relationship, and provenance without expecting retention.
  `review_ready` remains package status and never closes the question without
  raw review and a second specimen. The EVM manual is CORROBORATED workflow
  evidence only.
- **Confidence:** VERIFIED_PRIMARY for the named reset effects and unchanged
  OVM; CORROBORATED for EVM register recoverability; UNKNOWN for the exact
  physical reset network and mask invariance of all unlisted state.

## SC-043 — Publication/speed-grade changes versus unknown silicon revisions

- **Revisioned primary artifacts:** one pinned SPRU001B artifact appends a
  TMS32010 data sheet revised October 1985; another appends a February-1986
  revision despite the same March-1985 manual colophon. The former labels
  base TMS32010 and TMS32010-25 speed versions, while the latter uses
  TMS32010-20 and TMS32010-25 timing-table labels
  [ti-tms32010-users-guide-1985-alt-scan, appended data-sheet heading,
  PDF p. 358; ti-tms32010-users-guide-spru001b, appended data-sheet heading
  and clock table, PDF pp. 357 and 366-367].
- **Product-list change:** the December-1986 support guide and May-1987
  family guide list 14/20/25-MHz 2.4-micrometer NMOS TMS32010 products. The
  April-1989 support guide and May-1989 revised first-generation data sheet
  list only the 20-MHz NMOS TMS32010 while retaining separate CMOS speed
  grades. None calls this a mask change, discontinuation notice, or functional
  difference
  [ti-development-support-spru011-1986, Appendix A Table A-1, PDF p. 176;
  ti-first-generation-users-guide-1987, Appendix A and Appendix E, PDF
  pp. 232-234 and 361; ti-development-support-spru011a-1989, Section 2.1 and
  Appendix A, PDF pp. 21 and 318; ti-first-generation-users-guide-1989,
  Appendix A and Appendix E, PDF pp. 238-240 and 426].
- **Package-marking boundary:** both original data-sheet artifacts describe a
  standard part number, tracking mark/date code, and lot code, but publish no
  mask-revision character or code map. Raw package strings must therefore be
  preserved; they cannot be decoded by assumption
  [ti-tms32010-users-guide-1985-alt-scan, symbolization, PDF p. 379;
  ti-tms32010-users-guide-spru001b, symbolization, PDF p. 377].
- **Missing update channel:** TI says current/new-device specification updates
  were communicated through its contemporary dial-up BBS. No authenticated
  TMS32010-specific BBS notice archive has been located, so the surviving
  manuals are not proved complete
  [ti-development-support-spru011a-1989, Section 7.7, PDF pp. 160-161].
- **Current treatment:** document revision, speed grade, package suffix,
  tracking/date string, lot, ROM sibling, and later CMOS/later-generation
  device identity remain separate fields. No model or RTL behavior changes.
  `docs/research/device_revision_audit.md` defines the search log and specimen
  evidence rules; `OQ-008` remains open.
- **Confidence:** VERIFIED_PRIMARY for the document/product-list timeline;
  UNKNOWN for original-NMOS mask identities, behavior changes, and invariance.

## SC-044 — Physical sample-ROM block 8 versus packed MAME block 4

- **Primary board map:** A044427 sheet 6 assigns A-row sockets `65A`, `55A`,
  `45A`, `30A`, `20A`, and `5A` to `/SR0` through `/SR5`. C-row sockets
  `65C`, `55C`, `45C`, `30C`, `20C`, and `5C` receive `/SR6` through `/SR11`.
  Thus `45C` is physical block 8; the complete C row is marked `NOT LOADED` on
  the Rev-A drawing [atari-driver-sound-board-schematic, drawing A044427 Rev
  A, sheet 6 of 10, PDF pp. 11-12].
- **Primary upgrade population:** Atari TM-356 identifies an `A046491-02`
  Driver Sound PCB Assembly and instructs the technician to install
  `136077-1017` at `45C`. It also requires `136052-3125` at `45A` when not
  already present [atari-race-drivin-upgrade-kit-tm356-first, Figure 1-3 and
  Figure 1-7, printed pp. 1-5 and 1-10, PDF pp. 13 and 18].
- **Secondary packed map:** pinned MAME allocates a `0x50000`-byte Race Drivin'
  region, loads the four A-row files at offsets `0x00000` through `0x30000`,
  and appends `136077-1017.45c` at `0x40000`. Its port-6 handler uses the block
  nibble as address bits 19:16, so those bytes are selected as block 4. The
  adjacent `10*128k` comment matches neither the five 64-KiB files nor the
  declared region [mame-harddriv-driver-030fefc, Race Drivin' `serialroms`
  declarations; mame-harddriv-audio-030fefc, `hdsnddsp_soundaddr_w` and
  `hdsnddsp_rom_r`].
- **Conflict:** no reviewed primary source remaps 45C to `/SR4`. Correcting the
  physical wrapper to packed block 4 would contradict both the schematic and
  Atari's installation figure. Whether current Race Drivin' firmware selects
  block 8, and which sounds MAME loses or substitutes if it does, require an
  authorized trace.
- **Current treatment:** `sound_rom_present_i[11:0]` follows physical selects;
  45C sets bit 8. The content-free socket analyzer enforces the same sparse
  matrix. MAME remains a named secondary oracle for content hashes, not block
  placement. See `OQ-026` and
  `docs/research/hard_drivin_sample_rom_population_audit.md`.
- **Confidence:** VERIFIED_PRIMARY for the Rev-A block/socket wiring and the
  TM-356 upgrade socket; CORROBORATED for MAME's packed behavior; UNKNOWN for
  factory populations, authorized firmware use, and absent-bus values.
