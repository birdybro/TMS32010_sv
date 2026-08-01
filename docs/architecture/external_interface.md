# Native external interface research

## Architectural transactions versus physical pins

The reusable core will expose distinct program, data, and I/O transactions
for verification while retaining enough phase information to reconstruct the
documented pins. A pin-compatibility wrapper may multiplex them onto the
original 16-bit data bus and address/control signals. This separation is an
implementation decision; it must not merge address spaces or hide bus order.

The physical TMS32010 interface includes:

- 12 program-address outputs, with `A2..A0` multiplexed as `PA2..PA0` for I/O;
- a bidirectional 16-bit data bus;
- active-low `MEN`, `DEN`, and `WE`;
- active-low `RS`, `INT`, and `BIO`;
- `CLKIN`, `CLKOUT`, and oscillator pins;
- `MC/MP` mode selection.

`MEN`, `DEN`, and `WE` are mutually exclusive. `DEN` identifies `IN`;
`WE` identifies `OUT` and `TBLW`; `MEN` identifies external program-memory
activity including the table-read phase
[ti-tms32010-users-guide-spru001b, §§2.3–2.5 and Figures 2-10–2-12,
printed pp. 2-15–2-19 (PDF pp. 39–43)]. **Confidence: VERIFIED_PRIMARY.**

Table 2-4 is stronger than a transaction-family summary: it says `MEN` is
active low on every machine cycle except while `WE` or `DEN` is active
[ti-tms32010-users-guide-spru001b, Table 2-4, printed p. 2-21
(PDF p. 45)]. This constrains both execution intervals of the one-word,
two-cycle PUSH/POP instructions because neither has an I/O or program-write
transfer. It does not identify the address or fetched-word validity of each
interval. `SC-018`/`OQ-016` therefore prohibit both an invented idle cycle and
an invented repeated/speculative prefetch; the physical experiment is defined
in `docs/research/push_pop_bus_experiment.md`. **Confidence:
VERIFIED_PRIMARY for strobe activity; UNKNOWN for PUSH/POP address and word
ownership.**

US4577282A independently gives the same every-state external-read rule for a
related contemporary TI DSP embodiment. Its instruction table omits the
production accumulator PUSH/POP opcodes, so it corroborates the general
control architecture without identifying either missing address
[ti-dsp-microcomputer-patent-us4577282a, patent cols. 5-6 and 34-36 (PDF
pp. 29 and 43-44)].

TI's TMS32010 EVM further rejects a breakpoint at the word after PUSH/POP,
and its breakpoint RAM is indexed by the processor program-address bus. This
corroborates external `N+1` visibility in the multicycle context, but the
address-driven breakpoint circuit and manual provide no `MEN` phase, repeat
count, or next address. It does not select an RTL sequence
[ti-tms32010-evm-users-guide-spru005a, SB note 7, printed p. 3-58 (PDF
p. 99), and §9.3, printed pp. 9-2 through 9-3 (PDF pp. 179-180)].

The data sheet establishes falling `CLKOUT` as the input sampling boundary.
Address transition begins after a falling edge, a read strobe asserts about
one quarter-cycle later, and address/strobe remain stable through the next
falling edge. See `docs/timing/native_phase_contract.md`
[ti-tms32010-users-guide-spru001b, Appendix A data sheet, printed
pp. 13–18 (PDF pp. 369–374)]. **Confidence: VERIFIED_PRIMARY.**

The current `tms32010_phase_slice` wrapper implements and tests this normal
read relationship for the 41 supported one-cycle sequential instructions and
both cycles of `B`, `BANZ`, `BIOZ`, `BV`, `CALL`, the six
accumulator-conditional branches, `IN`, and `OUT`. Its `ADD`, `ADDH`, `ADDS`, `AND`,
`DMOV`, `LAC`, `LAR`, `LDP`, `LT`, `LTA`, `LTD`, `MPY`, `OR`, `SUB`,
`SUBC`, `SUBH`, `XOR`, `ZALH`, `ZALS`, `LST`, and `SUBS` cases expose concurrent
internal logical reads, while `SACL`, `SACH`, `SAR`, and `SST` expose writes,
without changing the physical `MEN` activity from a normal program fetch.
ADDH's logical internal read accompanies the same normal program cycle and
has no external data-memory strobe. ABS is among the program-only one-cycle cases and asserts no internal-data or
I/O transaction. SST retains that same physical program read while exposing
its internal status-word write on the verification interface.
IN/OUT instead replace the second-cycle address with the port and assert
`DEN` or `WE`. Table transfers and the Figure 2-12 interrupt program-read
order are also qualified below; the explicit wrapper now owns both I/O and
table execution intervals. Remaining instructions and general
fetch/execute overlap are not complete.

