module RepeatabilityRatioBiasAnalysis

using Printf
using SHA
using Statistics

# Deterministic, post-hoc analysis of already-banked recovery TSVs.
# This script performs no fitting, simulation, resampling, or RNG call.

const Z975 = 1.959963984540054
const RR_EXPECTED_COLUMNS = [
    "cell", "seed", "scope", "nsire", "ndam", "noffspring", "records", "mu",
    "animals", "observations", "converged", "sigma_a2", "sigma_pe2", "sigma_e2",
    "t", "h2", "sigma_a2_true", "sigma_pe2_true", "sigma_e2_true", "t_true", "h2_true",
]
const SUPPLIED_EXPECTED_COLUMNS = [
    "cell", "kind", "scope", "seed", "q", "records", "n", "mu", "sk_true", "se_true",
    "h2_true", "cond_k", "converged", "iterations", "loglik", "sk_hat", "se_hat",
    "h2_hat", "factors", "ridge", "kseed",
]

_arg(args, key, default = nothing) = begin
    prefix = "--$key="
    for arg in args
        startswith(arg, prefix) && return String(split(arg, "="; limit = 2)[2])
    end
    default
end

function _read_tsv(path)
    lines = readlines(path)
    isempty(lines) && error("empty TSV: $path")
    header = split(chomp(lines[1]), '\t')
    length(unique(header)) == length(header) || error("duplicate TSV columns: $path")
    rows = [split(chomp(line), '\t') for line in lines[2:end] if !isempty(strip(line))]
    all(length(row) == length(header) for row in rows) || error("ragged TSV rows: $path")
    return header, rows
end

_index(header, name) = begin
    idx = findfirst(==(name), header)
    idx === nothing && error("required column '$name' is missing")
    idx
end

function _assert_exact_schema(header, expected, label)
    header == expected || error("$label TSV schema/order mismatch")
    nothing
end

_strings(header, rows, name) = [String(row[_index(header, name)]) for row in rows]
_ints(header, rows, name) = parse.(Int, _strings(header, rows, name))
_floats(header, rows, name) = parse.(Float64, _strings(header, rows, name))
_bools(header, rows, name) = [lowercase(x) in ("true", "1") ? true :
                              lowercase(x) in ("false", "0") ? false :
                              error("invalid Bool '$x' in column '$name'")
                              for x in _strings(header, rows, name)]

function _constant(xs, name; atol = 0.0)
    isempty(xs) && error("empty column '$name'")
    x0 = first(xs)
    if x0 isa Number
        all(isapprox(x, x0; atol = atol, rtol = 0.0) for x in xs) ||
            error("configuration/truth drift in '$name'")
    else
        all(==(x0), xs) || error("configuration drift in '$name'")
    end
    x0
end

function _check_hash(path, expected)
    observed = bytes2hex(sha256(read(path)))
    expected === nothing || lowercase(observed) == lowercase(expected) ||
        error("SHA-256 mismatch for $path: expected=$expected observed=$observed")
    observed
end

_ratio(s, e) = s / (s + e)

function _gradient(s, e)
    d = s + e
    (e / d^2, -s / d^2)
end

function _hessian(s, e)
    d3 = (s + e)^3
    (-2e / d3, (s - e) / d3, 2s / d3) # Hss, Hse, Hee
end

function _var_m(xs, xbar)
    sum((x - xbar)^2 for x in xs) / length(xs)
end

function _cov_m(xs, ys, xbar, ybar)
    sum((x - xbar) * (y - ybar) for (x, y) in zip(xs, ys)) / length(xs)
end

function _mcse(influence)
    m = length(influence)
    m > 1 || error("at least two complete rows are required")
    sqrt(sum((x - mean(influence))^2 for x in influence) / (m - 1) / m)
end

function _cov_est(influence1, influence2)
    m = length(influence1)
    xbar, ybar = mean(influence1), mean(influence2)
    sum((x - xbar) * (y - ybar) for (x, y) in zip(influence1, influence2)) /
        (m - 1) / m
end

