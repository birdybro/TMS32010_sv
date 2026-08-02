# Partial-core synthesis evidence

## 2026-07-31 Quartus fits

These results cover the fifty-eight-instruction explicit fetch/execute RTL,
signed multiplier, 144-word internal data RAM, program-bus phase engine,
native IN/OUT and TBLR/TBLW paths, CALA/RET under ADR-0003's CORROBORATED-RET/
INFERRED-CALA external mapping, and the partial interrupt request/entry
sequencer.
They are not complete-core resource or interface-timing results.

- Tool: Quartus Prime Lite 17.0.2 Build 602, 2017-07-19.
- Target: Cyclone V `5CSEBA6U23I7` (DE10-Nano FPGA).
- Top: synthesis-only `tms32010_synth_top`, elaborating the partial execution
  core through its explicit fetch/execute native-phase wrapper.
- Constraint: 25.0 MHz `clk_i`; non-clock harness ports explicitly false
  pathed until a real integration wrapper defines their timing.
- Analysis/synthesis: successful, 0 errors.
- Fitter: successful, 0 errors.
- TimeQuest: successful, 0 errors.
- Logic: 1,362 ALMs (3%).
- Registers: 400.
- Memory: 2,304 used bits in one M10K block.
- DSP blocks: 1.
- PLLs: 0.
- Worst internal setup slack across analyzed corners: +17.838 ns at 25 MHz.
- Worst internal hold slack across analyzed corners: +0.164 ns.
- Slow-corner internal Fmax: 45.12 MHz at 100 °C, 45.55 MHz at -40 °C.
- Unconstrained clocks, inputs, input paths, outputs, and output paths: 0.

The I/O categories report zero because each of the 415 harness-only interface
pins is explicitly excluded, not because portable-core I/O timing is closed.
The future wrapper must replace every false path with real constraints.
Quartus also labels timing paths involving virtual pins as estimates; the
setup, hold, and Fmax figures above are scoped to internal register paths.

### Critical-path characterization and operand-selection change

The reproducible full-path report first measured the preceding 2,504-ALM
checkpoint from registered `execute_word_o[3]` to `accumulator_o[10]`. Its
33.464 ns data path had 26 logic levels: wrapper decode and program-data
selection fed the core decoder, effective data-address selection, the
asynchronous internal-RAM mux, operand shift, accumulator adder, and result
selection. Interconnect contributed 69% of the measured data delay. This
locates the principal limit in the broad single-boundary execution cone and
the asynchronous RAM, not in CALA/RET target selection alone.

The wrapper already retains accepted control operands and table-read data.
It now selects the branch operand from the registered control-target state
and retains one table-direction bit when a table transfer starts. An assertion
checks that retained direction against the still-owned execute instruction at
the TBLR/TBLW prefetch boundary. This removes a redundant wrapper decode from
the sampled-operand mux without changing any native phase or retirement edge.

The retained-operand checkpoint's worst 100 °C setup path was from registered
`execute_word_o[11]` to `accumulator_o[28]`: 29.180 ns and 19 logic levels,
with 64% interconnect delay. Relative to the preceding checkpoint, the fit
uses 90 fewer ALMs and improves worst slow-corner Fmax from 29.30 MHz to
33.33 MHz. A first intermediate experiment that retained a live TBLR decode
in this mux was rejected after it regressed to 2,633 ALMs and 28.98 MHz.

ADR-0004 then uses the wrapper's existing FPGA subphases to capture internal
RAM data before the architectural boundary. The standalone core remains
asynchronous, while the explicit pipeline selects a registered simple-dual-
port template. A directed `IN`-then-`OUT` test rejected the first old-data-only
mapping because the next owner's phase-0 output word was stale. The accepted
implementation retains same-address write metadata beside the memory and
forwards the committed word through an output mux. A second in-process bypass
form was rejected because Quartus again lowered the array to registers.

The first separately forwarded fit was also rejected after the broad formal
sweep proved its RAM output could advance while the wrapper clock enable was
clear. That checkpoint used 1,420 ALMs and reported 22.988 ns/15 levels and
42.11 MHz worst slow-corner Fmax, but it is not passing evidence. Qualifying
read capture with the wrapper subphase enable restores the existing stall
invariant and produces the accepted figures below.

