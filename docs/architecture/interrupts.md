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

The qualified model/RTL slice implements the architectural `INTM` write for
the exact one-cycle words `DINT=0x7f81` and `EINT=0x7f82`, including
program-only bus behavior and clock-enable stalls. It deliberately has no
`INT` input, pending latch, recognition state, stack entry, or vector fetch
yet. Consequently its cleared `INTM` output after EINT is architectural-state
evidence only: it does not claim the documented following-instruction service
delay. That missing sequencer behavior remains `CTRL-002`/`OQ-004`.

The pin must be low at least 50 ns before falling `CLKOUT`, and a guaranteed
pulse is at least one full `CLKOUT` period. The complete vector-fetch bus trace
and entry latency are still `OQ-004`; no fixed entry cycle count is claimed
yet. The original pin list has no separate interrupt-acknowledge output. A
wrapper must not invent one and call it native without an explicit derivation
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
