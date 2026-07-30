from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
)


class AddModelTests(unittest.TestCase):
    def test_sign_extension_and_shift_match_primary_examples(self) -> None:
        model = Tms32010Model()
        model.state.acc = 7
        model.data[1] = 2
        model.program[0] = 0x0301

        trace = model.step()

        self.assertEqual(model.state.acc, 0x0000_0017)
        self.assertFalse(model.state.status.ov)
        self.assertEqual(trace.transactions[1].operation, "read")
        self.assertEqual(trace.transactions[1].address, 1)
        self.assertEqual(trace.transactions[1].data, 2)
        self.assertEqual(trace.cycles, 1)

        model.state.acc = 0
        model.data[2] = 0x8B0E
        model.program[1] = 0x0402
        model.step()
        self.assertEqual(model.state.acc, 0xFFF8_B0E0)

    def test_positive_overflow_wraps_and_sets_sticky_ov(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x7FFF_FFFE
        model.data[2] = 1
        model.program[0] = 0x0102

        model.step()

        self.assertEqual(model.state.acc, 0x8000_0000)
        self.assertTrue(model.state.status.ov)
        self.assertFalse(model.state.status.ovm)

        model.data[2] = 0
        model.program[1] = 0x0002
        model.step()
        self.assertTrue(model.state.status.ov)

    def test_positive_overflow_saturates_when_ovm_is_set(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x7FFF_FFFE
        model.state.status.ovm = True
        model.data[2] = 1
        model.program[0] = 0x0102

        model.step()

        self.assertEqual(model.state.acc, 0x7FFF_FFFF)
        self.assertTrue(model.state.status.ov)

    def test_negative_overflow_saturates_to_negative_endpoint(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x8000_0001
        model.state.status.ovm = True
        model.data[3] = 0xFFFF
        model.program[0] = 0x0103

        model.step()

        self.assertEqual(model.state.acc, 0x8000_0000)
        self.assertTrue(model.state.status.ov)

    def test_negative_overflow_wraps_when_ovm_is_clear(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x8000_0001
        model.data[3] = 0xFFFF
        model.program[0] = 0x0103

        model.step()

        self.assertEqual(model.state.acc, 0x7FFF_FFFF)
        self.assertTrue(model.state.status.ov)
        self.assertFalse(model.state.status.ovm)

    def test_direct_page_one_reaches_last_physical_word(self) -> None:
        model = Tms32010Model()
        model.state.acc = 5
        model.state.status.dp = 1
        model.data[143] = 2
        model.program[0] = 0x010F

        model.step()

        self.assertEqual(model.state.acc, 9)

    def test_indirect_read_precedes_counter_and_arp_update(self) -> None:
        model = Tms32010Model()
        model.state.acc = 7
        model.state.status.arp = 0
        model.state.ar[0] = 0xAA8F
        model.data[143] = 2
        model.program[0] = 0x03A1

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(model.state.acc, 23)
        self.assertEqual(model.state.ar[0], 0xAA90)
        self.assertEqual(model.state.status.arp, 1)

    def test_unresolved_address_traps_without_state_change(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x1234_5678
        model.state.status.dp = 1
        model.program[0] = 0x0010
        before = model.architectural_state()

        with self.assertRaises(UnsupportedDataAddress):
            model.step()

        self.assertEqual(model.architectural_state(), before)


if __name__ == "__main__":
    unittest.main()
