using Test
using LinearAlgebra
using SparseArrays
using HSquared

@testset "Wave 1 numerical contracts" begin
    @testset "inner PCG convergence is required" begin
        n = 8
        y = [1.0, 3.0, 2.0, 5.0, 1.5, 4.0, 2.5, 6.0]
        X = ones(n, 1)
        Z = sparse(1.0I, n, n)
        Q = spdiagm(0 => collect(1.0:n), 1 => fill(0.1, n - 1), -1 => fill(0.1, n - 1))
        effects = [(Z, Q)]
        sigmas = [1.2]
        se2 = 0.8
        starved = solve_multi_effect_pcg(y, X, effects, sigmas, se2; tol = 1e-12, maxiter = 1)
        @test !starved.converged
        for shared in (false, true)
            @test_throws ArgumentError mc_reml_block_traces(X, effects, sigmas, se2;
                nprobe = 4, tol = 1e-12, maxiter = 1, shared_probes = shared)
        end
        @test_throws ArgumentError fit_multi_effect_mc_reml(y, X, effects;
            initial = [1.2, 0.8], iterations = 2, nprobe = 4, pcg_tol = 1e-12, pcg_maxiter = 1)
        @test_throws ArgumentError matrix_free_reml_loglik(y, X, effects, sigmas, se2;
            pcg_tol = 1e-12, pcg_maxiter = 1, slq_probes = 2, slq_steps = 8)
        @test_throws ArgumentError matrix_free_reml_information(y, X, effects, sigmas, se2;
            pcg_tol = 1e-12, pcg_maxiter = 1)
        @test_throws ArgumentError matrix_free_ratio_intervals(y, X, effects, sigmas, se2;
            pcg_tol = 1e-12, pcg_maxiter = 1)
        V = 1.2 .* inv(Matrix(Q)) + se2 .* Matrix{Float64}(I, n, n)
        Vi = inv(V)
        P = Vi - Vi * X * inv(X' * Vi * X) * X' * Vi
        py = P * y
        W = hcat(inv(Matrix(Q)) * py, py)
        AI = 0.5 .* (W' * P * W)
        @test Matrix(matrix_free_reml_information(y, X, effects, sigmas, se2;
            pcg_tol = 1e-12)) ≈ AI rtol = 1e-9
    end
    @testset "normal two-sided tails preserve sign symmetry" begin
        # Independent standard-normal two-sided probabilities, not the package CDF.
        for (z, reference) in ((8.0, 1.244192114854356e-15),
                               (9.0, 2.257176811907681e-19),
                               (12.0, 3.552964224155358e-33))
            positive = HSquared._standard_normal_two_sided_pvalue(z)
            negative = HSquared._standard_normal_two_sided_pvalue(-z)
            @test positive > 0
            @test positive == negative
            # Relative accuracy must also hold when the tail is much smaller than eps().
            @test positive ≈ reference rtol = 1e-12
        end
        @test HSquared._standard_normal_two_sided_pvalue(0.0) == 1.0
        @test_throws ArgumentError HSquared._standard_normal_two_sided_pvalue(Inf)
    end
    @testset "genomic covariance symmetry is validated" begin
        asymmetric = [2.0 0.25; 0.5 2.0]
        @test_throws ArgumentError genomic_relationship_inverse(asymmetric; ridge = 0.1)
        @test_throws ArgumentError apy_genomic_relationship_inverse(asymmetric, [1]; ridge = 0.1)
        @test_throws ArgumentError HSquared._mixed_marker_scan_cache([1.0, 2.0], ones(2, 1),
            Matrix{Float64}(I, 2, 2), asymmetric, 1.0, 1.0)
        symmetric = [2.0 0.5; 0.5 2.0]
        @test (symmetric + 0.1I) * genomic_relationship_inverse(symmetric; ridge = 0.1) ≈ I(2)
        @test apy_genomic_relationship_inverse(symmetric, [1, 2]; ridge = 0.1) ≈
            genomic_relationship_inverse(symmetric; ridge = 0.1)
    end
end
