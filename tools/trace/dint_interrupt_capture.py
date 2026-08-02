#!/usr/bin/env python3
"""Classify original-TMS32010 DINT/interrupt-boundary captures.

This tool preserves the observed port sequence and independently checks pulse
timing. It does not use the current RTL or any emulator as an expected result.
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import asdict, dataclass
from decimal import Decimal, InvalidOperation
from hashlib import sha256
import json
from pathlib import Path
import re
import sys
from typing import Mapping, Sequence, TextIO

from tools.trace.push_pop_capture import (
    EvidencePackage,
    validate_evidence_package,
)
from tools.trace.specimen_evidence import (
    SpecimenEvidence,
    validate_specimen_evidence,
)


CAPTURE_COLUMNS = (
    "run",
    "sample",
    "time_ns",
    "rs_n",
    "int_n",
    "men_n",
    "we_n",
    "den_n",
    "address",
    "data",
)
PULSE_COLUMNS = (
    "run",
    "int_assert_ns",
    "int_release_ns",
    "int_fall_time_ns",
)

FIXTURE_WORDS = {
    0x000: 0xF900,
    0x001: 0x0010,
    0x002: 0xF900,
    0x003: 0x0030,
    0x010: 0x6E00,
    0x011: 0x7E11,
    0x012: 0x5000,
    0x013: 0x7E22,
    0x014: 0x5001,
    0x015: 0x7E33,
    0x016: 0x5002,
    0x017: 0x7F82,
    0x018: 0x7F80,
    0x019: 0x4F02,
    0x01A: 0x7F80,
    0x01B: 0x7F81,
    0x01C: 0x4F01,
    0x01D: 0xF900,
    0x01E: 0x001F,
    0x01F: 0xF900,
    0x020: 0x001F,
    0x030: 0x7F9D,
    0x031: 0x5003,
    0x032: 0x7F9C,
    0x033: 0x4F03,
    0x034: 0x4F00,
    0x035: 0x7F82,
    0x036: 0x7F8D,
}
FIXTURE_SOURCE_SHA256 = (
    "55828c4cef0679d58dd8e5400bc88ad4bffaf476fb8d0e8c34acc9ba4fbeb3d4"
)

CANCELS_ENTRY = "DINT_CANCELS_ENTRY"
ENTRY_STACKS_N_PLUS_2 = "ENTRY_STACKS_N_PLUS_2"
ENTRY_STACKS_N_PLUS_1 = "ENTRY_STACKS_N_PLUS_1"
OTHER_SEQUENCE = "OTHER_SEQUENCE"
KNOWN_RESULTS = frozenset(
    (CANCELS_ENTRY, ENTRY_STACKS_N_PLUS_2, ENTRY_STACKS_N_PLUS_1)
)

SETUP_MIN_NS = Decimal("50")
FALL_MAX_NS = Decimal("15")
SHA256_PATTERN = re.compile(r"[0-9a-f]{64}")
CALIBRATION_NAMES = ("no_pulse", "one_fetch_earlier", "one_fetch_later")


class CaptureError(ValueError):
    """Raised when a normalized capture violates its declared schema."""


@dataclass(frozen=True)
class EdgeSample:
    """Signals sampled at one falling CLKOUT boundary."""

    run: str
    sample: int
    time_ns: Decimal
    rs_n: int
    int_n: int
    men_n: int
    we_n: int
    den_n: int
    address: int
    data: int


@dataclass(frozen=True)
class PulseMeasurement:
    """Threshold and 10%-to-90% measurements derived from the raw capture."""

    run: str
    int_assert_ns: Decimal
    int_release_ns: Decimal
    int_fall_time_ns: Decimal


@dataclass(frozen=True)
class Observation:
    """One run's electrical qualification and complete port sequence."""

    run: str
    classification: str
    arm_sample: int
    arm_time_ns: Decimal
    setup_ns: Decimal
    pulse_width_ns: Decimal
    local_clkout_period_ns: Decimal
    int_fall_time_ns: Decimal
    port_sequence: tuple[int, ...]
    fixture_valid: bool
    warnings: tuple[str, ...]


