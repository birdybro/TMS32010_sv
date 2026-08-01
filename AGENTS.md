# AGENTS.md

## Project goal

Develop a clean-room, synthesizable, portable, extensively verified,
cycle-accurate implementation of the original NMOS Texas Instruments
TMS32010. The eventual consumer is a MiSTer implementation of Atari Hard
Drivin', especially its sound subsystem, but Hard Drivin'-specific behavior
must stay outside the architectural core.

The labels "instruction-complete", "cycle-accurate", and "release-ready" are
claims of evidence. Never use them until every applicable criterion below is
objectively satisfied.

## Mandatory reading before work

Before modifying RTL, read:

1. this file;
2. `TASKS.md`;
3. `CHANGELOG.md`;
4. all architecture, timing, research, and integration documents relevant to
   the change;
5. every applicable architecture decision record in `docs/decisions/`.

Before every meaningful development cycle, select a stable task ID from
`TASKS.md`. Update both `TASKS.md` and `CHANGELOG.md` in the same cycle.

## Authority and clean-room rules

Architectural evidence has this precedence:

1. original TI TMS32010 user manuals, data sheets, errata, and timing data;
2. Atari schematics, service manuals, PAL equations, and board documents;
3. contemporary TI development-tool and application documents;
4. decap evidence and independently measured physical-hardware behavior;
5. maintained emulator implementations;
6. academic FPGA implementations;
7. community summaries.

When sources conflict, do not choose silently. Record the exact conflict,
citations, competing hypotheses, impact, and confidence in
`docs/research/source_conflicts.md` or `docs/research/open_questions.md`.
Follow `docs/decisions/ADR-0001-reference-precedence.md`.
Pipeline changes must also follow
`docs/decisions/ADR-0002-fetch-execute-separation.md`.

MAME and other implementations are independent behavioral oracles only. Do
not copy or transliterate their code into the model or RTL. Preserve exact
commit IDs, paths, licenses, and adapter changes. Never let emulator behavior
override primary documentation without documented stronger evidence.

Classify every uncertain claim as one of:

- `VERIFIED_PRIMARY`
- `VERIFIED_HARDWARE`
- `CORROBORATED`
- `INFERRED`
- `PROVISIONAL`
- `UNKNOWN`

Do not promote confidence without new evidence.

## Source provenance and copyright

Every acquired reference requires a record in
`docs/references/manifest.yaml`: title, organization/author, publication
number, date, revision, URL, retrieval date, local filename, SHA-256, type,
license or redistribution status, authority, relevance, commit permission,
notes, and pages/sections used.

Put documents whose redistribution status is unclear in the gitignored
`reference-cache/`. Do not commit copyrighted manuals, game ROMs, downloaded
binaries, or third-party source snapshots without explicit permission. Do not
evade access controls. Never execute downloaded legacy tools. Treat all
downloads as untrusted.

## Coding conventions

- Use lower-case `snake_case` for files, modules, signals, variables, and
  functions; `UPPER_SNAKE_CASE` for constants; and a `tms32010_` prefix for
  public modules and packages.
- Use two spaces per indentation level and no tabs.
- Put shared architectural types and widths in
  `rtl/packages/tms32010_pkg.sv`.
- Use explicit widths, explicit signedness, sized literals, and named ports.
- Use `logic`, `always_ff`, `always_comb`, `typedef enum logic`, and package
  types supported by current Quartus and Verilator.
- Give every combinational output a default. No inferred latches,
  combinational loops, implicit nets, accidental truncation, or width-dependent
  arithmetic.
- Start synthesizable files with ``default_nettype none`` and restore
  ``default_nettype wire`` at the end when tool compatibility requires it.
- Comments explain evidence, externally observable timing, and non-obvious
  intent; they do not restate syntax.
- Architectural constants need a citation in nearby documentation. Do not use
  an implementation convenience as an architectural fact.

## Synthesizable SystemVerilog subset

Architectural RTL must be portable across Quartus, Verilator, and Yosys.
Never use delays, `force`/`release`, real-number constructs, DPI, classes,
randomization, testbench-only system tasks, unsynthesizable `initial` behavior,
vendor primitives, or simulation-dependent initialization in synthesizable
files. Arrays, functions, generate blocks, assertions guarded for tool
compatibility, and packages are permitted when all target tools accept them.

