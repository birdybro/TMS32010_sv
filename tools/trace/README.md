# Trace tools

These helpers analyze user-supplied evidence without assigning undocumented
hardware behavior. They use only Python's standard library and never execute a
captured binary or legacy development tool.

## PUSH/POP physical-capture classifier

`push_pop_capture.py` implements the decoding step in
`docs/research/push_pop_bus_experiment.md`. It recognizes the three retained
`OQ-016` sequences independently for `PUSH` and `POP`:

- H1: inactive first interval, then an active `N+1` read;
- H2: two active reads of `N+1`;
- H3: active reads of `N+1` and then `N+2`.

Any other sequence is reported as `UNCLASSIFIED`; it is not folded into the
nearest hypothesis. H1 is reported with the explicit conflict against
SPRU001B's every-machine-cycle `MEN` rule. Active `WE` or `DEN`, active reset,
or program data that disagrees with the checked fixture is also retained as a
warning rather than silently reinterpreted.

The input is a normalized CSV with exactly one row per falling `CLKOUT`
boundary and this exact header:

```text
run,sample,time_ns,rs_n,men_n,we_n,den_n,address,data
```

`run` identifies an independent reset-to-loop capture. `sample` and
`time_ns` must increase strictly within each run. Control columns contain `0`
or `1`; active-low signals therefore contain `0` when asserted. Addresses and
data must be `0x`-prefixed hexadecimal. The normalizer used for a particular
logic analyzer remains part of the evidence package, and the original raw
transition file must be retained; this classifier does not treat normalized
rows as the raw evidence.

Run an exploratory classification with:

```sh
python3 -m tools.trace.push_pop_capture normalized.csv
```

The JSON result hashes the normalized capture, lists both intervals from every
run, reports repeatability, and states its claim boundary. With no provenance
sidecar, `review_ready` is intentionally false.

For the complete package check, supply 32 or more runs plus:

```sh
python3 -m tools.trace.push_pop_capture normalized.csv \
  --metadata metadata.json \
  --program-image push_pop_bus_probe.bin \
  --artifact-root capture-artifacts \
  --require-review-ready
```

The metadata JSON schema is:

```json
{
  "schema_version": 1,
  "device_marking": "complete package text with line breaks",
  "specimen_id": "local stable identifier",
  "tracking_date_string": "raw undecoded string",
  "lot_string": "raw undecoded string",
  "package_type": "observed package",
  "acquisition_provenance": "custody/source record",
  "socketed": true,
  "temperature_c": 25.0,
  "reset_duration_cycles": 8,
  "monitor_revision": "monitor identity or none",
  "specimen_scope": "this_specimen_only",
  "board_revision": "board and revision",
  "oscillator_hz": 20000000,
  "supply_voltage_v": "measured value and instrument",
  "program_memory": "device type and access time",
  "probe_model": "probe model",
  "analyzer_model": "analyzer model",
  "analyzer_firmware": "firmware version",
  "program_image_sha256": "lowercase SHA-256 of the supplied image file",
  "normalized_capture_sha256": "lowercase SHA-256 of normalized.csv",
  "fixture_tool_versions": {
    "assembler": "version/commit",
    "capture_normalizer": "version/commit",
    "analyzer_decoder": "version/commit"
  },
  "fixture_artifacts": {
    "source": {"path": "fixture/push_pop_bus_probe.asm", "sha256": "..."},
    "listing": {"path": "fixture/push_pop_bus_probe.lst", "sha256": "..."}
  },
  "signal_pin_map": {
    "CLKOUT": "physical pin/channel",
    "MEN_N": "physical pin/channel",
    "WE_N": "physical pin/channel",
    "DEN_N": "physical pin/channel",
    "RS_N": "physical pin/channel",
    "A11:A0": "physical pins/channels",
    "D15:D0": "physical pins/channels"
  },
  "raw_artifacts": {
    "raw/capture.sal": "lowercase SHA-256"
  },
  "probe_photographs": {
    "photos/probe-placement.jpg": "lowercase SHA-256"
  },
  "specimen_photographs": {
    "top": {"path": "photos/specimen-top.jpg", "sha256": "..."},
    "bottom": {"path": "photos/specimen-bottom.jpg", "sha256": "..."},
    "board_context": {"path": "photos/specimen-board.jpg", "sha256": "..."}
  }
}
```

