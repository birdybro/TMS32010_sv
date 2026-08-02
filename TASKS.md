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
  until permission is demonstrated. The ignored cache now verifies 60 pinned
  sources, including Atari TM-327 for published Sound Board diagnostic roles,
  Motorola M68000UM Ninth Edition for local-host bus-state timing, TI's ALS32
  data sheet for the local memory gates, the 1983 AMD
  manufacturer data book needed to interpret A044427's Am6012 path, and the
  pinned MAME DAC support sources needed to distinguish emulator sample
  mapping from board wiring. Four historical MAME artifacts now trace that
  mapping from the first located 0.62 Hard Drivin' sound support through the
  2016 AM6012 migration, separating continuous signed-software behavior from
  the migration's later unsupported schematic-inversion comment. Three newly
  pinned primary Atari publications add Hard Drivin' compact TM-329, Race
  Drivin' compact SP-360, and Race Drivin' cockpit TM-351 provenance for
  Sound PCB cabinet/assembly-variant research.
  A contemporaneous AMD memory data book now establishes the 27256 pin-1
  VPP/read requirement and pin-compatible 27512 A15 option used by A044427's
  E1/E2 footprint, without asserting an installed EPROM vendor or population.
  Atari TM-356 first printing now provides primary field-installation evidence
  that Race Drivin' deluxe-cockpit upgrades used `A046491-02`, moved the
  program-ROM link to E2, retained/replaced `45A` sample block 2 as needed,
  and added `136077-1017` at physical `45C`/block 8. The manual remains only
  in the ignored cache because redistribution permission is not established.
  The exact TI
  LS20, AS00, combined ALS32/AS32,
  F04, F11, and F74 component documents now support SP-327 main-bus Boolean
  and future propagation analysis without treating a gate symbol as an
  electrical specification. Atari A044425 Rev-J supplemental GSP/MSP sheets
  and TI SPVU001 now qualify both high-speed wait nets as direct TMS34010
  `HRDY` outputs with high-ready/low-wait semantics.
  Motorola's exact 1985 MC68681 advance information and the official archived
  MC68HC681 successor manual now qualify the independently clocked DUART
  acknowledge boundary without transferring successor-only behavior.
  TI SDLS013A now qualifies the active-low B:A/Y0-Y3 truth table for both
  SP-327 LS139 subdecoders.
  TI patent US4577282A is now integrity-pinned as non-committed architectural
  background. Its explicit RET discard/pop/target timing corroborates
  ADR-0003, while its omission of the production accumulator PUSH/POP opcodes
  prevents it from resolving `OQ-016`. SPRU011's XDS/22 and Kontron sections
  now establish that contemporary tooling sampled individual machine cycles
  and clock-qualified external fetches; they describe the required measurement
  granularity but contain no PUSH/POP trace and therefore do not select a bus
  hypothesis. TI's 1982 TMS32010 simulator guide now pins the official
  distinction between instruction acquisition and program-ROM reads, a
  256-state PC/ACC/AR architectural trace, its separate clock-cycle counter,
  and stop code 9950 after a prohibited SUBC dependency. These are tool
  semantics only: the guide supplies no external-pin trace or violating-
  silicon result. A public-index search did not locate the bibliographically
  identified XDS/22 manual `SPDU015`.

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
- **Tests:** `tests/regressions/test_documentation.py`,
  `tests/regressions/test_push_pop_capture.py`,
  `tests/regressions/test_toolchain.py::ToolchainSliceTests::test_reset_retention_probe_images_and_provisional_paths_are_stable`,
  `tests/regressions/test_simultaneous_ar_capture.py`,
  `tests/regressions/test_ram_boundary_capture.py`,
  `tests/regressions/test_ram_invalid_read_capture.py`,
  `tests/regressions/test_ram_invalid_write_capture.py`,
  `tests/regressions/test_reset_retention_capture.py`
- **Notes:** Initial primary-cited baseline and ADR exist. The status register
  is now qualified as exactly five architectural bits plus a 16-bit LST/SST
  representation: bits 12:9 and 7:2 are fixed-one SST output/ignored LST
  input at VERIFIED_PRIMARY confidence, while bit 1 alone retains its
  CORROBORATED stored-one resolution under `OQ-003`/`SC-008`. Remaining
  acceptance work includes out-of-range RAM decode, explicit interrupt
  ownership beyond the qualified basic Figure 2-12 path, and the
  per-cycle program-address/fetched-word ownership of single-word PUSH/POP
  under `OQ-016`. TI's every-cycle `MEN` rule narrows the strobe behavior, but
  does not distinguish a repeated/discarded next-word read from an advancing
  prefetch. Contemporary TI patent US4577282A independently corroborates the
  general read rule but omits accumulator PUSH/POP; `SC-018` and the physical
  experiment preserve that boundary. TI's EVM breakpoint restriction now
  corroborates external `N+1` visibility during the multicycle context, but
  its address-driven logic supplies no exact phase, repeat count, or later
  address and therefore does not choose a hypothesis. The physical experiment
  now has a strict normalized falling-edge classifier and evidence-package
  validator. It can report a repeatable H1/H2/H3 result only after 32 runs and
  verified exact-image/decoded-trace/raw/photo hashes. Its expanded `OQ-008`
  sidecar preserves raw tracking/lot/package identity, custody, test
  conditions/tool versions, and distinct top/bottom/board photographs while
  scoping the result to one specimen. A rehashed arbitrary image cannot become
  review-ready, and `acceptance_complete` stays false. This cannot change
  architectural confidence without raw-capture review or establish
  cross-specimen invariance.
  The contemporary TI software simulator additionally separates instruction
  acquisition from program-ROM-read breakpoints but traces only PC/ACC/AR0/
  AR1; it supplies neither a PUSH/POP bus phase nor a path to resolve
  `OQ-016`.
  `OQ-014` is now reduced to a reproducible original-NMOS measurement:
  `SC-038` preserves SPRU001B's isolated `128-144` off-by-one table, the
  consistent 144-word/`128-143` production evidence, and the related patent's
  internally inconsistent row/column capacity. Stable DMOV and LTD probe
  images clear and scan all valid words through `OUT`, expose an `0x90` read,
  and leave T/P/ACC inspectable. A paired strict normalizer now checks both
  exact images, all 145 outputs, fetch/write framing, EVM register rows, and
  hashed raw/transcript/photo provenance. It preserves varying diagnostics,
  valid-RAM changes, and parallel-register mismatches as evidence instead of
  test failures. Shared specimen validation now independently pins each exact
  source/26-word listing/decoded trace and requires the two sidecars to name
  the same raw marking/date/lot/package specimen. Six regressions cover full,
  partial, extra, malformed, substitute-listing, mismatched-specimen, and
  complete-package flows. Fixed-baseline `review_ready` remains explicitly
  short of acceptance because varied history/sentinels, raw review, and a
  second specimen remain required. No boundary outcome has been assigned
  without the physical capture.
  The broader `OQ-002` absent-address question is separately reduced to three
  reproducible original-NMOS fixtures under `SC-041`: a read-only
  `0x90`-`0xff` sweep places controlled `0x0000` and `0xffff` legal reads
  immediately before every observation, and ascending/descending SAR sweeps
  write unique full-AR sentinels before scanning all 144 valid words and all
  112 absent selects. The read-only image must run first. No absent value,
  alias, zero-fill, or trap result is assigned without physical capture. Its
  strict stage-1 classifier now validates all 451 framed outputs plus 32 reset
  and eight cold-power run identities. It retains both raw readings per
  address, labels only predecessor-tracking/history-independent/history-
  dependent relationships, and permits complete variable results to reach
  review. Shared specimen validation now pins the exact source/35-word
  listing/decoded trace and complete raw marking/date/lot/package record to one
  part without constraining any read value. Six regressions cover every
  relationship, substitute listing, and malformed/package boundary.
  `acceptance_complete` remains false until both destructive
  directions, any targeted follow-up, raw review, and a second specimen. A
  paired stage-2 normalizer now checks both exact 258-output directions,
  preserves every valid disturbance and address/sentinel/readback tuple, and
  requires a pinned stage-1 report plus an explicit order declaration. Shared
  specimen validation pins both exact source/43-word listing/decoded-trace
  packages to the same identity as stage 1 without constraining any result.
  Six further regressions cover direction mapping, all result categories,
  disturbances, framing, variable packages, substitute listings, exact
  images, mismatched specimens, and bad workflow links. The hash/declaration
  does not itself prove physical chronology and no primary-backed write-run
  count is invented.
  `OQ-012` now has a similarly reproducible boundary. `SC-042` separates the
  production guide's unlisted register values from SPRU005A's statement that
  warm EVM RESET saves every register except PC, its separate
  clear/corruption warning, related-patent software initialization, and
  conflicting MAME/IKA policies. Complementary set/clear fixtures export the
  complete state before reset, reconstruct every destructively observed
  register, use external BIO alone to choose the post-reset path, and consume
  no retained RAM while capturing the after vector. The EVM evidence is
  CORROBORATED. A strict paired normalizer now checks both exact dense images,
  every OUT/fetch and BIO path, derived RS/BIO transitions, all nine declared
  clock/hold combinations, the reset bus contract, every architectural field,
  and raw/photo provenance. Variable and non-retained post-state remains
  reviewable; only the primary-defined unchanged OVM control can invalidate a
  complete capture. Shared specimen validation now binds both exact source,
  dense 297-word listing, image, and normalized-trace packages to the same raw
  marking/date/lot/package identity. Each side verifies seven artifacts and
  remains explicitly `this_specimen_only`. Six regressions cover field
  decomposition, reserved bit 1, variable review-ready packages,
  reset/BIO/bus timing, exact anchors and pre-state, partial/extra flow,
  condition coverage, hashes, exact images, substitute listings, and
  mismatched specimens.
  Original-silicon retention remains PROVISIONAL pending physical captures,
  raw review, and a second identified specimen.
  `OQ-001` is resolved from the original TMS32010-20 AC table: physical
  master-clock periods are limited to 48.78–150 ns with 47.5–52.5% pulse
  duration, so arbitrary clock stops remain outside specified conditions.
  Physical pin timing and logical transaction timing must remain distinct.
  `OQ-010` now has a strict physical-capture classifier around its stable exact
  raw-word fixture. It distinguishes all three complete priority candidates,
  preserves arbitrary other words, and separately records armed-only,
  first-result-before-second-fetch, and second-fetch-without-second-result
  noncompletion. Partial or noncandidate sequences can never become
  `review_ready`. A shared specimen validator now binds the normalized trace,
  exact source/listing/image, raw marking/date/lot record, access time, tool
  versions, and three specimen photographs to one stable `OQ-008` identity;
  `acceptance_complete` remains false. No physical capture exists and all 372
  words remain rejected by fail-closed policy rather than claimed silicon
  trap behavior.
  `OQ-015` now uses the same specimen boundary around its exact 30-word
  bidirectional fixture: complete review packages bind source/listing/image,
  normalized trace, test context, and raw package/date/lot provenance to one
  specimen while leaving `acceptance_complete=false`. The classifier still
  requires both directions to select one precedence rule; no physical capture
  exists and memory-wins remains PROVISIONAL.
  `OQ-017`/`OQ-018` now apply the same boundary independently to their exact
  dependency and overflow fixtures. Complete packages bind each decoded trace
  and source/listing/image to one specimen, but the dependency's first word
  remains unconstrained, all four overflow pairs remain retainable, and
  `acceptance_complete` is always false. No physical capture exists.
  `OQ-019` now layers the shared specimen boundary over its existing pulse,
  sampled-level, exact sparse-image, and three-calibration checks. Complete
  packages bind source/listing/decoded trace and raw package/date/lot data to
  one specimen while leaving all three candidates unchanged and
  `acceptance_complete=false`. No physical capture exists.
  `OQ-008` now has a dated, reproducible publication/device-revision audit.
  `SC-043` separates the October-1985, February-1986, January-1987, and
  May-1989 data-sheet revisions and changing 14/20/25-MHz NMOS product lists
  from any unproved silicon-mask identity. Two newly pinned 1989 TI guides
  agree that their current lists contain only the 20-MHz NMOS part, but
  neither is an erratum or product-change notice. TI's stated BBS
  specification-update route has no authenticated TMS32010 notice archive in
  the located corpus. Full raw package/date/lot provenance and at least two
  specimens are now required for physical generalization; no RTL behavior
  changed and `OQ-008` remains RESEARCHING/NO REVISION MAP.
  Five direct shared-validator regressions now cover its complete
  five-artifact subset and malformed identity, timing, tool-version, exact
  source/listing/trace, and photograph records. Empty IDs and invalid scope
  fail closed as `null`/`UNQUALIFIED`; no experiment result or confidence
  classification changes.

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
  `tests/expected/opcode_fixtures.yaml`,
  `tests/asm/simultaneous_ar_update_probe.asm`,
  `tests/regressions/test_toolchain.py::ToolchainSliceTests::test_simultaneous_ar_update_probe_image_is_stable`,
  `tests/regressions/test_simultaneous_ar_capture.py`
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
  address combinations. The decoder accepts 21,895 supported words without
  collisions. A separate provenance-aware audit now partitions all 65,536
  words into 21,895 documented-legal encodings, 10,976 words that set TI's
  explicitly reserved indirect bits 6/2/1, 372 unresolved simultaneous
  increment/decrement controls under `OQ-010`/`SC-040`, 3,637
  documented-pattern mismatches, and 28,656 encodings absent from TI's
  explicitly complete
  original instruction summary. Generated counts and boundary vectors are
  regression-checked. A one-step symbolic RTL harness independently exhausts
  all 65,536 input words against a compact family/field-validity predicate,
  checks meaningful operand projections, and reaches eight classification
  boundaries. It proves the partial decoder's 21,893-word acceptance set,
  including CALA/RET while retaining PUSH/POP rejection;
  mnemonic identity remains grounded in the database, fixtures, and exhaustive
  simulation rather than the formal predicate. The primary-documentation
  partition is complete, but
  full reserved-region qualification remains incomplete: only the explicit
  indirect-bit class is called reserved, while mismatches/primary-unlisted
  words receive no invented behavior. A later TI C1x reference card now
  proves the simultaneous controls are a prohibited source form, but it does
  not define forced-word behavior on the original NMOS part. Pinned MAME and
  IKA choose no net update; the current decoder rejection remains fail-closed
  and the stable two-boundary original-device probe assigns no expected
  result. A strict capture classifier now verifies the exact image, ordered
  fetch/output anchors, terminal/trailing boundaries, 32-run consistency, and
  raw/photo provenance. Six regressions distinguish the three complete
  priority candidates, arbitrary complete results, and three explicit partial
  noncompletion stages. Only complete priority candidates can be review-ready,
  and no physical data is present. Exact
  `ABS=0x7f88`, accumulator result, OVM-selected
  most-negative wrap/saturation, and one-cycle program-only boundary are
  primary-verified. Original-part OV preservation is `CORROBORATED` by
  SPRU013's instruction-format rule, the absence of status annotations on the
  original ABS page, the later C14/E14 variant's explicit added OV effect,
  and pinned MAME; `SC-007`/`OQ-013` record the resolution. Exact
  `SST=0x7cxx` contributes 28 legal encodings: direct offsets 0–15 force page
  1 and twelve indirect controls use the common reserved-field policy. Its
  defined status fields, address rules, and one-cycle timing are primary-
  verified. Bits 12:9 and 7:2 are primary-verified fixed-one outputs and
  ignored LST inputs; reserved bit 1 and pre-update-status ordering are
  CORROBORATED by
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
  are primary-verified. ADR-0003 provisionally selects discarded `PC+1` then
  target fetch for future RTL at `INFERRED` confidence; original-pin
  confirmation remains `OQ-007`/`SC-037`.
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
  endpoints under `OQ-014`. The executable original-NMOS clear/scan probe now
  makes that provisional policy falsifiable without claiming a result.
  `DMOV` performs only that unchanged-word copy,
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
  preserves INTM, ignores every non-field source position, and applies
  indirect counter updates to the old selected AR.
  Memory-sourced ARP precedence over an encoded next ARP is explicitly
  PROVISIONAL under `OQ-015`/`SC-009`. The original worked example plus pinned
  IKA support encoded-field-wins, while later TI plus MAME support memory-wins;
  a stable two-direction original-NMOS probe assigns no expected result.
  `SUBC` implements
  both conditional subtract/divide paths and TI's 65/7 worked result with
  legally inserted ACC-free following instructions. Intermediate-subtraction
  sticky OV is provisional under `OQ-018`, and same-boundary ACC commit is
  not evidence for prohibited scheduling under `OQ-017`.
  `SST` exhausts all 32 combinations of the defined status fields, forces
  direct page 1, captures old ARP in the stored word before indirect
  post-update, stores the ten primary-verified constant positions high, and
  stores reserved bit 1 high at CORROBORATED confidence
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
  fetch. RTL now implements ADR-0003's targeted mapping of
  discarded `PC+1` followed by selected-target fetch; physical confirmation
  remains pending under `OQ-007`/`SC-037`. This mapping remains INFERRED for
  CALA.
  `RET` loads PC from the old stack top, shifts all lower levels upward,
  duplicates the old bottom, and counts the primary-defined two cycles. Its
  logical transaction trace deliberately includes only the known opcode
  fetch. ADR-0003 now permits the same targeted discarded-`PC+1` /
  selected-target RTL mapping as CALA. Contemporary TI patent US4577282A
  corroborates this RET ordering without upgrading it to production-primary
  proof;
  directed bus, stall, interrupt-boundary, bounded-formal, and architectural
  differential tests now cover the combined CALA/RET path.
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
  overlapped pipeline timing, RTL/native PUSH/POP timing, and untested
  interrupt arrival combinations remain unimplemented. CALA/RET retain
  `INFERRED` rather than physical timing confidence.

