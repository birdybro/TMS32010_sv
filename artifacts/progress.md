# Progress summary

- **Current milestone:** multicycle fetch/execute integration
- **Completed task IDs:** REPO-001, REF-001, BUS-003
- **Tests passing:** 98 repository/provenance/document/ISA/toolchain tests; 218
  directed model tests; one standalone fetch/execute RTL unit; 35 RTL
  instruction/decode tests; 5 interrupt RTL/phase
  tests; 19 native bus/phase tests, including nine explicit pipeline tests; one
  512-instruction seeded
  38-one-cycle-instruction model/RTL differential including T, P, OV/OVM/INTM,
  all four stack levels, distinct logical source/write addresses, and all 144
  final RAM words; 16 reference hashes; focused two-cycle B, BANZ, BIOZ, BV,
  CALL, and all six accumulator-conditional-branch model/RTL traces; focused
  IN/OUT cycle/state/RAM/transaction differential; focused three-cycle
  TBLR/TBLW bus/state/stack/RAM/program-memory differential; focused
  EINT/protected-instruction/dummy-entry/vector model/RTL differential; 32
  directed request-arrival cases across every represented machine cycle
  of all 15 currently supported multicycle core families; four native
  subphase arrivals with a stalled phase-2 case and falling-boundary ownership
- **Synthesis status:** Quartus 17.0.2 full flow passes internal timing for
  the fifty-three-instruction partial core, multiplier, 144-word RAM, and
  program/I/O/table/interrupt-entry phase engine on `5CSEBA6U23I7`: 2,098
  ALMs, 2,588 registers, 0 RAM blocks, 1 DSP block, 54.45 MHz worst
  slow-corner internal Fmax, +1.634 ns setup slack, and +0.168 ns worst hold
  slack at 50 MHz. TimeQuest
  reports zero
  unconstrained categories after enumerated
  harness-only exclusions; no wrapper I/O is closed. Yosys 0.67+111 passes
  structural checks and generic synthesis from the 2026-07-29 OSS CAD Suite,
  producing 13,514 generic cells with 26 retained checks and lowering the
  asynchronous RAM to registers/muxes; its technology-neutral multiplier
  contributes 1,753 generic cells; Yosys
  is not installed on the host path. The fetch/execute register separately
  passes Yosys 0.67+111 with 29 flip-flops, 68 generic
  cells including two retained checks, and no structural problems. The
  `make synth-yosys` now also runs the sequential pipeline script, which
  independently passes at 15,035 generic cells with 67 retained checks and
  no structural problems after exact B/BANZ/BV/BIOZ/CALL/accumulator-branch/
  IN/OUT integration;
  this is not a
  Quartus fit or complete-pipeline result
