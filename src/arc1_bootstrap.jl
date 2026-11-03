"""Return the fixed-B percentile bootstrap for the four ARC1 trait heritabilities.

This is a candidate internal API. Formation records computation only; it does
not establish interval calibration. `selector` is called once per seed with
the complete response, fixed-effect design, incidence matrix and pedigree.
It receives no starts or generating values, so each call runs the frozen
automatic K0/K1 selection schedule.
"""
const _ARC1_BOOTSTRAP_METHOD = "arc1_bootstrap_v1"
const _ARC1_BOOTSTRAP_METHOD_VERSION = 1
const _ARC1_BOOTSTRAP_POLICY = "arc1_v1"
const _ARC1_BOOTSTRAP_POLICY_VERSION = 1
const _ARC1_BOOTSTRAP_V2_METHOD = "arc1_bootstrap_v2"
const _ARC1_BOOTSTRAP_V2_METHOD_VERSION = 2
const _ARC1_BOOTSTRAP_V2_POLICY = "arc1_v2"
const _ARC1_BOOTSTRAP_V2_POLICY_VERSION = 2

_arc1_bootstrap_expected_starts(policy) =
    policy == _ARC1_BOOTSTRAP_POLICY ? 24 :
    policy == _ARC1_BOOTSTRAP_V2_POLICY ? 19 : nothing
const _ARC1_BOOTSTRAP_V2_REPRESENTATION = "retained_factors_v1"
const _ARC1_BOOTSTRAP_V2_GENERATOR = "arc1_factor_gaussian_v1"
const _ARC1_BOOTSTRAP_SEED_VERSION = "explicit_uint64_v1"
const _ARC1_BOOTSTRAP_QUANTILE = "type7"

function _arc1_bootstrap_v2_identity(; actual_optimizer_policy = nothing)
    return (; method = _ARC1_BOOTSTRAP_V2_METHOD,
        method_version = _ARC1_BOOTSTRAP_V2_METHOD_VERSION,
        policy = _ARC1_BOOTSTRAP_V2_POLICY,
        policy_version = _ARC1_BOOTSTRAP_V2_POLICY_VERSION,
        optimizer_policy = _ARC1_BOOTSTRAP_V2_POLICY,
        optimizer_policy_version = _ARC1_BOOTSTRAP_V2_POLICY_VERSION,
        requested_optimizer_policy = _ARC1_BOOTSTRAP_V2_POLICY,
        actual_optimizer_policy,
        covariance_representation = _ARC1_BOOTSTRAP_V2_REPRESENTATION,
        factor_generator_identity = _ARC1_BOOTSTRAP_V2_GENERATOR)
end

function _arc1_bootstrap_design_fingerprint(Y, X, Z, traits, ids)
    return bytes2hex(sha256(repr((Y, X, Z, traits, ids))))
end

function _arc1_bootstrap_relationship(pedigree)
    Ainv = pedigree_inverse(pedigree)
    return inv(Symmetric(Matrix(Ainv)))
end

function _arc1_bootstrap_policy_ok(selection; policy = _ARC1_BOOTSTRAP_POLICY)
    version = policy == _ARC1_BOOTSTRAP_V2_POLICY ? _ARC1_BOOTSTRAP_V2_POLICY_VERSION :
              policy == _ARC1_BOOTSTRAP_POLICY ? _ARC1_BOOTSTRAP_POLICY_VERSION : return false
    hasproperty(selection, :optimizer_policy) && selection.optimizer_policy == policy &&
    hasproperty(selection, :optimizer_policy_version) &&
        selection.optimizer_policy_version == version &&
    hasproperty(selection, :source_identity) && selection.source_identity == _ARC1_SOURCE_IDENTITY &&
    hasproperty(selection, :starts_planned) &&
        selection.starts_planned == _arc1_bootstrap_expected_starts(policy) &&
    (policy != _ARC1_BOOTSTRAP_V2_POLICY ||
        (hasproperty(selection, :requested_optimizer_policy) &&
         selection.requested_optimizer_policy == policy &&
         hasproperty(selection, :actual_optimizer_policy) &&
         selection.actual_optimizer_policy == policy &&
         hasproperty(selection, :covariance_representation) &&
         selection.covariance_representation == _ARC1_BOOTSTRAP_V2_REPRESENTATION))
end

