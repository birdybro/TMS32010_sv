# RTL qualification boundary

The current RTL is an execution slice, not a cycle-accurate TMS32010 core.
`tms32010_core` supports only `ABS`, `ADD`, `ADDH`, `ADDS`, `AND`, `APAC`, `B`, `BANZ`, `BGEZ`, `BGZ`, `BIOZ`, `BLEZ`, `BLZ`, `BNZ`, `BV`, `BZ`, `CALL`, `DINT`, `DMOV`, `EINT`, `IN`, `LAC`, `LACK`, `LAR`,
`LARK`, `LARP`, `LDP`, `LDPK`, `LST`, `LT`, `LTA`, `LTD`, `MAR`, `MPY`, `MPYK`, `NOP`, `OR`, `PAC`,
`OUT`, `ROVM`, `SACL`, `SACH`, `SAR`, `SOVM`, `SPAC`, `SST`, `SUB`, `SUBC`, `SUBH`, `SUBS`,
`TBLR`, `TBLW`, `XOR`, `ZAC`,
`ZALH`, and `ZALS` at an
instruction-boundary program interface. One asserted `clock_enable_i` retires
one supported one-cycle instruction. Unsupported words, undocumented SACH
shifts, and common-address data accesses outside the verified 144-word RAM
assert `illegal_o` and do not advance the PC.

`tms32010_decode` also emits `data_addressed_o`, an implementation-only
family qualifier used to shorten the core's effective-address and legality
cones. It is not an architectural instruction attribute and has no standalone
meaning: every caller must combine it with `valid_o`, because an invalid word
inside a recognized family envelope may still assert the qualifier. The
exhaustive decoder test visits all 65,536 words and independently checks every
valid encoding; the one-step formal decoder proof covers the same valid space.

`tms32010_internal_ram` supplies the original-part 144 by 16-bit data store.
Its default asynchronous read lets the standalone single-boundary execution
slice consume an operand without inventing another architectural cycle. The
explicit fetch/execute wrapper instead enables ADR-0004's registered read:
the effective address is retained early enough for the operand to arrive by
phase 1 without adding a processor cycle. Same-address write forwarding makes
the newly committed word available during the next owner's phase-0 setup
interval. In registered mode, `internal_ram_read_enable_i` must advance with
the caller's FPGA subphase sequence; the explicit wrapper connects it to
`clock_enable_i`, so a global pause holds the captured operand and forwarding
metadata. Standalone asynchronous users still connect the input explicitly,
although that generate branch does not consume it. Quartus maps registered
mode to one portable 144-by-16 M10K; no vendor
primitive appears in RTL. These are implementation choices, not claims about
the physical TMS32010 memory array. DMOV and LTD use independent RAM read and
write addresses to copy the unchanged source word to the next location; LTD
additionally loads T and accumulates P.
The
explicit debug write port is only for deterministic verification preload;
physical reset never initializes the RAM, and assertions reject preload during
live execution or collision with an architectural write. Logical source
address, distinct write address, operation, and data outputs expose internal
activity for tests and are not original package pins.

`tms32010_multiplier` is a combinational signed 16-by-16 implementation.
It explicitly reproduces the original part's documented
`0x8000 * 0x8000 -> 0xc0000000` exception. Quartus may infer a native DSP
resource; that mapping is a synthesis choice and the RTL contains no
vendor-specific primitive. MPYK feeds the same datapath with its sign-extended
13-bit instruction constant and performs no data-memory access.

`tms32010_input_shifter` is the shared combinational 16-to-32-bit signed input
barrel shifter used by `LAC`, `ADD`, and `SUB`. It sign-extends the selected
data word before the decoded 0-through-15 left shift; zeros enter at the low
end. A one-step symbolic proof constructs the expected output bit by bit and
exhausts every data/count combination. Decode, data addressing, arithmetic,
status, and cycle timing remain in the architectural core.

