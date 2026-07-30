# Progress summary

- **Current milestone:** SUBS unsigned-source accumulator-arithmetic slice
- **Completed task IDs:** REPO-001, REF-001
- **Tests passing:** 50 repository/provenance/document/ISA/toolchain tests; 70
  directed model tests; 11 RTL instruction/decode tests; 2 native bus/phase
  tests; one 512-instruction seeded twenty-instruction model/RTL
  differential including OV/OVM, logical reads/writes, and all 144 final RAM
  words; 15 reference hashes
- **Synthesis status:** Quartus 17.0.2 full flow passes internal timing for
  the twenty-instruction partial core, 144-word RAM, and phase engine on
  `5CSEBA6U23I7`: 1,615 ALMs, 2,421 registers, 0 RAM/DSP, 60.96 MHz worst
  slow-corner internal Fmax, +3.597 ns setup and +0.165 ns worst hold slack at
  50 MHz. TimeQuest reports zero unconstrained categories after enumerated
  harness-only exclusions; no wrapper I/O is closed. Yosys 0.33 passes
  structural checks and generic synthesis in isolated Ubuntu 24.04, producing
  7,844 generic cells and lowering the asynchronous RAM to registers/muxes; it
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
  TMS32010 at 20 MHz; ADD sign-extends and left-shifts its RAM operand before
  full-accumulator addition, applies sticky OV, wraps with OVM clear, and
  saturates at either signed endpoint with OVM set; SUB uses the same signed
  source extension and shift path, subtracts it from ACC, sets sticky OV,
  wraps with OVM clear, and saturates at either signed endpoint with OVM set;
  SUBS instead zero-extends its RAM word, can overflow only negatively, and
  follows the same sticky-OV/wrap/saturation policy
- **Unresolved issues:** general pipeline overlap, control-flow and
  interrupt-entry traces, reserved SST bits, simultaneous indirect
  increment/decrement, out-of-range RAM behavior, original-part ADDH overflow,
  physical-reset retention of unlisted state, Hard Drivin' INT net, and safe
  phase adaptation without READY
- **Next task:** research and qualify `ABS` if its original-part overflow
  behavior is explicit; keep `ADDH` and any similarly ambiguous high-half
  arithmetic outside the supported boundary
- **Latest committed baseline before this cycle:**
  `a311c9e9d1776f2bcb116ee2b85910052262db5e`
