# Synthesis qualification

The checked-in projects synthesize the current fifty-six-instruction
execution slice, signed multiplier, 144-word data RAM, and program phase
engine only. They do not establish
resource or timing characteristics of an instruction-complete TMS32010.

## Yosys

```sh
make synth-yosys
```

The script elaborates the portable package, decoder, execution core, program
bus, and sequential phase wrapper through a synthesis-only harness; runs
hierarchy and structural checks; performs generic synthesis; and writes an
ignored JSON netlist below `build/yosys/`. The integration is qualified only
for the current 41 one-cycle instructions, eleven qualified two-cycle
control-flow paths, two native IN/OUT paths, and two three-cycle table-transfer
paths.
Yosys 0.67+111 from
the 2026-07-29 OSS CAD Suite is the currently verified open-source synthesis
baseline; see `synthesis/qualification.md` for the exact invocation and
results. The
asynchronous data-RAM read currently lowers to registers and muxes rather than
a memory block. The portable multiply operator remains technology-neutral;
the current Cyclone V flow infers one DSP block.

The command runs four checked-in scripts. The main synthesis harness targets
the legacy multicycle phase wrapper and writes `build/yosys/tms32010.json`.
The second directly targets `tms32010_sequential_pipeline_slice` and writes
`build/yosys/tms32010_sequential_pipeline.json`. Its result includes the core,
a second decoder, program bus, and fetch/execute register. It is not a
Quartus resource or timing result and qualifies only the pipeline subset
documented in `docs/architecture/pipeline.md`. After exact B integration,
the checkpoint was 14,213 generic cells and 41 checks. With exact BANZ
integrated, the checkpoint was 14,276 generic cells and 42 checks. With the
six accumulator branches integrated, Yosys 0.67+111 reports 14,525 generic
cells and 43 retained checks. With exact BV integrated, the
checkpoint was 14,567 generic cells and 44 retained checks. With exact BIOZ
integrated, the checkpoint was 14,715 generic cells and 47 retained checks.
With the basic Figure 2-12 interrupt path integrated, the current checkpoint
was 15,129 generic cells and 78 retained checks. With exact TBLR/TBLW
discarded-prefetch, program-transfer, and repeated-prefetch ownership, plus
ABS, SST, and ADDH execution, the checkpoint was 15,686 generic cells.
Explicit reset-time instruction qualification and the loop-free recognized-
reset boundary bring the current checkpoint to 15,733 generic cells, 103
retained checks, and zero
structural-check problems.

The third script directly targets the generic `tms32010_mister` adapter and
writes `build/yosys/tms32010_mister.json`. It covers the synchronous-reset
stretcher, registered program/I/O response wait, callback mapping, and debug
fanout around the same partial explicit pipeline. It does not synthesize an
SDRAM controller, CDC bridge, board-specific memory map, or MiSTer top level.
Yosys 0.67+111 reports 15,779 generic cells and 110 retained checks, with zero
structural problems; 46 cells and seven checks are local to the new adapter.

The fourth script targets the storage-free A044427 Rev-A
`hard_drivin_sound_bus_decode`. It reports 15 generic combinational cells,
zero registers or memories, and zero structural problems. This qualifies only
the exhaustive-tested address/strobe and ownership-conflict truth table; it is
not shared program RAM, a host/DSP arbiter, or a board timing result.

## Quartus

The initial project targets the DE10-Nano Cyclone V SoC FPGA
`5CSEBA6U23I7`. It has no board pin assignments because this is a portable
core fit, not a MiSTer top level.

```sh
make synth-quartus \
  QUARTUS_SH=/path/to/quartus/bin/quartus_sh
```

The 50 MHz constraint is an FPGA implementation objective, not an emulated
TMS32010 crystal frequency. The current synthesis-only harness explicitly
false-paths its non-clock ports because no board-level memory/host wrapper yet
defines their timing. This qualifies internal register timing only. The
integrated wrapper must replace every exclusion with real I/O or
register-to-register constraints before release; these exclusions are not
portable-core I/O closure. Fitter and timing reports are generated locally
and remain ignored.

All non-clock harness ports are Quartus virtual pins. This prevents the
diagnostic state/interface width from being mistaken for a DE10-Nano package
pinout while retaining the logic for internal resource and timing analysis.
The setting is confined to the synthesis project, not the portable RTL.
