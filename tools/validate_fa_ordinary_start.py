#!/usr/bin/env python3
"""Validate frozen FA ordinary-start primary TSVs, using only Python's stdlib.

No fitting occurs. Hashes are caller-supplied trust anchors. A partial result is
an ordered prefix, never campaign completion. Matrix finiteness is not observable
from the driver's scalar serialization; class audits are conditional on that
recorded projection. Threshold comparisons admit the 12-significant-digit
rounding interval and report ambiguities instead of asserting hidden precision.
"""

import argparse
from collections import Counter
from decimal import Decimal, InvalidOperation
import hashlib
import itertools
import json
import math
from pathlib import Path
import re
import statistics
import sys

HEADER = "seed mode fit_status converged recovered class rel_G rel_R dlog min_psi iterations strategy starts_attempted selected_start objective_range uniqueness_floor_distance near_uniqueness_floor g_relative_disagreement r_relative_disagreement better_nonconverged_start per_start seconds error".split()
SEEDS = list(range(20261200, 20261400))
NUMBERS = "rel_G rel_R dlog min_psi objective_range uniqueness_floor_distance g_relative_disagreement r_relative_disagreement seconds".split()
BOOLS = ("converged", "recovered")
OPTIONAL_BOOLS = ("near_uniqueness_floor", "better_nonconverged_start")
CLASSES = ("recovered", "exception", "nonconverged", "nonfinite", "uniqueness_floor", "G_error", "R_error", "below_truth_objective", "other_failure")
SUMMARY = re.compile(r"# summary n=(\d+) recovered=(\d+) rate=(\S+) mcse=(\S+) wilson95=\[([^,]+),([^\]]+)\]")


class ValidationError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise ValidationError(message)


def boolean(value, name, nullable=False):
    if nullable and value == "NA":
        return None
    require(value in ("true", "false"), f"{name}: expected true/false" + ("/NA" if nullable else ""))
    return value == "true"


def number(value, name):
    if value == "NA":
        return None
    require(bool(re.fullmatch(r"[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?", value)), f"{name}: invalid number")
    result = float(value)
    require(math.isfinite(result), f"{name}: nonfinite value must serialize as NA")
    return result


def integer(value, name, nullable=False):
    if nullable and value == "NA":
        return None
    require(bool(re.fullmatch(r"\d+", value)), f"{name}: expected nonnegative integer")
    return int(value)


def rounding_interval(value):
    """Interval implied by Julia @sprintf(\"%.12g\", x), not printed digit count."""
    x = Decimal(value)
    radius = Decimal(0) if x == 0 else Decimal(5).scaleb(x.copy_abs().adjusted() - 12)
    return x - radius, x + radius


def comparison(value, threshold, direction):
    if value == "NA":
        return (False,), False
    lo, hi = rounding_interval(value)
    threshold = Decimal(threshold)
    if direction == "le":
        choices = tuple(flag for flag, possible in ((True, lo <= threshold), (False, hi > threshold)) if possible)
    else:
        choices = tuple(flag for flag, possible in ((True, hi >= threshold), (False, lo < threshold)) if possible)
    return choices, len(choices) == 2


def recovery_statistics(n, recovered):
    require(n > 0, "empty result has no rate or interval")
    p = recovered / n
    z = 1.959963984540054
    denom = 1 + z * z / n
    center = (p + z * z / (2 * n)) / denom
    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / denom
    return dict(n=n, recovered=recovered, rate=p, mcse=math.sqrt(p * (1-p) / n), wilson95=[center-half, center+half])


def conditional(values):
    values = [x for x in values if x is not None]
    if not values:
        return dict(n=0, min=None, median=None, mean=None, max=None)
    return dict(n=len(values), min=min(values), median=statistics.median(values), mean=statistics.mean(values), max=max(values))


