# Pre-declared PRODUCTION-SCALE realistic-design type-I calibration campaign for the
# conservative add-one genome-wide rule (`genome_wide_pvalue`). The validation-scale
# add-one gates (#203 single design, #204 3-point grid; all n≤500, m≤300, ≤20 seeds)
# established type-I control at small scale. This campaign tests the SAME one-sided-upper
# (not-anti-conservative) criterion at REALISTIC marker counts and sample sizes with many
# more seeds — doc-18's owed "realistic-LD/design calibration that controls genome-wide
# type-I error" item that currently holds the production genome-wide-significance claim.
#
# Parallel: Julia Distributed `pmap` over independent (design, seed) cells, capped at
# `NWORKERS` (≤ a shared-host core budget). Each worker pins BLAS to 1 thread.
#
# PRE-DECLARED (see docs/dev-log/recovery-checkpoints/
# 2026-06-30-v5-qtl-production-calibration-predeclaration.md, committed BEFORE this runs):
#   - DGP: same NULL marker DGP (`_simulate_markers`: LD via shared latent factors +
#     allele-freq gradient), intercept-only X, σ²e=1, nperm=2000, type1_reps=1000, α=0.05.
#   - DESIGN GRID (production scale): (n, m) ∈ {(500, 2000), (1000, 5000), (2000, 10000)}.
#   - SEEDS: 50 cold seeds per design, UNSEEN at declaration:
#       (500, 2000):  20261000..20261049
#       (1000, 5000): 20261050..20261099
#       (2000, 10000):20261100..20261149
#   - PASS (ALL design points required): for each design, all 50 cells complete AND
#     `mean(empirical_type1) − α ≤ 2·MCSE` (MCSE = sd(per-seed type-I)/√50). ONE-SIDED
#     UPPER (not anti-conservative), justified identically to #203/#204 (the add-one rule
#     is a valid exact permutation test controlling type-I at ≤ α by construction; the
#     gate tests only that it does NOT VIOLATE the level). Overall PASS iff ALL designs
#     pass. With 50 seeds the MCSE is tighter than the validation gates, so this is a
#     STRICTER test. Criterion fixed BEFORE the run; no post-hoc relaxation.
#   A FAIL at production scale would be a banked NEGATIVE (the slight finite-sample
#   conservatism/excess becomes detectable, or the permutation/fresh-phenotype nulls are
#   not exchangeable at scale); the V5 production claim would NOT proceed.
#
#   NWORKERS=96 OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase5_qtl_production_calibration.jl

using Distributed
using Statistics, Printf

const NWORKERS = parse(Int, get(ENV, "NWORKERS", "96"))
const REPO = normpath(joinpath(@__DIR__, ".."))

if nprocs() <= NWORKERS
    addprocs(NWORKERS - nprocs() + 1; exeflags = "--project=$(REPO)")
end

@everywhere begin
    using HSquared
    using Random, Statistics
    ENV["OPENBLAS_NUM_THREADS"] = "1"
    include(joinpath(@__DIR__, "phase5_threshold_calibration.jl"))  # _simulate_markers, _max_chisq_under_null

    # One (n, m, seed) add-one type-I cell — mirrors run_addone_calibration's RNG order.
    function production_cell(n, m, seed; nperm = 2000, alpha = 0.05, type1_reps = 1000)
        sigma_e2 = 1.0
        rng = MersenneTwister(seed)
        X = ones(n, 1)
        markers = _simulate_markers(rng, n, m)
        y = X * [2.0] .+ sqrt(sigma_e2) .* randn(rng, n)
        betaX = X \ y
        fitted = X * betaX
        resid = y .- fitted
        null_max = Vector{Float64}(undef, nperm)
        for i in 1:nperm
            yp = fitted .+ resid[randperm(rng, n)]
            sc = single_marker_scan(yp, X, markers; sigma_e2 = sigma_e2)
            null_max[i] = HSquared._scan_max_statistic(sc; statistic = :chisq)
        end
        reject = 0
        for _ in 1:type1_reps
            mc = _max_chisq_under_null(rng, n, m, X, sigma_e2, markers, :fixed)
            genome_wide_pvalue(mc, null_max) <= alpha && (reject += 1)
        end
        return (n = n, m = m, seed = seed, type1 = reject / type1_reps)
    end
end

const ALPHA = 0.05
const DESIGNS = (
    (n = 500,  m = 2000,  seeds = 20261000:20261049),
    (n = 1000, m = 5000,  seeds = 20261050:20261099),
    (n = 2000, m = 10000, seeds = 20261100:20261149),
)

function main()
    cells = [(d.n, d.m, s) for d in DESIGNS for s in d.seeds]
    @printf("Production calibration: %d cells over %d workers (α=%.3f)\n",
            length(cells), nworkers(), ALPHA)
    t0 = time()
    results = pmap(c -> production_cell(c[1], c[2], c[3]), cells)
    @printf("all cells done in %.1f min\n", (time() - t0) / 60)

    open(joinpath(@__DIR__, "..", "sim", "phase5_production_calibration.tsv"), "w") do io
        println(io, "n\tm\tseed\ttype1")
        for r in results
            @printf(io, "%d\t%d\t%d\t%.6f\n", r.n, r.m, r.seed, r.type1)
        end
    end

    all_pass = true
    for d in DESIGNS
        t1 = [r.type1 for r in results if r.n == d.n && r.m == d.m]
        nseed = length(t1)
        mt1 = mean(t1); mcse = std(t1) / sqrt(nseed); excess = mt1 - ALPHA
        pass = (nseed == length(d.seeds)) && (excess <= 2 * mcse)
        all_pass &= pass
        @printf("  (n=%4d, m=%5d) seeds=%d  mean type-I=%.4f  excess=%+.4f  2·MCSE=%.4f  range=[%.4f,%.4f]  %s\n",
                d.n, d.m, nseed, mt1, excess, 2 * mcse, minimum(t1), maximum(t1),
                pass ? "PASS" : "FAIL")
    end
    @printf("GATE: %s  (all %d production designs not-anti-conservative: %s)\n",
            all_pass ? "PASS" : "FAIL", length(DESIGNS), all_pass ? "true" : "false")
    return all_pass
end

if abspath(PROGRAM_FILE) == @__FILE__
    ok = main()
    exit(ok ? 0 : 1)
end
