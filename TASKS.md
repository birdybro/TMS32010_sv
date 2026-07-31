# Engineering backlog

Statuses: `NOT STARTED`, `RESEARCHING`, `BLOCKED`, `IMPLEMENTING`, `VERIFYING`,
`COMPLETE`. A task reaches `COMPLETE` only after all acceptance criteria have
objective passing evidence.

## Milestone 1 — Repository and automation foundation

### REPO-001 — Repository structure and governance

- **Status:** COMPLETE
- **Priority:** P0
- **Dependencies:** none
- **Description:** Establish the required layout, governance, licensing,
  contribution policy, build entrypoints, progress evidence, and clean default
  branch.
- **Acceptance criteria:** all required paths exist; governance covers source
  precedence, RTL rules, verification, ambiguity, provenance, and commit
  policy; `make help`, `make docs`, and a clean-tree audit pass; generated
  products are ignored.
- **Documentation:** `AGENTS.md`, `README.md`, `CONTRIBUTING.md`
- **Tests:** `tests/regressions/test_repository.py`
- **Notes:** Existing GitHub repository already uses `main`; retain its initial
  commit.

### REPO-002 — Continuous integration

- **Status:** VERIFYING
- **Priority:** P1
- **Dependencies:** REPO-001
- **Description:** Add pinned, legal CI jobs for formatting, Python tests, RTL,
  documentation consistency, and synthesis smoke tests.
- **Acceptance criteria:** workflow passes from a clean checkout and does not
  fetch legacy executables or copyrighted ROMs/manuals.
- **Documentation:** `.github/workflows/`, `CONTRIBUTING.md`
- **Tests:** GitHub Actions workflow runs
- **Notes:** Pinned Ubuntu 24.04 jobs cover repository/model/tool checks,
  Verilator regression/lint, and Yosys synthesis. Local structural tests and
  equivalent tool runs pass; retain `VERIFYING` until the workflow completes
  on GitHub. No dependency cache is needed because the Python tooling is
  standard-library-only and simulator/synthesis packages come from Ubuntu.

## Milestone 2 — Documentation acquisition and provenance

### REF-001 — Reference manifest and acquisition tools

- **Status:** COMPLETE
- **Priority:** P0
- **Dependencies:** REPO-001
- **Description:** Catalog primary TI documents, Atari board documents, current
  MAME paths, development tools, and independent research; implement safe,
  idempotent fetching and hash verification.
- **Acceptance criteria:** required manifest fields validate; downloads remain
  ignored; content types and SHA-256 are checked; unavailable sources do not
  abort the full fetch; no binary is executed.
- **Documentation:** `docs/references/manifest.yaml`,
  `docs/references/README.md`
- **Tests:** `tests/regressions/test_references.py`
- **Notes:** Redistribution status of historical manuals is assumed unclear
  until permission is demonstrated.

## Milestone 3 — Architecture specification

### ARCH-001 — Cited original-TMS32010 specification

- **Status:** VERIFYING
- **Priority:** P0
- **Dependencies:** REF-001
- **Description:** Specify the programmer's model, memory model, pipeline,
  interrupts, native interface, reset behavior, and device-variant boundaries.
- **Acceptance criteria:** each architectural claim has a precise primary
  citation and confidence; contradictions and unknowns are linked; no C10/C15
  behavior is silently assigned to the TMS32010.
- **Documentation:** `docs/architecture/*.md`, `docs/research/*.md`
- **Tests:** `tests/regressions/test_documentation.py`
- **Notes:** Initial primary-cited baseline and ADR exist. Remaining acceptance
  work includes exact reserved status bits,
  out-of-range RAM decode, explicit interrupt ownership beyond the qualified
  basic Figure 2-12 path, and the
  per-cycle program-address/fetched-word ownership of single-word PUSH/POP
  under `OQ-016`. TI's every-cycle `MEN` rule narrows the strobe behavior, but
  does not distinguish a repeated/discarded next-word read from an advancing
  prefetch; `SC-018` and the physical experiment preserve that boundary.
  Physical pin timing and logical transaction timing must remain distinct.

## Milestone 4 — Instruction encoding database

### ISA-001 — Canonical machine-readable ISA

- **Status:** IMPLEMENTING
- **Priority:** P0
- **Dependencies:** ARCH-001
- **Description:** Encode every documented TMS32010 mnemonic, legal encoding,
  operand, side effect, cycle case, bus operation, citation, and uncertainty.
- **Acceptance criteria:** complete 16-bit decode-space audit has no collisions;
  all legal and reserved regions are classified; generated tables reproduce
  independently verified fixtures.
- **Documentation:** `docs/generated/tms32010_isa.yaml`,
  `docs/architecture/opcode_map.md`
- **Tests:** `tests/regressions/test_isa_database.py`,
  `tests/expected/opcode_fixtures.yaml`
- **Notes:** All sixty documented mnemonics (`ABS`, `ADD`, `ADDH`, `ADDS`, `AND`, `APAC`, `B`, `BANZ`, `BGEZ`, `BGZ`, `BIOZ`, `BLEZ`, `BLZ`, `BNZ`, `BV`, `BZ`, `CALA`, `CALL`, `DINT`, `DMOV`, `EINT`, `IN`, `LAC`, `LACK`, `LAR`,
  `LARK`, `LARP`, `LDP`, `LDPK`, `LST`, `LT`, `LTA`, `LTD`, `MAR`, `MPY`, `MPYK`, `NOP`, `OR`, `OUT`, `ROVM`,
  `PAC`, `POP`, `PUSH`, `RET`, `SACL`, `SACH`, `SAR`,
  `SOVM`, `SPAC`, `SST`, `TBLR`, `TBLW`, `XOR`, `ZAC`, `ZALH`, `ZALS`, `SUB`,
  `SUBC`, `SUBH`, `SUBS`) are primary-transcribed in the opcode research table. The
  twenty-six common-address data instructions plus SST's forced-page direct
  form add
  conditional legality constraints for
  indirect control bits; SACH additionally restricts its sparse shift field
  to 0, 1, and 4. The
  IN and OUT add 2,240 legal direct/indirect port/address combinations under
  those same common indirect constraints. TBLR/TBLW add 280 legal common
  address combinations. The decoder exhaustively classifies all 65,536 words
  against this supported set, accepting 21,895 supported words without
  collisions; full reserved-region classification remains. Exact `ABS=0x7f88`, accumulator result, OVM-selected
  most-negative wrap/saturation, and one-cycle program-only boundary are
  primary-verified. Original-part OV preservation is `CORROBORATED` by
  SPRU013's instruction-format rule, the absence of status annotations on the
  original ABS page, the later C14/E14 variant's explicit added OV effect,
  and pinned MAME; `SC-007`/`OQ-013` record the resolution. Exact
  `SST=0x7cxx` contributes 28 legal encodings: direct offsets 0–15 force page
  1 and twelve indirect controls use the common reserved-field policy. Its
  defined status fields, address rules, and one-cycle timing are primary-
  verified; reserved bit 1 and pre-update-status ordering are CORROBORATED by
  the original SST page, later TI architecture prose/worked result, and
  pinned MAME under resolved `SC-008`/`OQ-003`. Exact
  `PUSH=0x7f9c` and `POP=0x7f9d` encodings, stack
  transformations, and one-word/two-cycle totals are primary-transcribed in
  the supported database and independent hand fixtures. Their external
  address/word-ownership sequence remains explicitly unresolved under
  `OQ-016`; the general every-cycle `MEN` constraint is primary-verified but
  does not supply that sequence. This
  model/tool support does not qualify RTL/native timing. Hand fixtures must
  not be generated by the assembler. Exact `CALA=0x7f8c`, its PC+1 stack
  push, `ACC[11:0]` target, one-word/two-cycle total, and model/tool boundary
  are primary-verified; its second external cycle remains `OQ-007`.
  `SUBH=0x62xx` adds 140 legal common-address words and primary-verified
  high-half subtraction, sticky OV, OVM endpoint saturation, and one-cycle
  behavior; `SC-016` records why ordinary/wrapped results preserve ACC low
  while OVM saturation replaces all 32 bits.
  `ADDH=0x60xx` adds 140 legal common-address words. Encoding, high-half
  modulo addition, low-half preservation, and one-cycle timing are primary-
  verified; original-part OV preservation and OVM independence are
  CORROBORATED under resolved `SC-017`/`OQ-011`, not silicon-verified.
  SUBC's
  encoding,
  addressing, and timing are primary-verified; its exact ACC availability
  after a forbidden dependency and exact OV-producing stage remain explicitly
  scoped by `OQ-017`/`OQ-018`. BANZ exact opcode `0xf400`, canonical
  following target word, two-cycle total, program-read sequence, old-counter
  condition, and low-nine-bit decrement are primary-verified; `SC-011` and
  `SC-012` preserve the later-guide state and MAME timing conflicts.
  B exact opcode `0xf900`, canonical following target word, unconditional
  two-cycle target load, and two normal program reads are primary-verified and
  independently corroborated by pinned MAME.
  Exact `BLZ=0xfa00`, `BLEZ=0xfb00`, `BGZ=0xfc00`, `BGEZ=0xfd00`,
  `BNZ=0xfe00`, and `BZ=0xff00` encodings, canonical target words, signed/zero
  predicates, and unconditional two-cycle totals are primary-verified.
  Exact `BV=0xf500`, canonical target word, OV predicate, taken-path OV clear,
  and unconditional two-cycle total are primary-verified; `SC-014` records
  MAME's shorter untaken timing.
  Exact `BIOZ=0xf600`, canonical target word, active-low raw pin predicate,
  non-latched second-sample ownership, and unconditional two-cycle total are
  primary-verified; `SC-015` records MAME's shorter untaken timing.
  Exact `CALL=0xf800`, canonical target word, opcode-PC+2 stack push,
  old-bottom discard, and two normal program reads are primary-verified and
  independently corroborated by pinned MAME.
  Exact `TBLR=0x67xx` and `TBLW=0x7dxx`, common address legality,
  ACC-derived program address, three-cycle total, discarded prefetch, table
  direction, final stack-bottom effect, and repeated following address are
  primary-verified.