def parse_row(fields, row_number):
    require(len(fields) == len(HEADER), f"row {row_number}: expected 23 fields, got {len(fields)}")
    raw = dict(zip(HEADER, fields))
    row = dict(raw)
    row["seed"] = integer(raw["seed"], "seed")
    require(raw["mode"] == "primary", "row mode must be primary")
    require(raw["fit_status"] in ("ok", "exception"), "invalid fit_status")
    require(raw["class"] in CLASSES, "invalid class")
    for key in BOOLS:
        row[key] = boolean(raw[key], key)
    for key in OPTIONAL_BOOLS:
        row[key] = boolean(raw[key], key, nullable=True)
    for key in NUMBERS:
        row[key] = number(raw[key], key)
    for key in ("iterations", "starts_attempted"):
        row[key] = integer(raw[key], key, nullable=True)
    for key in ("rel_G", "rel_R", "min_psi", "objective_range", "g_relative_disagreement", "r_relative_disagreement", "seconds"):
        require(row[key] is None or row[key] >= 0, f"{key}: must be nonnegative")
    if raw["fit_status"] == "exception":
        require(not row["converged"] and not row["recovered"] and raw["class"] == "exception", "exception flags/class mismatch")
        require(all(raw[key] == "NA" for key in HEADER[6:21]), "exception diagnostics must all be NA")
        require(bool(raw["error"]), "exception requires an error message")
        row["starts"] = []
        row["criteria"] = {"exception": (False,)}
        row["ambiguities"] = []
        return row
    require(raw["class"] != "exception" and raw["error"] == "", "ok row has exception class/error")
    require(raw["strategy"] == "default_and_balanced" and row["starts_attempted"] == 2, "frozen campaign requires two ordinary starts")
    starts = []
    for item in raw["per_start"].split(";"):
        parts = item.split(":")
        require(len(parts) == 4, "malformed per_start")
        name, valid, converged, iterations = parts
        starts.append(dict(name=name, valid=boolean(valid, "per_start.valid"), converged=boolean(converged, "per_start.converged"), iterations=integer(iterations, "per_start.iterations")))
    require([s["name"] for s in starts] == ["default", "balanced"], "expected ordered default and balanced starts")
    require(all(s["iterations"] <= 5000 for s in starts), "per-start iteration cap exceeded")
    require(raw["selected_start"] in ("default", "balanced"), "invalid selected_start")
    selected = next(s for s in starts if s["name"] == raw["selected_start"])
    require(selected["valid"], "selected start is invalid")
    require(row["converged"] == selected["converged"] and row["iterations"] == selected["iterations"], "selected-start convergence/iterations mismatch")
    valid_count = sum(s["valid"] for s in starts)
    for key in ("objective_range", "g_relative_disagreement", "r_relative_disagreement"):
        # Overflow can serialize a computed diagnostic as NA even with two valid starts.
        require(valid_count > 1 or row[key] is None, f"{key}: present with fewer than two valid starts")
    require(all(row[k] is not None for k in OPTIONAL_BOOLS), "ok row requires diagnostic booleans")
    require(not row["better_nonconverged_start"] or any(s["valid"] and not s["converged"] and s["name"] != raw["selected_start"] for s in starts), "better-nonconverged flag has no candidate start")
    if row["min_psi"] is not None and row["uniqueness_floor_distance"] is not None:
        psi_lo, psi_hi = rounding_interval(raw["min_psi"])
        floor_lo, floor_hi = rounding_interval(raw["uniqueness_floor_distance"])
        # Subtraction can lose binary precision close to the floor.
        epsilon = Decimal(str(4 * math.ulp(row["min_psi"])))
        require(psi_lo - Decimal("0.0001") - epsilon <= floor_hi and psi_hi - Decimal("0.0001") + epsilon >= floor_lo, "uniqueness_floor_distance inconsistent with min_psi")
    near_choices, near_ambiguous = comparison(raw["uniqueness_floor_distance"], "0.000001", "le")
    if raw["uniqueness_floor_distance"] == "NA":
        near_choices, near_ambiguous = (True, False), False
    require(row["near_uniqueness_floor"] in near_choices, "near-floor flag inconsistent with floor distance")
    criteria = {}
    metric_states = {}
    ambiguities = []
    for key, threshold, direction in (("rel_G", ".45", "le"), ("rel_R", ".25", "le"), ("min_psi", ".0001", "ge"), ("dlog", "-.000001", "ge")):
        criteria[key], ambiguous = comparison(raw[key], threshold, direction)
        if raw[key] != "NA":
            # Finite numbers obey opposite comparisons. NaN does not.
            metric_states[key] = tuple((passed, not passed) for passed in criteria[key])
        elif key in ("rel_G", "rel_R"):
            # A relative norm error is nonnegative: +Inf satisfies >tol; NaN
            # fails both <=tol and >tol. Both serialize as NA.
            metric_states[key] = ((False, True), (False, False))
        elif key == "dlog":
            # +Inf passes >=-tol, -Inf fails <-tol, NaN satisfies neither.
            # The driver finite gate excludes fit.loglik nonfiniteness, but
            # does not separately require a finite truth objective or dlog.
            metric_states[key] = ((True, False), (False, True), (False, False))
        else:
            # A missing minimum uniqueness makes the full finite gate false.
            metric_states[key] = ((False, True), (False, False), (True, False))
        criteria[key] = tuple(dict.fromkeys(state[0] for state in metric_states[key]))
        if ambiguous:
            ambiguities.append(key)
    if near_ambiguous:
        ambiguities.append("near_uniqueness_floor")
    # Numeric rel errors prove the driver's finite gate was entered. Missing
    # errors cannot distinguish matrix nonfiniteness from scalar norm overflow.
    has_numeric_error = row["rel_G"] is not None or row["rel_R"] is not None
    require(not has_numeric_error or row["min_psi"] is not None, "numeric relative error contradicts nonfinite uniqueness")
    finite_choices = (False,) if row["min_psi"] is None else (True,) if has_numeric_error else (False, True)
    possible = set()
    for finite, g_state, r_state, psi_state, log_state in itertools.product(finite_choices, metric_states["rel_G"], metric_states["rel_R"], metric_states["min_psi"], metric_states["dlog"]):
        g_ok, g_failed = g_state
        r_ok, r_failed = r_state
        psi_ok, psi_failed = psi_state
        log_ok, log_failed = log_state
        recovered = row["converged"] and finite and g_ok and r_ok and psi_ok and log_ok
        klass = ("recovered" if recovered else "nonconverged" if not row["converged"] else "nonfinite" if not finite else
                 "uniqueness_floor" if psi_failed else
                 "G_error" if g_failed else
                 "R_error" if r_failed else
                 "below_truth_objective" if log_failed else "other_failure")
        possible.add((recovered, klass))
    require((row["recovered"], raw["class"]) in possible, f"seed {row['seed']}: recovery/class inconsistent with scalar metrics and precedence")
    row.update(starts=starts, criteria=criteria, ambiguities=ambiguities,
               criterion_failures={key: tuple(dict.fromkeys(state[1] for state in states)) for key, states in metric_states.items()},
               possible_outcomes=[dict(recovered=recovered, primary_class=klass) for recovered, klass in sorted(possible)])
    return row


