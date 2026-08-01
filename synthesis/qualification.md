# Partial-core synthesis evidence

## 2026-07-31 Quartus fits

These results cover the fifty-six-instruction RTL, signed multiplier,
144-word internal data RAM, program-bus phase engine, native IN/OUT and
TBLR/TBLW paths, and the partial interrupt request/entry sequencer.
They are not complete-core resource or interface-timing results.

- Tool: Quartus Prime Lite 17.0.2 Build 602, 2017-07-19.
- Target: Cyclone V `5CSEBA6U23I7` (DE10-Nano FPGA).
- Top: synthesis-only `tms32010_synth_top`, elaborating the partial execution
  core through its sequential native-phase wrapper.
- Constraint: 50.0 MHz `clk_i`; non-clock harness ports explicitly false
  pathed until a real integration wrapper defines their timing.
- Analysis/synthesis: successful, 0 errors.
- Fitter: successful, 0 errors.
- TimeQuest: successful, 0 errors.
- Logic: 2,188 ALMs (5%).
- Registers: 2,588.
- Memory: 0 bits, 0 RAM blocks.
- DSP blocks: 1.
- PLLs: 0.
- Worst internal setup slack across analyzed corners: +2.656 ns at 50 MHz.
- Worst internal hold slack across analyzed corners: +0.166 ns.
- Slow-corner internal Fmax: 57.83 MHz at 100 °C, 57.66 MHz at -40 °C.
- Unconstrained clocks, inputs, input paths, outputs, and output paths: 0.

The I/O categories report zero because each of the 385 harness-only interface
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
read is asynchronous, so it maps to registers and logic. The fit uses 385
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
passes report zero problems; no latches are inferred, 26 RTL checks
remain represented, and the generic result contains 13,877 cells. The
asynchronous 144-word read lowers the array to 2,304 enabled flip-flops and
1,217 mux cells, leaving no inferred memories after generic synthesis. This
is a portability smoke test, not an FPGA resource estimate. The standalone
signed multiplier accounts for 1,753 of those generic cells; unlike Quartus,
generic Yosys synthesis does not map it to a target DSP resource.

The second checked-in script directly synthesizes
`tms32010_sequential_pipeline_slice`. After exact B, BANZ, BV, BIOZ, CALL, and
the six accumulator branches, plus exact IN/OUT transfer and
following-prefetch ownership, exact TBLR/TBLW discarded-prefetch/table-
transfer/repeated-prefetch ownership, and the basic Figure 2-12 interrupt
path, it passes both structural checks with zero reported problems, retains
103 RTL checks, and contains 15,733 generic cells. Reset-time instruction
qualification and direct recognized-boundary derivation add 47 cells to the
previous 15,686-cell checkpoint without changing the retained-check count.
The ADDH increment added 75
cells without adding or removing retained checks; SST added 76 cells and ABS
added 170 cells in the preceding checkpoints. This result is 604 cells and
25 checks above the pre-table 15,129-cell/78-check checkpoint, 698 cells and
36 checks above the IN/OUT 15,035-cell/67-check checkpoint, 955 cells/54 checks
above the exact-CALL 14,778-cell/49-check checkpoint, 1,018 cells/56 checks
above the exact-BIOZ 14,715-cell/47-check checkpoint, 1,457 cells/61 checks
above the exact-B/BANZ 14,276-cell/42-check checkpoint, and 1,793 cells/71
checks above the
one-cycle-only 13,940-cell/32-check checkpoint. The result is a portability
smoke test for the narrow explicit-pipeline subset, not a Quartus fit or an
instruction-complete resource estimate.

The third checked-in script directly synthesizes `tms32010_mister` around the
same explicit-pipeline hierarchy. Yosys 0.67+111 passes both structural checks
with zero problems, retains 110 checks, and reports 15,782 generic cells. The
adapter itself contributes 49 cells and seven checks beyond the 15,733-cell,
103-check pipeline checkpoint. This result covers the five-cycle synchronous
reset stretcher, registered same-clock callback wait, request mapping, and
debug fanout only. It is not an SDRAM/CDC qualification, Quartus fit, board
pinout, I/O timing result, or evidence for the still-missing instruction
families.

The fourth checked-in script directly synthesizes the storage-free
`hard_drivin_sound_bus_decode`. Yosys 0.67+111 passes both structural checks
with zero problems and reports 15 generic combinational cells, with no
register or memory cells. This is a portability check for the verified
A044427 Rev-A ownership/port/program decode only; it is not a shared-memory
implementation, arbitration policy, Quartus fit, or timing result.

The fifth checked-in script stops before memory mapping for
`hard_drivin_sound_program_ram`. Yosys 0.67+111 retains one 4,096-by-16
`$mem_v2` with one registered read port and consolidates the mutually
exclusive host/TMS writes into one clocked write port. The complete hierarchy
contains 85 cells, including five retained checks and the 12-cell decoder;
both structural checks report zero problems. This establishes an inferable
synchronous memory shape, not a Quartus M10K mapping or fitted timing result.

The sixth checked-in script targets the storage-free
`hard_drivin_sound_rom_path`. Yosys 0.67+111 reports 18 abstract combinational
cells with three retained checks, no memory or latch, and zero structural
problems. This qualifies only the tested block/address/presence and signed-byte
mapping logic, not ROM content or access time.

