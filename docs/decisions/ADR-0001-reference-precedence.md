# ADR-0001: architectural reference precedence

- **Status:** Accepted
- **Date:** 2026-07-30
- **Decision owners:** project maintainers

## Context

The original NMOS TMS32010 is described by several TI publications and was
later followed by object-code-compatible CMOS and larger-memory parts. Atari
board drawings describe one concrete integration. Emulators are useful
independent oracles but may intentionally abstract electrical or cycle
behavior. Treating all of these sources as interchangeable would silently
import later-device behavior into the target.

## Decision

Architectural claims use this descending precedence:

1. original TI TMS32010 user guide, data sheet, errata, and AC timing tables;
2. Atari schematics and service information for Hard Drivin'-specific wiring;
3. contemporary TI development-tool and application documentation;
4. physical-chip measurements or die evidence with a reproducible method;
5. maintained emulator implementations, including MAME;
6. academic implementations and community descriptions.

A lower-precedence source may corroborate a claim. It may supersede a
higher-precedence statement only when reproducible hardware evidence or a
documented erratum establishes that the higher-precedence statement is wrong.
The conflict and rationale must then be recorded in
`docs/research/source_conflicts.md`.

Every substantive architecture statement carries one of:
`VERIFIED_PRIMARY`, `VERIFIED_HARDWARE`, `CORROBORATED`, `INFERRED`,
`PROVISIONAL`, or `UNKNOWN`. A later compatible part is not evidence of
original-TMS32010 behavior unless the cited material explicitly says so.

MAME source is never copied or transliterated into RTL or the architectural
model. It remains an independently licensed differential-testing oracle.
Historical manuals and Atari drawings stay in the ignored reference cache
unless redistribution permission is established.

## Consequences

- Research may remain incomplete even when an emulator supplies an answer.
- Variant selection is explicit; the portable core defaults only to the
  original ROMless NMOS TMS32010.
- Unresolved behavior traps or remains unimplemented instead of becoming a
  convenient no-op.
- Citations use manifest source IDs and printed page/section references; PDF
  page numbers are added where scan pagination differs.

## Evidence

The initial sources and immutable hashes are in
`docs/references/manifest.yaml`. TI identifies the original TMS32010 as NMOS
and the TMS320C10 as a later CMOS, object-code- and pin-compatible part
[ti-first-generation-users-guide-1987, §1.1, printed pp. 1-2–1-4].
