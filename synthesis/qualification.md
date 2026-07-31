# Partial-core synthesis evidence

## 2026-07-30 Quartus fits

These results cover the forty-seven-instruction RTL, signed multiplier,
144-word internal data RAM, and first program-bus phase engine. They are not
complete-core resource or interface-timing results.

- Tool: Quartus Prime Lite 17.0.2 Build 602, 2017-07-19.
- Target: Cyclone V `5CSEBA6U23I7` (DE10-Nano FPGA).
- Top: synthesis-only `tms32010_synth_top`, elaborating the partial execution
  core through its sequential native-phase wrapper.
- Constraint: 50.0 MHz `clk_i`; non-clock harness ports explicitly false
  pathed until a real integration wrapper defines their timing.
- Analysis/synthesis: successful, 0 errors.
- Fitter: successful, 0 errors.
- TimeQuest: successful, 0 errors.
- Logic: 1,942 ALMs (5%).
- Registers: 2,491.
- Memory: 0 bits, 0 RAM blocks.
- DSP blocks: 1.
- PLLs: 0.
- Worst internal setup slack across analyzed corners: +3.903 ns at 50 MHz.
- Worst internal hold slack across analyzed corners: +0.167 ns.
- Slow-corner internal Fmax: 62.12 MHz at 100 °C, 62.13 MHz at -40 °C.
- Unconstrained clocks, inputs, input paths, outputs, and output paths: 0.

The I/O categories report zero because each of the 279 harness-only interface
pins is explicitly excluded, not because portable-core I/O timing is closed.
The future wrapper must replace every false path with real constraints.
Quartus also labels timing paths involving virtual pins as estimates; the
setup, hold, and Fmax figures above are scoped to internal register paths.

The first LT fit exposed the newly added 16-bit T diagnostic port without
matching SDC exclusions. TimeQuest reported all 16 outputs unconstrained, so
that run was rejected even though place-and-route succeeded. Adding the exact
T port to the synthesis-harness false-path list restored zero unconstrained
categories in the full rerun. This exclusion remains harness-scoped and is not
a claim of wrapper I/O timing.

The portable multiplier infers one Cyclone V DSP block without a
vendor-specific primitive. This is a technology mapping result, not an
architectural dependency.

The reports contain no latch diagnostic. The three warnings are the expected
synthesis-harness notices: a Lite-only LogicLock notice, incomplete I/O
assignments, and the sole physical clock's intentionally absent package
location. Quartus separately
reports as information that the 144-word array cannot infer RAM because its
read is asynchronous, so it maps to registers and logic. The fit uses 279
virtual pins and one physical clock pin; the expected critical warning says
that clock has no package location.
This is not a deployable board image, and the generated `.sof` is deliberately
ignored.

The first fit after adding the RAM accidentally omitted the new harness ports
from the explicit SDC exclusions. TimeQuest correctly reported 25
unconstrained inputs, 26 unconstrained outputs, and corresponding path counts.
That run was rejected. After adding the exact new debug/data ports to the
harness-only false paths, TimeQuest reports zero unconstrained categories and
the fully constrained setup/hold status above. This still does not replace
real wrapper I/O constraints.

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

Yosys 0.67+111 from the 2026-07-29 OSS CAD Suite successfully elaborates and
synthesizes the same integrated partial hierarchy. Both pre- and
post-synthesis `check -assert`
passes report zero problems; no latches are inferred, 11 RTL assertions
remain represented, and the generic result contains 12,655 cells. The
asynchronous 144-word read lowers the array to 2,304 enabled flip-flops and
1,217 mux cells, leaving no inferred memories after generic synthesis. This
is a portability smoke test, not an FPGA resource estimate. The standalone
signed multiplier accounts for 1,756 of those generic cells; unlike Quartus,
generic Yosys synthesis does not map it to a target DSP resource.

The host executable path does not contain Yosys, so a direct
`make synth-yosys` still fails explicitly with `ERROR: Yosys is required`.
The successful run prepended an already installed OSS CAD Suite tool
directory:

```sh
PATH=/path/to/oss-cad-suite/bin:$PATH make synth-yosys
```

The ignored output is `build/yosys/tms32010.json`. Tool-version differences
make the generic cell count unsuitable for direct comparison with the earlier
Yosys 0.33 result; only same-version changes should be treated as utilization
regressions.