The explicit pipeline prefetches `BANZ` at opcode PC, then reads its canonical
operand at PC+1 during execution cycle 1. The old selected low-nine AR counter
chooses execution cycle 2's instruction fetch at target or PC+2 without
changing the counter. BANZ owns execution until that fetch completes, when it
decrements modulo 512, retires, and captures the fetched instruction.
Directed tests verify both outcomes and an active selected-fetch
clock-enable stall. This digital mapping does not infer analog pin delays
[ti-tms32010-users-guide-spru001b, §§2.4.1 and 2.6.1 and `BANZ`, printed
pp. 2-9–2-10, 2-13, and 3-16 (PDF pp. 33–34, 37, and 66)].
**Confidence: VERIFIED_PRIMARY for component facts; INFERRED for the combined
execute-interval mapping; VERIFIED_SIMULATION for the implementation.**

The explicit pipeline prefetches exact B opcode `0xf900` at PC, reads its
canonical operand at PC+1 during execution cycle 1, and redirects execution
cycle 2's instruction fetch to the target. B retains ownership until that
fetch completes, when it retires and captures the target without executing
it. No data or I/O transaction accompanies either interval
[ti-tms32010-users-guide-spru001b, Table 3-2 and `B`, printed pp. 3-6 and
3-15 (PDF pp. 56 and 65)]. **Confidence: VERIFIED_PRIMARY for component
facts; INFERRED for the combined execute-interval mapping;
VERIFIED_SIMULATION for the implementation.**

The explicit pipeline prefetches each exact accumulator-conditional opcode at
PC, reads its canonical operand at PC+1 during execution cycle 1, and uses the
unchanged full 32-bit ACC to select execution cycle 2's instruction fetch at
target or PC+2. The branch owns execution until that fetch completes, when it
retires and captures the selected word without executing it. No data or I/O
transaction occurs. The explicit matrix covers both outcomes for every
mnemonic, zero/positive/negative ACC, stalls on both selected paths, and
malformed-operand parking; legacy native-phase tests retain additional
transaction coverage
[ti-tms32010-users-guide-spru001b, Table 3-2 and individual branch pages,
printed pp. 3-6, 3-17–3-18, 3-20–3-22, and 3-24
(PDF pp. 56, 67–68, 70–72, and 74)]. **Confidence: VERIFIED_PRIMARY for
component facts; INFERRED for the combined execute-interval mapping;
VERIFIED_SIMULATION for the implementation.**

The explicit pipeline prefetches exact BV opcode `0xf500` at PC, reads its
canonical operand at PC+1 during execution cycle 1, and uses old sticky OV to
select execution cycle 2's instruction fetch at target or PC+2. BV owns
execution until that fetch completes, when it retires, captures the selected
word without executing it, and clears OV only on the taken path. OV is stable
through an active selected-fetch stall. No data or I/O transaction
accompanies either execution interval
[ti-tms32010-users-guide-spru001b, Table 3-2 and `BV`, printed pp. 3-6 and
3-23 (PDF pp. 56 and 73)]. **Confidence: VERIFIED_PRIMARY for component
facts; INFERRED for the combined execute-interval mapping;
VERIFIED_SIMULATION for the implementation.**

The explicit pipeline prefetches exact BIOZ opcode `0xf600` at PC, reads its
canonical operand at PC+1 during execution cycle 1, and samples the raw
active-low input at that operand's falling boundary. The sampled level
selects execution cycle 2's instruction fetch at target or PC+2. BIOZ owns
execution until that fetch completes, when it retires and captures the
selected word without executing it. The implementation retains only the
decision after operand completion, so later BIO changes or a selected-fetch
stall cannot redirect the active address. Both intervals use normal `MEN`
reads and no data or I/O transaction
[ti-tms32010-users-guide-spru001b, §2.9, Table 3-2, `BIOZ`, and Appendix A
BIO timing, printed pp. 2-18, 3-6, 3-19, and data-sheet 20
(PDF pp. 42, 56, 69, and 376)]. **Confidence: VERIFIED_PRIMARY for component
facts and BIO sampling; INFERRED for the combined execute-interval mapping;
VERIFIED_SIMULATION for the implementation.**

Exact `CALL` prefetches opcode `0xf800` at PC, reads its canonical target at
PC+1 as nonexecutable execution cycle 1, and fetches the selected target
instruction in execution cycle 2. All are ordinary `MEN` reads with no `DEN`
or `WE` transaction. At selected-target capture CALL pushes opcode-PC+2 onto
the internal stack, transfers PC, and retires
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and
`CALL`, printed pp. 2-2, 2-13, 3-6, and 3-26
(PDF pp. 26, 37, 56, and 76)]. **Confidence: VERIFIED_PRIMARY for component
facts; INFERRED for the combined execute-interval mapping;
VERIFIED_SIMULATION for the implementation.**

