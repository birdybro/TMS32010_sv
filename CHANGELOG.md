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
  mnemonics and fully describes the first five supported encodings.
- Structurally independent executable model with explicit-width state, raw
  image loading, logical fetch traces, deterministic JSON, and trap-on-unknown
  behavior for the initial five-instruction slice.
- Independent hand opcode fixtures and decode/model boundary tests.
- Deterministic project-local assembler/disassembler slice with checked
  expressions, labels, origin/data/include directives, raw/hex/listing output,
  and lossless source round trips.

### Changed

- Replaced the initial placeholder README with an evidence-oriented project
  overview.
- Reframed the external-wait milestone after confirming that the original
  40-pin TMS32010 has no READY/WAIT input.
- The local assembler diagnoses out-of-range `LACK` operands instead of
  reproducing the historical assembler's silent truncation.

### Fixed

- Corrected project spelling and naming in the README.

### Verified

- Existing repository is on `main` with a clean initial commit.
- Eight repository/provenance tests pass; all 14 cached initial sources match
  their recorded SHA-256 values.
- Initial encodings for `LACK`, `NOP`, `ZAC`, `ROVM`, and `SOVM` are
  transcribed from TI SPRU001B; database collision, fixture, and directed model
  tests pass over the supported boundary.
- Atari drawing A044427 identifies a physical TMS32010 with a 20 MHz crystal;
  MAME's C10 device selection is recorded as a secondary-source conflict.

### Known Issues

- No instruction behavior or cycle timing is yet qualified.
- Bus waveform transcription, reset first-fetch timing, interrupt entry
  phases, reserved status bits, and out-of-range RAM behavior remain open.
- Yosys, iverilog, SymbiYosys, and pytest are not currently available on the
  local executable path.
