# Changelog

All notable project changes are documented here. The format is based on Keep a
Changelog, and the project follows semantic versioning once releases begin.

## [Unreleased]

### Added

- Repository governance, build, research, model, RTL, verification, formal,
  synthesis, and integration directory framework.
- Reference-provenance policy, safe acquisition/hash tools, a 16-source
  integrity-pinned initial catalog, and living engineering backlog.
- Standard-library regression entrypoints and documentation consistency checks.
- Primary-cited programmer, memory, pipeline, interrupt, external-interface,
  instruction, and timing research baselines.
- Source-precedence ADR, ambiguity/conflict registers, and an initial
  schematic-led Hard Drivin' Driver Sound Board inventory.
- Partial machine-readable ISA database that enumerates all 60 documented
  mnemonics and fully describes the first forty-seven model/tool encodings.
- Structurally independent executable model with explicit-width state, raw
  image loading, logical fetch traces, deterministic JSON, and trap-on-unknown
  behavior for the initial eight-instruction slice.
- Independent hand opcode fixtures and decode/model boundary tests.
- Deterministic project-local assembler/disassembler slice with checked
  expressions, labels, origin/data/include directives, raw/hex/listing output,
  and lossless source round trips.
- Portable SystemVerilog package, exhaustive partial decoder, and
  clock-enable execution core for the forty-seven-instruction slice.
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
- Sequential native-phase wrapper that retires the 37 supported one-cycle
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
  transaction. Interrupt recognition, EINT's following-instruction service
  deferral, and vector entry remain explicitly outside this functional slice.
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
  behavior, one-word size, and two-cycle totals without prematurely adding
  them to the supported implementation boundary.
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

### Changed

- Replaced the initial placeholder README with an evidence-oriented project
  overview.
- Reframed the external-wait milestone after confirming that the original
  40-pin TMS32010 has no READY/WAIT input.
- The local assembler diagnoses out-of-range `LACK` operands instead of
  reproducing the historical assembler's silent truncation.
- Quartus 17.0.2 fits the integrated forty-seven-instruction
  phase/RAM/multiplier slice in 1,942 ALMs/2,491 registers and one DSP block,
  with +3.903 ns worst setup and +0.167 ns worst hold slack at 50 MHz and
  62.12 MHz worst slow-corner internal Fmax; 279
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
- The qualified model/tool/RTL boundary now covers forty-seven of 60 documented
  mnemonics and twenty-two common-address data-operation families.

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
- All 16 acquired reference files match their manifest SHA-256 values.
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
- Yosys 0.67+111 synthesizes the forty-seven-instruction hierarchy to 12,655
  generic cells with 11 assertions, zero latches, and clean pre/post checks;
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
- The complete current regression passes 81 repository/ISA/tool tests, 180
  directed model tests, 31 exhaustive/directed instruction RTL tests, seven
  native bus/phase tests, one interrupt-mask RTL test, one 512-step seeded
  model/RTL differential, and five focused two-cycle branch differentials.

### Known Issues

- Only forty-seven of 60 documented instruction mnemonics have model, tool, and
  RTL/differential evidence.
- MAME models untaken BANZ as one cycle and does not fetch its following target
  word, contrary to original TI's unconditional two-word/two-cycle entry. MAME
  remains a functional oracle only for this instruction (`SC-012`).
- MAME also shortens untaken BV to one cycle and omits its target read;
  project behavior follows TI's unconditional two-cycle entry (`SC-014`).
- MAME also shortens untaken BIOZ to one cycle and does not read the target;
  it exposes an abstract asserted callback rather than documenting physical
  pin polarity. Project behavior follows TI's active-low pin and unconditional
  two-cycle entry (`SC-015`).
- Original TMS32010 manuals do not define LST's memory-sourced ARP versus
  encoded next-ARP precedence. The implemented memory-word precedence is
  PROVISIONAL under `OQ-015`; later TI and MAME evidence corroborates but does
  not prove original silicon behavior.
- The located original PUSH/POP pages do not show the program-address and
  `MEN` sequence during their extra internal cycle. Native two-cycle stack
  sequencing remains deferred under `OQ-016`; no repeated or speculative
  prefetch has been assigned.
- TI requires the instruction after SUBC not to use ACC but does not establish
  observable behavior for a violation; current same-boundary result commit is
  an implementation convenience under `OQ-017`. TI also says SUBC affects OV
  without identifying the producing arithmetic stage; intermediate-subtraction
  sticky OV is PROVISIONAL under `OQ-018`.
- DINT/EINT architectural mask changes are verified, but the core has no
  interrupt input, pending latch, EINT following-instruction service deferral,
  stack entry, or vector fetch; those remain under `CTRL-002`/`OQ-004`.
- MPY/MPYK functional results and one-cycle transactions are verified, but
  their documented suppression of interrupt service through the following
  instruction remains unimplemented until `CTRL-002`.
- Original-part ADDH overflow/saturation, physical-reset retention of unlisted
  state, and ABS sticky-OV behavior remain unresolved as OQ-011 through
  OQ-013.
- Original-part DMOV/LTD behavior when source `0x8f` implies destination
  `0x90` remains unresolved under `OQ-014`; the partial implementation traps
  before all effects and labels that policy provisional.
- Control-flow bus traces, interrupt entry phases, reserved status bits, and
  out-of-range RAM behavior remain open.
- The execution core still has an instruction-step test interface; the
  native-phase wrapper covers only normal sequential program reads.
- The asynchronous RAM read is intentionally correctness-first and maps to
  2,304 registers plus mux logic, not an FPGA block RAM.
- Yosys, iverilog, SymbiYosys, and pytest are not currently available on the
  local executable path. Yosys is qualified in an isolated Ubuntu 24.04
  environment; the host target still fails explicitly when the tool is absent.
