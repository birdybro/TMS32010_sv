from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.assembler.tms32010_as import Assembler, AssemblyError
from tools.disassembler.tms32010_dis import Disassembler


class ToolchainSliceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.assembler = Assembler()
        self.disassembler = Disassembler()

    def test_supported_instruction_encodings_match_hand_fixtures(self) -> None:
        result = self.assembler.assemble_text(
            """
            LARP 0
            LARP AR1
            LDPK 0
            LDPK 1
            LARK AR0,0
            LARK AR0,255
            LARK AR1,0
            LARK AR1,255
            LACK 0
            LACK 255
            NOP
            ZAC
            ROVM
            SOVM
            LAC 0
            LAC 127,15
            LAC *
            LAC *+
            LAC *-
            LAC *+,8,AR1
            LAC *+,8,0
            SACL 0
            SACL 127,0
            SACL *
            SACL *+
            SACL *-
            SACL *,0,AR0
            SACL *+,0,1
            """
        )
        self.assertEqual(
            list(result.words.values()),
            [
                0x6880,
                0x6881,
                0x6E00,
                0x6E01,
                0x7000,
                0x70FF,
                0x7100,
                0x71FF,
                0x7E00,
                0x7EFF,
                0x7F80,
                0x7F89,
                0x7F8A,
                0x7F8B,
                0x2000,
                0x2F7F,
                0x2088,
                0x20A8,
                0x2098,
                0x28A1,
                0x28A0,
                0x5000,
                0x507F,
                0x5088,
                0x50A8,
                0x5098,
                0x5080,
                0x50A1,
            ],
        )

    def test_round_trip_preserves_supported_and_unknown_words(self) -> None:
        original = [
            0x7001,
            0x71FE,
            0x6881,
            0x6E00,
            0x7E2A,
            0x7F80,
            0x1234,
            0x7F89,
            0x7F8A,
            0x7F8B,
            0x2000,
            0x2F7F,
            0x2088,
            0x20A8,
            0x2098,
            0x28A1,
            0x28A0,
            0x2089,
            0x5000,
            0x507F,
            0x5088,
            0x50A8,
            0x5098,
            0x5080,
            0x50A1,
            0x5089,
        ]
        source = self.disassembler.disassemble_source(original)
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), original)

    def test_labels_origin_words_expressions_and_listing(self) -> None:
        result = self.assembler.assemble_text(
            """
            .org >010
            START: LACK (1 << 4) + 2
            .word START, $ + 1
            NOP ; comment
            """,
            source_name="fixture.asm",
        )
        self.assertEqual(result.symbols["START"], 0x10)
        self.assertEqual(
            result.words,
            {0x10: 0x7E12, 0x11: 0x0010, 0x12: 0x0013, 0x13: 0x7F80},
        )
        self.assertIn("010 7e12 fixture.asm:3", result.listing_text())

    def test_include_file_is_relative_and_deterministic(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "constant.inc").write_text(
                "VALUE: .word 0x1234\n",
                encoding="utf-8",
            )
            source = root / "program.asm"
            source.write_text(
                '.include "constant.inc"\nLACK VALUE + 1\n',
                encoding="utf-8",
            )
            result = self.assembler.assemble_file(source)
            self.assertEqual(result.words, {0: 0x1234, 1: 0x7E01})

    def test_binary_hex_and_listing_outputs_are_stable(self) -> None:
        result = self.assembler.assemble_text(".org 1\nNOP\nLACK 1\n")
        self.assertEqual(result.raw_bytes(), bytes.fromhex("00007f807e01"))
        self.assertEqual(
            result.raw_bytes(byteorder="little"),
            bytes.fromhex("0000807f017e"),
        )
        self.assertEqual(result.hex_text(), "0000\n7f80\n7e01\n")

    def test_lack_out_of_range_is_an_error_not_truncation(self) -> None:
        with self.assertRaisesRegex(AssemblyError, "out of range"):
            self.assembler.assemble_text("LACK 256\n")

    def test_immediate_control_operand_diagnostics(self) -> None:
        for source in ("LARP 2\n", "LDPK -1\n", "LARK AR0,256\n"):
            with self.subTest(source=source):
                with self.assertRaisesRegex(AssemblyError, "out of range"):
                    self.assembler.assemble_text(source)
        with self.assertRaisesRegex(AssemblyError, "AR0 or AR1"):
            self.assembler.assemble_text("LARK AR2,1\n")

    def test_lac_operand_diagnostics(self) -> None:
        cases = (
            ("LAC 128\n", "direct address"),
            ("LAC 0,16\n", "shift"),
            ("LAC *+,0,2\n", "next ARP"),
            ("LAC 0,0,1\n", "only with indirect"),
            ("LAC\n", "1 to 3 operands"),
        )
        for source, message in cases:
            with self.subTest(source=source):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(source)

    def test_lac_noncanonical_preserve_bit_round_trips_as_word(self) -> None:
        source = self.disassembler.disassemble_source([0x2089])
        self.assertEqual(source, ".word 0x2089\n")
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), [0x2089])

    def test_sacl_operand_diagnostics(self) -> None:
        cases = (
            ("SACL 128\n", "direct address"),
            ("SACL 0,1\n", "no shift"),
            ("SACL *+,0,2\n", "next ARP"),
            ("SACL 0,0,1\n", "only with indirect"),
            ("SACL\n", "1 to 3 operands"),
        )
        for source, message in cases:
            with self.subTest(source=source):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(source)

    def test_sacl_noncanonical_preserve_bit_round_trips_as_word(self) -> None:
        source = self.disassembler.disassemble_source([0x5089])
        self.assertEqual(source, ".word 0x5089\n")
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), [0x5089])

    def test_unsupported_documented_instruction_is_explicit(self) -> None:
        with self.assertRaisesRegex(
            AssemblyError,
            "documented instruction ADD is not implemented",
        ):
            self.assembler.assemble_text("ADD 0\n")

    def test_expression_language_rejects_code_execution(self) -> None:
        with self.assertRaisesRegex(AssemblyError, "invalid expression"):
            self.assembler.assemble_text(
                "LACK __import__('os').system('false')\n"
            )

    def test_overlapping_origin_is_rejected(self) -> None:
        with self.assertRaisesRegex(AssemblyError, "already contains"):
            self.assembler.assemble_text("NOP\n.org 0\nZAC\n")


if __name__ == "__main__":
    unittest.main()
