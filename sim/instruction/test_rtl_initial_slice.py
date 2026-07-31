from __future__ import annotations

import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = ROOT / "rtl" / "packages" / "tms32010_pkg.sv"
DECODE = ROOT / "rtl" / "core" / "tms32010_decode.sv"
CORE = ROOT / "rtl" / "core" / "tms32010_core.sv"
INTERNAL_RAM = ROOT / "rtl" / "core" / "tms32010_internal_ram.sv"
MULTIPLIER = ROOT / "rtl" / "core" / "tms32010_multiplier.sv"


class RtlInitialSliceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.verilator = shutil.which("verilator")
        if cls.verilator is None:
            raise RuntimeError("Verilator is required once architectural RTL exists")

    def _run_testbench(self, name: str, sources: list[Path]) -> None:
        build = ROOT / "build" / "verilator" / name
        build.mkdir(parents=True, exist_ok=True)
        sources = list(sources)
        if CORE in sources and MULTIPLIER not in sources:
            sources.insert(sources.index(CORE), MULTIPLIER)
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
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_initial_rtl_slice.sv",
            ],
        )

    def test_lac_data_address_shift_and_counter_behavior(self) -> None:
        self._run_testbench(
            "tb_lac_rtl",
            [
                PACKAGE,
                DECODE,
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_lac_rtl.sv",
            ],
        )

    def test_lar_target_and_counter_ordering(self) -> None:
        self._run_testbench(
            "tb_lar_rtl",
            [
                PACKAGE,
                DECODE,
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_lar_rtl.sv",
            ],
        )

    def test_sar_store_value_and_counter_ordering(self) -> None:
        self._run_testbench(
            "tb_sar_rtl",
            [
                PACKAGE,
                DECODE,
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_sar_rtl.sv",
            ],
        )

    def test_mar_counter_and_pointer_behavior_without_memory_access(self) -> None:
        self._run_testbench(
            "tb_mar_rtl",
            [
                PACKAGE,
                DECODE,
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_mar_rtl.sv",
            ],
        )

    def test_ldp_source_bit_address_and_counter_behavior(self) -> None:
        self._run_testbench(
            "tb_ldp_rtl",
            [
                PACKAGE,
                DECODE,
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_ldp_rtl.sv",
            ],
        )

    def test_lt_full_word_address_and_counter_behavior(self) -> None:
        self._run_testbench(
            "tb_lt_rtl",
            [
                PACKAGE,
                DECODE,
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_lt_rtl.sv",
            ],
        )

    def test_mpy_signed_product_address_and_counter_behavior(self) -> None:
        self._run_testbench(
            "tb_mpy_rtl",
            [
                PACKAGE,
                DECODE,
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_mpy_rtl.sv",
            ],
        )

    def test_mpyk_signed_immediate_product_and_no_data_access(self) -> None:
        self._run_testbench(
            "tb_mpyk_rtl",
            [
                PACKAGE,
                DECODE,
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_mpyk_rtl.sv",
            ],
        )

    def test_sacl_data_write_and_counter_behavior(self) -> None:
        self._run_testbench(
            "tb_sacl_rtl",
            [
                PACKAGE,
                DECODE,
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_sacl_rtl.sv",
            ],
        )

    def test_sach_output_shifts_and_counter_behavior(self) -> None:
        self._run_testbench(
            "tb_sach_rtl",
            [
                PACKAGE,
                DECODE,
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_sach_rtl.sv",
            ],
        )

    def test_zero_load_transfers_and_counter_behavior(self) -> None:
        self._run_testbench(
            "tb_zero_loads_rtl",
            [
                PACKAGE,
                DECODE,
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_zero_loads_rtl.sv",
            ],
        )

    def test_adds_arithmetic_status_and_counter_behavior(self) -> None:
        self._run_testbench(
            "tb_adds_rtl",
            [
                PACKAGE,
                DECODE,
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_adds_rtl.sv",
            ],
        )

    def test_add_shift_overflow_and_counter_behavior(self) -> None:
        self._run_testbench(
            "tb_add_rtl",
            [
                PACKAGE,
                DECODE,
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_add_rtl.sv",
            ],
        )

    def test_sub_shift_overflow_and_counter_behavior(self) -> None:
        self._run_testbench(
            "tb_sub_rtl",
            [
                PACKAGE,
                DECODE,
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_sub_rtl.sv",
            ],
        )

    def test_subs_unsigned_source_overflow_and_counter_behavior(self) -> None:
        self._run_testbench(
            "tb_subs_rtl",
            [
                PACKAGE,
                DECODE,
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_subs_rtl.sv",
            ],
        )

    def test_logic_halves_status_and_counter_behavior(self) -> None:
        self._run_testbench(
            "tb_logic_rtl",
            [
                PACKAGE,
                DECODE,
                INTERNAL_RAM,
                CORE,
                ROOT / "sim" / "instruction" / "tb_logic_rtl.sv",
            ],
        )


if __name__ == "__main__":
    unittest.main()
