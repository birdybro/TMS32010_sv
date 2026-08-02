#!/usr/bin/env python3
"""Normalize paired original-TMS32010 absent-RAM sentinel-write captures."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
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


DIRECTIONS = ("ASCENDING", "DESCENDING")
ASCENDING_WORDS = (
    0x6E00, 0x7F8A, 0x7EA0, 0x5000, 0x7E6F, 0x5001, 0x2800,
    0x0001, 0x5002, 0x3902, 0x7F89, 0x708F, 0x6880, 0x5088,
    0xF400, 0x000D, 0x7E41, 0x5000, 0x4F00, 0x7F89, 0x5000,
    0x7090, 0x6880, 0x31A1, 0xF400, 0x0016, 0x708F, 0x6880,
    0x4F88, 0xF400, 0x001C, 0x7090, 0x716F, 0x6880, 0x4FA1,
    0xF400, 0x0021, 0x7E4F, 0x5000, 0x4F00, 0x7F80, 0xF900,
    0x0029,
)
DESCENDING_REPLACEMENTS = {
    0x010: 0x7E42,
    0x015: 0x70FF,
    0x017: 0x3191,
    0x01F: 0x70FF,
    0x022: 0x4F91,
}
FIXTURE_SOURCE_SHA256 = {
    "ASCENDING": (
        "8945f392bde5090bfbe84a57582ba1236dd616335980a4f3cae9c7f73491cac7"
    ),
    "DESCENDING": (
        "ee8be3f52da8323a65773709b4bbaf014d0299f866239f6806c649dbb8f1b0d0"
    ),
}
START_OUT = (0x012, 0x4F00)
VALID_SCAN_OUT = (0x01C, 0x4F88)
ABSENT_OUT = {
    "ASCENDING": (0x022, 0x4FA1),
    "DESCENDING": (0x022, 0x4F91),
}
END_OUT = (0x027, 0x4F00)
TERMINAL_BRANCH = (0x029, 0xF900)
VALID_COUNT = 144
ABSENT_COUNT = 112
COMPLETE_OUTPUT_COUNT = 258


@dataclass(frozen=True)
class AbsentObservation:
    address: int
    expected_sentinel: int
    observed: int
    relationship: str


@dataclass(frozen=True)
class Observation:
    direction: str
    run: str
    classification: str
    output_sequence: tuple[int, ...]
    output_samples: tuple[EdgeSample, ...]
    valid_scan_sha256: str | None
    changed_valid_addresses: tuple[int, ...]
    absent_observations: tuple[AbsentObservation, ...]
    terminal_seen: bool
    capture_complete: bool
    fixture_valid: bool
    warnings: tuple[str, ...]


@dataclass(frozen=True)
class DirectionSummary:
    direction: str
    run_count: int
    minimum_runs_met: bool
    complete: bool
    repeatable: bool
    fixture_valid: bool
    capture_sha256: str
    classifications: tuple[str, ...]
    observations: tuple[Observation, ...]
    evidence_package: EvidencePackage


@dataclass(frozen=True)
class PriorReadEvidence:
    complete: bool
    errors: tuple[str, ...]
    report_sha256: str | None
    specimen_id: str | None
    specimen_scope: str


@dataclass(frozen=True)
class CaptureReport:
    minimum_runs: int
    minimum_runs_met: bool
    complete: bool
    fixture_valid: bool
    review_ready: bool
    acceptance_complete: bool
    specimen_id: str | None
    specimen_scope: str
    specimen_pair_errors: tuple[str, ...]
    directions: tuple[DirectionSummary, ...]
    prior_read_evidence: PriorReadEvidence

    def to_json_object(self) -> dict[str, object]:
        return {
            "schema_version": 1,
            "claim_boundary": (
                "Stage-2 paired sentinel-write normalization and package validation "
                "only; a pinned stage-1 report plus capture-order declaration does "
                "not independently prove wall-clock order. review_ready does not "
                "change OQ-002, prove write suppression, hidden storage, or an exact "
                "alias map, establish mask invariance, or establish VERIFIED_HARDWARE "
                "without engineering review of all raw captures and physical setups. "
                "It does not generalize beyond the paired, identified specimen."
            ),
            "minimum_runs": self.minimum_runs,
            "minimum_runs_met": self.minimum_runs_met,
            "complete": self.complete,
            "fixture_valid": self.fixture_valid,
            "review_ready": self.review_ready,
            "acceptance_complete": self.acceptance_complete,
            "specimen_id": self.specimen_id,
            "specimen_scope": self.specimen_scope,
            "specimen_pair_errors": list(self.specimen_pair_errors),
            "directions": [
                {
                    "direction": summary.direction,
                    "run_count": summary.run_count,
                    "minimum_runs_met": summary.minimum_runs_met,
                    "complete": summary.complete,
                    "repeatable": summary.repeatable,
                    "fixture_valid": summary.fixture_valid,
                    "capture_sha256": summary.capture_sha256,
                    "classifications": list(summary.classifications),
                    "observations": [
                        _observation_json(observation)
                        for observation in summary.observations
                    ],
                    "evidence_package": _package_json(summary.evidence_package),
                }
                for summary in self.directions
            ],
            "prior_read_evidence": {
                "complete": self.prior_read_evidence.complete,
                "errors": list(self.prior_read_evidence.errors),
                "report_sha256": self.prior_read_evidence.report_sha256,
                "specimen_id": self.prior_read_evidence.specimen_id,
                "specimen_scope": self.prior_read_evidence.specimen_scope,
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


def _observation_json(observation: Observation) -> dict[str, object]:
    return {
        "direction": observation.direction,
        "run": observation.run,
        "classification": observation.classification,
        "output_sequence": [
            f"0x{value:04x}" for value in observation.output_sequence
        ],
        "output_samples": [
            _sample_json(sample) for sample in observation.output_samples
        ],
        "valid_scan_sha256": observation.valid_scan_sha256,
        "changed_valid_addresses": [
            f"0x{address:02x}" for address in observation.changed_valid_addresses
        ],
        "absent_observations": [
            {
                "address": f"0x{item.address:02x}",
                "expected_sentinel": f"0x{item.expected_sentinel:04x}",
                "observed": f"0x{item.observed:04x}",
                "relationship": item.relationship,
            }
            for item in observation.absent_observations
        ],
        "terminal_seen": observation.terminal_seen,
        "capture_complete": observation.capture_complete,
        "fixture_valid": observation.fixture_valid,
        "warnings": list(observation.warnings),
    }


def _package_json(package: EvidencePackage) -> dict[str, object]:
    return {
        "complete": package.complete,
        "errors": list(package.errors),
        "program_image_sha256": package.program_image_sha256,
        "verified_artifacts": list(package.verified_artifacts),
    }


def _hash_file(path: Path) -> str:
    digest = sha256()
    with path.open("rb") as input_file:
        for chunk in iter(lambda: input_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _hash_words(words: tuple[int, ...]) -> str:
    digest = sha256()
    for word in words:
        digest.update(word.to_bytes(2, byteorder="big"))
    return digest.hexdigest()


def _fixture_words(direction: str) -> tuple[int, ...]:
    words = list(ASCENDING_WORDS)
    if direction == "DESCENDING":
        for address, word in DESCENDING_REPLACEMENTS.items():
            words[address] = word
    return tuple(words)


def _program_read(sample: EdgeSample, address: int, data: int) -> bool:
    return (
        sample.rs_n == 1
        and sample.men_n == 0
        and sample.we_n == 1
        and sample.den_n == 1
        and sample.address == address
        and sample.data == data
    )


def _matches(samples: tuple[EdgeSample, ...], anchor: tuple[int, int]) -> list[int]:
    return [
        index
        for index, sample in enumerate(samples)
        if _program_read(sample, anchor[0], anchor[1])
    ]


def _absent_address(direction: str, index: int) -> int:
    return 0x90 + index if direction == "ASCENDING" else 0xFF - index


def _sentinel(index: int) -> int:
    return 0xA06F - index


def _relationship(observed: int, expected: int) -> str:
    if observed == expected:
        return "STORED_SENTINEL"
    if observed == 0:
        return "ZERO_VALUE"
    return f"OTHER_{observed:04x}"


def _classify(
    output_count: int,
    changed_count: int,
    absent: tuple[AbsentObservation, ...],
) -> str:
    if output_count < COMPLETE_OUTPUT_COUNT:
        return f"PARTIAL_OUTPUT_STREAM_{output_count:03d}"
    if output_count > COMPLETE_OUTPUT_COUNT:
        return f"EXTRA_OUTPUT_STREAM_{output_count:03d}"
    sentinel_matches = sum(item.relationship == "STORED_SENTINEL" for item in absent)
    zero_values = sum(item.relationship == "ZERO_VALUE" for item in absent)
    other_values = len(absent) - sentinel_matches - zero_values
    return (
        f"COMPLETE_VALID_CHANGED_{changed_count:03d}_SM_{sentinel_matches:03d}_"
        f"ZV_{zero_values:03d}_OT_{other_values:03d}"
    )


def analyze_direction(
    direction: str,
    runs: Mapping[str, tuple[EdgeSample, ...]],
) -> tuple[Observation, ...]:
    observations: list[Observation] = []
    expected_marker = 0x0041 if direction == "ASCENDING" else 0x0042
    for run, samples in runs.items():
        start_anchors = _matches(samples, START_OUT)
        if not start_anchors:
            raise CaptureError(
                f"{direction} run {run!r}: exact start-marker OUT fetch is absent"
            )
        output_indexes = [
            index for index, sample in enumerate(samples) if sample.we_n == 0
        ]
        outputs = tuple(samples[index] for index in output_indexes)
        sequence = tuple(sample.data for sample in outputs)
        warnings: list[str] = []
        for ordinal, sample in enumerate(outputs, start=1):
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
        capture_complete = len(sequence) == COMPLETE_OUTPUT_COUNT
        terminal = _matches(samples, TERMINAL_BRANCH)
        anchor_indexes: list[int] = []
        absent_observations: tuple[AbsentObservation, ...] = ()
        changed_addresses: tuple[int, ...] = ()
        valid_scan: tuple[int, ...] = ()
        if capture_complete:
            groups = {
                START_OUT: start_anchors,
                VALID_SCAN_OUT: _matches(samples, VALID_SCAN_OUT),
                ABSENT_OUT[direction]: _matches(samples, ABSENT_OUT[direction]),
                END_OUT: _matches(samples, END_OUT),
            }
            expected_counts = {
                START_OUT: 1,
                VALID_SCAN_OUT: VALID_COUNT,
                ABSENT_OUT[direction]: ABSENT_COUNT,
                END_OUT: 1,
            }
            for anchor, count in expected_counts.items():
                if len(groups[anchor]) != count:
                    warnings.append(
                        f"OUT fetch 0x{anchor[0]:03x}/0x{anchor[1]:04x} appears "
                        f"{len(groups[anchor])} times, expected {count}"
                    )
            if all(len(groups[item]) == count for item, count in expected_counts.items()):
                anchor_indexes = (
                    groups[START_OUT]
                    + groups[VALID_SCAN_OUT]
                    + groups[ABSENT_OUT[direction]]
                    + groups[END_OUT]
                )
                for index, (anchor_index, output_index) in enumerate(
                    zip(anchor_indexes, output_indexes)
                ):
                    if anchor_index >= output_index:
                        warnings.append(
                            f"output {index} does not follow its checked OUT fetch"
                        )
                    if index + 1 < COMPLETE_OUTPUT_COUNT:
                        if output_index >= anchor_indexes[index + 1]:
                            warnings.append(
                                f"output {index} overlaps the next checked OUT fetch"
                            )
            if sequence[0] != expected_marker:
                warnings.append(
                    f"start marker is not 0x{expected_marker:04x}"
                )
            if sequence[-1] != 0x004F:
                warnings.append("terminal marker is not 0x004f")
            valid_scan = sequence[1 : 1 + VALID_COUNT]
            changed_addresses = tuple(
                0x8F - index
                for index, value in enumerate(valid_scan)
                if value != 0
            )
            absent_values = sequence[1 + VALID_COUNT : -1]
            absent_observations = tuple(
                AbsentObservation(
                    address=_absent_address(direction, index),
                    expected_sentinel=_sentinel(index),
                    observed=value,
                    relationship=_relationship(value, _sentinel(index)),
                )
                for index, value in enumerate(absent_values)
            )
            if not terminal or terminal[0] <= output_indexes[-1]:
                warnings.append("complete flow does not reach the terminal branch")
        else:
            if len(sequence) > COMPLETE_OUTPUT_COUNT:
                warnings.append("capture contains output cycles beyond the fixture")
            if terminal:
                warnings.append("terminal branch appears before a complete output stream")

        framing_indexes = start_anchors + anchor_indexes + output_indexes
        last_event = max(framing_indexes)
        if last_event + 4 >= len(samples):
            raise CaptureError(
                f"{direction} run {run!r}: fewer than four falling boundaries "
                "follow the last checked fetch/output event"
            )
        observations.append(
            Observation(
                direction=direction,
                run=run,
                classification=_classify(
                    len(sequence),
                    len(changed_addresses),
                    absent_observations,
                ),
                output_sequence=sequence,
                output_samples=outputs,
                valid_scan_sha256=(
                    _hash_words(valid_scan) if len(valid_scan) == VALID_COUNT else None
                ),
                changed_valid_addresses=changed_addresses,
                absent_observations=absent_observations,
                terminal_seen=bool(terminal),
                capture_complete=capture_complete,
                fixture_valid=not warnings,
                warnings=tuple(warnings),
            )
        )
    return tuple(observations)


def _validate_exact_image(
    direction: str,
    program_image: Path | None,
    package: EvidencePackage,
) -> EvidencePackage:
    errors = list(package.errors)
    if program_image is not None and program_image.is_file():
        try:
            image = program_image.read_bytes()
        except OSError as error:
            errors.append(f"cannot read checked {direction} image: {error}")
        else:
            expected = b"".join(
                word.to_bytes(2, byteorder="big")
                for word in _fixture_words(direction)
            )
            if image != expected:
                errors.append(
                    f"program image is not the exact big-endian {direction} fixture"
                )
    return EvidencePackage(
        complete=not errors,
        errors=tuple(errors),
        program_image_sha256=package.program_image_sha256,
        verified_artifacts=package.verified_artifacts,
    )


def _metadata_object(path: Path | None) -> dict[str, object]:
    if path is None:
        return {}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return {}
    return value if isinstance(value, dict) else {}


def _validate_prior_read_report(path: Path | None) -> PriorReadEvidence:
    if path is None:
        return PriorReadEvidence(
            False,
            ("prior stage-1 report was not supplied",),
            None,
            None,
            "UNQUALIFIED",
        )
    try:
        report_hash = _hash_file(path)
        report = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        return PriorReadEvidence(
            False,
            (f"cannot read prior stage-1 report: {error}",),
            None,
            None,
            "UNQUALIFIED",
        )
    errors: list[str] = []
    if not isinstance(report, dict):
        errors.append("prior stage-1 report root must be an object")
        report = {}
    if report.get("schema_version") != 1:
        errors.append("prior stage-1 report schema_version must be 1")
    if report.get("review_ready") is not True:
        errors.append("prior stage-1 report is not review_ready")
    if report.get("acceptance_complete") is not False:
        errors.append("prior stage-1 report must retain incomplete acceptance")
    if report.get("complete") is not True or report.get("fixture_valid") is not True:
        errors.append("prior stage-1 report is not complete and fixture-valid")
    if report.get("minimum_conditions_met") is not True:
        errors.append("prior stage-1 report lacks reset/cold-power minima")
    evidence = report.get("evidence_package")
    if not isinstance(evidence, dict) or evidence.get("complete") is not True:
        errors.append("prior stage-1 report lacks a complete evidence package")
    claim = report.get("claim_boundary")
    if not isinstance(claim, str) or "Stage-1 controlled-history" not in claim:
        errors.append("prior report is not identified as the stage-1 read workflow")
    specimen_id = report.get("specimen_id")
    if not isinstance(specimen_id, str) or not specimen_id.strip():
        errors.append("prior stage-1 report lacks a specimen_id")
        specimen_id = None
    specimen_scope = report.get("specimen_scope")
    if specimen_scope != "this_specimen_only":
        errors.append("prior stage-1 report is not this_specimen_only")
        specimen_scope = "UNQUALIFIED"
    return PriorReadEvidence(
        not errors,
        tuple(errors),
        report_hash,
        specimen_id,
        specimen_scope,
    )


def _merge_specimen_evidence(
    package: EvidencePackage,
    specimen: SpecimenEvidence,
) -> EvidencePackage:
    errors = package.errors + specimen.errors
    return EvidencePackage(
        complete=not errors,
        errors=errors,
        program_image_sha256=package.program_image_sha256,
        verified_artifacts=tuple(
            sorted(
                set(package.verified_artifacts)
                | set(specimen.verified_artifacts)
            )
        ),
    )


def _validate_specimen_pair(
    specimens: Mapping[str, SpecimenEvidence],
    prior: PriorReadEvidence,
) -> tuple[str, ...]:
    errors: list[str] = []
    ascending = specimens["ASCENDING"].metadata
    descending = specimens["DESCENDING"].metadata
    for field in (
        "specimen_id",
        "device_marking",
        "tracking_date_string",
        "lot_string",
        "package_type",
    ):
        if ascending.get(field) != descending.get(field):
            errors.append(
                f"ascending and descending metadata disagree on specimen {field}"
            )
    if (
        prior.specimen_id is not None
        and ascending.get("specimen_id") != prior.specimen_id
    ):
        errors.append("write metadata specimen_id differs from the stage-1 report")
    return tuple(errors)


def _validate_workflow_link(
    direction: str,
    metadata_path: Path | None,
    prior: PriorReadEvidence,
    package: EvidencePackage,
) -> EvidencePackage:
    errors = list(package.errors)
    metadata = _metadata_object(metadata_path)
    if metadata.get("prior_read_report_sha256") != prior.report_sha256:
        errors.append(
            f"{direction} metadata does not pin the supplied stage-1 report"
        )
    if metadata.get("capture_stage") != "write_after_pinned_read_only":
        errors.append(
            f"{direction} metadata does not declare write_after_pinned_read_only"
        )
    return EvidencePackage(
        complete=not errors,
        errors=tuple(errors),
        program_image_sha256=package.program_image_sha256,
        verified_artifacts=package.verified_artifacts,
    )


def _read_capture(path: Path) -> dict[str, tuple[EdgeSample, ...]]:
    try:
        with path.open("r", encoding="utf-8", newline="") as input_file:
            return read_normalized_capture(input_file)
    except (OSError, UnicodeError) as error:
        raise CaptureError(f"cannot read capture {path}: {error}") from error


def build_report(
    ascending_capture: Path,
    descending_capture: Path,
    *,
    minimum_runs: int = 1,
    ascending_metadata: Path | None = None,
    descending_metadata: Path | None = None,
    ascending_image: Path | None = None,
    descending_image: Path | None = None,
    prior_read_report: Path | None = None,
    artifact_root: Path | None = None,
) -> CaptureReport:
    if minimum_runs <= 0:
        raise CaptureError("minimum_runs must be positive")
    capture_paths = {
        "ASCENDING": ascending_capture,
        "DESCENDING": descending_capture,
    }
    metadata_paths = {
        "ASCENDING": ascending_metadata,
        "DESCENDING": descending_metadata,
    }
    image_paths = {
        "ASCENDING": ascending_image,
        "DESCENDING": descending_image,
    }
    prior = _validate_prior_read_report(prior_read_report)
    specimens = {
        direction: validate_specimen_evidence(
            metadata_paths[direction],
            capture_paths[direction],
            artifact_root,
            fixture_source_sha256=FIXTURE_SOURCE_SHA256[direction],
            fixture_words={
                address: word
                for address, word in enumerate(_fixture_words(direction))
            },
        )
        for direction in DIRECTIONS
    }
    specimen_pair_errors = _validate_specimen_pair(specimens, prior)
    summaries: list[DirectionSummary] = []
    for direction in DIRECTIONS:
        runs = _read_capture(capture_paths[direction])
        observations = analyze_direction(direction, runs)
        package = validate_evidence_package(
            metadata_paths[direction],
            image_paths[direction],
            artifact_root,
        )
        package = _merge_specimen_evidence(package, specimens[direction])
        package = _validate_exact_image(direction, image_paths[direction], package)
        package = _validate_workflow_link(
            direction,
            metadata_paths[direction],
            prior,
            package,
        )
        summaries.append(
            DirectionSummary(
                direction=direction,
                run_count=len(runs),
                minimum_runs_met=len(runs) >= minimum_runs,
                complete=all(item.capture_complete for item in observations),
                repeatable=len({item.output_sequence for item in observations}) == 1,
                fixture_valid=all(item.fixture_valid for item in observations),
                capture_sha256=_hash_file(capture_paths[direction]),
                classifications=tuple(
                    item.classification for item in observations
                ),
                observations=observations,
                evidence_package=package,
            )
        )
    minimum_met = all(item.minimum_runs_met for item in summaries)
    complete = all(item.complete for item in summaries)
    fixture_valid = all(item.fixture_valid for item in summaries)
    review_ready = (
        minimum_met
        and complete
        and fixture_valid
        and prior.complete
        and all(item.evidence_package.complete for item in summaries)
        and not specimen_pair_errors
    )
    specimen_id = specimens["ASCENDING"].specimen_id
    specimen_scope = specimens["ASCENDING"].specimen_scope
    if specimen_pair_errors:
        specimen_id = None
        specimen_scope = "UNQUALIFIED"
    return CaptureReport(
        minimum_runs=minimum_runs,
        minimum_runs_met=minimum_met,
        complete=complete,
        fixture_valid=fixture_valid,
        review_ready=review_ready,
        acceptance_complete=False,
        specimen_id=specimen_id,
        specimen_scope=specimen_scope,
        specimen_pair_errors=specimen_pair_errors,
        directions=tuple(summaries),
        prior_read_evidence=prior,
    )


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ascending_capture", type=Path)
    parser.add_argument("descending_capture", type=Path)
    parser.add_argument("--ascending-metadata", type=Path)
    parser.add_argument("--descending-metadata", type=Path)
    parser.add_argument("--ascending-image", type=Path)
    parser.add_argument("--descending-image", type=Path)
    parser.add_argument("--prior-read-report", type=Path)
    parser.add_argument("--artifact-root", type=Path)
    parser.add_argument("--minimum-runs", type=int, default=1)
    parser.add_argument("--require-review-ready", action="store_true")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_argument_parser().parse_args(argv)
    try:
        report = build_report(
            args.ascending_capture,
            args.descending_capture,
            minimum_runs=args.minimum_runs,
            ascending_metadata=args.ascending_metadata,
            descending_metadata=args.descending_metadata,
            ascending_image=args.ascending_image,
            descending_image=args.descending_image,
            prior_read_report=args.prior_read_report,
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
