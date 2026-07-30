# Source conflicts and transcription hazards

## SC-001 — Overflow-mode prose

- **Sources:** TI SPRU001B §2.1.2, printed pp. 2-3–2-5.
- **Conflict:** one sentence in the scan/OCR says the accumulator is
  unmodified on overflow when `OVM=0`, while the following explanation says
  the overflowed result is loaded; normal two's-complement wrap is also
  implied by instruction examples.
- **Current treatment:** unresolved wording conflict. Individual instruction
  pages and another TI revision must be checked before arithmetic RTL.
- **Confidence:** UNKNOWN for the disputed sentence; saturation endpoints
  with `OVM=1` are VERIFIED_PRIMARY.

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
