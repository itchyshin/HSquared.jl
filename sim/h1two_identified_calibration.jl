# Ratified H1-two identified fixture.  This is deliberately a deterministic
# path fixture, not a coverage campaign and not a public capability change.

using HSquared
using LinearAlgebra
using Random
using SparseArrays

const H1T_SEED = 20260701
const H1T_SIRES = 20
const H1T_OFFSPRING = 200
const H1T_GROUPS = 40
const H1T_TRUTH = (sigma1 = 1.0, sigma2 = 0.5, sigma_e2 = 1.0)
const H1T_LEVEL = 0.95

function h1two_identified_fixture(; seed::Integer = H1T_SEED,
                                  sires::Integer = H1T_SIRES,
                                  offspring::Integer = H1T_OFFSPRING,
                                  groups::Integer = H1T_GROUPS)
    seed == H1T_SEED || throw(ArgumentError("ratified H1-two seed is $(H1T_SEED)"))
    sires == H1T_SIRES || throw(ArgumentError("ratified H1-two sire count is $(H1T_SIRES)"))
    offspring == H1T_OFFSPRING || throw(ArgumentError("ratified H1-two offspring count is $(H1T_OFFSPRING)"))
    groups == H1T_GROUPS || throw(ArgumentError("ratified H1-two group count is $(H1T_GROUPS)"))

    rng = MersenneTwister(seed)
    sire = zeros(Int, sires + offspring)
    for i in 1:offspring
        sire[sires + i] = rand(rng, 1:sires)
    end
    Ainv = pedigree_inverse(collect(1:(sires + offspring)), sire,
                            zeros(Int, sires + offspring))
    A = inv(Symmetric(Matrix(Ainv)))
    n_animals = size(A, 1)
    genetic = cholesky(Symmetric(A + 1e-8I)).L * randn(rng, n_animals)
    group_effect = randn(rng, groups) .* sqrt(H1T_TRUTH.sigma2)
    records = (sires + 1):(sires + offspring)
    n = length(records)
    X = ones(n, 1)
    Z1 = zeros(n, n_animals)
    Z2 = zeros(n, groups)
    y = zeros(n)
    for (row, animal) in enumerate(records)
        Z1[row, animal] = 1.0
        group = rand(rng, 1:groups) # independent of pedigree by construction
        Z2[row, group] = 1.0
        y[row] = 3.0 + genetic[animal] + group_effect[group] + randn(rng)
    end
    A2inv = sparse(Matrix(1.0I, groups, groups))
    interval = two_effect_ratio_interval(y, X, sparse(Z1), Ainv, sparse(Z2), A2inv;
                                          level = H1T_LEVEL)
    fit = fit_two_effect_reml(y, X, sparse(Z1), Ainv, sparse(Z2), A2inv)
    return (fit = fit, interval = interval, n = n, claim_eligible = false)
end

if abspath(PROGRAM_FILE) == @__FILE__
    result = h1two_identified_fixture()
    println("H1T_IDENTIFIED_PATH_ONLY converged=$(result.fit.converged) n=$(result.n) claim_eligible=false")
end
