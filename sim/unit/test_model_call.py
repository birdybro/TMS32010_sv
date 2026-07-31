from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedProgramOperand,
)


class CallModelTests(unittest.TestCase):
    def test_call_pushes_return_address_and_selects_target(self) -> None:
        model = Tms32010Model()
        model.load_words([0xF800, 0x035A])
        model.state.acc = 0x8123_4567
        model.state.p = 0x89AB_CDEF
        model.state.t = 0x8001
        model.state.ar = [0xA400, 0xBE01]
        model.state.stack = [0x111, 0x222, 0x333, 0x444]
        model.state.status.ov = True
        model.state.status.ovm = True
        model.state.status.intm = True
        model.state.status.arp = 1
        model.state.status.dp = 1
        model.state.interrupt_pending = True
        before = model.architectural_state()

        trace = model.step()

        self.assertEqual(trace.mnemonic, "CALL")
        self.assertEqual(trace.operands, {"program_address": 0x35A})
        self.assertEqual(trace.cycles, 2)
        self.assertEqual(model.state.pc, 0x35A)
        self.assertEqual(model.state.stack, [0x002, 0x111, 0x222, 0x333])
        self.assertEqual(model.cycle_count, 2)
        after = model.architectural_state()
        for key in (
            "acc",
            "p",
            "t",
            "ar",
            "status",
            "interrupt_pending",
        ):
            self.assertEqual(after[key], before[key])
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
                (0, "instruction_fetch", 0, 0xF800),
                (1, "following_word_fetch", 1, 0x035A),
            ],
        )

    def test_call_at_program_end_wraps_operand_and_return_address(self) -> None:
        model = Tms32010Model()
        model.program[0xFFF] = 0xF800
        model.program[0x000] = 0x0123
        model.state.pc = 0xFFF
        model.state.stack = [0xAAA, 0xBBB, 0xCCC, 0xDDD]

        trace = model.step()

        self.assertEqual(
            [transaction.address for transaction in trace.transactions],
            [0xFFF, 0x000],
        )
        self.assertEqual(model.state.pc, 0x123)
        self.assertEqual(model.state.stack, [0x001, 0xAAA, 0xBBB, 0xCCC])

    def test_noncanonical_target_traps_before_stack_or_pc_effects(self) -> None:
        model = Tms32010Model()
        model.load_words([0xF800, 0xF123])
        model.state.stack = [0x111, 0x222, 0x333, 0x444]
        before = model.architectural_state()

        with self.assertRaises(UnsupportedProgramOperand):
            model.step()

        self.assertEqual(model.architectural_state(), before)


if __name__ == "__main__":
    unittest.main()