The accepted RAM-staging fit maps all 2,304 bits into one M10K, reducing the
full hierarchy from 2,414 to 1,416 ALMs and from 2,703 to 417 registers. Its
worst 100 °C setup path was from registered `execute_word_o[14]` to a
multiplier input enable: 24.217 ns, 16 logic levels, and 65% interconnect
delay. Worst slow-corner Fmax rose from 33.33 to 40.54 MHz. Directed traces
preserve
phase-1 operand availability, phase-0 same-address forwarding, every native
program/I/O/table edge, stalls, retirement, and cycle counts; the new
five-step inductive proof covers all 144 RAM words and both forwarding ports.

The next accepted optimization adds one implementation-only decoder qualifier
for instruction families that address internal data memory. The core consumes
that qualifier in its address and validity cones instead of duplicating two
long instruction-family lists. The qualifier has no architectural effect and
must be combined with the decoder's valid result. Simulation visits all 65,536
instruction words and independently checks every valid encoding; the one-step
decoder proof covers the same valid space. That fit retained one M10K and one
DSP, used 1,414 ALMs and 417 registers, and removed the preceding
execute-word-to-multiplier path from the twenty worst setup paths. That
checkpoint's worst 100 °C path is from the retained table-prefetch state to
`stack_bottom_o[2]`:
21.399 ns, 14 logic levels, and 61% interconnect delay. Worst slow-corner
Fmax rose to 44.84 MHz.

The retained-carrier checkpoint replaced the execute-word, branch-operand,
table-read-data, and table-direction carriers plus their combinational state
mux with one context-owned 16-bit core-program register. Normal executable
fetches replace it at ownership boundaries; a control operand or TBLR program
word replaces it one interval before the core consumes it. Clock-enable stalls
cannot reach either update edge. Directed BANZ and TBLR traces inspect capture,
stall hold, consumption, and following-fetch replacement. Both 40-step table
proofs retain their read/write bus, RAM, stack, retirement, and nonvacuity
results. That fit used 1,393 ALMs and 400 registers, retained one M10K
and one DSP, and removes the prior table-state-to-stack cone from the twenty
worst paths. The new worst 100 °C path runs from `core_program_data[4]` to
`accumulator_o[5]`: 20.034 ns, 12 logic levels, and 64% interconnect delay.
Worst slow-corner Fmax was 48.07 MHz.

The next accepted optimization centralizes the common signed 32-bit
addition/subtraction, overflow, wrap, and OVM-result selection in one portable
combinational block. `ADD`, `SUB`, `SUBH`, `APAC`, `SPAC`, `LTA`, and `LTD`
select their operands around that shared relation; the specialized
`ADDS`/`ADDH`/`SUBS`/`SUBC` policies remain separate. The fit uses 1,332 ALMs
and the same 400 registers, one M10K, and one DSP block. The worst 100 °C path
runs from `core_program_data[9]` to `accumulator_o[6]`: 20.016 ns, 13 logic
levels, and 67% interconnect delay. Worst slow-corner Fmax was 48.27 MHz.

The next accepted source extracted the primary-documented 16-bit signed input shift
relation into one portable combinational block shared by `LAC`, `ADD`, and
`SUB`. The block sign-extends before applying the decoded zero-through-15
left shift and does not own decode, addressing, status, or sequencing. The
fit remains 1,332 ALMs, 400 registers, one M10K, and one DSP block. At 100 °C
the worst path now runs from `core_program_data[6]` to `io_read_sample[2]`:
19.408 ns, 13 logic levels, and 62% interconnect delay. The input shifter is
not on this path. Slow-corner Fmax is 49.79 MHz at 100 °C and 49.77 MHz at
-40 °C; the worst setup slack across those corners is +19.907 ns. The
standalone exhaustive proof, rather than that fitter result, qualifies all
1,048,576 data/count relations.

The next accepted source also extracts SACH's separate zero/one/four output shift
into a portable combinational block and retains a core assertion that every
decoded SACH selects one of those modes. The block consumes only ACC[31:12],
because no lower bit can reach the stored high word at the maximum shift.
Quartus now uses 1,372 ALMs with the same 400 registers, one M10K, and one DSP.
The worst 100 °C setup path runs from retained `core_program_data[12]` to
`overflow_flag_o`: 20.866 ns, 14 logic levels, and 69% interconnect delay.
The output shifter is not the endpoint or arithmetic relation on this path.
Slow-corner Fmax is 47.3 MHz at 100 °C and 47.87 MHz at -40 °C; worst setup
and hold slack across all analyzed corners are +18.860 ns and +0.165 ns.
The standalone symbolic proof, not this fit, qualifies every ACC/field
combination and the lower-ACC-bit independence relation.

