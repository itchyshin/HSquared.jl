#!/usr/bin/env python3
"""Frozen deterministic seed manifests for the Arc1 Gaussian reliability programme.

The CSV contains every outer data/reference seed. Bootstrap rows are compactly
represented as nested ranges in JSON; verification enumerates every inner seed.
No outcomes or fitted values are read or written here.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import itertools
import json
import re
import subprocess
from pathlib import Path
from typing import Iterator

NAMESPACE = "h2-arc1-gaussian-reliability-20261002-v1"
FA_SIGNALS = ("null", "weak", "strong")
REPEATABILITY_SIGNALS = ("interior", "near_zero_pe", "near_zero_additive")
REPEATABILITY_TRUTHS = {
    "interior": (0.3, 0.2, 0.5),
    "near_zero_pe": (0.3, 0.01, 0.69),
    "near_zero_additive": (0.01, 0.3, 0.69),
}
PHASES = ("development", "pilot", "confirmation")
STREAMS = ("data", "bootstrap", "reference")
PROTOCOL_VERSION = "arc1-seed-manifest-v1"
CSV_FIELDS = ("programme", "phase", "N", "signal", "outer", "inner", "stream", "seed")
def discover_admission_source_paths(root: Path) -> list[str]:
    """Discover engine includes and Arc1 runner, protocol, and test sources."""
    root = root.resolve()
    module_file = root / "src/HSquared.jl"
    if not module_file.is_file():
        raise ValueError("source root lacks src/HSquared.jl")
    include_names = re.findall(r'^\s*include\("([^"/]+)"\)',
                               module_file.read_text(encoding="utf-8"), flags=re.MULTILINE)
    paths = {"src/HSquared.jl", *(f"src/{name}" for name in include_names)}
    for base, patterns in ((root / "sim/arc1", ("*.py", "*.jl", "*.r", "*.md", "*.toml", "*.json", "*.csv")),
                           (root / "tools", ("arc1_*.py",)),
                           (root / "test", ("*.jl", "*.py", "*.r")),
                           (root / "docs/design", ("arc1*.md",)),
                           (root / "LOOP/lanes/arc1-gaussian-reliability-20261002", ("*.md",))):
        if base.exists():
            for pattern in patterns:
                paths.update(path.relative_to(root).as_posix() for path in base.rglob(pattern) if path.is_file())
    return sorted(paths)

# This is the stable protocol identity. Mutable execution notes, manifest file
# hashes, and run status are intentionally outside this object.
SCIENTIFIC_CONTRACT = {
    "contract": "h2-gaussian-reliability-arc1-v1",
    "execution": {"julia_version": "1.10.0", "rng": "Random.MersenneTwister",
                  "seed_type": "UInt64, passed without truncation or modulo reduction",
                  "seed_version_rule": "record exact Julia VERSION at run admission; require 1.10.0"},
    "seed": {
        "namespace": NAMESPACE,
        "canonical_fields": ["namespace", "programme", "phase", "N", "signal-label", "outer-index", "inner-index", "stream"],
        "hash": "SHA-256 UTF-8 pipe-joined fields; UInt64 from first 16 lowercase hex digits",
        "bootstrap_seed_hash": "SHA-256 over ordered ASCII decimal UInt64 seeds, one newline per inner index",
        "indices": "outer and inner 1-based; inner=0 denotes outer-data generation",
        "programmes": ["fa_rank", "fa_interval", "repeatability", "boundary"],
        "phases": ["development", "pilot", "confirmation", "diagnostic"],
        "streams": ["data", "bootstrap", "reference"],
    },
    "allocation": {
        "fa_rank": {"N": [80, 160, 320], "signals": {"null": 0.0, "weak": 0.15, "strong": 0.7},
                                      "development": 30, "pilot": 30, "confirmation": 400},
        "fa_rank_reference": {"preselected_confirmation_outer": [1, 20]},
        "fa_interval": {"N": 160, "signals": {"null": 0.0, "weak": 0.15, "strong": 0.7},
                         "development": 30, "pilot": 30, "confirmation": 400,
                         "bootstrap_B": {"development": 19, "pilot": 199, "confirmation": 499},
                         "endpoint_pilot_round_robin_outer_count": 20,
                         "endpoint_nested_B": [199, 499, 999],
                         "endpoint_primary_result_B": 199,
                         "endpoint_stability_results_B": [499, 999],
                         "endpoint_prefix_usability_checked_independently": True},
        "repeatability": {"N": [80, 160, 320], "signals": {k: list(v) for k, v in REPEATABILITY_TRUTHS.items()},
                          "development": 30, "pilot": 30, "confirmation": 400,
                          "records_per_offspring": 2},
        "boundary": {"N": 160, "signals": {"Va_zero": [0.0, 0.3, 0.7],
                                                  "Vpe_zero": [0.3, 0.0, 0.7]},
                     "diagnostic_each": 200, "records_per_offspring": 2},
    },
    "data_generating_process": {
        "pedigree": {"N_counts": "observed offspring", "sires": "N/8 unrelated founders",
                     "dams_per_sire": 2, "offspring_per_dam": 4,
                     "parents_unobserved": True, "pedigree_size": "11N/8",
                     "relationship_values": {"diagonal": 1.0, "full_sib": 0.5,
                                               "half_sib": 0.25, "unrelated": 0.0}},
        "offspring_genetic_effect": "0.5*sire + 0.5*dam + sqrt(0.5)*independent MVN(0,G) draw",
        "founder_genetic_effects": "independent MVN(0,G) draws",
        "repeatability_permanent_environment": "independent per offspring, variance Vpe",
        "residual": "independent per record; FA records use multivariate covariance R",
        "truth_initializations": False,
        "fa_record_layout": {"records_per_offspring": 1, "traits": 4,
                             "mean": [0.0, 1.0, -1.0, 2.0],
                             "rho": [0.0, 0.15, 0.70],
                             "loading": "sqrt(0.5*rho)*[1,1,-1,-1]'",
                             "loading_sign_vector": [1, 1, -1, -1],
                             "psi": "0.5*(1-rho)", "G": "L*L' + Diagonal(psi)",
                             "diag_G": 0.5, "diag_R": 0.5, "offdiag_R": 0.1,
                             "observation_order": "record-major; y=vec(Y'); V=B⊗G+I⊗R; Xfull=X⊗I4; rotate U'⊗I4"},
        "repeatability": {"fixed_mean": 0.0, "fixed_effect": "intercept",
                          "records_per_offspring": 2, "truth_mapping": REPEATABILITY_TRUTHS},
    },
    "fa_optimizer": {
        "policy": "arc1_v1 opt-in; omitted policy preserves legacy path",
        "objective": "exact spectral REML with analytic gradient",
        "ordinary": {"method": "BFGS", "line_search": "Hager-Zhang",
                     "iterations_per_start": 2000,
                     "optimizer_tolerance": 1e-8, "final_scaled_gradient_inf_norm_max": 1e-6,
                     "K0_starts": "existing single start",
                     "K1_starts": "existing two starts plus 16 deterministic K0-derived starts",
                     "derived_signs": [[1, *[(-1 if mask & (1 << bit) else 1) for bit in range(3)]]
                                        for mask in range(8)],
                     "derived_start_order": "amplitude-major a=(0.1,0.7), then mask=0:7; mask bit 0 flips trait 2",
                     "derived_amplitudes": [0.1, 0.7],
                     "uniqueness_floor": 1e-4,
                     "loading": "L_i=a*s_i*sqrt(g_i-1e-4)",
                     "specific_variance": "psi_i=g_i-L_i^2", "carry_residual_covariance": True},
        "invalid_trials": {
            "policy": "guard callbacks and restart Hager-Zhang from the same iterate/direction with a halved offending step bound",
            "artificial_penalty": False, "feasible_interval_assumption": False,
            "max_domain_restarts": 32, "max_callback_requests": 256,
            "count_separately": ["callback_requests", "objective_evaluations", "rejected_trials", "domain_restarts"],
            "exhaustion": "failed start; restore objective/gradient caches and scratch coordinates; failure step is zero",
            "wolfe": {"delta": 0.1, "sigma": 0.9, "epsilon": 1e-6},
            "verify_returned_step_against_true_objective_and_gradient": True,
            "numerical_gradient_failure_status_preserved": True,
            "finite_difference_verification_tolerance": 5e-6,
            "analytic_gradient_eligibility_threshold": 1e-6,
        },
        "existing_start_construction": {
            "Gbase": "Diagonal(0.5*phenotypic_variance)",
            "Rbase": "Diagonal(0.5*phenotypic_variance)",
            "K0": "g0=max(diag(Gbase),2*uniqueness_floor); transformed g0 plus Cholesky Rbase",
            "K1_start_1": "structured FA rank-1 parameters from Gbase plus Cholesky Rbase",
            "K1_start_2": "loadings=sqrt(0.5)*sqrt(max(diag(Gbase),eps)); uniqueness=max(0.5*phenotypic_variance,2*floor); R0=Rbase",
            "source_baseline": "src/fa_rank_selection.jl:_fa_rank_starts",
        },
        "selection": {"criterion": "-2*raw_REML_loglik + aic_penalty", "parameter_count": {"K0": 14, "K1": 18},
                      "aic_penalty": {"K0": 28, "K1": 36},
                      "tie_tolerance": 1e-6, "tie_favors": "K0"},
        "expanded_reference": {"status": "best found, never claim global optimum",
                               "K0_split": [0.05, 0.15, 0.3, 0.5, 0.7, 0.9],
                               "K1_signs": [[1, *tail] for tail in itertools.product((1, -1), repeat=3)],
                               "K1_sign_order": "lexicographic product order, separate from ordinary engine mask order",
                               "K1_amplitudes": [0.025, 0.1, 0.25, 0.5, 0.7, 0.9, 0.97, 0.995],
                               "each_start": {"method": "BFGS", "line_search": "Hager-Zhang",
                                              "iterations": 10000},
        "top_finite_solutions": 4,
        "top_finite_solutions_scope": "per rank, independently for K0 and K1",
                               "refinement": [{"method": "Nelder-Mead", "iterations": 20000},
                                              {"method": "BFGS", "iterations": 10000}],
                               "maximum_raw_loglik_shortfall": 1e-4},
    },
    "repeatability_profiles": {"targets": ["Va", "Vpe", "Ve", "h2", "t"],
                               "method": "exact REML; analytic scale where available",
                               "boundary": "explicit zero-component reduced models",
                               "lr_chisq1_cutoff": 3.841458820694124,
                               "statuses": ["unconverged", "nuisance_unresolved", "singular", "unbracketed"],
                               "disconnected_profile_sets": "report all components"},
    "profile_search": {
        "method_version": "arc1_profile_v1", "confidence": 0.95,
        "lr_chisq1_cutoff": 3.841458820694124,
        "scale_reference": "s0=OLS residual sum of squares / residual df",
        "ordinary_point_fit": {"method": "BFGS", "line_search": "Hager-Zhang",
                                "iterations_per_start": 2000,
                                "optimizer_tolerance": 1e-8,
                                "final_scaled_gradient_inf_norm_max": 1e-6},
        "fixed_ratio_target_grid": {"step": 0.02, "extra_points": [2**-20, 2**-12, 2**-8],
                                    "also_complements": True, "bounded_refinement": "Brent",
                                    "allocation_tolerance": 1e-7, "likelihood_tolerance": 1e-8,
                                    "max_evaluations_per_bracket": 2000,
                                    "final_certificate": "actual final bracket width <= 1e-7 and raw likelihood spread across endpoints/returned maximum <= 1e-8",
                                    "refinement_and_certificate_share_budget": True,
                                    "compare_valid_exact_endpoints": True},
        "fixed_raw_variance": {"nuisance_starts_s0_multipliers": [0.01, 0.1, 0.5, 1.0, 5.0],
                               "nuisance_start_grid": "Cartesian product squared multipliers",
                               "include_zero_faces_and_intersection": True,
                               "optimizer": "BFGS", "iterations_per_start": 2000,
                               "optimizer_tolerance": 1e-8,
                               "final_scaled_gradient_inf_norm_max": 1e-6,
                               "target_positive_lower_rail": "2^-20*s0",
                               "positive_nuisance_lower": "2^-40*s0",
                               "positive_nuisance_upper": "1e6*s0",
                               "competitive_bound_hit_or_better_unconverged": "nuisance_unresolved"},
        "ratio_target_search": {"grid_step": 0.02, "include_point_estimate": True,
                                "max_initial_gap": 0.005,
                                "refine": ["observed crossings", "cutoff-adjacent regions",
                                           "sampled local maxima", "midpoint-linear LR difference > 0.05"],
                                "max_grid_width": 0.00025, "root_tolerance": 1e-6,
                                "max_distinct_evaluations_per_target": 4097},
        "raw_variance_target_search": {"initial_points": ["zero", "point estimate", "s0*2^(j/2), j=-40:8"],
                                       "positive_gap_max_octaves": 0.125,
                                       "zero_first_gap_max": "1e-6*s0",
                                       "densify_complete_rail_including_tail_extensions": True,
                                       "upper_tail_extension": "double until four successive outside-cutoff points with decreasing profile likelihood",
                                       "hard_upper_bound": "1e6*s0", "root_tolerance": "1e-6*s0",
                                       "max_distinct_evaluations_per_target": 4097,
                                       "unbracketed_at_bound": "explicit refusal"},
        "common_unrestricted_maximum": True,
        "maximum_check_includes_valid_evaluations_from_failed_nuisance_searches": True,
        "point_fit_violation_max": 1e-7,
        "point_fit_violation_refusal": "point_fit_not_optimal",
        "analytic_exclusions": ["exact ratio-one boundary", "zero-residual boundary"],
        "certified_zero_face_resolution": {
            "scope": "matching competitive positive lower-bound approximations only",
            "projectable_nuisance_components": ["Va", "Vpe"],
            "all_contacts_must_be_lower_bounds": True,
            "preserve_fixed_target_and_other_components": True,
            "require_certified_matching_face_or_intersection": True,
            "raw_loglikelihood_agreement_max": 1e-8,
            "remaining_log_gradient_inf_norm_max": 1e-6,
            "dimensionless_one_sided_derivative": "s0*dq/dv, finite and >5e-6",
            "independent_forward_derivative": "(-3q(0)+4q(h)-q(2h))/(2h) in v/s0 coordinates",
            "finite_difference_steps": [1e-4, 1e-5],
            "finite_difference_estimates_nonnegative": True,
            "finite_difference_agreement_max": 5e-6,
            "retain_original_failure_and_separate_zero_face_status": True,
            "upper_bounds_and_unrelated_failed_competitors_resolved": False,
        },
        "reduced_models": ["zero additive variance", "zero permanent-environment variance",
                           "h2 zero", "repeatability zero"],
        "unresolved_evaluation": "do not interpolate across; retain disconnected components, domain, gaps, refinement history, brackets, tail evidence, and nuisance statuses",
        "search_claim_limit": "finite_grid_resolved describes declared search only; narrower unsampled components are not ruled out",
    },
    "interval_contract": {
        "repeatability_targets": ["Va", "Vpe", "Ve", "h2", "t"],
        "repeatability_method": "profile likelihood ratio with explicit zero-component reductions",
        "fa_h2_targets": ["h2_1", "h2_2", "h2_3", "h2_4"],
        "fa_h2_formula": "G_ii/(G_ii+R_ii)",
        "fa_bootstrap": "candidate percentile; rerun entire selector in every inner sample; fixed B",
        "bootstrap_usability": {"usable_fraction_min": 0.99,
                                "fixed_attempts": True,
                                "failed_inner_attempts_are_retained": True,
                                "outer_fit_failure": "record refusal stage and status; no inner attempts"},
        "fa_pilot": {"N": 160, "outer_per_signal": 30, "B": 199,
                     "formed_min": 29, "all_target_all_attempt_coverage": [0.85, 1.0]},
        "endpoint_pilot": {"preselected_outer_count": 20, "nested_B": [199, 499, 999],
                           "primary_result_B": 199, "stability_results_B": [499, 999],
                           "each_prefix_has_independent_usability_check": True,
                           "max_difference_0_02_min": 18, "max_difference_0_05_max": 0},
        "confirmation": {"outer_per_signal": 400, "B": 499,
                         "formation_fraction_min": 0.99,
                         "coverage_wilson_confidence": 0.90,
                         "coverage_wilson_bounds": [0.92, 0.98],
                         "finite_ordered_intervals": True},
        "failure_policy": "retain failed attempts; no replacement; failed pilot holds confirmation",
    },
    "rank_selection_gate": {
        "allocation": "30 development + 30 pilot + 400 confirmation per each of 9 cells",
        "pilot_screen": {"both_candidate_available_min": 29, "denominator": 30,
                         "expanded_reference_all_good": True, "null_K1_max": 6,
                         "strong_N320_K1_min": 24},
        "confirmation": {"eligibility_wilson95_lower_min": 0.90,
                         "null_K1_wilson95_upper_max": 0.20,
                         "strong_N320_K1_wilson95_lower_min": 0.80,
                         "denominator": "all attempts including failed/unavailable"},
    },
    "rank_selection": {"score": "-2*raw_REML_loglik + aic_penalty",
                       "parameter_count": {"K0": 14, "K1": 18},
                       "aic_penalty": {"K0": 28, "K1": 36},
                       "tie_tolerance": 1e-6, "pilot_numerical_minimum_available": 29,
                       "null_pilot_K1_max": 6, "strong_N320_pilot_K1_min": 24,
                       "eligible_wilson95_lower_min": 0.90, "null_K1_wilson95_upper_max": 0.20,
                       "strong_N320_K1_wilson95_lower_min": 0.80},
    "global_failure_rule": "failed pilot holds confirmation; failed confirmation gate remains unmet",
}


def contract_sha256() -> str:
    return contract_sha256_for(SCIENTIFIC_CONTRACT)


def contract_sha256_for(contract: dict[str, object]) -> str:
    return hashlib.sha256(json.dumps(contract, sort_keys=True,
                                     separators=(",", ":")).encode("utf-8")).hexdigest()


def _file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def build_run_admission(root: Path, cell: dict[str, object], *, source_paths: list[str],
                        julia_version: str, julia_threads: int, blas_threads: int,
                        manifest_audit_root: Path | None = None) -> dict[str, object]:
    """Pin source, environment, exact seeds, and execution settings before a cell run."""
    root = root.resolve()
    if julia_version != "1.10.0":
        raise ValueError("Arc1 admitted run requires Julia 1.10.0")
    if julia_threads < 1 or blas_threads < 1:
        raise ValueError("thread counts must be positive integers")
    manifest_path = root / "sim/arc1/manifests/arc1_seed_manifest.json"
    manifest_verification = verify_manifest(manifest_path, audit_root=manifest_audit_root or root)
    required = {"programme", "phase", "N", "signal"}
    if not required.issubset(cell):
        raise ValueError("cell pin is missing programme/phase/N/signal")
    count = _cell_outer_count(cell)
    outer_seeds = [seed_for(str(cell["programme"]), str(cell["phase"]), int(cell["N"]),
                            str(cell["signal"]), i, 0, "data") for i in range(1, count + 1)]
    bootstrap_seeds: dict[str, list[int]] = {}
    if cell["programme"] == "fa_interval":
        for outer in range(1, count + 1):
            budget = _expected_bootstrap_budget(cell, outer)
            bootstrap_seeds[str(outer)] = [seed_for("fa_interval", str(cell["phase"]), int(cell["N"]),
                                                    str(cell["signal"]), outer, inner, "bootstrap")
                                           for inner in range(1, budget + 1)]
    paths = sorted(set(source_paths) | set(discover_admission_source_paths(root)) |
                   {"Project.toml", "Manifest.toml"})
    hashes: dict[str, str] = {}
    for relative in paths:
        rel = Path(relative)
        if rel.is_absolute() or ".." in rel.parts:
            raise ValueError(f"admission path must remain inside repository: {relative}")
        file = (root / rel).resolve()
        if not file.is_relative_to(root) or not file.is_file():
            raise ValueError(f"admission source is missing or outside repository: {relative}")
        hashes[rel.as_posix()] = _file_sha256(file)
    return {"schema": "arc1-run-admission-v1", "protocol_sha256": contract_sha256(),
            "cell": dict(cell), "planned_attempts": count, "expected_outer_seeds": outer_seeds,
            "expected_bootstrap_seeds": bootstrap_seeds,
            "source_sha256": hashes,
            "environment_sha256": {key: hashes[key] for key in ("Project.toml", "Manifest.toml")},
            "manifest_verification": manifest_verification,
            "seed_manifest_sha256": hashes["sim/arc1/manifests/arc1_seed_manifest.json"],
            "outer_csv_sha256": hashes["sim/arc1/manifests/arc1_outer_seeds.csv"],
            "julia_version": julia_version,
            "threads": {"julia": julia_threads, "blas": blas_threads},
            "thread_environment": {"JULIA_NUM_THREADS": str(julia_threads),
                                   "OPENBLAS_NUM_THREADS": str(blas_threads)},
            "status": "admitted_before_execution"}


def validate_candidate_manifest(root: Path) -> None:
    """Fast integrity check; exhaustive seed validation belongs to initial admission."""
    root = root.resolve()
    json_path = root / "sim/arc1/manifests/arc1_seed_manifest.json"
    csv_path = root / "sim/arc1/manifests/arc1_outer_seeds.csv"
    if not json_path.is_file() or not csv_path.is_file():
        raise ValueError("canonical Arc1 seed manifest files are missing")
    value = json.loads(json_path.read_text(encoding="utf-8"))
    canonical_contract = json.loads(json.dumps(SCIENTIFIC_CONTRACT, sort_keys=True))
    if value.get("scientific_contract") != canonical_contract or \
       value.get("protocol_sha256") != contract_sha256():
        raise ValueError("candidate seed manifest is stale and not admitted for execution")
    if value.get("outer_csv_sha256") != _file_sha256(csv_path):
        raise ValueError("candidate outer-seed CSV hash does not match its manifest pin")


def verify_execution_identity(root: Path, admission: dict[str, object], identity: dict[str, object]) -> None:
    """Check an executor's runtime report against the admitted engine and environment pins."""
    if not isinstance(identity, dict):
        raise ValueError("successful fit lacks runtime execution identity")
    hashes = admission["source_sha256"]
    engine_sources = {path: digest for path, digest in hashes.items() if path.startswith("src/")}
    if identity.get("engine_package_uuid") != "a0667dea-0f38-44e8-9150-4fda00624eac" or \
       identity.get("engine_module_path") != str((root.resolve() / "src/HSquared.jl")):
        raise ValueError("runtime loaded engine identity differs from the admitted HSquared source")
    modules = identity.get("loaded_module_names")
    if not isinstance(modules, list) or "HSquared" not in modules:
        raise ValueError("runtime report does not identify the loaded HSquared module")
    if identity.get("loaded_engine_source_sha256") != engine_sources:
        raise ValueError("runtime loaded engine source set/hash differs from admission")
    if identity.get("source_sha256_at_load") != engine_sources or \
       identity.get("source_sha256_after_load") != engine_sources:
        raise ValueError("runtime load-time/final source pins differ from admitted engine bytes")
    if identity.get("environment_sha256") != admission.get("environment_sha256"):
        raise ValueError("runtime dependency environment differs from admitted Project/Manifest")
    if identity.get("active_project") != str(root.resolve() / "Project.toml"):
        raise ValueError("runtime active Julia project differs from the admitted source root")
    dependencies = identity.get("loaded_dependencies")
    if identity.get("dependency_environment_verified") is not True or not isinstance(dependencies, list):
        raise ValueError("runtime loaded dependency identities were not verified against Manifest.toml")
    seen_dependency_uuids = set()
    for dependency in dependencies:
        if not isinstance(dependency, dict) or not all(
                isinstance(dependency.get(key), str) for key in ("name", "uuid", "version", "tree_hash", "source")):
            raise ValueError("runtime dependency identity is incomplete")
        if dependency["uuid"] in seen_dependency_uuids:
            raise ValueError("runtime dependency identity contains a duplicate UUID")
        seen_dependency_uuids.add(dependency["uuid"])
    if identity.get("julia_version") != admission.get("julia_version") or \
       identity.get("julia_threads") != admission["threads"]["julia"] or \
       identity.get("blas_runtime_threads") != admission["threads"]["blas"]:
        raise ValueError("runtime Julia/BLAS thread identity differs from admission")
    if identity.get("thread_environment") != admission.get("thread_environment"):
        raise ValueError("runtime thread environment differs from admission")
    if not isinstance(identity.get("blas_vendor"), str) or not identity["blas_vendor"]:
        raise ValueError("runtime identity must retain the BLAS vendor")


