from __future__ import annotations

from contextlib import redirect_stdout
from decimal import Decimal
from hashlib import sha256
import io
import json
from pathlib import Path
import tempfile
import unittest

from tools.assembler.tms32010_as import Assembler
from tools.trace.push_pop_capture import CaptureError
from tools.trace.reset_retention_capture import (
    ARMED_BRANCHES,
    ARMED_MARKERS,
    ARMED_OUT_ANCHORS,
    BIOZ_ANCHOR,
    CAPTURE_COLUMNS,
    POST_OUT_ANCHORS,
    POST_TARGET_ANCHOR,
    PRE_OUT_ANCHORS,
    PRE_VECTORS,
    RESET_COLUMNS,
    TERMINAL_BRANCH,
    TERMINAL_OUT_ANCHOR,
    RunCondition,
    ResetMeasurement,
    analyze_fixture,
    build_report,
    main,
    read_capture,
    read_reset_measurements,
)


ROOT = Path(__file__).resolve().parents[2]


def _program_event(anchor: tuple[int, int], bio_n: int = 1) -> tuple[int, ...]:
    return (1, bio_n, 0, 1, 1, anchor[0], anchor[1])


def _output_event(value: int, bio_n: int) -> tuple[int, ...]:
    return (1, bio_n, 1, 0, 1, 7, value)


def _run(
    fixture: str,
    run: str,
    *,
    target_cycles: int = 5,
    period_ns: int = 100,
    post_vector: tuple[int, ...] | None = None,
) -> tuple[list[str], ResetMeasurement]:
    pre = PRE_VECTORS[fixture]
    post = pre if post_vector is None else post_vector
    events: list[tuple[int, ...]] = [_program_event(BIOZ_ANCHOR)]
    events.append(_program_event((0x001, 0x0100)))
    for anchor, value in zip(PRE_OUT_ANCHORS[fixture], pre):
        events.append(_program_event(anchor))
        events.append(_output_event(value, 1))
    events.append(_program_event(ARMED_OUT_ANCHORS[fixture]))
    events.append(_output_event(ARMED_MARKERS[fixture], 1))
    armed_output_index = len(events) - 1
    events.append(_program_event(ARMED_BRANCHES[fixture], 0))
    bio_assert = Decimal(armed_output_index * period_ns) + Decimal(period_ns) / 4
    rs_assert = Decimal((armed_output_index + 1) * period_ns) + Decimal(period_ns) / 2
    for _ in range(target_cycles + 1):
        events.append((0, 0, 1, 1, 1, 0, 0xDEAD))
    last_low_index = len(events) - 1
    rs_release = Decimal(last_low_index * period_ns) + Decimal(period_ns) / 2
    events.append(_program_event(BIOZ_ANCHOR, 0))
    events.append(_program_event((0x001, 0x0100), 0))
    events.append(_program_event(POST_TARGET_ANCHOR, 0))
    for anchor, value in zip(POST_OUT_ANCHORS, post):
        events.append(_program_event(anchor, 0))
        events.append(_output_event(value, 0))
    events.append(_program_event(TERMINAL_OUT_ANCHOR, 0))
    events.append(_output_event(0x00AF, 0))
    events.append(_program_event(TERMINAL_BRANCH, 0))
    events.extend(_program_event((0x005, 0x7F80), 0) for _ in range(4))
    rows = []
    for sample, event in enumerate(events):
        rs_n, bio_n, men_n, we_n, den_n, address, data = event
        rows.append(
            ",".join(
                (
                    run,
                    str(sample),
                    str(sample * period_ns),
                    str(rs_n),
                    str(bio_n),
                    str(men_n),
                    str(we_n),
                    str(den_n),
                    f"0x{address:03x}",
                    f"0x{data:04x}",
                )
            )
        )
    return rows, ResetMeasurement(run, rs_assert, rs_release, bio_assert)


