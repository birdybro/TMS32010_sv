# Partial-core synthesis evidence

## 2026-07-30 Quartus fit

This result covers commit work leading to the initial five-instruction RTL
slice. It is not a complete-core resource or timing result.

- Tool: Quartus Prime Lite 17.0.2 Build 602, 2017-07-19.
- Target: Cyclone V `5CSEBA6U23I7` (DE10-Nano FPGA).
- Top: `tms32010_core`.
- Constraint: 50.0 MHz `clk_i`, 2 ns max/0 ns min synchronous I/O delays.
- Analysis/synthesis: successful, 0 errors.
- Fitter: successful, 0 errors.
- TimeQuest: successful, 0 errors.
- Logic: 36 ALMs (<1%).
- Registers: 55 synthesized design registers; 121 after fitter I/O
  duplication/packing.
- Memory: 0 bits, 0 RAM blocks.
- DSP blocks: 0.
- PLLs: 0.
- Slow 1.1 V, 100 °C setup slack: +2.193 ns at 50 MHz.
- Worst reported hold slack across analyzed corners: +0.030 ns.
- Slow-corner reported Fmax: 56.16 MHz at 100 °C, 58.47 MHz at -40 °C.
- Unconstrained clocks, inputs, input paths, outputs, and output paths: 0.

The reports contained no latch diagnostic. They did contain 26 synthesis
warnings for outputs constant in the partial instruction boundary: only the
low eight accumulator bits can currently become nonzero, and `INTM` can only
be set. The fitter also emitted the expected critical warning that the
portable core's 112 top-level ports have no physical pin locations. This is
not a deployable board image, and the generated `.sof` is deliberately
ignored.

Generated reports are not committed. Reproduce with:

```sh
make synth-quartus \
  QUARTUS_SH=/home/aberu/intelFPGA_lite/17.0/quartus/bin/quartus_sh
```

## Yosys status

The portable synthesis script exists, but Yosys is not installed on the local
executable path. `make synth-yosys` therefore fails explicitly with
`ERROR: Yosys is required`; there is no Yosys synthesis evidence yet.
