# Bounded formal verification

`make formal` runs committed SymbiYosys configurations and fails if the tool
is missing or any bounded check fails. Generated work directories live below
the ignored `build/formal/` tree.

The qualified local run used SymbiYosys v0.67-4-gfea6e46, Yosys SMTBMC from
the 2026-07-29 OSS CAD Suite, and Bitwuzla 0.9.1:

```sh
PATH=/path/to/oss-cad-suite/bin:$PATH make formal
```

## Interrupt-entry harness

`tms32010_interrupt.sby` checks the actual portable core, not a replacement
controller. It has two tasks:

- a 12-step BMC task checks every arbitrary `clock_enable_i` sequence within
  the bound;
- a 12-step cover task demonstrates a reachable complete entry and vector
  instruction.

The harness initializes the core synchronously, holds active-low `INT` through
acceptance of `EINT` at address 0, and then releases the pin. Program memory is
fixed to `EINT`, protected `LACK 0x2a`, a dummy-fetched/vector
`LACK 0x5a`, and NOP elsewhere. This is a formal fixture, not a claim that
software memory is constrained in the processor.

Assertions check:

- masked, nonpending initialization;
- active-low request retention after the input returns high;
- the protected following instruction;
- the non-retiring program-only dummy fetch;
- return-PC stack push, vector-2 selection, INTM set, and pending clear;
- vector instruction execution;
- architectural and transaction-output stability across arbitrary
  clock-enable stalls;
- bus-direction exclusion and the core's embedded safety assertions.

The bound and fixture do not prove general interrupt behavior. In particular,
they exclude DINT cancellation, multiply extension, multicycle arrival
positions, held-low relatching, RET, the complete fetch/execute pipeline, and
electrical timing. The next harness covers two of those gaps, but this first
fixture remains intentionally independent.

## Multiply-extension and held-low harness

`tms32010_interrupt_multiply.sby` checks a second fixed actual-core program.
Its 14-step BMC again leaves `clock_enable_i` arbitrary, and its cover reaches
the final relatch state at step 8. The program:

1. executes EINT without a request;
2. holds `INT` low while a NOP arms the normal one-instruction delay;
3. executes MPYK in that protected slot;
4. executes the additional instruction protected by MPYK;
5. performs the return-PC dummy fetch and vector entry; and
6. executes vector word 2 while `INT` remains low, relatching the request
   behind the newly set mask.

Assertions check each PC, mask, pending, product, accumulator, stack, dummy-bus,
and clock-enable-stall boundary in that sequence. This qualifies the MPYK
control path and held-low relatching at the stated bound. It does not prove
data-memory MPY, arbitrary instruction placement, repeated multiply chains,
or every interrupt arrival point.

Both harnesses leave DINT ordering, multicycle arrival positions, RET, the
complete fetch/execute pipeline, and electrical timing to simulation/research
or future formal work under `CTRL-002`, `FORMAL-001`, `OQ-004`, and `OQ-019`.
No liveness theorem is claimed because arbitrary clock-enable input may remain
disabled forever; the covers supply non-vacuity evidence for enabled paths.
