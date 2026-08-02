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
from tools.trace.ram_invalid_write_capture import (
    ABSENT_COUNT,
    ASCENDING_WORDS,
    DESCENDING_REPLACEMENTS,
    analyze_direction,
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


def _sequence(
    direction: str,
    valid_scan: tuple[int, ...],
    absent_values: tuple[int, ...],
) -> tuple[int, ...]:
    if len(valid_scan) != 144 or len(absent_values) != ABSENT_COUNT:
        raise AssertionError("write capture requires 144 valid and 112 absent words")
    marker = 0x0041 if direction == "ASCENDING" else 0x0042
    return (marker,) + valid_scan + absent_values + (0x004F,)


def _sentinels() -> tuple[int, ...]:
    return tuple(0xA06F - index for index in range(ABSENT_COUNT))


def _run_rows(direction: str, run: str, sequence: tuple[int, ...]) -> list[str]:
    events: list[tuple[int, int, int, int, int]] = []
    if len(sequence) >= 258:
        absent_word = 0x4FA1 if direction == "ASCENDING" else 0x4F91
        output_specs: list[tuple[tuple[int, int], int]] = [
            ((0x012, 0x4F00), sequence[0])
        ]
        output_specs.extend(
            ((0x01C, 0x4F88), value) for value in sequence[1:145]
        )
        output_specs.extend(
            ((0x022, absent_word), value) for value in sequence[145:257]
        )
        output_specs.append(((0x027, 0x4F00), sequence[257]))
        for (address, word), value in output_specs:
            events.extend(
                (
                    (address, word, 0, 1, 1),
                    (7, value, 1, 0, 1),
                )
            )
        for value in sequence[258:]:
            events.append((7, value, 1, 0, 1))
    else:
        events.append((0x012, 0x4F00, 0, 1, 1))
        for value in sequence:
            events.append((7, value, 1, 0, 1))
    if len(sequence) >= 258:
        events.append((0x029, 0xF900, 0, 1, 1))
        trailing_count = 3
    else:
        trailing_count = 4
    events.extend((0x028, 0x7F80, 0, 1, 1) for _ in range(trailing_count))
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


def _capture_text(direction: str, sequences: list[tuple[int, ...]]) -> str:
    rows = [",".join(CAPTURE_COLUMNS)]
    for index, sequence in enumerate(sequences):
        rows.extend(_run_rows(direction, f"run-{index:02d}", sequence))
    return "\n".join(rows) + "\n"


def _binary(direction: str) -> bytes:
    words = list(ASCENDING_WORDS)
    if direction == "DESCENDING":
        for address, word in DESCENDING_REPLACEMENTS.items():
            words[address] = word
    return b"".join(word.to_bytes(2, byteorder="big") for word in words)


def _prior_report(root: Path, *, valid: bool = True) -> Path:
    report = root / "read-stage-report.json"
    report.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "claim_boundary": (
                    "Stage-1 controlled-history read classification and package "
                    "validation only"
                ),
                "review_ready": valid,
                "acceptance_complete": False,
                "complete": True,
                "fixture_valid": True,
                "minimum_conditions_met": True,
                "evidence_package": {"complete": True},
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    return report


def _write_package(
    root: Path,
    ascending_sequences: list[tuple[int, ...]],
    descending_sequences: list[tuple[int, ...]],
) -> dict[str, Path]:
    paths: dict[str, Path] = {}
    prior = _prior_report(root)
    paths["prior"] = prior
    prior_hash = sha256(prior.read_bytes()).hexdigest()
    for direction, sequences in (
        ("ASCENDING", ascending_sequences),
        ("DESCENDING", descending_sequences),
    ):
        lower = direction.lower()
        capture = root / f"{lower}.csv"
        capture.write_text(_capture_text(direction, sequences), encoding="utf-8")
        paths[f"{lower}_capture"] = capture
        image = root / f"{lower}.bin"
        image.write_bytes(_binary(direction))
        paths[f"{lower}_image"] = image
        raw = root / f"{lower}.sal"
        raw.write_bytes(f"raw {direction} write capture".encode("ascii"))
        photograph = root / f"{lower}.jpg"
        photograph.write_bytes(f"{direction} write probe".encode("ascii"))
        metadata = root / f"{lower}_metadata.json"
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
                    "prior_read_report_sha256": prior_hash,
                    "capture_stage": "write_after_pinned_read_only",
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
                },
                indent=2,
            ),
            encoding="utf-8",
        )
        paths[f"{lower}_metadata"] = metadata
    return paths


