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

    def test_ti_patent_claim_boundary_is_explicit(self) -> None:
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        patent = next(
            source
            for source in manifest["sources"]
            if source["id"] == "ti-dsp-microcomputer-patent-us4577282a"
        )
        research = (
            DOCS / "research" / "ti_patent_us4577282a.md"
        ).read_text(encoding="utf-8")
        normalized_research = re.sub(r"\s+", " ", research)
        push_pop = (
            DOCS / "research" / "push_pop_bus_experiment.md"
        ).read_text(encoding="utf-8")
        ret_adr = (
            DOCS / "decisions" / "ADR-0003-computed-control-prefetch.md"
        ).read_text(encoding="utf-8")
        normalized_push_pop = re.sub(r"\s+", " ", push_pop)
        normalized_ret_adr = re.sub(r"\s+", " ", ret_adr)
        self.assertEqual(patent["authority_level"], 4)
        self.assertEqual(patent["status"], "acquired")
        self.assertFalse(patent["may_commit"])
        self.assertRegex(patent["sha256"], r"^[0-9a-f]{64}$")
        for required in (
            "not an original-TMS32010 production specification",
            "does not contain the production TMS32010 accumulator `PUSH` or `POP`",
            "no resolution of `OQ-016`",
        ):
            self.assertIn(required, normalized_research)
        self.assertIn("supplies no PUSH/POP address", normalized_push_pop)
        self.assertIn("CORROBORATED for RET", normalized_ret_adr)
        self.assertIn("INFERRED for CALA", normalized_ret_adr)

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
        memory = (
            DOCS / "architecture" / "memory_model.md"
        ).read_text(encoding="utf-8")
        pipeline = (
            DOCS / "architecture" / "pipeline.md"
        ).read_text(encoding="utf-8")
        ram_adr = (
            DOCS / "decisions" / "ADR-0004-phase-staged-internal-ram.md"
        ).read_text(encoding="utf-8")
        governance = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
        qualification = (
            ROOT / "synthesis" / "qualification.md"
        ).read_text(encoding="utf-8")
        rtl_boundary = (ROOT / "rtl" / "README.md").read_text(
            encoding="utf-8"
        )
        self.assertRegex(
            architecture,
            r"not yet a complete implementation\s+specification",
        )
        self.assertIn("partial RTL support only", architecture)
        self.assertIn("does not constitute", architecture)
        self.assertNotIn("cycle-accurate implementation", architecture.lower())
        for required in (
            "phase 1",
            "same-address forwarding",
            "global pause",
        ):
            self.assertIn(required, memory)
        for required in (
            "clock_enable_i",
            "arbitrary",
            "remain stable",
        ):
            self.assertIn(required, pipeline)
        self.assertIn("It does not raise confidence", ram_adr)
        self.assertIn("ADR-0004-phase-staged-internal-ram.md", governance)
        self.assertIn("not passing evidence", qualification)
        for required in (
            "data_addressed_o",
            "every caller must combine it with `valid_o`",
            "visits all 65,536 words",
            "core_program_data",
            "not an original TMS32010 register",
        ):
            self.assertIn(required, rtl_boundary)

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
            "board top now connects",
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
            "does not implement a raw-pin/CDC 68000 boundary",
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
            "Local-68000 memory callback boundary",
            "Upper-Y5 direct DSP I/O is deliberately distinct",
            "host_timing_partial_program_write_o",
            "host_timing_partial_communication_write_o",
            "use_internal_local_ram_i",
            "local_processor_halt_n_i",
            "local_processor_release_blocked_o",
            "8,192 clocks",
            "3,502",
            "405 checks",
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
            "2,966 abstract cells",
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
            "The separate `use_host_timing_i` option",
            "`/IRQCLR` remains distinct",
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
            "hard_drivin_sound_switches.sv",
            "`J3-11/J3-9/J3-8/J3-7` lane order",
            "all sixteen raw connector",
            "10 abstract cells",
            "six retained checks",
            "hard_drivin_sound_host_read_mux.sv",
            "`00` | `0001` | `/SOUNDRD`",
            "selecting\n`/SOUNDRD` does not clear `MAINFLAG`",
            "72 abstract cells",
            "13 retained checks",
        ):
            self.assertIn(required, host_reads)
        self.assertIn("SC-030 — Populated `/CPORT` host latch", conflicts)
        self.assertIn(
            "SC-033 — Rev-A `/320PORT`/`/SWITCHES` quadrants",
            conflicts,
        )
        self.assertIn("OQ-030", questions)
        self.assertIn("OQ-032", questions)

    def test_hard_drivin_host_timing_preserves_fixed_primary_sequence(self) -> None:
        host_timing = (
            DOCS / "integration" / "hard_drivin_host_timing.md"
        ).read_text(encoding="utf-8")
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        for required in (
            "`A22:A17` are not inputs",
            "both `/RVF` and `/RVAS`",
            "rising edge entering S4",
            "falling edge entering S7",
            "no READY input",
            "cannot reassert merely",
            "hard_drivin_sound_host_timing.sv",
            "8,192 complete",
            "142 abstract cells",
            "24 checks",
            "hard_drivin_sound_host_timing.sby",
            "16-step bounded check",
            "read/write covers reach step 8",
            "VPA cover\nreaches step 9",
            "Opt-in board-top composition",
            "host_timing_partial_sound_write_o",
            "hard_drivin_sound_host_routing.sby",
            "12-step bounded composition",
            "Seven covers span all six classes",
            "lower-Y5 program-RAM storage",
            "Y6 communication-RAM storage under CRAMEN",
            "optional lane-valid SRAM",
            "3,502 abstract cells",
            "405 checks",
        ):
            self.assertIn(required, host_timing)
        self.assertIn("OQ-033", questions)

    def test_hard_drivin_local_memory_preserves_physical_aliases(self) -> None:
        local_memory = (
            DOCS / "integration" / "hard_drivin_local_memory.md"
        ).read_text(encoding="utf-8")
        local_memory_flat = " ".join(local_memory.split())
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        for required in (
            "/ROMCE = A23 OR /AS",
            "physical 64 KiB image repeats",
            "`A22:A17` do not reach `30P`",
            "Y5 program/direct-I/O subdecode",
            "`0xff4000-0xff5fff`",
            "`0xff6000-0xff7fff`",
            "/RWS = RWN OR /RVAS",
            "131,072 combinations",
            "56 abstract combinational cells",
            "17 retained checks",
            "hard_drivin_sound_local_memory_bridge",
            "direct `/PWE` callback is sampled at the S6 rising boundary",
            "ROM-invalid",
            "305 abstract combinational hierarchy cells",
            "40 retained checks",
            "Optional lane-valid FPGA SRAM",
            "8,192-clock scrub",
            "hard_drivin_sound_local_ram",
            "88 cells",
            "nine checks",
            "six memories",
            "provide a 68000 core",
        ):
            self.assertIn(required, local_memory_flat)
        self.assertIn(
            "SC-034 — Physical local-68000 aliases", conflicts
        )
        self.assertIn("OQ-034", questions)

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
            "`hard_drivin_sound_mister` instantiates the standalone adapter",
            "both coincident write/read",
            "2,966 abstract cells",
            "257 retained\nchecks",
        ):
            self.assertIn(required, mailboxes)
        self.assertIn(
            "SC-031 — Physical whole-word mailboxes", conflicts
        )
        self.assertIn("OQ-031", questions)

    def test_hard_drivin_direct_io_preserves_asymmetric_decode(self) -> None:
        direct_io = (
            DOCS / "integration" / "hard_drivin_direct_io.md"
        ).read_text(encoding="utf-8")
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        for required in (
            "LS139 95K is enabled directly by `/PDEN`",
            "alias modulo four",
            "`RA11:RA3`",
            "no labeled connection",
            "no drawn data-source enable",
            "no READY input",
            "only `TD15`",
            "`offset & 7` for both reads and writes",
            "all 4,096 addresses in both directions",
            "direct_io_ownership_conflict_o",
        ):
            self.assertIn(required, direct_io)
        self.assertIn("LS139 95K instead ignores `RA11:RA2`", conflicts)
        self.assertIn("OQ-021", questions)
        self.assertIn("OQ-029", questions)
        self.assertIn("OQ-030", questions)

    def test_hard_drivin_local_reset_keeps_fpga_policy_separate(self) -> None:
        local_reset = (
            DOCS / "integration" / "hard_drivin_local_reset.md"
        ).read_text(encoding="utf-8")
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        for required in (
            "RESET pin 18",
            "HALT pin 17",
            "asserted together",
            "platform_release_permitted",
            "all 32 combinations",
            "8,192",
            "implementation convenience",
            "not physical-board behavior",
            "OQ-035",
        ):
            self.assertIn(required, local_reset)
        self.assertIn("OQ-035", questions)

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
