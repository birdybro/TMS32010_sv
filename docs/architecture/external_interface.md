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
read relationship for the 37 supported one-cycle sequential instructions and
both cycles of `B` and `BANZ`. Its `ADD`, `ADDS`, `AND`, `DMOV`, `LAC`, `LAR`, `LDP`, `LT`, `LTA`, `LTD`, `MPY`, `OR`, `SUB`,
`SUBC`, `XOR`, `ZALH`, `ZALS`, `LST`, and `SUBS` cases expose concurrent internal logical reads, while
`SACL`, `SACH`, and `SAR` expose writes, without changing the physical `MEN`
activity from a normal program fetch. That is implementation evidence for the
cited normal-read mapping, not a claim that remaining control flow, external
data/I/O access, or general pipeline overlap is complete.

`BANZ` presents `PC` during its opcode read and `PC+1` during its target-word
read. At the second falling-edge sample it selects the canonical target when
the old selected low-nine AR counter is nonzero, or `PC+2` otherwise. Directed
tests verify identical two-cycle read topology for taken and untaken paths,
including an active-phase clock-enable stall. This logical sequence is
primary-backed; it does not infer analog pin delays
[ti-tms32010-users-guide-spru001b, §§2.4.1 and 2.6.1 and `BANZ`, printed
pp. 2-9–2-10, 2-13, and 3-16 (PDF pp. 33–34, 37, and 66)].
**Confidence: VERIFIED_PRIMARY.**

`B` presents `PC` for exact opcode `0xf900`, then `PC+1` for its canonical
target word, using two normal program reads. At the second falling-edge sample
it retires and the next address becomes the target. No data or I/O
transaction accompanies either cycle
[ti-tms32010-users-guide-spru001b, Table 3-2 and `B`, printed pp. 3-6 and
3-15 (PDF pp. 56 and 65)]. **Confidence: VERIFIED_PRIMARY.**

`DINT` and `EINT` retain the same normal external program fetch and have no
logical data-memory transaction. The current phase wrapper verifies their
`INTM` changes at the falling-edge retirement boundary. It has no interrupt
pin or entry sequencer, so this does not qualify EINT's following-instruction
service delay
[ti-tms32010-users-guide-spru001b, `DINT` and `EINT`, printed pp. 3-27 and
3-29 (PDF pp. 77 and 79)]. **Confidence: VERIFIED_PRIMARY for the one-cycle
program transaction and state effect; entry timing unimplemented.**

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
