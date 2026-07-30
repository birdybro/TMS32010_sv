from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
    UnsupportedOpcode,
)


class LacModelTests(unittest.TestCase):
    def test_direct_sign_extension_and_shift_boundaries(self) -> None:
        cases = [
            (0x0000, 0, 0x0000_0000),
            (0x0001, 15, 0x0000_8000),
            (0x7FFF, 15, 0x3FFF_8000),
            (0x8000, 15, 0xC000_0000),
            (0xFFFF, 0, 0xFFFF_FFFF),
        ]
        for data_word, shift, expected in cases:
            with self.subTest(data_word=data_word, shift=shift):
                model = Tms32010Model()
                model.data[3] = data_word
                model.load_words([0x2003 | (shift << 8)])
                trace = model.step()
                self.assertEqual(model.state.acc, expected)
                self.assertEqual(trace.mnemonic, "LAC")
                self.assertEqual(trace.cycles, 1)
                self.assertEqual(trace.operands["effective_address"], 3)
                self.assertEqual(
                    [(item.space, item.operation) for item in trace.transactions],
                    [("program", "instruction_fetch"), ("data", "read")],
                )

    def test_direct_page_one_last_physical_word(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.data[143] = 0x1234
        model.load_words([0x200F])
        trace = model.step()
        self.assertEqual(model.state.acc, 0x0000_1234)
        self.assertEqual(trace.transactions[1].address, 143)

    def test_unresolved_data_address_traps_without_state_change(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.load_words([0x2010])
        before = model.architectural_state()
        with self.assertRaises(UnsupportedDataAddress) as caught:
            model.step()
        self.assertEqual(caught.exception.address, 144)
        self.assertEqual(model.architectural_state(), before)

        model = Tms32010Model()
        model.state.ar[0] = 0x0090
        model.load_words([0x2088])
        before = model.architectural_state()
        with self.assertRaises(UnsupportedDataAddress) as caught:
            model.step()
        self.assertEqual(caught.exception.address, 144)
        self.assertEqual(model.architectural_state(), before)

    def test_indirect_uses_preincrement_address_then_updates_low_nine_bits(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 1
        model.state.ar[1] = 0xAB8F
        model.data[0x8F] = 0xFF80
        model.load_words([0x24A0])
        trace = model.step()
        self.assertEqual(trace.operands["effective_address"], 0x8F)
        self.assertEqual(model.state.acc, 0xFFFF_F800)
        self.assertEqual(model.state.ar[1], 0xAB90)
        self.assertEqual(model.state.status.arp, 0)

    def test_counter_helper_wraps_low_nine_bits_only(self) -> None:
        self.assertEqual(Tms32010Model._modify_counter(0xABFF, 1), 0xAA00)
        self.assertEqual(Tms32010Model._modify_counter(0xAA00, -1), 0xABFF)

    def test_indirect_decrement_wrap_and_preserve_alias(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 0
        model.state.ar[0] = 0x5400
        model.data[0] = 7
        model.load_words([0x2098, 0x2089])
        model.step()
        self.assertEqual(model.state.ar[0], 0x55FF)
        self.assertEqual(model.state.status.arp, 0)
        model.state.ar[0] = 1
        model.step()
        self.assertEqual(model.state.ar[0], 1)
        self.assertEqual(model.state.status.arp, 0)

    def test_reserved_indirect_controls_trap(self) -> None:
        for opcode in (0x20C8, 0x208A, 0x20B8):
            with self.subTest(opcode=opcode):
                model = Tms32010Model()
                model.load_words([opcode])
                with self.assertRaises(UnsupportedOpcode):
                    model.step()


if __name__ == "__main__":
    unittest.main()
