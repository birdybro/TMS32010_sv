# Pipeline and instruction overlap

## Established behavior

The TMS32010 overlaps instruction fetch with execution of the previously
fetched instruction. TI describes most instructions as one word and one
cycle, with branch, I/O, stack, and table operations consuming additional
cycles [ti-tms32010-users-guide-spru001b, §2.1 and Table 3-2, printed
pp. 2-1, 3-5–3-7 (PDF pp. 25, 55–57)]. **Confidence: VERIFIED_PRIMARY.**

A machine cycle is one `CLKOUT` period and four input-clock periods. The
baseline 20 MHz input therefore corresponds to a nominal 5 MHz machine-cycle
rate. Speed-grade limits and electrical edge requirements belong in wrapper
constraints, not synthesizable delay statements
[ti-tms32010-users-guide-spru001b, Appendix A data sheet, clock characteristics
and AC timing tables]. **Confidence: VERIFIED_PRIMARY.**

## Required implementation model

The portable RTL will use one FPGA clock and explicit phase/state enables. It
will not generate clocks in logic. A future internal FPGA clock may be faster
than the emulated crystal input only if:

1. each documented processor phase is explicit;
2. native bus outputs change on the documented boundaries;
3. instruction-cycle counts are measured in architectural machine cycles;
4. interrupt and BIO sampling boundaries remain observable.

This is an implementation policy, not a claim about the original internal
gate topology.

## Unresolved sequences

Normal read, table, I/O, and reset pin sequences are transcribed in
`docs/timing/native_phase_contract.md`. Exact pipeline ownership remains to be
resolved for:

- B, BANZ, BIOZ, BV, CALL, and the six accumulator-tested conditions are now
  qualified;
- IN and OUT are now qualified as one opcode-read cycle followed by one
  mutually exclusive DEN or WE I/O cycle;
- TBLR and TBLW are now qualified as opcode read, discarded PC+1 read, and
  ACC-addressed table transfer, followed by a repeated PC+1 read;
- CALA and RET have model-qualified state/cycle behavior but externally
  unresolved second cycles, as do the second cycles of model-qualified
  `PUSH`/`POP` (`OQ-007`, `OQ-016`);
- complete implementation of the now-transcribed interrupt fetch/execute
  overlap and request ownership within native subphases (`OQ-004`); all 32
  represented machine-cycle arrival points across the 15 currently supported
  multicycle core families are directed-tested;
- any external cycle stretching (`OQ-001`).

Until these rows have cited diagrams and automated traces, the project does
not claim cycle accuracy.

## Interrupt pipeline sequence

SPRU001B Figure 2-12 supplies the missing normal-entry sequence. An interrupt
that becomes active during fetch N does not discard N or N+1. The fetch row is
N, N+1, dummy N+2, vector 2; the aligned execute row is N, N+1, dummy, vector
2. The current return PC is therefore N+2, and the dummy-fetched word resumes
after the handler returns
[ti-tms32010-users-guide-spru001b, §2.10 and Figure 2-12, printed p. 2-19
(PDF p. 43)]. **Confidence: VERIFIED_PRIMARY.**

The partial phase wrapper now verifies the external program sequence and
architectural entry state. Its implementation state allows one more
instruction retirement, performs a non-retiring program read at the return
PC, then selects vector 2. A focused model/RTL differential compares PC,
ACC, stack top, INTM, pending flag, cycle total, and retirement for EINT,
the protected instruction, entry, and vector word.

The wrapper still executes each supported fetched word at its sample boundary;
it does not yet contain separate general fetch and execute registers. Thus the
address sequence is qualified, while the complete overlapped execution row is
still an implementation requirement rather than a cycle-accuracy claim.
`OQ-004` retains that distinction. A separate 32-case core matrix exhausts
arrival at every represented machine cycle of the 11 supported two-word
control-flow families, IN, OUT, TBLR, and TBLW; it does not convert the
collapsed fetch-sample implementation into a physical subphase or
fetch/execute-overlap claim.

`BANZ` now supplies the first qualified two-word control-flow sequence. Cycle
1 reads exact opcode `0xf400` at PC. Cycle 2 reads the following target word
at PC+1 regardless of the condition. At the second falling-edge sample, the
old selected `AR[8:0]` chooses the next address (target when nonzero, PC+2
when zero), then that nine-bit counter decrements modulo 512. Each read uses
the normal four-subphase `MEN` sequence; clock-enable stalls hold the active
phase, address, pending operand state, PC, and AR
[ti-tms32010-users-guide-spru001b, §§2.1.1, 2.4.1, and 2.6.1, Table 3-2,
and `BANZ`, printed pp. 2-2, 2-9–2-10, 2-13, 3-6, and 3-16
(PDF pp. 26, 33–34, 37, 56, and 66)]. **Confidence: VERIFIED_PRIMARY for
logical ordering and normal-read pin phases.**

Unconditional `B` reuses the same verified two-read shape without a counter
condition. Cycle 1 reads exact opcode `0xf900` at PC; cycle 2 reads the
canonical target at PC+1; at the second falling-edge sample PC receives the
target and the instruction retires. Both reads use normal program phases, and
a clock-enable stall holds the second phase without architectural progress
[ti-tms32010-users-guide-spru001b, Table 3-2 and `B`, printed pp. 3-6 and
3-15 (PDF pp. 56 and 65)]. **Confidence: VERIFIED_PRIMARY for logical
ordering and normal-read pin phases.**

