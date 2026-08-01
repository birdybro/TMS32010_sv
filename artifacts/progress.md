# Progress summary

- **Current milestone:** `RTL-001` shared signed accumulator arithmetic
- **Completed task IDs:** REPO-001, REF-001, TOOLS-001, BUS-003, TIMING-002
- **Tests passing:** 164 repository/provenance/document/ISA/toolchain/program
  tests; 232
  directed model/unit tests, including standalone fetch/execute and
  architectural-reset RTL units; 39 RTL
  instruction/decode tests; 5 interrupt RTL/phase
  tests; 57 native bus/phase/wrapper tests, including exhaustive original-
  MC68000 mailbox word/upper-byte/lower-byte normalization, CALA/RET bus/stall,
  and
  four-boundary interrupt qualification,
  plus a zero-versus-16-pause cross-space comparison;
  one
  512-instruction seeded
  40-one-cycle-instruction model/RTL differential including T, P, OV/OVM/INTM,
  all four stack levels, distinct logical source/write addresses, and all 144
  final RAM words; 59 reference hashes; focused two-cycle B, BANZ, BIOZ, BV,
  CALL, CALA/RET, and all six accumulator-conditional-branch model/RTL traces; focused
  IN/OUT cycle/state/RAM/transaction differential; focused three-cycle
  TBLR/TBLW bus/state/stack/RAM/program-memory differential; focused
  EINT/protected-instruction/dummy-entry/vector model/RTL differential; 36
  directed request-arrival cases across every represented machine cycle
  of all 17 currently supported multicycle core families; four native
  subphase arrivals with a stalled phase-2 case and falling-boundary ownership;
  plus fourteen ROM-free MAME-adapter/orchestration tests covering strict
  parsing, original-part widths, state normalization, strict model-state
  validation, pre/post boundary alignment, safe debugger command generation,
  executable resolution, and deterministic mismatch reporting; one opt-in
  live synthetic MAME smoke matching ten model steps across eleven boundary rows
  without copyrighted ROM content
- **Synthesis status:** Quartus 17.0.2 full flow passes internal timing for
  the fifty-eight-instruction explicit-pipeline core, multiplier, 144-word
  RAM, and program/I/O/table/interrupt-entry phase engine on `5CSEBA6U23I7`:
  1,332 ALMs, 400 registers, one 144-by-16 M10K, 1 DSP block, 48.27 MHz worst
  slow-corner internal Fmax, +19.282 ns setup slack, and +0.164 ns worst hold
  slack at the qualified 25 MHz target. A rejected explicit-pipeline 50 MHz
  fit missed slow-corner setup by as much as -9.098 ns; 50 MHz closure is not
  claimed. TimeQuest
  reports zero
  unconstrained categories after enumerated
  harness-only exclusions; no wrapper I/O is closed. Yosys 0.67+111 passes
  structural checks and generic synthesis from the 2026-07-29 OSS CAD Suite,
  producing 16,236 generic cells with 125 retained checks and lowering the
  registered RAM and forwarding to generic registers/muxes; its
  technology-neutral multiplier
  contributes 1,753 generic cells; Yosys
  is not installed on the host path. The fetch/execute register separately
  passes Yosys 0.67+111 with 29 flip-flops, 68 generic
  cells including two retained checks, and no structural problems. The
  `make synth-yosys` also runs the sequential pipeline script, which
  independently passes at 16,183 generic cells with 125 retained checks and
  no structural problems after exact B/BANZ/BV/BIOZ/CALL/accumulator-branch/
  IN/OUT/TBLR/TBLW/interrupt integration; this is not a Quartus fit or
  complete-pipeline result. The generic MiSTer wrapper separately passes
  Yosys at 16,232 generic cells
  with 132 retained checks and zero structural problems, including 49 cells
  and seven checks local to reset/callback adaptation. The standalone
  storage-free A044427 bus decoder separately passes at 15 combinational cells
  with zero structural problems. A fifth target retains the board's 4K-by-16
  adapter as one registered-read, single-write-port abstract memory in an
  85-cell hierarchy with five checks and zero structural problems.
  A sixth standalone target checks the storage-free parallel sample-ROM
  adapter at 18 abstract cells/three checks with no latch or structural
  problem. A seventh target checks the raw DAC latch at 14 cells/two checks
  with no memory, latch, or structural problem. An eighth target checks raw
  MUTE complement and IRQ latch/clear control at 33 cells/four checks with no
  memory, latch, or structural problem. The ninth, partial processor/program/
  communication/sample-ROM/DAC/output-control/BIO/host-control/port-3-latch
  board top retains six memories and passes at 3,752 abstract cells/410 checks
  with zero structural problems before technology mapping. A tenth target
  retains the standalone 512-by-16 communication memory as one `$mem_v2` in an
  82-cell hierarchy with seven checks and zero structural problems. An
  eleventh target checks the
  standalone explicit-enable BIO divider/resampler at 52 cells/seven checks
  with no memory, latch, or structural problem.
  A twelfth target checks the standalone address-encoded LS259 adapter at 53
  cells/six retained checks with no memory, latch, or structural problem.
  A thirteenth target checks the standalone port-3 LS374 adapter at 19 cells,
  five retained checks, no memory/latch, and zero structural problems.
  A fourteenth target checks both standalone complete-word mailboxes and flags
  at 259 cells, ten retained checks, no memory/latch, and zero structural
  problems.
  A fifteenth target checks the storage-free raw `/READSTAT` mapper at 23
  combinational cells, eight retained checks, no storage/latch, and zero
  structural problems.
  A sixteenth target checks the storage-free raw `/SWITCHES` mapper at 10
  combinational cells, six retained checks, no storage/latch, and zero
  structural problems.
  A seventeenth target checks the storage-free masked low-host-read selector
  at 72 abstract cells, 13 retained checks, no storage/latch, and zero
  structural problems.
  An eighteenth target checks the standalone explicit-enable local-68000 host
  timing adapter at 142 abstract cells, 24 retained checks, no memory/latch,
  and zero structural problems.
  A nineteenth target checks the storage-free local-68000 memory decoder at
  56 abstract combinational cells, 17 retained checks, no memory/latch, and
  zero structural problems.
  A twentieth target checks the composed storage-free local-memory timing
  bridge at 305 abstract combinational hierarchy cells, 40 retained checks,
  no memory/latch, and zero structural problems.
  A twenty-first target retains the optional local 8K-by-16 SRAM as separate
  upper-byte, lower-byte, and two-bit validity memories at 88 abstract cells,
  nine retained checks, no latch, and zero structural problems.
  A twenty-second target checks the storage-free upper-Y5 direct-I/O decoder
  and carrier at 336 abstract cells, seven retained checks, no storage/latch,
  and zero structural problems.
  A twenty-third target checks the storage-free local-MC68000 RESET/HALT
  release interlock at 13 combinational cells, seven retained checks, no
  storage/latch, and zero structural problems.
  A twenty-fourth target checks the tick-domain retriggerable local-MC68000
  reset source at 28 cells/seven retained checks, no memory/latch/generated
  clock, and zero structural problems.
  A twenty-fifth target checks the storage-free main `/SRES` decode at 16
  cells/four retained checks, no memory/latch, and zero structural problems.
  A twenty-sixth target checks the standalone main-board request/early-
  `/RVAS0`/`RVA`/sampled-`/DTACK`/`/RVAS` state chain at 93 cells/25 retained
  checks, with no memory, latch, generated clock, or structural problem.
  A twenty-seventh target checks the complete storage-free main `/VPA`/
  ordinary-RVA/HSBUS-wait/DUART `/DTACK` cone at 21 cells/eight retained
  checks, with no memory, latch, generated clock, or structural problem.
  A twenty-eighth target checks the storage-free main primary/RAM/HSBUS
  address decoder at 49 cells/20 retained checks, with no memory, latch,
  generated clock, or structural problem.
  A twenty-ninth target checks the address-driven composition of that decoder,
  the two held strobes, and the complete `/DTACK` cone at 185 hierarchy
  cells/64 retained checks, with no memory, latch, generated clock, or
  structural problem.
  A thirtieth target checks the storage-free original-MC68000 write-word
  normalizer at 39 mapped cells/three retained checks, with no memory, latch,
  generated clock, or structural problem.
  A thirty-first target checks the shared combinational signed accumulator
  arithmetic at 367 mapped cells with no storage, latch, retained check, or
  structural problem.
