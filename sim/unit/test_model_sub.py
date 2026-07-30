from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
)


class SubModelTests(unittest.TestCase):
    def test_primary_example_and_negative_source_shift(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x24
        model.data[59] = 0x11
        model.program[0] = 0x103B

        trace = model.step()

        self.assertEqual(model.state.acc, 0x13)
        self.assertFalse(model.state.status.ov)
        self.assertEqual(trace.transactions[1].operation, "read")
        self.assertEqual(trace.transactions[1].address, 59)
        self.assertEqual(trace.transactions[1].data, 0x11)
        self.assertEqual(trace.cycles, 1)

        model.data[1] = 0xFFFF
        model.program[1] = 0x1301
        model.step()
        self.assertEqual(model.state.acc, 0x1B)

        model.state.acc = 0
        model.data[2] = 1
        model.program[2] = 0x1F02
        model.step()
        self.assertEqual(model.state.acc, 0xFFFF_8000)

    def test_positive_overflow_wraps_and_sets_sticky_ov(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x7FFF_FFFF
        model.data[1] = 0xFFFF
        model.program[0] = 0x1001

        model.step()

        self.assertEqual(model.state.acc, 0x8000_0000)
        self.assertTrue(model.state.status.ov)
        self.assertFalse(model.state.status.ovm)

        model.data[1] = 0
        model.program[1] = 0x1001
        model.step()
        self.assertTrue(model.state.status.ov)

    def test_negative_overflow_wraps_when_ovm_is_clear(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x8000_0000
        model.data[1] = 1
        model.program[0] = 0x1001

        model.step()

        self.assertEqual(model.state.acc, 0x7FFF_FFFF)
        self.assertTrue(model.state.status.ov)
        self.assertFalse(model.state.status.ovm)

    def test_positive_overflow_saturates_when_ovm_is_set(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x7FFF_FFFF
        model.state.status.ovm = True
        model.data[1] = 0xFFFF
        model.program[0] = 0x1001

        model.step()

        self.assertEqual(model.state.acc, 0x7FFF_FFFF)
        self.assertTrue(model.state.status.ov)

    def test_negative_overflow_saturates_to_negative_endpoint(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x8000_0000
        model.state.status.ovm = True
        model.data[1] = 1
        model.program[0] = 0x1001

        model.step()

        self.assertEqual(model.state.acc, 0x8000_0000)
        self.assertTrue(model.state.status.ov)

    def test_direct_page_one_reaches_last_physical_word(self) -> None:
        model = Tms32010Model()
        model.state.acc = 12
        model.state.status.dp = 1
        model.data[143] = 2
        model.program[0] = 0x110F

        model.step()

        self.assertEqual(model.state.acc, 8)

    def test_indirect_read_precedes_counter_and_arp_update(self) -> None:
        model = Tms32010Model()
        model.state.acc = 23
        model.state.status.arp = 0
        model.state.ar[0] = 0xAA8F
        model.data[143] = 2
        model.program[0] = 0x13A1

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(model.state.acc, 7)
        self.assertEqual(model.state.ar[0], 0xAA90)
        self.assertEqual(model.state.status.arp, 1)

    def test_unresolved_address_traps_without_state_change(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x1234_5678
        model.state.status.dp = 1
        model.program[0] = 0x1010
        before = model.architectural_state()

        with self.assertRaises(UnsupportedDataAddress):
            model.step()

        self.assertEqual(model.architectural_state(), before)


if __name__ == "__main__":
    unittest.main()
