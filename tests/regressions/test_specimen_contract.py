from __future__ import annotations

import ast
from hashlib import sha256
import json
from pathlib import Path
import tempfile
import unittest

from tools.trace.specimen_evidence import (
    SpecimenEvidence,
    validate_specimen_evidence,
)


ROOT = Path(__file__).resolve().parents[2]
CAPTURE_MODULES = (
    "push_pop_capture.py",
    "simultaneous_ar_capture.py",
    "lst_arp_capture.py",
    "subc_capture.py",
    "dint_interrupt_capture.py",
    "ram_boundary_capture.py",
    "ram_invalid_read_capture.py",
    "ram_invalid_write_capture.py",
    "reset_retention_capture.py",
)


def _hash(path: Path) -> str:
    return sha256(path.read_bytes()).hexdigest()


def _write_valid_package(root: Path) -> tuple[Path, Path, str]:
    capture = root / "normalized.csv"
    capture.write_text("synthetic normalized capture\n", encoding="utf-8")
    source = root / "fixture.asm"
    source.write_text("NOP\n", encoding="utf-8")
    listing = root / "fixture.lst"
    listing.write_text("000 7f80 synthetic:test\n", encoding="utf-8")
    photographs: dict[str, dict[str, str]] = {}
    for view in ("top", "bottom", "board_context"):
        photo = root / f"specimen-{view}.jpg"
        photo.write_bytes(f"synthetic {view}".encode("ascii"))
        photographs[view] = {"path": photo.name, "sha256": _hash(photo)}
    metadata = root / "metadata.json"
    metadata.write_text(
        json.dumps(
            {
                "device_marking": "TMS32010NL TEST\nTRACKING RAW\nLOT RAW",
                "specimen_id": "synthetic-specimen-01",
                "tracking_date_string": "TRACKING RAW",
                "lot_string": "LOT RAW",
                "package_type": "40-pin DIP",
                "acquisition_provenance": "synthetic regression fixture",
                "monitor_revision": "none",
                "specimen_scope": "this_specimen_only",
                "socketed": True,
                "temperature_c": 25.0,
                "program_memory_access_time_ns": 35.0,
                "reset_duration_cycles": 8,
                "normalized_capture_sha256": _hash(capture),
                "fixture_tool_versions": {
                    "assembler": "test assembler",
                    "capture_normalizer": "test normalizer",
                    "analyzer_decoder": "test decoder",
                },
                "fixture_artifacts": {
                    "source": {"path": source.name, "sha256": _hash(source)},
                    "listing": {"path": listing.name, "sha256": _hash(listing)},
                },
                "specimen_photographs": photographs,
            }
        ),
        encoding="utf-8",
    )
    return capture, metadata, _hash(source)


def _validate(
    root: Path,
    capture: Path,
    metadata: Path,
    source_hash: str,
) -> SpecimenEvidence:
    return validate_specimen_evidence(
        metadata,
        capture,
        root,
        fixture_source_sha256=source_hash,
        fixture_words={0: 0x7F80},
    )


