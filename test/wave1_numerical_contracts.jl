using Test
using Random
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

        @test_throws ArgumentError matrix_free_reml_information(ones(2), ones(2, 2), effects, sigmas, se2)
        @test_throws ArgumentError matrix_free_reml_information(ones(2), ones(3, 1), effects, sigmas, se2)
        @test_throws ArgumentError matrix_free_reml_information(ones(2), ones(2, 1),
            [(ones(3, 2), Matrix{Float64}(I, 2, 2))], sigmas, se2)
        @test_throws ArgumentError matrix_free_reml_information(ones(2), ones(2, 1),
            [(ones(2, 3), Matrix{Float64}(I, 2, 2))], sigmas, se2)
    end
    @testset "matrix-free REML rejects rank-deficient fixed effects" begin
        n = 4
        y0 = zeros(n)
        y1 = [1.0, -1.0, 2.0, -2.0]
        Xdup = hcat(ones(n), ones(n))
        Xzero = hcat(ones(n), zeros(n))
        Z = sparse(1.0I, n, n)
        Q = spdiagm(0 => ones(n))
        effects = [(Z, Q)]

        for Xbad in (Xdup, Xzero), y in (y0, y1)
            @test_throws ArgumentError solve_multi_effect_pcg(y, Xbad, effects, [1.0], 1.0)
            @test_throws ArgumentError mc_reml_block_traces(Xbad, effects, [1.0], 1.0;
                nprobe = 2)
            @test_throws ArgumentError fit_multi_effect_mc_reml(y, Xbad, effects;
                iterations = 1, nprobe = 2)
            @test_throws ArgumentError matrix_free_reml_information(y, Xbad, effects, [1.0], 1.0)
        end
        @test_throws ArgumentError matrix_free_reml_loglik(y0, Xdup, effects, [1.0], 1.0;
            slq_probes = 2, slq_steps = 2)
        @test_throws ArgumentError solve_animal_model_pcg(
            animal_model_spec(y0, Xdup, Z, Q), 1.0, 1.0)

        # A model with no fixed effects is a valid REML case.
        @test solve_multi_effect_pcg(y0, zeros(n, 0), effects, [1.0], 1.0).converged
    end
    @testset "supplied-variance multi-effect solve accepts square full-rank X" begin
        y = [1.0, -2.0]
        X = Matrix{Float64}(I, 2, 2)
        Z = Matrix{Float64}(I, 2, 2)
        Ainv = Matrix{Float64}(I, 2, 2)
        spec = animal_model_spec(y, X, Z, Ainv)

        single = solve_animal_model_pcg(spec, 1.0, 1.0)
        multi = solve_multi_effect_pcg(y, X, [(Z, Ainv)], [1.0], 1.0)

        @test single.converged
        @test multi.converged
        @test multi.beta ≈ single.beta atol = 1e-12
        @test multi.effects[1].values ≈ single.breeding_values.values atol = 1e-12
    end
    @testset "matrix-free likelihood validates PCG budget on zero response" begin
        n = 3
        y = zeros(n)
        X = zeros(n, 0)
        Z = sparse(1.0I, n, n)
        Q = spdiagm(0 => ones(n))
        for budget in (0, -1)
            @test_throws ArgumentError matrix_free_reml_loglik(y, X, [(Z, Q)], [1.0], 1.0;
                pcg_maxiter = budget, slq_probes = 2, slq_steps = 3)
        end
    end
    @testset "SLQ MCSE does not measure Lanczos quadrature error" begin
        y = zeros(3)
        X = zeros(3, 0)
        Z = sparse(1.0I, 3, 3)
        Q = spdiagm(0 => [1.0, 2.0, 3.0])
        effects = [(Z, Q)]
        approx, mcse = matrix_free_reml_loglik(y, X, effects, [1.0], 1.0;
            slq_probes = 8, slq_steps = 2)
        exact, exact_mcse = matrix_free_reml_loglik(y, X, effects, [1.0], 1.0;
            slq_probes = 8, slq_steps = 3)
        exact_reference = -0.5 * (3 * log(2pi) + sum(log.([2.0, 1.5, 4 / 3])))
        @test isapprox(mcse, 0.0; atol = 1e-14)
        @test isapprox(exact_mcse, 0.0; atol = 1e-14)
        @test isapprox(exact, exact_reference; atol = 1e-12)
        @test !isapprox(approx, exact_reference; atol = 1e-6)

        y_info = [1.0, -1.0, 2.0]
        A = Diagonal([1.0, 0.5, 1 / 3])
        V = Diagonal([2.0, 1.5, 4 / 3])
        P = inv(V)
        py = P * y_info
        W = hcat(A * py, py)
        info_reference = 0.5 .* (W' * P * W)
        info = matrix_free_reml_information(y_info, X, effects, [1.0], 1.0)
        @test Matrix(info) ≈ info_reference rtol = 1e-12
    end
    @testset "shared trace probes need not have lower Monte-Carlo error" begin
        # With no fixed effects, two identical one-record incidence columns and
        # unit precisions give C = [2 1; 1 2]. Per-block probes estimate each
        # diagonal trace exactly (2/3); shared probes also include the random
        # cross-block term and therefore have positive probe variance.
        X = zeros(1, 0)
        effects = [(ones(1, 1), ones(1, 1)), (ones(1, 1), ones(1, 1))]
        per_block, per_block_mcse = mc_reml_block_traces(
            X, effects, [1.0, 1.0], 1.0; nprobe = 32, seed = 731,
        )
        shared, shared_mcse = mc_reml_block_traces(
            X, effects, [1.0, 1.0], 1.0; nprobe = 32, seed = 731,
            shared_probes = true,
        )

        @test per_block ≈ fill(2 / 3, 2) atol = 1e-12
        @test per_block_mcse ≈ zeros(2) atol = 1e-12
        @test all(>(0), shared_mcse)
        @test all(shared_mcse .> per_block_mcse)
    end
    @testset "fit trace MCSE is evaluated at returned variances" begin
        y = [1.0, 2.0, -1.0, 0.5, 3.0, -2.0]
        X = ones(6, 1)
        Z = sparse([1.0 0 0; 1 0 0; 0 1 0; 0 1 0; 0 0 1; 0 0 1])
        Ainv = Diagonal([1.0, 2.0, 3.0])
        effects = [(Z, Ainv)]
        nprobe = 12
        seed = 731

        fit = fit_multi_effect_mc_reml(
            y, X, effects; initial = [0.7, 0.9], iterations = 1,
            nprobe = nprobe, seed = seed, pcg_tol = 1e-11,
        )
        _, expected_mcse = mc_reml_block_traces(
            X, effects, fit.variance_components.sigmas,
            fit.variance_components.sigma_e2; nprobe = nprobe,
            seed = seed, tol = 1e-11,
        )

        @test fit.trace_mcse ≈ expected_mcse atol = 1e-12
        @test fit.trace_evaluation_variance_components == fit.variance_components
    end
    @testset "matrix-free routes reject invalid relationship precision" begin
        y = zeros(2)
        X = zeros(2, 0)
        Z = sparse(1.0I, 2, 2)
        valid = spdiagm(0 => ones(2))
        asymmetric = sparse([1.0 0.25; 0.0 1.0])
        tiny_asymmetric = 1e-20 .* asymmetric
        indefinite = sparse([1.0 2.0; 2.0 1.0])
        nonfinite = sparse([1.0 Inf; Inf 1.0])
        tiny_valid = sparse(1e-20 .* Matrix{Float64}(I, 2, 2))

        for invalid in (asymmetric, tiny_asymmetric, indefinite, nonfinite)
            effects = [(Z, invalid)]
            # A zero RHS makes PCG return immediately, so rejection must come
            # from validating the covariance model rather than sampled curvature.
            @test_throws ArgumentError solve_multi_effect_pcg(y, X, effects, [1.0], 1.0)
            @test_throws ArgumentError matrix_free_reml_loglik(y, X, effects, [1.0], 1.0;
                slq_probes = 2, slq_steps = 2)
            @test_throws ArgumentError mc_reml_block_traces(X, effects, [1.0], 1.0;
                nprobe = 2)
            @test_throws ArgumentError fit_multi_effect_mc_reml(y, X, effects;
                iterations = 1, nprobe = 2)
            @test_throws ArgumentError matrix_free_reml_information(y, X, effects, [1.0], 1.0)
            spec = animal_model_spec(y, X, Z, invalid)
            @test_throws ArgumentError solve_animal_model_pcg(spec, 1.0, 1.0; matrix_free = true)
            @test_throws ArgumentError solve_animal_model_pcg(spec, 1.0, 1.0)
        end

        for preconditioner in (:jacobi, :none, :ichol)
            @test_throws ArgumentError solve_animal_model_pcg(animal_model_spec(y, X, Z, indefinite),
                10.0, 1.0; preconditioner = preconditioner)
        end

        @test_throws ArgumentError solve_animal_model_pcg(animal_model_spec(y, X, Z, valid),
            1.0, 1.0; tol = Inf)
        @test_throws ArgumentError solve_animal_model_pcg(animal_model_spec(y, X, Z, valid),
            Inf, 1.0)
        @test_throws ArgumentError solve_animal_model_pcg(animal_model_spec(y, X, Z, valid),
            1.0, BigFloat("1e10000"))
        @test_throws ArgumentError solve_animal_model_pcg(animal_model_spec(y, X, Z, valid),
            nextfloat(0.0), 1.0)
        @test_throws ArgumentError matrix_free_reml_loglik(y, X, [(Z, valid)], [Inf], 1.0;
            slq_probes = 2, slq_steps = 2)
        @test_throws ArgumentError matrix_free_reml_loglik(y, X, [(Z, valid)], [1.0], Inf;
            slq_probes = 2, slq_steps = 2)
        @test_throws ArgumentError matrix_free_reml_loglik(y, X, [(Z, valid)], [nextfloat(0.0)], 1.0;
            slq_probes = 2, slq_steps = 2)
        @test_throws ArgumentError matrix_free_reml_loglik(y, X, [(Z, valid)], [1.0], nextfloat(0.0);
            slq_probes = 2, slq_steps = 2)
        @test_throws ArgumentError matrix_free_reml_loglik(y, X, [(Z, valid)], [1.0], 1.0;
            pcg_tol = Inf, slq_probes = 2, slq_steps = 2)
        @test_throws ArgumentError matrix_free_reml_loglik(y, ones(2, 2), [(Z, valid)], [1.0], 1.0;
            slq_probes = 2, slq_steps = 2)
        @test_throws ArgumentError matrix_free_reml_loglik(y, X, [(ones(3, 2), valid)], [1.0], 1.0;
            slq_probes = 2, slq_steps = 2)
        @test_throws ArgumentError matrix_free_reml_loglik(y, X, [(ones(2, 3), valid)], [1.0], 1.0;
            slq_probes = 2, slq_steps = 2)
        for invalid_variance in (Inf, BigFloat("1e10000"), nextfloat(0.0))
            @test_throws ArgumentError mc_reml_block_traces(X, [(Z, valid)], [invalid_variance], 1.0)
            @test_throws ArgumentError mc_reml_block_traces(X, [(Z, valid)], [1.0], invalid_variance)
        end
        # Finite Q and variances can still overflow while forming the MME
        # diagonal. A zero RHS must not bypass that model-scale validation.
        huge_precision = spdiagm(0 => fill(1e308, 2))
        huge_spec = animal_model_spec(y, X, Z, huge_precision)
        huge_effects = [(Z, huge_precision)]
        @test_throws ArgumentError solve_animal_model_pcg(huge_spec, 0.1, 1.0)
        @test_throws ArgumentError solve_multi_effect_pcg(y, X, huge_effects, [0.1], 1.0)
        @test_throws ArgumentError mc_reml_block_traces(X, huge_effects, [0.1], 1.0; nprobe = 2)
        @test_throws ArgumentError matrix_free_reml_loglik(y, X, huge_effects, [0.1], 1.0;
            slq_probes = 2, slq_steps = 2)
        @test_throws ArgumentError matrix_free_reml_information(y, X, huge_effects, [0.1], 1.0)
        @test_throws ArgumentError mc_reml_block_traces(X, [(Z, valid)], [1.0], 1.0; tol = Inf)
        @test_throws ArgumentError solve_multi_effect_pcg(ones(8), ones(8, 1),
            [(sparse(1.0I, 8, 8), spdiagm(0 => ones(8)))], [1.0], 1.0; tol = Inf, maxiter = 1)
        @test_throws ArgumentError solve_multi_effect_pcg(ones(8), ones(8, 1),
            [(sparse(1.0I, 8, 8), spdiagm(0 => ones(8)))], [Inf], 1.0)
        @test_throws ArgumentError solve_multi_effect_pcg(ones(8), ones(8, 1),
            [(sparse(1.0I, 8, 8), spdiagm(0 => ones(8)))], [1.0], BigFloat("1e10000"))
        @test_throws ArgumentError fit_multi_effect_mc_reml(ones(8), ones(8, 1),
            [(sparse(1.0I, 8, 8), spdiagm(0 => ones(8)))]; tol = Inf, iterations = 1, nprobe = 4)
        @test_throws ArgumentError fit_multi_effect_mc_reml(ones(8), ones(8, 1),
            [(sparse(1.0I, 8, 8), spdiagm(0 => ones(8)))];
            initial = [Inf, 1.0], iterations = 1, nprobe = 4)
        @test_throws ArgumentError fit_multi_effect_mc_reml(ones(8), ones(8, 1),
            [(sparse(1.0I, 8, 8), spdiagm(0 => ones(8)))];
            initial = [nextfloat(0.0), 1.0], iterations = 1, nprobe = 4)
        @test HSquared._finite_positive_variance_update([1.0], 1.0)
        @test !HSquared._finite_positive_variance_update([Inf], 1.0)
        @test !HSquared._finite_positive_variance_update([1.0], Inf)

        solution = solve_multi_effect_pcg(y, X, [(Z, valid)], [1.0], 1.0)
        @test solution.converged
        @test all(iszero, solution.beta)
        @test solve_multi_effect_pcg(y, X, [(Z, tiny_valid)], [1.0], 1.0).converged

        roundoff_asymmetric = sparse([1.0 0.5 + 1e-15; 0.5 1.0])
        canonical, _ = HSquared._validate_matrix_free_precision(roundoff_asymmetric, 1)
        @test issymmetric(canonical)
        @test Matrix(canonical) == Matrix(0.5 .* (roundoff_asymmetric + transpose(roundoff_asymmetric)))
        @test isposdef(Matrix(canonical))

        # Averaging finite entries near Float64's upper range must not
        # overflow in the intermediate sum.
        large_finite = sparse([1e308 0.0; 0.0 1e308])
        canonical_large, _ = HSquared._validate_matrix_free_precision(large_finite, 1)
        @test all(isfinite, nonzeros(canonical_large))
        @test canonical_large == large_finite

        yfit = [1.0, -1.0]
        spec = animal_model_spec(yfit, X, Z, roundoff_asymmetric; method = :REML)
        single_fit = fit_matrix_free_reml(spec; initial = (1.0, 1.0), iterations = 1,
            nprobe = 4, seed = 17, compute_loglik = true)
        @test issymmetric(single_fit.spec.Ainv)

        fit = fit_multi_effect_mc_reml(yfit, X, [(Z, valid)];
            initial = [1.0, 1.0], iterations = 1, nprobe = 4, seed = 17,
            compute_loglik = true, slq_probes = 4, slq_steps = 2)
        direct_loglik = matrix_free_reml_loglik(yfit, X, [(Z, valid)],
            fit.variance_components.sigmas, fit.variance_components.sigma_e2;
            seed = 17, slq_probes = 4, slq_steps = 2)[1]
        @test isfinite(fit.loglik)
        @test fit.loglik ≈ direct_loglik rtol = 1e-12
    end
    @testset "SLQ Lanczos stopping is invariant to covariance scale" begin
        # With no fixed effects, identity incidence, Q⁻¹ = diag(1, 1/3), and
        # σ²a = σ²e = 1e14, the MME precision is diag(2e-14, 4e-14).
        # Two Lanczos steps are exact for this 2 × 2 operator; an absolute
        # breakdown threshold incorrectly truncates every probe at step one.
        y = zeros(2)
        X = zeros(2, 0)
        Z = sparse(1.0I, 2, 2)
        Ainv = spdiagm(0 => [1.0, 3.0])
        effects = [(Z, Ainv)]
        scaled, scaled_mcse = matrix_free_reml_loglik(
            y, X, effects, [1e14], 1e14;
            slq_probes = 4, slq_steps = 2, seed = 3,
        )
        scaled_reference = -0.5 * (2log(2π) + log(2e14) + log((4 / 3) * 1e14))
        @test scaled ≈ scaled_reference atol = 1e-10
        @test scaled_mcse == 0.0

        unit, unit_mcse = matrix_free_reml_loglik(
            y, X, effects, [1.0], 1.0;
            slq_probes = 4, slq_steps = 2, seed = 3,
        )
        unit_reference = -0.5 * (2log(2π) + log(2.0) + log(4 / 3))
        @test unit ≈ unit_reference atol = 1e-12
        @test unit_mcse == 0.0
    end
    @testset "SLQ Lanczos stops at Krylov exhaustion" begin
        # The requested quadrature order may exceed the operator dimension.
        # A generic three-eigenvalue operator exhausts its Krylov space after
        # three directions, including when the spectrum is rescaled.
        for scale in (1e-14, 1.0, 1e14)
            diagonal = scale .* [1.0, 2.0, 3.0]
            A = Diagonal(diagonal)
            observed = HSquared._lanczos_logquad(v -> A * v, ones(3), 40)
            @test isfinite(observed)
            @test observed ≈ sum(log, diagonal) / length(diagonal) rtol = 1e-12 atol = 1e-12
        end

        # Repeated eigenvalues reduce the Krylov dimension below N. Full
        # re-orthogonalization must detect that breakdown before normalizing a
        # numerically zero residual or passing a nonfinite tridiagonal to LAPACK.
        diagonal = [1.0, 2.0, 2.0, 2.0, 3.0]
        A = Diagonal(diagonal)
        observed = HSquared._lanczos_logquad(v -> A * v, ones(5), 40)
        @test isfinite(observed)
        @test observed ≈ sum(log, diagonal) / length(diagonal) rtol = 1e-12 atol = 1e-12
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
    @testset "REML quadratics survive a large fitted intercept" begin
        n = 8
        y0 = [1.0, 3.0, 2.0, 5.0, 1.5, 4.0, 2.5, 6.0]
        X = ones(n, 1)
        Z = sparse(1.0I, n, n)
        Q = spdiagm(0 => collect(1.0:n), 1 => fill(0.1, n - 1),
                    -1 => fill(0.1, n - 1))
        effects = [(Z, Q)]
        reference = gaussian_loglik(
            animal_model_spec(y0, X, Z, Q; ids = string.(1:n), method = :REML),
            1.2, 0.8; method = :REML).loglik
        baseline_mc = matrix_free_reml_loglik(y0, X, effects, [1.2], 0.8;
            pcg_tol = 1e-12, slq_probes = 2, slq_steps = 8, seed = 11)[1]
        for shift in (0.0, 1e4, 1e6, 1e8)
            y = y0 .+ shift
            spec = animal_model_spec(y, X, Z, Q; ids = string.(1:n), method = :REML)
            @test sparse_reml_loglik(spec, 1.2, 0.8).loglik ≈ reference atol = 1e-5
            @test sparse_multi_reml_loglik(y, X, effects, [1.2], 0.8)[1] ≈
                  reference atol = 1e-5
            @test matrix_free_reml_loglik(y, X, effects, [1.2], 0.8;
                pcg_tol = 1e-12, slq_probes = 2, slq_steps = 8, seed = 11)[1] ≈
                  baseline_mc atol = 1e-5
            context = (eigenvalues = ones(n), y = y, X = X, n = n, p = 1)
            baseline_context = (eigenvalues = ones(n), y = y0, X = X, n = n, p = 1)
            @test HSquared._genomic_profile_reml(context, 0.5).loglik ≈
                  HSquared._genomic_profile_reml(baseline_context, 0.5).loglik atol = 1e-5
        end
    end
end


@testset "constructed genomic relationships are symmetric and invertible" begin
    rng = MersenneTwister(42)
    markers = 2 .* rand(rng, 8, 11)
    weights = rand(rng, 11)
    ridge = 0.05
    relationships = (
        ("VanRaden 1", genomic_relationship_matrix(markers)),
        ("weighted VanRaden 1", genomic_relationship_matrix(markers; weights = weights)),
        ("VanRaden 2", genomic_relationship_matrix(markers; method = :vanraden2)),
    )

    for (label, G) in relationships
        @testset "$label" begin
            @test issymmetric(G)
            Q = genomic_relationship_inverse(G; ridge = ridge)
            @test (G + ridge * I) * Q ≈ I(8) rtol = 1e-10 atol = 1e-10

            Qapy = apy_genomic_relationship_inverse(G, [1, 2]; ridge = ridge)
            @test issymmetric(Qapy)
            @test apy_genomic_relationship_inverse(G, collect(1:8); ridge = ridge) ≈ Q
        end
    end

    rounded = [1.0 0.25; 0.25000000000000006 1.0]
    HSquared._symmetrize_roundoff!(rounded)
    @test issymmetric(rounded)
    overflow_markers = reshape([2.0, 0.0, 0.0, 0.0], 4, 1)
    overflow_weights = [8e307]
    overflow_centered = centered_markers(overflow_markers)
    finite_weighted_scale = sum(overflow_weights .* 2 .* overflow_centered.p .*
                                (1 .- overflow_centered.p))
    @test isfinite(finite_weighted_scale)
    overflowing_crossproduct = overflow_centered.W * Diagonal(overflow_weights) *
                               transpose(overflow_centered.W)
    @test !isfinite(overflowing_crossproduct[1, 1])
    @test_throws ArgumentError genomic_relationship_matrix(overflow_markers; weights = overflow_weights)
end


@testset "APY finite inputs and conditional variance scale" begin
    G = [2.0 0.5; 0.5 2.0]
    Q = apy_genomic_relationship_inverse(G, [1]; ridge = 0.0)
    small = 1e-13 .* G
    Qsmall = try
        apy_genomic_relationship_inverse(small, [1]; ridge = 0.0)
    catch
        nothing
    end
    @test Qsmall !== nothing
    if Qsmall !== nothing
        @test Qsmall ≈ Q ./ 1e-13 rtol = 1e-12
    end

    @test_throws ArgumentError apy_genomic_relationship_inverse(G, [1]; ridge = Inf)
    @test_throws ArgumentError apy_genomic_relationship_inverse([1.0 0.0; 0.0 Inf], [1]; ridge = 0.0)
    @test_throws ArgumentError apy_genomic_relationship_inverse([1.0 0.0; 0.0 NaN], [1]; ridge = 0.0)
    @test_throws ArgumentError apy_genomic_relationship_inverse(reshape(BigFloat[big"1e400"], 1, 1), [1]; ridge = 0.0)
    @test_throws ArgumentError apy_genomic_relationship_inverse(reshape([1e308], 1, 1), [1]; ridge = 1e308)
    @test_throws ArgumentError apy_genomic_relationship_inverse(reshape([1.0], 1, 1), [1]; ridge = big"1e400")
end


@testset "APY partial-core block formula and Schur cutoff" begin
    G = [2.0 0.5; 0.5 2.0]
    Q = apy_genomic_relationship_inverse(G, [1])
    partial_core_reference = [8 / 15 -2 / 15; -2 / 15 8 / 15]
    @test Q ≈ partial_core_reference rtol = 1e-14 atol = 1e-14

    below_correlation = prevfloat(1.0)
    G_below = [1.0 below_correlation; below_correlation 1.0]
    @test_throws ArgumentError apy_genomic_relationship_inverse(G_below, [1])

    above_correlation = sqrt(1 - 128eps(Float64))
    G_above = [1.0 above_correlation; above_correlation 1.0]
    Q_above = apy_genomic_relationship_inverse(G_above, [1])
    conditional_variance = 1 - above_correlation^2
    @test all(isfinite, Q_above)
    @test issymmetric(Q_above)
    @test Q_above[2, 2] ≈ inv(conditional_variance) rtol = 1e-8
end

@testset "dense Gaussian routes reject indefinite relationship precision" begin
    y = [-0.5, 0.5]
    X = ones(2, 1)
    Z = Matrix{Float64}(I, 2, 2)
    Ainv = [1.0 2.0; 2.0 1.0]
    spec = animal_model_spec(y, X, Z, Ainv; method = :ML)

    # The residual variance can make the implied marginal V positive definite
    # even though Ainv is indefinite. A finite marginal likelihood would still
    # be based on an invalid random-effect covariance model.
    A = inv(Symmetric(Ainv))
    V = Z * A * Z' + 10.0 .* I(2)
    @test isposdef(Symmetric(Matrix(V)))

    for method in (:ML, :REML)
        @test_throws ArgumentError gaussian_loglik(spec, 1.0, 10.0; method = method)
    end
    @test_throws ArgumentError fit_variance_components(
        spec; initial = (sigma_a2 = 1.0, sigma_e2 = 10.0), iterations = 2)
end

@testset "dense Gaussian routes validate relationship precision inputs" begin
    y = [-0.5, 0.5]
    X = ones(2, 1)
    Z = Matrix{Float64}(I, 2, 2)
    valid_spec = animal_model_spec(y, X, Z, Matrix{Float64}(I, 2, 2); method = :ML)
    @test_throws ArgumentError gaussian_loglik(valid_spec, 1.0, 1.0; method = :invalid)
    @test_throws ArgumentError fit_variance_components(valid_spec; method = :invalid, iterations = 2)

    asymmetric_spec = animal_model_spec(y, X, Z, [2.0 0.25; 0.5 1.0]; method = :ML)
    @test_throws ArgumentError gaussian_loglik(asymmetric_spec, 1.0, 1.0)

    nonfinite_spec = animal_model_spec(y, X, Z, [2.0 0.0; 0.0 Inf]; method = :ML)
    @test_throws ArgumentError gaussian_loglik(nonfinite_spec, 1.0, 1.0)
end
