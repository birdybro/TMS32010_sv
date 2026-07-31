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
`docs/timing/native_phase_contract.md`. Exact pipeline ownership remains to be
resolved for:

- a taken versus untaken conditional branch (`OQ-007`);
- `CALL`, `CALA`, and `RET`, plus the second cycle of `PUSH`/`POP`
  (`OQ-016`);
- interrupt entry and its dummy fetches (`OQ-004`);
- any external cycle stretching (`OQ-001`).

Until these rows have cited diagrams and automated traces, the project does
not claim cycle accuracy.

`PUSH` and `POP` are primary-defined one-word, two-cycle instructions. Their
architectural stack transformations are fully specified, but the located
original documentation contains no dedicated external-bus waveform for their
second cycle. Do not implement the extra cycle by merely refetching the same
opcode or by assuming a next-word prefetch: both would create an unsupported
external sequence. This is tracked as `OQ-016`
[ti-tms32010-users-guide-spru001b, Table 3-2 and `POP`/`PUSH`, printed
pp. 3-7 and 3-49–3-50 (PDF pp. 57 and 99–100)].
