# Exact complete-data T4 Gaussian FA objective for the ARC1 rank-selection
# programme. This file is included directly by the isolated proof test until
# the parent integrates it into the package module.

function _arc1_fa_invalid(reason, nparams)
    return (; status = :invalid_proposal, reason,
            objective = Inf, raw_objective = Inf, loglik = -Inf,
            gradient = zeros(Float64, nparams))
end

function _arc1_fa_exact_objective_gradient(params, Y, X, B, k)
    k in (0, 1) || return _arc1_fa_invalid("rank must be 0 or 1", length(params))
    n, t = size(Y)
    t == 4 || return _arc1_fa_invalid("ARC1 requires exactly four traits", length(params))
    size(B) == (n, n) || return _arc1_fa_invalid("B must be n×n", length(params))
    size(X, 1) == n || return _arc1_fa_invalid("X must have n rows", length(params))
    p = size(X, 2)
    df = n * t - p * t
    df > 0 || return _arc1_fa_invalid("REML requires positive residual degrees of freedom", length(params))
    expected = k == 0 ? 14 : 18
    length(params) == expected || return _arc1_fa_invalid("wrong parameter-vector length", length(params))
    all(isfinite, params) && all(isfinite, Y) && all(isfinite, X) && all(isfinite, B) ||
        return _arc1_fa_invalid("inputs and parameters must be finite", expected)
    isapprox(B, transpose(B); atol = 1e-12, rtol = 1e-12) ||
        return _arc1_fa_invalid("B must be symmetric", expected)

    local E
    try
        E = eigen(Symmetric((Matrix{Float64}(B) + transpose(Matrix{Float64}(B))) / 2))
    catch err
        err isa InterruptException && rethrow()
        err isa LinearAlgebra.LAPACKException && return _arc1_fa_invalid("B eigendecomposition failed", expected)
        rethrow()
    end
    vals = Vector{Float64}(E.values)
    all(isfinite, vals) || return _arc1_fa_invalid("B eigenvalues must be finite", expected)
    # B is a covariance kernel and must be positive semidefinite. Permit only
    # eigensolver-scale negative roundoff (64 ε × scale × n), setting those
    # values to zero; reject any materially negative eigenvalue. No jitter is
    # added to B, G, R, or the marginal covariance.
    scale = max(1.0, maximum(abs, vals))
    roundoff = 64 * eps(Float64) * scale * max(n, 1)
    minimum(vals) < -roundoff &&
        return _arc1_fa_invalid("B is not positive semidefinite", expected)
    vals .= max.(vals, 0.0)
    return _arc1_fa_exact_from_eigen(params, Y, X, vals, Matrix{Float64}(E.vectors), k)
end

function _arc1_fa_exact_from_eigen(params, Y, X, eigenvalues, U, k)
    n, t = size(Y)
    p = size(X, 2)
    q = length(params)
    expected = k == 0 ? 14 : 18
    (k in (0, 1) && t == 4 && size(X, 1) == n && length(eigenvalues) == n &&
     size(U) == (n, n) && q == expected) ||
        return _arc1_fa_invalid("incompatible spectral objective dimensions", q)
    all(isfinite, params) && all(isfinite, Y) && all(isfinite, X) &&
        all(isfinite, eigenvalues) && all(isfinite, U) ||
        return _arc1_fa_invalid("inputs and parameters must be finite", q)
    minimum(eigenvalues) >= 0 || return _arc1_fa_invalid("B eigenvalues must be nonnegative", q)
    isapprox(transpose(U) * U, I; atol = 1e-10, rtol = 1e-10) ||
        return _arc1_fa_invalid("spectral rotation must be orthonormal", q)
    df = 4n - 4p
    df > 0 || return _arc1_fa_invalid("REML requires positive residual degrees of freedom", q)

    local G, R, ψ, λ, chol
    ng = k == 0 ? 4 : 8
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

    # In record-major order, rotation by U'⊗I₄ gives independent blocks
    # Vᵢ = dᵢG + R and fixed-effect blocks Dᵢ = (U'X)ᵢ⊗I₄. In particular,
    # U'1 need not be an eigenvector or have only one nonzero entry.
    Yrot = transpose(U) * Matrix{Float64}(Y)
    Xrot = transpose(U) * Matrix{Float64}(X)
    I4 = Matrix{Float64}(I, 4, 4)
    Ds = [kron(reshape(Vector{Float64}(Xrot[i, :]), 1, p), I4) for i in 1:n]
    zs = [Vector{Float64}(@view Yrot[i, :]) for i in 1:n]
    Ws = Matrix{Float64}[]
    logdetV = 0.0
    try
        for i in 1:n
            Vi = eigenvalues[i] .* G + R
            FV = cholesky(Symmetric(Vi); check = true)
            push!(Ws, FV \ I4)
            logdetV += logdet(FV)
        end
    catch err
        err isa InterruptException && rethrow()
        err isa PosDefException && return _arc1_fa_invalid("a spectral covariance block is not positive definite", q)
        rethrow()
    end

    nc = 4p
    C = zeros(Float64, nc, nc)
    b = zeros(Float64, nc)
    for i in 1:n
        D, z, W = Ds[i], zs[i], Ws[i]
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
    raw = 0.5 * (df * log(2π) + logdetV + logdet(FC))
    SG = zeros(Float64, 4, 4)
    SR = zeros(Float64, 4, 4)
    for i in 1:n
        D, z, W = Ds[i], zs[i], Ws[i]
        e = z - D * β
        raw += 0.5 * dot(e, W * e)
        WD = W * D
        H = W - WD * Cinv * transpose(WD)
        a = W * e
        Ti = (H - a * transpose(a)) / (2df)
        SG .+= eigenvalues[i] .* Ti
        SR .+= Ti
    end
    isfinite(raw) || return _arc1_fa_invalid("REML objective is nonfinite", q)
    SG .= (SG .+ transpose(SG)) ./ 2
    SR .= (SR .+ transpose(SR)) ./ 2

    grad = zeros(Float64, q)
    if k == 0
        η = @view params[1:4]
        grad[1:4] .= exp.(η) .* diag(SG)
    else
        η = @view params[5:8]
        # Differentiate the supplied raw loading vector directly. Do not
        # canonicalize its sign: that would give the wrong derivative at λ<0.
        grad[1:4] .= 2 .* (SG * λ)
        grad[5:8] .= exp.(η) .* diag(SG)
    end

    # R = LL'. Parameters follow the package's column-major lower-triangle
    # order (11,21,31,41,22,32,42,33,43,44).
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
            objective = raw / df, raw_objective = raw, loglik = -raw,
            gradient = grad,
            fixed_effects = permutedims(reshape(β, 4, p)))
end
