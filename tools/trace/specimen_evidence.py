#!/usr/bin/env python3
"""Shared validation for original-TMS32010 physical-specimen evidence.

This module validates provenance and scope only.  It deliberately does not
interpret a package tracking string, identify a silicon mask, classify a bus
trace, or promote architectural confidence.
"""

from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256
import json
from math import isfinite
from pathlib import Path
import re
from typing import Mapping


SHA256_PATTERN = re.compile(r"[0-9a-f]{64}")
REQUIRED_SPECIMEN_TEXT = (
    "specimen_id",
    "tracking_date_string",
    "lot_string",
    "package_type",
    "acquisition_provenance",
    "monitor_revision",
)
REQUIRED_TOOL_VERSIONS = (
    "assembler",
    "capture_normalizer",
    "analyzer_decoder",
)
REQUIRED_PHOTOGRAPH_VIEWS = ("top", "bottom", "board_context")


@dataclass(frozen=True)
class SpecimenEvidence:
    """Validated additions to one experiment's base evidence package."""

    metadata: Mapping[str, object]
    errors: tuple[str, ...]
    verified_artifacts: tuple[str, ...]

    @property
    def specimen_id(self) -> str | None:
        value = self.metadata.get("specimen_id")
        return value if isinstance(value, str) and value.strip() else None

    @property
    def specimen_scope(self) -> str:
        value = self.metadata.get("specimen_scope")
        return value if value == "this_specimen_only" else "UNQUALIFIED"


