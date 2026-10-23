using Test, LinearAlgebra, SparseArrays, HSquared

@testset "W1 multi-REML structural support survives cancellation" begin
    cases = (
        (name = "centered fixed covariate", X = hcat(ones(3), [-1.0, 0, 1]),
         Z = sparse(1.0I, 3, 3), Q = sparse(1.0I, 3, 3)),
        (name = "crossproduct and precision cancellation", X = ones(3, 1),
         Z = sparse([1.0 0; 0 1; 1 1]), Q = sparse([2.0 -1; -1 2])),
    )
    y = [1.0, 2, 4]
    for case in cases
        @testset "$(case.name)" begin
            X, Z, Q = case.X, case.Z, case.Q
            effects = [(Z, Q)]
            ws = HSquared._multi_reml_workspace(y, X, effects)
            colptr, rowval = ws.lhs.colptr, rowvals(ws.lhs)
            initial_colptr, initial_rowval = copy(colptr), copy(rowval)
            A = inv(Matrix(Q))
            # Move away from cancellation, return to it, and change both scales.
            for (sa, se) in ((1.0, 1.0), (2.0, 1.0), (0.4, 1.7), (1.0, 1.0))
                ll, beta, us = HSquared._multi_reml_loglik!(ws, [sa], se)
                @test ws.lhs.colptr === colptr
                @test rowvals(ws.lhs) === rowval
                @test colptr == initial_colptr
                @test rowval == initial_rowval

                # Independent dense marginal equations for GLS, BLUP and REML.
                V = cholesky(Symmetric(sa * Matrix(Z) * A * Matrix(Z)' + se * I))
                ViX = V \ X
                F = cholesky(Symmetric(X' * ViX))
                expected_beta = F \ (X' * (V \ y))
                residual = y - X * expected_beta
                expected_u = sa * A * (Z' * (V \ residual))
                expected_ll = -0.5 * ((length(y) - size(X, 2)) * log(2pi) +
                    logdet(V) + logdet(F) + dot(residual, V \ residual))
                @test beta ≈ expected_beta atol = 1e-12 rtol = 1e-12
                @test only(us) ≈ expected_u atol = 1e-12 rtol = 1e-12
                @test ll ≈ expected_ll atol = 1e-12 rtol = 1e-12

                # Dense Henderson solve also checks the assembled block values.
                D = hcat(X, Matrix(Z))
                precision = zeros(size(D, 2), size(D, 2))
                p = size(X, 2)
                precision[(p + 1):end, (p + 1):end] = Matrix(Q) / sa
                C = D' * D / se + precision
                @test Matrix(ws.lhs) ≈ C atol = 1e-14 rtol = 1e-14
                @test ws.factor \ ws.rhs ≈ C \ (D' * y / se) atol = 1e-12 rtol = 1e-12
                @test sparse_multi_reml_loglik(y, X, effects, [sa], se)[1] ≈ expected_ll atol = 1e-12 rtol = 1e-12
            end
            # The public auto fitter must get through workspace construction.
            fit = fit_multi_effect(y, X, effects; method = :auto, iterations = 1,
                                   compute_loglik = true, verbose = false)
            @test isfinite(fit.loglik)
        end
    end
end
