from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from sim.reference_models.tms32010_model import (
    Tms32010Model,
    UnsupportedOpcode,
)


class InitialModelSliceTests(unittest.TestCase):
    def test_lack_boundaries_zero_extend(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0xFFFF_FFFF
        model.load_words([0x7E00, 0x7EFF])

        zero = model.step()
        self.assertEqual(zero.mnemonic, "LACK")
        self.assertEqual(model.state.acc, 0)
        maximum = model.step()
        self.assertEqual(maximum.operands, {"constant": 0xFF})
        self.assertEqual(model.state.acc, 0x0000_00FF)

    def test_nop_changes_only_pc_and_cycle_count(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x8123_4567
        model.state.p = 0xFEDC_BA98
        model.state.status.ov = True
        model.load_words([0x7F80])
        trace = model.step()
        self.assertEqual(trace.mnemonic, "NOP")
        self.assertEqual(model.state.acc, 0x8123_4567)
        self.assertEqual(model.state.p, 0xFEDC_BA98)
        self.assertTrue(model.state.status.ov)
        self.assertEqual(model.state.pc, 1)
        self.assertEqual(model.cycle_count, 1)

    def test_zac_does_not_change_overflow_status(self) -> None:
        model = Tms32010Model()
        model.state.acc = 0x8000_0000
        model.state.status.ov = True
        model.state.status.ovm = True
        model.load_words([0x7F89])
        model.step()
        self.assertEqual(model.state.acc, 0)
        self.assertTrue(model.state.status.ov)
        self.assertTrue(model.state.status.ovm)

    def test_overflow_mode_set_and_reset_preserve_ov(self) -> None:
        model = Tms32010Model()
        model.state.status.ov = True
        model.load_words([0x7F8B, 0x7F8A])
        model.step()
        self.assertTrue(model.state.status.ovm)
        self.assertTrue(model.state.status.ov)
        model.step()
        self.assertFalse(model.state.status.ovm)
        self.assertTrue(model.state.status.ov)

    def test_immediate_auxiliary_and_page_controls(self) -> None:
        model = Tms32010Model()
        model.state.ar = [0xFFFF, 0xFFFF]
        model.state.status.arp = 0
        model.state.status.dp = 0
        model.load_words(
            [0x7000, 0x71FF, 0x6881, 0x6E01, 0x6880, 0x6E00]
        )

        traces = [model.step() for _ in range(6)]

        self.assertEqual(model.state.ar, [0x0000, 0x00FF])
        self.assertEqual(model.state.status.arp, 0)
        self.assertEqual(model.state.status.dp, 0)
        self.assertEqual(
            [trace.mnemonic for trace in traces],
            ["LARK", "LARK", "LARP", "LDPK", "LARP", "LDPK"],
        )
        self.assertEqual(
            traces[1].operands,
            {"auxiliary_register": 1, "constant": 255},
        )
        self.assertEqual(traces[3].state_after["status"]["dp"], 1)

    def test_unknown_opcode_traps_without_advancing_state(self) -> None:
        model = Tms32010Model()
        model.load_words([0x7F83])
        before = model.architectural_state()
        with self.assertRaises(UnsupportedOpcode) as caught:
            model.step()
        self.assertEqual(caught.exception.pc, 0)
        self.assertEqual(caught.exception.opcode, 0x7F83)
        self.assertEqual(model.architectural_state(), before)

    def test_pc_wraps_at_12_bits(self) -> None:
        model = Tms32010Model()
        model.state.pc = 0xFFF
        model.program[0xFFF] = 0x7F80
        model.step()
        self.assertEqual(model.state.pc, 0)

    def test_trace_exposes_logical_fetch_and_is_deterministic_json(self) -> None:
        model = Tms32010Model()
        model.load_words([0x7E2A])
        trace = model.step()
        self.assertEqual(trace.transactions[0].space, "program")
        self.assertEqual(trace.transactions[0].address, 0)
        self.assertEqual(trace.transactions[0].data, 0x7E2A)
        parsed = json.loads(trace.to_json())
        self.assertEqual(parsed["mnemonic"], "LACK")
        self.assertEqual(parsed["state_after"]["acc"], 42)

    def test_raw_binary_loader_has_explicit_endianness(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "program.bin"
            path.write_bytes(bytes([0x7F, 0x80, 0x7E, 0x01]))
            model = Tms32010Model()
            model.load_binary(path, byteorder="big")
            self.assertEqual(model.program[:2], [0x7F80, 0x7E01])

    def test_reset_preserves_ovm_and_unrelated_registers(self) -> None:
        model = Tms32010Model()
        model.state.pc = 0x345
        model.state.acc = 0x1234_5678
        model.state.status.ovm = True
        model.state.status.arp = 1
        model.state.status.dp = 1
        model.state.ar = [0x1234, 0x5678]
        model.state.status.intm = False
        model.state.interrupt_pending = True
        model.reset_at_instruction_boundary()
        self.assertEqual(model.state.pc, 0)
        self.assertEqual(model.state.acc, 0x1234_5678)
        self.assertTrue(model.state.status.ovm)
        self.assertEqual(model.state.status.arp, 1)
        self.assertEqual(model.state.status.dp, 1)
        self.assertEqual(model.state.ar, [0x1234, 0x5678])
        self.assertTrue(model.state.status.intm)
        self.assertFalse(model.state.interrupt_pending)


if __name__ == "__main__":
    unittest.main()