The image must also match the independently checked exact 16-byte fixture and
the retained listing must contain its exact eight address/word pairs;
rehashing different bytes or unrelated text in the metadata cannot qualify
them. Every artifact
path is resolved beneath `--artifact-root`, and every hash is recomputed. Path
traversal, missing files, malformed hashes, inconsistent runs, truncated
windows, duplicate triggers, and malformed CSV fail closed.

`review_ready` means only that the package is complete, repeatable, and matches
one retained hypothesis for each instruction. It does not resolve `OQ-016`,
prove `OQ-008` mask-revision invariance, generalize beyond the identified
specimen, or establish `VERIFIED_HARDWARE`. The report always leaves
`acceptance_complete=false`. Engineering review must still inspect the raw
transitions, probe loading, board identity, and the relationship between bus
reads and subsequent execution.

`specimen_evidence.py` provides the reusable subset of these checks for other
original-device experiments. In addition to the fields shown above, migrated
workflows require numeric `program_memory_access_time_ns`. The helper binds
the normalized trace, exact project source and address/word listing, raw
tracking/lot strings, test conditions and tool versions, and distinct
top/bottom/board photographs to `specimen_scope=this_specimen_only`. It does
not identify a mask or interpret a tracking string. Each experiment must still
check its exact image and its own signals, anchors, repetitions, and result
criteria.

## SUBC physical-capture classifier

`subc_capture.py` consumes the same strict falling-`CLKOUT` CSV and metadata
schema. It has two explicitly selected modes:

- `dependency` checks the two OUT-opcode fetches in
  `subc_dependency_probe.asm`, preserves the first port-7 word without an
  expected result, and requires the NOP-separated comparator to be `0x000b`;
- `overflow` checks the two OUT-opcode fetches in
  `subc_overflow_stage_probe.asm`, interprets architectural `OV` at status
  word bit 15, and classifies all four `(first OV, second OV)` pairs.

The dependency result is labeled as old-low-word, trial-low-word,
final-low-word, or `OTHER_LOW_0x....`. An arbitrary other word is not rejected:
the violating sequence is undocumented, so a repeatable unanticipated value
is evidence to retain. Runs disagreeing on the exact classification are not
repeatable.

The overflow fixture validates every known status-word bit except `OV` and
reserved bit 1. Bit 1 is intentionally masked because its physical SST output
remains only CORROBORATED under `SC-008`; the tool may not turn that separate
question into a reason to discard a SUBC capture. The fixture explicitly loads
ARP zero so `OQ-012` reset retention cannot leak into the comparison. Status
bit 12 is fixed one, not `OV`.

Build the exact big-endian images and classify captures with:

```sh
python3 -m tools.assembler.tms32010_as \
  tests/asm/subc_dependency_probe.asm \
  --binary subc_dependency_probe.bin --byteorder big
python3 -m tools.trace.subc_capture dependency.csv \
  --experiment dependency \
  --metadata dependency-metadata.json \
  --program-image subc_dependency_probe.bin \
  --artifact-root capture-artifacts \
  --require-review-ready
```

Use `--experiment overflow` and the overflow probe image for the second
fixture. In addition to the sidecar SHA-256 check, the tool compares the
supplied binary byte-for-byte with the independently checked fixture word
list. It requires exactly two exclusive port-write samples, their checked
program-fetch anchors in order, two following falling boundaries, at least 32
runs by default, stable classification, valid fixture consistency checks, and
complete raw/photo provenance. For each independently captured fixture, the
shared specimen validator additionally binds the normalized trace, exact
project source and complete listing, numeric program-memory access time, raw
package/date/lot record, fixture tool versions, and distinct
top/bottom/board-context photographs to one named specimen.

`review_ready` is evidence-package status only. It does not change `OQ-017`
or `OQ-018`, establish which internal phase produced a captured word, prove
`OQ-008` mask-revision invariance, generalize beyond the named specimen, or
establish `VERIFIED_HARDWARE`. The report always leaves
`acceptance_complete=false`. The official TI simulator's stop code `9950` is
not an expected physical result and is not an input to the classifier.