The physical TMS32010's unknown power-up state must not be replaced by arbitrary
architectural initialization. FPGA-friendly deterministic initialization, if
needed, belongs in a documented wrapper or explicit compatibility parameter.

## Clocking and reset

- The portable core has one primary clock.
- Use clock enables and explicit phase/state sequencing.
- Never create gated or logic-generated clocks.
- No asynchronous internal control paths.
- Reset polarity, assertion, release, minimum duration, initial state, bus
  behavior, and first-fetch timing must be source-backed.
- Do not choose synchronous versus asynchronous reset merely for convenience.
  Until primary evidence is resolved, keep reset behavior marked `UNKNOWN` and
  avoid architectural claims.
- A future multi-clock wrapper must use explicit, reviewed clock-domain
  crossing logic; the core itself stays single-clock.

## Verification rules

RTL existence is not completion. Every claimed instruction needs:

- an ISA database entry and source citation;
- an independently hand-verified opcode fixture;
- directed reference-model tests;
- RTL execution tests;
- arithmetic and flag boundary tests;
- cycle-count tests;
- externally visible bus-trace tests;
- addressing and control-flow tests as applicable;
- randomized differential coverage where practical.

Every claimed cycle count and bus sequence needs an automated timing assertion.
Reserved encodings are not no-ops unless authoritative evidence establishes
that behavior. Tests must be deterministic; preserve failing random seeds.

Never bypass a failure, weaken an assertion, delete coverage, loosen expected
results, or edit a test merely to conceal a defect. A changed expectation
requires cited evidence and a documented rationale. Investigate discrepancies
among primary sources, the model, RTL, and oracles as research issues.

Formal claims must state bounds and assumptions. Synthesis claims must retain
tool version, warnings, utilization, clock constraints, and timing evidence.
Quartus "timing closure" requires fitter and TimeQuest evidence, not an
estimate.

## Required commands

Before every commit, inspect the diff and run the applicable subset:

```sh
make docs
make unit
make instruction-tests
make bus-tests
make differential
make lint
make formal
make synth-yosys
make test
```

For RTL changes, `make lint`, focused simulation, broader RTL regression, and
`make synth-yosys` are required when tools are available. For model/tool
changes, run unit and round-trip tests. Missing tools must be documented in
`artifacts/progress.md`; they are not passing evidence. Before release, all
commands plus `make synth-quartus` must pass in a qualified environment.

## Commit discipline

- Keep commits small, coherent, reviewable, and buildable.
- Use prefixes such as `chore`, `docs`, `research`, `model`, `tools`, `rtl`,
  `test`, `formal`, `synth`, `integration`, and `fix`.
- Before committing, inspect staged content and ensure no manuals, ROMs,
  binaries, generated build products, secrets, or unrelated user changes are
  included.
- Update `TASKS.md`, `CHANGELOG.md`, citations, and
  `artifacts/progress.md` for every meaningful cycle.
- Never rewrite published history.

## Documentation requirements

Architectural statements cite publication, revision, page, section, table, or
figure wherever possible. Keep documented hardware behavior, software-observed
behavior, inference, implementation convenience, and unknown behavior visibly
separate. Machine-generated ISA and timing tables come from the canonical ISA
database where practical; do not maintain contradictory handwritten copies.

Record decisions that constrain future work as ADRs. Record all unresolved
timing and mask-revision questions even when Hard Drivin' appears unaffected.

## Repository layout

- `docs/architecture/`: cited architectural specification
- `docs/research/`: open questions, conflicts, and investigation notes
- `docs/references/`: provenance manifest and acquisition policy
- `docs/timing/`: instruction and bus timing evidence
- `docs/integration/`: wrappers and Hard Drivin' requirements
- `docs/decisions/`: architecture decision records
- `docs/generated/`: generated human/machine-readable ISA artifacts
- `rtl/core/`, `rtl/packages/`, `rtl/wrappers/`: synthesizable design
- `sim/`: simulation tests, programs, and independent reference models
- `formal/`: assertions, harnesses, and proof configurations
- `tools/`: assembler, disassembler, trace, reference, and generators
- `scripts/`: repeatable acquisition, verification, and regression entrypoints
- `tests/`: source programs, expected fixtures, and regression tests
- `synthesis/`: portable, Quartus, Verilator, and Yosys configurations
- `third_party/`: permitted metadata/adapters, not uncategorized downloads
- `build/`: ignored generated products
- `artifacts/`: concise tracked evidence summaries; large outputs remain ignored
- `.github/workflows/`: reproducible CI

