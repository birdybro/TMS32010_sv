from __future__ import annotations

import ast
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
CAPTURE_MODULES = (
    "push_pop_capture.py",
    "simultaneous_ar_capture.py",
    "lst_arp_capture.py",
    "subc_capture.py",
    "dint_interrupt_capture.py",
    "ram_boundary_capture.py",
    "ram_invalid_read_capture.py",
    "ram_invalid_write_capture.py",
    "reset_retention_capture.py",
)


class SpecimenContractTests(unittest.TestCase):
    def test_all_physical_classifiers_share_the_fail_closed_boundary(self) -> None:
        for filename in CAPTURE_MODULES:
            with self.subTest(filename=filename):
                path = ROOT / "tools" / "trace" / filename
                tree = ast.parse(path.read_text(encoding="utf-8"), filename=filename)
                calls_shared_validator = any(
                    isinstance(node, ast.Call)
                    and isinstance(node.func, ast.Name)
                    and node.func.id == "validate_specimen_evidence"
                    for node in ast.walk(tree)
                )
                keeps_acceptance_open = any(
                    isinstance(node, ast.keyword)
                    and node.arg == "acceptance_complete"
                    and isinstance(node.value, ast.Constant)
                    and node.value.value is False
                    for node in ast.walk(tree)
                )
                function_names = {
                    node.name
                    for node in ast.walk(tree)
                    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
                }
                self.assertTrue(calls_shared_validator)
                self.assertTrue(keeps_acceptance_open)
                self.assertNotIn("_validate_fixture_listing", function_names)


if __name__ == "__main__":
    unittest.main()
