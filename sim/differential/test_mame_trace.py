from __future__ import annotations

import io
import json
import tempfile
import unittest
from pathlib import Path

from tools.reference.mame_trace import (
    DEFAULT_DEVICE_TAG,
    TraceFormatError,
    compare_steps,
    debugger_trace_command,
    main,
    parse_mame_lines,
    parse_model_lines,
)


def state_line(
    *,
    pc: int,
    acc: int = 0,
    p: int = 0,
    t: int = 0,
    ar0: int = 0,
    ar1: int = 0,
    status: int = 0,
    stk0: int = 0,
    stk1: int = 0,
    stk2: int = 0,
    stk3: int = 0,
) -> str:
    return (
        "prefix TMS32010_STATE "
        f"PC={pc:04X} ACC={acc:08X} P={p:08X} T={t:04X} "
        f"AR0={ar0:04X} AR1={ar1:04X} STR={status:04X} "
        f"STK0={stk0:04X} STK1={stk1:04X} "
        f"STK2={stk2:04X} STK3={stk3:04X} 0000: LACK 5\n"
    )


def model_line(
    *,
    pc: int,
    opcode: int,
    mnemonic: str,
    next_pc: int,
    acc: int = 0,
    p: int = 0,
    t: int = 0,
    ar: list[int] | None = None,
    stack: list[int] | None = None,
    ov: bool = False,
    ovm: bool = False,
    intm: bool = False,
    arp: int = 0,
    dp: int = 0,
) -> str:
    return json.dumps(
        {
            "pc": pc,
            "opcode": opcode,
            "mnemonic": mnemonic,
            "operands": {},
            "cycles": 1,
            "transactions": [],
            "state_after": {
                "pc": next_pc,
                "acc": acc,
                "p": p,
                "t": t,
                "ar": ar or [0, 0],
                "stack": stack or [0, 0, 0, 0],
                "status": {
                    "ov": ov,
                    "ovm": ovm,
                    "intm": intm,
                    "arp": arp,
                    "dp": dp,
                },
            },
        }
    )


