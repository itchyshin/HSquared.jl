# Part of #409: profile intervals validate the spec once per interval, not once
# per likelihood evaluation. Reference numbers were recorded from main before
# the hoist (same animal-model fit). The data are built from sin/cos rather than
# an RNG, because MersenneTwister streams differ between Julia 1.10 and later
# releases; main gives bit-identical results on 1.10 and 1.12 with this data.
# The hoist moves the variance-component endpoints by at most 3e-10, so 1e-7
# leaves room for BLAS differences across platforms.
using Test, LinearAlgebra, SparseArrays, HSquared

@testset "Issue 409: profile interval hoists spec validation" begin
    nanim = 120
    ids = ["a$i" for i in 1:nanim]
    sire = [i <= 10 ? "0" : "a$(1 + i % 5)" for i in 1:nanim]
    dam = [i <= 10 ? "0" : "a$(6 + i % 5)" for i in 1:nanim]
    ped = normalize_pedigree(ids, sire, dam)
    Ainv = pedigree_inverse(ped)
    a = cholesky(Symmetric(Matrix(Ainv))).L \ [sin(1.3 * i) for i in 1:nanim]
    y = 10 .+ 1.2 .* a .+ [1.4 * cos(2.1 * i + 0.3) for i in 1:nanim]
    spec = animal_model_spec(y, ones(nanim, 1), sparse(1.0I, nanim, nanim), Ainv;
                             ids = ped.ids, method = :REML)
    fit = fit_sparse_reml(spec)
    @test fit.converged

    counter = HSquared._VALIDATED_SPEC_CALLS

    counter[] = 0
    h = heritability_interval(fit; method = :profile)
    h_calls = counter[]
    @test h.heritability ≈ 0.44048273065835036 atol = 1e-7
    @test h.lower ≈ 0.15389657583498323 atol = 1e-7
    @test h.upper ≈ 0.78883205496024766 atol = 1e-7
    @test !h.lower_clamped && !h.upper_clamped
    @test h_calls <= 3

    counter[] = 0
    v = variance_component_interval(fit)
    v_calls = counter[]
    @test v.sigma_a2 ≈ 0.89949124011893655 atol = 1e-7
    @test v.lower ≈ 0.27537247811364074 atol = 1e-7
    @test v.upper ≈ 2.2347502461349471 atol = 1e-7
    @test !v.lower_clamped && !v.upper_clamped
    @test v_calls <= 3
end
