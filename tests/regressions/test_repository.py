from __future__ import annotations

import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class RepositoryFoundationTests(unittest.TestCase):
    def test_license_is_mit_and_preserves_owner(self) -> None:
        license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
        self.assertTrue(license_text.startswith("MIT License\n"))
        self.assertIn("Copyright (c) 2026 Kevin Coleman", license_text)

    def test_reference_cache_and_build_outputs_are_ignored(self) -> None:
        probes = [
            "reference-cache/manual.pdf",
            "build/simulator/output.vcd",
            "artifacts/full_synthesis.log",
        ]
        result = subprocess.run(
            ["git", "check-ignore", "--stdin"],
            cwd=ROOT,
            input="\n".join(probes) + "\n",
            text=True,
            check=True,
            capture_output=True,
        )
        self.assertEqual(result.stdout.splitlines(), probes)

    def test_no_gated_clock_language_in_policy(self) -> None:
        agents = (ROOT / "AGENTS.md").read_text(encoding="utf-8").lower()
        self.assertRegex(agents, r"never create gated or logic-generated clocks")
        self.assertIn("clock enables", agents)

    def test_readme_discloses_incomplete_status(self) -> None:
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        self.assertRegex(
            readme,
            re.compile(r"not yet an\s+instruction-complete or cycle-accurate", re.I),
        )


if __name__ == "__main__":
    unittest.main()
