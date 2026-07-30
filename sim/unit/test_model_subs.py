from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
)


class SubsModelTests(unittest.TestCase):
    def test_primary_example_and_unsigned_source(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x0000_F105
        model.data[61] = 0xF003
        model.program[0] = 0x633D

        trace = model.step()

        self.assertEqual(model.state.acc, 0x0000_0102)
        self.assertFalse(model.state.status.ov)
        self.assertEqual(trace.transactions[1].operation, "read")
        self.assertEqual(trace.transactions[1].address, 61)
        self.assertEqual(trace.transactions[1].data, 0xF003)
        self.assertEqual(trace.cycles, 1)

        model.state.acc = 0
        model.data[1] = 0xFFFF
        model.program[1] = 0x6301
        model.step()
        self.assertEqual(model.state.acc, 0xFFFF_0001)

    def test_negative_overflow_wraps_and_sets_sticky_ov(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x8000_0000
        model.data[1] = 1
        model.program[0] = 0x6301

        model.step()

        self.assertEqual(model.state.acc, 0x7FFF_FFFF)
        self.assertTrue(model.state.status.ov)
        self.assertFalse(model.state.status.ovm)

        model.data[1] = 0
        model.program[1] = 0x6301
        model.step()
        self.assertTrue(model.state.status.ov)

    def test_negative_overflow_saturates_when_ovm_is_set(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x8000_0000
        model.state.status.ovm = True
        model.data[1] = 1
        model.program[0] = 0x6301

        model.step()

        self.assertEqual(model.state.acc, 0x8000_0000)
        self.assertTrue(model.state.status.ov)

    def test_nonnegative_accumulator_cannot_overflow(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x7FFF_FFFF
        model.state.status.ovm = True
        model.data[1] = 0xFFFF
        model.program[0] = 0x6301

        model.step()

        self.assertEqual(model.state.acc, 0x7FFF_0000)
        self.assertFalse(model.state.status.ov)

    def test_direct_page_one_reaches_last_physical_word(self) -> None:
        model = Tms32010Model()
        model.state.acc = 5
        model.state.status.dp = 1
        model.data[143] = 2
        model.program[0] = 0x630F

        model.step()

        self.assertEqual(model.state.acc, 3)

    def test_indirect_read_precedes_counter_and_arp_update(self) -> None:
        model = Tms32010Model()
        model.state.acc = 7
        model.state.status.arp = 0
        model.state.ar[0] = 0xAA8F
        model.data[143] = 2
        model.program[0] = 0x63A1

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(model.state.acc, 5)
        self.assertEqual(model.state.ar[0], 0xAA90)
        self.assertEqual(model.state.status.arp, 1)

    def test_unresolved_address_traps_without_state_change(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x1234_5678
        model.state.status.dp = 1
        model.program[0] = 0x6310
        before = model.architectural_state()

        with self.assertRaises(UnsupportedDataAddress):
            model.step()

        self.assertEqual(model.architectural_state(), before)


if __name__ == "__main__":
    unittest.main()
