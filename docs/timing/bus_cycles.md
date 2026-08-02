# External bus-cycle research

## Established logical cycles

Program fetch uses the external address bus and `MEN`. `IN` selects one of
eight input ports with `DEN`; `OUT` selects an output port and uses `WE`.
`TBLR` obtains a program-space word under `MEN`; `TBLW` drives a program-space
write under `WE`. TI states that `MEN`, `DEN`, and `WE` are mutually
exclusive
[ti-tms32010-users-guide-spru001b, §§2.3.1–2.3.2 and Figures 2-10/2-11,
printed pp. 2-12, 2-15–2-18 (PDF pp. 36, 39–42)].
**Confidence: VERIFIED_PRIMARY.**

During reset all three strobes are inactive high and the data bus is high
impedance [ti-tms32010-users-guide-spru001b, §2.5, printed p. 2-19 (PDF
p. 43)]. **Confidence: VERIFIED_PRIMARY.**

## Electrical versus architectural timing

Appendix A gives nanosecond setup, hold, access, pulse-width, and delay
limits. Those values will become wrapper constraints and timing-test
parameters; they will not be represented with RTL `#delay` constructs.
Logical phase ordering will be represented with synchronous state.

The normal read, table, I/O, reset, and input-sampling figures are now
transcribed in `docs/timing/native_phase_contract.md`. Falling `CLKOUT` is the
read-data, interrupt, and BIO sampling boundary. A normal read changes address
after one falling edge, asserts `MEN` about one quarter-cycle later, and
samples the word at the next falling edge
[ti-tms32010-users-guide-spru001b, Appendix A data sheet, printed
pp. 13–20 (PDF pp. 369–376)]. **Confidence: VERIFIED_PRIMARY.**

Figures 2-9 and 2-10 label the opcode transaction as “instruction prefetch”
and number the execution intervals after its completion. The next
instruction's prefetch is the final interval of the current multicycle
instruction. Legacy phase tests preserve the transaction order and elapsed
periods, but their retirement-mapped cycle counter is not evidence of
distinct execute ownership. See `docs/timing/native_phase_contract.md`.

No READY pin appears in the original pinout. There is therefore no verified
native wait-state transaction to diagram. Slow-memory integration therefore
uses a separately labeled synchronous platform adaptation, not a presumed
handshake.

## Portable synchronous phase pause

The portable wrappers expose `clock_enable_i` to hold one of the four modeled
digital subphases. When it is low during an active retained phase, the phase,
`CLKOUT`, program/port address, `MEN`/`DEN`/`WE`, direction, write data,
execute ownership, architectural registers, internal RAM, and architectural
cycle count remain unchanged. Event observations such as `sample_o` and
`retired_o` are pulses and remain inactive while paused; they are not retained
level signals. Wrapper-owned combinational qualifiers must also remain stable.
In particular, the standalone program-bus proof makes `MEN` stability
conditional on stable `program_read_i`.

Read data is deliberately live until the enabled falling-boundary sample.
An integration adapter may therefore wait for program or I/O input data, then
present it before re-enabling the phase. It must not change a write address,
direction, or output word during the pause.

`sim/bus/tb_wait_states.sv` compares the same synthetic program with zero
holds and with 16 host-clock holds distributed across an ordinary program
read, IN/DEN, OUT/WE, TBLR/MEN, and TBLW/WE. It checks every exposed retained
state/control value on each held clock, exact elapsed-host-clock extension,
finite resumption, and identical final PC, ACC, RAM, and program memory.
Transaction-specific tests separately check that IN and program read inputs
remain live until the enabled sample. The 40-step standalone program-bus BMC
proves phase/address/transaction retention for arbitrary clock-enable choices;
the integrated TBLR/TBLW BMCs cover their fixed programs under arbitrary
holds. None of this proves a native wait protocol, arbitrary physical clock
stoppage, electrical timing, or unbounded liveness. TI separately limits the
TMS32010-20 external master clock to 48.78–150 ns with a 47.5–52.5% pulse
window, so pin-compatible timing cannot hold one level indefinitely
[ti-tms32010-users-guide-spru001b, Appendix A data sheet, Clock
Characteristics and Timing, printed p. 11 (PDF p. 367)]. **Confidence:
VERIFIED_SIMULATION for the FPGA phase-pause adaptation; VERIFIED_PRIMARY for
the bounded physical clock envelope resolved under `OQ-001`.**

