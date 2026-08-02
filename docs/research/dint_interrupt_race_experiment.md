# Original-TMS32010 DINT/interrupt-boundary experiment

## Question and current claim boundary

This experiment targets `OQ-019`: an interrupt becomes active soon enough to
place `DINT` in the original guide's already-fetched N+1 execution slot. Does
the DINT write cancel entry before acknowledge, or has the internal interrupt
processor already committed the vector branch?

The repository currently chooses cancellation: DINT retires, sets `INTM`,
leaves the request latched, and suppresses stack/vector effects. That is a
reversible **PROVISIONAL** policy, not a measured original-silicon result.

## Original production evidence

SPRU001B Figure 2-11 draws interrupt-active as the synchronized request gated
by the enabled output of the interrupt-mode register. DINT clocks that mode
register to its disabled state, while acknowledge also presets it and clears
the separate request flag. The prose says DINT does not clear the flag
[ti-tms32010-users-guide-spru001b, Section 2.10 and Figure 2-11, printed
p. 2-18 (PDF p. 42)].

The following printed page contains an internal polarity error: it says a set
INTM makes interrupt-active valid, although Figure 2-11 uses the enabled
complement and the same page says DINT sets INTM to disable interrupts. The
later guide correctly says active becomes valid when INTM is zero. This typo
cannot decide same-boundary priority and is retained in `SC-039`, not silently
quoted as architecture
[ti-tms32010-users-guide-spru001b, Section 2.10, printed p. 2-19 (PDF p. 43);
ti-first-generation-users-guide-1987, Section 3.8, printed p. 3-31 (PDF
p. 60)].

Figure 2-12 then shows the original TMS32010 fetch/execute sequence after a
request becomes active:

```text
fetch:    N        N+1       dummy N+2       vector 2
execute:           N         N+1             dummy       vector 2
```

Thus a DINT word already at N+1 is executed while N+2 is dummy-fetched. The
guide says acknowledge occurs when the interrupt service routine begins, but
does not state whether the DINT mode-register write or an already active
internal-processor decision wins at the shared N+1 boundary
[ti-tms32010-users-guide-spru001b, Section 2.10 and Figure 2-12, printed
pp. 2-18-2-19 (PDF pp. 42-43)]. The DINT instruction page only says that it
sets `INTM` and disables further maskable interrupts
[same source, `DINT`, printed p. 3-27 (PDF p. 77)].

The original assembly guide adds that a set mode bit inhibits the TMS32010
from responding and that an interrupt grant clears the flag and sets the mode
bit. It still does not locate grant relative to DINT retirement
[ti-tms32010-assembly-guide-spru002b, Appendix A.3.2, printed p. A-2
(PDF p. 184)]. **The mode gate supports cancellation, but the exact same-edge
priority remains INFERRED.**

## Later-family timing conflict

The 1987 first-generation guide says maskable interrupts are disabled
immediately after DINT executes. That wording supports cancellation only if
DINT actually reaches execution before grant
[ti-first-generation-users-guide-1987, `DINT`, printed p. 4-32 (PDF p. 113)].
Its general Figure 3-20, however, differs materially from the original-part
Figure 2-12:

```text
fetch:    N        dummy N+1       vector 2
execute:           N               dummy       vector 2
```

On that diagram a DINT at N+1 is not the protected executed word at all. The
same chapter says an asynchronous NMOS TMS32010 requires external
synchronizing flip-flops. That is not a conflict with the original guide:
SPRU001B draws an internal logical Sync FF in Figure 2-11 but separately
recommends an external CLKOUT-clocked flip-flop for asynchronous inputs in
Section 2.14. The portable core therefore must not claim that its digital
sampling boundary provides physical metastability conditioning
[ti-tms32010-users-guide-spru001b, Section 2.14 and Figure 2-17, printed
p. 2-24 (PDF p. 48); ti-first-generation-users-guide-1987, Section 3.8 and
Figures 3-19-3-20, printed pp. 3-31-3-34 (PDF pp. 60-63)]. The material
`SC-039` conflict is the executed-N+1 versus dummy-N+1 sequence; the external
NMOS synchronizer requirement is corroborated across both guides.

## Related and independent implementations

- US4577282A says DINT/EINT reset or set a latch that determines whether the
  related DSP responds to `INT-`, but supplies no normal-interrupt state
  sequence or same-boundary priority. It does not resolve this question
  [ti-dsp-microcomputer-patent-us4577282a, patent cols. 13-14 (PDF p. 33)].
- Pinned MAME checks a pending interrupt before fetching/executing its next
  instruction and has no explicit N/N+1 fetch overlap. If DINT has already
  executed, its mask blocks `Ext_IRQ`; if a request is pending first, MAME can
  service it before DINT is fetched. It cannot represent the exact Figure
  2-12 race and is not cancellation evidence
  [mame-tms320c1x-core-030fefc, `execute_run()`, `Ext_IRQ()`, and `dint()`,
  lines 514-517 and 982-1019].
- Pinned IKA32010 derives `int_rq` combinationally from the old mode bit. When
  it is already true during DINT execution, default control selects vector 2
  and pushes PC while DINT sets the mode bit at the same FPGA edge. It thus
  represents an **entry-wins** hypothesis, although its pipeline and bus
  behavior are independently known not to prove production timing
  [ika32010-rtl-51bc1f0, `IKA32010.sv`, lines 273-285, 349-376, 612-656].

