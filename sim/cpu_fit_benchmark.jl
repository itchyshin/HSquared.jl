using HSquared
using LinearAlgebra
using SparseArrays
using Printf

"""
OPT-IN CPU benchmark harness for the sparse AI-REML fit path.

This file is deliberately OUTSIDE `test/` — it is NOT part of the committed
CI suite.  The committed suite stays RNG-free; the timings here are wallclock
measurements on the developer's machine and are NOT asserted by CI.

Purpose
-------
Record representative single-threaded wall-clock timings of the sparse CPU
fit path (`fit_ai_reml`) at several pedigree sizes as an honest BASELINE
MEASUREMENT.  This is NOT a competitive claim ("the engine is fast"),
NOT a performance-regression gate, and NOT a CI-enforced bound.  It is the
CPU baseline that a future GPU port (Apple Metal / Compute Canada CUDA) would
be compared against.

What is measured
----------------
For each target pedigree size q (total animals including founders and
offspring):

  1. Build a deterministic half-sib pedigree and invert it (`pedigree_inverse`).
  2. Construct a deterministic response vector `y` (no RNG; structured linear
     trend plus a fixed-seed-free offset so the vector has variation).
  3. Build the `AnimalModelSpec` (`animal_model_spec`).
  4. Warm-up run of `fit_ai_reml` to force JIT compilation.
  5. Three timed runs; report the median elapsed time (seconds).
  6. At the two smaller sizes (q ≤ 500), additionally time
     `prediction_error_variance(fit; method = :selinv)` and
     `prediction_error_variance(fit; method = :dense)`.
     The dense path is O(q³) and is deliberately skipped at q > 500.

Nothing is asserted about the measured values.  All output is printed and
captured in `docs/dev-log/2026-06-20-cpu-fit-benchmark-baseline.md`.

Run from the repository root (single-threaded):

    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \\
        ~/.juliaup/bin/julia --project=. sim/cpu_fit_benchmark.jl
"""

# ---------------------------------------------------------------------------
# Half-sib pedigree generator (same pattern as phase6_poisson_recovery.jl)
# ---------------------------------------------------------------------------

function _halfsib_pedigree(nsire, ndam, noffspring)
    sire_ids = ["s$(i)" for i in 1:nsire]
    dam_ids  = ["d$(i)" for i in 1:ndam]
    off_ids  = ["o$(i)" for i in 1:noffspring]
    ids  = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(fill("0", nsire + ndam),
                [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring])
    dam  = vcat(fill("0", nsire + ndam),
                [dam_ids[((i - 1) % ndam) + 1]  for i in 1:noffspring])
    return normalize_pedigree(ids, sire, dam)
end

# ---------------------------------------------------------------------------
# Deterministic y vector (no RNG)
# ---------------------------------------------------------------------------
# y[i] = 5.0 + 0.3 * (i mod 7) + 0.1 * sin(i * 0.17)
# This produces a vector with numerical variation without requiring a seed.

function _make_y(q)
    return [5.0 + 0.3 * Float64(i % 7) + 0.1 * sin(i * 0.17) for i in 1:q]
end

# ---------------------------------------------------------------------------
# Benchmark a single pedigree size
# ---------------------------------------------------------------------------

function _benchmark_size(nsire, ndam, noffspring; n_rep = 3, run_dense_pev = true)
    ped  = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped)
    q    = length(ped.ids)
    nnz_ainv = nnz(Ainv)

    y = _make_y(q)
    X = ones(q, 1)
    Z = sparse(1.0 * I, q, q)

    spec = animal_model_spec(y, X, Z, Ainv; method = :REML)

    # --- warm-up: force JIT compilation; timing discarded ---
    _ = fit_ai_reml(spec)

    # --- timed fit runs ---
    fit_times = [(@elapsed fit_ai_reml(spec)) for _ in 1:n_rep]
    fit_med   = sort(fit_times)[div(n_rep, 2) + 1]

    fit = fit_ai_reml(spec)

    # --- selinv PEV (O(nnz(L)), always timed) ---
    _ = prediction_error_variance(fit; method = :selinv)   # warm-up
    selinv_times = [(@elapsed prediction_error_variance(fit; method = :selinv)) for _ in 1:n_rep]
    selinv_med   = sort(selinv_times)[div(n_rep, 2) + 1]

    # --- dense PEV (O(q³), only at small q) ---
    dense_med = NaN
    if run_dense_pev
        _ = prediction_error_variance(fit; method = :dense)    # warm-up
        dense_times = [(@elapsed prediction_error_variance(fit; method = :dense)) for _ in 1:n_rep]
        dense_med   = sort(dense_times)[div(n_rep, 2) + 1]
    end

    return (q = q, nnz_ainv = nnz_ainv,
            fit_time_s = fit_med,
            selinv_pev_s = selinv_med,
            dense_pev_s = dense_med)
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

function main()
    println()
    println("HSquared.jl — CPU fit benchmark baseline")
    println("=========================================")
    println("Opt-in measurement only.  NOT a performance claim.")
    println("Machine: developer laptop ($(Sys.MACHINE)), single-threaded")
    println("Julia:   $(VERSION)")
    println("BLAS:    $(BLAS.get_config())")
    println()

    # Pedigree configurations: (nsire, ndam, noffspring)
    # Chosen so total q = nsire + ndam + noffspring approximates the target sizes
    # ~100, ~500, ~2000, ~8000
    configs = [
        (nsire =  5, ndam = 10, noffspring =  85,  label = "q≈100",  dense_pev = true),
        (nsire = 20, ndam = 40, noffspring = 440,  label = "q≈500",  dense_pev = true),
        (nsire = 80, ndam = 160, noffspring = 1760, label = "q≈2000", dense_pev = false),
        (nsire = 320, ndam = 640, noffspring = 7040, label = "q≈8000", dense_pev = false),
    ]

    results = []

    for c in configs
        @printf("  Benchmarking %s  (nsire=%d ndam=%d noffspring=%d)...\n",
                c.label, c.nsire, c.ndam, c.noffspring)
        r = _benchmark_size(c.nsire, c.ndam, c.noffspring;
                            n_rep = 3, run_dense_pev = c.dense_pev)
        push!(results, (label = c.label, r...))
    end

    println()
    println("Results")
    println("-------")
    @printf("%-10s  %8s  %10s  %14s  %15s  %18s\n",
            "Label", "q", "nnz(Ainv)", "fit_ai_reml(s)", "selinv-PEV(s)", "dense-PEV(s)")
    @printf("%-10s  %8s  %10s  %14s  %15s  %18s\n",
            "----------", "--------", "----------", "--------------", "---------------", "------------------")
    for r in results
        dense_str = isnan(r.dense_pev_s) ? "     (skipped)" : @sprintf("%18.4f", r.dense_pev_s)
        @printf("%-10s  %8d  %10d  %14.4f  %15.4f  %s\n",
                r.label, r.q, r.nnz_ainv, r.fit_time_s, r.selinv_pev_s, dense_str)
    end

    println()
    println("Notes")
    println("-----")
    println("  - Median of 3 timed runs after one JIT warm-up run.")
    println("  - dense-PEV skipped at q > 500 (O(q³) cost).")
    println("  - JULIA_NUM_THREADS=1, OPENBLAS_NUM_THREADS=1 for single-threaded baseline.")
    println("  - These numbers are machine-dependent.  No performance claim is made.")
    println()
end

main()
