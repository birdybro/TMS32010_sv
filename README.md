# tms32010-sv

Clean-room, synthesizable SystemVerilog implementation of the original Texas
Instruments TMS32010 fixed-point digital signal processor.

The long-term integration target is the Atari Hard Drivin' sound subsystem on
MiSTer. The architectural core is intentionally platform-independent.

## Status

This project is in its research and infrastructure phase. It is **not yet an
instruction-complete or cycle-accurate processor**. Architectural claims are
accepted only when they are tied to cited evidence and automated tests. See
[TASKS.md](TASKS.md), [CHANGELOG.md](CHANGELOG.md), and
[artifacts/progress.md](artifacts/progress.md) for current evidence.

The reference model and local tools currently support fifty-seven
instructions: `ADD`, `ADDS`, `AND`, `APAC`, `B`, `BANZ`, `BGEZ`, `BGZ`, `BIOZ`, `BLEZ`, `BLZ`, `BNZ`, `BV`, `BZ`, `CALA`, `CALL`, `DINT`, `DMOV`, `EINT`, `LAC`, `LACK`, `LAR`, `LARK`, `LARP`,
`IN`, `LDP`, `LDPK`, `LST`, `LT`, `LTA`, `LTD`, `MAR`, `MPY`, `MPYK`, `NOP`, `OR`, `OUT`, `PAC`, `ROVM`, `SACL`,
`POP`, `PUSH`, `RET`, `SACH`, `SAR`, `SOVM`, `SPAC`, `SUB`, `SUBC`, `SUBH`, `SUBS`, `TBLR`, `TBLW`,
`XOR`, `ZAC`, `ZALH`, and `ZALS`. The partial RTL and seeded differential
boundary support the same set except CALA, POP, PUSH, and RET,
for fifty-three shared instructions; their second external cycles remain
unresolved under `OQ-007`/`OQ-016`.
The 144-word internal RAM exposes verification-visible logical
`ADD`/`ADDS`/`AND`/`DMOV`/`LAC`/`LAR`/`LDP`/`LST`/`LT`/`LTA`/`LTD`/`MPY`/`OR`/`SUB`/
`SUBC`/`SUBH`/`SUBS`/`XOR`/`ZALH`/`ZALS` reads and `DMOV`/`LTD`/`SACL`/`SACH`/`SAR` writes;
MAR changes only AR/ARP and produces no data transaction; MPYK consumes its
signed immediate from the program word, PAC copies P to ACC, and APAC adds P
to ACC while SPAC subtracts P from ACC; APAC and SPAC apply sticky overflow
and OVM saturation, and none has a data transaction.
LTA combines a full-word internal-RAM load to T with previous-P accumulation
into ACC in the same documented one-cycle transaction.
LTD performs those same two operations while also copying the unchanged
source word to the next internal-RAM address; the logical verification
interface exposes separate read and write addresses for this dual-address
transaction. An LTD whose source or destination is outside the verified
144-word RAM traps provisionally rather than inventing wrap or alias behavior.
DMOV performs only that source-preserving next-address copy, leaving
ACC/T/P and arithmetic status unchanged; it follows the same explicit
unresolved-endpoint policy.
`DINT` and `EINT` set and clear the architectural interrupt mask in one
program-only cycle. The partial core now also exposes active-low `int_i`,
latches a request while masked, implements the tested EINT and MPY/MPYK
deferrals, dummy-fetches and stacks the return PC, masks and clears the
request, and selects vector 2. A native-phase test matches TI Figure 2-12's
external read order. A 32-case core matrix exhausts request arrival at every
represented machine cycle of all 15 currently supported multicycle families.
A four-case native test also checks the enabled falling-boundary sample from
each modeled subphase, including a stalled phase. Complete fetch/execute
overlap, physical pin setup/synchronizer behavior, unsupported
CALA/RET/PUSH/POP cycles, RET resumption, and the provisional
DINT-at-final-boundary ordering remain outside any cycle-accuracy claim.
ADR-0002 and a standalone synthesizable fetch/execute register now establish
the required distinct fetched-word and execute-slot validity/address state.
Directed tests cover priming, overlap, stalls, branch flush, interrupt dummy
suppression, vector capture, and reset.
The separate `tms32010_sequential_pipeline_slice` connects that register to
the core for reset priming and sequential one-cycle instructions. Its fetch
address stays one word ahead of the execute PC, all 43 words in the existing
38-family one-cycle stream match the previously qualified architectural state
at a one-retirement offset, and the wrapper parks before executing a
multicycle branch. It does not yet integrate branch, I/O, table, or interrupt
pipeline sequencing.
Beneath two explicit sequencer assumptions, a 12-step bounded proof checks the
standalone register's transition relation for arbitrary fetch words and
boundaries, with a prime/stall/replace/flush/target cover reached at step 7.
Bounded actual-core formal harnesses check fixed EINT entry,
MPYK-extension/held-low-relatch, direct-MPY/repeated-multiply-chain, and
indirect-MPY/address-update slices across arbitrary clock-enable stalls. Their
12/14/20/20-step bounds and reachable covers are documented in
`formal/README.md`; they are not a general interrupt proof.
`LST` reads one internal word in one cycle, loads `OV`, `OVM`, `ARP`, and
`DP`, and preserves `INTM`. Its indirect next-ARP precedence is explicitly
provisional under `OQ-015`, based on later TI and independent MAME
corroboration because the original-part manuals do not state the precedence.
`SUBC` performs TI's one-cycle conditional subtract/divide step through the
common data-address path. Tests use the documented requirement that its next
instruction not consume ACC; the exact illegal-scheduling result availability
and the precise arithmetic stage that sets sticky `OV` remain explicitly
provisional under `OQ-017` and `OQ-018`.
`SUBH` subtracts the selected word aligned to `ACC[31:16]`. Directed
model/RTL/native and seeded differential tests cover low-half retention,
sticky OV, both wrapped overflow directions, full-accumulator OVM
saturation, and common address updates; `SC-016` records the primary wording
that distinguishes ordinary low-half preservation from saturation.
`BANZ` is the first qualified control-flow instruction. It always performs two
normal program reads: exact opcode `0xf400`, then a canonical 12-bit target
word. It tests the old selected auxiliary-register counter, decrements only
its low nine bits, and selects the target or `PC+2` at the second sample.
Taken and untaken paths both take two cycles. A later first-generation guide's
contradictory full-register wrap example and MAME's shortened untaken timing
are recorded as `SC-011` and `SC-012`.
`B` is exact opcode `0xf900` followed by the same canonical 12-bit target-word
form. It unconditionally loads PC at the second sample, takes two cycles, and
otherwise preserves architectural state.
`BGEZ`, `BGZ`, `BLEZ`, `BLZ`, `BNZ`, and `BZ` test signed/zero ACC
conditions through that same two-read sequence. Both outcomes take two cycles;
MAME's shorter untaken abstraction is disclosed as `SC-013`.
`BV` is exact opcode `0xf500`; it uses the same mandatory second read, tests
sticky OV, and clears OV only when the target path retires. MAME's untaken
timing disagreement is `SC-014`.
`BIOZ` is exact opcode `0xf600` and exposes the raw active-low input through
the portable core. The live level at the second falling-edge target sample
selects target or `PC+2`; both paths take two cycles. MAME's shorter untaken
path is disclosed as `SC-015`.
`CALL` is exact opcode `0xf800` followed by a canonical 12-bit target word.
At the second normal program-read sample it pushes opcode-PC+2 onto the
four-level 12-bit stack and selects the target. Nested-call, stack-overflow,
target-stall, return-address-wrap, and malformed-target cases are automated.
`CALA=0x7f8c` has primary-cited model/tool coverage for pushing opcode-PC+1
and selecting `ACC[11:0]` in two cycles. Its second external program cycle is
unknown, so it has no RTL/native or differential qualification under
`OQ-007`.
`PUSH=0x7f9c` and `POP=0x7f9d` now have primary-cited model/tool coverage for
their complete four-level stack effects and two-cycle totals. Their second
external program cycle is unknown, so neither has RTL/native or differential
qualification under `OQ-016`.
`IN` and `OUT` each perform an ordinary opcode read followed by a distinct
I/O-space cycle. IN asserts DEN and stores the live 16-bit port input into the
old resolved internal-RAM address; OUT asserts WE and drives the selected RAM
word. Both expose the three-bit port separately, apply indirect updates only
at second-cycle retirement, and have directed state, cycle, stall, bus-phase,
and differential tests.
`TBLR` and `TBLW` perform an opcode read, a discarded following-instruction
read, and an `ACC[11:0]` table transfer under MEN or WE. The following address
is then fetched again. Directed and differential tests cover program-memory
mutation, internal RAM, indirect AR/ARP updates, stalls, and the documented
stack-bottom side effect.
Unsupported opcodes,
undocumented SACH shifts, and unresolved RAM addresses trap. A separate
native-phase wrapper qualifies the normal reads for all 38 supported one-cycle
instructions, eleven two-cycle control-flow instructions, and the two
qualified I/O instructions, plus both three-cycle table transfers; it is not
a general pipeline or cycle-accuracy claim.

