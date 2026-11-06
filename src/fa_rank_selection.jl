# Experimental, explicit T4 pedigree Gaussian selector. This code deliberately
# leaves fit_multivariate_reml and its public fixed-rank parameter maps untouched.
const _FA_RANK_TAU = 1e-6
const _FA_RANK_RECHECK_TOL = 1e-8

_fa_rank_structure(k) = k == 0 ? :diagonal : :factor_analytic
_fa_rank_q(k) = k == 0 ? 14 : 18

function _fa_rank_optimizer_output(fit)
    return (; phat = fit.phat, objective = fit.raw_objective,
        converged = fit.optimizer_converged,
        optimizer_converged = fit.optimizer_converged,
        optimizer_assessment_status = fit.optimizer_assessment_status,
        optimizer_assessment_reason = fit.optimizer_assessment_reason,
        iterations = fit.iterations, optimizer_status = fit.optimizer_status,
        scaled_objective = fit.objective,
        final_gradient_inf_norm = fit.final_gradient_inf_norm,
        numerical_gradient_inf_norms = fit.numerical_gradient_inf_norms,
        numerical_gradient_discrepancies = fit.numerical_gradient_discrepancies,
        numerical_gradient_status = fit.numerical_gradient_status,
        numerical_gradient_failed_sides = fit.numerical_gradient_failed_sides,
        line_search_success = fit.line_search_success,
        line_search_terminal_reason = fit.line_search_terminal_reason,
        line_search_stats = fit.line_search_stats,
        algorithm = fit.algorithm, optimizer_assessment = fit)
end

function _fa_rank_score(ell0::Real, ell1::Real)
    D = 8 - 2 * (ell1 - ell0)
    tie = abs(D) <= _FA_RANK_TAU
    return (; criterion_difference = D, near_tie = tie,
            selected_rank = D < -_FA_RANK_TAU ? 1 : 0)
end

function _fa_rank_candidate(k; status = :unattempted, reason = nothing,
                            eligible = false, selected_start = nothing,
                            loglik = nothing, criterion = nothing,
                            converged = nothing, attempts_count = 0,
                            minimum_floor_distance = nothing, near_floor = nothing,
                            objective_range = nothing, g_relative_disagreement = nothing,
                            r_relative_disagreement = nothing)
    (; rank = k, structure = _fa_rank_structure(k), status, reason, eligible,
       selected_start, loglik, q = _fa_rank_q(k), penalty = 2 * _fa_rank_q(k),
       criterion, converged, attempts_count, minimum_floor_distance, near_floor,
       objective_range, g_relative_disagreement, r_relative_disagreement)
end

function _fa_rank_attempt(k, start_id, retry_index; status = :running, reason = nothing,
                          converged = nothing, optimizer_status = nothing,
                          optimizer_converged = nothing,
                          optimizer_assessment_status = nothing,
                          optimizer_assessment_reason = nothing,
                          failure_status = nothing,
                          optimizer_iterations = nothing, finite_objective = nothing,
                          finite_estimates = nothing, pd_genetic = nothing,
                          pd_residual = nothing, optimizer_objective = nothing,
                          loglik = nothing,
                          reevaluated_loglik = nothing, objective_discrepancy = nothing,
                          criterion = nothing, uniqueness = nothing,
                          floor_distances = nothing, near_floor = nothing,
                          eligible = false, selected_within_rank = false,
                          selected = false, genetic_covariance = nothing,
                          residual_covariance = nothing, genetic_loadings = nothing,
                          initial_parameters = nothing, estimated_parameters = nothing)
    (; rank = k, structure = _fa_rank_structure(k), start_id, retry_index,
       attempted = true,
       status, reason, converged, optimizer_status, optimizer_converged,
       optimizer_assessment_status, optimizer_assessment_reason, failure_status,
       optimizer_iterations,
       finite_objective, finite_estimates, pd_genetic, pd_residual,
       optimizer_objective, loglik,
       reevaluated_loglik, objective_discrepancy, q = _fa_rank_q(k),
       penalty = 2 * _fa_rank_q(k), criterion, uniqueness, floor_distances,
       near_floor, eligible, selected_within_rank, selected,
       genetic_covariance, residual_covariance, genetic_loadings,
       initial_parameters, estimated_parameters)
end

function _fa_rank_result(candidates, attempts; selection_status = :in_progress,
                         reason = nothing, selected_rank = nothing,
                         criterion_difference = nothing, near_tie = nothing,
                         boundary_sensitive = false, start_sensitive = false,
                         selected_fit = nothing, records = nothing,
                         design_fingerprint = nothing,
                         relationship_fingerprint = nothing,
                         kernel_ratio = nothing,
                         nesting_witness_discrepancy = nothing,
                         guard_results = (; schedule_complete = nothing,
                             better_unaccepted = nothing, nonnested = nothing,
                             nesting_witness = (; status = :not_evaluated,
                                 discrepancy = nothing, tolerance = _FA_RANK_RECHECK_TOL)))
    (; selection_status, reason, requested_ranks = (0, 1), selected_rank,
       criterion = :reml_aic_covariance, criterion_status = :experimental,
       q = (14, 18), penalties = (28, 36), criterion_difference,
       tie_tolerance = _FA_RANK_TAU, near_tie, records, design_fingerprint,
       relationship_fingerprint, kernel_ratio, nesting_witness_discrepancy,
       guard_results,
       candidate_summary = copy(candidates),
       attempts = copy(attempts), boundary_sensitive, start_sensitive,
       uncertainty_scope = :conditional_on_selected_rank, selected_fit)
end

function _fa_rank_publish!(sink, candidates, attempts; optimizer_policy = nothing,
                           optimizer_policy_version = nothing, source_identity = nothing,
                           requested_optimizer_policy = nothing,
                           actual_optimizer_policy = nothing,
                           covariance_representation = nothing,
                           kwargs...)
    snapshot = _fa_rank_result(candidates, attempts; kwargs...)
    if optimizer_policy !== nothing
        snapshot = merge(snapshot, (; optimizer_policy, optimizer_policy_version, source_identity,
            optimizer_algorithm = :bfgs_hager_zhang, optimizer_iterations = 2_000,
            optimizer_tolerance = 1e-8, final_scaled_gradient_tolerance = 1e-6,
            numerical_gradient_steps = (1e-4, 1e-5), numerical_gradient_tolerance = 5e-6,
            starts_planned = length(attempts), starts_attempted = count(a -> hasproperty(a, :attempted) && a.attempted, attempts)))
    end
    if requested_optimizer_policy == "arc1_v2"
        v2_identity = (; requested_optimizer_policy, actual_optimizer_policy,
            covariance_representation = _ARC1_FA_V2_REPRESENTATION,
            optimizer_policy = "arc1_v2", optimizer_policy_version = 2,
            source_identity = _ARC1_SOURCE_IDENTITY)
        attempts = [merge(a, v2_identity, (; actual_optimizer_policy =
            hasproperty(a, :actual_optimizer_policy) ? a.actual_optimizer_policy : nothing,
            optimizer_observations = hasproperty(a, :optimizer_observations) &&
                a.optimizer_observations !== nothing ? a.optimizer_observations : NamedTuple[],
            best_observed_loglik = hasproperty(a, :best_observed_loglik) ? a.best_observed_loglik : nothing,
            best_observation_certificate_status = hasproperty(a, :best_observation_certificate_status) ?
                a.best_observation_certificate_status : :unavailable,
            best_observation_accepted = hasproperty(a, :best_observation_accepted) ?
                a.best_observation_accepted : false))
            for a in attempts]
        candidates = [merge(c, v2_identity, (; actual_optimizer_policy =
            any(a -> a.rank == c.rank && a.attempted &&
                    hasproperty(a, :actual_optimizer_policy) &&
                    a.actual_optimizer_policy !== nothing, attempts) ? optimizer_policy : nothing))
            for c in candidates]
        snapshot = merge(snapshot, v2_identity, (; attempts, candidate_summary = copy(candidates)))
        if snapshot.selected_fit !== nothing
            snapshot = merge(snapshot, (; selected_fit = merge(snapshot.selected_fit, v2_identity)))
        end
    end
    sink === nothing || (sink[] = snapshot)
    return snapshot
end

# The selector's diagonal map shares the FA uniqueness floor exactly. The
# public :diagonal fit retains its older exp(theta) map.
function _fa_rank_cov(params, k)
    if k == 0
        ψ = _fa_uniqueness_from_unconstrained(params)
        return Matrix(Diagonal(ψ)), nothing, ψ
    end
    return _structured_genetic_params_to_cov(params, 4, :factor_analytic, 1)
end

function _fa_rank_objective(params, ctx, k)
    length(params) == _fa_rank_q(k) || return Inf
    try
        G, _, ψ = _fa_rank_cov(@view(params[1:(k == 0 ? 4 : 8)]), k)
        R = _chol_params_to_cov(@view(params[(k == 0 ? 5 : 9):end]), 4)
        all(isfinite, G) && all(isfinite, R) && all(isfinite, ψ) || return Inf
        minimum(ψ .- FA_UNIQUENESS_FLOOR) > 0 || return Inf
        isposdef(Symmetric(G)) && isposdef(Symmetric(R)) || return Inf
        v = -_mv_reml_loglik_core(ctx.y, ctx.Xfull, ctx.Zfull, ctx.A,
                                   ctx.indiv, length(ctx.y), G, R)
        return isfinite(v) ? v : Inf
    catch err
        err isa InterruptException && rethrow()
        (err isa PosDefException || err isa ArgumentError || err isa DomainError ||
         err isa OverflowError) && return Inf
        rethrow()
    end
end

# An independent same-covariance check: direct B⊗G + I⊗R, dense Cholesky GLS.
# It intentionally does not call the optimizer's covariance or REML builders.
function _fa_rank_dense_recheck(ctx, G, R)
    n = size(ctx.Y, 1)
    B = ctx.Z * ctx.A * transpose(ctx.Z)
    V = kron(B, G) + kron(Matrix{Float64}(I, n, n), R)
    F = cholesky(Symmetric(V); check = true)
    Xi = F \ ctx.Xfull
    M = cholesky(Symmetric(transpose(ctx.Xfull) * Xi); check = true)
    beta = M \ (transpose(ctx.Xfull) * (F \ ctx.y))
    resid = ctx.y - ctx.Xfull * beta
    return -0.5 * ((length(ctx.y) - size(ctx.Xfull, 2)) * log(2π) +
                    logdet(F) + logdet(M) + dot(resid, F \ resid))
