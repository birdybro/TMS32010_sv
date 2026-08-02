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
    CaptureError,
    read_normalized_capture,
)
from tools.trace.subc_capture import (
    DEPENDENCY,
    DEPENDENCY_FINAL,
    DEPENDENCY_OLD,
    DEPENDENCY_TRIAL,
    DEPENDENCY_WORDS,
    OVERFLOW,
    OVERFLOW_EITHER,
    OVERFLOW_FINAL,
    OVERFLOW_INTERMEDIATE,
    OVERFLOW_NEITHER,
    OVERFLOW_WORDS,
    analyze_runs,
    build_report,
    main,
)


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


def _run_rows(
    run: str,
    experiment: str,
    first_output: int,
    second_output: int,
) -> list[str]:
    if experiment == DEPENDENCY:
        anchors = ((0x014, 0x4F03), (0x016, 0x4F04))
        trailing = ((0x017, 0x7F80), (0x018, 0xF900))
    elif experiment == OVERFLOW:
        anchors = ((0x01D, 0x4F00), (0x01F, 0x4F01))
        trailing = ((0x020, 0x7F80), (0x021, 0xF900))
    else:
        raise AssertionError(experiment)
    return [
        _edge(run, 0, *anchors[0]),
        _edge(run, 1, 7, first_output, men_n=1, we_n=0),
        _edge(run, 2, trailing[0][0], trailing[0][1]),
        _edge(run, 3, *anchors[1]),
        _edge(run, 4, 7, second_output, men_n=1, we_n=0),
        _edge(run, 5, *trailing[0]),
        _edge(run, 6, *trailing[1]),
    ]


def _capture_text(
    experiment: str,
    pairs: list[tuple[int, int]],
) -> str:
    rows = [",".join(CAPTURE_COLUMNS)]
    for index, (first, second) in enumerate(pairs):
        rows.extend(_run_rows(f"run-{index:02d}", experiment, first, second))
    return "\n".join(rows) + "\n"


def _binary(words: tuple[int, ...]) -> bytes:
    return b"".join(word.to_bytes(2, byteorder="big") for word in words)


