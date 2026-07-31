from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import Tms32010Model


class CalaModelTests(unittest.TestCase):
    def test_cala_pushes_pc_plus_one_and_selects_accumulator_target(self) -> None:
        model = Tms32010Model()
        model.program[0x456] = 0x7F8C
        model.state.pc = 0x456
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

        self.assertEqual(trace.mnemonic, "CALA")
        self.assertEqual(trace.operands, {})
        self.assertEqual(trace.cycles, 2)
        self.assertEqual(model.cycle_count, 9)
        self.assertEqual(model.state.pc, 0xDEF)
        self.assertEqual(model.state.stack, [0x457, 0x111, 0x222, 0x333])
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
            [(7, "program", "instruction_fetch", 0x456, 0x7F8C)],
        )

    def test_cala_wraps_return_address_at_program_space_end(self) -> None:
        model = Tms32010Model()
        model.program[0xFFF] = 0x7F8C
        model.state.pc = 0xFFF
        model.state.acc = 0xF123
        model.state.stack = [0xAAA, 0xBBB, 0xCCC, 0xDDD]

        trace = model.step()

        self.assertEqual(trace.mnemonic, "CALA")
        self.assertEqual(trace.cycles, 2)
        self.assertEqual(model.state.pc, 0x123)
        self.assertEqual(model.state.stack, [0x000, 0xAAA, 0xBBB, 0xCCC])

    def test_nested_cala_calls_discard_the_oldest_bottom(self) -> None:
        model = Tms32010Model()
        model.state.stack = [0xA00, 0xB00, 0xC00, 0xD00]
        addresses = [0x000, 0x101, 0x202, 0x303, 0x404]
        for address in addresses:
            model.program[address] = 0x7F8C

        for target in addresses[1:] + [0x505]:
            model.state.acc = target
            trace = model.step()
            self.assertEqual(trace.mnemonic, "CALA")
            self.assertEqual(trace.cycles, 2)

        self.assertEqual(model.state.pc, 0x505)
        self.assertEqual(model.state.stack, [0x405, 0x304, 0x203, 0x102])
        self.assertEqual(model.cycle_count, 10)


if __name__ == "__main__":
    unittest.main()
