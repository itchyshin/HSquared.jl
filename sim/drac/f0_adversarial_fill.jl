#!/usr/bin/env julia
# Wave F / Track A — F0 ADVERSARIAL high-fill measure-first benchmark.  OPT-IN, NOT CI.
#
# WHY this exists.  The 2026-06-23 F0 baseline (`f0_scale_benchmark.jl`) measured a BENIGN
# half-sib pedigree, whose MME barely fills in (nnz(L)/n small, ~AMD-optimal); there
# `fit_ai_reml` scales to q=300k in ~2.3 s with NO factorization wall.  That is exactly the
# structure where "no wall" is a foregone conclusion (Gauss/Rose Phase-2 plan review, 2026-07-24).
# The F6-or-not decision (do we WIRE the existing matrix-free PCG solve into the fit loop?) is
# only a real test on the OPPOSITE structure: a small-founder RANDOM-mating pedigree whose MME is
# HIGH-FILL-IN.  That is the one case that can wall the direct sparse Cholesky + selected-inverse
# path.  Honest measurement only: NO performance claim, NO regression gate, NOT part of CI.
#
# DECIDES F6-or-not:
#   * if fit_ai_reml still fits fast + CONVERGES at q>=1e5 under high fill  -> direct path
#     suffices, F6 stays DEFERRED;
#   * if it walls (t_fit / t_chol / peak RSS blow up super-linearly, or non-convergence traced
#     to the factorization) -> F6 (wire the existing PCG) is the lever.
#
# Fill is reported as nnz(L)/n of the (variance-independent) MME Cholesky — the SAME metric the
# `:auto` router uses (`_AUTO_EIGEN_FILL_THRESHOLD = 60`, likelihood.jl).  Note that at q>=1e5 the
# eigen-once rescue is unavailable (its dense O(n^3) path is capped at max_dense_n=20_000), so a
# high-fill pedigree at scale MUST go through sparse AI-REML — precisely the regime under test.
#
# Usage:  julia --project=. sim/drac/f0_adversarial_fill.jl [q1,q2,...] [out.tsv] [nfounder_frac]

using HSquared
using LinearAlgebra, SparseArrays, Printf, Dates, Random

# High-fill pedigree: a small founder base + RANDOM mating — each non-founder draws 2 distinct
# parents uniformly from ALL earlier individuals.  The long-range parent edges make the
# elimination graph fill in heavily even after CHOLMOD's AMD reordering (contrast the half-sib
# baseline, where parents are local).  O(q) to build, forms no dense A.
function adversarial(q::Int; nfounder_frac::Float64 = 0.005, seed::Int = 20260724)
    rng = MersenneTwister(seed)
    nf  = max(4, round(Int, nfounder_frac * q))
    ids  = ["a$i" for i in 1:q]
    sire = fill("0", q)
    dam  = fill("0", q)
    @inbounds for i in (nf + 1):q
        p = rand(rng, 1:(i - 1))
        m = rand(rng, 1:(i - 1))
        while m == p
            m = rand(rng, 1:(i - 1))
        end
        sire[i] = ids[p]
        dam[i]  = ids[m]
    end
    return normalize_pedigree(ids, sire, dam)
end

# Gene-dropping (O(q)) breeding values down the topologically-sorted pedigree so AI-REML has a
# genuine interior optimum (same signal generator as the half-sib baseline).
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

function bench(qt::Int; nfounder_frac = 0.005)
    GC.gc()
    ped = adversarial(qt; nfounder_frac = nfounder_frac)
    q   = length(ped.ids)
    t_ainv = @elapsed Ainv = pedigree_inverse(ped)
    nz  = nnz(Ainv)
    y = simulate_y(ped); X = ones(q, 1); Z = sparse(1.0 * I, q, q)
    spec = animal_model_spec(y, X, Z, Ainv; method = :REML)
    # fill = nnz(L)/n of the (variance-independent) MME Cholesky — identical to the :auto metric.
    lhs, _, _ = HSquared._sparse_mme_system(spec, 1.0, 1.0)
    t_chol = @elapsed chf = cholesky(Symmetric(lhs); check = true)
    fill = nnz(sparse(chf.L)) / q
    t_fit = @elapsed fit = fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    vc = fit.variance_components
    σa, σe = vc.sigma_a2, vc.sigma_e2
    t_pcg = @elapsed solve_animal_model_pcg(spec, σa, σe; preconditioner = :jacobi)
    t_pev = @elapsed prediction_error_variance(fit; method = :selinv)
    return (; q, nz, fill, t_ainv, t_chol, t_fit, t_pcg, t_pev, rss = rss_mb(),
            sigma_a2 = σa, sigma_e2 = σe, converged = fit.converged)
end

function main()
    qs  = length(ARGS) >= 1 ? parse.(Int, split(ARGS[1], ",")) : [2_000, 10_000, 30_000, 100_000]
    out = length(ARGS) >= 2 ? ARGS[2] : "f0_adversarial_fill.tsv"
    nff = length(ARGS) >= 3 ? parse(Float64, ARGS[3]) : 0.005
    println("# HSquared.jl Wave-F F0 ADVERSARIAL high-fill benchmark  ", Dates.now())
    println("# host=", gethostname(), "  julia=", VERSION,
            "  JULIA_NUM_THREADS=", Threads.nthreads(), "  nfounder_frac=", nff)
    println("# ", BLAS.get_config())
    println("# OPT-IN measurement; NO performance claim, NO CI gate. Random-mating HIGH-FILL pedigree.")
    bench(500; nfounder_frac = nff)   # global JIT warm-up (discarded)
    rows = NamedTuple[]
    for q in qs
        @printf("# benchmarking adversarial q≈%d ...\n", q); flush(stdout)
        push!(rows, bench(q; nfounder_frac = nff))
    end
    @printf("\n%-9s %12s %8s %9s %9s %9s %9s %11s %5s\n",
            "q", "nnz_Ainv", "fill", "ainv_s", "chol_s", "fit_s", "selinv_s", "peakRSS_MB", "conv")
    for r in rows
        @printf("%-9d %12d %8.1f %9.3f %9.3f %9.3f %9.3f %11.0f %5s\n",
                r.q, r.nz, r.fill, r.t_ainv, r.t_chol, r.t_fit, r.t_pev, r.rss, r.converged)
    end
    open(out, "w") do io
        println(io, "q\tnnz_Ainv\tfill_nnzL_over_n\tainv_s\tchol_s\tfit_s\tpcg_s\tselinvPEV_s\tpeakRSS_MB\tsigma_a2\tsigma_e2\tconverged\tnfounder_frac\thost\tjulia")
        for r in rows
            @printf(io, "%d\t%d\t%.3f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.1f\t%.6f\t%.6f\t%s\t%.4f\t%s\t%s\n",
                    r.q, r.nz, r.fill, r.t_ainv, r.t_chol, r.t_fit, r.t_pcg, r.t_pev, r.rss,
                    r.sigma_a2, r.sigma_e2, r.converged, nff, gethostname(), VERSION)
        end
    end
    println("\n# wrote ", out)
end

main()
