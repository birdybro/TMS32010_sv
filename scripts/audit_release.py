#!/usr/bin/env python3
"""Audit candidate tracked files against the repository release policy."""

from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256
import json
from pathlib import Path
import subprocess
import sys
from typing import Mapping, Sequence

try:
    from reference_manifest import ManifestError, REPOSITORY_ROOT, load_manifest
except ModuleNotFoundError:  # Imported as scripts.audit_release by unit tests.
    from scripts.reference_manifest import (
        ManifestError,
        REPOSITORY_ROOT,
        load_manifest,
    )


POLICY_PATH = REPOSITORY_ROOT / "docs" / "release_audit.yaml"
REQUIRED_POLICY_KEYS = {
    "schema_version",
    "claim_boundary",
    "project_license",
    "prohibited_path_prefixes",
    "allowed_placeholder_paths",
    "tracked_artifact_allowlist",
    "forbidden_binary_suffixes",
    "binary_allowlist",
    "external_materials",
    "generated_files",
    "canonical_data_files",
}


class AuditError(ValueError):
    """Raised when the release-audit policy itself cannot be interpreted."""


@dataclass(frozen=True)
class AuditReport:
    candidate_file_count: int
    generated_file_count: int
    canonical_data_file_count: int
    external_material_count: int
    binary_file_count: int
    noncommittable_reference_count: int
    errors: tuple[str, ...]

    @property
    def passed(self) -> bool:
        return not self.errors


