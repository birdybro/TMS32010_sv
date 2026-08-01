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

The command runs seventeen checked-in scripts. The main synthesis harness targets
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
Yosys 0.67+111 reports 15,782 generic cells and 110 retained checks, with zero
structural problems; 49 cells and seven checks are local to the adapter after
separating deterministic initialization from processor reset.

The fourth script targets the storage-free A044427 Rev-A
`hard_drivin_sound_bus_decode`. It reports 15 generic combinational cells,
zero registers or memories, and zero structural problems. This qualifies only
the exhaustive-tested address/strobe and ownership-conflict truth table; it is
not shared program RAM, a host/DSP arbiter, or a board timing result.

The fifth script targets `hard_drivin_sound_program_ram` before technology
mapping. Yosys 0.67+111 retains the 4,096-by-16 array as one `$mem_v2` with a
registered read port and one merged synchronous write port. The hierarchy has
85 cells including the decoder and five retained checks, with zero structural
problems. This supports portable memory inference; it does not prove Cyclone V
M10K mapping, fitter timing, or physical asynchronous-SRAM equivalence.

The sixth script targets the storage-free `hard_drivin_sound_rom_path`. It
reports 18 abstract combinational cells, including three retained checks, no
memory or latch, and zero structural problems. This is only the exact digital
selection/data-mapping boundary; it contains no ROM and proves no device access
time.

The seventh script targets `hard_drivin_sound_dac_latch`. It reports 14 cells,
including two retained checks, with no memory, latch, or structural problem.
It qualifies only raw `TD15:TD4` capture and an FPGA commit pulse, not an
analog or signed-sample model.

The eighth script targets `hard_drivin_sound_output_control`. It reports 33
cells, including four retained checks, with no memory, latch, or structural
problem. It qualifies raw port-4 complement state and port-5 IRQ latch/clear
logic, not an effective analog mute or 68000 bus decoder.

The ninth script stops before technology mapping for the partial
`hard_drivin_sound_mister` hierarchy. It retains the 4K program RAM, 512-word
communication RAM, and 144-word internal RAM as three memory objects and
reports 2,737 abstract cells, 216 checks, and zero structural problems after
the opt-in host-control, port-3 latch, mailbox, raw-source, and masked-selector
integration.
This is not comparable to the
technology-mapped generic-cell counts above and is not a Cyclone V fit or
timing result.

The tenth script applies the same boundary to the standalone
`hard_drivin_sound_communication_path`. It retains the 512-by-16 communication
RAM as one `$mem_v2` and reports 82 abstract cells, seven checks, and zero
structural problems. This supports portable memory inference and control-path
elaboration only; it is not a Quartus mapping, HM6116 timing result, 68000
bridge, or completed sound-board hierarchy.

The eleventh script targets `hard_drivin_sound_bio_generator`. It reports 52
cells, seven retained checks, no memory or latch, and zero structural problems.
This qualifies the explicit-enable divide-by-50, reset, validity, and CLKOUT
sample structure only; it is not independent-clock electrical timing or a
metastability result.

The twelfth script targets `hard_drivin_sound_host_control`. It reports 53
cells, six retained checks, no memory or latch, and zero structural problems.
This qualifies only the address-encoded LS259 state, board-reset sampling, and
per-bit validity; it is not a 68000 decoder, DTACK path, or physical
level-sensitive latch-timing result.

The thirteenth script targets `hard_drivin_sound_320_port_latch`. It reports
19 cells, five retained checks, no memory or latch, and zero structural
problems. This qualifies only low-byte TMS capture and masked host-lane
carriers, not the undriven byte or physical propagation timing.

The fourteenth script targets `hard_drivin_sound_mailboxes`. It reports 259
cells, ten retained checks, no memory or latch, and zero structural problems.
This qualifies the complete-word callback state and conservative conflict
validity, not physical collision priority, byte behavior, or a 68000 bridge.

The fifteenth script targets the storage-free
`hard_drivin_sound_read_status`. It reports 23 combinational cells, eight
retained checks, no storage or latch, and zero structural problems. This
qualifies only the raw high-nibble mapping and masked digital carrier, not the
undriven low twelve lanes or a complete 68000 read cycle.

The sixteenth script targets the storage-free
`hard_drivin_sound_switches`. It reports 10 combinational cells, six retained
checks, no storage or latch, and zero structural problems. This qualifies only
the raw connector-to-high-nibble mapping and masked carrier, not cabinet
semantics, connector idle levels, undriven low lanes, or a 68000 read cycle.

The seventeenth script targets the storage-free
`hard_drivin_sound_host_read_mux`. It reports 68 abstract cells, 13 retained
checks, no storage or latch, and zero structural problems. This qualifies the
Atari quadrant order and exact mask forwarding only; it is not `/RVAS`, DTACK,
side-effect, open-bus, or physical cycle evidence.

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
