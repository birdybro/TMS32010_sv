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

## Cycle labels and prefetch boundaries

TI's instruction-specific diagrams label the current opcode transaction
“instruction prefetch,” then number the execution intervals that follow it.
For example, Figure 2-10 shows four program-bus transactions for a
three-cycle `TBLR`: opcode prefetch, dummy prefetch, table transfer, and next
instruction prefetch. The three documented cycles are the three elapsed
intervals from completion of the current opcode prefetch through completion
of the next opcode prefetch. Figure 2-9 applies the same convention to the
two-cycle `IN`/`OUT` sequence.

The legacy `tms32010_phase_slice` drives the correct ordered transactions but
accounts and retires them at fetch-sample boundaries without a distinct
execute slot. Its “opcode cycle” terminology must therefore not be read as
TI's numbered execution-cycle label or as complete pipeline evidence. The
explicit `tms32010_sequential_pipeline_slice` currently maps this convention
only for sequential one-cycle instructions, exact
`B`/`BANZ`/`BV`/`BIOZ`/`CALL`, and the six accumulator branches
[ti-tms32010-users-guide-spru001b, §2.1.1 and Figures 2-2, 2-9, and 2-10,
printed pp. 2-3 and 2-16–2-17 (PDF pp. 27 and 40–41)].
**Confidence: VERIFIED_PRIMARY for the source labels and transaction
intervals; implementation scope VERIFIED_SIMULATION.**

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

| Boundary/interval | Address role | Data-bus role | Strobe |
|---|---|---|---|
| opcode prefetch boundary | `TBLR` instruction prefetch | instruction input | `MEN` read |
| execution cycle 1 | dummy next-instruction prefetch | instruction input, discarded | `MEN` read |
| execution cycle 2 | program address from `ACC[11:0]` | table data input | `MEN` read |
| execution cycle 3 | same next-instruction address as cycle 1 | instruction input, retained | `MEN` read |

The dummy word is fetched externally and then fetched again; suppressing it
would be externally observable and incorrect.

## Table write

`TBLW` also occupies three cycles:

| Boundary/interval | Address/data role | Strobe behavior |
|---|---|---|
| opcode prefetch boundary | `TBLW` instruction prefetch | `MEN` read |
| execution cycle 1 | dummy next-instruction prefetch | `MEN` read; word discarded |
| execution cycle 2 | `ACC[11:0]` address and data-memory word driven | `MEN` inactive, `WE` active-low pulse |
| execution cycle 3 | repeat next-instruction prefetch | `MEN` read |

The processor begins driving output data before `WE` asserts, holds it through
the falling `CLKOUT` boundary, then releases it after `WE` deasserts. Exact
`td6`–`td10` bounds remain data-sheet constraint parameters.

The qualified synchronous phase mapping for both table instructions is:

| Machine cycle / phase | Address | Active-low strobe | Boundary effect |
|---|---|---|---|
| opcode, phase 0 | opcode PC | none | address setup |
| opcode, phases 1–3 | opcode PC | `MEN` | sample opcode, capture `ACC[11:0]` and old data address |
| discarded, phase 0 | opcode PC + 1 | none | following-address setup |
| discarded, phases 1–3 | opcode PC + 1 | `MEN` | discard input and enter table phase |
| table, phase 0 | captured `ACC[11:0]` | none | table address and TBLW output-data setup |
| TBLR table, phases 1–3 | captured `ACC[11:0]` | `MEN` | sample program word into selected RAM |
| TBLW table, phases 1–3 | captured `ACC[11:0]` | `WE` | complete selected-RAM-to-program write |
| following, phase 0 | opcode PC + 1 | none | repeat discarded following-address setup |

The legacy wrapper's opcode, discarded, and table samples increment its
architectural cycle counter, and its table sample performs the RAM effect,
indirect AR/ARP post-modification, and documented final stack-bottom
duplication. It then presents the repeated next address. This preserves the
three-period bus spacing and all four ordered transactions, but retirement is
still attached to the table sample rather than held through completion of the
repeated next-instruction prefetch. A low FPGA clock enable holds every active
table phase, address, strobe, write datum, pending operation, and
architectural state. `sim/bus/tb_table_transfer_phase.sv` asserts the bus
rows, including `MEN`/`DEN`/`WE` exclusivity and the repeated following
address; explicit execute ownership remains unqualified.
**Confidence: VERIFIED_PRIMARY for the logical waveform;
VERIFIED_SIMULATION for legacy bus order; VERIFIED_HARDWARE is not claimed.**