- **Formal status:** all 52 tasks from 26 SymbiYosys configurations pass with
  SymbiYosys v0.67-4-gfea6e46 and Bitwuzla 0.9.1. These include
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
  scenario evidence, not a complete interrupt or core proof. A fifth
  24-step actual-core CALA/RET BMC proves both execution boundaries,
  retirement-only push/pop, target/return PC selection, no side-bus activity,
  and arbitrary clock-enable stalls; its complete call/return cover reaches
  step 9. A separate
  12-step standalone fetch/execute BMC covers arbitrary input values under
  two legal sequencer assumptions and proves initialization, exact capture,
  stall/retention, replacement/bubble, and reset/flush transitions; its
  prime/stall/replace/flush/target cover reaches step 7. It does not prove
  integrated pipeline behavior. A sixth 40-step BMC over the actual
  sequential pipeline proves one direct LACK/TBLR/LAC/NOP path across
  arbitrary clock-enable stalls, including discarded PC+1, ACC-addressed MEN
  transfer of `0x1234`, RAM commit, repeated PC+1, and following ACC
  consumption. Its complete cover reaches step 34; this is not a general
  table or pipeline proof. A seventh 40-step BMC checks one direct TBLW under
  an explicit enabled phase-3 synchronous program-memory contract. It proves
  the old PC+1 word persists until the exact write boundary, address 2 receives
  `0x7e44` exactly once, and only the repeated replacement fetch executes as
  `LACK 0x44`; its complete cover reaches step 35. An eighth 10-step
  actual-core BMC proves recognized-reset controls, transaction and
  instruction-valid suppression, clock-enable priority, documented OVM
  retention, and the explicitly provisional retention bundle under `OQ-012`;
  its nonzero-ACC/OVM reset cover reaches step 5. A ninth 40-step standalone
  native-program-bus BMC leaves logical reset, clock enable, program-read
  qualification, and next address arbitrary. It proves four-phase
  progression, synchronous boundary-only reset assertion, no premature read
  abort, inactive address zero, the full release wait, first-read activation,
  `CLKOUT`/`MEN`/sample relationships, and stall behavior. Its five-cycle
  reset/address-0/address-1 cover reaches step 34; physical electrical timing
  remains outside the proof. A tenth one-step standalone multiplier BMC checks
  all 2^32 arbitrary 16-bit operand pairs against an explicitly sign-extended
  signed product. It proves the unique `0x8000`-square exception,
  commutativity, and zero/unity identities; all four exception/extrema covers
  reach step 0. Instruction sequencing, physical timing, and technology
  mapping remain outside that proof. A separate one-step standalone
  accumulator proof quantifies all two-operand/add-subtract/OVM combinations,
  checks modulo results, signed overflow, and final saturation against an
  independent signed 33-bit reference, and reaches all four saturation
  directions at step 0. Operand selection, sticky OV, instruction sequencing,
  and timing remain outside that primitive. An eleventh standalone RAM configuration
  passes a six-step base case and temporal induction over a symbolic address
  spanning every qualified word. From arbitrary initial contents and under
  active-address-valid/mutually-exclusive-write interface assumptions, it
  proves CPU/debug read-after-write, non-target preservation, every eight-bit
  validity result, and the portable invalid-read-zero policy. Five covers
  reach word 0, word `0x8f`, a non-target write, and invalid reads at `0x90`
  and `0xff`. Original-silicon `OQ-002`, physical power-up contents,
  instruction address selection, electrical timing, and technology mapping
  remain outside that proof. A separate five-step phase-staged RAM induction
  quantifies the same 144 addresses and proves CPU/debug same-address
  forwarding plus untouched-word persistence without constraining initial
  contents; three covers reach both write sources and the stable path. A
  twelfth one-step decoder BMC leaves all 16
  instruction bits arbitrary and proves the partial RTL's exact valid set
  against a compact family/field predicate, operation bounds, and meaningful
  operand projections. Nine step-0 covers reach legal direct/indirect,
  primary-reserved, simultaneous-update, pattern-mismatch, primary-unlisted,
  RTL-supported CALA/RET, and upper-MPYK cases. Mnemonic authority remains with the
  database/fixtures; execution, timing, and unsupported-silicon behavior are
  excluded. A thirteenth 16-step standalone host-timing BMC checks arbitrary
  address/control values and stalls under explicit alternating-edge and
  completed-release assumptions. It proves exact external equations, captured
  state, VPA suppression, completion timing, and held-`/AS` no-retry behavior;
  whole-word read/write covers reach step 8 and the fully settled VPA cover
  reaches step 9. Raw-pin CDC, board-top side effects, and electrical timing
  remain outside this proof.
  A fourteenth 12-step board-hierarchy BMC/cover pauses DSP execution and
  symbolically selects `/SOUNDRD`, complete or partial `/SOUNDWR`,
  `/LATCHES`, `/SPEECH`, or `/IRQCLR`. It proves exact pre-completion read
  data/masks, S7 mailbox/control routing, duplicated upper/lower byte capture,
  speech non-effect,
  external-callback isolation, both partial-byte orientations, and
  invalid-carrier clamping. Seven covers reach solver step 10. Arbitrary
  host-event spacing, running-DSP interaction,
  raw-pin CDC, preset-release collision behavior, and electrical timing remain
  outside this proof.
  A fifteenth 7-step communication-byte composition BMC leaves the nine-bit
  address, sixteen-bit bus data, and selected byte lane arbitrary. It proves
  the original-MC68000 normalizer result is committed and returned by the
  owner-qualified 512-word RAM; both upper- and lower-byte covers are
  reachable at solver step 6. HM6116 electrical timing, raw-pin CDC, and
  firmware access widths remain outside this proof.
  A sixteenth 7-step program-byte composition BMC leaves the twelve-bit
  address, sixteen-bit bus data, and selected byte lane arbitrary. It proves
  the original-MC68000 normalizer result is committed and returned by the
  reset-qualified 4,096-word program RAM; both upper- and lower-byte covers
  are reachable at solver step 6. Firmware reset-handoff compliance,
  asynchronous SRAM electrical timing, raw-pin CDC, and access widths remain
  outside this proof.
  A nineteenth standalone main-held-strobe configuration passes a 12-step BMC
  against an independent transition model under event-exclusivity and
  phase-level/edge-consistency assumptions. Its 16-step cover reaches seven
  classes: the complete request/assert/low-sample/RVA-end/release chain, held
  `/RVAS` after a missed low sample, `/RVAS` release, early `/RVAS0`,
  low-phase immediate assertion, asynchronous-preset priority, and `/RVAS0`
  release. The proof excludes the upstream acknowledgement equation, raw-pin
  CDC, electrical timing, and physical power-up state.
  A twentieth standalone main-`/DTACK` configuration proves all intermediate
  and final Boolean equations in one step across arbitrary raw inputs. Its
  one-step cover reaches ordinary ACK, CPU-space `/VPA`, HSBUS ACK and wait,
  and DUART ACK and wait. Legal bus combinations, external peripheral
  protocols, propagation delay, and raw-pin CDC are outside this proof.
- **Phase-pause evidence:** the original part has no READY/WAIT pin. The
  platform `clock_enable_i` adaptation is now directed-tested across ordinary
  MEN, IN/DEN, OUT/WE, TBLR/MEN, and TBLW/WE phases. Sixteen inserted host
  clocks hold every exposed retained control/state value, produce no early
  sample or retirement, add exactly 16 clocks to completion, and converge to
  the zero-pause PC/ACC/RAM/program-memory result. The standalone 40-step bus
  proof additionally checks held `CLKOUT` and conditionally held `MEN` under
  arbitrary enable choices. This is synchronous FPGA evidence only; physical
  timing is governed separately by the primary clock envelope and no unbounded
  liveness theorem is claimed.
- **Physical clock evidence:** SPRU001B specifies the TMS32010-20 external
  master-clock period as 48.78–150 ns and pulse duration as 47.5–52.5% of the
  period. With four master periods per `CLKOUT`, the rated physical machine
  cycle spans 195.12–600 ns. `OQ-001` is resolved: bounded slowing is allowed,
  but an arbitrary or indefinite physical phase stop is outside specified
  conditions. TI does not separately qualify dynamic modulation between
  otherwise conforming periods.
- **Status-word evidence:** SPRU001B defines exactly five architectural status
  bits. Its overview, LST, and SST figures agree that stored-word bits 12:9
  and 7:2 are ones; LST ignores bit 13 and every non-field position. Only bit
  1 conflicts: the overview calls it don't-care while both original
  instruction pages draw one, and later TI figures are internally
  inconsistent. Model tests now exercise every ignored source position and
  the RTL test checks the full `0x1efe` constant mask. Stored bit 1 remains
  CORROBORATED under `OQ-003`/`SC-008`; no hidden writable status is inferred.
