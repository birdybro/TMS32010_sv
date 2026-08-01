# PUSH/POP program-bus experiment

## Purpose and claim boundary

This experiment is intended to resolve `OQ-016`: the exact address and
`MEN` sequence during the two execution cycles of the original NMOS
TMS32010 `PUSH` and `POP` instructions. It is not needed to verify their
already documented stack transformations or two-cycle totals.

The production primary sources impose four useful constraints:

1. `PUSH` and `POP` are each one word and two cycles
   [ti-tms32010-users-guide-spru001b, `POP`/`PUSH`, printed pp. 3-49–3-50
   (PDF pp. 99–100); ti-first-generation-users-guide-1987, `POP`/`PUSH`,
   printed pp. 4-55–4-56 (PDF pp. 136–137)].
2. Their execution descriptions include `(PC) + 1 -> PC`, as do ordinary
   instruction descriptions in the same guide
   [ti-first-generation-users-guide-1987, §4.3 and `POP`/`PUSH`, printed
   pp. 4-11–4-13 and 4-55–4-56 (PDF pp. 92–94 and 136–137)].
3. Program memory is always addressed by the PC, which contains the next
   instruction to execute and is incremented in preparation for the next
   prefetch
   [ti-first-generation-users-guide-1987, §3.6.1 and Figure 3-12, printed
   pp. 3-22–3-23 (PDF pp. 51–52)].
4. `MEN` is active low on every machine cycle except a cycle in which `WE`
   or `DEN` is active. Neither exception is part of PUSH or POP
   [ti-tms32010-users-guide-spru001b, Table 2-4, printed p. 2-21
   (PDF p. 45)].

A contemporary TI patent for a closely related DSP embodiment independently
uses the same every-state external-program-read rule, but its Table A omits
the production accumulator PUSH/POP opcodes. Its push/pop clocks only describe
subroutine CALL/RET stack control. It reinforces constraint 4 but supplies no
PUSH/POP address or word-validity evidence
[ti-dsp-microcomputer-patent-us4577282a, patent cols. 5-6 and 31-36 (PDF
pp. 29 and 42-44)].

TI's original-device EVM supplies an additional address-level clue. Its
monitor rejects a breakpoint at the word immediately after PUSH or POP, while
§9.3 says a 4K-by-1 breakpoint RAM is indexed directly from the TMS32010
program-address bus and substitutes NOP data when the address matches. This
corroborates external visibility of `N+1` in the multicycle context, but the
breakpoint logic is address-driven and the manual gives no `MEN` phase,
repeat count, or later address
[ti-tms32010-evm-users-guide-spru005a, SB note 7, printed p. 3-58 (PDF
p. 99), and §9.3, printed pp. 9-2 through 9-3 (PDF pp. 179-180)]. See
`docs/research/evm_breakpoint_evidence.md`.

These facts make a completely inactive extra cycle inconsistent with the
general pin contract. They do not establish which active-low `MEN` sample is
accepted by the instruction pipeline, or whether the program address repeats.
No exact bus sequence is implemented from this document alone.

## Competing hypotheses

Measure rather than merge the following externally distinguishable cases.
Here `N` is the PUSH or POP opcode address and `N+1` is the following
instruction.

| Hypothesis | First execution interval | Second execution interval | Present evidence |
|---|---|---|---|
| H1: inactive internal interval | `MEN` high; address unspecified or held | `MEN` low at `N+1`; word accepted | Independent IKA32010 behaves this way, but it conflicts with the production guide and related TI patent's every-cycle read rule. |
| H2: repeated prefetch | `MEN` low at `N+1`; word discarded | `MEN` low again at `N+1`; word accepted | Reconciles the production pin rule with the secondary implementation's PC hold, but neither TI source contains these accumulator opcodes in a control waveform. |
| H3: advancing prefetch | `MEN` low at `N+1` | `MEN` low at another PC value, such as `N+2` | Compatible with full fetch/execute overlap in the abstract; exact PC ownership and word validity are not documented for PUSH/POP. |

