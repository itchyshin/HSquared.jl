using HSquared
using LinearAlgebra
using SparseArrays
using Test

@testset "heritability profile intervals report search-rail clamps (#428)" begin
    ids = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    ped = normalize_pedigree(
        ids,
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"],
    )
    spec = animal_model_spec(
        [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5],
        ones(8, 1),
        sparse(1.0I, 8, 8),
        pedigree_inverse(ped);
        ids = ped.ids,
        method = :REML,
    )
    fit = fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))

    profile = heritability_interval(fit; method = :profile)
    @test profile.lower ≈ 1e-6 atol = 1e-9
    @test profile.upper ≈ 1 - 1e-6 atol = 1e-9
    @test profile.lower_clamped
    @test profile.upper_clamped

    delta = heritability_interval(fit; method = :delta)
    @test delta.lower_clamped == (delta.lower <= 1e-6)
    @test delta.upper_clamped == (delta.upper >= 1 - 1e-6)
end