- **New architecture facts:** original part is ROMless NMOS with 144 data
  words and no READY pin; the TMS32010-20 external master clock must remain
  within 48.78–150 ns and 47.5–52.5% pulse duty, bounding `CLKOUT` machine
  cycles to 195.12–600 ns rather than permitting a stopped physical clock;
  TI SPRA003A describes original-TMS32010 direct-form FIR evaluation as a
  finite weighted sum and identifies `LTD`/`MPY` as the paired mechanism for
  accumulating the previous product, loading the next sample, moving sample
  history, and starting the next product; the new source and numeric fixture
  are independently project-authored and do not elevate the application
  report above the original instruction definitions;
  the pinned Hard Drivin' adapter maps port 0 as sound-ROM read/DAC write,
  port 1 as communication-RAM read, port 2 as an incompletely modeled compare
  read, port 3 as an eight-bit `/CPORT` latch onto host `D15:D8`, ports 4–5 as
  mute/68000-IRQ writes, and ports 6–7 as
  sound-ROM bank/address writes; the synthetic smoke fixture verifies raw
  processor transactions while retaining these roles below primary authority;
  reset requires at least five machine cycles and leaves
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
  one word and one program-only cycle, negates ordinary negative ACC values,
  and selects wrap or positive saturation for `0x80000000` through OVM. It
  preserves incoming OV: SPRU013's instruction-format rule makes the original
  ABS page's absent status annotation meaningful, the later C14/E14 variant
  explicitly adds an OV effect, and pinned MAME independently corroborates
  preservation. Result and timing are VERIFIED_PRIMARY; OV preservation is
  CORROBORATED under resolved `SC-007`/`OQ-013`; ADDH is family `0x60xx` and
  performs a modulo-16-bit addition into `ACC[31:16]` while always preserving
  `ACC[15:0]`. Original TI instruction-format rules and both original ADDH
  descriptions omit any status effect, so the qualified original-part result
  preserves OV and ignores OVM. The later C14/E14 variant explicitly adds
  OV/OVM behavior, pinned MAME intentionally adopts that later behavior, and
  the independent IKA32010 RTL routes ADDH through a common saturating path;
  those conflicts are retained under resolved `SC-017`/`OQ-011`, making the
  original-part status behavior CORROBORATED rather than hardware-verified;
  SST is family `0x7cxx`,
  stores OV/OVM/INTM/ARP/DP plus documented one-filled fields, forces direct
  accesses to page-one addresses `0x80` through `0x8f`, and captures the old
  ARP before indirect post-modification/replacement. SPRU001B and SPRU013,
  independently corroborated by pinned MAME, resolve reserved output bit 1
  high under `SC-008`/`OQ-003`; it remains reserved to software. LAR loads either auxiliary
  register from internal data RAM in one
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
  EINT before a pending interrupt can reenter; CALA is exact word `0x7f8c`,
  one word/two cycles,
  pushes wrapped opcode-PC+1 while discarding the old stack bottom, and loads
  PC from `ACC[11:0]`; directed model tests cover upper-ACC exclusion, PC
  wrap, state preservation, and nested old-bottom loss; model/RTL/
  differential, bus/stall, interrupt-arrival, and bounded-formal tests now
  qualify both computed-control instructions under ADR-0003's discarded-
  `PC+1` then selected-target mapping, while physical pin confirmation remains
  explicitly `UNKNOWN`; PUSH and POP are exact words `0x7f9c`/`0x7f9d`,
  one word/two cycles, with low-12-bit push/old-bottom discard and
  zero-extending pop/old-bottom duplication respectively; model/tool tests
  cover repeated overflow/underflow and PC wrap; TI's original pin table
  requires active MEN in both non-I/O execution cycles, while its pipeline
  prose says program memory is always addressed by PC, but no located primary
  waveform establishes the address or fetched-word ownership of each
  interval. Pinned IKA32010 instead idles and holds PC in the first
  microcycle, producing source conflict `SC-018`; `OQ-016` remains open and a
  checked eight-word synthetic program plus original-NMOS logic-analyzer
  procedure now defines the resolving evidence; SUBH is opcode family
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
  dummy entry, stack push, and vector selection; matching directed 32-case
  core and explicit-pipeline matrices now
  exhausts active-low request arrival at both modeled cycles of the 11
  supported two-word control-flow families and IN/OUT, plus all three modeled
  cycles of TBLR/TBLW, checking family-specific logical bus activity,
  completion before service, one protected retirement, the resolved-PC dummy
  fetch, stack/acknowledge effects, and vector selection; the explicit
  pipeline now implements the basic Figure 2-12 ownership sequence by
  retiring one protected word while discarding N+2, performing entry with an
  empty execute slot while capturing vector 2, and deferring vector execution
  until the following interval; MPY and MPYK in that protected slot now have
  explicit tests for signed products, internal-read versus program-only bus
  shape, independent stalls, one additional retirement, dummy discard,
  post-following stacked PC, vector capture, and deferred vector execution;
  the explicit table pipeline now retains TBLR/TBLW through discarded PC+1,
  ACC-addressed MEN/WE transfer, and repeated PC+1 intervals, committing
  RAM/AR/ARP/stack/retirement state only on the repeated fetch; a
  self-modifying TBLW test proves the old PC+1 word is discarded and only the
  rewritten word executes; a bounded integrated-pipeline proof independently
  checks one direct TBLR program through subsequent LAC consumption across
  arbitrary clock-enable stalls; a complementary proof checks one direct TBLW
  write/refetch/execution sequence under an explicit synchronous
  program-memory model; matching core and explicit-pipeline 32-case
  matrices now cover every
  represented execution interval of the 11 supported two-word control-flow
  families, IN/OUT, and TBLR/TBLW, including native strobe ownership,
  no midinstruction entry, one protected retirement, dummy discard, stack
  entry, acknowledge state, and vector capture
- **New opcode-audit evidence:** all 65,536 words now receive exactly one
  evidence-scoped classification: 21,895 documented legal, 10,976 setting
  TI's explicitly reserved indirect-address bits 6/2/1, 372 original-pattern
  simultaneous increment/decrement combinations held under `OQ-010`,
  3,637 documented-pattern mismatches, and 28,656 encodings absent from TI's
  explicitly complete primary instruction summary. A generated
  report and boundary tests guard the counts. Pattern mismatches and
  primary-unlisted words are not called reserved and receive no original-
  silicon behavior; the documentation partition is complete while reserved-
  behavior qualification remains partial.
- **New integration evidence:** A044427 Rev-A sheet 7 and AMD's 1983 Am6012
  data establish `/DACL` latching of raw `TD15:TD4` onto uncomplemented
  `B1:B12`, with `TD3:TD0` absent and the complete analog current inverted by
  the first TL084 stage. Pinned MAME separately XORs bit 11 before its
  unsigned DAC mapper; `SC-019`/`OQ-020` preserve this as an unresolved
  signed-audio/board-variant conflict. The ROM-free smoke now asserts physical
  code `0xf23` separately from MAME's `0x723` for source word `0xf230`.
- **New program-memory evidence:** A044427 sheets 3–5 establish a 4K-by-16
  program RAM with independent host and DSP buffer enables rather than an
  arbiter. Legal host access requires asserted `/320RES`; selecting `/320RAM`
  while the DSP runs is invalid contention (`SC-020`/`OQ-021`). The physical
  decoder routes every low-address WE, including TBLW at `0x000`–`0x007`, to
  output ports instead of program RAM (`SC-021`). A synthesizable decoder now
  exhaustively checks all addresses and ownership combinations.
- **New storage evidence:** the same-clock board adapter loads all 4,096 words
  through the reset-qualified host path and reads each back through the TMS
  path. It preserves memory across adapter initialization, commits safe
  high-address TMS writes, diverts low-eight writes to I/O, and disables both
  writers during invalid overlap. Yosys retains the array as one `$mem_v2`;
  Quartus block-RAM mapping remains unclaimed. At that checkpoint, A044427's
  unqualified host path conflicted with MAME byte merging under
  `SC-022`/`OQ-022`; the later original-MC68000 audit below resolves the
  physical captured value.
- **New integration evidence:** the processor-connected wrapper host-loads the
  corrected ROM-free smoke, preloads communication word `0x056`, performs
  conflict-free `/320RES` and CRAMEN handoffs, and
  reproduces 12 retirements, 22 cycles, nine physical I/O transfers, the BIOZ
  path, and final ACC. Internal port 1 ignores a deliberately wrong external
  sentinel, and the three input reads advance the loaded address from
  `0x3456` to `0x3459`. A reset-time host read proves communication retention;
  a second reset/reload proves low-address TBLW readiness and write data route
  through output port 3 without changing program RAM.
- **New communication evidence:** A044427 configures two HM6116 devices as
  512 by 16 words. CRAMEN selects host read/write or DSP port-1 read-only
  ownership; `SA8:SA0` supplies the DSP address. Four LS191 counters load on
  port 7 and increment after every input read, with a separate port-6 ROM
  block nibble. Port 3 is separate from that state and clocks `TD7:TD0` into
  host-facing LS374 50L. Official TI LS191/LS259/LS374 sources are hash-pinned,
  and `SC-023`–`SC-025` isolate MAME's
  unconditional DSP access, selective increment, and byte merge.
- **New communication implementation evidence:** the standalone adapter loads
  all 512 complete words from the host and reads them at exact low-nine
  addresses through DSP port 1. Directed simulation covers both ownership
  states, blocked non-owner requests, owner-tagged synchronous reads, global
  port-2 increment, 16-bit wrap, port-7 load, port-6 low-nibble state, port-3
  address-control isolation, invalid pre-load state, and memory retention. Yosys retains one
  512-by-16 memory in an 82-cell hierarchy with seven checks. The board-top
  execution described above now qualifies its processor callback connection;
  physical HM6116 timing and a 68000 bridge remain unimplemented.
- **New sample-ROM evidence:** A044427 implements a parallel, byte-wide path,
  not a serial shifter. Port 6 selects one of twelve drawn 64K-byte blocks,
  the pre-increment shared address drives `SA15:SA0`, and port 0 maps byte
  `SD14:SD7` as `{{2{byte[7]}}, byte[6:0], 7'b0}`. Pinned MAME omits TDI15 for
  negative bytes (`SC-026`). Official TI LS138/LS244/LS374 sources are
  hash-pinned. The smoke fixture now selects populated Hard Drivin' block 3
  and expects physical byte `0xd5` as `0xea80`; block population and absent
  reads remain `OQ-026`.
- **New sample-ROM implementation evidence:** the storage-free adapter checks
  all 16 block values, every one of 65,536 pre-increment addresses, all 256
  byte values, explicit presence/validity, unready responses, and port
  isolation. It never acknowledges an invalid/absent selection. The board top
  now routes port 0 internally, rejects an external `0x6a80` sentinel, holds
  block 3/address `0x3457` across three unready clocks, returns synthetic byte
  `0xd5` as `0xea80`, commits once, and advances only through the shared
  physical I/O pulse. No ROM image is stored or distributed.
