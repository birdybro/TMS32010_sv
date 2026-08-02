# Changelog

All notable project changes are documented here. The format is based on Keep a
Changelog, and the project follows semantic versioning once releases begin.

## [Unreleased]

### Added

- A 20-step actual-core direct-TBLR interrupt-arrival formal harness with a
  constrained symbolic choice across all three represented instruction
  cycles. It proves the discarded fetch, program-word-to-RAM transfer,
  committed-word readback through the protected instruction, table stack
  state, dummy fetch, stack push, and vector selection under arbitrary bounded
  clock-enable stalls.
- An 18-step actual-core unconditional-B interrupt-arrival formal harness with
  a symbolic choice between both documented execution intervals. It proves
  operand ownership, no midinstruction entry, resolved-target retirement, one
  protected instruction, dummy fetch, stack push, and vector selection under
  arbitrary bounded clock-enable stalls, while excluding unresolved physical
  branch pin timing.
- An 18-step actual-core protected-DINT formal harness with BMC and non-vacuity
  cover. Under arbitrary bounded clock-enable stalls it proves the current
  cancellation/retention policy, ordinary masked continuation, later EINT and
  protected word, dummy fetch, stack push, and vector selection while keeping
  OQ-019/SC-039 explicitly PROVISIONAL.
- A four-placement explicit-pipeline DINT/EINT interrupt matrix covering
  request arrival during each mask control and each mask control in the
  protected N+1 slot. It verifies program-only MEN ownership, pending-request
  retention, redundant-EINT nonextension, dummy/vector classification, and
  later service, while labeling protected-DINT cancellation PROVISIONAL under
  OQ-019/SC-039.
- A matching 39-case explicit fetch/execute interrupt-arrival matrix for every
  supported ordinary one-cycle family. It checks concurrent MEN program reads,
  exact registered internal-RAM read/write directions and addresses, protected
  retirement, dummy classification, stacked return PC, acknowledge, and vector
  capture; its representatives must match the core matrix and canonical ISA.
- A 39-case core-level interrupt-arrival matrix spanning every supported
  ordinary one-cycle operation except the separately qualified DINT/EINT mask
  controls. Each case checks current retirement with request capture, one safe
  protected retirement, nonexecuting return-PC dummy ownership, stacked PC,
  acknowledge state, and vector-2 selection.
- A clean-tree `make evidence-current` runner for local current-scope command
  receipts. It binds a fixed six-gate vector and SHA-256 log set to exact Git
  commit/tree IDs, records controlled environment and tool-version metadata,
  preserves later results after one failure, confines mutable outputs below
  ignored `build/release-evidence/`, and verifies revision/log/summary integrity
  without promoting release status.
- A machine-readable 21-criterion release-evidence inventory and fail-closed
  checker. Every criterion links repository evidence, runnable `make` targets,
  and live task or open-question blockers; the checked human-readable table
  must match its IDs and statuses exactly. The initial state contains two
  `NOT_MET`, six `PARTIAL`, thirteen `PASS_CURRENT_SCOPE`, and zero
  `RELEASE_QUALIFIED` criteria, so `release_ready` remains false.
- A machine-readable tracked-file license/provenance policy, deterministic
  `make audit-release` checker, and explicit release checklist. The checker
  covers pre-commit candidates, prohibited output/cache paths, generated and
  canonical data, third-party/binary allowlists, and all manifest hashes whose
  sources may not be committed.
- A reusable `tools.trace.specimen_evidence` validator for one original-NMOS
  specimen. It checks normalized-trace, exact source/listing, package/date/lot,
  custody/test-condition/tool-version, and distinct top/bottom/board-photo
  provenance while refusing to interpret mask identity.
- A strict paired `tools.trace.reset_retention_capture` workflow for `OQ-012`.
  It checks exact set/clear images and all 28 anchored outputs, measures BIO/RS
  routing and complete reset intervals, enforces the documented reset bus/OVM
  controls, requires all nine clock/hold combinations plus 32 nominal runs,
  and preserves every post-reset architectural field without expecting the
  provisional model result.
- Six reset-retention capture regressions covering all architectural fields
  and reserved SST bit 1, variable review-ready results, reset/BIO/bus timing,
  pre-state/markers/anchors/OVM, partial/extra/truncated flows, the condition
  matrix, provenance hashes, and wrong exact images.
- A paired `tools.trace.ram_invalid_write_capture` workflow for destructive
  `OQ-002` stage 2. It checks both exact images and 258-output streams, lists
  every valid-RAM disturbance, preserves direction-specific intended
  sentinels/readbacks, and requires a pinned qualified stage-1 report plus an
  explicit capture-order declaration.
- Six absent-RAM write-capture regressions covering both address directions,
  sentinel/zero/other readbacks, valid-array disturbance, partial/extra
  streams, markers/anchors/controls/windows, variable complete packages,
  prior-stage/order failures, and wrong exact images.
- A strict `tools.trace.ram_invalid_read_capture` workflow for nondestructive
  `OQ-002` stage 1. It checks the exact image, all 451 marker/predecessor/
  absent-read outputs and fetch anchors, 32 reset plus eight cold-power run
  identities, and complete raw/photo provenance without assigning a read
  value.
- Six absent-RAM read-capture regressions covering predecessor-tracking,
  history-independent, and history-dependent results; partial/extra streams;
  markers, legal predecessors, anchors, controls, and windows; variable
  complete packages; run-condition schemas/minima; and wrong exact images.
- A paired `tools.trace.ram_boundary_capture` workflow for `OQ-014`. It checks
  both exact DMOV/LTD images, all scan/diagnostic fetch-write framing, 32-run
  packages, EVM register-observation identity, and hashed raw/transcript/photo
  provenance while preserving every measured word and field.
- Six RAM-boundary capture regressions covering unchanged and corrupted valid
  scans, varying diagnostic words, partial/extra flows, malformed framing and
  register schemas, documented parallel-state differences, exact images,
  transcript linkage, complete packages, and the fixed-baseline acceptance
  boundary.
- A strict `tools.trace.simultaneous_ar_capture` workflow for `OQ-010`. It
  validates the exact 23-word raw-instruction image, forced-word/result fetch
  ordering, terminal/trailing capture window, 32-run agreement, and raw/photo
  provenance without adopting MAME or IKA as an original-part oracle.
- Six simultaneous-AR capture regressions covering all three complete update
  candidates, arbitrary complete sequences, three distinct partial
  noncompletion stages, malformed anchors/order/controls/markers/windows,
  unstable runs, exact images, complete packages, and the no-confidence-
  promotion boundary.
- A strict `tools.trace.lst_arp_capture` workflow for `OQ-015`. It validates
  the exact 30-word image, three OUT anchors and exclusive port-7 writes,
  terminal window, 32-run agreement, and raw/photo provenance without choosing
  MAME or IKA as an original-part oracle.
- Six LST-ARP capture regressions covering memory-word precedence, encoded-
  field precedence, both mixed directions, arbitrary other words, wrong
  anchors/order/controls/markers/images, unstable runs, complete packages, and
  the no-confidence-promotion boundary.
- A strict `tools.trace.dint_interrupt_capture` workflow for `OQ-019`. It
  preserves complete port sequences, recognizes cancel/original-N+2/early-N+1
  candidates without choosing among them, validates exact sparse image and
  fetch anchors, and recomputes electrical pulse qualification per run.
- DINT evidence-package checks for 50 ns setup, one local `CLKOUT` low width,
  15 ns maximum fall time, sampled INT consistency, 32-run repeatability,
  open-collector driver provenance, and hashed no-pulse/one-fetch-early/one-
  fetch-late calibrations, raw captures, and probe photographs.
- Six DINT capture regressions covering every retained candidate, a preserved
  unanticipated sequence, pulse/sample violations, strict schemas and race
  windows, unstable repetitions, exact images, complete packages, and path
  traversal.
- A strict `tools.trace.subc_capture` workflow for the two unresolved original-
  NMOS SUBC experiments. It checks independently fixed big-endian probe images,
  OUT-fetch/write ordering, exclusive port-7 outputs, 32-run consistency, and
  raw/photo provenance while preserving every measured word.
- Six SUBC capture regressions covering all three anticipated dependency low
  words plus an arbitrary other result, a bad legal comparator, all four
  overflow-stage pairs, status consistency, malformed anchors/order/windows,
  unstable runs, bad strobes, exact images, complete packages, and the no-
  confidence-promotion boundary.
- An integrity-pinned, non-committed 1982 TI *TMS32010 Simulator User's
  Guide* plus a source-scoped research note. It records the official
  instruction-acquisition versus program-ROM-read breakpoint distinction,
  256-state PC/ACC/AR trace, separate simulated clock counter, and SUBC
  dependency diagnostic without treating software-tool behavior as a silicon
  or external-pin trace.
- A documentation regression that locks the simulator source's provenance,
  page use, non-redistributable status, absent PUSH/POP bus evidence, and
  nonphysical SUBC-diagnostic boundary.
- A strict `tools.trace.push_pop_capture` workflow for the unresolved original-
  NMOS PUSH/POP bus experiment. It consumes one normalized row per falling
  `CLKOUT` boundary, independently classifies H1/H2/H3 for PUSH and POP,
  retains exact sampled intervals and source-conflict warnings, checks 32-run
  repeatability, and refuses malformed, truncated, duplicate-trigger, fixture-
  mismatch, or unclassified traces.
- A physical-evidence sidecar validator for the PUSH/POP workflow. It records
  device/board/clock/supply/memory/probe/analyzer identity, recomputes the exact
  program image plus raw-capture and probe-photograph SHA-256 values, constrains
  artifacts beneath an explicit root, and reports only `review_ready`; it
  cannot promote `OQ-016` to hardware-verified status.
- Seven regressions covering all retained PUSH/POP hypotheses, primary `MEN`
  conflict disclosure, active external strobes, fixture-data disagreement,
  strict CSV ordering/types, unique/trailing capture windows, mixed-run
  inconsistency, complete evidence packages, path traversal, and the documented
  claim boundary.
- A portable combinational `tms32010_status_word` pack/extract relation and
  one-step symbolic harness. The proof leaves every stored field and complete
  LST source word arbitrary, constructs SST independently by bit index,
  proves selection of source bits 15, 14, 8, and 0, and reaches five
  fixed-field and ignored-bit covers without assigning address, INTM, update,
  or timing behavior.
- A standalone zero-cell Yosys smoke target for the pure-wiring status-word
  relation.
- A portable combinational `tms32010_auxiliary_counter` relation and one-step
  symbolic harness. The proof leaves all 16 value bits and both controls
  arbitrary, derives low-nine-bit carry/borrow independently, proves upper-bit
  preservation and control validity, and reaches six wrap, ordinary, hold,
  and invalid-control covers.
- A standalone Yosys smoke target for the low-nine-bit auxiliary counter.
- A portable combinational `tms32010_stack` relation and one-step symbolic
  harness. The proof quantifies all four existing entries, the push word, and
  every control combination; proves hold, push/drop-bottom,
  pop/duplicate-bottom, table-final, and invalid-control behavior; and reaches
  six distinct covers.
- A standalone Yosys smoke target for the four-level stack relation.
- A portable combinational `tms32010_output_shifter` and one-step symbolic
  harness. The proof leaves the complete ACC and SACH field arbitrary, derives
  each stored bit independently for shifts zero, one, and four, proves
  ACC[11:0] independence, and reaches six primary/boundary/invalid covers.
- A standalone Yosys smoke target for the SACH output shifter.
- A portable combinational `tms32010_input_shifter` and one-step symbolic
  harness. The proof exhausts all 1,048,576 data/count combinations against an
  independent bit-indexed sign-extension/zero-fill reference and reaches
  shift-zero and shift-15 signed boundaries.
- A standalone Yosys smoke target for the input shifter.
- A portable combinational `tms32010_accumulator` block and one-step symbolic
  harness. The proof covers every pair of 32-bit operands, addition and
  subtraction, both OVM states, modulo results, signed overflow, and all four
  saturation directions against an independent 33-bit reference.
- A standalone Yosys smoke target for the shared accumulator arithmetic.
- A 7-step bounded program-byte composition check. It proves arbitrary
  address/data upper- and lower-byte writes through the original-MC68000
  normalizer into reset-qualified 4K program RAM and reaches both lane covers.
- A 7-step bounded communication-byte composition check. It proves arbitrary
  address/data upper- and lower-byte writes through the original-MC68000
  normalizer into the 512-word FPGA RAM and reaches both lane covers.
- `OQ-031` primary-source mailbox byte audit. It traces A044427 LS138 `20P`
  `/MAINWR` generation and physical `0x840000..0x843fff` alias, SP-327's
  exported `/EWEU`/`/EWEL`, both unqualified LS374 latch pairs, the
  original-MC68000 duplicated selected-byte rule, and the remaining LS74
  preset-release/read-edge uncertainty.
- A synthesizable `hard_drivin_mc68000_write_word` adapter plus an exhaustive
  regression covering all 65,536 data words in word, upper-byte, and
  lower-byte modes and the no-strobe state.
- `OQ-026` Driver Sound sample-ROM population audit. It transcribes the exact
  sparse A044427 socket-to-`/SR` matrix, identifies the complete Rev-A C row as
  not loaded, records the Race Drivin' field-upgrade population, and defines
  board/continuity/authorized-device/firmware evidence needed to close factory
  variants and absent-selection behavior.
- A content-free authorized sample-ROM inventory helper and four regressions.
  It accepts only explicit physical sockets and exact 64-KiB images, emits
  hashes plus the sparse 12-bit wrapper presence mask, keeps `45C` at block 8,
  rejects duplicate/unknown/wrong-size inputs, and never treats supplied data
  as proof of physical population.
- An integrity-pinned, non-committed Atari TM-356 first-printing upgrade-kit
  manual. It identifies `A046491-02`, prescribes E2 for the Race Drivin'
  deluxe-cockpit program-ROM upgrade, and places `136052-3125` at `45A` when
  needed plus new sample `136077-1017` at `45C`.
- `SC-044`, preserving the primary physical `45C`/block-8 wiring against
  pinned MAME's packed Race Drivin' region, where the same file is reachable
  as logical block 4.
- `OQ-034` Driver Sound local-program-ROM strap audit. It proves A044427's
  alternative E1/+5-V and E2/A16 topology, separates the drawn 27256 default
  from a pin-compatible 27512 capacity option, inventories released and
  Panorama MAME lane sizes, and defines the board-identified continuity and
  device-read evidence needed to close production population.
- A content-free authorized program-ROM analyzer and five regressions. It
  accepts only matching 27256- or 27512-sized lane images, hashes each lane
  and the correctly interleaved image, compares 32-KiB halves, and never
  promotes a file-size or mirror result into proof of a physical strap.
- An integrity-pinned, non-committed 1986 AMD Bipolar/MOS Memory Data Book as
  contemporaneous component-family evidence for 27256 VPP and 27512 A15 pin-1
  behavior. It is not evidence of the EPROM vendor installed by Atari.
- `OQ-032` Driver Sound J3 audit using complete Atari cabinet wiring rather
  than connector-name inference. It traces the no-discrete-pull RC network,
  proves that SP-327 Hard Drivin' cockpit and SP-360 Race Drivin' compact do
  not connect J3, distinguishes `A046491-01` from later `A046491-02`, and
  defines board-identified continuity/voltage/read captures for the remaining
  variants and physical-open value.
- Three integrity-pinned, non-committed primary Atari references: Hard
  Drivin' compact TM-329 second printing, Race Drivin' compact SP-360 first
  printing, and Race Drivin' cockpit TM-351 second printing.
- `SC-019`/`OQ-020` DAC-code lineage audit reconstructing the complete Rev-A
  positive-reference, current-output, transimpedance, and AC-coupling path;
  tracing MAME's sign-bit transform back to its first located 0.62 sound
  support; and defining a TM-327 walking-ones/ramp plus authorized-game
  capture that can distinguish a physical inverter from a software-only
  interpretation.
- A deterministic Driver Sound DAC trace helper and five regressions. It
  exhausts every 16-bit output word and low-nibble alias, keeps the primary raw
  Am6012 code separate from MAME's mapper code, checks the signed major
  boundary, and reproduces ideal nominal primary-component transfer points
  without labeling them measurements.
- Four integrity-pinned, non-committed historical MAME references: the 0.62
  Hard Drivin' sound handler, its generic signed-DAC function and changes
  attribution, plus the exact 2016 AM6012-migration snapshot.
- `SC-043` and an original-TMS32010 device-revision audit that separates
  publication revision, speed grade, package marking, tracking/date and lot
  fields, ROM siblings, and later CMOS devices from unproved silicon-mask
  identity. It records the exact lawful negative-search routes and defines the
  specimen provenance needed before any physical result is generalized.
- Integrity-pinned, non-committed copies of the October-1985-appended
  SPRU001B artifact, March-1989 SPRU013B, and April-1989 SPRU011A. A downloaded
  `TI32000` false positive is also checksum-cataloged as unrelated so every
  acquired artifact retains provenance and the route is not repeated.
- `SC-042` and complementary set/clear original-NMOS reset-retention probes.
  Each image exports ACC/T/P/AR/status/stack before reset, reconstructs every
  destructive observation, emits an armed marker, and uses external BIO alone
  to select a post-reset observer whose scratch data is written only after
  reset. The capture protocol assigns no original-silicon result.
- Primary EVM research showing that TI's warm-reset `EX`/`RUN` workflow saves
  every TMS32010 register except PC, alongside the same manual's separate
  clear/corruption warning and an explicit monitor-ordering nonclaim.
- `SC-041` and three stable original-NMOS absent-data-address probes. A
  read-only fixture sweeps `0x90`-`0xff` after controlled zero and all-one
  legal reads; ascending and descending fixtures write unique full-AR
  sentinels, scan all 144 valid words, and read all 112 absent selects. No
  absent value, alias, or retirement behavior is assigned.
- A metadata-only decap lead for a publicly indexed TMS320M10 die. Lawful
  retrieval returned HTTP 429 and the indexed subject is mask-ROM extraction,
  so it contributes no RAM-decoder claim and automation remains disabled.
- `SC-040` plus a stable original-NMOS simultaneous-INC/DEC raw-word probe.
  Original manuals leave the combination undefined, a later TI C1x card
  prohibits it, MAME and IKA independently choose no net AR update, and the
  related patent counter assumes mutual exclusion. The two-boundary fixture
  assigns no silicon result and preserves the current fail-closed decoder.
- Expanded `SC-009` plus a stable two-direction original-NMOS indirect-LST
  probe. The research now preserves the original guides' `ARP becomes 1`
  worked result against their memory-status restore contract, later C25/MAME
  memory-wins behavior, pinned IKA encoded-field-wins behavior, and related TI
  patent control background without assigning a silicon outcome. The fixture
  makes status bit 8 and encoded next ARP disagree in both directions.
- `SC-039` and an exact original-NMOS DINT/interrupt-race probe. The source
  conflict preserves original SPRU001B's executed N+1/dummy N+2 sequence
  against later mixed-family SPRU013's dummy N+1 sequence and separately
  records both guides' external-NMOS-synchronizer requirement/recommendation.
  It also isolates SPRU001B's self-contradictory set-INTM polarity sentence as
  a typo rather than race evidence.
  The synthetic handler exports its stacked return
  PC so cancellation, N+2 entry, and earlier N+1 entry remain distinguishable.
- Two stable, noncopyrighted original-NMOS SUBC probe images and a physical
  capture protocol. One distinguishes old, unshifted-intermediate, and final
  ACC visibility in TI-prohibited successor scheduling; the other isolates
  intermediate-only and final-shift-only overflow while checking OVM is
  ignored. Undefined observations deliberately have no expected result.
- Scoped US4577282A SUBC research showing a related Q4/Q1/Q2 unshifted-ALU
  path, following-state Q3 accumulator-local shift, and ALU-derived status.
  Its two-state wording and conflicts with pinned IKA/MAME keep production
  `OQ-017`/`OQ-018` unresolved.
- Two stable, noncopyrighted original-NMOS RAM-boundary probe images and a
  physical-capture protocol for `DMOV`/`LTD` source `0x8f`. The programs clear
  and scan all 144 valid words through port 7, expose an `0x90` read, preserve
  register results for EVM inspection, and assign no expected value to the
  undefined sample.