## Milestone 6 — Assembler and test-program workflow

### TOOLS-001 — Assembler and disassembler

- **Status:** COMPLETE
- **Priority:** P1
- **Dependencies:** ISA-001
- **Description:** Qualify a legal assembler or implement deterministic local
  assembly and database-driven disassembly.
- **Acceptance criteria:** all original mnemonics, labels, constants, comments,
  data, origin, includes, expressions, raw/hex/listing output, and diagnostics
  work; source-binary-disassembly-binary round trips match hand fixtures.
- **Documentation:** `tools/assembler/README.md`,
  `tools/disassembler/README.md`
- **Tests:** `tests/regressions/test_toolchain.py`,
  `tests/regressions/test_fir4_program.py`
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
  directed-tested across all sixty documented mnemonics. The checked synthetic
  `tests/asm/push_pop_bus_probe.asm` image provides a reproducible,
  noncopyrighted original-device pin-trace fixture for `OQ-016`. SST
  additionally enforces direct offsets 0–15 while
  retaining common indirect syntax and lossless noncanonical aliases. A surviving
  binary tool may be cataloged but never executed outside isolation. The
  project-authored `sim/programs/fir4/fir4.asm` closes the initial realistic
  test-program workflow: independently fixed words round-trip through the
  tools, the model produces Q15 `0x1a00` from a hand-calculated four-tap
  vector, all twelve one-cycle instructions fetch in order, and every logical
  `LT`/`MPY`/`LTD`/`SACH` RAM transaction matches the committed expectation.
  This task's tool/workflow criteria are complete; it does not imply
  instruction-complete RTL or final assembler syntax compatibility with every
  historical TI extension.

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
- **Tests:** `sim/unit/tb_*`, `formal/tms32010_multiplier.sby`,
  `formal/tms32010_input_shifter.sby`,
  `formal/tms32010_output_shifter.sby`,
  `formal/tms32010_auxiliary_counter.sby`,
  `formal/tms32010_status_word.sby`,
  `formal/tms32010_stack.sby`,
  `formal/tms32010_accumulator.sby`,
  `formal/tms32010_internal_ram.sby`,
  `formal/tms32010_internal_ram_registered.sby`
- **Notes:** Initial 32-bit accumulator, 16-bit T register, 32-bit P register,
  two 16-bit ARs,
  ARP, DP, OV/OVM, and 144-word internal RAM exist for the
  fifty-eight-instruction slice. `ABS` verifies zero, positive, ordinary
  negative, and most-negative accumulator values under both OVM modes while
  preserving incoming OV. `LAC`
  verifies sign extension and left shifts. The shared combinational
  `tms32010_input_shifter` now supplies that same qualified operand to LAC,
  ADD, and SUB. Its one-step proof leaves all 20 input bits arbitrary, builds
  the expected output bit by bit, and exhausts every signed source/count
  combination from shift 0 through 15. Decode, addressing, ALU/status effects,
  and instruction timing remain outside the primitive. `SACH` now uses a
  separate combinational output shifter for its primary-documented zero, one,
  and four counts. Its one-step proof leaves the complete ACC and field
  arbitrary, independently indexes every result bit, proves ACC[11:0]
  independence, reaches primary examples, and checks local fail-closed
  invalid-field behavior. Decode, address selection, the data write, and
  one-cycle timing remain instruction-owned and directed-tested. `ZALH`/`ZALS`
  verify accumulator half placement; all
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
  current Quartus harness. A one-step symbolic proof checks all 2^32 operand
  pairs against an explicitly sign-extended product, proves the original
  `0x8000`-square exception is the only departure, and checks commutativity
  plus zero/unity identities. `MPYK` reuses that portable datapath with a
  sign-extended 13-bit immediate and no RAM transaction. `PAC` transfers all
  32 P bits into ACC without changing P or arithmetic status. `APAC` adds P
  to ACC with signed overflow, sticky OV, and OVM-controlled saturation.
  `SPAC` subtracts P from ACC with the same status and result policy.
  `tms32010_accumulator` now centralizes the qualified signed 32-bit add,
  subtract, wrap, overflow, and OVM-saturation relation used by ADD/SUB/SUBH,
  APAC/SPAC, and LTA/LTD. A one-step symbolic proof leaves both operands,
  operation direction, and OVM arbitrary, compares against an independent
  signed 33-bit reference, and reaches all four signed saturation directions.
  Sticky OV and operand selection remain instruction-owned and retain their
  directed/differential tests. ADDS/ADDH/SUBS/SUBC remain separate because
  their documented arithmetic policies differ.
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
  provisional under OQ-012. The standalone RAM passes temporal induction over
  a symbolic qualified address with arbitrary initial contents and legal
  CPU/debug writes. It proves both write paths, preservation under non-target
  writes, all eight-bit validity results, and zero output for invalid reads;
  that invalid-read value remains implementation policy under `OQ-002`.
  Remaining specialized ALU behavior, native PUSH/POP sequencing, and
  remaining status behavior remain. The portable combinational stack block
  now supplies the exact hold, push/drop-bottom, pop/duplicate-bottom, and
  table-final relations used by CALL, CALA, RET, interrupt entry, and table
  retirement. Its one-step proof quantifies all 60 stack/push-data bits and
  all eight control combinations, asserts every output word, and reaches six
  distinct behavioral covers. The core retains each owner's established
  retirement boundary and asserts mutually exclusive stack-operation classes.
  Invalid overlapping controls are local fail-closed policy, and the primitive
  does not resolve native PUSH/POP bus ownership under `OQ-016`.
  The portable combinational auxiliary counter now supplies hold and exclusive
  increment/decrement for the common indirect path, MAR, BANZ, IN/OUT, and
  TBLR/TBLW. It wraps only AR[8:0] and preserves AR[15:9]. Its independent
  bitwise carry/borrow proof leaves the complete value and both controls
  arbitrary and reaches six wrap/ordinary/hold/invalid covers. Owner selection,
  old-address use, ARP changes, LAR suppression, SAR ordering, and commit timing
  remain in the core. Dual controls hold and invalidate as implementation
  policy only; original-silicon behavior remains UNKNOWN under
  `OQ-010`/`SC-040`.
  The portable combinational status-word relation now supplies SST packing
  and the four primary-defined LST load fields. Its one-step proof leaves all
  five stored fields and the complete LST word arbitrary, builds the expected
  SST representation independently by bit index, proves exact selection of
  source bits 15, 14, 8, and 0, and reaches five fixed-field/ignored-bit
  covers. The core still owns INTM preservation, addresses, old/new ordering,
  retirement, and the PROVISIONAL indirect-LST next-ARP precedence under
  `OQ-015`/`SC-009`; reserved SST bit 1 remains CORROBORATED under
  `OQ-003`/`SC-008`.
  ADR-0004 keeps the standalone asynchronous RAM boundary but enables a
  phase-staged registered read in the explicit pipeline. Directed and
  inductive tests prove registered capture, stable untouched data, invalid
  qualification, debug and CPU writes, and same-address forwarding. The
  native IN-to-OUT test proves the new word is present during phase-0 setup
  before OUT's active WE phase. Quartus maps the 144-by-16 array to one M10K
  without adding a processor cycle. The table-transfer formal proof exposed
  and now guards a separate requirement: global clock-enable pauses must hold
  read data and forwarding metadata. Exact synthesis evidence is under
  SYNTH-001.
  Decoder family metadata was retained only after simulation visited all
  65,536 words and compared every valid internal-data classification, the full
  instruction/bus/differential/formal regressions retained their expectations,
  Quartus preserved one M10K and one DSP, and the accepted full-path report
  improved from 24.217 ns/16 levels to 21.399 ns/14 levels. Invalid encodings
  may assert family metadata but remain behaviorless because every consumer
  must also require decoder validity.

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
  `sim/bus/tb_sequential_pipeline_cala_ret.sv`,
  `sim/bus/tb_sequential_pipeline_io.sv`,
  `sim/bus/tb_sequential_pipeline_table.sv`,
  `sim/interrupt/tb_sequential_pipeline_interrupt.sv`,
  `sim/interrupt/tb_sequential_pipeline_interrupt_multiply.sv`,
  `sim/interrupt/tb_sequential_pipeline_interrupt_multicycle.sv`,
  `sim/interrupt/tb_sequential_pipeline_interrupt_computed.sv`,
  `sim/bus/tb_sequential_pipeline_differential.sv`,
  `sim/unit/tb_fetch_execute.sv`, `sim/instruction/tb_sequencer.sv`,
  `formal/tms32010_decode.sby`, `formal/sequencer/`
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
  branches, ADR-0003 CALA/RET, plus exact IN/OUT and TBLR/TBLW execution ownership. All branches retain
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
  CALA/RET retain ownership across an explicitly nonexecutable sequential read
  and the accumulator/old-TOS target read, commit stack/PC effects only at
  selected-target capture, and stall in either interval. The legacy wrapper
  rejects them rather than imply this provisional sequence.
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
  multicycle arrival boundary; four more explicit cases cover both intervals
  of CALA and RET;
  a separate four-case native test checks digital falling-boundary ownership
  from every modeled subphase. Physical setup/synchronizer behavior remains
  unresolved. Remaining
  PUSH/POP interrupt ownership and cycles remain. Physical confirmation of
  ADR-0003 also remains. Do not collapse Harvard
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
- **Tests:** `sim/bus/tb_data_bus.sv`,
  `tests/asm/ram_invalid_*_probe.asm`,
  `tests/regressions/test_toolchain.py::ToolchainSliceTests::test_ram_invalid_decode_probe_images_are_stable`,
  `tests/regressions/test_ram_invalid_read_capture.py`,
  `tests/regressions/test_ram_invalid_write_capture.py`
