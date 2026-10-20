# HSquared.jl #422 -- no SE / interval for the non-identified A = I design.
# Standalone:
# julia --project=. -e 'include("test/test_issue_422_founders_only_uncertainty.jl")'

using HSquared
using LinearAlgebra
using SparseArrays
using Test

@testset "issue 422 founders-only uncertainty is refused, not absurd" begin
    n = 30
    ids = string.(1:n)
    ped = normalize_pedigree(ids, fill("0", n), fill("0", n))
    Ainv = pedigree_inverse(ped)
    y = [1.622, 3.04, 1.928, 1.91, 0.916, 2.399, 1.219, 0.641, 1.14, 2.198,
         2.954, 2.712, 2.797, 1.513, 1.487, 4.829, 3.032, 2.472, 2.986, 4.373,
         1.927, 0.055, 3.354, 1.418, 2.145, 2.403, 1.675, 2.589, 0.944, 2.258]
    X = hcat(ones(n), Float64.(repeat([0, 1], n ÷ 2)))
    Z = sparse(1.0I, n, n)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    fit = @test_logs (:warn, r"not separately identifiable") begin
        fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    end

    for f in (variance_component_covariance, variance_component_standard_errors,
              heritability_standard_error, heritability_interval,
              variance_component_interval)
        err = try f(fit); nothing catch e; e end
        @test err isa ArgumentError
        @test err isa ArgumentError && occursin("not separately identifiable", err.msg)
    end
    @test_throws ArgumentError heritability_interval(fit; method = :profile)

    # An identified design (related animals) is unaffected.
    related = normalize_pedigree(
        string.(1:8),
        ["0", "0", "1", "1", "2", "2", "3", "5"],
        ["0", "0", "2", "2", "0", "0", "4", "6"],
    )
    @test !HSquared._animal_residual_split_unidentifiable(
        sparse(1.0I, 8, 8), pedigree_inverse(related))
end
