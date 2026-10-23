# Issue #421: the non-Gaussian Laplace marginal must keep Z, Ainv and the joint
# Hessian sparse. `_laplace_marginal_loglik_dense` is the retained dense reference.
using Random
using SparseArrays
using LinearAlgebra
using Test

function _issue421_fixture(q::Int, n::Int; seed::Int, nfounders::Int = 30)
    rng = MersenneTwister(seed)
    sire = fill("0", q)
    dam = fill("0", q)
    for i in (nfounders + 1):q
        a = rand(rng, 1:(i - 1))
        b = rand(rng, 1:(i - 1))
        while b == a
            b = rand(rng, 1:(i - 1))
        end
        sire[i] = string(a)
        dam[i] = string(b)
    end
    ped = HSquared.normalize_pedigree(string.(1:q), sire, dam)
    Ainv = HSquared.pedigree_inverse(ped)
    rec = vcat(collect(1:q), rand(rng, 1:q, n - q))
    Z = sparse(1:n, rec, 1.0, n, q)
    X = ones(n, 1)
    u = 0.6 .* randn(rng, q)
    η = 0.2 .+ Z * u
    ybin = Float64[rand(rng) < 1 / (1 + exp(-e)) for e in η]
    ypois = Float64[_issue421_poisson(rng, exp(e)) for e in η]
    return (; Ainv, Z, X, ybin, ypois)
end

function _issue421_poisson(rng, λ)
    L = exp(-λ)
    k = 0
    p = 1.0
    while true
        p *= rand(rng)
        p <= L && return k
        k += 1
    end
end

@testset "issue 421: sparse Laplace matches the dense reference" begin
    fx = _issue421_fixture(300, 450; seed = 421)
    σ2 = 0.4
    cases = [
        ("bernoulli", fx.ybin, HSquared.BernoulliResponse()),
        ("poisson", fx.ypois, HSquared.PoissonResponse()),
        ("binomial", min.(fx.ybin .+ Float64.(fx.ypois .> 1), 2.0), HSquared.BinomialResponse(2)),
    ]
    for (name, y, fam) in cases
        dense = HSquared._laplace_marginal_loglik_dense(y, fx.X, Matrix(fx.Z), Matrix(fx.Ainv), σ2, fam)
        sp = HSquared.laplace_marginal_loglik(y, fx.X, fx.Z, fx.Ainv, σ2, fam)
        @testset "$name" begin
            @test dense.converged
            @test sp.converged
            @test isapprox(sp.loglik, dense.loglik; atol = 1e-9, rtol = 0)
            @test isapprox(sp.u, dense.u; atol = 1e-7)
            @test isapprox(sp.beta, dense.beta; atol = 1e-7)
        end
    end
    # Dense inputs still work and agree with sparse inputs.
    y = fx.ybin
    fam = HSquared.BernoulliResponse()
    a = HSquared.laplace_marginal_loglik(y, fx.X, Matrix(fx.Z), Matrix(fx.Ainv), σ2, fam)
    b = HSquared.laplace_marginal_loglik(y, fx.X, fx.Z, fx.Ainv, σ2, fam)
    @test isapprox(a.loglik, b.loglik; atol = 1e-9, rtol = 0)
end

@testset "issue 421: sparse Laplace does not densify at q = n = 2000" begin
    q = 2000
    fx = _issue421_fixture(q, q; seed = 4210)
    fam = HSquared.BernoulliResponse()
    HSquared.laplace_marginal_loglik(fx.ybin[1:300], fx.X[1:300, :], fx.Z[1:300, 1:300],
                                     HSquared.pedigree_inverse(HSquared.normalize_pedigree(
                                         string.(1:300), fill("0", 300), fill("0", 300))),
                                     0.4, fam)  # compile warm-up on a tiny problem
    stats = @timed HSquared.laplace_marginal_loglik(fx.ybin, fx.X, fx.Z, fx.Ainv, 0.4, fam)
    @test stats.value.converged
    @test isfinite(stats.value.loglik)
    # Any dense q x q array costs 8q^2 bytes and the dense path builds several per
    # Newton step (about 1 GB at this size), so staying below 8q^2 in total rules
    # out densifying Z, Ainv or H. The sparse Cholesky factor of a random-mating
    # pedigree is itself ~150k entries, so a 5%-of-8q^2 bound is not attainable.
    @test stats.bytes < 8 * q^2
    @test stats.time < 5.0
end
