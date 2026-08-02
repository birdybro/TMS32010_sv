#!/usr/bin/env python3
"""Classify original-TMS32010 forced simultaneous INC/DEC captures."""

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


FIXTURE_WORDS = (
    0x6E00, 0x7E33, 0x5000, 0x7E01, 0x5010, 0x7EFF,
    0x5011, 0x2810, 0x0011, 0x5012, 0x4F00, 0x7000,
    0x6880, 0x68B8, 0x3020, 0x4F20, 0x3812, 0x6880,
    0x68B8, 0x3021, 0x4F21, 0xF900, 0x0015,
)
ARMED_OUT = (0x00A, 0x4F00)
FIRST_FORCED = (0x00D, 0x68B8)
FIRST_RESULT_OUT = (0x00F, 0x4F20)
SECOND_FORCED = (0x012, 0x68B8)
SECOND_RESULT_OUT = (0x014, 0x4F21)
TERMINAL_BRANCH = (0x015, 0xF900)

NO_NET_UPDATE = "NO_NET_UPDATE"
INCREMENT_PRIORITY = "INCREMENT_PRIORITY"
DECREMENT_PRIORITY = "DECREMENT_PRIORITY"
NONCOMPLETION_AFTER_FIRST = "NONCOMPLETION_AFTER_FIRST_FORCED_WORD"
NONCOMPLETION_BEFORE_SECOND = "NONCOMPLETION_BEFORE_SECOND_FORCED_WORD"
NONCOMPLETION_AFTER_SECOND = "NONCOMPLETION_AFTER_SECOND_FORCED_WORD"
OTHER_SEQUENCE = "OTHER_SEQUENCE"
RESOLVED_CANDIDATES = frozenset(
    (NO_NET_UPDATE, INCREMENT_PRIORITY, DECREMENT_PRIORITY)
)


@dataclass(frozen=True)
class Observation:
    run: str
    classification: str
    port_sequence: tuple[int, ...]
    output_samples: tuple[EdgeSample, ...]
    first_forced_fetch_count: int
    second_forced_fetch_count: int
    terminal_seen: bool
    fixture_valid: bool
    warnings: tuple[str, ...]