`IN` and `OUT` have a primary-defined native transaction sequence. The
ordinary one-word opcode prefetch uses `MEN`. At that falling-edge sample the
architectural PC advances by one but the instruction remains pending. During
the following port interval `A11..A3` are zero and `PA2..PA0` carry the encoded port.
`IN` asserts only `DEN`, samples the external 16-bit word at the falling
boundary, and writes it to the already-resolved old data-memory address.
`OUT` reads that internal word, drives it during address setup, and asserts
only `WE` through the falling boundary. The following normal read uses opcode
PC+1 and completes the second documented execution interval. The legacy
wrapper applies indirect AR/ARP updates and retirement at the port sample.
The explicit wrapper instead holds those architectural effects and execute
ownership through the following prefetch
[ti-tms32010-users-guide-spru001b, Table 3-2, `IN`/`OUT`, and Appendix A
timing, printed pp. 3-6, 3-30, 3-47, and data-sheet pp. 17–18
(PDF pp. 56, 80, 97, and 373–374)]. **Confidence: VERIFIED_PRIMARY for the
waveform; VERIFIED_SIMULATION for legacy bus order and explicit ownership.**

Directed native testing separately holds active `DEN` and `WE` phases with
the FPGA clock enable low and requires phase, address, strobe, PC, and cycle
count to remain stable. It also proves that input data remains live until the
enabled sample and that `OUT` data remains unchanged throughout its hold and
completion phases. This validates the synchronous emulation contract but does
not assert that an NMOS TMS32010 may be stopped arbitrarily or that a
READY/wait pin exists.

`TBLR` and `TBLW` have the corresponding primary-defined transaction
sequence. Both begin with an opcode `MEN` prefetch at PC and a second `MEN`
read at PC+1 whose word is discarded. The next interval replaces the external address with
captured `ACC[11:0]`: TBLR keeps `MEN` active and writes the sampled 16-bit
program word into the pre-resolved internal-RAM address; TBLW suppresses
`MEN`, reads that RAM word, and asserts `WE` while driving it. At the table
sample the legacy wrapper applies indirect AR/ARP updates, duplicates old
stack level 2 into the bottom after the documented temporary push/pop, and
retires. The following normal read returns to PC+1 and completes the third
documented execution interval, so even a TBLW that overwrites that address
changes the word subsequently executed. The explicit wrapper instead retains
the table instruction until that repeated read completes; only then does it
commit RAM, AR/ARP, stack-bottom, retirement, and execute-slot replacement.
Its separate `program_write_o`/`program_write_data_o` outputs identify TBLW
without conflating it with an I/O write
[ti-tms32010-users-guide-spru001b, §2.8.2, Figure 2-10,
`TBLR`/`TBLW`, and Appendix A table timing, printed pp. 2-17 and
3-64–3-67 plus data-sheet pp. 15–16
(PDF pp. 41, 114–117, and 371–372)]. **Confidence: VERIFIED_PRIMARY for the
waveform; VERIFIED_SIMULATION for legacy bus order and explicit ownership.**

Directed native testing holds both the discarded `MEN` phase and active table
`MEN`/`WE` phases under a low FPGA clock enable and requires phase, address,
strobe, write data, PC, cycle count, and pending state to remain stable. The
focused differential independently compares all three external program
transactions, internal RAM direction, stack state, and final program-memory
mutation. The explicit test additionally stalls each interval, checks
deferred architectural commit, and uses self-modifying TBLW to prove the
discarded word never enters execution. These tests validate logical phases,
not analog delay or arbitrary physical-device clock stoppage.

