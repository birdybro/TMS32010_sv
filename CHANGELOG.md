# Changelog

All notable project changes are documented here. The format is based on Keep a
Changelog, and the project follows semantic versioning once releases begin.

## [Unreleased]

### Added

- ADR-0004 defining phase-staged internal-RAM reads without another TMS32010
  machine cycle, including phase-1 operand validity, phase-0 same-address
  forwarding, standalone-core compatibility, and explicit nonclaims about the
  original silicon array.
- A directed registered-RAM test and a five-step symbolic proof covering all
  144 words, both write sources, untouched-word persistence, and same-address
  forwarding while leaving initial contents arbitrary.
- A reproducible Quartus full setup-path reporter that writes twenty detailed,
  untracked paths with endpoints, logic depth, and routing/cell delay shares.
- Repository governance, build, research, model, RTL, verification, formal,
  synthesis, and integration directory framework.
- A ROM-free MAME instruction-boundary oracle adapter with strict debugger
  command generation, PC/post-state alignment, original-part width checks,
  explicit MAME stack-order normalization, deterministic diagnostics, seven
  synthetic differential regressions including exact-row and strict
  model-state validation, explicit interrupt-hook limitations, and separate
  pinned-source versus local dirty-binary provenance. It deliberately does not
  launch MAME, obtain ROMs, or claim cycle/pin evidence.
- An opt-in ROM-free MAME execution smoke using size-limited, all-zero,
  deliberately wrong-checksum placeholders; fail-closed debugger injection of
  a hand-fixed combined PUSH/POP/CALA/RET fixture; a finite-timeout live run;
  seven orchestration tests; and generated hash/result metadata. Ten model
  steps match eleven live TMS320C10 boundary rows while `/MEN`, cycle, pin,
  original-part, and Atari-firmware claims remain explicitly excluded.
- Reference-provenance policy, safe acquisition/hash tools, a 45-source
  integrity-pinned catalog, and living engineering backlog.
- Primary acquisition of Atari A044425 Rev-J supplemental Driver Main GSP and
  MSP sheets plus TI's 1988 TMS34010 User's Guide. The drawings connect each
  `/GSPWAIT`/`/MSPWAIT` net directly to its processor's `HRDY` output; TI
  qualifies high as ready, low as wait, and high whenever active-low `HCS` is
  inactive.
- Standard-library regression entrypoints and documentation consistency checks.
- Primary-cited programmer, memory, pipeline, interrupt, external-interface,
  instruction, and timing research baselines.
- Source-precedence ADR, ambiguity/conflict registers, and an initial
  schematic-led Hard Drivin' Driver Sound Board inventory.
- A provisional computed-control prefetch ADR that constrains CALA/RET RTL to
  an explicitly `INFERRED` discarded-`PC+1` read followed by selected-target
  fetch. It preserves the original every-cycle `/MEN` rule, the conflicting
  IKA idle-first sequence, and target-repeat as separate hypotheses; physical
  original-part confirmation remains open.
- CALA/RET decode and two-boundary core execution with retirement-only stack
  and PC effects, plus explicit-pipeline discarded-sequential/selected-target
  ownership under ADR-0003. Directed instruction, both-interval stall/bus,
  four-case interrupt-arrival, architectural differential, legacy-wrapper
  rejection, and 24-step bounded-formal checks preserve the mapping's
  `INFERRED` confidence and keep PUSH/POP out of RTL.
- A reproducible original-NMOS PUSH/POP pin-trace experiment, including a
  deterministic synthetic assembly image, stable opcode regression, competing
  bus hypotheses, required analyzer signals, artifact provenance, and explicit
  acceptance criteria for resolving `OQ-016`.
- Primary schematic qualification of the A044427 Rev-A TMS32010 pin paths:
  `/INT` is held inactive-high through `PR1`/`R26`, `/320BIO` is resampled by
  `CLKOUT` into `/BIOS`, and the separate `320IRQ` net belongs to the
  68000-side interrupt path.
- Primary manufacturer qualification of the A044427 DAC path using AMD's
  1983 analog-products data book, with separately pinned MAME DAC support
  sources and an explicit source-conflict record.
- Machine-readable ISA database that represents all 60 documented mnemonics;
  reserved/unmatched-word classification remains incomplete.
- Provenance-aware exhaustive opcode audit and generated count report. All
  65,536 words are partitioned into documented legal encodings, explicitly
  reserved indirect fields, unresolved simultaneous AR updates, documented-
  pattern mismatches, and encodings absent from TI's explicitly complete
  instruction summary without assigning unsupported silicon behavior.
- Structurally independent executable model with explicit-width state, raw
  image loading, logical fetch traces, deterministic JSON, and trap-on-unknown
  behavior for the initial eight-instruction slice.
- Independent hand opcode fixtures and decode/model boundary tests.
- Deterministic project-local assembler/disassembler slice with checked
  expressions, labels, origin/data/include directives, raw/hex/listing output,
  and lossless source round trips.
- A project-authored four-tap Q15 FIR program with independently fixed opcode,
  input, output, sample-history, cycle, program-fetch, and logical
  data-transaction expectations. It exercises the primary-documented
  `LTD`/`MPY` pipelined multiply/accumulate idiom without reproducing TI
  example source.
- A portable `tms32010_mister` integration layer with active-high synchronous
  reset, automatic five-machine-cycle modeled reset hold, same-clock
  program/I/O request-ready callbacks, registered phase-3 waits, native-phase
  visibility, interrupt/BIO inputs, and deterministic state/RAM debug ports.
  It contains no Atari-specific memory or peripheral behavior.
- A project-authored, ROM-free Hard Drivin' Driver Sound Board smoke program
  covering every working mapped I/O role, active-low BIO control flow, fixed
  opcodes, raw program/I/O traces, model state, and explicitly scoped MAME
  adapter expectations. Port 2 and the signed-audio DAC interpretation remain
  disclosed as unqualified rather than inferred from the fixture.
- A synthesizable, storage-free A044427 Rev-A bus decoder exposing physical
  program-RAM ownership, invalid host/running-DSP overlap, low-eight I/O
  selection, and the board's low-address TBLW/OUT alias, plus an exhaustive
  address/ownership test and standalone Yosys target.
- A synthesizable A044427 4K-by-16 same-clock program-RAM adapter with
  synchronous host/TMS reads, explicit write commits, reset-preserved
  contents, no-priority conflict rejection, complete 4,096-word host-load/TMS
  readback coverage, and a memory-retaining Yosys target.
- A partial `hard_drivin_sound_mister` top connecting the generic processor,
  board-native decoder, shared program RAM, and communication path, with
  physical I/O commit signaling, internal port-1 routing, whole-word
  communication host callbacks, and correct low-address TBLW readiness.
- Primary-transcribed Driver Sound communication-RAM and shared-address
  contract, backed by newly pinned TI LS191/LS259 component data sheets. It
  records 512-word CRAMEN ownership, read-only DSP access, port-7 load,
  every-input-read increment, and three explicit MAME abstraction conflicts.
- A standalone synthesizable Driver Sound communication path comprising a
  512-by-16 CRAMEN-selected host/DSP memory, read-only DSP port-1 view,
  shared 16-bit sound-address state, port-7 load, every-input-read increment,
  port-6 block latch, and explicit physical-state validity. Port 3 remains
  orthogonal to that address/RAM state and is modeled by its separate LS374.
- Primary-transcribed Driver Sound parallel sample-ROM wiring, backed by
  newly pinned TI LS138, LS244, and LS374 data sheets. The contract identifies
  twelve decoded 64K-byte positions, exact pre-increment addressing,
  population validity, and the physical signed-byte-left-seven TMS input
  mapping while isolating MAME's unsigned-shift discrepancy as `SC-026`.
- A synthesizable, storage-free sample-ROM adapter with explicit twelve-block
  presence metadata, exact block/address byte callback, invalid-selection
  reporting, response stalls, and schematic-accurate duplicated-sign mapping.
  The board top now routes processor port 0 internally without embedding or
  accepting any copyrighted image in the repository.
- A synthesizable raw Driver Sound DAC latch that captures uncomplemented
  `TD15:TD4` on committed port-0 writes, retains explicit validity, and emits a
  one-clock downstream commit without modeling analog conversion or promoting
  MAME's disputed bit-11 XOR into hardware.
- Primary schematic qualification of both Driver Sound LS74 halves at 100H,
  backed by the official TI SDLS119 data sheet: port 4 captures `TD0` onto Q
  and exposes complementary raw `MUTE`, while port 5 presets `320IRQ` until
  reset or a 68000-side `/IRQCLR` completion. The only drawn Rev-A mute
  consumer is explicitly not loaded, so effective audio semantics remain
  unresolved rather than being inferred from the net name.
- A synthesizable Driver Sound output-control adapter exposing raw `MUTE`, a
  one-clock mute commit, the data-independent 68000 IRQ latch, and an explicit
  future-host clear callback. The partial board top now acknowledges ports 4
  and 5 internally without relying on an unrelated external ready callback.
- Primary schematic qualification of the complete Driver Sound BIO path,
  backed by TI SDLS060/SDLS119: an LS161 pair preloads `0xce`, counts through
  `0xff`, and emits a one-1-MHz-period active-low source every 50 periods;
  board reset clears only the source LS74, and a separate CLKOUT LS74 samples
  the level. Counter power-up/reset phase and independent-clock coincidence
  remain explicit rather than being assigned emulator behavior.
- A synthesizable standalone BIO generator using two clock enables, no
  generated clocks, caller-seeded phase validity, raw-source validity, and
  sampled-pin validity. The partial board top now offers it as an explicit
  opt-in, derives CLKOUT sampling from the core phase, keeps external raw BIO
  as the default, and rejects unresolved coincident 1 MHz scheduling under
  `OQ-028`.
- Primary schematic qualification of Driver Sound port 2, backed by TI
  SLCS007K: `/CMPRD` exposes only `CMPOUT` on `TDI15`, while the optional
  microphone/LM311 source and pull-up are on a sheet explicitly marked
  `THIS SHEET NOT LOADED.` `SC-029`/`OQ-029` now prevent MAME's zero-return
  stub from being promoted into physical behavior; the wrapper retains an
  explicit external callback and the smoke zero is a named synthetic sentinel.
- Primary qualification of Driver Sound LS138 `30N` and LS259 `80R`: the
  `/LATCHES` host quadrant writes one Q selected by `A3:A1` from address bit
  `A4`, board reset clears every output, and raw Q3/Q4 are `CRAMEN` and
  `/320RES`. Host data is not incorrectly treated as latch data.
- A standalone synthesizable host-control adapter with explicit decoded
  completion, all eight raw outputs, per-bit validity, reset qualification,
  six retained checks, and exhaustive select/value verification. Full
  `/RVAS`/DTACK integration remains separate.
- An opt-in board-top host-control path that selects LS259 Q4/Q3 for
  `/320RES` and CRAMEN, exports raw and selected-control validity, preserves
  the external callbacks by default, and keeps `/IRQCLR` separate.
- Primary cross-sheet qualification of all four low 68000 host reads,
  including complete `/SOUNDRD`, partial `/320PORT`/`/SWITCHES`/`/READSTAT`
  lane maps, handshake side effects, raw status polarity, and explicit
  `OQ-030` treatment for lanes the selected target does not drive.
- A standalone synthesizable port-3 LS374 model that captures `TD7:TD0`,
  exposes it on host `D15:D8`, and separates fixed driven lanes from captured
  data validity. The board top now acknowledges `/CPORT` internally without
  inheriting external callback backpressure.
- Primary qualification of both complete-word main/sound mailbox directions,
  their LS74 `20S` pending flags, reset behavior, read-clear edges, and
  unresolved byte/coincident-strobe boundaries under `SC-031`/`OQ-031`.
- A standalone synthesizable whole-word mailbox adapter with independent data
  and flag validity, explicit conflict reporting, exhaustive bidirectional
  16-bit verification, ten retained transition checks, and a Yosys target.
- A standalone storage-free `/READSTAT` mapper preserving the raw
  `MAINFLAG`/`SOUNDFLAG`/`SOUND.TEST`/`/TIRDY` order on host `D15:D12`, fixed
  driven mask `0xf000`, independent per-source validity, and deterministic
  carrier bits that do not claim an open-bus value.
- Board-top mailbox and raw-status integration using four distinct whole-word
  completion callbacks, complete retained data/flag validity and conflict
  visibility, direct flag-to-status wiring, and explicit raw test/ready inputs
  without a 68000 bus or open-bus policy.
- A standalone storage-free `/SWITCHES` mapper preserving the non-inverting
  `J3-11/J3-9/J3-8/J3-7` order on host `D15:D12`, fixed driven lanes,
  independent connector validity, and deterministic filler outside the masks.
- A storage-free low-host-read selector and board-top composition for
  `/SOUNDRD`, `/320PORT`, `/SWITCHES`, and `/READSTAT` in primary Atari LS138
  order, forwarding exact data/driven/valid masks and one-hot target state
  without generating a bus cycle or read-clear side effect.
- Primary acquisition of Atari TM-327 third printing and Motorola M68000UM
  Ninth Edition. TM-327 identifies the published local-68000/TMS32010 Sound Board
  diagnostic roles; M68000UM supplies the processor S2-through-S7 bus-state
  and electrical timing contract used to interpret A044427.
- A pin-level host-cycle timing transcription for A044427: LS138 `30P` Y4
  qualifies `/RVF` from `/AS`, `A23`, and `A16:A14`; the shared-8-MHz F74
  chain produces one-period `RVA`/`/DTACK`; and falling-edge state holds
  `/RVAS` through the S7 read-data latch boundary. It records the lack of
  READY/retry behavior and separates the resolved logical sequence from the
  still-open electrical margin and power-up transient under `OQ-033`.
- A synthesizable standalone Driver Sound host-timing adapter with explicit
  8 MHz edge and `/AS` events, complete address/control capture, exact
  `/VPA`/`RVA`/`/DTACK`/`/RVAS`/`/RVF` outputs, global byte-write strobes,
  one-hot low-I/O selection, and qualified completion pulses. It deliberately
  has no READY input and labels deterministic initialization as FPGA-only.