end

# Orthonormal Helmert contrasts remove the trait intercepts. Since the full
# contrast is Q⊗I4, a two-kernel rank check needs only Q'ZA Z'Q versus I.
function _fa_rank_kernel_ratio(A, Z)
    n = size(Z, 1)
    Q = zeros(n, n - 1)
    for j in 1:(n - 1)
        d = sqrt(j * (j + 1))
        Q[1:j, j] .= 1 / d
        Q[j + 1, j] = -j / d
    end
    H = transpose(Q) * (Z * A * transpose(Z)) * Q
    J = Matrix{Float64}(I, n - 1, n - 1)
    hnorm = norm(H)
    isfinite(hnorm) && hnorm > 0 || return 0.0
    S = svdvals(hcat(vec(H) / hnorm, vec(J) / norm(J)))
    return all(isfinite, S) && S[1] > 0 ? S[end] / S[1] : 0.0
end

function _fa_rank_preflight(Y, X, Z, pedigree, ids, traits, iterations)
    Y isa AbstractMatrix && X isa AbstractMatrix && Z isa AbstractMatrix ||
        return "Y, X and Z must be matrices"
    n, t = size(Y)
    t == 4 || return "automatic FA rank selection requires four traits"
    n >= 3 || return "automatic FA rank selection requires at least three records"
    size(X) == (n, 1) || return "automatic FA rank selection requires one intercept column in X"
    size(Z) == (n, length(pedigree)) || return "Z must have one column per pedigree animal"
    iterations isa Integer && iterations > 0 || return "iterations must be a positive integer"
    try
        aids = _mv_labels(ids === nothing ? pedigree.ids : ids, length(pedigree), "ids")
        isequal(aids, pedigree.ids) || return "ids must equal the pedigree's canonical ID order"
        _mv_labels(traits, 4, "traits")
        Ym = Matrix{Float64}(Y)
        Xm = Matrix{Float64}(X)
        Zm = Matrix{Float64}(Z)
        all(isfinite, Ym) || return "Y must contain four complete finite Gaussian traits"
        all(isfinite, Xm) && all(==(1.0), Xm) ||
            return "X must be an all-ones intercept column"
        all(isfinite, Zm) || return "Z must contain finite unit entries"
        seen = Set{Int}()
        for i in 1:n
            active = findall(!iszero, @view Zm[i, :])
            length(active) == 1 && Zm[i, active[1]] == 1.0 ||
                return "each Z row must select exactly one pedigree animal with a unit entry"
            active[1] ∉ seen || return "repeated observed animals are unsupported"
            push!(seen, active[1])
        end
    catch err
        err isa InterruptException && rethrow()
        return "unsupported selector input: $(sprint(showerror, err))"
    end
    return nothing
end

function _fa_rank_context(Y, X, Z, pedigree, traits)
    Ym, Xm, Zm = Matrix{Float64}(Y), Matrix{Float64}(X), Matrix{Float64}(Z)
    Ainv = pedigree_inverse(pedigree)
    A = inv(Symmetric(Matrix(_check_relationship_precision(Ainv, length(pedigree)))))
    n = size(Ym, 1)
    y, Xfull, Zfull, indiv, _ = _mv_observed(Ym, Xm, Zm, n, 4, length(pedigree), 1)
    phen = [begin
        col = @view Ym[:, j]
        v = sum(abs2, col .- sum(col) / n) / (n - 1)
        isfinite(v) && v > 0 ? v : 1.0
    end for j in 1:4]
    tlabels = traits === nothing ? collect(1:4) : collect(traits)
    return (; Y = Ym, X = Xm, Z = Zm, A, y, Xfull, Zfull, indiv,
            phen, ids = pedigree.ids, traits = tlabels)
end

function _fa_rank_starts(ctx)
    Gbase = Matrix(Diagonal(0.5 .* ctx.phen))
    Rbase = Matrix(Diagonal(0.5 .* ctx.phen))
    # K0 follows the documented half-phenotypic-variance start where possible.
    # Tiny-scale traits need a strictly interior matched-floor start.
    g0 = max.(diag(Gbase), 2 * FA_UNIQUENESS_FLOOR)
    p0 = vcat(_fa_uniqueness_to_unconstrained(g0), _cov_to_chol_params(Rbase, 4))
    f0 = vcat(_structured_genetic_params0(Gbase, :factor_analytic, 1, 4, nothing),
              _cov_to_chol_params(Rbase, 4))
    L0 = reshape(sqrt.(max.(diag(Gbase), eps(Float64))), 4, 1)
    balanced = (; loadings = sqrt(0.5) .* L0,
                uniqueness = max.(0.5 .* ctx.phen, 2 * FA_UNIQUENESS_FLOOR),
                R0 = Rbase)
    f1 = vcat(_structured_genetic_params0(Gbase, :factor_analytic, 1, 4, balanced),
              _cov_to_chol_params(Rbase, 4))
    return p0, f0, f1
end

const _ARC1_K0_SPLIT_SCHEDULE = (0.05, 0.15, 0.3, 0.5, 0.7, 0.9)

function _arc1_k0_start_schedule(ctx, default_params)
    starts = NamedTuple[]
    floor = FA_UNIQUENESS_FLOOR
    for (index, split) in enumerate(_ARC1_K0_SPLIT_SCHEDULE)
        start_id = split == 0.5 ? :default : Symbol("split_$(split)")
        try
            params = if split == 0.5
                copy(default_params)
            else
                n = size(ctx.Y, 1)
                variance = [begin
                    column = @view ctx.Y[:, j]
                    observed = sum(abs2, column .- sum(column) / n) / (n - 1)
                    max(isfinite(observed) && observed > 0 ? observed : 1.0,
                        2 * floor)
                end for j in axes(ctx.Y, 2)]
                genetic_diagonal = max.(split .* variance, 2 * floor)
                residual_covariance = Matrix(Diagonal((1 - split) .* variance))
                all(x -> isfinite(x) && x > floor, genetic_diagonal) ||
                    throw(ArgumentError("K0 split does not leave positive uniqueness above the floor"))
                vcat(_fa_uniqueness_to_unconstrained(genetic_diagonal),
                     _cov_to_chol_params(residual_covariance, 4))
            end
            push!(starts, (; rank = 0, start_id, split, schedule_index = index,
                params, initialization_status = :ok, failure_reason = nothing))
        catch err
            err isa InterruptException && rethrow()
            push!(starts, (; rank = 0, start_id, split, schedule_index = index,
                params = Float64[], initialization_status = :invalid,
                failure_reason = sprint(showerror, err)))
        end
    end
    return starts
end

function _fa_rank_retry_params(diagonal_attempt)
    g = diag(diagonal_attempt.genetic_covariance)
    c = FA_UNIQUENESS_FLOOR
    all(x -> isfinite(x) && x > c, g) ||
        throw(ArgumentError("diagonal estimate cannot initialize an interior FA retry"))
    L = reshape([0.1 * (-1.0)^(i - 1) * sqrt(g[i] - c) for i in 1:4], 4, 1)
    ψ = g .- vec(L).^2
    all(isfinite, L) && all(!iszero, L) && all(x -> isfinite(x) && x > c, ψ) ||
        throw(ArgumentError("FA retry loading or uniqueness is not finite and strictly floor-admissible"))
    G = L * transpose(L) + Diagonal(ψ)
    isapprox(diag(G), g; atol = 1e-12, rtol = 1e-12) ||
        throw(ArgumentError("FA retry changed the diagonal covariance"))
    for i in 1:4, j in 1:4
        i == j && continue
        isapprox(G[i, j], L[i, 1] * L[j, 1]; atol = 1e-12, rtol = 1e-12) ||
            throw(ArgumentError("FA retry off-diagonal perturbation is inconsistent"))
    end
    return vcat(vec(L), _fa_uniqueness_to_unconstrained(ψ),
                _cov_to_chol_params(diagonal_attempt.residual_covariance, 4))
end

function _fa_rank_nesting_discrepancy(ctx, diagonal_attempt)
    if hasproperty(diagonal_attempt, :factor_state) && diagonal_attempt.factor_state !== nothing
        state = diagonal_attempt.factor_state
        params = vcat(zeros(4), state.parameters[1:4], state.parameters[5:14])
        nested = _arc1_fa_v2_exact_objective_gradient(ctx.spectral, params, 1)
        return nested.status == :ok ? abs(nested.loglik - diagonal_attempt.loglik) : Inf
    end
    g = diag(diagonal_attempt.genetic_covariance)
    p = vcat(zeros(4), _fa_uniqueness_to_unconstrained(g),
             _cov_to_chol_params(diagonal_attempt.residual_covariance, 4))
    nested = _fa_rank_objective(p, ctx, 1)
    return abs(nested + diagonal_attempt.loglik)
end

# Inject only this seam in policy/interruption tests. Ordinary calls use Optim.
function _fa_rank_optimize(objective, params0, iterations, rank, start_id)
    result = optimize(objective, params0, NelderMead(), Optim.Options(iterations = iterations))
    return (; phat = Optim.minimizer(result), objective = Optim.minimum(result),
            converged = Optim.converged(result), iterations = Optim.iterations(result),
            optimizer_status = Optim.converged(result) ? "converged" : "not_converged")
end

function _fa_rank_read_or(f, fallback)
    try
        return f()
    catch err
        err isa InterruptException && rethrow()
        return fallback
    end
end

function _arc1_fa_v2_valid_likelihood_observation(evaluation)
    evaluation === nothing && return false
    hasproperty(evaluation, :loglik) && isfinite(evaluation.loglik) || return false
    hasproperty(evaluation, :factor_state) && evaluation.factor_state !== nothing || return false
    evaluation.factor_state.factor_valid || return false
    evaluation.status == :ok && return true
    return evaluation.status == :failed && hasproperty(evaluation, :observation) &&
           evaluation.observation.status == :ok
