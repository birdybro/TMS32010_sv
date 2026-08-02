from __future__ import annotations

from contextlib import redirect_stdout
import io
from hashlib import sha256
import json
from pathlib import Path
import tempfile
import unittest

from tools.trace.push_pop_capture import (
    CAPTURE_COLUMNS,
    FIXTURE_WORDS,
    H1_IDLE,
    H2_REPEAT,
    H3_ADVANCE,
    UNCLASSIFIED,
    CaptureError,
    analyze_runs,
    build_report,
    main,
    read_normalized_capture,
)


ROOT = Path(__file__).resolve().parents[2]


def _edge(
    run: str,
    sample: int,
    address: int,
    data: int,
    *,
    men_n: int = 0,
    we_n: int = 1,
    den_n: int = 1,
) -> str:
    return ",".join(
        (
            run,
            str(sample),
            str(sample * 50),
            "1",
            str(men_n),
            str(we_n),
            str(den_n),
            f"0x{address:03x}",
            f"0x{data:04x}",
        )
    )


def _run_rows(run: str, hypothesis: str) -> list[str]:
    if hypothesis == H1_IDLE:
        push_intervals = (
            _edge(run, 2, 0x002, 0x7F80, men_n=1),
            _edge(run, 3, 0x002, 0x7F80),
        )
        pop_intervals = (
            _edge(run, 6, 0x005, 0x7F80, men_n=1),
            _edge(run, 7, 0x005, 0x7F80),
        )
    elif hypothesis == H2_REPEAT:
        push_intervals = (
            _edge(run, 2, 0x002, 0x7F80),
            _edge(run, 3, 0x002, 0x7F80),
        )
        pop_intervals = (
            _edge(run, 6, 0x005, 0x7F80),
            _edge(run, 7, 0x005, 0x7F80),
        )
    elif hypothesis == H3_ADVANCE:
        push_intervals = (
            _edge(run, 2, 0x002, 0x7F80),
            _edge(run, 3, 0x003, 0x7EAA),
        )
        pop_intervals = (
            _edge(run, 6, 0x005, 0x7F80),
            _edge(run, 7, 0x006, 0xF900),
        )
    else:
        raise AssertionError(hypothesis)
    return [
        _edge(run, 0, 0x000, 0x7E55),
        _edge(run, 1, 0x001, 0x7F9C),
        *push_intervals,
        _edge(run, 4, 0x003, 0x7EAA),
        _edge(run, 5, 0x004, 0x7F9D),
        *pop_intervals,
        _edge(run, 8, 0x006, 0xF900),
        _edge(run, 9, 0x007, 0x0006),
        _edge(run, 10, 0x006, 0xF900),
    ]


def _capture_text(hypotheses: list[str]) -> str:
    rows = [",".join(CAPTURE_COLUMNS)]
    for index, hypothesis in enumerate(hypotheses):
        rows.extend(_run_rows(f"run-{index:02d}", hypothesis))
    return "\n".join(rows) + "\n"


