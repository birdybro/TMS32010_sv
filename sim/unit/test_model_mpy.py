from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
    UnsupportedOpcode,
)


class MpyModelTests(unittest.TestCase):
    def _multiply(self, t_value: int, data_value: int) -> Tms32010Model:
        model = Tms32010Model()
        model.state.t = t_value
        model.data[0] = data_value
        model.program[0] = 0x6D00
        trace = model.step()
        self.assertEqual(trace.cycles, 1)
        self.assertEqual(trace.transactions[1].operation, "read")
        return model

    def test_signed_product_boundaries(self) -> None:
        cases = (
            (0x0000, 0xFFFF, 0x0000_0000),
            (0x0001, 0xFFFF, 0xFFFF_FFFF),
            (0xFFFF, 0xFFFF, 0x0000_0001),
            (0x7FFF, 0x7FFF, 0x3FFF_0001),
            (0x8000, 0x0001, 0xFFFF_8000),
            (0x7FFF, 0x8000, 0xC000_8000),
        )
        for t_value, data_value, expected in cases:
            with self.subTest(t=t_value, data=data_value):
                model = self._multiply(t_value, data_value)
                self.assertEqual(model.state.p, expected)

    def test_original_hardware_most_negative_exception(self) -> None:
        model = self._multiply(0x8000, 0x8000)
        self.assertEqual(model.state.p, 0xC000_0000)

    def test_direct_page_one_preserves_accumulator_t_and_status(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.state.status.ov = True
        model.state.status.ovm = True
        model.state.acc = 0x1234_5678
        model.state.t = 0xFFFE
        model.data[143] = 0x0003
        model.program[0] = 0x6D0F

        trace = model.step()

        self.assertEqual(model.state.p, 0xFFFF_FFFA)
        self.assertEqual(model.state.acc, 0x1234_5678)
        self.assertEqual(model.state.t, 0xFFFE)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)
        self.assertEqual(trace.operands["effective_address"], 143)

    def test_indirect_read_precedes_counter_and_arp_update(self) -> None:
        model = Tms32010Model()
        model.state.t = 0x0006
        model.state.status.arp = 0
        model.state.ar[0] = 0xAA8F
        model.data[143] = 0x0007
        model.program[0] = 0x6DA1

        trace = model.step()

        self.assertEqual(model.state.p, 0x0000_002A)
        self.assertEqual(model.state.ar[0], 0xAA90)
        self.assertEqual(model.state.status.arp, 1)
        self.assertEqual(trace.transactions[1].address, 143)

    def test_unresolved_direct_address_traps_without_state_change(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.state.t = 0x1234
        model.state.p = 0x55AA_55AA
        model.program[0] = 0x6D10
        before = model.architectural_state()

        with self.assertRaises(UnsupportedDataAddress):
            model.step()

        self.assertEqual(model.architectural_state(), before)

    def test_reserved_indirect_controls_trap(self) -> None:
        for opcode in (0x6DC8, 0x6D8A, 0x6DB8):
            with self.subTest(opcode=opcode):
                model = Tms32010Model()
                model.program[0] = opcode
                with self.assertRaises(UnsupportedOpcode):
                    model.step()


if __name__ == "__main__":
    unittest.main()
