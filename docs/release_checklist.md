# Release qualification checklist

## Present status

**NOT RELEASE READY.** This checklist is an evidence index, not a release
claim. The project must not be described as instruction-complete or
cycle-accurate while any required row is incomplete or any cited open question
affects externally observable behavior.

## Automated license and provenance boundary

Run:

```sh
make audit-release
```

The command examines every tracked file plus every nonignored untracked
pre-commit candidate. Policy lives in `docs/release_audit.yaml`. The audit:

- verifies the repository MIT license and copyright record;
- rejects committed reference-cache, Quartus database/output, build, and
  unreviewed artifact paths;
- requires every file under `third_party/` to have explicit license,
  provenance, checksum, and commit-permission metadata;
- rejects binary/manual/ROM candidates unless an explicit checksummed policy
  record permits them;
- inventories generated and hand-maintained canonical data separately;
- hashes every candidate and rejects an exact match to any reference whose
  manifest record has `may_commit: false`.

Passing this audit proves only the checked tracked-file boundary. It cannot
detect unattributed ideas, determine legal compatibility by itself, or replace
human source and license review.

## Release criteria

| Criterion | Status | Current objective evidence or blocker |
|---|---|---|
| Every documented instruction in model, RTL, tools, timing, and bus tests | NOT MET | Model/tools cover all 60 mnemonics; native RTL remains at 58 because PUSH/POP bus ownership is `OQ-016` |
| Every legal encoding and reserved/unlisted behavior qualified | NOT MET | The 65,536-word audit is exhaustive, but 28,656 primary-unlisted and 372 simultaneous-update words retain unknown silicon behavior |
| Complete cycle and fetch/execute timing | NOT MET | Supported one-cycle/control/I/O/table/interrupt slices pass; PUSH/POP and other open timing questions remain |
| Deterministic regressions | PASS FOR CURRENT SCOPE | `make test`; exact counts are maintained in `artifacts/progress.md` |
| Strict lint | PASS FOR CURRENT SCOPE | `make lint`; no current inferred-latch or accidental-clock warning |
| Differential testing | PARTIAL | Model/RTL supported slice and ROM-free MAME adapter pass; complete instruction and long-running oracle coverage remain |
| Formal verification | PARTIAL | Bounds and assumptions are documented in `formal/README.md` and `artifacts/progress.md`; this is not a complete proof |
| Portable Yosys synthesis | PASS FOR CURRENT SCOPE | `make synth-yosys`; qualification inventory is in `synthesis/qualification.md` |
| Quartus fit and constrained timing | PASS FOR CURRENT SCOPE | Current partial design fit/TimeQuest evidence is in `synthesis/qualification.md`; release design is incomplete |
| Native and MiSTer integration documentation | PARTIAL | Native interface and partial Hard Drivin' wrapper are documented; complete board/peripheral integration remains |
| Reference provenance | PASS FOR CATALOGED SOURCES | `make docs` validates the manifest; unavailable and unresolved sources remain disclosed |
| Tracked-file license/provenance audit | PASS FOR CURRENT TREE | `make audit-release`; zero vendored external payloads and zero binary candidates are presently allowed |
| Realistic DSP and Hard Drivin' synthetic programs | PARTIAL | FIR and ROM-free Hard Drivin' smoke pass; authorized-ROM qualification is absent |
| Known-issues and release evidence audit | NOT MET | Open questions and conflicts are documented, but full release evidence is incomplete |

## Strict release command

`make release-check` intentionally remains failing after running its available
verification dependencies. It must not pass until every criterion above has a
reproducible artifact and no undisclosed release blocker remains.