`DINT` and `EINT` retain the same normal external program fetch and have no
logical data-memory transaction. The phase wrapper verifies their `INTM`
changes at the falling-edge retirement boundary. It now exposes active-low
`int_i`, latches a request even while masked, and verifies EINT's
previously-disabled following-instruction protection. The generic core
diagnostic `interrupt_pending_o` is not a physical TMS32010 pin
[ti-tms32010-users-guide-spru001b, `DINT` and `EINT`, printed pp. 3-27 and
3-29 (PDF pp. 77 and 79)]. **Confidence: VERIFIED_PRIMARY.**

For ordinary interrupt entry, Figure 2-12 shows normal program reads at N and
N+1, a dummy read at return address N+2, and a read at vector `0x002`. The
dummy word cannot decode into a logical internal-data or I/O transaction.
The explicit pipeline wrapper executes exactly one protected word while
discarding the N+2 read, then performs entry with an empty execute slot while
reading vector 2. At that vector sample the core pushes N+2, masks interrupts,
clears its pending diagnostic, and captures vector 2 without executing it.
The following interval executes that vector word. Stalls preserve each
address and defer all boundary effects. There is no native
interrupt-acknowledge output; TI's acknowledge is internal
[ti-tms32010-users-guide-spru001b, §2.10 and Figure 2-12, printed
pp. 2-18–2-19 (PDF pp. 42–43)]. **Confidence: VERIFIED_PRIMARY for the
external fetch order and entry effects; VERIFIED_SIMULATION for the basic
explicit ownership path, MPY/MPYK protected-slot extension, matching 32-case
core/explicit arrival matrices, and four CALA/RET explicit arrival cases.
Physical sampling, PUSH/POP cycles, and physical confirmation of ADR-0003
remain `OQ-004`/`OQ-007`/`OQ-016`.**

`LST` retains the ordinary external program fetch while exposing one internal
logical data read. The loaded status fields commit at the falling-edge sample;
no physical `DEN` or `WE` transaction is produced
[ti-tms32010-users-guide-spru001b, `LST`, printed p. 3-38 (PDF p. 88)].
**Confidence: VERIFIED_PRIMARY for its one-cycle program/internal-read
boundary; indirect next-ARP precedence remains PROVISIONAL under `OQ-015`.**

`SUBC` retains the ordinary external program fetch while performing its
single internal divisor-word read. Directed phase tests place the required
ACC-free NOP after SUBC and observe no physical `DEN` or `WE` activity
[ti-tms32010-users-guide-spru001b, `SUBC`, printed p. 3-61 (PDF p. 111)].
**Confidence: VERIFIED_PRIMARY for the one-cycle program/internal-read
boundary; result availability remains open under `OQ-017`.**

`LTA` presents its internal data-word read beside the same normal external
program fetch while also accumulating the previous P value into ACC
[ti-tms32010-users-guide-spru001b, `LTA`, printed p. 3-40 (PDF p. 90)].
**Confidence: VERIFIED_PRIMARY.**

`DMOV` retains the normal external program fetch while internal RAM performs
a source read and distinct `source+1` write. These logical verification
transactions do not assert physical `DEN` or `WE`
[ti-tms32010-users-guide-spru001b, `DMOV`, printed p. 3-28 (PDF p. 78);
ti-first-generation-users-guide-1987, §3.4.3, printed p. 3-13 (PDF p. 42)].
**Confidence: VERIFIED_PRIMARY.**

`LTD` retains that normal external program fetch while its internal data RAM
performs a selected-word read and a distinct next-address write. These two
logical transactions are exposed separately for verification but do not
assert physical `DEN` or `WE`
[ti-tms32010-users-guide-spru001b, `LTD`, printed p. 3-41 (PDF p. 91);
ti-first-generation-users-guide-1987, §3.4.3, printed p. 3-13 (PDF p. 42)].
**Confidence: VERIFIED_PRIMARY.**

`MPYK` retains the same normal program read and exposes no logical data read or
write because its signed multiplier operand is carried in the instruction
word [ti-tms32010-users-guide-spru001b, `MPYK`, printed p. 3-44 (PDF p. 94)].
**Confidence: VERIFIED_PRIMARY.**