## Milestone 5 — Executable reference model

### MODEL-001 — Independent architectural model

- **Status:** IMPLEMENTING
- **Priority:** P0
- **Dependencies:** ISA-001
- **Description:** Implement deterministic decode, state, memory spaces, I/O,
  interrupts, cycles, transactions, image loading, stepping, and trace output.
- **Acceptance criteria:** every supported opcode has directed behavior tests;
  arithmetic is width-explicit; unknown opcodes trap; traces support replay.
- **Documentation:** `sim/reference_models/README.md`
- **Tests:** `sim/unit/test_model_*.py`
- **Notes:** Independent model supports all sixty documented mnemonics: `ABS`, `ADD`, `ADDH`, `ADDS`, `AND`, `APAC`, `B`, `BANZ`, `BGEZ`, `BGZ`, `BIOZ`, `BLEZ`, `BLZ`, `BNZ`, `BV`, `BZ`, `CALA`, `CALL`, `DINT`, `DMOV`, `EINT`, `IN`, `LAC`, `LACK`,
  `LAR`, `LARK`, `LARP`, `LDP`, `LDPK`, `LST`, `LT`, `LTA`, `LTD`, `MAR`, `MPY`, `MPYK`, `NOP`, `OR`,
  `OUT`, `PAC`, `POP`, `PUSH`, `RET`, `TBLR`, `TBLW`,
  `ROVM`, `SACL`, `SACH`,
  `SAR`, `SOVM`, `SPAC`, `SST`, `XOR`, `ZAC`, `ZALH`, `ZALS`, `SUB`, `SUBC`, `SUBH`, and `SUBS`,
  raw program loading, logical program/data traces, reset-boundary effects,
  and deterministic replay. The twenty-six common-address data/table instructions plus SST
  cover
  direct/indirect reads or writes and nine-bit AR updates; `LAC` additionally
  covers sign extension and shifts, SACH covers output shifts 0/1/4, and the
  zero loads cover high-half placement and low-half zero extension. `LAR`
  loads either auxiliary register and suppresses post-modification only when
  its target is the selected address register. `SAR` stores either auxiliary
  register and, for a selected-source indirect update, writes the
  post-modification value at the old address. `MAR` implements direct NOP
  forms and indirect AR/ARP modification without a data-memory transaction;
  its two `LARP` aliases remain canonical LARP decodes. `LDP` loads DP from
  the selected word's LSB after resolving the old direct/indirect address and
  before normal indirect AR/ARP post-modification. `LT` loads all 16 selected
  word bits into T through the same address/update order. `LTA` combines that
  full-word T load with previous-P accumulation, sticky OV, and
  OVM-controlled wrap or signed-endpoint saturation. `LTD` adds the unchanged
  source-word copy to the next internal-RAM address, with distinct logical
  read/write transactions and provisional trap-before-effects for unresolved
  endpoints under `OQ-014`. `DMOV` performs only that unchanged-word copy,
  preserves ACC/T/P/arithmetic status, and applies the same address/update and
  endpoint policy. `MPY` produces a
  signed 16-by-16 P result through that same path and reproduces the
  documented `0x8000`-by-`0x8000` exception. `MPYK` multiplies T by a
  sign-extended 13-bit immediate without a data-memory transaction. `PAC`
  copies the complete P register into ACC without a data-memory transaction
  or status change. `APAC` adds the complete P value to ACC with signed
  overflow, sticky OV, and OVM-controlled wrap or endpoint saturation, also
  without a data-memory transaction. `SPAC` subtracts P from ACC with the
  same signed-overflow policy, P preservation, and program-only transaction
  boundary. Both multiply instructions now extend a pending interrupt through
  their following instruction, after which the model emits a non-instruction
  `INTERRUPT` dummy-fetch step. ADDS
  covers unsigned-source arithmetic, sticky OV, wrap, and positive saturation.
  ADD covers sign extension, shifts 0–15, sticky OV, wrap, and both
  positive/negative saturation endpoints. SUB covers the corresponding
  subtraction, shift, wrap, sticky-OV, and saturation cases.
  SUBH covers complete-word high-half alignment, ordinary/wrapped low-half
  retention, both signed-overflow directions, sticky OV, full-accumulator OVM
  endpoint saturation, and common direct/indirect address updates.
  SUBS covers unsigned-source subtraction, sticky OV, negative wrap, and
  negative saturation.
  ABS negates only negative ACC values, selects two's-complement wrap or
  positive saturation for the most-negative input through OVM, preserves OV
  and all unrelated state, and consumes one program-only cycle. The result,
  OVM selection, and timing are primary-verified; OV preservation is
  `CORROBORATED` under resolved `SC-007`/`OQ-013`.
  AND/OR/XOR cover low-half logic, their distinct upper-half behavior, and
  unchanged OV/OVM.
  DINT/EINT set and clear INTM in one program-only cycle while preserving the
  pending-request latch. The model samples active-low INT, retains masked
  pulses, implements EINT's previously-disabled following-instruction
  deferral, pushes the return PC on a dummy fetch, masks and clears the
  request, and selects vector 2. Its DINT-at-final-boundary cancellation is
  PROVISIONAL under `OQ-019`.
  `LST` reads one status word through the old DP/ARP, loads OV/OVM/ARP/DP,
  preserves INTM, and applies indirect counter updates to the old selected AR.
  Memory-sourced ARP precedence over an encoded next ARP is explicitly
  PROVISIONAL under `OQ-015`, supported by later TI and independent MAME
  evidence but not stated in the original-part manuals. `SUBC` implements
  both conditional subtract/divide paths and TI's 65/7 worked result with
  legally inserted ACC-free following instructions. Intermediate-subtraction
  sticky OV is provisional under `OQ-018`, and same-boundary ACC commit is
  not evidence for prohibited scheduling under `OQ-017`.
  `SST` exhausts all 32 combinations of the defined status fields, forces
  direct page 1, captures old ARP in the stored word before indirect
  post-update, and stores reserved bit 1 high at CORROBORATED confidence
  under resolved `OQ-003`/`SC-008`.
  `ADDH` covers ordinary and both high-half wrap directions under all four
  incoming OV/OVM combinations, always preserves ACC low and arithmetic
  status, and exercises direct/indirect address/update/trap behavior under
  the CORROBORATED `SC-017`/`OQ-011` resolution.
  `BANZ` fetches the canonical target from `PC+1`, tests the old selected
  low-nine AR counter, decrements it modulo 512 while preserving upper bits,
  selects target or `PC+2`, records both logical program transactions, and
  counts two cycles. Noncanonical target words trap before counter/PC effects.
  `B` uses the same two program reads and canonical-target trap policy,
  unconditionally loads PC at the second transaction, and preserves every
  other modeled architectural state item.
  The six accumulator branches test all signed/zero boundaries, select target
  or PC+2 after the mandatory second read, and preserve non-PC state.
  `BV` uses the same mandatory read, branches and clears set OV, falls through
  with clear OV unchanged, and preserves unrelated state.
  `BIOZ` uses inactive-high external input state, branches on a low level,
  records both mandatory reads, and preserves all architectural state but PC.
  `CALL` pushes wrapped opcode-PC+2 onto a top-first four-level stack, discards
  the old bottom, selects its canonical target, and records both reads.
  `CALA` pushes wrapped opcode-PC+1, discards the old stack bottom, selects
  `ACC[11:0]`, and counts two cycles. Directed tests cover upper-ACC
  exclusion, PC wrap, nested calls, state preservation, and the known opcode
  fetch; its unresolved second external cycle is omitted under `OQ-007`.
  `RET` loads PC from the old stack top, shifts all lower levels upward,
  duplicates the old bottom, and counts the primary-defined two cycles. Its
  logical transaction trace deliberately includes only the known opcode
  fetch because the second external cycle remains unresolved under `OQ-007`.
  A directed `EINT; RET` test proves RET completes before a pending request
  schedules reentry.
  `PUSH` copies ACC[11:0] onto the top-first stack and discards the old
  bottom; `POP` zero-extends the old top into ACC, shifts lower levels upward,
  and duplicates the old bottom. Directed tests cover PC wrap, preserved
  unrelated state, repeated over-push/over-pop behavior, and exact two-cycle
  totals. Their logical traces likewise omit the unresolved per-cycle
  program-address/word ownership under `OQ-016`; `SC-018` records that an
  independent FPGA implementation's idle first interval conflicts with TI's
  general every-cycle `MEN` rule.
  `IN` and `OUT` resolve the common internal-data address before updates,
  transfer all 16 bits between that word and one of eight distinct I/O ports,
  apply indirect AR/ARP controls at completion, record an opcode fetch plus
  second-cycle I/O and internal-data transactions, and count two cycles.
  `TBLR`/`TBLW` capture ACC and the old internal-data address, record opcode
  and discarded PC+1 reads plus the third-cycle table transfer, mutate RAM or
  program memory, duplicate old stack level 2 into the bottom, apply indirect
  updates at completion, and count three cycles.
  Out-of-range
  original-RAM addresses and unsupported words trap. Complete
  overlapped pipeline timing, RTL/native
  CALA/RET/PUSH/POP timing, and untested interrupt arrival combinations
  remain unimplemented.

