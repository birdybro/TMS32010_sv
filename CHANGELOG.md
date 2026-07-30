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

### Changed

- Replaced the initial placeholder README with an evidence-oriented project
  overview.

### Fixed

- Corrected project spelling and naming in the README.

### Verified

- Existing repository is on `main` with a clean initial commit.
- Eight repository/provenance tests pass; all 14 cached initial sources match
  their recorded SHA-256 values.

### Known Issues

- No instruction behavior or cycle timing is yet qualified.
- Primary reference acquisition and checksum validation are in progress.
- Yosys, iverilog, SymbiYosys, and pytest are not currently available on the
  local executable path.
