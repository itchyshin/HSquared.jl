using Test, HSquared, LinearAlgebra, SparseArrays

# The production module include is owned by the integration lane. This test is
# therefore runnable against the frozen source without changing src/HSquared.jl.
const ARC1_SOURCE = joinpath(@__DIR__, "..", "src", "arc1_profiles.jl")
if !isfile(ARC1_SOURCE)
    @testset "Arc1 profile source is present" begin
        @test isfile(ARC1_SOURCE)
    end
else
    isdefined(HSquared, :_arc1_profile_context) || Base.include(HSquared, ARC1_SOURCE)
const H = HSquared

function _arc1_test_data()
    na = 6
    n = 2na
    z = sparse(1:n, repeat(1:na, inner = 2), ones(n), n, na)
    A = Matrix{Float64}(I, na, na)
    for i in 2:na
        A[i, i - 1] = A[i - 1, i] = 0.16
    end
    Ainv = inv(A)
    X = hcat(ones(n), collect(range(-1.0, 1.0; length = n)))
    y = [0.4 + 0.2 * i + 0.1 * sin(1.7i) + 0.3 * (-1)^i for i in 1:n]
    return y, X, z, Ainv, A
end

function _arc1_dense_reml_oracle(y, X, Z, A, Va, Vpe, Ve)
    V = Va .* (Z * A * Z') + Vpe .* (Z * Z') + Ve .* Matrix{Float64}(I, length(y), length(y))
    F = cholesky(Symmetric(Matrix(V)); check = true)
    ViX = F \ X
    Viy = F \ y
    C = Symmetric(X' * ViX)
    FC = cholesky(C; check = true)
    beta = FC \ (X' * Viy)
    residual = y - X * beta
    q = dot(residual, F \ residual)
    logdet_v = 2sum(log, diag(F.L))
    logdet_c = 2sum(log, diag(FC.L))
    n, p = length(y), size(X, 2)
    return (loglik = -0.5 * (logdet_v + logdet_c + q), beta = beta)
end

function _arc1_bigfloat_dense_reml_oracle(y, X, Z, A, Va, Vpe, Ve)
    by, bX, bZ, bA = BigFloat.(y), BigFloat.(X), BigFloat.(Matrix(Z)), BigFloat.(A)
    n = length(by)
    V = BigFloat(Va) .* (bZ * bA * bZ') + BigFloat(Vpe) .* (bZ * bZ') +
        BigFloat(Ve) .* Matrix{BigFloat}(I, n, n)
    F = cholesky(Symmetric(V))
    ViX, Viy = F \ bX, F \ by
    FC = cholesky(Symmetric(bX' * ViX))
    beta = FC \ (bX' * Viy)
    residual = by - bX * beta
    q = dot(residual, F \ residual)
    loglik = -BigFloat(0.5) * (2sum(log, diag(F.L)) +
                               2sum(log, diag(FC.L)) + q)
    return (loglik = Float64(loglik), beta = Float64.(beta))
end

@testset "Arc1 repeatability profile exact objective" begin
    y, X, Z, Ainv, A = _arc1_test_data()
    context = H._arc1_profile_context(y, X, Z, Ainv)

    @testset "positive components agree with independent dense REML oracle" begin
        for (Va, Vpe, Ve) in ((0.3, 0.2, 0.5), (1.1, 0.05, 0.7))
            got = H._arc1_profile_reml(context, Va, Vpe, Ve)
            expected = _arc1_dense_reml_oracle(y, X, Z, A, Va, Vpe, Ve)
            @test got.status == :ok
            @test got.loglik ≈ expected.loglik atol = 1e-10
            @test got.beta ≈ expected.beta atol = 1e-10
            @test got.loglik_convention == :reml_omit_2pi
            @test !got.loglik_comparable_across_routes
        end
    end

    @testset "exact additive and permanent zero faces remain evaluable" begin
        for (Va, Vpe, Ve) in ((0.0, 0.4, 0.6), (0.3, 0.0, 0.7), (0.0, 0.0, 1.0))
            got = H._arc1_profile_reml(context, Va, Vpe, Ve)
            expected = _arc1_dense_reml_oracle(y, X, Z, A, Va, Vpe, Ve)
            @test got.status == :ok
            @test got.loglik ≈ expected.loglik atol = 1e-10
            @test got.beta ≈ expected.beta atol = 1e-10
        end
    end

    @testset "unphenotyped ancestors retain full-pedigree covariance marginal" begin
        n_animal, n_observed = 8, 6
        A_full = Matrix{Float64}(I, n_animal, n_animal) .+ 0.08
        A_observed = A_full[3:end, 3:end]
        n = 2n_observed
        Xfull = hcat(ones(n), collect(range(-1.0, 1.0; length = n)))
        yfull = [0.2 * i + 0.15 * cos(0.9i) for i in 1:n]
        observed_index = repeat(3:n_animal, inner = 2)
        Zfull = sparse(1:n, observed_index, ones(n), n, n_animal)
        Zobserved = sparse(1:n, repeat(1:n_observed, inner = 2), ones(n), n, n_observed)
        full_context = try
            H._arc1_profile_context(yfull, Xfull, Zfull, inv(A_full))
        catch
            nothing
        end
        @test full_context !== nothing
        if full_context !== nothing
            observed_context = H._arc1_profile_context(
                yfull, Xfull, Zobserved, inv(A_observed))
            full_fit = H._arc1_profile_reml(full_context, 0.3, 0.2, 0.5)
            observed_fit = H._arc1_profile_reml(observed_context, 0.3, 0.2, 0.5)
            @test full_fit.status == observed_fit.status == :ok
            @test full_fit.loglik ≈ observed_fit.loglik atol = 1e-10
        end
    end

    @testset "zero residual variance reports a singular proposal" begin
        got = H._arc1_profile_reml(context, 0.3, 0.2, 0.0)
        @test got.status == :singular_proposal
        @test !isfinite(got.loglik)
    end

    @testset "analytic total-scale profile and ratio parameterizations" begin
        proportions = (0.3, 0.2, 0.5)
        scale = H._arc1_profile_scale(context, proportions)
        V0 = proportions[1] .* (Z * A * Z') + proportions[2] .* (Z * Z') +
             proportions[3] .* Matrix{Float64}(I, length(y), length(y))
        F0 = cholesky(Symmetric(Matrix(V0)); check = true)
        ViX0, Viy0 = F0 \ X, F0 \ y
        P_y = Viy0 - ViX0 * ((X' * ViX0) \ (X' * Viy0))
        @test scale ≈ dot(y, P_y) / (length(y) - size(X, 2)) rtol = 1e-10
        h = H._arc1_components_at_ratio(:heritability, 0.25, 1.7, 0.4)
        t = H._arc1_components_at_ratio(:repeatability, 0.65, 1.7, 0.3)
        @test h == (sigma_a2 = 1.7 * 0.25,
                    sigma_pe2 = 1.7 * 0.75 * 0.4,
                    sigma_e2 = 1.7 * 0.75 * 0.6)
        @test t == (sigma_a2 = 1.7 * 0.65 * 0.3,
                    sigma_pe2 = 1.7 * 0.65 * 0.7,
                    sigma_e2 = 1.7 * 0.35)
        @test h.sigma_a2 / sum(values(h)) ≈ 0.25
        @test (t.sigma_a2 + t.sigma_pe2) / sum(values(t)) ≈ 0.65
    end

    @testset "profile likelihood is stable to large fixed-effect shifts" begin
        proportions = (0.3, 0.2, 0.5)
        shift = X * [1.0e7, -2.0e7]
        shifted_y = y + shift
        base_fit = H._arc1_profile_reml(context, proportions...)
        shifted_context = H._arc1_profile_context(shifted_y, X, Z, Ainv)
        shifted_fit = H._arc1_profile_reml(shifted_context, proportions...)
        base_scale = H._arc1_profile_scale(context, proportions)
        shifted_scale = H._arc1_profile_scale(shifted_context, proportions)
        base_components = H._arc1_components_at_ratio(:heritability, 0.25, base_scale, 0.4)
        shifted_components = H._arc1_components_at_ratio(:heritability, 0.25, shifted_scale, 0.4)

        @test shifted_fit.loglik ≈ base_fit.loglik atol = 1e-6
        @test shifted_scale ≈ base_scale atol = 1e-7
        @test shifted_components.sigma_a2 ≈ base_components.sigma_a2 atol = 1e-7
        @test shifted_components.sigma_pe2 ≈ base_components.sigma_pe2 atol = 1e-7
        @test shifted_components.sigma_e2 ≈ base_components.sigma_e2 atol = 1e-7
    end

    @testset "paired reduction preserves record and animal order and dense oracle" begin
        components = (0.3, 0.2, 0.5)
        reference = H._arc1_profile_reml(context, components...)
        record_order = [7, 2, 11, 4, 9, 1, 12, 3, 8, 5, 10, 6]
        record_context = H._arc1_profile_context(y[record_order], X[record_order, :],
                                                 Z[record_order, :], Ainv)
        record_fit = H._arc1_profile_reml(record_context, components...)
        animal_order = [6, 2, 5, 1, 4, 3]
        animal_context = H._arc1_profile_context(y, X, Z[:, animal_order],
            Ainv[animal_order, animal_order])
        animal_fit = H._arc1_profile_reml(animal_context, components...)
        @test record_fit.loglik ≈ reference.loglik atol = 1e-10
        @test record_fit.beta ≈ reference.beta atol = 1e-10
        @test animal_fit.loglik ≈ reference.loglik atol = 1e-10
        @test animal_fit.beta ≈ reference.beta atol = 1e-10

        repeated = H._arc1_profile_context(y, X, Z, Matrix{Float64}(I, 6, 6))
        repeated_fit = H._arc1_profile_reml(repeated, components...)
        @test repeated_fit.loglik ≈ _arc1_dense_reml_oracle(
            y, X, Z, Matrix{Float64}(I, 6, 6), components...).loglik atol = 1e-10
        @test repeated_fit.beta ≈ _arc1_dense_reml_oracle(
            y, X, Z, Matrix{Float64}(I, 6, 6), components...).beta atol = 1e-10

        tiny_fit = H._arc1_profile_reml(context, 0.3, 0.2, 1e-10)
        tiny_oracle = _arc1_bigfloat_dense_reml_oracle(y, X, Z, A, 0.3, 0.2, 1e-10)
        @test tiny_fit.status == :ok
        @test tiny_fit.loglik ≈ tiny_oracle.loglik atol = 1e-6
        @test tiny_fit.beta ≈ tiny_oracle.beta atol = 1e-6
    end

    @testset "paired reduced analytic gradient matches finite differences" begin
        components = [0.3, 0.2, 0.5]
        result = H._arc1_profile_objective_gradient(context, components)
        @test result.loglik ≈ _arc1_dense_reml_oracle(y, X, Z, A, components...).loglik atol = 1e-10
        @test result.beta ≈ _arc1_dense_reml_oracle(y, X, Z, A, components...).beta atol = 1e-10
        @test result.objective ≈ -result.loglik / context.residual_df atol = 1e-12
        for i in eachindex(components)
            step = 1e-6 * components[i]
            plus, minus = copy(components), copy(components)
            plus[i] += step
            minus[i] -= step
            fp = -H._arc1_profile_reml(context, plus...).loglik / context.residual_df
            fm = -H._arc1_profile_reml(context, minus...).loglik / context.residual_df
            natural = (fp - fm) / (2step)
            @test result.component_gradient[i] ≈ natural rtol = 2e-5 atol = 2e-7
            @test result.log_gradient[i] ≈ natural * components[i] rtol = 2e-5 atol = 2e-7
        end

        face = H._arc1_profile_objective_gradient(context, [0.0, 0.2, 0.5];
                                                   free_indices = [2, 3])
        @test length(face.log_gradient) == 2
        for (j, i) in pairs([2, 3])
            step = 1e-6 * components[i]
            plus = [0.0, 0.2, 0.5]
            minus = copy(plus)
            plus[i] += step
            minus[i] -= step
            fp = -H._arc1_profile_reml(context, plus...).loglik / context.residual_df
            fm = -H._arc1_profile_reml(context, minus...).loglik / context.residual_df
            natural = (fp - fm) / (2step)
            @test face.component_gradient[i] ≈ natural rtol = 2e-5 atol = 2e-7
            @test face.log_gradient[j] ≈ natural * [0.0, 0.2, 0.5][i] rtol = 2e-5 atol = 2e-7
        end
    end

    @testset "confidence-set scan preserves disconnected components" begin
        score(x) = (x - 0.2) * (x - 0.4) * (x - 0.6) * (x - 0.8)
        grid = collect(0.0:0.1:1.0)
        scan = H._arc1_segments_from_scores(grid, score.(grid), score; tolerance = 1e-7)
        @test scan.status == :ok
        @test length(scan.segments) == 2
        @test scan.segments[1][1] ≈ 0.2 atol = 1e-7
        @test scan.segments[1][2] ≈ 0.4 atol = 1e-7
        @test scan.segments[2][1] ≈ 0.6 atol = 1e-7
        @test scan.segments[2][2] ≈ 0.8 atol = 1e-7
    end

    @testset "unresolved root gaps remain unresolved" begin
        score(x) = x - 0.5
        scan = H._arc1_segments_from_scores([0.0, 1.0], [-0.5, 0.5],
                                             x -> x == 0.5 ? NaN : score(x);
                                             tolerance = 1e-7)
        @test scan.status == :unresolved_search
        @test isempty(scan.segments)
    end

    @testset "root termination follows bracket width rather than LR residual" begin
        score(x) = x - 0.5000000001
        scan = H._arc1_segments_from_scores([0.0, 1.0], [score(0.0), score(1.0)],
                                             score; tolerance = 1e-7)
        @test scan.status == :ok
        @test scan.root_terminations == [:bracket_tolerance]
        @test scan.roots[1] ≈ 0.5000000001 atol = 1e-7
        adjacent = [1.0e16, nextfloat(1.0e16)]
        unresolved = H._arc1_segments_from_scores(adjacent, [-1.0, 1.0],
            x -> x == adjacent[1] ? -1.0 : 1.0; tolerance = 1e-6)
        @test unresolved.status == :unresolved_search
        @test unresolved.root_terminations == [:representable_limit]
    end

    @testset "adaptive midpoints use target-scale geometry" begin
        @test H._arc1_midpoint(:heritability, 0.2, 0.8) == 0.5
        @test H._arc1_midpoint(:additive_variance, 0.25, 4.0) == 1.0
    end

    @testset "bounded Brent certifies its final bracket with Optim keywords" begin
        search = H._arc1_bounded_brent(x -> (x - 0.37)^2, 0.0, 1.0;
            x_tolerance = 1e-7, likelihood_tolerance = 1e-8, max_evaluations = 2000)
        @test search.status == :ok
        @test search.certified
        @test search.evaluations <= 2000
        @test search.bracket[2] - search.bracket[1] <= 1e-7
        @test search.likelihood_spread <= 1e-8
    end

    @testset "analytic singular endpoints are excluded without nuisance failure" begin
        score(x) = x == 0.0 || x == 1.0 ? Inf : (x - 0.3) * (x - 0.7)
        grid = [0.0, 0.5, 1.0]
        scan = H._arc1_segments_from_scores(grid, score.(grid), score; tolerance = 1e-7)
        @test scan.status == :ok
        @test length(scan.segments) == 1
        @test scan.segments[1][1] ≈ 0.3 atol = 1e-7
        @test scan.segments[1][2] ≈ 0.7 atol = 1e-7
    end

    @testset "common unrestricted maximum is enforced" begin
        @test H._arc1_point_fit_not_optimal(-4.0, -4.0 + 1.01e-7)
        @test !H._arc1_point_fit_not_optimal(-4.0, -4.0 + 0.99e-7)
        @test H._arc1_raw_competitor_is_competitive(
            (converged = false, loglik = -4.0 + 0.5e-8, hit_bound = true), -4.0)
        @test !H._arc1_raw_competitor_is_competitive(
            (converged = false, loglik = -4.0, hit_bound = false), -4.0)
        @test H._arc1_raw_competitor_is_competitive(
            (converged = false, loglik = -4.0 + 1.1e-8, hit_bound = false), -4.0)
    end

    @testset "raw nuisance polishing maximum reaches the shared five-target guard" begin
        point_loglik = 10.0
        raw_mock_context = (residual_df = 5,)
        candidate = (; loglik=point_loglik, max_valid_loglik=point_loglik,
            components=[1.0, 1.0, 1.0], converged=false, hit_bound=true,
            hit_bound_components=[(component=2, side=:lower, value=1e-13)],
            gradient_norm=2e-6, finite_difference_error=0.0,
            analytic_gradient_valid=true, line_search_failed=false,
            optimizer_status="controlled failed start", iterations=20)
        bfgs_runner = (ctx, base, free, starts, scale) -> candidate
        scalar_profile_runner = (ctx, make_components, scale; kwargs...) -> begin
            components = make_components(1.0)
            (; loglik=point_loglik, max_valid_loglik=point_loglik,
               components, converged=true, gradient_norm=0.0,
               optimizer_status="controlled face", hit_bound=false,
               status=:ok, candidates=Any[], value=1.0,
               physical_zero_endpoint_certificate=nothing)
        end
        loglik_runner = (ctx, components) -> (point_loglik, :ok)
        gradient_runner = (ctx, components; kwargs...) ->
            (; component_gradient=zeros(3), loglik=point_loglik)
        certificate_runner = (args...) ->
            (; status=:projected_gradient_unresolved,
               max_valid_loglik=point_loglik)
        polish_runner = (ctx, candidate, index, scale, df, faces, intersection,
                         initial; maximum_seen, kwargs...) -> begin
            maximum_seen[] = point_loglik + 2e-7
            (; status=:better_probe_likelihood,
               continuation=(; status=:better_probe_likelihood,
                   parent_candidate_index=candidate.candidate_index,
                   max_valid_loglik=maximum_seen[]))
        end

        for target in (:additive_variance, :permanent_environment_variance,
                       :residual_variance)
            raw = H._arc1_raw_nuisance(raw_mock_context, target, 1.0, 1.0;
                bfgs_runner, scalar_profile_runner, loglik_runner,
                gradient_runner, certificate_runner, polish_runner)
            @test raw.status == :nuisance_unresolved
            @test raw.max_valid_loglik == point_loglik + 2e-7
            state = H._Arc1ProfileState(nothing, 1.0, point_loglik,
                Dict{Symbol,Dict{Float64,Any}}(), Dict{Symbol,Int}(), -Inf, Any[])
            @test H._arc1_include_valid_profile_max!(state, raw) == point_loglik + 2e-7
            targets = Dict{Symbol,Any}(target_name =>
                (confidence_set=[(0.0, 1.0)], status=:finite_grid_resolved,
                 search_status=:finite_grid_resolved, formed=true)
                for target_name in H._ARC1_PROFILE_TARGETS)
            @test H._arc1_apply_point_fit_guard!(targets, point_loglik,
                state.max_constrained_loglik)
            @test all(targets[t].search_status == :point_fit_not_optimal
                      for t in H._ARC1_PROFILE_TARGETS)
            @test all(!targets[t].formed && targets[t].confidence_set === nothing
                      for t in H._ARC1_PROFILE_TARGETS)
        end
    end

    @testset "resolved raw candidates report the polished gradient" begin
        raw_mock_context = (residual_df = 5,)
        calls = Ref(0)
        bfgs_runner = (ctx, base, free, starts, scale) -> begin
            calls[] += 1
            bound = calls[] == 1
            (; loglik=2.0, max_valid_loglik=2.0, components=[1.0, 1.0, 1.0],
               converged=false, hit_bound=bound,
               hit_bound_components=bound ? [(component=2, side=:lower, value=1e-13)] : Any[],
               gradient_norm=2e-6, finite_difference_error=0.0,
               analytic_gradient_valid=true, line_search_failed=false,
               optimizer_status="controlled failed start", iterations=20)
        end
        scalar_profile_runner = (ctx, make_components, scale; kwargs...) -> begin
            components = make_components(1.0)
            (; loglik=2.0, max_valid_loglik=2.0, components,
               converged=false, gradient_norm=0.0, optimizer_status="face unresolved",
               hit_bound=true, status=:nuisance_unresolved, candidates=Any[], value=1.0,
               physical_zero_endpoint_certificate=nothing)
        end
        certificate_runner = (args...) ->
            (; status=:projected_gradient_unresolved, max_valid_loglik=2.0)
        polish_runner = (ctx, candidate, index, scale, df, faces, intersection,
                         initial; maximum_seen, kwargs...) -> begin
            (; status=:resolved_projected_face_polish, loglik=2.0,
               components=[1.0, 0.0, 1.0], max_valid_loglik=2.0,
               boundary_certificate=(; status=:resolved_lower_bound_by_zero_face),
               continuation=(; continuation_gradient_norm=7e-7,
                   parent_candidate_index=candidate.candidate_index,
                   max_valid_loglik=2.0))
        end
        raw = H._arc1_raw_nuisance(raw_mock_context, :additive_variance, 1.0, 1.0;
            bfgs_runner, scalar_profile_runner,
            loglik_runner=(ctx, components)->count(>(0), components) == 1 ?
                (-Inf, :singular_proposal) : (2.0, :ok),
            gradient_runner=(ctx, components; kwargs...)->(;component_gradient=zeros(3)),
            certificate_runner, polish_runner)
        search = only(filter(x -> x.kind == :raw_nuisance_search, raw.nuisance_statuses))
        @test search.resolved_by_projected_face_polish == 1
        @test search.best_certified.gradient_norm == 7e-7
        @test search.best_certified.polished_gradient_norm == 7e-7
        @test search.best_certified.original_gradient_norm == 2e-6
    end

    @testset "unresolved profiles still update the shared valid maximum" begin
        state = H._Arc1ProfileState(nothing, 1.0, -2.0,
            Dict{Symbol,Dict{Float64,Any}}(), Dict{Symbol,Int}(), -2.0, Any[])
        profile = (loglik = -Inf, max_valid_loglik = -1.5,
                   status = :nuisance_unresolved)
        @test H._arc1_include_valid_profile_max!(state, profile) == -1.5
        @test H._arc1_point_fit_not_optimal(-2.0, state.max_constrained_loglik)
    end

    function fake_profile_state(scorefn; s0 = 1.0, failfn = x -> false,
                                budget = 4097)
        state = H._Arc1ProfileState(nothing, s0, 0.0,
            Dict{Symbol,Dict{Float64,Any}}(), Dict{Symbol,Int}(), 0.0, Any[])
        calls = Ref(0)
        cache = Dict{Float64,Any}()
        evaluator = function (x)
            x = Float64(x)
            haskey(cache, x) && return cache[x]
            if calls[] >= budget
                return (loglik = -Inf, status = :unresolved_search_budget,
                        nuisance_statuses = Any[:target_evaluation_budget])
            end
            calls[] += 1
            for target in H._ARC1_PROFILE_TARGETS
                state.evaluation_counts[target] = calls[]
            end
            if failfn(x)
                cache[x] = (loglik = -Inf, status = :nuisance_unresolved,
                            nuisance_statuses = Any[:synthetic_nuisance_failure])
            else
                ll = -(scorefn(x) + H._ARC1_PROFILE_CUTOFF_95) / 2
                cache[x] = (loglik = ll, status = :ok, nuisance_statuses = Any[])
            end
            return cache[x]
        end
        return state, evaluator
    end

    @testset "artificial profile scans retain components and classify failures" begin
        # Two disjoint confidence components must both survive the scan.
        disconnected(x) = 1.0e6 * (x - 0.2) * (x - 0.4) * (x - 0.6) * (x - 0.8)
        state, evaluator = fake_profile_state(disconnected)
        result = H._arc1_target_search(state, :heritability, 0.5;
                                      profile_evaluator = evaluator)
        @test result.search_status == :finite_grid_resolved
        @test length(result.segments) == 2
        @test result.segments[1][1] ≈ 0.2 atol = 1e-6
        @test result.segments[2][2] ≈ 0.8 atol = 1e-6

        # A sampled narrow peak triggers breadth-first refinement and remains in
        # the point set used to identify its roots.
        shallow(x) = 10.0 - 20.0 * exp(-((x - 0.5025) / 0.0008)^2)
        state, evaluator = fake_profile_state(shallow)
        result = H._arc1_target_search(state, :heritability, 0.5;
                                      profile_evaluator = evaluator)
        @test result.refinements > 0
        @test result.search_status == :finite_grid_resolved
        @test length(result.segments) >= 1

        # A sampled likelihood maximum at an existing grid vertex is detected
        # even when its LR score is not cutoff-adjacent.
        vertex_peak(x) = 1.0 + 1000.0 * (x - 0.5)^2
        state, evaluator = fake_profile_state(vertex_peak)
        result = H._arc1_target_search(state, :heritability, 0.5;
                                      profile_evaluator = evaluator)
        @test result.refinements > 0
        @test result.evaluated > 401

        # The raw rail includes the upper-domain component and the full tail.
        upper_component(x) = x > 9e5 ? -0.1 : 1.0
        state, evaluator = fake_profile_state(upper_component)
        result = H._arc1_target_search(state, :additive_variance, 1.0;
                                      profile_evaluator = evaluator)
        @test result.domain[2] == 1.0e6
        @test any(segment -> segment[2] == 1.0e6, result.segments)
        @test result.search_status == :unbracketed_limits

        # Nuisance failures under the evaluation cap retain a distinct cause.
        state, evaluator = fake_profile_state(x -> 100.0 * ((x - 0.5)^2 - 0.0004);
                                              failfn = x -> 0.49 < x < 0.51)
        result = H._arc1_target_search(state, :heritability, 0.5;
                                      profile_evaluator = evaluator)
        @test result.search_status == :nuisance_unresolved
        @test result.evaluated < 4097
        @test result.nuisance_statuses[1].counts[:nuisance] > 0
        @test length(result.nuisance_statuses[1].examples[:nuisance]) <= 3

        # A genuine cap exhaustion refuses rather than returning a partial scan.
        state, evaluator = fake_profile_state(x -> x - 0.5; budget = 3)
        result = H._arc1_target_search(state, :heritability, 0.5;
                                      profile_evaluator = evaluator)
        @test result.search_status == :unresolved_search_budget
        @test result.evaluated == 3

        # Raw resolution is measured in octaves for positive values and on the
        # declared first gap in the original variance units.
        raw_grid = H._arc1_target_grid(:additive_variance, 0.4, 1.0)
        @test raw_grid[1] == 0.0
        @test raw_grid[2] <= 1e-6
        @test maximum(log2(raw_grid[i + 1] / raw_grid[i])
                      for i in 2:length(raw_grid)-1) <= 1 / 8 + 1e-10
    end

    @testset "ratio nuisance accepts zero genetic boundary and excludes singular ratio one" begin
        diagnostics = Any[]
        h0 = H._arc1_ratio_nuisance(context, :heritability, 0.0,
                                    H._arc1_profile_scale(context, (0.3, 0.2, 0.5)), diagnostics)
        h1 = H._arc1_ratio_nuisance(context, :heritability, 1.0,
                                    H._arc1_profile_scale(context, (0.3, 0.2, 0.5)), diagnostics)
        hmid = H._arc1_ratio_nuisance(context, :heritability, 0.75,
                                      H._arc1_profile_scale(context, (0.3, 0.2, 0.5)), diagnostics)
        t0 = H._arc1_ratio_nuisance(context, :repeatability, 0.0,
                                    H._arc1_profile_scale(context, (0.3, 0.2, 0.5)), diagnostics)
        @test h0.status == :ok
        @test isfinite(h0.loglik)
        @test h1.status == :singular_proposal
        @test hmid.status == :ok
        @test hmid.nuisance_statuses[1].winner_status == :brent
        @test 0.0 < hmid.nuisance_statuses[1].best_allocation < 1.0
        @test t0.status == :ok
        @test isfinite(t0.loglik)
        face = H._arc1_scalar_profile_max(context, v -> [0.0, 0.0, v],
                                          H._arc1_profile_scale(context, (0.3, 0.2, 0.5)))
        @test face.status == :ok
        @test any(c -> c.status == :brent, face.candidates)
        @test face.max_valid_loglik >= face.loglik
    end

    @testset "raw lower-bound contact resolves only through certified exact-zero face" begin
        df = 20.0
        s0 = 1.0
        ll0 = -100.0
        slope = 0.02
        curvature = 0.001
        q(x) = -ll0 / df + slope * x + curvature * x^2
        objective(components) = (-df * q(components[2] / s0), :ok)
        gradient(components; free_indices) = begin
            x = components[2] / s0
            component_gradient = [0.0, (slope + 2curvature * x) / s0, 0.0]
            (component_gradient, log_gradient = component_gradient[free_indices] .*
                components[free_indices])
        end
        face = (status = :ok, zero_index = 2, loglik = ll0,
                components = [2.0, 0.0, 3.0])
        candidate = (loglik = ll0, components = [2.0, 1e-13, 3.0],
            max_valid_loglik = ll0,
            converged = false, optimizer_converged = true, gradient_norm = 0.0,
            finite_difference_error = 0.0, analytic_gradient_valid = true,
            line_search_failed = false,
            free_indices = [2, 3], finite_difference_errors = Dict(2 => Inf, 3 => 0.0),
            hit_bound_components = [(component = 2, side = :lower, value = 1e-13)])
        certificate = H._arc1_zero_bound_face_certificate(candidate, 1, s0, df,
            [face], nothing, objective, gradient)
        @test certificate.status == :resolved_lower_bound_by_zero_face
        @test certificate.components == [2.0, 0.0, 3.0]
        @test certificate.face_loglik == ll0
        @test certificate.projected_log_gradient_norm <= 1e-6
        @test certificate.analytic_active_derivatives[2] > 5e-6
        @test all(all(>=(0), estimates) for estimates in values(certificate.forward_derivatives))
        @test maximum(abs(fd - certificate.analytic_active_derivatives[index])
                      for (index, estimates) in certificate.forward_derivatives
                      for fd in estimates) <= 5e-6
        bad_remaining_gradient(components; free_indices) = begin
            component_gradient = [0.0, slope / s0, 2e-6]
            (component_gradient, log_gradient = component_gradient[free_indices] .*
                components[free_indices])
        end
        gradient_refusal = H._arc1_zero_bound_face_certificate(candidate, 1, s0, df,
            [face], nothing, objective, bad_remaining_gradient)
        @test gradient_refusal.status == :projected_gradient_unresolved
        @test gradient_refusal.original_loglik == gradient_refusal.projected_loglik ==
              gradient_refusal.face_loglik
        @test gradient_refusal.projected_gradient_norm > 1e-6

        negative_objective(components) = (df * (0.1 * components[2] / s0), :ok)
        negative_gradient(components; free_indices) = begin
            component_gradient = [0.0, -0.1 / s0, 0.0]
            (component_gradient, log_gradient = component_gradient[free_indices] .*
                components[free_indices])
        end
        rejected = H._arc1_zero_bound_face_certificate(candidate, 1, s0, df,
            [merge(face, (loglik = 0.0,))], nothing, negative_objective, negative_gradient)
        @test rejected.status != :resolved_lower_bound_by_zero_face
        mismatched_face = merge(face, (loglik = ll0 + 1e-7,))
        @test H._arc1_zero_bound_face_certificate(candidate, 1, s0, df,
            [mismatched_face], nothing, objective, gradient).status == :face_likelihood_mismatch
        disallowed_residual = merge(candidate, (components = [2.0, 3.0, 1e-13],
            free_indices = [2, 3], finite_difference_errors = Dict(2 => 0.0, 3 => Inf),
            hit_bound_components = [(component = 3, side = :lower, value = 1e-13)],))
        @test H._arc1_zero_bound_face_certificate(disallowed_residual, 1, s0, df,
            [face], nothing, objective, gradient).status == :ineligible_contact
        upper = merge(candidate, (hit_bound_components =
            [(component = 2, side = :upper, value = 1e6)],))
        @test H._arc1_zero_bound_face_certificate(upper, 1, s0, df,
            [face], nothing, objective, gradient).status != :resolved_lower_bound_by_zero_face
        flat_objective(components) = (-df * (components[2] / s0)^2, :ok)
        flat_gradient(components; free_indices) = begin
            component_gradient = [0.0, 2components[2] / (s0^2), 0.0]
            (component_gradient, log_gradient = component_gradient[free_indices] .*
                components[free_indices])
        end
        flat_candidate = merge(candidate, (loglik = 0.0,))
        @test H._arc1_zero_bound_face_certificate(flat_candidate, 1, s0, df,
            [merge(face, (loglik = 0.0,))], nothing,
            flat_objective, flat_gradient).status != :resolved_lower_bound_by_zero_face

        # The intersection is the only matching reduced model for two hits.
        both = merge(candidate, (components = [1e-13, 1e-13, 3.0],
            free_indices = [1, 2], finite_difference_errors = Dict(1 => Inf, 2 => Inf),
            hit_bound_components = [(component = 1, side = :lower, value = 1e-13),
                                    (component = 2, side = :lower, value = 1e-13)]))
        intersection = (status = :ok, loglik = ll0, components = [0.0, 0.0, 3.0])
        both_objective(components) = (-df * q(components[1] / s0 + components[2] / s0), :ok)
        both_gradient(components; free_indices) = begin
            component_gradient = fill((slope + 2curvature *
                (components[1] + components[2]) / s0) / s0, 3)
            component_gradient[3] = 0.0
            (component_gradient, log_gradient = component_gradient[free_indices] .*
                components[free_indices])
        end
        both_certificate = H._arc1_zero_bound_face_certificate(both, 3, s0, df,
            Any[], intersection, both_objective, both_gradient)
        @test both_certificate.status == :resolved_lower_bound_by_zero_face
        @test both_certificate.components == [0.0, 0.0, 3.0]

        # A matching final boundary likelihood cannot erase a better valid
        # interior value visited earlier by this same failed optimizer start.
        better_interior = merge(candidate, (max_valid_loglik = ll0 + 2e-8,))
        @test H._arc1_zero_bound_face_certificate(better_interior, 1, s0, df,
            [face], nothing, objective, gradient).status == :candidate_maximum_mismatch

        # The certified face, rather than the approximate projection, supplies
        # the accepted components and likelihood. The projection remains a
        # separate diagnostic.
        different_face = merge(face, (components = [2.0, 0.0, 3.25],))
        face_result = H._arc1_zero_bound_face_certificate(candidate, 1, s0, df,
            [different_face], nothing, objective, gradient)
        @test face_result.status == :resolved_lower_bound_by_zero_face
        @test face_result.components == different_face.components
        @test face_result.loglik == different_face.loglik
        @test face_result.projected_components == [2.0, 0.0, 3.0]
    end

    @testset "failed profile paths retain their best valid likelihood" begin
        state = H._Arc1ProfileState(nothing, 1.0, 0.0,
            Dict{Symbol,Dict{Float64,Any}}(), Dict{Symbol,Int}(), -Inf, Any[])
        @test H._arc1_include_valid_profile_max!(state,
            (loglik = -Inf, max_valid_loglik = 2.0, status = :nuisance_unresolved)) == 2.0
        @test H._arc1_point_fit_not_optimal(1.0, state.max_constrained_loglik)

        # A valid BFGS trial remains part of the shared maximum even if a later
        # optimizer callback throws and no final candidate is returned.
        failed_bfgs = H._arc1_bfgs_candidate(context, zeros(3), [1, 2, 3],
            [0.3, 0.2, 0.5], 1.0; optimizer_runner = (objective, gradient!, start) -> begin
                objective(start)
                objective(start .+ 0.001)
                error("synthetic optimizer exit after valid trials")
            end)
        @test failed_bfgs.loglik == -Inf
        @test isfinite(failed_bfgs.max_valid_loglik)
        failed_state = H._Arc1ProfileState(nothing, 1.0, 0.0,
            Dict{Symbol,Dict{Float64,Any}}(), Dict{Symbol,Int}(), -Inf, Any[])
        H._arc1_include_valid_profile_max!(failed_state, failed_bfgs)
        @test failed_state.max_constrained_loglik == failed_bfgs.max_valid_loglik
        @test H._arc1_point_fit_not_optimal(failed_bfgs.max_valid_loglik - 1e-6,
                                            failed_state.max_constrained_loglik)

        # A Brent exception still returns its best finite log-likelihood trial.
        failed_brent = H._arc1_bounded_brent(x -> x < 0.5 ? -12.0 :
            error("synthetic objective exception"), 0.0, 1.0;
            x_tolerance = 1e-7, max_evaluations = 20)
        @test failed_brent.result === nothing
        @test failed_brent.max_valid_loglik == 12.0
        cache = Dict(0.25 => 9.0, 0.4 => 11.0, 0.75 => 20.0)
        failed_ratio_no_result = (result = nothing, max_valid_loglik = 10.0)
        failed_ratio_uncertified = (result = :uncertified, max_valid_loglik = 12.0)
        @test H._arc1_unresolved_brent_max(cache, failed_ratio_no_result,
            0.0, 0.5) == 11.0
        @test H._arc1_unresolved_brent_max(cache, failed_ratio_uncertified,
            0.0, 0.5) == 12.0
        ratio_failure = (loglik = -Inf,
            max_valid_loglik = H._arc1_unresolved_brent_max(cache,
                failed_ratio_uncertified, 0.0, 0.5), status = :nuisance_unresolved)
        ratio_state = H._Arc1ProfileState(nothing, 1.0, 0.0,
            Dict{Symbol,Dict{Float64,Any}}(), Dict{Symbol,Int}(), -Inf, Any[])
        H._arc1_include_valid_profile_max!(ratio_state, ratio_failure)
        @test H._arc1_point_fit_not_optimal(11.0, ratio_state.max_constrained_loglik)

        # The raw-nuisance reduction must not drop a valid maximum merely
        # because every final result is marked failed.
        failed_candidates = [(loglik = -Inf, max_valid_loglik = 13.0),
                             (loglik = -Inf, max_valid_loglik = 12.0)]
        @test H._arc1_max_valid_profile_likelihood(failed_candidates) == 13.0
        @test H._arc1_raw_competitor_is_competitive(
            (converged = false, loglik = -Inf, max_valid_loglik = 13.0,
             hit_bound = false), 12.0)

        # Certificate likelihood and gradient probes share one maximum recorder.
        probe_max = Ref(-Inf)
        probe_ll(components) = (components[1], :ok)
        probe_gradient(components; free_indices) =
            (loglik = components[1] + 0.25,
             component_gradient = zeros(3), log_gradient = zeros(length(free_indices)))
        recorded_ll, recorded_gradient = H._arc1_profile_probe_recorders!(
            probe_max, probe_ll, probe_gradient)
        @test recorded_ll([4.0, 0.0, 1.0]) == (4.0, :ok)
        @test recorded_gradient([5.0, 0.0, 1.0]; free_indices = [3]).loglik == 5.25
        @test probe_max[] == 5.25

        # If a later certificate callback throws, earlier valid values survive
        # and still invalidate the shared point fit.
        throw_calls = Ref(0)
        throwing_ll(components) = (throw_calls[] += 1;
            throw_calls[] == 1 ? (components[1], :ok) :
            error("synthetic later certificate failure"))
        throwing_recorded_ll, _ = H._arc1_profile_probe_recorders!(
            probe_max, throwing_ll, probe_gradient)
        @test throwing_recorded_ll([7.0, 0.0, 1.0]) == (7.0, :ok)
        @test_throws ErrorException throwing_recorded_ll([8.0, 0.0, 1.0])
        @test probe_max[] == 7.0
        H._arc1_include_valid_profile_max!(state,
            (loglik = -Inf, max_valid_loglik = probe_max[], status = :nuisance_unresolved))
        @test state.max_constrained_loglik == 7.0
        @test H._arc1_point_fit_not_optimal(6.0, state.max_constrained_loglik)

        point_failure = H._arc1_point_failure_result(nothing, :heritability,
                                                     :point_fit_unconverged)
        @test hasproperty(point_failure, :point_fit_not_optimal)
        @test !point_failure.point_fit_not_optimal
    end

    @testset "physical zero endpoint certifies only a valid reduced scalar face" begin
        df, s0 = 20.0, 1.0
        q0, slope, curvature = 5.0, 0.02, 0.001
        endpoint = [0.0, 0.0, 3.0] # Va held at zero; Ve target fixed
        make_components(value) = [0.0, value, 3.0]
        q(components) = q0 + slope * components[2] / s0 +
                        curvature * (components[2] / s0)^2
        objective(components) = (-df * q(components), :ok)
        gradient(components; free_indices) = begin
            component_gradient = [0.0,
                (slope + 2curvature * components[2] / s0) / s0, 0.0]
            (loglik = -df * q(components), component_gradient = component_gradient,
             log_gradient = component_gradient[free_indices] .* components[free_indices])
        end
        lower = make_components(s0 * 2.0^-40)
        lower_ll = first(objective(lower))
        cert = H._arc1_physical_zero_endpoint_certificate(make_components, 2, 3, 1,
            s0, df, lower, lower_ll, Ref(lower_ll), objective, gradient)
        @test cert.status == :resolved_physical_zero_endpoint
        @test cert.components == endpoint
        @test cert.loglik == first(objective(endpoint))
        @test cert.analytic_derivative > 5e-6
        @test all(>=(0), cert.forward_derivatives)
        @test abs(cert.forward_derivatives[1] - cert.analytic_derivative) <= 5e-6
        @test abs(cert.forward_derivatives[2] - cert.analytic_derivative) <= 5e-6

        @test H._arc1_physical_zero_endpoint_certificate(make_components, 2, 3, 1,
            s0, df, lower, lower_ll, Ref(lower_ll + 2e-8), objective, gradient).status ==
            :better_probe_likelihood
        @test H._arc1_physical_zero_endpoint_certificate(make_components, 2, 3, 1,
            s0, df, lower, lower_ll + 2e-7, Ref(lower_ll), objective, gradient).status ==
            :lower_endpoint_likelihood_mismatch
        better_probe(components; free_indices) = merge(gradient(components; free_indices),
            (loglik = first(objective(endpoint)) + 2e-8,))
        @test H._arc1_physical_zero_endpoint_certificate(make_components, 2, 3, 1,
            s0, df, lower, lower_ll, Ref(lower_ll), objective, better_probe).status ==
            :better_probe_likelihood
        singular(components) = (NaN, :singular_proposal)
        @test H._arc1_physical_zero_endpoint_certificate(make_components, 2, 3, 1,
            s0, df, lower, lower_ll, Ref(lower_ll), singular, gradient).status ==
            :physical_zero_endpoint_invalid
        flat_gradient(components; free_indices) = merge(gradient(components; free_indices),
            (component_gradient = zeros(3),))
        @test H._arc1_physical_zero_endpoint_certificate(make_components, 2, 3, 1,
            s0, df, lower, lower_ll, Ref(lower_ll), objective, flat_gradient).status ==
            :endpoint_derivative_not_positive
        mismatch(components) = (first(objective(components)) + 1e-5, :ok)
        @test H._arc1_physical_zero_endpoint_certificate(make_components, 2, 3, 1,
            s0, df, lower, lower_ll, Ref(lower_ll), mismatch, gradient).status ==
            :lower_endpoint_likelihood_mismatch
        changed_other = [0.1, lower[2], 3.0]
        @test H._arc1_physical_zero_endpoint_certificate(make_components, 2, 3, 1,
            s0, df, changed_other, lower_ll, Ref(lower_ll), objective, gradient).status ==
            :fixed_components_mismatch
        @test H._arc1_physical_zero_endpoint_certificate(make_components, 3, 2, 1,
            s0, df, lower, lower_ll, Ref(lower_ll), objective, gradient).status ==
            :ineligible_zero_endpoint
    end

    @testset "certified physical-zero endpoint supersedes its artificial scalar endpoint" begin
        s0 = 1.0
        df = context.residual_df
        q0, slope, curvature = 2.0, 0.02, 0.001
        make_components(value) = [value, 0.0, 3.0]
        endpoint_ll = -df * q0
        function scalar_ll(components, bump)
            value = components[1]
            lower = s0 * 2.0^-40
            if isapprox(value, lower; rtol = 1e-12, atol = 0.0)
                return endpoint_ll + bump, :ok
            end
            x = value / s0
            return -df * (q0 + slope * x + curvature * x^2), :ok
        end
        scalar_gradient(components; free_indices) = begin
            x = components[1] / s0
            component_gradient = [(slope + 2curvature * x) / s0, 0.0, 0.0]
            (loglik = -df * (q0 + slope * x + curvature * x^2),
             component_gradient = component_gradient,
             log_gradient = component_gradient[free_indices] .* components[free_indices])
        end
        for bump in (0.0, 5e-9)
            result = H._arc1_scalar_profile_max(context, make_components, s0;
                physical_zero_component = 1, target_component = 3,
                held_zero_component = 2,
                profile_loglik_at = components -> scalar_ll(components, bump),
                profile_gradient_at = scalar_gradient)
            @test result.physical_zero_endpoint_certificate.status ==
                  :resolved_physical_zero_endpoint
            @test result.status == :ok
            @test result.value == 0.0
            @test result.winner_status == :physical_zero_endpoint
            @test !isempty(result.superseded_lower_endpoint_indices)
            artificial = result.candidates[only(result.superseded_lower_endpoint_indices)]
            @test artificial.loglik == endpoint_ll + bump
            @test result.max_valid_loglik == endpoint_ll + bump
        end
    end

    @testset "projected-face polish is one bounded continuation from its own projection" begin
        df, s0, ll0 = 20.0, 1.0, -100.0
        slope, curvature = 0.02, 0.001
        q(x) = -ll0 / df + slope * x + curvature * x^2
        objective(components) = (-df * q(components[2] / s0), :ok)
        exact_gradient(components; free_indices) = begin
            x = components[2] / s0
            component_gradient = [0.0, (slope + 2curvature * x) / s0, 0.0]
            (loglik = first(objective(components)), component_gradient = component_gradient,
             log_gradient = component_gradient[free_indices] .* components[free_indices])
        end
        initial_bad_gradient(components; free_indices) = begin
            g = exact_gradient(components; free_indices)
            component_gradient = copy(g.component_gradient)
            component_gradient[3] = 2e-6
            (loglik = g.loglik, component_gradient = component_gradient,
             log_gradient = component_gradient[free_indices] .* components[free_indices])
        end
        face = (status = :ok, zero_index = 2, loglik = ll0,
                components = [2.0, 0.0, 3.0])
        original = (candidate_index = 4, loglik = ll0,
            max_valid_loglik = ll0, components = [2.0, 1e-13, 3.0],
            converged = false, optimizer_converged = true, gradient_norm = 0.0,
            finite_difference_error = 0.0, analytic_gradient_valid = true,
            line_search_failed = false, free_indices = [2, 3],
            finite_difference_errors = Dict(2 => Inf, 3 => 0.0),
            hit_bound = true, iterations = 40,
            hit_bound_components = [(component = 2, side = :lower, value = 1e-13)])
        initial = H._arc1_zero_bound_face_certificate(original, 1, s0, df,
            [face], nothing, objective, initial_bad_gradient)
        @test initial.status == :projected_gradient_unresolved
        function polished_result(base, free, start, iterations; kwargs...)
            (loglik = ll0, max_valid_loglik = ll0, components = copy(base),
             free_indices = copy(free), converged = true, gradient_norm = 0.0,
             optimizer_converged = true, analytic_gradient_valid = true,
             line_search_failed = false, finite_difference_errors = Dict(3 => 0.0),
             finite_difference_error = 0.0, hit_bound = false,
             hit_bound_components = Any[], iterations = 100,
             objective_evaluations = 23, gradient_evaluations = 8,
             termination_code = :gradient_converged, stopped_by = :gradient,
             optimizer_status = "converged")
        end
        runner_calls = Ref(0)
        starts_seen = Ref{Any}(nothing)
        runner = (ctx, base, free, start, scale, budget) -> begin
            runner_calls[] += 1
            starts_seen[] = (copy(base), copy(free), copy(start), budget)
            polished_result(base, free, start, budget)
        end
        maximum_seen = Ref(ll0)
        result = H._arc1_projected_face_polish(context, original, 1, s0, df,
            [face], nothing, initial; maximum_seen, loglik_at = objective,
            gradient_at = exact_gradient, continuation_runner = runner)
        @test result.status == :resolved_projected_face_polish
        @test result.components == [2.0, 0.0, 3.0]
        @test result.loglik == ll0
        @test starts_seen[] == ([2.0, 0.0, 3.0], [3], [3.0], 1960)
        @test runner_calls[] == 1
        @test result.continuation.parent_candidate_index == 4
        @test result.continuation.original_iterations == 40
        @test result.continuation.continuation_iterations == 100
        @test result.continuation.combined_iterations == 140
        @test result.continuation.objective_evaluations == 23
        @test result.continuation.gradient_evaluations == 8
        @test original.components == [2.0, 1e-13, 3.0]
        @test original.loglik == ll0

        # Exhaustion does not invoke an optimizer or increase its allowance.
        exhausted = merge(original, (iterations = 2000,))
        exhausted_calls = Ref(0)
        no_runner = (args...) -> (exhausted_calls[] += 1; polished_result(args[2],
            args[3], args[4], args[6]))
        exhausted_result = H._arc1_projected_face_polish(context, exhausted, 1,
            s0, df, [face], nothing, initial; maximum_seen = Ref(ll0),
            loglik_at = objective, gradient_at = exact_gradient,
            continuation_runner = no_runner)
        @test exhausted_result.status == :iteration_budget_exhausted
        @test exhausted_result.continuation.parent_candidate_index == 4
        @test exhausted_calls[] == 0

        no_coordinates = merge(original, (free_indices=[1],))
        no_coordinates_result = H._arc1_projected_face_polish(context, no_coordinates,
            1, s0, df, [face], nothing, initial; maximum_seen=Ref(ll0),
            loglik_at=objective, gradient_at=exact_gradient)
        @test no_coordinates_result.status == :no_remaining_positive_coordinates
        @test no_coordinates_result.continuation.parent_candidate_index == 4

        exception_runner = (args...) -> error("controlled continuation exception")
        exception_result = H._arc1_projected_face_polish(context, original, 1,
            s0, df, [face], nothing, initial; maximum_seen=Ref(ll0),
            loglik_at=objective, gradient_at=exact_gradient,
            continuation_runner=exception_runner)
        @test exception_result.status == :continuation_exception
        @test exception_result.continuation.parent_candidate_index == 4
        @test occursin("controlled continuation exception",
                       exception_result.continuation.error)

        # A second bound contact is retained as a refusal.
        another_bound_runner = (ctx, base, free, start, scale, budget) ->
            merge(polished_result(base, free, start, budget),
                  (converged = false,
                   hit_bound_components = [(component = 3, side = :lower, value = 1e-13)]))
        another_bound = H._arc1_projected_face_polish(context, original, 1, s0,
            df, [face], nothing, initial; maximum_seen = Ref(ll0),
            loglik_at = objective, gradient_at = exact_gradient,
            continuation_runner = another_bound_runner)
        @test another_bound.status == :additional_bound_contact

        better_history_runner = (ctx, base, free, start, scale, budget) ->
            merge(polished_result(base, free, start, budget),
                  (max_valid_loglik = ll0 + 2e-8,))
        better_history_max = Ref(ll0)
        better_history = H._arc1_projected_face_polish(context, original, 1,
            s0, df, [face], nothing, initial; maximum_seen = better_history_max,
            loglik_at = objective, gradient_at = exact_gradient,
            continuation_runner = better_history_runner)
        @test better_history.status == :candidate_maximum_mismatch
        @test better_history_max[] == ll0 + 2e-8

        better_probe_gradient(components; free_indices) = merge(
            exact_gradient(components; free_indices), (loglik = ll0 + 2e-8,))
        better_probe_max = Ref(ll0)
        better_probe = H._arc1_projected_face_polish(context, original, 1,
            s0, df, [face], nothing, initial; maximum_seen = better_probe_max,
            loglik_at = objective, gradient_at = better_probe_gradient,
            continuation_runner = runner)
        @test better_probe.status == :better_probe_likelihood
        @test better_probe_max[] == ll0 + 2e-8

        failed_gradient_runner = (ctx, base, free, start, scale, budget) ->
            merge(polished_result(base, free, start, budget),
                  (converged = false, gradient_norm = 2e-6,))
        failed_gradient = H._arc1_projected_face_polish(context, original, 1,
            s0, df, [face], nothing, initial; maximum_seen = Ref(ll0),
            loglik_at = objective, gradient_at = exact_gradient,
            continuation_runner = failed_gradient_runner)
        @test failed_gradient.status == :continuation_unresolved

        failed_fd_runner = (ctx, base, free, start, scale, budget) ->
            merge(polished_result(base, free, start, budget),
                  (converged = false, finite_difference_errors = Dict(3 => 6e-6),))
        failed_fd = H._arc1_projected_face_polish(context, original, 1, s0,
            df, [face], nothing, initial; maximum_seen = Ref(ll0),
            loglik_at = objective, gradient_at = exact_gradient,
            continuation_runner = failed_fd_runner)
        @test failed_fd.status == :continuation_unresolved

        mismatch_runner = (ctx, base, free, start, scale, budget) ->
            merge(polished_result(base, free, start, budget),
                  (loglik = ll0 + 2e-7, max_valid_loglik = ll0 + 2e-7,))
        mismatch = H._arc1_projected_face_polish(context, original, 1, s0,
            df, [face], nothing, initial; maximum_seen = Ref(ll0),
            loglik_at = objective, gradient_at = exact_gradient,
            continuation_runner = mismatch_runner)
        @test mismatch.status == :face_likelihood_mismatch
    end

    @testset "raw nuisance optimizer only stops on the gradient" begin
        options = H._arc1_bfgs_options()
        @test options.iterations == 2000
        @test options.g_abstol == 1e-8
        @test options.f_reltol == 0.0
        @test options.x_abstol == 0.0
    end

    if get(ENV, "ARC1_SKIP_EXPENSIVE_PROFILE_WRAPPER", "0") != "1"
    @testset "all-five Arc1 profile wrapper reports one shared point maximum" begin
        fit = H._arc1_repeatability_profile_intervals(y, X, Z, Ainv)
        @test fit.point_fit_status == :ok
        @test !fit.point_fit_not_optimal
        @test Set(keys(fit.targets)) == Set(H._ARC1_PROFILE_TARGETS)
        @test fit.method_version == :arc1_profile_v1
        @test fit.loglik_convention == :reml_omit_2pi
        formed_count = 0
        for target_name in H._ARC1_PROFILE_TARGETS
            target_fit = fit.targets[target_name]
            @test target_fit.search_status in (:finite_grid_resolved, :nuisance_unresolved,
                :root_unresolved, :resolution_unresolved, :unbracketed_limits,
                :unresolved_search_budget, :unresolved_search, :point_fit_not_optimal)
            @test target_fit.formed == (target_fit.search_status == :finite_grid_resolved &&
                                        !isempty(target_fit.confidence_set))
            target_fit.formed && (formed_count += 1)
            @test length(target_fit.profile_diagnostics) == target_fit.evaluated
            @test target_fit.evaluated <= 4097
        end
        @test formed_count >= 1
        @test fit.targets[:repeatability].formed
        @test_throws ArgumentError H._arc1_repeatability_profile_intervals(y, X, Z, Ainv;
                                                                           level = 0.9)
        @test_throws ArgumentError H._arc1_repeatability_profile_intervals(y, X, Z, Ainv;
                                                                           cutoff = 3.0)
    end
    end
end
end
