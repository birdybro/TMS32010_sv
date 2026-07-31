from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
    UnsupportedOpcode,
)


class IoModelTests(unittest.TestCase):
    def test_direct_in_samples_port_and_writes_page_selected_ram(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.io_input[5] = 0xBEEF
        model.program[0] = 0x4503

        trace = model.step()

        self.assertEqual(trace.mnemonic, "IN")
        self.assertEqual(
            trace.operands,
            {
                "port": 5,
                "indirect": 0,
                "addressing_field": 3,
                "effective_address": 131,
            },
        )
        self.assertEqual(trace.cycles, 2)
        self.assertEqual(model.data[131], 0xBEEF)
        self.assertEqual(model.state.pc, 1)
        self.assertEqual(model.cycle_count, 2)
        self.assertEqual(
            [
                (
                    transaction.cycle,
                    transaction.space,
                    transaction.operation,
                    transaction.address,
                    transaction.data,
                )
                for transaction in trace.transactions
            ],
            [
                (0, "program", "instruction_fetch", 0, 0x4503),
                (1, "io", "read", 5, 0xBEEF),
                (1, "data", "write", 131, 0xBEEF),
            ],
        )

    def test_indirect_in_uses_old_ar_then_updates_ar_and_arp(self) -> None:
        model = Tms32010Model()
        model.state.ar = [143, 22]
        model.state.status.arp = 0
        model.io_input[1] = 0x1357
        model.program[0] = 0x41A1

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(model.data[143], 0x1357)
        self.assertEqual(model.state.ar, [144, 22])
        self.assertEqual(model.state.status.arp, 1)

    def test_direct_out_reads_ram_and_drives_selected_port(self) -> None:
        model = Tms32010Model()
        model.data[120] = 0xCAFE
        model.program[0] = 0x4F78

        trace = model.step()

        self.assertEqual(trace.mnemonic, "OUT")
        self.assertEqual(trace.cycles, 2)
        self.assertEqual(model.io_output[7], 0xCAFE)
        self.assertEqual(model.state.pc, 1)
        self.assertEqual(model.cycle_count, 2)
        self.assertEqual(
            [
                (
                    transaction.cycle,
                    transaction.space,
                    transaction.operation,
                    transaction.address,
                    transaction.data,
                )
                for transaction in trace.transactions
            ],
            [
                (0, "program", "instruction_fetch", 0, 0x4F78),
                (1, "data", "read", 120, 0xCAFE),
                (1, "io", "write", 7, 0xCAFE),
            ],
        )

    def test_indirect_out_decrements_after_read_and_preserves_other_state(
        self,
    ) -> None:
        model = Tms32010Model()
        model.state.acc = 0x8123_4567
        model.state.p = 0x89AB_CDEF
        model.state.t = 0x8001
        model.state.ar = [8, 77]
        model.state.stack = [1, 2, 3, 4]
        model.state.status.ov = True
        model.state.status.ovm = True
        model.state.status.intm = True
        model.state.status.arp = 0
        model.state.interrupt_pending = True
        model.data[8] = 0xA55A
        model.program[0] = 0x4D98
        before = model.architectural_state()

        model.step()

        self.assertEqual(model.io_output[5], 0xA55A)
        self.assertEqual(model.state.ar, [7, 77])
        after = model.architectural_state()
        for key in ("acc", "p", "t", "stack", "interrupt_pending"):
            self.assertEqual(after[key], before[key])
        self.assertEqual(after["status"], before["status"])

    def test_unresolved_address_traps_before_io_or_state_effects(self) -> None:
        for opcode in (0x4010, 0x4810):
            with self.subTest(opcode=opcode):
                model = Tms32010Model()
                model.state.status.dp = 1
                model.program[0] = opcode
                model.io_input[0] = 0xBEEF
                model.io_output[0] = 0x1234
                state_before = model.architectural_state()
                data_before = list(model.data)
                io_before = list(model.io_output)

                with self.assertRaises(UnsupportedDataAddress):
                    model.step()

                self.assertEqual(model.architectural_state(), state_before)
                self.assertEqual(model.data, data_before)
                self.assertEqual(model.io_output, io_before)

    def test_reserved_indirect_controls_are_rejected(self) -> None:
        for opcode in (0x40C0, 0x40B0, 0x48C8, 0x48A2):
            with self.subTest(opcode=opcode):
                model = Tms32010Model()
                model.program[0] = opcode
                with self.assertRaises(UnsupportedOpcode):
                    model.step()


if __name__ == "__main__":
    unittest.main()
