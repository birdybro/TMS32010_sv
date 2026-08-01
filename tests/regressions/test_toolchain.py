from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.assembler.tms32010_as import Assembler, AssemblyError
from tools.disassembler.tms32010_dis import Disassembler

ROOT = Path(__file__).resolve().parents[2]


class ToolchainSliceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.assembler = Assembler()
        self.disassembler = Disassembler()

    def test_push_pop_physical_bus_probe_image_is_stable(self) -> None:
        result = self.assembler.assemble_file(
            ROOT / "tests" / "asm" / "push_pop_bus_probe.asm"
        )
        self.assertEqual(
            result.words,
            {
                0x000: 0x7E55,
                0x001: 0x7F9C,
                0x002: 0x7F80,
                0x003: 0x7EAA,
                0x004: 0x7F9D,
                0x005: 0x7F80,
                0x006: 0xF900,
                0x007: 0x0006,
            },
        )
        self.assertEqual(result.symbols["HOLD"], 0x006)

    def test_ram_boundary_physical_probe_images_are_stable(self) -> None:
        expected = [
            0x6E00,
            0x6880,
            0x708F,
            0x7F89,
            0x5088,
            0xF400,
            0x0004,
            0x708F,
            0x7E5A,
            0x5088,
            0x6E00,
            0x7E03,
            0x5000,
            0x6A00,
            0x8005,
            0x7E07,
            0x6E01,
            0x690F,
            0x708F,
            0x4F88,
            0xF400,
            0x0013,
            0x4F10,
            0x7F80,
            0xF900,
            0x0018,
        ]
        for source_name, boundary_word in (
            ("ram_boundary_dmov_probe.asm", 0x690F),
            ("ram_boundary_ltd_probe.asm", 0x6B0F),
        ):
            result = self.assembler.assemble_file(
                ROOT / "tests" / "asm" / source_name
            )
            fixture_words = expected.copy()
            fixture_words[0x011] = boundary_word
            self.assertEqual(
                result.words,
                dict(enumerate(fixture_words)),
                source_name,
            )
            self.assertEqual(
                result.symbols,
                {
                    "BOUNDARY": 0x011,
                    "CLEAR": 0x004,
                    "HOLD": 0x018,
                    "SCAN": 0x013,
                },
            )

    def test_mame_stack_control_smoke_image_is_stable(self) -> None:
        result = self.assembler.assemble_file(
            ROOT / "tests" / "asm" / "mame_stack_control_smoke.asm"
        )
        self.assertEqual(
            result.words,
            {
                0x000: 0x7E55,
                0x001: 0x7F9C,
                0x002: 0x7F80,
                0x003: 0x7EAA,
                0x004: 0x7F9D,
                0x005: 0x7E0C,
                0x006: 0x7F8C,
                0x007: 0x7E33,
                0x008: 0x7F80,
                0x009: 0xF900,
                0x00A: 0x0009,
                0x00C: 0x7E77,
                0x00D: 0x7F8D,
            },
        )
        self.assertEqual(result.symbols["HOLD"], 0x009)
        self.assertEqual(result.symbols["SUBROUTINE"], 0x00C)

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
            DMOV 0
            DMOV 127
            DMOV *
            DMOV *+,AR1
            DMOV *-,0
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
            LTD 0
            LTD 127
            LTD *
            LTD *+,AR1
            LTD *-,0
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
            DINT
            EINT
            LST 0
            LST 127
            LST *
            LST *+,AR1
            LST *-,0
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
            SUBH 0
            SUBH 127
            SUBH *
            SUBH *+,AR1
            SUBH *-,0
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
                0x6900,
                0x697F,
                0x6988,
                0x69A1,
                0x6990,
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
                0x6B00,
                0x6B7F,
                0x6B88,
                0x6BA1,
                0x6B90,
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
                0x7F81,
                0x7F82,
                0x7B00,
                0x7B7F,
                0x7B88,
                0x7BA1,
                0x7B90,
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
                0x6200,
                0x627F,
                0x6288,
                0x62A1,
                0x6290,
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
            0x6900,
            0x697F,
            0x6988,
            0x69A1,
            0x6990,
            0x6C00,
            0x6C7F,
            0x6C88,
            0x6CA1,
            0x6C90,
            0x6B00,
            0x6B7F,
            0x6B88,
            0x6BA1,
            0x6B90,
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
            0x7F81,
            0x7F82,
            0x7F83,
            0x7B00,
            0x7B7F,
            0x7B88,
            0x7BA1,
            0x7B90,
            0x7B89,
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
            0xF400,
            0x035A,
            0xF500,
            0x0100,
            0xF600,
            0x0101,
            0xF800,
            0x0102,
            0xF900,
            0x0123,
            0xFA00,
            0x0200,
            0xFB00,
            0x0201,
            0xFC00,
            0x0202,
            0xFD00,
            0x0203,
            0xFE00,
            0x0204,
            0xFF00,
            0x0205,
        ]
        source = self.disassembler.disassemble_source(original)
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), original)

    def test_banz_emits_and_consumes_the_following_target_word(self) -> None:
        result = self.assembler.assemble_text(
            """
            START: NOP
            LOOP:  BANZ LOOP
            AFTER: NOP
            """
        )
        self.assertEqual(
            result.words,
            {
                0: 0x7F80,
                1: 0xF400,
                2: 0x0001,
                3: 0x7F80,
            },
        )
        self.assertEqual(result.symbols["LOOP"], 1)
        self.assertEqual(result.symbols["AFTER"], 3)
        self.assertEqual(len(result.listing), 4)

        source = self.disassembler.disassemble_source(
            [0xF400, 0x035A, 0x7F80]
        )
        self.assertEqual(source, "BANZ 0x35a\nNOP\n")
        self.assertEqual(
            self.disassembler.disassemble_listing(
                [0xF400, 0x035A, 0x7F80],
                origin=0x100,
            ),
            "100 f400  BANZ 0x35a\n"
            "101 035a  .word 0x035a ; BANZ target\n"
            "102 7f80  NOP\n",
        )
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(
            list(rebuilt.words.values()),
            [0xF400, 0x035A, 0x7F80],
        )
        self.assertEqual(
            self.disassembler.disassemble_word(0xF400),
            ".word 0xf400",
        )

        for invalid, message in (
            ("BANZ -1\n", "program address"),
            ("BANZ 4096\n", "program address"),
            ("BANZ\n", "1 operand"),
            ("BANZ 1,2\n", "1 operand"),
        ):
            with self.subTest(source=invalid):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(invalid)

    def test_b_emits_and_consumes_the_following_target_word(self) -> None:
        result = self.assembler.assemble_text(
            """
            START: B TARGET
            SKIP:  ZAC
            TARGET: NOP
            """
        )
        self.assertEqual(
            result.words,
            {
                0: 0xF900,
                1: 0x0003,
                2: 0x7F89,
                3: 0x7F80,
            },
        )
        self.assertEqual(result.symbols["SKIP"], 2)
        self.assertEqual(result.symbols["TARGET"], 3)
        self.assertEqual(len(result.listing), 4)

        source = self.disassembler.disassemble_source(
            [0xF900, 0x035A, 0x7F80]
        )
        self.assertEqual(source, "B 0x35a\nNOP\n")
        self.assertEqual(
            self.disassembler.disassemble_listing(
                [0xF900, 0x035A, 0x7F80],
                origin=0x100,
            ),
            "100 f900  B 0x35a\n"
            "101 035a  .word 0x035a ; B target\n"
            "102 7f80  NOP\n",
        )
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(
            list(rebuilt.words.values()),
            [0xF900, 0x035A, 0x7F80],
        )
        self.assertEqual(
            self.disassembler.disassemble_word(0xF900),
            ".word 0xf900",
        )

        for invalid, message in (
            ("B -1\n", "program address"),
            ("B 4096\n", "program address"),
            ("B\n", "1 operand"),
            ("B 1,2\n", "1 operand"),
        ):
            with self.subTest(source=invalid):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(invalid)

    def test_bv_round_trips_target_and_diagnostics(self) -> None:
        result = self.assembler.assemble_text(
            "BV TARGET\nZAC\nTARGET: NOP\n"
        )
        self.assertEqual(
            result.words,
            {
                0: 0xF500,
                1: 0x0003,
                2: 0x7F89,
                3: 0x7F80,
            },
        )
        self.assertEqual(result.symbols["TARGET"], 3)
        source = self.disassembler.disassemble_source(
            [0xF500, 0x035A, 0x7F80]
        )
        self.assertEqual(source, "BV 0x35a\nNOP\n")
        self.assertEqual(
            self.disassembler.disassemble_listing(
                [0xF500, 0x035A],
                origin=0x100,
            ),
            "100 f500  BV 0x35a\n"
            "101 035a  .word 0x035a ; BV target\n",
        )
        self.assertEqual(
            list(self.assembler.assemble_text(source).words.values()),
            [0xF500, 0x035A, 0x7F80],
        )
        self.assertEqual(
            self.disassembler.disassemble_word(0xF500),
            ".word 0xf500",
        )

        for invalid, message in (
            ("BV -1\n", "program address"),
            ("BV 4096\n", "program address"),
            ("BV\n", "1 operand"),
            ("BV 1,2\n", "1 operand"),
        ):
            with self.subTest(source=invalid):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(invalid)

    def test_bioz_round_trips_target_and_diagnostics(self) -> None:
        result = self.assembler.assemble_text(
            "BIOZ TARGET\nZAC\nTARGET: NOP\n"
        )
        self.assertEqual(
            result.words,
            {
                0: 0xF600,
                1: 0x0003,
                2: 0x7F89,
                3: 0x7F80,
            },
        )
        self.assertEqual(result.symbols["TARGET"], 3)
        source = self.disassembler.disassemble_source(
            [0xF600, 0x035A, 0x7F80]
        )
        self.assertEqual(source, "BIOZ 0x35a\nNOP\n")
        self.assertEqual(
            self.disassembler.disassemble_listing(
                [0xF600, 0x035A],
                origin=0x100,
            ),
            "100 f600  BIOZ 0x35a\n"
            "101 035a  .word 0x035a ; BIOZ target\n",
        )
        self.assertEqual(
            list(self.assembler.assemble_text(source).words.values()),
            [0xF600, 0x035A, 0x7F80],
        )
        self.assertEqual(
            self.disassembler.disassemble_word(0xF600),
            ".word 0xf600",
        )

        for invalid, message in (
            ("BIOZ -1\n", "program address"),
            ("BIOZ 4096\n", "program address"),
            ("BIOZ\n", "1 operand"),
            ("BIOZ 1,2\n", "1 operand"),
        ):
            with self.subTest(source=invalid):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(invalid)

    def test_call_round_trips_target_and_diagnostics(self) -> None:
        result = self.assembler.assemble_text(
            "CALL TARGET\nZAC\nTARGET: NOP\n"
        )
        self.assertEqual(
            result.words,
            {
                0: 0xF800,
                1: 0x0003,
                2: 0x7F89,
                3: 0x7F80,
            },
        )
        self.assertEqual(result.symbols["TARGET"], 3)
        source = self.disassembler.disassemble_source(
            [0xF800, 0x035A, 0x7F80]
        )
        self.assertEqual(source, "CALL 0x35a\nNOP\n")
        self.assertEqual(
            self.disassembler.disassemble_listing(
                [0xF800, 0x035A],
                origin=0x100,
            ),
            "100 f800  CALL 0x35a\n"
            "101 035a  .word 0x035a ; CALL target\n",
        )
        self.assertEqual(
            list(self.assembler.assemble_text(source).words.values()),
            [0xF800, 0x035A, 0x7F80],
        )
        self.assertEqual(
            self.disassembler.disassemble_word(0xF800),
            ".word 0xf800",
        )

        for invalid, message in (
            ("CALL -1\n", "program address"),
            ("CALL 4096\n", "program address"),
            ("CALL\n", "1 operand"),
            ("CALL 1,2\n", "1 operand"),
        ):
            with self.subTest(source=invalid):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(invalid)

    def test_ret_round_trips_exact_implied_word(self) -> None:
        result = self.assembler.assemble_text("RET\n")
        self.assertEqual(result.words, {0: 0x7F8D})
        self.assertEqual(
            self.disassembler.disassemble_word(0x7F8D),
            "RET",
        )
        source = self.disassembler.disassemble_source([0x7F8D, 0x7F80])
        self.assertEqual(source, "RET\nNOP\n")
        self.assertEqual(
            list(self.assembler.assemble_text(source).words.values()),
            [0x7F8D, 0x7F80],
        )
        with self.assertRaisesRegex(AssemblyError, "no operands"):
            self.assembler.assemble_text("RET 1\n")

    def test_cala_round_trips_exact_implied_word(self) -> None:
        result = self.assembler.assemble_text("CALA\n")
        self.assertEqual(result.words, {0: 0x7F8C})
        self.assertEqual(
            self.disassembler.disassemble_word(0x7F8C),
            "CALA",
        )
        source = self.disassembler.disassemble_source([0x7F8C, 0x7F80])
        self.assertEqual(source, "CALA\nNOP\n")
        self.assertEqual(
            list(self.assembler.assemble_text(source).words.values()),
            [0x7F8C, 0x7F80],
        )
        with self.assertRaisesRegex(AssemblyError, "no operands"):
            self.assembler.assemble_text("CALA 1\n")

    def test_push_pop_round_trip_exact_implied_words(self) -> None:
        result = self.assembler.assemble_text("PUSH\nPOP\n")
        self.assertEqual(result.words, {0: 0x7F9C, 1: 0x7F9D})
        self.assertEqual(
            self.disassembler.disassemble_source([0x7F9C, 0x7F9D]),
            "PUSH\nPOP\n",
        )
        rebuilt = self.assembler.assemble_text(
            self.disassembler.disassemble_source([0x7F9C, 0x7F9D])
        )
        self.assertEqual(list(rebuilt.words.values()), [0x7F9C, 0x7F9D])
        for invalid in ("PUSH 1\n", "POP 1\n"):
            with self.subTest(invalid=invalid):
                with self.assertRaisesRegex(AssemblyError, "no operands"):
                    self.assembler.assemble_text(invalid)

    def test_accumulator_branches_round_trip_targets_and_diagnostics(
        self,
    ) -> None:
        branches = {
            "BLZ": 0xFA00,
            "BLEZ": 0xFB00,
            "BGZ": 0xFC00,
            "BGEZ": 0xFD00,
            "BNZ": 0xFE00,
            "BZ": 0xFF00,
        }
        for mnemonic, opcode in branches.items():
            with self.subTest(mnemonic=mnemonic):
                result = self.assembler.assemble_text(
                    f"{mnemonic} TARGET\nZAC\nTARGET: NOP\n"
                )
                self.assertEqual(
                    result.words,
                    {
                        0: opcode,
                        1: 0x0003,
                        2: 0x7F89,
                        3: 0x7F80,
                    },
                )
                self.assertEqual(result.symbols["TARGET"], 3)
                source = self.disassembler.disassemble_source(
                    [opcode, 0x035A, 0x7F80]
                )
                self.assertEqual(source, f"{mnemonic} 0x35a\nNOP\n")
                self.assertEqual(
                    self.disassembler.disassemble_listing(
                        [opcode, 0x035A],
                        origin=0x100,
                    ),
                    f"100 {opcode:04x}  {mnemonic} 0x35a\n"
                    f"101 035a  .word 0x035a ; {mnemonic} target\n",
                )
                self.assertEqual(
                    list(self.assembler.assemble_text(source).words.values()),
                    [opcode, 0x035A, 0x7F80],
                )
                self.assertEqual(
                    self.disassembler.disassemble_word(opcode),
                    f".word 0x{opcode:04x}",
                )

                for invalid, message in (
                    (f"{mnemonic} -1\n", "program address"),
                    (f"{mnemonic} 4096\n", "program address"),
                    (f"{mnemonic}\n", "1 operand"),
                    (f"{mnemonic} 1,2\n", "1 operand"),
                ):
                    with self.assertRaisesRegex(AssemblyError, message):
                        self.assembler.assemble_text(invalid)

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
            ("DMOV", 0x6989),
            ("LT", 0x6A89),
            ("LTA", 0x6C89),
            ("LTD", 0x6B89),
            ("MPY", 0x6D89),
            ("LST", 0x7B89),
            ("SUBC", 0x6489),
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

    def test_subh_operand_diagnostics_and_noncanonical_alias(self) -> None:
        cases = (
            ("SUBH 128\n", "direct address"),
            ("SUBH *+,2\n", "next ARP"),
            ("SUBH 0,1\n", "only with indirect"),
            ("SUBH\n", "1 to 2 operands"),
        )
        for source, message in cases:
            with self.subTest(source=source):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(source)

        source = self.disassembler.disassemble_source([0x6289])
        self.assertEqual(source, ".word 0x6289\n")
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), [0x6289])

    def test_addh_round_trip_and_operand_diagnostics(self) -> None:
        source = "ADDH 0\nADDH 127\nADDH *\nADDH *+,1\nADDH *-,0\n"
        expected = [0x6000, 0x607F, 0x6088, 0x60A1, 0x6090]
        result = self.assembler.assemble_text(source)
        self.assertEqual(list(result.words.values()), expected)
        disassembly = self.disassembler.disassemble_source(expected)
        self.assertEqual(disassembly, source)
        rebuilt = self.assembler.assemble_text(disassembly)
        self.assertEqual(list(rebuilt.words.values()), expected)

        for text, message in (
            ("ADDH 128\n", "direct address"),
            ("ADDH *+,2\n", "next ARP"),
            ("ADDH 0,1\n", "only with indirect"),
            ("ADDH\n", "1 to 2 operands"),
        ):
            with self.subTest(text=text):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(text)

        disassembly = self.disassembler.disassemble_source([0x6089])
        self.assertEqual(disassembly, ".word 0x6089\n")
        rebuilt = self.assembler.assemble_text(disassembly)
        self.assertEqual(list(rebuilt.words.values()), [0x6089])

    def test_subc_encodings_round_trip_and_diagnose_operands(self) -> None:
        result = self.assembler.assemble_text(
            """
            SUBC 0
            SUBC 127
            SUBC *
            SUBC *+,AR1
            SUBC *-,0
            """
        )
        self.assertEqual(
            list(result.words.values()),
            [0x6400, 0x647F, 0x6488, 0x64A1, 0x6490],
        )
        source = self.disassembler.disassemble_source(
            [0x6400, 0x647F, 0x6488, 0x64A1, 0x6490]
        )
        self.assertEqual(
            source,
            "SUBC 0\n"
            "SUBC 127\n"
            "SUBC *\n"
            "SUBC *+,1\n"
            "SUBC *-,0\n",
        )
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), list(result.words.values()))

        cases = (
            ("SUBC 128\n", "direct address"),
            ("SUBC *+,2\n", "next ARP"),
            ("SUBC 0,1\n", "only with indirect"),
            ("SUBC\n", "1 to 2 operands"),
        )
        for case, message in cases:
            with self.subTest(source=case):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(case)

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

    def test_io_encodings_and_pa_aliases_round_trip(self) -> None:
        result = self.assembler.assemble_text(
            """
            IN 0,PA0
            IN 127,5
            IN *-,PA1,0
            IN *+,7,AR1
            OUT 0,0
            OUT 120,PA7
            OUT *,PA5
            OUT *+,5,0
            """
        )
        expected = [
            0x4000,
            0x457F,
            0x4190,
            0x47A1,
            0x4800,
            0x4F78,
            0x4D88,
            0x4DA0,
        ]
        self.assertEqual(list(result.words.values()), expected)

        source = self.disassembler.disassemble_source(expected)
        self.assertEqual(
            source,
            "IN 0,0\n"
            "IN 127,5\n"
            "IN *-,1,0\n"
            "IN *+,7,1\n"
            "OUT 0,0\n"
            "OUT 120,7\n"
            "OUT *,5\n"
            "OUT *+,5,0\n",
        )
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), expected)

    def test_io_operand_diagnostics_and_noncanonical_aliases(self) -> None:
        cases = (
            ("IN 0,8\n", "port out of range"),
            ("OUT 0,PAX\n", "I/O port"),
            ("IN 128,0\n", "direct address"),
            ("OUT *+,0,2\n", "next ARP"),
            ("IN 0,0,1\n", "only with indirect"),
            ("OUT 0\n", "2 to 3 operands"),
        )
        for source, message in cases:
            with self.subTest(source=source):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(source)

        original = [0x4089, 0x4F89]
        source = self.disassembler.disassemble_source(original)
        self.assertEqual(source, ".word 0x4089\n.word 0x4f89\n")
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), original)

    def test_table_transfer_encodings_round_trip(self) -> None:
        result = self.assembler.assemble_text(
            """
            TBLR 0
            TBLR 127
            TBLR *-,AR0
            TBLR *+,AR1
            TBLW 0
            TBLW 127
            TBLW *
            TBLW *+,0
            """
        )
        expected = [
            0x6700,
            0x677F,
            0x6790,
            0x67A1,
            0x7D00,
            0x7D7F,
            0x7D88,
            0x7DA0,
        ]
        self.assertEqual(list(result.words.values()), expected)

        source = self.disassembler.disassemble_source(expected)
        self.assertEqual(
            source,
            "TBLR 0\n"
            "TBLR 127\n"
            "TBLR *-,0\n"
            "TBLR *+,1\n"
            "TBLW 0\n"
            "TBLW 127\n"
            "TBLW *\n"
            "TBLW *+,0\n",
        )
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), expected)

    def test_table_transfer_diagnostics_and_noncanonical_aliases(self) -> None:
        cases = (
            ("TBLR 128\n", "direct address"),
            ("TBLW *+,2\n", "next ARP"),
            ("TBLR 0,1\n", "only with indirect"),
            ("TBLW\n", "1 to 2 operands"),
        )
        for source, message in cases:
            with self.subTest(source=source):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(source)

        original = [0x6789, 0x7D89]
        source = self.disassembler.disassemble_source(original)
        self.assertEqual(source, ".word 0x6789\n.word 0x7d89\n")
        rebuilt = self.assembler.assemble_text(source)
        self.assertEqual(list(rebuilt.words.values()), original)

    def test_abs_round_trips_exact_implied_word(self) -> None:
        result = self.assembler.assemble_text("ABS\n")
        self.assertEqual(list(result.words.values()), [0x7F88])
        self.assertEqual(self.disassembler.disassemble_source([0x7F88]), "ABS\n")
        rebuilt = self.assembler.assemble_text(
            self.disassembler.disassemble_source([0x7F88])
        )
        self.assertEqual(list(rebuilt.words.values()), [0x7F88])

        with self.assertRaisesRegex(AssemblyError, "expects no operands"):
            self.assembler.assemble_text("ABS 1\n")

    def test_sst_round_trips_forced_page_one_and_indirect_forms(self) -> None:
        source = (
            "SST 0\n"
            "SST 15\n"
            "SST *\n"
            "SST *+,0\n"
            "SST *-,1\n"
        )
        expected = [0x7C00, 0x7C0F, 0x7C88, 0x7CA0, 0x7C91]
        result = self.assembler.assemble_text(source)
        self.assertEqual(list(result.words.values()), expected)
        disassembly = self.disassembler.disassemble_source(expected)
        self.assertEqual(disassembly, source)
        rebuilt = self.assembler.assemble_text(disassembly)
        self.assertEqual(list(rebuilt.words.values()), expected)

        for text, message in (
            ("SST 16\n", "direct address out of range 0..15"),
            ("SST 0,1\n", "only with indirect addressing"),
            ("SST *+,2\n", "next ARP out of range"),
            ("SST\n", "1 to 2 operands"),
        ):
            with self.subTest(text=text):
                with self.assertRaisesRegex(AssemblyError, message):
                    self.assembler.assemble_text(text)

        aliases = [0x7C89, 0x7CA9]
        disassembly = self.disassembler.disassemble_source(aliases)
        self.assertEqual(disassembly, ".word 0x7c89\n.word 0x7ca9\n")
        rebuilt = self.assembler.assemble_text(disassembly)
        self.assertEqual(list(rebuilt.words.values()), aliases)

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
