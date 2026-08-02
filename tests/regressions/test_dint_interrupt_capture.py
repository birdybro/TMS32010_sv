from __future__ import annotations

from contextlib import redirect_stdout
import io
from hashlib import sha256
import json
from pathlib import Path
import tempfile
import unittest

from tools.trace.dint_interrupt_capture import (
    CANCELS_ENTRY,
    CAPTURE_COLUMNS,
    ENTRY_STACKS_N_PLUS_1,
    ENTRY_STACKS_N_PLUS_2,
    FIXTURE_WORDS,
    OTHER_SEQUENCE,
    PULSE_COLUMNS,
    CaptureError,
    analyze_runs,
    build_report,
    main,
    read_capture,
    read_pulse_measurements,
)


ROOT = Path(__file__).resolve().parents[2]


def _edge(
    run: str,
    sample: int,
    address: int,
    data: int,
    *,
    int_n: int = 1,
    men_n: int = 0,
    we_n: int = 1,
    den_n: int = 1,
) -> str:
    return ",".join(
        (
            run,
            str(sample),
            str(sample * 200),
            "1",
            str(int_n),
            str(men_n),
            str(we_n),
            str(den_n),
            f"0x{address:03x}",
            f"0x{data:04x}",
        )
    )


def _run_rows(run: str, sequence: tuple[int, ...]) -> list[str]:
    rows = [
        _edge(run, 0, 7, sequence[0], men_n=1, we_n=0),
        _edge(run, 1, 0x01A, 0x7F80, int_n=0),
        _edge(run, 2, 0x01B, 0x7F81),
    ]
    for value in sequence[1:]:
        sample = len(rows)
        rows.append(_edge(run, sample, 7, value, men_n=1, we_n=0))
    sample = len(rows)
    rows.append(_edge(run, sample, 0x01F, 0xF900))
    rows.append(_edge(run, sample + 1, 0x020, 0x001F))
    return rows


def _capture_text(sequences: list[tuple[int, ...]]) -> str:
    rows = [",".join(CAPTURE_COLUMNS)]
    for index, sequence in enumerate(sequences):
        rows.extend(_run_rows(f"run-{index:02d}", sequence))
    return "\n".join(rows) + "\n"


def _pulse_text(
    count: int,
    *,
    assertion: str = "120",
    release: str = "350",
    fall: str = "10",
) -> str:
    rows = [",".join(PULSE_COLUMNS)]
    for index in range(count):
        rows.append(f"run-{index:02d},{assertion},{release},{fall}")
    return "\n".join(rows) + "\n"


def _expected_image() -> bytes:
    return b"".join(
        FIXTURE_WORDS.get(address, 0).to_bytes(2, byteorder="big")
        for address in range(max(FIXTURE_WORDS) + 1)
    )


