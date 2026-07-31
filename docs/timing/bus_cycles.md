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

`PUSH` and `POP` each consume two cycles despite carrying only one program
word. No located original-part timing figure shows whether `MEN` is inactive,
the current address is held, or the next instruction is prefetched during the
extra internal cycle. The IN/OUT two-cycle figures cannot prove stack-cycle
behavior because those instructions use their extra cycle for an external
data transfer. Native stack bus sequencing remains `OQ-016`; no waveform is
invented here.

The partial phase integration test proves that one-cycle `ADD`, `ADDS`, `AND`,
`DMOV`, `LAC`, `LAR`, `LDP`, `LST`, `LT`, `LTA`, `LTD`, `MPY`, `OR`, `SACL`, `SACH`, `SAR`, `SUB`, `SUBS`, `XOR`, `ZALH`,
and `ZALS`
perform the same external program fetch as the other qualified sequential
instructions while their ordinary data operands remain internal,
verification-visible logical reads/writes. No physical `DEN` or `WE` behavior
is claimed from those internal transactions.

The phase test verifies LST's internal status-word read and architectural
status commit during one ordinary external program fetch. The operation
introduces no external data or I/O strobe
[ti-tms32010-users-guide-spru001b, `LST`, printed p. 3-38 (PDF p. 88)].
**Confidence: VERIFIED_PRIMARY for the bus boundary; indirect next-ARP
precedence remains PROVISIONAL under `OQ-015`.**

The phase test verifies that `LTA` performs its internal data-word read and
previous-P accumulation during the ordinary one-cycle external program fetch;
it introduces no external data-memory pin transaction
[ti-tms32010-users-guide-spru001b, `LTA`, printed p. 3-40 (PDF p. 90)].
**Confidence: VERIFIED_PRIMARY.**

The same phase test verifies DMOV's simultaneous internal source read and
next-address write, unchanged copied data, and preserved arithmetic/T state
during one ordinary external program fetch. Both RAM addresses are logical
verification signals; DMOV introduces no external data-memory pin transaction
[ti-tms32010-users-guide-spru001b, `DMOV`, printed p. 3-28 (PDF p. 78);
ti-first-generation-users-guide-1987, §3.4.3, printed p. 3-13 (PDF p. 42)].
**Confidence: VERIFIED_PRIMARY.**

The phase test also verifies LTD's simultaneous internal source read and
next-address write, unchanged copied data, T load, and previous-P accumulation
during one ordinary external program fetch. Both internal RAM addresses are
logical verification signals; LTD introduces no external data-memory pin
transaction
[ti-tms32010-users-guide-spru001b, `LTD`, printed p. 3-41 (PDF p. 91);
ti-first-generation-users-guide-1987, §3.4.3, printed p. 3-13 (PDF p. 42)].
**Confidence: VERIFIED_PRIMARY.**

The same phase test verifies that `MAR` performs neither a logical data read
nor write while retaining the normal external program fetch. This follows
TI's explicit statement that indirect MAR makes no use of the referenced
memory and direct MAR is a NOP
[ti-tms32010-users-guide-spru001b, `MAR`, printed p. 3-42 (PDF p. 92)].
**Confidence: VERIFIED_PRIMARY.**

The phase test also verifies that `MPYK` performs no logical data read or
write while retaining the ordinary external program fetch. Its signed 13-bit
operand is part of the fetched instruction word
[ti-tms32010-users-guide-spru001b, `MPYK`, printed p. 3-44 (PDF p. 94)].
**Confidence: VERIFIED_PRIMARY.**

The phase test likewise verifies that `PAC` copies P to ACC while retaining
the ordinary external program fetch and exposing no logical data read or
write
[ti-tms32010-users-guide-spru001b, `PAC`, printed p. 3-48 (PDF p. 98)].
**Confidence: VERIFIED_PRIMARY.**

`APAC` likewise retains the ordinary external program fetch and has no
logical data transaction while adding P to ACC. Its arithmetic status and OVM
behavior are internal to the processor
[ti-tms32010-users-guide-spru001b, `APAC`, printed p. 3-14 (PDF p. 64)].
**Confidence: VERIFIED_PRIMARY.**

`SPAC` has the same program-only bus boundary while subtracting P from ACC;
the operation, P source, overflow status, and OVM result selection are
internal
[ti-tms32010-users-guide-spru001b, `SPAC`, printed p. 3-58 (PDF p. 108)].
**Confidence: VERIFIED_PRIMARY.**

## Remaining diagrams

The primary normal fetch, `IN`, `OUT`, `TBLR`, `TBLW`, and reset pin waveforms
are transcribed. Remaining work must identify:

- branch/call/return prefetch address order;
- complete interrupt entry and vector-fetch order;
- any internal conflict that changes an otherwise normal read;
- safe wrapper phase pause, if one exists, despite the absence of READY.
