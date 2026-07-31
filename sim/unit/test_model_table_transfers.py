from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
    UnsupportedOpcode,
)


class TableTransferModelTests(unittest.TestCase):
    @staticmethod
    def _transactions(trace: object) -> list[tuple[int, str, str, int, int]]:
        return [
            (
                transaction.cycle,
                transaction.space,
                transaction.operation,
                transaction.address,
                transaction.data,
            )
            for transaction in trace.transactions
        ]

    def test_direct_tblr_discards_prefetch_and_reads_acc_address(self) -> None:
        model = Tms32010Model()
        model.program[0] = 0x6705
        model.program[1] = 0x7F80
        model.program[0x345] = 0xBEEF
        model.state.acc = 0xA123_4345
        model.state.stack = [0x111, 0x222, 0x333, 0x444]

        trace = model.step()

        self.assertEqual(trace.mnemonic, "TBLR")
        self.assertEqual(
            trace.operands,
            {
                "indirect": 0,
                "addressing_field": 5,
                "effective_address": 5,
                "program_address": 0x345,
            },
        )
        self.assertEqual(trace.cycles, 3)
        self.assertEqual(model.data[5], 0xBEEF)
        self.assertEqual(model.state.pc, 1)
        self.assertEqual(model.state.acc, 0xA123_4345)
        self.assertEqual(model.state.stack, [0x111, 0x222, 0x333, 0x333])
        self.assertEqual(model.cycle_count, 3)
        self.assertEqual(
            self._transactions(trace),
            [
                (0, "program", "instruction_fetch", 0, 0x6705),
                (1, "program", "discarded_prefetch", 1, 0x7F80),
                (2, "program", "table_read", 0x345, 0xBEEF),
                (2, "data", "write", 5, 0xBEEF),
            ],
        )

    def test_indirect_tblr_uses_old_ar_then_updates_ar_and_arp(self) -> None:
        model = Tms32010Model()
        model.program[0] = 0x67A1
        model.program[0x234] = 0x1357
        model.state.acc = 0xFFFF_F234
        model.state.ar = [143, 22]
        model.state.status.arp = 0

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(model.data[143], 0x1357)
        self.assertEqual(model.state.ar, [144, 22])
        self.assertEqual(model.state.status.arp, 1)

    def test_direct_tblw_writes_program_space_after_discarded_prefetch(self) -> None:
        model = Tms32010Model()
        model.program[0] = 0x7D78
        model.program[1] = 0x7F80
        model.program[0x456] = 0xAAAA
        model.data[120] = 0xCAFE
        model.state.acc = 0x0000_0456
        model.state.stack = [0xAAA, 0xBBB, 0xCCC, 0xDDD]

        trace = model.step()

        self.assertEqual(trace.mnemonic, "TBLW")
        self.assertEqual(trace.cycles, 3)
        self.assertEqual(model.program[0x456], 0xCAFE)
        self.assertEqual(model.state.pc, 1)
        self.assertEqual(model.state.stack, [0xAAA, 0xBBB, 0xCCC, 0xCCC])
        self.assertEqual(
            self._transactions(trace),
            [
                (0, "program", "instruction_fetch", 0, 0x7D78),
                (1, "program", "discarded_prefetch", 1, 0x7F80),
                (2, "data", "read", 120, 0xCAFE),
                (2, "program", "table_write", 0x456, 0xCAFE),
            ],
        )

    def test_tblw_can_replace_the_discarded_following_word(self) -> None:
        model = Tms32010Model()
        model.program[0] = 0x7D03
        model.program[1] = 0x1111
        model.data[3] = 0x7F80
        model.state.acc = 1

        trace = model.step()

        self.assertEqual(trace.transactions[1].data, 0x1111)
        self.assertEqual(model.program[1], 0x7F80)
        self.assertEqual(model.state.pc, 1)
        next_trace = model.step()
        self.assertEqual(next_trace.mnemonic, "NOP")

    def test_unresolved_address_traps_before_dummy_prefetch_or_stack_effect(
        self,
    ) -> None:
        for opcode in (0x6710, 0x7D10):
            with self.subTest(opcode=opcode):
                model = Tms32010Model()
                model.state.status.dp = 1
                model.state.stack = [1, 2, 3, 4]
                model.program[0] = opcode
                before = model.architectural_state()
                program_before = list(model.program)

                with self.assertRaises(UnsupportedDataAddress):
                    model.step()

                self.assertEqual(model.architectural_state(), before)
                self.assertEqual(model.program, program_before)

    def test_reserved_indirect_controls_are_rejected(self) -> None:
        for opcode in (0x67C0, 0x67B0, 0x7DC8, 0x7DA2):
            with self.subTest(opcode=opcode):
                model = Tms32010Model()
                model.program[0] = opcode
                with self.assertRaises(UnsupportedOpcode):
                    model.step()


if __name__ == "__main__":
    unittest.main()
