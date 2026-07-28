#!/usr/bin/env julia
# F6 — matrix-free-vs-exact CROSSOVER measurement on high-fill pedigrees. OPT-IN, NOT CI.
#
# WHY this exists.  F0 (`sim/drac/f0_adversarial_fill.jl`,
# `docs/dev-log/recovery-checkpoints/2026-07-24-f0-adversarial-highfill-decision.md`) established
# that `fit_ai_reml` walls on HIGH-FILL pedigrees, and that the wall is the per-iteration
# Takahashi SELECTED INVERSE (381 s of the 1529 s q=20 000 fit), not the Cholesky (0.35 s).
# F6 replaces that exact trace with a matrix-free Hutchinson estimator + PCG solves
# (`fit_matrix_free_reml`).  This harness measures the resulting crossover: at what fill does the
# stochastic matrix-free fitter overtake the exact one, and how much accuracy does that cost?
#
# It measures TWO axes at once, and both matter:
#   * WALL CLOCK  — exact / matrix-free ratio (>1 means matrix-free wins);
#   * ACCURACY    — relative difference of the recovered variance components vs the exact optimum,
#                   which is Monte-Carlo error (∝ 1/√nprobe), NOT a bug.
# A speed win that loses the optimum is not a win.  Report both or report neither.
#
# HONEST STATUS: a MEASUREMENT on whatever machine runs it — NOT a performance claim, NOT a
# regression gate, NOT part of CI, and NOT recovery evidence.  Recovery-to-truth for this
# estimator (a pre-declared known-truth gate + an external same-estimand comparator) is OWED
# separately; agreeing with `fit_ai_reml` is agreement with another estimator, not with truth.
#
# Usage:  julia --project=. sim/matrix_free_crossover_benchmark.jl [q1,q2,...] [out.tsv] [nprobe]

using HSquared
using LinearAlgebra, SparseArrays, Printf, Dates, Random

# High-fill pedigree: small founder base + RANDOM mating (each non-founder draws two distinct
# parents uniformly from ALL earlier individuals). The long-range parent edges make the
# elimination graph fill in heavily even after AMD reordering. Same generator as F0, so the fill
# figures are directly comparable to that benchmark's table.
function adversarial(q::Int; nfounder_frac::Float64 = 0.005, seed::Int = 20260724)
    rng = MersenneTwister(seed)
    nf = max(4, round(Int, nfounder_frac * q))
    ids = ["a$i" for i in 1:q]
    sire = fill("0", q)
    dam = fill("0", q)
    @inbounds for i in (nf + 1):q
        p = rand(rng, 1:(i - 1))
        m = rand(rng, 1:(i - 1))
        while m == p
            m = rand(rng, 1:(i - 1))
        end
        sire[i] = ids[p]
        dam[i] = ids[m]
    end
    return normalize_pedigree(ids, sire, dam)
end

# Gene-dropping (O(q)) down the topologically-sorted pedigree, so the fit has a genuine interior
# optimum rather than a no-signal boundary one. Same generator as F0.
function simulate_y(ped; sigma_a2 = 1.0, sigma_e2 = 1.0, mu = 5.0, seed = 20260724)
    rng = MersenneTwister(seed)
    q = length(ped.ids)
    u = zeros(q)
    @inbounds for i in 1:q
        s = ped.sire[i]; d = ped.dam[i]
        pa = s > 0 ? u[s] : 0.0
        pb = d > 0 ? u[d] : 0.0
        nknown = (s > 0) + (d > 0)
        msv = nknown == 0 ? 1.0 : (nknown == 1 ? 0.75 : 0.5)
        u[i] = 0.5 * (pa + pb) + sqrt(sigma_a2 * msv) * randn(rng)
    end
    return mu .+ u .+ sqrt(sigma_e2) .* randn(rng, q)
end

rss_mb() = Sys.maxrss() / 2^20

