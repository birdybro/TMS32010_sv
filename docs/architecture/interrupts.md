# Interrupt and BIO behavior

## Interrupt input

The active-low `INT` input is synchronized internally. TI describes a request
as a high-to-low transition or a low level and latches a pending request even
while interrupts are masked. Service pushes the current PC, loads program
address 2, sets `INTM`, and clears the internal interrupt flag
[ti-tms32010-users-guide-spru001b, §2.4.1 and Figure 2-11, printed
pp. 2-18–2-19 (PDF pp. 42–43)]. **Confidence: VERIFIED_PRIMARY.**

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
DINT's provisional cancellation at every placement, physical
synchronizer/setup behavior, PUSH/POP cycles, physical confirmation of
ADR-0003, or analog input timing (`CTRL-002`, `OQ-004`,
`OQ-007`, `OQ-016`).

The current behavior when `DINT` occupies the already-pipelined protected
slot cancels entry, retains the request, and leaves it masked. Figure 2-11's
mode gate and pinned MAME behavior corroborate that ordering, but the located
original prose does not explicitly order DINT's write against an already
active internal interrupt processor. The policy and targeted test are
therefore PROVISIONAL under `OQ-019`, not a silicon-verified fact.

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