## Milestone 6 — Assembler and test-program workflow

### TOOLS-001 — Assembler and disassembler

- **Status:** IMPLEMENTING
- **Priority:** P1
- **Dependencies:** ISA-001
- **Description:** Qualify a legal assembler or implement deterministic local
  assembly and database-driven disassembly.
- **Acceptance criteria:** all original mnemonics, labels, constants, comments,
  data, origin, includes, expressions, raw/hex/listing output, and diagnostics
  work; source-binary-disassembly-binary round trips match hand fixtures.
- **Documentation:** `tools/assembler/README.md`,
  `tools/disassembler/README.md`
- **Tests:** `tests/regressions/test_toolchain.py`
- **Notes:** Qualified slice supports the same sixty instructions as the
  model, labels, expressions, `.word`, `.org`, `.include`, raw/hex/listing
  output, lossless unknown-word disassembly, and round trips. `LAC` and `SACL`
  support checked direct and indirect TI syntax, including SACL's required
  zero placeholder before a next ARP, SACH's sparse 0/1/4 shifts, and
  ADD/LAC/SUB common address syntax with shifts, `LAR`/`SAR` target-register
  syntax, MAR direct/indirect syntax and LARP aliases, and
  ADDH/ADDS/AND/DMOV/LDP/LST/LT/LTA/LTD/MPY/OR/SST/SUBC/SUBH/SUBS/TBLR/TBLW/XOR/ZALH/ZALS syntax without a shift operand,
  checked `IN`/`OUT` data-address plus numeric or PA0–PA7 port syntax,
  plus the complete signed 13-bit MPYK immediate range and implied
  ABS/PAC/APAC/SPAC/CALA/DINT/EINT/POP/PUSH/RET and two-word
  `B`/`BANZ`/`BIOZ`/`BV`/`CALL`/accumulator-branch targets.
  Branch-aware location accounting, label resolution, listing output,
  diagnostics, and source-binary-disassembly-binary round trips are
  directed-tested. The checked synthetic
  `tests/asm/push_pop_bus_probe.asm` image provides a reproducible,
  noncopyrighted original-device pin-trace fixture for `OQ-016`. SST
  additionally enforces direct offsets 0–15 while
  retaining common indirect syntax and lossless noncanonical aliases. A surviving
  binary tool may be cataloged but never executed outside isolation.

## Milestone 7 — RTL datapath

### RTL-001 — Width-accurate datapath primitives

- **Status:** IMPLEMENTING
- **Priority:** P0
- **Dependencies:** ARCH-001, MODEL-001
- **Description:** Implement accumulator, ALU, multiplier, shifters, auxiliary
  registers, status, stack, and internal RAM using portable RTL.
- **Acceptance criteria:** exhaustive feasible arithmetic and boundary-focused
  simulation/formal tests pass; lint and Yosys synthesis are clean.
- **Documentation:** `docs/architecture/tms32010_architecture.md`
- **Tests:** `sim/unit/tb_*`, `formal/datapath/`
- **Notes:** Initial 32-bit accumulator, 16-bit T register, 32-bit P register,
  two 16-bit ARs,
  ARP, DP, OV/OVM, and 144-word internal RAM exist for the
  fifty-six-instruction slice. `ABS` verifies zero, positive, ordinary
  negative, and most-negative accumulator values under both OVM modes while
  preserving incoming OV. `LAC`
  verifies sign extension and left shifts; `SACH` verifies its output-shifter
  cross-half behavior; `ZALH`/`ZALS` verify accumulator half placement; all
  twenty-six common-address data instructions plus SST verify direct/indirect read/write
  addressing and low-nine-bit AR updates. `LAR` additionally verifies that an
  indirect load into the selected address register suppresses its otherwise
  requested post-modification. `SAR` verifies the distinct same-source rule:
  it stores the post-modification value at the pre-modification address.
  `MAR` verifies low-nine-bit AR update and ARP replacement without touching
  the RAM datapath.
  SST verifies forced page-one direct addressing, exact packed status data,
  reserved bit 1, and pre-update-status/post-update-AR ordering.
  `LDP` verifies old-DP/old-AR address selection and source-bit transfer into
  DP before the common indirect post-update.
  `LT` verifies full-word transfer into T through the same old-address and
  post-update ordering.
  `LTA` combines that transfer with previous-P accumulation, sticky OV, and
  OVM-controlled wrap/saturation without changing P.
  `LTD` adds a simultaneous unchanged-word copy to the following RAM address;
  distinct source/write addresses, page crossing, and unresolved-destination
  trap-before-effects are verified.
  `DMOV` reuses the dual-address RAM path without LTD's T/ACC effects;
  source and unrelated-state preservation, page crossing, indirect
  post-update, and unresolved-destination trapping are verified.
  `MPY` verifies signed products, the original most-negative exception, and
  P replacement through the same old-address/post-update order. Its
  combinational portable multiplier infers one Cyclone V DSP block in the
  current Quartus harness. `MPYK` reuses that portable datapath with a
  sign-extended 13-bit immediate and no RAM transaction. `PAC` transfers all
  32 P bits into ACC without changing P or arithmetic status. `APAC` adds P
  to ACC with signed overflow, sticky OV, and OVM-controlled saturation.
  `SPAC` subtracts P from ACC with the same status and result policy.
  ADDS additionally verifies sticky
  overflow, OVM-clear wrap, and OVM-set positive saturation. AND/OR/XOR verify
  low-half logic, AND upper clearing, OR/XOR upper preservation, and unchanged
  overflow state. ADD and SUB verify signed shifting, general signed overflow,
  wrap, and both saturation endpoints for their respective arithmetic.
  SUBS verifies zero-extended subtraction, negative wrap/saturation, and
  sticky OV.
  ADDH verifies modulo high-half addition, unconditional ACC-low/OV/OVM
  preservation for both signed wrap directions, and the common address path;
  the status policy remains CORROBORATED under `SC-017`/`OQ-011`.
  IN writes a live external 16-bit port word into RAM and OUT reads a RAM word
  for external drive through the same old-address/post-update path; both keep
  the I/O space distinct from the internal data transaction.
  SUBC verifies unsigned operand alignment, both conditional result paths, and
  the 16-step 65/7 divide. The intermediate-subtraction OV stage remains
  provisional under `OQ-018` and ignores OVM as TI documents.
  Physical reset
  preserves OVM as documented and assigns no arbitrary value to
  ACC/T/P/AR/ARP/DP/OV or RAM; retention of unlisted FPGA state remains
  provisional under OQ-012. ALU, multiplier, other output-shifter consumers,
  remaining stack operations and remaining status behavior remain. The CALL
  path implements and exposes all four 12-bit stack levels, including
  nested pushes and old-bottom discard.
  The asynchronous RAM read is a provisional implementation boundary and
  synthesizes to registers, not block RAM.

## Milestone 8 — RTL program sequencer

### RTL-002 — Fetch/decode/execute sequencer

- **Status:** IMPLEMENTING
- **Priority:** P0
- **Dependencies:** RTL-001, ISA-001
- **Description:** Implement documented phases, pipeline overlap, control flow,
  stalls, and architectural commit boundaries.
- **Acceptance criteria:** state-transition assertions and per-instruction
  cycle tests pass without gated clocks or combinational cycles.
- **Documentation:** `docs/architecture/pipeline.md`
- **Tests:** `sim/bus/tb_phase_slice_integration.sv`,
  `sim/bus/tb_sequential_pipeline_slice.sv`,
  `sim/bus/tb_sequential_pipeline_b.sv`,
  `sim/bus/tb_sequential_pipeline_banz.sv`,
  `sim/bus/tb_sequential_pipeline_accumulator_branches.sv`,
  `sim/bus/tb_sequential_pipeline_bv.sv`,
  `sim/bus/tb_sequential_pipeline_bioz.sv`,
  `sim/bus/tb_sequential_pipeline_call.sv`,
  `sim/bus/tb_sequential_pipeline_io.sv`,
  `sim/bus/tb_sequential_pipeline_table.sv`,
  `sim/interrupt/tb_sequential_pipeline_interrupt.sv`,
  `sim/interrupt/tb_sequential_pipeline_interrupt_multiply.sv`,
  `sim/interrupt/tb_sequential_pipeline_interrupt_multicycle.sv`,
  `sim/bus/tb_sequential_pipeline_differential.sv`,
  `sim/unit/tb_fetch_execute.sv`, `sim/instruction/tb_sequencer.sv`,
  `formal/sequencer/`