function _arc1_bootstrap_full_automatic(selection; policy = _ARC1_BOOTSTRAP_POLICY)
    _arc1_bootstrap_policy_ok(selection; policy) || return false
    hasproperty(selection, :selected_fit) && selection.selected_fit !== nothing || return false
    fit = selection.selected_fit
    hasproperty(fit, :fa_start_diagnostics) || return false
    d = fit.fa_start_diagnostics
    complete = hasproperty(d, :fixed_rank_request) && d.fixed_rank_request === nothing &&
        hasproperty(d, :source_identity) && d.source_identity == _ARC1_SOURCE_IDENTITY &&
        hasproperty(d, :optimizer_policy) && d.optimizer_policy == policy &&
        hasproperty(d, :optimizer_policy_version) &&
            d.optimizer_policy_version == (policy == _ARC1_BOOTSTRAP_V2_POLICY ?
                _ARC1_BOOTSTRAP_V2_POLICY_VERSION : _ARC1_BOOTSTRAP_POLICY_VERSION) &&
        hasproperty(d, :starts_planned) &&
            d.starts_planned == _arc1_bootstrap_expected_starts(policy) &&
        hasproperty(d, :starts_attempted) &&
            d.starts_attempted == _arc1_bootstrap_expected_starts(policy) &&
        (policy != _ARC1_BOOTSTRAP_V2_POLICY ||
            (hasproperty(fit, :requested_optimizer_policy) && fit.requested_optimizer_policy == policy &&
             hasproperty(fit, :actual_optimizer_policy) && fit.actual_optimizer_policy == policy &&
             hasproperty(fit, :optimizer_policy) && fit.optimizer_policy == policy &&
             hasproperty(fit, :optimizer_policy_version) && fit.optimizer_policy_version == 2 &&
             hasproperty(fit, :covariance_representation) &&
                fit.covariance_representation == _ARC1_BOOTSTRAP_V2_REPRESENTATION))
    complete || return false
    policy == _ARC1_BOOTSTRAP_POLICY && return true
    hasproperty(selection, :guard_results) || return false
    guards = selection.guard_results
    hasproperty(guards, :schedule_complete) && guards.schedule_complete === true &&
        hasproperty(guards, :better_unaccepted) && guards.better_unaccepted === false &&
        hasproperty(guards, :nonnested) && guards.nonnested === false &&
        hasproperty(guards, :nesting_witness) &&
        hasproperty(guards.nesting_witness, :status) &&
        guards.nesting_witness.status == :passed &&
        hasproperty(guards.nesting_witness, :tolerance) &&
        guards.nesting_witness.tolerance == 1e-8 &&
        hasproperty(guards.nesting_witness, :discrepancy) &&
        guards.nesting_witness.discrepancy !== nothing &&
        isfinite(guards.nesting_witness.discrepancy) &&
        0 <= guards.nesting_witness.discrepancy <= 1e-8
end

function _arc1_bootstrap_v2_genetic_factor(state)
    # Preserve floor and uniqueness excess as separate retained factors, even
    # when floor + delta rounds back to floor in Float64. QR gives a canonical
    # square factor; positive diagonal fixes its row-sign convention.
    U = hcat(state.loadings,
        sqrt(state.floor) .* Matrix{Float64}(I, 4, 4),
        Diagonal(sqrt.(state.delta)))
    size(U, 1) == 4 && all(isfinite, U) || return nothing
    Rq = Matrix(qr(transpose(U)).R[1:4, 1:4])
    signs = map(x -> signbit(x) ? -1.0 : 1.0, diag(Rq))
    Rq = Diagonal(signs) * Rq
    all(isfinite, Rq) && all(>(0), diag(Rq)) || return nothing
    return Matrix(transpose(Rq))
end

function _arc1_bootstrap_v2_factor_failure(selection, fit)
    hasproperty(selection, :covariance_representation) &&
        selection.covariance_representation == _ARC1_BOOTSTRAP_V2_REPRESENTATION || return :selection_representation
    hasproperty(fit, :covariance_representation) &&
        fit.covariance_representation == _ARC1_BOOTSTRAP_V2_REPRESENTATION || return :fit_representation
    hasproperty(fit, :factor_valid) && fit.factor_valid === true || return :fit_factor_valid
    hasproperty(fit, :factor_state) || return :missing_factor_state
    state = fit.factor_state
    all(hasproperty(state, name) for name in
        (:rank, :parameters, :loadings, :delta, :floor, :psi, :residual_factor, :G, :R,
         :factor_order, :factor_valid)) || return :incomplete_factor_state
    state.rank == selection.selected_rank && state.factor_valid === true || return :state_rank_or_validity
    state.factor_order == _ARC1_FA_V2_FACTOR_ORDER || return :factor_order
    result = _arc1_fa_v2_factor_state(state.parameters, state.rank)
    result.status == :ok || return :canonical_state_invalid
    canonical = result.state
    state.loadings == canonical.loadings && state.delta == canonical.delta &&
        state.floor == canonical.floor && state.psi == canonical.psi &&
        state.residual_factor == canonical.residual_factor &&
        state.G == canonical.G && state.R == canonical.R || return :state_not_canonical
    hasproperty(fit, :genetic_covariance) && fit.genetic_covariance == state.G || return :genetic_covariance_link
    hasproperty(fit, :residual_covariance) && fit.residual_covariance == state.R || return :residual_covariance_link
    expected_loadings = state.rank == 0 ? nothing : vec(state.loadings)
    hasproperty(fit, :genetic_loadings) && fit.genetic_loadings == expected_loadings ||
        return :loading_link
    hasproperty(fit, :genetic_uniqueness) && fit.genetic_uniqueness == state.psi || return :uniqueness_link
    valid_factor = _arc1_bootstrap_v2_genetic_factor(state) !== nothing &&
        size(state.residual_factor) == (4, 4) && all(isfinite, state.residual_factor) &&
        all(>(0), diag(state.residual_factor))
    return valid_factor ? :ok : :factor_domain
