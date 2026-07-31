from __future__ import annotations

import json
import unittest
from pathlib import Path

from tools.generators.isa_database import (
    REQUIRED_INSTRUCTION_FIELDS,
    decode_word,
    load_database,
)

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
                "LACK",
                "NOP",
                "ZAC",
                "ROVM",
                "SOVM",
                "LARK",
                "LARP",
                "LDP",
                "LDPK",
                "LT",
                "MPY",
                "MPYK",
                "PAC",
                "LAC",
                "SACL",
                "SACH",
                "ADD",
                "SUB",
                "ADDS",
                "SUBS",
                "AND",
                "OR",
                "XOR",
                "ZALH",
                "ZALS",
                "LAR",
                "SAR",
                "MAR",
            },
        )
        self.assertFalse(coverage["complete"])
        self.assertFalse(coverage["reserved_encoding_audit_complete"])

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
        self.assertIsNone(decode_word(self.database, 0x7F81))
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

    def test_pac_is_the_single_primary_documented_fixed_word(self) -> None:
        decoded = decode_word(self.database, 0x7F8E)
        self.assertIsNotNone(decoded)
        assert decoded is not None
        self.assertEqual(decoded[0]["mnemonic"], "PAC")
        self.assertEqual(decoded[1], {})
        self.assertIsNone(decode_word(self.database, 0x7F8D))
        self.assertIsNone(decode_word(self.database, 0x7F8F))

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
