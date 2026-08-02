#!/usr/bin/env python3
"""Validate the machine-readable release evidence without making a release claim."""

from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
import json
from pathlib import Path
import re
import sys
from typing import Mapping, Sequence

try:
    from audit_release import AuditError, REPOSITORY_ROOT, candidate_files
except ModuleNotFoundError:  # Imported as scripts.check_release_evidence.
    from scripts.audit_release import AuditError, REPOSITORY_ROOT, candidate_files


EVIDENCE_PATH = REPOSITORY_ROOT / "docs" / "release_evidence.yaml"
CHECKLIST_PATH = REPOSITORY_ROOT / "docs" / "release_checklist.md"
REQUIRED_CRITERIA = {
    "instruction_completeness",
    "cycle_timing_completeness",
    "clean_lint",
    "passing_regressions",
    "differential_tests",
    "formal_checks",
    "yosys_synthesis",
    "quartus_synthesis",
    "no_inferred_latches",
    "no_accidental_clocks",
    "constrained_timing_paths",
    "resource_utilization",
    "maximum_clock_frequency",
    "integration_guide",
    "programming_model",
    "native_interface_specification",
    "known_issues",
    "reproducible_toolchain",
    "license_and_provenance",
    "realistic_dsp_program",
    "hard_drivin_qualification",
}
ALLOWED_STATUSES = {
    "NOT_MET",
    "PARTIAL",
    "PASS_CURRENT_SCOPE",
    "RELEASE_QUALIFIED",
}


@dataclass(frozen=True)
class EvidenceReport:
    criterion_count: int
    status_counts: Mapping[str, int]
    release_ready: bool
    errors: tuple[str, ...]

    @property
    def passed(self) -> bool:
        return not self.errors


def load_inventory(path: Path = EVIDENCE_PATH) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise AuditError(f"cannot read release-evidence inventory: {error}") from error
    if not isinstance(value, dict):
        raise AuditError("release-evidence inventory root must be an object")
    if set(value) != {"schema_version", "release_ready", "claim_boundary", "criteria"}:
        raise AuditError("release-evidence inventory keys differ from schema")
    if value.get("schema_version") != 1:
        raise AuditError("release-evidence schema_version must be 1")
    return value


def _make_targets(root: Path) -> set[str]:
    text = (root / "Makefile").read_text(encoding="utf-8")
    return set(re.findall(r"^([a-z][a-z0-9-]*):", text, re.MULTILINE))


def _known_blockers(root: Path) -> tuple[set[str], set[str]]:
    tasks = (root / "TASKS.md").read_text(encoding="utf-8")
    questions = (root / "docs" / "research" / "open_questions.md").read_text(
        encoding="utf-8"
    )
    return (
        set(re.findall(r"^### ([A-Z]+-\d+) —", tasks, re.MULTILINE)),
        set(re.findall(r"\| (OQ-\d+) \|", questions)),
    )


def _checklist_rows(path: Path, errors: list[str]) -> dict[str, str]:
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        errors.append(f"cannot read release checklist: {error}")
        return {}
    rows: dict[str, str] = {}
    for criterion_id, status in re.findall(
        r"^\| `([a-z][a-z0-9_]*)` \| [^|]+ \| ([A-Z_]+) \|",
        text,
        re.MULTILINE,
    ):
        if criterion_id in rows:
            errors.append(f"release checklist repeats criterion {criterion_id}")
        rows[criterion_id] = status
    return rows