- `SC-038`, separating the verified 144-word/`0x00`-`0x8f` production range
  from SPRU001B's isolated `128-144` off-by-one table, a related patent's
  internally inconsistent row/column capacity, and incompatible storage
  policies in MAME and IKA32010.
- An integrity-pinned, non-committed copy of TI patent US4577282A plus a
  claim-boundary research note. Its related DSP embodiment explicitly
  describes RET's discarded sequential fetch, stack pop, return-address fetch,
  and target decode, while its omission of accumulator PUSH/POP prevents it
  from resolving `OQ-016`.
- A primary-cited EVM breakpoint analysis showing that the word after
  PUSH/POP is externally address-visible in a multicycle context, plus an
  explicit proof boundary: the address-driven breakpoint circuit supplies no
  `MEN` phase, repetition count, or later address and cannot choose OQ-016's
  three hypotheses.
- Directed branch/table traces that inspect the retained core-program carrier
  at operand capture, across clock-enable stalls, and after replacement by the
  selected or repeated instruction fetch.
- ADR-0004 defining phase-staged internal-RAM reads without another TMS32010
  machine cycle, including phase-1 operand validity, phase-0 same-address
  forwarding, standalone-core compatibility, and explicit nonclaims about the
  original silicon array.
- A directed registered-RAM test and a five-step symbolic proof covering all
  144 words, both write sources, untouched-word persistence, and same-address
  forwarding while leaving initial contents arbitrary.
- Decoder-provided internal-data-family metadata. Simulation visits all 65,536
  instruction words and compares every valid encoding; a one-step symbolic
  check covers the same valid space. Invalid encodings remain behaviorless and
  must still be qualified by the decoder valid output.
- A reproducible Quartus full setup-path reporter that writes twenty detailed,
  untracked paths with endpoints, logic depth, and routing/cell delay shares.
- Repository governance, build, research, model, RTL, verification, formal,
  synthesis, and integration directory framework.
- A ROM-free MAME instruction-boundary oracle adapter with strict debugger
  command generation, PC/post-state alignment, original-part width checks,
  explicit MAME stack-order normalization, deterministic diagnostics, seven
  synthetic differential regressions including exact-row and strict
  model-state validation, explicit interrupt-hook limitations, and separate
  pinned-source versus local dirty-binary provenance. It deliberately does not
  launch MAME, obtain ROMs, or claim cycle/pin evidence.
- An opt-in ROM-free MAME execution smoke using size-limited, all-zero,
  deliberately wrong-checksum placeholders; fail-closed debugger injection of
  a hand-fixed combined PUSH/POP/CALA/RET fixture; a finite-timeout live run;
  seven orchestration tests; and generated hash/result metadata. Ten model
  steps match eleven live TMS320C10 boundary rows while `/MEN`, cycle, pin,
  original-part, and Atari-firmware claims remain explicitly excluded.
- Reference-provenance policy, safe acquisition/hash tools, a 46-source
  integrity-pinned catalog, and living engineering backlog.
- Primary acquisition of Atari A044425 Rev-J supplemental Driver Main GSP and
  MSP sheets plus TI's 1988 TMS34010 User's Guide. The drawings connect each
  `/GSPWAIT`/`/MSPWAIT` net directly to its processor's `HRDY` output; TI
  qualifies high as ready, low as wait, and high whenever active-low `HCS` is
  inactive.
- Standard-library regression entrypoints and documentation consistency checks.
- Primary-cited programmer, memory, pipeline, interrupt, external-interface,
  instruction, and timing research baselines.
- Source-precedence ADR, ambiguity/conflict registers, and an initial
  schematic-led Hard Drivin' Driver Sound Board inventory.
- A provisional computed-control prefetch ADR that constrains CALA/RET RTL to
  an explicitly `INFERRED` discarded-`PC+1` read followed by selected-target
  fetch. It preserves the original every-cycle `/MEN` rule, the conflicting
  IKA idle-first sequence, and target-repeat as separate hypotheses; physical
  original-part confirmation remains open.
- CALA/RET decode and two-boundary core execution with retirement-only stack
  and PC effects, plus explicit-pipeline discarded-sequential/selected-target
  ownership under ADR-0003. Directed instruction, both-interval stall/bus,
  four-case interrupt-arrival, architectural differential, legacy-wrapper
  rejection, and 24-step bounded-formal checks preserve the mapping's
  `INFERRED` confidence and keep PUSH/POP out of RTL.
- A reproducible original-NMOS PUSH/POP pin-trace experiment, including a
  deterministic synthetic assembly image, stable opcode regression, competing
  bus hypotheses, required analyzer signals, artifact provenance, and explicit
  acceptance criteria for resolving `OQ-016`.
- Primary schematic qualification of the A044427 Rev-A TMS32010 pin paths:
  `/INT` is held inactive-high through `PR1`/`R26`, `/320BIO` is resampled by
  `CLKOUT` into `/BIOS`, and the separate `320IRQ` net belongs to the
  68000-side interrupt path.
- Primary manufacturer qualification of the A044427 DAC path using AMD's
  1983 analog-products data book, with separately pinned MAME DAC support
  sources and an explicit source-conflict record.
- Machine-readable ISA database that represents all 60 documented mnemonics;
  reserved/unmatched-word classification remains incomplete.
- Provenance-aware exhaustive opcode audit and generated count report. All
  65,536 words are partitioned into documented legal encodings, explicitly
  reserved indirect fields, unresolved simultaneous AR updates, documented-
  pattern mismatches, and encodings absent from TI's explicitly complete
  instruction summary without assigning unsupported silicon behavior.
- Structurally independent executable model with explicit-width state, raw
  image loading, logical fetch traces, deterministic JSON, and trap-on-unknown
  behavior for the initial eight-instruction slice.
- Independent hand opcode fixtures and decode/model boundary tests.
- Deterministic project-local assembler/disassembler slice with checked
  expressions, labels, origin/data/include directives, raw/hex/listing output,
  and lossless source round trips.
- A project-authored four-tap Q15 FIR program with independently fixed opcode,
  input, output, sample-history, cycle, program-fetch, and logical
  data-transaction expectations. It exercises the primary-documented
  `LTD`/`MPY` pipelined multiply/accumulate idiom without reproducing TI
  example source.
- A portable `tms32010_mister` integration layer with active-high synchronous
  reset, automatic five-machine-cycle modeled reset hold, same-clock
  program/I/O request-ready callbacks, registered phase-3 waits, native-phase
  visibility, interrupt/BIO inputs, and deterministic state/RAM debug ports.
  It contains no Atari-specific memory or peripheral behavior.
- A project-authored, ROM-free Hard Drivin' Driver Sound Board smoke program
  covering every working mapped I/O role, active-low BIO control flow, fixed
  opcodes, raw program/I/O traces, model state, and explicitly scoped MAME
  adapter expectations. Port 2 and the signed-audio DAC interpretation remain
  disclosed as unqualified rather than inferred from the fixture.
- A synthesizable, storage-free A044427 Rev-A bus decoder exposing physical
  program-RAM ownership, invalid host/running-DSP overlap, low-eight I/O
  selection, and the board's low-address TBLW/OUT alias, plus an exhaustive
  address/ownership test and standalone Yosys target.
- A synthesizable A044427 4K-by-16 same-clock program-RAM adapter with
  synchronous host/TMS reads, explicit write commits, reset-preserved
  contents, no-priority conflict rejection, complete 4,096-word host-load/TMS
  readback coverage, and a memory-retaining Yosys target.
- A partial `hard_drivin_sound_mister` top connecting the generic processor,
  board-native decoder, shared program RAM, and communication path, with
  physical I/O commit signaling, internal port-1 routing, whole-word
  communication host callbacks, and correct low-address TBLW readiness.
- Primary-transcribed Driver Sound communication-RAM and shared-address
  contract, backed by newly pinned TI LS191/LS259 component data sheets. It
  records 512-word CRAMEN ownership, read-only DSP access, port-7 load,
  every-input-read increment, and three explicit MAME abstraction conflicts.
- A standalone synthesizable Driver Sound communication path comprising a
  512-by-16 CRAMEN-selected host/DSP memory, read-only DSP port-1 view,
  shared 16-bit sound-address state, port-7 load, every-input-read increment,
  port-6 block latch, and explicit physical-state validity. Port 3 remains
  orthogonal to that address/RAM state and is modeled by its separate LS374.
- Primary-transcribed Driver Sound parallel sample-ROM wiring, backed by
  newly pinned TI LS138, LS244, and LS374 data sheets. The contract identifies
  twelve decoded 64K-byte positions, exact pre-increment addressing,
  population validity, and the physical signed-byte-left-seven TMS input
  mapping while isolating MAME's unsigned-shift discrepancy as `SC-026`.
- A synthesizable, storage-free sample-ROM adapter with explicit twelve-block
  presence metadata, exact block/address byte callback, invalid-selection
  reporting, response stalls, and schematic-accurate duplicated-sign mapping.
  The board top now routes processor port 0 internally without embedding or
  accepting any copyrighted image in the repository.
- A synthesizable raw Driver Sound DAC latch that captures uncomplemented
  `TD15:TD4` on committed port-0 writes, retains explicit validity, and emits a
  one-clock downstream commit without modeling analog conversion or promoting
  MAME's disputed bit-11 XOR into hardware.
- Primary schematic qualification of both Driver Sound LS74 halves at 100H,
  backed by the official TI SDLS119 data sheet: port 4 captures `TD0` onto Q
  and exposes complementary raw `MUTE`, while port 5 presets `320IRQ` until
  reset or a 68000-side `/IRQCLR` completion. The only drawn Rev-A mute
  consumer is explicitly not loaded, so effective audio semantics remain
  unresolved rather than being inferred from the net name.
- A synthesizable Driver Sound output-control adapter exposing raw `MUTE`, a
  one-clock mute commit, the data-independent 68000 IRQ latch, and an explicit
  future-host clear callback. The partial board top now acknowledges ports 4
  and 5 internally without relying on an unrelated external ready callback.
- Primary schematic qualification of the complete Driver Sound BIO path,
  backed by TI SDLS060/SDLS119: an LS161 pair preloads `0xce`, counts through
  `0xff`, and emits a one-1-MHz-period active-low source every 50 periods;
  board reset clears only the source LS74, and a separate CLKOUT LS74 samples
  the level. Counter power-up/reset phase and independent-clock coincidence
  remain explicit rather than being assigned emulator behavior.
- A synthesizable standalone BIO generator using two clock enables, no
  generated clocks, caller-seeded phase validity, raw-source validity, and
  sampled-pin validity. The partial board top now offers it as an explicit
  opt-in, derives CLKOUT sampling from the core phase, keeps external raw BIO
  as the default, and rejects unresolved coincident 1 MHz scheduling under
  `OQ-028`.
- Primary schematic qualification of Driver Sound port 2, backed by TI
  SLCS007K: `/CMPRD` exposes only `CMPOUT` on `TDI15`, while the optional
  microphone/LM311 source and pull-up are on a sheet explicitly marked
  `THIS SHEET NOT LOADED.` `SC-029`/`OQ-029` now prevent MAME's zero-return
  stub from being promoted into physical behavior; the wrapper retains an
  explicit external callback and the smoke zero is a named synthetic sentinel.
- Primary qualification of Driver Sound LS138 `30N` and LS259 `80R`: the
  `/LATCHES` host quadrant writes one Q selected by `A3:A1` from address bit
  `A4`, board reset clears every output, and raw Q3/Q4 are `CRAMEN` and
  `/320RES`. Host data is not incorrectly treated as latch data.
- A standalone synthesizable host-control adapter with explicit decoded
  completion, all eight raw outputs, per-bit validity, reset qualification,
  six retained checks, and exhaustive select/value verification. Full
  `/RVAS`/DTACK integration remains separate.
- An opt-in board-top host-control path that selects LS259 Q4/Q3 for
  `/320RES` and CRAMEN, exports raw and selected-control validity, preserves
  the external callbacks by default, and keeps `/IRQCLR` separate.
- Primary cross-sheet qualification of all four low 68000 host reads,
  including complete `/SOUNDRD`, partial `/320PORT`/`/SWITCHES`/`/READSTAT`
  lane maps, handshake side effects, raw status polarity, and explicit
  `OQ-030` treatment for lanes the selected target does not drive.
- A standalone synthesizable port-3 LS374 model that captures `TD7:TD0`,
  exposes it on host `D15:D8`, and separates fixed driven lanes from captured
  data validity. The board top now acknowledges `/CPORT` internally without
  inheriting external callback backpressure.
- Primary qualification of both complete-word main/sound mailbox directions,
  their LS74 `20S` pending flags, reset behavior, read-clear edges, and
  unresolved byte/coincident-strobe boundaries under `SC-031`/`OQ-031`.
- A standalone synthesizable whole-word mailbox adapter with independent data
  and flag validity, explicit conflict reporting, exhaustive bidirectional
  16-bit verification, ten retained transition checks, and a Yosys target.
- A standalone storage-free `/READSTAT` mapper preserving the raw
  `MAINFLAG`/`SOUNDFLAG`/`SOUND.TEST`/`/TIRDY` order on host `D15:D12`, fixed
  driven mask `0xf000`, independent per-source validity, and deterministic
  carrier bits that do not claim an open-bus value.
- Board-top mailbox and raw-status integration using four distinct whole-word
  completion callbacks, complete retained data/flag validity and conflict
  visibility, direct flag-to-status wiring, and explicit raw test/ready inputs
  without a 68000 bus or open-bus policy.
- A standalone storage-free `/SWITCHES` mapper preserving the non-inverting
  `J3-11/J3-9/J3-8/J3-7` order on host `D15:D12`, fixed driven lanes,
  independent connector validity, and deterministic filler outside the masks.
- A storage-free low-host-read selector and board-top composition for
  `/SOUNDRD`, `/320PORT`, `/SWITCHES`, and `/READSTAT` in primary Atari LS138
  order, forwarding exact data/driven/valid masks and one-hot target state
  without generating a bus cycle or read-clear side effect.
- Primary acquisition of Atari TM-327 third printing and Motorola M68000UM
  Ninth Edition. TM-327 identifies the published local-68000/TMS32010 Sound Board
  diagnostic roles; M68000UM supplies the processor S2-through-S7 bus-state
  and electrical timing contract used to interpret A044427.
- A pin-level host-cycle timing transcription for A044427: LS138 `30P` Y4
  qualifies `/RVF` from `/AS`, `A23`, and `A16:A14`; the shared-8-MHz F74
  chain produces one-period `RVA`/`/DTACK`; and falling-edge state holds
  `/RVAS` through the S7 read-data latch boundary. It records the lack of
  READY/retry behavior and separates the resolved logical sequence from the
  still-open electrical margin and power-up transient under `OQ-033`.
- A synthesizable standalone Driver Sound host-timing adapter with explicit
  8 MHz edge and `/AS` events, complete address/control capture, exact
  `/VPA`/`RVA`/`/DTACK`/`/RVAS`/`/RVF` outputs, global byte-write strobes,
  one-hot low-I/O selection, and qualified completion pulses. It deliberately
  has no READY input and labels deterministic initialization as FPGA-only.
- A dedicated 16-step bounded host-timing proof with explicit legal
  alternating-edge and VPA-release assumptions, exact external-equation and
  captured-state assertions, and reachable whole-word read, whole-word write,
  and fully settled CPU-space covers.
- A 12-step bounded board-hierarchy host-routing proof that symbolically
  selects all six implemented timing-derived transaction classes, holds
  contradictory explicit callbacks active, checks exact S7 stateful effects
  with the DSP paused, and reaches seven covers including both partial-byte
  orientations.
- An opt-in board-top composition of that timing path: all four masked read
  quadrants are driven during the held selection interval, and pre-edge S7
  events route `/SOUNDRD`, complete-word `/SOUNDWR`, `/LATCHES`, and
  `/IRQCLR` to their existing stateful adapters. Partial mailbox writes are
  explicitly reported and rejected under `OQ-031`; `/SPEECH` completion
  remains visible without an invented device side effect.
- Portable SystemVerilog package, exhaustive partial decoder, and
  clock-enable execution core for the fifty-eight-instruction slice.
- Directed RTL tests, exhaustive 16-bit decode-space validation, and a seeded
  512-instruction model/RTL differential trace.
- A 32-case interrupt-arrival matrix covering every represented machine cycle
  of all 15 currently supported multicycle core families, with logical bus,
  retirement, protected-instruction, dummy-fetch, stack, acknowledge, and
  vector assertions.
- A four-case native INT sampling matrix covering each modeled subphase,
  including a stalled pre-sample phase, with no early pending/cycle change and
  exact falling-boundary, protected-instruction, dummy, stack, and vector
  assertions.
- A matching 32-case explicit-pipeline interrupt-arrival matrix covering both
  execution intervals of all eleven supported two-word control families and
  IN/OUT, plus all three TBLR/TBLW intervals. It checks native strobe
  ownership, no midinstruction entry, one protected retirement, dummy
  discard, stack entry, acknowledge state, and vector capture.
- A separate four-case explicit-pipeline interrupt-arrival test covering both
  CALA and RET intervals, no midinstruction stack effect or entry, selected-
  target completion, protected retirement, dummy/vector ownership, and
  resolved return-PC stacking.
- Fetch/execute-separation ADR and a standalone synthesizable pipeline register
  with explicit word/address validity, completion, stall, and flush ownership;
  directed tests cover Figure 2-2 priming/overlap and Figure 2-12
  dummy/vector flow without claiming integrated pipeline completion.
- A core-connected sequential pipeline qualification wrapper with a distinct
  fetch address, first-fetch priming, one-cycle retirement overlap, visible
  multicycle parking, reset recovery, and full-state offset comparison across
  the existing 46-word/41-family one-cycle stream.
- Explicit unconditional-B pipeline ownership: the operand fetch is
  nonexecutable cycle 1, the redirected target fetch is cycle 2, B retains
  the execute slot until target capture, and malformed operands park before
  an unsupported speculative address.
- Explicit BANZ pipeline ownership for both old-counter outcomes: the
  nonexecutable operand selects target or fallthrough, the selected fetch is
  cycle 2, and the modulo-512 counter decrement occurs only as BANZ retires
  and captures that instruction.
- Explicit pipeline ownership for all six accumulator-conditioned branches:
  the unchanged full 32-bit ACC selects target or fallthrough after the
  nonexecutable operand fetch, and branch retirement only captures the
  selected instruction.
- Explicit BV pipeline ownership for both old-OV outcomes: the nonexecutable
  operand selects target or fallthrough, the selected fetch is cycle 2, and
  sticky OV clears only when a taken BV retires and captures that instruction.
- Explicit BIOZ pipeline ownership for both active-low pin outcomes: the raw
  input is sampled at operand completion, the selected fetch is cycle 2, and
  the resulting decision remains stable through later pin changes or stalls.
- Explicit CALL pipeline ownership: the nonexecutable operand selects the
  target fetch, CALL retires only when that word is captured, and opcode-PC+2
  is pushed at that retirement boundary.
- Explicit IN/OUT pipeline ownership from primary Figure 2-9: cycle 1 performs
  the mutually exclusive DEN/WE transfer at the encoded port, cycle 2
  prefetches PC+1 under MEN, and retirement/capture occurs only at that
  following-prefetch boundary.
- Explicit TBLR/TBLW pipeline ownership from primary Figure 2-10: cycle 1
  discards PC+1, cycle 2 transfers program space at captured `ACC[11:0]`
  under MEN or WE, and cycle 3 repeats PC+1 before architectural retirement
  and execute-slot replacement. Separate program-write direction/data outputs
  keep TBLW distinct from OUT.
- A bounded integrated-pipeline formal harness for fixed
  `LACK 4; TBLR 0; LAC 0; NOP`, checking discarded and repeated PC+1 fetches,
  ACC-addressed program transfer, RAM commit/consumption, bus exclusion, and
  arbitrary clock-enable stalls.
- A complementary bounded direct-TBLW formal harness with an explicit
  synchronous phase-3 program-memory model, checking old-word discard, exact
  WE address/data, one memory mutation, replacement refetch, and execution of
  the rewritten instruction across arbitrary clock-enable stalls.
