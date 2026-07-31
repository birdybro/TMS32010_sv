# Progress summary

- **Current milestone:** SPAC product-subtract qualification
- **Completed task IDs:** REPO-001, REF-001
- **Tests passing:** 65 repository/provenance/document/ISA/toolchain tests; 120
  directed model tests; 21 RTL instruction/decode tests; 2 native bus/phase
  tests; one 512-instruction seeded thirty-instruction model/RTL
  differential including T, P, OV/OVM, logical reads/writes, and all 144 final RAM
  words; 15 reference hashes
- **Synthesis status:** Quartus 17.0.2 full flow passes internal timing for
  the thirty-instruction partial core, multiplier, 144-word RAM, and phase
  engine on `5CSEBA6U23I7`: 1,844 ALMs, 2,483 registers, 0 RAM blocks,
  1 DSP block, 61.49 MHz worst slow-corner internal Fmax, +3.737 ns setup
  slack, and +0.165 ns worst hold slack at 50 MHz. TimeQuest reports zero
  unconstrained categories after enumerated
  harness-only exclusions; no wrapper I/O is closed. Yosys 0.33 passes
  structural checks and generic synthesis in isolated Ubuntu 24.04, producing
  11,029 generic cells and lowering the asynchronous RAM to registers/muxes;
  its technology-neutral multiplier contributes 1,841 generic cells; Yosys
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
  follows the same sticky-OV/wrap/saturation policy; ABS is opcode `0x7f88`,
  one word and one cycle, and selects wrap or positive saturation for
  `0x80000000` through OVM, but original sources do not say whether it sets
  sticky OV; LAR loads either auxiliary register from internal data RAM in one
  cycle, replaces ARP when requested, and exceptionally suppresses indirect
  auto-increment/decrement when the loaded target is the selected address
  register while retaining normal post-modification for the other target; SAR
  instead uses the old selected AR as its indirect address but, when storing
  that same AR with auto-modification, writes the post-modification value at
  the old address; an other-AR source is stored unchanged while the selected
  address AR updates normally; direct MAR is a documented NOP, while indirect
  MAR changes only the selected AR/ARP and never accesses the nominal data-RAM
  location; `MAR *,0/1` are exact canonical LARP aliases; LDP reads through
  the old direct DP or indirect selected AR, ignores source bits 15:1,
  transfers source bit 0 to DP, and only then applies ordinary indirect
  AR/ARP updates; LT uses the same old-address/post-update ordering but loads
  all 16 source bits into T without changing ACC or arithmetic status; MPY
  signed-multiplies T and the selected word into P, except that the documented
  original-hardware `0x8000` square produces `0xc0000000`; MPYK sign-extends
  a 13-bit program-word constant, multiplies it by signed T into P, and has no
  data-memory transaction; PAC is fixed opcode `0x7f8e`, copies all 32 P bits
  into ACC in one cycle, leaves P/T/OV/OVM and address state unchanged, and
  has no data-memory transaction; APAC is fixed opcode `0x7f8f`, adds all 32
  P bits to ACC in one cycle, leaves P/T/address state unchanged, sets sticky
  OV on signed overflow, wraps when OVM is clear, saturates to the appropriate
  signed endpoint when OVM is set, and has no data-memory transaction; SPAC
  is fixed opcode `0x7f90`, subtracts all 32 P bits from ACC in one
  cycle, leaves P/T/address state unchanged, uses the same sticky signed
  overflow and OVM-controlled wrap/saturation policy, and has no data-memory
  transaction
- **Unresolved issues:** general pipeline overlap, control-flow and
  interrupt-entry traces, reserved SST bits, simultaneous indirect
  increment/decrement, out-of-range RAM behavior, original-part ADDH and ABS
  overflow-status behavior, physical-reset retention of unlisted state,
  MPY/MPYK interrupt deferral, Hard Drivin' INT net, and safe phase adaptation
  without READY
- **Next task:** research and qualify primary-defined `LTA` data-to-T load plus
  previous-P accumulation, including exact old-P ordering, common
  direct/indirect updates, overflow modes, and one-cycle bus behavior; keep
  multiply interrupt-deferral gaps under `INT-001` and keep `ADDH` and `ABS`
  outside the supported boundary pending `OQ-011` and `OQ-013`
- **Latest committed baseline before this cycle:**
  `a20f5b4859ea7fe537b24b4392d4241329fa1e67`