def _cell_outer_count(cell: dict[str, object]) -> int:
    programme, phase = cell.get("programme"), cell.get("phase")
    n, signal = cell.get("N"), cell.get("signal")
    if programme == "fa_rank":
        valid = n in {80, 160, 320} and signal in FA_SIGNALS
        allowed_phases = {"development": 30, "pilot": 30, "confirmation": 400}
    elif programme == "repeatability":
        valid = n in {80, 160, 320} and signal in REPEATABILITY_SIGNALS
        allowed_phases = {"development": 30, "pilot": 30, "confirmation": 400}
    elif programme == "fa_interval":
        valid = n == 160 and signal in FA_SIGNALS
        allowed_phases = {"development": 30, "pilot": 30, "confirmation": 400}
    elif programme == "boundary":
        valid = n == 160 and signal in {"Va_zero", "Vpe_zero"}
        allowed_phases = {"diagnostic": 200}
    else:
        valid, allowed_phases = False, {}
    expected = allowed_phases.get(str(phase), 0) if valid else 0
    if expected <= 0:
        raise ValueError("cell is outside the frozen Arc1 allocation")
    return expected


def _expected_bootstrap_budget(cell: dict[str, object], outer: int) -> int:
    phase = str(cell["phase"])
    if phase == "development":
        return 19
    if phase == "confirmation":
        return 499
    pooled = (outer - 1) * len(FA_SIGNALS) + FA_SIGNALS.index(str(cell["signal"])) + 1
    return 999 if pooled <= 20 else 199