At pinned commit `51bc1f05a2a08a61c8815a9643d08a42e99779c6`, IKA32010
holds PC and requests `BUSCTRL_STOP` during its first PUSH/POP microcycle,
then requests an opcode read during its second. This is a useful independent
hypothesis, not original-device proof
[ika32010-rtl-51bc1f0, PUSH/POP control, lines 690–731].

## Synthetic probe program

Use [push_pop_bus_probe.asm](../../tests/asm/push_pop_bus_probe.asm). The
project assembler must produce this stable image:

| Address | Word | Source |
|---:|---:|---|
| `0x000` | `0x7e55` | `LACK 0x55` |
| `0x001` | `0x7f9c` | `PUSH` |
| `0x002` | `0x7f80` | `NOP` |
| `0x003` | `0x7eaa` | `LACK 0xaa` |
| `0x004` | `0x7f9d` | `POP` |
| `0x005` | `0x7f80` | `NOP` |
| `0x006` | `0xf900` | `B hold` |
| `0x007` | `0x0006` | branch target |

The distinct neighboring words make address, data, and repeated-read
patterns visible without copyrighted program material. The first LACK makes
the stack round trip deterministic; the terminal self-branch prevents
execution from escaping the fixture.

Assemble it with:

```sh
python3 -m tools.assembler.tms32010_as \
  tests/asm/push_pop_bus_probe.asm \
  --hex build/push_pop_bus_probe.hex \
  --listing build/push_pop_bus_probe.lst
```

SPRU005A documents a contemporary TMS32010 EVM register and memory
display/modify workflow that may be used to load and inspect a synthetic
program. It does not document the missing pin trace
[ti-tms32010-evm-users-guide-spru005a, §3.3.2, printed pp. 3-4–3-5 and
command pp. 3-53–3-54].

## Capture procedure

Use only an original NMOS device whose complete package marking and board
revision are recorded. A TMS320C10, TMS320C15, or compatible FPGA core is not
a substitute for this experiment.

1. Record device markings, oscillator frequency, supply voltage, program
   memory type/access time, probe model, analyzer model, firmware, and the
   SHA-256 of the exact program image.
2. Probe `CLKOUT`, active-low `MEN`, `WE`, `DEN`, `RS`, `A11:A0`, and
   `D15:D0`. Use high-impedance probes and board-safe grounding; a trained
   operator must assess loading before attaching equipment.
3. Trigger on the address/data combination for `PUSH` at `0x001`, retaining
   at least two ordinary fetches before it and four intervals after it.
   Repeat for `POP` at `0x004`.
4. Sample substantially faster than `CLKOUT` and retain both raw transitions
   and values at every falling `CLKOUT` boundary. Do not reconstruct missing
   address bits from the known program.
5. Capture at least 32 reset-to-loop repetitions. Report any disagreement
   rather than selecting the majority silently.
6. Confirm `WE` and `DEN` remain inactive throughout both PUSH/POP intervals.
   A violation is a source conflict, not permission to reinterpret `MEN`.
7. Save raw analyzer data, a signal-name/pin map, photographs of probe
   placement, and a short decoding script. Hash every artifact before any
   conversion.

## Acceptance and interpretation

`OQ-016` can advance to `VERIFIED_HARDWARE` only if captures from an original
TMS32010 identify, for both instructions:

- the address present during every execution interval;
- `MEN`, `WE`, and `DEN` polarity and transition ordering;
- the sampled program data word at every falling boundary;
- which read becomes the following executed instruction, demonstrated by the
  stable terminal control flow;
- repeatability across all retained runs.

One device is sufficient to establish a reproducible observed behavior, but
not mask-revision invariance. Conflicting original devices must be recorded
under `OQ-008`. Until such evidence or an authoritative TI waveform is
available, H1–H3 remain research hypotheses and PUSH/POP remain outside the
native/RTL timing claim.
