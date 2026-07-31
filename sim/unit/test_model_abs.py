from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import Tms32010Model


class AbsModelTests(unittest.TestCase):
    def test_signed_boundaries_and_ovm_selection(self) -> None:
        cases = (
            (0x0000_0000, False, 0x0000_0000),
            (0x0000_0001, False, 0x0000_0001),
            (0x7FFF_FFFF, True, 0x7FFF_FFFF),
            (0xFFFF_FFFF, False, 0x0000_0001),
            (0xFFFF_0000, True, 0x0001_0000),
            (0x8000_0000, False, 0x8000_0000),
            (0x8000_0000, True, 0x7FFF_FFFF),
        )
        for accumulator, ovm, expected in cases:
            with self.subTest(accumulator=accumulator, ovm=ovm):
                model = Tms32010Model()
                model.state.acc = accumulator
                model.state.status.ovm = ovm
                model.program[0] = 0x7F88

                trace = model.step()

                self.assertEqual(trace.mnemonic, "ABS")
                self.assertEqual(trace.cycles, 1)
                self.assertEqual(model.state.acc, expected)
                self.assertEqual(model.state.pc, 1)
                self.assertEqual(model.cycle_count, 1)
                self.assertEqual(len(trace.transactions), 1)
                self.assertEqual(trace.transactions[0].space, "program")

    def test_preserves_ov_and_all_unrelated_state(self) -> None:
        for ov in (False, True):
            with self.subTest(ov=ov):
                model = Tms32010Model()
                model.state.acc = 0x8000_0000
                model.state.p = 0xDEAD_BEEF
                model.state.t = 0x8123
                model.state.ar[:] = [0xAAAA, 0x5555]
                model.state.stack[:] = [1, 2, 3, 4]
                model.state.status.ov = ov
                model.state.status.ovm = True
                model.state.status.intm = True
                model.state.status.arp = 1
                model.state.status.dp = 1
                model.data[17] = 0xCAFE
                model.program[0] = 0x7F88

                model.step()

                self.assertEqual(model.state.acc, 0x7FFF_FFFF)
                self.assertEqual(model.state.status.ov, ov)
                self.assertTrue(model.state.status.ovm)
                self.assertTrue(model.state.status.intm)
                self.assertTrue(model.state.status.arp)
                self.assertTrue(model.state.status.dp)
                self.assertEqual(model.state.p, 0xDEAD_BEEF)
                self.assertEqual(model.state.t, 0x8123)
                self.assertEqual(model.state.ar, [0xAAAA, 0x5555])
                self.assertEqual(model.state.stack, [1, 2, 3, 4])
                self.assertEqual(model.data[17], 0xCAFE)


if __name__ == "__main__":
    unittest.main()
