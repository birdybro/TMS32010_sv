#!/usr/bin/env python3
"""Normalize paired original-TMS32010 DMOV/LTD RAM-boundary captures."""

from __future__ import annotations

import argparse
import csv
from dataclasses import asdict, dataclass
from hashlib import sha256
import json
from pathlib import Path
import re
import sys
from typing import Mapping, Sequence, TextIO

from tools.trace.push_pop_capture import (
    CaptureError,
    EdgeSample,
    EvidencePackage,
    read_normalized_capture,
    validate_evidence_package,
)


EXPERIMENTS = ("DMOV", "LTD")
BASE_WORDS = (
    0x6E00, 0x6880, 0x708F, 0x7F89, 0x5088, 0xF400, 0x0004,
    0x708F, 0x7E5A, 0x5088, 0x6E00, 0x7E03, 0x5000, 0x6A00,
    0x8005, 0x7E07, 0x6E01, 0x690F, 0x708F, 0x4F88, 0xF400,
    0x0013, 0x4F10, 0x7F80, 0xF900, 0x0018,
)
BOUNDARY_WORD = {"DMOV": 0x690F, "LTD": 0x6B0F}
BOUNDARY_ADDRESS = 0x011
SCAN_OUT = (0x013, 0x4F88)
DIAGNOSTIC_OUT = (0x016, 0x4F10)
TERMINAL_BRANCH = (0x018, 0xF900)
VALID_SCAN_LENGTH = 144
COMPLETE_OUTPUT_LENGTH = 145
DEFINED_SCAN = (0x005A,) + (0x0000,) * 143

REGISTER_COLUMNS = (
    "experiment",
    "run",
    "acc",
    "t",
    "p",
    "ov",
    "ovm",
    "dp",
    "arp",
    "ar0",
    "ar1",
    "transcript_sha256",
)
SHA256_PATTERN = re.compile(r"[0-9a-f]{64}")


@dataclass(frozen=True)
class RegisterObservation:
    experiment: str
    run: str
    acc: int
    t: int
    p: int
    ov: int
    ovm: int
    dp: int
    arp: int
    ar0: int
    ar1: int
    transcript_sha256: str


@dataclass(frozen=True)
class Observation:
    experiment: str
    run: str
    classification: str
    output_sequence: tuple[int, ...]
    output_samples: tuple[EdgeSample, ...]
    valid_scan_sha256: str | None
    changed_valid_addresses: tuple[int, ...]
    diagnostic_word: int | None
    boundary_fetch_count: int
    scan_out_fetch_count: int
    diagnostic_out_fetch_count: int
    terminal_seen: bool
    capture_complete: bool
    fixture_valid: bool
    documented_register_effects_match: bool | None
    register_observation: RegisterObservation | None
    warnings: tuple[str, ...]
    register_differences: tuple[str, ...]


@dataclass(frozen=True)
class ExperimentSummary:
    experiment: str
    run_count: int
    minimum_runs_met: bool
    complete: bool
    repeatable: bool
    fixture_valid: bool
    classifications: tuple[str, ...]
    observations: tuple[Observation, ...]
    capture_sha256: str
    evidence_package: EvidencePackage


@dataclass(frozen=True)
class RegisterEvidence:
    complete: bool
    errors: tuple[str, ...]
    observations_sha256: str | None


