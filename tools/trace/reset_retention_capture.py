#!/usr/bin/env python3
"""Normalize paired original-TMS32010 physical-reset retention captures.

The tool validates fixture execution, BIO-selected reset routing, measured
reset duration, and evidence provenance.  It preserves post-reset values and
describes their relationship to the checked pre-reset state without importing
the model's PROVISIONAL retention policy as an expected hardware result.
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
from hashlib import sha256
import json
from pathlib import Path
import re
import sys
from typing import Mapping, Sequence, TextIO

from tools.trace.push_pop_capture import (
    CaptureError,
    EvidencePackage,
    validate_evidence_package,
)
from tools.trace.specimen_evidence import (
    SpecimenEvidence,
    validate_specimen_evidence,
)


FIXTURES = ("SET", "CLEAR")
CAPTURE_COLUMNS = (
    "run",
    "sample",
    "time_ns",
    "rs_n",
    "bio_n",
    "men_n",
    "we_n",
    "den_n",
    "address",
    "data",
)
RESET_COLUMNS = (
    "run",
    "rs_assert_ns",
    "rs_release_ns",
    "bio_assert_ns",
)
SHA256_PATTERN = re.compile(r"[0-9a-f]{64}")
PROGRAM_IMAGES = {
    "SET": {
        "size": 594,
        "sha256": "26926dd7469ec723c0abde9e541ef24d2af10e92c2cffb84a873a845a5b7065c",
    },
    "CLEAR": {
        "size": 594,
        "sha256": "f8313381163fe3238b786b755372ca8404a72dba64a04e6f7b4e87458eb6ee25",
    },
}
FIXTURE_SOURCE_SHA256 = {
    "SET": (
        "3c2e6e6ca2c3dc2cccafdda02d77f11b984deb28af162d16b1cbe4c06bf0c9c8"
    ),
    "CLEAR": (
        "38dabb539d46752d733a819dfb4c316e460a56c69e617506a587e444657517f5"
    ),
}
PRE_VECTORS = {
    "SET": (
        0x00A5, 0x0000, 0x0012, 0x0034, 0xFFFF, 0x00FF, 0x0000,
        0x0055, 0x0000, 0x0044, 0x0033, 0x0022, 0x0011,
    ),
    "CLEAR": (
        0x003C, 0x0000, 0x0056, 0x0078, 0x3EFE, 0x00AA, 0x0000,
        0x0022, 0x0000, 0x0088, 0x0077, 0x0066, 0x0055,
    ),
}
ARMED_MARKERS = {"SET": 0x00A1, "CLEAR": 0x00A2}
PRE_OUT_ANCHORS = {
    "SET": (
        (0x03B, 0x4F00), (0x03C, 0x4F01), (0x03D, 0x4F02),
        (0x03E, 0x4F03), (0x040, 0x4F00), (0x045, 0x4F04),
        (0x046, 0x4F05), (0x04B, 0x4F06), (0x04C, 0x4F07),
        (0x04F, 0x4F08), (0x052, 0x4F08), (0x055, 0x4F08),
        (0x058, 0x4F08),
    ),
    "CLEAR": (
        (0x030, 0x4F00), (0x031, 0x4F01), (0x032, 0x4F02),
        (0x033, 0x4F03), (0x035, 0x4F00), (0x03A, 0x4F04),
        (0x03B, 0x4F05), (0x040, 0x4F06), (0x041, 0x4F07),
        (0x044, 0x4F08), (0x047, 0x4F08), (0x04A, 0x4F08),
        (0x04D, 0x4F08),
    ),
}
ARMED_OUT_ANCHORS = {"SET": (0x065, 0x4F09), "CLEAR": (0x05A, 0x4F09)}
ARMED_BRANCHES = {"SET": (0x066, 0xF900), "CLEAR": (0x05B, 0xF900)}
POST_OUT_ANCHORS = (
    (0x106, 0x4F00), (0x107, 0x4F01), (0x108, 0x4F02),
    (0x109, 0x4F03), (0x10B, 0x4F00), (0x110, 0x4F04),
    (0x111, 0x4F05), (0x116, 0x4F06), (0x117, 0x4F07),
    (0x11A, 0x4F08), (0x11D, 0x4F08), (0x120, 0x4F08),
    (0x123, 0x4F08),
)
TERMINAL_OUT_ANCHOR = (0x126, 0x4F0C)
BIOZ_ANCHOR = (0x000, 0xF600)
POST_TARGET_ANCHOR = (0x100, 0x7C00)
TERMINAL_BRANCH = (0x127, 0xF900)
COMPLETE_OUTPUT_COUNT = 28
ALLOWED_CLOCK_CONDITIONS = frozenset(("slow_limit", "nominal", "fast_limit"))
REQUIRED_RESET_TARGETS = frozenset((5, 8, 32))


@dataclass(frozen=True)
class EdgeSample:
    run: str
    sample: int
    time_ns: Decimal
    rs_n: int
    bio_n: int
    men_n: int
    we_n: int
    den_n: int
    address: int
    data: int


@dataclass(frozen=True)
class ResetMeasurement:
    run: str
    rs_assert_ns: Decimal
    rs_release_ns: Decimal
    bio_assert_ns: Decimal


@dataclass(frozen=True)
class RunCondition:
    clock_condition: str
    reset_hold_target_cycles: int


@dataclass(frozen=True)
class FieldObservation:
    name: str
    width: int
    evidence_scope: str
    pre_value: int
    post_value: int
    relationship: str


@dataclass(frozen=True)
class Observation:
    fixture: str
    run: str
    classification: str
    clock_condition: str
    reset_hold_target_cycles: int
    reset_low_complete_cycles: int
    reset_width_ns: Decimal
    minimum_clkout_period_ns: Decimal
    maximum_clkout_period_ns: Decimal
    output_sequence: tuple[int, ...]
    pre_vector: tuple[int, ...]
    post_vector: tuple[int, ...]
    pre_status_reserved_bit_1: int | None
    post_status_reserved_bit_1: int | None
    fields: tuple[FieldObservation, ...]
    capture_complete: bool
    fixture_valid: bool
    warnings: tuple[str, ...]


@dataclass(frozen=True)
class FixtureSummary:
    fixture: str
    run_count: int
    nominal_run_count: int
    minimum_nominal_runs_met: bool
    condition_coverage_complete: bool
    complete: bool
    repeatable: bool
    fixture_valid: bool
    capture_sha256: str
    reset_measurements_sha256: str
    classifications: tuple[str, ...]
    observations: tuple[Observation, ...]
    evidence_package: EvidencePackage


@dataclass(frozen=True)
class FieldSummary:
    name: str
    width: int
    set_relationships: tuple[str, ...]
    clear_relationships: tuple[str, ...]
    set_post_values: tuple[int, ...]
    clear_post_values: tuple[int, ...]
    pair_classification: str


@dataclass(frozen=True)
class CaptureReport:
    minimum_nominal_runs: int
    minimum_nominal_runs_met: bool
    condition_coverage_complete: bool
    complete: bool
    fixture_valid: bool
    review_ready: bool
    observed_full_retention_candidate: bool
    acceptance_complete: bool
    specimen_id: str | None
    specimen_scope: str
    specimen_pair_errors: tuple[str, ...]
    fixtures: tuple[FixtureSummary, ...]
    field_summaries: tuple[FieldSummary, ...]

    def to_json_object(self) -> dict[str, object]:
        return {
            "schema_version": 1,
            "claim_boundary": (
                "Original-NMOS reset-capture normalization and package validation "
                "only. review_ready does not require post-reset retention, change "
                "OQ-012 or the PROVISIONAL model/RTL policy, prove which physical "
                "latches RS affects, establish mask-revision invariance, or establish "
                "VERIFIED_HARDWARE without raw engineering review and a second "
                "identified original specimen. It does not generalize beyond the "
                "paired, identified specimen."
            ),
            "minimum_nominal_runs": self.minimum_nominal_runs,
            "minimum_nominal_runs_met": self.minimum_nominal_runs_met,
            "condition_coverage_complete": self.condition_coverage_complete,
            "complete": self.complete,
            "fixture_valid": self.fixture_valid,
            "review_ready": self.review_ready,
            "observed_full_retention_candidate": (
                self.observed_full_retention_candidate
            ),
            "acceptance_complete": self.acceptance_complete,
            "specimen_id": self.specimen_id,
            "specimen_scope": self.specimen_scope,
            "specimen_pair_errors": list(self.specimen_pair_errors),
            "fixtures": [_fixture_json(item) for item in self.fixtures],
            "field_summaries": [_field_summary_json(item) for item in self.field_summaries],
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
        raise CaptureError(f"row {row_number}: {name} must be a finite decimal") from error
    if not value.is_finite() or value < 0:
        raise CaptureError(f"row {row_number}: {name} must be finite and nonnegative")
    return value


def read_capture(input_file: TextIO) -> dict[str, tuple[EdgeSample, ...]]:
    reader = csv.DictReader(input_file)
    if reader.fieldnames is None or tuple(reader.fieldnames) != CAPTURE_COLUMNS:
        raise CaptureError("capture header must be exactly: " + ",".join(CAPTURE_COLUMNS))
    runs: dict[str, list[EdgeSample]] = {}
    last_sample: dict[str, int] = {}
    last_time: dict[str, Decimal] = {}
    for row_number, row in enumerate(reader, start=2):
        run = row["run"].strip()
        if not run:
            raise CaptureError(f"row {row_number}: run must not be empty")
        sample = _parse_uint(row["sample"].strip(), "sample", row_number)
        time_ns = _parse_decimal(row["time_ns"].strip(), "time_ns", row_number)
        if run in last_sample and sample != last_sample[run] + 1:
            raise CaptureError(
                f"row {row_number}: sample must increase by one within run {run!r}"
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
                bio_n=_parse_bit(row["bio_n"].strip(), "bio_n", row_number),
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


def read_reset_measurements(
    input_file: TextIO,
) -> dict[str, ResetMeasurement]:
    reader = csv.DictReader(input_file)
    if reader.fieldnames is None or tuple(reader.fieldnames) != RESET_COLUMNS:
        raise CaptureError(
            "reset-measurement header must be exactly: " + ",".join(RESET_COLUMNS)
        )
    measurements: dict[str, ResetMeasurement] = {}
    for row_number, row in enumerate(reader, start=2):
        run = row["run"].strip()
        if not run:
            raise CaptureError(f"row {row_number}: run must not be empty")
        if run in measurements:
            raise CaptureError(f"row {row_number}: duplicate reset run {run!r}")
        item = ResetMeasurement(
            run=run,
            rs_assert_ns=_parse_decimal(
                row["rs_assert_ns"].strip(), "rs_assert_ns", row_number
            ),
            rs_release_ns=_parse_decimal(
                row["rs_release_ns"].strip(), "rs_release_ns", row_number
            ),
            bio_assert_ns=_parse_decimal(
                row["bio_assert_ns"].strip(), "bio_assert_ns", row_number
            ),
        )
        if item.rs_release_ns <= item.rs_assert_ns:
            raise CaptureError(
                f"row {row_number}: rs_release_ns must follow rs_assert_ns"
            )
        measurements[run] = item
    if not measurements:
        raise CaptureError("reset measurements contain no runs")
    return measurements


def _hash_file(path: Path) -> str:
    digest = sha256()
    with path.open("rb") as input_file:
        for chunk in iter(lambda: input_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _program_read(sample: EdgeSample, anchor: tuple[int, int]) -> bool:
    return (
        sample.rs_n == 1
        and sample.men_n == 0
        and sample.we_n == 1
        and sample.den_n == 1
        and sample.address == anchor[0]
        and sample.data == anchor[1]
    )


def _matches(samples: tuple[EdgeSample, ...], anchor: tuple[int, int]) -> list[int]:
    return [index for index, sample in enumerate(samples) if _program_read(sample, anchor)]


def _relationship(pre_value: int, post_value: int, width: int) -> str:
    if post_value == pre_value:
        return "RETAINED"
    if post_value == 0:
        return "FORCED_ZERO"
    if width == 1 and post_value == 1:
        return "FORCED_ONE"
    digits = (width + 3) // 4
    return f"OTHER_0x{post_value:0{digits}x}"


def _fields(pre: tuple[int, ...], post: tuple[int, ...]) -> tuple[FieldObservation, ...]:
    values = (
        ("ACC", 32, (pre[1] << 16) | pre[0], (post[1] << 16) | post[0]),
        ("AR0", 16, pre[2], post[2]),
        ("AR1", 16, pre[3], post[3]),
        ("OV", 1, (pre[4] >> 15) & 1, (post[4] >> 15) & 1),
        ("OVM", 1, (pre[4] >> 14) & 1, (post[4] >> 14) & 1),
        ("ARP", 1, (pre[4] >> 8) & 1, (post[4] >> 8) & 1),
        ("DP", 1, pre[4] & 1, post[4] & 1),
        ("P", 32, (pre[6] << 16) | pre[5], (post[6] << 16) | post[5]),
        ("T", 32, (pre[8] << 16) | pre[7], (post[8] << 16) | post[7]),
        ("STACK_TOP", 12, pre[9], post[9]),
        ("STACK_LEVEL_1", 12, pre[10], post[10]),
        ("STACK_LEVEL_2", 12, pre[11], post[11]),
        ("STACK_BOTTOM", 12, pre[12], post[12]),
    )
    return tuple(
        FieldObservation(
            name=name,
            width=width,
            evidence_scope=(
                "DOCUMENTED_UNCHANGED_CONTROL"
                if name == "OVM"
                else "UNLISTED_RESET_STATE"
            ),
            pre_value=pre_value,
            post_value=post_value,
            relationship=_relationship(pre_value, post_value, width),
        )
        for name, width, pre_value, post_value in values
    )


def _classify_output_count(count: int, fields: tuple[FieldObservation, ...]) -> str:
    if count < COMPLETE_OUTPUT_COUNT:
        return f"PARTIAL_OUTPUT_STREAM_{count:03d}"
    if count > COMPLETE_OUTPUT_COUNT:
        return f"EXTRA_OUTPUT_STREAM_{count:03d}"
    retained = sum(item.relationship == "RETAINED" for item in fields)
    return f"COMPLETE_FIELDS_RETAINED_{retained:02d}_CHANGED_{len(fields) - retained:02d}"


def analyze_fixture(
    fixture: str,
    runs: Mapping[str, tuple[EdgeSample, ...]],
    measurements: Mapping[str, ResetMeasurement],
    conditions: Mapping[str, RunCondition],
) -> tuple[Observation, ...]:
    if fixture not in FIXTURES:
        raise CaptureError(f"unknown fixture {fixture!r}")
    if set(runs) != set(measurements) or set(runs) != set(conditions):
        raise CaptureError(
            f"{fixture} capture, reset-measurement, and run-condition names must match"
        )
    observations: list[Observation] = []
    for run, samples in runs.items():
        measurement = measurements[run]
        condition = conditions[run]
        output_indexes = [index for index, sample in enumerate(samples) if sample.we_n == 0]
        outputs = tuple(samples[index] for index in output_indexes)
        sequence = tuple(sample.data for sample in outputs)
        capture_complete = len(sequence) == COMPLETE_OUTPUT_COUNT
        warnings: list[str] = []
        for ordinal, sample in enumerate(outputs, start=1):
            if (
                sample.rs_n != 1
                or sample.bio_n not in (0, 1)
                or sample.men_n != 1
                or sample.we_n != 0
                or sample.den_n != 1
                or sample.address != 7
            ):
                warnings.append(
                    f"output {ordinal} is not an exclusive active-low port-7 WE cycle"
                )

        pre_vector: tuple[int, ...] = ()
        post_vector: tuple[int, ...] = ()
        fields: tuple[FieldObservation, ...] = ()
        if capture_complete:
            anchors = (
                PRE_OUT_ANCHORS[fixture]
                + (ARMED_OUT_ANCHORS[fixture],)
                + POST_OUT_ANCHORS
                + (TERMINAL_OUT_ANCHOR,)
            )
            anchor_indexes: list[int] = []
            for anchor in anchors:
                matches = _matches(samples, anchor)
                if len(matches) != 1:
                    warnings.append(
                        f"OUT fetch 0x{anchor[0]:03x}/0x{anchor[1]:04x} appears "
                        f"{len(matches)} times, expected 1"
                    )
                else:
                    anchor_indexes.append(matches[0])
            if len(anchor_indexes) == COMPLETE_OUTPUT_COUNT:
                for ordinal, (anchor_index, output_index) in enumerate(
                    zip(anchor_indexes, output_indexes), start=1
                ):
                    if anchor_index >= output_index:
                        warnings.append(f"output {ordinal} does not follow its checked OUT fetch")
                    if ordinal < COMPLETE_OUTPUT_COUNT and output_index >= anchor_indexes[ordinal]:
                        warnings.append(f"output {ordinal} overlaps the next checked OUT fetch")
            pre_vector = sequence[:13]
            marker = sequence[13]
            post_vector = sequence[14:27]
            terminal_marker = sequence[27]
            expected_pre = PRE_VECTORS[fixture]
            for index, (observed, expected) in enumerate(zip(pre_vector, expected_pre)):
                if index == 4:
                    if (observed & 0xFFFD) != (expected & 0xFFFD):
                        warnings.append("pre-reset status differs outside reserved bit 1")
                elif observed != expected:
                    warnings.append(f"pre-reset vector position {index} is not fixture value")
            if marker != ARMED_MARKERS[fixture]:
                warnings.append(f"armed marker is not 0x{ARMED_MARKERS[fixture]:04x}")
            if terminal_marker != 0x00AF:
                warnings.append("terminal marker is not 0x00af")
            if (post_vector[4] & 0x3EFC) != 0x3EFC:
                warnings.append("post-reset SST fixed-one fields or INTM are invalid")
            if any(value > 0x0FFF for value in post_vector[9:13]):
                warnings.append("post-reset stack carrier exceeds the 12-bit stack width")
            fields = _fields(pre_vector, post_vector)
            ovm = next(item for item in fields if item.name == "OVM")
            if ovm.relationship != "RETAINED":
                warnings.append("documented unchanged OVM control did not retain")
        elif len(sequence) > COMPLETE_OUTPUT_COUNT:
            warnings.append("capture contains output cycles beyond the fixture")

        bioz_indexes = _matches(samples, BIOZ_ANCHOR)
        if len(bioz_indexes) != 2:
            warnings.append(f"BIOZ fetch appears {len(bioz_indexes)} times, expected 2")
            pre_bioz_index = None
            post_bioz_index = None
        else:
            pre_bioz_index, post_bioz_index = bioz_indexes
            if samples[pre_bioz_index].bio_n != 1:
                warnings.append("initial BIOZ fetch did not sample BIO inactive-high")
            if samples[post_bioz_index].bio_n != 0:
                warnings.append("post-reset BIOZ fetch did not sample BIO active-low")
        post_targets = _matches(samples, POST_TARGET_ANCHOR)
        if len(post_targets) != 1:
            warnings.append(
                f"post-reset target fetch appears {len(post_targets)} times, expected 1"
            )
        elif post_bioz_index is not None and post_targets[0] <= post_bioz_index:
            warnings.append("post-reset target does not follow the BIOZ decision")

        low_indexes = [index for index, sample in enumerate(samples) if sample.rs_n == 0]
        reset_cycles = 0
        periods: list[Decimal] = []
        if not low_indexes:
            warnings.append("capture contains no sampled active reset interval")
        else:
            if low_indexes != list(range(low_indexes[0], low_indexes[-1] + 1)):
                warnings.append("sampled reset contains more than one active interval")
            for previous, current in zip(low_indexes, low_indexes[1:]):
                if current == previous + 1:
                    reset_cycles += 1
                    periods.append(samples[current].time_ns - samples[previous].time_ns)
            for index in low_indexes[1:]:
                sample = samples[index]
                if sample.men_n != 1 or sample.we_n != 1 or sample.den_n != 1:
                    warnings.append("external controls are active after a complete reset interval")
                    break
                if sample.address != 0:
                    warnings.append("address bus is nonzero after a complete reset interval")
                    break
        if reset_cycles != condition.reset_hold_target_cycles:
            warnings.append(
                f"observed {reset_cycles} complete reset cycles, expected declared "
                f"target {condition.reset_hold_target_cycles}"
            )
        if reset_cycles < 5:
            warnings.append("reset is shorter than five complete CLKOUT cycles")

        for sample in samples:
            expected_rs_n = int(
                not (measurement.rs_assert_ns <= sample.time_ns < measurement.rs_release_ns)
            )
            if sample.rs_n != expected_rs_n:
                warnings.append(
                    f"sample {sample.sample} RS level disagrees with measured transitions"
                )
                break
        for sample in samples:
            expected_bio_n = int(sample.time_ns < measurement.bio_assert_ns)
            if sample.bio_n != expected_bio_n:
                warnings.append(
                    f"sample {sample.sample} BIO level disagrees with measured assertion"
                )
                break

        armed_output_index = output_indexes[13] if len(output_indexes) > 13 else None
        if armed_output_index is not None:
            armed_time = samples[armed_output_index].time_ns
            if not (armed_time < measurement.bio_assert_ns <= measurement.rs_assert_ns):
                warnings.append("BIO/RS assertion order does not follow the armed marker")
            branches = _matches(samples, ARMED_BRANCHES[fixture])
            if not any(
                armed_output_index < index < (low_indexes[0] if low_indexes else len(samples))
                for index in branches
            ):
                warnings.append("armed hold branch is absent before reset")
        if post_bioz_index is not None and measurement.rs_release_ns >= samples[post_bioz_index].time_ns:
            warnings.append("RS release does not precede the post-reset BIOZ fetch")
        if pre_bioz_index is not None and output_indexes and pre_bioz_index >= output_indexes[0]:
            warnings.append("initial BIOZ decision does not precede the pre-reset vector")

        terminal_branches = _matches(samples, TERMINAL_BRANCH)
        terminal_after = [
            index
            for index in terminal_branches
            if output_indexes and index > output_indexes[-1]
        ]
        if not terminal_after:
            warnings.append("terminal hold branch is absent after the final output")
        elif terminal_after[0] + 4 >= len(samples):
            raise CaptureError(
                f"{fixture} run {run!r}: fewer than four falling boundaries follow "
                "the terminal hold fetch"
            )

        if periods:
            minimum_period = min(periods)
            maximum_period = max(periods)
        else:
            minimum_period = Decimal(0)
            maximum_period = Decimal(0)
        observations.append(
            Observation(
                fixture=fixture,
                run=run,
                classification=_classify_output_count(len(sequence), fields),
                clock_condition=condition.clock_condition,
                reset_hold_target_cycles=condition.reset_hold_target_cycles,
                reset_low_complete_cycles=reset_cycles,
                reset_width_ns=measurement.rs_release_ns - measurement.rs_assert_ns,
                minimum_clkout_period_ns=minimum_period,
                maximum_clkout_period_ns=maximum_period,
                output_sequence=sequence,
                pre_vector=pre_vector,
                post_vector=post_vector,
                pre_status_reserved_bit_1=(
                    (pre_vector[4] >> 1) & 1 if len(pre_vector) == 13 else None
                ),
                post_status_reserved_bit_1=(
                    (post_vector[4] >> 1) & 1 if len(post_vector) == 13 else None
                ),
                fields=fields,
                capture_complete=capture_complete,
                fixture_valid=not warnings,
                warnings=tuple(warnings),
            )
        )
    return tuple(observations)


def _load_metadata(path: Path | None) -> dict[str, object]:
    if path is None:
        return {}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return {}
    return value if isinstance(value, dict) else {}


def validate_reset_evidence(
    fixture: str,
    metadata_path: Path | None,
    program_image: Path | None,
    reset_measurements_path: Path,
    artifact_root: Path | None,
    run_names: set[str],
) -> tuple[EvidencePackage, dict[str, RunCondition]]:
    base = validate_evidence_package(metadata_path, program_image, artifact_root)
    errors = list(base.errors)
    metadata = _load_metadata(metadata_path)
    expected_image = PROGRAM_IMAGES[fixture]
    if program_image is not None and program_image.is_file():
        try:
            actual_size = program_image.stat().st_size
            actual_hash = _hash_file(program_image)
        except OSError as error:
            errors.append(f"cannot read checked {fixture} image: {error}")
        else:
            if actual_size != expected_image["size"] or actual_hash != expected_image["sha256"]:
                errors.append(f"program image is not the exact sparse big-endian {fixture} fixture")
    for field in ("reset_driver_circuit", "bio_driver_circuit"):
        value = metadata.get(field)
        if not isinstance(value, str) or not value.strip():
            errors.append(f"metadata {field} must be a nonempty string")
    signal_map = metadata.get("signal_pin_map")
    if (
        not isinstance(signal_map, dict)
        or not isinstance(signal_map.get("BIO_N"), str)
        or not signal_map.get("BIO_N", "").strip()
    ):
        errors.append("metadata signal_pin_map lacks BIO_N")
    expected_measurement_hash = metadata.get("reset_measurements_sha256")
    if not isinstance(expected_measurement_hash, str) or not SHA256_PATTERN.fullmatch(
        expected_measurement_hash
    ):
        errors.append("metadata reset_measurements_sha256 must be a lowercase SHA-256")
    elif _hash_file(reset_measurements_path) != expected_measurement_hash:
        errors.append("reset measurements SHA-256 mismatch")

    conditions: dict[str, RunCondition] = {}
    condition_object = metadata.get("run_conditions")
    if not isinstance(condition_object, dict):
        errors.append("metadata run_conditions must be an object")
    else:
        if set(condition_object) != run_names:
            errors.append("metadata run_conditions names do not match capture runs")
        for run, value in condition_object.items():
            if not isinstance(run, str) or not isinstance(value, dict):
                errors.append("metadata run_conditions entries must be named objects")
                continue
            clock_condition = value.get("clock_condition")
            reset_target = value.get("reset_hold_target_cycles")
            if clock_condition not in ALLOWED_CLOCK_CONDITIONS:
                errors.append(f"run_conditions[{run!r}] has invalid clock_condition")
                continue
            if isinstance(reset_target, bool) or reset_target not in REQUIRED_RESET_TARGETS:
                errors.append(f"run_conditions[{run!r}] has invalid reset hold target")
                continue
            conditions[run] = RunCondition(clock_condition, reset_target)
    return (
        EvidencePackage(
            complete=not errors,
            errors=tuple(errors),
            program_image_sha256=base.program_image_sha256,
            verified_artifacts=base.verified_artifacts,
        ),
        conditions,
    )


def _read_capture(path: Path) -> dict[str, tuple[EdgeSample, ...]]:
    try:
        with path.open("r", encoding="utf-8", newline="") as input_file:
            return read_capture(input_file)
    except (OSError, UnicodeError) as error:
        raise CaptureError(f"cannot read capture {path}: {error}") from error


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
) -> tuple[str, ...]:
    errors: list[str] = []
    set_metadata = specimens["SET"].metadata
    clear_metadata = specimens["CLEAR"].metadata
    for field in (
        "specimen_id",
        "device_marking",
        "tracking_date_string",
        "lot_string",
        "package_type",
    ):
        if set_metadata.get(field) != clear_metadata.get(field):
            errors.append(f"SET and CLEAR metadata disagree on specimen {field}")
    return tuple(errors)


def _program_image_words(path: Path | None) -> dict[int, int]:
    if path is None or not path.is_file():
        return {}
    try:
        image = path.read_bytes()
    except OSError:
        return {}
    if len(image) % 2:
        return {}
    return {
        address: int.from_bytes(image[offset : offset + 2], "big")
        for address, offset in enumerate(range(0, len(image), 2))
    }


def _read_measurements(path: Path) -> dict[str, ResetMeasurement]:
    try:
        with path.open("r", encoding="utf-8", newline="") as input_file:
            return read_reset_measurements(input_file)
    except (OSError, UnicodeError) as error:
        raise CaptureError(f"cannot read reset measurements {path}: {error}") from error


def _coverage(
    observations: tuple[Observation, ...], minimum_nominal_runs: int
) -> tuple[int, bool, bool]:
    nominal_count = sum(item.clock_condition == "nominal" for item in observations)
    minimum_met = nominal_count >= minimum_nominal_runs
    labels = {item.clock_condition for item in observations}
    targets = {item.reset_hold_target_cycles for item in observations}
    combinations = {
        (item.clock_condition, item.reset_hold_target_cycles)
        for item in observations
    }
    by_label = {
        label: [
            (item.minimum_clkout_period_ns + item.maximum_clkout_period_ns) / 2
            for item in observations
            if item.clock_condition == label and item.minimum_clkout_period_ns > 0
        ]
        for label in ALLOWED_CLOCK_CONDITIONS
    }
    ordered = all(by_label.values()) and (
        min(by_label["slow_limit"]) > max(by_label["nominal"])
        and min(by_label["nominal"]) > max(by_label["fast_limit"])
    )
    complete = (
        labels == ALLOWED_CLOCK_CONDITIONS
        and targets == REQUIRED_RESET_TARGETS
        and combinations
        == {
            (label, target)
            for label in ALLOWED_CLOCK_CONDITIONS
            for target in REQUIRED_RESET_TARGETS
        }
        and ordered
    )
    return nominal_count, minimum_met, complete


def _field_summaries(fixtures: tuple[FixtureSummary, ...]) -> tuple[FieldSummary, ...]:
    observations = {
        summary.fixture: [item for item in summary.observations if item.fields]
        for summary in fixtures
    }
    if not all(observations.values()):
        return ()
    result: list[FieldSummary] = []
    for field_index, template in enumerate(observations["SET"][0].fields):
        set_fields = [item.fields[field_index] for item in observations["SET"]]
        clear_fields = [item.fields[field_index] for item in observations["CLEAR"]]
        relationships = set(item.relationship for item in set_fields + clear_fields)
        post_values = set(item.post_value for item in set_fields + clear_fields)
        if relationships == {"RETAINED"}:
            pair_classification = "RETAINED_BOTH_FIXTURES"
        elif len(post_values) == 1:
            digits = (template.width + 3) // 4
            pair_classification = f"COMMON_POST_0x{next(iter(post_values)):0{digits}x}"
        else:
            pair_classification = "MIXED_OR_VARIABLE"
        result.append(
            FieldSummary(
                name=template.name,
                width=template.width,
                set_relationships=tuple(item.relationship for item in set_fields),
                clear_relationships=tuple(item.relationship for item in clear_fields),
                set_post_values=tuple(item.post_value for item in set_fields),
                clear_post_values=tuple(item.post_value for item in clear_fields),
                pair_classification=pair_classification,
            )
        )
    return tuple(result)


def build_report(
    set_capture: Path,
    clear_capture: Path,
    set_reset_measurements: Path,
    clear_reset_measurements: Path,
    *,
    minimum_nominal_runs: int = 32,
    set_metadata: Path | None = None,
    clear_metadata: Path | None = None,
    set_image: Path | None = None,
    clear_image: Path | None = None,
    artifact_root: Path | None = None,
) -> CaptureReport:
    if minimum_nominal_runs <= 0:
        raise CaptureError("minimum_nominal_runs must be positive")
    capture_paths = {"SET": set_capture, "CLEAR": clear_capture}
    measurement_paths = {
        "SET": set_reset_measurements,
        "CLEAR": clear_reset_measurements,
    }
    metadata_paths = {"SET": set_metadata, "CLEAR": clear_metadata}
    image_paths = {"SET": set_image, "CLEAR": clear_image}
    specimens = {
        fixture: validate_specimen_evidence(
            metadata_paths[fixture],
            capture_paths[fixture],
            artifact_root,
            fixture_source_sha256=FIXTURE_SOURCE_SHA256[fixture],
            fixture_words=_program_image_words(image_paths[fixture]),
        )
        for fixture in FIXTURES
    }
    specimen_pair_errors = _validate_specimen_pair(specimens)
    summaries: list[FixtureSummary] = []
    for fixture in FIXTURES:
        runs = _read_capture(capture_paths[fixture])
        measurements = _read_measurements(measurement_paths[fixture])
        package, conditions = validate_reset_evidence(
            fixture,
            metadata_paths[fixture],
            image_paths[fixture],
            measurement_paths[fixture],
            artifact_root,
            set(runs),
        )
        package = _merge_specimen_evidence(package, specimens[fixture])
        if set(runs) != set(measurements):
            raise CaptureError(
                f"{fixture} capture and reset-measurement run names must match"
            )
        if set(conditions) == set(runs):
            observations = analyze_fixture(fixture, runs, measurements, conditions)
        else:
            observations = ()
        nominal_count, minimum_met, coverage_complete = _coverage(
            observations, minimum_nominal_runs
        )
        summaries.append(
            FixtureSummary(
                fixture=fixture,
                run_count=len(runs),
                nominal_run_count=nominal_count,
                minimum_nominal_runs_met=minimum_met,
                condition_coverage_complete=coverage_complete,
                complete=(
                    len(observations) == len(runs)
                    and all(item.capture_complete for item in observations)
                ),
                repeatable=(
                    bool(observations)
                    and len({item.post_vector for item in observations}) == 1
                ),
                fixture_valid=(
                    len(observations) == len(runs)
                    and all(item.fixture_valid for item in observations)
                ),
                capture_sha256=_hash_file(capture_paths[fixture]),
                reset_measurements_sha256=_hash_file(measurement_paths[fixture]),
                classifications=tuple(item.classification for item in observations),
                observations=observations,
                evidence_package=package,
            )
        )
    fixture_tuple = tuple(summaries)
    field_summaries = _field_summaries(fixture_tuple)
    minimum_met = all(item.minimum_nominal_runs_met for item in fixture_tuple)
    coverage_complete = all(item.condition_coverage_complete for item in fixture_tuple)
    complete = all(item.complete for item in fixture_tuple)
    fixture_valid = all(item.fixture_valid for item in fixture_tuple)
    review_ready = (
        minimum_met
        and coverage_complete
        and complete
        and fixture_valid
        and all(item.evidence_package.complete for item in fixture_tuple)
        and not specimen_pair_errors
    )
    specimen_id = specimens["SET"].specimen_id
    specimen_scope = specimens["SET"].specimen_scope
    if specimen_pair_errors:
        specimen_id = None
        specimen_scope = "UNQUALIFIED"
    return CaptureReport(
        minimum_nominal_runs=minimum_nominal_runs,
        minimum_nominal_runs_met=minimum_met,
        condition_coverage_complete=coverage_complete,
        complete=complete,
        fixture_valid=fixture_valid,
        review_ready=review_ready,
        observed_full_retention_candidate=(
            review_ready
            and bool(field_summaries)
            and all(item.pair_classification == "RETAINED_BOTH_FIXTURES" for item in field_summaries)
        ),
        acceptance_complete=False,
        specimen_id=specimen_id,
        specimen_scope=specimen_scope,
        specimen_pair_errors=specimen_pair_errors,
        fixtures=fixture_tuple,
        field_summaries=field_summaries,
    )


def _format_value(value: int, width: int) -> str:
    return f"0x{value:0{(width + 3) // 4}x}"


def _field_json(item: FieldObservation) -> dict[str, object]:
    return {
        "name": item.name,
        "width": item.width,
        "evidence_scope": item.evidence_scope,
        "pre_value": _format_value(item.pre_value, item.width),
        "post_value": _format_value(item.post_value, item.width),
        "relationship": item.relationship,
    }


def _observation_json(item: Observation) -> dict[str, object]:
    return {
        "fixture": item.fixture,
        "run": item.run,
        "classification": item.classification,
        "clock_condition": item.clock_condition,
        "reset_hold_target_cycles": item.reset_hold_target_cycles,
        "reset_low_complete_cycles": item.reset_low_complete_cycles,
        "reset_width_ns": str(item.reset_width_ns),
        "minimum_clkout_period_ns": str(item.minimum_clkout_period_ns),
        "maximum_clkout_period_ns": str(item.maximum_clkout_period_ns),
        "output_sequence": [f"0x{value:04x}" for value in item.output_sequence],
        "pre_vector": [f"0x{value:04x}" for value in item.pre_vector],
        "post_vector": [f"0x{value:04x}" for value in item.post_vector],
        "pre_status_reserved_bit_1": item.pre_status_reserved_bit_1,
        "post_status_reserved_bit_1": item.post_status_reserved_bit_1,
        "fields": [_field_json(field) for field in item.fields],
        "capture_complete": item.capture_complete,
        "fixture_valid": item.fixture_valid,
        "warnings": list(item.warnings),
    }


def _package_json(item: EvidencePackage) -> dict[str, object]:
    return {
        "complete": item.complete,
        "errors": list(item.errors),
        "program_image_sha256": item.program_image_sha256,
        "verified_artifacts": list(item.verified_artifacts),
    }


def _fixture_json(item: FixtureSummary) -> dict[str, object]:
    return {
        "fixture": item.fixture,
        "run_count": item.run_count,
        "nominal_run_count": item.nominal_run_count,
        "minimum_nominal_runs_met": item.minimum_nominal_runs_met,
        "condition_coverage_complete": item.condition_coverage_complete,
        "complete": item.complete,
        "repeatable": item.repeatable,
        "fixture_valid": item.fixture_valid,
        "capture_sha256": item.capture_sha256,
        "reset_measurements_sha256": item.reset_measurements_sha256,
        "classifications": list(item.classifications),
        "observations": [_observation_json(observation) for observation in item.observations],
        "evidence_package": _package_json(item.evidence_package),
    }


def _field_summary_json(item: FieldSummary) -> dict[str, object]:
    return {
        "name": item.name,
        "width": item.width,
        "set_relationships": list(item.set_relationships),
        "clear_relationships": list(item.clear_relationships),
        "set_post_values": [_format_value(value, item.width) for value in item.set_post_values],
        "clear_post_values": [_format_value(value, item.width) for value in item.clear_post_values],
        "pair_classification": item.pair_classification,
    }


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("set_capture", type=Path)
    parser.add_argument("clear_capture", type=Path)
    parser.add_argument("--set-reset-measurements", type=Path, required=True)
    parser.add_argument("--clear-reset-measurements", type=Path, required=True)
    parser.add_argument("--set-metadata", type=Path)
    parser.add_argument("--clear-metadata", type=Path)
    parser.add_argument("--set-image", type=Path)
    parser.add_argument("--clear-image", type=Path)
    parser.add_argument("--artifact-root", type=Path)
    parser.add_argument("--minimum-nominal-runs", type=int, default=32)
    parser.add_argument("--require-review-ready", action="store_true")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_argument_parser().parse_args(argv)
    try:
        report = build_report(
            args.set_capture,
            args.clear_capture,
            args.set_reset_measurements,
            args.clear_reset_measurements,
            minimum_nominal_runs=args.minimum_nominal_runs,
            set_metadata=args.set_metadata,
            clear_metadata=args.clear_metadata,
            set_image=args.set_image,
            clear_image=args.clear_image,
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
