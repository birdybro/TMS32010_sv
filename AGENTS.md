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

As of 2026-07-30 the machine-readable database, independent model, local
tools, RTL, and seeded differential boundary support fifty-two instructions:
`ADD`, `ADDS`, `AND`, `APAC`, `B`, `BANZ`, `BGEZ`, `BGZ`, `BIOZ`, `BLEZ`, `BLZ`, `BNZ`, `BV`, `BZ`, `CALL`, `DINT`, `DMOV`, `EINT`, `LAC`, `LACK`, `LAR`, `LARK`, `LARP`, `LDP`,
`LDPK`, `LST`, `LT`, `LTA`, `LTD`, `MAR`, `MPY`, `MPYK`, `NOP`, `OR`,
`IN`, `OUT`, `PAC`, `ROVM`, `SACL`, `SACH`, `SAR`, `SOVM`, `SPAC`, `SUB`,
`SUBC`, `SUBS`, `TBLR`, `TBLW`, `XOR`, `ZAC`, `ZALH`, and `ZALS`. This includes
`ADD`/`ADDS`/`AND`/`DMOV`/`LAC`/`LAR`/`LDP`/`LST`/`LT`/`LTA`/`LTD`/`MPY`/`OR`/`SUB`/`SUBC`/`SUBS`/`XOR`/`ZALH`/`ZALS`
reads and `DMOV`/`LTD`/`SACL`/`SACH`/`SAR` writes in a 144-word internal RAM, plus SACH output shifts
0, 1, and 4. ADD and SUB have directed sign-extension, shift, positive/negative
wrap/saturation, and sticky-OV evidence. ADDS and SUBS have directed unsigned
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
matches TI Figure 2-12's external address order. Complete fetch/execute
overlap, exhaustive multicycle arrival coverage, RET resumption, and the
provisional DINT-at-final-boundary ordering remain outside the qualified
boundary under `OQ-004`/`OQ-019`.
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
`IN`/`OUT` use distinct two-cycle I/O transactions. `TBLR`/`TBLW` use three
cycles: opcode fetch, discarded PC+1 fetch, and ACC-addressed program read or
write, followed by another PC+1 fetch. Table retirement also reproduces the
documented old-stack-bottom loss and old-level-2 duplication.
Both multiply instructions' interrupt-deferral rule has directed
model/RTL/native coverage through the following instruction. A 12-step
bounded formal harness checks the EINT/protected-instruction/dummy/vector
slice with arbitrary clock-enable stalls and reaches the vector cover point.
This is not a complete formal proof; no general pipeline, exhaustive
interrupt entry matrix, or complete pin timing exists.
The project must not be called instruction-complete or cycle-accurate. Consult
`TASKS.md` and `artifacts/progress.md` for the exact current evidence.
