#!/usr/bin/env python3
"""Fail-closed integrity checks for Arc1 cell receipts; not a scientific gate runner."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import subprocess
import tempfile
from pathlib import Path
from statistics import NormalDist
from typing import Any, Iterable

import arc1_manifest as manifest


class ReceiptError(ValueError):
    """Evidence is incomplete, inconsistent, or differs from independent pins."""


def _inspect_full_artifacts(source_root: Path, paths: list[Path]) -> dict[str, dict[str, Any]]:
    """Read actual Julia serialization metadata and its embedded receipt summary."""
    if not paths:
        return {}
    source_root = source_root.resolve()
    inspector = source_root / "sim/arc1/inspect_artifacts.jl"
    _need(inspector.is_file(), "frozen source root lacks the full-artifact inspector")
    with tempfile.TemporaryDirectory(prefix="arc1-artifact-inspect-") as temporary:
        request = Path(temporary) / "artifacts.txt"
        request.write_text("".join(f"{path.resolve()}\n" for path in paths), encoding="utf-8")
        depot = Path(temporary) / "depot"
        depot.mkdir()
        julia = os.environ.get("ARC1_JULIA", "julia")
        env = dict(os.environ)
        env["JULIA_NUM_THREADS"] = "1"
        env["OPENBLAS_NUM_THREADS"] = "1"
        inherited_depots = env.get("JULIA_DEPOT_PATH", str(Path.home() / ".julia"))
        env["JULIA_DEPOT_PATH"] = os.pathsep.join([str(depot), inherited_depots])
        try:
            completed = subprocess.run([julia, "--startup-file=no", "--threads=1",
                f"--project={source_root}", str(inspector), str(request)],
                check=False, capture_output=True, text=True, timeout=120, env=env)
        except (OSError, subprocess.TimeoutExpired) as error:
            raise ReceiptError(f"could not inspect retained Julia artifacts: {error}") from error
    if completed.returncode != 0:
        raise ReceiptError("Julia artifact inspection failed: " + completed.stderr[-2000:])
    try:
        decoded = json.loads(completed.stdout.splitlines()[-1])
    except (IndexError, json.JSONDecodeError) as error:
        raise ReceiptError("Julia artifact inspector returned no typed metadata") from error
    _need(isinstance(decoded, list) and len(decoded) == len(paths),
          "Julia artifact inspection did not return every requested artifact")
    indexed = {}
    for row in decoded:
        _need(isinstance(row, dict) and isinstance(row.get("path"), str) and
              isinstance(row.get("metadata"), dict),
              "Julia artifact inspector returned malformed metadata")
        path = str(Path(row["path"]).resolve())
        _need(path not in indexed, "Julia artifact inspector returned a duplicate path")
        indexed[path] = row
    _need(set(indexed) == {str(path.resolve()) for path in paths},
          "Julia artifact inspector returned different artifact paths")
    return indexed


def wilson_interval(successes: int, total: int, confidence: float = 0.95) -> tuple[float, float]:
    if total <= 0 or not 0 <= successes <= total or not 0 < confidence < 1:
        raise ValueError("require total>0, 0<=successes<=total, and confidence in (0,1)")
    z = NormalDist().inv_cdf(0.5 + confidence / 2)
    p = successes / total
    den = 1 + z * z / total
    center = (p + z * z / (2 * total)) / den
    radius = z * math.sqrt(p * (1 - p) / total + z * z / (4 * total * total)) / den
    return max(0.0, center - radius), min(1.0, center + radius)


def _need(condition: bool, message: str) -> None:
    if not condition:
        raise ReceiptError(message)


def _sha256(value: Any) -> bool:
    return isinstance(value, str) and len(value) == 64 and all(c in "0123456789abcdef" for c in value)


def _expected_outer_count(cell: dict[str, Any]) -> int:
    programme, phase, n, signal = (cell.get(k) for k in ("programme", "phase", "N", "signal"))
    if programme in {"fa_rank", "repeatability"}:
        valid = n in {80, 160, 320} and signal in (
            manifest.FA_SIGNALS if programme == "fa_rank" else manifest.REPEATABILITY_SIGNALS)
        counts = {"development": 30, "pilot": 30, "confirmation": 400}
    elif programme == "fa_interval":
        valid, counts = n == 160 and signal in manifest.FA_SIGNALS, {
            "development": 30, "pilot": 30, "confirmation": 400}
    elif programme == "boundary":
        valid, counts = n == 160 and signal in {"Va_zero", "Vpe_zero"}, {"diagnostic": 200}
    else:
        raise ReceiptError(f"unsupported expected programme: {programme}")
    _need(valid, "externally pinned cell has invalid programme, N, or signal label")
    _need(phase in counts, "externally pinned phase is not allocated by the frozen contract")
    return counts[phase]


def _expected_bootstrap_count(cell: dict[str, Any], outer: int) -> int | None:
    if cell["programme"] != "fa_interval":
        return None
    phase = cell["phase"]
    if phase == "development":
        return 19
    if phase == "confirmation":
        return 499
    # The first 20 pooled pilot indices in null/weak/strong round-robin are the
    # endpoint set. They reuse each outer data seed and extend its B prefix.
    pooled = (outer - 1) * len(manifest.FA_SIGNALS) + manifest.FA_SIGNALS.index(cell["signal"]) + 1
    # Endpoint attempts retain all nested draws for stability diagnostics, but
    # the pilot result and denominator remain the frozen B=199 prefix.
    return 999 if pooled <= 20 else 199


def _expected_bootstrap_prefixes(cell: dict[str, Any], outer: int) -> list[int]:
    if cell["programme"] != "fa_interval":
        return []
    if cell["phase"] == "pilot":
        pooled = (outer - 1) * len(manifest.FA_SIGNALS) + manifest.FA_SIGNALS.index(cell["signal"]) + 1
        if pooled <= 20:
            return [199, 499, 999]
        return [199]
    return [19] if cell["phase"] == "development" else [499]


def _expected_interval_truths(cell: dict[str, Any]) -> dict[str, float]:
    if cell["programme"] == "repeatability" or cell["programme"] == "boundary":
        if cell["programme"] == "boundary":
            triples = {"Va_zero": (0.0, 0.3, 0.7), "Vpe_zero": (0.3, 0.0, 0.7)}
        else:
            triples = manifest.REPEATABILITY_TRUTHS
        va, vpe, ve = triples[cell["signal"]]
        vp = va + vpe + ve
        return {"Va": va, "Vpe": vpe, "Ve": ve, "h2": va / vp, "t": (va + vpe) / vp}
    if cell["programme"] == "fa_interval":
        return {f"h2_{i}": 0.5 for i in range(1, 5)}
    return {}


def _expected_interval_formulas(cell: dict[str, Any]) -> dict[str, str]:
    if cell["programme"] in {"repeatability", "boundary"}:
        return {"Va": "Va", "Vpe": "Vpe", "Ve": "Ve",
                "h2": "Va/(Va+Vpe+Ve)", "t": "(Va+Vpe)/(Va+Vpe+Ve)"}
    if cell["programme"] == "fa_interval":
        return {f"h2_{i}": f"G_{i}{i}/(G_{i}{i}+R_{i}{i})" for i in range(1, 5)}
    return {}


_INTERVAL_STATUSES = {"formed", "unconverged", "nuisance_unresolved", "singular",
                      "unbracketed", "point_fit_not_optimal", "outer_fit_failed",
                      "insufficient_usable_bootstrap", "unresolved_evaluation"}


def _check_interval_row(target: str, item: Any, expected_formula: str) -> None:
    _need(isinstance(item, dict) and isinstance(item.get("formed"), bool),
          f"{target} interval formation state must be explicit")
    _need(item.get("formula") == expected_formula, f"{target} interval formula differs from protocol")
    status = item.get("status")
    _need(status in _INTERVAL_STATUSES, f"{target} interval has an unrecognized status")
    _need((status == "formed") is item["formed"], f"{target} interval status and formation flag disagree")
    if item["formed"]:
        _validate_target_segments(target, item.get("segments"))
    else:
        _need(item.get("segments") == [] and isinstance(item.get("refusal_status"), str)
              and bool(item["refusal_status"]),
              f"refused/unresolved {target} interval must retain empty segments and refusal status")


def _check_profile_point_diagnostics(attempt: dict[str, Any], profile: dict[str, Any]) -> None:
    """Bind formed profile targets to their one optimal unrestricted point fit."""
    fields = ("point_fit_status", "point_fit_not_optimal", "point_loglik",
              "max_constrained_loglik", "point_identity", "reference_point_identity",
              "source_identity", "reference_source_identity", "point_fit_diagnostic_identity",
              "target_diagnostics_identity", "profile_method_version")
    present = [field in attempt for field in fields]
    if not any(present):
        _need(attempt.get("success") is False and all(not row.get("formed") for row in profile.values()),
              "successful or formed profile evidence requires shared point-fit diagnostics")
        return
    _need(all(present), "profile receipt has incomplete shared point-fit diagnostics")
    _need(attempt["point_fit_status"] in {"ok", "point_fit_unconverged", "not_run"},
          "profile receipt has an unknown point-fit status")
    if attempt["point_fit_status"] == "not_run":
        _need(attempt["profile_method_version"] in (None, "arc1_profile_v1"),
              "not-run profile method version is malformed")
        _need(attempt.get("success") is False and all(not row["formed"] and
              row["status"] == "outer_fit_failed" for row in profile.values()) and
              all(attempt[field] is None for field in fields if field != "point_fit_status"),
              "not-run point fit must retain null diagnostics and refused target rows")
        return
    _need(attempt["profile_method_version"] == "arc1_profile_v1",
          "profile method version differs from the frozen common point-fit method")
    _need(isinstance(attempt["point_fit_not_optimal"], bool),
          "point_fit_not_optimal must be an explicit boolean")
    _need(attempt["source_identity"] == attempt["reference_source_identity"],
          "profile source identity differs from its reference source identity")
    for key in ("source_identity", "reference_source_identity"):
        _need(_sha256(attempt[key]), f"{key} must be a SHA-256 identity")
    for key in ("point_fit_diagnostic_identity", "target_diagnostics_identity"):
        _need(_sha256(attempt[key]), f"{key} must be a SHA-256 identity")
    if attempt["point_fit_status"] == "ok":
        _need(_sha256(attempt["point_identity"]) and
              attempt["point_identity"] == attempt["reference_point_identity"],
              "profile and reference point-fit identities differ")
        point = attempt["point_loglik"]
        maximum = attempt["max_constrained_loglik"]
        _need(isinstance(point, (int, float)) and math.isfinite(point) and
              isinstance(maximum, (int, float)) and math.isfinite(maximum),
              "successful point fit must retain finite common and constrained maxima")
        expected_not_optimal = maximum > point + 1e-7
        _need(attempt["point_fit_not_optimal"] is expected_not_optimal,
              "point-fit optimality flag disagrees with the shared constrained maximum")
        if expected_not_optimal:
            _need(all(not row["formed"] and row["status"] == "point_fit_not_optimal"
                      for row in profile.values()),
                  "nonoptimal common point fit cannot support formed profile intervals")
        else:
            _need(attempt.get("success") is True,
                  "a converged optimal point fit must be retained as a successful attempt")
    else:
        _need(attempt.get("success") is False and all(
              not row["formed"] and row["status"] == "outer_fit_failed" for row in profile.values()),
              "failed common point fit cannot support formed profile intervals")
        _need(attempt["point_fit_not_optimal"] is False and attempt["point_loglik"] is None and
              attempt["point_identity"] is None and attempt["reference_point_identity"] is None,
              "failed point fit must retain null point likelihood/identity and a false optimality flag")


def _decode_covariance_matrix(value: Any, label: str) -> tuple[list[list[float]], list[list[float]]]:
    """Validate a lossless Julia column-major matrix payload and strict PD."""
    _need(isinstance(value, dict) and value.get("__arc1_array__") is True and
          value.get("layout") == "julia_column_major" and value.get("dims") == [4, 4],
          f"selected {label} covariance must retain tagged 4x4 dimensions and Julia layout")
    data = value.get("data")
    _need(isinstance(data, list) and len(data) == 16 and
          all(isinstance(x, (int, float)) and not isinstance(x, bool) and math.isfinite(x) for x in data),
          f"selected {label} covariance must retain sixteen finite values")
    matrix = [[float(data[c * 4 + r]) for c in range(4)] for r in range(4)]
    for i in range(4):
        for j in range(4):
            _need(math.isclose(matrix[i][j], matrix[j][i], rel_tol=1e-12, abs_tol=1e-12),
                  f"selected {label} covariance must be symmetric")
    # Explicit Cholesky test; positive diagonals alone do not establish PD.
    lower = [[0.0] * 4 for _ in range(4)]
    for i in range(4):
        for j in range(i + 1):
            residual = matrix[i][j] - sum(lower[i][k] * lower[j][k] for k in range(j))
            if i == j:
                _need(residual > 0.0, f"selected {label} covariance must be positive definite")
                lower[i][j] = math.sqrt(residual)
            else:
                lower[i][j] = residual / lower[j][j]
    return matrix, lower


def _type7_quantile(values: list[float], probability: float) -> float:
    """Julia Statistics.quantile's default Hyndman-Fan Type 7 rule."""
    _need(bool(values) and all(math.isfinite(v) for v in values), "quantile needs finite retained bootstrap estimates")
    ordered = sorted(values)
    h = (len(ordered) - 1) * probability
    lo = math.floor(h)
    hi = math.ceil(h)
    return ordered[lo] + (h - lo) * (ordered[hi] - ordered[lo])


