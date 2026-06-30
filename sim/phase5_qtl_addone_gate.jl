using HSquared
using Statistics
using Printf
using Random

# Pre-declared genome-wide threshold CALIBRATION gate for the CONSERVATIVE add-one
# permutation decision rule (`genome_wide_pvalue`) — the constructive follow-up to
# the #202 banked NEGATIVE (the `(1−α)` quantile threshold failed anti-conservative).
# This is the substitutable-gate candidate for a V5 "calibrated genome-wide
# threshold" covered LEG (the #48 gate that holds the R `gwas()` significance
# wording). Same DGP and design as `sim/phase5_qtl_threshold_gate.jl` — only the
# accept/reject decision changes (quantile threshold → add-one p-value), so for a
# given seed the null distribution and marker panel are byte-identical.
#
# PRE-DECLARED (see docs/dev-log/recovery-checkpoints/
# 2026-06-30-v5-qtl-addone-gate-predeclaration.md, committed BEFORE this runs):
#   - DGP: NULL (no marker signal). n=300 records, m=200 correlated markers (LD via
#     shared latent factors + allele-freq gradient — `_simulate_markers`), intercept-only
#     X, σ²e=1. Per seed: an LD-aware residual-permutation null (nperm=2000) → the null
#     distribution of per-scan-MAX chi-square; then type1_reps=1000 INDEPENDENT no-signal
#     scans on the SAME panel each get an add-one genome-wide p-value
#     `genome_wide_pvalue(max, null) = (1 + #{null ≥ max})/(nperm + 1)`; reject if p ≤ α.
#     Empirical type-I = fraction rejected.
#   - α = 0.05. Seeds 20260920..20260939 (20 cold-start; UNSEEN at declaration).
#   - PASS (ALL): 20/20 runs complete AND `mean(empirical_type1) − α ≤ 2·MCSE`, where
#     MCSE = sd(per-seed empirical_type1)/√20. ONE-SIDED UPPER (not anti-conservative):
#     the add-one rule is CONSERVATIVE by construction (a valid exact permutation test
#     controlling type-I at ≤ α), so being at or BELOW α is the designed behaviour — the
#     gate tests only that it does NOT VIOLATE the level. This is deliberately the
#     complement of the #202 two-sided gate, justified by the construction, not relaxed
#     post-hoc.
#   Read as: NO DETECTABLE type-I inflation of the add-one rule at α (a low-power
#   non-rejection), never "exactly calibrated". NO post-hoc relaxation. A FAIL (mean
#   type-I > α beyond 2·MCSE) would be a banked NEGATIVE and a genuine surprise (it
#   would mean the permutation null and the fresh-phenotype null are not exchangeable
#   on this design); the V5 covered claim would NOT proceed and the R `gwas()` wording
#   stays held.
#
#   env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase5_qtl_addone_gate.jl

include("phase5_threshold_calibration.jl")   # _simulate_markers, _max_chisq_under_null (no auto-main when included)

const ALPHA = 0.05
const SEEDS = 20260920:20260939
const N, M, NPERM, T1REPS = 300, 200, 2000, 1000

# Mirrors `run_threshold_calibration` RNG order exactly, but the type-I decision uses
# the add-one `genome_wide_pvalue` rather than the (1−α) quantile threshold.
function run_addone_calibration(seed::Integer; n::Integer = N, m::Integer = M,
                                nperm::Integer = NPERM, alpha::Real = ALPHA,
                                type1_reps::Integer = T1REPS)
    n > 2 || throw(ArgumentError("n must be > 2"))
    m > 0 || throw(ArgumentError("markers must be positive"))
    nperm > 0 || throw(ArgumentError("n-permutations must be positive"))
    type1_reps > 0 || throw(ArgumentError("type1-reps must be positive"))
    0 < alpha < 1 || throw(ArgumentError("alpha must be in (0, 1)"))
    sigma_e2 = 1.0

    rng = MersenneTwister(seed)
    X = ones(n, 1)
    markers = _simulate_markers(rng, n, m)
    y = X * [2.0] .+ sqrt(sigma_e2) .* randn(rng, n)

    # residual permutation conditional on X (intercept-only ⇒ permuting y)
    betaX = X \ y
    fitted = X * betaX
    resid = y .- fitted
    null_max = Vector{Float64}(undef, nperm)
    for i in 1:nperm
        yp = fitted .+ resid[randperm(rng, n)]
        scan = single_marker_scan(yp, X, markers; sigma_e2 = sigma_e2)
        null_max[i] = HSquared._scan_max_statistic(scan; statistic = :chisq)
    end

    # type-I via the CONSERVATIVE add-one decision rule
    reject = 0
    for _ in 1:type1_reps
        mc = _max_chisq_under_null(rng, n, m, X, sigma_e2, markers, :fixed)
        genome_wide_pvalue(mc, null_max) <= alpha && (reject += 1)
    end
    empirical_type1 = reject / type1_reps

    return (seed = Int(seed), n = Int(n), markers = Int(m), permutations = Int(nperm),
            alpha = Float64(alpha), type1_reps = Int(type1_reps),
            reject = reject, empirical_type1 = empirical_type1)
end

function main_gate()
    results = [run_addone_calibration(s) for s in SEEDS]
    t1 = [r.empirical_type1 for r in results]
    nseed = length(t1)
    mt1 = mean(t1)
    mcse = std(t1) / sqrt(nseed)
    excess = mt1 - ALPHA
    completed = nseed == length(SEEDS)
    # ONE-SIDED UPPER: not anti-conservative beyond noise.
    not_inflated = excess <= 2 * mcse
    pass = completed && not_inflated

    @printf("Add-one genome-wide threshold calibration gate — %d seeds (%d..%d), runs=%d/%d\n",
            nseed, first(SEEDS), last(SEEDS), nseed, length(SEEDS))
    @printf("  DGP: NULL, n=%d, m=%d (LD), nperm=%d, type1_reps=%d, α=%.3f\n",
            N, M, NPERM, T1REPS, ALPHA)
    @printf("  mean empirical type-I = %.4f  (target α = %.3f)\n", mt1, ALPHA)
    @printf("  excess = mean − α      = %+.4f\n", excess)
    @printf("  MCSE                   = %.4f  (2·MCSE = %.4f)\n", mcse, 2 * mcse)
    @printf("  per-seed type-I range  = [%.4f, %.4f]\n", minimum(t1), maximum(t1))
    @printf("GATE: %s  (one-sided upper: not anti-conservative; mean−α=%+.4f ≤ 2·MCSE=%.4f → %s)\n",
            pass ? "PASS" : "FAIL", excess, 2 * mcse, not_inflated ? "true" : "false")
    return pass
end

if abspath(PROGRAM_FILE) == @__FILE__
    ok = main_gate()
    exit(ok ? 0 : 1)
end
