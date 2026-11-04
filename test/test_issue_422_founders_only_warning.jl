# HSquared.jl #422 — warn when A = I and each animal has one record.
# Standalone:
# julia --project=. -e 'include("test/test_issue_422_founders_only_warning.jl")'

using HSquared
using LinearAlgebra
using Logging
using SparseArrays
using Test

@testset "issue 422 founders-only animal/residual split is warned" begin
    help = read(joinpath(@__DIR__, "..", "src", "likelihood.jl"), String)
    @test occursin("founders-only pedigree (`A = I`)", help)
    @test occursin("ridge in `σ²a + σ²e`", help)
    @test occursin("HSquared.jl #422", help)
    @test occursin("_ANIMAL_RESIDUAL_UNIDENTIFIABLE_MSG", help)
    @test occursin("not separately identifiable", HSquared._ANIMAL_RESIDUAL_UNIDENTIFIABLE_MSG)

    n = 8
    ids = string.(1:n)
    ped = normalize_pedigree(ids, fill("0", n), fill("0", n))
    Ainv = pedigree_inverse(ped)
    Z = sparse(1.0I, n, n)
    X = ones(n, 1)
    y = [1.6, 3.0, 1.9, 1.9, 0.9, 2.4, 1.2, 0.6]
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)

    @test HSquared._is_identity_precision(Ainv)
    @test HSquared._single_record_incidence(Z)
    @test HSquared._animal_residual_split_unidentifiable(Z, Ainv)

    @test_logs (:warn, r"not separately identifiable") min_level = Logging.Warn begin
        fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0), iterations = 2)
    end

    # Decision on #422 (25 Oct 2026): the ridge fit is not certified. converged is
    # false, h2 and its standard error and interval are NaN, and a reason is given.
    ridge = with_logger(NullLogger()) do
        fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0), iterations = 100)
    end
    @test ridge.converged == false
    @test ridge.optimizer_status == "unidentified_ridge"
    @test isnan(heritability(ridge))
    @test isnan(heritability_standard_error(ridge))
    for method in (:delta, :profile)
        iv = heritability_interval(ridge; method = method)
        @test isnan(iv.heritability) && isnan(iv.lower) && isnan(iv.upper)
        @test occursin("not separately identifiable", iv.reason)
        @test iv.method == method
    end
    @test isnan(heritability_interval(ridge).se)
    # The identified total Va + Ve is still reported.
    @test ridge.variance_components.sigma_a2 > 0 && ridge.variance_components.sigma_e2 > 0

    Zrep = sparse(1:n, repeat(1:(n ÷ 2), inner = 2), 1.0, n, n ÷ 2)
    Arep = sparse(1.0I, n ÷ 2, n ÷ 2)
    @test HSquared._is_identity_precision(Arep)
    @test !HSquared._single_record_incidence(Zrep)
    @test !HSquared._animal_residual_split_unidentifiable(Zrep, Arep)

    related = normalize_pedigree(
        ids,
        ["0", "0", "1", "1", "2", "2", "3", "5"],
        ["0", "0", "2", "2", "0", "0", "4", "6"],
    )
    Q = pedigree_inverse(related)
    @test !HSquared._is_identity_precision(Q)
    @test !HSquared._animal_residual_split_unidentifiable(Z, Q)

    # Replicated records identify the split even with A = I: no override.
    yrep = [1.6, 3.0, 1.9, 1.9, 0.9, 2.4, 1.2, 0.6]
    sprep = animal_model_spec(yrep, ones(n, 1), Zrep, Arep; ids = string.(1:(n ÷ 2)), method = :REML)
    frep = fit_ai_reml(sprep; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0), iterations = 200)
    @test frep.optimizer_status != "unidentified_ridge"
    @test !isnan(heritability(frep))
end
