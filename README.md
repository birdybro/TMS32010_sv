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

The reference model, local tools, and partial RTL currently support forty-seven
instructions: `ADD`, `ADDS`, `AND`, `APAC`, `B`, `BANZ`, `BGEZ`, `BGZ`, `BIOZ`, `BLEZ`, `BLZ`, `BNZ`, `BV`, `BZ`, `DINT`, `DMOV`, `EINT`, `LAC`, `LACK`, `LAR`, `LARK`, `LARP`,
`LDP`, `LDPK`, `LST`, `LT`, `LTA`, `LTD`, `MAR`, `MPY`, `MPYK`, `NOP`, `OR`, `PAC`, `ROVM`, `SACL`,
`SACH`, `SAR`, `SOVM`, `SPAC`, `SUB`, `SUBC`, `SUBS`, `XOR`, `ZAC`, `ZALH`, and `ZALS`. The 144-word
internal RAM exposes verification-visible logical
`ADD`/`ADDS`/`AND`/`DMOV`/`LAC`/`LAR`/`LDP`/`LST`/`LT`/`LTA`/`LTD`/`MPY`/`OR`/`SUB`/
`SUBC`/`SUBS`/`XOR`/`ZALH`/`ZALS` reads and `DMOV`/`LTD`/`SACL`/`SACH`/`SAR` writes;
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
program-only cycle. Interrupt input recognition, EINT's following-instruction
service delay, stack entry, and vector fetch are not implemented.
`LST` reads one internal word in one cycle, loads `OV`, `OVM`, `ARP`, and
`DP`, and preserves `INTM`. Its indirect next-ARP precedence is explicitly
provisional under `OQ-015`, based on later TI and independent MAME
corroboration because the original-part manuals do not state the precedence.
`SUBC` performs TI's one-cycle conditional subtract/divide step through the
common data-address path. Tests use the documented requirement that its next
instruction not consume ACC; the exact illegal-scheduling result availability
and the precise arithmetic stage that sets sticky `OV` remain explicitly
provisional under `OQ-017` and `OQ-018`.
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
Unsupported opcodes,
undocumented SACH shifts, and unresolved RAM addresses trap. A separate
native-phase wrapper qualifies the normal reads for all 37 supported one-cycle
instructions and the ten qualified two-cycle branches; it is not a general pipeline or
cycle-accuracy claim.

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
simulation; Yosys and Quartus are optional until their qualification
milestones.

```sh
make test
make lint
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