- Explicit Figure 2-12 interrupt ownership for the qualified EINT path:
  protected execution discards N+2, entry uses an empty execute slot while
  fetching vector 2, and vector execution waits for the following interval.
- Explicit MPY/MPYK interrupt-protection extension through one additional
  instruction, with post-following dummy/return-PC ownership.
- Reproducible Yosys and Quartus synthesis projects with synchronous I/O
  constraints and partial-core synthesis qualification record.
- Primary-transcribed native timing contract for normal program reads, table
  transfers, I/O, reset, interrupt sampling, and BIO sampling.
- Standalone four-subphase program-read engine with distinct FPGA
  initialization and physical-reset controls, plus directed phase/reset/stall
  verification.
- A unified synchronous phase-pause regression comparing zero holds with 16
  host-clock holds across ordinary program reads, IN, OUT, TBLR, and TBLW. It
  checks retained controls and architectural state on every held clock, exact
  elapsed-clock extension, bounded resumption, and identical final RAM and
  program-memory results without claiming a native READY protocol.
- Primary-transcribed `LARK`, `LARP`, and `LDPK` encodings and effects across
  hand fixtures, model, assembler/disassembler, RTL, and differential traces.
- Sequential native-phase wrapper that retires the 41 supported one-cycle
  instructions on falling-edge program samples and keeps PC/native address
  aligned across clock-enable stalls, traps, and reset.
- Yosys 0.33 portable-synthesis qualification for the integrated partial core,
  with a reproducible Ubuntu 24.04 command.
- Least-privilege, immutable-action GitHub Actions jobs for documentation,
  repository/model/tool tests, Verilator regression/lint, and Yosys synthesis.
- Primary-cited `LAC` database/model/tool slice with direct and indirect
  addressing, sign-extension/shift boundaries, logical internal-data traces,
  nine-bit circular AR updates, and explicit unresolved-address traps.
- Portable 144-word internal data RAM, verification-only preload port, logical
  data-read observation interface, and full `LAC` RTL execution path.
- Directed `LAC` RTL/address/cycle tests and randomized logical-data
  transaction comparison against the independent model.
- Primary-cited `SACL` database, model, assembler/disassembler, RTL, and
  native-phase slice, including direct/indirect writes and TI's zero
  next-ARP placeholder syntax.
- Write-enabled internal RAM with logical write observation and assertions
  against invalid or simultaneous CPU/debug writes.
- Primary-cited `SACH` database, model, assembler/disassembler, RTL, and
  native-phase slice with exact 0/1/4 whole-accumulator output shifts.
- Machine-readable legal-value constraints for sparse opcode fields, used to
  reject all five undocumented SACH shift encodings.
- Primary-cited `ZALH`/`ZALS` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for high-half placement and unsigned
  low-half zero extension through the common data-address modes.
- Primary-cited `ADDS` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for unsigned-source accumulation,
  sticky overflow, wrapped `OVM=0` results, and positive `OVM=1` saturation.
- A separately acquired and hash-pinned TI SPRU032A C14/E14 guide, used only
  as explicitly scoped variant evidence for the unresolved ADDH wording.
- An explicit deterministic FPGA/test initialization path distinct from
  physical reset, plus an observable OV output for arithmetic verification.
- Primary-cited `AND`, `OR`, and `XOR` database, model,
  assembler/disassembler, RTL, native-phase, and differential support for
  low-half logic and the common direct/indirect data-address modes.
- Primary-cited `ADD` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for signed-source shifts, sticky
  overflow, wrapped results, and positive/negative OVM saturation.
- Primary-cited `SUB` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for signed-source shifts, sticky
  overflow, wrapped results, and positive/negative OVM saturation.
- Primary-cited `SUBS` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for unsigned-source subtraction,
  sticky overflow, wrapped results, and negative OVM saturation.
- Primary-cited exact `ABS=0x7f88` database, independent fixture,
  assembler/disassembler, model, RTL, native-phase, and differential support
  for ordinary negation and OVM-selected most-negative wrap/saturation while
  preserving incoming OV.
- Primary-cited `LAR` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for either auxiliary-register target,
  including TI's exceptional suppression of indirect post-modification when
  the loaded target is the selected address register.
- Primary-cited `SAR` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for either auxiliary-register source,
  including TI's exceptional post-modified same-source value written at the
  pre-modification indirect address.
- Primary-cited `MAR` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for direct NOP forms and indirect
  AR/ARP modification without a data-memory access, preserving its exact LARP
  aliases.
- Primary-cited `LDP` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for loading DP from an internal
  data-word LSB after old-DP/old-AR address selection and before ordinary
  indirect AR/ARP post-modification.
- Primary-cited `LT` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for loading all 16 bits of an
  internal data word into T through the common address/update path.
- Primary-cited `MPY` database, model, assembler/disassembler, portable
  multiplier RTL, native-phase, and differential support for signed
  16-by-16 products in P through the common address/update path.
- Primary-cited `MPYK` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for signed T times a sign-extended
  13-bit immediate in P without a data-memory transaction.
- Primary-cited `PAC` database, hand fixture, model, assembler/disassembler,
  RTL, native-phase, and differential support for a full-width P-to-ACC
  transfer without changing P or arithmetic status and without a data-memory
  transaction.
- Primary-cited `APAC` database, hand fixture, model, assembler/disassembler,
  RTL, native-phase, and differential support for full-width P-plus-ACC
  arithmetic, sticky signed overflow, OVM-controlled wrap or signed-endpoint
  saturation, unchanged P, and no data-memory transaction.
- Primary-cited `SPAC` database, hand fixture, model, assembler/disassembler,
  RTL, native-phase, and differential support for full-width ACC-minus-P
  arithmetic with the same overflow/result policy, unchanged P, and no
  data-memory transaction.
- Primary-cited `LTA` database, hand fixtures, model, assembler/disassembler,
  RTL, native-phase, and differential support for simultaneous full-word T
  loading and previous-P accumulation with common data-address updates,
  sticky overflow, and OVM-controlled results.
- Primary-cited `LTD` database, hand fixtures, model, assembler/disassembler,
  RTL, native-phase, and differential support for simultaneous T loading,
  previous-P accumulation, and unchanged source-word copy to the next
  internal-RAM address.
- Separate logical source and destination RAM address diagnostics for
  dual-address instructions, with independent internal-RAM read/write
  addresses and validity assertions.
- Primary-cited `DMOV` database, hand fixtures, model,
  assembler/disassembler, RTL, native-phase, and differential support for an
  unchanged source-word copy to the next internal-RAM address without LTD's
  T-load or accumulator effects.
- Primary-cited exact `DINT=0x7f81` and `EINT=0x7f82` database entries, hand
  fixtures, model, assembler/disassembler, RTL, native-phase, and differential
  support for one-cycle `INTM` set/clear effects with no data-memory
  transaction. Directed interrupt tests additionally cover request retention,
  EINT's following-instruction service deferral, vector entry, and all
  represented supported-multicycle arrival positions; complete overlapped
  execution and physical setup/synchronizer behavior remain outside the
  qualified boundary.
- Acquired and hash-pinned TI's 1986 preliminary TMS320C25 guide as
  explicitly later-variant evidence for the otherwise unresolved indirect
  LST next-ARP precedence; it is not treated as original-part authority.
- Primary-cited `LST` opcode-family, status-field, one-cycle, and internal-read
  support across the database, hand fixtures, model, assembler/disassembler,
  RTL, native-phase integration, and differential trace. Memory-sourced ARP
  precedence over an encoded next ARP remains PROVISIONAL under
  `OQ-015`/`SC-009`.
- Primary-source `PUSH=0x7f9c` and `POP=0x7f9d` research covering their exact
  four-level stack transformations, accumulator effect, overflow/underflow
  behavior, one-word size, and two-cycle totals.
- Primary-cited `SUBC` database/model/tool/RTL/native-phase slice with hand
  fixtures, common direct/indirect addressing, both conditional result paths,
  TI's 16-step 65-divided-by-7 example, seeded direct/indirect randomized
  differential coverage, and explicit `OQ-017`/`OQ-018` limits on result
  availability and OV staging.
- Primary-cited `BANZ=0xf400` database, hand fixture, assembler/disassembler,
  independent model, two-cycle RTL state, native phase, and focused
  differential support. Taken and untaken paths both read the following
  canonical target word, test the old selected low-nine AR counter, decrement
  modulo 512 while preserving upper bits, and retire at the second sample.
- Explicit conflict records for a later TI guide's contradictory full-register
  BANZ wrap example (`SC-011`) and MAME's shortened untaken timing
  (`SC-012`), without weakening the original-part primary-backed behavior.
- Primary-cited `B=0xf900` database, hand fixture, assembler/disassembler,
  independent model, shared two-cycle RTL branch state, native phase, and
  focused differential support. It always reads a canonical following target,
  loads PC, preserves other architectural state, and retires at the second
  sample.
- Primary-cited exact `BLZ=0xfa00`, `BLEZ=0xfb00`, `BGZ=0xfc00`,
  `BGEZ=0xfd00`, `BNZ=0xfe00`, and `BZ=0xff00` support across the database,
  hand fixtures, local tools, independent model, shared two-cycle RTL state,
  native phases, and focused differential traces. Directed tests cover every
  signed/zero predicate boundary and both outcomes.
- Explicit `SC-013` record for MAME's one-cycle untaken accumulator-branch
  abstraction; project timing follows TI's unconditional two-word/two-cycle
  definitions.
- Primary-cited exact `BV=0xf500` support across the database, fixtures, local
  tools, independent model, shared two-cycle RTL state, native phases, and a
  focused differential. Both OV states read the target word; taken BV clears
  OV only at second-cycle retirement.
- Explicit `SC-014` record for MAME's one-cycle untaken BV abstraction.
- Primary-cited exact `BIOZ=0xf600` support across the database, fixtures,
  local tools, independent model, shared two-cycle RTL state, native phases,
  and a focused differential. The raw active-low BIO input is sampled live at
  the target-word falling-edge boundary, not latched with the opcode, and both
  pin states consume the mandatory target read.
- Explicit `SC-015` record for MAME's shorter untaken BIOZ abstraction and its
  abstract asserted callback polarity; project behavior follows the original
  TI pin-level and two-cycle definitions.
- Primary-cited exact `CALL=0xf800` support across the database, hand fixture,
  local tools, independent model, shared two-cycle RTL state, native phases,
  and a focused differential. CALL reads its canonical following target,
  pushes wrapped opcode-PC+2 onto the top of the four-level 12-bit stack at
  target-word retirement, shifts the older entries, and discards the old
  bottom.
- Architectural stack observation across the portable core, phase wrapper,
  synthesis harness, and differential trace, with deterministic test
  initialization kept explicitly separate from physical reset behavior.
- Primary-cited `IN`/`OUT` opcode families across the database, independent
  fixtures, local tools, model, RTL, native phases, and differential trace.
  Each performs one normal opcode read followed by one distinct I/O cycle;
  IN samples live port data under DEN into the old resolved RAM address, while
  OUT drives that RAM word under WE. Direct/indirect ordering, all eight
  ports, exact two-cycle retirement, clock-enable stalls, strobe exclusion,
  traps, and AR/ARP post-updates are automated.
- Primary-cited `TBLR`/`TBLW` opcode families across the database, independent
  fixtures, local tools, model, RTL, native phases, and differential trace.
  Each performs an opcode read, discarded PC+1 read, and ACC-addressed
  program-space transfer; directed tests cover RAM/program effects,
  self-modification, stack-bottom duplication, indirect updates, exact
  three-cycle retirement, stalls, strobe exclusion, and repeated PC+1 fetch.
- Active-low `int_i`, observable pending-latch diagnostics, and an interrupt
  entry sequencer shared by the portable core, native phase wrapper, and
  synthesis harness. It retains masked requests, honors EINT and MPY/MPYK
  deferral, dummy-fetches and stacks the return PC, applies the internal
  acknowledge effects, and selects vector 2.
- Directed model, architectural RTL, native-phase, and focused differential
  interrupt tests covering one-cycle pulses, held-low relatching, reset,
  DINT cancellation, EINT's previously-disabled qualification, multiply
  extension, two-cycle-branch completion, dummy-bus exclusion, and vector
  entry.
- A SymbiYosys actual-core interrupt harness with a 12-step BMC task over
  arbitrary clock-enable stalls and a separate non-vacuity cover task for
  EINT, protected execution, dummy entry, and vector execution.
- A second actual-core formal harness with a 14-step BMC and cover for MPYK
  extending an armed interrupt through its following instruction, followed by
  held-low request relatching after acknowledge.
- A third actual-core formal harness with a 20-step BMC and cover for
  deterministic direct data-memory MPY operands, a mixed MPY/MPYK/MPY
  deferral chain, signed product results, and final interrupt entry.
- A fourth actual-core formal harness with a 20-step BMC and cover for
  indirect `MPY *-,AR1`, old-address data ownership, low-nine-bit AR
  decrement with upper-bit preservation, ARP replacement, signed product,
  interrupt deferral, entry effects, and arbitrary clock-enable stalls.
- Primary-cited exact `RET=0x7f8d` database/fixture support, assembler and
  disassembler round trips, and directed model tests for the old-TOS PC load,
  four-level pop with old-bottom duplication, two-cycle total, state
  preservation, and protected `EINT; RET` pending-interrupt reentry.
- Primary-cited exact `PUSH=0x7f9c` and `POP=0x7f9d` database/fixture support,
  assembler/disassembler round trips, and directed model tests for low-12-bit
  push, zero-extending pop, complete four-level shifts, PC wrap, preserved
  state, repeated over-push/over-pop behavior, and two-cycle totals.
- Primary-cited exact `CALA=0x7f8c` database/fixture support, assembler and
  disassembler round trips, and directed model tests for opcode-PC+1 stack
  push, `ACC[11:0]` target selection, upper-ACC exclusion, PC wrap, nested
  old-bottom loss, state preservation, and two-cycle totals.
- Primary-cited `SUBH=0x62xx` database/fixture/tool/model/RTL/native and
  differential support for high-half subtraction, ordinary/wrapped low-half
  preservation, sticky signed overflow, both OVM wrap/saturation directions,
  common address updates, one-cycle retirement, and logical data-read traces.
  `SC-016` records the primary wording that makes full-accumulator saturation
  the exception to ordinary low-half preservation.
- Primary-cited `SST=0x7cxx` database/fixture/tool/model/RTL/native and
  differential support for forced-page-one direct addressing, indirect
  pre-update status capture and post-update AR/ARP ordering, exact one-cycle
  internal-RAM writes, all 32 combinations of defined status fields, and all
  28 legal encodings. Reserved bit 1 is stored high at CORROBORATED confidence
  under resolved `SC-008`/`OQ-003` and remains reserved to software.
- A dedicated actual-core reset regression that seeds every exposed datapath,
  address, stack, status, pending/trap, and internal-RAM category before reset,
  then checks TI-defined control effects separately from `OQ-012`'s
  provisional retention policy.
- A 10-step actual-core reset BMC/cover proving reset priority, inactive
  transactions/instruction qualification, exact documented control effects,
  and the implementation-scoped retention transition; its nonzero ACC/OVM
  cover reaches step 5.

- A storage-free local-68000 memory decoder transcribing A044427's broad
  low-ROM aliases, all eight high-bank LS138 outputs, Y5 program/direct-I/O
  split, communication/local-RAM selects, populated word-address projections,
  and local 6264 byte-lane controls. It includes exhaustive alias/control
  verification and a standalone Yosys target without embedding memory data.
- Primary research for the Driver Sound local program-memory diagnostics,
  backed by a newly pinned TI SDAS113B ALS32 data sheet, exact Rev-A equations,
  `SC-034` for physical-versus-MAME mapping differences, and `OQ-034` for the
  unqualified E1/E2/larger-EPROM production option.
- A storage-free local-memory timing bridge connecting the captured
  S2-through-S7 host state to ROM/local-SRAM callbacks, exact byte-lane S7
  commits, program/communication-RAM callbacks, and the distinct direct-TMS
  `/PWE` S6 edge. Read data carries separate driven/valid masks and an explicit
  fixed-boundary missing-response event without a READY or open-bus policy.
- An optional 8K-by-16 local SRAM built from independent byte memories and
  per-lane validity metadata. Its 8,192-clock FPGA initialization scrub never
  resets the data arrays, exposes readiness/progress, and rejects pre-ready
  writes instead of inventing known physical power-up contents.
- Primary-qualified upper-Y5 direct-I/O research and a storage-free adapter
  preserving the board's asymmetric decode: reads alias modulo four throughout
  the window, while writes select only canonical words 0-7. The adapter
  carries one-hot targets, exact S6/S7 completion classes, raw write data, and
  read driven/valid masks without assigning open-bus values.
- A one-step symbolic proof of every direct-I/O address/control/data/mask
  combination, with covers for the highest read alias, undriven port 3,
  canonical port-7 writes, and the first unselected write.
- A storage-free local-MC68000 reset-release interlock preserving separate raw
  RESET and HALT callbacks while clamping both during FPGA initialization or
  an incomplete selected internal-SRAM scrub, plus exhaustive simulation and
  one-step formal coverage of all policy inputs.
- Primary qualification of the populated A044427 local-MC68000 reset source,
  backed by the pinned TI SDLS043 LS123 data sheet: `/MRES` and decoded `/SRES`
  trigger a nominal 155.1 ms one-shot with about 2.2 ms of documented
  early-retrigger inhibit, `SOUND.RESET` holds the result directly, and
  separate 7406 branches deliver equal stable logic to RESET and HALT. A
  standalone synthesizable tick-domain reconstruction exposes both outputs,
  active hold, and trigger events without analog or real-time RTL.
- Primary qualification of the SP-327/A044427 main-side sound-reset decode.
  The new storage-free module preserves the write-only, `/AS`- and
  `/RVAS`-qualified `0x84c000..0x84ffff` mirror without inventing lower
  address or byte-strobe qualification.
- Primary qualification of SP-327's main-board `/RVAS` state chain and a
  standalone same-clock event model. It captures `/AS`, emits the one-period
  `RVA`, asserts `/RVAS` from `/RVA`, and releases only after `/DTACK` has
  sampled low then high; a missing low sample deliberately holds the bus.
- Primary qualification of SP-327's early `/RVAS0` F74 and its normal
  MC68000 phase contract. The timing adapter now represents S2 high-phase
  `/AS`, S3 asynchronous preset, common sampled-`/DTACK` release, low-phase
  immediate assertion, and active-preset priority. A composed HSBUS test adds
  zero-wait and GSP-wait traces without assigning undocumented peripheral
  semantics to the raw wait inputs.
- Primary qualification of the complete SP-327 sheet-4 combinational
  `/DTACK` cone: function-code-7 `/VPA`, ordinary `RVA`, qualified HSBUS wait,
  DUART acknowledgement, and final three-way active-low merge. The
  storage-free RTL exposes every intermediate term and adds a synthetic
  end-to-end reset-write timing composition.
- Five newly acquired and hash-pinned official TI component data sheets for
  LS20, AS00, F04, F11, and F74. The existing SDAS113B source was confirmed
  byte-identical at TI's AS32 URL and reused instead of duplicated.
- Primary qualification of the selected MC68681 acknowledgement boundary,
  backed by Motorola's exact 1985 advance-information publication and the
  official archived successor manual. SP-327 connects `/RDUART` to `CS`, uses
  the independent 3.6864 MHz crystal, and pulls active-low open-drain
  `/DUDTACK` high through 4.7 kΩ. A composed test retains arbitrary device
  wait, accepts late ACK, and checks select/release ordering without inventing
  fixed main-clock latency.
- Primary qualification of SP-327's `/AS`-enabled LS138 and both LS139
  subdecoders, backed by the newly pinned TI SDLS013A data sheet. The
  storage-free RTL exposes all active-low outputs and preserves physical
  `/DUART`, `/GSP`, and `/MSP` aliases that are broader than MAME's canonical
  software-facing handlers.
- An address-driven `hard_drivin_main_bus_control` hierarchy connecting the
  verified decoder, held-strobe state, and `/DTACK` cone. It preserves the
  explicit event-domain boundary and peripheral-owned TMS34010 `HRDY` and
  MC68681 `DTACK` inputs while exposing all raw selects and intermediate
  acknowledgement terms.