- **Notes:** Temporary clock-enable execution and
  trap-without-PC-advance are verified. The sequential phase wrapper now
  retires each of 41 supported one-cycle instructions, including all
  twenty-five internal-data operations, on its falling-edge sample. B, BANZ,
  BIOZ, BV, CALL, and six accumulator branches share the first two-cycle state:
  opcode and following target receive
  separate normal program reads, retirement occurs only on the target-word
  sample, and next-address selection aligns PC with the native bus across
  stalls. CALL additionally pushes opcode-PC+2 only at target-word retirement.
  IN/OUT use a separate pending state after the opcode sample: the next
  enabled falling boundary completes a DEN read or WE write, commits the
  internal RAM effect and indirect AR/ARP update, advances PC, and retires.
  Program MEN is suppressed throughout that I/O cycle.
  The legacy wrapper gives TBLR/TBLW a three-cycle pending state and preserves
  the discarded PC+1, table transfer, and repeated PC+1 bus order. Its
  retirement remains attached to the table sample. The explicit wrapper
  instead retains the table opcode through all three Figure 2-10 execution
  intervals and commits RAM, indirect AR/ARP, documented stack-bottom, and
  retirement effects only at the repeated-prefetch boundary.
  Interrupt control now includes active-low request latching, one-instruction
  pipeline deferral, MPY/MPYK extension, a non-retiring return-PC dummy read,
  stack entry, mask/flag acknowledge effects, and vector-2 selection.
  Complete fetch/execute overlap still does not exist; the narrow explicit
  ownership slice now includes the basic Figure 2-12 interrupt path and the
  MPY/MPYK protected-slot extension and is described below. A four-case native
  test now
  asserts falling-boundary request ownership from each modeled subphase,
  including a stalled pre-sample phase, while leaving physical setup/CDC
  behavior unclaimed. Matching 32-case core and explicit matrices exhaust
  arrival at every
  represented machine cycle of the 11 supported two-word control-flow
  families, IN, OUT, TBLR, and TBLW. SUBC tests use a
  following NOP; the exact prohibited same-ACC dependency remains `OQ-017`.
  PUSH/POP stack state is
  primary-specified, but a two-cycle RTL state is intentionally deferred
  rather than assigning an unsupported program-address/fetched-word sequence
  under `OQ-016`. TI does require active `MEN` in both non-I/O cycles;
  `SC-018` explains why that fact alone cannot select repeated versus
  advancing prefetch ownership.
  ADR-0002 now fixes the integration direction: fetched word/address validity
  must be separate from the execute slot, operand/dummy reads must be invalid,
  and redirects must flush rather than execute a convenient placeholder. The
  standalone synthesizable `tms32010_fetch_execute` block passes priming,
  sequential replacement, stall, multicycle-retention, branch-flush,
  interrupt-dummy/vector, and recognized-reset tests plus independent Yosys
  synthesis. The separate `tms32010_sequential_pipeline_slice` now connects
  it to the core for reset priming, decoded one-cycle operation families, and
  exact B, BANZ, BV, BIOZ, CALL, and the six accumulator-conditional
  branches, plus exact IN/OUT and TBLR/TBLW execution ownership. All branches retain
  execute ownership across a nonexecutable PC+1 operand
  fetch and the selected target/fallthrough-instruction fetch, retire only as
  that instruction enters the execute slot, and cannot apply its effects until
  the following fetch interval. BANZ selects from the old selected `AR[8:0]` and
  defers its modulo-512 decrement until branch retirement. The accumulator
  family tests every predicate in both directions with zero, positive, or
  negative ACC,
  stalls taken and untaken selected fetches, preserves ACC, and defers the
  selected instruction's effect. Directed tests also cover conservative
  malformed-operand parking. BV tests both old-OV outcomes, keeps set OV
  unchanged through operand and selected-fetch stalls, clears it only at
  taken retirement, and leaves a malformed taken-path operand parked with OV
  set. BIOZ tests both raw pin levels, changes BIO from its opcode-prefetch
  level while the operand is stalled, samples the final active-low level at
  operand completion, then reverses the pin while proving the chosen cycle-2
  fetch and retained decision stay stable. CALL preserves all non-stack state,
  defers opcode-PC+2 push until selected-target capture, and shifts nested
  return addresses correctly. These combined interval mappings are INFERRED
  from Figure 2-2, Table 3-2, and the instruction pages because no dedicated
  branch/call pin waveform has been located.
  IN/OUT follow the dedicated primary Figure 2-9 mapping: transfer cycle 1
  suppresses MEN, multiplexes the zero-extended port address, and asserts
  only DEN or WE; following-prefetch cycle 2 suppresses I/O strobes and reads
  PC+1 under MEN. The execute slot retires and captures PC+1 only at the
  second boundary. Directed tests stall both intervals, sample changed live
  IN data, hold OUT data, prove no early RAM/AR/ARP or following-word effect,
  enforce native-strobe exclusivity, and park invalid addresses before any
  transaction.
  TBLR/TBLW keep the execute slot through the nonexecutable discarded PC+1
  MEN read, ACC-addressed MEN/WE transfer, and repeated PC+1 MEN read. The
  explicit program-write direction/data outputs distinguish TBLW from OUT.
  Directed stalls prove no early state change, and a self-modifying TBLW
  proves that only the rewritten repeated word is captured and executed.
  The sequential directed test proves first-fetch nonretirement, distinct
  fetch/execute addresses, phase stalls, sequential replacement, visible
  parking on an unsupported control word, and reset recovery. An offset differential
  runs the full existing 46-word/41-family one-cycle program and compares PC,
  ACC, T, P, both ARs, ARP, DP, all stack levels, OV/OVM/INTM, cycle count,
  and illegal state after every pipelined retirement. Figure 2-12's basic
  EINT/protected/dummy/vector path now has explicit ownership with stalls and
  deferred vector execution.

## Milestone 9 — Program-memory interface

### BUS-001 — Native program transactions

- **Status:** IMPLEMENTING
- **Priority:** P0
- **Dependencies:** RTL-002, ARCH-001
- **Description:** Reproduce instruction, immediate, branch, and table/program
  memory access sequences.
- **Acceptance criteria:** phase, address, strobe, data, overlap, and stall
  traces match primary timing figures for every access case.
- **Documentation:** `docs/architecture/external_interface.md`,
  `docs/timing/bus_cycles.md`
- **Tests:** `sim/bus/tb_program_bus_phase.sv`,
  `sim/bus/tb_phase_slice_integration.sv`,
  `sim/bus/tb_table_transfer_phase.sv`,
  `sim/bus/tb_sequential_pipeline_table.sv`
- **Notes:** Appendix A normal read and table-transfer pin waveforms are
  transcribed. The four-subphase normal-read/reset engine verifies
  falling-edge sampling, quarter-cycle MEN assertion, address stability, and
  release delay. The legacy partial wrapper integrates those phases with all 38
  supported one-cycle instructions plus both cycles of eleven qualified
  control-flow instructions, checks that internal logical data
  activity retains a normal external program read, and holds PC/address on
  traps and stalls. Every legacy-qualified control-flow path verifies
  opcode/target addresses and target-read stalls; conditional branches cover
  both outcomes, but those tests do not establish separate execute ownership.
  The explicit pipeline now covers exact B/BANZ/BV/BIOZ/CALL and all six
  accumulator-branch operand and selected target/fallthrough fetches,
  including stalls, both BANZ conditions, every ACC predicate outcome,
  retirement-only BV clear, live active-low BIOZ sampling, retained BIOZ
  decision after operand completion, deferred counter mutation, and no early
  fetched-instruction execution. CALL also verifies no early push, selected-
  target retirement, nested stack shifting, and non-stack state preservation.
  IN/OUT additionally retain execute ownership through Figure 2-9's distinct
  transfer and following-prefetch intervals, including independent stalls,
  mutually exclusive DEN/WE then MEN, sampled/held data, retirement-only
  state commit, and fetched-word effect deferral. TBLR/TBLW additionally
  retain explicit execute ownership across the discarded MEN read, captured
  ACC-addressed MEN/WE transfer, and repeated PC+1 MEN read. Tests cover
  independent stalls, RAM/program-write data, deferred AR/ARP/stack/retirement
  commit, and a self-modifying TBLW whose rewritten word is the only one
  captured. Interrupt testing adds Figure 2-12's
  protected instruction, return-PC dummy read, and vector-2 read. Matching
  32-case logical-core and explicit-pipeline matrices test each represented
  multicycle arrival boundary;
  a separate four-case native test checks digital falling-boundary ownership
  from every modeled subphase. Physical setup/synchronizer behavior remains
  unresolved. Remaining
  indirect-call/return,
  unsupported CALA/RET/PUSH/POP interrupt ownership,
  cycles
  remain. Do not collapse Harvard
  spaces in the native interface.

## Milestone 10 — Data-memory interface

### BUS-002 — Internal data transactions

- **Status:** IMPLEMENTING
- **Priority:** P0
- **Dependencies:** RTL-002, ARCH-001
- **Description:** Implement internal RAM mapping and verification-visible
  logical data reads/writes, including conflicts and indirect addressing.
