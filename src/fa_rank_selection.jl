# Experimental, explicit T4 pedigree Gaussian selector. This code deliberately
# leaves fit_multivariate_reml and its public fixed-rank parameter maps untouched.
const _FA_RANK_TAU = 1e-6
const _FA_RANK_RECHECK_TOL = 1e-8

_fa_rank_structure(k) = k == 0 ? :diagonal : :factor_analytic
_fa_rank_q(k) = k == 0 ? 14 : 18

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
                           kwargs...)
    snapshot = _fa_rank_result(candidates, attempts; kwargs...)
    if optimizer_policy !== nothing
        snapshot = merge(snapshot, (; optimizer_policy, optimizer_policy_version, source_identity,
            optimizer_algorithm = :bfgs_hager_zhang, optimizer_iterations = 2_000,
            optimizer_tolerance = 1e-8, final_scaled_gradient_tolerance = 1e-6,
            numerical_gradient_steps = (1e-4, 1e-5), numerical_gradient_tolerance = 5e-6,
            starts_planned = 19, starts_attempted = count(a -> hasproperty(a, :attempted) && a.attempted, attempts)))
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

function _fa_rank_evaluate_attempt(ctx, k, start_id, retry_index, params0, out)
    base = _fa_rank_attempt(k, start_id, retry_index;
                            initial_parameters = copy(params0))
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
        a.pd_genetic === true && a.pd_residual === true &&
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

function _fa_rank_fit(ctx, attempt, candidates, attempts)
    G, R = attempt.genetic_covariance, attempt.residual_covariance
    beta, ebv = _mv_gls_blup(ctx.y, ctx.Xfull, ctx.Zfull, ctx.A, ctx.indiv,
                              length(ctx.y), G, R, 4, 1, length(ctx.ids))
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
    return (; genetic_covariance = G, residual_covariance = R,
        genetic_correlation = genetic_correlation(G), residual_correlation = genetic_correlation(R),
        heritability = [G[i, i] / (G[i, i] + R[i, i]) for i in 1:4], beta,
        breeding_values = (; ids = ctx.ids, traits = ctx.traits, values = ebv),
        genetic_structure = _fa_rank_structure(k), genetic_rank = k == 1 ? 1 : nothing,
        genetic_loadings = attempt.genetic_loadings, genetic_uniqueness = attempt.uniqueness,
        loglik = attempt.loglik, converged = true, iterations = attempt.optimizer_iterations,
        fa_start_diagnostics = diag, traits = ctx.traits)
end

function _arc1_result_with_policy(result, rows, fixed_rank, k0_eligible)
    diag = (; strategy = :arc1_v1_bfgs_hager_zhang,
        optimizer_policy = "arc1_v1", optimizer_policy_version = 1,
        algorithm = :bfgs_hager_zhang, optimizer_iterations = 2_000,
        optimizer_tolerance = 1e-8, final_scaled_gradient_tolerance = 1e-6,
        numerical_gradient_steps = (1e-4, 1e-5), numerical_gradient_tolerance = 5e-6,
        source_identity = _ARC1_SOURCE_IDENTITY, julia_version = string(VERSION),
        optim_version = string(Base.pkgversion(Optim)),
        starts_planned = 19, starts_attempted = count(a -> a.attempted, rows),
        fixed_rank_request = fixed_rank, eligible_k0 = k0_eligible,
        starts = rows)
    fit = result.selected_fit === nothing ? nothing :
          merge(result.selected_fit, (; fa_start_diagnostics = diag))
    return merge(result, (; optimizer_policy = "arc1_v1", optimizer_policy_version = 1,
                           optimizer_algorithm = :bfgs_hager_zhang, optimizer_iterations = 2_000,
                           optimizer_tolerance = 1e-8, final_scaled_gradient_tolerance = 1e-6,
                           numerical_gradient_steps = (1e-4, 1e-5), numerical_gradient_tolerance = 5e-6,
                           starts_planned = 19,
                           starts_attempted = count(a -> hasproperty(a, :attempted) && a.attempted, rows),
                           source_identity = _ARC1_SOURCE_IDENTITY,
                           selected_fit = fit))
end

