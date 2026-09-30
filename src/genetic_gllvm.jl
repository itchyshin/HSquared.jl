# Genetic GLLVM (#50) — latent-structure descriptors (slice 1).
#
# Descriptive, SUPPLIED-covariance ONLY. Given supplied latent loadings `Λ`
# (`traits × K`) and optional uniqueness `Ψ` (`traits`), report the
# rotation-INVARIANT functionals of the implied among-trait genetic covariance
# `Σ_g = ΛΛ' (+ diag Ψ)` — the latent layer of a genetic GLLVM. NO solver, NO
# marginal, NO estimation. Reuses `multivariate.jl` (`lowrank_covariance`,
# `factor_analytic_covariance`, `genetic_correlation`) and `evolvability.jl`
# (`genetic_pca`, `g_max`). Raw loadings are NEVER returned (rotation-nonidentified
# — the FA rotation convention, docs/dev-log/decisions/2026-06-19-fa-rotation-convention.md).

"""
    genetic_gllvm_descriptors(loadings; uniqueness = nothing)

Rotation-invariant descriptors of a genetic-GLLVM latent layer with SUPPLIED
`traits × K` loadings `Λ` (and optional positive `traits`-vector uniqueness `Ψ`).
The implied among-trait genetic covariance is `Σ_g = ΛΛ'` (low-rank,
`uniqueness = nothing`) or `Σ_g = ΛΛ' + diag(Ψ)` (factor-analytic). Returns a
NamedTuple:

- `genetic_covariance` — `Σ_g`;
- `genetic_variances` — `diag(Σ_g)`;
- `genetic_correlation` — the correlation matrix of `Σ_g`;
- `communality` — `c²_t = (ΛΛ')_tt / Σ_g[t,t]` ∈ `[0,1]`, the per-trait fraction of
  genetic variance explained by the common latent factors (`= 1` when `Ψ` is
  absent; the one genuinely new GLLVM descriptor);
- `genetic_pca` — `(values, vectors)` of `Σ_g` (descending eigenvalues,
  sign-canonicalized eigenvectors);
- `g_max` — leading genetic principal axis of `Σ_g`;
- `rank` / `n_latent_factors` — the latent-factor count `K = size(Λ, 2)`.

DESCRIPTIVE, supplied-covariance only: `Λ`/`Ψ` are NOT estimated by this
descriptor function, which computes no marginal / likelihood / fit or bridge
payload. The genetic covariance, variances, correlations, and PCA eigenvalues
are functionals of `Σ_g`; communality additionally depends on the supplied
decomposition through `Ψ`. At fixed `Ψ`, an orthogonal rotation `Λ → ΛQ` leaves
communality unchanged, but decompositions with the same `Σ_g` and different
`Ψ` need not have the same communality. Raw loadings `Λ` are never returned
(they are rotation-nonidentified). The `genetic_pca` eigenvectors are defined
only up to sign, and a repeated eigenvalue identifies its eigenspace rather
than a unique axis. Guards
(dimension / positivity / rank) are delegated to [`lowrank_covariance`](@ref) and
[`factor_analytic_covariance`](@ref). The first foundation step of the genetic
GLLVM (#50); the supplied-covariance latent objective and estimation were added
in later slices below.
"""
function genetic_gllvm_descriptors(loadings::AbstractMatrix; uniqueness = nothing)
    Σ_g = uniqueness === nothing ?
        lowrank_covariance(loadings) :
        factor_analytic_covariance(loadings, uniqueness)
    common = vec(sum(abs2, Float64.(loadings); dims = 2))   # diag(ΛΛ'), the common (latent) part
    gv = diag(Σ_g)
    communality = common ./ gv
    K = size(loadings, 2)
    return (genetic_covariance = Σ_g,
            genetic_variances = gv,
            genetic_correlation = genetic_correlation(Σ_g),
            communality = communality,
            genetic_pca = genetic_pca(Σ_g),
            g_max = g_max(Σ_g),
            rank = K,
            n_latent_factors = K)
end

