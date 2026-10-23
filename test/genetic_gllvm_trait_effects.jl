using Test
using LinearAlgebra
using HSquared

struct SmoothNonconcaveGLLVMTestFamily <: HSquared.ResponseFamily end
HSquared._fam_loglik(::SmoothNonconcaveGLLVMTestFamily, y, η) =
    y * η - η^2 / 2 + 4η^2 * (η - 1)^2 * exp(-η^2)
HSquared._fam_score(::SmoothNonconcaveGLLVMTestFamily, y, η) =
    y - η + 4exp(-η^2) *
        (4η^3 - 6η^2 + 2η - 2η * (η^4 - 2η^3 + η^2))
HSquared._fam_weight(::SmoothNonconcaveGLLVMTestFamily, y, η) = 1.0
HSquared._fam_observed_weight(::SmoothNonconcaveGLLVMTestFamily, y, η) =
    1 - exp(-η^2) *
        (16η^6 - 32η^5 - 56η^4 + 112η^3 + 8η^2 - 48η + 8)

struct NonfiniteCurvatureGLLVMTestFamily <: HSquared.ResponseFamily end
HSquared._fam_loglik(::NonfiniteCurvatureGLLVMTestFamily, y, η) = y * η - η^2 / 2
HSquared._fam_score(::NonfiniteCurvatureGLLVMTestFamily, y, η) = y - η
HSquared._fam_weight(::NonfiniteCurvatureGLLVMTestFamily, y, η) = 1.0
HSquared._fam_observed_weight(::NonfiniteCurvatureGLLVMTestFamily, y, η) = NaN

struct SingularWorkingGLLVMTestFamily <: HSquared.ResponseFamily end
HSquared._fam_loglik(::SingularWorkingGLLVMTestFamily, y, η) = y * η
HSquared._fam_score(::SingularWorkingGLLVMTestFamily, y, η) = y
HSquared._fam_weight(::SingularWorkingGLLVMTestFamily, y, η) = 0.0
HSquared._fam_observed_weight(::SingularWorkingGLLVMTestFamily, y, η) = 0.0

@testset "genetic GLLVM handles inner convergence before Laplace curvature" begin
    Y = reshape([2.0], 1, 1)
    Ainv = ones(1, 1)
    Λ = ones(1, 1)
    family = SmoothNonconcaveGLLVMTestFamily()

    # At the initial mode the score is nonzero and the observed joint curvature
    # is negative. A capped solve should report nonconvergence without factoring it.
    capped = HSquared.gllvm_laplace_marginal_loglik(
        Y, Ainv, Λ, family; X = zeros(1, 0), maxiter = 0,
    )
    @test !capped.converged
    @test isnan(capped.loglik)
    @test capped.stop_reason == :maxiter

    # One Fisher-scoring step reaches a stationary point with an invalid observed
    # Laplace Hessian. That is a classified parameter failure, not a Cholesky leak.
    @test_throws HSquared.GLLVMInvalidLaplaceCurvatureError HSquared.gllvm_laplace_marginal_loglik(
        Y, Ainv, Λ, family; X = zeros(1, 0), maxiter = 1,
    )

    nonfinite_family = NonfiniteCurvatureGLLVMTestFamily()
    @test_throws HSquared.GLLVMInvalidParameterEvaluationError HSquared.fit_gllvm_laplace_reml(
        Y, Ainv, nonfinite_family; rank = 1, X = zeros(1, 0),
        initial = Λ, iterations = 2,
    )
    @test_throws HSquared.GLLVMInvalidParameterEvaluationError HSquared.fit_gllvm_laplace_reml(
        Y, Ainv, family; rank = 1, X = zeros(1, 0),
        initial = Λ, iterations = 2, maxiter = 0,
    )
    @test_throws HSquared.GLLVMInvalidParameterEvaluationError HSquared.gllvm_laplace_marginal_loglik(
        Y, Ainv, Λ, SingularWorkingGLLVMTestFamily(); X = ones(1, 1), maxiter = 1,
    )
    @test_throws ArgumentError HSquared.fit_gllvm_laplace_reml(
        Y, zeros(1, 1), family; rank = 1, X = zeros(1, 0),
        initial = Λ, iterations = 2,
    )
end