class SpecimenContractTests(unittest.TestCase):
    def test_all_physical_classifiers_share_the_fail_closed_boundary(self) -> None:
        for filename in CAPTURE_MODULES:
            with self.subTest(filename=filename):
                path = ROOT / "tools" / "trace" / filename
                tree = ast.parse(path.read_text(encoding="utf-8"), filename=filename)
                calls_shared_validator = any(
                    isinstance(node, ast.Call)
                    and isinstance(node.func, ast.Name)
                    and node.func.id == "validate_specimen_evidence"
                    for node in ast.walk(tree)
                )
                keeps_acceptance_open = any(
                    isinstance(node, ast.keyword)
                    and node.arg == "acceptance_complete"
                    and isinstance(node.value, ast.Constant)
                    and node.value.value is False
                    for node in ast.walk(tree)
                )
                function_names = {
                    node.name
                    for node in ast.walk(tree)
                    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
                }
                self.assertTrue(calls_shared_validator)
                self.assertTrue(keeps_acceptance_open)
                self.assertNotIn("_validate_fixture_listing", function_names)

    def test_complete_shared_package_verifies_identity_and_five_artifacts(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            capture, metadata, source_hash = _write_valid_package(root)
            evidence = _validate(root, capture, metadata, source_hash)
            self.assertEqual(evidence.errors, ())
            self.assertEqual(evidence.specimen_id, "synthetic-specimen-01")
            self.assertEqual(evidence.specimen_scope, "this_specimen_only")
            self.assertEqual(
                set(evidence.verified_artifacts),
                {
                    "fixture.asm",
                    "fixture.lst",
                    "specimen-top.jpg",
                    "specimen-bottom.jpg",
                    "specimen-board_context.jpg",
                },
            )

    def test_identity_timing_and_tool_fields_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            capture, metadata, source_hash = _write_valid_package(root)
            value = json.loads(metadata.read_text(encoding="utf-8"))
            value.update(
                {
                    "device_marking": "TMS32010NL TEST",
                    "specimen_id": "",
                    "tracking_date_string": "OTHER TRACKING",
                    "lot_string": "",
                    "specimen_scope": "mask_wide",
                    "socketed": "yes",
                    "temperature_c": True,
                    "program_memory_access_time_ns": 0,
                    "reset_duration_cycles": 4,
                }
            )
            value["fixture_tool_versions"]["analyzer_decoder"] = ""
            metadata.write_text(json.dumps(value), encoding="utf-8")
            evidence = _validate(root, capture, metadata, source_hash)
            self.assertIsNone(evidence.specimen_id)
            self.assertEqual(evidence.specimen_scope, "UNQUALIFIED")
            for expected in (
                "metadata specimen_id must be a nonempty string",
                "metadata lot_string must be a nonempty string",
                "metadata device_marking must preserve multiple package lines",
                "metadata tracking_date_string is absent from device_marking",
                "metadata specimen_scope must be this_specimen_only",
                "metadata socketed must be a boolean",
                "metadata temperature_c must be a finite number",
                "metadata program_memory_access_time_ns must be a positive finite number",
                "metadata reset_duration_cycles must be an integer at least 5",
                "metadata fixture_tool_versions lacks analyzer_decoder",
            ):
                self.assertIn(expected, evidence.errors)

    def test_source_listing_and_normalized_trace_are_exact(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            capture, metadata, source_hash = _write_valid_package(root)
            value = json.loads(metadata.read_text(encoding="utf-8"))
            source = root / value["fixture_artifacts"]["source"]["path"]
            source.write_text("ZAC\n", encoding="utf-8")
            value["fixture_artifacts"]["source"]["sha256"] = _hash(source)
            listing = root / value["fixture_artifacts"]["listing"]["path"]
            listing.write_text("000 7f81 substitute\n", encoding="utf-8")
            value["fixture_artifacts"]["listing"]["sha256"] = _hash(listing)
            capture.write_text("substitute normalized capture\n", encoding="utf-8")
            metadata.write_text(json.dumps(value), encoding="utf-8")
            evidence = _validate(root, capture, metadata, source_hash)
            for expected in (
                "normalized capture SHA-256 mismatch",
                "fixture source is not the exact project-authored source",
                "fixture listing does not contain the exact address/word map",
            ):
                self.assertIn(expected, evidence.errors)

    def test_photograph_roles_are_distinct_complete_and_root_confined(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            capture, metadata, source_hash = _write_valid_package(root)
            value = json.loads(metadata.read_text(encoding="utf-8"))
            photos = value["specimen_photographs"]
            photos["bottom"] = dict(photos["top"])
            photos["board_context"] = {
                "path": "../outside.jpg",
                "sha256": "0" * 64,
            }
            metadata.write_text(json.dumps(value), encoding="utf-8")
            evidence = _validate(root, capture, metadata, source_hash)
            self.assertIn(
                "metadata specimen photograph paths must be distinct",
                evidence.errors,
            )
            self.assertTrue(
                any("escapes artifact_root" in error for error in evidence.errors)
            )


if __name__ == "__main__":
    unittest.main()
