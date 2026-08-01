# Original-TMS32010 indirect-LST ARP-precedence experiment

## Question and current claim boundary

This experiment targets `OQ-015`: when indirect `LST` both restores `ARP`
from data-word bit 8 and explicitly encodes a different next `ARP`, which
value controls the following instruction?

The repository currently gives the memory word final precedence. That is a
reversible **PROVISIONAL** policy, not an original-silicon result.

## Contradictory original-part evidence

The ordinary indirect-addressing contract says that when instruction bit 3 is
zero, instruction bit 0 is loaded into `ARP` after the current instruction.
It does not state an LST exception
[ti-tms32010-users-guide-spru001b, Section 3.3.2, printed pp. 3-1-3-2
(PDF pp. 51-52); ti-tms32010-assembly-guide-spru002b, Section 3.3.2,
printed pp. 3-1-3-2 (PDF pp. 22-23)].

Each original LST page simultaneously says that the data-memory word restores
the saved status bits, including `ARP` from bit 8. Its worked sequence is:

```text
LARP 0
LST  *,1
```

The accompanying result says the word addressed through AR0 replaces the
status bits and that `ARP` becomes one. The example supplies no memory value,
so it does not say whether bit 8 was also one. Read literally as a demonstration
of the operand, it supports encoded-field precedence; read as a status-restore
example with an omitted bit-8 value, it is compatible with memory precedence.
The operation diagram and example therefore do not establish a unique result
[ti-tms32010-users-guide-spru001b, `LST`, printed p. 3-38 (PDF p. 88);
ti-tms32010-assembly-guide-spru002b, `LST`, printed p. 3-38 (PDF p. 59)].
In short, the status-restore prose and example admit opposing readings.

The later first-generation guide retains both the optional `next ARP` syntax
and the same “ARP becomes 1” example while saying the addressed word loads the
status register. It does not add a priority rule
[ti-first-generation-users-guide-1987, `LST`, printed p. 4-43
(PDF p. 124)]. This is an internal primary-document ambiguity, not merely
silence about a theoretical illegal combination: the assembler syntax
expressly permits the conflicting form.

## Later variant and implementation hypotheses

- The preliminary TMS320C25 guide explicitly says an indirect LST ignores the
  encoded next-ARP value and loads ARP from the addressed word. Its worked
  example calls out that exception. This is direct evidence for a later
  variant, not proof of the original NMOS device
  [ti-tms320c25-users-guide-spru012-1986, `LST` and Example 1, printed
  p. 4-75 (PDF p. 170)].
- Pinned MAME forces the preserve-ARP control before its common address helper
  and then loads the status word, representing **memory-word precedence**. Its
  shared C1x implementation does not supply original-device provenance for
  that choice
  [mame-tms320c1x-core-030fefc, `tms320c1x_device_base::lst`, lines 594-604].
- Pinned IKA32010 applies instruction bit 0 to ARP for indirect LST and uses
  data bit 8 only for direct LST, representing **encoded-field precedence**.
  It independently matches the literal original worked example but is not a
  production-silicon oracle
  [ika32010-rtl-51bc1f0, `IKA32010.sv`, lines 663-688].
- Contemporary TI patent US4577282A says its indirect control bit loads the
  encoded ARP after the current instruction, says the indirect explanation
  applies to its table generally, and separately describes LST as restoring
  status. It does not state same-instruction priority, and its disclosed
  embodiment differs from the production instruction set. It preserves the
  two hypotheses rather than resolving them
  [ti-dsp-microcomputer-patent-us4577282a, patent cols. 11-16
  (PDF pp. 32-34)].

## Stable synthetic fixture

[lst_arp_precedence_probe.asm](../../tests/asm/lst_arp_precedence_probe.asm)
contains only documented original-part instructions and no copyrighted data.
It initializes every internal-RAM word it consumes, emits armed marker
`0x0033`, and runs both disagreement directions.

Case A begins with `ARP=0`, `AR0=0x10`, and `AR1=0x12`. RAM word `0x10` has
status bit 8 clear; `LST *+,1` increments old AR0 to `0x11` while requesting
next ARP one. The following indirect OUT exports:

- `0x00a0` from RAM `0x11` if the memory word wins; or
- `0x00a1` from RAM `0x12` if the encoded field wins.

Case B begins with `ARP=1`, `AR1=0x20`, and `AR0=0x22`. RAM word `0x20` has
status bit 8 set; `LST *+,0` increments old AR1 to `0x21` while requesting
next ARP zero. The following indirect OUT exports:

- `0x00b1` from RAM `0x21` if the memory word wins; or
- `0x00b0` from RAM `0x22` if the encoded field wins.

Interpret the complete port-7 sequence:

| Export sequence | Candidate interpretation |
|---|---|
| `0033, 00a0, 00b1` | memory-word ARP wins in both directions |
| `0033, 00a1, 00b0` | encoded next ARP wins in both directions |
| mixed or other | direction-dependent behavior, fixture failure, or unexpected instruction behavior |

The repository assigns no passing expected sequence until qualified original
hardware is captured. The two cases must agree before either precedence rule
is accepted.

## Physical capture procedure

Use an original NMOS TMS32010, not a TMS320C10/C15, TMS32020/C25, or later
compatible device:

1. Record package marking, mask/date code, EVM or board and monitor revisions,
   oscillator, voltage, program-memory access time, and hashes of the exact
   hex/listing used.
2. Load the synthetic image into external program memory without modifying its
   words. Never execute a downloaded legacy binary to perform this step.
3. Decode port 7 writes or capture `WE`, `A11:A0`, and `D15:D0`. Retain the raw
   transition capture as well as decoded marker words; `MEN`, `DEN`, and
   `CLKOUT` should also be captured to demonstrate normal instruction flow.
4. Run at least 32 reset-and-execute trials at nominal clock. Repeat at the
   documented slow and fast limits if the memory fixture meets all access,
   setup, and hold requirements.
5. Save the analyzer setup, raw capture, decoded CSV, pin map, photographs,
   monitor transcript, and tool versions. Hash every artifact before format
   conversion.
6. Repeat on another original-part date/mask code before generalizing the
   outcome across `OQ-008`.

## Acceptance

A result can upgrade `OQ-015` only when every run begins with `0033`, produces
exactly one A marker and one B marker in order, reaches the terminal loop, and
the two directions select the same precedence hypothesis. A mixed result is a
new architectural observation, not permission to average or discard trials.

Until then, memory-word precedence remains **PROVISIONAL**, the original
worked example must be disclosed as competing primary evidence, and neither
MAME nor IKA may be cited as original-silicon proof.