- **Notes:** Primary documentation establishes that ordinary operands are
  wholly internal; external storage moves through table or I/O instructions.
  `ADD`/`ADDS`/`AND`/`DMOV`/`LAC`/`LAR`/`LDP`/`LST`/`LT`/`LTA`/`LTD`/`MPY`/`OR`/`SACL`/`SACH`/`SAR`/`SUB`/`SUBC`/`SUBS`/
  `XOR`/`ZALH`/`ZALS` model/RTL tests cover valid address selection, logical
  read/write traces, ordering, and explicitly trap unresolved `0x90`–`0xff`.
  The portable RTL contains exactly 144 words and a nonarchitectural preload
  port. Directed tests read back every store class; seeded differential
  compares all 144 final words. A standalone inductive proof additionally
  quantifies all qualified word addresses and arbitrary 16-bit legal writes,
  checks non-target preservation, and exhausts the 256-value read/write
  validity functions. The invalid-read-zero result is a verification-interface
  policy, not original-silicon evidence for `OQ-002`. `SC-041` now records the
  primary eight-bit-address/144-word boundary and MAME-unmapped versus
  IKA-256-word policy split. Stable read-only and two-direction write/scan
  images make alias, disturbance, history, and absent-read hypotheses
  physically testable without weakening the fail-closed implementation;
  `tests/regressions/test_toolchain.py::ToolchainSliceTests::test_ram_invalid_decode_probe_images_are_stable`
  locks their exact machine words and symbols. The read-only stage now also
  has strict 451-output framing, address-by-address two-history classification,
  reset/cold-power provenance checks, and six regressions; variable absent
  words are preserved and no read value is expected. Paired directional write
  normalization now adds exact 258-output framing, nonzero valid-address and
  intended-sentinel/readback preservation, stage-1 report linkage, and six
  regressions without converting zero/sentinel/other readings into expected
  behavior. Physical chronology, raw review, targeted follow-up, and cross-
  specimen scope remain incomplete. Remaining instruction
  interactions remain.
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
  `formal/tms32010_reset.sby`, `formal/tms32010_program_bus_reset.sby`,
  `tests/regressions/test_reset_retention_capture.py`
- **Notes:** Appendix A verifies five-machine-cycle minimum assertion,
  synchronized response, inactive strobes/high-Z data, PC/address clear after
  the next full cycle, and first address-0 read one full cycle after release.
  The standalone phase test covers these external reset phases; architectural
  core and explicit-pipeline tests cover recognized-boundary PC/INTM/IF/control
  reset, execute-slot invalidation, trap recovery, clock-enable priority, and
  first-fetch priming. A dedicated actual-core test establishes nonzero ACC,
  T, P, AR0/AR1, ARP, DP, stack, OV, OVM, interrupt-pending, trap, and RAM
  state before reset; it distinguishes TI-defined effects from provisional
  retention under `OQ-012`. A 10-step BMC proves the exposed core reset
  transition for arbitrary reset/clock-enable inputs and reaches a nonzero-
  ACC/OVM reset cover at step 5. `instruction_valid_o` is now explicitly low
  during initialization/reset. A separate 40-step native-program-bus BMC
  leaves reset, clock enable, read qualification, and next address arbitrary;
  it proves boundary-only assertion, inactive address zero, the full release
  wait, first-read activation, `MEN`/phase relationships, and stall behavior.
  Its five-cycle reset/address-0/address-1 cover reaches step 34. Physical
  electrical timing and values for TI-unlisted state remain. The paired
  physical normalizer now makes those values reproducibly reviewable without
  using provisional RTL retention as an expected result, but no capture exists
  and no complete reset claim is made.
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
  `sim/interrupt/tb_interrupt_one_cycle_arrivals.sv`,
  `sim/interrupt/tb_interrupt_multicycle_arrivals.sv`,
  `sim/interrupt/tb_interrupt_native_sampling.sv`,
  `sim/interrupt/tb_interrupt_phase.sv`,
  `sim/interrupt/tb_sequential_pipeline_interrupt.sv`,
  `sim/interrupt/tb_sequential_pipeline_interrupt_mask_controls.sv`,
  `sim/interrupt/tb_sequential_pipeline_interrupt_one_cycle.sv`,
  `sim/interrupt/tb_sequential_pipeline_interrupt_multiply.sv`,
  `formal/tms32010_interrupt_dint.sby`,
  `sim/differential/test_interrupt_model_rtl.py`,
  `sim/instruction/tb_bioz_rtl.sv`,
  `tests/asm/dint_interrupt_race_probe.asm`,
  `tests/regressions/test_toolchain.py::ToolchainSliceTests::test_dint_interrupt_race_probe_image_is_stable`
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
  Four additional explicit cases pulse INT in both CALA and RET intervals and
  prove no early stack effect or service, selected-target completion, one
  protected retirement, and subsequent dummy/vector ownership under the
  `INFERRED` ADR-0003 address sequence.
  Paired 39-case core and explicit-pipeline matrices now sample a request while
  every supported ordinary one-cycle operation retires, excluding only the
  separately tested DINT/EINT mask controls. Each case proves current
  retirement/request capture, one safe protected retirement, dummy return-PC
  ownership, and stacked-PC/vector entry. The explicit matrix also proves the
  concurrent MEN fetch and exact registered internal-RAM read/write direction
  and address for every family.
  Four explicit mask-control placements now cover request arrival during EINT
  and DINT plus EINT and DINT in the already-protected slot. They prove
  program-only MEN ownership, request retention, ordinary versus dummy fetch
  classification, redundant-EINT nonextension, and eventual service. The
  protected-DINT cancellation assertion remains explicitly PROVISIONAL under
  `OQ-019`/`SC-039` and is not physical-device evidence.
  An 18-step actual-core BMC proves the same fixed protected-DINT cancellation,
  masked continuation, later EINT/protection, dummy, stack, and vector path
  under arbitrary bounded clock-enable stalls; its cover reaches step 9. This
  is implementation consistency only and cannot promote the provisional
  original-silicon ordering.
  The model also verifies that EINT protects a following RET long enough to
  pop/select the saved PC before an already-pending request schedules reentry.
  Figure 2-12's basic explicit path now discards N+2, performs entry with an
  empty execute slot, captures vector 2 without executing it, and defers the
  vector effect through independently stalled reads. MPY and MPYK in that
  protected slot now explicitly extend service through one more instruction;
  directed checks cover signed results, internal-read versus program-only bus
  shape, stalls, dummy discard, return-PC ownership, and vector deferral.
  Original SPRU001B and later mixed-family SPRU013 now have a recorded
  protected-N+1/dummy-N+1 timing conflict (`SC-039`). Both guides require or
  recommend external NMOS asynchronous conditioning. MAME cannot model the
  exact DINT race and pinned IKA predicts
  entry-wins. An exact synthetic program plus pulse/address/stacked-PC capture
  procedure now defines the original-NMOS evidence needed for `OQ-019`. The
  strict DINT capture classifier retains all port sequences, recomputes setup,
  low width, local CLKOUT period, and fall time from per-run measurements,
  validates sampled INT and exact ARM/DINT anchors, and requires 32 stable
  runs plus exact image/raw/photo/no-pulse/early/late calibration hashes. Six
  regressions cover every known candidate, an unanticipated sequence, pulse
  and sample failures, malformed windows, unstable runs, complete evidence,
  path traversal, and wrong images. No physical data is present.
  Physical setup/synchronizer behavior, PUSH/POP arrival cycles, physical
  confirmation of ADR-0003, and provisional DINT cancellation
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
- **Tests:** `sim/instruction/test_*`, `tests/asm/instruction_*`,
  `tests/asm/lst_arp_precedence_probe.asm`,
  `tests/asm/simultaneous_ar_update_probe.asm`,
  `tests/regressions/test_toolchain.py::ToolchainSliceTests::test_lst_arp_precedence_probe_image_is_stable`,
  `tests/regressions/test_toolchain.py::ToolchainSliceTests::test_simultaneous_ar_update_probe_image_is_stable`,
  `tests/regressions/test_simultaneous_ar_capture.py`
