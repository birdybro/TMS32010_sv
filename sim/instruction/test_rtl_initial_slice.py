from __future__ import annotations

import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = ROOT / "rtl" / "packages" / "tms32010_pkg.sv"
DECODE = ROOT / "rtl" / "core" / "tms32010_decode.sv"
CORE = ROOT / "rtl" / "core" / "tms32010_core.sv"


class RtlInitialSliceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.verilator = shutil.which("verilator")
        if cls.verilator is None:
            raise RuntimeError("Verilator is required once architectural RTL exists")

    def _run_testbench(self, name: str, sources: list[Path]) -> None:
        build = ROOT / "build" / "verilator" / name
        build.mkdir(parents=True, exist_ok=True)
        command = [
            self.verilator,
            "--binary",
            "--timing",
            "--Wall",
            "--top-module",
            name,
            "--Mdir",
            str(build),
            *map(str, sources),
        ]
        compile_result = subprocess.run(
            command,
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
        self.assertIn(f"PASS {name}", run_result.stdout)

    def test_exhaustive_supported_decode_space(self) -> None:
        self._run_testbench(
            "tb_decode_exhaustive",
            [
                PACKAGE,
                DECODE,
                ROOT / "sim" / "instruction" / "tb_decode_exhaustive.sv",
            ],
        )

    def test_instruction_state_clock_enable_and_reset(self) -> None:
        self._run_testbench(
            "tb_initial_rtl_slice",
            [
                PACKAGE,
                DECODE,
                CORE,
                ROOT / "sim" / "instruction" / "tb_initial_rtl_slice.sv",
            ],
        )


if __name__ == "__main__":
    unittest.main()
