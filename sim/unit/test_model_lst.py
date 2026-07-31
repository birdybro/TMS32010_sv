from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
    UnsupportedOpcode,
)


class LstModelTests(unittest.TestCase):
    def test_all_documented_status_fields_load_from_exact_source_bits(self) -> None:
        for fields in range(16):
            for intm in (False, True):
                with self.subTest(fields=fields, intm=intm):
                    model = Tms32010Model()
                    source = 0x1EFE
                    source |= ((fields >> 3) & 1) << 15
                    source |= ((fields >> 2) & 1) << 14
                    source |= ((fields >> 1) & 1) << 8
                    source |= fields & 1
                    if not intm:
                        source |= 0x2000
                    model.state.status.ov = not bool(fields & 8)
                    model.state.status.ovm = not bool(fields & 4)
                    model.state.status.intm = intm
                    model.state.status.arp = 1 - ((fields >> 1) & 1)
                    model.state.status.dp = 1 - (fields & 1)
                    source_address = model.state.status.dp << 7
                    model.data[source_address] = source
                    model.program[0] = 0x7B00

                    trace = model.step()

                    self.assertEqual(trace.mnemonic, "LST")
                    self.assertEqual(model.state.status.ov, bool(fields & 8))
                    self.assertEqual(model.state.status.ovm, bool(fields & 4))
                    self.assertEqual(
                        model.state.status.arp,
                        (fields >> 1) & 1,
                    )
                    self.assertEqual(model.state.status.dp, fields & 1)
                    self.assertEqual(model.state.status.intm, intm)
                    self.assertEqual(trace.cycles, 1)
                    self.assertEqual(
                        [(item.space, item.operation, item.address, item.data)
                         for item in trace.transactions],
                        [
                            ("program", "instruction_fetch", 0, 0x7B00),
                            ("data", "read", source_address, source),
                        ],
                    )

    def test_direct_address_uses_old_dp_before_loading_new_dp(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.data[143] = 0xC100
        model.program[0] = 0x7B0F

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(trace.transactions[1].address, 143)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)
        self.assertTrue(model.state.status.arp)
        self.assertFalse(model.state.status.dp)

    def test_indirect_update_uses_old_arp_but_status_word_arp_wins(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 0
        model.state.ar[:] = [0xAA8F, 0xBB10]
        model.data[143] = 0x0001
        model.program[0] = 0x7BA1  # LST *+,1

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(model.state.ar, [0xAA90, 0xBB10])
        self.assertEqual(
            model.state.status.arp,
            0,
            "provisional OQ-015 policy ignores encoded next ARP",
        )
        self.assertEqual(model.state.status.dp, 1)

    def test_decrement_targets_old_selected_ar_and_loaded_arp_can_differ(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 1
        model.state.ar[:] = [0xAA20, 0xFE00]
        model.data[0] = 0x0100
        model.program[0] = 0x7B90  # LST *-,0

        trace = model.step()

        self.assertEqual(trace.transactions[1].address, 0)
        self.assertEqual(model.state.ar, [0xAA20, 0xFFFF])
        self.assertEqual(
            model.state.status.arp,
            1,
            "source bit 8 wins over the conflicting encoded next ARP",
        )
        self.assertFalse(model.state.status.dp)

    def test_preserves_nonstatus_state_and_pending_interrupt(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x8123_4567
        model.state.p = 0xDEAD_BEEF
        model.state.t = 0xA55A
        model.state.ar[:] = [0x1234, 0xFEDC]
        model.state.stack[:] = [0x111, 0x222, 0x333, 0x444]
        model.state.status.intm = True
        model.state.interrupt_pending = True
        model.data[7] = 0xC101
        model.program[0] = 0x7B07

        model.step()

        self.assertEqual(model.state.acc, 0x8123_4567)
        self.assertEqual(model.state.p, 0xDEAD_BEEF)
        self.assertEqual(model.state.t, 0xA55A)
        self.assertEqual(model.state.ar, [0x1234, 0xFEDC])
        self.assertEqual(model.state.stack, [0x111, 0x222, 0x333, 0x444])
        self.assertTrue(model.state.status.intm)
        self.assertTrue(model.state.interrupt_pending)

    def test_unresolved_address_and_reserved_controls_trap_before_effects(
        self,
    ) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.program[0] = 0x7B10
        before = model.architectural_state()

        with self.assertRaises(UnsupportedDataAddress):
            model.step()

        self.assertEqual(model.architectural_state(), before)

        for opcode in (0x7BC8, 0x7B8A, 0x7BB8):
            with self.subTest(opcode=opcode):
                model = Tms32010Model()
                model.program[0] = opcode
                with self.assertRaises(UnsupportedOpcode):
                    model.step()


if __name__ == "__main__":
    unittest.main()