- A dedicated 16-step bounded host-timing proof with explicit legal
  alternating-edge and VPA-release assumptions, exact external-equation and
  captured-state assertions, and reachable whole-word read, whole-word write,
  and fully settled CPU-space covers.
- A 12-step bounded board-hierarchy host-routing proof that symbolically
  selects all six implemented timing-derived transaction classes, holds
  contradictory explicit callbacks active, checks exact S7 stateful effects
  with the DSP paused, and reaches seven covers including both partial-byte
  orientations.
- An opt-in board-top composition of that timing path: all four masked read
  quadrants are driven during the held selection interval, and pre-edge S7
  events route `/SOUNDRD`, complete-word `/SOUNDWR`, `/LATCHES`, and
  `/IRQCLR` to their existing stateful adapters. Partial mailbox writes are
  explicitly reported and rejected under `OQ-031`; `/SPEECH` completion
  remains visible without an invented device side effect.
- Portable SystemVerilog package, exhaustive partial decoder, and
  clock-enable execution core for the fifty-eight-instruction slice.
- Directed RTL tests, exhaustive 16-bit decode-space validation, and a seeded
  512-instruction model/RTL differential trace.
- A 32-case interrupt-arrival matrix covering every represented machine cycle
  of all 15 currently supported multicycle core families, with logical bus,
  retirement, protected-instruction, dummy-fetch, stack, acknowledge, and
  vector assertions.
- A four-case native INT sampling matrix covering each modeled subphase,
  including a stalled pre-sample phase, with no early pending/cycle change and
  exact falling-boundary, protected-instruction, dummy, stack, and vector
  assertions.
- A matching 32-case explicit-pipeline interrupt-arrival matrix covering both
  execution intervals of all eleven supported two-word control families and
  IN/OUT, plus all three TBLR/TBLW intervals. It checks native strobe
  ownership, no midinstruction entry, one protected retirement, dummy
  discard, stack entry, acknowledge state, and vector capture.
- A separate four-case explicit-pipeline interrupt-arrival test covering both
  CALA and RET intervals, no midinstruction stack effect or entry, selected-
  target completion, protected retirement, dummy/vector ownership, and
  resolved return-PC stacking.
- Fetch/execute-separation ADR and a standalone synthesizable pipeline register
  with explicit word/address validity, completion, stall, and flush ownership;
  directed tests cover Figure 2-2 priming/overlap and Figure 2-12
  dummy/vector flow without claiming integrated pipeline completion.
- A core-connected sequential pipeline qualification wrapper with a distinct
  fetch address, first-fetch priming, one-cycle retirement overlap, visible
  multicycle parking, reset recovery, and full-state offset comparison across
  the existing 46-word/41-family one-cycle stream.
- Explicit unconditional-B pipeline ownership: the operand fetch is
  nonexecutable cycle 1, the redirected target fetch is cycle 2, B retains
  the execute slot until target capture, and malformed operands park before
  an unsupported speculative address.
- Explicit BANZ pipeline ownership for both old-counter outcomes: the
  nonexecutable operand selects target or fallthrough, the selected fetch is
  cycle 2, and the modulo-512 counter decrement occurs only as BANZ retires
  and captures that instruction.
- Explicit pipeline ownership for all six accumulator-conditioned branches:
  the unchanged full 32-bit ACC selects target or fallthrough after the
  nonexecutable operand fetch, and branch retirement only captures the
  selected instruction.
- Explicit BV pipeline ownership for both old-OV outcomes: the nonexecutable
  operand selects target or fallthrough, the selected fetch is cycle 2, and
  sticky OV clears only when a taken BV retires and captures that instruction.
- Explicit BIOZ pipeline ownership for both active-low pin outcomes: the raw
  input is sampled at operand completion, the selected fetch is cycle 2, and
  the resulting decision remains stable through later pin changes or stalls.
- Explicit CALL pipeline ownership: the nonexecutable operand selects the
  target fetch, CALL retires only when that word is captured, and opcode-PC+2
  is pushed at that retirement boundary.
- Explicit IN/OUT pipeline ownership from primary Figure 2-9: cycle 1 performs
  the mutually exclusive DEN/WE transfer at the encoded port, cycle 2
  prefetches PC+1 under MEN, and retirement/capture occurs only at that
  following-prefetch boundary.
- Explicit TBLR/TBLW pipeline ownership from primary Figure 2-10: cycle 1
  discards PC+1, cycle 2 transfers program space at captured `ACC[11:0]`
  under MEN or WE, and cycle 3 repeats PC+1 before architectural retirement
  and execute-slot replacement. Separate program-write direction/data outputs
  keep TBLW distinct from OUT.
- A bounded integrated-pipeline formal harness for fixed
  `LACK 4; TBLR 0; LAC 0; NOP`, checking discarded and repeated PC+1 fetches,
  ACC-addressed program transfer, RAM commit/consumption, bus exclusion, and
  arbitrary clock-enable stalls.
- A complementary bounded direct-TBLW formal harness with an explicit
  synchronous phase-3 program-memory model, checking old-word discard, exact
  WE address/data, one memory mutation, replacement refetch, and execution of
  the rewritten instruction across arbitrary clock-enable stalls.
- Explicit Figure 2-12 interrupt ownership for the qualified EINT path:
  protected execution discards N+2, entry uses an empty execute slot while
  fetching vector 2, and vector execution waits for the following interval.
- Explicit MPY/MPYK interrupt-protection extension through one additional
  instruction, with post-following dummy/return-PC ownership.
- Reproducible Yosys and Quartus synthesis projects with synchronous I/O
  constraints and partial-core synthesis qualification record.
- Primary-transcribed native timing contract for normal program reads, table
  transfers, I/O, reset, interrupt sampling, and BIO sampling.
- Standalone four-subphase program-read engine with distinct FPGA
  initialization and physical-reset controls, plus directed phase/reset/stall
  verification.
- A unified synchronous phase-pause regression comparing zero holds with 16
  host-clock holds across ordinary program reads, IN, OUT, TBLR, and TBLW. It
  checks retained controls and architectural state on every held clock, exact
  elapsed-clock extension, bounded resumption, and identical final RAM and
  program-memory results without claiming a native READY protocol.
- Primary-transcribed `LARK`, `LARP`, and `LDPK` encodings and effects across
  hand fixtures, model, assembler/disassembler, RTL, and differential traces.
- Sequential native-phase wrapper that retires the 41 supported one-cycle
  instructions on falling-edge program samples and keeps PC/native address
  aligned across clock-enable stalls, traps, and reset.
- Yosys 0.33 portable-synthesis qualification for the integrated partial core,
  with a reproducible Ubuntu 24.04 command.
- Least-privilege, immutable-action GitHub Actions jobs for documentation,
  repository/model/tool tests, Verilator regression/lint, and Yosys synthesis.
- Primary-cited `LAC` database/model/tool slice with direct and indirect
  addressing, sign-extension/shift boundaries, logical internal-data traces,
  nine-bit circular AR updates, and explicit unresolved-address traps.
- Portable 144-word internal data RAM, verification-only preload port, logical
  data-read observation interface, and full `LAC` RTL execution path.
- Directed `LAC` RTL/address/cycle tests and randomized logical-data
  transaction comparison against the independent model.
- Primary-cited `SACL` database, model, assembler/disassembler, RTL, and
  native-phase slice, including direct/indirect writes and TI's zero
  next-ARP placeholder syntax.
- Write-enabled internal RAM with logical write observation and assertions
  against invalid or simultaneous CPU/debug writes.
- Primary-cited `SACH` database, model, assembler/disassembler, RTL, and
  native-phase slice with exact 0/1/4 whole-accumulator output shifts.
- Machine-readable legal-value constraints for sparse opcode fields, used to
  reject all five undocumented SACH shift encodings.
- Primary-cited `ZALH`/`ZALS` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for high-half placement and unsigned
  low-half zero extension through the common data-address modes.
- Primary-cited `ADDS` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for unsigned-source accumulation,
  sticky overflow, wrapped `OVM=0` results, and positive `OVM=1` saturation.
- A separately acquired and hash-pinned TI SPRU032A C14/E14 guide, used only
  as explicitly scoped variant evidence for the unresolved ADDH wording.
- An explicit deterministic FPGA/test initialization path distinct from
  physical reset, plus an observable OV output for arithmetic verification.
- Primary-cited `AND`, `OR`, and `XOR` database, model,
  assembler/disassembler, RTL, native-phase, and differential support for
  low-half logic and the common direct/indirect data-address modes.
- Primary-cited `ADD` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for signed-source shifts, sticky
  overflow, wrapped results, and positive/negative OVM saturation.
- Primary-cited `SUB` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for signed-source shifts, sticky
  overflow, wrapped results, and positive/negative OVM saturation.
- Primary-cited `SUBS` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for unsigned-source subtraction,
  sticky overflow, wrapped results, and negative OVM saturation.
- Primary-cited exact `ABS=0x7f88` database, independent fixture,
  assembler/disassembler, model, RTL, native-phase, and differential support
  for ordinary negation and OVM-selected most-negative wrap/saturation while
  preserving incoming OV.
- Primary-cited `LAR` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for either auxiliary-register target,
  including TI's exceptional suppression of indirect post-modification when
  the loaded target is the selected address register.
- Primary-cited `SAR` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for either auxiliary-register source,
  including TI's exceptional post-modified same-source value written at the
  pre-modification indirect address.
- Primary-cited `MAR` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for direct NOP forms and indirect
  AR/ARP modification without a data-memory access, preserving its exact LARP
  aliases.
- Primary-cited `LDP` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for loading DP from an internal
  data-word LSB after old-DP/old-AR address selection and before ordinary
  indirect AR/ARP post-modification.
- Primary-cited `LT` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for loading all 16 bits of an
  internal data word into T through the common address/update path.
- Primary-cited `MPY` database, model, assembler/disassembler, portable
  multiplier RTL, native-phase, and differential support for signed
  16-by-16 products in P through the common address/update path.
- Primary-cited `MPYK` database, model, assembler/disassembler, RTL,
  native-phase, and differential support for signed T times a sign-extended
  13-bit immediate in P without a data-memory transaction.
- Primary-cited `PAC` database, hand fixture, model, assembler/disassembler,
  RTL, native-phase, and differential support for a full-width P-to-ACC
  transfer without changing P or arithmetic status and without a data-memory
  transaction.
- Primary-cited `APAC` database, hand fixture, model, assembler/disassembler,
  RTL, native-phase, and differential support for full-width P-plus-ACC
  arithmetic, sticky signed overflow, OVM-controlled wrap or signed-endpoint
  saturation, unchanged P, and no data-memory transaction.
- Primary-cited `SPAC` database, hand fixture, model, assembler/disassembler,
  RTL, native-phase, and differential support for full-width ACC-minus-P
  arithmetic with the same overflow/result policy, unchanged P, and no
  data-memory transaction.
- Primary-cited `LTA` database, hand fixtures, model, assembler/disassembler,
  RTL, native-phase, and differential support for simultaneous full-word T
  loading and previous-P accumulation with common data-address updates,
  sticky overflow, and OVM-controlled results.
- Primary-cited `LTD` database, hand fixtures, model, assembler/disassembler,
  RTL, native-phase, and differential support for simultaneous T loading,
  previous-P accumulation, and unchanged source-word copy to the next
  internal-RAM address.
- Separate logical source and destination RAM address diagnostics for
  dual-address instructions, with independent internal-RAM read/write
  addresses and validity assertions.
- Primary-cited `DMOV` database, hand fixtures, model,
  assembler/disassembler, RTL, native-phase, and differential support for an
  unchanged source-word copy to the next internal-RAM address without LTD's
  T-load or accumulator effects.
- Primary-cited exact `DINT=0x7f81` and `EINT=0x7f82` database entries, hand
  fixtures, model, assembler/disassembler, RTL, native-phase, and differential
  support for one-cycle `INTM` set/clear effects with no data-memory
  transaction. Directed interrupt tests additionally cover request retention,
  EINT's following-instruction service deferral, vector entry, and all
  represented supported-multicycle arrival positions; complete overlapped
  execution and physical setup/synchronizer behavior remain outside the
  qualified boundary.
- Acquired and hash-pinned TI's 1986 preliminary TMS320C25 guide as
  explicitly later-variant evidence for the otherwise unresolved indirect
  LST next-ARP precedence; it is not treated as original-part authority.
- Primary-cited `LST` opcode-family, status-field, one-cycle, and internal-read
  support across the database, hand fixtures, model, assembler/disassembler,
  RTL, native-phase integration, and differential trace. Memory-sourced ARP
  precedence over an encoded next ARP remains PROVISIONAL under
  `OQ-015`/`SC-009`.
- Primary-source `PUSH=0x7f9c` and `POP=0x7f9d` research covering their exact
  four-level stack transformations, accumulator effect, overflow/underflow
  behavior, one-word size, and two-cycle totals.
- Primary-cited `SUBC` database/model/tool/RTL/native-phase slice with hand
  fixtures, common direct/indirect addressing, both conditional result paths,
  TI's 16-step 65-divided-by-7 example, seeded direct/indirect randomized
  differential coverage, and explicit `OQ-017`/`OQ-018` limits on result
  availability and OV staging.
- Primary-cited `BANZ=0xf400` database, hand fixture, assembler/disassembler,
  independent model, two-cycle RTL state, native phase, and focused
  differential support. Taken and untaken paths both read the following
  canonical target word, test the old selected low-nine AR counter, decrement
  modulo 512 while preserving upper bits, and retire at the second sample.
- Explicit conflict records for a later TI guide's contradictory full-register
  BANZ wrap example (`SC-011`) and MAME's shortened untaken timing
  (`SC-012`), without weakening the original-part primary-backed behavior.
