from __future__ import annotations

import shutil
import subprocess
import unittest
from pathlib import Path

from sim.reference_models.tms32010_model import Tms32010Model

ROOT = Path(__file__).resolve().parents[2]


class InterruptModelRtlDifferentialTests(unittest.TestCase):
    def test_eint_dummy_entry_and_vector_trace(self) -> None:
        verilator = shutil.which("verilator")
        if verilator is None:
            raise RuntimeError(
                "Verilator is required once architectural RTL exists"
            )
        name = "tb_interrupt_model_rtl"
        build = ROOT / "build" / "verilator" / name
        build.mkdir(parents=True, exist_ok=True)
        sources = [
            ROOT / "rtl" / "packages" / "tms32010_pkg.sv",
            ROOT / "rtl" / "core" / "tms32010_decode.sv",
            ROOT / "rtl" / "core" / "tms32010_internal_ram.sv",
            ROOT / "rtl" / "core" / "tms32010_multiplier.sv",
            ROOT / "rtl" / "core" / "tms32010_core.sv",
            ROOT / "sim" / "differential" / "tb_interrupt_model_rtl.sv",
        ]
        compile_result = subprocess.run(
            [
                verilator,
                "--binary",
                "--timing",
                "--Wall",
                "--Wno-PINCONNECTEMPTY",
                "--top-module",
                name,
                "--Mdir",
                str(build),
                *map(str, sources),
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(
            compile_result.returncode,
            0,
            compile_result.stdout + compile_result.stderr,
        )
        run_result = subprocess.run(
            [str(build / f"V{name}")],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(
            run_result.returncode,
            0,
            run_result.stdout + run_result.stderr,
        )

        rtl_rows: list[tuple[int, ...]] = []
        for line in run_result.stdout.splitlines():
            if line.startswith("TRACE "):
                fields = line.split()
                rtl_rows.append(
                    (
                        int(fields[1]),
                        int(fields[2], 16),
                        int(fields[3], 16),
                        int(fields[4], 16),
                        int(fields[5]),
                        int(fields[6]),
                        int(fields[7]),
                        int(fields[8]),
                    )
                )

        model = Tms32010Model()
        model.program[0] = 0x7F82
        model.program[1] = 0x7E2A
        model.program[2] = 0x7E5A
        model.state.status.intm = True
        model.interrupt_input_high = False
        traces = [model.step()]
        model.interrupt_input_high = True
        traces.extend(model.step() for _ in range(3))
        model_rows = [
            (
                index,
                int(trace.state_after["pc"]),
                int(trace.state_after["acc"]),
                int(trace.state_after["stack"][0]),
                int(trace.state_after["status"]["intm"]),
                int(trace.state_after["interrupt_pending"]),
                int(trace.state_after["cycle_count"]),
                int(trace.mnemonic != "INTERRUPT"),
            )
            for index, trace in enumerate(traces)
        ]

        self.assertEqual(rtl_rows, model_rows)
        self.assertEqual(
            [trace.mnemonic for trace in traces],
            ["EINT", "LACK", "INTERRUPT", "LACK"],
        )


if __name__ == "__main__":
    unittest.main()
