# Formal verification

`make formal` runs committed SymbiYosys configurations and fails if the tool
is missing or any check fails. Generated work directories live below
the ignored `build/formal/` tree.

The qualified local run used SymbiYosys v0.67-4-gfea6e46, Yosys SMTBMC from
the 2026-07-29 OSS CAD Suite, and Bitwuzla 0.9.1:

```sh
PATH=/path/to/oss-cad-suite/bin:$PATH make formal
```

## Driver Sound communication-byte composition harness

`hard_drivin_sound_communication_byte.sby` uses a 7-step BMC and cover over
the original-MC68000 write normalizer plus the owner-qualified 512-word
communication RAM. The nine-bit address, complete bus word, and selected byte
orientation remain arbitrary. A fixed legal write/read sequence proves the
selected byte is duplicated, committed to the addressed word, and returned by
the synchronous FPGA read boundary. Separate covers reach upper- and lower-
byte transfers at solver step 6.

This is bounded same-clock FPGA composition evidence. It does not prove raw-
pin CDC, HM6116 setup/hold or access time, substitute-68k inactive-lane
behavior, or that authorized firmware performs byte writes.

## Driver Sound program-byte composition harness

`hard_drivin_sound_program_byte.sby` uses a 7-step BMC and cover over the
original-MC68000 write normalizer plus the reset-qualified 4,096-word program
RAM. The twelve-bit address, complete bus word, and selected byte orientation
remain arbitrary. A fixed legal host-ownership write/read sequence proves the
selected byte is duplicated, committed to the addressed word, and returned by
the synchronous FPGA read boundary. Separate covers reach upper- and lower-
byte transfers at solver step 6.

This is bounded same-clock FPGA composition evidence. It holds `/320RES`
asserted throughout host ownership and does not prove firmware handoff
discipline, raw-pin CDC, asynchronous SRAM setup/hold or access time,
substitute-68k inactive-lane behavior, or that authorized firmware performs
byte writes.

## Exhaustive decoder-safety harness

`tms32010_decode.sby` leaves the complete 16-bit instruction word
unconstrained in a one-step BMC. A compact family-envelope predicate, arranged
differently from the RTL priority chain, checks the exact valid/invalid result
for all 65,536 words. It includes common direct/indirect field constraints,
AR0/AR1 selection, sparse SACH shifts, direct SST range, MPYK, LDPK, LARK,
LACK, supported fixed controls, and exact-low-byte two-word controls.

Additional assertions bound the dense partial-RTL operation value and check
immediate, shift, port, auxiliary-register, indirect, and address-field
projections where those fields are meaningful. Exact CALA/RET are included;
the two model/tool-only exact words PUSH and POP remain invalid until their
native second-cycle ownership is qualified. Nine step-0 covers independently
reach legal direct/indirect words, a primary-reserved indirect field,
simultaneous increment/decrement, a branch-pattern mismatch, a primary-unlisted
fixed-control gap, CALA, RET, and the upper MPYK boundary.

This proves the partial RTL's validity predicate and field-safety invariants.
It does not replace the primary-cited ISA database or hand fixtures as the
mnemonic/operand authority, qualify silicon behavior for unsupported words,
or prove execution, timing, or bus behavior.

## Computed-control core harness

`tms32010_computed_control.sby` checks the actual portable core with a 24-step
BMC and cover. Its fixed `LACK 6; CALA; LACK 0x44; RET; LACK 0xee` path checks
both machine-cycle boundaries of CALA and RET, opcode-PC+1 push, old-top target
and pop, target/return execution, cycle count, program-only ownership, and
absence of early stack mutation. `clock_enable_i` remains arbitrary, so the
same proof asserts architectural and logical-output stability through stalls
in either half. The complete call/return path reaches cover step 9.

This is bounded state/transaction-class evidence for the actual core. It does
not prove the explicit wrapper's physical program addresses, interrupt timing,
or original-silicon prefetch order. ADR-0003's discarded-sequential/selected-
target address sequence remains `INFERRED` and simulation-asserted.

## Exhaustive input-shifter harness

`tms32010_input_shifter.sby` checks the standalone combinational signed input
barrel shifter in one solver step. The 16-bit source and four-bit shift count
remain arbitrary, covering all 1,048,576 input combinations and every legal
count from 0 through 15. Its reference constructs each output bit from a
source index: negative indices become zero, indices 0–15 select the source,
and higher indices select the source sign bit. It does not reuse the DUT's
concatenation-and-shift expression.

The assertion proves the complete 32-bit result. Four independent step-0
covers reach negative shift zero plus positive, all-one, and largest-positive
shift-15 boundaries. The core uses the result for `LAC`, `ADD`, and `SUB`;
their addressing, arithmetic/status effects, and instruction timing remain
outside this combinational proof.

