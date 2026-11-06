# Candidate-only retained-factor implementation for the opt-in Arc1 v2 policy.
# This file is intentionally not included by the package module yet. The v1
# objective and its strict rounded-matrix domain checks remain untouched.

const _ARC1_FA_V2_REPRESENTATION = "retained_factors_v1"
const _ARC1_FA_V2_FACTOR_ORDER = :loading_floor_uniqueness_residual

function _arc1_fa_v2_invalid(reason, nparams; status = :invalid_proposal)
    return (; status, reason, objective = Inf, raw_objective = Inf,
            loglik = -Inf, gradient = zeros(Float64, nparams),
            fixed_effects = nothing, factor_state = nothing)
end

function _arc1_fa_v2_gradient_failure(raw, df, state, beta, gradient)
    reason = "REML gradient is nonfinite"
    likelihood_observation = (; stage = :likelihood, status = :ok,
        raw_objective = raw, loglik = -raw, parameters = copy(state.parameters),
        factor_state = deepcopy(state))
    gradient_observation = (; stage = :gradient, status = :failed, reason,
                            gradient = copy(gradient))
    return (; status = :failed, reason, objective = raw / df, raw_objective = raw,
            loglik = -raw, gradient = copy(gradient),
            fixed_effects = permutedims(reshape(beta, 4, length(beta) ÷ 4)),
            factor_state = state, observation = likelihood_observation,
            observations = [likelihood_observation, gradient_observation])
end

"""Classify strict positive definiteness of a finite symmetric Float64 matrix exactly."""
function _arc1_fa_v2_exact_float64_pd(matrix)
    size(matrix) == (4, 4) || return false
    all(isfinite, matrix) && issymmetric(matrix) || return false
    exact = Rational{BigInt}.(matrix)
    for n in 1:4
        det(exact[1:n, 1:n]) > 0 || return false
    end
    return true
end

"""Decode optimizer coordinates without recovering the excess from rounded `c + delta`."""
function _arc1_fa_v2_factor_state(params, k)
    (k isa Integer && !(k isa Bool) && k in (0, 1)) ||
        return (; status = :invalid_proposal, reason = "rank must be integer 0 or 1", state = nothing)
    params isa AbstractVector{Float64} ||
        return (; status = :invalid_proposal, reason = "parameters must be a Float64 vector", state = nothing)
    q = k == 0 ? 14 : 18
    length(params) == q || return (; status = :invalid_proposal, reason = "wrong parameter-vector length", state = nothing)
    all(isfinite, params) || return (; status = :invalid_proposal, reason = "parameters must be finite", state = nothing)

    ng = k == 0 ? 4 : 8
    loadings = k == 0 ? zeros(Float64, 4, 0) : reshape(Vector{Float64}(@view params[1:4]), 4, 1)
    eta = k == 0 ? @view(params[1:4]) : @view(params[5:8])
    delta = exp.(eta)
    all(isfinite, delta) && all(>(0), delta) ||
        return (; status = :invalid_proposal, reason = "uniqueness excess transform underflowed or overflowed", state = nothing)

    L = zeros(Float64, 4, 4)
    idx = ng
    for j in 1:4, i in j:4
        idx += 1
        L[i, j] = i == j ? exp(params[idx]) : params[idx]
    end
    all(isfinite, L) && all(>(0), diag(L)) ||
        return (; status = :invalid_proposal, reason = "residual factor must be finite with a positive diagonal", state = nothing)

    c = Float64(FA_UNIQUENESS_FLOOR)
    psi = c .+ delta
    G = loadings * transpose(loadings) + Diagonal(psi)
    R = L * transpose(L)
    all(isfinite, psi) && all(isfinite, G) && all(isfinite, R) ||
        return (; status = :invalid_proposal, reason = "rounded covariance report is nonfinite", state = nothing)

    state = (; rank = Int(k), parameters = Vector{Float64}(params), loadings, delta,
             floor = c, psi, residual_factor = L, G = Matrix{Float64}(G),
             R = Matrix{Float64}(R), factor_order = _ARC1_FA_V2_FACTOR_ORDER,
             factor_valid = true,
             pd_genetic = _arc1_fa_v2_exact_float64_pd(Matrix{Float64}(G)),
             pd_residual = _arc1_fa_v2_exact_float64_pd(Matrix{Float64}(R)),
             rounded_floor_distance = psi .- c,
             floor_rounding = any(iszero, psi .- c))
    return (; status = :ok, reason = nothing, state)
