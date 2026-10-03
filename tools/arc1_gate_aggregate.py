#!/usr/bin/env python3
"""Scientific rollups for integrity-verified Arc1 cell receipts.

This module evaluates frozen pilot screens and confirmation rules. It never
admits or launches a study; a successful pilot result leaves 400-attempt
confirmation allocations held for a separate explicit decision.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Any

import arc1_manifest as manifest
import arc1_receipt_check as integrity


class GateError(ValueError):
    """Gate inputs are incomplete or do not match the frozen design."""


def _need(ok: bool, message: str) -> None:
    if not ok:
        raise GateError(message)


def _cell_key(cell: dict[str, Any]) -> tuple[str, str, int, str]:
    return (cell["programme"], cell["phase"], int(cell["N"]), cell["signal"])


def required_cells(gate: str, phase: str) -> list[dict[str, Any]]:
    _need(gate in {"G2", "G3", "G4", "G5"}, "gate must be G2, G3, G4, or G5")
    allowed_phases = {"pilot", "confirmation"} | ({"diagnostic"} if gate == "G5" else set())
    _need(phase in allowed_phases, "scientific gate phase is not defined for this gate")
    if gate == "G5" and phase == "diagnostic":
        return [{"programme": "boundary", "phase": "diagnostic", "N": 160,
                 "signal": signal} for signal in ("Va_zero", "Vpe_zero")]
    if gate in {"G2", "G3"}:
        return [{"programme": "fa_rank", "phase": phase, "N": n, "signal": signal}
                for n in (80, 160, 320) for signal in manifest.FA_SIGNALS]
    if gate == "G4":
        return [{"programme": "fa_interval", "phase": phase, "N": 160, "signal": signal}
                for signal in manifest.FA_SIGNALS]
    return [{"programme": "repeatability", "phase": phase, "N": n, "signal": signal}
            for n in (80, 160, 320) for signal in manifest.REPEATABILITY_SIGNALS]


def _usable_rank(attempt: dict[str, Any]) -> bool:
    guards = attempt.get("guard_results")
    return (attempt.get("selection_status") == "selected" and
            attempt.get("selected_rank") in {"K0", "K1"} and
            attempt.get("success") is True and isinstance(guards, dict) and
            guards.get("schedule_complete") is True and
            guards.get("better_unaccepted") is False and
            guards.get("nonnested") is False and
            isinstance(guards.get("nesting_witness"), dict) and
            guards["nesting_witness"].get("status") == "passed")


def _near_floor_flags(attempt: dict[str, Any]) -> dict[str, bool] | None:
    """Frozen flag mapping: selection.near_tie; candidate_summary[K].near_floor."""
    selection = attempt.get("selection")
    candidates = attempt.get("candidate_summary")
    if not isinstance(selection, dict) or type(selection.get("near_tie")) is not bool:
        return None
    if not isinstance(candidates, dict) or set(candidates) != {"K0", "K1"}:
        return None
    flags: dict[str, bool] = {}
    for rank in ("K0", "K1"):
        row = candidates[rank]
        if not isinstance(row, dict) or type(row.get("near_floor")) is not bool:
            return None
        flags[rank] = row["near_floor"]
    candidates_rank = attempt.get("rank_candidates")
    if not isinstance(candidates_rank, dict) or not all(
            isinstance(candidates_rank.get(rank), dict) and
            isinstance(candidates_rank[rank].get("score"), (int, float)) and
            math.isfinite(candidates_rank[rank]["score"]) for rank in ("K0", "K1")):
        return None
    recomputed_near_tie = abs(float(candidates_rank["K0"]["score"]) -
                              float(candidates_rank["K1"]["score"])) <= 1e-6
    if selection["near_tie"] is not recomputed_near_tie:
        return None
    return {"near_tie": recomputed_near_tie, **{f"{rank}_near_floor": value
                                                     for rank, value in flags.items()}}


def _reference_required(attempt: dict[str, Any], *, preselected: bool) -> bool | None:
    if preselected or not _usable_rank(attempt):
        return True
    flags = _near_floor_flags(attempt)
    if flags is None:
        return None
    return flags["near_tie"] or flags["K0_near_floor"] or flags["K1_near_floor"]


def _decode_reference_matrix(value: Any) -> Any:
    """Decode the native Julia column-major matrix wire form without guessing."""
    if not isinstance(value, dict) or value.get("__arc1_array__") is not True:
        return value
    dims, layout, data = value.get("dims"), value.get("layout"), value.get("data")
    if (not isinstance(dims, list) or len(dims) != 2 or
            any(type(size) is not int or size <= 0 for size in dims) or
            layout != "julia_column_major" or not isinstance(data, list) or
            len(data) != dims[0] * dims[1]):
        return None
    nrow, ncol = dims
    return [[data[i + nrow * j] for j in range(ncol)] for i in range(nrow)]


def _reference_cholesky_params(matrix: Any) -> list[float] | None:
    """Independently encode a 4x4 covariance using the frozen lower-Cholesky order."""
    matrix = _decode_reference_matrix(matrix)
    if (not isinstance(matrix, list) or len(matrix) != 4 or
            any(not isinstance(row, list) or len(row) != 4 for row in matrix) or
            any(not isinstance(value, (int, float)) or not math.isfinite(value)
                for row in matrix for value in row)):
        return None
    a = [[float(value) for value in row] for row in matrix]
    if any(abs(a[i][j] - a[j][i]) > 1e-12 for i in range(4) for j in range(4)):
        return None
    lower = [[0.0] * 4 for _ in range(4)]
    try:
        for i in range(4):
            for j in range(i + 1):
                residual = a[i][j] - sum(lower[i][k] * lower[j][k] for k in range(j))
                if i == j:
                    if residual <= 0 or not math.isfinite(residual):
                        return None
                    lower[i][j] = math.sqrt(residual)
                else:
                    lower[i][j] = residual / lower[j][j]
        return [math.log(lower[i][j]) if i == j else lower[i][j]
                for j in range(4) for i in range(j, 4)]
    except (OverflowError, ValueError, ZeroDivisionError):
        return None


def _reference_cholesky_covariance(params: Any) -> list[list[float]] | None:
    if (not isinstance(params, list) or len(params) != 10 or
            any(not isinstance(value, (int, float)) or not math.isfinite(value)
                for value in params)):
        return None
    lower = [[0.0] * 4 for _ in range(4)]
    index = 0
    try:
        for j in range(4):
            for i in range(j, 4):
                value = float(params[index])
                lower[i][j] = math.exp(value) if i == j else value
                index += 1
    except OverflowError:
        return None
    covariance = [[sum(lower[i][k] * lower[j][k] for k in range(4))
                   for j in range(4)] for i in range(4)]
    return covariance if all(math.isfinite(value) for row in covariance for value in row) else None


def _reference_matrix_matches(observed: Any, expected: list[list[float]]) -> bool:
    observed = _decode_reference_matrix(observed)
    return (isinstance(observed, list) and len(observed) == len(expected) and
            all(isinstance(row, list) and len(row) == len(expected[i]) for i, row in enumerate(observed)) and
            all(isinstance(value, (int, float)) and math.isfinite(value) and
                math.isclose(float(value), target, rel_tol=1e-12, abs_tol=1e-12)
                for row, targets in zip(observed, expected) for value, target in zip(row, targets)))


def _reference_vector_matches(observed: Any, expected: list[float]) -> bool:
    return (isinstance(observed, list) and len(observed) == len(expected) and
            all(isinstance(value, (int, float)) and math.isfinite(value) and
                math.isclose(float(value), target, rel_tol=1e-12, abs_tol=1e-12)
                for value, target in zip(observed, expected)))


def _reference_exp(value: Any) -> float | None:
    if not isinstance(value, (int, float)) or not math.isfinite(value):
        return None
    try:
        result = math.exp(float(value))
    except OverflowError:
        return None
    return result if math.isfinite(result) else None


def _check_reference_audit(attempt: dict[str, Any]) -> tuple[bool, str | None]:
    audit = attempt.get("reference_audit")
    if not isinstance(audit, dict) or audit.get("status") != "best_found":
        return False, "required expanded-reference audit is missing or incomplete"
    identity = attempt.get("data_identity_sha256")
    if not isinstance(identity, str) or audit.get("dataset_identity") != identity:
        return False, "reference audit does not share the retained outer-data identity"
    rows = audit.get("rows")
    if not isinstance(rows, list) or not rows:
        return False, "reference audit lacks its deterministic evaluation ledger"
    if any(not isinstance(row, dict) or row.get("dataset_identity") != identity for row in rows):
        return False, "reference ledger contains a different dataset identity"
    # Validate every row before any schedule filtering or maxima aggregation.
    # Otherwise unknown stages/ranks can disappear from those filtered views.
    allowed_stages = {"start_generation", "bfgs_initial", "nelder_mead", "bfgs_final"}
    stage_budgets = {"start_generation": 0, "bfgs_initial": 10_000,
                     "nelder_mead": 20_000, "bfgs_final": 10_000}
    for row in rows:
        rank, stage = row.get("rank"), row.get("stage")
        if type(rank) is not int or rank not in (0, 1):
            return False, "reference ledger contains an unsupported rank"
        if not isinstance(stage, str) or stage not in allowed_stages:
            return False, "reference ledger contains an unsupported stage"
        if not isinstance(row.get("start_name"), str) or not row["start_name"]:
            return False, "reference ledger contains an unsupported start identity"
        if stage == "start_generation" and rank != 0:
            return False, "reference ledger contains an unsupported initialization stage"
        index = row.get("schedule_index")
        rank_count = 6 if rank == 0 else 64
        if type(index) is not int or not 1 <= index <= rank_count:
            return False, "reference ledger contains an unsupported schedule index"
        budget = row.get("iterations_budget")
        if type(budget) is not int or budget != stage_budgets[stage]:
            return False, "reference ledger row differs from the frozen optimizer budget"
    planned = audit.get("starts_planned")
    if planned != {"K0": 6, "K1": 64}:
        return False, "reference start schedule differs from frozen per-rank design"
    budgets = audit.get("optimizer_budgets")
    if budgets != {"bfgs": 10000, "nelder_mead": 20000, "retained_per_rank": 4}:
        return False, "reference optimizer budgets differ from the frozen per-rank schedule"
    refinement = audit.get("refinement_selection")
    if not isinstance(refinement, dict) or refinement.get("per_rank") != 4:
        return False, "reference audit lacks the retained per-rank refinement selections"
    k0_anchor = audit.get("k0_anchor")
    if not isinstance(k0_anchor, dict) or k0_anchor.get("status") != "available":
        return False, "reference audit lacks the retained K0 anchor provenance"
    scale = audit.get("phenotypic_variances")
    if (audit.get("phenotypic_variance_method") !=
            "retained_Y_sample_variance_nonpositive_fallback_1" or
            not isinstance(scale, list) or len(scale) != 4 or
            any(not isinstance(value, (int, float)) or not math.isfinite(value) or value <= 0
                for value in scale)):
        return False, "reference start scale lacks finite retained-Y sample variances"
    source_by_rank: dict[int, dict[tuple[str, int], dict[str, Any]]] = {}
    for rank, count in ((0, 6), (1, 64)):
        label = f"K{rank}"
        initial_rows = [row for row in rows if row.get("rank") == rank and
                        row.get("stage") in {"bfgs_initial", "start_generation"}]
        indices = [row.get("schedule_index") for row in initial_rows]
        names = [row.get("start_name") for row in initial_rows]
        if (len(initial_rows) != count or set(indices) != set(range(1, count + 1)) or
                len(set(indices)) != count or len(set(names)) != count):
            return False, f"{label} reference initial schedule ledger is incomplete"
        if any(type(index) is not int for index in indices):
            return False, f"{label} reference schedule indices are malformed"
        initial_by_index = {row["schedule_index"]: row for row in initial_rows}
        source_by_rank[rank] = {(str(row.get("start_name")), int(row["schedule_index"])): row
                                for row in initial_rows}
        for row in initial_rows:
            definition = row.get("start_definition")
            if (not isinstance(definition, dict) or definition.get("rank") != rank or
                    str(definition.get("name")) != str(row.get("start_name"))):
                return False, f"{label} initial row lost its start-definition/parameter provenance"
            if row.get("stage") == "start_generation":
                if (row.get("finite") is not False or definition.get("params") not in (None, []) or
                        row.get("params") not in (None, [])):
                    return False, f"{label} invalid initial row has inconsistent not-run parameter provenance"
            elif (definition.get("params") != row.get("start_params") or
                  (row.get("finite") is False and row.get("params") != row.get("start_params"))):
                return False, f"{label} initial row lost its start-definition/parameter provenance"
        expected_defs = (manifest.SCIENTIFIC_CONTRACT["fa_optimizer"]["expanded_reference"]["K0_split"]
                         if rank == 0 else None)
        floor = float(manifest.SCIENTIFIC_CONTRACT["fa_optimizer"]["ordinary"]["uniqueness_floor"])
        if rank == 0:
            for index, split in enumerate(expected_defs, start=1):
                row = initial_by_index[index]
                definition = row.get("start_definition", {})
                try:
                    observed_split = float(definition.get("split", math.nan))
                except (TypeError, ValueError, OverflowError):
                    observed_split = math.nan
                if not math.isfinite(observed_split) or not math.isclose(
                        observed_split, float(split), rel_tol=0, abs_tol=1e-15):
                    return False, "K0 start provenance differs from the frozen split schedule"
                genetic = definition.get("genetic_diagonal")
                residual = definition.get("residual_covariance")
                residual = _decode_reference_matrix(residual)
                rchol = _reference_cholesky_params(residual)
                if (not isinstance(genetic, list) or len(genetic) != 4 or rchol is None or
                        any(not isinstance(value, (int, float)) or not math.isfinite(value) or
                            value <= floor for value in genetic)):
                    return False, "K0 mathematical start lacks finite genetic and residual covariance values"
                phenotypic = [float(value) for value in scale]
                effective = [max(value, 2 * float(floor)) for value in phenotypic]
                expected_genetic = [max(observed_split * value,
                                        2 * float(floor)) for value in effective]
                expected_residual_diagonal = [
                    (1 - observed_split) * value for value in effective]
                if (not _reference_vector_matches(genetic, expected_genetic) or
                        any(not math.isclose(float(residual[j][j]), expected_residual_diagonal[j],
                                             rel_tol=1e-12, abs_tol=1e-12) for j in range(4)) or
                        any(abs(float(residual[j][k])) > 1e-12
                            for j in range(4) for k in range(4) if j != k)):
                    return False, "K0 start components do not derive from the frozen split definition"
                expected_params = [math.log(float(value) - float(floor)) for value in genetic] + rchol
                if not _reference_vector_matches(definition.get("params"), expected_params):
                    return False, "K0 encoded start parameters do not derive from their mathematical definition"
                if not _reference_vector_matches(row.get("start_params"), expected_params):
                    return False, "K0 retained start parameters do not match their encoded mathematical start"
        else:
            amplitudes = manifest.SCIENTIFIC_CONTRACT["fa_optimizer"]["expanded_reference"]["K1_amplitudes"]
            signs = manifest.SCIENTIFIC_CONTRACT["fa_optimizer"]["expanded_reference"]["K1_signs"]
            anchor_diag = k0_anchor.get("genetic_diagonal")
            if (not isinstance(anchor_diag, list) or len(anchor_diag) != 4 or
                    not all(isinstance(x, (int, float)) and math.isfinite(x) and x > 0
                            for x in anchor_diag)):
                return False, "K0 anchor lacks four finite positive genetic variances"
            for index in range(1, count + 1):
                amplitude = amplitudes[(index - 1) // len(signs)]
                sign_pattern = signs[(index - 1) % len(signs)]
                row = initial_by_index[index]
                definition = row.get("start_definition")
                if not isinstance(definition, dict):
                    return False, "K1 start lost its initialization provenance"
                if (not math.isclose(float(definition.get("amplitude", math.nan)), amplitude,
                                     rel_tol=0, abs_tol=1e-15) or
                        definition.get("signs") != sign_pattern):
                    return False, "K1 start order differs from the frozen amplitude/sign schedule"
                expected_loading = [amplitude * sign * math.sqrt(float(g) - floor)
                                    for g, sign in zip(anchor_diag, sign_pattern)]
                loading, uniqueness = definition.get("loading"), definition.get("uniqueness")
                if (not isinstance(loading, list) or len(loading) != 4 or
                        not isinstance(uniqueness, list) or len(uniqueness) != 4 or
                        any(not isinstance(x, (int, float)) or not math.isfinite(x)
                            for x in [*loading, *uniqueness]) or
                        any(not math.isclose(float(x), y, rel_tol=1e-12, abs_tol=1e-12)
                            for x, y in zip(loading, expected_loading))):
                    return False, "K1 starting loadings do not derive from the retained K0 anchor"
                expected_uniqueness = [float(g) - float(l) ** 2
                                       for g, l in zip(anchor_diag, expected_loading)]
                if (any(value <= floor for value in expected_uniqueness) or
                        any(not math.isclose(float(value), expected, rel_tol=1e-12, abs_tol=1e-12)
                            for value, expected in zip(uniqueness, expected_uniqueness))):
                    return False, "K1 starting uniquenesses do not derive from the retained K0 anchor"
                params, start_params = definition.get("params"), row.get("start_params")
                anchor_residual = _reference_cholesky_params(k0_anchor.get("residual_covariance"))
                if anchor_residual is None:
                    return False, "K0 anchor lacks a valid retained residual covariance"
                expected_params = (expected_loading +
                    [math.log(value - float(floor)) for value in expected_uniqueness] +
                    anchor_residual)
                if (not _reference_vector_matches(params, expected_params) or
                        not _reference_vector_matches(start_params, expected_params) or
                        not _reference_vector_matches(loading, expected_loading)):
                    return False, "K1 optimizer start parameters differ from retained initialization"
        initial_key, nm_key = f"k{rank}_initial", f"k{rank}_nelder_mead"
        selected_initial = refinement.get(initial_key)
        selected_nm = refinement.get(nm_key)
        if not isinstance(selected_initial, list) or not isinstance(selected_nm, list):
            return False, f"{label} reference refinement selection record is missing"
        if len(selected_initial) > 4 or len(selected_nm) > 4:
            return False, f"{label} reference retains more than four starts at a refinement stage"
        for stage, recorded, label_key in (("bfgs_initial", selected_initial, initial_key),
                                           ("nelder_mead", selected_nm, nm_key)):
            finite_rows = [row for row in rows if row.get("rank") == rank and
                           row.get("stage") == stage and row.get("finite") is True]
            finite_rows.sort(key=lambda row: (-float(row["loglik"]), int(row["schedule_index"])))
            expected_selection = [(row.get("start_name"), row.get("schedule_index"))
                                  for row in finite_rows[:4]]
            observed_selection = [(row.get("start_name"), row.get("schedule_index"))
                                  if isinstance(row, dict) else (None, None) for row in recorded]
            if observed_selection != expected_selection:
                return False, f"{label} refinement selection is not the frozen top four within rank"
            expected_params = [next(row.get("params") for row in finite_rows
                                    if row.get("start_name") == name and row.get("schedule_index") == index)
                               for name, index in expected_selection]
            if any(not isinstance(item, dict) or item.get("params") != params
                   for item, params in zip(recorded, expected_params)):
                return False, f"{label} refinement lost its retained start-parameter provenance"
        initial_params = {(item["start_name"], item["schedule_index"]): item["params"]
                          for item in selected_initial}
        nm_params = {(item["start_name"], item["schedule_index"]): item["params"]
                     for item in selected_nm}
        for row in rows:
            if row.get("rank") != rank:
                continue
            stage = row.get("stage")
            if stage == "bfgs_initial":
                source_params = row.get("start_definition", {}).get("params")
            elif stage == "nelder_mead":
                source_params = initial_params.get((row.get("start_name"), row.get("schedule_index")))
            elif stage == "bfgs_final":
                source_params = nm_params.get((row.get("start_name"), row.get("schedule_index")))
            else:
                continue
            if row.get("start_params") != source_params:
                return False, f"{label} {stage} start parameters differ from the preceding retained stage"
        expected_nm = {(item["start_name"], item["schedule_index"]) for item in selected_initial}
        nm_rows = [row for row in rows if row.get("rank") == rank and row.get("stage") == "nelder_mead"]
        actual_nm = [(row.get("start_name"), row.get("schedule_index")) for row in nm_rows]
        if len(actual_nm) != len(set(actual_nm)) or set(actual_nm) != expected_nm:
            return False, f"{label} reference Nelder-Mead ledger differs from its selected starts"
        expected_final = {(item["start_name"], item["schedule_index"]) for item in selected_nm}
        final_rows = [row for row in rows if row.get("rank") == rank and row.get("stage") == "bfgs_final"]
        actual_final = [(row.get("start_name"), row.get("schedule_index")) for row in final_rows]
        if len(actual_final) != len(set(actual_final)) or set(actual_final) != expected_final:
            return False, f"{label} reference final BFGS ledger differs from its selected starts"
    candidates = attempt.get("rank_candidates")
    if not isinstance(candidates, dict):
        return False, "reference audit lacks ordinary candidate identities"
    maxima_by_rank: dict[int, list[tuple[float, int, int, dict[str, Any]]]] = {0: [], 1: []}
    for row in rows:
        if row.get("stage") != "start_generation" and not isinstance(row.get("intermediate_maxima"), list):
            return False, "reference optimizer row does not retain intermediate exact maxima"
        if row.get("finite") is True:
            if not all(isinstance(row.get(name), (int, float)) and math.isfinite(row[name])
                       for name in ("objective", "raw_objective", "loglik")):
                return False, "finite reference row lacks finite exact objective and likelihood values"
            if not isinstance(row.get("intermediate_maxima"), list) or not row["intermediate_maxima"]:
                return False, "finite reference row lacks its retained exact evaluation maxima"
        maxima = row.get("intermediate_maxima", [])
        if not isinstance(maxima, list):
            return False, "reference row does not retain its intermediate-maxima ledger"
        prior_loglik = -math.inf
        prior_observation_order = 0
        for maximum in maxima:
            if not isinstance(maximum, dict) or not all(
                    isinstance(maximum.get(name), (int, float)) and math.isfinite(maximum[name])
                    for name in ("objective", "raw_objective", "loglik")):
                return False, "reference intermediate maximum is missing finite exact evaluation values"
            expected_dimension = 14 if row.get("rank") == 0 else 18 if row.get("rank") == 1 else None
            if (expected_dimension is None or maximum.get("rank") != row.get("rank") or
                    not isinstance(maximum.get("params"), list) or
                    len(maximum["params"]) != expected_dimension or
                    not all(isinstance(value, (int, float)) and math.isfinite(value)
                            for value in maximum["params"]) or
                    type(maximum.get("observation_order")) is not int or
                    maximum["observation_order"] <= prior_observation_order or
                    maximum.get("schedule_index") != row.get("schedule_index") or
                    maximum.get("source") not in {"objective_callback", "optimizer"}):
                return False, "reference intermediate maximum lost parameter/observation provenance"
            if float(maximum["loglik"]) + 1e-12 < prior_loglik:
                return False, "reference intermediate maxima are not retained in increasing likelihood order"
            prior_loglik = float(maximum["loglik"])
            prior_observation_order = maximum["observation_order"]
            if row.get("rank") in maxima_by_rank:
                maxima_by_rank[row["rank"]].append((float(maximum["loglik"]),
                    int(row.get("schedule_index", 0)), int(maximum.get("observation_order", 0)), row))
        if row.get("finite") is True and maxima:
            final_maximum = maxima[-1]
            if any(not math.isclose(float(final_maximum[name]), float(row[name]),
                                    rel_tol=1e-12, abs_tol=1e-12)
                   for name in ("objective", "raw_objective", "loglik")):
                return False, "reference row result differs from its final retained improving maximum"
            params = row.get("params")
            if not isinstance(params, list) or params != final_maximum.get("params"):
                return False, "reference row parameters differ from its final retained improving maximum"
            intermediate_best = row.get("intermediate_best")
            if not isinstance(intermediate_best, dict) or any(
                    intermediate_best.get(name) != final_maximum.get(name)
                    for name in ("params", "objective", "raw_objective", "loglik", "rank",
                                 "observation_order", "source", "schedule_index")):
                return False, "reference intermediate-best record differs from its retained maximum ledger"
        elif row.get("intermediate_best") is not None:
            return False, "reference row retains an intermediate best without a finite maximum ledger"
    for rank in (0, 1):
        chronological = [item[2] for item in maxima_by_rank[rank]]
        if any(current <= previous for previous, current in zip(chronological, chronological[1:])):
            return False, f"K{rank} reference maxima do not retain rank-wide chronological observation order"
        if not maxima_by_rank[rank] and candidates.get(f"K{rank}", {}).get("available"):
            return False, f"K{rank} available reference rank lacks retained valid objective evaluations"
    k0_best = (sorted(maxima_by_rank[0], key=lambda item: (-item[0], item[1], item[2]))[0]
               if maxima_by_rank[0] else None)
    if k0_anchor.get("source") == "best_finite_reference_k0":
        if k0_best is None:
            return False, "K0 best-fit anchor has no retained finite K0 maximum"
        anchor_loglik = k0_anchor.get("loglik")
        if (k0_anchor.get("start_name") != k0_best[3].get("start_name") or
                k0_anchor.get("source_stage") != k0_best[3].get("stage") or
                not isinstance(anchor_loglik, (int, float)) or not math.isfinite(anchor_loglik) or
                not math.isclose(float(anchor_loglik), k0_best[0],
                                 rel_tol=1e-12, abs_tol=1e-12) or
                k0_anchor.get("observation_order") != k0_best[2] or
                k0_anchor.get("observation_source") != k0_best[3].get("intermediate_best", {}).get("source")):
            return False, "K0 anchor does not match the deterministic best retained K0 maximum"
        best_params = k0_best[3].get("params")
        floor = float(manifest.SCIENTIFIC_CONTRACT["fa_optimizer"]["ordinary"]["uniqueness_floor"])
        anchor_diag = k0_anchor.get("genetic_diagonal")
        expected_anchor = ([(floor + value) for eta in best_params[:4]
                            if (value := _reference_exp(eta)) is not None]
                           if isinstance(best_params, list) and len(best_params) >= 4 else [])
        anchor_residual = (_reference_cholesky_covariance(best_params[4:14])
                           if isinstance(best_params, list) and len(best_params) == 14 else None)
        if (not isinstance(best_params, list) or len(best_params) != 14 or
                not isinstance(anchor_diag, list) or len(anchor_diag) != 4 or
                len(expected_anchor) != 4 or
                not _reference_vector_matches(anchor_diag, expected_anchor) or
                anchor_residual is None or
                not _reference_matrix_matches(k0_anchor.get("residual_covariance"), anchor_residual)):
            return False, "K0 anchor genetic and residual covariance do not derive from the retained best parameters"
    elif k0_anchor.get("source") == "analytic_split_fallback":
        if maxima_by_rank[0]:
            return False, "analytic K0 fallback is invalid when retained finite K0 maxima exist"
        if not math.isclose(float(k0_anchor.get("split", math.nan)), 0.5,
                            rel_tol=0, abs_tol=1e-15):
            return False, "analytic K0 fallback does not retain the frozen split provenance"
    else:
        return False, "K0 anchor has an unrecognized source provenance"
    comparisons = audit.get("rank_comparisons")
    if not isinstance(comparisons, dict) or set(comparisons) != {"K0", "K1"}:
        return False, "reference audit lacks both rank comparisons"
    for rank in ("K0", "K1"):
        comparison = comparisons[rank]
        if not isinstance(comparison, dict):
            return False, f"{rank} reference comparison is malformed"
        if not candidates.get(rank, {}).get("available"):
            if comparison.get("status") != "not_applicable":
                return False, f"unavailable ordinary {rank} comparison must be explicitly not applicable"
            continue
        rank_maxima = maxima_by_rank[int(rank[-1])]
        if not rank_maxima:
            return False, f"available ordinary {rank} comparison lacks finite reference fits"
        reference_best = max(item[0] for item in rank_maxima)
        shortfall = comparison.get("shortfall")
        ordinary_loglik = comparison.get("ordinary_loglik")
        reference_loglik = comparison.get("reference_loglik")
        expected_ordinary = candidates[rank].get("raw_loglik")
        if (comparison.get("status") != "compared" or
                not isinstance(ordinary_loglik, (int, float)) or
                not math.isclose(float(ordinary_loglik), float(expected_ordinary), rel_tol=1e-12, abs_tol=1e-12) or
                not isinstance(reference_loglik, (int, float)) or
                not math.isclose(float(reference_loglik), reference_best, rel_tol=1e-12, abs_tol=1e-12) or
                not isinstance(shortfall, (int, float)) or
                not math.isclose(float(shortfall), reference_best - float(expected_ordinary), rel_tol=1e-12, abs_tol=1e-12) or
                comparison.get("passed") is not (shortfall <= 1e-4) or
                not isinstance(shortfall, (int, float)) or not math.isfinite(shortfall) or shortfall > 1e-4):
            return False, f"available ordinary {rank} fit failed expanded-reference agreement"
    return True, None


def _rank_rollup(gate: str, phase: str, checked: dict[tuple, dict[str, Any]]) -> dict[str, Any]:
    cells = required_cells(gate, phase)
    rows: dict[tuple, dict[str, Any]] = {}
    ref_failures: list[str] = []
    for cell in cells:
        key = _cell_key(cell)
        attempts = checked[key]["receipt"]["attempts"]
        usable = sum(_usable_rank(row) for row in attempts)
        selected_k1 = sum(_usable_rank(row) and row.get("selected_rank") == "K1" for row in attempts)
        refs_required = refs_checked = 0
        for i, attempt in enumerate(attempts, start=1):
            required = _reference_required(attempt, preselected=(i <= 20))
            if required is None:
                ref_failures.append(f"{key}:attempt{i}:missing frozen selector flag mapping")
                continue
            if required:
                refs_required += 1
                ok, reason = _check_reference_audit(attempt)
                if ok:
                    refs_checked += 1
                else:
                    ref_failures.append(f"{key}:attempt{i}:{reason}")
        rows[key] = {"attempts": len(attempts), "usable": usable,
                     "selected_K1": selected_k1, "references_required": refs_required,
                     "references_passed": refs_checked}
    cells_ok = all(row["attempts"] == 30 and row["usable"] >= 29 for row in rows.values()) if phase == "pilot" else all(
        row["attempts"] == 400 for row in rows.values())
    if phase == "confirmation":
        for key, row in rows.items():
            lower, upper = integrity.wilson_interval(row["usable"], 400, 0.95)
            row["eligibility_wilson95"] = [lower, upper]
            cells_ok &= lower >= 0.90
    pilot_rule_ok = True
    ordinary_k1_witnesses = sum(row["selected_K1"] for row in rows.values())
    if gate == "G3" and phase == "pilot":
        null_k1 = [rows[("fa_rank", phase, n, "null")]["selected_K1"] for n in (80, 160, 320)]
        strong_k1 = rows[("fa_rank", phase, 320, "strong")]["selected_K1"]
        pilot_rule_ok = all(count <= 6 for count in null_k1) and strong_k1 >= 24
    if gate == "G3" and phase == "confirmation":
        nulls = [rows[("fa_rank", phase, n, "null")] for n in (80, 160, 320)]
        strong = rows[("fa_rank", phase, 320, "strong")]
        null_cis = [integrity.wilson_interval(row["selected_K1"], 400, 0.95) for row in nulls]
        strong_ci = integrity.wilson_interval(strong["selected_K1"], 400, 0.95)
        for row, interval in zip(nulls, null_cis):
            row["K1_selection_wilson95"] = list(interval)
        strong["K1_selection_wilson95"] = list(strong_ci)
        pilot_rule_ok = all(interval[1] <= 0.20 for interval in null_cis) and strong_ci[0] >= 0.80
    refs_ok = not ref_failures and all(row["references_required"] == row["references_passed"] for row in rows.values())
    witness_ok = gate != "G2" or ordinary_k1_witnesses > 0
    qualified = cells_ok and pilot_rule_ok and refs_ok and witness_ok
    return {"gate": gate, "phase": phase, "cell_metrics": [
                {"cell": {"programme": k[0], "phase": k[1], "N": k[2], "signal": k[3]}, **v}
                for k, v in rows.items()],
            "numerical_screen": "PASS" if cells_ok else "HOLD",
            "selection_rule": "PASS" if pilot_rule_ok else "HOLD",
            "reference_audits": "PASS" if refs_ok else "HOLD",
            "ordinary_K1_witnesses": ordinary_k1_witnesses,
            "ordinary_K1_witness": "PASS" if witness_ok else "HOLD",
            "reference_failures": ref_failures,
            "pilot_qualification": "PASS" if qualified and phase == "pilot" else "HOLD",
            "confirmation_result": ("PASS" if qualified else "FAIL") if phase == "confirmation" else "NOT_RUN",
            "confirmation_allocation": "HOLD",
            "success_marker": (f"ARC1_{gate}_PILOT_QUALIFIED" if qualified and phase == "pilot" else
                               f"ARC1_{gate}_CONFIRMATION_PASS" if qualified and phase == "confirmation" else None)}


def _interval_attempt_intervals(cell: dict[str, Any], attempt: dict[str, Any]) -> dict[str, Any]:
    if cell["programme"] == "fa_interval":
        bootstrap = attempt.get("bootstrap")
        if not isinstance(bootstrap, dict) or bootstrap.get("stage") != "started":
            return {}
        return bootstrap.get("intervals", {})
    return attempt.get("profile_intervals", {})


def _interval_rollup(gate: str, phase: str, checked: dict[tuple, dict[str, Any]]) -> dict[str, Any]:
    cells = required_cells(gate, phase)
    metrics: list[dict[str, Any]] = []
    qualified = True
    for cell in cells:
        key = _cell_key(cell)
        attempts = checked[key]["receipt"]["attempts"]
        total = 30 if phase == "pilot" else 400
        targets = checker_targets(cell)
        cell_ok = len(attempts) == total
        target_metrics = {}
        for target, truth in targets.items():
            formed = covered = 0
            for attempt in attempts:
                intervals = _interval_attempt_intervals(cell, attempt)
                row = intervals.get(target) if isinstance(intervals, dict) else None
                if not isinstance(row, dict):
                    continue
                if row.get("formed") is True:
                    segments = integrity._validate_target_segments(target, row.get("segments"))
                    formed += 1
                    covered += integrity.truth_in_segments(truth, segments)
            low, high = integrity.wilson_interval(covered, total, 0.90)
            if phase == "pilot":
                passed = formed >= 29 and covered >= 26
            else:
                passed = formed >= math.ceil(0.99 * total) and low >= 0.92 and high <= 0.98
            target_metrics[target] = {"formed": formed, "formation_denominator": total,
                                      "covered": covered, "coverage_denominator": total,
                                      "all_attempt_coverage": covered / total,
                                      "coverage_wilson90": [low, high], "screen": "PASS" if passed else "HOLD"}
            cell_ok &= passed
        metrics.append({"cell": cell, "attempts": len(attempts), "targets": target_metrics,
                        "screen": "PASS" if cell_ok else "HOLD"})
        qualified &= cell_ok
    endpoints: dict[str, Any] = {"required": 0, "within_002": 0, "exceeding_005": 0,
                                  "maximum_absolute_endpoint_difference": None}
    if gate == "G4" and phase == "pilot":
        differences: list[float | None] = []
        for cell in cells:
            attempts = checked[_cell_key(cell)]["receipt"]["attempts"]
            pooled_start = manifest.FA_SIGNALS.index(cell["signal"])
            designated = [a for a in attempts if ((a["outer"] - 1) * len(manifest.FA_SIGNALS) + pooled_start + 1) <= 20]
            for attempt in designated:
                prefix = attempt.get("bootstrap", {}).get("prefix_results", [])
                by_b = {row.get("B"): row for row in prefix if isinstance(row, dict)}
                if set(by_b) != {199, 499, 999}:
                    differences.append(None)
                    continue
                dataset_diffs = []
                good = True
                for target in (f"h2_{i}" for i in range(1, 5)):
                    p499, p999 = by_b[499].get("intervals", {}).get(target), by_b[999].get("intervals", {}).get(target)
                    if not isinstance(p499, dict) or not isinstance(p999, dict) or not p499.get("formed") or not p999.get("formed"):
                        good = False
                        break
                    e499, e999 = p499["segments"][0], p999["segments"][0]
                    dataset_diffs.extend(abs(float(x) - float(y)) for x, y in zip(e499, e999))
                if not good or len(dataset_diffs) != 8:
                    differences.append(None)
                else:
                    differences.append(max(dataset_diffs))
        endpoints = {"required": 20, "observed": len(differences),
                     "within_002": sum(value is not None and value <= 0.02 for value in differences),
                     "exceeding_005": sum(value is None or value > 0.05 for value in differences),
                     "maximum_absolute_endpoint_difference": max(
                         (value for value in differences if value is not None), default=None)}
        qualified &= len(differences) == 20 and endpoints["within_002"] >= 18 and endpoints["exceeding_005"] == 0
    return {"gate": gate, "phase": phase, "cell_metrics": metrics,
            "nested_endpoint_stability": endpoints,
            "pilot_qualification": "PASS" if qualified and phase == "pilot" else "HOLD",
            "confirmation_result": ("PASS" if qualified else "FAIL") if phase == "confirmation" else "NOT_RUN",
            "confirmation_allocation": "HOLD",
            "success_marker": (f"ARC1_{gate}_PILOT_QUALIFIED" if qualified and phase == "pilot" else
                               f"ARC1_{gate}_CONFIRMATION_PASS" if qualified and phase == "confirmation" else None)}


def _boundary_diagnostic_rollup(checked: dict[tuple, dict[str, Any]]) -> dict[str, Any]:
    """Report exact-zero diagnostic outcomes without imposing nominal coverage."""
    cells = required_cells("G5", "diagnostic")
    metrics = []
    complete = True
    for cell in cells:
        attempts = checked[_cell_key(cell)]["receipt"]["attempts"]
        target_counts: dict[str, dict[str, int]] = {}
        for target in ("Va", "Vpe", "Ve", "h2", "t"):
            formed = 0
            statuses: dict[str, int] = {}
            for attempt in attempts:
                row = attempt.get("profile_intervals", {}).get(target, {})
                status = str(row.get("status", "missing"))
                statuses[status] = statuses.get(status, 0) + 1
                formed += row.get("formed") is True
            target_counts[target] = {"formed": formed, "statuses": statuses}
        complete &= len(attempts) == 200
        metrics.append({"cell": cell, "attempts": len(attempts),
                        "targets": target_counts,
                        "receipt_completeness": "PASS" if len(attempts) == 200 else "HOLD"})
    return {"gate": "G5", "phase": "diagnostic", "integrity": "PASS",
            "integrity_cells": len(cells), "cell_metrics": metrics,
            "nominal_coverage_claim": "NONE; descriptive exact-zero diagnostics only",
            "diagnostic_receipts": "PASS" if complete else "HOLD",
            "confirmation_allocation": "HOLD", "success_marker": None}


def checker_targets(cell: dict[str, Any]) -> dict[str, float]:
    return integrity._expected_interval_truths(cell)


def requested_gate_passed(result: dict[str, Any], phase: str) -> bool:
    if phase == "diagnostic":
        return result.get("diagnostic_receipts") == "PASS"
    if phase == "pilot":
        return result.get("pilot_qualification") == "PASS"
    return result.get("confirmation_result") == "PASS"


def aggregate_gate(gate: str, phase: str, envelopes: list[dict[str, Any]]) -> dict[str, Any]:
    """Verify exact cell coverage and each receipt's pins, then apply G2-G5 rules.

    Each envelope is ``{"receipt": ..., "pins": ...}``, where pins are the
    complete independent arguments consumed by :func:`verify_receipt`.
    """
    expected_cells = required_cells(gate, phase)
    if gate == "G5" and phase == "confirmation":
        expected_cells = [*expected_cells, *required_cells("G5", "diagnostic")]
    expected = {_cell_key(cell): cell for cell in expected_cells}
    _need(isinstance(envelopes, list), "gate bundle must contain a list of receipt envelopes")
    supplied: dict[tuple, dict[str, Any]] = {}
    common_pins: tuple[Any, ...] | None = None
    for envelope in envelopes:
        _need(isinstance(envelope, dict) and isinstance(envelope.get("pins"), dict) and
              isinstance(envelope.get("receipt"), dict), "each cell needs a receipt and independent pins")
        pins = envelope["pins"]
        _need(all(isinstance(pins.get(name), str) and pins[name]
                  for name in ("expected_source_root", "expected_artifact_root")) and
              isinstance(pins.get("expected_admission"), dict),
              "each gate cell must pin its source root, artifact root, and run admission")
        cell = pins.get("expected_cell")
        _need(isinstance(cell, dict), "receipt envelope lacks externally pinned cell identity")
        key = _cell_key(cell)
        _need(key in expected and key not in supplied, "gate bundle has an unexpected or duplicate cell")
        admission = pins["expected_admission"]
        env_hashes = admission.get("environment_sha256")
        current_pins = (pins.get("expected_protocol_sha256"), pins.get("expected_source_hashes"),
                        env_hashes, str(Path(pins["expected_source_root"]).resolve()))
        if common_pins is None:
            common_pins = current_pins
        else:
            _need(current_pins == common_pins,
                  "cell receipts do not share one frozen source, protocol, and environment identity")
        integrity.verify_receipt(envelope["receipt"], expected_seeds=pins["expected_seeds"],
            expected_source_hashes=pins["expected_source_hashes"],
            expected_protocol_sha256=pins["expected_protocol_sha256"], expected_cell=cell,
            expected_bootstrap_inner_seeds=pins.get("expected_bootstrap_inner_seeds"),
            expected_artifact_root=Path(pins["expected_artifact_root"]),
            expected_source_root=Path(pins["expected_source_root"]),
            expected_admission=admission)
        supplied[key] = {"receipt": envelope["receipt"], "pins": pins}
    _need(set(supplied) == set(expected), "gate bundle is missing one or more required cells")
    if gate == "G5" and phase == "diagnostic":
        result = _boundary_diagnostic_rollup(supplied)
    elif gate in {"G2", "G3"}:
        result = _rank_rollup(gate, phase, supplied)
    else:
        result = _interval_rollup(gate, phase, supplied)
        if gate == "G5" and phase == "confirmation":
            diagnostics = _boundary_diagnostic_rollup(supplied)
            result["exact_zero_diagnostics"] = diagnostics["cell_metrics"]
            result["exact_zero_diagnostic_receipts"] = diagnostics["diagnostic_receipts"]
            if diagnostics["diagnostic_receipts"] != "PASS":
                result["confirmation_result"] = "FAIL"
                result["success_marker"] = None
    result["integrity"] = "PASS"
    result["integrity_cells"] = len(expected_cells)
    result["protocol_sha256"] = manifest.contract_sha256()
    result["confirmation_allocation"] = "HOLD"
    return result


def aggregate_gate_files(gate: str, phase: str, bundle_path: Path, pins_path: Path) -> dict[str, Any]:
    """Load a durable receipt bundle and separate pin ledger, then verify all cells."""
    bundle = json.loads(bundle_path.read_text(encoding="utf-8"))
    pins_doc = json.loads(pins_path.read_text(encoding="utf-8"))
    _need(isinstance(bundle, dict) and isinstance(bundle.get("receipts"), list),
          "bundle JSON must contain a receipts array")
    _need(isinstance(pins_doc, dict) and isinstance(pins_doc.get("pins"), dict),
          "trusted pin file must contain a pins mapping")
    envelopes = []
    for item in bundle["receipts"]:
        _need(isinstance(item, dict) and isinstance(item.get("cell"), dict) and
              isinstance(item.get("receipt"), dict), "each input requires a pinned cell and receipt")
        cell = item["cell"]
        key = "|".join((cell.get("programme", ""), cell.get("phase", ""),
                        str(cell.get("N", "")), cell.get("signal", "")))
        _need(key in pins_doc["pins"], f"trusted pin file lacks cell key {key}")
        pins = dict(pins_doc["pins"][key])
        pins["expected_cell"] = cell
        envelopes.append({"receipt": item["receipt"], "pins": pins})
    return aggregate_gate(gate, phase, envelopes)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("gate", choices=("G2", "G3", "G4", "G5"))
    parser.add_argument("phase", choices=("pilot", "confirmation", "diagnostic"))
    parser.add_argument("bundle", type=Path, help="JSON with a `receipts` array")
    parser.add_argument("--pins", required=True, type=Path,
                        help="separate trusted JSON mapping cell keys to independent verifier pins")
    args = parser.parse_args()
    result = aggregate_gate_files(args.gate, args.phase, args.bundle, args.pins)
    print(json.dumps(result, sort_keys=True))
    if not requested_gate_passed(result, args.phase):
        raise SystemExit(2)


if __name__ == "__main__":
    main()
