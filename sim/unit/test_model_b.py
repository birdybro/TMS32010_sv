from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedProgramOperand,
)


class ModelBTests(unittest.TestCase):
    def test_unconditional_branch_reads_target_and_preserves_state(self) -> None:
        model = Tms32010Model()
        model.load_words([0xF900, 0x035A])
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
        before = model.architectural_state()

        trace = model.step()

        self.assertEqual(trace.mnemonic, "B")
        self.assertEqual(trace.operands, {"program_address": 0x35A})
        self.assertEqual(trace.cycles, 2)
        self.assertEqual(model.state.pc, 0x35A)
        self.assertEqual(model.cycle_count, 2)
        after = model.architectural_state()
        self.assertEqual(
            {
                key: value
                for key, value in after.items()
                if key not in {"pc", "cycle_count"}
            },
            {
                key: value
                for key, value in before.items()
                if key not in {"pc", "cycle_count"}
            },
        )
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
                (0, "instruction_fetch", 0x000, 0xF900),
                (1, "following_word_fetch", 0x001, 0x035A),
            ],
        )

    def test_branch_can_target_its_own_opcode(self) -> None:
        model = Tms32010Model()
        model.load_words([0xF900, 0x0000])

        first = model.step()
        second = model.step()

        self.assertEqual(first.state_after["pc"], 0)
        self.assertEqual(second.state_after["pc"], 0)
        self.assertEqual(model.cycle_count, 4)

    def test_operand_fetch_wraps_at_end_of_program_space(self) -> None:
        model = Tms32010Model()
        model.program[0xFFF] = 0xF900
        model.program[0x000] = 0x0123
        model.state.pc = 0xFFF

        trace = model.step()

        self.assertEqual(model.state.pc, 0x123)
        self.assertEqual(
            [transaction.address for transaction in trace.transactions],
            [0xFFF, 0x000],
        )

    def test_noncanonical_target_traps_before_architectural_effects(self) -> None:
        model = Tms32010Model()
        model.load_words([0xF900, 0xF123])
        model.state.acc = 0xDEAD_BEEF
        before = model.architectural_state()

        with self.assertRaises(UnsupportedProgramOperand) as caught:
            model.step()

        self.assertEqual(caught.exception.address, 1)
        self.assertEqual(caught.exception.word, 0xF123)
        self.assertEqual(model.architectural_state(), before)


if __name__ == "__main__":
    unittest.main()
