using HSquared
using LinearAlgebra
using Random
using SparseArrays
using Test

@testset "W1-05 strict-order versus SIMD AI-REML fit parity" begin
    # Predeclared numerical tolerances. The two recursions differ only in the
    # aligned-tail reduction order; these bounds cover accumulated roundoff,
    # not a different optimizer solution.
    TRACE_RTOL = 1e-10
    SCORE_RTOL = 1e-9
    SCORE_ATOL = 1e-9
    STEP_RTOL = 1e-8
    STEP_ATOL = 1e-9
    FIT_RTOL = 1e-8
    LOGLIK_ATOL = 1e-7
    PEV_RTOL = 1e-8

    # Same seeded, additive-signal pedigree design as the existing aligned-tail
    # test. The additive signal keeps the fit at an identified interior optimum.
    rng = MersenneTwister(20260920)
    q = 400
    sire = zeros(Int, q)
    dam = zeros(Int, q)
    for i in 5:q
        sire[i] = rand(rng, 1:(i - 1))
        dam[i] = rand(rng, 1:(i - 1))
        while dam[i] == sire[i]
            dam[i] = rand(rng, 1:(i - 1))
        end
    end
    ped = normalize_pedigree(collect(1:q), sire, dam)
    Ainv = pedigree_inverse(ped)
    additive = zeros(q)
    for i in 1:q
        si, di = ped.sire[i], ped.dam[i]
        additive[i] = (si == 0 && di == 0) ? randn(rng) :
                      0.5 * (additive[si] + additive[di]) + sqrt(0.5) * randn(rng)
    end
    y = additive .+ 0.5 .* randn(rng, q)
    spec = animal_model_spec(y, ones(q, 1), sparse(1.0I, q, q), Ainv;
                             ids = ped.ids, method = :REML)

    # An aligned-tail match makes the default recursion execute its SIMD branch.
    # Check this structural precondition on both fixed-point factors.
    function aligned_tail_count(ch)
        L = sparse(ch.L)
        cp, rv = L.colptr, L.rowval
        count = 0
        for j in 1:size(L, 1)
            cs, ce = cp[j], cp[j + 1] - 1
            m = ce - cs
            for p in 1:(m - 1)
                ip = rv[cs + p]
                pcs, pce = cp[ip], cp[ip + 1] - 1
                ntail = m - p
                count += (pce - pcs) >= ntail &&
                         rv[pcs + 1] == rv[cs + p + 1] &&
                         rv[pcs + ntail] == rv[cs + m]
            end
        end
        return count
    end

    function evaluator(strict_order)
        calls = Ref(0)
        trace = (ch, Q, p) -> begin
            calls[] += 1
            strict_order ? HSquared._selinv_trace_against(ch, Q, p, true) :
                           HSquared.selinv_trace_against(ch, Q, p)
        end
        return trace, calls
    end

    function strict_selected_inverse_diagonal(ch)
        Zvals, colptr, _, perm, n = HSquared._selinv_zvals(ch; strict_order = true)
        diagonal = Vector{Float64}(undef, n)
        for j in 1:n
            diagonal[perm[j]] = Zvals[colptr[j]]
        end
        return diagonal
    end

    controls = (iterations = 100, tol = 1e-8, em_warmup = 0)
    for (a, e) in ((0.8, 1.2), (1.5, 0.6))
        lhs, = HSquared._sparse_mme_system(spec, a, e)
        ch = cholesky(Symmetric(lhs); check = true)
        @test aligned_tail_count(ch) > 0
        strict_trace = HSquared._selinv_trace_against(ch, Ainv, 1, true)
        simd_trace = HSquared.selinv_trace_against(ch, Ainv, 1)
        @test isapprox(strict_trace, simd_trace; rtol = TRACE_RTOL)

        strict_evaluator, strict_calls = evaluator(true)
        simd_evaluator, simd_calls = evaluator(false)
        initial = (sigma_a2 = a, sigma_e2 = e)
        strict = HSquared._fit_ai_reml_diagnostics(spec; initial,
                                                   merge(controls, (iterations = 1,))...,
                                                   trace_evaluator = strict_evaluator)
        simd = HSquared._fit_ai_reml_diagnostics(spec; initial,
                                                 merge(controls, (iterations = 1,))...,
                                                 trace_evaluator = simd_evaluator)
        @test strict_calls[] > 0 && simd_calls[] > 0
        @test strict.diagnostics.boundary_score_fallbacks == 0
        @test simd.diagnostics.boundary_score_fallbacks == 0
        strict_score = (strict.diagnostics.ai_score_a, strict.diagnostics.ai_score_e)
        simd_score = (simd.diagnostics.ai_score_a, simd.diagnostics.ai_score_e)
        @test all(isfinite, strict_score)
        @test all(isfinite, simd_score)
        @test all(isapprox.(strict_score, simd_score;
                            rtol = SCORE_RTOL, atol = SCORE_ATOL))
        @test all(isfinite, strict.diagnostics.last_newton_step)
        @test all(isfinite, simd.diagnostics.last_newton_step)
        @test all(isapprox.(strict.diagnostics.last_newton_step,
                            simd.diagnostics.last_newton_step;
                            rtol = STEP_RTOL, atol = STEP_ATOL))

        # The same score comparison must reject a deliberately biased trace.
        perturbed_evaluator = (ch, Q, p) ->
            1.01 * HSquared._selinv_trace_against(ch, Q, p, true)
        perturbed = HSquared._fit_ai_reml_diagnostics(
            spec; initial,
            merge(controls, (iterations = 1,))...,
            trace_evaluator = perturbed_evaluator,
        )
        perturbed_score = (perturbed.diagnostics.ai_score_a,
                           perturbed.diagnostics.ai_score_e)
        @test !all(isapprox.(strict_score, perturbed_score;
                             rtol = SCORE_RTOL, atol = SCORE_ATOL))
    end

    strict_evaluator, strict_calls = evaluator(true)
    simd_evaluator, simd_calls = evaluator(false)
    initial = (sigma_a2 = 1.0, sigma_e2 = 1.0)
    strict = HSquared._fit_ai_reml_diagnostics(spec; initial, controls...,
                                               trace_evaluator = strict_evaluator)
    simd = HSquared._fit_ai_reml_diagnostics(spec; initial, controls...,
                                             trace_evaluator = simd_evaluator)
    @test strict_calls[] > 0 && simd_calls[] > 0
    @test strict.diagnostics.boundary_score_fallbacks == 0
    @test simd.diagnostics.boundary_score_fallbacks == 0
    @test strict.fit.converged && simd.fit.converged
    @test strict.diagnostics.termination_reason == "score_tolerance"
    @test simd.diagnostics.termination_reason == "score_tolerance"
    for key in (:sigma_a2, :sigma_e2)
        strict_value = getproperty(strict.fit.variance_components, key)
        simd_value = getproperty(simd.fit.variance_components, key)
        @test strict_value > 0.05 && simd_value > 0.05
        @test isapprox(strict_value, simd_value; rtol = FIT_RTOL)
    end
    @test isapprox(strict.fit.likelihood.loglik, simd.fit.likelihood.loglik;
                   atol = LOGLIK_ATOL)
    strict_pev = prediction_error_variance(strict.fit; method = :selinv).values
    simd_pev = prediction_error_variance(simd.fit; method = :selinv).values
    @test all(isfinite, strict_pev) && all(>(0), strict_pev)
    @test all(isfinite, simd_pev) && all(>(0), simd_pev)
    @test all(isapprox.(strict_pev, simd_pev; rtol = PEV_RTOL))

    # Compare strict and default PEV diagonals from one common fitted MME, then
    # confirm that this shared-point reference agrees with the reported PEV.
    lhs, = HSquared._sparse_mme_system(
        spec, strict.fit.variance_components.sigma_a2,
        strict.fit.variance_components.sigma_e2,
    )
    ch = HSquared._selinv_cholesky(Symmetric(lhs), "W1-05 parity test MME")
    nfixed = size(spec.X, 2)
    strict_diag = strict_selected_inverse_diagonal(ch)[(nfixed + 1):end]
    simd_diag = HSquared.takahashi_diag(ch)[(nfixed + 1):end]
    @test all(isapprox.(strict_diag, simd_diag; rtol = PEV_RTOL))
    @test all(isapprox.(strict_pev, strict_diag; rtol = PEV_RTOL))
end

println("W105_FIT_PARITY_PASS")