def _candidate_score(candidate: dict[str, Any], label: str, parameter_count: int) -> float | None:
    _need(isinstance(candidate, dict), f"{label} candidate row must be an object")
    aic_penalty = 2 * parameter_count
    _need(candidate.get("parameter_count") == parameter_count,
          f"invalid {label} covariance parameter count; expected {parameter_count}")
    _need(candidate.get("aic_penalty") == aic_penalty,
          f"invalid {label} AIC penalty; expected 2q={aic_penalty}")
    _need(isinstance(candidate.get("available"), bool), f"{label} availability must be explicit")
    _need(isinstance(candidate.get("status"), str) and bool(candidate["status"]),
          f"{label} candidate status must be explicit")
    if candidate["available"]:
        raw = candidate.get("raw_loglik")
        score = candidate.get("score")
        _need(isinstance(raw, (int, float)) and math.isfinite(raw),
              f"available {label} candidate must retain finite raw REML log-likelihood")
        expected = -2.0 * float(raw) + aic_penalty
        _need(isinstance(score, (int, float)) and math.isfinite(score),
              f"available {label} candidate must retain finite score")
        _need(math.isclose(float(score), expected, rel_tol=1e-12, abs_tol=1e-10),
              f"{label} score does not equal -2*raw_loglik + aic_penalty")
        _need(candidate["status"] in {"ok", "success"},
              f"available {label} candidate has unsuccessful status")
        _need(candidate.get("error_reason") in (None, ""),
              f"available {label} candidate cannot carry an error reason")
        return expected
    _need(isinstance(candidate.get("error_reason"), str) and bool(candidate["error_reason"]),
          f"unavailable {label} candidate must retain its error reason")
    _need(candidate["status"] not in {"ok", "success"},
          f"unavailable {label} candidate cannot have successful status")
    _need(candidate.get("raw_loglik") is None and candidate.get("score") is None,
          f"unavailable {label} candidate cannot carry a usable likelihood or score")
    return None


