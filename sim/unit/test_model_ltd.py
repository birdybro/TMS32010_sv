from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedDataAddress,
    UnsupportedOpcode,
)


class LtdModelTests(unittest.TestCase):
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
        model.data[25] = 0x1234
        model.program[0] = 0x6B18

        trace = model.step()

        self.assertEqual(trace.mnemonic, "LTD")
        self.assertEqual(trace.cycles, 1)
        self.assertEqual(model.state.t, 0x8062)
        self.assertEqual(model.state.p, product & 0xFFFF_FFFF)
        self.assertEqual(model.data[24:26], [0x8062, 0x8062])
        self.assertEqual(model.state.pc, 1)
        self.assertEqual(model.cycle_count, 1)
        self.assertEqual(len(trace.transactions), 3)
        self.assertEqual(
            (
                trace.transactions[1].space,
                trace.transactions[1].operation,
                trace.transactions[1].address,
                trace.transactions[1].data,
            ),
            ("data", "read", 24, 0x8062),
        )
        self.assertEqual(
            (
                trace.transactions[2].space,
                trace.transactions[2].operation,
                trace.transactions[2].address,
                trace.transactions[2].data,
            ),
            ("data", "write", 25, 0x8062),
        )
        return model

    def test_primary_example_performs_all_three_parallel_operations(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x0000_0005
        model.state.p = 0x0000_000F
        model.state.t = 0x0003
        model.data[24] = 0x0062
        model.data[25] = 0x0000
        model.program[0] = 0x6B18

        trace = model.step()

        self.assertEqual(model.state.t, 0x0062)
        self.assertEqual(model.state.acc, 0x0000_0014)
        self.assertEqual(model.state.p, 0x0000_000F)
        self.assertEqual(model.data[24:26], [0x0062, 0x0062])
        self.assertFalse(model.state.status.ov)
        self.assertEqual(trace.operands["effective_address"], 24)
        self.assertEqual(trace.operands["move_address"], 25)

    def test_positive_overflow_wraps_or_saturates_under_ovm(self) -> None:
        wrapped = self._execute_arithmetic(0x7FFF_FFFE, 0x0000_0002)
        saturated = self._execute_arithmetic(
            0x7FFF_FFFE,
            0x0000_0002,
            overflow_mode=True,
        )

        self.assertEqual(wrapped.state.acc, 0x8000_0000)
        self.assertTrue(wrapped.state.status.ov)
        self.assertEqual(saturated.state.acc, 0x7FFF_FFFF)
        self.assertTrue(saturated.state.status.ov)

    def test_negative_overflow_wraps_or_saturates_under_ovm(self) -> None:
        wrapped = self._execute_arithmetic(0x8000_0001, 0xFFFF_FFFE)
        saturated = self._execute_arithmetic(
            0x8000_0001,
            0xFFFF_FFFE,
            overflow_mode=True,
        )

        self.assertEqual(wrapped.state.acc, 0x7FFF_FFFF)
        self.assertTrue(wrapped.state.status.ov)
        self.assertEqual(saturated.state.acc, 0x8000_0000)
        self.assertTrue(saturated.state.status.ov)

    def test_nonoverflowing_ltd_preserves_sticky_ov(self) -> None:
        model = self._execute_arithmetic(
            0x0000_0010,
            0x0000_0008,
            overflow=True,
            overflow_mode=True,
        )

        self.assertEqual(model.state.acc, 0x0000_0018)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)

    def test_move_crosses_direct_page_boundary_without_changing_dp(self) -> None:
        model = Tms32010Model()
        model.state.status.dp = 0
        model.data[127] = 0xCAFE
        model.data[128] = 0x0000
        model.program[0] = 0x6B7F

        trace = model.step()

        self.assertEqual(model.data[127:129], [0xCAFE, 0xCAFE])
        self.assertEqual(model.state.t, 0xCAFE)
        self.assertEqual(model.state.status.dp, 0)
        self.assertEqual(trace.transactions[2].address, 128)

    def test_indirect_move_precedes_counter_and_arp_update(self) -> None:
        model = Tms32010Model()
        model.state.acc = 5
        model.state.p = 15
        model.state.status.arp = 0
        model.state.ar[:] = [0xAA18, 0x5555]
        model.data[24] = 0x0062
        model.data[25] = 0x0000
        model.program[0] = 0x6BA1

        trace = model.step()

        self.assertEqual(model.state.t, 0x0062)
        self.assertEqual(model.state.acc, 20)
        self.assertEqual(model.data[24:26], [0x0062, 0x0062])
        self.assertEqual(model.state.ar, [0xAA19, 0x5555])
        self.assertEqual(model.state.status.arp, 1)
        self.assertEqual(
            [transaction.address for transaction in trace.transactions[1:]],
            [24, 25],
        )

    def test_unresolved_destination_traps_before_every_parallel_effect(
        self,
    ) -> None:
        model = Tms32010Model()
        model.state.status.dp = 1
        model.state.acc = 5
        model.state.p = 15
        model.state.t = 3
        model.state.ar[:] = [0x008F, 0x5555]
        model.data[143] = 0x0062
        model.program[0] = 0x6B0F
        before_state = model.architectural_state()
        before_data = list(model.data)

        with self.assertRaises(UnsupportedDataAddress) as context:
            model.step()

        self.assertEqual(context.exception.address, 144)
        self.assertEqual(model.architectural_state(), before_state)
        self.assertEqual(model.data, before_data)

    def test_reserved_indirect_controls_trap(self) -> None:
        for opcode in (0x6BC8, 0x6B8A, 0x6BB8):
            with self.subTest(opcode=opcode):
                model = Tms32010Model()
                model.program[0] = opcode
                with self.assertRaises(UnsupportedOpcode):
                    model.step()


if __name__ == "__main__":
    unittest.main()
