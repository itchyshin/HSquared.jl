# Exact complete-data T4 Gaussian FA objective for the ARC1 rank-selection
# programme. A validated spectral context is built once per fit; optimizer
# evaluations only factor N four-by-four covariance blocks.

function _arc1_tree_identity(root)
    isdir(root) || return "missing"
    files = String[]
    for (dir, _, names) in walkdir(root)
        for name in names
            endswith(name, ".jl") && push!(files, joinpath(dir, name))
        end
    end
    sort!(files)
    payload = join((string(relpath(path, root), ":", bytes2hex(sha256(read(path))))
                    for path in files), "\n")
    return bytes2hex(sha256(payload))
end

# Bind metadata to every Julia source loaded by HSquared plus the exact
# optimizer dependency trees. Register source inputs with Julia's precompiler
# so edits invalidate this identity rather than reusing an old compiled value.
const _ARC1_SOURCE_IDENTITY = let
    root = normpath(joinpath(@__DIR__, ".."))
    srcroot = joinpath(root, "src")
    source_files = String[]
    for (dir, _, names) in walkdir(srcroot)
        for name in names
            endswith(name, ".jl") && push!(source_files, joinpath(dir, name))
        end
    end
    sort!(source_files)
    for path in source_files
        Base.include_dependency(path)
    end
    project_files = filter(isfile, [joinpath(root, "Project.toml"), joinpath(root, "Manifest.toml")])
    foreach(Base.include_dependency, project_files)
    dependency_modules = (Optim, Optim.LineSearches, Optim.NLSolversBase)
    dependency_data = map(dependency_modules) do mod
        pkgroot = Base.pkgdir(mod)
        tree = _arc1_tree_identity(joinpath(pkgroot, "src"))
        "$(nameof(mod))=$(Base.pkgversion(mod))@$tree"
    end
    source_data = join((string(relpath(path, root), ":", bytes2hex(sha256(read(path))))
                        for path in source_files), "\n")
    config_data = join((string(basename(path), ":", bytes2hex(sha256(read(path)))) for path in project_files), "\n")
    isfile(joinpath(root, "Manifest.toml")) || (config_data *= "\nManifest.toml=absent")
    bytes2hex(sha256(source_data * "\n" * config_data * "\nJulia=" * string(VERSION) *
                     "\n" * join(dependency_data, "\n")))
end

mutable struct _Arc1LineSearchStats
    callback_requests::Int
    objective_evaluations::Int
    rejected_trials::Int
    domain_restarts::Int
    observation_events::Union{Nothing,Vector{Any}}
    diagnostic_context::Any
    search_baseline::Any
    search_index::Int
    terminal_reason::Union{Nothing,String}
end
_Arc1LineSearchStats(; observation_events = nothing) =
    _Arc1LineSearchStats(0, 0, 0, 0, observation_events, nothing, nothing, 0, nothing)

function _arc1_observation!(stats::_Arc1LineSearchStats, stage::Symbol, reason::AbstractString;
                            coordinates = nothing, direction = nothing, step = nothing,
                            value = nothing, slope = nothing, outcome = nothing)
    events = stats.observation_events
    events === nothing && return nothing
    context = stats.diagnostic_context
    if context !== nothing
        coordinates === nothing && (coordinates = context.coordinates)
        direction === nothing && (direction = context.direction)
        step === nothing && (step = context.step)
        value === nothing && (value = context.value)
        slope === nothing && (slope = context.slope)
    end
    baseline = stats.search_baseline
    counters = baseline === nothing ?
        (; callback_requests = 0, objective_evaluations = 0, rejected_trials = 0,
           domain_restarts = 0) :
        (; callback_requests = stats.callback_requests - baseline.callback_requests,
           objective_evaluations = stats.objective_evaluations - baseline.objective_evaluations,
           rejected_trials = stats.rejected_trials - baseline.rejected_trials,
           domain_restarts = stats.domain_restarts - baseline.domain_restarts)
    push!(events, (; search_index = stats.search_index, stage, reason = String(reason), outcome,
        coordinates = coordinates === nothing ? nothing : copy(coordinates),
        direction = direction === nothing ? nothing : copy(direction), step, value, slope, counters))
    return nothing
end

function _arc1_requested_trial!(stats::_Arc1LineSearchStats, origin, direction, step)
    stats.observation_events === nothing && return nothing
    trial = origin .+ step .* direction
    stats.diagnostic_context = (; coordinates = copy(trial), direction = copy(direction),
        step = Float64(step), value = nothing, slope = nothing)
    trial
end

struct _Arc1DomainTrial <: Exception
    alpha::Float64
    reason::String
    kind::Symbol
end

struct _Arc1DomainHagerZhang{S,P}
    stats::S
    max_domain_restarts::Int
    max_callback_requests::Int
    make_pair::P
end
_Arc1DomainHagerZhang(stats; max_domain_restarts = 32, max_callback_requests = 256,
                      make_pair = getfield(Optim.LineSearches, :make_ϕ_ϕdϕ)) =
    _Arc1DomainHagerZhang(stats, max_domain_restarts, max_callback_requests, make_pair)

function _arc1_line_search_wolfe_check!(search::_Arc1DomainHagerZhang, origin,
        direction, requested_initial_step, initial_step, step_cap, domain_restart,
        returned_step, origin_value, origin_slope, trial_value, trial_slope,
        wolfe, approximate_wolfe)
    events = search.stats.observation_events
    events === nothing && return nothing
    baseline = search.stats.search_baseline
    counters = baseline === nothing ?
        (; callback_requests = 0, objective_evaluations = 0, rejected_trials = 0,
           domain_restarts = 0) :
        (; callback_requests = search.stats.callback_requests - baseline.callback_requests,
           objective_evaluations = search.stats.objective_evaluations - baseline.objective_evaluations,
           rejected_trials = search.stats.rejected_trials - baseline.rejected_trials,
           domain_restarts = search.stats.domain_restarts - baseline.domain_restarts)
    accepted = wolfe || approximate_wolfe
    push!(events, (; search_index = search.stats.search_index,
        stage = :line_search_wolfe_check,
        reason = accepted ? "returned step satisfies a Wolfe condition" :
                            "returned step satisfies neither Wolfe condition",
        outcome = accepted ? :accepted : :rejected,
        origin = copy(origin), direction = copy(direction),
        requested_initial_step = Float64(requested_initial_step),
        initial_step = Float64(initial_step), step_cap = Float64(step_cap),
        domain_restart = Int(domain_restart), returned_step = Float64(returned_step),
        origin_value = Float64(origin_value), origin_slope = Float64(origin_slope),
        trial_value = Float64(trial_value), trial_slope = Float64(trial_slope),
        wolfe = Bool(wolfe), approximate_wolfe = Bool(approximate_wolfe), counters))
    return nothing
end