The preceding source centralized the primary-defined four-level stack
transition relation in one portable combinational block. CALL, CALA, RET,
interrupt entry, and TBLR/TBLW retirement retain their established commit
boundaries; a core invariant rejects overlapping distinct stack operations.
The fit uses 1,352 ALMs with the same 400 registers, one M10K, and one DSP.
The worst 100 °C setup path runs from retained `core_program_data[9]` to
`accumulator_o[24]`: 20.720 ns, 13 logic levels, and 67% interconnect delay.
The stack block is not on the endpoint relation. Slow-corner Fmax is 46.58 MHz
at 100 °C and 47.09 MHz at -40 °C; worst setup and hold slack across all
analyzed corners are +18.530 ns and +0.164 ns. The standalone symbolic proof,
not this fit, qualifies every stack/control combination. The primitive assigns
no `PUSH`/`POP` external cycle under `OQ-016`.

The current source centralizes the primary-defined low-nine-bit AR circular
counter in one portable combinational block. Supported data-addressed
instructions, MAR, BANZ, I/O, and table retirement retain their old-ARP
selection, old-address use, ARP changes, special LAR/SAR ordering, and
established commit edges around that shared relation. A core invariant rejects
simultaneous controls; local hold in that invalid case is fail-closed policy,
not an original-silicon claim under `OQ-010`/`SC-040`. The fit uses 1,362 ALMs
with the same 400 registers, one M10K, and one DSP. The worst 100 °C setup path
runs from retained `core_program_data[8]` to `accumulator_o[0]`: 21.476 ns,
14 logic levels, and 67% interconnect delay. The auxiliary counter is not the
endpoint relation. Slow-corner Fmax is 45.12 MHz at 100 °C and 45.55 MHz at
-40 °C; worst setup and hold slack across all analyzed corners are +17.838 ns
and +0.164 ns. The standalone symbolic proof, not this fit, qualifies every
value/exclusive-control combination.

The first explicit-pipeline fit retained the old 50 MHz exploratory objective.
It failed slow-corner setup by -8.999 ns at 100 °C and -9.098 ns at -40 °C;
the fitted slow-corner Fmax was 34.48/34.37 MHz. That checkpoint is rejected,
not timing closure. The qualified 25 MHz constraint still exceeds the A044427
Rev-A board's primary-documented 20 MHz input by 25%; the current 45.12 MHz
worst slow-corner result is a 125.6% margin over the board frequency. The
explicit pipeline's 50 MHz critical path remains an optimization opportunity,
not a release requirement or a concealed pass. The retained-direction,
RAM-staging, decoder-qualification, retained-carrier, shared-arithmetic, and
input/output-shifter, stack, and auxiliary-counter changes raise the qualified
worst slow-corner result to 45.12 MHz, but do not turn
that historical 50 MHz run into a pass.

The first LT fit exposed the newly added 16-bit T diagnostic port without
matching SDC exclusions. TimeQuest reported all 16 outputs unconstrained, so
that run was rejected even though place-and-route succeeded. Adding the exact
T port to the synthesis-harness false-path list restored zero unconstrained
categories in the full rerun. This exclusion remains harness-scoped and is not
a claim of wrapper I/O timing.

The portable multiplier infers one Cyclone V DSP block without a
vendor-specific primitive. This is a technology mapping result, not an
architectural dependency.

The reports contain no latch diagnostic. Analysis/synthesis and TimeQuest
finish with zero warnings. The three full-flow warnings are the expected
synthesis-harness notices: a Lite-only LogicLock notice, incomplete I/O
assignments, and the sole physical clock's intentionally absent package
location. Quartus infers the phase-aware 144-word array as a 144-by-16 simple-
dual-port `altsyncram` and fits it into one M10K; the standalone core's default
remains asynchronous. The fit uses 415
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

The twenty worst internal setup paths, including full routing and logic-level
detail, can be regenerated after a fit with:

```sh
cd synthesis/quartus
/path/to/quartus/bin/quartus_sta -t report_setup.tcl
```

The generated `build/quartus/setup_paths.rpt` is intentionally untracked.

## Yosys status

