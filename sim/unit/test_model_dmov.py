from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
    UnsupportedOpcode,
)


class DmovModelTests(unittest.TestCase):
    def test_primary_example_copies_source_to_next_address_in_one_cycle(
        self,
    ) -> None:
        model = Tms32010Model()
        model.data[8] = 0x0043
        model.data[9] = 0x0002
        model.program[0] = 0x6908

        trace = model.step()

        self.assertEqual(trace.mnemonic, "DMOV")
        self.assertEqual(trace.operands["effective_address"], 8)
        self.assertEqual(trace.operands["move_address"], 9)
        self.assertEqual(trace.cycles, 1)
        self.assertEqual(model.data[8:10], [0x0043, 0x0043])
        self.assertEqual(model.state.pc, 1)
        self.assertEqual(model.cycle_count, 1)
        self.assertEqual(
            [
                (
                    transaction.space,
                    transaction.operation,
                    transaction.address,
                    transaction.data,
                )
                for transaction in trace.transactions
            ],
            [
                ("program", "instruction_fetch", 0, 0x6908),
                ("data", "read", 8, 0x0043),
                ("data", "write", 9, 0x0043),
            ],
        )

    def test_direct_move_preserves_all_unrelated_architectural_state(
        self,
    ) -> None:
        model = Tms32010Model()
        model.state.acc = 0x89AB_CDEF
        model.state.p = 0x7654_3210
        model.state.t = 0xA55A
        model.state.ar = [0x01FE, 0xA123]
        model.state.stack = [1, 2, 3, 4]
        model.state.status.ov = True
        model.state.status.ovm = True
        model.state.status.intm = True
        model.state.status.arp = 1
        model.state.status.dp = 1
        model.state.interrupt_pending = True
        model.data[128] = 0xBEEF
        model.program[0] = 0x6900

        model.step()

        self.assertEqual(model.data[128:130], [0xBEEF, 0xBEEF])
        self.assertEqual(model.state.acc, 0x89AB_CDEF)
        self.assertEqual(model.state.p, 0x7654_3210)
        self.assertEqual(model.state.t, 0xA55A)
        self.assertEqual(model.state.ar, [0x01FE, 0xA123])
        self.assertEqual(model.state.stack, [1, 2, 3, 4])
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)
        self.assertTrue(model.state.status.intm)
        self.assertEqual(model.state.status.arp, 1)
        self.assertEqual(model.state.status.dp, 1)
        self.assertTrue(model.state.interrupt_pending)

    def test_direct_page_zero_crosses_127_to_128(self) -> None:
        model = Tms32010Model()
        model.data[127] = 0xCAFE
        model.data[128] = 0x1234
        model.program[0] = 0x697F

        trace = model.step()

        self.assertEqual(model.data[127:129], [0xCAFE, 0xCAFE])
        self.assertEqual(trace.transactions[1].address, 127)
        self.assertEqual(trace.transactions[2].address, 128)

    def test_indirect_read_uses_old_ar_before_postincrement_and_arp_update(
        self,
    ) -> None:
        model = Tms32010Model()
        model.state.ar = [8, 40]
        model.state.status.arp = 0
        model.data[8] = 0x1357
        model.data[9] = 0x2468
        model.program[0] = 0x69A1

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 8)
        self.assertEqual(model.data[8:10], [0x1357, 0x1357])
        self.assertEqual(model.state.ar, [9, 40])
        self.assertEqual(model.state.status.arp, 1)

    def test_unresolved_destination_traps_before_any_architectural_effect(
        self,
    ) -> None:
        model = Tms32010Model()
        model.state.acc = 0x1234_5678
        model.state.ar = [4, 5]
        model.state.status.dp = 1
        model.data[143] = 0xFACE
        model.program[0] = 0x690F
        state_before = model.architectural_state()
        data_before = list(model.data)

        with self.assertRaisesRegex(UnsupportedDataAddress, "0x90"):
            model.step()

        self.assertEqual(model.architectural_state(), state_before)
        self.assertEqual(model.data, data_before)

    def test_reserved_indirect_controls_are_rejected(self) -> None:
        for opcode in (0x69C8, 0x698A, 0x69B8):
            with self.subTest(opcode=opcode):
                model = Tms32010Model()
                model.program[0] = opcode
                with self.assertRaises(UnsupportedOpcode):
                    model.step()


if __name__ == "__main__":
    unittest.main()
