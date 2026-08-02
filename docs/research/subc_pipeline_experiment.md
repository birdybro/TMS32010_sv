# Original-TMS32010 SUBC pipeline experiments

## Purpose and claim boundary

These experiments target two distinct uncertainties:

- `OQ-017`: what accumulator value, if any, a successor observes when it
  violates TI's rule that the instruction after `SUBC` cannot use ACC;
- `OQ-018`: whether sticky `OV` is driven by overflow of the intermediate
  subtraction, the final one-bit quotient shift, either stage, or both.

The original production guides define `SUBC` as one word and one cycle. They
first compute `trial = ACC - (unsigned_word << 15)`, then select either
`(trial << 1) + 1` when trial is nonnegative or `old_ACC << 1` otherwise. Both
guides explicitly prohibit the next instruction from using ACC, but neither
defines a violating sequence or the internal overflow source
[ti-tms32010-users-guide-spru001b, `SUBC`, printed p. 3-61 (PDF p. 111);
ti-tms32010-assembly-guide-spru002b, `SUBC` and Section 4.6, printed pp. 3-61
and 4-5-4-7 (PDF pp. 82 and 98-100)].

The later first-generation guide says SUBC affects sticky `OV`, ignores `OVM`,
and never saturates, but still does not identify the stage
[ti-first-generation-users-guide-1987, `SUBC`, printed pp. 4-67-4-68
(PDF pp. 148-149)]. Thus the legal final ACC transform, one-cycle program
count, scheduling restriction, and no-saturation rule are documented. Exact
subphase ownership and out-of-contract behavior are not.

## Related patent evidence

US4577282A describes a closely related contemporary TI accumulator circuit:

- the unshifted SUBC ALU output reaches the accumulator input at Q4;
- it passes the first accumulator stage at Q1 and recirculates at Q2;
- an accumulator-local transistor path performs the one-bit shift at Q3 of
  the following state and conditionally inserts the quotient bit;
- the prose assumes the following state is a non-ALU instruction or NOP;
- the status overflow input is derived from the ALU output/carry path, while
  the later shift is drawn in the accumulator rather than the ALU
  [ti-dsp-microcomputer-patent-us4577282a, patent cols. 21-24 (PDF pp. 37-38),
  Figure 5c].

This directly explains why a successor cannot safely consume ACC and supports
intermediate-subtraction overflow as a microarchitectural hypothesis. It is
not original-TMS32010 production proof. The patent also calls SUBC a two-state
instruction while the production manuals count it as one cycle, apparently
counting the overlapped following-state work differently
[same source, patent cols. 13-14 (PDF p. 33)]. The repository therefore does
not silently convert its Q3 description into a production pin or violating-
sequence claim.

## Independent implementation conflicts

- Pinned MAME computes and commits the final result within one handler. Its
  overflow expression appears intended to test the intermediate subtraction,
  but compares the old accumulator against an accumulator value that has not
  changed and therefore cannot set `OV`
  [mame-tms320c1x-core-030fefc, `subc()`, lines 732-742]. It supplies neither a
  valid flag oracle nor subcycle visibility.
- Pinned IKA32010 records the first adder value, loads the final ACC one FPGA
  cycle later through `prev_subc`, and updates its V flag from that later
  shifted/add result. It therefore represents the final-stage hypothesis, in
  conflict with the related patent's ALU-derived status path
  [ika32010-rtl-51bc1f0, `IKA32010.sv`, lines 965-981 and 1793-1906].

The current project model and RTL commit the final ACC at the SUBC retirement
boundary and set sticky `OV` only for intermediate signed-subtraction
overflow. Tests always insert an ACC-free successor for claimed behavior.
That is a reversible implementation policy: it does not resolve either
physical question.

## Contemporary TI simulator diagnostic

TI's 1982 software-simulator guide documents stop code `9950` for use of the
accumulator in the first clock cycle after `SUBC`
[ti-tms32010-simulator-users-guide-1982, Appendix A, printed p. 47
(PDF p. 49)]. That is primary evidence that contemporary TI reference software
actively rejected the prohibited dependency. It corroborates the legal-stream
scheduling rule, but it is a tool diagnostic rather than physical-device
behavior: it reveals neither the value a violating successor would sample nor
the accumulator's production-silicon subphase. `OQ-017` therefore remains
open.

## Dependency probe (`OQ-017`)

