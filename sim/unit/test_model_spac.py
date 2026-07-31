from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import Tms32010Model


class SpacModelTests(unittest.TestCase):
    def _execute(
        self,
        accumulator: int,
        product: int,
        *,
        overflow: bool = False,
        overflow_mode: bool = False,
    ) -> Tms32010Model:
        model = Tms32010Model()
        model.state.acc = accumulator
        model.state.p = product
        model.state.status.ov = overflow
        model.state.status.ovm = overflow_mode
        model.program[0] = 0x7F90

        trace = model.step()

        self.assertEqual(trace.mnemonic, "SPAC")
        self.assertEqual(trace.cycles, 1)
        self.assertEqual(model.state.p, product & 0xFFFF_FFFF)
        self.assertEqual(model.state.pc, 1)
        self.assertEqual(model.cycle_count, 1)
        self.assertEqual(len(trace.transactions), 1)
        self.assertEqual(trace.transactions[0].space, "program")
        self.assertEqual(trace.transactions[0].operation, "instruction_fetch")
        return model

    def test_primary_example_subtracts_product_from_accumulator(self) -> None:
        model = self._execute(60, 36)

        self.assertEqual(model.state.acc, 24)
        self.assertFalse(model.state.status.ov)
        self.assertFalse(model.state.status.ovm)

    def test_positive_overflow_wraps_when_ovm_is_clear(self) -> None:
        model = self._execute(0x7FFF_FFFE, 0xFFFF_FFFE)

        self.assertEqual(model.state.acc, 0x8000_0000)
        self.assertTrue(model.state.status.ov)
        self.assertFalse(model.state.status.ovm)

    def test_positive_overflow_saturates_when_ovm_is_set(self) -> None:
        model = self._execute(
            0x7FFF_FFFE,
            0xFFFF_FFFE,
            overflow_mode=True,
        )

        self.assertEqual(model.state.acc, 0x7FFF_FFFF)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)

    def test_negative_overflow_wraps_when_ovm_is_clear(self) -> None:
        model = self._execute(0x8000_0001, 0x0000_0002)

        self.assertEqual(model.state.acc, 0x7FFF_FFFF)
        self.assertTrue(model.state.status.ov)
        self.assertFalse(model.state.status.ovm)

    def test_negative_overflow_saturates_when_ovm_is_set(self) -> None:
        model = self._execute(
            0x8000_0001,
            0x0000_0002,
            overflow_mode=True,
        )

        self.assertEqual(model.state.acc, 0x8000_0000)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)

    def test_nonoverflowing_subtraction_preserves_sticky_ov_and_other_state(
        self,
    ) -> None:
        model = Tms32010Model()
        model.state.acc = 0x0000_0010
        model.state.p = 0x0000_0008
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
        model.program[0] = 0x7F90

        trace = model.step()

        self.assertEqual(model.state.acc, 0x0000_0008)
        self.assertEqual(model.state.p, 0x0000_0008)
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
        self.assertEqual(len(trace.transactions), 1)


if __name__ == "__main__":
    unittest.main()