- Primary-cited `B=0xf900` database, hand fixture, assembler/disassembler,
  independent model, shared two-cycle RTL branch state, native phase, and
  focused differential support. It always reads a canonical following target,
  loads PC, preserves other architectural state, and retires at the second
  sample.
- Primary-cited exact `BLZ=0xfa00`, `BLEZ=0xfb00`, `BGZ=0xfc00`,
  `BGEZ=0xfd00`, `BNZ=0xfe00`, and `BZ=0xff00` support across the database,
  hand fixtures, local tools, independent model, shared two-cycle RTL state,
  native phases, and focused differential traces. Directed tests cover every
  signed/zero predicate boundary and both outcomes.
- Explicit `SC-013` record for MAME's one-cycle untaken accumulator-branch
  abstraction; project timing follows TI's unconditional two-word/two-cycle
  definitions.
- Primary-cited exact `BV=0xf500` support across the database, fixtures, local
  tools, independent model, shared two-cycle RTL state, native phases, and a
  focused differential. Both OV states read the target word; taken BV clears
  OV only at second-cycle retirement.
- Explicit `SC-014` record for MAME's one-cycle untaken BV abstraction.
- Primary-cited exact `BIOZ=0xf600` support across the database, fixtures,
  local tools, independent model, shared two-cycle RTL state, native phases,
  and a focused differential. The raw active-low BIO input is sampled live at
  the target-word falling-edge boundary, not latched with the opcode, and both
  pin states consume the mandatory target read.
- Explicit `SC-015` record for MAME's shorter untaken BIOZ abstraction and its
  abstract asserted callback polarity; project behavior follows the original
  TI pin-level and two-cycle definitions.
- Primary-cited exact `CALL=0xf800` support across the database, hand fixture,
  local tools, independent model, shared two-cycle RTL state, native phases,
  and a focused differential. CALL reads its canonical following target,
  pushes wrapped opcode-PC+2 onto the top of the four-level 12-bit stack at
  target-word retirement, shifts the older entries, and discards the old
  bottom.
- Architectural stack observation across the portable core, phase wrapper,
  synthesis harness, and differential trace, with deterministic test
  initialization kept explicitly separate from physical reset behavior.
- Primary-cited `IN`/`OUT` opcode families across the database, independent
  fixtures, local tools, model, RTL, native phases, and differential trace.
  Each performs one normal opcode read followed by one distinct I/O cycle;
  IN samples live port data under DEN into the old resolved RAM address, while
  OUT drives that RAM word under WE. Direct/indirect ordering, all eight
  ports, exact two-cycle retirement, clock-enable stalls, strobe exclusion,
  traps, and AR/ARP post-updates are automated.
- Primary-cited `TBLR`/`TBLW` opcode families across the database, independent
  fixtures, local tools, model, RTL, native phases, and differential trace.
  Each performs an opcode read, discarded PC+1 read, and ACC-addressed
  program-space transfer; directed tests cover RAM/program effects,
  self-modification, stack-bottom duplication, indirect updates, exact
  three-cycle retirement, stalls, strobe exclusion, and repeated PC+1 fetch.
- Active-low `int_i`, observable pending-latch diagnostics, and an interrupt
  entry sequencer shared by the portable core, native phase wrapper, and
  synthesis harness. It retains masked requests, honors EINT and MPY/MPYK
  deferral, dummy-fetches and stacks the return PC, applies the internal
  acknowledge effects, and selects vector 2.
- Directed model, architectural RTL, native-phase, and focused differential
  interrupt tests covering one-cycle pulses, held-low relatching, reset,
  DINT cancellation, EINT's previously-disabled qualification, multiply
  extension, two-cycle-branch completion, dummy-bus exclusion, and vector
  entry.
- A SymbiYosys actual-core interrupt harness with a 12-step BMC task over
  arbitrary clock-enable stalls and a separate non-vacuity cover task for
  EINT, protected execution, dummy entry, and vector execution.
- A second actual-core formal harness with a 14-step BMC and cover for MPYK
  extending an armed interrupt through its following instruction, followed by
  held-low request relatching after acknowledge.
- A third actual-core formal harness with a 20-step BMC and cover for
  deterministic direct data-memory MPY operands, a mixed MPY/MPYK/MPY
  deferral chain, signed product results, and final interrupt entry.
- A fourth actual-core formal harness with a 20-step BMC and cover for
  indirect `MPY *-,AR1`, old-address data ownership, low-nine-bit AR
  decrement with upper-bit preservation, ARP replacement, signed product,
  interrupt deferral, entry effects, and arbitrary clock-enable stalls.
- Primary-cited exact `RET=0x7f8d` database/fixture support, assembler and
  disassembler round trips, and directed model tests for the old-TOS PC load,
  four-level pop with old-bottom duplication, two-cycle total, state
  preservation, and protected `EINT; RET` pending-interrupt reentry.
- Primary-cited exact `PUSH=0x7f9c` and `POP=0x7f9d` database/fixture support,
  assembler/disassembler round trips, and directed model tests for low-12-bit
  push, zero-extending pop, complete four-level shifts, PC wrap, preserved
  state, repeated over-push/over-pop behavior, and two-cycle totals.
- Primary-cited exact `CALA=0x7f8c` database/fixture support, assembler and
  disassembler round trips, and directed model tests for opcode-PC+1 stack
  push, `ACC[11:0]` target selection, upper-ACC exclusion, PC wrap, nested
  old-bottom loss, state preservation, and two-cycle totals.
- Primary-cited `SUBH=0x62xx` database/fixture/tool/model/RTL/native and
  differential support for high-half subtraction, ordinary/wrapped low-half
  preservation, sticky signed overflow, both OVM wrap/saturation directions,
  common address updates, one-cycle retirement, and logical data-read traces.
  `SC-016` records the primary wording that makes full-accumulator saturation
  the exception to ordinary low-half preservation.
- Primary-cited `SST=0x7cxx` database/fixture/tool/model/RTL/native and
  differential support for forced-page-one direct addressing, indirect
  pre-update status capture and post-update AR/ARP ordering, exact one-cycle
  internal-RAM writes, all 32 combinations of defined status fields, and all
  28 legal encodings. Reserved bit 1 is stored high at CORROBORATED confidence
  under resolved `SC-008`/`OQ-003` and remains reserved to software.
- A dedicated actual-core reset regression that seeds every exposed datapath,
  address, stack, status, pending/trap, and internal-RAM category before reset,
  then checks TI-defined control effects separately from `OQ-012`'s
  provisional retention policy.
- A 10-step actual-core reset BMC/cover proving reset priority, inactive
  transactions/instruction qualification, exact documented control effects,
  and the implementation-scoped retention transition; its nonzero ACC/OVM
  cover reaches step 5.

- A storage-free local-68000 memory decoder transcribing A044427's broad
  low-ROM aliases, all eight high-bank LS138 outputs, Y5 program/direct-I/O
  split, communication/local-RAM selects, populated word-address projections,
  and local 6264 byte-lane controls. It includes exhaustive alias/control
  verification and a standalone Yosys target without embedding memory data.
- Primary research for the Driver Sound local program-memory diagnostics,
  backed by a newly pinned TI SDAS113B ALS32 data sheet, exact Rev-A equations,
  `SC-034` for physical-versus-MAME mapping differences, and `OQ-034` for the
  unqualified E1/E2/larger-EPROM production option.
- A storage-free local-memory timing bridge connecting the captured
  S2-through-S7 host state to ROM/local-SRAM callbacks, exact byte-lane S7
  commits, program/communication-RAM callbacks, and the distinct direct-TMS
  `/PWE` S6 edge. Read data carries separate driven/valid masks and an explicit
  fixed-boundary missing-response event without a READY or open-bus policy.
- An optional 8K-by-16 local SRAM built from independent byte memories and
  per-lane validity metadata. Its 8,192-clock FPGA initialization scrub never
  resets the data arrays, exposes readiness/progress, and rejects pre-ready
  writes instead of inventing known physical power-up contents.
- Primary-qualified upper-Y5 direct-I/O research and a storage-free adapter
  preserving the board's asymmetric decode: reads alias modulo four throughout
  the window, while writes select only canonical words 0-7. The adapter
  carries one-hot targets, exact S6/S7 completion classes, raw write data, and
  read driven/valid masks without assigning open-bus values.
- A one-step symbolic proof of every direct-I/O address/control/data/mask
  combination, with covers for the highest read alias, undriven port 3,
  canonical port-7 writes, and the first unselected write.
- A storage-free local-MC68000 reset-release interlock preserving separate raw
  RESET and HALT callbacks while clamping both during FPGA initialization or
  an incomplete selected internal-SRAM scrub, plus exhaustive simulation and
  one-step formal coverage of all policy inputs.
- Primary qualification of the populated A044427 local-MC68000 reset source,
  backed by the pinned TI SDLS043 LS123 data sheet: `/MRES` and decoded `/SRES`
  trigger a nominal 155.1 ms one-shot with about 2.2 ms of documented
  early-retrigger inhibit, `SOUND.RESET` holds the result directly, and
  separate 7406 branches deliver equal stable logic to RESET and HALT. A
  standalone synthesizable tick-domain reconstruction exposes both outputs,
  active hold, and trigger events without analog or real-time RTL.
- Primary qualification of the SP-327/A044427 main-side sound-reset decode.
  The new storage-free module preserves the write-only, `/AS`- and
  `/RVAS`-qualified `0x84c000..0x84ffff` mirror without inventing lower
  address or byte-strobe qualification.
- Primary qualification of SP-327's main-board `/RVAS` state chain and a
  standalone same-clock event model. It captures `/AS`, emits the one-period
  `RVA`, asserts `/RVAS` from `/RVA`, and releases only after `/DTACK` has
  sampled low then high; a missing low sample deliberately holds the bus.
- Primary qualification of SP-327's early `/RVAS0` F74 and its normal
  MC68000 phase contract. The timing adapter now represents S2 high-phase
  `/AS`, S3 asynchronous preset, common sampled-`/DTACK` release, low-phase
  immediate assertion, and active-preset priority. A composed HSBUS test adds
  zero-wait and GSP-wait traces without assigning undocumented peripheral
  semantics to the raw wait inputs.
- Primary qualification of the complete SP-327 sheet-4 combinational
  `/DTACK` cone: function-code-7 `/VPA`, ordinary `RVA`, qualified HSBUS wait,
  DUART acknowledgement, and final three-way active-low merge. The
  storage-free RTL exposes every intermediate term and adds a synthetic
  end-to-end reset-write timing composition.
- Five newly acquired and hash-pinned official TI component data sheets for
  LS20, AS00, F04, F11, and F74. The existing SDAS113B source was confirmed
  byte-identical at TI's AS32 URL and reused instead of duplicated.
- Primary qualification of the selected MC68681 acknowledgement boundary,
  backed by Motorola's exact 1985 advance-information publication and the
  official archived successor manual. SP-327 connects `/RDUART` to `CS`, uses
  the independent 3.6864 MHz crystal, and pulls active-low open-drain
  `/DUDTACK` high through 4.7 kΩ. A composed test retains arbitrary device
  wait, accepts late ACK, and checks select/release ordering without inventing
  fixed main-clock latency.
- Primary qualification of SP-327's `/AS`-enabled LS138 and both LS139
  subdecoders, backed by the newly pinned TI SDLS013A data sheet. The
  storage-free RTL exposes all active-low outputs and preserves physical
  `/DUART`, `/GSP`, and `/MSP` aliases that are broader than MAME's canonical
  software-facing handlers.
- An address-driven `hard_drivin_main_bus_control` hierarchy connecting the
  verified decoder, held-strobe state, and `/DTACK` cone. It preserves the
  explicit event-domain boundary and peripheral-owned TMS34010 `HRDY` and
  MC68681 `DTACK` inputs while exposing all raw selects and intermediate
  acknowledgement terms.

### Changed

- The explicit fetch/execute wrapper now selects a synchronous internal-RAM
  read while the standalone core retains its asynchronous default. The
  wrapper uses its existing FPGA subphases to capture the operand by phase 1;
  separately registered forwarding metadata supplies a same-address committed
  word during the following owner's phase-0 setup interval. No native strobe,
  retirement boundary, or processor cycle moves.
- Registered RAM capture now uses a distinct wrapper-subphase enable. The
  complete operand/forwarding output holds during a global pause and advances
  with phase 0 to phase 1, independently of the core's architectural execute
  pulse.
- The explicit phase wrapper now selects retained branch operands directly
  from registered pipeline state and records TBLR/TBLW direction when the
  table sequence starts. This removes a redundant wrapper decode from the
  sampled-program-data mux while preserving every tested native phase and
  retirement boundary; a prefetch assertion checks retained direction against
  the still-owned instruction.
- The common Yosys/Quartus synthesis harness now elaborates the explicit
  fetch/execute pipeline instead of the legacy fail-closed wrapper, so current
  resource and timing evidence actually includes CALA/RET. The Cyclone V
  internal target is 25 MHz, 25% above the A044427 board's documented 20 MHz
  TMS32010 clock. A rejected 50 MHz fit remains disclosed with its setup
  failure rather than being described as closure.
- `OQ-035` now separates resolved Rev-A connectivity and nominal timing from
  unresolved RC tolerance, power-up behavior, raw-input CDC, platform tick
  calibration, firmware use, and the future MC68000-core interface. `SC-035`
  records that pinned MAME pulses only RESET immediately and is not a timing
  oracle for the paired physical source.
- `SC-036` separates the physical 16 KiB `/SRES` alias window from pinned
  MAME's canonical `0x84c000..0x84c001` handler. `OQ-036` retains the unknown
  system `/RESET` driver, specialized peripheral timing, electrical timing,
  unreset power-up state, and raw CDC boundary; both discrete held-strobe
  dependencies and the complete combinational `/DTACK` cone are now
  primary-resolved. The GSP/MSP ready protocol and generic MC68681
  acknowledge contract and physical primary/peripheral address-select
  qualification are now resolved; workload phase, electrical margin, and raw
  CDC remain open.
