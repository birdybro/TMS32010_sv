# Hard Drivin' Driver Sound FPGA wrapper

## Status and scope

`rtl/wrappers/hard_drivin_sound_mister.sv` is a partial, same-clock FPGA top
for the qualified processor slice and Atari A044427 Rev-A program and
communication-memory, sample-ROM, raw DAC-latch, output-control, and opt-in
board-BIO and host-control paths.
It combines the generic `tms32010_mister`, the board-native decoder, and the
4K-by-16 shared program RAM. It now also connects the separately qualified
512-by-16 communication RAM and sound-address controls to processor input port
1 and routes port 0 through a present-block-aware byte callback.
It does not implement the 68000 bus/address decoder, actual sample storage,
the optional unpopulated compare circuit, DAC analog path, a loaded mute consumer, a board 1 MHz
clock-enable source, or a MiSTer framework top level.

The separately qualified `hard_drivin_sound_host_control` is connected behind
`use_host_control_i`. The default false setting still accepts `/320RES` as
`dsp_reset_n_i` and CRAMEN as `communication_host_enable_i`; selecting the
board path instead uses LS259 Q4 and Q3. Raw latch state, per-bit validity, and
validity of both selected controls remain visible. `/IRQCLR` is electrically
separate from LS259 `80R` and remains the explicit
`host_irq_clear_commit_i` callback. No `/RVAS` generator, 68000 address
decoder, byte-lane logic, or DTACK path is implied by this opt-in selection.

The wrapped processor still omits CALA, RET, PUSH, and POP from RTL and retains
the timing and silicon uncertainties in `docs/research/open_questions.md`.
This wrapper is therefore not evidence that the project is instruction-
complete, cycle-accurate, or release-ready.

## Clock and reset boundary

All inputs are synchronous to `clk_i`. `initialize_i` performs the explicit
FPGA-only deterministic state initialization. The selected reset is either the
default external `dsp_reset_n_i` callback or opt-in LS259 Q4, both representing
the board's active-low `/320RES` latch output. It enters the generic wrapper as
a separate processor-reset request. Holding `/320RES` low does not clear shared
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

1. hold the selected `/320RES` low, using `dsp_reset_n_i=0` in the default
   mode or board-reset-cleared/Q4-low state in host-control mode;
2. assert `host_program_select_n_i=0` only after the host begins its RAM access;
3. supply a complete 12-bit word address and 16-bit write word;
4. pulse `host_commit_i` once for each write accepted with `host_ready_o=1`;
5. release `host_program_select_n_i=1`;
6. verify `ownership_conflict_o=0`; and
7. release the selected `/320RES`, using `dsp_reset_n_i=1` or a decoded Q4
   write as selected.

The host callback is whole-word only because A044427 routes A12:A1, D15:D0,
and one RAM write strobe without UDS/LDS lane enables. `SC-022`/`OQ-022`
govern byte accesses. If host selection overlaps released DSP reset,
`ownership_conflict_o` asserts and neither storage path is acknowledged. The
wrapper does not choose a protective winner and call that physical behavior.

## Communication-RAM host sequence

The selected CRAMEN is either default external
`communication_host_enable_i` or opt-in LS259 Q3. When high, the
`host_communication_*` whole-word callback owns the 512-word
memory and processor port 1 is blocked. The host may pulse
`host_communication_commit_i` once for a selected write accepted with
`host_communication_ready_o=1`. When CRAMEN returns low, the host callback is
disabled and processor port 1 reads the word at `sound_address_o[8:0]`.

CRAMEN is deliberately not derived from `/320RES`: the drawing shows it as a
separate host LS259 output cleared by board `/RESET`. The opt-in path updates
that output only from an explicit decoded completion. Host byte lanes,
`/RVAS`, address decode, and DTACK remain unresolved integration work under
`SC-025`/`OQ-024`.

## Parallel sample-ROM callback

`sound_rom_present_i[11:0]` explicitly declares which of the twelve decoded
positions the integration can supply. A valid port-0 read asserts
`sound_rom_request_o` with `sound_rom_request_block_o` and the pre-increment
`sound_rom_request_address_o`. The integration returns one authorized byte and
`sound_rom_byte_ready_i`; the wrapper constructs the exact physical signed-
byte-left-seven word. Invalid or absent selections assert
`sound_rom_selection_invalid_o`, remain unacknowledged, and therefore hold the
processor rather than fabricating an open-bus zero. `OQ-026` still governs the
unmeasured electrical value of those out-of-contract reads.