def _check_selector_guards(attempt: dict[str, Any], *, selected: bool) -> None:
    guards = attempt.get("guard_results")
    _need(isinstance(guards, dict) and
          {"schedule_complete", "better_unaccepted", "nonnested", "nesting_witness"}.issubset(guards),
          "rank evidence must retain structured selector guard results")
    for name in ("schedule_complete", "better_unaccepted", "nonnested"):
        _need(guards.get(name) is None or isinstance(guards.get(name), bool),
              f"selector guard {name} must be an explicit boolean or not-evaluated null")
    witness = guards.get("nesting_witness")
    _need(isinstance(witness, dict) and witness.get("status") in
          {"passed", "failed", "unavailable", "not_evaluated"},
          "nesting witness must retain a structured status")
    tolerance = witness.get("tolerance")
    _need(isinstance(tolerance, (int, float)) and math.isfinite(tolerance) and tolerance > 0,
          "nesting witness must retain a finite positive tolerance")
    discrepancy = witness.get("discrepancy")
    _need(discrepancy is None or (isinstance(discrepancy, (int, float)) and math.isfinite(discrepancy)),
          "nesting witness discrepancy must be finite or explicitly unavailable")
    if witness["status"] == "passed":
        _need(discrepancy is not None and discrepancy <= tolerance,
              "passed nesting witness exceeds its retained tolerance")
    if selected:
        _need(guards["schedule_complete"] is True and guards["better_unaccepted"] is False and
              guards["nonnested"] is False and witness["status"] == "passed" and
              tolerance == 1e-8 and discrepancy is not None and 0.0 <= discrepancy <= 1e-8,
              "selected rank conflicts with a retained selector guard")


def _check_rank_decision(attempt: dict[str, Any], *, required: bool) -> tuple[bool, int]:
    candidates = attempt.get("rank_candidates")
    if candidates is None:
        _need(not required, "rank attempt lacks candidate rows")
        return False, 0
    _need(isinstance(candidates, dict) and set(candidates) == {"K0", "K1"},
          "rank evidence must contain exactly K0 and K1 rows")
    s0 = _candidate_score(candidates["K0"], "K0", 14)
    s1 = _candidate_score(candidates["K1"], "K1", 18)
    pair_available = s0 is not None and s1 is not None
    preferred = None if not pair_available else ("K1" if s1 < s0 - 1e-6 else "K0")
    _need(attempt.get("eligible", attempt.get("both_candidates_available")) is pair_available,
          "attempt eligibility disagrees with K0/K1 candidate availability")
    selection_status = attempt.get("selection_status", attempt.get("selector_status"))
    _need(isinstance(selection_status, str) and bool(selection_status),
          "rank evidence must retain the selector outcome separately from candidate availability")
    selected = attempt.get("selected_rank")
    if selection_status == "selected":
        _need(pair_available and selected == preferred,
              "selected rank disagrees with recomputed candidate scores and K0 tie rule")
        _check_selector_guards(attempt, selected=True)
    else:
        _need(selected is None,
              "unusable selector outcome cannot retain a selected rank")
        _check_selector_guards(attempt, selected=False)
    return pair_available, int(not candidates["K0"]["available"]) + int(not candidates["K1"]["available"])


def candidate_error_counts(attempts: list[dict[str, Any]]) -> dict[str, Any]:
    if not attempts:
        raise ValueError("candidate error summary requires at least one attempt")
    counts = {"K0": 0, "K1": 0}
    for attempt in attempts:
        candidates = attempt.get("rank_candidates")
        if not isinstance(candidates, dict) or set(candidates) != {"K0", "K1"}:
            raise ReceiptError("every rank attempt must retain both candidate rows")
        for label in counts:
            counts[label] += not bool(candidates[label].get("available"))
    total = len(attempts)
    return {label: {"errors": count, "denominator": total, "rate": count / total}
            for label, count in counts.items()}


def validate_segments(segments: Any) -> list[tuple[float, float]]:
    """Validate a finite ordered confidence set without bridging disconnected gaps."""
    _need(isinstance(segments, list) and len(segments) > 0, "formed confidence set needs one or more segments")
    parsed: list[tuple[float, float]] = []
    for segment in segments:
        _need(isinstance(segment, list) and len(segment) == 2,
              "each confidence-set segment must contain exactly lower and upper endpoints")
        lower, upper = segment
        _need(isinstance(lower, (int, float)) and isinstance(upper, (int, float)) and
              math.isfinite(lower) and math.isfinite(upper) and lower <= upper,
              "confidence-set endpoints must be finite and ordered")
        parsed.append((float(lower), float(upper)))
    _need(all(parsed[i][1] < parsed[i + 1][0] for i in range(len(parsed) - 1)),
          "confidence-set segments must be sorted, non-overlapping, and preserve gaps")
    return parsed