def _capture_text(specs: list[tuple[str, int, int, tuple[int, ...] | None]]) -> tuple[str, dict[str, ResetMeasurement]]:
    rows = [",".join(CAPTURE_COLUMNS)]
    measurements: dict[str, ResetMeasurement] = {}
    for fixture, target, period, post in specs:
        run_name = f"run-{len(measurements):02d}"
        run_rows, measurement = _run(
            fixture,
            run_name,
            target_cycles=target,
            period_ns=period,
            post_vector=post,
        )
        rows.extend(run_rows)
        measurements[run_name] = measurement
    return "\n".join(rows) + "\n", measurements


def _measurement_text(measurements: dict[str, ResetMeasurement]) -> str:
    rows = [",".join(RESET_COLUMNS)]
    rows.extend(
        ",".join(
            (
                run,
                str(item.rs_assert_ns),
                str(item.rs_release_ns),
                str(item.bio_assert_ns),
            )
        )
        for run, item in measurements.items()
    )
    return "\n".join(rows) + "\n"


def _dense_image(fixture: str) -> bytes:
    source = ROOT / "tests" / "asm" / f"reset_retention_{fixture.lower()}_probe.asm"
    result = Assembler().assemble_file(source)
    return b"".join(
        result.words.get(address, 0).to_bytes(2, byteorder="big")
        for address in range(max(result.words) + 1)
    )


def _write_fixture_package(
    root: Path,
    fixture: str,
    *,
    post_override: tuple[int, ...] | None = None,
    nominal_runs: int = 32,
) -> dict[str, Path]:
    specs: list[tuple[str, int, int, tuple[int, ...] | None]] = []
    condition_specs: list[tuple[str, int]] = []
    for index in range(nominal_runs):
        target = (5, 8, 32)[index % 3]
        specs.append((fixture, target, 100, post_override))
        condition_specs.append(("nominal", target))
    for clock_condition, period in (("slow_limit", 200), ("fast_limit", 50)):
        for target in (5, 8, 32):
            specs.append((fixture, target, period, post_override))
            condition_specs.append((clock_condition, target))
    capture_text, measurements = _capture_text(specs)
    lower = fixture.lower()
    capture = root / f"{lower}.csv"
    capture.write_text(capture_text, encoding="utf-8")
    reset_path = root / f"{lower}-reset.csv"
    reset_path.write_text(_measurement_text(measurements), encoding="utf-8")
    image = root / f"{lower}.bin"
    image.write_bytes(_dense_image(fixture))
    raw = root / f"{lower}.sal"
    raw.write_bytes(f"raw {fixture} reset capture".encode("ascii"))
    photo = root / f"{lower}.jpg"
    photo.write_bytes(f"{fixture} reset probe placement".encode("ascii"))
    run_conditions: dict[str, object] = {}
    for run, (clock_condition, target) in zip(
        measurements, condition_specs, strict=True
    ):
        run_conditions[run] = {
            "clock_condition": clock_condition,
            "reset_hold_target_cycles": target,
        }
    metadata = root / f"{lower}-metadata.json"
    metadata.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "device_marking": "TMS32010NL ORIGINAL TEST SPECIMEN",
                "board_revision": "synthetic test carrier",
                "oscillator_hz": 20_000_000,
                "supply_voltage_v": "5.00 measured",
                "program_memory": "synthetic memory",
                "probe_model": "synthetic probe",
                "analyzer_model": "synthetic analyzer",
                "analyzer_firmware": "test",
                "program_image_sha256": sha256(image.read_bytes()).hexdigest(),
                "reset_measurements_sha256": sha256(reset_path.read_bytes()).hexdigest(),
                "reset_driver_circuit": "open-collector-compatible synthetic driver",
                "bio_driver_circuit": "open-collector-compatible synthetic driver",
                "signal_pin_map": {
                    "CLKOUT": "pin/channel",
                    "MEN_N": "pin/channel",
                    "WE_N": "pin/channel",
                    "DEN_N": "pin/channel",
                    "RS_N": "pin/channel",
                    "BIO_N": "pin/channel",
                    "A11:A0": "pins/channels",
                    "D15:D0": "pins/channels",
                },
                "raw_artifacts": {raw.name: sha256(raw.read_bytes()).hexdigest()},
                "probe_photographs": {photo.name: sha256(photo.read_bytes()).hexdigest()},
                "run_conditions": run_conditions,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    return {
        "capture": capture,
        "reset": reset_path,
        "image": image,
        "metadata": metadata,
    }


