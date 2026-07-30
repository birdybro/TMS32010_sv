from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
    UnsupportedOpcode,
)


class SarModelTests(unittest.TestCase):
    def test_direct_page_one_stores_all_bits_without_state_effects(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.state.status.ov = True
        model.state.status.ovm = True
        model.state.acc = 0x1234_5678
        model.state.ar = [0xAAAA, 0xFEDC]
        model.load_words([0x310F])  # SAR AR1,15 on data page one

        trace = model.step()

        self.assertEqual(model.data[143], 0xFEDC)
        self.assertEqual(model.state.ar, [0xAAAA, 0xFEDC])
        self.assertEqual(model.state.acc, 0x1234_5678)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)
        self.assertEqual(trace.cycles, 1)
        self.assertEqual(trace.transactions[1].address, 143)
        self.assertEqual(trace.transactions[1].data, 0xFEDC)

    def test_current_address_ar_increment_is_stored_at_old_address(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 0
        model.state.ar = [10, 0x9999]
        model.load_words([0x30A1])  # SAR AR0,*+,AR1

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 10)
        self.assertEqual(trace.transactions[1].data, 11)
        self.assertEqual(model.data[10], 11)
        self.assertEqual(model.state.ar, [11, 0x9999])
        self.assertEqual(model.state.status.arp, 1)

    def test_current_address_ar_decrement_wrap_is_stored(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 0
        model.state.ar = [0xFE00, 0x7777]
        model.load_words([0x3098])  # SAR AR0,*-

        model.step()

        self.assertEqual(model.data[0], 0xFFFF)
        self.assertEqual(model.state.ar, [0xFFFF, 0x7777])
        self.assertEqual(model.state.status.arp, 0)

    def test_other_target_stores_unchanged_while_address_ar_updates(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 0
        model.state.ar = [10, 0xCAFE]
        model.load_words([0x31A8])  # SAR AR1,*+

        trace = model.step()

        self.assertEqual(trace.transactions[1].data, 0xCAFE)
        self.assertEqual(model.data[10], 0xCAFE)
        self.assertEqual(model.state.ar, [11, 0xCAFE])

    def test_unresolved_address_traps_without_write_or_modification(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.state.ar = [0x1111, 0x2222]
        model.load_words([0x317F])  # SAR AR1,127
        before = model.architectural_state()

        with self.assertRaises(UnsupportedDataAddress):
            model.step()

        self.assertEqual(model.architectural_state(), before)

    def test_reserved_indirect_control_traps(self) -> None:
        model = Tms32010Model()
        model.load_words([0x30B8])

        with self.assertRaises(UnsupportedOpcode):
            model.step()


if __name__ == "__main__":
    unittest.main()