`tms32010_output_shifter` is the shared combinational SACH path. It accepts
ACC[31:12], because lower bits cannot reach the stored high word for the only
legal shifts (zero, one, and four), and returns the exact 16-bit write word.
The architectural core asserts that every decoded SACH selects a legal mode.
The block itself fails closed with an invalid qualifier and zero data for the
other five fields; that is implementation policy, not undocumented silicon
behavior. A one-step symbolic proof leaves the full ACC and shift field
arbitrary, checks an independently bit-indexed result, proves low-bit
independence, and reaches primary examples plus invalid-field covers.

`tms32010_accumulator` is the shared combinational signed 32-bit add/subtract
and OVM-saturation block. The core uses it for `ADD`, `SUB`, `SUBH`, `APAC`,
`SPAC`, and the previous-P accumulation in `LTA`/`LTD`; their sticky `OV`
register update remains in the architectural core. The block separately
exports the modulo result, current-operation signed-overflow predicate, and
OVM-selected result. A one-step symbolic proof compares every operand pair,
both operations, and both OVM states against an independently widened 33-bit
signed calculation. ADDS, ADDH, SUBS, and SUBC retain separate datapaths
because their documented operand, status, or recurrence rules differ.

This temporary core interface does not itself reproduce `MEN`, `CLKOUT`,
fetch/execute overlap, or pin subphases. It exists to qualify decode, state
effects, clock enables, and reset preservation. It must not be used alone as
evidence of cycle accuracy.

`tms32010_fetch_execute` is the pipeline ownership boundary required by
ADR-0002. It stores explicit execute validity, word, and
address; accepts a valid fetched instruction only when the slot is empty or
the current instruction completes; holds an incomplete instruction; and
invalidates the slot on reset or redirect. Assertions reject a valid fetch on
a flush and overwriting an incomplete instruction. Directed simulation covers
pipeline priming, sequential overlap, stalls, multicycle retention, branch
redirect, interrupt dummy/vector flow, and recognized reset. Standalone Yosys
synthesis finds 29 flip-flops, 68 generic cells including two retained checks,
and no structural problems. The block alone does not prove integrated-core
behavior; its surrounding sequencer must classify every fetched, operand, and
dummy transaction.
A 12-step bounded formal harness proves its capture, hold, replacement,
bubble, reset, and flush transitions for arbitrary words and boundary timing
under the block's two explicit legal-input contracts. The non-vacuity cover
reaches a complete prime/stall/replace/flush/target path at step 7; this still
does not qualify core integration.

`tms32010_sequential_pipeline_slice` is its first deliberately narrow core
integration. A separate fetch address primes word 0 without retirement, then
stays one word ahead while the core retires decoded one-cycle instructions.
Directed tests cover stalls and reset recovery; a 43-retirement offset
differential spans all 38 already-qualified one-cycle operation families and
compares the complete exposed architectural state. Exact B, BANZ, BV, BIOZ,
CALL, and the six accumulator-conditional branches also retain execute
ownership through nonexecutable operand fetch and selected instruction fetch. BANZ
selects from the old nine-bit counter and decrements only at branch
retirement; the accumulator family selects from the unchanged full 32-bit
ACC; BV selects from old sticky OV and clears it only at taken retirement;
BIOZ samples raw active-low BIO at operand completion and retains only the
resulting decision through the selected fetch; CALL pushes opcode-PC+2 only
at selected-target retirement. IN and OUT retain ownership across the
primary-defined I/O transfer and following-instruction prefetch: the transfer
interval multiplexes the zero-extended port address and asserts only DEN or
WE, the following interval asserts only MEN at PC+1, and retirement/capture
occurs only at that second boundary. The IN word is sampled at the transfer
boundary and committed before the captured following instruction can execute;
OUT data comes from the old resolved internal-RAM word. Both intervals hold
under clock-enable stalls, and invalid RAM addresses park before a native
strobe. The qualified Figure 2-12 path retains one protected instruction
while its concurrent N+2 read is discarded, empties the execute slot for the
entry interval, and captures vector 2 without executing it. Independent N+2
and vector stalls prove retirement, stack push, and vector effects occur only
at their owning boundaries. If MPY or MPYK occupies that protected slot, the
wrapper retains protection through one additional instruction; directed tests
cover both signed products, internal-read versus program-only activity,
stalls, dummy discard, and the post-following stacked PC.
The current protected-slot DINT cancellation remains PROVISIONAL. Original
SPRU001B executes N+1, later mixed-family SPRU013 dummy-fetches it, MAME lacks
the overlap, and pinned IKA represents entry-wins (`SC-039`, `OQ-019`). The
physical probe, not these RTL checks, is the resolving evidence.
The explicit wrapper also retains TBLR/TBLW through Figure 2-10's discarded
PC+1 read, ACC-addressed program transfer, and repeated PC+1 read. TBLR
carries sampled program data from the transfer boundary to retirement; TBLW
asserts separate
`program_write_o`/`program_write_data_o` outputs while `we_n_o` is low.
RAM/AR/ARP/stack effects and retirement occur only when the repeated PC+1
word is captured. Directed stalls cover all three intervals, and a
self-modifying TBLW case proves that only the rewritten repeated fetch
executes. Other multicycle, reserved, or invalid-address execute words park
the wrapper at
phase zero with a visible `pipeline_blocked_o`; this is a qualification
mechanism, not claimed hardware behavior.

