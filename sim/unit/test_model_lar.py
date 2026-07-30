from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
    UnsupportedOpcode,
)


class LarModelTests(unittest.TestCase):
    def test_direct_page_one_loads_ar1_without_other_state_effects(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.state.status.ov = True
        model.state.status.ovm = True
        model.state.acc = 0x1234_5678
        model.state.ar = [0xAAAA, 0xBBBB]
        model.data[143] = 0xFEDC
        model.load_words([0x390F])  # LAR AR1,15 on data page one

        trace = model.step()

        self.assertEqual(model.state.ar, [0xAAAA, 0xFEDC])
        self.assertEqual(model.state.acc, 0x1234_5678)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)
        self.assertEqual(trace.cycles, 1)
        self.assertEqual(trace.transactions[1].address, 143)
        self.assertEqual(trace.transactions[1].data, 0xFEDC)

    def test_current_address_ar_load_suppresses_postdecrement(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 0
        model.state.ar = [7, 0x9999]
        model.data[7] = 0x1234
        model.load_words([0x3891])  # LAR AR0,*-,AR1

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 7)
        self.assertEqual(model.state.ar, [0x1234, 0x9999])
        self.assertEqual(model.state.status.arp, 1)

    def test_other_target_ar_preserves_normal_postincrement(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 0
        model.state.ar = [0x008F, 0x7777]
        model.data[143] = 0xCAFE
        model.load_words([0x39A8])  # LAR AR1,*+

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(model.state.ar, [0x0090, 0xCAFE])
        self.assertEqual(model.state.status.arp, 0)

    def test_unresolved_address_traps_without_loading_or_modifying(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.state.ar = [0x1111, 0x2222]
        model.load_words([0x397F])  # LAR AR1,127
        # Direct field 127 on page one resolves to 255, outside physical RAM.
        before = model.architectural_state()

        with self.assertRaises(UnsupportedDataAddress):
            model.step()

        self.assertEqual(model.architectural_state(), before)

    def test_reserved_indirect_control_traps(self) -> None:
        model = Tms32010Model()
        model.load_words([0x38B8])

        with self.assertRaises(UnsupportedOpcode):
            model.step()


if __name__ == "__main__":
    unittest.main()