def verify_run_admission(root: Path, admission: dict[str, object], *, julia_version: str,
                         julia_threads: int, blas_threads: int) -> None:
    """Fail closed on protocol, source, dependency, seed, or execution drift at resume."""
    root = root.resolve()
    if admission.get("schema") != "arc1-run-admission-v1":
        raise ValueError("unsupported Arc1 run admission schema")
    if admission.get("protocol_sha256") != contract_sha256():
        raise ValueError("Arc1 canonical protocol changed since run admission")
    if admission.get("julia_version") != julia_version or julia_version != "1.10.0":
        raise ValueError("Julia version differs from the admitted run")
    if admission.get("threads") != {"julia": julia_threads, "blas": blas_threads}:
        raise ValueError("Julia/BLAS thread counts differ from the admitted run")
    if admission.get("thread_environment") != {"JULIA_NUM_THREADS": str(julia_threads),
                                               "OPENBLAS_NUM_THREADS": str(blas_threads)}:
        raise ValueError("thread environment pins disagree with the admitted Julia/BLAS counts")
    manifest_path = root / "sim/arc1/manifests/arc1_seed_manifest.json"
    csv_path = root / "sim/arc1/manifests/arc1_outer_seeds.csv"
    if admission.get("seed_manifest_sha256") != _file_sha256(manifest_path) or \
       admission.get("outer_csv_sha256") != _file_sha256(csv_path):
        raise ValueError("seed manifest or CSV bytes changed after exhaustive admission verification")
    verified_manifest = admission.get("manifest_verification")
    if not isinstance(verified_manifest, dict) or \
       verified_manifest.get("protocol_sha256") != contract_sha256() or \
       verified_manifest.get("outer_csv_sha256") != admission.get("outer_csv_sha256"):
        raise ValueError("admission lacks successful exhaustive seed-manifest verification")
    environment = admission.get("environment_sha256")
    source_hashes = admission.get("source_sha256")
    if not isinstance(environment, dict) or not isinstance(source_hashes, dict) or \
       environment != {name: source_hashes.get(name) for name in ("Project.toml", "Manifest.toml")}:
        raise ValueError("environment hash mapping disagrees with pinned Project/Manifest bytes")
    cell = admission.get("cell")
    if not isinstance(cell, dict):
        raise ValueError("admission lacks a pinned cell")
    expected_count = _cell_outer_count(cell)
    if admission.get("planned_attempts") != expected_count:
        raise ValueError("planned attempt count differs from the frozen allocation")
    seeds = [seed_for(str(cell["programme"]), str(cell["phase"]), int(cell["N"]),
                      str(cell["signal"]), i, 0, "data") for i in range(1, expected_count + 1)]
    if admission.get("expected_outer_seeds") != seeds:
        raise ValueError("outer seed partition differs from the canonical allocation")
    bootstrap = admission.get("expected_bootstrap_seeds")
    expected_bootstrap: dict[str, list[int]] = {}
    if cell.get("programme") == "fa_interval":
        for outer in range(1, expected_count + 1):
            budget = _expected_bootstrap_budget(cell, outer)
            expected_bootstrap[str(outer)] = [seed_for("fa_interval", str(cell["phase"]), int(cell["N"]),
                                                       str(cell["signal"]), outer, inner, "bootstrap")
                                              for inner in range(1, budget + 1)]
    if bootstrap != expected_bootstrap:
        raise ValueError("bootstrap seed partition differs from the canonical allocation")
    hashes = admission.get("source_sha256")
    if not isinstance(hashes, dict) or not hashes:
        raise ValueError("admission lacks source hashes")
    discovered = set(discover_admission_source_paths(root))
    if not discovered.issubset(hashes):
        raise ValueError("admission omits dynamically discovered engine, protocol, or test sources")
    for relative, expected_digest in hashes.items():
        path = (root / relative).resolve()
        if not path.is_relative_to(root) or not path.is_file() or _file_sha256(path) != expected_digest:
            raise ValueError(f"source or dependency bytes differ from the admitted run: {relative}")
    validate_candidate_manifest(root)


