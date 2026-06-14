using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in recovery harness for Phase 4 unstructured multivariate REML.

This script is deliberately outside `test/` so the package test suite remains
RNG-free. It simulates a repeated-record half-sib design with two correlated
traits, fits the unstructured multivariate REML estimator, and checks that the
estimated genetic and residual covariance matrices recover the generating
matrices within loose, version-robust bounds.

Run from the repository root:

    julia --project=. sim/phase4_multivariate_reml_recovery.jl

Optional arguments:

    --seed=N
    --seeds=N[,N...]
    --iterations=N
    --threshold-g=X
    --threshold-r=X

Use `--seed` for a single historical-style run and `--seeds` for an explicit
seed list. The options are mutually exclusive.
"""

struct MultivariateRecoveryConfig
    seed::Int
    nsire::Int
    ndam::Int
    noffspring::Int
    records_per_animal::Int
    iterations::Int
    threshold_g::Float64
    threshold_r::Float64
end

function _parse_args(args)
    opts = Dict{String,String}()
    for arg in args
        startswith(arg, "--") || throw(ArgumentError("arguments must use --key=value form, got $arg"))
        keyval = split(arg[3:end], "=", limit = 2)
        length(keyval) == 2 || throw(ArgumentError("arguments must use --key=value form, got $arg"))
        opts[keyval[1]] = keyval[2]
    end

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
        [parse(Int, get(opts, "seed", "20260616"))]
    end
    iterations = parse(Int, get(opts, "iterations", "5000"))
    iterations > 0 || throw(ArgumentError("--iterations must be positive"))
    threshold_g = parse(Float64, get(opts, "threshold-g", "0.25"))
    threshold_r = parse(Float64, get(opts, "threshold-r", "0.20"))
    threshold_g > 0 || throw(ArgumentError("--threshold-g must be positive"))
    threshold_r > 0 || throw(ArgumentError("--threshold-r must be positive"))
    return seeds, iterations, threshold_g, threshold_r
end

function _halfsib_pedigree(nsire, ndam, noffspring)
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

function _simulate_repeated_records(config::MultivariateRecoveryConfig)
    rng = MersenneTwister(config.seed)
    ped = _halfsib_pedigree(config.nsire, config.ndam, config.noffspring)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    t = 2

    Gtrue = [1.0 0.35; 0.35 0.7]
    Rtrue = [0.8 0.2; 0.2 0.55]
    LA = cholesky(Symmetric(A)).L
    LG = cholesky(Symmetric(Gtrue)).L
    LR = cholesky(Symmetric(Rtrue)).L

    U = LA * randn(rng, q, t) * transpose(LG)
    n = q * config.records_per_animal
    X = ones(n, 1)
    Z = zeros(n, q)
    Y = zeros(n, t)
    row = 1
    for animal in 1:q, _rep in 1:config.records_per_animal
        Z[row, animal] = 1.0
        Y[row, :] .= 2.0 .+ U[animal, :] .+
                     (randn(rng, 1, t) * transpose(LR))[1, :]
        row += 1
    end

    return Y, X, Z, Ainv, Gtrue, Rtrue
end

function _run(config::MultivariateRecoveryConfig)
    Y, X, Z, Ainv, Gtrue, Rtrue = _simulate_repeated_records(config)
    fit = fit_multivariate_reml(
        Y,
        X,
        Z,
        Ainv;
        initial = (G0 = Gtrue, R0 = Rtrue),
        iterations = config.iterations,
    )
    rel_g = norm(fit.genetic_covariance - Gtrue) / norm(Gtrue)
    rel_r = norm(fit.residual_covariance - Rtrue) / norm(Rtrue)
    pass = fit.converged && rel_g <= config.threshold_g && rel_r <= config.threshold_r
    return (
        seed = config.seed,
        observations = size(Y, 1),
        animals = size(Z, 2),
        traits = size(Y, 2),
        records_per_animal = config.records_per_animal,
        converged = fit.converged,
        iterations = fit.iterations,
        rel_g = rel_g,
        rel_r = rel_r,
        threshold_g = config.threshold_g,
        threshold_r = config.threshold_r,
        genetic_covariance = fit.genetic_covariance,
        residual_covariance = fit.residual_covariance,
        pass = pass,
    )
end

function _print_result(result)
    status = result.pass ? "PASS" : "FAIL"
    @printf("[%s] unstructured seed=%d observations=%d animals=%d traits=%d records_per_animal=%d\n",
        status, result.seed, result.observations, result.animals,
        result.traits, result.records_per_animal)
    @printf("  converged=%s iterations=%d\n", result.converged, result.iterations)
    @printf("  relative_error_G=%.6f threshold=%.3f\n", result.rel_g, result.threshold_g)
    @printf("  relative_error_R=%.6f threshold=%.3f\n", result.rel_r, result.threshold_r)
    println("  estimated_G =")
    show(stdout, "text/plain", round.(result.genetic_covariance; digits = 3))
    println()
    println("  estimated_R =")
    show(stdout, "text/plain", round.(result.residual_covariance; digits = 3))
    println("\n")
end

function _print_summary(results)
    pass_count = count(result -> result.pass, results)
    max_rel_g = maximum(result.rel_g for result in results)
    max_rel_r = maximum(result.rel_r for result in results)
    @printf("SUMMARY seeds=%d passed=%d max_relative_error_G=%.6f max_relative_error_R=%.6f\n",
        length(results), pass_count, max_rel_g, max_rel_r)
end

function main(args = ARGS)
    seeds, iterations, threshold_g, threshold_r = _parse_args(args)
    results = Any[]
    for seed in seeds
        result = _run(MultivariateRecoveryConfig(seed, 8, 16, 56, 3, iterations, threshold_g, threshold_r))
        _print_result(result)
        push!(results, result)
        flush(stdout)
    end
    _print_summary(results)
    all(result.pass for result in results) || exit(1)
    return nothing
end

main()