function _arc1_derived_starts(diagonal_attempt)
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
                              attempt_runner = nothing, checkpoint = () -> nothing)
    candidates = NamedTuple[_fa_rank_candidate(k) for k in 0:1]
    attempts = NamedTuple[]
    function publish(; kwargs...)
        _fa_rank_publish!(ledger_sink, candidates, attempts;
            optimizer_policy = "arc1_v1", optimizer_policy_version = 1,
            source_identity = _ARC1_SOURCE_IDENTITY, kwargs...)
    end
    publish(selection_status = :in_progress, reason = "ARC1 selector initialized")
    invalid = _fa_rank_preflight(Y, X, Z, pedigree, ids, traits, iterations)
    if invalid !== nothing
        candidates = NamedTuple[_fa_rank_candidate(k; status = :unsupported_input,
            reason = invalid) for k in 0:1]
        base = publish(
            selection_status = :unsupported_input, reason = invalid)
        return _arc1_result_with_policy(base, attempts, fixed_rank, false)
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
        return _arc1_result_with_policy(base, attempts, fixed_rank, false)
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
        return _arc1_result_with_policy(base, attempts, fixed_rank, false)
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
        return _arc1_result_with_policy(base, attempts, fixed_rank, false)
    end
    publish_context(; kwargs...) = publish(; records, design_fingerprint = design_fp,
        relationship_fingerprint = rel_fp, kernel_ratio = ratio, kwargs...)
    runner = attempt_runner === nothing ? nothing : attempt_runner
    # Declare the full frozen schedule before fitting so interruptions retain
    # explicit rows for every not-yet-run start.
    push!(attempts, merge(_fa_rank_attempt(0, :default, 0;
        status = :unattempted, reason = "queued"), (; attempted = false)))
    for name in (:default, :balanced)
        push!(attempts, merge(_fa_rank_attempt(1, name, 0;
            status = :unattempted, reason = "queued"), (; attempted = false)))
    end
    for a in (0.1, 0.7), mask in 0:7
        name = Symbol("derived_a$(a)_s$(mask)")
        push!(attempts, merge(_fa_rank_attempt(1, name, 0;
            status = :unattempted, reason = "awaiting eligible K0 estimate"),
            (; attempted = false)))
    end
    function runstart(k, name, params0)
        rowidx = findfirst(a -> a.rank == k && a.start_id == name && !a.attempted, attempts)
        fresh = _fa_rank_attempt(k, name, 0; initial_parameters = copy(params0))
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
            out = if runner === nothing
                fit = _arc1_fa_bfgs(ctx.spectral, params0, k)
        (; phat = fit.phat, objective = fit.raw_objective,
                   converged = fit.optimizer_converged,
                   optimizer_converged = fit.optimizer_converged,
                   optimizer_assessment_status = fit.optimizer_assessment_status,
                   optimizer_assessment_reason = fit.optimizer_assessment_reason,
                   iterations = fit.iterations,
                   optimizer_status = fit.optimizer_status,
                   scaled_objective = fit.objective,
                   final_gradient_inf_norm = fit.final_gradient_inf_norm,
                   numerical_gradient_inf_norms = fit.numerical_gradient_inf_norms,
                   numerical_gradient_discrepancies = fit.numerical_gradient_discrepancies,
                   numerical_gradient_status = fit.numerical_gradient_status,
                   line_search_success = fit.line_search_success,
                   line_search_stats = fit.line_search_stats,
                   algorithm = fit.algorithm, optimizer_assessment = fit)
            else
                runner(ctx.spectral, params0, k, name)
            end
            row = _fa_rank_evaluate_attempt(ctx, k, name, 0, params0, out)
            if hasproperty(out, :line_search_success) && !out.line_search_success
                row = merge(row, (; status = :failed,
                    eligible = false, reason = "Hager-Zhang line search failed"))
            end
            extra = (; scaled_objective = hasproperty(out, :scaled_objective) ? out.scaled_objective : nothing,
                     final_gradient_inf_norm = hasproperty(out, :final_gradient_inf_norm) ? out.final_gradient_inf_norm : nothing,
                     numerical_gradient_inf_norms = hasproperty(out, :numerical_gradient_inf_norms) ? out.numerical_gradient_inf_norms : nothing,
                     numerical_gradient_discrepancies = hasproperty(out, :numerical_gradient_discrepancies) ? out.numerical_gradient_discrepancies : nothing,
                     numerical_gradient_status = hasproperty(out, :numerical_gradient_status) ? out.numerical_gradient_status : :test_seam,
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
            attempts[rowidx] = merge(row, extra)
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
    p0, f0, f1 = _fa_rank_starts(ctx)
    runstart(0, :default, p0)
    try
        checkpoint()
    catch err
        if err isa InterruptException
            publish_context(; selection_status = :interrupted, reason = "interrupted after K0 start")
            return _arc1_result_with_policy(publish_context(; selection_status = :interrupted,
                reason = "interrupted after K0 start"), attempts, fixed_rank, candidates[1].eligible)
        end
        rethrow()
    end
    runstart(1, :default, f0)
    runstart(1, :balanced, f1)
    k0row = findfirst(a -> a.rank == 0 && a.eligible, attempts)
    derived = NamedTuple[]
    if k0row !== nothing
        derived = _arc1_derived_starts(attempts[k0row])
        for start in derived
            runstart(1, start.name, start.params)
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
                reason = "interrupted after K1 starts"), attempts, fixed_rank, candidates[1].eligible)
        end
        rethrow()
    end
    c0, c1 = candidates
    k1rows = filter(a -> a.rank == 1 && a.attempted, attempts)
    schedule_complete = count(a -> a.attempted, k1rows) == 18 &&
                        count(a -> a.start_id in (:default, :balanced), k1rows) == 2 &&
                        count(a -> startswith(string(a.start_id), "derived_"), k1rows) == 16
    better_unaccepted = c1.eligible && any(a -> a.attempted && !a.eligible &&
        a.finite_objective === true && a.finite_estimates === true &&
        a.pd_genetic === true && a.pd_residual === true &&
        a.reevaluated_loglik !== nothing && isfinite(a.reevaluated_loglik) &&
        a.objective_discrepancy !== nothing && isfinite(a.objective_discrepancy) &&
        a.objective_discrepancy <= _FA_RANK_RECHECK_TOL &&
        a.floor_distances !== nothing && all(>(0), a.floor_distances) &&
        a.loglik !== nothing && isfinite(a.loglik) &&
        a.loglik > c1.loglik + _FA_RANK_TAU / 2, k1rows)
    nonnested = c0.eligible && c1.eligible && c1.loglik < c0.loglik - _FA_RANK_TAU / 2
    nesting_discrepancy = k0row === nothing ? nothing : _fa_rank_nesting_discrepancy(ctx, attempts[k0row])
    score = c0.eligible && c1.eligible ? _fa_rank_score(c0.loglik, c1.loglik) : nothing
    why = if !c0.eligible
        "an eligible K0 fit is required to complete the ARC1 start schedule"
    elseif !schedule_complete
        "the frozen 18-start K1 schedule was not completed"
    elseif !c1.eligible
        "no eligible converged K1 start"
    elseif nesting_discrepancy === nothing || !isfinite(nesting_discrepancy) ||
           nesting_discrepancy > _FA_RANK_RECHECK_TOL
        "matched-floor L=0 nesting witness differs from the diagonal objective"
    elseif better_unaccepted
        "a materially better finite unaccepted K1 attempt remains after the frozen schedule"
    elseif nonnested
        "FA likelihood remains non-nested below the diagonal fit"
    else
        nothing
    end
    guard_results = (; schedule_complete, better_unaccepted, nonnested,
        nesting_witness = (; status = nesting_discrepancy === nothing ? :unavailable :
            isfinite(nesting_discrepancy) && nesting_discrepancy <= _FA_RANK_RECHECK_TOL ? :passed : :failed,
            discrepancy = nesting_discrepancy, tolerance = _FA_RANK_RECHECK_TOL))
    if why !== nothing
        base = publish_context(; selection_status = :unavailable, reason = why,
            criterion_difference = score === nothing ? nothing : score.criterion_difference,
            near_tie = score === nothing ? nothing : score.near_tie,
            nesting_witness_discrepancy = nesting_discrepancy, guard_results)
        return _arc1_result_with_policy(base, attempts, fixed_rank, c0.eligible)
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
    fit = _fa_rank_fit(ctx, attempts[chosen], candidates, attempts)
    base = publish_context(; selection_status = fixed_rank === nothing ? :selected : :fixed_rank_fit,
        selected_rank = winner,
        criterion_difference = score.criterion_difference, near_tie = score.near_tie,
        selected_fit = fit, nesting_witness_discrepancy = nesting_discrepancy, guard_results)
    return _arc1_result_with_policy(base, attempts, fixed_rank, c0.eligible)
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
    end
    why = "unknown optimizer_policy: $(repr(optimizer_policy)); supported value is \"arc1_v1\""
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
                "unknown optimizer_policy: $(repr(optimizer_policy))") for k in 0:1],
        NamedTuple[]; selection_status = :unsupported_input,
        optimizer_policy = "arc1_v1", optimizer_policy_version = 1,
        source_identity = _ARC1_SOURCE_IDENTITY,
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