@testset "genetic GLLVM Gaussian one-step mode convergence" begin
    Y = Float64[1 2; 2 1; 3 4; 4 3]
    Ainv = Matrix{Float64}(I, size(Y, 1), size(Y, 1))
    Λ = [0.7; -0.4;;]
    result = HSquared.gllvm_laplace_marginal_loglik(
        Y, Ainv, Λ, HSquared.GaussianResponse(1.0); maxiter = 1,
    )
    reference = HSquared._multivariate_reml_loglik(
        Y, ones(size(Y, 1), 1), Matrix{Float64}(I, size(Y, 1), size(Y, 1)),
        Ainv, Λ * transpose(Λ), Matrix{Float64}(I, 2, 2),
    )
    @test result.converged
    @test isfinite(result.loglik)
    @test result.gradient_norm < 1e-10
    @test result.stop_reason == :converged
    @test result.loglik ≈ reference atol = 1e-8
end

@testset "genetic GLLVM Gaussian reduction with multi-column fixed effects" begin
    ped = normalize_pedigree(
        ["a1", "a2", "a3", "a4", "a5", "a6"],
        ["0", "0", "a1", "a1", "a2", "a3"],
        ["0", "0", "a2", "a2", "a3", "a4"],
    )
    Ainv = Matrix(pedigree_inverse(ped))
    q, t = length(ped.ids), 2
    Z = Matrix{Float64}(I, q, q)
    X = hcat(ones(q), [-2.0, -1.0, 0.0, 1.0, 2.0, 3.0])
    Y = [2.0 4.1; 3.2 3.7; 2.8 5.4; 4.5 4.0; 5.1 6.2; 3.9 5.7]
    Λ = reshape([0.8, -0.45], t, 1)
    σe2 = 0.75

    reduced = HSquared.gllvm_laplace_marginal_loglik(
        Y, Ainv, Λ, HSquared.GaussianResponse(σe2); X = X, maxiter = 1,
    )
    reference = HSquared._multivariate_reml_loglik(
        Y, X, Z, Ainv, Λ * transpose(Λ), σe2 .* Matrix{Float64}(I, t, t),
    )
    @test reduced.converged
    @test reduced.loglik ≈ reference atol = 1e-8

    # The flat fixed-effect measure uses the supplied X coordinates. A
    # nonsingular change of basis therefore shifts the objective by
    # -T*log(abs(det(C))) while preserving its fitted-value space.
    C = [2.0 0.25; 0.0 1.5]
    Xc = X * C
    reduced_c = HSquared.gllvm_laplace_marginal_loglik(
        Y, Ainv, Λ, HSquared.GaussianResponse(σe2); X = Xc, maxiter = 1,
    )
    reference_c = HSquared._multivariate_reml_loglik(
        Y, Xc, Z, Ainv, Λ * transpose(Λ), σe2 .* Matrix{Float64}(I, t, t),
    )
    coordinate_shift = -t * log(abs(det(C)))
    @test reduced_c.converged
    @test reduced_c.loglik ≈ reference_c atol = 1e-8
    @test reduced_c.loglik - reduced.loglik ≈ coordinate_shift atol = 1e-8
    @test reference_c - reference ≈ coordinate_shift atol = 1e-8
end

@testset "genetic GLLVM accepts damped scoring steps" begin
    Y = reshape([0.0, 0, 0, 0, 20, 20, 20, 20], 8, 1)
    Ainv = Matrix{Float64}(I, size(Y, 1), size(Y, 1))
    Λ = fill(0.5, 1, 1)
    result = HSquared.gllvm_laplace_marginal_loglik(
        Y, Ainv, Λ, HSquared.BetaBinomialResponse(20, 0.5);
        tol = 1e-8, maxiter = 100,
    )
    @test result.converged
    @test isfinite(result.loglik)
    @test result.stop_reason == :converged
    @test result.backtracks > 0