def _validate_target_segments(target: str, segments: Any) -> list[tuple[float, float]]:
    parsed = validate_segments(segments)
    lower_bound = 0.0
    upper_bound = 1.0 if target in {"h2", "t", "h2_1", "h2_2", "h2_3", "h2_4"} else math.inf
    _need(all(lower_bound <= lo <= hi <= upper_bound for lo, hi in parsed),
          f"{target} confidence-set segment violates its parameter bounds")
    return parsed


def truth_in_segments(truth: float, segments: list[tuple[float, float]]) -> bool:
    return any(lower <= truth <= upper for lower, upper in segments)


def summarize_interval_attempts(attempts: list[dict[str, Any]], targets: dict[str, float]) -> dict[str, Any]:
    """Count target-specific formation and all-attempt coverage over set segments."""
    if not attempts or not targets:
        raise ValueError("interval summary requires attempts and targets")
    out: dict[str, Any] = {}
    total = len(attempts)
    for target, truth in targets.items():
        formed = covered = 0
        for attempt in attempts:
            intervals = attempt.get("intervals")
            _need(isinstance(intervals, dict) and target in intervals,
                  f"every attempt must retain target-specific interval status for {target}")
            record = intervals[target]
            _need(isinstance(record, dict) and isinstance(record.get("formed"), bool),
                  f"{target} interval formation status must be explicit")
            if record["formed"]:
                segments = _validate_target_segments(target, record.get("segments"))
                formed += 1
                covered += truth_in_segments(truth, segments)
            else:
                _need(record.get("segments") == [],
                      f"refused/unresolved {target} interval cannot retain a formed segment")
        out[target] = {"formed": formed, "formation_denominator": total,
                       "coverage": covered, "coverage_denominator": total,
                       "formation_fraction": formed / total,
                       "all_attempt_coverage": covered / total,
                       "coverage_wilson90": list(wilson_interval(covered, total, 0.90))}
    return out


def _check_inner_attempt(inner: dict[str, Any], inner_index: int, expected_seed: int) -> tuple[bool, int]:
    _need(isinstance(inner, dict), "bootstrap inner attempt must be an object")
    _need(type(inner.get("inner_index")) is int and inner["inner_index"] == inner_index,
          "bootstrap inner indices must be complete and ordered from one")
    _need(type(inner.get("seed")) is int and inner["seed"] == expected_seed,
          "bootstrap inner seed is missing, reordered, or replaced")
    _need(isinstance(inner.get("status"), str) and bool(inner["status"]),
          "every bootstrap inner attempt must retain an outcome status")
    pair_available, _ = _check_rank_decision(inner, required=True)
    success = inner.get("success")
    selected = inner.get("selection_status", inner.get("selector_status")) == "selected"
    _need(isinstance(success, bool) and success is (pair_available and selected),
          "bootstrap inner usability must agree with candidate availability and selector outcome")
    if success:
        _check_selector_guards(inner, selected=True)
        _need(inner.get("schedule_complete") is True and inner.get("starts_planned") == 19 and
              inner.get("starts_attempted") == 19,
              "usable bootstrap selector must retain the completed frozen 19-start schedule")
    _need((inner["status"] in {"ok", "success"}) is success,
          "bootstrap inner status and success fields disagree")
    if not success:
        _need(isinstance(inner.get("failure_reason"), str) and bool(inner["failure_reason"]),
              "failed bootstrap inner attempt must retain its failure reason")
        _need(inner.get("selected_fit") is None,
              "failed bootstrap inner attempt cannot retain a selected covariance fit")
    else:
        fit = inner.get("selected_fit")
        _need(isinstance(fit, dict) and set(fit) == {"G_matrix", "R_matrix"},
              "usable bootstrap inner attempt must retain full selected G/R matrices")
        G, _ = _decode_covariance_matrix(fit["G_matrix"], "G")
        R, _ = _decode_covariance_matrix(fit["R_matrix"], "R")
        gd, rd = [G[i][i] for i in range(4)], [R[i][i] for i in range(4)]
        h2 = [float(g) / (float(g) + float(r)) for g, r in zip(gd, rd)]
        _need(all(0 < v < 1 for v in h2), "selected covariance-derived h2 values must lie in (0,1)")
        inner["_computed_h2"] = h2
    return pair_available, 2 - int(inner["rank_candidates"]["K0"]["available"]) - int(inner["rank_candidates"]["K1"]["available"])