def fa_sign_patterns() -> list[list[int]]:
    """Ordinary K1 derived-start sign order used by Julia masks 0:7."""
    return [[1, *[(-1 if mask & (1 << bit) else 1) for bit in range(3)]]
            for mask in range(8)]


_INTEGER_LITERAL = re.compile(r"(?<![\w.])(?:0[xX][0-9a-fA-F]{1,16}|\d{1,20})(?![\w.])")
_SEED_CONTEXT = re.compile(r"\b(seed|seeds|rng|mersenne.?twister)\b", re.IGNORECASE)


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def historical_seed_audit(root: Path) -> dict[str, object]:
    """Scan tracked source and seed/manifests for historic literals, not outcomes.

    This bounded audit excludes generated result/receipt trees, binary fixtures,
    and large log/output files. It records every scanned/excluded path and hash.
    Only integer literals on lines explicitly mentioning seed/RNG are collected.
    """
    listing = subprocess.run(["git", "ls-files", "-z", "--", "sim", "test", "docs/dev-log"],
                            cwd=root, check=True, stdout=subprocess.PIPE).stdout
    tracked = [item.decode("utf-8") for item in listing.split(b"\0") if item]
    scanned: list[dict[str, object]] = []
    excluded: list[dict[str, object]] = []
    literals: set[int] = set()
    source_ext = {".jl", ".r", ".py", ".sh"}
    seed_ext = source_ext | {".md", ".txt", ".csv", ".tsv", ".json", ".yaml", ".yml"}
    for rel in tracked:
        path = root / rel
        lower = rel.lower()
        basename = Path(rel).name.lower()
        in_sim_test = rel.startswith(("sim/", "test/"))
        in_devlog = rel.startswith("docs/dev-log/")
        if rel.startswith("test/test_arc1") or rel.startswith("sim/arc1/"):
            continue
        if in_sim_test:
            source_candidate = path.suffix.lower() in source_ext and "/fixtures/" not in rel
            manifest_candidate = any(token in basename for token in ("seed", "manifest")) and path.suffix.lower() in seed_ext
            if not (source_candidate or manifest_candidate):
                continue
        elif in_devlog:
            doc_candidate = path.suffix.lower() in {".md", ".txt"}
            manifest_candidate = any(token in lower for token in ("seed", "manifest")) and path.suffix.lower() in seed_ext
            if not (doc_candidate or manifest_candidate):
                continue
            # Executed receipts, raw outputs, and indexed check logs are not seed sources.
            if any(token in lower for token in ("check-log.d/", "/receipt", "/results/", "/outputs/", ".jsonl", ".log")) and not manifest_candidate:
                continue
        else:
            continue
        size = path.stat().st_size
        file_hash = _sha256_file(path)
        if size > 2_000_000:
            excluded.append({"path": rel, "sha256": file_hash, "bytes": size,
                             "reason": "large tracked log/output excluded from literal scan"})
            continue
        found: set[int] = set()
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except UnicodeDecodeError:
            excluded.append({"path": rel, "sha256": file_hash, "bytes": size,
                             "reason": "non-UTF8 tracked file excluded"})
            continue
        for line in lines:
            if not _SEED_CONTEXT.search(line):
                continue
            for match in _INTEGER_LITERAL.finditer(line):
                literal = match.group(0)
                try:
                    value = int(literal, 16 if literal.lower().startswith("0x") else 10)
                except ValueError:
                    continue
                if 0 <= value <= 2**64 - 1:
                    found.add(value)
        literals.update(found)
        scanned.append({"path": rel, "sha256": file_hash, "bytes": size,
                        "distinct_seed_context_literals": len(found)})
    return {
        "scope": "tracked sim/ and test/ source plus tracked docs/dev-log Markdown/text; only seed-context integer literals",
        "inclusion_rules": ["tracked sim/ and test/ source files with extensions .jl/.r/.py/.sh, excluding fixtures and the current Arc1 manifest/tests",
                            "tracked sim/ and test/ seed/manifest files with extensions .jl/.r/.py/.sh/.md/.txt/.csv/.tsv/.json/.yaml/.yml",
                            "tracked docs/dev-log .md/.txt files and seed/manifest files; receipt/result/output/check-log.d/log/jsonl paths excluded unless named as a seed manifest",
                            "only integer literals on lines containing seed, seeds, rng, or MersenneTwister are extracted"],
        "scanned_paths": scanned,
        "excluded_paths": excluded,
        "unique_integer_literals": sorted(literals),
        "limitations": ["no broad Git history scan", "result/receipt/check-log trees excluded",
                        "code literals in compound expressions may be conservatively included",
                        "this audit establishes no complete historical seed inventory"],
    }


