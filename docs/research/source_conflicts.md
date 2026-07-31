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
wrapper-level phase pause may still be useful, but it cannot be labeled a
native protocol without clocking evidence. **Treatment: open as OQ-001.**

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

- **Original-part sources:** SPRU001B and SPRU002B `LST`, printed p. 3-38,
  and SPRU013 `LST`, printed p. 4-43, all expose an optional indirect
  next-ARP operand while stating that data-word bit 8 loads `ARP`. None states
  which source wins when the two values differ.
- **Variant clarification:** TI SPRU012 `LST`, printed p. 4-75, explicitly
  says the next-ARP field is ignored and the memory word supplies `ARP`.
- **Independent oracle:** pinned MAME commit
  `030fefcbd14e47c01ec9d67655be90f64a1dc8ab` suppresses the ordinary
  next-ARP update in its `lst()` handler before loading the status word.
- **Current treatment:** the model and RTL will ignore LST's encoded next-ARP
  field and load `ARP` from source bit 8. This is a targeted, tested
  provisional original-part behavior under `OQ-015`, not a claim that later
  C25 behavior proves the NMOS TMS32010.
- **Confidence:** PROVISIONAL for the original TMS32010; CORROBORATED across
  the later TI guide and independent emulator.

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
- **Independent oracle:** pinned MAME commit
  `030fefcbd14e47c01ec9d67655be90f64a1dc8ab` computes the documented
  conditional result immediately. Its handler appears intended to detect
  signed overflow of the intermediate subtraction, but the present Boolean
  expression compares the old accumulator with an unchanged accumulator and
  therefore cannot set `OV`
  [mame-tms320c1x-core-030fefc, `subc()`, lines 732–742].
- **Current treatment:** the model and RTL provisionally set sticky `OV` on
  signed overflow of the intermediate subtract, ignore `OVM`, and never
  saturate. Directed tests distinguish intermediate-only and final-shift-only
  overflow vectors and label that boundary provisional.
  Tests place an ACC-free instruction after every SUBC; behavior of a
  violating dependent sequence is not claimed. See `OQ-017` and `OQ-018`.
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
- **Independent FPGA implementation:** pinned IKA32010 commit
  `51bc1f05a2a08a61c8815a9643d08a42e99779c6` requests `BUSCTRL_STOP` and
  holds PC during PUSH/POP microcycle zero, then requests `OPCODE_READ` from
  PC during microcycle one [ika32010-rtl-51bc1f0, lines 690–731].
- **Conflict:** the secondary implementation supplies a useful PC-hold
  hypothesis but suppresses the first program transaction that the primary
  every-cycle `MEN` wording requires. Replacing that idle with an active
  discarded read is plausible, but would still invent the address/validity
  relationship without a waveform.
- **Current treatment:** do not copy either external sequence into the RTL.
  Preserve H1 inactive, H2 repeated/discarded `N+1`, and H3 advancing
  prefetch as separately measurable hypotheses. The synthetic fixture and
  original-device capture criteria are in
  `docs/research/push_pop_bus_experiment.md`; see `OQ-016`.
- **Confidence:** VERIFIED_PRIMARY for two cycles, general `MEN` behavior,
  and the architectural state transform; UNKNOWN for the exact address and
  fetched-word ownership of each cycle.