function _summarize(label, numerator, residual, stored_ratio, truth_numerator, truth_residual;
                    part1 = nothing, part2 = nothing)
    m = length(numerator)
    m == length(residual) == length(stored_ratio) || error("analysis columns differ in length")
    m > 2 || error("at least three converged rows are required")
    all(isfinite, numerator) && all(isfinite, residual) && all(isfinite, stored_ratio) ||
        error("non-finite complete-case analysis value in $label")
    all((numerator .+ residual) .> 0) || error("nonpositive total variance in $label")

    computed = _ratio.(numerator, residual)
    max_ratio_diff = maximum(abs.(computed .- stored_ratio))
    # Source drivers serialize components and ratios independently with %.10g, so a
    # reconstruction discrepancy of order 1e-8 is expected from decimal roundoff.
    max_ratio_diff <= 2e-8 || error("stored ratio does not reconstruct from components in $label: $max_ratio_diff")

    sbar, ebar = mean(numerator), mean(residual)
    truth_ratio = _ratio(truth_numerator, truth_residual)
    mean_ratio = mean(computed)
    total_bias = mean_ratio - truth_ratio
    ratio_of_means = _ratio(sbar, ebar)
    mean_shift = ratio_of_means - truth_ratio
    nonlinear = mean_ratio - ratio_of_means
    closure_error = total_bias - mean_shift - nonlinear
    abs(closure_error) <= 5e-15 || error("exact decomposition did not close in $label")

    var_s = _var_m(numerator, sbar)
    var_e = _var_m(residual, ebar)
    cov_se = _cov_m(numerator, residual, sbar, ebar)
    d3 = (sbar + ebar)^3
    curvature_s = -ebar * var_s / d3
    curvature_cov = (sbar - ebar) * cov_se / d3
    curvature_e = sbar * var_e / d3
    delta2 = curvature_s + curvature_cov + curvature_e
    delta2_remainder = nonlinear - delta2

    gs, ge = _gradient(sbar, ebar)
    if_total = computed .- mean_ratio
    if_mean = [gs * (s - sbar) + ge * (e - ebar) for (s, e) in zip(numerator, residual)]
    if_nonlinear = if_total .- if_mean
    maximum(abs.(if_total .- if_mean .- if_nonlinear)) <= 1e-15 ||
        error("influence decomposition did not close in $label")

    total_mcse = _mcse(if_total)
    mean_shift_mcse = _mcse(if_mean)
    nonlinear_mcse = _mcse(if_nonlinear)
    contribution_covariance = _cov_est(if_mean, if_nonlinear)
    contribution_correlation = contribution_covariance /
        max(mean_shift_mcse * nonlinear_mcse, eps(Float64))

    var_part1 = NaN
    var_part2 = NaN
    twice_cov_parts = NaN
    var_identity_error = NaN
    if part1 !== nothing || part2 !== nothing
        part1 !== nothing && part2 !== nothing || error("both numerator parts are required")
        length(part1) == m == length(part2) || error("numerator parts differ in length")
        maximum(abs.(part1 .+ part2 .- numerator)) <= 1e-12 ||
            error("numerator parts do not reconstruct in $label")
        p1bar, p2bar = mean(part1), mean(part2)
        var_part1 = _var_m(part1, p1bar)
        var_part2 = _var_m(part2, p2bar)
        twice_cov_parts = 2 * _cov_m(part1, part2, p1bar, p2bar)
        var_identity_error = var_s - var_part1 - var_part2 - twice_cov_parts
        abs(var_identity_error) <= 1e-10 || error("numerator variance identity failed in $label")
    end

    ci(est, se) = (est - Z975 * se, est + Z975 * se)
    total_ci = ci(total_bias, total_mcse)
    mean_ci = ci(mean_shift, mean_shift_mcse)
    nonlinear_ci = ci(nonlinear, nonlinear_mcse)
    ratio_bias_pass = abs(total_bias) <= 2 * total_mcse

    return (; label, m, truth_numerator, truth_residual, truth_ratio, mean_numerator = sbar,
        mean_residual = ebar, mean_ratio, total_bias, total_mcse,
        total_ci_lo = total_ci[1], total_ci_hi = total_ci[2], ratio_bias_pass,
        ratio_of_means, mean_shift, mean_shift_mcse, mean_shift_ci_lo = mean_ci[1],
        mean_shift_ci_hi = mean_ci[2], nonlinear, nonlinear_mcse,
        nonlinear_ci_lo = nonlinear_ci[1], nonlinear_ci_hi = nonlinear_ci[2],
        contribution_covariance, contribution_correlation, var_numerator = var_s,
        var_residual = var_e, cov_numerator_residual = cov_se, curvature_numerator = curvature_s,
        curvature_covariance = curvature_cov, curvature_residual = curvature_e,
        delta2_nonlinear = delta2, delta2_remainder,
        mean_shift_share = mean_shift / total_bias, nonlinear_share = nonlinear / total_bias,
        max_ratio_diff, closure_error, var_part1, var_part2, twice_cov_parts,
        var_identity_error)
