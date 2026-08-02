#!/usr/bin/env python3
"""Run current-scope gates and bind their logs to one clean Git revision."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from hashlib import sha256
import json
import os
from pathlib import Path
import subprocess
import sys
from typing import Callable, Mapping, Sequence

try:
    from audit_release import REPOSITORY_ROOT
except ModuleNotFoundError:  # Imported as scripts.run_release_checks.
    from scripts.audit_release import REPOSITORY_ROOT


DEFAULT_OUTPUT = Path("build/release-evidence/current/receipt.json")
CLAIM_BOUNDARY = (
    "A passing receipt proves only that the listed current-scope commands "
    "returned zero on the recorded clean Git tree. It is not release "
    "qualification, independent attestation, or proof of unimplemented scope."
)
REQUIRED_COMMANDS = (
    "make audit-release",
    "make test",
    "make lint",
    "make formal",
    "make synth-yosys",
    "make synth-quartus",
)
CONTROLLED_ENVIRONMENT = {
    "LC_ALL": "C",
    "PYTHONHASHSEED": "0",
    "TZ": "UTC",
}
REQUIRED_TOOL_NAMES = {
    "git",
    "make",
    "python",
    "quartus",
    "symbiyosys",
    "verilator",
    "yosys",
}
RunCommand = Callable[
    [Sequence[str], Path, Mapping[str, str]], subprocess.CompletedProcess[bytes]
]


class ReceiptError(ValueError):
    """Raised when a receipt cannot be safely produced or interpreted."""


@dataclass(frozen=True)
class RepositoryState:
    commit: str
    tree: str
    clean: bool


@dataclass(frozen=True)
class ReceiptReport:
    command_count: int
    overall_pass: bool
    errors: tuple[str, ...]

    @property
    def passed(self) -> bool:
        return not self.errors


def _run_capture(
    argv: Sequence[str],
    root: Path,
    environment: Mapping[str, str],
) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        list(argv),
        cwd=root,
        env=dict(environment),
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )


def _git_output(root: Path, arguments: Sequence[str]) -> str:
    try:
        result = subprocess.run(
            ["git", *arguments],
            cwd=root,
            check=True,
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError) as error:
        raise ReceiptError(f"cannot inspect Git repository: {error}") from error
    return result.stdout.strip()


def repository_state(root: Path = REPOSITORY_ROOT) -> RepositoryState:
    commit = _git_output(root, ["rev-parse", "HEAD"])
    tree = _git_output(root, ["rev-parse", "HEAD^{tree}"])
    status = _git_output(
        root,
        ["status", "--porcelain=v1", "--untracked-files=all"],
    )
    if not all(len(value) == 40 for value in (commit, tree)):
        raise ReceiptError("Git returned an invalid commit or tree identifier")
    return RepositoryState(commit=commit, tree=tree, clean=not status)


def _version_summary(
    argv: Sequence[str],
    root: Path,
    environment: Mapping[str, str],
    line_count: int = 1,
) -> str:
    try:
        result = subprocess.run(
            list(argv),
            cwd=root,
            env=dict(environment),
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError as error:
        return f"UNAVAILABLE: {error}"
    combined = "\n".join(part for part in (result.stdout, result.stderr) if part)
    lines = [line.strip() for line in combined.splitlines() if line.strip()]
    summary = " | ".join(lines[:line_count])
    if result.returncode != 0:
        return f"UNAVAILABLE: exit {result.returncode}: {summary}"
    return summary or "AVAILABLE: version output empty"


def tool_versions(
    root: Path,
    environment: Mapping[str, str],
) -> dict[str, str]:
    quartus = environment.get("QUARTUS_SH", "quartus_sh")
    symbiyosys = environment.get("SBY", "sby")
    verilator = environment.get("VERILATOR", "verilator")
    yosys = environment.get("YOSYS", "yosys")
    return {
        "git": _version_summary(["git", "--version"], root, environment),
        "make": _version_summary(["make", "--version"], root, environment),
        "python": _version_summary(
            [sys.executable, "--version"], root, environment
        ),
        "quartus": _version_summary(
            [quartus, "--version"], root, environment, line_count=2
        ),
        "symbiyosys": _version_summary(
            [symbiyosys, "--version"], root, environment
        ),
        "verilator": _version_summary(
            [verilator, "--version"], root, environment
        ),
        "yosys": _version_summary([yosys, "-V"], root, environment),
    }


def _receipt_output(root: Path, output: Path) -> Path:
    absolute = output if output.is_absolute() else root / output
    resolved = absolute.resolve()
    allowed_root = (root / "build" / "release-evidence").resolve()
    try:
        resolved.relative_to(allowed_root)
    except ValueError as error:
        raise ReceiptError(
            "receipt output must stay below build/release-evidence"
        ) from error
    if resolved.suffix != ".json":
        raise ReceiptError("receipt output must have a .json suffix")
    return resolved


def _command_argv(command: str) -> tuple[str, str]:
    parts = command.split()
    if len(parts) != 2 or parts[0] != "make":
        raise ReceiptError(f"unsafe release command {command!r}")
    target = parts[1]
    if not target.replace("-", "").isalnum() or target[0].isdigit():
        raise ReceiptError(f"unsafe make target {target!r}")
    return "make", target


def _log_digest(data: bytes) -> str:
    return sha256(data).hexdigest()


def _valid_git_identifier(value: str) -> bool:
    return len(value) == 40 and all(
        character in "0123456789abcdef" for character in value
    )


def write_receipt(
    root: Path,
    output: Path,
    *,
    state: RepositoryState | None = None,
    versions: Mapping[str, str] | None = None,
    command_runner: RunCommand = _run_capture,
    announce: bool = True,
) -> dict[str, object]:
    output = _receipt_output(root, output)
    state = state if state is not None else repository_state(root)
    if not state.clean:
        raise ReceiptError("release checks require a clean Git candidate tree")
    if not _valid_git_identifier(state.commit) or not _valid_git_identifier(state.tree):
        raise ReceiptError("release checks require full lowercase Git identifiers")
    environment = dict(os.environ)
    environment.update(CONTROLLED_ENVIRONMENT)
    recorded_versions = (
        dict(versions) if versions is not None else tool_versions(root, environment)
    )
    if set(recorded_versions) != REQUIRED_TOOL_NAMES:
        raise ReceiptError("tool-version record has missing or extra tools")
    if not all(
        isinstance(version, str) and version.strip()
        for version in recorded_versions.values()
    ):
        raise ReceiptError("tool-version values must be nonempty strings")
    if any(
        version.startswith(("UNAVAILABLE:", "AVAILABLE:"))
        for version in recorded_versions.values()
    ):
        raise ReceiptError("every release-check tool must report an exact version")
    output.parent.mkdir(parents=True, exist_ok=True)
    expected_paths = [output]
    expected_paths.extend(
        output.parent / f"{index:02d}-{_command_argv(command)[1]}.log"
        for index, command in enumerate(REQUIRED_COMMANDS, start=1)
    )
    if any(path.is_symlink() for path in expected_paths):
        raise ReceiptError("release-check receipt and log paths must not be symlinks")
    command_records: list[dict[str, object]] = []
    for index, command in enumerate(REQUIRED_COMMANDS, start=1):
        argv = _command_argv(command)
        target = argv[1]
        log_name = f"{index:02d}-{target}.log"
        if announce:
            print(f"RUN: {command}", flush=True)
        result = command_runner(argv, root, environment)
        log_data = result.stdout or b""
        log_path = output.parent / log_name
        log_path.write_bytes(log_data)
        passed = result.returncode == 0
        if announce:
            print(f"{'PASS' if passed else 'FAIL'}: {command}", flush=True)
        command_records.append(
            {
                "command": command,
                "argv": list(argv),
                "result": "PASS" if passed else "FAIL",
                "return_code": result.returncode,
                "log_path": log_name,
                "log_sha256": _log_digest(log_data),
            }
        )
    overall_pass = all(record["result"] == "PASS" for record in command_records)
    receipt: dict[str, object] = {
        "schema_version": 1,
        "claim_boundary": CLAIM_BOUNDARY,
        "repository": {
            "commit": state.commit,
            "tree": state.tree,
            "clean": state.clean,
        },
        "controlled_environment": dict(CONTROLLED_ENVIRONMENT),
        "tool_versions": dict(sorted(recorded_versions.items())),
        "required_commands": list(REQUIRED_COMMANDS),
        "commands": command_records,
        "overall_pass": overall_pass,
    }
    output.write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return receipt


def load_receipt(path: Path) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ReceiptError(f"cannot read release-check receipt: {error}") from error
    if not isinstance(value, dict):
        raise ReceiptError("release-check receipt root must be an object")
    return value


def verify_receipt(
    root: Path,
    path: Path,
    *,
    state: RepositoryState | None = None,
) -> ReceiptReport:
    errors: list[str] = []
    try:
        path = _receipt_output(root, path)
        receipt = load_receipt(path)
    except ReceiptError as error:
        return ReceiptReport(command_count=0, overall_pass=False, errors=(str(error),))
    expected_keys = {
        "schema_version",
        "claim_boundary",
        "repository",
        "controlled_environment",
        "tool_versions",
        "required_commands",
        "commands",
        "overall_pass",
    }
    if set(receipt) != expected_keys:
        errors.append("release-check receipt keys differ from schema")
    schema_version = receipt.get("schema_version")
    if type(schema_version) is not int or schema_version != 1:
        errors.append("release-check receipt schema_version must be 1")
    if receipt.get("claim_boundary") != CLAIM_BOUNDARY:
        errors.append("release-check receipt claim boundary differs")
    if receipt.get("controlled_environment") != CONTROLLED_ENVIRONMENT:
        errors.append("release-check controlled environment differs")
    versions = receipt.get("tool_versions")
    if (
        not isinstance(versions, dict)
        or set(versions) != REQUIRED_TOOL_NAMES
        or not all(
            isinstance(version, str) and version.strip()
            for version in versions.values()
        )
        or any(
            version.startswith(("UNAVAILABLE:", "AVAILABLE:"))
            for version in versions.values()
        )
    ):
        errors.append("release-check tool-version record is invalid")
    if receipt.get("required_commands") != list(REQUIRED_COMMANDS):
        errors.append("release-check required command list differs")

    try:
        current_state = state if state is not None else repository_state(root)
    except ReceiptError as error:
        errors.append(str(error))
        current_state = RepositoryState(commit="", tree="", clean=False)
    repository = receipt.get("repository")
    expected_repository = {
        "commit": current_state.commit,
        "tree": current_state.tree,
        "clean": True,
    }
    if repository != expected_repository:
        errors.append("receipt does not match the current clean Git revision")
    if not current_state.clean:
        errors.append("current Git candidate tree is dirty")

    commands = receipt.get("commands")
    if not isinstance(commands, list):
        errors.append("release-check commands must be a list")
        commands = []
    if len(commands) != len(REQUIRED_COMMANDS):
        errors.append("release-check command count differs")
    observed_passes: list[bool] = []
    for index, expected_command in enumerate(REQUIRED_COMMANDS, start=1):
        if index > len(commands):
            break
        record = commands[index - 1]
        if not isinstance(record, dict):
            errors.append(f"release-check command {index} must be an object")
            continue
        target = _command_argv(expected_command)[1]
        expected_log = f"{index:02d}-{target}.log"
        expected_record_keys = {
            "command",
            "argv",
            "result",
            "return_code",
            "log_path",
            "log_sha256",
        }
        if set(record) != expected_record_keys:
            errors.append(f"release-check command {index} keys differ from schema")
        if record.get("command") != expected_command:
            errors.append(f"release-check command {index} differs")
        if record.get("argv") != list(_command_argv(expected_command)):
            errors.append(f"release-check argv {index} differs")
        return_code = record.get("return_code")
        result = record.get("result")
        valid_return_code = type(return_code) is int
        if not valid_return_code:
            errors.append(f"release-check return code {index} must be an integer")
        if result not in {"PASS", "FAIL"}:
            errors.append(f"release-check result {index} is invalid")
        passed = valid_return_code and return_code == 0 and result == "PASS"
        observed_passes.append(passed)
        if valid_return_code and (return_code == 0) != (result == "PASS"):
            errors.append(f"release-check result {index} contradicts return code")
        if not passed:
            errors.append(f"release-check command failed: {expected_command}")
        if record.get("log_path") != expected_log:
            errors.append(f"release-check log path {index} differs")
            continue
        log_path = path.parent / expected_log
        try:
            digest = _log_digest(log_path.read_bytes())
        except OSError as error:
            errors.append(f"cannot read release-check log {expected_log}: {error}")
            continue
        if record.get("log_sha256") != digest:
            errors.append(f"release-check log hash differs: {expected_log}")
    overall_pass = receipt.get("overall_pass")
    expected_pass = (
        len(observed_passes) == len(REQUIRED_COMMANDS) and all(observed_passes)
    )
    if type(overall_pass) is not bool or overall_pass != expected_pass:
        errors.append("release-check overall_pass contradicts command results")
    return ReceiptReport(
        command_count=len(commands),
        overall_pass=overall_pass is True,
        errors=tuple(errors),
    )


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help="receipt path below build/release-evidence",
    )
    parser.add_argument(
        "--verify",
        type=Path,
        help="verify an existing receipt instead of running commands",
    )
    return parser.parse_args()


def main() -> int:
    arguments = _arguments()
    if arguments.verify is not None:
        report = verify_receipt(REPOSITORY_ROOT, arguments.verify)
        for error in report.errors:
            print(f"ERROR: {error}", file=sys.stderr)
        if not report.passed:
            print(f"FAIL: current-scope receipt ({len(report.errors)} errors)")
            return 1
        print(
            f"PASS: current-scope receipt ({report.command_count} commands; "
            f"overall_pass={str(report.overall_pass).lower()})"
        )
        return 0
    try:
        output = _receipt_output(REPOSITORY_ROOT, arguments.output)
        receipt = write_receipt(REPOSITORY_ROOT, output)
    except ReceiptError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    if receipt["overall_pass"] is not True:
        print(f"FAIL: current-scope receipt written to {output}")
        return 1
    print(f"PASS: current-scope receipt written to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