One context-owned `core_program_data` register now carries ordinary executable
words, accepted control operands, and sampled TBLR data. Each value is captured
one ownership boundary before the core consumes it and remains stable while a
native phase is paused. At the same retirement edge that consumes an operand
or table word, a selected or repeated executable fetch may replace the carrier
for the next owner. Directed BANZ and TBLR traces inspect those capture, hold,
consume, and replacement points; the existing composed table proofs retain the
external transaction and retirement checks. This is an FPGA pipeline carrier,
not an original TMS32010 register or a new architectural boundary.

The wrapper's internal-data observation follows ADR-0004. A newly owned
instruction's `data_address_o` is visible immediately at phase 0, while
`data_read_data_o` is guaranteed to match that address by phase 1 and through
the eventual architectural boundary. Same-address writes bypass the inferred
RAM's old-data output, so a following `OUT` has its new word during phase 0,
before `WE` becomes active. These signals are verification diagnostics, not
original package pins; standalone-core mode retains its combinational read.

A 40-step formal harness checks one fixed direct-TBLR use of this complete
hierarchy across arbitrary clock-enable stalls. It covers discarded PC+1,
ACC-addressed program read, RAM commit, repeated PC+1, and consumption by the
following LAC; the complete path is reachable at step 34. It is not a general
pipeline, TBLW, indirect-table, or interrupt proof by itself.

A complementary 40-step harness checks one direct TBLW self-modification
under the same enabled phase-3 synchronous program-memory contract used by
the directed testbench. The old following ZAC survives until the write
boundary, replacement `LACK 0x44` is written exactly once, and only its
repeated fetch is captured and executed; cover reaches step 35. The
verification-only RAM preload and external-memory model are harness
conveniences, not architectural reset or electrical timing claims.

`tms32010_program_bus` is the first independently tested native timing
primitive. It advances a four-subphase logical `CLKOUT`, asserts `MEN` one
quarter-cycle after the falling boundary, samples at the next falling
boundary, preserves address during the active strobe, and implements the
documented one-cycle reset-release wait. It does not model analog pin delays.