end

function _arc1_fa_v2_retain_observation!(observations, params, evaluation;
                                         rank, start_id, retry_index, source_identity)
    _arc1_fa_v2_valid_likelihood_observation(evaluation) || return nothing
    coordinates = try Float64.(collect(params)) catch; return nothing end
    length(coordinates) == _fa_rank_q(rank) && all(isfinite, coordinates) || return nothing
    existing = findfirst(o -> isequal(o.coordinates, coordinates), observations)
    status = evaluation.status == :ok ? :ok : :likelihood_with_gradient_failure
    if existing !== nothing
        if status == :ok && observations[existing].evaluation_status != :ok
            observations[existing] = merge(observations[existing],
                (; evaluation_status = :ok, loglik = Float64(evaluation.loglik)))
        end
        return observations[existing]
    end
    identity = (; requested_optimizer_policy = "arc1_v2", actual_optimizer_policy = "arc1_v2",
        optimizer_policy = "arc1_v2", optimizer_policy_version = 2,
        covariance_representation = _ARC1_FA_V2_REPRESENTATION, source_identity,
        rank, start_id, retry_index)
    observation_id = bytes2hex(sha256(repr((identity, coordinates))))
    record = merge(identity, (; observation_id, coordinates,
        loglik = Float64(evaluation.loglik), evaluation_status = status,
        factor_valid = evaluation.factor_state.factor_valid,
        certificate_status = :pending, independent_loglik = nothing,
        certificate_discrepancy = nothing, comparison_threshold = nothing,
        optimizer_accepted = false))
    push!(observations, record)
    return record
end

function _arc1_fa_v2_certify_observations(observations, spectral, Y, X, B, rank,
                                          candidate_loglik;
                                          accepted_parameters = nothing,
                                          accepted_loglik = nothing,
                                          certifier = nothing)
    certified = NamedTuple[]
    threshold = candidate_loglik + _FA_RANK_TAU / 2
    for observation in observations
        observation.rank == rank || continue
        # Exact re-evaluation may raise the observed likelihood by up to the
        # accepted certificate tolerance. Keep that margin in the cheap screen
        # so a just-below raw value cannot hide a just-above certified value.
        if observation.loglik <= threshold - _FA_RANK_RECHECK_TOL
            push!(certified, merge(observation, (; certificate_status = :below_candidate,
                independent_loglik = nothing, certificate_discrepancy = nothing,
                comparison_threshold = threshold, optimizer_accepted = false)))
            continue
        end
        certificate = if certifier === nothing
            evaluation = _arc1_fa_v2_exact_objective_gradient(spectral,
                observation.coordinates, rank)
            _arc1_fa_v2_valid_likelihood_observation(evaluation) ?
                _arc1_fa_v2_certify(Y, X, B, observation.coordinates, rank,
                    evaluation.loglik) :
                (; status = :failed, independent_loglik = -Inf, discrepancy = Inf)
        else
            certifier(observation)
        end
        accepted = accepted_parameters !== nothing && accepted_loglik !== nothing &&
            isequal(observation.coordinates, accepted_parameters) &&
            certificate.status == :ok && isfinite(certificate.independent_loglik) &&
            abs(certificate.independent_loglik - accepted_loglik) <= _FA_RANK_RECHECK_TOL
        comparison_status = certificate.status == :ok &&
            certificate.independent_loglik <= threshold ? :below_candidate : certificate.status
        push!(certified, merge(observation, (; certificate_status = comparison_status,
            independent_loglik = certificate.independent_loglik,
            certificate_discrepancy = certificate.discrepancy,
            comparison_threshold = threshold, optimizer_accepted = accepted)))
    end
    return certified
end

function _fa_rank_evaluate_attempt(ctx, k, start_id, retry_index, params0, out;
                                   optimizer_policy = "arc1_v1")
    base = _fa_rank_attempt(k, start_id, retry_index;
                            initial_parameters = copy(params0))
    if optimizer_policy == "arc1_v2"
        base = merge(base, (; requested_optimizer_policy = optimizer_policy,
            actual_optimizer_policy = optimizer_policy,
            optimizer_policy = optimizer_policy, optimizer_policy_version = 2,
            covariance_representation = _ARC1_FA_V2_REPRESENTATION,
            source_identity = _ARC1_SOURCE_IDENTITY,
            optimizer_observations = hasproperty(out, :optimizer_observations) ?
                out.optimizer_observations : NamedTuple[]))
    end
    p = try
        Float64.(collect(out.phat))
    catch err
        err isa InterruptException && rethrow()
        return merge(base, (; status = :failed, reason = "optimizer returned no parameter vector: $(sprint(showerror, err))"))
    end
    obj = _fa_rank_read_or(() -> Float64(out.objective), NaN)
    converged = _fa_rank_read_or(() -> Bool(out.converged), false)
    optimizer_converged = _fa_rank_read_or(() -> Bool(out.optimizer_converged), converged)
    assessment_status = _fa_rank_read_or(() -> Symbol(out.optimizer_assessment_status), nothing)
    assessment_reason = _fa_rank_read_or(() -> out.optimizer_assessment_reason, nothing)
    opt_iter = _fa_rank_read_or(() -> Int(out.iterations), nothing)
    opt_status = _fa_rank_read_or(() -> string(out.optimizer_status), "unknown")
    finite_objective = isfinite(obj)
    finite_estimates = length(p) == _fa_rank_q(k) && all(isfinite, p)
    core = (; converged = optimizer_converged, optimizer_converged,
            optimizer_assessment_status = assessment_status,
            optimizer_assessment_reason = assessment_reason,
            optimizer_status = opt_status, optimizer_iterations = opt_iter,
            finite_objective, finite_estimates, estimated_parameters = p,
            optimizer_objective = finite_objective ? obj : nothing)
    finite_estimates || return merge(base, core,
        (; status = :failed, reason = "optimizer returned nonfinite or wrong-length estimates"))
    if optimizer_policy == "arc1_v2"
        state_result = _arc1_fa_v2_factor_state(p, k)
        state_result.status == :ok || return merge(base, core,
            (; status = :failed, reason = state_result.reason, factor_valid = false,
              covariance_representation = _ARC1_FA_V2_REPRESENTATION,
              requested_optimizer_policy = optimizer_policy,
              actual_optimizer_policy = optimizer_policy))
        state = state_result.state
        certificate = _arc1_fa_v2_certify(ctx.Y, ctx.X, ctx.Z * ctx.A * transpose(ctx.Z),
            p, k, -obj)
        distances = copy(state.delta)
        near = any(x -> x > 0 && x <= 1e-6, distances)
        discrepancy = certificate.discrepancy
        assessment_accepted = assessment_status === :accepted
        accepted = isfinite(obj) && certificate.status == :ok && assessment_accepted
        loglik = certificate.status == :ok ? certificate.independent_loglik : nothing
        reason = !assessment_accepted ?
            (assessment_status === nothing ? "optimizer assessment status is missing" :
             "optimizer assessment was not accepted: $(assessment_status)") :
            accepted ? (converged ? nothing : "optimizer did not converge") : certificate.reason
        return merge(base, core, (; status = accepted ? :completed : :failed,
            reason,
            eligible = accepted && converged,
            pd_genetic = state.pd_genetic, pd_residual = state.pd_residual,
            factor_valid = state.factor_valid, factor_state = state,
            covariance_representation = _ARC1_FA_V2_REPRESENTATION,
            requested_optimizer_policy = optimizer_policy,
            actual_optimizer_policy = optimizer_policy,
            genetic_covariance = state.G, residual_covariance = state.R,
            genetic_loadings = k == 0 ? nothing : vec(state.loadings),
            uniqueness = state.psi, floor_distances = distances, near_floor = near,
            reevaluated_loglik = loglik, independent_loglik = certificate.independent_loglik,
            objective_discrepancy = discrepancy,
            loglik, criterion = loglik === nothing ? nothing : -2loglik + 2 * _fa_rank_q(k),
            best_observed_loglik = hasproperty(out, :best_observed_loglik) ? out.best_observed_loglik :
                certificate.status == :ok ? certificate.independent_loglik : nothing,
            best_observation_certificate_status = hasproperty(out, :best_observation_certificate_status) ?
                out.best_observation_certificate_status : certificate.status,
            best_observation_accepted = hasproperty(out, :best_observation_accepted) ?
                out.best_observation_accepted : accepted))
    end
    local G, R, L, ψ
    try
        G, L, ψ = _fa_rank_cov(@view(p[1:(k == 0 ? 4 : 8)]), k)
        R = Matrix(Symmetric(_chol_params_to_cov(@view(p[(k == 0 ? 5 : 9):end]), 4)))
    catch err
        err isa InterruptException && rethrow()
        return merge(base, core, (; status = :failed,
            reason = "covariance reconstruction failed: $(sprint(showerror, err))"))
    end
    finite_estimates &= all(isfinite, G) && all(isfinite, R) && all(isfinite, ψ) &&
                        (L === nothing || all(isfinite, L))
    pd_g = finite_estimates && isposdef(Symmetric(G))
    pd_r = finite_estimates && isposdef(Symmetric(R))
    distances = finite_estimates ? collect(ψ .- FA_UNIQUENESS_FLOOR) : nothing
    near = distances === nothing ? nothing : any(x -> x > 0 && x <= 1e-6, distances)
    info = merge(base, core, (; finite_estimates, pd_genetic = pd_g,
        pd_residual = pd_r, genetic_covariance = G, residual_covariance = R,
        genetic_loadings = L, uniqueness = ψ, floor_distances = distances,
        near_floor = near))
    finite_objective || return merge(info, (; status = :failed, reason = "nonfinite optimizer objective"))
    finite_estimates && pd_g && pd_r || return merge(info,
        (; status = :failed, reason = "nonfinite or non-positive-definite covariance estimate"))
    minimum(distances) > 0 || return merge(info,
        (; status = :failed, reason = "uniqueness is at or below the matched floor"))
    local ll2
    try
        ll2 = _fa_rank_dense_recheck(ctx, G, R)
    catch err
        err isa InterruptException && rethrow()
        return merge(info, (; status = :failed,
            reason = "independent dense objective failed: $(sprint(showerror, err))"))
    end
    discrepancy = abs(ll2 + obj)
    info = merge(info, (; reevaluated_loglik = ll2, objective_discrepancy = discrepancy))
    isfinite(ll2) && discrepancy <= _FA_RANK_RECHECK_TOL || return merge(info,
        (; status = :failed, reason = "independent dense objective discrepancy exceeds 1e-8"))
    assessment_accepted = assessment_status === nothing || assessment_status == :accepted
    return merge(info, (; status = :completed,
        loglik = ll2, criterion = -2ll2 + 2 * _fa_rank_q(k),
        reason = assessment_accepted ? (converged ? nothing : "optimizer did not converge") : assessment_reason,
        eligible = converged && assessment_accepted))
