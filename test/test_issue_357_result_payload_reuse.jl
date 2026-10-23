using HSquared
using LinearAlgebra
using SparseArrays
using Test

@testset "issue 357 result_payload solves the Henderson MME once" begin
    y = [1.0, 2.0, 3.0]
    X = ones(3, 1)
    Z = sparse(I, 3, 3)
    Ainv = sparse(I, 3, 3)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ["a", "b", "c"], method = :ML)
    likelihood = gaussian_loglik(spec, 1.0, 1.0; method = :ML)
    fit = AnimalModelFit(
        spec,
        likelihood,
        (sigma_a2 = 1.0, sigma_e2 = 1.0),
        true,
        "test",
        0,
    )
    vc = variance_components(fit)
    mme = henderson_mme(fit.spec, vc.sigma_a2, vc.sigma_e2)
    payload = result_payload(fit)

    @test payload.fixed_effects ≈ fixed_effects(fit)
    @test payload.breeding_values.ids == breeding_values(mme).ids
    @test payload.breeding_values.values ≈ breeding_values(mme).values atol = 0
    @test payload.predictions ≈ fitted_values(mme) atol = 0
    @test payload.breeding_values.values ≈ breeding_values(fit).values atol = 0
    @test payload.predictions ≈ fitted_values(fit) atol = 0
    @test payload.random_effects.animal.values ≈ payload.breeding_values.values atol = 0
end