## Completion criteria

Instruction completion requires every documented original-TMS32010 opcode and
legal encoding in the database, model, RTL, assembler/disassembler, directed
tests, arithmetic/flag/address tests, timing/bus tests, and full regression.

Cycle accuracy requires automated evidence for every documented timing case,
fetch/execute overlap, branch/repeat timing, interrupt boundaries and latency,
wait states, and native program/data/I/O sequencing, with every unresolved
question disclosed.

Release readiness additionally requires clean lint, differential regression,
documented formal bounds, Yosys and Quartus synthesis, no latches or accidental
clocks, constrained fitter timing, license and provenance audits, complete
interfaces and integration guides, realistic DSP code, and a legal synthetic
or user-supplied Hard Drivin' execution test.

## Current architectural status

As of 2026-07-31 the machine-readable database, independent model, and local
tools support all sixty documented instructions:
`ABS`, `ADD`, `ADDH`, `ADDS`, `AND`, `APAC`, `B`, `BANZ`, `BGEZ`, `BGZ`, `BIOZ`, `BLEZ`, `BLZ`, `BNZ`, `BV`, `BZ`, `CALA`, `CALL`, `DINT`, `DMOV`, `EINT`, `LAC`, `LACK`, `LAR`, `LARK`, `LARP`, `LDP`,
`LDPK`, `LST`, `LT`, `LTA`, `LTD`, `MAR`, `MPY`, `MPYK`, `NOP`, `OR`,
`IN`, `OUT`, `PAC`, `POP`, `PUSH`, `RET`, `ROVM`, `SACL`, `SACH`, `SAR`, `SOVM`, `SPAC`, `SST`, `SUB`,
`SUBC`, `SUBH`, `SUBS`, `TBLR`, `TBLW`, `XOR`, `ZAC`, `ZALH`, and `ZALS`. This includes
CALA's primary-defined computed-call effects, RET's primary-defined stack
pop/PC load, and PUSH/POP's primary-defined stack effects at their two-cycle
model boundaries.
The opcode audit assigns exactly one evidence-scoped classification to every
16-bit word: 21,895 documented legal, 10,976 that set TI's explicitly reserved
indirect-address bits, 372 simultaneous increment/decrement combinations
under `OQ-010`, 3,637 documented-pattern mismatches, and 28,656 encodings not
listed in TI's explicitly complete primary instruction summary.
Only the explicit reserved-bit class may be called reserved. Pattern mismatch
and primary-unlisted do not establish execution behavior; the current model/RTL
trap remains conservative project policy. The reserved-encoding audit is not
complete.
RTL and seeded differential support the same set except CALA, POP, PUSH, and
RET, for fifty-six shared instructions; their second external cycles remain
`OQ-007`/`OQ-016`.
The synthesizable `tms32010_fetch_execute` register now separately represents
fetched instruction validity/address and execute ownership with completion and
flush controls. It passes directed overlap/dummy/redirect/reset tests,
standalone Yosys synthesis, and a bounded transition proof.
Recognized core reset now has dedicated actual-core simulation and a 10-step
bounded proof for TI-defined PC/INTM/interrupt-flag/control effects, inactive
transactions/instruction qualification, clock-enable priority, documented OVM
retention, and explicitly PROVISIONAL retention of TI-unlisted state under
`OQ-012`. Do not promote that implementation retention to physical behavior.
`tms32010_sequential_pipeline_slice` now connects it to the partial core for
reset priming, the 41 already-qualified one-cycle operation families, and
exact B, BANZ, BV, BIOZ, CALL, the six accumulator-conditional branches, and
the primary-defined IN/OUT transfer-plus-prefetch and TBLR/TBLW
discarded-prefetch/table-transfer/repeated-prefetch sequences.
The control-flow instructions retain execute ownership through a
nonexecutable operand fetch and the selected target/fallthrough instruction
fetch, retiring only as that instruction enters the execute slot. BANZ tests the old selected nine-bit
counter and defers its modulo-512 decrement until retirement. The
accumulator-branch matrix covers both outcomes for every predicate and
zero/positive/negative ACC. BV selects from unchanged OV and clears it only
at taken retirement. BIOZ samples the raw active-low input at operand
completion, not opcode recognition, and retains the resulting decision
through the selected fetch. CALL pushes opcode-PC+2 only at selected-target
capture; nested calls prove stack shifting. Selected-fetch stalls cover both
outcomes for the conditional families and the direct call. These combined
interval mappings are INFERRED from primary component facts because no
dedicated branch/call pin waveform has been located. The full-state offset
differential covers the 46-word directed one-cycle stream and parks before
an unsupported control word. IN/OUT retain execute ownership while cycle 1
multiplexes
the port address and asserts only DEN or WE, sample/hold live transfer data
at that falling boundary, and retire only when cycle 2 fetches the following
instruction under MEN. Directed stalls prove stable phase, address, strobe,
data, and ownership in both intervals; invalid RAM addresses park before any
native strobe. Figure 2-9 makes this combined I/O mapping
VERIFIED_PRIMARY rather than inferred. TBLR/TBLW retain ownership through
Figure 2-10's discarded PC+1 read, ACC-addressed program read/write, and
repeated PC+1 fetch. Only the repeated-fetch boundary commits RAM, indirect
AR/ARP, stack-bottom, and retirement state. A self-modifying TBLW test proves
that the first PC+1 word is discarded and the rewritten word is fetched and
executed. The explicit native interface exposes program writes separately
from I/O writes. Figure 2-12's basic
EINT/protected-instruction/dummy/vector path now has explicit ownership,
including stalls and deferred vector execution. MPY and MPYK in the protected
slot now have explicit extension through one additional instruction, including
signed products, bus shape, stalls, and post-following return-PC ownership.
The 32 represented arrival intervals across all 15 supported multicycle
families now have matching core and explicit-pipeline matrices; the explicit
matrix checks family-specific native strobes, no midinstruction entry, one
protected retirement, dummy ownership, stack entry, acknowledge state, and
vector capture. Other multicycle
pipeline integration remains absent; do not
generalize this narrow evidence into a complete fetch/execute claim.
A 12-step standalone BMC checks its transition relation for arbitrary
fetch/control inputs satisfying the two legal sequencer contracts; the cover
reaches prime/stall/replacement/flush/target capture at step 7. This is not
evidence for correct core integration.
The shared boundary includes
`ADD`/`ADDH`/`ADDS`/`AND`/`DMOV`/`LAC`/`LAR`/`LDP`/`LST`/`LT`/`LTA`/`LTD`/`MPY`/`OR`/`SUB`/`SUBC`/`SUBH`/`SUBS`/`XOR`/`ZALH`/`ZALS`
reads and `DMOV`/`LTD`/`SACL`/`SACH`/`SAR`/`SST` writes in a 144-word internal RAM, plus SACH output shifts
0, 1, and 4. ADD and SUB have directed sign-extension, shift, positive/negative
wrap/saturation, and sticky-OV evidence. SUBH has directed high-half alignment,
low-half preservation, both signed-overflow directions, full-accumulator OVM
saturation, and common-address evidence. ADDH has directed modulo high-half
addition, unconditional low-half and OV/OVM preservation under the
CORROBORATED `SC-017`/`OQ-011` resolution, and common-address evidence. ADDS and SUBS have directed unsigned
source, wrap/saturation, and sticky-OV evidence. AND, OR, and
XOR have directed accumulator-half and status-preservation evidence. A phase
wrapper also verifies LAR's same-address-AR update suppression and
different-target post-modification, and SAR's post-modified same-source store
at the old address. MAR modifies only AR/ARP in indirect form, is a direct-form
NOP, and produces no data-memory transaction. LDP loads DP from a selected
data-word LSB using the old DP or selected AR for address resolution. The
LT path loads all 16 selected data-word bits into T through the same
old-address and post-access update order. MPY signed-multiplies T by the
selected word into P, including the documented most-negative exception,
through that same address/update path. MPYK sign-extends its signed 13-bit
program-word constant and multiplies it by T into P without a data-memory
access. PAC copies P into ACC without a data-memory access or arithmetic
status change. APAC adds P to ACC with sticky signed overflow and
OVM-controlled wrapping or saturation. SPAC applies the same arithmetic policy
while subtracting P from ACC; neither operation has a data-memory access.
LTA reads an internal data word into T while adding the unchanged previous P
value to ACC with APAC's overflow policy in the same documented cycle.
LTD adds the source-preserving copy to the next data address in that same
cycle. Its logical interface exposes distinct read/write addresses; source or
destination addresses outside the verified 144-word RAM trap provisionally
under `OQ-002`/`OQ-014`.
DMOV performs that same unchanged-word next-address copy without the LTD
T-load or ACC-plus-P effects and preserves ACC, T, P, OV, OVM, and DP.
Its endpoint policy is equally provisional under `OQ-002`/`OQ-014`.
`DINT` and `EINT` set and clear `INTM` at their one-cycle retirement
boundaries without a data transaction. The core samples active-low `INT`,
retains masked requests, implements the qualified EINT and MPY/MPYK
deferrals, performs a non-retiring return-PC dummy fetch and stack push, sets
INTM, clears the request, and selects vector 2. Directed native-phase evidence
matches TI Figure 2-12's external address order. Matching 32-case core and
explicit-pipeline matrices exhaust arrival at every represented execution
interval of all 15 supported multicycle families. A four-case native test
also proves the current digital
wrapper samples a held-low request only at the enabled falling boundary from
each modeled subphase, including a phase stall. The explicit pipeline
additionally qualifies the basic EINT/protected-word/discarded-N+2/vector
sequence, including the MPY/MPYK protected-slot extension. Physical
setup/synchronizer behavior, native/RTL CALA/RET
sequencing, PUSH/POP second-cycle sequencing, and the provisional
DINT-at-final-boundary ordering remain outside the qualified boundary under
`OQ-004`/`OQ-007`/`OQ-016`/`OQ-019`.
For Atari integration specifically, production drawing A044427 Rev A holds the
TMS32010 active-low interrupt input inactive through the `PR1`/`R26` 1 kΩ
pull-up. Its board-generated `/320BIO` signal is resampled by `CLKOUT` into
`/BIOS`; the similarly named `320IRQ` is instead part of the 68000-side
interrupt path. These are board-wrapper facts, not generic-core behavior.
A044427 also directly latches raw DAC code `TD15:TD4` onto Am6012 `B1:B12`;
pinned MAME's bit-11 complement is an unresolved secondary conflict under
`SC-019`/`OQ-020`. Its 4K-by-16 program RAM has no hardware arbiter: the
68000 must hold `/320RES` asserted while `/320RAM` enables host buffers, and
simultaneous host/running-DSP ownership is invalid (`SC-020`/`OQ-021`). The
board's physical WE decode also routes addresses `0x000`–`0x007` to output
ports, so low-address TBLW aliases OUT on Rev A (`SC-021`). Keep all of this
outside the generic core.
The board-only `hard_drivin_sound_dac_latch` now captures exactly
`io_write_data[15:4]` on a committed port-0 write, retains the raw code across
processor reset, and reports a one-clock commit pulse. Its deterministic
initialization validity is an FPGA convention. Never add MAME's bit-11 XOR,
signed-sample conversion, or analog filtering to this module without resolving
`SC-019`/`OQ-020` from stronger evidence.
The board-only `hard_drivin_sound_output_control` follows the two LS74 halves
at A044427 location 100H. Port 4 commits raw `MUTE=/Q=!TD0`; port 5 presets
active-high `320IRQ` independently of write data, `/320RES` clears both Q
states, and the separate host callback clocks grounded D to clear the IRQ.
Expose the raw mute net only: its sole Rev-A analog consumer is marked
`NOT LOADED`, and `SC-027`/`OQ-027` prohibit inventing an audio effect.
The standalone `hard_drivin_sound_bio_generator` transcribes the A044427
LS161 `0xce`-through-`0xff` divide-by-50 chain, one-period active-low source,
and CLKOUT LS74 resampler. Represent its independent clocks only through
explicit enables; never generate internal clocks. Board `/RESET` clears the
source LS74 but not the counters or resampler. Preserve caller-seed and pin
validity. Its opt-in board-top connection derives CLKOUT sampling from the
actual modeled processor phase, keeps external raw BIO as the default, and
rejects a coincident 1 MHz enable by assertion. Do not weaken that containment
or select physical coincidence behavior without resolving `OQ-028`.
The board-specific `hard_drivin_sound_program_ram` now implements a
same-clock, synchronous-read 4K-by-16 FPGA storage adaptation. It permits host
access only while `/320RES` is asserted, permits TMS access only after host
selection is released, grants neither side during overlap, and never clears
program contents on reset. Its whole-word host port follows the shown
A12:A1/D15:D0 path; byte-access compatibility is unresolved under
`SC-022`/`OQ-022`. This is an integration convention, not a claim that the
physical asynchronous SRAM has ready signaling or registered reads.
The standalone `hard_drivin_sound_host_control` transcribes LS259 `80R` only.
A decoded `/LATCHES` completion uses host `A3:A1` to select Q and `A4` as the
new value; `D15:D0` is irrelevant. Board `/RESET` clears all eight outputs,
including `CRAMEN=Q3` and `/320RES=Q4`. Preserve per-bit validity before reset
or write, and do not describe the same-clock completion as the physical
level-sensitive interval. It is not yet connected to the board top. Read
`docs/integration/hard_drivin_host_control.md` before modifying or integrating
this path; full `/RVAS`, DTACK, and 68000 timing remain outside it.
The partial `hard_drivin_sound_mister` connects that storage to the generic
callback wrapper, separates deterministic initialization from physical
processor reset, and passes the host-loaded ROM-free smoke plus a low-TBLW
alias execution test. It ties Rev-A INT inactive and selects between default
external BIO and an explicit-validity board generator. It is not a 68000
bridge, complete peripheral implementation, full MiSTer top, or board timing
qualification.
A044427 communication RAM is a separate 512-by-16 resource. Host latch
`CRAMEN` selects either host read/write access or DSP port-1 read-only access;
the DSP address comes from the low nine bits of a shared 16-bit LS191 counter.
Every physical input read increments that counter, port 7 loads it, and port 6
latches a separate ROM block nibble. Port 3 only produces an unconsumed
`/CPORT` decode in the audited Rev-A drawing and must remain unresolved under
`OQ-023`. Follow `docs/integration/hard_drivin_communication_ram.md` and
`SC-023` through `SC-025` before changing this path.
The standalone `hard_drivin_sound_communication_path` now implements that
FPGA storage/control boundary with explicit validity for the physically
uncleared LS191/port-6 state. Its exhaustive test and memory-retaining Yosys
script qualify the isolated adapter. `hard_drivin_sound_mister` now routes
processor port 1 to that path and exposes its whole-word host callback; the
synthetic execution test qualifies the handoff, data source, global read
increments, and reset retention. Do not infer a 68000 bridge/latch decode,
physical HM6116 latency, or completed board integration.
A044427's sample-ROM path is parallel, not serial: a port-6 LS374 selects one
of twelve drawn 64K-byte blocks, `SA15:SA0` supplies the pre-increment byte
address, and port 0 returns
`{{2{rom_byte[7]}}, rom_byte[6:0], 7'b0}`. A block must be explicitly declared
present; blocks 12–15 select no drawn ROM, and an absent block is electrically
undefined under `OQ-026`. Pinned MAME's unsigned left shift omits TDI15 and is
only a named secondary-oracle difference (`SC-026`). Read
`docs/integration/hard_drivin_sound_rom.md` before implementing this path.
The storage-free `hard_drivin_sound_rom_path` now enforces that contract. It
issues a byte callback only for explicit present/valid block and address state,
never acknowledges invalid or absent selections, and forms the duplicated-sign
word combinationally. `hard_drivin_sound_mister` routes processor port 0 to it;
the external generic I/O response must not override ports 0 or 1. Do not infer
ROM contents, absent-bus values, asynchronous device timing, or authorized ROM
provenance from this adapter.
A044427 port 2 is not a qualified compare word. `/CMPRD` enables an LS244 path
from `CMPOUT` only to `TDI15`; the optional microphone/LM311 source sheet,
including its output pull-up, is explicitly `THIS SHEET NOT LOADED.` Keep port
2 on an explicit external data/ready callback under `SC-029`/`OQ-029`. Never
hardwire MAME's zero-return stub and label it production Rev-A behavior; the
synthetic smoke zero is only a named test sentinel. Read
`docs/integration/hard_drivin_compare.md` before changing this boundary.
`LST` loads `OV`, `OVM`, `ARP`, and `DP` from an internal word while
preserving `INTM`; the indirect next-ARP precedence remains a labeled
provisional behavior under `OQ-015`.
`SUBC` implements the documented conditional subtract/divide recurrence in
one cycle and is tested only with the required ACC-free following
instruction. Its exact result availability after a scheduling violation and
the exact intermediate that sets sticky `OV` remain provisional under
`OQ-017`/`OQ-018`.
`BANZ` is an exact two-word, two-cycle control-flow instruction. The second
normal program read obtains a canonical 12-bit target; the old selected
low-nine AR counter selects target versus fallthrough before a modulo-512
decrement. Its upper-seven-bit preservation is primary-backed; contradictory
later-guide and MAME timing evidence remains visible as `SC-011`/`SC-012`.
`B` is exact opcode `0xf900` and uses the same canonical second-word target
fetch. It unconditionally loads PC and retires at the second sample without
changing other architectural state.
`BGEZ`, `BGZ`, `BLEZ`, `BLZ`, `BNZ`, and `BZ` test signed/zero ACC through
the same two-word/two-cycle state. Both outcomes perform the second program
read; MAME's untaken timing disagreement is `SC-013`.
`BV` tests sticky OV through that state and clears OV only on a taken
target-word retirement. Both outcomes take two cycles; `SC-014` records
MAME's shorter untaken path.
`BIOZ` exposes the raw active-low pin and uses its live value at the second
falling-edge target-word sample. Both paths take two cycles; `SC-015` records
MAME's shorter untaken path.
`CALL` uses exact opcode `0xf800`, reads its canonical target in the second
normal program cycle, pushes opcode-PC+2 onto the four-level 12-bit stack at
retirement, and then selects the target. Stack overflow discards the old
bottom without an exception.
`CALA=0x7f8c` has model/tool evidence for a wrapped opcode-PC+1 stack push,
`ACC[11:0]` target selection, and a two-cycle total. Its second external
program cycle remains unknown, so RTL/native and differential support are
deferred under `OQ-007`.
`PUSH=0x7f9c` and `POP=0x7f9d` have model/tool evidence for their complete
four-level stack transformations, PC+1 sequencing, and two-cycle totals.
TI's general pin rule requires active `MEN` in both non-I/O cycles, but their
per-cycle program address and fetched-word ownership remain unknown, so
RTL/native and differential support are deferred under `OQ-016`/`SC-018`.
`IN`/`OUT` use distinct two-cycle I/O transactions. `TBLR`/`TBLW` use three
cycles: opcode fetch, discarded PC+1 fetch, and ACC-addressed program read or
write, followed by another PC+1 fetch. Table retirement also reproduces the
documented old-stack-bottom loss and old-level-2 duplication.
Both multiply instructions' interrupt-deferral rule has directed
model/RTL/native and explicit-pipeline coverage through the following
instruction. Four actual-core
formal harnesses at 12, 14, 20, and 20 steps check ordinary EINT entry, MPYK
extension, held-low relatching, direct data-memory MPY, a fixed repeated
multiply chain, one indirect MPY old-address/decrement/ARP-replacement case,
and arbitrary clock-enable stalls, with reachable covers.
A separate 40-step bounded harness checks one integrated direct-TBLR sequence
through discarded PC+1, ACC-addressed program read, repeated PC+1 capture,
RAM commit, and following LAC consumption across arbitrary clock-enable
stalls; its complete path is reachable at step 34.
A complementary 40-step direct-TBLW harness uses a verification-only RAM
preload and a phase-3 synchronous program-memory model to prove one exact
write, repeated-fetch replacement, and execution of the rewritten LACK word;
its complete self-modifying path is reachable at step 35.
This is not a complete formal proof; no general pipeline, formally exhaustive
interrupt entry matrix, indirect table proof, general external-memory proof,
or complete pin timing
exists.
The project must not be called instruction-complete or cycle-accurate. Consult
`TASKS.md` and `artifacts/progress.md` for the exact current evidence.
