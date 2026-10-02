"""Unit-only adversarial checks for Arc1 receipt integrity, not scientific gates."""
from __future__ import annotations

import copy
import hashlib
import json
import math
import multiprocessing
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "sim" / "arc1"))

import arc1_manifest
import arc1_receipt_check as checker
import runner as arc1_runner


def _overlapping_store_worker(source_root, output_dir, admission, result_queue):
    try:
        arc1_runner.Arc1AttemptStore(Path(source_root), Path(output_dir), admission,
                                     julia_version="1.10.0", julia_threads=4, blas_threads=1)
    except arc1_runner.StoreBusyError:
        result_queue.put("busy")
    else:
        result_queue.put("unexpectedly-acquired")


def _dead_owner_worker(source_root, output_dir, admission):
    store = arc1_runner.Arc1AttemptStore(Path(source_root), Path(output_dir), admission,
                                         julia_version="1.10.0", julia_threads=4, blas_threads=1)
    store.begin(2)
    os._exit(0)


def _copy_valid_source_tree(destination: Path) -> Path:
    source = ROOT
    for relative in ("Project.toml", "Manifest.toml", *arc1_manifest.discover_admission_source_paths(source)):
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source / relative, target)
    arc1_manifest.write_manifest(destination / "sim/arc1/manifests", audit_root=ROOT)
    return destination


SOURCE_HASHES = {"engine": "a" * 64, "driver": "b" * 64}
PROTOCOL_HASH = arc1_manifest.contract_sha256()
RANK_CELL = {"programme": "fa_rank", "phase": "development", "N": 80, "signal": "null"}
INTERVAL_CELL = {"programme": "fa_interval", "phase": "development", "N": 160, "signal": "null"}


def candidate(label: str, available: bool = True, raw: float = -10.0) -> dict:
    q = 14 if label == "K0" else 18
    penalty = 2 * q
    return {"parameter_count": q, "aic_penalty": penalty,
            "available": available, "status": "ok" if available else "fit_failed",
            "raw_loglik": raw if available else None,
            "score": -2 * raw + penalty if available else None,
            "error_reason": None if available else "optimizer_failed"}


def rank_receipt() -> tuple[dict, list[int]]:
    n = 30
    seeds = [arc1_manifest.seed_for(RANK_CELL["programme"], RANK_CELL["phase"],
                                   RANK_CELL["N"], RANK_CELL["signal"], i, 0, "data")
             for i in range(1, n + 1)]
    attempts = []
    for i, seed in enumerate(seeds, 1):
        k0 = candidate("K0", True, -10.0)
        k1 = candidate("K1", i != 2, -7.0)
        eligible = k0["available"] and k1["available"]
        attempts.append({"attempt_id": f"rank-{i:03d}", "outer": i, "seed": seed,
                         "status": "ok" if eligible else "candidate_failure",
                         "success": eligible,
                         "failure_reason": None if eligible else "K1 optimizer failed",
                         "eligible": eligible, "selected_rank": "K0" if eligible else None,
                         "rank_candidates": {"K0": k0, "K1": k1}})
    receipt = {"schema": "arc1-attempt-receipt-v1", **RANK_CELL,
               "protocol_sha256": PROTOCOL_HASH, "source_hashes": dict(SOURCE_HASHES),
               "planned_attempts": n, "attempts": attempts}
    return receipt, seeds


