# Original-TMS32010 physical-reset retention experiment

## Question and present claim boundary

This experiment targets `OQ-012`: does a warm physical `RS` assertion preserve
`ACC`, `T`, `P`, `AR0`, `AR1`, `ARP`, `DP`, the four stack words, and `OV`, as
the current portable implementation does?

The production-device guide does not assign those values. The current
model/RTL retention remains a reversible **PROVISIONAL** policy. Contemporary
TI EVM behavior corroborates retention as a hypothesis, but no repository
test or software implementation is relabeled as original-silicon proof.

## Production reset contract

SPRU001B says active-low `RS` must be held for at least five clock cycles. At
the next complete cycle it synchronously clears PC and the address bus, makes
`MEN`, `DEN`, and `WE` inactive, and tristates the data bus. It also masks
interrupts, clears the interrupt flag, and explicitly leaves `OVM` unchanged.
The separate PC description repeats only `PC=0`. Neither passage assigns a
reset value to the other programmer-visible registers or the stack
[ti-tms32010-users-guide-spru001b, Sections 2.6.1 and 2.11, printed
pp. 2-13 and 2-19 (PDF pp. 37 and 43)].

Silence is not a zero value, and it is not by itself proof of retention.
Power-up state is a separate question: a value cannot be described as
"retained" across loss of power without storage evidence.

## Contemporary TI implementation evidence

### Evaluation-module warm reset

The original TMS32010 EVM manual says that using RESET to stop `EX` or `RUN`
is an uncontrolled halt that saves all internal registers except PC. Its
register menu identifies ACC, T, P, AR0, AR1, OV, OVM, DP, ARP, and every
stack location. Thus the intended EVM workflow expects those values to remain
recoverable after the event that resets PC
[ti-tms32010-evm-users-guide-spru005a, Table 3-2 and Sections 3.3.2, `EX`,
and `RUN`, printed pp. 3-4-3-5, 3-27-3-28, and 3-56-3-57 (PDF pp. 45-46,
68-69, and 97-98)].

That evidence has a qualification. The same guide's warm-reset overview says
the uncontrolled halt clears internal registers and may corrupt program or
data memory. It does not publish the monitor's save-before-clear sequence or
prove that a displayed shadow value was read without intervening instructions
[ti-tms32010-evm-users-guide-spru005a, Section 2.3.10.2, printed
pp. 2-28-2-29 (PDF pp. 39-40)]. The EVM therefore **CORROBORATES** register
recoverability under its workflow; it does not independently specify every
hardware latch's `RS` transistor.

### Related patent distinction

TI patent US4577282A says `RS` clears PC/address, tristates the data bus, and
inactivates the external controls. It then says address and temporary data
registers are cleared by a reset routine in ROM, while internal RAM is not
cleared. The explicit attribution to software prevents that sentence from
being imported as a hardware-reset value for the production TMS32010
[ti-dsp-microcomputer-patent-us4577282a, patent columns 5-6
(PDF p. 29)].

### Independent implementation policies

- Pinned MAME resets PC and ACC, clears `OV`/`ARP`/`DP`, sets `OVM` and
  `INTM`, and leaves T/P/AR/stack values untouched after their separate device
  start initialization. Its forced `OVM=1` conflicts with the production
  requirement to leave OVM unchanged, so this mixed policy is not a physical
  oracle [mame-tms320c1x-core-030fefc, reset handler, lines 925-932].
- Pinned IKA retains OVM but explicitly clears several unlisted datapath,
  address, multiplier, and stack elements. Its DP reset conditional also does
  not form a coherent original-device reset specification. These are
  independent FPGA choices, not silicon evidence
  [ika32010-rtl-51bc1f0, `IKA32010.sv` reset paths around lines 102-114,
  262-413, and the instantiated ALU/multiplier/stack reset paths].

The disagreement is recorded as `SC-042`.

## Two complementary self-checking fixtures

[reset_retention_set_probe.asm](../../tests/asm/reset_retention_set_probe.asm)
and
[reset_retention_clear_probe.asm](../../tests/asm/reset_retention_clear_probe.asm)
use only documented original-part instructions and contain no copyrighted
program data. Both implement the same protocol:

1. Address 0 executes `BIOZ POST_RESET`. BIO high selects initialization;
   BIO low after reset selects observation. No retained RAM flag or candidate
   register chooses the path.
2. Initialization establishes a fully known register vector.
3. The program exports that vector through port 7 before reset. Destructive
   observations of P, T, and stack are followed by explicit reconstruction;
   `LST` restores the previously saved status, and ACC is restored last.
4. An armed marker is emitted only after reconstruction. The program then
   loops on a branch whose only architectural effect is PC selection.
5. Following external `RS`, the observer executes `SST` first. That captures
   `OV`, `OVM`, `ARP`, and `DP` before `LDPK 0` establishes a known scratch
   page. ACC and both ARs are stored before PAC/MPYK/POP destructively expose
   P, T, and the stack.
6. Every scratch word consumed after reset is written after reset. The
   post-reset vector therefore does not depend on internal-RAM retention.

The vector order is:

| Position | Observation |
|---:|---|
| 0-1 | ACC low, ACC high |
| 2-3 | AR0, AR1 |
| 4 | complete SST status word |
| 5-6 | P low, P high |
| 7-8 | T reconstructed through `MPYK 1`, low then high |
| 9-12 | stack top, level 1, level 2, bottom |

The set-pattern fixture has the following project-model pre-reset vector:

```text
00a5 0000 0012 0034 ffff 00ff 0000 0055 0000 0044 0033 0022 0011
```

