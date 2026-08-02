# Original-TMS32010 device-revision audit

## Question and result

This audit targets `OQ-008`: did any production mask revision of the original
NMOS TMS32010 change architecturally visible behavior?

No located Texas Instruments source identifies an original-TMS32010 silicon
mask revision, maps a package code to a die revision, or assigns a behavioral
change to such a revision. The surviving primary corpus does show changes in
data-sheet revision and product/speed-grade listings. Those are distinct facts
and must not be converted into a mask history. `OQ-008` therefore remains
**UNKNOWN** for silicon behavior and **RESEARCHING/NO REVISION MAP** for the
document search.

This result does not authorize treating every original NMOS specimen as
identical. It establishes only that the repository has no lawful primary or
physical evidence with which to classify a difference.

## Terms that must remain separate

| Label or observation | What the primary material establishes | What it does not establish |
|---|---|---|
| `SPRU001B`, `SPRU013`, `SPRU013B` | Publication revision or literature identity | Silicon-mask identity |
| Data sheet “revised October 1985,” “revised February 1986,” or “revised May 1989” | Editorial/specification control date for that embedded data sheet | A new die, mask spin, or behavior change |
| TMS32010, TMS32010-14, TMS32010-20, TMS32010-25 | Product/speed-grade naming in the cited publication | Different instruction semantics or internal logic |
| `TMS32010NL`, package suffixes, temperature suffixes | Device, package, and temperature nomenclature | A published mask-revision field |
| Tracking mark/date code and lot code | Raw manufacturing trace fields shown by TI | A decoded mask map or behavior guarantee |
| TMS320M10 | Mask-ROM product sibling | A revision of the ROMless target |
| TMS320C10/C15/C17 or TMS32020/C25 | Separately named CMOS or later-generation devices | Original-NMOS evidence |

The default core continues to target the ROMless, 20-MHz-class NMOS
TMS32010. A speed suffix may constrain electrical timing, but no current
architectural behavior is parameterized by it.

## Primary publication timeline

### October-1985 embedded data sheet

An alternate scan of SPRU001B contains 1985 copyright front matter and an
embedded TMS32010 data sheet dated May 1983, revised October 1985. Its first
page lists a base TMS32010 at 20.5 MHz and a TMS32010-25 at 25 MHz. The
symbolization page identifies the standard device number, TI design
copyright, tracking mark/date code, and lot code. It does not identify a
silicon-revision character or explain how to decode a mask
[ti-tms32010-users-guide-1985-alt-scan, appended data-sheet heading and
symbolization, PDF pp. 358 and 379].

### February-1986 embedded data sheet

The already pinned SPRU001B archive artifact has the same March-1985 manual
colophon but a later embedded data sheet dated May 1983, revised February
1986. It labels the two timing columns TMS32010-20 and TMS32010-25 while the
standard package-symbol example remains `TMS32010NL`. The package legend
again exposes tracking/date and lot fields without a mask decoder
[ti-tms32010-users-guide-spru001b, appended data-sheet heading, clock tables,
and symbolization, PDF pp. 357, 366-367, and 377].

The two scans prove a data-sheet revision chain and a naming change from base
TMS32010 to TMS32010-20 in the timing table. They do not prove that either
artifact corresponds to a different die.

### December-1986 and May-1987 product lists

The December-1986 development-support guide lists TMS32010NL,
TMS32010NL-14, and TMS32010NL-25 as 2.4-micrometer NMOS devices with 20, 14,
and 25 MHz operating frequencies. It separately identifies the TMS320C10
family as CMOS. The guide names the original TMS32010 data sheet as SPRS02A
and the TMS32010-14 data sheet as SPRS008
[ti-development-support-spru011-1986, Section 2.1, documentation support,
and Appendix A Table A-1, PDF pp. 21-25, 117, and 176].

The May-1987 initial first-generation guide likewise says the NMOS
TMS32010 was available in three speed versions and lists the same three part
numbers in its product table
[ti-first-generation-users-guide-1987, Appendix A printed pp. A-1-A-3 and
Appendix E product table, PDF pp. 232-234 and 361].

These are speed/product-list facts. Neither source calls them mask revisions
or assigns a functional difference among them.

### April/May-1989 product lists

The April-1989 SPRU011A family-support guide lists one 20-MHz NMOS
TMS32010 and moves the 14/25-MHz names to the CMOS TMS320C10 family. Its
current-product Table A-1 contains TMS32010NL but no original-NMOS -14 or -25
entry
[ti-development-support-spru011a-1989, Section 2.1 and Appendix A Table A-1,
PDF pp. 21 and 318].

SPRU013B is printed March 1989 but contains a first-generation data sheet
marked January 1987, revised May 1989. That sheet describes only the 20-MHz
NMOS TMS32010; its current product table also lists only TMS32010NL among the
NMOS first-generation products
[ti-first-generation-users-guide-1989, colophon, Appendix A printed
pp. A-1-A-3, and Appendix E Table E-1, PDF pp. 598, 238-240, and 426].

The matching 1989 lists show an intentional contemporary product-document
scope. They do not say whether earlier speed grades were discontinued,
renamed, merely omitted, or implemented with a different die. Absence from a
current-products table is not a product-change notice.

## Missing update archive

