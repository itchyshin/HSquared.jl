"""Execution-scope fences shared by CLI and durable attempt store."""
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from argparse import Namespace
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "sim" / "arc1"))
import runner
import run_cell


class ExecutionScopeTests(unittest.TestCase):
    def test_unscoped_admissions_keep_their_existing_partition(self):
        runner.validate_execution_scope({"planned_attempts": 60}, 60)

    def test_declared_scope_accepts_only_its_exact_outer_indices(self):
        admission = {"execution_scope": {"run_kind": "measured_pre_run",
                                          "allowed_outer_indices": [31],
                                          "case_count": 1, "full_tranche": False}}
        runner.validate_execution_scope(admission, 31)
        with self.assertRaisesRegex(ValueError, "outside the admitted execution_scope"):
            runner.validate_execution_scope(admission, 30)
        with self.assertRaisesRegex(ValueError, "outside the admitted execution_scope"):
            runner.validate_execution_scope(admission, 32)
        with self.assertRaisesRegex(ValueError, "outside the admitted execution_scope"):
            runner.validate_execution_scope(admission, True)

    def test_cli_enforces_scope_before_julia_or_output_work(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            admission_path = root / "admission.json"
            admission_path.write_text(json.dumps({"execution_scope": {
                "run_kind": "measured_pre_run", "allowed_outer_indices": [31],
                "case_count": 1, "full_tranche": False}}), encoding="utf-8")
            args = Namespace(source_root=root / "source", output_root=root / "output",
                             admission=admission_path, julia="missing-julia", outer=32)
            with self.assertRaisesRegex(ValueError, "outside the admitted execution_scope"):
                run_cell.execute_cli(args)
            self.assertFalse((root / "output").exists())

    def test_attempt_store_enforces_scope_before_manifest_or_disk_work(self):
        store = object.__new__(runner.Arc1AttemptStore)
        store.admission = {"execution_scope": {"run_kind": "measured_pre_run",
                                                "allowed_outer_indices": [31],
                                                "case_count": 1, "full_tranche": False}}
        with self.assertRaisesRegex(ValueError, "outside the admitted execution_scope"):
            store.begin(32)

    def test_invalid_scope_fails_closed(self):
        invalid = [
            {"run_kind": "measured_pre_run", "allowed_outer_indices": [], "case_count": 0, "full_tranche": False},
            {"run_kind": "measured_pre_run", "allowed_outer_indices": [31, 31], "case_count": 2, "full_tranche": False},
            {"run_kind": "measured_pre_run", "allowed_outer_indices": [True], "case_count": 1, "full_tranche": False},
            {"run_kind": "measured_pre_run", "allowed_outer_indices": [0], "case_count": 1, "full_tranche": False},
            {"run_kind": "measured_pre_run", "allowed_outer_indices": [31], "case_count": 2, "full_tranche": False},
            {"run_kind": "measured_pre_run", "allowed_outer_indices": [31], "case_count": 1, "full_tranche": False, "extra": "x"},
        ]
        for scope in invalid:
            with self.subTest(scope=scope), self.assertRaises(ValueError):
                runner.validate_execution_scope({"execution_scope": scope}, 31)


if __name__ == "__main__":
    unittest.main()