### Changed

- Shared specimen reports now normalize empty IDs to `null` and any invalid
  scope to `UNQUALIFIED`; the underlying evidence package remains incomplete.
- PUSH/POP evidence now uses the shared specimen validator rather than a
  private duplicate and requires numeric program-memory access time. Its exact
  image, H1/H2/H3 classification, single-specimen scope, and always-open
  acceptance semantics are unchanged.
- Reset-retention evidence now requires independently exact SET/CLEAR source,
  dense 297-word listing, image, and normalized-trace records for the same raw
  marking/date/lot/package specimen. All measured fields remain unconstrained,
  the scope is `this_specimen_only`, and `acceptance_complete` remains false.
- The paired absent-RAM write workflow now requires independently exact
  ascending/descending source, 43-word listing, image, and trace records for
  the same specimen named by the pinned stage-1 report. Chronology and all
  measured results remain unconstrained, and `acceptance_complete` is false.
- The nondestructive absent-RAM read workflow now binds its exact source,
  35-word listing, image, normalized trace, and complete `OQ-008` record to one
  specimen while preserving every history-conditioned and variable read.
  `acceptance_complete` remains false.
- The paired RAM-boundary workflow now validates both exact source/listing/
  image/trace packages through the shared `OQ-008` boundary and requires DMOV
  and LTD metadata to identify the same specimen. Variable scan, diagnostic,
  and documented-register results remain reviewable, and
  `acceptance_complete` remains false.
- DINT/interrupt-boundary evidence now layers shared single-specimen
  provenance over the exact sparse fixture, pulse-measurement, sampled-level,
  and three-calibration checks, always leaving `acceptance_complete=false`
  without changing candidate resolution.
- Both SUBC physical workflows now use the shared `OQ-008` validator for their
  independently exact source/listing/image packages and expose
  single-specimen scope with `acceptance_complete=false`; dependency outputs
  and overflow-stage candidates remain unconstrained by provenance.
- LST-ARP physical packages now use the shared `OQ-008` validator, require the
  exact 30-word listing and numeric program-memory access time, and expose
  single-specimen scope plus `acceptance_complete=false` without changing the
  bidirectional precedence acceptance rule.
- Simultaneous-AR physical packages now use the shared `OQ-008` validator,
  require the exact 23-word listing and numeric program-memory access time,
  report explicit single-specimen scope, and always retain
  `acceptance_complete=false` without changing any candidate classification.
- PUSH/POP physical evidence now fails closed unless the program is the exact
  independent 16-byte fixture, the listing contains its exact eight-word map,
  and metadata pins the normalized trace plus a
  single-specimen `OQ-008` record: raw tracking/lot/package identity, custody,
  socket/temperature/reset context, tool versions, and distinct top, bottom,
  and board-context photographs. Reports explicitly retain
  `acceptance_complete=false` and cannot imply mask invariance.
- The PUSH/POP physical experiment now cites TI SPRU011's contemporary
  every-traceable-machine-cycle XDS/22 capture and clock-qualified Kontron
  external-fetch workflow, defines the normalized CSV handoff, and links the
  reproducible classifier without treating either development-tool overview as
  a missing instruction waveform.
- LST and SST now share the proved status-word bitfield relation while the
  instruction owner retains INTM preservation, address selection, old/new
  ordering, retirement, and the PROVISIONAL indirect-LST next-ARP policy.
  Reserved SST bit 1 remains CORROBORATED rather than promoted to silicon
  proof.
- Supported indirect data instructions, MAR, BANZ, IN/OUT, and TBLR/TBLW now
  share one qualified AR counter relation while retaining their established
  selected-register, pre-address, ARP, special LAR/SAR, and retirement rules.
  Simultaneous controls remain unsupported and fail closed without assigning
  original-silicon behavior.
- CALL, CALA, RET, interrupt entry, and TBLR/TBLW retirement now consume the
  shared proved stack relation without changing their qualified commit
  boundaries. Native PUSH/POP sequencing remains deferred under `OQ-016`.
- SACH now consumes the proved shared output-shifter result; its decode,
  effective address, write ownership, one-cycle timing, and ACC preservation
  remain unchanged. Invalid fields remain decoder-rejected, while the local
  primitive's zero result is explicitly implementation-only fail-closed
  policy.
- LAC, ADD, and SUB now consume the proved shared signed input-shifter result;
  instruction decode, addressing, arithmetic/status effects, and timing are
  unchanged.
- ADD, SUB, SUBH, APAC, SPAC, LTA, and LTD now share the proved signed
  accumulator arithmetic relation. Instruction-owned operand selection,
  sticky OV, timing, and all specialized ADDS/ADDH/SUBS/SUBC policies remain
  separate.
- `OQ-022` is now `PARTIALLY_RESOLVED_PRIMARY`: A044427's common `/RAMWR`
  combined with original-MC68000 Table 3-1 establishes `{byte, byte}` capture
  for program-RAM byte writes. Pinned MAME's retained-other-byte merge remains
  a documented `SC-022` conflict.
- The timing-derived lower-Y5 path now accepts byte writes after original-
  MC68000 normalization. `host_timing_partial_program_write_o` is an accepted-
  event diagnostic; the timing-disabled callback remains a complete-word
  contract.
- `OQ-024` is now `PARTIALLY_RESOLVED_PRIMARY`: A044427's common `/CRWE`
  combined with original-MC68000 Table 3-1 establishes `{byte, byte}` capture
  for communication-RAM byte writes. Pinned MAME's retained-other-byte merge
  remains a documented `SC-025` conflict.
- The timing-derived Y6 path now accepts byte writes after original-MC68000
  normalization. `host_timing_partial_communication_write_o` is an accepted-
  event diagnostic; the timing-disabled callback remains a complete-word
  contract.
- The timing-derived local `/SOUNDWR` path now accepts original-MC68000 byte
  transfers and clocks `{byte, byte}` into the complete mailbox word. Its
  existing partial-write output is now an accepted-event diagnostic rather
  than a rejection indication; the external main callback remains an
  already-captured complete-word contract.
- `SC-031` now distinguishes verified asserted-preset dominance from the
  still-unknown preset-release/read-clock edge and records MAME's retained-
  other-byte merge as a conflict with primary hardware behavior.
- `OQ-026` is now `PARTIALLY_RESOLVED_PRIMARY`: the Rev-A socket matrix and
  TM-356 field-upgrade locations are resolved, while factory/variant
  population, authorized firmware block writes, and absent-selection
  electrical data remain unknown. The existing wrapper already preserves the
  sparse physical mask, so no RTL behavior changed.
- `OQ-034` now includes TM-356's narrow field evidence that the documented
  Race Drivin' deluxe-cockpit upgrade requires E2. That instruction does not
  prove factory population, successful installation, or the contents of the
  program devices' upper halves.
- `OQ-034` is now `PARTIALLY_RESOLVED_PRIMARY`: E1 is required by the
  drawing's 27256 configuration and E2 is the intended 27512/A16 option, but
  no reviewed assembly BOM, option table, ECO, or physical board identifies
  the production link. The wrapper retains its explicit drawing-default
  `A15:A1` projection; no RTL behavior changed.
- `OQ-032` is now `PARTIALLY RESOLVED_PRIMARY`: the reviewed cabinet wiring
  assigns no function to `J3-11/J3-9/J3-8/J3-7`, while the sound-board
  network and LS244 specification provide no guaranteed disconnected value.
  The raw mapper remains unchanged; an exact published-cabinet platform
  clears source validity instead of forcing MAME's zero or a floating-TTL
  high assumption.
- `OQ-020` is narrowed from an unexplained current-MAME discrepancy to a
  source-dated conflict. MAME's signed interpretation is now CORROBORATED as
  continuous software behavior since 2002, while its 2016 schematic-inversion
  comment is explicitly non-independent. The verified physical latch remains
  raw `data[15:4]`; no RTL or architectural-model behavior changed.
- Original-device scope now explicitly treats the 1985/1986/1987/1989
  data-sheet and 14/20/25-MHz product-list changes as document/product facts,
  not RTL parameters or mask-revision proof. `OQ-008` is narrowed to
  `RESEARCHING/NO REVISION MAP` and no architectural behavior changed.
- Refined `OQ-012` from source silence alone to
  `RESEARCHING/CORROBORATED EVM`: production TI reset effects remain narrow,
  EVM register recoverability supports retention, related patent clearing is
  explicitly a ROM-routine effect, and conflicting MAME/IKA policies remain
  nonauthoritative. The portable retention policy is still PROVISIONAL.
- Corrected the architecture reset citation from SPRU001B Section 2.5 to the
  actual Section 2.11 while retaining the already verified page and behavior.
- Raised ADR-0003's RET address ownership from INFERRED to CORROBORATED using
  the related contemporary TI patent, while retaining CALA as INFERRED and
  exact original-TMS32010 pin behavior as UNKNOWN. PUSH/POP remain excluded
  from RTL because the patent does not contain those accumulator opcodes.
- Narrowed PUSH/POP research with TI EVM evidence without promoting a bus
  guess: `N+1` visibility is now corroborated, while H1 inactive, H2 repeated,
  and H3 advancing remain separately measurable.
- The explicit pipeline now retains instruction words, control operands, and
  TBLR program data in one context-owned core-program register. This replaces
  separate branch/table registers and their combinational state-selected mux;
  no program phase, memory effect, retirement boundary, or cycle count moves.
- The explicit fetch/execute wrapper now selects a synchronous internal-RAM
  read while the standalone core retains its asynchronous default. The
  wrapper uses its existing FPGA subphases to capture the operand by phase 1;
  separately registered forwarding metadata supplies a same-address committed
  word during the following owner's phase-0 setup interval. No native strobe,
  retirement boundary, or processor cycle moves.
- Registered RAM capture now uses a distinct wrapper-subphase enable. The
  complete operand/forwarding output holds during a global pause and advances
  with phase 0 to phase 1, independently of the core's architectural execute
  pulse.
- The core now consumes the decoder's internal-data-family qualifier for
  address selection and validity instead of rebuilding two long operation
  whitelists. This is functionally neutral decode metadata; it changes no
  instruction, native phase, retirement boundary, or confidence level.
- The explicit phase wrapper now selects retained branch operands directly
  from registered pipeline state and records TBLR/TBLW direction when the
  table sequence starts. This removes a redundant wrapper decode from the
  sampled-program-data mux while preserving every tested native phase and
  retirement boundary; a prefetch assertion checks retained direction against
  the still-owned instruction.
- The common Yosys/Quartus synthesis harness now elaborates the explicit
  fetch/execute pipeline instead of the legacy fail-closed wrapper, so current
  resource and timing evidence actually includes CALA/RET. The Cyclone V
  internal target is 25 MHz, 25% above the A044427 board's documented 20 MHz
  TMS32010 clock. A rejected 50 MHz fit remains disclosed with its setup
  failure rather than being described as closure.
- `OQ-035` now separates resolved Rev-A connectivity and nominal timing from
  unresolved RC tolerance, power-up behavior, raw-input CDC, platform tick
  calibration, firmware use, and the future MC68000-core interface. `SC-035`
  records that pinned MAME pulses only RESET immediately and is not a timing
  oracle for the paired physical source.
- `SC-036` separates the physical 16 KiB `/SRES` alias window from pinned
  MAME's canonical `0x84c000..0x84c001` handler. `OQ-036` retains the unknown
  system `/RESET` driver, specialized peripheral timing, electrical timing,
  unreset power-up state, and raw CDC boundary; both discrete held-strobe
  dependencies and the complete combinational `/DTACK` cone are now
  primary-resolved. The GSP/MSP ready protocol and generic MC68681
  acknowledge contract and physical primary/peripheral address-select
  qualification are now resolved; workload phase, electrical margin, and raw
  CDC remain open.
- The opt-in board host-timing path now selects the complete local-memory
  bridge. Lower Y5 owns the existing program-RAM callback, Y6 owns the existing
  communication-RAM callback under CRAMEN, and timing-disabled operation keeps
  the original explicit callbacks. Upper-Y5 direct DSP I/O now shares the
  existing physical sample-ROM, communication, DAC, CPORT, output-control,
  block, and address consumers; active host/TMS overlap is suppressed and
  explicitly reported rather than arbitrated.
- Local Y7 storage remains an external callback by default and can now select
  the internal lane-valid SRAM explicitly. Internal selection suppresses the
  external request and write commits while retaining raw address/data
  observability; authorized ROM data remains a separate external callback.
  The board wrapper now exports separately gated local RESET/HALT signals and
  a denied-release diagnostic without changing the TMS `/320RES` path.
- The host-timing adapter now exposes its captured R/W direction alongside
  the already captured address and byte strobes, preventing downstream bank
  decode from consulting a live processor input after `/AS` assertion.
- Added pre-edge S7 completion-event outputs to the host-timing adapter so
  same-clock state consumers update on the documented trailing boundary; the
  registered one-clock completion outputs remain available for trace/debug.
- Preserved all explicit local-host callbacks as the default board-top mode
  while making timing-derived reads and side effects a separate
  `use_host_timing_i` opt-in.
- Replaced the misleading serial-ROM shorthand with parallel sample-ROM
  terminology after tracing the direct `SA15:SA0` address and `SD14:SD7` data
  wiring in A044427.
- Corrected the earlier Driver Sound port-3 conclusion after locating populated
  LS374 `50L` on A044427 sheet 4. `/CPORT` captures `TD7:TD0`, `/320PORT`
  drives those bits onto host `D15:D8`, and MAME's logging/zero-return stubs
  are now isolated as `SC-030` instead of being treated as missing hardware.
- Corrected the mailbox flag component location from LS74 `10J` to `20S` and
  separated the two-68000 word exchange from the unrelated TMS port-3 latch.
- Split deterministic FPGA initialization from an independent synchronous
  processor-reset request in `tms32010_mister`, allowing board `/320RES` to
  retain shared program contents while preserving the five-cycle reset hold.
- Defined the board adapter's host program path as whole-word only. A044427
  does not route UDS/LDS into this SRAM bank; byte-preserving MAME writes are
  now isolated as `SC-022`/`OQ-022` rather than promoted to hardware behavior.
- Clarified that the generic program/I/O qualifiers preserve architectural
  ownership while the Hard Drivin' board deliberately decodes native address
  and strobes, causing WE at addresses 0–7 to select output ports.
- Split Hard Drivin' port-0 qualification into the primary-backed raw DAC code
  `data[15:4]` and MAME's secondary `(data >> 4) XOR 0x800` transform. The
  latter is no longer described as shown board wiring because A044427 contains
  no bit-11 inverter.
- Narrowed the PUSH/POP timing gap using TI's primary pin contract: `MEN` must
  be active in both non-I/O execution cycles, but the address and fetched-word
  ownership remain unknown. Native/RTL implementation stays deferred rather
  than inventing a repeated or speculative prefetch.
- Replaced the single undifferentiated unsupported-opcode bucket with five
  evidence-scoped classifications. Only words setting TI's explicitly
  reserved indirect bits are labeled reserved; fixed-pattern mismatches and
  map gaps retain narrower or unknown labels.
- Reclassified the 28,656 remaining map gaps as
  `PRIMARY_UNLISTED_ENCODING` after locating TI's explicit statement that the
  original Table 3-2 is the complete instruction-set summary. This is a
  documentation classification only, not a reserved-behavior claim.

- Replaced the initial placeholder README with an evidence-oriented project
  overview.
- Reframed the external-wait milestone after confirming that the original
  40-pin TMS32010 has no READY/WAIT input.
- The local assembler diagnoses out-of-range `LACK` operands instead of
  reproducing the historical assembler's silent truncation.
- Quartus 17.0.2 fits the integrated fifty-six-instruction
  phase/RAM/multiplier/I/O/table/interrupt-entry slice in 2,188 ALMs/2,588
  registers and one DSP block, with +2.656 ns worst setup and +0.166 ns worst
  hold slack at 50 MHz and 57.66 MHz worst slow-corner internal Fmax; 385
  diagnostic pins are virtual, and enumerated harness I/O paths are explicitly
  excluded pending a real wrapper.
- Appendix A establishes falling `CLKOUT` as the input sampling boundary and
  resolves reset release to an address-0 fetch after one complete cycle.
- Decoder operation ports use an explicitly encoded packed vector at module
  boundaries so the same RTL elaborates in Verilator, Quartus 17.0.2, and
  Yosys 0.33; exhaustive decode tests guard the package/RTL encoding contract.
- The internal packed operation code is now six bits wide to represent the
  33rd qualified operation without aliasing an existing decode.
- Data-memory documentation now distinguishes verification-visible logical
  RAM accesses from physical pins; ordinary operands are entirely on-chip.
- Physical reset and deterministic initialization are separate controls.
  Unlisted physical-reset state receives no arbitrary assigned value, while
  its FPGA retention behavior remains provisional under OQ-012.
- The qualified model/tool/RTL boundary now covers fifty-eight of 60 documented
  mnemonics: twenty-five common-address internal-data families, SST's
  forced-page status store, two
  common-address I/O families, and two table-transfer families.
- The instruction-boundary model represents interrupt acknowledge as a
  non-instruction `INTERRUPT` step with an `interrupt_dummy_fetch`
  transaction. This preserves deterministic single stepping without claiming
  that the discarded return-PC word executed.
- The model/tool boundary contains all 60 documented instructions while
  RTL/differential covers 58. CALA/RET now use ADR-0003's CORROBORATED-RET/
  INFERRED-CALA external sequence; PUSH/POP cycles are not fabricated in model
  transaction traces and remain outside RTL under `OQ-016`.
- Timing documentation now follows TI's explicit opcode-prefetch convention:
  Figure 2-9/2-10 execution cycles begin after current-opcode prefetch and end
  with next-instruction prefetch. Legacy bus-order evidence is separated from
  explicit execute-slot ownership and no longer labeled as primary proof of
  commit timing.

### Fixed

- Corrected the SUBC physical-probe interpretation from status bit 12 to the
  primary-defined `OV` position at bit 15. Bit 12 is a fixed-one SST field;
  reserved bit 1 remains excluded from capture validation under `SC-008`.
  The probe now explicitly loads ARP zero so unresolved physical reset
  retention under `OQ-012` cannot invalidate its status consistency check.

- Qualified current-instruction auxiliary-counter controls with decoder
  validity and the internal-data-addressed family, plus the documented MAR
  exception. The new core invariant and the seeded differential/formal runs
  first exposed immediate operand bits being mistaken for update controls;
  the follow-up seeded trace then exposed MAR's intentional no-memory update.
  Both root causes were fixed without changing expected results.
- Made the auxiliary-counter proof's reference carry/borrow loop unconditional
  after the first bounded build correctly rejected a harness-only inferred
  loop-index latch. The DUT and asserted result relation were not weakened.
- Connected the shared accumulator's modulo result into a core invariant that
  proves the selected result differs only for an overflowing OVM operation,
  eliminating the strict-lint empty-pin warning without suppressing it.
- Replaced the provisional lower-Y5 byte-write rejection with the primary-
  backed duplicated-byte result while preserving the reset-qualified ownership
  contract.
- Replaced the provisional Y6 byte-write rejection with the primary-backed
  duplicated-byte result; lower-Y5 remained protected at that checkpoint and
  is superseded by the later program-RAM result above.
- Replaced the provisional local-mailbox byte-write rejection with the
  documented original-MC68000 duplicated-byte result; both upper and lower
  byte transfers now set `SOUNDFLAG` and expose the captured word.
- Fixed registered internal-RAM output movement while the wrapper clock enable
  was clear. The existing table-transfer formal stall invariant found the
  defect; the read-side enable now holds captured data and forwarding metadata
  instead of weakening the invariant.
- Formal configuration discovery is now sorted and top-level-only, so direct
  SymbiYosys output left below `formal/` cannot be recursively mistaken for a
  checked-in configuration on a later `make formal` run. A repository
  regression locks this build contract.
- The ROM-free MAME runner now rejects shell-script launchers before execution,
  preventing generated provenance from hashing only `/usr/bin/mame`-style
  wrappers while omitting the actual emulator binary bytes.
