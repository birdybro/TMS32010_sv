# Original-TMS32010 RAM-boundary experiment

## Purpose and claim boundary

This experiment is intended to resolve `OQ-014`: what the original NMOS
TMS32010 does when `DMOV` or `LTD` selects source address `0x8f` and therefore
requests destination `0x90`, immediately beyond its documented 144-word data
RAM. It also supplies one observation toward the broader `OQ-002`; it cannot
characterize every absent address from `0x90` through `0xff`.

The production sources establish the valid memory and ordinary operation:

1. The original TMS32010 has 144 16-bit data words. Later TI material
   identifies page 0 as `0x00`-`0x7f` and the original-part portion of page 1
   as `0x80`-`0x8f`
   [ti-tms32010-assembly-guide-spru002b, `LDP`/`LDPK`, printed pp. 3-36-3-37
   (PDF pp. 57-58); ti-first-generation-users-guide-1987, Sections 3.4.1 and
   3.4.6, printed pp. 3-10 and 3-19 (PDF pp. 39 and 48)].
2. `DMOV` copies the selected word to the next higher address in one cycle;
   `LTD` performs the same move while loading T and adding the unchanged P
   value to ACC
   [ti-tms32010-users-guide-spru001b, `DMOV`/`LTD`, printed pp. 3-28 and 3-41
   (PDF pp. 78 and 91)].
3. Neither instruction page restricts the effective source so that the
   computed destination must remain within the physically implemented RAM.
   Direct operand fields are only seven bits, but DP or an eight-bit indirect
   address can select `0x8f` [same source, Sections 2.3.1.1-2.3.1.2, printed
   pp. 2-8-2-9 (PDF pp. 32-33)].

The `128-144` page-one range printed once in SPRU001B is arithmetically
incompatible with that guide's own 144-word total. SPRU002B and the later TI
family guide explicitly use `128-143`. It is retained as `SC-038`, not treated
as evidence for a 145th word.

No located production source says whether the boundary write is suppressed,
aliases a valid cell, reaches hidden storage, produces a dynamic-array side
effect, or prevents `LTD`'s other parallel operations. The current model/RTL
trap-before-effects policy remains **PROVISIONAL** and is not a prediction of
physical behavior.

## Related patent evidence

US4577282A describes a related contemporary TI DSP RAM move in transistor-level
terms. A RAM-move control connects sensed data to an adjacent column during
Q4 and holds it for a Q2 write in the next state. For an even address the
column-select bit is complemented; for an odd address it is complemented and
the row select is incremented
[ti-dsp-microcomputer-patent-us4577282a, patent cols. 25-26 (PDF p. 39),
Figures 5i and 5j]. This is useful background for why ordinary odd-to-even
crossings can occur without the ALU or D bus.

It does not resolve the last original-TMS32010 location. The same patent says
both that its RAM has a 1-of-144 row decoder and a 1-of-2 column decoder and
that eight address bits suffice, then later describes 144 row lines with an
even/odd word select [same source, patent cols. 17-18 and 25-26 (PDF pp. 35
and 39)]. Those statements do not form a self-consistent 144-word production
map, and the patent is not an original-TMS32010 production specification. It
contains no last-row or absent-row outcome.

## Independent implementation hypotheses

These sources are useful only for constructing competing tests:

- Pinned MAME maps its TMS320C10 data space only through `0x8f`, but its
  `dmov` and `ltd` handlers still issue a write to `m_memaccess + 1`. The LTD
  handler proceeds to T and ACC effects around that write. Framework handling
  of the unmapped target is an emulator policy, not silicon evidence
  [mame-tms320c1x-core-030fefc, `tms320c10_ram`, `dmov`, and `ltd`].
- Pinned IKA32010 allocates 256 words and writes `0x8f + 1` to `0x90`. That
  storage choice matches a later expanded-memory variant, not the original
  144-word device [ika32010-rtl-51bc1f0, `IKA32010_ram`, lines 1909-1937].

Measure rather than merge these possible outcomes:

| Hypothesis | Boundary write/read | Valid-RAM scan | LTD T/ACC effects |
|---|---|---|---|
| H1: absent select | write is suppressed; later `0x90` read is open/dynamic | only source `0x8f` remains nonzero | complete |
| H2: hidden cell | `0x90` stores and returns the source word | no valid alias | complete |
| H3: alias | one or more valid words receive the source word | changed valid word identifies alias | complete or coupled |
| H4: array-edge behavior | read and/or corruption depends on precharge, history, or device | results vary or multiple words change | complete or coupled |
| H5: global suppression | no boundary instruction effect retires | no move-induced change | T/ACC remain at their inputs |

H5 describes the current conservative project boundary but has no located
hardware support. A different physical result is a correction target, not a
test failure to hide.

## Synthetic probe programs

The project supplies two independently buildable fixtures:

- [ram_boundary_dmov_probe.asm](../../tests/asm/ram_boundary_dmov_probe.asm)
- [ram_boundary_ltd_probe.asm](../../tests/asm/ram_boundary_ltd_probe.asm)

Each program performs the following sequence without copyrighted data:

1. clear every documented data word from `0x8f` down through `0x00` using an
   indirect `SACL`/`BANZ` loop;
