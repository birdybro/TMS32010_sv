from __future__ import annotations

import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class HardDrivinSoundLocalResetInterlockTests(unittest.TestCase):
    def test_exhaustive_reset_release_truth_table(self) -> None:
        verilator = shutil.which("verilator")
        if verilator is None:
            raise RuntimeError("Verilator is required once architectural RTL exists")
        name = "tb_hard_drivin_sound_local_reset_interlock"
        build = ROOT / "build" / "verilator" / name
        build.mkdir(parents=True, exist_ok=True)
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
                str(
                    ROOT
                    / "rtl"
                    / "wrappers"
                    / "hard_drivin_sound_local_reset_interlock.sv"
                ),
                str(ROOT / "sim" / "bus" / f"{name}.sv"),
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