def _check_bootstrap(attempt: dict[str, Any], cell: dict[str, Any], expected_inner_seeds: list[int]) -> dict[str, Any]:
    record = attempt.get("bootstrap")
    _need(isinstance(record, dict), "FA interval attempt lacks explicit bootstrap admission record")
    expected_b = len(expected_inner_seeds)
    prefixes = _expected_bootstrap_prefixes(cell, int(attempt["outer"]))
    primary_b = prefixes[0]
    _need(record.get("requested_B") == primary_b,
          "bootstrap requested_B differs from the externally pinned fixed budget")
    _need(record.get("stage") in {"not_started", "started"}, "bootstrap stage must be explicit")
    if record["stage"] == "not_started":
        _need(attempt.get("success") is False,
              "bootstrap cannot be marked not_started after a successful interval attempt")
        _need(isinstance(record.get("refusal_status"), str) and bool(record["refusal_status"]),
              "bootstrap refusal before admission needs a status")
        _need(record.get("inner_attempts") == [],
              "bootstrap not_started must not claim inner attempts")
        _need(record.get("usable_inner") == 0,
              "bootstrap not_started has zero usable inner attempts")
        outer_selection = attempt.get("outer_selection")
        _need(isinstance(outer_selection, dict),
              "bootstrap refusal must retain outer selector evidence")
        _check_rank_decision(outer_selection, required=True)
        _need(outer_selection.get("selection_status") != "selected",
              "bootstrap refusal cannot claim a selected outer selector")
        intervals = record.get("intervals")
        targets = _expected_interval_truths(cell)
        formulas = _expected_interval_formulas(cell)
        _need(isinstance(intervals, dict) and set(intervals) == set(targets),
              "bootstrap refusal must retain target-specific refused interval rows")
        for target, item in intervals.items():
            _check_interval_row(target, item, formulas[target])
            _need(item["formed"] is False, f"not-started bootstrap cannot form interval target {target}")
        return {"stage": "not_started", "attempted_inner": 0, "usable_inner": 0,
                "formed_targets": 0, "total_targets": len(targets)}

    _need(record.get("refusal_status") in (None, ""),
          "started bootstrap cannot also claim refusal before admission")
    _need(attempt.get("success") is True,
          "bootstrap cannot start when the outer fit did not succeed")
    inner_attempts = record.get("inner_attempts")
    _need(isinstance(inner_attempts, list) and len(inner_attempts) == expected_b,
          "started bootstrap must retain every fixed-B inner attempt, including failures")
    for outer_inner, (inner, expected_seed) in enumerate(zip(inner_attempts, expected_inner_seeds), start=1):
        _check_inner_attempt(inner, outer_inner, expected_seed)
    outer_selection = attempt.get("outer_selection")
    _need(isinstance(outer_selection, dict), "FA interval attempt must retain nested outer K0/K1 selection evidence")
    outer_eligible, _ = _check_rank_decision(outer_selection, required=True)
    _need(outer_eligible is True and outer_selection.get("selection_status") == "selected",
          "bootstrap admission requires an available pair and a usable outer selector outcome")
    actual_seeds = [item["seed"] for item in inner_attempts]
    digest = hashlib.sha256("".join(f"{seed}\n" for seed in actual_seeds).encode("ascii")).hexdigest()
    _need(record.get("inner_seed_sha256") == digest,
          "bootstrap ordered inner-seed digest does not match retained attempts")
    usable = sum(bool(item["success"]) for item in inner_attempts[:primary_b])
    _need(record.get("usable_inner") == usable,
          "bootstrap usable count does not equal the recomputed primary-prefix successful count")
    intervals = record.get("intervals")
    targets = _expected_interval_truths(cell)
    formulas = _expected_interval_formulas(cell)
    _need(isinstance(intervals, dict) and set(intervals) == set(targets),
          "started bootstrap must retain every target-specific interval row")
    minimum = math.ceil(0.99 * primary_b)
    formed_targets = 0
    for target, item in intervals.items():
        _check_interval_row(target, item, formulas[target])
        if item["formed"]:
            _need(usable >= minimum,
                  f"{target} interval formed below the fixed-B 0.99 usable threshold")
            target_index = int(target.split("_")[1]) - 1
            primary_attempts = inner_attempts[:primary_b]
            values = [row["_computed_h2"][target_index] for row in primary_attempts if row["success"]]
            expected_segment = [_type7_quantile(values, 0.025), _type7_quantile(values, 0.975)]
            observed_segment = item.get("segments")
            _need(isinstance(observed_segment, list) and len(observed_segment) == 1 and
                  isinstance(observed_segment[0], list) and len(observed_segment[0]) == 2 and
                  all(isinstance(x, (int, float)) and math.isclose(float(x), y, rel_tol=1e-12, abs_tol=1e-14)
                      for x, y in zip(observed_segment[0], expected_segment)),
                  f"{target} endpoints do not match retained selected-fit h2 values and Type-7 quantiles")
            formed_targets += 1
    prefix_records = record.get("prefix_results")
    _need(isinstance(prefix_records, list) and [p.get("B") for p in prefix_records] == prefixes,
          "bootstrap must retain each externally pinned prefix result in order")
    _need(record.get("intervals") == prefix_records[0].get("intervals"),
          "ordinary bootstrap interval must equal the first, primary-B prefix result")
    for prefix_row in prefix_records:
        b = int(prefix_row["B"])
        prefix_inner = inner_attempts[:b]
        prefix_usable = sum(bool(item["success"]) for item in prefix_inner)
        _need(prefix_row.get("usable_inner") == prefix_usable,
              f"B={b} prefix usable count differs from retained attempts")
        _need(prefix_row.get("usable_fraction") == prefix_usable / b,
              f"B={b} prefix usability fraction is incorrect")
        prefix_intervals = prefix_row.get("intervals")
        _need(isinstance(prefix_intervals, dict) and set(prefix_intervals) == set(targets),
              f"B={b} prefix must retain every target interval")
        for target, item in prefix_intervals.items():
            _check_interval_row(target, item, formulas[target])
            if item["formed"]:
                _need(prefix_usable >= math.ceil(0.99 * b),
                      f"B={b} formed interval below its independent 0.99 usability threshold")
                target_index = int(target.split("_")[1]) - 1
                values = [row["_computed_h2"][target_index] for row in prefix_inner if row["success"]]
                expected_segment = [_type7_quantile(values, 0.025), _type7_quantile(values, 0.975)]
                observed = item.get("segments")
                _need(isinstance(observed, list) and len(observed) == 1 and len(observed[0]) == 2 and
                      all(math.isclose(float(x), y, rel_tol=1e-12, abs_tol=1e-14)
                          for x, y in zip(observed[0], expected_segment)),
                      f"B={b} {target} endpoints do not match this prefix's retained draws")
    _need(record.get("method") == "candidate_percentile_bootstrap" and
          record.get("quantiles") == [0.025, 0.975],
          "FA intervals must identify the fixed 95% candidate percentile method")
    return {"stage": "started", "attempted_inner": expected_b,
            "usable_inner": sum(bool(item["success"]) for item in inner_attempts[:primary_b]),
            "usable_denominator": primary_b, "prefix_B": prefixes,
            "formed_targets": formed_targets, "total_targets": len(targets)}


