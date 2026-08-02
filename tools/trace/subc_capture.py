#!/usr/bin/env python3
"""Classify normalized original-TMS32010 SUBC physical-probe captures.

The dependency experiment preserves its first output as an observation, not an
expected result.  The overflow experiment interprets only architectural OV
bit 15 and never treats a stable classification as hardware verification.
"""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
from hashlib import sha256
import json
from pathlib import Path
import sys
from typing import Mapping, Sequence

from tools.trace.push_pop_capture import (
    CaptureError,
    EdgeSample,
    EvidencePackage,
    read_normalized_capture,
    validate_evidence_package,
)
from tools.trace.specimen_evidence import (
    SpecimenEvidence,
    validate_specimen_evidence,
)


DEPENDENCY = "dependency"
OVERFLOW = "overflow"

DEPENDENCY_WORDS = (
    0x6E00, 0x7E02, 0x5000, 0x7E05, 0x5001, 0x7E03,
    0x5002, 0x7F89, 0x5003, 0x5004, 0x6500, 0x6101,
    0x6402, 0x5003, 0x7F80, 0x6500, 0x6101, 0x6402,
    0x7F80, 0x5004, 0x4F03, 0x7F80, 0x4F04, 0x7F80,
    0xF900, 0x0018,
)
OVERFLOW_WORDS = (
    0x6E00, 0x6880, 0x7F89, 0x5000, 0x7E01, 0x5001,
    0x7F89, 0x6301, 0x5002, 0x7E80, 0x5003, 0x2803,
    0x5004, 0x7E40, 0x5005, 0x2805, 0x5006, 0x6504,
    0x7F8B, 0x6402, 0x7F80, 0x7C00, 0x7B00, 0x6506,
    0x7F8B, 0x6400, 0x7F80, 0x7C01, 0x6E01, 0x4F00,
    0x7F80, 0x4F01, 0x7F80, 0xF900, 0x0021,
)

FIXTURE_WORDS = {
    DEPENDENCY: DEPENDENCY_WORDS,
    OVERFLOW: OVERFLOW_WORDS,
}
FIXTURE_SOURCE_SHA256 = {
    DEPENDENCY: (
        "e45098709c66bf38264316bf07d78ff707640f29972ff2a31fcab6a68d8edb56"
    ),
    OVERFLOW: (
        "390f7731175b7b61d9799d3ff66001d04cb7fc3407a134f628e4dc603bcd551e"
    ),
}
OUT_ANCHORS = {
    DEPENDENCY: ((0x014, 0x4F03), (0x016, 0x4F04)),
    OVERFLOW: ((0x01D, 0x4F00), (0x01F, 0x4F01)),
}

DEPENDENCY_OLD = "OLD_ACC_LOW_0x0005"
DEPENDENCY_TRIAL = "TRIAL_LOW_0x8005"
DEPENDENCY_FINAL = "FINAL_LOW_0x000b"

OVERFLOW_INTERMEDIATE = "INTERMEDIATE_SUBTRACTION_ONLY"
OVERFLOW_FINAL = "FINAL_SHIFT_ONLY"
OVERFLOW_EITHER = "EITHER_STAGE"
OVERFLOW_NEITHER = "NEITHER_VECTOR"

# OV is bit 15. The fixture initializes ARP explicitly. Bit 1 is excluded
# because SC-008 retains its physical output value at CORROBORATED confidence.
# Every other bit is fixed by the fixture and primary-defined SST representation.
STATUS_CHECK_MASK = 0x7FFD
STATUS_EXPECTED = 0x7EFC


@dataclass(frozen=True)
class Observation:
    """Two port-7 output cycles from one reset-to-loop run."""

    run: str
    experiment: str
    classification: str
    first_output: EdgeSample
    second_output: EdgeSample
    fixture_valid: bool
    warnings: tuple[str, ...]


