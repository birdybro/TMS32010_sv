from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedProgramOperand,
)


class ModelBanzTests(unittest.TestCase):
    def test_nonzero_counter_branches_then_decrements_low_nine_bits(self) -> None:
        model = Tms32010Model()
        model.load_words([0xF400, 0x035A])
        model.state.status.arp = 1
        model.state.ar = [0xAAAA, 0xBE01]
        model.state.acc = 0x1234_5678
        model.state.status.ov = True
        model.state.status.ovm = True
        model.state.status.intm = True

        trace = model.step()

        self.assertEqual(trace.mnemonic, "BANZ")
        self.assertEqual(trace.cycles, 2)
        self.assertEqual(
            trace.operands,
            {
                "program_address": 0x35A,
                "auxiliary_register": 1,
                "branch_taken": 1,
            },
        )
        self.assertEqual(model.state.pc, 0x35A)
        self.assertEqual(model.state.ar, [0xAAAA, 0xBE00])
        self.assertEqual(model.state.acc, 0x1234_5678)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)
        self.assertTrue(model.state.status.intm)
        self.assertEqual(model.cycle_count, 2)
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
                (0, "instruction_fetch", 0x000, 0xF400),
                (1, "following_word_fetch", 0x001, 0x035A),
            ],
        )

    def test_zero_counter_falls_through_and_wraps_modulo_512(self) -> None:
        model = Tms32010Model()
        model.load_words([0xF400, 0x03AA])
        model.state.ar[0] = 0xA400

        trace = model.step()

        self.assertEqual(trace.operands["branch_taken"], 0)
        self.assertEqual(model.state.pc, 2)
        self.assertEqual(model.state.ar[0], 0xA5FF)
        self.assertEqual(model.cycle_count, 2)

    def test_test_occurs_before_decrement(self) -> None:
        model = Tms32010Model()
        model.load_words([0xF400, 0x0123])
        model.state.ar[0] = 1

        trace = model.step()

        self.assertEqual(trace.operands["branch_taken"], 1)
        self.assertEqual(model.state.pc, 0x123)
        self.assertEqual(model.state.ar[0], 0)

    def test_operand_fetch_and_fallthrough_wrap_program_space(self) -> None:
        model = Tms32010Model()
        model.program[0xFFF] = 0xF400
        model.program[0x000] = 0x0555
        model.state.pc = 0xFFF
        model.state.ar[0] = 0

        trace = model.step()

        self.assertEqual(model.state.pc, 1)
        self.assertEqual(
            [transaction.address for transaction in trace.transactions],
            [0xFFF, 0x000],
        )

    def test_noncanonical_operand_word_traps_before_state_change(self) -> None:
        model = Tms32010Model()
        model.load_words([0xF400, 0xF123])
        model.state.ar[0] = 4
        before = model.architectural_state()

        with self.assertRaises(UnsupportedProgramOperand) as caught:
            model.step()

        self.assertEqual(caught.exception.address, 1)
        self.assertEqual(caught.exception.word, 0xF123)
        self.assertEqual(model.architectural_state(), before)


if __name__ == "__main__":
    unittest.main()
