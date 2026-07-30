# Progress summary

- **Current milestone:** First RTL execution slice and early synthesis
- **Completed task IDs:** REPO-001, REF-001
- **Tests passing:** 27 repository/provenance/document/ISA/toolchain tests; 10
  directed model tests; 2 RTL instruction/decode tests; 1 native bus-phase
  test; one 512-instruction seeded model/RTL differential; 14 reference hashes
- **Synthesis status:** Quartus 17.0.2 full flow passes internal timing for
  the eight-instruction partial core plus phase engine on `5CSEBA6U23I7`:
  144 ALMs, 90 registers, 0 RAM/DSP, 315.36 MHz worst slow-corner internal
  Fmax, +16.829 ns setup and +0.167 ns hold slack at 50 MHz. Harness I/O is
  virtual and explicitly excluded pending a real wrapper; Yosys unavailable
- **New architecture facts:** original part is ROMless NMOS with 144 data
  words and no READY pin; reset requires at least five machine cycles and leaves
  OVM unchanged; most instructions are one cycle, branches are two, and table
  transfers are three; falling CLKOUT samples program/I/O data, INT, and BIO;
  reset release waits one full cycle then fetches addresses 0 and 1; Atari
  A044427 labels a TMS32010 at 20 MHz
- **Unresolved issues:** pipeline ownership of bus phases, control-flow and
  interrupt-entry traces, reserved SST bits, out-of-range RAM behavior, Hard
  Drivin' INT net, and safe phase adaptation without READY
- **Next task:** integrate the verified normal-read phases with a fetch
  sequencer, then research the first data-memory instruction family
- **Latest commit:** `b3bc61c484e016c7725192b76226b46d9147b9d4`
