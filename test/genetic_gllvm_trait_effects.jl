using Test
using LinearAlgebra
using HSquared

@testset "genetic GLLVM trait effects include specific modes" begin
    Λ = [1.0 0.2; 0.5 -0.3; -0.2 0.8]
    ψ = [0.25, 0.36, 0.49]
    F = [0.4 -0.2; -0.3 0.6]
    Dstandard = [0.1 -0.4 0.2; -0.2 0.3 0.5]
    modes = hcat(F, Dstandard)
    expected = F * transpose(Λ) + Dstandard * Diagonal(sqrt.(ψ))
    @test HSquared._gllvm_trait_effects(modes, Λ, ψ) ≈ expected

    Q = [0.0 -1.0; 1.0 0.0]
    rotated = hcat(F * Q, Dstandard)
    @test HSquared._gllvm_trait_effects(rotated, Λ * Q, ψ) ≈ expected
    @test HSquared._gllvm_trait_effects(F, Λ, nothing) ≈ F * transpose(Λ)
    @test_throws DimensionMismatch HSquared._gllvm_trait_effects(F, Λ, ψ)
end

@testset "genetic GLLVM Poisson intercept boundary and count-scale start" begin
    Y = Float64[0 4 1; 0 3 2; 0 5 4; 0 2 1;
                0 6 3; 0 1 5; 0 7 3; 0 0 2]
    Λ = [0.6 0.1; 0.2 0.7; -0.3 0.4]
    Ai = Matrix{Float64}(I, 8, 8)
    @test_throws ArgumentError HSquared.gllvm_laplace_marginal_loglik(
        Y, Ai, Λ, HSquared.PoissonResponse())
    @test_throws ArgumentError HSquared.fit_gllvm_laplace_reml(
        Y, Ai, HSquared.PoissonResponse(); rank = 2, iterations = 2)
    no_intercept = HSquared.gllvm_laplace_marginal_loglik(
        Y, Ai, Λ, HSquared.PoissonResponse(); X = zeros(8, 0))
    @test isfinite(no_intercept.loglik)
    @test_throws ArgumentError HSquared.gllvm_laplace_marginal_loglik(
        Y .+ 1, Ai, Λ, HSquared.PoissonResponse(); X = ones(8, 2))

    high = fill(1000.0, 8, 3)
    result = HSquared.gllvm_laplace_marginal_loglik(
        high, Ai, Λ, HSquared.PoissonResponse())
    @test result.converged
    @test isfinite(result.loglik)
    @test maximum(abs.(result.beta .- log(1000.0))) < 1e-3
end

@testset "genetic GLLVM Poisson T3 K2 ordinary restarts" begin
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = Matrix(pedigree_inverse(ped))
    Y = Float64[2 4 1; 1 3 2; 3 5 4; 0 2 1;
                4 6 3; 2 1 5; 1 7 3; 5 0 2]
    start1 = [0.6 0.1; 0.2 0.7; -0.3 0.4]
    start2 = [0.4 -0.4; -0.5 0.3; 0.2 0.6]
    fits = [HSquared.fit_gllvm_laplace_reml(
        Y, Ainv, HSquared.PoissonResponse(); rank = 2,
        initial = initial, iterations = 300,
    ) for initial in (nothing, start1, start2, 0.1 .* start1)]
    @test all(fit -> fit.converged, fits)
    @test maximum(fit.loglik for fit in fits) - minimum(fit.loglik for fit in fits) < 1e-5
    @test all(fit -> size(breeding_values(fit)) == size(Y), fits)
    @test all(fit -> isfinite(fit.loglik), fits)

    reference = HSquared.gllvm_laplace_marginal_loglik(
        Y, Ainv, start1, HSquared.PoissonResponse())
    trait_order = [3, 1, 2]
    trait_fit = HSquared.gllvm_laplace_marginal_loglik(
        Y[:, trait_order], Ainv, start1[trait_order, :], HSquared.PoissonResponse())
    animal_order = [8, 6, 4, 2, 7, 5, 3, 1]
    animal_fit = HSquared.gllvm_laplace_marginal_loglik(
        Y[animal_order, :], Ainv[animal_order, animal_order], start1,
        HSquared.PoissonResponse())
    Q = [0.0 -1.0; 1.0 0.0]
    rotated = HSquared.gllvm_laplace_marginal_loglik(
        Y, Ainv, start1 * Q, HSquared.PoissonResponse())
    @test reference.converged && trait_fit.converged && animal_fit.converged && rotated.converged
    @test trait_fit.loglik ≈ reference.loglik atol = 1e-8
    @test animal_fit.loglik ≈ reference.loglik atol = 1e-8
    @test rotated.loglik ≈ reference.loglik atol = 1e-8
    @test HSquared._gllvm_trait_effects(rotated.g, start1 * Q, nothing) ≈
        HSquared._gllvm_trait_effects(reference.g, start1, nothing) atol = 1e-8
end

@testset "genetic GLLVM fitted breeding values are trait effects" begin
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = Matrix(pedigree_inverse(ped))
    Y = Float64[2 4; 1 3; 3 5; 0 2; 4 6; 2 1; 1 7; 5 0]
    fit = HSquared.fit_gllvm_laplace_reml(
        Y, Ainv, HSquared.PoissonResponse();
        rank = 1, initial = reshape([0.6, 0.5], 2, 1), iterations = 100,
    )
    @test size(breeding_values(fit)) == size(Y)
    @test breeding_values(fit) == fit.breeding_values

    fit_fa = HSquared.fit_gllvm_laplace_reml(
        Y, Ainv, HSquared.PoissonResponse();
        rank = 1, structure = :factor_analytic,
        initial = reshape([0.6, 0.5], 2, 1),
        initial_uniqueness = [0.2, 0.3], iterations = 100,
    )
    @test size(breeding_values(fit_fa)) == size(Y)
    @test all(isfinite, breeding_values(fit_fa))
    @test fit_fa.uniqueness !== nothing
end
