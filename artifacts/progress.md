# Progress summary

- **Current milestone:** First RTL execution slice and early synthesis
- **Completed task IDs:** REPO-001, REF-001
- **Tests passing:** 26 repository/provenance/document/ISA/toolchain tests; 9
  directed model tests; 2 RTL tests including all 65,536 decode words; one
  512-instruction seeded model/RTL differential; 14 reference SHA-256 checks
- **Synthesis status:** Quartus 17.0.2 full flow passes for partial core on
  `5CSEBA6U23I7`: 36 ALMs, 55 synthesis registers, 0 RAM/DSP, 56.16 MHz
  slow-corner Fmax, +2.193 ns worst setup and +0.030 ns worst hold slack at
  50 MHz, zero unconstrained I/O path categories; Yosys unavailable
- **New architecture facts:** original part is ROMless NMOS with 144 data
  words and no READY pin; reset requires at least five input clocks and leaves
  OVM unchanged; most instructions are one cycle, branches are two, and table
  transfers are three; Atari A044427 labels a TMS32010 at 20 MHz
- **Unresolved issues:** exact bus waveforms, reset first-fetch edge, interrupt
  entry phases, reserved SST bits, out-of-range RAM behavior, Hard Drivin' INT
  net, and safe phase adaptation without READY
- **Next task:** transcribe normal fetch/reset bus waveforms, define native
  phase sequencer contract, then expand primary-verified instruction entries
- **Latest commit:** `1d19fff3a973932c961a11c38d65cba2286b824a`
