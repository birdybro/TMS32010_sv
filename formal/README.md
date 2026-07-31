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
they exclude DINT cancellation, MPY/MPYK extension, multicycle arrival
positions, held-low relatching, RET, the complete fetch/execute pipeline, and
electrical timing. Those remain simulation/research or future formal work
under `CTRL-002`, `FORMAL-001`, `OQ-004`, and `OQ-019`. No liveness theorem is
claimed because arbitrary clock-enable input may remain disabled forever; the
cover supplies non-vacuity evidence for an enabled path.
