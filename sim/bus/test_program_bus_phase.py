from __future__ import annotations

import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class ProgramBusPhaseTests(unittest.TestCase):
    def test_primary_transcribed_normal_read_and_reset_phases(self) -> None:
        verilator = shutil.which("verilator")
        if verilator is None:
            raise RuntimeError("Verilator is required once architectural RTL exists")
        build = ROOT / "build" / "verilator" / "tb_program_bus_phase"
        build.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(
            [
                verilator,
                "--binary",
                "--timing",
                "--Wall",
                "--top-module",
                "tb_program_bus_phase",
                "--Mdir",
                str(build),
                str(ROOT / "rtl" / "core" / "tms32010_program_bus.sv"),
                str(ROOT / "sim" / "bus" / "tb_program_bus_phase.sv"),
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        run = subprocess.run(
            [str(build / "Vtb_program_bus_phase")],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
        self.assertIn("PASS tb_program_bus_phase", run.stdout)


if __name__ == "__main__":
    unittest.main()
