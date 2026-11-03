# test_issue_415_two_effect_sparse_route.jl: Part of #415.
#
# Defect: the payload-v2 `:two_effect` arm only runs the dense `fit_two_effect_reml`
# (NelderMead, dense n x n covariance per evaluation) and `_reject_unsupported_fit_kwargs`
# rejects `scale_method`. On a 6547-animal pedigree that took ~1900 s against ~1.3 s for a
# sparse reference. The `:multi_effect` arm already honours `scale_method = :auto` through
# `fit_multi_effect` (sparse AI-REML). This file pins the same opt-in for `:two_effect`.
#
# Red on main: the `scale_method = :auto` calls throw the unsupported-kwarg ArgumentError.
# The default route (scale_method absent or :dense) is not changed.

using HSquared
using Test
using LinearAlgebra
using SparseArrays
using Random
using Statistics

function _issue415_payload(; n_animals::Integer, n_herds::Integer, seed::Integer)
    rng = MersenneTwister(seed)
    n_founders = max(20, n_animals ÷ 6)
    ids = collect(1:n_animals)
    sire = zeros(Int, n_animals)
    dam = zeros(Int, n_animals)
    a = zeros(n_animals)
    for i in 1:n_animals
        if i <= n_founders
            a[i] = sqrt(2.0) * randn(rng)
        else
            s = rand(rng, 1:(i - 1))
            d = rand(rng, 1:(i - 1))
            while d == s
                d = rand(rng, 1:(i - 1))
            end
            sire[i] = s
            dam[i] = d
            a[i] = 0.5 * (a[s] + a[d]) + sqrt(2.0 * 0.5) * randn(rng)
        end
    end
    herd = rand(rng, 1:n_herds, n_animals)
    h = sqrt(1.5) .* randn(rng, n_herds)
    y = 5.0 .+ a .+ h[herd] .+ sqrt(3.0) .* randn(rng, n_animals)
    y = (y .- mean(y)) ./ std(y)   # unit variance: keep the #413 unit-scale start out of play
    Zanimal = Matrix{Float64}(I, n_animals, n_animals)
    Zherd = zeros(n_animals, n_herds)
    for r in 1:n_animals
        Zherd[r, herd[r]] = 1.0
    end
    payload = Dict(
        "payload_version" => 2,
        "y" => y,
        "X" => ones(n_animals, 1),
        "random_effects" => [
            Dict("name" => "animal", "type" => "pedigree", "Z" => Zanimal,
                 "relmat_status" => "build_in_julia",
                 "pedigree" => Dict("id" => ids, "sire" => sire, "dam" => dam),
                 "ids" => ids),
            Dict("name" => "herd", "type" => "iid", "Z" => Zherd,
                 "relmat_status" => "identity", "ids" => collect(1:n_herds)),
        ],
    )
    return payload, (y = y, Z1 = Zanimal, Z2 = Zherd, ids = ids,
                     Ainv = Matrix(pedigree_inverse(ids, sire, dam)), n_herds = n_herds)
end

@testset "#415 :two_effect honours scale_method = :auto (sparse route)" begin
    payload, raw = _issue415_payload(n_animals = 300, n_herds = 40, seed = 20261004)
    X = ones(length(raw.y), 1)
    I40 = Matrix{Float64}(I, raw.n_herds, raw.n_herds)

    dense_direct = fit_two_effect_reml(raw.y, X, raw.Z1, raw.Ainv, raw.Z2, I40;
                                       ids1 = raw.ids, ids2 = collect(1:raw.n_herds))

    @testset "default call unchanged (absent and :dense)" begin
        d0 = fit_payload_v2(payload)
        d1 = fit_payload_v2(payload; scale_method = :dense)
        for f in (d0, d1)
            @test f.variance_components == dense_direct.variance_components
            @test f.loglik == dense_direct.loglik
            @test f.converged == dense_direct.converged
            @test keys(f) == keys(dense_direct)
        end
    end

    @testset "sparse route agrees with the dense two-effect fit" begin
        fit = fit_payload_v2(payload; scale_method = :auto)
        vc, vd = fit.variance_components, dense_direct.variance_components
        @test keys(vc) == keys(vd)
        @test fit.converged
        @test isapprox(vc.sigma1, vd.sigma1; rtol = 1e-4)
        @test isapprox(vc.sigma2, vd.sigma2; rtol = 1e-4)
        @test isapprox(vc.sigma_e2, vd.sigma_e2; rtol = 1e-4)
        @test isapprox(fit.ratio1, dense_direct.ratio1; rtol = 1e-4)
        @test isapprox(fit.ratio2, dense_direct.ratio2; rtol = 1e-4)
        @test isapprox(comparable_loglik(fit), comparable_loglik(dense_direct); atol = 1e-6)
        @test fit.effect1.ids == raw.ids
        @test fit.effect2.ids == collect(1:raw.n_herds)
        @test length(fit.effect1.values) == length(raw.ids)
        @test length(fit.boundary) == 2

        res = result_payload_v2(fit, parse_payload_v2(payload))
        @test res.variance_components.blocks[1].variance == vc.sigma1
        @test res.variance_components.blocks[2].variance == vc.sigma2
        @test res.variance_components.residual == vc.sigma_e2
        @test res.converged
    end

    @testset "initial and iterations are forwarded on the opt-in route" begin
        f = fit_payload_v2(payload; scale_method = :auto, iterations = 1)
        @test !f.converged
        @test_throws ArgumentError fit_payload_v2(payload; initial = [1.0, 1.0, 1.0])
        @test_throws ArgumentError fit_payload_v2(payload; scale_method = :bogus)
    end

    @testset "variance_component_standard_errors on the routed fit" begin
        fit = fit_payload_v2(payload; scale_method = :auto)
        effects = [(sparse(raw.Z1), sparse(raw.Ainv)), (sparse(raw.Z2), sparse(I40))]
        vc = fit.variance_components
        se = multi_effect_variance_component_standard_errors(
            raw.y, X, effects, [vc.sigma1, vc.sigma2], vc.sigma_e2)
        @test all(isfinite, se.sigmas) && all(>(0), se.sigmas)
        @test isfinite(se.sigma_e2) && se.sigma_e2 > 0
    end
end

@testset "#415 wall-time guard: sparse :two_effect at n = 2000" begin
    payload, _ = _issue415_payload(n_animals = 2000, n_herds = 100, seed = 20261005)
    fit_payload_v2(payload; scale_method = :auto)   # warm up compilation
    elapsed = @elapsed fit = fit_payload_v2(payload; scale_method = :auto)
    @test fit.converged
    @test elapsed < 10.0
end