function bench(qt::Int; nfounder_frac = 0.005, nprobe = 64, seed = 20260728)
    GC.gc()
    ped = adversarial(qt; nfounder_frac = nfounder_frac)
    q = length(ped.ids)
    Ainv = pedigree_inverse(ped)
    y = simulate_y(ped); X = ones(q, 1); Z = sparse(1.0 * I, q, q)
    spec = animal_model_spec(y, X, Z, Ainv; method = :REML)

    # fill = nnz(L)/n of the (variance-independent) MME Cholesky — the SAME metric both :auto
    # thresholds use (likelihood.jl).
    lhs, _, _ = HSquared._sparse_mme_system(spec, 1.0, 1.0)
    chf = cholesky(Symmetric(lhs); check = true)
    fill = nnz(sparse(chf.L)) / q

    t_exact = @elapsed ex = fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    t_mf = @elapsed mf = fit_matrix_free_reml(spec; nprobe = nprobe, seed = seed)
    ev = ex.variance_components; mv = mf.variance_components

    return (; q, fill, t_exact, t_mf,
            ratio = t_exact / t_mf,
            rel_a = abs(mv.sigma_a2 - ev.sigma_a2) / ev.sigma_a2,
            rel_e = abs(mv.sigma_e2 - ev.sigma_e2) / ev.sigma_e2,
            sigma_a2_exact = ev.sigma_a2, sigma_e2_exact = ev.sigma_e2,
            sigma_a2_mf = mv.sigma_a2, sigma_e2_mf = mv.sigma_e2,
            conv_exact = ex.converged, conv_mf = mf.converged,
            iters_mf = mf.iterations, rss = rss_mb())
end

function main()
    qs = length(ARGS) >= 1 ? parse.(Int, split(ARGS[1], ",")) : [1_000, 2_000, 5_000, 10_000]
    out = length(ARGS) >= 2 ? ARGS[2] : "matrix_free_crossover.tsv"
    np = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 64
    println("# HSquared.jl F6 matrix-free crossover benchmark  ", Dates.now())
    println("# host=", gethostname(), "  julia=", VERSION,
            "  JULIA_NUM_THREADS=", Threads.nthreads(), "  nprobe=", np)
    println("# ", BLAS.get_config())
    println("# OPT-IN measurement; NO performance claim, NO CI gate, NOT recovery evidence.")
    println("# ratio > 1 means the matrix-free fitter is faster; rel_a/rel_e are Monte-Carlo error.")
    bench(400; nprobe = np)                      # JIT warm-up (discarded)
    rows = NamedTuple[]
    for q in qs
        @printf("# benchmarking high-fill q≈%d ...\n", q); flush(stdout)
        push!(rows, bench(q; nprobe = np))
    end
    @printf("\n%-9s %8s %10s %10s %8s %10s %10s %6s\n",
            "q", "fill", "exact_s", "matfree_s", "ratio", "rel_sa2", "rel_se2", "it_mf")
    for r in rows
        @printf("%-9d %8.1f %10.3f %10.3f %8.2f %10.2e %10.2e %6d\n",
                r.q, r.fill, r.t_exact, r.t_mf, r.ratio, r.rel_a, r.rel_e, r.iters_mf)
    end
    open(out, "w") do io
        println(io, "q\tfill_nnzL_over_n\texact_s\tmatfree_s\tratio\trel_sigma_a2\trel_sigma_e2\t" *
                    "sigma_a2_exact\tsigma_e2_exact\tsigma_a2_mf\tsigma_e2_mf\t" *
                    "conv_exact\tconv_mf\titers_mf\tnprobe\tpeakRSS_MB\thost\tjulia")
        for r in rows
            @printf(io, "%d\t%.3f\t%.4f\t%.4f\t%.4f\t%.6e\t%.6e\t%.6f\t%.6f\t%.6f\t%.6f\t%s\t%s\t%d\t%d\t%.1f\t%s\t%s\n",
                    r.q, r.fill, r.t_exact, r.t_mf, r.ratio, r.rel_a, r.rel_e,
                    r.sigma_a2_exact, r.sigma_e2_exact, r.sigma_a2_mf, r.sigma_e2_mf,
                    r.conv_exact, r.conv_mf, r.iters_mf, np, r.rss, gethostname(), VERSION)
        end
    end
    println("\n# wrote ", out)
end

main()