end

function _fa_rank_candidate_from_attempts(k, attempts)
    rows = filter(a -> a.rank == k, attempts)
    isempty(rows) && return _fa_rank_candidate(k)
    good = filter(a -> a.eligible, rows)
    function finite_checked(a)
        a.attempted && a.finite_objective === true && a.finite_estimates === true &&
        (hasproperty(a, :factor_valid) ? a.factor_valid === true :
            a.pd_genetic === true && a.pd_residual === true) &&
        a.reevaluated_loglik !== nothing && isfinite(a.reevaluated_loglik) &&
        a.objective_discrepancy !== nothing && isfinite(a.objective_discrepancy) &&
        a.objective_discrepancy <= _FA_RANK_RECHECK_TOL &&
        a.floor_distances !== nothing && all(>(0), a.floor_distances)
    end
    finite = filter(a -> finite_checked(a) && a.loglik !== nothing && isfinite(a.loglik), rows)
    chosen = isempty(good) ? nothing : good[argmax(getproperty.(good, :loglik))]
    obj_range = length(finite) > 1 ? maximum(a.loglik for a in finite) -
                                     minimum(a.loglik for a in finite) : nothing
    covs = filter(a -> finite_checked(a) && a.genetic_covariance !== nothing &&
                       a.residual_covariance !== nothing, rows)
    function max_pairwise(field)
        length(covs) > 1 || return nothing
        return maximum(norm(getproperty(covs[i], field) - getproperty(covs[j], field)) /
                       max(norm(getproperty(covs[i], field)),
                           norm(getproperty(covs[j], field)), eps())
                       for i in 1:(length(covs) - 1) for j in (i + 1):length(covs))
    end
    rel_g = max_pairwise(:genetic_covariance)
    rel_r = max_pairwise(:residual_covariance)
    return _fa_rank_candidate(k; status = chosen === nothing ? :failed : :completed,
        reason = chosen === nothing ? "no eligible converged start for rank $k" : nothing,
        eligible = chosen !== nothing, selected_start = chosen === nothing ? nothing : chosen.start_id,
        loglik = chosen === nothing ? nothing : chosen.loglik,
        criterion = chosen === nothing ? nothing : chosen.criterion,
        converged = chosen === nothing ? false : true, attempts_count = length(rows),
        minimum_floor_distance = chosen === nothing ? nothing : minimum(chosen.floor_distances),
        near_floor = chosen === nothing ? nothing : chosen.near_floor,
        objective_range = obj_range, g_relative_disagreement = rel_g,
        r_relative_disagreement = rel_r)
end

function _fa_rank_fit(ctx, attempt, candidates, attempts; optimizer_policy = "arc1_v1")
    G, R = attempt.genetic_covariance, attempt.residual_covariance
    rounded_matrix_pd = if optimizer_policy == "arc1_v2"
        (; genetic = _arc1_fa_v2_exact_float64_pd(G),
            residual = _arc1_fa_v2_exact_float64_pd(R))
    else
        # Preserve the legacy v1 diagnostic and avoid exact-rational work on
        # a result that does not expose the v2 summary.
        (; genetic = isposdef(Symmetric(G)), residual = isposdef(Symmetric(R)))
    end
    # ARC1 v2 currently certifies the factor-defined likelihood only. A PD
    # rounded summary does not certify the accuracy of downstream GLS/BLUP
    # operations, so leave those fields unavailable until a factor-aware or
    # independently validated solver is supplied.
    beta, ebv = if optimizer_policy == "arc1_v2"
        (nothing, nothing)
    else
        _mv_gls_blup(ctx.y, ctx.Xfull, ctx.Zfull, ctx.A, ctx.indiv,
                      length(ctx.y), G, R, 4, 1, length(ctx.ids))
    end
    k = attempt.rank
    fa_rows = filter(a -> a.rank == 1, attempts)
    diag = k == 1 ? (; strategy = :default_balanced_optional_retry,
        starts_attempted = length(fa_rows), selected_start = attempt.start_id,
        objective_range = candidates[2].objective_range,
        g_relative_disagreement = candidates[2].g_relative_disagreement,
        r_relative_disagreement = candidates[2].r_relative_disagreement,
        better_nonconverged_start = any(a -> a.status == :completed && a.converged === false &&
            a.loglik !== nothing && a.loglik > attempt.loglik, fa_rows),
        minimum_uniqueness = minimum(attempt.uniqueness),
        uniqueness_floor_distance = minimum(attempt.floor_distances),
        near_uniqueness_floor = attempt.near_floor,
        starts = [(; name = a.start_id, loglik = a.loglik, valid = a.status == :completed,
                    converged = a.converged, iterations = a.optimizer_iterations,
                    minimum_uniqueness = a.uniqueness === nothing ? nothing : minimum(a.uniqueness),
                    uniqueness_floor_distance = a.floor_distances === nothing ? nothing : minimum(a.floor_distances))
                  for a in fa_rows]) : nothing
    fit = (; genetic_covariance = G, residual_covariance = R,
        genetic_correlation = genetic_correlation(G), residual_correlation = genetic_correlation(R),
        heritability = [G[i, i] / (G[i, i] + R[i, i]) for i in 1:4], beta,
        breeding_values = ebv === nothing ? nothing : (; ids = ctx.ids, traits = ctx.traits, values = ebv),
        genetic_structure = _fa_rank_structure(k), genetic_rank = k == 1 ? 1 : nothing,
        genetic_loadings = attempt.genetic_loadings, genetic_uniqueness = attempt.uniqueness,
        loglik = attempt.loglik, converged = true, iterations = attempt.optimizer_iterations,
        fa_start_diagnostics = diag, traits = ctx.traits)
    optimizer_policy == "arc1_v1" && return fit
    return merge(fit, (; factor_state = attempt.factor_state,
        covariance_representation = _ARC1_FA_V2_REPRESENTATION,
        factor_valid = attempt.factor_valid,
        rounded_matrix_pd,
        matrix_operations_status = :unavailable,
        matrix_operations_reason = "factor-defined fit does not certify GLS/BLUP accuracy from rounded covariance matrices",
        downstream_diagnostics = (; gls = :not_certified, blup = :not_certified,
            rounded_matrix_pd, factor_valid = attempt.factor_valid)))
end

function _arc1_result_with_policy(result, rows, fixed_rank, k0_eligible;
                                  optimizer_policy = "arc1_v1", actual_policy = nothing)
    optimizer_policy == "arc1_v2" || begin
    diag = (; strategy = :arc1_v1_bfgs_hager_zhang,
        optimizer_policy = "arc1_v1", optimizer_policy_version = 1,
        algorithm = :bfgs_hager_zhang, optimizer_iterations = 2_000,
        optimizer_tolerance = 1e-8, final_scaled_gradient_tolerance = 1e-6,
        numerical_gradient_steps = (1e-4, 1e-5), numerical_gradient_tolerance = 5e-6,
        source_identity = _ARC1_SOURCE_IDENTITY, julia_version = string(VERSION),
        optim_version = string(Base.pkgversion(Optim)),
        starts_planned = length(rows), starts_attempted = count(a -> a.attempted, rows),
        fixed_rank_request = fixed_rank, eligible_k0 = k0_eligible,
        starts = rows)
    fit = result.selected_fit === nothing ? nothing :
          merge(result.selected_fit, (; fa_start_diagnostics = diag))
    return merge(result, (; optimizer_policy = "arc1_v1", optimizer_policy_version = 1,
                           optimizer_algorithm = :bfgs_hager_zhang, optimizer_iterations = 2_000,
                           optimizer_tolerance = 1e-8, final_scaled_gradient_tolerance = 1e-6,
                           numerical_gradient_steps = (1e-4, 1e-5), numerical_gradient_tolerance = 5e-6,
                           starts_planned = length(rows),
                           starts_attempted = count(a -> hasproperty(a, :attempted) && a.attempted, rows),
                           source_identity = _ARC1_SOURCE_IDENTITY,
                           selected_fit = fit))
    end
    identity = (; requested_optimizer_policy = optimizer_policy,
        actual_optimizer_policy = actual_policy, optimizer_policy,
        optimizer_policy_version = 2,
        covariance_representation = _ARC1_FA_V2_REPRESENTATION,
        source_identity = _ARC1_SOURCE_IDENTITY)
    rows = [merge(row, identity, (; actual_optimizer_policy =
        hasproperty(row, :actual_optimizer_policy) ? row.actual_optimizer_policy : nothing))
        for row in rows]
    diag = (; strategy = :arc1_v2_bfgs_hager_zhang,
        optimizer_policy, optimizer_policy_version = 2,
        covariance_representation = _ARC1_FA_V2_REPRESENTATION,
        algorithm = :bfgs_hager_zhang, optimizer_iterations = 2_000,
        optimizer_tolerance = 1e-8, final_scaled_gradient_tolerance = 1e-6,
        numerical_gradient_steps = (1e-4, 1e-5), numerical_gradient_tolerance = 5e-6,
        independent_likelihood_tolerance = 1e-8,
        source_identity = _ARC1_SOURCE_IDENTITY, julia_version = string(VERSION),
        optim_version = string(Base.pkgversion(Optim)), starts_planned = length(rows),
        starts_attempted = count(a -> a.attempted, rows), fixed_rank_request = fixed_rank,
        eligible_k0 = k0_eligible, requested_optimizer_policy = optimizer_policy,
        actual_optimizer_policy = actual_policy, starts = rows)
    fit = result.selected_fit === nothing ? nothing :
        merge(result.selected_fit, (; fa_start_diagnostics = diag,
            requested_optimizer_policy = optimizer_policy,
            actual_optimizer_policy = actual_policy,
            optimizer_policy, optimizer_policy_version = 2,
            covariance_representation = _ARC1_FA_V2_REPRESENTATION,
            source_identity = _ARC1_SOURCE_IDENTITY))
    return merge(result, (; optimizer_policy, optimizer_policy_version = 2,
        covariance_representation = _ARC1_FA_V2_REPRESENTATION,
        requested_optimizer_policy = optimizer_policy, actual_optimizer_policy = actual_policy,
        optimizer_algorithm = :bfgs_hager_zhang, optimizer_iterations = 2_000,
        optimizer_tolerance = 1e-8, final_scaled_gradient_tolerance = 1e-6,
        numerical_gradient_steps = (1e-4, 1e-5), numerical_gradient_tolerance = 5e-6,
        independent_likelihood_tolerance = 1e-8, starts_planned = length(rows),
        starts_attempted = count(a -> hasproperty(a, :attempted) && a.attempted, rows),
        source_identity = _ARC1_SOURCE_IDENTITY, selected_fit = fit))
