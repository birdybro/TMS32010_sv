# Pipeline and instruction overlap

## Established behavior

The TMS32010 overlaps instruction fetch with execution of the previously
fetched instruction. TI describes most instructions as one word and one
cycle, with branch, I/O, stack, and table operations consuming additional
cycles [ti-tms32010-users-guide-spru001b, §2.1 and Table 3-2, printed
pp. 2-1, 3-5–3-7 (PDF pp. 25, 55–57)]. **Confidence: VERIFIED_PRIMARY.**

A machine cycle is one `CLKOUT` period and four input-clock periods. The
baseline 20 MHz input therefore corresponds to a nominal 5 MHz machine-cycle
rate. Speed-grade limits and electrical edge requirements belong in wrapper
constraints, not synthesizable delay statements
[ti-tms32010-users-guide-spru001b, Appendix A data sheet, clock characteristics
and AC timing tables]. **Confidence: VERIFIED_PRIMARY.**

Figure 2-2 makes the overlap structurally explicit. At falling `CLKOUT`, the
PC selects the next instruction to prefetch while the previously fetched
instruction is decoded and begins execution. The fetch continues while that
instruction executes, and the following fetch can begin while work from the
two preceding instructions remains in the internal pipeline
[ti-tms32010-users-guide-spru001b, §2.1.1 and Figure 2-2, printed p. 2-3
(PDF p. 27)]. **Confidence: VERIFIED_PRIMARY.**

Consequently, a fetched word and the instruction effects observed during the
same external program-read cycle are not generally the same pipeline item.
The final sequencer must retain distinct fetch and execute validity/address
state and must flush or suppress fetched words for branches, table operations,
and interrupts. Merely renaming the current falling-edge execution boundary
would not implement TI's pipeline.

ADR-0002 therefore requires explicit fetched-word and execute-slot validity,
addresses, and flush ownership. The standalone synthesizable
`tms32010_fetch_execute` register implements only that boundary: executable
fetches may fill an empty slot or replace a completed instruction;
operand/dummy reads carry no valid instruction; an incomplete instruction
cannot be overwritten; and a redirect flushes the old path. Its directed test
covers reset priming, Figure 2-2 sequential replacement, a retained
multicycle slot, branch redirection, and the Figure 2-12 dummy/vector
transition. These tests prove the building block independently of its narrow
core integration
[`docs/decisions/ADR-0002-fetch-execute-separation.md`,
`sim/unit/tb_fetch_execute.sv`].
A 12-step bounded proof additionally checks exact arbitrary-word capture,
non-boundary stability, incomplete-slot retention, completion/replacement,
bubbles, and reset/flush invalidation under the two documented legal-input
contracts. Its step-7 cover traverses prime, stall, replacement, flush, and
target capture. These remain standalone-register properties, not integrated
pipeline evidence
[`formal/tms32010_fetch_execute.sby`, `formal/README.md`].