end

_arc1_bootstrap_v2_factor_ok(selection, fit) =
    _arc1_bootstrap_v2_factor_failure(selection, fit) == :ok

function _arc1_bootstrap_outer_check(selection, Y, X, Z, pedigree, ids, traits;
                                     policy = _ARC1_BOOTSTRAP_POLICY)
    ndims(Y) == ndims(X) == ndims(Z) == 2 ||
        throw(ArgumentError("ARC1 bootstrap requires matrix Y, X, and Z"))
    size(Y, 2) == 4 || throw(ArgumentError("ARC1 bootstrap requires exactly four traits"))
    collect(ids) == pedigree.ids || throw(ArgumentError("ids must match pedigree order exactly"))
    length(traits) == 4 || throw(ArgumentError("traits must name the four response columns"))
    size(X, 1) == size(Y, 1) == size(Z, 1) ||
        throw(ArgumentError("Y, X, and Z must have the same record count"))
    length(pedigree.ids) == size(Z, 2) ||
        throw(ArgumentError("pedigree size must match the animal columns of Z"))
    hasproperty(selection, :selection_status) && selection.selection_status == :selected ||
        throw(ArgumentError("outer selection must be a completed automatic selection"))
    hasproperty(selection, :selected_rank) && selection.selected_rank in (0, 1) ||
        throw(ArgumentError("outer selection must retain selected rank 0 or 1"))
    _arc1_bootstrap_policy_ok(selection; policy) ||
        throw(ArgumentError("outer selection source or requested policy identity does not match"))
    _arc1_bootstrap_full_automatic(selection; policy) ||
        throw(ArgumentError("outer selection must retain a completed $(_arc1_bootstrap_expected_starts(policy))-start automatic fit"))
    hasproperty(selection, :selected_fit) && selection.selected_fit !== nothing ||
        throw(ArgumentError("outer selection must retain its point fit"))
    fit = selection.selected_fit
    _arc1_bootstrap_full_automatic(selection; policy) ||
        throw(ArgumentError("outer point fit must retain the complete automatic $(_arc1_bootstrap_expected_starts(policy))-start schedule"))
    Ym, Xm, Zm = Matrix{Float64}(Y), Matrix{Float64}(X), Matrix{Float64}(Z)
    trait_labels = collect(traits)
    hasproperty(selection, :design_fingerprint) &&
        selection.design_fingerprint == _arc1_bootstrap_design_fingerprint(Ym, Xm, Zm, trait_labels, pedigree.ids) ||
        throw(ArgumentError("outer selection design identity does not match Y, X, Z, traits, and IDs"))
    A = _arc1_bootstrap_relationship(pedigree)
    hasproperty(selection, :relationship_fingerprint) &&
        selection.relationship_fingerprint == bytes2hex(sha256(repr(A))) ||
        throw(ArgumentError("outer selection relationship identity does not match the pedigree"))
    hasproperty(fit, :genetic_covariance) && hasproperty(fit, :residual_covariance) &&
        hasproperty(fit, :beta) || throw(ArgumentError("outer point fit lacks G, R, or fixed effects"))
    G = Matrix{Float64}(fit.genetic_covariance)
    R = Matrix{Float64}(fit.residual_covariance)
    beta = if policy == _ARC1_BOOTSTRAP_V2_POLICY
        # The factor-defined v2 fit deliberately withholds beta/BLUP outputs
        # until rounded covariance operations are certified. Recompute the
        # exact GLS beta from the retained v2 parameter vector for simulation.
        spectral = _arc1_fa_spectral_context(Ym, Xm, Zm * A * transpose(Zm))
        spectral.status == :ok || throw(ArgumentError(
            "outer arc1_v2 fixed-effect reconstruction failed: $(spectral.reason)"))
        reconstructed = _arc1_fa_v2_exact_objective_gradient(
            spectral.context, fit.factor_state.parameters, fit.factor_state.rank)
        reconstructed.status == :ok && reconstructed.fixed_effects !== nothing ||
            throw(ArgumentError("outer arc1_v2 fixed-effect reconstruction was not finite"))
        hasproperty(fit, :loglik) && isfinite(fit.loglik) ||
            throw(ArgumentError("outer arc1_v2 point fit lacks a finite reference likelihood"))
        abs(reconstructed.loglik - fit.loglik) <= 1e-8 ||
            throw(ArgumentError("outer arc1_v2 fixed-effect reconstruction changed the fitted likelihood"))
        reconstructed_beta = Matrix{Float64}(reconstructed.fixed_effects)
        if fit.beta !== nothing
            supplied_beta = Matrix{Float64}(fit.beta)
            size(supplied_beta) == size(reconstructed_beta) &&
                all(isfinite, supplied_beta) && isapprox(supplied_beta, reconstructed_beta;
                    rtol = 1e-10, atol = 1e-12) ||
                throw(ArgumentError("outer arc1_v2 supplied fixed effects do not match the exact reconstructed values"))
        end
        reconstructed_beta
    elseif fit.beta !== nothing
        Matrix{Float64}(fit.beta)
    else
        throw(ArgumentError("outer point fit lacks fixed effects"))
    end
    size(G) == size(R) == (4, 4) || throw(ArgumentError("outer G and R must be 4×4"))
    size(beta) == (size(X, 2), 4) || throw(ArgumentError("outer fixed effects must be p×4"))
    all(isfinite, G) && all(isfinite, R) && all(isfinite, beta) ||
        throw(ArgumentError("outer G, R, and fixed effects must be finite"))
    isapprox(G, transpose(G); rtol = 1e-10, atol = 1e-12) &&
        isapprox(R, transpose(R); rtol = 1e-10, atol = 1e-12) ||
        throw(ArgumentError("outer G and R must be symmetric"))
    isposdef(Symmetric(A)) ||
        throw(ArgumentError("outer pedigree relationship must be positive definite"))
    factor_state = nothing
    genetic_factor = nothing
    if policy == _ARC1_BOOTSTRAP_V2_POLICY
        factor_failure = _arc1_bootstrap_v2_factor_failure(selection, fit)
        factor_failure == :ok || throw(ArgumentError(
            "outer arc1_v2 factor certificate or covariance linkage is invalid: $(factor_failure)"))
        factor_state = fit.factor_state
        genetic_factor = _arc1_bootstrap_v2_genetic_factor(factor_state)
        genetic_factor === nothing &&
            throw(ArgumentError("outer arc1_v2 genetic factor is outside the Float64 domain"))
    else
        isposdef(Symmetric(G)) && isposdef(Symmetric(R)) ||
            throw(ArgumentError("outer G and R must be positive definite"))
    end
    h2 = diag(G) ./ (diag(G) .+ diag(R))
    all(isfinite, h2) && all((0 .<= h2) .& (h2 .<= 1)) ||
        throw(ArgumentError("outer point fit gives invalid trait heritabilities"))
    return (; A, G, R, beta, h2, Ym, Xm, Zm, trait_labels,
             factor_state, genetic_factor)