end

function _arc1_derived_starts(diagonal_attempt)
    if hasproperty(diagonal_attempt, :factor_state) && diagonal_attempt.factor_state !== nothing
        state = diagonal_attempt.factor_state
        starts = NamedTuple[]
        for a in (0.1, 0.7), mask in 0:7
            signs = [1.0; [((mask >> (i - 2)) & 1) == 0 ? 1.0 : -1.0 for i in 2:4]]
            λ = a .* signs .* sqrt.(state.delta)
            delta = (1 - a^2) .* state.delta
            name = Symbol("derived_a$(a)_s$(mask)")
            params = vcat(λ, log.(delta), state.parameters[5:14])
            push!(starts, (; name, params, loading = λ,
                uniqueness = state.floor .+ delta, uniqueness_excess = delta))
        end
        return starts
    end
    g = diag(diagonal_attempt.genetic_covariance)
    c = FA_UNIQUENESS_FLOOR
    all(x -> isfinite(x) && x > c, g) ||
        throw(ArgumentError("eligible diagonal genetic variances must exceed the uniqueness floor"))
    starts = NamedTuple[]
    for a in (0.1, 0.7), mask in 0:7
        signs = [1.0; [((mask >> (i - 2)) & 1) == 0 ? 1.0 : -1.0 for i in 2:4]]
        λ = a .* signs .* sqrt.(g .- c)
        ψ = g .- λ.^2
        all(x -> isfinite(x) && x > c, ψ) ||
            throw(ArgumentError("derived FA uniqueness is not strictly above its floor"))
        G = λ * transpose(λ) + Diagonal(ψ)
        isapprox(diag(G), g; atol = 1e-12, rtol = 1e-12) ||
            throw(ArgumentError("derived FA start changed a genetic marginal variance"))
        name = Symbol("derived_a$(a)_s$(mask)")
        params = vcat(λ, _fa_uniqueness_to_unconstrained(ψ),
                      _cov_to_chol_params(diagonal_attempt.residual_covariance, 4))
        push!(starts, (; name, params, loading = λ, uniqueness = ψ))
    end
    return starts
end

