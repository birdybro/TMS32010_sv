# Interrupt and BIO behavior

## Interrupt input

The active-low `INT` input recognizes a high-to-low transition or low level and
latches a pending request even while interrupts are masked. Service pushes the
current PC, loads program address 2, sets `INTM`, and clears the internal flag
[ti-tms32010-users-guide-spru001b, §2.10 and Figure 2-11, printed
pp. 2-18–2-19 (PDF pp. 42–43)]. **Confidence: VERIFIED_PRIMARY for the
logical request and service effects.** Original SPRU001B draws a logical Sync
FF inside the simplified TMS32010 boundary but Section 2.14 also recommends an
external CLKOUT-clocked flip-flop for asynchronous input. Later mixed-family
SPRU013 likewise requires external NMOS synchronization. The portable core
exposes a digital sampling boundary and does not claim an analog synchronizer;
`SC-039` separately records the guides' conflicting instruction sequence
[ti-tms32010-users-guide-spru001b, Section 2.14 and Figure 2-17, printed
p. 2-24 (PDF p. 48); ti-first-generation-users-guide-1987, Section 3.8,
printed pp. 3-31-3-34 (PDF pp. 60-63)].

Recognition is delayed until:

- an executing multicycle instruction finishes;
- the instruction after `MPY` or `MPYK` finishes; or
- the instruction after `EINT` finishes.

`DINT` and reset set `INTM`; `EINT` clears it. These instructions do not erase
an already latched request
[ti-tms32010-users-guide-spru001b, §2.4.1, printed pp. 2-18–2-19 (PDF
pp. 42–43)]. **Confidence: VERIFIED_PRIMARY.**

Figure 2-12 establishes the normal interrupt fetch/execute order. While
instruction N is fetched, the active-low request becomes valid. The processor
then fetches N+1 while executing N, dummy-fetches N+2 while executing N+1,
fetches vector word 2 while consuming a dummy execution slot, and executes
word 2 afterward. The N+2 word is not executed before entry; because the
current PC is stacked, it is available to be fetched and executed after the
handler returns
[ti-tms32010-users-guide-spru001b, §2.10 and Figure 2-12, printed p. 2-19
(PDF p. 43)]. **Confidence: VERIFIED_PRIMARY.**

The qualified model and partial native RTL now implement the corresponding
retirement-mapped sequence:

1. an active-low sample sets `interrupt_pending_o`, including while `INTM=1`;
2. the current instruction and one already-pipelined following instruction
   complete;
3. a program read at the resulting return PC is marked invalid and cannot
   retire or issue data/I/O traffic;
4. that dummy-read boundary pushes the return PC, sets PC to `0x002`, sets
   `INTM`, and clears the pending latch; and
5. the next program transaction reads vector word 2.

Directed tests cover a one-cycle pulse, a held-low level that relatches after
acknowledge, a pulse retained while masked, entry after EINT plus its required
following instruction, completion of a two-cycle branch before deferral,
MPY/MPYK protection through one additional instruction, reset clearing, and
model/RTL state comparison. Matching 32-case core and explicit-pipeline
matrices drive a one-machine-cycle active-low pulse at each modeled execution
interval of all 15 currently supported
multicycle families: the 11 two-word control-flow operations, `IN`, `OUT`,
`TBLR`, and `TBLW`. Every case asserts the family-specific logical bus shape,
no midinstruction entry, final retirement before deferral, exactly one
protected instruction, a nonretiring dummy fetch at the resolved return PC
with next address `0x002`, and the resulting stack/vector state. The explicit
matrix also checks family-specific MEN/DEN/WE ownership. The native
test independently observes the external address sequence `N`, `N+1`, dummy
return PC, `0x002` with ordinary `MEN` phases
[`sim/interrupt/tb_interrupt_entry.sv`,
`sim/interrupt/tb_interrupt_multicycle_arrivals.sv`,
`sim/interrupt/tb_sequential_pipeline_interrupt_multicycle.sv`,
`sim/interrupt/tb_interrupt_native_sampling.sv`,
`sim/interrupt/tb_interrupt_phase.sv`,
`sim/differential/test_interrupt_model_rtl.py`].
A pair of 39-case core and explicit-pipeline matrices sample a request while
each supported ordinary one-cycle operation retires. They cover every
one-cycle family except
the separately qualified `DINT` and `EINT` mask controls, including both
multiply operations, all three P/ACC operations, the parallel LTA/LTD paths,
SUBC, status load/store, and every ordinary data/address operation. Each case
asserts current-instruction retirement with request capture, exactly one safe
`LARK` protected retirement, a nonexecuting return-PC dummy fetch, and vector
entry with the resolved PC stacked. The explicit matrix additionally checks
that the ordinary program read owns MEN while every family exposes its exact
registered internal-RAM read/write direction and address, including LTD/DMOV's
distinct next-word write and SST's forced page-one destination
[`sim/interrupt/tb_interrupt_one_cycle_arrivals.sv`,
`sim/interrupt/tb_sequential_pipeline_interrupt_one_cycle.sv`].
A separate explicit four-placement test covers request arrival during EINT,
request arrival during DINT, a redundant EINT in the protected N+1 slot, and
DINT in that protected slot. The first three verify the implemented primary-
backed mask/retain/deferral rules. The fourth reproduces the current
PROVISIONAL cancellation policy, proves that the request remains latched, and
services it only after a later EINT plus protected word; it is implementation
evidence, not resolution of `OQ-019`/`SC-039`
[`sim/interrupt/tb_sequential_pipeline_interrupt_mask_controls.sv`].
The native sampling test also begins a held-low request at each of the four
modeled phases. It asserts no pending state before the enabled falling
boundary, checks a stalled phase-2 hold, and then verifies the same protected,
dummy, and vector sequence. These are digital phase-engine assertions, not an
analog claim that a transition without the documented 50 ns setup is
recognized.
The instruction-boundary model and RTL additionally verify the primary-
described `EINT; RET` sequence: RET loads the saved PC and pops the stack
before a previously pending request can schedule another dummy entry. Its
explicit bus sequence follows ADR-0003 at CORROBORATED confidence for RET
under `OQ-007`; exact original-part pin behavior remains unverified.