- **Acceptance criteria:** address selection, read/write ordering, stalls, and
  internal/external boundaries pass directed and randomized bus tests.
- **Documentation:** `docs/architecture/memory_model.md`
- **Tests:** `sim/bus/tb_data_bus.sv`
- **Notes:** Primary documentation establishes that ordinary operands are
  wholly internal; external storage moves through table or I/O instructions.
  `ADD`/`ADDS`/`AND`/`DMOV`/`LAC`/`LAR`/`LDP`/`LST`/`LT`/`LTA`/`LTD`/`MPY`/`OR`/`SACL`/`SACH`/`SAR`/`SUB`/`SUBC`/`SUBS`/
  `XOR`/`ZALH`/`ZALS` model/RTL tests cover valid address selection, logical
  read/write traces, ordering, and explicitly trap unresolved `0x90`–`0xff`.
  The portable RTL contains exactly 144 words and a nonarchitectural preload
  port. Directed tests read back every store class; seeded differential
  compares all 144 final words. Remaining instruction interactions remain.
  MPYK separately verifies that its immediate multiply performs no logical
  data-memory transaction. PAC separately verifies that its internal P-to-ACC
  transfer performs no logical data-memory transaction. APAC verifies the same
  program-only boundary for its internal P-plus-ACC arithmetic. SPAC verifies
  it for internal ACC-minus-P arithmetic.
  Variant RAM sizes must not leak into the TMS32010 default.

## Milestone 11 — I/O interface

### BUS-003 — Native I/O-space transactions

- **Status:** COMPLETE
- **Priority:** P0
- **Dependencies:** RTL-002, ARCH-001
- **Description:** Implement documented I/O address, data, strobes, and
  cycle behavior separately from program and data spaces.
- **Acceptance criteria:** all IN/OUT timing, data-direction, address, and
  clock-enable-stall cases match automated primary-sourced traces.
- **Documentation:** `docs/architecture/external_interface.md`
- **Tests:** `sim/bus/tb_io_phase.sv`,
  `sim/bus/tb_sequential_pipeline_io.sv`,
  `sim/instruction/tb_io_rtl.sv`,
  `sim/unit/test_model_io.py`,
  `sim/differential/test_model_rtl_slice.py`
- **Notes:** IN/OUT each perform one normal MEN opcode cycle followed by one
  port cycle with A11–A3 low and A2–A0 equal to the encoded port. IN asserts
  DEN, samples the live external word at falling CLKOUT, and stores it into
  the old resolved internal-RAM address. OUT asserts WE and holds the old
  resolved RAM word as write data. Directed tests cover all bus-strobe
  exclusions, direct/indirect ordering, AR/ARP commit, stable active phases,
  two-cycle retirement, traps, and model/RTL transaction agreement. Explicit
  pipeline testing retains the executing word through the port transfer and
  PC+1 prefetch, stalls each interval, and proves that the following word
  cannot execute before IN/OUT retirement. The
  original 40-pin part has no READY input; clock-enable holding is a wrapper
  adaptation and not a claimed native wait protocol. Hard Drivin' mappings
  belong in an integration wrapper.

## Milestone 12 — Reset and initialization behavior

### CTRL-001 — Evidence-backed reset

- **Status:** IMPLEMENTING
- **Priority:** P0
- **Dependencies:** ARCH-001, RTL-002, BUS-001
- **Description:** Implement assertion/release, duration, initial architectural
  state, bus outputs, vector, mask, and first-fetch timing.
- **Acceptance criteria:** reset tests cover every documented state and preserve
  documented unknowns; assertions show no unintended unknown control state.
- **Documentation:** `docs/architecture/tms32010_architecture.md`
- **Tests:** `sim/bus/tb_program_bus_phase.sv`, `sim/unit/tb_reset.sv`,
  `formal/reset/`
- **Notes:** Appendix A verifies five-machine-cycle minimum assertion,
  synchronized response, inactive strobes/high-Z data, PC/address clear after
  the next full cycle, and first address-0 read one full cycle after release.
  The standalone phase test covers these external reset phases; architectural
  state/pipeline integration and formal reset properties remain.
  FPGA-deterministic behavior, if any, must be separately labeled.

## Milestone 13 — Interrupt behavior

### CTRL-002 — Interrupt and BIO behavior

- **Status:** IMPLEMENTING
- **Priority:** P0
- **Dependencies:** CTRL-001, RTL-002
- **Description:** Implement interrupt recognition, masking, acknowledge,
  latency, priority, return behavior, BIO sampling, and pipeline interaction.
- **Acceptance criteria:** every recognition boundary and latency case has an
  automated cycle/bus assertion; deferred/ignored cases are verified.
- **Documentation:** `docs/architecture/interrupts.md`
- **Tests:** `sim/interrupt/tb_interrupt_mask.sv`,
  `sim/interrupt/tb_interrupt_entry.sv`,
  `sim/interrupt/tb_interrupt_multicycle_arrivals.sv`,
  `sim/interrupt/tb_interrupt_native_sampling.sv`,
  `sim/interrupt/tb_interrupt_phase.sv`,
  `sim/interrupt/tb_sequential_pipeline_interrupt.sv`,
  `sim/interrupt/tb_sequential_pipeline_interrupt_multiply.sv`,
  `sim/differential/test_interrupt_model_rtl.py`,
  `sim/instruction/tb_bioz_rtl.sv`
- **Notes:** Primary sources establish an internally latched request from a
  high-to-low transition or low level, mask persistence, exact
  `DINT=0x7f81`/`EINT=0x7f82` words, one-cycle INTM effects, and EINT's
  following-instruction service deferral. Database/model/tool/RTL, directed
  mask tests, native-phase tests, and seeded differential now qualify the
  mask-state subset. Exact BIOZ decode/model/tool/RTL/native/differential
  tests qualify a raw active-low BIO input, live second-falling-edge
  predicate ownership, and both two-cycle paths. INT now has directed
  model/RTL/native/differential evidence for masked pulse retention, held-low
  relatching, EINT and MPY/MPYK deferral, multicycle completion, dummy return
  fetch, stack push, internal acknowledge effects, and vector-2 selection.
  Matching 32-case directed core and explicit-pipeline matrices now cover
  active-low arrival at both
  machine-cycle boundaries of all eleven supported two-word control-flow
  families and IN/OUT, plus all three boundaries of TBLR/TBLW. Each case
  asserts the family-specific logical/native bus shape, no midinstruction entry,
  exactly one protected retirement, the resolved-return-PC dummy fetch, stack
  state, acknowledge effects, and vector-2 selection.
  The model also verifies that EINT protects a following RET long enough to
  pop/select the saved PC before an already-pending request schedules reentry.
  Figure 2-12's basic explicit path now discards N+2, performs entry with an
  empty execute slot, captures vector 2 without executing it, and defers the
  vector effect through independently stalled reads. MPY and MPYK in that
  protected slot now explicitly extend service through one more instruction;
  directed checks cover signed results, internal-read versus program-only bus
  shape, stalls, dummy discard, return-PC ownership, and vector deferral.
  Physical setup/synchronizer behavior, unsupported CALA/RET/PUSH/POP
  arrival cycles, RTL/native RET behavior, and provisional DINT cancellation
  remain under `OQ-004`/`OQ-007`/`OQ-016`/`OQ-019`; no complete
  interrupt-cycle claim is made.

## Milestone 14 — Every instruction family

### ISA-002 — Instruction-family implementation

- **Status:** IMPLEMENTING
- **Priority:** P0
- **Dependencies:** MODEL-001, RTL-001, RTL-002, BUS-001, BUS-002, BUS-003
- **Description:** Research, model, implement, and verify arithmetic, logic,
  multiply/MAC, shifts, load/store, indirect, auxiliary, branch/call, stack,
  repeat, status, I/O, interrupt-control, table/special, and reserved groups.
- **Acceptance criteria:** definition of instruction-complete in `AGENTS.md` is
  met for every family and full regression passes.