`PAC` also retains the normal program read with no logical data transaction:
its only data movement is the internal full-width P-to-ACC transfer
[ti-tms32010-users-guide-spru001b, `PAC`, printed p. 3-48 (PDF p. 98)].
**Confidence: VERIFIED_PRIMARY.**

`APAC` has the same program-only interface behavior while the internal ALU
adds the full-width P value to ACC
[ti-tms32010-users-guide-spru001b, `APAC`, printed p. 3-14 (PDF p. 64)].
**Confidence: VERIFIED_PRIMARY.**

`SPAC` also preserves this program-only interface behavior while the internal
ALU subtracts the full-width P value from ACC
[ti-tms32010-users-guide-spru001b, `SPAC`, printed p. 3-58 (PDF p. 108)].
**Confidence: VERIFIED_PRIMARY.**

`MAR` also retains the normal external program read but exposes no logical
data-memory transaction: TI explicitly says the referenced location is unused
in indirect form and direct MAR is a NOP
[ti-tms32010-users-guide-spru001b, `MAR`, printed p. 3-42 (PDF p. 92)].
**Confidence: VERIFIED_PRIMARY.**

Ordinary data-memory accesses stay inside the chip's 144-word RAM and produce
no physical memory strobe. Logical data transactions remain observable in the
model/core verification interface; only table and I/O instructions use pins
to move values between internal RAM and external storage
[ti-tms32010-users-guide-spru001b, §2.3, printed p. 2-7 (PDF p. 31)].
**Confidence: VERIFIED_PRIMARY.**

For an I/O operation the selected three-bit port address appears on
`PA2..PA0` while upper address pins are zero. Input and output each have eight
16-bit ports [ti-tms32010-users-guide-spru001b, §2.3.2, printed
pp. 2-15–2-16 (PDF pp. 39–40)]. **Confidence: VERIFIED_PRIMARY.**

The qualified portable interface exposes `io_port_o`, `io_read_o`,
`io_write_o`, `io_write_data_o`, and `io_read_data_i` separately from
program and internal-data signals. Program space separately exposes the
active transaction address, `program_read_o`, `program_write_o`,
`program_data_i`, and `program_write_data_o`, so a TBLW cannot be mistaken
for an I/O write at the reusable logical interface. A physical board decoder
may intentionally discard that distinction: Atari A044427 Rev A routes every
WE transaction at address `0x000`–`0x007` through its output-port decoder,
including low-address TBLW (`SC-021`). The native phase wrapper additionally
exposes active-low `den_n_o` and `we_n_o` and multiplexes
`program_address_o` to `{9'b0, io_port_o}` during the port cycle. This naming
does not merge the I/O space into program memory: logical direction and
transaction ownership remain explicit.

After the opcode prefetch, Figure 2-9 assigns IN/OUT execution cycle 1 to the
I/O transfer and execution cycle 2 to the next-instruction prefetch. During
cycle 1, MEN is inactive. Phase zero establishes the zero-extended port
address with all strobes high; phases 1–3 assert only DEN for IN or only WE
for OUT. IN keeps its external input live through the enabled falling-edge
sample. OUT reads the old resolved RAM word combinationally, drives it before
WE asserts, and holds it through the sample. During cycle 2, DEN and WE are
inactive and MEN fetches opcode PC+1
[ti-tms32010-users-guide-spru001b, §2.8.1, Figure 2-9, Table 3-2,
`IN`/`OUT`, and Appendix A IN/OUT timing, printed pp. 2-15–2-16, 3-6, 3-30,
3-47, and data-sheet pp. 17–18
(PDF pp. 39–40, 56, 80, 97, and 373–374)]. **Confidence:
VERIFIED_PRIMARY.**

The explicit pipeline implements those ownership intervals directly. At the
cycle-1 boundary it samples IN data, advances the internal execution state,
and retains the IN/OUT word in the execute slot; no RAM/AR/ARP update or
retirement is yet exposed. Cycle 2 presents PC+1 under MEN while I/O and
logical data-transaction outputs are inactive. Its boundary commits the
sampled IN word or completes OUT state, applies indirect AR/ARP updates,
retires, and captures PC+1 without executing it. This commit placement is an
implementation choice at the architectural boundary before the following
instruction, not a claim that the physical RAM write occurs later than the
documented I/O sample.

`sim/bus/tb_io_phase.sv` checks every native phase, strobe exclusivity,
clock-enable hold, input sampling, output stability, and prefetch resumption.
`sim/bus/tb_sequential_pipeline_io.sv` additionally checks explicit
transfer/following-prefetch ownership, independent stalls in both intervals,
no early RAM/AR/ARP mutation or fetched-word effect, and invalid-address
parking before any native strobe.
`sim/instruction/tb_io_rtl.sv` checks direct/indirect address effects and
trap-before-effects, while the focused differential compares model and RTL
cycles, transactions, state, and final RAM. The core exposes no READY input
because the original pinout contains none.

