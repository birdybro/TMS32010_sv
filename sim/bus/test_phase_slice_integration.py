from __future__ import annotations

import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class PhaseSliceIntegrationTests(unittest.TestCase):
    def test_native_samples_drive_sequential_execution_slice(self) -> None:
        verilator = shutil.which("verilator")
        if verilator is None:
            raise RuntimeError("Verilator is required once architectural RTL exists")
        build = ROOT / "build" / "verilator" / "tb_phase_slice_integration"
        build.mkdir(parents=True, exist_ok=True)
        sources = [
            ROOT / "rtl" / "packages" / "tms32010_pkg.sv",
            ROOT / "rtl" / "core" / "tms32010_decode.sv",
            ROOT / "rtl" / "core" / "tms32010_internal_ram.sv",
            ROOT / "rtl" / "core" / "tms32010_multiplier.sv",
            ROOT / "rtl" / "core" / "tms32010_core.sv",
            ROOT / "rtl" / "core" / "tms32010_program_bus.sv",
            ROOT / "rtl" / "wrappers" / "tms32010_phase_slice.sv",
            ROOT / "sim" / "bus" / "tb_phase_slice_integration.sv",
        ]
        result = subprocess.run(
            [
                verilator,
                "--binary",
                "--timing",
                "--Wall",
                "--top-module",
                "tb_phase_slice_integration",
                "--Mdir",
                str(build),
                *map(str, sources),
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        run = subprocess.run(
            [str(build / "Vtb_phase_slice_integration")],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
        self.assertIn("PASS tb_phase_slice_integration", run.stdout)


if __name__ == "__main__":
    unittest.main()
