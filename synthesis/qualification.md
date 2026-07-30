# Partial-core synthesis evidence

## 2026-07-30 Quartus fits

These results cover the initial instruction RTL and first program-bus
phase engine. They are not complete-core resource or interface-timing results.

- Tool: Quartus Prime Lite 17.0.2 Build 602, 2017-07-19.
- Target: Cyclone V `5CSEBA6U23I7` (DE10-Nano FPGA).
- Top: synthesis-only `tms32010_synth_top`, elaborating the partial execution
  core through its sequential native-phase wrapper.
- Constraint: 50.0 MHz `clk_i`; non-clock harness ports explicitly false
  pathed until a real integration wrapper defines their timing.
- Analysis/synthesis: successful, 0 errors.
- Fitter: successful, 0 errors.
- TimeQuest: successful, 0 errors.
- Logic: 138 ALMs (<1%).
- Registers: 90.
- Memory: 0 bits, 0 RAM blocks.
- DSP blocks: 0.
- PLLs: 0.
- Worst internal setup slack across analyzed corners: +15.389 ns at 50 MHz.
- Worst internal hold slack across analyzed corners: +0.165 ns.
- Slow-corner internal Fmax: 216.87 MHz at 100 °C, 221.14 MHz at -40 °C.
- Unconstrained clocks, inputs, input paths, outputs, and output paths: 0.

The I/O categories report zero because each harness-only interface path is
explicitly excluded, not because portable-core I/O timing is closed. The
future wrapper must replace every false path with real constraints. Quartus
also labels timing paths involving virtual pins as estimates; the setup, hold,
and Fmax figures above are scoped to internal register paths.

The reports contain no latch diagnostic. They identify 41 constant output
bits in the partial instruction boundary: only the low eight accumulator and
auxiliary-register bits can currently become nonzero, and `INTM` can only be
set. The fit uses 152 virtual pins and one physical clock pin; the expected
critical warning says that clock has no package location. This is not a
deployable board image, and the generated `.sof` is deliberately ignored.

An intermediate expanded-harness run assigned invented 0/2 ns synchronous
delays to every port and produced hold violations down to -0.143 ns on an
artificial top-level-input-to-register path. That run was rejected. The
diagnostic `report_hold.tcl` localized the path; the correction was to stop
claiming interface timing before a wrapper exists, not to weaken a physical
requirement. Internal register timing then passed all analyzed corners.

The first eight-instruction fit attempt also failed because its 177 diagnostic
ports exceeded the selected package's 145 user I/O pins. The harness now marks
every non-clock port as a Quartus virtual pin. This preserves internal logic
analysis without inventing a board pinout; it is not evidence for wrapper I/O
fit or timing.

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