def validate(tsv, expected_source_sha256, expected_driver_sha256, log=None, allow_partial=False):
    tsv = Path(tsv)
    for value in (expected_source_sha256, expected_driver_sha256):
        require(bool(re.fullmatch(r"[0-9a-f]{64}", value)), "expected hashes must be lowercase SHA-256")
    tsv_bytes = tsv.read_bytes()
    lines = tsv_bytes.decode("utf-8").splitlines()
    require(len(lines) >= 8, "missing manifest/header")
    require(re.fullmatch(r"# ordinary-start FA recovery; mode=primary; timestamp=.+", lines[0]), "manifest must declare primary mode")
    provenance = re.fullmatch(r"# source_tree_sha256=([0-9a-f]{64}); driver_sha256=([0-9a-f]{64}); host=(.+)", lines[1])
    require(provenance is not None, "malformed provenance manifest")
    require(provenance[1] == expected_source_sha256 and provenance[2] == expected_driver_sha256, "source/driver hash mismatch")
    require(re.fullmatch(r"# julia=\S+; threads=4; BLAS_threads=1", lines[2]), "runtime/thread manifest mismatch")
    require(lines[3] == "# seeds=20261200:20261399; attempts=200; iterations=5000", "frozen seed/cap manifest mismatch")
    require(lines[4] == "# DGP: 60 pedigree animals (6 sires,12 dams,42 offspring), 3 records each, T=4,K=1, complete; slack=4", "DGP/slack manifest mismatch")
    require(lines[5] == "# no initial supplied; criteria: conv, finite, relG<=0.45, relR<=0.25, minPsi>=0.0001, dlog>=-1.0e-6, slack>0", "frozen threshold manifest mismatch")
    require(lines[6] == "# thresholds reused from frozen S2 as conservative diagnostics; not a validated ordinary-start accuracy bar", "missing interpretation manifest")
    require(lines[7].split("\t") == HEADER, "header must match exact 23-column contract")
    body = lines[8:]
    summary = SUMMARY.fullmatch(body[-1]) if body else None
    if summary:
        body = body[:-1]
    require(not any(line.startswith("#") for line in body), "unexpected comment or nonterminal summary")
    rows = [parse_row(line.split("\t"), i+9) for i, line in enumerate(body)]
    n = len(rows)
    require(n > 0 and n <= 200, "expected 1 to 200 rows")
    require([r["seed"] for r in rows] == SEEDS[:n], "seeds must be unique ordered frozen primary prefix")
    require(allow_partial or n == 200, "completed mode requires all 200 seeds")
    stats = recovery_statistics(n, sum(r["recovered"] for r in rows))
    if n < 200:
        require(summary is None, "partial stream must not have a terminal campaign summary")
    else:
        require(summary is not None, "completed result requires terminal summary")
        require(int(summary[1]) == n and int(summary[2]) == stats["recovered"], "summary counts mismatch")
        for token, expected in zip(summary.group(3, 4, 5, 6), [stats["rate"], stats["mcse"], *stats["wilson95"]]):
            require(number(token, "summary") is not None, "summary cannot contain NA")
            lo, hi = rounding_interval(token)
            require(lo - Decimal("1e-16") <= Decimal(str(expected)) <= hi + Decimal("1e-16"), "summary rate/MCSE/Wilson mismatch")
        require(log is not None, "completed result requires --log with final WROTE marker")
        log_lines = [s for s in Path(log).read_text(encoding="utf-8").splitlines() if s.strip()]
        require(bool(log_lines) and re.fullmatch(r"WROTE /.+", log_lines[-1]), "log lacks final WROTE marker")
        # Copied outputs can have a different local parent than the remote path.
        require(Path(log_lines[-1][6:]).name == tsv.name, "WROTE marker output basename mismatch")
    classes = Counter(r["class"] for r in rows)
    failures = {}
    for key in ("rel_G", "rel_R", "min_psi", "dlog"):
        failures[key] = dict(definite=sum(r["fit_status"] == "ok" and r["criterion_failures"][key] == (True,) for r in rows),
                             possible=sum(r["fit_status"] == "ok" and True in r["criterion_failures"][key] for r in rows),
                             missing=sum(r["fit_status"] == "ok" and r[key] is None for r in rows))
    failures["nonconverged"] = sum(not r["converged"] for r in rows)
    flags = {key: {group: dict(true=sum(r[key] is True for r in subset), false=sum(r[key] is False for r in subset), missing=sum(r[key] is None for r in subset))
                   for group, subset in (("all", rows), ("recovered", [r for r in rows if r["recovered"]]))} for key in OPTIONAL_BOOLS}
    per_start = {}
    for name in ("default", "balanced"):
        starts = [s for r in rows for s in r["starts"] if s["name"] == name]
        per_start[name] = dict(attempted=len(starts), valid=sum(s["valid"] for s in starts), converged=sum(s["converged"] for s in starts),
                               selected=sum(r["selected_start"] == name for r in rows), iterations=conditional([s["iterations"] for s in starts]))
    limitations = ["Full matrix finiteness, covariance errors, log likelihoods and start objectives cannot be independently recomputed from scalar TSV fields.",
                   "NA conflates nonfinite scalar values: relative errors can be +Inf or NaN, dlog can be either infinity or NaN. These values have distinct Julia comparisons; compatible outcomes are reported, not reconstructed.",
                   "12-significant-digit threshold boundary values admit plausible rounding; listed ambiguous rows are not proof of an exact threshold violation.",
                   "Finite-error summaries condition on available scalars; every exception and nonconvergence stays in the recovery denominator.",
                   "Diagnostic thresholds are not a campaign-level pass cutoff, covered-status decision or release criterion.",
                   "The log marker's basename is checked because copied TSVs can differ from the remote absolute path."]
    return dict(status="complete" if n == 200 else "partial", campaign_complete=n == 200, **stats,
                source_tree_sha256=provenance[1], driver_sha256=provenance[2], tsv_sha256=hashlib.sha256(tsv_bytes).hexdigest(),
                converged=sum(r["converged"] for r in rows), class_counts={k: classes[k] for k in CLASSES},
                convergence_counts=dict(converged=sum(r["converged"] for r in rows),
                                        nonconverged_ok=sum(r["fit_status"] == "ok" and not r["converged"] for r in rows),
                                        exception=classes["exception"]),
                missing_scalar_metric_rows=[dict(seed=r["seed"], fit_status=r["fit_status"], fields=[k for k in ("rel_G", "rel_R", "dlog", "min_psi") if r[k] is None])
                                            for r in rows if any(r[k] is None for k in ("rel_G", "rel_R", "dlog", "min_psi"))],
                overlapping_criterion_failures=failures, diagnostic_flags=flags, per_start=per_start,
                total_start_iterations=sum(s["iterations"] for r in rows for s in r["starts"]),
                finite_error_summaries={group: {k: conditional([r[k] for r in subset]) for k in ("rel_G", "rel_R", "dlog", "min_psi", "seconds")}
                                        for group, subset in (("all", rows), ("recovered", [r for r in rows if r["recovered"]]))},
                threshold_ambiguities=[dict(seed=r["seed"], fields=r["ambiguities"]) for r in rows if r["ambiguities"]],
                scalar_projection_ambiguities=[dict(seed=r["seed"], fields=[key for key in ("rel_G", "rel_R", "dlog", "min_psi") if r[key] is None],
                                                   compatible_outcomes=r["possible_outcomes"])
                                              for r in rows if r["fit_status"] == "ok" and any(r[key] is None for key in ("rel_G", "rel_R", "dlog", "min_psi"))],
                limitations=limitations)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tsv", type=Path)
    parser.add_argument("--expected-source-sha256", required=True)
    parser.add_argument("--expected-driver-sha256", required=True)
    parser.add_argument("--log", type=Path)
    parser.add_argument("--allow-partial", action="store_true")
    args = parser.parse_args(argv)
    try:
        result = validate(args.tsv, args.expected_source_sha256, args.expected_driver_sha256, log=args.log, allow_partial=args.allow_partial)
    except (ValidationError, OSError, InvalidOperation, ValueError) as error:
        print(json.dumps(dict(status="invalid", error=str(error))), file=sys.stderr)
        return 1
    print(json.dumps(result, indent=2, sort_keys=True, allow_nan=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
