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

The reference model, local tools, and partial RTL currently support seventeen
instructions: `ADDS`, `AND`, `LAC`, `LACK`, `LARK`, `LARP`, `LDPK`, `NOP`,
`OR`, `ROVM`, `SACL`, `SACH`, `SOVM`, `XOR`, `ZAC`, `ZALH`, and `ZALS`. The
144-word internal RAM exposes verification-visible logical
`ADDS`/`AND`/`LAC`/`OR`/`XOR`/`ZALH`/`ZALS` reads and `SACL`/`SACH` writes;
unsupported opcodes, undocumented SACH shifts, and unresolved RAM addresses
trap. A
separate native-phase wrapper qualifies normal sequential program reads for
this seventeen-instruction subset only; it is not a general
pipeline or cycle-accuracy claim.

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