end

# Multiply nonnegative square-root factors while preserving machine-domain
# refusals. A zero result from strictly positive operands means the required
# represented column underflowed; exact zero relationship eigenvalues are
# handled separately in the block builder.
function _arc1_fa_v2_checked_product(a::Float64, b::Float64)
    isfinite(a) && isfinite(b) && a >= 0 && b >= 0 || return nothing
    x = a * b
    isfinite(x) && !(a > 0 && b > 0 && iszero(x)) || return nothing
    return x
end

function _arc1_fa_v2_block_factor(state, d::Float64)
    isfinite(d) && d >= 0 || return nothing
    d == 0 && return Matrix{Float64}(state.residual_factor)
    sd = sqrt(d)
    sfloor = _arc1_fa_v2_checked_product(sd, sqrt(state.floor))
    sfloor === nothing && return nothing
    sexcess = [_arc1_fa_v2_checked_product(sd, sqrt(x)) for x in state.delta]
    any(isnothing, sexcess) && return nothing
    loading = state.rank == 0 ? zeros(Float64, 4, 0) : sd .* state.loadings
    all(isfinite, loading) || return nothing
    state.rank == 1 && any((loading .== 0) .& (state.loadings .!= 0)) && return nothing
    U = hcat(loading, sfloor .* Matrix{Float64}(I, 4, 4),
             Diagonal(Float64[x for x in sexcess]), state.residual_factor)
    all(isfinite, U) || return nothing
    # QR(U') gives U*U' = R'*R. Row signs make diag(R) positive without
    # changing that product; no jitter or covariance refactor is used.
    F = qr(transpose(U))
    Rq = Matrix(F.R[1:4, 1:4])
    signs = map(x -> signbit(x) ? -1.0 : 1.0, diag(Rq))
    Rq = Diagonal(signs) * Rq
    all(isfinite, Rq) && all(>(0), diag(Rq)) || return nothing
    return Matrix(transpose(Rq))
end