Yosys 0.67+111 from the 2026-07-29 OSS CAD Suite successfully elaborates and
synthesizes the same integrated partial hierarchy. Both pre- and
post-synthesis `check -assert`
passes report zero problems; no latches are inferred, 128 RTL checks
remain represented, and the synthesis harness and directly targeted pipeline
contain 15,941 and 15,929 cells respectively. The
registered array and forwarding logic lower to flip-flops and muxes under
generic synthesis, leaving no inferred memories after technology mapping. This
is a portability smoke test, not an FPGA resource estimate. The standalone
signed multiplier accounts for 1,753 of those generic cells; unlike Quartus,
generic Yosys synthesis does not map it to a target DSP resource.

The second checked-in script directly synthesizes
`tms32010_sequential_pipeline_slice`. After exact B, BANZ, BV, BIOZ, CALL, and
the six accumulator branches, plus exact IN/OUT transfer and
following-prefetch ownership, exact TBLR/TBLW discarded-prefetch/table-
transfer/repeated-prefetch ownership, and the basic Figure 2-12 interrupt
path, plus ADR-0003 CALA/RET ownership, it passes both structural checks with
zero reported problems, retains 128 RTL checks, and contains 15,929 generic
cells. Extracting the input shifter removed 11 cells from the preceding
16,183-cell shared-accumulator checkpoint without changing the retained-check
count; the independently proved standalone input shifter maps to 89 cells.
Extracting the output shifter then added 21 mapped cells and one retained
decoded-SACH legality invariant; its independently proved standalone block
maps to 86 combinational cells. Sharing stack transitions across five current
owners then added 47 mapped cells and one control-valid invariant; the
independently proved standalone stack relation maps to 92 combinational cells.
Sharing the auxiliary-counter relation across the current qualified owners
then removed 311 mapped cells and added one control-valid invariant; the
independently proved standalone counter maps to 54 combinational cells. The
shared accumulator primitive had removed 343 cells and added one
retained saturation-selection invariant relative to the retained-carrier
checkpoint. The single retained carrier had removed 423 cells from the preceding
16,949-cell decoder-qualifier checkpoint. Eliminating the now-absent table-
direction state also removes its consistency assertion; directed carrier
checks and both composed table proofs retain the behavior that assertion
guarded. ADR-0004 and the decoder family qualifier had added 443 generic cells
beyond the 16,506-cell retained-table-direction checkpoint because target-
neutral Yosys maps the memory and bypass to gates rather than a Cyclone V
M10K. The retained table-direction checkpoint had added 226 generic cells and one
check to the 16,280-cell/124-check CALA/RET checkpoint even though Cyclone V
technology mapping uses 90 fewer ALMs; generic cells are not a device-resource
estimate. CALA/RET had added 547 cells and 21 checks to the preceding
15,733-cell/103-check checkpoint. Reset-time instruction qualification and
direct recognized-boundary derivation had added 47 cells to the earlier
15,686-cell checkpoint without changing its retained-check count.
The ADDH increment added 75
cells without adding or removing retained checks; SST added 76 cells and ABS
added 170 cells in the preceding checkpoints. The current result is 800 cells
and 50 checks above the pre-table 15,129-cell/78-check checkpoint, 894 cells
and 61 checks above the IN/OUT 15,035-cell/67-check checkpoint, 1,151 cells/79
checks above the exact-CALL 14,778-cell/49-check checkpoint, 1,214 cells/81
checks above the exact-BIOZ 14,715-cell/47-check checkpoint, 1,653 cells/86
checks above the exact-B/BANZ 14,276-cell/42-check checkpoint, and 1,989 cells/96
checks above the
one-cycle-only 13,940-cell/32-check checkpoint. The result is a portability
smoke test for the narrow explicit-pipeline subset, not a Quartus fit or an
instruction-complete resource estimate.