## I/O reads and writes

`IN` and `OUT` each occupy two execution intervals after the opcode-prefetch
boundary. During execution cycle 1, `MEN` remains inactive, the selected port
is on `PA2..PA0`, and upper address pins are zero. Execution cycle 2 is the
next instruction prefetch.

- `IN`: `DEN` asserts active-low around the falling-edge sampling boundary;
  external data observes the same 50 ns setup and 0 ns hold requirements.
- `OUT`: `WE` asserts active-low, with processor-driven data valid through the
  falling-edge boundary.
- The following instruction prefetch begins after the I/O transaction.

The same physical `WE` pin is used for `OUT` and `TBLW`; address context
distinguishes I/O from program-space writes.

The qualified synchronous phase mapping is:

| Machine cycle / phase | Address | Active-low strobe | Boundary effect |
|---|---|---|---|
| opcode, phase 0 | opcode PC | none | address setup |
| opcode, phases 1–3 | opcode PC | `MEN` | sample opcode at phase-3 falling boundary |
| port, phase 0 | `{9'b0, ppp}` | none | port/address and output-data setup |
| port, phases 1–3 | `{9'b0, ppp}` | `DEN` for `IN`; `WE` for `OUT` | sample input or complete output at phase-3 falling boundary |
| following, phase 0 | opcode PC + 1 | none | next program-address setup |

In the legacy wrapper, the opcode sample advances architectural PC to PC+1
without retirement. The port-cycle sample performs the internal RAM write for
`IN` or completes the RAM-read-to-port transfer for `OUT`, applies indirect
AR/ARP post-modification, increments the cycle total a second time, and
retires while presenting the next program address. This preserves the
two-period bus spacing but does not yet retain execute ownership through
completion of the next-instruction prefetch. A low FPGA clock enable holds
the current native phase, address, strobe, pending operation, write data, and
architectural state; this is a synchronous emulation control, not an
undocumented original READY pin.

`sim/bus/tb_io_phase.sv` asserts the legacy bus rows above, including mutually
exclusive `MEN`/`DEN`/`WE`, input changes before the enabled sample, stable
output data, and the next program address. Analog delay values remain wrapper
constraints rather than RTL delays. Explicit execute ownership remains
unqualified. **Confidence: VERIFIED_PRIMARY for the logical waveform;
VERIFIED_SIMULATION for legacy bus order; VERIFIED_HARDWARE is not claimed.**

## BANZ

Except for exact `B`, `BANZ`, `BV`, `BIOZ`, `CALL`, and the six accumulator
branches, the branch-family tables below describe transaction order in the
legacy wrapper. Their numbered read slots are not TI's post-prefetch
execution-cycle labels. TI establishes two words, two cycles, the following
target word, and ordinary program-memory fetch behavior, but no located
original-part document supplies a dedicated branch/call pin waveform.
Consequently, the combined
read/execute/commit mapping for these still unintegrated families is INFERRED
even where each component fact is VERIFIED_PRIMARY.

The explicit pipeline drives `BANZ` through these source-derived intervals:

| Boundary/interval | Address role | Execute ownership/effect |
|---|---|---|
| opcode prefetch boundary | opcode PC | recognize `0xf400`; BANZ enters execute ownership |
| execution cycle 1 | opcode PC + 1 | sample canonical target operand; old selected `AR[8:0]` selects target or fallthrough fetch without decrement |
| execution cycle 2 | target if old counter was nonzero; otherwise opcode PC + 2 | fetch selected instruction; decrement selected counter modulo 512, retire BANZ, and capture fetched word |

Both condition outcomes consume both execution intervals. The second word's
documented upper nibble is zero. Every transaction uses the normal
address/`MEN`/falling-edge relationship above; BANZ adds no `DEN` or `WE`
phase. A low clock enable in an active selected-fetch phase holds the bus,
execute owner, PC, counter, and numeric cycle total
[ti-tms32010-users-guide-spru001b, §§2.4.1 and 2.6.1, Table 3-2, and `BANZ`,
printed pp. 2-9–2-10, 2-13, 3-6, and 3-16
(PDF pp. 33–34, 37, 56, and 66)]. **Confidence: VERIFIED_PRIMARY for the
component facts; INFERRED for the combined execute-interval mapping;
VERIFIED_SIMULATION for the stated implementation.**