- **New raw-DAC implementation evidence:** the board-only latch exhausts all
  65,536 input words and proves `TD3:TD0` aliases, port isolation, one-clock
  commit, persistence, and explicit FPGA validity. The integrated smoke ignores
  deliberately low external readiness for port-0 output and captures `0xf230`
  exactly once as uncomplemented `0xf23`; MAME's `0x723` stays outside RTL.
  A separate five-cycle address-zero TBLW run captures internal word `0x00a5`
  once as raw code `0x00a` despite that external backpressure, then reads
  program word zero back unchanged as `0x7e00`. This test exposed and corrected
  board-top readiness selection for low-address TBLW.
  Analog voltage and signed-sample interpretation remain `OQ-020`.
- **New output-control evidence:** A044427 sheets 2, 3, 5, and 7 plus TI
  SDLS119 establish both LS74 halves at location 100H. Port 4 captures `TD0`
  and exports raw complementary `MUTE=/Q`; port 5 presets active-high
  `320IRQ` independently of data, while `/320RES` and the separate host
  `/IRQCLR` path clear the respective Q state. The standalone RTL exhausts all
  65,536 port-4 words and all 65,536 port-5 words, reset, isolation, host
  clear, and set priority. Integrated smoke completes both ports despite low
  external readiness, captures MUTE low, asserts and host-clears IRQ, and
  restores MUTE high on reset. The only drawn Rev-A mute consumer is marked
  `NOT LOADED`; `SC-027`/`OQ-027` therefore keep effective audio semantics
  unknown. The newly acquired TI LS74 data sheet and all 28 local reference
  files passed pinned SHA-256 verification at that checkpoint.
- **New BIO evidence:** A044427 sheets 1, 2, and 4 plus newly acquired TI
  SDLS060 and existing SDLS119 establish a cascaded LS161 preload of `0xce`,
  terminal `0xff` reload, and one-1-MHz-period active-low `/320BIO` pulse every
  50 periods. LS74 70S separately samples it on nominal 5 MHz CLKOUT. Board
  `/RESET` clears only the source LS74; the counters and resampler have no
  reset initialization. Standalone RTL therefore uses two noncoincident clock
  enables and exports counter, source, and pin validity. Directed simulation
  covers all fifty states, the five-sample pulse, reset continuity, release,
  and invalid-seed self-qualification from all 256 possible values. All 29
  cached sources match pinned
  hashes. MAME corroborates 20 kHz cadence but its query-driven event remains
  `SC-028`, not pin-waveform evidence; independent-clock setup/hold is
  `OQ-028`. The partial board top now instantiates this generator as an opt-in
  while preserving external raw BIO as the default. It derives CLKOUT sampling
  from the actual modeled processor phase and rejects a same-FPGA-clock 1 MHz
  coincidence. An integrated fixture holds external BIO high, selects a
  qualified generated low, proves BIOZ reaches only `LACK 0x22` in three
  cycles, and observes release only after a later CLKOUT sample. Board-top
  Yosys passes at 2,495 abstract cells/171 checks/three memories.
- **New compare-path evidence:** A044427 sheets 3 and 5 prove that port-2
  `/CMPRD` enables only `CMPOUT` onto `TDI15`; the target supplies no drawn
  source for `TDI14:TDI0`. Sheet 8 draws the microphone/DAC LM311 comparison
  and 1 kΩ open-collector pull-up, then explicitly states
  `THIS SHEET NOT LOADED.` Newly acquired TI SLCS007K confirms the component
  pinout and output polarity. `SC-029`/`OQ-029` now isolate MAME's complete
  zero word as an emulator stub, not a physical default. The existing external
  port-2 callback is retained, the smoke zero is labeled a synthetic sentinel,
  and no unsupported RTL was added. All 30 cached sources pass pinned SHA-256
  verification; the full regression and lint pass unchanged.
- **New host-control evidence:** A044427 sheet 3 and TI SDLS086 establish that
  LS138 `30N` selects `/LATCHES` for a host write with `A13:A12=01`, while
  LS259 `80R` takes its select from `A3:A1` and its value from `A4`; host data
  does not enter the latch. Board `/RESET` clears all raw Q outputs, including
  `CRAMEN=Q3` and `/320RES=Q4`. The new standalone same-clock completion
  adapter exposes all eight raw values plus per-bit validity. Directed
  simulation exhausts every selection and both values, retention, reset, and
  reset-over-write priority; standalone Yosys reports 53 cells/six checks.
  The board top now connects it only behind an explicit opt-in, preserves the
  external callbacks by default, and exports validity for selected Q4/Q3.
  With opposite-valued external sentinels, a synthetic sequence applies board
  reset, loads program and communication RAM under latched ownership, hands
  both to the DSP, executes `LACK 0x5a; NOP` in two cycles, reasserts latched
  reset, and reads communication word `0x1357` back under Q3. Integrated Yosys
  reports 2,495 cells/171 checks/three memories with zero structural problems.
  This does not claim `/RVAS`, DTACK, or physical level-sensitive timing.
- **New host-read evidence:** A044427 sheets 2–4 establish that `/SOUNDRD`
  drives a complete word and clears `MAINFLAG`, `/320PORT` drives only
  `D15:D8`, and `/SWITCHES` plus `/READSTAT` each drive only `D15:D12`.
  `OQ-030` keeps every undriven lane electrically unknown. Sheet 4 LS374 50L
  resolves `OQ-023`: `/CPORT` captures `TD7:TD0`, while pinned MAME only logs
  the write and returns zero (`SC-030`). The new standalone RTL exhausts all
  65,536 input words, non-target ports, direction/commit isolation, validity,
  and masks. Integrated smoke captures `0xa5` on OUT and `0x30` on low-address
  TBLW under forced external backpressure, exposes only masked host carriers
  `0xa500`/`0x3000`, preserves state across board reset, and leaves program
  RAM unchanged. Standalone Yosys reports 19 cells/five checks; the board top
  reports 2,495 cells/171 checks/three memories with zero problems.
- **New mailbox evidence:** A044427 sheet 2 and TI SDLS165B/SDLS119 establish
  complete 16-bit LS374 latches in both main/sound directions, LS74 `20S`
  pending flags set by writes and cleared by opposite-side reads, flag-only
  board reset, and unreset data latches. Pinned MAME corroborates the nominal
  software handshake but byte-merges local sound writes (`SC-031`/`OQ-031`).
  The standalone callback exhausts all 65,536 words in both directions,
  reset/data retention, read-clear, conflict invalidity, and requalification.
  Standalone Yosys reports 259 cells/ten checks with zero structural problems;
  board-top integration remains deliberately separate.
- **New `/READSTAT` evidence:** A044427 sheet 2 proves that LS244 `10K` maps
  live raw `MAINFLAG`, `SOUNDFLAG`, `SOUND.TEST`, and active-low `/TIRDY` to
  host `D15:D12`, while the selected target does not drive `D11:D0`. Pinned
  MAME instead fixes the test/ready/low-lane values, now isolated as `SC-032`.
  The storage-free mapper exhausts all sixteen source nibbles and all sixteen
  source-validity masks, exposes constant driven mask `0xf000`, and never
  promotes deterministic filler into board behavior. Standalone Yosys reports
  23 cells/eight checks with zero structural problems. Board-top evidence is
  recorded separately below; complete 68000 read integration remains absent.
- **New mailbox/status integration evidence:** `hard_drivin_sound_mister` now
  exposes distinct decoded-completion callbacks for main-system write/read and
  local sound-CPU write/read, retains both complete words, and exports every
  data/flag validity and conflict signal. The mailbox flags directly drive the
  masked raw `/READSTAT` adapter alongside explicit external `SOUND.TEST` and
  `/TIRDY` inputs. The integrated regression verifies both nominal directions,
  both coincident conflicts, exact status data/masks, later requalification,
  external-source invalidity, and board-reset flag clear with data retention.
  Pre-technology board synthesis retains three memories at 2,737 cells/216
  checks with zero structural problems. No byte policy, `/RVAS`, DTACK,
  physical collision priority, or open-bus value is inferred.
- **New `/SWITCHES` evidence:** A044427 sheet 3 and TI's LS244 function table
  establish the non-inverting order `J3-11/J3-9/J3-8/J3-7` on host
  `D15:D12`; no connector source is drawn for `D11:D0`. The storage-free
  mapper exhausts all sixteen raw nibbles against all sixteen validity masks
  and exposes fixed driven mask `0xf000` without assigning cabinet functions
  or idle levels. Standalone Yosys reports 10 cells/six checks with zero
  structural problems. Cross-checking pinned MAME found its named
  `/SWITCHES` and `/320PORT` read handlers reversed relative to Atari LS138
  `30N`; both zero stubs conceal that difference. `SC-033` records the
  conflict, and `OQ-032` retains connector semantics. The complete
  125/231/38/38/5/10 regression split, strict lint, all sixteen Yosys targets,
  all 30 hashes, and all 24 formal tasks pass at this checkpoint.
- **New masked-read evidence:** `hard_drivin_sound_host_read_mux` selects
  `/SOUNDRD`, `/320PORT`, `/SWITCHES`, and `/READSTAT` in A044427 LS138
  `30N` order and forwards each source's exact data/driven/valid masks. Its
  standalone regression checks invalid selection, every driven lane, distinct
  source masks, and exact one-hot state; Yosys reports 68 cells/13 checks.
  The board top now composes live sources and verifies the Atari order that
  conflicts with MAME's handler names, switch validity, `/SOUNDRD` selection
  without flag clear, and both `/320PORT` captures. Integrated synthesis
  retains three memories at 2,737 cells/216 checks. No `/RVAS`, DTACK,
  completed-read, byte, or open-bus behavior is inferred. The complete
  125/231/38/39/5/10 regression split, strict lint, all seventeen Yosys
  targets, all 30 hashes, and all 24 formal tasks pass at this checkpoint.