end

function _arc1_bootstrap_type7(values::AbstractVector{<:Real}, probability::Real)
    isempty(values) && return missing
    x = sort!(Float64.(collect(values)))
    all(isfinite, x) || throw(ArgumentError("type-7 quantiles require finite values"))
    0 <= probability <= 1 || throw(ArgumentError("quantile probability must be in [0, 1]"))
    h = (length(x) - 1) * Float64(probability) + 1
    lo = floor(Int, h)
    hi = ceil(Int, h)
    lo == hi && return x[lo]
    return x[lo] + (h - lo) * (x[hi] - x[lo])
end

function _arc1_bootstrap_summary(result, n::Integer)
    1 <= n <= length(result.attempts) ||
        throw(ArgumentError("bootstrap prefix must be between 1 and the requested B"))
    attempts = result.attempts[1:n]
    usable = filter(a -> a.status == :ok && length(a.h2) == 4 && all(isfinite, a.h2), attempts)
    required = cld(99n, 100)
    formed = length(usable) >= required
    endpoints = ntuple(i -> formed ?
        (_arc1_bootstrap_type7([a.h2[i] for a in usable], 0.025),
         _arc1_bootstrap_type7([a.h2[i] for a in usable], 0.975)) : (missing, missing), 4)
    ranks = Dict(0 => count(a -> a.selected_rank === 0, usable),
                 1 => count(a -> a.selected_rank === 1, usable))
    failure_causes = Dict{String,Int}()
    for a in attempts
        if a.status != :ok
            cause = something(a.failure_reason, string(a.status))
            key = first(split(cause, ":"; limit = 2))
            failure_causes[key] = get(failure_causes, key, 0) + 1
        end
    end
    intervals = [(estimand = :heritability, trait = result.traits[i], segment = 1,
        estimate = result.point_estimates[i], lower = endpoints[i][1], upper = endpoints[i][2],
        formed, status = formed ? :formed : :insufficient_usable_bootstrap) for i in 1:4]
    return merge(result, (; requested_bootstrap_count = n,
        usable_bootstrap_count = length(usable), required_usable_count = required,
        formed, status = formed ? :formed : :insufficient_usable_bootstrap,
        prefix_size = n, retained_full_stream_count = length(result.attempts),
        intervals, rank_frequencies = ranks, failure_causes,
        counts = (; planned = n,
            started = count(a -> a.status ∉ (:unattempted, :not_run_after_interruption,
                                               :not_run_after_outer_selection_failure), attempts),
            completed = count(a -> a.status in (:ok, :failed, :selection_failed), attempts),
            usable = length(usable), failed = count(a -> a.status in (:failed, :selection_failed), attempts),
            interrupted = count(a -> a.status == :interrupted, attempts),
            not_run = count(a -> a.status in (:not_run_after_interruption,
                                               :not_run_after_outer_selection_failure), attempts))))
