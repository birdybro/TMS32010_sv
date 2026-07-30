# External bus-cycle research

## Established logical cycles

Program fetch uses the external address bus and `MEN`. `IN` selects one of
eight input ports with `DEN`; `OUT` selects an output port and uses `WE`.
`TBLR` obtains a program-space word under `MEN`; `TBLW` drives a program-space
write under `WE`. TI states that `MEN`, `DEN`, and `WE` are mutually
exclusive
[ti-tms32010-users-guide-spru001b, §§2.3.1–2.3.2 and Figures 2-10/2-11,
printed pp. 2-12, 2-15–2-18 (PDF pp. 36, 39–42)].
**Confidence: VERIFIED_PRIMARY.**

During reset all three strobes are inactive high and the data bus is high
impedance [ti-tms32010-users-guide-spru001b, §2.5, printed p. 2-19 (PDF
p. 43)]. **Confidence: VERIFIED_PRIMARY.**

## Electrical versus architectural timing

Appendix A gives nanosecond setup, hold, access, pulse-width, and delay
limits. Those values will become wrapper constraints and timing-test
parameters; they will not be represented with RTL `#delay` constructs.
Logical phase ordering will be represented with synchronous state.

No READY pin appears in the original pinout. There is therefore no verified
native wait-state transaction to diagram. `TIMING-002` remains a research
task for safe clock/phase adaptation rather than a presumed handshake.

## Diagrams pending transcription

Waveform tables remain pending for normal fetch, `IN`, `OUT`, `TBLR`,
`TBLW`, reset, and interrupt entry. Each final diagram must identify:

- input-clock and `CLKOUT` edge;
- address validity;
- data direction and sampling edge;
- strobe assertion/deassertion;
- pipeline instruction owning the external access;
- citation to the exact timing figure and speed grade.