@dataclass(frozen=True)
class CaptureReport:
    minimum_runs: int
    minimum_runs_met: bool
    complete: bool
    fixture_valid: bool
    documented_register_effects_match: bool | None
    review_ready: bool
    acceptance_complete: bool
    experiments: tuple[ExperimentSummary, ...]
    register_evidence: RegisterEvidence

    def to_json_object(self) -> dict[str, object]:
        return {
            "schema_version": 1,
            "claim_boundary": (
                "Fixed-baseline capture normalization and package validation only; "
                "review_ready does not change OQ-014, prove hidden storage or an "
                "alias, qualify varied-history/sentinel behavior, establish mask "
                "invariance, or establish VERIFIED_HARDWARE without engineering "
                "review of raw captures, EVM transcripts, and the physical setup."
            ),
            "minimum_runs": self.minimum_runs,
            "minimum_runs_met": self.minimum_runs_met,
            "complete": self.complete,
            "fixture_valid": self.fixture_valid,
            "documented_register_effects_match": (
                self.documented_register_effects_match
            ),
            "review_ready": self.review_ready,
            "acceptance_complete": self.acceptance_complete,
            "experiments": [
                {
                    "experiment": summary.experiment,
                    "run_count": summary.run_count,
                    "minimum_runs_met": summary.minimum_runs_met,
                    "complete": summary.complete,
                    "repeatable": summary.repeatable,
                    "fixture_valid": summary.fixture_valid,
                    "classifications": list(summary.classifications),
                    "capture_sha256": summary.capture_sha256,
                    "observations": [
                        _observation_json(observation)
                        for observation in summary.observations
                    ],
                    "evidence_package": _package_json(summary.evidence_package),
                }
                for summary in self.experiments
            ],
            "register_evidence": {
                "complete": self.register_evidence.complete,
                "errors": list(self.register_evidence.errors),
                "observations_sha256": (
                    self.register_evidence.observations_sha256
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


def _register_json(observation: RegisterObservation) -> dict[str, object]:
    result = asdict(observation)
    for field, digits in (("acc", 8), ("t", 4), ("p", 8), ("ar0", 4), ("ar1", 4)):
        result[field] = f"0x{getattr(observation, field):0{digits}x}"
    return result


def _observation_json(observation: Observation) -> dict[str, object]:
    return {
        "experiment": observation.experiment,
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
        "diagnostic_word": (
            None
            if observation.diagnostic_word is None
            else f"0x{observation.diagnostic_word:04x}"
        ),
        "boundary_fetch_count": observation.boundary_fetch_count,
        "scan_out_fetch_count": observation.scan_out_fetch_count,
        "diagnostic_out_fetch_count": observation.diagnostic_out_fetch_count,
        "terminal_seen": observation.terminal_seen,
        "capture_complete": observation.capture_complete,
        "fixture_valid": observation.fixture_valid,
        "documented_register_effects_match": (
            observation.documented_register_effects_match
        ),
        "register_observation": (
            None
            if observation.register_observation is None
            else _register_json(observation.register_observation)
        ),
        "warnings": list(observation.warnings),
        "register_differences": list(observation.register_differences),
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


def _fixture_words(experiment: str) -> tuple[int, ...]:
    words = list(BASE_WORDS)
    words[BOUNDARY_ADDRESS] = BOUNDARY_WORD[experiment]
    return tuple(words)


def _parse_hex(token: str, digits: int, name: str, row_number: int) -> int:
    if not re.fullmatch(rf"0x[0-9a-fA-F]{{1,{digits}}}", token):
        raise CaptureError(
            f"register row {row_number}: {name} must be a 0x-prefixed value"
        )
    return int(token, 16)


def _parse_flag(token: str, name: str, row_number: int) -> int:
    if token not in ("0", "1"):
        raise CaptureError(f"register row {row_number}: {name} must be 0 or 1")
    return int(token)


def read_register_observations(
    input_file: TextIO,
) -> dict[tuple[str, str], RegisterObservation]:
    reader = csv.DictReader(input_file)
    if reader.fieldnames is None:
        raise CaptureError("register observations have no CSV header")
    if tuple(reader.fieldnames) != REGISTER_COLUMNS:
        raise CaptureError(
            "register observation header must be exactly: "
            + ",".join(REGISTER_COLUMNS)
        )
    observations: dict[tuple[str, str], RegisterObservation] = {}
    for row_number, row in enumerate(reader, start=2):
        experiment = row["experiment"].strip().upper()
        run = row["run"].strip()
        if experiment not in EXPERIMENTS:
            raise CaptureError(
                f"register row {row_number}: experiment must be DMOV or LTD"
            )
        if not run:
            raise CaptureError(f"register row {row_number}: run must not be empty")
        key = (experiment, run)
        if key in observations:
            raise CaptureError(f"register row {row_number}: duplicate {key!r}")
        transcript_hash = row["transcript_sha256"].strip()
        if not SHA256_PATTERN.fullmatch(transcript_hash):
            raise CaptureError(
                f"register row {row_number}: transcript_sha256 is invalid"
            )
        observations[key] = RegisterObservation(
            experiment=experiment,
            run=run,
            acc=_parse_hex(row["acc"].strip(), 8, "acc", row_number),
            t=_parse_hex(row["t"].strip(), 4, "t", row_number),
            p=_parse_hex(row["p"].strip(), 8, "p", row_number),
            ov=_parse_flag(row["ov"].strip(), "ov", row_number),
            ovm=_parse_flag(row["ovm"].strip(), "ovm", row_number),
            dp=_parse_flag(row["dp"].strip(), "dp", row_number),
            arp=_parse_flag(row["arp"].strip(), "arp", row_number),
            ar0=_parse_hex(row["ar0"].strip(), 4, "ar0", row_number),
            ar1=_parse_hex(row["ar1"].strip(), 4, "ar1", row_number),
            transcript_sha256=transcript_hash,
        )
    if not observations:
        raise CaptureError("register observations contain no rows")
    return observations


def _program_read(sample: EdgeSample, address: int, data: int) -> bool:
    return (
        sample.rs_n == 1
        and sample.men_n == 0
        and sample.we_n == 1
        and sample.den_n == 1
        and sample.address == address
        and sample.data == data
    )


def _matches(
    samples: tuple[EdgeSample, ...],
    address: int,
    data: int,
) -> list[int]:
    return [
        index
        for index, sample in enumerate(samples)
        if _program_read(sample, address, data)
    ]


def _classify(sequence: tuple[int, ...]) -> str:
    count = len(sequence)
    if count == 0:
        return "NONCOMPLETION_AFTER_BOUNDARY_FETCH"
    if count < VALID_SCAN_LENGTH:
        return f"PARTIAL_VALID_SCAN_{count:03d}"
    if count == VALID_SCAN_LENGTH:
        return "VALID_SCAN_COMPLETE_NO_DIAGNOSTIC_OUTPUT"
    if count == COMPLETE_OUTPUT_LENGTH:
        changed = sum(
            actual != expected
            for actual, expected in zip(sequence[:VALID_SCAN_LENGTH], DEFINED_SCAN)
        )
        scan = "UNCHANGED" if changed == 0 else f"CHANGED_{changed:03d}"
        return f"COMPLETE_SCAN_{scan}_DIAGNOSTIC_{sequence[-1]:04x}"
    return f"EXTRA_OUTPUTS_{count:03d}"


def _register_differences(
    experiment: str,
    observation: RegisterObservation | None,
) -> tuple[str, ...]:
    if observation is None:
        return ()
    expected = {
        "acc": 0x00000007 if experiment == "DMOV" else 0x00000016,
        "t": 0x0003 if experiment == "DMOV" else 0x005A,
        "p": 0x0000000F,
        "dp": 1,
        "arp": 0,
        "ar0": 0x01FF,
    }
    differences = []
    for field, value in expected.items():
        actual = getattr(observation, field)
        if actual != value:
            differences.append(
                f"{field} observed 0x{actual:x}, documented-path value 0x{value:x}"
            )
    return tuple(differences)


def analyze_experiment(
    experiment: str,
    runs: Mapping[str, tuple[EdgeSample, ...]],
    registers: Mapping[tuple[str, str], RegisterObservation],
) -> tuple[Observation, ...]:
    observations: list[Observation] = []
    for run, samples in runs.items():
        boundary = _matches(
            samples,
            BOUNDARY_ADDRESS,
            BOUNDARY_WORD[experiment],
        )
        if not boundary:
            raise CaptureError(
                f"{experiment} run {run!r}: exact boundary instruction fetch is absent"
            )
        scan_anchors = _matches(samples, *SCAN_OUT)
        diagnostic_anchors = _matches(samples, *DIAGNOSTIC_OUT)
        terminal = _matches(samples, *TERMINAL_BRANCH)
        output_indexes = [
            index for index, sample in enumerate(samples) if sample.we_n == 0
        ]
        outputs = tuple(samples[index] for index in output_indexes)
        sequence = tuple(sample.data for sample in outputs)
        warnings: list[str] = []
        if len(boundary) != 1:
            warnings.append("boundary instruction fetch is repeated")
        if output_indexes and output_indexes[0] <= boundary[0]:
            warnings.append("an output precedes the boundary instruction fetch")
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

        paired_scan_count = min(len(sequence), VALID_SCAN_LENGTH)
        allowed_scan_counts = {paired_scan_count}
        if paired_scan_count < VALID_SCAN_LENGTH:
            allowed_scan_counts.add(paired_scan_count + 1)
        if len(scan_anchors) not in allowed_scan_counts:
            warnings.append(
                f"found {len(scan_anchors)} scan OUT fetches for "
                f"{paired_scan_count} observed scan writes"
            )
        for index in range(min(len(scan_anchors), paired_scan_count)):
            if not boundary[0] < scan_anchors[index] < output_indexes[index]:
                warnings.append(f"scan OUT {index} fetch/write ordering is invalid")
            if index + 1 < min(len(scan_anchors), paired_scan_count):
                if output_indexes[index] >= scan_anchors[index + 1]:
                    warnings.append(
                        f"scan OUT {index} overlaps the next checked fetch"
                    )
        if len(scan_anchors) == paired_scan_count + 1:
            preceding_event = (
                output_indexes[paired_scan_count - 1]
                if paired_scan_count
                else boundary[0]
            )
            if scan_anchors[-1] <= preceding_event:
                warnings.append("pending scan OUT fetch is out of order")

        if len(sequence) >= COMPLETE_OUTPUT_LENGTH:
            if len(diagnostic_anchors) != 1:
                warnings.append("complete flow lacks one exact diagnostic OUT fetch")
            elif not (
                output_indexes[VALID_SCAN_LENGTH - 1]
                < diagnostic_anchors[0]
                < output_indexes[VALID_SCAN_LENGTH]
            ):
                warnings.append("diagnostic OUT fetch/write ordering is invalid")
        elif len(diagnostic_anchors) > 1:
            warnings.append("partial flow repeats the diagnostic OUT fetch")
        elif diagnostic_anchors and len(sequence) < VALID_SCAN_LENGTH:
            warnings.append("diagnostic OUT fetch appears before a complete valid scan")

        if len(sequence) > COMPLETE_OUTPUT_LENGTH:
            warnings.append("capture contains output cycles beyond the fixture")
        capture_complete = len(sequence) == COMPLETE_OUTPUT_LENGTH
        if capture_complete:
            if not terminal or terminal[0] <= output_indexes[-1]:
                warnings.append("complete flow does not reach the terminal branch")
        elif terminal:
            warnings.append("terminal branch appears before the complete output stream")

        last_event = max(boundary + scan_anchors + diagnostic_anchors + output_indexes)
        if last_event + 4 >= len(samples):
            raise CaptureError(
                f"{experiment} run {run!r}: fewer than four falling boundaries "
                "follow the final boundary/fetch/output event"
            )

        valid_scan = sequence[:VALID_SCAN_LENGTH]
        changed_addresses = tuple(
            0x8F - index
            for index, (actual, expected) in enumerate(
                zip(valid_scan, DEFINED_SCAN)
            )
            if actual != expected
        )
        register_observation = registers.get((experiment, run))
        register_differences = _register_differences(
            experiment,
            register_observation,
        )
        observations.append(
            Observation(
                experiment=experiment,
                run=run,
                classification=_classify(sequence),
                output_sequence=sequence,
                output_samples=outputs,
                valid_scan_sha256=(
                    _hash_words(valid_scan)
                    if len(valid_scan) == VALID_SCAN_LENGTH
                    else None
                ),
                changed_valid_addresses=changed_addresses,
                diagnostic_word=(
                    sequence[VALID_SCAN_LENGTH]
                    if len(sequence) > VALID_SCAN_LENGTH
                    else None
                ),
                boundary_fetch_count=len(boundary),
                scan_out_fetch_count=len(scan_anchors),
                diagnostic_out_fetch_count=len(diagnostic_anchors),
                terminal_seen=bool(terminal),
                capture_complete=capture_complete,
                fixture_valid=not warnings,
                documented_register_effects_match=(
                    None
                    if register_observation is None
                    else not register_differences
                ),
                register_observation=register_observation,
                warnings=tuple(warnings),
                register_differences=register_differences,
            )
        )
    return tuple(observations)


def _validate_exact_image(
    experiment: str,
    program_image: Path | None,
    package: EvidencePackage,
) -> EvidencePackage:
    errors = list(package.errors)
    if program_image is not None and program_image.is_file():
        try:
            image = program_image.read_bytes()
        except OSError as error:
            errors.append(f"cannot read checked {experiment} image: {error}")
        else:
            expected = b"".join(
                word.to_bytes(2, byteorder="big")
                for word in _fixture_words(experiment)
            )
            if image != expected:
                errors.append(
                    f"program image is not the exact big-endian {experiment} fixture"
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


def _validate_register_evidence(
    state_path: Path | None,
    registers: Mapping[tuple[str, str], RegisterObservation],
    run_keys: set[tuple[str, str]],
    metadata_paths: Mapping[str, Path | None],
) -> RegisterEvidence:
    if state_path is None:
        return RegisterEvidence(False, ("register observations were not supplied",), None)
    state_hash = _hash_file(state_path)
    errors: list[str] = []
    actual_keys = set(registers)
    missing = sorted(run_keys - actual_keys)
    extra = sorted(actual_keys - run_keys)
    if missing:
        errors.append(f"register observations lack capture runs: {missing!r}")
    if extra:
        errors.append(f"register observations contain extra runs: {extra!r}")
    for experiment in EXPERIMENTS:
        metadata = _metadata_object(metadata_paths[experiment])
        if metadata.get("register_observations_sha256") != state_hash:
            errors.append(
                f"{experiment} metadata does not pin the register-observation CSV"
            )
        raw_artifacts = metadata.get("raw_artifacts")
        raw_hashes = {
            value
            for value in raw_artifacts.values()
            if isinstance(value, str)
        } if isinstance(raw_artifacts, dict) else set()
        for key, observation in registers.items():
            if key[0] == experiment and observation.transcript_sha256 not in raw_hashes:
                errors.append(
                    f"{experiment} run {key[1]!r} transcript hash is not in "
                    "validated raw_artifacts"
                )
    return RegisterEvidence(
        complete=not errors,
        errors=tuple(errors),
        observations_sha256=state_hash,
    )


def _read_capture(path: Path) -> dict[str, tuple[EdgeSample, ...]]:
    try:
        with path.open("r", encoding="utf-8", newline="") as input_file:
            return read_normalized_capture(input_file)
    except (OSError, UnicodeError) as error:
        raise CaptureError(f"cannot read capture {path}: {error}") from error


def build_report(
    dmov_capture: Path,
    ltd_capture: Path,
    *,
    minimum_runs: int = 32,
    dmov_metadata: Path | None = None,
    ltd_metadata: Path | None = None,
    dmov_image: Path | None = None,
    ltd_image: Path | None = None,
    register_observations: Path | None = None,
    artifact_root: Path | None = None,
) -> CaptureReport:
    if minimum_runs <= 0:
        raise CaptureError("minimum_runs must be positive")
    capture_paths = {"DMOV": dmov_capture, "LTD": ltd_capture}
    metadata_paths = {"DMOV": dmov_metadata, "LTD": ltd_metadata}
    image_paths = {"DMOV": dmov_image, "LTD": ltd_image}
    runs = {
        experiment: _read_capture(path)
        for experiment, path in capture_paths.items()
    }
    registers: dict[tuple[str, str], RegisterObservation] = {}
    if register_observations is not None:
        try:
            with register_observations.open(
                "r", encoding="utf-8", newline=""
            ) as input_file:
                registers = read_register_observations(input_file)
        except (OSError, UnicodeError) as error:
            raise CaptureError(f"cannot read register observations: {error}") from error

    summaries: list[ExperimentSummary] = []
    run_keys: set[tuple[str, str]] = set()
    for experiment in EXPERIMENTS:
        experiment_runs = runs[experiment]
        run_keys.update((experiment, run) for run in experiment_runs)
        observations = analyze_experiment(experiment, experiment_runs, registers)
        base_package = validate_evidence_package(
            metadata_paths[experiment],
            image_paths[experiment],
            artifact_root,
        )
        package = _validate_exact_image(
            experiment,
            image_paths[experiment],
            base_package,
        )
        summaries.append(
            ExperimentSummary(
                experiment=experiment,
                run_count=len(experiment_runs),
                minimum_runs_met=len(experiment_runs) >= minimum_runs,
                complete=all(item.capture_complete for item in observations),
                repeatable=len({item.output_sequence for item in observations}) == 1,
                fixture_valid=all(item.fixture_valid for item in observations),
                classifications=tuple(
                    item.classification for item in observations
                ),
                observations=observations,
                capture_sha256=_hash_file(capture_paths[experiment]),
                evidence_package=package,
            )
        )
    register_evidence = _validate_register_evidence(
        register_observations,
        registers,
        run_keys,
        metadata_paths,
    )
    minimum_runs_met = all(summary.minimum_runs_met for summary in summaries)
    complete = all(summary.complete for summary in summaries)
    fixture_valid = all(summary.fixture_valid for summary in summaries)
    register_results = [
        observation.documented_register_effects_match
        for summary in summaries
        for observation in summary.observations
    ]
    documented_match = (
        all(value is True for value in register_results)
        if register_results and all(value is not None for value in register_results)
        else None
    )
    review_ready = (
        minimum_runs_met
        and complete
        and fixture_valid
        and register_evidence.complete
        and all(summary.evidence_package.complete for summary in summaries)
    )
    return CaptureReport(
        minimum_runs=minimum_runs,
        minimum_runs_met=minimum_runs_met,
        complete=complete,
        fixture_valid=fixture_valid,
        documented_register_effects_match=documented_match,
        review_ready=review_ready,
        acceptance_complete=False,
        experiments=tuple(summaries),
        register_evidence=register_evidence,
    )


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dmov_capture", type=Path)
    parser.add_argument("ltd_capture", type=Path)
    parser.add_argument("--dmov-metadata", type=Path)
    parser.add_argument("--ltd-metadata", type=Path)
    parser.add_argument("--dmov-image", type=Path)
    parser.add_argument("--ltd-image", type=Path)
    parser.add_argument("--register-observations", type=Path)
    parser.add_argument("--artifact-root", type=Path)
    parser.add_argument("--minimum-runs", type=int, default=32)
    parser.add_argument("--require-review-ready", action="store_true")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_argument_parser().parse_args(argv)
    try:
        report = build_report(
            args.dmov_capture,
            args.ltd_capture,
            minimum_runs=args.minimum_runs,
            dmov_metadata=args.dmov_metadata,
            ltd_metadata=args.ltd_metadata,
            dmov_image=args.dmov_image,
            ltd_image=args.ltd_image,
            register_observations=args.register_observations,
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