"""
    genetic_gllvm_descriptors(result::NamedTuple)

Rotation-invariant genetic-GLLVM latent-structure descriptors for an ESTIMATED
factor-analytic or low-rank multivariate REML fit (`fit_multivariate_reml(...;
genetic_structure = :factor_analytic | :lowrank, rank = K)`). Reads the fit's
estimated, rotation-invariant genetic covariance `G = result.genetic_covariance`
and uniqueness `Ψ` ([`genetic_uniqueness`](@ref); `nothing` ⇒ low-rank, `Ψ = 0`) —
NEVER the rotation-nonidentified loadings — and returns the same NamedTuple as the
supplied-loadings method, with `communality = 1 − Ψ / diag(G)` (the per-trait
fraction of genetic variance from the common latent factors; `= 1` for low-rank).
For FA, this communality is conditional on the fitted `G`/`Ψ` decomposition;
equal `G` matrices can yield different communalities. Synthetic results must carry
consistent factor-count/loading dimensions and finite nonnegative uniqueness with
`Ψ <= diag(G)`. Loading values are checked when supplied, but descriptors are
computed from `G` and `Ψ`, preserving the rotation-free output contract.
Rejects the rotation-free `:diagonal` / `:unstructured` structures, which have no
latent-factor interpretation.
"""
function genetic_gllvm_descriptors(result::NamedTuple)
    meta = genetic_structure(result)   # throws unless the fit carries structured metadata
    meta.structure in (:lowrank, :factor_analytic) || throw(ArgumentError(
        "genetic_gllvm_descriptors(result) needs a :lowrank or :factor_analytic fit; got :$(meta.structure)"))
    G = Matrix{Float64}(result.genetic_covariance)
    correlation = genetic_correlation(G)  # validate covariance before descriptor arithmetic
    T = size(G, 1)
    K = meta.rank
    (K isa Integer && !(K isa Bool) && 1 <= K <= T) || throw(ArgumentError(
        "structured result rank must be an integer between 1 and the number of traits"))
    L = result.genetic_loadings
    if L !== nothing
        L isa AbstractMatrix || throw(ArgumentError("structured result loadings must be a matrix"))
        size(L) == (T, K) || throw(ArgumentError("structured result loadings must be T×K"))
        _check_finite_matrix(L, "structured result loadings")
    end
    rawψ = result.genetic_uniqueness
    ψ = if rawψ === nothing
        meta.structure == :lowrank || throw(ArgumentError(
            "factor-analytic result must contain uniqueness"))
        nothing
    else
        rawψ isa Union{AbstractVector, Tuple} || throw(ArgumentError(
            "structured result uniqueness must be a vector"))
        v = Float64.(collect(rawψ))
        length(v) == T || throw(ArgumentError("structured result uniqueness length must equal T"))
        all(isfinite, v) && all(>=(0), v) || throw(ArgumentError(
            "structured result uniqueness must be finite and nonnegative"))
        meta.structure == :lowrank && !all(iszero, v) && throw(ArgumentError(
            "lowrank result uniqueness must be nothing or zero"))
        v
    end
    gv = diag(G)
    ψ === nothing || all(ψ .<= gv) || throw(ArgumentError(
        "structured result uniqueness must not exceed genetic variances"))
    communality = ψ === nothing ? ones(T) : (gv .- ψ) ./ gv
    return (genetic_covariance = G,
            genetic_variances = gv,
            genetic_correlation = correlation,
            communality = communality,
            genetic_pca = genetic_pca(G),
            g_max = g_max(G),
            rank = K,
            n_latent_factors = K)
end

"""
    genetic_gllvm_gaussian_mme(Y, X, Z, Ainv, loadings, R0; uniqueness = nothing, ids = nothing)

Supplied-covariance **Gaussian** genetic-GLLVM latent solve (#50 slice 2). With a
Gaussian response, the genetic-GLLVM latent layer `η[i,t] = Σ_k Λ[t,k] g[i,k]`,
`g[·,k] ~ N(0, A)` and, when supplied, trait-specific effects
`d[·,t] ~ N(0, Ψ[t,t] A)` make the trait-level effect `U = FΛ′ + D` and the
among-trait genetic covariance `G_lat = ΛΛ' (+ diag Ψ)` satisfy
`Cov(vec(U)) = G_lat ⊗ A` — i.e. the Gaussian genetic GLLVM is EXACTLY the
multivariate animal model at `G0 = G_lat`. This convenience builds `G_lat` from the
SUPPLIED `traits × K` loadings `Λ` (+ optional positive uniqueness `Ψ`) and solves
it through [`multivariate_mme`](@ref), returning that solve (`beta`,
`breeding_values`, `genetic_covariance = G_lat`, `residual_covariance`,
`genetic_correlation`, `residual_correlation`, `traits`) augmented with the
rotation-invariant `latent_structure` ([`genetic_gllvm_descriptors`](@ref)) and
`n_latent_factors = K`.

`G_lat` must be positive definite for the multivariate genetic precision `G0⁻¹` to
exist: supply a positive uniqueness `Ψ`, or full-rank loadings (`K ≥ traits`). A
pure low-rank `G_lat` (`K < traits`, no `Ψ`) is singular and is rejected by the
solve. SUPPLIED-covariance only — `Λ`/`Ψ`/`R0` are NOT estimated (that is slice 3),
and only rotation-INVARIANT functionals of the latent structure are reported (never
raw loadings). No R model-spec or bridge payload.
"""
function genetic_gllvm_gaussian_mme(Y, X, Z, Ainv, loadings, R0;
                                    uniqueness = nothing, ids = nothing)
    G_lat = uniqueness === nothing ?
        lowrank_covariance(loadings) :
        factor_analytic_covariance(loadings, uniqueness)
    size(G_lat, 1) == size(Y, 2) || throw(ArgumentError(
        "loadings imply $(size(G_lat, 1)) traits but Y has $(size(Y, 2)) columns"))
    solve = multivariate_mme(Y, X, Z, Ainv, G_lat, R0; ids = ids)
    return (beta = solve.beta,
            breeding_values = solve.breeding_values,
            genetic_covariance = solve.genetic_covariance,
            residual_covariance = solve.residual_covariance,
            genetic_correlation = solve.genetic_correlation,
            residual_correlation = solve.residual_correlation,
            traits = solve.traits,
            latent_structure = genetic_gllvm_descriptors(loadings; uniqueness = uniqueness),
            n_latent_factors = size(loadings, 2))