def check_inventory(
    root: Path,
    inventory: Mapping[str, object],
    candidates: Sequence[Path],
    checklist_path: Path = CHECKLIST_PATH,
) -> EvidenceReport:
    errors: list[str] = []
    criteria_value = inventory.get("criteria")
    if not isinstance(criteria_value, list):
        errors.append("release-evidence criteria must be a list")
        criteria_value = []
    release_ready = inventory.get("release_ready")
    if not isinstance(release_ready, bool):
        errors.append("release_ready must be a boolean")
        release_ready = False
    claim_boundary = inventory.get("claim_boundary")
    if (
        not isinstance(claim_boundary, str)
        or "not release qualification" not in claim_boundary.lower()
    ):
        errors.append("release-evidence claim boundary is missing or overbroad")

    candidate_names = {path.as_posix() for path in candidates}
    make_targets = _make_targets(root)
    task_ids, question_ids = _known_blockers(root)
    records: dict[str, Mapping[str, object]] = {}
    statuses: Counter[str] = Counter()
    for index, value in enumerate(criteria_value):
        if not isinstance(value, dict):
            errors.append(f"criterion {index} must be an object")
            continue
        criterion_id = value.get("id")
        if not isinstance(criterion_id, str) or not re.fullmatch(
            r"[a-z][a-z0-9_]*", criterion_id
        ):
            errors.append(f"criterion {index} has an invalid id")
            continue
        if criterion_id in records:
            errors.append(f"release evidence repeats criterion {criterion_id}")
            continue
        records[criterion_id] = value
        if set(value) != {
            "id",
            "criterion",
            "status",
            "evidence_paths",
            "verification_commands",
            "blockers",
        }:
            errors.append(f"criterion {criterion_id} keys differ from schema")
        description = value.get("criterion")
        if not isinstance(description, str) or not description.strip():
            errors.append(f"criterion {criterion_id} lacks a description")
        status = value.get("status")
        if not isinstance(status, str) or status not in ALLOWED_STATUSES:
            errors.append(f"criterion {criterion_id} has an invalid status")
        else:
            statuses[status] += 1
        paths = value.get("evidence_paths")
        if not isinstance(paths, list) or not paths:
            errors.append(f"criterion {criterion_id} lacks evidence paths")
        else:
            for path in paths:
                if not isinstance(path, str) or path not in candidate_names:
                    errors.append(
                        f"criterion {criterion_id} has missing evidence path {path!r}"
                    )
        commands = value.get("verification_commands")
        if not isinstance(commands, list) or not commands:
            errors.append(f"criterion {criterion_id} lacks verification commands")
        else:
            for command in commands:
                match = re.fullmatch(r"make ([a-z][a-z0-9-]*)", str(command))
                if match is None or match.group(1) not in make_targets:
                    errors.append(
                        f"criterion {criterion_id} has unknown command {command!r}"
                    )
        blockers = value.get("blockers")
        if not isinstance(blockers, list):
            errors.append(f"criterion {criterion_id} blockers must be a list")
        else:
            for blocker in blockers:
                if blocker not in task_ids and blocker not in question_ids:
                    errors.append(
                        f"criterion {criterion_id} has unknown blocker {blocker!r}"
                    )
        if status == "RELEASE_QUALIFIED" and blockers:
            errors.append(f"release-qualified criterion {criterion_id} retains blockers")

    actual_ids = set(records)
    if actual_ids != REQUIRED_CRITERIA:
        errors.append(
            "release criterion set differs: "
            f"missing={sorted(REQUIRED_CRITERIA - actual_ids)} "
            f"extra={sorted(actual_ids - REQUIRED_CRITERIA)}"
        )
    checklist_rows = _checklist_rows(checklist_path, errors)
    expected_rows = {
        criterion_id: str(record.get("status"))
        for criterion_id, record in records.items()
    }
    checklist_ids = set(checklist_rows)
    expected_ids = set(expected_rows)
    if checklist_ids != expected_ids:
        errors.append(
            "release checklist rows differ from inventory: "
            f"missing={sorted(expected_ids - checklist_ids)} "
            f"extra={sorted(checklist_ids - expected_ids)}"
        )
    else:
        for criterion_id, status in expected_rows.items():
            if checklist_rows[criterion_id] != status:
                errors.append(
                    f"release checklist status differs for {criterion_id}: "
                    f"{checklist_rows[criterion_id]} != {status}"
                )
    all_qualified = (
        len(records) == len(REQUIRED_CRITERIA)
        and all(
            record.get("status") == "RELEASE_QUALIFIED"
            for record in records.values()
        )
        and all(not record.get("blockers") for record in records.values())
    )
    if release_ready != all_qualified:
        errors.append(
            "release_ready must be true exactly when every criterion is "
            "RELEASE_QUALIFIED without blockers"
        )
    return EvidenceReport(
        criterion_count=len(records),
        status_counts=dict(sorted(statuses.items())),
        release_ready=release_ready,
        errors=tuple(errors),
    )


def run_check() -> EvidenceReport:
    return check_inventory(
        REPOSITORY_ROOT,
        load_inventory(),
        candidate_files(REPOSITORY_ROOT),
    )


def main() -> int:
    try:
        report = run_check()
    except AuditError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    for error in report.errors:
        print(f"ERROR: {error}", file=sys.stderr)
    if not report.passed:
        print(f"FAIL: release-evidence inventory ({len(report.errors)} errors)")
        return 1
    counts = ", ".join(
        f"{status}={count}" for status, count in report.status_counts.items()
    )
    print(
        f"PASS: release-evidence inventory ({report.criterion_count} criteria; "
        f"{counts}; release_ready={str(report.release_ready).lower()})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