def _direct_observation(
    fixture: str,
    *,
    target: int = 5,
    period: int = 100,
    post: tuple[int, ...] | None = None,
):
    text, measurements = _capture_text([(fixture, target, period, post)])
    runs = read_capture(io.StringIO(text))
    conditions = {"run-00": RunCondition("nominal", target)}
    return analyze_fixture(fixture, runs, measurements, conditions)[0]


class ResetRetentionCaptureTests(unittest.TestCase):
    def test_each_architectural_field_and_reserved_status_bit_are_preserved(self) -> None:
        set_post = list(PRE_VECTORS["SET"])
        set_post[4] &= ~0x0002
        observation = _direct_observation("SET", post=tuple(set_post))
        self.assertTrue(observation.capture_complete)
        self.assertTrue(observation.fixture_valid)
        self.assertEqual(observation.pre_status_reserved_bit_1, 1)
        self.assertEqual(observation.post_status_reserved_bit_1, 0)
        self.assertEqual(len(observation.fields), 13)
        self.assertEqual(
            {item.name for item in observation.fields},
            {
                "ACC", "AR0", "AR1", "OV", "OVM", "ARP", "DP", "P", "T",
                "STACK_TOP", "STACK_LEVEL_1", "STACK_LEVEL_2", "STACK_BOTTOM",
            },
        )
        self.assertTrue(all(item.relationship == "RETAINED" for item in observation.fields))

    def test_variable_post_values_can_be_review_ready_without_acceptance(self) -> None:
        clear_post = list(PRE_VECTORS["CLEAR"])
        clear_post[0] = 0
        clear_post[2] = 0x1234
        clear_post[3] = 0x5678
        clear_post[5] = 0xBEEF
        clear_post[7] = 0xCAFE
        clear_post[9:13] = (0x001, 0x002, 0x003, 0x004)
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            set_paths = _write_fixture_package(root, "SET")
            clear_paths = _write_fixture_package(
                root, "CLEAR", post_override=tuple(clear_post)
            )
            report = build_report(
                set_paths["capture"],
                clear_paths["capture"],
                set_paths["reset"],
                clear_paths["reset"],
                set_metadata=set_paths["metadata"],
                clear_metadata=clear_paths["metadata"],
                set_image=set_paths["image"],
                clear_image=clear_paths["image"],
                artifact_root=root,
            )
            self.assertTrue(report.minimum_nominal_runs_met)
            self.assertTrue(report.condition_coverage_complete)
            self.assertTrue(report.complete)
            self.assertTrue(report.fixture_valid)
            self.assertTrue(report.review_ready)
            self.assertFalse(report.observed_full_retention_candidate)
            self.assertFalse(report.acceptance_complete)
            fields = {item.name: item for item in report.field_summaries}
            self.assertEqual(fields["ACC"].pair_classification, "MIXED_OR_VARIABLE")
            self.assertEqual(fields["OVM"].pair_classification, "RETAINED_BOTH_FIXTURES")
            encoded = json.dumps(report.to_json_object(), sort_keys=True)
            self.assertIn("does not require post-reset retention", encoded)
            self.assertIn("PROVISIONAL model/RTL policy", encoded)

            output = io.StringIO()
            with redirect_stdout(output):
                return_code = main(
                    (
                        str(set_paths["capture"]),
                        str(clear_paths["capture"]),
                        "--set-reset-measurements", str(set_paths["reset"]),
                        "--clear-reset-measurements", str(clear_paths["reset"]),
                        "--set-metadata", str(set_paths["metadata"]),
                        "--clear-metadata", str(clear_paths["metadata"]),
                        "--set-image", str(set_paths["image"]),
                        "--clear-image", str(clear_paths["image"]),
                        "--artifact-root", str(root),
                        "--require-review-ready",
                    )
                )
            self.assertEqual(return_code, 0)
            self.assertTrue(json.loads(output.getvalue())["review_ready"])

    def test_reset_bio_duration_and_reset_bus_contract_fail_closed(self) -> None:
        good = _direct_observation("CLEAR", target=8)
        self.assertTrue(good.fixture_valid)
        self.assertEqual(good.reset_low_complete_cycles, 8)
        text, measurements = _capture_text([("CLEAR", 8, 100, None)])
        bad_bus = text.replace(
            "run-00,32,3200,0,0,1,1,1,0x000,0xdead",
            "run-00,32,3200,0,0,0,1,1,0x001,0xdead",
            1,
        )
        observation = analyze_fixture(
            "CLEAR",
            read_capture(io.StringIO(bad_bus)),
            measurements,
            {"run-00": RunCondition("nominal", 8)},
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("external controls" in item for item in observation.warnings))

        measurement = measurements["run-00"]
        bad_measurement = {
            "run-00": ResetMeasurement(
                "run-00",
                measurement.rs_assert_ns,
                measurement.rs_release_ns,
                measurement.bio_assert_ns + Decimal(200),
            )
        }
        observation = analyze_fixture(
            "CLEAR",
            read_capture(io.StringIO(text)),
            bad_measurement,
            {"run-00": RunCondition("nominal", 8)},
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("BIO level disagrees" in item for item in observation.warnings))

    def test_pre_state_marker_ovm_and_exact_anchors_are_validity_controls(self) -> None:
        text, measurements = _capture_text([("SET", 5, 100, None)])
        bad_pre = text.replace("0x007,0x00a5", "0x007,0x00a4", 1)
        observation = analyze_fixture(
            "SET",
            read_capture(io.StringIO(bad_pre)),
            measurements,
            {"run-00": RunCondition("nominal", 5)},
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("pre-reset vector position" in item for item in observation.warnings))

        bad_anchor = text.replace("0x106,0x4f00", "0x106,0x4f01", 1)
        observation = analyze_fixture(
            "SET",
            read_capture(io.StringIO(bad_anchor)),
            measurements,
            {"run-00": RunCondition("nominal", 5)},
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("OUT fetch" in item for item in observation.warnings))

        post = list(PRE_VECTORS["SET"])
        post[4] &= ~0x4000
        observation = _direct_observation("SET", post=tuple(post))
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("unchanged OVM" in item for item in observation.warnings))

    def test_partial_extra_and_truncated_windows_remain_explicit(self) -> None:
        text, measurements = _capture_text([("SET", 5, 100, None)])
        lines = text.splitlines()
        terminal_output = next(
            index for index, line in enumerate(lines) if line.endswith("0x007,0x00af")
        )
        partial_lines = lines[:terminal_output] + lines[terminal_output + 1 :]
        for sample, index in enumerate(range(1, len(partial_lines)), start=0):
            fields = partial_lines[index].split(",")
            fields[1] = str(sample)
            partial_lines[index] = ",".join(fields)
        observation = analyze_fixture(
            "SET",
            read_capture(io.StringIO("\n".join(partial_lines) + "\n")),
            measurements,
            {"run-00": RunCondition("nominal", 5)},
        )[0]
        self.assertEqual(observation.classification, "PARTIAL_OUTPUT_STREAM_027")
        self.assertFalse(observation.capture_complete)

        extra = lines[:terminal_output] + [lines[terminal_output]] + [lines[terminal_output]] + lines[terminal_output + 1 :]
        for sample, index in enumerate(range(1, len(extra)), start=0):
            fields = extra[index].split(",")
            fields[1] = str(sample)
            fields[2] = str(sample * 100)
            extra[index] = ",".join(fields)
        shifted_measurement = {
            "run-00": measurements["run-00"],
        }
        observation = analyze_fixture(
            "SET",
            read_capture(io.StringIO("\n".join(extra) + "\n")),
            shifted_measurement,
            {"run-00": RunCondition("nominal", 5)},
        )[0]
        self.assertEqual(observation.classification, "EXTRA_OUTPUT_STREAM_029")
        self.assertFalse(observation.capture_complete)

        truncated = "\n".join(lines[:-1]) + "\n"
        with self.assertRaises(CaptureError):
            analyze_fixture(
                "SET",
                read_capture(io.StringIO(truncated)),
                measurements,
                {"run-00": RunCondition("nominal", 5)},
            )

    def test_condition_matrix_measurement_hash_and_exact_images_gate_review(self) -> None:
        with self.assertRaises(CaptureError):
            read_capture(io.StringIO("run,sample\nrun-0,0\n"))
        with self.assertRaises(CaptureError):
            read_reset_measurements(
                io.StringIO(
                    ",".join(RESET_COLUMNS)
                    + "\nrun-0,200,100,50\n"
                )
            )
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            set_paths = _write_fixture_package(root, "SET", nominal_runs=3)
            clear_paths = _write_fixture_package(root, "CLEAR", nominal_runs=3)
            report = build_report(
                set_paths["capture"], clear_paths["capture"],
                set_paths["reset"], clear_paths["reset"],
                minimum_nominal_runs=4,
                set_metadata=set_paths["metadata"], clear_metadata=clear_paths["metadata"],
                set_image=set_paths["image"], clear_image=clear_paths["image"],
                artifact_root=root,
            )
            self.assertFalse(report.minimum_nominal_runs_met)
            self.assertTrue(report.condition_coverage_complete)
            self.assertFalse(report.review_ready)

            report = build_report(
                set_paths["capture"], clear_paths["capture"],
                set_paths["reset"], clear_paths["reset"],
                minimum_nominal_runs=3,
                set_metadata=set_paths["metadata"], clear_metadata=clear_paths["metadata"],
                set_image=set_paths["image"], clear_image=clear_paths["image"],
                artifact_root=root,
            )
            self.assertTrue(report.review_ready)
            self.assertTrue(report.observed_full_retention_candidate)

            clear_paths["image"].write_bytes(b"\x00" + clear_paths["image"].read_bytes()[1:])
            metadata = json.loads(clear_paths["metadata"].read_text(encoding="utf-8"))
            metadata["program_image_sha256"] = sha256(clear_paths["image"].read_bytes()).hexdigest()
            metadata["reset_measurements_sha256"] = "0" * 64
            clear_paths["metadata"].write_text(json.dumps(metadata, indent=2), encoding="utf-8")
            report = build_report(
                set_paths["capture"], clear_paths["capture"],
                set_paths["reset"], clear_paths["reset"],
                minimum_nominal_runs=1,
                set_metadata=set_paths["metadata"], clear_metadata=clear_paths["metadata"],
                set_image=set_paths["image"], clear_image=clear_paths["image"],
                artifact_root=root,
            )
            clear_summary = {item.fixture: item for item in report.fixtures}["CLEAR"]
            self.assertFalse(clear_summary.evidence_package.complete)
            self.assertTrue(any("exact sparse" in item for item in clear_summary.evidence_package.errors))
            self.assertTrue(any("measurements SHA-256 mismatch" in item for item in clear_summary.evidence_package.errors))
            self.assertFalse(report.review_ready)


if __name__ == "__main__":
    unittest.main()