A depth-80 composed-pipeline proof adds one fixed indirect TBLR case after
four nested CALLs. It proves distinct preexisting stack state, old-AR0 address
5, ACC program address `0x020`, exact `0xb33c` MEN transfer, repeated-prefetch-
only AR/ARP/stack/RAM effects, and following-LAC consumption under arbitrary
bounded clock-enable stalls; cover reaches step 74
[`formal/tms32010_pipeline_table_indirect_stack.sby`]. It does not generalize
to other indirect controls, arbitrary programs/memory, physical clock stopping,
or electrical timing.

A complementary depth-88 proof composes the same full-stack setup with fixed
indirect `TBLW *-,AR0`. It proves discarded/repeated PC+1 MEN at `0x085`,
old-AR1 RAM address 9, one `0x7e44` WE transfer and enabled phase-3 commit at
distinct ACC target `0x086`, deferred AR1/ARP/stack effects, and execution of
the rewritten program word; cover reaches step 83
[`formal/tms32010_pipeline_table_indirect_stack_write.sby`]. This is one
synchronous fixture-memory contract, not arbitrary memory, interrupt,
physical-clock-stop, package-delay, or electrical evidence.

Figure 2-12 now establishes the interrupt program-read order. After a request
becomes active during fetch N, program space reads N, N+1, a dummy N+2, and
vector 2. N and N+1 execute; N+2 is not executed before entry. The internal
acknowledge associated with service sets INTM and clears the latched request;
there is no external acknowledge pin
[ti-tms32010-users-guide-spru001b, §§2.10 and Figure 2-12, printed
pp. 2-18–2-19 (PDF pp. 42–43)]. **Confidence: VERIFIED_PRIMARY.**

The legacy native wrapper reproduces the tested address/strobe sequence with
four normal program-read subphases per word. Its dummy-return-PC cycle asserts
only `MEN`; `DEN`, `WE`, logical data operations, I/O operations, and
instruction retirement remain inactive. At the dummy sample the core pushes
the return PC and selects vector 2. `sim/interrupt/tb_interrupt_phase.sv`
observes branch target `0x100`, EINT at `0x100`, protected word `0x101`,
dummy address `0x102`, and vector `0x002`.

The explicit wrapper independently retires the protected word while
discarding N+2, leaves the execute slot empty during vector fetch and entry,
captures vector 2 without executing it, and executes it only in the following
interval. Directed stalls prove the dummy and vector addresses remain stable
and that retirement, stack entry, and vector effects cannot occur early
[`sim/interrupt/tb_sequential_pipeline_interrupt.sv`]. This qualifies the
basic Figure 2-12 ownership path. A second explicit test qualifies MPY/MPYK
protected-slot extension through one additional instruction, including MPY's
internal read, MPYK's program-only cycle, stalls, dummy discard, and
post-following return-PC ownership
[`sim/interrupt/tb_sequential_pipeline_interrupt_multiply.sv`]. The complete
multicycle-arrival matrix remains open as described in
`docs/architecture/pipeline.md`.

`PUSH` and `POP` each consume two cycles despite carrying only one program
word. No located original-part timing figure shows whether `MEN` is inactive,
the current address is held, or the next instruction is prefetched during the
extra internal cycle. The IN/OUT two-cycle figures cannot prove stack-cycle
behavior because those instructions use their extra cycle for an external
data transfer. Native stack bus sequencing remains `OQ-016`; no waveform is
invented here.

