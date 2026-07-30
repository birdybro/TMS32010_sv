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

The normal read, table, I/O, reset, and input-sampling figures are now
transcribed in `docs/timing/native_phase_contract.md`. Falling `CLKOUT` is the
read-data, interrupt, and BIO sampling boundary. A normal read changes address
after one falling edge, asserts `MEN` about one quarter-cycle later, and
samples the word at the next falling edge
[ti-tms32010-users-guide-spru001b, Appendix A data sheet, printed
pp. 13–20 (PDF pp. 369–376)]. **Confidence: VERIFIED_PRIMARY.**

No READY pin appears in the original pinout. There is therefore no verified
native wait-state transaction to diagram. `TIMING-002` remains a research
task for safe clock/phase adaptation rather than a presumed handshake.

The partial phase integration test proves that one-cycle `ADD`, `ADDS`, `AND`,
`LAC`, `LAR`, `OR`, `SACL`, `SACH`, `SAR`, `SUB`, `SUBS`, `XOR`, `ZALH`, and `ZALS`
perform the same external program fetch as the other qualified sequential
instructions while their ordinary data operands remain internal,
verification-visible logical reads/writes. No physical `DEN` or `WE` behavior
is claimed from those internal transactions.

## Remaining diagrams

The primary normal fetch, `IN`, `OUT`, `TBLR`, `TBLW`, and reset pin waveforms
are transcribed. Remaining work must identify:

- branch/call/return prefetch address order;
- complete interrupt entry and vector-fetch order;
- any internal conflict that changes an otherwise normal read;
- safe wrapper phase pause, if one exists, despite the absence of READY.
