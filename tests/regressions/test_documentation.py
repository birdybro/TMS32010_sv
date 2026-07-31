from __future__ import annotations

import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"


class ArchitectureDocumentationTests(unittest.TestCase):
    def test_every_manifest_citation_resolves(self) -> None:
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        source_ids = {source["id"] for source in manifest["sources"]}
        citation_ids: set[str] = set()
        for path in DOCS.rglob("*.md"):
            if path.parts[-2] == "references":
                continue
            text = path.read_text(encoding="utf-8")
            citation_ids.update(
                re.findall(
                    r"\[((?:ti|atari|mame)-[a-z0-9-]+)"
                    r"(?=,|\])",
                    text,
                )
            )
        self.assertTrue(citation_ids, "no source citations found")
        self.assertEqual(citation_ids - source_ids, set())

    def test_open_question_ids_are_unique_and_resolve(self) -> None:
        register = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        registered = re.findall(r"^\| (OQ-\d+) \|", register, re.MULTILINE)
        self.assertEqual(len(registered), len(set(registered)))
        referenced: set[str] = set()
        for path in DOCS.rglob("*.md"):
            referenced.update(
                re.findall(r"\bOQ-\d+\b", path.read_text(encoding="utf-8"))
            )
        self.assertEqual(referenced - set(registered), set())

    def test_architecture_docs_disclose_unqualified_state(self) -> None:
        architecture = (
            DOCS / "architecture" / "tms32010_architecture.md"
        ).read_text(encoding="utf-8")
        self.assertRegex(
            architecture,
            r"not yet a complete implementation\s+specification",
        )
        self.assertIn("partial RTL support only", architecture)
        self.assertIn("does not constitute", architecture)
        self.assertNotIn("cycle-accurate implementation", architecture.lower())

    def test_no_native_ready_protocol_is_claimed(self) -> None:
        interface = (
            DOCS / "architecture" / "external_interface.md"
        ).read_text(encoding="utf-8")
        self.assertIn("No documented READY pin", interface)
        self.assertIn("must not be described as original", interface)
        self.assertIn("48.78–150 ns", interface)
        self.assertIn("47.5–52.5%", interface)
        self.assertIn("195.12–600 ns", interface)
        self.assertIn("not arbitrary clock stretching", interface)

    def test_hard_drivin_int_and_bio_nets_remain_distinct(self) -> None:
        integration = (
            DOCS / "integration" / "hard_drivin_requirements.md"
        ).read_text(encoding="utf-8")
        for required in (
            "A044427 Rev A",
            "`PR1`",
            "`R26`, 1 kΩ",
            "`NOT LOADED`",
            "`/320BIO`",
            "`CLKOUT`",
            "`/BIOS`",
            "`320IRQ` is a different net",
        ):
            self.assertIn(required, integration)
        self.assertRegex(
            integration.lower(),
            r"does\s+not configure a dsp interrupt source",
        )
        self.assertIn("default the DSP interrupt input high", integration)
        self.assertIn("not pin-timing proof", integration)


if __name__ == "__main__":
    unittest.main()
