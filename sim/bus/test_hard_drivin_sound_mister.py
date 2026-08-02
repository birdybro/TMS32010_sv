from __future__ import annotations

import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class HardDrivinSoundMisterTests(unittest.TestCase):
    def test_host_loaded_smoke_and_low_tblw_alias_execute_in_rtl(self) -> None:
        verilator = shutil.which("verilator")
        if verilator is None:
            raise RuntimeError("Verilator is required once architectural RTL exists")
        name = "tb_hard_drivin_sound_mister"
        build = ROOT / "build" / "verilator" / name
        build.mkdir(parents=True, exist_ok=True)
        sources = [
            ROOT / "rtl" / "packages" / "tms32010_pkg.sv",
            ROOT / "rtl" / "core" / "tms32010_decode.sv",
            ROOT / "rtl" / "core" / "tms32010_internal_ram.sv",
            ROOT / "rtl" / "core" / "tms32010_multiplier.sv",
            ROOT / "rtl" / "core" / "tms32010_input_shifter.sv",
            ROOT / "rtl" / "core" / "tms32010_accumulator.sv",
            ROOT / "rtl" / "core" / "tms32010_fetch_execute.sv",
            ROOT / "rtl" / "core" / "tms32010_core.sv",
            ROOT / "rtl" / "core" / "tms32010_program_bus.sv",
            ROOT / "rtl" / "wrappers" / "tms32010_sequential_pipeline_slice.sv",
            ROOT / "rtl" / "wrappers" / "tms32010_mister.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_bus_decode.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_program_ram.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_address_control.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_communication_ram.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_communication_path.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_rom_path.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_dac_latch.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_320_port_latch.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_output_control.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_bio_generator.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_host_control.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_mc68000_write_word.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_mailboxes.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_read_status.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_switches.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_host_read_mux.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_host_timing.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_local_memory_decode.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_local_memory_bridge.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_direct_io.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_local_ram.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_local_reset_interlock.sv",
            ROOT / "rtl" / "wrappers" / "hard_drivin_sound_mister.sv",
            ROOT / "sim" / "bus" / f"{name}.sv",
        ]
        result = subprocess.run(
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