@dataclass(frozen=True)
class CaptureReport:
    """Aggregate classification without an architectural confidence claim."""

    capture_sha256: str
    pulse_measurements_sha256: str
    run_count: int
    minimum_runs: int
    minimum_runs_met: bool
    repeatable: bool
    candidate_resolved: bool
    fixture_valid: bool
    review_ready: bool
    acceptance_complete: bool
    specimen_id: str | None
    specimen_scope: str
    classifications: tuple[str, ...]
    observations: tuple[Observation, ...]
    evidence_package: EvidencePackage

    def to_json_object(self) -> dict[str, object]:
        return {
            "schema_version": 1,
            "claim_boundary": (
                "Classification and package validation only; this output does not "
                "change OQ-019, establish original-silicon DINT priority, prove "
                "mask-revision invariance, or establish VERIFIED_HARDWARE without "
                "engineering review of raw captures and the physical setup. It "
                "does not generalize beyond the identified specimen."
            ),
            "capture_sha256": self.capture_sha256,
            "pulse_measurements_sha256": self.pulse_measurements_sha256,
            "run_count": self.run_count,
            "minimum_runs": self.minimum_runs,
            "minimum_runs_met": self.minimum_runs_met,
            "repeatable": self.repeatable,
            "candidate_resolved": self.candidate_resolved,
            "fixture_valid": self.fixture_valid,
            "review_ready": self.review_ready,
            "acceptance_complete": self.acceptance_complete,
            "specimen_id": self.specimen_id,
            "specimen_scope": self.specimen_scope,
            "classifications": list(self.classifications),
            "observations": [
                {
                    **asdict(observation),
                    "arm_time_ns": str(observation.arm_time_ns),
                    "setup_ns": str(observation.setup_ns),
                    "pulse_width_ns": str(observation.pulse_width_ns),
                    "local_clkout_period_ns": str(
                        observation.local_clkout_period_ns
                    ),
                    "int_fall_time_ns": str(observation.int_fall_time_ns),
                    "port_sequence": [
                        f"0x{value:04x}" for value in observation.port_sequence
                    ],
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


def _parse_uint(token: str, name: str, row_number: int) -> int:
    if not re.fullmatch(r"0|[1-9][0-9]*", token):
        raise CaptureError(f"row {row_number}: {name} must be a decimal integer")
    return int(token, 10)


def _parse_bit(token: str, name: str, row_number: int) -> int:
    if token not in ("0", "1"):
        raise CaptureError(f"row {row_number}: {name} must be 0 or 1")
    return int(token)


def _parse_hex(token: str, digits: int, name: str, row_number: int) -> int:
    if not re.fullmatch(rf"0x[0-9a-fA-F]{{1,{digits}}}", token):
        raise CaptureError(
            f"row {row_number}: {name} must use a 0x-prefixed hexadecimal value"
        )
    return int(token, 16)


def _parse_decimal(token: str, name: str, row_number: int) -> Decimal:
    try:
        value = Decimal(token)
    except InvalidOperation as error:
        raise CaptureError(
            f"row {row_number}: {name} must be a finite decimal"
        ) from error
    if not value.is_finite() or value < 0:
        raise CaptureError(
            f"row {row_number}: {name} must be finite and nonnegative"
        )
    return value


def read_capture(input_file: TextIO) -> dict[str, tuple[EdgeSample, ...]]:
    reader = csv.DictReader(input_file)
    if reader.fieldnames is None or tuple(reader.fieldnames) != CAPTURE_COLUMNS:
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
        sample = _parse_uint(row["sample"].strip(), "sample", row_number)
        time_ns = _parse_decimal(row["time_ns"].strip(), "time_ns", row_number)
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
                rs_n=_parse_bit(row["rs_n"].strip(), "rs_n", row_number),
                int_n=_parse_bit(row["int_n"].strip(), "int_n", row_number),
                men_n=_parse_bit(row["men_n"].strip(), "men_n", row_number),
                we_n=_parse_bit(row["we_n"].strip(), "we_n", row_number),
                den_n=_parse_bit(row["den_n"].strip(), "den_n", row_number),
                address=_parse_hex(row["address"].strip(), 3, "address", row_number),
                data=_parse_hex(row["data"].strip(), 4, "data", row_number),
            )
        )
    if not runs:
        raise CaptureError("capture contains no samples")
    return {run: tuple(samples) for run, samples in runs.items()}


def read_pulse_measurements(
    input_file: TextIO,
) -> dict[str, PulseMeasurement]:
    reader = csv.DictReader(input_file)
    if reader.fieldnames is None or tuple(reader.fieldnames) != PULSE_COLUMNS:
        raise CaptureError(
            "pulse header must be exactly: " + ",".join(PULSE_COLUMNS)
        )
    measurements: dict[str, PulseMeasurement] = {}
    for row_number, row in enumerate(reader, start=2):
        run = row["run"].strip()
        if not run:
            raise CaptureError(f"row {row_number}: run must not be empty")
        if run in measurements:
            raise CaptureError(f"row {row_number}: duplicate pulse run {run!r}")
        measurement = PulseMeasurement(
            run=run,
            int_assert_ns=_parse_decimal(
                row["int_assert_ns"].strip(), "int_assert_ns", row_number
            ),
            int_release_ns=_parse_decimal(
                row["int_release_ns"].strip(), "int_release_ns", row_number
            ),
            int_fall_time_ns=_parse_decimal(
                row["int_fall_time_ns"].strip(), "int_fall_time_ns", row_number
            ),
        )
        if measurement.int_release_ns <= measurement.int_assert_ns:
            raise CaptureError(
                f"row {row_number}: int_release_ns must follow int_assert_ns"
            )
        measurements[run] = measurement
    if not measurements:
        raise CaptureError("pulse measurements contain no runs")
    return measurements


def _program_read(sample: EdgeSample, address: int, data: int) -> bool:
    return (
        sample.rs_n == 1
        and sample.men_n == 0
        and sample.we_n == 1
        and sample.den_n == 1
        and sample.address == address
        and sample.data == data
    )


def _classify_sequence(sequence: tuple[int, ...]) -> str:
    if sequence == (0x0033, 0x0022):
        return CANCELS_ENTRY
    if sequence == (0x0033, 0x001C, 0x0011, 0x0022):
        return ENTRY_STACKS_N_PLUS_2
    if sequence == (0x0033, 0x001B, 0x0011, 0x0022):
        return ENTRY_STACKS_N_PLUS_1
    return OTHER_SEQUENCE + "_" + "_".join(f"{value:04x}" for value in sequence)


def analyze_runs(
    runs: Mapping[str, tuple[EdgeSample, ...]],
    pulses: Mapping[str, PulseMeasurement],
) -> tuple[Observation, ...]:
    if set(runs) != set(pulses):
        raise CaptureError("capture and pulse-measurement run names must match exactly")
    observations: list[Observation] = []
    for run, samples in runs.items():
        arm_matches = [
            index
            for index, sample in enumerate(samples)
            if _program_read(sample, 0x01A, 0x7F80)
        ]
        dint_matches = [
            index
            for index, sample in enumerate(samples)
            if _program_read(sample, 0x01B, 0x7F81)
        ]
        if len(arm_matches) != 1 or len(dint_matches) != 1:
            raise CaptureError(
                f"run {run!r}: expected one checked ARM_WINDOW and RACING_DINT "
                f"fetch, found {len(arm_matches)} and {len(dint_matches)}"
            )
        arm_index = arm_matches[0]
        dint_index = dint_matches[0]
        if arm_index == 0 or arm_index + 1 >= len(samples):
            raise CaptureError(f"run {run!r}: arm fetch lacks adjacent CLKOUT samples")
        if dint_index <= arm_index:
            raise CaptureError(f"run {run!r}: DINT fetch does not follow arm fetch")

        output_indexes = [
            index for index, sample in enumerate(samples) if sample.we_n == 0
        ]
        if not output_indexes:
            raise CaptureError(f"run {run!r}: capture contains no output cycles")
        if output_indexes[0] >= arm_index or output_indexes[-1] <= dint_index:
            raise CaptureError(
                f"run {run!r}: armed and terminal outputs do not bracket the race"
            )
        if output_indexes[-1] + 2 >= len(samples):
            raise CaptureError(
                f"run {run!r}: fewer than two falling boundaries follow terminal output"
            )

        warnings: list[str] = []
        outputs: list[int] = []
        for ordinal, index in enumerate(output_indexes, start=1):
            sample = samples[index]
            outputs.append(sample.data)
            if (
                sample.rs_n != 1
                or sample.men_n != 1
                or sample.we_n != 0
                or sample.den_n != 1
                or sample.address != 7
            ):
                warnings.append(
                    f"output {ordinal} is not an exclusive active-low port-7 WE cycle"
                )

        pulse = pulses[run]
        arm = samples[arm_index]
        local_period = samples[arm_index + 1].time_ns - arm.time_ns
        setup = arm.time_ns - pulse.int_assert_ns
        width = pulse.int_release_ns - pulse.int_assert_ns
        if pulse.int_assert_ns >= arm.time_ns:
            warnings.append("INT assertion does not precede the ARM_WINDOW boundary")
        if setup < SETUP_MIN_NS:
            warnings.append(
                f"INT setup is {setup} ns, below the documented 50 ns minimum"
            )
        if width < local_period:
            warnings.append(
                f"INT low width is {width} ns, below local CLKOUT period "
                f"{local_period} ns"
            )
        if pulse.int_fall_time_ns > FALL_MAX_NS:
            warnings.append(
                f"INT fall time is {pulse.int_fall_time_ns} ns, above 15 ns"
            )
        for sample in samples:
            expected_int_n = not (
                pulse.int_assert_ns <= sample.time_ns < pulse.int_release_ns
            )
            if sample.int_n != int(expected_int_n):
                warnings.append(
                    f"sample {sample.sample} INT level disagrees with pulse transitions"
                )
                break

        sequence = tuple(outputs)
        if not sequence or sequence[0] != 0x0033:
            warnings.append("first output is not the 0x0033 armed marker")
        if not sequence or sequence[-1] != 0x0022:
            warnings.append("last output is not the 0x0022 terminal marker")
        observations.append(
            Observation(
                run=run,
                classification=_classify_sequence(sequence),
                arm_sample=arm.sample,
                arm_time_ns=arm.time_ns,
                setup_ns=setup,
                pulse_width_ns=width,
                local_clkout_period_ns=local_period,
                int_fall_time_ns=pulse.int_fall_time_ns,
                port_sequence=sequence,
                fixture_valid=not warnings,
                warnings=tuple(warnings),
            )
        )
    return tuple(observations)


def _hash_file(path: Path) -> str:
    digest = sha256()
    with path.open("rb") as input_file:
        for chunk in iter(lambda: input_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _expected_image() -> bytes:
    highest = max(FIXTURE_WORDS)
    words = [FIXTURE_WORDS.get(address, 0) for address in range(highest + 1)]
    return b"".join(word.to_bytes(2, byteorder="big") for word in words)


def _safe_artifact(
    root: Path,
    relative_name: object,
    expected_hash: object,
    label: str,
    errors: list[str],
    verified: list[str],
) -> None:
    if not isinstance(relative_name, str) or not relative_name:
        errors.append(f"{label} path must be a nonempty string")
        return
    if not isinstance(expected_hash, str) or not SHA256_PATTERN.fullmatch(
        expected_hash
    ):
        errors.append(f"{label} SHA-256 must be lowercase hexadecimal")
        return
    resolved_root = root.resolve()
    candidate = (resolved_root / relative_name).resolve()
    if candidate != resolved_root and resolved_root not in candidate.parents:
        errors.append(f"{label} path escapes artifact_root")
        return
    if not candidate.is_file():
        errors.append(f"{label} path does not name a file")
        return
    actual = _hash_file(candidate)
    if actual != expected_hash:
        errors.append(f"{label} SHA-256 mismatch: {actual}")
        return
    verified.append(relative_name)


def validate_dint_evidence(
    metadata_path: Path | None,
    program_image: Path | None,
    pulse_path: Path,
    artifact_root: Path | None,
    specimen: SpecimenEvidence,
) -> EvidencePackage:
    base = validate_evidence_package(metadata_path, program_image, artifact_root)
    errors = list(base.errors) + list(specimen.errors)
    verified = list(base.verified_artifacts) + list(specimen.verified_artifacts)
    if program_image is not None and program_image.is_file():
        try:
            if program_image.read_bytes() != _expected_image():
                errors.append("program image is not the exact sparse big-endian DINT fixture")
        except OSError as error:
            errors.append(f"cannot read checked program image: {error}")
    if metadata_path is None:
        return EvidencePackage(
            complete=False,
            errors=tuple(errors),
            program_image_sha256=base.program_image_sha256,
            verified_artifacts=tuple(sorted(verified)),
        )
    try:
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        metadata = {}
    if not isinstance(metadata, dict):
        metadata = {}
    for field in (
        "interrupt_driver_circuit",
        "interrupt_driver_voltage_v",
        "pulse_generator_model",
    ):
        value = metadata.get(field)
        if not isinstance(value, str) or not value.strip():
            errors.append(f"metadata {field} must be a nonempty string")
    signal_map = metadata.get("signal_pin_map")
    if not isinstance(signal_map, dict) or not isinstance(
        signal_map.get("INT_N"), str
    ) or not signal_map.get("INT_N", "").strip():
        errors.append("metadata signal_pin_map lacks INT_N")
    expected_pulse_hash = metadata.get("pulse_measurements_sha256")
    if not isinstance(expected_pulse_hash, str) or not SHA256_PATTERN.fullmatch(
        expected_pulse_hash
    ):
        errors.append("metadata pulse_measurements_sha256 must be a lowercase SHA-256")
    elif _hash_file(pulse_path) != expected_pulse_hash:
        errors.append("pulse measurements SHA-256 mismatch")
    calibrations = metadata.get("calibrations")
    if not isinstance(calibrations, dict):
        errors.append("metadata calibrations must be an object")
    elif artifact_root is None:
        errors.append("artifact_root is required to verify calibrations")
    else:
        for name in CALIBRATION_NAMES:
            item = calibrations.get(name)
            if not isinstance(item, dict):
                errors.append(f"metadata calibrations lacks {name}")
                continue
            _safe_artifact(
                artifact_root,
                item.get("path"),
                item.get("sha256"),
                f"calibrations.{name}",
                errors,
                verified,
            )
    return EvidencePackage(
        complete=not errors,
        errors=tuple(errors),
        program_image_sha256=base.program_image_sha256,
        verified_artifacts=tuple(sorted(set(verified))),
    )


def build_report(
    capture_path: Path,
    pulse_path: Path,
    minimum_runs: int = 32,
    metadata_path: Path | None = None,
    program_image: Path | None = None,
    artifact_root: Path | None = None,
) -> CaptureReport:
    if minimum_runs <= 0:
        raise CaptureError("minimum_runs must be positive")
    try:
        with capture_path.open("r", encoding="utf-8", newline="") as input_file:
            runs = read_capture(input_file)
        with pulse_path.open("r", encoding="utf-8", newline="") as input_file:
            pulses = read_pulse_measurements(input_file)
    except (OSError, UnicodeError) as error:
        raise CaptureError(f"cannot read capture input: {error}") from error
    observations = analyze_runs(runs, pulses)
    classifications = tuple(item.classification for item in observations)
    repeatable = len(set(classifications)) == 1
    candidate_resolved = repeatable and classifications[0] in KNOWN_RESULTS
    fixture_valid = all(item.fixture_valid for item in observations)
    specimen = validate_specimen_evidence(
        metadata_path,
        capture_path,
        artifact_root,
        fixture_source_sha256=FIXTURE_SOURCE_SHA256,
        fixture_words=FIXTURE_WORDS,
    )
    package = validate_dint_evidence(
        metadata_path, program_image, pulse_path, artifact_root, specimen
    )
    minimum_runs_met = len(runs) >= minimum_runs
    return CaptureReport(
        capture_sha256=_hash_file(capture_path),
        pulse_measurements_sha256=_hash_file(pulse_path),
        run_count=len(runs),
        minimum_runs=minimum_runs,
        minimum_runs_met=minimum_runs_met,
        repeatable=repeatable,
        candidate_resolved=candidate_resolved,
        fixture_valid=fixture_valid,
        review_ready=(
            minimum_runs_met
            and repeatable
            and candidate_resolved
            and fixture_valid
            and package.complete
        ),
        acceptance_complete=False,
        specimen_id=specimen.specimen_id,
        specimen_scope=specimen.specimen_scope,
        classifications=classifications,
        observations=observations,
        evidence_package=package,
    )


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("capture", type=Path, help="falling-CLKOUT CSV with INT_N")
    parser.add_argument(
        "--pulse-measurements",
        required=True,
        type=Path,
        help="per-run INT transition and fall-time CSV",
    )
    parser.add_argument("--metadata", type=Path, help="physical setup JSON sidecar")
    parser.add_argument("--program-image", type=Path, help="exact big-endian image")
    parser.add_argument("--artifact-root", type=Path)
    parser.add_argument("--minimum-runs", type=int, default=32)
    parser.add_argument("--require-review-ready", action="store_true")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_argument_parser().parse_args(argv)
    try:
        report = build_report(
            capture_path=args.capture,
            pulse_path=args.pulse_measurements,
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
