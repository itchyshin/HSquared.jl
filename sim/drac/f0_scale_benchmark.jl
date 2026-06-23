#!/usr/bin/env julia
# Wave F / Track A — F0 measure-first scale benchmark.  OPT-IN, NOT CI.
#
# Times the EXISTING sparse primitives at large q to LOCATE THE BOTTLENECK and
# confirm scaling BEFORE any hardening (F1 O(n) inbreeding / F2 fill-reducing
# ordering / F3 AI-REML hardening).  Honest measurement only: NO performance
# claim, NO regression gate, NOT part of the CI suite.
#
# Per size q (deterministic half-sib pedigree), one timed run after a global JIT
# warm-up, separately timing:
#   pedigree_inverse (Ainv build)  |  fit_ai_reml (full REML fit)  |
#   solve_animal_model_pcg (matrix-free)  |  prediction_error_variance(:selinv)
# and recording peak RSS (Sys.maxrss) + nnz(Ainv).  Writes a TSV for ingestion.
#
# Usage:  julia --project=. sim/drac/f0_scale_benchmark.jl [q1,q2,...] [out.tsv]

using HSquared
using LinearAlgebra, SparseArrays, Printf, Dates, Random

function halfsib(q::Int)
    nsire = max(2, round(Int, 0.04q))
    ndam  = max(2, round(Int, 0.08q))
    noff  = q - nsire - ndam
    sire_ids = ["s$i" for i in 1:nsire]
    dam_ids  = ["d$i" for i in 1:ndam]
    off_ids  = ["o$i" for i in 1:noff]
    ids  = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(fill("0", nsire + ndam), [sire_ids[((i - 1) % nsire) + 1] for i in 1:noff])
    dam  = vcat(fill("0", nsire + ndam), [dam_ids[((i - 1) % ndam) + 1]  for i in 1:noff])
    return normalize_pedigree(ids, sire, dam)
end

# Gene-dropping (O(q)) breeding values down the topologically-sorted pedigree:
# u_i = 0.5(u_sire + u_dam) + Mendelian sampling.  Gives a genuine additive-
# genetic signal so AI-REML converges to an interior optimum.  Scalable to 1e5+
# (NO dense A / Cholesky, unlike the recovery sims).
function simulate_y(ped; sigma_a2 = 1.0, sigma_e2 = 1.0, mu = 5.0, seed = 20260623)
    rng = MersenneTwister(seed)
    q = length(ped.ids)
    u = zeros(q)
    @inbounds for i in 1:q
        s = ped.sire[i]; d = ped.dam[i]
        pa = s > 0 ? u[s] : 0.0
        pb = d > 0 ? u[d] : 0.0
        nknown = (s > 0) + (d > 0)
        msv = nknown == 0 ? 1.0 : (nknown == 1 ? 0.75 : 0.5)   # Mendelian sampling var (no inbreeding adj)
        u[i] = 0.5 * (pa + pb) + sqrt(sigma_a2 * msv) * randn(rng)
    end
    return mu .+ u .+ sqrt(sigma_e2) .* randn(rng, q)
end

rss_mb() = Sys.maxrss() / 2^20

function bench(qt::Int)
    GC.gc()
    ped = halfsib(qt)
    q   = length(ped.ids)
    t_ainv = @elapsed Ainv = pedigree_inverse(ped)
    nz  = nnz(Ainv)
    y = simulate_y(ped); X = ones(q, 1); Z = sparse(1.0 * I, q, q)
    spec = animal_model_spec(y, X, Z, Ainv; method = :REML)
    t_fit = @elapsed fit = fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    vc = fit.variance_components
    σa, σe = vc.sigma_a2, vc.sigma_e2
    t_pcg = @elapsed solve_animal_model_pcg(spec, σa, σe; preconditioner = :jacobi)
    t_pev = @elapsed prediction_error_variance(fit; method = :selinv)
    return (; q, nz, t_ainv, t_fit, t_pcg, t_pev, rss = rss_mb(),
            sigma_a2 = σa, sigma_e2 = σe, converged = fit.converged)
end

function main()
    qs  = length(ARGS) >= 1 ? parse.(Int, split(ARGS[1], ",")) : [10_000, 30_000, 100_000]
    out = length(ARGS) >= 2 ? ARGS[2] : "f0_scale_benchmark.tsv"
    println("# HSquared.jl Wave-F F0 scale benchmark  ", Dates.now())
    println("# host=", gethostname(), "  julia=", VERSION,
            "  JULIA_NUM_THREADS=", Threads.nthreads())
    println("# ", BLAS.get_config())
    println("# OPT-IN measurement; NO performance claim, NO CI gate.")
    bench(500)   # global JIT warm-up (discarded)
    rows = NamedTuple[]
    for q in qs
        @printf("# benchmarking q≈%d ...\n", q); flush(stdout)
        push!(rows, bench(q))
    end
    @printf("\n%-9s %12s %10s %10s %10s %12s %11s %5s\n",
            "q", "nnz_Ainv", "ainv_s", "fit_s", "pcg_s", "selinvPEV_s", "peakRSS_MB", "conv")
    for r in rows
        @printf("%-9d %12d %10.3f %10.3f %10.3f %12.3f %11.0f %5s\n",
                r.q, r.nz, r.t_ainv, r.t_fit, r.t_pcg, r.t_pev, r.rss, r.converged)
    end
    open(out, "w") do io
        println(io, "q\tnnz_Ainv\tainv_s\tfit_s\tpcg_s\tselinvPEV_s\tpeakRSS_MB\tsigma_a2\tsigma_e2\tconverged\thost\tjulia")
        for r in rows
            @printf(io, "%d\t%d\t%.4f\t%.4f\t%.4f\t%.4f\t%.1f\t%.6f\t%.6f\t%s\t%s\t%s\n",
                    r.q, r.nz, r.t_ainv, r.t_fit, r.t_pcg, r.t_pev, r.rss,
                    r.sigma_a2, r.sigma_e2, r.converged, gethostname(), VERSION)
        end
    end
    println("\n# wrote ", out)
end

main()
