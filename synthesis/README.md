# Synthesis qualification

The checked-in projects synthesize the current eleven-instruction execution
slice, 144-word data RAM, and program phase engine only. They do not establish
resource or timing characteristics of an instruction-complete TMS32010.

## Yosys

```sh
make synth-yosys
```

The script elaborates the portable package, decoder, execution core, program
bus, and sequential phase wrapper through a synthesis-only harness; runs
hierarchy and structural checks; performs generic synthesis; and writes an
ignored JSON netlist below `build/yosys/`. The integration is qualified only
for the current one-cycle sequential instruction subset. Yosys 0.33 from
Ubuntu 24.04 is the currently verified open-source synthesis baseline; see
`synthesis/qualification.md` for the reproducible isolated command. The
asynchronous data-RAM read currently lowers to registers and muxes rather than
a memory block.

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
