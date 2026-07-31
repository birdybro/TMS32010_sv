from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import Tms32010Model


class PacModelTests(unittest.TestCase):
    def test_copies_every_product_bit_in_one_program_only_cycle(self) -> None:
        for product in (
            0x0000_0000,
            0x0000_0001,
            0x7FFF_FFFF,
            0x8000_0000,
            0xFFFF_FFFF,
            0xC000_0000,
        ):
            with self.subTest(product=product):
                model = Tms32010Model()
                model.state.acc = 0x1234_5678
                model.state.p = product
                model.program[0] = 0x7F8E

                trace = model.step()

                self.assertEqual(trace.mnemonic, "PAC")
                self.assertEqual(trace.cycles, 1)
                self.assertEqual(model.state.acc, product)
                self.assertEqual(model.state.p, product)
                self.assertEqual(len(trace.transactions), 1)
                self.assertEqual(trace.transactions[0].space, "program")

    def test_preserves_non_accumulator_state_and_internal_ram(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0xAAAA_5555
        model.state.p = 0xDEAD_BEEF
        model.state.t = 0x8123
        model.state.ar[:] = [0xAAAA, 0x5555]
        model.state.stack[:] = [1, 2, 3, 4]
        model.state.status.ov = True
        model.state.status.ovm = True
        model.state.status.intm = True
        model.state.status.arp = 1
        model.state.status.dp = 1
        model.state.interrupt_pending = True
        model.data[17] = 0xCAFE
        model.program[0] = 0x7F8E

        trace = model.step()

        self.assertEqual(model.state.acc, 0xDEAD_BEEF)
        self.assertEqual(model.state.p, 0xDEAD_BEEF)
        self.assertEqual(model.state.t, 0x8123)
        self.assertEqual(model.state.ar, [0xAAAA, 0x5555])
        self.assertEqual(model.state.stack, [1, 2, 3, 4])
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)
        self.assertTrue(model.state.status.intm)
        self.assertTrue(model.state.status.arp)
        self.assertTrue(model.state.status.dp)
        self.assertTrue(model.state.interrupt_pending)
        self.assertEqual(model.data[17], 0xCAFE)
        self.assertEqual(model.state.pc, 1)
        self.assertEqual(model.cycle_count, 1)
        self.assertEqual(len(trace.transactions), 1)


if __name__ == "__main__":
    unittest.main()
