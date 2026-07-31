# Hard Drivin' Driver Sound FPGA wrapper

## Status and scope

`rtl/wrappers/hard_drivin_sound_mister.sv` is a partial, same-clock FPGA top
for the qualified processor slice and Atari A044427 Rev-A program and
communication-memory paths.
It combines the generic `tms32010_mister`, the board-native decoder, and the
4K-by-16 shared program RAM. It now also connects the separately qualified
512-by-16 communication RAM and sound-address controls to processor input port
1. It does not implement the 68000 bus/latches, sound-ROM shifter, compare
circuit, DAC analog path, mute/IRQ consumers, BIO divider, or a MiSTer
framework top level.

The wrapped processor still omits CALA, RET, PUSH, and POP from RTL and retains
the timing and silicon uncertainties in `docs/research/open_questions.md`.
This wrapper is therefore not evidence that the project is instruction-
complete, cycle-accurate, or release-ready.

## Clock and reset boundary

All inputs are synchronous to `clk_i`. `initialize_i` performs the explicit
FPGA-only deterministic state initialization. `dsp_reset_n_i` represents the
board's active-low `/320RES` latch output and enters the generic wrapper as a
separate processor-reset request. Holding `/320RES` low does not clear shared
program RAM; each release invokes the generic five-enabled-machine-cycle reset
hold and the qualified inactive release cycle before address-zero fetch.

This separation matters during a firmware reload: applying deterministic
initialization to every physical reset would be a needless FPGA divergence,
while clearing program RAM would break the board's host-load protocol. The
physical TMS-side buffers disable immediately when `/320RES` falls; the
processor itself recognizes reset at its documented falling-CLKOUT boundary
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets 3–4 of 10,
PDF pp. 5–8; ti-tms32010-users-guide-spru001b, §2.5 and Appendix A reset
timing, printed p. 2-19 and data-sheet p. 19 (PDF pp. 43 and 375)].
**Confidence: VERIFIED_PRIMARY for the physical relationships;
VERIFIED_SIMULATION for this synchronous FPGA adaptation.**

## Safe host-load sequence

The required same-clock sequence is:

1. assert `dsp_reset_n_i=0`;
2. assert `host_program_select_n_i=0` only after the host begins its RAM access;
3. supply a complete 12-bit word address and 16-bit write word;
4. pulse `host_commit_i` once for each write accepted with `host_ready_o=1`;
5. release `host_program_select_n_i=1`;
6. verify `ownership_conflict_o=0`; and
7. release `dsp_reset_n_i=1`.

The host callback is whole-word only because A044427 routes A12:A1, D15:D0,
and one RAM write strobe without UDS/LDS lane enables. `SC-022`/`OQ-022`
govern byte accesses. If host selection overlaps released DSP reset,
`ownership_conflict_o` asserts and neither storage path is acknowledged. The
wrapper does not choose a protective winner and call that physical behavior.

## Communication-RAM host sequence

`communication_host_enable_i` represents the external CRAMEN latch state.
When high, the `host_communication_*` whole-word callback owns the 512-word
memory and processor port 1 is blocked. The host may pulse
`host_communication_commit_i` once for a selected write accepted with
`host_communication_ready_o=1`. When CRAMEN returns low, the host callback is
disabled and processor port 1 reads the word at `sound_address_o[8:0]`.

CRAMEN is deliberately not derived from `/320RES`: the drawing shows it as a
separate host LS259 output cleared by board `/RESET`. This wrapper exposes the
latch output but does not implement the 68000 decode that controls it. Host
byte lanes and DTACK remain unresolved integration work under
`SC-025`/`OQ-024`.

## Physical I/O callback

`io_port_o`, `io_read_o`, `io_write_o`, `io_write_data_o`, `io_ready_i`, and
`io_read_data_i` represent the board's physical low-eight target after native
address/MEN/DEN/WE decode. `io_commit_o` pulses at an enabled phase-3 boundary
when the physical request and selected target readiness are both active.
Processor port-1 reads take their data/readiness from the internal
communication path; the external `io_read_data_i` and `io_ready_i` are ignored
for that target. All other ports continue to use the external callback.
Consumers commit writes or count reads only on `io_commit_o`, not on every
FPGA clock for which a request remains asserted. The same pulse drives the
shared address control, so every committed input read—including external
ports 0/2 and internal port 1—increments the full 16-bit address once. Port 7
loads that address and port 6 latches the separate low block nibble.

This physical callback intentionally differs from the generic logical split.
A TBLW to address 0–7 arrives as `io_write_o`, receives readiness from
`io_ready_i`, and never acknowledges or writes program RAM. TBLW at address 8
or above receives readiness from the shared RAM. IN/OUT use the same physical
callback. This is the A044427 alias documented by `SC-021`.

The production Rev-A TMS interrupt input is tied internally inactive-high.
`bio_i` remains an external active-low input because the board-specific divider
and CLKOUT resynchronizer are not implemented yet.

## Verification and synthesis

`sim/bus/tb_hard_drivin_sound_mister.sv` host-loads the committed ROM-free
Hard Drivin' smoke fixture, initializes only its project-authored data words,
performs a safe host-to-DSP handoff, and executes the program in RTL. It checks
five reset cycles, 12 retirements, the documented 22-cycle total, six output
writes, three input reads, the BIOZ branch, final accumulator, and raw DAC word.

The test then reasserts only processor reset, reloads a LACK/TBLW/NOP program,
and proves a low-address TBLW commits once through output port 3 while shared
RAM word 3 retains the unsupported park word. A final host read verifies the
unchanged word. No Atari ROM data is used.

Before the first execution, the test also uses CRAMEN host ownership to load
communication word `0x056` with `0x55aa`, releases that ownership, and runs a
corrected synthetic sequence that loads port 7 before the first input read.
The processor receives the internal word even though the external port-1
callback supplies a deliberately different sentinel. Port-1, port-0, and
port-2 reads advance the shared address from `0x3456` to `0x3459`; port 6
retains block nibble `0xb`. A processor-reset/host-read handoff then proves the
communication word survived execution and reset.

The pre-technology Yosys target retains three memories and reports 2,259
abstract cells with 131 checks and zero structural problems. This is not a
Cyclone V fit, block-RAM placement result, TimeQuest result, 68000 bridge
qualification, or complete Driver Sound emulation.