- The opt-in board host-timing path now selects the complete local-memory
  bridge. Lower Y5 owns the existing program-RAM callback, Y6 owns the existing
  communication-RAM callback under CRAMEN, and timing-disabled operation keeps
  the original explicit callbacks. Upper-Y5 direct DSP I/O now shares the
  existing physical sample-ROM, communication, DAC, CPORT, output-control,
  block, and address consumers; active host/TMS overlap is suppressed and
  explicitly reported rather than arbitrated.
- Local Y7 storage remains an external callback by default and can now select
  the internal lane-valid SRAM explicitly. Internal selection suppresses the
  external request and write commits while retaining raw address/data
  observability; authorized ROM data remains a separate external callback.
  The board wrapper now exports separately gated local RESET/HALT signals and
  a denied-release diagnostic without changing the TMS `/320RES` path.
- The host-timing adapter now exposes its captured R/W direction alongside
  the already captured address and byte strobes, preventing downstream bank
  decode from consulting a live processor input after `/AS` assertion.
- Added pre-edge S7 completion-event outputs to the host-timing adapter so
  same-clock state consumers update on the documented trailing boundary; the
  registered one-clock completion outputs remain available for trace/debug.
- Preserved all explicit local-host callbacks as the default board-top mode
  while making timing-derived reads and side effects a separate
  `use_host_timing_i` opt-in.
- Replaced the misleading serial-ROM shorthand with parallel sample-ROM
  terminology after tracing the direct `SA15:SA0` address and `SD14:SD7` data
  wiring in A044427.
- Corrected the earlier Driver Sound port-3 conclusion after locating populated
  LS374 `50L` on A044427 sheet 4. `/CPORT` captures `TD7:TD0`, `/320PORT`
  drives those bits onto host `D15:D8`, and MAME's logging/zero-return stubs
  are now isolated as `SC-030` instead of being treated as missing hardware.
- Corrected the mailbox flag component location from LS74 `10J` to `20S` and
  separated the two-68000 word exchange from the unrelated TMS port-3 latch.
- Split deterministic FPGA initialization from an independent synchronous
  processor-reset request in `tms32010_mister`, allowing board `/320RES` to
  retain shared program contents while preserving the five-cycle reset hold.
- Defined the board adapter's host program path as whole-word only. A044427
  does not route UDS/LDS into this SRAM bank; byte-preserving MAME writes are
  now isolated as `SC-022`/`OQ-022` rather than promoted to hardware behavior.
- Clarified that the generic program/I/O qualifiers preserve architectural
  ownership while the Hard Drivin' board deliberately decodes native address
  and strobes, causing WE at addresses 0–7 to select output ports.
- Split Hard Drivin' port-0 qualification into the primary-backed raw DAC code
  `data[15:4]` and MAME's secondary `(data >> 4) XOR 0x800` transform. The
  latter is no longer described as shown board wiring because A044427 contains
  no bit-11 inverter.
- Narrowed the PUSH/POP timing gap using TI's primary pin contract: `MEN` must
  be active in both non-I/O execution cycles, but the address and fetched-word
  ownership remain unknown. Native/RTL implementation stays deferred rather
  than inventing a repeated or speculative prefetch.
- Replaced the single undifferentiated unsupported-opcode bucket with five
  evidence-scoped classifications. Only words setting TI's explicitly
  reserved indirect bits are labeled reserved; fixed-pattern mismatches and
  map gaps retain narrower or unknown labels.
- Reclassified the 28,656 remaining map gaps as
  `PRIMARY_UNLISTED_ENCODING` after locating TI's explicit statement that the
  original Table 3-2 is the complete instruction-set summary. This is a
  documentation classification only, not a reserved-behavior claim.

- Replaced the initial placeholder README with an evidence-oriented project
  overview.
- Reframed the external-wait milestone after confirming that the original
  40-pin TMS32010 has no READY/WAIT input.
- The local assembler diagnoses out-of-range `LACK` operands instead of
  reproducing the historical assembler's silent truncation.
- Quartus 17.0.2 fits the integrated fifty-six-instruction
  phase/RAM/multiplier/I/O/table/interrupt-entry slice in 2,188 ALMs/2,588
  registers and one DSP block, with +2.656 ns worst setup and +0.166 ns worst
  hold slack at 50 MHz and 57.66 MHz worst slow-corner internal Fmax; 385
  diagnostic pins are virtual, and enumerated harness I/O paths are explicitly
  excluded pending a real wrapper.
- Appendix A establishes falling `CLKOUT` as the input sampling boundary and
  resolves reset release to an address-0 fetch after one complete cycle.
- Decoder operation ports use an explicitly encoded packed vector at module
  boundaries so the same RTL elaborates in Verilator, Quartus 17.0.2, and
  Yosys 0.33; exhaustive decode tests guard the package/RTL encoding contract.
- The internal packed operation code is now six bits wide to represent the
  33rd qualified operation without aliasing an existing decode.
- Data-memory documentation now distinguishes verification-visible logical
  RAM accesses from physical pins; ordinary operands are entirely on-chip.
- Physical reset and deterministic initialization are separate controls.
  Unlisted physical-reset state receives no arbitrary assigned value, while
  its FPGA retention behavior remains provisional under OQ-012.
- The qualified model/tool/RTL boundary now covers fifty-eight of 60 documented
  mnemonics: twenty-five common-address internal-data families, SST's
  forced-page status store, two
  common-address I/O families, and two table-transfer families.
- The instruction-boundary model represents interrupt acknowledge as a
  non-instruction `INTERRUPT` step with an `interrupt_dummy_fetch`
  transaction. This preserves deterministic single stepping without claiming
  that the discarded return-PC word executed.
- The model/tool boundary contains all 60 documented instructions while
  RTL/differential covers 58. CALA/RET now use ADR-0003's explicitly
  `INFERRED` external sequence; PUSH/POP cycles are not fabricated in model
  transaction traces and remain outside RTL under `OQ-016`.
- Timing documentation now follows TI's explicit opcode-prefetch convention:
  Figure 2-9/2-10 execution cycles begin after current-opcode prefetch and end
  with next-instruction prefetch. Legacy bus-order evidence is separated from
  explicit execute-slot ownership and no longer labeled as primary proof of
  commit timing.

### Fixed

- Fixed registered internal-RAM output movement while the wrapper clock enable
  was clear. The existing table-transfer formal stall invariant found the
  defect; the read-side enable now holds captured data and forwarding metadata
  instead of weakening the invariant.
- Formal configuration discovery is now sorted and top-level-only, so direct
  SymbiYosys output left below `formal/` cannot be recursively mistaken for a
  checked-in configuration on a later `make formal` run. A repository
  regression locks this build contract.
- The ROM-free MAME runner now rejects shell-script launchers before execution,
  preventing generated provenance from hashing only `/usr/bin/mame`-style
  wrappers while omitting the actual emulator binary bytes.
- Exposed execute-slot validity/address/word and pipeline-blocked diagnostics
  through the synthesis harness after the first explicit-pipeline Quartus
  elaboration reported all four output groups unconnected. Analysis/synthesis
  now returns zero connectivity warnings and the new virtual pins have exact
  harness-only timing exclusions.
- The low-host-read selector now clamps arbitrary bits outside each selected
  source-valid mask instead of requiring unqualified storage to power up at
  zero. Raw source outputs and physical driven-lane masks remain unchanged;
  this fixes the deterministic interface carrier without inventing an
  open-bus value.
- Removed the nonphysical external-ready dependency from Driver Sound port 3
  and implemented its populated byte latch. Both OUT and low-address TBLW now
  complete against the internal no-wait target and update the masked host view
  exactly once.
- Board-top low-address `TBLW` completion now uses the selected physical I/O
  target's readiness instead of the external callback unconditionally. This
  prevents address-zero `/DACL` writes from stalling when the external port-0
  callback is unready and keeps the internal DAC latch and ordinary `OUT PA0`
  on the same qualified path.
- Corrected the synthetic Hard Drivin' port-0 response for byte `0xd5` from
  MAME's unsigned `0x6a80` to the physical schematic value `0xea80`, where
  `SD14` drives both `TDI15` and `TDI14`. The fixture now selects populated
  Hard Drivin' block 3 instead of Rev-A's unpopulated block 11.
- Reordered the project-authored Hard Drivin' smoke so port 7 qualifies the
  physically uncleared sound-address counters before the first
  communication-RAM read. The independent opcode and transaction fixture
  retains the same twelve instructions, 22 documented cycles, and final
  architectural results.
- Prevented inactive program-data pins from asserting the nonphysical
  `instruction_valid_o` qualification during initialization or recognized
  reset.
- Corrected project spelling and naming in the README.
- Corrected reset duration from five crystal clocks to five complete `CLKOUT`
  machine cycles after reviewing the Appendix A timing table.
- Rejected artificial harness I/O delay assumptions that produced hold
  violations; synthesis evidence now scopes itself to internal timing.
- Added the OV diagnostic output to the Quartus virtual-pin set after a rejected
  fit exposed an unintended physical harness pin assignment.
- Added the T diagnostic output to the Quartus SDC exclusions after rejecting
  an otherwise successful fit with 16 unconstrained output ports.
- Corrected the architecture baseline's logic-datapath description: all three
  operations combine the RAM operand with `ACC[15:0]`; `AND` clears the upper
  half, while `OR` and `XOR` preserve it.
- Held the logical next program address during the pending IN/OUT cycle; the
  native phase test exposed that the initial integration would otherwise skip
  the instruction after an I/O transfer at second-cycle retirement.
- Scoped the mutually exclusive retired/illegal invariant to initialized,
  non-reset operation after the first bounded run correctly exposed
  unconstrained physical power-up state at the pre-initialization edge.

### Verified

- The complete repository gates pass with 131 provenance/document/tool tests,
  232 model/unit tests, 39 instruction/decode RTL tests, 56 bus/integration
  tests, 5 interrupt RTL tests, and 25 differential/oracle tests. Verilator lint
  checks 39 modules; all 46 formal jobs from 23 configurations pass; all 29
  Yosys targets synthesize; and all 45 acquired reference hashes verify.
- Quartus 17.0.2 fits the fifty-eight-instruction explicit-pipeline hierarchy
  on `5CSEBA6U23I7` in 1,416 ALMs, 417 registers, one 144-by-16 M10K, and one
  DSP block. TimeQuest closes the 25 MHz internal constraint with +15.331 ns
  worst setup and +0.164 ns worst hold slack, 40.54 MHz worst slow-corner Fmax, and
  zero unconstrained categories across 415 explicitly virtual/false-pathed
  harness pins. The three remaining full-flow warnings are harness-only pin/
  Lite-license notices; analysis/synthesis and TimeQuest each report zero
  warnings. The detailed 100 °C critical path improves from the original
  33.464 ns/26 levels through 29.180 ns/19 levels to 24.217 ns/16 levels.
- Yosys 0.67+111 reports 17,017 cells/125 checks for the synthesis harness,
  16,923 cells/125 checks for the direct pipeline, and 16,972 cells/132 checks for the generic
  MiSTer adapter, all with clean structural checks. The generic count grows
  while Cyclone V ALMs fall, so neither representation is reported as a proxy
  for the other.
- The address-driven bus-control regression reaches a mirrored GSP access,
  canonical MSP access with arbitrary external wait, mirrored DUART access
  with late external acknowledge, and ordinary expansion-bus `RVA`
  acknowledgement through their complete held-strobe release sequences.
  Hierarchical Yosys synthesis reports 185 cells/64 retained checks, no
  memory, latch, generated clock, or structural problem; its three constituent
  blocks retain their separately bounded formal evidence.
- The main address-decode regression exhausts all 1,024 `A23:A14` values
  across both `/AS` and `/RVAS0` levels, then directs canonical and physically
  mirrored DUART, RAM, GSP, and MSP selections. Its one-step BMC proves the
  LS138 and named LS139 equations and reaches six covers. Yosys reports 49
  cells/20 retained checks with no memory, latch, generated clock, or
  structural problem.
- The `/DTACK` decode regression exhausts all 4,096 raw input combinations;
  its one-step BMC proves every intermediate/final equation and six covers
  reach ordinary ACK, CPU-space VPA, both HSBUS wait states, and both DUART
  acknowledgement states. The composed bus test checks `/AS` capture,
  `RVA`/`/DTACK` assertion, held `/RVAS`/`/SRES`, and sampled release. Yosys
  reports 21 cells/eight checks with no storage or structural problem.
- The main held-strobe timing regression covers normal S2/S3 `/RVAS0`, S4
  `RVA`/`/RVAS`, low-phase immediate preset, preset-over-release priority,
  continued hold when `/DTACK` never samples low, later recovery, and FPGA
  reinitialization. Its independent 12-step BMC passes; 16-step cover reaches
  seven timing classes. The HSBUS composition additionally checks early
  zero-wait ACK, independent active-low GSP and MSP wait extensions,
  raw-select deassertion, and delayed sampled release. Yosys reports 93
  cells/25 retained checks with no memory, latch, generated clock, or
  structural problem. The DUART composition separately checks `/RVAS`
  selection, externally delayed `/DUDTACK`, MC68681-CS removal while its
  open-drain pin remains low, and the later sampled hold release.
- The main sound-reset decode regression exhausts all 1,024 `A23:A14` values
  across eight strobe/direction combinations. Its one-step BMC passes and four
  covers reach a canonical write, read isolation, inactive `/RVAS`, and a
  nonexternal address. Yosys reports 16 cells/four retained checks with no
  memory or latch.
- The reset-source regression covers deterministic startup, exact six-tick
  release, paused ticks, direct `SOUND.RESET`, both falling-edge trigger
  sources, held-low behavior, an early ignored retrigger, and a post-inhibit
  accepted retrigger. Its independent hold/inhibit-counter BMC passes 10 steps
  and its 14-step cover run reaches release, both accepted trigger sources, an
  ignored trigger, and direct reset. Default-parameter Yosys reports 28 cells/
  seven retained checks with no memory, latch, or generated clock.
