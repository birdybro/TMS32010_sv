from __future__ import annotations

import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class ResetRtlTests(unittest.TestCase):
    def test_documented_effects_and_provisional_retention_boundary(self) -> None:
        verilator = shutil.which("verilator")
        if verilator is None:
            raise RuntimeError(
                "Verilator is required once architectural RTL exists"
            )
        name = "tb_reset"
        build = ROOT / "build" / "verilator" / name
        build.mkdir(parents=True, exist_ok=True)
        sources = [
            ROOT / "rtl" / "packages" / "tms32010_pkg.sv",
            ROOT / "rtl" / "core" / "tms32010_decode.sv",
            ROOT / "rtl" / "core" / "tms32010_internal_ram.sv",
            ROOT / "rtl" / "core" / "tms32010_multiplier.sv",
            ROOT / "rtl" / "core" / "tms32010_input_shifter.sv",
            ROOT / "rtl" / "core" / "tms32010_output_shifter.sv",
            ROOT / "rtl" / "core" / "tms32010_accumulator.sv",
            ROOT / "rtl" / "core" / "tms32010_core.sv",
            ROOT / "sim" / "unit" / f"{name}.sv",
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
        self.assertIn(f"PASS {name}", run_result.stdout)


if __name__ == "__main__":
    unittest.main()