[subc_dependency_probe.asm](../../tests/asm/subc_dependency_probe.asm)
constructs this initial state entirely in documented data RAM:

```text
ACC     = 0x00020005
divisor = 0x0003
trial   = 0x00008005
final   = 0x0001000b
```

The first sequence deliberately executes `SACL 3` immediately after SUBC.
The second reconstructs the same inputs, inserts the required NOP, and stores
the legal final value with `SACL 4`. It then exports both low words on port 7.

| Observed first port word | Candidate interpretation |
|---:|---|
| `0x0005` | successor sampled old ACC |
| `0x8005` | successor sampled unshifted trial/intermediate |
| `0x000b` | successor sampled final shifted result |
| other or unstable | control contention, different internal ordering, or history dependence |

The second port word must be `0x000b` before the capture is considered valid.
The first word intentionally has no repository expected result.

## Overflow-stage probe (`OQ-018`)

[subc_overflow_stage_probe.asm](../../tests/asm/subc_overflow_stage_probe.asm)
uses legal NOP successors and stores status after two separated cases:

| Case | Initial ACC | Divisor | Overflow distinction |
|---|---:|---:|---|
| intermediate-only | `0x80000000` | `0xffff` | signed trial subtraction overflows; final shift does not |
| final-shift-only | `0x40000000` | `0x0000` | trial does not overflow; final left shift crosses the signed boundary |

`SOVM` is set before both cases. Each SUBC must still produce its wrapped,
unsaturated result because TI explicitly says OVM is ignored. An intervening
`LST` of a zero status word clears OV/OVM before the second `SOVM`. `SST 0`
and `SST 1` store the two results at page-one words `0x80` and `0x81`; port-7
OUT writes export them. Interpret only status bit 12 (`OV`):

| First OV | Second OV | Candidate stage policy |
|---:|---:|---|
| 1 | 0 | intermediate subtraction only (current project hypothesis) |
| 0 | 1 | final quotient shift only (IKA hypothesis) |
| 1 | 1 | either stage sets sticky OV |
| 0 | 0 | neither vector sets OV, or another undocumented qualification applies |

All other SST fields are retained as consistency checks, not recast as SUBC
evidence.

## Build and capture procedure

Assemble either fixture with the project-local assembler, for example:

```sh
python3 -m tools.assembler.tms32010_as \
  tests/asm/subc_dependency_probe.asm \
  --hex build/subc_dependency_probe.hex \
  --listing build/subc_dependency_probe.lst
```

Repository tests lock every emitted word and symbol location. Hash the exact
hex and listing used for a capture.

Use an original NMOS TMS32010, not a CMOS variant or compatible model:

1. Record complete package marking, board/EVM and monitor revisions, clock,
   voltage, program-memory type, analyzer/probe models, and fixture hashes.
2. Probe `CLKOUT`, active-low `MEN`, `WE`, `DEN`, `RS`, `A11:A0`, and
   `D15:D0`. Decode port-7 writes from the physical strobes and address pins.
3. Trigger before the selected SUBC and retain the complete program through
   the terminal loop. Sample faster than CLKOUT and retain raw transitions at
   every falling boundary.
4. For the dependency probe, capture the violating and legal SACL writes as
   well as both later port exports. For the overflow probe, retain the status
   exports and use EVM register display only as a corroborating check.
5. Run at least 32 resets per fixture. Repeat dependency captures with several
   input patterns whose old, trial, and final halves are all distinct. Record
   every varying result.
6. Save raw analyzer data, decoded CSV, monitor transcript, pin map,
   photographs, and tool versions; hash every artifact before conversion.

## Acceptance and interpretation

`OQ-017` may advance to `VERIFIED_HARDWARE` for the tested device only if the
legal comparator is correct and the violating successor's sampled word and
phase are repeatable. A deterministic violation result remains out of the
documented programming contract; it must not make such code supported.

`OQ-018` may advance when the two isolated status vectors repeat and the
wrapped ACC results show that OVM was ignored. Conflicting device markings
reopen mask-revision question `OQ-008`.

Until production documentation or qualified original-device captures exist,
the patent timing remains **CORROBORATED RELATED-EMBODIMENT** evidence, the
intermediate-only OV stage remains **PROVISIONAL**, and the current same-
boundary final-ACC commit remains an implementation convenience for legal
instruction streams.
