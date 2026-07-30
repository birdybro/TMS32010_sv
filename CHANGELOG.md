# Changelog

All notable project changes are documented here. The format is based on Keep a
Changelog, and the project follows semantic versioning once releases begin.

## [Unreleased]

### Added

- Repository governance, build, research, model, RTL, verification, formal,
  synthesis, and integration directory framework.
- Reference-provenance policy, safe acquisition/hash tools, a 14-source
  integrity-pinned initial catalog, and living engineering backlog.
- Standard-library regression entrypoints and documentation consistency checks.
- Primary-cited programmer, memory, pipeline, interrupt, external-interface,
  instruction, and timing research baselines.
- Source-precedence ADR, ambiguity/conflict registers, and an initial
  schematic-led Hard Drivin' Driver Sound Board inventory.
- Partial machine-readable ISA database that enumerates all 60 documented
  mnemonics and fully describes the first eight supported encodings.
- Structurally independent executable model with explicit-width state, raw
  image loading, logical fetch traces, deterministic JSON, and trap-on-unknown
  behavior for the initial eight-instruction slice.
- Independent hand opcode fixtures and decode/model boundary tests.
- Deterministic project-local assembler/disassembler slice with checked
  expressions, labels, origin/data/include directives, raw/hex/listing output,
  and lossless source round trips.
- Portable SystemVerilog package, exhaustive partial decoder, and
  clock-enable execution core for the eight-instruction slice.
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

### Changed

- Replaced the initial placeholder README with an evidence-oriented project
  overview.
- Reframed the external-wait milestone after confirming that the original
  40-pin TMS32010 has no READY/WAIT input.
- The local assembler diagnoses out-of-range `LACK` operands instead of
  reproducing the historical assembler's silent truncation.
- Quartus 17.0.2 fits the eight-instruction partial core plus phase engine in
  144 ALMs/90 registers with positive internal 50 MHz setup/hold slack and
  315.36 MHz worst slow-corner internal Fmax; 176 diagnostic ports are virtual
  and harness I/O paths are explicitly excluded pending a real wrapper.
- Appendix A establishes falling `CLKOUT` as the input sampling boundary and
  resolves reset release to an address-0 fetch after one complete cycle.

### Fixed

- Corrected project spelling and naming in the README.
- Corrected reset duration from five crystal clocks to five complete `CLKOUT`
  machine cycles after reviewing the Appendix A timing table.
- Rejected artificial harness I/O delay assumptions that produced hold
  violations; synthesis evidence now scopes itself to internal timing.

### Verified

- Existing repository is on `main` with a clean initial commit.
- Eight repository/provenance tests pass; all 14 cached initial sources match
  their recorded SHA-256 values.
- Initial encodings for `LACK`, `NOP`, `ZAC`, `ROVM`, and `SOVM` are
  transcribed from TI SPRU001B; database collision, fixture, and directed model
  tests pass over the supported boundary.
- `LARK`, `LARP`, and `LDPK` immediate boundaries and AR/ARP/DP effects agree
  between independent model and RTL paths across the seeded mixed trace.
- Atari drawing A044427 identifies a physical TMS32010 with a 20 MHz crystal;
  MAME's C10 device selection is recorded as a secondary-source conflict.

### Known Issues

- Only eight instruction behaviors are qualified; instruction-to-pin timing
  is not yet integrated.
- Control-flow bus traces, interrupt entry phases, reserved status bits, and
  out-of-range RAM behavior remain open.
- The RTL program interface is an instruction-step test interface, not native
  pin timing; only eight instructions are implemented.
- Yosys, iverilog, SymbiYosys, and pytest are not currently available on the
  local executable path; the Yosys target fails explicitly.
