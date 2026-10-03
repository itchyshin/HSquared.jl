"""Synthetic aggregate tests; these are not study results or seed runs."""
from __future__ import annotations

import sys
import math
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from unittest import mock
from pathlib import Path

ROOT = __import__("pathlib").Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import arc1_gate_aggregate as gates
import arc1_manifest
import arc1_receipt_check as integrity


def rank_attempt(*, usable=True, rank="K0"):
    if rank == "K1":
        k0_raw, k1_raw, selected = -10.0, -5.0, "K1"
    else:
        k0_raw, k1_raw, selected = -10.0, -10.0, "K0"
    rows = {}
    for label, q, raw in (("K0", 14, k0_raw), ("K1", 18, k1_raw)):
        rows[label] = {"parameter_count": q, "aic_penalty": 2 * q,
                       "available": True, "status": "ok", "raw_loglik": raw,
                       "score": -2 * raw + 2 * q, "error_reason": None}
    return {"success": usable, "status": "ok" if usable else "selection_failed",
            "selection_status": "selected" if usable else "unavailable",
            "selected_rank": selected if usable else None,
            "rank_candidates": rows,
            "guard_results": {"schedule_complete": True, "better_unaccepted": False,
                "nonnested": not usable,
                "nesting_witness": {"status": "passed" if usable else "failed",
                    "discrepancy": 0.0 if usable else 0.1, "tolerance": 1e-4}}}


def truth_interval(target, truth, formed=True, covered=True):
    if not formed:
        segments = []
    elif covered:
        segments = [[truth - 0.01, truth + 0.01]]
    elif target in {"h2", "t"} or target.startswith("h2_"):
        segments = [[truth + 0.1, truth + 0.2]] if truth <= 0.8 else [[truth - 0.2, truth - 0.1]]
    else:
        segments = [[truth + 1.0, truth + 2.0]]
    return {"formed": formed, "segments": segments,
            "status": "formed" if formed else "outer_fit_failed",
            "refusal_status": None if formed else "fit failed", "formula": "test"}


def repeatability_checked(gate, phase, *, missing_formed=(), formation_count=None, coverage_count=None):
    checked = {}
    for cell in gates.required_cells(gate, phase):
        key = gates._cell_key(cell)
        truths = integrity._expected_interval_truths(cell)
        attempts = []
        for i in range(30 if phase == "pilot" else 400):
            rows = {target: truth_interval(target, truth,
                    formed=(key, target, i) not in missing_formed and
                        (formation_count is None or i < formation_count),
                    covered=coverage_count is None or i < coverage_count)
                    for target, truth in truths.items()}
            attempts.append({"outer": i + 1, "profile_intervals": rows})
        checked[key] = {"receipt": {"attempts": attempts}}
    return checked