end

function _load_repeatability(path, expected_sha)
    sha = _check_hash(path, expected_sha)
    header, rows = _read_tsv(path)
    _assert_exact_schema(header, RR_EXPECTED_COLUMNS, "repeatability")
    length(rows) == 2000 || error("repeatability TSV must contain exactly 2,000 rows")
    seeds = _ints(header, rows, "seed")
    length(unique(seeds)) == 2000 || error("repeatability seeds are not unique")
    sort(seeds) == collect(20280000:20281999) || error("unexpected repeatability seed block")
    _constant(_strings(header, rows, "cell"), "cell") == "wellpowered" || error("wrong cell")
    _constant(_strings(header, rows, "scope"), "scope") == "interior" || error("wrong scope")
    _constant(_ints(header, rows, "nsire"), "nsire") == 20 || error("wrong nsire")
    _constant(_ints(header, rows, "ndam"), "ndam") == 40 || error("wrong ndam")
    _constant(_ints(header, rows, "noffspring"), "noffspring") == 800 || error("wrong noffspring")
    _constant(_ints(header, rows, "records"), "records") == 4 || error("wrong records")

    converged = _bools(header, rows, "converged")
    count(converged) == 1999 || error("repeatability convergence must be 1,999/2,000")
    excluded_seeds = seeds[.!converged]
    length(excluded_seeds) == 1 || error("expected exactly one excluded seed")

    a = _floats(header, rows, "sigma_a2")[converged]
    pe = _floats(header, rows, "sigma_pe2")[converged]
    e = _floats(header, rows, "sigma_e2")[converged]
    stored = _floats(header, rows, "t")[converged]
    a0 = _constant(_floats(header, rows, "sigma_a2_true"), "sigma_a2_true"; atol = 1e-12)
    pe0 = _constant(_floats(header, rows, "sigma_pe2_true"), "sigma_pe2_true"; atol = 1e-12)
    e0 = _constant(_floats(header, rows, "sigma_e2_true"), "sigma_e2_true"; atol = 1e-12)
    stored_truth = _constant(_floats(header, rows, "t_true"), "t_true"; atol = 1e-12)
    abs(stored_truth - _ratio(a0 + pe0, e0)) <= 5e-10 || error("repeatability truth mismatch")
    summary = _summarize("repeatability", a .+ pe, e, stored, a0 + pe0, e0;
                         part1 = a, part2 = pe)
    !summary.ratio_bias_pass || error("banked repeatability ratio-bias criterion unexpectedly passed")
    abs(summary.total_bias - (-0.00120)) <= 1e-5 || error("repeatability bias not reproduced")
    abs(summary.total_mcse - 0.00057) <= 1e-5 || error("repeatability MCSE not reproduced")
    return summary, sha, excluded_seeds
end

