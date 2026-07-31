from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
    UnsupportedOpcode,
)


class LtModelTests(unittest.TestCase):
    def test_direct_page_one_loads_all_source_bits_and_preserves_status(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.state.status.ov = True
        model.state.status.ovm = True
        model.state.acc = 0x1234_5678
        model.state.t = 0xAAAA
        model.data[143] = 0xFEDC
        model.program[0] = 0x6A0F

        trace = model.step()

        self.assertEqual(model.state.t, 0xFEDC)
        self.assertEqual(model.state.acc, 0x1234_5678)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)
        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(trace.transactions[1].operation, "read")
        self.assertEqual(trace.transactions[1].data, 0xFEDC)
        self.assertEqual(trace.cycles, 1)

    def test_indirect_read_precedes_increment_and_arp_replacement(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 0
        model.state.ar[0] = 0xAA8F
        model.data[143] = 0x8001
        model.program[0] = 0x6AA1

        trace = model.step()

        self.assertEqual(model.state.t, 0x8001)
        self.assertEqual(model.state.ar[0], 0xAA90)
        self.assertEqual(model.state.status.arp, 1)
        self.assertEqual(trace.transactions[1].address, 143)

    def test_indirect_decrement_wraps_low_nine_bits(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 1
        model.state.ar[1] = 0xFE00
        model.data[0] = 0x0000
        model.program[0] = 0x6A90

        trace = model.step()

        self.assertEqual(model.state.t, 0x0000)
        self.assertEqual(model.state.ar[1], 0xFFFF)
        self.assertEqual(model.state.status.arp, 0)
        self.assertEqual(trace.transactions[1].address, 0)

    def test_unresolved_direct_address_traps_without_state_change(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.state.t = 0x55AA
        model.program[0] = 0x6A10
        before = model.architectural_state()

        with self.assertRaises(UnsupportedDataAddress):
            model.step()

        self.assertEqual(model.architectural_state(), before)

    def test_reserved_indirect_controls_trap(self) -> None:
        for opcode in (0x6AC8, 0x6A8A, 0x6AB8):
            with self.subTest(opcode=opcode):
                model = Tms32010Model()
                model.program[0] = opcode
                with self.assertRaises(UnsupportedOpcode):
                    model.step()


if __name__ == "__main__":
    unittest.main()