The first core-connected use is
`tms32010_sequential_pipeline_slice`. It gives the native program bus a fetch
address separate from the core PC. Fetch 0 primes an empty slot; while fetch
N+1 runs, the core owns and retires one-cycle instruction N. Arbitrary
clock-enable stalls hold both addresses, and recognized reset empties both
domains. Exact `B`, `BANZ`, `BV`, `BIOZ`, `CALL`, and the six
accumulator-conditional branches are integrated multicycle cases.
After a branch prefetch enters execute ownership, its operand fetch is
explicitly nonexecutable execution cycle 1. B redirects unconditionally;
BANZ selects from the old selected `AR[8:0]`; the accumulator family selects
from the unchanged full 32-bit ACC; BV selects from old sticky OV; BIOZ
samples the live active-low pin at operand completion. The selected
instruction fetch is execution cycle 2, and only its boundary retires the
branch and captures that instruction. BANZ's selected counter decrements
modulo 512 only at this retirement boundary, taken BV clears OV only there,
and BIOZ retains its sampled decision through the selected fetch. Directed
tests check B, both BANZ/BV/BIOZ outcomes, all six ACC predicates in both
directions, target/fallthrough fetch stalls, no early fetched-instruction
effect, architectural-source preservation, and conservative parking on
malformed operands. `CALL` uses the same operand/selected-fetch ownership and
pushes only at selected-target capture. `IN` and `OUT` retain the execute
slot across Figure 2-9's two execution intervals: cycle 1 multiplexes the
encoded port, suppresses MEN, and asserts only DEN or WE; cycle 2 suppresses
both I/O strobes and fetches PC+1 under MEN. IN samples the live external
word at the cycle-1 falling boundary; OUT holds the old resolved RAM word
through that boundary. Architectural RAM/AR/ARP effects, retirement, and
replacement with PC+1 occur only at the cycle-2 boundary, so the captured
following instruction cannot execute early. `TBLR` and `TBLW` retain the
execute slot across Figure 2-10's three execution intervals. Cycle 1 fetches
PC+1 under MEN but marks it nonexecutable and discards it. Cycle 2 addresses
program space with the captured `ACC[11:0]`; TBLR samples a program word
under MEN, whereas TBLW drives the old resolved RAM word under WE. Cycle 3
repeats the PC+1 MEN read. Only that last boundary commits TBLR RAM data,
indirect AR/ARP changes, documented stack-bottom duplication, retirement, and
replacement with the repeated word. Stalls hold all addresses, strobes, data,
and architectural state. A self-modifying TBLW test proves that the first
PC+1 input is discarded and the rewritten repeated word is the one captured
and later executed. Figure 2-12 is mapped explicitly
for the qualified interrupt path: the protected instruction retains execute
ownership while N+2 is read under MEN but marked nonexecutable; its boundary
empties the slot and selects vector 2. Entry pushes the resolved return PC
while vector 2 is fetched into that empty slot, without retirement or vector
effects. A following interval executes the vector. Directed stalls cover both
the N+2 and vector reads and prove no early retirement, stack push, or vector
effect. If MPY or MPYK occupies the protected slot, explicit ownership remains
set through one additional instruction; directed tests cover both signed
products, logical bus shapes, stalls, dummy discard, and the post-following
return PC. Another
directed test checks the sequential boundary explicitly. A differential test runs
the existing 46-word stream spanning all 41 qualified one-cycle operation
families through both wrappers and compares complete exposed architectural
state one retirement apart
[`sim/bus/tb_sequential_pipeline_slice.sv`,
`sim/bus/tb_sequential_pipeline_b.sv`,
`sim/bus/tb_sequential_pipeline_banz.sv`,
`sim/bus/tb_sequential_pipeline_accumulator_branches.sv`,
`sim/bus/tb_sequential_pipeline_bv.sv`,
`sim/bus/tb_sequential_pipeline_bioz.sv`,
`sim/bus/tb_sequential_pipeline_call.sv`,
`sim/bus/tb_sequential_pipeline_io.sv`,
`sim/bus/tb_sequential_pipeline_table.sv`,
`sim/interrupt/tb_sequential_pipeline_interrupt.sv`,
`sim/interrupt/tb_sequential_pipeline_interrupt_multiply.sv`,
`sim/bus/tb_sequential_pipeline_differential.sv`].

This wrapper is intentionally a qualification slice. It parks at phase zero
when the execute slot contains any other multicycle, reserved, or
invalid-address word; it does not claim that parking is TMS32010 hardware
behavior. **Confidence:
VERIFIED_PRIMARY for the required overlap; INFERRED for exact
B/BANZ/BV/BIOZ/CALL/accumulator-branch interval ownership because no
dedicated branch/call waveform has been located; VERIFIED_PRIMARY for the
IN/OUT and TBLR/TBLW interval mappings in §§2.8.1–2.8.2 and Figures 2-9–2-10;
implementation behavior
VERIFIED_PRIMARY for Figure 2-12 interrupt ownership; VERIFIED_SIMULATION
only within this stated slice.**