2. write sentinel `0x005a` to source `0x8f`;
3. establish T=`0x0003`, P=`0x0000000f`, and ACC=`0x00000007`;
4. execute direct page-one `DMOV 0x0f` or `LTD 0x0f`;
5. emit all 144 valid words, descending `0x8f` through `0x00`, as port-7
   `OUT` writes so any alias or corruption is visible on the external data
   bus;
6. emit a final port-7 `OUT` sourced from direct page-one field `0x10`, which
   selects absent address `0x90`;
7. execute a NOP and enter a terminal self-branch. The NOP permits an EVM
   breakpoint at `hold` despite the monitor's restriction on breakpoints
   immediately following `OUT`.

The expected defined-state results at `hold` are:

| Probe | ACC | T | P | valid scan absent alias |
|---|---:|---:|---:|---|
| DMOV | `0x00000007` | `0x0003` | `0x0000000f` | first sample `0x005a`, following 143 samples zero |
| LTD | `0x00000016` | `0x005a` | `0x0000000f` | first sample `0x005a`, following 143 samples zero |

The 145th port write is the observed `0x90` read and has no expected value.
Do not initialize or patch that result into the fixture.

Assemble with:

```sh
python3 -m tools.assembler.tms32010_as \
  tests/asm/ram_boundary_ltd_probe.asm \
  --hex build/ram_boundary_ltd_probe.hex \
  --listing build/ram_boundary_ltd_probe.lst
```

Repeat with the DMOV source name. Hash the generated hex and listing used for
every hardware capture. Repository tests lock both source images and symbol
locations against accidental change.

## Capture procedure

Use an original NMOS TMS32010. A TMS320C10/C15, MAME, or FPGA core does not
resolve this question.

1. Record complete device markings, board revision, clock, supply voltage,
   program-memory type, EVM/monitor revision, probe/analyzer models, and hashes
   of both exact images.
2. Probe `CLKOUT`, active-low `MEN`, `WE`, `DEN`, `RS`, `A11:A0`, and
   `D15:D0`. Use high-impedance probes and a board-safe grounding plan.
3. Capture from reset through the terminal loop. Decode each active `WE`
   port-7 interval using the physical pin polarity and address lines, not an
   assumed instruction count.
4. Preserve the ordered 144-word scan and the distinct final `0x90` sample.
   If timing makes them hard to distinguish, use the program address and the
   NOP/terminal branch as frame markers; do not insert undocumented reads.
5. At the `hold` breakpoint, use the contemporary EVM register commands to
   record ACC, T, P, OV, OVM, DP, ARP, and both AR values. The EVM documents
   those commands, while its direct `MDM` command is limited to `0x00-0x5f`
   and is therefore insufficient for this experiment
   [ti-tms32010-evm-users-guide-spru005a, Section 3.3.2 and Tables 3-2/3-3,
   printed pp. 3-4-3-6 (PDF pp. 45-47), and `MDM`, printed p. 3-47
   (PDF p. 88)].
6. Run each probe at least 32 times after reset, then repeat while varying the
   immediately preceding legal RAM read and the sentinel pattern. Preserve
   every differing run.
7. Save raw analyzer files, decoded CSV, command transcript, photographs, pin
   map, and tool versions. Hash every artifact before conversion.

## Fixed-baseline normalization

Normalize both analyzer captures to one row per falling `CLKOUT` boundary and
record the EVM state using the exact schemas in
[the trace-tool README](../../tools/trace/README.md). Assemble the checked
big-endian images and run the paired normalizer:

```sh
python3 -m tools.trace.ram_boundary_capture dmov.csv ltd.csv \
  --dmov-metadata dmov-metadata.json \
  --ltd-metadata ltd-metadata.json \
  --dmov-image ram_boundary_dmov_probe.bin \
  --ltd-image ram_boundary_ltd_probe.bin \
  --register-observations registers.csv \
  --artifact-root capture-artifacts \
  --require-review-ready
```

The normalizer preserves every valid-RAM word and the diagnostic word; it does
not require the scan to remain unchanged, the diagnostic to repeat, or the
documented DMOV/LTD parallel register effects to match. Any of those outcomes
may be the physical evidence sought. Fixture validity instead covers exact
program images, fetch/write framing, complete output length, EVM run identity,
and hashed raw-capture/transcript/photo provenance.

`review_ready` describes only a complete paired fixed-baseline package. The
report keeps `acceptance_complete=false` because these two exact images do not
vary the immediately preceding legal read or sentinel and one device cannot
establish mask invariance. Partial noncompletion and extra-output streams are
retained in reports but cannot become review-ready.

## Acceptance and interpretation

`OQ-014` can advance to `VERIFIED_HARDWARE` for the tested device only when
both probes establish:

- whether the valid 144-word array aliases or is corrupted;
- the value and repeatability of the subsequent `0x90` read;
- whether DMOV preserves ACC/T/P and arithmetic status;
- whether LTD loads T and accumulates prior P despite the absent destination;
- whether results depend on previous read history or sentinel value;
- complete device/image/capture provenance.

A repeatable `0x90` value does not by itself prove a hidden independent cell;
the valid-array scan and varied-history runs are required. One part establishes
observed behavior for that device, not mask-revision invariance (`OQ-008`).
Until a qualified capture or authoritative production source exists, no
boundary outcome is assigned to the architectural model or RTL.
