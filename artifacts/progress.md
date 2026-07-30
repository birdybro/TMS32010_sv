# Progress summary

- **Current milestone:** Architecture specification and source review
- **Completed task IDs:** REPO-001, REF-001
- **Tests passing:** repository/provenance and architecture-document tests;
  documentation consistency; 14 reference SHA-256 checks
- **Synthesis status:** not started; no architectural RTL exists
- **New architecture facts:** original part is ROMless NMOS with 144 data
  words and no READY pin; reset requires at least five input clocks and leaves
  OVM unchanged; most instructions are one cycle, branches are two, and table
  transfers are three; Atari A044427 labels a TMS32010 at 20 MHz
- **Unresolved issues:** exact bus waveforms, reset first-fetch edge, interrupt
  entry phases, reserved SST bits, out-of-range RAM behavior, Hard Drivin' INT
  net, and safe phase adaptation without READY
- **Next task:** ISA-001 machine-readable first instruction slice, hand opcode
  fixtures, and MODEL-001 executable behavior
- **Latest commit:** `017826508b3c1ca7834777676415b2a7ad64b52d`