## Design principles

- Original TI documentation has precedence over secondary implementations.
- Unknown and conflicting behavior is recorded, never silently invented.
- Reference software and RTL remain structurally independent.
- Program, data, and I/O transactions remain externally observable.
- The core uses one clock, synchronous enables, and no gated clocks.
- Vendor-specific resources belong in wrappers, never in the core.
- MAME may be used as a differential oracle but is not copied into this
  MIT-licensed implementation.

## Quick start

Requirements are detected by the build. Python 3 and GNU Make are sufficient
for documentation and model tests; Verilator is used for RTL lint and
simulation; SymbiYosys plus an SMT solver run bounded formal checks; Yosys and
Quartus provide synthesis qualification.

```sh
make test
make lint
make formal
make synth-yosys
```

Use `make help` for the full command list. Missing tools are reported
explicitly. Release qualification never treats an unavailable required tool as
passing evidence.

## References

Copyrighted manuals are not committed unless redistribution permission is
clear. Metadata and hashes live in
[docs/references/manifest.yaml](docs/references/manifest.yaml); authorized
users can populate the ignored `reference-cache/` directory with:

```sh
python3 scripts/fetch_references.py
python3 scripts/verify_reference_hashes.py
```

Downloaded files are data only and are never executed.

## Licensing

Original project source is licensed under the MIT License. Third-party
documents, programs, source code, ROMs, and other materials retain their own
licenses and are not covered by this repository's license. See
[docs/references/README.md](docs/references/README.md).
