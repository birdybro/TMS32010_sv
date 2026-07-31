from __future__ import annotations

import json
import unittest
from pathlib import Path

from sim.reference_models.tms32010_model import Tms32010Model
from tools.assembler.tms32010_as import Assembler
from tools.disassembler.tms32010_dis import Disassembler

ROOT = Path(__file__).resolve().parents[2]
PROGRAM_DIR = ROOT / "sim" / "programs" / "hard_drivin_smoke"


def _hex(value: str) -> int:
    return int(value, 16)


class HardDrivinSmokeProgramTests(unittest.TestCase):
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
        model.bio_input_high = False
        for address, word in self.fixture["initial_data"].items():
            model.data[_hex(address)] = _hex(word)
        for port, word in self.fixture["io_inputs"].items():
            model.io_input[int(port)] = _hex(word)

        traces = []
        while model.state.pc != _hex(self.fixture["expected_final"]["pc"]):
            traces.append(model.step())
        return model, traces

    def test_image_is_fixed_and_round_trips(self) -> None:
        assembled = Assembler().assemble_file(
            PROGRAM_DIR / "hard_drivin_smoke.asm"
        )
        expected = dict(enumerate(self.expected_words))

        self.assertEqual(assembled.words, expected)
        disassembled = Disassembler().disassemble_source(self.expected_words)
        self.assertEqual(Assembler().assemble_text(disassembled).words, expected)

    def test_synthetic_board_state_and_cycle_total(self) -> None:
        model, traces = self._run_program()
        expected = self.fixture["expected_final"]

        self.assertEqual(len(traces), 12)
        self.assertEqual(model.state.pc, _hex(expected["pc"]))
        self.assertEqual(model.state.acc, _hex(expected["acc"]))
        self.assertEqual(model.cycle_count, expected["cycles"])
        self.assertNotIn(0x00B, [trace.pc for trace in traces])
        for address, word in expected["data"].items():
            self.assertEqual(model.data[_hex(address)], _hex(word))
        for port, word in expected["io_outputs"].items():
            self.assertEqual(model.io_output[int(port)], _hex(word))

        raw_dac = model.io_output[0]
        self.assertEqual(
            (raw_dac >> 4) & 0x0FFF,
            _hex(expected["physical_dac_code"]),
        )
        self.assertEqual(
            ((raw_dac >> 4) ^ 0x800) & 0x0FFF,
            _hex(expected["mame_dac_12bit"]),
        )
        self.assertEqual(model.io_output[6] & 0xF, _hex(expected["sound_rom_bank"]))
        self.assertEqual(model.io_output[7], _hex(expected["sound_rom_address"]))

    def test_logical_program_and_io_transactions_are_exact(self) -> None:
        _, traces = self._run_program()
        actual_program = [
            (
                transaction.cycle,
                transaction.operation,
                transaction.address,
                transaction.data,
            )
            for trace in traces
            for transaction in trace.transactions
            if transaction.space == "program"
        ]
        expected_program = [
            (cycle, operation, _hex(address), _hex(word))
            for cycle, operation, address, word in self.fixture[
                "program_transactions"
            ]
        ]
        self.assertEqual(actual_program, expected_program)

        actual_io = [
            (
                transaction.cycle,
                transaction.operation,
                transaction.address,
                transaction.data,
            )
            for trace in traces
            for transaction in trace.transactions
            if transaction.space == "io"
        ]
        expected_io = [
            (cycle, operation, port, _hex(word))
            for cycle, operation, port, word in self.fixture["io_transactions"]
        ]
        self.assertEqual(actual_io, expected_io)


if __name__ == "__main__":
    unittest.main()
