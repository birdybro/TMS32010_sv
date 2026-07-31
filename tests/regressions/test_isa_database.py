from __future__ import annotations

import json
import unittest
from pathlib import Path

from tools.generators.isa_database import (
    REQUIRED_INSTRUCTION_FIELDS,
    audit_opcode_space,
    classify_word,
    decode_word,
    load_database,
)
from tools.generators.opcode_audit import render_report

ROOT = Path(__file__).resolve().parents[2]


class IsaDatabaseTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.database = load_database()
        fixture_path = ROOT / "tests" / "expected" / "opcode_fixtures.yaml"
        cls.fixtures = json.loads(fixture_path.read_text(encoding="utf-8"))

    def test_scope_is_complete_but_implementation_is_disclosed_partial(self) -> None:
        coverage = self.database["coverage"]
        self.assertEqual(len(coverage["documented_mnemonics"]), 60)
        self.assertEqual(
            set(coverage["supported_mnemonics"]),
            {
                "ABS",
                "LACK",
                "NOP",
                "ZAC",
                "ROVM",
                "SOVM",
                "DINT",
                "EINT",
                "LST",
                "LARK",
                "LARP",
                "LDP",
                "LDPK",
                "DMOV",
                "LT",
                "LTD",
                "LTA",
                "MPY",
                "MPYK",
                "PAC",
                "APAC",
                "SPAC",
                "SST",
                "LAC",
                "SACL",
                "SACH",
                "ADD",
                "ADDH",
                "SUB",
                "SUBH",
                "ADDS",
                "SUBS",
                "SUBC",
                "AND",
                "OR",
                "XOR",
                "ZALH",
                "ZALS",
                "LAR",
                "SAR",
                "MAR",
                "BANZ",
                "BV",
                "BIOZ",
                "CALL",
                "CALA",
                "RET",
                "POP",
                "PUSH",
                "IN",
                "OUT",
                "TBLR",
                "TBLW",
                "B",
                "BGEZ",
                "BGZ",
                "BLEZ",
                "BLZ",
                "BNZ",
                "BZ",
            },
        )
        self.assertFalse(coverage["complete"])
        self.assertFalse(coverage["reserved_encoding_audit_complete"])

    def test_exhaustive_opcode_space_classification_is_stable(self) -> None:
        counts = audit_opcode_space(self.database)
        self.assertEqual(
            counts,
            self.database["opcode_space_audit"]["expected_counts"],
        )
        self.assertEqual(sum(counts.values()), 0x10000)
        report = ROOT / "docs" / "generated" / "tms32010_opcode_audit.md"
        self.assertEqual(
            report.read_text(encoding="utf-8"),
            render_report(self.database, counts),
        )

    def test_opcode_classification_boundaries_do_not_infer_behavior(self) -> None:
        cases = {
            0x0000: ("DOCUMENTED_LEGAL", ["ADD"]),
            0x00C8: ("PRIMARY_RESERVED_INDIRECT_FIELD", ["ADD"]),
            0x00B0: ("UNRESOLVED_SIMULTANEOUS_UPDATE", ["ADD"]),
            0x5A00: ("DOCUMENTED_PATTERN_MISMATCH", ["SACH"]),
            0x5AB0: ("DOCUMENTED_PATTERN_MISMATCH", ["SACH"]),
            0x5AC8: ("PRIMARY_RESERVED_INDIRECT_FIELD", ["SACH"]),
            0x7C10: ("DOCUMENTED_PATTERN_MISMATCH", ["SST"]),
            0xF401: ("DOCUMENTED_PATTERN_MISMATCH", ["BANZ"]),
            0x7F83: ("UNCLASSIFIED", []),
        }
        for word, (classification, mnemonics) in cases.items():
            with self.subTest(word=word):
                result = classify_word(self.database, word)
                self.assertEqual(result["classification"], classification)
                self.assertEqual(result["mnemonics"], mnemonics)
        self.assertEqual(
            classify_word(self.database, 0x00B0)["unresolved_question"],
            "OQ-010",
        )

    def test_abs_is_exact_one_cycle_and_preserves_status(self) -> None:
        decoded = decode_word(self.database, 0x7F88)
        self.assertIsNotNone(decoded)
        assert decoded is not None
        instruction, operands = decoded
        self.assertEqual(instruction["mnemonic"], "ABS")
        self.assertEqual(operands, {})
        self.assertEqual(instruction["documented_cycle_count"], 1)
        self.assertEqual(instruction["status_flags_affected"], [])
        self.assertEqual(instruction["confidence_level"], "CORROBORATED")

    def test_sst_forces_page_one_and_has_exactly_28_legal_encodings(self) -> None:
        legal = []
        for word in range(0x7C00, 0x7D00):
            decoded = decode_word(self.database, word)
            if decoded is not None:
                legal.append(word)
                self.assertEqual(decoded[0]["mnemonic"], "SST")
                self.assertEqual(decoded[0]["documented_cycle_count"], 1)
                self.assertEqual(decoded[0]["confidence_level"], "CORROBORATED")
        self.assertEqual(len(legal), 28)
        self.assertEqual(legal[:16], list(range(0x7C00, 0x7C10)))
        for word in (0x7C10, 0x7C7F, 0x7CC8, 0x7C8A, 0x7CB8):
            self.assertIsNone(decode_word(self.database, word))

    def test_table_transfers_use_common_addressing_and_three_cycles(self) -> None:
        for match, mnemonic in ((0x6700, "TBLR"), (0x7D00, "TBLW")):
            for control in (0xC8, 0x8A, 0xB8):
                self.assertIsNone(decode_word(self.database, match | control))
            direct = decode_word(self.database, match | 0x7F)
            indirect = decode_word(self.database, match | 0xA1)
            self.assertIsNotNone(direct)
            self.assertIsNotNone(indirect)
            assert direct is not None and indirect is not None
            self.assertEqual(direct[0]["mnemonic"], mnemonic)
            self.assertEqual(direct[0]["documented_cycle_count"], 3)
            self.assertEqual(
                indirect[1],
                {"indirect": 1, "addressing_field": 0x21},
            )

    def test_every_supported_instruction_has_required_fields(self) -> None:
        for instruction in self.database["instructions"]:
            self.assertEqual(
                REQUIRED_INSTRUCTION_FIELDS - set(instruction),
                set(),
                instruction["mnemonic"],
            )

    def test_independent_fixtures_decode(self) -> None:
        for fixture in self.fixtures["fixtures"]:
            word = int(fixture["word"], 0)
            decoded = decode_word(self.database, word)
            self.assertIsNotNone(decoded, fixture)
            assert decoded is not None
            entry, operands = decoded
            self.assertEqual(entry["mnemonic"], fixture["mnemonic"])
            self.assertEqual(operands, fixture["operands"])

    def test_adjacent_unimplemented_control_opcode_does_not_decode(self) -> None:
        self.assertIsNone(decode_word(self.database, 0x7F83))
        self.assertIsNone(decode_word(self.database, 0x7F87))
        self.assertIsNone(decode_word(self.database, 0x6882))
        self.assertIsNone(decode_word(self.database, 0x6E02))

    def test_lac_rejects_reserved_indirect_controls(self) -> None:
        self.assertIsNone(decode_word(self.database, 0x20C8))
        self.assertIsNone(decode_word(self.database, 0x208A))
        self.assertIsNone(decode_word(self.database, 0x20B8))
        self.assertIsNotNone(decode_word(self.database, 0x207F))

    def test_lar_rejects_reserved_register_and_indirect_fields(self) -> None:
        for control in (0xC8, 0x8A, 0xB8):
            self.assertIsNone(decode_word(self.database, 0x3800 | control))
            self.assertIsNone(decode_word(self.database, 0x3900 | control))
        for reserved_register in range(2, 8):
            self.assertIsNone(
                decode_word(self.database, 0x3800 | (reserved_register << 8))
            )
        self.assertIsNotNone(decode_word(self.database, 0x397F))

    def test_sar_rejects_reserved_register_and_indirect_fields(self) -> None:
        for control in (0xC8, 0x8A, 0xB8):
            self.assertIsNone(decode_word(self.database, 0x3000 | control))
            self.assertIsNone(decode_word(self.database, 0x3100 | control))
        for reserved_register in range(2, 8):
            self.assertIsNone(
                decode_word(self.database, 0x3000 | (reserved_register << 8))
            )
        self.assertIsNotNone(decode_word(self.database, 0x317F))

    def test_mar_rejects_reserved_fields_and_keeps_larp_aliases(self) -> None:
        for control in (0xC8, 0x8A, 0xB8):
            self.assertIsNone(decode_word(self.database, 0x6800 | control))
        for word, constant in ((0x6880, 0), (0x6881, 1)):
            decoded = decode_word(self.database, word)
            self.assertIsNotNone(decoded)
            assert decoded is not None
            entry, operands = decoded
            self.assertEqual(entry["mnemonic"], "LARP")
            self.assertEqual(operands, {"constant": constant})
        decoded = decode_word(self.database, 0x6888)
        self.assertIsNotNone(decoded)
        assert decoded is not None
        self.assertEqual(decoded[0]["mnemonic"], "MAR")

    def test_ldp_rejects_reserved_indirect_controls(self) -> None:
        for control in (0xC8, 0x8A, 0xB8):
            self.assertIsNone(decode_word(self.database, 0x6F00 | control))
        self.assertIsNotNone(decode_word(self.database, 0x6F7F))
        self.assertIsNotNone(decode_word(self.database, 0x6FA1))

    def test_lt_rejects_reserved_indirect_controls(self) -> None:
        for control in (0xC8, 0x8A, 0xB8):
            self.assertIsNone(decode_word(self.database, 0x6A00 | control))
        self.assertIsNotNone(decode_word(self.database, 0x6A7F))
        self.assertIsNotNone(decode_word(self.database, 0x6AA1))

    def test_lst_rejects_reserved_indirect_controls(self) -> None:
        for control in (0xC8, 0x8A, 0xB8):
            self.assertIsNone(decode_word(self.database, 0x7B00 | control))
        self.assertIsNotNone(decode_word(self.database, 0x7B7F))
        self.assertIsNotNone(decode_word(self.database, 0x7BA1))

    def test_subc_uses_common_data_addressing_without_reserved_controls(
        self,
    ) -> None:
        for control in (0xC8, 0x8A, 0xB8):
            self.assertIsNone(decode_word(self.database, 0x6400 | control))
        direct = decode_word(self.database, 0x647F)
        indirect = decode_word(self.database, 0x64A1)
        self.assertIsNotNone(direct)
        self.assertIsNotNone(indirect)
        assert direct is not None and indirect is not None
        self.assertEqual(direct[0]["mnemonic"], "SUBC")
        self.assertEqual(
            direct[1],
            {"indirect": 0, "addressing_field": 0x7F},
        )
        self.assertEqual(indirect[0]["mnemonic"], "SUBC")
        self.assertEqual(
            indirect[1],
            {"indirect": 1, "addressing_field": 0x21},
        )

    def test_banz_is_the_exact_two_word_opcode(self) -> None:
        decoded = decode_word(self.database, 0xF400)
        self.assertIsNotNone(decoded)
        assert decoded is not None
        self.assertEqual(decoded[0]["mnemonic"], "BANZ")
        self.assertEqual(decoded[1], {})
        self.assertEqual(decoded[0]["documented_cycle_count"], 2)
        self.assertIsNone(decode_word(self.database, 0xF401))

    def test_b_is_the_exact_two_word_opcode(self) -> None:
        decoded = decode_word(self.database, 0xF900)
        self.assertIsNotNone(decoded)
        assert decoded is not None
        self.assertEqual(decoded[0]["mnemonic"], "B")
        self.assertEqual(decoded[1], {})
        self.assertEqual(decoded[0]["word_count"], 2)
        self.assertEqual(decoded[0]["documented_cycle_count"], 2)
        self.assertIsNone(decode_word(self.database, 0xF901))

    def test_bv_is_exact_two_word_and_conditionally_clears_ov(self) -> None:
        decoded = decode_word(self.database, 0xF500)
        self.assertIsNotNone(decoded)
        assert decoded is not None
        instruction, operands = decoded
        self.assertEqual(instruction["mnemonic"], "BV")
        self.assertEqual(operands, {})
        self.assertEqual(instruction["word_count"], 2)
        self.assertEqual(instruction["documented_cycle_count"], 2)
        self.assertEqual(instruction["status_flags_affected"], ["OV"])
        self.assertEqual(instruction["conditional_cycle_differences"], [])
        self.assertIsNone(decode_word(self.database, 0xF501))

    def test_bioz_is_exact_two_word_and_reads_active_low_pin(self) -> None:
        decoded = decode_word(self.database, 0xF600)
        self.assertIsNotNone(decoded)
        assert decoded is not None
        instruction, operands = decoded
        self.assertEqual(instruction["mnemonic"], "BIOZ")
        self.assertEqual(operands, {})
        self.assertEqual(instruction["word_count"], 2)
        self.assertEqual(instruction["documented_cycle_count"], 2)
        self.assertEqual(instruction["status_flags_affected"], [])
        self.assertEqual(instruction["conditional_cycle_differences"], [])
        self.assertIn("BIO pin", instruction["registers_read"][0])
        self.assertIsNone(decode_word(self.database, 0xF601))

    def test_call_is_exact_two_word_stack_control_flow(self) -> None:
        decoded = decode_word(self.database, 0xF800)
        self.assertIsNotNone(decoded)
        assert decoded is not None
        instruction, operands = decoded
        self.assertEqual(instruction["mnemonic"], "CALL")
        self.assertEqual(operands, {})
        self.assertEqual(instruction["word_count"], 2)
        self.assertEqual(instruction["documented_cycle_count"], 2)
        self.assertEqual(instruction["status_flags_affected"], [])
        self.assertEqual(instruction["conditional_cycle_differences"], [])
        self.assertIn("all four stack levels", instruction["registers_written"])
        self.assertIsNone(decode_word(self.database, 0xF801))

    def test_cala_is_exact_two_cycle_accumulator_indirect_call(self) -> None:
        decoded = decode_word(self.database, 0x7F8C)
        self.assertIsNotNone(decoded)
        assert decoded is not None
        instruction, operands = decoded
        self.assertEqual(instruction["mnemonic"], "CALA")
        self.assertEqual(operands, {})
        self.assertEqual(instruction.get("word_count", 1), 1)
        self.assertEqual(instruction["documented_cycle_count"], 2)
        self.assertEqual(instruction["status_flags_affected"], [])
        self.assertEqual(instruction["conditional_cycle_differences"], [])
        self.assertIn("ACC[11:0]", instruction["registers_read"])
        self.assertIn("all four stack levels", instruction["registers_written"])
        self.assertIn("OQ-007", instruction["unresolved_questions"])

    def test_ret_is_exact_two_cycle_stack_control_flow(self) -> None:
        decoded = decode_word(self.database, 0x7F8D)
        self.assertIsNotNone(decoded)
        assert decoded is not None
        instruction, operands = decoded
        self.assertEqual(instruction["mnemonic"], "RET")
        self.assertEqual(operands, {})
        self.assertEqual(instruction.get("word_count", 1), 1)
        self.assertEqual(instruction["documented_cycle_count"], 2)
        self.assertEqual(instruction["status_flags_affected"], [])
        self.assertEqual(instruction["conditional_cycle_differences"], [])
        self.assertIn("all four stack levels", instruction["registers_read"])
        self.assertIn("OQ-007", instruction["unresolved_questions"])

    def test_push_pop_are_exact_two_cycle_stack_operations(self) -> None:
        for word, mnemonic in ((0x7F9C, "PUSH"), (0x7F9D, "POP")):
            with self.subTest(mnemonic=mnemonic):
                decoded = decode_word(self.database, word)
                self.assertIsNotNone(decoded)
                assert decoded is not None
                instruction, operands = decoded
                self.assertEqual(instruction["mnemonic"], mnemonic)
                self.assertEqual(operands, {})
                self.assertEqual(instruction.get("word_count", 1), 1)
                self.assertEqual(instruction["documented_cycle_count"], 2)
                self.assertEqual(instruction["status_flags_affected"], [])
                self.assertEqual(
                    instruction["conditional_cycle_differences"],
                    [],
                )
                self.assertIn(
                    "all four stack levels",
                    instruction["registers_written"],
                )
                self.assertIn("OQ-016", instruction["unresolved_questions"])

    def test_io_families_cover_ports_and_reject_reserved_controls(self) -> None:
        for base, mnemonic, operation in (
            (0x4000, "IN", "read"),
            (0x4800, "OUT", "write"),
        ):
            direct = decode_word(self.database, base | 0x077F)
            indirect = decode_word(self.database, base | 0x05A1)
            self.assertIsNotNone(direct)
            self.assertIsNotNone(indirect)
            assert direct is not None and indirect is not None
            self.assertEqual(direct[0]["mnemonic"], mnemonic)
            self.assertEqual(
                direct[1],
                {"port": 7, "indirect": 0, "addressing_field": 0x7F},
            )
            self.assertEqual(
                indirect[1],
                {"port": 5, "indirect": 1, "addressing_field": 0x21},
            )
            self.assertEqual(direct[0]["documented_cycle_count"], 2)
            self.assertEqual(direct[0]["external_bus_cycles"][1]["operation"], operation)
            for control in (0xC8, 0x8A, 0xB8):
                self.assertIsNone(decode_word(self.database, base | control))

    def test_accumulator_branches_are_exact_two_word_opcodes(self) -> None:
        expected = {
            0xFA00: "BLZ",
            0xFB00: "BLEZ",
            0xFC00: "BGZ",
            0xFD00: "BGEZ",
            0xFE00: "BNZ",
            0xFF00: "BZ",
        }
        for word, mnemonic in expected.items():
            with self.subTest(mnemonic=mnemonic):
                decoded = decode_word(self.database, word)
                self.assertIsNotNone(decoded)
                assert decoded is not None
                self.assertEqual(decoded[0]["mnemonic"], mnemonic)
                self.assertEqual(decoded[1], {})
                self.assertEqual(decoded[0]["word_count"], 2)
                self.assertEqual(decoded[0]["documented_cycle_count"], 2)
                self.assertIsNone(decode_word(self.database, word | 1))

    def test_dmov_uses_common_data_addressing_without_reserved_controls(
        self,
    ) -> None:
        direct = decode_word(self.database, 0x697F)
        indirect = decode_word(self.database, 0x69A1)
        self.assertIsNotNone(direct)
        self.assertIsNotNone(indirect)
        assert direct is not None and indirect is not None
        self.assertEqual(direct[0]["mnemonic"], "DMOV")
        self.assertEqual(
            direct[1],
            {"indirect": 0, "addressing_field": 0x7F},
        )
        self.assertEqual(indirect[0]["mnemonic"], "DMOV")
        self.assertEqual(
            indirect[1],
            {"indirect": 1, "addressing_field": 0x21},
        )
        for word in (0x69C8, 0x698A, 0x69B8):
            with self.subTest(word=word):
                self.assertIsNone(decode_word(self.database, word))

    def test_mpy_rejects_reserved_indirect_controls(self) -> None:
        for control in (0xC8, 0x8A, 0xB8):
            self.assertIsNone(decode_word(self.database, 0x6D00 | control))
        self.assertIsNotNone(decode_word(self.database, 0x6D7F))
        self.assertIsNotNone(decode_word(self.database, 0x6DA1))

    def test_mpyk_covers_the_complete_signed_thirteen_bit_field(self) -> None:
        cases = (
            (0x9000, -4096),
            (0x9FFF, -1),
            (0x8000, 0),
            (0x8FFF, 4095),
        )
        for word, expected in cases:
            with self.subTest(word=word):
                decoded = decode_word(self.database, word)
                self.assertIsNotNone(decoded)
                assert decoded is not None
                self.assertEqual(decoded[0]["mnemonic"], "MPYK")
                self.assertEqual(decoded[1], {"constant": expected})

    def test_pac_is_the_primary_documented_fixed_word(self) -> None:
        decoded = decode_word(self.database, 0x7F8E)
        self.assertIsNotNone(decoded)
        assert decoded is not None
        self.assertEqual(decoded[0]["mnemonic"], "PAC")
        self.assertEqual(decoded[1], {})

    def test_apac_is_the_adjacent_primary_documented_fixed_word(self) -> None:
        decoded = decode_word(self.database, 0x7F8F)
        self.assertIsNotNone(decoded)
        assert decoded is not None
        self.assertEqual(decoded[0]["mnemonic"], "APAC")
        self.assertEqual(decoded[1], {})

    def test_spac_is_the_primary_documented_fixed_word(self) -> None:
        decoded = decode_word(self.database, 0x7F90)
        self.assertIsNotNone(decoded)
        assert decoded is not None
        self.assertEqual(decoded[0]["mnemonic"], "SPAC")
        self.assertEqual(decoded[1], {})
        self.assertIsNone(decode_word(self.database, 0x7F91))

    def test_lta_uses_common_data_addressing_without_reserved_controls(
        self,
    ) -> None:
        direct = decode_word(self.database, 0x6C7F)
        indirect = decode_word(self.database, 0x6CA1)
        self.assertIsNotNone(direct)
        self.assertIsNotNone(indirect)
        assert direct is not None and indirect is not None
        self.assertEqual(direct[0]["mnemonic"], "LTA")
        self.assertEqual(
            direct[1],
            {"indirect": 0, "addressing_field": 0x7F},
        )
        self.assertEqual(indirect[0]["mnemonic"], "LTA")
        self.assertEqual(
            indirect[1],
            {"indirect": 1, "addressing_field": 0x21},
        )
        for word in (0x6CC8, 0x6C8A, 0x6CB8):
            with self.subTest(word=word):
                self.assertIsNone(decode_word(self.database, word))

    def test_ltd_uses_common_data_addressing_without_reserved_controls(
        self,
    ) -> None:
        direct = decode_word(self.database, 0x6B7F)
        indirect = decode_word(self.database, 0x6BA1)
        self.assertIsNotNone(direct)
        self.assertIsNotNone(indirect)
        assert direct is not None and indirect is not None
        self.assertEqual(direct[0]["mnemonic"], "LTD")
        self.assertEqual(
            direct[1],
            {"indirect": 0, "addressing_field": 0x7F},
        )
        self.assertEqual(indirect[0]["mnemonic"], "LTD")
        self.assertEqual(
            indirect[1],
            {"indirect": 1, "addressing_field": 0x21},
        )
        for word in (0x6BC8, 0x6B8A, 0x6BB8):
            with self.subTest(word=word):
                self.assertIsNone(decode_word(self.database, word))

    def test_sacl_rejects_reserved_indirect_controls(self) -> None:
        self.assertIsNone(decode_word(self.database, 0x50C8))
        self.assertIsNone(decode_word(self.database, 0x508A))
        self.assertIsNone(decode_word(self.database, 0x50B8))
        self.assertIsNotNone(decode_word(self.database, 0x507F))

    def test_sach_rejects_undocumented_shifts_and_reserved_controls(self) -> None:
        for shift in (2, 3, 5, 6, 7):
            self.assertIsNone(decode_word(self.database, 0x5800 | (shift << 8)))
        for word in (0x58C8, 0x588A, 0x58B8):
            self.assertIsNone(decode_word(self.database, word))
        for word in (0x5800, 0x5900, 0x5C00, 0x5C7F):
            self.assertIsNotNone(decode_word(self.database, word))

    def test_zero_loads_reject_reserved_indirect_controls(self) -> None:
        for base in (0x6500, 0x6600):
            for control in (0xC8, 0x8A, 0xB8):
                self.assertIsNone(decode_word(self.database, base | control))
            self.assertIsNotNone(decode_word(self.database, base | 0x7F))

    def test_adds_rejects_reserved_indirect_controls(self) -> None:
        for control in (0xC8, 0x8A, 0xB8):
            self.assertIsNone(decode_word(self.database, 0x6100 | control))
        self.assertIsNotNone(decode_word(self.database, 0x617F))

    def test_add_rejects_reserved_indirect_controls(self) -> None:
        for shift in (0, 7, 15):
            for control in (0xC8, 0x8A, 0xB8):
                self.assertIsNone(
                    decode_word(self.database, (shift << 8) | control)
                )
            self.assertIsNotNone(
                decode_word(self.database, (shift << 8) | 0x7F)
            )

    def test_sub_rejects_reserved_indirect_controls(self) -> None:
        for shift in (0, 7, 15):
            for control in (0xC8, 0x8A, 0xB8):
                self.assertIsNone(
                    decode_word(
                        self.database,
                        0x1000 | (shift << 8) | control,
                    )
                )
            self.assertIsNotNone(
                decode_word(
                    self.database,
                    0x1000 | (shift << 8) | 0x7F,
                )
            )

    def test_subs_rejects_reserved_indirect_controls(self) -> None:
        for control in (0xC8, 0x8A, 0xB8):
            self.assertIsNone(decode_word(self.database, 0x6300 | control))
        self.assertIsNotNone(decode_word(self.database, 0x637F))

    def test_subh_is_high_half_subtract_with_common_addressing(self) -> None:
        for control in (0xC8, 0x8A, 0xB8):
            self.assertIsNone(decode_word(self.database, 0x6200 | control))
        direct = decode_word(self.database, 0x627F)
        indirect = decode_word(self.database, 0x62A1)
        self.assertIsNotNone(direct)
        self.assertIsNotNone(indirect)
        assert direct is not None and indirect is not None
        self.assertEqual(direct[0]["mnemonic"], "SUBH")
        self.assertEqual(direct[0]["documented_cycle_count"], 1)
        self.assertEqual(
            direct[1],
            {"indirect": 0, "addressing_field": 0x7F},
        )
        self.assertEqual(
            indirect[1],
            {"indirect": 1, "addressing_field": 0x21},
        )
        self.assertIn("OV is set", direct[0]["status_flags_affected"][0])

    def test_addh_is_status_preserving_high_half_add(self) -> None:
        for control in (0xC8, 0x8A, 0xB8):
            self.assertIsNone(decode_word(self.database, 0x6000 | control))
        direct = decode_word(self.database, 0x607F)
        indirect = decode_word(self.database, 0x60A1)
        self.assertIsNotNone(direct)
        self.assertIsNotNone(indirect)
        assert direct is not None and indirect is not None
        self.assertEqual(direct[0]["mnemonic"], "ADDH")
        self.assertEqual(direct[0]["documented_cycle_count"], 1)
        self.assertEqual(direct[0]["confidence_level"], "CORROBORATED")
        self.assertEqual(
            direct[0]["status_flags_affected"],
            ["ARP only when requested by indirect addressing"],
        )
        self.assertIn("OV is preserved", direct[0]["overflow_behavior"])
        self.assertEqual(
            indirect[1],
            {"indirect": 1, "addressing_field": 0x21},
        )

    def test_logic_rejects_reserved_indirect_controls(self) -> None:
        for base in (0x7800, 0x7900, 0x7A00):
            for control in (0xC8, 0x8A, 0xB8):
                self.assertIsNone(decode_word(self.database, base | control))
            self.assertIsNotNone(decode_word(self.database, base | 0x7F))

    def test_fixture_provenance_is_independent(self) -> None:
        provenance = self.fixtures["provenance"].lower()
        self.assertIn("manually transcribed", provenance)
        self.assertIn("never generated", provenance)


if __name__ == "__main__":
    unittest.main()
