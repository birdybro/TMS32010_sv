# Progress summary

- **Current milestone:** AND/OR/XOR accumulator-logic instruction slice
- **Completed task IDs:** REPO-001, REF-001
- **Tests passing:** 44 repository/provenance/document/ISA/toolchain tests; 47
  directed model tests; 8 RTL instruction/decode tests; 2 native bus/phase
  tests; one 512-instruction seeded seventeen-instruction model/RTL
  differential including OV/OVM, logical reads/writes, and all 144 final RAM
  words; 15 reference hashes
- **Synthesis status:** Quartus 17.0.2 full flow passes internal timing for
  the seventeen-instruction partial core, 144-word RAM, and phase engine on
  `5CSEBA6U23I7`: 1,504 ALMs, 2,421 registers, 0 RAM/DSP, 67.84 MHz worst
  slow-corner internal Fmax, +5.260 ns setup and +0.166 ns worst hold slack at
  50 MHz. TimeQuest reports zero unconstrained categories after enumerated
  harness-only exclusions; no wrapper I/O is closed. Yosys 0.33 passes
  structural checks and generic synthesis in isolated Ubuntu 24.04, producing
  6,738 generic cells and lowering the asynchronous RAM to registers/muxes; it
  is not installed on the host path
- **New architecture facts:** original part is ROMless NMOS with 144 data
  words and no READY pin; reset requires at least five machine cycles and leaves
  OVM unchanged; most instructions are one cycle, branches are two, and table
  transfers are three; falling CLKOUT samples program/I/O data, INT, and BIO;
  reset release waits one full cycle then fetches addresses 0 and 1; `LAC`
  sign-extends before shifting and indirect AR updates wrap only bits 8:0;
  ordinary data operands never leave on-chip RAM; `LAC` and `SACL` have
  matching model/RTL direct/indirect logical transactions; SACL stores
  `ACC[15:0]` without a shift and requires a zero syntax placeholder before a
  next ARP; SACH shifts the complete accumulator left by only 0, 1, or 4 and
  stores shifted bits 31:16 without changing ACC/status; ZALH loads a data word
  into ACC[31:16] and clears the low half, while ZALS zero-extends it into
  ACC[15:0]; both preserve overflow status and use the common post-access
  indirect controls; ADDS zero-extends its 16-bit operand, applies sticky OV,
  wraps with OVM clear, and positively saturates with OVM set; TI SPRU013
  resolves the older OVM-clear prose contradiction; AND/OR/XOR combine the
  internal word with `ACC[15:0]`, cannot overflow, and preserve OV/OVM; AND
  clears `ACC[31:16]`, whereas OR and XOR preserve it; Atari A044427 labels a
  TMS32010 at 20 MHz
- **Unresolved issues:** general pipeline overlap, control-flow and
  interrupt-entry traces, reserved SST bits, simultaneous indirect
  increment/decrement, out-of-range RAM behavior, original-part ADDH overflow,
  physical-reset retention of unlisted state, Hard Drivin' INT net, and safe
  phase adaptation without READY
- **Next task:** research and qualify the primary-defined `ADD` shifted
  accumulator-arithmetic instruction while ADDH remains blocked on OQ-011
- **Latest committed baseline before this cycle:**
  `d36783718cee197779d2e365c5e6fa4c81be04b0`