- **Notes:** First control/immediate slice (`LACK`, `NOP`, `ZAC`, `ROVM`,
  `SOVM`) passes model, RTL, toolchain, and differential tests. `DINT` and
  `EINT` now pass exact-opcode fixtures, model/tool/RTL state effects,
  one-cycle/program-only/clock-enable checks, native-phase retirement, and
  seeded INTM differential comparison. Four explicit-pipeline placements
  distinguish request-during-EINT/DINT and protected EINT/DINT while retaining
  the protected-DINT PROVISIONAL label. Interrupt recognition, EINT's
  following-instruction service deferral, Figure 2-12 external read order,
  and every represented supported-multicycle arrival position now pass
  directed checks under `CTRL-002`; complete execute-overlap and
  physical setup/synchronizer behavior remain open under `OQ-004`.
  `LST` now passes primary-cited database/tool support, exhaustive model
  status-field tests plus every ignored source position, directed RTL
  address/order/cycle/stall/trap checks,
  native-phase retirement, and seeded differential comparison. Original
  manuals' status-restore prose and `LST *,1` worked result admit opposing
  precedence readings. Later TI/MAME implement memory-wins and pinned IKA
  implements encoded-wins, so current memory-word precedence remains
  PROVISIONAL under `OQ-015`/`SC-009`. The exact 30-word two-direction fixture
  and physical procedure now define the resolving original-NMOS evidence. A
  strict classifier checks its exact image, three OUT anchors and exclusive
  port-7 writes, terminal window, 32-run agreement, and raw/photo hashes. Its
  shared `OQ-008` validator additionally binds exact source/listing/decoded
  trace and a complete single-specimen record while leaving acceptance open.
  Six regressions preserve both consistent hypotheses, both mixed directions,
  arbitrary other words, bad controls/markers/windows/images, and unstable
  repetitions. Mixed or other results never become resolved candidates, and
  no physical capture exists.
  `SST` now passes primary-cited database/tool support, exhaustive 32-state
  model packing tests, directed RTL page-one/address/update/cycle tests,
  native-phase and explicit-pipeline retirement, and seeded differential RAM/
  transaction comparison. Bits 12:9 and 7:2 are VERIFIED_PRIMARY fixed ones;
  reserved bit 1 and pre-update capture ordering are
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
  `OQ-017`/`OQ-018`. Contemporary patent evidence narrows the mechanism to a
  related Q4/Q1/Q2 intermediate path, following-state Q3 shift, and earlier
  ALU-derived status, but differs in cycle accounting. Two exact assembler
  fixtures now define the required original-NMOS dependency and overflow-stage
  captures without assigning an expected result. Their shared specimen
  validation now binds exact source/listing/image, normalized trace, test
  context, and package/date/lot provenance without choosing an outcome.
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
  The paired physical-capture normalizer now makes that provisional behavior
  reviewable without using it as an expected result: it retains the complete
  valid scan, diagnostic value, and all EVM fields, and does not reject a
  qualified package for differing RAM/register effects. No physical data is
  present and the fixed baselines alone cannot complete `OQ-014` acceptance.
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
  following MPY/MPYK uses the generic recognized retirement boundary, and the
  paired 39-case core and explicit-pipeline matrices cover request arrival
  while PAC retires, including its program-only explicit bus shape.
  `APAC` now passes primary-cited database/model/tool/RTL, one-cycle,
  native-phase, and randomized differential tests for exact `0x7f8f` decode,
  full-width P-plus-ACC results, sticky OV, both signed-overflow directions,
  OVM-clear wrap, OVM-set endpoint saturation, P/T/address preservation, and
  no data-memory transaction. Its retirement can end generic multiply
  deferral; paired core and explicit-pipeline matrices cover APAC-time arrival
  and its program-only explicit bus shape.
  `SPAC` now passes primary-cited database/model/tool/RTL, one-cycle,
  native-phase, and randomized differential tests for exact `0x7f90` decode,
  full-width ACC-minus-P results, sticky OV, both signed-overflow directions,
  OVM-clear wrap, OVM-set endpoint saturation, P/T/address preservation, and
  no data-memory transaction. Its retirement can end generic multiply
  deferral; paired core and explicit-pipeline matrices cover SPAC-time arrival
  and its program-only explicit bus shape.
  `RET` now passes primary-cited exact decode, hand fixture, assembler/
  disassembler, model/RTL/differential, bus, stall, interrupt-boundary, and
  bounded-formal tests for its old-TOS PC load, four-level
  pop with old-bottom duplication, two-cycle total, state preservation, and
  protected execution after EINT before pending interrupt reentry. The model
  intentionally omits physical bus detail; the explicit wrapper implements
  ADR-0003 at CORROBORATED confidence for RET under `OQ-007`; original-part
  pin confirmation remains open.
  `CALA` now passes primary-cited exact decode, independent hand fixture,
  assembler/disassembler, model/RTL/differential, bus, stall, interrupt-
  boundary, and bounded-formal tests for its opcode-PC+1 stack
  push, `ACC[11:0]` target, upper-ACC exclusion, PC wrap, nested old-bottom
  loss, state preservation, and two-cycle total. Its model trace intentionally
  remains abstract while the explicit wrapper uses the `INFERRED` ADR-0003
  bus mapping under `OQ-007`.
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
  needed to resolve it. The primary EVM's refusal to place a breakpoint at the
  following word corroborates `N+1` address visibility but does not assign it
  to an interval or distinguish repeated from advancing prefetch. The new
  capture analyzer independently classifies both opcodes across every run,
  retains the exact interval values and primary-source conflicts, fails closed
  on malformed/truncated/unknown sequences, and recomputes all evidence hashes.
  Its synthetic regressions are measurement-tool qualification, not RTL/native
  instruction qualification.
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
  model-qualified single-word/two-cycle stack instructions remain outside
  RTL/native qualification. CALA/RET now implement ADR-0003's reversible
  CORROBORATED-RET/INFERRED-CALA mapping; PUSH/POP remain blocked on address
  ownership under `OQ-016`. Maintain one subtask per timing family.

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
  deferral, multiply deferral, a 32-case matrix, and four CALA/RET arrival
  cases over all represented intervals of 17 supported multicycle families
  are directed-tested. A
  four-case native test additionally proves digital falling-boundary ownership
  from each modeled subphase, including a stalled phase 2, while physical
  setup/CDC, PUSH/POP arrivals, and physical confirmation of ADR-0003 remain.
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
  CALA/RET are primary-confirmed one-word/two-cycle computed control
  operations. The explicit pipeline implements ADR-0003's reversible
  `INFERRED` discarded-`PC+1` then selected-target mapping. Directed tests
  cover both stalls, nonexecution, target capture, retirement-only stack
  effects, differential state/cycles, interrupt arrivals, and a bounded core
  proof; physical confirmation remains open under `OQ-007`/`SC-037`.
  PUSH/POP are model-asserted as
  primary-confirmed one-word/two-cycle instructions with exact state effects.
  `MEN` activity in both execution intervals is constrained by TI's general
  pin rule, but the address and fetched-word ownership remain open under
  `OQ-016`/`SC-018`; `docs/research/push_pop_bus_experiment.md` defines the
  resolving original-device trace. `tools.trace.push_pop_capture` now provides
  the deterministic H1/H2/H3 classifier, exact-image/decoded-trace checks, and
  shared traversal-safe single-specimen `OQ-008` provenance validation,
  including numeric program-memory access time; six regressions exercise every
  hypothesis, conflicting strobes/data, truncation, inconsistent repetitions,
  exact-image rejection, seven-artifact completion, and complete/malformed
  packages. A structural cross-workflow regression now proves that all nine
  physical classifiers invoke the shared validator, keep
  `acceptance_complete=false`, and do not retain private listing validators.
  No original-NMOS capture is present, so this advances evidence readiness
  only.
  SUBC's one-cycle total is asserted
  only with the documented ACC-free following instruction; dependency
  behavior remains `OQ-017`. TI's 1982 simulator stop code 9950 corroborates
  that contemporary reference software rejected the prohibited dependency,
  but does not establish a physical result or subphase. The related-patent
  timing and two stable physical
  probes are documented in `docs/research/subc_pipeline_experiment.md`. The
  strict `tools.trace.subc_capture` classifier checks exact big-endian images,
  OUT-fetch/write ordering, the dependency probe's known comparator without
  assigning its first word, all four bit-15 OV pairs, 32-run consistency, and
  traversal-safe raw/photo provenance. The overflow fixture explicitly loads
  ARP zero so `OQ-012` reset retention cannot enter its SST consistency check.
  Six regressions retain unexpected dependency results, mask disputed SST bit
  1, and reject wrong anchors,
  controls, fixed fields, comparators, images, or packages. No production
  capture exists, and `review_ready` cannot change confidence. The original
  TMS32010-20 clock envelope is now
  primary-qualified as 48.78–150 ns per master period and 47.5–52.5% pulse
  duration; electrical delays are wrapper constraints, not RTL delays.

## Milestone 16 — External wait-state behavior

### TIMING-002 — Stall protocol and stability

- **Status:** COMPLETE
- **Priority:** P0
- **Dependencies:** BUS-001, BUS-002, BUS-003
- **Description:** Define and verify the synchronous platform phase-pause
  adaptation used when an FPGA integration cannot complete a represented bus
  phase at the nominal host-clock rate. This is not a native READY protocol.
- **Acceptance criteria:** zero and multiple host-clock holds produce identical
  architectural results; phase, address, control, and write data remain stable;
  no sample or retirement occurs early; execution resumes within a directed
  finite bound after re-enable. Any unbounded liveness claim requires an
  explicit eventually-enabled environment assumption.
- **Documentation:** `docs/timing/bus_cycles.md`,
  `docs/timing/native_phase_contract.md`
- **Tests:** `sim/bus/tb_wait_states.sv`,
  `formal/tms32010_program_bus_reset.sby`,
  `formal/tms32010_pipeline_table.sby`,
  `formal/tms32010_pipeline_table_write.sby`