function _load_supplied(path, label, expected_sha)
    sha = _check_hash(path, expected_sha)
    header, rows = _read_tsv(path)
    _assert_exact_schema(header, SUPPLIED_EXPECTED_COLUMNS, label)
    length(rows) == 2000 || error("$label TSV must contain exactly 2,000 rows")
    seeds = _ints(header, rows, "seed")
    length(unique(seeds)) == 2000 || error("$label seeds are not unique")
    sort(seeds) == collect(20266000:20267999) || error("unexpected $label seed block")
    _constant(_strings(header, rows, "cell"), "cell") == label || error("wrong supplied-K cell")
    converged = _bools(header, rows, "converged")
    all(converged) || error("$label must have 2,000/2,000 convergence")
    sk = _floats(header, rows, "sk_hat")
    se = _floats(header, rows, "se_hat")
    stored = _floats(header, rows, "h2_hat")
    sk0 = _constant(_floats(header, rows, "sk_true"), "sk_true"; atol = 1e-12)
    se0 = _constant(_floats(header, rows, "se_true"), "se_true"; atol = 1e-12)
    stored_truth = _constant(_floats(header, rows, "h2_true"), "h2_true"; atol = 1e-12)
    abs(stored_truth - _ratio(sk0, se0)) <= 5e-10 || error("$label truth mismatch")
    return _summarize(label, sk, se, stored, sk0, se0), sha
end

const OUTPUT_COLUMNS = [
    :label, :m, :truth_numerator, :truth_residual, :truth_ratio, :mean_numerator,
    :mean_residual, :mean_ratio, :total_bias, :total_mcse, :total_ci_lo, :total_ci_hi,
    :ratio_bias_pass, :ratio_of_means, :mean_shift, :mean_shift_mcse, :mean_shift_ci_lo,
    :mean_shift_ci_hi, :nonlinear, :nonlinear_mcse, :nonlinear_ci_lo, :nonlinear_ci_hi,
    :contribution_covariance, :contribution_correlation, :var_numerator, :var_residual,
    :cov_numerator_residual, :curvature_numerator, :curvature_covariance,
    :curvature_residual, :delta2_nonlinear, :delta2_remainder, :mean_shift_share,
    :nonlinear_share, :max_ratio_diff, :closure_error, :var_part1, :var_part2,
    :twice_cov_parts, :var_identity_error,
]

function _format_value(x)
    x isa Bool && return lowercase(string(x))
    x isa Integer && return string(x)
    x isa AbstractFloat && return @sprintf("%.12g", x)
    string(x)
end

function _write_output(path, summaries)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, join(string.(OUTPUT_COLUMNS), '\t'))
        for summary in summaries
            println(io, join((_format_value(getproperty(summary, col)) for col in OUTPUT_COLUMNS), '\t'))
        end
    end
end

function _self_test()
    _assert_exact_schema(copy(RR_EXPECTED_COLUMNS), RR_EXPECTED_COLUMNS, "self-test")
    schema_failed = false
    try
        _assert_exact_schema(reverse(RR_EXPECTED_COLUMNS), RR_EXPECTED_COLUMNS, "mutated")
    catch err
        occursin("schema/order mismatch", sprint(showerror, err)) || rethrow()
        schema_failed = true
    end
    schema_failed || error("mutated schema/order mismatch did not fail")

    constant = _summarize("constant", fill(1.6, 4), fill(1.5, 4),
                          fill(_ratio(1.6, 1.5), 4), 1.6, 1.5)
    abs(constant.nonlinear) <= 1e-15 || error("constant-case nonlinear gap is nonzero")
    abs(constant.delta2_nonlinear) <= 1e-15 || error("constant-case curvature is nonzero")

    s = [0.8, 1.6, 3.2, 4.8]
    e = [0.75, 1.5, 3.0, 4.5]
    proportional = _summarize("proportional", s, e, _ratio.(s, e), 1.6, 1.5)
    abs(proportional.nonlinear) <= 1e-15 || error("proportional-scaling nonlinear gap is nonzero")
    mismatch_failed = false
    try
        _summarize("mutated_ratio", s, e, _ratio.(s, e) .+ 1e-6, 1.6, 1.5)
    catch err
        occursin("stored ratio does not reconstruct", sprint(showerror, err)) || rethrow()
        mismatch_failed = true
    end
    mismatch_failed || error("mutated stored-ratio mismatch did not fail")

    s2 = [1.0, 2.0, 4.0, 7.0]
    e2 = [1.0, 2.0, 8.0, 3.0]
    original = _summarize("original", s2, e2, _ratio.(s2, e2), 2.0, 2.0)
    permuted_e = e2[[3, 2, 4, 1]]
    permuted = _summarize("permuted", s2, permuted_e, _ratio.(s2, permuted_e), 2.0, 2.0)
    mean(e2) == mean(permuted_e) || error("permutation changed component means")
    abs(original.nonlinear - permuted.nonlinear) > 1e-3 ||
        error("paired permutation did not expose covariance sensitivity")
    reversed = _summarize("reversed", reverse(s2), reverse(e2), reverse(_ratio.(s2, e2)), 2.0, 2.0)
    abs(original.total_bias - reversed.total_bias) <= 1e-15 || error("row-order dependence")
    abs(original.nonlinear - reversed.nonlinear) <= 1e-15 || error("row-order dependence")

    s0, e0, h = 1.6, 1.5, 1e-4
    hss, hse, hee = _hessian(s0, e0)
    f0 = _ratio(s0, e0)
    hss_fd = (_ratio(s0 + h, e0) - 2 * f0 + _ratio(s0 - h, e0)) / h^2
    hee_fd = (_ratio(s0, e0 + h) - 2 * f0 + _ratio(s0, e0 - h)) / h^2
    hse_fd = (_ratio(s0 + h, e0 + h) - _ratio(s0 + h, e0 - h) -
              _ratio(s0 - h, e0 + h) + _ratio(s0 - h, e0 - h)) / (4h^2)
    maximum(abs.([hss - hss_fd, hse - hse_fd, hee - hee_fd])) <= 2e-8 ||
        error("analytic Hessian does not match finite differences")
    println("SELF_TEST_PASS deterministic ratio decomposition, covariance sensitivity, order invariance, Hessian")
