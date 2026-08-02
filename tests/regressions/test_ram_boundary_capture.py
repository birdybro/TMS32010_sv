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
from tools.trace.ram_boundary_capture import (
    BASE_WORDS,
    BOUNDARY_WORD,
    DEFINED_SCAN,
    REGISTER_COLUMNS,
    RegisterObservation,
    analyze_experiment,
    build_report,
    main,
    read_register_observations,
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
    experiment: str,
    run: str,
    sequence: tuple[int, ...],
    *,
    pending_scan_fetch: bool = False,
    diagnostic_fetch: bool = True,
) -> list[str]:
    events: list[tuple[int, int, int, int, int]] = [
        (0x011, BOUNDARY_WORD[experiment], 0, 1, 1),
    ]
    for value in sequence[:144]:
        events.extend(
            (
                (0x013, 0x4F88, 0, 1, 1),
                (7, value, 1, 0, 1),
            )
        )
    if pending_scan_fetch and len(sequence) < 144:
        events.append((0x013, 0x4F88, 0, 1, 1))
    if len(sequence) >= 145:
        events.extend(
            (
                (0x016, 0x4F10, 0, 1, 1),
                (7, sequence[144], 1, 0, 1),
            )
        )
        for value in sequence[145:]:
            events.append((7, value, 1, 0, 1))
    elif len(sequence) == 144 and diagnostic_fetch:
        events.append((0x016, 0x4F10, 0, 1, 1))
    if len(sequence) >= 145:
        events.append((0x018, 0xF900, 0, 1, 1))
        trailing_count = 3
    else:
        trailing_count = 4
    events.extend((0x017, 0x7F80, 0, 1, 1) for _ in range(trailing_count))
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
    experiment: str,
    sequences: list[tuple[int, ...]],
    **run_options: bool,
) -> str:
    rows = [",".join(CAPTURE_COLUMNS)]
    for index, sequence in enumerate(sequences):
        rows.extend(
            _run_rows(
                experiment,
                f"run-{index:02d}",
                sequence,
                **run_options,
            )
        )
    return "\n".join(rows) + "\n"


def _binary(experiment: str) -> bytes:
    words = list(BASE_WORDS)
    words[0x011] = BOUNDARY_WORD[experiment]
    return b"".join(word.to_bytes(2, byteorder="big") for word in words)


def _register(
    experiment: str,
    run: str,
    transcript_hash: str,
    **changes: int,
) -> RegisterObservation:
    values = {
        "acc": 0x00000007 if experiment == "DMOV" else 0x00000016,
        "t": 0x0003 if experiment == "DMOV" else 0x005A,
        "p": 0x0000000F,
        "ov": 1,
        "ovm": 1,
        "dp": 1,
        "arp": 0,
        "ar0": 0x01FF,
        "ar1": 0xFFFF,
    }
    values.update(changes)
    return RegisterObservation(
        experiment=experiment,
        run=run,
        transcript_sha256=transcript_hash,
        **values,
    )


def _register_csv(observations: list[RegisterObservation]) -> str:
    rows = [",".join(REGISTER_COLUMNS)]
    for item in observations:
        rows.append(
            ",".join(
                (
                    item.experiment,
                    item.run,
                    f"0x{item.acc:08x}",
                    f"0x{item.t:04x}",
                    f"0x{item.p:08x}",
                    str(item.ov),
                    str(item.ovm),
                    str(item.dp),
                    str(item.arp),
                    f"0x{item.ar0:04x}",
                    f"0x{item.ar1:04x}",
                    item.transcript_sha256,
                )
            )
        )
    return "\n".join(rows) + "\n"