- **Notes:** Original 40-pin TMS32010 has no READY/WAIT input. Research safe
  physical clock adaptation is resolved under OQ-001 to bounded slowing only:
  TMS32010-20 master-clock periods must remain 48.78–150 ns with 47.5–52.5%
  pulse duration. Do not invent a native wait protocol. The unified directed
  test inserts 16 host clocks across ordinary
  MEN, IN/DEN, OUT/WE, TBLR/MEN, and TBLW/WE phases and compares the final
  state with a zero-pause run. Existing transaction-specific tests independently
  exercise live-read sampling and deferred commit.

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
  precedence under `OQ-015`/`SC-009`; this is consistency evidence despite the
  opposing original-example/IKA hypothesis. LT cases compare
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
  A focused CALA/RET differential compares model and RTL PC, ACC, all four
  stack levels, retirement, and cumulative cycles through a complete computed
  call/return path. The model bus trace stays abstract; the independent
  explicit-pipeline bus test owns ADR-0003 address evidence.
  A focused IN/OUT differential compares direct and indirect transfers,
  opcode-plus-I/O transaction order, exact two-cycle totals, RAM results,
  port/data direction, PC, and AR/ARP post-updates.
  A focused TBLR/TBLW differential compares opcode, discarded, table, and
  repeated-following program addresses, three-cycle retirement, MEN/WE
  direction, RAM and program-memory effects, PC, and all four stack levels.
  A strict ROM-free MAME debugger-trace adapter now compares pre-PC alignment
  and following-boundary PC/ACC/P/T/AR0/AR1/stack/OV/OVM/INTM/ARP/DP state,
  with synthetic tests for parsing, state normalization, sentinel alignment,
  safe command generation, and mismatch diagnostics. It records pinned-source
  commit `030fefcbd14e47c01ec9d67655be90f64a1dc8ab` separately from the local
  packaged `0.287 (mame0287-dirty)` executable and does not treat that binary
  as an exact-commit build. MAME identifies Hard Drivin's device as a 20 MHz
  TMS320C10, so it remains a secondary functional oracle, not original-part
  or timing proof. A ROM-free live trace now constructs the Hard Drivin'
  machine with exact-sized all-zero placeholders, requires wrong-checksum
  diagnostics, debugger-injects the hand-fixed combined PUSH/POP/CALA/RET
  fixture, and matches ten model steps across eleven MAME rows. It
  corroborates architectural stack and computed-control state but cannot
  resolve `OQ-007` or `OQ-016` because the debugger exposes no bus cycles.
  Script launchers are rejected so the recorded SHA-256 identifies the actual
  trusted emulator binary rather than only its wrapper.
  Firmware comparison and legal randomized full-ISA streams remain; no
  authorized Hard Drivin' ROM is present. MAME disagreement creates research
  work, not an automatic oracle verdict.

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
- **Notes:** Six actual-core configurations pass bounded checks over
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
  A 24-step actual-core CALA/RET configuration checks both boundaries,
  opcode-PC+1 push, old-top pop/target, target and returned instructions,
  program-only ownership, no early stack effect, and arbitrary clock-enable
  stalls; its complete call/return cover reaches step 9.
  An 18-step actual-core protected-DINT configuration samples a request during
  NOP, follows the current PROVISIONAL DINT-cancels policy, proves ordinary
  masked continuation with the request retained, then reaches later EINT,
  protected retirement, dummy entry, stack push, and vector selection. Its
  complete cover reaches step 9 under arbitrary bounded clock-enable stalls.
  It proves implementation consistency, not original-silicon priority under
  `OQ-019`/`SC-039`.
  A separate standalone 12-step BMC leaves all fetch/execute register inputs
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
  An eighth 10-step actual-core configuration leaves recognized reset and
  clock enable arbitrary. It proves deterministic initialization, reset
  priority, PC/INTM/IF/trap/cycle effects, inactive transaction/instruction
  qualification, documented OVM retention, and the explicitly provisional
  retention bundle under `OQ-012`. Its fixed `SOVM; LACK 0x5a` cover reaches
  nonzero retained ACC/OVM after reset at step 5. It does not prove native RS
  phasing, internal-RAM retention, or original-silicon values for unlisted
  state.
  A ninth 40-step standalone native-program-bus configuration leaves logical
  reset, clock enable, program-read qualification, and next address arbitrary.
  It proves four-phase progression, synchronous assertion without premature
  read abort, recognized inactive/address-zero state, one-complete-cycle
  release delay, first-read activation, `MEN` qualification, sample pulses,
  and stall behavior. Its five asserted cycles followed by address-0 and
  address-1 reads reach cover step 34. It does not prove electrical timing or
  that an external environment satisfies physical reset duration.
  A tenth one-step combinational configuration leaves both 16-bit multiplier
  operands arbitrary. It exhaustively proves the ordinary signed product,
  unique original-hardware exception, commutativity, and zero/unity
  identities; four independent covers reach the exception and signed
  boundaries at step 0. It does not prove instruction sequencing, address
  selection, physical timing, or technology mapping.
  A separate one-step combinational configuration leaves two 32-bit
  accumulator operands, add/subtract selection, and OVM arbitrary. It proves
  modulo results, signed overflow, and positive/negative saturation against
  an independently widened 33-bit mathematical reference. Four covers reach
  every operation/direction saturation boundary at step 0. It does not prove
  instruction decode, operand selection, sticky OV, sequencing, or timing.
  Another one-step combinational configuration leaves the 16-bit input word
  and four-bit shift count arbitrary. It proves all 1,048,576 signed
  extension/zero-fill/left-shift combinations against an independent bit-
  indexed reference and reaches sign/count boundaries at step 0. It does not
  prove decode, addressing, ALU effects, or instruction timing.
  A second shifter configuration leaves the full 32-bit ACC and three-bit
  SACH field arbitrary. It independently assembles every legal stored bit,
  proves exact zero/one/four qualification and ACC[11:0] independence, and
  reaches six primary/boundary/invalid covers at step 0. Its invalid zero is
  implementation policy; decode, addressing, writes, and instruction timing
  remain outside the proof.
  An eleventh standalone internal-RAM configuration passes six-step base case
  and temporal induction. It leaves initial memory arbitrary, quantifies a
  symbolic address across all 144 qualified words, and leaves both write
  paths arbitrary under active-address-valid and mutual-exclusion interface
  assumptions. It proves both read-after-write paths, non-target preservation,
  all 256 validity results, and the portable invalid-read-zero policy. Five
  covers reach word 0, word `0x8f`, non-target writes, and invalid `0x90`/`0xff`
  reads. It does not resolve original-silicon `OQ-002`, power-up contents,
  instruction address selection, electrical timing, or technology mapping.
  A twelfth one-step decoder configuration leaves all 16 instruction bits
  arbitrary and proves the exact partial-RTL valid predicate against a compact
  family/field formula, plus dense-operation and meaningful operand-projection
  invariants. Nine covers reach legal direct/indirect, primary-reserved,
  simultaneous-update, pattern-mismatch, primary-unlisted, RTL-supported
  CALA/RET, and MPYK-extreme words at step 0. This does not prove mnemonic identity,
  execution, timing, unsupported silicon behavior, or the four deferred native
  cycles.
  A thirteenth 16-step standalone configuration leaves the Driver Sound host
  address, function code, direction, byte strobes, and legal event spacing
  arbitrary. Under explicit alternating-edge, idle-only assertion,
  completion-owned ordinary release, and fully settled VPA-release assumptions,
  it proves captured controls, exact `/VPA`/`/DTACK`/`/RVF`/write-enable/select
  equations, one-hot target routing, pre-edge and registered completion
  ownership, VPA suppression, stable held state, and no held-`/AS` retry.
  Whole-word read/write covers reach step 8 and the complete VPA path reaches
  step 9. This is bounded common-clock adapter evidence, not raw-pin CDC,
  electrical timing, open-bus, byte-policy, or board-side-effect proof.
  A fourteenth 12-step board-hierarchy configuration pauses DSP execution and
  selects one symbolic `/SOUNDRD`, whole-word `/SOUNDWR`, partial
  `/SOUNDWR`, `/LATCHES`, `/SPEECH`, or `/IRQCLR` transaction with symbolic
  data/address bits. Contradictory explicit callbacks prove timing-mode
  isolation. Assertions check pre-completion read data/masks, exact S7
  mailbox/control effects, both original-MC68000 duplicated-byte orientations, speech
  non-effect, no early state change, and invalid-carrier clamping. Seven covers
  reach solver step 10. This is a fixed legal common-clock sequence with the processor paused,
  not arbitrary event-spacing, raw-pin, collision, byte, or electrical proof.
  The canonical runner sorts only top-level `formal/*.sby` sources; a repository
  regression prevents recursively generated SymbiYosys outputs from becoming
  accidental configurations.
  The current runner passes all 64 BMC/cover tasks from 32 checked-in
  configurations, including the standalone SACH output-shifter, stack, and
  auxiliary-counter relations. The stack proof leaves every existing entry, push word, and
  control arbitrary, proves hold/push/pop/table-final/invalid-control results,
  and reaches six step-0 covers; it assigns no instruction or external-cycle
  ownership. The counter proof leaves every input/control bit arbitrary,
  independently derives low-nine-bit carry/borrow, proves upper-bit
  preservation and validity, and reaches six step-0 covers; it assigns no
  selected-register, instruction, timing, or dual-control silicon behavior.
  SymbiYosys v0.67-4-gfea6e46 with Bitwuzla 0.9.1 was used. Arbitrary DINT
  placement and original-silicon priority, the other indirect MPY control/
  update cases, arbitrary chain placement/length, formal multicycle-arrival
  coverage, general
  FSM and remaining integrated decode/RAM/arithmetic properties, and
  liveness
  assumptions remain.
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
- **Notes:** Fifty-eight-instruction RTL, explicit fetch/execute phase engine,
  multiplier, and
  144-word RAM are
  qualified in both synthesis flows; exact current utilization, internal Fmax,
  slack, warning scope, and generic-cell totals are recorded in
  `synthesis/qualification.md`. All harness exclusions are enumerated and
  TimeQuest reports zero unconstrained categories; this is still not wrapper
  I/O closure. Yosys 0.67+111 from the 2026-07-29 OSS CAD Suite passes
  structural/generic synthesis. Generic technology mapping still lowers the
  registered array to flip-flops/muxes, while Quartus recognizes one M10K.
  `make synth-yosys` now reproducibly checks both the
  synthesis harness (15,844 generic cells/128 checks) and the directly
  targeted
  exact-B/BANZ/BV/BIOZ/CALL/accumulator-branch/IN/OUT/TBLR/TBLW/interrupt
  pipeline slice (15,850 generic cells/128 checks),
  each with zero structural problems. The Quartus harness now elaborates that
  explicit pipeline rather than the legacy fail-closed wrapper. Retained
  table direction and state-driven sampled-operand selection first
  removed the wrapper decoder from that mux cone without changing a processor
  boundary:
  ADR-0004 then phase-stages internal-RAM reads and forwards same-address
  writes. Decoder-provided internal-data-family metadata then replaces two
  reconstructed core operation whitelists; its 65,536-word simulation and
  one-step symbolic checks make the optimization independently reviewable.
  One retained core-program carrier now replaces the separate execute/branch/
  table data registers and the state-selected mux. Directed BANZ/TBLR traces
  prove capture before consumption, replacement at the next executable fetch,
  and carrier stability across pauses; the existing table read/write formal
  paths retain their exact external and retirement behavior. The retained-
  carrier fit used 1,393 ALMs/400 registers/one M10K/one DSP and
  measured 20.034 ns/12 levels from the retained core-program word to ACC.
  Sharing the proved accumulator arithmetic relation across seven instruction
  paths reduced the fit to 1,332 ALMs with the same register, M10K, and DSP
  counts. Extracting the independently proved input shifter left those
  resources unchanged; extracting the separately proved SACH output shifter
  and retaining its decode-legality invariant produced the preceding 1,372-
  ALM fit. Sharing the proved stack relation across five current owners
  produced the preceding 1,352-ALM fit. Sharing the proved low-nine-bit
  auxiliary counter across current indirect owners produces the current 1,362
  ALM fit with 400 registers, one M10K, and one DSP. It closes a 25 MHz
  constraint with +17.838 ns worst setup and +0.164 ns worst hold slack across
  all analyzed corners and reports 45.12 MHz worst slow-corner Fmax. The
  reproducible 100 °C full path measures 21.476 ns/14 levels from retained
  program data to ACC; the standalone counter block is not the endpoint
  relation. Extracting the storage-free status-word relation leaves those
  Quartus resources and timing figures unchanged. Generic Yosys re-optimizes
  the current hierarchy to 15,844 cells/128 checks in the synthesis harness,
  15,850/128 in the direct pipeline, 15,899/135 in the generic MiSTer wrapper,
  and 3,786/413 in the six-memory Driver Sound hierarchy; the standalone
  status relation itself is zero-cell wiring/constants.
  An unforwarded M10K experiment failed the back-to-back IN/OUT data contract;
  an in-process bypass experiment lost RAM inference. Both were rejected.
  The board's primary-documented clock is 20 MHz. A rejected exploratory
  explicit-pipeline fit missed the old 50 MHz objective by -9.098 ns worst
  setup; 50 MHz closure is not claimed. All 415 non-clock harness pins remain
  virtual/false-pathed and TimeQuest reports zero unconstrained categories.
  A fourth standalone script exhaustively tests and synthesizes the
  A044427 storage-free bus decoder to 15 generic combinational cells with no
  structural problems. A fifth script retains the 4K-by-16 board adapter as
  one synchronous-read, single-write-port abstract memory with 85 total cells
  and zero structural problems. A sixth pre-technology script checks the
  standalone storage-free sample-ROM adapter as 18 abstract cells with three
  checks and zero structural problems. A seventh script checks the raw DAC
  latch as 14 cells/two checks with no memory, latch, or structural problem. An
  eighth script checks the port-4/5 LS74 output-control path as 33 cells/four
  checks with no memory, latch, or structural problem. A ninth pre-technology
  script checks the partial processor/program/communication/sample-ROM/DAC/
  output-control/BIO/host-control/host-timing/port-3-latch/mailbox/masked-read
  board top; its current six-memory count is recorded below and in
  `synthesis/qualification.md`. A tenth
  pre-technology script checks the standalone communication-RAM and
  sound-address path as 82 abstract cells, seven retained checks, and one
  retained 512-by-16 memory with zero structural problems. An eleventh script
  checks the standalone explicit-enable BIO divider/resampler as 52 cells,
  seven retained checks, no memory or latch, and zero structural problems.
  A twelfth script checks the address-encoded LS259 host-control adapter as 53
  cells/six checks. A thirteenth script checks the port-3 LS374 adapter as 19
  cells/five checks. A fourteenth script checks both whole-word mailboxes and
  LS74 flags as 259 cells/ten checks. A fifteenth script checks the
  storage-free `/READSTAT` mapper as 23 cells/eight checks. A sixteenth checks
  the storage-free raw `/SWITCHES` mapper as 10 cells/six checks. A seventeenth
  checks the masked low-host-read selector as 72 cells/13 checks. An eighteenth
  checks the same-clock host-timing adapter as 142 cells/24 checks. A
  nineteenth checks the storage-free local-68000 memory decoder as 56
  cells/17 checks. A twentieth composes that decoder into the storage-free
  timing/callback bridge as 305 hierarchy cells/40 checks. Nine additional
  Hard Drivin' targets bring the board/core command to 30 scripts; their
  current counts and scopes are recorded in `synthesis/qualification.md`.
  A thirty-first standalone script maps the shared signed accumulator
  add/subtract and OVM-result block to 367 generic cells with no storage,
  latch, retained check, or structural problem. This is portable synthesis
  evidence only; the exhaustive relation is qualified separately by formal.
  A thirty-second standalone script maps the shared signed input shifter to 89
  generic cells with no storage, latch, retained check, or structural problem;
  its exhaustive relation is qualified separately by formal.
  A thirty-third standalone script maps the SACH output shifter to 86 generic
  combinational cells with no storage, latch, retained check, or structural
  problem; its full-ACC/field relation is qualified separately by formal.
  A thirty-fourth standalone script maps the four-level stack transition
  relation to 92 generic combinational cells with no storage, latch, retained
  check, or structural problem; its exhaustive stack/control relation is
  qualified separately by formal.
  A thirty-fifth standalone script maps the low-nine-bit auxiliary-counter
  relation to 54 generic combinational cells with no storage, latch, retained
  check, or structural problem; its exhaustive value/control relation is
  qualified separately by formal.
  A thirty-sixth standalone script reduces the status pack/extract relation to
  pure connections and constants with zero generic cells and no storage,
  latch, retained check, or structural problem; its exhaustive bitfield
  relation is qualified separately by formal.
  This is not a Quartus mapping or completed sound-board fit.
  Instruction-complete resources, pin-level wrapper constraints, and final
  board timing remain.

## Milestone 20 — MiSTer-compatible wrapper

### INTEG-001 — Generic MiSTer-facing wrapper

- **Status:** IMPLEMENTING
- **Priority:** P1
- **Dependencies:** TIMING-001, SYNTH-001
- **Description:** Adapt the native interface to clock-enable operation,
  synchronous memories, optional SDRAM, callbacks, interrupts, BIO, trace, and
  deterministic simulation hooks.
- **Acceptance criteria:** wrapper preserves native timing, passes integration
  simulations, and contains no Hard Drivin'-specific processor behavior.
