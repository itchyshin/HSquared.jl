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
end
_Arc1LineSearchStats() = _Arc1LineSearchStats(0, 0, 0, 0)

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

function (search::_Arc1DomainHagerZhang)(df, x, direction, alpha, xnew, phi0, dphi0)
    LS = Optim.LineSearches
    LSE = LS.LineSearchException
    NLS = Optim.NLSolversBase
    original_x = copy(x)
    original_direction = copy(direction)
    original_guess = Float64(alpha)

    function reset_origin()
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
        reset_origin()
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
            callbacks_this_search < search.max_callback_requests || begin
                search.stats.rejected_trials += 1
                throw(_Arc1DomainTrial(Float64(a), "line-search callback budget exhausted", :budget))
            end
            isfinite(a) && a > 0 || begin
                search.stats.rejected_trials += 1
                throw(_Arc1DomainTrial(Float64(a), "line-search trial step is nonfinite or nonpositive", :invalid_step))
            end
            callbacks_this_search += 1
            search.stats.callback_requests += 1
            trial = original_x .+ a .* original_direction
            all(isfinite, trial) || begin
                search.stats.rejected_trials += 1
                throw(_Arc1DomainTrial(Float64(a), "line-search parameter vector is nonfinite", :invalid_step))
            end
            nothing
        end
        function phi_guard(a)
            request!(a)
            value = phi_raw(a)
            isfinite(value) || begin
                search.stats.rejected_trials += 1
                throw(_Arc1DomainTrial(Float64(a), "objective callback returned a nonfinite value", :domain))
            end
            return value
        end
        function phidphi_guard(a)
            request!(a)
            value, slope = phidphi_raw(a)
            (isfinite(value) && isfinite(slope)) || begin
                search.stats.rejected_trials += 1
                why = !isfinite(value) ? "joint value/gradient callback returned a nonfinite value" :
                      "directional slope is nonfinite"
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
        (wolfe || approximate_wolfe) ||
            restore_origin("Hager-Zhang returned a finite step that satisfies neither Wolfe condition")
        copyto!(xnew, original_x .+ step .* original_direction)
        return step, value
    end
    restore_origin("ARC1 finite-domain restart budget exhausted")
end

struct _Arc1FASpectralContext
    n::Int
    p::Int
    df::Int
    eigenvalues::Vector{Float64}
    design_blocks::Vector{Matrix{Float64}}
    response_blocks::Vector{Vector{Float64}}
end

function _arc1_fa_invalid(reason, nparams)
    return (; status = :invalid_proposal, reason,
            objective = Inf, raw_objective = Inf, loglik = -Inf,
            gradient = zeros(Float64, nparams), fixed_effects = nothing)
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
    return _arc1_fa_context_from_eigen(Y, X, vals, Matrix{Float64}(E.vectors))
end

function _arc1_fa_context_from_eigen(Y, X, eigenvalues, U)
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
    ctx = _Arc1FASpectralContext(n, p, df, Vector{Float64}(eigenvalues), Ds, zs)
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
    (all(isfinite, G) && all(isfinite, R) && all(isfinite, ψ) &&
     isposdef(Symmetric(G)) && isposdef(Symmetric(R))) ||
        return _arc1_fa_invalid("G and R must be finite positive-definite covariances", q)
    minimum(ψ .- FA_UNIQUENESS_FLOOR) > 0 ||
        return _arc1_fa_invalid("uniqueness must exceed its interior floor", q)

    Ws = Matrix{Float64}[]
    logdetV = 0.0
    I4 = Matrix{Float64}(I, 4, 4)
    try
        for i in 1:ctx.n
            Vi = ctx.eigenvalues[i] .* G + R
            FV = cholesky(Symmetric(Vi); check = true)
            push!(Ws, FV \ I4)
            logdetV += logdet(FV)
        end
    catch err
        err isa InterruptException && rethrow()
        err isa PosDefException && return _arc1_fa_invalid("a spectral covariance block is not positive definite", q)
        rethrow()
    end

    nc = 4 * ctx.p
    C = zeros(Float64, nc, nc)
    b = zeros(Float64, nc)
    for i in 1:ctx.n
        D, z, W = ctx.design_blocks[i], ctx.response_blocks[i], Ws[i]
        C .+= transpose(D) * W * D
        b .+= transpose(D) * W * z
    end
    local FC
    try
        FC = cholesky(Symmetric(C); check = true)
    catch err
        err isa InterruptException && rethrow()
        err isa PosDefException && return _arc1_fa_invalid("fixed-effect information is not positive definite", q)
        rethrow()
    end
    β = FC \ b
    Cinv = FC \ Matrix{Float64}(I, nc, nc)
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
    L = zeros(Float64, 4, 4)
    idx = ng
    for j in 1:4, i in j:4
        idx += 1
        L[i, j] = i == j ? exp(params[idx]) : params[idx]
    end
    GL = 2 .* (SR * L)
    idx = ng
    for j in 1:4, i in j:4
        idx += 1
        grad[idx] = i == j ? GL[i, j] * L[j, j] : GL[i, j]
    end
    all(isfinite, grad) || return _arc1_fa_invalid("REML gradient is nonfinite", q)
    return (; status = :ok, reason = nothing,
            objective = raw / ctx.df, raw_objective = raw, loglik = -raw,
            gradient = grad,
            fixed_effects = permutedims(reshape(β, 4, ctx.p)))