function (search::_Arc1DomainHagerZhang)(df, x, direction, alpha, xnew, phi0, dphi0)
    LS = Optim.LineSearches
    LSE = LS.LineSearchException
    NLS = Optim.NLSolversBase
    original_x = copy(x)
    original_direction = copy(direction)
    original_guess = Float64(alpha)
    search.stats.search_index += 1
    search.stats.search_baseline = (; callback_requests = search.stats.callback_requests,
        objective_evaluations = search.stats.objective_evaluations,
        rejected_trials = search.stats.rejected_trials,
        domain_restarts = search.stats.domain_restarts)
    if search.stats.observation_events !== nothing
        search.stats.diagnostic_context = (; coordinates = copy(original_x),
            direction = copy(original_direction), step = nothing, value = phi0, slope = dphi0,
            requested_initial_step = original_guess)
    end

    function set_origin_context!()
        if search.stats.observation_events !== nothing
            search.stats.diagnostic_context = (; coordinates = copy(original_x),
                direction = copy(original_direction), step = nothing, value = phi0, slope = dphi0,
                requested_initial_step = original_guess)
        end
        nothing
    end
    function reset_origin(update_context = true)
        update_context && set_origin_context!()
        copyto!(xnew, original_x)
        try
            NLS.value_gradient!(df, original_x)
        catch err
            err isa InterruptException && rethrow()
            # Preserve the line-search failure as the primary outcome. The
            # origin was finite before the line search began.
        finally
            copyto!(xnew, original_x)
        end
        nothing
    end
    function restore_origin(reason)
        # The terminal refusal describes the restored origin, even when the
        # immediately preceding event was a rejected trial.
        set_origin_context!()
        search.stats.terminal_reason = String(reason)
        _arc1_observation!(search.stats, :line_search_terminal, reason; outcome = :failed)
        reset_origin(false)
        throw(LSE(reason, 0.0))
    end

    isfinite(original_guess) && original_guess > 0 ||
        restore_origin("ARC1 received an invalid initial line-search step")
    all(isfinite, original_x) && all(isfinite, original_direction) &&
        isfinite(phi0) && isfinite(dphi0) && dphi0 < 0 ||
        restore_origin("ARC1 received invalid line-search bounds or a non-descent direction")

    cap = Inf
    callbacks_this_search = 0
    for restart in 0:search.max_domain_restarts
        xnew .= original_x
        phi_raw, phidphi_raw = search.make_pair(df, xnew, original_x, original_direction)
        function request!(a)
            observed_trial = _arc1_requested_trial!(search.stats, original_x,
                original_direction, a)
            callbacks_this_search < search.max_callback_requests || begin
                search.stats.rejected_trials += 1
                _arc1_observation!(search.stats, :line_search_rejection,
                    "line-search callback budget exhausted"; step = a, outcome = :rejected)
                throw(_Arc1DomainTrial(Float64(a), "line-search callback budget exhausted", :budget))
            end
            isfinite(a) && a > 0 || begin
                search.stats.rejected_trials += 1
                _arc1_observation!(search.stats, :line_search_rejection,
                    "line-search trial step is nonfinite or nonpositive"; step = a,
                    outcome = :rejected)
                throw(_Arc1DomainTrial(Float64(a), "line-search trial step is nonfinite or nonpositive", :invalid_step))
            end
            callbacks_this_search += 1
            search.stats.callback_requests += 1
            trial = observed_trial === nothing ? original_x .+ a .* original_direction : observed_trial
            all(isfinite, trial) || begin
                search.stats.rejected_trials += 1
                _arc1_observation!(search.stats, :line_search_rejection,
                    "line-search parameter vector is nonfinite"; outcome = :rejected)
                throw(_Arc1DomainTrial(Float64(a), "line-search parameter vector is nonfinite", :invalid_step))
            end
            nothing
        end
        function phi_guard(a)
            request!(a)
            value = phi_raw(a)
            if search.stats.observation_events !== nothing
                search.stats.diagnostic_context = merge(search.stats.diagnostic_context,
                    (; value, slope = nothing))
            end
            isfinite(value) || begin
                search.stats.rejected_trials += 1
                _arc1_observation!(search.stats, :line_search_rejection,
                    "objective callback returned a nonfinite value"; outcome = :rejected)
                throw(_Arc1DomainTrial(Float64(a), "objective callback returned a nonfinite value", :domain))
            end
            return value
        end
        function phidphi_guard(a)
            request!(a)
            value, slope = phidphi_raw(a)
            if search.stats.observation_events !== nothing
                search.stats.diagnostic_context = merge(search.stats.diagnostic_context,
                    (; value, slope))
            end
            (isfinite(value) && isfinite(slope)) || begin
                search.stats.rejected_trials += 1
                why = !isfinite(value) ? "joint value/gradient callback returned a nonfinite value" :
                      "directional slope is nonfinite"
                _arc1_observation!(search.stats, :line_search_rejection, why; outcome = :rejected)
                throw(_Arc1DomainTrial(Float64(a), why, :domain))
            end
            return value, slope
        end

        guess = min(original_guess, cap)
        hz = LS.HagerZhang(alphamax = cap)
        local result
        try
            result = hz(phi_guard, phidphi_guard, guess, phi0, dphi0)
        catch err
            if err isa _Arc1DomainTrial
                if err.kind == :budget
                    restore_origin(err.reason)
                end
                if restart >= search.max_domain_restarts
                    restore_origin("ARC1 finite-domain restart budget exhausted after: $(err.reason)")
                end
                newcap = min(cap, err.alpha / 2)
                if !(isfinite(newcap) && newcap > eps(Float64) && newcap < cap)
                    restore_origin("ARC1 cannot represent a smaller feasible step after: $(err.reason)")
                end
                search.stats.domain_restarts += 1
                cap = newcap
                continue
            elseif err isa LSE
                _arc1_observation!(search.stats, :hager_zhang_terminal,
                    "Hager-Zhang failed: $(err.message)"; outcome = :failed)
                restore_origin("Hager-Zhang failed: $(err.message)")
            else
                reset_origin()
                rethrow()
            end
        end

        step, _ = result
        (isfinite(step) && step > eps(Float64)) ||
            restore_origin("Hager-Zhang returned an unjustified zero or unrepresentable step")
        local value, slope
        try
            value, slope = phidphi_guard(step)
        catch err
            if err isa _Arc1DomainTrial
                if err.kind == :budget
                    restore_origin(err.reason)
                end
                if restart >= search.max_domain_restarts
                    restore_origin("ARC1 finite-domain restart budget exhausted after: $(err.reason)")
                end
                newcap = min(cap, err.alpha / 2)
                if !(isfinite(newcap) && newcap > eps(Float64) && newcap < cap)
                    restore_origin("ARC1 cannot represent a smaller feasible step after: $(err.reason)")
                end
                search.stats.domain_restarts += 1
                cap = newcap
                continue
            end
            reset_origin()
            rethrow()
        end
        phi_lim = phi0 + 1e-6 * abs(phi0)
        wolfe = 0.1 * dphi0 >= (value - phi0) / step && slope >= 0.9 * dphi0
        approximate_wolfe = (2 * 0.1 - 1) * dphi0 >= slope >= 0.9 * dphi0 && value <= phi_lim
        _arc1_line_search_wolfe_check!(search, original_x, original_direction,
            original_guess, guess, cap, restart, step, phi0, dphi0, value, slope,
            wolfe, approximate_wolfe)
        (wolfe || approximate_wolfe) ||
            restore_origin("Hager-Zhang returned a finite step that satisfies neither Wolfe condition")
        if search.stats.observation_events !== nothing
            _arc1_observation!(search.stats, :hager_zhang_terminal,
                "Hager-Zhang returned a step satisfying an independently checked Wolfe condition";
                coordinates = original_x .+ step .* original_direction,
                direction = original_direction, step, value, slope, outcome = :accepted)
        end
        copyto!(xnew, original_x .+ step .* original_direction)
        return step, value
    end
    restore_origin("ARC1 finite-domain restart budget exhausted")
