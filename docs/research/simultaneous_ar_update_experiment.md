# Original-TMS32010 simultaneous auxiliary-register update experiment

## Question and current claim boundary

This experiment targets `OQ-010`: what does an original NMOS TMS32010 do
when an indirect-address control field has both `INC` (bit 5) and `DEC`
(bit 4) set?

The project decoder rejects every such word before architectural effects. That
is a fail-closed implementation policy, not a claim that physical silicon
traps, stalls, preserves the register, or gives either command priority.

## TI documentation boundary

The original user and assembly guides define bit 5 as a post-execution
increment and bit 4 as a post-execution decrement. They define the zero/zero
case, reserve bits 6, 2, and 1, and expose only `*`, `*+`, and `*-` assembler
forms. They neither call `INC=DEC=1` reserved nor state its result
[ti-tms32010-users-guide-spru001b, Section 3.3.2, printed p. 3-2
(PDF p. 52); ti-tms32010-assembly-guide-spru002b, Section 3.3.2, printed
p. 3-2 (PDF p. 23)].

A later TI TMS320C1x programmer's reference card says `INC` and `DEC` cannot
both be one. This establishes that the combination is not a supported
first-generation-family source form, but its C1x scope and lack of execution
semantics do not prove the result on an original NMOS TMS32010
[ti-first-generation-users-guide-1987, TMS320C1x Programmer's Reference
Card, unnumbered card page (PDF p. 402)].

## Related control evidence and independent hypotheses

- Contemporary TI patent US4577282A describes separate increment and
  decrement controls on a related bidirectional counter. Its prose says the
  decrement path is used “instead of” increment and never defines both
  commands active. Inferring a Boolean priority or electrically stable result
  from that circuit would exceed the patent's claim boundary
  [ti-dsp-microcomputer-patent-us4577282a, patent cols. 27-28
  (PDF p. 40)].
- Pinned MAME accepts the forced word through its high-byte instruction
  handler, increments a temporary value, then decrements it, and writes the
  low nine bits back. It therefore produces **no net update**. Its
  disassembler renders the simultaneous mode as `??`, disclosing that it is
  not a normal source form
  [mame-tms320c1x-core-030fefc, `UPDATE_AR`, lines 240-248;
  mame-tms320c1x-disassembler-030fefc, indirect-mode table, lines 33-34].
- Pinned IKA32010 forwards both instruction bits to a four-way register
  update case and explicitly preserves the auxiliary register for `2'b11`.
  It independently produces **no net update**, but does not provide physical
  original-device provenance
  [ika32010-rtl-51bc1f0, `IKA32010.sv`, lines 290-328 and representative
  control at lines 663-675].

Agreement between MAME and IKA is hypothesis evidence only. Both were written
after the device documentation and neither is an original-silicon capture.

## Stable synthetic fixture

[simultaneous_ar_update_probe.asm](../../tests/asm/simultaneous_ar_update_probe.asm)
contains documented setup/readback instructions plus raw word `0x68b8`. That
word is the MAR indirect pattern with `INC=DEC=1`, bits 6/2/1 clear, bit 3 set
to preserve ARP, and bit 0 clear. The project assembler deliberately provides
no mnemonic for this combination; `.word` makes the unsupported encoding
visible in source.

The fixture emits armed marker `0x0033`, then applies the same word twice:

1. AR0 starts at `0x0000`; direct `SAR` and `OUT` export the complete result.
2. AR0 starts at `0x01ff`; the same readback exposes nine-bit wrap behavior.

Interpret the complete port-7 sequence:

| Export sequence | Candidate interpretation |
|---|---|
| `0033, 0000, 01ff` | no net update, as modeled independently by MAME and IKA |
| `0033, 0001, 0000` | increment priority |
| `0033, 01ff, 01fe` | decrement priority |
| missing, mixed, or other | unsupported-opcode side effect, unstable result, different priority, or fixture failure |

The repository assigns no passing expected sequence until qualified original
hardware is captured. In particular, the MAME/IKA sequence is not treated as
the expected silicon answer.

## Physical capture procedure

Use an original NMOS TMS32010, not a TMS320C10/C15, TMS32020/C25, or later
compatible device:

1. Record package marking, mask/date code, EVM or board and monitor revisions,
   oscillator, voltage, program-memory access time, and hashes of the exact
   hex/listing used.
2. Load the synthetic image into external program memory without modifying
   raw word `0x68b8`. Never execute a downloaded legacy binary to do so.
3. Capture `CLKOUT`, `MEN`, `DEN`, `WE`, `A11:A0`, and `D15:D0` from reset
   through the terminal loop. Decode port 7 writes while retaining the raw
   transition capture.
4. Run at least 32 reset-and-execute trials at nominal clock. Repeat at the
   documented slow and fast limits if the complete fixture satisfies access,
   setup, and hold requirements.
5. Save the analyzer setup, raw capture, decoded CSV, pin map, photographs,
   monitor transcript, exact program image/listing, and tool versions. Hash
   every artifact before format conversion.
6. Repeat on another original-part date/mask code before generalizing the
   outcome across `OQ-008`.

## Acceptance

A result can constrain `OQ-010` only when every run begins with `0033`, emits
exactly two result words in order, reaches the terminal loop, and is stable
across the required resets. A varying or unmatched sequence is architectural
evidence in its own right and must not be discarded as an inconvenient test.

Until such evidence exists, the combination remains unsupported, physical
behavior remains **UNKNOWN**, and the model/RTL fail-closed rejection must not
be relabeled as chip-equivalent trap behavior.