def seed_for(programme: str, phase: str, n: int, signal: str,
             outer: int, inner: int, stream: str) -> int:
    """Return frozen UInt64 seed derived from the canonical pipe-joined tuple."""
    if programme not in {"fa_rank", "fa_interval", "repeatability", "boundary"}:
        raise ValueError(f"invalid programme: {programme}")
    if phase not in {*PHASES, "diagnostic"}:
        raise ValueError(f"invalid phase: {phase}")
    if stream not in STREAMS:
        raise ValueError(f"invalid stream: {stream}")
    allowed_signals = {
        "fa_rank": FA_SIGNALS, "fa_interval": FA_SIGNALS,
        "repeatability": REPEATABILITY_SIGNALS, "boundary": ("Va_zero", "Vpe_zero"),
    }[programme]
    if signal not in allowed_signals:
        raise ValueError(f"invalid {programme} signal label: {signal}")
    if n <= 0 or outer <= 0 or inner < 0 or (inner == 0 and stream == "bootstrap"):
        raise ValueError("N/outer must be positive; bootstrap inner indices start at one")
    fields = (NAMESPACE, programme, phase, str(n), signal, str(outer), str(inner), stream)
    digest = hashlib.sha256("|".join(fields).encode("utf-8")).hexdigest()
    return int(digest[:16], 16)