end

struct _Arc1FASpectralContext
    n::Int
    p::Int
    df::Int
    Y::Matrix{Float64}
    X::Matrix{Float64}
    B::Matrix{Float64}
    eigenvalues::Vector{Float64}
    design_blocks::Vector{Matrix{Float64}}
    response_blocks::Vector{Vector{Float64}}
end

function _arc1_fa_invalid(reason, nparams)
    return (; status = :invalid_proposal, reason,
            objective = Inf, raw_objective = Inf, loglik = -Inf,
            gradient = zeros(Float64, nparams), fixed_effects = nothing)
end

const ARC1_V1_FIXED_EFFECT_EPS_COND_MAX = 1e-10

function _arc1_v1_fixed_effect_condition_screen(C::AbstractMatrix{<:Real})
    size(C, 1) == size(C, 2) && !isempty(C) ||
        return (; status = :invalid_proposal, reason = "fixed-effect information has invalid dimensions", eps_condition = Inf)
    all(isfinite, C) ||
        return (; status = :invalid_proposal, reason = "fixed-effect information is nonfinite", eps_condition = Inf)
    diagonal = diag(C)
    all(diagonal .> 0) ||
        return (; status = :invalid_proposal, reason = "fixed-effect information has a nonpositive diagonal", eps_condition = Inf)

    local eps_condition
    try
        scale = Diagonal(1.0 ./ sqrt.(diagonal))
        normalized = Matrix(Symmetric(scale * Matrix(Symmetric(C)) * scale))
        all(isfinite, normalized) ||
            return (; status = :invalid_proposal, reason = "scaled fixed-effect information is nonfinite", eps_condition = Inf)
        eps_condition = eps(Float64) * cond(normalized)
    catch err
        err isa InterruptException && rethrow()
        return (; status = :invalid_proposal,
            reason = "fixed-effect condition estimate failed: $(sprint(showerror, err))",
            eps_condition = Inf)
    end
    isfinite(eps_condition) && eps_condition <= ARC1_V1_FIXED_EFFECT_EPS_COND_MAX ||
        return (; status = :invalid_proposal,
            reason = "fixed-effect information exceeds empirical numerical condition screen",
            eps_condition)
    return (; status = :ok, reason = nothing, eps_condition)
end

function _arc1_fa_v1_block_factor(Rfactor, Gfactor, d::Real)
    failed(reason) = (; status = :failed, reason, factor = nothing,
        inverse = nothing, logdet = NaN)
    size(Rfactor) == (4, 4) && size(Gfactor, 1) == 4 ||
        return failed("spectral factor dimensions are invalid")
    isfinite(d) && d >= 0 || return failed("spectral eigenvalue is nonfinite or negative")
    all(isfinite, Rfactor) && all(isfinite, Gfactor) ||
        return failed("spectral factors are nonfinite")
    all(diag(Rfactor) .> 0) || return failed("residual factor is underflowed or singular")

    local L
    if d == 0
        # Preserve exact zero-eigenvalue behavior: the block is exactly R and
        # does not acquire a rounded or thresholded contribution from G.
        L = Matrix{Float64}(Rfactor)
    else
        scale = sqrt(Float64(d))
        scaled_G = scale .* Matrix{Float64}(Gfactor)
        any((Gfactor .!= 0) .& (scaled_G .== 0)) &&
            return failed("genetic factor contribution underflowed")
        A = hcat(Matrix{Float64}(Rfactor), scaled_G)
        all(isfinite, A) || return failed("spectral factor matrix is nonfinite")
        local upper
        try
            upper = Matrix(qr(transpose(A)).R)
        catch err
            err isa InterruptException && rethrow()
            return failed("spectral QR factorization failed: $(sprint(showerror, err))")
        end
        size(upper) == (4, 4) && all(isfinite, upper) ||
            return failed("spectral QR factor is nonfinite or malformed")
        diagonal = diag(upper)
        all(isfinite, diagonal) && all(diagonal .!= 0) ||
            return failed("spectral QR factor is singular or underflowed")
        signs = ifelse.(diagonal .> 0, 1.0, -1.0)
        upper = Diagonal(signs) * upper
        L = Matrix(transpose(upper))
    end

    all(isfinite, L) && all(diag(L) .> 0) ||
        return failed("spectral lower factor is nonfinite or underflowed")
    local inverse, logdet_block
    try
        I4 = Matrix{Float64}(I, 4, 4)
        lower_solve = LowerTriangular(L) \ I4
        inverse = UpperTriangular(transpose(L)) \ lower_solve
        logdet_block = 2sum(log, diag(L))
    catch err
        err isa InterruptException && rethrow()
        return failed("spectral factor solve failed: $(sprint(showerror, err))")
    end
    all(isfinite, inverse) && isfinite(logdet_block) ||
        return failed("spectral factor solve or log determinant is nonfinite")
    return (; status = :ok, reason = nothing, factor = L, inverse, logdet = logdet_block)
end