- **Formal status:** SymbiYosys v0.67-4-gfea6e46 with Bitwuzla 0.9.1 passes
  12-, 14-, and two 20-step actual-core BMCs across arbitrary clock-enable
  choices. The
  first fixed EINT/protected-LACK/dummy/vector cover reaches vector execution
  at step 6; the second EINT/NOP/MPYK/following/dummy/vector cover reaches
  held-low request relatching at step 8; the third deterministic
  LT/EINT/NOP/MPY/MPYK/MPY/LACK/dummy/vector cover reaches completed entry at
  step 12 after checking three exact signed products. The fourth
  LT/LAR/LARP/EINT/NOP/MPY/LACK/dummy/vector cover reaches completed entry at
  step 12 after proving old address `0x8f`, product `0xffff0000`, AR0
  decrement from `0xaa8f` to `0xaa8e`, and ARP replacement. This is bounded
  scenario evidence, not a complete interrupt or core proof. A separate
  12-step standalone fetch/execute BMC covers arbitrary input values under
  two legal sequencer assumptions and proves initialization, exact capture,
  stall/retention, replacement/bubble, and reset/flush transitions; its
  prime/stall/replace/flush/target cover reaches step 7. It does not prove
  integrated pipeline behavior.
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
  clears `ACC[31:16]`, whereas OR and XOR preserve it; Atari A044427 Rev A
  labels a TMS32010 at 20 MHz, connects its active-low `INT` pin to pull-up
  net `PR1`/`R26` with no loaded active driver, generates `/320BIO` from
  1 MHz divider logic, and resamples it through a `CLKOUT`-clocked LS74 as
  `/BIOS`; the separate `320IRQ` net serves the 68000-side interrupt path;
  TI Figure 2-2 explicitly launches the next prefetch while a previously
  fetched instruction begins/continues execution, requiring distinct
  fetch/execute validity and address state in the final sequencer; TI Figures
  2-9 and 2-10 consistently label the current opcode transaction as
  instruction prefetch and count the following execution intervals, with the
  next instruction prefetch occupying the final interval; combining those
  verified-primary conventions with B's verified two-word/two-cycle
  definition yields an explicitly labeled inferred pipeline mapping in which
  the operand fetch is execution cycle 1, the redirected target fetch is
  execution cycle 2, and B retires only as that target instruction is
  captured; directed RTL evidence now verifies that ownership mapping,
  operand nonexecution, target-effect deferral, stalls, and conservative
  malformed-operand parking;
  ADD sign-extends and left-shifts its RAM operand before
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
  inhibited until the following instruction completes; Figure 2-12 establishes
  fetch N, fetch N+1, dummy fetch N+2, and vector-2 fetch beside execute N,
  execute N+1, dummy execution, and vector execution; the partial model/RTL
  now retains masked active-low requests, applies EINT and MPY/MPYK deferral,
  dummy-fetches and stacks the return PC, sets INTM, clears the pending latch,
  and selects vector 2; no external interrupt-acknowledge pin exists; LST is opcode family
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
  execution intervals; its INFERRED explicit-pipeline mapping holds BANZ
  ownership through the nonexecutable operand and condition-selected
  target/fallthrough fetch, tests the old selected AR[8:0], and defers the
  modulo-512 decrement with AR[15:9] preservation until retirement; directed
  evidence covers both conditions, selected-fetch stalls, no early mutation
  or fetched-instruction effect, and malformed-operand parking; original
  SPRU001B and later architectural prose support the low-nine-bit wrap, while
  a later-guide example and MAME's one-cycle untaken abstraction remain
  disclosed as `SC-011`/`SC-012`; B is
  exact opcode `0xf900`, followed by a canonical absolute 12-bit target word,
  and unconditionally loads PC after two normal program-read cycles while
  preserving all other architectural state; original TI sources and pinned
  MAME agree on its behavior and cycle total; BLZ, BLEZ, BGZ, BGEZ, BNZ, and
  BZ are exact opcodes `0xfa00` through `0xff00`, test the complete signed
  32-bit accumulator, and always consume their canonical target word and a
  second program-read cycle whether or not the branch is taken; their
  INFERRED explicit-pipeline mapping selects the target/fallthrough fetch from
  the unchanged ACC during operand completion, retains branch ownership until
  that selected word is captured, and defers its instruction effect; a
  directed matrix covers every predicate and both outcomes, including stalls
  on each selected path and malformed-operand parking; MAME instead skips that
  read/cycle on untaken paths, recorded as `SC-013`, so project timing follows
  the original TI two-word/two-cycle definitions; BV is exact
  opcode `0xf500`, tests sticky OV, always reads its canonical target word,
  selects target and clears OV when set, or selects PC+2 with OV clear when
  not set; both outcomes take two cycles; its INFERRED explicit-pipeline
  mapping holds BV through the nonexecutable operand and condition-selected
  fetch, uses old OV for selection, and clears OV only at taken retirement;
  directed tests cover both outcomes, selected-fetch stalls, effect deferral,
  and malformed-operand parking; MAME's shorter untaken abstraction is
  recorded as `SC-014`; BIOZ is exact opcode `0xf600`,
  exposes the physical active-low input without an opcode-time latch, samples
  its live value at the target-word/operand falling edge, and consumes the
  mandatory target read/two cycles in both pin states; its INFERRED
  explicit-pipeline mapping uses that sample to select cycle 2 and retains
  only the resulting decision through later pin changes or fetch stalls;
  directed tests cover both levels, changes before and after the decision,
  effect deferral, and malformed-operand parking; MAME's abstract asserted
  callback and shorter untaken path are recorded as `SC-015`; CALL is exact
  opcode `0xf800`, reads a canonical absolute 12-bit target, pushes wrapped
  opcode-PC+2 onto the top of the four-level 12-bit stack, shifts older
  entries toward the bottom, and discards the old bottom; its INFERRED
  explicit-pipeline mapping retains CALL through nonexecutable operand and
  target-instruction fetches, then pushes and transfers PC only when that
  selected word is captured; directed evidence covers both stalls, nested
  stack shifting, non-stack preservation, effect deferral, and malformed
  operands; original TI sources and pinned MAME agree on the architectural
  behavior and two-cycle total; IN and OUT are one-word/two-cycle opcode
  families with three-bit ports and the common direct/indirect internal-data
  address; Figure 2-9 explicitly places the zero-extended port and DEN/WE
  transfer in execution cycle 1 and the PC+1 MEN prefetch in execution cycle
  2; the integrated pipeline retains IN/OUT ownership across both intervals,
  samples the live IN word or holds the OUT word at the first falling
  boundary, then commits RAM/AR/ARP state, retires, and captures PC+1 only at
  the second; directed stalls prove mutual strobe exclusion, stable ownership,
  and following-word effect deferral, while invalid RAM addresses park before
  any native transaction; TBLR and TBLW are
  common-address opcode families `0x67xx` and `0x7dxx`, capture
  `ACC[11:0]`, read and discard PC+1 in their second MEN cycle, then read
  program space under MEN or write it under WE in cycle 3; completion mutates
  the selected RAM or program word, applies indirect AR/ARP changes, duplicates
  old stack level 2 into the bottom after the documented temporary push/pop,
  and leaves PC at PC+1 so the following word is fetched again; RET is exact
  word `0x7f8d`, one word/two cycles, loads PC from old TOS, shifts the
  remaining stack upward with old-bottom duplication, and is protected after
  EINT before a pending interrupt can reenter; RET's second external address
  and MEN behavior remain unknown, so model/tool support does not imply
  RTL/native qualification; CALA is exact word `0x7f8c`, one word/two cycles,
  pushes wrapped opcode-PC+1 while discarding the old stack bottom, and loads
  PC from `ACC[11:0]`; directed model tests cover upper-ACC exclusion, PC
  wrap, state preservation, and nested old-bottom loss, while its unknown
  second external address and MEN behavior keep it outside RTL/native
  qualification; PUSH and POP are exact words `0x7f9c`/`0x7f9d`,
  one word/two cycles, with low-12-bit push/old-bottom discard and
  zero-extending pop/old-bottom duplication respectively; model/tool tests
  cover repeated overflow/underflow and PC wrap, while their second external
  program cycles remain unknown under `OQ-016`; SUBH is opcode family
  `0x62xx`, subtracts the complete selected 16-bit pattern aligned at bit 16,
  preserves ACC[15:0] for ordinary and OVM-clear wrapped results, sets sticky
  OV on signed overflow, and replaces the full accumulator with the signed
  endpoint when OVM is set; direct and indirect addressing, both overflow
  directions, and its one-cycle data-read transaction are model/RTL/native/
  differential qualified, with the primary-wording resolution recorded as
  `SC-016`; an actual-core 20-step BMC now proves one fixed protected
  indirect-MPY case across arbitrary clock-enable stalls, including the old
  selected data address, signed product, low-nine-bit AR decrement with
  upper-bit preservation, ARP replacement, following-instruction protection,
  dummy entry, stack push, and vector selection; a directed 32-case matrix now
  exhausts active-low request arrival at both modeled cycles of the 11
  supported two-word control-flow families and IN/OUT, plus all three modeled
  cycles of TBLR/TBLW, checking family-specific logical bus activity,
  completion before service, one protected retirement, the resolved-PC dummy
  fetch, stack/acknowledge effects, and vector selection