def _hash_file(path: Path) -> str:
    digest = sha256()
    with path.open("rb") as input_file:
        for chunk in iter(lambda: input_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _metadata_object(path: Path | None, errors: list[str]) -> dict[str, object]:
    if path is None:
        errors.append("metadata sidecar was not supplied for specimen validation")
        return {}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        errors.append(f"cannot read specimen metadata sidecar: {error}")
        return {}
    if not isinstance(value, dict):
        errors.append("specimen metadata root must be an object")
        return {}
    return value


def _validate_artifact_map(
    value: Mapping[str, object],
    name: str,
    artifact_root: Path | None,
    errors: list[str],
    verified: list[str],
) -> None:
    if not value:
        return
    if artifact_root is None:
        errors.append(f"artifact_root is required to verify {name}")
        return
    root = artifact_root.resolve()
    for relative_name, expected_hash in sorted(value.items()):
        if not relative_name:
            errors.append(f"{name} contains an empty path")
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
        try:
            actual_hash = _hash_file(candidate)
        except OSError as error:
            errors.append(f"cannot hash {name}[{relative_name!r}]: {error}")
            continue
        if actual_hash != expected_hash:
            errors.append(
                f"{name}[{relative_name!r}] SHA-256 mismatch: {actual_hash}"
            )
            continue
        verified.append(relative_name)


def _validate_fixture_listing(
    artifact_root: Path | None,
    listing_path: object,
    fixture_words: Mapping[int, int],
    errors: list[str],
) -> None:
    if artifact_root is None or not isinstance(listing_path, str) or not listing_path:
        return
    root = artifact_root.resolve()
    candidate = (root / listing_path).resolve()
    if candidate != root and root not in candidate.parents:
        return
    if not candidate.is_file():
        return
    try:
        lines = candidate.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as error:
        errors.append(f"cannot read fixture listing: {error}")
        return
    listed: dict[int, int] = {}
    for line_number, line in enumerate(lines, start=1):
        if not line.strip():
            continue
        match = re.match(r"^([0-9a-fA-F]{3})\s+([0-9a-fA-F]{4})(?:\s|$)", line)
        if match is None:
            errors.append(f"fixture listing line {line_number} is malformed")
            return
        address = int(match.group(1), 16)
        if address in listed:
            errors.append(f"fixture listing repeats address 0x{address:03x}")
            return
        listed[address] = int(match.group(2), 16)
    if listed != dict(fixture_words):
        errors.append("fixture listing does not contain the exact address/word map")


def validate_specimen_evidence(
    metadata_path: Path | None,
    capture_path: Path,
    artifact_root: Path | None,
    *,
    fixture_source_sha256: str,
    fixture_words: Mapping[int, int],
) -> SpecimenEvidence:
    """Validate one original-device specimen record and fixture provenance."""

    errors: list[str] = []
    verified: list[str] = []
    metadata = _metadata_object(metadata_path, errors)

    expected_capture_hash = metadata.get("normalized_capture_sha256")
    if not isinstance(expected_capture_hash, str) or not SHA256_PATTERN.fullmatch(
        expected_capture_hash
    ):
        errors.append("metadata normalized_capture_sha256 must be a lowercase SHA-256")
    else:
        try:
            actual_capture_hash = _hash_file(capture_path)
        except OSError as error:
            errors.append(f"cannot hash normalized capture: {error}")
        else:
            if actual_capture_hash != expected_capture_hash:
                errors.append("normalized capture SHA-256 mismatch")

    for field in REQUIRED_SPECIMEN_TEXT:
        value = metadata.get(field)
        if not isinstance(value, str) or not value.strip():
            errors.append(f"metadata {field} must be a nonempty string")
    device_marking = metadata.get("device_marking")
    marking_lines = (
        [line for line in device_marking.splitlines() if line.strip()]
        if isinstance(device_marking, str)
        else []
    )
    if len(marking_lines) < 2:
        errors.append("metadata device_marking must preserve multiple package lines")
    for field in ("tracking_date_string", "lot_string"):
        value = metadata.get(field)
        if (
            isinstance(device_marking, str)
            and isinstance(value, str)
            and value.strip()
            and value not in device_marking
        ):
            errors.append(f"metadata {field} is absent from device_marking")
    if metadata.get("specimen_scope") != "this_specimen_only":
        errors.append("metadata specimen_scope must be this_specimen_only")
    if not isinstance(metadata.get("socketed"), bool):
        errors.append("metadata socketed must be a boolean")

    for field in ("temperature_c", "program_memory_access_time_ns"):
        value = metadata.get(field)
        if (
            isinstance(value, bool)
            or not isinstance(value, (int, float))
            or not isfinite(value)
            or (field == "program_memory_access_time_ns" and value <= 0)
        ):
            qualifier = (
                "a positive finite number"
                if "access_time" in field
                else "a finite number"
            )
            errors.append(f"metadata {field} must be {qualifier}")
    reset_duration_cycles = metadata.get("reset_duration_cycles")
    if (
        isinstance(reset_duration_cycles, bool)
        or not isinstance(reset_duration_cycles, int)
        or reset_duration_cycles < 5
    ):
        errors.append("metadata reset_duration_cycles must be an integer at least 5")

    tool_versions = metadata.get("fixture_tool_versions")
    if not isinstance(tool_versions, dict):
        errors.append("metadata fixture_tool_versions must be an object")
    else:
        for name in REQUIRED_TOOL_VERSIONS:
            value = tool_versions.get(name)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"metadata fixture_tool_versions lacks {name}")

    fixture_artifacts = metadata.get("fixture_artifacts")
    fixture_files: dict[str, object] = {}
    listing_path: object = None
    if not isinstance(fixture_artifacts, dict):
        errors.append("metadata fixture_artifacts must be an object")
    else:
        for kind in ("source", "listing"):
            item = fixture_artifacts.get(kind)
            if not isinstance(item, dict):
                errors.append(f"metadata fixture_artifacts lacks {kind}")
                continue
            path = item.get("path")
            digest = item.get("sha256")
            if not isinstance(path, str) or not path:
                errors.append(f"metadata fixture_artifacts.{kind} path is invalid")
                continue
            if path in fixture_files:
                errors.append("metadata fixture artifact paths must be distinct")
                continue
            fixture_files[path] = digest
            if kind == "source" and digest != fixture_source_sha256:
                errors.append("fixture source is not the exact project-authored source")
            if kind == "listing":
                listing_path = path
    _validate_artifact_map(
        fixture_files,
        "fixture_artifacts",
        artifact_root,
        errors,
        verified,
    )
    _validate_fixture_listing(artifact_root, listing_path, fixture_words, errors)

    photographs = metadata.get("specimen_photographs")
    photograph_files: dict[str, object] = {}
    if not isinstance(photographs, dict):
        errors.append("metadata specimen_photographs must be an object")
    else:
        for view in REQUIRED_PHOTOGRAPH_VIEWS:
            item = photographs.get(view)
            if not isinstance(item, dict):
                errors.append(f"metadata specimen_photographs lacks {view}")
                continue
            path = item.get("path")
            digest = item.get("sha256")
            if not isinstance(path, str) or not path:
                errors.append(f"metadata specimen_photographs.{view} path is invalid")
                continue
            if path in photograph_files:
                errors.append("metadata specimen photograph paths must be distinct")
                continue
            photograph_files[path] = digest
    _validate_artifact_map(
        photograph_files,
        "specimen_photographs",
        artifact_root,
        errors,
        verified,
    )
    return SpecimenEvidence(
        metadata=metadata,
        errors=tuple(errors),
        verified_artifacts=tuple(sorted(set(verified))),
    )
