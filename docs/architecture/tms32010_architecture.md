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
half as a zero operand and combine the selected 16-bit RAM word with
`ACC[15:0]`. Consequently `AND` clears `ACC[31:16]`, while `OR` and `XOR`
preserve it; all three place their logical result in `ACC[15:0]` and cannot
overflow
[ti-tms32010-users-guide-spru001b, `AND`, `OR`, and `XOR`, printed
pp. 3-13, 3-46, and 3-68 (PDF pp. 63, 96, and 118);
ti-first-generation-users-guide-1987, §3.5.2, printed pp. 3-19–3-20
(PDF pp. 48–49)]. **Confidence: VERIFIED_PRIMARY.**

The overflow flag `OV` is sticky until `BV` or a status load clears it. With
overflow mode `OVM` set, positive and negative overflows clamp to
`0x7fff_ffff` and `0x8000_0000`, respectively. With `OVM` clear, the wrapped
overflow result is loaded without saturation and `OV` is still set. The older
SPRU001B paragraph contains one contradictory sentence, but its following
explanation and the later TI SPRU013 architecture and `ROVM` descriptions
unambiguously establish the latter behavior
[ti-tms32010-users-guide-spru001b, §2.2.1.1, printed p. 2-4 (PDF p. 28);
ti-first-generation-users-guide-1987, §3.5.2 and `ROVM`, printed pp. 3-20 and
4-58 (PDF pp. 49 and 139); `SC-001`]. **Confidence: CORROBORATED for the
resolved contradiction; VERIFIED_PRIMARY for sticky `OV` and saturation
endpoints.**

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

`RS` is active low and must remain low for at least five complete `CLKOUT`
machine cycles (twenty crystal/input-clock periods).
After the current machine cycle completes, reset synchronously clears the PC,
sets the interrupt mask, clears the interrupt flag, and drives `MEN`, `DEN`,
and `WE` inactive high while the data bus is high impedance. Reset does not
change `OVM`. Other register reset/power-up values are not specified by this
pass and must not be invented
[ti-tms32010-users-guide-spru001b, §2.5, printed p. 2-19 (PDF p. 43)].
**Confidence: VERIFIED_PRIMARY.**

Appendix A resolves the external first-fetch sequence: after reset release,
normal operation resumes after one complete processor cycle and reads address
0 followed by address 1. The current wrapper offers a separate explicit
FPGA/test initialization input that establishes deterministic modeled state;
it is not physical `RS` behavior and does not initialize RAM. Physical reset
assigns no value to unlisted RTL state, so it retains prior FPGA state as a
conservative implementation policy pending `OQ-012`, not as a verified
physical-device claim
[ti-tms32010-users-guide-spru001b, Appendix A reset timing, printed data-sheet
p. 19 (PDF p. 375)]. **Confidence: VERIFIED_PRIMARY.**

## Current qualification boundary

The executable model, local assembler/disassembler, RTL, and seeded
differential boundary support `ADD`, `ADDS`, `AND`, `LAC`, `LACK`, `LAR`,
`LARK`, `LARP`, `LDP`, `LDPK`, `LT`, `MAR`, `MPY`, `MPYK`, `NOP`, `OR`, `PAC`, `ROVM`,
`SACL`, `SACH`, `SAR`, `SOVM`, `SUB`, `SUBS`, `XOR`, `ZAC`, `ZALH`, and
`ZALS`. The seventeen common-address data instructions have independent
fixtures plus directed and
seeded tests for direct/indirect address selection, reads or writes,
accumulator behavior, and nine-bit counter updates. SACH additionally verifies
all three documented output shifts and rejects all five other field values.
ZALH and ZALS verify high-half placement and low-half zero extension,
respectively. ADDS verifies unsigned operands, sticky overflow, wrapped
`OVM=0` results, and positive `OVM=1` saturation. AND, OR, and XOR verify the
documented low-half result, their distinct upper-half effects, and unchanged
`OV`/`OVM`. ADD verifies signed source extension, all shift-field bounds,
sticky overflow, wrapped results, and both OVM saturation endpoints. SUB
verifies the corresponding signed subtraction, shift, sticky-overflow, wrap,
and saturation cases.
SUBS verifies unsigned-source subtraction, sticky overflow, negative wrap,
and negative saturation without importing SUB's sign extension.
LAR verifies 16-bit loads to either auxiliary register, including suppression
of an indirect counter update when the destination also supplied the address.
SAR verifies 16-bit stores from either auxiliary register, including its
post-modified-value store when the source also supplied the old address.
MAR verifies direct no-operation forms and indirect AR/ARP modification
without a logical or physical data-memory access; its two LARP alias words
retain canonical LARP decode. Unresolved addresses trap rather than alias.
LDP reads through the old DP or selected AR, transfers source bit 0 to DP, and
then applies the ordinary indirect AR/ARP post-update.
LT reads through the same address path, transfers all 16 source bits to T, and
then applies the ordinary indirect AR/ARP post-update.
MPY signed-multiplies T by the selected 16-bit data word into P through that
same address/update path. Its documented `0x8000`-by-`0x8000` result is
`0xc0000000`, and directed tests preserve that physical multiplier exception.
MPYK instead sign-extends its signed 13-bit program-word constant, multiplies
it by T into P, and performs no data-memory access.
PAC copies all 32 P bits into ACC without changing P or arithmetic status and
also performs no data-memory access.
TI's separate rule deferring interrupt service through the instruction after
MPY or MPYK is documented but cannot yet be execution-tested because
interrupt entry does not exist.
This is partial RTL support only.
The sequential native-phase wrapper covers normal program reads only.
Current evidence does not constitute instruction completeness or cycle
accuracy.
