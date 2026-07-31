# RTL qualification boundary

The current RTL is an execution slice, not a cycle-accurate TMS32010 core.
`tms32010_core` supports only `ADD`, `ADDS`, `AND`, `APAC`, `DINT`, `DMOV`, `EINT`, `LAC`, `LACK`, `LAR`,
`LARK`, `LARP`, `LDP`, `LDPK`, `LT`, `LTA`, `LTD`, `MAR`, `MPY`, `MPYK`, `NOP`, `OR`, `PAC`,
`ROVM`, `SACL`, `SACH`, `SAR`, `SOVM`, `SPAC`, `SUB`, `SUBS`, `XOR`, `ZAC`,
`ZALH`, and `ZALS` at an
instruction-boundary program interface. One asserted `clock_enable_i` retires
one supported one-cycle instruction. Unsupported words, undocumented SACH
shifts, and common-address data accesses outside the verified 144-word RAM
assert `illegal_o` and do not advance the PC.

`tms32010_internal_ram` supplies the original-part 144 by 16-bit data store.
Its asynchronous read lets the present single-boundary execution slice consume
an operand without inventing another architectural cycle. This is an
implementation convenience, not a claim about the physical memory array, and
currently maps to registers and muxes in both qualified synthesis flows. DMOV
and LTD use independent RAM read and write addresses to copy the unchanged
source word to the next location; LTD additionally loads T and accumulates P.
The
explicit debug write port is only for deterministic verification preload;
physical reset never initializes the RAM, and assertions reject preload during
live execution or collision with an architectural write. Logical source
address, distinct write address, operation, and data outputs expose internal
activity for tests and are not original package pins.

`tms32010_multiplier` is a combinational signed 16-by-16 implementation.
It explicitly reproduces the original part's documented
`0x8000 * 0x8000 -> 0xc0000000` exception. Quartus may infer a native DSP
resource; that mapping is a synthesis choice and the RTL contains no
vendor-specific primitive. MPYK feeds the same datapath with its sign-extended
13-bit instruction constant and performs no data-memory access.

This temporary core interface does not itself reproduce `MEN`, `CLKOUT`,
fetch/execute overlap, or pin subphases. It exists to qualify decode, state
effects, clock enables, and reset preservation. It must not be used alone as
evidence of cycle accuracy.

`tms32010_program_bus` is the first independently tested native timing
primitive. It advances a four-subphase logical `CLKOUT`, asserts `MEN` one
quarter-cycle after the falling boundary, samples at the next falling
boundary, preserves address during the active strobe, and implements the
documented one-cycle reset-release wait. It does not model analog pin delays.

`tms32010_phase_slice` connects that phase primitive to the execution slice.
For the thirty-five currently qualified one-cycle sequential instructions it
samples and retires on the same falling boundary, keeps PC and native address
aligned, holds both on an unsupported opcode, and preserves
phase/address/control state during a clock-enable stall. It is not a general
sequencer: branch,
multi-cycle, other data-memory operations, I/O, table, and interrupt sequences
remain absent.

The phase primitive separates `initialize_i` (explicit deterministic FPGA/test
initialization) from `rs_i` (the emulated active-high form of physical
active-low `RS`). Initialization clears the modeled registers and status for
reproducibility but does not initialize internal RAM. Physical reset assigns
only the source-backed control effects; unlisted state receives no arbitrary
reset value. `CLKOUT` phases continue while `rs_i` is held, matching the
data-sheet reset waveform. Retention of unlisted state is an implementation
policy pending `OQ-012`, not a physical-device reset claim.

The synthesizable code:

- uses one rising-edge clock and synchronous active-high reset;
- has no generated or gated clocks;
- leaves physical-reset-unspecified data state unspecified;
- resets the PC to zero and masks interrupts;
- sets and clears `INTM` for exact `DINT`/`EINT` words without claiming
  interrupt recognition or EINT's following-instruction service delay;
- preserves `OVM` through physical reset as TI documents;
- exposes sticky `OV` for ADD/ADDS/APAC/LTA/LTD/SPAC/SUB/SUBS
  wrap/saturation verification;
- performs LTA's internal-RAM-to-T load and previous-P accumulation in one
  retirement with APAC's overflow result policy;
- performs LTD's simultaneous source read, unchanged next-address copy,
  T load, and previous-P accumulation in one retirement;
- exposes T and P for multiply-path differential verification;
- uses no vendor primitive.

Run:

```sh
make instruction-tests
make lint
```