- **New local-host timing evidence:** the ignored cache now pins Atari TM-327
  third printing and Motorola M68000UM Ninth Edition, bringing the manifest to 32
  acquired sources. Cross-sheet tracing corrects the earlier abbreviated
  decode description: LS138 `30N` requires active `/RVF` as well as `/RVAS`;
  LS138 `30P` produces `/RVF` only for asserted `/AS`, `A23=1`, and
  `A16:A14=100`, leaving `A22:A17` as physical aliases. The shared-8-MHz F74
  chain is now accounted for from S2 through S7: `/AS` arms the sequence, S4
  asserts a one-period `RVA` and `/DTACK`, falling-edge F74 `50S` holds
  `/RVAS` across S6, and the target releases after the S7 data-latch edge.
  There is no READY input or held-`/AS` acknowledgement retry. TM-327 also
  supplies primary-published future test roles for local-68000 program/program
  RAM, TMS32010 communication/program RAM, IRQ, DAC, tune/sweep, and block
  latch diagnostics. No RTL was added: full TTL propagation/loading margin
  and unreset power-up transients remain explicit `OQ-033` work.
- **New logical host-adapter evidence:**
  `hard_drivin_sound_host_timing` implements the isolated same-clock
  S2-through-S7 boundary with mutually exclusive 8 MHz enables, distinct
  `/AS` events, complete address/control capture, `/VPA` suppression, exact
  `/RVF` and eight-way target decode, global byte-write strobes, and qualified
  one-clock completions. It has no READY input. Simulation exhausts all 8,192
  `A22:A17` alias, `A23`, `A16:A14`, read/write, and quadrant combinations,
  then directs every UDS/LDS state, CPU-space VPA, delayed `/AS` release,
  held-`/AS` no-retry behavior, and mid-cycle deterministic FPGA
  initialization. Pre-edge completion events preserve the S7 state-consumer
  boundary while registered pulses remain available for tracing. Yosys
  0.67+111 reports 142 cells/24 checks with no memory/latch or structural
  problem. The board top now offers it as an explicit opt-in: all four masked
  read quadrants remain selected through S6; S7 routes `/SOUNDRD`, word or
  normalized-byte `/SOUNDWR`, `/LATCHES`, and `/IRQCLR`; byte mailbox writes
  are reported and accepted; and `/SPEECH` remains visible without a side
  effect. External callbacks remain the default and are explicitly isolated
  while opted in.
  Integrated Yosys retained three memories at 3,294 cells/338 checks at that
  checkpoint. At that checkpoint this did not close `OQ-030` open bus, the
  then-open `OQ-031` byte behavior, or `OQ-033`
  raw-pin CDC, TTL margin, and physical startup. The complete current
  127/231/38/43/5/10 regression split, strict lint across 31 modules, all
  twenty-one Yosys targets, all 33 hashes, and all 28 tasks from fourteen formal
  configurations pass. The adapter's dedicated 16-step bounded harness uses
  the documented legal same-clock event contract and reaches read, write, and
  VPA paths; the 12-step board harness reaches seven covers across all six
  implemented routing classes and both partial-byte orientations with the
  processor paused.
- **New local-68000 memory-decode evidence:** A044427 sheets 3-5 and newly
  pinned TI SDAS113B establish the ROM `/CE=A23 OR /AS` gate, all eight LS138
  `30P` high-bank outputs, Y5's A13-selected program-RAM versus direct-TMS-I/O
  controls, Y6 communication selection, and Y7 local-RAM selection. The
  drawn/default 27256 pair uses CPU `A15:A1`; the local 6264 pair uses `A13:A1`
  with separate `/UDS`/`/LDS` write enables and complete-word read drive. The
  storage-free RTL exhausts 131,072 combinations over `/AS`, `RVA`, `/RVAS`,
  `A23`, every ignored `A22:A17` alias, all banks, A13, direction, and byte
  strobes. Strict lint covered 30 modules, and all twenty Yosys targets
  pass; the new target reports 56 cells/17 checks. Pinned MAME's canonical
  windows and 128 KiB declared ROM region do not reproduce the physical
  aliases (`SC-034`). The exact E1/E2 production option remains `OQ-034`.
- **New local-memory callback evidence:** the timing adapter now exports its
  captured R/W direction, and the storage-free bridge composes it with the
  complete decoder. End-to-end synthetic cycles verify valid and unavailable
  ROM data, physical ROM aliases, explicitly invalid unwritten local SRAM,
  full and upper-byte local-SRAM S7 commits, a broad Y7 alias, Y5 program
  reads/writes, direct `/PDEN` reads and `/PWE` S6 writes, Y6 communication
  reads/writes, and Y4 isolation. Read carriers preserve separate driven and
  valid masks and report a fixed-S7 missing response without READY or an
  open-bus value. Standalone Yosys reports 305 hierarchy cells/40 checks and
  no storage/latch or structural problem.
- **New board-composition evidence:** selecting host timing now routes lower
  Y5 into the existing program RAM and Y6 into the existing communication RAM
  without changing their reset/CRAMEN ownership rules. The board regression
  writes and synchronously reads both memories through complete physical host
  cycles, proves upper-Y5 direct I/O cannot modify program RAM, observes its
  `/PWE` callback at S6, forwards synthetic valid ROM/local-SRAM read carriers,
  and emits one upper-byte local-SRAM commit at S7. Contradictory explicit
  callback sentinels are ignored while opted in; later timing-disabled phases
  still pass through the original explicit callbacks. Integrated Yosys retains
  the three then-existing memories at 3,294 cells/338 checks with zero
  structural problems.
  At that checkpoint, partial lower-Y5/Y6 writes produced distinct trace
  pulses and were rejected pending inactive-lane evidence. Later original-
  MC68000 audits supersede both protective policies with duplicated-byte
  capture while retaining the diagnostics.
- **New local-SRAM evidence:** `hard_drivin_sound_local_ram` preserves the two
  physical byte lanes as independent 8K-by-8 data memories and tracks known
  FPGA contents in a separate two-bit validity memory. Its exact 8,192-clock
  metadata scrub leaves both data arrays unreset, masks every unwritten lane,
  reports pre-ready writes, and exposes readiness/progress to the platform.
  Standalone regression covers all 8,192 addresses before writes, after a full
  patterned load, and after re-scrub, plus separate upper/lower boundary cases.
  Board regression proves the external callback is the default, internal opt-
  in ignores an all-valid external sentinel, and independent byte writes
  compose `0x5aa7`. Standalone Yosys reports 88 cells/nine checks/three
  memories; the board top reports 3,424 cells/362 checks/six memories. This
  initialization contract is an FPGA policy, not physical 6264 reset evidence.
- **New upper-Y5 direct-I/O evidence:** A044427 sheet 5 establishes an
  asymmetric decoder: reads ignore `RA11:RA2` and alias modulo four, while
  writes require `RA11:RA3=0` and select no target above canonical word 7.
  The storage-free adapter exhausts all 4,096 addresses in both directions,
  preserves separate driven/valid masks, limits comparator reads to bit 15,
  and leaves port 3 undriven. Board regression proves canonical address,
  block, DAC, and CPORT commits at S6; sample-ROM and comparator reads;
  shared-address increment at S7; a high port-3 alias; and a noncanonical
  write with `/PWE` timing but no target. Simultaneous host/TMS I/O ownership
  is suppressed and reported under `OQ-021`. Standalone formal proves the
  combinational decode/carrier contract and reaches all four target classes;
  the full regression is 128/231/38/44/5/10, strict lint covers 32 modules,
  all 22 Yosys targets pass, and all 30 formal tasks from 15 configurations
  pass. Pinned MAME's symmetric `offset & 7` behavior remains `SC-034`.
- **New local-reset evidence:** A044427 sheet 2 shows separate local-MC68000
  RESET and HALT paths, while Motorola MC68000UM §5.5 requires both asserted
  for a proper external reset. The storage-free FPGA policy preserves separate
  raw inputs and clamps both only during deterministic initialization or an
  incomplete selected internal-SRAM scrub. Standalone simulation exhausts all
  32 Boolean cases; board simulation proves external-storage pass-through,
  active-scrub blocking, and release after validity address `0x1fff`; formal
  proves every input combination and reaches four nonvacuity classes.
  Standalone Yosys reports 13 cells/seven checks, and the current board reports
  3,752 cells/410 checks with six memories. This interlock does not itself
  select
  the separate physical-source model, establish RC tolerance, or implement
  cross-domain deassertion (`OQ-035`).
- **New physical reset-source evidence:** A044427 sheet 2 and TI SDLS043 now
  establish that `/MRES` and decoded `/SRES` feed LS08 `10S` into active-low A
  of retriggerable LS123 `100N`, with B/clear high. C43=10 µF and R79=47 kΩ
  yield about 155.1 ms nominal from TI's typical large-capacitance equation;
  the data sheet's early-trigger rule yields about 2.2 ms of trigger inhibit.
  The LS123 `/Q` and active-low `SOUND.RESET` test node feed LS00 `40S`; two
  separate 7406/pull-up paths then drive equal stable logic to MC68000 HALT
  and RESET. Pinned MAME instead pulses only RESET immediately (`SC-035`). A
  standalone synthesizable reconstruction uses caller-calibrated hold ticks,
  deterministic FPGA startup hold, TI's early-retrigger inhibit, and direct
  test reset. Simulation covers exact six-tick expiry, pause, both triggers,
  held-low behavior, an early ignored retrigger, and a later accepted retrigger;
  a 10-step independent hold/inhibit-counter BMC and 14-step five-class cover
  pass. Yosys reports 28 cells/seven checks. This is
  VERIFIED_PRIMARY for stable board logic and nominal calculation, verified
  only in the tick domain for RTL, and not analog/pin-timing equivalence.