class SubcCaptureTests(unittest.TestCase):
    def test_dependency_preserves_three_candidates_and_arbitrary_other(self) -> None:
        cases = (
            (0x0005, DEPENDENCY_OLD),
            (0x8005, DEPENDENCY_TRIAL),
            (0x000B, DEPENDENCY_FINAL),
            (0x1234, "OTHER_LOW_0x1234"),
        )
        for first, expected in cases:
            with self.subTest(first=first):
                runs = read_normalized_capture(
                    io.StringIO(_capture_text(DEPENDENCY, [(first, 0x000B)]))
                )
                observation = analyze_runs(DEPENDENCY, runs)[0]
                self.assertEqual(observation.classification, expected)
                self.assertTrue(observation.fixture_valid)
                self.assertFalse(observation.warnings)

    def test_dependency_legal_comparator_is_required_but_unknown_is_not(self) -> None:
        text = _capture_text(DEPENDENCY, [(0xCAFE, 0x000A)])
        observation = analyze_runs(
            DEPENDENCY,
            read_normalized_capture(io.StringIO(text)),
        )[0]
        self.assertEqual(observation.classification, "OTHER_LOW_0xcafe")
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(
            any(
                "legal NOP-separated comparator" in item
                for item in observation.warnings
            )
        )

    def test_all_four_overflow_stage_policies_use_status_bit_15(self) -> None:
        cases = (
            ((0xFEFE, 0x7EFE), OVERFLOW_INTERMEDIATE),
            ((0x7EFE, 0xFEFE), OVERFLOW_FINAL),
            ((0xFEFE, 0xFEFE), OVERFLOW_EITHER),
            ((0x7EFE, 0x7EFE), OVERFLOW_NEITHER),
        )
        for pair, expected in cases:
            with self.subTest(pair=pair):
                observation = analyze_runs(
                    OVERFLOW,
                    read_normalized_capture(
                        io.StringIO(_capture_text(OVERFLOW, [pair]))
                    ),
                )[0]
                self.assertEqual(observation.classification, expected)
                self.assertTrue(observation.fixture_valid)

        # Bit 12 is fixed high in every valid SST word; clearing it invalidates
        # the fixture instead of changing the bit-15 classification.
        observation = analyze_runs(
            OVERFLOW,
            read_normalized_capture(
                io.StringIO(_capture_text(OVERFLOW, [(0xEEFE, 0x7EFE)]))
            ),
        )[0]
        self.assertEqual(observation.classification, OVERFLOW_INTERMEDIATE)
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(
            any(
                "outside OV and reserved bit 1" in item
                for item in observation.warnings
            )
        )

    def test_capture_requires_exact_anchors_outputs_order_and_trailing_edges(self) -> None:
        good = _capture_text(DEPENDENCY, [(0x0005, 0x000B)])
        malformed = (
            good.replace("0x014,0x4f03", "0x014,0x4f02", 1),
            good.replace(
                "run-00,3,150,1,0,1,1,0x016,0x4f04",
                "run-00,3,150,1,1,1,1,0x016,0x4f04",
                1,
            ),
            "\n".join(good.splitlines()[:-2]) + "\n",
        )
        for text in malformed:
            with self.subTest(text=text):
                with self.assertRaises(CaptureError):
                    analyze_runs(
                        DEPENDENCY,
                        read_normalized_capture(io.StringIO(text)),
                    )

    def test_inconsistent_runs_and_bad_output_controls_are_not_review_ready(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            capture = Path(temporary_directory) / "capture.csv"
            capture.write_text(
                _capture_text(
                    DEPENDENCY,
                    [(0x0005, 0x000B), (0x8005, 0x000B)],
                ),
                encoding="utf-8",
            )
            report = build_report(capture, DEPENDENCY, minimum_runs=2)
            self.assertFalse(report.repeatable)
            self.assertTrue(report.fixture_valid)
            self.assertFalse(report.review_ready)

            capture.write_text(
                _capture_text(DEPENDENCY, [(0x0005, 0x000B)]).replace(
                    "run-00,1,50,1,1,0,1,0x007,0x0005",
                    "run-00,1,50,1,0,0,1,0x007,0x0005",
                ),
                encoding="utf-8",
            )
            report = build_report(capture, DEPENDENCY, minimum_runs=1)
            self.assertFalse(report.fixture_valid)
            self.assertFalse(report.review_ready)

    def test_complete_exact_package_is_review_ready_without_overclaim(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            capture = root / "normalized.csv"
            capture.write_text(
                _capture_text(OVERFLOW, [(0xFEFE, 0x7EFE)] * 32),
                encoding="utf-8",
            )
            image = root / "probe.bin"
            image.write_bytes(_binary(OVERFLOW_WORDS))
            raw = root / "capture.sal"
            raw.write_bytes(b"raw SUBC transition artifact")
            photograph = root / "probe.jpg"
            photograph.write_bytes(b"SUBC probe photograph fixture")
            metadata = root / "metadata.json"
            metadata.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "device_marking": "TMS32010NL TEST FIXTURE",
                        "board_revision": "synthetic test fixture",
                        "oscillator_hz": 20_000_000,
                        "supply_voltage_v": "5.00 measured",
                        "program_memory": "synthetic test memory",
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
                    },
                    indent=2,
                ),
                encoding="utf-8",
            )
            report = build_report(
                capture,
                OVERFLOW,
                metadata_path=metadata,
                program_image=image,
                artifact_root=root,
            )
            self.assertTrue(report.minimum_runs_met)
            self.assertTrue(report.repeatable)
            self.assertTrue(report.fixture_valid)
            self.assertTrue(report.evidence_package.complete)
            self.assertTrue(report.review_ready)
            self.assertEqual(set(report.classifications), {OVERFLOW_INTERMEDIATE})
            encoded = json.dumps(report.to_json_object(), sort_keys=True)
            self.assertIn("does not change OQ-017 or OQ-018", encoded)

            output = io.StringIO()
            with redirect_stdout(output):
                return_code = main(
                    (
                        str(capture),
                        "--experiment",
                        OVERFLOW,
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

            wrong_image = root / "wrong.bin"
            wrong_image.write_bytes(_binary(DEPENDENCY_WORDS))
            changed = json.loads(metadata.read_text(encoding="utf-8"))
            changed["program_image_sha256"] = sha256(
                wrong_image.read_bytes()
            ).hexdigest()
            metadata.write_text(json.dumps(changed), encoding="utf-8")
            wrong_report = build_report(
                capture,
                OVERFLOW,
                metadata_path=metadata,
                program_image=wrong_image,
                artifact_root=root,
            )
            self.assertFalse(wrong_report.evidence_package.complete)
            self.assertFalse(wrong_report.review_ready)
            self.assertIn(
                "program image is not the exact big-endian overflow fixture",
                wrong_report.evidence_package.errors,
            )


if __name__ == "__main__":
    unittest.main()