## Required implementation model

The portable RTL will use one FPGA clock and explicit phase/state enables. It
will not generate clocks in logic. A future internal FPGA clock may be faster
than the emulated crystal input only if:

1. each documented processor phase is explicit;
2. native bus outputs change on the documented boundaries;
3. instruction-cycle counts are measured in architectural machine cycles;
4. interrupt and BIO sampling boundaries remain observable.

This is an implementation policy, not a claim about the original internal
gate topology.

## Unresolved sequences

Normal read, table, I/O, and reset pin sequences are transcribed in
`docs/timing/native_phase_contract.md`. Their bus order is qualified,
but exact pipeline ownership remains to be resolved except for sequential
one-cycle instructions, exact `B`/`BANZ`/`BV`/`BIOZ`/`CALL`, and the six
accumulator branches, plus `IN`/`OUT` and `TBLR`/`TBLW`:

- CALA and RET have model-qualified state/cycle behavior but externally
  unresolved second cycles. For model-qualified `PUSH`/`POP`, TI's general
  pin rule requires `MEN` on both non-I/O execution cycles and its
  architecture prose says PC always addresses program memory, but no located
  waveform identifies address progression or fetched-word validity. The
  conflict with an independent implementation's idle first microcycle and a
  reproducible pin-capture plan are recorded under `SC-018`/`OQ-016`;
- interrupt ownership beyond the explicit EINT/protected-word/discarded-N+2/
  vector path, MPY/MPYK protected-slot extension, and matching 32-case
  core/explicit arrival matrices for the 15 supported multicycle families
  (`OQ-004`);
- any external cycle stretching (`OQ-001`).

Until these rows have cited diagrams and explicit-pipeline automated traces,
the project does not claim cycle accuracy.

## Interrupt pipeline sequence

SPRU001B Figure 2-12 supplies the missing normal-entry sequence. An interrupt
that becomes active during fetch N does not discard N or N+1. The fetch row is
N, N+1, dummy N+2, vector 2; the aligned execute row is N, N+1, dummy, vector
2. The current return PC is therefore N+2, and the dummy-fetched word resumes
after the handler returns
[ti-tms32010-users-guide-spru001b, §2.10 and Figure 2-12, printed p. 2-19
(PDF p. 43)]. **Confidence: VERIFIED_PRIMARY.**

The partial phase wrapper now verifies the external program sequence and
architectural entry state. Its implementation state allows one more
instruction retirement, performs a non-retiring program read at the return
PC, then selects vector 2. A focused model/RTL differential compares PC,
ACC, stack top, INTM, pending flag, cycle total, and retirement for EINT,
the protected instruction, entry, and vector word.

The wrapper still executes each supported fetched word at its sample boundary;
it does not yet contain separate general fetch and execute registers. Thus the
address sequence is qualified, while the complete overlapped execution row is
still an implementation requirement rather than a cycle-accuracy claim.
`OQ-004` retains that distinction. A native-phase test now drives INT low
starting at each of the four modeled subphases and holds it through the next
enabled falling boundary. The request remains invisible before that boundary,
including across a five-FPGA-clock stall in phase 2, then follows the
protected-instruction/dummy/vector sequence. This qualifies digital phase
ownership only; it does not model the data sheet's 50 ns setup aperture or
prove how an asynchronous transition maps into a physical synchronizer.
Matching 32-case core and explicit-pipeline matrices exhaust arrival at every
represented execution interval of the 11 supported two-word control-flow
families, IN, OUT, TBLR, and TBLW. The explicit matrix checks native strobes,
no midinstruction entry, one protected retirement, dummy discard, stack and
acknowledge effects, and vector capture. Neither matrix models a physical
input synchronizer or setup aperture.

