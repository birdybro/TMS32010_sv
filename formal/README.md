# Bounded formal verification

`make formal` runs committed SymbiYosys configurations and fails if the tool
is missing or any bounded check fails. Generated work directories live below
the ignored `build/formal/` tree.

The qualified local run used SymbiYosys v0.67-4-gfea6e46, Yosys SMTBMC from
the 2026-07-29 OSS CAD Suite, and Bitwuzla 0.9.1:

```sh
PATH=/path/to/oss-cad-suite/bin:$PATH make formal
```

## Architectural reset-boundary harness

`tms32010_reset.sby` checks the actual portable core with a 10-step BMC and
cover. The already-recognized `reset_i` input remains arbitrary, as does
`clock_enable_i`; native active-low `RS` duration, falling-`CLKOUT`
recognition, and first-fetch timing remain properties of the separately tested
program-bus phase engine. Assertions prove that initialization is
deterministic, recognized reset clears PC, the interrupt flag, trap/control
bookkeeping, and cycle count, sets `INTM`, suppresses every transaction and
instruction-valid output, and has priority over clock enable.

The same proof checks OVM retention as documented by TI. It also checks the
current retention implementation for ACC, T, P, AR0/AR1, ARP, DP, stack, and
OV, but that bundle is explicitly only PROVISIONAL FPGA policy under
`OQ-012`; the proof does not promote it to original-silicon behavior. A fixed
`SOVM; LACK 0x5a` path makes this boundary nonvacuous, and the reset-retention
cover is reached at step 5. Internal-RAM retention is directed-tested rather
than formally quantified by this harness.

## Native program-bus reset/release harness

`tms32010_program_bus_reset.sby` checks the standalone native program-read
phase engine with a 40-step BMC and cover. The harness input `rs_i` is the
active-high logical assertion used inside the repository; a physical pin
wrapper must invert the original part's active-low `RS` pin. Logical reset,
clock enable, read qualification, and the next program address all remain
arbitrary in the safety proof.

Assertions check deterministic FPGA initialization, exact four-phase
progression, `CLKOUT` and active-low `MEN` relationships, phase/address/
transaction retention across arbitrary clock-enable stalls, and single-pulse
sampling. They also prove that reset assertion does not abort an active read
before an enabled phase-3 falling boundary, that a recognized boundary makes
the bus inactive at address zero, that the first deasserted boundary only
synchronizes release, and that the second deasserted boundary starts the
first read using the supplied address.

The cover selects an unstalled path with five consecutive complete asserted
machine cycles, release synchronization, one complete inactive cycle,
address-0 read activation, and address-1 sampling. It reaches step 34. This
is bounded digital-phase evidence for the source-transcribed wrapper. It does
not prove electrical setup/hold timing, that an external board held physical
`RS` for the required duration, analog pin behavior, architectural state
values not listed by TI, or general pipeline correctness.

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

## Data-memory MPY and repeated-chain harness

`tms32010_interrupt_multiply_chain.sby` checks a third fixed actual-core
program with a 20-step BMC and cover. Three initialization cycles use the
explicit nonarchitectural debug port to preload data words `0x8000`, `0x0002`,
and `0xffff`; this is a formal-fixture convenience, not a physical reset or
RAM-initialization claim. The program then:

1. loads `T=0x8000` through direct `LT`;
2. executes EINT and samples a request during the following NOP;
3. executes direct `MPY 1`, `MPYK -2`, and direct `MPY 2` as a repeated
   multiply chain;
4. executes one final protected `LACK 0x55`; and
5. performs the return-PC dummy fetch and vector entry.

Assertions check both data-memory reads and addresses, all three signed product
results (`0xffff0000`, `0x00010000`, and `0x00008000`), pending retention
through the chain, final ACC and product preservation, dummy-bus exclusion,
stack/vector/mask effects, and architectural plus bus-output stability across
arbitrary clock-enable stalls. The cover reaches completed entry at step 12.
This qualifies these direct MPY operands and this finite mixed chain only; it
does not prove indirect MPY address updates, arbitrary chain lengths or
placements, or every interrupt arrival point.

## Indirect-MPY address-update harness

`tms32010_interrupt_multiply_indirect.sby` checks a fourth fixed actual-core
program with a 20-step BMC and cover. Three initialization cycles preload
`data[0]=0x8000`, `data[1]=0xaa8f`, and `data[143]=0x0002` through the same
explicit nonarchitectural debug port used by the direct-MPY harness. The
program:

1. loads `T=0x8000` and then loads `AR0=0xaa8f` from internal RAM;
2. explicitly selects AR0, executes EINT, and samples a request during the
   following NOP;
3. executes protected `MPY *-,AR1`, followed by protected `LACK 0x55`; and
4. performs the return-PC dummy fetch and vector entry.