- **Documentation:** `docs/integration/mister_wrapper.md`
- **Tests:** `sim/bus/tb_mister_wrapper.sv`
- **Notes:** Vendor resources are permitted only behind this boundary. The
  first portable `tms32010_mister` adapter now supplies active-high
  deterministic initialization plus a distinct synchronous processor-reset
  request with an exact five-machine-cycle modeled RS hold,
  clock-enable operation, registered same-clock program/I/O request-ready
  callbacks, native phase visibility, active-low INT/BIO pass-through, and
  deterministic state/RAM debug ports. A directed callback test uses
  registered responders, late-response phase-3 holds, a separate global
  pause, IN/OUT, an exact-once TBLW program write, documented cycle totals,
  unsupported-word parking, and reset recovery. Yosys reports 15,899 generic
  cells/135 checks with no structural problems. This is an IMPLEMENTING
  milestone: asynchronous SDRAM CDC/adaptation, a full
  instruction pipeline, Quartus wrapper timing, and board integration remain.

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
- **Documentation:** `docs/integration/hard_drivin_requirements.md`,
  `docs/integration/hard_drivin_communication_ram.md`,
  `docs/integration/hard_drivin_sound_rom.md`,
  `docs/integration/hard_drivin_sound_control.md`,
  `docs/integration/hard_drivin_bio.md`,
  `docs/integration/hard_drivin_compare.md`,
  `docs/integration/hard_drivin_local_memory.md`,
  `docs/integration/hard_drivin_direct_io.md`,
  `docs/integration/hard_drivin_local_reset.md`,
  `docs/integration/hard_drivin_main_address_decode.md`,
  `docs/integration/hard_drivin_main_bus_timing.md`,
  `docs/integration/hard_drivin_host_control.md`,
  `docs/integration/hard_drivin_host_timing.md`,
  `docs/integration/hard_drivin_host_reads.md`,
  `docs/integration/hard_drivin_host_mailboxes.md`,
  `docs/research/hard_drivin_mailbox_byte_audit.md`,
  `docs/research/hard_drivin_sample_rom_population_audit.md`,
  `docs/research/hard_drivin_dac_code_audit.md`,
  `docs/research/hard_drivin_switch_input_audit.md`,
  `docs/research/hard_drivin_program_rom_strap_audit.md`
- **Tests:** `sim/programs/hard_drivin_smoke/`,
  `sim/bus/tb_hard_drivin_sound_bus_decode.sv`,
  `sim/bus/tb_hard_drivin_sound_program_ram.sv`,
  `sim/bus/tb_hard_drivin_sound_mister.sv`,
  `sim/bus/tb_hard_drivin_sound_communication_path.sv`,
  `sim/bus/tb_hard_drivin_sound_rom_path.sv`,
  `sim/bus/tb_hard_drivin_sound_dac_latch.sv`,
  `sim/bus/tb_hard_drivin_sound_output_control.sv`,
  `sim/bus/tb_hard_drivin_sound_bio_generator.sv`,
  `sim/bus/tb_hard_drivin_sound_host_control.sv`,
  `sim/bus/tb_hard_drivin_sound_320_port_latch.sv`,
  `sim/bus/tb_hard_drivin_sound_mailboxes.sv`,
  `sim/bus/tb_hard_drivin_mc68000_write_word.sv`,
  `sim/bus/tb_hard_drivin_sound_read_status.sv`,
  `sim/bus/tb_hard_drivin_sound_switches.sv`,
  `sim/bus/tb_hard_drivin_sound_host_read_mux.sv`,
  `sim/bus/tb_hard_drivin_sound_host_timing.sv`,
  `sim/bus/tb_hard_drivin_sound_local_memory_decode.sv`,
  `sim/bus/tb_hard_drivin_sound_local_memory_bridge.sv`,
  `sim/bus/tb_hard_drivin_sound_local_ram.sv`,
  `sim/bus/tb_hard_drivin_sound_direct_io.sv`,
  `sim/bus/tb_hard_drivin_main_address_decode.sv`,
  `sim/bus/tb_hard_drivin_main_bus_control.sv`,
  `sim/bus/tb_hard_drivin_main_dtack_decode.sv`,
  `sim/bus/tb_hard_drivin_main_duart_timing.sv`,
  `sim/bus/tb_hard_drivin_main_hsbus_timing.sv`,
  `sim/bus/tb_hard_drivin_main_rvas_timing.sv`,
  `sim/bus/tb_hard_drivin_main_sound_reset_decode.sv`,
  `sim/bus/tb_hard_drivin_main_sound_reset_timing.sv`,
  `sim/bus/tb_hard_drivin_sound_local_reset_source.sv`,
  `sim/bus/tb_hard_drivin_sound_local_reset_interlock.sv`,
  `formal/hard_drivin_main_dtack_decode.sby`,
  `formal/hard_drivin_main_address_decode.sby`,
  `formal/hard_drivin_main_sound_reset_decode.sby`,
  `formal/hard_drivin_main_rvas_timing.sby`,
  `formal/hard_drivin_sound_direct_io.sby`,
  `formal/hard_drivin_sound_local_reset_source.sby`,
  `formal/hard_drivin_sound_local_reset_interlock.sby`,
  `formal/hard_drivin_sound_communication_byte.sby`,
  `formal/hard_drivin_sound_program_byte.sby`,
  `formal/hard_drivin_sound_host_routing.sby`,
  `tests/regressions/test_hard_drivin_dac_codes.py`,
  `tests/regressions/test_hard_drivin_program_roms.py`,
  `tests/regressions/test_hard_drivin_sample_roms.py`,
  `tests/regressions/test_documentation.py`