`tms32010_phase_slice` connects that phase primitive to the execution slice.
For the 38 currently qualified one-cycle operation families it samples
and retires on the same falling boundary. B, BANZ, BIOZ, BV, CALL, and the six
qualified accumulator branches instead fetch their following target words through a
second complete, independently stallable
normal read and retire only at that second falling boundary. All paths keep PC and native
address aligned and hold state on traps or clock-enable stalls. BV clears OV
only on a taken second-cycle retirement. This is not a general sequencer: the
raw active-low `bio_i` level at BIOZ's second falling boundary owns its
predicate; the opcode cycle does not latch the pin. CALL shifts opcode-PC+2
into the exposed four-level 12-bit stack only at second-cycle retirement. The
IN/OUT pending state instead changes the second cycle from a program read to
one mutually exclusive native I/O transaction: `io_port_o` drives A2–A0,
`io_read_o`/DEN samples the live `io_read_data_i` word into RAM for IN, and
`io_write_o`/WE drives `io_write_data_o` from RAM for OUT. Address, controls,
write data, PC, and pending indirect updates hold across clock-enable stalls;
the old internal address is used before AR/ARP commit at retirement.
TBLR/TBLW instead enter a discarded-prefetch cycle at PC+1 and then an
ACC-addressed table cycle. TBLR keeps `program_read_o` active and writes the
sampled word to RAM; TBLW asserts the distinct `program_write_o` and drives
`program_write_data_o` from RAM. The third sample retires, applies indirect
updates, and duplicates old stack level 2 into the bottom before the wrapper
repeats PC+1. The remaining branches, other multi-cycle instructions, and
unresolved CALA/RET/PUSH/POP sequences remain absent. The current interrupt
path is retirement-mapped and has directed external-order/entry tests, but it
does not yet use the standalone fetch/execute register.

SUBC retires through this same path only in legally scheduled test streams
whose following instruction does not read ACC. Immediate internal ACC commit
and intermediate-subtraction OV detection remain provisional under
`OQ-017`/`OQ-018`.

The phase primitive separates `initialize_i` (explicit deterministic FPGA/test
initialization) from `rs_i` (the emulated active-high form of physical
active-low `RS`). Initialization clears the modeled registers and status for
reproducibility but does not initialize internal RAM. Physical reset assigns
only the source-backed control effects; unlisted state receives no arbitrary
reset value. `CLKOUT` phases continue while `rs_i` is held, matching the
data-sheet reset waveform. Retention of unlisted state is an implementation
policy pending `OQ-012`, not a physical-device reset claim. TI's contemporary
EVM manual corroborates recoverability by saying warm RESET saves every
register except PC, but its separate clear/corruption warning and unpublished
save ordering keep the policy PROVISIONAL under `SC-042`; the two exact
before/after hardware fixtures are documented in
`docs/research/reset_retention_experiment.md`.
The core also forces its nonphysical `instruction_valid_o` qualification low
during deterministic initialization and recognized physical reset so inactive
program-data pins cannot advertise executable ownership.

The synthesizable code:

- uses one rising-edge clock and synchronous active-high reset;
- has no generated or gated clocks;
- leaves physical-reset-unspecified data state unspecified;
- resets the PC to zero and masks interrupts;
- sets and clears `INTM` for exact `DINT`/`EINT` words without claiming
  interrupt recognition or EINT's following-instruction service delay;
- loads `OV`, `OVM`, `ARP`, and `DP` from an `LST` internal-RAM read while
  preserving `INTM`; indirect next-ARP precedence is a reversible provisional
  policy under `OQ-015`/`SC-009`, pending the exact original-NMOS probe;
- preserves `OVM` through physical reset as TI documents;
- rejects all 372 simultaneous INC/DEC control words before effects under
  `OQ-010`/`SC-040`; this is fail-closed project behavior, not a claim that
  original silicon traps or preserves the selected AR;
- suppresses instruction qualification and every transaction class while
  recognized physical reset is active;
- exposes sticky `OV` for ADD/ADDS/APAC/LTA/LTD/SPAC/SUB/SUBS
  wrap/saturation verification and a separately labeled provisional
  intermediate-subtraction `OV` path for nonsaturating SUBC;
- performs LTA's internal-RAM-to-T load and previous-P accumulation in one
  retirement with APAC's overflow result policy;
- performs LTD's simultaneous source read, unchanged next-address copy,
  T load, and previous-P accumulation in one retirement;
- exposes T and P for multiply-path differential verification;
- uses no vendor primitive.

Run:

```sh
make instruction-tests
make lint
```
