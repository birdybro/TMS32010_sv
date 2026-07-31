from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedProgramOperand,
)

BRANCHES = {
    "BLZ": 0xFA00,
    "BLEZ": 0xFB00,
    "BGZ": 0xFC00,
    "BGEZ": 0xFD00,
    "BNZ": 0xFE00,
    "BZ": 0xFF00,
}

TAKEN_BY_VALUE = {
    0x0000_0000: {"BGEZ", "BLEZ", "BZ"},
    0x0000_0001: {"BGEZ", "BGZ", "BNZ"},
    0x7FFF_FFFF: {"BGEZ", "BGZ", "BNZ"},
    0xFFFF_FFFF: {"BLEZ", "BLZ", "BNZ"},
    0x8000_0000: {"BLEZ", "BLZ", "BNZ"},
}


class AccumulatorBranchModelTests(unittest.TestCase):
    def test_signed_and_zero_predicates_cover_boundaries(self) -> None:
        for accumulator, taken_mnemonics in TAKEN_BY_VALUE.items():
            for mnemonic, opcode in BRANCHES.items():
                with self.subTest(
                    accumulator=f"0x{accumulator:08x}",
                    mnemonic=mnemonic,
                ):
                    model = Tms32010Model()
                    model.load_words([opcode, 0x035A])
                    model.state.acc = accumulator
                    model.state.p = 0x89AB_CDEF
                    model.state.t = 0x8001
                    model.state.ar = [0xA400, 0xBE01]
                    model.state.stack = [1, 2, 3, 4]
                    model.state.status.ov = True
                    model.state.status.ovm = True
                    model.state.status.intm = True
                    model.state.status.arp = 1
                    model.state.status.dp = 1
                    model.state.interrupt_pending = True
                    before = model.architectural_state()
                    expected_taken = mnemonic in taken_mnemonics

                    trace = model.step()

                    self.assertEqual(trace.mnemonic, mnemonic)
                    self.assertEqual(
                        trace.operands,
                        {
                            "program_address": 0x35A,
                            "branch_taken": int(expected_taken),
                        },
                    )
                    self.assertEqual(trace.cycles, 2)
                    self.assertEqual(
                        model.state.pc,
                        0x35A if expected_taken else 2,
                    )
                    self.assertEqual(model.cycle_count, 2)
                    after = model.architectural_state()
                    for key in (
                        "acc",
                        "p",
                        "t",
                        "ar",
                        "stack",
                        "status",
                        "interrupt_pending",
                    ):
                        self.assertEqual(after[key], before[key])

    def test_every_condition_has_two_program_transactions(self) -> None:
        for mnemonic, opcode in BRANCHES.items():
            with self.subTest(mnemonic=mnemonic):
                model = Tms32010Model()
                model.load_words([opcode, 0x0123])

                trace = model.step()

                self.assertEqual(
                    [
                        (
                            transaction.cycle,
                            transaction.operation,
                            transaction.address,
                            transaction.data,
                        )
                        for transaction in trace.transactions
                    ],
                    [
                        (0, "instruction_fetch", 0, opcode),
                        (1, "following_word_fetch", 1, 0x0123),
                    ],
                )

    def test_every_condition_rejects_a_noncanonical_target_before_effects(
        self,
    ) -> None:
        for mnemonic, opcode in BRANCHES.items():
            with self.subTest(mnemonic=mnemonic):
                model = Tms32010Model()
                model.load_words([opcode, 0xF123])
                model.state.acc = 0x8000_0000
                before = model.architectural_state()

                with self.assertRaises(UnsupportedProgramOperand):
                    model.step()

                self.assertEqual(model.architectural_state(), before)


if __name__ == "__main__":
    unittest.main()