- The local-reset policy passes all 32 initialization/RESET/HALT/selection/
  readiness combinations, and board simulation proves an actual sequential
  scrub clamps both processor inputs until validity address `0x1fff` clears.
  Its one-step BMC and four covers pass; standalone Yosys reports 13 cells/
  seven checks, and the six-memory board hierarchy reports 3,809 cells/406
  checks with no structural problem. The updated board-routing proof passes.
- The direct-I/O decoder passes exhaustive simulation across all 4,096 read
  aliases and all 4,096 write addresses plus a one-step symbolic BMC over
  arbitrary masks and data. Board simulation proves canonical address/block,
  DAC, and CPORT writes at S6; complete sample-ROM and one-bit comparator read
  carriers; the undriven port-3 alias; noncanonical-write isolation; and the
  shared-address S7 increment. Standalone Yosys reports 336 cells/seven checks,
  while the six-memory board hierarchy reports 3,560 cells/374 checks with no
  structural problem. The updated 12-step board-routing BMC/cover also passes.
- The standalone local SRAM checks exactly 8,192 metadata-scrub clocks,
  blocked pre-ready writes, every invalid word, independent upper/lower byte
  validity, all 8,192 complete-word writes and reads, and reinitialization.
  Yosys retains three memories at 88 abstract cells/nine checks with no latch
  or structural problem. Board simulation proves internal/external callback
  isolation, an invalid unwritten read, and independent byte writes composing
  `0x5aa7`; the board hierarchy retains six memories at 3,424 cells/362 checks.
  The existing 12-step routing BMC and all seven covers still pass with the
  internal SRAM disabled in that proof. The complete regression passes
  127 repository/tool, 231 model/unit, 38 instruction RTL, 43 bus/wrapper,
  five interrupt, and ten differential tests; strict lint covers 31 modules,
  all 21 Yosys targets pass, all 33 hashes verify, and all 28 formal tasks
  from fourteen configurations pass.
- Board-level synthetic host cycles now cover mirrored valid ROM data,
  lane-valid local SRAM and an upper-byte S7 write, lower-Y5 program-RAM
  write/readback, upper-Y5 direct-I/O S6 commit and storage isolation, and Y6
  communication-RAM write/readback under CRAMEN. Opposite explicit callback
  sentinels prove opt-in selection, while later regression phases prove the
  timing-disabled fallback. Partial lower-Y5 and Y6 writes are separately
  reported and leave their FPGA memories unchanged. At that checkpoint Yosys
  retained three memories at 3,294 abstract cells/338 checks with zero
  structural problems; the existing
  12-step board-routing BMC/cover remains passing after composition.
- Arbitrary nonzero invalid bits for all four low-read sources are masked at
  the composition boundary. The dedicated board BMC passes solver steps 0–11
  and all seven read/write/latch/speech/IRQ routing covers reach solver step 10,
  including both partial-byte orientations.
  Standalone selector synthesis reports 72 cells/13 checks and the board
  hierarchy reports 2,966 cells/257 checks with three memories and no
  structural problems.
- Invalid low-read selection, exact `00/01/10/11` Atari target order, every
  physically driven lane, distinct source masks, one-hot visibility, live
  board source transitions, MAME-swapped quadrant discrimination, and
  `/SOUNDRD` selection without implicit `MAINFLAG` clear. Standalone Yosys
  reports 68 cells/13 checks; integrated synthesis retains three memories at
  2,737 cells/216 checks with zero structural problems. The full regression
  passes 125 repository/tool, 231 model/unit, 38 instruction RTL, 39
  bus/wrapper, 5 interrupt, and 10 differential tests; strict lint, all
  seventeen Yosys targets, all 30 hashes, and all 24 formal tasks pass.

- All sixteen raw `/SWITCHES` connector nibbles against all sixteen validity
  masks, including exact connector-to-lane order, non-inversion, invalid-source
  clamping, fixed driven lanes, per-bit validity, and low-lane filler
  separation. Standalone Yosys reports 10 cells/six checks, no storage/latch,
  and zero structural problems. The full regression passes 125
  repository/tool, 231 model/unit, 38 instruction RTL, 38 bus/wrapper, 5
  interrupt, and 10 differential tests; strict lint, all sixteen Yosys
  targets, all 30 hashes, and all 24 formal tasks pass.

- Integrated nominal main-to-sound and sound-to-main word exchange, exact
  flag set/read-clear and raw-status mapping, both coincident write/read
  conflicts, independent flag invalidity/requalification, external
  test/ready validity masking, and board-reset flag clear with both LS374
  words preserved. Pre-technology board synthesis retains three memories and
  reports 2,644 cells/194 checks with zero structural problems. The full
  regression passes 125 repository/tool, 231 model/unit, 38 instruction RTL,
  37 bus/wrapper, 5 interrupt, and 10 differential tests; strict lint, all
  fifteen Yosys targets, all 30 hashes, and all 24 formal tasks pass.

- All sixteen `/READSTAT` source nibbles against all sixteen source-validity
  masks, including exact raw polarity, invalid-source clamping, constant
  driven lanes, per-lane validity, and low-lane filler separation. Standalone
  Yosys reports 23 cells/eight checks, no storage/latch, and zero structural
  problems. The full regression passes 125 repository/tool, 231 model/unit,
  38 instruction RTL, 37 bus/wrapper, 5 interrupt, and 10 differential tests;
  strict lint, all fifteen Yosys targets, all 30 hashes, and all 24 formal
  tasks pass.

- Both main/sound mailbox directions over all 65,536 possible complete words,
  nominal flag set/read-clear, uncommitted retention, reset-preserved data,
  reset-qualified flags, simultaneous write/read and reset/write invalidity,
  and later read/write/reset requalification. Standalone Yosys reports 259
  cells, ten checks, no memory/latch, and zero structural problems. The full
  regression passes 124 repository/tool, 231 model/unit, 38 instruction RTL,
  36 bus/wrapper, 5 interrupt, and 10 differential tests; strict lint, all
  fourteen Yosys targets, all 30 hashes, and all 24 formal tasks pass.

- All eight LS259 selections, both A4 values, uncommitted retention, per-bit
  validity, two complete alternating patterns, board-reset qualification, and
  reset-over-write priority. Standalone Yosys reports 53 cells, six checks,
  no memory/latch, and zero structural problems. The complete regression
  passes 123 repository/tool, 231 model/unit, 38 instruction RTL, 35
  bus/wrapper, 5 interrupt, and 10 differential tests; strict lint, all thirteen
  Yosys targets, and all 24 tasks from twelve formal configurations pass.

- Exhaustive port-3 LS374 coverage over all 65,536 TMS words, every non-target
  port, direction/commit isolation, persistence, invalid FPGA startup state,
  and fixed driven/valid masks. Integrated OUT and low-address TBLW captures
  produce masked host carriers `0xa500` and `0x3000` under forced external
  backpressure; board reset preserves the unreset latch and program RAM stays
  unchanged. Standalone Yosys reports 19 cells/five checks, while the board
  hierarchy reports 2,495 cells/171 checks/three memories with zero problems.

- Opt-in Q4/Q3 board control with opposite-valued external callback sentinels:
  board reset qualifies all raw outputs, Q4 enables a safe synthetic
  program-RAM handoff, Q3 loads and releases communication RAM, the DSP
  executes `LACK 0x5a; NOP` in two instruction cycles, and a later Q4 reset/Q3
  host read returns preserved word `0x1357`. Integrated Yosys reports 2,495
  cells, 171 retained checks, three memories, and zero structural problems.

- The A044427 cross-sheet port-2 trace from LS139 decode through LS244 `10H`
  to `TDI15`, the absent compare-target connections to `TDI14:TDI0`, the
  optional LM311 open-collector polarity, and Rev-A's explicit nonpopulation
  notice. All 30 cached references pass pinned SHA-256 verification. This is
  source qualification, not a physical read-word measurement.

- Board-level BIO selection with an external-high sentinel and a generated,
  qualified low: BIOZ takes only target `LACK 0x22`, consumes three total
  instruction cycles with that target, and sees source release only after a
  later modeled CLKOUT sample. The partial board hierarchy synthesizes to
  2,495 abstract cells, 171 checks, and three retained memories with zero
  structural problems.

- The complete fifty-state BIO divider sequence, one-source-period low pulse,
  five nominal CLKOUT samples, reset-only source clear, counter continuity,
  unchanged reset-release phase, invalid-seed self-qualification, and
  resampler validity across all 256 possible seed values. Standalone Yosys
  reports 52 cells, seven checks, no
  memory/latch, and zero structural problems.

- Exhaustive standalone output-control coverage across all 65,536 port-4
  words and all 65,536 port-5 words, plus reset, retention, port isolation,
  host clear, and set-over-clear priority. Integrated smoke proves raw MUTE
  capture, data-independent IRQ assertion, host clear, and reset restoration
  while external readiness remains low. Yosys reports 33 cells/four checks for
  the standalone path and 2,495 cells/171 checks/three memories for the partial
  board hierarchy, with zero structural problems.

- Exhaustive raw-DAC coverage across all 65,536 TMS output words, every
  low-nibble alias, ports 1-7, input-side commits, no-commit retention, and
  FPGA validity. Yosys reports 14 cells, two checks, no memory/latch, and zero
  structural problems.
- Integrated port-0 output readiness independent of the external callback,
  exactly one `0xf230` to raw `0xf23` capture, and no `0x723` MAME transform.
  A separate five-cycle `LACK 0; TBLW 0x11; NOP` execution captures internal
  word `0x00a5` as raw code `0x00a` through the same target while a host
  readback proves program word zero remains `0x7e00`.
  The board hierarchy passes Yosys at 2,495 abstract cells/171 checks with its
  same three memories.
- Exhaustive standalone sample-ROM coverage across all sixteen block values,
  all 65,536 pre-increment addresses, all 256 bytes, validity/presence cases,
  response readiness, and non-port-0 isolation. Yosys reports 18 abstract
  cells, three retained checks, no memory/latch, and zero structural problems.
- Integrated port-0 ownership through a three-clock byte-response stall at
  block 3/address `0x3457`, exact synthetic `0xd5` to `0xea80` mapping, one
  commit, external-sentinel rejection, and shared-counter advance. The board
  hierarchy retains three memories and, with the raw DAC latch, passes Yosys
  at 2,495 abstract cells with 171 checks and zero structural problems.
- A documentation/model-fixture invariant independently derives physical
  sound-ROM words as `{{2{byte[7]}}, byte[6:0], 7'b0}`, preserves the distinct
  pinned-MAME oracle value, and rejects absent-block behavior as unverified.
- Complete host loading and exact DSP port-1 readback across all 512
  communication words; both CRAMEN ownership states, blocked non-owner
  accesses, owner-tagged synchronous responses, port-2 increment, 16-bit
  wrap, port-7 load, port-6 low-nibble latch, port-3 address-state isolation, invalid
  preload state, and initialization-time memory retention. Pre-technology
  Yosys retains one 512-by-16 memory in an 82-cell hierarchy with seven checks
  and zero structural problems.
- All 29 acquired reference files match their pinned SHA-256 values, including
  the official TI-hosted LS74, LS138, LS161, LS191, LS244, LS259, and LS374
  data sheets.
- End-to-end RTL host loading and safe reset handoff for the ROM-free Driver
  Sound smoke: the host preloads communication word `0x056`, port 7 first
  qualifies the address chain, internal port 1 ignores an external sentinel,
  and three reads advance `0x3456` to `0x3459`. The run still produces 12
  retirements, 22 cycles, six writes, three reads, active-low BIOZ branch,
  final ACC `0x000055aa`, and raw DAC word `0xf230`. A reset/CRAMEN host read
  proves retention. A second
  reset/reload executes LACK/TBLW/NOP in five cycles and proves low-address
  TBLW commits once to port 3 while RAM word 3 remains `0x7f83`.
- The partial board hierarchy passes pre-technology Yosys with 2,495 abstract
  cells, 171 retained checks, three memory objects, and zero structural errors.
- Complete host loading, synchronous TMS readback, and address identity across
  all 4,096 shared program words; contents survive adapter initialization,
  legal high-address TMS writes commit, low-eight writes remain I/O, and
  simultaneous host/running-DSP write attempts grant neither side. Yosys
  retains one 4,096-by-16 memory with a registered read port and merged write
  port in an 85-cell hierarchy with zero structural problems.
- A044427's complete 4,096-address combinational target decode and four-state
  host/DSP ownership truth table. Every MEN read selects 4K-by-16 program RAM;
  DEN reaches only input ports 0–7; WE reaches output ports 0–7 or program RAM
  at addresses 8–4095. Yosys 0.67+111 reports 15 combinational cells and zero
  structural problems for the standalone decoder.
- A044427 Rev-A `/DACL` latches `TD15:TD4` directly onto Am6012 `B1:B12` and
  omits `TD3:TD0`; AMD identifies those pins as uncomplemented straight-binary
  MSB-to-LSB inputs. The smoke fixture independently fixes raw physical code
  `0xf23` and MAME's conflicting derived value `0x723` for input `0xf230`.
- The synthetic Hard Drivin' source/image/tool/model workflow: twelve executed
  instructions consume 22 documented cycles, BIOZ skips the sentinel word,
  nine raw I/O transactions occur in exact order, host/sound-ROM words land in
  internal RAM, and all six output ports retain their expected words. This is
  model-level integration evidence, not game-ROM or physical-board evidence.
- Generic wrapper integration with registered program and I/O responders,
  delayed readiness, a separate three-clock global pause, exact-once OUT/IN
  and TBLW commits, documented `1/1/2/2/1/3/1 = 11` cycle total, unsupported-
  word parking, and reset recovery. Yosys 0.67+111 independently synthesizes
  the wrapper top to 15,782 generic cells with 110 retained checks and zero
  structural problems.