- **New upstream reset evidence:** SP-327 sheet 7 makes `/MRES` a permanently
  enabled LS244 copy of system `/RESET` and transports `/EXTBUS`, `/RVAS`, R/W,
  and address to A044427. SP-327 sheet 4 and A044427 sheet 1 together prove
  `/SRES` is a write-only, `/AS`- and `/RVAS`-qualified
  `0x84c000..0x84ffff` mirror; A13:A0 and UDS/LDS are not decoded. The
  standalone module exhausts 8,192 cases, passes a one-step proof with four
  covers, and synthesizes to 16 cells/four checks. Pinned MAME exposes only
  `0x84c000..0x84c001` (`SC-036`).
- **New main-bus hold evidence:** SP-327 sheet 4 proves that `/AS` clocks a
  request latch, normal high-phase S2 assertion presets `/RVAS0` on S3
  falling, S4 rising produces one-period `RVA` and presets `/RVAS`, and a
  falling-edge sample of `/DTACK` must transition low-to-high before either
  D=0 hold releases. Low-phase immediate assertion and active-preset priority
  are also represented. The same-clock event model preserves continued hold
  if the low sample is missed, passes directed simulation and 12/16-step
  BMC/cover, and synthesizes to 93 cells/25 checks. A composed HSBUS test
  verifies zero-wait ACK, independent GSP/MSP wait extensions, raw-select
  release, and the later sampled release. The original system `/RESET`
  source, peripheral response latency, raw CDC, electrical margin, and
  physical power-up state remain `OQ-036`.
- **New main acknowledgement evidence:** the full sheet-4 gate cone is now
  pinned to TI's LS20, AS00, combined ALS32/AS32, F11, F04, and F74 data.
  `/VPA` blocks the ordinary term for function-code-7 CPU space; ordinary
  cycles acknowledge from `RVA`; `/RHSBUS` plus the GSP/MSP wait NAND form the
  HSBUS term; `/RDUART` plus MC68681 `/DUDTACK` form the DUART term; and F11
  ANDs all three active-low results. Exhaustive 4,096-case simulation,
  one-step BMC/six covers, a complete synthetic sound-reset cycle, and
  21-cell/eight-check synthesis pass. Five new cached TI files bring the
  pinned total to 39; TI's AS32 URL is byte-identical to the existing combined
  SDAS113B source. Specialized peripheral/AC timing remains open rather than
  inferred.
- **New graphics-wait evidence:** Atari A044425 Rev-J supplemental sheets 10
  and 15 connect `/GSPWAIT` and `/MSPWAIT` directly to the respective GSP and
  MSP TMS34010 `HRDY` pins while `/GSP` and `/MSP` drive `HCS`. TI SPVU001
  defines high `HRDY` as ready-to-complete, low as wait, and forces high while
  active-low `HCS` is inactive. The gate model therefore correctly retains
  both signals as peripheral-owned inputs; the composed test now exercises
  each wait source independently. The two Atari drawings and TI guide bring
  the pinned total to 42. Workload-specific host-interface latency,
  propagation margin, and CDC remain open.
- **New DUART acknowledge evidence:** SP-327 sheet 6 connects `/RDUART`
  directly to MC68681 `CS`, uses a dedicated 3.6864 MHz crystal, and pulls
  pin-9 `/DUDTACK` high through 4.7 kΩ. Motorola ADI988R1 defines that pin as
  active-low open-drain `DTACK`; recognition is tied to X1 and may move one
  device cycle when `CS` misses setup. The gate input therefore remains
  peripheral-owned. A new composition proves arbitrary external wait, late
  acknowledge, raw-select removal while the device pin is still low, and the
  later sampled release of both held strobes. The exact-device and official
  successor publications bring the pinned total to 44; successor-only write
  behavior is not transferred to Atari's part.
- **New main address-decode evidence:** SP-327 sheet 4 plus TI SDLS014 and
  newly pinned SDLS013A resolve the `/AS`-qualified `A23:A21` LS138, the
  `/RAMEN` `A15:A14` LS139, and the `/RVAS0`-qualified HSBUS LS139. Exhaustive
  simulation covers all 4,096 consumed address/control combinations and
  directs ignored-bit aliases, including physical DUART/GSP/MSP selections
  broader than MAME's canonical handlers. One-step BMC and six covers pass;
  the storage-free target is 49 cells/20 checks. The pinned total is 45.
- **New address-driven main-bus evidence:** `hard_drivin_main_bus_control`
  connects the verified raw selects to the separately verified held-strobe
  and `/DTACK` blocks without adding peripheral latency. Directed simulation
  reaches a mirrored GSP zero-wait cycle, canonical MSP cycle held by its
  external `HRDY`, mirrored DUART cycle completed by a late external
  `/DUDTACK`, and ordinary expansion-bus `RVA` acknowledgement through each
  release sequence. Strict lint and 185-cell/64-check hierarchical synthesis
  pass; constituent formal bounds remain unchanged.
- **New MAME-oracle evidence:** the strict debugger-action adapter now parses
  the exact PC/ACC/P/T/AR0/AR1/STR/STK0-STK3 marker, enforces original-part
  widths, reverses MAME's bottom-to-top backing array into the model's
  top-first stack order, and aligns model post-state N with MAME's
  pre-instruction marker N+1. Seven ROM-free synthetic tests pass. The pinned
  source remains exact commit `030fefcbd14e47c01ec9d67655be90f64a1dc8ab`;
  the separately inspected local binary is package `0.287-2.1`, reports
  `0.287 (mame0287-dirty)`, and has SHA-256
  `e8732a07ffc6995e31e5526fbf1f72e6ce55fb92cf2a1373b6a76e27cdc7dd91`.
  It is not claimed as an exact-commit build. MAME names the 20 MHz nested
  device TMS320C10. A new opt-in live run builds the machine with 20 exact-sized
  all-zero placeholders, requires MAME's wrong-checksum warning, injects the
  hand-fixed combined PUSH/POP/CALA/RET program, and matches ten model steps
  across eleven boundary rows. CALA pushes return PC `0x007`, enters `0x00c`,
  and RET restores PC `0x007` and the stack. The runner now rejects script
  launchers so its hash identifies the actual emulator binary. This is actual
  synthetic TMS320C10 execution but not Atari firmware; device equivalence,
  `/MEN`, cycles, and pin timing remain unqualified.
- **New synthesis evidence:** a checked-in setup-path reporter localized the
  preceding 33.464 ns/26-level path from registered execute word through
  wrapper decode, sampled-program selection, core decode, asynchronous RAM,
  shift, and accumulation. Registered pipeline state plus one retained table-
  direction bit remove the redundant wrapper decode without changing any
  verified machine-cycle edge. The accepted fit reduces the path to 29.180
  ns/19 levels, saves 90 ALMs, and raises worst slow-corner Fmax from 29.30 to
  33.33 MHz. A 2,633-ALM/28.98-MHz intermediate is explicitly rejected; the
  asynchronous RAM and broad core execution cone left those structures as the
  next timing limit. ADR-0004 now exploits the already modeled FPGA subphases to
  stage internal-RAM reads without another processor cycle. Same-address
  forwarding was added after an `IN`-then-`OUT` trace rejected the first
  old-data-only experiment; an in-process bypass was also rejected because it
  lost memory inference. The broad formal sweep then rejected an ungated read
  capture because `data_read_data_o` moved during a global pause; a distinct
  wrapper-subphase read enable now preserves the pre-existing stall invariant.
  The rejected ungated checkpoint's 1,420-ALM, 22.988-ns/15-level, 42.11-MHz
  figures are retained as failed evidence rather than reported as closure.
  The accepted separate forwarding metadata preserves
  one M10K and reduces the fit from 2,414 ALMs/2,703 registers to 1,416
  ALMs/417 registers. The worst path falls from 29.180 ns/19 levels to 24.217
  ns/16 levels, and worst slow-corner Fmax rises from 33.33 to 40.54 MHz.
  Decoder-provided internal-data-family metadata then removes two reconstructed
  core operation whitelists. Simulation visits all 65,536 words and compares
  every valid encoding; one-step formal covers the same valid space. The
  accepted fit uses 1,414 ALMs/417 registers,
  retains the M10K and DSP, removes the multiplier-enable cone from the top
  twenty setup paths, and places the new worst 100 °C path at 21.399 ns/14
  levels from retained table state to stack-bottom enable. Worst slow-corner
  Fmax rises to 44.84 MHz.
  One retained core-program word then replaces separate instruction/branch/
  table carriers and the combinational state-selected mux. Directed BANZ and
  TBLR traces inspect capture, stall hold, consumption, and next-fetch
  replacement; both 40-step table proofs retain their prior outcomes. The
  accepted fit uses 1,393 ALMs/400 registers, retains one M10K and one DSP, and
  moves the worst 100 °C path to the carrier-to-ACC cone at 20.034 ns/12
  levels. Worst slow-corner Fmax rises to 48.07 MHz.
