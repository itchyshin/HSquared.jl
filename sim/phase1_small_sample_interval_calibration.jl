#!/usr/bin/env julia

using HSquared
using LinearAlgebra
using Printf
using Random
using SparseArrays

mutable struct IntervalSummary
    reps::Int
    fit_success::Int
    interval_success::Int
    covered::Int
    width_sum::Float64
end

IntervalSummary() = IntervalSummary(0, 0, 0, 0, 0.0)

struct DesignSpec
    label::String
    nsire::Int
    ndam::Int
    noffspring::Int
end

struct HarnessConfig
    reps::Int
    seed::Int
    designs::Vector{DesignSpec}
    h2_values::Vector{Float64}
    levels::Vector{Float64}
    n_boot::Int
    include_bootstrap::Bool
    output::String
end

function _usage()
    return """
    Small-sample Gaussian interval calibration smoke/grid harness.

    This is a validation probe, not a public interval API.

    Options:
      --reps=N              Monte Carlo replicates per condition (default: 5)
      --seed=N              RNG seed (default: 20260627)
      --nsire=N             Number of founder sires (default: 4)
      --ndam=N              Number of founder dams (default: 8)
      --noffspring=N        Number of offspring records (default: 24)
      --designs=LIST        Optional comma-separated named designs:
                            label:nsire:ndam:noffspring
                            Example: tiny:4:8:24,small:8:16:96
      --h2=LIST             Comma-separated true h2 values (default: 0.4)
      --levels=LIST         Comma-separated confidence levels (default: 0.95)
      --nboot=N             Bootstrap samples per fitted replicate (default: 10)
      --bootstrap=true|false
                            Include bootstrap percentile intervals (default: true)
      --out=PATH            Summary TSV path. Rows are grouped by design,
                            target, method, true h2, and confidence level.
    """
end

function _parse_bool(value::AbstractString)
    lower = lowercase(value)
    lower in ("true", "yes", "1") && return true
    lower in ("false", "no", "0") && return false
    error("expected boolean value, got $(value)")
end

function _parse_float_list(value::AbstractString)
    vals = Float64[]
    for item in split(value, ",")
        stripped = strip(item)
        isempty(stripped) && continue
        push!(vals, parse(Float64, stripped))
    end
    isempty(vals) && error("empty numeric list")
    return vals
end

function _parse_designs(value::AbstractString)
    specs = DesignSpec[]
    for item in split(value, ",")
        stripped = strip(item)
        isempty(stripped) && continue
        parts = split(stripped, ":")
        length(parts) == 4 ||
            error("expected design as label:nsire:ndam:noffspring, got $(stripped)")
        label = strip(parts[1])
        isempty(label) && error("design label must not be empty")
        spec = DesignSpec(
            label,
            parse(Int, parts[2]),
            parse(Int, parts[3]),
            parse(Int, parts[4]),
        )
        _check_design_spec(spec)
        push!(specs, spec)
    end
    isempty(specs) && error("empty design list")
    return specs
end

function _check_design_spec(spec::DesignSpec)
    spec.nsire > 0 || error("$(spec.label): nsire must be positive")
    spec.ndam > 0 || error("$(spec.label): ndam must be positive")
    spec.noffspring > 0 || error("$(spec.label): noffspring must be positive")
    return spec
end

function _parse_args(args)
    opts = Dict{String,String}()
    for arg in args
        arg in ("-h", "--help") && (print(_usage()); exit(0))
        startswith(arg, "--") || error("unexpected argument $(arg)")
        pieces = split(arg[3:end], "=", limit = 2)
        length(pieces) == 2 || error("expected --key=value, got $(arg)")
        opts[pieces[1]] = pieces[2]
    end

    default_design = DesignSpec(
        "default",
        parse(Int, get(opts, "nsire", "4")),
        parse(Int, get(opts, "ndam", "8")),
        parse(Int, get(opts, "noffspring", "24")),
    )
    _check_design_spec(default_design)
    designs = haskey(opts, "designs") ? _parse_designs(opts["designs"]) : [default_design]

    return HarnessConfig(
        parse(Int, get(opts, "reps", "5")),
        parse(Int, get(opts, "seed", "20260627")),
        designs,
        _parse_float_list(get(opts, "h2", "0.4")),
        _parse_float_list(get(opts, "levels", "0.95")),
        parse(Int, get(opts, "nboot", "10")),
        _parse_bool(get(opts, "bootstrap", "true")),
        get(
            opts,
            "out",
            joinpath(
                @__DIR__,
                "..",
                "docs",
                "dev-log",
                "recovery-checkpoints",
                "2026-06-27-small-sample-interval-calibration-smoke.tsv",
            ),
        ),
    )