def bootstrap_seed_sha256(programme: str, phase: str, n: int, signal: str,
                          outer: int, budget: int) -> str:
    """Hash the ordered inner bootstrap seeds as ASCII decimal lines."""
    if budget <= 0:
        raise ValueError("bootstrap budget must be positive")
    payload = "".join(
        f"{seed_for(programme, phase, n, signal, outer, inner, 'bootstrap')}\n"
        for inner in range(1, budget + 1)
    )
    return hashlib.sha256(payload.encode("ascii")).hexdigest()


def outer_rows() -> Iterator[dict[str, str | int]]:
    """Enumerate outer data seeds; reference analyses reuse these datasets."""
    for programme in ("fa_rank", "repeatability"):
        signals = FA_SIGNALS if programme == "fa_rank" else REPEATABILITY_SIGNALS
        for n in (80, 160, 320):
            for signal in signals:
                for phase, count in (("development", 30), ("pilot", 30), ("confirmation", 400)):
                    for outer in range(1, count + 1):
                        yield _row(programme, phase, n, signal, outer, 0, "data")
    for signal in FA_SIGNALS:
        for phase, count in (("development", 30), ("pilot", 30), ("confirmation", 400)):
            for outer in range(1, count + 1):
                yield _row("fa_interval", phase, 160, signal, outer, 0, "data")
    # Exact-zero boundary diagnostics, 200 each.
    for signal in ("Va_zero", "Vpe_zero"):
        for outer in range(1, 201):
            yield _row("boundary", "diagnostic", 160, signal, outer, 0, "data")