## DINT/interrupt-boundary physical-capture classifier

`dint_interrupt_capture.py` checks the `OQ-019` fixture without adopting the
current RTL cancellation policy or IKA's entry policy as an oracle. It retains
the complete port-7 sequence and recognizes only:

- `0033,0022`: DINT-cancels-entry candidate;
- `0033,001c,0011,0022`: entry with original Figure 2-12 N+2 return;
- `0033,001b,0011,0022`: earlier entry with N+1 return.

Every other complete sequence is serialized as `OTHER_SEQUENCE_...` and is
never folded into a known candidate. A stable other sequence is repeatable but
does not set `candidate_resolved` or `review_ready`.

The falling-boundary CSV adds sampled `INT_N` to the common bus columns:

```text
run,sample,time_ns,rs_n,int_n,men_n,we_n,den_n,address,data
```

The classifier requires a second derived CSV containing one independently
measured pulse per run:

```text
run,int_assert_ns,int_release_ns,int_fall_time_ns
```

The normalizer must use a documented threshold for assertion/release and a
10%-to-90% falling-edge measurement. It must reject additional transitions;
it may not omit them to satisfy this schema. The tool recomputes setup from
the checked `ARM_WINDOW` falling boundary, pulse width from the two transition
times, and a local `CLKOUT` period from adjacent falling boundaries. It
requires at least 50 ns setup, at least one local `CLKOUT` period low, no more
than 15 ns fall time, and consistency between the transition interval and
every sampled `INT_N` value. These derived files do not replace raw waveforms.

Build and check the exact sparse big-endian image with:

```sh
python3 -m tools.assembler.tms32010_as \
  tests/asm/dint_interrupt_race_probe.asm \
  --binary dint_interrupt_race_probe.bin --byteorder big
python3 -m tools.trace.dint_interrupt_capture normalized.csv \
  --pulse-measurements pulse-measurements.csv \
  --metadata metadata.json \
  --program-image dint_interrupt_race_probe.bin \
  --artifact-root capture-artifacts \
  --require-review-ready
```

In addition to the common metadata fields, the sidecar requires:

```json
{
  "interrupt_driver_circuit": "open-collector-compatible circuit",
  "interrupt_driver_voltage_v": "measured level and instrument",
  "pulse_generator_model": "model and firmware",
  "pulse_measurements_sha256": "lowercase SHA-256",
  "signal_pin_map": {
    "INT_N": "physical pin/channel"
  },
  "calibrations": {
    "no_pulse": {"path": "cal/no-pulse.sal", "sha256": "..."},
    "one_fetch_earlier": {"path": "cal/early.sal", "sha256": "..."},
    "one_fetch_later": {"path": "cal/late.sal", "sha256": "..."}
  }
}
```

The full `signal_pin_map` still needs every common bus signal. Calibration,
raw-capture, and photograph paths are confined beneath the artifact root and
rehashed. The classifier checks exact `ARM_WINDOW`/`RACING_DINT` fetches,
exclusive port-7 outputs bracketing the race, terminal flow, 32 stable runs,
the exact project-authored image, and the complete evidence package.

`review_ready` remains package status only. It does not change `OQ-019`, prove
which internal edge has priority, qualify an omitted or malformed pulse,
establish mask invariance, or establish `VERIFIED_HARDWARE`.

## Indirect-LST ARP-precedence physical-capture classifier

`lst_arp_capture.py` checks the two-direction `OQ-015` fixture without treating
MAME's memory-word precedence or IKA's encoded-field precedence as an oracle.
It recognizes:

- `0033,00a0,00b1`: memory-word ARP wins both directions;
- `0033,00a1,00b0`: encoded next ARP wins both directions;
- `0033,00a0,00b0`: case A memory, case B encoded;
- `0033,00a1,00b1`: case A encoded, case B memory.

Mixed outcomes are preserved as explicit classifications. They may be stable
and fixture-valid, but cannot set `candidate_resolved` or `review_ready`
because the experiment's acceptance rule requires both directions to agree.
Any other complete sequence is retained verbatim as `OTHER_SEQUENCE_...`.