## Stable synthetic fixture

[dint_interrupt_race_probe.asm](../../tests/asm/dint_interrupt_race_probe.asm)
contains only documented original-part instructions and no copyrighted ROM
data. It initializes three port-7 markers, executes `EINT` and its required
following NOP, emits `0x0033`, and then places:

```text
0x01a  NOP       ARM_WINDOW (instruction N)
0x01b  DINT      RACING_DINT (instruction N+1)
0x01c  OUT 1,7   RESUME_N_PLUS_2
```

The interrupt handler temporarily pops the stacked PC, stores it in RAM,
pushes it back, exports that word, exports entry marker `0x0011`, and executes
the documented `EINT; RET` sequence. POP/PUSH architectural state is
primary-defined, but their extra program-bus ownership remains independently
open under `OQ-016`; those handler intervals must not be reused as PUSH/POP
bus proof.

Interpret the complete port-7 sequence:

| Export sequence | Candidate interpretation |
|---|---|
| `0033, 0022` | DINT executed and canceled entry; request remains masked |
| `0033, 001c, 0011, 0022` | entry won with original Figure 2-12 return PC N+2 |
| `0033, 001b, 0011, 0022` | entry occurred before DINT execution; N+1 was stacked/refetched |
| any other sequence | different recognition, pulse qualification, repeated level, or fixture failure |

The repository assigns no passing expected sequence until qualified original
hardware is captured.

## Physical capture procedure

Use an original NMOS TMS32010, not a TMS320C10/C15 or later compatible part:

1. Record the exact multiline package marking, raw tracking/date and lot
   strings without decoding them, stable local specimen ID, package/custody/
   socket/temperature/reset context, EVM/board and monitor revisions,
   oscillator, voltage, program-memory access time, interrupt-driver circuit,
   analyzer/probe models, and fixture tool versions.
2. Drive `INT` from a clocked, open-collector-compatible fixture. Do not drive
   it directly from an analyzer pod or FPGA pin without verified voltage and
   current compatibility.
3. After observing the `0x0033` port-7 write, issue exactly one active-low
   pulse during the fetch of address `0x01a`. Meet SPRU001B's minimum pulse
   and 50 ns setup before falling `CLKOUT`; record the actual margin. Calibrate
   with a no-pulse run and pulses one fetch earlier/later.
4. Capture `CLKOUT`, `INT`, `MEN`, `WE`, `DEN`, `A11:A0`, and `D15:D0` from
   before address `0x019` through the terminal loop. Retain raw transitions,
   not only decoded bus words.
5. Run at least 32 resets at the nominal clock, then repeat at documented slow
   and fast clock limits if the memory/driver fixture meets timing. A held-low
   run is a separate level-sensitive experiment and must not be mixed with
   the one-pulse result.
6. Save analyzer setup, raw capture, decoded CSV, pin map, probe-placement
   photographs, distinct specimen top/bottom/board-context photographs,
   monitor transcript, and exact project source/image/listing. Hash the
   normalized trace and every retained artifact.

Normalize a derived copy to one row per falling `CLKOUT` with the exact DINT
schema in `tools/trace/README.md`. Separately derive one assertion time,
release time, and 10%-to-90% fall time per run. The normalizer must reject a
run containing additional INT transitions rather than omitting them. Retain
the raw transitions as the authoritative measurement.

Assemble an exact sparse big-endian binary and validate the capture package:

```sh
python3 -m tools.assembler.tms32010_as \
  tests/asm/dint_interrupt_race_probe.asm \
  --binary dint_interrupt_race_probe.bin --byteorder big

python3 -m tools.trace.dint_interrupt_capture normalized.csv \
  --pulse-measurements pulse-measurements.csv \
  --metadata metadata.json \
  --program-image dint_interrupt_race_probe.bin \
  --artifact-root capture-artifacts \
  --require-review-ready
```

The classifier recomputes setup, low width, local `CLKOUT` period, and the
15 ns maximum falling-edge time; checks sampled INT against the transition
interval; validates the exact ARM/DINT fetch anchors and port-7 flow; requires
32 consistent runs and no-pulse/one-fetch-early/one-fetch-late calibration
hashes; and independently compares the program binary with its checked sparse
word map. The shared `OQ-008` validator additionally rejects substitute
rehashed source/listing content and binds the decoded capture to a complete
record for one named specimen; it does not replace pulse or calibration
qualification. An unanticipated sequence is retained verbatim but cannot
become a known resolved candidate. `review_ready` is evidence-package status
only, `acceptance_complete` remains false, and neither changes `OQ-019`
without review of raw waveforms, thresholds, loading, and board/device
provenance.

## Acceptance

A result can upgrade `OQ-019` only when the armed marker, pulse width/setup,
address alignment, stacked-PC export (when present), and terminal flow are all
consistent. Repeated results apply only to the recorded device marking until
mask-revision evidence addresses `OQ-008`. If the port order varies with small
phase movement despite meeting published setup, record a metastability or
undocumented recognition window rather than choosing the majority outcome.

Until then, current DINT cancellation remains **PROVISIONAL** and MAME must
not be cited as a same-boundary oracle. Another identified original-NMOS
specimen remains necessary before any cross-specimen claim.
