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

DESCRIPTIVE, supplied-covariance only: `Λ`/`Ψ` are NOT estimated, there is no
marginal / likelihood / fit, no R model-spec or bridge payload, and only
rotation-INVARIANT functionals of `Σ_g` are returned — never the raw loadings `Λ`
(which are rotation-nonidentified). For any orthogonal `Q`, `Λ → ΛQ` leaves every
returned quantity invariant (the `genetic_pca` eigenvectors up to sign). Guards
(dimension / positivity / rank) are delegated to [`lowrank_covariance`](@ref) and
[`factor_analytic_covariance`](@ref). The first foundation step of the genetic
GLLVM (#50); the supplied-covariance latent marginal and REML estimation are later
slices.
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
IDENTIFIED, rotation-invariant genetic covariance `G = result.genetic_covariance`
and uniqueness `Ψ` ([`genetic_uniqueness`](@ref); `nothing` ⇒ low-rank, `Ψ = 0`) —
NEVER the rotation-nonidentified loadings — and returns the same NamedTuple as the
supplied-loadings method, with `communality = 1 − Ψ / diag(G)` (the per-trait
fraction of genetic variance from the common latent factors; `= 1` for low-rank).
Rejects the rotation-free `:diagonal` / `:unstructured` structures, which have no
latent-factor interpretation.
"""
function genetic_gllvm_descriptors(result::NamedTuple)
    meta = genetic_structure(result)   # throws unless the fit carries structured metadata
    meta.structure in (:lowrank, :factor_analytic) || throw(ArgumentError(
        "genetic_gllvm_descriptors(result) needs a :lowrank or :factor_analytic fit; got :$(meta.structure)"))
    G = Matrix{Float64}(result.genetic_covariance)
    gv = diag(G)
    ψ = genetic_uniqueness(result)
    communality = ψ === nothing ? ones(length(gv)) : (gv .- ψ) ./ gv
    K = meta.rank
    return (genetic_covariance = G,
            genetic_variances = gv,
            genetic_correlation = genetic_correlation(G),
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
`g[·,k] ~ N(0, A)` makes the among-trait genetic covariance `G_lat = ΛΛ' (+ diag Ψ)`
and the trait-level breeding values `u[i,·] = Λ g[i,·]` satisfy
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

Laplace-approximate marginal log-likelihood of the **K-factor genetic GLLVM** with
SUPPLIED `T×K` loadings `Λ`. The latent field `vec(g) ~ N(0, I_K ⊗ A)` (`A⁻¹ = Ainv`)
enters `η[i,t] = (Xβ)[i,t] + Σ_k Λ[t,k] g[i,k]` and `y[i,t] | η[i,t] ~ family`
(a `ResponseFamily` or a length-`T` `Vector` of `ResponseFamily`s — one per trait column
of `Y`); `β` is integrated under a flat prior. `Y` is the `q×T` response matrix
(balanced, fully observed); `X` is the `q×p` individual-level fixed-effect design
(per-trait coefficients; default per-trait intercept). Returns
`(loglik, beta (p×T), g (q×K), converged, gradient_norm, iterations)`.

**Per-trait families:** pass a `Vector` of `T` `ResponseFamily` objects to apply a
different family to each trait column of `Y` — e.g.
`[PoissonResponse(), GaussianResponse(1.0)]` for a count first trait and a continuous
second trait. Passing a single `ResponseFamily` (the original call form) applies it
uniformly to all traits; a uniform `Vector` of `T` identical families gives numerically
IDENTICAL results to the scalar path (the per-record dispatch is the same). The vector
length must equal `T = size(Y, 2)`; a mismatch throws `ArgumentError`. Per-trait
`_check_counts` is run per column against its own family before the Newton loop.

Generalizes [`laplace_marginal_loglik`](@ref) (the `K = 1` single-factor case, to
which it reduces EXACTLY, the Laplace approximation being invariant under the affine
latent reparameterization). For a `GaussianResponse` it is EXACT and equals the
multivariate REML marginal at `G0 = ΛΛ'`, `R0 = σ²e·I`. `G_lat = ΛΛ'` need NOT be
positive definite (`P = I_K ⊗ Ainv` is full-rank regardless), so `K < T` /
`K > T` / a singular `ΛΛ'` are all handled — unlike the Gaussian-MME path
([`genetic_gllvm_gaussian_mme`](@ref)), which requires a PD `G_lat`. The convergence
flag lags the mode by one Newton step (as in the single-factor kernel), so an exact
Gaussian solve needs `maxiter ≥ 2`. EXPERIMENTAL, dense / validation-scale, SUPPLIED
loadings (NOT estimated — slice 3 REML), balanced/fully-observed `Y` only; INTERNAL
(not exported, mirroring the single-factor kernel), no R model-spec.
"""
function gllvm_laplace_marginal_loglik(Y::AbstractMatrix, Ainv::AbstractMatrix,
                                       loadings::AbstractMatrix,
                                       family::Union{ResponseFamily, AbstractVector};
                                       X::AbstractMatrix = ones(size(Y, 1), 1),
                                       tol::Real = 1e-10, maxiter::Integer = 100)
    Yd = Matrix{Float64}(Y)
    Ai = Matrix{Float64}(Ainv)
    Λ = Matrix{Float64}(loadings)
    Xd = Matrix{Float64}(X)
    q, T = size(Yd)
    size(Ai, 1) == q == size(Ai, 2) || throw(ArgumentError("Ainv must be q×q with q = size(Y,1)"))
    size(Λ, 1) == T || throw(ArgumentError("loadings must have T = size(Y,2) rows"))
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
    _loglik_r(r, y, η) = fam_of_r === nothing ? _fam_loglik(family, y, η) : _fam_loglik(fam_of_r[r], y, η)

    # latent prior precision P = I_K ⊗ Ainv (block diagonal, K blocks of Ainv)
    P = zeros(q * K, q * K)
    for k in 1:K
        rngk = ((k - 1) * q + 1):(k * q)
        P[rngk, rngk] .= Ai
    end

    pβ = p * T
    β = zeros(pβ)
    g = zeros(q * K)
    gnorm = Inf
    iters = 0
    converged = false
    local H
    for it in 1:maxiter
        iters = it
        η = Xrec * β .+ W * g
        s = [_score(i, yv[i], η[i]) for i in 1:n]
        w = [_weight(i, yv[i], η[i]) for i in 1:n]
        grad = vcat(transpose(Xrec) * s, transpose(W) * s .- P * g)
        gnorm = norm(grad)
        WX = w .* Xrec
        WW = w .* W
        H = [transpose(Xrec)*WX  transpose(Xrec)*WW
             transpose(W)*WX     (transpose(W)*WW .+ P)]
        step = Symmetric(H) \ grad
        β .+= step[1:pβ]
        g .+= step[(pβ + 1):end]
        if gnorm < tol
            converged = true
            break
        end
    end

    η = Xrec * β .+ W * g
    w = [_weight(i, yv[i], η[i]) for i in 1:n]
    WX = w .* Xrec
    WW = w .* W
    H = [transpose(Xrec)*WX  transpose(Xrec)*WW
         transpose(W)*WX     (transpose(W)*WW .+ P)]
    cond = sum(_loglik_r(i, yv[i], η[i]) for i in 1:n)
    quad_g = dot(g, P * g)
    logdet_Ainv = logdet(cholesky(Symmetric(Ai)))
    logdet_H = logdet(cholesky(Symmetric(H)))
    loglik = cond - 0.5 * quad_g + 0.5 * K * logdet_Ainv + 0.5 * pβ * log(2π) - 0.5 * logdet_H
    return (loglik = converged ? loglik : NaN,
            beta = reshape(β, p, T),     # p×T (trait-major β reshapes to columns = traits)
            g = reshape(g, q, K),        # q×K
            converged = converged, gradient_norm = gnorm, iterations = iters)
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
the same nine fields as the former bare `NamedTuple` return and exposes typed
extractor methods:

- `genetic_covariance(fit)` — the rotation-invariant `G_lat` matrix
- `breeding_values(fit)`    — `q × K` common-factor EBV scores
- `latent_structure(fit)`   — the `genetic_gllvm_descriptors` NamedTuple
- `loglik(fit)`             — the Laplace marginal log-likelihood at the optimum

All other fields (`uniqueness`, `beta`, `n_latent_factors`, `converged`,
`iterations`) are accessible via `fit.fieldname`. INTERNAL (not exported).
EXPERIMENTAL — dense/validation-scale, supplied Gaussian/non-Gaussian families,
balanced/fully-observed `Y`, no R model-spec or bridge payload.
"""
struct GeneticGLLVMFit
    loglik::Float64
    genetic_covariance::Matrix{Float64}
    latent_structure::NamedTuple
    uniqueness::Union{Vector{Float64}, Nothing}
    beta::Matrix{Float64}
    breeding_values::Matrix{Float64}
    n_latent_factors::Int
    converged::Bool
    iterations::Int
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

Return the `q × K` matrix of common-factor breeding-value scores (the Newton
mode of `vec(g)`, reshaped) from a `GeneticGLLVMFit` (internal struct).
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

Return the Laplace-approximate marginal log-likelihood at the REML optimum
from a `GeneticGLLVMFit` (internal struct).
"""
loglik(fit::GeneticGLLVMFit) = fit.loglik

"""
    fit_gllvm_laplace_reml(Y, Ainv, family; rank, structure = :lowrank, X = ones(size(Y,1), 1),
                           initial = nothing, initial_uniqueness = nothing, ...)

Genetic-GLLVM REML (#50 slice 3): ESTIMATE the rank-`K` latent loadings `Λ` (`T×K`) by
maximizing the K-factor Laplace marginal [`gllvm_laplace_marginal_loglik`](@ref) over
the loadings (NelderMead). The among-trait genetic covariance is `G_lat = ΛΛ'`
(`structure = :lowrank`) or `G_lat = ΛΛ' + diag(Ψ)` (`structure = :factor_analytic`,
adding a per-trait specific genetic variance `Ψ > 0` — fitted on the `log` scale). The
FA structure is fitted by augmenting the loadings to `[Λ | diag(√Ψ)]` (so
`G_lat = ΛΛ' + diag(Ψ)`) and reusing the marginal unchanged. The marginal depends on
the loadings only through `G_lat`, so it is ROTATION-INVARIANT; the returned
`genetic_covariance` / `latent_structure` / `uniqueness` are the rotation-invariant
functionals (the raw `Λ̂` is an arbitrary point on the rotation manifold, NOT reported
as identified). Returns a `GeneticGLLVMFit` (internal struct) with fields `loglik`,
`genetic_covariance`, `latent_structure`, `uniqueness`, `beta (p×T)`,
`breeding_values (q×K common-factor scores)`, `n_latent_factors`, `converged`,
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
known-truth recovery claim (structured non-Gaussian REML recovery is a separate opt-in
study, and the multivariate FA recovery has not passed); no R model-spec or bridge payload.
"""
function fit_gllvm_laplace_reml(Y::AbstractMatrix, Ainv::AbstractMatrix,
                                family::Union{ResponseFamily, AbstractVector}; rank::Integer,
                                structure::Symbol = :lowrank,
                                X::AbstractMatrix = ones(size(Y, 1), 1),
                                initial = nothing, initial_uniqueness = nothing,
                                iterations::Integer = 1000,
                                tol::Real = 1e-10, maxiter::Integer = 200)
    q, T = size(Y)
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
    nλ = T * K

    # Build the (possibly Ψ-augmented) loadings from the optimizer parameters.
    augment(params) = structure == :factor_analytic ?
        hcat(reshape(@view(params[1:nλ]), T, K), Matrix(Diagonal(sqrt.(exp.(@view(params[(nλ + 1):(nλ + T)])))))) :
        reshape(params, T, K)
    function negloglik(params)
        m = gllvm_laplace_marginal_loglik(Y, Ainv, augment(params), family;
                                          X = X, tol = tol, maxiter = maxiter)
        return (m.converged && isfinite(m.loglik)) ? -m.loglik : Inf
    end

    params0 = if structure == :factor_analytic
        ψ0 = initial_uniqueness === nothing ? fill(0.1, T) : Float64.(collect(initial_uniqueness))
        (length(ψ0) == T && all(>(0), ψ0)) ||
            throw(ArgumentError("initial_uniqueness must be a positive length-$T vector"))
        vcat(vec(Λ0), log.(ψ0))
    else
        vec(Λ0)
    end
    res = optimize(negloglik, params0, NelderMead(), Optim.Options(iterations = iterations))
    phat = Optim.minimizer(res)
    Λhat = reshape(phat[1:nλ], T, K)
    ψhat = structure == :factor_analytic ? exp.(phat[(nλ + 1):(nλ + T)]) : nothing
    mhat = gllvm_laplace_marginal_loglik(Y, Ainv, augment(phat), family; X = X, tol = tol, maxiter = maxiter)
    Glat = ψhat === nothing ? Λhat * transpose(Λhat) : Λhat * transpose(Λhat) + Diagonal(ψhat)
    descr = ψhat === nothing ? genetic_gllvm_descriptors(Λhat) :
        genetic_gllvm_descriptors(Λhat; uniqueness = ψhat)
    return GeneticGLLVMFit(
        mhat.loglik,
        Matrix(Glat),
        descr,
        ψhat,
        mhat.beta,
        mhat.g[:, 1:K],   # the K common-factor scores
        K,
        Optim.converged(res) && mhat.converged,
        Optim.iterations(res),
    )
end
