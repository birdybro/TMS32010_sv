#!/usr/bin/env python3
"""Check repository layout, backlog structure, and provenance consistency."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

from reference_manifest import ManifestError, REPOSITORY_ROOT, load_manifest

REQUIRED_FILES = {
    "AGENTS.md",
    "README.md",
    "CHANGELOG.md",
    "TASKS.md",
    "LICENSE",
    "CONTRIBUTING.md",
    ".gitignore",
    ".gitattributes",
    "docs/references/manifest.yaml",
    "docs/references/README.md",
    "artifacts/progress.md",
}
REQUIRED_DIRECTORIES = {
    "docs/architecture",
    "docs/research",
    "docs/references",
    "docs/timing",
    "docs/integration",
    "docs/decisions",
    "docs/generated",
    "rtl/core",
    "rtl/packages",
    "rtl/wrappers",
    "sim/unit",
    "sim/instruction",
    "sim/bus",
    "sim/interrupt",
    "sim/programs",
    "sim/differential",
    "sim/reference_models",
    "formal",
    "tools/assembler",
    "tools/disassembler",
    "tools/trace",
    "tools/reference",
    "tools/generators",
    "scripts",
    "tests/asm",
    "tests/expected",
    "tests/regressions",
    "synthesis/quartus",
    "synthesis/verilator",
    "synthesis/yosys",
    "third_party",
    "build",
    "artifacts",
    ".github/workflows",
}
TASK_FIELDS = {
    "Status",
    "Priority",
    "Dependencies",
    "Description",
    "Acceptance criteria",
    "Documentation",
    "Tests",
    "Notes",
}
FORBIDDEN_TRACKED_SUFFIXES = {".pdf", ".rom", ".zip", ".exe", ".dll"}


def check_layout(errors: list[str]) -> None:
    for relative in sorted(REQUIRED_FILES):
        if not (REPOSITORY_ROOT / relative).is_file():
            errors.append(f"missing required file: {relative}")
    for relative in sorted(REQUIRED_DIRECTORIES):
        if not (REPOSITORY_ROOT / relative).is_dir():
            errors.append(f"missing required directory: {relative}/")


def check_tasks(errors: list[str]) -> None:
    tasks_path = REPOSITORY_ROOT / "TASKS.md"
    text = tasks_path.read_text(encoding="utf-8")
    milestones = {
        int(number)
        for number in re.findall(r"^## Milestone (\d+)\b", text, re.MULTILINE)
    }
    expected = set(range(1, 23))
    if milestones != expected:
        errors.append(
            "TASKS.md milestone set differs: "
            f"missing={sorted(expected - milestones)} "
            f"extra={sorted(milestones - expected)}"
        )

    task_matches = list(
        re.finditer(
            r"^### ([A-Z]+-\d+) — .+?(?=^### |^## Milestone |\Z)",
            text,
            re.MULTILINE | re.DOTALL,
        )
    )
    if not task_matches:
        errors.append("TASKS.md contains no stable task IDs")
        return
    seen: set[str] = set()
    for match in task_matches:
        task_id = match.group(1)
        if task_id in seen:
            errors.append(f"TASKS.md has duplicate task ID: {task_id}")
        seen.add(task_id)
        block = match.group(0)
        fields = set(re.findall(r"^- \*\*([^*]+):\*\*", block, re.MULTILINE))
        missing = TASK_FIELDS - fields
        if missing:
            errors.append(
                f"{task_id} missing task fields: {', '.join(sorted(missing))}"
            )


def check_changelog(errors: list[str]) -> None:
    text = (REPOSITORY_ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    for heading in (
        "## [Unreleased]",
        "### Added",
        "### Changed",
        "### Fixed",
        "### Verified",
        "### Known Issues",
    ):
        if heading not in text:
            errors.append(f"CHANGELOG.md missing heading: {heading}")


def tracked_files() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=REPOSITORY_ROOT,
        check=True,
        capture_output=True,
    )
    return [
        Path(raw.decode("utf-8"))
        for raw in result.stdout.split(b"\0")
        if raw
    ]


def check_tracked_content(errors: list[str]) -> None:
    try:
        tracked = tracked_files()
    except (OSError, subprocess.CalledProcessError) as error:
        errors.append(f"cannot inspect tracked files: {error}")
        return
    for path in tracked:
        if path.parts and path.parts[0] == "reference-cache":
            errors.append(f"reference cache is tracked: {path}")
        if path.suffix.lower() in FORBIDDEN_TRACKED_SUFFIXES:
            errors.append(f"unreviewed binary/document is tracked: {path}")


def main() -> int:
    errors: list[str] = []
    check_layout(errors)
    check_tasks(errors)
    check_changelog(errors)
    check_tracked_content(errors)
    try:
        manifest = load_manifest()
        acquired = sum(
            source["status"] == "acquired" for source in manifest["sources"]
        )
    except ManifestError as error:
        errors.append(str(error))
        acquired = 0

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        print(f"FAIL: documentation consistency ({len(errors)} errors)")
        return 1
    print(
        f"PASS: documentation consistency "
        f"({len(REQUIRED_DIRECTORIES)} directories, {acquired} acquired sources)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
