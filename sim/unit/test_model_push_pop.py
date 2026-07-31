from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import Tms32010Model


class PushPopModelTests(unittest.TestCase):
    def test_push_uses_low_accumulator_and_discards_old_bottom(self) -> None:
        model = Tms32010Model()
        model.program[0xFFF] = 0x7F9C
        model.state.pc = 0xFFF
        model.state.acc = 0x89AB_CDEF
        model.state.p = 0x8123_4567
        model.state.t = 0x8001
        model.state.ar = [0xA400, 0xBE01]
        model.state.stack = [0x111, 0x222, 0x333, 0x444]
        model.state.status.ov = True
        model.state.status.ovm = True
        model.state.status.intm = True
        model.state.status.arp = 1
        model.state.status.dp = 1
        model.cycle_count = 7
        before = model.architectural_state()

        trace = model.step()

        self.assertEqual(trace.mnemonic, "PUSH")
        self.assertEqual(trace.operands, {})
        self.assertEqual(trace.cycles, 2)
        self.assertEqual(model.cycle_count, 9)
        self.assertEqual(model.state.pc, 0x000)
        self.assertEqual(model.state.stack, [0xDEF, 0x111, 0x222, 0x333])
        after = model.architectural_state()
        for key in ("acc", "p", "t", "ar", "status", "interrupt_pending"):
            self.assertEqual(after[key], before[key])
        self.assertEqual(
            [
                (
                    transaction.cycle,
                    transaction.space,
                    transaction.operation,
                    transaction.address,
                    transaction.data,
                )
                for transaction in trace.transactions
            ],
            [(7, "program", "instruction_fetch", 0xFFF, 0x7F9C)],
        )

    def test_pop_zero_extends_top_and_duplicates_old_bottom(self) -> None:
        model = Tms32010Model()
        model.program[0x456] = 0x7F9D
        model.state.pc = 0x456
        model.state.acc = 0xFFFF_FFFF
        model.state.p = 0x8123_4567
        model.state.t = 0x8001
        model.state.ar = [0xA400, 0xBE01]
        model.state.stack = [0xABC, 0x234, 0x345, 0x456]
        model.state.status.ov = True
        model.state.status.ovm = True
        model.state.status.intm = True
        model.state.status.arp = 1
        model.state.status.dp = 1
        before = model.architectural_state()

        trace = model.step()

        self.assertEqual(trace.mnemonic, "POP")
        self.assertEqual(trace.operands, {})
        self.assertEqual(trace.cycles, 2)
        self.assertEqual(model.cycle_count, 2)
        self.assertEqual(model.state.pc, 0x457)
        self.assertEqual(model.state.acc, 0x0000_0ABC)
        self.assertEqual(model.state.stack, [0x234, 0x345, 0x456, 0x456])
        after = model.architectural_state()
        for key in ("p", "t", "ar", "status", "interrupt_pending"):
            self.assertEqual(after[key], before[key])
        self.assertEqual(
            [
                (
                    transaction.cycle,
                    transaction.space,
                    transaction.operation,
                    transaction.address,
                    transaction.data,
                )
                for transaction in trace.transactions
            ],
            [(0, "program", "instruction_fetch", 0x456, 0x7F9D)],
        )

    def test_repeated_pops_fill_stack_with_old_bottom(self) -> None:
        model = Tms32010Model()
        model.load_words([0x7F9D] * 4)
        model.state.stack = [0x111, 0x222, 0x333, 0x444]

        observed = []
        for _ in range(4):
            trace = model.step()
            observed.append(model.state.acc)
            self.assertEqual(trace.mnemonic, "POP")
            self.assertEqual(trace.cycles, 2)

        self.assertEqual(observed, [0x111, 0x222, 0x333, 0x444])
        self.assertEqual(model.state.stack, [0x444, 0x444, 0x444, 0x444])
        self.assertEqual(model.state.pc, 4)
        self.assertEqual(model.cycle_count, 8)

    def test_repeated_pushes_drop_oldest_bottom_without_overflow_flag(self) -> None:
        model = Tms32010Model()
        model.load_words([0x7F9C] * 5)
        model.state.stack = [0x111, 0x222, 0x333, 0x444]
        model.state.status.ov = True

        for value in range(1, 6):
            model.state.acc = 0xA000_0000 | value
            trace = model.step()
            self.assertEqual(trace.mnemonic, "PUSH")
            self.assertEqual(trace.cycles, 2)

        self.assertEqual(model.state.stack, [5, 4, 3, 2])
        self.assertTrue(model.state.status.ov)
        self.assertEqual(model.state.pc, 5)
        self.assertEqual(model.cycle_count, 10)


if __name__ == "__main__":
    unittest.main()
