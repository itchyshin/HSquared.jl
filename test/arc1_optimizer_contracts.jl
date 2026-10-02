using LinearAlgebra
using Random
using Test
using HSquared

if !isdefined(HSquared, :_arc1_fa_spectral_context)
    Base.include(HSquared, joinpath(@__DIR__, "..", "src", "arc1_fa.jl"))
end

function _arc1_optimizer_fixture()
    rng = MersenneTwister(810204)
    n = 8
    ped = HSquared.normalize_pedigree(collect(1:n),
        [0, 0, 0, 0, 1, 1, 2, 3], [0, 0, 0, 0, 2, 3, 3, 4])
    Ainv = Matrix(HSquared.pedigree_inverse(ped))
    A = Matrix(inv(Symmetric(Ainv)))
    Z = Matrix{Float64}(I, n, n)
    B = Z * A * transpose(Z)
    X = ones(n, 1)
    λ = [0.62, -0.44, 0.31, -0.53]
    ψ = [0.24, 0.33, 0.29, 0.21]
    G = λ * transpose(λ) + Diagonal(ψ)
    R = [0.7 0.08 0.03 0.0; 0.08 0.8 0.06 0.02;
         0.03 0.06 0.75 0.04; 0.0 0.02 0.04 0.72]
    V = kron(B, G) + kron(Matrix{Float64}(I, n, n), R)
    μ = repeat(reshape([0.2, 0.7, -0.4, 1.0], 1, 4), n, 1)
    Y = μ + reshape(cholesky(Symmetric(V)).L * randn(rng, 4n), 4, n)'
    (; Y, X, Z, Ainv, A, B, ped, λ, ψ, G, R)
end

function _arc1_optimizer_params(λ, ψ, R)
    L = Matrix(cholesky(Symmetric(R)).L)
    rp = Float64[]
    for j in 1:4, i in j:4
        push!(rp, i == j ? log(L[i, j]) : L[i, j])
    end
    vcat(λ, log.(ψ .- HSquared.FA_UNIQUENESS_FLOOR), rp)
end

function _arc1_direct_linesearch(f, derivative; x0 = 0.0, alpha = 1.0,
                                 max_domain_restarts = 32,
                                 max_callback_requests = 256, make_pair = nothing)
    NLS = HSquared.Optim.NLSolversBase
    x = [Float64(x0)]
    g! = function (g, z)
        g[1] = derivative(z[1])
        g
    end
    df = NLS.OnceDifferentiable(z -> f(z[1]), g!, x)
    phi0, grad0 = NLS.value_gradient!(df, x)
    dphi0 = grad0[1]
    xnew = copy(x)
    stats = HSquared._Arc1LineSearchStats()
    options = (; max_domain_restarts, max_callback_requests)
    ls = make_pair === nothing ? HSquared._Arc1DomainHagerZhang(stats; options...) :
        HSquared._Arc1DomainHagerZhang(stats; options..., make_pair)
    result = try
        (value = ls(df, x, [1.0], alpha, xnew, phi0, dphi0), error = nothing)
    catch err
        (value = nothing, error = err)
    end
    (; result..., x, xnew, df, stats, phi0, dphi0)
end

