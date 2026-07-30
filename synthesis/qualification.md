# Partial-core synthesis evidence

## 2026-07-30 Quartus fits

These results cover the initial five-instruction RTL and first program-bus
phase engine. They are not complete-core resource or interface-timing results.

- Tool: Quartus Prime Lite 17.0.2 Build 602, 2017-07-19.
- Target: Cyclone V `5CSEBA6U23I7` (DE10-Nano FPGA).
- Top: synthesis-only `tms32010_synth_top`, elaborating the partial execution
  core and phase engine without claiming functional integration.
- Constraint: 50.0 MHz `clk_i`; non-clock harness ports explicitly false
  pathed until a real integration wrapper defines their timing.
- Analysis/synthesis: successful, 0 errors.
- Fitter: successful, 0 errors.
- TimeQuest: successful, 0 errors.
- Logic: 42 ALMs (<1%).
- Registers: 72.
- Memory: 0 bits, 0 RAM blocks.
- DSP blocks: 0.
- PLLs: 0.
- Slow 1.1 V, 100 °C setup slack: +15.222 ns at 50 MHz.
- Worst internal hold slack across analyzed corners: +0.170 ns.
- Slow-corner internal Fmax: 209.29 MHz at 100 °C, 219.93 MHz at -40 °C.
- Unconstrained clocks, inputs, input paths, outputs, and output paths: 0.

The I/O categories report zero because each harness-only interface path is
explicitly excluded, not because portable-core I/O timing is closed. The
future wrapper must replace every false path with real constraints.

The reports contain no latch diagnostic. They contain 26 synthesis
warnings for outputs constant in the partial instruction boundary: only the
low eight accumulator bits can currently become nonzero, and `INTM` can only
be set. The fitter also emitted the expected critical warning that the
synthetic harness's 143 ports have no physical pin locations. This is
not a deployable board image, and the generated `.sof` is deliberately
ignored.

An intermediate expanded-harness run assigned invented 0/2 ns synchronous
delays to every port and produced hold violations down to -0.143 ns on an
artificial top-level-input-to-register path. That run was rejected. The
diagnostic `report_hold.tcl` localized the path; the correction was to stop
claiming interface timing before a wrapper exists, not to weaken a physical
requirement. Internal register timing then passed all analyzed corners.

Generated reports are not committed. Reproduce with:

```sh
make synth-quartus \
  QUARTUS_SH=/home/aberu/intelFPGA_lite/17.0/quartus/bin/quartus_sh
```

Detailed hold-path diagnostics can be regenerated with:

```sh
/path/to/quartus/bin/quartus_sta \
  -t synthesis/quartus/report_hold.tcl
```

## Yosys status

The portable synthesis script exists, but Yosys is not installed on the local
executable path. `make synth-yosys` therefore fails explicitly with
`ERROR: Yosys is required`; there is no Yosys synthesis evidence yet.