def interval_attempts() -> tuple[dict, list[int], dict[int, list[int]]]:
    n, B = 30, 19
    seeds = [arc1_manifest.seed_for(INTERVAL_CELL["programme"], INTERVAL_CELL["phase"],
                                   INTERVAL_CELL["N"], INTERVAL_CELL["signal"], i, 0, "data")
             for i in range(1, n + 1)]
    inner_map = {}
    attempts = []
    target_intervals = {}
    for outer, seed in enumerate(seeds, 1):
        inner_seeds = [arc1_manifest.seed_for("fa_interval", "development", 160, "null",
                                              outer, inner, "bootstrap") for inner in range(1, B + 1)]
        inner_map[seed] = inner_seeds
        inner_rows = []
        usable = 0
        for inner_index, inner_seed in enumerate(inner_seeds, 1):
            failed = outer == 1 and inner_index == 1
            k0 = candidate("K0", True, -1.0)
            k1 = candidate("K1", not failed, -1.0)
            okay = not failed
            usable += okay
            inner_rows.append({"inner_index": inner_index, "seed": inner_seed,
                               "status": "ok" if okay else "fit_failed", "success": okay,
                               "failure_reason": None if okay else "K1 bootstrap optimizer failed",
                               "eligible": okay, "selected_rank": "K0" if okay else None,
                               "rank_candidates": {"K0": k0, "K1": k1},
                               "selected_fit": ({"G_diag": [0.25 + inner_index * 1e-5] * 4,
                                                 "R_diag": [0.25] * 4} if okay else None)})
        usable_rows = [row for row in inner_rows if row["success"]]
        for trait in range(1, 5):
            values = [row["selected_fit"]["G_diag"][trait - 1] /
                      (row["selected_fit"]["G_diag"][trait - 1] + row["selected_fit"]["R_diag"][trait - 1])
                      for row in usable_rows]
            target_intervals[f"h2_{trait}"] = {
                "formed": True,
                "segments": [[checker._type7_quantile(values, 0.025), checker._type7_quantile(values, 0.975)]],
                "formula": f"G_{trait}{trait}/(G_{trait}{trait}+R_{trait}{trait})",
                "status": "formed"}
        intervals = copy.deepcopy(target_intervals)
        if usable < B:
            for item in intervals.values():
                item.update({"formed": False, "segments": [], "status": "insufficient_usable_bootstrap",
                             "refusal_status": "insufficient_usable_bootstrap"})
        intervals = copy.deepcopy(intervals)
        attempts.append({"attempt_id": f"interval-{outer:03d}", "outer": outer, "seed": seed,
                         "status": "ok", "success": True,
                         "outer_selection": {"eligible": True, "selected_rank": "K0",
                                             "rank_candidates": {"K0": candidate("K0", True, -10.0),
                                                                 "K1": candidate("K1", True, -10.0)}},
                         "bootstrap": {"stage": "started", "requested_B": B,
                                       "refusal_status": None, "inner_attempts": inner_rows,
                                       "inner_seed_sha256": hashlib.sha256(
                                           "".join(f"{s}\n" for s in inner_seeds).encode("ascii")).hexdigest(),
                                       "usable_inner": usable, "intervals": intervals,
                                       "prefix_results": [{"B": B, "usable_inner": usable,
                                                           "usable_fraction": usable / B,
                                                           "intervals": copy.deepcopy(intervals)}],
                                       "method": "candidate_percentile_bootstrap",
                                       "quantiles": [0.025, 0.975]}})
    receipt = {"schema": "arc1-attempt-receipt-v1", **INTERVAL_CELL,
               "protocol_sha256": PROTOCOL_HASH, "source_hashes": dict(SOURCE_HASHES),
               "planned_attempts": n, "attempts": attempts}
    return receipt, seeds, inner_map


def verify(receipt: dict, *, cell: dict | None = None, seeds: list[int] | None = None,
           source_hashes: dict | None = None, protocol_hash: str | None = None,
           bootstrap_seeds: dict[int, list[int]] | None = None) -> dict:
    cell = RANK_CELL if cell is None else cell
    receipt_seeds = rank_receipt()[1] if seeds is None and cell == RANK_CELL else seeds
    if receipt_seeds is None:
        receipt_seeds = interval_attempts()[1]
    return checker.verify_receipt(
        receipt, expected_seeds=receipt_seeds,
        expected_source_hashes=SOURCE_HASHES if source_hashes is None else source_hashes,
        expected_protocol_sha256=PROTOCOL_HASH if protocol_hash is None else protocol_hash,
        expected_cell=cell,
        expected_bootstrap_inner_seeds=bootstrap_seeds,
    )