end

# ── Non-Gaussian K-factor latent Laplace marginal (#50 slice 2, non-Gaussian) ──────

# Varying trial counts are supported by the standalone scalar animal-model path.
# Genetic GLLVM currently dispatches one scalar response family per trait.
function _check_gllvm_record_family(family)
    families = family isa AbstractVector ? family : (family,)
    any(f -> f isa BinomialVectorResponse, families) && throw(ArgumentError(
        "per-record binomial trials are not supported by genetic GLLVM; use standalone laplace_marginal_loglik or fit_laplace_reml for varying trials"))
    return nothing
end

"""A converged GLLVM mode has non-positive observed joint Laplace curvature."""
abstract type GLLVMParameterEvaluationError <: Exception end

struct GLLVMInvalidLaplaceCurvatureError <: GLLVMParameterEvaluationError
    message::String
end
struct GLLVMInvalidParameterEvaluationError <: GLLVMParameterEvaluationError
    message::String
end
Base.showerror(io::IO, err::GLLVMInvalidLaplaceCurvatureError) = print(io, err.message)
Base.showerror(io::IO, err::GLLVMInvalidParameterEvaluationError) = print(io, err.message)

# Validate caller inputs before mode calculations or outer optimizer evaluations.
function _check_gllvm_mode_inputs(Y, X, family, tol::Real, maxiter::Integer)
    isfinite(tol) && tol > 0 || throw(ArgumentError("tol must be finite and positive"))
    maxiter >= 0 || throw(ArgumentError("maxiter must be nonnegative"))
    Yd = _check_finite_matrix(Y, "Y")
    Xd = _check_finite_matrix(X, "X")
    if family isa AbstractVector
        length(family) == size(Yd, 2) || throw(ArgumentError(
            "families vector length must equal T = size(Y,2) = $(size(Yd, 2))"))
        all(f -> f isa ResponseFamily, family) || throw(ArgumentError(
            "families vector must contain ResponseFamily objects"))
    end
    families = family isa AbstractVector ? family : (family,)
    for f in families
        if f isa GaussianResponse
            isfinite(f.sigma_e2) && f.sigma_e2 > 0 || throw(ArgumentError(
                "GaussianResponse sigma_e2 must be finite and positive"))
        end
    end
    return Yd, Xd
end
#
# Generalizes the single-factor `laplace_marginal_loglik` (nongaussian.jl) to a
# K-FACTOR genetic latent field: vec(g) ~ N(0, I_K ⊗ A) (each factor g[·,k] ~ N(0,A)
# independently), η[i,t] = (Xβ)[i,t] + Σ_k Λ[t,k] g[i,k], y[i,t] | η ~ Family. The
# implied among-trait genetic covariance is G_lat = ΛΛ'. Penalized-IRLS Newton over
# [β (flat prior); vec(g)] then a Gaussian integral at the mode — the SAME structure
# as the single-factor kernel with (Z, Ainv/σ²a) replaced by (W, I_K ⊗ Ainv), where
# W is the Λ-weighted latent design (record (i,t) scatters Λ[t,:] into animal i's
# K factor slots). Reuses the `nongaussian.jl` `ResponseFamily` kernels.

