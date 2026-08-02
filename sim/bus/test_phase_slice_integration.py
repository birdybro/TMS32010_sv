from __future__ import annotations

import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class PhaseSliceIntegrationTests(unittest.TestCase):
    def _run_testbench(self, name: str) -> None:
        verilator = shutil.which("verilator")
        if verilator is None:
            raise RuntimeError("Verilator is required once architectural RTL exists")
        build = ROOT / "build" / "verilator" / name
        build.mkdir(parents=True, exist_ok=True)
        testbench = ROOT / "sim" / "bus" / f"{name}.sv"
        if not testbench.exists():
            testbench = ROOT / "sim" / "interrupt" / f"{name}.sv"
        sources = [
            ROOT / "rtl" / "packages" / "tms32010_pkg.sv",
            ROOT / "rtl" / "core" / "tms32010_decode.sv",
            ROOT / "rtl" / "core" / "tms32010_internal_ram.sv",
            ROOT / "rtl" / "core" / "tms32010_multiplier.sv",
            ROOT / "rtl" / "core" / "tms32010_input_shifter.sv",
            ROOT / "rtl" / "core" / "tms32010_output_shifter.sv",
            ROOT / "rtl" / "core" / "tms32010_auxiliary_counter.sv",
            ROOT / "rtl" / "core" / "tms32010_status_word.sv",
            ROOT / "rtl" / "core" / "tms32010_stack.sv",
            ROOT / "rtl" / "core" / "tms32010_accumulator.sv",
            ROOT / "rtl" / "core" / "tms32010_fetch_execute.sv",
            ROOT / "rtl" / "core" / "tms32010_core.sv",
            ROOT / "rtl" / "core" / "tms32010_program_bus.sv",
            ROOT / "rtl" / "wrappers" / "tms32010_phase_slice.sv",
            ROOT / "rtl" / "wrappers" / "tms32010_sequential_pipeline_slice.sv",
            ROOT / "rtl" / "wrappers" / "tms32010_mister.sv",
            testbench,
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

    def test_native_samples_drive_sequential_execution_slice(self) -> None:
        self._run_testbench("tb_phase_slice_integration")

    def test_fetch_primes_before_sequential_one_cycle_execution(self) -> None:
        self._run_testbench("tb_sequential_pipeline_slice")

    def test_b_retains_execute_ownership_through_target_fetch(self) -> None:
        self._run_testbench("tb_sequential_pipeline_b")

    def test_banz_selects_target_or_fallthrough_before_decrement(self) -> None:
        self._run_testbench("tb_sequential_pipeline_banz")

    def test_accumulator_branches_select_before_retirement(self) -> None:
        self._run_testbench("tb_sequential_pipeline_accumulator_branches")

    def test_bv_clears_overflow_only_at_taken_retirement(self) -> None:
        self._run_testbench("tb_sequential_pipeline_bv")

    def test_bioz_samples_live_pin_before_selected_fetch(self) -> None:
        self._run_testbench("tb_sequential_pipeline_bioz")

    def test_call_pushes_only_when_selected_fetch_completes(self) -> None:
        self._run_testbench("tb_sequential_pipeline_call")

    def test_cala_ret_discard_sequential_prefetch_before_target(self) -> None:
        self._run_testbench("tb_sequential_pipeline_cala_ret")

    def test_io_transfer_precedes_following_instruction_prefetch(self) -> None:
        self._run_testbench("tb_sequential_pipeline_io")

    def test_interrupt_discards_dummy_and_captures_vector(self) -> None:
        self._run_testbench("tb_sequential_pipeline_interrupt")

    def test_multiply_extends_explicit_interrupt_protection(self) -> None:
        self._run_testbench("tb_sequential_pipeline_interrupt_multiply")

    def test_multicycle_arrivals_preserve_explicit_interrupt_ownership(
        self,
    ) -> None:
        self._run_testbench("tb_sequential_pipeline_interrupt_multicycle")

    def test_one_cycle_arrivals_preserve_explicit_interrupt_ownership(
        self,
    ) -> None:
        self._run_testbench("tb_sequential_pipeline_interrupt_one_cycle")

    def test_mask_controls_preserve_explicit_interrupt_ownership(self) -> None:
        self._run_testbench("tb_sequential_pipeline_interrupt_mask_controls")

    def test_computed_control_arrivals_defer_until_target_capture(self) -> None:
        self._run_testbench("tb_sequential_pipeline_interrupt_computed")

    def test_table_transfer_repeats_following_prefetch(self) -> None:
        self._run_testbench("tb_sequential_pipeline_table")

    def test_qualified_one_cycle_stream_matches_at_pipeline_offset(self) -> None:
        self._run_testbench("tb_sequential_pipeline_differential")

    def test_banz_uses_two_stallable_native_program_reads(self) -> None:
        self._run_testbench("tb_banz_phase")

    def test_b_uses_two_stallable_native_program_reads(self) -> None:
        self._run_testbench("tb_b_phase")

    def test_bv_uses_two_stallable_native_program_reads(self) -> None:
        self._run_testbench("tb_bv_phase")

    def test_bioz_samples_live_pin_on_second_native_read(self) -> None:
        self._run_testbench("tb_bioz_phase")

    def test_call_pushes_on_the_second_native_program_read(self) -> None:
        self._run_testbench("tb_call_phase")

    def test_io_uses_distinct_two_cycle_den_and_we_waveforms(self) -> None:
        self._run_testbench("tb_io_phase")

    def test_table_transfers_repeat_prefetch_and_use_men_or_we(self) -> None:
        self._run_testbench("tb_table_transfer_phase")

    def test_phase_pauses_preserve_all_external_transaction_classes(
        self,
    ) -> None:
        self._run_testbench("tb_wait_states")

    def test_mister_callbacks_reset_and_synchronous_waits(self) -> None:
        self._run_testbench("tb_mister_wrapper")

    def test_accumulator_branches_use_two_stallable_native_reads(self) -> None:
        self._run_testbench("tb_accumulator_branches_phase")


if __name__ == "__main__":
    unittest.main()
