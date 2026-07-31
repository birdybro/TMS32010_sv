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
  work includes AC waveform transcription, exact reserved status bits,
  out-of-range RAM decode, and first-fetch/interrupt phase traces. Physical pin
  timing and logical transaction timing must remain distinct.

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
- **Notes:** Twenty-six encodings (`ADD`, `ADDS`, `AND`, `LAC`, `LACK`, `LAR`,
  `LARK`, `LARP`, `LDP`, `LDPK`, `LT`, `MAR`, `MPY`, `NOP`, `OR`, `ROVM`,
  `SACL`, `SACH`, `SAR`,
  `SOVM`, `XOR`, `ZAC`, `ZALH`, `ZALS`, `SUB`, `SUBS`) are
  primary-transcribed in the opcode research table. The seventeen
  common-address data instructions add
  conditional legality constraints for
  indirect control bits; SACH additionally restricts its sparse shift field
  to 0, 1, and 4. The
  decoder exhaustively classifies all 65,536 words against this partial set
  without collisions; the remaining 34 instructions and full reserved-region
  classification remain. `ABS` encoding `0x7f88` is primary-transcribed in
  the research notes but deliberately withheld from the supported database
  and fixtures until its original-part `OV` behavior is resolved under
  `SC-007`/`OQ-013`. Hand fixtures must not be generated by the assembler.

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
- **Notes:** Independent model supports `ADD`, `ADDS`, `AND`, `LAC`, `LACK`,
  `LAR`, `LARK`, `LARP`, `LDP`, `LDPK`, `LT`, `MAR`, `MPY`, `NOP`, `OR`,
  `ROVM`, `SACL`, `SACH`,
  `SAR`, `SOVM`, `XOR`, `ZAC`, `ZALH`, `ZALS`, `SUB`, and `SUBS`,
  raw program loading, logical program/data traces, reset-boundary effects,
  and deterministic replay. The seventeen common-address data instructions
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
  word bits into T through the same address/update order. `MPY` produces a
  signed 16-by-16 P result through that same path and reproduces the
  documented `0x8000`-by-`0x8000` exception. Its interrupt deferral remains
  outside the model until interrupt entry exists. ADDS
  covers unsigned-source arithmetic, sticky OV, wrap, and positive saturation.
  ADD covers sign extension, shifts 0–15, sticky OV, wrap, and both
  positive/negative saturation endpoints. SUB covers the corresponding
  subtraction, shift, wrap, sticky-OV, and saturation cases.
  SUBS covers unsigned-source subtraction, sticky OV, negative wrap, and
  negative saturation.
  AND/OR/XOR cover low-half logic, their distinct upper-half behavior, and
  unchanged OV/OVM.
  Out-of-range original-RAM addresses and unsupported words trap. Interrupts,
  remaining memory/I/O instructions, and pin phases remain unimplemented.

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
- **Notes:** Qualified slice supports the same twenty-six instructions as the
  model, labels, expressions, `.word`, `.org`, `.include`, raw/hex/listing
  output, lossless unknown-word disassembly, and round trips. `LAC` and `SACL`
  support checked direct and indirect TI syntax, including SACL's required
  zero placeholder before a next ARP, SACH's sparse 0/1/4 shifts, and
  ADD/LAC/SUB common address syntax with shifts, `LAR`/`SAR` target-register
  syntax, MAR direct/indirect syntax and LARP aliases, and
  ADDS/AND/LDP/LT/MPY/OR/SUBS/XOR/ZALH/ZALS syntax without a shift operand.
  The remaining 34
  documented instructions are rejected explicitly. A surviving
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
  twenty-six-instruction slice. `LAC`
  verifies sign extension and left shifts; `SACH` verifies its output-shifter
  cross-half behavior; `ZALH`/`ZALS` verify accumulator half placement; all
  seventeen common-address data instructions verify direct/indirect read/write
  addressing and low-nine-bit AR updates. `LAR` additionally verifies that an
  indirect load into the selected address register suppresses its otherwise
  requested post-modification. `SAR` verifies the distinct same-source rule:
  it stores the post-modification value at the pre-modification address.
  `MAR` verifies low-nine-bit AR update and ARP replacement without touching
  the RAM datapath.
  `LDP` verifies old-DP/old-AR address selection and source-bit transfer into
  DP before the common indirect post-update.
  `LT` verifies full-word transfer into T through the same old-address and
  post-update ordering.
  `MPY` verifies signed products, the original most-negative exception, and
  P replacement through the same old-address/post-update order. Its
  combinational portable multiplier infers one Cyclone V DSP block in the
  current Quartus harness.
  ADDS additionally verifies sticky
  overflow, OVM-clear wrap, and OVM-set positive saturation. AND/OR/XOR verify
  low-half logic, AND upper clearing, OR/XOR upper preservation, and unchanged
  overflow state. ADD and SUB verify signed shifting, general signed overflow,
  wrap, and both saturation endpoints for their respective arithmetic.
  SUBS verifies zero-extended subtraction, negative wrap/saturation, and
  sticky OV.
  Physical reset
  preserves OVM as documented and assigns no arbitrary value to
  ACC/T/AR/ARP/DP/OV or RAM; retention of unlisted FPGA state remains
  provisional under OQ-012. ALU, multiplier, other output-shifter consumers,
  stack, and remaining status behavior remain.
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
  `sim/instruction/tb_sequencer.sv`, `formal/sequencer/`
- **Notes:** Temporary one-enable instruction execution and
  trap-without-PC-advance are verified. The sequential phase wrapper now
  retires each of twenty-six supported one-cycle instructions, including all
  seventeen internal-data operations, on its falling-edge sample and aligns
  PC/native address across stalls, traps, and reset. General overlap, branch,
  multi-cycle, and interrupt control do not exist yet.

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
  `sim/bus/tb_phase_slice_integration.sv`
