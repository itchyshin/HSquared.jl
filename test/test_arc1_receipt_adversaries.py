"""Unit-only adversarial checks for Arc1 receipt integrity, not scientific gates."""
from __future__ import annotations

import copy
import argparse
import hashlib
import json
import math
import multiprocessing
import os
import shutil
import sys
import subprocess
import re
import tempfile
import unittest
from unittest import mock
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "sim" / "arc1"))

import arc1_manifest
import arc1_package_checks as package_checks
import arc1_receipt_check as checker
import runner as arc1_runner
import run_cell as arc1_run_cell


class RetainedArtifactInspectorBoundaryTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "sim/arc1").mkdir(parents=True)
        (self.root / "sim/arc1/inspect_artifacts.jl").write_text("# fixture\n", encoding="utf-8")
        self.artifact = self.root / "retained.jls"
        self.artifact.write_bytes(b"fixture")

    def _completed(self, rows, *, stdout_prefix="", stderr=""):
        return subprocess.CompletedProcess(
            args=["julia"], returncode=0,
            stdout=stdout_prefix + json.dumps(rows) + "\n", stderr=stderr)

    def test_empty_request_skips_julia_and_failures_are_contextual(self):
        with mock.patch.object(checker.subprocess, "run") as run:
            self.assertEqual(checker._inspect_full_artifacts(self.root, []), {})
            run.assert_not_called()

        inspector = self.root / "sim/arc1/inspect_artifacts.jl"
        inspector.unlink()
        with self.assertRaisesRegex(checker.ReceiptError, "lacks the full-artifact inspector"):
            checker._inspect_full_artifacts(self.root, [self.artifact])
        inspector.write_text("# fixture\n", encoding="utf-8")

        for failure in (OSError("julia missing"), subprocess.TimeoutExpired("julia", 120)):
            with self.subTest(failure=type(failure).__name__), \
                    mock.patch.object(checker.subprocess, "run", side_effect=failure):
                with self.assertRaisesRegex(checker.ReceiptError,
                                            "could not inspect retained Julia artifacts"):
                    checker._inspect_full_artifacts(self.root, [self.artifact])

    def test_inspector_process_is_bounded_and_nonzero_exit_is_rejected(self):
        with mock.patch.dict(os.environ, {"ARC1_JULIA": "julia-test",
                                          "JULIA_DEPOT_PATH": "/existing/depot"}), \
                mock.patch.object(checker.subprocess, "run",
                                  return_value=subprocess.CompletedProcess(
                                      args=["julia-test"], returncode=7, stdout="",
                                      stderr="x" * 2500 + "TAIL")) as run:
            with self.assertRaises(checker.ReceiptError) as caught:
                checker._inspect_full_artifacts(self.root, [self.artifact])
        args, kwargs = run.call_args
        self.assertEqual(args[0][0], "julia-test")
        self.assertIn("--threads=1", args[0])
        self.assertEqual(kwargs["timeout"], 120)
        self.assertTrue(kwargs["capture_output"])
        self.assertEqual(kwargs["env"]["JULIA_NUM_THREADS"], "1")
        self.assertEqual(kwargs["env"]["OPENBLAS_NUM_THREADS"], "1")
        self.assertEqual(kwargs["env"]["ARC1_INSPECT_INCLUDE_V3_EVIDENCE"], "false")
        self.assertTrue(kwargs["env"]["JULIA_DEPOT_PATH"].endswith(os.pathsep + "/existing/depot"))
        self.assertIn("Julia artifact inspection failed", str(caught.exception))
        self.assertIn("TAIL", str(caught.exception))
        self.assertLessEqual(len(str(caught.exception).split(": ", 1)[-1]), 2000)

        expected = {"path": str(self.artifact.resolve()), "metadata": {"kind": "container"}}
        with mock.patch.object(checker.subprocess, "run",
                               return_value=self._completed([expected])) as run:
            checker._inspect_full_artifacts(self.root, [self.artifact],
                                            include_v3_evidence=True)
        self.assertEqual(run.call_args.kwargs["env"]["ARC1_INSPECT_INCLUDE_V3_EVIDENCE"], "true")

    def test_inspector_requires_typed_complete_unique_exact_path_rows(self):
        expected = {"path": str(self.artifact.resolve()), "metadata": {"kind": "container"}}
        invalid_payloads = [
            ("", "no typed metadata"),
            ("not-json\n", "no typed metadata"),
            ("[]\n", "every requested artifact"),
            ("{}\n", "every requested artifact"),
            (json.dumps([None]) + "\n", "malformed metadata"),
            (json.dumps([{"path": 7, "metadata": {}}]) + "\n", "malformed metadata"),
            (json.dumps([{"path": str(self.artifact), "metadata": None}]) + "\n",
             "malformed metadata"),
            (json.dumps([{"path": str(self.root / "other.jls"), "metadata": {}}]) + "\n",
             "different artifact paths"),
        ]
        for stdout, message in invalid_payloads:
            with self.subTest(stdout=stdout[:40]), \
                    mock.patch.object(checker.subprocess, "run",
                                      return_value=subprocess.CompletedProcess(
                                          args=["julia"], returncode=0, stdout=stdout, stderr="")):
                with self.assertRaisesRegex(checker.ReceiptError, message):
                    checker._inspect_full_artifacts(self.root, [self.artifact])

        with mock.patch.object(checker.subprocess, "run",
                               return_value=self._completed([expected, expected])):
            with self.assertRaisesRegex(checker.ReceiptError, "duplicate path"):
                checker._inspect_full_artifacts(self.root, [self.artifact, self.artifact])

        with mock.patch.object(checker.subprocess, "run",
                               return_value=self._completed([expected], stdout_prefix="startup noise\n")):
            inspected = checker._inspect_full_artifacts(self.root, [self.artifact])
        self.assertEqual(inspected[str(self.artifact.resolve())], expected)


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


def covariance_payload(diagonal: float = 0.25) -> dict:
    return {"__arc1_array__": True, "dims": [4, 4], "layout": "julia_column_major",
            "data": [diagonal if i == j else 0.0 for j in range(4) for i in range(4)]}


def selector_guards(*, schedule_complete: bool = True, better_unaccepted: bool = False,
                    nonnested: bool = False, witness_status: str = "passed",
                    discrepancy: float | None = 0.0) -> dict:
    return {"schedule_complete": schedule_complete, "better_unaccepted": better_unaccepted,
            "nonnested": nonnested,
            "nesting_witness": {"status": witness_status, "discrepancy": discrepancy,
                                "tolerance": 1e-8}}