The explicit pipeline now qualifies Figure 2-12's basic EINT path. EINT
captures exactly one protected instruction. That instruction executes while
N+2 is read under MEN but classified as a dummy; its retirement leaves the
execute slot empty and selects vector 2. The entry interval pushes the
resolved N+2 return PC, masks/acknowledges internally, and captures vector 2
without executing it. A following interval executes the vector. Directed
stalls on both reads prove that protected retirement, entry push, and vector
effects cannot occur early
[`sim/interrupt/tb_sequential_pipeline_interrupt.sv`].

MPY and MPYK in the protected slot explicitly retain that protection through
one additional instruction. Directed tests verify signed P results, MPY's
internal read versus MPYK's program-only cycle, independent fetch stalls, no
early entry, retirement of the instruction following the multiply, dummy
discard, the post-following stacked PC, vector capture, and deferred vector
execution
[`sim/interrupt/tb_sequential_pipeline_interrupt_multiply.sv`].

The 32-case explicit-pipeline matrix pulses active-low INT in every
represented execution interval of B, BANZ, BV, BIOZ, CALL, all six
accumulator branches, IN, OUT, TBLR, and TBLW. It checks the family-specific
MEN/DEN/WE shape, no midinstruction entry, completion before service, one
protected retirement, dummy discard, resolved return PC, stack entry,
acknowledge state, and vector capture. A separate core matrix provides the
same interval coverage at the architectural interface
[`sim/interrupt/tb_sequential_pipeline_interrupt_multicycle.sv`,
`sim/interrupt/tb_interrupt_multicycle_arrivals.sv`].

A bounded actual-core harness independently crosses the six accumulator-
conditional branch families, the negative/zero/positive ACC equivalence
classes, and both represented branch intervals. A fixture-local truth table
checks taken and untaken resolution without reusing the RTL predicate helper;
the proof also checks ACC preservation, no midinstruction entry, one protected
instruction, the outcome-specific dummy return PC, stack entry, mask/pending
effects, and arbitrary bounded clock-enable stalls. All 36 complete selector
tuples reach vector entry at cover step 9 through depth 20
[`formal/tms32010_interrupt_accumulator_branches.sby`]. This is finite logical
implementation evidence only. It does not promote ADR-0002's combined branch
interval mapping beyond `INFERRED`, qualify original-package pins, or replace
the explicit-pipeline bus matrix.

A companion actual-core harness crosses both represented intervals with
zero/nonzero BANZ, clear/set BV, high/low BIOZ, and CALL. It checks the
family-specific state effects as well as selected PC, protected/dummy
ownership, interrupt state, and CALL/interrupt stack ordering. All 14 complete
scenario/arrival tuples reach vector entry at cover step 9 through depth 20
[`formal/tms32010_interrupt_banz_bv_bioz_call.sby`]. The BIO cases use stable
pin levels; directed simulation remains the evidence for a pin transition at
the live target-word sample. This finite proof does not promote ADR-0002's
combined interval mapping beyond `INFERRED` or qualify package/electrical
timing.

A separate actual-core harness crosses both represented IN/OUT intervals with
both directions, both old ARP selections, all three legal single-update
choices, and ARP preserve/switch. It proves exact callback/RAM ownership,
old-address transfer ordering, post-transfer AR/ARP effects, one protected
readback, dummy return-PC ownership, and vector entry. All 48 complete tuples
reach cover step 13 through depth 22 under arbitrary clock-enable stalls
[`formal/tms32010_interrupt_io_indirect.sby`]. This is bounded logical core
evidence, not peripheral, explicit-pipeline subphase, package-pin, electrical,
or unbounded proof; simultaneous increment/decrement remains `OQ-010`.

