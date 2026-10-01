using Test, LinearAlgebra, SparseArrays, HSquared

@testset "W1-09 multi-effect fixed-point score ladder" begin
    ped = normalize_pedigree(collect(1:8), [0, 0, 1, 1, 3, 3, 5, 6],
                             [0, 0, 2, 2, 4, 4, 4, 7])
    Q = pedigree_inverse(ped)
    rows = [1, 2, 3, 4, 5, 6, 7, 8, 3, 5, 8]
    n = length(rows)
    Z1 = sparse(1:n, rows, 1.0, n, 8)
    Z2 = sparse(1:n, mod1.(1:n, 3), 1.0, n, 3)
    effects = [(Z1, Q), (Z2, sparse(1.0I, 3, 3))]
    kernels = [Matrix(Z1 * inv(Matrix(Q)) * Z1'), Matrix(Z2 * Z2'), Matrix(1.0I, n, n)]
    X = hcat(ones(n), collect(1:n) ./ n)
    y0 = [2.0, 4, 3, 5, 2, 6, 3, 4, 3, 2, 4]
    for simultaneous in (false, true), amplitude in (0.25, 1.0), scale in (1e-4, 1.0, 1e4), ratio in (1e-8, 1e-12, 1e-16)
        y = (scale * amplitude) .* y0
        variances = scale^2 .* [ratio, simultaneous ? ratio : 0.4, 1.7]
        sigmas, evar = variances[1:2], variances[3]
        ws = HSquared._multi_reml_workspace(y, X, effects)
        _, rhs = HSquared._assemble_lhs_rhs!(ws, sigmas, evar)
        factor = HSquared._factorize!(ws)
        solution = factor \ rhs
        residual = y - ws.Xs * solution[1:ws.nfixed] - ws.Zf * solution[ws.nfixed+1:end]
        us = [solution[ws.offsets[i]+1:ws.offsets[i]+ws.qs[i]] for i in 1:2]
        traces = HSquared.selinv_block_traces(factor, ws.Ainvs, ws.offsets)
        actual = HSquared._multi_reml_scores(ws, factor, sigmas, evar, residual, traces, us)
        # Independent dense observation-space score with BOTH covariance terms.
        V = sum(variances[i] .* kernels[i] for i in 1:3)
        Vi = inv(Symmetric(V))
        P = Vi - Vi * X * ((X' * Vi * X) \ (X' * Vi))
        py = P * y
        expected = [0.5 * (dot(py, B * py) - tr(P * B)) for B in kernels]
        @test scale^2 .* actual ≈ scale^2 .* expected atol = 1e-9 rtol = 1e-9
    end
end

# Independent observation-space score. Dense matrices are confined to these
# tiny fixtures; neither the MME inverse nor selected inversion is used here.
function _w109_marginal_score(y, X, K, a, e)
    Vi = inv(Symmetric(a .* K + e * I))
    P = Vi - Vi * X * ((X' * Vi * X) \ (X' * Vi))
    py = P * y
    return [0.5 * (dot(py, K * py) - tr(P * K)),
            0.5 * (dot(py, py) - tr(P))]
end

@testset "W1-09 large boundary score refuses unbounded trace work" begin
    q = 513
    X = ones(q, 1)
    Z = sparse(1.0I, q, q)
    Q = sparse(1.0I, q, q)
    y = sin.(collect(1:q))
    a, e = 1e-16, 1.7
    spec = animal_model_spec(y, X, Z, Q; method = :REML)
    result = HSquared._fit_ai_reml_diagnostics(
        spec; initial = (sigma_a2 = a, sigma_e2 = e), iterations = 1)
    # Independent K=I closed form confirms that this point is not stationary.
    centered = y .- sum(y) / q
    score = 0.5 * (dot(centered, centered) / (a + e)^2 - (q - 1) / (a + e))
    @test score < -1
    @test !result.fit.converged
    @test result.diagnostics.termination_reason == "boundary_score_unresolved"
    @test result.fit.optimizer_status == "boundary_score_unresolved"
    @test fit_diagnostics(result.fit).optimizer_status == "boundary_score_unresolved"
    @test result.fit.variance_components == (sigma_a2 = a, sigma_e2 = e)
    @test isnan(result.diagnostics.ai_score_norm)
    @test isfinite(result.fit.likelihood.loglik)
end

@testset "W1-09 multi-effect boundary budget covers all triggered blocks" begin
    q = 257
    X = ones(q, 1)
    Z = sparse(1.0I, q, q)
    Q = sparse(1.0I, q, q)
    y = sin.(collect(1:q))
    initial = [1e-16, 1e-16, 1.7]
    result = fit_sparse_multi_effect_aireml(
        y, X, [(Z, Q), (Z, Q)]; initial = initial, iterations = 1)
    # Each block fits the budget separately; their combined trace work does not.
    @test !result.converged
    @test result.status == "boundary_score_unresolved"
    @test result.variance_components.sigmas == initial[1:2]
    @test result.variance_components.sigma_e2 == initial[3]
    @test isfinite(result.loglik)
end

@testset "W1-09 fixed-point additive-boundary score ladder" begin
    ped = normalize_pedigree(collect(1:8), [0, 0, 1, 1, 3, 3, 5, 6],
                             [0, 0, 2, 2, 4, 4, 4, 7])
    Q = pedigree_inverse(ped)
    A = inv(Matrix(Q))
    for repeated in (false, true)
        rows = repeated ? [1, 2, 3, 4, 5, 6, 7, 8, 3, 5, 8] : collect(1:8)
        n = length(rows)
        Z = sparse(1:n, rows, 1.0, n, 8)
        X = repeated ? hcat(ones(n), collect(1:n) ./ n) : ones(n, 1)
        y0 = [2.0, 4, 3, 5, 2, 6, 3, 4, 3, 2, 4][1:n]
        K = Matrix(Z * A * Z')
        # Both signs of the boundary score matter: low residual signal should
        # point toward zero; stronger signal should point into the interior.
        for amplitude in (0.25, 1.0), scale in (1e-4, 1.0, 1e4), ratio in (1e-8, 1e-12, 1e-16)
            y = (scale * amplitude) .* y0
            a, e = scale^2 * ratio, scale^2 * 1.7
            spec = animal_model_spec(y, X, Z, Q; ids = ped.ids, method = :REML)
            # With one iteration, diagnostics contain the score at the supplied
            # initial point, independently of the subsequent optimizer step.
            result = HSquared._fit_ai_reml_diagnostics(
                spec; initial = (sigma_a2 = a, sigma_e2 = e), iterations = 1)
            score = [result.diagnostics.ai_score_a, result.diagnostics.ai_score_e]
            expected = _w109_marginal_score(y, X, K, a, e)
            @test scale^2 .* score ≈ scale^2 .* expected atol = 1e-9 rtol = 1e-9
            @test !result.fit.converged
            @test all(isfinite, score)
        end
    end
end