Exact `BANZ` now has the same explicit two-interval ownership structure as B.
Opcode-prefetch completion places `0xf400` in the execute slot. Its canonical
PC+1 operand fetch is nonexecutable execution cycle 1. The old selected
`AR[8:0]` chooses the next fetch—target when nonzero, opcode PC+2 when
zero—without yet changing the register. That selected instruction fetch is
execution cycle 2. At its falling-edge boundary BANZ decrements the selected
nine-bit counter modulo 512, retires, and captures the fetched instruction
without executing it. Each interval uses the normal four-subphase `MEN`
sequence; clock-enable stalls hold the active phase, address, ownership, PC,
and AR
[ti-tms32010-users-guide-spru001b, §§2.1.1, 2.4.1, and 2.6.1, Table 3-2,
and `BANZ`, printed pp. 2-2, 2-9–2-10, 2-13, 3-6, and 3-16
(PDF pp. 26, 33–34, 37, 56, and 66)]. **Confidence: VERIFIED_PRIMARY for
the component facts; INFERRED for this combined execute-interval mapping
because no dedicated BANZ pin waveform has been located.**

Unconditional `B` supplies the first integrated multicycle ownership trace.
The `0xf900` opcode prefetch completes at the boundary where B enters the
execute slot. During execution cycle 1, the canonical operand is read at
PC+1 and redirects the next bus interval. During execution cycle 2, the
target instruction is fetched while B retains execute ownership. At that
second interval's falling-edge boundary PC receives the target, B retires,
and the fetched target enters—but does not yet execute from—the execute
slot. A clock-enable stall holds that target phase without architectural
progress
[ti-tms32010-users-guide-spru001b, Table 3-2 and `B`, printed pp. 3-6 and
3-15 (PDF pp. 56 and 65), plus §2.1.1 and Figure 2-2, printed p. 2-3
(PDF p. 27)]. **Confidence: VERIFIED_PRIMARY for the component facts;
INFERRED for this combined execute-interval mapping because no dedicated B
pin waveform has been located.**

The explicit pipeline gives `BGEZ`, `BGZ`, `BLEZ`, `BLZ`, `BNZ`, and `BZ`
the same ownership shape as BANZ. Opcode-prefetch completion enters branch
ownership; the nonexecutable PC+1 operand fetch is execution cycle 1 and uses
the unchanged full 32-bit ACC to select target or PC+2; execution cycle 2
fetches that selected instruction. Only the selected-fetch boundary retires
the branch and captures—but does not execute—the fetched word. A directed
matrix covers both outcomes for every predicate, zero/positive/negative ACC,
ACC preservation, stalls on both selected paths, effect deferral, and
malformed-operand parking. Legacy tests retain additional native transaction
coverage. Pinned MAME's one-cycle untaken abstraction is disclosed in
`SC-013`, not adopted
[ti-tms32010-users-guide-spru001b, Table 3-2 and individual branch pages,
printed pp. 3-6, 3-17–3-18, 3-20–3-22, and 3-24
(PDF pp. 56, 67–68, 70–72, and 74)]. **Confidence: VERIFIED_PRIMARY for
component facts; INFERRED for the combined execute-interval mapping;
VERIFIED_SIMULATION for the implementation.**

The explicit pipeline gives `BV` the same ownership shape as the other
integrated conditional branches. Opcode-prefetch completion enters BV
ownership; the nonexecutable PC+1 operand fetch is execution cycle 1 and uses
old sticky OV to select target or PC+2 without clearing it; execution cycle 2
fetches that selected instruction. Only the selected-fetch boundary retires
BV and captures—but does not execute—the fetched word. OV clears there only
on the taken path. A directed test covers both old-OV outcomes, stalls both
selected paths, proves OV and execute ownership stable before retirement,
defers selected-instruction effects, and parks a malformed operand before OV
mutation. Legacy tests retain additional native transaction coverage. MAME's
shorter untaken abstraction is disclosed in `SC-014`, not adopted
[ti-tms32010-users-guide-spru001b, Table 3-2 and `BV`, printed pp. 3-6 and
3-23 (PDF pp. 56 and 73)]. **Confidence: VERIFIED_PRIMARY for component
facts; INFERRED for the combined execute-interval mapping;
VERIFIED_SIMULATION for the implementation.**