The tool consumes the common falling-`CLKOUT` CSV and evidence metadata. It
checks the exact three OUT fetch addresses and words, their order relative to
exactly three exclusive port-7 writes, the `0x0033` armed marker, two retained
terminal boundaries, at least 32 stable runs, exact big-endian program bytes,
and program/raw/photo hashes beneath the artifact root. The shared specimen
validator additionally binds the normalized trace, exact project source and
30-word listing, numeric program-memory access time, raw package/date/lot
record, fixture tool versions, and distinct top/bottom/board-context
photographs to one named specimen.

```sh
python3 -m tools.assembler.tms32010_as \
  tests/asm/lst_arp_precedence_probe.asm \
  --binary lst_arp_precedence_probe.bin --byteorder big
python3 -m tools.trace.lst_arp_capture normalized.csv \
  --metadata metadata.json \
  --program-image lst_arp_precedence_probe.bin \
  --artifact-root capture-artifacts \
  --require-review-ready
```

`review_ready` remains evidence-package status only. It does not change
`OQ-015`, select MAME or IKA as an original-part oracle, prove mask-revision
invariance, generalize beyond the named specimen, or establish
`VERIFIED_HARDWARE`. The report always leaves `acceptance_complete=false`.

## Simultaneous auxiliary-register update physical-capture classifier

`simultaneous_ar_capture.py` checks the raw-word `OQ-010` fixture without
assuming that unsupported word `0x68b8` retires normally. It recognizes the
three complete priority hypotheses:

- `0033,0000,01ff`: no net update;
- `0033,0001,0000`: increment priority;
- `0033,01ff,01fe`: decrement priority.

An armed-marker-only run, a first result without the second forced-word fetch,
and a first result followed by that fetch but no second result are retained as
three distinct `NONCOMPLETION_...` classifications. Stable partial captures
remain `candidate_resolved=false` and can never become `review_ready`. Any
other complete sequence is retained verbatim as `OTHER_SEQUENCE_...`.

The tool consumes the common falling-`CLKOUT` CSV and evidence metadata. It
checks the exact armed/result/forced-word fetch anchors and ordering, exclusive
port-7 writes, four retained boundaries after the last forced-word or output
event, complete-flow terminal branch, at least 32 stable runs, exact big-endian
program bytes, and program/raw/photo hashes beneath the artifact root. The
shared specimen validator additionally requires the normalized-capture hash,
exact project source and 23-word listing, raw package/date/lot record,
program-memory access time, fixture tool versions, and distinct specimen
top/bottom/board-context photographs.

```sh
python3 -m tools.assembler.tms32010_as \
  tests/asm/simultaneous_ar_update_probe.asm \
  --binary simultaneous_ar_update_probe.bin --byteorder big
python3 -m tools.trace.simultaneous_ar_capture normalized.csv \
  --metadata metadata.json \
  --program-image simultaneous_ar_update_probe.bin \
  --artifact-root capture-artifacts \
  --require-review-ready
```

`review_ready` remains evidence-package status only. It does not change
`OQ-010`, make `0x68b8` supported, choose MAME or IKA as an original-part
oracle, prove `OQ-008` mask-revision invariance, generalize beyond the named
specimen, or establish `VERIFIED_HARDWARE`. The report always leaves
`acceptance_complete=false`.

## DMOV/LTD RAM-boundary physical-capture normalizer

`ram_boundary_capture.py` consumes the paired fixed-image `OQ-014` DMOV and
LTD captures. For every run it retains the complete port-7 output sequence,
hashes the 144-word valid-RAM scan, lists each changed valid address, records
the unconstrained diagnostic `0x90` word, and checks the exact boundary,
scan-OUT, diagnostic-OUT, and terminal fetch order. Partial scan,
scan-complete/no-diagnostic, and extra-output flows remain explicit rather
than being coerced to one of the experiment's hypotheses.

The separate EVM register-observation CSV has this exact header:

```text
experiment,run,acc,t,p,ov,ovm,dp,arp,ar0,ar1,transcript_sha256
```