- **Notes:** Atari production drawing A044427 Rev A is identified. Its
  TMS32010 `INT` pin connects to pull-up net `PR1` and is held inactive-high
  by `R26` (1 kΩ), while `/320BIO` is generated from 1 MHz divider logic and
  resampled by `CLKOUT` before reaching `/BIOS`. The distinct `320IRQ` net
  feeds the 68000-side interrupt path. A044427 has no program-RAM arbiter:
  independent `/320RES` and `/320RAM` buffer enables require reset during host
  access, and overlap is invalid contention. Its native write decode also
  diverts TBLW addresses `0x000`–`0x007` to output ports. The storage-free
  board decoder exhaustively verifies all 4,096 addresses and all ownership
  states. A same-clock FPGA storage adapter now host-loads and TMS-reads all
  4,096 16-bit words, preserves contents across adapter reset, commits safe
  high-address TMS writes, diverts low writes to I/O, and grants neither side
  during invalid overlap. Firmware compliance/release timing remains
  `OQ-021`. The later original-MC68000 audit below resolves the physical byte
  capture value under `SC-022`/`OQ-022` while leaving firmware use open.
  A physical coincident-edge policy, signed-audio DAC interpretation,
  effective mute semantics, board-variant audit, 68000 bus adaptation, and
  complete peripheral integration remain.
  The current local-SRAM reset-interlock acceptance slice requires exhaustive
  pass/block truth-table simulation, symbolic proof, an actual 8,192-clock
  integrated scrub-to-release transition, immediate re-clamp on initialization
  or board reset, strict lint, standalone and board Yosys checks, and explicit
  documentation that the output is an FPGA platform policy rather than a
  physical 6264 or portable-TMS reset behavior.
  The partial `hard_drivin_sound_mister` now connects the core, native decoder,
  shared program RAM, and communication path. A directed RTL test host-loads
  the fixed ROM-free smoke and a synthetic communication word,
  performs the safe reset handoff, verifies its 12 retirements/22 cycles and
  nine physical I/O transfers, then reloads a focused low-TBLW sequence and
  proves one I/O commit with unchanged RAM word 3. A second five-cycle
  `LACK 0; TBLW 0x11; NOP` sequence deliberately holds external port-0
  readiness low, captures internal data `0x00a5` once as raw DAC code `0x00a`,
  and proves by host readback that program word zero remains `0x7e00`. This
  regression exposed and fixed board-top logical readiness incorrectly using
  the external callback instead of the selected internal DAC target.
  A044427 sheets 2, 3, 5, and 7 plus newly pinned TI SDLS119 establish the two
  LS74 halves at 100H. Port 4 captures TD0 and exposes complementary
  `MUTE=/Q`; its only Rev-A analog consumer is explicitly not loaded, so
  `SC-027`/`OQ-027` prohibit treating the raw net as an effective mute. Port 5
  presets data-independent `320IRQ`, host `/IRQCLR` clocks grounded D to clear
  it, and `/320RES` clears both Q states. The standalone RTL exhausts all
  65,536 port-4 and port-5 words, priority, reset, commit, and isolation cases;
  the integrated smoke forces external backpressure on both targets, captures
  raw MUTE low, asserts IRQ, clears it through the host callback, and restores
  MUTE high on reset.
  A044427 sheets 1, 2, and 4 plus TI SDLS060/SDLS119 establish the complete
  BIO source and resampler: cascaded LS161s preload `0xce`, count through
  `0xff`, and produce a one-1-MHz-period active-low source every 50 periods;
  separate LS74 70S samples that level on CLKOUT. Board `/RESET` clears only
  the source LS74, so counter and resampler phase are not invented. Standalone
  RTL uses two noncoincident enables, caller-seed and pin validity, and passes
  the full fifty-state/reset/five-sample test plus self-qualification from all
  256 possible seed values. The board top now connects it as an explicit
  opt-in while leaving external raw BIO as the default, derives its CLKOUT
  sample enable from the core's actual modeled phase, and rejects a coincident
  1 MHz schedule by assertion under `OQ-028`. The integrated BIOZ fixture holds
  external BIO high, selects a qualified generated low, takes only target
  `LACK 0x22` in three cycles, and propagates release only on a later CLKOUT
  sample.
  A044427 sheet 7 plus the AMD
  Am6012 data book now establish the raw port-0 mapping as `TD15:TD4` to
  uncomplemented `B1:B12`; pinned MAME's additional bit-11 XOR conflicts with
  that wiring and remains isolated under `SC-019`/`OQ-020`. The complete
  positive-reference network, grounded complementary output, inverting
  2.2-kOhm current stage, and 1-uF AC coupling confirm that Rev-A does not hide
  a single-bit digital conversion. Historical MAME 0.62 already interpreted
  the DSP word as signed; the 2016 AM6012 migration preserved that behavior
  and only then added the schematic-inversion comment while modeling symmetric
  references. No cited alternate drawing/ECO accompanies it. A deterministic
  helper now exhausts raw/MAME code mapping and ideal nominal transfer; TM-327
  walking-ones/ramp and authorized-game capture criteria are fixed in
  `hard_drivin_dac_code_audit.md`. No RTL changed and the default audio
  transform remains blocked pending physical or authorized-game evidence. The
  first ROM-free
  model/tool smoke program now covers
  raw accesses to every mapped port role, an asserted-BIO branch, exact
  program/I/O transaction traces, a 22-cycle total, the primary raw DAC code,
  the distinct pinned-MAME transform, and an explicit synthetic port-2
  sentinel. A044427 sheets 3, 5, and 8 plus newly pinned TI SLCS007K establish
  that `/CMPRD` connects only `CMPOUT` to `TDI15`, while the complete
  microphone/LM311 source and pull-up sheet is marked `THIS SHEET NOT LOADED.`
  The production sixteen-bit read therefore remains `OQ-029`; MAME's returned
  zero is isolated as `SC-029`, and the existing external callback remains the
  honest wrapper boundary. User-supplied ROM
  hashes may enable local tests; ROMs are never committed.
  Sheets 3, 5, and 6 plus TI's original LS191/LS259 data sheets now establish
  the separate 512-by-16 communication RAM: CRAMEN low grants DSP port-1
  read-only access at `SA8:SA0`, CRAMEN high grants host read/write access at
  `A9:A1`, and reset clears CRAMEN to DSP ownership. Port 7 loads the shared
  16-bit sound address, every input-read trailing edge increments it, and port
  6 holds a separate ROM-block nibble. Pinned MAME's unconditional DSP RAM
  visibility, selective port-0/1-only increment, and byte merge remain
  `SC-023` through `SC-025`. Rev-A sheet 4 resolves the former `/CPORT`
  uncertainty: LS374 50L captures `TD7:TD0` and host `/320PORT` enables the
  byte onto `D15:D8`. Pinned MAME logs the DSP write and returns zero from its
  host stub (`SC-030`), while undriven host `D7:D0` remain `OQ-030`. The standalone
  FPGA communication path now exhaustively host-loads and DSP-reads all 512
  words, rejects the non-owning side, preserves storage across initialization,
  tracks explicit counter/block validity, verifies global port-2 increment and
  16-bit wrap, and proves port 3 does not alter address control. Its pre-technology Yosys target
  retains one memory in an 82-cell hierarchy with seven checks. The board top
  now routes processor port 1 internally, proves it ignores an external
  sentinel, verifies `0x3456` to `0x3459` global increments, and reads the
  retained word back after processor reset.
  Sheets 5 and 6 plus official TI LS138/LS244/LS374 data sheets establish that
  the sample-ROM path is parallel: port 6 selects one of twelve drawn 64K-byte
  positions, the shared pre-increment `SA15:SA0` addresses a byte, and port 0
  returns `{{2{byte[7]}}, byte[6:0], 7'b0}`. Pinned MAME omits the duplicated
  sign bit (`SC-026`). The smoke fixture now derives physical byte `0xd5` as
  `0xea80` and selects populated Hard Drivin' block 3 rather than the Rev-A
  unpopulated block 11. Population and absent-block reads remain `OQ-026`.
  The storage-free sample-ROM adapter now exhaustively checks all 16 block
  values, 65,536 addresses, 256 byte values, explicit presence/validity,
  readiness stalls, exact sign mapping, and target isolation; Yosys reports 18
  cells/three checks with no latch or structural problem. The board top routes
  port 0 internally, ignores the external unsigned-MAME sentinel, holds
  block 3/address `0x3457` through three unready clocks, commits synthetic byte
  `0xd5` exactly once as `0xea80`, and advances the shared counter only on that
  commit. The raw DAC adapter exhausts all 65,536 input words and captures only
  `data[15:4]`; the board top acknowledges port-0 output independently of the
  external callback and commits smoke word `0xf230` once as uncomplemented code
  `0xf23`, never MAME's `0x723`. Address-zero TBLW is separately executed under
  forced external backpressure and captures raw code `0x00a` without changing
  shared program word zero. Standalone Yosys reports 14 cells/two checks;
  the output-control adapter reports 33 cells/four checks. Integrated Yosys
  reports 2,966 abstract cells/257 checks and retains the same three memories.
  A044427's exact socket matrix is now fixed as A-row blocks 0–5 and C-row
  blocks 6–11. TM-356 identifies `A046491-02` and prescribes
  `136052-3125` at `45A`/block 2 when needed plus `136077-1017` at
  `45C`/block 8. Pinned MAME instead places the 45C file at packed logical
  block 4; this unresolved firmware/emulator conflict is `SC-044`. The
  content-free authorized-image helper accepts only explicit physical sockets,
  produces a sparse 12-bit presence mask, and never promotes a file into
  board-population proof. Exact factory population, firmware block writes,
  and absent-selection electrical data remain `OQ-026`; no RTL behavior
  changed because the existing wrapper already exposes the primary sparse
  physical mask.
  Full 68000 bus adaptation, authorized sample storage, optional
  populated-compare/DAC-analog/effective-mute peripherals, exact Rev-A port-2
  electrical data, and physical timing remain acceptance work.
  A044427 sheet 3 plus TI SDLS086 establish the host low-I/O LS138 and LS259
  `80R`: `/LATCHES` is the write quadrant at `A13:A12=01`, `A3:A1` selects Q,
  `A4` supplies its value, and host data is ignored. Board `/RESET` clears all
  raw outputs, including `CRAMEN=Q3` and `/320RES=Q4`. The standalone adapter
  verifies every selection/value, per-bit validity, reset, retention, and
  reset-over-write priority; Yosys reports 53 cells/six checks. The board-top
  opt-in preserves external defaults, exposes selected Q4/Q3 validity, and
  passes a synthetic program/communication-memory handoff while opposite
  external sentinels are ignored. Sheet 3 and Motorola M68000UM Ninth Edition now
  establish the missing high-address and timing gates: LS138 `30P` Y4 makes
  `/RVF` from asserted `/AS`, `A23=1`, and `A16:A14=100`; LS138 `30N` requires
  both `/RVF` and `/RVAS`; and the shared-8-MHz F74 sequence creates one
  `RVA`/`/DTACK` period at S4 while holding `/RVAS` through the S7 data-latch
  edge. The path has no READY input or held-`/AS` retry. Its exact edge table
  and FPGA requirements are cited in `hard_drivin_host_timing.md`; complete
  electrical propagation/loading margin and unreset power-up transients remain
  `OQ-033`. The standalone same-clock logical adapter now uses explicit
  8 MHz and `/AS` events with no READY input. Its regression exhausts 8,192
  alias/address/direction/quadrant transactions and directs VPA, byte-strobe,
  delayed-release, no-retry, and FPGA-initialization cases; its pre-edge S7
  event outputs keep same-clock state consumers on the physical trailing-edge
  boundary. Yosys reports 142 cells/24 checks with no latch or structural
  problem. The board-top opt-in now drives all four masked read quadrants and
  routes S7 `/SOUNDRD`, whole-word `/SOUNDWR`, `/LATCHES`, and `/IRQCLR` to
  the existing adapters. Partial `/SOUNDWR` is disclosed and rejected under
  `OQ-031`; `/SPEECH` remains a side-effect-free trace completion. Directed
  integration checks external-callback isolation, all eight target quadrants,
  exact masks, and S7 side effects. Integrated Yosys retains three memories at
  2,966 cells/257 checks. It does not claim raw-pin CDC, open-bus policy, or
  electrical closure. At that checkpoint, the
  127/231/38/42/5/10 regression split, strict lint across 30 modules, all
  twenty Yosys targets, all 33 hashes, and all 28 formal tasks from fourteen
  configurations pass. The host adapter's 16-step proof uses an explicit
  legal same-clock event contract and reaches read, write, and VPA covers; the
  12-step board proof reaches seven covers across all six implemented routing
  classes and both partial-byte orientations.
  Atari TM-327 is now
  pinned and records local-68000 program/program-RAM tests plus TMS32010
  communication-RAM, IRQ, DAC, tune/sweep, and block-latch diagnostics as
  future synthetic qualification targets. The new standalone
  `hard_drivin_sound_320_port_latch` exhausts all
  65,536 words and every non-target/commit/direction case, preserves explicit
  invalid startup state, and exports fixed driven mask `0xff00` separately
  from captured-data validity. Its Yosys target reports 19 cells/five checks.
  The board top treats port 3 as internal no-wait hardware: the smoke OUT
  exposes masked carrier `0xa500`, and low-address TBLW later exposes
  `0x3000` from word `0xf230` exactly once while program RAM remains unchanged.
  `/SOUNDRD`, `/SWITCHES`, and `/READSTAT` are now schematic-traced, but their
  full host bridge, side effects, and partial-lane/open-bus policy remain
  acceptance work. Sheet 2 plus TI SDLS165B/SDLS119 now establish the two
  complete-word LS374 mailbox directions and LS74 20S pending flags. The
  standalone whole-word callback exhausts every 16-bit value in both
  directions, preserves reset-independent data, clears flags on accepted
  opposite-side reads, and explicitly invalidates coincident preset/clear or
  preset/read-clock conditions instead of assigning an undocumented priority.
  Pinned MAME corroborates ordinary handshakes but its local byte merge is
  isolated as `SC-031`/`OQ-031`. The board top now retains both directions
  behind explicit whole-word main/sound-CPU completion callbacks, exports all
  data/flag validity and conflict state, and verifies nominal traffic, both
  conflicts, requalification, and board-reset data retention without claiming
  a complete bus.
  The storage-free `/READSTAT` mapper separately preserves the exact raw
  `MAINFLAG`/`SOUNDFLAG`/`SOUND.TEST`/`/TIRDY` order on `D15:D12`, exports fixed
  driven mask `0xf000`, and tracks per-source validity without assigning a
  value to the physical low twelve lanes. All 256 source/value-validity
  combinations pass, and standalone Yosys reports 23 cells/eight checks.
  MAME's fixed test/ready/low-lane values remain `SC-032`. The board top now
  drives its flag lanes from the mailboxes, retains raw external test/ready
  inputs, and passes exact data/mask checks through all integrated transitions.
  Pre-technology board synthesis reports 2,966 cells/257 checks/three
  memories. The complete 125/231/38/39/5/10 regression
  split, strict lint, all seventeen Yosys targets, all 30 pinned reference
  hashes, and all 24 tasks from twelve formal configurations pass at this
  checkpoint.
  A044427 sheet 3 plus TI's LS244 function table now establish the exact raw
  `/SWITCHES` order: `J3-11`, `J3-9`, `J3-8`, and `J3-7` drive host
  `D15:D12` without inversion. The storage-free adapter exhausts all sixteen
  source nibbles and all sixteen validity masks, retains fixed driven mask
  `0xf000`, and assigns no invented cabinet meaning or idle state under
  `OQ-032`. SP-327 cockpit and SP-360 Race Drivin' compact main wiring both
  show the `044427-XX` Sound PCB's normal harness groups but no J3 cable or
  cabinet device. A044427 ties J3-1/J3-2 to ground but gives each signal only
  a 1-kOhm series resistor and capacitive shunts; TI does not specify an open
  LS244 input state. TM-327/TM-329 identify `A046491-01`, while newly pinned
  TM-351 identifies later `A046491-02` without resolving its J3 population.
  Thus the reviewed cabinets have no documented J3 functions, a matching
  platform leaves all four source-valid bits clear, and physical open values
  plus other variants remain `PARTIALLY RESOLVED_PRIMARY`. Standalone Yosys
  reports 10 cells/six checks. Cross-checking pinned MAME
  exposed its swapped `/SWITCHES`/`/320PORT` handler names and two zero stubs;
  `SC-033` requires Atari LS138 `30N` order. The board top now connects this
  source and composes all four low reads behind a qualified combinational
  selector while keeping `/SOUNDRD` clear as a separate completion callback.
  The standalone mux checks invalid selection, exact one-hot order, distinct
  masks, arbitrary invalid input bits, and every driven lane; Yosys reports
  72 cells/13 checks. Integrated
  tests use live source state and prove selection has no side effect. Complete
  `/RVF`/`/RVAS`/DTACK/open-bus integration remains separate. The full
  125/231/38/39/5/10 regression split, strict lint, all seventeen Yosys
  targets, all 30 hashes, and all 24 formal tasks pass at this checkpoint.
  The timing-enabled board regression preserves external-callback
  fallback, overrides only the selected local paths when opted in, reads all
  four masked targets through S6, applies `/SOUNDRD`, word or normalized-byte
  `/SOUNDWR`, `/LATCHES`, and `/IRQCLR` at S7, reports accepted byte writes,
  and exposes `/SPEECH` without a side effect. The complete current
  127/231/38/43/5/10 regression split and strict lint across 31 modules pass;
  all twenty-one Yosys targets and all 33 hashes pass. Formal qualification now
  comprises 28 tasks from fourteen configurations: the standalone adapter
  proof is bounded to 16 steps, and a separate 12-step board-routing proof
  checks seven covers across all six implemented timing-derived transaction
  classes and both partial-byte orientations with the DSP paused.
  The board top now selects the complete local-memory bridge whenever host
  timing is enabled. Lower Y5 drives the existing program RAM at `A12:A1`
  with an S7 whole-word commit; Y6 drives the existing communication RAM at
  `A9:A1` under unchanged CRAMEN ownership; and upper Y5 remains a separately
  exported direct `/PDEN`/`/PWE` path with its write callback at S6. Synthetic
  board cycles prove program and communication write/readback, opposite
  explicit-callback isolation, upper-Y5 non-aliasing, mirrored authorized-ROM
  callbacks, and lane-valid local-SRAM reads plus an upper-byte S7 commit.
  Timing-disabled tests continue to exercise the original explicit storage
  callbacks. The explicitly selectable local SRAM now uses independent 8K-by-8
  data memories and a two-bit-per-word validity memory. It scrubs validity over
  exactly 8,192 clocks without resetting either data array, reports readiness
  and blocked pre-ready writes, preserves the external callback as the default,
  and suppresses that callback while selected. Standalone tests cover every
  address, independent byte validity, complete writes/reads, and re-scrub;
  board cycles prove external-sentinel isolation and independent byte writes.
  Integrated Yosys retains six memories and reports 3,786 abstract cells/413
  checks with no structural problem. At that checkpoint, partial lower-Y5 and
  Y6 writes were reported and rejected pending inactive-lane evidence under
  `OQ-022`/`OQ-024`; the later original-MC68000 audits below supersede both
  protective policies with target-specific duplicated-byte evidence.
  A044427 sheet 5 now qualifies upper-Y5's asymmetric downstream decode:
  LS139 reads ignore `RA11:RA2` and alias modulo four, while LS138 writes
  require `RA11:RA3=0` and select no target above canonical word 7. A
  storage-free adapter exhausts all 4,096 addresses in both directions,
  masks port-2 to the sole drawn bit 15, leaves port 3 undriven, and formally
  proves the full combinational contract. The board top routes canonical host
  writes into the existing address/block/DAC/CPORT/control consumers at S6,
  composes masked port-0/1/2/3 reads, increments the shared address at S7, and
  suppresses/reports active host/TMS I/O overlap under `OQ-021`. Pinned MAME's
  symmetric `offset & 7` alias remains `SC-034`. Standalone Yosys reports 336
  cells/seven checks. Raw-pin CDC, authorized ROM storage, and open-bus policy
  remain acceptance work. The reset-interlock slice now preserves separate
  raw MC68000 RESET and HALT inputs, gates both only for initialization or an
  incomplete selected
  scrub, exhausts all 32 Boolean cases, symbolically proves the policy, and
  demonstrates release after the real 8,192-clock board scrub. Standalone
  Yosys reports 13 cells/seven checks; integrated Yosys reports 3,786 cells/
  413 checks. A044427 sheet 2 plus TI SDLS043 now resolve the populated raw
  source's stable logic: `/MRES` and decoded `/SRES` retrigger LS123 `100N`,
  the 47 kΩ/10 µF network calculates to about 155.1 ms nominal typical, and
  separate 7406/pull-up branches drive equal logical RESET/HALT requests after
  combination with `SOUND.RESET`. A standalone parameterized tick-domain
  reconstruction covers deterministic startup, both triggers, direct reset,
  paused ticks, exact expiry, early ignored retriggering, and later accepted
  retriggering; its 10-step BMC and 14-step five-class cover tasks pass, and
  default-parameter Yosys reports 28 cells/seven checks.
  SP-327 sheets 4/7 and A044427 sheet 1 now trace `/MRES` to a buffered main
  `/RESET` input and completely resolve `/SRES`: a write-only, `/AS`- and
  `/RVAS`-qualified `0x84c000..0x84ffff` mirror with A13:A0 and UDS/LDS absent
  from the decode. The standalone high-address module exhausts 8,192
  address/control cases, passes a one-step proof with four covers, and
  synthesizes to 16 cells/four checks. MAME's canonical-only mapping is
  `SC-036`. SP-327 sheet 4 now also resolves both logical hold chains. Normal
  S2 high-phase `/AS` assertion asynchronously presets early `/RVAS0` on S3
  falling; S4 rising creates one-period `RVA` and presets `/RVAS`; and the
  falling-edge-sampled `/DTACK` low-to-high clock releases both D=0 F74s
  unless the `/RVAS0` preset is active. The standalone event-domain RTL
  covers normal and low-phase assertion, preset priority, missed-low continued
  hold, late recovery, and deterministic FPGA reinitialization; its 12-step
  BMC and 16-step seven-class cover pass, and Yosys reports 93 cells/25
  checks. The complete sheet-4 combinational
  `/DTACK` cone is also transcribed: `/VPA`, ordinary-RVA, HSBUS wait, DUART,
  and final F11 terms are exhaustively tested over all 4,096 raw inputs,
  proved in one step with six covers, and synthesize to 21 cells/eight checks.
  A composed test checks the synthetic sound-reset write from `/AS` capture
  through `/SRES` release. A second composition checks the S2/S3 early HSBUS
  path, zero-wait acknowledgement, independent GSP/MSP wait extensions,
  raw-select deassertion, and later sampled release. A044425 Rev-J sheets 10
  and 15 plus TI SPVU001 qualify both wait inputs as direct TMS34010 `HRDY`
  outputs and resolve their general polarity/selection protocol. SP-327 sheet
  6 plus Motorola ADI988R1 now qualify `/RDUART` as MC68681 `CS`, the
  3.6864 MHz device clock, and pulled-up active-low open-drain `/DUDTACK`.
  The composed DUART test preserves arbitrary external latency, late ACK,
  raw-select release with a still-low device pin, and sampled hold release.
  SP-327 sheet 4 plus TI SDLS014/SDLS013A now resolve the main primary LS138,
  RAM-region LS139, and `/RVAS0`-qualified HSBUS LS139. The standalone decoder
  exhausts all 1,024 consumed `A23:A14` values with both `/AS` and `/RVAS0`,
  explicitly tests ignored-bit mirrors and canonical MAME windows, passes a
  one-step proof with six covers, and synthesizes to 49 cells/20 checks. It
  exposes all active-low outputs, including unconnected Y1/Y2 and Y2/Y3,
  without assigning peripheral-internal register behavior.
  The address-driven `hard_drivin_main_bus_control` hierarchy now composes
  that decoder with the held-strobe and `/DTACK` blocks. A directed test
  reaches mirrored GSP, canonical waited MSP, mirrored late-acknowledged
  DUART, and ordinary expansion-bus cycles through complete release; Yosys
  reports 185 hierarchy cells/64 checks. Peripheral response latency, phase
  adaptation, raw CDC, and electrical timing remain explicitly external.
  The original system `/RESET` driver, workload-specific TMS34010 latency,
  exact cross-clock phase, raw CDC, and electrical timing remain `OQ-036`.
  Production RC tolerance, power-up behavior, board-top timebase selection,
  raw-input CDC, and the future MC68000-core interface remain `OQ-035`, so this
  is not pin-level reset timing.
  A044427 sheets 3-5 plus TI's LS138/ALS32 data sheets now establish the
  local-68000 ROM and high-bank decode. The drawn 27256 pair uses
  `A15:A1` and is selected throughout `A23=0`; LS138 `30P` ignores `A22:A17`
  and assigns Y4-Y7 to low I/O, the Y5 program/direct-I/O bank,
  communication RAM, and local 6264 RAM. A13 further splits Y5 through raw
  `/RAMCE`, `/PWE`, and `/PDEN` controls. The standalone storage-free decoder
  exhausts 131,072 control/alias/lane combinations and synthesizes to 56
  abstract cells/17 checks with no memory or latch. Pinned MAME's canonical
  windows and wider declared ROM region remain `SC-034`. A044427 sheet 3 and
  AMD publication 08005 Rev A now resolve the option topology: E1 supplies
  the 27256 VPP pin from +5 V, while E2 makes the compatible 27512 pin an A16
  extension. Released MAME sets declare 0x8000-byte lanes and the Panorama
  prototype declares 0x10000-byte lanes, but no reviewed assembly publication
  marks the fitted link or installed device. The deterministic authorized-
  image analyzer hashes/interleaves lanes and distinguishes information-
  bearing 27512 halves without ever claiming a physical strap. `OQ-034` is
  therefore `PARTIALLY_RESOLVED_PRIMARY`; exact board/variant population
  remains open. This is decode and option-topology evidence, not a
  68000, memory storage, or raw-pin timing implementation.
  The storage-free timing bridge now consumes the host adapter's captured
  direction/address/lanes. Synthetic end-to-end cycles verify valid and
  unavailable ROM reads, explicitly invalid unwritten SRAM, complete and
  upper-byte SRAM writes at S7, Y5 program and direct-I/O paths, Y6
  communication callbacks, high-bank aliases, and Y4 isolation. Direct
  `/PWE` commits at its S6 trailing edge; SRAM callbacks commit at S7. The
  bridge synthesizes to 305 hierarchy cells/40 checks with no storage or
  latch. It neither supplies copyrighted contents nor inserts READY/open-bus
  behavior. Board-top callback selection and the optional integration-specific
  local SRAM are now verified as described above; a complete upper-Y5 direct-
  I/O bus path remains acceptance work.
  OQ-031 is now `PARTIALLY_RESOLVED_PRIMARY`: A044427 LS138 `20P` generates
  `/MAINWR` locally for physical alias `0x840000..0x843fff`; neither that
  decode nor local `/SOUNDWR` uses the available MC68000 byte enables. SP-327
  proves `/EWEU` and `/EWEL` reach the expansion connector, and Motorola
  Table 3-1 proves the original MC68000 duplicates the selected byte across
  both halves of `D15:D0`. Both mailbox directions therefore capture
  `{byte, byte}`, not MAME's retained-other-byte merge. The new combinational
  `hard_drivin_mc68000_write_word` adapter exhausts all 65,536 data words in
  word, upper-byte, and lower-byte modes plus the no-strobe state; Yosys
  reports 39 mapped cells/three checks. Timed local writes now accept both
  byte orientations, set `SOUNDFLAG`, and retain a one-event byte-transfer
  diagnostic. The board routing BMC proves both symbolic orientations, and
  integrated Yosys reports 3,786 cells/413 checks/six memories. LS74 preset
  dominance is primary-verified while asserted, but exact preset-release/
  opposite-read-clock coincidence and authorized-firmware byte-write use
  remain open. The external main callback still expects an already captured
  complete word; no raw main bus or CDC bridge is claimed.
  OQ-024 is now `PARTIALLY_RESOLVED_PRIMARY`: the same original-MC68000 Table
  3-1 rule and A044427's common `/CRWE` prove that a communication-RAM byte
  write clocks `{byte, byte}` into the two HM6116 banks. The timing-derived Y6
  path now reuses `hard_drivin_mc68000_write_word`; directed board readback
  checks lower `0xef -> 0xefef` and upper `0xbc -> 0xbcbc`. A new 7-step BMC
  proves arbitrary address/data capture and reaches both symbolic lane covers.
  Pinned MAME's retained-other-byte `COMBINE_DATA` remains `SC-025` conflict,
  while authorized-firmware access widths, raw CDC, HM6116 electrical timing,
  and substitute-68k inactive lanes remain open. The timing-disabled callback
  stays an already captured complete-word contract. Integrated Yosys remains
  3,786 cells/413 checks/six memories with zero structural problems.
  OQ-022 is now `PARTIALLY_RESOLVED_PRIMARY`: original-MC68000 Table 3-1 and
  A044427's common `/RAMWR` prove that a lower-Y5 program-RAM byte write clocks
  `{byte, byte}` into all four SRAM slices. The timing-derived lower-Y5 path
  reuses `hard_drivin_mc68000_write_word`; directed board readback checks upper
  `0xde -> 0xdede` and lower `0xef -> 0xefef`. A new 7-step BMC proves arbitrary
  address/data capture under legal reset-qualified host ownership and reaches
  both symbolic lane covers. Pinned MAME's retained-other-byte `COMBINE_DATA`
  remains `SC-022` conflict, while authorized-firmware access widths, reset-
  handoff compliance, raw CDC, asynchronous SRAM electrical timing, and
  substitute-68k inactive lanes remain open. The timing-disabled callback
  stays an already captured complete-word contract.

