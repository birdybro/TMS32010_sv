# RTL qualification boundary

The current RTL is an execution slice, not a cycle-accurate TMS32010 core.
`tms32010_core` supports only `LACK`, `NOP`, `ZAC`, `ROVM`, and `SOVM` at an
instruction-boundary program interface. One asserted `clock_enable_i` retires
one supported one-cycle instruction. Unsupported words assert `illegal_o` and
do not advance the PC.

This temporary interface does not reproduce `MEN`, `CLKOUT`, fetch/execute
overlap, or pin subphases. It exists to qualify decode, state effects, clock
enables, and reset preservation before the cited native bus sequencer is
available. It must not be used as evidence of cycle accuracy.

The synthesizable code:

- uses one rising-edge clock and synchronous active-high reset;
- has no generated or gated clocks;
- leaves physical-reset-unspecified data state unspecified;
- resets the PC to zero and masks interrupts;
- preserves `OVM` through reset as TI documents;
- uses no vendor primitive.

Run:

```sh
make instruction-tests
make lint
```
