# Native pin-phase contract

## Scope

This contract transcribes logical relationships from the February 1986
TMS32010 data-sheet waveforms included in SPRU001B. It distinguishes:

- **architectural phase:** ordering that future RTL must reproduce;
- **electrical bound:** a wrapper/constraint requirement in nanoseconds;
- **not yet modeled:** behavior outside the current partial RTL.

Source for this document:
[ti-tms32010-users-guide-spru001b, Appendix A TMS32010 data sheet,
memory/peripheral, reset, interrupt, and BIO timing, printed data-sheet
pp. 13–20 (PDF pp. 369–376)]. **Confidence: VERIFIED_PRIMARY.**

## Clock and normal program read

One `CLKOUT` period is one processor machine cycle and four crystal/input-clock
periods. The falling `CLKOUT` edge is the program-read sampling boundary.
Logically, a normal external program read proceeds as:

```text
              address/strobe preparation          sample
CLKOUT     \__________/----------------\____________↓
MEN_n      ----high----\______________low__________/----
A11..A0    ----change---<======= valid address =====>----
D15..D0    -------------------<== input valid ==>-------
```

The diagram is relational, not to scale. After a falling `CLKOUT` edge the
address becomes valid, and active-low `MEN` asserts approximately one quarter
cycle later. At the following falling edge the processor samples the program
word; `MEN` deasserts and the next address transition begins.

Electrical bounds for both -20 and -25 speed columns:

| Parameter | Requirement |
|---|---|
| address valid after falling `CLKOUT` (`td1`) | 10 ns characterized minimum, 50 ns maximum |
| falling `CLKOUT` to `MEN` assertion (`td2`) | ¼ cycle − 5 ns characterized minimum, ¼ cycle + 15 ns maximum |
| falling `CLKOUT` to `MEN` deassertion (`td3`) | −10 ns characterized minimum, 15 ns maximum |
| input-data setup before falling `CLKOUT` | 50 ns minimum |
| input-data hold after falling `CLKOUT` | 0 ns minimum |
| address setup before `MEN` assertion | ¼ cycle − 45 ns minimum |

TI notes that the address is valid when `MEN`, `DEN`, or `WE` asserts.
Characterization-only minima must not be promoted to production guarantees.

## Table read

`TBLR` occupies three instruction cycles and creates this program-bus order:

| Cycle | Address role | Data-bus role | Strobe |
|---:|---|---|---|
| 1 | `TBLR` instruction prefetch | instruction input | `MEN` read |
| 2 | dummy next-instruction prefetch | instruction input, discarded | `MEN` read |
| 3 | program address from `ACC[11:0]` | table data input | `MEN` read |
| following | same next-instruction address as cycle 2 | instruction input, retained | `MEN` read |

The dummy word is fetched externally and then fetched again; suppressing it
would be externally observable and incorrect.

## Table write

`TBLW` also occupies three cycles:

| Cycle | Address/data role | Strobe behavior |
|---:|---|---|
| 1 | `TBLW` instruction prefetch | `MEN` read |
| 2 | dummy next-instruction prefetch | `MEN` read; word discarded |
| 3 | `ACC[11:0]` address and data-memory word driven | `MEN` inactive, `WE` active-low pulse |
| following | repeat next-instruction prefetch | `MEN` read |

The processor begins driving output data before `WE` asserts, holds it through
the falling `CLKOUT` boundary, then releases it after `WE` deasserts. Exact
`td6`–`td10` bounds remain data-sheet constraint parameters.

## I/O reads and writes

`IN` and `OUT` each occupy two cycles. Cycle 1 is the instruction prefetch.
During cycle 2 `MEN` remains inactive, the selected port is on `PA2..PA0`,
and upper address pins are zero.

- `IN`: `DEN` asserts active-low around the falling-edge sampling boundary;
  external data observes the same 50 ns setup and 0 ns hold requirements.
- `OUT`: `WE` asserts active-low, with processor-driven data valid through the
  falling-edge boundary.
- The following instruction prefetch begins after the I/O transaction.

The same physical `WE` pin is used for `OUT` and `TBLW`; address context
distinguishes I/O from program-space writes.

## BANZ

`BANZ` uses two consecutive normal program reads:

| Cycle | Address role | Result at falling-edge sample |
|---:|---|---|
| 1 | opcode PC | recognize `0xf400`; advance PC/address to the following word |
| 2 | opcode PC + 1 | sample the 12-bit target, test old selected `AR[8:0]`, decrement that field modulo 512, and select the next address |
| following | target if old counter was nonzero; otherwise opcode PC + 2 | normal next instruction read |

Both condition outcomes consume the second read and retire after two cycles.
The second word's documented upper nibble is zero. Each of the two reads uses
the normal address/`MEN`/falling-edge relationship above; BANZ adds no
`DEN` or `WE` phase
[ti-tms32010-users-guide-spru001b, §§2.4.1 and 2.6.1, Table 3-2, and `BANZ`,
printed pp. 2-9–2-10, 2-13, 3-6, and 3-16
(PDF pp. 33–34, 37, 56, and 66)]. **Confidence: VERIFIED_PRIMARY.**