def _row(programme: str, phase: str, n: int, signal: str,
         outer: int, inner: int, stream: str) -> dict[str, str | int]:
    return {"programme": programme, "phase": phase, "N": n, "signal": signal,
            "outer": outer, "inner": inner, "stream": stream,
            "seed": seed_for(programme, phase, n, signal, outer, inner, stream)}


def nested_ranges() -> list[dict[str, object]]:
    """Describe all bootstrap prefixes; ranges share identical seed prefixes."""
    ranges: list[dict[str, object]] = []
    for phase, count, budget in (("development", 30, 19), ("pilot", 30, 199),
                                 ("confirmation", 400, 499)):
        for signal in FA_SIGNALS:
            for outer in range(1, count + 1):
                pooled = (outer - 1) * len(FA_SIGNALS) + FA_SIGNALS.index(signal) + 1
                endpoint = phase == "pilot" and pooled <= 20
                ranges.append({"programme": "fa_interval", "phase": phase, "N": 160,
                               "signal": signal, "outer": outer, "stream": "bootstrap",
                               "inner_start": 1, "inner_stop": 999 if endpoint else budget,
                               "endpoint": endpoint,
                               "result_prefixes": [199, 499, 999] if endpoint else [budget],
                               "primary_result_B": 199 if endpoint else budget})
    return ranges


def iter_all_seed_records() -> Iterator[tuple[str, tuple[object, ...], int]]:
    """Yield every compact and nested seed with its unique semantic key."""
    for row in outer_rows():
        key = tuple(row[k] for k in CSV_FIELDS[:-1])
        yield "outer", key, int(row["seed"])
    for spec in nested_ranges():
        for inner in range(int(spec["inner_start"]), int(spec["inner_stop"]) + 1):
            row = _row(str(spec["programme"]), str(spec["phase"]), int(spec["N"]),
                       str(spec["signal"]), int(spec["outer"]), inner, "bootstrap")
            key = tuple(row[k] for k in CSV_FIELDS[:-1])
            yield "nested", key, int(row["seed"])


def validate(root: Path | None = None) -> dict[str, object]:
    """Exhaustively check semantic-key uniqueness and UInt64 seed collisions."""
    root = root or Path(__file__).resolve().parents[1]
    historical = historical_seed_audit(root)
    historical_seeds = set(historical["unique_integer_literals"])
    keys: set[tuple[object, ...]] = set()
    seeds: dict[int, tuple[object, ...]] = {}
    counts = {"outer": 0, "nested": 0}
    for kind, key, seed in iter_all_seed_records():
        if seed in historical_seeds:
            raise ValueError(f"fresh seed collides with historical seed-context literal {seed}")
        if key in keys:
            raise ValueError(f"duplicate manifest key: {key}")
        if seed in seeds:
            raise ValueError(f"UInt64 seed collision: {seed} for {seeds[seed]} and {key}")
        keys.add(key)
        seeds[seed] = key
        counts[kind] += 1
    return {"unique_keys": len(keys), "unique_seeds": len(seeds), **counts,
            "historical_seed_audit": historical}


