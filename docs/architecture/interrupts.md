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

The precise sampled edge, vector-fetch bus trace, and entry latency are still
`OQ-004`; no fixed cycle count is claimed yet. The original pin list has no
separate interrupt-acknowledge output. A wrapper must not invent one and call
it native without an explicit derivation.

## BIO input

`BIO` is an active-low, nonlatched input tested by `BIOZ`. TI says it is
examined during every clock cycle; the branch occurs when the sampled value is
low [ti-tms32010-users-guide-spru001b, §2.4.2, printed p. 2-18 (PDF p. 42)].
**Confidence: VERIFIED_PRIMARY.**

The Hard Drivin' sound schematic places external flip-flop logic in the BIO
path, so that board-level synchronization is wrapper behavior rather than
evidence that the processor pin itself latches BIO
[atari-driver-sound-board-schematic, drawing A044427, sheet 4 of 10, PDF
pp. 7–8]. **Confidence: VERIFIED_PRIMARY for the wiring; signal semantics
still under review.**
