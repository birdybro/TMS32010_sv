# TMS32010 architecture research baseline

## Status and citation convention

This is a cited research baseline, not yet a complete implementation
specification. `VERIFIED_PRIMARY` means the statement is explicit in a
first-party source; it does not mean the corresponding RTL or timing test
exists. Open items are linked to `docs/research/open_questions.md`.

Citation keys resolve through `docs/references/manifest.yaml`:

- `ti-tms32010-users-guide-spru001b`: TI, *TMS32010 User's Guide*,
  revision B, March 1985.
- `ti-first-generation-users-guide-1987`: TI, *First-Generation TMS320
  User's Guide*, 1987.
- `atari-driver-sound-board-schematic`: Atari drawing A044427 Driver Sound
  Board schematics.
- `mame-*`: MAME commit
  `030fefcbd14e47c01ec9d67655be90f64a1dc8ab`, used only as an independent
  secondary reference.

## Device identity and scope

The target is the original ROMless NMOS TMS32010 in microprocessor mode:
144 words of on-chip data RAM and up to 4096 words of external program
memory. The 1987 family guide separately identifies the TMS320C10 as a CMOS
part and the C15/E15 as 256-word-RAM parts. Object-code or pin compatibility
does not prove identical undocumented behavior or electrical timing
[ti-tms32010-users-guide-spru001b, §2.1.1, printed pp. 2-1–2-3 (PDF
pp. 25–27); ti-first-generation-users-guide-1987, §1.1, printed
pp. 1-2–1-4]. **Confidence: VERIFIED_PRIMARY.**

The default core will not expose on-chip program ROM, expanded C15 RAM, C17
serial peripherals, or later-family instructions. Variant parameterization is
deferred until the base part is objectively qualified.

## Data path

The programmer-visible data path comprises a 32-bit accumulator and ALU, a
16-bit T register, a signed 16-by-16 parallel multiplier with 32-bit P
register, two 16-bit auxiliary registers, a one-bit auxiliary-register
pointer, and a data-page bit. A barrel shifter aligns data-memory operands
before the ALU; a separate output shifter supports accumulator stores
[ti-tms32010-users-guide-spru001b, §2.1 and Figures 2-1/2-2, printed
pp. 2-1–2-7 (PDF pp. 25–31)]. **Confidence: VERIFIED_PRIMARY.**

Arithmetic uses two's-complement values. The ALU is 32 bits wide. A
data-memory operand is sign-extended before a documented left shift of 0–15
places; zeros enter at the low end. Instructions that suppress sign extension
are called out individually. Logical operations act on the upper accumulator
half while passing the lower half unchanged
[ti-tms32010-users-guide-spru001b, §§2.1.2–2.1.3, printed pp. 2-3–2-7
(PDF pp. 27–31)]. **Confidence: VERIFIED_PRIMARY.**

The overflow flag `OV` is sticky until `BV` or a status load clears it. With
overflow mode `OVM` set, positive and negative overflows clamp to
`0x7fff_ffff` and `0x8000_0000`, respectively. The prose for `OVM=0`
contains an internal wording conflict tracked as `SC-001`; no implementation
claim is made from the contradictory sentence
[ti-tms32010-users-guide-spru001b, §2.1.2, printed pp. 2-3–2-5 (PDF
pp. 27–29)]. **Confidence: VERIFIED_PRIMARY except SC-001.**

## Control path

The PC is 12 bits. A four-level, 12-bit hardware stack supports branches,
calls, returns, interrupts, `PUSH`, and `POP`. Stack overflow discards the
deepest value; popping beyond the bottom propagates the bottom value upward
[ti-tms32010-users-guide-spru001b, §§2.2.1–2.2.2, printed pp. 2-13–2-14
(PDF pp. 37–38)]. **Confidence: VERIFIED_PRIMARY.**

The processor fetches an instruction while executing the preceding
instruction. Multiword and multicycle operations disturb this overlap in
documented ways; those phase sequences are not yet fully transcribed
[ti-tms32010-users-guide-spru001b, §§2.1, 3.4.2, printed pp. 2-1, 3-5–3-7
(PDF pp. 25, 55–57)]. **Confidence: VERIFIED_PRIMARY for overlap and listed
cycle counts; UNKNOWN for the complete phase-level matrix.**

## Reset baseline

`RS` is active low and must remain low for at least five input-clock cycles.
After the current machine cycle completes, reset synchronously clears the PC,
sets the interrupt mask, clears the interrupt flag, and drives `MEN`, `DEN`,
and `WE` inactive high while the data bus is high impedance. Reset does not
change `OVM`. Other register power-up values are not specified by this
pass and must not be invented
[ti-tms32010-users-guide-spru001b, §2.5, printed p. 2-19 (PDF p. 43)].
**Confidence: VERIFIED_PRIMARY.**

Implementation reset semantics remain pending the first-fetch phase review
(`OQ-006`). FPGA-friendly deterministic initialization, if later offered,
will be wrapper behavior and visibly distinct from physical-chip guarantees.

## Current qualification boundary

The executable model and partial RTL support only `LACK`, `NOP`, `ZAC`,
`ROVM`, and `SOVM`; all other encodings trap. This narrow slice has
independent fixtures, directed model/RTL tests, and seeded differential
evidence. Its instruction-boundary program interface does not constitute
native-bus, instruction-completeness, or cycle-accuracy evidence.