function _arc1_fa_v2_exact_objective_gradient(ctx::_Arc1FASpectralContext, params, k)
    params isa AbstractVector || return _arc1_fa_v2_invalid("parameters must be a vector", 0)
    q = length(params)
    state_result = _arc1_fa_v2_factor_state(params, k)
    state_result.status == :ok || return _arc1_fa_v2_invalid(state_result.reason, q)
    state = state_result.state
    state.rank == k || return _arc1_fa_v2_invalid("factor state rank mismatch", q)

    n = ctx.n
    Ls = Vector{Matrix{Float64}}(undef, n)
    logdetV = 0.0
    I4 = Matrix{Float64}(I, 4, 4)
    try
        for i in 1:n
            Li = _arc1_fa_v2_block_factor(state, ctx.eigenvalues[i])
            Li === nothing && return _arc1_fa_v2_invalid("a required spectral factor is outside the Float64 domain", q)
            Ls[i] = Li
            logdetV += 2sum(log, diag(Li))
        end
    catch err
        err isa InterruptException && rethrow()
        return _arc1_fa_v2_invalid("spectral factor evaluation failed: $(sprint(showerror, err))", q)
    end

    Ws = Matrix{Float64}[]
    try
        for L in Ls
            push!(Ws, transpose(L) \ (L \ I4))
        end
    catch err
        err isa InterruptException && rethrow()
        return _arc1_fa_v2_invalid("spectral factor solve failed: $(sprint(showerror, err))", q)
    end

    nc = 4 * ctx.p
    C = zeros(Float64, nc, nc)
    b = zeros(Float64, nc)
    for i in 1:n
        D, z, W = ctx.design_blocks[i], ctx.response_blocks[i], Ws[i]
        C .+= transpose(D) * W * D
        b .+= transpose(D) * W * z
    end
    local FC, beta, Cinv
    try
        FC = cholesky(Symmetric(C); check = true)
        beta = FC \ b
        Cinv = FC \ Matrix{Float64}(I, nc, nc)
    catch err
        err isa InterruptException && rethrow()
        return _arc1_fa_v2_invalid("fixed-effect information is not positive definite", q)
    end
    raw = 0.5 * (ctx.df * log(2π) + logdetV + logdet(FC))
    SG = zeros(Float64, 4, 4)
    SR = zeros(Float64, 4, 4)
    for i in 1:n
        D, z, W = ctx.design_blocks[i], ctx.response_blocks[i], Ws[i]
        e = z - D * beta
        raw += 0.5 * dot(e, W * e)
        WD = W * D
        H = W - WD * Cinv * transpose(WD)
        a = W * e
        Ti = (H - a * transpose(a)) / (2 * ctx.df)
        SG .+= ctx.eigenvalues[i] .* Ti
        SR .+= Ti
    end
    isfinite(raw) || return _arc1_fa_v2_invalid("REML objective is nonfinite", q)
    SG .= (SG .+ transpose(SG)) ./ 2
    SR .= (SR .+ transpose(SR)) ./ 2

    grad = zeros(Float64, q)
    if k == 0
        grad[1:4] .= state.delta .* diag(SG)
        ng = 4
    else
        lambda = vec(state.loadings)
        grad[1:4] .= 2 .* (SG * lambda)
        grad[5:8] .= state.delta .* diag(SG)
        ng = 8
    end
    GL = 2 .* (SR * state.residual_factor)
    idx = ng
    for j in 1:4, i in j:4
        idx += 1
        grad[idx] = i == j ? GL[i, j] * state.residual_factor[j, j] : GL[i, j]
    end
    all(isfinite, grad) || return _arc1_fa_v2_gradient_failure(raw, ctx.df, state, beta, grad)
    return (; status = :ok, reason = nothing,
            objective = raw / ctx.df, raw_objective = raw, loglik = -raw,
            gradient = grad,
            fixed_effects = permutedims(reshape(beta, 4, ctx.p)),
            factor_state = state)
end

function _arc1_fa_v2_checked_kron(A::AbstractMatrix{Float64}, B::AbstractMatrix{Float64})
    out = kron(A, B)
    all(isfinite, out) || return nothing
    for j in axes(A, 2), i in axes(A, 1), l in axes(B, 2), k in axes(B, 1)
        (A[i, j] != 0 && B[k, l] != 0 &&
         iszero(out[(i - 1) * size(B, 1) + k, (j - 1) * size(B, 2) + l])) && return nothing
    end
    return out
end

function _arc1_fa_v2_relationship_factor(B::Matrix{Float64})
    E = eigen(Symmetric((B + transpose(B)) / 2))
    vals = Vector{Float64}(E.values)
    all(isfinite, vals) || return nothing
    scale = max(1.0, maximum(abs, vals))
    roundoff = 64 * eps(Float64) * scale * max(size(B, 1), 1)
    minimum(vals) < -roundoff && return nothing
    vals .= max.(vals, 0.0) # only the same eigensolver-scale allowance as v1 context validation
    roots = sqrt.(vals)
    U = Matrix{Float64}(E.vectors)
    S = U .* reshape(roots, 1, :)
    all(isfinite, S) || return nothing
    for j in eachindex(roots), i in axes(U, 1)
        U[i, j] != 0 && roots[j] > 0 && iszero(S[i, j]) && return nothing
    end
    return S