The third checked-in script directly synthesizes `tms32010_mister` around the
same explicit-pipeline hierarchy. Yosys 0.67+111 passes both structural checks
with zero problems, retains 135 checks, and reports 15,978 generic cells. The
adapter itself contributes 49 cells and seven checks beyond the 15,929-cell,
128-check pipeline checkpoint. This result covers the five-cycle synchronous
reset stretcher, registered same-clock callback wait, request mapping, and
debug fanout only. It is not an SDRAM/CDC qualification, Quartus fit, board
pinout, I/O timing result, or evidence for unresolved PUSH/POP bus ownership.

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
`hard_drivin_sound_mister`. Yosys 0.67+111 reports 3,787 abstract cells, 413
retained checks, and six `$mem_v2` objects: the synchronous 4K-by-16 shared
program RAM, synchronous 512-by-16 communication RAM, the core's phase-staged
144-by-16 internal RAM, and the optional local SRAM's upper,
lower, and validity arrays.
Both structural checks pass with zero problems. This proves hierarchy and
memory retention plus the opt-in BIO/host-control/host-timing selection,
original-MC68000 local byte-write normalization, and mailbox/raw-status
boundaries only; it is not a
technology-mapped utilization, block-RAM
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
`hard_drivin_sound_host_read_mux`. Yosys 0.67+111 reports 72 abstract cells
with 13 retained checks, no storage or latch, and zero structural problems.
This proves only invalid-selection suppression, physical quadrant order,
one-hot target visibility, and masked-source forwarding; it is not a 68000
strobe/DTACK, side-effect, open-bus, or timing implementation.

The eighteenth checked-in script targets `hard_drivin_sound_host_timing`.
Yosys 0.67+111 reports 142 abstract cells with 24 retained checks, no memory
or latch, and zero structural problems. Together with the exhaustive
simulation, this qualifies only the same-clock logical edge adaptation,
`/RVF` alias qualification, VPA
suppression, exact low-I/O target order, and fixed no-retry completion. It is
not raw-pin CDC, physical F74 startup, complete TTL timing closure, or a
Cyclone V fit.

The nineteenth checked-in script targets the storage-free
`hard_drivin_sound_local_memory_decode`. Yosys 0.67+111 reports 56 abstract
combinational cells with 17 retained checks, no memory or latch, and zero
structural problems. Together with exhaustive simulation, this qualifies the
Rev-A ROM/high-bank/Y5/local-RAM equations, populated word-address
projections, and local byte lanes. It does not qualify memory contents,
raw-pin timing, a 68000 implementation, or a Cyclone V fit.

The twentieth checked-in script targets the composed storage-free
`hard_drivin_sound_local_memory_bridge` hierarchy. Yosys 0.67+111 reports 305
abstract combinational cells with 40 retained checks, no memory or latch, and
zero structural problems. This qualifies callback decode, exact S6/S7 event
selection, and validity-mask carriers only; it does not qualify storage,
raw-pin timing, a 68000 implementation, or a Cyclone V fit.

The twenty-first checked-in script targets `hard_drivin_sound_local_ram`.
Yosys 0.67+111 retains its two 8K-by-8 data arrays and two-bit validity array
as three `$mem_v2` objects and reports 88 abstract cells with nine checks, no
latch, and zero structural problems. This is an FPGA storage-structure check,
not physical 6264 initialization or AC timing evidence.

The twenty-second checked-in script targets the storage-free
`hard_drivin_sound_direct_io`. Yosys 0.67+111 reports 336 abstract
combinational cells with seven retained checks, no memory or latch, and zero
structural problems. Together with exhaustive simulation and the one-step
symbolic proof, this qualifies exact address decode and mask composition only;
it is not an electrical host/TMS arbitration or open-bus result.

The twenty-third checked-in script targets the storage-free
`hard_drivin_sound_local_reset_interlock`. Yosys 0.67+111 reports 13
combinational cells with seven retained checks, no memory or latch, and zero
structural problems. Together with exhaustive simulation and the one-step
symbolic proof, this qualifies only the FPGA RESET/HALT release equation; it
is not MC68000 reset duration, physical HALT behavior, CDC, or electrical
timing evidence.

The twenty-fourth through twenty-ninth checked-in scripts qualify the newer
board-boundary blocks at the same pre-technology level:

| target | cells | retained checks | qualified scope |
|---|---:|---:|---|
| `hard_drivin_sound_local_reset_source` | 28 | 7 | caller-calibrated LS123 hold/retrigger state |
| `hard_drivin_main_sound_reset_decode` | 16 | 4 | physical `/SRES` address/control decode |
| `hard_drivin_main_rvas_timing` | 93 | 25 | same-clock request and held-strobe state |
| `hard_drivin_main_dtack_decode` | 21 | 8 | complete combinational acknowledgement cone |
| `hard_drivin_main_address_decode` | 49 | 20 | primary/RAM/HSBUS TTL decode |
| `hard_drivin_main_bus_control` | 185 | 64 | address-driven timing/decode composition |