- Complete local assembler/disassembler acceptance across all sixty documented
  mnemonics and the first realistic test-program workflow. The synthetic FIR
  image round-trips exactly, executes twelve one-cycle instructions, sums four
  signed products to ACC `0x0d000000`, stores Q15 `0x1a00`, advances three
  history words, and matches every logical program/data transaction.
- The platform-only `clock_enable_i` phase-pause contract across every
  currently represented external transaction class. The complete native
  bus/phase suite now passes 24 tests. The 40-step program-bus BMC also proves
  held `CLKOUT` and conditionally held `MEN` when its wrapper-owned read
  qualifier is stable. Unbounded liveness remains outside this evidence.
- Original SPRU001B electrical timing resolves `OQ-001`: a TMS32010-20
  external master clock must remain within 48.78–150 ns with each pulse at
  47.5–52.5% of the period. Since `CLKOUT` divides by four, the corresponding
  physical machine-cycle envelope is 195.12–600 ns. This permits bounded
  slowing but not an indefinite pin-compatible phase stop; the RTL pause stays
  explicitly platform-only.
- Original status-word evidence now separates the five architectural fields
  from the 16-bit LST/SST representation. SPRU001B agrees that SST bits 12:9
  and 7:2 are ones and LST ignores every non-field source bit; model tests
  exercise every ignored position and RTL checks the complete `0x1efe`
  constant mask. Only stored bit 1 remains CORROBORATED under `SC-008` rather
  than being promoted beyond the conflicting primary figures.
- All 65,536 partial-RTL decoder inputs match a compact family/field-validity
  predicate in a one-step symbolic proof. Operand projections and operation
  bounds hold, eight classification covers reach step 0, and deferred
  CALA/RET/PUSH/POP words remain invalid. Database/fixture authority,
  execution, timing, and unsupported-silicon behavior are explicitly outside
  this proof.
- Standalone 144-word internal RAM passes a six-step base case and temporal
  induction over a symbolic qualified word, arbitrary initial contents, and
  arbitrary legal CPU/debug writes. Both read-after-write paths, non-target
  preservation, all 256 address-valid results, and invalid-read-zero policy
  hold; five covers reach words `0x00`/`0x8f`, non-target writes, and invalid
  `0x90`/`0xff`. This does not resolve original-silicon `OQ-002` behavior.
- All 2^32 standalone multiplier input pairs in a one-step symbolic proof.
  Ordinary pairs equal the explicitly sign-extended signed product; equal
  `0x8000` operands uniquely select the documented `0xc0000000` exception.
  Commutativity and zero/unity identities also hold, with four independent
  boundary covers reached at step 0. Instruction sequencing, physical timing,
  and technology mapping remain outside this proof.
- A 40-step bounded proof over the standalone native program bus leaves
  logical reset, clock enable, read qualification, and next address arbitrary.
  It proves boundary-only reset recognition without premature read abort,
  inactive address zero, the complete release-wait cycle, first-read
  activation, `CLKOUT`/`MEN`/sample relationships, and stall behavior. Its
  five-cycle reset/address-0/address-1 cover reaches step 34; electrical and
  original-silicon qualification are explicitly excluded.
- Recognized core reset clears PC, pending interrupt, trap state, and cycle
  count, sets INTM, suppresses all transaction classes, overrides a disabled
  clock enable, and preserves OVM. Directed testing also guards the explicitly
  provisional retention implementation for all other exposed state and RAM;
  it is not evidence of original-silicon reset values.
- Yosys 0.67+111 reports zero structural problems after the reset change:
  13,877 generic cells/26 checks for the legacy phase harness and 15,733
  cells/103 checks for the explicit sequential pipeline harness.
- Cross-checked SPRU001B's every-machine-cycle `MEN` rule with SPRU013's
  program-counter/stack description and PUSH/POP Execution blocks. Pinned
  IKA32010 instead suppresses its first PUSH/POP bus microcycle, now preserved
  as secondary-source conflict `SC-018`, not used as silicon proof.
- Exhaustively classified all 65,536 instruction words with stable counts:
  21,895 documented legal, 10,976 primary-reserved indirect-field, 372
  unresolved simultaneous-update, 3,637 documented-pattern mismatch, and
  28,656 primary-unlisted. Boundary tests distinguish legal ADD, reserved
  indirect ADD, ambiguous update, unsupported SACH/SST/branch fields, and an
  unlisted fixed-control gap.
- Corroborated original-guide instruction-set completeness against SPRU013's
  independently complete first-generation summary and individual-description
  contract. All 28,656 no-pattern words can therefore be called primary-
  unlisted while their silicon behavior remains UNKNOWN.

- Original-part `ADDH=0x60xx` encoding, one-cycle/common-address behavior,
  modulo high-half result, and unconditional low-half preservation through
  hand fixtures, model/tool, exhaustive decode, directed RTL, native-phase,
  pipeline-offset, and seeded differential tests. OV preservation and OVM
  independence remain CORROBORATED—not silicon-verified—under resolved
  `SC-017`/`OQ-011`.

- Existing repository is on `main` with a clean initial commit.
- Eight repository/provenance tests pass; all 14 cached initial sources match
  their recorded SHA-256 values.
- Initial encodings for `LACK`, `NOP`, `ZAC`, `ROVM`, and `SOVM` are
  transcribed from TI SPRU001B; database collision, fixture, and directed model
  tests pass over the supported boundary.
- `LARK`, `LARP`, and `LDPK` immediate boundaries and AR/ARP/DP effects agree
  between independent model and RTL paths across the seeded mixed trace.
- Native phase integration test proves address-0 startup, sequential sampling,
  same-boundary retirement, phase stalls, trap hold, and reset realignment for
  the supported subset.
- Yosys 0.33 parses, checks, and synthesizes the integrated partial hierarchy
  without structural-check failures or inferred latches; Quartus still passes
  full fit and timing after the portability changes.
- CI policy regression checks enforce immutable action references,
  read-only repository permissions, required build commands, and exclusion of
  the ignored reference cache.
- Hand fixtures and directed tests verify legal `LAC` direct/indirect words,
  negative and boundary shifts, DP/ARP addressing, post-access AR updates,
  lossless noncanonical aliases, and rejection of reserved controls.
- RTL tests verify `LAC` sign extension and all documented shift extremes,
  direct page boundaries, pre-modification indirect reads, low-nine-bit AR
  wrap, ARP update/preserve behavior, one-cycle retirement, and trapping of
  unresolved RAM addresses.
- The 512-instruction seeded differential now compares internal `LAC`
  address/read/data traces as well as all qualified architectural state.
- Yosys 0.33 synthesizes the RAM-integrated hierarchy with zero structural
  check failures or inferred latches; Quartus 17.0.2 reports zero unconstrained
  timing categories after explicit harness exclusions and positive setup/hold
  slack at 50 MHz.
- Hand fixtures and directed tests verify `SACL` direct/page-one writes,
  low-word selection with full-ACC preservation, indirect pre-modification
  addresses, counter wrap, ARP update/preserve, invalid-address traps, and
  one-cycle retirement.
- The seeded differential compares every logical SACL write
  and all 144 final RAM words after 512 steps.
- Hand fixtures and directed tests verify all three documented `SACH` shifts,
  cross-half bit transfer, direct/indirect writes, accumulator/status
  preservation, both data pages, unresolved-address trapping, post-access
  AR/ARP updates, and one-cycle retirement.
- The seeded differential compares logical SACH writes and
  all final RAM words; undocumented shifts 2, 3, 5, 6, and 7 fail decode.
- The prior SACH synthesis checkpoint produced 7,844 Yosys generic cells with
  eight assertions, zero latches, and clean pre/post checks.
- Hand fixtures and directed tests verify `ZALH`/`ZALS` direct and indirect
  reads, both data pages, high/low accumulator placement, zero extension,
  accumulator/status effects, post-access AR/ARP updates, unresolved-address
  traps, and one-cycle retirement.
- The seeded 512-step differential and native-phase integration compare both
  zero-load read directions and results without changing the ordinary external
  program-fetch sequence.
- Directed model/RTL tests verify ADDS unsigned interpretation, positive
  overflow boundary, sticky OV, OVM-clear wrap, OVM-set saturation, direct and
  indirect addressing, both data pages, counter/ARP updates, unresolved-address
  traps, one-cycle timing, and native program-fetch coexistence.
- The seeded 512-step differential now compares OV in addition to ACC/OVM and
  includes deterministic ADDS overflow plus randomized common-address cases.
- Hand fixtures and directed model/RTL tests verify `AND`, `OR`, and `XOR`
  direct/indirect reads, both data pages, distinct accumulator upper-half
  effects, unchanged sticky OV/OVM, AR/ARP post-modification,
  unresolved-address traps, and one-cycle retirement.
- The seeded 512-step differential and native-phase integration now include
  deterministic and randomized logic operations with logical read-transaction
  comparison.
- Directed model/RTL tests verify ADD sign extension and shifts,
  positive/negative wrap, positive/negative OVM saturation, sticky OV, direct/page-one and
  indirect addressing, AR/ARP post-modification, one-cycle timing, native
  program-fetch coexistence, and unresolved-address trapping.
- The seeded 512-step differential now includes deterministic and randomized
  shifted ADD operations with data-read transaction comparison.
- Directed model/RTL tests verify SUB against TI's worked subtraction example,
  negative-source sign extension, shifts, positive/negative wrap,
  positive/negative OVM saturation, sticky OV, direct/page-one and indirect
  addressing, AR/ARP post-modification, one-cycle timing, native
  program-fetch coexistence, and unresolved-address trapping.
- The seeded 512-step differential includes deterministic and randomized
  shifted SUB operations with data-read transaction comparison.
- Directed model/RTL tests verify SUBS against TI's unsigned-source worked
  example, distinguish it from sign-extending SUB, cover negative wrap and
  saturation, sticky OV, the unreachable positive-overflow boundary,
  direct/page-one and indirect addressing, AR/ARP post-modification,
  one-cycle timing, native fetch coexistence, and unresolved-address trapping.
- The seeded 512-step differential includes deterministic and randomized SUBS
  operations with data-read transaction comparison.
- All 16 acquired reference files match their manifest SHA-256 values.
- Atari drawing A044427 identifies a physical TMS32010 with a 20 MHz crystal;
  MAME's C10 device selection is recorded as a secondary-source conflict.
- Original TI pages and the later C14/E14 variant page were compared directly
  with pinned MAME for `ABS`. SPRU013's instruction-format rule makes the
  original page's absent status annotation meaningful, while the later
  variant explicitly adds an OV effect; `SC-007` records the scoped variant
  difference and `OQ-013` is resolved with `CORROBORATED` original-part OV
  preservation.
- Directed ABS model/RTL tests cover zero, positive, ordinary negative, and
  most-negative accumulator values under both OVM modes and both incoming OV
  values. Exact one-cycle program-only timing, exhaustive decode, implied
  assembler/disassembler round trips, seeded differential inclusion, and
  native/explicit-pipeline state preservation are checked automatically.
- Hand fixtures and directed model/RTL tests verify both `LAR` targets,
  direct/page-one and indirect reads, status preservation, unresolved-address
  traps, reserved target rejection, ARP replacement, and the selected-target
  post-modification exception.
- The seeded 512-step differential and native-phase integration compare `LAR`
  read transactions, loaded auxiliary-register values, both update-ordering
  cases, and one-cycle retirement without changing the external program-read
  sequence.
- Yosys 0.67+111 synthesizes the fifty-six-instruction hierarchy and partial
  interrupt-entry sequencer to 13,866 generic cells with 26 retained checks,
  zero latches, and clean pre/post checks;
  Quartus 17.0.2 completes analysis, fit, and TimeQuest with zero errors and
  three scoped harness warnings.
- Hand fixtures and directed model/RTL tests verify both `SAR` sources,
  direct/page-one and indirect writes, all 16 source bits, status preservation,
  unresolved-address traps, reserved source rejection, ARP replacement, and
  low-nine-bit counter wrap.
- The primary SAR warning case is automated in both directions: same-source
  `*+`/`*-` writes the post-modified value at the old address, while an
  other-source store writes that source unchanged and modifies only the
  selected address AR.
- The seeded 512-step differential, final 144-word RAM comparison, and native
  phase integration include deterministic and randomized SAR writes without
  changing the external program-read sequence.
- Four hand fixtures and exhaustive decode checks verify all 140 legal SUBC
  words without collisions. Directed model/RTL tests cover both conditional
  paths, unsigned operand alignment, address/update order, sticky-OV
  boundaries, OVM independence, unresolved-address trapping, and the legally
  scheduled 65/7 divide; native-phase and 512-step differential tests cover
  its logical read and one-cycle retirement, including 16 seeded-random
  SUBC/NOP pairs.
- Exhaustive decode verifies all 128 direct MAR NOP encodings. Hand fixtures
  and directed model/RTL tests verify representative direct forms, indirect
  increment/decrement and ARP replacement/preservation, low-nine-bit wrap,
  reserved-control traps, and canonical `LARP` decoding for alias words
  `0x6880`/`0x6881`.
- Model, RTL, native-phase, and seeded differential tests verify that MAR
  produces no logical data-memory read or write while preserving the ordinary
  one-cycle external program-fetch sequence.
- Hand fixtures and directed model/RTL tests verify both LDP source-bit values,
  old-DP direct address selection, indirect old-AR reads, AR/ARP post-update
  ordering, arithmetic-state preservation, one-cycle retirement, and
  unresolved-address/reserved-control traps.
- The seeded 512-step differential and native-phase integration compare LDP's
  logical data read, DP result, indirect updates, and unchanged external
  program-read sequence.
- Hand fixtures and directed model/RTL tests verify LT full-width loads,
  old-DP direct selection, indirect old-AR reads, low-nine-bit counter wrap,
  ARP replacement, status preservation, one-cycle retirement, and
  unresolved-address/reserved-control traps.
- The seeded 512-step differential now compares T on every boundary and
  includes deterministic/randomized LT reads; native-phase integration
  verifies that LT retains the normal external program-read sequence.
