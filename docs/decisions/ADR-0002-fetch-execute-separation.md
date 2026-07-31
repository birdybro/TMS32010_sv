# ADR-0002: separate fetch and execute ownership

- **Status:** Accepted
- **Date:** 2026-07-30
- **Decision owners:** project maintainers

## Context

The current partial core executes the word visible on the program input at its
falling-edge sample boundary. That structure is useful for qualifying
instruction effects and external read sequences, but it associates a fetched
word with execution in the same cycle.

TI Figure 2-2 instead shows the PC launching an instruction prefetch while a
previously fetched instruction is decoded and executes. Figure 2-12 separately
shows an interrupt dummy fetch that must never execute. Branch operands and
table dummy reads are likewise program-space transactions that are not new
instructions.

## Decision

The final sequencer will represent fetch and execute ownership explicitly:

- each executable fetch carries a word, 12-bit address, and valid bit;
- operand, table-dummy, and interrupt-dummy reads are classified as
  noninstruction fetches;
- an incomplete multicycle instruction retains the execute slot;
- a completed instruction may be replaced by a simultaneously sampled valid
  fetch;
- redirects flush the old execute path, and the target enters execution only
  after its own fetch completes;
- reset invalidates pipeline state only at its recognized architectural
  boundary;
- validity, not a convenient no-op word, represents bubbles and dummy cycles.

The first implementation was the standalone synthesizable
`tms32010_fetch_execute` register. The
`tms32010_sequential_pipeline_slice` now connects it to `tms32010_core` for
the qualified one-cycle subset plus exact `B`, `BANZ`, `BV`, `BIOZ`, `CALL`,
and the six accumulator-conditional branches. Other
multicycle integration will proceed only when directed traces preserve the
already qualified I/O, table, reset, and interrupt bus sequences and map
their execution intervals to the explicit pipeline.

## Consequences

- First fetch after reset primes execution and does not itself retire an
  instruction.
- Program bus address and execute instruction address become distinct
  observable state.
- The surrounding sequencer must explicitly classify each program-space
  transaction and must not overwrite an incomplete execute slot.
- Existing retirement-mapped core results remain partial evidence; adding this
  register alone does not make the core cycle-accurate.
- Exact `B` retains its execute slot while the following operand is fetched,
  then retires only as the redirected target fetch completes. The operand is
  never marked executable, and the target instruction cannot execute at the
  branch-retirement boundary.
- Exact `BANZ` follows the same ownership rule but selects the second
  execution interval's fetch from the old selected `AR[8:0]`: target when
  nonzero, fallthrough when zero. Its modulo-512 decrement is deferred until
  that fetch completes and the branch retires.
- Exact `BGEZ`, `BGZ`, `BLEZ`, `BLZ`, `BNZ`, and `BZ` use the same ownership
  rule and select the second execution interval's fetch from the unchanged
  full 32-bit accumulator. They preserve ACC and retire only as the selected
  instruction is captured.
- Exact `BV` uses old sticky OV to select target or fallthrough after its
  operand fetch. OV remains unchanged through that decision and any
  selected-fetch stall, then clears only when a taken BV retires as the
  selected instruction is captured.
- Exact `BIOZ` samples the raw active-low input at operand completion, not
  opcode recognition. The resulting decision selects the second execution
  interval's fetch and remains stable through later pin changes or stalls;
  retaining that decision is not an opcode-time latch of the BIO pin.
- CALA, RET, PUSH, and POP remain outside native integration until their
  unresolved external cycles are sourced.

## Evidence

- TMS32010 User's Guide, SPRU001B, §2.1.1 and Figure 2-2, printed p. 2-3
  (PDF p. 27): fetch overlaps execution of previously fetched instructions.
- SPRU001B §2.8.2 and Figure 2-10, printed p. 2-17 (PDF p. 41): table
  prefetch is discarded and repeated.
- SPRU001B §2.10 and Figure 2-12, printed p. 2-19 (PDF p. 43): interrupt
  fetch N+2 is a nonexecuting dummy before vector 2.

These claims use
[ti-tms32010-users-guide-spru001b]. **Confidence: VERIFIED_PRIMARY for
separate fetch/execute ownership and the table/interrupt dummy-fetch rules;
INFERRED for the exact B/BANZ/BV/BIOZ/CALL/accumulator-branch execute-interval
mappings synthesized from Figure 2-2, Table 3-2, and the individual
instruction pages because TI supplies no dedicated branch/call pin
waveform.**