Assertions establish that MPY reads old selected address `0x8f` and operand
`0x0002`, produces `0xffff0000`, preserves AR0's upper seven bits while
decrementing its low-nine-bit counter to `0x08e`, replaces ARP with one, and
retains those effects through interrupt entry and arbitrary clock-enable
stalls. The cover reaches completed entry at step 12. This is one fixed
indirect decrement/ARP-replacement case; it does not prove every indirect
control encoding, counter wrap, arbitrary instruction placement, or
unbounded interrupt behavior.

## Fetch/execute ownership-register harness

`tms32010_fetch_execute.sby` checks the standalone ADR-0002 ownership
register with a 12-step BMC and cover. Reset, cycle-boundary, fetched-valid,
fetched address/word, completion, and flush inputs remain arbitrary. The
harness assumes only the two legal-sequencer contracts that the RTL also
asserts:

- a redirect does not simultaneously supply a valid executable fetch; and
- a new valid fetch does not overwrite an incomplete valid execute slot.

Within that environment, assertions check synchronous FPGA initialization,
zero-valued invalid state, exact capture of arbitrary address/word values,
non-boundary stall stability, incomplete-slot retention, simultaneous
completion/replacement, completion-to-bubble behavior, and reset/flush
invalidation. The cover reaches a prime, stall, replacement, flush, and target
capture path at step 7.

This proof qualifies the isolated register transition relation at the stated
bound. It does not prove that the partial core classifies program transactions
correctly, connects the register correctly, implements TI's complete
fetch/execute overlap, or meets electrical timing.

## Integrated direct-TBLR pipeline harness

`tms32010_pipeline_table.sby` checks the actual
`tms32010_sequential_pipeline_slice` hierarchy with a 40-step BMC and cover.
The fixed program executes `LACK 4`, direct `TBLR 0`, the repeated `LAC 0`
following word, and NOP; program address 4 contains `0x1234`.
`clock_enable_i` remains arbitrary.

Assertions check:

- reset/prime state and program-only bus exclusion;
- retained TBLR execute ownership while the first PC+1 word is discarded;
- the ACC-addressed MEN transfer and exact `0x1234` logical RAM write;
- the repeated PC+1 MEN fetch before TBLR ownership is released;
- subsequent LAC observation of the committed RAM word and ACC result;
- absence of program writes, I/O traffic, illegal execution, interrupt state,
  and stack mutation; and
- complete architectural and bus-output stability across arbitrary
  clock-enable stalls, except the intentionally transient sample/retire
  observation pulses.

All assertions pass through 40 solver steps. The separate cover reaches the
complete LACK/TBLR/LAC/NOP path at step 34. This is bounded evidence for one
direct TBLR sequence. It does not prove indirect table addressing, arbitrary
surrounding instructions, interrupts during the table operation, the complete
integrated pipeline, or electrical timing.

## Integrated direct-TBLW self-modification harness

`tms32010_pipeline_table_write.sby` checks the same complete hierarchy with a
second 40-step BMC and cover. The explicitly nonarchitectural debug port
preloads RAM word 0 with `LACK 0x44` (`0x7e44`). The fixed program executes
`LACK 2`, direct `TBLW 0`, an old ZAC at program address 2, and NOP.
The formal program-memory fixture commits a write only on an enabled, active
phase-3 boundary, matching the synchronous contract in
`sim/bus/tb_sequential_pipeline_table.sv`.

Assertions check:

- the old ZAC word remains unchanged through the discarded PC+1 read and any
  clock-enable stalls;
- cycle 2 reads RAM word 0 and drives only WE at program address 2 with exact
  data `0x7e44`;
- the program-memory fixture commits exactly one write at the enabled
  phase-3 boundary;
- cycle 3 reads the replacement word at repeated PC+1 under MEN;
- TBLW retains ownership until that repeated fetch and the replacement
  `LACK 0x44`, rather than old ZAC, subsequently sets ACC; and
- bus exclusion, stack/interrupt preservation, and complete checked-state
  stability across arbitrary clock-enable stalls.

All assertions pass through 40 solver steps. The cover reaches the complete
self-modifying path at step 35. This is one fixed direct TBLW scenario under
the stated program-memory model. It does not prove indirect addressing,
arbitrary write targets/data, interrupt arrival, asynchronous or electrical
memory timing, or the general integrated pipeline.

The nine harnesses leave DINT ordering, formal coverage of the represented
multicycle interrupt-arrival matrix, RET, arbitrary multiply-chain
placement/length, the complete integrated fetch/execute pipeline, and
electrical timing to
simulation/research or future formal work under `CTRL-002`, `FORMAL-001`,
`OQ-004`, and `OQ-019`.
No liveness theorem is claimed because arbitrary clock-enable or
cycle-boundary inputs may remain disabled forever; the covers supply
non-vacuity evidence for enabled paths.
