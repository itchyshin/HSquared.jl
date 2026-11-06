"""Pure launcher tests; these never admit or execute a study cell."""
from __future__ import annotations

import json
import os
import signal
import subprocess
import sys
import threading
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "sim" / "arc1"))
import run_cell


class ExecutorTransportTests(unittest.TestCase):
    def test_cleanup_kills_descendant_after_group_leader_exits(self):
        script = (
            "import subprocess,sys; "
            "subprocess.Popen([sys.executable,'-c','import time; time.sleep(30)'], "
            "stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)"
        )
        leader = subprocess.Popen([sys.executable, "-c", script], start_new_session=True)
        try:
            leader.wait(timeout=3)
            self.assertIsNotNone(leader.poll())
            run_cell._stop_process_group(leader, grace_seconds=0.2)

            deadline = time.monotonic() + 1.0
            while True:
                try:
                    os.killpg(leader.pid, 0)
                    group_exists = True
                except ProcessLookupError:
                    group_exists = False
                except PermissionError:
                    group_exists = True
                if not group_exists or time.monotonic() >= deadline:
                    break
                time.sleep(0.01)
            self.assertFalse(group_exists, "descendant survived cleanup after its group leader exited")
        finally:
            try:
                os.killpg(leader.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass

    def test_child_profile_method_is_crossbound_without_relabeling_returned_results(self):
        returned = {"schema": "arc1-attempt-result-v1",
                    "requested_profile_method_version": "arc1_profile_v3"}
        run_cell._check_returned_attempt_identity(returned, 1, 11, "arc1_profile_v3")
        with self.assertRaisesRegex(ValueError, "different requested profile method"):
            run_cell._check_returned_attempt_identity({"schema": "arc1-attempt-result-v1",
                "requested_profile_method_version": "arc1_profile_v2"}, 1, 11, "arc1_profile_v3")
        pre_engine = {"status": "error", "success": False}
        run_cell._check_returned_attempt_identity(pre_engine, 1, 11, "arc1_profile_v3")
        self.assertEqual(pre_engine["requested_profile_method_version"], "arc1_profile_v3")
        with self.assertRaisesRegex(ValueError, "different requested profile method"):
            run_cell._check_returned_attempt_identity({"status": "error",
                "requested_profile_method_version": "arc1_profile_v2"}, 1, 11, "arc1_profile_v3")
        # A historical v2 request remains a valid explicit identity; it is never relabelled v3.
        run_cell._check_returned_attempt_identity({"schema": "arc1-attempt-result-v1",
            "requested_profile_method_version": "arc1_profile_v2"}, 1, 11, "arc1_profile_v2")

    def test_toml_input_preserves_large_seed_as_exact_string(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            admission = {
                "source_sha256": {"src/HSquared.jl": "a" * 64},
                "environment_sha256": {"Project.toml": "b" * 64,
                                       "Manifest.toml": "c" * 64},
                "profile_method_version": "arc1_profile_v3",
                "protocol_sha256": "d" * 64,
            }
            path = base / "attempt.input.toml"
            run_cell._toml_input(
                path, mode="engineering_probe", source_root=base,
                attempt_output=base / "out", artifact_path=base / "out/full.jls",
                cell={"programme": "repeatability", "phase": "engineering_probe",
                      "N": 16, "signal": "weak"}, outer=1,
                seed=2**64 - 1, bootstrap_seeds=[2**64 - 1],
                admission=admission, blas_threads=1,
            )
            text = path.read_text(encoding="utf-8")
            self.assertIn('seed = "18446744073709551615"', text)
            self.assertIn('bootstrap_seeds = ["18446744073709551615"]', text)
            self.assertIn('mode = "engineering_probe"', text)
            self.assertIn('profile_method_version = "arc1_profile_v3"', text)
            self.assertIn('"src/HSquared.jl" = "' + "a" * 64 + '"', text)
            with self.assertRaises(FileExistsError):
                run_cell._toml_input(
                    path, mode="engineering_probe", source_root=base,
                    attempt_output=base / "out", artifact_path=base / "out/full.jls",
                    cell={"programme": "repeatability", "phase": "engineering_probe",
                          "N": 16, "signal": "weak"}, outer=1,
                    seed=1, bootstrap_seeds=[], admission=admission, blas_threads=1,
                )

    def test_launcher_accepts_only_final_typed_result_and_retains_log(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            log = root / "attempt.log"
            payload = {"schema": "arc1-attempt-result-v1", "success": True,
                       "status": "ok", "seed_string": "18446744073709551615"}
            command = [sys.executable, "-c",
                       "import json; print(json.dumps(" + repr(payload) + "))"]
            result = run_cell.launch_julia_attempt(
                command, env=dict(os.environ), timeout_seconds=10, log_path=log)
            self.assertTrue(result["success"])
            self.assertEqual(result["seed_string"], "18446744073709551615")
            self.assertTrue(log.is_file())
            self.assertIn("arc1-attempt-result-v1", log.read_text(encoding="utf-8"))

    def test_timeout_kills_owned_process_group_and_keeps_log(self):
        with tempfile.TemporaryDirectory() as directory:
            log = Path(directory) / "timeout.log"
            command = [sys.executable, "-c", "import time; time.sleep(30)"]
            result = run_cell.launch_julia_attempt(
                command, env=dict(os.environ), timeout_seconds=0.2, log_path=log)
            self.assertFalse(result["success"])
            self.assertEqual(result["status"], "timeout")
            self.assertIsNotNone(result["child_exit_code"])
            self.assertTrue(log.is_file())

    def test_sigterm_is_forwarded_to_owned_child_and_handler_restored(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            log = root / "signal.log"
            pid_path = root / "child.pid"
            command = [sys.executable, "-c",
                       "import os,time; open(" + repr(str(pid_path)) + ", 'w').write(str(os.getpid())); time.sleep(30)"]
            old_handler = signal.getsignal(signal.SIGTERM)
            timer = threading.Timer(0.2, lambda: os.kill(os.getpid(), signal.SIGTERM))
            timer.start()
            try:
                result = run_cell.launch_julia_attempt(
                    command, env=dict(os.environ), timeout_seconds=10, log_path=log)
            finally:
                timer.cancel()
            self.assertEqual(result["status"], "interrupted")
            self.assertEqual(result["signal"], signal.SIGTERM)
            self.assertIsNotNone(result["child_exit_code"])
            self.assertEqual(signal.getsignal(signal.SIGTERM), old_handler)
            child_pid = int(pid_path.read_text(encoding="utf-8"))
            with self.assertRaises(ProcessLookupError):
                os.kill(child_pid, 0)
            self.assertTrue(log.is_file())


if __name__ == "__main__":
    unittest.main()
