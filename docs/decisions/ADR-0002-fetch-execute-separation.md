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

The first implementation is the standalone synthesizable
`tms32010_fetch_execute` register. It is not yet connected to
`tms32010_core`; integration will proceed only when directed traces preserve
the already qualified branch, I/O, table, reset, and interrupt bus sequences.

## Consequences

- First fetch after reset primes execution and does not itself retire an
  instruction.
- Program bus address and execute instruction address become distinct
  observable state.
- The surrounding sequencer must explicitly classify each program-space
  transaction and must not overwrite an incomplete execute slot.
- Existing retirement-mapped core results remain partial evidence; adding this
  register alone does not make the core cycle-accurate.
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
[ti-tms32010-users-guide-spru001b]. **Confidence: VERIFIED_PRIMARY.**
