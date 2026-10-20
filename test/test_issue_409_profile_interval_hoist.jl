# Part of #409: profile intervals validate the spec once per interval, not once
# per likelihood evaluation. Reference numbers were recorded from main before
# the hoist (same simulated animal-model fit).
using Test, LinearAlgebra, SparseArrays, Random, HSquared

@testset "Issue 409: profile interval hoists spec validation" begin
    rng = MersenneTwister(409)
    nanim = 120
    ids = ["a$i" for i in 1:nanim]
    sire = [i <= 10 ? "0" : "a$(rand(rng, 1:5))" for i in 1:nanim]
    dam = [i <= 10 ? "0" : "a$(rand(rng, 6:10))" for i in 1:nanim]
    ped = normalize_pedigree(ids, sire, dam)
    Ainv = pedigree_inverse(ped)
    a = cholesky(Symmetric(Matrix(Ainv))).L \ randn(rng, nanim)
    y = 10 .+ 1.2 .* a .+ randn(rng, nanim)
    spec = animal_model_spec(y, ones(nanim, 1), sparse(1.0I, nanim, nanim), Ainv;
                             ids = ped.ids, method = :REML)
    fit = fit_sparse_reml(spec)
    @test fit.converged

    counter = HSquared._VALIDATED_SPEC_CALLS

    counter[] = 0
    h = heritability_interval(fit; method = :profile)
    h_calls = counter[]
    @test h.heritability ≈ 0.23777997548336954 atol = 1e-8
    @test h.lower ≈ 0.02298703886185304 atol = 1e-8
    @test h.upper ≈ 0.6178169650011641 atol = 1e-8
    @test !h.lower_clamped && !h.upper_clamped
    @test h_calls <= 3

    counter[] = 0
    v = variance_component_interval(fit)
    v_calls = counter[]
    @test v.sigma_a2 ≈ 0.464737709893309 atol = 1e-8
    @test v.lower ≈ 0.04325313321613321 atol = 1e-8
    @test v.upper ≈ 1.587478922859485 atol = 1e-8
    @test !v.lower_clamped && !v.upper_clamped
    @test v_calls <= 3
end