class PushPopCaptureTests(unittest.TestCase):
    def test_all_retained_hypotheses_are_distinguished_per_instruction(self) -> None:
        for hypothesis in (H1_IDLE, H2_REPEAT, H3_ADVANCE):
            with self.subTest(hypothesis=hypothesis):
                runs = read_normalized_capture(io.StringIO(_capture_text([hypothesis])))
                observations = analyze_runs(runs)
                self.assertEqual(len(observations), 2)
                self.assertEqual(
                    {observation.mnemonic for observation in observations},
                    {"PUSH", "POP"},
                )
                self.assertEqual(
                    {observation.classification for observation in observations},
                    {hypothesis},
                )
                if hypothesis == H1_IDLE:
                    for observation in observations:
                        self.assertTrue(
                            any(
                                "every-machine-cycle MEN rule" in warning
                                for warning in observation.warnings
                            )
                        )
                else:
                    self.assertTrue(
                        all(not observation.warnings for observation in observations)
                    )

    def test_wrong_fixture_data_or_external_strobe_cannot_match_a_hypothesis(self) -> None:
        text = _capture_text([H2_REPEAT]).replace(
            "run-00,2,100,1,0,1,1,0x002,0x7f80",
            "run-00,2,100,1,0,0,1,0x002,0x0000",
        )
        observations = analyze_runs(read_normalized_capture(io.StringIO(text)))
        push = next(
            observation
            for observation in observations
            if observation.mnemonic == "PUSH"
        )
        self.assertEqual(push.classification, UNCLASSIFIED)
        self.assertTrue(any("source conflict" in item for item in push.warnings))
        self.assertTrue(any("does not match fixture" in item for item in push.warnings))

    def test_parser_fails_closed_on_schema_and_sampling_errors(self) -> None:
        good = _capture_text([H2_REPEAT])
        malformed = (
            good.replace("time_ns,rs_n", "rs_n,time_ns", 1),
            good.replace("run-00,1,50", "run-00,1,0", 1),
            good.replace(",1,0,1,1,0x001", ",1,2,1,1,0x001", 1),
            good.replace("0x001,0x7f9c", "001,0x7f9c", 1),
        )
        for text in malformed:
            with self.subTest(text=text.splitlines()[0]):
                with self.assertRaises(CaptureError):
                    read_normalized_capture(io.StringIO(text))

    def test_capture_window_requires_unique_opcodes_and_four_trailing_edges(self) -> None:
        good = _capture_text([H2_REPEAT])
        duplicate = good.replace(
            "run-00,10,500,1,0,1,1,0x006,0xf900",
            "run-00,10,500,1,0,1,1,0x001,0x7f9c",
        )
        short = "\n".join(good.splitlines()[:-3]) + "\n"
        for text in (duplicate, short):
            with self.assertRaises(CaptureError):
                analyze_runs(read_normalized_capture(io.StringIO(text)))

    def test_complete_repeated_package_is_review_ready_without_overclaim(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            capture = root / "normalized.csv"
            capture.write_text(
                _capture_text([H2_REPEAT] * 32),
                encoding="utf-8",
            )
            image = root / "probe.bin"
            exact_image = b"".join(
                FIXTURE_WORDS[address].to_bytes(2, byteorder="big")
                for address in range(max(FIXTURE_WORDS) + 1)
            )
            image.write_bytes(exact_image)
            raw = root / "capture.sal"
            raw.write_bytes(b"raw transition artifact")
            photograph = root / "probe.jpg"
            photograph.write_bytes(b"probe photograph fixture")
            fixture_source = root / "push_pop_bus_probe.asm"
            fixture_source.write_bytes(
                (ROOT / "tests" / "asm" / "push_pop_bus_probe.asm").read_bytes()
            )
            fixture_listing = root / "push_pop_bus_probe.lst"
            exact_listing = "".join(
                f"{address:03x} {FIXTURE_WORDS[address]:04x} synthetic:test\n"
                for address in range(max(FIXTURE_WORDS) + 1)
            )
            fixture_listing.write_text(exact_listing, encoding="utf-8")
            specimen_photos = {}
            for view in ("top", "bottom", "board_context"):
                path = root / f"specimen-{view}.jpg"
                path.write_bytes(f"synthetic {view} specimen view".encode("ascii"))
                specimen_photos[view] = {
                    "path": path.name,
                    "sha256": sha256(path.read_bytes()).hexdigest(),
                }
            metadata = root / "metadata.json"
            metadata.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "device_marking": "TMS32010NL TEST\nTRACKING RAW\nLOT RAW",
                        "specimen_id": "synthetic-specimen-01",
                        "tracking_date_string": "TRACKING RAW",
                        "lot_string": "LOT RAW",
                        "package_type": "40-pin plastic DIP test fixture",
                        "acquisition_provenance": "synthetic regression fixture",
                        "socketed": True,
                        "temperature_c": 25.0,
                        "reset_duration_cycles": 8,
                        "monitor_revision": "none; standalone fixture",
                        "specimen_scope": "this_specimen_only",
                        "board_revision": "synthetic test fixture",
                        "oscillator_hz": 20_000_000,
                        "supply_voltage_v": "5.00 measured",
                        "program_memory": "synthetic test memory",
                        "program_memory_access_time_ns": 35.0,
                        "probe_model": "synthetic probe",
                        "analyzer_model": "synthetic analyzer",
                        "analyzer_firmware": "test",
                        "program_image_sha256": sha256(image.read_bytes()).hexdigest(),
                        "normalized_capture_sha256": sha256(
                            capture.read_bytes()
                        ).hexdigest(),
                        "fixture_tool_versions": {
                            "assembler": "project test assembler",
                            "capture_normalizer": "synthetic test normalizer",
                            "analyzer_decoder": "synthetic test decoder",
                        },
                        "fixture_artifacts": {
                            "source": {
                                "path": fixture_source.name,
                                "sha256": sha256(
                                    fixture_source.read_bytes()
                                ).hexdigest(),
                            },
                            "listing": {
                                "path": fixture_listing.name,
                                "sha256": sha256(
                                    fixture_listing.read_bytes()
                                ).hexdigest(),
                            },
                        },
                        "signal_pin_map": {
                            "CLKOUT": "pin 6",
                            "MEN_N": "pin 7",
                            "WE_N": "pin 8",
                            "DEN_N": "pin 9",
                            "RS_N": "pin 10",
                            "A11:A0": "test address bundle",
                            "D15:D0": "test data bundle",
                        },
                        "raw_artifacts": {
                            raw.name: sha256(raw.read_bytes()).hexdigest(),
                        },
                        "probe_photographs": {
                            photograph.name: sha256(
                                photograph.read_bytes()
                            ).hexdigest(),
                        },
                        "specimen_photographs": specimen_photos,
                    },
                    indent=2,
                ),
                encoding="utf-8",
            )
            report = build_report(
                capture,
                metadata_path=metadata,
                program_image=image,
                artifact_root=root,
            )
            self.assertEqual(report.run_count, 32)
            self.assertTrue(report.minimum_runs_met)
            self.assertTrue(report.repeatable)
            self.assertTrue(report.hypotheses_resolved)
            self.assertFalse(report.primary_source_conflict_observed)
            self.assertTrue(report.evidence_package.complete)
            self.assertTrue(report.review_ready)
            self.assertFalse(report.acceptance_complete)
            self.assertEqual(report.specimen_id, "synthetic-specimen-01")
            self.assertEqual(report.specimen_scope, "this_specimen_only")
            self.assertEqual(len(report.evidence_package.verified_artifacts), 7)
            self.assertEqual(set(report.classifications["PUSH"]), {H2_REPEAT})
            self.assertEqual(set(report.classifications["POP"]), {H2_REPEAT})
            encoded = json.dumps(report.to_json_object(), sort_keys=True)
            self.assertIn("does not change OQ-016", encoded)
            self.assertIn("OQ-008 mask-revision invariance", encoded)

            output = io.StringIO()
            with redirect_stdout(output):
                return_code = main(
                    (
                        str(capture),
                        "--metadata",
                        str(metadata),
                        "--program-image",
                        str(image),
                        "--artifact-root",
                        str(root),
                        "--require-review-ready",
                    )
                )
            self.assertEqual(return_code, 0)
            self.assertTrue(json.loads(output.getvalue())["review_ready"])

            valid_metadata = json.loads(metadata.read_text(encoding="utf-8"))
            image.write_bytes(b"\x00" + exact_image[1:])
            wrong_image_metadata = dict(valid_metadata)
            wrong_image_metadata["program_image_sha256"] = sha256(
                image.read_bytes()
            ).hexdigest()
            metadata.write_text(json.dumps(wrong_image_metadata), encoding="utf-8")
            wrong_image_report = build_report(
                capture,
                metadata_path=metadata,
                program_image=image,
                artifact_root=root,
            )
            self.assertFalse(wrong_image_report.review_ready)
            self.assertTrue(
                any(
                    "exact 16-byte" in error
                    for error in wrong_image_report.evidence_package.errors
                )
            )

            image.write_bytes(exact_image)
            fixture_listing.write_text("000 0000 unrelated\n", encoding="utf-8")
            wrong_listing_metadata = json.loads(json.dumps(valid_metadata))
            wrong_listing_metadata["fixture_artifacts"]["listing"]["sha256"] = sha256(
                fixture_listing.read_bytes()
            ).hexdigest()
            metadata.write_text(json.dumps(wrong_listing_metadata), encoding="utf-8")
            wrong_listing_report = build_report(
                capture,
                metadata_path=metadata,
                program_image=image,
                artifact_root=root,
            )
            self.assertFalse(wrong_listing_report.review_ready)
            self.assertIn(
                "fixture listing does not contain the exact address/word map",
                wrong_listing_report.evidence_package.errors,
            )

            fixture_listing.write_text(exact_listing, encoding="utf-8")
            incomplete_marking_metadata = dict(valid_metadata)
            incomplete_marking_metadata["device_marking"] = "TMS32010NL TEST"
            metadata.write_text(
                json.dumps(incomplete_marking_metadata), encoding="utf-8"
            )
            incomplete_marking_report = build_report(
                capture,
                metadata_path=metadata,
                program_image=image,
                artifact_root=root,
            )
            self.assertFalse(incomplete_marking_report.review_ready)
            self.assertIn(
                "metadata device_marking must preserve multiple package lines",
                incomplete_marking_report.evidence_package.errors,
            )
            self.assertIn(
                "metadata tracking_date_string is absent from device_marking",
                incomplete_marking_report.evidence_package.errors,
            )

            escaped = dict(valid_metadata)
            escaped["oscillator_hz"] = float("inf")
            escaped["program_memory_access_time_ns"] = 0
            escaped["raw_artifacts"] = {
                "../capture.sal": sha256(raw.read_bytes()).hexdigest(),
            }
            metadata.write_text(json.dumps(escaped), encoding="utf-8")
            escaped_report = build_report(
                capture,
                metadata_path=metadata,
                program_image=image,
                artifact_root=root,
            )
            self.assertFalse(escaped_report.evidence_package.complete)
            self.assertFalse(escaped_report.review_ready)
            self.assertIn(
                "metadata program_memory_access_time_ns must be a positive finite number",
                escaped_report.evidence_package.errors,
            )
            self.assertTrue(
                any(
                    "escapes artifact_root" in error
                    for error in escaped_report.evidence_package.errors
                )
            )
            self.assertIn(
                "metadata oscillator_hz must be a positive number",
                escaped_report.evidence_package.errors,
            )

    def test_mixed_runs_and_missing_provenance_are_not_review_ready(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            capture = Path(temporary_directory) / "mixed.csv"
            capture.write_text(
                _capture_text([H2_REPEAT, H3_ADVANCE]),
                encoding="utf-8",
            )
            report = build_report(capture, minimum_runs=2)
            self.assertFalse(report.repeatable)
            self.assertFalse(report.hypotheses_resolved)
            self.assertFalse(report.evidence_package.complete)
            self.assertFalse(report.review_ready)
            self.assertIn(
                "metadata sidecar was not supplied",
                report.evidence_package.errors,
            )
            self.assertIn(
                "metadata sidecar was not supplied for specimen validation",
                report.evidence_package.errors,
            )


if __name__ == "__main__":
    unittest.main()