- **Documentation:** `docs/architecture/instruction_set.md`
- **Tests:** `sim/instruction/test_*`, `tests/asm/instruction_*`
- **Notes:** First control/immediate slice (`LACK`, `NOP`, `ZAC`, `ROVM`,
  `SOVM`) passes model, RTL, toolchain, and differential tests. `DINT` and
  `EINT` now pass exact-opcode fixtures, model/tool/RTL state effects,
  one-cycle/program-only/clock-enable checks, native-phase retirement, and
  seeded INTM differential comparison. Interrupt recognition, EINT's
  following-instruction service deferral, Figure 2-12 external read order,
  and every represented supported-multicycle arrival position now pass
  directed checks under `CTRL-002`; complete execute-overlap and
  physical setup/synchronizer behavior remain open under `OQ-004`.
  `LST` now passes primary-cited database/tool support, exhaustive model
  status-field tests, directed RTL address/order/cycle/stall/trap checks,
  native-phase retirement, and seeded differential comparison. Original
  manuals leave the indirect next-ARP precedence unstated, so memory-word ARP
  precedence remains PROVISIONAL under `OQ-015`/`SC-009`.
  `SST` now passes primary-cited database/tool support, exhaustive 32-state
  model packing tests, directed RTL page-one/address/update/cycle tests,
  native-phase and explicit-pipeline retirement, and seeded differential RAM/
  transaction comparison. Reserved bit 1 and pre-update capture ordering are
  CORROBORATED under resolved `OQ-003`/`SC-008`, not hardware-verified.
  `BANZ` now passes primary-cited exact encoding/database/tool support,
  directed model and RTL state/timing/trap tests, two-read native-phase
  taken/untaken and stall tests, and an instruction-boundary-model versus
  per-cycle-RTL differential trace. The upper-seven-bit decrement conflict
  and MAME untaken timing abstraction remain disclosed as `SC-011`/`SC-012`;
  neither changes the primary-backed behavior.
  `B` now passes exact encoding/database/tool support, directed model and RTL
  state/timing/trap tests, two-read native-phase and target-stall tests, and a
  focused instruction-boundary-model versus per-cycle-RTL differential trace.
  `BGEZ`/`BGZ`/`BLEZ`/`BLZ`/`BNZ`/`BZ` now pass the same path with signed/zero
  boundary matrices and both outcomes for every mnemonic. `SC-013` preserves
  MAME's untaken timing disagreement without changing TI-backed behavior.
  `BV` passes exact decode/tool/model/RTL/native/differential checks for both
  OV states, including taken-target OV clear, target stall, and
  trap-before-clear. `SC-014` preserves MAME's untaken timing disagreement.
  `BIOZ` passes exact decode/tool/model/RTL/native/differential checks for
  both raw pin levels. Pin transitions between opcode and target samples
  prove live second-sample ownership; `SC-015` preserves MAME's untaken
  timing disagreement.
  `CALL` passes exact decode/tool/model/RTL/native/differential checks for
  canonical target fetch, opcode-PC+2 push, five nested calls against the
  four-level stack, old-bottom discard, target stall, 12-bit return-address
  wrap, state preservation, and malformed-target trap-before-push. The
  explicit-pipeline test additionally proves nonexecutable operand ownership,
  selected-target capture before retirement, no push through either stall,
  nested stack shifting, and deferred target effects. The combined
  execute-interval mapping remains INFERRED. `LAC`
  now passes primary-cited database/model/tool tests, directed RTL cycle and
  addressing tests, native phase integration, and seeded logical-data
  differential traces. `SACL` now passes the equivalent primary-cited
  database/model/tool/RTL/cycle/write-transaction path, including full final
  RAM comparison. `SACH` now passes the same path plus all three
  primary-documented output shifts and rejects all other shift field values.
  `ZALH` and `ZALS` now pass the same primary-cited database/model/tool/RTL,
  one-cycle, native-phase, and differential path; tests distinguish high-half
  transfer from unsigned low-half zero extension. `ADDS` now passes
  primary-cited database/model/tool/RTL, one-cycle, native-phase, randomized
  differential, unsigned-source, sticky-OV, wrap, and saturation tests.
  `AND`, `OR`, and `XOR` now pass primary-cited database/model/tool/RTL,
  one-cycle, native-phase, and randomized differential tests, including their
  distinct accumulator upper-half effects and unchanged OV/OVM.
  `ADD` now passes primary-cited database/model/tool/RTL, one-cycle,
  native-phase, and randomized differential tests, including signed shifts,
  sticky OV, wrap, and both OVM saturation endpoints.
  `SUB` now passes the same primary-cited qualification path, including TI's
  worked subtraction example, signed shifts, sticky OV, both wrap directions,
  and both OVM saturation endpoints.
  `SUBS` now passes primary-cited database/model/tool/RTL, one-cycle,
  native-phase, and randomized differential tests, including TI's unsigned
  worked example, sticky OV, negative wrap/saturation, and the unreachable
  positive-overflow boundary.
  `SUBC` now passes primary-cited database/model/tool/RTL, one-cycle,
  native-phase, seeded-random differential, common-address, and hand-fixture
  tests for both conditional paths and TI's 16-step 65/7 divide. The
  differential adds 16 legal direct/indirect SUBC/NOP pairs; all program tests
  obey the documented ACC-free following instruction. Same-boundary ACC commit
  and intermediate-subtraction sticky OV remain explicitly PROVISIONAL under
  `OQ-017`/`OQ-018`.
  `LAR` now passes primary-cited database/model/tool/RTL, one-cycle,
  native-phase, and randomized differential tests, including its documented
  suppression of indirect post-modification when the target is the selected
  address register and normal modification when the other register is loaded.
  `SAR` now passes the same qualification path, including TI's special
  same-source ordering that stores the post-modification AR value at the old
  indirect address, normal other-source modification, and full-width stores.
  `MAR` now passes primary-cited database/model/tool/RTL, one-cycle,
  native-phase, and randomized differential tests for direct NOP behavior,
  indirect AR/ARP updates, no data-memory transaction, and its exact LARP
  aliases.
  `LDP` now passes primary-cited database/model/tool/RTL, one-cycle,
  native-phase, and randomized differential tests for source-LSB transfer,
  old-DP/old-AR address selection, and common indirect post-modification.
  `LT` now passes the same qualification path for full-width T loads, old
  direct/indirect address selection, and common indirect post-modification.
  `LTA` now passes primary-cited database/model/tool/RTL, one-cycle,
  native-phase, and randomized differential tests for simultaneous full-word
  T loading and previous-P accumulation, both overflow directions, OVM
  wrap/saturation, sticky OV, unchanged P, old-address/post-update ordering,
  and trap-before-effects behavior. The generic sequencer now recognizes its
  retirement as a possible multiply-following interrupt boundary; exhaustive
  arrival combinations remain under `CTRL-002`.
  `LTD` now passes the same qualification path for its simultaneous source
  load to T, previous-P accumulation, and unchanged source copy to the next
  internal-RAM address. Directed and differential tests compare distinct
  source/write addresses, page crossing, both overflow/OVM result directions,
  common indirect post-update, and provisional trap-before-effects when the
  destination is unresolved under `OQ-014`.
  `DMOV` now passes the same primary-cited database/model/tool/RTL,
  one-cycle, native-phase, and randomized differential path for the copy-only
  subset: unchanged source, distinct next-address write, ACC/T/P/status
  preservation, page crossing, common indirect post-update, and provisional
  trap-before-effects at an unresolved destination under `OQ-014`.
  `MPY` now passes functional database/model/tool/RTL, one-cycle,
  native-phase, and randomized differential tests for signed P results,
  including TI's most-negative multiplier exception. Its documented
  one-following-instruction interrupt deferral shares the now-directed-tested
  MPY/MPYK sequencer path.
  `MPYK` now passes primary-cited database/model/tool/RTL, one-cycle,
  native-phase, and randomized differential tests for complete signed 13-bit
  immediate decoding, signed P results, state preservation, and no
  data-memory transaction. Directed interrupt tests place MPYK in a protected
  slot, execute one further instruction, then verify dummy entry and vector 2.
  `PAC` now passes primary-cited database/model/tool/RTL, one-cycle,
  native-phase, and randomized differential tests for full-width P-to-ACC
  transfer, P/T/status preservation, and no data-memory transaction. A PAC
  following MPY/MPYK uses the generic recognized retirement boundary, though
  PAC-specific interrupt arrival combinations remain under `CTRL-002`.
  `APAC` now passes primary-cited database/model/tool/RTL, one-cycle,
  native-phase, and randomized differential tests for exact `0x7f8f` decode,
  full-width P-plus-ACC results, sticky OV, both signed-overflow directions,
  OVM-clear wrap, OVM-set endpoint saturation, P/T/address preservation, and
  no data-memory transaction. Its retirement can end generic multiply
  deferral; APAC-specific interrupt arrivals remain future coverage.
  `SPAC` now passes primary-cited database/model/tool/RTL, one-cycle,
  native-phase, and randomized differential tests for exact `0x7f90` decode,
  full-width ACC-minus-P results, sticky OV, both signed-overflow directions,
  OVM-clear wrap, OVM-set endpoint saturation, P/T/address preservation, and
  no data-memory transaction. Its retirement can end generic multiply
  deferral; SPAC-specific interrupt arrivals remain future coverage.
  `RET` now passes primary-cited exact decode, hand fixture, assembler/
  disassembler, and directed model tests for its old-TOS PC load, four-level
  pop with old-bottom duplication, two-cycle total, state preservation, and
  protected execution after EINT before pending interrupt reentry. The model
  intentionally omits the unknown second external transaction; RTL/native and
  differential support remain deferred under `OQ-007`.
  `CALA` now passes primary-cited exact decode, independent hand fixture,
  assembler/disassembler, and directed model tests for its opcode-PC+1 stack
  push, `ACC[11:0]` target, upper-ACC exclusion, PC wrap, nested old-bottom
  loss, state preservation, and two-cycle total. Its model trace intentionally
  omits the unknown second external transaction; RTL/native and differential
  support remain deferred under `OQ-007`.
  `PUSH` and `POP` now pass primary-cited exact decode, independent hand
  fixtures, assembler/disassembler, and directed model tests for low-12-bit
  push, zero-extending pop, full four-level shifts, old-bottom
  discard/duplication, PC wrap, state preservation, repeated
  overflow/underflow, and two-cycle totals. Their model traces intentionally
  omit the unknown per-cycle program-address/word ownership; RTL/native and
  differential support remain deferred under `OQ-016`. The every-cycle `MEN`
  constraint is VERIFIED_PRIMARY, while `SC-018` records the conflict with an
  independent implementation's idle first microcycle. A stable synthetic
  program and original-device capture procedure now define the evidence
  needed to resolve it.
  `SUBH` now passes primary-cited common-address decode/fixture/tool support,
  TI-example and boundary model/RTL tests, one-cycle native retirement, and
  seeded differential coverage. Tests distinguish ordinary/wrapped low-half
  preservation from full-accumulator OVM saturation, cover both overflow
  directions and sticky OV, and exercise direct/indirect address ordering.
  The apparent wording tension is resolved and recorded as `SC-016`.
  `ABS` now passes exact-decode, hand-fixture, model/tool/RTL, one-cycle native,
  OV-preservation, OVM-boundary, seeded differential, and pipeline-stream
  tests. Its original-part OV preservation is `CORROBORATED`; result and
  timing are `VERIFIED_PRIMARY` under resolved `SC-007`/`OQ-013`. `ADDH`
  now passes primary-cited decode/fixture/tool/model/RTL, one-cycle native,
  pipeline-offset, and seeded differential tests. Its high-half modulo result
  and low-half preservation are primary-verified; OV preservation and OVM
  independence remain CORROBORATED under resolved `SC-017`/`OQ-011`. Four
  model-qualified single-word/two-cycle stack/control instructions remain
  outside RTL/native qualification until their external second cycles are
  resolved. Maintain one subtask per timing family when implementation begins.