## Milestone 22 — Release qualification

### REL-001 — Evidence and license audit

- **Status:** IMPLEMENTING
- **Priority:** P0
- **Dependencies:** all preceding milestones
- **Description:** Audit instruction/timing completeness, regressions, formal,
  synthesis, interfaces, tool reproducibility, provenance, licensing,
  documentation, realistic programs, and integration.
- **Acceptance criteria:** every release-ready criterion in `AGENTS.md` has a
  linked reproducible artifact and no undisclosed blocker.
- **Documentation:** `docs/release_evidence.yaml`,
  `docs/release_checklist.md`, `CHANGELOG.md`
- **Tests:** `make audit-release`, `make release-check`,
  `make evidence-current`, `tests/regressions/test_release_evidence.py`,
  `tests/regressions/test_release_command_evidence.py`
- **Notes:** A partial implementation must remain honestly versioned and must
  not be advertised as cycle-accurate. The first release-audit slice now
  checks tracked plus nonignored pre-commit candidates against an explicit
  policy: MIT license identity, prohibited output/cache paths, third-party and
  binary allowlists, generated/canonical-data inventory, and exact hashes of
  every manifest source marked `may_commit: false`. Six regressions cover the
  clean tree and fail-closed policy mutations. A second machine-readable
  inventory maps all 21 release-ready criteria to repository paths, executable
  `make` targets, and live task/open-question blockers. Its six regressions
  reject missing criteria/evidence, unknown commands/blockers, checklist drift,
  and premature release readiness. The current checked distribution is two
  `NOT_MET`, six `PARTIAL`, thirteen `PASS_CURRENT_SCOPE`, and zero
  `RELEASE_QUALIFIED`; `release_ready` is false. `make audit-release` passes,
  and the clean-tree `make evidence-current` runner binds the six current-
  scope audit/test/lint/formal/Yosys/Quartus commands and hashed logs to exact
  commit/tree IDs below ignored `build/`. Eight regressions enforce dirty-tree,
  failure-preservation, tamper, exact types, path confinement, and symlink
  boundaries. A
  local receipt is mutable execution evidence, not attestation or release
  qualification. `make release-check` remains intentionally failing because
  architectural, timing, formal, integration, and release evidence is
  incomplete.
