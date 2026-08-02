from __future__ import annotations

from contextlib import redirect_stdout
import io
from hashlib import sha256
import json
from pathlib import Path
import tempfile
import unittest

from tools.trace.lst_arp_capture import (
    ENCODED_WINS,
    FIXTURE_WORDS,
    MEMORY_WINS,
    MIXED_A_ENCODED,
    MIXED_A_MEMORY,
    OTHER_SEQUENCE,
    CaptureError,
    analyze_runs,
    build_report,
    main,
)
from tools.trace.push_pop_capture import CAPTURE_COLUMNS, read_normalized_capture


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


def _run_rows(run: str, sequence: tuple[int, int, int]) -> list[str]:
    return [
        _edge(run, 0, 0x011, 0x4F00),
        _edge(run, 1, 7, sequence[0], men_n=1, we_n=0),
        _edge(run, 2, 0x012, 0x7010),
        _edge(run, 3, 0x016, 0x4F88),
        _edge(run, 4, 7, sequence[1], men_n=1, we_n=0),
        _edge(run, 5, 0x017, 0x7022),
        _edge(run, 6, 0x01B, 0x4F88),
        _edge(run, 7, 7, sequence[2], men_n=1, we_n=0),
        _edge(run, 8, 0x01C, 0xF900),
        _edge(run, 9, 0x01D, 0x001C),
    ]


def _capture_text(sequences: list[tuple[int, int, int]]) -> str:
    rows = [",".join(CAPTURE_COLUMNS)]
    for index, sequence in enumerate(sequences):
        rows.extend(_run_rows(f"run-{index:02d}", sequence))
    return "\n".join(rows) + "\n"


def _binary() -> bytes:
    return b"".join(word.to_bytes(2, byteorder="big") for word in FIXTURE_WORDS)


