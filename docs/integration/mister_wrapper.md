# Generic MiSTer/FPGA wrapper

## Status and scope

`rtl/wrappers/tms32010_mister.sv` is the first synthesizable platform adapter
around the qualified `tms32010_sequential_pipeline_slice`. It provides a
standard active-high synchronous reset, a host clock enable, same-clock
program and I/O callbacks with response readiness, native-phase observability,
and deterministic debug/state ports. It contains no Hard Drivin'-specific
address map or peripheral behavior.

The wrapped processor is still partial. It supports the explicit-pipeline
instruction and transaction set documented in ADR-0002/ADR-0003; PUSH and
POP remain outside RTL, while CALA/RET use ADR-0003's CORROBORATED-RET/
INFERRED-CALA external sequence. The unresolved timing and silicon behaviors in
`docs/research/open_questions.md` remain unresolved. This wrapper therefore
does not make the project instruction-complete, cycle-accurate, or
release-ready.

## Clock and reset

All wrapper inputs are synchronous to `clk_i`. `clock_enable_i` is the MiSTer
or FPGA system's processor-rate enable. Deasserting it pauses the modeled
phase without creating a gated clock. `phase_advance_o` reports when the
native phase engine can actually advance after combining the host enable,
callback wait state, reset override, and conservative unsupported-word park.

`reset_i` and `processor_reset_i` are active-high and synchronous. `reset_i`
applies the FPGA-only deterministic initialization path; `processor_reset_i`
applies the modeled processor reset without clearing the wrapper's external
program memory. Either request reloads the five-machine-cycle hold counter.
At release, the wrapper keeps the modeled active reset condition for exactly
five enabled machine cycles, the minimum duration required by the original
data sheet. The native bus then performs its separately qualified full
inactive release cycle before fetching address zero
[ti-tms32010-users-guide-spru001b, §2.5 and Appendix A data sheet, reset
timing, printed p. 2-19 and data-sheet p. 19 (PDF pp. 43 and 375)].
**Confidence: VERIFIED_PRIMARY for the physical minimum and release
sequence; VERIFIED_SIMULATION for the wrapper's exact five-cycle adaptation.**

Deterministic initialization is an FPGA integration choice. It is not a claim
that the physical part initializes every register or RAM word. The original
reset's unlisted state remains `OQ-012`, and internal RAM is never cleared by
this wrapper.

## Program callback

The program interface is:

| Signal | Direction | Meaning |
| --- | --- | --- |
| `program_address_o[11:0]` | out | Current program-space address |
| `program_read_o` | out | Level request for a program read |
| `program_write_o` | out | Level request for a TBLW program write |
| `program_write_data_o[15:0]` | out | Program write word |
| `program_read_data_i[15:0]` | in | Program response word |
| `program_ready_i` | in | Response/acceptance is available |

Read and write requests are mutually exclusive and remain asserted during
native strobe phases 1–3. Address, direction, and write data remain stable
while phase 3 is held. An always-ready local memory may tie
`program_ready_i` high. A synchronous ROM or RAM may use the phase-1 request
as its enable and return registered data before the phase-3 boundary.

If ready is low when phase 2 advances, the wrapper registers a wait and holds
phase 3. It releases that hold only after observing ready high. The consumer
must keep ready and read data stable until the request deasserts. A write
consumer must commit once, at an edge where `phase_advance_o`, phase 3,
`program_write_o`, and ready are all high; the request is a held level and is
not itself a per-host-clock write pulse.

## I/O callback

`io_port_o`, `io_read_o`, `io_write_o`, `io_write_data_o`,
`io_read_data_i`, and `io_ready_i` use the same request/ready rules. Program
and I/O requests are mutually exclusive. The interface preserves the original
separation of program and I/O spaces even though the native pin-compatible
address bus is shared.

No data-memory callback exists because the original part's qualified
144-word data RAM remains internal. The `debug_data_*` ports expose logical
RAM transactions and provide the existing nonarchitectural preload write
port. A caller must not assert `debug_data_write_i` during a CPU data write;
the RAM asserts on that collision.

## Ready is platform-only

The original 40-pin TMS32010 has no READY or WAIT pin. This wrapper's ready
inputs pause explicit FPGA phases using the already verified
`clock_enable_i` behavior. They are not native pins and must not be used as
evidence that physical transactions can be stretched indefinitely. A
pin-compatible clock must still satisfy the 48.78–150 ns input-period and
47.5–52.5% pulse requirements documented in the external-interface timing
specification
[ti-tms32010-users-guide-spru001b, §2.12 and Appendix A data sheet, printed
pp. 2-20 and data-sheet pp. 10–11 (PDF pp. 44 and 366–367)].
**Confidence: VERIFIED_PRIMARY for the absence of READY and physical clock
limits; VERIFIED_SIMULATION for the callback hold.**

## Clock domains and SDRAM

The callback contract is single-clock. A same-clock MiSTer ROM, RAM, or local
arbiter can connect directly. An SDRAM controller in another clock domain
requires an explicit request/response CDC bridge outside this wrapper. No
asynchronous ready, data, interrupt, or BIO synchronization is implied here.
`int_i` and `bio_i` retain the core's active-low native sense and must already
be synchronized when their source is not in `clk_i`'s domain.

## Debug and trace visibility

The wrapper exposes native phase/strobe/sample state, current fetch/execute
ownership, pipeline blocking, the programmer-visible register set, interrupt
state, retirement/illegal pulses, cycle count, and logical internal-RAM
transactions. These are deterministic simulation and integration hooks, not
original package pins. `execute_address_o` and `execute_word_o` describe the
current execute slot; they are not yet a separately registered retired-
instruction trace tuple.

The separate `processor_reset_i` is exercised by the board-specific
`hard_drivin_sound_mister`, which holds shared program contents while applying
the same five-cycle processor reset interval. The generic wrapper test retains
`processor_reset_i=0` and continues to test `reset_i` as deterministic FPGA
initialization plus reset.

## Verification and synthesis

`sim/bus/tb_mister_wrapper.sv` supplies registered program and I/O responders,
delays responses through phase-3 holds, inserts a separate three-clock global
pause, and runs a synthetic seven-instruction program. The test checks:

- exactly five reset machine cycles and inactive callbacks during reset;
- stable phase/address and no retirement during the global pause;
- registered callback waits only at phase 3;
- one OUT of `0x002a` to port 3 and one IN of `0x1234` from port 4;
- one TBLW commit of `0x002a` to program address `0x234`, with no duplicate
  writes while the request is held;
- seven retirements in the documented `1/1/2/2/1/3/1 = 11` cycles;
- conservative parking on the following unsupported word; and
- synchronous reset recovery from that parked state.

Yosys independently elaborates this wrapper as a top level through
`synthesis/yosys/tms32010_mister.ys`. The current result is a structural
portability smoke test, not a Quartus fit, board pinout, CDC proof, SDRAM
controller qualification, or I/O timing-closure result.
