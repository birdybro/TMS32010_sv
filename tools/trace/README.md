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
  "device_marking": "complete package marking",
  "board_revision": "board and revision",
  "oscillator_hz": 20000000,
  "supply_voltage_v": "measured value and instrument",
  "program_memory": "device type and access time",
  "probe_model": "probe model",
  "analyzer_model": "analyzer model",
  "analyzer_firmware": "firmware version",
  "program_image_sha256": "lowercase SHA-256 of the supplied image file",
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
  }
}
```

Every artifact path is resolved beneath `--artifact-root`, and every hash is
recomputed. Path traversal, missing files, malformed hashes, inconsistent
runs, truncated windows, duplicate triggers, and malformed CSV fail closed.

`review_ready` means only that the package is complete, repeatable, and matches
one retained hypothesis for each instruction. It does not resolve `OQ-016`,
prove mask-revision invariance, or establish `VERIFIED_HARDWARE`. Engineering
review must still inspect the raw transitions, probe loading, board identity,
and the relationship between bus reads and subsequent execution.

## Driver Sound DAC code helper

`hard_drivin_dac_codes.py` keeps A044427's raw twelve-bit Am6012 input separate
from MAME's sign-bit-remapped value and the signed software interpretation.
Its ideal analog values are calculations, not measurements.