This callback is same-clock and storage-free. It does not establish ROM access
time, contain copyrighted bytes, or permit a ROM image to be committed.

## Raw DAC latch

Processor port-0 writes are acknowledged internally because A044427's `/DACL`
target is an edge-triggered latch with no wait input. A committed write captures
only `io_write_data_o[15:4]` into `dac_code_o`, sets `dac_code_valid_o`, and
pulses `dac_commit_o` for one FPGA clock. The external `io_ready_i` cannot
delay this target, although the physical I/O request and general commit remain
visible for tracing.

The latch has no processor-reset input, matching the absence of a clear on the
drawn LS374 path. `initialize_i` starts its FPGA validity false without claiming
a physical power-up code. `dac_code_o` is the uncomplemented Am6012 input code;
the analog transfer, signed PCM interpretation, and pinned MAME bit-11 XOR are
deliberately absent under `SC-019`/`OQ-020`.

## Output-control LS74s

Ports 4 and 5 are also acknowledged internally because their LS74 targets
have no wait input. A completed port-4 write captures complement
`io_write_data_o[0]` into the physical `mute_net_o` and pulses
`mute_commit_o`. This is the raw `/Q` net, not permission to gate audio: the
only Rev-A analog consumer is marked `NOT LOADED` and remains unresolved under
`SC-027`/`OQ-027`.

Any visible port-5 write request sets active-high `irq_68000_o` independently
of data, matching `/68IRQ` on the LS74 asynchronous preset. The level remains
asserted until `host_irq_clear_commit_i` clocks the grounded D input or
the selected reset applies `/320RES`. The host callback is a same-clock FPGA
boundary, not a 68000 address decoder or physical `/IRQCLR` pulse model. See
`hard_drivin_sound_control.md` for the pin-level provenance and confidence.

## Opt-in board BIO

The external active-low `bio_i` remains the default portable callback when
`use_board_bio_i=0`. When explicitly selected, the integrated
`hard_drivin_sound_bio_generator` supplies the processor BIO level and exposes
the divider state, raw `/320BIO`, CLKOUT-sampled board BIO, and validity of
each stage. `selected_bio_valid_o` is always true for the external callback
contract and otherwise follows the board resampler validity; selecting an
unqualified deterministic FPGA bit does not turn it into a known physical
power-up value.

`bio_one_mhz_rise_i` is a same-clock event enable supplied by the surrounding
board implementation. The top derives the CLKOUT rising event internally from
the processor's modeled phase advance, so software cannot sample a separately
invented CLKOUT schedule. The generator asserts that these two enables do not
coincide. This explicitly contains `OQ-028`: a future clock adapter must avoid
the unresolved same-edge case or replace that contract only after stronger
evidence establishes its behavior. `board_reset_n_i` represents global board
`/RESET` and is deliberately distinct from the selected `/320RES`. See
`hard_drivin_bio.md` for the primary divider/resampler provenance.

## Physical I/O callback

`io_port_o`, `io_read_o`, `io_write_o`, `io_write_data_o`, `io_ready_i`, and
`io_read_data_i` represent the board's physical low-eight target after native
address/MEN/DEN/WE decode. `io_commit_o` pulses at an enabled phase-3 boundary
when the physical request and selected target readiness are both active.
Processor port-0 reads take their data/readiness from the sample-ROM callback,
and port-1 reads from the internal communication path; the external `io_read_data_i` and `io_ready_i` are ignored
for both targets. Port 2 deliberately remains external because Rev-A `/CMPRD`
routes only unpopulated-source `CMPOUT` to `TDI15` and does not define a full
read word (`SC-029`/`OQ-029`). A caller must explicitly provide its data and
ready policy; the wrapper does not hardwire MAME's zero-return stub. Port-0,
port-4, and port-5 writes use internal always-ready
latches; other physical targets continue to use the external callback.
Consumers commit writes or count reads only on `io_commit_o`, not on every
FPGA clock for which a request remains asserted. The same pulse drives the
shared address control, so every committed input read—including internal ports
0/1 and external port 2—increments the full 16-bit address once. Port 7
loads that address and port 6 latches the separate low block nibble.

