# HSquared.jl #426 — sparse K-effect AI-REML on an ACE twin model whose C
# component is on the boundary must return the REML optimum (not an early-exit
# iterate far from it), from any start, with a status that is not
# boundary_score_unresolved. Standalone:
#   julia --project=. -e 'include("test/test_issue_426_ace_boundary_optimum.jl")'
# `converged` is NOT asserted: whether a boundary optimum may report converged
# = true is an open owner decision (DECISIONS-PENDING.md).

using HSquared
using LinearAlgebra
using Random
using SparseArrays
using Test

function _issue426_ace_fixture(; npairs = 700, va = 0.7, ve = 0.3, seed = 426)
    rng = MersenneTwister(seed)
    n = 2npairs
    r = [i <= npairs ÷ 2 ? 1.0 : 0.5 for i in 1:npairs]      # MZ then DZ
    y = zeros(n)
    for p in 1:npairs
        shared = sqrt(r[p]) * randn(rng)
        g = shared .+ sqrt(1 - r[p]) .* randn(rng, 2)
        y[2p - 1:2p] = sqrt(va) .* g .+ sqrt(ve) .* randn(rng, 2)
    end
    eps = 1e-6
    I_, J_, V_ = Int[], Int[], Float64[]
    for p in 1:npairs
        a = 1 + eps; d = a^2 - r[p]^2
        for (u, v, val) in ((2p - 1, 2p - 1, a / d), (2p, 2p, a / d),
                            (2p - 1, 2p, -r[p] / d), (2p, 2p - 1, -r[p] / d))
            push!(I_, u); push!(J_, v); push!(V_, val)
        end
    end
    Ainv = sparse(I_, J_, V_, n, n)
    Zp = sparse(1:n, repeat(1:npairs, inner = 2), 1.0, n, npairs)
    effects = [(sparse(1.0I, n, n), Ainv), (Zp, sparse(1.0I, npairs, npairs))]
    return y, reshape(ones(n), n, 1), effects
end

@testset "ACE boundary C: AI-REML reaches the optimum from every start (#426)" begin
    y, X, effects = _issue426_ace_fixture()
    ll(f) = HSquared.sparse_multi_reml_loglik(
        y, X, effects, f.variance_components.sigmas, f.variance_components.sigma_e2)
    value(r) = r isa Tuple ? r[1] : r
    fits = [HSquared.fit_multi_effect(y, X, effects; method = :auto, verbose = false,
                                      initial = s, iterations = 400)
            for s in (nothing, :auto, [0.1, 0.1, 0.1], [0.005, 1e-4, 0.01])]
    lls = [value(ll(f)) for f in fits]
    for f in fits
        @test f.status != "boundary_score_unresolved"
        @test all(!ismissing, f.boundary)
        @test f.variance_components.sigmas[2] / (sum(f.variance_components.sigmas) + f.variance_components.sigma_e2) < 1e-3
    end
    @test maximum(lls) - minimum(lls) < 1e-3
end
