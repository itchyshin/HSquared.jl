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
                          optimizer_iterations = nothing, finite_objective = nothing,
                          finite_estimates = nothing, pd_genetic = nothing,
                          pd_residual = nothing, loglik = nothing,
                          reevaluated_loglik = nothing, objective_discrepancy = nothing,
                          criterion = nothing, uniqueness = nothing,
                          floor_distances = nothing, near_floor = nothing,
                          eligible = false, selected_within_rank = false,
                          selected = false, genetic_covariance = nothing,
                          residual_covariance = nothing, genetic_loadings = nothing,
                          initial_parameters = nothing, estimated_parameters = nothing)
    (; rank = k, structure = _fa_rank_structure(k), start_id, retry_index,
       attempted = true,
       status, reason, converged, optimizer_status, optimizer_iterations,
       finite_objective, finite_estimates, pd_genetic, pd_residual, loglik,
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
                         nesting_witness_discrepancy = nothing)
    (; selection_status, reason, requested_ranks = (0, 1), selected_rank,
       criterion = :reml_aic_covariance, criterion_status = :experimental,
       q = (14, 18), penalties = (28, 36), criterion_difference,
       tie_tolerance = _FA_RANK_TAU, near_tie, records, design_fingerprint,
       relationship_fingerprint, kernel_ratio, nesting_witness_discrepancy,
       candidate_summary = copy(candidates),
       attempts = copy(attempts), boundary_sensitive, start_sensitive,
       uncertainty_scope = :conditional_on_selected_rank, selected_fit)
end

function _fa_rank_publish!(sink, candidates, attempts; kwargs...)
    snapshot = _fa_rank_result(candidates, attempts; kwargs...)
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
    opt_iter = _fa_rank_read_or(() -> Int(out.iterations), nothing)
    opt_status = _fa_rank_read_or(() -> string(out.optimizer_status), "unknown")
    finite_objective = isfinite(obj)
    finite_estimates = length(p) == _fa_rank_q(k) && all(isfinite, p)
    core = (; converged, optimizer_status = opt_status, optimizer_iterations = opt_iter,
            finite_objective, finite_estimates, estimated_parameters = p)
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
        near_floor = near, loglik = finite_objective ? -obj : nothing,
        criterion = finite_objective ? 2obj + 2 * _fa_rank_q(k) : nothing))
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
    return merge(info, (; status = :completed,
        reason = converged ? nothing : "optimizer did not converge",
        eligible = converged))
end

function _fa_rank_candidate_from_attempts(k, attempts)
    rows = filter(a -> a.rank == k, attempts)
    isempty(rows) && return _fa_rank_candidate(k)
    good = filter(a -> a.eligible, rows)
    finite = filter(a -> a.loglik !== nothing && isfinite(a.loglik), rows)
    chosen = isempty(good) ? nothing : good[argmax(getproperty.(good, :loglik))]
    obj_range = length(finite) > 1 ? maximum(a.loglik for a in finite) -
                                     minimum(a.loglik for a in finite) : nothing
    covs = filter(a -> a.genetic_covariance !== nothing && a.residual_covariance !== nothing &&
                       a.finite_estimates === true, rows)
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
                        iterations = 2_000, ledger_sink = nothing)
    return _select_fa_rank(Y, X, Z, pedigree; ids, traits, iterations, ledger_sink)
end

function select_fa_rank(Y, X, Z, relationship;
                        ids = nothing, traits = nothing,
                        iterations = 2_000, ledger_sink = nothing)
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
        fa_finite = [a.loglik for a in attempts if a.rank == 1 && a.loglik !== nothing && isfinite(a.loglik)]
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
