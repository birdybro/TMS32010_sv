# Original-TMS32010 absent data-address decode experiment

## Question and current claim boundary

This experiment targets `OQ-002`: what is observed when an original NMOS
TMS32010 ordinary data operand selects `0x90` through `0xff`, beyond its
documented 144-word `0x00`-`0x8f` RAM?

The current model and RTL reject such an effective address before any
instruction effect. The standalone RAM returns zero on its diagnostic invalid
read port. Both choices are fail-closed project policies, not claims that
physical silicon traps, suppresses the instruction, or reads zero.

## Production documentation boundary

The original guide says the on-chip data RAM contains exactly 144 16-bit
words and that every non-immediate data operand resides there. Its direct
address is nevertheless formed by concatenating DP with a seven-bit field,
and its indirect address uses all eight low auxiliary-register bits. Apart
from the isolated `128-144` endpoint error retained in `SC-005`/`SC-038`, the
original assembly guide and later TI family map identify the implemented
range as `0x00`-`0x8f`
[ti-tms32010-users-guide-spru001b, Sections 2.3-2.3.1.2, printed
pp. 2-7-2-8 (PDF pp. 31-32); ti-tms32010-assembly-guide-spru002b,
`LDP`/`LDPK`, printed pp. 3-36-3-37 (PDF pp. 57-58);
ti-first-generation-users-guide-1987, Sections 3.4.1, 3.4.4, and Figure 3-5,
printed pp. 3-10 and 3-13 (PDF pp. 39 and 42)].

No located production page assigns an absent-select read value, alias,
write suppression, corruption behavior, instruction-retirement result, or
mask-revision guarantee. Eight address bits being present does not prove that
all 256 selects name storage.

## Related physical-decode evidence and independent policies

- TI patent US4577282A shows a related chip layout and says an eight-bit RAM
  address feeds separate row and one-of-two column selection. The same prose
  inconsistently combines 144 row lines with a two-column organization while
  the production architecture has 144 total words. It cannot establish the
  original production decoder or any absent-select result
  [ti-dsp-microcomputer-patent-us4577282a, patent cols. 17-18 and 25-26
  (PDF pp. 35 and 39), Figures 4 and 5i-5j].
- Pinned MAME maps TMS320C10 data RAM only at `0x00`-`0x8f`; its eight-bit
  address space leaves the remainder unmapped. Framework open-bus handling is
  emulator policy and is not imported into this core
  [mame-tms320c1x-core-030fefc, `tms320c10_ram`, lines 40-49, and data-space
  configuration, lines 64-68].
- Pinned IKA32010 instead allocates all 256 words and initializes them to
  zero. That is an FPGA storage choice compatible with expanded later
  variants, not original-NMOS evidence
  [ika32010-rtl-51bc1f0, `IKA32010_ram`, lines 1909-1937].
- A publicly indexed TMS320M10 decap was located during this cycle, but the
  source page was unavailable to the lawful fetcher with HTTP 429 and the
  indexed description concerns mask-ROM extraction, not RAM-select analysis.
  No decoder claim is derived from the search result
  [caps0ff-tms320m10-decap-2020, search-index metadata only; retrieval
  attempted 2026-07-31].

These sources motivate competing hypotheses only: no select, hidden storage,
partial decode alias, several addresses sharing a cell, history-dependent
dynamic output, or broader array disturbance.

## Stage 1: read-only controlled-history sweep

[ram_invalid_read_sweep_probe.asm](../../tests/asm/ram_invalid_read_sweep_probe.asm)
does not issue a data-RAM write to any absent address. It emits through port 7:

1. marker `0x0031`;
2. all 112 addresses `0x90`-`0xff` in ascending order, each immediately
   preceded by a valid-RAM read of `0x0000`;
3. marker `0x0032`;
4. the same 112 addresses, each immediately preceded by a valid-RAM read of
   `0xffff`;
5. terminal marker `0x003f`.

Thus each middle item of a `(known predecessor, observation)` pair is an
unassigned physical result. A value matching its predecessor is consistent
with an open/dynamic internal bus, but does not prove that explanation. A
stable different value may be an alias, hidden cell, wired pattern, or another
dynamic effect. The repository assigns no passing expected absent-read value.

This fixture is minimally destructive with respect to the unknown region: it
writes only five documented RAM words during setup. Run it before either
write probe and before using an EVM monitor command that might touch data RAM.

### Stage-1 normalization