def rank_receipt() -> tuple[dict, list[int]]:
    n = arc1_manifest.FA_RANK_DEVELOPMENT_COUNT
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
                         "eligible": eligible, "selection_status": "selected" if eligible else "unavailable",
                         "selected_rank": "K0" if eligible else None,
                         "guard_results": selector_guards(schedule_complete=eligible,
                             witness_status="passed" if eligible else "unavailable",
                             discrepancy=0.0 if eligible else None),
                         "starts_planned": 24, "starts_attempted": 24 if eligible else 6,
                         "selector_attempts": ([{"rank": 0 if i < 6 else 1,
                             "attempted": True} for i in range(24)] if eligible else
                             [{"rank": 0, "attempted": True} for _ in range(6)] +
                             [{"rank": 1, "attempted": False} for _ in range(18)]),
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
                               "eligible": okay, "selection_status": "selected" if okay else "unavailable",
                               "selector_status": "selected" if okay else "unavailable",
                               "selected_rank": "K0" if okay else None,
                               "guard_results": selector_guards(schedule_complete=okay,
                                   witness_status="passed" if okay else "unavailable",
                                   discrepancy=0.0 if okay else None),
                               "starts_planned": 24, "starts_attempted": 24 if okay else 3,
                               "schedule_complete": okay,
                               "rank_candidates": {"K0": k0, "K1": k1},
                               "selected_fit": ({"G_matrix": covariance_payload(0.25 + inner_index * 1e-5),
                                                 "R_matrix": covariance_payload(0.25)} if okay else None)})
        usable_rows = [row for row in inner_rows if row["success"]]
        for trait in range(1, 5):
            values = [row["selected_fit"]["G_matrix"]["data"][(trait - 1) * 5] /
                      (row["selected_fit"]["G_matrix"]["data"][(trait - 1) * 5] + row["selected_fit"]["R_matrix"]["data"][(trait - 1) * 5])
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
                         "outer_selection": {"eligible": True, "selection_status": "selected", "selected_rank": "K0",
                                             "guard_results": selector_guards(),
                                             "starts_planned": 24, "starts_attempted": 24,
                                             "selector_attempts": [{"rank": 0 if i < 6 else 1,
                                                 "attempted": True} for i in range(24)],
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
    def test_g7_julia_command_runs_only_the_reviewed_environment_without_pkg_resolution(self):
        with tempfile.TemporaryDirectory(prefix="arc1-g7-command-") as temp:
            run_dir = Path(temp) / "run"
            run_dir.mkdir()
            sandbox_dir = Path(temp) / "reviewed-sandbox"
            sandbox = {
                "project_path": str(sandbox_dir / "Project.toml"),
                "manifest_path": str(sandbox_dir / "Manifest.toml"),
                "project_sha256": "a" * 64,
                "manifest_sha256": "b" * 64,
            }

            argv, env = package_checks._julia_command(run_dir / "julia-test-driver.jl", sandbox)

            self.assertIn("--startup-file=no", argv)
            self.assertIn("--check-bounds=yes", argv)
            self.assertIn("--threads=1", argv)
            self.assertIn(f"--project={sandbox_dir.resolve()}", argv)
            self.assertEqual(argv[-1], str((run_dir / "julia-test-driver.jl").resolve()))
            command = "\n".join(argv)
            self.assertNotIn("Pkg.test", command)
            self.assertNotIn("Pkg.resolve", command)
            self.assertNotIn("Pkg.instantiate", command)
            self.assertEqual(env["JULIA_LOAD_PATH"], "@:@stdlib")
            driver = package_checks.julia_test_driver_source(sandbox, run_dir / "julia-test-sandbox")
            self.assertNotIn("Pkg.test", driver)
            self.assertNotIn("Pkg.resolve", driver)
            self.assertNotIn("Pkg.instantiate", driver)
            self.assertIn("ARC1_TEST_SANDBOX_VERIFIED", driver)
            self.assertIn("ARC1_LOADED_HSQUARED_SOURCE_VERIFIED", driver)
            self.assertIn(sandbox["project_sha256"], driver)
            self.assertIn(sandbox["manifest_sha256"], driver)
            self.assertIn("include(ARC1_TEST_FILE)", driver)

    def test_profile_search_contract_admits_v4_without_changing_legacy_meanings(self):
        profile = arc1_manifest.SCIENTIFIC_CONTRACT["profile_search"]
        self.assertEqual(profile["method_version"], "arc1_profile_v4")
        self.assertEqual(profile["default_method_version"], "arc1_profile_v1")
        self.assertEqual(profile["study_admission_method_version"], "arc1_profile_v4")
        self.assertTrue(profile["method_version_policy"]["explicit_request_required"])
        self.assertTrue(profile["method_version_policy"]["refuse_mismatch"])
        self.assertTrue(profile["method_version_policy"]["preserve_v1_implementation_and_artifacts"])
        self.assertTrue(profile["method_version_policy"]["preserve_v2_implementation_and_artifacts"])
        self.assertTrue(profile["method_version_policy"]["preserve_v3_implementation_and_artifacts"])
        self.assertEqual(profile["v4_uniform_tail_bound"]["precision_bits"], 256)
        self.assertEqual(profile["v4_uniform_tail_bound"]["strict_gap_minimum"], 1e-8)
        self.assertEqual(profile["v4_candidate_history"]["shared_certified_winner_only_exemption"], True)
        self.assertEqual(profile["v3_corner_certificate"]["target"], "residual_variance")
        self.assertEqual(profile["v3_corner_certificate"]["target_index"], 3)
        self.assertEqual(profile["v3_corner_certificate"]["fixed_residual_variance"], True)

        refinement = profile["positive_bound_refinement"]
        self.assertEqual(refinement["name"], "positive_bound_refine_v1")
        eligibility = refinement["eligibility"]
        self.assertEqual(eligibility["termination"], "NoObjectiveChange")
        self.assertIs(eligibility["candidate_final_converged"], False)
        self.assertTrue(eligibility["optimizer_converged"])
        self.assertEqual(eligibility["optimizer_status"], "converged")
        self.assertTrue(eligibility["analytic_gradient_valid"])
        self.assertFalse(eligibility["line_search_failed"])
        self.assertEqual(eligibility["total_bound_contacts_exactly"], 1)
        self.assertEqual(eligibility["permitted_contact_side"], "lower")
        self.assertEqual(eligibility["permitted_contact_components"], ["Va", "Vpe"])
        self.assertTrue(eligibility["contact_must_differ_from_target"])
        self.assertFalse(eligibility["upper_or_mixed_contacts_allowed"])
        self.assertEqual(eligibility["remaining_positive_nuisance_coordinates"], 1)
        self.assertEqual(eligibility["initial_certificate"], "face_likelihood_mismatch")
        self.assertTrue(eligibility["initial_certificate_must_be_finite"])
        self.assertTrue(eligibility["matching_zero_face_independently_certified"])
        self.assertEqual(eligibility["remaining_coordinate_fd_error_max"], 5e-6)
        self.assertEqual(eligibility["contact_coordinate_fd_error_policy"],
                         {"finite_max": 5e-6, "allow_positive_infinity": True,
                          "reject_nan": True, "reject_negative_infinity": True})

        budget = refinement["shared_iteration_budget"]
        self.assertEqual(budget["total_maximum"], 2000)
        self.assertTrue(budget["original_iterations_must_be_below_total_maximum"])
        self.assertEqual(budget["continuation_allowance"], "max(0, total_maximum-original_iterations)")
        self.assertEqual(budget["continuations_per_original_candidate"], 1)
        self.assertTrue(budget["no_retry_or_replenishment"])
        self.assertTrue(refinement["projected_face_polish_v1_unchanged"])
        self.assertTrue(refinement["continuations_mutually_exclusive"])

        certificate = refinement["terminal_and_physical_zero_certificate"]
        self.assertTrue(certificate["valid_covariance"])
        self.assertTrue(certificate["optimizer_success_without_line_search_failure"])
        self.assertTrue(certificate["fixed_target_and_contact_coordinates_unchanged"])
        self.assertTrue(certificate["no_additional_bound_contact"])
        self.assertEqual(certificate["remaining_scaled_gradient_inf_norm_max"], 1e-6)
        self.assertEqual(certificate["finite_difference_agreement_max"], 5e-6)
        self.assertEqual(certificate["physical_zero_dimensionless_active_derivative_min_exclusive"], 5e-6)
        self.assertEqual(certificate["physical_zero_forward_probe_steps"], [1e-4, 1e-5])
        self.assertTrue(certificate["physical_zero_forward_probe_estimates_finite_and_nonnegative"])
        self.assertEqual(certificate["physical_zero_forward_probe_agreement_with_analytic_and_each_other_max"],
                         5e-6)
        self.assertEqual(certificate["terminal_projection_face_score_range_max"], 1e-8)

        history = refinement["likelihood_history_guards"]
        self.assertEqual(history["capture_stages"], [
            "original_native_before_summary_projection", "continuation", "certificate_probes",
            "valid_values_before_exception"])
        self.assertTrue(history["full_and_same_target_centered_histories_separate"])
        self.assertTrue(history["preserve_centering_tag"])
        self.assertEqual(history["authoritative_raw_nuisance_max_guard"], {
            "uncentered_scale": "full_loglik_vs_winning_certified_nuisance_score",
            "centered_scale": "fixed_ve_centered_loglik_vs_winning_certified_nuisance_score",
            "centered_requires_matching_fixed_ve_tag": True,
            "maximum_excess": 1e-8,
            "final_refusal_status": "nuisance_unresolved",
        })
        self.assertEqual(history["shared_unrestricted_point_guard"],
                         "retained_full_loglik_compared_separately_to_shared_point")
        self.assertEqual(history["local_refinement_success_status"],
                         "resolved_positive_bound_refine_is_not_final_profile_acceptance")
        self.assertTrue(history["preserve_original_failed_candidate_and_certificate"])
        self.assertTrue(history["preserve_shared_unrestricted_point_and_other_candidate_guards"])
        self.assertEqual(history["nuisance_winner"], "independently_certified_exact_zero_face")

        manifest_path = ROOT / "sim/arc1/manifests/arc1_seed_manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        canonical_contract = json.loads(json.dumps(arc1_manifest.SCIENTIFIC_CONTRACT,
                                                   sort_keys=True))
        self.assertEqual(manifest["scientific_contract"], canonical_contract)
        self.assertEqual(manifest["protocol_sha256"], arc1_manifest.contract_sha256())
        self.assertEqual(manifest["nested_seed_ranges"], arc1_manifest.nested_ranges())
        self.assertEqual(manifest["outer_csv_sha256"],
                         "498fcac802f01fedf4b8fb4fc90ba7a61d5b05259c44907d000a6e585587fe07")
        arc1_manifest.verify_manifest(manifest_path, audit_root=ROOT)

    def test_actual_run_cell_closure_rejects_child_outer_seed_relabeling(self):
        julia = shutil.which("julia")
        self.assertIsNotNone(julia, "Julia is required for source-bound admission")
        cell = dict(RANK_CELL)
        with tempfile.TemporaryDirectory(prefix="arc1-run-cell-identity-") as temporary:
            base = Path(temporary)
            source = _copy_valid_source_tree(base / "source")
            admission = arc1_manifest.build_run_admission(
                source, cell, source_paths=[], julia_version="1.10.0",
                julia_threads=1, blas_threads=1, manifest_audit_root=ROOT)
            admission_path = base / "admission.json"
            admission_path.write_text(json.dumps(admission), encoding="utf-8")
            args = argparse.Namespace(source_root=source, output_root=base / "results",
                admission=admission_path, outer=1, julia=julia, julia_threads=1,
                blas_threads=1, timeout=10.0)

            def wrong_child(_command, *, env, timeout_seconds, log_path):
                log_path.write_text("synthetic mismatched child identity\n", encoding="utf-8")
                return {"schema": "arc1-attempt-result-v1", "success": True,
                        "status": "ok", "outer": 999, "seed": 999,
                        "seed_string": "999", "exact_seed_string": "999"}

            with mock.patch.object(arc1_run_cell, "_julia_version", return_value="1.10.0"), \
                    mock.patch.object(arc1_runner, "require_verified_attempt_record"), \
                    mock.patch.object(arc1_run_cell, "launch_julia_attempt", side_effect=wrong_child):
                row = arc1_run_cell.execute_cli(args)
            self.assertFalse(row["success"])
            self.assertEqual(row["status"], "error")
            self.assertIn("returned outer 999", row["failure_reason"])
            self.assertEqual(row["outer"], 1)
            self.assertEqual(row["seed"], admission["expected_outer_seeds"][0])

    def test_fresh_julia_json_to_durable_store_to_checker_fixture(self):
        """Cross-language transport fixture; never admitted or reported as study evidence."""
        julia = shutil.which("julia")
        self.assertIsNotNone(julia, "Julia is required; this integration test must not skip")
        version_result = subprocess.run([julia, "--version"], check=True, capture_output=True, text=True)
        version = re.search(r"([0-9]+\.[0-9]+\.[0-9]+)", version_result.stdout).group(1)
        cell = {"programme": "fa_rank", "phase": "pilot", "N": 80, "signal": "null"}
        with tempfile.TemporaryDirectory(prefix="arc1-json-store-checker-") as temp:
            base = Path(temp)
            source = base / "source"
            output = arc1_runner.cell_output_dir(base / "results", cell)
            stdout_path = base / "child.stdout"
            setup = base / "setup-fake-source.jl"
            setup.write_text('''include(ARGS[1])
_arc1_write_fake_engine(ARGS[2])
''', encoding="utf-8")
            depot = base / "depot"
            depot.mkdir()
            env = dict(os.environ, JULIA_DEPOT_PATH=os.pathsep.join(
                [str(depot), str(Path.home() / ".julia")]),
                JULIA_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1")
            setup_result = subprocess.run([julia, "--startup-file=no", "--threads=1", f"--project={ROOT}",
                str(setup), str(ROOT / "test/arc1_simulation_executor.jl"), str(source)],
                capture_output=True, text=True, timeout=1800, env=env)
            self.assertEqual(setup_result.returncode, 0,
                setup_result.stdout + "\n" + setup_result.stderr)
            for relative in arc1_manifest.discover_admission_source_paths(ROOT):
                if relative.startswith("src/") or relative.startswith("sim/arc1/manifests/"):
                    continue
                origin, target = ROOT / relative, source / relative
                if origin.is_file() and not target.exists():
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(origin, target)
            arc1_manifest.write_manifest(source / "sim/arc1/manifests", audit_root=ROOT)
            admission = arc1_manifest.build_run_admission(source, cell, source_paths=[],
                julia_version=version, julia_threads=1, blas_threads=1, manifest_audit_root=ROOT)
            admission_path = base / "admission.toml"
            attempt_dir = output / "attempts"
            attempt_dir.mkdir(parents=True, exist_ok=True)
            arc1_run_cell._toml_input(admission_path, mode="engineering_probe", source_root=source,
                attempt_output=attempt_dir, artifact_path=attempt_dir / "fake.full.jls",
                cell=cell, outer=21, seed=arc1_manifest.seed_for(
                    cell["programme"], cell["phase"], cell["N"], cell["signal"], 21, 0, "data"),
                bootstrap_seeds=[], admission=admission, blas_threads=1)
            fixture = base / "run-fixture.jl"
            fixture.write_text('''include(ARGS[1])
root = ARGS[2]
output = ARGS[3]
seed = parse(UInt64, ARGS[4])
config = TOML.parsefile(ARGS[6])
cell = (; programme="fa_rank", phase="pilot", N=80, signal="null")
mkpath(root); mkpath(output)
_arc1_write_fake_engine(root)
stdout, artifact = _arc1_run_fake_attempt(root, output, cell, seed, UInt64[];
    outer=21, admission=config)
write(ARGS[5], stdout)
''', encoding="utf-8")
            seed = arc1_manifest.seed_for("fa_rank", "pilot", 80, "null", 21, 0, "data")
            julia_fixture = subprocess.run([julia, "--startup-file=no", "--threads=1", f"--project={ROOT}",
                str(fixture), str(ROOT / "test/arc1_simulation_executor.jl"),
                str(source), str(output), str(seed), str(stdout_path), str(admission_path)],
                capture_output=True, text=True, timeout=1800, env=env)
            self.assertEqual(julia_fixture.returncode, 0,
                julia_fixture.stdout + "\n" + julia_fixture.stderr)
            child = json.loads(stdout_path.read_text(encoding="utf-8"))
            self.assertEqual(child["schema"], "arc1-attempt-result-v1")
            self.assertTrue(child["success"])
            store = arc1_runner.Arc1AttemptStore(source, output, admission,
                julia_version=version, julia_threads=1, blas_threads=1)
            for index, allocated_seed in enumerate(admission["expected_outer_seeds"], start=1):
                store.begin(index)
                if index == 21:
                    self.assertEqual(child["seed"], allocated_seed)
                    payload = dict(child, full_result_path=child["artifact_path"],
                                   full_result_sha256=child["artifact_sha256"])
                else:
                    payload = {"status": "error", "success": False,
                               "failure_reason": "omitted synthetic integration-fixture row"}
                store.finish(index, payload)
            rows = store.rows()
            store.close()
            receipt = arc1_runner.assemble_cell_receipt(rows, admission,
                source_root=source, artifact_root=output)
            verified = checker.verify_receipt(receipt,
                expected_seeds=admission["expected_outer_seeds"],
                expected_source_hashes=admission["source_sha256"],
                expected_protocol_sha256=admission["protocol_sha256"], expected_cell=cell,
                expected_artifact_root=output, expected_source_root=source,
                expected_admission=admission)
            self.assertEqual(verified["attempts"], 30)
            self.assertEqual(verified["failures"], 29)
            retained = receipt["attempts"][20]
            self.assertEqual(retained["selected_rank"], "K0")
            self.assertEqual(retained["candidate_summary"]["K1"]["near_floor"], False)
            self.assertEqual(retained["stored_row"]["result"], child["result"])
            wrong_row_admission = copy.deepcopy(receipt)
            wrong_row_admission["attempts"][20]["stored_row"]["admission_sha256"] = "0" * 64
            with self.assertRaisesRegex(checker.ReceiptError, "durable row admission digest"):
                checker.verify_receipt(wrong_row_admission,
                    expected_seeds=admission["expected_outer_seeds"],
                    expected_source_hashes=admission["source_sha256"],
                    expected_protocol_sha256=admission["protocol_sha256"], expected_cell=cell,
                    expected_artifact_root=output, expected_source_root=source,
                    expected_admission=admission)
            inspected = checker._inspect_full_artifacts(source, [Path(retained["artifact_path"])])
            inspected_row = inspected[str(Path(retained["artifact_path"]).resolve())]
            self.assertEqual(inspected_row["metadata"]["schema"], "arc1-full-result-v2")
            self.assertTrue(inspected_row["data_seed_matches_metadata"])
            self.assertTrue(inspected_row["raw_result_matches_derived_receipt"])
            failed_output = arc1_runner.cell_output_dir(base / "returned-failure-results", cell)
            failed_attempt_dir = failed_output / "attempts"
            failed_attempt_dir.mkdir(parents=True)
            failed_seed = admission["expected_outer_seeds"][0]
            failed_config = base / "returned-failure.toml"
            failed_artifact = failed_attempt_dir / "outer-0001.full.jls"
            arc1_run_cell._toml_input(failed_config, mode="engineering_probe",
                source_root=source, attempt_output=failed_attempt_dir,
                artifact_path=failed_artifact, cell=cell, outer=1, seed=failed_seed,
                bootstrap_seeds=[], admission=admission, blas_threads=1)
            failed_run = subprocess.run([julia, "--startup-file=no", "--threads=1",
                f"--project={source}", str(source / "sim/arc1/execute_attempt.jl"),
                str(failed_config)], capture_output=True, text=True, timeout=90,
                env=dict(env, ARC1_FAKE_UNAVAILABLE="true"))
            self.assertEqual(failed_run.returncode, 2, failed_run.stdout + "\n" + failed_run.stderr)
            returned_failure = json.loads(failed_run.stdout)
            self.assertFalse(returned_failure["success"])
            self.assertEqual(returned_failure["status"], "selection_failed")
            self.assertTrue(failed_artifact.is_file())
            self.assertTrue(returned_failure["receipt_summary_path"])
            failed_store = arc1_runner.Arc1AttemptStore(source, failed_output, admission,
                julia_version=version, julia_threads=1, blas_threads=1)
            for index, allocated_seed in enumerate(admission["expected_outer_seeds"], start=1):
                failed_store.begin(index)
                payload = (dict(returned_failure, full_result_path=returned_failure["artifact_path"],
                                full_result_sha256=returned_failure["artifact_sha256"])
                           if index == 1 else
                           {"status": "error", "success": False,
                            "failure_reason": "synthetic pre-engine fixture failure"})
                failed_store.finish(index, payload)
            failed_rows = failed_store.rows()
            failed_store.close()
            failed_receipt = arc1_runner.assemble_cell_receipt(failed_rows, admission,
                source_root=source, artifact_root=failed_output)
            failed_verified = checker.verify_receipt(failed_receipt,
                expected_seeds=admission["expected_outer_seeds"],
                expected_source_hashes=admission["source_sha256"],
                expected_protocol_sha256=admission["protocol_sha256"], expected_cell=cell,
                expected_artifact_root=failed_output, expected_source_root=source,
                expected_admission=admission)
            self.assertEqual(failed_verified["attempts"], 30)
            self.assertEqual(failed_verified["failures"], 30)
            self.assertEqual(failed_receipt["attempts"][0]["status"], "selection_failed")
            self.assertIsNotNone(failed_receipt["attempts"][0]["receipt_summary_path"])
            self.assertEqual(failed_receipt["attempts"][1]["status"], "error")
            self.assertIsNone(failed_receipt["attempts"][1]["artifact_path"])
            mutate_jls = base / "mutate-retained-data.jl"
            mutate_jls.write_text('''using HSquared, Serialization
root = dirname(Base.active_project())
include(joinpath(root, "sim/arc1/engine_io.jl"))
include(joinpath(root, "sim/arc1/artifact_container.jl"))
artifact = arc1_read_artifact_container(ARGS[1])
artifact.data.Y[1, 1] += 1
arc1_write_artifact_container_new(ARGS[2], artifact)
artifact = arc1_read_artifact_container(ARGS[1])
metadata = merge(artifact.metadata,
    (; semantic_data_identity_sha256=repeat("0", 64)))
artifact = merge(artifact, (; metadata))
arc1_write_artifact_container_new(ARGS[3], artifact)
artifact = arc1_read_artifact_container(ARGS[1])
result = merge(artifact.result,
    (; success=false, status="selection_failed", failure_reason="mutated retained result"))
artifact = merge(artifact, (; result))
arc1_write_artifact_container_new(ARGS[4], artifact)
artifact = arc1_read_artifact_container(ARGS[1])
driver = merge(artifact.metadata.driver_protocol_identity,
    (; protocol_sha256=repeat("f", 64)))
metadata = merge(artifact.metadata, (; driver_protocol_identity=driver))
artifact = merge(artifact, (; metadata))
arc1_write_artifact_container_new(ARGS[5], artifact)
artifact = arc1_read_artifact_container(ARGS[1])
data = merge(artifact.data, (; seed=UInt64(999)))
artifact = merge(artifact, (; data))
arc1_write_artifact_container_new(ARGS[6], artifact)
artifact = arc1_read_artifact_container(ARGS[1])
raw_selection = merge(artifact.raw_selection, (; selected_rank=1))
artifact = merge(artifact, (; raw_selection))
arc1_write_artifact_container_new(ARGS[7], artifact)
''', encoding="utf-8")
            changed_artifact = output / "attempts" / "changed-data.full.jls"
            changed_metadata_artifact = output / "attempts" / "changed-metadata.full.jls"
            stale_summary_artifact = output / "attempts" / "stale-summary.full.jls"
            changed_driver_artifact = output / "attempts" / "changed-driver.full.jls"
            changed_seed_artifact = output / "attempts" / "changed-seed.full.jls"
            changed_selector_artifact = output / "attempts" / "changed-selector.full.jls"
            mutation = subprocess.run([julia, "--startup-file=no", "--threads=1",
                f"--project={source}", str(mutate_jls), retained["artifact_path"],
                str(changed_artifact), str(changed_metadata_artifact),
                str(stale_summary_artifact), str(changed_driver_artifact),
                str(changed_seed_artifact), str(changed_selector_artifact)],
                capture_output=True, text=True, timeout=90, env=env)
            self.assertEqual(mutation.returncode, 0, mutation.stdout + "\n" + mutation.stderr)
            seed_inspection = checker._inspect_full_artifacts(source, [changed_seed_artifact])
            self.assertFalse(seed_inspection[str(changed_seed_artifact.resolve())]["data_seed_matches_metadata"])
            selector_inspection = checker._inspect_full_artifacts(source, [changed_selector_artifact])
            self.assertFalse(selector_inspection[str(changed_selector_artifact.resolve())]
                             ["raw_result_matches_derived_receipt"])
            for programme, signal in (("repeatability", "near_zero_pe"),
                                      ("fa_interval", "null")):
                raw_cell = {"programme": programme, "phase": "engineering_probe",
                            "N": 80, "signal": signal}
                # This is a transport-only fixture over the already-pinned
                # synthetic source tree; it is not a cell admission or study run.
                raw_admission = dict(admission)
                raw_admission["profile_method_version"] = (
                    "arc1_profile_v4" if programme == "repeatability" else None)
                raw_output = arc1_runner.cell_output_dir(base / "raw-path-results", raw_cell)
                raw_attempt_dir = raw_output / "attempts"
                raw_attempt_dir.mkdir(parents=True, exist_ok=True)
                raw_artifact = raw_attempt_dir / f"{programme}.full.jls"
                raw_seed = 12345
                raw_bootstrap_seeds = ([12345000 + j for j in range(1, 1000)]
                    if programme == "fa_interval" else [])
                raw_config = base / f"{programme}.toml"
                arc1_run_cell._toml_input(raw_config, mode="engineering_probe",
                    source_root=source, attempt_output=raw_attempt_dir,
                    artifact_path=raw_artifact, cell=raw_cell, outer=1,
                    seed=raw_seed, bootstrap_seeds=raw_bootstrap_seeds,
                    admission=raw_admission, blas_threads=1)
                raw_run = subprocess.run([julia, "--startup-file=no", "--threads=1",
                    f"--project={source}", str(source / "sim/arc1/execute_attempt.jl"),
                    str(raw_config)], capture_output=True, text=True, timeout=120, env=env)
                self.assertIn(raw_run.returncode, (0, 2), raw_run.stdout + "\n" + raw_run.stderr)
                self.assertTrue(raw_artifact.is_file(), raw_run.stdout + "\n" + raw_run.stderr)
                raw_inspected = checker._inspect_full_artifacts(source, [raw_artifact])
                raw_row = raw_inspected[str(raw_artifact.resolve())]
                self.assertTrue(raw_row["raw_result_matches_derived_receipt"],
                    f"{programme}: {raw_row.get('raw_result_projection_difference')}")
                if programme == "repeatability":
                    self.assertEqual(raw_row["metadata"]["requested_profile_method_version"],
                                     "arc1_profile_v4")
                    self.assertEqual(raw_row["metadata"]["profile_method_version"],
                                     "arc1_profile_v4")
                    self.assertIs(raw_row["metadata"]["profile_method_version_mismatch"], False)
                    self.assertIs(raw_row["profile_method_identity_matches"], True)
                mutation_script = base / f"mutate-{programme}.jl"
                mutation_body = ('''using HSquared, Serialization
root = dirname(Base.active_project())
include(joinpath(root, "sim/arc1/engine_io.jl"))
include(joinpath(root, "sim/arc1/artifact_container.jl"))
artifact = arc1_read_artifact_container(ARGS[1])
targets = copy(artifact.profile.targets)
targets[:heritability] = merge(targets[:heritability], (; status=:controlled_mutation))
profile = merge(artifact.profile, (; targets))
artifact = merge(artifact, (; profile))
arc1_write_artifact_container_new(ARGS[2], artifact)
artifact = arc1_read_artifact_container(ARGS[1])
metadata = merge(artifact.metadata, (; profile_method_version="arc1_profile_v2"))
artifact = merge(artifact, (; metadata))
arc1_write_artifact_container_new(ARGS[3], artifact)
''' if programme == "repeatability" else '''using HSquared, Serialization
root = dirname(Base.active_project())
include(joinpath(root, "sim/arc1/engine_io.jl"))
include(joinpath(root, "sim/arc1/artifact_container.jl"))
artifact = arc1_read_artifact_container(ARGS[1])
attempts = copy(artifact.bootstrap_raw.attempts)
attempts[1] = merge(attempts[1], (; seed=UInt64(1)))
bootstrap_raw = merge(artifact.bootstrap_raw, (; attempts))
artifact = merge(artifact, (; bootstrap_raw))
arc1_write_artifact_container_new(ARGS[2], artifact)
''')
                mutation_script.write_text(mutation_body, encoding="utf-8")
                altered_raw_artifact = raw_attempt_dir / f"{programme}-raw-mutation.full.jls"
                altered_method_artifact = raw_attempt_dir / f"{programme}-method-mutation.full.jls"
                mutated = subprocess.run([julia, "--startup-file=no", "--threads=1",
                    f"--project={source}", str(mutation_script), str(raw_artifact),
                    str(altered_raw_artifact), str(altered_method_artifact)],
                    capture_output=True, text=True, timeout=90, env=env)
                self.assertEqual(mutated.returncode, 0, mutated.stdout + "\n" + mutated.stderr)
                altered_inspected = checker._inspect_full_artifacts(source, [altered_raw_artifact])
                self.assertFalse(altered_inspected[str(altered_raw_artifact.resolve())]
                    ["raw_result_matches_derived_receipt"], programme)
                if programme == "repeatability":
                    altered_method = checker._inspect_full_artifacts(source, [altered_method_artifact])
                    self.assertIs(altered_method[str(altered_method_artifact.resolve())]
                                  ["profile_method_identity_matches"], False)
            for path, reason in ((changed_artifact, "semantic data identity differs"),
                                 (changed_metadata_artifact, "semantic data identity differs"),
                                 (stale_summary_artifact, "retained JLS result differs from its embedded receipt summary"),
                                 (changed_driver_artifact, "full driver/protocol identity"),
                                 (changed_seed_artifact,
                                  "retained data seed differs from externally pinned metadata seed"),
                                 (changed_selector_artifact,
                                  "retained raw selector/profile/bootstrap output differs from its derived receipt")):
                tampered = copy.deepcopy(receipt)
                changed_row = tampered["attempts"][20]
                changed_hash = hashlib.sha256(path.read_bytes()).hexdigest()
                changed_row["artifact_path"] = str(path)
                changed_row["artifact_sha256"] = changed_hash
                changed_row["stored_row"]["full_result_path"] = str(path)
                changed_row["stored_row"]["full_result_sha256"] = changed_hash
                with self.assertRaisesRegex(checker.ReceiptError, reason):
                    checker.verify_receipt(tampered,
                        expected_seeds=admission["expected_outer_seeds"],
                        expected_source_hashes=admission["source_sha256"],
                        expected_protocol_sha256=admission["protocol_sha256"], expected_cell=cell,
                        expected_artifact_root=output, expected_source_root=source,
                        expected_admission=admission)
            adversary = copy.deepcopy(receipt)
            forged = adversary["attempts"][20]
            fake_artifact = output / "attempts" / "forged.full.jls"
            shutil.copy2(ROOT / "README.md", fake_artifact)
            fake_hash = hashlib.sha256(fake_artifact.read_bytes()).hexdigest()
            forged["artifact_path"] = str(fake_artifact)
            forged["artifact_sha256"] = fake_hash
            forged["stored_row"]["full_result_path"] = str(fake_artifact)
            forged["stored_row"]["full_result_sha256"] = fake_hash
            with self.assertRaisesRegex(checker.ReceiptError, "Julia artifact inspection failed"):
                checker.verify_receipt(adversary,
                    expected_seeds=admission["expected_outer_seeds"],
                    expected_source_hashes=admission["source_sha256"],
                    expected_protocol_sha256=admission["protocol_sha256"], expected_cell=cell,
                    expected_artifact_root=output, expected_source_root=source,
                    expected_admission=admission)

    def test_confirmation_admission_refuses_without_pilot_and_explicit_400_decision(self):
        cell = {"programme": "fa_rank", "phase": "confirmation", "N": 80, "signal": "null"}
        kwargs = {"source_paths": [], "julia_version": "1.10.0",
                  "julia_threads": 4, "blas_threads": 1}
        with self.assertRaisesRegex(ValueError, "requires pilot qualification and explicit allocation decision"):
            arc1_manifest.build_run_admission(ROOT, cell, **kwargs)
        pilot = {gate: {"success_marker": f"ARC1_{gate}_PILOT_QUALIFIED",
                        "pilot_qualification": "PASS",
                        "protocol_sha256": PROTOCOL_HASH} for gate in ("G2", "G3")}
        bad_decision = {"schema": "arc1-confirmation-allocation-decision-v1",
            "status": "authorized", "allocation_per_cell": 400,
            "protocol_sha256": PROTOCOL_HASH, "decision_id": "decision-1"}
        with self.assertRaisesRegex(ValueError, "pilot bundle evidence"):
            arc1_manifest.build_run_admission(ROOT, cell, pilot_qualification=pilot,
                confirmation_allocation_decision=bad_decision, **kwargs)

    def test_confirmation_admission_recomputes_retained_pilot_bundle(self):
        cell = {"programme": "fa_rank", "phase": "confirmation", "N": 80, "signal": "null"}
        with tempfile.TemporaryDirectory(prefix="arc1-forged-pilot-") as temporary:
            folder = Path(temporary)
            bundle = folder / "bundle.json"
            pins = folder / "pins.json"
            bundle.write_text(json.dumps({"receipts": []}), encoding="utf-8")
            pins.write_text(json.dumps({"pins": {}}), encoding="utf-8")
            forged_gates = {}
            for gate in ("G2", "G3"):
                result = folder / f"{gate}-result.json"
                forged = {"gate": gate, "phase": "confirmation", "integrity": "FAIL",
                    "integrity_cells": 0, "pilot_qualification": "PASS",
                    "confirmation_result": "HOLD", "confirmation_allocation": "HOLD",
                    "protocol_sha256": PROTOCOL_HASH,
                    "success_marker": f"ARC1_{gate}_PILOT_QUALIFIED"}
                result.write_text(json.dumps(forged), encoding="utf-8")
                forged_gates[gate] = {
                    "bundle_path": str(bundle), "bundle_sha256": hashlib.sha256(bundle.read_bytes()).hexdigest(),
                    "pins_path": str(pins), "pins_sha256": hashlib.sha256(pins.read_bytes()).hexdigest(),
                    "result_path": str(result), "result_sha256": hashlib.sha256(result.read_bytes()).hexdigest()}
            decision = {"schema": "arc1-confirmation-allocation-decision-v1",
                "status": "authorized", "allocation_per_cell": 400,
                "protocol_sha256": PROTOCOL_HASH, "decision_id": "synthetic-forgery"}
            with self.assertRaisesRegex(ValueError, "does not verify|missing one or more required cells"):
                arc1_manifest.build_run_admission(ROOT, cell, source_paths=[],
                    julia_version="1.10.0", julia_threads=4, blas_threads=1,
                    pilot_qualification=forged_gates,
                    confirmation_allocation_decision=decision)

    def test_confirmation_admission_requires_programme_specific_pilot_gate(self):
        decision = {"schema": "arc1-confirmation-allocation-decision-v1",
            "status": "authorized", "allocation_per_cell": 400,
            "protocol_sha256": PROTOCOL_HASH, "decision_id": "synthetic-cross-gate"}
        rank_markers = {gate: {"success_marker": f"ARC1_{gate}_PILOT_QUALIFIED",
            "pilot_qualification": "PASS", "protocol_sha256": PROTOCOL_HASH}
            for gate in ("G2", "G3")}
        for cell, expected_gate in (
                ({"programme": "fa_interval", "phase": "confirmation", "N": 160,
                  "signal": "null"}, "G4"),
                ({"programme": "repeatability", "phase": "confirmation", "N": 80,
                  "signal": "interior"}, "G5")):
            with self.subTest(programme=cell["programme"]):
                with self.assertRaisesRegex(ValueError, f"retained {expected_gate} pilot evidence"):
                    arc1_manifest._validate_confirmation_authorization(
                        ROOT, cell, rank_markers, decision)

    def test_canonical_seed_vectors_are_pinned(self):
        self.assertNotIn("sim/arc1/manifest-revisions.md",
                         arc1_manifest.discover_admission_source_paths(ROOT))
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
            self.assertEqual(admission["schema"], "arc1-run-admission-v2")
            self.assertIsNone(admission["profile_method_version"])
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
            repeatability_cell = {"programme": "repeatability", "phase": "development",
                                  "N": 80, "signal": "interior"}
            with self.assertRaisesRegex(ValueError, "requires explicit arc1_profile_v4"):
                arc1_manifest.build_run_admission(root, repeatability_cell, source_paths=[],
                    julia_version="1.10.0", julia_threads=1, blas_threads=1,
                    manifest_audit_root=ROOT)
            with self.assertRaisesRegex(ValueError, "requires explicit arc1_profile_v4"):
                arc1_manifest.build_run_admission(root, repeatability_cell, source_paths=[],
                    julia_version="1.10.0", julia_threads=1, blas_threads=1,
                    manifest_audit_root=ROOT, profile_method_version="arc1_profile_v2")
            with self.assertRaisesRegex(ValueError, "requires explicit arc1_profile_v4"):
                arc1_manifest.build_run_admission(root, repeatability_cell, source_paths=[],
                    julia_version="1.10.0", julia_threads=1, blas_threads=1,
                    manifest_audit_root=ROOT, profile_method_version="arc1_profile_v3")
            profile_admission = arc1_manifest.build_run_admission(
                root, repeatability_cell, source_paths=[], julia_version="1.10.0",
                julia_threads=1, blas_threads=1, manifest_audit_root=ROOT,
                profile_method_version="arc1_profile_v4")
            arc1_manifest.verify_run_admission(root, profile_admission, julia_version="1.10.0",
                                                julia_threads=1, blas_threads=1)
            for wrong_version in ("arc1_profile_v1", "arc1_profile_v2", "arc1_profile_v3", None):
                altered_profile = copy.deepcopy(profile_admission)
                if wrong_version is None:
                    del altered_profile["profile_method_version"]
                else:
                    altered_profile["profile_method_version"] = wrong_version
                with self.assertRaisesRegex(ValueError, "frozen arc1_profile_v4"):
                    arc1_manifest.verify_run_admission(root, altered_profile, julia_version="1.10.0",
                                                       julia_threads=1, blas_threads=1)
            legacy_profile = copy.deepcopy(profile_admission)
            legacy_profile["schema"] = "arc1-run-admission-v1"
            with self.assertRaisesRegex(ValueError, "unsupported Arc1 run admission schema"):
                arc1_manifest.verify_run_admission(root, legacy_profile, julia_version="1.10.0",
                                                   julia_threads=1, blas_threads=1)
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
        with tempfile.TemporaryDirectory(prefix="arc1-stale-contract-") as temp:
            stale_root = Path(temp)
            stale_manifest_dir = stale_root / "sim/arc1/manifests"
            stale_manifest_dir.mkdir(parents=True)
            shutil.copy2(ROOT / "sim/arc1/manifests/arc1_outer_seeds.csv",
                         stale_manifest_dir / "arc1_outer_seeds.csv")
            stale_descriptor = json.loads(
                (ROOT / "sim/arc1/manifests/arc1_seed_manifest.json").read_text()
            )
            stale_descriptor["scientific_contract"]["profile_search"]["method_version"] = "arc1_profile_v1"
            (stale_manifest_dir / "arc1_seed_manifest.json").write_text(
                json.dumps(stale_descriptor, sort_keys=True, indent=2) + "\n"
            )
            with self.assertRaisesRegex(ValueError, "candidate seed manifest is stale"):
                arc1_manifest.validate_candidate_manifest(stale_root)

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
            seed = admission["expected_outer_seeds"][0]
            with self.assertRaisesRegex(ValueError, "different outer index"):
                store.finish(1, {"outer": 2, "status": "ok", "success": True,
                                 "observed_seed": seed, "execution_identity": identity})
            with self.assertRaisesRegex(ValueError, "different UInt64 seed"):
                store.finish(1, {"outer": 1, "seed": seed + 1, "status": "ok",
                                 "success": True, "observed_seed": seed,
                                 "execution_identity": identity})
            with self.assertRaisesRegex(ValueError, "mismatched exact_seed_string"):
                store.finish(1, {"outer": 1, "seed": seed, "exact_seed_string": str(seed + 1),
                                 "status": "ok", "success": True,
                                 "observed_seed": seed, "execution_identity": identity})
            completed = store.finish(1, {"status": "ok", "success": True,
                                         "observed_seed": seed,
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
            with mock.patch.object(arc1_runner, "require_verified_attempt_record"):
                errored = arc1_runner.execute_one(resumed, 3,
                    lambda *_: (_ for _ in ()).throw(RuntimeError("fit failed")))
            self.assertEqual(errored["status"], "error")
            self.assertIn("fit failed", errored["failure_reason"])
            resumed.close()

    def test_stored_executor_rows_assemble_and_roundtrip_through_receipt_checker(self):
        with tempfile.TemporaryDirectory(prefix="arc1-receipt-assembly-") as temp:
            temp_root = Path(temp)
            root = _copy_valid_source_tree(temp_root / "source")
            cell = dict(RANK_CELL)
            admission = arc1_manifest.build_run_admission(
                root, cell, source_paths=["sim/arc1/runner.py", "sim/arc1/run_cell.py",
                                          "sim/arc1/execute_attempt.jl", "sim/arc1/engine_io.jl",
                                          "sim/arc1/execution_identity.jl", "tools/arc1_receipt_check.py"],
                julia_version="1.10.0", julia_threads=4, blas_threads=1,
                manifest_audit_root=ROOT)
            output_dir = arc1_runner.cell_output_dir(temp_root / "results", cell)
            store = arc1_runner.Arc1AttemptStore(root, output_dir, admission,
                julia_version="1.10.0", julia_threads=4, blas_threads=1)
            source_identity = {path: digest for path, digest in admission["source_sha256"].items()
                               if path.startswith("src/")}
            identity = {"engine_package_uuid": "a0667dea-0f38-44e8-9150-4fda00624eac",
                        "engine_module_path": str(root.resolve() / "src/HSquared.jl"),
                        "loaded_module_names": ["HSquared"],
                        "loaded_engine_source_sha256": source_identity,
                        "source_sha256_at_load": source_identity,
                        "source_sha256_after_load": source_identity,
                        "environment_sha256": admission["environment_sha256"],
                        "active_project": str(root.resolve() / "Project.toml"),
                        "loaded_dependencies": [], "dependency_environment_verified": True,
                        "julia_version": "1.10.0", "julia_threads": 4,
                        "blas_runtime_threads": 1, "blas_vendor": "test-vendor",
                        "thread_environment": admission["thread_environment"]}
            synthetic, expected_seeds = rank_receipt()
            for attempt in synthetic["attempts"]:
                outer = attempt["outer"]
                store.begin(outer)
                artifact = store.directory / f"{outer:04d}.full.jls"
                artifact.write_bytes(f"verified fake Julia artifact {outer}".encode())
                payload = {"outer": outer, "seed": attempt["seed"],
                           "status": attempt["status"], "success": attempt["success"],
                           "failure_reason": attempt["failure_reason"],
                           "result": {key: value for key, value in attempt.items()
                                      if key not in {"attempt_id", "outer", "seed", "status", "success", "failure_reason"}},
                           "execution_identity": identity,
                           "full_result_path": str(artifact),
                           "full_result_sha256": hashlib.sha256(artifact.read_bytes()).hexdigest()}
                store.finish(outer, payload)
            rows = store.rows()
            store.close()
            receipt = arc1_runner.assemble_cell_receipt(rows, admission,
                source_root=root, artifact_root=output_dir)
            self.assertEqual(receipt["attempts"][0]["stored_row"], rows[0])
            wrong_admission_row = copy.deepcopy(receipt)
            wrong_admission_row["attempts"][0]["stored_row"]["admission_sha256"] = "0" * 64
            with self.assertRaisesRegex(checker.ReceiptError, "durable row admission digest"):
                checker.verify_receipt(wrong_admission_row,
                    expected_seeds=expected_seeds,
                    expected_source_hashes=admission["source_sha256"],
                    expected_protocol_sha256=admission["protocol_sha256"], expected_cell=cell,
                    expected_artifact_root=output_dir, expected_source_root=root,
                    expected_admission=admission)
            with self.assertRaisesRegex(checker.ReceiptError, "artifact claims require"):
                checker.verify_receipt(receipt, expected_seeds=expected_seeds,
                    expected_source_hashes=admission["source_sha256"],
                    expected_protocol_sha256=admission["protocol_sha256"], expected_cell=cell)
            failed_before_engine = copy.deepcopy(rows)
            failed_before_engine[2].update(status="error", success=False,
                failure_reason="Julia child failed before emitting an attempt result")
            failed_before_engine[2].pop("result", None)
            receipt_with_launch_failure = arc1_runner.assemble_cell_receipt(
                failed_before_engine, admission, source_root=root, artifact_root=output_dir)
            self.assertEqual(receipt_with_launch_failure["attempts"][2]["selection_status"], "not_run")
            with self.assertRaisesRegex(checker.ReceiptError, "artifact claims require"):
                checker.verify_receipt(receipt_with_launch_failure,
                    expected_seeds=expected_seeds, expected_source_hashes=admission["source_sha256"],
                    expected_protocol_sha256=admission["protocol_sha256"], expected_cell=cell)
            rows[0]["full_result_path"] = str(output_dir / "missing.jls")
            with self.assertRaisesRegex(ValueError, "artifact is missing"):
                arc1_runner.assemble_cell_receipt(rows, admission, source_root=root,
                                                   artifact_root=output_dir)

    def test_valid_full_cell_receipt_counts_failed_candidate_in_all_attempt_denominator(self):
        receipt, seeds = rank_receipt()
        result = verify(receipt, seeds=seeds)
        self.assertEqual(result["attempts"], arc1_manifest.FA_RANK_DEVELOPMENT_COUNT)
        self.assertEqual(result["failures"], 1)
        self.assertEqual(result["eligible_both_candidates"], 59)
        self.assertEqual(result["candidate_errors"]["K1"]["denominator"],
                         arc1_manifest.FA_RANK_DEVELOPMENT_COUNT)

    def test_available_candidate_pair_is_separate_from_guarded_selector_outcome(self):
        receipt, seeds = rank_receipt()
        attempt = receipt["attempts"][0]
        attempt.update(status="selection_failed", success=False,
                       failure_reason="schedule_complete guard refused automatic selection",
                       selection_status="unavailable", selected_rank=None)
        pair_available, _ = checker._check_rank_decision(attempt, required=True)
        self.assertTrue(pair_available)
        result = verify(receipt, seeds=seeds)
        self.assertEqual(result["eligible_both_candidates"], 59)
        self.assertEqual(result["failures"], 2)

    def test_selected_rank_reconciles_retained_six_plus_eighteen_schedule(self):
        receipt, _ = rank_receipt()
        selected = receipt["attempts"][0]
        checker._check_rank_decision(selected, required=True)
        selected["selector_attempts"].pop()
        with self.assertRaisesRegex(checker.ReceiptError, "planned-start count"):
            checker._check_rank_decision(selected, required=True)
        receipt, _ = rank_receipt()
        selected = receipt["attempts"][0]
        del selected["selector_attempts"]
        with self.assertRaisesRegex(checker.ReceiptError, "must retain every selector attempt"):
            checker._check_rank_decision(selected, required=True)
        receipt, _ = rank_receipt()
        spoofed = receipt["attempts"][0]
        del spoofed["selector_attempts"]
        spoofed["inner_index"] = 1
        with self.assertRaisesRegex(checker.ReceiptError, "must retain every selector attempt"):
            checker._check_rank_decision(spoofed, required=True)
        receipt, _ = rank_receipt()
        interrupted = receipt["attempts"][0]
        interrupted.update(status="interrupted", success=False,
            selection_status="interrupted", selected_rank=None,
            failure_reason="interrupted before K0 schedule completion")
        interrupted["selector_attempts"] = [{"rank": 0, "attempted": True}
            for _ in range(6)] + [{"rank": 1, "attempted": True} for _ in range(18)]
        interrupted["starts_attempted"] = 24
        interrupted["guard_results"]["schedule_complete"] = None
        checker._check_rank_decision(interrupted, required=True)

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

    def test_receipt_pins_must_crossbind_to_source_root_admission(self):
        receipt, seeds = rank_receipt()
        admission = {"cell": dict(RANK_CELL), "expected_outer_seeds": list(seeds),
            "source_sha256": dict(SOURCE_HASHES), "protocol_sha256": PROTOCOL_HASH}
        variants = []
        changed = copy.deepcopy(admission)
        changed["cell"]["N"] = 160
        variants.append(changed)
        changed = copy.deepcopy(admission)
        changed["protocol_sha256"] = "e" * 64
        variants.append(changed)
        changed = copy.deepcopy(admission)
        changed["source_sha256"]["engine"] = "e" * 64
        variants.append(changed)
        changed = copy.deepcopy(admission)
        changed["expected_outer_seeds"][0] += 1
        variants.append(changed)
        for forged in variants:
            with self.assertRaisesRegex(checker.ReceiptError, "pins differ from the source-root admission"):
                checker.verify_receipt(receipt, expected_seeds=seeds,
                    expected_source_hashes=SOURCE_HASHES,
                    expected_protocol_sha256=PROTOCOL_HASH, expected_cell=RANK_CELL,
                    expected_source_root=ROOT, expected_admission=forged)

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
                         "eligible": not failed, "selection_status": "selected" if not failed else "unavailable",
                         "selector_status": "selected" if not failed else "unavailable",
                         "selected_rank": "K0" if not failed else None,
                         "guard_results": selector_guards(schedule_complete=not failed,
                             witness_status="passed" if not failed else "unavailable",
                             discrepancy=0.0 if not failed else None),
                         "starts_planned": 24, "starts_attempted": 24 if not failed else 3,
                         "schedule_complete": not failed,
                         "rank_candidates": {"K0": candidate("K0"), "K1": candidate("K1", not failed)},
                         "selected_fit": None if failed else {"G_matrix": covariance_payload(), "R_matrix": covariance_payload()}})

        def prefix_result(b):
            usable_rows = [row for row in rows[:b] if row["success"]]
            values = [row["selected_fit"]["G_matrix"]["data"][0] /
                      (row["selected_fit"]["G_matrix"]["data"][0] + row["selected_fit"]["R_matrix"]["data"][0])
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
                    vals = [r["selected_fit"]["G_matrix"]["data"][(trait - 1) * 5] /
                            (r["selected_fit"]["G_matrix"]["data"][(trait - 1) * 5] + r["selected_fit"]["R_matrix"]["data"][(trait - 1) * 5])
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
                   "outer_selection": {"eligible": True, "selection_status": "selected", "selected_rank": "K0",
                                       "guard_results": selector_guards(),
                                       "starts_planned": 24, "starts_attempted": 24,
                                       "selector_attempts": [{"rank": 0 if i < 6 else 1,
                                                              "attempted": True}
                                                             for i in range(24)],
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

    def test_usable_bootstrap_inner_requires_exact_false_guards_and_certified_nesting(self):
        for field, value in (("better_unaccepted", None),
                             ("nonnested", None)):
            receipt, seeds, inner = interval_attempts()
            row = receipt["attempts"][1]["bootstrap"]["inner_attempts"][1]
            row["guard_results"][field] = value
            with self.assertRaises(checker.ReceiptError):
                verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)
        for field, value in (("tolerance", 1e-4), ("discrepancy", 1.1e-8)):
            receipt, seeds, inner = interval_attempts()
            row = receipt["attempts"][1]["bootstrap"]["inner_attempts"][1]
            row["guard_results"]["nesting_witness"][field] = value
            with self.assertRaises(checker.ReceiptError):
                verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)
        receipt, seeds, inner = interval_attempts()
        receipt["attempts"][0]["bootstrap"]["usable_inner"] = 19
        with self.assertRaisesRegex(checker.ReceiptError, "usable count"):
            verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)

    def test_bootstrap_recomputes_h2_estimands_and_percentile_endpoints(self):
        receipt, seeds, inner = interval_attempts()
        row = receipt["attempts"][1]["bootstrap"]["inner_attempts"][0]
        row["selected_fit"]["G_matrix"]["data"][0] = 0.4
        with self.assertRaisesRegex(checker.ReceiptError, "endpoints do not match"):
            verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)
        receipt, seeds, inner = interval_attempts()
        del receipt["attempts"][1]["bootstrap"]["inner_attempts"][0]["selected_fit"]["R_matrix"]
        with self.assertRaisesRegex(checker.ReceiptError, "full selected G/R matrices"):
            verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)

    def test_bootstrap_rejects_positive_diagonal_but_indefinite_covariance(self):
        receipt, seeds, inner = interval_attempts()
        fit = receipt["attempts"][1]["bootstrap"]["inner_attempts"][0]["selected_fit"]
        fit["G_matrix"]["data"] = [0.25, 0.0, 0.0, 0.0,
                                      0.30, 0.25, 0.0, 0.0,
                                      0.0, 0.0, 0.25, 0.0,
                                      0.0, 0.0, 0.0, 0.25]
        with self.assertRaisesRegex(checker.ReceiptError, "symmetric"):
            verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)
        # Keep symmetry and positive diagonal while violating strict PD.
        fit["G_matrix"]["data"] = [0.25, 0.30, 0.0, 0.0,
                                      0.30, 0.25, 0.0, 0.0,
                                      0.0, 0.0, 0.25, 0.0,
                                      0.0, 0.0, 0.0, 0.25]
        with self.assertRaisesRegex(checker.ReceiptError, "positive definite"):
            verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)

    def test_covariance_checker_rejects_cholesky_pass_exactly_indefinite_roundoff_witness(self):
        matrix = [
            [0.32703552661281554, 0.3339778994936688, -0.12197868147333915, -0.15526750130081754],
            [0.3339778994936688, 0.6110494128948445, 0.25214283287929734, -0.07012389993364093],
            [-0.12197868147333915, 0.25214283287929734, 0.5862464535913825, 0.09660223544193038],
            [-0.15526750130081754, -0.07012389993364093, 0.09660223544193038, 0.5773462119534791],
        ]
        payload = covariance_payload()
        payload["data"] = [matrix[row][col] for col in range(4) for row in range(4)]
        with self.assertRaisesRegex(checker.ReceiptError, "positive definite"):
            checker._decode_covariance_matrix(payload, "R")

    def test_exact_positive_covariance_can_fail_legacy_float64_refactorability(self):
        # Exact rational Sylvester minors are positive for this retained Float64
        # witness; its last Float64 Cholesky pivot rounds slightly below zero.
        matrix = [
            [0.33508673936601313, 0.3329139329960774, -0.10266151482077902, -0.25402233285563575],
            [0.3329139329960774, 0.6297492767174504, 0.1727480599916967, 0.003372019247056772],
            [-0.10266151482077902, 0.1727480599916967, 0.5911721167915641, 0.06976173434632839],
            [-0.25402233285563575, 0.003372019247056772, 0.06976173434632839, 0.6036129132899815],
        ]
        payload = covariance_payload()
        payload["data"] = [matrix[row][col] for col in range(4) for row in range(4)]
        with self.assertRaisesRegex(checker.ReceiptError, "Float64-Cholesky-refactorable"):
            checker._decode_covariance_matrix(payload, "R")

    def test_covariance_checker_rejects_subtolerance_asymmetry(self):
        payload = covariance_payload()
        payload["data"] = [
            1.0, 0.0, 0.0, 0.0,
            1e-13, 1.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
        ]

        with self.assertRaisesRegex(checker.ReceiptError, "symmetric"):
            checker._decode_covariance_matrix(payload, "R")

    def test_covariance_checker_rejects_singular_zero_leading_pivot_and_nonfinite(self):
        payload = covariance_payload()
        payload["data"] = [1.0, 0.0, 0.0, 0.0,
                           0.0, 0.0, 0.0, 0.0,
                           0.0, 0.0, 1.0, 0.0,
                           0.0, 0.0, 0.0, 1.0]
        with self.assertRaisesRegex(checker.ReceiptError, "positive definite"):
            checker._decode_covariance_matrix(payload, "R")

        payload["data"] = [0.0, 1.0, 0.0, 0.0,
                           1.0, 0.0, 0.0, 0.0,
                           0.0, 0.0, 1.0, 0.0,
                           0.0, 0.0, 0.0, 1.0]
        with self.assertRaisesRegex(checker.ReceiptError, "positive definite"):
            checker._decode_covariance_matrix(payload, "R")

        payload["data"] = [1.0, 0.0, 0.0, 0.0,
                           0.0, float("inf"), 0.0, 0.0,
                           0.0, 0.0, 1.0, 0.0,
                           0.0, 0.0, 0.0, 1.0]
        with self.assertRaisesRegex(checker.ReceiptError, "finite values"):
            checker._decode_covariance_matrix(payload, "R")

    def test_bootstrap_requires_nested_outer_selector_proof(self):
        receipt, seeds, inner = interval_attempts()
        del receipt["attempts"][0]["outer_selection"]
        with self.assertRaisesRegex(checker.ReceiptError, "nested outer K0/K1"):
            verify(receipt, cell=INTERVAL_CELL, seeds=seeds, bootstrap_seeds=inner)

    def test_external_phase_cell_pins_enforce_full_denominators(self):
        self.assertEqual(checker._expected_outer_count(
            {"programme": "fa_rank", "phase": "development", "N": 80, "signal": "null"}),
            arc1_manifest.FA_RANK_DEVELOPMENT_COUNT)
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
        with self.assertRaises(checker.ReceiptError):
            checker.verify_receipt(receipt, expected_seeds=seeds,
                                   expected_source_hashes=SOURCE_HASHES,
                                   expected_protocol_sha256=PROTOCOL_HASH, expected_cell=cell)

    def test_profile_point_guard_binds_all_five_formed_targets(self):
        cell = {"programme": "repeatability", "phase": "development", "N": 80,
                "signal": "interior"}
        seeds = [arc1_manifest.seed_for(cell["programme"], cell["phase"], cell["N"],
            cell["signal"], i, 0, "data") for i in range(1, 31)]
        formulae = checker._expected_interval_formulas(cell)
        attempts = []
        for i, seed in enumerate(seeds, 1):
            intervals = {target: {"formed": True, "segments": [[0.0, 1.0]],
                "status": "formed", "formula": formula} for target, formula in formulae.items()}
            attempts.append({"attempt_id": f"formed-{i}", "outer": i, "seed": seed,
                "status": "ok", "success": True, "failure_reason": None,
                "profile_method": "profile_likelihood_ratio", "profile_lr_cutoff": 3.841458820694124,
                "profile_method_version": "arc1_profile_v1", "point_fit_status": "ok",
                "point_fit_not_optimal": False, "point_loglik": -10.0,
                "max_constrained_loglik": -10.0, "point_identity": "a" * 64,
                "reference_point_identity": "a" * 64, "source_identity": "b" * 64,
                "reference_source_identity": "b" * 64,
                "point_fit_diagnostic_identity": "c" * 64,
                "target_diagnostics_identity": "d" * 64, "profile_intervals": intervals})
        receipt = {"schema": "arc1-attempt-receipt-v1", **cell,
            "protocol_sha256": PROTOCOL_HASH, "source_hashes": dict(SOURCE_HASHES),
            "planned_attempts": 30, "attempts": attempts}
        self.assertEqual(verify(receipt, cell=cell, seeds=seeds)["interval_targets"]["Va"]["formed"], 30)
        for change, expected in (({"point_fit_not_optimal": True, "max_constrained_loglik": 0.0},
                                  "nonoptimal common point fit"),
                                 ({"reference_point_identity": "e" * 64}, "point-fit identities differ"),
                                 ({"reference_source_identity": "e" * 64}, "source identity differs"),
                                 ({"point_identity": "invalid", "reference_point_identity": "invalid"},
                                  "point-fit identities differ"),
                                 ({"source_identity": "invalid", "reference_source_identity": "invalid"},
                                  "source_identity must be a SHA-256 identity"),
                                 ({"point_fit_diagnostic_identity": "invalid"},
                                  "point_fit_diagnostic_identity must be a SHA-256 identity"),
                                 ({"target_diagnostics_identity": "invalid"},
                                  "target_diagnostics_identity must be a SHA-256 identity")):
            adversarial = copy.deepcopy(receipt)
            for row in adversarial["attempts"]:
                row.update(change)
            with self.assertRaisesRegex(checker.ReceiptError, expected):
                verify(adversarial, cell=cell, seeds=seeds)

    def test_v4_profile_admission_binds_requested_actual_and_pre_engine_identity(self):
        cell = {"programme": "repeatability", "phase": "development", "N": 80,
                "signal": "interior"}
        seeds = [arc1_manifest.seed_for(cell["programme"], cell["phase"], cell["N"],
            cell["signal"], i, 0, "data") for i in range(1, 31)]
        formulas = checker._expected_interval_formulas(cell)
        with tempfile.TemporaryDirectory(prefix="arc1-profile-v4-admission-") as temporary:
            base = Path(temporary)
            source = _copy_valid_source_tree(base / "source")
            admission = arc1_manifest.build_run_admission(source, cell, source_paths=[],
                julia_version="1.10.0", julia_threads=1, blas_threads=1,
                manifest_audit_root=ROOT, profile_method_version="arc1_profile_v4")
            engine_sources = {name: digest for name, digest in admission["source_sha256"].items()
                              if name.startswith("src/")}
            runtime_identity = {"engine_package_uuid": "a0667dea-0f38-44e8-9150-4fda00624eac",
                "engine_module_path": str((source / "src/HSquared.jl").resolve()),
                "loaded_module_names": ["HSquared"],
                "source_sha256_at_load": engine_sources,
                "source_sha256_after_load": engine_sources,
                "loaded_engine_source_sha256": engine_sources,
                "environment_sha256": admission["environment_sha256"],
                "active_project": str((source / "Project.toml").resolve()),
                "loaded_dependencies": [], "dependency_environment_verified": True,
                "julia_version": "1.10.0", "julia_threads": 1, "blas_runtime_threads": 1,
                "thread_environment": admission["thread_environment"], "blas_vendor": "synthetic-test"}
            attempts = []
            for i, seed in enumerate(seeds, 1):
                intervals = {target: {"formed": True, "segments": [[0.0, 1.0]],
                    "status": "formed", "formula": formula} for target, formula in formulas.items()}
                attempts.append({"attempt_id": f"v4-{i}", "outer": i, "seed": seed,
                    "status": "ok", "success": True, "failure_reason": None,
                    "profile_method": "profile_likelihood_ratio", "profile_lr_cutoff": 3.841458820694124,
                    "requested_profile_method_version": "arc1_profile_v4",
                    "profile_method_version": "arc1_profile_v4", "point_fit_status": "ok",
                    "point_fit_not_optimal": False, "point_loglik": -10.0,
                    "max_constrained_loglik": -10.0, "point_identity": "a" * 64,
                    "reference_point_identity": "a" * 64, "source_identity": "b" * 64,
                    "reference_source_identity": "b" * 64,
                    "point_fit_diagnostic_identity": "c" * 64,
                    "target_diagnostics_identity": "d" * 64, "profile_intervals": intervals,
                    "execution_identity": runtime_identity})
            receipt = {"schema": "arc1-attempt-receipt-v1", **cell,
                "protocol_sha256": admission["protocol_sha256"],
                "source_hashes": admission["source_sha256"],
                "planned_attempts": 30, "attempts": attempts}

            def verify_admitted(candidate):
                return checker.verify_receipt(candidate, expected_seeds=seeds,
                    expected_source_hashes=admission["source_sha256"],
                    expected_protocol_sha256=admission["protocol_sha256"], expected_cell=cell,
                    expected_source_root=source, expected_admission=admission)

            self.assertEqual(verify_admitted(receipt)["interval_targets"]["Va"]["formed"], 30)
            wrong_native = copy.deepcopy(receipt)
            wrong_native["attempts"][0]["profile_method_version"] = "arc1_profile_v2"
            with self.assertRaisesRegex(checker.ReceiptError, "method version"):
                verify_admitted(wrong_native)
            wrong_request = copy.deepcopy(receipt)
            wrong_request["attempts"][0]["requested_profile_method_version"] = "arc1_profile_v2"
            with self.assertRaisesRegex(checker.ReceiptError, "request differs"):
                verify_admitted(wrong_request)
            wrong_native_failure = copy.deepcopy(receipt)
            wrong_native_failure["attempts"][0].update(profile_method_version_mismatch=True,
                profile_method_version="arc1_profile_v2", success=False, status="error",
                failure_reason="native method mismatch")
            with self.assertRaisesRegex(checker.ReceiptError, "native profile method version differs"):
                verify_admitted(wrong_native_failure)

            error_rows = [{"outer": i, "seed": seed, "status": "error", "success": False,
                "failure_reason": "Julia failed before emitting an attempt result"}
                for i, seed in enumerate(seeds, 1)]
            with tempfile.TemporaryDirectory(dir=base) as artifacts:
                pre_engine = arc1_runner.assemble_cell_receipt(error_rows, admission,
                    source_root=source, artifact_root=Path(artifacts))
            self.assertEqual(pre_engine["attempts"][0]["requested_profile_method_version"],
                             "arc1_profile_v4")
            self.assertIsNone(pre_engine["attempts"][0]["profile_method_version"])
            self.assertEqual(verify_admitted(pre_engine)["failures"], 30)

            interrupted_evidence_summary = {
                "requested_method_version": "arc1_profile_v4",
                "actual_method_version": "arc1_profile_v4",
                "source_identity": "f" * 64,
                "returned_method_version": None,
                "history_aliases_match": True,
                "history_row_count": 0,
                "history_event_count": 0,
                "v4_tail_certificates": [],
            }
            entered_rows = [{"outer": i, "seed": seed, "status": "interrupted",
                "success": False, "failure_reason": "synthetic interrupt after method entry",
                "requested_profile_method_version": "arc1_profile_v4",
                "profile_method_version": "arc1_profile_v4",
                "profile_source_identity": "f" * 64,
                "v3_profile_evidence_summary": interrupted_evidence_summary}
                for i, seed in enumerate(seeds, 1)]
            with tempfile.TemporaryDirectory(dir=base) as artifacts:
                entered = arc1_runner.assemble_cell_receipt(entered_rows, admission,
                    source_root=source, artifact_root=Path(artifacts))
            entered_attempt = entered["attempts"][0]
            self.assertEqual(entered_attempt["profile_method_version"], "arc1_profile_v4")
            self.assertEqual(entered_attempt["profile_source_identity"], "f" * 64)
            self.assertEqual(entered_attempt["v3_profile_evidence_summary"],
                             interrupted_evidence_summary)
            self.assertEqual(entered_attempt["point_fit_status"], "not_run")
            self.assertTrue(all(not target["formed"] for target in
                                entered_attempt["profile_intervals"].values()))
            checker._check_profile_point_diagnostics(entered_attempt,
                entered_attempt["profile_intervals"], expected_method_version="arc1_profile_v4")
            checker._check_v4_profile_evidence_payload(entered_attempt, "f" * 64,
                native_evidence=interrupted_evidence_summary)

    def test_v4_json_evidence_checks_aliases_tail_bound_and_source(self):
        source = "f" * 64
        threshold = checker.Fraction.from_float(1e-8)
        certificate = {"status": "excluded_tail", "certified": True, "precision": 256,
            "rounding": "directed_mpfr", "determinant_identity":
                "detD_detHinvDH_equals_detHtH_detCtDC", "design_identity": "a" * 64,
            "determinant": {"__arc1_rational__": {"numerator": "1", "denominator": "2",
                "type": "Rational{BigInt}"}}, "residual_df": 78, "convention": "omit_2pi",
            "E": 2.0, "gap_lower": {"__arc1_bigfloat__": {"numerator": "11",
                "denominator": "1000000000", "precision": 256}}}
        history = [{"target": "residual_variance", "value": 1.0}]
        attempt = {"profile_source_identity": source,
            "v3_profile_evidence": {"requested_method_version": "arc1_profile_v4",
                "actual_method_version": "arc1_profile_v4", "source_identity": source,
                "arc1_profile_v3_evaluations": history,
                "arc1_profile_v4_evaluations": copy.deepcopy(history),
                "v4_tail_certificates": [{"target": "residual_variance",
                                            "certificate": certificate}]}}
        checker._check_v4_profile_evidence_payload(attempt, source)
        compact = {"requested_method_version": "arc1_profile_v4",
            "actual_method_version": "arc1_profile_v4", "source_identity": source,
            "returned_method_version": "arc1_profile_v4",
            "history_aliases_match": True, "history_row_count": 1,
            "history_event_count": 1,
            "v4_tail_certificates_shape": "vector",
            "v4_tail_certificates": attempt["v3_profile_evidence"]["v4_tail_certificates"]}
        compact_attempt = {"profile_source_identity": source,
            "v3_profile_evidence_summary": compact}
        checker._check_v4_profile_evidence_payload(compact_attempt, source,
            native_evidence=copy.deepcopy(compact))
        for field, value, expected in (
            ("v4_tail_certificates_shape", "malformed", "tail-certificate collection"),
            ("history_aliases_match", False, "history aliases"),
            ("history_row_count", -1, "history summary"),
            ("source_identity", "0" * 64, "evidence identity"),
        ):
            corrupted_compact = copy.deepcopy(compact)
            corrupted_compact[field] = value
            with self.assertRaisesRegex(checker.ReceiptError, expected):
                checker._check_v4_profile_evidence_payload(
                    {"profile_source_identity": source,
                     "v3_profile_evidence_summary": corrupted_compact}, source,
                    native_evidence=corrupted_compact)
        missing_shape = copy.deepcopy(compact)
        missing_shape.pop("v4_tail_certificates_shape")
        with self.assertRaisesRegex(checker.ReceiptError, "tail-certificate collection"):
            checker._check_v4_profile_evidence_payload(
                {"profile_source_identity": source,
                 "v3_profile_evidence_summary": missing_shape}, source,
                native_evidence=missing_shape)
        for mutate, expected in (
            (lambda x: x["v3_profile_evidence"].update(
                returned_method_version="arc1_profile_v3"), "returned method version"),
            (lambda x: x["v3_profile_evidence"].update(
                returned_method_version=None), "returned method version"),
            (lambda x: x["v3_profile_evidence"].pop("arc1_profile_v4_evaluations"),
             "history aliases"),
            (lambda x: x["v3_profile_evidence"].update(
                arc1_profile_v4_evaluations=[{"target": "other"}]), "history aliases"),
            (lambda x: x["v3_profile_evidence"].update(source_identity="0" * 64),
             "evidence identity"),
            (lambda x: x["v3_profile_evidence"]["v4_tail_certificates"][0]["certificate"].update(
                gap_lower={"__arc1_bigfloat__": {"numerator": str(threshold.numerator),
                    "denominator": str(threshold.denominator), "precision": 256}}),
             "strict separation gap"),
            (lambda x: x["v3_profile_evidence"]["v4_tail_certificates"][0]["certificate"].update(
                gap_lower=None), "losslessly encoded"),
            (lambda x: x["v3_profile_evidence"]["v4_tail_certificates"][0]["certificate"].update(
                gap_lower="1.1e-8"), "losslessly encoded"),
            (lambda x: x["v3_profile_evidence"]["v4_tail_certificates"][0]["certificate"].update(
                gap_lower=True), "losslessly encoded"),
            (lambda x: x["v3_profile_evidence"]["v4_tail_certificates"][0]["certificate"].update(
                gap_lower={"__arc1_float__": "NaN"}), "losslessly encoded"),
            (lambda x: x["v3_profile_evidence"]["v4_tail_certificates"][0]["certificate"].pop(
                "gap_lower"), "losslessly encoded"),
        ):
            corrupted = copy.deepcopy(attempt)
            mutate(corrupted)
            with self.assertRaisesRegex(checker.ReceiptError, expected):
                checker._check_v4_profile_evidence_payload(corrupted, source)
        for mutate in (
            lambda x: x["v3_profile_evidence"].update(
                arc1_profile_v3_evaluations=[], arc1_profile_v4_evaluations=[],
                v4_tail_certificates=[]),
            lambda x: x["v3_profile_evidence"].update(
                arc1_profile_v3_evaluations=[{"target": "replaced"}],
                arc1_profile_v4_evaluations=[{"target": "replaced"}]),
        ):
            corrupted = copy.deepcopy(attempt)
            retained_native = copy.deepcopy(attempt["v3_profile_evidence"])
            mutate(corrupted)
            with self.assertRaisesRegex(checker.ReceiptError, "retained native JLS sink"):
                checker._check_v4_profile_evidence_payload(
                    corrupted, source, native_evidence=retained_native)

    def test_v4_native_certificate_validation_checks_absence_and_interrupted_unavailability(self):
        attempt = {"status": "ok"}
        metadata = {"status": "ok"}
        for malformed in (
            {},
            {"v3_evidence_records": None},
            {"v3_evidence_records": []},
            {"v3_evidence_records": {"v4_tail_certificates": ()}},
            {"v3_evidence_records": {"v4_tail_certificates": {"target": "residual_variance"}}},
            {"v3_evidence_records": {"v4_tail_certificates": None}},
        ):
            with self.assertRaisesRegex(checker.ReceiptError,
                                        "native v4 certificate evidence is missing or malformed"):
                checker._check_v4_native_certificate_validation(
                    attempt, metadata, malformed)

        absent = {"v3_evidence_records": {"v4_tail_certificates_shape": "vector",
                                    "v4_tail_certificates": []},
            "v4_tail_certificate_validation_status": "no_certificate",
            "v4_tail_certificate_design_correspondence": "not_applicable",
            "v4_tail_certificate_evidence_valid": True}
        self.assertFalse(checker._check_v4_native_certificate_validation(
            attempt, metadata, absent))
        for contradictory_absence in (
            {**absent, "v4_tail_certificate_validation_status": "validated"},
            {**absent, "v4_tail_certificate_design_correspondence": "matched"},
            {**absent, "v4_tail_certificate_evidence_valid": False},
        ):
            with self.assertRaisesRegex(checker.ReceiptError, "native v4 certificate absence"):
                checker._check_v4_native_certificate_validation(
                    attempt, metadata, contradictory_absence)

        valid = {"v3_evidence_records": {"v4_tail_certificates_shape": "vector",
                                          "v4_tail_certificates": [{"target": "residual_variance"}]},
            "v4_tail_certificate_validation_status": "validated",
            "v4_tail_certificate_design_correspondence": "matched",
            "v4_tail_certificate_evidence_valid": True}
        checker._check_v4_native_certificate_validation(attempt, metadata, valid)
        for contradictory_validation in (
            {**valid, "v4_tail_certificate_design_correspondence": "unavailable_interrupted"},
            {**valid, "v4_tail_certificate_evidence_valid": False},
        ):
            with self.assertRaisesRegex(checker.ReceiptError,
                                        "native v4 certificate is not fully validated"):
                checker._check_v4_native_certificate_validation(
                    attempt, metadata, contradictory_validation)

        interrupted_attempt = {"status": "interrupted"}
        interrupted_metadata = {"status": "interrupted"}
        unavailable = {"v3_evidence_records": {"v4_tail_certificates_shape": "vector",
                                                "v4_tail_certificates": [{"target": "residual_variance"}]},
            "v4_tail_certificate_validation_status": "design_correspondence_unavailable_interrupted",
            "v4_tail_certificate_design_correspondence": "unavailable_interrupted",
            "v4_tail_certificate_evidence_valid": False}
        checker._check_v4_native_certificate_validation(
            interrupted_attempt, interrupted_metadata, unavailable)

        for mutated_attempt, mutated_metadata, mutated_status in (
            ({"status": "error"}, {"status": "interrupted"}, unavailable),
            (interrupted_attempt, {"status": "error"}, unavailable),
            (interrupted_attempt, interrupted_metadata, {**unavailable,
                "v4_tail_certificate_validation_status": "invalid"}),
            (interrupted_attempt, interrupted_metadata, {**unavailable,
                "v4_tail_certificate_design_correspondence": "matched"}),
            (interrupted_attempt, interrupted_metadata, {**unavailable,
                "v4_tail_certificate_evidence_valid": True}),
            (attempt, metadata, {**valid, "v4_tail_certificate_evidence_valid": False}),
        ):
            with self.assertRaisesRegex(checker.ReceiptError, "native v4 certificate"):
                checker._check_v4_native_certificate_validation(
                    mutated_attempt, mutated_metadata, mutated_status)

    def test_rehashed_container_rejects_result_summary_contradiction(self):
        julia = shutil.which("julia")
        self.assertIsNotNone(julia, "Julia is required; this integrity test must not skip")
        with tempfile.TemporaryDirectory(prefix="arc1-container-contradiction-") as temporary:
            directory = Path(temporary)
            original, changed = directory / "original.arc1c", directory / "changed.arc1c"
            script = directory / "contradict.jl"
            script.write_text('''using HSquared, Serialization, SHA
source_root = ARGS[3]
include(joinpath(source_root, "sim/arc1/engine_io.jl"))
include(joinpath(source_root, "sim/arc1/artifact_container.jl"))
include(joinpath(source_root, "sim/arc1/execute_attempt.jl"))
metadata = (; schema="arc1-full-result-v2", status="error", outer=1,
    seed_string="1", cell=(; programme="fa_rank", phase="pilot", N=80, signal="null"),
    execution_identity=(;), driver_protocol_identity=(; source_sha256=Dict(),
        protocol_sha256=repeat("0", 64), environment_sha256=Dict()))
result = (; status="error", success=false, failure_reason="synthetic refusal",
    profile_method="profile_likelihood_ratio", profile_lr_cutoff=3.841458820694124,
    profile_intervals=Dict(), point_estimates=nothing, v3_profile_evidence=nothing,
    profile_method_version=nothing, point_fit_status="not_run",
    point_fit_not_optimal=nothing, point_loglik=nothing,
    max_constrained_loglik=nothing, point_identity=nothing,
    reference_point_identity=nothing, source_identity=nothing,
    reference_source_identity=nothing, point_fit_diagnostic_identity=nothing,
    target_diagnostics_identity=nothing)
summary = merge(arc1_json_receipt(result), (; requested_profile_method_version=nothing))
arc1_write_artifact_container_new(ARGS[1], (; metadata, result, receipt_summary=summary))
artifact = arc1_read_artifact_container(ARGS[1])
mutated = merge(artifact.result, (; failure_reason="mutated retained result"))
arc1_write_artifact_container_new(ARGS[2], merge(artifact, (; result=mutated)))
''', encoding="utf-8")
            depot = directory / "julia-depot"
            depot.mkdir()
            inherited_depots = os.environ.get("JULIA_DEPOT_PATH", str(Path.home() / ".julia"))
            env = dict(os.environ, JULIA_DEPOT_PATH=os.pathsep.join(
                [str(depot), inherited_depots]), JULIA_NUM_THREADS="1",
                OPENBLAS_NUM_THREADS="1")
            generated = subprocess.run([julia, "--startup-file=no", "--threads=1",
                f"--project={ROOT}", str(script), str(original), str(changed), str(ROOT)],
                check=False, capture_output=True, text=True, timeout=120, env=env)
            self.assertEqual(generated.returncode, 0, generated.stdout + "\n" + generated.stderr)
            self.assertNotEqual(hashlib.sha256(original.read_bytes()).digest(),
                                hashlib.sha256(changed.read_bytes()).digest())
            inspected = checker._inspect_full_artifacts(ROOT, [changed])
            row = inspected[str(changed.resolve())]
            self.assertIs(row["receipt_summary_matches_retained_result"], False)

    def test_explicit_historical_v2_identity_remains_checkable(self):
        cell = {"programme": "repeatability", "N": 80}
        profile = {target: {"formed": False, "segments": [], "status": "outer_fit_failed",
            "refusal_status": "fit failed", "formula": formula} for target, formula in
            checker._expected_interval_formulas(cell).items()}
        attempt = {"success": True, "profile_method_version": "arc1_profile_v2",
            "requested_profile_method_version": "arc1_profile_v2", "point_fit_status": "ok",
            "point_fit_not_optimal": False, "point_loglik": -10.0,
            "max_constrained_loglik": -10.0, "point_identity": "a" * 64,
            "reference_point_identity": "a" * 64, "source_identity": "b" * 64,
            "reference_source_identity": "b" * 64, "point_fit_diagnostic_identity": "c" * 64,
            "target_diagnostics_identity": "d" * 64}
        checker._check_profile_point_diagnostics(attempt, profile,
            expected_method_version="arc1_profile_v2")
        with self.assertRaisesRegex(checker.ReceiptError, "request differs"):
            checker._check_profile_point_diagnostics(attempt, profile,
                expected_method_version="arc1_profile_v3")

    def test_pre_engine_profile_failure_never_fabricates_truth_as_point_estimate(self):
        cell = {"programme": "repeatability", "phase": "development", "N": 80,
                "signal": "interior"}
        seeds = [arc1_manifest.seed_for(cell["programme"], cell["phase"], cell["N"],
                                        cell["signal"], i, 0, "data") for i in range(1, 31)]
        admission = {"cell": cell, "planned_attempts": 30,
                    "expected_outer_seeds": seeds, "source_sha256": dict(SOURCE_HASHES),
                    "protocol_sha256": PROTOCOL_HASH}
        rows = [{"outer": i, "seed": seed, "status": "error", "success": False,
                 "failure_reason": "Julia failed before emitting an attempt result"}
                for i, seed in enumerate(seeds, 1)]
        with tempfile.TemporaryDirectory() as temporary:
            receipt = arc1_runner.assemble_cell_receipt(rows, admission,
                source_root=ROOT, artifact_root=Path(temporary))
        checked = verify(receipt, cell=cell, seeds=seeds)
        self.assertEqual(checked["attempts"], 30)
        self.assertEqual(checked["failures"], 30)
        failed = receipt["attempts"][0]
        self.assertIsNone(failed["point_estimates"])
        self.assertIsNone(failed["point_fit_not_optimal"])
        rank_cell = {"programme": "fa_rank", "phase": "development", "N": 80,
                     "signal": "null"}
        rank_seeds = [arc1_manifest.seed_for(rank_cell["programme"], rank_cell["phase"],
            rank_cell["N"], rank_cell["signal"], i, 0, "data")
            for i in range(1, arc1_manifest.FA_RANK_DEVELOPMENT_COUNT + 1)]
        rank_admission = {"cell": rank_cell,
                          "planned_attempts": arc1_manifest.FA_RANK_DEVELOPMENT_COUNT,
                          "expected_outer_seeds": rank_seeds,
                          "source_sha256": dict(SOURCE_HASHES),
                          "protocol_sha256": PROTOCOL_HASH}
        rank_rows = [{"outer": i, "seed": seed, "status": "error", "success": False,
                      "failure_reason": "Julia failed before emitting an attempt result"}
                     for i, seed in enumerate(rank_seeds, 1)]
        with tempfile.TemporaryDirectory() as temporary:
            rank_receipt = arc1_runner.assemble_cell_receipt(rank_rows, rank_admission,
                source_root=ROOT, artifact_root=Path(temporary))
        guards = rank_receipt["attempts"][0]["guard_results"]
        self.assertIsNone(guards["better_unaccepted"])
        self.assertIsNone(guards["nonnested"])
        self.assertEqual(guards["nesting_witness"]["status"], "not_evaluated")

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
        attempt["outer_selection"].update({"selection_status": "unavailable",
                                           "selected_rank": None,
                                           "guard_results": selector_guards(nonnested=True)})
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