For `TBLR` and `TBLW`, the opcode prefetch at PC enters the execute slot.
Execution cycle 1 performs a full `MEN` read at PC+1 but classifies its input
as nonexecutable and discards it. Execution cycle 2 changes
`program_address_o` to the captured low 12 ACC bits. TBLR asserts `MEN` and
samples `program_data_i`; TBLW asserts the distinct `program_write_o` while
`WE` is active and drives `program_write_data_o` from the old resolved RAM
word. `DEN` is inactive throughout. Execution cycle 3 repeats the full
`MEN` read at PC+1. Only that repeated-fetch falling boundary commits the
TBLR RAM word, indirect AR/ARP changes, documented stack-bottom duplication,
retirement, and execute-slot replacement
[ti-tms32010-users-guide-spru001b, §2.8.2, Figure 2-10,
`TBLR`/`TBLW`, and Appendix A table timing, printed pp. 2-17 and
3-64–3-67 plus data-sheet pp. 15–16
(PDF pp. 41, 114–117, and 371–372)]. **Confidence: VERIFIED_PRIMARY.**

`sim/bus/tb_table_transfer_phase.sv` checks the legacy opcode, discarded,
table, and repeated-following phases, all strobe combinations, clock-enable
holds, read/write data, and bus order.
`sim/bus/tb_sequential_pipeline_table.sv` checks explicit execute ownership,
independent stalls in all three execution intervals, deferred state commit,
and a self-modifying TBLW whose repeated PC+1 fetch observes and executes the
new word. `sim/instruction/tb_table_transfers_rtl.sv`
checks direct/indirect data addressing and stack effects; the focused
differential additionally validates final RAM and program-memory contents.

## No documented READY pin

The original 40-pin pinout contains no `READY`, `WAIT`, or equivalent input.
The initial user-guide and data-sheet review has therefore found no native
per-transaction wait-state handshake
[ti-tms32010-users-guide-spru001b, §2.3 and Appendix A pin assignments].
**Confidence: VERIFIED_PRIMARY for the pinout.**

TI's external-clock timing requirements bound the TMS32010-20 master-clock
period to 48.78–150 ns and its pulse duration to 47.5–52.5% of that period.
Because `CLKOUT` is one fourth of the input frequency, a conforming physical
machine cycle is 195.12–600 ns. There is no specified indefinite stop or
transaction-selected extension
[ti-tms32010-users-guide-spru001b, §2.12 and Appendix A data sheet, Clock
Characteristics and Timing, printed pp. 2-20 and data-sheet pp. 10–11 (PDF
pp. 44 and 366–367)]. **Confidence: VERIFIED_PRIMARY.**

Consequently a modern `ready` input must not be described as original
TMS32010 behavior. If integration needs slow memory, a separate adapter may
pause explicit emulation phases with the platform-only `clock_enable_i`.
`TIMING-002` now verifies that digital adaptation across ordinary program,
I/O, and table transactions: retained address/control/write-data state does
not advance, sample/retirement events remain inactive, and re-enabling resumes
the same transaction. This is **VERIFIED_SIMULATION** platform behavior, not
evidence that an NMOS TMS32010 clock may be stopped at an arbitrary point.
`OQ-001` therefore resolves to bounded physical slowing within the TI clock
envelope, not arbitrary clock stretching.

The first platform adapter implements this separation explicitly:
`tms32010_mister` presents same-clock program/I/O request and ready callbacks,
registers a late response at phase 2, and holds only the phase-3 sample
boundary until ready is observed. Its directed test includes synchronous
program reads, I/O reads/writes, and a TBLW program write without duplicate
commits [`docs/integration/mister_wrapper.md` and
`sim/bus/tb_mister_wrapper.sv`]. **Confidence: VERIFIED_SIMULATION for this
platform adapter; not physical-device evidence.**

## Native RTL signal groups

The current qualified slice retains:

| Group | Information retained |
|---|---|
| program | 12-bit word address, 16-bit read/write data, read/write phase |
| data | 8-bit word address, 16-bit read/write data, internal/external marker |
| I/O | 3-bit port, 16-bit read/write data, direction |
| control | reset, interrupt, raw active-low BIO level, clock enable |
| observation | architectural cycle, phase, transaction-valid |

The core must keep transaction signals stable for the entire documented
phase. Initial Appendix A electrical parameters are transcribed in the native
phase contract; the pin wrapper will apply them as constraints rather than
RTL delays.