The explicit pipeline gives `BIOZ` the same ownership shape as the other
integrated conditional branches. Opcode-prefetch completion enters BIOZ
ownership; the nonexecutable PC+1 operand fetch is execution cycle 1 and the
raw active-low pin meeting setup at its falling boundary selects target or
PC+2. Execution cycle 2 fetches that selected instruction. Only the
selected-fetch boundary retires BIOZ and captures—but does not execute—the
fetched word. The wrapper retains the sampled decision, not an opcode-time
pin latch, so later BIO changes cannot redirect an already selected fetch.
A directed test presents the opposite level at opcode prefetch, changes BIO
during an operand stall, reverses it after operand completion, stalls both
selected paths, defers selected-instruction effects, and parks a malformed
operand before selection. Legacy tests retain additional native transaction
coverage. MAME's shorter untaken abstraction is disclosed in `SC-015`, not
adopted
[ti-tms32010-users-guide-spru001b, §§2.9 and 2.6.1, Table 3-2, `BIOZ`, and
Appendix A BIO timing, printed pp. 2-13, 2-18, 3-6, 3-19, and data-sheet 20
(PDF pp. 37, 42, 56, 69, and 376)]. **Confidence: VERIFIED_PRIMARY for BIO
sampling and component facts; INFERRED for the combined execute-interval
mapping; VERIFIED_SIMULATION for the implementation.**

Exact `CALL` now follows explicit execute ownership. Opcode `0xf800`
prefetches at opcode PC and enters the execute slot. The nonexecutable
canonical PC+1 operand fetch is execution cycle 1 and selects the target
instruction fetch for execution cycle 2. CALL remains the execute owner until
that selected word is captured; only then does it retire, push opcode-PC+2
onto the four-level stack, and transfer PC to the target. The target word
enters the execute slot but cannot execute until the following fetch
interval. Directed tests hold both operand and target phases, prove no early
push, chain a nested CALL to verify return-address ordering, preserve all
exposed non-stack state, defer the selected target's effect, and park a
malformed operand before a push. Legacy tests retain old-bottom discard and
12-bit return-address-wrap coverage
[ti-tms32010-users-guide-spru001b, §§2.6.1–2.6.2, Table 3-2, and `CALL`,
printed pp. 2-13–2-14, 3-6, and 3-26
(PDF pp. 37–38, 56, and 76)]. **Confidence: VERIFIED_PRIMARY for instruction
effects and component facts; INFERRED for the combined execute-interval
mapping; VERIFIED_SIMULATION for the stated implementation.**

`IN` and `OUT` are one-word instructions whose two documented execution
intervals follow the opcode-prefetch boundary. Execution cycle 1 suppresses
MEN, drives the three-bit port on A2–A0 with A11–A3 low, and asserts DEN for
IN or WE for OUT. Execution cycle 2 is the next-instruction prefetch. At the
port sample, IN captures the live external word for the pre-update
internal-RAM address; OUT completes the selected internal-RAM-word transfer.
The explicit pipeline retains the IN/OUT execute slot, suppresses logical I/O
during cycle 2, fetches PC+1 under MEN, and only then commits RAM/AR/ARP
effects, retires, and captures that fetched word without executing it. This
commit placement is an RTL ownership choice at the only architectural
boundary before the following instruction; the pin sample remains at the
primary-defined cycle-1 falling edge. Directed tests independently stall both
cycles, require MEN, DEN, and WE mutual exclusion, prove live-input sampling
and stable output data, reject early state changes or fetched-word effects,
and park an invalid RAM address before any native strobe
[ti-tms32010-users-guide-spru001b, §2.8.1, Figure 2-9, Table 3-2,
`IN`/`OUT`, and Appendix A I/O timing, printed pp. 2-15–2-16, 3-6, 3-30,
and 3-47 plus data-sheet pp. 17–18
(PDF pp. 39–40, 56, 80, 97, and 373–374)]. **Confidence:
VERIFIED_PRIMARY for logical ordering, native pin phases, and execute
interval ownership; VERIFIED_SIMULATION for explicit and legacy
implementations.**