- **Unresolved issues:** pipeline ownership remains absent beyond sequential
  one-cycle instructions, exact B/BANZ/BV/BIOZ/CALL, the six accumulator
  branches, and exact IN/OUT; table and interrupt
  execute-overlap
  ownership and physical interrupt setup/synchronizer behavior, CALA/RET
  second external cycles and native/RTL resumption, unsupported
  CALA/RET/PUSH/POP arrival cycles,
  provisional DINT-at-final-boundary ordering under `OQ-019`, remaining
  control-flow traces, SST reserved bit 1, LST next-ARP precedence,
  PUSH/POP second-cycle program-bus sequencing, SUBC result availability and
  OV stage, simultaneous indirect
  increment/decrement, out-of-range RAM behavior, original-part ADDH and ABS
  overflow-status behavior, physical-reset retention of unlisted state,
  DMOV/LTD source-`0x8f` destination behavior, complete Hard Drivin' BIO
  divider state and program-RAM arbitration, board-revision equivalence, and
  safe phase adaptation without READY
- **Next task:** continue `CTRL-002` by
  separating Figure 2-12 fetch/execute ownership from the now-qualified core
  machine-cycle and digital-subphase arrival matrices, and
  extend `FORMAL-001` only with bounded cases whose architectural ordering is
  already documented; preserve the
  distinction between model-qualified CALA/RET/PUSH/POP
  state/cycle behavior and absent native/RTL timing, and between the
  verified Figure 2-12 external address order and the still-collapsed
  fetch/execute pipeline;
  keep PUSH/POP RTL outside the boundary until `OQ-016` supplies the
  second-cycle program-bus sequence; keep `SST` outside the qualified boundary until reserved output
  bit 1 is resolved under `OQ-003`/`SC-008`; keep LST's loaded-ARP
  precedence labeled PROVISIONAL under `OQ-015`; keep complete interrupt
  cycle-accuracy outside the claim boundary until `CTRL-002`/`OQ-004` has
  exhaustive execute-overlap evidence; keep
  DMOV/LTD source-`0x8f` behavior provisional under `OQ-014` and
  `ADDH`/`ABS` outside the supported boundary pending `OQ-011`/`OQ-013`
- **Latest committed baseline before this cycle:**
  `45bb641`