@dataclass(frozen=True)
class CaptureReport:
    capture_sha256: str
    run_count: int
    minimum_runs: int
    minimum_runs_met: bool
    repeatable: bool
    candidate_resolved: bool
    fixture_valid: bool
    review_ready: bool
    classifications: tuple[str, ...]
    observations: tuple[Observation, ...]
    evidence_package: EvidencePackage

    def to_json_object(self) -> dict[str, object]:
        return {
            "schema_version": 1,
            "claim_boundary": (
                "Classification and package validation only; this output does not "
                "change OQ-010, make 0x68b8 a supported instruction, use MAME or "
                "IKA as a silicon oracle, or establish VERIFIED_HARDWARE without "
                "engineering review of raw captures and the physical setup."
            ),
            "capture_sha256": self.capture_sha256,
            "run_count": self.run_count,
            "minimum_runs": self.minimum_runs,
            "minimum_runs_met": self.minimum_runs_met,
            "repeatable": self.repeatable,
            "candidate_resolved": self.candidate_resolved,
            "fixture_valid": self.fixture_valid,
            "review_ready": self.review_ready,
            "classifications": list(self.classifications),
            "observations": [
                {
                    **asdict(observation),
                    "port_sequence": [
                        f"0x{value:04x}" for value in observation.port_sequence
                    ],
                    "output_samples": [
                        _sample_json(sample) for sample in observation.output_samples
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


def _expected_image() -> bytes:
    return b"".join(word.to_bytes(2, byteorder="big") for word in FIXTURE_WORDS)


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


def _classify(sequence: tuple[int, ...], second_forced_count: int) -> str:
    if sequence == (0x0033, 0x0000, 0x01FF):
        return NO_NET_UPDATE
    if sequence == (0x0033, 0x0001, 0x0000):
        return INCREMENT_PRIORITY
    if sequence == (0x0033, 0x01FF, 0x01FE):
        return DECREMENT_PRIORITY
    if len(sequence) == 1:
        return NONCOMPLETION_AFTER_FIRST
    if len(sequence) == 2:
        return (
            NONCOMPLETION_AFTER_SECOND
            if second_forced_count
            else NONCOMPLETION_BEFORE_SECOND
        )
    return OTHER_SEQUENCE + "_" + "_".join(f"{value:04x}" for value in sequence)


def analyze_runs(
    runs: Mapping[str, tuple[EdgeSample, ...]],
) -> tuple[Observation, ...]:
    observations: list[Observation] = []
    for run, samples in runs.items():
        armed_anchors = _matches(samples, ARMED_OUT)
        first_forced = _matches(samples, FIRST_FORCED)
        if len(armed_anchors) != 1 or not first_forced:
            raise CaptureError(
                f"run {run!r}: capture must contain one armed OUT fetch and at "
                "least one first 0x68b8 fetch"
            )
        output_indexes = [
            index for index, sample in enumerate(samples) if sample.we_n == 0
        ]
        if not output_indexes:
            raise CaptureError(f"run {run!r}: capture contains no output cycles")
        if output_indexes[0] <= armed_anchors[0] or output_indexes[0] >= first_forced[0]:
            raise CaptureError(
                f"run {run!r}: armed output does not precede the first forced word"
            )

        second_forced = _matches(samples, SECOND_FORCED)
        first_result_anchors = _matches(samples, FIRST_RESULT_OUT)
        second_result_anchors = _matches(samples, SECOND_RESULT_OUT)
        terminal_matches = _matches(samples, TERMINAL_BRANCH)
        warnings: list[str] = []
        outputs = tuple(samples[index] for index in output_indexes)
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
        sequence = tuple(sample.data for sample in outputs)
        if sequence[0] != 0x0033:
            warnings.append("first output is not the 0x0033 armed marker")

        if len(sequence) >= 2:
            if len(first_result_anchors) != 1:
                warnings.append("first result lacks one exact OUT fetch anchor")
            elif not (
                first_forced[0] < first_result_anchors[0] < output_indexes[1]
            ):
                warnings.append("first result OUT fetch/write ordering is invalid")
        if second_forced and len(sequence) >= 2:
            if len(second_forced) != 1:
                warnings.append("second 0x68b8 program read is repeated")
            elif second_forced[0] <= output_indexes[1]:
                warnings.append("second 0x68b8 fetch precedes the first result")
        if len(sequence) >= 3:
            if not second_forced:
                warnings.append("complete flow lacks one exact second 0x68b8 fetch")
            if len(second_result_anchors) != 1:
                warnings.append("second result lacks one exact OUT fetch anchor")
            elif not second_forced or not (
                second_forced[0] < second_result_anchors[0] < output_indexes[2]
            ):
                warnings.append("second result OUT fetch/write ordering is invalid")
            if not terminal_matches or terminal_matches[0] <= output_indexes[2]:
                warnings.append("complete flow does not reach the terminal branch")
        if len(sequence) > 3:
            warnings.append("capture contains extra output cycles")

        last_event = max(first_forced + second_forced + output_indexes)
        if last_event + 4 >= len(samples):
            raise CaptureError(
                f"run {run!r}: fewer than four falling boundaries follow the last "
                "forced-word/output event"
            )
        classification = _classify(sequence, len(second_forced))
        complete_candidate = classification in RESOLVED_CANDIDATES
        if complete_candidate and len(first_forced) != 1:
            warnings.append("complete flow repeats the first 0x68b8 program read")
        observations.append(
            Observation(
                run=run,
                classification=classification,
                port_sequence=sequence,
                output_samples=outputs,
                first_forced_fetch_count=len(first_forced),
                second_forced_fetch_count=len(second_forced),
                terminal_seen=bool(terminal_matches),
                fixture_valid=not warnings,
                warnings=tuple(warnings),
            )
        )
    return tuple(observations)


def _validate_checked_image(
    program_image: Path | None,
    package: EvidencePackage,
) -> EvidencePackage:
    errors = list(package.errors)
    if program_image is not None and program_image.is_file():
        try:
            image = program_image.read_bytes()
        except OSError as error:
            errors.append(f"cannot read checked program image: {error}")
        else:
            if image != _expected_image():
                errors.append(
                    "program image is not the exact big-endian simultaneous-AR fixture"
                )
    return EvidencePackage(
        complete=not errors,
        errors=tuple(errors),
        program_image_sha256=package.program_image_sha256,
        verified_artifacts=package.verified_artifacts,
    )


def build_report(
    capture_path: Path,
    minimum_runs: int = 32,
    metadata_path: Path | None = None,
    program_image: Path | None = None,
    artifact_root: Path | None = None,
) -> CaptureReport:
    if minimum_runs <= 0:
        raise CaptureError("minimum_runs must be positive")
    try:
        with capture_path.open("r", encoding="utf-8", newline="") as input_file:
            runs = read_normalized_capture(input_file)
    except (OSError, UnicodeError) as error:
        raise CaptureError(f"cannot read capture: {error}") from error
    observations = analyze_runs(runs)
    classifications = tuple(item.classification for item in observations)
    repeatable = len(set(classifications)) == 1
    candidate_resolved = repeatable and classifications[0] in RESOLVED_CANDIDATES
    fixture_valid = all(item.fixture_valid for item in observations)
    package = _validate_checked_image(
        program_image,
        validate_evidence_package(metadata_path, program_image, artifact_root),
    )
    minimum_runs_met = len(runs) >= minimum_runs
    return CaptureReport(
        capture_sha256=_hash_file(capture_path),
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
        classifications=classifications,
        observations=observations,
        evidence_package=package,
    )


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("capture", type=Path, help="normalized falling-edge CSV")
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