## Milestone 15 — Pipeline and cycle timing

### TIMING-001 — Complete timing matrix

- **Status:** RESEARCHING
- **Priority:** P0
- **Dependencies:** ISA-002, RTL-002
- **Description:** Map every instruction/addressing case to documented cycles,
  overlap, conflicts, branches, repeats, and transactions.
- **Acceptance criteria:** every timing-matrix row has an automated assertion
  and citation; no hidden discrepancy remains.
- **Documentation:** `docs/timing/instruction_cycles.md`
- **Tests:** `sim/instruction/test_cycles_*`
- **Notes:** Normal memory read, TBLR/TBLW, IN/OUT, reset, INT, and BIO pin
  timing is transcribed. One-cycle retirement for all twenty-six qualified
  common-address data instructions plus SST's forced-page status store is
  asserted through the partial native-phase
  integration. Figure 2-12 interrupt program reads, entry effects, EINT
  deferral, multiply deferral, and a 32-case matrix over every represented
  cycle of all 15 supported multicycle families are directed-tested in both
  the core and explicit pipeline. A
  four-case native test additionally proves digital falling-boundary ownership
  from each modeled subphase, including a stalled phase 2, while physical
  setup/CDC and unsupported CALA/RET/PUSH/POP
  arrivals remain.
  BANZ's two-word/two-cycle opcode and following-target
  normal reads, taken/untaken selection, second-cycle stall, and retirement
  are asserted. B's unconditional two-word/two-cycle target load and the same
  second-cycle stall/retirement boundary are asserted. The six accumulator
  branches assert that boundary for both outcomes. BV asserts it for both OV
  states and places the taken clear at second-cycle retirement. BIOZ asserts
  both active-low paths and changes the pin between its samples. CALL asserts
  two reads, no opcode-sample push, target-sample push, and target-phase stall.
  IN/OUT assert one MEN opcode read followed by one mutually exclusive DEN/WE
  cycle, live input sampling or stable output data, old-address ownership,
  second-cycle indirect updates, retirement, and phase stalls.
  TBLR/TBLW assert one MEN opcode read, one discarded MEN PC+1 read, one
  ACC-addressed MEN/WE table cycle, third-cycle retirement and updates,
  strobe/data stability during stalls, and the repeated PC+1 fetch.
  Primary Figures 2-9/2-10 label opcode prefetch separately from the numbered
  execution intervals; the legacy wrapper preserves the bus sequence and
  totals but does not yet retain IN/OUT or TBL execute ownership through the
  following/repeated prefetch. Exact B, BANZ, BV, BIOZ, CALL, and the six
  accumulator branches are the first multicycle cases mapped into explicit
  ownership: operand fetch is execution cycle 1 and the selected instruction
  fetch is execution cycle 2. BANZ selects from its old counter and decrements
  only at retirement; the accumulator family selects from the unchanged full
  32-bit ACC; BV selects from unchanged OV and clears it only at taken
  retirement; BIOZ samples raw active-low BIO at operand completion and
  retains only the resulting decision through the selected fetch; CALL pushes
  opcode-PC+2 only at selected-target retirement.
  The mappings are INFERRED from primary component facts and directed-tested,
  not presented as dedicated primary pin waveforms.
  Other control flow remains. CALA is model-asserted as a
  primary-confirmed one-word/two-cycle computed call, but its second-cycle
  external sequence remains open under `OQ-007`. PUSH/POP are model-asserted as
  primary-confirmed one-word/two-cycle instructions with exact state effects.
  `MEN` activity in both execution intervals is constrained by TI's general
  pin rule, but the address and fetched-word ownership remain open under
  `OQ-016`/`SC-018`; `docs/research/push_pop_bus_experiment.md` defines the
  resolving original-device trace.
  SUBC's one-cycle total is asserted
  only with the documented ACC-free following instruction; dependency
  behavior remains `OQ-017`. Electrical delays are wrapper
  constraints, not RTL delays.

## Milestone 16 — External wait-state behavior

### TIMING-002 — Stall protocol and stability

- **Status:** NOT STARTED
- **Priority:** P0
- **Dependencies:** BUS-001, BUS-002, BUS-003
- **Description:** Reproduce ready sampling and wait insertion for all external
  spaces and relevant phases.
- **Acceptance criteria:** zero/multiple waits pass; address/control/write data
  remain stable; liveness holds under an eventually-ready assumption.
- **Documentation:** `docs/timing/bus_cycles.md`
- **Tests:** `sim/bus/tb_wait_states.sv`, `formal/bus/`
- **Notes:** Original 40-pin TMS32010 has no READY/WAIT input. Research safe
  clock/phase adaptation under OQ-001; do not invent a native wait protocol.

## Milestone 17 — Differential testing

### DIFF-001 — Model/RTL/MAME trace comparison

- **Status:** IMPLEMENTING
- **Priority:** P1
- **Dependencies:** MODEL-001, ISA-002, TOOLS-001
- **Description:** Compare architectural state, memories, transactions,
  instruction counts, and cycles with deterministic replay and minimized
  mismatches.
- **Acceptance criteria:** legal randomized streams agree with the model; MAME
  adapter records exact commit/configuration/license and known timing limits.
- **Documentation:** `sim/differential/README.md`
- **Tests:** `sim/differential/test_*`
- **Notes:** Seed `0x32010` runs 512 supported instructions with model/RTL
  state including T, P, OV/OVM, logical-cycle,
  `ADD`/`ADDH`/`ADDS`/`AND`/`DMOV`/`LAC`/`LAR`/`LDP`/`LST`/`LT`/`LTA`/`LTD`/`MPY`/`OR`/`SUB`/`SUBS`/`XOR`/
  `ZALH`/`ZALS`
  reads, `SACL`/`SACH`/`SAR`/`SST` writes, and final 144-word RAM agreement over an
  identical deterministic image. MAR direct/indirect cases compare AR/ARP
  changes and
  inactive logical data strobes. LDP direct/indirect cases compare the logical
  read, DP source-bit result, and common AR/ARP post-update.
  LST cases compare the logical read, all four loaded status fields, preserved
  INTM, old-address counter update, and provisional memory-word ARP
  precedence under `OQ-015`. LT cases compare
  the logical read, full-width T result, and common AR/ARP post-update. LTA
  cases additionally compare the simultaneous previous-P accumulation and
  OV/OVM outcomes. LTD cases compare the same state effects plus distinct
  source-read and next-address-write transactions and final RAM. DMOV cases
  compare the same two-address copy topology and final RAM while requiring
  the LTD-specific T/ACC effects to be absent. MPY
  cases compare signed P results, TI's most-negative exception, and common
  post-update ordering. MPYK cases compare signed immediate endpoints and P
  results while requiring inactive logical data strobes. PAC cases compare
  the full-width ACC result, unchanged P, and inactive logical data strobes.
  APAC cases compare full-width arithmetic, OV/OVM outcomes, unchanged P, and
  inactive logical data strobes.
  SPAC cases compare full-width subtraction, OV/OVM outcomes, unchanged P,
  and inactive logical data strobes.
  ABS cases compare ordinary negation, most-negative OVM wrap/saturation,
  preserved incoming OV, one-cycle totals, and inactive logical data strobes.
  ADDH cases compare ordinary and boundary modulo high-half addition,
  low-half/OV/OVM preservation, logical reads, one-cycle totals, and common
  address updates under the CORROBORATED original-part policy.
  A focused BANZ differential aligns model instruction boundaries with the
  RTL's two machine-cycle traces and compares both program-read addresses,
  retirement, cumulative cycles, branch/fallthrough PC, and counter effects.
  A focused B differential applies the same alignment to two successive
  branches and compares both program reads, skipped fall-through words,
  retirement, cumulative cycles, target PC, and preserved state.
  A focused accumulator-branch differential chains taken and untaken cases
  for all six predicates and compares every program transaction and commit.
  A focused BV differential compares taken and untaken reads, retirement,
  cumulative cycles, PC, and OV at every commit.
  A focused BIOZ differential compares low/high pin paths, both mandatory
  reads, second-cycle retirement, cumulative cycles, and PC.
  A focused CALL differential compares two nested calls, every opcode/target
  read, second-cycle retirement, cumulative cycles, PC, and all four stack
  levels at each commit.
  A focused IN/OUT differential compares direct and indirect transfers,
  opcode-plus-I/O transaction order, exact two-cycle totals, RAM results,
  port/data direction, PC, and AR/ARP post-updates.
  A focused TBLR/TBLW differential compares opcode, discarded, table, and
  repeated-following program addresses, three-cycle retirement, MEN/WE
  direction, RAM and program-memory effects, PC, and all four stack levels.
  MAME comparison and
  legal randomized full-ISA streams
  remain. MAME disagreement
  creates research work, not an automatic oracle verdict.