Each reports zero structural problems. Their documented exclusions remain
physical RC tolerance, raw-pin CDC, peripheral latency, electrical timing,
power-up state, and Cyclone V fitting as applicable.

The thirtieth checked-in script targets the storage-free
`hard_drivin_mc68000_write_word`. Yosys 0.67+111 reports 39 mapped cells with
three retained checks, no memory or latch, and zero structural problems. It
qualifies only the exhaustive-tested original-MC68000 word/duplicated-byte
mapping used before an unqualified pair of LS374s. It is not a substitute-68k
bus contract, raw-pin timing, CDC, or physical mailbox fit.

The thirty-first checked-in script targets the storage-free
`tms32010_accumulator` combinational arithmetic block. Yosys 0.67+111 reports
367 mapped cells, no retained assertion, memory, latch, or register, and zero
structural problems. This qualifies portable elaboration of the signed
add/subtract, overflow, wrap, and OVM-result relation; the separate symbolic
proof supplies exhaustive functional evidence. It is not an instruction-
sequencing, sticky-OV, technology-timing, or Cyclone V fit result.

The thirty-second checked-in script targets the storage-free
`tms32010_input_shifter` combinational barrel shifter. Yosys 0.67+111 reports
89 mapped cells, no retained assertion, memory, latch, or register, and zero
structural problems. This qualifies portable elaboration only; the separate
symbolic proof supplies exhaustive signed-extension/shift evidence, and the
result is not instruction-timing or Cyclone V fit evidence.

The thirty-third checked-in script targets the storage-free
`tms32010_output_shifter` combinational SACH path. Yosys 0.67+111 reports 86
mapped cells, no retained assertion, memory, latch, or register, and zero
structural problems. This qualifies portable elaboration only; the separate
symbolic proof supplies the exhaustive full-ACC/field relation.

The thirty-fourth checked-in script targets the storage-free
`tms32010_stack` combinational transition relation. Yosys 0.67+111 reports 92
mapped cells, no retained assertion, memory, latch, or register, and zero
structural problems. This qualifies portable elaboration only; the separate
symbolic proof supplies exhaustive stack/control evidence, and neither result
assigns instruction sequencing or an external bus cycle.

The thirty-fifth checked-in script targets the storage-free
`tms32010_auxiliary_counter` combinational relation. Yosys 0.67+111 reports 54
mapped cells, no retained assertion, memory, latch, or register, and zero
structural problems. This qualifies portable elaboration only; the separate
symbolic proof supplies exhaustive hold/exclusive-update evidence. Neither
result assigns selected-AR ownership, instruction timing, or original-silicon
behavior for simultaneous controls.

The host executable path does not contain Yosys, so a direct
`make synth-yosys` still fails explicitly with `ERROR: Yosys is required`.
The successful run used the official 2026-07-29 Linux-x64 OSS CAD Suite
release after verifying its published SHA-256
`89ea1152ea84bc600f18cc685f721d534d1f018e09831662787865a3d79ce4aa`:

```sh
make YOSYS=/path/to/oss-cad-suite/bin/yosys synth-yosys
```

The ignored outputs are `build/yosys/tms32010_input_shifter.json`,
`build/yosys/tms32010_output_shifter.json`,
`build/yosys/tms32010_stack.json`,
`build/yosys/tms32010_auxiliary_counter.json`,
`build/yosys/tms32010_accumulator.json`,
`build/yosys/tms32010.json`,
`build/yosys/tms32010_sequential_pipeline.json`, and
`build/yosys/tms32010_mister.json`; the board-specific scripts also write
ignored JSON outputs including
`build/yosys/hard_drivin_sound_communication_path.json`,
`build/yosys/hard_drivin_sound_local_memory_bridge.json`,
`build/yosys/hard_drivin_sound_local_ram.json`,
`build/yosys/hard_drivin_sound_direct_io.json`,
`build/yosys/hard_drivin_sound_local_reset_interlock.json`,
`build/yosys/hard_drivin_sound_bio_generator.json`,
`build/yosys/hard_drivin_sound_host_control.json`,
`build/yosys/hard_drivin_sound_320_port_latch.json`,
`build/yosys/hard_drivin_sound_mailboxes.json`,
`build/yosys/hard_drivin_mc68000_write_word.json`, and
`build/yosys/hard_drivin_sound_read_status.json`. Tool-version differences
make the generic cell count unsuitable for direct comparison with the earlier
Yosys 0.33 result; only same-version changes should be treated as utilization
regressions.