class DintInterruptCaptureTests(unittest.TestCase):
    def test_all_three_retained_sequences_are_distinguished(self) -> None:
        cases = (
            ((0x0033, 0x0022), CANCELS_ENTRY),
            ((0x0033, 0x001C, 0x0011, 0x0022), ENTRY_STACKS_N_PLUS_2),
            ((0x0033, 0x001B, 0x0011, 0x0022), ENTRY_STACKS_N_PLUS_1),
        )
        for sequence, expected in cases:
            with self.subTest(sequence=sequence):
                observations = analyze_runs(
                    read_capture(io.StringIO(_capture_text([sequence]))),
                    read_pulse_measurements(io.StringIO(_pulse_text(1))),
                )
                self.assertEqual(len(observations), 1)
                self.assertEqual(observations[0].classification, expected)
                self.assertTrue(observations[0].fixture_valid)
                self.assertEqual(observations[0].setup_ns, 80)
                self.assertEqual(observations[0].pulse_width_ns, 230)
                self.assertEqual(observations[0].local_clkout_period_ns, 200)

    def test_unanticipated_sequence_is_retained_without_candidate_resolution(self) -> None:
        sequence = (0x0033, 0x9999, 0x0022)
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            capture = root / "capture.csv"
            pulse = root / "pulse.csv"
            capture.write_text(_capture_text([sequence]), encoding="utf-8")
            pulse.write_text(_pulse_text(1), encoding="utf-8")
            report = build_report(capture, pulse, minimum_runs=1)
            self.assertEqual(
                report.classifications,
                (OTHER_SEQUENCE + "_0033_9999_0022",),
            )
            self.assertTrue(report.repeatable)
            self.assertFalse(report.candidate_resolved)
            self.assertFalse(report.review_ready)

    def test_setup_width_fall_and_sampled_level_are_checked_independently(self) -> None:
        capture = _capture_text([(0x0033, 0x0022)])
        pulses = _pulse_text(1, assertion="151", release="350", fall="16")
        observation = analyze_runs(
            read_capture(io.StringIO(capture)),
            read_pulse_measurements(io.StringIO(pulses)),
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("below the documented 50 ns" in item for item in observation.warnings))
        self.assertTrue(any("below local CLKOUT period" in item for item in observation.warnings))
        self.assertTrue(any("above 15 ns" in item for item in observation.warnings))

        wrong_level = capture.replace(
            "run-00,1,200,1,0,0,1,1,0x01a,0x7f80",
            "run-00,1,200,1,1,0,1,1,0x01a,0x7f80",
        )
        observation = analyze_runs(
            read_capture(io.StringIO(wrong_level)),
            read_pulse_measurements(io.StringIO(_pulse_text(1))),
        )[0]
        self.assertTrue(any("INT level disagrees" in item for item in observation.warnings))

    def test_parsers_and_race_window_fail_closed(self) -> None:
        good_capture = _capture_text([(0x0033, 0x0022)])
        good_pulses = _pulse_text(1)
        malformed_capture = (
            good_capture.replace("rs_n,int_n", "int_n,rs_n", 1),
            good_capture.replace("run-00,2,400", "run-00,2,200", 1),
            good_capture.replace("0x01a,0x7f80", "0x01a,0x7f81", 1),
            "\n".join(good_capture.splitlines()[:-2]) + "\n",
        )
        for text in malformed_capture:
            with self.subTest(text=text):
                with self.assertRaises(CaptureError):
                    analyze_runs(
                        read_capture(io.StringIO(text)),
                        read_pulse_measurements(io.StringIO(good_pulses)),
                    )

        malformed_pulses = (
            good_pulses.replace("int_assert_ns,int_release_ns", "int_release_ns,int_assert_ns", 1),
            good_pulses.replace("120,350", "350,120", 1),
            good_pulses + "run-00,120,350,10\n",
            good_pulses.replace("run-00", "different-run"),
        )
        for text in malformed_pulses:
            with self.subTest(text=text):
                with self.assertRaises(CaptureError):
                    analyze_runs(
                        read_capture(io.StringIO(good_capture)),
                        read_pulse_measurements(io.StringIO(text)),
                    )

    def test_complete_calibrated_package_is_review_ready_without_overclaim(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            capture = root / "normalized.csv"
            pulse = root / "pulse.csv"
            image = root / "probe.bin"
            raw = root / "raw.sal"
            photograph = root / "probe.jpg"
            capture.write_text(
                _capture_text([(0x0033, 0x0022)] * 32),
                encoding="utf-8",
            )
            pulse.write_text(_pulse_text(32), encoding="utf-8")
            image.write_bytes(_expected_image())
            raw.write_bytes(b"raw DINT capture")
            photograph.write_bytes(b"DINT probe photograph")
            fixture_source = root / "dint_interrupt_race_probe.asm"
            fixture_source.write_bytes(
                (
                    ROOT / "tests" / "asm" / "dint_interrupt_race_probe.asm"
                ).read_bytes()
            )
            fixture_listing = root / "dint_interrupt_race_probe.lst"
            fixture_listing.write_text(
                "".join(
                    f"{address:03x} {word:04x} synthetic:test\n"
                    for address, word in sorted(FIXTURE_WORDS.items())
                ),
                encoding="utf-8",
            )
            specimen_photos = {}
            for view in ("top", "bottom", "board_context"):
                path = root / f"specimen-{view}.jpg"
                path.write_bytes(f"synthetic {view} specimen view".encode("ascii"))
                specimen_photos[view] = {
                    "path": path.name,
                    "sha256": sha256(path.read_bytes()).hexdigest(),
                }
            calibrations: dict[str, dict[str, str]] = {}
            for name in ("no_pulse", "one_fetch_earlier", "one_fetch_later"):
                path = root / f"{name}.sal"
                path.write_bytes(f"synthetic {name} calibration".encode())
                calibrations[name] = {
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
                        "program_memory": "synthetic memory",
                        "program_memory_access_time_ns": 35.0,
                        "probe_model": "synthetic probe",
                        "analyzer_model": "synthetic analyzer",
                        "analyzer_firmware": "test",
                        "interrupt_driver_circuit": "open-collector test driver",
                        "interrupt_driver_voltage_v": "5.00 measured",
                        "pulse_generator_model": "synthetic pulse generator",
                        "program_image_sha256": sha256(image.read_bytes()).hexdigest(),
                        "normalized_capture_sha256": sha256(
                            capture.read_bytes()
                        ).hexdigest(),
                        "pulse_measurements_sha256": sha256(pulse.read_bytes()).hexdigest(),
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
                            "INT_N": "pin 7",
                            "MEN_N": "pin 8",
                            "WE_N": "pin 9",
                            "DEN_N": "pin 10",
                            "RS_N": "pin 11",
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
                        "specimen_photographs": specimen_photos,
                        "calibrations": calibrations,
                    },
                    indent=2,
                ),
                encoding="utf-8",
            )
            report = build_report(
                capture,
                pulse,
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
            self.assertEqual(set(report.classifications), {CANCELS_ENTRY})
            self.assertEqual(len(report.evidence_package.verified_artifacts), 10)
            encoded = json.dumps(report.to_json_object(), sort_keys=True)
            self.assertIn("does not change OQ-019", encoded)
            self.assertIn("identified specimen", encoded)

            output = io.StringIO()
            with redirect_stdout(output):
                return_code = main(
                    (
                        str(capture),
                        "--pulse-measurements",
                        str(pulse),
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

            escaped = json.loads(metadata.read_text(encoding="utf-8"))
            escaped["calibrations"]["no_pulse"]["path"] = "../no_pulse.sal"
            metadata.write_text(json.dumps(escaped), encoding="utf-8")
            escaped_report = build_report(
                capture,
                pulse,
                metadata_path=metadata,
                program_image=image,
                artifact_root=root,
            )
            self.assertFalse(escaped_report.evidence_package.complete)
            self.assertFalse(escaped_report.review_ready)
            self.assertTrue(
                any(
                    "escapes artifact_root" in error
                    for error in escaped_report.evidence_package.errors
                )
            )

    def test_wrong_exact_image_and_unstable_runs_cannot_be_review_ready(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            capture = root / "capture.csv"
            pulse = root / "pulse.csv"
            capture.write_text(
                _capture_text(
                    [
                        (0x0033, 0x0022),
                        (0x0033, 0x001C, 0x0011, 0x0022),
                    ]
                ),
                encoding="utf-8",
            )
            pulse.write_text(_pulse_text(2), encoding="utf-8")
            report = build_report(capture, pulse, minimum_runs=2)
            self.assertFalse(report.repeatable)
            self.assertFalse(report.candidate_resolved)
            self.assertFalse(report.review_ready)

            wrong = root / "wrong.bin"
            wrong.write_bytes(b"not the DINT fixture")
            metadata = root / "metadata.json"
            metadata.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "device_marking": "x",
                        "board_revision": "x",
                        "oscillator_hz": 1,
                        "supply_voltage_v": "x",
                        "program_memory": "x",
                        "probe_model": "x",
                        "analyzer_model": "x",
                        "analyzer_firmware": "x",
                        "interrupt_driver_circuit": "x",
                        "interrupt_driver_voltage_v": "x",
                        "pulse_generator_model": "x",
                        "program_image_sha256": sha256(wrong.read_bytes()).hexdigest(),
                        "pulse_measurements_sha256": sha256(pulse.read_bytes()).hexdigest(),
                        "signal_pin_map": {name: "x" for name in (
                            "CLKOUT", "INT_N", "MEN_N", "WE_N", "DEN_N",
                            "RS_N", "A11:A0", "D15:D0",
                        )},
                        "raw_artifacts": {},
                        "probe_photographs": {},
                        "calibrations": {},
                    }
                ),
                encoding="utf-8",
            )
            wrong_report = build_report(
                capture,
                pulse,
                minimum_runs=2,
                metadata_path=metadata,
                program_image=wrong,
                artifact_root=root,
            )
            self.assertIn(
                "program image is not the exact sparse big-endian DINT fixture",
                wrong_report.evidence_package.errors,
            )


if __name__ == "__main__":
    unittest.main()
