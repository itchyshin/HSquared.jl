using Test
using LinearAlgebra
using HSquared

# #50 owner decision (25 Oct 2026): export the genetic-GLLVM fitter, fit object and
# result payload, labelled partial and experimental, for the R lane bridge.
@testset "#50 genetic-GLLVM fitter, fit object and result payload are exported" begin
    for name in (:fit_gllvm_laplace_reml, :GeneticGLLVMFit, :genetic_gllvm_result_payload)
        @test name in names(HSquared)
    end

    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = Matrix(pedigree_inverse(ped))
    Y = hcat(Float64[2, 1, 3, 0, 4, 2, 1, 5],
             Float64[2.1, 3.4, 2.8, 3.1, 4.2, 1.9, 3.0, 4.7])
    families = [HSquared.PoissonResponse(), HSquared.GaussianResponse(1.0)]
    fit = fit_gllvm_laplace_reml(Y, Ainv, families; rank = 1,
                                 initial = reshape([0.6, 0.5], 2, 1),
                                 trait_names = ["count", "size"])
    @test fit isa GeneticGLLVMFit

    p = genetic_gllvm_result_payload(fit)
    @test p.engine == "HSquared.jl"
    @test p.target == "genetic_gllvm_laplace"
    @test p.families == ["poisson", "gaussian"]
    @test p.marginal == "laplace"
    @test p.status == "partial"
    @test p.experimental === true
    @test p.scale == "latent"
    @test p.trait_names == ["count", "size"]
    @test p.n_latent_factors == 1
    @test p.loglik == fit.loglik
    @test p.converged == fit.converged
    @test p.fixed_effects == fit.beta
    @test p.breeding_values.values == fit.breeding_values
    @test p.latent_structure.genetic_covariance == fit.genetic_covariance
    @test haskey(p.latent_structure, :communality)

    # Rotation-invariant functionals only: no raw loadings, no heritability.
    @test !haskey(p, :loadings)
    @test !haskey(p.latent_structure, :loadings)
    @test !haskey(p, :heritability)

    # Value-preserving: the payload copies, it does not alias the fit's arrays.
    p.fixed_effects[1] = 99.0
    @test fit.beta[1] != 99.0

    # A scalar family is reported once per trait.
    fit_s = fit_gllvm_laplace_reml(Float64[2 4; 1 3; 3 5; 0 2; 4 6; 2 1; 1 7; 5 0],
                                   Ainv, HSquared.PoissonResponse(); rank = 1,
                                   initial = reshape([0.6, 0.5], 2, 1))
    ps = genetic_gllvm_result_payload(fit_s)
    @test ps.families == ["poisson", "poisson"]
    @test ps.trait_names === nothing
end