- **New architecture evidence:** TI patent US4577282A is integrity-pinned in
  the ignored reference cache and scoped as authority-level-4 background. Its
  related DSP embodiment explicitly discards RET's sequential S1 fetch, pops
  the old stack top into PC, fetches that target, and begins target decode in
  S2. This CORROBORATES ADR-0003 for RET but does not establish an exact
  original-TMS32010 pin waveform. The patent's Table A omits accumulator
  PUSH/POP, so `OQ-016` remains open; the every-state external-read rule is
  independently reinforced without choosing repeated versus advancing PC
  ownership.
- **New EVM evidence:** SPRU005A rejects a breakpoint at the word following
  PUSH/POP. Section 9.3 proves the breakpoint RAM observes the TMS32010
  program-address bus and substitutes NOP data on a match. This corroborates
  `N+1` visibility during the multicycle context but does not expose `MEN`
  phase, repetition, or a subsequent address; OQ-016 H1-H3 all remain live.
- **New RAM-edge evidence:** original TI sources consistently establish 144
  implemented words at `0x00`-`0x8f`; SPRU001B's isolated `128-144` table is
  an internal off-by-one conflict, not a 145th-word specification. Related TI
  patent US4577282A explains an adjacent-column move but gives mutually
  incompatible 144-row/even-odd/eight-bit capacity statements and no final-row
  result. Pinned MAME maps only through `0x8f` yet asks its framework for the
  `+1` write, while IKA allocates 256 words. Two stable 26-word probes now
  clear/scan all 144 valid cells, expose the `0x90` read, and preserve DMOV/LTD
  registers for an original-NMOS capture; `OQ-014` remains RESEARCHING and the
  RTL policy remains PROVISIONAL.
- **New SUBC evidence:** original production guides document one cycle and
  prohibit the following instruction from consuming ACC. Related TI patent
  US4577282A exposes a Q4/Q1/Q2 unshifted-ALU path, following-state Q3
  accumulator-local quotient shift, and ALU-derived overflow input, but calls
  SUBC two-state and therefore remains related-embodiment corroboration only.
  Pinned IKA agrees on delayed availability but flags its later result; pinned
  MAME commits immediately and its apparent intermediate-overflow expression
  cannot set OV. Exact 26-word dependency and 34-word overflow-stage probes
  now distinguish these hypotheses on original NMOS hardware without assigning
  a result to the forbidden sequence. `OQ-017` remains RESEARCHING and
  `OQ-018` remains PROVISIONAL, NARROWED.
- **New DINT/interrupt evidence:** original SPRU001B Figure 2-12 executes N and
  N+1 before dummy N+2/vector entry, while later mixed-family SPRU013 Figure
  3-20 executes only N and dummy-fetches N+1. The later guide also requires
  external synchronization for an asynchronous NMOS TMS32010 input; original
  Section 2.14 independently recommends the same conditioning despite its
  simplified internal logical Sync FF. MAME
  has no overlapping boundary; pinned IKA evaluates old-mask `int_rq` while
  DINT sets the mask and therefore predicts entry-wins. `SC-039` preserves the
  conflict and isolates SPRU001B's contradictory set-INTM-valid sentence as a
  polarity typo, not priority evidence. A stable sparse 28-word fixture emits
  an armed marker, places DINT
  at original N+1, and exports the stacked return PC plus entry/resume markers
  to distinguish cancellation, N+2 entry, and earlier N+1 entry. No silicon
  result is assigned; `OQ-019` remains RESEARCHING/CONFLICT.
- **New indirect-LST evidence:** original SPRU001B/SPRU002B and later
  first-generation SPRU013 all pair the memory-status restore contract with
  `LARP 0; LST *,1` and the unexplained result “ARP becomes 1.” Generic
  indirect prose says the encoded field loads after execution and gives no
  LST exception. Later C25 documentation and pinned MAME implement
  memory-word precedence, while pinned IKA implements encoded-field
  precedence; contemporary patent control prose leaves their priority
  unstated. Expanded `SC-009` preserves the contradiction. A stable contiguous
  30-word fixture makes bit 8 disagree with the encoded field in both
  directions and emits distinct port-7 markers for both hypotheses. No
  silicon result is assigned; `OQ-015` remains RESEARCHING/CONFLICT and the
  current memory-wins model/RTL policy remains PROVISIONAL.
- **New simultaneous-update evidence:** the original TMS32010 guides define
  separate INC/DEC controls and only three normal source forms, without
  defining both bits set. A later TI TMS320C1x reference card explicitly says
  they cannot both be one. Pinned MAME increments then decrements and pinned
  IKA explicitly preserves on `2'b11`, so both independently choose no net
  update; the related TI patent counter assumes mutually exclusive controls
  and supplies no simultaneous result. `SC-040` preserves those scopes. A
  stable contiguous 23-word raw-`0x68b8` fixture exports full AR results from
  zero and `0x01ff`, distinguishing preserve, increment priority, decrement
  priority, and unexpected outcomes. No silicon result is assigned; the 372
  words remain rejected fail-closed and `OQ-010` remains open.
- **New absent-data-address evidence:** original TI material proves 144 words
  at `0x00`-`0x8f` while permitting eight-bit effective-address formation,
  but gives no `0x90`-`0xff` select result. The related patent's row/column
  capacity is internally inconsistent; pinned MAME leaves the range unmapped
  while pinned IKA allocates 256 initialized words. `SC-041` preserves those
  scopes. A stable 35-word read-only image observes every absent address after
  controlled `0x0000` and `0xffff` reads. Stable 43-word ascending and
  descending images write unique `0xa06f`-`0xa000` sentinels, then scan all
  144 valid and 112 absent locations. The read-only image must run first and
  none assigns an expected physical result. A TMS320M10 decap lead remains
  metadata-only after a lawful HTTP-429 response and supplies no decoder fact.
- **New physical-reset evidence:** SPRU001B assigns PC/address clear,
  interrupt mask/flag effects, inactive bus controls, and unchanged OVM, but
  no value to ACC/T/P/AR/ARP/DP/stack/OV. Contemporary SPRU005A says its warm
  `EX`/`RUN` RESET workflow saves every TMS32010 register except PC, while its
  overview separately warns that the uncontrolled halt clears registers and
  may corrupt memory without publishing save order. The related TI patent
  assigns broader clearing to a ROM reset routine, not the pin. Pinned MAME
  and IKA use conflicting mixed policies. `SC-042` therefore classifies the
  EVM workflow as CORROBORATED while retaining original-silicon behavior as
  PROVISIONAL. Two exact sparse images now export a complete set/clear state
  vector before reset, reconstruct P/stack/ACC/status, arm on `00a1`/`00a2`,
  and use external BIO alone to enter a post-reset observer that consumes no
  retained RAM. The project model emits matching 13-word before/after vectors;
  hardware has no assigned result.
- **New device-revision evidence:** a second SPRU001B archive artifact pins an
  October-1985 TMS32010 data-sheet revision against the existing February-1986
  embedded revision; the former labels base/-25 timing and the latter
  -20/-25. December-1986 SPRU011 and May-1987 SPRU013 list 14/20/25-MHz
  2.4-micrometer NMOS products, while April-1989 SPRU011A and the May-1989
  revised data sheet embedded in SPRU013B list only the 20-MHz NMOS product.
  None identifies a silicon mask, package-code decoder, functional change, or
  erratum. Both family timelines say current/new-device specification updates
  were distributed through a dial-up BBS whose authenticated TMS32010 notice
  archive was not located. `SC-043` and
  `docs/research/device_revision_audit.md` therefore retain publication,
  speed grade, package, tracking/date, lot, ROM sibling, and later-CMOS
  identity as separate fields. The lawful search also cataloged and rejected
  an unrelated TI32000 manual false positive. The complete source cache
  verifies; `OQ-008` remains RESEARCHING/NO REVISION MAP and no RTL behavior
  changed.
- **New DAC-code evidence:** Rev-A's complete converter path uses +5 V through
  1 kOhm plus 4.7 kOhm to the positive Am6012 reference, grounds the
  complementary current output, converts `IOUT` through an inverting 2.2-kOhm
  TL084B stage, and AC-couples `DACOUT` through 1 uF. Its physical codes
  `0x7ff`/`0x800` are adjacent ideal steps. Historical MAME 0.62 already
  paired `data XOR 0x8000` with a signed-DAC subtraction; the 2016 AM6012
  migration retained that signed interpretation, selected bits 15:4, added
  the later schematic-inversion comment, and modeled symmetric references.
  Thus MAME's comment is not independent pin evidence. Four exact historical
  sources bring the verified cache to 54. A new trace helper exhausts every
  16-bit word/low-nibble alias and emits raw, MAME, signed, current, and ideal
  first-stage voltage columns. `hard_drivin_dac_code_audit.md` fixes the
  TM-327 walking-ones/ramp plus authorized normal-game physical capture. No
  alternate drawing/ECO was located, `OQ-020` remains RESEARCHING/CONFLICT,
  and no RTL/model behavior changed.