A complementary actual-core harness crosses all three represented TBLR/TBLW
intervals with both directions, both old ARP selections, all three legal
single-update choices, and ARP preserve/switch. It proves discarded-prefetch
ownership, exact RAM/program ownership and data, repeated-prefetch-only AR/ARP
effects, one protected readback, dummy return-PC ownership, and vector entry.
All 72 complete tuples reach cover step 15 through depth 28 under arbitrary
clock-enable stalls [`formal/tms32010_interrupt_table_indirect.sby`]. This is
bounded logical fixture evidence, not arbitrary memory, nontrivial prior-stack,
explicit-pipeline subphase, package-pin, electrical, simultaneous-update, or
unbounded proof.

An explicit-pipeline direct-TBLW harness independently crosses its three
documented intervals with all four represented native request phases while
placing exactly one symbolic single-clock pause between formal steps 10 and
54. Through depth 57 it proves one RAM-0-to-program-`0x017` phase-3 write,
TBLW completion before service, protected `LACK 0x66`, discarded dummy fetch
and pushed return PC `0x014`, mask/pending effects, and vector `LACK 0x55`;
all twelve covers reach solver step 55
[`formal/tms32010_pipeline_table_write_interrupt.sby`]. This is a bounded
held-level logical composition. It does not prove arbitrary composed pause
histories, original-package interrupt setup/hold, a synchronizer or edge
latch, package delay, electrical timing, other table controls, or arbitrary
programs/memory.

A separate four-case explicit-pipeline test pulses INT in each of CALA's and
RET's two execution intervals. It proves that the request may latch during the
discarded sequential or selected-target read but cannot retire, mutate the
stack, or enter service midinstruction. Selected-target capture completes the
computed control flow, exactly one protected instruction retires, and only
then do dummy/vector ownership and interrupt stack entry proceed
[`sim/interrupt/tb_sequential_pipeline_interrupt_computed.sv`]. The external
address mapping remains ADR-0003 CORROBORATED for RET and INFERRED for CALA,
not original-part physical-pin proof.

This remains an incomplete pipeline claim. The explicit tests do not cover
DINT across every multicycle interval and digital subphase, the `SC-039`
original-versus-later interrupt sequence, external synchronization, physical
setup behavior, PUSH/POP cycles, physical confirmation of
ADR-0003, or analog input timing (`CTRL-002`, `OQ-004`,
`OQ-007`, `OQ-016`).

The current behavior when `DINT` occupies the already-pipelined protected
slot cancels entry, retains the request, and leaves it masked. Figure 2-11's
mode gate supports that ordering, but the located original prose does not
explicitly order DINT's write against an already active internal interrupt
processor. MAME cannot express the overlapping Figure 2-12 boundary; pinned
IKA instead represents entry-wins from its old-mask combinational request.
The stable original-device program and capture procedure are in
`docs/research/dint_interrupt_race_experiment.md`. The policy is therefore
PROVISIONAL under `OQ-019`, not a silicon-verified fact.

The pin must be low at least 50 ns before falling `CLKOUT`, and a guaranteed
pulse is at least one full `CLKOUT` period. The external fetch trace is now
primary-transcribed, but no nanosecond pin delay is modeled in RTL. The
original pin list has no separate interrupt-acknowledge output: the guide's
acknowledge is an internal signal that presets INTM and clears the flag. A
wrapper must not invent an acknowledge pin and call it native
[ti-tms32010-users-guide-spru001b, Appendix A interrupt timing, printed
data-sheet p. 20 (PDF p. 376)]. **Confidence: VERIFIED_PRIMARY.**

## BIO input

`BIO` is an active-low, nonlatched input tested by `BIOZ`. TI says it is
examined during every clock cycle; the branch occurs when the sampled value is
low [ti-tms32010-users-guide-spru001b, §2.4.2, printed p. 2-18 (PDF p. 42)].
**Confidence: VERIFIED_PRIMARY.**

Appendix A places its 50 ns setup requirement before falling `CLKOUT` and
requires a one-cycle low pulse for guaranteed recognition
[ti-tms32010-users-guide-spru001b, Appendix A BIO timing, printed data-sheet
p. 20 (PDF p. 376)]. **Confidence: VERIFIED_PRIMARY.**

The Hard Drivin' sound schematic places external flip-flop logic in the BIO
path, so that board-level synchronization is wrapper behavior rather than
evidence that the processor pin itself latches BIO
[atari-driver-sound-board-schematic, drawing A044427, sheet 4 of 10, PDF
pp. 7–8]. **Confidence: VERIFIED_PRIMARY for the wiring; signal semantics
still under review.**
