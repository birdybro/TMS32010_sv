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

The canonical status and evidence links are in
`docs/release_evidence.yaml`. This table is deliberately redundant and is
checked against that inventory by `make audit-release` so that neither version
can drift silently.

| ID | Criterion | Status | Current objective evidence or blocker |
|---|---|---|---|
| `instruction_completeness` | Complete instruction implementation and qualification | NOT_MET | Model/tools cover all 60 mnemonics; native RTL remains at 58, with PUSH/POP blocked by `OQ-016` and unlisted/simultaneous-update silicon behavior unqualified |
| `cycle_timing_completeness` | Complete instruction and external timing qualification | NOT_MET | Supported timing slices pass, but PUSH/POP and other open timing questions remain |
| `clean_lint` | Strict Python and RTL lint | PASS_CURRENT_SCOPE | `make lint` passes for the partial design; `RTL-002` and `REL-001` remain |
| `passing_regressions` | Complete available deterministic regression suite | PASS_CURRENT_SCOPE | `make test`; exact current counts are in `artifacts/progress.md` |
| `differential_tests` | Model, RTL, and reliable-oracle differential qualification | PARTIAL | Current supported slice and ROM-free MAME adapter pass; complete coverage remains |
| `formal_checks` | Documented bounded formal checks | PARTIAL | Present bounds pass, but this is not a complete proof and `FORMAL-001` remains |
| `yosys_synthesis` | Portable Yosys synthesis | PASS_CURRENT_SCOPE | Current partial design passes; release-design qualification remains |
| `quartus_synthesis` | Quartus fit and TimeQuest | PASS_CURRENT_SCOPE | Current partial design passes; release-design qualification remains |
| `no_inferred_latches` | No inferred latches | PASS_CURRENT_SCOPE | Current lint and synthesis evidence pass; full RTL is incomplete |
| `no_accidental_clocks` | No gated or accidental clocks | PASS_CURRENT_SCOPE | Current lint and synthesis evidence pass; full RTL is incomplete |
| `constrained_timing_paths` | No unconstrained primary timing path | PASS_CURRENT_SCOPE | Current Quartus design has constrained clocks; final RTL is incomplete |
| `resource_utilization` | Release-design utilization documented | PASS_CURRENT_SCOPE | Current partial-design utilization is recorded; final figures remain |
| `maximum_clock_frequency` | Fitted maximum clock rate documented | PASS_CURRENT_SCOPE | Current fitted timing is recorded; final figures remain |
| `integration_guide` | Complete generic and MiSTer integration guide | PARTIAL | Native and partial Hard Drivin' wrappers are documented; complete integration remains |
| `programming_model` | Complete original-device programming model | PARTIAL | The supported subset is cited; architecture and ISA work remain |
| `native_interface_specification` | Complete native-interface specification | PARTIAL | The current phase contract is tested; unresolved pin behavior remains |
| `known_issues` | Current known-issue and conflict register | PASS_CURRENT_SCOPE | Open questions and conflicts are checked, but architecture research is ongoing |
| `reproducible_toolchain` | Reproducible release toolchain | PARTIAL | Open-source CI is defined; complete release and synthesis qualification remain |
| `license_and_provenance` | License and reference-provenance audit | PASS_CURRENT_SCOPE | `make audit-release` passes for the current candidate tree; final human audit remains |
| `realistic_dsp_program` | Realistic DSP program | PASS_CURRENT_SCOPE | The deterministic four-tap FIR program passes for the current implementation |
| `hard_drivin_qualification` | Legal Hard Drivin'-oriented test | PASS_CURRENT_SCOPE | The ROM-free synthetic smoke program passes; full board qualification remains |

## Strict release command

`make release-check` intentionally remains failing after running its available
verification dependencies. It must not pass until every criterion above has a
reproducible artifact and no undisclosed release blocker remains.
