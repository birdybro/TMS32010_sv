# Synthesis qualification

The checked-in projects synthesize the current partial execution slice only.
They do not establish resource or timing characteristics of an
instruction-complete TMS32010.

## Yosys

```sh
make synth-yosys
```

The script elaborates the portable package, decoder, and core; runs hierarchy
and structural checks; performs generic synthesis; and writes an ignored JSON
netlist below `build/yosys/`.

## Quartus

The initial project targets the DE10-Nano Cyclone V SoC FPGA
`5CSEBA6U23I7`. It has no board pin assignments because this is a portable
core fit, not a MiSTer top level.

```sh
make synth-quartus \
  QUARTUS_SH=/path/to/quartus/bin/quartus_sh
```

The 50 MHz constraint is an FPGA implementation objective, not an emulated
TMS32010 crystal frequency. All current primary inputs and outputs receive
simple synchronous I/O delay constraints so TimeQuest can identify genuinely
unconstrained paths. Fitter and timing reports are generated locally and
remain ignored.