def _write_evidence_package(
    root: Path,
    dmov_sequences: list[tuple[int, ...]],
    ltd_sequences: list[tuple[int, ...]],
    *,
    register_changes: dict[tuple[str, str], dict[str, int]] | None = None,
) -> dict[str, Path]:
    register_changes = register_changes or {}
    paths: dict[str, Path] = {}
    transcript_hashes: dict[str, str] = {}
    specimen_photos: dict[str, dict[str, str]] = {}
    for view in ("top", "bottom", "board_context"):
        photo = root / f"specimen-{view}.jpg"
        photo.write_bytes(f"synthetic {view} specimen view".encode("ascii"))
        specimen_photos[view] = {
            "path": photo.name,
            "sha256": sha256(photo.read_bytes()).hexdigest(),
        }
    for experiment in ("DMOV", "LTD"):
        lower = experiment.lower()
        capture = root / f"{lower}.csv"
        sequences = dmov_sequences if experiment == "DMOV" else ltd_sequences
        capture.write_text(_capture_text(experiment, sequences), encoding="utf-8")
        paths[f"{lower}_capture"] = capture
        image = root / f"{lower}.bin"
        image.write_bytes(_binary(experiment))
        paths[f"{lower}_image"] = image
        raw = root / f"{lower}.sal"
        raw.write_bytes(f"raw {experiment} capture".encode("ascii"))
        paths[f"{lower}_raw"] = raw
        transcript = root / f"{lower}_transcript.txt"
        transcript.write_text(
            f"synthetic {experiment} EVM register transcript\n",
            encoding="utf-8",
        )
        paths[f"{lower}_transcript"] = transcript
        transcript_hashes[experiment] = sha256(transcript.read_bytes()).hexdigest()
        photograph = root / f"{lower}.jpg"
        photograph.write_bytes(f"{experiment} probe photograph".encode("ascii"))
        paths[f"{lower}_photo"] = photograph
        fixture_source = root / f"ram_boundary_{lower}_probe.asm"
        fixture_source.write_bytes(
            (
                ROOT / "tests" / "asm" / f"ram_boundary_{lower}_probe.asm"
            ).read_bytes()
        )
        paths[f"{lower}_source"] = fixture_source
        fixture_listing = root / f"ram_boundary_{lower}_probe.lst"
        image_bytes = image.read_bytes()
        fixture_listing.write_text(
            "".join(
                f"{address:03x} {word:04x} synthetic:test\n"
                for address, word in enumerate(
                    int.from_bytes(image_bytes[offset : offset + 2], "big")
                    for offset in range(0, len(image_bytes), 2)
                )
            ),
            encoding="utf-8",
        )
        paths[f"{lower}_listing"] = fixture_listing

    observations = []
    for experiment, sequences in (("DMOV", dmov_sequences), ("LTD", ltd_sequences)):
        for index in range(len(sequences)):
            run = f"run-{index:02d}"
            observations.append(
                _register(
                    experiment,
                    run,
                    transcript_hashes[experiment],
                    **register_changes.get((experiment, run), {}),
                )
            )
    state = root / "registers.csv"
    state.write_text(_register_csv(observations), encoding="utf-8")
    paths["registers"] = state
    state_hash = sha256(state.read_bytes()).hexdigest()

    for experiment in ("DMOV", "LTD"):
        lower = experiment.lower()
        metadata = root / f"{lower}_metadata.json"
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
                    "monitor_revision": "synthetic monitor",
                    "specimen_scope": "this_specimen_only",
                    "board_revision": "synthetic test fixture",
                    "oscillator_hz": 20_000_000,
                    "supply_voltage_v": "5.00 measured",
                    "program_memory": "synthetic memory",
                    "program_memory_access_time_ns": 35.0,
                    "probe_model": "synthetic probe",
                    "analyzer_model": "synthetic analyzer",
                    "analyzer_firmware": "test",
                    "program_image_sha256": sha256(
                        paths[f"{lower}_image"].read_bytes()
                    ).hexdigest(),
                    "normalized_capture_sha256": sha256(
                        paths[f"{lower}_capture"].read_bytes()
                    ).hexdigest(),
                    "register_observations_sha256": state_hash,
                    "fixture_tool_versions": {
                        "assembler": "project test assembler",
                        "capture_normalizer": "synthetic test normalizer",
                        "analyzer_decoder": "synthetic test decoder",
                    },
                    "fixture_artifacts": {
                        "source": {
                            "path": paths[f"{lower}_source"].name,
                            "sha256": sha256(
                                paths[f"{lower}_source"].read_bytes()
                            ).hexdigest(),
                        },
                        "listing": {
                            "path": paths[f"{lower}_listing"].name,
                            "sha256": sha256(
                                paths[f"{lower}_listing"].read_bytes()
                            ).hexdigest(),
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
                        paths[f"{lower}_raw"].name: sha256(
                            paths[f"{lower}_raw"].read_bytes()
                        ).hexdigest(),
                        paths[f"{lower}_transcript"].name: transcript_hashes[
                            experiment
                        ],
                    },
                    "probe_photographs": {
                        paths[f"{lower}_photo"].name: sha256(
                            paths[f"{lower}_photo"].read_bytes()
                        ).hexdigest(),
                    },
                    "specimen_photographs": specimen_photos,
                },
                indent=2,
            ),
            encoding="utf-8",
        )
        paths[f"{lower}_metadata"] = metadata
    return paths