- Directed model/RTL tests verify signed MPY zero, sign, and extremal
  boundaries, direct/page-one and indirect reads, T/ACC/status preservation,
  AR/ARP post-update ordering, unresolved/reserved traps, and one-cycle
  retirement.
- The model and RTL both reproduce TI's documented original-multiplier
  exception `0x8000 * 0x8000 -> 0xc0000000`; pinned MAME independently
  corroborates it.
- The seeded 512-step differential compares P on every boundary and includes
  deterministic/randomized MPY reads; native-phase integration verifies that
  MPY retains the normal external program-read sequence.
- Hand fixtures and directed model/RTL tests verify every MPYK encoding bit,
  the signed immediate range -4096 through 4095, TI's `7 * -9` example, zero,
  T sign extremes, P replacement, architectural-state preservation, one-cycle
  retirement, and absence of logical data-memory activity.
- The seeded 512-step differential includes deterministic endpoint and
  randomized MPYK cases; native-phase integration verifies its ordinary
  external program fetch with no concurrent logical data transaction.
- Hand fixtures plus directed model/RTL tests verify PAC's exact `0x7f8e`
  decode, full-width ACC replacement, P/T/OV/OVM preservation, one-cycle
  retirement, and absence of logical data-memory activity.
- The seeded 512-step differential includes deterministic and randomized PAC
  cases; native-phase integration verifies the same ordinary external program
  fetch after MPYK.
- Hand fixtures plus directed model/RTL tests verify APAC's exact `0x7f8f`
  decode, TI's 32-plus-64 example, positive and negative overflow, OVM-clear
  wrapping, OVM-set endpoint saturation, sticky OV, unchanged P/T/address
  state, one-cycle retirement, and absence of logical data-memory activity.
- The seeded 512-step differential includes deterministic and randomized APAC
  cases; native-phase integration verifies its ordinary external program
  fetch and program-only transaction boundary.
- Hand fixtures plus directed model/RTL tests verify SPAC's exact `0x7f90`
  decode, TI's 60-minus-36 example, positive and negative overflow, OVM-clear
  wrapping, OVM-set endpoint saturation, sticky OV, unchanged P/T/address
  state, one-cycle retirement, and absence of logical data-memory activity.
- The seeded 512-step differential includes deterministic and randomized SPAC
  cases; native-phase integration verifies its ordinary external program
  fetch and program-only transaction boundary.
- Hand fixtures and directed model/RTL tests verify LTA's `0x6c` family,
  TI's RAM/T/P/ACC worked example, direct/page-one and indirect reads,
  old-address AR/ARP updates, positive and negative overflow, both OVM result
  modes, sticky OV, unchanged P, one-cycle retirement, and trap-before-effects
  behavior.
- The seeded 512-step differential includes deterministic and randomized LTA
  cases; native-phase integration verifies its internal read beside the
  ordinary external program fetch.
- Hand fixtures and directed model/RTL tests verify LTD's `0x6b` family, TI's
  three-operation RAM/T/P/ACC example, direct/page-one and indirect accesses,
  source-to-next-address copies, page crossing, positive/negative overflow,
  both OVM result modes, sticky OV, unchanged P, common post-update ordering,
  one-cycle retirement, and trap-before-effects for an unresolved endpoint.
- The seeded 512-step differential compares LTD's distinct logical source
  read and destination write plus all 144 final RAM words; native-phase
  integration verifies both internal transactions beside the ordinary
  external program fetch.
- Hand fixtures and directed model/RTL tests verify DMOV's `0x69` family,
  TI's source-preserving worked example, direct/page-one and indirect
  accesses, 127-to-128 page crossing, ACC/T/P/status preservation, common
  post-update ordering, one-cycle retirement, reserved controls, and
  trap-before-effects for an unresolved destination.
- The seeded 512-step differential compares DMOV's distinct logical source
  read and destination write plus all 144 final RAM words; native-phase
  integration verifies both internal transactions beside the ordinary
  external program fetch without LTD's T/ACC side effects.
- Hand fixtures and exhaustive decode verify only exact fixed words `0x7f81`
  and `0x7f82` as DINT/EINT while adjacent `0x7f83` still traps. Directed
  model/RTL tests verify immediate `INTM` state effects, preservation of
  unrelated state and a latched model request, reset masking, clock-enable
  hold, one-cycle retirement, and program-only transaction behavior.
- The seeded 512-step differential compares `INTM` after deterministic and
  randomized DINT/EINT cases. Native-phase integration retires EINT, a
  following NOP, and DINT at falling-edge sample boundaries without claiming
  pending-interrupt recognition or entry timing.
- Hand fixtures and exhaustive decode classify 140 legal `LST` words.
  Directed model tests exhaust the 16 combinations of loaded OV/OVM/ARP/DP
  under both old INTM values, and directed RTL tests verify direct/indirect
  address order, counter updates, status effects, INTM preservation,
  clock-enable hold, and trap-before-effects. Native-phase and seeded
  differential tests cover the same logical read and architectural state.
- Directed BANZ model/RTL tests cover both conditions, old-counter
  test-before-decrement, modulo-512 wrap, upper-bit preservation, PC wrap,
  canonical target enforcement, malformed-target trap-before-effects, and
  clock-enable hold. Native-phase tests cover both normal reads and target-read
  stalls; focused differential traces align model commits with both RTL cycles.
- Directed B model/RTL tests cover exact decode, two program reads,
  unconditional target selection, PC and operand-fetch wrap, preserved state,
  malformed-target trap-before-effects, target-phase stall, and skipped
  fall-through words. A focused differential aligns both RTL cycles with
  model commits.
- Accumulator-conditional directed tests cover all six exact opcodes, zero,
  positive, negative, maximum-positive, and most-negative predicates, both
  paths, mandatory second reads, target-phase stalls, state preservation, and
  malformed target traps. Native-phase and focused differential traces cover
  all six taken and untaken paths.
- Directed BV tests cover OV set and clear, target/fallthrough selection,
  taken-path clear at second-cycle retirement, mandatory second reads,
  target-phase stall, unrelated-state preservation, and malformed-target
  trap-before-clear. A focused differential compares per-cycle OV and every
  program transaction.
- Directed BIOZ tests reverse the raw pin in both directions between opcode
  and target samples, proving second-sample ownership and absence of an
  opcode-time latch. They also cover active-low target/fallthrough selection,
  the mandatory target read, target-phase stalls, malformed-target
  trap-before-effects, native control phases, and focused model/RTL traces.
- Directed CALL tests cover five nested calls, exact return addresses, all
  four stack levels, old-bottom discard, target-word stalls, program-counter
  and return-address wrap, malformed-target trap-before-push, and the absence
  of data-memory transactions. Native-phase and focused differential tests
  compare both program reads and the target-sample stack commit.
- Directed IN/OUT tests cover direct and indirect old-address ordering, all
  transfer directions, live input sampling, stable output data, AR/ARP
  updates, unresolved-address and reserved-control traps, exact cycle counts,
  MEN/DEN/WE exclusion, phase stalls, and model/RTL transaction agreement.
- Directed TBLR/TBLW tests cover direct and indirect old-address ordering,
  ACC-derived program addresses, RAM/program-memory direction and data,
  discarded-prefetch refetch, self-modifying code, stack-bottom duplication,
  AR/ARP updates, unresolved-address traps, exact three-cycle retirement,
  MEN/WE exclusion, phase stalls, and model/RTL transaction agreement.
- A rejected first table-transfer Quartus fit exposed 17 newly added
  program-write outputs and 2,906 output paths missing from the
  synthesis-harness exclusions. The corrected full rerun explicitly excludes
  those harness-only ports and reports zero unconstrained categories; this is
  still not wrapper I/O timing closure.
- Figure 2-12's program-read sequence is transcribed and asserted as current
  instruction, following instruction, dummy return PC, and vector 2. State
  tests independently assert masked-pulse persistence, one protected
  instruction, MPY/MPYK extension, stack push, INTM set, pending clear, and
  no retirement or data/I/O traffic during the dummy fetch.
- Active-low interrupt arrival at all 32 represented multicycle execution
  intervals passes in both core and explicit-pipeline matrices: both cycles
  of the 11 supported two-word control-flow
  families and IN/OUT, and all three cycles of TBLR/TBLW. Every path completes
  before service, retires exactly one protected instruction, dummy-fetches the
  resolved return PC while advertising vector 2 next, and enters with the
  expected stack and bus state.
- SymbiYosys v0.67-4-gfea6e46 and Bitwuzla 0.9.1 pass the 12-step actual-core
  interrupt BMC across arbitrary clock-enable choices; the separate cover
  reaches completed vector execution at step 6.
- The same formal stack passes a 14-step MPYK-extension/held-low-relatch BMC;
  its separate cover reaches the final masked-pending state at step 8.
- The same formal stack passes a 20-step direct-MPY/repeated-chain BMC across
  arbitrary clock-enable choices; its cover reaches completed entry at step
  12 after checking three exact signed products.
- The same formal stack passes a 20-step indirect-MPY BMC across arbitrary
  clock-enable choices; its cover reaches completed entry at step 12 after
  checking old address `0x8f`, product `0xffff0000`, AR0
  `0xaa8f`-to-`0xaa8e` decrement, and ARP replacement.
- A standalone 12-step BMC proves fetch/execute-register initialization,
  arbitrary-word capture, boundary stalls, incomplete retention,
  completion/replacement, bubbles, and reset/flush invalidation under two
  explicit sequencer assumptions; its cover reaches the complete
  prime/stall/replace/flush/target path at step 7.
- A 40-step actual-pipeline BMC proves one direct TBLR sequence across
  arbitrary clock-enable choices; its cover reaches the complete
  LACK/TBLR/LAC/NOP path at step 34 after checking `0x1234` program-to-RAM
  transfer and following ACC consumption.
- A second 40-step actual-pipeline BMC proves one direct TBLW
  self-modification sequence across arbitrary clock-enable choices; its cover
  reaches step 35 after the old ZAC is discarded, `0x7e44` is written exactly
  once at program address 2, refetched, and executed as `LACK 0x44`.
- Yosys 0.67+111 synthesizes the
  exact-B/BANZ/BV/BIOZ/CALL/accumulator-branch/IN/OUT/TBLR/TBLW/interrupt
  sequential pipeline wrapper, including ADDH, to 15,686 generic cells with
  103 retained
  checks and zero structural errors;
  `make synth-yosys` now reproducibly runs this top as well as the
  13,866-cell/26-check legacy harness.
- Directed pipeline tests prove that fetch 0 does not retire, fetch and execute
  addresses remain one word apart across stalls, every word in the qualified
  one-cycle stream matches legacy architectural state at one-retirement
  offset, an unsupported control word cannot enter the qualified execution
  path, and reset recovers the parked pipeline.
- A directed B pipeline test proves operand nonexecution, retained B ownership,
  redirected target fetch, two execution intervals, target-fetch stall
  stability, no early target effect, target execution in the following
  interval, and conservative malformed-operand parking.
- A directed BANZ pipeline test proves both old-counter outcomes, target or
  fallthrough selection before decrement, nine-bit modulo wrap with upper-bit
  preservation, retained ownership and register stability through a selected
  fetch stall, deferred fetched-instruction effects, and malformed-operand
  parking before counter mutation.
- A directed accumulator-branch pipeline matrix proves taken and untaken
  selection for every exact predicate, zero/positive/negative ACC
  distinctions, full-ACC preservation, retained ownership through stalls on
  both selected paths, deferred selected-instruction effects, and malformed
  operand parking.
- A directed BV pipeline test proves selection from the old sticky OV state,
  retained ownership and unchanged OV through operand and selected-fetch
  stalls, taken-path clear only at retirement, deferred selected-instruction
  effects on both outcomes, and malformed-operand parking before OV mutation.
- A directed BIOZ pipeline test proves the opcode-prefetch level is not
  latched, a pin change during an operand stall owns the decision at operand
  completion, later pin changes cannot redirect the selected fetch, both
  paths retain ownership through stalls, selected-instruction effects are
  deferred, and malformed operands park before speculative selection.
- A directed CALL pipeline test proves operand nonexecution, no push through
  operand or selected-target stalls, opcode-PC+2 push only at retirement,
  nested stack shifting, full non-stack state preservation, deferred target
  effects, and malformed-operand parking before a push.
- A directed IN/OUT pipeline test proves port-address/strobe ownership,
  MEN/DEN/WE mutual exclusion, live IN sampling, stable OUT data, independent
  stalls in both execution intervals, no early RAM or AR/ARP mutation,
  following-word effect deferral, and invalid-address parking before any
  native transaction.
- A directed TBLR/TBLW pipeline test proves retained execute ownership across
  all three Figure 2-10 intervals, mutually exclusive MEN/WE activity,
  independent stalls, deferred RAM/AR/ARP/stack/retirement effects, and a
  self-modifying TBLW whose discarded old PC+1 word never executes.
- A directed interrupt pipeline test proves masked-request retention through
  B/EINT, protected-instruction retirement, stalled N+2 discard, stalled
  vector fetch without early stack push, return-PC entry state, and deferred
  vector execution.
- A directed explicit-pipeline multiply test proves MPY and MPYK signed
  results, internal-read versus program-only bus shape, stalls, one additional
  protected retirement, discarded dummy words, post-following stacked PCs,
  vector capture, and deferred vector effects.
- The ignored reference cache verifies both newly acquired primary documents
  by SHA-256. Cross-sheet pin tracing now checks that low-I/O LS138 `30N`
  requires `/RVF` as well as `/RVAS`, and the documented MC68000 edge table
  accounts for every F74 transition from `/AS` assertion through S7.