- **New J3 evidence:** A044427 Rev A gives `J3-11/J3-9/J3-8/J3-7` only
  1-kOhm series resistors and capacitive shunts before non-inverting LS244
  `10H`; only J3-1/J3-2 are grounded, and there is no discrete signal pull.
  Complete SP-327 Hard Drivin' cockpit and SP-360 Race Drivin' compact main
  wiring diagrams show their `044427-XX` Sound PCB power/audio harnesses but
  no J3 cable or cabinet device. TM-327/TM-329 identify `A046491-01`, while
  TM-351 establishes later `A046491-02` without an assembly drawing that
  resolves J3 population. TI specifies driven LS244 thresholds/currents but
  no open-input result. Three new primary Atari documents bring the verified
  cache to 57; a documentation regression locks the evidence and policy.
  `OQ-032` is now `PARTIALLY RESOLVED_PRIMARY`: matching published cabinets
  clear the four source-valid bits rather than forcing MAME zero or an
  assumed floating-TTL high. Physical open values and other revisions remain
  unknown; no RTL/model behavior changed.
- **New program-ROM option evidence:** A044427 Rev A connects the two EPROM
  pin-1 nodes through alternative `E1` to +5 V or `E2` to local-MC68000 A16.
  AMD publication 08005 Rev A establishes that the drawn 32Kx8 27256 needs
  VPP=VCC on pin 1 for read operation, while the pin-compatible 64Kx8 27512
  uses pin 1 as its highest address input. E1 is therefore required for the
  drawing's 64-KiB combined image and E2 is the intended 128-KiB option;
  fitting both is electrically illegal. Released pinned-MAME sets declare
  0x8000-byte lanes, while the Race Drivin' Panorama prototype declares
  0x10000-byte lanes. No reviewed assembly BOM, option table, or physical
  board identifies its fitted link. A deterministic authorized-image helper
  hashes and interleaves the lanes, distinguishes information-bearing 27512
  halves, and always leaves `physical_strap_proven` false. The new AMD source
  brings the verified ignored cache to 58. `OQ-034` is
  `PARTIALLY_RESOLVED_PRIMARY`; no RTL/model behavior changed.
- **New sample-ROM population evidence:** A044427 Rev A maps A-row sockets
  `65A..5A` to blocks 0–5 and C-row sockets `65C..5C` to blocks 6–11, with
  the complete C row marked `NOT LOADED`. Atari TM-356 identifies the Race
  Drivin' deluxe-cockpit upgrade board as `A046491-02`, requires
  `136052-3125` at `45A`/block 2 when needed, and installs
  `136077-1017` at `45C`/block 8. Pinned MAME instead packs the 45C file at
  logical block 4; `SC-044` preserves that unresolved conflict. A new
  content-free helper hashes authorized 64-KiB images by physical socket and
  emits the exact sparse presence mask while always leaving
  `physical_population_proven` false. The verified cache now contains 59
  sources. `OQ-026` is `PARTIALLY_RESOLVED_PRIMARY`; no RTL changed because
  the existing wrapper already represents sparse physical blocks.
- **New mailbox byte evidence:** A044427 LS138 `20P` generates `/MAINWR`
  locally for physical alias `0x840000..0x843fff`; neither it nor local
  `/SOUNDWR` uses the available byte enables. SP-327 proves `/EWEU` and
  `/EWEL` reach the expansion connector, while Motorola Table 3-1 proves the
  original MC68000's current implementation drives the selected byte on both
  bus halves. Both LS374 pairs therefore capture `{byte, byte}`, not MAME's
  retained-other-byte merge (`SC-031`). The standalone normalizer exhausts
  all 65,536 data words in word and both byte orientations; the timed local
  board path accepts `0xab -> 0xabab` and `0x34 -> 0x3434`, sets/clears the
  mailbox flag, and passes both symbolic routing covers. TI's LS74 function
  table verifies preset dominance while asserted, but not the exact read edge
  at preset release. `OQ-031` is `PARTIALLY_RESOLVED_PRIMARY`.
- **New communication-RAM byte evidence:** A044427's common `/CRWE` and absent
  `/HEU`/`/HEL` RAM qualification combine with original-MC68000 Table 3-1 to
  establish `{byte, byte}` capture in both HM6116 banks. The timing-derived Y6
  path now reuses the write normalizer and reads back lower `0xef -> 0xefef`
  and upper `0xbc -> 0xbcbc` under CRAMEN ownership. A 7-step BMC proves the
  same write/read relationship for arbitrary addresses/data and reaches both
  symbolic byte orientations. Pinned MAME's retained-other-byte merge remains
  `SC-025`; authorized-firmware access widths and electrical/substitute-CPU
  qualification remain open. `OQ-024` is `PARTIALLY_RESOLVED_PRIMARY`.
- **New program-RAM byte evidence:** A044427's common `/RAMWR` and absent
  `/UDS`/`/LDS` slice qualification combine with original-MC68000 Table 3-1 to
  establish `{byte, byte}` capture in all four program-SRAM slices. The
  timing-derived lower-Y5 path reuses the write normalizer and reads back upper
  `0xde -> 0xdede` and lower `0xef -> 0xefef` under reset-qualified host
  ownership. A 7-step BMC proves the same write/read relationship for arbitrary
  addresses/data and reaches both symbolic byte orientations. Pinned MAME's
  retained-other-byte merge remains `SC-022`; authorized-firmware access
  widths, reset-handoff compliance, and electrical/substitute-CPU qualification
  remain open. `OQ-022` is `PARTIALLY_RESOLVED_PRIMARY`.
- **New accumulator datapath evidence:** the portable core now routes the
  common signed 32-bit ADD/SUB/SUBH/APAC/SPAC/LTA/LTD arithmetic through one
  combinational relation while leaving instruction operand selection, sticky
  OV, and the distinct ADDS/ADDH/SUBS/SUBC policies outside it. A one-step
  proof quantifies every 66-bit input combination against an independent
  signed 33-bit result and reaches positive/negative add/subtract saturation.
  All 39 directed RTL instruction tests and all 25 differential/oracle tests
  pass after integration; the complete 52-task/26-configuration formal sweep
  also passes. Yosys maps the primitive to 367 cells and reduces the direct
  pipeline to 16,183 cells/125 checks; the six-memory Driver Sound hierarchy
  is 3,752 abstract cells/410 checks. Quartus fits the explicit pipeline in
  1,332 ALMs with unchanged 400-register/one-M10K/one-DSP resources and closes
  25 MHz at +19.282 ns setup, +0.164 ns hold, and 48.27 MHz worst slow-corner
  Fmax. The current 100 °C path is 20.016 ns/13 levels from retained program
  context into ACC.
- **Unresolved issues:** PUSH/POP multicycle pipeline ownership remains absent,
  and complete fetch/execute overlap remains unqualified beyond the supported
  one-cycle, branch/call/computed-control, I/O, table, and interrupt paths;
  physical interrupt setup/synchronizer
  behavior, original-part physical confirmation of the CORROBORATED-RET/
  INFERRED-CALA discarded-`PC+1` then target sequence, unsupported PUSH/POP
  arrival cycles,
  provisional DINT-at-final-boundary ordering under `OQ-019`, remaining
  control-flow traces, LST next-ARP precedence,
  PUSH/POP per-cycle program-address/fetched-word ownership, SUBC result availability and
  OV stage, simultaneous indirect
  increment/decrement, `0x90`-`0xff` read/write/alias behavior under
  `OQ-002`/`SC-041`, physical-reset retention of unlisted state under
  `OQ-012`/`SC-042` despite CORROBORATED EVM recoverability,
  DMOV/LTD source-`0x8f` destination behavior, 68000-side reset-handoff timing
  and firmware compliance,
  program-RAM firmware access widths and reset-handoff discipline,
  communication-RAM firmware access widths, CRAMEN firmware discipline,
  HM6116 electrical timing, and substitute-68k inactive lanes, exact
  sample-ROM factory/variant population, authorized Race Drivin' port-6 block
  writes, the `SC-044` physical-block-8 versus MAME-packed-block-4 conflict,
  and absent-block electrical behavior,
  BIO power-up/reset-release phase and independent-clock coincidence,
  production Rev-A port-2 `TDI15:TDI0` electrical value,
  undriven host lanes for `/320PORT`, `/SWITCHES`, and `/READSTAT`,
  physical J3 population/field options and disconnected LS244 voltage/read
  values on `A046491-01`/`A046491-02`,
  main/sound firmware mailbox access widths, exact write-preset-release/
  opposite-read-clock behavior, and substitute-68k inactive byte lanes,
  local-68000 host-cycle TTL timing margin and unreset power-up transient,
  local-MC68000 RC tolerance/power-up behavior, main `/RESET` origin,
  main-bus peripheral response latency, exact DUART/main-clock phase and
  raw-CDC/electrical timing, platform tick calibration, and
  future-core reset CDC,
  exact local-68000 E1/E2 EPROM strap/variant population despite the now-
  verified capacity-option topology,
  authenticated original-TMS32010 errata/BBS notices, package-code decoding,
  and mask/date invariance across physical specimens under `OQ-008`/`SC-043`,
  optional `/DACR`/unlabeled write-target loading and direct-read open-bus
  policy,
  Hard Drivin' signed-audio DAC interpretation and possible unrecorded
  production MSB rework under `OQ-020`, pending walking-ones/ramp plus
  authorized normal-game captures on two documented boards, and general
  board-revision equivalence;
  the opcode audit
  still has 28,656 primary-unlisted words with unknown silicon behavior and
  372 unsupported simultaneous-update words with unknown original forced-word
  execution
- **Next task:** continue `RTL-001` by extracting the portable signed input
  shifter used by the qualified accumulator instructions and prove its exact
  width, sign-extension, and shift relation independently of instruction
  decode and timing.
- **Latest committed baseline before this cycle:**
  `4f68996`