Figure 2-9 gives `IN` and `OUT` explicit pipeline ownership rather than only
a transaction order. After the opcode prefetch enters the execute slot,
execution cycle 1 drives `{9'b0, port}` and asserts only DEN for IN or only WE
for OUT; MEN is suppressed. Execution cycle 2 removes both I/O strobes and
fetches PC+1 under MEN. The instruction retires only when that following word
is captured, and the word cannot execute until the next interval. Directed
testing stalls each active phase independently, samples changed live IN data
at the cycle-1 boundary, holds OUT data through that boundary, enforces
MEN/DEN/WE mutual exclusion, and rejects both early retirement and any
invalid-address strobe
[ti-tms32010-users-guide-spru001b, §2.8.1, Figure 2-9, Table 3-2, and
Appendix A IN/OUT timing, printed pp. 2-15–2-16 and 3-6 plus data-sheet
pp. 17–18 (PDF pp. 39–40, 56, and 373–374)]. **Confidence:
VERIFIED_PRIMARY for interval and pin ownership; VERIFIED_SIMULATION for the
explicit implementation.**

No dedicated original-part pin waveform has been located for the two-word
branch family. Except for the newly integrated exact `B`, `BANZ`, `BV`,
`BIOZ`, `CALL`, and six accumulator-conditional branches, the ordered reads
below are derived from the primary word/cycle totals, following-word operand
definitions, normal program-read rules, and legacy directed traces. They
remain INFERRED as combined pipeline mappings even though the component facts
are VERIFIED_PRIMARY.

Exact `BANZ` now has explicit pipeline ownership. Opcode `0xf400` prefetches
at PC and enters the execute slot. Its canonical operand is read at PC+1
during execution cycle 1 and is not marked executable. The old selected
`AR[8:0]` redirects execution cycle 2's normal `MEN` read to the target when
nonzero or PC+2 when zero. BANZ retains ownership and its counter value until
that selected instruction is captured, then decrements modulo 512 and
retires. Both outcomes therefore consume both intervals. A directed test
stalls the selected read and parks malformed operands before decrement or an
unsupported speculative fetch. Pinned MAME's one-cycle untaken shortcut is
recorded as a functional-emulator abstraction in `SC-012`, not copied into
the RTL
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and `BANZ`,
printed pp. 2-2, 2-13, 3-6, and 3-16
(PDF pp. 26, 37, 56, and 66)]. **Confidence: VERIFIED_PRIMARY for component
facts; INFERRED for combined interval mapping; VERIFIED_SIMULATION for the
implementation.**

Exact `B` now has explicit pipeline ownership. Opcode `0xf900` prefetches at
PC and enters the execute slot. Its canonical target operand is read at PC+1
during execution cycle 1 and is not marked executable. The operand redirects
the normal `MEN` read during execution cycle 2 to the target. B retains
execute ownership until that target word is captured, then retires; the
target cannot execute until the following fetch interval. A directed test
also stalls the active target read and parks malformed operands before any
unsupported speculative fetch. No `DEN` or `WE` transaction occurs
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and `B`,
printed pp. 2-2, 2-13, 3-6, and 3-15
(PDF pp. 26, 37, 56, and 65)]. **Confidence: VERIFIED_PRIMARY for component
facts; INFERRED for combined interval mapping; VERIFIED_SIMULATION for the
implementation.**

Exact `BGEZ`, `BGZ`, `BLEZ`, `BLZ`, `BNZ`, and `BZ` now have explicit
pipeline ownership. Each opcode prefetch enters execution, its canonical
PC+1 operand is a nonexecutable execution-cycle-1 read, and the unchanged
full 32-bit ACC selects execution cycle 2's normal `MEN` read at target or
opcode PC+2. The branch owns execution until that selected word is captured
and retires; no `DEN` or `WE` phase occurs. A directed matrix covers every
predicate and both outcomes, including stalls on the taken and untaken
selected reads and malformed-operand parking. MAME's untaken shortcut is
recorded in `SC-013` and is not used as bus evidence
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and
individual branch pages, printed pp. 2-2, 2-13, 3-6, 3-17–3-18, 3-20–3-22,
and 3-24 (PDF pp. 26, 37, 56, 67–68, 70–72, and 74)].
**Confidence: VERIFIED_PRIMARY for component facts; INFERRED for combined
interval mapping; VERIFIED_SIMULATION for the implementation.**