class LstArpCaptureTests(unittest.TestCase):
    def test_both_precedence_and_both_mixed_results_are_distinguished(self) -> None:
        cases = (
            ((0x0033, 0x00A0, 0x00B1), MEMORY_WINS),
            ((0x0033, 0x00A1, 0x00B0), ENCODED_WINS),
            ((0x0033, 0x00A0, 0x00B0), MIXED_A_MEMORY),
            ((0x0033, 0x00A1, 0x00B1), MIXED_A_ENCODED),
        )
        for sequence, expected in cases:
            with self.subTest(sequence=sequence):
                observation = analyze_runs(
                    read_normalized_capture(
                        io.StringIO(_capture_text([sequence]))
                    )
                )[0]
                self.assertEqual(observation.classification, expected)
                self.assertEqual(observation.port_sequence, sequence)
                self.assertTrue(observation.fixture_valid)

    def test_unanticipated_sequence_is_preserved_and_nonresolving(self) -> None:
        sequence = (0x0033, 0x1234, 0x5678)
        with tempfile.TemporaryDirectory() as temporary_directory:
            capture = Path(temporary_directory) / "capture.csv"
            capture.write_text(_capture_text([sequence]), encoding="utf-8")
            report = build_report(capture, minimum_runs=1)
            self.assertEqual(
                report.classifications,
                (OTHER_SEQUENCE + "_0033_1234_5678",),
            )
            self.assertTrue(report.repeatable)
            self.assertFalse(report.candidate_resolved)
            self.assertFalse(report.review_ready)

    def test_mixed_results_are_repeatable_but_not_resolved_candidates(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            capture = Path(temporary_directory) / "capture.csv"
            capture.write_text(
                _capture_text([(0x0033, 0x00A0, 0x00B0)] * 2),
                encoding="utf-8",
            )
            report = build_report(capture, minimum_runs=2)
            self.assertTrue(report.repeatable)
            self.assertTrue(report.fixture_valid)
            self.assertFalse(report.candidate_resolved)
            self.assertFalse(report.review_ready)

    def test_exact_anchors_order_controls_marker_and_window_are_required(self) -> None:
        good = _capture_text([(0x0033, 0x00A0, 0x00B1)])
        malformed = (
            good.replace("0x016,0x4f88", "0x016,0x4f80", 1),
            good.replace(
                "run-00,6,300,1,0,1,1,0x01b,0x4f88",
                "run-00,6,300,1,1,1,1,0x01b,0x4f88",
                1,
            ),
            "\n".join(good.splitlines()[:-2]) + "\n",
        )
        for text in malformed:
            with self.subTest(text=text):
                with self.assertRaises(CaptureError):
                    analyze_runs(
                        read_normalized_capture(io.StringIO(text))
                    )

        bad_marker = good.replace("0x007,0x0033", "0x007,0x0032", 1)
        observation = analyze_runs(
            read_normalized_capture(io.StringIO(bad_marker))
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("armed marker" in item for item in observation.warnings))

        bad_control = good.replace(
            "run-00,4,200,1,1,0,1,0x007,0x00a0",
            "run-00,4,200,1,0,0,1,0x007,0x00a0",
        )
        observation = analyze_runs(
            read_normalized_capture(io.StringIO(bad_control))
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("exclusive" in item for item in observation.warnings))

    def test_complete_package_is_review_ready_without_confidence_promotion(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            capture = root / "normalized.csv"
            image = root / "probe.bin"
            raw = root / "capture.sal"
            photograph = root / "probe.jpg"
            capture.write_text(
                _capture_text([(0x0033, 0x00A1, 0x00B0)] * 32),
                encoding="utf-8",
            )
            image.write_bytes(_binary())
            raw.write_bytes(b"raw LST ARP capture")
            photograph.write_bytes(b"LST ARP probe photograph")
            metadata = root / "metadata.json"
            metadata.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "device_marking": "TMS32010NL TEST FIXTURE",
                        "board_revision": "synthetic test fixture",
                        "oscillator_hz": 20_000_000,
                        "supply_voltage_v": "5.00 measured",
                        "program_memory": "synthetic memory",
                        "probe_model": "synthetic probe",
                        "analyzer_model": "synthetic analyzer",
                        "analyzer_firmware": "test",
                        "program_image_sha256": sha256(image.read_bytes()).hexdigest(),
                        "signal_pin_map": {
                            "CLKOUT": "pin 6",
                            "MEN_N": "pin 7",
                            "WE_N": "pin 8",
                            "DEN_N": "pin 9",
                            "RS_N": "pin 10",
                            "A11:A0": "address bundle",
                            "D15:D0": "data bundle",
                        },
                        "raw_artifacts": {
                            raw.name: sha256(raw.read_bytes()).hexdigest(),
                        },
                        "probe_photographs": {
                            photograph.name: sha256(
                                photograph.read_bytes()
                            ).hexdigest(),
                        },
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
            self.assertTrue(report.minimum_runs_met)
            self.assertTrue(report.repeatable)
            self.assertTrue(report.candidate_resolved)
            self.assertTrue(report.fixture_valid)
            self.assertTrue(report.evidence_package.complete)
            self.assertTrue(report.review_ready)
            self.assertEqual(set(report.classifications), {ENCODED_WINS})
            encoded = json.dumps(report.to_json_object(), sort_keys=True)
            self.assertIn("does not change OQ-015", encoded)
            self.assertIn("choose between MAME and IKA", encoded)

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

            wrong = root / "wrong.bin"
            wrong.write_bytes(b"wrong fixture")
            changed = json.loads(metadata.read_text(encoding="utf-8"))
            changed["program_image_sha256"] = sha256(wrong.read_bytes()).hexdigest()
            metadata.write_text(json.dumps(changed), encoding="utf-8")
            wrong_report = build_report(
                capture,
                metadata_path=metadata,
                program_image=wrong,
                artifact_root=root,
            )
            self.assertFalse(wrong_report.evidence_package.complete)
            self.assertIn(
                "program image is not the exact big-endian LST-ARP fixture",
                wrong_report.evidence_package.errors,
            )

    def test_inconsistent_precedence_runs_are_not_review_ready(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            capture = Path(temporary_directory) / "capture.csv"
            capture.write_text(
                _capture_text(
                    [
                        (0x0033, 0x00A0, 0x00B1),
                        (0x0033, 0x00A1, 0x00B0),
                    ]
                ),
                encoding="utf-8",
            )
            report = build_report(capture, minimum_runs=2)
            self.assertFalse(report.repeatable)
            self.assertFalse(report.candidate_resolved)
            self.assertFalse(report.review_ready)


if __name__ == "__main__":
    unittest.main()