function _arc1_fa_spectral_context(Y, X, B)
    n, t = size(Y)
    t == 4 || return (; status = :invalid_input, reason = "ARC1 requires exactly four traits", context = nothing)
    size(B) == (n, n) || return (; status = :invalid_input, reason = "B must be n×n", context = nothing)
    size(X, 1) == n || return (; status = :invalid_input, reason = "X must have n rows", context = nothing)
    p = size(X, 2)
    df = 4n - 4p
    df > 0 || return (; status = :invalid_input, reason = "REML requires positive residual degrees of freedom", context = nothing)
    all(isfinite, Y) && all(isfinite, X) && all(isfinite, B) ||
        return (; status = :invalid_input, reason = "Y, X, and B must be finite", context = nothing)
    isapprox(B, transpose(B); atol = 1e-12, rtol = 1e-12) ||
        return (; status = :invalid_input, reason = "B must be symmetric", context = nothing)
    local E
    try
        BM = Matrix{Float64}(B)
        E = eigen(Symmetric((BM + transpose(BM)) / 2))
    catch err
        err isa InterruptException && rethrow()
        err isa LinearAlgebra.LAPACKException &&
            return (; status = :invalid_input, reason = "B eigendecomposition failed", context = nothing)
        rethrow()
    end
    vals = Vector{Float64}(E.values)
    all(isfinite, vals) || return (; status = :invalid_input, reason = "B eigenvalues must be finite", context = nothing)
    # Permit only eigensolver-scale negative roundoff (64 ε × scale × n).
    # Set that roundoff to zero; reject a materially negative eigenvalue.
    scale = max(1.0, maximum(abs, vals))
    roundoff = 64 * eps(Float64) * scale * max(n, 1)
    minimum(vals) < -roundoff &&
        return (; status = :invalid_input, reason = "B is not positive semidefinite", context = nothing)
    vals .= max.(vals, 0.0)
    return _arc1_fa_context_from_eigen(Y, X, vals, Matrix{Float64}(E.vectors); B = Matrix{Float64}(B))
end

function _arc1_fa_context_from_eigen(Y, X, eigenvalues, U; B = U * Diagonal(eigenvalues) * transpose(U))
    n, t = size(Y)
    p = size(X, 2)
    t == 4 || return (; status = :invalid_input, reason = "ARC1 requires exactly four traits", context = nothing)
    size(X, 1) == n && length(eigenvalues) == n && size(U) == (n, n) ||
        return (; status = :invalid_input, reason = "incompatible spectral context dimensions", context = nothing)
    df = 4n - 4p
    df > 0 || return (; status = :invalid_input, reason = "REML requires positive residual degrees of freedom", context = nothing)
    all(isfinite, Y) && all(isfinite, X) && all(isfinite, eigenvalues) && all(isfinite, U) ||
        return (; status = :invalid_input, reason = "spectral context inputs must be finite", context = nothing)
    minimum(eigenvalues) >= 0 ||
        return (; status = :invalid_input, reason = "B eigenvalues must be nonnegative", context = nothing)
    isapprox(transpose(U) * U, I; atol = 1e-10, rtol = 1e-10) ||
        return (; status = :invalid_input, reason = "spectral rotation must be orthonormal", context = nothing)

    # In record-major order, rotation by U'⊗I₄ gives independent blocks
    # Vᵢ = dᵢG + R and fixed-effect blocks Dᵢ = (U'X)ᵢ⊗I₄. U'1 need not
    # be an eigenvector or have only one nonzero entry.
    Yrot = transpose(U) * Matrix{Float64}(Y)
    Xrot = transpose(U) * Matrix{Float64}(X)
    I4 = Matrix{Float64}(I, 4, 4)
    Ds = [kron(reshape(Vector{Float64}(Xrot[i, :]), 1, p), I4) for i in 1:n]
    zs = [Vector{Float64}(@view Yrot[i, :]) for i in 1:n]
    ctx = _Arc1FASpectralContext(n, p, df, Matrix{Float64}(Y), Matrix{Float64}(X),
        Matrix{Float64}(B),
        Vector{Float64}(eigenvalues), Ds, zs)
    return (; status = :ok, reason = nothing, context = ctx)
end

function _arc1_fa_exact_objective_gradient(params, Y, X, B, k)
    k in (0, 1) || return _arc1_fa_invalid("rank must be 0 or 1", length(params))
    expected = k == 0 ? 14 : 18
    length(params) == expected || return _arc1_fa_invalid("wrong parameter-vector length", length(params))
    built = _arc1_fa_spectral_context(Y, X, B)
    built.status == :ok || return _arc1_fa_invalid(built.reason, expected)
    return _arc1_fa_exact_objective_gradient(built.context, params, k)
end

function _arc1_fa_exact_from_eigen(params, Y, X, eigenvalues, U, k)
    k in (0, 1) || return _arc1_fa_invalid("rank must be 0 or 1", length(params))
    expected = k == 0 ? 14 : 18
    length(params) == expected || return _arc1_fa_invalid("wrong parameter-vector length", length(params))
    built = _arc1_fa_context_from_eigen(Y, X, eigenvalues, U)
    built.status == :ok || return _arc1_fa_invalid(built.reason, expected)
    return _arc1_fa_exact_objective_gradient(built.context, params, k)
end

