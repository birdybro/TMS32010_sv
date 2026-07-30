from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
)


class LogicModelTests(unittest.TestCase):
    def test_xor_changes_low_half_and_preserves_high_half_and_status(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x1234_5678
        model.state.status.ov = True
        model.state.status.ovm = True
        model.data[5] = 0xF0F0
        model.program[0] = 0x7805

        trace = model.step()

        self.assertEqual(model.state.acc, 0x1234_A688)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)
        self.assertEqual(trace.transactions[1].space, "data")
        self.assertEqual(trace.transactions[1].operation, "read")
        self.assertEqual(trace.transactions[1].address, 5)
        self.assertEqual(trace.transactions[1].data, 0xF0F0)
        self.assertEqual(trace.cycles, 1)

    def test_and_changes_low_half_and_clears_high_half(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0xABCD_5678
        model.state.status.ov = True
        model.state.status.ovm = True
        model.data[6] = 0x00FF
        model.program[0] = 0x7906

        model.step()

        self.assertEqual(model.state.acc, 0x0000_0078)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)

    def test_or_changes_low_half_and_preserves_high_half(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x1234_0678
        model.state.status.ov = True
        model.state.status.ovm = True
        model.data[7] = 0xF000
        model.program[0] = 0x7A07

        model.step()

        self.assertEqual(model.state.acc, 0x1234_F678)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)

    def test_direct_page_one_reaches_last_physical_word(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0xCAFE_0F0F
        model.state.status.dp = 1
        model.data[143] = 0xFFFF
        model.program[0] = 0x780F

        model.step()

        self.assertEqual(model.state.acc, 0xCAFE_F0F0)

    def test_indirect_read_precedes_counter_and_arp_update(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0xBEEF_0FF0
        model.state.status.arp = 0
        model.state.ar[0] = 0xAA8F
        model.data[143] = 0x00FF
        model.program[0] = 0x79A1

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(model.state.acc, 0x0000_00F0)
        self.assertEqual(model.state.ar[0], 0xAA90)
        self.assertEqual(model.state.status.arp, 1)

    def test_each_logic_family_rejects_unresolved_address_without_change(
        self,
    ) -> None:
        for opcode in (0x7810, 0x7910, 0x7A10):
            model = Tms32010Model()
            model.state.acc = 0x1234_5678
            model.state.status.dp = 1
            model.program[0] = opcode
            before = model.architectural_state()

            with self.subTest(opcode=opcode):
                with self.assertRaises(UnsupportedDataAddress):
                    model.step()
                self.assertEqual(model.architectural_state(), before)


if __name__ == "__main__":
    unittest.main()