class Arc1ReceiptAdversaries(unittest.TestCase):
    def test_canonical_seed_vectors_are_pinned(self):
        self.assertEqual(arc1_manifest.seed_for("fa_interval", "pilot", 160, "null", 1, 0, "data"),
                         5356929701607681179)
        self.assertEqual(arc1_manifest.seed_for("fa_interval", "pilot", 160, "null", 1, 1, "bootstrap"),
                         7620720963701940051)
        self.assertEqual(arc1_manifest.seed_for("repeatability", "confirmation", 320,
                                                "near_zero_additive", 400, 0, "data"),
                         18307736988284808080)

    def test_ordinary_fa_derived_start_order_matches_julia_mask_schedule(self):
        ordinary = arc1_manifest.SCIENTIFIC_CONTRACT["fa_optimizer"]["ordinary"]
        expected = [[1] + [-1 if mask & (1 << bit) else 1 for bit in range(3)]
                    for mask in range(8)]
        self.assertEqual(ordinary["derived_signs"], expected)
        self.assertEqual(ordinary["derived_start_order"],
                         "amplitude-major a=(0.1,0.7), then mask=0:7; mask bit 0 flips trait 2")
        self.assertEqual(arc1_manifest.SCIENTIFIC_CONTRACT["fa_optimizer"]["expanded_reference"]
                         ["top_finite_solutions_scope"], "per rank, independently for K0 and K1")

    def test_endpoint_manifest_keeps_199_primary_and_499_999_stability_prefixes(self):
        specs = {(row["phase"], row["signal"], row["outer"]): row
                 for row in arc1_manifest.nested_ranges()}
        first = specs[("pilot", "null", 1)]
        twentieth = specs[("pilot", "strong", 6)]
        outside = specs[("pilot", "strong", 7)]
        self.assertEqual(first["inner_stop"], 999)
        self.assertEqual(first["result_prefixes"], [199, 499, 999])
        self.assertEqual(first["primary_result_B"], 199)
        self.assertEqual(twentieth["primary_result_B"], 199)
        self.assertEqual(outside["inner_stop"], 199)
        self.assertEqual(outside["result_prefixes"], [199])

    def test_run_admission_pins_exact_sources_environment_seeds_and_threads(self):
        with tempfile.TemporaryDirectory(prefix="arc1-valid-admission-") as temp:
            root = _copy_valid_source_tree(Path(temp) / "source")
            cell = {"programme": "fa_interval", "phase": "pilot", "N": 160, "signal": "null"}
            admission = arc1_manifest.build_run_admission(
                root, cell, source_paths=["sim/arc1/independent_dgp.jl", "tools/arc1_manifest.py",
                                          "tools/arc1_receipt_check.py"],
                julia_version="1.10.0", julia_threads=4, blas_threads=1, manifest_audit_root=ROOT)
            arc1_manifest.verify_run_admission(root, admission, julia_version="1.10.0",
                                               julia_threads=4, blas_threads=1)
            altered = copy.deepcopy(admission)
            altered["source_sha256"]["tools/arc1_manifest.py"] = "0" * 64
            with self.assertRaisesRegex(ValueError, "source or dependency bytes"):
                arc1_manifest.verify_run_admission(root, altered, julia_version="1.10.0",
                                                   julia_threads=4, blas_threads=1)
            with self.assertRaisesRegex(ValueError, "thread counts"):
                arc1_manifest.verify_run_admission(root, admission, julia_version="1.10.0",
                                                   julia_threads=8, blas_threads=1)
            altered = copy.deepcopy(admission)
            altered["expected_bootstrap_seeds"]["1"].pop()
            with self.assertRaisesRegex(ValueError, "bootstrap seed partition"):
                arc1_manifest.verify_run_admission(root, altered, julia_version="1.10.0",
                                                   julia_threads=4, blas_threads=1)
            csv_path = root / "sim/arc1/manifests/arc1_outer_seeds.csv"
            csv_path.write_text(csv_path.read_text().replace("5356929701607681179", "5356929701607681178", 1))
            json_path = root / "sim/arc1/manifests/arc1_seed_manifest.json"
            descriptor = json.loads(json_path.read_text())
            descriptor["outer_csv_sha256"] = hashlib.sha256(csv_path.read_bytes()).hexdigest()
            json_path.write_text(json.dumps(descriptor, sort_keys=True, indent=2) + "\n")
            with self.assertRaisesRegex(ValueError, "outer CSV rows differ"):
                arc1_manifest.build_run_admission(
                    root, cell, source_paths=[], julia_version="1.10.0", julia_threads=4,
                    blas_threads=1, manifest_audit_root=ROOT)
        with self.assertRaisesRegex(ValueError, "candidate seed manifest is stale"):
            arc1_manifest.validate_candidate_manifest(ROOT)

    def test_attempt_store_writes_once_and_turns_dangling_start_into_interruption(self):
        with tempfile.TemporaryDirectory(prefix="arc1-attempt-store-") as temp:
            temp_root = Path(temp)
            root = _copy_valid_source_tree(temp_root / "source")
            cell = {"programme": "fa_rank", "phase": "development", "N": 80, "signal": "null"}
            admission = arc1_manifest.build_run_admission(
                root, cell, source_paths=["sim/arc1/runner.py", "sim/arc1/independent_dgp.jl",
                                          "tools/arc1_manifest.py", "tools/arc1_receipt_check.py"],
                julia_version="1.10.0", julia_threads=4, blas_threads=1,
                manifest_audit_root=ROOT)
            output_dir = arc1_runner.cell_output_dir(temp_root / "results", cell)
            store = arc1_runner.Arc1AttemptStore(root, output_dir, admission, julia_version="1.10.0",
                                                 julia_threads=4, blas_threads=1)
            store.begin(1)
            progress = store.rows()
            self.assertEqual(progress[0]["status"], "started")
            self.assertFalse(store._path(1, "result").exists())

            context = multiprocessing.get_context("spawn")
            queue = context.Queue()
            other = context.Process(target=_overlapping_store_worker,
                                    args=(str(root), str(output_dir), admission, queue))
            other.start()
            other.join(timeout=30)
            self.assertEqual(other.exitcode, 0)
            self.assertEqual(queue.get(timeout=2), "busy")

            engine_sources = {path: digest for path, digest in admission["source_sha256"].items()
                              if path.startswith("src/")}
            identity = {"engine_package_uuid": "a0667dea-0f38-44e8-9150-4fda00624eac",
                        "engine_module_path": str(root.resolve() / "src/HSquared.jl"),
                        "loaded_module_names": ["HSquared"],
                        "loaded_engine_source_sha256": engine_sources,
                        "source_sha256_at_load": engine_sources,
                        "source_sha256_after_load": engine_sources,
                        "environment_sha256": admission["environment_sha256"],
                        "active_project": str(root.resolve() / "Project.toml"),
                        "loaded_dependencies": [], "dependency_environment_verified": True,
                        "julia_version": "1.10.0", "julia_threads": 4,
                        "blas_runtime_threads": 1, "blas_vendor": "test-vendor",
                        "thread_environment": admission["thread_environment"]}
            completed = store.finish(1, {"status": "ok", "success": True,
                                         "observed_seed": admission["expected_outer_seeds"][0],
                                         "execution_identity": identity})
            self.assertEqual(completed["status"], "ok")
            store.close()

            dead = context.Process(target=_dead_owner_worker,
                                   args=(str(root), str(output_dir), admission))
            dead.start()
            dead.join(timeout=30)
            self.assertEqual(dead.exitcode, 0)
            resumed = arc1_runner.Arc1AttemptStore(root, output_dir, admission, julia_version="1.10.0",
                                                   julia_threads=4, blas_threads=1)
            progress = resumed.rows()
            self.assertEqual(progress[1]["status"], "started")
            self.assertFalse(resumed._path(2, "result").exists())
            interrupted_rows = resumed.recover_orphans()
            self.assertEqual(len(interrupted_rows), 1)
            self.assertEqual(interrupted_rows[0]["status"], "interrupted")
            self.assertEqual(resumed.rows()[1]["status"], "interrupted")
            errored = arc1_runner.execute_one(resumed, 3,
                lambda *_: (_ for _ in ()).throw(RuntimeError("fit failed")))
            self.assertEqual(errored["status"], "error")
            self.assertIn("fit failed", errored["failure_reason"])
            resumed.close()

    def test_valid_full_cell_receipt_counts_failed_candidate_in_all_attempt_denominator(self):
        receipt, seeds = rank_receipt()
        result = verify(receipt, seeds=seeds)
        self.assertEqual(result["attempts"], 30)
        self.assertEqual(result["failures"], 1)
        self.assertEqual(result["eligible_both_candidates"], 29)
        self.assertEqual(result["candidate_errors"]["K1"]["denominator"], 30)

    def test_rejects_missing_attempt_even_when_failure_was_dropped(self):
        receipt, seeds = rank_receipt()
        receipt["attempts"].pop(1)
        with self.assertRaisesRegex(checker.ReceiptError, "missing planned attempts"):
            verify(receipt, seeds=seeds)

    def test_rejects_tampered_denominator(self):
        receipt, seeds = rank_receipt()
        receipt["planned_attempts"] = 29
        with self.assertRaisesRegex(checker.ReceiptError, "denominator"):
            verify(receipt, seeds=seeds)

    def test_rejects_duplicate_ids_and_seeds(self):
        receipt, seeds = rank_receipt()
        receipt["attempts"][1]["attempt_id"] = receipt["attempts"][0]["attempt_id"]
        with self.assertRaisesRegex(checker.ReceiptError, "duplicate attempt_id"):
            verify(receipt, seeds=seeds)
        receipt, seeds = rank_receipt()
        receipt["attempts"][1]["seed"] = seeds[0]
        with self.assertRaisesRegex(checker.ReceiptError, "missing, reordered, duplicated"):
            verify(receipt, seeds=seeds)

    def test_rejects_replacement_seed(self):
        receipt, seeds = rank_receipt()
        receipt["attempts"][0]["seed"] = seeds[-1] + 1
        with self.assertRaisesRegex(checker.ReceiptError, "replaced"):
            verify(receipt, seeds=seeds)

    def test_receipt_cannot_bypass_rank_validation_by_changing_programme(self):
        receipt, seeds = rank_receipt()
        receipt["programme"] = "repeatability"
        with self.assertRaisesRegex(checker.ReceiptError, "programme differs"):
            verify(receipt, seeds=seeds)

    def test_rejects_wrong_q_or_two_q_penalty(self):
        receipt, seeds = rank_receipt()
        receipt["attempts"][0]["rank_candidates"]["K1"]["aic_penalty"] = 18
        with self.assertRaisesRegex(checker.ReceiptError, "AIC penalty; expected 2q=36"):
            verify(receipt, seeds=seeds)

    def test_recomputes_score_from_raw_loglik(self):
        receipt, seeds = rank_receipt()
        receipt["attempts"][0]["rank_candidates"]["K0"]["score"] += 1.0
        with self.assertRaisesRegex(checker.ReceiptError, "score does not equal"):
            verify(receipt, seeds=seeds)

    def test_recomputes_selected_rank_and_k0_tie_rule(self):
        receipt, seeds = rank_receipt()
        attempt = receipt["attempts"][0]
        attempt["rank_candidates"]["K1"] = candidate("K1", True, -6.0)
        self.assertEqual(attempt["rank_candidates"]["K0"]["score"],
                         attempt["rank_candidates"]["K1"]["score"])
        attempt["selected_rank"] = "K1"
        with self.assertRaisesRegex(checker.ReceiptError, "tie rule"):
            verify(receipt, seeds=seeds)

    def test_rejects_inconsistent_eligibility_and_success_string(self):
        receipt, seeds = rank_receipt()
        receipt["attempts"][0]["eligible"] = False
        with self.assertRaisesRegex(checker.ReceiptError, "eligibility disagrees"):
            verify(receipt, seeds=seeds)
        receipt, seeds = rank_receipt()
        del receipt["attempts"][0]["success"]
        with self.assertRaisesRegex(checker.ReceiptError, "retain boolean success"):
            verify(receipt, seeds=seeds)

    def test_rejects_empty_or_malformed_external_pins(self):
        receipt, seeds = rank_receipt()
        with self.assertRaisesRegex(checker.ReceiptError, "nonempty external mapping"):
            verify(receipt, seeds=seeds, source_hashes={})
        with self.assertRaisesRegex(checker.ReceiptError, "malformed SHA-256"):
            verify(receipt, seeds=seeds, source_hashes={"engine": "bad"})
        with self.assertRaisesRegex(checker.ReceiptError, "nonempty SHA-256"):
            verify(receipt, seeds=seeds, protocol_hash="")

    def test_rejects_protocol_and_source_drift(self):
        receipt, seeds = rank_receipt()
        receipt["protocol_sha256"] = "d" * 64
        with self.assertRaisesRegex(checker.ReceiptError, "canonical-contract pin"):
            verify(receipt, seeds=seeds)
        receipt, seeds = rank_receipt()
        receipt["source_hashes"]["engine"] = "d" * 64
        with self.assertRaisesRegex(checker.ReceiptError, "independently supplied source pins"):
            verify(receipt, seeds=seeds)

    def test_bootstrap_requires_all_fixed_inner_rows_and_recomputed_reranking(self):
        receipt, seeds, inner = interval_attempts()
        result = verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)
        self.assertEqual(result["bootstrap"]["fixed_B"], [19])
        self.assertEqual(result["bootstrap"]["refused_before_start"], 0)
        self.assertEqual(result["interval_targets"]["h2_1"]["formation_denominator"], 30)

    def test_pilot_199_failure_is_not_replaced_by_formed_999_extension(self):
        # First pooled round-robin pilot endpoint: retain 999 seeds, but the
        # primary pilot interval must use the first 199 and fail 99% usability.
        cell = {"programme": "fa_interval", "phase": "pilot", "N": 160, "signal": "null"}
        seeds = [arc1_manifest.seed_for("fa_interval", "pilot", 160, "null", 1, i, "bootstrap")
                 for i in range(1, 1000)]
        rows = []
        for i, seed in enumerate(seeds, 1):
            failed = i <= 3
            rows.append({"inner_index": i, "seed": seed,
                         "status": "fit_failed" if failed else "ok", "success": not failed,
                         "failure_reason": "synthetic retained failure" if failed else None,
                         "eligible": not failed, "selected_rank": "K0" if not failed else None,
                         "rank_candidates": {"K0": candidate("K0"), "K1": candidate("K1", not failed)},
                         "selected_fit": None if failed else {"G_diag": [0.25] * 4, "R_diag": [0.25] * 4}})

        def prefix_result(b):
            usable_rows = [row for row in rows[:b] if row["success"]]
            values = [row["selected_fit"]["G_diag"][0] /
                      (row["selected_fit"]["G_diag"][0] + row["selected_fit"]["R_diag"][0])
                      for row in usable_rows]
            formed = len(usable_rows) >= math.ceil(0.99 * b)
            intervals = {}
            for trait in range(1, 5):
                item = {"formed": formed, "segments": [[0.5, 0.5]] if formed else [],
                        "formula": f"G_{trait}{trait}/(G_{trait}{trait}+R_{trait}{trait})",
                        "status": "formed" if formed else "insufficient_usable_bootstrap"}
                if not formed:
                    item["refusal_status"] = "insufficient_usable_bootstrap"
                else:
                    vals = [r["selected_fit"]["G_diag"][trait - 1] /
                            (r["selected_fit"]["G_diag"][trait - 1] + r["selected_fit"]["R_diag"][trait - 1])
                            for r in usable_rows]
                    item["segments"] = [[checker._type7_quantile(vals, 0.025),
                                          checker._type7_quantile(vals, 0.975)]]
                intervals[f"h2_{trait}"] = item
            return {"B": b, "usable_inner": len(usable_rows), "usable_fraction": len(usable_rows) / b,
                    "intervals": intervals}

        primary = prefix_result(199)
        self.assertFalse(primary["intervals"]["h2_1"]["formed"])
        self.assertTrue(prefix_result(999)["intervals"]["h2_1"]["formed"])
        attempt = {"outer": 1, "success": True,
                   "outer_selection": {"eligible": True, "selected_rank": "K0",
                                       "rank_candidates": {"K0": candidate("K0"), "K1": candidate("K1")}},
                   "bootstrap": {"stage": "started", "requested_B": 199,
                                 "inner_attempts": rows, "usable_inner": 196,
                                 "inner_seed_sha256": hashlib.sha256("".join(f"{s}\n" for s in seeds).encode("ascii")).hexdigest(),
                                 "intervals": primary["intervals"],
                                 "prefix_results": [prefix_result(b) for b in (199, 499, 999)],
                                 "method": "candidate_percentile_bootstrap", "quantiles": [0.025, 0.975]}}
        result = checker._check_bootstrap(attempt, cell, seeds)
        self.assertEqual(result["usable_inner"], 196)
        self.assertEqual(result["usable_denominator"], 199)
        self.assertEqual(result["prefix_B"], [199, 499, 999])

    def test_pilot_primary_interval_cannot_diverge_from_199_prefix_record(self):
        cell = {"programme": "fa_interval", "phase": "pilot", "N": 160, "signal": "null"}
        seeds = [arc1_manifest.seed_for("fa_interval", "pilot", 160, "null", 1, i, "bootstrap")
                 for i in range(1, 1000)]
        receipt, _, _ = interval_attempts()
        attempt = receipt["attempts"][0]
        attempt["outer"] = 1
        boot = attempt["bootstrap"]
        # Rebuild this tiny fixture's B=19 rows into the externally pinned 999 stream;
        # this adversary targets only the primary/prefix equality condition.
        boot["requested_B"] = 199
        original_rows = boot["inner_attempts"]
        boot["inner_attempts"] = ([copy.deepcopy(row) for _ in range(52) for row in original_rows] +
                                   [copy.deepcopy(row) for row in original_rows[:11]])
        for i, row in enumerate(boot["inner_attempts"], 1):
            row["inner_index"] = i
            row["seed"] = seeds[i - 1]
        boot["usable_inner"] = sum(row["success"] for row in boot["inner_attempts"][:199])
        boot["inner_seed_sha256"] = hashlib.sha256("".join(f"{s}\n" for s in seeds).encode("ascii")).hexdigest()
        primary = copy.deepcopy(boot["intervals"])
        for item in primary.values():
            item.update({"formed": False, "segments": [], "status": "insufficient_usable_bootstrap",
                         "refusal_status": "insufficient_usable_bootstrap"})
        boot["intervals"] = copy.deepcopy(primary)
        boot["prefix_results"] = []
        for b in (199, 499, 999):
            usable = sum(row["success"] for row in boot["inner_attempts"][:b])
            intervals = copy.deepcopy(primary)
            if b == 199:
                intervals["h2_1"]["refusal_status"] = "unresolved_evaluation"
            boot["prefix_results"].append({"B": b, "usable_inner": usable,
                                            "usable_fraction": usable / b, "intervals": intervals})
        with self.assertRaisesRegex(checker.ReceiptError, "must equal the first"):
            checker._check_bootstrap(attempt, cell, seeds)

    def test_bootstrap_rejects_dropped_failed_inner_and_false_usable_count(self):
        receipt, seeds, inner = interval_attempts()
        boot = receipt["attempts"][0]["bootstrap"]
        boot["inner_attempts"].pop(0)
        with self.assertRaisesRegex(checker.ReceiptError, "every fixed-B inner attempt"):
            verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)
        receipt, seeds, inner = interval_attempts()
        receipt["attempts"][0]["bootstrap"]["usable_inner"] = 19
        with self.assertRaisesRegex(checker.ReceiptError, "usable count"):
            verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)

    def test_bootstrap_recomputes_h2_estimands_and_percentile_endpoints(self):
        receipt, seeds, inner = interval_attempts()
        row = receipt["attempts"][1]["bootstrap"]["inner_attempts"][0]
        row["selected_fit"]["G_diag"][0] = 0.4
        with self.assertRaisesRegex(checker.ReceiptError, "endpoints do not match"):
            verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)
        receipt, seeds, inner = interval_attempts()
        del receipt["attempts"][1]["bootstrap"]["inner_attempts"][0]["selected_fit"]["R_diag"]
        with self.assertRaisesRegex(checker.ReceiptError, "selected G/R diagonals"):
            verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)

    def test_bootstrap_requires_nested_outer_selector_proof(self):
        receipt, seeds, inner = interval_attempts()
        del receipt["attempts"][0]["outer_selection"]
        with self.assertRaisesRegex(checker.ReceiptError, "nested outer K0/K1"):
            verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)

    def test_external_phase_cell_pins_enforce_full_denominators(self):
        self.assertEqual(checker._expected_outer_count(
            {"programme": "fa_rank", "phase": "confirmation", "N": 320, "signal": "strong"}), 400)
        self.assertEqual(checker._expected_outer_count(
            {"programme": "boundary", "phase": "diagnostic", "N": 160, "signal": "Va_zero"}), 200)
        with self.assertRaisesRegex(checker.ReceiptError, "invalid programme, N, or signal"):
            checker._expected_outer_count(
                {"programme": "repeatability", "phase": "confirmation", "N": 160, "signal": "null"})

    def test_failed_profile_outer_fit_cannot_claim_formed_intervals(self):
        receipt, seeds = rank_receipt()
        cell = {"programme": "repeatability", "phase": "development", "N": 80,
                "signal": "interior"}
        count = 30
        seeds = [arc1_manifest.seed_for(cell["programme"], cell["phase"], cell["N"],
                                        cell["signal"], i, 0, "data") for i in range(1, count + 1)]
        profile = {name: {"formed": False, "segments": [], "status": "outer_fit_failed",
                          "refusal_status": "outer_fit_failed", "formula": formula}
                   for name, formula in checker._expected_interval_formulas(cell).items()}
        attempts = [{"attempt_id": f"profile-{i}", "outer": i, "seed": seed,
                     "status": "outer_fit_failed", "success": False,
                     "failure_reason": "REML did not converge", "profile_method": "profile_likelihood_ratio",
                     "profile_lr_cutoff": 3.841458820694124,
                     "profile_intervals": copy.deepcopy(profile)} for i, seed in enumerate(seeds, 1)]
        receipt = {"schema": "arc1-attempt-receipt-v1", **cell,
                   "protocol_sha256": PROTOCOL_HASH, "source_hashes": dict(SOURCE_HASHES),
                   "planned_attempts": count, "attempts": attempts}
        receipt["attempts"][0]["profile_intervals"]["h2"].update(
            {"formed": True, "segments": [[0.2, 0.4]], "status": "formed"})
        with self.assertRaisesRegex(checker.ReceiptError, "failed outer fit cannot form h2"):
            checker.verify_receipt(receipt, expected_seeds=seeds,
                                   expected_source_hashes=SOURCE_HASHES,
                                   expected_protocol_sha256=PROTOCOL_HASH, expected_cell=cell)

    def test_bootstrap_rejects_wrong_inner_seed_or_decision_and_boolean_only_claim(self):
        receipt, seeds, inner = interval_attempts()
        receipt["attempts"][1]["bootstrap"]["inner_attempts"][0]["seed"] += 1
        with self.assertRaisesRegex(checker.ReceiptError, "missing, reordered, or replaced"):
            verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)
        receipt, seeds, inner = interval_attempts()
        receipt["attempts"][1]["bootstrap"]["inner_attempts"][0]["selected_rank"] = "K1"
        with self.assertRaisesRegex(checker.ReceiptError, "selected rank disagrees"):
            verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)
        receipt, seeds, inner = interval_attempts()
        receipt["attempts"][1]["bootstrap"] = {
            "stage": "started", "requested_B": 19, "reranked_each_inner": True,
            "selector_rerun": True, "inner_attempts": [], "usable_inner": 19,
        }
        with self.assertRaisesRegex(checker.ReceiptError, "every fixed-B inner attempt"):
            verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)

    def test_bootstrap_not_started_requires_explicit_refusal_without_inner_attempts(self):
        receipt, seeds, inner = interval_attempts()
        attempt = receipt["attempts"][0]
        attempt.update({"status": "outer_fit_failed", "success": False,
                        "failure_reason": "outer REML did not converge"})
        attempt["bootstrap"] = {"stage": "not_started", "requested_B": 19,
                                 "refusal_status": "outer_fit_failed", "inner_attempts": [],
                                 "usable_inner": 0,
                                 "intervals": {f"h2_{i}": {"formed": False, "segments": [],
                                                              "status": "outer_fit_failed",
                                                              "refusal_status": "outer_fit_failed",
                                                              "formula": f"G_{i}{i}/(G_{i}{i}+R_{i}{i})"}
                                               for i in range(1, 5)}}
        result = verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)
        self.assertEqual(result["bootstrap"]["refused_before_start"], 1)

    def test_disconnected_confidence_sets_do_not_cover_gap(self):
        segments = checker.validate_segments([[0.0, 0.4], [0.6, 1.0]])
        self.assertFalse(checker.truth_in_segments(0.5, segments))
        self.assertTrue(checker.truth_in_segments(0.7, segments))
        with self.assertRaisesRegex(checker.ReceiptError, "preserve gaps"):
            checker.validate_segments([[0.0, 0.6], [0.4, 1.0]])

    def test_wilson_coverage_checks_detect_under_and_overcoverage(self):
        lower, upper = checker.wilson_interval(380, 400, 0.90)
        self.assertGreaterEqual(lower, 0.92)
        self.assertLessEqual(upper, 0.98)
        self.assertGreater(checker.wilson_interval(392, 400, 0.90)[1], 0.98)
        self.assertLess(checker.wilson_interval(360, 400, 0.90)[0], 0.92)

    def test_protocol_hash_changes_when_dgp_changes(self):
        contract = copy.deepcopy(arc1_manifest.SCIENTIFIC_CONTRACT)
        before = arc1_manifest.contract_sha256_for(contract)
        contract["data_generating_process"]["fa_record_layout"]["mean"][0] = 0.01
        self.assertNotEqual(before, arc1_manifest.contract_sha256_for(contract))

    def test_seed_partition_keeps_fa_labels_but_changes_repeatability_labels(self):
        fa_seed = arc1_manifest.seed_for("fa_rank", "development", 80, "null", 1, 0, "data")
        rep_seed = arc1_manifest.seed_for("repeatability", "development", 80, "near_zero_pe", 1, 0, "data")
        self.assertNotEqual(fa_seed, rep_seed)
        with self.assertRaises(ValueError):
            arc1_manifest.seed_for("repeatability", "development", 80, "null", 1, 0, "data")


if __name__ == "__main__":
    unittest.main()
