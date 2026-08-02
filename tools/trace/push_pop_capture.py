#!/usr/bin/env python3
"""Classify normalized original-TMS32010 PUSH/POP program-bus captures.

This tool does not manufacture an expected native sequence.  It recognizes
the three hypotheses retained by ``OQ-016``, reports every sampled value, and
checks that a physical-evidence package is reproducible enough for review.
Human review is still required before changing architectural confidence.
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import asdict, dataclass
from decimal import Decimal, InvalidOperation
from hashlib import sha256
import json
from math import isfinite
from pathlib import Path
import re
import sys
from typing import Mapping, Sequence, TextIO


FIXTURE_WORDS = {
    0x000: 0x7E55,
    0x001: 0x7F9C,
    0x002: 0x7F80,
    0x003: 0x7EAA,
    0x004: 0x7F9D,
    0x005: 0x7F80,
    0x006: 0xF900,
    0x007: 0x0006,
}

CAPTURE_COLUMNS = (
    "run",
    "sample",
    "time_ns",
    "rs_n",
    "men_n",
    "we_n",
    "den_n",
    "address",
    "data",
)

H1_IDLE = "H1_INACTIVE_FIRST_INTERVAL"
H2_REPEAT = "H2_REPEATED_N_PLUS_1"
H3_ADVANCE = "H3_ADVANCING_N_PLUS_1_N_PLUS_2"
UNCLASSIFIED = "UNCLASSIFIED"
KNOWN_HYPOTHESES = frozenset((H1_IDLE, H2_REPEAT, H3_ADVANCE))

REQUIRED_METADATA_TEXT = (
    "device_marking",
    "board_revision",
    "supply_voltage_v",
    "program_memory",
    "probe_model",
    "analyzer_model",
    "analyzer_firmware",
)
REQUIRED_SIGNAL_MAP = (
    "CLKOUT",
    "MEN_N",
    "WE_N",
    "DEN_N",
    "RS_N",
    "A11:A0",
    "D15:D0",
)
SHA256_PATTERN = re.compile(r"[0-9a-f]{64}")


class CaptureError(ValueError):
    """Raised when a normalized capture violates its declared schema."""


@dataclass(frozen=True)
class EdgeSample:
    """Signal values at one falling CLKOUT boundary."""

    run: str
    sample: int
    time_ns: Decimal
    rs_n: int
    men_n: int
    we_n: int
    den_n: int
    address: int
    data: int


@dataclass(frozen=True)
class InstructionSpec:
    mnemonic: str
    opcode_address: int

    @property
    def opcode(self) -> int:
        return FIXTURE_WORDS[self.opcode_address]

    @property
    def next_address(self) -> int:
        return (self.opcode_address + 1) & 0xFFF

    @property
    def advance_address(self) -> int:
        return (self.opcode_address + 2) & 0xFFF


INSTRUCTIONS = (
    InstructionSpec("PUSH", 0x001),
    InstructionSpec("POP", 0x004),
)


@dataclass(frozen=True)
class Observation:
    """Two observed intervals following one exact PUSH or POP fetch."""

    run: str
    mnemonic: str
    opcode_sample: int
    classification: str
    first_interval: EdgeSample
    second_interval: EdgeSample
    warnings: tuple[str, ...]


@dataclass(frozen=True)
class EvidencePackage:
    """Machine-checkable status of the physical-capture sidecar artifacts."""

    complete: bool
    errors: tuple[str, ...]
    program_image_sha256: str | None
    verified_artifacts: tuple[str, ...]


@dataclass(frozen=True)
class CaptureReport:
    """Aggregate classification without an architectural confidence claim."""

    capture_sha256: str
    run_count: int
    minimum_runs: int
    minimum_runs_met: bool
    repeatable: bool
    hypotheses_resolved: bool
    primary_source_conflict_observed: bool
    review_ready: bool
    classifications: Mapping[str, tuple[str, ...]]
    observations: tuple[Observation, ...]
    evidence_package: EvidencePackage

    def to_json_object(self) -> dict[str, object]:
        """Return a stable JSON-ready representation with explicit claim scope."""

        return {
            "schema_version": 1,
            "claim_boundary": (
                "Classification and package validation only; this output does not "
                "change OQ-016 or establish VERIFIED_HARDWARE without engineering "
                "review of the raw capture and physical setup."
            ),
            "capture_sha256": self.capture_sha256,
            "run_count": self.run_count,
            "minimum_runs": self.minimum_runs,
            "minimum_runs_met": self.minimum_runs_met,
            "repeatable": self.repeatable,
            "hypotheses_resolved": self.hypotheses_resolved,
            "primary_source_conflict_observed": (
                self.primary_source_conflict_observed
            ),
            "review_ready": self.review_ready,
            "classifications": {
                mnemonic: list(values)
                for mnemonic, values in sorted(self.classifications.items())
            },
            "observations": [
                {
                    **asdict(observation),
                    "first_interval": _sample_json(observation.first_interval),
                    "second_interval": _sample_json(observation.second_interval),
                    "warnings": list(observation.warnings),
                }
                for observation in self.observations
            ],
            "evidence_package": {
                "complete": self.evidence_package.complete,
                "errors": list(self.evidence_package.errors),
                "program_image_sha256": (
                    self.evidence_package.program_image_sha256
                ),
                "verified_artifacts": list(
                    self.evidence_package.verified_artifacts
                ),
            },
        }


def _sample_json(sample: EdgeSample) -> dict[str, object]:
    return {
        "run": sample.run,
        "sample": sample.sample,
        "time_ns": str(sample.time_ns),
        "rs_n": sample.rs_n,
        "men_n": sample.men_n,
        "we_n": sample.we_n,
        "den_n": sample.den_n,
        "address": f"0x{sample.address:03x}",
        "data": f"0x{sample.data:04x}",
    }


def _parse_decimal_integer(token: str, name: str, row_number: int) -> int:
    if not re.fullmatch(r"0|[1-9][0-9]*", token):
        raise CaptureError(f"row {row_number}: {name} must be a decimal integer")
    return int(token, 10)


def _parse_binary(token: str, name: str, row_number: int) -> int:
    if token not in ("0", "1"):
        raise CaptureError(f"row {row_number}: {name} must be 0 or 1")
    return int(token)


def _parse_hex(token: str, digits: int, name: str, row_number: int) -> int:
    if not re.fullmatch(rf"0x[0-9a-fA-F]{{1,{digits}}}", token):
        raise CaptureError(
            f"row {row_number}: {name} must use a 0x-prefixed hexadecimal value"
        )
    return int(token, 16)


def read_normalized_capture(input_file: TextIO) -> dict[str, tuple[EdgeSample, ...]]:
    """Read strict falling-edge CSV rows, preserving independent run identity."""

    reader = csv.DictReader(input_file)
    if reader.fieldnames is None:
        raise CaptureError("capture has no CSV header")
    if tuple(reader.fieldnames) != CAPTURE_COLUMNS:
        raise CaptureError(
            "capture header must be exactly: " + ",".join(CAPTURE_COLUMNS)
        )

    runs: dict[str, list[EdgeSample]] = {}
    last_sample: dict[str, int] = {}
    last_time: dict[str, Decimal] = {}
    for row_number, row in enumerate(reader, start=2):
        run = row["run"].strip()
        if not run:
            raise CaptureError(f"row {row_number}: run must not be empty")
        sample = _parse_decimal_integer(row["sample"].strip(), "sample", row_number)
        try:
            time_ns = Decimal(row["time_ns"].strip())
        except InvalidOperation as error:
            raise CaptureError(
                f"row {row_number}: time_ns must be a finite decimal"
            ) from error
        if not time_ns.is_finite() or time_ns < 0:
            raise CaptureError(f"row {row_number}: time_ns must be finite and nonnegative")
        if run in last_sample and sample <= last_sample[run]:
            raise CaptureError(
                f"row {row_number}: sample must increase strictly within run {run!r}"
            )
        if run in last_time and time_ns <= last_time[run]:
            raise CaptureError(
                f"row {row_number}: time_ns must increase strictly within run {run!r}"
            )
        last_sample[run] = sample
        last_time[run] = time_ns
        runs.setdefault(run, []).append(
            EdgeSample(
                run=run,
                sample=sample,
                time_ns=time_ns,
                rs_n=_parse_binary(row["rs_n"].strip(), "rs_n", row_number),
                men_n=_parse_binary(row["men_n"].strip(), "men_n", row_number),
                we_n=_parse_binary(row["we_n"].strip(), "we_n", row_number),
                den_n=_parse_binary(row["den_n"].strip(), "den_n", row_number),
                address=_parse_hex(row["address"].strip(), 3, "address", row_number),
                data=_parse_hex(row["data"].strip(), 4, "data", row_number),
            )
        )
    if not runs:
        raise CaptureError("capture contains no samples")
    return {run: tuple(samples) for run, samples in runs.items()}


def _matches_program_read(sample: EdgeSample, address: int) -> bool:
    return (
        sample.rs_n == 1
        and sample.men_n == 0
        and sample.we_n == 1
        and sample.den_n == 1
        and sample.address == address
        and sample.data == FIXTURE_WORDS[address]
    )


def _classify_intervals(
    spec: InstructionSpec,
    first: EdgeSample,
    second: EdgeSample,
) -> tuple[str, tuple[str, ...]]:
    warnings: list[str] = []
    for ordinal, sample in (("first", first), ("second", second)):
        if sample.rs_n == 0:
            warnings.append(f"{ordinal} interval sampled with RS active")
        if sample.we_n == 0 or sample.den_n == 0:
            warnings.append(
                f"{ordinal} interval has unexpected active WE or DEN; record as a "
                "source conflict"
            )
        if sample.men_n == 0 and sample.address in FIXTURE_WORDS:
            expected = FIXTURE_WORDS[sample.address]
            if sample.data != expected:
                warnings.append(
                    f"{ordinal} interval data 0x{sample.data:04x} does not match "
                    f"fixture word 0x{expected:04x} at 0x{sample.address:03x}"
                )

    next_read_first = _matches_program_read(first, spec.next_address)
    next_read_second = _matches_program_read(second, spec.next_address)
    advance_read_second = _matches_program_read(second, spec.advance_address)
    controls_inactive_first = (
        first.rs_n == 1
        and first.men_n == 1
        and first.we_n == 1
        and first.den_n == 1
    )

    if controls_inactive_first and next_read_second:
        warnings.append(
            "H1 conflicts with SPRU001B Table 2-4's every-machine-cycle MEN rule"
        )
        return H1_IDLE, tuple(warnings)
    if next_read_first and next_read_second:
        return H2_REPEAT, tuple(warnings)
    if next_read_first and advance_read_second:
        return H3_ADVANCE, tuple(warnings)
    warnings.append("intervals do not match OQ-016 hypothesis H1, H2, or H3")
    return UNCLASSIFIED, tuple(warnings)


def analyze_runs(
    runs: Mapping[str, tuple[EdgeSample, ...]],
) -> tuple[Observation, ...]:
    """Locate the exact probe opcodes and classify their following intervals."""

    observations: list[Observation] = []
    for run, samples in runs.items():
        for spec in INSTRUCTIONS:
            anchors = [
                index
                for index, sample in enumerate(samples)
                if _matches_program_read(sample, spec.opcode_address)
            ]
            if len(anchors) != 1:
                raise CaptureError(
                    f"run {run!r}: expected exactly one {spec.mnemonic} fetch at "
                    f"0x{spec.opcode_address:03x}, found {len(anchors)}"
                )
            anchor = anchors[0]
            if anchor + 4 >= len(samples):
                raise CaptureError(
                    f"run {run!r}: {spec.mnemonic} capture retains fewer than four "
                    "falling boundaries after its opcode fetch"
                )
            first = samples[anchor + 1]
            second = samples[anchor + 2]
            classification, warnings = _classify_intervals(spec, first, second)
            observations.append(
                Observation(
                    run=run,
                    mnemonic=spec.mnemonic,
                    opcode_sample=samples[anchor].sample,
                    classification=classification,
                    first_interval=first,
                    second_interval=second,
                    warnings=warnings,
                )
            )
    return tuple(observations)


def _hash_file(path: Path) -> str:
    digest = sha256()
    with path.open("rb") as input_file:
        for chunk in iter(lambda: input_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _validate_artifact_map(
    value: object,
    name: str,
    artifact_root: Path | None,
    errors: list[str],
    verified: list[str],
) -> None:
    if not isinstance(value, dict) or not value:
        errors.append(f"{name} must be a nonempty path-to-SHA-256 object")
        return
    if artifact_root is None:
        errors.append(f"artifact_root is required to verify {name}")
        return
    root = artifact_root.resolve()
    for relative_name, expected_hash in sorted(value.items()):
        if not isinstance(relative_name, str) or not relative_name:
            errors.append(f"{name} contains an empty or non-string path")
            continue
        if not isinstance(expected_hash, str) or not SHA256_PATTERN.fullmatch(
            expected_hash
        ):
            errors.append(f"{name}[{relative_name!r}] is not a lowercase SHA-256")
            continue
        candidate = (root / relative_name).resolve()
        if candidate != root and root not in candidate.parents:
            errors.append(f"{name}[{relative_name!r}] escapes artifact_root")
            continue
        if not candidate.is_file():
            errors.append(f"{name}[{relative_name!r}] does not name a file")
            continue
        actual_hash = _hash_file(candidate)
        if actual_hash != expected_hash:
            errors.append(
                f"{name}[{relative_name!r}] SHA-256 mismatch: {actual_hash}"
            )
            continue
        verified.append(relative_name)


def validate_evidence_package(
    metadata_path: Path | None,
    program_image: Path | None,
    artifact_root: Path | None,
) -> EvidencePackage:
    """Validate metadata, exact image hash, raw captures, and probe photographs."""

    errors: list[str] = []
    verified: list[str] = []
    program_hash: str | None = None
    if metadata_path is None:
        return EvidencePackage(
            complete=False,
            errors=("metadata sidecar was not supplied",),
            program_image_sha256=None,
            verified_artifacts=(),
        )
    try:
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        return EvidencePackage(
            complete=False,
            errors=(f"cannot read metadata sidecar: {error}",),
            program_image_sha256=None,
            verified_artifacts=(),
        )
    if not isinstance(metadata, dict):
        errors.append("metadata root must be an object")
        metadata = {}
    if metadata.get("schema_version") != 1:
        errors.append("metadata schema_version must be 1")
    for field in REQUIRED_METADATA_TEXT:
        value = metadata.get(field)
        if not isinstance(value, str) or not value.strip():
            errors.append(f"metadata {field} must be a nonempty string")
    oscillator_hz = metadata.get("oscillator_hz")
    if (
        isinstance(oscillator_hz, bool)
        or not isinstance(oscillator_hz, (int, float))
        or not isfinite(oscillator_hz)
        or oscillator_hz <= 0
    ):
        errors.append("metadata oscillator_hz must be a positive number")

    signal_map = metadata.get("signal_pin_map")
    if not isinstance(signal_map, dict):
        errors.append("metadata signal_pin_map must be an object")
    else:
        for signal in REQUIRED_SIGNAL_MAP:
            value = signal_map.get(signal)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"metadata signal_pin_map lacks {signal}")

    expected_program_hash = metadata.get("program_image_sha256")
    if not isinstance(expected_program_hash, str) or not SHA256_PATTERN.fullmatch(
        expected_program_hash
    ):
        errors.append("metadata program_image_sha256 must be a lowercase SHA-256")
    elif program_image is None:
        errors.append("program_image is required to verify program_image_sha256")
    elif not program_image.is_file():
        errors.append("program_image does not name a file")
    else:
        program_hash = _hash_file(program_image)
        if program_hash != expected_program_hash:
            errors.append(f"program image SHA-256 mismatch: {program_hash}")

    _validate_artifact_map(
        metadata.get("raw_artifacts"),
        "raw_artifacts",
        artifact_root,
        errors,
        verified,
    )
    _validate_artifact_map(
        metadata.get("probe_photographs"),
        "probe_photographs",
        artifact_root,
        errors,
        verified,
    )
    return EvidencePackage(
        complete=not errors,
        errors=tuple(errors),
        program_image_sha256=program_hash,
        verified_artifacts=tuple(sorted(verified)),
    )


def build_report(
    capture_path: Path,
    minimum_runs: int = 32,
    metadata_path: Path | None = None,
    program_image: Path | None = None,
    artifact_root: Path | None = None,
) -> CaptureReport:
    """Parse, classify, aggregate, and validate one capture package."""

    if minimum_runs <= 0:
        raise CaptureError("minimum_runs must be positive")
    try:
        with capture_path.open("r", encoding="utf-8", newline="") as input_file:
            runs = read_normalized_capture(input_file)
    except (OSError, UnicodeError) as error:
        raise CaptureError(f"cannot read capture: {error}") from error
    observations = analyze_runs(runs)
    classifications = {
        mnemonic: tuple(
            observation.classification
            for observation in observations
            if observation.mnemonic == mnemonic
        )
        for mnemonic in (spec.mnemonic for spec in INSTRUCTIONS)
    }
    repeatable = all(len(set(values)) == 1 for values in classifications.values())
    hypotheses_resolved = repeatable and all(
        values and values[0] in KNOWN_HYPOTHESES
        for values in classifications.values()
    )
    primary_conflict = any(
        observation.classification == H1_IDLE
        or any("source conflict" in warning for warning in observation.warnings)
        for observation in observations
    )
    package = validate_evidence_package(
        metadata_path,
        program_image,
        artifact_root,
    )
    minimum_runs_met = len(runs) >= minimum_runs
    return CaptureReport(
        capture_sha256=_hash_file(capture_path),
        run_count=len(runs),
        minimum_runs=minimum_runs,
        minimum_runs_met=minimum_runs_met,
        repeatable=repeatable,
        hypotheses_resolved=hypotheses_resolved,
        primary_source_conflict_observed=primary_conflict,
        review_ready=(
            minimum_runs_met
            and repeatable
            and hypotheses_resolved
            and package.complete
        ),
        classifications=classifications,
        observations=observations,
        evidence_package=package,
    )


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("capture", type=Path, help="normalized falling-edge CSV")
    parser.add_argument("--metadata", type=Path, help="physical setup JSON sidecar")
    parser.add_argument("--program-image", type=Path, help="exact loaded image")
    parser.add_argument(
        "--artifact-root",
        type=Path,
        help="root for raw-artifact and probe-photograph paths",
    )
    parser.add_argument("--minimum-runs", type=int, default=32)
    parser.add_argument(
        "--require-review-ready",
        action="store_true",
        help="fail unless all repeatability and evidence-package checks pass",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_argument_parser().parse_args(argv)
    try:
        report = build_report(
            capture_path=args.capture,
            minimum_runs=args.minimum_runs,
            metadata_path=args.metadata,
            program_image=args.program_image,
            artifact_root=args.artifact_root,
        )
    except CaptureError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    json.dump(report.to_json_object(), sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    if args.require_review_ready and not report.review_ready:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
