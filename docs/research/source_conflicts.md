# Source conflicts and transcription hazards

## SC-001 — Overflow-mode prose

- **Sources:** TI SPRU001B §2.1.2, printed pp. 2-3–2-5.
- **Conflict:** one sentence in the scan/OCR says the accumulator is
  unmodified on overflow when `OVM=0`, while the following explanation says
  the overflowed result is loaded; normal two's-complement wrap is also
  implied by instruction examples.
- **Resolution:** the detailed paragraph immediately following the disputed
  sentence says the overflowed result is loaded without modification. TI
  SPRU013 §3.5.2, printed p. 3-20, and its `ROVM` page, printed p. 4-58,
  repeat that behavior unambiguously: `OVM=0` retains the wrapped result and
  sets `OV`; `OVM=1` saturates while also setting `OV`.
- **Current treatment:** resolved for arithmetic implementation. Retain this
  record because the original revision-B sentence remains erroneous.
- **Confidence:** CORROBORATED for the resolution across TI revisions;
  VERIFIED_PRIMARY for the saturation endpoints and sticky `OV`.

## SC-002 — Hard Drivin' device identity

- **Primary hardware evidence:** Atari drawing A044427 sheet 4 labels the
  physical device `TMS32010` and shows a 20 MHz crystal.
- **Secondary software evidence:** current MAME configures its `TMS320C10`
  device type at 20 MHz, although surrounding comments call the slave a
  TMS32010.
- **Current treatment:** implement the original TMS32010. MAME's C10 model is
  a functional oracle only; disagreements are not automatically resolved in
  its favor.
- **Confidence:** VERIFIED_PRIMARY for the board label, CORROBORATED for
  object-code compatibility, UNKNOWN for undocumented NMOS/CMOS differences.

## SC-003 — Scan OCR mnemonic corruption

SPRU001B OCR renders `LAR`/`MPY`/`DMOV` as `LAA`/`MPV`/`OMOV` in parts of
Table 3-2. Individual instruction headings, examples, and other TI documents
use the former spellings. Database transcription must use page images rather
than raw OCR. **Treatment: resolved as OCR artifacts; VERIFIED_PRIMARY.**

## SC-004 — Presumed wait states versus actual pinout

The requested qualification includes READY/wait-state behavior, but the
original TMS32010 40-pin interface has no READY/WAIT pin in SPRU001B. A
wrapper-level phase pause may still be useful, but it cannot be labeled a
native protocol without clocking evidence. **Treatment: open as OQ-001.**

## SC-005 — Data-page-one upper bound

SPRU001B §2.3.1.2 prints page 1 as locations 128–144, which would contain 17
words. The same guide repeatedly specifies 144 total words and a 16-word
second page, establishing implemented locations 128–143. **Treatment:** model
only 0–143; keep address 144 and all higher eight-bit addresses unresolved
under `OQ-002` rather than interpreting the inconsistent endpoint as storage.
**Confidence:** VERIFIED_PRIMARY for the 144-word capacity; UNKNOWN for the
electrical result of an out-of-range access.

## SC-006 — ADDH overflow wording

- **Original-part sources:** TI SPRU001B `ADDH`, printed p. 3-11, gives the
  high-half addition and says it is useful for 32-bit arithmetic, but does not
  state whether `OV` or `OVM` applies. TI SPRU013 `ADDH`, printed p. 4-16,
  repeats that omission.
- **Variant source:** TI SPRU032A for the TMS320C14/E14 explicitly says
  `ADDH` affects `OV` and is affected by `OVM`, while still saying the low
  accumulator half is unaffected.
- **Secondary source:** the pinned MAME implementation applies high-half
  overflow and saturation but comments that this is an inference because the
  manual omitted it.
- **Current treatment:** `ADDH` remains outside the implemented boundary under
  `OQ-011`. `ADDS`, whose status behavior is explicit in SPRU013 and SPRU032A,
  can proceed independently.