end

function _arc1_fa_assess_optimizer_result(raw_result, ctx::_Arc1FASpectralContext, k;
                                          final_gradient_tol = 1e-6,
                                          evaluation_callback = nothing)
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
    final = _arc1_fa_exact_objective_gradient(ctx, phat, k)
    evaluation_callback === nothing || evaluation_callback(copy(phat), final)
    final_norm = final.status == :ok ? norm(final.gradient, Inf) : Inf
    # Independent central differences of the cached objective provide a
    # numerical check of the analytic gradient at two step sizes. This is
    # cheap relative to fitting because each evaluation only visits n 4×4
    # blocks. A parameter is never omitted from either sweep.
    fd = final.status == :ok ? _arc1_fa_central_gradient_sweep(ctx, phat, k;
         evaluation_callback) :
         (; status = :not_evaluated, reason = final.reason,
            gradients = (Float64[], Float64[]), norms = (Inf, Inf),
            discrepancies = (Inf, Inf), steps = (1e-4, 1e-5))
    numerical_ok = fd.status == :ok &&
                   maximum(fd.norms) <= 5e-6 && maximum(fd.discrepancies) <= 5e-6
    accepted = final.status == :ok && isfinite(final.objective) &&
               optimizer_converged && line_search_success && isfinite(final_norm) && final_norm <= final_gradient_tol &&
               numerical_ok
    status = accepted ? :converged : final.status != :ok ? :failed :
             !line_search_success ? :line_search_failed :
             fd.status != :ok || !numerical_ok ? :numerical_gradient_failure : :not_converged
    reason = accepted ? nothing : final.status != :ok ? final.reason :
             !line_search_success ? "Hager-Zhang line search failed" :
             fd.status != :ok ? fd.reason : !numerical_ok ? "central-difference gradient check failed" :
             !optimizer_converged ? "optimizer did not converge" :
             "final scaled-gradient infinity norm exceeds $(final_gradient_tol)"
    assessment_status = accepted ? :accepted : final.status != :ok ? :objective_or_gradient_failure :
        !line_search_success ? :line_search_failure :
        fd.status != :ok || !numerical_ok ? :numerical_gradient_failure :
        !optimizer_converged ? :optimizer_unconverged : :final_gradient_failure
    return (; status, reason, accepted, phat,
            objective = final.status == :ok ? final.objective : Inf,
            raw_objective = final.status == :ok ? final.raw_objective : Inf,
            loglik = final.status == :ok ? final.loglik : -Inf,
            optimizer_converged, line_search_success, iterations, optimizer_status,
            optimizer_assessment_status = assessment_status,
            optimizer_assessment_reason = reason,
            final_status = final.status,
            final_gradient_inf_norm = final_norm,
            final_gradient_tol,
            numerical_gradient_status = fd.status,
            numerical_gradient_steps = fd.steps,
            numerical_gradient_inf_norms = fd.norms,
            numerical_gradient_discrepancies = fd.discrepancies,
            numerical_gradient_tolerance = 5e-6,
            fixed_effects = final.status == :ok ? final.fixed_effects : nothing)