def write_manifest(outdir: Path, *, audit_root: Path | None = None) -> dict[str, object]:
    outdir.mkdir(parents=True, exist_ok=True)
    checked = validate(audit_root or Path(__file__).resolve().parents[1])
    validation_counts = {key: checked[key] for key in ("unique_keys", "unique_seeds", "outer", "nested")}
    csv_path = outdir / "arc1_outer_seeds.csv"
    with csv_path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=CSV_FIELDS, lineterminator="\n")
        writer.writeheader()
        writer.writerows(outer_rows())
    csv_sha = hashlib.sha256(csv_path.read_bytes()).hexdigest()
    protocol = {
        "schema": PROTOCOL_VERSION,
        "namespace": NAMESPACE,
        "scientific_contract": SCIENTIFIC_CONTRACT,
        "protocol_sha256": contract_sha256(),
        "seed_rule": "first 16 hex digits of SHA-256(UTF-8(pipe-joined canonical fields)); UInt64",
        "canonical_fields": ["namespace", "programme", "phase", "N", "signal-label", "outer-index", "inner-index", "stream"],
        "indices": {"outer": "1-based", "inner": "1-based for nested; 0 denotes outer-data generation"},
        "signals": {"fa": list(FA_SIGNALS), "repeatability": list(REPEATABILITY_SIGNALS),
                    "boundary": ["Va_zero", "Vpe_zero"]},
        "reference_reuse": {"fa_rank_confirmation_outer_indices": [1, 20],
                            "fa_interval_endpoint_pilot_order": FA_SIGNALS,
                            "endpoint_outer_indices_by_signal": {signal: list(range(1, 8 if signal != "strong" else 7)) for signal in FA_SIGNALS},
                            "reference_uses_same_outer_data_seed": True,
                            "reference_rng_seeds_generated": False,
                            "reference_search_is_deterministic": True},
        "outer_rows": len(list(outer_rows())),
        "nested_seed_ranges": nested_ranges(),
        "nested_seed_rows_exhaustively_validated": checked["nested"],
        "all_seed_rows_exhaustively_validated": checked["unique_seeds"],
        "validation": validation_counts,
        "historical_seed_audit": checked["historical_seed_audit"],
        "outer_csv": csv_path.name,
        "outer_csv_sha256": csv_sha,
        "scope_note": "Seed allocation only. No data, truth starts, fits, or outcomes are present.",
    }
    json_path = outdir / "arc1_seed_manifest.json"
    json_path.write_text(json.dumps(protocol, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    audit = checked["historical_seed_audit"]
    return {"json": str(json_path), "csv": str(csv_path),
            "unique_keys": checked["unique_keys"], "unique_seeds": checked["unique_seeds"],
            "outer": checked["outer"], "nested": checked["nested"],
            "historical_paths_scanned": len(audit["scanned_paths"]),
            "historical_paths_excluded": len(audit["excluded_paths"]),
            "historical_literals_checked": len(audit["unique_integer_literals"]),
            "protocol_sha256": protocol["protocol_sha256"], "outer_csv_sha256": csv_sha}


def verify_manifest(json_path: Path, *, audit_root: Path | None = None) -> dict[str, object]:
    """Verify frozen descriptor, compact CSV, and every materialized seed."""
    manifest = json.loads(json_path.read_text(encoding="utf-8"))
    recorded_protocol_hash = manifest.get("protocol_sha256")
    canonical_contract = json.loads(json.dumps(SCIENTIFIC_CONTRACT, sort_keys=True))
    if recorded_protocol_hash != contract_sha256() or manifest.get("scientific_contract") != canonical_contract:
        raise ValueError("manifest scientific protocol identity mismatch")
    if manifest.get("schema") != PROTOCOL_VERSION or manifest.get("namespace") != NAMESPACE:
        raise ValueError("manifest schema or namespace mismatch")
    if manifest.get("nested_seed_ranges") != nested_ranges():
        raise ValueError("nested seed ranges differ from the frozen allocation")
    current_audit = historical_seed_audit(audit_root or json_path.resolve().parents[3])
    if manifest.get("historical_seed_audit") != current_audit:
        raise ValueError("tracked historical seed audit paths or hashes changed")
    csv_path = json_path.parent / str(manifest.get("outer_csv"))
    csv_bytes = csv_path.read_bytes()
    csv_hash = hashlib.sha256(csv_bytes).hexdigest()
    if csv_hash != manifest.get("outer_csv_sha256"):
        raise ValueError("outer CSV SHA-256 mismatch")
    with csv_path.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    expected_rows = list(outer_rows())
    if rows != [{key: str(value) for key, value in row.items()} for row in expected_rows]:
        raise ValueError("outer CSV rows differ from deterministic seed allocation")
    counts = validate(audit_root or json_path.resolve().parents[3])
    validation_counts = {key: counts[key] for key in ("unique_keys", "unique_seeds", "outer", "nested")}
    if manifest.get("validation") != validation_counts or manifest.get("all_seed_rows_exhaustively_validated") != counts["unique_seeds"]:
        raise ValueError("manifest exhaustive seed validation counts mismatch")
    return {"outer_rows": len(rows), **counts, "protocol_sha256": recorded_protocol_hash,
            "outer_csv_sha256": csv_hash}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--outdir", type=Path, default=Path("sim/arc1/manifests"))
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()
    result = validate() if args.validate_only else write_manifest(args.outdir)
    if args.validate_only:
        audit = result["historical_seed_audit"]
        result = {key: value for key, value in result.items() if key != "historical_seed_audit"}
        result.update({"historical_paths_scanned": len(audit["scanned_paths"]),
                       "historical_paths_excluded": len(audit["excluded_paths"]),
                       "historical_literals_checked": len(audit["unique_integer_literals"])})
    print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    main()