Both first-generation family guides say that a dial-up TMS320 DSP Bulletin
Board Service communicated specification updates for current and new devices
[ti-first-generation-users-guide-1987, Appendix E, PDF p. 360;
ti-first-generation-users-guide-1989, Appendix E, PDF p. 424]. The
development-support revisions repeat that role
[ti-development-support-spru011-1986, documentation support, PDF p. 117;
ti-development-support-spru011a-1989, Section 7.7, PDF pp. 160-161].

No authenticated archive of the period's TMS32010-specific BBS notices was
located. The surviving manuals therefore cannot be assumed to contain every
erratum or interim specification notice.

## Search routes and negative evidence

The following lawful searches were run on 2026-07-31:

- exact literature-number searches for `SPRS02A`, `SPRS002A`, and
  `TMS32010 Data Sheet`;
- exact phrase searches for `TMS32010 errata`, `TMS32010 mask set`,
  `TMS32010 silicon revision`, `TMS32010 product change notice`, and
  `TMS32010 tracking mark and date code`;
- TI-domain, Internet Archive, Bitsavers, and historical-document mirror
  searches for the same terms;
- inspection of the current Bitsavers `TMS320xx/3201x` and tool indexes.

They located the manuals cataloged above and distributor inventory mentions,
but no authentic TI TMS32010 erratum, product-change notice, mask map, or
revision-specific behavioral statement. Distributor descriptions are not
used as evidence. A file named `TI32000_Family_Data_Manual_1985.pdf` was
downloaded because its archive location and filename resembled TMS320. Cover
inspection proved that it documents the unrelated 32-bit TI32000 family. The
rejected artifact and checksum remain in the manifest so the false-positive
route is reproducible
[ti-ti32000-family-data-manual-1985-rejected, cover and contents, PDF
pp. 1-8].

Negative search results mean only “not located by these routes on this date.”
They are not proof that no erratum, field bulletin, internal change notice, or
unarchived BBS file ever existed.

## Physical specimen record

Every original-device capture used to close another open question must add a
specimen row with at least:

- exact top-side package text, line breaks, suffix, and all punctuation;
- raw tracking/date and lot strings, without guessing their meaning;
- sharp top, bottom, and board-context photographs;
- package type, acquisition provenance, and whether the part was socketed;
- board/EVM drawing and monitor revisions;
- oscillator frequency, supply voltage, temperature, reset duration, and
  program-memory timing;
- exact fixture source/listing/image hashes and tool versions;
- raw analyzer-file hash, pin map, decoded trace hash, trial count, and every
  unstable result;
- test result scoped to that specimen only.

Run each uncertainty probe on at least two original NMOS devices with
different raw tracking/date strings before claiming cross-specimen
corroboration. A matching pair is not a mask map. A differing pair is a
revision candidate that requires repetition, board/timing exclusion, package
photography, and another independent specimen before attributing the result
to silicon. Do not decap or otherwise destroy a specimen without explicit
owner authorization.

The `OQ-016` PUSH/POP capture workflow now machine-checks this record's
single-specimen subset: stable specimen ID, exact multiline marking, raw
tracking/date and lot strings, package/custody/socket/temperature/reset and
board/monitor details, exact fixture source/listing/image evidence, fixture
tool versions, normalized-trace hash, and distinct top/bottom/board-context
photographs. Its report is explicitly
`this_specimen_only` and `acceptance_complete=false`. This validates evidence
bookkeeping; it does not decode a TI mask or replace the required second
specimen for cross-device corroboration.

The `OQ-010` simultaneous-AR workflow applies the reusable version of the
same boundary. It additionally records numeric program-memory access time and
binds its exact 23-word listing and normalized trace to the named specimen.
Its classifications remain experiment results for `this_specimen_only`, with
`acceptance_complete=false`; no forced-word outcome is present and the
workflow cannot establish mask identity or invariance.

The `OQ-015` LST-ARP workflow now applies that same reusable boundary to its
exact 30-word bidirectional fixture. Its memory-wins, encoded-wins, mixed, and
other classifications remain scoped to `this_specimen_only`, and its report
always leaves `acceptance_complete=false`. Provenance completeness cannot
resolve the primary-document contradiction or establish mask invariance.

Both `OQ-017`/`OQ-018` SUBC workflows now apply the reusable boundary
independently to their exact dependency and overflow fixtures. A stable
unanticipated dependency word and any of the four status pairs remain valid
one-specimen observations; provenance validation does not choose among them.
Both reports are `this_specimen_only` with `acceptance_complete=false`.

## Implementation and release policy

- No RTL or model behavior changes solely because a later publication changed
  a speed-grade list.
- C10/C15/C17 and later-family evidence remains variant-scoped.
- Existing physical probes must retain raw package/date/lot data and must not
  generalize one specimen's result.
- A production erratum or authenticated change notice can close the question
  if it names affected devices/revisions and the changed behavior.
- Otherwise `OQ-008` can close only after physical results cover every
  externally meaningful difference required for release and the claim's
  specimen scope is explicit.

Present confidence is **VERIFIED_PRIMARY** for the publication/product-list
timeline, **UNKNOWN** for original-TMS32010 mask identities and behavioral
differences, and **UNKNOWN** for invariance across unmeasured specimens.