function _arc1_select_fa_rank(Y, X, Z, pedigree::Pedigree;
                              ids = nothing, traits = nothing, iterations = 2_000,
                              fixed_rank = nothing, ledger_sink = nothing,
                              attempt_runner = nothing, checkpoint = () -> nothing,
                              optimizer_policy = "arc1_v1",
                              observation_certifier = nothing,
                              k0_start_builder = _arc1_k0_start_schedule)
    candidates = NamedTuple[_fa_rank_candidate(k) for k in 0:1]
    attempts = NamedTuple[]
    actual_policy = Ref{Union{Nothing,String}}(nothing)
    function publish(; kwargs...)
        policy_version = optimizer_policy == "arc1_v2" ? 2 : 1
        representation = optimizer_policy == "arc1_v2" ? _ARC1_FA_V2_REPRESENTATION : nothing
        snapshot = _fa_rank_publish!(ledger_sink, candidates, attempts;
            optimizer_policy, optimizer_policy_version = policy_version,
            source_identity = _ARC1_SOURCE_IDENTITY,
            requested_optimizer_policy = optimizer_policy == "arc1_v2" ? optimizer_policy : nothing,
            actual_optimizer_policy = optimizer_policy == "arc1_v2" ? actual_policy[] : nothing,
            covariance_representation = representation, kwargs...)
        snapshot
    end
    publish(selection_status = :in_progress, reason = "ARC1 selector initialized")
    invalid = _fa_rank_preflight(Y, X, Z, pedigree, ids, traits, iterations)
    if invalid !== nothing
        candidates = NamedTuple[_fa_rank_candidate(k; status = :unsupported_input,
            reason = invalid) for k in 0:1]
        base = publish(
            selection_status = :unsupported_input, reason = invalid)
        return _arc1_result_with_policy(base, attempts, fixed_rank, false;
            optimizer_policy, actual_policy = actual_policy[])
    end
    ctx = try
        _fa_rank_context(Y, X, Z, pedigree, traits)
    catch err
        if err isa InterruptException
            publish(selection_status = :interrupted, reason = "interrupted during pedigree/model construction")
            rethrow()
        end
        why = "pedigree/model construction failed: $(sprint(showerror, err))"
        candidates = NamedTuple[_fa_rank_candidate(k; status = :unsupported_input, reason = why) for k in 0:1]
        base = publish(selection_status = :unsupported_input, reason = why)
        return _arc1_result_with_policy(base, attempts, fixed_rank, false;
            optimizer_policy, actual_policy = actual_policy[])
    end
    B = ctx.Z * ctx.A * transpose(ctx.Z)
    spectral = try
        _arc1_fa_spectral_context(ctx.Y, ctx.X, B)
    catch err
        if err isa InterruptException
            publish(selection_status = :interrupted, reason = "interrupted during spectral context construction")
            rethrow()
        end
        rethrow()
    end
    if spectral.status != :ok
        candidates = NamedTuple[_fa_rank_candidate(k; status = :unsupported_input, reason = spectral.reason) for k in 0:1]
        base = publish(selection_status = :unsupported_input, reason = spectral.reason)
        return _arc1_result_with_policy(base, attempts, fixed_rank, false;
            optimizer_policy, actual_policy = actual_policy[])
    end
    ctx = merge(ctx, (; spectral = spectral.context))
    records = size(ctx.Y, 1)
    design_fp = bytes2hex(sha256(repr((ctx.Y, ctx.X, ctx.Z, ctx.traits, ctx.ids))))
    rel_fp = bytes2hex(sha256(repr(ctx.A)))
    ratio = _fa_rank_kernel_ratio(ctx.A, ctx.Z)
    if !isfinite(ratio) || ratio <= 1e-8
        why = "genetic and residual kernels are unresolved on REML contrasts (ratio=$(ratio))"
        candidates = NamedTuple[_fa_rank_candidate(k; status = :unsupported_input, reason = why) for k in 0:1]
        base = publish(
            selection_status = :unsupported_input, reason = why,
            records, design_fingerprint = design_fp, relationship_fingerprint = rel_fp,
            kernel_ratio = ratio)
        return _arc1_result_with_policy(base, attempts, fixed_rank, false;
            optimizer_policy, actual_policy = actual_policy[])
    end
    publish_context(; kwargs...) = publish(; records, design_fingerprint = design_fp,
        relationship_fingerprint = rel_fp, kernel_ratio = ratio, kwargs...)
    runner = attempt_runner === nothing ? nothing : attempt_runner
    p0, f0, f1 = _fa_rank_starts(ctx)
    k0_starts = optimizer_policy == "arc1_v1" ? k0_start_builder(ctx, p0) :
        [(; rank = 0, start_id = :default, split = 0.5, schedule_index = 1,
          params = copy(p0), initialization_status = :ok, failure_reason = nothing)]
    # Declare the full frozen schedule before fitting so interruptions retain
    # explicit rows for every not-yet-run start.
    for start in k0_starts
        reason = start.initialization_status == :ok ? "queued" : start.failure_reason
        push!(attempts, merge(_fa_rank_attempt(0, start.start_id, 0;
            status = :unattempted, reason),
            (; attempted = false, split = start.split,
               schedule_index = start.schedule_index,
               initialization_status = start.initialization_status)))
    end
    for (schedule_index, name) in enumerate((:default, :balanced))
        push!(attempts, merge(_fa_rank_attempt(1, name, 0;
            status = :unattempted, reason = "queued"),
            (; attempted = false, schedule_index, k0_anchor_start_id = nothing)))
    end
    for (offset, (a, mask)) in enumerate(((a, mask) for a in (0.1, 0.7) for mask in 0:7))
        name = Symbol("derived_a$(a)_s$(mask)")
        push!(attempts, merge(_fa_rank_attempt(1, name, 0;
            status = :unattempted, reason = "awaiting eligible K0 estimate"),
            (; attempted = false, schedule_index = offset + 2,
               k0_anchor_start_id = nothing)))
    end
    function runstart(k, name, params0; start_metadata = NamedTuple())
        rowidx = findfirst(a -> a.rank == k && a.start_id == name && !a.attempted, attempts)
        fresh = merge(_fa_rank_attempt(k, name, 0; initial_parameters = copy(params0)),
                      start_metadata)
        if rowidx === nothing
            push!(attempts, fresh)
            rowidx = length(attempts)
        else
            attempts[rowidx] = fresh
        end
        candidates[k + 1] = merge(candidates[k + 1],
            (; status = :running, attempts_count = count(a -> a.rank == k && a.attempted, attempts)))
        publish_context()
        try
            actual_policy[] = optimizer_policy
            optimizer_policy == "arc1_v2" &&
                (attempts[rowidx] = merge(attempts[rowidx],
                    (; actual_optimizer_policy = optimizer_policy,
                       optimizer_observations = NamedTuple[])))
            observations = optimizer_policy == "arc1_v2" ? NamedTuple[] : nothing
            observe = function (params, evaluation)
                if optimizer_policy == "arc1_v2"
                    record = _arc1_fa_v2_retain_observation!(observations, params, evaluation;
                        rank = k, start_id = name, retry_index = 0,
                        source_identity = _ARC1_SOURCE_IDENTITY)
                    attempts[rowidx] = merge(attempts[rowidx],
                        (; optimizer_observations = observations))
                    return record
                end
                return nothing
            end
            out = if runner === nothing
                fit = _arc1_fa_bfgs(ctx.spectral, params0, k; optimizer_policy,
                    evaluation_callback = optimizer_policy == "arc1_v2" ? observe : nothing)
                _fa_rank_optimizer_output(fit)
            else
                applicable(runner, ctx.spectral, params0, k, name, observe) ?
                    runner(ctx.spectral, params0, k, name, observe) :
                    runner(ctx.spectral, params0, k, name)
            end
            if optimizer_policy == "arc1_v2"
                if hasproperty(out, :best_observation_parameters)
                    proposed = try Float64.(collect(out.best_observation_parameters)) catch; Float64[] end
                    proposed_eval = length(proposed) == _fa_rank_q(k) && all(isfinite, proposed) ?
                        _arc1_fa_v2_exact_objective_gradient(ctx.spectral, proposed, k) : nothing
                    _arc1_fa_v2_retain_observation!(observations, proposed, proposed_eval;
                        rank = k, start_id = name, retry_index = 0,
                        source_identity = _ARC1_SOURCE_IDENTITY)
                end
                if isempty(observations) && hasproperty(out, :phat)
                    proposed = try Float64.(collect(out.phat)) catch; Float64[] end
                    proposed_eval = length(proposed) == _fa_rank_q(k) && all(isfinite, proposed) ?
                        _arc1_fa_v2_exact_objective_gradient(ctx.spectral, proposed, k) : nothing
                    _arc1_fa_v2_retain_observation!(observations, proposed, proposed_eval;
                        rank = k, start_id = name, retry_index = 0,
                        source_identity = _ARC1_SOURCE_IDENTITY)
                end
                out = merge(out, (; optimizer_observations = observations))
            end
            row = _fa_rank_evaluate_attempt(ctx, k, name, 0, params0, out; optimizer_policy)
            if hasproperty(out, :line_search_success) && !out.line_search_success
                row = merge(row, (; status = :failed,
                    eligible = false, reason = "Hager-Zhang line search failed"))
            end
            extra = (; scaled_objective = hasproperty(out, :scaled_objective) ? out.scaled_objective : nothing,
                     final_gradient_inf_norm = hasproperty(out, :final_gradient_inf_norm) ? out.final_gradient_inf_norm : nothing,
                     numerical_gradient_inf_norms = hasproperty(out, :numerical_gradient_inf_norms) ? out.numerical_gradient_inf_norms : nothing,
                     numerical_gradient_discrepancies = hasproperty(out, :numerical_gradient_discrepancies) ? out.numerical_gradient_discrepancies : nothing,
                     numerical_gradient_status = hasproperty(out, :numerical_gradient_status) ? out.numerical_gradient_status : :test_seam,
                     numerical_gradient_failed_sides = hasproperty(out, :numerical_gradient_failed_sides) ? out.numerical_gradient_failed_sides : nothing,
                     line_search_terminal_reason = hasproperty(out, :line_search_terminal_reason) ? out.line_search_terminal_reason : nothing,
                     optimizer_converged = hasproperty(out, :optimizer_converged) ? out.optimizer_converged : nothing,
                     optimizer_assessment_status = hasproperty(out, :optimizer_assessment_status) ? out.optimizer_assessment_status : nothing,
                     optimizer_assessment_reason = hasproperty(out, :optimizer_assessment_reason) ? out.optimizer_assessment_reason : nothing,
                     failure_status = hasproperty(out, :optimizer_assessment_status) &&
                         out.optimizer_assessment_status != :accepted ? out.optimizer_assessment_status : nothing,
                     numerical_gradient_reason = hasproperty(out, :optimizer_assessment) ? out.optimizer_assessment.reason : nothing,
                     line_search_success = hasproperty(out, :line_search_success) ? out.line_search_success : nothing,
                     callback_requests = hasproperty(out, :line_search_stats) ? out.line_search_stats.callback_requests : nothing,
                     objective_evaluations = hasproperty(out, :line_search_stats) ? out.line_search_stats.objective_evaluations : nothing,
                     rejected_trials = hasproperty(out, :line_search_stats) ? out.line_search_stats.rejected_trials : nothing,
                     domain_restarts = hasproperty(out, :line_search_stats) ? out.line_search_stats.domain_restarts : nothing,
                     line_search_stats = hasproperty(out, :line_search_stats) ? out.line_search_stats : nothing,
                     algorithm = hasproperty(out, :algorithm) ? out.algorithm : :test_seam)
            attempts[rowidx] = merge(row, start_metadata, extra)
        catch err
            if err isa InterruptException
                attempts[rowidx] = merge(attempts[rowidx], (; status = :interrupted,
                    reason = "interrupted during optimizer start"))
                candidates[k + 1] = merge(_fa_rank_candidate_from_attempts(k, attempts),
                    (; status = :interrupted, reason = "interrupted during optimizer start"))
                publish_context(; selection_status = :interrupted, reason = "interrupted during optimizer start")
                rethrow()
            end
            attempts[rowidx] = merge(attempts[rowidx], (; status = :failed,
                reason = "optimizer start failed: $(sprint(showerror, err))"))
        end
        candidates[k + 1] = _fa_rank_candidate_from_attempts(k, attempts)
        publish_context()
        return attempts[rowidx]
    end
    function scheduled_k1_metadata(name)
        row = only(filter(a -> a.rank == 1 && a.start_id == name, attempts))
        return (; schedule_index = row.schedule_index,
            k0_anchor_start_id = row.k0_anchor_start_id)
    end
    if optimizer_policy == "arc1_v2"
        try
            checkpoint()
        catch err
            if err isa InterruptException
                publish_context(; selection_status = :interrupted,
                    reason = "interrupted before first optimizer start")
                return _arc1_result_with_policy(publish_context(
                    selection_status = :interrupted,
                    reason = "interrupted before first optimizer start"),
                    attempts, fixed_rank, false; optimizer_policy,
                    actual_policy = actual_policy[])
            end
            rethrow()
        end
    end
    for start in k0_starts
        if start.initialization_status == :ok
            runstart(0, start.start_id, start.params;
                start_metadata = (; split = start.split,
                    schedule_index = start.schedule_index,
                    initialization_status = start.initialization_status))
        else
            rowidx = findfirst(a -> a.rank == 0 && a.start_id == start.start_id && !a.attempted,
                               attempts)
            rowidx === nothing && error("K0 initialization failure has no planned ledger row")
            attempts[rowidx] = merge(attempts[rowidx], (; status = :failed,
                reason = start.failure_reason, initialization_status = start.initialization_status))
            candidates[1] = _fa_rank_candidate_from_attempts(0, attempts)
            publish_context()
        end
        try
            checkpoint()
        catch err
            if err isa InterruptException
                publish_context(; selection_status = :interrupted,
                    reason = "interrupted after K0 start schedule position $(start.schedule_index)")
                return _arc1_result_with_policy(publish_context(; selection_status = :interrupted,
                    reason = "interrupted after K0 start schedule position $(start.schedule_index)"),
                    attempts, fixed_rank, candidates[1].eligible;
                    optimizer_policy, actual_policy = actual_policy[])
            end
            rethrow()
        end
    end
    k0_eligible_rows = filter(a -> a.rank == 0 && a.eligible, attempts)
    k0row = if isempty(k0_eligible_rows)
        nothing
    else
        best_loglik = maximum(a.loglik for a in k0_eligible_rows)
        findfirst(a -> a.rank == 0 && a.eligible && a.loglik == best_loglik, attempts)
    end
    if k0row !== nothing
        anchor = string(attempts[k0row].start_id)
        for i in eachindex(attempts)
            a = attempts[i]
            a.rank == 1 && (attempts[i] = merge(a, (; k0_anchor_start_id = anchor)))
        end
    end
    derived = NamedTuple[]
    should_run_phenotypic_k1 = k0row !== nothing || optimizer_policy == "arc1_v2"
    if should_run_phenotypic_k1
        runstart(1, :default, f0; start_metadata = scheduled_k1_metadata(:default))
        runstart(1, :balanced, f1; start_metadata = scheduled_k1_metadata(:balanced))
    end
    if k0row !== nothing
        derived = _arc1_derived_starts(attempts[k0row])
        for start in derived
            runstart(1, start.name, start.params;
                start_metadata = scheduled_k1_metadata(start.name))
        end
    elseif optimizer_policy == "arc1_v1"
        for i in eachindex(attempts)
            a = attempts[i]
            a.rank == 1 && !a.attempted &&
                (attempts[i] = merge(a, (; reason = "eligible K0 estimate unavailable for K1 schedule")))
        end
    else
        for i in eachindex(attempts)
            a = attempts[i]
            startswith(string(a.start_id), "derived_") &&
                (attempts[i] = merge(a, (; reason = "eligible K0 estimate unavailable for derived start")))
        end
    end
    try
        checkpoint()
    catch err
        if err isa InterruptException
            publish_context(; selection_status = :interrupted, reason = "interrupted after K1 starts")
            return _arc1_result_with_policy(publish_context(; selection_status = :interrupted,
                reason = "interrupted after K1 starts"), attempts, fixed_rank, candidates[1].eligible;
                optimizer_policy, actual_policy = actual_policy[])
        end
        rethrow()
    end
    c0, c1 = candidates
    k1rows = filter(a -> a.rank == 1 && a.attempted, attempts)
    if optimizer_policy == "arc1_v2" && c1.eligible
        for i in eachindex(attempts)
            row = attempts[i]
            row.rank == 1 && row.attempted || continue
            observations = hasproperty(row, :optimizer_observations) &&
                row.optimizer_observations !== nothing ? row.optimizer_observations : NamedTuple[]
            certified = _arc1_fa_v2_certify_observations(observations,
                ctx.spectral, ctx.Y, ctx.X, B, 1, c1.loglik;
                accepted_parameters = row.eligible ? row.estimated_parameters : nothing,
                accepted_loglik = row.eligible ? row.loglik : nothing,
                certifier = observation_certifier)
            valid = filter(o -> o.certificate_status == :ok &&
                o.independent_loglik isa Real && isfinite(o.independent_loglik), certified)
            best = isempty(valid) ? nothing : valid[argmax(getproperty.(valid, :independent_loglik))]
            attempts[i] = merge(row, (; optimizer_observations = certified,
                best_observed_loglik = best === nothing ? nothing : best.independent_loglik,
                best_observation_certificate_status = best === nothing ?
                    (isempty(certified) ? :unavailable : :failed) : best.certificate_status,
                best_observation_accepted = best === nothing ? false : best.optimizer_accepted))
        end
        k1rows = filter(a -> a.rank == 1 && a.attempted, attempts)
    end
    k0_schedule_rows = filter(a -> a.rank == 0, attempts)
    expected_k0_starts = optimizer_policy == "arc1_v1" ? 6 : 1
    schedule_complete = count(a -> a.attempted, k0_schedule_rows) == expected_k0_starts &&
                        count(a -> a.attempted, k1rows) == 18 &&
                        count(a -> a.start_id in (:default, :balanced), k1rows) == 2 &&
                        count(a -> startswith(string(a.start_id), "derived_"), k1rows) == 16
    k0_attempts = filter(a -> a.rank == 0 && a.attempted, attempts)
    better_unaccepted_k0 = optimizer_policy == "arc1_v1" && c0.eligible && any(a -> a.attempted &&
        !a.eligible && a.finite_objective === true && a.finite_estimates === true &&
        a.pd_genetic === true && a.pd_residual === true &&
        a.reevaluated_loglik !== nothing && isfinite(a.reevaluated_loglik) &&
        a.objective_discrepancy !== nothing && isfinite(a.objective_discrepancy) &&
        a.objective_discrepancy <= _FA_RANK_RECHECK_TOL &&
        a.floor_distances !== nothing && all(>(0), a.floor_distances) &&
        a.loglik !== nothing && isfinite(a.loglik) &&
        a.loglik > c0.loglik + _FA_RANK_TAU / 2, k0_attempts)
    better_unaccepted_k1 = optimizer_policy == "arc1_v2" && c1.eligible && any(a -> a.attempted &&
        hasproperty(a, :best_observation_certificate_status) &&
        a.best_observation_certificate_status === :ok &&
        hasproperty(a, :best_observed_loglik) && hasproperty(a, :best_observation_accepted) &&
        a.best_observed_loglik !== nothing && isfinite(a.best_observed_loglik) &&
        a.best_observed_loglik > c1.loglik + _FA_RANK_TAU / 2 &&
        a.best_observation_accepted !== true, k1rows) ||
        (c1.eligible && any(a -> a.attempted && !a.eligible &&
        a.finite_objective === true && a.finite_estimates === true &&
        (hasproperty(a, :factor_valid) ? a.factor_valid === true :
            a.pd_genetic === true && a.pd_residual === true) &&
        a.reevaluated_loglik !== nothing && isfinite(a.reevaluated_loglik) &&
        a.objective_discrepancy !== nothing && isfinite(a.objective_discrepancy) &&
        a.objective_discrepancy <= _FA_RANK_RECHECK_TOL &&
        a.floor_distances !== nothing && all(>(0), a.floor_distances) &&
        a.loglik !== nothing && isfinite(a.loglik) &&
        a.loglik > c1.loglik + _FA_RANK_TAU / 2, k1rows))
    better_unaccepted = better_unaccepted_k0 || better_unaccepted_k1
    nonnested = c0.eligible && c1.eligible && c1.loglik < c0.loglik - _FA_RANK_TAU / 2
    nesting_discrepancy = k0row === nothing ? nothing : _fa_rank_nesting_discrepancy(ctx, attempts[k0row])
    score = c0.eligible && c1.eligible ? _fa_rank_score(c0.loglik, c1.loglik) : nothing
    why = if !c0.eligible
        "an eligible K0 fit is required to complete the ARC1 start schedule"
    elseif better_unaccepted_k0
        "a materially better finite unaccepted K0 attempt remains after the frozen schedule"
    elseif !schedule_complete
        "the frozen six-start K0 and 18-start K1 schedules were not completed"
    elseif !c1.eligible
        "no eligible converged K1 start"
    elseif nesting_discrepancy === nothing || !isfinite(nesting_discrepancy) ||
           nesting_discrepancy > _FA_RANK_RECHECK_TOL
        "matched-floor L=0 nesting witness differs from the diagonal objective"
    elseif better_unaccepted_k1
        "a materially better finite unaccepted K1 attempt remains after the frozen schedule"
    elseif nonnested
        "FA likelihood remains non-nested below the diagonal fit"
    else
        nothing
    end
    guard_results = (; schedule_complete, better_unaccepted,
        better_unaccepted_k0, better_unaccepted_k1, nonnested,
        nesting_witness = (; status = nesting_discrepancy === nothing ? :unavailable :
            isfinite(nesting_discrepancy) && nesting_discrepancy <= _FA_RANK_RECHECK_TOL ? :passed : :failed,
            discrepancy = nesting_discrepancy, tolerance = _FA_RANK_RECHECK_TOL))
    if why !== nothing
        base = publish_context(; selection_status = :unavailable, reason = why,
            criterion_difference = score === nothing ? nothing : score.criterion_difference,
            near_tie = score === nothing ? nothing : score.near_tie,
            nesting_witness_discrepancy = nesting_discrepancy, guard_results)
        return _arc1_result_with_policy(base, attempts, fixed_rank, c0.eligible;
            optimizer_policy, actual_policy = actual_policy[])
    end
    if fixed_rank == 1
        winner = 1
    else
        winner = score.selected_rank
    end
    chosen = findfirst(a -> a.rank == winner && a.eligible &&
                           a.loglik == candidates[winner + 1].loglik, attempts)
    chosen === nothing && (chosen = findfirst(a -> a.rank == winner && a.eligible, attempts))
    attempts[chosen] = merge(attempts[chosen], (; selected_within_rank = true, selected = true))
    fit = _fa_rank_fit(ctx, attempts[chosen], candidates, attempts; optimizer_policy)
    base = publish_context(; selection_status = fixed_rank === nothing ? :selected : :fixed_rank_fit,
        selected_rank = winner,
        criterion_difference = score.criterion_difference, near_tie = score.near_tie,
        selected_fit = fit, nesting_witness_discrepancy = nesting_discrepancy, guard_results)
    return _arc1_result_with_policy(base, attempts, fixed_rank, c0.eligible;
        optimizer_policy, actual_policy = actual_policy[])
