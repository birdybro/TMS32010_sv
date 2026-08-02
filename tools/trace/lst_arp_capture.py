#!/usr/bin/env python3
"""Classify original-TMS32010 indirect-LST ARP-precedence captures."""

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


FIXTURE_WORDS = (
    0x6E00, 0x7E33, 0x5000, 0x7EA0, 0x5011, 0x7EA1,
    0x5012, 0x7EB1, 0x5021, 0x7EB0, 0x5022, 0x7E00,
    0x5010, 0x7E01, 0x5030, 0x2830, 0x5020, 0x4F00,
    0x7010, 0x7112, 0x6880, 0x7BA1, 0x4F88, 0x7022,
    0x7120, 0x6881, 0x7BA0, 0x4F88, 0xF900, 0x001C,
)
FIXTURE_SOURCE_SHA256 = (
    "08a9c9b5d9745164b604a7a43c93f3577e83a685d036edb4a311c33d5e0f6a6b"
)
OUT_ANCHORS = ((0x011, 0x4F00), (0x016, 0x4F88), (0x01B, 0x4F88))

MEMORY_WINS = "MEMORY_WORD_ARP_WINS_BOTH"
ENCODED_WINS = "ENCODED_NEXT_ARP_WINS_BOTH"
MIXED_A_MEMORY = "MIXED_A_MEMORY_B_ENCODED"
MIXED_A_ENCODED = "MIXED_A_ENCODED_B_MEMORY"
OTHER_SEQUENCE = "OTHER_SEQUENCE"
RESOLVED_CANDIDATES = frozenset((MEMORY_WINS, ENCODED_WINS))


@dataclass(frozen=True)
class Observation:
    run: str
    classification: str
    port_sequence: tuple[int, ...]
    output_samples: tuple[EdgeSample, ...]
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
                "change OQ-015, choose between MAME and IKA, prove mask-revision "
                "invariance, or establish VERIFIED_HARDWARE without engineering "
                "review of raw captures and the physical setup. It does not "
                "generalize beyond the identified specimen."
            ),
            "capture_sha256": self.capture_sha256,
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


def _classify(sequence: tuple[int, ...]) -> str:
    if sequence == (0x0033, 0x00A0, 0x00B1):
        return MEMORY_WINS
    if sequence == (0x0033, 0x00A1, 0x00B0):
        return ENCODED_WINS
    if sequence == (0x0033, 0x00A0, 0x00B0):
        return MIXED_A_MEMORY
    if sequence == (0x0033, 0x00A1, 0x00B1):
        return MIXED_A_ENCODED
    return OTHER_SEQUENCE + "_" + "_".join(f"{value:04x}" for value in sequence)


def analyze_runs(
    runs: Mapping[str, tuple[EdgeSample, ...]],
) -> tuple[Observation, ...]:
    observations: list[Observation] = []
    for run, samples in runs.items():
        anchor_indexes: list[int] = []
        for address, word in OUT_ANCHORS:
            matches = [
                index
                for index, sample in enumerate(samples)
                if _program_read(sample, address, word)
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
        if len(output_indexes) != 3:
            raise CaptureError(
                f"run {run!r}: expected exactly three active-low WE samples, "
                f"found {len(output_indexes)}"
            )
        if not all(
            anchor_indexes[index] < output_indexes[index]
            for index in range(3)
        ) or not all(
            output_indexes[index] < anchor_indexes[index + 1]
            for index in range(2)
        ):
            raise CaptureError(
                f"run {run!r}: checked OUT fetches and output cycles are out of order"
            )
        if output_indexes[-1] + 2 >= len(samples):
            raise CaptureError(
                f"run {run!r}: fewer than two boundaries follow the final output"
            )
        outputs = tuple(samples[index] for index in output_indexes)
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
        sequence = tuple(sample.data for sample in outputs)
        if sequence[0] != 0x0033:
            warnings.append("first output is not the 0x0033 armed marker")
        observations.append(
            Observation(
                run=run,
                classification=_classify(sequence),
                port_sequence=sequence,
                output_samples=outputs,
                fixture_valid=not warnings,
                warnings=tuple(warnings),
            )
        )
    return tuple(observations)


def _validate_checked_image(
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
            if image != _expected_image():
                errors.append(
                    "program image is not the exact big-endian LST-ARP fixture"
                )
    return EvidencePackage(
        complete=not errors,
        errors=tuple(errors),
        program_image_sha256=package.program_image_sha256,
        verified_artifacts=tuple(sorted(verified)),
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
    specimen = validate_specimen_evidence(
        metadata_path,
        capture_path,
        artifact_root,
        fixture_source_sha256=FIXTURE_SOURCE_SHA256,
        fixture_words={
            address: word for address, word in enumerate(FIXTURE_WORDS)
        },
    )
    package = _validate_checked_image(
        program_image,
        validate_evidence_package(metadata_path, program_image, artifact_root),
        specimen,
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
