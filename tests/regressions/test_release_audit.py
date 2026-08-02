from __future__ import annotations

from copy import deepcopy
from hashlib import sha256
import io
from contextlib import redirect_stdout
import unittest

from scripts.audit_release import (
    POLICY_PATH,
    REPOSITORY_ROOT,
    audit_repository,
    candidate_files,
    load_policy,
    main,
)
from scripts.reference_manifest import load_manifest


class ReleaseAuditTests(unittest.TestCase):
    def test_candidate_tree_passes_the_committed_policy(self) -> None:
        report = audit_repository(
            REPOSITORY_ROOT,
            load_policy(POLICY_PATH),
            candidate_files(REPOSITORY_ROOT),
            load_manifest(),
        )
        self.assertTrue(report.passed, report.errors)
        self.assertEqual(report.generated_file_count, 1)
        self.assertEqual(report.canonical_data_file_count, 1)
        self.assertEqual(report.external_material_count, 0)
        self.assertEqual(report.binary_file_count, 0)
        self.assertEqual(report.noncommittable_reference_count, 59)

    def test_generated_and_canonical_inventory_must_be_complete(self) -> None:
        policy = deepcopy(load_policy(POLICY_PATH))
        policy["generated_files"] = []
        report = audit_repository(
            REPOSITORY_ROOT,
            policy,
            candidate_files(REPOSITORY_ROOT),
            load_manifest(),
        )
        self.assertFalse(report.passed)
        self.assertTrue(
            any("docs/generated policy differs" in error for error in report.errors)
        )

    def test_third_party_and_binary_allowlists_fail_closed(self) -> None:
        policy = deepcopy(load_policy(POLICY_PATH))
        policy["allowed_placeholder_paths"] = ["build/.gitkeep"]
        policy["binary_allowlist"] = [
            {
                "path": "LICENSE",
                "license": "MIT",
                "provenance": "invalid test record",
                "sha256": "0" * 64,
                "may_commit": True,
            }
        ]
        report = audit_repository(
            REPOSITORY_ROOT,
            policy,
            candidate_files(REPOSITORY_ROOT),
            load_manifest(),
        )
        self.assertFalse(report.passed)
        self.assertIn(
            "third-party material lacks a policy record: third_party/.gitkeep",
            report.errors,
        )
        self.assertTrue(
            any("binary allowlist contains nonbinary" in error for error in report.errors)
        )

    def test_noncommittable_reference_hash_cannot_enter_candidate_tree(self) -> None:
        manifest = deepcopy(load_manifest())
        manifest["sources"].append(
            {
                "id": "synthetic-prohibited-license-copy",
                "may_commit": False,
                "sha256": sha256(
                    (REPOSITORY_ROOT / "LICENSE").read_bytes()
                ).hexdigest(),
            }
        )
        report = audit_repository(
            REPOSITORY_ROOT,
            load_policy(POLICY_PATH),
            candidate_files(REPOSITORY_ROOT),
            manifest,
        )
        self.assertFalse(report.passed)
        self.assertIn(
            "candidate LICENSE matches noncommittable reference "
            "synthetic-prohibited-license-copy",
            report.errors,
        )

    def test_cli_output_is_deterministic_and_reports_no_release_claim(self) -> None:
        output = io.StringIO()
        with redirect_stdout(output):
            return_code = main()
        self.assertEqual(return_code, 0)
        text = output.getvalue()
        self.assertIn("PASS: tracked license/provenance audit", text)
        self.assertIn("0 external, 0 binary", text)

    def test_checklist_and_make_target_preserve_the_release_boundary(self) -> None:
        checklist = (REPOSITORY_ROOT / "docs" / "release_checklist.md").read_text(
            encoding="utf-8"
        )
        makefile = (REPOSITORY_ROOT / "Makefile").read_text(encoding="utf-8")
        self.assertIn("**NOT RELEASE READY.**", checklist)
        self.assertIn("make audit-release", checklist)
        self.assertIn("`make release-check` intentionally remains failing", checklist)
        self.assertIn("audit-release:", makefile)
        self.assertIn("$(PYTHON) scripts/audit_release.py", makefile)


if __name__ == "__main__":
    unittest.main()
