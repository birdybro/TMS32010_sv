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

    def test_pair_preserves_all_other_architectural_state_without_request(
        self,
    ) -> None:
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
        self.assertFalse(model.state.interrupt_pending)
        self.assertEqual(model.data[17], 0xCAFE)
        self.assertEqual(model.cycle_count, 3)

    def test_active_low_pulse_executes_one_instruction_then_enters_vector(
        self,
    ) -> None:
        model = Tms32010Model()
        model.state.pc = 0x100
        model.state.status.intm = False
        model.state.stack[:] = [0x111, 0x222, 0x333, 0x444]
        model.program[0x100] = 0x7F80  # NOP, request sample
        model.program[0x101] = 0x7E2A  # protected LACK 0x2a
        model.program[0x102] = 0x7F89  # dummy-fetched, not executed
        model.program[0x002] = 0x7E5A  # vector instruction
        model.interrupt_input_high = False

        request = model.step()
        model.interrupt_input_high = True
        protected = model.step()
        entry = model.step()

        self.assertEqual(
            [request.mnemonic, protected.mnemonic, entry.mnemonic],
            ["NOP", "LACK", "INTERRUPT"],
        )
        self.assertEqual(model.state.acc, 0x2A)
        self.assertEqual(entry.pc, 0x102)
        self.assertEqual(entry.opcode, 0x7F89)
        self.assertEqual(
            entry.operands,
            {"return_address": 0x102, "vector": 0x002},
        )
        self.assertEqual(
            [
                (transaction.operation, transaction.address)
                for transaction in entry.transactions
            ],
            [("interrupt_dummy_fetch", 0x102)],
        )
        self.assertEqual(model.state.pc, 0x002)
        self.assertEqual(model.state.stack, [0x102, 0x111, 0x222, 0x333])
        self.assertTrue(model.state.status.intm)
        self.assertFalse(model.state.interrupt_pending)
        self.assertEqual(model.cycle_count, 3)

        vector = model.step()
        self.assertEqual(vector.mnemonic, "LACK")
        self.assertEqual(vector.pc, 0x002)
        self.assertEqual(model.state.acc, 0x5A)
        self.assertEqual(model.state.pc, 0x003)
        self.assertEqual(model.cycle_count, 4)

    def test_masked_pulse_persists_through_eint_and_following_instruction(
        self,
    ) -> None:
        model = Tms32010Model()
        model.state.pc = 0x100
        model.state.status.intm = True
        model.load_words(
            [0x7F80, 0x7F82, 0x7E33, 0x7F89],
            origin=0x100,
        )
        model.interrupt_input_high = False

        masked = model.step()
        model.interrupt_input_high = True
        enable = model.step()
        protected = model.step()
        entry = model.step()

        self.assertEqual(
            [
                masked.mnemonic,
                enable.mnemonic,
                protected.mnemonic,
                entry.mnemonic,
            ],
            ["NOP", "EINT", "LACK", "INTERRUPT"],
        )
        self.assertTrue(masked.state_after["interrupt_pending"])
        self.assertFalse(enable.state_after["status"]["intm"])
        self.assertTrue(enable.state_after["interrupt_delay_one"])
        self.assertEqual(model.state.acc, 0x33)
        self.assertEqual(model.state.stack[0], 0x103)
        self.assertEqual(model.state.pc, 0x002)

    def test_dint_in_protected_slot_cancels_entry_but_keeps_request(
        self,
    ) -> None:
        model = Tms32010Model()
        model.state.pc = 0x100
        model.state.status.intm = False
        model.load_words([0x7F80, 0x7F81, 0x7F80], origin=0x100)
        model.interrupt_input_high = False

        model.step()
        model.interrupt_input_high = True
        dint = model.step()
        following = model.step()

        self.assertEqual(dint.mnemonic, "DINT")
        self.assertEqual(following.mnemonic, "NOP")
        self.assertTrue(model.state.status.intm)
        self.assertTrue(model.state.interrupt_pending)
        self.assertFalse(model._interrupt_delay_one)
        self.assertFalse(model._interrupt_entry_pending)
        self.assertEqual(model.state.pc, 0x103)

    def test_multiply_in_protected_slot_extends_deferral_one_instruction(
        self,
    ) -> None:
        model = Tms32010Model()
        model.state.pc = 0x100
        model.state.status.intm = False
        model.state.t = 3
        model.load_words(
            [0x7F80, 0x8002, 0x7E44, 0x7F89],
            origin=0x100,
        )
        model.interrupt_input_high = False

        request = model.step()
        model.interrupt_input_high = True
        multiply = model.step()
        protected = model.step()
        entry = model.step()

        self.assertEqual(
            [
                request.mnemonic,
                multiply.mnemonic,
                protected.mnemonic,
                entry.mnemonic,
            ],
            ["NOP", "MPYK", "LACK", "INTERRUPT"],
        )
        self.assertEqual(model.state.p, 6)
        self.assertEqual(model.state.acc, 0x44)
        self.assertEqual(model.state.stack[0], 0x103)

    def test_eint_while_already_enabled_does_not_add_a_second_deferral(
        self,
    ) -> None:
        model = Tms32010Model()
        model.state.pc = 0x100
        model.state.status.intm = False
        model.load_words([0x7F80, 0x7F82, 0x7F89], origin=0x100)
        model.interrupt_input_high = False

        model.step()
        model.interrupt_input_high = True
        redundant_enable = model.step()
        entry = model.step()

        self.assertEqual(redundant_enable.mnemonic, "EINT")
        self.assertTrue(
            redundant_enable.state_after["interrupt_entry_pending"]
        )
        self.assertEqual(entry.mnemonic, "INTERRUPT")
        self.assertEqual(model.state.stack[0], 0x102)

    def test_low_level_relatches_after_acknowledge_while_masked(self) -> None:
        model = Tms32010Model()
        model.state.pc = 0x100
        model.state.status.intm = False
        model.load_words([0x7F80, 0x7F80, 0x7F80], origin=0x100)
        model.program[0x002] = 0x7F80
        model.interrupt_input_high = False

        model.step()
        model.step()
        entry = model.step()
        vector = model.step()

        self.assertEqual(entry.mnemonic, "INTERRUPT")
        self.assertEqual(vector.mnemonic, "NOP")
        self.assertTrue(model.state.status.intm)
        self.assertTrue(model.state.interrupt_pending)
        self.assertFalse(model._interrupt_delay_one)

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