## Milestone 18 — Formal verification

### FORMAL-001 — Bounded safety and liveness properties

- **Status:** IMPLEMENTING
- **Priority:** P1
- **Dependencies:** RTL-001, RTL-002, TIMING-002
- **Description:** Prove reset, decode, FSM, bus, stack, PC, repeat, interrupt,
  RAM-bound, transaction, and arithmetic properties.
- **Acceptance criteria:** proofs pass at documented bounds and assumptions;
  cover statements demonstrate non-vacuity.
- **Documentation:** `formal/README.md`
- **Tests:** `make formal`
- **Notes:** Four actual-core configurations pass bounded checks over
  arbitrary clock-enable sequences. The 12-step
  EINT/protected-LACK/dummy/vector fixture
  reaches vector execution at step 6. The 14-step
  EINT/NOP/MPYK/following-instruction/dummy/vector fixture reaches held-low
  request relatching at step 8. A 20-step fixture preloads deterministic RAM,
  executes LT/EINT/NOP/direct-MPY/MPYK/direct-MPY/LACK/dummy/vector, checks
  three signed products and repeated multiply deferral, and reaches entry at
  step 12. A second 20-step fixture executes
  LT/LAR/LARP/EINT/NOP/indirect-MPY/LACK/dummy/vector, proves that
  `MPY *-,AR1` reads old address `0x8f`, produces `0xffff0000`, preserves
  AR0's upper bits while decrementing its low-nine-bit counter from `0x08f`
  to `0x08e`, replaces ARP, and reaches entry at step 12. Together the four
  configurations check initialization, pending retention, MPY/MPYK
  extension, program-only entry, stack/vector/INTM effects, bus exclusion,
  relatching, and stall stability.
  A fifth standalone 12-step BMC leaves all fetch/execute register inputs
  arbitrary while assuming only no valid fetch on flush and no overwrite of
  an incomplete slot. It proves initialization, exact arbitrary-word capture,
  non-boundary stability, incomplete retention, completion/replacement,
  bubbles, and reset/flush invalidation. Its cover reaches
  prime/stall/replace/flush/target capture at step 7. This does not prove core
  integration or complete TI pipeline overlap.
  A sixth configuration runs a 40-step BMC and cover over the actual
  sequential-pipeline hierarchy for fixed `LACK 4; TBLR 0; LAC 0; NOP`.
  It leaves clock enable arbitrary and proves discarded PC+1 ownership,
  ACC-addressed MEN transfer of `0x1234`, exact logical RAM commit, repeated
  PC+1 fetch, following LAC consumption, bus exclusion, stack/interrupt
  preservation, and stall stability. The complete path reaches cover step 34.
  This configuration itself proves only one direct TBLR scenario, not TBLW,
  indirect-table, interrupt-arrival, arbitrary-program, or general
  integrated-pipeline behavior.
  A seventh 40-step configuration preloads RAM word 0 through the explicit
  verification-only debug port, executes `LACK 2; TBLW 0`, and models program
  memory as committing only at an enabled active phase-3 write boundary. It
  proves the old PC+1 ZAC remains through discard and stalls, exact address-2
  WE/data ownership, one write, repeated replacement fetch, and subsequent
  execution of rewritten `LACK 0x44`; cover reaches step 35. This is one
  direct synchronous-memory scenario, not an indirect, arbitrary-data,
  interrupt-arrival, or electrical-memory proof.
  SymbiYosys v0.67-4-gfea6e46 with Bitwuzla 0.9.1 was used. DINT,
  the other indirect MPY control/update cases, arbitrary chain
  placement/length, formal multicycle-arrival coverage, RET, general
  decode/FSM/RAM/arithmetic properties, and liveness assumptions remain.
  Never describe bounded checks as complete proof.

## Milestone 19 — FPGA synthesis and timing

### SYNTH-001 — Portable and Cyclone V qualification

- **Status:** IMPLEMENTING
- **Priority:** P1
- **Dependencies:** RTL-001, RTL-002
- **Description:** Run early Yosys smoke synthesis, then a constrained Quartus
  DE10-Nano project with fitter and TimeQuest evidence.
- **Acceptance criteria:** no latches/accidental clocks/unconstrained primary
  paths; versions, warnings, resources, Fmax, and critical paths are recorded.
- **Documentation:** `synthesis/README.md`, `artifacts/synthesis/`
- **Tests:** `make synth-yosys`, `make synth-quartus`
- **Notes:** Fifty-six-instruction RTL, phase engine, multiplier, and
  144-word RAM are
  qualified in both synthesis flows; exact current utilization, internal Fmax,
  slack, warning scope, and generic-cell totals are recorded in
  `synthesis/qualification.md`. All harness exclusions are enumerated and
  TimeQuest reports zero unconstrained categories; this is still not wrapper
  I/O closure. Yosys 0.67+111 from the 2026-07-29 OSS CAD Suite passes
  structural/generic synthesis, lowering the asynchronous RAM to
  flip-flops/muxes. `make synth-yosys` now reproducibly checks both the legacy
  harness (13,866 generic cells/26 checks) and the
  exact-B/BANZ/BV/BIOZ/CALL/accumulator-branch/IN/OUT/TBLR/TBLW/interrupt
  pipeline slice (15,686 cells/103 checks), each with zero structural
  problems. Full-core
  resources, a block-RAM-safe
  pipeline, pin-level wrapper constraints, and final timing remain.

## Milestone 20 — MiSTer-compatible wrapper

### INTEG-001 — Generic MiSTer-facing wrapper

- **Status:** NOT STARTED
- **Priority:** P1
- **Dependencies:** TIMING-001, SYNTH-001
- **Description:** Adapt the native interface to clock-enable operation,
  synchronous memories, optional SDRAM, callbacks, interrupts, BIO, trace, and
  deterministic simulation hooks.
- **Acceptance criteria:** wrapper preserves native timing, passes integration
  simulations, and contains no Hard Drivin'-specific processor behavior.
- **Documentation:** `docs/integration/mister_wrapper.md`
- **Tests:** `sim/bus/tb_mister_wrapper.sv`
- **Notes:** Vendor resources are permitted only behind this boundary.

## Milestone 21 — Hard Drivin' integration research

### HD-001 — Driver Sound Board requirements

- **Status:** RESEARCHING
- **Priority:** P1
- **Dependencies:** REF-001, ARCH-001
- **Description:** Determine exact board revision, clocks, memories, 68000
  communication, interrupts, BIO, DAC path, registers, waits, reset, ROM
  regions, and variants from Atari documents and maintained software.
- **Acceptance criteria:** each mapping has schematic/manual/MAME citations and
  confidence; synthetic smoke program tests reset, handshake, interrupt, and
  DAC traces without copyrighted ROMs.
- **Documentation:** `docs/integration/hard_drivin_requirements.md`
- **Tests:** `sim/programs/hard_drivin_smoke/`
- **Notes:** Atari production drawing A044427 Rev A is identified. Its
  TMS32010 `INT` pin connects to pull-up net `PR1` and is held inactive-high
  by `R26` (1 kΩ), while `/320BIO` is generated from 1 MHz divider logic and
  resampled by `CLKOUT` before reaching `/BIOS`. The distinct `320IRQ` net
  feeds the 68000-side interrupt path. Exact program-RAM arbitration phases,
  complete BIO divider state, DAC polarity, board-variant audit, and synthetic
  smoke tests remain. User-supplied ROM hashes may enable local tests; ROMs
  are never committed.

## Milestone 22 — Release qualification

### REL-001 — Evidence and license audit

- **Status:** NOT STARTED
- **Priority:** P0
- **Dependencies:** all preceding milestones
- **Description:** Audit instruction/timing completeness, regressions, formal,
  synthesis, interfaces, tool reproducibility, provenance, licensing,
  documentation, realistic programs, and integration.
- **Acceptance criteria:** every release-ready criterion in `AGENTS.md` has a
  linked reproducible artifact and no undisclosed blocker.
- **Documentation:** `docs/release_checklist.md`, `CHANGELOG.md`
- **Tests:** `make release-check`
- **Notes:** A partial implementation must remain honestly versioned and must
  not be advertised as cycle-accurate.
