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
            LDP 0
            LDP 127
            LDP *
            LDP *+,AR1
            LDP *-,0
            LT 0
            LT 127
            LT *
            LT *+,AR1
            LT *-,0
            LTA 0
            LTA 127
            LTA *
            LTA *+,AR1
            LTA *-,0
            MPY 0
            MPY 127
            MPY *
            MPY *+,AR1
            MPY *-,0
            MPYK -4096
            MPYK -9
            MPYK -1
            MPYK 0
            MPYK 1
            MPYK 4095
            PAC
            APAC
            SPAC
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
            SACH 0
            SACH 127,4
            SACH *
            SACH *+,1
            SACH *-,4
            SACH *,0,AR0
            SACH *+,4,1
            ADD 0
            ADD 127,15
            ADD *
            ADD *+
            ADD *-
            ADD *+,8,AR1
            ADD *+,8,0
            SUB 0
            SUB 127,15
            SUB *
            SUB *+
            SUB *-
            SUB *+,8,AR1
            SUB *+,8,0
            SUBS 0
            SUBS 127
            SUBS *
            SUBS *+,AR1
            SUBS *-,0
            ADDS 0
            ADDS 127
            ADDS *
            ADDS *+,AR1
            ADDS *-,0
            XOR 0
            XOR 127
            XOR *
            XOR *+,AR1
            XOR *-,0
            AND 0
            AND 127
            AND *
            AND *+,AR1
            AND *-,0
            OR 0
            OR 127
            OR *
            OR *+,AR1
            OR *-,0
            ZALH 0
            ZALH 127
            ZALH *
            ZALH *+,AR1
            ZALS 0
            ZALS 127
            ZALS *-
            ZALS *,0
            """
        )
        self.assertEqual(
            list(result.words.values()),
            [
                0x6880,
                0x6881,
                0x6E00,
                0x6E01,
                0x6F00,
                0x6F7F,
                0x6F88,
                0x6FA1,
                0x6F90,
                0x6A00,
                0x6A7F,
                0x6A88,
                0x6AA1,
                0x6A90,
                0x6C00,
                0x6C7F,
                0x6C88,
                0x6CA1,
                0x6C90,
                0x6D00,
                0x6D7F,
                0x6D88,
                0x6DA1,
                0x6D90,
                0x9000,
                0x9FF7,
                0x9FFF,
                0x8000,
                0x8001,
                0x8FFF,
                0x7F8E,
                0x7F8F,
                0x7F90,
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
                0x5800,
                0x5C7F,
                0x5888,
                0x59A8,
                0x5C98,
                0x5880,
                0x5CA1,
                0x0000,
                0x0F7F,
                0x0088,
                0x00A8,
                0x0098,
                0x08A1,
                0x08A0,
                0x1000,
                0x1F7F,
                0x1088,
                0x10A8,
                0x1098,
                0x18A1,
                0x18A0,
                0x6300,
                0x637F,
                0x6388,
                0x63A1,
                0x6390,
                0x6100,
                0x617F,
                0x6188,
                0x61A1,
                0x6190,
                0x7800,
                0x787F,
                0x7888,
                0x78A1,
                0x7890,
                0x7900,
                0x797F,
                0x7988,
                0x79A1,
                0x7990,
                0x7A00,
                0x7A7F,
                0x7A88,
                0x7AA1,
                0x7A90,
                0x6500,
                0x657F,
                0x6588,
                0x65A1,
                0x6600,
                0x667F,
                0x6698,
                0x6680,
            ],
        )

    def test_round_trip_preserves_supported_and_unknown_words(self) -> None:
        original = [
            0x7001,
            0x71FE,
            0x6881,
            0x6E00,
            0x9000,
            0x9FF7,
            0x8000,
            0x8FFF,
            0x7F8E,
            0x7F8F,
            0x7F90,
            0x6C00,
            0x6C7F,
            0x6C88,
            0x6CA1,
            0x6C90,
            0x6F00,
            0x6F7F,
            0x6F88,
            0x6FA1,
            0x6F90,
            0x7E2A,
            0x7F80,
            0x3ABC,
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
            0x5800,
            0x597F,
            0x5C88,
            0x59A8,
            0x5C98,
            0x5880,
            0x5CA1,
            0x5C89,
            0x0000,
            0x0F7F,
            0x0088,
            0x00A8,
            0x0098,
            0x08A1,
            0x08A0,
            0x0089,
            0x1000,
            0x1F7F,
            0x1088,
            0x10A8,
            0x1098,
            0x18A1,
            0x18A0,
            0x1089,
            0x6300,
            0x637F,
            0x6388,
            0x63A1,
            0x6390,
            0x6389,
            0x6100,
            0x617F,
            0x6188,
            0x61A1,
            0x6190,
            0x6189,
            0x7800,
            0x787F,
            0x7888,
            0x78A1,
            0x7890,
            0x7889,
            0x7900,
            0x797F,
            0x7988,
            0x79A1,
            0x7990,
            0x7989,
            0x7A00,
            0x7A7F,
            0x7A88,
            0x7AA1,
            0x7A90,
            0x7A89,
            0x6500,
            0x657F,
            0x6588,
            0x65A1,
            0x6589,
            0x6600,
            0x667F,
            0x6698,
            0x6680,
            0x6689,
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
        for source in ("MPYK -4097\n", "MPYK 4096\n"):
            with self.subTest(source=source):
                with self.assertRaisesRegex(AssemblyError, "out of range"):
                    self.assembler.assemble_text(source)

    def test_mpyk_signed_immediate_round_trip(self) -> None:
        original = [0x9000, 0x9FF7, 0x9FFF, 0x8000, 0x8001, 0x8FFF]
        source = self.disassembler.disassemble_source(original)
        self.assertEqual(
            source,
            "MPYK -4096\n"
            "MPYK -9\n"
            "MPYK -1\n"
            "MPYK 0\n"
            "MPYK 1\n"
            "MPYK 4095\n",
        )
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), original)

    def test_common_address_operand_diagnostics_and_noncanonical_aliases(self) -> None:
        for mnemonic, noncanonical in (
            ("LDP", 0x6F89),
            ("LT", 0x6A89),
            ("LTA", 0x6C89),
            ("MPY", 0x6D89),
        ):
            for operand, message in (
                ("128", "direct address"),
                ("*+,2", "next ARP"),
                ("0,1", "only with indirect"),
            ):
                source = f"{mnemonic} {operand}\n"
                with self.subTest(source=source):
                    with self.assertRaisesRegex(AssemblyError, message):
                        self.assembler.assemble_text(source)
            source = self.disassembler.disassemble_source([noncanonical])
            self.assertEqual(source, f".word 0x{noncanonical:04x}\n")
            rebuilt = self.assembler.assemble_text(source)
            self.assertEqual(list(rebuilt.words.values()), [noncanonical])

    def test_lar_encodings_round_trip_and_diagnose_operands(self) -> None:
        result = self.assembler.assemble_text(
            """
            LAR AR0,0
            LAR AR1,127
            LAR AR0,*+
            LAR AR1,*-,AR0
            """
        )
        self.assertEqual(
            list(result.words.values()),
            [0x3800, 0x397F, 0x38A8, 0x3990],
        )
        source = self.disassembler.disassemble_source(
            [0x3800, 0x397F, 0x38A8, 0x3990, 0x3989]
        )
        self.assertEqual(
            source,
            "LAR AR0,0\n"
            "LAR AR1,127\n"
            "LAR AR0,*+\n"
            "LAR AR1,*-,0\n"
            ".word 0x3989\n",
        )
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(
            list(rebuilt.words.values()),
            [0x3800, 0x397F, 0x38A8, 0x3990, 0x3989],
        )
        for invalid, message in (
            ("LAR AR2,0\n", "AR0 or AR1"),
            ("LAR AR0,128\n", "direct address"),
            ("LAR AR0,*+,2\n", "next ARP"),
            ("LAR AR0,0,1\n", "only with indirect"),
            ("LAR AR0\n", "2 to 3 operands"),
        ):
            with self.subTest(source=invalid):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(invalid)

    def test_sar_encodings_round_trip_and_diagnose_operands(self) -> None:
        result = self.assembler.assemble_text(
            """
            SAR AR0,0
            SAR AR1,127
            SAR AR0,*+
            SAR AR1,*-,AR0
            """
        )
        self.assertEqual(
            list(result.words.values()),
            [0x3000, 0x317F, 0x30A8, 0x3190],
        )
        source = self.disassembler.disassemble_source(
            [0x3000, 0x317F, 0x30A8, 0x3190, 0x3189]
        )
        self.assertEqual(
            source,
            "SAR AR0,0\n"
            "SAR AR1,127\n"
            "SAR AR0,*+\n"
            "SAR AR1,*-,0\n"
            ".word 0x3189\n",
        )
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(
            list(rebuilt.words.values()),
            [0x3000, 0x317F, 0x30A8, 0x3190, 0x3189],
        )
        for invalid, message in (
            ("SAR AR2,0\n", "AR0 or AR1"),
            ("SAR AR0,128\n", "direct address"),
            ("SAR AR0,*+,2\n", "next ARP"),
            ("SAR AR0,0,1\n", "only with indirect"),
            ("SAR AR0\n", "2 to 3 operands"),
        ):
            with self.subTest(source=invalid):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(invalid)

    def test_mar_encodings_aliases_round_trip_and_diagnose_operands(self) -> None:
        result = self.assembler.assemble_text(
            """
            MAR 127
            MAR *
            MAR *+,AR0
            MAR *-,AR1
            MAR *,AR0
            """
        )
        self.assertEqual(
            list(result.words.values()),
            [0x687F, 0x6888, 0x68A0, 0x6891, 0x6880],
        )
        source = self.disassembler.disassemble_source(
            [0x687F, 0x6888, 0x68A0, 0x6891, 0x6880, 0x6889]
        )
        self.assertEqual(
            source,
            "MAR 127\n"
            "MAR *\n"
            "MAR *+,0\n"
            "MAR *-,1\n"
            "LARP 0\n"
            ".word 0x6889\n",
        )
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(
            list(rebuilt.words.values()),
            [0x687F, 0x6888, 0x68A0, 0x6891, 0x6880, 0x6889],
        )
        for invalid, message in (
            ("MAR 128\n", "direct address"),
            ("MAR *+,2\n", "next ARP"),
            ("MAR 0,1\n", "only with indirect"),
            ("MAR\n", "1 to 2 operands"),
        ):
            with self.subTest(source=invalid):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(invalid)

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

    def test_add_operand_diagnostics_and_noncanonical_alias(self) -> None:
        cases = (
            ("ADD 128\n", "direct address"),
            ("ADD 0,16\n", "shift"),
            ("ADD *+,0,2\n", "next ARP"),
            ("ADD 0,0,1\n", "only with indirect"),
            ("ADD\n", "1 to 3 operands"),
        )
        for source, message in cases:
            with self.subTest(source=source):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(source)

        source = self.disassembler.disassemble_source([0x0089])
        self.assertEqual(source, ".word 0x0089\n")
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), [0x0089])

    def test_sub_operand_diagnostics_and_noncanonical_alias(self) -> None:
        cases = (
            ("SUB 128\n", "direct address"),
            ("SUB 0,16\n", "shift"),
            ("SUB *+,0,2\n", "next ARP"),
            ("SUB 0,0,1\n", "only with indirect"),
            ("SUB\n", "1 to 3 operands"),
        )
        for source, message in cases:
            with self.subTest(source=source):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(source)

        source = self.disassembler.disassemble_source([0x1089])
        self.assertEqual(source, ".word 0x1089\n")
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), [0x1089])

    def test_subs_operand_diagnostics_and_noncanonical_alias(self) -> None:
        cases = (
            ("SUBS 128\n", "direct address"),
            ("SUBS *+,2\n", "next ARP"),
            ("SUBS 0,1\n", "only with indirect"),
            ("SUBS\n", "1 to 2 operands"),
        )
        for source, message in cases:
            with self.subTest(source=source):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(source)

        source = self.disassembler.disassemble_source([0x6389])
        self.assertEqual(source, ".word 0x6389\n")
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), [0x6389])

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

    def test_sach_operand_diagnostics(self) -> None:
        cases = (
            ("SACH 128\n", "direct address"),
            ("SACH 0,2\n", "exactly 0, 1, or 4"),
            ("SACH *+,4,2\n", "next ARP"),
            ("SACH 0,0,1\n", "only with indirect"),
            ("SACH\n", "1 to 3 operands"),
        )
        for source, message in cases:
            with self.subTest(source=source):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(source)

    def test_sach_noncanonical_preserve_bit_round_trips_as_word(self) -> None:
        source = self.disassembler.disassemble_source([0x5C89])
        self.assertEqual(source, ".word 0x5c89\n")
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), [0x5C89])

    def test_zero_load_operand_diagnostics(self) -> None:
        for mnemonic in ("ZALH", "ZALS"):
            cases = (
                (f"{mnemonic} 128\n", "direct address"),
                (f"{mnemonic} *+,2\n", "next ARP"),
                (f"{mnemonic} 0,1\n", "only with indirect"),
                (f"{mnemonic}\n", "1 to 2 operands"),
            )
            for source, message in cases:
                with self.subTest(source=source):
                    with self.assertRaisesRegex(AssemblyError, message):
                        self.assembler.assemble_text(source)

    def test_zero_load_noncanonical_aliases_round_trip_as_words(self) -> None:
        original = [0x6589, 0x6689]
        source = self.disassembler.disassemble_source(original)
        self.assertEqual(source, ".word 0x6589\n.word 0x6689\n")
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), original)

    def test_adds_operand_diagnostics_and_noncanonical_alias(self) -> None:
        cases = (
            ("ADDS 128\n", "direct address"),
            ("ADDS *+,2\n", "next ARP"),
            ("ADDS 0,1\n", "only with indirect"),
            ("ADDS\n", "1 to 2 operands"),
        )
        for source, message in cases:
            with self.subTest(source=source):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(source)

        source = self.disassembler.disassemble_source([0x6189])
        self.assertEqual(source, ".word 0x6189\n")
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), [0x6189])

    def test_logic_operand_diagnostics_and_noncanonical_aliases(self) -> None:
        for mnemonic in ("XOR", "AND", "OR"):
            cases = (
                (f"{mnemonic} 128\n", "direct address"),
                (f"{mnemonic} *+,2\n", "next ARP"),
                (f"{mnemonic} 0,1\n", "only with indirect"),
                (f"{mnemonic}\n", "1 to 2 operands"),
            )
            for source, message in cases:
                with self.subTest(source=source):
                    with self.assertRaisesRegex(AssemblyError, message):
                        self.assembler.assemble_text(source)

        original = [0x7889, 0x7989, 0x7A89]
        source = self.disassembler.disassemble_source(original)
        self.assertEqual(
            source,
            ".word 0x7889\n.word 0x7989\n.word 0x7a89\n",
        )
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), original)

    def test_unsupported_documented_instruction_is_explicit(self) -> None:
        with self.assertRaisesRegex(
            AssemblyError,
            "documented instruction ADDH is not implemented",
        ):
            self.assembler.assemble_text("ADDH 0\n")

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