`BGEZ`, `BGZ`, `BLEZ`, `BLZ`, `BNZ`, and `BZ` use that same two-read shape.
At the second sample, a signed/zero test of the unchanged 32-bit ACC selects
the canonical target or PC+2. Both outcomes retire after the second read;
clock-enable stalls hold the target phase and condition inputs. Pinned MAME's
one-cycle untaken abstraction is disclosed in `SC-013`, not adopted
[ti-tms32010-users-guide-spru001b, Table 3-2 and individual branch pages,
printed pp. 3-6, 3-17–3-18, 3-20–3-22, and 3-24
(PDF pp. 56, 67–68, 70–72, and 74)]. **Confidence: VERIFIED_PRIMARY.**

`BV` uses the same two-read shape and tests unchanged sticky OV at the second
sample. OV set selects the canonical target and clears OV at retirement; OV
clear selects PC+2 and remains clear. Both paths consume the second read, and
a clock-enable stall holds PC, OV, and the target phase. MAME's shorter
untaken abstraction is disclosed in `SC-014`
[ti-tms32010-users-guide-spru001b, Table 3-2 and `BV`, printed pp. 3-6 and
3-23 (PDF pp. 56 and 73)]. **Confidence: VERIFIED_PRIMARY.**

`BIOZ` also uses the same two-read shape, but its predicate is the raw
external active-low BIO level. TI says BIO is sampled every machine cycle and
is not latched, and the AC table places its setup boundary before falling
`CLKOUT`. The level at the second, target-word sample therefore selects the
target or PC+2. Directed tests change BIO between the opcode and target
samples in both directions, require two cycles in both outcomes, and preserve
the active target phase across a clock-enable stall. MAME's shorter untaken
abstraction is disclosed in `SC-015`
[ti-tms32010-users-guide-spru001b, §§2.9 and 2.6.1, Table 3-2, `BIOZ`, and
Appendix A BIO timing, printed pp. 2-13, 2-18, 3-6, 3-19, and data-sheet 20
(PDF pp. 37, 42, 56, 69, and 376)]. **Confidence: VERIFIED_PRIMARY.**

`CALL` uses the same two normal program reads, then commits two architectural
effects at the target-word sample: opcode-PC+2 is pushed onto the four-level
stack and the canonical target becomes PC. Directed tests prove no early push
at the opcode sample, preserve stack/PC during an active target-phase stall,
and check old-bottom discard and 12-bit return-address wrap
[ti-tms32010-users-guide-spru001b, §§2.6.1–2.6.2, Table 3-2, and `CALL`,
printed pp. 2-13–2-14, 3-6, and 3-26
(PDF pp. 37–38, 56, and 76)]. **Confidence: VERIFIED_PRIMARY for instruction
effects and two-read sequence; implementation commit ownership is qualified
at the architectural falling-edge boundary only.**

`IN` and `OUT` are one-word instructions whose two documented cycles have
different bus ownership. Cycle 1 performs the ordinary MEN opcode read. Cycle
2 suppresses MEN, drives the three-bit port on A2–A0 with A11–A3 low, and
asserts DEN for IN or WE for OUT. At the second falling `CLKOUT` sample, IN
writes the live external word to the pre-update internal-RAM address; OUT has
held the selected internal-RAM word on the external data bus and completes the
write. The common indirect AR/ARP update and instruction retirement also
occur at that boundary. Directed phase tests require MEN, DEN, and WE to be
mutually exclusive and hold address, control, data, PC, and pending state
through a disabled clock-enable phase
[ti-tms32010-users-guide-spru001b, Table 3-2, `IN`/`OUT`, and Appendix A I/O
timing, printed pp. 3-6, 3-30, and 3-47 plus data-sheet pp. 17–18
(PDF pp. 56, 80, 97, and 373–374)]. **Confidence: VERIFIED_PRIMARY for
logical ordering and native pin phases; analog delays are wrapper
constraints.**

`TBLR` and `TBLW` use a distinct three-cycle pending state. Cycle 1 samples
the opcode, advances architectural PC to PC+1, and captures `ACC[11:0]` plus
the old resolved internal-data address. Cycle 2 performs a complete normal
`MEN` read at PC+1 but discards its input. Cycle 3 drives the captured
accumulator address and either reads under `MEN` into RAM or writes the
selected RAM word under `WE`. Only the table sample applies indirect AR/ARP
updates, the documented final stack-bottom duplication, and retirement. The
next normal read repeats PC+1; stalls hold each pending phase without
architectural progress
[ti-tms32010-users-guide-spru001b, §2.8.2, Figure 2-10, and
`TBLR`/`TBLW`, printed pp. 2-17 and 3-64–3-67
(PDF pp. 41 and 114–117)]. **Confidence: VERIFIED_PRIMARY for logical
ordering and native pin ownership.**

`SUBC` is documented as one cycle, but TI explicitly prohibits the immediately
following instruction from using ACC. This exposes a result-availability
constraint that the current instruction-boundary core cannot physically
characterize. Qualified programs insert an ACC-free NOP after every SUBC;
the core's immediate result commit is an implementation convenience, not a
claim about a violating instruction sequence. The missing silicon behavior is
tracked as `OQ-017`
[ti-tms32010-users-guide-spru001b, `SUBC`, printed p. 3-61 (PDF p. 111)].
**Confidence: VERIFIED_PRIMARY for the scheduling restriction; UNKNOWN for
violation behavior.**

`PUSH` and `POP` are primary-defined one-word, two-cycle instructions. Their
architectural stack transformations and numeric cycle totals are now
model/tool-qualified, but the located original documentation contains no
dedicated external-bus waveform for their second cycle. Do not implement an
RTL/native extra cycle by merely refetching the same opcode or by assuming a
next-word prefetch: both would create an unsupported external sequence. This
is tracked as `OQ-016`
[ti-tms32010-users-guide-spru001b, Table 3-2 and `POP`/`PUSH`, printed
pp. 3-7 and 3-49–3-50 (PDF pp. 57 and 99–100)].