Values use `0x`-prefixed fixed-width-compatible hexadecimal, except the four
one-bit fields. Each row must match one capture run, and its transcript hash
must occur in that experiment's validated `raw_artifacts`. Both metadata
sidecars must additionally set `register_observations_sha256` to the CSV's
lowercase SHA-256. The normalizer checks only fixture-determined register
state: ACC/T/P, DP, ARP, and AR0. It records OV, OVM, and AR1 verbatim because
their retained/reset input state is not established by these programs.

```sh
python3 -m tools.assembler.tms32010_as \
  tests/asm/ram_boundary_dmov_probe.asm \
  --binary ram_boundary_dmov_probe.bin --byteorder big
python3 -m tools.assembler.tms32010_as \
  tests/asm/ram_boundary_ltd_probe.asm \
  --binary ram_boundary_ltd_probe.bin --byteorder big
python3 -m tools.trace.ram_boundary_capture dmov.csv ltd.csv \
  --dmov-metadata dmov-metadata.json \
  --ltd-metadata ltd-metadata.json \
  --dmov-image ram_boundary_dmov_probe.bin \
  --ltd-image ram_boundary_ltd_probe.bin \
  --register-observations registers.csv \
  --artifact-root capture-artifacts \
  --require-review-ready
```

Unlike the priority classifiers, `review_ready` deliberately does not require
repeatable data or agreement with documented parallel effects: variation,
aliasing, corruption, or coupled state is the evidence being measured. It
means only that both fixed baselines have complete 32-run capture/register/
provenance packages. The report therefore always leaves
`acceptance_complete=false`; the varied-history/sentinel work, engineering
review, a second specimen, and `OQ-008` mask scope remain outstanding.

## Absent-RAM controlled-history read classifier

`ram_invalid_read_capture.py` qualifies only nondestructive stage 1 of the
`OQ-002` experiment. It checks the exact 35-word image and all 451 ordered
port-7 outputs: marker `0031`, 112 zero-predecessor/absent-read pairs, marker
`0032`, 112 one-predecessor/absent-read pairs, and marker `003f`. Every OUT
fetch/write pair and the terminal branch are framed explicitly.

For each address `0x90`-`0xff`, the report retains both raw words and assigns
one descriptive relationship:

- `PREDECESSOR_TRACKING` when the readings are `0000` then `ffff`;
- `HISTORY_INDEPENDENT_xxxx` when both readings match one another;
- `HISTORY_DEPENDENT_xxxx_yyyy` for every other pair.

These labels describe measurements; none proves open bus, hidden storage, or
an alias. Complete runs may vary and still qualify for review. Partial and
extra output streams remain explicit but cannot become review-ready.

The ordinary evidence metadata must add a `run_conditions` object mapping
every capture run to exactly `reset` or `cold_power`. Defaults require at
least 32 reset-and-execute trials and eight cold-power trials.

```sh
python3 -m tools.assembler.tms32010_as \
  tests/asm/ram_invalid_read_sweep_probe.asm \
  --binary ram_invalid_read_sweep_probe.bin --byteorder big
python3 -m tools.trace.ram_invalid_read_capture read-sweep.csv \
  --metadata read-sweep-metadata.json \
  --program-image ram_invalid_read_sweep_probe.bin \
  --artifact-root capture-artifacts \
  --require-review-ready
```

`review_ready` means only that the fixed stage-1 package is structurally and
provenance complete. The report always leaves `acceptance_complete=false`:
both destructive write directions, any indicated single-target follow-up,
raw engineering review, and another original specimen remain outstanding.

## Absent-RAM paired sentinel-write normalizer

`ram_invalid_write_capture.py` qualifies the ascending and descending stage-2
fixtures together. Each run retains all 258 port-7 words: its direction marker,
144 descending valid-RAM samples, 112 direction-ordered absent readbacks, and
the terminal marker. The report lists every nonzero valid address and records,
for every absent address, its intended unique sentinel, measured value, and a
descriptive `STORED_SENTINEL`, `ZERO_VALUE`, or `OTHER_xxxx` relationship.
None of those labels alone proves storage, suppression, or an alias.

Both ordinary evidence metadata files must add:

```json
{
  "prior_read_report_sha256": "lowercase SHA-256",
  "capture_stage": "write_after_pinned_read_only"
}
```

