# HSquared.jl #422 -- no SE or interval from an unidentified animal/residual split.
# Standalone:
# julia --project=. -e 'include("test/test_issue_422_se_guard.jl")'

using HSquared
using LinearAlgebra
using Random
using SparseArrays
using Test

@testset "issue 422 SE and interval refuse a non-identified ridge" begin
    n = 300
    ids = string.(1:n)
    ped = normalize_pedigree(ids, fill("0", n), fill("0", n))
    Ainv = pedigree_inverse(ped)
    X = hcat(ones(n), Float64.(repeat([0, 1], n ÷ 2)))
    Z = sparse(1.0I, n, n)
    # seed 11 gave h2 SE exactly 0.0 (indefinite inverse clipped by max(0, .))
    Random.seed!(11)
    y = 2 .+ randn(n)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    fit = Base.CoreLogging.with_logger(Base.CoreLogging.NullLogger()) do
        fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
                    iterations = 100, em_warmup = 0)
    end
    @test fit.converged
    @test_throws ArgumentError variance_component_covariance(fit)
    @test_throws ArgumentError variance_component_standard_errors(fit)
    @test_throws ArgumentError heritability_standard_error(fit)
    @test_throws ArgumentError heritability_interval(fit)
end

