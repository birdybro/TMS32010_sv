from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
)


class SaclModelTests(unittest.TestCase):
    def test_direct_store_copies_only_accumulator_low_word(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0xA5A5_8421
        model.state.status.ov = True
        model.state.status.ovm = True
        model.program[0] = 0x5023

        trace = model.step()

        self.assertEqual(model.data[0x23], 0x8421)
        self.assertEqual(model.state.acc, 0xA5A5_8421)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)
        writes = [
            transaction
            for transaction in trace.transactions
            if transaction.space == "data"
        ]
        self.assertEqual(len(writes), 1)
        self.assertEqual(writes[0].operation, "write")
        self.assertEqual(writes[0].address, 0x23)
        self.assertEqual(writes[0].data, 0x8421)

    def test_direct_page_one_reaches_last_physical_word(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.state.acc = 0x1234_5678
        model.program[0] = 0x500F

        model.step()

        self.assertEqual(model.data[143], 0x5678)

    def test_indirect_uses_old_address_then_updates_counter_and_arp(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 0
        model.state.ar[0] = 0xAA8F
        model.state.acc = 0xFFFF_00C3
        model.program[0] = 0x50A1

        trace = model.step()

        self.assertEqual(model.data[143], 0x00C3)
        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(model.state.ar[0], 0xAA90)
        self.assertEqual(model.state.status.arp, 1)

    def test_indirect_decrement_wraps_low_nine_bits_and_preserves_arp(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 1
        model.state.ar[1] = 0
        model.state.acc = 0x0000_BEEF
        model.program[0] = 0x5098

        model.step()

        self.assertEqual(model.data[0], 0xBEEF)
        self.assertEqual(model.state.ar[1], 0x01FF)
        self.assertEqual(model.state.status.arp, 1)

    def test_unresolved_address_traps_before_any_write_or_state_change(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.state.acc = 0xDEAD_BEEF
        model.data[:] = [0x1234] * len(model.data)
        model.program[0] = 0x5010
        before_state = model.architectural_state()
        before_data = list(model.data)

        with self.assertRaises(UnsupportedDataAddress):
            model.step()

        self.assertEqual(model.architectural_state(), before_state)
        self.assertEqual(model.data, before_data)


if __name__ == "__main__":
    unittest.main()