end

function _halfsib_pedigree(spec::DesignSpec)
    ids = String[]
    sire = Union{Missing,String}[]
    dam = Union{Missing,String}[]

    sire_ids = ["$(spec.label)_s$(i)" for i in 1:spec.nsire]
    dam_ids = ["$(spec.label)_d$(i)" for i in 1:spec.ndam]

    append!(ids, sire_ids)
    append!(sire, fill(missing, spec.nsire))
    append!(dam, fill(missing, spec.nsire))

    append!(ids, dam_ids)
    append!(sire, fill(missing, spec.ndam))
    append!(dam, fill(missing, spec.ndam))

    for i in 1:spec.noffspring
        push!(ids, "$(spec.label)_o$(i)")
        push!(sire, sire_ids[mod1(i, spec.nsire)])
        push!(dam, dam_ids[mod1(i, spec.ndam)])
    end

    return normalize_pedigree(ids, sire, dam)
end

function _design(spec::DesignSpec)
    pedigree = _halfsib_pedigree(spec)
    Ainv = sparse(pedigree_inverse(pedigree))
    A = inv(Symmetric(Matrix(Ainv)))
    A = Symmetric((A + A') ./ 2)
    X = ones(length(pedigree.ids), 1)
    Z = sparse(1.0I, length(pedigree.ids), length(pedigree.ids))
    rank_x = rank(X)
    residual_df = max(1, length(pedigree.ids) - rank_x - 2)
    family_df = max(1, spec.nsire + spec.ndam - rank_x - 2)
    chol_A = cholesky(A).L
    return (
        label = spec.label,
        nsire = spec.nsire,
        ndam = spec.ndam,
        noffspring = spec.noffspring,
        pedigree = pedigree,
        Ainv = Ainv,
        chol_A = chol_A,
        X = X,
        Z = Z,
        residual_df = residual_df,
        family_df = family_df,
    )
end

function _normal_quantile(level::Float64)
    return HSquared._standard_normal_quantile((1 + level) / 2)
end

function _student_t_quantile_approx(level::Float64, df::Int)
    z = _normal_quantile(level)
    v = Float64(df)
    return z +
           (z^3 + z) / (4v) +
           (5z^5 + 16z^3 + 3z) / (96v^2) +
           (3z^7 + 19z^5 + 17z^3 - 15z) / (384v^3)
end

function _chisq_quantile_bisect(prob::Float64, df::Float64)
    0 < prob < 1 || error("chi-square probability must be in (0, 1)")
    df > 0 || error("chi-square degrees of freedom must be positive")
    target_tail = 1 - prob
    lo = 0.0
    hi = max(df, 1.0)
    while HSquared._chisq_sf(hi, df) > target_tail
        hi *= 2
        hi < 1e12 || error("could not bracket chi-square quantile")
    end
    for _ in 1:100
        mid = (lo + hi) / 2
        if HSquared._chisq_sf(mid, df) > target_tail
            lo = mid
        else
            hi = mid
        end
    end
    return (lo + hi) / 2
end

function _add!(
    summaries::Dict{Tuple{String,String,String,Float64,Float64,Int,Int,Int},IntervalSummary},
    design,
    target::String,
    method::String,
    h2_true::Float64,
    level::Float64;
    fit_success::Bool,
    interval_success::Bool,
    covered::Bool = false,
    width::Float64 = NaN,
)
    key = (
        design.label,
        target,
        method,
        h2_true,
        level,
        length(design.pedigree.ids),
        design.residual_df,
        design.family_df,
    )
    summary = get!(summaries, key, IntervalSummary())
    summary.reps += 1
    summary.fit_success += fit_success ? 1 : 0
    summary.interval_success += interval_success ? 1 : 0
    summary.covered += covered ? 1 : 0
    if interval_success && isfinite(width)
        summary.width_sum += width
    end
    return summaries
end

function _record_interval!(
    summaries,
    design,
    target::String,
    method::String,
    h2_true::Float64,
    level::Float64,
    truth::Float64,
    interval,
)
    if interval === nothing
        return _add!(
            summaries,
            design,
            target,
            method,
            h2_true,
            level;
            fit_success = true,
            interval_success = false,
        )
    end

    lower, upper = interval
    ok = isfinite(lower) && isfinite(upper) && upper >= lower
    return _add!(
        summaries,
        design,
        target,
        method,
        h2_true,
        level;
        fit_success = true,
        interval_success = ok,
        covered = ok && lower <= truth <= upper,
        width = ok ? upper - lower : NaN,
    )
end

function _safe_interval(f)
    try
        interval = f()
        return (Float64(interval.lower), Float64(interval.upper))
    catch err
        @debug "interval failed" exception = (err, catch_backtrace())
        return nothing
    end
end

function _safe_pair(f)
    try
        lower, upper = f()
        return (Float64(lower), Float64(upper))
    catch err
        @debug "interval failed" exception = (err, catch_backtrace())
        return nothing
    end
end

function _vc_delta_interval(estimate::Float64, se::Float64, quantile::Float64)
    isfinite(estimate) && isfinite(se) && se >= 0 || return nothing
    lower = max(0.0, estimate - quantile * se)
    upper = estimate + quantile * se
    return upper >= lower ? (lower, upper) : nothing
end

function _vc_satterthwaite_chisq_interval(estimate::Float64, se::Float64, level::Float64)
    isfinite(estimate) && estimate > 0 || return nothing
    isfinite(se) && se > 0 || return nothing
    df_eff = 2 * estimate^2 / se^2
    isfinite(df_eff) && df_eff > 0 || return nothing
    # Very small moment-matched df put the lower chi-square quantile essentially
    # at zero, yielding uninformative numerical explosions. Treat that as a
    # failed probe interval rather than evidence for a useful calibration.
    df_eff >= 2 || return nothing
    alpha = 1 - level
    q_lo = _chisq_quantile_bisect(alpha / 2, df_eff)
    q_hi = _chisq_quantile_bisect(1 - alpha / 2, df_eff)
    q_lo > 0 && q_hi > q_lo || return nothing
    lower = df_eff * estimate / q_hi
    upper = df_eff * estimate / q_lo
    return isfinite(lower) && isfinite(upper) && upper >= lower ? (lower, upper) : nothing
end

function _h2_delta_interval(fit, quantile::Float64)
    try
        h2 = Float64(heritability(fit))
        se = Float64(heritability_standard_error(fit))
        0 < h2 < 1 || return nothing
        isfinite(se) && se >= 0 || return nothing
        logit = log(h2 / (1 - h2))
        se_logit = se / (h2 * (1 - h2))
        lower = 1 / (1 + exp(-(logit - quantile * se_logit)))
        upper = 1 / (1 + exp(-(logit + quantile * se_logit)))
        return upper >= lower ? (lower, upper) : nothing
    catch err
        @debug "h2 delta interval failed" exception = (err, catch_backtrace())
        return nothing
    end
end

function _vc_se(fit)
    try
        ses = variance_component_standard_errors(fit)
        return Float64(ses.sigma_a2)
    catch err
        @debug "variance component SE failed" exception = (err, catch_backtrace())
        return NaN
    end
end

function _method_labels(include_bootstrap::Bool)
    labels = [
        ("h2", "h2_delta_z"),
        ("h2", "h2_delta_t_residual_df_probe"),
        ("h2", "h2_delta_t_family_df_probe"),
        ("h2", "h2_profile_chisq"),
        ("sigma_a2", "sigma_a2_delta_z"),
        ("sigma_a2", "sigma_a2_delta_t_residual_df_probe"),
        ("sigma_a2", "sigma_a2_delta_t_family_df_probe"),
        ("sigma_a2", "sigma_a2_satterthwaite_chisq_probe"),
        ("sigma_a2", "sigma_a2_profile_chisq"),
    ]
    if include_bootstrap
        push!(labels, ("h2", "h2_bootstrap_percentile"))
        push!(labels, ("sigma_a2", "sigma_a2_bootstrap_percentile"))
    end
    return labels
end

function _record_fit_failure!(summaries, design, h2_true::Float64, level::Float64, include_bootstrap::Bool)
    for (target, method) in _method_labels(include_bootstrap)
        _add!(
            summaries,
            design,
            target,
            method,
            h2_true,
            level;
            fit_success = false,
            interval_success = false,
        )
    end
end

function _fit_replicate(design, rng::AbstractRNG, h2_true::Float64)
    sigma_a2_true = h2_true
    sigma_e2_true = 1 - h2_true
    a = sqrt(sigma_a2_true) .* (design.chol_A * randn(rng, length(design.pedigree.ids)))
    e = sqrt(sigma_e2_true) .* randn(rng, length(design.pedigree.ids))
    y = 1.0 .+ a .+ e

    spec = animal_model_spec(
        y,
        design.X,
        design.Z,
        design.Ainv;
        ids = design.pedigree.ids,
        method = :REML,
    )

    return fit_ai_reml(
        spec;
        initial = (sigma_a2 = max(sigma_a2_true, 0.05), sigma_e2 = max(sigma_e2_true, 0.05)),
        iterations = 500,
    )
end

function _run_condition!(summaries, config::HarnessConfig, design, rng, h2_true::Float64)
    sigma_a2_true = h2_true

    for rep in 1:config.reps
        fit = try
            _fit_replicate(design, rng, h2_true)
        catch err
            @warn "fit failed" h2_true rep exception = (err, catch_backtrace())
            nothing
        end

        for level in config.levels
            if fit === nothing || !getproperty(fit, :converged)
                _record_fit_failure!(summaries, design, h2_true, level, config.include_bootstrap)
                continue
            end

            z = _normal_quantile(level)
            t_residual = _student_t_quantile_approx(level, design.residual_df)
            t_family = _student_t_quantile_approx(level, design.family_df)

            _record_interval!(
                summaries,
                design,
                "h2",
                "h2_delta_z",
                h2_true,
                level,
                h2_true,
                _safe_interval(() -> heritability_interval(fit; level = level, method = :delta)),
            )
            _record_interval!(
                summaries,
                design,
                "h2",
                "h2_delta_t_residual_df_probe",
                h2_true,
                level,
                h2_true,
                _h2_delta_interval(fit, t_residual),
            )
            _record_interval!(
                summaries,
                design,
                "h2",
                "h2_delta_t_family_df_probe",
                h2_true,
                level,
                h2_true,
                _h2_delta_interval(fit, t_family),
            )
            _record_interval!(
                summaries,
                design,
                "h2",
                "h2_profile_chisq",
                h2_true,
                level,
                h2_true,
                _safe_interval(() -> heritability_interval(fit; level = level, method = :profile)),
            )

            vc_estimate = Float64(fit.variance_components.sigma_a2)
            vc_se = _vc_se(fit)
            _record_interval!(
                summaries,
                design,
                "sigma_a2",
                "sigma_a2_delta_z",
                h2_true,
                level,
                sigma_a2_true,
                _vc_delta_interval(vc_estimate, vc_se, z),
            )
            _record_interval!(
                summaries,
                design,
                "sigma_a2",
                "sigma_a2_delta_t_residual_df_probe",
                h2_true,
                level,
                sigma_a2_true,
                _vc_delta_interval(vc_estimate, vc_se, t_residual),
            )
            _record_interval!(
                summaries,
                design,
                "sigma_a2",
                "sigma_a2_delta_t_family_df_probe",
                h2_true,
                level,
                sigma_a2_true,
                _vc_delta_interval(vc_estimate, vc_se, t_family),
            )
            _record_interval!(
                summaries,
                design,
                "sigma_a2",
                "sigma_a2_satterthwaite_chisq_probe",
                h2_true,
                level,
                sigma_a2_true,
                _vc_satterthwaite_chisq_interval(vc_estimate, vc_se, level),
            )
            _record_interval!(
                summaries,
                design,
                "sigma_a2",
                "sigma_a2_profile_chisq",
                h2_true,
                level,
                sigma_a2_true,
                _safe_interval(() -> variance_component_interval(fit; level = level)),
            )

            if config.include_bootstrap
                boot_rng = MersenneTwister(rand(rng, 1:10^9))
                boot = try
                    bootstrap_variance_component_interval(
                        fit;
                        level = level,
                        n_boot = config.n_boot,
                        estimator = :ai_reml,
                        rng = boot_rng,
                    )
                catch err
                    @warn "bootstrap interval failed" h2_true rep level exception = (err, catch_backtrace())
                    nothing
                end

                _record_interval!(
                    summaries,
                    design,
                    "h2",
                    "h2_bootstrap_percentile",
                    h2_true,
                    level,
                    h2_true,
                    boot === nothing ? nothing : (Float64(boot.heritability_ci.lower), Float64(boot.heritability_ci.upper)),
                )
                _record_interval!(
                    summaries,
                    design,
                    "sigma_a2",
                    "sigma_a2_bootstrap_percentile",
                    h2_true,
                    level,
                    sigma_a2_true,
                    boot === nothing ? nothing : (Float64(boot.sigma_a2_ci.lower), Float64(boot.sigma_a2_ci.upper)),
                )
            end
        end
    end

    return summaries
end

function _format_float(x::Float64)
    return isfinite(x) ? @sprintf("%.8g", x) : "NaN"
end

function _write_summary(path::AbstractString, summaries)
    mkpath(dirname(path))
    rows = sort(collect(summaries); by = pair -> string(pair[1]))
    open(path, "w") do io
        println(
            io,
            join(
                [
                    "target",
                    "method",
                    "design",
                    "n_animals",
                    "residual_df",
                    "family_df",
                    "h2_true",
                    "level",
                    "reps",
                    "fit_success",
                    "interval_success",
                    "covered",
                    "coverage",
                    "mcse_observed",
                    "mcse_nominal",
                    "mean_width",
                ],
                '\t',
            ),
        )
        for ((design_label, target, method, h2_true, level, n_animals, residual_df, family_df), summary) in rows
            n = summary.interval_success
            coverage = n > 0 ? summary.covered / n : NaN
            mcse_observed = n > 0 ? sqrt(max(coverage * (1 - coverage), 0) / n) : NaN
            mcse_nominal = n > 0 ? sqrt(level * (1 - level) / n) : NaN
            mean_width = n > 0 ? summary.width_sum / n : NaN
            println(
                io,
                join(
                    [
                        target,
                        method,
                        design_label,
                        string(n_animals),
                        string(residual_df),
                        string(family_df),
                        _format_float(h2_true),
                        _format_float(level),
                        string(summary.reps),
                        string(summary.fit_success),
                        string(summary.interval_success),
                        string(summary.covered),
                        _format_float(coverage),
                        _format_float(mcse_observed),
                        _format_float(mcse_nominal),
                        _format_float(mean_width),
                    ],
                    '\t',
                ),
            )
        end
    end
    return path
end

function main(args = ARGS)
    config = _parse_args(args)
    config.reps > 0 || error("--reps must be positive")
    config.n_boot >= 0 || error("--nboot must be non-negative")
    all(0 .< config.h2_values .< 1) || error("--h2 values must be in (0, 1)")
    all(0 .< config.levels .< 1) || error("--levels values must be in (0, 1)")

    rng = MersenneTwister(config.seed)
    summaries = Dict{Tuple{String,String,String,Float64,Float64,Int,Int,Int},IntervalSummary}()

    designs = [_design(spec) for spec in config.designs]
    for design in designs
        for h2_true in config.h2_values
            _run_condition!(summaries, config, design, rng, h2_true)
        end
    end

    path = _write_summary(config.output, summaries)
    println("wrote ", path)
    println("seed=", config.seed)
    println("reps=", config.reps, " h2=", join(config.h2_values, ","), " levels=", join(config.levels, ","))
    for design in designs
        println(
            "design=", design.label,
            " pedigree_n=", length(design.pedigree.ids),
            " residual_df=", design.residual_df,
            " family_df=", design.family_df,
        )
    end
    println("bootstrap=", config.include_bootstrap, " n_boot=", config.n_boot)
    return path
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