end

"""Independent full covariance factor assembly and whitened full-design QR.

This uses the original record-level Y, X and relationship kernel B. It does
not consume spectral context blocks or call the optimized block factor builder.
"""
function _arc1_fa_v2_independent_loglik(Y, X, B, params, k)
    observations = NamedTuple[]
    function refusal(status, stage, reason; loglik = -Inf)
        return (; status, reason, failure_stage = stage, loglik,
                observations = copy(observations))
    end

    state_result = _arc1_fa_v2_factor_state(params, k)
    state_result.status == :ok || return refusal(:invalid_proposal, :factor_state, state_result.reason)
    state = state_result.state
    (Y isa AbstractMatrix && X isa AbstractMatrix && B isa AbstractMatrix) ||
        return refusal(:invalid_input, :input, "Y, X and B must be matrices")
    n, t = size(Y)
    size(X, 1) == n && size(B) == (n, n) && t == 4 ||
        return refusal(:invalid_input, :input, "incompatible response, design or relationship dimensions")
    p = size(X, 2)
    df = 4n - 4p
    df > 0 || return refusal(:invalid_input, :input, "REML requires positive residual degrees of freedom")

    local Yf, Xf, Bf
    try
        Yf, Xf, Bf = Matrix{Float64}(Y), Matrix{Float64}(X), Matrix{Float64}(B)
    catch err
        err isa InterruptException && rethrow()
        return refusal(:invalid_input, :input, "Y, X or B cannot be represented as Float64 matrices")
    end
    (all(isfinite, Yf) && all(isfinite, Xf) && all(isfinite, Bf)) ||
        return refusal(:invalid_input, :input, "Y, X and B must be finite")
    isapprox(Bf, transpose(Bf); atol = 1e-12, rtol = 1e-12) ||
        return refusal(:invalid_input, :input, "B must be symmetric")
    push!(observations, (; stage = :validated_input, status = :ok, rows = n, fixed_columns = p, residual_df = df))

    # Match the package's established model-input rank contract rather than
    # treating a merely nonzero unpivoted Householder diagonal as full rank.
    try
        _require_full_fixed_effect_rank(sparse(Xf))
    catch err
        err isa InterruptException && rethrow()
        err isa ArgumentError && return refusal(:invalid_input, :fixed_effect_design, sprint(showerror, err))
        return refusal(:numerical_error, :fixed_effect_design, sprint(showerror, err))
    end
    push!(observations, (; stage = :fixed_effect_design, status = :ok,
                         columns = p, rank = p))

    local S
    try
        S = _arc1_fa_v2_relationship_factor(Bf)
    catch err
        err isa InterruptException && rethrow()
        return refusal(:numerical_error, :relationship_factor, sprint(showerror, err))
    end
    S === nothing && return refusal(:invalid_input, :relationship_factor,
        "B is outside the accepted positive-semidefinite Float64 spectrum domain")
    push!(observations, (; stage = :relationship_factor, status = :ok,
                         factor_columns = size(S, 2), rows = size(S, 1)))

    local full_factor
    try
        blocks = Matrix{Float64}[]
        if state.rank == 1
            loading = _arc1_fa_v2_checked_kron(S, state.loadings)
            loading === nothing && return refusal(:numerical_error, :covariance_factor,
                "loading factor assembly overflowed or underflowed")
            push!(blocks, loading)
        end
        floor_block = _arc1_fa_v2_checked_kron(S,
            sqrt(state.floor) .* Matrix{Float64}(I, 4, 4))
        excess_block = _arc1_fa_v2_checked_kron(S, Matrix(Diagonal(sqrt.(state.delta))))
        residual_block = kron(Matrix{Float64}(I, n, n), state.residual_factor)
        floor_block === nothing && return refusal(:numerical_error, :covariance_factor,
            "floor factor assembly overflowed or underflowed")
        excess_block === nothing && return refusal(:numerical_error, :covariance_factor,
            "uniqueness factor assembly overflowed or underflowed")
        all(isfinite, residual_block) || return refusal(:numerical_error, :covariance_factor,
            "residual factor assembly is nonfinite")
        append!(blocks, (floor_block, excess_block, residual_block))
        full_factor = hcat(blocks...)
        all(isfinite, full_factor) || return refusal(:numerical_error, :covariance_factor,
            "full covariance factor is nonfinite")
    catch err
        err isa InterruptException && rethrow()
        return refusal(:numerical_error, :covariance_factor, sprint(showerror, err))
    end

    m = 4n
    local Lfull, logdetV
    try
        Fv = qr(transpose(full_factor))
        Rv = Matrix(Fv.R[1:m, 1:m])
        signs = map(x -> signbit(x) ? -1.0 : 1.0, diag(Rv))
        Rv = Diagonal(signs) * Rv
        (all(isfinite, Rv) && all(>(0), diag(Rv))) ||
            return refusal(:numerical_error, :covariance_qr, "full covariance factor is numerically rank deficient")
        Lfull = Matrix(transpose(Rv))
        logdetV = 2sum(log, diag(Lfull))
        isfinite(logdetV) || return refusal(:numerical_error, :covariance_qr, "full covariance log determinant is nonfinite")
    catch err
        err isa InterruptException && rethrow()
        return refusal(:numerical_error, :covariance_qr, sprint(showerror, err))
    end
    push!(observations, (; stage = :covariance_factor, status = :ok,
                         factor_rows = m, factor_columns = size(full_factor, 2), logdet_covariance = logdetV))

    local Xw, yw
    try
        Xfull = kron(Xf, Matrix{Float64}(I, 4, 4))
        yfull = vec(permutedims(Yf))
        Xw = LowerTriangular(Lfull) \ Xfull
        yw = LowerTriangular(Lfull) \ yfull
        (all(isfinite, Xw) && all(isfinite, yw)) ||
            return refusal(:numerical_error, :whitening, "whitened response or design is nonfinite")
    catch err
        err isa InterruptException && rethrow()
        return refusal(:numerical_error, :whitening, sprint(showerror, err))
    end
    push!(observations, (; stage = :whitened_data, status = :ok,
                         rows = size(Xw, 1), columns = size(Xw, 2)))

    local fixed_logdet, residual_norm
    try
        Fx = qr(Xw)
        Rx = Matrix(Fx.R[1:(4p), 1:(4p)])
        (all(isfinite, Rx) && all(x -> !iszero(x), diag(Rx))) ||
            return refusal(:numerical_error, :fixed_effect_qr, "whitened fixed-effect design is rank deficient")
        fixed_logdet = 2sum(log, abs.(diag(Rx)))
        transformed = Fx.Q' * yw
        (length(transformed) == m && all(isfinite, transformed)) ||
            return refusal(:numerical_error, :fixed_effect_qr, "Householder response reduction failed")
        residual_coordinates = @view transformed[(4p + 1):m]
        residual_norm = sum(abs2, residual_coordinates)
        (isfinite(fixed_logdet) && isfinite(residual_norm)) ||
            return refusal(:numerical_error, :fixed_effect_qr, "fixed-effect correction is nonfinite")
    catch err
        err isa InterruptException && rethrow()
        return refusal(:numerical_error, :fixed_effect_qr, sprint(showerror, err))
    end
    push!(observations, (; stage = :fixed_effect_qr, status = :ok,
                         logdet_fixed_effects = fixed_logdet, residual_sum_squares = residual_norm))

    raw = 0.5 * (df * log(2π) + logdetV + fixed_logdet + residual_norm)
    isfinite(raw) || return refusal(:numerical_error, :likelihood, "independent REML likelihood is nonfinite")
    ll = -raw
    push!(observations, (; stage = :likelihood, status = :ok, raw_loglik = ll))
    return (; status = :ok, reason = nothing, failure_stage = nothing, loglik = ll,
            raw_objective = raw, observations = copy(observations))