function _arc1_fa_exact_objective_gradient(ctx::_Arc1FASpectralContext, params, k)
    q = length(params)
    k in (0, 1) || return _arc1_fa_invalid("rank must be 0 or 1", q)
    expected = k == 0 ? 14 : 18
    q == expected || return _arc1_fa_invalid("wrong parameter-vector length", q)
    all(isfinite, params) || return _arc1_fa_invalid("parameters must be finite", q)

    ng = k == 0 ? 4 : 8
    local G, R, ψ, λ, η, chol
    try
        if k == 0
            η = @view params[1:4]
            ψ = _fa_uniqueness_from_unconstrained(η)
            λ = nothing
            G = Matrix(Diagonal(ψ))
            chol = @view params[5:14]
        else
            λ = Vector{Float64}(@view params[1:4])
            η = @view params[5:8]
            ψ = _fa_uniqueness_from_unconstrained(η)
            G = λ * transpose(λ) + Diagonal(ψ)
            chol = @view params[9:18]
        end
        R = _chol_params_to_cov(chol, 4)
    catch err
        err isa InterruptException && rethrow()
        (err isa ArgumentError || err isa DomainError || err isa OverflowError) &&
            return _arc1_fa_invalid("covariance parameter transform failed", q)
        rethrow()
    end
    (all(isfinite, G) && all(isfinite, R) && all(isfinite, ψ)) ||
        return _arc1_fa_invalid("G and R must be finite covariances", q)
    minimum(ψ .- FA_UNIQUENESS_FLOOR) > 0 ||
        return _arc1_fa_invalid("uniqueness must exceed its interior floor", q)
    isposdef(Symmetric(G)) ||
        return _arc1_fa_invalid("genetic covariance is not positive definite in Float64", q)

    # Reconstruct the supplied residual Cholesky factor directly. Re-factoring
    # its rounded Gram matrix can lose positive definiteness near the strict
    # uniqueness floor, even though the parameterized factor remains valid.
    L = zeros(Float64, 4, 4)
    idx = ng
    for j in 1:4, i in j:4
        idx += 1
        L[i, j] = i == j ? exp(params[idx]) : params[idx]
    end
    all(isfinite, L) && all(diag(L) .> 0) ||
        return _arc1_fa_invalid("residual Cholesky factor is nonfinite or underflowed", q)
    Gfactor = k == 0 ? Matrix(Diagonal(sqrt.(ψ))) :
        hcat(Matrix(Diagonal(sqrt.(ψ))), reshape(λ, 4, 1))
    all(isfinite, Gfactor) || return _arc1_fa_invalid("genetic factor is nonfinite", q)

    Ws = Matrix{Float64}[]
    logdetV = 0.0
    for i in 1:ctx.n
        block = _arc1_fa_v1_block_factor(L, Gfactor, ctx.eigenvalues[i])
        block.status == :ok || return _arc1_fa_invalid(block.reason, q)
        push!(Ws, block.inverse)
        logdetV += block.logdet
    end

    nc = 4 * ctx.p
    C = zeros(Float64, nc, nc)
    b = zeros(Float64, nc)
    for i in 1:ctx.n
        D, z, W = ctx.design_blocks[i], ctx.response_blocks[i], Ws[i]
        C .+= transpose(D) * W * D
        b .+= transpose(D) * W * z
    end
    all(isfinite, C) && all(isfinite, b) ||
        return _arc1_fa_invalid("fixed-effect information is nonfinite", q)
    local FC
    try
        FC = cholesky(Symmetric(C); check = true)
    catch err
        err isa InterruptException && rethrow()
        err isa PosDefException && return _arc1_fa_invalid("fixed-effect information is not positive definite", q)
        rethrow()
    end
    condition_screen = _arc1_v1_fixed_effect_condition_screen(C)
    condition_screen.status == :ok || return _arc1_fa_invalid(condition_screen.reason, q)
    local β, Cinv
    try
        β = FC \ b
        Cinv = FC \ Matrix{Float64}(I, nc, nc)
    catch err
        err isa InterruptException && rethrow()
        return _arc1_fa_invalid("fixed-effect information solve failed: $(sprint(showerror, err))", q)
    end
    all(isfinite, β) && all(isfinite, Cinv) ||
        return _arc1_fa_invalid("fixed-effect information solve is nonfinite", q)
    raw = 0.5 * (ctx.df * log(2π) + logdetV + logdet(FC))
    SG = zeros(Float64, 4, 4)
    SR = zeros(Float64, 4, 4)
    for i in 1:ctx.n
        D, z, W = ctx.design_blocks[i], ctx.response_blocks[i], Ws[i]
        e = z - D * β
        raw += 0.5 * dot(e, W * e)
        WD = W * D
        H = W - WD * Cinv * transpose(WD)
        a = W * e
        Ti = (H - a * transpose(a)) / (2 * ctx.df)
        SG .+= ctx.eigenvalues[i] .* Ti
        SR .+= Ti
    end
    isfinite(raw) || return _arc1_fa_invalid("REML objective is nonfinite", q)
    objective = raw / ctx.df
    isfinite(objective) || return _arc1_fa_invalid("scaled REML objective is nonfinite", q)
    SG .= (SG .+ transpose(SG)) ./ 2
    SR .= (SR .+ transpose(SR)) ./ 2

    grad = zeros(Float64, q)
    if k == 0
        grad[1:4] .= exp.(η) .* diag(SG)
    else
        # Keep the supplied raw loading signs in the derivative.
        grad[1:4] .= 2 .* (SG * λ)
        grad[5:8] .= exp.(η) .* diag(SG)
    end

    # Cholesky parameters use column-major lower-triangle order:
    # 11,21,31,41,22,32,42,33,43,44.
    GL = 2 .* (SR * L)
    idx = ng
    for j in 1:4, i in j:4
        idx += 1
        grad[idx] = i == j ? GL[i, j] * L[j, j] : GL[i, j]
    end
    all(isfinite, grad) || return _arc1_fa_invalid("REML gradient is nonfinite", q)
    return (; status = :ok, reason = nothing,
            objective, raw_objective = raw, loglik = -raw,
            gradient = grad,
            fixed_effects = permutedims(reshape(β, 4, ctx.p)))
end

_arc1_fa_policy_objective_gradient(ctx, params, k, policy) =
    policy == "arc1_v2" ? _arc1_fa_v2_exact_objective_gradient(ctx, params, k) :
                           _arc1_fa_exact_objective_gradient(ctx, params, k)

function _arc1_fa_central_difference_failed_sides(parameter, relative_scale,
                                                  absolute_step, plus, minus)
    failures = Any[]
    plus.status == :ok || push!(failures, (; side = :plus, parameter,
        relative_scale, absolute_step, objective_status = plus.status,
        objective_reason = plus.reason))
    minus.status == :ok || push!(failures, (; side = :minus, parameter,
        relative_scale, absolute_step, objective_status = minus.status,
        objective_reason = minus.reason))
    failures
end