end

function main(args = ARGS)
    if _arg(args, "self-test", "false") == "true"
        _self_test()
        return
    end
    rr = _arg(args, "repeatability")
    rr === nothing && error("--repeatability=<pooled TSV> is required")
    out = _arg(args, "out")
    out === nothing && error("--out=<summary TSV> is required")
    rr_sha = _arg(args, "repeatability-sha256")
    rr_sha === nothing && error("--repeatability-sha256=<digest> is required")

    supplied_specs = [
        ("arbK", _arg(args, "supplied-arbk"), _arg(args, "supplied-arbk-sha256")),
        ("identity", _arg(args, "supplied-identity"), _arg(args, "supplied-identity-sha256")),
        ("pedA", _arg(args, "supplied-peda"), _arg(args, "supplied-peda-sha256")),
    ]
    all(spec -> spec[2] !== nothing && spec[3] !== nothing, supplied_specs) ||
        error("all three supplied-K paths and SHA-256 digests are required")

    _self_test()
    rr_summary, observed_rr_sha, excluded = _load_repeatability(rr, rr_sha)
    summaries = [rr_summary]
    hashes = [("repeatability", observed_rr_sha)]
    for (label, path, expected_sha) in supplied_specs
        summary, observed_sha = _load_supplied(path, label, expected_sha)
        push!(summaries, summary)
        push!(hashes, (label, observed_sha))
    end
    _write_output(out, summaries)
    println("ANALYSIS_COMPLETE out=$out rows=$(length(summaries)) excluded_repeatability_seed=$(only(excluded))")
    for summary in summaries
        @printf("DECOMPOSITION label=%s m=%d total_bias=%+.8f mcse=%.8f ratio_bias_pass=%s mean_shift=%+.8f nonlinear=%+.8f delta2=%+.8f remainder=%+.8f shares=(%.3f,%.3f)\n",
            summary.label, summary.m, summary.total_bias, summary.total_mcse,
            string(summary.ratio_bias_pass), summary.mean_shift, summary.nonlinear,
            summary.delta2_nonlinear, summary.delta2_remainder,
            summary.mean_shift_share, summary.nonlinear_share)
    end
    for (label, digest) in hashes
        println("INPUT_SHA256 label=$label digest=$digest")
    end
end

end # module RepeatabilityRatioBiasAnalysis

if abspath(PROGRAM_FILE) == @__FILE__
    RepeatabilityRatioBiasAnalysis.main()
end
