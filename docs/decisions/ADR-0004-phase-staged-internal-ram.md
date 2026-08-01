# ADR-0004: phase-staged internal-RAM reads

- **Status:** Accepted
- **Date:** 2026-07-31
- **Decision owners:** project maintainers

## Context

The original TMS32010 contains 144 words of internal data RAM, and its
documented one-cycle instructions must retain their architectural cycle count.
The first execution slice used an asynchronous array read so an operand could
be selected and consumed in one FPGA edge. Quartus consequently implemented
all 2,304 memory bits as registers plus a large read mux. The measured path
from execute ownership through decode, address selection, that mux, shifting,
and arithmetic limited the explicit-pipeline fit.

ADR-0002's wrapper already holds an execute word and its effective address
through four FPGA subphases before the instruction's qualified falling
machine-cycle boundary. That implementation lead time can supply a synchronous
RAM read without inserting a TMS32010 machine cycle or moving any native bus
edge. The standalone core does not guarantee that lead time, so changing its
default read contract would be unsafe.

The first registered-read experiment exposed two distinct cases:

- immediately after a new word enters execute ownership, the diagnostic RAM
  data still belongs to the address captured on the preceding FPGA edge and
  becomes valid at phase 1; and
- a same-address architectural write followed immediately by a reader must
  expose the just-committed word during the new owner's phase-0 setup interval.
  In particular, `IN` followed by `OUT` must establish the new output word
  before the active `WE` phase.

Neither observation establishes the original silicon array's internal
read-during-write topology. They constrain only this FPGA implementation and
its existing external timing contract.

## Decision

`tms32010_core` retains a combinational internal-RAM read by default. A caller
may explicitly select a registered read only when it provides at least one
FPGA edge between effective-address ownership and architectural consumption.

`tms32010_sequential_pipeline_slice` selects that registered mode. The memory
uses a single-clock, simple-dual-port synchronous template with no reset or
initial value. Invalid read addresses are safely redirected to word zero and
qualified separately so the portable invalid-read output remains zero.
Architectural and debug writes remain mutually exclusive and retain their
existing priority.

Read-side capture is qualified by the wrapper's FPGA subphase clock enable.
When that enable is clear, the captured validity, memory output, and forwarding
metadata all hold. This makes a global pause freeze the complete diagnostic
and write-data cone; resuming from phase 0 captures the owned address on the
same edge that advances to phase 1. Architectural and debug write enables
remain separate from that implementation-only read enable.

An explicit same-address forwarding path supplies the accepted write word to
the registered read output. This forwarding does not change the operand seen
by the instruction retiring on that edge: nonblocking state updates mean the
retiring instruction consumes the previously staged word. It makes the new
word available to the following execute owner during phase 0, preserving
back-to-back dependencies and external write-data setup.

For the phase-aware wrapper, `data_address_o` and its validity remain
combinational diagnostics. `data_read_data_o` is boundary-valid for an owned
instruction by phase 1 and at every later subphase through architectural
consumption. It is not guaranteed to match a newly changed address during the
same phase-0 ownership edge unless same-address forwarding applies. This port
is not an original TMS32010 package pin.

No processor phase, native program/I/O strobe, instruction retirement edge,
wait-state boundary, interrupt boundary, or machine-cycle count may change as
a consequence of this implementation choice. Any such change requires
reverting the registered mode, not changing architectural expectations.

## Consequences

- Quartus can infer one 144-by-16 simple-dual-port M10K rather than 2,304
  individual storage registers.
- Standalone core users and the legacy retirement-mapped phase wrapper retain
  their prior asynchronous-read behavior.
- Testbenches must distinguish effective-address visibility at phase 0 from
  registered operand validity at phase 1.
- Global clock-enable pauses hold the complete registered output; read capture
  resumes only with the wrapper subphase sequence.
- Directed tests must cover invalid reads, debug preload, same-address
  forwarding, following-edge persistence, `IN` to `OUT` forwarding, table
  transfers, ordinary one-cycle streams, stalls, and reset/preload ordering.
- The registered output remains physically unknown until its first qualified
  clock capture; deterministic initialization is not added to architectural
  RAM state.
- This is an FPGA microarchitecture decision. It does not raise confidence in
  any unresolved TMS32010 silicon behavior.

## Evidence

- TMS32010 User's Guide, SPRU001B, Figure 2-2 and §§2.1.1 and 2.3,
  printed pp. 2-3 and 2-7 (PDF pp. 27 and 31): overlapped instruction
  execution and the original-part 144-word internal data store.
- SPRU001B §§2.8.1–2.8.2 and Figures 2-9–2-10, printed pp. 2-15–2-17
  (PDF pp. 39–41): native I/O and table-transfer interval ordering that this
  decision must not move.
- `sim/unit/tb_internal_ram_registered.sv`: registered capture, invalid-read
  qualification, debug preload, disabled-capture stability, and same-address
  forwarding.
- `sim/bus/tb_sequential_pipeline_io.sv`: phase-1 operand availability,
  back-to-back `IN`/`OUT` forwarding, and unchanged native I/O ownership.
- `formal/tms32010_pipeline_table.sby`: arbitrary clock-enable holds across the
  composed table-transfer sequence.
- The complete instruction, bus, interrupt, differential, formal, Yosys, and
  Quartus regressions recorded in `synthesis/qualification.md`.

The source documents are cataloged as
`ti-tms32010-users-guide-spru001b` in the reference manifest.
**Confidence: VERIFIED_PRIMARY for RAM capacity and cited processor/bus
boundaries; VERIFIED_SIMULATION for phase-staged equivalence;
VERIFIED_SYNTHESIS for the recorded Cyclone V mapping; implementation-only
for same-address forwarding.**
