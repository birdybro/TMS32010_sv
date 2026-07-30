# Progress summary

- **Current milestone:** ISA database and independent executable model
- **Completed task IDs:** REPO-001, REF-001
- **Tests passing:** 17 repository/provenance/document/ISA tests; 9 directed
  reference-model tests; documentation consistency; 14 reference SHA-256 checks
- **Synthesis status:** not started; no architectural RTL exists
- **New architecture facts:** original part is ROMless NMOS with 144 data
  words and no READY pin; reset requires at least five input clocks and leaves
  OVM unchanged; most instructions are one cycle, branches are two, and table
  transfers are three; Atari A044427 labels a TMS32010 at 20 MHz
- **Unresolved issues:** exact bus waveforms, reset first-fetch edge, interrupt
  entry phases, reserved SST bits, out-of-range RAM behavior, Hard Drivin' INT
  net, and safe phase adaptation without READY
- **Next task:** project-local assembler/disassembler slice, then independent
  RTL package/decode/execution for the same five opcodes
- **Latest commit:** `839c4acf4786064ac79c6cc8b7727d422a36d37d`
