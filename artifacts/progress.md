# Progress summary

- **Current milestone:** accumulator-tested conditional-branch qualification
- **Completed task IDs:** REPO-001, REF-001
- **Tests passing:** 77 repository/provenance/document/ISA/toolchain tests; 172
  directed model tests; 29 RTL instruction/decode tests; 1 interrupt-mask RTL
  test; 5 native bus/phase tests; one 512-instruction seeded
  37-one-cycle-instruction model/RTL differential including T, P, OV/OVM/INTM,
  distinct logical source/write addresses, and all 144 final RAM words; 16
  reference hashes; focused two-cycle B, BANZ, and all six
  accumulator-conditional-branch model/RTL traces
- **Synthesis status:** Quartus 17.0.2 full flow passes internal timing for
  the forty-five-instruction partial core, multiplier, 144-word RAM, and phase
  engine on `5CSEBA6U23I7`: 1,927 ALMs, 2,491 registers, 0 RAM blocks,
  1 DSP block, 55.94 MHz worst slow-corner internal Fmax, +2.123 ns setup
  slack, and +0.165 ns worst hold slack at 50 MHz. TimeQuest reports zero
  unconstrained categories after enumerated
  harness-only exclusions; no wrapper I/O is closed. Yosys 0.67+111 passes
  structural checks and generic synthesis from the 2026-07-29 OSS CAD Suite,
  producing 12,557 generic cells with 11 assertions and lowering the
  asynchronous RAM to registers/muxes; its technology-neutral multiplier
  contributes 1,756 generic cells; Yosys
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
  transaction; LTA is opcode family `0x6c`, reads the addressed data word into
  T while adding the unchanged previous P to ACC in the same cycle, leaves P
  unchanged, uses the common old-address/post-update ordering, and applies
  sticky OV with OVM-controlled wrap or signed-endpoint saturation; LTD is
  opcode family `0x6b` and adds an unchanged source-word copy to the next
  internal-RAM address in that same cycle, so source and destination must be
  observable independently; DMOV is opcode family `0x69`, performs only that
  unchanged-word next-address copy in one cycle, and preserves ACC, T, P,
  OV, OVM, and DP while retaining common indirect AR/ARP post-update behavior;
  exact implied `DINT=0x7f81` and `EINT=0x7f82` each retire in one
  program-only cycle; DINT sets `INTM` immediately, EINT clears it immediately,
  neither clears a latched request, and interrupt service after EINT remains
  inhibited until the following instruction completes; LST is opcode family
  `0x7b`, consumes one internal status-word read in one cycle, loads OV, OVM,
  ARP, and DP from bits 15, 14, 8, and 0 while preserving INTM, resolves direct
  and indirect addresses from old status, and applies counter updates to the
  old selected AR; original-part sources do not specify whether loaded ARP or
  encoded next ARP wins, while later TI and pinned MAME agree on loaded ARP;
  PUSH is exact opcode `0x7f9c` and pushes ACC[11:0] onto a four-level,
  12-bit stack while discarding the old bottom; POP is exact opcode `0x7f9d`,
  zero-extends the old top into ACC and duplicates the old bottom while
  shifting upward; neither detects overflow/underflow, and both are one word
  and two cycles; SUBC is opcode family `0x64`, treats the selected word as an
  unsigned divisor aligned at bit 15, conditionally subtracts it, shifts the
  chosen intermediate left, appends a quotient bit, and completes in one
  cycle; 16 legally spaced steps transform the documented 65/7 inputs into
  `0x00020009`; TI requires the following instruction not to use ACC, says
  SUBC affects OV but ignores OVM, and does not specify either violation
  behavior or the exact overflow-producing stage; BANZ is exact opcode
  `0xf400` followed by a canonical 12-bit target word and always consumes two
  normal program-read cycles; it tests the old selected AR[8:0], decrements
  that counter modulo 512 while preserving AR[15:9], and selects the target
  or `PC+2` at the second sample; original SPRU001B and later architectural
  prose support the low-nine-bit wrap, while a later-guide example and MAME's
  one-cycle untaken abstraction remain disclosed as `SC-011`/`SC-012`; B is
  exact opcode `0xf900`, followed by a canonical absolute 12-bit target word,
  and unconditionally loads PC after two normal program-read cycles while
  preserving all other architectural state; original TI sources and pinned
  MAME agree on its behavior and cycle total; BLZ, BLEZ, BGZ, BGEZ, BNZ, and
  BZ are exact opcodes `0xfa00` through `0xff00`, test the complete signed
  32-bit accumulator, and always consume their canonical target word and a
  second program-read cycle whether or not the branch is taken; MAME instead
  skips that read/cycle on untaken paths, recorded as `SC-013`, so project
  timing follows the original TI two-word/two-cycle definitions
- **Unresolved issues:** general pipeline overlap, control-flow and
  interrupt-entry traces, SST reserved bit 1, LST next-ARP precedence,
  PUSH/POP second-cycle program-bus sequencing, SUBC result availability and
  OV stage, simultaneous indirect
  increment/decrement, out-of-range RAM behavior, original-part ADDH and ABS
  overflow-status behavior, physical-reset retention of unlisted state,
  MPY/MPYK interrupt deferral, DMOV/LTD source-`0x8f` destination behavior,
  Hard Drivin' INT net, and safe phase adaptation without READY
- **Next task:** qualify `BV` using its primary instruction pages and the
  established two-word control-flow sequencer, including its taken-path
  overflow-clear side effect and mandatory target-word read;
  keep PUSH/POP RTL outside the boundary until `OQ-016` supplies the
  second-cycle program-bus sequence; keep `SST` outside the qualified boundary until reserved output
  bit 1 is resolved under `OQ-003`/`SC-008`; keep LST's loaded-ARP
  precedence labeled PROVISIONAL under `OQ-015`; keep interrupt recognition,
  EINT's following-instruction service deferral, and entry outside the claim
  boundary until `CTRL-002`/`OQ-004` has cycle/phase evidence; keep
  DMOV/LTD source-`0x8f` behavior provisional under `OQ-014` and
  `ADDH`/`ABS` outside the supported boundary pending `OQ-011`/`OQ-013`
- **Latest committed baseline before this cycle:**
  `d9f0eb5`