@testset "ARC1 optimizer and opt-in policy contracts" begin
    @testset "spectral context caches record rotations outside evaluations" begin
        d = _arc1_optimizer_fixture()
        built = HSquared._arc1_fa_spectral_context(d.Y, d.X, d.B)
        @test built.status == :ok
        ctx = built.context
        @test length(ctx.design_blocks) == size(d.Y, 1)
        @test length(ctx.response_blocks) == size(d.Y, 1)
        @test ctx.df == 4 * size(d.Y, 1) - 4 * size(d.X, 2)
        p = _arc1_optimizer_params(d.λ, d.ψ, d.R)
        one = HSquared._arc1_fa_exact_objective_gradient(ctx, p, 1)
        two = HSquared._arc1_fa_exact_objective_gradient(ctx, p, 1)
        @test one.status == :ok
        @test two.objective == one.objective
        @test two.gradient == one.gradient
        @test one.objective ≈ one.raw_objective / ctx.df atol = 1e-12 rtol = 0
    end

    @testset "BFGS reports its independently recomputed final gradient" begin
        d = _arc1_optimizer_fixture()
        ctx = HSquared._arc1_fa_spectral_context(d.Y, d.X, d.B).context
        p = _arc1_optimizer_params(d.λ, d.ψ, d.R)
        out = HSquared._arc1_fa_bfgs(ctx, p, 1; iterations = 2)
        @test out.algorithm == :bfgs_hager_zhang
        @test out.iterations <= 2
        @test length(out.phat) == 18
        @test out.final_gradient_inf_norm isa Real
        @test out.objective ≈ out.raw_objective / ctx.df atol = 1e-10 rtol = 0
        @test out.numerical_gradient_status == :ok
        @test length(out.numerical_gradient_inf_norms) == 2
        @test length(out.numerical_gradient_discrepancies) == 2
        @test out.line_search_stats.objective_evaluations > 0
        @test out.line_search_stats.objective_evaluations <= out.line_search_stats.callback_requests
        @test out.accepted == (out.optimizer_converged && out.line_search_success &&
                               out.final_gradient_inf_norm <= 1e-6 &&
                               maximum(out.numerical_gradient_inf_norms) <= 5e-6 &&
                               maximum(out.numerical_gradient_discrepancies) <= 5e-6)
    end

    @testset "invalid proposal sentinels and nonconverged points cannot pass" begin
        d = _arc1_optimizer_fixture()
        ctx = HSquared._arc1_fa_spectral_context(d.Y, d.X, d.B).context
        p = _arc1_optimizer_params(d.λ, d.ψ, d.R)
        pinvalid = copy(p)
        pinvalid[end - 9] = -1000.0
        out = HSquared._arc1_fa_bfgs(ctx, pinvalid, 1; iterations = 2)
        @test !out.accepted
        @test out.status == :failed
        @test out.final_status == :invalid_proposal

        # A finite optimizer result with an inaccurate final score must fail
        # the policy criterion, regardless of the optimizer's status flag.
        forced = HSquared._arc1_fa_assess_optimizer_result(
            (; phat = p, optimizer_converged = true, iterations = 1,
               line_search_success = true,
               optimizer_status = "forced_converged"), ctx, 1)
        @test !forced.accepted
        @test forced.optimizer_converged
        @test forced.optimizer_assessment_status == :numerical_gradient_failure
        @test occursin("gradient", forced.optimizer_assessment_reason)
        @test forced.final_gradient_inf_norm > 1e-6
    end

    @testset "guarded Hager-Zhang restarts only on invalid trials" begin
        # The endpoints are valid, while secant/bisection trials through the
        # open interval are outside the objective domain.
        bad_interval(x) = 0.74 < x < 0.76
        f(x) = bad_interval(x) ? Inf : (x - 0.75)^2
        df(x) = bad_interval(x) ? -0.5 : 2(x - 0.75)
        recovered = _arc1_direct_linesearch(f, df)
        @test recovered.error === nothing
        @test recovered.stats.domain_restarts > 0
        @test recovered.stats.rejected_trials > 0
        @test recovered.stats.callback_requests <= 256
        @test recovered.stats.objective_evaluations <= recovered.stats.callback_requests
        step, value = recovered.value
        @test isfinite(step) && isfinite(value)
        @test recovered.xnew[1] ≈ step atol = 1e-12
        @test 0.1 * recovered.dphi0 >= (value - recovered.phi0) / step
        @test 2(step - 0.75) >= 0.9 * recovered.dphi0

        # A finite value with a nonfinite directional derivative must follow
        # the same guarded restart path.
        slope(x) = 0.45 < x < 0.55 ? NaN : 2(x - 1)
        nonfinite_slope = _arc1_direct_linesearch(x -> (x - 1)^2, slope; alpha = 0.5)
        @test nonfinite_slope.error === nothing
        @test nonfinite_slope.stats.domain_restarts > 0
        @test nonfinite_slope.stats.rejected_trials > 0

        # An invalid open ray exhausts the restart allowance. Optim receives
        # alpha=0 and both its trial vector and differentiated cache return to
        # the original feasible point.
        always_bad(x) = x > 0 ? Inf : -x
        always_bad_grad(x) = -1.0
        exhausted = _arc1_direct_linesearch(always_bad, always_bad_grad;
            max_domain_restarts = 1, max_callback_requests = 256)
        @test exhausted.error isa HSquared.Optim.LineSearches.LineSearchException
        @test exhausted.error.alpha == 0.0
        @test exhausted.stats.domain_restarts == 1
        @test exhausted.xnew == [0.0]
        value0, gradient0 = HSquared.Optim.NLSolversBase.value_gradient!(exhausted.df, exhausted.x)
        @test value0 == 0.0
        @test gradient0 == [-1.0]

        # Callback exhaustion is a distinct bounded refusal and must also
        # restore the state before Optim sees the failure.
        budgeted = _arc1_direct_linesearch(always_bad, always_bad_grad;
            max_domain_restarts = 32, max_callback_requests = 1)
        @test budgeted.error isa HSquared.Optim.LineSearches.LineSearchException
        @test budgeted.error.alpha == 0.0
        @test budgeted.stats.callback_requests == 1
        @test budgeted.xnew == [0.0]

        # A regular quadratic still returns an independently verified Wolfe
        # step and does not need a domain restart.
        valid = _arc1_direct_linesearch(x -> (x - 1)^2, x -> 2(x - 1))
        @test valid.error === nothing
        @test valid.value[1] ≈ 1.0 atol = 1e-12
        @test valid.stats.domain_restarts == 0
        @test valid.stats.rejected_trials == 0

        # An unexpected exception at ARC1's final value/gradient check must
        # propagate only after restoring xnew and the differentiated cache.
        callback_calls = Ref(0)
        final_error = _arc1_direct_linesearch(x -> (x - 1)^2, x -> 2(x - 1);
            make_pair = function (df, xnew, x0, direction)
                phi = alpha -> (alpha - 1)^2
                phidphi = alpha -> begin
                    if isapprox(alpha, 1.0; atol = 1e-12, rtol = 0)
                        callback_calls[] += 1
                        callback_calls[] == 2 && error("unexpected final callback failure")
                    end
                    ((alpha - 1)^2, 2(alpha - 1))
                end
                phi, phidphi
            end)
        @test final_error.error isa ErrorException
        @test occursin("unexpected final callback failure", sprint(showerror, final_error.error))
        @test callback_calls[] == 2
        @test final_error.xnew == [0.0]
        value0, gradient0 = HSquared.Optim.NLSolversBase.value_gradient!(final_error.df, final_error.x)
        @test value0 == 1.0
        @test gradient0 == [-2.0]
        @test final_error.stats.rejected_trials == 0
    end

    @testset "frozen derived starts and opt-in API boundaries" begin
        d = _arc1_optimizer_fixture()
        diagonal = (; genetic_covariance = Matrix(Diagonal([0.8, 1.1, 0.9, 1.3])),
                    residual_covariance = d.R)
        starts = HSquared._arc1_derived_starts(diagonal)
        @test length(starts) == 16
        @test length(unique([s.name for s in starts])) == 16
        for a in starts
            @test a.loading[1] > 0
            @test all(a.uniqueness .> HSquared.FA_UNIQUENESS_FLOOR)
            @test diag(a.loading * transpose(a.loading) + Diagonal(a.uniqueness)) ≈
                  diag(diagonal.genetic_covariance) atol = 1e-12 rtol = 0
            @test a.params[9:18] == HSquared._cov_to_chol_params(d.R, 4)
        end
        @test length(unique(Tuple(sign.(s.loading)) for s in starts[1:8])) == 8
        @test all(all(isapprox.(starts[i].loading ./ starts[i + 8].loading,
                               fill(0.1 / 0.7, 4); atol = 1e-12, rtol = 0))
                  for i in 1:8)

        @test HSquared._ARC1_SOURCE_IDENTITY isa String
        @test length(HSquared._ARC1_SOURCE_IDENTITY) == 64
        bad_iterations = HSquared.select_fa_rank(d.Y, d.X, d.Z, d.ped;
            optimizer_policy = "arc1_v1", iterations = 1_999)
        @test bad_iterations.selection_status == :unsupported_input
        @test occursin("2,000", bad_iterations.reason)
        @test bad_iterations.optimizer_policy == "arc1_v1"
        @test bad_iterations.optimizer_policy_version == 1
        @test bad_iterations.source_identity == HSquared._ARC1_SOURCE_IDENTITY
        @test bad_iterations.optimizer_algorithm == :bfgs_hager_zhang
        bad_policy = HSquared.select_fa_rank(d.Y, d.X, d.Z, d.ped;
            optimizer_policy = "custom")
        @test bad_policy.selection_status == :unsupported_input
        @test occursin("unknown optimizer_policy", bad_policy.reason)
        matrix_policy = try
            HSquared.fit_multivariate_reml(d.Y, d.X, d.Z, d.Ainv;
                genetic_structure = :factor_analytic, rank = 1,
                optimizer_policy = "arc1_v1")
            nothing
        catch err
            err
        end
        @test matrix_policy isa ArgumentError
        @test occursin("validated Pedigree", sprint(showerror, matrix_policy))
        initial_policy = try
            HSquared.fit_multivariate_reml(d.Y, d.X, d.Z, d.ped;
                genetic_structure = :factor_analytic, rank = 1,
                optimizer_policy = "arc1_v1", initial = (; G0 = d.G, R0 = d.R))
            nothing
        catch err
            err
        end
        @test initial_policy isa ArgumentError
        @test occursin("truth starts", sprint(showerror, initial_policy))
    end

    @testset "complete frozen attempt ledger survives interruption" begin
        d = _arc1_optimizer_fixture()
        ledger = Ref{Any}(nothing)
        interrupted_runner = (ctx, p, k, name) -> throw(InterruptException())
        @test_throws InterruptException HSquared._arc1_select_fa_rank(
            d.Y, d.X, d.Z, d.ped; ledger_sink = ledger,
            attempt_runner = interrupted_runner)
        @test ledger[] !== nothing
        @test length(ledger[].attempts) == 19
        @test ledger[].optimizer_policy == "arc1_v1"
        @test ledger[].optimizer_policy_version == 1
        @test ledger[].source_identity == HSquared._ARC1_SOURCE_IDENTITY
        @test ledger[].optimizer_algorithm == :bfgs_hager_zhang
        @test ledger[].optimizer_iterations == 2_000
        @test ledger[].starts_planned == 19
        @test ledger[].starts_attempted == 1
        @test count(a -> a.attempted, ledger[].attempts) == 1
        @test count(a -> a.status == :unattempted, ledger[].attempts) == 18
        @test only(filter(a -> a.rank == 0, ledger[].attempts)).status == :interrupted
        @test occursin("optimizer start", ledger[].reason)
    end

    @testset "a better finite failed K1 receipt blocks selection" begin
        d = _arc1_optimizer_fixture()
        diagonal_G, diagonal_R = Ref{Any}(nothing), Ref{Any}(nothing)
        diagonal_objective = Ref(Inf)
        find_better = function (objective, start)
            candidates = Vector{Vector{Float64}}()
            for loading_scale in (0.0, 0.25, 0.5, 1.0, 1.5),
                uniqueness_shift in (-2.0, -1.0, 0.0, 1.0, 2.0),
                residual_shift in (-1.0, 0.0, 1.0, 2.0)
                p = copy(start)
                p[1:4] .*= loading_scale
                p[5:8] .+= uniqueness_shift
                p[9:end] .+= residual_shift
                push!(candidates, p)
            end
            values = [objective(p) for p in candidates]
            i = argmin(values)
            candidates[i], values[i]
        end
        runner = function (ctx, params0, rank, start_id)
            raw_objective(p, k) = HSquared._arc1_fa_exact_objective_gradient(ctx, p, k).raw_objective
            if rank == 0
                p = copy(params0)
                p[1:4] .-= 2.0
                p[5:end] .+= 1.5
                diagonal_G[] = HSquared._fa_rank_cov(p[1:4], 0)[1]
                diagonal_R[] = HSquared._chol_params_to_cov(p[5:end], 4)
                value = raw_objective(p, 0)
                diagonal_objective[] = value
                return (; phat = p, objective = value, converged = true,
                    iterations = 1, optimizer_status = "injected weak K0")
            elseif start_id == :default
                p, value = find_better(x -> raw_objective(x, 1), params0)
                value < diagonal_objective[] - 1e-3 || error("fixture lacks better finite K1 receipt")
                return (; phat = p, objective = value, converged = true,
                    optimizer_converged = true, line_search_success = false,
                    optimizer_assessment_status = :line_search_failure,
                    optimizer_assessment_reason = "injected line search failure",
                    iterations = 1, optimizer_status = "better failed K1")
            end
            g = diag(diagonal_G[])
            loading = [0.1 * (-1.0)^(i - 1) * sqrt(g[i] - HSquared.FA_UNIQUENESS_FLOOR) for i in 1:4]
            psi = g .- loading.^2
            p = vcat(loading, log.(psi .- HSquared.FA_UNIQUENESS_FLOOR),
                HSquared._cov_to_chol_params(diagonal_R[], 4))
            return (; phat = p, objective = raw_objective(p, 1), converged = true,
                iterations = 1, optimizer_status = "eligible nested K1")
        end
        ledger = Ref{Any}(nothing)
        result = HSquared._arc1_select_fa_rank(d.Y, d.X, d.Z, d.ped;
            ledger_sink = ledger, attempt_runner = runner)
        @test result.selection_status == :unavailable
        @test occursin("better finite unaccepted K1", result.reason)
        @test result.source_identity == HSquared._ARC1_SOURCE_IDENTITY
        @test ledger[].source_identity == HSquared._ARC1_SOURCE_IDENTITY
        failed = only(filter(a -> a.rank == 1 && a.start_id == :default, result.attempts))
        @test failed.status == :failed
        @test failed.optimizer_converged
        @test failed.optimizer_assessment_status == :line_search_failure
        @test failed.optimizer_assessment_reason == "injected line search failure"
        @test failed.loglik > result.candidate_summary[2].loglik
    end
end
