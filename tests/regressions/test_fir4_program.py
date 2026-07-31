from __future__ import annotations

import json
import unittest
from pathlib import Path

from sim.reference_models.tms32010_model import Tms32010Model
from tools.assembler.tms32010_as import Assembler
from tools.disassembler.tms32010_dis import Disassembler

ROOT = Path(__file__).resolve().parents[2]
PROGRAM_DIR = ROOT / "sim" / "programs" / "fir4"


def _hex(value: str) -> int:
    return int(value, 16)


class Fir4ProgramTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.fixture = json.loads(
            (PROGRAM_DIR / "expected.json").read_text(encoding="utf-8")
        )
        cls.expected_words = [
            _hex(word) for word in cls.fixture["program_words"]
        ]

    def _run_program(self) -> tuple[Tms32010Model, list[object]]:
        model = Tms32010Model()
        model.load_words(self.expected_words)
        for address, word in self.fixture["initial_data"].items():
            model.data[_hex(address)] = _hex(word)
        traces = [model.step() for _ in self.expected_words]
        return model, traces

    def test_hand_fixed_image_and_lossless_round_trip(self) -> None:
        assembled = Assembler().assemble_file(PROGRAM_DIR / "fir4.asm")
        expected = dict(enumerate(self.expected_words))

        self.assertEqual(assembled.words, expected)
        disassembled = Disassembler().disassemble_source(self.expected_words)
        self.assertEqual(Assembler().assemble_text(disassembled).words, expected)

    def test_q15_result_history_and_cycle_total(self) -> None:
        model, traces = self._run_program()
        expected = self.fixture["expected_final"]

        self.assertEqual(
            [trace.mnemonic for trace in traces],
            [
                "ZAC",
                "LT",
                "MPY",
                "LTD",
                "MPY",
                "LTD",
                "MPY",
                "LTD",
                "MPY",
                "APAC",
                "SACH",
                "NOP",
            ],
        )
        self.assertEqual([trace.cycles for trace in traces], [1] * 12)
        self.assertEqual(model.state.acc, _hex(expected["acc"]))
        self.assertEqual(model.state.p, _hex(expected["p"]))
        self.assertEqual(model.state.t, _hex(expected["t"]))
        self.assertEqual(model.state.pc, _hex(expected["pc"]))
        self.assertEqual(model.cycle_count, expected["cycles"])
        self.assertEqual(
            model.data[_hex(expected["output_address"])],
            _hex(expected["output_word"]),
        )
        for address, word in expected["sample_history"].items():
            self.assertEqual(model.data[_hex(address)], _hex(word))
        self.assertFalse(model.state.status.ov)
        self.assertFalse(model.state.status.ovm)

    def test_program_fetch_and_data_transaction_trace(self) -> None:
        _, traces = self._run_program()

        for cycle, (trace, opcode) in enumerate(
            zip(traces, self.expected_words, strict=True)
        ):
            program_transactions = [
                transaction
                for transaction in trace.transactions
                if transaction.space == "program"
            ]
            self.assertEqual(len(program_transactions), 1)
            fetch = program_transactions[0]
            self.assertEqual(
                (
                    fetch.cycle,
                    fetch.operation,
                    fetch.address,
                    fetch.data,
                ),
                (cycle, "instruction_fetch", cycle, opcode),
            )

        actual_data = [
            (
                transaction.cycle,
                transaction.operation,
                transaction.address,
                transaction.data,
            )
            for trace in traces
            for transaction in trace.transactions
            if transaction.space == "data"
        ]
        expected_data = [
            (cycle, operation, _hex(address), _hex(word))
            for cycle, operation, address, word in self.fixture[
                "data_transactions"
            ]
        ]
        self.assertEqual(actual_data, expected_data)


if __name__ == "__main__":
    unittest.main()