@dataclass(frozen=True)
class CaptureReport:
    """Aggregate result with no automatic architecture-confidence change."""

    capture_sha256: str
    experiment: str
    run_count: int
    minimum_runs: int
    minimum_runs_met: bool
    repeatable: bool
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
                "change OQ-017 or OQ-018, establish a production-silicon subphase, "
                "or establish VERIFIED_HARDWARE without engineering review of raw "
                "captures and the physical setup. It does not establish OQ-008 "
                "mask-revision invariance or generalize beyond the identified "
                "specimen."
            ),
            "capture_sha256": self.capture_sha256,
            "experiment": self.experiment,
            "run_count": self.run_count,
            "minimum_runs": self.minimum_runs,
            "minimum_runs_met": self.minimum_runs_met,
            "repeatable": self.repeatable,
            "fixture_valid": self.fixture_valid,
            "review_ready": self.review_ready,
            "acceptance_complete": self.acceptance_complete,
            "specimen_id": self.specimen_id,
            "specimen_scope": self.specimen_scope,
            "classifications": list(self.classifications),
            "observations": [
                {
                    **asdict(observation),
                    "first_output": _sample_json(observation.first_output),
                    "second_output": _sample_json(observation.second_output),
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


def _hash_file(path: Path) -> str:
    digest = sha256()
    with path.open("rb") as input_file:
        for chunk in iter(lambda: input_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _expected_image(experiment: str) -> bytes:
    return b"".join(
        word.to_bytes(2, byteorder="big")
        for word in FIXTURE_WORDS[experiment]
    )


def _matches_program_read(sample: EdgeSample, address: int, data: int) -> bool:
    return (
        sample.rs_n == 1
        and sample.men_n == 0
        and sample.we_n == 1
        and sample.den_n == 1
        and sample.address == address
        and sample.data == data
    )


def _classify_dependency(first: int) -> str:
    if first == 0x0005:
        return DEPENDENCY_OLD
    if first == 0x8005:
        return DEPENDENCY_TRIAL
    if first == 0x000B:
        return DEPENDENCY_FINAL
    return f"OTHER_LOW_0x{first:04x}"


def _classify_overflow(first: int, second: int) -> str:
    pair = ((first >> 15) & 1, (second >> 15) & 1)
    return {
        (1, 0): OVERFLOW_INTERMEDIATE,
        (0, 1): OVERFLOW_FINAL,
        (1, 1): OVERFLOW_EITHER,
        (0, 0): OVERFLOW_NEITHER,
    }[pair]


def _output_warnings(
    experiment: str,
    first: EdgeSample,
    second: EdgeSample,
) -> tuple[str, ...]:
    warnings: list[str] = []
    for ordinal, sample in (("first", first), ("second", second)):
        if sample.rs_n == 0:
            warnings.append(f"{ordinal} output sampled with RS active")
        if sample.we_n != 0 or sample.men_n != 1 or sample.den_n != 1:
            warnings.append(
                f"{ordinal} output is not an exclusive active-low WE cycle"
            )
        if sample.address != 7:
            warnings.append(
                f"{ordinal} output address 0x{sample.address:03x} is not port 7"
            )
    if experiment == DEPENDENCY and second.data != 0x000B:
        warnings.append(
            f"legal NOP-separated comparator is 0x{second.data:04x}, expected 0x000b"
        )
    if experiment == OVERFLOW:
        for ordinal, sample in (("first", first), ("second", second)):
            if sample.data & STATUS_CHECK_MASK != STATUS_EXPECTED:
                warnings.append(
                    f"{ordinal} SST word 0x{sample.data:04x} disagrees with the "
                    "fixture outside OV and reserved bit 1"
                )
    return tuple(warnings)


def analyze_runs(
    experiment: str,
    runs: Mapping[str, tuple[EdgeSample, ...]],
) -> tuple[Observation, ...]:
    """Validate fixture anchors and retain the two physical port outputs."""

    if experiment not in FIXTURE_WORDS:
        raise CaptureError(f"unknown SUBC experiment {experiment!r}")
    observations: list[Observation] = []
    for run, samples in runs.items():
        anchor_indexes: list[int] = []
        for address, word in OUT_ANCHORS[experiment]:
            matches = [
                index
                for index, sample in enumerate(samples)
                if _matches_program_read(sample, address, word)
            ]
            if len(matches) != 1:
                raise CaptureError(
                    f"run {run!r}: expected exactly one checked OUT fetch at "
                    f"0x{address:03x}, found {len(matches)}"
                )
            anchor_indexes.append(matches[0])

        output_indexes = [
            index for index, sample in enumerate(samples) if sample.we_n == 0
        ]
        if len(output_indexes) != 2:
            raise CaptureError(
                f"run {run!r}: expected exactly two active-low WE samples, "
                f"found {len(output_indexes)}"
            )
        if not (
            anchor_indexes[0]
            < output_indexes[0]
            < anchor_indexes[1]
            < output_indexes[1]
        ):
            raise CaptureError(
                f"run {run!r}: checked OUT fetches and output cycles are out of order"
            )
        if output_indexes[1] + 2 >= len(samples):
            raise CaptureError(
                f"run {run!r}: capture retains fewer than two boundaries after "
                "the second output"
            )

        first = samples[output_indexes[0]]
        second = samples[output_indexes[1]]
        warnings = _output_warnings(experiment, first, second)
        classification = (
            _classify_dependency(first.data)
            if experiment == DEPENDENCY
            else _classify_overflow(first.data, second.data)
        )
        observations.append(
            Observation(
                run=run,
                experiment=experiment,
                classification=classification,
                first_output=first,
                second_output=second,
                fixture_valid=not warnings,
                warnings=warnings,
            )
        )
    return tuple(observations)


def _validate_checked_image(
    experiment: str,
    program_image: Path | None,
    package: EvidencePackage,
    specimen: SpecimenEvidence,
) -> EvidencePackage:
    errors = list(package.errors) + list(specimen.errors)
    verified = set(package.verified_artifacts)
    verified.update(specimen.verified_artifacts)
    if program_image is not None and program_image.is_file():
        try:
            image = program_image.read_bytes()
        except OSError as error:
            errors.append(f"cannot read checked program image: {error}")
        else:
            if image != _expected_image(experiment):
                errors.append(
                    f"program image is not the exact big-endian {experiment} fixture"
                )
    return EvidencePackage(
        complete=not errors,
        errors=tuple(errors),
        program_image_sha256=package.program_image_sha256,
        verified_artifacts=tuple(sorted(verified)),
    )


def build_report(
    capture_path: Path,
    experiment: str,
    minimum_runs: int = 32,
    metadata_path: Path | None = None,
    program_image: Path | None = None,
    artifact_root: Path | None = None,
) -> CaptureReport:
    if experiment not in FIXTURE_WORDS:
        raise CaptureError(f"unknown SUBC experiment {experiment!r}")
    if minimum_runs <= 0:
        raise CaptureError("minimum_runs must be positive")
    try:
        with capture_path.open("r", encoding="utf-8", newline="") as input_file:
            runs = read_normalized_capture(input_file)
    except (OSError, UnicodeError) as error:
        raise CaptureError(f"cannot read capture: {error}") from error
    observations = analyze_runs(experiment, runs)
    classifications = tuple(item.classification for item in observations)
    repeatable = len(set(classifications)) == 1
    fixture_valid = all(item.fixture_valid for item in observations)
    specimen = validate_specimen_evidence(
        metadata_path,
        capture_path,
        artifact_root,
        fixture_source_sha256=FIXTURE_SOURCE_SHA256[experiment],
        fixture_words={
            address: word
            for address, word in enumerate(FIXTURE_WORDS[experiment])
        },
    )
    package = _validate_checked_image(
        experiment,
        program_image,
        validate_evidence_package(metadata_path, program_image, artifact_root),
        specimen,
    )
    minimum_runs_met = len(runs) >= minimum_runs
    return CaptureReport(
        capture_sha256=_hash_file(capture_path),
        experiment=experiment,
        run_count=len(runs),
        minimum_runs=minimum_runs,
        minimum_runs_met=minimum_runs_met,
        repeatable=repeatable,
        fixture_valid=fixture_valid,
        review_ready=(
            minimum_runs_met and repeatable and fixture_valid and package.complete
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
    parser.add_argument("capture", type=Path, help="normalized falling-edge CSV")
    parser.add_argument(
        "--experiment",
        required=True,
        choices=(DEPENDENCY, OVERFLOW),
        help="checked project-authored probe image represented by the capture",
    )
    parser.add_argument("--metadata", type=Path, help="physical setup JSON sidecar")
    parser.add_argument("--program-image", type=Path, help="exact big-endian image")
    parser.add_argument(
        "--artifact-root",
        type=Path,
        help="root for raw-artifact and probe-photograph paths",
    )
    parser.add_argument("--minimum-runs", type=int, default=32)
    parser.add_argument(
        "--require-review-ready",
        action="store_true",
        help="fail unless repeatability, fixture, and evidence checks pass",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_argument_parser().parse_args(argv)
    try:
        report = build_report(
            capture_path=args.capture,
            experiment=args.experiment,
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
