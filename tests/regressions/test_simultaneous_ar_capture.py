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
from tools.trace.simultaneous_ar_capture import (
    DECREMENT_PRIORITY,
    FIXTURE_WORDS,
    INCREMENT_PRIORITY,
    NONCOMPLETION_AFTER_FIRST,
    NONCOMPLETION_AFTER_SECOND,
    NONCOMPLETION_BEFORE_SECOND,
    NO_NET_UPDATE,
    OTHER_SEQUENCE,
    analyze_runs,
    build_report,
    main,
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


def _run_rows(
    run: str,
    sequence: tuple[int, ...],
    *,
    second_forced: bool | None = None,
    second_before_first_result: bool = False,
) -> list[str]:
    if not 1 <= len(sequence) <= 3:
        raise AssertionError(sequence)
    if second_forced is None:
        second_forced = len(sequence) == 3
    events: list[tuple[int, int, int, int, int]] = [
        (0x00A, 0x4F00, 0, 1, 1),
        (7, sequence[0], 1, 0, 1),
        (0x00D, 0x68B8, 0, 1, 1),
    ]
    if second_forced and second_before_first_result:
        events.append((0x012, 0x68B8, 0, 1, 1))
    if len(sequence) >= 2:
        events.extend(
            (
                (0x00F, 0x4F20, 0, 1, 1),
                (7, sequence[1], 1, 0, 1),
            )
        )
    if second_forced and not second_before_first_result:
        events.append((0x012, 0x68B8, 0, 1, 1))
    if len(sequence) == 3:
        events.extend(
            (
                (0x014, 0x4F21, 0, 1, 1),
                (7, sequence[2], 1, 0, 1),
                (0x015, 0xF900, 0, 1, 1),
            )
        )
        trailing_count = 3
    else:
        trailing_count = 4
    events.extend((0x016, 0x0015, 0, 1, 1) for _ in range(trailing_count))
    return [
        _edge(
            run,
            sample,
            address,
            data,
            men_n=men_n,
            we_n=we_n,
            den_n=den_n,
        )
        for sample, (address, data, men_n, we_n, den_n) in enumerate(events)
    ]


def _capture_text(
    sequences: list[tuple[int, ...]],
    *,
    second_forced: bool | None = None,
) -> str:
    rows = [",".join(CAPTURE_COLUMNS)]
    for index, sequence in enumerate(sequences):
        rows.extend(
            _run_rows(
                f"run-{index:02d}",
                sequence,
                second_forced=second_forced,
            )
        )
    return "\n".join(rows) + "\n"


def _binary() -> bytes:
    return b"".join(word.to_bytes(2, byteorder="big") for word in FIXTURE_WORDS)


class SimultaneousArCaptureTests(unittest.TestCase):
    def test_three_complete_priority_candidates_are_distinguished(self) -> None:
        cases = (
            ((0x0033, 0x0000, 0x01FF), NO_NET_UPDATE),
            ((0x0033, 0x0001, 0x0000), INCREMENT_PRIORITY),
            ((0x0033, 0x01FF, 0x01FE), DECREMENT_PRIORITY),
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
                self.assertEqual(len(observation.output_samples), 3)
                self.assertTrue(observation.terminal_seen)
                self.assertTrue(observation.fixture_valid)

    def test_partial_noncompletion_observations_are_retained_but_unresolved(
        self,
    ) -> None:
        cases = (
            ((0x0033,), False, NONCOMPLETION_AFTER_FIRST),
            ((0x0033, 0x0000), False, NONCOMPLETION_BEFORE_SECOND),
            ((0x0033, 0x0000), True, NONCOMPLETION_AFTER_SECOND),
        )
        for sequence, second_forced, expected in cases:
            with self.subTest(expected=expected):
                with tempfile.TemporaryDirectory() as temporary_directory:
                    capture = Path(temporary_directory) / "capture.csv"
                    capture.write_text(
                        _capture_text(
                            [sequence] * 2,
                            second_forced=second_forced,
                        ),
                        encoding="utf-8",
                    )
                    report = build_report(capture, minimum_runs=2)
                    self.assertEqual(set(report.classifications), {expected})
                    self.assertTrue(report.repeatable)
                    self.assertTrue(report.fixture_valid)
                    self.assertFalse(report.candidate_resolved)
                    self.assertFalse(report.review_ready)

    def test_unanticipated_complete_sequence_is_preserved_and_nonresolving(
        self,
    ) -> None:
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
            self.assertTrue(report.fixture_valid)
            self.assertFalse(report.candidate_resolved)
            self.assertFalse(report.review_ready)

    def test_anchors_controls_order_marker_and_trailing_window_are_checked(
        self,
    ) -> None:
        sequence = (0x0033, 0x0000, 0x01FF)
        good = _capture_text([sequence])
        malformed = (
            good.replace("0x00a,0x4f00", "0x00a,0x4f01", 1),
            good.replace("0x00d,0x68b8", "0x00d,0x68b9", 1),
            "\n".join(good.splitlines()[:-1]) + "\n",
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
            "run-00,4,200,1,1,0,1,0x007,0x0000",
            "run-00,4,200,1,0,0,1,0x007,0x0000",
        )
        observation = analyze_runs(
            read_normalized_capture(io.StringIO(bad_control))
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("exclusive" in item for item in observation.warnings))

        rows = [",".join(CAPTURE_COLUMNS)]
        rows.extend(
            _run_rows(
                "run-00",
                sequence,
                second_before_first_result=True,
            )
        )
        observation = analyze_runs(
            read_normalized_capture(io.StringIO("\n".join(rows) + "\n"))
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(
            any("precedes the first result" in item for item in observation.warnings)
        )

    def test_complete_exact_package_is_review_ready_without_claim_promotion(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            capture = root / "normalized.csv"
            image = root / "probe.bin"
            raw = root / "capture.sal"
            photograph = root / "probe.jpg"
            capture.write_text(
                _capture_text([(0x0033, 0x0001, 0x0000)] * 32),
                encoding="utf-8",
            )
            image.write_bytes(_binary())
            raw.write_bytes(b"raw simultaneous-AR capture")
            photograph.write_bytes(b"simultaneous-AR probe photograph")
            fixture_source = root / "simultaneous_ar_update_probe.asm"
            fixture_source.write_bytes(
                (
                    ROOT / "tests" / "asm" / "simultaneous_ar_update_probe.asm"
                ).read_bytes()
            )
            fixture_listing = root / "simultaneous_ar_update_probe.lst"
            exact_listing = "".join(
                f"{address:03x} {word:04x} synthetic:test\n"
                for address, word in enumerate(FIXTURE_WORDS)
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
            metadata_object = {
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
                "program_memory": "synthetic memory",
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
                        "sha256": sha256(fixture_source.read_bytes()).hexdigest(),
                    },
                    "listing": {
                        "path": fixture_listing.name,
                        "sha256": sha256(fixture_listing.read_bytes()).hexdigest(),
                    },
                },
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
                    photograph.name: sha256(photograph.read_bytes()).hexdigest(),
                },
                "specimen_photographs": specimen_photos,
            }
            metadata.write_text(
                json.dumps(metadata_object, indent=2),
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
            self.assertFalse(report.acceptance_complete)
            self.assertEqual(report.specimen_id, "synthetic-specimen-01")
            self.assertEqual(report.specimen_scope, "this_specimen_only")
            self.assertEqual(set(report.classifications), {INCREMENT_PRIORITY})
            encoded = json.dumps(report.to_json_object(), sort_keys=True)
            self.assertIn("does not change OQ-010", encoded)
            self.assertIn("make 0x68b8 a supported instruction", encoded)
            self.assertIn("OQ-008 mask-revision invariance", encoded)
            self.assertIn('"output_samples"', encoded)

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

            image.write_bytes(b"\x00" + _binary()[1:])
            metadata_object["program_image_sha256"] = sha256(
                image.read_bytes()
            ).hexdigest()
            metadata.write_text(
                json.dumps(metadata_object, indent=2),
                encoding="utf-8",
            )
            wrong = build_report(
                capture,
                metadata_path=metadata,
                program_image=image,
                artifact_root=root,
            )
            self.assertFalse(wrong.evidence_package.complete)
            self.assertFalse(wrong.review_ready)
            self.assertTrue(
                any("exact big-endian" in item for item in wrong.evidence_package.errors)
            )

            image.write_bytes(_binary())
            fixture_listing.write_text("000 0000 unrelated\n", encoding="utf-8")
            metadata_object["program_image_sha256"] = sha256(
                image.read_bytes()
            ).hexdigest()
            metadata_object["fixture_artifacts"]["listing"]["sha256"] = sha256(
                fixture_listing.read_bytes()
            ).hexdigest()
            metadata.write_text(json.dumps(metadata_object), encoding="utf-8")
            wrong_listing = build_report(
                capture,
                metadata_path=metadata,
                program_image=image,
                artifact_root=root,
            )
            self.assertFalse(wrong_listing.review_ready)
            self.assertIn(
                "fixture listing does not contain the exact address/word map",
                wrong_listing.evidence_package.errors,
            )

            fixture_listing.write_text(exact_listing, encoding="utf-8")
            fixture_source.write_bytes(b"correctly hashed unrelated source")
            malformed_provenance = json.loads(json.dumps(metadata_object))
            malformed_provenance["normalized_capture_sha256"] = "0" * 64
            malformed_provenance["fixture_artifacts"]["source"]["sha256"] = sha256(
                fixture_source.read_bytes()
            ).hexdigest()
            malformed_provenance["fixture_artifacts"]["listing"]["sha256"] = sha256(
                fixture_listing.read_bytes()
            ).hexdigest()
            malformed_provenance["specimen_photographs"]["top"]["path"] = (
                "../escaped-top.jpg"
            )
            metadata.write_text(json.dumps(malformed_provenance), encoding="utf-8")
            malformed_report = build_report(
                capture,
                metadata_path=metadata,
                program_image=image,
                artifact_root=root,
            )
            self.assertFalse(malformed_report.review_ready)
            self.assertIn(
                "normalized capture SHA-256 mismatch",
                malformed_report.evidence_package.errors,
            )
            self.assertIn(
                "fixture source is not the exact project-authored source",
                malformed_report.evidence_package.errors,
            )
            self.assertTrue(
                any(
                    "escapes artifact_root" in error
                    for error in malformed_report.evidence_package.errors
                )
            )

    def test_inconsistent_candidate_runs_are_not_review_ready(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            capture = Path(temporary_directory) / "capture.csv"
            capture.write_text(
                _capture_text(
                    [
                        (0x0033, 0x0000, 0x01FF),
                        (0x0033, 0x0001, 0x0000),
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