end

function _arc1_bootstrap_starts_attempted(ledger, selection = nothing)
    ledger !== nothing && hasproperty(ledger, :starts_attempted) &&
        return Int(ledger.starts_attempted)
    rows = ledger !== nothing && hasproperty(ledger, :attempts) ? ledger.attempts :
           selection !== nothing && hasproperty(selection, :attempts) ? selection.attempts : nothing
    rows === nothing && return selection !== nothing && hasproperty(selection, :starts_attempted) ?
        Int(selection.starts_attempted) : 0
    return count(rows) do row
        hasproperty(row, :attempted) ? Bool(row.attempted) :
            !(hasproperty(row, :status) && row.status in (:queued, :unattempted))
    end
end

function _arc1_bootstrap_outer_selection_failure(selection, seeds, traits)
    reason = hasproperty(selection, :reason) && selection.reason !== nothing ?
        string(selection.reason) : hasproperty(selection, :selection_status) ?
            string(selection.selection_status) : "outer selection unavailable"
    source_identity = hasproperty(selection, :source_identity) && selection.source_identity !== nothing ?
        selection.source_identity : _ARC1_SOURCE_IDENTITY
    policy = hasproperty(selection, :optimizer_policy) &&
        selection.optimizer_policy == _ARC1_BOOTSTRAP_V2_POLICY ?
        _ARC1_BOOTSTRAP_V2_POLICY : _ARC1_BOOTSTRAP_POLICY
    actual = hasproperty(selection, :actual_optimizer_policy) ?
        selection.actual_optimizer_policy : nothing
    identity = policy == _ARC1_BOOTSTRAP_V2_POLICY ?
        _arc1_bootstrap_v2_identity(; actual_optimizer_policy = actual) : nothing
    expected_starts = _arc1_bootstrap_expected_starts(policy)
    attempts = [(; seed, status = :not_run_after_outer_selection_failure,
        failure_reason = "outer_selection_failure: " * reason,
        selected_rank = nothing, h2 = Float64[], selector_status = :not_run,
        candidate_summary = nothing, selector_attempts = nothing,
        selected_fit_summary = nothing, starts_planned = expected_starts, starts_attempted = 0,
        selector_ledger = nothing, source_identity,
        optimizer_policy = policy,
        optimizer_policy_version = policy == _ARC1_BOOTSTRAP_V2_POLICY ?
            _ARC1_BOOTSTRAP_V2_POLICY_VERSION : _ARC1_BOOTSTRAP_POLICY_VERSION) for seed in seeds]
    if identity !== nothing
        attempts = [merge(a, identity) for a in attempts]
    end
    base = (; schema = "arc1-bootstrap-result-v1", method = _ARC1_BOOTSTRAP_METHOD,
        method_version = _ARC1_BOOTSTRAP_METHOD_VERSION, policy = _ARC1_BOOTSTRAP_POLICY,
        policy_version = _ARC1_BOOTSTRAP_POLICY_VERSION, source_identity,
        reference_source_identity = source_identity,
        design_fingerprint = hasproperty(selection, :design_fingerprint) ? selection.design_fingerprint : "unavailable",
        relationship_fingerprint = hasproperty(selection, :relationship_fingerprint) ? selection.relationship_fingerprint : "unavailable",
        seed_derivation_version = _ARC1_BOOTSTRAP_SEED_VERSION,
        rng_identity = "MersenneTwister", julia_version = string(VERSION),
        quantile_convention = _ARC1_BOOTSTRAP_QUANTILE,
        estimand = "trait_h2_i=G_ii/(G_ii+R_ii)", traits = collect(traits),
        point_estimates = fill(NaN, 4), point_fit = nothing, outer_selection = selection,
        requested_seeds = copy(seeds), attempts,
        interruption_ledger = nothing,
        outer_selection_failure = reason,
        calibration_status = :unverified,
        formation_claim = :computational_formation_only)
    identity === nothing || (base = merge(base, identity,
        (; schema = "arc1-bootstrap-result-v2")))
    return _arc1_bootstrap_summary(base, length(seeds))