## Exhaustive output-shifter harness

`tms32010_output_shifter.sby` checks the standalone combinational SACH output
shifter in one solver step. The full 32-bit accumulator and three-bit shift
field remain arbitrary. An independent reference assembles every stored bit
from ACC bit `bit + 16 - shift` for the legal zero, one, and four counts; it
does not reuse the DUT's part selects. This checks all accumulator values,
all eight field values, and proves that ACC[11:0] cannot affect a legal stored
word.

Assertions prove exact legality and result data. Six independent step-0 covers
reach two primary-manual examples, zero- and four-shift cross-half boundaries,
and invalid fields two and seven. Invalid fields producing zero with a clear
qualifier is local fail-closed policy; the core decoder separately rejects
those SACH encodings, and no silicon behavior is claimed. Address resolution,
RAM writes, the one-cycle instruction boundary, and external bus timing remain
outside this combinational proof.

## Exhaustive stack-transition harness

`tms32010_stack.sby` checks the standalone combinational four-level stack
relation in one solver step. All 48 existing stack bits, all 12 push-data
bits, and all eight push/pop/table control combinations remain arbitrary. The
reference uses an independently indexed four-entry array to derive hold,
push/drop-bottom, pop/duplicate-bottom, and the final TBLR/TBLW bottom
replacement.

Assertions prove the control-valid result and all four output words. Six
independent step-0 covers reach distinct-entry push, distinct-entry pop,
bottom propagation after over-pop, table-final replacement, hold, and the
all-three-controls-invalid case. Invalid simultaneous controls holding state
is implementation policy. The proof assigns no external cycle, does not expose
the temporary internal table state, and does not resolve `PUSH`/`POP` bus
ownership under `OQ-016`.

## Exhaustive auxiliary-counter harness

`tms32010_auxiliary_counter.sby` checks the standalone combinational 16-bit
AR update relation in one solver step. Every value bit and both update
controls remain arbitrary. The reference constructs increment carries and
decrement borrows bit by bit across only the low nine bits, independently of
the RTL arithmetic expression.

Assertions prove hold, exclusive increment, exclusive decrement, low-nine-bit
wrap, upper-seven-bit preservation, and the control-valid result. Six
independent step-0 covers reach increment wrap with a distinctive upper field,
decrement wrap, ordinary increment, ordinary decrement, hold, and invalid
simultaneous controls. Invalid controls holding is local fail-closed policy;
the proof assigns no original-silicon behavior and does not cover selected-AR
choice, effective addressing, ARP updates, instruction sequencing, or timing.

## Exhaustive accumulator-arithmetic harness

`tms32010_accumulator.sby` checks the standalone combinational signed
32-bit accumulator block in one solver step. Both 32-bit operands, the
add/subtract selection, and OVM remain arbitrary. The reference expression
sign-extends both operands to 33 bits before performing the mathematical
operation, then independently derives the representable range, modulo result,
and positive or negative saturation endpoint.

Assertions prove the wrapped result, signed-overflow predicate, and selected
result for every input combination. Four independent step-0 covers reach
positive and negative overflow for both addition and subtraction with OVM
enabled. The core uses this relation for `ADD`, `SUB`, `SUBH`, `APAC`, `SPAC`,
`LTA`, and `LTD`; their instruction sequencing, operand selection, and sticky
OV update remain covered by the directed core tests rather than this
combinational proof.

## Exhaustive multiplier harness

`tms32010_multiplier.sby` checks the standalone combinational multiplier with
a one-step BMC over two unconstrained 16-bit inputs. Thus the solver checks
all 2^32 operand pairs. The reference product uses explicit 32-bit sign
extension before multiplication.

Assertions prove the ordinary signed product, commutativity, zero and unity
identities, and that equal `0x8000` operands are the only permitted departure
from the mathematical result. That pair must produce TI's documented
`0xc0000000`. Four independent step-0 covers reach the exceptional pair,
maximum-positive square, most-negative times positive one, and negative one
times most-negative boundaries.

This proves the RTL's combinational bit-vector relation. It does not prove
physical multiplier timing, a technology-mapped DSP implementation, MPY/MPYK
instruction sequencing, operand-address selection, or interrupt interaction.

## Inductive internal-RAM harness

`tms32010_internal_ram.sby` uses temporal induction for the standalone
144-word portable RAM. A symbolic watched address is constrained only to the
qualified `0x00`–`0x8f` range, so one proof covers all 144 words. Initial RAM
contents remain arbitrary. CPU and debug write controls, addresses, and all
16 data bits remain arbitrary subject to three interface assumptions: an
active write has a qualified address, an active debug write has a qualified
address, and both write ports are not asserted together.

