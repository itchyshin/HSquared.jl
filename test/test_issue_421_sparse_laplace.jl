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

# The variational path had the same densifications plus a dense q x q inverse S
# at every covariance fixed-point step. `_variational_marginal_loglik_dense` is
# the retained dense reference.
@testset "issue 421: sparse variational matches the dense reference" begin
    fx = _issue421_fixture(300, 450; seed = 421)
    σ2 = 0.4
    X0 = zeros(450, 0)
    ybinom = min.(fx.ybin .+ Float64.(fx.ypois .> 1), 2.0)
    cases = [
        ("bernoulli", fx.ybin, HSquared.BernoulliResponse()),
        ("poisson", fx.ypois, HSquared.PoissonResponse()),
        ("binomial", ybinom, HSquared.BinomialResponse(2)),
        ("gaussian", fx.ypois, HSquared.GaussianResponse(0.7)),
    ]
    for (name, y, fam) in cases, X in (fx.X, X0), cov in (:full, :diagonal)
        dense = HSquared._variational_marginal_loglik_dense(y, X, Matrix(fx.Z), Matrix(fx.Ainv), σ2, fam;
                                                             covariance = cov)
        sp = HSquared.variational_marginal_loglik(y, X, fx.Z, fx.Ainv, σ2, fam; covariance = cov)
        @testset "$name p=$(size(X, 2)) $cov" begin
            @test dense.converged
            @test sp.converged
            @test isapprox(sp.elbo, dense.elbo; atol = 1e-9, rtol = 0)
            @test isapprox(sp.m, dense.m; atol = 1e-7)
            @test isapprox(sp.beta, dense.beta; atol = 1e-7)
            @test isapprox(Matrix(sp.S), Matrix(dense.S); atol = 1e-9)
            @test sp.objective === dense.objective
            @test sp.is_lower_bound === dense.is_lower_bound
            @test sp.covariance_iterations == dense.covariance_iterations
        end
    end
    # Dense inputs still work and agree with sparse inputs.
    a = HSquared.variational_marginal_loglik(fx.ybin, fx.X, Matrix(fx.Z), Matrix(fx.Ainv), σ2,
                                             HSquared.BernoulliResponse())
    b = HSquared.variational_marginal_loglik(fx.ybin, fx.X, fx.Z, fx.Ainv, σ2,
                                             HSquared.BernoulliResponse())
    @test isapprox(a.elbo, b.elbo; atol = 1e-9, rtol = 0)
end

@testset "issue 421: fitted variational path does not densify at q = n = 2000" begin
    q = 2000
    fx = _issue421_fixture(q, q; seed = 4210)
    fam = HSquared.BernoulliResponse()
    small = _issue421_fixture(300, 300; seed = 4211)
    HSquared.variational_marginal_loglik(small.ybin, small.X, small.Z, small.Ainv, 0.4, fam)  # warm-up
    HSquared._variational_marginal_loglik_sparse(small.ybin, small.X, small.Z, small.Ainv, 0.4, fam;
                                                 dense_covariance = false)
    # Bytes here are total churn over all outer and covariance fixed-point steps.
    # Each selected-inverse pass allocates O(nnz(L)) (about 6 MB at this size), so
    # the sparse total is about 60 q^2 bytes; the dense path allocated several
    # 8q^2 arrays per pass (Z, Z'WZ, S, Z*S), i.e. thousands of q^2 bytes. The
    # public function also keeps its dense S field (one q x q inverse at the end);
    # the fitter's route returns no dense S at all.
    pub = @timed HSquared.variational_marginal_loglik(fx.ybin, fx.X, fx.Z, fx.Ainv, 0.4, fam)
    @test pub.value.converged
    @test size(pub.value.S) == (q, q)
    @test pub.bytes < 150 * q^2
    fitpath = @timed HSquared._variational_marginal_loglik_sparse(fx.ybin, fx.X, fx.Z, fx.Ainv, 0.4, fam;
                                                                  dense_covariance = false)
    @test fitpath.value.converged
    @test fitpath.value.S === nothing
    @test isapprox(fitpath.value.elbo, pub.value.elbo; atol = 1e-10, rtol = 0)
    @test fitpath.bytes < 100 * q^2
    @test fitpath.time < 10.0
end

@testset "issue 421: fit_laplace_reml variational agrees for sparse and dense inputs" begin
    fx = _issue421_fixture(120, 200; seed = 4212)
    a = fit_laplace_reml(fx.ybin, fx.X, fx.Z, fx.Ainv; family = :bernoulli, marginal = :variational)
    b = fit_laplace_reml(fx.ybin, fx.X, Matrix(fx.Z), Matrix(fx.Ainv); family = :bernoulli,
                         marginal = :variational)
    @test a.converged
    # Same objective; sigma_a2 agrees to Brent's stopping tolerance, not to 1e-10.
    @test isapprox(a.variance_components.sigma_a2, b.variance_components.sigma_a2; rtol = 1e-6)
    @test isapprox(a.marginal_loglik, b.marginal_loglik; atol = 1e-9, rtol = 0)
end