def passing_reference(attempt, identity, *, variance=0.1):
    rows = []
    refinement = {"per_rank": 4}
    optimizer = arc1_manifest.SCIENTIFIC_CONTRACT["fa_optimizer"]
    k0_splits = optimizer["expanded_reference"]["K0_split"]
    k1_amplitudes = optimizer["expanded_reference"]["K1_amplitudes"]
    k1_signs = optimizer["expanded_reference"]["K1_signs"]
    uniqueness_floor = optimizer["ordinary"]["uniqueness_floor"]
    effective_variance = max(variance, 2 * uniqueness_floor)
    anchor_genetic = max(k0_splits[0] * effective_variance, 2 * uniqueness_floor)
    k0_diagonal = [anchor_genetic] * 4
    anchor_residual_diagonal = (1 - k0_splits[0]) * effective_variance
    anchor_residual = [[anchor_residual_diagonal if i == j else 0.0 for j in range(4)]
                       for i in range(4)]
    observation_order = {0: 0, 1: 0}
    for rank, count in ((0, 6), (1, 64)):
        label = f"K{rank}"
        loglik = attempt["rank_candidates"][label]["raw_loglik"]
        initial_selection = []
        for i in range(1, count + 1):
            start_name = f"{label}-start-{i}"
            if rank == 0:
                split = k0_splits[i - 1]
                genetic = [max(split * effective_variance, 2 * uniqueness_floor)] * 4
                residual_diag = (1 - split) * effective_variance
                residual = [[residual_diag if j == k else 0.0 for k in range(4)]
                            for j in range(4)]
                rchol = [math.log(math.sqrt(residual_diag)) if i == j else 0.0
                         for j in range(4) for i in range(j, 4)]
                params = [math.log(value - uniqueness_floor) for value in genetic] + rchol
                definition = {"rank": rank, "name": start_name, "split": split,
                              "genetic_diagonal": genetic, "residual_covariance": residual,
                              "params": params}
                start_params = definition["params"]
            else:
                amplitude = k1_amplitudes[(i - 1) // len(k1_signs)]
                signs = k1_signs[(i - 1) % len(k1_signs)]
                loading = [amplitude * sign * (value - uniqueness_floor) ** 0.5
                           for value, sign in zip(k0_diagonal, signs)]
                uniqueness = [value - loading_i ** 2
                              for value, loading_i in zip(k0_diagonal, loading)]
                anchor_rchol = [math.log(math.sqrt(anchor_residual_diagonal)) if i == j else 0.0
                                for j in range(4) for i in range(j, 4)]
                start_params = loading + [math.log(value - uniqueness_floor)
                                          for value in uniqueness] + anchor_rchol
                definition = {"rank": rank, "name": start_name,
                    "amplitude": amplitude, "signs": signs, "loading": loading,
                    "uniqueness": uniqueness, "params": start_params}
            observation_order[rank] += 1
            maximum = {"objective": -loglik, "raw_objective": -loglik,
                       "loglik": loglik, "params": start_params,
                       "rank": rank, "observation_order": observation_order[rank],
                       "source": "objective_callback",
                       "schedule_index": i}
            row = {"dataset_identity": identity, "rank": rank, "stage": "bfgs_initial",
                   "schedule_index": i, "start_name": start_name, "finite": True,
                   "start_definition": definition, "start_params": start_params,
                   "params": start_params,
                   "objective": -loglik, "raw_objective": -loglik, "loglik": loglik,
                   "iterations_budget": 10000, "intermediate_maxima": [maximum],
                   "intermediate_best": dict(maximum)}
            rows.append(row)
            if i <= 4:
                initial_selection.append({"start_name": start_name, "schedule_index": i,
                                          "params": start_params})
        refinement[f"k{rank}_initial"] = initial_selection
        refinement[f"k{rank}_nelder_mead"] = list(initial_selection)
        for stage in ("nelder_mead", "bfgs_final"):
            for selected in initial_selection:
                params = next(row["start_params"] for row in rows
                              if row["rank"] == rank and row["schedule_index"] == selected["schedule_index"])
                observation_order[rank] += 1
                maximum = {"objective": -loglik, "raw_objective": -loglik,
                           "loglik": loglik, "params": params,
                           "rank": rank, "observation_order": observation_order[rank],
                           "source": "objective_callback",
                           "schedule_index": selected["schedule_index"]}
                rows.append({"dataset_identity": identity, "rank": rank, "stage": stage,
                    "schedule_index": selected["schedule_index"],
                    "start_name": selected["start_name"], "finite": True,
                    "start_params": params, "params": params,
                    "objective": -loglik, "raw_objective": -loglik, "loglik": loglik,
                    "iterations_budget": 20000 if stage == "nelder_mead" else 10000,
                    "intermediate_maxima": [maximum], "intermediate_best": dict(maximum)})
    comparisons = {}
    for rank in (0, 1):
        candidate = attempt["rank_candidates"][f"K{rank}"]
        likelihood = candidate["raw_loglik"]
        comparisons[f"K{rank}"] = {"status": "compared", "passed": True,
            "ordinary_loglik": likelihood, "reference_loglik": likelihood,
            "shortfall": 0.0}
    k0_best_name = f"K0-start-1"
    k0_best_maximum = next(row["intermediate_best"] for row in rows
                           if row["rank"] == 0 and row["stage"] == "bfgs_initial" and
                           row["schedule_index"] == 1)
    k0_anchor = {"status": "available", "source": "best_finite_reference_k0",
        "start_name": k0_best_name, "source_stage": "bfgs_initial",
        "loglik": attempt["rank_candidates"]["K0"]["raw_loglik"],
        "genetic_diagonal": k0_diagonal,
        "residual_covariance": anchor_residual,
        "observation_order": k0_best_maximum["observation_order"],
        "observation_source": k0_best_maximum["source"]}
    return {"status": "best_found", "dataset_identity": identity, "rows": rows,
        "k0_anchor": k0_anchor,
        "starts_planned": {"K0": 6, "K1": 64},
        "optimizer_budgets": {"bfgs": 10000, "nelder_mead": 20000,
                               "retained_per_rank": 4},
        "refinement_selection": refinement, "rank_comparisons": comparisons,
        "phenotypic_variances": [variance] * 4,
        "phenotypic_variance_method": "retained_Y_sample_variance_nonpositive_fallback_1"}


def tagged_matrix(matrix):
    return {"__arc1_array__": True, "dims": [len(matrix), len(matrix[0])],
            "layout": "julia_column_major",
            "data": [matrix[i][j] for j in range(len(matrix[0])) for i in range(len(matrix))]}


def rank_phase_checked(gate, phase, k1_counts):
    checked = {}
    total = 30 if phase == "pilot" else 400
    for cell in gates.required_cells(gate, phase):
        key = gates._cell_key(cell)
        attempts = []
        k1_count = k1_counts.get((cell["N"], cell["signal"]), 0)
        for i in range(1, total + 1):
            row = rank_attempt(rank="K1" if i <= k1_count else "K0")
            identity = __import__("hashlib").sha256(f"{key}-{i}".encode()).hexdigest()
            row.update(outer=i, data_identity_sha256=identity,
                selection={"near_tie": False},
                candidate_summary={"K0": {"near_floor": False},
                                   "K1": {"near_floor": False}})
            if i <= 20:
                row["reference_audit"] = passing_reference(row, identity)
            attempts.append(row)
        checked[key] = {"receipt": {"attempts": attempts}}
    return checked


class Arc1ScientificGateTests(unittest.TestCase):
    def test_reference_flags_follow_frozen_selector_mapping_and_refusals_are_flagged(self):
        attempt = rank_attempt()
        self.assertIsNone(gates._reference_required(attempt, preselected=False))
        attempt.update({"selection": {"near_tie": False},
                        "candidate_summary": {"K0": {"near_floor": False},
                                              "K1": {"near_floor": False}}})
        self.assertFalse(gates._reference_required(attempt, preselected=False))
        attempt["guard_results"]["nonnested"] = True
        attempt["selection_status"] = "unavailable"
        attempt["selected_rank"] = None
        attempt["success"] = False
        self.assertTrue(gates._reference_required(attempt, preselected=False))
        attempt["reference_audit"] = {"status": "not_implemented"}
        self.assertEqual(gates._check_reference_audit(attempt),
                         (False, "required expanded-reference audit is missing or incomplete"))

    def test_reference_audit_rejects_failed_comparison_and_accepts_unavailable_rank_only_as_na(self):
        attempt = rank_attempt()
        identity = "d" * 64
        attempt["data_identity_sha256"] = identity
        attempt["reference_audit"] = passing_reference(attempt, identity)
        attempt["reference_audit"]["rank_comparisons"]["K1"].update(
            passed=False, shortfall=1.1e-4)
        ok, reason = gates._check_reference_audit(attempt)
        self.assertFalse(ok)
        self.assertIn("K1", reason)
        attempt["rank_candidates"]["K1"].update(available=False, status="failed",
            raw_loglik=None, score=None, error_reason="optimizer failed")
        attempt["reference_audit"]["rank_comparisons"]["K1"] = {
            "status": "not_applicable", "passed": False, "shortfall": None}
        self.assertEqual(gates._check_reference_audit(attempt), (True, None))

    def test_reference_audit_sees_earlier_retained_maximum_and_exact_schedule_multiplicity(self):
        attempt = rank_attempt()
        identity = "e" * 64
        attempt["data_identity_sha256"] = identity
        attempt["reference_audit"] = passing_reference(attempt, identity)
        rows = attempt["reference_audit"]["rows"]
        hidden = next(row for row in rows if row["rank"] == 0 and
                      row["stage"] == "bfgs_initial" and row["schedule_index"] == 2)
        better = -9.0
        hidden["objective"] = hidden["raw_objective"] = -better
        hidden["loglik"] = better
        hidden["intermediate_maxima"][-1].update(
            objective=-better, raw_objective=-better, loglik=better)
        # The final row's reported score is self-consistent, so only scanning every
        # retained maximum exposes that the K0 anchor is no longer the best start.
        self.assertEqual(gates._check_reference_audit(attempt)[0], False)

        attempt["reference_audit"] = passing_reference(attempt, identity)
        rows = attempt["reference_audit"]["rows"]
        duplicate = next(row for row in rows if row["rank"] == 1 and
                         row["stage"] == "bfgs_initial" and row["schedule_index"] == 2)
        duplicate["schedule_index"] = 1
        ok, reason = gates._check_reference_audit(attempt)
        self.assertFalse(ok)
        self.assertIn("schedule", reason)

    def test_reference_audit_rejects_all_reviewed_provenance_bypasses(self):
        mutations = (
            lambda audit: [row.update(start_params=[999.0]) for row in audit["rows"]
                           if row["stage"] in {"nelder_mead", "bfgs_final"}],
            lambda audit: [row["start_definition"].update(uniqueness=[999.0] * 4)
                           for row in audit["rows"] if row["rank"] == 1 and
                           row["stage"] == "bfgs_initial"],
            lambda audit: audit["k0_anchor"].update(source="analytic_split_fallback", split=0.5),
            lambda audit: next(row for row in audit["rows"] if row["rank"] == 0 and
                               row["stage"] == "bfgs_initial")["intermediate_best"].update(loglik=0.0),
            lambda audit: [row.update(iterations_budget=1) for row in audit["rows"]
                           if row["stage"] != "start_generation"],
        )
        for mutate in mutations:
            with self.subTest(mutation=mutate):
                attempt = rank_attempt()
                identity = "f" * 64
                attempt["data_identity_sha256"] = identity
                attempt["reference_audit"] = passing_reference(attempt, identity)
                mutate(attempt["reference_audit"])
                self.assertFalse(gates._check_reference_audit(attempt)[0])

    def test_reference_audit_binds_full_parameter_vectors_to_start_definitions(self):
        identity = "a" * 64
        def mutate_k0_params(audit):
            audit["rows"][0]["start_params"][0] = 999.0
        def mutate_k1_params(audit):
            row = next(row for row in audit["rows"] if row["rank"] == 1 and
                       row["stage"] == "bfgs_initial")
            row["start_params"][4] = 999.0
        def mutate_k1_definition_params(audit):
            row = next(row for row in audit["rows"] if row["rank"] == 1 and
                       row["stage"] == "bfgs_initial")
            row["start_definition"]["params"][4] = 999.0
        for mutate in (mutate_k0_params, mutate_k1_params, mutate_k1_definition_params,
                       lambda audit: audit["k0_anchor"]["residual_covariance"][0].__setitem__(0, 999.0)):
            with self.subTest(mutation=mutate):
                attempt = rank_attempt()
                attempt["data_identity_sha256"] = identity
                attempt["reference_audit"] = passing_reference(attempt, identity)
                mutate(attempt["reference_audit"])
                self.assertFalse(gates._check_reference_audit(attempt)[0])

    def test_reference_audit_rejects_nonchronological_retained_maxima(self):
        attempt = rank_attempt()
        identity = "b" * 64
        attempt["data_identity_sha256"] = identity
        attempt["reference_audit"] = passing_reference(attempt, identity)
        row = next(row for row in attempt["reference_audit"]["rows"]
                   if row["rank"] == 0 and row["stage"] == "bfgs_initial")
        first = dict(row["intermediate_maxima"][0], observation_order=9)
        later = dict(first, observation_order=3, loglik=row["loglik"] + 1.0,
                     objective=row["objective"] - 1.0,
                     raw_objective=row["raw_objective"] - 1.0)
        row["intermediate_maxima"] = [first, later]
        row.update(loglik=later["loglik"], objective=later["objective"],
                   raw_objective=later["raw_objective"], params=later["params"],
                   intermediate_best=dict(later))
        self.assertFalse(gates._check_reference_audit(attempt)[0])

    def test_reference_audit_uses_retained_y_scale_and_native_tagged_matrices(self):
        attempt = rank_attempt()
        identity = "c" * 64
        attempt["data_identity_sha256"] = identity
        audit = passing_reference(attempt, identity, variance=1e-12)
        self.assertEqual(gates._check_reference_audit({**attempt, "reference_audit": audit}),
                         (True, None))
        # Native Julia matrices arrive tagged and column-major. The consumer
        # must decode those bytes/values rather than requiring test-only lists.
        audit["k0_anchor"]["residual_covariance"] = tagged_matrix(
            audit["k0_anchor"]["residual_covariance"])
        for row in audit["rows"]:
            definition = row.get("start_definition", {})
            if row["rank"] == 0 and "residual_covariance" in definition:
                definition["residual_covariance"] = tagged_matrix(definition["residual_covariance"])
        self.assertEqual(gates._check_reference_audit({**attempt, "reference_audit": audit}),
                         (True, None))
        audit["phenotypic_variances"] = [0.1] * 4
        self.assertFalse(gates._check_reference_audit({**attempt, "reference_audit": audit})[0])

    def test_reference_audit_rejects_rank_wide_duplicate_orders_and_extra_rank_rows(self):
        identity = "d" * 64
        attempt = rank_attempt()
        attempt["data_identity_sha256"] = identity
        attempt["reference_audit"] = passing_reference(attempt, identity)
        rows = attempt["reference_audit"]["rows"]
        first = next(row for row in rows if row["rank"] == 0 and row["stage"] == "bfgs_initial")
        second = next(row for row in rows if row["rank"] == 0 and
                      row["stage"] == "bfgs_initial" and row["schedule_index"] == 2)
        second["intermediate_maxima"][0]["observation_order"] = \
            first["intermediate_maxima"][0]["observation_order"]
        second["intermediate_best"]["observation_order"] = \
            first["intermediate_maxima"][0]["observation_order"]
        self.assertFalse(gates._check_reference_audit(attempt)[0])
        attempt["reference_audit"] = passing_reference(attempt, identity)
        forged = dict(attempt["reference_audit"]["rows"][0])
        forged["rank"] = 2
        forged["intermediate_maxima"] = [dict(forged["intermediate_maxima"][0], rank=2)]
        attempt["reference_audit"]["rows"].append(forged)
        self.assertFalse(gates._check_reference_audit(attempt)[0])

    def test_reference_audit_rejects_every_unsupported_row_schedule(self):
        identity = "e" * 64

        def fresh():
            attempt = rank_attempt()
            attempt["data_identity_sha256"] = identity
            attempt["reference_audit"] = passing_reference(attempt, identity)
            return attempt

        # An empty failed row used to evade rank validation because that check
        # only ran while traversing retained maxima.
        attempt = fresh()
        attempt["reference_audit"]["rows"].append({
            "dataset_identity": identity, "rank": 2, "stage": "bfgs_initial",
            "schedule_index": 1, "iterations_budget": 10_000, "finite": False,
            "status": "failed", "params": [], "intermediate_maxima": [],
            "intermediate_best": None})
        self.assertFalse(gates._check_reference_audit(attempt)[0])

        # An unknown stage used to bypass the stage-specific budget check and
        # remain invisible to both selected-refinement and maxima ledgers.
        attempt = fresh()
        extra = dict(next(row for row in attempt["reference_audit"]["rows"]
                          if row["rank"] == 1 and row["stage"] == "bfgs_initial"))
        extra.update(stage="unscheduled_refinement", schedule_index=999,
                     iterations_budget=999_999)
        attempt["reference_audit"]["rows"].append(extra)
        self.assertFalse(gates._check_reference_audit(attempt)[0])

        attempt = fresh()
        extra = dict(attempt["reference_audit"]["rows"][0], stage=["malformed"])
        attempt["reference_audit"]["rows"].append(extra)
        self.assertFalse(gates._check_reference_audit(attempt)[0])

        # A known refinement stage is still invalid when it is not one of the
        # exact selected (start_name, schedule_index) pairs.
        attempt = fresh()
        extra = dict(next(row for row in attempt["reference_audit"]["rows"]
                          if row["rank"] == 1 and row["stage"] == "nelder_mead"))
        extra["start_name"] = "K1-unselected-start"
        attempt["reference_audit"]["rows"].append(extra)
        self.assertFalse(gates._check_reference_audit(attempt)[0])

    def test_reference_audit_preserves_legitimate_failed_scheduled_start(self):
        identity = "f" * 64
        attempt = rank_attempt()
        attempt["data_identity_sha256"] = identity
        audit = passing_reference(attempt, identity)
        failed = next(row for row in audit["rows"] if row["rank"] == 0 and
                      row["stage"] == "bfgs_initial" and row["schedule_index"] == 6)
        failed.update(finite=False, status="failed", failure_reason="synthetic optimizer failure",
                      params=list(failed["start_params"]), objective=math.inf,
                      raw_objective=math.inf, loglik=-math.inf,
                      intermediate_maxima=[], intermediate_best=None)
        attempt["reference_audit"] = audit
        self.assertEqual(gates._check_reference_audit(attempt), (True, None))

    def test_native_julia_reference_json_is_accepted_by_aggregator(self):
        julia = shutil.which("julia")
        self.assertIsNotNone(julia, "Julia is required; this producer-consumer test must not skip")
        with tempfile.TemporaryDirectory(prefix="arc1-native-reference-") as temporary:
            folder = Path(temporary)
            output = folder / "native-audit.json"
            depot = folder / "depot"
            depot.mkdir()
            env = dict(os.environ, ARC1_NATIVE_AUDIT_OUT=str(output),
                JULIA_DEPOT_PATH=os.pathsep.join((str(depot), str(Path.home() / ".julia"))),
                JULIA_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1")
            command = [julia, "--startup-file=no", "--threads=1", f"--project={ROOT}",
                "-e", 'using Test, HSquared; include("test/arc1_simulation_reference.jl")']
            result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True,
                text=True, timeout=120)
            self.assertEqual(result.returncode, 0, result.stdout + "\\n" + result.stderr)
            self.assertTrue(output.is_file(), result.stdout + "\\n" + result.stderr)
            audit = json.loads(output.read_text(encoding="utf-8"))
        attempt = rank_attempt()
        attempt["data_identity_sha256"] = audit["dataset_identity"]
        for rank in ("K0", "K1"):
            ordinary = audit["rank_comparisons"][rank]["ordinary_loglik"]
            attempt["rank_candidates"][rank]["raw_loglik"] = ordinary
            attempt["rank_candidates"][rank]["score"] = (
                -2 * ordinary + attempt["rank_candidates"][rank]["aic_penalty"])
        attempt["reference_audit"] = audit
        self.assertTrue(gates._check_reference_audit(attempt)[0],
            gates._check_reference_audit(attempt)[1])

    def test_gate_entrypoint_requires_every_cell_and_calls_integrity_verifier(self):
        cell = gates.required_cells("G2", "pilot")[0]
        envelope = {"receipt": {}, "pins": {"expected_cell": cell,
            "expected_seeds": [], "expected_source_hashes": {},
            "expected_protocol_sha256": "0" * 64,
            "expected_source_root": str(ROOT), "expected_artifact_root": str(ROOT / ".tmp"),
            "expected_admission": {"environment_sha256": {}}}}
        with mock.patch.object(gates.integrity, "verify_receipt", return_value={}) as verify:
            with self.assertRaisesRegex(gates.GateError, "missing one or more required cells"):
                gates.aggregate_gate("G2", "pilot", [envelope])
        verify.assert_called_once()

    def test_rank_confirmation_uses_all_attempts_and_holds_failed_eligibility(self):
        checked = {}
        for cell in gates.required_cells("G3", "confirmation"):
            key = gates._cell_key(cell)
            attempts = []
            for i in range(400):
                usable = not (cell["N"] == 80 and cell["signal"] == "null" and i < 40)
                rank = "K1" if ((cell["N"], cell["signal"]) == (160, "null") and i < 50 or
                                 (cell["N"], cell["signal"]) == (320, "strong") and i < 340) else "K0"
                row = rank_attempt(usable=usable, rank=rank)
                row.update({"outer": i + 1, "data_identity_sha256": "d" * 64,
                    "selection": {"near_tie": False},
                    "candidate_summary": {"K0": {"near_floor": False},
                                          "K1": {"near_floor": False}}})
                attempts.append(row)
            checked[key] = {"receipt": {"attempts": attempts}}
        result = gates._rank_rollup("G3", "confirmation", checked)
        null = next(row for row in result["cell_metrics"] if
                    row["cell"] == {"programme": "fa_rank", "phase": "confirmation",
                                    "N": 160, "signal": "null"})
        self.assertEqual(null["attempts"], 400)
        self.assertEqual(null["selected_K1"], 50)
        weak = next(row for row in result["cell_metrics"] if row["cell"]["N"] == 80 and
                    row["cell"]["signal"] == "null")
        self.assertEqual(weak["usable"], 360)
        self.assertEqual(result["numerical_screen"], "HOLD")
        self.assertEqual(result["confirmation_allocation"], "HOLD")
        self.assertIsNone(result["success_marker"])

    def test_g3_null_selection_rule_applies_to_each_sample_size(self):
        pilot = rank_phase_checked("G3", "pilot", {(160, "null"): 1, (80, "null"): 7,
                                                     (320, "strong"): 24})
        self.assertEqual(gates._rank_rollup("G3", "pilot", pilot)["selection_rule"], "HOLD")
        confirmation = rank_phase_checked("G3", "confirmation", {(160, "null"): 1,
            (80, "null"): 120, (320, "strong"): 340})
        confirmed = gates._rank_rollup("G3", "confirmation", confirmation)
        weak = next(row for row in confirmed["cell_metrics"] if
                    row["cell"]["N"] == 80 and row["cell"]["signal"] == "null")
        self.assertGreater(weak["K1_selection_wilson95"][1], 0.20)
        self.assertEqual(confirmed["selection_rule"], "HOLD")

    def test_g5_confirmation_cannot_pass_without_zero_diagnostic_receipts(self):
        self.assertEqual(len(gates.required_cells("G5", "confirmation")), 9)
        all_required = [*gates.required_cells("G5", "confirmation"),
                        *gates.required_cells("G5", "diagnostic")]
        self.assertEqual(len(all_required), 11)
        self.assertEqual(len([c for c in all_required if c["programme"] == "boundary"]), 2)
        self.assertFalse(gates.requested_gate_passed({"confirmation_result": "FAIL"}, "confirmation"))
        self.assertTrue(gates.requested_gate_passed({"diagnostic_receipts": "PASS"}, "diagnostic"))

    def test_complete_rank_pilot_and_confirmation_emit_distinct_markers(self):
        pilot = rank_phase_checked("G2", "pilot", {(160, "null"): 6, (320, "strong"): 24})
        pilot_result = gates._rank_rollup("G2", "pilot", pilot)
        self.assertEqual(pilot_result["pilot_qualification"], "PASS")
        self.assertEqual(pilot_result["success_marker"], "ARC1_G2_PILOT_QUALIFIED")
        self.assertEqual(pilot_result["confirmation_allocation"], "HOLD")
        confirmation = rank_phase_checked("G3", "confirmation",
            {(160, "null"): 50, (320, "strong"): 340})
        confirmation_result = gates._rank_rollup("G3", "confirmation", confirmation)
        self.assertEqual(confirmation_result["confirmation_result"], "PASS")
        self.assertEqual(confirmation_result["success_marker"], "ARC1_G3_CONFIRMATION_PASS")
        self.assertEqual(confirmation_result["confirmation_allocation"], "HOLD")

    def test_g2_confirmation_requires_all_nine_cells_reference_audits_and_k1_witness(self):
        checked = rank_phase_checked("G2", "confirmation", {(80, "weak"): 1})
        result = gates._rank_rollup("G2", "confirmation", checked)
        self.assertEqual(len(result["cell_metrics"]), 9)
        self.assertEqual(result["numerical_screen"], "PASS")
        self.assertEqual(result["reference_audits"], "PASS")
        self.assertEqual(result["ordinary_K1_witness"], "PASS")
        self.assertEqual(result["confirmation_result"], "PASS")
        self.assertEqual(result["success_marker"], "ARC1_G2_CONFIRMATION_PASS")
        self.assertEqual(len(gates.required_cells("G2", "pilot")), 9)
        self.assertEqual(len(gates.required_cells("G2", "confirmation")), 9)

    def test_g5_exact_zero_diagnostic_cells_are_complete_but_noninferential(self):
        self.assertEqual([(cell["signal"], cell["N"]) for cell in
                          gates.required_cells("G5", "diagnostic")],
                         [("Va_zero", 160), ("Vpe_zero", 160)])
        checked = {}
        for cell in gates.required_cells("G5", "diagnostic"):
            attempts = [{"profile_intervals": {target: {"formed": False,
                "status": "unresolved_boundary"} for target in ("Va", "Vpe", "Ve", "h2", "t")}}
                for _ in range(200)]
            checked[gates._cell_key(cell)] = {"receipt": {"attempts": attempts}}
        result = gates._boundary_diagnostic_rollup(checked)
        self.assertEqual(result["diagnostic_receipts"], "PASS")
        self.assertEqual(result["nominal_coverage_claim"],
                         "NONE; descriptive exact-zero diagnostics only")
        self.assertIsNone(result["success_marker"])
        self.assertEqual([row["attempts"] for row in result["cell_metrics"]], [200, 200])

    def test_repeatability_pilot_checks_each_estimand_and_counts_failures(self):
        cell = ("repeatability", "pilot", 80, "interior")
        checked = repeatability_checked("G5", "pilot", missing_formed={(cell, "Va", i)
                                                                    for i in range(2)})
        result = gates._interval_rollup("G5", "pilot", checked)
        target = next(row for item in result["cell_metrics"] if
                      gates._cell_key(item["cell"]) == cell
                      for row in [item["targets"]["Va"]])
        self.assertEqual(target["formed"], 28)
        self.assertEqual(target["formation_denominator"], 30)
        self.assertEqual(target["covered"], 28)
        self.assertEqual(result["pilot_qualification"], "HOLD")
        self.assertIsNone(result["success_marker"])
        self.assertFalse(gates.requested_gate_passed(result, "pilot"))
        self.assertEqual(result["confirmation_allocation"], "HOLD")

    def test_complete_repeatability_pilot_emits_only_pilot_qualification(self):
        checked = repeatability_checked("G5", "pilot")
        result = gates._interval_rollup("G5", "pilot", checked)
        self.assertEqual(result["pilot_qualification"], "PASS")
        self.assertEqual(result["success_marker"], "ARC1_G5_PILOT_QUALIFIED")
        self.assertEqual(result["confirmation_result"], "NOT_RUN")
        self.assertEqual(result["confirmation_allocation"], "HOLD")

    def test_complete_repeatability_confirmation_uses_coverage_confidence_interval(self):
        checked = repeatability_checked("G5", "confirmation", formation_count=396,
                                        coverage_count=380)
        result = gates._interval_rollup("G5", "confirmation", checked)
        self.assertEqual(result["confirmation_result"], "PASS")
        self.assertEqual(result["success_marker"], "ARC1_G5_CONFIRMATION_PASS")
        self.assertEqual(result["confirmation_allocation"], "HOLD")

    def test_fa_pilot_requires_all_nested_endpoint_comparisons(self):
        checked = {}
        for cell in gates.required_cells("G4", "pilot"):
            key = gates._cell_key(cell)
            truths = integrity._expected_interval_truths(cell)
            attempts = []
            for i in range(30):
                intervals = {target: truth_interval(target, truth) for target, truth in truths.items()}
                pooled = i * len(arc1_manifest.FA_SIGNALS) + arc1_manifest.FA_SIGNALS.index(cell["signal"]) + 1
                prefixes = []
                if pooled <= 20:
                    for budget in (199, 499, 999):
                        prefixes.append({"B": budget, "usable_inner": budget,
                            "intervals": {target: truth_interval(target, truth)
                                          for target, truth in truths.items()}})
                    if cell["signal"] == "null" and i == 0:
                        prefixes.pop()  # Missing fixed endpoint evidence must hold G4.
                attempts.append({"outer": i + 1,
                    "bootstrap": {"stage": "started", "intervals": intervals,
                                  "prefix_results": prefixes}})
            checked[key] = {"receipt": {"attempts": attempts}}
        result = gates._interval_rollup("G4", "pilot", checked)
        self.assertEqual(result["nested_endpoint_stability"]["required"], 20)
        self.assertEqual(result["nested_endpoint_stability"]["observed"], 20)
        self.assertEqual(result["nested_endpoint_stability"]["within_002"], 19)
        self.assertEqual(result["pilot_qualification"], "HOLD")
        self.assertIsNone(result["success_marker"])
        self.assertFalse(gates.requested_gate_passed(result, "pilot"))
        first_null = checked[("fa_interval", "pilot", 160, "null")]["receipt"]["attempts"][0]
        truth = integrity._expected_interval_truths(
            {"programme": "fa_interval", "phase": "pilot", "N": 160, "signal": "null"})
        first_null["bootstrap"]["prefix_results"].append({"B": 999, "usable_inner": 999,
            "intervals": {target: truth_interval(target, value) for target, value in truth.items()}})
        passed = gates._interval_rollup("G4", "pilot", checked)
        self.assertEqual(passed["pilot_qualification"], "PASS")
        self.assertEqual(passed["nested_endpoint_stability"]["within_002"], 20)
        self.assertEqual(passed["success_marker"], "ARC1_G4_PILOT_QUALIFIED")


if __name__ == "__main__":
    unittest.main()
