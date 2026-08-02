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
from tools.trace.ram_invalid_read_capture import (
    ABSENT_COUNT,
    FIXTURE_WORDS,
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


def _sequence(
    zero_values: tuple[int, ...],
    one_values: tuple[int, ...],
) -> tuple[int, ...]:
    if len(zero_values) != ABSENT_COUNT or len(one_values) != ABSENT_COUNT:
        raise AssertionError("both absent-value sweeps must contain 112 words")
    values = [0x0031]
    for value in zero_values:
        values.extend((0x0000, value))
    values.append(0x0032)
    for value in one_values:
        values.extend((0xFFFF, value))
    values.append(0x003F)
    return tuple(values)


def _run_rows(run: str, sequence: tuple[int, ...]) -> list[str]:
    events: list[tuple[int, int, int, int, int]] = []
    if len(sequence) >= 451:
        output_specs: list[tuple[tuple[int, int], int]] = [
            ((0x00F, 0x4F02), sequence[0])
        ]
        for index in range(ABSENT_COUNT):
            output_specs.append(((0x013, 0x4F00), sequence[1 + 2 * index]))
            output_specs.append(((0x014, 0x4FA1), sequence[2 + 2 * index]))
        output_specs.append(((0x017, 0x4F03), sequence[225]))
        for index in range(ABSENT_COUNT):
            output_specs.append(((0x01B, 0x4F01), sequence[226 + 2 * index]))
            output_specs.append(((0x01C, 0x4FA1), sequence[227 + 2 * index]))
        output_specs.append(((0x01F, 0x4F04), sequence[450]))
        for (address, word), value in output_specs:
            events.extend(
                (
                    (address, word, 0, 1, 1),
                    (7, value, 1, 0, 1),
                )
            )
        for value in sequence[451:]:
            events.append((7, value, 1, 0, 1))
    else:
        events.append((0x00F, 0x4F02, 0, 1, 1))
        for value in sequence:
            events.append((7, value, 1, 0, 1))
    if len(sequence) >= 451:
        events.append((0x021, 0xF900, 0, 1, 1))
        trailing_count = 3
    else:
        trailing_count = 4
    events.extend((0x020, 0x7F80, 0, 1, 1) for _ in range(trailing_count))
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


def _capture_text(sequences: list[tuple[int, ...]]) -> str:
    rows = [",".join(CAPTURE_COLUMNS)]
    for index, sequence in enumerate(sequences):
        rows.extend(_run_rows(f"run-{index:02d}", sequence))
    return "\n".join(rows) + "\n"


def _binary() -> bytes:
    return b"".join(word.to_bytes(2, byteorder="big") for word in FIXTURE_WORDS)


def _metadata(
    root: Path,
    capture: Path,
    image: Path,
    run_conditions: dict[str, object],
) -> Path:
    raw = root / "read-sweep.sal"
    photograph = root / "read-probe.jpg"
    raw.write_bytes(b"raw absent-RAM read sweep")
    photograph.write_bytes(b"absent-RAM read probe photograph")
    fixture_source = root / "ram_invalid_read_sweep_probe.asm"
    fixture_source.write_bytes(
        (
            ROOT / "tests" / "asm" / "ram_invalid_read_sweep_probe.asm"
        ).read_bytes()
    )
    fixture_listing = root / "ram_invalid_read_sweep_probe.lst"
    fixture_listing.write_text(
        "".join(
            f"{address:03x} {word:04x} synthetic:test\n"
            for address, word in enumerate(FIXTURE_WORDS)
        ),
        encoding="utf-8",
    )
    specimen_photos: dict[str, dict[str, str]] = {}
    for view in ("top", "bottom", "board_context"):
        specimen_photo = root / f"specimen-{view}.jpg"
        specimen_photo.write_bytes(
            f"synthetic {view} specimen view".encode("ascii")
        )
        specimen_photos[view] = {
            "path": specimen_photo.name,
            "sha256": sha256(specimen_photo.read_bytes()).hexdigest(),
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
                "program_image_sha256": sha256(image.read_bytes()).hexdigest(),
                "normalized_capture_sha256": sha256(
                    capture.read_bytes()
                ).hexdigest(),
                "run_conditions": run_conditions,
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
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    return metadata


class RamInvalidReadCaptureTests(unittest.TestCase):
    def test_each_history_relationship_is_preserved_by_address(self) -> None:
        zero_values = [0x0000] * ABSENT_COUNT
        one_values = [0xFFFF] * ABSENT_COUNT
        zero_values[1] = 0x1234
        one_values[1] = 0x1234
        zero_values[2] = 0x1111
        one_values[2] = 0x2222
        observation = analyze_runs(
            read_normalized_capture(
                io.StringIO(
                    _capture_text([_sequence(tuple(zero_values), tuple(one_values))])
                )
            )
        )[0]
        self.assertEqual(
            observation.classification,
            "COMPLETE_PT_110_HI_001_HD_001",
        )
        self.assertEqual(
            observation.address_observations[0].relationship,
            "PREDECESSOR_TRACKING",
        )
        self.assertEqual(
            observation.address_observations[1].relationship,
            "HISTORY_INDEPENDENT_1234",
        )
        self.assertEqual(
            observation.address_observations[2].relationship,
            "HISTORY_DEPENDENT_1111_2222",
        )
        self.assertTrue(observation.capture_complete)
        self.assertTrue(observation.fixture_valid)

    def test_partial_and_extra_streams_are_retained_but_incomplete(self) -> None:
        for sequence, classification in (
            ((0x0031,), "PARTIAL_OUTPUT_STREAM_001"),
            ((0x0031, 0x0000, 0xCAFE), "PARTIAL_OUTPUT_STREAM_003"),
            (
                _sequence((0x0000,) * 112, (0xFFFF,) * 112) + (0x9999,),
                "EXTRA_OUTPUT_STREAM_452",
            ),
        ):
            with self.subTest(classification=classification):
                observation = analyze_runs(
                    read_normalized_capture(
                        io.StringIO(_capture_text([sequence]))
                    )
                )[0]
                self.assertEqual(observation.classification, classification)
                self.assertFalse(observation.capture_complete)

    def test_markers_predecessors_anchors_controls_and_window_are_checked(
        self,
    ) -> None:
        sequence = _sequence((0x0000,) * 112, (0xFFFF,) * 112)
        good = _capture_text([sequence])
        missing_start = good.replace("0x00f,0x4f02", "0x00f,0x4f03", 1)
        with self.assertRaises(CaptureError):
            analyze_runs(read_normalized_capture(io.StringIO(missing_start)))
        truncated = "\n".join(good.splitlines()[:-1]) + "\n"
        with self.assertRaises(CaptureError):
            analyze_runs(read_normalized_capture(io.StringIO(truncated)))

        bad_marker = good.replace("0x007,0x0031", "0x007,0x0030", 1)
        observation = analyze_runs(
            read_normalized_capture(io.StringIO(bad_marker))
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("marker" in item for item in observation.warnings))

        bad_predecessor = good.replace("0x007,0x0000", "0x007,0x0001", 1)
        observation = analyze_runs(
            read_normalized_capture(io.StringIO(bad_predecessor))
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("predecessor" in item for item in observation.warnings))

        bad_control = good.replace(
            ",1,1,0,1,0x007,0x0031",
            ",1,0,0,1,0x007,0x0031",
            1,
        )
        observation = analyze_runs(
            read_normalized_capture(io.StringIO(bad_control))
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("exclusive" in item for item in observation.warnings))

        missing_anchor = good.replace("0x01c,0x4fa1", "0x01c,0x4fa0", 1)
        observation = analyze_runs(
            read_normalized_capture(io.StringIO(missing_anchor))
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("appears 111" in item for item in observation.warnings))

    def test_variable_complete_runs_do_not_block_stage_one_review(self) -> None:
        first = _sequence((0x0000,) * 112, (0xFFFF,) * 112)
        changed = list((0x0000,) * 112)
        changed[0] = 0xCAFE
        second = _sequence(tuple(changed), (0xFFFF,) * 112)
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            capture = root / "capture.csv"
            image = root / "probe.bin"
            capture.write_text(
                _capture_text([first, second, first]),
                encoding="utf-8",
            )
            image.write_bytes(_binary())
            metadata = _metadata(
                root,
                capture,
                image,
                {
                    "run-00": "reset",
                    "run-01": "reset",
                    "run-02": "cold_power",
                },
            )
            report = build_report(
                capture,
                minimum_reset_runs=2,
                minimum_cold_power_runs=1,
                metadata_path=metadata,
                program_image=image,
                artifact_root=root,
            )
            self.assertTrue(report.minimum_conditions_met)
            self.assertTrue(report.complete)
            self.assertTrue(report.fixture_valid)
            self.assertFalse(report.repeatable)
            self.assertTrue(report.review_ready)
            self.assertFalse(report.acceptance_complete)
            self.assertEqual(report.specimen_id, "synthetic-specimen-01")
            self.assertEqual(report.specimen_scope, "this_specimen_only")
            self.assertEqual(len(report.evidence_package.verified_artifacts), 7)
            encoded = json.dumps(report.to_json_object(), sort_keys=True)
            self.assertIn("does not change OQ-002", encoded)
            self.assertIn("qualify destructive writes", encoded)

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
                        "--minimum-reset-runs",
                        "2",
                        "--minimum-cold-power-runs",
                        "1",
                        "--require-review-ready",
                    )
                )
            self.assertEqual(return_code, 0)
            self.assertTrue(json.loads(output.getvalue())["review_ready"])

    def test_run_condition_schema_and_minima_fail_closed(self) -> None:
        sequence = _sequence((0x0000,) * 112, (0xFFFF,) * 112)
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            capture = root / "capture.csv"
            image = root / "probe.bin"
            capture.write_text(_capture_text([sequence]), encoding="utf-8")
            image.write_bytes(_binary())
            metadata = _metadata(root, capture, image, {"run-00": "reset"})
            report = build_report(
                capture,
                minimum_reset_runs=1,
                minimum_cold_power_runs=1,
                metadata_path=metadata,
                program_image=image,
                artifact_root=root,
            )
            self.assertFalse(report.minimum_conditions_met)
            self.assertFalse(report.review_ready)

            metadata = _metadata(root, capture, image, {"run-00": ["reset"]})
            report = build_report(
                capture,
                minimum_reset_runs=1,
                minimum_cold_power_runs=1,
                metadata_path=metadata,
                program_image=image,
                artifact_root=root,
            )
            self.assertFalse(report.evidence_package.complete)
            self.assertFalse(report.review_ready)
            self.assertTrue(
                any("reset or cold_power" in item for item in report.evidence_package.errors)
            )

    def test_wrong_exact_image_blocks_review_without_assigning_read_data(self) -> None:
        sequence = _sequence((0x1234,) * 112, (0x5678,) * 112)
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            capture = root / "capture.csv"
            image = root / "probe.bin"
            capture.write_text(_capture_text([sequence, sequence]), encoding="utf-8")
            image.write_bytes(b"\x00" + _binary()[1:])
            metadata = _metadata(
                root,
                capture,
                image,
                {"run-00": "reset", "run-01": "cold_power"},
            )
            metadata_value = json.loads(metadata.read_text(encoding="utf-8"))
            listing = (
                root
                / metadata_value["fixture_artifacts"]["listing"]["path"]
            )
            listing.write_text(
                listing.read_text(encoding="utf-8").replace(
                    "010 7090", "010 7091"
                ),
                encoding="utf-8",
            )
            metadata_value["fixture_artifacts"]["listing"]["sha256"] = sha256(
                listing.read_bytes()
            ).hexdigest()
            metadata.write_text(
                json.dumps(metadata_value, indent=2),
                encoding="utf-8",
            )
            report = build_report(
                capture,
                minimum_reset_runs=1,
                minimum_cold_power_runs=1,
                metadata_path=metadata,
                program_image=image,
                artifact_root=root,
            )
            self.assertFalse(report.evidence_package.complete)
            self.assertFalse(report.review_ready)
            self.assertTrue(
                any(
                    "exact big-endian" in item
                    for item in report.evidence_package.errors
                )
            )
            self.assertTrue(
                any(
                    "exact address/word map" in item
                    for item in report.evidence_package.errors
                )
            )
            self.assertEqual(
                report.observations[0].address_observations[0].after_zero,
                0x1234,
            )


if __name__ == "__main__":
    unittest.main()