def verify_receipt(
    receipt: dict[str, Any], *, expected_seeds: Iterable[int],
    expected_source_hashes: dict[str, str], expected_protocol_sha256: str,
    expected_cell: dict[str, Any],
    expected_bootstrap_inner_seeds: dict[int, list[int]] | None = None,
    expected_artifact_root: Path | None = None,
    expected_source_root: Path | None = None,
    expected_admission: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Verify one cell-phase receipt against external cell, seed, source, and protocol pins.

    This establishes row-level integrity and internal arithmetic. It cannot
    prove that pinned code actually executed; that requires source-bound run
    admission and execution evidence from the later campaign driver.
    """
    _need(isinstance(receipt, dict), "receipt must be an object")
    _need(_sha256(expected_protocol_sha256) and expected_protocol_sha256 == manifest.contract_sha256(),
          "expected protocol pin must be a nonempty SHA-256 of the canonical frozen contract")
    _need(isinstance(expected_source_hashes, dict) and bool(expected_source_hashes),
          "expected source pins must be a nonempty external mapping")
    _need(all(isinstance(path, str) and path and _sha256(digest)
              for path, digest in expected_source_hashes.items()),
          "expected source pins contain an empty path or malformed SHA-256")
    _need(receipt.get("schema") == "arc1-attempt-receipt-v1", "unsupported receipt schema")
    _need(receipt.get("protocol_sha256") == expected_protocol_sha256,
          "receipt protocol hash differs from external canonical-contract pin")
    _need(receipt.get("source_hashes") == expected_source_hashes,
          "receipt source hashes differ from independently supplied source pins")
    _need(isinstance(expected_cell, dict) and set(expected_cell) == {"programme", "phase", "N", "signal"},
          "expected cell pin must contain programme, phase, N, and signal")
    expected_count = _expected_outer_count(expected_cell)
    for field, expected_value in expected_cell.items():
        _need(receipt.get(field) == expected_value,
              f"receipt {field} differs from the externally pinned cell")

    expected = list(expected_seeds)
    _need(len(expected) == expected_count and all(type(s) is int and 0 <= s <= 2**64 - 1 for s in expected),
          "external seed pin has wrong cell count or invalid UInt64 values")
    _need(len(expected) == len(set(expected)), "external seed pin itself contains duplicates")
    canonical = [manifest.seed_for(expected_cell["programme"], expected_cell["phase"],
                                   expected_cell["N"], expected_cell["signal"], outer, 0, "data")
                 for outer in range(1, expected_count + 1)]
    _need(expected == canonical, "external outer seed pin differs from canonical seed manifest")
    if expected_admission is not None:
        _need(expected_source_root is not None and isinstance(expected_admission, dict),
              "receipt cross-binding requires the frozen source root and run admission")
        _need(expected_admission.get("cell") == expected_cell and
              expected_admission.get("expected_outer_seeds") == expected and
              expected_admission.get("source_sha256") == expected_source_hashes and
              expected_admission.get("protocol_sha256") == expected_protocol_sha256,
              "receipt pins differ from the source-root admission's cell, seeds, protocol, or source bytes")
        threads = expected_admission.get("threads")
        _need(isinstance(threads, dict), "run admission lacks execution thread pins")
        try:
            manifest.verify_run_admission(Path(expected_source_root), expected_admission,
                julia_version=str(expected_admission.get("julia_version")),
                julia_threads=int(threads["julia"]), blas_threads=int(threads["blas"]))
        except (ValueError, KeyError, TypeError) as error:
            raise ReceiptError(f"run admission is not valid against the frozen source root: {error}") from error
        if expected_bootstrap_inner_seeds is not None:
            admission_bootstrap = expected_admission.get("expected_bootstrap_seeds", {})
            by_outer_seed = {canonical[i - 1]: admission_bootstrap.get(str(i))
                             for i in range(1, expected_count + 1)}
            _need(expected_bootstrap_inner_seeds == by_outer_seed,
                  "bootstrap receipt seed pins differ from source-root run admission")
    _need(receipt.get("planned_attempts") == expected_count,
          "declared attempt denominator differs from the full frozen cell allocation")
    attempts = receipt.get("attempts")
    _need(isinstance(attempts, list) and len(attempts) == expected_count,
          "receipt is missing planned attempts or contains unexpected replacements")
    artifact_fields = ("artifact_path", "artifact_sha256", "receipt_summary_path",
                       "receipt_summary_sha256")
    has_artifact_claims = any(isinstance(row, dict) and any(row.get(name) is not None
                              for name in artifact_fields) for row in attempts)
    artifact_metadata: dict[str, dict[str, Any]] = {}
    if expected_artifact_root is None:
        _need(not has_artifact_claims,
              "artifact claims require an independently pinned artifact root and source admission")
    else:
        _need(expected_source_root is not None and isinstance(expected_admission, dict),
              "full-artifact semantics require a frozen source root and run admission")
        artifact_root = Path(expected_artifact_root).resolve()
        paths = []
        for row in attempts:
            if not isinstance(row, dict) or row.get("artifact_path") is None:
                continue
            path = Path(row["artifact_path"]).resolve()
            _need(path.is_relative_to(artifact_root) and path.is_file(),
                  "retained full-result artifact is missing or outside the pinned output root")
            paths.append(path)
        artifact_metadata = _inspect_full_artifacts(Path(expected_source_root),
            list(dict.fromkeys(paths)))
    attempt_ids: set[str] = set()
    actual_seeds: list[int] = []
    eligible_count = 0
    failed_count = 0
    candidate_errors = {"K0": 0, "K1": 0}
    bootstrap_summaries: list[dict[str, Any]] = []
    interval_attempts: list[dict[str, Any]] = []
    expected_targets = _expected_interval_truths(expected_cell)
    for index, (attempt, expected_seed) in enumerate(zip(attempts, expected), start=1):
        _need(isinstance(attempt, dict), f"attempt {index} must be an object")
        attempt_id = attempt.get("attempt_id")
        _need(isinstance(attempt_id, str) and attempt_id and attempt_id not in attempt_ids,
              f"attempt {index} has missing or duplicate attempt_id")
        attempt_ids.add(attempt_id)
        _need(type(attempt.get("outer")) is int and attempt["outer"] == index,
              "outer attempts must retain canonical 1-based order")
        seed = attempt.get("seed")
        _need(type(seed) is int and seed == expected_seed,
              "attempt seed is missing, reordered, duplicated, or replaced")
        actual_seeds.append(seed)
        _need(isinstance(attempt.get("status"), str) and bool(attempt["status"]),
              f"attempt {attempt_id} must retain an outcome status")
        _need(isinstance(attempt.get("success"), bool), f"attempt {attempt_id} must retain boolean success")
        _need((attempt["status"] in {"ok", "success"}) is attempt["success"],
              f"attempt {attempt_id} status and success fields disagree")
        artifact_path = attempt.get("artifact_path")
        artifact_sha = attempt.get("artifact_sha256")
        if artifact_path is not None:
            resolved_artifact = Path(artifact_path).resolve()
            observed_row = artifact_metadata.get(str(resolved_artifact))
            _need(isinstance(observed_row, dict),
                  f"attempt {attempt_id} is not present in the inspected full artifacts")
            metadata = observed_row["metadata"]
            _need(metadata.get("schema") == "arc1-full-result-v2" and
                  metadata.get("outer") == index and
                  metadata.get("seed_string") == str(expected_seed) and
                  metadata.get("cell") == expected_cell,
                  f"attempt {attempt_id} artifact metadata differs from external outer/seed/cell pins")
            driver_identity = metadata.get("driver_protocol_identity")
            _need(isinstance(driver_identity, dict) and
                  driver_identity.get("source_sha256") == expected_source_hashes and
                  driver_identity.get("protocol_sha256") == expected_protocol_sha256 and
                  (expected_admission is None or
                   driver_identity.get("environment_sha256") == expected_admission.get("environment_sha256")),
                  f"attempt {attempt_id} artifact lacks the externally pinned full driver/protocol identity")
            _need(observed_row.get("receipt_summary_matches_retained_result") is True,
                  f"attempt {attempt_id} retained JLS result differs from its embedded receipt summary "
                  f"(result={observed_row.get('retained_result_summary_sha256')}, "
                  f"embedded={observed_row.get('embedded_receipt_summary_sha256')})")
            _need(observed_row.get("raw_result_matches_derived_receipt") is True,
                  f"attempt {attempt_id} retained raw selector/profile/bootstrap output differs from its derived receipt")
            _need(observed_row.get("reference_scale_matches_retained_y") is True,
                  f"attempt {attempt_id} reference initialization scale differs from retained response data")
            if observed_row.get("retained_data_present") is True:
                _need(observed_row.get("data_seed_matches_metadata") is True,
                      f"attempt {attempt_id} retained data seed differs from externally pinned metadata seed")
            else:
                _need(observed_row.get("data_seed_matches_metadata") is None,
                      f"attempt {attempt_id} has inconsistent data-seed inspection without retained data")
            _need(observed_row.get("semantic_data_identity_matches_recomputed") is True,
                  f"attempt {attempt_id} semantic data identity differs from retained data/design values")
            if observed_row.get("retained_result_present") is True:
                _need(observed_row.get("data_identity_method") == "arc1-semantic-data-v2" and
                      _sha256(observed_row.get("semantic_data_identity_sha256")) and
                      observed_row.get("semantic_data_identity_sha256") ==
                      observed_row.get("recomputed_semantic_data_identity_sha256"),
                      f"attempt {attempt_id} retained-result semantic identity lacks its versioned digest")
                _need(attempt.get("semantic_data_identity_sha256") ==
                      observed_row.get("semantic_data_identity_sha256"),
                      f"attempt {attempt_id} semantic identity differs between receipt and artifact")
            else:
                _need(not attempt["success"] and observed_row.get("semantic_data_identity_sha256") is None,
                      f"attempt {attempt_id} lacks semantic identity despite retaining a result")
            retained_identity = attempt.get("execution_identity")
            _need(metadata.get("execution_identity") == retained_identity,
                  f"attempt {attempt_id} artifact execution identity differs from its durable row")
            if attempt["success"]:
                _need(_sha256(attempt.get("data_identity_sha256")) and
                      metadata.get("data_identity_sha256") == attempt["data_identity_sha256"],
                      f"attempt {attempt_id} artifact data identity differs from its durable row")
                _need(attempt.get("data_identity_method") == "arc1-semantic-data-v2",
                      f"attempt {attempt_id} lacks the required semantic data identity method")
                _need(_sha256(attempt.get("semantic_data_identity_sha256")) and
                      metadata.get("semantic_data_identity_sha256") == attempt["semantic_data_identity_sha256"],
                      f"attempt {attempt_id} semantic data identity differs from its durable row")
            elif attempt.get("data_identity_sha256") is not None:
                _need(metadata.get("data_identity_sha256") == attempt["data_identity_sha256"],
                      f"attempt {attempt_id} artifact data identity differs from its durable row")
            if attempt.get("semantic_data_identity_sha256") is not None:
                _need(attempt.get("data_identity_method") == "arc1-semantic-data-v2",
                      f"attempt {attempt_id} has an unknown semantic data identity method")
                _need(metadata.get("semantic_data_identity_sha256") ==
                      attempt["semantic_data_identity_sha256"],
                          f"attempt {attempt_id} semantic data identity differs from its durable row")
            artifact_summary = observed_row.get("receipt_summary")
            if attempt["success"]:
                _need(isinstance(artifact_summary, dict),
                      f"attempt {attempt_id} full artifact lacks its embedded canonical receipt summary")
                _need(metadata.get("receipt_summary_path") == attempt.get("receipt_summary_path") and
                      metadata.get("receipt_summary_sha256") == attempt.get("receipt_summary_sha256"),
                      f"attempt {attempt_id} embedded summary identity differs from external receipt pins")
            elif artifact_summary is not None:
                _need(isinstance(artifact_summary, dict) and
                      artifact_summary.get("success") is False and
                      observed_row.get("retained_result_success") is False and
                      observed_row.get("retained_result_status") == attempt["status"] and
                      artifact_summary.get("status") == attempt["status"],
                      f"failed attempt {attempt_id} retained summary is not a matching returned failure")
                _need(metadata.get("receipt_summary_path") == attempt.get("receipt_summary_path") and
                      metadata.get("receipt_summary_sha256") == attempt.get("receipt_summary_sha256"),
                      f"failed attempt {attempt_id} retained summary identity differs from external pins")
        if expected_artifact_root is not None:
            artifact_root = Path(expected_artifact_root).resolve()
            if attempt["success"]:
                _need(isinstance(artifact_path, str) and _sha256(artifact_sha),
                      f"successful attempt {attempt_id} lacks a pinned full-result artifact")
            if artifact_path is not None:
                resolved_artifact = Path(artifact_path).resolve()
                _need(resolved_artifact.is_relative_to(artifact_root) and resolved_artifact.is_file(),
                      f"attempt {attempt_id} artifact is missing or outside the pinned output root")
                observed_sha = hashlib.sha256(resolved_artifact.read_bytes()).hexdigest()
                _need(observed_sha == artifact_sha,
                      f"attempt {attempt_id} artifact bytes differ from the retained SHA-256")
            has_summary_claim = attempt.get("receipt_summary_path") is not None or \
                attempt.get("receipt_summary_sha256") is not None
            if attempt["success"] or has_summary_claim:
                summary_path = attempt.get("receipt_summary_path")
                summary_sha = attempt.get("receipt_summary_sha256")
                _need(isinstance(summary_path, str) and _sha256(summary_sha),
                      f"attempt {attempt_id} has incomplete canonical receipt summary pins")
                resolved_summary = Path(summary_path).resolve()
                _need(resolved_summary.is_relative_to(artifact_root) and resolved_summary.is_file(),
                      f"attempt {attempt_id} summary is missing or outside the pinned output root")
                summary_bytes = resolved_summary.read_bytes()
                _need(hashlib.sha256(summary_bytes).hexdigest() == summary_sha,
                      f"attempt {attempt_id} summary bytes differ from the retained SHA-256")
                try:
                    summary = json.loads(summary_bytes.decode("utf-8"))
                except (UnicodeDecodeError, json.JSONDecodeError) as error:
                    raise ReceiptError(f"attempt {attempt_id} summary is not valid UTF-8 JSON") from error
                stored = attempt.get("stored_row")
                wrapper = stored.get("result") if isinstance(stored, dict) else None
                nested = wrapper.get("result") if isinstance(wrapper, dict) else None
                _need(isinstance(summary, dict) and
                      (summary == nested if isinstance(nested, dict) else summary == wrapper),
                      f"attempt {attempt_id} summary differs from its durable Julia result mapping")
                _need(summary == artifact_metadata[str(Path(artifact_path).resolve())].get("receipt_summary"),
                      f"attempt {attempt_id} sidecar summary differs from the embedded full-artifact summary")
                for name, value in summary.items():
                    if name in attempt:
                        _need(attempt[name] == value,
                              f"attempt {attempt_id} flattened {name} differs from its retained summary")
        if expected_source_root is not None or expected_admission is not None:
            _need(expected_source_root is not None and isinstance(expected_admission, dict),
                  "execution identity verification needs both source root and admitted environment pins")
            identity = attempt.get("execution_identity")
            if attempt["success"]:
                _need(isinstance(identity, dict),
                      f"successful attempt {attempt_id} lacks loaded execution identity")
            if identity is not None:
                manifest.verify_execution_identity(Path(expected_source_root), expected_admission, identity)
        if not attempt["success"]:
            failed_count += 1
            _need(isinstance(attempt.get("failure_reason"), str) and bool(attempt["failure_reason"]),
                  f"failed attempt {attempt_id} must retain its failure reason")

        eligible = False
        if expected_cell["programme"] == "fa_rank":
            eligible, _ = _check_rank_decision(attempt, required=True)
            eligible_count += eligible
            for label in candidate_errors:
                candidate_errors[label] += not attempt["rank_candidates"][label]["available"]
            selected = attempt.get("selection_status") == "selected"
            _need(attempt["success"] is (eligible and selected),
                  "rank attempt success must agree with pair availability and selector outcome")
        elif "rank_candidates" in attempt or "selected_rank" in attempt or "eligible" in attempt:
            _need(False, "rank evidence is unexpected for this externally pinned programme")

        if expected_cell["programme"] == "fa_interval":
            inner_pins = (expected_bootstrap_inner_seeds or {}).get(seed)
            _need(isinstance(inner_pins, list),
                  "each FA interval outer attempt requires an external exact inner-seed list")
            budget = _expected_bootstrap_count(expected_cell, index)
            _need(len(inner_pins) == budget,
                  "external bootstrap inner-seed list has wrong fixed budget")
            expected_inner = [manifest.seed_for("fa_interval", expected_cell["phase"],
                                                expected_cell["N"], expected_cell["signal"],
                                                index, inner, "bootstrap")
                              for inner in range(1, budget + 1)]
            _need(inner_pins == expected_inner,
                  "external bootstrap seed list differs from canonical inner-seed stream")
            bootstrap_summaries.append(_check_bootstrap(attempt, expected_cell, inner_pins))
            interval_attempts.append({"intervals": attempt["bootstrap"]["intervals"]})
        elif expected_targets:
            profile = attempt.get("profile_intervals")
            _need(isinstance(profile, dict) and set(profile) == set(expected_targets),
                  "every repeatability/boundary attempt needs all target-specific profile rows")
            _need(attempt.get("profile_method") == "profile_likelihood_ratio" and
                  attempt.get("profile_lr_cutoff") == 3.841458820694124,
                  "profile receipt must identify the frozen likelihood-ratio method and cutoff")
            _check_profile_point_diagnostics(attempt, profile)
            formulas = _expected_interval_formulas(expected_cell)
            for target, item in profile.items():
                _check_interval_row(target, item, formulas[target])
                if not attempt["success"]:
                    _need(item["formed"] is False and item.get("status") == "outer_fit_failed",
                          f"failed outer fit cannot form {target} profile interval")
            interval_attempts.append({"intervals": profile})
        elif "bootstrap" in attempt or "profile_intervals" in attempt:
            _need(False, "interval evidence is unexpected for this externally pinned programme")

    _need(actual_seeds == expected, "receipt attempt order differs from the pinned manifest rowset")
    result: dict[str, Any] = {"attempts": expected_count, "failures": failed_count,
                              "eligibility_denominator": expected_count,
                              "eligible_both_candidates": eligible_count}
    if expected_cell["programme"] == "fa_rank":
        result["candidate_errors"] = {
            label: {"errors": count, "denominator": expected_count, "rate": count / expected_count}
            for label, count in candidate_errors.items()}
    if expected_targets:
        result["interval_targets"] = summarize_interval_attempts(interval_attempts, expected_targets)
    if bootstrap_summaries:
        result["bootstrap"] = {"outer_attempts": len(bootstrap_summaries),
                               "fixed_B": sorted({item["attempted_inner"] for item in bootstrap_summaries}),
                               "refused_before_start": sum(item["stage"] == "not_started" for item in bootstrap_summaries),
                               "usable_denominators_retained": all(
                                   item["stage"] == "not_started" or
                                   item["usable_denominator"] == item["prefix_B"][0]
                                   for item in bootstrap_summaries)}
    return result


def verify_file(receipt_path: Path, pins_path: Path) -> dict[str, Any]:
    receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
    pins = json.loads(pins_path.read_text(encoding="utf-8"))
    _need(isinstance(pins, dict) and
          {"expected_seeds", "source_hashes", "protocol_sha256", "cell"}.issubset(pins),
          "external pin file is missing required independent pin fields")
    _need(isinstance(pins["expected_seeds"], list) and isinstance(pins["source_hashes"], dict)
          and isinstance(pins["cell"], dict), "external pin fields have invalid shapes")
    if any(key in pins for key in ("artifact_root", "source_root", "admission")):
        _need(all(isinstance(pins.get(key), str) and pins[key]
                  for key in ("artifact_root", "source_root")) and
              isinstance(pins.get("admission"), dict),
              "artifact and execution pins require artifact_root, source_root, and admission")
    bootstrap_pins = pins.get("bootstrap_inner_seeds", {})
    _need(isinstance(bootstrap_pins, dict), "bootstrap inner seed pins must be an object")
    return verify_receipt(receipt, expected_seeds=pins["expected_seeds"],
                          expected_source_hashes=pins["source_hashes"],
                          expected_protocol_sha256=pins["protocol_sha256"],
                          expected_cell=pins["cell"],
                          expected_bootstrap_inner_seeds={int(k): v for k, v in bootstrap_pins.items()},
                          expected_artifact_root=Path(pins["artifact_root"]) if pins.get("artifact_root") else None,
                          expected_source_root=Path(pins["source_root"]) if pins.get("source_root") else None,
                          expected_admission=pins.get("admission"))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("receipt", type=Path)
    parser.add_argument("--pins", required=True, type=Path,
                        help="independent cell, seed, protocol and source pins")
    args = parser.parse_args()
    print(json.dumps(verify_file(args.receipt, args.pins), sort_keys=True))


if __name__ == "__main__":
    main()