- Exposed execute-slot validity/address/word and pipeline-blocked diagnostics
  through the synthesis harness after the first explicit-pipeline Quartus
  elaboration reported all four output groups unconnected. Analysis/synthesis
  now returns zero connectivity warnings and the new virtual pins have exact
  harness-only timing exclusions.
- The low-host-read selector now clamps arbitrary bits outside each selected
  source-valid mask instead of requiring unqualified storage to power up at
  zero. Raw source outputs and physical driven-lane masks remain unchanged;
  this fixes the deterministic interface carrier without inventing an
  open-bus value.
- Removed the nonphysical external-ready dependency from Driver Sound port 3
  and implemented its populated byte latch. Both OUT and low-address TBLW now
  complete against the internal no-wait target and update the masked host view
  exactly once.
- Board-top low-address `TBLW` completion now uses the selected physical I/O
  target's readiness instead of the external callback unconditionally. This
  prevents address-zero `/DACL` writes from stalling when the external port-0
  callback is unready and keeps the internal DAC latch and ordinary `OUT PA0`
  on the same qualified path.
- Corrected the synthetic Hard Drivin' port-0 response for byte `0xd5` from
  MAME's unsigned `0x6a80` to the physical schematic value `0xea80`, where
  `SD14` drives both `TDI15` and `TDI14`. The fixture now selects populated
  Hard Drivin' block 3 instead of Rev-A's unpopulated block 11.
- Reordered the project-authored Hard Drivin' smoke so port 7 qualifies the
  physically uncleared sound-address counters before the first
  communication-RAM read. The independent opcode and transaction fixture
  retains the same twelve instructions, 22 documented cycles, and final
  architectural results.
- Prevented inactive program-data pins from asserting the nonphysical
  `instruction_valid_o` qualification during initialization or recognized
  reset.
- Corrected project spelling and naming in the README.
- Corrected reset duration from five crystal clocks to five complete `CLKOUT`
  machine cycles after reviewing the Appendix A timing table.
- Rejected artificial harness I/O delay assumptions that produced hold
  violations; synthesis evidence now scopes itself to internal timing.
- Added the OV diagnostic output to the Quartus virtual-pin set after a rejected
  fit exposed an unintended physical harness pin assignment.
- Added the T diagnostic output to the Quartus SDC exclusions after rejecting
  an otherwise successful fit with 16 unconstrained output ports.
- Corrected the architecture baseline's logic-datapath description: all three
  operations combine the RAM operand with `ACC[15:0]`; `AND` clears the upper
  half, while `OR` and `XOR` preserve it.
- Held the logical next program address during the pending IN/OUT cycle; the
  native phase test exposed that the initial integration would otherwise skip
  the instruction after an I/O transfer at second-cycle retirement.
- Scoped the mutually exclusive retired/illegal invariant to initialized,
  non-reset operation after the first bounded run correctly exposed
  unconstrained physical power-up state at the pre-initialization edge.

### Verified

- All three symbolic interrupt-arrival choices for fixed direct `TBLR 0` pass
  BMC through depth 20 and independently reach completed entry at cover step
  8. The full formal inventory now has 68 passing tasks from 34 configurations;
  this remains one logical direct-TBLR scenario, not TBLW, indirect-table,
  explicit-pipeline, original-package, or electrical proof.
- Both symbolic interrupt-arrival choices for the fixed two-cycle `B` program
  pass BMC through depth 18 and independently reach completed entry at cover
  step 7. This is one actual-core logical-sequencing proof, not complete
  multicycle-family or original-package bus evidence.
- The protected-DINT BMC passes through depth 18 and its complete retained-
  request service path reaches cover step 9. The formal inventory then had 66
  passing tasks from 33 configurations; this remains bounded
  implementation evidence, not original-silicon DINT priority proof.
- Explicit mask-control placement now distinguishes request-during-EINT,
  request-during-DINT, protected redundant EINT, and protected DINT. The last
  result is a reproducible implementation-policy check only; it does not
  resolve the conflicting TI sequences or substitute for original-NMOS data.
- Request arrival at LACK/NOP/control, all common data/address operations,
  MPY/MPYK, PAC/APAC/SPAC, LTA/LTD/DMOV, LST/SST, SUBC, SUBH, ABS, and ADDH now
  follows the same primary-backed core and explicit-pipeline retirement/
  deferral/entry contract.
  An independent regression derives all ordinary one-cycle mnemonics from the
  canonical ISA, decodes the 39 distinct words, and requires both matrices to
  use the identical ordered representative set.
- Eight command-receipt regressions cover a successful clean revision, dirty-
  tree preflight, retained formal failure with later commands still executed,
  revision and log tampering, command/summary rewriting, output confinement,
  pre-existing log-symlink refusal without modifying its target, and Python
  Boolean/integer substitution in typed receipt fields.
- Six release-evidence regressions cover the complete non-release inventory,
  a removed criterion, missing evidence, unknown command and blocker IDs,
  premature `release_ready`, checklist drift, and deterministic CLI output.
  `make audit-release` validates all 21 criteria without converting current-
  scope test results into release qualification.
- Six release-audit regressions pass for the live tree and fail closed on an
  incomplete generated inventory, undeclared third-party content, and stale or
  inapplicable binary allowlists, including a synthetic exact match to a
  noncommittable source. The current audit finds zero external or binary
  candidates and 59 distinct prohibited reference hashes.
- Five direct shared-validator regressions cover a complete five-artifact
  package and malformed identity, timing, tool versions, source, listing,
  normalized trace, and specimen photographs without interpreting any result.
- A structural cross-workflow regression proves that all nine physical
  classifiers invoke the shared specimen validator, retain
  `acceptance_complete=false`, and carry no private listing validator. All six
  PUSH/POP regressions pass with seven-artifact complete-package accounting and
  fail closed on a nonpositive access time.
- All six reset-retention regressions pass with two seven-artifact packages.
  A digest-valid substitute listing or mismatched SET/CLEAR specimen fails
  closed while every captured post-reset field and relationship remains
  unchanged in the report.
- All six absent-RAM write regressions pass with two seven-artifact packages.
  Mismatched stage/direction specimen identities and digest-valid substitute
  listings fail closed without changing sentinel/readback observations.
- All six absent-RAM read regressions pass with a seven-artifact specimen-bound
  package. A digest-valid substitute listing fails closed while the arbitrary
  measured absent-read words remain unchanged in the report.
- All six RAM-boundary regressions pass with two eight-artifact specimen-bound
  packages. Digest-valid substitute listings and mismatched paired specimen
  identities fail closed without assigning expected scan or diagnostic data.
- All six DINT regressions pass with the expanded ten-artifact complete
  package while retaining the 50 ns setup, local-CLKOUT low width, 15 ns fall
  limit, sampled-level, calibration, and path-traversal failure boundaries.
- All six SUBC regressions pass with complete specimen-bound dependency and
  overflow packages. A stable arbitrary dependency low word remains
  review-ready evidence, while all four overflow pairs retain equal status.
- All six LST-ARP regressions pass with complete specimen-bound provenance;
  memory-wins, encoded-wins, mixed, other, and unstable outcomes retain their
  prior candidate and review semantics, and no synthetic result is promoted.
- The six simultaneous-AR regressions now prove that a full specimen-bound
  package can reach review readiness while a correctly rehashed unrelated
  source/listing, mismatched decoded trace, or traversing specimen-photo path
  cannot; no synthetic candidate is promoted to physical evidence.
- The expanded PUSH/POP package regression proves that merely updating a
  sidecar hash cannot qualify different program bytes, while a complete exact
  single-specimen package can still reach review readiness without resolving
  `OQ-016`, generalizing under `OQ-008`, or supplying physical data.
- The paired reset normalizer accepts non-retention and variable post-state as
  reviewable evidence while keeping OVM as the sole primary-defined retention
  control. Even a fully retained pair is only an observed candidate; no
  physical capture exists, `acceptance_complete` is always false, and
  `OQ-012`/`SC-042` remain open.
- The absent-RAM write normalizer retains every directional measurement and
  allows variable or implementation-disagreeing data in a review-ready
  package. It discloses that the pinned report/order declaration does not
  prove chronology and always reports `acceptance_complete=false`; no physical
  capture exists and `OQ-002` stays open.
- The absent-RAM read classifier preserves both raw values for every address
  and permits a complete variable package to reach review. It always reports
  `acceptance_complete=false`: destructive writes, targeted alias follow-up,
  raw review, and another specimen remain outstanding, no physical capture
  exists, and `OQ-002` stays open.
- The paired RAM-boundary normalizer can mark a structurally complete fixed-
  baseline package review-ready without requiring repeated data or agreement
  with the conservative model. It always reports `acceptance_complete=false`:
  varied history/sentinels, raw engineering review, and another specimen are
  still required, no physical capture exists, and `OQ-014` stays open.
- The simultaneous-AR classifier permits `review_ready` only for a stable,
  terminal-reaching complete priority candidate with a complete evidence
  package. Stable partial noncompletion and unanticipated complete sequences
  remain explicit and nonresolving; no original-device capture exists,
  fail-closed decoder rejection remains policy, and `OQ-010` stays open.
- The LST-ARP classifier resolves a candidate only when both deliberately
  opposing directions select the same precedence and all runs agree. Stable
  mixed or unanticipated sequences remain explicit and nonresolving. With no
  original-device capture, memory-word precedence remains PROVISIONAL and
  `OQ-015` stays open.
- Synthetic DINT traces distinguish the three documented experiment outcomes
  and retain any other sequence without candidate resolution. They qualify the
  measurement workflow only: no original-device capture exists, current DINT
  cancellation remains PROVISIONAL, and `OQ-019` stays open.
- The SUBC capture tool accepts a stable unexpected dependency result instead
  of inventing an oracle, requires the legal comparison word `0x000b`, and
  distinguishes all bit-15 OV pairs without using fixed bit 12. Synthetic
  fixtures qualify the measurement workflow only; `OQ-017` and `OQ-018`
  remain open with no physical capture.
- All 60 cached reference artifacts match their pinned SHA-256 values. The
  official simulator's architectural trace lacks `MEN`/`WE`/`DEN` and a
  PUSH/POP example, so `OQ-016` remains open; stop code `9950` corroborates
  only enforcement of the legal SUBC schedule and leaves `OQ-017` open.

- The PUSH/POP capture tooling recognizes the exact checked probe image at
  addresses `0x001`/`0x004`, requires four retained following boundaries,
  distinguishes repeated from advancing reads without using the assembler as
  an oracle, and serializes every observed signal value. Synthetic H1 remains
  explicitly contradictory to SPRU001B's general `MEN` rule; no physical
  capture exists and no RTL timing sequence has been added.
- Strict lint checks 46 RTL modules; all 62 formal tasks from 31 configurations
  pass; all 39 instruction, 57 bus/wrapper, five interrupt, and 25 differential
  regressions pass, alongside 220 repository and 232 model/unit tests. All 36
  Yosys targets pass with zero structural problems. The status relation maps
  to zero cells; the direct pipeline reports 15,850 cells/128 checks, the
  synthesis harness 15,844/128, the MiSTer wrapper 15,899/135, and the
  six-memory Driver Sound hierarchy 3,786/413. Quartus fits the current
  hierarchy in 1,362 ALMs, 400
  registers, one M10K, and one DSP; closes 25 MHz at +17.838 ns worst setup
  and +0.164 ns worst hold slack; and reports 45.12 MHz worst slow-corner
  Fmax. The reproducible critical path is 21.476 ns over 14 logic levels from
  retained program data to ACC.
- The SACH output-shifter proof passes for every full-ACC/three-bit-field
  combination and reaches all six primary-example, cross-half, and invalid
  covers at step 0. Directed SACH tests retain all three legal shifts,
  invalid-field trapping, ACC preservation, addressing, writes, and one-cycle
  counts. Standalone Yosys maps the block to 86 combinational cells with no
  storage, latch, retained check, or structural problem. The complete
  56-task/28-configuration formal matrix and all repository, model/unit,
  instruction, bus, interrupt, and differential suites pass after integration.
- The shared input-shifter proof passes for every 20-bit source/count
  combination and reaches all four signed/count boundary covers at step 0.
  Focused LAC, ADD, and SUB RTL tests retain their sign-extension, shift,
  arithmetic, status, address-update, and cycle expectations. Standalone
  Yosys maps the block to 89 cells with no storage, latch, retained check, or
  structural problem. The complete 54-task/27-configuration formal matrix,
  39 instruction tests, 57 bus/wrapper tests, five interrupt tests, and 25
  differential tests pass after integration.
- The shared accumulator proof passes for arbitrary 66-bit input combinations
  and reaches positive/negative add/subtract saturation covers at step 0.
  Directed core tests retain wrap, saturation, sticky-OV, addressing, and
  cycle expectations for all seven refactored instructions. Standalone Yosys
  maps the block to 367 cells with no storage, latch, retained check, or
  structural problem. The complete formal matrix passes all 54 tasks from 27
  configurations, and post-change instruction and differential suites pass
  39 and 25 tests respectively.
- Integrated lower-Y5 readback checks upper byte `0xde -> 0xdede` and lower
  byte `0xef -> 0xefef` while `/320RES` grants host ownership. The new BMC
  proves all symbolic addresses and data values through write/read completion;
  both covers are reachable. Integrated Yosys reports 3,752 cells, 410 checks,
  and six memories with zero structural problems.
- Integrated Y6 readback checks lower byte `0xef -> 0xefef` and upper byte
  `0xbc -> 0xbcbc` under CRAMEN ownership. The new BMC proves all symbolic
  addresses and data values through write/read completion; both covers are
  reachable. Integrated Yosys now reports 3,752 cells, 410 checks, and six
  memories with zero structural problems.
- The MC68000 write normalizer passes exhaustive simulation and Yosys
  0.67+111 synthesis at 39 mapped cells/three retained checks with no memory,
  latch, or structural problem. The integrated board test checks `0xab ->
  0xabab` and `0x34 -> 0x3434`, flag set/read-clear, and callback isolation;
  the board-routing BMC proves and covers both symbolic byte orientations.
  Integrated pre-technology Yosys reports 3,752 cells, 410 checks, six
  memories, and zero structural problems.
- All 59 locally acquired references pass their pinned SHA-256 checks. The
  socket-based authorized sample-ROM analyzer passes four regressions for
  exact physical ordering, sparse masks, fail-closed diagnostics,
  deterministic output, and byte non-disclosure; documentation consistency
  pins TM-356, `SC-044`, block-8 policy, and the remaining open-bus nonclaim.
- All 58 locally acquired references pass their pinned SHA-256 checks. Focused
  regressions lock the E1/E2 short-circuit exclusion, the released-versus-
  Panorama declaration boundary, the legacy RTL-name nonclaim, deterministic
  content-free analysis, and `physical_strap_proven=false` policy.
- All 57 locally acquired references pass their pinned SHA-256 checks. A new
  documentation regression locks both no-J3 cabinet diagrams, the passive
  input network, later Sound PCB assembly identity, MAME non-authority, and
  the validity-clear FPGA policy.
- The 54-source DAC corpus passed its pinned SHA-256 checks. The DAC
  helper proves physical `0x7ff`/`0x800` are adjacent ideal transfer steps
  while the MAME mapper crosses `0xfff`/`0x000`, and retains the known smoke
  distinction `0xf23` versus `0x723` across all low-nibble aliases.
- The 50-source device-revision corpus passed its pinned SHA-256 checks, and a
  documentation regression locks the OQ-008 source timeline, the TI32000
  false-positive exclusion, the missing-BBS boundary, and the prohibition on
  inferring a silicon revision from a document or speed label.
- The two sparse reset-retention images are locked by fixed address/word
  digests, word counts, and symbols. The independent instruction-boundary
  model emits the exact set/clear pre-vectors, reconstructs the armed state,
  applies only the current provisional reset policy, and emits matching
  post-vectors. Documentation tests require the EVM/patent claim boundary,
  BIO-only selection, no retained-RAM dependency, both complementary cases,
  and an explicit physical-capture requirement.
- The absent-data-address fixtures assemble deterministically to exact
  contiguous 35-, 43-, and 43-word images with fixed history/write/scan/read/
  terminal symbols. Documentation regressions require read-before-write
  ordering, both controlled predecessor values, both write directions, all
  valid/absent sample counts, and no expected original-silicon result.
- The simultaneous-update fixture assembles deterministically to an exact
  contiguous 23-word image with fixed zero, wrap-boundary, and terminal
  symbols. Documentation regressions require preserve/increment/decrement
  hypotheses, later-family prohibition, both independent no-net-update
  implementations, and no expected original-silicon sequence.
- The indirect-LST precedence fixture assembles deterministically to an exact
  contiguous 30-word image with fixed case and terminal symbols.
  Documentation regressions require both marker hypotheses, both independent
  implementation results, the original worked-result ambiguity, and no
  expected hardware sequence.
- The DINT race fixture assembles deterministically to an exact sparse 28-word
  image with fixed vector, arm, race, resume, handler, and hold symbols.
  Documentation regressions require the TI source conflict, MAME/IKA scope,
  no expected hardware sequence, and external-synchronizer nonclaim.
- The SUBC dependency and overflow-stage probes assemble deterministically to
  exact 26- and 34-word images with fixed observation points and symbols.
  Documentation regressions require the related-patent claim boundary, the
  MAME/IKA conflicts, and unresolved `OQ-017`/`OQ-018` labels.
- The DMOV and LTD RAM-edge probes assemble deterministically to 26-word
  synthetic images with fixed clear/boundary/scan/hold symbols. Documentation
  regressions require the patent/EVM claim boundary and keep `OQ-014`
  unresolved pending original-device capture.
- The complete repository gates pass with 164 provenance/document/tool tests,
  232 model/unit tests, 39 instruction/decode RTL tests, 57 bus/integration
  tests, 5 interrupt RTL tests, and 25 differential/oracle tests. Verilator
  lint checks 43 modules; all 56 formal jobs from 28 configurations pass; all
  33 Yosys targets synthesize; and all 59 acquired reference hashes verify.
- Quartus 17.0.2 fits the fifty-eight-instruction explicit-pipeline hierarchy
  on `5CSEBA6U23I7` in 1,372 ALMs, 400 registers, one 144-by-16 M10K, and one
  DSP block. TimeQuest closes the 25 MHz internal constraint with +18.860 ns
  worst setup and +0.165 ns worst hold slack, 47.3 MHz worst slow-corner
  Fmax, and
  zero unconstrained categories across 415 explicitly virtual/false-pathed
  harness pins. The three remaining full-flow warnings are harness-only pin/
  Lite-license notices; analysis/synthesis and TimeQuest each report zero
  warnings. The detailed 100 °C critical path improves from the original
  33.464 ns/26 levels through 29.180 ns/19 levels, 24.217 ns/16 levels, and
  21.399 ns/14 levels, 20.034 ns/12 levels, 20.016 ns/13 levels,
  19.408 ns/13 levels, and the current 20.866 ns/14-level
  program-data-to-overflow-state result.
- Yosys 0.67+111 reports 16,225 cells/126 checks for the synthesis harness,
  16,193 cells/126 checks for the direct pipeline, and 16,242 cells/133 checks
  for the generic
  MiSTer adapter, all with clean structural checks. The generic and Cyclone V
  counts both increase at this checkpoint, but neither representation is
  reported as a proxy for the other.
- The address-driven bus-control regression reaches a mirrored GSP access,
  canonical MSP access with arbitrary external wait, mirrored DUART access
  with late external acknowledge, and ordinary expansion-bus `RVA`
  acknowledgement through their complete held-strobe release sequences.
  Hierarchical Yosys synthesis reports 185 cells/64 retained checks, no
  memory, latch, generated clock, or structural problem; its three constituent
  blocks retain their separately bounded formal evidence.
- The main address-decode regression exhausts all 1,024 `A23:A14` values
  across both `/AS` and `/RVAS0` levels, then directs canonical and physically
  mirrored DUART, RAM, GSP, and MSP selections. Its one-step BMC proves the
  LS138 and named LS139 equations and reaches six covers. Yosys reports 49
  cells/20 retained checks with no memory, latch, generated clock, or
  structural problem.
