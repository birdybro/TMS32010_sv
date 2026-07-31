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

The data sheet establishes falling `CLKOUT` as the input sampling boundary.
Address transition begins after a falling edge, a read strobe asserts about
one quarter-cycle later, and address/strobe remain stable through the next
falling edge. See `docs/timing/native_phase_contract.md`
[ti-tms32010-users-guide-spru001b, Appendix A data sheet, printed
pp. 13–18 (PDF pp. 369–374)]. **Confidence: VERIFIED_PRIMARY.**

The current `tms32010_phase_slice` wrapper implements and tests this normal
read relationship for the twenty-seven supported one-cycle sequential
instructions. Its `ADD`, `ADDS`, `AND`, `LAC`, `LAR`, `LDP`, `LT`, `MPY`, `OR`, `SUB`,
`XOR`, `ZALH`, `ZALS`, and `SUBS` cases expose concurrent internal logical reads, while
`SACL`, `SACH`, and `SAR` expose writes, without changing the physical `MEN`
activity from a normal program fetch. That is implementation evidence for the
cited normal-read mapping, not a claim that control flow, external data/I/O
access, or general pipeline overlap is complete.

`MPYK` retains the same normal program read and exposes no logical data read or
write because its signed multiplier operand is carried in the instruction
word [ti-tms32010-users-guide-spru001b, `MPYK`, printed p. 3-44 (PDF p. 94)].
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

## No documented READY pin

The original 40-pin pinout contains no `READY`, `WAIT`, or equivalent input.
The initial user-guide and data-sheet review has therefore found no native
per-transaction wait-state handshake
[ti-tms32010-users-guide-spru001b, §2.3 and Appendix A pin assignments].
**Confidence: VERIFIED_PRIMARY for the pinout; `OQ-001` remains open for any
documented clock-stretching rule.**

Consequently a modern `ready` input must not be described as original
TMS32010 behavior. If integration needs slow memory, a separate adapter may
pause explicit emulation phases under documented-safe clock conditions; its
behavior and divergence will be tested and labeled. TASKS milestone
`TIMING-002` must be revised around evidence rather than presuming a READY
protocol.

## Candidate native RTL signals

This is a design target, not final port naming:

| Group | Information retained |
|---|---|
| program | 12-bit word address, 16-bit read/write data, read/write phase |
| data | 8-bit word address, 16-bit read/write data, internal/external marker |
| I/O | 3-bit port, 16-bit read/write data, direction |
| control | reset, interrupt, BIO, clock enable |
| observation | architectural cycle, phase, transaction-valid |

The core must keep transaction signals stable for the entire documented
phase. Initial Appendix A electrical parameters are transcribed in the native
phase contract; the pin wrapper will apply them as constraints rather than
RTL delays.