- **Confidence:** UNKNOWN for original-TMS32010 `ADDH` overflow and saturation
  details; VERIFIED_PRIMARY for its ordinary non-overflow transfer.

## SC-007 — ABS overflow-flag omission

- **Original-part sources:** TI SPRU001B `ABS`, printed p. 3-9 (PDF p. 59),
  and SPRU013 `ABS`, printed p. 4-14 (PDF p. 95), both define opcode
  `0x7f88`, the ordinary absolute-value result, the OVM-dependent
  `ABS(0x80000000)` result, and one-cycle timing. Neither page states whether
  that boundary case sets sticky `OV`.
- **Variant source:** TI SPRU032A for the TMS320C14/E14, `ABS`, printed
  p. 4-14 (PDF p. 121), explicitly states that ABS affects `OV` and is
  affected by `OVM`. This is evidence about a later variant, not proof of the
  original NMOS part.
- **Secondary source:** pinned MAME commit
  `030fefcbd14e47c01ec9d67655be90f64a1dc8ab` implements negation and OVM
  saturation in `tms320c1x.cpp:341`, but its handler never writes `OV`.
- **Competing hypotheses:** the original part sets sticky `OV` on the unique
  unrepresentable negation, consistent with the variant guide; or it leaves
  `OV` unchanged, consistent with the original pages' omission and MAME.
- **Current treatment:** `ABS` remains outside the database/model/tool/RTL
  support boundary under `OQ-013`. No provisional status behavior is selected.
- **Confidence:** VERIFIED_PRIMARY for encoding, accumulator result, OVM
  result selection, word count, and cycle count; UNKNOWN for original-part
  `OV`.

## SC-008 — SST reserved bit 1

- **Original-part sources:** TI SPRU001B Figure 2-7, printed p. 2-15 (PDF
  p. 39), marks stored status-word bit 1 as “don't care.” The same guide's
  `LST` page, printed p. 3-38 (PDF p. 88), and SPRU002B `LST`, printed
  p. 3-38 (PDF p. 59), draw bit 1 as one.
- **Later family source:** TI SPRU013 `LST`, printed p. 4-43 (PDF p. 124),
  draws bit 1 as zero even though it covers the TMS32010 among several
  first-generation variants.
- **Conflict:** the authoritative documents assign three incompatible
  descriptions to the same reserved result bit. This does not affect `LST`,
  which ignores reserved input bits, but it prevents a deterministic `SST`
  result claim.
- **Current treatment:** bits 12:9 and 7:2 are documented ones. `SST` remains
  outside the qualified boundary under `OQ-003` until an original-part erratum
  or physical measurement resolves bit 1.
- **Confidence:** VERIFIED_PRIMARY for the contradiction and the other
  reserved bits; UNKNOWN for stored bit 1.

## SC-009 — LST next-ARP precedence

- **Original-part sources:** SPRU001B and SPRU002B `LST`, printed p. 3-38,
  and SPRU013 `LST`, printed p. 4-43, all expose an optional indirect
  next-ARP operand while stating that data-word bit 8 loads `ARP`. None states
  which source wins when the two values differ.
- **Variant clarification:** TI SPRU012 `LST`, printed p. 4-75, explicitly
  says the next-ARP field is ignored and the memory word supplies `ARP`.
- **Independent oracle:** pinned MAME commit
  `030fefcbd14e47c01ec9d67655be90f64a1dc8ab` suppresses the ordinary
  next-ARP update in its `lst()` handler before loading the status word.
- **Current treatment:** the model and RTL will ignore LST's encoded next-ARP
  field and load `ARP` from source bit 8. This is a targeted, tested
  provisional original-part behavior under `OQ-015`, not a claim that later
  C25 behavior proves the NMOS TMS32010.
- **Confidence:** PROVISIONAL for the original TMS32010; CORROBORATED across
  the later TI guide and independent emulator.
