from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
)


class ZeroLoadModelTests(unittest.TestCase):
    def test_zalh_loads_high_word_and_clears_low_without_status_effect(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0xDEAD_BEEF
        model.state.status.ov = True
        model.state.status.ovm = True
        model.data[3] = 0xF7FF
        model.program[0] = 0x6503

        trace = model.step()

        self.assertEqual(model.state.acc, 0xF7FF_0000)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)
        self.assertEqual(trace.transactions[1].operation, "read")
        self.assertEqual(trace.transactions[1].data, 0xF7FF)
        self.assertEqual(trace.cycles, 1)

    def test_zals_zero_extends_even_when_data_sign_bit_is_set(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0xDEAD_BEEF
        model.state.status.ov = True
        model.state.status.ovm = True
        model.data[4] = 0xFA37
        model.program[0] = 0x6604

        model.step()

        self.assertEqual(model.state.acc, 0x0000_FA37)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)

    def test_direct_page_one_reaches_last_physical_word(self) -> None:
        for opcode, expected in ((0x650F, 0x8421_0000), (0x660F, 0x0000_8421)):
            with self.subTest(opcode=opcode):
                model = Tms32010Model()
                model.state.status.dp = 1
                model.data[143] = 0x8421
                model.program[0] = opcode

                model.step()

                self.assertEqual(model.state.acc, expected)

    def test_indirect_access_precedes_counter_and_arp_update(self) -> None:
        for opcode, expected in ((0x65A1, 0x1234_0000), (0x66A1, 0x0000_1234)):
            with self.subTest(opcode=opcode):
                model = Tms32010Model()
                model.state.status.arp = 0
                model.state.ar[0] = 0xAA8F
                model.data[143] = 0x1234
                model.program[0] = opcode

                trace = model.step()

                self.assertEqual(model.state.acc, expected)
                self.assertEqual(trace.operands["effective_address"], 143)
                self.assertEqual(model.state.ar[0], 0xAA90)
                self.assertEqual(model.state.status.arp, 1)

    def test_unresolved_address_traps_without_state_change(self) -> None:
        for opcode in (0x6510, 0x6610):
            with self.subTest(opcode=opcode):
                model = Tms32010Model()
                model.state.status.dp = 1
                model.program[0] = opcode
                before = model.architectural_state()

                with self.assertRaises(UnsupportedDataAddress):
                    model.step()

                self.assertEqual(model.architectural_state(), before)


if __name__ == "__main__":
    unittest.main()