On physical hardware, status `fffd` instead of `ffff` differs only in reserved
status bit 1 under `OQ-003`; retain it rather than rejecting the run. The
fixture then emits armed marker `00a1`. The clear-pattern fixture complements
every status candidate (`OV=OVM=ARP=DP=0`) and uses distinct nonzero multi-bit
state:

```text
003c 0000 0056 0078 3efe 00aa 0000 0022 0000 0088 0077 0066 0055
```

Status `3efc` is the corresponding reserved-bit-1 alternative to project-model
`3efe`. The fixture then emits armed marker `00a2`. Each post-reset vector is
followed by terminal marker `00af`. The assembler regression locks every sparse
address/word pair with a fixed digest, and the instruction-boundary model
replays the pre/restore/reset/post path as fixture validation. That replay
checks the current provisional policy only; it is not hardware evidence.

## Capture normalization and evidence boundary

Use `tools.trace.reset_retention_capture` with one falling-boundary CSV and one
derived reset-transition CSV per fixture. The exact schemas, additional
metadata fields, and complete command are specified in
[the trace-tool README](../../tools/trace/README.md). The tool validates both
exact 594-byte dense images assembled from the sparse address layouts, every
OUT fetch/write pair, initial-high and
post-reset-low BIO decisions, measured RS/BIO transitions, complete reset
intervals, reset bus controls/address, terminal flow, and raw/photo hashes.

Each sidecar must also bind the capture to the exact fixture source, a dense
297-word address/word listing (including zero-filled address gaps), and the
normalized falling-boundary trace. The SET and CLEAR packages are validated
independently and must identify the same raw package marking, tracking/date
string, lot string, and package type. A complete package verifies seven
hashed artifacts: source, listing, program image, normalized trace, and the
top, bottom, and board-context photographs. These checks establish only a
`this_specimen_only` evidence scope; they do not decode a mask identity or
constrain any post-reset field to the provisional implementation result.

Review qualification requires 32 nominal runs per fixture and coverage of all
nine combinations of slow/nominal/fast clock condition with 5-, 8-, and
32-cycle reset targets. Raw `CLKOUT` timestamps, not a condition label, are
the measured clock evidence; their ranges must preserve the declared slow to
nominal to fast ordering.

The post-reset vector is never compared with the project model as an expected
passing value. Instead, the normalizer retains every raw word, separates SST
reserved bit 1, and reports retained, forced-zero, forced-one, or other
relationships for each complete architectural field. Variation and
non-retention remain reviewable evidence. Only `OVM` must retain its fixture
value, because unchanged OVM is part of the production reset contract and is
the experiment's validity control. `observed_full_retention_candidate` remains
a descriptive capture result, not an architectural confidence promotion.
Even a structurally review-ready package always reports
`acceptance_complete=false` pending engineering review and a second identified
original specimen.

## Physical capture procedure

Use an original NMOS TMS32010, not a TMS320C10/C15, TMS32020/C25, or later
compatible device:

1. Record the full package marking, date/mask code, board/EVM and monitor
   revisions, oscillator, supply voltage, program-memory access time, and
   hashes of the exact program images/listings.
2. Hold BIO high, assert `RS` for a conforming startup interval, release it,
   and capture the complete pre-reset vector and armed marker. Reject a run if
   either differs from the fixture's exact pre-vector/marker.
3. After the armed marker, drive BIO low with margin to the next relevant
   cycle, then assert `RS` for at least five complete `CLKOUT` cycles. Keep BIO
   low through the address-0 `BIOZ` decision after release.
4. Capture `RS`, BIO, `CLKOUT`, active-low `MEN`, `DEN`, `WE`, `A11:A0`, and
   `D15:D0` through terminal marker `00af`. Preserve raw edges and decoded
   port-7 words.
5. Run at least 32 warm-reset trials per fixture at nominal timing. Repeat
   with 5-, 8-, and 32-cycle reset holds and at the documented slow and fast
   clock limits when all memory timing requirements remain satisfied.
6. Repeat both fixtures on another original-part date/mask code before making
   a mask-independent claim. Preserve every unstable or mixed result.
7. Optionally repeat with the EVM `RUN` warm-reset/`STATE` workflow as a
   corroborating transcript, but do not substitute its shadow state for the
   pin-level port capture.

## Interpretation and acceptance

The set-pattern passing sequence is its 13-word pre-vector, `00a1`, the same
13-word post-vector, then `00af`. The clear-pattern equivalent uses `00a2`.
At status position 4, compare the complete raw pre/post word while accepting
either reserved-bit-1 value; all named bits and all other vector positions
must match the case definition. Both directions are required: one pattern
cannot distinguish retention from a coincidentally forced reset value.

`OVM` is the built-in validity control. It must remain one in the set case and
zero in the clear case because production TI documentation explicitly says
reset leaves it unchanged. A failure there invalidates the capture setup or
reveals a source conflict that must be investigated before interpreting any
unlisted bit.

A qualified matching pair can upgrade retention for the tested device and
mask. A partial match identifies per-register behavior; it must not be rounded
to an all-or-nothing result. Any missing vector word, wrong named pre-state,
unexplained difference outside reserved status bit 1, absent marker, malformed
reset interval, BIO ambiguity, or post-reset execution of the initializer is a
fixture failure, not a register result.

Until such captures exist, `OQ-012` remains open. The EVM evidence is
**CORROBORATED** workflow evidence, while the portable core's unlisted-state
retention remains **PROVISIONAL** original-silicon behavior.