Exact `BV` now has explicit pipeline ownership. Opcode `0xf500` prefetches at
PC and enters the execute slot. Its canonical PC+1 operand is a nonexecutable
execution-cycle-1 read, and old sticky OV selects execution cycle 2's normal
`MEN` read at target or opcode PC+2. BV owns execution and preserves OV until
that selected word is captured and the branch retires; only a taken
retirement clears OV. No `DEN` or `WE` phase occurs. A directed test stalls
both selected paths and parks malformed operands before clear. MAME's
untaken shortcut is recorded in `SC-014`
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and `BV`,
printed pp. 2-2, 2-13, 3-6, and 3-23
(PDF pp. 26, 37, 56, and 73)]. **Confidence: VERIFIED_PRIMARY for component
facts; INFERRED for combined interval mapping; VERIFIED_SIMULATION for the
implementation.**

Exact `BIOZ` now has explicit pipeline ownership. Opcode `0xf600` prefetches
at PC and enters the execute slot. Its canonical PC+1 operand is a
nonexecutable execution-cycle-1 read. Raw BIO is not latched and must meet
setup before that operand's falling boundary, where low selects execution
cycle 2's normal `MEN` read at the target and high selects opcode PC+2. BIOZ
owns execution until the selected word is captured and the branch retires.
The implementation retains the sampled decision through later pin changes or
stalls; neither interval emits `DEN` or `WE`. A directed test covers both
paths and parks malformed operands before selection. Pinned MAME shortens the
untaken path; `SC-015` records that emulator abstraction
[ti-tms32010-users-guide-spru001b, §§2.1.1, 2.6.1, and 2.9, Table 3-2,
`BIOZ`, and Appendix A BIO timing, printed pp. 2-2, 2-13, 2-18, 3-6, 3-19,
and data-sheet 20 (PDF pp. 26, 37, 42, 56, 69, and 376)].
**Confidence: VERIFIED_PRIMARY for component facts and the pin sample;
INFERRED for combined interval mapping; VERIFIED_SIMULATION for the
implementation.**

Exact `CALL` has explicit ownership. Opcode `0xf800` prefetches at PC. Its
canonical PC+1 operand is a nonexecutable execution-cycle-1 `MEN` read and
selects the target. Execution cycle 2 is the normal target-instruction `MEN`
read. CALL retires and pushes opcode-PC+2 only as that selected word is
captured; neither execution interval emits `DEN` or `WE`
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and
`CALL`, printed pp. 2-2, 2-13, 3-6, and 3-26
(PDF pp. 26, 37, 56, and 76)]. **Confidence: VERIFIED_PRIMARY for component
facts; INFERRED for combined pipeline mapping; VERIFIED_SIMULATION for the
implementation.**

The partial phase integration test proves that one-cycle `ADD`, `ADDS`, `AND`,
`DMOV`, `LAC`, `LAR`, `LDP`, `LST`, `LT`, `LTA`, `LTD`, `MPY`, `OR`, `SACL`, `SACH`, `SAR`, `SUB`, `SUBC`, `SUBS`, `XOR`, `ZALH`,
and `ZALS`
perform the same external program fetch as the other qualified sequential
instructions while their ordinary data operands remain internal,
verification-visible logical reads/writes. No physical `DEN` or `WE` behavior
is claimed from those internal transactions.

The phase test verifies LST's internal status-word read and architectural
status commit during one ordinary external program fetch. The operation
introduces no external data or I/O strobe
[ti-tms32010-users-guide-spru001b, `LST`, printed p. 3-38 (PDF p. 88)].
**Confidence: VERIFIED_PRIMARY for the bus boundary; indirect next-ARP
precedence remains PROVISIONAL under `OQ-015`/`SC-009`.**