end

function _arc1_fa_v2_certify(Y, X, B, params, k, optimized)
    (optimized isa Real && !(optimized isa Bool) && isfinite(optimized)) ||
        return (; status = :failed, reason = "optimized loglik is nonfinite or malformed",
        independent_loglik = -Inf, discrepancy = Inf, observations = NamedTuple[])
    independent = _arc1_fa_v2_independent_loglik(Y, X, B, params, k)
    independent.status == :ok ||
        return (; status = :failed, reason = independent.reason,
                independent_status = independent.status, independent_loglik = independent.loglik,
                discrepancy = Inf, observations = independent.observations)
    discrepancy = abs(independent.loglik - optimized)
    isfinite(discrepancy) && discrepancy <= 1e-8 ||
        return (; status = :failed, reason = "independent likelihood discrepancy exceeds the frozen 1e-8 limit",
                independent_status = :ok, independent_loglik = independent.loglik,
                discrepancy, observations = independent.observations)
    return (; status = :ok, reason = nothing, independent_status = :ok,
            independent_loglik = independent.loglik, discrepancy,
            observations = independent.observations)
end

"""Apply frozen Arc1 v2 numerical acceptance limits to already observed checks."""
function _arc1_fa_v2_accuracy_check(optimized_loglik, independent_loglik,
                                    analytic_gradient, fd_large, fd_small,
                                    line_search_success)
    valid_containers = analytic_gradient isa AbstractVector &&
        fd_large isa AbstractVector && fd_small isa AbstractVector
    valid_scalars = optimized_loglik isa Real && !(optimized_loglik isa Bool) &&
        independent_loglik isa Real && !(independent_loglik isa Bool) &&
        line_search_success isa Bool
    valid_shapes = valid_containers && length(analytic_gradient) > 0 &&
        length(fd_large) == length(analytic_gradient) && length(fd_small) == length(analytic_gradient)
    finite_real_nonbool = x -> x isa Real && !(x isa Bool) && isfinite(x)
    valid_values = valid_scalars && valid_shapes &&
        all(finite_real_nonbool, analytic_gradient) &&
        all(finite_real_nonbool, fd_large) && all(finite_real_nonbool, fd_small) &&
        isfinite(optimized_loglik) && isfinite(independent_loglik)
    if !valid_values
        return (; status = :failed, reason = "accuracy inputs are malformed or nonfinite",
                passed = false, loglik_discrepancy = Inf, analytic_gradient_inf_norm = Inf,
                fd_norms = (Inf, Inf), fd_discrepancies = (Inf, Inf))
    end
    ll_diff = abs(independent_loglik - optimized_loglik)
    gnorm = norm(analytic_gradient, Inf)
    norms = (norm(fd_large, Inf), norm(fd_small, Inf))
    diffs = (norm(fd_large - analytic_gradient, Inf), norm(fd_small - analytic_gradient, Inf))
    passed = line_search_success && ll_diff <= 1e-8 && gnorm <= 1e-6 &&
             maximum(norms) <= 5e-6 && maximum(diffs) <= 5e-6
    reason = passed ? nothing : !line_search_success ? "line search failed" :
             ll_diff > 1e-8 ? "independent likelihood discrepancy exceeds 1e-8" :
             gnorm > 1e-6 ? "scaled analytic gradient exceeds 1e-6" :
             "central-difference norm or discrepancy exceeds 5e-6"
    return (; status = passed ? :ok : :failed, reason, passed,
            loglik_discrepancy = ll_diff, analytic_gradient_inf_norm = gnorm,
            fd_norms = norms, fd_discrepancies = diffs)
end