- The standalone host-timing regression passes 8,192 exhaustive
  alias/address/direction/quadrant transactions plus directed byte-strobe,
  VPA, delayed-release, held-`/AS` no-retry, and FPGA-reinitialization cases.
  Yosys reports 142 abstract cells, 24 retained checks, no memory or latch,
  and zero structural problems. The integrated board regression additionally
  checks all four timed reads and writes, exact masked S4-through-S6 data,
  S7 mailbox/control effects, partial-write rejection, unimplemented speech
  visibility, and external-callback selection. Integrated Yosys retains three
  memories at 2,966 cells/257 checks. That checkpoint regression passed 127
  repository/tool, 231 model/unit, 38 instruction RTL, 42 bus/wrapper, 5
  interrupt, and 10 differential tests; strict lint across 30 modules, all
  twenty Yosys targets, all 33 reference hashes, and all 28 tasks from
  fourteen formal configurations pass. The adapter BMC passes through 16
  steps; its whole-word read/write covers reach step 8 and the fully settled
  VPA cover reaches step 9. The separate board BMC passes 12 steps and reaches
  all seven timing-derived routing covers at solver step 10. Both proofs remain
  scoped to common-clock digital behavior, not raw-pin CDC or electrical
  timing.
- An earlier checkpoint regression passed 124 repository/ISA/tool tests, 231
  directed model/unit tests, 38 exhaustive/directed instruction RTL tests, 33
  native bus/phase/wrapper tests including the exhaustive mailbox test and
  thirteen explicit pipeline tests, five
  interrupt RTL/phase tests, one 512-step seeded
  model/RTL differential, six focused two-cycle control-flow differentials,
  one focused IN/OUT differential, one focused TBLR/TBLW differential, and
  one focused interrupt-entry differential.

- The local-68000 memory decoder passes 131,072 exhaustive control-relevant
  combinations covering every ignored `A22:A17` alias, bank, transfer
  direction, and byte-strobe state. Yosys 0.67+111 reports 56 combinational
  cells, 17 checks, no memory/latch, and zero structural problems.
- The local-memory timing bridge passes complete synthetic ROM-valid,
  ROM-invalid, unwritten-SRAM, full-word SRAM, upper-byte SRAM, Y5 program,
  Y5 direct-I/O, Y6 communication, and isolated Y4 transactions. Yosys reports
  305 combinational hierarchy cells, 40 retained checks, no storage/latch,
  and zero structural problems.
- The upper-Y5 direct-I/O regression exhausts all 4,096 read and 4,096 write
  addresses, and the integrated board regression verifies canonical S6 write
  commits, S7 read completions, physical read aliases, unselected writes,
  masked read carriers, and ownership-conflict suppression. The complete
  regression split is 128/231/38/44/5/10; strict lint covers 32 modules, all
  22 Yosys targets pass, all 33 pinned hashes verify, and all 30 formal tasks
  from 15 configurations pass.
- The local-reset increment passes the complete 129/231/38/45/5/10 regression
  split, strict lint across 33 modules, all 23 Yosys targets, all 33 pinned
  reference hashes, and all 32 formal tasks from 16 configurations.
- The physical reset-source increment passes the complete
  129/231/38/46/5/10 regression split, strict lint across 34 modules, all 24
  Yosys targets, all 34 pinned reference hashes, and all 34 formal tasks from
  17 configurations.
- The main sound-reset decode increment passes the complete
  129/231/38/47/5/10 regression split, strict lint across 35 modules, all 25
  Yosys targets, all 34 pinned reference hashes, and all 36 formal tasks from
  18 configurations.
- The main `/RVAS` timing increment passes the complete
  129/231/38/48/5/10 regression split, strict lint across 36 modules, all 26
  Yosys targets, all 34 pinned reference hashes, and all 38 formal tasks from
  19 configurations.

### Known Issues

- The explicit pipeline closes the current 25 MHz Cyclone V internal target
  but not the exploratory 50 MHz target; the rejected fit has -9.098 ns worst
  slow-corner setup slack. This still exceeds the Driver Sound board's 20 MHz
  processor clock, but further pipelining/critical-path work is required before
  any higher-frequency claim.
- The optional FPGA local SRAM needs 8,192 clocks to invalidate metadata after
  `initialize_i`. This is an integration convention, not physical 6264 reset
  or wait behavior. The wrapper gates exported local RESET/HALT release, but a
  future MC68000 integration must compose the now-qualified common Rev-A reset
  source with a calibrated tick, raw-input CDC, component-tolerance policy,
  and the selected core's reset interface under `OQ-035`. The nominal
  155.1 ms calculation is not a production-board pulse-width guarantee.
- A044427's `RVA`/`/DTACK`/`/RVAS` logic and same-clock board composition are
  qualified at logical bus-state resolution, but complete TTL
  propagation/loading margin, raw-pin CDC, and unreset power-up transient are
  not. The board-faithful path cannot insert arbitrary callback stalls
  because the circuit has no READY input or held-`/AS` re-arm (`OQ-033`).
- A production A044427 Rev-A port-2 word is electrically unqualified. The
  drawing routes only `CMPOUT` to `TDI15`, while the complete source and pull-up
  sheet is not loaded; pinned MAME's `0x0000` handler is a deterministic stub,
  not hardware evidence (`SC-029`/`OQ-029`).
- The parallel sample-ROM callback is implemented, but exact population remains
  board/revision data and authorized storage is external. An absent block
  leaves the shown physical data bus undriven; the adapter reports and stalls
  instead of returning a protective zero (`OQ-026`).
- The communication-RAM/address adapter is connected to
  `hard_drivin_sound_mister`, and the opt-in same-clock Y6 path now supplies
  its host cycles. CRAMEN remains an explicit ownership input unless the
  separate host-control opt-in supplies Q3; no raw-pin/CDC 68000 boundary
  exists. Its registered response is an FPGA convention, not physical HM6116
  timing.
  Pinned MAME still conflicts by returning RAM during host ownership and by
  omitting the global `/PDEN` increment from port 2. Port 3 is now resolved;
  its undriven host low byte remains a distinct open-bus question (`OQ-030`).
- The main/sound mailbox adapter is board-top connected but whole-word only.
  Physical
  byte accesses and coincident LS74 preset/read-clock/reset behavior remain
  unresolved under `SC-031`/`OQ-031`; no full 68000 or main-system bridge
  consumes these completion callbacks.
- The raw `/READSTAT` mapper is board-top connected to the mailbox flags and
  explicit raw test/ready inputs, but no 68000 read decode exists and physical
  `D11:D0` remain unresolved under `OQ-030`; MAME's fixed
  test/ready/low-lane values are isolated as `SC-032` rather than promoted to
  board behavior.
- The raw `/SWITCHES` mapper and masked selector are board-top connected but
  assign no cabinet functions or
  inactive levels to `J3-11/J3-9/J3-8/J3-7` under `OQ-032`. Pinned MAME swaps
  the `/SWITCHES` and `/320PORT` handler names relative to Atari LS138 `30N`
  and returns zero from both; `SC-033` prevents either stub from defining a
  board selector. The selector is not `/RVAS`, DTACK, a completed read, or an
  open-bus policy; physical `D11:D0` remain `OQ-030`.
- `hard_drivin_sound_mister` is only the processor/program/communication-RAM/
  sample-ROM-callback/BIO-generator and qualified physical-I/O boundary. It
  lacks the 68000 bridge, actual sample storage, compare/DAC-analog
  implementations, a board 1 MHz enable source, and a
  loaded mute consumer; raw MUTE and 68000-IRQ latch state are implemented but
  do not establish effective audio semantics or the host address decoder;
  its synchronous ready/commit callbacks are implementation conventions, not
  physical SRAM pins. Its Yosys result is not a Cyclone V fit or timing result,
  and the future 68000 bridge must resolve or reject byte accesses under
  `SC-022`/`OQ-022`.
- The BIO divider/resampler is primary-transcribed and connected as an opt-in,
  but the physical counters and CLKOUT resampler have no board-reset
  initialization, and their 1 MHz/CLKOUT clocks derive from independent
  crystals. The current same-clock boundary preserves exported validity and
  rejects, rather than models, coincident edges under `OQ-028`; MAME's
  query-driven 20 kHz event is not a pin-level replacement (`SC-028`).
- A044427 has no program-RAM arbiter. Simultaneously selecting the host window
  while `/320RES` is released enables conflicting buffer paths; pinned MAME's
  always-accessible shared array and HALT mapping do not reproduce that
  electrical contract (`SC-020`/`OQ-021`). The digital wrapper rejects overlap,
  but actual 68000 firmware compliance and handoff timing remain unqualified.
- A044427 Rev A directly wires the 12-bit Am6012 code, while pinned MAME
  complements bit 11 before its unsigned DAC mapper and describes that as a
  schematic inversion. No inverter is present in the reviewed drawing.
  `SC-019`/`OQ-020` therefore keep the signed PCM conversion and possible
  production ECO/variant difference unresolved; only raw `data[15:4]` is
  primary-qualified and implemented. Analog/sample interpretation remains
  unresolved.
- All 60 documented instruction mnemonics have model/tool evidence; fifty-eight
  also have RTL/differential evidence. PUSH and POP remain outside RTL/native
  qualification because their external address ownership is unresolved.
- The exhaustive primary-documentation partition contains 28,656
  `PRIMARY_UNLISTED_ENCODING` words and 372 simultaneous-update words under
  `OQ-010`. It is not a completed reserved-behavior map: TI's complete
  instruction summary proves those words are unlisted, not that silicon treats
  them as reserved. Unsupported execution behavior remains unclaimed and the
  model/RTL trap is only conservative project policy.
- MAME models untaken BANZ as one cycle and does not fetch its following target
  word, contrary to original TI's unconditional two-word/two-cycle entry. MAME
  remains a functional oracle only for this instruction (`SC-012`).
- MAME also shortens untaken BV to one cycle and omits its target read;
  project behavior follows TI's unconditional two-cycle entry (`SC-014`).
- MAME also shortens untaken BIOZ to one cycle and does not read the target;
  it exposes an abstract asserted callback rather than documenting physical
  pin polarity. Project behavior follows TI's active-low pin and unconditional
  two-cycle entry (`SC-015`).
- Original TMS32010 manuals do not define LST's memory-sourced ARP versus
  encoded next-ARP precedence. The implemented memory-word precedence is
  PROVISIONAL under `OQ-015`; later TI and MAME evidence corroborates but does
  not prove original silicon behavior.
- The located original PUSH/POP pages do not show per-cycle program-address or
  fetched-word ownership. TI's general pin table establishes active `MEN` in
  both non-I/O cycles, while pinned IKA32010 models an idle first microcycle;
  this is `SC-018`. State effects and numeric totals are model/tool-qualified,
  but native/RTL sequencing remains deferred under `OQ-016`; no repeated or
  speculative prefetch has been assigned. A physical experiment now defines
  the smallest resolving evidence.
- TI requires the instruction after SUBC not to use ACC but does not establish
  observable behavior for a violation; current same-boundary result commit is
  an implementation convenience under `OQ-017`. TI also says SUBC affects OV
  without identifying the producing arithmetic stage; intermediate-subtraction
  sticky OV is PROVISIONAL under `OQ-018`.
- Interrupt external fetch order and directed entry state are verified, but
  the partial core still collapses fetch and execution at sample boundaries.
  The 32 represented multicycle arrival intervals are independently qualified
  in the core and explicit pipeline;
  the current wrapper's four digital subphases now have falling-boundary
  sampling assertions. Physical
  setup/synchronizer behavior, PUSH/POP cycles, and physical confirmation of
  ADR-0003 remain under `CTRL-002`/`OQ-004`/`OQ-007`/`OQ-016`.
- No dedicated original-part branch pin waveform has been located. Exact B,
  BANZ, BV, BIOZ, CALL, and the six accumulator-branch explicit
  execute-interval mappings are INFERRED from Figure 2-2, the
  two-word/two-cycle table entries, and their operand/condition definitions,
  with directed simulation evidence under `OQ-007`.
- CALA/RET state effects and numeric two-cycle totals are model/RTL-qualified.
  Their explicit discarded-sequential/selected-target sequence remains
  `INFERRED`, not original-pin proof, under `OQ-007`/`SC-037`.
- DINT in the already-pipelined final slot currently cancels entry while
  retaining the request. That ordering is targeted-tested but PROVISIONAL
  under `OQ-019`.
- Formal evidence currently covers four fixed interrupt-entry programs,
  one fixed CALA/RET call/return program,
  at 12-, 14-, and two 20-step bounds, one standalone ownership register, and
  fixed direct-TBLR and direct-TBLW integrated-pipeline programs at 40 steps.
  It excludes DINT, the other indirect MPY control/update cases, arbitrary
  multiply-chain placement/length, formal coverage of the represented
  multicycle-arrival matrix, indirect table addressing, the general
  pipeline, general external-memory behavior, and broad decode/datapath
  properties.
- Original-part ADDH status behavior is resolved only at CORROBORATED
  confidence under `SC-017`/`OQ-011`: the implementation preserves OV,
  ignores OVM, and never saturates, but original-silicon measurement is still
  needed to upgrade confidence. Physical-reset retention of unlisted state
  remains unresolved as `OQ-012`. ABS result and
  timing are primary-verified; its OV preservation is explicitly
  `CORROBORATED`, not physical-hardware verified, under resolved `OQ-013`.
- Original-part DMOV/LTD behavior when source `0x8f` implies destination
  `0x90` remains unresolved under `OQ-014`; the partial implementation traps
  before all effects and labels that policy provisional.
- Remaining indirect control-flow/return traces, interrupt execute ownership,
  original-silicon SST bit-1 qualification, and out-of-range RAM behavior
  remain open.
- The execution core still has an instruction-step test interface; the
  native-phase wrapper covers the qualified normal, branch, I/O, table, and
  interrupt program-read sequences but not the complete overlapped pipeline.
- The standalone core intentionally retains its asynchronous RAM read. The
  phase-aware wrapper uses ADR-0004's registered one-M10K mapping; this does
  not qualify an arbitrary caller to enable registered mode without address
  lead time.
- Yosys, iverilog, SymbiYosys, and pytest are not currently available on the
  local executable path. Yosys is qualified in an isolated Ubuntu 24.04
  environment; the host target still fails explicitly when the tool is absent.