"""
    gllvm_laplace_marginal_loglik(Y, Ainv, loadings, family; X = ones(size(Y,1), 1), tol = 1e-10, maxiter = 100)

Laplace-approximate fixed-and-genetic-effect integrated objective of the
**K-factor genetic GLLVM** with
SUPPLIED `T×K` loadings `Λ`. The latent field `vec(g) ~ N(0, I_K ⊗ A)` (`A⁻¹ = Ainv`)
enters `η[i,t] = (Xβ)[i,t] + Σ_k Λ[t,k] g[i,k]` and `y[i,t] | η[i,t] ~ family`
(a `ResponseFamily` or a length-`T` `Vector` of `ResponseFamily`s — one per trait column
of `Y`); `β` is integrated under a flat measure, not optimized as in ordinary
non-Gaussian ML. `Y` is the `q×T` response matrix
(balanced, fully observed); `X` is the `q×p` individual-level fixed-effect design
(per-trait coefficients; default per-trait intercept). Returns a named tuple with
`loglik`, `beta (p×T)`, `g (q×K)`, `converged`, `gradient_norm`, `iterations`,
`stop_reason` (`:converged`, `:maxiter`, or `:line_search_failed`), and total
`backtracks` across the inner mode iterations. The gradient norm and convergence
flag describe the returned mode.

A finite mode that misses `tol` returns `loglik = NaN` with its stop reason and
gradient diagnostics, without evaluating observed Laplace curvature. A
nonfinite parameter-point calculation or non-positive observed curvature raises
an internal typed numerical error. The outer fitter treats only these typed
trial-point errors as invalid optimizer evaluations; input-contract errors
propagate. It rejects a final optimizer point without a finite, converged inner
mode.

**Per-trait families:** pass a `Vector` of `T` `ResponseFamily` objects to apply a
different family to each trait column of `Y` — e.g.
`[PoissonResponse(), GaussianResponse(1.0)]` for a count first trait and a continuous
second trait. Passing a single `ResponseFamily` (the original call form) applies it
uniformly to all traits; a uniform `Vector` of `T` identical families gives numerically
IDENTICAL results to the scalar path (the per-record dispatch is the same). The vector
length must equal `T = size(Y, 2)`; a mismatch throws `ArgumentError`. Per-trait
`_check_counts` is run per column against its own family before the Newton loop.
`X` must have full column rank under the flat fixed-effect measure. An all-zero
Poisson trait with an intercept is rejected because its integrated objective is
improper. Nonzero-count Poisson traits with an intercept start at the log trait
mean; this improves the bounded high-count case but is not a general solver
guarantee.

Generalizes [`laplace_marginal_loglik`](@ref) (the `K = 1` single-factor case, to
which it reduces EXACTLY, the Laplace approximation being invariant under the affine
latent reparameterization). For a `GaussianResponse` it is EXACT and equals the
multivariate REML marginal at `G0 = ΛΛ'`, `R0 = σ²e·I`. `G_lat = ΛΛ'` need NOT be
positive definite (`P = I_K ⊗ Ainv` is full-rank regardless), so `K < T` /
`K > T` / a singular `ΛΛ'` are all handled — unlike the Gaussian-MME path
([`genetic_gllvm_gaussian_mme`](@ref)), which requires a PD `G_lat`. The solver
reports the score norm at its returned mode and uses objective backtracking for
scoring steps; convergence establishes stationarity, not global optimality or
general recovery. EXPERIMENTAL, dense / validation-scale, SUPPLIED
loadings (NOT estimated by this kernel), balanced/fully-observed `Y` only; INTERNAL
(not exported, mirroring the single-factor kernel). The bounded R Poisson route
uses the fitted kernel below, not this supplied-loading function.
Per-record varying-trial `BinomialVectorResponse` is rejected; use the standalone
scalar animal-model path for varying trials.
"""
function gllvm_laplace_marginal_loglik(Y::AbstractMatrix, Ainv::AbstractMatrix,
                                       loadings::AbstractMatrix,
                                       family::Union{ResponseFamily, AbstractVector};
                                       X::AbstractMatrix = ones(size(Y, 1), 1),
                                       tol::Real = 1e-10, maxiter::Integer = 100)
    _check_gllvm_record_family(family)
    Yd, Xd = _check_gllvm_mode_inputs(Y, X, family, tol, maxiter)
    Ai = Matrix{Float64}(Ainv)
    Λ = Matrix{Float64}(loadings)
    q, T = size(Yd)
    size(Ai, 1) == q == size(Ai, 2) || throw(ArgumentError("Ainv must be q×q with q = size(Y,1)"))
    Ai = _check_relationship_precision(Ai, q)
    size(Λ, 1) == T || throw(ArgumentError("loadings must have T = size(Y,2) rows"))
    all(isfinite, Λ) || throw(ArgumentError("loadings must be finite"))
    size(Xd, 1) == q || throw(ArgumentError("X must have q = size(Y,1) rows"))

    # Build per-record family lookup: scalar family → same family for every record;
    # Vector of families → one per trait column (length must equal T).
    if family isa AbstractVector
        length(family) == T || throw(ArgumentError(
            "families vector length ($(length(family))) must equal T = size(Y,2) = $T"))
        fam_of_t = collect(family)   # Vector{ResponseFamily} (concrete copy, fast indexing)
    else
        fam_of_t = nothing           # sentinel: scalar path
    end
    # Per-trait _check_counts: each column of Y validated against its own family.
    if fam_of_t === nothing
        _check_counts(family, vec(Yd))
    else
        for t in 1:T
            _check_counts(fam_of_t[t], Yd[:, t])
        end
    end

    K = size(Λ, 2)
    p = size(Xd, 2)
    rank(Xd) == p || throw(ArgumentError(
        "X must have full column rank for a proper flat-measure fixed-effect integral"))
    intercept_direction = p == 0 ? Float64[] : Xd \ ones(q)
    has_intercept = norm(Xd * intercept_direction .- 1.0) <= 1e-8 * sqrt(q)
    for t in 1:T
        fam_t = fam_of_t === nothing ? family : fam_of_t[t]
        _check_flat_effect_integral(fam_t, @view(Yd[:, t]), Xd)
    end

    # records r = (i,t): β trait-major (trait t → cols (t-1)p+1:t·p), g factor-major
    # (factor k → cols (k-1)q+1:k·q); W scatters Λ[t,:] into animal i's K factor slots.
    n = q * T
    yv = Vector{Float64}(undef, n)
    fam_of_r = fam_of_t === nothing ? nothing : Vector{ResponseFamily}(undef, n)
    Xrec = zeros(n, p * T)
    W = zeros(n, q * K)
    r = 0
    for t in 1:T, i in 1:q
        r += 1
        yv[r] = Yd[i, t]
        if fam_of_r !== nothing
            fam_of_r[r] = fam_of_t[t]
        end
        @inbounds for j in 1:p
            Xrec[r, (t - 1) * p + j] = Xd[i, j]
        end
        @inbounds for k in 1:K
            W[r, (k - 1) * q + i] = Λ[t, k]
        end
    end

    # Convenience closures: dispatch to per-record family (scalar or per-trait).
    _score(r, y, η) = fam_of_r === nothing ? _fam_score(family, y, η) : _fam_score(fam_of_r[r], y, η)
    _weight(r, y, η) = fam_of_r === nothing ? _fam_weight(family, y, η) : _fam_weight(fam_of_r[r], y, η)
    _observed_weight(r, y, η) = fam_of_r === nothing ? _fam_observed_weight(family, y, η) : _fam_observed_weight(fam_of_r[r], y, η)
    _loglik_r(r, y, η) = fam_of_r === nothing ? _fam_loglik(family, y, η) : _fam_loglik(fam_of_r[r], y, η)

    # latent prior precision P = I_K ⊗ Ainv (block diagonal, K blocks of Ainv)
    P = zeros(q * K, q * K)
    for k in 1:K
        rngk = ((k - 1) * q + 1):(k * q)
        P[rngk, rngk] .= Ai
    end

    pβ = p * T
    β = zeros(pβ)
    if has_intercept
        for t in 1:T
            fam_t = fam_of_t === nothing ? family : fam_of_t[t]
            if fam_t isa PoissonResponse
                mean_count = sum(@view Yd[:, t]) / q
                β[((t - 1) * p + 1):(t * p)] .= log(mean_count) .* intercept_direction
            end
        end
    end
    g = zeros(q * K)
    gnorm = Inf
    iters = 0
    converged = false
    stop_reason = :maxiter
    backtracks = 0
    local H
    for it in 1:maxiter
        iters = it
        η = Xrec * β .+ W * g
        s = [_score(i, yv[i], η[i]) for i in 1:n]
        w = [_weight(i, yv[i], η[i]) for i in 1:n]
        all(isfinite, η) && all(isfinite, s) && all(isfinite, w) ||
            throw(GLLVMInvalidParameterEvaluationError(
                "genetic GLLVM scoring quantities became non-finite at this parameter point"))
        grad = vcat(transpose(Xrec) * s, transpose(W) * s .- P * g)
        gnorm = norm(grad)
        all(isfinite, grad) && isfinite(gnorm) || throw(GLLVMInvalidParameterEvaluationError(
            "genetic GLLVM scoring gradient became non-finite at this parameter point"))
        if gnorm < tol
            converged = true
            stop_reason = :converged
            break
        end
        WX = w .* Xrec
        WW = w .* W
        H = [transpose(Xrec)*WX  transpose(Xrec)*WW
             transpose(W)*WX     (transpose(W)*WW .+ P)]
        all(isfinite, H) || throw(GLLVMInvalidParameterEvaluationError(
            "genetic GLLVM working Hessian became non-finite at this parameter point"))
        step = try
            Symmetric(H) \ grad
        catch err
            (err isa PosDefException || err isa SingularException) || rethrow()
            throw(GLLVMInvalidParameterEvaluationError(
                "genetic GLLVM working Hessian is singular or not positive definite at this parameter point"))
        end
        all(isfinite, step) || throw(GLLVMInvalidParameterEvaluationError(
            "genetic GLLVM scoring step became non-finite at this parameter point"))

        # Fisher/Newton scoring is not guaranteed to improve the observed
        # joint mode objective for every supported response family. Backtrack
        # until the candidate is finite and non-decreasing.
        current_objective = sum(_loglik_r(i, yv[i], η[i]) for i in 1:n) - 0.5 * dot(g, P * g)
        isfinite(current_objective) || throw(GLLVMInvalidParameterEvaluationError(
            "genetic GLLVM conditional objective became non-finite at this parameter point"))
        objective_roundoff = 10 * eps(Float64) * max(1.0, abs(current_objective))
        α = 1.0
        accepted = false
        for _ in 1:40
            β_try = β .+ α .* step[1:pβ]
            g_try = g .+ α .* step[(pβ + 1):end]
            if β_try == β && g_try == g
                break
            end
            η_try = Xrec * β_try .+ W * g_try
            objective_try = sum(_loglik_r(i, yv[i], η_try[i]) for i in 1:n) -
                            0.5 * dot(g_try, P * g_try)
            if isfinite(objective_try) && objective_try >= current_objective - objective_roundoff
                β .= β_try
                g .= g_try
                accepted = true
                break
            end
            α *= 0.5
            backtracks += 1
        end
        if !accepted
            stop_reason = :line_search_failed
            break
        end
    end

    η = Xrec * β .+ W * g
    s = [_score(i, yv[i], η[i]) for i in 1:n]
    final_grad = vcat(transpose(Xrec) * s, transpose(W) * s .- P * g)
    gnorm = norm(final_grad)
    converged = isfinite(gnorm) && gnorm < tol
    converged && (stop_reason = :converged)
    all(isfinite, η) && all(isfinite, final_grad) && isfinite(gnorm) ||
        throw(GLLVMInvalidParameterEvaluationError(
            "genetic GLLVM mode or score became non-finite at this parameter point"))
    if !converged
        return (loglik = NaN,
                beta = reshape(β, p, T),
                g = reshape(g, q, K),
                converged = false, gradient_norm = gnorm, iterations = iters,
                stop_reason = stop_reason, backtracks = backtracks)
    end
    w = [_observed_weight(i, yv[i], η[i]) for i in 1:n]
    all(isfinite, w) || throw(GLLVMInvalidParameterEvaluationError(
        "genetic GLLVM observed weights became non-finite at this parameter point"))
    WX = w .* Xrec
    WW = w .* W
    H = [transpose(Xrec)*WX  transpose(Xrec)*WW
         transpose(W)*WX     (transpose(W)*WW .+ P)]
    all(isfinite, H) || throw(GLLVMInvalidParameterEvaluationError(
        "genetic GLLVM observed Hessian became non-finite at this parameter point"))
    cond = sum(_loglik_r(i, yv[i], η[i]) for i in 1:n)
    quad_g = dot(g, P * g)
    isfinite(cond) && isfinite(quad_g) || throw(GLLVMInvalidParameterEvaluationError(
        "genetic GLLVM Laplace objective terms became non-finite at this parameter point"))
    logdet_Ainv = logdet(cholesky(Symmetric(Ai)))
    Hfactor = try
        cholesky(Symmetric(H))
    catch err
        err isa PosDefException || rethrow()
        throw(GLLVMInvalidLaplaceCurvatureError(
            "converged genetic GLLVM mode has non-positive observed Laplace curvature"))
    end
    logdet_H = logdet(Hfactor)
    loglik = cond - 0.5 * quad_g + 0.5 * K * logdet_Ainv + 0.5 * pβ * log(2π) - 0.5 * logdet_H
    isfinite(loglik) || throw(GLLVMInvalidParameterEvaluationError(
        "genetic GLLVM Laplace objective became non-finite at this parameter point"))
    return (loglik = converged ? loglik : NaN,
            beta = reshape(β, p, T),     # p×T (trait-major β reshapes to columns = traits)
            g = reshape(g, q, K),        # q×K
            converged = converged, gradient_norm = gnorm, iterations = iters,
            stop_reason = stop_reason, backtracks = backtracks)
