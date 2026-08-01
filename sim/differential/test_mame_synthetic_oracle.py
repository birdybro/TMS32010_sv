from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.reference.mame_synthetic_oracle import (
    FIXTURE,
    SyntheticOracleError,
    _program_words,
    _resolve_mame,
    build_debug_script,
    build_model_trace,
)
from tools.reference.mame_synthetic_roms import (
    MAX_FILE_BYTES,
    SyntheticRomError,
    create_placeholders,
    read_machine_roms,
)
from tools.reference.mame_trace import parse_model_trace

ROOT = Path(__file__).resolve().parents[2]


class MameSyntheticRomTests(unittest.TestCase):
    def test_listxml_metadata_is_deduplicated_and_versioned(self) -> None:
        xml = """<?xml version="1.0"?>
        <mame>
          <machine name="other"><rom name="ignored.bin" size="2"/></machine>
          <machine name="harddriv">
            <rom name="b.bin" size="8"/>
            <rom name="a.bin" size="4"/>
            <rom name="a.bin" size="4"/>
          </machine>
        </mame>
        """
        results = [
            subprocess.CompletedProcess([], 0, "0.287-test\n", ""),
            subprocess.CompletedProcess([], 0, xml, ""),
        ]
        with patch(
            "tools.reference.mame_synthetic_roms._run_metadata",
            side_effect=results,
        ):
            version, files = read_machine_roms(Path("mame"), "harddriv")
        self.assertEqual(version, "0.287-test")
        self.assertEqual(files, [("a.bin", 4), ("b.bin", 8)])

    def test_listxml_rejects_unsafe_names_and_sizes(self) -> None:
        cases = (
            ('<rom name="../escape.bin" size="4"/>', "unsafe"),
            (
                f'<rom name="huge.bin" size="{MAX_FILE_BYTES + 1}"/>',
                "safety limit",
            ),
        )
        for rom, diagnostic in cases:
            with self.subTest(rom=rom):
                xml = f'<mame><machine name="harddriv">{rom}</machine></mame>'
                results = [
                    subprocess.CompletedProcess([], 0, "test\n", ""),
                    subprocess.CompletedProcess([], 0, xml, ""),
                ]
                with patch(
                    "tools.reference.mame_synthetic_roms._run_metadata",
                    side_effect=results,
                ):
                    with self.assertRaisesRegex(SyntheticRomError, diagnostic):
                        read_machine_roms(Path("mame"), "harddriv")

    def test_placeholder_creation_is_idempotent_and_refuses_overwrite(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            first = create_placeholders(
                root,
                "harddriv",
                [("a.bin", 4), ("b.bin", 2)],
                fill_byte=0,
                mame_path=Path("/test/mame"),
                mame_version="test",
            )
            second = create_placeholders(
                root,
                "harddriv",
                [("a.bin", 4), ("b.bin", 2)],
                fill_byte=0,
                mame_path=Path("/test/mame"),
                mame_version="test",
            )
            self.assertEqual(first, second)
            self.assertEqual((root / "harddriv" / "a.bin").read_bytes(), b"\0" * 4)
            manifest = json.loads(
                (root / "harddriv" / "synthetic_manifest.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(manifest["total_bytes"], 6)
            (root / "harddriv" / "a.bin").write_bytes(b"user")
            with self.assertRaisesRegex(SyntheticRomError, "refusing to overwrite"):
                create_placeholders(
                    root,
                    "harddriv",
                    [("a.bin", 4), ("b.bin", 2)],
                    fill_byte=0,
                    mame_path=Path("/test/mame"),
                    mame_version="test",
                )


class MameSyntheticOracleTests(unittest.TestCase):
    def test_bare_mame_name_must_resolve_from_path(self) -> None:
        with patch(
            "tools.reference.mame_synthetic_oracle.shutil.which",
            return_value="/trusted/bin/mame",
        ):
            self.assertEqual(_resolve_mame(Path("mame")), Path("/trusted/bin/mame"))
        with patch(
            "tools.reference.mame_synthetic_oracle.shutil.which", return_value=None
        ):
            with self.assertRaisesRegex(SyntheticOracleError, "not on PATH"):
                _resolve_mame(Path("mame"))

    def test_debug_script_uses_hand_fixture_and_two_stage_focus(self) -> None:
        words = _program_words(ROOT)
        script = build_debug_script(words, Path("build/mame/mame.tr"))
        lines = script.splitlines()
        self.assertEqual(len(lines), 2)
        self.assertEqual(FIXTURE, Path("tests/asm/push_pop_bus_probe.asm"))
        self.assertIn("sounddsp.pw@1 = 7f9c", lines[0])
        self.assertIn("sounddsp.pw@4 = 7f9d", lines[0])
        self.assertIn("soundcpu.pw!ff1018 = 0", lines[0])
        self.assertTrue(lines[0].endswith("focus mainpcb:harddriv_sound:sounddsp"))
        self.assertIn("TMS32010_STATE", lines[1])
        self.assertIn("bp 6,1", lines[1])
        self.assertTrue(lines[1].endswith("traceflush ; quit} ; go"))

    def test_model_trace_starts_after_prime_and_has_expected_stack_effects(self) -> None:
        words = _program_words(ROOT)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "model.jsonl"
            build_model_trace(words, path)
            records = parse_model_trace(path)
        self.assertEqual(
            [record.mnemonic for record in records],
            ["PUSH", "NOP", "LACK", "POP", "NOP"],
        )
        self.assertEqual(records[0].state_after["stack"], [0x55, 0, 0, 0])
        self.assertEqual(records[2].state_after["acc"], 0xAA)
        self.assertEqual(records[3].state_after["acc"], 0x55)
        self.assertEqual(records[3].state_after["stack"], [0, 0, 0, 0])
        self.assertEqual(records[-1].state_after["pc"], 6)


if __name__ == "__main__":
    unittest.main()
