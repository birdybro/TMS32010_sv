from __future__ import annotations

import io
import unittest
from fractions import Fraction

from tools.trace.hard_drivin_dac_codes import (
    DAC_LEVELS,
    FEEDBACK_OHMS,
    REFERENCE_OHMS,
    REFERENCE_VOLTS,
    ideal_board_dacout_volts,
    ideal_board_iout_amps,
    interpret_word,
    mame_dac_code,
    parse_word,
    raw_dac_code,
    signed_12bit,
    write_csv,
)


class HardDrivinDacCodeTests(unittest.TestCase):
    def test_all_words_preserve_raw_high_twelve_bits_and_low_aliases(self) -> None:
        for word in range(0x10000):
            self.assertEqual(raw_dac_code(word), word >> 4)
            self.assertEqual(mame_dac_code(word), (word >> 4) ^ 0x800)

        for code in range(DAC_LEVELS):
            aliases = {raw_dac_code((code << 4) | low) for low in range(16)}
            self.assertEqual(aliases, {code})

    def test_signed_interpretation_and_major_boundary_are_explicit(self) -> None:
        self.assertEqual(signed_12bit(0x000), 0)
        self.assertEqual(signed_12bit(0x7FF), 2047)
        self.assertEqual(signed_12bit(0x800), -2048)
        self.assertEqual(signed_12bit(0xFFF), -1)
        self.assertEqual(mame_dac_code(0xF230), 0x723)

        physical_step = ideal_board_dacout_volts(0x800) - ideal_board_dacout_volts(
            0x7FF
        )
        one_lsb_step = ideal_board_dacout_volts(1) - ideal_board_dacout_volts(0)
        self.assertEqual(physical_step, one_lsb_step)
        self.assertEqual(signed_12bit(0x800) - signed_12bit(0x7FF), -4095)

    def test_ideal_nominal_transfer_uses_primary_component_values(self) -> None:
        self.assertEqual(ideal_board_iout_amps(0), 0)
        self.assertEqual(ideal_board_dacout_volts(0), 0)
        expected_full_scale = (
            -FEEDBACK_OHMS
            * 4
            * REFERENCE_VOLTS
            * 0xFFF
            / (REFERENCE_OHMS * DAC_LEVELS)
        )
        self.assertEqual(ideal_board_dacout_volts(0xFFF), expected_full_scale)
        self.assertLess(ideal_board_dacout_volts(0xFFF), Fraction(-7, 1))
        self.assertGreater(ideal_board_dacout_volts(0xFFF), Fraction(-8, 1))

    def test_rows_and_csv_keep_physical_and_oracle_codes_separate(self) -> None:
        row = interpret_word(0xF23F)
        self.assertEqual(row.raw_code, 0xF23)
        self.assertEqual(row.mame_code, 0x723)
        self.assertEqual(row.signed_code, -221)

        output = io.StringIO()
        write_csv((0x0000, 0x800F, 0xF23F), output)
        self.assertEqual(
            output.getvalue().splitlines()[:2],
            [
                "tms_word,raw_am6012_code,mame_mapper_code,signed_12bit,ideal_iout_ma,ideal_dacout_v",
                "0x0000,0x000,0x800,0,0.000000000,0.000000000",
            ],
        )
        self.assertIn("0x800f,0x800,0x000,-2048", output.getvalue())
        self.assertIn("0xf23f,0xf23,0x723,-221", output.getvalue())

    def test_hex_parser_fails_closed(self) -> None:
        self.assertEqual(parse_word("f23f"), 0xF23F)
        self.assertEqual(parse_word("0xF2_3F"), 0xF23F)
        for malformed in ("", "0x", "10000", "-1", "zzzz"):
            with self.subTest(malformed=malformed):
                with self.assertRaises(ValueError):
                    parse_word(malformed)


if __name__ == "__main__":
    unittest.main()