## B

`B` also uses two consecutive normal program reads:

| Cycle | Address role | Result at falling-edge sample |
|---:|---|---|
| 1 | opcode PC | recognize `0xf900`; advance PC/address to the following word |
| 2 | opcode PC + 1 | sample the canonical 12-bit target, load PC, and retire |
| following | target | normal next instruction read |

Each read uses the normal address/`MEN`/falling-edge relationship and has no
`DEN` or `WE` phase. A clock-enable stall in the implementation holds the
active target-word phase, address, PC, and pending operation
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and `B`,
printed pp. 2-2, 2-13, 3-6, and 3-15
(PDF pp. 26, 37, 56, and 65)]. **Confidence: VERIFIED_PRIMARY.**

## Accumulator-conditional branches

`BGEZ`, `BGZ`, `BLEZ`, `BLZ`, `BNZ`, and `BZ` use the same native shape:

| Cycle | Address role | Result at falling-edge sample |
|---:|---|---|
| 1 | opcode PC | recognize the exact condition; advance PC/address to the following word |
| 2 | opcode PC + 1 | sample the canonical target, test unchanged 32-bit ACC, select target or opcode PC + 2, and retire |
| following | selected target/fallthrough | normal next instruction read |

Every predicate outcome consumes cycle 2. Each read has the ordinary
address/`MEN` relationship and no `DEN` or `WE` phase. Directed phase tests
cover both outcomes and an active target-phase stall for all six instructions
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and
individual branch pages, printed pp. 2-2, 2-13, 3-6, 3-17–3-18, 3-20–3-22,
and 3-24 (PDF pp. 26, 37, 56, 67–68, 70–72, and 74)].
**Confidence: VERIFIED_PRIMARY.**

## Branch on overflow

`BV` uses the same native shape:

| Cycle | Address role | Result at falling-edge sample |
|---:|---|---|
| 1 | opcode PC | recognize exact `0xf500`; advance PC/address to the following word without changing OV |
| 2 | opcode PC + 1 | sample the canonical target; if OV was set, select target and clear OV, otherwise select opcode PC + 2; retire |
| following | selected target/fallthrough | normal next instruction read |

Both outcomes consume cycle 2. A clock-enable stall during its active target
phase holds PC, address, pending operation, and OV. Directed phase tests cover
both outcomes and verify no data transaction
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and `BV`,
printed pp. 2-2, 2-13, 3-6, and 3-23
(PDF pp. 26, 37, 56, and 73)]. **Confidence: VERIFIED_PRIMARY.**

## Reset assertion and release

`RS` may change at any point in a processor cycle. To guarantee synchronous
recognition it must meet 50 ns setup before falling `CLKOUT` and remain low at
least five full `CLKOUT` cycles.

After recognized assertion:

- `DEN`, `WE`, and `MEN` become inactive high;
- the data bus becomes high impedance;
- PC/address becomes zero after the next complete processor cycle.

After recognized deassertion, normal operation resumes after one complete
processor cycle. The first program read is address 0, followed by address 1.
Because assertion is synchronized, exact response delay varies with the
arrival point inside the cycle. During a write cycle reset can momentarily
produce an invalid write address; wrappers must not invent a stronger
asynchronous-abort guarantee.

## Interrupt and BIO sampling

Both active-low inputs have a 50 ns setup requirement before falling
`CLKOUT`, maximum 15 ns falling-edge time, and minimum low pulse width of one
full `CLKOUT` cycle. This establishes the physical sampling boundary but not
the complete interrupt vector-fetch bus sequence.

## RTL mapping status

The standalone `tms32010_program_bus` primitive represents the normal read
with four explicit subphases per machine cycle:

1. falling-edge boundary: sample input, deassert prior strobe, start address
   transition;
2. address-valid/strobe-assert phase;
3. `CLKOUT` rising/high phase with strobe active;
4. high-to-falling setup phase with address/strobe/data stable.

Directed tests verify reset assertion at a falling boundary, the five-cycle
minimum assertion interval, one-cycle release delay, address-0/address-1
startup, quarter-cycle `MEN` assertion, address stability, the falling-edge
sample event, and clock-enable stalls. This four-phase mapping is an
implementation choice, not an assertion about the original internal gate
topology. `tms32010_phase_slice` now integrates these phases with the current
one-cycle sequential execution subset and the qualified two-cycle branch
paths: directed tests
verify synchronized PC/native-address advancement, ordinary same-boundary
retirement, branch target-word fetch and second-boundary retirement, stalls,
traps, and recognized reset. It has not been qualified for the remaining
branches, other multi-cycle operations, table, I/O, or interrupt sequences.