`TBLR` and `TBLW` have three execution intervals after their opcode-prefetch
boundary: a discarded PC+1 prefetch, an ACC-addressed table transfer, and the
repeated PC+1 instruction prefetch. The explicit pipeline retains the table
opcode across all three intervals. It captures `ACC[11:0]` and the old
resolved internal-data address, marks the first PC+1 read nonexecutable,
performs TBLR MEN or TBLW WE at the captured table address, and commits RAM or
program memory, indirect updates, the documented final stack-bottom
duplication, retirement, and execute-slot replacement only at the repeated
PC+1 sample. Stalls hold every interval without architectural progress; a
self-modifying TBLW test proves that the discarded old PC+1 word cannot
execute after replacement.

A 40-step bounded check over the actual sequential-pipeline hierarchy
independently asserts one direct TBLR path: `LACK 4` supplies the table
address, program word `0x1234` is transferred to RAM, PC+1 is repeated, and
the following `LAC 0` consumes that committed word. Arbitrary clock-enable
stalls preserve all checked bus and architectural state, and the complete
path reaches cover step 34.

A complementary 40-step harness checks one direct self-modifying TBLW path.
Its verification-only preload places `LACK 0x44` in RAM word 0, and its
explicit program-memory fixture commits writes only at an enabled active
phase-3 boundary. The old PC+1 ZAC remains visible through discard and stalls;
TBLW then drives address 2 and `0x7e44` under WE exactly once, repeats address
2 under MEN, and captures and executes the replacement word. The complete
path reaches cover step 35. These are two fixed direct scenarios, not proofs
of indirect table addressing, arbitrary programs or memory systems, or the
general pipeline
[ti-tms32010-users-guide-spru001b, §2.8.2, Figure 2-10, and
`TBLR`/`TBLW`, printed pp. 2-17 and 3-64–3-67
(PDF pp. 41 and 114–117);
`sim/bus/tb_sequential_pipeline_table.sv`;
`formal/tms32010_pipeline_table.sby`;
`formal/tms32010_pipeline_table_write.sby`; `formal/README.md`].
**Confidence: VERIFIED_PRIMARY for source ordering and native pin ownership;
VERIFIED_SIMULATION for explicit execute ownership; bounded formal evidence
for the two stated direct scenarios.**

`SUBC` is documented as one cycle, but TI explicitly prohibits the immediately
following instruction from using ACC. This exposes a result-availability
constraint that the current instruction-boundary core cannot physically
characterize. Qualified programs insert an ACC-free NOP after every SUBC;
the core's immediate result commit is an implementation convenience, not a
claim about a violating instruction sequence. The missing silicon behavior is
tracked as `OQ-017`
[ti-tms32010-users-guide-spru001b, `SUBC`, printed p. 3-61 (PDF p. 111)].
**Confidence: VERIFIED_PRIMARY for the scheduling restriction; UNKNOWN for
violation behavior.**

`PUSH` and `POP` are primary-defined one-word, two-cycle instructions. Their
architectural stack transformations and numeric cycle totals are now
model/tool-qualified, but the located original documentation contains no
dedicated external-bus waveform for their second cycle. Do not implement an
RTL/native extra cycle by merely refetching the same opcode or by assuming a
next-word prefetch: both would create an unsupported external sequence. This
is tracked as `OQ-016`
[ti-tms32010-users-guide-spru001b, Table 3-2 and `POP`/`PUSH`, printed
pp. 3-7 and 3-49–3-50 (PDF pp. 57 and 99–100)].