end

"""
    select_fa_rank(Y, X, Z, pedigree::Pedigree; ids=nothing, traits=nothing,
                   iterations=2000, ledger_sink=nothing)

Experimental explicit Gaussian four-trait pedigree comparison of matched-floor
diagonal genetic covariance (K=0) and one-factor FA covariance (K=1). Return a
selection ledger and an ordinary `selected_fit` only if both ranks are eligible.
`ledger_sink` is an optional request-local `Ref` updated around every start;
on interruption its last snapshot retains the interrupted attempt.
"""
function select_fa_rank(Y, X, Z,
                        pedigree::Pedigree; ids = nothing, traits = nothing,
                        iterations = nothing, ledger_sink = nothing,
                        optimizer_policy = nothing)
    niter = iterations === nothing ? 2_000 : iterations
    if optimizer_policy === nothing
        return _select_fa_rank(Y, X, Z, pedigree; ids, traits, iterations = niter, ledger_sink)
    elseif optimizer_policy in ("arc1_v1", :arc1_v1)
        iterations === nothing || iterations == 2_000 || return _fa_rank_publish!(ledger_sink,
            NamedTuple[_fa_rank_candidate(k; status = :unsupported_input,
                reason = "arc1_v1 fixes iterations at 2,000 per start") for k in 0:1], NamedTuple[];
            optimizer_policy = "arc1_v1", optimizer_policy_version = 1,
            source_identity = _ARC1_SOURCE_IDENTITY,
            selection_status = :unsupported_input, reason = "arc1_v1 fixes iterations at 2,000 per start")
        return _arc1_select_fa_rank(Y, X, Z, pedigree; ids, traits,
            iterations = niter, ledger_sink)
    elseif optimizer_policy in ("arc1_v2", :arc1_v2)
        why = iterations === nothing || iterations == 2_000 ? nothing :
            "arc1_v2 fixes iterations at 2,000 per start"
        if why !== nothing
            candidates = NamedTuple[_fa_rank_candidate(k; status = :unsupported_input,
                reason = why) for k in 0:1]
            return _fa_rank_publish!(ledger_sink, candidates, NamedTuple[];
                optimizer_policy = "arc1_v2", optimizer_policy_version = 2,
                source_identity = _ARC1_SOURCE_IDENTITY,
                requested_optimizer_policy = "arc1_v2",
                actual_optimizer_policy = nothing,
                covariance_representation = _ARC1_FA_V2_REPRESENTATION,
                selection_status = :unsupported_input, reason = why)
        end
        return _arc1_select_fa_rank(Y, X, Z, pedigree; ids, traits,
            iterations = 2_000, ledger_sink, optimizer_policy = "arc1_v2")
    end
    why = "unknown optimizer_policy: $(repr(optimizer_policy)); supported values are \"arc1_v1\" and \"arc1_v2\""
    return _fa_rank_publish!(ledger_sink,
        NamedTuple[_fa_rank_candidate(k; status = :unsupported_input, reason = why) for k in 0:1],
        NamedTuple[]; selection_status = :unsupported_input, reason = why)
end

