"""Pure-Python negative and refusal tests for the Arc 1 diagnostic launcher."""
from __future__ import annotations

import hashlib
import importlib.util
import json
import os
import signal
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path
from typing import Any

LAUNCHER = Path(__file__).resolve().parents[1] / "sim/arc1/run_diagnostic_cells.py"
SPEC = importlib.util.spec_from_file_location("arc1_diagnostic_launcher", LAUNCHER)
assert SPEC and SPEC.loader
launcher = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(launcher)


def digest(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def canonical_hash(value: Any) -> str:
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":"),
                                   ensure_ascii=False, allow_nan=False).encode()).hexdigest()


class DiagnosticLauncherTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.previous_reservation_root = launcher.RESERVATION_ROOT
        launcher.RESERVATION_ROOT = (self.base / "central-ledger").resolve()
        self.root = self.base / "julia-source"
        self.root.mkdir()
        self.reservations = self.base / "central-ledger"
        self.reservations.mkdir()
        self._write_source_tree()
        self.admission_path = self._write_bundle(self.base / "bundle")

    def tearDown(self):
        launcher.RESERVATION_ROOT = self.previous_reservation_root
        self.temp.cleanup()

    def _write_source_tree(self):
        names = sorted(launcher.REQUIRED_NATIVE_FILES)
        entries = []
        for index, rel in enumerate(names):
            path = self.root / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            if rel == "tools/arc1_manifest.py":
                raw = b"def contract_sha256():\n    return '" + b"a" * 64 + b"'\n"
            else:
                raw = f"pinned test source {index}\n".encode()
            path.write_bytes(raw)
            entries.append({"path": str(path.resolve()), "sha256": digest(raw)})
        self.source_map = {"schema": "test-source-map-v1", "root": str(self.root.resolve()),
                           "files": entries}

    @staticmethod
    def _seed(cell: dict[str, Any]) -> int:
        amendment_hash = digest(b"approved diagnostic amendment fixture\n")
        label = "/".join((launcher.AMENDMENT_ID, amendment_hash, cell["programme"],
                          cell["phase"], str(cell["N"]), cell["signal"], "outer=1"))
        return int.from_bytes(hashlib.sha256(label.encode()).digest()[:8], "big")

    def _write_bundle(self, bundle: Path, *, rows: list[dict[str, Any]] | None = None,
                      run_kind: str = "diagnostic_only", output_name: str = "out",
                      estimate_seconds: float = 60) -> Path:
        bundle.mkdir(parents=True, exist_ok=True)
        amendment = bundle / "amendment.md"
        amendment.write_text("approved diagnostic amendment fixture\n", encoding="utf-8")
        generator = bundle / "seed_generator.py"
        generator.write_text("# deterministic test generator pin\n", encoding="utf-8")
        allocation = bundle / "allocation.csv"
        allocation.write_text("programme,phase,seed\nfa_rank,development,19\nfa_rank,pilot,20\nfa_rank,confirmation,21\n", encoding="utf-8")
        source_map_path = bundle / "source-map.json"
        source_map_bytes = json.dumps(self.source_map, sort_keys=True, indent=2).encode() + b"\n"
        source_map_path.write_bytes(source_map_bytes)

        entries = []
        for item in self.source_map["files"]:
            source = Path(item["path"])
            entries.append({"path": str(source.resolve()), "bytes": source.stat().st_size,
                            "sha256": digest(source.read_bytes())})
        amendment_hash = digest(amendment.read_bytes())
        seed_rows = rows or [
            {"cell": dict(cell), "outer": 1, "seed": self._seed(cell),
             "namespace": launcher.AMENDMENT_ID}
            for i, cell in enumerate(launcher.CELLS)
        ]
        inventory = {"schema": "arc1-diagnostic-history-inventory-v1", "records": [
                         {"path": str(allocation.resolve()),
                          "role": "allocation", "status": "parsed", "seed_count": 3,
                          "seed_records": [{"seed": seed, "record": f"row:{i}", "consumed": True}
                                           for i, seed in enumerate((19, 20, 21), start=2)],
                          "sha256": digest(allocation.read_bytes())}],
                     "missing_or_unavailable": [],
                     "scope_statement": "Only explicitly supplied fixture records were inspected.",
                     "exhaustive_history_claim": False}
        inventory["inventory_sha256"] = canonical_hash(inventory)
        report = {
            "schema": launcher.HISTORY_SCHEMA,
            "status": "candidate_scoped_collision_check_passed",
            "amendment": {"id": launcher.AMENDMENT_ID, "path": str(amendment.resolve()),
                          "sha256": digest(amendment.read_bytes())},
            "source_map": {"path": str(source_map_path.resolve()), "root": str(self.root.resolve()),
                           "sha256": digest(source_map_path.read_bytes()), "files": entries,
                           "canonical_sha256": canonical_hash(entries)},
            "seed_generator": {"path": str(generator.resolve()), "sha256": digest(generator.read_bytes())},
            "seed_generator_sha256": digest(generator.read_bytes()),
            "history_inventory": inventory,
            "history_scope": {"claim": "no_collision_among_extracted_seeds_pending_review",
                              "exhaustive": False, "independent_review_required": True,
                              "unreadable_count": 0, "unparsed_count": 0,
                              "missing_or_unavailable_count": 0},
            "diagnostic_seeds": seed_rows,
            "diagnostic_seed_sha256": canonical_hash(seed_rows),
            "consumed_seed_count_in_supplied_scope": 3, "collisions": [],
            "execution_authorized": False,
            "pilot_or_confirmation_authorized": False, "gate_credit": False,
        }
        report["report_sha256"] = canonical_hash(report)
        report_path = bundle / "history-report.json"
        report_path.write_text(json.dumps(report, sort_keys=True, indent=2) + "\n", encoding="utf-8")

        julia = bundle / "julia"
        julia.write_text("test double; never executed\n", encoding="utf-8")
        julia.chmod(0o755)
        library = bundle / "libjulia.so"
        library.write_bytes(b"test runtime library pin\n")
        runtime_files = [
            {"path": str(julia.resolve()), "role": "executable", "sha256": digest(julia.read_bytes())},
            {"path": str(library.resolve()), "role": "library", "sha256": digest(library.read_bytes())},
        ]
        runtime_inventory_sha256 = canonical_hash(sorted(runtime_files, key=lambda x: x["path"]))
        admission = {
            "schema": launcher.SCHEMA,
            "amendment_id": launcher.AMENDMENT_ID,
            "amendment_path": str(amendment.resolve()),
            "amendment_sha256": digest(amendment.read_bytes()),
            "source_map_path": str(source_map_path.resolve()),
            "source_map_sha256": digest(source_map_path.read_bytes()),
            "source_map_canonical_sha256": canonical_hash(entries),
            "history_report_path": str(report_path.resolve()),
            "history_report_sha256": digest(report_path.read_bytes()),
            "source_root": str(self.root.resolve()),
            "output_root": str((bundle / output_name).resolve()),
            "reservation_root": str(launcher.RESERVATION_ROOT),
            "julia": str(julia.resolve()), "julia_version": "1.10.0",
            "julia_sha256": digest(julia.read_bytes()), "runtime_files": runtime_files,
            "runtime_inventory_sha256": runtime_inventory_sha256,
            "launcher_path": str(LAUNCHER.resolve()), "launcher_sha256": digest(LAUNCHER.read_bytes()),
            "reference_schedule": "full_expanded_pilot_outer1_reference",
            "timeout_seconds": 120, "runtime_estimate_seconds": estimate_seconds,
            "concurrency": 4, "threads": {"julia": 1, "blas": 1},
            "run_kind": run_kind, "diagnostic_seed_sha256": canonical_hash(seed_rows),
            "history_inventory_sha256": inventory["inventory_sha256"],
            "seed_generator_sha256": digest(generator.read_bytes()),
            "julia_sha256": digest(julia.read_bytes()),
            "runtime_inventory_sha256": runtime_inventory_sha256,
            "launcher_sha256": digest(LAUNCHER.read_bytes()),
            "runtime_estimate_seconds": estimate_seconds, "timeout_seconds": 120,
            "output_root": str((bundle / output_name).resolve()),
            "reference_schedule": "full_expanded_pilot_outer1_reference",
            "execution_authorized": True,
            "pilot_or_confirmation_authorized": False, "gate_credit": False,
            "protocol_sha256": "a" * 64,
        }
        receipt = {
            "schema": "arc1-diagnostic-execution-review-v1", "status": "reviewed",
            "reviewer": "independent-reviewer", "reviewed_at_utc": "2026-10-24T00:00:00Z",
            "admission_core_sha256": canonical_hash(admission),
            "amendment_sha256": admission["amendment_sha256"],
            "source_map_sha256": admission["source_map_sha256"],
            "history_report_sha256": admission["history_report_sha256"],
            "diagnostic_seed_sha256": admission["diagnostic_seed_sha256"],
            "history_inventory_sha256": admission["history_inventory_sha256"],
            "seed_generator_sha256": admission["seed_generator_sha256"],
            "julia_sha256": admission["julia_sha256"],
            "runtime_inventory_sha256": admission["runtime_inventory_sha256"],
            "launcher_sha256": admission["launcher_sha256"],
            "runtime_estimate_seconds": admission["runtime_estimate_seconds"],
            "timeout_seconds": admission["timeout_seconds"],
            "output_root": admission["output_root"],
            "reference_schedule": admission["reference_schedule"],
        }
        receipt_path = bundle / "review.json"
        receipt_path.write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n", encoding="utf-8")
        admission["review_receipt"] = {"path": str(receipt_path.resolve()),
                                       "sha256": digest(receipt_path.read_bytes())}
        admission_path = bundle / "admission.json"
        admission_path.write_text(json.dumps(admission, sort_keys=True, indent=2) + "\n", encoding="utf-8")
        return admission_path

    def test_plan_is_eight_exact_jobs_and_writes_nothing(self):
        plan = launcher.build_plan(self.admission_path)
        self.assertEqual(len(plan["jobs"]), 8)
        self.assertEqual([job["cell"] for job in plan["jobs"]], launcher.CELLS)
        self.assertTrue(all(job["outer"] == 1 for job in plan["jobs"]))
        self.assertEqual(plan["admission"]["threads"], {"julia": 1, "blas": 1})
        self.assertEqual(plan["concurrency"], 4)
        self.assertFalse(plan["output_root"].exists())

    def test_source_drift_refuses_before_reservation(self):
        source = Path(self.source_map["files"][0]["path"])
        source.write_text("altered after source freeze\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "source drift"):
            launcher.build_plan(self.admission_path)
        self.assertEqual(list(self.reservations.glob("seed-*.json")), [])

    def test_changed_review_receipt_refuses(self):
        admission = json.loads(self.admission_path.read_text())
        receipt = Path(admission["review_receipt"]["path"])
        receipt.write_text("{}\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "review receipt bytes changed"):
            launcher.build_plan(self.admission_path)

    def test_duplicate_cells_refuse_even_when_report_is_resigned(self):
        rows = [{"cell": dict(cell), "outer": 1, "seed": self._seed(cell),
                 "namespace": launcher.AMENDMENT_ID} for i, cell in enumerate(launcher.CELLS)]
        rows[1]["cell"] = dict(rows[0]["cell"])
        path = self._write_bundle(self.base / "duplicate", rows=rows)
        with self.assertRaisesRegex(ValueError, "exact eight-cell schedule"):
            launcher.build_plan(path)

    def test_excess_attempts_refuse(self):
        rows = [{"cell": dict(cell), "outer": 1, "seed": self._seed(cell),
                 "namespace": launcher.AMENDMENT_ID} for i, cell in enumerate(launcher.CELLS)]
        rows.append({"cell": dict(launcher.CELLS[-1]), "outer": 2, "seed": 73000,
                     "namespace": launcher.AMENDMENT_ID})
        path = self._write_bundle(self.base / "excess", rows=rows)
        with self.assertRaisesRegex(ValueError, "exactly eight seeds"):
            launcher.build_plan(path)

    def test_pilot_route_is_refused(self):
        path = self._write_bundle(self.base / "pilot", run_kind="pilot")
        with self.assertRaisesRegex(ValueError, "refuses pilot/confirmation authority"):
            launcher.build_plan(path)

    def test_existing_output_root_refuses(self):
        plan = launcher.build_plan(self.admission_path)
        plan["output_root"].mkdir()
        with self.assertRaisesRegex(ValueError, "output root already exists"):
            launcher.build_plan(self.admission_path)

    def test_seed_reservation_prevents_alternate_output_retry(self):
        plan1 = launcher.build_plan(self.admission_path)
        second = self._write_bundle(self.base / "second", output_name="alternate-output")
        plan2 = launcher.build_plan(second)
        launcher.reserve_batch(plan1)
        with self.assertRaises(FileExistsError):
            launcher.reserve_batch(plan2)
        self.assertEqual(len(list(self.reservations.glob("seed-*.json"))), 8)

    def test_dispatch_failure_consumes_all_seeds_and_keeps_denominator(self):
        plan = launcher.build_plan(self.admission_path)

        def failed_spawn(*args, **kwargs):
            raise OSError("synthetic dispatch failure")

        results = launcher.execute_plan(plan, popen=failed_spawn, version_probe=lambda _path: "1.10.0")
        self.assertEqual(len(results), 8)
        self.assertTrue(all(row["status"] == "launcher_error" for row in results))
        self.assertEqual(len(list(self.reservations.glob("seed-*.json"))), 8)
        self.assertEqual(len(list(plan["output_root"].glob("fa_rank/pilot/N*/*/outer-0001.diagnostic-result.json"))), 8)
        with self.assertRaisesRegex(ValueError, "output root already exists"):
            launcher.build_plan(self.admission_path)

    def test_communicate_exception_kills_spawned_process_group(self):
        plan = launcher.build_plan(self.admission_path)
        pid_file = self.base / "grandchild.pid"
        script = ("import subprocess,sys,time; "
                  "p=subprocess.Popen([sys.executable,'-c','import time; time.sleep(60)']); "
                  f"open({str(pid_file)!r},'w').write(str(p.pid)); time.sleep(60)")
        spawned = {}
        spawn_lock = threading.Lock()

        class CommunicateFailure:
            def __init__(self, process):
                self.process = process
                self.pid = process.pid
                self.failed = False

            def poll(self):
                return self.process.poll()

            def wait(self, *args, **kwargs):
                return self.process.wait(*args, **kwargs)

            def communicate(self, *args, **kwargs):
                if not self.failed:
                    deadline = time.monotonic() + 5
                    while not pid_file.exists() and time.monotonic() < deadline:
                        time.sleep(0.01)
                    if not pid_file.exists():
                        raise AssertionError("test process did not start its child")
                    self.failed = True
                    raise RuntimeError("synthetic communicate failure")
                return self.process.communicate(*args, **kwargs)

            def __getattr__(self, name):
                return getattr(self.process, name)

        def spawn(_command, **kwargs):
            with spawn_lock:
                if "process" in spawned:
                    raise OSError("synthetic stop after the process-group cleanup case")
                process = subprocess.Popen([sys.executable, "-c", script], **kwargs)
                spawned["process"] = process
                return CommunicateFailure(process)

        def pinned_version(_path):
            return "1.10.0"

        results = launcher.execute_plan(plan, popen=spawn, version_probe=pinned_version)
        exceptional = [row for row in results if row.get("failure_reason", "").find("synthetic communicate failure") >= 0]
        self.assertGreaterEqual(len(exceptional), 1)
        grandchild_pid = int(pid_file.read_text())
        self.assertFalse(launcher._group_exists(spawned["process"].pid))
        with self.assertRaises(ProcessLookupError):
            os.kill(grandchild_pid, 0)

    def test_runtime_estimate_timeout_kills_spawned_process_group(self):
        admission_path = self._write_bundle(self.base / "short-estimate", estimate_seconds=1)
        plan = launcher.build_plan(admission_path)
        script = "import time; time.sleep(60)"
        spawned = {}
        spawn_lock = threading.Lock()

        def spawn(_command, **kwargs):
            with spawn_lock:
                if "process" in spawned:
                    raise OSError("only the first slot launches in this timeout test")
                process = subprocess.Popen([sys.executable, "-c", script], **kwargs)
                spawned["process"] = process
                return process

        results = launcher.execute_plan(plan, popen=spawn, version_probe=lambda _path: "1.10.0")
        self.assertTrue(any(row["status"] == "runtime_estimate_exceeded" for row in results))
        self.assertFalse(launcher._group_exists(spawned["process"].pid))

    def test_sigterm_cancels_and_reaps_launched_process_group(self):
        plan = launcher.build_plan(self.admission_path)
        pid_file = self.base / "cancel-grandchild.pid"
        script = ("import subprocess,sys,time; "
                  "p=subprocess.Popen([sys.executable,'-c','import time; time.sleep(60)']); "
                  f"open({str(pid_file)!r},'w').write(str(p.pid)); time.sleep(60)")
        spawned = {}
        spawn_lock = threading.Lock()

        def spawn(_command, **kwargs):
            with spawn_lock:
                if "process" in spawned:
                    raise OSError("only one process is needed to check cancellation")
                process = subprocess.Popen([sys.executable, "-c", script], **kwargs)
                spawned["process"] = process
                return process

        def interrupt_when_ready():
            deadline = time.monotonic() + 5
            while not pid_file.exists() and time.monotonic() < deadline:
                time.sleep(0.01)
            if pid_file.exists():
                os.kill(os.getpid(), signal.SIGTERM)

        interrupter = threading.Thread(target=interrupt_when_ready, daemon=True)
        interrupter.start()
        results = launcher.execute_plan(plan, popen=spawn, version_probe=lambda _path: "1.10.0")
        interrupter.join(timeout=5)
        self.assertTrue(any(row["status"] == "interrupted" for row in results))
        self.assertFalse(launcher._group_exists(spawned["process"].pid))

    def test_review_receipt_without_approved_status_refuses(self):
        admission = json.loads(self.admission_path.read_text())
        receipt_path = Path(admission["review_receipt"]["path"])
        receipt = json.loads(receipt_path.read_text())
        receipt["status"] = "pending"
        receipt_path.write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n")
        admission["review_receipt"]["sha256"] = digest(receipt_path.read_bytes())
        self.admission_path.write_text(json.dumps(admission, sort_keys=True, indent=2) + "\n")
        with self.assertRaisesRegex(ValueError, "not approved"):
            launcher.build_plan(self.admission_path)


if __name__ == "__main__":
    unittest.main()