The seventh checked-in script targets `hard_drivin_sound_dac_latch`. Yosys
0.67+111 reports 14 cells with two retained checks, no memory or latch, and
zero structural problems. This proves only the exhaustive-tested raw latch and
commit-pulse logic, not analog conversion or sample interpretation.

The eighth checked-in script targets `hard_drivin_sound_output_control`. Yosys
0.67+111 reports 33 cells with four retained checks, no memory or latch, and
zero structural problems. This proves only the exhaustive-tested raw MUTE-net
and IRQ latch/clear behavior, not a loaded analog mute or 68000 bus decoder.

The ninth script applies the same pre-technology boundary to
`hard_drivin_sound_mister`. Yosys 0.67+111 reports 2,737 abstract cells, 216
retained checks, and three `$mem_v2` objects: the synchronous 4K-by-16 shared
program RAM, synchronous 512-by-16 communication RAM, and the core's existing
asynchronous-read 144-by-16 internal RAM.
Both structural checks pass with zero problems. This proves hierarchy and
memory retention plus the opt-in BIO/host-control selection and whole-word
mailbox/raw-status boundaries only; it is not a technology-mapped utilization, block-RAM
placement, fitter, or TimeQuest result.

The tenth script applies the pre-technology boundary to
`hard_drivin_sound_communication_path`. Yosys 0.67+111 retains its 512-by-16
communication RAM as one `$mem_v2` and reports 82 abstract cells with seven
retained checks. Both structural checks pass with zero problems. This proves
standalone hierarchy and memory retention only; it is not physical HM6116
timing, a 68000 bus, a Quartus memory mapping, or board-top timing closure.

The eleventh checked-in script targets `hard_drivin_sound_bio_generator`.
Yosys 0.67+111 reports 52 cells with seven retained checks, no memory or latch,
and zero structural problems. This proves only the tested one-clock,
explicit-enable representation of the divide-by-50 and CLKOUT sample state;
it is not physical independent-clock setup/hold or metastability evidence.

The twelfth checked-in script targets `hard_drivin_sound_host_control`. Yosys
0.67+111 reports 53 cells with six retained checks, no memory or latch, and
zero structural problems. This proves only the tested address-encoded LS259
update, reset, retention, and validity logic; it is not `/RVAS`/DTACK decode,
a complete 68000 bridge, or physical latch timing.

The thirteenth checked-in script targets
`hard_drivin_sound_320_port_latch`. Yosys 0.67+111 reports 19 cells with five
retained checks, no memory or latch, and zero structural problems. This proves
only the tested low-byte capture, validity, and partial-lane masks; it is not
physical LS374 timing or an open-bus policy.

The fourteenth checked-in script targets `hard_drivin_sound_mailboxes`. Yosys
0.67+111 reports 259 cells with ten retained checks, no memory or latch, and
zero structural problems. This proves only the exhaustive-tested whole-word
callback state and explicit conflict invalidity; it is not an electrical
LS74 collision result, byte-lane policy, or completed 68000 bridge.

The fifteenth checked-in script targets the storage-free
`hard_drivin_sound_read_status`. Yosys 0.67+111 reports 23 combinational cells
with eight retained checks, no storage or latch, and zero structural problems.
This proves only the exhaustive-tested raw `D15:D12` mapping, driven mask, and
source-validity carrier; it is not an open-bus policy, live peripheral proof,
or completed 68000 read path.

The sixteenth checked-in script targets the storage-free
`hard_drivin_sound_switches`. Yosys 0.67+111 reports 10 combinational cells
with six retained checks, no storage or latch, and zero structural problems.
This proves only the exhaustive-tested raw connector order, driven mask, and
per-source validity carrier; it is not cabinet-semantic, electrical-idle,
open-bus, or completed 68000-read evidence.

The seventeenth checked-in script targets the storage-free
`hard_drivin_sound_host_read_mux`. Yosys 0.67+111 reports 68 abstract cells
with 13 retained checks, no storage or latch, and zero structural problems.
This proves only invalid-selection suppression, physical quadrant order,
one-hot target visibility, and masked-source forwarding; it is not a 68000
strobe/DTACK, side-effect, open-bus, or timing implementation.

The host executable path does not contain Yosys, so a direct
`make synth-yosys` still fails explicitly with `ERROR: Yosys is required`.
The successful run used the official 2026-07-29 Linux-x64 OSS CAD Suite
release after verifying its published SHA-256
`89ea1152ea84bc600f18cc685f721d534d1f018e09831662787865a3d79ce4aa`:

```sh
make YOSYS=/path/to/oss-cad-suite/bin/yosys synth-yosys
```

The ignored outputs are `build/yosys/tms32010.json`,
`build/yosys/tms32010_sequential_pipeline.json`, and
`build/yosys/tms32010_mister.json`; the board-specific scripts also write
ignored JSON outputs including
`build/yosys/hard_drivin_sound_communication_path.json`,
`build/yosys/hard_drivin_sound_bio_generator.json`, and
`build/yosys/hard_drivin_sound_host_control.json`,
`build/yosys/hard_drivin_sound_320_port_latch.json`, and
`build/yosys/hard_drivin_sound_mailboxes.json`, and
`build/yosys/hard_drivin_sound_read_status.json`. Tool-version differences
make the generic cell count unsuitable for direct comparison with the earlier
Yosys 0.33 result; only same-version changes should be treated as utilization
regressions.