- The `/DTACK` decode regression exhausts all 4,096 raw input combinations;
  its one-step BMC proves every intermediate/final equation and six covers
  reach ordinary ACK, CPU-space VPA, both HSBUS wait states, and both DUART
  acknowledgement states. The composed bus test checks `/AS` capture,
  `RVA`/`/DTACK` assertion, held `/RVAS`/`/SRES`, and sampled release. Yosys
  reports 21 cells/eight checks with no storage or structural problem.
- The main held-strobe timing regression covers normal S2/S3 `/RVAS0`, S4
  `RVA`/`/RVAS`, low-phase immediate preset, preset-over-release priority,
  continued hold when `/DTACK` never samples low, later recovery, and FPGA
  reinitialization. Its independent 12-step BMC passes; 16-step cover reaches
  seven timing classes. The HSBUS composition additionally checks early
  zero-wait ACK, independent active-low GSP and MSP wait extensions,
  raw-select deassertion, and delayed sampled release. Yosys reports 93
  cells/25 retained checks with no memory, latch, generated clock, or
  structural problem. The DUART composition separately checks `/RVAS`
  selection, externally delayed `/DUDTACK`, MC68681-CS removal while its
  open-drain pin remains low, and the later sampled hold release.
- The main sound-reset decode regression exhausts all 1,024 `A23:A14` values
  across eight strobe/direction combinations. Its one-step BMC passes and four
  covers reach a canonical write, read isolation, inactive `/RVAS`, and a
  nonexternal address. Yosys reports 16 cells/four retained checks with no
  memory or latch.
- The reset-source regression covers deterministic startup, exact six-tick
  release, paused ticks, direct `SOUND.RESET`, both falling-edge trigger
  sources, held-low behavior, an early ignored retrigger, and a post-inhibit
  accepted retrigger. Its independent hold/inhibit-counter BMC passes 10 steps
  and its 14-step cover run reaches release, both accepted trigger sources, an
  ignored trigger, and direct reset. Default-parameter Yosys reports 28 cells/
  seven retained checks with no memory, latch, or generated clock.
- The local-reset policy passes all 32 initialization/RESET/HALT/selection/
  readiness combinations, and board simulation proves an actual sequential
  scrub clamps both processor inputs until validity address `0x1fff` clears.
  Its one-step BMC and four covers pass; standalone Yosys reports 13 cells/
  seven checks, and the six-memory board hierarchy reports 3,502 cells/405
  checks with no structural problem. The updated board-routing proof passes.
- The direct-I/O decoder passes exhaustive simulation across all 4,096 read
  aliases and all 4,096 write addresses plus a one-step symbolic BMC over
  arbitrary masks and data. Board simulation proves canonical address/block,
  DAC, and CPORT writes at S6; complete sample-ROM and one-bit comparator read
  carriers; the undriven port-3 alias; noncanonical-write isolation; and the
  shared-address S7 increment. Standalone Yosys reports 336 cells/seven checks,
  while the six-memory board hierarchy reports 3,560 cells/374 checks with no
  structural problem. The updated 12-step board-routing BMC/cover also passes.
- The standalone local SRAM checks exactly 8,192 metadata-scrub clocks,
  blocked pre-ready writes, every invalid word, independent upper/lower byte
  validity, all 8,192 complete-word writes and reads, and reinitialization.
  Yosys retains three memories at 88 abstract cells/nine checks with no latch
  or structural problem. Board simulation proves internal/external callback
  isolation, an invalid unwritten read, and independent byte writes composing
  `0x5aa7`; the board hierarchy retains six memories at 3,424 cells/362 checks.
  The existing 12-step routing BMC and all seven covers still pass with the
  internal SRAM disabled in that proof. The complete regression passes
  127 repository/tool, 231 model/unit, 38 instruction RTL, 43 bus/wrapper,
  five interrupt, and ten differential tests; strict lint covers 31 modules,
  all 21 Yosys targets pass, all 33 hashes verify, and all 28 formal tasks
  from fourteen configurations pass.
- Board-level synthetic host cycles now cover mirrored valid ROM data,
  lane-valid local SRAM and an upper-byte S7 write, lower-Y5 program-RAM
  write/readback, upper-Y5 direct-I/O S6 commit and storage isolation, and Y6
  communication-RAM write/readback under CRAMEN. Opposite explicit callback
  sentinels prove opt-in selection, while later regression phases prove the
  timing-disabled fallback. Partial lower-Y5 and Y6 writes are separately
  reported and leave their FPGA memories unchanged. At that checkpoint Yosys
  retained three memories at 3,294 abstract cells/338 checks with zero
  structural problems; the existing
  12-step board-routing BMC/cover remains passing after composition.
- Arbitrary nonzero invalid bits for all four low-read sources are masked at
  the composition boundary. The dedicated board BMC passes solver steps 0–11
  and all seven read/write/latch/speech/IRQ routing covers reach solver step 10,
  including both partial-byte orientations.
  Standalone selector synthesis reports 72 cells/13 checks and the board
  hierarchy reports 2,966 cells/257 checks with three memories and no
  structural problems.
- Invalid low-read selection, exact `00/01/10/11` Atari target order, every
  physically driven lane, distinct source masks, one-hot visibility, live
  board source transitions, MAME-swapped quadrant discrimination, and
  `/SOUNDRD` selection without implicit `MAINFLAG` clear. Standalone Yosys
  reports 68 cells/13 checks; integrated synthesis retains three memories at
  2,737 cells/216 checks with zero structural problems. The full regression
  passes 125 repository/tool, 231 model/unit, 38 instruction RTL, 39
  bus/wrapper, 5 interrupt, and 10 differential tests; strict lint, all
  seventeen Yosys targets, all 30 hashes, and all 24 formal tasks pass.

- All sixteen raw `/SWITCHES` connector nibbles against all sixteen validity
  masks, including exact connector-to-lane order, non-inversion, invalid-source
  clamping, fixed driven lanes, per-bit validity, and low-lane filler
  separation. Standalone Yosys reports 10 cells/six checks, no storage/latch,
  and zero structural problems. The full regression passes 125
  repository/tool, 231 model/unit, 38 instruction RTL, 38 bus/wrapper, 5
  interrupt, and 10 differential tests; strict lint, all sixteen Yosys
  targets, all 30 hashes, and all 24 formal tasks pass.

- Integrated nominal main-to-sound and sound-to-main word exchange, exact
  flag set/read-clear and raw-status mapping, both coincident write/read
  conflicts, independent flag invalidity/requalification, external
  test/ready validity masking, and board-reset flag clear with both LS374
  words preserved. Pre-technology board synthesis retains three memories and
  reports 2,644 cells/194 checks with zero structural problems. The full
  regression passes 125 repository/tool, 231 model/unit, 38 instruction RTL,
  37 bus/wrapper, 5 interrupt, and 10 differential tests; strict lint, all
  fifteen Yosys targets, all 30 hashes, and all 24 formal tasks pass.

- All sixteen `/READSTAT` source nibbles against all sixteen source-validity
  masks, including exact raw polarity, invalid-source clamping, constant
  driven lanes, per-lane validity, and low-lane filler separation. Standalone
  Yosys reports 23 cells/eight checks, no storage/latch, and zero structural
  problems. The full regression passes 125 repository/tool, 231 model/unit,
  38 instruction RTL, 37 bus/wrapper, 5 interrupt, and 10 differential tests;
  strict lint, all fifteen Yosys targets, all 30 hashes, and all 24 formal
  tasks pass.

- Both main/sound mailbox directions over all 65,536 possible complete words,
  nominal flag set/read-clear, uncommitted retention, reset-preserved data,
  reset-qualified flags, simultaneous write/read and reset/write invalidity,
  and later read/write/reset requalification. Standalone Yosys reports 259
  cells, ten checks, no memory/latch, and zero structural problems. The full
  regression passes 124 repository/tool, 231 model/unit, 38 instruction RTL,
  36 bus/wrapper, 5 interrupt, and 10 differential tests; strict lint, all
  fourteen Yosys targets, all 30 hashes, and all 24 formal tasks pass.

- All eight LS259 selections, both A4 values, uncommitted retention, per-bit
  validity, two complete alternating patterns, board-reset qualification, and
  reset-over-write priority. Standalone Yosys reports 53 cells, six checks,
  no memory/latch, and zero structural problems. The complete regression
  passes 123 repository/tool, 231 model/unit, 38 instruction RTL, 35
  bus/wrapper, 5 interrupt, and 10 differential tests; strict lint, all thirteen
  Yosys targets, and all 24 tasks from twelve formal configurations pass.

- Exhaustive port-3 LS374 coverage over all 65,536 TMS words, every non-target
  port, direction/commit isolation, persistence, invalid FPGA startup state,
  and fixed driven/valid masks. Integrated OUT and low-address TBLW captures
  produce masked host carriers `0xa500` and `0x3000` under forced external
  backpressure; board reset preserves the unreset latch and program RAM stays
  unchanged. Standalone Yosys reports 19 cells/five checks, while the board
  hierarchy reports 2,495 cells/171 checks/three memories with zero problems.

- Opt-in Q4/Q3 board control with opposite-valued external callback sentinels:
  board reset qualifies all raw outputs, Q4 enables a safe synthetic
  program-RAM handoff, Q3 loads and releases communication RAM, the DSP
  executes `LACK 0x5a; NOP` in two instruction cycles, and a later Q4 reset/Q3
  host read returns preserved word `0x1357`. Integrated Yosys reports 2,495
  cells, 171 retained checks, three memories, and zero structural problems.

- The A044427 cross-sheet port-2 trace from LS139 decode through LS244 `10H`
  to `TDI15`, the absent compare-target connections to `TDI14:TDI0`, the
  optional LM311 open-collector polarity, and Rev-A's explicit nonpopulation
  notice. All 30 cached references pass pinned SHA-256 verification. This is
  source qualification, not a physical read-word measurement.

- Board-level BIO selection with an external-high sentinel and a generated,
  qualified low: BIOZ takes only target `LACK 0x22`, consumes three total
  instruction cycles with that target, and sees source release only after a
  later modeled CLKOUT sample. The partial board hierarchy synthesizes to
  2,495 abstract cells, 171 checks, and three retained memories with zero
  structural problems.

- The complete fifty-state BIO divider sequence, one-source-period low pulse,
  five nominal CLKOUT samples, reset-only source clear, counter continuity,
  unchanged reset-release phase, invalid-seed self-qualification, and
  resampler validity across all 256 possible seed values. Standalone Yosys
  reports 52 cells, seven checks, no
  memory/latch, and zero structural problems.

- Exhaustive standalone output-control coverage across all 65,536 port-4
  words and all 65,536 port-5 words, plus reset, retention, port isolation,
  host clear, and set-over-clear priority. Integrated smoke proves raw MUTE
  capture, data-independent IRQ assertion, host clear, and reset restoration
  while external readiness remains low. Yosys reports 33 cells/four checks for
  the standalone path and 2,495 cells/171 checks/three memories for the partial
  board hierarchy, with zero structural problems.

- Exhaustive raw-DAC coverage across all 65,536 TMS output words, every
  low-nibble alias, ports 1-7, input-side commits, no-commit retention, and
  FPGA validity. Yosys reports 14 cells, two checks, no memory/latch, and zero
  structural problems.
- Integrated port-0 output readiness independent of the external callback,
  exactly one `0xf230` to raw `0xf23` capture, and no `0x723` MAME transform.
  A separate five-cycle `LACK 0; TBLW 0x11; NOP` execution captures internal
  word `0x00a5` as raw code `0x00a` through the same target while a host
  readback proves program word zero remains `0x7e00`.
  The board hierarchy passes Yosys at 2,495 abstract cells/171 checks with its
  same three memories.
- Exhaustive standalone sample-ROM coverage across all sixteen block values,
  all 65,536 pre-increment addresses, all 256 bytes, validity/presence cases,
  response readiness, and non-port-0 isolation. Yosys reports 18 abstract
  cells, three retained checks, no memory/latch, and zero structural problems.
- Integrated port-0 ownership through a three-clock byte-response stall at
  block 3/address `0x3457`, exact synthetic `0xd5` to `0xea80` mapping, one
  commit, external-sentinel rejection, and shared-counter advance. The board
  hierarchy retains three memories and, with the raw DAC latch, passes Yosys
  at 2,495 abstract cells with 171 checks and zero structural problems.
- A documentation/model-fixture invariant independently derives physical
  sound-ROM words as `{{2{byte[7]}}, byte[6:0], 7'b0}`, preserves the distinct
  pinned-MAME oracle value, and rejects absent-block behavior as unverified.
- Complete host loading and exact DSP port-1 readback across all 512
  communication words; both CRAMEN ownership states, blocked non-owner
  accesses, owner-tagged synchronous responses, port-2 increment, 16-bit
  wrap, port-7 load, port-6 low-nibble latch, port-3 address-state isolation, invalid
  preload state, and initialization-time memory retention. Pre-technology
  Yosys retains one 512-by-16 memory in an 82-cell hierarchy with seven checks
  and zero structural problems.
- All 29 acquired reference files match their pinned SHA-256 values, including
  the official TI-hosted LS74, LS138, LS161, LS191, LS244, LS259, and LS374
  data sheets.
- End-to-end RTL host loading and safe reset handoff for the ROM-free Driver
  Sound smoke: the host preloads communication word `0x056`, port 7 first
  qualifies the address chain, internal port 1 ignores an external sentinel,
  and three reads advance `0x3456` to `0x3459`. The run still produces 12
  retirements, 22 cycles, six writes, three reads, active-low BIOZ branch,
  final ACC `0x000055aa`, and raw DAC word `0xf230`. A reset/CRAMEN host read
  proves retention. A second
  reset/reload executes LACK/TBLW/NOP in five cycles and proves low-address
  TBLW commits once to port 3 while RAM word 3 remains `0x7f83`.
- The partial board hierarchy passes pre-technology Yosys with 2,495 abstract
  cells, 171 retained checks, three memory objects, and zero structural errors.
- Complete host loading, synchronous TMS readback, and address identity across
  all 4,096 shared program words; contents survive adapter initialization,
  legal high-address TMS writes commit, low-eight writes remain I/O, and
  simultaneous host/running-DSP write attempts grant neither side. Yosys
  retains one 4,096-by-16 memory with a registered read port and merged write
  port in an 85-cell hierarchy with zero structural problems.
- A044427's complete 4,096-address combinational target decode and four-state
  host/DSP ownership truth table. Every MEN read selects 4K-by-16 program RAM;
  DEN reaches only input ports 0–7; WE reaches output ports 0–7 or program RAM
  at addresses 8–4095. Yosys 0.67+111 reports 15 combinational cells and zero
  structural problems for the standalone decoder.
- A044427 Rev-A `/DACL` latches `TD15:TD4` directly onto Am6012 `B1:B12` and
  omits `TD3:TD0`; AMD identifies those pins as uncomplemented straight-binary
  MSB-to-LSB inputs. The smoke fixture independently fixes raw physical code
  `0xf23` and MAME's conflicting derived value `0x723` for input `0xf230`.
- The synthetic Hard Drivin' source/image/tool/model workflow: twelve executed
  instructions consume 22 documented cycles, BIOZ skips the sentinel word,
  nine raw I/O transactions occur in exact order, host/sound-ROM words land in
  internal RAM, and all six output ports retain their expected words. This is
  model-level integration evidence, not game-ROM or physical-board evidence.
- Generic wrapper integration with registered program and I/O responders,
  delayed readiness, a separate three-clock global pause, exact-once OUT/IN
  and TBLW commits, documented `1/1/2/2/1/3/1 = 11` cycle total, unsupported-
  word parking, and reset recovery. Yosys 0.67+111 independently synthesizes
  the wrapper top to 15,782 generic cells with 110 retained checks and zero
  structural problems.
- Complete local assembler/disassembler acceptance across all sixty documented
  mnemonics and the first realistic test-program workflow. The synthetic FIR
  image round-trips exactly, executes twelve one-cycle instructions, sums four
  signed products to ACC `0x0d000000`, stores Q15 `0x1a00`, advances three
  history words, and matches every logical program/data transaction.
- The platform-only `clock_enable_i` phase-pause contract across every
  currently represented external transaction class. The complete native
  bus/phase suite now passes 24 tests. The 40-step program-bus BMC also proves
  held `CLKOUT` and conditionally held `MEN` when its wrapper-owned read
  qualifier is stable. Unbounded liveness remains outside this evidence.
- Original SPRU001B electrical timing resolves `OQ-001`: a TMS32010-20
  external master clock must remain within 48.78–150 ns with each pulse at
  47.5–52.5% of the period. Since `CLKOUT` divides by four, the corresponding
  physical machine-cycle envelope is 195.12–600 ns. This permits bounded
  slowing but not an indefinite pin-compatible phase stop; the RTL pause stays
  explicitly platform-only.
- Original status-word evidence now separates the five architectural fields
  from the 16-bit LST/SST representation. SPRU001B agrees that SST bits 12:9
  and 7:2 are ones and LST ignores every non-field source bit; model tests
  exercise every ignored position and RTL checks the complete `0x1efe`
  constant mask. Only stored bit 1 remains CORROBORATED under `SC-008` rather
  than being promoted beyond the conflicting primary figures.
- All 65,536 partial-RTL decoder inputs match a compact family/field-validity
  predicate in a one-step symbolic proof. Operand projections and operation
  bounds hold, eight classification covers reach step 0, and deferred
  CALA/RET/PUSH/POP words remain invalid. Database/fixture authority,
  execution, timing, and unsupported-silicon behavior are explicitly outside
  this proof.
- Standalone 144-word internal RAM passes a six-step base case and temporal
  induction over a symbolic qualified word, arbitrary initial contents, and
  arbitrary legal CPU/debug writes. Both read-after-write paths, non-target
  preservation, all 256 address-valid results, and invalid-read-zero policy
  hold; five covers reach words `0x00`/`0x8f`, non-target writes, and invalid
  `0x90`/`0xff`. This does not resolve original-silicon `OQ-002` behavior.
- All 2^32 standalone multiplier input pairs in a one-step symbolic proof.
  Ordinary pairs equal the explicitly sign-extended signed product; equal
  `0x8000` operands uniquely select the documented `0xc0000000` exception.
  Commutativity and zero/unity identities also hold, with four independent
  boundary covers reached at step 0. Instruction sequencing, physical timing,
  and technology mapping remain outside this proof.
- A 40-step bounded proof over the standalone native program bus leaves
  logical reset, clock enable, read qualification, and next address arbitrary.
  It proves boundary-only reset recognition without premature read abort,
  inactive address zero, the complete release-wait cycle, first-read
  activation, `CLKOUT`/`MEN`/sample relationships, and stall behavior. Its
  five-cycle reset/address-0/address-1 cover reaches step 34; electrical and
  original-silicon qualification are explicitly excluded.
- Recognized core reset clears PC, pending interrupt, trap state, and cycle
  count, sets INTM, suppresses all transaction classes, overrides a disabled
  clock enable, and preserves OVM. Directed testing also guards the explicitly
  provisional retention implementation for all other exposed state and RAM;
  it is not evidence of original-silicon reset values.
- Yosys 0.67+111 reports zero structural problems after the reset change:
  13,877 generic cells/26 checks for the legacy phase harness and 15,733
  cells/103 checks for the explicit sequential pipeline harness.
- Cross-checked SPRU001B's every-machine-cycle `MEN` rule with SPRU013's
  program-counter/stack description and PUSH/POP Execution blocks. Pinned
  IKA32010 instead suppresses its first PUSH/POP bus microcycle, now preserved
  as secondary-source conflict `SC-018`, not used as silicon proof.
- Exhaustively classified all 65,536 instruction words with stable counts:
  21,895 documented legal, 10,976 primary-reserved indirect-field, 372
  unresolved simultaneous-update, 3,637 documented-pattern mismatch, and
  28,656 primary-unlisted. Boundary tests distinguish legal ADD, reserved
  indirect ADD, ambiguous update, unsupported SACH/SST/branch fields, and an
  unlisted fixed-control gap.
- Corroborated original-guide instruction-set completeness against SPRU013's
  independently complete first-generation summary and individual-description
  contract. All 28,656 no-pattern words can therefore be called primary-
  unlisted while their silicon behavior remains UNKNOWN.

