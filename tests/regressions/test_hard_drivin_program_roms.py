from __future__ import annotations

from hashlib import sha256
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from tools.reference.hard_drivin_program_roms import (
    EPROM_27256_BYTES,
    EPROM_27512_BYTES,
    ProgramRomError,
    analyze_program_roms,
    interleave_program_lanes,
    main,
)


class HardDrivinProgramRomTests(unittest.TestCase):
    def test_27256_sized_pair_hashes_without_claiming_a_physical_strap(self) -> None:
        upper = bytes((index * 3) & 0xFF for index in range(EPROM_27256_BYTES))
        lower = bytes((index * 5 + 1) & 0xFF for index in range(EPROM_27256_BYTES))
        report = analyze_program_roms(upper, lower)

        self.assertEqual(report["size_class"], "27256-sized")
        self.assertIsNone(report["a16_information_bearing"])
        self.assertEqual(
            report["strap_implication"],
            "E1_if_each_file_is_a_complete_27256_image",
        )
        self.assertFalse(report["physical_strap_proven"])
        self.assertEqual(report["interleaved_bytes"], 0x10000)
        self.assertEqual(
            report["interleaved_sha256"],
            sha256(interleave_program_lanes(upper, lower)).hexdigest(),
        )
        self.assertIsNone(
            report["lanes"]["70n_upper_even"]["upper_32k_equals_lower_32k"]
        )

    def test_distinct_27512_halves_make_a16_information_bearing(self) -> None:
        upper = bytes(EPROM_27256_BYTES) + bytes([0xA5]) * EPROM_27256_BYTES
        lower = bytes([0x5A]) * EPROM_27256_BYTES + bytes(
            [0xC3]
        ) * EPROM_27256_BYTES
        report = analyze_program_roms(upper, lower)

        self.assertEqual(report["size_class"], "27512-sized")
        self.assertTrue(report["a16_information_bearing"])
        self.assertEqual(
            report["strap_implication"],
            "E2_required_to_execute_both_distinct_32k_halves",
        )
        self.assertFalse(
            report["lanes"]["70n_upper_even"]["upper_32k_equals_lower_32k"]
        )
        self.assertFalse(
            report["lanes"]["45n_lower_odd"]["upper_32k_equals_lower_32k"]
        )

    def test_repeated_27512_halves_are_explicitly_ambiguous(self) -> None:
        upper_half = bytes(
            (index * 7) & 0xFF for index in range(EPROM_27256_BYTES)
        )
        lower_half = bytes(
            (index * 11) & 0xFF for index in range(EPROM_27256_BYTES)
        )
        report = analyze_program_roms(upper_half * 2, lower_half * 2)

        self.assertFalse(report["a16_information_bearing"])
        self.assertEqual(report["strap_implication"], "ambiguous_mirrored_64k_dump")
        self.assertTrue(
            report["lanes"]["70n_upper_even"]["upper_32k_equals_lower_32k"]
        )
        self.assertTrue(
            report["lanes"]["45n_lower_odd"]["upper_32k_equals_lower_32k"]
        )

    def test_invalid_sizes_and_mismatched_lanes_fail_closed(self) -> None:
        with self.assertRaisesRegex(ProgramRomError, "documented lane sizes"):
            analyze_program_roms(bytes(0x4000), bytes(0x4000))
        with self.assertRaisesRegex(ProgramRomError, "lane sizes must match"):
            analyze_program_roms(bytes(EPROM_27256_BYTES), bytes(EPROM_27512_BYTES))

    def test_cli_is_deterministic_and_emits_no_rom_bytes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            upper_path = root / "70n.bin"
            lower_path = root / "45n.bin"
            upper_path.write_bytes(bytes([0xA5]) * EPROM_27256_BYTES)
            lower_path.write_bytes(bytes([0x5A]) * EPROM_27256_BYTES)
            first = io.StringIO()
            second = io.StringIO()
            with patch("sys.stdout", first):
                self.assertEqual(
                    main(
                        (
                            "--upper-even",
                            str(upper_path),
                            "--lower-odd",
                            str(lower_path),
                        )
                    ),
                    0,
                )
            with patch("sys.stdout", second):
                self.assertEqual(
                    main(
                        (
                            "--upper-even",
                            str(upper_path),
                            "--lower-odd",
                            str(lower_path),
                        )
                    ),
                    0,
                )

        self.assertEqual(first.getvalue(), second.getvalue())
        parsed = json.loads(first.getvalue())
        self.assertEqual(
            parsed["policy"],
            "authorized_user_supplied_data_only_no_execution",
        )
        self.assertNotIn("a5a5a5", first.getvalue().lower())
        self.assertNotIn("5a5a5a", first.getvalue().lower())


if __name__ == "__main__":
    unittest.main()