end

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
        trait_names = ["t1", "t2", "t3"],
    ) for initial in (nothing, start1, start2, 0.1 .* start1)]
    @test all(fit -> fit.converged, fits)
    @test all(fit -> fit.converged == (fit.optimizer_converged && fit.mode_converged), fits)
    @test all(fit -> fit.mode_converged && fit.mode_gradient_norm < 1e-10, fits)
    @test all(fit -> fit.mode_stop_reason == :converged && fit.mode_backtracks >= 0, fits)
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

    capped = HSquared.fit_gllvm_laplace_reml(
        Y, Ainv, HSquared.PoissonResponse(); rank = 2,
        initial = start1, iterations = 1,
    )
    @test !capped.optimizer_converged
    @test capped.mode_converged
    @test !capped.converged
    @test capped.iterations == 1

    # Independently evaluate the joint score at the returned mode. A convergence
    # flag and gradient norm must describe that mode, not the preceding iterate.
    η = reference.beta[1, :]'
    η = repeat(η, size(Y, 1)) .+ reference.g * transpose(start1)
    score_y = Y .- exp.(η)
    score_beta = vec(sum(score_y; dims = 1))
    score_g = score_y * start1 - Ainv * reference.g
    final_score_norm = norm(vcat(score_beta, vec(score_g)))
    @test reference.gradient_norm ≈ final_score_norm atol = 1e-12 rtol = 1e-8
    @test reference.converged == (final_score_norm < 1e-10)

    # Fitted summaries must follow trait permutations. Rotate-invariant G and
    # trait effects are compared; raw loading rows are intentionally excluded.
    trait_order_fit = HSquared.fit_gllvm_laplace_reml(
        Y[:, trait_order], Ainv, HSquared.PoissonResponse(); rank = 2,
        initial = start1[trait_order, :], iterations = 300,
        trait_names = ["t1", "t2", "t3"][trait_order],
    )
    @test trait_order_fit.converged
    @test trait_order_fit.trait_names == ["t1", "t2", "t3"][trait_order]
    @test trait_order_fit.loglik ≈ fits[2].loglik atol = 1e-6
    @test trait_order_fit.genetic_covariance ≈
        fits[2].genetic_covariance[trait_order, trait_order] atol = 1e-5
    @test trait_order_fit.beta ≈ fits[2].beta[:, trait_order] atol = 1e-5
    @test breeding_values(trait_order_fit) ≈
        breeding_values(fits[2])[:, trait_order] atol = 1e-5

    # Rebuild Ainv after permuting raw pedigree input rows, then align the
    # returned trait modes by normalized pedigree ID before comparing fits.
    ids_input = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    sire_input = ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"]
    dam_input = ["0", "0", "a2", "a2", "0", "0", "a4", "a6"]
    permuted_ped = normalize_pedigree(
        ids_input[animal_order], sire_input[animal_order], dam_input[animal_order],
    )
    permuted_Ainv = Matrix(pedigree_inverse(permuted_ped))
    permuted_Y = Y[[findfirst(==(id), ped.ids) for id in permuted_ped.ids], :]
    animal_order_fit = HSquared.fit_gllvm_laplace_reml(
        permuted_Y, permuted_Ainv, HSquared.PoissonResponse(); rank = 2,
        initial = start1, iterations = 300,
        trait_names = ["t1", "t2", "t3"],
    )
    align_animals = [findfirst(==(id), permuted_ped.ids) for id in ped.ids]
    @test animal_order_fit.converged
    @test animal_order_fit.loglik ≈ fits[2].loglik atol = 1e-6
    @test animal_order_fit.genetic_covariance ≈ fits[2].genetic_covariance atol = 1e-5
    @test animal_order_fit.beta ≈ fits[2].beta atol = 1e-5
    @test breeding_values(animal_order_fit)[align_animals, :] ≈
        breeding_values(fits[2]) atol = 1e-5

    @test_throws ArgumentError HSquared.fit_gllvm_laplace_reml(
        Y, Ainv, HSquared.PoissonResponse(); rank = 2,
        trait_names = ["t1", "t1", "t3"], iterations = 1,
    )
    @test_throws ArgumentError HSquared.fit_gllvm_laplace_reml(
        Y, Ainv, HSquared.PoissonResponse(); rank = 2,
        trait_names = ["t1", "t2"], iterations = 1,
    )
    @test_throws ArgumentError HSquared.fit_gllvm_laplace_reml(
        Y, Ainv, HSquared.PoissonResponse(); rank = 2,
        trait_names = ["t1", "   ", "t3"], iterations = 1,
    )
    for separator in ('\u2028', '\u2029')
        @test_throws ArgumentError HSquared.fit_gllvm_laplace_reml(
            Y, Ainv, HSquared.PoissonResponse(); rank = 2,
            trait_names = ["t1", string(separator), "t3"], iterations = 1,
        )
    end
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
