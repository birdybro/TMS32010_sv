from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
    UnsupportedOpcode,
)


class SachModelTests(unittest.TestCase):
    def test_shift_zero_stores_accumulator_high_and_preserves_state(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0xA34B_78CD
        model.state.status.ov = True
        model.state.status.ovm = True
        model.program[0] = 0x5823

        trace = model.step()

        self.assertEqual(model.data[0x23], 0xA34B)
        self.assertEqual(model.state.acc, 0xA34B_78CD)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)
        transaction = trace.transactions[1]
        self.assertEqual(transaction.operation, "write")
        self.assertEqual(transaction.address, 0x23)
        self.assertEqual(transaction.data, 0xA34B)
        self.assertEqual(trace.cycles, 1)

    def test_shifts_one_and_four_move_low_bits_into_stored_word(self) -> None:
        vectors = (
            (0x0420_8001, 1, 0x0841),
            (0xA34B_78CD, 4, 0x34B7),
            (0xA8F3_5000, 4, 0x8F35),
        )
        for accumulator, shift, expected in vectors:
            with self.subTest(accumulator=accumulator, shift=shift):
                model = Tms32010Model()
                model.state.acc = accumulator
                model.program[0] = 0x5800 | (shift << 8)

                model.step()

                self.assertEqual(model.data[0], expected)
                self.assertEqual(model.state.acc, accumulator)

    def test_indirect_write_precedes_counter_and_arp_update(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 0
        model.state.ar[0] = 0xAA8F
        model.state.acc = 0x8421_C3D2
        model.program[0] = 0x59A1

        trace = model.step()

        self.assertEqual(model.data[143], 0x0843)
        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(model.state.ar[0], 0xAA90)
        self.assertEqual(model.state.status.arp, 1)

    def test_direct_page_one_reaches_last_physical_word(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.state.acc = 0x1234_5678
        model.program[0] = 0x5C0F

        model.step()

        self.assertEqual(model.data[143], 0x2345)

    def test_shift_four_indirect_decrement_wraps_and_preserves_arp(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 1
        model.state.ar[1] = 0
        model.state.acc = 0x1234_5678
        model.program[0] = 0x5C98

        model.step()

        self.assertEqual(model.data[0], 0x2345)
        self.assertEqual(model.state.ar[1], 0x01FF)
        self.assertEqual(model.state.status.arp, 1)

    def test_undocumented_shift_encodings_trap(self) -> None:
        for shift in (2, 3, 5, 6, 7):
            with self.subTest(shift=shift):
                model = Tms32010Model()
                model.program[0] = 0x5800 | (shift << 8)
                before = model.architectural_state()

                with self.assertRaises(UnsupportedOpcode):
                    model.step()

                self.assertEqual(model.architectural_state(), before)

    def test_unresolved_address_traps_before_any_write(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.state.acc = 0xDEAD_BEEF
        model.data[:] = [0x1234] * len(model.data)
        model.program[0] = 0x5810
        before_state = model.architectural_state()
        before_data = list(model.data)

        with self.assertRaises(UnsupportedDataAddress):
            model.step()

        self.assertEqual(model.architectural_state(), before_state)
        self.assertEqual(model.data, before_data)


if __name__ == "__main__":
    unittest.main()