end

# ── GeneticGLLVMFit fitted-object wrapper (#50 consumability) ─────────────────
#
# Wraps the result of `fit_gllvm_laplace_reml` in a named struct so that
# accessor methods can dispatch on it (avoiding collision with the multivariate
# NamedTuple extractors in multivariate.jl and the AnimalModelFit extractors in
# likelihood.jl). All original field names remain accessible via the struct
# fields. INTERNAL — not exported, mirroring `fit_gllvm_laplace_reml` itself.

"""
    GeneticGLLVMFit

Internal fitted-object wrapper for [`fit_gllvm_laplace_reml`](@ref). Stores
the fitted trait covariance and effects, outer optimizer status, and final inner
mode diagnostics, and exposes typed extractor methods:

- `genetic_covariance(fit)` — the rotation-invariant `G_lat` matrix
- `breeding_values(fit)`    — `q × T` trait genetic conditional modes on the link scale
- `latent_structure(fit)`   — the `genetic_gllvm_descriptors` NamedTuple
- `loglik(fit)`             — the fitted fixed-and-genetic-effect integrated Laplace objective

`converged` is true only when both the outer loading optimizer and final inner
mode converge. `iterations` remains the outer optimizer iteration count.
`optimizer_converged`, `mode_converged`, `mode_gradient_norm`,
`mode_iterations`, `mode_stop_reason`, and `mode_backtracks` expose the two
levels separately. INTERNAL (not exported).
EXPERIMENTAL — dense/validation-scale, supplied Gaussian/non-Gaussian families,
balanced/fully-observed `Y`. The R twin exposes only a bounded Poisson-log
three-trait, two-factor pedigree route through expert controls.
"""
struct GeneticGLLVMFit
    loglik::Float64
    genetic_covariance::Matrix{Float64}
    latent_structure::NamedTuple
    uniqueness::Union{Vector{Float64}, Nothing}
    beta::Matrix{Float64}
    breeding_values::Matrix{Float64}
    trait_names::Union{Vector{String}, Nothing}
    n_latent_factors::Int
    converged::Bool
    iterations::Int
    optimizer_converged::Bool
    mode_converged::Bool
    mode_gradient_norm::Float64
    mode_iterations::Int
    mode_stop_reason::Symbol
    mode_backtracks::Int
