# Changelog

All notable project changes are documented here. The format is based on Keep a
Changelog, and the project follows semantic versioning once releases begin.

## [Unreleased]

### Added

- Repository governance, build, research, model, RTL, verification, formal,
  synthesis, and integration directory framework.
- Reference-provenance policy, safe acquisition/hash tools, a 15-source
  integrity-pinned initial catalog, and living engineering backlog.
- Standard-library regression entrypoints and documentation consistency checks.
- Primary-cited programmer, memory, pipeline, interrupt, external-interface,
  instruction, and timing research baselines.
- Source-precedence ADR, ambiguity/conflict registers, and an initial
  schematic-led Hard Drivin' Driver Sound Board inventory.
- Partial machine-readable ISA database that enumerates all 60 documented
  mnemonics and fully describes the first thirty-one model/tool encodings.
- Structurally independent executable model with explicit-width state, raw
  image loading, logical fetch traces, deterministic JSON, and trap-on-unknown
  behavior for the initial eight-instruction slice.
- Independent hand opcode fixtures and decode/model boundary tests.
- Deterministic project-local assembler/disassembler slice with checked
  expressions, labels, origin/data/include directives, raw/hex/listing output,
  and lossless source round trips.
- Portable SystemVerilog package, exhaustive partial decoder, and
  clock-enable execution core for the thirty-one-instruction slice.
- Directed RTL tests, exhaustive 16-bit decode-space validation, and a seeded
  512-instruction model/RTL differential trace.
- Reproducible Yosys and Quartus synthesis projects with synchronous I/O
  constraints and partial-core synthesis qualification record.
- Primary-transcribed native timing contract for normal program reads, table
  transfers, I/O, reset, interrupt sampling, and BIO sampling.
- Standalone four-subphase program-read engine with distinct FPGA
  initialization and physical-reset controls, plus directed phase/reset/stall
  verification.
- Primary-transcribed `LARK`, `LARP`, and `LDPK` encodings and effects across
  hand fixtures, model, assembler/disassembler, RTL, and differential traces.
- Sequential native-phase wrapper that retires the thirty-one supported
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
- A scoped `ABS` evidence record that separates its primary-verified opcode,
  result, OVM behavior, and one-cycle timing from its unresolved original-part
  sticky-OV side effect.
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

### Changed

- Replaced the initial placeholder README with an evidence-oriented project
  overview.
- Reframed the external-wait milestone after confirming that the original
  40-pin TMS32010 has no READY/WAIT input.
- The local assembler diagnoses out-of-range `LACK` operands instead of
  reproducing the historical assembler's silent truncation.
- Quartus 17.0.2 fits the integrated thirty-one-instruction
  phase/RAM/multiplier slice in 1,762 ALMs/2,483 registers and one DSP block,
  with +3.050 ns worst setup and +0.166 ns worst hold slack at 50 MHz and
  59.0 MHz worst slow-corner internal Fmax; 269
  diagnostic pins are virtual, and enumerated harness I/O paths are explicitly
  excluded pending a real wrapper.
- Appendix A establishes falling `CLKOUT` as the input sampling boundary and
  resolves reset release to an address-0 fetch after one complete cycle.
- Decoder operation ports use an explicitly encoded packed vector at module
  boundaries so the same RTL elaborates in Verilator, Quartus 17.0.2, and
  Yosys 0.33; exhaustive decode tests guard the package/RTL encoding contract.
- Data-memory documentation now distinguishes verification-visible logical
  RAM accesses from physical pins; ordinary operands are entirely on-chip.
- Physical reset and deterministic initialization are separate controls.
  Unlisted physical-reset state receives no arbitrary assigned value, while
  its FPGA retention behavior remains provisional under OQ-012.
- The qualified model/tool/RTL boundary now covers thirty-one of 60 documented
  mnemonics and eighteen common-address data-operation families.

### Fixed

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

### Verified

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
- All 15 acquired reference files match their manifest SHA-256 values.
- Atari drawing A044427 identifies a physical TMS32010 with a 20 MHz crystal;
  MAME's C10 device selection is recorded as a secondary-source conflict.
- Original TI pages and the later C14/E14 variant page were compared directly
  with pinned MAME for `ABS`; the disagreement is preserved as
  `SC-007`/`OQ-013`, and no provisional implementation was admitted.
- Hand fixtures and directed model/RTL tests verify both `LAR` targets,
  direct/page-one and indirect reads, status preservation, unresolved-address
  traps, reserved target rejection, ARP replacement, and the selected-target
  post-modification exception.
- The seeded 512-step differential and native-phase integration compare `LAR`
  read transactions, loaded auxiliary-register values, both update-ordering
  cases, and one-cycle retirement without changing the external program-read
  sequence.
- Yosys 0.33 synthesizes the thirty-one-instruction hierarchy to 11,051 generic
  cells with eight assertions, zero latches, and clean pre/post checks;
  Quartus 17.0.2 completes analysis, fit, and TimeQuest with zero errors and
  five scoped harness warnings.
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

### Known Issues

- Only thirty-one of 60 documented instruction mnemonics have model, tool, and
  RTL/differential evidence.
- MPY/MPYK functional results and one-cycle transactions are verified, but
  their documented suppression of interrupt service through the following
  instruction remains unimplemented until `INT-001`.
- Original-part ADDH overflow/saturation, physical-reset retention of unlisted
  state, and ABS sticky-OV behavior remain unresolved as OQ-011 through
  OQ-013.
- Control-flow bus traces, interrupt entry phases, reserved status bits, and
  out-of-range RAM behavior remain open.
- The execution core still has an instruction-step test interface; the
  native-phase wrapper covers only normal sequential program reads.
- The asynchronous RAM read is intentionally correctness-first and maps to
  2,304 registers plus mux logic, not an FPGA block RAM.
- Yosys, iverilog, SymbiYosys, and pytest are not currently available on the
  local executable path. Yosys is qualified in an isolated Ubuntu 24.04
  environment; the host target still fails explicitly when the tool is absent.