function _arc1_fa_assess_optimizer_result(raw_result, ctx::_Arc1FASpectralContext, k;
                                          final_gradient_tol = 1e-6,
                                          evaluation_callback = nothing,
                                          optimizer_policy = "arc1_v1")
    phat = try
        Float64.(collect(raw_result.phat))
    catch err
        err isa InterruptException && rethrow()
        Float64[]
    end
    optimizer_converged = try Bool(raw_result.optimizer_converged) catch; false end
    line_search_success = try Bool(raw_result.line_search_success) catch; false end
    iterations = try Int(raw_result.iterations) catch; 0 end
    optimizer_status = try string(raw_result.optimizer_status) catch; "unknown" end
    final = _arc1_fa_policy_objective_gradient(ctx, phat, k, optimizer_policy)
    evaluation_callback === nothing || evaluation_callback(copy(phat), final)
    final_norm = final.status == :ok ? norm(final.gradient, Inf) : Inf
    # Independent central differences of the cached objective provide a
    # numerical check of the analytic gradient at two step sizes. This is
    # cheap relative to fitting because each evaluation only visits n 4×4
    # blocks. A parameter is never omitted from either sweep.
    fd = final.status == :ok ? _arc1_fa_central_gradient_sweep(ctx, phat, k;
         evaluation_callback, optimizer_policy) :
         (; status = :not_evaluated, reason = final.reason,
            gradients = (Float64[], Float64[]), norms = (Inf, Inf),
            discrepancies = (Inf, Inf), steps = (1e-4, 1e-5), failed_sides = Any[])
    numerical_ok = fd.status == :ok &&
                   maximum(fd.norms) <= 5e-6 && maximum(fd.discrepancies) <= 5e-6
    certificate = optimizer_policy == "arc1_v2" && final.status == :ok ?
        _arc1_fa_v2_certify(ctx.Y, ctx.X, ctx.B, phat, k, final.loglik) : nothing
    certificate_ok = certificate === nothing || certificate.status == :ok
    accepted = final.status == :ok && isfinite(final.objective) &&
               optimizer_converged && line_search_success && isfinite(final_norm) && final_norm <= final_gradient_tol &&
               numerical_ok && certificate_ok
    status = accepted ? :converged : final.status != :ok ? :failed :
             !line_search_success ? :line_search_failed :
             fd.status != :ok || !numerical_ok || !certificate_ok ? :numerical_gradient_failure : :not_converged
    reason = accepted ? nothing : final.status != :ok ? final.reason :
             !line_search_success ? something(get(raw_result, :line_search_terminal_reason, nothing),
                 "Hager-Zhang line search failed") :
             fd.status != :ok ? fd.reason : !numerical_ok ? "central-difference gradient check failed" :
             !certificate_ok ? certificate.reason :
             !optimizer_converged ? "optimizer did not converge" :
             "final scaled-gradient infinity norm exceeds $(final_gradient_tol)"
    assessment_status = accepted ? :accepted : final.status != :ok ? :objective_or_gradient_failure :
        !line_search_success ? :line_search_failure :
        fd.status != :ok || !numerical_ok || !certificate_ok ? :numerical_gradient_failure :
        !optimizer_converged ? :optimizer_unconverged : :final_gradient_failure
    result = (; status, reason, accepted, phat,
            objective = final.status == :ok ? final.objective : Inf,
            raw_objective = final.status == :ok ? final.raw_objective : Inf,
            loglik = final.status == :ok ? final.loglik : -Inf,
            optimizer_converged, line_search_success, iterations, optimizer_status,
            optimizer_assessment_status = assessment_status,
            optimizer_assessment_reason = reason,
            line_search_terminal_reason = get(raw_result, :line_search_terminal_reason, nothing),
            final_status = final.status,
            final_gradient_inf_norm = final_norm,
            final_gradient_tol,
            numerical_gradient_status = fd.status,
            numerical_gradient_steps = fd.steps,
            numerical_gradient_inf_norms = fd.norms,
            numerical_gradient_discrepancies = fd.discrepancies,
            numerical_gradient_failed_sides = fd.failed_sides,
            numerical_gradient_tolerance = 5e-6,
            fixed_effects = final.status == :ok ? final.fixed_effects : nothing)
    optimizer_policy == "arc1_v2" || return result
    return merge(result, (; optimizer_policy, optimizer_policy_version = 2,
        covariance_representation = _ARC1_FA_V2_REPRESENTATION,
        independent_loglik = certificate === nothing ? nothing : certificate.independent_loglik,
        independent_likelihood_discrepancy = certificate === nothing ? nothing : certificate.discrepancy,
        factor_state = final.status == :ok ? final.factor_state : nothing,
        factor_valid = final.status == :ok && final.factor_state.factor_valid,
        pd_genetic = final.status == :ok && final.factor_state.pd_genetic,
        pd_residual = final.status == :ok && final.factor_state.pd_residual))
end

function _arc1_fa_central_gradient_sweep(ctx::_Arc1FASpectralContext, params, k;
                                         evaluation_callback = nothing,
                                         optimizer_policy = "arc1_v1",
                                         objective_evaluator = nothing)
    p0 = Float64.(params)
    evaluate = objective_evaluator === nothing ?
        (parameters -> _arc1_fa_policy_objective_gradient(ctx, parameters, k, optimizer_policy)) :
        (parameters -> objective_evaluator(ctx, parameters, k, optimizer_policy))
    base = evaluate(p0)
    evaluation_callback === nothing || evaluation_callback(copy(p0), base)
    base.status == :ok || return (; status = :failed, reason = base.reason,
        gradients = (Float64[], Float64[]), norms = (Inf, Inf),
        discrepancies = (Inf, Inf), steps = (1e-4, 1e-5), failed_sides = Any[])
    steps = (1e-4, 1e-5)
    gradients = Vector{Float64}[]
    norms = Float64[]
    discrepancies = Float64[]
    for scale in steps
        fd = similar(p0)
        for j in eachindex(p0)
            h = scale * max(1.0, abs(p0[j]))
            plus, minus = copy(p0), copy(p0)
            plus[j] += h
            minus[j] -= h
            fp = evaluate(plus)
            evaluation_callback === nothing || evaluation_callback(copy(plus), fp)
            fm = evaluate(minus)
            evaluation_callback === nothing || evaluation_callback(copy(minus), fm)
            if fp.status != :ok || fm.status != :ok
                failed_sides = _arc1_fa_central_difference_failed_sides(j, scale, h, fp, fm)
                return (; status = :failed,
                    reason = "central difference failed at parameter $(j) and step $(scale)",
                    gradients = (Float64[], Float64[]), norms = (Inf, Inf),
                    discrepancies = (Inf, Inf), steps, failed_sides)
            end
            fd[j] = (fp.objective - fm.objective) / (2h)
        end
        push!(gradients, fd)
        push!(norms, norm(fd, Inf))
        push!(discrepancies, norm(fd - base.gradient, Inf))
    end
    return (; status = :ok, reason = nothing,
            gradients = (gradients[1], gradients[2]),
            norms = (norms[1], norms[2]),
            discrepancies = (discrepancies[1], discrepancies[2]), steps,
            failed_sides = Any[])
end

function _arc1_bfgs_inverse_update(H::AbstractMatrix, s::AbstractVector, y::AbstractVector)
    sy = dot(s, y)
    sy > 0 || return Matrix(H)
    u = H * y
    c1 = (sy + dot(y, u)) / (sy * sy)
    c2 = inv(sy)
    return H + c1 .* (s * transpose(s)) .- c2 .* (u * transpose(s) .+ s * transpose(u))
end

function _arc1_bfgs_trace_events(trace)
    events = NamedTuple[]
    previous = nothing
    for (index, state) in pairs(trace)
        metadata = state.metadata
        all(key -> haskey(metadata, key), ("x", "g(x)", "~inv(H)", "Current step size")) ||
            throw(ArgumentError("extended BFGS trace is missing optimizer state metadata"))
        x = vec(Float64.(copy(metadata["x"])))
        gradient = vec(Float64.(copy(metadata["g(x)"])))
        inverse_hessian = Matrix{Float64}(copy(metadata["~inv(H)"]))
        length(x) == length(gradient) == size(inverse_hessian, 1) == size(inverse_hessian, 2) ||
            throw(ArgumentError("extended BFGS trace state dimensions disagree"))
        all(isfinite, x) && all(isfinite, gradient) && all(isfinite, inverse_hessian) ||
            throw(ArgumentError("extended BFGS trace contains nonfinite optimizer state"))
        if previous === nothing
            push!(events, (; iteration = 0, accepted = false, coordinates = x, gradient,
                inverse_hessian, step = nothing, displacement = nothing,
                search_direction = nothing, x_displacement = nothing,
                gradient_change = nothing, curvature = nothing, reset_before_search = nothing,
                update = :initial_state, reconstruction = :not_applicable))
        else
            step = Float64(metadata["Current step size"])
            isfinite(step) && step > 0 ||
                throw(ArgumentError("extended BFGS trace has an invalid accepted step"))
            x_displacement = x .- previous.coordinates
            gradient_change = gradient .- previous.gradient
            direction_slope = -dot(previous.gradient, previous.inverse_hessian * previous.gradient)
            reset_before_search = direction_slope >= 0
            base_hessian = reset_before_search ? Matrix{Float64}(I, length(x), length(x)) :
                previous.inverse_hessian
            search_direction = reset_before_search ? -previous.gradient :
                -(previous.inverse_hessian * previous.gradient)
            # Optim's BFGSState.dx is computed as alpha .* direction before
            # x is rounded by addition. That is the vector used by update_h!.
            displacement = step .* search_direction
            curvature = dot(displacement, gradient_change)
            update = curvature > 0 ? :updated : :skipped_nonpositive_curvature
            expected = curvature > 0 ?
                _arc1_bfgs_inverse_update(base_hessian, displacement, gradient_change) : base_hessian
            scale = max(1.0, norm(expected, Inf), norm(inverse_hessian, Inf))
            matches = norm(expected - inverse_hessian, Inf) <= 256eps(Float64) * scale
            push!(events, (; iteration = index - 1, accepted = true, coordinates = x, gradient,
                inverse_hessian, step, search_direction, displacement, x_displacement,
                gradient_change, curvature, reset_before_search, update,
                reconstruction = matches ? :matches_optim_bfgs_state : :mismatch))
        end
        previous = (; coordinates = x, gradient, inverse_hessian)
    end
    return events