The proof establishes CPU/debug read-after-write behavior and preservation of
the watched word when either port writes elsewhere. A second inactive-write
instance exhausts all 256 read and write address values, proving the exact
`address < 144` valid flags and the implementation's zero output for invalid
reads. The five covers independently reach CPU write/readback at word 0,
debug write/readback at word 143, a non-target write, and invalid reads at
`0x90` and `0xff`.

This qualifies the portable storage block and its verification interface. It
does not assign original-silicon behavior to `0x90`–`0xff` (`OQ-002`), assign
physical power-up contents, make the debug port architectural, prove
instruction address selection, or qualify asynchronous-read electrical
timing or FPGA memory mapping.

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
than formally quantified by this harness. `SC-042` now records contemporary
TI EVM warm-save evidence and the contradictory clear/corruption warning;
neither changes what this bounded implementation proof establishes.

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
sampling. A disabled host clock holds `CLKOUT`; `MEN` is also proven stable
when its wrapper-owned combinational `program_read_i` qualifier is stable.
They also prove that reset assertion does not abort an active read
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
positions, held-low relatching, the complete fetch/execute pipeline, and
electrical timing. Other harnesses cover several of those gaps, but this first
fixture remains intentionally independent.

## Protected-DINT implementation-policy harness

`tms32010_interrupt_dint.sby` checks the actual portable core with an 18-step
BMC and cover while leaving `clock_enable_i` arbitrary. Its fixed program:

1. executes EINT request-free and samples a request during the following NOP;
2. executes DINT in the already-protected N+1 slot;
3. continues with one ordinary masked LARK while retaining the request;
4. executes a later EINT and its protected LARK;
5. performs the return-PC dummy fetch and vector entry.

Assertions check program-only ownership, every PC/mask/pending boundary,
ordinary execution after DINT, both LARK results, dummy classification, stack
entry, vector selection, and state/output stability across arbitrary bounded
stalls. The complete path reaches cover step 9.

This proves only that the current RTL implements its selected policy
consistently at the stated bound. DINT cancellation at protected N+1 remains
PROVISIONAL under `OQ-019`/`SC-039`; the harness is not production-silicon
priority evidence, does not represent the alternate entry-wins hypothesis,
and does not prove arbitrary DINT placement or electrical interrupt timing.

## Two-cycle branch-arrival harness

`tms32010_interrupt_branch.sby` checks the actual portable core with an
18-step BMC and cover while leaving `clock_enable_i` arbitrary. One symbolic
constant selects request arrival during either execution interval of the fixed
program `EINT; B 0x010`. Assertions prove that the first interval retains B
while presenting its canonical operand, the second resolves PC `0x010` before
interrupt deferral, `LACK 0x44` is the sole protected instruction, address
`0x011` is a nonretiring dummy fetch, and entry stacks `0x011`, masks, clears
pending state, and selects vector 2. Separate covers for both symbolic choices
reach completed entry at solver step 7.

The branch operand at address 2 is necessarily also the vector word in this
fixed program. Bus-exclusion assertions therefore stop at the dummy boundary;
the subsequently decoded vector word is outside the scenario. This proof
qualifies one unconditional-B logical sequence only. It does not prove the
other control, I/O, or table families; an explicit fetch/execute wrapper;
original-package MEN/address ownership; electrical interrupt timing; or an
unbounded liveness property.

## Three-cycle table-read-arrival harness

`tms32010_interrupt_table.sby` checks the actual portable core with a 20-step
BMC and cover while leaving `clock_enable_i` arbitrary. A constrained symbolic
constant selects request arrival during the opcode, discarded-following-word,
or program-to-data transfer cycle of fixed direct `TBLR 0`. Program address 0
contains the EINT word `0x7f82`; the table transfer writes that exact word to
internal RAM 0, and protected `LAC 0` reads the committed value back into ACC
before the address-3 dummy fetch and vector entry. Assertions also check all
program/data directions and addresses, no early retirement or entry, the
table-final stack state, stacked return PC, mask, and pending state. Separate
covers for all three choices reach completed entry at solver step 8.

This qualifies one direct TBLR logical core sequence and portable internal-RAM
effect only. It does not prove TBLW, indirect table addressing, nonzero table
program addresses, nontrivial preexisting stack contents, an explicit
fetch/execute wrapper, original-package pin ownership, electrical interrupt
timing, or an unbounded liveness property.

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

## Driver Sound same-clock host-timing harness

`hard_drivin_sound_host_timing.sby` checks the isolated A044427 logical timing
adapter with a 16-step BMC and cover. Address, function code, read/write
direction, and both byte strobes remain arbitrary. The same-clock environment
assumes only the adapter's legal event contract:

