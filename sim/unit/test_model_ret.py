from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import Tms32010Model


class RetModelTests(unittest.TestCase):
    def test_ret_loads_top_and_pops_with_bottom_duplication(self) -> None:
        model = Tms32010Model()
        model.program[0x456] = 0x7F8D
        model.state.pc = 0x456
        model.state.acc = 0x8123_4567
        model.state.p = 0x89AB_CDEF
        model.state.t = 0x8001
        model.state.ar = [0xA400, 0xBE01]
        model.state.stack = [0x123, 0x234, 0x345, 0x456]
        model.state.status.ov = True
        model.state.status.ovm = True
        model.state.status.intm = True
        model.state.status.arp = 1
        model.state.status.dp = 1
        before = model.architectural_state()

        trace = model.step()

        self.assertEqual(trace.mnemonic, "RET")
        self.assertEqual(trace.operands, {})
        self.assertEqual(trace.cycles, 2)
        self.assertEqual(model.cycle_count, 2)
        self.assertEqual(model.state.pc, 0x123)
        self.assertEqual(model.state.stack, [0x234, 0x345, 0x456, 0x456])
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
            [(0, "program", "instruction_fetch", 0x456, 0x7F8D)],
        )

    def test_eint_protects_ret_before_pending_interrupt_reentry(self) -> None:
        model = Tms32010Model()
        model.load_words([0x7F82, 0x7F8D])
        model.program[0x321] = 0x7F80
        model.state.stack = [0x321, 0x222, 0x111, 0x000]
        model.state.status.intm = True
        model.state.interrupt_pending = True

        eint = model.step()
        ret = model.step()

        self.assertEqual(eint.mnemonic, "EINT")
        self.assertEqual(ret.mnemonic, "RET")
        self.assertEqual(model.state.pc, 0x321)
        self.assertEqual(model.state.stack, [0x222, 0x111, 0x000, 0x000])
        self.assertTrue(
            model.architectural_state()["interrupt_entry_pending"]
        )

        entry = model.step()

        self.assertEqual(entry.mnemonic, "INTERRUPT")
        self.assertEqual(entry.operands["return_address"], 0x321)
        self.assertEqual(model.state.pc, 0x002)
        self.assertEqual(model.state.stack[0], 0x321)
        self.assertTrue(model.state.status.intm)


if __name__ == "__main__":
    unittest.main()
