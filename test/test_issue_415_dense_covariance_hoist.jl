# test_issue_415_dense_covariance_hoist.jl: Part of #415.
#
# Defect: the dense `two_effect` / `repeatability` REML objectives rebuilt
# `Z1*A1*Z1'` and `Z2*A2*Z2'` (dense n x q x q products, independent of the variances)
# on every NelderMead evaluation. `_two_effect_dense_pre` takes those products
# precomputed; it must return bit-identical results to `_two_effect_dense`.
# Red on main: `_two_effect_dense_pre` does not exist.

using HSquared
using Test
using LinearAlgebra
using Random

@testset "#415 dense covariance hoist is bit-identical" begin
    rng = MersenneTwister(415)
    n, q1, q2 = 40, 12, 5
    X = hcat(ones(n), randn(rng, n))
    Z1 = Matrix{Float64}(I, n, n)[:, 1:q1][shuffle(rng, 1:n), :]
    Z2 = Float64.(reshape(rand(rng, 1:q2, n), n, 1) .== reshape(1:q2, 1, q2))
    B = randn(rng, q1, q1); A1 = B * B' + I
    A2 = Matrix{Float64}(I, q2, q2)
    y = randn(rng, n)
    G1 = Z1 * A1 * transpose(Z1)
    G2 = Z2 * A2 * transpose(Z2)
    for s in ((0.7, 1.3, 2.1), (1e-3, 4.0, 0.5))
        a = HSquared._two_effect_dense(y, X, Z1, A1, Z2, A2, s...)
        b = HSquared._two_effect_dense_pre(y, X, Z1, A1, G1, Z2, A2, G2, s...)
        @test a[1] === b[1]
        @test a[2] == b[2]
        @test a[3] == b[3]
        @test a[4] == b[4]
    end
end
