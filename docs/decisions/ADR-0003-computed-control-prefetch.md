# ADR-0003: provisional CALA/RET program-fetch ownership

- **Status:** Accepted provisionally
- **Date:** 2026-07-31
- **Decision owners:** project maintainers

## Context

The original TMS32010 defines `CALA` and `RET` as one-word, two-cycle
instructions, but the acquired instruction pages do not give a dedicated pin
waveform. Their programmer-visible state transforms are primary-verified; the
program address and fetched-word ownership of both execution intervals are
not.

Several original-part facts constrain the missing sequence:

- the instruction pipeline prefetches the next word while the current
  instruction executes;
- program memory is addressed by the program counter;
- `/MEN` is active on every machine cycle except the `WE` and `DEN` intervals
  of documented write and input operations; and
- the primary TBL sequence demonstrates a one-word multicycle redirect by
  reading and discarding the sequential word before accessing the redirected
  program address.

Neither `CALA` nor `RET` asserts `WE` or `DEN`. A located independent FPGA
implementation instead makes its first microcycle bus-idle and reads the
target in its second. That idle interval conflicts with the original-part
every-cycle `/MEN` rule. MAME corroborates architectural state and numeric
cycle totals but exposes no program-bus subcycles. A contemporary TI patent
for a related DSP embodiment explicitly describes RET as discarding its
sequential S1 fetch, popping the return address into PC, and fetching that
target for decode in S2. The patent is corroborating architectural background,
not an original-TMS32010 production specification; it gives no equally
explicit CALA timing sequence.

## Decision

The explicit fetch/execute wrapper may implement this sequence:

1. opcode prefetch completes and the one-word instruction enters execute
   ownership;
2. execution cycle 1 reads `opcode-PC+1` under `/MEN` and classifies the word
   as nonexecutable/discarded;
3. the cycle-1 boundary selects `ACC[11:0]` for `CALA` or the old stack top for
   `RET` as the next program address;
4. execution cycle 2 reads that selected address under `/MEN`, retires the
   instruction, applies the documented stack/PC transform, and captures the
   selected word as the next executable instruction.

Tests, comments, and documentation must label RET's combined mapping
`CORROBORATED` and CALA's mapping `INFERRED`, never `VERIFIED_PRIMARY`. The
opcodes, state transforms, two-cycle totals, and requirement for active `/MEN`
remain independently `VERIFIED_PRIMARY` from production documentation.

The following competing hypotheses remain recorded:

- the selected target is driven and read in both execution intervals;
- another PC-addressed word is repeated before the selected target; or
- the first interval is inactive as in IKA32010, despite the primary `/MEN`
  rule.

A physical original-NMOS trace or an original TI instruction-specific
waveform supersedes this provisional mapping if it disagrees. The wrapper
must keep the discarded word invalid so replacing the address sequence does
not require inventing an executable placeholder.

## Consequences

- CALA/RET RTL work can proceed without presenting a related patent embodiment
  or the TBL analogy as production-silicon-verified.
- Directed tests must assert both `/MEN` reads, stalls in both intervals,
  nonexecution of the discarded word, target-word capture, retirement-only
  stack mutation, and interrupt deferral until completion.
- Instruction/cycle completeness and release readiness remain false while the
  exact original-part physical address sequence lacks primary or hardware
  confirmation.
- PUSH/POP remain outside this decision because they do not redirect PC and
  the available evidence does not select their second address.

## Evidence

- TMS32010 User's Guide, SPRU001B, Figure 2-2 and §§2.4.2, 2.8.2, plus
  Table 2-4, printed pp. 2-3, 2-10, 2-17, and 2-21 (PDF pp. 27, 34, 41,
  and 45): overlapped prefetch, PC program addressing, the TBL discarded
  sequential fetch, and the every-cycle `/MEN` contract.
- SPRU001B `CALA` and `RET`, printed pp. 3-25 and 3-51 (PDF pp. 75 and 101):
  exact one-word/two-cycle totals and architectural operations.
- IKA32010 pinned source, `IKA32010.sv`, CALA/RET microcycles and bus-control
  outputs, lines 1401-1461 and 166-228: idle-first implementation hypothesis.
- MAME pinned TMS320C1x source, `cala()`/`ret()` and opcode table, lines
  501-505, 676-679, and 849: functional and numeric-cycle corroboration only.
- TI US4577282A, patent columns 5-6 and 17-18 (PDF pp. 29 and 35), Figure
  3u: related-embodiment every-state external read rule and explicit RET
  sequential-fetch discard, stack pop, return-address fetch, and target decode.

These sources are cataloged as `ti-tms32010-users-guide-spru001b`,
`ika32010-rtl-51bc1f0`, `mame-tms320c1x-core-030fefc`, and
`ti-dsp-microcomputer-patent-us4577282a` in the reference manifest.
**Confidence: CORROBORATED for RET and INFERRED for CALA combined
address/fetch ownership; UNKNOWN for exact original-part pin confirmation.**
