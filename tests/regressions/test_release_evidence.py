from __future__ import annotations

from contextlib import redirect_stdout
from copy import deepcopy
import io
import tempfile
from pathlib import Path
import unittest

from scripts.audit_release import REPOSITORY_ROOT, candidate_files
from scripts.check_release_evidence import (
    CHECKLIST_PATH,
    EvidenceReport,
    REQUIRED_CRITERIA,
    check_inventory,
    load_inventory,
    main,
)


class ReleaseEvidenceTests(unittest.TestCase):
    def _check(
        self,
        inventory: dict[str, object],
        checklist: Path = CHECKLIST_PATH,
    ) -> EvidenceReport:
        return check_inventory(
            REPOSITORY_ROOT,
            inventory,
            candidate_files(REPOSITORY_ROOT),
            checklist,
        )

    def test_current_inventory_is_complete_but_not_release_ready(self) -> None:
        report = self._check(load_inventory())
        self.assertTrue(report.passed, report.errors)
        self.assertEqual(report.criterion_count, len(REQUIRED_CRITERIA))
        self.assertFalse(report.release_ready)
        self.assertEqual(report.status_counts.get("RELEASE_QUALIFIED", 0), 0)
        self.assertGreater(report.status_counts.get("NOT_MET", 0), 0)
        self.assertGreater(report.status_counts.get("PARTIAL", 0), 0)

    def test_missing_criterion_and_stale_evidence_path_fail_closed(self) -> None:
        inventory = deepcopy(load_inventory())
        inventory["criteria"] = inventory["criteria"][1:]
        inventory["criteria"][0]["evidence_paths"] = ["missing/evidence.txt"]
        report = self._check(inventory)
        self.assertFalse(report.passed)
        self.assertTrue(
            any("criterion set differs" in error for error in report.errors)
        )
        self.assertTrue(any("missing evidence path" in error for error in report.errors))

    def test_unknown_command_and_blocker_fail_closed(self) -> None:
        inventory = deepcopy(load_inventory())
        inventory["criteria"][0]["verification_commands"] = ["make invented"]
        inventory["criteria"][0]["blockers"] = ["OQ-999"]
        report = self._check(inventory)
        self.assertFalse(report.passed)
        self.assertTrue(any("unknown command" in error for error in report.errors))
        self.assertTrue(any("unknown blocker" in error for error in report.errors))

    def test_release_ready_cannot_precede_qualification(self) -> None:
        inventory = deepcopy(load_inventory())
        inventory["release_ready"] = True
        report = self._check(inventory)
        self.assertFalse(report.passed)
        self.assertTrue(
            any(
                "release_ready must be true exactly" in error
                for error in report.errors
            )
        )

    def test_checklist_status_mismatch_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            checklist = Path(temporary_directory) / "release_checklist.md"
            checklist.write_text(
                CHECKLIST_PATH.read_text(encoding="utf-8").replace(
                    "| `clean_lint` |", "| `missing_row` |", 1
                ),
                encoding="utf-8",
            )
            report = self._check(load_inventory(), checklist)
            self.assertFalse(report.passed)
            self.assertTrue(any("checklist rows differ" in error for error in report.errors))

    def test_cli_is_deterministic_and_discloses_false_release_state(self) -> None:
        output = io.StringIO()
        with redirect_stdout(output):
            return_code = main()
        self.assertEqual(return_code, 0)
        text = output.getvalue()
        self.assertIn("PASS: release-evidence inventory", text)
        self.assertIn("release_ready=false", text)


if __name__ == "__main__":
    unittest.main()
