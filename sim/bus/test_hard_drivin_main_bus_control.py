from __future__ import annotations

import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class HardDrivinMainBusControlTests(unittest.TestCase):
    def test_address_driven_main_bus_control_sequences(self) -> None:
        verilator = shutil.which("verilator")
        if verilator is None:
            raise RuntimeError("Verilator is required once architectural RTL exists")
        name = "tb_hard_drivin_main_bus_control"
        build = ROOT / "build" / "verilator" / name
        build.mkdir(parents=True, exist_ok=True)
        sources = [
            ROOT / "rtl" / "wrappers" / "hard_drivin_main_address_decode.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_main_dtack_decode.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_main_rvas_timing.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_main_bus_control.sv",
            ROOT / "sim" / "bus" / f"{name}.sv",
        ]
        result = subprocess.run(
            [
                verilator,
                "--binary",
                "--timing",
                "--Wall",
                "--top-module",
                name,
                "--Mdir",
                str(build),
                *(str(source) for source in sources),
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        run = subprocess.run(
            [str(build / f"V{name}")],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
        self.assertIn(f"PASS {name}", run.stdout)


if __name__ == "__main__":
    unittest.main()
