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
                    r"\[((?:ti|atari|amd|mame)-[a-z0-9-]+)"
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

    def test_hard_drivin_dac_mapping_remains_evidence_scoped(self) -> None:
        integration = (
            DOCS / "integration" / "hard_drivin_requirements.md"
        ).read_text(encoding="utf-8")
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        for required in (
            "`TD15` through `TD4` directly",
            "`B1` through `B12`",
            "`TD3:TD0` do not enter the converter",
            "There is no inverter",
            "`data[15:4]`",
            "`SC-019`/`OQ-020`",
        ):
            self.assertIn(required, integration)
        self.assertIn(
            "Hard Drivin' DAC direct wiring versus MAME MSB complement",
            conflicts,
        )
        self.assertIn("UNKNOWN for the intended signed PCM mapping", conflicts)

    def test_hard_drivin_program_decode_remains_evidence_scoped(self) -> None:
        integration = (
            DOCS / "integration" / "hard_drivin_requirements.md"
        ).read_text(encoding="utf-8")
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        for required in (
            "The drawing contains no mutual-exclusion arbiter",
            "invalid driver contention, not arbitration",
            "`/RAMEN = /MEN AND (/TWE OR PORT)`",
            "`0x000`–`0x007`",
            "electrically decoded exactly like OUT",
            "`SC-021`",
        ):
            self.assertIn(required, integration)
        self.assertIn("Physical reset-qualified RAM ownership", conflicts)
        self.assertIn("Low-address TBLW board alias", conflicts)

    def test_hard_drivin_shared_ram_adapter_remains_evidence_scoped(self) -> None:
        integration = (
            DOCS / "integration" / "hard_drivin_requirements.md"
        ).read_text(encoding="utf-8")
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        for required in (
            "do not enter this program-RAM control path",
            "Same-clock FPGA storage adaptation",
            "does not initialize or erase program words",
            "acknowledges neither side in the invalid overlap",
            "Quartus block-RAM mapping",
        ):
            self.assertIn(required, integration)
        self.assertIn("Physical whole-word program RAM", conflicts)
        self.assertIn("`OQ-022`", conflicts)

    def test_hard_drivin_mister_wrapper_remains_partial_and_physical(self) -> None:
        wrapper = (
            DOCS / "integration" / "hard_drivin_mister_wrapper.md"
        ).read_text(encoding="utf-8")
        for required in (
            "partial, same-clock FPGA top",
            "does not implement the 68000 bus",
            "needless FPGA divergence",
            "neither storage path is acknowledged",
            "Communication-RAM host sequence",
            "external `io_read_data_i` and `io_ready_i` are ignored",
            "A TBLW to address 0–7 arrives as `io_write_o`",
            "No Atari ROM data is used",
            "`0x3456` to `0x3459`",
            "2,290",
            "Cyclone V",
        ):
            self.assertIn(required, wrapper)

    def test_hard_drivin_communication_ram_remains_primary_scoped(self) -> None:
        communication = (
            DOCS / "integration" / "hard_drivin_communication_ram.md"
        ).read_text(encoding="utf-8")
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        for required in (
            "exposes 512 words",
            "When `CRAMEN=0`",
            "making the DSP path read-only",
            "after every completed input-port read",
            "No clear or board-reset input is drawn",
            "Port 3 is unresolved",
            "not a claimed control command",
            "hard_drivin_sound_communication_path",
            "loads every one of the 512 words",
            "now connected",
            "physical HM6116 timing",
        ):
            self.assertIn(required, communication)
        for required in (
            "SC-023 — CRAMEN ownership",
            "SC-024 — Global input-read address increment",
            "SC-025 — Physical whole-word communication RAM",
        ):
            self.assertIn(required, conflicts)

    def test_hard_drivin_sound_rom_mapping_remains_primary_scoped(self) -> None:
        sound_rom = (
            DOCS / "integration" / "hard_drivin_sound_rom.md"
        ).read_text(encoding="utf-8")
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        for required in (
            "not a serial shifter",
            "Blocks 12-15 therefore select no drawn ROM",
            "`TDI15` | `SD14`",
            "`0xc000`",
            "pre-increment `SA15:SA0`",
            "accept only authorized user-supplied data",
            "hard_drivin_sound_rom_path.sv",
            "65,536 pre-increment addresses",
            "is never acknowledged",
            "18 abstract combinational cells",
        ):
            self.assertIn(required, sound_rom)
        self.assertIn("SC-026 — Sound-ROM sign extension", conflicts)
        self.assertIn("| OQ-026 |", questions)


if __name__ == "__main__":
    unittest.main()
