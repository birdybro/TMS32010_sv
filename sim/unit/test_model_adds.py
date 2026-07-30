from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
)


class AddsModelTests(unittest.TestCase):
    def test_unsigned_operand_is_not_sign_extended(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x0000_0003
        model.data[11] = 0xF006
        model.program[0] = 0x610B

        trace = model.step()

        self.assertEqual(model.state.acc, 0x0000_F009)
        self.assertFalse(model.state.status.ov)
        self.assertEqual(trace.transactions[1].space, "data")
        self.assertEqual(trace.transactions[1].operation, "read")
        self.assertEqual(trace.transactions[1].address, 11)
        self.assertEqual(trace.transactions[1].data, 0xF006)
        self.assertEqual(trace.cycles, 1)

    def test_overflow_wraps_and_sets_sticky_ov_when_ovm_is_clear(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x7FFF_FFFE
        model.data[2] = 0x0002
        model.program[0] = 0x6102

        model.step()

        self.assertEqual(model.state.acc, 0x8000_0000)
        self.assertTrue(model.state.status.ov)
        self.assertFalse(model.state.status.ovm)

        model.data[2] = 0
        model.program[1] = 0x6102
        model.step()
        self.assertTrue(model.state.status.ov)

    def test_overflow_saturates_positive_when_ovm_is_set(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x7FFF_FFFE
        model.state.status.ovm = True
        model.data[2] = 0x0002
        model.program[0] = 0x6102

        model.step()

        self.assertEqual(model.state.acc, 0x7FFF_FFFF)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)

    def test_negative_accumulator_plus_unsigned_word_does_not_false_overflow(
        self,
    ) -> None:
        model = Tms32010Model()
        model.state.acc = 0x8000_0000
        model.data[4] = 0xFFFF
        model.program[0] = 0x6104

        model.step()

        self.assertEqual(model.state.acc, 0x8000_FFFF)
        self.assertFalse(model.state.status.ov)

    def test_direct_page_one_reaches_last_physical_word(self) -> None:
        model = Tms32010Model()
        model.state.acc = 5
        model.state.status.dp = 1
        model.data[143] = 1
        model.program[0] = 0x610F

        model.step()

        self.assertEqual(model.state.acc, 6)

    def test_indirect_read_precedes_counter_and_arp_update(self) -> None:
        model = Tms32010Model()
        model.state.acc = 7
        model.state.status.arp = 0
        model.state.ar[0] = 0xAA8F
        model.data[143] = 2
        model.program[0] = 0x61A1

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(model.state.acc, 9)
        self.assertEqual(model.state.ar[0], 0xAA90)
        self.assertEqual(model.state.status.arp, 1)

    def test_unresolved_address_traps_without_state_change(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x1234_5678
        model.state.status.dp = 1
        model.program[0] = 0x6110
        before = model.architectural_state()

        with self.assertRaises(UnsupportedDataAddress):
            model.step()

        self.assertEqual(model.architectural_state(), before)


if __name__ == "__main__":
    unittest.main()