end

function _validate_gllvm_trait_names(trait_names, n_traits::Integer)
    trait_names === nothing && return nothing
    raw_names = collect(trait_names)
    all(name -> name isa AbstractString, raw_names) ||
        throw(ArgumentError("trait_names must contain strings"))
    names = String.(raw_names)
    length(names) == n_traits ||
        throw(ArgumentError("trait_names must have length $n_traits"))
    is_blank(name) = isempty(name) || all(
        c -> isspace(c) || c == '\u2028' || c == '\u2029', name,
    )
    all(name -> !is_blank(name), names) ||
        throw(ArgumentError("trait_names must be nonempty"))
    length(unique(names)) == n_traits ||
        throw(ArgumentError("trait_names must be unique"))
    return names
end

# Typed extractor methods — dispatch on GeneticGLLVMFit, distinct from the
# NamedTuple overloads in multivariate.jl and the AnimalModelFit overloads in
# likelihood.jl.

"""
    genetic_covariance(fit::GeneticGLLVMFit)

Return the estimated rotation-invariant among-trait genetic covariance `G_lat`
from a `GeneticGLLVMFit` (internal struct).
"""
genetic_covariance(fit::GeneticGLLVMFit) = fit.genetic_covariance

"""
    breeding_values(fit::GeneticGLLVMFit)

Return the `q × T` trait genetic conditional modes on the link scale from a
`GeneticGLLVMFit` (internal struct). These combine common factors and, for
factor-analytic fits, trait-specific genetic modes. They are invariant to an
orthogonal rotation of the common factors; they are not posterior means.
"""
breeding_values(fit::GeneticGLLVMFit) = fit.breeding_values

