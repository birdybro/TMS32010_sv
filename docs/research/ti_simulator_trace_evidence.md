# TI TMS32010 simulator trace evidence

## Source and authority boundary

Texas Instruments' 1982 *TMS32010 Simulator User's Guide* documents a
contemporary TI-hosted software model and its user-visible diagnostics. The
located scan states a 1982 copyright date but shows no publication number or
revision. It is primary evidence for that TI tool's documented behavior and
reference-software contract; it is not a production-device data sheet, an
external-pin trace, or proof that the simulator reproduced undocumented
silicon behavior
[ti-tms32010-simulator-users-guide-1982, §§1.1-1.2, printed pp. 3-4
(PDF pp. 5-6)].

Confidence is therefore **VERIFIED_PRIMARY** for the manual statements below.
Behavior of the simulator executable itself remains **NOT OBSERVED** because
no executable or source was acquired or run in this research cycle.

## Acquisition and program-memory events

The breakpoint vocabulary distinguishes:

- `BIAQ`, which stops when an instruction is acquired and before it executes;
- `BPR`, which stops when a program-memory read occurs.

That separation is useful evidence that the official simulator did not define
every program-memory read as an executed instruction acquisition
[ti-tms32010-simulator-users-guide-1982, §§2.6.7-2.6.8, printed p. 19
(PDF p. 21)]. It does not identify which internal fetch is accepted, expose
`MEN`, show address repetition, or specify an original-device bus phase.

## Trace and cycle counter

The documented trace is a 256-state circular buffer. Its displayed state is
limited to the program counter, accumulator, AR0, and AR1. The manual does not
say that the buffer records program addresses by external phase, data words,
or `MEN`/`WE`/`DEN`
[ti-tms32010-simulator-users-guide-1982, §§2.13-2.14, printed pp. 39-40
(PDF pp. 41-42)]. The separate clock counter reports elapsed simulated clock
cycles
[ti-tms32010-simulator-users-guide-1982, §2.20, printed p. 43
(PDF p. 45)].

Consequently, even an archived transcript of this trace would be architectural
and cycle-count evidence, not the pin-level evidence required to choose the
`OQ-016` PUSH/POP bus hypothesis. No PUSH/POP transcript was located in the
guide.

## SUBC scheduling diagnostic

Appendix A assigns simulator stop code `9950` to accumulator use in the first
clock cycle after `SUBC`
[ti-tms32010-simulator-users-guide-1982, Appendix A, printed p. 47
(PDF p. 49)]. This corroborates that contemporary TI reference software
actively enforced the documented scheduling restriction; it was not merely a
later editorial note.

The stop is a tool diagnostic. It does not say which old, intermediate, or
final accumulator value physical NMOS silicon supplies when software violates
the restriction, nor does it locate result availability within a device
phase. It therefore strengthens the legal-stream contract while leaving
`OQ-017` unresolved.

## Negative archival result

The public VTDA TI directory, the Bitsavers TMS320 tools directory, and an
Internet Archive title/description search were checked on 2026-07-31 for the
XDS/22 *TMS32010 Emulator User's Guide* cited bibliographically as `SPDU015`.
No scan was located in those indexes. VTDA did expose the simulator guide
cataloged here; Bitsavers exposed later XDS/22 material and other simulator
manuals. Absence from those indexes is not evidence that `SPDU015` is lost or
inaccessible elsewhere.

## Result

- `OQ-016`: unchanged; no external bus signals or PUSH/POP phase trace.
- `OQ-017`: unchanged; TI tool enforcement is corroborated, but violating
  silicon behavior is unknown.
- Architectural tooling: a future model-debugger compatibility layer should
  preserve the distinction between instruction acquisition and program-memory
  read and may expose a separate cycle counter without describing either as a
  pin trace.
