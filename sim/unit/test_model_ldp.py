from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
    UnsupportedOpcode,
)


class LdpModelTests(unittest.TestCase):
    def test_direct_uses_old_page_and_loads_only_source_lsb(self) -> None:
        for source, expected_dp in ((0xFFFE, 0), (0x8001, 1)):
            with self.subTest(source=source):
                model = Tms32010Model()
                model.state.status.dp = 1
                model.state.status.ov = True
                model.state.status.ovm = True
                model.data[143] = source
                model.program[0] = 0x6F0F

                trace = model.step()

                self.assertEqual(model.state.status.dp, expected_dp)
                self.assertTrue(model.state.status.ov)
                self.assertTrue(model.state.status.ovm)
                self.assertEqual(trace.operands["effective_address"], 143)
                self.assertEqual(trace.transactions[1].space, "data")
                self.assertEqual(trace.transactions[1].operation, "read")
                self.assertEqual(trace.transactions[1].data, source)
                self.assertEqual(trace.cycles, 1)

    def test_indirect_read_precedes_counter_and_arp_update(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.state.status.arp = 0
        model.state.ar[0] = 0xAA8F
        model.data[143] = 0x1234
        model.program[0] = 0x6FA1

        trace = model.step()

        self.assertEqual(model.state.status.dp, 0)
        self.assertEqual(model.state.ar[0], 0xAA90)
        self.assertEqual(model.state.status.arp, 1)
        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(trace.transactions[1].address, 143)

    def test_indirect_decrement_preserves_requested_old_address(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 1
        model.state.ar[1] = 0xFE00
        model.data[0] = 0xFFFF
        model.program[0] = 0x6F90

        trace = model.step()

        self.assertEqual(model.state.status.dp, 1)
        self.assertEqual(model.state.ar[1], 0xFFFF)
        self.assertEqual(model.state.status.arp, 0)
        self.assertEqual(trace.transactions[1].address, 0)

    def test_unresolved_direct_address_traps_without_state_change(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.program[0] = 0x6F10
        before = model.architectural_state()

        with self.assertRaises(UnsupportedDataAddress):
            model.step()

        self.assertEqual(model.architectural_state(), before)

    def test_reserved_indirect_controls_trap(self) -> None:
        for opcode in (0x6FC8, 0x6F8A, 0x6FB8):
            with self.subTest(opcode=opcode):
                model = Tms32010Model()
                model.program[0] = opcode
                with self.assertRaises(UnsupportedOpcode):
                    model.step()


if __name__ == "__main__":
    unittest.main()