class MameTraceAdapterTests(unittest.TestCase):
    def test_parse_normalizes_status_and_stack_order(self) -> None:
        states = parse_mame_lines(
            [
                state_line(
                    pc=0x123,
                    acc=0xFEDCBA98,
                    p=0x80000000,
                    t=0x8123,
                    ar0=0xAA8F,
                    ar1=0x0077,
                    status=0xE101,
                    stk0=0x111,
                    stk1=0x222,
                    stk2=0x333,
                    stk3=0x444,
                )
            ]
        )
        state = states[0]
        self.assertEqual(state.pc, 0x123)
        self.assertEqual(state.acc, 0xFEDCBA98)
        self.assertEqual(state.p, 0x80000000)
        self.assertEqual(state.ar, (0xAA8F, 0x0077))
        self.assertEqual(state.stack, (0x444, 0x333, 0x222, 0x111))
        self.assertTrue(state.ov)
        self.assertTrue(state.ovm)
        self.assertTrue(state.intm)
        self.assertEqual(state.arp, 1)
        self.assertEqual(state.dp, 1)

    def test_compare_aligns_model_post_state_with_following_mame_row(self) -> None:
        model = parse_model_lines(
            [
                model_line(
                    pc=0,
                    opcode=0x7E05,
                    mnemonic="LACK",
                    next_pc=1,
                    acc=5,
                    ar=[0xAA8F, 0x77],
                    stack=[0x444, 0x333, 0x222, 0x111],
                    ov=True,
                    intm=True,
                    arp=1,
                    dp=1,
                ),
                model_line(
                    pc=1,
                    opcode=0x7F80,
                    mnemonic="NOP",
                    next_pc=2,
                    acc=5,
                    ar=[0xAA8F, 0x77],
                    stack=[0x444, 0x333, 0x222, 0x111],
                    ov=True,
                    intm=True,
                    arp=1,
                    dp=1,
                ),
            ]
        )
        mame = parse_mame_lines(
            [
                state_line(pc=0),
                state_line(
                    pc=1,
                    acc=5,
                    ar0=0xAA8F,
                    ar1=0x77,
                    status=0xA101,
                    stk0=0x111,
                    stk1=0x222,
                    stk2=0x333,
                    stk3=0x444,
                ),
                state_line(
                    pc=2,
                    acc=5,
                    ar0=0xAA8F,
                    ar1=0x77,
                    status=0xA101,
                    stk0=0x111,
                    stk1=0x222,
                    stk2=0x333,
                    stk3=0x444,
                ),
            ]
        )
        result = compare_steps(model, mame)
        self.assertEqual(result.compared_steps, 2)
        self.assertEqual(result.mame_rows, 3)
        self.assertEqual(result.mismatches, ())

    def test_compare_requires_following_sentinel_row(self) -> None:
        model = parse_model_lines(
            [model_line(pc=0, opcode=0x7F80, mnemonic="NOP", next_pc=1)]
        )
        with self.assertRaisesRegex(TraceFormatError, "following sentinel"):
            compare_steps(model, parse_mame_lines([state_line(pc=0)]))
        three_rows = parse_mame_lines(
            [state_line(pc=0), state_line(pc=1), state_line(pc=2)]
        )
        with self.assertRaisesRegex(TraceFormatError, "exactly 2"):
            compare_steps(model, three_rows)
        self.assertEqual(
            compare_steps(model, three_rows, allow_trailing=True).mame_rows, 3
        )

    def test_malformed_marker_and_original_part_width_are_rejected(self) -> None:
        with self.assertRaisesRegex(TraceFormatError, "malformed"):
            parse_mame_lines(["TMS32010_STATE PC=0000 incomplete\n"])
        with self.assertRaisesRegex(TraceFormatError, "12-bit program space"):
            parse_mame_lines([state_line(pc=0x1000)])
        with self.assertRaisesRegex(TraceFormatError, "12-bit stack width"):
            parse_mame_lines([state_line(pc=0, stk3=0x1000)])

    def test_model_state_types_and_widths_are_strict(self) -> None:
        record = json.loads(
            model_line(pc=0, opcode=0x7F80, mnemonic="NOP", next_pc=1)
        )
        record["state_after"]["status"]["ov"] = 1
        model = parse_model_lines([json.dumps(record)])
        mame = parse_mame_lines([state_line(pc=0), state_line(pc=1)])
        with self.assertRaisesRegex(TraceFormatError, "status.ov must be boolean"):
            compare_steps(model, mame)
        record["state_after"]["status"]["ov"] = False
        record["state_after"]["stack"][0] = 0x1000
        model = parse_model_lines([json.dumps(record)])
        with self.assertRaisesRegex(TraceFormatError, r"stack\[0\].*exceeds range"):
            compare_steps(model, mame)
        interrupt_record = json.loads(
            model_line(
                pc=0, opcode=0x7F80, mnemonic="INTERRUPT", next_pc=2
            )
        )
        with self.assertRaisesRegex(TraceFormatError, "hold interrupt inactive"):
            parse_model_lines([json.dumps(interrupt_record)])

    def test_debugger_command_is_deterministic_and_rejects_injection(self) -> None:
        command = debugger_trace_command("build/mame/tms.tr", DEFAULT_DEVICE_TAG)
        self.assertEqual(
            command,
            "trace build/mame/tms.tr,:mainpcb:harddriv_sound:sounddsp,noloop,"
            '{tracelog "TMS32010_STATE PC=%04X ACC=%08X P=%08X T=%04X '
            "AR0=%04X AR1=%04X STR=%04X STK0=%04X STK1=%04X STK2=%04X "
            'STK3=%04X ",PC,ACC,P,T,AR0,AR1,STR,STK0,STK1,STK2,STK3}',
        )
        with self.assertRaisesRegex(ValueError, "filename"):
            debugger_trace_command("trace.tr,{quit}", DEFAULT_DEVICE_TAG)
        with self.assertRaisesRegex(ValueError, "device tag"):
            debugger_trace_command("trace.tr", ":sounddsp,{quit}")

    def test_cli_reports_field_mismatch_and_success(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            model_path = root / "model.jsonl"
            mame_path = root / "mame.tr"
            model_path.write_text(
                model_line(
                    pc=0, opcode=0x7E05, mnemonic="LACK", next_pc=1, acc=5
                )
                + "\n",
                encoding="utf-8",
            )
            mame_path.write_text(
                state_line(pc=0) + state_line(pc=1, acc=4), encoding="utf-8"
            )
            stdout = io.StringIO()
            stderr = io.StringIO()
            self.assertEqual(
                main(
                    [
                        "compare",
                        "--model",
                        str(model_path),
                        "--mame",
                        str(mame_path),
                    ],
                    stdout=stdout,
                    stderr=stderr,
                ),
                1,
            )
            self.assertIn("post.acc model=0x5 mame=0x4", stderr.getvalue())
            mame_path.write_text(
                state_line(pc=0) + state_line(pc=1, acc=5), encoding="utf-8"
            )
            stdout = io.StringIO()
            stderr = io.StringIO()
            self.assertEqual(
                main(
                    [
                        "compare",
                        "--model",
                        str(model_path),
                        "--mame",
                        str(mame_path),
                    ],
                    stdout=stdout,
                    stderr=stderr,
                ),
                0,
            )
            self.assertIn("PASS: 1 model steps match MAME", stdout.getvalue())
            self.assertEqual(stderr.getvalue(), "")


if __name__ == "__main__":
    unittest.main()