function select_fa_rank(Y, X, Z, relationship;
                        ids = nothing, traits = nothing, iterations = nothing,
                        ledger_sink = nothing, optimizer_policy = nothing)
    optimizer_policy === nothing || return _fa_rank_publish!(ledger_sink,
        NamedTuple[_fa_rank_candidate(k; status = :unsupported_input,
            reason = optimizer_policy in ("arc1_v1", :arc1_v1) ?
                "arc1_v1 requires a validated Pedigree relationship; use Pedigree input" :
                optimizer_policy in ("arc1_v2", :arc1_v2) ?
                "arc1_v2 requires a validated Pedigree relationship; use Pedigree input" :
                "unknown optimizer_policy: $(repr(optimizer_policy))") for k in 0:1],
        NamedTuple[]; selection_status = :unsupported_input,
        optimizer_policy = optimizer_policy in ("arc1_v2", :arc1_v2) ? "arc1_v2" : "arc1_v1",
        optimizer_policy_version = optimizer_policy in ("arc1_v2", :arc1_v2) ? 2 : 1,
        source_identity = _ARC1_SOURCE_IDENTITY,
        requested_optimizer_policy = optimizer_policy in ("arc1_v2", :arc1_v2) ? "arc1_v2" : nothing,
        actual_optimizer_policy = nothing,
        covariance_representation = optimizer_policy in ("arc1_v2", :arc1_v2) ? _ARC1_FA_V2_REPRESENTATION : nothing,
        reason = optimizer_policy in ("arc1_v1", :arc1_v1) ?
            "arc1_v1 requires a validated Pedigree relationship; use Pedigree input" :
            "unknown optimizer_policy: $(repr(optimizer_policy))")
    why = "automatic FA rank selection requires a validated Pedigree; genomic and custom relationship providers are unsupported"
    candidates = NamedTuple[_fa_rank_candidate(k; reason = why) for k in 0:1]
    return _fa_rank_publish!(ledger_sink, candidates, NamedTuple[];
        selection_status = :unsupported_input, reason = why)
end

function _select_fa_rank(Y, X, Z,
                         pedigree::Pedigree; ids = nothing, traits = nothing,
                         iterations = 2_000, ledger_sink = nothing,
                         attempt_runner = _fa_rank_optimize,
                         checkpoint = () -> nothing)
    candidates = NamedTuple[_fa_rank_candidate(0), _fa_rank_candidate(1)]
    attempts = NamedTuple[]
    invalid = _fa_rank_preflight(Y, X, Z, pedigree, ids, traits, iterations)
    if invalid !== nothing
        candidates = NamedTuple[_fa_rank_candidate(k; reason = invalid) for k in 0:1]
        return _fa_rank_publish!(ledger_sink, candidates, attempts;
            selection_status = :unsupported_input, reason = invalid)
    end
    local ctx
    try
        ctx = _fa_rank_context(Y, X, Z, pedigree, traits)
    catch err
        err isa InterruptException && rethrow()
        why = "pedigree/model construction failed: $(sprint(showerror, err))"
        candidates = NamedTuple[_fa_rank_candidate(k; reason = why) for k in 0:1]
        return _fa_rank_publish!(ledger_sink, candidates, attempts;
            selection_status = :unsupported_input, reason = why)
    end
    records = size(Y, 1)
    design_fp = bytes2hex(sha256(repr((ctx.Y, ctx.X, ctx.Z, ctx.traits, ctx.ids))))
    rel_fp = bytes2hex(sha256(repr(ctx.A)))
    ratio = _fa_rank_kernel_ratio(ctx.A, ctx.Z)
    if !isfinite(ratio) || ratio <= 1e-8
        why = "genetic and residual kernels are unresolved on REML contrasts (ratio=$(ratio))"
        candidates = NamedTuple[_fa_rank_candidate(k; reason = why) for k in 0:1]
        return _fa_rank_publish!(ledger_sink, candidates, attempts;
            selection_status = :unsupported_input, reason = why,
            records, design_fingerprint = design_fp, relationship_fingerprint = rel_fp,
            kernel_ratio = ratio)
    end
    function publish(; kwargs...)
        _fa_rank_publish!(ledger_sink, candidates, attempts;
            records, design_fingerprint = design_fp, relationship_fingerprint = rel_fp,
            kernel_ratio = ratio,
            kwargs...)
    end
    function runstart(k, name, index, params0)
        push!(attempts, _fa_rank_attempt(k, name, index;
                                         initial_parameters = copy(params0)))
        candidates[k + 1] = merge(candidates[k + 1],
            (; status = :running, attempts_count = count(a -> a.rank == k, attempts)))
        publish()
        objective = p -> _fa_rank_objective(p, ctx, k)
        try
            out = attempt_runner(objective, params0, iterations, k, name)
            attempts[end] = _fa_rank_evaluate_attempt(ctx, k, name, index, params0, out)
        catch err
            if err isa InterruptException
                attempts[end] = merge(attempts[end], (; status = :interrupted,
                    reason = "interrupted during optimizer start"))
                candidates[k + 1] = merge(_fa_rank_candidate_from_attempts(k, attempts),
                    (; status = :interrupted, reason = "interrupted during optimizer start"))
                publish(; selection_status = :interrupted,
                    reason = "interrupted during optimizer start")
                rethrow()
            end
            attempts[end] = merge(attempts[end], (; status = :failed,
                reason = "optimizer start failed: $(sprint(showerror, err))"))
        end
        candidates[k + 1] = _fa_rank_candidate_from_attempts(k, attempts)
        publish()
        return attempts[end]
    end
    local p0, f0, f1
    try
        p0, f0, f1 = _fa_rank_starts(ctx)
    catch err
        err isa InterruptException && rethrow()
        why = "selector start construction failed: $(sprint(showerror, err))"
        candidates = NamedTuple[_fa_rank_candidate(k; reason = why) for k in 0:1]
        return publish(; selection_status = :unavailable, reason = why)
    end
    runstart(0, :default, 0, p0)
    try
        checkpoint()
    catch err
        if err isa InterruptException
            publish(; selection_status = :interrupted,
                reason = "interrupted between rank candidates")
        end
        rethrow()
    end
    runstart(1, :default, 0, f0)
    runstart(1, :balanced, 0, f1)
    c0, c1 = candidates
    fa_rows = filter(a -> a.rank == 1, attempts)
    better_unconverged = c1.eligible && any(a -> a.status == :completed && a.converged === false &&
        a.loglik !== nothing && a.loglik > c1.loglik + _FA_RANK_TAU / 2, fa_rows)
    nonnested = c0.eligible && c1.eligible && c1.loglik < c0.loglik - _FA_RANK_TAU / 2
    retry_needed = !c1.eligible || nonnested || better_unconverged
    if retry_needed
        diagonal = findfirst(a -> a.rank == 0 && a.eligible, attempts)
        retry_failure = nothing
        if diagonal === nothing
            # A retry cannot be floor-safe without an eligible K0 covariance.
            retry_failure = "eligible diagonal covariance unavailable for retry"
        else
            local retry
            try
                retry = _fa_rank_retry_params(attempts[diagonal])
                runstart(1, :diagonal_retry, 1, retry)
            catch err
                err isa InterruptException && rethrow()
                retry_failure = "FA retry initializer failed: $(sprint(showerror, err))"
            end
        end
        candidates[2] = _fa_rank_candidate_from_attempts(1, attempts)
        retry_failure === nothing || (candidates[2] = merge(candidates[2], (; reason = retry_failure)))
        publish()
    end
    for k in 0:1
        c = candidates[k + 1]
        if c.eligible
            j = findfirst(a -> a.rank == k && a.start_id == c.selected_start && a.eligible, attempts)
            attempts[j] = merge(attempts[j], (; selected_within_rank = true))
        end
    end
    c0, c1 = candidates
    start_sensitive = begin
        fa_finite = [a.loglik for a in attempts if a.rank == 1 && a.status == :completed &&
                     a.loglik !== nothing && isfinite(a.loglik)]
        length(fa_finite) > 1 && maximum(fa_finite) - minimum(fa_finite) > _FA_RANK_TAU / 2 ||
            (c1.eligible && any(a -> a.rank == 1 && a.status == :completed && a.converged === false &&
                a.loglik !== nothing && a.loglik > c1.loglik, attempts))
    end
    boundary = (c0.near_floor === true) || (c1.near_floor === true)
    diagonal = findfirst(a -> a.rank == 0 && a.selected_within_rank, attempts)
    nesting_discrepancy = diagonal === nothing ? nothing :
        _fa_rank_nesting_discrepancy(ctx, attempts[diagonal])
    score = c0.eligible && c1.eligible ? _fa_rank_score(c0.loglik, c1.loglik) : nothing
    why = if nesting_discrepancy !== nothing &&
             (!isfinite(nesting_discrepancy) || nesting_discrepancy > _FA_RANK_RECHECK_TOL)
        "matched-floor L=0 nesting witness differs from the diagonal objective"
    elseif !c0.eligible || !c1.eligible
        "both ranks require an eligible converged start"
    elseif c1.loglik < c0.loglik - _FA_RANK_TAU / 2
        "FA likelihood remains non-nested below the diagonal fit"
    elseif any(a -> a.rank == 1 && a.status == :completed && a.converged === false && a.loglik !== nothing &&
                      a.loglik > c1.loglik + _FA_RANK_TAU / 2, attempts)
        "a better finite unconverged FA attempt remains after the retry budget"
    else
        nothing
    end
    if why !== nothing
        return publish(; selection_status = :unavailable, reason = why,
            criterion_difference = score === nothing ? nothing : score.criterion_difference,
            near_tie = score === nothing ? nothing : score.near_tie,
            boundary_sensitive = boundary, start_sensitive,
            nesting_witness_discrepancy = nesting_discrepancy)
    end
    D, tie, winner = score.criterion_difference, score.near_tie, score.selected_rank
    chosen = findfirst(a -> a.rank == winner && a.selected_within_rank, attempts)
    attempts[chosen] = merge(attempts[chosen], (; selected = true))
    fit = _fa_rank_fit(ctx, attempts[chosen], candidates, attempts)
    return publish(; selection_status = :selected, selected_rank = winner,
        criterion_difference = D, near_tie = tie, boundary_sensitive = boundary,
        start_sensitive, selected_fit = fit,
        nesting_witness_discrepancy = nesting_discrepancy)
end