"""
    latent_structure(fit::GeneticGLLVMFit)

Return the `genetic_gllvm_descriptors` NamedTuple (rotation-invariant latent-
structure descriptors including `communality`, `genetic_pca`, `g_max`, etc.)
from a `GeneticGLLVMFit` (internal struct).
"""
latent_structure(fit::GeneticGLLVMFit) = fit.latent_structure

"""
    loglik(fit::GeneticGLLVMFit)

Return the Laplace approximation to the objective that integrates both fixed
effects (under flat measure) and genetic modes from a `GeneticGLLVMFit`.
Only its Gaussian reduction is REML; this is not ordinary non-Gaussian ML.
"""
loglik(fit::GeneticGLLVMFit) = fit.loglik

function _gllvm_trait_effects(modes::AbstractMatrix, loadings::AbstractMatrix,
                              uniqueness::Union{Nothing,AbstractVector})
    _, nmodes = size(modes)
    T, K = size(loadings)
    expected_modes = uniqueness === nothing ? K : K + T
    nmodes == expected_modes || throw(DimensionMismatch(
        "latent mode matrix has $nmodes columns; expected $expected_modes for $K factors and $T traits"))
    F = @view modes[:, 1:K]
    U = Matrix(F * transpose(loadings))
    if uniqueness !== nothing
        length(uniqueness) == T || throw(DimensionMismatch(
            "uniqueness has length $(length(uniqueness)); expected $T"))
        D = @view modes[:, (K + 1):(K + T)]
        U .+= D * Diagonal(sqrt.(uniqueness))
    end
    return U
end

