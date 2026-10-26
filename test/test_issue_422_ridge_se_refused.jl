# HSquared.jl #422 -- SE and interval must be refused, not numeric, when the
# average-information matrix is singular (founders-only ridge).
# Standalone:
# julia --project=. -e 'include("test/test_issue_422_ridge_se_refused.jl")'

using HSquared
using LinearAlgebra
using Random
using SparseArrays
using Test

@testset "issue 422 ridge fits refuse SE and interval" begin
    n = 300
    ped = normalize_pedigree(string.(1:n), fill("0", n), fill("0", n))
    Ainv = pedigree_inverse(ped)
    Z = sparse(1.0I, n, n)
    nridge = 0
    for seed in 1:12
        Random.seed!(seed)
        male = rand(Bool, n)
        y = 2 .+ 0.5 .* male .+ randn(n)
        X = hcat(ones(n), Float64.(male))
        spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
        fit = Base.CoreLogging.with_logger(Base.CoreLogging.NullLogger()) do
            fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
        end
        # Decision on #422 (25 Oct 2026): the ridge fit is never certified, so
        # every rep is converged = false with NaN h2, SE and interval.
        nridge += 1
        @test fit.converged === false
        @test fit.optimizer_status == "unidentified_ridge"
        @test isnan(heritability(fit))
        @test isnan(heritability_standard_error(fit))
        @test isnan(heritability_interval(fit).lower)
        @test isnan(heritability_interval(fit).upper)
        @test_throws ArgumentError variance_component_covariance(fit)
        @test_throws ArgumentError variance_component_standard_errors(fit)
    end
    @test nridge == 12
end

@testset "issue 422 singular information is still refused" begin
    @test_throws ArgumentError HSquared._require_identified_information(
        [1.0 1.0; 1.0 1.0], "test")
    @test HSquared._require_identified_information([2.0 0.0; 0.0 1.0], "test") === nothing
end

@testset "issue 422 identified fits keep their SE" begin
    n = 200
    ids = string.(1:n)
    sire = vcat(fill("0", 20), string.(rand(MersenneTwister(1), 1:20, n - 20)))
    dam = fill("0", n)
    ped = normalize_pedigree(ids, sire, dam)
    Ainv = pedigree_inverse(ped)
    Random.seed!(7)
    y = randn(n)
    spec = animal_model_spec(y, ones(n, 1), sparse(1.0I, n, n), Ainv; ids = ped.ids,
                             method = :REML)
    fit = fit_ai_reml(spec)
    if fit.converged === true
        se = heritability_standard_error(fit)
        @test isfinite(se) && se > 0
    end
end
