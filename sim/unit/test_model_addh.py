from __future__ import annotations

import itertools
import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
    UnsupportedOpcode,
)


class AddhModelTests(unittest.TestCase):
    def test_primary_example_adds_data_to_high_half_only(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x0000_0013
        model.state.p = 0x89AB_CDEF
        model.state.t = 0x1357
        model.data[4] = 4
        model.program[0] = 0x6004

        trace = model.step()

        self.assertEqual(trace.mnemonic, "ADDH")
        self.assertEqual(trace.cycles, 1)
        self.assertEqual(model.cycle_count, 1)
        self.assertEqual(model.state.pc, 1)
        self.assertEqual(model.state.acc, 0x0004_0013)
        self.assertEqual(model.state.p, 0x89AB_CDEF)
        self.assertEqual(model.state.t, 0x1357)
        self.assertEqual(len(trace.transactions), 2)
        self.assertEqual(trace.transactions[0].space, "program")
        self.assertEqual(trace.transactions[0].operation, "instruction_fetch")
        self.assertEqual(trace.transactions[1].space, "data")
        self.assertEqual(trace.transactions[1].operation, "read")
        self.assertEqual(trace.transactions[1].address, 4)
        self.assertEqual(trace.transactions[1].data, 4)

    def test_halfword_wraps_preserve_low_half_ov_and_ovm(self) -> None:
        cases = (
            (0x7FFF_1357, 0x0001, 0x8000_1357),
            (0x8000_BEEF, 0xFFFF, 0x7FFF_BEEF),
            (0xFFFF_0001, 0x0001, 0x0000_0001),
            (0x0000_FFFE, 0xFFFF, 0xFFFF_FFFE),
        )
        for (acc, operand, expected), ov, ovm in itertools.product(
            cases,
            (False, True),
            (False, True),
        ):
            with self.subTest(acc=acc, operand=operand, ov=ov, ovm=ovm):
                model = Tms32010Model()
                model.state.acc = acc
                model.state.status.ov = ov
                model.state.status.ovm = ovm
                model.state.status.intm = True
                model.state.status.arp = 1
                model.state.status.dp = 0
                model.state.ar[:] = [0x0111, 0x0022]
                model.state.stack[:] = [1, 2, 3, 4]
                model.data[2] = operand
                model.program[0] = 0x6002

                model.step()

                self.assertEqual(model.state.acc, expected)
                self.assertEqual(model.state.status.ov, ov)
                self.assertEqual(model.state.status.ovm, ovm)
                self.assertTrue(model.state.status.intm)
                self.assertEqual(model.state.status.arp, 1)
                self.assertEqual(model.state.status.dp, 0)
                self.assertEqual(model.state.ar, [0x0111, 0x0022])
                self.assertEqual(model.state.stack, [1, 2, 3, 4])

    def test_direct_page_one_reaches_last_physical_word(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x1234_ABCD
        model.state.status.dp = 1
        model.data[143] = 0x4321
        model.program[0] = 0x600F

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(model.state.acc, 0x5555_ABCD)

    def test_indirect_reads_old_address_then_updates_counter_and_arp(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x0001_2468
        model.state.status.arp = 0
        model.state.ar[:] = [0xAA8F, 0x0007]
        model.data[143] = 2
        model.program[0] = 0x60A1  # ADDH *+,AR1

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 143)
        self.assertEqual(model.state.acc, 0x0003_2468)
        self.assertEqual(model.state.ar, [0xAA90, 0x0007])
        self.assertEqual(model.state.status.arp, 1)

        model.state.status.arp = 1
        model.state.ar[1] = 0
        model.data[0] = 1
        model.program[1] = 0x6090  # ADDH *-,0

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 0)
        self.assertEqual(model.state.acc, 0x0004_2468)
        self.assertEqual(model.state.ar[1], 0x01FF)
        self.assertEqual(model.state.status.arp, 0)

    def test_invalid_address_and_reserved_controls_trap_without_retirement(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x1234_5678
        model.state.status.dp = 1
        model.program[0] = 0x6010
        before = model.architectural_state()

        with self.assertRaises(UnsupportedDataAddress):
            model.step()

        self.assertEqual(model.architectural_state(), before)

        for word in (0x608A, 0x60B8, 0x60C8):
            with self.subTest(word=word):
                model = Tms32010Model()
                model.program[0] = word
                before = model.architectural_state()
                with self.assertRaises(UnsupportedOpcode):
                    model.step()
                self.assertEqual(model.architectural_state(), before)


if __name__ == "__main__":
    unittest.main()
