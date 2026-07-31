# Simulation programs

This directory contains redistribution-safe programs used for whole-program
model and RTL qualification. Generated binaries and listings remain build
artifacts unless a fixture has an explicit review reason to be committed.

## Programs

- `fir4/`: project-authored four-tap Q15 FIR kernel with fixed opcode, result,
  cycle, program-fetch, and logical data-transaction expectations.
- `hard_drivin_smoke/`: ROM-free Driver Sound Board I/O sequence with fixed
  raw port traces and explicitly secondary/provisional board expectations.

Copyrighted application listings and game ROMs do not belong here. Tests that
eventually consume user-supplied ROMs must validate hashes and keep the images
outside version control.
