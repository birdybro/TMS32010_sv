from __future__ import annotations

import unittest

from sim.reference_models.tms32010_model import Tms32010Model


class MpykModelTests(unittest.TestCase):
    def _multiply(self, t_value: int, constant: int) -> Tms32010Model:
        model = Tms32010Model()
        model.state.t = t_value
        model.program[0] = 0x8000 | (constant & 0x1FFF)
        trace = model.step()
        self.assertEqual(trace.cycles, 1)
        self.assertEqual(len(trace.transactions), 1)
        self.assertEqual(trace.transactions[0].space, "program")
        return model

    def test_primary_example_and_signed_boundaries(self) -> None:
        cases = (
            (0x0007, -9, 0xFFFF_FFC1),
            (0x0000, -4096, 0x0000_0000),
            (0x0001, -4096, 0xFFFF_F000),
            (0xFFFF, -4096, 0x0000_1000),
            (0x7FFF, 4095, 0x07FF_7001),
            (0x8000, 4095, 0xF800_8000),
        )
        for t_value, constant, expected in cases:
            with self.subTest(t=t_value, constant=constant):
                model = self._multiply(t_value, constant)
                self.assertEqual(model.state.p, expected)

    def test_zero_and_positive_one_decode_without_data_access(self) -> None:
        for constant, opcode in ((0, 0x8000), (1, 0x8001)):
            with self.subTest(constant=constant):
                model = Tms32010Model()
                model.state.t = 0x8123
                model.program[0] = opcode
                trace = model.step()
                expected = 0 if constant == 0 else 0xFFFF_8123
                self.assertEqual(model.state.p, expected)
                self.assertEqual(len(trace.transactions), 1)

    def test_preserves_t_accumulator_status_address_state_and_ram(self) -> None:
        model = Tms32010Model()
        model.state.t = 0xFFFE
        model.state.acc = 0x1234_5678
        model.state.status.ov = True
        model.state.status.ovm = True
        model.state.status.arp = 1
        model.state.status.dp = 1
        model.state.ar[:] = [0xAAAA, 0x5555]
        model.data[0] = 0xBEEF
        model.program[0] = 0x8FFD

        trace = model.step()

        self.assertEqual(model.state.p, 0xFFFF_E006)
        self.assertEqual(model.state.t, 0xFFFE)
        self.assertEqual(model.state.acc, 0x1234_5678)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)
        self.assertTrue(model.state.status.arp)
        self.assertTrue(model.state.status.dp)
        self.assertEqual(model.state.ar, [0xAAAA, 0x5555])
        self.assertEqual(model.data[0], 0xBEEF)
        self.assertEqual(len(trace.transactions), 1)


if __name__ == "__main__":
    unittest.main()