end

"""Summarize a nested prefix without changing or replacing any stored attempt."""
_arc1_bootstrap_prefix(result, n::Integer) = _arc1_bootstrap_summary(result, n)

"""Run fixed-B, selector-repeating percentile bootstrap for ARC1 trait h².

`seeds` must be the exact, unique UInt64 vector allocated to this result. A
failed or interrupted fit remains in the denominator; no retry or replacement
is performed. The returned `calibration_status` is always `:unverified`.
"""
function _arc1_bootstrap(selection, Y, X, Z, pedigree; seeds::AbstractVector{UInt64},
                         ids, traits, selector = _arc1_select_fa_rank)
    isempty(seeds) && throw(ArgumentError("bootstrap seeds must be nonempty"))
    length(unique(seeds)) == length(seeds) || throw(ArgumentError("bootstrap seeds must be unique"))
    length(traits) == 4 || throw(ArgumentError("traits must name the four response columns"))
    outer_available = hasproperty(selection, :selection_status) && selection.selection_status == :selected &&
        hasproperty(selection, :selected_rank) && selection.selected_rank in (0, 1) &&
        hasproperty(selection, :selected_fit) && selection.selected_fit !== nothing
    outer_available || return _arc1_bootstrap_outer_selection_failure(selection, seeds, traits)
    policy = hasproperty(selection, :optimizer_policy) &&
        selection.optimizer_policy == _ARC1_BOOTSTRAP_V2_POLICY ?
        _ARC1_BOOTSTRAP_V2_POLICY : _ARC1_BOOTSTRAP_POLICY
    identity = policy == _ARC1_BOOTSTRAP_V2_POLICY ? _arc1_bootstrap_v2_identity() : nothing
    expected_starts = _arc1_bootstrap_expected_starts(policy)
    outer = _arc1_bootstrap_outer_check(selection, Y, X, Z, pedigree, ids, traits; policy)
    n, q = size(outer.Ym, 1), size(outer.Zm, 2)
    LA = cholesky(Symmetric(outer.A)).L
    LG = policy == _ARC1_BOOTSTRAP_V2_POLICY ? outer.genetic_factor :
         cholesky(Symmetric(outer.G)).L
    LR = policy == _ARC1_BOOTSTRAP_V2_POLICY ? outer.factor_state.residual_factor :
         cholesky(Symmetric(outer.R)).L
    attempts = NamedTuple[]
    for seed in seeds
        push!(attempts, (; seed, status = :unattempted, failure_reason = nothing,
            selected_rank = nothing, h2 = Float64[], selector_status = nothing,
            candidate_summary = nothing, selector_attempts = nothing,
            selected_fit_summary = nothing, starts_planned = expected_starts, starts_attempted = 0,
            selector_ledger = nothing,
            source_identity = selection.source_identity,
            optimizer_policy = policy,
            optimizer_policy_version = policy == _ARC1_BOOTSTRAP_V2_POLICY ?
                _ARC1_BOOTSTRAP_V2_POLICY_VERSION : _ARC1_BOOTSTRAP_POLICY_VERSION))
    end
    identity === nothing || (attempts = NamedTuple[merge(a, identity) for a in attempts])
    interrupted_at = nothing
    for i in eachindex(seeds)
        seed = seeds[i]
        inner_ledger = Ref{Any}(nothing)
        try
            rng = Random.MersenneTwister(seed)
            animal = LA * randn(rng, q, 4) * transpose(LG)
            response = outer.Xm * outer.beta + outer.Zm * animal +
                       randn(rng, n, 4) * transpose(LR)
            inner = if policy == _ARC1_BOOTSTRAP_V2_POLICY
                selector(response, outer.Xm, outer.Zm, pedigree;
                         ids = pedigree.ids, traits = outer.trait_labels,
                         optimizer_policy = policy, ledger_sink = inner_ledger)
            else
                selector(response, outer.Xm, outer.Zm, pedigree;
                         ids = pedigree.ids, traits = outer.trait_labels,
                         ledger_sink = inner_ledger)
            end
            inner_common = (; selector_status = hasproperty(inner, :selection_status) ? inner.selection_status : :missing,
                selected_rank = hasproperty(inner, :selected_rank) ? inner.selected_rank : nothing,
                candidate_summary = hasproperty(inner, :candidate_summary) ? inner.candidate_summary : nothing,
                selector_attempts = hasproperty(inner, :attempts) ? inner.attempts : nothing,
                starts_planned = hasproperty(inner, :starts_planned) ? inner.starts_planned : 0,
                starts_attempted = hasproperty(inner, :starts_attempted) ? inner.starts_attempted : 0,
                guard_results = hasproperty(inner, :guard_results) ? inner.guard_results : nothing,
                source_identity = hasproperty(inner, :source_identity) ? inner.source_identity : nothing,
                optimizer_policy = hasproperty(inner, :optimizer_policy) ? inner.optimizer_policy : nothing,
                optimizer_policy_version = hasproperty(inner, :optimizer_policy_version) ? inner.optimizer_policy_version : nothing)
            if policy == _ARC1_BOOTSTRAP_V2_POLICY
                inner_common = merge(inner_common, (; requested_optimizer_policy =
                    hasproperty(inner, :requested_optimizer_policy) ? inner.requested_optimizer_policy : nothing,
                    actual_optimizer_policy = hasproperty(inner, :actual_optimizer_policy) ?
                        inner.actual_optimizer_policy : nothing,
                    covariance_representation = hasproperty(inner, :covariance_representation) ?
                        inner.covariance_representation : nothing))
            end
            design_matches = hasproperty(inner, :design_fingerprint) &&
                inner.design_fingerprint == _arc1_bootstrap_design_fingerprint(
                    response, outer.Xm, outer.Zm, outer.trait_labels, pedigree.ids)
            relationship_matches = hasproperty(inner, :relationship_fingerprint) &&
                inner.relationship_fingerprint == selection.relationship_fingerprint
            if hasproperty(inner, :selection_status) && inner.selection_status == :interrupted
                partial = inner_ledger[] === nothing ? inner : inner_ledger[]
                reason = "interrupted: " * (hasproperty(inner, :reason) && inner.reason !== nothing ?
                    string(inner.reason) : "inner selector returned interrupted status")
                identity_ok = _arc1_bootstrap_policy_ok(inner; policy) &&
                    design_matches && relationship_matches
                attempts[i] = merge(attempts[i], inner_common, (; status =
                    policy == _ARC1_BOOTSTRAP_V2_POLICY && !identity_ok ? :failed : :interrupted,
                    selector_ledger = partial,
                    starts_attempted = _arc1_bootstrap_starts_attempted(inner_ledger[], inner),
                    failure_reason = policy == _ARC1_BOOTSTRAP_V2_POLICY && !identity_ok ?
                        "identity_mismatch: interrupted inner selector source, policy, design, or relationship differs" :
                        reason))
                interrupted_at = i
                for j in (i + 1):length(seeds)
                    attempts[j] = merge(attempts[j], (; status = :not_run_after_interruption,
                        failure_reason = "not_run: interrupted at attempt $(i)"))
                end
                break
            elseif !_arc1_bootstrap_policy_ok(inner; policy) || !design_matches || !relationship_matches
                attempts[i] = merge(attempts[i], inner_common, (; status = :failed,
                    failure_reason = "identity_mismatch: inner selector source, policy, design, or relationship differs"))
            elseif inner.selection_status != :selected || inner.selected_fit === nothing ||
                   inner.selected_rank ∉ (0, 1)
                why = hasproperty(inner, :reason) && inner.reason !== nothing ? string(inner.reason) :
                      "inner automatic selector did not return a selected fit"
                attempts[i] = merge(attempts[i], inner_common, (; status = :selection_failed,
                    failure_reason = "selection_failed: " * why))
            elseif !_arc1_bootstrap_full_automatic(inner; policy)
                attempts[i] = merge(attempts[i], inner_common, (; status = :selection_failed,
                    failure_reason = "incomplete_schedule: selected inner fit did not complete all $expected_starts starts"))
            else
                fit = inner.selected_fit
                if !(hasproperty(fit, :genetic_covariance) && hasproperty(fit, :residual_covariance))
                    attempts[i] = merge(attempts[i], inner_common, (; status = :failed,
                        failure_reason = "invalid_fit: inner selected fit lacks G or R"))
                else
                    Gi = Matrix{Float64}(fit.genetic_covariance)
                    Ri = Matrix{Float64}(fit.residual_covariance)
                    fit_summary = (; genetic_covariance = Gi, residual_covariance = Ri,
                        beta = hasproperty(fit, :beta) ? fit.beta : nothing,
                        loglik = hasproperty(fit, :loglik) ? fit.loglik : nothing,
                        converged = hasproperty(fit, :converged) ? fit.converged : nothing,
                        start_diagnostics = hasproperty(fit, :fa_start_diagnostics) ?
                            fit.fa_start_diagnostics : nothing,
                        factor_state = hasproperty(fit, :factor_state) ? fit.factor_state : nothing,
                        covariance_representation = hasproperty(fit, :covariance_representation) ?
                            fit.covariance_representation : nothing)
                    invalid_v2_factors = policy == _ARC1_BOOTSTRAP_V2_POLICY &&
                        !_arc1_bootstrap_v2_factor_ok(inner, fit)
                    if size(Gi) != (4, 4) || size(Ri) != (4, 4) || !all(isfinite, Gi) || !all(isfinite, Ri) ||
                       !isapprox(Gi, transpose(Gi); rtol = 1e-10, atol = 1e-12) ||
                       !isapprox(Ri, transpose(Ri); rtol = 1e-10, atol = 1e-12) ||
                       (policy == _ARC1_BOOTSTRAP_POLICY &&
                        (!isposdef(Symmetric(Gi)) || !isposdef(Symmetric(Ri)))) ||
                       invalid_v2_factors
                        attempts[i] = merge(attempts[i], inner_common,
                            (; selected_fit_summary = fit_summary, status = :failed,
                            failure_reason = invalid_v2_factors ?
                                "invalid_fit: inner arc1_v2 factor certificate or covariance linkage is invalid" :
                                "invalid_fit: inner G and R must be finite 4×4 matrices"))
                    else
                        hi = diag(Gi) ./ (diag(Gi) .+ diag(Ri))
                        if !all(isfinite, hi) || !all((0 .<= hi) .& (hi .<= 1))
                            attempts[i] = merge(attempts[i], inner_common,
                                (; selected_fit_summary = fit_summary, status = :failed,
                                failure_reason = "invalid_estimand: inner trait h² is outside [0, 1]"))
                        else
                            attempts[i] = merge(attempts[i], inner_common,
                                (; selected_fit_summary = fit_summary, status = :ok,
                                failure_reason = nothing, h2 = collect(hi)))
                        end
                    end
                end
            end
        catch err
            if err isa InterruptException
                attempts[i] = merge(attempts[i], (; status = :interrupted,
                    selector_ledger = inner_ledger[],
                    guard_results = inner_ledger[] !== nothing && hasproperty(inner_ledger[], :guard_results) ?
                        inner_ledger[].guard_results : nothing,
                    starts_attempted = _arc1_bootstrap_starts_attempted(inner_ledger[]),
                    failure_reason = "interrupted: $(sprint(showerror, err))"))
                interrupted_at = i
                for j in (i + 1):length(seeds)
                    attempts[j] = merge(attempts[j], (; status = :not_run_after_interruption,
                        failure_reason = "not_run: interrupted at attempt $(i)"))
                end
                break
            end
            attempts[i] = merge(attempts[i], (; status = :failed,
                selector_ledger = inner_ledger[],
                guard_results = inner_ledger[] !== nothing && hasproperty(inner_ledger[], :guard_results) ?
                    inner_ledger[].guard_results : nothing,
                failure_reason = "exception: $(sprint(showerror, err))"))
        end
    end
    base = (; schema = "arc1-bootstrap-result-v1",
        method = _ARC1_BOOTSTRAP_METHOD,
        method_version = _ARC1_BOOTSTRAP_METHOD_VERSION,
        policy = _ARC1_BOOTSTRAP_POLICY,
        policy_version = _ARC1_BOOTSTRAP_POLICY_VERSION,
        source_identity = selection.source_identity,
        reference_source_identity = selection.source_identity,
        design_fingerprint = selection.design_fingerprint,
        relationship_fingerprint = selection.relationship_fingerprint,
        seed_derivation_version = _ARC1_BOOTSTRAP_SEED_VERSION,
        rng_identity = "MersenneTwister",
        julia_version = string(VERSION),
        quantile_convention = _ARC1_BOOTSTRAP_QUANTILE,
        estimand = "trait_h2_i=G_ii/(G_ii+R_ii)",
        traits = collect(traits),
        point_estimates = collect(outer.h2),
        point_fit = selection.selected_fit,
        requested_seeds = copy(seeds),
        attempts = attempts,
        interruption_ledger = interrupted_at === nothing ? nothing :
            (; attempt = interrupted_at, seed = seeds[interrupted_at],
              completed_rows = interrupted_at, planned_rows = length(seeds)),
        calibration_status = :unverified,
        formation_claim = :computational_formation_only)
    if identity !== nothing
        base = merge(base, _arc1_bootstrap_v2_identity(; actual_optimizer_policy = policy),
            (; schema = "arc1-bootstrap-result-v2", rank_frequencies_role = :diagnostic_only))
    end
    _arc1_bootstrap_summary(base, length(seeds))
end
