from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
    UnsupportedOpcode,
)


class LtaModelTests(unittest.TestCase):
    def _execute_arithmetic(
        self,
        accumulator: int,
        product: int,
        *,
        overflow: bool = False,
        overflow_mode: bool = False,
    ) -> Tms32010Model:
        model = Tms32010Model()
        model.state.acc = accumulator
        model.state.p = product
        model.state.t = 0xAAAA
        model.state.status.ov = overflow
        model.state.status.ovm = overflow_mode
        model.data[24] = 0x8062
        model.program[0] = 0x6C18

        trace = model.step()

        self.assertEqual(trace.mnemonic, "LTA")
        self.assertEqual(trace.cycles, 1)
        self.assertEqual(model.state.t, 0x8062)
        self.assertEqual(model.state.p, product & 0xFFFF_FFFF)
        self.assertEqual(model.state.pc, 1)
        self.assertEqual(model.cycle_count, 1)
        self.assertEqual(len(trace.transactions), 2)
        self.assertEqual(trace.transactions[0].space, "program")
        self.assertEqual(trace.transactions[1].space, "data")
        self.assertEqual(trace.transactions[1].operation, "read")
        self.assertEqual(trace.transactions[1].address, 24)
        self.assertEqual(trace.transactions[1].data, 0x8062)
        return model

    def test_primary_example_loads_t_and_accumulates_previous_product(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x0000_0005
        model.state.p = 0x0000_000F
        model.state.t = 0x0003
        model.data[24] = 0x0062
        model.program[0] = 0x6C18

        trace = model.step()

        self.assertEqual(model.state.t, 0x0062)
        self.assertEqual(model.state.acc, 0x0000_0014)
        self.assertEqual(model.state.p, 0x0000_000F)
        self.assertFalse(model.state.status.ov)
        self.assertEqual(trace.operands["effective_address"], 24)
        self.assertEqual(trace.cycles, 1)

    def test_positive_overflow_wraps_or_saturates_under_ovm(self) -> None:
        wrapped = self._execute_arithmetic(0x7FFF_FFFE, 0x0000_0002)
        saturated = self._execute_arithmetic(
            0x7FFF_FFFE,
            0x0000_0002,
            overflow_mode=True,
        )

        self.assertEqual(wrapped.state.acc, 0x8000_0000)
        self.assertTrue(wrapped.state.status.ov)
        self.assertFalse(wrapped.state.status.ovm)
        self.assertEqual(saturated.state.acc, 0x7FFF_FFFF)
        self.assertTrue(saturated.state.status.ov)
        self.assertTrue(saturated.state.status.ovm)

    def test_negative_overflow_wraps_or_saturates_under_ovm(self) -> None:
        wrapped = self._execute_arithmetic(0x8000_0001, 0xFFFF_FFFE)
        saturated = self._execute_arithmetic(
            0x8000_0001,
            0xFFFF_FFFE,
            overflow_mode=True,
        )

        self.assertEqual(wrapped.state.acc, 0x7FFF_FFFF)
        self.assertTrue(wrapped.state.status.ov)
        self.assertFalse(wrapped.state.status.ovm)
        self.assertEqual(saturated.state.acc, 0x8000_0000)
        self.assertTrue(saturated.state.status.ov)
        self.assertTrue(saturated.state.status.ovm)

    def test_nonoverflowing_lta_preserves_sticky_ov_and_unrelated_state(
        self,
    ) -> None:
        model = self._execute_arithmetic(
            0x0000_0010,
            0x0000_0008,
            overflow=True,
            overflow_mode=True,
        )

        self.assertEqual(model.state.acc, 0x0000_0018)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)

    def test_indirect_read_precedes_counter_and_arp_update(self) -> None:
        model = Tms32010Model()
        model.state.acc = 5
        model.state.p = 15
        model.state.status.arp = 0
        model.state.ar[:] = [0xAA18, 0x5555]
        model.data[24] = 0x0062
        model.program[0] = 0x6CA1

        trace = model.step()

        self.assertEqual(model.state.t, 0x0062)
        self.assertEqual(model.state.acc, 20)
        self.assertEqual(model.state.p, 15)
        self.assertEqual(model.state.ar, [0xAA19, 0x5555])
        self.assertEqual(model.state.status.arp, 1)
        self.assertEqual(trace.transactions[1].address, 24)

    def test_unresolved_direct_address_traps_without_parallel_effects(
        self,
    ) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.state.acc = 5
        model.state.p = 15
        model.state.t = 3
        model.program[0] = 0x6C10
        before = model.architectural_state()

        with self.assertRaises(UnsupportedDataAddress):
            model.step()

        self.assertEqual(model.architectural_state(), before)

    def test_reserved_indirect_controls_trap(self) -> None:
        for opcode in (0x6CC8, 0x6C8A, 0x6CB8):
            with self.subTest(opcode=opcode):
                model = Tms32010Model()
                model.program[0] = opcode
                with self.assertRaises(UnsupportedOpcode):
                    model.step()


if __name__ == "__main__":
    unittest.main()
