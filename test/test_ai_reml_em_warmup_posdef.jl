using HSquared
using LinearAlgebra
using SparseArrays
using Test

@testset "AI-REML EM warmup handles non-PD systems" begin
    ped = normalize_pedigree(
        ["offspring", "parent_a", "parent_b"],
        ["parent_a", "0", "0"],
        ["parent_b", "0", "0"],
    )
    spec = animal_model_spec(
        [1.0, 2.0, 3.0],
        [1.0 0.0; 1.0 1.0; 1.0 2.0],
        sparse(I, 3, 3),
        pedigree_inverse(ped);
        ids = ped.ids,
        method = "REML",
    )

    result = HSquared._fit_ai_reml_diagnostics(
        spec;
        initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
        iterations = 100,
        em_warmup = 5,
    )
    fit = result.fit

    @test !fit.converged
    @test fit.optimizer_status == "non_positive_definite"
    @test result.diagnostics.termination_reason == "non_positive_definite"
    @test 1 <= result.diagnostics.em_steps <= 5
    @test all(isfinite, values(fit.variance_components))
    @test all(>(0), values(fit.variance_components))
    @test isfinite(fit.likelihood.loglik)
end