- rising and falling 8 MHz enables are mutually exclusive and alternate when
  present, with arbitrary idle clocks between them;
- `/AS` assertion is separate from either phase edge and begins only while no
  cycle is active;
- an ordinary `/AS` release occurs at its S7 completion event or after the
  registered completion indication; and
- a CPU-space/VPA release is separate from a phase edge and occurs only after
  the complete `RVA` pulse and following falling-edge settle sequence.

Within that environment, the harness checks deterministic FPGA initialization,
complete address/function/direction/strobe capture, exact `/VPA`, `/DTACK`,
`/RVF`, global write-enable, read/write select, one-hot target, and pre-edge
completion equations. It also checks the registered pulse delay, stable
captured fields, rising-edge `RVA` ownership, VPA suppression, and absence of
a second ordinary completion while `/AS` remains asserted. Separate covers
reach a qualified whole-word read and write at step 8 and a fully settled
CPU-space/VPA cycle at step 9.

This is bounded digital evidence for a common-clock enable adapter. It does
not prove a raw-pin CDC, analog TTL propagation/loading margin, MC68000
electrical setup/hold, physical unreset power-up state, open-bus values,
mailbox partial-byte behavior, or the board-top side effects driven by the
completion events.

## Driver Sound board host-routing harness

`hard_drivin_sound_host_routing.sby` instantiates the complete current
`hard_drivin_sound_mister` hierarchy with DSP execution paused and the
same-clock host-timing path selected. A 12-step BMC and cover choose one of six
symbolic transactions: `/SOUNDRD`, whole-word `/SOUNDWR`, partial
`/SOUNDWR`, `/LATCHES`, `/SPEECH`, or `/IRQCLR`. The transferred word, LS259
address bits, and upper-only versus lower-only partial-write choice remain
symbolic. Deterministic FPGA initialization and a
fixed legal `/AS`/S3-through-S7 event sequence are explicit harness
conditions; opposite external callbacks are asserted with contradictory
sentinel values to prove timing-mode isolation.

The assertions check read target/data/masks before completion, exact S7
mailbox read-clear and whole-word write effects, partial-write rejection,
address-coded LS259 state, side-effect-free speech visibility, IRQ-clear
routing, completion classification, and absence of early state changes. The
BMC passes solver steps 0 through 11. Seven covers span the six transaction
classes, including both partial-byte orientations, and all reach solver step
10, corresponding to harness state `step_q == 8` after the registered effects
are visible. Embedded hierarchy assertions also prove that arbitrary invalid
pre-initialization source data is clamped by the low-read selector.

This is one bounded, fixed-edge common-clock composition scenario per
transaction class. It does not prove DSP execution during a host cycle,
arbitrary event spacing, raw-pin CDC, physical LS374/LS74 collision behavior,
partial-byte electrical behavior, an implemented speech peripheral, open-bus
values, or TTL/MC68000 electrical timing.

## Driver Sound direct-I/O decode harness

`hard_drivin_sound_direct_io.sby` is a one-step symbolic BMC and cover over all
twelve host word-address bits, all control combinations, and arbitrary data,
driven-mask, and valid-mask inputs for the three populated/read callback
classes. It proves modulo-four read selection, canonical-only word-0-through-7
write selection, completion qualification, alias/unselected diagnostics, raw
write data, and clamping of every unqualified read bit. Four step-0 covers
reach the highest read alias, undriven port 3, canonical port-7 write, and the
first noncanonical write. This is exhaustive combinational evidence, not a
host-cycle, peripheral-state, or electrical contention proof.

## Driver Sound local-reset interlock harness

`hard_drivin_sound_local_reset_interlock.sby` is a one-step symbolic BMC and
cover over arbitrary initialization, raw MC68000 RESET/HALT, internal-storage
selection, and storage readiness. It proves separate RESET/HALT preservation,
initialization and selected-scrub clamping, external-storage independence, and
the exact denied-release diagnostic. Four step-0 covers reach external
pass-through, active scrub blocking, ready internal release, and asserted raw
RESET/HALT. This is exhaustive Boolean policy evidence, not MC68000 reset
duration, a physical HALT-source implementation, or clock-domain proof.

The current 34 configurations produce 68 passing BMC/cover tasks. They still
leave original-silicon DINT ordering, arbitrary DINT placement, formal
coverage of the remaining represented multicycle interrupt-arrival families,
arbitrary multiply-chain placement/length, the complete integrated
fetch/execute pipeline, and electrical timing to
simulation/research or future formal work under `CTRL-002`, `FORMAL-001`,
`OQ-004`, and `OQ-019`.
No liveness theorem is claimed because arbitrary clock-enable or
cycle-boundary inputs may remain disabled forever; the covers supply
non-vacuity evidence for enabled paths.
