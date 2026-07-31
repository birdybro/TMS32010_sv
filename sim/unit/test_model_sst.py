from __future__ import annotations

import itertools
import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedOpcode,
)


def packed_status(
    ov: bool,
    ovm: bool,
    intm: bool,
    arp: int,
    dp: int,
) -> int:
    return (
        (int(ov) << 15)
        | (int(ovm) << 14)
        | (int(intm) << 13)
        | 0x1EFE
        | ((arp & 1) << 8)
        | (dp & 1)
    )


class SstModelTests(unittest.TestCase):
    def test_direct_exhausts_defined_status_bits_and_forces_page_one(self) -> None:
        for bits in itertools.product((False, True), repeat=5):
            ov, ovm, intm, arp_bit, dp_bit = bits
            for direct in (0, 15):
                with self.subTest(bits=bits, direct=direct):
                    model = Tms32010Model()
                    model.state.status.ov = ov
                    model.state.status.ovm = ovm
                    model.state.status.intm = intm
                    model.state.status.arp = int(arp_bit)
                    model.state.status.dp = int(dp_bit)
                    model.state.acc = 0x8123_4567
                    model.state.p = 0x89AB_CDEF
                    model.state.t = 0x1357
                    model.state.ar[:] = [0x0012, 0x008E]
                    model.program[0] = 0x7C00 | direct

                    trace = model.step()

                    address = 0x80 | direct
                    expected = packed_status(ov, ovm, intm, arp_bit, dp_bit)
                    self.assertEqual(trace.mnemonic, "SST")
                    self.assertEqual(trace.operands["effective_address"], address)
                    self.assertEqual(trace.cycles, 1)
                    self.assertEqual(model.cycle_count, 1)
                    self.assertEqual(model.state.pc, 1)
                    self.assertEqual(model.data[address], expected)
                    self.assertEqual(len(trace.transactions), 2)
                    self.assertEqual(trace.transactions[1].space, "data")
                    self.assertEqual(trace.transactions[1].operation, "write")
                    self.assertEqual(trace.transactions[1].address, address)
                    self.assertEqual(trace.transactions[1].data, expected)
                    self.assertEqual(expected & 0x1EFE, 0x1EFE)
                    self.assertEqual(model.state.acc, 0x8123_4567)
                    self.assertEqual(model.state.p, 0x89AB_CDEF)
                    self.assertEqual(model.state.t, 0x1357)
                    self.assertEqual(model.state.ar, [0x0012, 0x008E])
                    self.assertEqual(
                        (
                            model.state.status.ov,
                            model.state.status.ovm,
                            model.state.status.intm,
                            model.state.status.arp,
                            model.state.status.dp,
                        ),
                        (ov, ovm, intm, int(arp_bit), int(dp_bit)),
                    )

    def test_indirect_captures_old_arp_then_applies_post_update(self) -> None:
        model = Tms32010Model()
        model.state.status.ov = True
        model.state.status.ovm = False
        model.state.status.intm = True
        model.state.status.arp = 1
        model.state.status.dp = 1
        model.state.ar[:] = [0x0004, 0x008E]
        model.program[0] = 0x7CA0  # SST *+,0

        trace = model.step()

        expected = packed_status(True, False, True, 1, 1)
        self.assertEqual(trace.operands["effective_address"], 0x8E)
        self.assertEqual(model.data[0x8E], expected)
        self.assertEqual(trace.transactions[1].data, expected)
        self.assertEqual(model.state.ar, [0x0004, 0x008F])
        self.assertEqual(model.state.status.arp, 0)
        self.assertEqual(model.state.status.dp, 1)

    def test_indirect_decrement_wraps_nine_bit_counter_after_store(self) -> None:
        model = Tms32010Model()
        model.state.status.arp = 0
        model.state.ar[:] = [0x0000, 0x0080]
        model.program[0] = 0x7C91  # SST *-,1

        trace = model.step()

        self.assertEqual(trace.operands["effective_address"], 0)
        self.assertEqual(model.data[0], packed_status(False, False, False, 0, 0))
        self.assertEqual(model.state.ar[0], 0x01FF)
        self.assertEqual(model.state.status.arp, 1)

    def test_rejects_nonexistent_direct_locations_and_reserved_controls(self) -> None:
        for word in (0x7C10, 0x7C7F, 0x7CC8, 0x7C8A, 0x7CB8):
            with self.subTest(word=word):
                model = Tms32010Model()
                model.program[0] = word
                with self.assertRaises(UnsupportedOpcode):
                    model.step()


if __name__ == "__main__":
    unittest.main()