The phase test also verifies SUBC's internal divisor-word read beside the
ordinary external program fetch and requires no physical data or I/O strobe.
The following program word is NOP so the trace obeys TI's ACC-use restriction
[ti-tms32010-users-guide-spru001b, `SUBC`, printed p. 3-61 (PDF p. 111)].
**Confidence: VERIFIED_PRIMARY for bus scope; exact ACC result availability
after a prohibited dependency remains UNKNOWN under `OQ-017`.**

The phase test verifies that `LTA` performs its internal data-word read and
previous-P accumulation during the ordinary one-cycle external program fetch;
it introduces no external data-memory pin transaction
[ti-tms32010-users-guide-spru001b, `LTA`, printed p. 3-40 (PDF p. 90)].
**Confidence: VERIFIED_PRIMARY.**

The same phase test verifies DMOV's simultaneous internal source read and
next-address write, unchanged copied data, and preserved arithmetic/T state
during one ordinary external program fetch. Both RAM addresses are logical
verification signals; DMOV introduces no external data-memory pin transaction
[ti-tms32010-users-guide-spru001b, `DMOV`, printed p. 3-28 (PDF p. 78);
ti-first-generation-users-guide-1987, §3.4.3, printed p. 3-13 (PDF p. 42)].
**Confidence: VERIFIED_PRIMARY.**

The phase test also verifies LTD's simultaneous internal source read and
next-address write, unchanged copied data, T load, and previous-P accumulation
during one ordinary external program fetch. Both internal RAM addresses are
logical verification signals; LTD introduces no external data-memory pin
transaction
[ti-tms32010-users-guide-spru001b, `LTD`, printed p. 3-41 (PDF p. 91);
ti-first-generation-users-guide-1987, §3.4.3, printed p. 3-13 (PDF p. 42)].
**Confidence: VERIFIED_PRIMARY.**

The same phase test verifies that `MAR` performs neither a logical data read
nor write while retaining the normal external program fetch. This follows
TI's explicit statement that indirect MAR makes no use of the referenced
memory and direct MAR is a NOP
[ti-tms32010-users-guide-spru001b, `MAR`, printed p. 3-42 (PDF p. 92)].
**Confidence: VERIFIED_PRIMARY.**

The phase test also verifies that `MPYK` performs no logical data read or
write while retaining the ordinary external program fetch. Its signed 13-bit
operand is part of the fetched instruction word
[ti-tms32010-users-guide-spru001b, `MPYK`, printed p. 3-44 (PDF p. 94)].
**Confidence: VERIFIED_PRIMARY.**

The phase test likewise verifies that `PAC` copies P to ACC while retaining
the ordinary external program fetch and exposing no logical data read or
write
[ti-tms32010-users-guide-spru001b, `PAC`, printed p. 3-48 (PDF p. 98)].
**Confidence: VERIFIED_PRIMARY.**

`APAC` likewise retains the ordinary external program fetch and has no
logical data transaction while adding P to ACC. Its arithmetic status and OVM
behavior are internal to the processor
[ti-tms32010-users-guide-spru001b, `APAC`, printed p. 3-14 (PDF p. 64)].
**Confidence: VERIFIED_PRIMARY.**

`SPAC` has the same program-only bus boundary while subtracting P from ACC;
the operation, P source, overflow status, and OVM result selection are
internal
[ti-tms32010-users-guide-spru001b, `SPAC`, printed p. 3-58 (PDF p. 108)].
**Confidence: VERIFIED_PRIMARY.**

## Remaining diagrams

The primary normal fetch, `IN`, `OUT`, `TBLR`, `TBLW`, reset, and interrupt
fetch sequences
are transcribed and have directed native-phase tests. Remaining work must
identify:

- physical confirmation of the implemented `INFERRED` branch/call/return
  prefetch address order;
- explicit interrupt ownership beyond the qualified EINT/protected-word/
  discarded-N+2/vector path, MPY/MPYK extension, the matching 32-case
  core/explicit matrices, and four CALA/RET explicit arrival cases;
- any internal conflict that changes an otherwise normal read.
