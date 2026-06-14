using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in recovery harness for Phase 4B structured multivariate covariance fits.

This script is deliberately outside `test/` so the package test suite remains
RNG-free. It simulates a repeated-record half-sib design where the genetic
covariance has either a rank-1 low-rank form or a rank-1 factor-analytic form,
then checks that `fit_multivariate_reml` recovers the true covariance matrices
within loose, version-robust bounds.

Run from the repository root:

    julia --project=. sim/phase4b_structured_covariance_recovery.jl

Optional arguments:

    --case=both|factor_analytic|lowrank
    --iterations=N
    --threshold-g=X
    --threshold-r=X
"""

struct RecoveryConfig
    case::Symbol
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

    case = Symbol(get(opts, "case", "both"))
    case in (:both, :factor_analytic, :lowrank) ||
        throw(ArgumentError("--case must be one of both, factor_analytic, or lowrank"))
    iterations = parse(Int, get(opts, "iterations", "5000"))
    iterations > 0 || throw(ArgumentError("--iterations must be positive"))
    threshold_g = parse(Float64, get(opts, "threshold-g", "0.45"))
    threshold_r = parse(Float64, get(opts, "threshold-r", "0.25"))
    threshold_g > 0 || throw(ArgumentError("--threshold-g must be positive"))
    threshold_r > 0 || throw(ArgumentError("--threshold-r must be positive"))
    return case, iterations, threshold_g, threshold_r
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

function _simulate_repeated_records(config::RecoveryConfig)
    rng = MersenneTwister(config.seed)
    ped = _halfsib_pedigree(config.nsire, config.ndam, config.noffspring)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    t = 3

    loadings = reshape([0.9, 0.55, -0.35], t, 1)
    uniqueness = [0.35, 0.45, 0.55]
    Gtrue = config.case == :lowrank ?
        Matrix(lowrank_covariance(loadings)) :
        Matrix(factor_analytic_covariance(loadings, uniqueness))
    Rtrue = [0.85 0.18 0.05; 0.18 0.75 -0.08; 0.05 -0.08 0.65]

    # The low-rank genetic covariance is singular by construction. The tiny
    # jitter is only for simulation Cholesky; the fitted target remains low-rank.
    Gsim = config.case == :lowrank ? Gtrue + 1e-12I : Gtrue
    LA = cholesky(Symmetric(A)).L
    LG = cholesky(Symmetric(Matrix(Gsim))).L
    LR = cholesky(Symmetric(Rtrue)).L

    U = LA * randn(rng, q, t) * transpose(LG)
    n = q * config.records_per_animal
    X = ones(n, 1)
    Z = zeros(n, q)
    Y = zeros(n, t)
    row = 1
    for animal in 1:q, _rep in 1:config.records_per_animal
        Z[row, animal] = 1.0
        Y[row, :] .= 1.5 .+ U[animal, :] .+
                     (randn(rng, 1, t) * transpose(LR))[1, :]
        row += 1
    end

    initial = config.case == :lowrank ?
        (loadings = 0.7 .* loadings, R0 = 1.2 .* Rtrue) :
        (loadings = 0.7 .* loadings, uniqueness = 1.3 .* uniqueness, R0 = 1.2 .* Rtrue)

    return Y, X, Z, Ainv, Gtrue, Rtrue, loadings, uniqueness, initial
end

function _run_case(config::RecoveryConfig)
    Y, X, Z, Ainv, Gtrue, Rtrue, _loadings, _uniqueness, initial =
        _simulate_repeated_records(config)
    fit = fit_multivariate_reml(
        Y,
        X,
        Z,
        Ainv;
        genetic_structure = config.case,
        rank = 1,
        initial = initial,
        iterations = config.iterations,
    )
    rel_g = norm(fit.genetic_covariance - Gtrue) / norm(Gtrue)
    rel_r = norm(fit.residual_covariance - Rtrue) / norm(Rtrue)
    pass = fit.converged && rel_g <= config.threshold_g && rel_r <= config.threshold_r
    return (
        case = config.case,
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
    @printf("[%s] %s seed=%d observations=%d animals=%d traits=%d records_per_animal=%d\n",
        status, result.case, result.seed, result.observations, result.animals,
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

function main(args = ARGS)
    case, iterations, threshold_g, threshold_r = _parse_args(args)
    cases = case == :both ? (:factor_analytic, :lowrank) : (case,)
    seeds = Dict(:factor_analytic => 20260614, :lowrank => 20260615)
    results = map(cases) do c
        _run_case(RecoveryConfig(c, seeds[c], 6, 12, 42, 3, iterations, threshold_g, threshold_r))
    end
    foreach(_print_result, results)
    all(result.pass for result in results) || exit(1)
    return nothing
end

main()
