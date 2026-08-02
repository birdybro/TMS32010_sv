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

    def test_evm_breakpoint_clue_does_not_resolve_push_pop(self) -> None:
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        evm = next(
            source
            for source in manifest["sources"]
            if source["id"] == "ti-tms32010-evm-users-guide-spru005a"
        )
        research = re.sub(
            r"\s+",
            " ",
            (DOCS / "research" / "evm_breakpoint_evidence.md").read_text(
                encoding="utf-8"
            ),
        )
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        used_pages = " ".join(evm["sections_or_pages_used"])
        for required in (
            "printed page 3-58",
            "PDF page 99",
            "PDF pages 179-180",
            "PDF page 188",
        ):
            self.assertIn(required, used_pages)
        for required in (
            "breakpoint RAM is indexed by the TMS32010 program address",
            "does not reveal",
            "cannot choose `OQ-016` H1, H2, or H3",
            "no new native bus sequence",
        ):
            self.assertIn(required, research)
        self.assertIn("all three hypotheses survive", questions)

    def test_push_pop_capture_tool_preserves_physical_claim_boundary(self) -> None:
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        support = next(
            source
            for source in manifest["sources"]
            if source["id"] == "ti-development-support-spru011-1986"
        )
        experiment = re.sub(
            r"\s+",
            " ",
            (DOCS / "research" / "push_pop_bus_experiment.md").read_text(
                encoding="utf-8"
            ),
        )
        trace_readme = re.sub(
            r"\s+",
            " ",
            (ROOT / "tools" / "trace" / "README.md").read_text(encoding="utf-8"),
        )
        revision_audit = re.sub(
            r"\s+",
            " ",
            (DOCS / "research" / "device_revision_audit.md").read_text(
                encoding="utf-8"
            ),
        )
        used_pages = " ".join(support["sections_or_pages_used"])
        for required in (
            "every-traceable-machine-cycle BTT sampling",
            "Kontron TMS32010 clock-qualified external-fetch trace",
        ):
            self.assertIn(required, used_pages)
        for required in (
            "one CSV row per falling `CLKOUT` boundary",
            "refuses to merge an unknown sequence into H1-H3",
            "evidence-package status only",
            "exact 16-byte image",
            "OQ-008` specimen record",
            "through the shared validator",
            "numeric program-memory access time",
            "complete package verifies seven",
            "acceptance_complete=false",
        ):
            self.assertIn(required, experiment)
        for required in (
            "does not resolve `OQ-016`",
            "original raw transition file must be retained",
            "Path traversal",
            "normalized_capture_sha256",
            "program_memory_access_time_ns",
            "specimen_scope",
            "specimen_photographs",
            "same `specimen_evidence.py` validator",
            "exact 16-byte fixture",
            "acceptance_complete=false",
        ):
            self.assertIn(required, trace_readme)
        for required in (
            "single-specimen subset",
            "uses the reusable validator",
            "verifies seven artifacts",
            "this_specimen_only",
            "does not decode a TI mask",
        ):
            self.assertIn(required, revision_audit)

    def test_ti_simulator_evidence_stays_tool_scoped(self) -> None:
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        simulator = next(
            source
            for source in manifest["sources"]
            if source["id"] == "ti-tms32010-simulator-users-guide-1982"
        )
        research = re.sub(
            r"\s+",
            " ",
            (DOCS / "research" / "ti_simulator_trace_evidence.md").read_text(
                encoding="utf-8"
            ),
        )
        push_pop = re.sub(
            r"\s+",
            " ",
            (DOCS / "research" / "push_pop_bus_experiment.md").read_text(
                encoding="utf-8"
            ),
        )
        subc = re.sub(
            r"\s+",
            " ",
            (DOCS / "research" / "subc_pipeline_experiment.md").read_text(
                encoding="utf-8"
            ),
        )
        self.assertEqual(simulator["authority_level"], 3)
        self.assertEqual(simulator["status"], "acquired")
        self.assertFalse(simulator["may_commit"])
        self.assertRegex(simulator["sha256"], r"^[0-9a-f]{64}$")
        used_pages = " ".join(simulator["sections_or_pages_used"])
        for required in (
            "BIAQ instruction-acquisition and BPR program-ROM-read",
            "256-state trace buffer containing PC, accumulator, AR0, and AR1",
            "stop code 9950",
        ):
            self.assertIn(required, used_pages)
        for required in (
            "not a production-device data sheet",
            "no executable or source was acquired",
            "not the pin-level evidence required to choose",
            "leaving `OQ-017` unresolved",
        ):
            self.assertIn(required, research)
        self.assertIn("cannot select H1, H2, or H3", push_pop)
        self.assertIn("tool diagnostic rather than physical-device behavior", subc)

    def test_ram_boundary_evidence_stays_unresolved_and_reproducible(self) -> None:
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        patent = next(
            source
            for source in manifest["sources"]
            if source["id"] == "ti-dsp-microcomputer-patent-us4577282a"
        )
        evm = next(
            source
            for source in manifest["sources"]
            if source["id"] == "ti-tms32010-evm-users-guide-spru005a"
        )
        research = re.sub(
            r"\s+",
            " ",
            (DOCS / "research" / "ram_boundary_experiment.md").read_text(
                encoding="utf-8"
            ),
        )
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        memory = (
            DOCS / "architecture" / "memory_model.md"
        ).read_text(encoding="utf-8")
        trace_readme = (ROOT / "tools" / "trace" / "README.md").read_text(
            encoding="utf-8"
        )
        for required in (
            "patent columns 17-18 and 25-26",
            "PDF pages 35 and 39",
        ):
            self.assertIn(required, " ".join(patent["sections_or_pages_used"]))
        for required in ("0x00-0x5f", "PDF page 88"):
            self.assertIn(required, " ".join(evm["sections_or_pages_used"]))
        for required in (
            "cannot characterize every absent address",
            "does not resolve the last original-TMS32010 location",
            "The 145th port write is the observed `0x90` read and has no expected value",
            "Until a qualified capture or authoritative production source exists",
            "raw tracking/date and lot strings",
            "requires the DMOV/LTD sidecars to name the same",
        ):
            self.assertIn(required, research)
        self.assertIn("RESEARCHING/CONFLICT (`SC-038`)", questions)
        self.assertIn("## SC-038", conflicts)
        self.assertIn("PROVISIONAL safety policy", conflicts)
        self.assertIn("UNKNOWN outside that range", memory)
        for required in (
            "ram_boundary_capture.py",
            "register_observations_sha256",
            "acceptance_complete=false",
            "does not require\nrepeatable data",
            "exact project source and 26-word listing",
            "this_specimen_only",
        ):
            self.assertIn(required, trace_readme)
        self.assertIn("review_ready` is not acceptance completion", questions)
        self.assertIn("preserves all 144 valid words", conflicts)
        self.assertIn("identify the same\n  `OQ-008` specimen", conflicts)

    def test_absent_ram_decode_stays_unknown_and_probe_order_is_safe(self) -> None:
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        by_id = {source["id"]: source for source in manifest["sources"]}
        research = re.sub(
            r"\s+",
            " ",
            (DOCS / "research" / "ram_invalid_decode_experiment.md").read_text(
                encoding="utf-8"
            ),
        )
        questions = (DOCS / "research" / "open_questions.md").read_text(
            encoding="utf-8"
        )
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        memory = re.sub(
            r"\s+",
            " ",
            (DOCS / "architecture" / "memory_model.md").read_text(
                encoding="utf-8"
            ),
        )
        trace_readme = (ROOT / "tools" / "trace" / "README.md").read_text(
            encoding="utf-8"
        )
        family_pages = " ".join(
            by_id["ti-first-generation-users-guide-1987"]["sections_or_pages_used"]
        )
        mame_lines = " ".join(
            by_id["mame-tms320c1x-core-030fefc"]["sections_or_pages_used"]
        )
        ika_lines = " ".join(
            by_id["ika32010-rtl-51bc1f0"]["sections_or_pages_used"]
        )
        decap = by_id["caps0ff-tms320m10-decap-2020"]
        self.assertIn("Figure 3-5", family_pages)
        self.assertIn("TMS320C10 RAM map", mame_lines)
        self.assertIn("256-word internal RAM allocation", ika_lines)
        self.assertEqual(decap["status"], "unavailable")
        self.assertFalse(decap["download"]["enabled"])
        for required in (
            "Run it before either write probe",
            "repository assigns no passing expected absent-read value",
            "0xa06f` through `0xa000",
            "all 144 valid words",
            "at least 32 reset-and-execute trials",
            "at least 8 cold-power trials",
            "follow with a single-target probe",
            "cannot establish mask invariance",
            "exact project source and 35-word listing",
            "raw tracking/date and lot strings",
            "each exact source/43-word listing/normalized trace",
        ):
            self.assertIn(required, research)
        self.assertIn("RESEARCHING/CONFLICT (`SC-041`)", questions)
        self.assertIn("## SC-041", conflicts)
        self.assertIn("read-only controlled-history sweep", memory)
        for required in (
            "ram_invalid_read_capture.py",
            "PREDECESSOR_TRACKING",
            "run_conditions",
            "at\nleast 32 reset-and-execute trials and eight cold-power trials",
            "acceptance_complete=false",
            "specimen_evidence.py",
            "this_specimen_only",
            "ram_invalid_write_capture.py",
            "prior_read_report_sha256",
            "do\nnot independently prove",
            "defaults to one\ncomplete run per direction rather than inventing a count",
            "Ascending, descending, and the pinned stage-1",
        ):
            self.assertIn(required, trace_readme)
        self.assertIn("not overall acceptance or proof of physical chronology", questions)
        self.assertIn("strict stage-1 classifier", conflicts)
        self.assertIn("one named specimen", conflicts)
        self.assertIn("paired stage-2 normalizer", conflicts)
        self.assertIn("same specimen identity", conflicts)

    def test_reset_retention_keeps_evm_evidence_below_silicon_proof(self) -> None:
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        by_id = {source["id"]: source for source in manifest["sources"]}
        research = re.sub(
            r"\s+",
            " ",
            (DOCS / "research" / "reset_retention_experiment.md").read_text(
                encoding="utf-8"
            ),
        )
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        architecture = (
            DOCS / "architecture" / "tms32010_architecture.md"
        ).read_text(encoding="utf-8")
        trace_readme = re.sub(
            r"\s+",
            " ",
            (ROOT / "tools" / "trace" / "README.md").read_text(
                encoding="utf-8"
            ),
        )
        evm_pages = " ".join(
            by_id["ti-tms32010-evm-users-guide-spru005a"][
                "sections_or_pages_used"
            ]
        )
        patent_pages = " ".join(
            by_id["ti-dsp-microcomputer-patent-us4577282a"][
                "sections_or_pages_used"
            ]
        )
        for required in (
            "warm RESET saves all TMS32010 registers except PC",
            "PDF pages 68-69 and 97-98",
            "uncontrolled halt warning",
        ):
            self.assertIn(required, evm_pages)
        self.assertIn("explicitly assigned to a ROM reset routine", patent_pages)
        for required in (
            "No retained RAM flag or candidate register chooses the path",
            "post-reset vector therefore does not depend on internal-RAM retention",
            "Both directions are required",
            "at least 32 warm-reset trials per fixture",
            "coverage of all nine combinations",
            "post-reset vector is never compared with the project model",
            "dense 297-word address/word listing",
            "A complete package verifies seven",
            "`this_specimen_only` evidence scope",
            "acceptance_complete=false",
            "EVM evidence is **CORROBORATED** workflow evidence",
            "portable core's unlisted-state retention remains **PROVISIONAL**",
        ):
            self.assertIn(required, research)
        self.assertIn("## SC-042", conflicts)
        self.assertIn("strict paired normalizer", conflicts)
        self.assertIn("both packages to name the same raw marking", conflicts)
        self.assertIn("RESEARCHING/CORROBORATED EVM (`SC-042`)", questions)
        self.assertIn("without requiring retention", questions)
        self.assertIn("scope remains `this_specimen_only`", questions)
        self.assertIn("§2.11", architecture)
        for required in (
            "run,sample,time_ns,rs_n,bio_n,men_n,we_n,den_n,address,data",
            "run,rs_assert_ns,rs_release_ns,bio_assert_ns",
            "32 nominal runs per fixture",
            "A complete SET or CLEAR package verifies seven",
            "otherwise the report scope is `UNQUALIFIED`",
            "Variation and non-retention do not block review",
            "only OVM is an expected retention control",
        ):
            self.assertIn(required, trace_readme)
        for source_name in (
            "reset_retention_set_probe.asm",
            "reset_retention_clear_probe.asm",
        ):
            self.assertTrue((ROOT / "tests" / "asm" / source_name).is_file())
        self.assertTrue(
            (ROOT / "tools" / "trace" / "reset_retention_capture.py").is_file()
        )
        self.assertTrue(
            (ROOT / "tests" / "regressions" / "test_reset_retention_capture.py").is_file()
        )

    def test_device_revision_audit_separates_documents_from_silicon(self) -> None:
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        by_id = {source["id"]: source for source in manifest["sources"]}
        audit = re.sub(
            r"\s+",
            " ",
            (DOCS / "research" / "device_revision_audit.md").read_text(
                encoding="utf-8"
            ),
        )
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        architecture = re.sub(
            r"\s+",
            " ",
            (DOCS / "architecture" / "tms32010_architecture.md").read_text(
                encoding="utf-8"
            ),
        )
        for source_id in (
            "ti-tms32010-users-guide-1985-alt-scan",
            "ti-first-generation-users-guide-1989",
            "ti-development-support-spru011a-1989",
            "ti-ti32000-family-data-manual-1985-rejected",
        ):
            source = by_id[source_id]
            self.assertEqual(source["status"], "acquired")
            self.assertRegex(source["sha256"], r"^[0-9a-f]{64}$")
            self.assertFalse(source["may_commit"])
            self.assertTrue(source["sections_or_pages_used"])
        self.assertIn(
            "revised October 1985",
            " ".join(
                by_id["ti-tms32010-users-guide-1985-alt-scan"][
                    "sections_or_pages_used"
                ]
            ),
        )
        self.assertIn(
            "revised February 1986",
            " ".join(
                by_id["ti-tms32010-users-guide-spru001b"][
                    "sections_or_pages_used"
                ]
            ),
        )
        self.assertEqual(
            by_id["ti-ti32000-family-data-manual-1985-rejected"][
                "authority_level"
            ],
            8,
        )
        for required in (
            "No located Texas Instruments source identifies",
            "not be converted into a mask history",
            "A matching pair is not a mask map",
            "No RTL or model behavior changes solely because",
            "Negative search results mean only",
            "Tracking mark/date code and lot code",
            "unrelated 32-bit TI32000 family",
            "`OQ-010` simultaneous-AR workflow",
            "`OQ-015` LST-ARP workflow",
            "Both `OQ-017`/`OQ-018` SUBC workflows",
            "`OQ-019` DINT workflow",
            "paired `OQ-014` DMOV/LTD RAM-boundary workflow",
            "nondestructive `OQ-002` stage-1 absent-RAM read workflow",
            "paired destructive `OQ-002` stage-2 workflow",
            "paired `OQ-012` reset-retention workflow",
            "Each complete package verifies seven artifacts",
            "acceptance_complete=false",
        ):
            self.assertIn(required, audit)
        self.assertIn("## SC-043", conflicts)
        self.assertIn("RESEARCHING/NO REVISION MAP (`SC-043`)", questions)
        self.assertIn("none selects architectural RTL behavior", architecture)

    def test_subc_pipeline_evidence_stays_provisional_and_reproducible(self) -> None:
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        patent = next(
            source
            for source in manifest["sources"]
            if source["id"] == "ti-dsp-microcomputer-patent-us4577282a"
        )
        research = re.sub(
            r"\s+",
            " ",
            (DOCS / "research" / "subc_pipeline_experiment.md").read_text(
                encoding="utf-8"
            ),
        )
        trace_readme = re.sub(
            r"\s+",
            " ",
            (ROOT / "tools" / "trace" / "README.md").read_text(encoding="utf-8"),
        )
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        used_pages = " ".join(patent["sections_or_pages_used"])
        for required in (
            "patent columns 13-14 and 21-24",
            "PDF pages 33 and 37-38",
            "Figure 5c",
        ):
            self.assertIn(required, used_pages)
        for required in (
            "first word intentionally has no repository expected result",
            "intermediate-only OV stage remains **PROVISIONAL**",
            "**CORROBORATED RELATED-EMBODIMENT**",
            "cannot set `OV`",
            "final-stage hypothesis",
            "status bit 15 (`OV`)",
            "Status bit 12 is one of the fixed-one",
            "executes `LARP 0`",
            "none of these three values alone proves",
            "raw tracking/date and lot",
            "acceptance_complete` remains false",
        ):
            self.assertIn(required, research)
        for required in (
            "repeatable unanticipated value is evidence to retain",
            "does not change `OQ-017` or `OQ-018`",
            "stop code `9950` is not an expected physical result",
            "exact project source and complete listing",
            "acceptance_complete=false",
        ):
            self.assertIn(required, trace_readme)
        self.assertIn("RESEARCHING/CORROBORATED RELATED-EMBODIMENT", questions)
        self.assertIn("PROVISIONAL, NARROWED", questions)
        self.assertIn("## SC-010", conflicts)
        self.assertIn("physical probe", conflicts)
        self.assertIn("complete `OQ-008` record", conflicts)
        self.assertIn("named `OQ-008` specimen provenance", questions)

    def test_dint_race_preserves_ti_timing_conflict_and_physical_boundary(self) -> None:
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        by_id = {source["id"]: source for source in manifest["sources"]}
        original_pages = " ".join(
            by_id["ti-tms32010-users-guide-spru001b"]["sections_or_pages_used"]
        )
        assembly_pages = " ".join(
            by_id["ti-tms32010-assembly-guide-spru002b"]["sections_or_pages_used"]
        )
        family_pages = " ".join(
            by_id["ti-first-generation-users-guide-1987"]["sections_or_pages_used"]
        )
        research = re.sub(
            r"\s+",
            " ",
            (DOCS / "research" / "dint_interrupt_race_experiment.md").read_text(
                encoding="utf-8"
            ),
        )
        trace_readme = re.sub(
            r"\s+",
            " ",
            (ROOT / "tools" / "trace" / "README.md").read_text(encoding="utf-8"),
        )
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        interrupts = (
            DOCS / "architecture" / "interrupts.md"
        ).read_text(encoding="utf-8")
        for required in ("Appendix A.3.2", "PDF page 184"):
            self.assertIn(required, assembly_pages)
        for required in ("Section 2.14", "PDF page 48", "external CLKOUT-clocked"):
            self.assertIn(required, original_pages)
        for required in (
            "Figures 3-19 through 3-20",
            "PDF pages 60-63",
            "retained as a conflict",
        ):
            self.assertIn(required, family_pages)
        for required in (
            "The repository assigns no passing expected sequence",
            "MAME must not be cited as a same-boundary oracle",
            "0033, 001c, 0011, 0022",
            "entry-wins",
            "at least 32 resets",
            "external NMOS synchronizer requirement is corroborated",
            "internal polarity error",
            "normalizer must reject a run containing additional INT transitions",
            "unanticipated sequence is retained verbatim",
            "`review_ready` is evidence-package status only",
            "raw tracking/date and lot",
            "`acceptance_complete` remains false",
        ):
            self.assertIn(required, research)
        for required in (
            "never folded into a known candidate",
            "at least 50 ns setup",
            "at least one local `CLKOUT` period low",
            "does not change `OQ-019`",
            "no_pulse",
            "one_fetch_earlier",
            "one_fetch_later",
            "exact source and sparse listing",
            "acceptance_complete=false",
        ):
            self.assertIn(required, trace_readme)
        self.assertIn("## SC-039", conflicts)
        self.assertIn("complete `OQ-008` record", conflicts)
        self.assertIn("RESEARCHING/CONFLICT (`SC-039`)", questions)
        self.assertIn("one named `OQ-008` specimen", questions)
        self.assertIn("PARTIALLY RESOLVED_PRIMARY/CONFLICT (`SC-039`)", questions)
        self.assertNotIn("is synchronized internally", interrupts)
        self.assertIn("does not claim an analog synchronizer", interrupts)

    def test_lst_arp_conflict_preserves_both_hypotheses_and_hardware_boundary(
        self,
    ) -> None:
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        by_id = {source["id"]: source for source in manifest["sources"]}
        original_pages = " ".join(
            by_id["ti-tms32010-users-guide-spru001b"]["sections_or_pages_used"]
        )
        assembly_pages = " ".join(
            by_id["ti-tms32010-assembly-guide-spru002b"]["sections_or_pages_used"]
        )
        family_pages = " ".join(
            by_id["ti-first-generation-users-guide-1987"]["sections_or_pages_used"]
        )
        patent_pages = " ".join(
            by_id["ti-dsp-microcomputer-patent-us4577282a"][
                "sections_or_pages_used"
            ]
        )
        ika_lines = " ".join(
            by_id["ika32010-rtl-51bc1f0"]["sections_or_pages_used"]
        )
        research = re.sub(
            r"\s+",
            " ",
            (DOCS / "research" / "lst_arp_precedence_experiment.md").read_text(
                encoding="utf-8"
            ),
        )
        trace_readme = re.sub(
            r"\s+",
            " ",
            (ROOT / "tools" / "trace" / "README.md").read_text(encoding="utf-8"),
        )
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        questions = (DOCS / "research" / "open_questions.md").read_text(
            encoding="utf-8"
        )
        for pages in (original_pages, assembly_pages):
            self.assertIn("generic post-execution encoded-ARP rule", pages)
            self.assertIn("ambiguous LARP 0/LST *,1 result", pages)
        self.assertIn("ARP becomes one", family_pages)
        self.assertIn("does not order simultaneous", patent_pages)
        self.assertIn("encoded next-ARP wins only in indirect form", ika_lines)
        for required in (
            "The repository assigns no passing expected sequence",
            "0033, 00a0, 00b1",
            "0033, 00a1, 00b0",
            "at least 32 reset-and-execute trials",
            "MAME nor IKA may be cited as original-silicon proof",
            "status-restore prose and example admit opposing readings",
            "Both mixed-direction combinations and every other sequence are preserved",
            "cannot become resolved candidates",
            "raw tracking/date and lot",
            "acceptance_complete=false",
        ):
            self.assertIn(required, research)
        for required in (
            "without treating MAME's memory-word precedence",
            "Mixed outcomes are preserved as explicit classifications",
            "does not change `OQ-015`",
            "exact project source and 30-word listing",
            "program-memory access time",
            "acceptance_complete=false",
        ):
            self.assertIn(required, trace_readme)
        self.assertIn("## SC-009", conflicts)
        self.assertIn("literal example plus IKA", conflicts)
        self.assertIn("named\n  single-specimen provenance", conflicts)
        self.assertIn("RESEARCHING/CONFLICT (`SC-009`)", questions)
        self.assertIn("one named `OQ-008` specimen record", questions)

    def test_simultaneous_ar_update_stays_unsupported_and_hardware_unknown(
        self,
    ) -> None:
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        by_id = {source["id"]: source for source in manifest["sources"]}
        family_pages = " ".join(
            by_id["ti-first-generation-users-guide-1987"]["sections_or_pages_used"]
        )
        mame_core = " ".join(
            by_id["mame-tms320c1x-core-030fefc"]["sections_or_pages_used"]
        )
        mame_dasm = " ".join(
            by_id["mame-tms320c1x-disassembler-030fefc"][
                "sections_or_pages_used"
            ]
        )
        ika_lines = " ".join(
            by_id["ika32010-rtl-51bc1f0"]["sections_or_pages_used"]
        )
        patent_pages = " ".join(
            by_id["ti-dsp-microcomputer-patent-us4577282a"][
                "sections_or_pages_used"
            ]
        )
        research = re.sub(
            r"\s+",
            " ",
            (
                DOCS / "research" / "simultaneous_ar_update_experiment.md"
            ).read_text(encoding="utf-8"),
        )
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        questions = (DOCS / "research" / "open_questions.md").read_text(
            encoding="utf-8"
        )
        trace_readme = (ROOT / "tools" / "trace" / "README.md").read_text(
            encoding="utf-8"
        )
        self.assertIn("INC and DEC cannot both be one", family_pages)
        self.assertIn("UPDATE_AR() simultaneous-bit execution order", mame_core)
        self.assertIn("?? for simultaneous INC/DEC", mame_dasm)
        self.assertIn("simultaneous controls preserve the register", ika_lines)
        self.assertIn("does not define simultaneous assertion", patent_pages)
        for required in (
            "The repository assigns no passing expected sequence",
            "0033, 0000, 01ff",
            "0033, 0001, 0000",
            "0033, 01ff, 01fe",
            "at least 32 reset-and-execute trials",
            "fail-closed implementation policy",
            "not treated as the expected silicon answer",
            "raw tracking/date and lot",
            "acceptance_complete=false",
        ):
            self.assertIn(required, research)
        self.assertIn("## SC-040", conflicts)
        self.assertIn("candidate hypothesis", conflicts)
        self.assertIn("RESEARCHING/CONFLICT (`SC-040`)", questions)
        for required in (
            "simultaneous_ar_capture.py",
            "NONCOMPLETION_...",
            "candidate_resolved=false",
            "does not change\n`OQ-010`",
            "specimen_evidence.py",
            "program_memory_access_time_ns",
            "exact project source and 23-word listing",
            "acceptance_complete=false",
        ):
            self.assertIn(required, trace_readme)
        self.assertIn("three partial noncompletion stages", conflicts)
        self.assertIn("one named specimen", conflicts)
        self.assertIn("strict capture classifier", questions)
        self.assertIn("full `OQ-008` record", questions)

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
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        by_id = {source["id"]: source for source in manifest["sources"]}
        integration = (
            DOCS / "integration" / "hard_drivin_requirements.md"
        ).read_text(encoding="utf-8")
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        questions = (DOCS / "research" / "open_questions.md").read_text(
            encoding="utf-8"
        )
        audit = re.sub(
            r"\s+",
            " ",
            (DOCS / "research" / "hard_drivin_dac_code_audit.md").read_text(
                encoding="utf-8"
            ),
        )
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
            "`R12=1 kOhm` and `R13=4.7 kOhm`",
            "MAME's XOR is older than its hardware explanation",
            "tools/trace/hard_drivin_dac_codes.py",
        ):
            self.assertIn(required, integration)
        self.assertIn(
            "Hard Drivin' DAC direct wiring versus MAME MSB complement",
            conflicts,
        )
        self.assertIn("Secondary lineage", conflicts)
        self.assertIn("intended game PCM mapping", conflicts)
        self.assertIn("RESEARCHING/CONFLICT (`SC-019`)", questions)
        for source_id in (
            "historic-mame-harddriv-audio-062",
            "historic-mame-dac-core-062",
            "historic-mame-whatsnew-062",
            "mame-harddriv-audio-36944269",
        ):
            source = by_id[source_id]
            self.assertEqual(source["status"], "acquired")
            self.assertRegex(source["sha256"], r"^[0-9a-f]{64}$")
            self.assertFalse(source["may_commit"])
            self.assertTrue(source["sections_or_pages_used"])
        for required in (
            "positive-reference, single-ended current-to-voltage path",
            "not independent hardware corroboration",
            "MAME 0.62 introduction",
            "2016 AM6012 migration",
            "Negative search results mean only",
            "`320 DAC Ones`",
            "`75E` Q pin 19",
            "no RTL or model behavior changes",
        ):
            self.assertIn(required, audit)

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
        self.assertIn("Unqualified program RAM", conflicts)
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
            "reports an accepted byte transfer",
            "use_internal_local_ram_i",
            "local_processor_halt_n_i",
            "local_processor_release_blocked_o",
            "8,192 clocks",
            "3,767",
            "409 checks",
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
            "Original-MC68000 Table 3-1",
            "byte cycle writes `{byte, byte}`",
            "7-step",
            "both symbolic lane covers",
            "physical HM6116 timing",
        ):
            self.assertIn(required, communication)
        for required in (
            "SC-023 — CRAMEN ownership",
            "SC-024 — Global input-read address increment",
            "SC-025 — Unqualified communication RAM",
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

    def test_hard_drivin_j3_inputs_remain_unbiased_and_unnamed(self) -> None:
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        by_id = {source["id"]: source for source in manifest["sources"]}
        host_reads = (
            DOCS / "integration" / "hard_drivin_host_reads.md"
        ).read_text(encoding="utf-8")
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        audit = re.sub(
            r"\s+",
            " ",
            (DOCS / "research" / "hard_drivin_switch_input_audit.md").read_text(
                encoding="utf-8"
            ),
        )
        for source_id in (
            "atari-hard-drivin-compact-manual-tm329-second",
            "atari-race-drivin-compact-schematic-package-sp360",
            "atari-race-drivin-cockpit-manual-tm351-second",
        ):
            source = by_id[source_id]
            self.assertEqual(source["status"], "acquired")
            self.assertRegex(source["sha256"], r"^[0-9a-f]{64}$")
            self.assertFalse(source["may_commit"])
            self.assertTrue(source["sections_or_pages_used"])
        for required in (
            "no discrete DC pull-up or pull-down",
            "no J3 harness or cabinet switch",
            "source-valid nibble clear",
            "hard_drivin_switch_input_audit.md",
        ):
            self.assertIn(required, host_reads)
        self.assertIn("Cabinet cross-check", conflicts)
        self.assertIn("PARTIALLY RESOLVED_PRIMARY", questions)
        for required in (
            "does not assign cabinet functions",
            "A capacitor is open at DC",
            "no parameter that guarantees the result of an open input",
            "SP-327 sheet 1",
            "SP-360 sheet 1",
            "`A046491-02` Sound PCB Assembly",
            "MAME is not an idle-level oracle",
            "leave the four source-valid bits clear",
            "No RTL or model behavior changes",
        ):
            self.assertIn(required, audit)

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
            "lower-Y5 word plus normalized-byte program-RAM storage",
            "Y6 word plus normalized-byte communication-RAM storage under CRAMEN",
            "optional lane-valid SRAM",
            "3,767 abstract cells",
            "409 checks",
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

    def test_hard_drivin_program_rom_strap_remains_board_scoped(self) -> None:
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        by_id = {source["id"]: source for source in manifest["sources"]}
        source = by_id["amd-bipolar-mos-memories-databook-1986"]
        self.assertEqual(source["status"], "acquired")
        self.assertRegex(source["sha256"], r"^[0-9a-f]{64}$")
        self.assertFalse(source["may_commit"])
        self.assertTrue(source["sections_or_pages_used"])

        audit = " ".join(
            (DOCS / "research" / "hard_drivin_program_rom_strap_audit.md")
            .read_text(encoding="utf-8")
            .split()
        )
        local_memory = " ".join(
            (DOCS / "integration" / "hard_drivin_local_memory.md")
            .read_text(encoding="utf-8")
            .split()
        )
        questions = (
            DOCS / "research" / "open_questions.md"
        ).read_text(encoding="utf-8")
        conflicts = (
            DOCS / "research" / "source_conflicts.md"
        ).read_text(encoding="utf-8")
        for required in (
            "`E1` reaches `+5 V`",
            "`E2` reaches local-MC68000 `A16`",
            "fitting both links would short CPU `A16` to `+5 V`",
            "Race Drivin' Panorama prototype",
            "Distinct halves in either 64 KiB lane",
            "always leaves `physical_strap_proven` false",
            "prescribed Race Drivin' deluxe-cockpit field-upgrade configuration",
            "No RTL behavior changes",
        ):
            self.assertIn(required, audit)
        for required in (
            "E1 is required for the drawing's 27256 configuration",
            "With E2 and a 27512 pair",
            "legacy name",
            "hard_drivin_program_rom_strap_audit.md",
        ):
            self.assertIn(required, local_memory)
        self.assertIn("PARTIALLY_RESOLVED_PRIMARY (`SC-034`)", questions)
        self.assertIn("EPROM-option refinement", conflicts)

    def test_hard_drivin_mailboxes_preserve_reset_and_conflict_scope(self) -> None:
        mailboxes = (
            DOCS / "integration" / "hard_drivin_host_mailboxes.md"
        ).read_text(encoding="utf-8")
        byte_audit = (
            DOCS / "research" / "hard_drivin_mailbox_byte_audit.md"
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
            "preset dominates the clock while",
            "`0x840000..0x843fff`",
            "`/EWEU` or `/EWEL`",
            "`{2{D15:D8}}`",
            "`{2{D7:D0}}`",
            "current implementation",
            "hard_drivin_mc68000_write_word.sv",
            "accepted byte write",
            "all 65,536 words in both directions",
            "Ten retained RTL checks",
            "`hard_drivin_sound_mister` instantiates the standalone adapter",
            "both coincident write/read",
            "3,767 abstract cells",
            "409 retained\nchecks",
        ):
            self.assertIn(required, mailboxes)
        for required in (
            "LS138 `20P`",
            "Y0",
            "`/EWEU` and `/EWEL`",
            "`{byte, byte}`",
            "current implementation",
            "read edge at write-preset release",
            "all 65,536 data words",
            "39 mapped cells",
        ):
            self.assertIn(required, byte_audit)
        self.assertIn(
            "SC-031 — Physical whole-word mailboxes", conflicts
        )
        self.assertIn("PARTIALLY_RESOLVED_PRIMARY (`SC-031`)", questions)

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
        manifest = json.loads(
            (DOCS / "references" / "manifest.yaml").read_text(encoding="utf-8")
        )
        tm356 = next(
            source
            for source in manifest["sources"]
            if source["id"] == "atari-race-drivin-upgrade-kit-tm356-first"
        )
        sound_rom = (
            DOCS / "integration" / "hard_drivin_sound_rom.md"
        ).read_text(encoding="utf-8")
        population = re.sub(
            r"\s+",
            " ",
            (
                DOCS / "research" / "hard_drivin_sample_rom_population_audit.md"
            ).read_text(encoding="utf-8"),
        )
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
            "physical `45C` is block 8",
        ):
            self.assertIn(required, sound_rom)
        self.assertIn("SC-026 — Sound-ROM sign extension", conflicts)
        self.assertIn(
            "SC-044 — Physical sample-ROM block 8 versus packed MAME block 4",
            conflicts,
        )
        self.assertIn("PARTIALLY_RESOLVED_PRIMARY (`SC-044`)", questions)
        self.assertEqual(tm356["publication_number"], "TM-356")
        self.assertEqual(tm356["status"], "acquired")
        self.assertFalse(tm356["may_commit"])
        self.assertRegex(tm356["sha256"], r"^[0-9a-f]{64}$")
        for required in (
            "new Race Drivin' sample `136077-1017` is installed at `45C`",
            "MAME offset `0x40000` is logical block 4",
            "`physical_population_proven` false",
            "No open-bus value is established",
        ):
            self.assertIn(required, population)


if __name__ == "__main__":
    unittest.main()