- Original-part `ADDH=0x60xx` encoding, one-cycle/common-address behavior,
  modulo high-half result, and unconditional low-half preservation through
  hand fixtures, model/tool, exhaustive decode, directed RTL, native-phase,
  pipeline-offset, and seeded differential tests. OV preservation and OVM
  independence remain CORROBORATED—not silicon-verified—under resolved
  `SC-017`/`OQ-011`.

- Existing repository is on `main` with a clean initial commit.
- Eight repository/provenance tests pass; all 14 cached initial sources match
  their recorded SHA-256 values.
- Initial encodings for `LACK`, `NOP`, `ZAC`, `ROVM`, and `SOVM` are
  transcribed from TI SPRU001B; database collision, fixture, and directed model
  tests pass over the supported boundary.
- `LARK`, `LARP`, and `LDPK` immediate boundaries and AR/ARP/DP effects agree
  between independent model and RTL paths across the seeded mixed trace.
- Native phase integration test proves address-0 startup, sequential sampling,
  same-boundary retirement, phase stalls, trap hold, and reset realignment for
  the supported subset.
- Yosys 0.33 parses, checks, and synthesizes the integrated partial hierarchy
  without structural-check failures or inferred latches; Quartus still passes
  full fit and timing after the portability changes.
- CI policy regression checks enforce immutable action references,
  read-only repository permissions, required build commands, and exclusion of
  the ignored reference cache.
- Hand fixtures and directed tests verify legal `LAC` direct/indirect words,
  negative and boundary shifts, DP/ARP addressing, post-access AR updates,
  lossless noncanonical aliases, and rejection of reserved controls.
- RTL tests verify `LAC` sign extension and all documented shift extremes,
  direct page boundaries, pre-modification indirect reads, low-nine-bit AR
  wrap, ARP update/preserve behavior, one-cycle retirement, and trapping of
  unresolved RAM addresses.
- The 512-instruction seeded differential now compares internal `LAC`
  address/read/data traces as well as all qualified architectural state.
- Yosys 0.33 synthesizes the RAM-integrated hierarchy with zero structural
  check failures or inferred latches; Quartus 17.0.2 reports zero unconstrained
  timing categories after explicit harness exclusions and positive setup/hold
  slack at 50 MHz.
- Hand fixtures and directed tests verify `SACL` direct/page-one writes,
  low-word selection with full-ACC preservation, indirect pre-modification
  addresses, counter wrap, ARP update/preserve, invalid-address traps, and
  one-cycle retirement.
- The seeded differential compares every logical SACL write
  and all 144 final RAM words after 512 steps.
- Hand fixtures and directed tests verify all three documented `SACH` shifts,
  cross-half bit transfer, direct/indirect writes, accumulator/status
  preservation, both data pages, unresolved-address trapping, post-access
  AR/ARP updates, and one-cycle retirement.
- The seeded differential compares logical SACH writes and
  all final RAM words; undocumented shifts 2, 3, 5, 6, and 7 fail decode.
- The prior SACH synthesis checkpoint produced 7,844 Yosys generic cells with
  eight assertions, zero latches, and clean pre/post checks.
- Hand fixtures and directed tests verify `ZALH`/`ZALS` direct and indirect
  reads, both data pages, high/low accumulator placement, zero extension,
  accumulator/status effects, post-access AR/ARP updates, unresolved-address
  traps, and one-cycle retirement.
- The seeded 512-step differential and native-phase integration compare both
  zero-load read directions and results without changing the ordinary external
  program-fetch sequence.
- Directed model/RTL tests verify ADDS unsigned interpretation, positive
  overflow boundary, sticky OV, OVM-clear wrap, OVM-set saturation, direct and
  indirect addressing, both data pages, counter/ARP updates, unresolved-address
  traps, one-cycle timing, and native program-fetch coexistence.
- The seeded 512-step differential now compares OV in addition to ACC/OVM and
  includes deterministic ADDS overflow plus randomized common-address cases.
- Hand fixtures and directed model/RTL tests verify `AND`, `OR`, and `XOR`
  direct/indirect reads, both data pages, distinct accumulator upper-half
  effects, unchanged sticky OV/OVM, AR/ARP post-modification,
  unresolved-address traps, and one-cycle retirement.
- The seeded 512-step differential and native-phase integration now include
  deterministic and randomized logic operations with logical read-transaction
  comparison.
- Directed model/RTL tests verify ADD sign extension and shifts,
  positive/negative wrap, positive/negative OVM saturation, sticky OV, direct/page-one and
  indirect addressing, AR/ARP post-modification, one-cycle timing, native
  program-fetch coexistence, and unresolved-address trapping.
- The seeded 512-step differential now includes deterministic and randomized
  shifted ADD operations with data-read transaction comparison.
- Directed model/RTL tests verify SUB against TI's worked subtraction example,
  negative-source sign extension, shifts, positive/negative wrap,
  positive/negative OVM saturation, sticky OV, direct/page-one and indirect
  addressing, AR/ARP post-modification, one-cycle timing, native
  program-fetch coexistence, and unresolved-address trapping.
- The seeded 512-step differential includes deterministic and randomized
  shifted SUB operations with data-read transaction comparison.
- Directed model/RTL tests verify SUBS against TI's unsigned-source worked
  example, distinguish it from sign-extending SUB, cover negative wrap and
  saturation, sticky OV, the unreachable positive-overflow boundary,
  direct/page-one and indirect addressing, AR/ARP post-modification,
  one-cycle timing, native fetch coexistence, and unresolved-address trapping.
- The seeded 512-step differential includes deterministic and randomized SUBS
  operations with data-read transaction comparison.
- All 16 acquired reference files match their manifest SHA-256 values.
- Atari drawing A044427 identifies a physical TMS32010 with a 20 MHz crystal;
  MAME's C10 device selection is recorded as a secondary-source conflict.
- Original TI pages and the later C14/E14 variant page were compared directly
  with pinned MAME for `ABS`. SPRU013's instruction-format rule makes the
  original page's absent status annotation meaningful, while the later
  variant explicitly adds an OV effect; `SC-007` records the scoped variant
  difference and `OQ-013` is resolved with `CORROBORATED` original-part OV
  preservation.
- Directed ABS model/RTL tests cover zero, positive, ordinary negative, and
  most-negative accumulator values under both OVM modes and both incoming OV
  values. Exact one-cycle program-only timing, exhaustive decode, implied
  assembler/disassembler round trips, seeded differential inclusion, and
  native/explicit-pipeline state preservation are checked automatically.
- Hand fixtures and directed model/RTL tests verify both `LAR` targets,
  direct/page-one and indirect reads, status preservation, unresolved-address
  traps, reserved target rejection, ARP replacement, and the selected-target
  post-modification exception.
- The seeded 512-step differential and native-phase integration compare `LAR`
  read transactions, loaded auxiliary-register values, both update-ordering
  cases, and one-cycle retirement without changing the external program-read
  sequence.
- Yosys 0.67+111 synthesizes the fifty-six-instruction hierarchy and partial
  interrupt-entry sequencer to 13,866 generic cells with 26 retained checks,
  zero latches, and clean pre/post checks;
  Quartus 17.0.2 completes analysis, fit, and TimeQuest with zero errors and
  three scoped harness warnings.
- Hand fixtures and directed model/RTL tests verify both `SAR` sources,
  direct/page-one and indirect writes, all 16 source bits, status preservation,
  unresolved-address traps, reserved source rejection, ARP replacement, and
  low-nine-bit counter wrap.
- The primary SAR warning case is automated in both directions: same-source
  `*+`/`*-` writes the post-modified value at the old address, while an
  other-source store writes that source unchanged and modifies only the
  selected address AR.
- The seeded 512-step differential, final 144-word RAM comparison, and native
  phase integration include deterministic and randomized SAR writes without
  changing the external program-read sequence.
- Four hand fixtures and exhaustive decode checks verify all 140 legal SUBC
  words without collisions. Directed model/RTL tests cover both conditional
  paths, unsigned operand alignment, address/update order, sticky-OV
  boundaries, OVM independence, unresolved-address trapping, and the legally
  scheduled 65/7 divide; native-phase and 512-step differential tests cover
  its logical read and one-cycle retirement, including 16 seeded-random
  SUBC/NOP pairs.
- Exhaustive decode verifies all 128 direct MAR NOP encodings. Hand fixtures
  and directed model/RTL tests verify representative direct forms, indirect
  increment/decrement and ARP replacement/preservation, low-nine-bit wrap,
  reserved-control traps, and canonical `LARP` decoding for alias words
  `0x6880`/`0x6881`.
- Model, RTL, native-phase, and seeded differential tests verify that MAR
  produces no logical data-memory read or write while preserving the ordinary
  one-cycle external program-fetch sequence.
- Hand fixtures and directed model/RTL tests verify both LDP source-bit values,
  old-DP direct address selection, indirect old-AR reads, AR/ARP post-update
  ordering, arithmetic-state preservation, one-cycle retirement, and
  unresolved-address/reserved-control traps.
- The seeded 512-step differential and native-phase integration compare LDP's
  logical data read, DP result, indirect updates, and unchanged external
  program-read sequence.
- Hand fixtures and directed model/RTL tests verify LT full-width loads,
  old-DP direct selection, indirect old-AR reads, low-nine-bit counter wrap,
  ARP replacement, status preservation, one-cycle retirement, and
  unresolved-address/reserved-control traps.
- The seeded 512-step differential now compares T on every boundary and
  includes deterministic/randomized LT reads; native-phase integration
  verifies that LT retains the normal external program-read sequence.
- Directed model/RTL tests verify signed MPY zero, sign, and extremal
  boundaries, direct/page-one and indirect reads, T/ACC/status preservation,
  AR/ARP post-update ordering, unresolved/reserved traps, and one-cycle
  retirement.
- The model and RTL both reproduce TI's documented original-multiplier
  exception `0x8000 * 0x8000 -> 0xc0000000`; pinned MAME independently
  corroborates it.
- The seeded 512-step differential compares P on every boundary and includes
  deterministic/randomized MPY reads; native-phase integration verifies that
  MPY retains the normal external program-read sequence.
- Hand fixtures and directed model/RTL tests verify every MPYK encoding bit,
  the signed immediate range -4096 through 4095, TI's `7 * -9` example, zero,
  T sign extremes, P replacement, architectural-state preservation, one-cycle
  retirement, and absence of logical data-memory activity.
- The seeded 512-step differential includes deterministic endpoint and
  randomized MPYK cases; native-phase integration verifies its ordinary
  external program fetch with no concurrent logical data transaction.
- Hand fixtures plus directed model/RTL tests verify PAC's exact `0x7f8e`
  decode, full-width ACC replacement, P/T/OV/OVM preservation, one-cycle
  retirement, and absence of logical data-memory activity.
- The seeded 512-step differential includes deterministic and randomized PAC
  cases; native-phase integration verifies the same ordinary external program
  fetch after MPYK.
- Hand fixtures plus directed model/RTL tests verify APAC's exact `0x7f8f`
  decode, TI's 32-plus-64 example, positive and negative overflow, OVM-clear
  wrapping, OVM-set endpoint saturation, sticky OV, unchanged P/T/address
  state, one-cycle retirement, and absence of logical data-memory activity.
- The seeded 512-step differential includes deterministic and randomized APAC
  cases; native-phase integration verifies its ordinary external program
  fetch and program-only transaction boundary.
- Hand fixtures plus directed model/RTL tests verify SPAC's exact `0x7f90`
  decode, TI's 60-minus-36 example, positive and negative overflow, OVM-clear
  wrapping, OVM-set endpoint saturation, sticky OV, unchanged P/T/address
  state, one-cycle retirement, and absence of logical data-memory activity.
- The seeded 512-step differential includes deterministic and randomized SPAC
  cases; native-phase integration verifies its ordinary external program
  fetch and program-only transaction boundary.
- Hand fixtures and directed model/RTL tests verify LTA's `0x6c` family,
  TI's RAM/T/P/ACC worked example, direct/page-one and indirect reads,
  old-address AR/ARP updates, positive and negative overflow, both OVM result
  modes, sticky OV, unchanged P, one-cycle retirement, and trap-before-effects
  behavior.
- The seeded 512-step differential includes deterministic and randomized LTA
  cases; native-phase integration verifies its internal read beside the
  ordinary external program fetch.
- Hand fixtures and directed model/RTL tests verify LTD's `0x6b` family, TI's
  three-operation RAM/T/P/ACC example, direct/page-one and indirect accesses,
  source-to-next-address copies, page crossing, positive/negative overflow,
  both OVM result modes, sticky OV, unchanged P, common post-update ordering,
  one-cycle retirement, and trap-before-effects for an unresolved endpoint.
- The seeded 512-step differential compares LTD's distinct logical source
  read and destination write plus all 144 final RAM words; native-phase
  integration verifies both internal transactions beside the ordinary
  external program fetch.
- Hand fixtures and directed model/RTL tests verify DMOV's `0x69` family,
  TI's source-preserving worked example, direct/page-one and indirect
  accesses, 127-to-128 page crossing, ACC/T/P/status preservation, common
  post-update ordering, one-cycle retirement, reserved controls, and
  trap-before-effects for an unresolved destination.
- The seeded 512-step differential compares DMOV's distinct logical source
  read and destination write plus all 144 final RAM words; native-phase
  integration verifies both internal transactions beside the ordinary
  external program fetch without LTD's T/ACC side effects.
- Hand fixtures and exhaustive decode verify only exact fixed words `0x7f81`
  and `0x7f82` as DINT/EINT while adjacent `0x7f83` still traps. Directed
  model/RTL tests verify immediate `INTM` state effects, preservation of
  unrelated state and a latched model request, reset masking, clock-enable
  hold, one-cycle retirement, and program-only transaction behavior.
- The seeded 512-step differential compares `INTM` after deterministic and
  randomized DINT/EINT cases. Native-phase integration retires EINT, a
  following NOP, and DINT at falling-edge sample boundaries without claiming
  pending-interrupt recognition or entry timing.
- Hand fixtures and exhaustive decode classify 140 legal `LST` words.
  Directed model tests exhaust the 16 combinations of loaded OV/OVM/ARP/DP
  under both old INTM values, and directed RTL tests verify direct/indirect
  address order, counter updates, status effects, INTM preservation,
  clock-enable hold, and trap-before-effects. Native-phase and seeded
  differential tests cover the same logical read and architectural state.
- Directed BANZ model/RTL tests cover both conditions, old-counter
  test-before-decrement, modulo-512 wrap, upper-bit preservation, PC wrap,
  canonical target enforcement, malformed-target trap-before-effects, and
  clock-enable hold. Native-phase tests cover both normal reads and target-read
  stalls; focused differential traces align model commits with both RTL cycles.
- Directed B model/RTL tests cover exact decode, two program reads,
  unconditional target selection, PC and operand-fetch wrap, preserved state,
  malformed-target trap-before-effects, target-phase stall, and skipped
  fall-through words. A focused differential aligns both RTL cycles with
  model commits.
- Accumulator-conditional directed tests cover all six exact opcodes, zero,
  positive, negative, maximum-positive, and most-negative predicates, both
  paths, mandatory second reads, target-phase stalls, state preservation, and
  malformed target traps. Native-phase and focused differential traces cover
  all six taken and untaken paths.
- Directed BV tests cover OV set and clear, target/fallthrough selection,
  taken-path clear at second-cycle retirement, mandatory second reads,
  target-phase stall, unrelated-state preservation, and malformed-target
  trap-before-clear. A focused differential compares per-cycle OV and every
  program transaction.
- Directed BIOZ tests reverse the raw pin in both directions between opcode
  and target samples, proving second-sample ownership and absence of an
  opcode-time latch. They also cover active-low target/fallthrough selection,
  the mandatory target read, target-phase stalls, malformed-target
  trap-before-effects, native control phases, and focused model/RTL traces.
- Directed CALL tests cover five nested calls, exact return addresses, all
  four stack levels, old-bottom discard, target-word stalls, program-counter
  and return-address wrap, malformed-target trap-before-push, and the absence
  of data-memory transactions. Native-phase and focused differential tests
  compare both program reads and the target-sample stack commit.
- Directed IN/OUT tests cover direct and indirect old-address ordering, all
  transfer directions, live input sampling, stable output data, AR/ARP
  updates, unresolved-address and reserved-control traps, exact cycle counts,
  MEN/DEN/WE exclusion, phase stalls, and model/RTL transaction agreement.
- Directed TBLR/TBLW tests cover direct and indirect old-address ordering,
  ACC-derived program addresses, RAM/program-memory direction and data,
  discarded-prefetch refetch, self-modifying code, stack-bottom duplication,
  AR/ARP updates, unresolved-address traps, exact three-cycle retirement,
  MEN/WE exclusion, phase stalls, and model/RTL transaction agreement.
- A rejected first table-transfer Quartus fit exposed 17 newly added
  program-write outputs and 2,906 output paths missing from the
  synthesis-harness exclusions. The corrected full rerun explicitly excludes
  those harness-only ports and reports zero unconstrained categories; this is
  still not wrapper I/O timing closure.
- Figure 2-12's program-read sequence is transcribed and asserted as current
  instruction, following instruction, dummy return PC, and vector 2. State
  tests independently assert masked-pulse persistence, one protected
  instruction, MPY/MPYK extension, stack push, INTM set, pending clear, and
  no retirement or data/I/O traffic during the dummy fetch.
- Active-low interrupt arrival at all 32 represented multicycle execution
  intervals passes in both core and explicit-pipeline matrices: both cycles
  of the 11 supported two-word control-flow
  families and IN/OUT, and all three cycles of TBLR/TBLW. Every path completes
  before service, retires exactly one protected instruction, dummy-fetches the
  resolved return PC while advertising vector 2 next, and enters with the
  expected stack and bus state.
- SymbiYosys v0.67-4-gfea6e46 and Bitwuzla 0.9.1 pass the 12-step actual-core
  interrupt BMC across arbitrary clock-enable choices; the separate cover
  reaches completed vector execution at step 6.
- The same formal stack passes a 14-step MPYK-extension/held-low-relatch BMC;
  its separate cover reaches the final masked-pending state at step 8.
- The same formal stack passes a 20-step direct-MPY/repeated-chain BMC across
  arbitrary clock-enable choices; its cover reaches completed entry at step
  12 after checking three exact signed products.
- The same formal stack passes a 20-step indirect-MPY BMC across arbitrary
  clock-enable choices; its cover reaches completed entry at step 12 after
  checking old address `0x8f`, product `0xffff0000`, AR0
  `0xaa8f`-to-`0xaa8e` decrement, and ARP replacement.
- A standalone 12-step BMC proves fetch/execute-register initialization,
  arbitrary-word capture, boundary stalls, incomplete retention,
  completion/replacement, bubbles, and reset/flush invalidation under two
  explicit sequencer assumptions; its cover reaches the complete
  prime/stall/replace/flush/target path at step 7.
- A 40-step actual-pipeline BMC proves one direct TBLR sequence across
  arbitrary clock-enable choices; its cover reaches the complete
  LACK/TBLR/LAC/NOP path at step 34 after checking `0x1234` program-to-RAM
  transfer and following ACC consumption.
- A second 40-step actual-pipeline BMC proves one direct TBLW
  self-modification sequence across arbitrary clock-enable choices; its cover
  reaches step 35 after the old ZAC is discarded, `0x7e44` is written exactly
  once at program address 2, refetched, and executed as `LACK 0x44`.
- Yosys 0.67+111 synthesizes the
  exact-B/BANZ/BV/BIOZ/CALL/accumulator-branch/IN/OUT/TBLR/TBLW/interrupt
  sequential pipeline wrapper, including ADDH, to 15,686 generic cells with
  103 retained
  checks and zero structural errors;
  `make synth-yosys` now reproducibly runs this top as well as the
  13,866-cell/26-check legacy harness.
- Directed pipeline tests prove that fetch 0 does not retire, fetch and execute
  addresses remain one word apart across stalls, every word in the qualified
  one-cycle stream matches legacy architectural state at one-retirement
  offset, an unsupported control word cannot enter the qualified execution
  path, and reset recovers the parked pipeline.
