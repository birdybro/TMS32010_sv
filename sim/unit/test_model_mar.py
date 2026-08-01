from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedOpcode,
)


class MarModelTests(unittest.TestCase):
    def test_direct_form_is_one_cycle_nop_without_data_transaction(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x1234_5678
        model.state.ar = [0xAAAA, 0x5555]
        model.state.status.dp = 1
        model.state.status.arp = 1
        model.state.status.ov = True
        model.state.status.ovm = True
        model.load_words([0x687F])  # MAR 127; DP is architecturally ignored

        trace = model.step()

        self.assertEqual(trace.mnemonic, "MAR")
        self.assertEqual(len(trace.transactions), 1)
        self.assertEqual(trace.cycles, 1)
        self.assertEqual(model.state.acc, 0x1234_5678)
        self.assertEqual(model.state.ar, [0xAAAA, 0x5555])
        self.assertEqual(model.state.status.arp, 1)
        self.assertEqual(model.state.status.dp, 1)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)

    def test_indirect_decrement_wraps_low_nine_bits_only(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 0
        model.state.ar = [0xFE00, 0x2222]
        model.load_words([0x6898])  # MAR *-

        trace = model.step()

        self.assertEqual(trace.mnemonic, "MAR")
        self.assertEqual(len(trace.transactions), 1)
        self.assertEqual(model.state.ar, [0xFFFF, 0x2222])
        self.assertEqual(model.state.status.arp, 0)

    def test_indirect_increment_wraps_then_replaces_arp(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 1
        model.state.ar = [0x1111, 0xA1FF]
        model.load_words([0x68A0])  # MAR *+,AR0

        model.step()

        self.assertEqual(model.state.ar, [0x1111, 0xA000])
        self.assertEqual(model.state.status.arp, 0)

    def test_indirect_preserve_form_has_no_memory_or_register_effect(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 1
        model.state.ar = [0x1111, 0xA155]
        model.load_words([0x6888])  # MAR *

        trace = model.step()

        self.assertEqual(len(trace.transactions), 1)
        self.assertEqual(model.state.ar, [0x1111, 0xA155])
        self.assertEqual(model.state.status.arp, 1)

    def test_larp_alias_words_remain_canonical_larp_decode(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 1
        model.load_words([0x6880])  # MAR *,0 is LARP 0

        trace = model.step()

        self.assertEqual(trace.mnemonic, "LARP")
        self.assertEqual(model.state.status.arp, 0)

    def test_simultaneous_update_traps_without_state_change(self) -> None:
        model = Tms32010Model()
        model.state.ar = [0x1234, 0x5678]
        model.load_words([0x68B8])
        before = model.architectural_state()

        with self.assertRaises(UnsupportedOpcode):
            model.step()

        self.assertEqual(model.architectural_state(), before)


if __name__ == "__main__":
    unittest.main()
