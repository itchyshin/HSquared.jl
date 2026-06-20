using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in genome-wide significance threshold calibration harness (Phase 5, #48).

Deliberately outside `test/` so the package test suite stays RNG-free; the
deterministic threshold machinery it drives (`genome_wide_threshold_from_null`,
`genome_wide_pvalue`) is unit-tested in CI. This script does the RNG-heavy step:
it builds an empirical NULL distribution of per-scan maximum statistics by
PHENOTYPE PERMUTATION (residual permutation conditional on `X`, so the fixed
effects are preserved and only the phenotype-marker association is broken, while
the marker LD/correlation is held fixed), turns it into a genome-wide threshold,
contrasts that with the Bonferroni `alpha/m` threshold (the permutation threshold
should be LOWER when markers are correlated — fewer effective tests), and records
a loose type-I smoke (the fraction of independent no-signal scans whose maximum
exceeds the threshold should be approximately `alpha`).

This is validation-scale evidence-gathering, NOT a production
genome-wide-significance claim: a production claim needs a realistic LD/design
calibration and is the #48 gate that holds the R `gwas()` significance wording.

Run from the repository root (throttle threads on interactive machines):

    julia --project=. sim/phase5_threshold_calibration.jl
    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 nice -n 15 julia --project=. sim/phase5_threshold_calibration.jl

Optional arguments:

    --seed=N              base RNG seed (default 20260620)
    --n=N                 number of records (default 300)
    --markers=N           number of markers (default 200)
    --n-permutations=N    permutations for the null (default 1000)
    --alpha=X             genome-wide level (default 0.05)
    --type1-reps=N        independent no-signal datasets for the type-I smoke (default 500)
"""

function _argval(args, key, default)
    for a in args
        startswith(a, key * "=") && return split(a, "="; limit = 2)[2]
    end
    return default
end

# Correlated marker block: an allele-frequency gradient plus shared latent factors
# induces LD, so the per-scan maximum is not a set of independent tests.
function _simulate_markers(rng, n, m)
    freqs = range(0.1, 0.45; length = m)
    latent = randn(rng, n, max(1, m ÷ 20))               # shared structure -> LD
    M = Matrix{Float64}(undef, n, m)
    for j in 1:m
        base = latent[:, ((j - 1) % size(latent, 2)) + 1]
        p = freqs[j]
        # dosage in {0,1,2} biased by the latent factor and allele frequency
        liab = 0.6 .* base .+ randn(rng, n)
        thr1 = quantile_sorted(liab, (1 - p)^2)
        thr2 = quantile_sorted(liab, 1 - p^2)
        M[:, j] = [x <= thr1 ? 0.0 : (x <= thr2 ? 1.0 : 2.0) for x in liab]
    end
    return M
end

quantile_sorted(v, q) = sort(v)[clamp(round(Int, q * length(v)), 1, length(v))]

function _max_chisq_under_null(rng, n, X, markers, sigma_e2)
    y = X * [2.0] .+ sqrt(sigma_e2) .* randn(rng, n)      # no marker signal
    scan = single_marker_scan(y, X, markers; sigma_e2 = sigma_e2)
    return HSquared._scan_max_statistic(scan; statistic = :chisq)
end

function main(args)
    seed = parse(Int, _argval(args, "--seed", "20260620"))
    n = parse(Int, _argval(args, "--n", "300"))
    m = parse(Int, _argval(args, "--markers", "200"))
    nperm = parse(Int, _argval(args, "--n-permutations", "1000"))
    alpha = parse(Float64, _argval(args, "--alpha", "0.05"))
    type1_reps = parse(Int, _argval(args, "--type1-reps", "500"))
    sigma_e2 = 1.0

    rng = MersenneTwister(seed)
    X = ones(n, 1)
    markers = _simulate_markers(rng, n, m)
    # one observed phenotype (no marker signal here, so this is the calibration set)
    y = X * [2.0] .+ sqrt(sigma_e2) .* randn(rng, n)

    # residual permutation conditional on X
    betaX = X \ y
    fitted = X * betaX
    resid = y .- fitted
    null_max = Vector{Float64}(undef, nperm)
    for i in 1:nperm
        yp = fitted .+ resid[randperm(rng, n)]
        scan = single_marker_scan(yp, X, markers; sigma_e2 = sigma_e2)
        null_max[i] = HSquared._scan_max_statistic(scan; statistic = :chisq)
    end

    thr = genome_wide_threshold_from_null(null_max; alpha = alpha, statistic = :chisq)
    bonferroni_chisq = _bonferroni_chisq_threshold(alpha, m)

    # type-I smoke: independent no-signal datasets, fraction exceeding the threshold
    exceed = 0
    for _ in 1:type1_reps
        mc = _max_chisq_under_null(rng, n, X, markers, sigma_e2)
        mc >= thr.threshold && (exceed += 1)
    end
    empirical_type1 = exceed / type1_reps

    @printf("seed=%d n=%d markers=%d permutations=%d alpha=%.3f\n", seed, n, m, nperm, alpha)
    @printf("permutation genome-wide chi-square threshold: %.4f\n", thr.threshold)
    @printf("Bonferroni alpha/m chi-square threshold:      %.4f\n", bonferroni_chisq)
    @printf("  (permutation < Bonferroni expected under LD: %s)\n",
            thr.threshold < bonferroni_chisq ? "yes" : "no")
    @printf("empirical type-I (independent null scans):    %.4f (target ~ %.3f)\n",
            empirical_type1, alpha)
    println("NOTE: validation-scale smoke only — NOT a production genome-wide-significance claim.")
    return nothing
end

# Bonferroni chi-square (1 df) threshold at genome-wide alpha over m markers, via
# the package's dependency-light normal-quantile (two-sided): z_{1-alpha/(2m)}^2.
function _bonferroni_chisq_threshold(alpha, m)
    z = HSquared._standard_normal_quantile(1 - alpha / (2 * m))
    return z^2
end

main(ARGS)
