using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in recovery harness for Phase 5 direct marker-scan helpers.

This script is deliberately outside `test/` so the package test suite remains
RNG-free. It simulates a single known causal marker with a strong additive
effect, runs the direct Julia fixed, supplied-variance mixed, and supplied LOCO
marker scans, and checks loose recovery properties: the causal marker is the
top raw-p marker, the estimated effect has the expected sign and magnitude, and
the nominal returned-marker-set summaries flag the causal marker.

Run from the repository root:

    julia --project=. sim/phase5_marker_scan_recovery.jl

On interactive machines, prefer throttling Julia/BLAS/OpenMP threads and using
lower process priority:

    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 julia --project=. sim/phase5_marker_scan_recovery.jl

Optional arguments:

    --case=all|fixed|mixed|loco
    --seed=N
    --seeds=N[,N...]
    --n=N
    --markers=N
    --effect=X
    --sigma-a2=X
    --sigma-e2=X
    --threshold-effect-rel=X
    --threshold-p=X
    --threshold-bh=X
    --min-lod=X

The thresholds are loose smoke-check thresholds for the simulated scenario.
They are not calibrated genome-wide thresholds, QTL/eQTL evidence, or
comparator parity.
"""

struct MarkerRecoveryConfig
    case::Symbol
    seed::Int
    n::Int
    markers::Int
    effect::Float64
    sigma_a2::Float64
    sigma_e2::Float64
    threshold_effect_rel::Float64
    threshold_p::Float64
    threshold_bh::Float64
    min_lod::Float64
end

function _parse_args(args)
    opts = Dict{String,String}()
    for arg in args
        startswith(arg, "--") || throw(ArgumentError("arguments must use --key=value form, got $arg"))
        keyval = split(arg[3:end], "=", limit = 2)
        length(keyval) == 2 || throw(ArgumentError("arguments must use --key=value form, got $arg"))
        opts[keyval[1]] = keyval[2]
    end
    allowed = Set([
        "case",
        "seed",
        "seeds",
        "n",
        "markers",
        "effect",
        "sigma-a2",
        "sigma-e2",
        "threshold-effect-rel",
        "threshold-p",
        "threshold-bh",
        "min-lod",
    ])
    unknown = sort(setdiff(collect(keys(opts)), collect(allowed)))
    isempty(unknown) ||
        throw(ArgumentError("unknown arguments: $(join(unknown, ", "))"))

    case = Symbol(get(opts, "case", "all"))
    case in (:all, :fixed, :mixed, :loco) ||
        throw(ArgumentError("--case must be one of all, fixed, mixed, or loco"))

    haskey(opts, "seed") && haskey(opts, "seeds") &&
        throw(ArgumentError("use either --seed or --seeds, not both"))
    seeds = if haskey(opts, "seeds")
        parsed = Int[]
        for raw_seed in split(opts["seeds"], ",")
            seed_text = strip(raw_seed)
            isempty(seed_text) && throw(ArgumentError("--seeds must not contain empty entries"))
            push!(parsed, parse(Int, seed_text))
        end
        isempty(parsed) && throw(ArgumentError("--seeds must include at least one seed"))
        length(unique(parsed)) == length(parsed) ||
            throw(ArgumentError("--seeds must not contain duplicate entries"))
        parsed
    else
        [parse(Int, get(opts, "seed", "20260614"))]
    end

    n = parse(Int, get(opts, "n", "180"))
    markers = parse(Int, get(opts, "markers", "24"))
    n >= 40 || throw(ArgumentError("--n must be at least 40"))
    markers >= 8 || throw(ArgumentError("--markers must be at least 8"))

    effect = parse(Float64, get(opts, "effect", "1.5"))
    sigma_a2 = parse(Float64, get(opts, "sigma-a2", "0.20"))
    sigma_e2 = parse(Float64, get(opts, "sigma-e2", "0.25"))
    threshold_effect_rel = parse(Float64, get(opts, "threshold-effect-rel", "0.35"))
    threshold_p = parse(Float64, get(opts, "threshold-p", "1e-6"))
    threshold_bh = parse(Float64, get(opts, "threshold-bh", "0.05"))
    min_lod = parse(Float64, get(opts, "min-lod", "4.0"))

    effect != 0 && isfinite(effect) ||
        throw(ArgumentError("--effect must be finite and non-zero"))
    sigma_a2 >= 0 && isfinite(sigma_a2) ||
        throw(ArgumentError("--sigma-a2 must be finite and non-negative"))
    sigma_e2 > 0 && isfinite(sigma_e2) ||
        throw(ArgumentError("--sigma-e2 must be finite and positive"))
    threshold_effect_rel > 0 && isfinite(threshold_effect_rel) ||
        throw(ArgumentError("--threshold-effect-rel must be finite and positive"))
    0 < threshold_p <= 1 ||
        throw(ArgumentError("--threshold-p must be in (0, 1]"))
    0 < threshold_bh <= 1 ||
        throw(ArgumentError("--threshold-bh must be in (0, 1]"))
    min_lod >= 0 && isfinite(min_lod) ||
        throw(ArgumentError("--min-lod must be finite and non-negative"))

    return case, seeds, n, markers, effect, sigma_a2, sigma_e2,
        threshold_effect_rel, threshold_p, threshold_bh, min_lod
end

function _marker_matrix(rng, n::Int, m::Int)
    markers = zeros(Float64, n, m)
    for j in 1:m
        p = 0.18 + 0.34 * (j - 1) / max(m - 1, 1)
        for i in 1:n
            markers[i, j] = (rand(rng) < p) + (rand(rng) < p)
        end
    end
    return markers
end

function _marker_groups(m::Int)
    return ["chr$(((j - 1) % 4) + 1)" for j in 1:m]
end

function _halfsib_pedigree(n::Int)
    nsire = max(4, min(8, n ÷ 10))
    ndam = max(8, min(16, n ÷ 5))
    noffspring = n - nsire - ndam
    noffspring > 0 ||
        throw(ArgumentError("n must leave at least one offspring after founders"))

    sire_ids = ["s$(i)" for i in 1:nsire]
    dam_ids = ["d$(i)" for i in 1:ndam]
    offspring_ids = ["o$(i)" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, offspring_ids)
    sire = vcat(
        fill("0", nsire + ndam),
        [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring],
    )
    dam = vcat(
        fill("0", nsire + ndam),
        [dam_ids[((i - 1) % ndam) + 1] for i in 1:noffspring],
    )
    return normalize_pedigree(ids, sire, dam)
end

function _simulated_scan_inputs(config::MarkerRecoveryConfig)
    rng = MersenneTwister(config.seed)
    n = config.n
    m = config.markers
    markers = _marker_matrix(rng, n, m)
    marker_ids = ["m" * lpad(string(j), 2, "0") for j in 1:m]
    causal_index = max(2, min(m - 1, cld(m, 3)))
    causal_marker = marker_ids[causal_index]

    batch = [isodd(i) ? -0.5 : 0.5 for i in 1:n]
    X = hcat(ones(n), batch)
    cm = centered_markers(markers)
    signal = config.effect .* cm.W[:, causal_index]

    pedigree = _halfsib_pedigree(n)
    Ainv = pedigree_inverse(pedigree)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    Z = Matrix{Float64}(I, n, n)
    random_effect = sqrt(config.sigma_a2) .* (cholesky(Symmetric(A)).L * randn(rng, n))
    residual = sqrt(config.sigma_e2) .* randn(rng, n)
    y = 1.0 .+ 0.35 .* batch .+ signal .+ random_effect .+ residual

    return (
        y = y,
        X = X,
        Z = Z,
        Ainv = Ainv,
        markers = markers,
        marker_ids = marker_ids,
        marker_groups = _marker_groups(m),
        causal_index = causal_index,
        causal_marker = causal_marker,
    )
end

function _scan_for_case(config::MarkerRecoveryConfig, inputs)
    if config.case == :fixed
        return single_marker_scan(
            inputs.y,
            inputs.X,
            inputs.markers;
            sigma_e2 = config.sigma_a2 + config.sigma_e2,
            marker_ids = inputs.marker_ids,
        )
    elseif config.case == :mixed
        return mixed_model_marker_scan(
            inputs.y,
            inputs.X,
            inputs.Z,
            inputs.Ainv,
            inputs.markers,
            config.sigma_a2,
            config.sigma_e2;
            marker_ids = inputs.marker_ids,
        )
    elseif config.case == :loco
        precisions = loco_relationship_precisions(
            inputs.markers,
            inputs.marker_groups;
            ridge = 0.25,
        )
        return loco_mixed_model_marker_scan(
            inputs.y,
            inputs.X,
            inputs.Z,
            precisions,
            inputs.marker_groups,
            inputs.markers,
            config.sigma_a2,
            config.sigma_e2;
            marker_ids = inputs.marker_ids,
        )
    end
    throw(ArgumentError("unsupported recovery case $(config.case)"))
end

function _run_case(config::MarkerRecoveryConfig)
    inputs = _simulated_scan_inputs(config)
    scan = _scan_for_case(config, inputs)
    significance = marker_significance_summary(scan; alpha = config.threshold_bh)
    top_index = significance.top_scan_index
    effect_hat = scan.effects[inputs.causal_index]
    effect_rel_error = abs(effect_hat - config.effect) / abs(config.effect)
    top_p_value = significance.top_p_value
    top_bh_q_value = significance.top_bh_q_value
    top_lod_score = significance.top_lod_score
    bh_hits_causal = inputs.causal_marker in significance.bh_marker_ids

    pass = top_index == inputs.causal_index &&
        sign(effect_hat) == sign(config.effect) &&
        effect_rel_error <= config.threshold_effect_rel &&
        top_p_value <= config.threshold_p &&
        top_bh_q_value <= config.threshold_bh &&
        top_lod_score >= config.min_lod &&
        bh_hits_causal

    return (
        case = config.case,
        seed = config.seed,
        observations = config.n,
        markers = config.markers,
        causal_marker = inputs.causal_marker,
        top_marker = significance.top_marker_id,
        causal_effect = config.effect,
        estimated_effect = effect_hat,
        effect_rel_error = effect_rel_error,
        threshold_effect_rel = config.threshold_effect_rel,
        top_p_value = top_p_value,
        threshold_p = config.threshold_p,
        top_bh_q_value = top_bh_q_value,
        threshold_bh = config.threshold_bh,
        top_lod_score = top_lod_score,
        min_lod = config.min_lod,
        n_bh_significant = significance.n_bh_significant,
        pass = pass,
    )
end

function _print_result(result)
    status = result.pass ? "PASS" : "FAIL"
    @printf("[%s] %s seed=%d observations=%d markers=%d causal_marker=%s top_marker=%s\n",
        status, result.case, result.seed, result.observations, result.markers,
        result.causal_marker, result.top_marker)
    @printf("  estimated_effect=%.6f target_effect=%.6f relative_error=%.6f threshold=%.3f\n",
        result.estimated_effect, result.causal_effect, result.effect_rel_error,
        result.threshold_effect_rel)
    @printf("  top_p_value=%.6e threshold=%.6e\n", result.top_p_value, result.threshold_p)
    @printf("  top_bh_q_value=%.6e threshold=%.6e n_bh_significant=%d\n",
        result.top_bh_q_value, result.threshold_bh, result.n_bh_significant)
    @printf("  top_lod_score=%.6f threshold=%.3f\n\n", result.top_lod_score, result.min_lod)
end

function _print_summary(results)
    println("SUMMARY")
    for case in unique(result.case for result in results)
        case_results = filter(result -> result.case == case, results)
        pass_count = count(result -> result.pass, case_results)
        max_effect_error = maximum(result.effect_rel_error for result in case_results)
        max_top_p = maximum(result.top_p_value for result in case_results)
        @printf("  %s seeds=%d passed=%d max_effect_rel_error=%.6f max_top_p_value=%.6e\n",
            case, length(case_results), pass_count, max_effect_error, max_top_p)
    end
end

function main(args = ARGS)
    case, seeds, n, markers, effect, sigma_a2, sigma_e2, threshold_effect_rel,
        threshold_p, threshold_bh, min_lod = _parse_args(args)
    cases = case == :all ? (:fixed, :mixed, :loco) : (case,)
    results = Any[]
    for c in cases
        for seed in seeds
            config = MarkerRecoveryConfig(
                c,
                seed,
                n,
                markers,
                effect,
                sigma_a2,
                sigma_e2,
                threshold_effect_rel,
                threshold_p,
                threshold_bh,
                min_lod,
            )
            result = _run_case(config)
            _print_result(result)
            push!(results, result)
            flush(stdout)
        end
    end
    _print_summary(results)
    all(result.pass for result in results) || exit(1)
    return nothing
end

main()
