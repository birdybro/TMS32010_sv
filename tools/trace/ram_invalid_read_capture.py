#!/usr/bin/env python3
"""Classify original-TMS32010 controlled-history absent-RAM read sweeps."""

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
from tools.trace.specimen_evidence import validate_specimen_evidence


FIXTURE_WORDS = (
    0x6E00, 0x7F8A, 0x7F89, 0x5000, 0x7E01, 0x5005, 0x7F89,
    0x1005, 0x5001, 0x7E31, 0x5002, 0x7E32, 0x5003, 0x7E3F,
    0x5004, 0x4F02, 0x7090, 0x716F, 0x6880, 0x4F00, 0x4FA1,
    0xF400, 0x0012, 0x4F03, 0x7090, 0x716F, 0x6880, 0x4F01,
    0x4FA1, 0xF400, 0x001A, 0x4F04, 0x7F80, 0xF900, 0x0021,
)
FIXTURE_SOURCE_SHA256 = (
    "2363d96f218d63a8266d8daef852a4bddb31b45ea537e30b3ef16c37a19d647a"
)
START_OUT = (0x00F, 0x4F02)
ZERO_PREDECESSOR_OUT = (0x013, 0x4F00)
ZERO_ABSENT_OUT = (0x014, 0x4FA1)
MIDDLE_OUT = (0x017, 0x4F03)
ONE_PREDECESSOR_OUT = (0x01B, 0x4F01)
ONE_ABSENT_OUT = (0x01C, 0x4FA1)
END_OUT = (0x01F, 0x4F04)
TERMINAL_BRANCH = (0x021, 0xF900)
ABSENT_COUNT = 112
COMPLETE_OUTPUT_COUNT = 451
RUN_CONDITIONS = frozenset(("reset", "cold_power"))


@dataclass(frozen=True)
class AddressObservation:
    address: int
    after_zero: int
    after_one: int
    relationship: str


@dataclass(frozen=True)
class Observation:
    run: str
    condition: str | None
    classification: str
    output_sequence: tuple[int, ...]
    output_samples: tuple[EdgeSample, ...]
    address_observations: tuple[AddressObservation, ...]
    terminal_seen: bool
    capture_complete: bool
    fixture_valid: bool
    warnings: tuple[str, ...]