The supplied prior report must be a structurally complete, review-ready output
from `ram_invalid_read_capture.py` with its acceptance still incomplete. This
creates an auditable workflow link. A file hash and operator declaration do
not independently prove that the read-only physical capture occurred first;
raw timestamps, setup records, and engineering review remain necessary.

```sh
python3 -m tools.trace.ram_invalid_write_capture ascending.csv descending.csv \
  --ascending-metadata ascending-metadata.json \
  --descending-metadata descending-metadata.json \
  --ascending-image ram_invalid_write_ascending_probe.bin \
  --descending-image ram_invalid_write_descending_probe.bin \
  --prior-read-report read-stage-report.json \
  --artifact-root capture-artifacts \
  --require-review-ready
```

No primary source sets a write-trial minimum, so the tool defaults to one
complete run per direction rather than inventing a count; `--minimum-runs`
can enforce a documented experiment plan. Complete results may vary without
blocking review. `acceptance_complete=false` remains mandatory until raw
review, any alias-directed single-target/alternate-sentinel follow-up, and a
second identified original specimen are complete.

## Physical-reset retention normalizer

`reset_retention_capture.py` qualifies the complementary `OQ-012` set/clear
fixtures without requiring the post-reset vector to match the current
PROVISIONAL model/RTL retention policy. It checks all 28 port-7 writes and
their exact fetch anchors, both BIOZ path selections, the armed/terminal
markers, the reset hold loop, and the post-reset target. The falling-boundary
CSV has this exact header:

```text
run,sample,time_ns,rs_n,bio_n,men_n,we_n,den_n,address,data
```

An independently derived transition file accompanies each fixture:

```text
run,rs_assert_ns,rs_release_ns,bio_assert_ns
```

The normalizer requires BIO to change only after the armed marker and before
RS assertion, checks every sampled level against those transition times, and
counts complete low-reset intervals between adjacent falling `CLKOUT`
boundaries. Beginning with the first completed interval it checks the primary
reset bus contract: inactive `MEN`, `DEN`, and `WE`, plus address zero. The
first sampled-low boundary remains recorded but is not silently treated as a
complete reset interval.

In addition to the common provenance fields, each metadata sidecar requires:

```json
{
  "reset_driver_circuit": "driver and electrical arrangement",
  "bio_driver_circuit": "driver and electrical arrangement",
  "reset_measurements_sha256": "lowercase SHA-256",
  "signal_pin_map": {"BIO_N": "physical pin/channel"},
  "run_conditions": {
    "run-00": {
      "clock_condition": "nominal",
      "reset_hold_target_cycles": 5
    }
  }
}
```

`clock_condition` is exactly `slow_limit`, `nominal`, or `fast_limit`; the raw
falling-boundary times remain the measured clock evidence. The ordinary
`oscillator_hz` field records the nominal setup. Review qualification requires
32 nominal runs per fixture and at least one run for every combination of the
three clock conditions and 5-, 8-, and 32-cycle reset targets. The observed
clock-period ranges must order slow greater than nominal greater than fast.

```sh
python3 -m tools.trace.reset_retention_capture set.csv clear.csv \
  --set-reset-measurements set-reset.csv \
  --clear-reset-measurements clear-reset.csv \
  --set-metadata set-metadata.json \
  --clear-metadata clear-metadata.json \
  --set-image reset_retention_set_probe.bin \
  --clear-image reset_retention_clear_probe.bin \
  --artifact-root capture-artifacts \
  --require-review-ready
```

Every complete post-reset vector is retained raw and decomposed into ACC, P,
T, AR0/AR1, OV, OVM, ARP, DP, and all four stack levels. Reserved SST bit 1 is
reported independently. Variation and non-retention do not block review;
only OVM is an expected retention control because SPRU001B explicitly says it
is unchanged. `observed_full_retention_candidate` is descriptive package
output, and `acceptance_complete=false` remains mandatory until raw review and
a second identified original specimen are complete.

## Driver Sound DAC code helper

`hard_drivin_dac_codes.py` keeps A044427's raw twelve-bit Am6012 input separate
from MAME's sign-bit-remapped value and the signed software interpretation.
Its ideal analog values are calculations, not measurements.