## B

The explicit pipeline drives `B` through these source-derived intervals:

| Boundary/interval | Address role | Execute ownership/effect |
|---|---|---|
| opcode prefetch boundary | opcode PC | recognize `0xf900`; B enters execute ownership |
| execution cycle 1 | opcode PC + 1 | sample canonical target operand; B remains executing and redirects next fetch |
| execution cycle 2 | target | fetch target instruction; load PC, retire B, and capture target into execute slot |

Each read uses the normal address/`MEN`/falling-edge relationship and has no
`DEN` or `WE` phase. In the explicit pipeline, opcode-prefetch completion
places B in execute ownership; the operand read occupies execution cycle 1;
the redirected target-instruction read occupies execution cycle 2; and B
retires as that target fetch completes. A clock-enable stall holds the active
target fetch, address, PC, and B ownership
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and `B`,
printed pp. 2-2, 2-13, 3-6, and 3-15
(PDF pp. 26, 37, 56, and 65)]. **Confidence: VERIFIED_PRIMARY for the
component facts; INFERRED for the combined execute-interval mapping.**

## Accumulator-conditional branches

The explicit pipeline drives `BGEZ`, `BGZ`, `BLEZ`, `BLZ`, `BNZ`, and `BZ`
through these source-derived intervals:

| Boundary/interval | Address role | Execute ownership/effect |
|---|---|---|
| opcode prefetch boundary | opcode PC | recognize exact condition; branch enters execute ownership |
| execution cycle 1 | opcode PC + 1 | sample canonical target operand; unchanged full 32-bit ACC selects target or fallthrough fetch |
| execution cycle 2 | selected target or opcode PC + 2 | fetch selected instruction; retire branch and capture fetched word |

Every predicate outcome consumes both execution intervals. Each transaction
has the ordinary address/`MEN` relationship and no `DEN` or `WE` phase. A
directed matrix covers every predicate and both outcomes, stalls the selected
fetch on each path, preserves ACC, defers the fetched instruction's effect,
and parks malformed operands. Legacy directed phase tests retain the complete
taken/untaken native transaction matrix
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and
individual branch pages, printed pp. 2-2, 2-13, 3-6, 3-17–3-18, 3-20–3-22,
and 3-24 (PDF pp. 26, 37, 56, 67–68, 70–72, and 74)].
**Confidence: VERIFIED_PRIMARY for component facts; INFERRED for the combined
execute-interval mapping; VERIFIED_SIMULATION for the implementation.**

## Branch on overflow

The explicit pipeline drives `BV` through these source-derived intervals:

| Boundary/interval | Address role | Execute ownership/effect |
|---|---|---|
| opcode prefetch boundary | opcode PC | recognize exact `0xf500`; BV enters execute ownership |
| execution cycle 1 | opcode PC + 1 | sample canonical target operand; old sticky OV selects target or fallthrough fetch without clearing |
| execution cycle 2 | target if old OV was set; otherwise opcode PC + 2 | fetch selected instruction; retire BV, capture fetched word, and clear OV only on the taken path |

Both outcomes consume both execution intervals. Every transaction uses the
normal address/`MEN`/falling-edge relationship and adds no `DEN` or `WE`
phase. A low clock enable in an active selected-fetch phase holds the bus,
execute owner, PC, OV, and numeric cycle total. Directed tests cover both
old-OV outcomes, both selected-path stalls, deferred instruction effects, and
malformed-operand parking before OV clear
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1, Table 3-2, and `BV`,
printed pp. 2-2, 2-13, 3-6, and 3-23
(PDF pp. 26, 37, 56, and 73)]. **Confidence: VERIFIED_PRIMARY for component
facts; INFERRED for the combined execute-interval mapping;
VERIFIED_SIMULATION for the stated implementation.**

## Branch on I/O status

The explicit pipeline drives `BIOZ` through these source-derived intervals:

