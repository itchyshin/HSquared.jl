"""No-fit controls for the temporary Arc 1 execution pause."""
import argparse
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "sim/arc1"))
sys.path.insert(0, str(ROOT / "tools"))
import runner
import run_cell
import run_diagnostic_cells as diagnostic
import run_pilot_cells as pilot


class LaunchRefusalTests(unittest.TestCase):
    def test_runner_denies_before_begin_or_executor(self):
        store = mock.Mock()
        store._executing = set()
        executor = mock.Mock()
        with self.assertRaisesRegex(PermissionError, "attempt.*record"):
            runner.execute_one(store, 1, executor)
        store.begin.assert_not_called()
        executor.assert_not_called()

    def test_cell_denies_before_version_or_output(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "source"
            source.mkdir()
            admission = root / "admission.json"
            admission.write_text(json.dumps({}), encoding="utf-8")
            output = root / "output"
            args = argparse.Namespace(source_root=source, output_root=output,
                                      admission=admission, outer=1, julia="julia")
            with mock.patch.object(run_cell, "_julia_version") as version:
                with self.assertRaisesRegex(PermissionError, "attempt.*record"):
                    run_cell.execute_cli(args)
                version.assert_not_called()
            self.assertFalse(output.exists())

    def test_diagnostic_denies_before_validation_or_output(self):
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "output"
            plan = {"admission": {"execution_authorized": True}, "output_root": output}
            with mock.patch.object(diagnostic, "_revalidate_plan") as validate:
                with self.assertRaisesRegex(PermissionError, "attempt.*record"):
                    diagnostic.execute_plan(plan)
                validate.assert_not_called()
            self.assertFalse(output.exists())

    def test_diagnostic_direct_worker_denies_before_write(self):
        with mock.patch.object(diagnostic, "_revalidate_plan") as validate, \
             mock.patch.object(diagnostic, "_write_result") as write:
            with self.assertRaisesRegex(PermissionError, "attempt.*record"):
                diagnostic._launch_one({}, {})
            validate.assert_not_called()
            write.assert_not_called()

    def test_pilot_denies_before_dispatch(self):
        with mock.patch.object(pilot, "execution_authorized", return_value=True), \
             mock.patch.object(pilot.concurrent.futures, "ThreadPoolExecutor") as pool:
            with self.assertRaisesRegex(PermissionError, "attempt.*record"):
                pilot.execute_plan({}, authorization={})
            pool.assert_not_called()

    def test_pilot_direct_worker_denies_before_write(self):
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "output"
            with mock.patch.object(pilot, "_atomic_json") as write:
                with self.assertRaisesRegex(PermissionError, "attempt.*record"):
                    pilot._execute_cell({}, source_root=Path(temporary), julia="julia",
                                        output_root=output, timeout=1, plan_sha256="x",
                                        batch_sha256="x", launcher_sha256="x")
                write.assert_not_called()
            self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
