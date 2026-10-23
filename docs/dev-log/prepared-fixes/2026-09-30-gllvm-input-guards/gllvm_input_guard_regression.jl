using Test, LinearAlgebra, HSquared
@testset "GLLVM input guard regressions" begin
H = HSquared
Y = [2.0 3.0; 4.0 1.0]
Ai = Matrix{Float64}(I, 2, 2)
L = reshape([0.6, 0.5], 2, 1)
X = ones(2, 1)
family = H.GaussianResponse(1.0)

@testset "GLLVM rejects invalid mode controls" begin
    for tolerance in (Inf, -Inf, NaN, 0.0, -1.0)
        @test_throws ArgumentError H.gllvm_laplace_marginal_loglik(
            Y, Ai, L, family; X = X, tol = tolerance, maxiter = 0)
        @test_throws ArgumentError H.fit_gllvm_laplace_reml(
            Y, Ai, family; rank = 1, initial = L, X = X,
            tol = tolerance, maxiter = 0, iterations = 0)
    end
    @test_throws ArgumentError H.gllvm_laplace_marginal_loglik(Y, Ai, L, family; maxiter = -1)
    @test_throws ArgumentError H.fit_gllvm_laplace_reml(Y, Ai, family; rank = 1, maxiter = -1, iterations = 0)
    capped = H.gllvm_laplace_marginal_loglik(Y, Ai, L, family; maxiter = 0)
    @test !capped.converged
    @test isnan(capped.loglik)
    @test capped.iterations == 0
    @test capped.stop_reason == :maxiter
end

@testset "GLLVM classifies invalid data and families before numerical evaluation" begin
    for (response, design, response_family) in (
        (copy(Y), [Inf; 1.0;;], family),
        ([NaN 3.0; 4.0 1.0], X, family),
        ([Inf 3.0; 4.0 1.0], X, family),
        (Y, X, H.GaussianResponse(Inf)),
        (Y, X, Any[family, "gaussian"]),
        (Y, X, [family, H.GaussianResponse(Inf)]),
        (Y, X, [family]),
    )
        @test_throws ArgumentError H.gllvm_laplace_marginal_loglik(
            response, Ai, L, response_family; X = design, maxiter = 0)
        @test_throws ArgumentError H.fit_gllvm_laplace_reml(
            response, Ai, response_family; rank = 1, initial = L,
            X = design, maxiter = 0, iterations = 0)
    end
    for initial in (fill(Inf, 2, 1), fill(NaN, 2, 1))
        @test_throws ArgumentError H.fit_gllvm_laplace_reml(
            Y, Ai, family; rank = 1, initial = initial, iterations = 0)
    end
    for uniqueness in ([Inf, 0.2], [NaN, 0.2])
        @test_throws ArgumentError H.fit_gllvm_laplace_reml(
            Y, Ai, family; rank = 1, structure = :factor_analytic,
            initial = L, initial_uniqueness = uniqueness, iterations = 0)
    end
end

@testset "GLLVM valid Gaussian and per-trait inputs retain their values" begin
    scalar = H.gllvm_laplace_marginal_loglik(Y, Ai, L, family; maxiter = 1)
    vector = H.gllvm_laplace_marginal_loglik(Y, Ai, L, [family, family]; maxiter = 1)
    @test scalar.converged
    @test isfinite(scalar.loglik)
    @test scalar.loglik == vector.loglik
    @test scalar.beta == vector.beta
    @test scalar.g == vector.g
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

end