"""
    fit_gllvm_laplace_reml(Y, Ainv, family; rank, structure = :lowrank, X = ones(size(Y,1), 1),
                           initial = nothing, initial_uniqueness = nothing,
                           trait_names = nothing, ...)

Genetic-GLLVM integrated-Laplace fitting (#50 slice 3): ESTIMATE the rank-`K` latent loadings `Λ` (`T×K`) by
maximizing the K-factor fixed-and-genetic-effect integrated objective [`gllvm_laplace_marginal_loglik`](@ref) over
the loadings (NelderMead). The among-trait genetic covariance is `G_lat = ΛΛ'`
(`structure = :lowrank`) or `G_lat = ΛΛ' + diag(Ψ)` (`structure = :factor_analytic`,
adding a per-trait specific genetic variance `Ψ > 0` — fitted on the `log` scale). The
FA structure is fitted by augmenting the loadings to `[Λ | diag(√Ψ)]` (so
`G_lat = ΛΛ' + diag(Ψ)`) and reusing the marginal unchanged. The marginal depends on
the loadings only through `G_lat`, so it is ROTATION-INVARIANT; the returned
`genetic_covariance` / `latent_structure` / `uniqueness` are unchanged by a
rotation of the common factors. Rotation invariance does not by itself identify
the FA decomposition or `Ψ`; the raw `Λ̂` is an arbitrary point on the rotation
manifold and is not reported as an identified biological axis. Returns a
`GeneticGLLVMFit` (internal struct) with fields `loglik`,
`genetic_covariance`, `latent_structure`, `uniqueness`, `beta (p×T)`,
`breeding_values (q×T trait conditional modes)`, optional `trait_names` in the
input-column order, `n_latent_factors`, `converged`,
`iterations`; typed extractor methods `genetic_covariance(fit)`,
`breeding_values(fit)`, `latent_structure(fit)`, and `loglik(fit)` are
defined on `GeneticGLLVMFit`.

**Per-trait families:** `family` may be a single `ResponseFamily` (applied uniformly
to all trait columns) or a length-`T` `Vector` of `ResponseFamily`s (one per trait
column of `Y`) — e.g. `[PoissonResponse(), GaussianResponse(1.0)]` for a count first
trait and a continuous second trait. The scalar path is numerically unchanged: a
uniform vector of `T` identical families gives the same objective value as the
corresponding scalar family. The vector length must equal `T = size(Y, 2)`; a
mismatch is detected at the marginal call.

For a `GaussianResponse(σ²e)` the residual is the FIXED scalar `σ²e` (not estimated);
the non-Gaussian families have no residual. The `K = 1, T = 1` Poisson `:lowrank` case
reduces to the single-factor [`fit_laplace_reml`](@ref) (`σ²a = λ̂²`). EXPERIMENTAL,
dense/validation-scale, balanced/fully-observed `Y`; INTERNAL (not exported). NOT a
general recovery or calibration claim (the opt-in study covers particular complete-data
cells, and the multivariate Gaussian FA gate covers one T=4,K=1 cell). The R
twin's bounded Poisson bridge does not extend this Julia fitter to other public
families, ranks, missing records, or response-scale summaries.
Per-record varying-trial `BinomialVectorResponse` is rejected before optimization;
use the standalone scalar animal-model path for varying trials.
"""
function fit_gllvm_laplace_reml(Y::AbstractMatrix, Ainv::AbstractMatrix,
                                family::Union{ResponseFamily, AbstractVector}; rank::Integer,
                                structure::Symbol = :lowrank,
                                X::AbstractMatrix = ones(size(Y, 1), 1),
                                initial = nothing, initial_uniqueness = nothing,
                                trait_names = nothing,
                                iterations::Integer = 1000,
                                tol::Real = 1e-10, maxiter::Integer = 200)
    _check_gllvm_record_family(family)
    Y, X = _check_gllvm_mode_inputs(Y, X, family, tol, maxiter)
    q, T = size(Y)
    trait_names = _validate_gllvm_trait_names(trait_names, T)
    Ainv = _check_relationship_precision(Ainv, q)
    K = Int(rank)
    K >= 1 || throw(ArgumentError("rank must be ≥ 1"))
    structure in (:lowrank, :factor_analytic) ||
        throw(ArgumentError("structure must be :lowrank or :factor_analytic"))
    Λ0 = if initial === nothing
        L = fill(0.2, T, K)
        for d in 1:min(T, K)
            L[d, d] = 0.5
        end
        L
    else
        Matrix{Float64}(initial)
    end
    size(Λ0) == (T, K) || throw(ArgumentError("initial loadings must be T×K = $((T, K))"))
    all(isfinite, Λ0) || throw(ArgumentError("initial loadings must be finite"))
    nλ = T * K

    # Build the (possibly Ψ-augmented) loadings from the optimizer parameters.
    function augment(params)
        all(isfinite, params) || throw(GLLVMInvalidParameterEvaluationError(
            "genetic GLLVM optimizer parameters became non-finite"))
        Λ = structure == :factor_analytic ?
            hcat(reshape(@view(params[1:nλ]), T, K), Matrix(Diagonal(sqrt.(exp.(@view(params[(nλ + 1):(nλ + T)])))))) :
            reshape(params, T, K)
        all(isfinite, Λ) || throw(GLLVMInvalidParameterEvaluationError(
            "genetic GLLVM trial loadings became non-finite"))
        return Λ
    end
    function negloglik(params)
        m = try
            gllvm_laplace_marginal_loglik(Y, Ainv, augment(params), family;
                                          X = X, tol = tol, maxiter = maxiter)
        catch err
            err isa GLLVMParameterEvaluationError || rethrow()
            return Inf
        end
        return (m.converged && isfinite(m.loglik)) ? -m.loglik : Inf
    end

    params0 = if structure == :factor_analytic
        ψ0 = initial_uniqueness === nothing ? fill(0.1, T) : Float64.(collect(initial_uniqueness))
        (length(ψ0) == T && all(isfinite, ψ0) && all(>(0), ψ0)) ||
            throw(ArgumentError("initial_uniqueness must be a finite positive length-$T vector"))
        vcat(vec(Λ0), log.(ψ0))
    else
        vec(Λ0)
    end
    res = optimize(negloglik, params0, NelderMead(), Optim.Options(iterations = iterations))
    phat = Optim.minimizer(res)
    Λhat = reshape(phat[1:nλ], T, K)
    ψhat = structure == :factor_analytic ? exp.(phat[(nλ + 1):(nλ + T)]) : nothing
    mhat = gllvm_laplace_marginal_loglik(Y, Ainv, augment(phat), family; X = X, tol = tol, maxiter = maxiter)
    mhat.converged && isfinite(mhat.loglik) || throw(GLLVMInvalidParameterEvaluationError(
        "genetic GLLVM optimizer did not return a finite converged inner mode"))
    Glat = ψhat === nothing ? Λhat * transpose(Λhat) : Λhat * transpose(Λhat) + Diagonal(ψhat)
    descr = ψhat === nothing ? genetic_gllvm_descriptors(Λhat) :
        genetic_gllvm_descriptors(Λhat; uniqueness = ψhat)
    return GeneticGLLVMFit(
        mhat.loglik,
        Matrix(Glat),
        descr,
        ψhat,
        mhat.beta,
        _gllvm_trait_effects(mhat.g, Λhat, ψhat),
        trait_names,
        K,
        Optim.converged(res) && mhat.converged,
        Optim.iterations(res),
        Optim.converged(res),
        mhat.converged,
        mhat.gradient_norm,
        mhat.iterations,
        mhat.stop_reason,
        mhat.backtracks,
    )
end
