from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedOpcode,
)


class InterruptMaskModelTests(unittest.TestCase):
    def test_dint_sets_mask_in_one_program_only_cycle(self) -> None:
        model = Tms32010Model()
        model.state.status.intm = False
        model.state.interrupt_pending = True
        model.program[0] = 0x7F81

        trace = model.step()

        self.assertEqual(trace.mnemonic, "DINT")
        self.assertTrue(model.state.status.intm)
        self.assertTrue(model.state.interrupt_pending)
        self.assertEqual(model.state.pc, 1)
        self.assertEqual(model.cycle_count, 1)
        self.assertEqual(len(trace.transactions), 1)
        self.assertEqual(trace.transactions[0].space, "program")

    def test_eint_clears_mask_but_preserves_latched_request(self) -> None:
        model = Tms32010Model()
        model.state.status.intm = True
        model.state.interrupt_pending = True
        model.program[0] = 0x7F82

        trace = model.step()

        self.assertEqual(trace.mnemonic, "EINT")
        self.assertFalse(model.state.status.intm)
        self.assertTrue(model.state.interrupt_pending)
        self.assertEqual(model.state.pc, 1)
        self.assertEqual(model.cycle_count, 1)
        self.assertEqual(len(trace.transactions), 1)

    def test_pair_preserves_all_other_architectural_state(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x8123_4567
        model.state.p = 0xDEAD_BEEF
        model.state.t = 0xA55A
        model.state.ar[:] = [0x1234, 0xFEDC]
        model.state.stack[:] = [0x111, 0x222, 0x333, 0x444]
        model.state.status.ov = True
        model.state.status.ovm = True
        model.state.status.intm = True
        model.state.status.arp = 1
        model.state.status.dp = 1
        model.state.interrupt_pending = True
        model.data[17] = 0xCAFE
        model.load_words([0x7F82, 0x7F80, 0x7F81])

        traces = [model.step() for _ in range(3)]

        self.assertEqual(
            [trace.mnemonic for trace in traces],
            ["EINT", "NOP", "DINT"],
        )
        self.assertFalse(traces[0].state_after["status"]["intm"])
        self.assertFalse(traces[1].state_after["status"]["intm"])
        self.assertTrue(traces[2].state_after["status"]["intm"])
        self.assertEqual(model.state.acc, 0x8123_4567)
        self.assertEqual(model.state.p, 0xDEAD_BEEF)
        self.assertEqual(model.state.t, 0xA55A)
        self.assertEqual(model.state.ar, [0x1234, 0xFEDC])
        self.assertEqual(model.state.stack, [0x111, 0x222, 0x333, 0x444])
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)
        self.assertTrue(model.state.status.arp)
        self.assertTrue(model.state.status.dp)
        self.assertTrue(model.state.interrupt_pending)
        self.assertEqual(model.data[17], 0xCAFE)
        self.assertEqual(model.cycle_count, 3)

    def test_adjacent_unqualified_word_traps_without_effects(self) -> None:
        model = Tms32010Model()
        model.state.status.intm = True
        model.program[0] = 0x7F83
        before = model.architectural_state()

        with self.assertRaises(UnsupportedOpcode):
            model.step()

        self.assertEqual(model.architectural_state(), before)


if __name__ == "__main__":
    unittest.main()
