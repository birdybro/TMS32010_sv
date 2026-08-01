from __future__ import annotations

import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from tools.reference.hard_drivin_sample_roms import (
    BLOCK_TO_SOCKET,
    SAMPLE_ROM_BYTES,
    SampleRomError,
    analyze_files,
    analyze_sample_roms,
    main,
)


class HardDrivinSampleRomTests(unittest.TestCase):
    def test_primary_socket_order_keeps_45c_at_physical_block_eight(self) -> None:
        self.assertEqual(
            BLOCK_TO_SOCKET,
            (
                "65A",
                "55A",
                "45A",
                "30A",
                "20A",
                "5A",
                "65C",
                "55C",
                "45C",
                "30C",
                "20C",
                "5C",
            ),
        )

    def test_sparse_images_emit_physical_presence_mask_without_population_claim(self) -> None:
        report = analyze_sample_roms(
            {
                "65a": bytes([0x11]) * SAMPLE_ROM_BYTES,
                "45C": bytes([0x88]) * SAMPLE_ROM_BYTES,
            }
        )

        self.assertEqual(report["present_blocks"], [0, 8])
        self.assertEqual(report["present_mask_12bit"], 0x101)
        self.assertEqual(report["present_mask_hex"], "0x101")
        self.assertEqual(report["undecoded_block_values"], [12, 13, 14, 15])
        self.assertFalse(report["physical_population_proven"])
        self.assertEqual(
            [(entry["block"], entry["socket"]) for entry in report["images"]],
            [(0, "65A"), (8, "45C")],
        )

    def test_unknown_duplicate_and_wrong_size_inputs_fail_closed(self) -> None:
        with self.assertRaisesRegex(SampleRomError, "unknown"):
            analyze_sample_roms({"40A": bytes(SAMPLE_ROM_BYTES)})
        with self.assertRaisesRegex(SampleRomError, "exactly"):
            analyze_sample_roms({"65A": bytes(0x8000)})
        with self.assertRaisesRegex(SampleRomError, "duplicate"):
            analyze_files(("45c=/first", "45C=/second"))

    def test_cli_is_deterministic_and_emits_no_sample_bytes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "45c.bin"
            path.write_bytes(bytes([0xA5]) * SAMPLE_ROM_BYTES)
            argv = ("--socket", f"45C={path}")
            first = io.StringIO()
            second = io.StringIO()
            with patch("sys.stdout", first):
                self.assertEqual(main(argv), 0)
            with patch("sys.stdout", second):
                self.assertEqual(main(argv), 0)

        self.assertEqual(first.getvalue(), second.getvalue())
        report = json.loads(first.getvalue())
        self.assertEqual(report["present_blocks"], [8])
        self.assertFalse(report["physical_population_proven"])
        self.assertNotIn("a5a5a5", first.getvalue().lower())


if __name__ == "__main__":
    unittest.main()