- A directed B pipeline test proves operand nonexecution, retained B ownership,
  redirected target fetch, two execution intervals, target-fetch stall
  stability, no early target effect, target execution in the following
  interval, and conservative malformed-operand parking.
- A directed BANZ pipeline test proves both old-counter outcomes, target or
  fallthrough selection before decrement, nine-bit modulo wrap with upper-bit
  preservation, retained ownership and register stability through a selected
  fetch stall, deferred fetched-instruction effects, and malformed-operand
  parking before counter mutation.
- A directed accumulator-branch pipeline matrix proves taken and untaken
  selection for every exact predicate, zero/positive/negative ACC
  distinctions, full-ACC preservation, retained ownership through stalls on
  both selected paths, deferred selected-instruction effects, and malformed
  operand parking.
- A directed BV pipeline test proves selection from the old sticky OV state,
  retained ownership and unchanged OV through operand and selected-fetch
  stalls, taken-path clear only at retirement, deferred selected-instruction
  effects on both outcomes, and malformed-operand parking before OV mutation.
- A directed BIOZ pipeline test proves the opcode-prefetch level is not
  latched, a pin change during an operand stall owns the decision at operand
  completion, later pin changes cannot redirect the selected fetch, both
  paths retain ownership through stalls, selected-instruction effects are
  deferred, and malformed operands park before speculative selection.
- A directed CALL pipeline test proves operand nonexecution, no push through
  operand or selected-target stalls, opcode-PC+2 push only at retirement,
  nested stack shifting, full non-stack state preservation, deferred target
  effects, and malformed-operand parking before a push.
- A directed IN/OUT pipeline test proves port-address/strobe ownership,
  MEN/DEN/WE mutual exclusion, live IN sampling, stable OUT data, independent
  stalls in both execution intervals, no early RAM or AR/ARP mutation,
  following-word effect deferral, and invalid-address parking before any
  native transaction.
- A directed TBLR/TBLW pipeline test proves retained execute ownership across
  all three Figure 2-10 intervals, mutually exclusive MEN/WE activity,
  independent stalls, deferred RAM/AR/ARP/stack/retirement effects, and a
  self-modifying TBLW whose discarded old PC+1 word never executes.
- A directed interrupt pipeline test proves masked-request retention through
  B/EINT, protected-instruction retirement, stalled N+2 discard, stalled
  vector fetch without early stack push, return-PC entry state, and deferred
  vector execution.
- A directed explicit-pipeline multiply test proves MPY and MPYK signed
  results, internal-read versus program-only bus shape, stalls, one additional
  protected retirement, discarded dummy words, post-following stacked PCs,
  vector capture, and deferred vector effects.
- The ignored reference cache verifies both newly acquired primary documents
  by SHA-256. Cross-sheet pin tracing now checks that low-I/O LS138 `30N`
  requires `/RVF` as well as `/RVAS`, and the documented MC68000 edge table
  accounts for every F74 transition from `/AS` assertion through S7.
- The standalone host-timing regression passes 8,192 exhaustive
  alias/address/direction/quadrant transactions plus directed byte-strobe,
  VPA, delayed-release, held-`/AS` no-retry, and FPGA-reinitialization cases.
  Yosys reports 142 abstract cells, 24 retained checks, no memory or latch,
  and zero structural problems. The integrated board regression additionally
  checks all four timed reads and writes, exact masked S4-through-S6 data,
  S7 mailbox/control effects, partial-write rejection, unimplemented speech
  visibility, and external-callback selection. Integrated Yosys retains three
  memories at 2,966 cells/257 checks. That checkpoint regression passed 127
  repository/tool, 231 model/unit, 38 instruction RTL, 42 bus/wrapper, 5
  interrupt, and 10 differential tests; strict lint across 30 modules, all
  twenty Yosys targets, all 33 reference hashes, and all 28 tasks from
  fourteen formal configurations pass. The adapter BMC passes through 16
  steps; its whole-word read/write covers reach step 8 and the fully settled
  VPA cover reaches step 9. The separate board BMC passes 12 steps and reaches
  all seven timing-derived routing covers at solver step 10. Both proofs remain
  scoped to common-clock digital behavior, not raw-pin CDC or electrical
  timing.
- An earlier checkpoint regression passed 124 repository/ISA/tool tests, 231
  directed model/unit tests, 38 exhaustive/directed instruction RTL tests, 33
  native bus/phase/wrapper tests including the exhaustive mailbox test and
  thirteen explicit pipeline tests, five
  interrupt RTL/phase tests, one 512-step seeded
  model/RTL differential, six focused two-cycle control-flow differentials,
  one focused IN/OUT differential, one focused TBLR/TBLW differential, and
  one focused interrupt-entry differential.

- The local-68000 memory decoder passes 131,072 exhaustive control-relevant
  combinations covering every ignored `A22:A17` alias, bank, transfer
  direction, and byte-strobe state. Yosys 0.67+111 reports 56 combinational
  cells, 17 checks, no memory/latch, and zero structural problems.
- The local-memory timing bridge passes complete synthetic ROM-valid,
  ROM-invalid, unwritten-SRAM, full-word SRAM, upper-byte SRAM, Y5 program,
  Y5 direct-I/O, Y6 communication, and isolated Y4 transactions. Yosys reports
  305 combinational hierarchy cells, 40 retained checks, no storage/latch,
  and zero structural problems.
- The upper-Y5 direct-I/O regression exhausts all 4,096 read and 4,096 write
  addresses, and the integrated board regression verifies canonical S6 write
  commits, S7 read completions, physical read aliases, unselected writes,
  masked read carriers, and ownership-conflict suppression. The complete
  regression split is 128/231/38/44/5/10; strict lint covers 32 modules, all
  22 Yosys targets pass, all 33 pinned hashes verify, and all 30 formal tasks
  from 15 configurations pass.
- The local-reset increment passes the complete 129/231/38/45/5/10 regression
  split, strict lint across 33 modules, all 23 Yosys targets, all 33 pinned
  reference hashes, and all 32 formal tasks from 16 configurations.
- The physical reset-source increment passes the complete
  129/231/38/46/5/10 regression split, strict lint across 34 modules, all 24
  Yosys targets, all 34 pinned reference hashes, and all 34 formal tasks from
  17 configurations.
- The main sound-reset decode increment passes the complete
  129/231/38/47/5/10 regression split, strict lint across 35 modules, all 25
  Yosys targets, all 34 pinned reference hashes, and all 36 formal tasks from
  18 configurations.
- The main `/RVAS` timing increment passes the complete
  129/231/38/48/5/10 regression split, strict lint across 36 modules, all 26
  Yosys targets, all 34 pinned reference hashes, and all 38 formal tasks from
  19 configurations.

### Known Issues

- TM-356 proves that one Race Drivin' field procedure places `136077-1017` at
  physical `45C`/block 8, while pinned MAME exposes that file at packed block
  4. An authorized firmware trace is required to determine the production
  port-6 value and any emulator consequence. Exact factory population and the
  electrical result of selecting an empty or undecoded block remain unknown.
- Neither `A046491-01` nor `A046491-02` has a reviewed Sound PCB assembly BOM
  or option drawing that identifies E1/E2 and installed program-EPROM types.
  Even a distinct 27512 image proves only that A16 is information-bearing for
  that content; a board-specific strap claim still requires physical
  continuity or authoritative assembly evidence (`OQ-034`).
- Published cockpit/compact wiring does not connect Driver Sound J3, but
  physical `A046491-01`/`A046491-02` header population, field options, open
  LS244 input voltage/read value, and other cabinet revisions remain
  unmeasured. `OQ-032` prohibits a forced zero/one production default.
- No authenticated alternate Driver Sound drawing, ECO, rework notice, or
  physical/authorized normal-game capture resolves the Rev-A raw DAC wiring
  against MAME's signed interpretation. A production-default digital audio
  transform remains blocked even though the raw latch is qualified.
- No authenticated original-TMS32010 erratum, product-change/mask notice,
  package-code decoder, or period BBS specification-update archive has been
  located. `OQ-008` remains open, and measurements on one specimen cannot be
  called mask-invariant.
- The explicit pipeline closes the current 25 MHz Cyclone V internal target
  but not the exploratory 50 MHz target; the rejected fit has -9.098 ns worst
  slow-corner setup slack. This still exceeds the Driver Sound board's 20 MHz
  processor clock, but further pipelining/critical-path work is required before
  any higher-frequency claim.
- The optional FPGA local SRAM needs 8,192 clocks to invalidate metadata after
  `initialize_i`. This is an integration convention, not physical 6264 reset
  or wait behavior. The wrapper gates exported local RESET/HALT release, but a
  future MC68000 integration must compose the now-qualified common Rev-A reset
  source with a calibrated tick, raw-input CDC, component-tolerance policy,
  and the selected core's reset interface under `OQ-035`. The nominal
  155.1 ms calculation is not a production-board pulse-width guarantee.
- A044427's `RVA`/`/DTACK`/`/RVAS` logic and same-clock board composition are
  qualified at logical bus-state resolution, but complete TTL
  propagation/loading margin, raw-pin CDC, and unreset power-up transient are
  not. The board-faithful path cannot insert arbitrary callback stalls
  because the circuit has no READY input or held-`/AS` re-arm (`OQ-033`).
- A production A044427 Rev-A port-2 word is electrically unqualified. The
  drawing routes only `CMPOUT` to `TDI15`, while the complete source and pull-up
  sheet is not loaded; pinned MAME's `0x0000` handler is a deterministic stub,
  not hardware evidence (`SC-029`/`OQ-029`).
- The parallel sample-ROM callback is implemented, but exact population remains
  board/revision data and authorized storage is external. An absent block
  leaves the shown physical data bus undriven; the adapter reports and stalls
  instead of returning a protective zero (`OQ-026`).
- The communication-RAM/address adapter is connected to
  `hard_drivin_sound_mister`, and the opt-in same-clock Y6 path now supplies
  its host cycles. CRAMEN remains an explicit ownership input unless the
  separate host-control opt-in supplies Q3; no raw-pin/CDC 68000 boundary
  exists. Its registered response is an FPGA convention, not physical HM6116
  timing. Original-MC68000 byte capture is resolved as `{byte, byte}`, but
  authorized-firmware access widths and substitute-68k inactive lanes remain
  unresolved under `OQ-024`.
  Pinned MAME still conflicts by returning RAM during host ownership and by
  omitting the global `/PDEN` increment from port 2. Port 3 is now resolved;
  its undriven host low byte remains a distinct open-bus question (`OQ-030`).
- Original-MC68000 mailbox byte capture is resolved as `{byte, byte}`, but
  authorized firmware use, exact LS74 behavior when write-preset releases at
  the opposite read-clock edge, and substitute-68k inactive-lane behavior
  remain unresolved under `SC-031`/`OQ-031`. No raw main-system or CDC bridge
  consumes the already-captured-word callback.
- The raw `/READSTAT` mapper is board-top connected to the mailbox flags and
  explicit raw test/ready inputs, but no 68000 read decode exists and physical
  `D11:D0` remain unresolved under `OQ-030`; MAME's fixed
  test/ready/low-lane values are isolated as `SC-032` rather than promoted to
  board behavior.
- The raw `/SWITCHES` mapper and masked selector are board-top connected but
  assign no cabinet functions or
  inactive levels to `J3-11/J3-9/J3-8/J3-7` under `OQ-032`. Pinned MAME swaps
  the `/SWITCHES` and `/320PORT` handler names relative to Atari LS138 `30N`
  and returns zero from both; `SC-033` prevents either stub from defining a
  board selector. The selector is not `/RVAS`, DTACK, a completed read, or an
  open-bus policy; physical `D11:D0` remain `OQ-030`.
- `hard_drivin_sound_mister` is only the processor/program/communication-RAM/
  sample-ROM-callback/BIO-generator and qualified physical-I/O boundary. It
  lacks the 68000 bridge, actual sample storage, compare/DAC-analog
  implementations, a board 1 MHz enable source, and a
  loaded mute consumer; raw MUTE and 68000-IRQ latch state are implemented but
  do not establish effective audio semantics or the host address decoder;
  its synchronous ready/commit callbacks are implementation conventions, not
  physical SRAM pins. Its Yosys result is not a Cyclone V fit or timing result,
  and the future raw 68000 bridge must reproduce the qualified original-
  MC68000 duplicated inactive lane or explicitly adapt substitute-CPU behavior
  under `SC-022`/`OQ-022`.
- The BIO divider/resampler is primary-transcribed and connected as an opt-in,
  but the physical counters and CLKOUT resampler have no board-reset
  initialization, and their 1 MHz/CLKOUT clocks derive from independent
  crystals. The current same-clock boundary preserves exported validity and
  rejects, rather than models, coincident edges under `OQ-028`; MAME's
  query-driven 20 kHz event is not a pin-level replacement (`SC-028`).
- A044427 has no program-RAM arbiter. Simultaneously selecting the host window
  while `/320RES` is released enables conflicting buffer paths; pinned MAME's
  always-accessible shared array and HALT mapping do not reproduce that
  electrical contract (`SC-020`/`OQ-021`). The digital wrapper rejects overlap,
  but actual 68000 firmware compliance and handoff timing remain unqualified.
- A044427 Rev A directly wires the 12-bit Am6012 code, while pinned MAME
  complements bit 11 before its unsigned DAC mapper and describes that as a
  schematic inversion. No inverter is present in the reviewed drawing.
  `SC-019`/`OQ-020` therefore keep the signed PCM conversion and possible
  production ECO/variant difference unresolved; only raw `data[15:4]` is
  primary-qualified and implemented. Analog/sample interpretation remains
  unresolved.
- All 60 documented instruction mnemonics have model/tool evidence; fifty-eight
  also have RTL/differential evidence. PUSH and POP remain outside RTL/native
  qualification because their external address ownership is unresolved.
- The exhaustive primary-documentation partition contains 28,656
  `PRIMARY_UNLISTED_ENCODING` words and 372 simultaneous-update words under
  `OQ-010`/`SC-040`. A later C1x card prohibits the simultaneous control form,
  but does not define original forced-word execution. MAME/IKA no-net-update
  behavior remains hypothesis evidence; unsupported silicon behavior is
  unclaimed and the model/RTL trap is only conservative project policy.
- MAME models untaken BANZ as one cycle and does not fetch its following target
  word, contrary to original TI's unconditional two-word/two-cycle entry. MAME
  remains a functional oracle only for this instruction (`SC-012`).
- MAME also shortens untaken BV to one cycle and omits its target read;
  project behavior follows TI's unconditional two-cycle entry (`SC-014`).
- MAME also shortens untaken BIOZ to one cycle and does not read the target;
  it exposes an abstract asserted callback rather than documenting physical
  pin polarity. Project behavior follows TI's active-low pin and unconditional
  two-cycle entry (`SC-015`).
- Original TMS32010/first-generation LST pages say both that the memory word
  restores ARP and, in `LARP 0; LST *,1`, that ARP becomes one without stating
  word bit 8. Later TI/MAME implement memory-wins; pinned IKA implements
  encoded-field-wins. The current memory-word policy remains PROVISIONAL under
  `OQ-015`/`SC-009`; the stable physical probe has no expected silicon result.
- The located original PUSH/POP pages do not show per-cycle program-address or
  fetched-word ownership. TI's general pin table establishes active `MEN` in
  both non-I/O cycles, while pinned IKA32010 models an idle first microcycle;
  this is `SC-018`. State effects and numeric totals are model/tool-qualified,
  but native/RTL sequencing remains deferred under `OQ-016`; no repeated or
  speculative prefetch has been assigned. A physical experiment now defines
  the smallest resolving evidence.
- TI requires the instruction after SUBC not to use ACC but does not establish
  observable behavior for a violation; current same-boundary result commit is
  an implementation convenience under `OQ-017`. Related-patent staging
  explains the prohibition but is not a production waveform. TI also says
  SUBC affects OV without identifying the producing arithmetic stage;
  related-patent ALU-derived status supports intermediate subtraction, pinned
  IKA flags its final stage, and MAME's intended intermediate check is
  ineffective. Sticky OV remains PROVISIONAL under `OQ-018`.
- Interrupt external fetch order and directed entry state are verified, but
  the partial core still collapses fetch and execution at sample boundaries.
  The 32 represented multicycle arrival intervals are independently qualified
  in the core and explicit pipeline;
  the current wrapper's four digital subphases now have falling-boundary
  sampling assertions. Physical
  setup/synchronizer behavior, PUSH/POP cycles, and physical confirmation of
  ADR-0003 remain under `CTRL-002`/`OQ-004`/`OQ-007`/`OQ-016`.
- No dedicated original-part branch pin waveform has been located. Exact B,
  BANZ, BV, BIOZ, CALL, and the six accumulator-branch explicit
  execute-interval mappings are INFERRED from Figure 2-2, the
  two-word/two-cycle table entries, and their operand/condition definitions,
  with directed simulation evidence under `OQ-007`.
- CALA/RET state effects and numeric two-cycle totals are model/RTL-qualified.
  Their explicit discarded-sequential/selected-target sequence is
  CORROBORATED for RET by a related TI patent and remains INFERRED for CALA;
  neither is original-part pin proof under `OQ-007`/`SC-037`.
- DINT in the already-pipelined final slot currently cancels entry while
  retaining the request. Original and later TI guides conflict on whether N+1
  executes before entry; both require or recommend external conditioning for
  asynchronous NMOS input. MAME cannot
  express the exact overlap, while pinned IKA predicts entry-wins. That
  ordering is targeted-tested but PROVISIONAL under `OQ-019`/`SC-039`, with a
  stable physical experiment now defined.
- Formal evidence currently covers seven fixed interrupt-entry programs,
  including protected-DINT policy and both arrival intervals of one fixed B,
  all three arrival intervals of one fixed direct TBLR, plus one fixed CALA/RET
  call/return program, at 12-, 14-, two 18-, and three 20-step bounds, one
  standalone ownership register, and
  fixed direct-TBLR and direct-TBLW integrated-pipeline programs at 40 steps.
  It excludes arbitrary DINT placement and original-silicon priority, the
  other indirect MPY control/update cases, arbitrary multiply-chain
  placement/length, the remaining represented multicycle-arrival families
  including TBLW, indirect table addressing, the general
  pipeline, general external-memory behavior, and broad decode/datapath
  properties.
- Original-part ADDH status behavior is resolved only at CORROBORATED
  confidence under `SC-017`/`OQ-011`: the implementation preserves OV,
  ignores OVM, and never saturates, but original-silicon measurement is still
  needed to upgrade confidence. Physical-reset retention of unlisted state
  remains unresolved as `OQ-012`; EVM warm-save behavior now corroborates the
  hypothesis, but both complementary original-device captures remain absent.
  ABS result and
  timing are primary-verified; its OV preservation is explicitly
  `CORROBORATED`, not physical-hardware verified, under resolved `OQ-013`.
- Original-part DMOV/LTD behavior when source `0x8f` implies destination
  `0x90` remains unresolved under `OQ-014`; the partial implementation traps
  before all effects and labels that policy provisional. Stable physical probe
  images now define the smallest clear/scan/register experiment, but no
  original NMOS capture is available.
- Ordinary original-part reads and writes at `0x90`-`0xff` remain unknown
  under `OQ-002`/`SC-041`. The current core trap and standalone diagnostic
  zero are fail-closed policies. Stable read-only and directional write/scan
  fixtures exist, but no original-NMOS capture or qualified RAM decap is
  available.
- Remaining indirect control-flow/return traces, interrupt execute ownership,
  original-silicon SST bit-1 qualification, and out-of-range RAM behavior
  remain open.
- The execution core still has an instruction-step test interface; the
  native-phase wrapper covers the qualified normal, branch, I/O, table, and
  interrupt program-read sequences but not the complete overlapped pipeline.
- The standalone core intentionally retains its asynchronous RAM read. The
  phase-aware wrapper uses ADR-0004's registered one-M10K mapping; this does
  not qualify an arbitrary caller to enable registered mode without address
  lead time.
- Yosys, iverilog, SymbiYosys, and pytest are not currently available on the
  local executable path. Yosys is qualified in an isolated Ubuntu 24.04
  environment; the host target still fails explicitly when the tool is absent.
