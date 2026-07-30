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
            {"LACK", "NOP", "ZAC", "ROVM", "SOVM", "LARK", "LARP", "LDPK"},
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

    def test_fixture_provenance_is_independent(self) -> None:
        provenance = self.fixtures["provenance"].lower()
        self.assertIn("manually transcribed", provenance)
        self.assertIn("never generated", provenance)


if __name__ == "__main__":
    unittest.main()
