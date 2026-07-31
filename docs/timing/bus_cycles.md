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

No READY pin appears in the original pinout. There is therefore no verified
native wait-state transaction to diagram. `TIMING-002` remains a research
task for safe clock/phase adaptation rather than a presumed handshake.

`PUSH` and `POP` each consume two cycles despite carrying only one program
word. No located original-part timing figure shows whether `MEN` is inactive,
the current address is held, or the next instruction is prefetched during the
extra internal cycle. The IN/OUT two-cycle figures cannot prove stack-cycle
behavior because those instructions use their extra cycle for an external
data transfer. Native stack bus sequencing remains `OQ-016`; no waveform is
invented here.

`BANZ` is different from those one-word stack operations: its second cycle
is the documented second program word. The native sequence is therefore two
ordinary `MEN` reads at opcode PC and PC+1, followed by a normal read at the
taken target or sequential PC+2. The condition cannot remove the operand
cycle because TI lists BANZ as two words/two cycles without a conditional
exception. Pinned MAME's one-cycle untaken shortcut is recorded as a
functional-emulator abstraction in `SC-012`, not copied into the RTL
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and `BANZ`,
printed pp. 2-2, 2-13, 3-6, and 3-16
(PDF pp. 26, 37, 56, and 66)]. **Confidence: VERIFIED_PRIMARY.**

`B` has the same two ordinary program-read cycles without BANZ's counter
condition: exact opcode `0xf900` at PC, canonical target at PC+1, then the
next normal read at the target. Both cycles assert only `MEN`; no `DEN` or
`WE` transaction occurs
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and `B`,
printed pp. 2-2, 2-13, 3-6, and 3-15
(PDF pp. 26, 37, 56, and 65)]. **Confidence: VERIFIED_PRIMARY.**

`BGEZ`, `BGZ`, `BLEZ`, `BLZ`, `BNZ`, and `BZ` also use two ordinary
program reads at opcode PC and PC+1 on both outcomes. The next read is the
target when the ACC predicate is true or opcode PC+2 when false. No `DEN` or
`WE` phase occurs. MAME's untaken shortcut is recorded in `SC-013` and is not
used as bus evidence
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and
individual branch pages, printed pp. 2-2, 2-13, 3-6, 3-17–3-18, 3-20–3-22,
and 3-24 (PDF pp. 26, 37, 56, 67–68, 70–72, and 74)].
**Confidence: VERIFIED_PRIMARY.**

`BV` also reads its opcode and following target at PC and PC+1 regardless of
OV. The next read is the target when OV was set or PC+2 when clear. OV clears
at the taken second-cycle retirement boundary; neither cycle emits `DEN` or
`WE`. MAME's untaken shortcut is recorded in `SC-014`
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and `BV`,
printed pp. 2-2, 2-13, 3-6, and 3-23
(PDF pp. 26, 37, 56, and 73)]. **Confidence: VERIFIED_PRIMARY.**

`BIOZ` likewise reads exact opcode `0xf600` at PC and its following target at
PC+1 on both pin levels. Both are normal `MEN` reads; neither emits `DEN` or
`WE`. BIO is not latched and must meet setup before the second falling
`CLKOUT` sample, where low selects the target and high selects PC+2. Pinned
MAME shortens the untaken path; `SC-015` records that emulator abstraction
[ti-tms32010-users-guide-spru001b, §§2.1.1, 2.6.1, and 2.9, Table 3-2,
`BIOZ`, and Appendix A BIO timing, printed pp. 2-2, 2-13, 2-18, 3-6, 3-19,
and data-sheet 20 (PDF pp. 26, 37, 42, 56, 69, and 376)].
**Confidence: VERIFIED_PRIMARY.**

`CALL` reads exact opcode `0xf800` at PC and its canonical target at PC+1 as
two ordinary `MEN` program reads. The following normal read is at the target.
The target-word retirement pushes opcode-PC+2 onto the internal return stack;
neither CALL cycle emits `DEN` or `WE`
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and
`CALL`, printed pp. 2-2, 2-13, 3-6, and 3-26
(PDF pp. 26, 37, 56, and 76)]. **Confidence: VERIFIED_PRIMARY.**

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
precedence remains PROVISIONAL under `OQ-015`.**

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

The primary normal fetch, `IN`, `OUT`, `TBLR`, `TBLW`, and reset pin waveforms
are transcribed. Remaining work must identify:

- branch/call/return prefetch address order;
- complete interrupt entry and vector-fetch order;
- any internal conflict that changes an otherwise normal read;
- safe wrapper phase pause, if one exists, despite the absence of READY.
