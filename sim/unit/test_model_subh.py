from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
)


class SubhModelTests(unittest.TestCase):
    def test_primary_example_subtracts_only_from_high_half(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x0017_4567
        model.state.p = 0x8123_4567
        model.state.t = 0x8001
        model.data[33] = 5
        model.program[0] = 0x6221

        trace = model.step()

        self.assertEqual(model.state.acc, 0x0012_4567)
        self.assertEqual(model.state.p, 0x8123_4567)
        self.assertEqual(model.state.t, 0x8001)
        self.assertFalse(model.state.status.ov)
        self.assertEqual(trace.mnemonic, "SUBH")
        self.assertEqual(trace.cycles, 1)
        self.assertEqual(trace.transactions[1].address, 33)
        self.assertEqual(trace.transactions[1].data, 5)

    def test_high_bit_data_word_is_aligned_as_its_complete_bit_pattern(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x0001_1234
        model.data[1] = 0xFFFF
        model.program[0] = 0x6201

        model.step()

        self.assertEqual(model.state.acc, 0x0002_1234)
        self.assertFalse(model.state.status.ov)

    def test_negative_overflow_wraps_and_preserves_low_half(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x8000_1234
        model.data[1] = 1
        model.program[0] = 0x6201

        model.step()

        self.assertEqual(model.state.acc, 0x7FFF_1234)
        self.assertTrue(model.state.status.ov)
        self.assertFalse(model.state.status.ovm)

        model.data[1] = 0
        model.program[1] = 0x6201
        model.step()
        self.assertTrue(model.state.status.ov)

    def test_negative_overflow_saturation_replaces_full_accumulator(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x8000_1234
        model.state.status.ovm = True
        model.data[1] = 1
        model.program[0] = 0x6201

        model.step()

        self.assertEqual(model.state.acc, 0x8000_0000)
        self.assertTrue(model.state.status.ov)

    def test_positive_overflow_wraps_or_saturates_under_ovm(self) -> None:
        for ovm, expected in (
            (False, 0x8000_1234),
            (True, 0x7FFF_FFFF),
        ):
            with self.subTest(ovm=ovm):
                model = Tms32010Model()
                model.state.acc = 0x7FFF_1234
                model.state.status.ovm = ovm
                model.data[1] = 0xFFFF
                model.program[0] = 0x6201

                model.step()

                self.assertEqual(model.state.acc, expected)
                self.assertTrue(model.state.status.ov)

    def test_direct_page_and_indirect_post_update_use_common_addressing(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x0005_ABCD
        model.state.status.dp = 1
        model.data[143] = 2
        model.program[0] = 0x620F

        direct_trace = model.step()

        self.assertEqual(model.state.acc, 0x0003_ABCD)
        self.assertEqual(direct_trace.operands["effective_address"], 143)

        model.state.status.arp = 0
        model.state.ar[0] = 0xAA8F
        model.program[1] = 0x62A1

        indirect_trace = model.step()

        self.assertEqual(model.state.acc, 0x0001_ABCD)
        self.assertEqual(indirect_trace.operands["effective_address"], 143)
        self.assertEqual(model.state.ar[0], 0xAA90)
        self.assertEqual(model.state.status.arp, 1)

    def test_unresolved_address_traps_without_state_change(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x1234_5678
        model.state.status.dp = 1
        model.program[0] = 0x6210
        before = model.architectural_state()

        with self.assertRaises(UnsupportedDataAddress):
            model.step()

        self.assertEqual(model.architectural_state(), before)


if __name__ == "__main__":
    unittest.main()