end

function _arc1_fa_bfgs(ctx::_Arc1FASpectralContext, params0, k;
                       iterations = 2_000, optimizer_tol = 1e-8,
                       final_gradient_tol = 1e-6, evaluation_callback = nothing,
                       observation_events = nothing, optimizer_state_events = nothing,
                       optimizer_policy = "arc1_v1", optimizer_runner = nothing,
                       identity_search_runner = nothing, objective_evaluator = nothing,
                       line_search_factory = nothing)
    iterations isa Integer && iterations > 0 || throw(ArgumentError("iterations must be positive"))
    optimizer_tol > 0 || throw(ArgumentError("optimizer tolerance must be positive"))
    observation_events === nothing || observation_events isa Vector{Any} ||
        throw(ArgumentError("observation_events must be nothing or Vector{Any}"))
    optimizer_state_events === nothing || optimizer_state_events isa Vector{Any} ||
        throw(ArgumentError("optimizer_state_events must be nothing or Vector{Any}"))
    line_search_stats = _Arc1LineSearchStats(; observation_events)
    objective_gradient = objective_evaluator === nothing ?
        (parameters -> _arc1_fa_policy_objective_gradient(ctx, parameters, k, optimizer_policy)) :
        (parameters -> objective_evaluator(ctx, parameters, k, optimizer_policy))
    initial = objective_gradient(params0)
    evaluation_callback === nothing || evaluation_callback(copy(Float64.(params0)), initial)
    if initial.status != :ok
        _arc1_observation!(line_search_stats, :evaluator_rejection, initial.reason;
            coordinates = Float64.(params0), value = initial.objective,
            outcome = initial.status)
    end
    initial.status == :ok || return merge(
        _arc1_fa_assess_optimizer_result((; phat = params0,
            optimizer_converged = false, iterations = 0,
            line_search_success = false,
            optimizer_status = "invalid_initial_proposal"), ctx, k;
            final_gradient_tol, evaluation_callback, optimizer_policy),
        (; algorithm = :bfgs_hager_zhang, status = :failed,
           accepted = false, final_status = initial.status, reason = initial.reason))

    last_x = copy(Float64.(params0))
    last_value = initial
    function evaluate(x)
        if !isequal(x, last_x)
            last_x .= x
            line_search_stats.objective_evaluations += 1
            last_value = objective_gradient(x)
            if last_value.status != :ok
                context = line_search_stats.diagnostic_context
                slope = context === nothing || !all(isfinite, last_value.gradient) ? nothing :
                    dot(last_value.gradient, context.direction)
                _arc1_observation!(line_search_stats, :evaluator_rejection,
                    last_value.reason; coordinates = Float64.(x),
                    value = last_value.objective, slope, outcome = last_value.status)
            end
            evaluation_callback === nothing || evaluation_callback(copy(Float64.(x)), last_value)
        end
        last_value
    end
    f = x -> begin
        out = evaluate(x)
        out.status == :ok ? out.objective : Inf
    end
    function g!(G, x)
        out = evaluate(x)
        G .= out.gradient
        return G
    end
    optimizer_run_index = 0
    function run_bfgs(start, budget)
        optimizer_run_index += 1
        options = Optim.Options(iterations = budget, g_abstol = optimizer_tol,
            x_abstol = 0.0, x_reltol = 0.0, f_abstol = 0.0, f_reltol = 0.0,
            allow_f_increases = false, store_trace = optimizer_state_events !== nothing,
            extended_trace = optimizer_state_events !== nothing)
        linesearch = line_search_factory === nothing ?
            _Arc1DomainHagerZhang(line_search_stats) :
            line_search_factory(line_search_stats, optimizer_run_index)
        runner_result = optimizer_runner === nothing ?
            optimize(f, g!, copy(start), Optim.BFGS(; linesearch), options) :
            optimizer_runner(f, g!, copy(start), budget, line_search_stats)
        if optimizer_runner !== nothing
            return runner_result
        end
        stop = runner_result.stopped_by
        return (; minimizer = Optim.minimizer(runner_result),
            converged = Optim.converged(runner_result),
            line_search_success = !(hasproperty(stop, :ls_failed) && stop.ls_failed),
            iterations = Optim.iterations(runner_result),
            status = sprint(show, Optim.summary(runner_result)),
            terminal_reason = line_search_stats.terminal_reason,
            trace = optimizer_state_events === nothing ? nothing : Optim.trace(runner_result))
    end
    first_run = run_bfgs(Float64.(params0), iterations)
    runs = Any[(; stage = :original, iterations = first_run.iterations,
        line_search_success = first_run.line_search_success,
        terminal_reason = first_run.terminal_reason, status = first_run.status)]
    accepted_iterations = Int(first_run.iterations)
    final_run = first_run
    recovery = (; attempted = false, original_terminal_reason = first_run.terminal_reason,
        identity = nothing, continuation = nothing)

    if !first_run.line_search_success && first_run.terminal_reason !== nothing &&
       first_run.iterations < iterations
        # Optim's failed line search leaves its minimizer at the last accepted
        # point. Re-evaluate that point before making the one permitted
        # identity-metric search; never use the rejected trial as its origin.
        origin = Float64.(first_run.minimizer)
        origin_value = evaluate(origin)
        if origin_value.status == :ok
            requested_initial_step = line_search_stats.diagnostic_context !== nothing &&
                hasproperty(line_search_stats.diagnostic_context, :requested_initial_step) ?
                line_search_stats.diagnostic_context.requested_initial_step : 1.0
            NLS = Optim.NLSolversBase
            df = NLS.OnceDifferentiable(f, g!, origin)
            phi0, gradient0_buffer = NLS.value_gradient!(df, origin)
            origin_gradient = copy(gradient0_buffer)
            endpoint = copy(origin)
            identity_result = try
                line_search_value = identity_search_runner === nothing ?
                    _Arc1DomainHagerZhang(line_search_stats)(df, origin,
                        -origin_gradient, requested_initial_step, endpoint, phi0,
                        -dot(origin_gradient, origin_gradient)) :
                    identity_search_runner(df, origin, -origin_gradient,
                        requested_initial_step, endpoint, phi0,
                        -dot(origin_gradient, origin_gradient), line_search_stats)
                (; accepted = true, endpoint = copy(endpoint), reason = nothing,
                   step = Float64(first(line_search_value)),
                   origin_gradient)
            catch err
                err isa InterruptException && rethrow()
                err isa Optim.LineSearches.LineSearchException || rethrow()
                (; accepted = false, endpoint = copy(origin), reason =
                    line_search_stats.terminal_reason === nothing ? sprint(showerror, err) :
                    line_search_stats.terminal_reason, step = nothing,
                    origin_gradient)
            end
            identity_endpoint_value = identity_result.accepted ? evaluate(identity_result.endpoint) : nothing
            identity_ok = identity_result.accepted && identity_endpoint_value.status == :ok &&
                all(isfinite, identity_endpoint_value.gradient)
            identity_ok || evaluate(origin)
            identity_record = (; accepted = identity_ok, origin = copy(origin),
                endpoint = copy(identity_ok ? identity_result.endpoint : origin),
                requested_initial_step = Float64(requested_initial_step),
                step = identity_result.step, reason = identity_ok ? nothing :
                    (identity_result.reason === nothing ? identity_endpoint_value.reason : identity_result.reason),
                iterations = identity_ok ? 1 : 0,
                origin_gradient = copy(identity_result.origin_gradient),
                endpoint_gradient = identity_ok ? copy(identity_endpoint_value.gradient) : nothing)
            if identity_ok && first_run.iterations + 1 < iterations
                accepted_iterations += 1
                remaining = iterations - accepted_iterations
                # Keep the original refusal in `recovery`, but make the
                # continuation's terminal field describe only its own run.
                line_search_stats.terminal_reason = nothing
                continuation = run_bfgs(identity_result.endpoint, remaining)
                accepted_iterations += Int(continuation.iterations)
                final_run = continuation
                push!(runs, (; stage = :identity_metric_step, iterations = 1,
                    line_search_success = true, terminal_reason = nothing,
                    status = "accepted strict Wolfe identity-metric step"))
                push!(runs, (; stage = :continuation, iterations = continuation.iterations,
                    line_search_success = continuation.line_search_success,
                    terminal_reason = continuation.terminal_reason, status = continuation.status,
                    iteration_budget = remaining))
                recovery = (; attempted = true,
                    original_terminal_reason = first_run.terminal_reason,
                    identity = identity_record,
                    continuation = (; iterations = continuation.iterations,
                        iteration_budget = remaining, status = continuation.status,
                        line_search_success = continuation.line_search_success,
                        terminal_reason = continuation.terminal_reason))
            else
                # A refused fallback restores its origin. A successful step
                # with no budget left is retained as a nonconverged endpoint.
                budget_exhausted = identity_ok
                budget_reason = budget_exhausted ?
                    "identity step accepted; no iteration budget remains for BFGS continuation" :
                    identity_record.reason
                final_run = (; minimizer = identity_ok ? identity_result.endpoint : origin,
                    converged = false, line_search_success = identity_ok,
                    iterations = first_run.iterations + identity_record.iterations,
                    status = budget_exhausted ? "identity step accepted; continuation budget exhausted" :
                        "identity-metric fallback refused",
                    terminal_reason = budget_reason,
                    trace = nothing)
                accepted_iterations = final_run.iterations
                push!(runs, (; stage = :identity_metric_step,
                    iterations = identity_record.iterations,
                    line_search_success = identity_ok, terminal_reason = budget_reason,
                    status = final_run.status))
                recovery = (; attempted = true,
                    original_terminal_reason = first_run.terminal_reason,
                    identity = identity_record, continuation = nothing)
            end
        else
            recovery = (; attempted = true,
                original_terminal_reason = first_run.terminal_reason,
                identity = (; accepted = false, origin = copy(origin), endpoint = copy(origin),
                    requested_initial_step = 1.0, step = nothing,
                    reason = origin_value.reason, iterations = 0), continuation = nothing)
        end
    end

    if optimizer_state_events !== nothing
        first_run.trace === nothing || append!(optimizer_state_events,
            _arc1_bfgs_trace_events(first_run.trace))
        if recovery.identity !== nothing && recovery.identity.accepted
            push!(optimizer_state_events, (; iteration = first_run.iterations + 1,
                accepted = true, coordinates = copy(recovery.identity.endpoint),
                gradient = copy(recovery.identity.endpoint_gradient),
                inverse_hessian = Matrix{Float64}(I, length(recovery.identity.endpoint_gradient),
                    length(recovery.identity.endpoint_gradient)), step = recovery.identity.step,
                search_direction = -recovery.identity.origin_gradient,
                displacement = recovery.identity.step .* -recovery.identity.origin_gradient,
                x_displacement = recovery.identity.endpoint - recovery.identity.origin,
                gradient_change = recovery.identity.endpoint_gradient - recovery.identity.origin_gradient,
                curvature = NaN, reset_before_search = true,
                update = :identity_metric_restart, reconstruction = :not_applicable))
        end
        if recovery.continuation !== nothing && final_run.trace !== nothing
            offset = first_run.iterations + 1
            continuation_events = _arc1_bfgs_trace_events(final_run.trace)
            append!(optimizer_state_events, [merge(event, (; iteration = event.iteration + offset))
                for event in continuation_events])
        end
    end
    line_search_success = final_run.line_search_success
    raw = (; phat = final_run.minimizer,
           optimizer_converged = final_run.converged,
           line_search_success,
           iterations = accepted_iterations,
           optimizer_status = final_run.status,
           line_search_stats = (; callback_requests = line_search_stats.callback_requests,
               objective_evaluations = line_search_stats.objective_evaluations,
               rejected_trials = line_search_stats.rejected_trials,
               domain_restarts = line_search_stats.domain_restarts,
               optimizer_runs = runs),
           line_search_terminal_reason = final_run.terminal_reason)
    assessed = _arc1_fa_assess_optimizer_result(raw, ctx, k; final_gradient_tol,
        evaluation_callback, optimizer_policy)
    status = assessed.accepted ? :converged : !assessed.line_search_success ?
        :line_search_failed : assessed.status == :numerical_gradient_failure ?
        :numerical_gradient_failure : assessed.final_status == :ok ? :not_converged : :failed
    return merge(assessed, (; status, algorithm = :bfgs_hager_zhang,
        line_search_stats = raw.line_search_stats,
        line_search_recovery = recovery))
end
