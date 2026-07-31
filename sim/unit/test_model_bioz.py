from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedProgramOperand,
)


class BiozModelTests(unittest.TestCase):
    def test_low_input_branches_and_preserves_architectural_state(self) -> None:
        model = Tms32010Model()
        model.load_words([0xF600, 0x035A])
        model.bio_input_high = False
        model.state.acc = 0x8123_4567
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

        trace = model.step()

        self.assertEqual(trace.mnemonic, "BIOZ")
        self.assertEqual(
            trace.operands,
            {"program_address": 0x35A, "branch_taken": 1},
        )
        self.assertEqual(trace.cycles, 2)
        self.assertEqual(model.state.pc, 0x35A)
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

    def test_high_input_falls_through(self) -> None:
        model = Tms32010Model()
        model.load_words([0xF600, 0x035A])
        self.assertTrue(model.bio_input_high)

        trace = model.step()

        self.assertEqual(
            trace.operands,
            {"program_address": 0x35A, "branch_taken": 0},
        )
        self.assertEqual(model.state.pc, 2)
        self.assertEqual(trace.cycles, 2)

    def test_both_input_levels_have_two_program_transactions(self) -> None:
        for input_high in (False, True):
            with self.subTest(input_high=input_high):
                model = Tms32010Model()
                model.load_words([0xF600, 0x0123])
                model.bio_input_high = input_high

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
                        (0, "instruction_fetch", 0, 0xF600),
                        (1, "following_word_fetch", 1, 0x0123),
                    ],
                )

    def test_noncanonical_target_traps_before_testing_pin(self) -> None:
        model = Tms32010Model()
        model.load_words([0xF600, 0xF123])
        model.bio_input_high = False
        before = model.architectural_state()

        with self.assertRaises(UnsupportedProgramOperand):
            model.step()

        self.assertEqual(model.architectural_state(), before)


if __name__ == "__main__":
    unittest.main()
