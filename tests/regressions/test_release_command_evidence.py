from __future__ import annotations

from copy import deepcopy
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

from scripts.run_release_checks import (
    CLAIM_BOUNDARY,
    CONTROLLED_ENVIRONMENT,
    REQUIRED_COMMANDS,
    ReceiptError,
    RepositoryState,
    load_receipt,
    verify_receipt,
    write_receipt,
)


CLEAN_STATE = RepositoryState(
    commit="1" * 40,
    tree="2" * 40,
    clean=True,
)
VERSIONS = {
    "git": "git version fixture",
    "make": "GNU Make fixture",
    "python": "Python fixture",
    "quartus": "Quartus fixture",
    "symbiyosys": "SymbiYosys fixture",
    "verilator": "Verilator fixture",
    "yosys": "Yosys fixture",
}


class FakeRunner:
    def __init__(self, failing_target: str | None = None) -> None:
        self.failing_target = failing_target
        self.calls: list[tuple[str, ...]] = []

    def __call__(
        self,
        argv: tuple[str, ...],
        root: Path,
        environment: dict[str, str],
    ) -> subprocess.CompletedProcess[bytes]:
        del root
        self.calls.append(tuple(argv))
        self.assert_environment(environment)
        failed = argv[1] == self.failing_target
        output = f"fixture output for {' '.join(argv)}\n".encode("ascii")
        return subprocess.CompletedProcess(argv, 1 if failed else 0, output)

    @staticmethod
    def assert_environment(environment: dict[str, str]) -> None:
        for name, value in CONTROLLED_ENVIRONMENT.items():
            if environment.get(name) != value:
                raise AssertionError(f"missing controlled environment {name}")


class ReleaseCommandEvidenceTests(unittest.TestCase):
    def _output(self, root: Path) -> Path:
        return root / "build" / "release-evidence" / "current" / "receipt.json"

    def test_clean_run_binds_every_command_log_to_revision(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = self._output(root)
            runner = FakeRunner()
            receipt = write_receipt(
                root,
                output,
                state=CLEAN_STATE,
                versions=VERSIONS,
                command_runner=runner,
                announce=False,
            )
            self.assertEqual(receipt["claim_boundary"], CLAIM_BOUNDARY)
            self.assertEqual(receipt["required_commands"], list(REQUIRED_COMMANDS))
            self.assertTrue(receipt["overall_pass"])
            self.assertEqual(len(runner.calls), len(REQUIRED_COMMANDS))
            report = verify_receipt(root, output, state=CLEAN_STATE)
            self.assertTrue(report.passed, report.errors)
            self.assertEqual(load_receipt(output), receipt)

    def test_dirty_tree_is_rejected_before_running_commands(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = self._output(root)
            runner = FakeRunner()
            with self.assertRaisesRegex(ReceiptError, "clean Git"):
                write_receipt(
                    root,
                    output,
                    state=RepositoryState("1" * 40, "2" * 40, False),
                    versions=VERSIONS,
                    command_runner=runner,
                    announce=False,
                )
            self.assertEqual(runner.calls, [])
            self.assertFalse(output.exists())

    def test_failure_is_preserved_and_remaining_commands_still_run(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = self._output(root)
            runner = FakeRunner(failing_target="formal")
            receipt = write_receipt(
                root,
                output,
                state=CLEAN_STATE,
                versions=VERSIONS,
                command_runner=runner,
                announce=False,
            )
            self.assertFalse(receipt["overall_pass"])
            self.assertEqual(len(runner.calls), len(REQUIRED_COMMANDS))
            report = verify_receipt(root, output, state=CLEAN_STATE)
            self.assertFalse(report.passed)
            self.assertTrue(
                any("make formal" in error for error in report.errors)
            )

    def test_log_tamper_and_revision_change_fail_verification(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = self._output(root)
            write_receipt(
                root,
                output,
                state=CLEAN_STATE,
                versions=VERSIONS,
                command_runner=FakeRunner(),
                announce=False,
            )
            (output.parent / "01-audit-release.log").write_text(
                "tampered\n", encoding="utf-8"
            )
            changed_state = RepositoryState("3" * 40, "2" * 40, True)
            report = verify_receipt(root, output, state=changed_state)
            self.assertFalse(report.passed)
            self.assertTrue(any("log hash differs" in error for error in report.errors))
            self.assertTrue(
                any("current clean Git revision" in error for error in report.errors)
            )

    def test_command_schema_and_summary_cannot_be_rewritten(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = self._output(root)
            write_receipt(
                root,
                output,
                state=CLEAN_STATE,
                versions=VERSIONS,
                command_runner=FakeRunner(),
                announce=False,
            )
            receipt = deepcopy(load_receipt(output))
            receipt["required_commands"] = ["make test"]
            receipt["commands"][0]["command"] = "make clean"
            receipt["tool_versions"] = {"python": "rewritten"}
            receipt["overall_pass"] = False
            output.write_text(json.dumps(receipt), encoding="utf-8")
            report = verify_receipt(root, output, state=CLEAN_STATE)
            self.assertFalse(report.passed)
            self.assertTrue(any("command list differs" in error for error in report.errors))
            self.assertTrue(any("command 1 differs" in error for error in report.errors))
            self.assertTrue(
                any("tool-version record" in error for error in report.errors)
            )
            self.assertTrue(any("overall_pass" in error for error in report.errors))

    def test_receipt_output_is_confined_to_ignored_build_subtree(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaisesRegex(ReceiptError, "must stay below"):
                write_receipt(
                    root,
                    root / "artifacts" / "receipt.json",
                    state=CLEAN_STATE,
                    versions=VERSIONS,
                    command_runner=FakeRunner(),
                    announce=False,
                )

    def test_boolean_integer_substitution_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = self._output(root)
            write_receipt(
                root,
                output,
                state=CLEAN_STATE,
                versions=VERSIONS,
                command_runner=FakeRunner(),
                announce=False,
            )
            receipt = load_receipt(output)
            receipt["schema_version"] = True
            receipt["commands"][0]["return_code"] = False
            receipt["overall_pass"] = 1
            output.write_text(json.dumps(receipt), encoding="utf-8")
            report = verify_receipt(root, output, state=CLEAN_STATE)
            self.assertFalse(report.passed)
            self.assertTrue(any("schema_version" in error for error in report.errors))
            self.assertTrue(any("return code 1" in error for error in report.errors))
            self.assertTrue(any("overall_pass" in error for error in report.errors))

    def test_existing_log_symlink_is_rejected_before_commands(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = self._output(root)
            output.parent.mkdir(parents=True)
            outside = root / "outside.log"
            outside.write_text("preserve\n", encoding="utf-8")
            (output.parent / "01-audit-release.log").symlink_to(outside)
            runner = FakeRunner()
            with self.assertRaisesRegex(ReceiptError, "must not be symlinks"):
                write_receipt(
                    root,
                    output,
                    state=CLEAN_STATE,
                    versions=VERSIONS,
                    command_runner=runner,
                    announce=False,
                )
            self.assertEqual(runner.calls, [])
            self.assertEqual(outside.read_text(encoding="utf-8"), "preserve\n")


if __name__ == "__main__":
    unittest.main()