@dataclass(frozen=True)
class CaptureReport:
    capture_sha256: str
    run_count: int
    reset_run_count: int
    cold_power_run_count: int
    minimum_reset_runs: int
    minimum_cold_power_runs: int
    minimum_conditions_met: bool
    complete: bool
    fixture_valid: bool
    repeatable: bool
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
                "Stage-1 controlled-history read classification and package "
                "validation only; review_ready does not change OQ-002, prove an "
                "open bus, hidden storage, or an alias, qualify destructive writes, "
                "establish mask invariance, or establish VERIFIED_HARDWARE without "
                "engineering review of raw captures and the physical setup. It "
                "does not generalize beyond the identified specimen."
            ),
            "capture_sha256": self.capture_sha256,
            "run_count": self.run_count,
            "reset_run_count": self.reset_run_count,
            "cold_power_run_count": self.cold_power_run_count,
            "minimum_reset_runs": self.minimum_reset_runs,
            "minimum_cold_power_runs": self.minimum_cold_power_runs,
            "minimum_conditions_met": self.minimum_conditions_met,
            "complete": self.complete,
            "fixture_valid": self.fixture_valid,
            "repeatable": self.repeatable,
            "review_ready": self.review_ready,
            "acceptance_complete": self.acceptance_complete,
            "specimen_id": self.specimen_id,
            "specimen_scope": self.specimen_scope,
            "classifications": list(self.classifications),
            "observations": [
                {
                    "run": observation.run,
                    "condition": observation.condition,
                    "classification": observation.classification,
                    "output_sequence": [
                        f"0x{value:04x}"
                        for value in observation.output_sequence
                    ],
                    "output_samples": [
                        _sample_json(sample)
                        for sample in observation.output_samples
                    ],
                    "address_observations": [
                        {
                            "address": f"0x{item.address:02x}",
                            "after_zero": f"0x{item.after_zero:04x}",
                            "after_one": f"0x{item.after_one:04x}",
                            "relationship": item.relationship,
                        }
                        for item in observation.address_observations
                    ],
                    "terminal_seen": observation.terminal_seen,
                    "capture_complete": observation.capture_complete,
                    "fixture_valid": observation.fixture_valid,
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


def _relationship(after_zero: int, after_one: int) -> str:
    if after_zero == 0x0000 and after_one == 0xFFFF:
        return "PREDECESSOR_TRACKING"
    if after_zero == after_one:
        return f"HISTORY_INDEPENDENT_{after_zero:04x}"
    return f"HISTORY_DEPENDENT_{after_zero:04x}_{after_one:04x}"


def _classify(addresses: tuple[AddressObservation, ...], output_count: int) -> str:
    if output_count < COMPLETE_OUTPUT_COUNT:
        return f"PARTIAL_OUTPUT_STREAM_{output_count:03d}"
    if output_count > COMPLETE_OUTPUT_COUNT:
        return f"EXTRA_OUTPUT_STREAM_{output_count:03d}"
    counts = {
        "PREDECESSOR_TRACKING": 0,
        "HISTORY_INDEPENDENT": 0,
        "HISTORY_DEPENDENT": 0,
    }
    for observation in addresses:
        if observation.relationship == "PREDECESSOR_TRACKING":
            counts["PREDECESSOR_TRACKING"] += 1
        elif observation.relationship.startswith("HISTORY_INDEPENDENT"):
            counts["HISTORY_INDEPENDENT"] += 1
        else:
            counts["HISTORY_DEPENDENT"] += 1
    return (
        "COMPLETE_PT_"
        f"{counts['PREDECESSOR_TRACKING']:03d}_HI_"
        f"{counts['HISTORY_INDEPENDENT']:03d}_HD_"
        f"{counts['HISTORY_DEPENDENT']:03d}"
    )


def _expected_anchor_groups() -> tuple[tuple[tuple[int, int], int], ...]:
    return (
        (START_OUT, 1),
        (ZERO_PREDECESSOR_OUT, ABSENT_COUNT),
        (ZERO_ABSENT_OUT, ABSENT_COUNT),
        (MIDDLE_OUT, 1),
        (ONE_PREDECESSOR_OUT, ABSENT_COUNT),
        (ONE_ABSENT_OUT, ABSENT_COUNT),
        (END_OUT, 1),
    )


def analyze_runs(
    runs: Mapping[str, tuple[EdgeSample, ...]],
    conditions: Mapping[str, str] | None = None,
) -> tuple[Observation, ...]:
    conditions = conditions or {}
    observations: list[Observation] = []
    for run, samples in runs.items():
        start_anchors = _matches(samples, START_OUT)
        if not start_anchors:
            raise CaptureError(
                f"run {run!r}: exact read-only start-marker OUT fetch is absent"
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
        address_observations: tuple[AddressObservation, ...] = ()
        terminal = _matches(samples, TERMINAL_BRANCH)
        all_anchor_indexes: list[int] = []
        if capture_complete:
            anchor_groups: dict[tuple[int, int], list[int]] = {}
            for anchor, count in _expected_anchor_groups():
                matches = _matches(samples, anchor)
                anchor_groups[anchor] = matches
                if len(matches) != count:
                    warnings.append(
                        f"OUT fetch 0x{anchor[0]:03x}/0x{anchor[1]:04x} "
                        f"appears {len(matches)} times, expected {count}"
                    )
            if all(
                len(anchor_groups[anchor]) == count
                for anchor, count in _expected_anchor_groups()
            ):
                all_anchor_indexes.append(anchor_groups[START_OUT][0])
                for index in range(ABSENT_COUNT):
                    all_anchor_indexes.append(
                        anchor_groups[ZERO_PREDECESSOR_OUT][index]
                    )
                    all_anchor_indexes.append(anchor_groups[ZERO_ABSENT_OUT][index])
                all_anchor_indexes.append(anchor_groups[MIDDLE_OUT][0])
                for index in range(ABSENT_COUNT):
                    all_anchor_indexes.append(
                        anchor_groups[ONE_PREDECESSOR_OUT][index]
                    )
                    all_anchor_indexes.append(anchor_groups[ONE_ABSENT_OUT][index])
                all_anchor_indexes.append(anchor_groups[END_OUT][0])
                for index, (anchor_index, output_index) in enumerate(
                    zip(all_anchor_indexes, output_indexes)
                ):
                    if anchor_index >= output_index:
                        warnings.append(
                            f"output {index} does not follow its checked OUT fetch"
                        )
                    if index + 1 < COMPLETE_OUTPUT_COUNT:
                        if output_index >= all_anchor_indexes[index + 1]:
                            warnings.append(
                                f"output {index} overlaps the next checked OUT fetch"
                            )
            if sequence[0] != 0x0031:
                warnings.append("first marker is not 0x0031")
            if sequence[225] != 0x0032:
                warnings.append("middle marker is not 0x0032")
            if sequence[450] != 0x003F:
                warnings.append("terminal marker is not 0x003f")
            for index in range(ABSENT_COUNT):
                if sequence[1 + (2 * index)] != 0x0000:
                    warnings.append(
                        f"address 0x{0x90 + index:02x} zero predecessor is not zero"
                    )
                if sequence[226 + (2 * index)] != 0xFFFF:
                    warnings.append(
                        f"address 0x{0x90 + index:02x} one predecessor is not 0xffff"
                    )
            address_observations = tuple(
                AddressObservation(
                    address=0x90 + index,
                    after_zero=sequence[2 + (2 * index)],
                    after_one=sequence[227 + (2 * index)],
                    relationship=_relationship(
                        sequence[2 + (2 * index)],
                        sequence[227 + (2 * index)],
                    ),
                )
                for index in range(ABSENT_COUNT)
            )
            if not terminal or terminal[0] <= output_indexes[-1]:
                warnings.append("complete flow does not reach the terminal branch")
        else:
            if len(sequence) > COMPLETE_OUTPUT_COUNT:
                warnings.append("capture contains output cycles beyond the fixture")
            if terminal:
                warnings.append("terminal branch appears before a complete output stream")

        framing_indexes = start_anchors + all_anchor_indexes + output_indexes
        last_event = max(framing_indexes)
        if last_event + 4 >= len(samples):
            raise CaptureError(
                f"run {run!r}: fewer than four falling boundaries follow the "
                "last checked fetch/output event"
            )
        observations.append(
            Observation(
                run=run,
                condition=conditions.get(run),
                classification=_classify(address_observations, len(sequence)),
                output_sequence=sequence,
                output_samples=outputs,
                address_observations=address_observations,
                terminal_seen=bool(terminal),
                capture_complete=capture_complete,
                fixture_valid=not warnings,
                warnings=tuple(warnings),
            )
        )
    return tuple(observations)


def _validate_exact_image(
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
                    "program image is not the exact big-endian absent-read fixture"
                )
    return EvidencePackage(
        complete=not errors,
        errors=tuple(errors),
        program_image_sha256=package.program_image_sha256,
        verified_artifacts=package.verified_artifacts,
    )


def _metadata_conditions(
    metadata_path: Path | None,
    run_names: set[str],
) -> tuple[dict[str, str], tuple[str, ...]]:
    if metadata_path is None:
        return {}, ("metadata run_conditions were not supplied",)
    try:
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        return {}, (f"cannot read metadata run_conditions: {error}",)
    conditions = metadata.get("run_conditions") if isinstance(metadata, dict) else None
    if not isinstance(conditions, dict):
        return {}, ("metadata run_conditions must be an object",)
    errors: list[str] = []
    normalized: dict[str, str] = {}
    for run, condition in conditions.items():
        if not isinstance(run, str) or not run:
            errors.append("metadata run_conditions contains an invalid run name")
            continue
        if not isinstance(condition, str) or condition not in RUN_CONDITIONS:
            errors.append(
                f"metadata run_conditions[{run!r}] must be reset or cold_power"
            )
            continue
        normalized[run] = condition
    missing = sorted(run_names - set(normalized))
    extra = sorted(set(normalized) - run_names)
    if missing:
        errors.append(f"metadata run_conditions lacks capture runs: {missing!r}")
    if extra:
        errors.append(f"metadata run_conditions contains extra runs: {extra!r}")
    return normalized, tuple(errors)


def build_report(
    capture_path: Path,
    *,
    minimum_reset_runs: int = 32,
    minimum_cold_power_runs: int = 8,
    metadata_path: Path | None = None,
    program_image: Path | None = None,
    artifact_root: Path | None = None,
) -> CaptureReport:
    if minimum_reset_runs <= 0 or minimum_cold_power_runs <= 0:
        raise CaptureError("minimum run counts must be positive")
    try:
        with capture_path.open("r", encoding="utf-8", newline="") as input_file:
            runs = read_normalized_capture(input_file)
    except (OSError, UnicodeError) as error:
        raise CaptureError(f"cannot read capture: {error}") from error
    conditions, condition_errors = _metadata_conditions(
        metadata_path,
        set(runs),
    )
    observations = analyze_runs(runs, conditions)
    base_package = validate_evidence_package(
        metadata_path,
        program_image,
        artifact_root,
    )
    specimen = validate_specimen_evidence(
        metadata_path,
        capture_path,
        artifact_root,
        fixture_source_sha256=FIXTURE_SOURCE_SHA256,
        fixture_words={
            address: word for address, word in enumerate(FIXTURE_WORDS)
        },
    )
    base_package = EvidencePackage(
        complete=not (base_package.errors or specimen.errors),
        errors=base_package.errors + specimen.errors,
        program_image_sha256=base_package.program_image_sha256,
        verified_artifacts=tuple(
            sorted(
                set(base_package.verified_artifacts)
                | set(specimen.verified_artifacts)
            )
        ),
    )
    package = _validate_exact_image(program_image, base_package)
    if condition_errors:
        package = EvidencePackage(
            complete=False,
            errors=package.errors + condition_errors,
            program_image_sha256=package.program_image_sha256,
            verified_artifacts=package.verified_artifacts,
        )
    reset_count = sum(value == "reset" for value in conditions.values())
    cold_count = sum(value == "cold_power" for value in conditions.values())
    minimum_met = (
        reset_count >= minimum_reset_runs
        and cold_count >= minimum_cold_power_runs
    )
    complete = all(item.capture_complete for item in observations)
    fixture_valid = all(item.fixture_valid for item in observations)
    repeatable = len({item.output_sequence for item in observations}) == 1
    return CaptureReport(
        capture_sha256=_hash_file(capture_path),
        run_count=len(runs),
        reset_run_count=reset_count,
        cold_power_run_count=cold_count,
        minimum_reset_runs=minimum_reset_runs,
        minimum_cold_power_runs=minimum_cold_power_runs,
        minimum_conditions_met=minimum_met,
        complete=complete,
        fixture_valid=fixture_valid,
        repeatable=repeatable,
        review_ready=minimum_met and complete and fixture_valid and package.complete,
        acceptance_complete=False,
        specimen_id=specimen.specimen_id,
        specimen_scope=specimen.specimen_scope,
        classifications=tuple(item.classification for item in observations),
        observations=observations,
        evidence_package=package,
    )


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("capture", type=Path)
    parser.add_argument("--metadata", type=Path)
    parser.add_argument("--program-image", type=Path)
    parser.add_argument("--artifact-root", type=Path)
    parser.add_argument("--minimum-reset-runs", type=int, default=32)
    parser.add_argument("--minimum-cold-power-runs", type=int, default=8)
    parser.add_argument("--require-review-ready", action="store_true")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_argument_parser().parse_args(argv)
    try:
        report = build_report(
            args.capture,
            minimum_reset_runs=args.minimum_reset_runs,
            minimum_cold_power_runs=args.minimum_cold_power_runs,
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