class RamBoundaryCaptureTests(unittest.TestCase):
    def test_complete_scan_preserves_diagnostic_alias_and_corruption_results(
        self,
    ) -> None:
        unchanged = DEFINED_SCAN + (0xCAFE,)
        changed = list(DEFINED_SCAN)
        changed[5] = 0x1234
        changed_sequence = tuple(changed) + (0xBEEF,)
        cases = (
            (unchanged, "COMPLETE_SCAN_UNCHANGED_DIAGNOSTIC_cafe", ()),
            (changed_sequence, "COMPLETE_SCAN_CHANGED_001_DIAGNOSTIC_beef", (0x8A,)),
        )
        for sequence, classification, addresses in cases:
            with self.subTest(classification=classification):
                runs = read_normalized_capture(
                    io.StringIO(_capture_text("DMOV", [sequence]))
                )
                observation = analyze_experiment("DMOV", runs, {})[0]
                self.assertEqual(observation.classification, classification)
                self.assertEqual(observation.changed_valid_addresses, addresses)
                self.assertEqual(observation.diagnostic_word, sequence[-1])
                self.assertTrue(observation.capture_complete)
                self.assertTrue(observation.fixture_valid)

    def test_partial_and_extra_flows_are_retained_without_expected_values(
        self,
    ) -> None:
        cases = (
            ((), "NONCOMPLETION_AFTER_BOUNDARY_FETCH", True),
            (DEFINED_SCAN[:10], "PARTIAL_VALID_SCAN_010", True),
            (DEFINED_SCAN, "VALID_SCAN_COMPLETE_NO_DIAGNOSTIC_OUTPUT", True),
            (DEFINED_SCAN + (0x1111, 0x2222), "EXTRA_OUTPUTS_146", False),
        )
        for sequence, classification, fixture_valid in cases:
            with self.subTest(classification=classification):
                text = _capture_text(
                    "DMOV",
                    [sequence],
                    pending_scan_fetch=len(sequence) < 144,
                )
                observation = analyze_experiment(
                    "DMOV",
                    read_normalized_capture(io.StringIO(text)),
                    {},
                )[0]
                self.assertEqual(observation.classification, classification)
                self.assertEqual(observation.fixture_valid, fixture_valid)
                self.assertFalse(observation.capture_complete)

    def test_anchors_controls_terminal_and_trailing_window_are_checked(self) -> None:
        good = _capture_text("DMOV", [DEFINED_SCAN + (0xCAFE,)])
        missing_boundary = good.replace("0x011,0x690f", "0x011,0x690e", 1)
        with self.assertRaises(CaptureError):
            analyze_experiment(
                "DMOV",
                read_normalized_capture(io.StringIO(missing_boundary)),
                {},
            )
        truncated = "\n".join(good.splitlines()[:-1]) + "\n"
        with self.assertRaises(CaptureError):
            analyze_experiment(
                "DMOV",
                read_normalized_capture(io.StringIO(truncated)),
                {},
            )

        bad_control = good.replace(
            ",1,1,0,1,0x007,0x005a",
            ",1,0,0,1,0x007,0x005a",
            1,
        )
        observation = analyze_experiment(
            "DMOV",
            read_normalized_capture(io.StringIO(bad_control)),
            {},
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("exclusive" in item for item in observation.warnings))

        no_terminal = good.replace("0x018,0xf900", "0x018,0xf901", 1)
        observation = analyze_experiment(
            "DMOV",
            read_normalized_capture(io.StringIO(no_terminal)),
            {},
        )[0]
        self.assertFalse(observation.fixture_valid)
        self.assertTrue(any("terminal" in item for item in observation.warnings))

    def test_register_schema_and_only_documented_fixture_state_are_checked(
        self,
    ) -> None:
        transcript_hash = "a" * 64
        register = _register("LTD", "run-00", transcript_hash)
        parsed = read_register_observations(
            io.StringIO(_register_csv([register]))
        )
        runs = read_normalized_capture(
            io.StringIO(_capture_text("LTD", [DEFINED_SCAN + (0x1234,)]))
        )
        observation = analyze_experiment("LTD", runs, parsed)[0]
        self.assertTrue(observation.documented_register_effects_match)
        self.assertEqual(observation.register_observation.ov, 1)
        self.assertEqual(observation.register_observation.ovm, 1)
        self.assertEqual(observation.register_observation.ar1, 0xFFFF)

        mismatched = _register("LTD", "run-00", transcript_hash, t=0x005B)
        observation = analyze_experiment(
            "LTD",
            runs,
            {("LTD", "run-00"): mismatched},
        )[0]
        self.assertFalse(observation.documented_register_effects_match)
        self.assertTrue(any("t observed" in item for item in observation.register_differences))

        duplicated = _register_csv([register, register])
        with self.assertRaises(CaptureError):
            read_register_observations(io.StringIO(duplicated))
        invalid_flag = _register_csv([register]).replace(",1,1,1,0,", ",1,2,1,0,")
        with self.assertRaises(CaptureError):
            read_register_observations(io.StringIO(invalid_flag))

    def test_complete_variable_package_is_review_ready_but_not_acceptance_complete(
        self,
    ) -> None:
        dmov_changed = list(DEFINED_SCAN)
        dmov_changed[5] = 0x1234
        dmov_sequences = [
            DEFINED_SCAN + (0x1111,),
            tuple(dmov_changed) + (0x2222,),
        ]
        ltd_sequences = [DEFINED_SCAN + (0x3333,)] * 2
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            paths = _write_evidence_package(
                root,
                dmov_sequences,
                ltd_sequences,
                register_changes={("LTD", "run-01"): {"acc": 0x17}},
            )
            report = build_report(
                paths["dmov_capture"],
                paths["ltd_capture"],
                minimum_runs=2,
                dmov_metadata=paths["dmov_metadata"],
                ltd_metadata=paths["ltd_metadata"],
                dmov_image=paths["dmov_image"],
                ltd_image=paths["ltd_image"],
                register_observations=paths["registers"],
                artifact_root=root,
            )
            self.assertTrue(report.minimum_runs_met)
            self.assertTrue(report.complete)
            self.assertTrue(report.fixture_valid)
            self.assertTrue(report.register_evidence.complete)
            self.assertTrue(report.review_ready)
            self.assertFalse(report.acceptance_complete)
            self.assertEqual(report.specimen_id, "synthetic-specimen-01")
            self.assertEqual(report.specimen_scope, "this_specimen_only")
            self.assertEqual(report.specimen_pair_errors, ())
            self.assertFalse(report.documented_register_effects_match)
            summaries = {item.experiment: item for item in report.experiments}
            self.assertFalse(summaries["DMOV"].repeatable)
            self.assertTrue(summaries["LTD"].repeatable)
            self.assertEqual(
                len(summaries["DMOV"].evidence_package.verified_artifacts),
                8,
            )
            self.assertEqual(
                len(summaries["LTD"].evidence_package.verified_artifacts),
                8,
            )
            encoded = json.dumps(report.to_json_object(), sort_keys=True)
            self.assertIn("does not change OQ-014", encoded)
            self.assertIn("varied-history/sentinel behavior", encoded)

            output = io.StringIO()
            with redirect_stdout(output):
                return_code = main(
                    (
                        str(paths["dmov_capture"]),
                        str(paths["ltd_capture"]),
                        "--minimum-runs",
                        "2",
                        "--dmov-metadata",
                        str(paths["dmov_metadata"]),
                        "--ltd-metadata",
                        str(paths["ltd_metadata"]),
                        "--dmov-image",
                        str(paths["dmov_image"]),
                        "--ltd-image",
                        str(paths["ltd_image"]),
                        "--register-observations",
                        str(paths["registers"]),
                        "--artifact-root",
                        str(root),
                        "--require-review-ready",
                    )
                )
            self.assertEqual(return_code, 0)
            self.assertTrue(json.loads(output.getvalue())["review_ready"])

    def test_wrong_image_or_unpinned_register_state_blocks_review(self) -> None:
        sequence = DEFINED_SCAN + (0xCAFE,)
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            paths = _write_evidence_package(root, [sequence], [sequence])
            paths["dmov_image"].write_bytes(b"\x00" + _binary("DMOV")[1:])
            metadata = json.loads(paths["dmov_metadata"].read_text(encoding="utf-8"))
            metadata["program_image_sha256"] = sha256(
                paths["dmov_image"].read_bytes()
            ).hexdigest()
            metadata.pop("register_observations_sha256")
            listing = paths["dmov_listing"]
            listing.write_text(
                listing.read_text(encoding="utf-8").replace(
                    "011 690f", "011 690e"
                ),
                encoding="utf-8",
            )
            metadata["fixture_artifacts"]["listing"]["sha256"] = sha256(
                listing.read_bytes()
            ).hexdigest()
            paths["dmov_metadata"].write_text(
                json.dumps(metadata, indent=2),
                encoding="utf-8",
            )
            ltd_metadata = json.loads(
                paths["ltd_metadata"].read_text(encoding="utf-8")
            )
            ltd_metadata["specimen_id"] = "synthetic-specimen-02"
            paths["ltd_metadata"].write_text(
                json.dumps(ltd_metadata, indent=2),
                encoding="utf-8",
            )
            report = build_report(
                paths["dmov_capture"],
                paths["ltd_capture"],
                minimum_runs=1,
                dmov_metadata=paths["dmov_metadata"],
                ltd_metadata=paths["ltd_metadata"],
                dmov_image=paths["dmov_image"],
                ltd_image=paths["ltd_image"],
                register_observations=paths["registers"],
                artifact_root=root,
            )
            self.assertFalse(report.review_ready)
            self.assertFalse(report.register_evidence.complete)
            self.assertIsNone(report.specimen_id)
            self.assertEqual(report.specimen_scope, "UNQUALIFIED")
            self.assertTrue(
                any(
                    "specimen specimen_id" in error
                    for error in report.specimen_pair_errors
                )
            )
            dmov = {item.experiment: item for item in report.experiments}["DMOV"]
            self.assertFalse(dmov.evidence_package.complete)
            self.assertTrue(
                any("exact big-endian" in error for error in dmov.evidence_package.errors)
            )
            self.assertTrue(
                any("does not pin" in error for error in report.register_evidence.errors)
            )
            self.assertTrue(
                any(
                    "exact address/word map" in error
                    for error in dmov.evidence_package.errors
                )
            )


if __name__ == "__main__":
    unittest.main()