- **Notes:** Appendix A normal read and table-transfer pin waveforms are
  transcribed. The four-subphase normal-read/reset engine verifies
  falling-edge sampling, quarter-cycle MEN assertion, address stability, and
  release delay. A partial wrapper integrates those phases with all twenty-six
  supported sequential instructions, checks that internal logical data
  activity retains a normal external program read, and holds PC/address on
  traps and stalls. Table cycles, branch/call/return, general pipeline overlap,
  and interrupt sequences remain. Do not collapse Harvard spaces in the native
  interface.

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
  `ADD`/`ADDS`/`AND`/`LAC`/`LAR`/`LDP`/`LT`/`MPY`/`OR`/`SACL`/`SACH`/`SAR`/`SUB`/`SUBS`/
  `XOR`/`ZALH`/`ZALS` model/RTL tests cover valid address selection, logical
  read/write traces, ordering, and explicitly trap unresolved `0x90`–`0xff`.
  The portable RTL contains exactly 144 words and a nonarchitectural preload
  port. Directed tests read back every store class; seeded differential
  compares all 144 final words. Remaining instruction interactions remain.
  Variant RAM sizes must not leak into the TMS32010 default.

## Milestone 11 — I/O interface

### BUS-003 — Native I/O-space transactions

- **Status:** NOT STARTED
- **Priority:** P0
- **Dependencies:** RTL-002, ARCH-001
- **Description:** Implement documented I/O address, data, strobes, ready, and
  cycle behavior separately from program and data spaces.
- **Acceptance criteria:** all IN/OUT timing and wait cases match automated
  primary-sourced traces.
- **Documentation:** `docs/architecture/external_interface.md`
- **Tests:** `sim/bus/tb_io_bus.sv`
- **Notes:** Hard Drivin' mappings belong in an integration wrapper.

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

- **Status:** NOT STARTED
- **Priority:** P0
- **Dependencies:** CTRL-001, RTL-002
- **Description:** Implement interrupt recognition, masking, acknowledge,
  latency, priority, return behavior, BIO sampling, and pipeline interaction.
- **Acceptance criteria:** every recognition boundary and latency case has an
  automated cycle/bus assertion; deferred/ignored cases are verified.
- **Documentation:** `docs/architecture/interrupts.md`
- **Tests:** `sim/interrupt/tb_interrupt.sv`, `sim/interrupt/tb_bio.sv`
- **Notes:** Edge versus level behavior remains unknown until cited.

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
  `SOVM`) passes model, RTL, toolchain, and differential tests. Cycle evidence
  is qualified only for the current sequential native-phase boundary. `LAC`
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
  `MPY` now passes functional database/model/tool/RTL, one-cycle,
  native-phase, and randomized differential tests for signed P results,
  including TI's most-negative multiplier exception. Its documented
  one-following-instruction interrupt deferral remains unverified under
  `INT-001`.
  `ADDH` remains explicitly unimplemented under `SC-006`/`OQ-011`; `ABS`
  remains explicitly unimplemented under `SC-007`/`OQ-013`. The rest of the
  arithmetic and load/store families remain. Maintain one subtask per family
  when implementation begins.

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
  timing is transcribed. One-cycle retirement for all seventeen qualified
  internal-data instructions plus MAR, including all three logic operations, is
  asserted through the partial native-phase
  integration. Control-flow, interrupt-entry, and most per-instruction
  ownership remain. Electrical delays are wrapper constraints, not RTL delays.

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
  `ADD`/`ADDS`/`AND`/`LAC`/`LAR`/`LDP`/`LT`/`MPY`/`OR`/`SUB`/`SUBS`/`XOR`/
  `ZALH`/`ZALS`
  reads, `SACL`/`SACH`/`SAR` writes, and final 144-word RAM agreement over an
  identical deterministic image. MAR direct/indirect cases compare AR/ARP
  changes and
  inactive logical data strobes. LDP direct/indirect cases compare the logical
  read, DP source-bit result, and common AR/ARP post-update. LT cases compare
  the logical read, full-width T result, and common AR/ARP post-update. MPY
  cases compare signed P results, TI's most-negative exception, and common
  post-update ordering. MAME comparison and legal randomized full-ISA streams
  remain. MAME disagreement
  creates research work, not an automatic oracle verdict.

## Milestone 18 — Formal verification

### FORMAL-001 — Bounded safety and liveness properties

- **Status:** NOT STARTED
- **Priority:** P1
- **Dependencies:** RTL-001, RTL-002, TIMING-002
- **Description:** Prove reset, decode, FSM, bus, stack, PC, repeat, interrupt,
  RAM-bound, transaction, and arithmetic properties.
- **Acceptance criteria:** proofs pass at documented bounds and assumptions;
  cover statements demonstrate non-vacuity.
- **Documentation:** `formal/README.md`
- **Tests:** `make formal`
- **Notes:** Never describe bounded checks as complete proof.

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
- **Notes:** Twenty-six-instruction RTL, phase engine, multiplier, and
  144-word RAM are
  qualified in both synthesis flows; exact current utilization, internal Fmax,
  slack, warning scope, and generic-cell totals are recorded in
  `synthesis/qualification.md`. All harness exclusions are enumerated and
  TimeQuest reports zero unconstrained categories; this is still not wrapper
  I/O closure. Yosys 0.33 passes structural/generic synthesis in isolated
  Ubuntu 24.04, lowering the asynchronous RAM to flip-flops/muxes. Full-core
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
- **Notes:** Initial sheets 3–7 inventory and MAME comparison exist; INT net,
  exact arbitration phases, DAC polarity, and synthetic smoke tests remain.
  User-supplied ROM hashes may enable local tests; ROMs are never committed.

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