class RamInvalidWriteCaptureTests(unittest.TestCase):
    def test_directional_addresses_sentinels_and_readback_are_preserved(self) -> None:
        absent_values = list(_sentinels())
        absent_values[1] = 0x0000
        absent_values[2] = 0x1234
        for direction, first_address, second_address in (
            ("ASCENDING", 0x90, 0x91),
            ("DESCENDING", 0xFF, 0xFE),
        ):
            with self.subTest(direction=direction):
                sequence = _sequence(
                    direction,
                    (0x0000,) * 144,
                    tuple(absent_values),
                )
                observation = analyze_direction(
                    direction,
                    read_normalized_capture(
                        io.StringIO(_capture_text(direction, [sequence]))
                    ),
                )[0]
                self.assertEqual(
                    observation.classification,
                    "COMPLETE_VALID_CHANGED_000_SM_110_ZV_001_OT_001",
                )
                self.assertEqual(observation.absent_observations[0].address, first_address)
                self.assertEqual(observation.absent_observations[1].address, second_address)
                self.assertEqual(
                    observation.absent_observations[0].expected_sentinel,
                    0xA06F,
                )
                self.assertEqual(
                    observation.absent_observations[1].relationship,
                    "ZERO_VALUE",
                )
                self.assertEqual(
                    observation.absent_observations[2].relationship,
                    "OTHER_1234",
                )
                self.assertTrue(observation.fixture_valid)

    def test_valid_array_disturbances_are_listed_in_descending_scan_order(self) -> None:
        valid = [0] * 144
        valid[0] = 0x1111
        valid[143] = 0x2222
        sequence = _sequence("ASCENDING", tuple(valid), (0x0000,) * 112)
        observation = analyze_direction(
            "ASCENDING",
            read_normalized_capture(
                io.StringIO(_capture_text("ASCENDING", [sequence]))
            ),
        )[0]
        self.assertEqual(observation.changed_valid_addresses, (0x8F, 0x00))
        self.assertIn("VALID_CHANGED_002", observation.classification)
        self.assertTrue(observation.fixture_valid)

    def test_partial_and_extra_streams_remain_incomplete(self) -> None:
        full = _sequence("ASCENDING", (0,) * 144, (0,) * 112)
        for sequence, classification in (
            ((0x0041,), "PARTIAL_OUTPUT_STREAM_001"),
            ((0x0041, 0x0000), "PARTIAL_OUTPUT_STREAM_002"),
            (full + (0x9999,), "EXTRA_OUTPUT_STREAM_259"),
        ):
            with self.subTest(classification=classification):
                observation = analyze_direction(
                    "ASCENDING",
                    read_normalized_capture(
                        io.StringIO(_capture_text("ASCENDING", [sequence]))
                    ),
                )[0]
                self.assertEqual(observation.classification, classification)
                self.assertFalse(observation.capture_complete)

    def test_markers_anchors_controls_terminal_and_window_are_checked(self) -> None:
        sequence = _sequence("DESCENDING", (0,) * 144, (0,) * 112)
        good = _capture_text("DESCENDING", [sequence])
        missing_start = good.replace("0x012,0x4f00", "0x012,0x4f01", 1)
        with self.assertRaises(CaptureError):
            analyze_direction(
                "DESCENDING",
                read_normalized_capture(io.StringIO(missing_start)),
            )
        truncated = "\n".join(good.splitlines()[:-1]) + "\n"
        with self.assertRaises(CaptureError):
            analyze_direction(
                "DESCENDING",
                read_normalized_capture(io.StringIO(truncated)),
            )

        bad_marker = good.replace("0x007,0x0042", "0x007,0x0041", 1)
        observation = analyze_direction(
            "DESCENDING",
            read_normalized_capture(io.StringIO(bad_marker)),
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("start marker" in item for item in observation.warnings))

        bad_anchor = good.replace("0x022,0x4f91", "0x022,0x4f90", 1)
        observation = analyze_direction(
            "DESCENDING",
            read_normalized_capture(io.StringIO(bad_anchor)),
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("appears 111" in item for item in observation.warnings))

        bad_control = good.replace(
            ",1,1,0,1,0x007,0x0042",
            ",1,0,0,1,0x007,0x0042",
            1,
        )
        observation = analyze_direction(
            "DESCENDING",
            read_normalized_capture(io.StringIO(bad_control)),
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("exclusive" in item for item in observation.warnings))

    def test_complete_variable_pair_is_review_ready_but_acceptance_is_open(self) -> None:
        ascending_first = _sequence("ASCENDING", (0,) * 144, _sentinels())
        valid_changed = [0] * 144
        valid_changed[0] = 0xCAFE
        ascending_second = _sequence(
            "ASCENDING",
            tuple(valid_changed),
            (0x1234,) * 112,
        )
        descending = _sequence("DESCENDING", (0,) * 144, (0,) * 112)
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            paths = _write_package(
                root,
                [ascending_first, ascending_second],
                [descending],
            )
            report = build_report(
                paths["ascending_capture"],
                paths["descending_capture"],
                ascending_metadata=paths["ascending_metadata"],
                descending_metadata=paths["descending_metadata"],
                ascending_image=paths["ascending_image"],
                descending_image=paths["descending_image"],
                prior_read_report=paths["prior"],
                artifact_root=root,
            )
            self.assertTrue(report.minimum_runs_met)
            self.assertTrue(report.complete)
            self.assertTrue(report.fixture_valid)
            self.assertTrue(report.prior_read_evidence.complete)
            self.assertTrue(report.review_ready)
            self.assertFalse(report.acceptance_complete)
            summaries = {item.direction: item for item in report.directions}
            self.assertFalse(summaries["ASCENDING"].repeatable)
            self.assertTrue(summaries["DESCENDING"].repeatable)
            encoded = json.dumps(report.to_json_object(), sort_keys=True)
            self.assertIn("does not independently prove wall-clock order", encoded)
            self.assertIn("does not change OQ-002", encoded)

            output = io.StringIO()
            with redirect_stdout(output):
                return_code = main(
                    (
                        str(paths["ascending_capture"]),
                        str(paths["descending_capture"]),
                        "--ascending-metadata",
                        str(paths["ascending_metadata"]),
                        "--descending-metadata",
                        str(paths["descending_metadata"]),
                        "--ascending-image",
                        str(paths["ascending_image"]),
                        "--descending-image",
                        str(paths["descending_image"]),
                        "--prior-read-report",
                        str(paths["prior"]),
                        "--artifact-root",
                        str(root),
                        "--require-review-ready",
                    )
                )
            self.assertEqual(return_code, 0)
            self.assertTrue(json.loads(output.getvalue())["review_ready"])

    def test_bad_prior_order_declaration_and_exact_image_block_review(self) -> None:
        ascending = _sequence("ASCENDING", (0,) * 144, (0,) * 112)
        descending = _sequence("DESCENDING", (0,) * 144, (0,) * 112)
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            paths = _write_package(root, [ascending], [descending])
            _prior_report(root, valid=False)
            paths["descending_image"].write_bytes(
                b"\x00" + _binary("DESCENDING")[1:]
            )
            metadata = json.loads(
                paths["descending_metadata"].read_text(encoding="utf-8")
            )
            metadata["program_image_sha256"] = sha256(
                paths["descending_image"].read_bytes()
            ).hexdigest()
            metadata["capture_stage"] = "unordered_write"
            paths["descending_metadata"].write_text(
                json.dumps(metadata, indent=2),
                encoding="utf-8",
            )
            report = build_report(
                paths["ascending_capture"],
                paths["descending_capture"],
                ascending_metadata=paths["ascending_metadata"],
                descending_metadata=paths["descending_metadata"],
                ascending_image=paths["ascending_image"],
                descending_image=paths["descending_image"],
                prior_read_report=paths["prior"],
                artifact_root=root,
            )
            self.assertFalse(report.prior_read_evidence.complete)
            self.assertFalse(report.review_ready)
            descending_summary = {
                item.direction: item for item in report.directions
            }["DESCENDING"]
            self.assertFalse(descending_summary.evidence_package.complete)
            self.assertTrue(
                any(
                    "exact big-endian" in item
                    for item in descending_summary.evidence_package.errors
                )
            )
            self.assertTrue(
                any(
                    "write_after_pinned_read_only" in item
                    for item in descending_summary.evidence_package.errors
                )
            )


if __name__ == "__main__":
    unittest.main()
