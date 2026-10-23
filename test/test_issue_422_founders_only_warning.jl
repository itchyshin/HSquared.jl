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
end