def _hash_file(path: Path) -> str:
    digest = sha256()
    with path.open("rb") as input_file:
        for chunk in iter(lambda: input_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_policy(path: Path = POLICY_PATH) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise AuditError(f"cannot read release-audit policy: {error}") from error
    if not isinstance(value, dict):
        raise AuditError("release-audit policy root must be an object")
    missing = REQUIRED_POLICY_KEYS - set(value)
    extra = set(value) - REQUIRED_POLICY_KEYS
    if missing or extra:
        raise AuditError(
            "release-audit policy keys differ: "
            f"missing={sorted(missing)} extra={sorted(extra)}"
        )
    if value.get("schema_version") != 1:
        raise AuditError("release-audit policy schema_version must be 1")
    return value


def candidate_files(root: Path = REPOSITORY_ROOT) -> tuple[Path, ...]:
    """Return tracked plus nonignored untracked candidates for pre-commit audit."""

    try:
        result = subprocess.run(
            [
                "git",
                "ls-files",
                "-z",
                "--cached",
                "--others",
                "--exclude-standard",
            ],
            cwd=root,
            check=True,
            capture_output=True,
        )
    except (OSError, subprocess.CalledProcessError) as error:
        raise AuditError(f"cannot enumerate candidate files: {error}") from error
    try:
        paths = [
            Path(raw.decode("utf-8"))
            for raw in result.stdout.split(b"\0")
            if raw
        ]
    except UnicodeDecodeError as error:
        raise AuditError("git returned a non-UTF-8 candidate path") from error
    return tuple(sorted(set(paths), key=lambda item: item.as_posix()))


def _string_list(policy: Mapping[str, object], key: str, errors: list[str]) -> list[str]:
    value = policy.get(key)
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        errors.append(f"policy {key} must be a list of strings")
        return []
    if len(value) != len(set(value)):
        errors.append(f"policy {key} contains duplicates")
    return list(value)


def _record_paths(
    policy: Mapping[str, object],
    key: str,
    errors: list[str],
) -> dict[str, Mapping[str, object]]:
    value = policy.get(key)
    if not isinstance(value, list):
        errors.append(f"policy {key} must be a list")
        return {}
    records: dict[str, Mapping[str, object]] = {}
    for index, item in enumerate(value):
        if not isinstance(item, dict):
            errors.append(f"policy {key}[{index}] must be an object")
            continue
        path = item.get("path")
        if (
            not isinstance(path, str)
            or not path
            or Path(path).is_absolute()
            or ".." in Path(path).parts
        ):
            errors.append(f"policy {key}[{index}] has an invalid path")
            continue
        if path in records:
            errors.append(f"policy {key} repeats path {path}")
            continue
        records[path] = item
    return records


def audit_repository(
    root: Path,
    policy: Mapping[str, object],
    candidates: Sequence[Path],
    reference_manifest: Mapping[str, object],
) -> AuditReport:
    errors: list[str] = []
    candidate_names = {path.as_posix() for path in candidates}
    placeholders = set(_string_list(policy, "allowed_placeholder_paths", errors))
    artifact_allowlist = set(
        _string_list(policy, "tracked_artifact_allowlist", errors)
    )
    prohibited_prefixes = _string_list(policy, "prohibited_path_prefixes", errors)
    forbidden_suffixes = {
        value.lower()
        for value in _string_list(policy, "forbidden_binary_suffixes", errors)
    }
    binary_records = _record_paths(policy, "binary_allowlist", errors)
    external_records = _record_paths(policy, "external_materials", errors)
    generated_records = _record_paths(policy, "generated_files", errors)
    canonical_records = _record_paths(policy, "canonical_data_files", errors)

    license_record = policy.get("project_license")
    if not isinstance(license_record, dict):
        errors.append("policy project_license must be an object")
    else:
        license_path = license_record.get("license_file")
        spdx = license_record.get("spdx_identifier")
        copyright_line = license_record.get("copyright_line")
        if spdx != "MIT" or not isinstance(license_path, str):
            errors.append("project license policy must select the tracked MIT license")
        else:
            candidate = root / license_path
            try:
                text = candidate.read_text(encoding="utf-8")
            except (OSError, UnicodeError) as error:
                errors.append(f"cannot read project license: {error}")
            else:
                if not text.startswith("MIT License\n"):
                    errors.append("project license does not contain the MIT text")
                if not isinstance(copyright_line, str) or copyright_line not in text:
                    errors.append("project license lacks the policy copyright line")
            if license_path not in candidate_names:
                errors.append("project license file is not a candidate file")

    for path in candidates:
        name = path.as_posix()
        absolute = root / path
        if absolute.is_symlink():
            errors.append(f"candidate symlink requires explicit review: {name}")
            continue
        if not absolute.is_file():
            errors.append(f"candidate path is not a regular file: {name}")
            continue
        if any(name.startswith(prefix) for prefix in prohibited_prefixes):
            errors.append(f"generated/reference-cache path is a candidate: {name}")
        if name.startswith("build/") and name not in placeholders:
            errors.append(f"build product is a candidate: {name}")
        if name.startswith("artifacts/") and name not in artifact_allowlist:
            errors.append(f"unreviewed artifact is a candidate: {name}")
        if (
            name.startswith("third_party/")
            and name not in placeholders
            and name not in external_records
        ):
            errors.append(f"third-party material lacks a policy record: {name}")

    for path in sorted(placeholders | artifact_allowlist):
        if path not in candidate_names:
            errors.append(f"policy allowlist path is not a candidate: {path}")

    generated_names = {
        name
        for name in candidate_names
        if name.startswith("docs/generated/") and not name.endswith("/.gitkeep")
    }
    documented_generated = set(generated_records) | set(canonical_records)
    if generated_names != documented_generated:
        errors.append(
            "docs/generated policy differs: "
            f"undocumented={sorted(generated_names - documented_generated)} "
            f"stale={sorted(documented_generated - generated_names)}"
        )
    for name, record in generated_records.items():
        generator = record.get("generator")
        inputs = record.get("inputs")
        command = record.get("verification_command")
        if not isinstance(generator, str) or generator not in candidate_names:
            errors.append(f"generated file {name} lacks a candidate generator")
        if not isinstance(inputs, list) or not inputs or not all(
            isinstance(item, str) and item in candidate_names for item in inputs
        ):
            errors.append(f"generated file {name} lacks candidate inputs")
        if not isinstance(command, str) or not command.strip():
            errors.append(f"generated file {name} lacks a verification command")
        candidate = root / name
        try:
            text = candidate.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as error:
            errors.append(f"cannot read generated file {name}: {error}")
        else:
            if isinstance(generator, str) and f"Generated by {generator}" not in text:
                errors.append(f"generated file {name} lacks its generator marker")
    for name, record in canonical_records.items():
        if not all(
            isinstance(record.get(field), str) and str(record[field]).strip()
            for field in ("status", "provenance")
        ):
            errors.append(f"canonical data file {name} lacks status/provenance")

    for name, record in external_records.items():
        if not name.startswith("third_party/") or name not in candidate_names:
            errors.append(f"external material {name} is outside tracked third_party")
        for field in ("license", "source_url", "sha256"):
            if not isinstance(record.get(field), str) or not str(record[field]).strip():
                errors.append(f"external material {name} lacks {field}")
        if record.get("may_commit") is not True:
            errors.append(f"external material {name} is not approved for commit")

    binary_names: set[str] = set()
    candidate_hashes: dict[str, str] = {}
    for path in candidates:
        name = path.as_posix()
        absolute = root / path
        if not absolute.is_file() or absolute.is_symlink():
            continue
        try:
            data = absolute.read_bytes()
        except OSError as error:
            errors.append(f"cannot read candidate {name}: {error}")
            continue
        candidate_hashes[name] = sha256(data).hexdigest()
        try:
            data.decode("utf-8")
            utf8 = True
        except UnicodeDecodeError:
            utf8 = False
        if data and (b"\0" in data or not utf8 or path.suffix.lower() in forbidden_suffixes):
            binary_names.add(name)
            if name not in binary_records:
                errors.append(f"binary/document candidate lacks an allowlist record: {name}")
    if set(binary_records) - binary_names:
        errors.append(
            "binary allowlist contains nonbinary or missing paths: "
            f"{sorted(set(binary_records) - binary_names)}"
        )
    for name, record in binary_records.items():
        for field in ("license", "provenance", "sha256"):
            if not isinstance(record.get(field), str) or not str(record[field]).strip():
                errors.append(f"binary allowlist record {name} lacks {field}")
        if record.get("may_commit") is not True:
            errors.append(f"binary allowlist record {name} is not approved for commit")
        digest = record.get("sha256")
        if isinstance(digest, str) and candidate_hashes.get(name) != digest:
            errors.append(f"binary allowlist record {name} has a SHA-256 mismatch")

    sources = reference_manifest.get("sources")
    if not isinstance(sources, list):
        errors.append("reference manifest sources must be a list")
        noncommittable_hashes: dict[str, str] = {}
    else:
        noncommittable_hashes = {
            str(source.get("sha256")): str(source.get("id"))
            for source in sources
            if isinstance(source, dict)
            and source.get("may_commit") is False
            and isinstance(source.get("sha256"), str)
        }
    for name, digest in candidate_hashes.items():
        if digest in noncommittable_hashes:
            errors.append(
                f"candidate {name} matches noncommittable reference "
                f"{noncommittable_hashes[digest]}"
            )

    return AuditReport(
        candidate_file_count=len(candidates),
        generated_file_count=len(generated_records),
        canonical_data_file_count=len(canonical_records),
        external_material_count=len(external_records),
        binary_file_count=len(binary_names),
        noncommittable_reference_count=len(noncommittable_hashes),
        errors=tuple(errors),
    )


def run_audit(root: Path = REPOSITORY_ROOT, policy_path: Path = POLICY_PATH) -> AuditReport:
    policy = load_policy(policy_path)
    try:
        manifest = load_manifest()
    except ManifestError as error:
        raise AuditError(str(error)) from error
    return audit_repository(root, policy, candidate_files(root), manifest)


def main() -> int:
    try:
        report = run_audit()
    except AuditError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    for error in report.errors:
        print(f"ERROR: {error}", file=sys.stderr)
    if not report.passed:
        print(f"FAIL: tracked license/provenance audit ({len(report.errors)} errors)")
        return 1
    print(
        "PASS: tracked license/provenance audit "
        f"({report.candidate_file_count} candidates, "
        f"{report.generated_file_count} generated, "
        f"{report.canonical_data_file_count} canonical data, "
        f"{report.external_material_count} external, "
        f"{report.binary_file_count} binary, "
        f"{report.noncommittable_reference_count} prohibited reference hashes)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