end

function _arc1_fa_central_gradient_sweep(ctx::_Arc1FASpectralContext, params, k;
                                         evaluation_callback = nothing)
    p0 = Float64.(params)
    base = _arc1_fa_exact_objective_gradient(ctx, p0, k)
    evaluation_callback === nothing || evaluation_callback(copy(p0), base)
    base.status == :ok || return (; status = :failed, reason = base.reason,
        gradients = (Float64[], Float64[]), norms = (Inf, Inf),
        discrepancies = (Inf, Inf), steps = (1e-4, 1e-5))
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
            fp = _arc1_fa_exact_objective_gradient(ctx, plus, k)
            evaluation_callback === nothing || evaluation_callback(copy(plus), fp)
            fm = _arc1_fa_exact_objective_gradient(ctx, minus, k)
            evaluation_callback === nothing || evaluation_callback(copy(minus), fm)
            if fp.status != :ok || fm.status != :ok
                return (; status = :failed,
                    reason = "central difference failed at parameter $(j) and step $(scale)",
                    gradients = (Float64[], Float64[]), norms = (Inf, Inf),
                    discrepancies = (Inf, Inf), steps)
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
            discrepancies = (discrepancies[1], discrepancies[2]), steps)
end

function _arc1_fa_bfgs(ctx::_Arc1FASpectralContext, params0, k;
                       iterations = 2_000, optimizer_tol = 1e-8,
                       final_gradient_tol = 1e-6, evaluation_callback = nothing)
    iterations isa Integer && iterations > 0 || throw(ArgumentError("iterations must be positive"))
    optimizer_tol > 0 || throw(ArgumentError("optimizer tolerance must be positive"))
    initial = _arc1_fa_exact_objective_gradient(ctx, params0, k)
    evaluation_callback === nothing || evaluation_callback(copy(Float64.(params0)), initial)
    initial.status == :ok || return merge(
        _arc1_fa_assess_optimizer_result((; phat = params0,
            optimizer_converged = false, iterations = 0,
            line_search_success = false,
            optimizer_status = "invalid_initial_proposal"), ctx, k;
            final_gradient_tol, evaluation_callback),
        (; algorithm = :bfgs_hager_zhang, status = :failed,
           accepted = false, final_status = initial.status, reason = initial.reason))

    line_search_stats = _Arc1LineSearchStats()
    last_x = copy(Float64.(params0))
    last_value = initial
    function evaluate(x)
        if !isequal(x, last_x)
            last_x .= x
            line_search_stats.objective_evaluations += 1
            last_value = _arc1_fa_exact_objective_gradient(ctx, x, k)
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
    options = Optim.Options(iterations = iterations, g_abstol = optimizer_tol,
        x_abstol = 0.0, x_reltol = 0.0, f_abstol = 0.0, f_reltol = 0.0,
        allow_f_increases = false)
    result = optimize(f, g!, Float64.(params0),
        Optim.BFGS(linesearch = _Arc1DomainHagerZhang(line_search_stats)), options)
    stop = result.stopped_by
    line_search_success = !(hasproperty(stop, :ls_failed) && stop.ls_failed)
    raw = (; phat = Optim.minimizer(result),
           optimizer_converged = Optim.converged(result),
           line_search_success,
           iterations = Optim.iterations(result),
           optimizer_status = sprint(show, Optim.summary(result)),
           line_search_stats = (; callback_requests = line_search_stats.callback_requests,
               objective_evaluations = line_search_stats.objective_evaluations,
               rejected_trials = line_search_stats.rejected_trials,
               domain_restarts = line_search_stats.domain_restarts))
    assessed = _arc1_fa_assess_optimizer_result(raw, ctx, k; final_gradient_tol,
        evaluation_callback)
    status = assessed.accepted ? :converged : !assessed.line_search_success ?
        :line_search_failed : assessed.status == :numerical_gradient_failure ?
        :numerical_gradient_failure : assessed.final_status == :ok ? :not_converged : :failed
    return merge(assessed, (; status, algorithm = :bfgs_hager_zhang,
        line_search_stats = raw.line_search_stats))
end
