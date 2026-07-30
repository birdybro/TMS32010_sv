# Progress summary

- **Current milestone:** First internal-data instruction RTL slice
- **Completed task IDs:** REPO-001, REF-001
- **Tests passing:** 31 repository/provenance/document/ISA/toolchain tests; 17
  directed model tests; 3 RTL instruction/decode tests; 2 native bus/phase
  tests; one 512-instruction seeded nine-instruction model/RTL differential
  including internal data reads; 14 reference hashes
- **Synthesis status:** Quartus 17.0.2 full flow passes internal timing for
  the nine-instruction partial core, 144-word RAM, and phase engine on
  `5CSEBA6U23I7`: 1,364 ALMs, 2,420 registers, 0 RAM/DSP, 73.69 MHz worst
  slow-corner internal Fmax, +6.429 ns setup and +0.168 ns hold slack at
  50 MHz. TimeQuest reports zero unconstrained categories after enumerated
  harness-only exclusions; no wrapper I/O is closed. Yosys 0.33 passes
  structural checks and generic synthesis in isolated Ubuntu 24.04, lowering
  the asynchronous RAM to registers/muxes; it is not installed on the host
  path
- **New architecture facts:** original part is ROMless NMOS with 144 data
  words and no READY pin; reset requires at least five machine cycles and leaves
  OVM unchanged; most instructions are one cycle, branches are two, and table
  transfers are three; falling CLKOUT samples program/I/O data, INT, and BIO;
  reset release waits one full cycle then fetches addresses 0 and 1; `LAC`
  sign-extends before shifting and indirect AR updates wrap only bits 8:0;
  ordinary data operands never leave on-chip RAM; `LAC` now has matching model
  and RTL direct/indirect logical transactions; Atari A044427 labels a
  TMS32010 at 20 MHz
- **Unresolved issues:** general pipeline overlap, control-flow and
  interrupt-entry traces, reserved SST bits, simultaneous indirect
  increment/decrement, out-of-range RAM behavior, Hard Drivin' INT net, and
  safe phase adaptation without READY
- **Next task:** research and implement the first architectural internal-RAM
  write instruction while preserving the verified one-cycle phase contract
- **Latest commit:** `d95a98f9e358204c53816e7267b2d843b6ba5238`
