# Progress summary

- **Current milestone:** First internal-data instruction model/tool slice
- **Completed task IDs:** REPO-001, REF-001
- **Tests passing:** 31 repository/provenance/document/ISA/toolchain tests; 17
  directed model tests; 2 RTL instruction/decode tests; 2 native bus/phase
  tests; one 512-instruction seeded model/RTL differential; 14 reference hashes
- **Synthesis status:** Quartus 17.0.2 full flow passes internal timing for
  the eight-instruction partial core plus phase engine on `5CSEBA6U23I7`:
  135 ALMs, 90 registers, 0 RAM/DSP, 182.08 MHz worst slow-corner internal
  Fmax, +14.508 ns setup and +0.167 ns hold slack at 50 MHz. Harness I/O is
  virtual and explicitly excluded pending a real wrapper. Yosys 0.33 passes
  structural checks and generic synthesis in isolated Ubuntu 24.04; it is not
  installed on the host path
- **New architecture facts:** original part is ROMless NMOS with 144 data
  words and no READY pin; reset requires at least five machine cycles and leaves
  OVM unchanged; most instructions are one cycle, branches are two, and table
  transfers are three; falling CLKOUT samples program/I/O data, INT, and BIO;
  reset release waits one full cycle then fetches addresses 0 and 1; `LAC`
  sign-extends before shifting and indirect AR updates wrap only bits 8:0;
  ordinary data operands never leave on-chip RAM; Atari A044427 labels a
  TMS32010 at 20 MHz
- **Unresolved issues:** general pipeline overlap, control-flow and
  interrupt-entry traces, reserved SST bits, simultaneous indirect
  increment/decrement, out-of-range RAM behavior, Hard Drivin' INT net, and
  safe phase adaptation without READY
- **Next task:** implement and verify `LAC` plus 144-word internal RAM in RTL
  without assigning behavior to unresolved addresses
- **Latest commit:** `153f238585df2ae087b381392acf70c026fed458`