| Boundary/interval | Address role | Execute ownership/effect |
|---|---|---|
| opcode prefetch boundary | opcode PC | recognize exact `0xf600`; BIOZ enters execute ownership without latching BIO |
| execution cycle 1 | opcode PC + 1 | sample canonical target and live active-low BIO; low selects target and high selects fallthrough fetch |
| execution cycle 2 | selected target or opcode PC + 2 | fetch selected instruction; retire BIOZ and capture fetched word |

Both outcomes consume both execution intervals. TI explicitly says BIO is
sampled every machine cycle and is not latched. The electrical input must
meet 50 ns setup before execution cycle 1's falling target-word/operand
boundary. The implementation retains only that resulting branch decision
through cycle 2; later pin changes or a clock-enable stall cannot redirect an
already selected fetch. Every transaction uses the normal
address/`MEN`/falling-edge relationship and adds no `DEN` or `WE` phase.
Directed tests change BIO during an operand stall, change it again after
selection, stall both selected paths, defer selected-instruction effects, and
park malformed operands
[ti-tms32010-users-guide-spru001b, §§2.1.1, 2.6.1, and 2.9, Table 3-2,
`BIOZ`, and Appendix A BIO timing, printed pp. 2-2, 2-13, 2-18, 3-6, 3-19,
and data-sheet 20 (PDF pp. 26, 37, 42, 56, 69, and 376)].
**Confidence: VERIFIED_PRIMARY for component facts and the pin sample;
INFERRED for the combined execute-interval mapping; VERIFIED_SIMULATION for
the stated implementation.**

## Direct subroutine call

The explicit pipeline drives `CALL` through these source-derived intervals:

| Boundary/interval | Address role | Execute ownership/effect |
|---|---|---|
| opcode prefetch boundary | opcode PC | recognize exact `0xf800`; CALL enters execute ownership without pushing |
| execution cycle 1 | opcode PC + 1 | sample canonical target; retain CALL; do not push |
| execution cycle 2 | selected target | fetch target instruction; push opcode PC + 2, retire CALL, and capture target word |

Every interval uses an ordinary program `MEN` read and no data/I/O
transaction. Clock-enable stalls during operand or selected-target phases
hold PC, address, execute ownership, and all stack levels. Directed tests
prove the push occurs only at selected-target capture, nested return
addresses shift correctly, the target instruction executes in the following
interval, non-stack state is preserved, and malformed operands park before a
push
[ti-tms32010-users-guide-spru001b, §§2.1.1 and 2.6.1–2.6.2, Table 3-2, and
`CALL`, printed pp. 2-2, 2-13–2-14, 3-6, and 3-26
(PDF pp. 26, 37–38, 56, and 76)]. **Confidence: VERIFIED_PRIMARY for
component facts; INFERRED for the combined execute-interval mapping;
VERIFIED_SIMULATION for the implementation.**

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
full `CLKOUT` cycle. BIOZ applies the current BIO level at its target-word
sample. Figure 2-12 establishes the interrupt fetch sequence as instruction N,
instruction N+1, dummy instruction N+2, then vector word 2, with a dummy
execute slot during the vector fetch. The phase wrapper now verifies those
four external program reads for a masked request released by EINT. Its input
is sampled only at enabled falling-edge boundaries; a later integration
wrapper must provide explicit CDC logic if `INT` originates in another FPGA
clock domain.

The directed native INT sampling test starts a low level in each of modeled
phases 0 through 3 and retains it through an enabled phase-3-to-phase-0
falling boundary. It requires the pending latch and architectural cycle count
to remain unchanged before that boundary; one phase-2 case holds
`clock_enable_i` low for five FPGA clocks before release. All four cases then
verify one protected retirement, the nonretiring return-PC dummy sample, and
vector-2 selection. This is an assertion about the explicit digital phase
mapping. A phase-3 transition in this simulation is not evidence that a
physical pin transition violating the 50 ns setup time would be recognized.

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
traps, and recognized reset. It has not been qualified for indirect call/return,
other unimplemented multi-cycle operations, or the complete fetch/execute
pipeline. Table, I/O, and the cited interrupt program-read sequence now have
directed native-phase tests, including INT ownership at the enabled falling
boundary for all four modeled arrival phases.