Normalize one row per falling `CLKOUT` boundary and add a `run_conditions`
metadata mapping for every `reset` or `cold_power` trial as documented in
[the trace-tool README](../../tools/trace/README.md). Then check the exact
big-endian image and classify:

```sh
python3 -m tools.trace.ram_invalid_read_capture read-sweep.csv \
  --metadata read-sweep-metadata.json \
  --program-image ram_invalid_read_sweep_probe.bin \
  --artifact-root capture-artifacts \
  --require-review-ready
```

The classifier retains both measured values for every address and labels only
their relationship: predecessor-tracking, history-independent, or history-
dependent. These are descriptive categories, not electrical explanations.
Variation between complete runs is preserved and does not block package
review. Exact markers, legal predecessor words, all 451 OUT fetch/write pairs,
the terminal window, 32 reset trials, eight cold-power trials, and raw/photo/
image hashes are mandatory.

Stage-1 `review_ready` does not authorize either write sweep and does not
complete `OQ-002`; reports therefore keep `acceptance_complete=false`.

## Stage 2: directional unique-sentinel write sweeps

The write probes first construct `0xa06f` in AR1, then clear all 144 valid
words. SAR stores the complete other auxiliary register through an address in
AR0; BANZ tests and decrements only AR1's low nine-bit counter while preserving
its upper seven bits. The zero-counter exit still performs the documented
low-nine-bit decrement after deciding not to branch, but that occurs after the
last sentinel store. This avoids a RAM-based constant or count that an invalid
write could silently corrupt while the probe is still running
[ti-tms32010-users-guide-spru001b, Section 2.4.1 and `BANZ`, printed
pp. 2-9-2-10 and 3-16 (PDF pp. 33-34 and 66)].

- [ram_invalid_write_ascending_probe.asm](../../tests/asm/ram_invalid_write_ascending_probe.asm)
  writes `0xa06f` through `0xa000` to `0x90` through `0xff`.
- [ram_invalid_write_descending_probe.asm](../../tests/asm/ram_invalid_write_descending_probe.asm)
  writes the same sentinels to `0xff` through `0x90`.

Each fixture emits its start marker (`0x0041` ascending or `0x0042`
descending), then:

1. the 144 documented words in descending `0x8f`-`0x00` order;
2. the 112 absent addresses in the write direction;
3. terminal marker `0x004f`.

All valid words are known zero immediately before the unsupported writes.
Nonzero scan words therefore identify an alias or disturbance candidate; the
stored sentinel and opposite write orders help constrain which absent select
caused it. Zero valid words do not prove write suppression because hidden or
dynamic storage remains possible. Likewise, the absent-region readback has
no expected value. If multiple selects collapse onto one valid word, the two
directional sweeps reveal only the first/last surviving sentinel; follow with
a single-target probe before claiming an exact alias map.

## Physical capture procedure

Use an original NMOS TMS32010, not a TMS320C10/C15 or another family member:

1. Record complete package marking and date/mask code, board/EVM and monitor
   revisions, oscillator, supply, program-memory timing, and hashes of the
   exact hex/listing files.
2. Run the read-only fixture first after cold power-up. Capture `CLKOUT`,
   active-low `MEN`, `DEN`, `WE`, `RS`, `A11:A0`, and `D15:D0` from reset to
   the terminal loop. Use the program address to retain exact output framing.
3. Run at least 32 reset-and-execute trials, then at least 8 cold-power trials.
   Preserve every variation; do not average dynamic or unstable results.
4. Only after the read-only captures, run both write directions on the same
   part. Repeat with another sentinel high pattern if any alias or disturbance
   appears. A targeted follow-up must isolate each candidate select.
5. Repeat the complete sequence on another original-part date/mask code before
   generalizing across `OQ-008`.
6. Save raw analyzer data, decoded CSV, pin map, photographs, monitor
   transcript, exact program images/listings, and tool versions. Hash every
   artifact before conversion.

## Acceptance

The capture must retain every marker, known predecessor, absent observation,
valid-array scan, program-address boundary, reset trial, and device identifier.
A missing marker, early loop exit, or malformed sample count is a fixture
failure; a nonzero, unstable, aliased, or otherwise surprising data value is
evidence and must not be discarded.

Qualified captures can classify the tested device's read and write behavior,
but cannot establish mask invariance from one part. Until then, `OQ-002`
remains **UNKNOWN**, and neither zero-fill, 256-word expansion, modulo aliasing,
nor trap-before-effects may be relabeled as original-silicon behavior.
