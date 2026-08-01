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

    def test_hard_drivin_read_status_preserves_masks_and_raw_polarity(self) -> None:
        host_reads = (
            DOCS / "integration" / "hard_drivin_host_reads.md"
        ).read_text(encoding="utf-8")
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        for required in (
            "hard_drivin_sound_read_status.sv",
            "fixed driven mask `16'hf000`",
            "`MAINFLAG`, `SOUNDFLAG`, `SOUND.TEST`, and `/TIRDY`",
            "all sixteen raw source nibbles",
            "23 abstract cells",
            "eight retained checks",
            "not yet connected",
        ):
            self.assertIn(required, host_reads)
        self.assertIn(
            "Live `/READSTAT` inputs versus fixed emulator constants",
            conflicts,
        )
        self.assertIn("see `OQ-030`", conflicts)

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
            "hard_drivin_sound_dac_latch.sv",
            "all 65,536 input words",
            "does not emit MAME's `0x723`",
            "14 cells, two retained checks",
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
            "does not implement the 68000 bus/address decoder",
            "needless FPGA divergence",
            "neither storage path is acknowledged",
            "Communication-RAM host sequence",
            "external `io_read_data_i` and `io_ready_i` are ignored",
            "A TBLW to address 0–7 arrives as `io_write_o`",
            "No Atari ROM data is used",
            "`0x3456` to `0x3459`",
            "Opt-in board BIO",
            "external active-low `bio_i` remains the default",
            "selected_bio_valid_o",
            "`use_host_control_i`",
            "per-bit validity",
            "`host_irq_clear_commit_i` callback",
            "`LACK 0x5a` and `NOP`",
            "2,495",
            "171 checks",
            "Cyclone V",
        ):
            self.assertIn(required, wrapper)

    def test_hard_drivin_output_control_remains_raw_and_evidence_scoped(self) -> None:
        control = (
            DOCS / "integration" / "hard_drivin_sound_control.md"
        ).read_text(encoding="utf-8")
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        for required in (
            "physical `MUTE` net (`/Q`)",
            "Only `TD0` participates",
            "`NOT LOADED`",
            "host_irq_clear_commit_i",
            "all 65,536 possible",
            "33 abstract cells",
            "four retained checks",
            "not electrical LS74 timing",
        ):
            self.assertIn(required, control)
        self.assertIn("SC-027", conflicts)
        self.assertIn("OQ-027", questions)

    def test_hard_drivin_bio_preserves_phase_and_clock_uncertainty(self) -> None:
        bio = (DOCS / "integration" / "hard_drivin_bio.md").read_text(
            encoding="utf-8"
        )
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        for required in (
            "counts `0xce` through `0xff`",
            "exact divide by 50",
            "reset neither loads `0xce`",
            "two crystals are independent",
            "noncoincident until",
            "separate validity bit",
            "all 256 explicitly invalid",
            "connected to `hard_drivin_sound_mister` as an explicit opt-in",
            "external platform-independent raw BIO input remains the default",
            "selected_bio_valid_o=0",
            "2,495 abstract cells",
            "52 cells",
            "seven retained checks",
        ):
            self.assertIn(required, bio)
        self.assertIn("SC-028", conflicts)
        self.assertIn("OQ-028", questions)

    def test_hard_drivin_compare_does_not_promote_mame_zero(self) -> None:
        compare = (DOCS / "integration" / "hard_drivin_compare.md").read_text(
            encoding="utf-8"
        )
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        for required in (
            "`/CMPRD`",
            "`CMPOUT`",
            "`TDI15`",
            "`TDI14:TDI0`",
            "`THIS SHEET NOT LOADED.`",
            "open-collector NPN",
            "zero is an emulator stub, not physical proof",
            "leaves port 2 on the explicit external",
            "No new RTL is warranted",
        ):
            self.assertIn(required, compare)
        self.assertIn("SC-029", conflicts)
        self.assertIn("OQ-029", questions)

    def test_hard_drivin_host_control_stays_callback_scoped(self) -> None:
        host = (DOCS / "integration" / "hard_drivin_host_control.md").read_text(
            encoding="utf-8"
        )
        host_flat = " ".join(host.split())
        for required in (
            "LS138 `30N`",
            "`RWN`, `A13`, and",
            "Host data `D15:D0` does not enter the latch",
            "`latch_address_i={A4,A3,A2,A1}`",
            "Q3 | `CRAMEN`",
            "Q4 | `/320RES`",
            "per-bit validity",
            "now instantiates the adapter behind `use_host_control_i`",
            "default false setting preserves external",
            "`/IRQCLR` remains the distinct",
            "53 abstract cells",
            "six retained checks",
            "not a Cyclone V fit",
        ):
            self.assertIn(required, host_flat)
        self.assertIn("`SC-020`", host_flat)

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
            "Port 3 is separate from communication RAM",
            "real latch transaction",
            "hard_drivin_sound_communication_path",
            "hard_drivin_sound_320_port_latch",
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

    def test_hard_drivin_host_reads_preserve_partial_lane_validity(self) -> None:
        host_reads = (
            DOCS / "integration" / "hard_drivin_host_reads.md"
        ).read_text(encoding="utf-8")
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        for required in (
            "`/SOUNDRD` | `D15:D0`",
            "`/320PORT` | `D15:D8`",
            "`/SWITCHES` | `D15:D12`",
            "`/READSTAT` | `D15:D12`",
            "LS374 `50L`",
            "host `D7:D0`",
            "driven-lane mask `16'hff00`",
            "valid-lane mask `16'hff00`",
            "all 65,536 TMS words",
            "low-address TBLW",
            "not a physical open-bus claim",
        ):
            self.assertIn(required, host_reads)
        self.assertIn("SC-030 — Populated `/CPORT` host latch", conflicts)
        self.assertIn("OQ-030", questions)

    def test_hard_drivin_mailboxes_preserve_reset_and_conflict_scope(self) -> None:
        mailboxes = (
            DOCS / "integration" / "hard_drivin_host_mailboxes.md"
        ).read_text(encoding="utf-8")
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        for required in (
            "LS374 `10L`/`10N`",
            "LS374 `20L`/`20N`",
            "LS74 `20S`",
            "Neither data-latch pair has a clear",
            "zero flag carrier with flag validity false",
            "whole-word only",
            "all 65,536 words in both directions",
            "Ten retained RTL checks",
            "not yet connected to\n`hard_drivin_sound_mister`",
        ):
            self.assertIn(required, mailboxes)
        self.assertIn(
            "SC-031 — Physical whole-word mailboxes", conflicts
        )
        self.assertIn("OQ-031", questions)

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