This physical callback intentionally differs from the generic logical split.
A TBLW to address 0–7 arrives as `io_write_o` and never writes program RAM.
Addresses 0, 4, and 5 receive their internal latch readiness, while addresses
1–3, 6, and 7 still receive `io_ready_i`; TBLW at address 8 or above receives
readiness from the shared RAM. IN/OUT use the same physical callback. This is
the A044427 alias documented by `SC-021`.

The production Rev-A TMS interrupt input is tied internally inactive-high.
The active-low BIO input is selected between the default external callback and
the explicit board generator described above.

## Verification and synthesis

`sim/bus/tb_hard_drivin_sound_mister.sv` host-loads the committed ROM-free
Hard Drivin' smoke fixture, initializes only its project-authored data words,
performs a safe host-to-DSP handoff, and executes the program in RTL. It checks
five reset cycles, 12 retirements, the documented 22-cycle total, six output
writes, three input reads, the BIOZ branch, final accumulator, and raw DAC word.

The test then reasserts only processor reset, reloads a LACK/TBLW/NOP program,
and proves a low-address TBLW commits once through output port 3 while shared
RAM word 3 retains the unsupported park word. The internal LS374 model
captures low byte `0x30` from `0xf230` and exposes host carrier `0x3000` with
driven/valid mask `0xff00`, even though external callback readiness is held
low. A final host read verifies the unchanged word. It then reloads a second
five-cycle sequence targeting address
zero while the external port-0 callback remains unready. `TBLW` captures
internal word `0x00a5` once as raw DAC code `0x00a`, and a host readback proves
program word zero remains the original `LACK 0` opcode `0x7e00`. This directly
tests that the physical alias uses internal `/DACL` readiness rather than the
external callback. No Atari ROM data is used.

Finally, the test loads a synthetic `BIOZ` fixture while holding the external
BIO high. A scheduled 1 MHz terminal edge reloads the divider to `0xce`; the
internally derived following CLKOUT edge samples the generated low level. The
test opts into that qualified board path, proves `BIOZ` takes only the
`LACK 0x22` target in three total instruction cycles, then proves the later
source release reaches the selected input only on another modeled CLKOUT
sample. This is same-clock FPGA integration evidence, not physical
independent-crystal timing.

Before the first execution, the test also uses CRAMEN host ownership to load
communication word `0x056` with `0x55aa`, releases that ownership, and runs a
corrected synthetic sequence that loads port 7 before the first input read.
The processor receives the internal word even though the external port-1
callback supplies a deliberately different sentinel. Port-1, port-0, and
port-2 reads advance the shared address from `0x3456` to `0x3459`; port 6
retains populated block nibble `0x3`. A processor-reset/host-read handoff then
proves the communication word survived execution and reset. Port 0 also
ignores an external unsigned-MAME sentinel, holds block 3/address `0x3457`
stable through three unready clocks, maps synthetic byte `0xd5` to `0xea80`,
and commits once. The port-0 output ignores a deliberately unready external
callback, captures raw word `0xf230` once as code `0xf23`, and never emits the
distinct MAME-derived `0x723` value. Ports 4 and 5 also ignore deliberately
unready external callbacks: TD0=1 drives raw `MUTE` low exactly once, the
data-independent IRQ latch asserts, a host-clear pulse clears only the IRQ,
and the following `/320RES` returns raw `MUTE` high.

The final test phase opts into the host-control path with the external reset
and CRAMEN callbacks held at opposite sentinel values. Board reset qualifies
all LS259 outputs low. Q4 then permits a synthetic three-word program load and
safe DSP release; Q3 permits one communication-word load and returns it to DSP
ownership. The DSP executes `LACK 0x5a` and `NOP` in two instruction cycles.
Q4 subsequently disables TMS ownership and reasserts processor reset, after
which Q3 grants a synchronous host readback of the preserved word `0x1357`.
This is an end-to-end same-clock callback test, not a physical 68000 bus test.

The pre-technology Yosys target retains three memories and reports 2,495
abstract cells with 171 checks and zero structural problems. This is not a
Cyclone V fit, block-RAM placement result, TimeQuest result, 68000 bridge
qualification, or complete Driver Sound emulation.
