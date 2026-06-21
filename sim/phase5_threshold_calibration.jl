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
contrasts that with the Bonferroni `alpha/m` threshold (an LD-aware permutation
threshold can be less conservative, but finite validation runs need not be below
Bonferroni), and records a loose type-I smoke (the fraction of independent
no-signal phenotype scans on the SAME fixed marker panel whose maximum exceeds
the threshold should be approximately `alpha`).

Honest caveats on the null scheme (review #48, Curie/Fisher):

- The committed default runs intercept-only `X = ones(n, 1)`, where residual
  permutation is numerically identical to permuting `y` directly (the conditioning
  on `X` is then a no-op). The "conditional on `X`" framing matters only for a
  non-trivial fixed-effect design.
- For a non-trivial `X`, the naive "permute residuals, add `Xβ̂` back" scheme is
  only APPROXIMATELY exchangeable; the exact permutation nulls are Freedman–Lane /
  ter Braak. Those are the upgrade path for covariate-adjusted GWAS and are not
  implemented here.
- The default type-I smoke keeps the marker panel FIXED across null phenotype
  replicates, matching the usual "this observed marker set" genome-wide
  calibration question. A `--type1-marker-mode=fresh` sensitivity mode draws a
  fresh correlated marker panel per replicate, but that is a panel-to-panel
  robustness smoke rather than the main calibration target.

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
    --type1-marker-mode=fixed|fresh
                          marker panel used by the type-I smoke (default fixed)
    --seeds=1,2,3         comma-separated seeds; overrides --seed
    --out=PATH            optional TSV output path for machine-readable evidence
"""

function _argval(args, key, default)
    for a in args
        startswith(a, key * "=") && return split(a, "="; limit = 2)[2]
    end
    return default
end

function _parse_seed_list(value)
    parts = strip.(split(value, ","))
    (isempty(parts) || any(isempty, parts)) &&
        throw(ArgumentError("--seeds must be a comma-separated list of integer seeds"))
    return [parse(Int, p) for p in parts]
end

function _checked_type1_marker_mode(value)
    mode = Symbol(lowercase(strip(String(value))))
    mode in (:fixed, :fresh) ||
        throw(ArgumentError("--type1-marker-mode must be fixed or fresh"))
    return mode
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

function _max_chisq_under_null(rng, n, m, X, sigma_e2, base_markers, marker_mode::Symbol)
    markers = marker_mode === :fixed ? base_markers : _simulate_markers(rng, n, m)
    y = X * [2.0] .+ sqrt(sigma_e2) .* randn(rng, n)     # no marker signal
    scan = single_marker_scan(y, X, markers; sigma_e2 = sigma_e2)
    return HSquared._scan_max_statistic(scan; statistic = :chisq)
end

function run_threshold_calibration(seed::Integer; n::Integer = 300, m::Integer = 200,
                                   nperm::Integer = 1000, alpha::Real = 0.05,
                                   type1_reps::Integer = 500,
                                   type1_marker_mode::Symbol = :fixed)
    n > 2 || throw(ArgumentError("n must be > 2"))
    m > 0 || throw(ArgumentError("markers must be positive"))
    nperm > 0 || throw(ArgumentError("n-permutations must be positive"))
    type1_reps > 0 || throw(ArgumentError("type1-reps must be positive"))
    0 < alpha < 1 || throw(ArgumentError("alpha must be in (0, 1)"))
    type1_marker_mode in (:fixed, :fresh) ||
        throw(ArgumentError("type1_marker_mode must be :fixed or :fresh"))
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
        mc = _max_chisq_under_null(rng, n, m, X, sigma_e2, markers, type1_marker_mode)
        mc >= thr.threshold && (exceed += 1)
    end
    empirical_type1 = exceed / type1_reps

    return (
        seed = Int(seed),
        n = Int(n),
        markers = Int(m),
        permutations = Int(nperm),
        alpha = Float64(alpha),
        type1_reps = Int(type1_reps),
        type1_marker_mode = type1_marker_mode,
        threshold = thr.threshold,
        bonferroni_chisq = bonferroni_chisq,
        threshold_less_than_bonferroni = thr.threshold < bonferroni_chisq,
        exceed = exceed,
        empirical_type1 = empirical_type1,
    )
end

function _threshold_calibration_tsv_header()
    return join((
        "seed", "n", "markers", "permutations", "alpha", "type1_reps",
        "type1_marker_mode", "threshold", "bonferroni_chisq",
        "threshold_less_than_bonferroni", "exceed", "empirical_type1",
    ), '\t')
end

function _threshold_calibration_tsv_row(result)
    return join((
        result.seed,
        result.n,
        result.markers,
        result.permutations,
        @sprintf("%.6g", result.alpha),
        result.type1_reps,
        String(result.type1_marker_mode),
        @sprintf("%.10g", result.threshold),
        @sprintf("%.10g", result.bonferroni_chisq),
        result.threshold_less_than_bonferroni,
        result.exceed,
        @sprintf("%.10g", result.empirical_type1),
    ), '\t')
end

function _write_threshold_calibration_tsv(path, results)
    isempty(results) && throw(ArgumentError("results must be non-empty"))
    dir = dirname(path)
    (!isempty(dir) && dir != ".") && mkpath(dir)
    open(path, "w") do io
        println(io, _threshold_calibration_tsv_header())
        for result in results
            println(io, _threshold_calibration_tsv_row(result))
        end
    end
    return path
end

function _summarize_threshold_calibration_results(results)
    isempty(results) && throw(ArgumentError("results must be non-empty"))
    empirical = [r.empirical_type1 for r in results]
    thresholds = [r.threshold for r in results]
    alpha = first(results).alpha
    return (
        n_seeds = length(results),
        alpha = alpha,
        mean_threshold = sum(thresholds) / length(thresholds),
        mean_empirical_type1 = sum(empirical) / length(empirical),
        min_empirical_type1 = minimum(empirical),
        max_empirical_type1 = maximum(empirical),
        max_abs_type1_error = maximum(abs.(empirical .- alpha)),
        all_thresholds_below_bonferroni = all(r.threshold_less_than_bonferroni for r in results),
    )
end

function _print_threshold_calibration_result(result)
    @printf("seed=%d n=%d markers=%d permutations=%d alpha=%.3f type1_reps=%d mode=%s\n",
            result.seed, result.n, result.markers, result.permutations,
            result.alpha, result.type1_reps, String(result.type1_marker_mode))
    @printf("permutation genome-wide chi-square threshold: %.4f\n", result.threshold)
    @printf("Bonferroni alpha/m chi-square threshold:      %.4f\n", result.bonferroni_chisq)
    @printf("  (permutation < Bonferroni in this finite run: %s)\n",
            result.threshold_less_than_bonferroni ? "yes" : "no")
    @printf("empirical type-I (independent null scans):    %.4f (target ~ %.3f)\n",
            result.empirical_type1, result.alpha)
end

function main(args)
    seed = parse(Int, _argval(args, "--seed", "20260620"))
    seed_arg = _argval(args, "--seeds", "")
    seeds = isempty(seed_arg) ? [seed] : _parse_seed_list(seed_arg)
    n = parse(Int, _argval(args, "--n", "300"))
    m = parse(Int, _argval(args, "--markers", "200"))
    nperm = parse(Int, _argval(args, "--n-permutations", "1000"))
    alpha = parse(Float64, _argval(args, "--alpha", "0.05"))
    type1_reps = parse(Int, _argval(args, "--type1-reps", "500"))
    type1_marker_mode = _checked_type1_marker_mode(_argval(args, "--type1-marker-mode", "fixed"))
    out = _argval(args, "--out", "")

    results = [
        run_threshold_calibration(seed; n = n, m = m, nperm = nperm, alpha = alpha,
                                  type1_reps = type1_reps,
                                  type1_marker_mode = type1_marker_mode)
        for seed in seeds
    ]

    for (i, result) in enumerate(results)
        i > 1 && println()
        _print_threshold_calibration_result(result)
    end
    if length(results) > 1
        summary = _summarize_threshold_calibration_results(results)
        println()
        @printf("summary: seeds=%d mean_type-I=%.4f range=[%.4f, %.4f] max_abs_error=%.4f all_perm_lt_bonf=%s\n",
                summary.n_seeds, summary.mean_empirical_type1,
                summary.min_empirical_type1, summary.max_empirical_type1,
                summary.max_abs_type1_error,
                summary.all_thresholds_below_bonferroni ? "yes" : "no")
    end
    if !isempty(out)
        _write_threshold_calibration_tsv(out, results)
        println("wrote TSV: ", out)
    end
    println("NOTE: validation-scale smoke only — NOT a production genome-wide-significance claim.")
    return nothing
end

# Bonferroni chi-square (1 df) threshold at genome-wide alpha over m markers, via
# the package's dependency-light normal-quantile (two-sided): z_{1-alpha/(2m)}^2.
function _bonferroni_chisq_threshold(alpha, m)
    z = HSquared._standard_normal_quantile(1 - alpha / (2 * m))
    return z^2
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
