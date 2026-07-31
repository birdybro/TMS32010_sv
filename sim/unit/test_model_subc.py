from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
)


class SubcModelTests(unittest.TestCase):
    def test_negative_intermediate_shifts_old_accumulator(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x0000_0041
        model.data[2] = 0x0007
        model.program[0] = 0x6402

        trace = model.step()

        self.assertEqual(model.state.acc, 0x0000_0082)
        self.assertFalse(model.state.status.ov)
        self.assertEqual(trace.mnemonic, "SUBC")
        self.assertEqual(trace.transactions[1].operation, "read")
        self.assertEqual(trace.transactions[1].address, 2)
        self.assertEqual(trace.transactions[1].data, 7)
        self.assertEqual(trace.cycles, 1)

    def test_nonnegative_intermediate_inserts_quotient_one(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x0004_0000
        model.data[2] = 0x0007
        model.program[0] = 0x6402

        model.step()

        self.assertEqual(model.state.acc, 0x0001_0001)
        self.assertFalse(model.state.status.ov)

    def test_sixteen_legally_spaced_steps_match_ti_divide_example(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x0000_0041
        model.data[2] = 0x0007
        for iteration in range(16):
            model.program[iteration * 2] = 0x6402
            model.program[iteration * 2 + 1] = 0x7F80

        for _ in range(32):
            model.step()

        self.assertEqual(model.state.acc, 0x0002_0009)
        self.assertEqual(model.state.pc, 32)
        self.assertEqual(model.cycle_count, 32)

    def test_operand_is_unsigned_and_shifted_fifteen_bits(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x7FFF_8000
        model.data[1] = 0xFFFF
        model.program[0] = 0x6401

        model.step()

        self.assertEqual(model.state.acc, 1)
        self.assertFalse(model.state.status.ov)

    def test_intermediate_overflow_sets_sticky_ov_and_ignores_ovm(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x8000_0000
        model.state.status.ovm = True
        model.data[1] = 0xFFFF
        model.program[0] = 0x6401

        model.step()

        self.assertEqual(model.state.acc, 0x0001_0001)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)

        model.state.acc = 0
        model.data[1] = 0
        model.program[1] = 0x7F80
        model.program[2] = 0x6401
        model.step()
        model.step()
        self.assertEqual(model.state.acc, 1)
        self.assertTrue(model.state.status.ov)

    def test_final_shift_overflow_does_not_set_ov_provisionally(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x4000_0000
        model.state.status.ovm = True
        model.data[1] = 0
        model.program[0] = 0x6401

        model.step()

        self.assertEqual(model.state.acc, 0x8000_0001)
        self.assertFalse(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)

    def test_direct_page_one_reaches_last_physical_word(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x0001_0000
        model.state.status.dp = 1
        model.data[143] = 2
        model.program[0] = 0x640F

        model.step()

        self.assertEqual(model.state.acc, 1)

    def test_indirect_read_precedes_counter_and_arp_update(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x0004_0000
        model.state.status.arp = 0
        model.state.ar[0] = 0xAA8F
        model.data[143] = 2
        model.program[0] = 0x64A1

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(model.state.acc, 0x0006_0001)
        self.assertEqual(model.state.ar[0], 0xAA90)
        self.assertEqual(model.state.status.arp, 1)

    def test_unresolved_address_traps_without_state_change(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x1234_5678
        model.state.status.dp = 1
        model.program[0] = 0x6410
        before = model.architectural_state()

        with self.assertRaises(UnsupportedDataAddress):
            model.step()

        self.assertEqual(model.architectural_state(), before)


if __name__ == "__main__":
    unittest.main()
