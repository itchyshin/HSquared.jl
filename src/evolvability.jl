# Evolvability / G-matrix geometry (Hansen & Houle 2008, J. Evol. Biol.).
#
# Descriptive linear-algebra tools on a genetic (co)variance matrix G: the
# additive genetic variance available in a direction (evolvability), the variance
# available once other traits are held at their conditional optimum (conditional
# evolvability), the response magnitude to a unit gradient (respondability), the
# fraction of evolvability that is autonomous of constraint (autonomy), the
# genetic principal axes (genetic_pca / g_max), and the genetic variance of an
# index. EXPERIMENTAL, validation-scale.
#
# These are functions of G itself, so they are ROTATION-INVARIANT — for a
# reduced-rank / factor-analytic fit, G = ΛΛ' (+Ψ) is identical for any orthogonal
# rotation Λ→ΛQ, so evolvability sidesteps the loading-rotation ambiguity that
# gates the structured bridge payload and structured SEs. They are descriptive
# geometry, NOT a selection-response prediction (no realized response without a
# real, unmodelled selection gradient) and NOT a fitting/estimation claim; metrics
# on an ESTIMATED G inherit all of fit_multivariate_reml's estimation caveats.
#
# Numerical conventions: the symmetry/PSD admissibility tolerances are
# SCALE-RELATIVE (so a large-variance G is not accepted with a meaningfully
# negative eigenvalue, nor a small-variance one wrongly rejected); positive-
# definiteness for the inverse-using metrics is checked by the scale-free
# `isposdef`; and the scalar variance metrics (evolvability, variance_along_gradient)
# are clamped at 0 so numerical roundoff on a near-singular but admissible G never
# yields a negative "variance".

# Pull G from either a bare matrix or a multivariate result NamedTuple.
_evolvability_G(G::AbstractMatrix) = G
_evolvability_G(result) = getproperty(result, :genetic_covariance)

# Square + symmetric + finite + PSD (allows rank-deficient G, e.g. lowrank ΛΛ').
# Tolerances are SCALE-RELATIVE (not absolute), so a large-variance G is not
# wrongly accepted with a meaningfully-negative eigenvalue, nor a small-variance
# one wrongly rejected.
function _check_symmetric_psd_G(G::AbstractMatrix)
    n = size(G, 1)
    size(G, 2) == n || throw(ArgumentError("G must be square"))
    Gf = Matrix{Float64}(G)
    all(isfinite, Gf) || throw(ArgumentError("G must contain only finite values"))
    gscale = max(1.0, maximum(abs, Gf))
    isapprox(Gf, transpose(Gf); atol = 1e-10 * gscale) ||
        throw(ArgumentError("G must be symmetric"))
    S = Symmetric(Gf)
    ev = eigvals(S)
    escale = max(1.0, maximum(abs, ev))
    minimum(ev) >= -1e-8 * escale ||
        throw(ArgumentError("G must be positive semidefinite"))
    return S
end

# Additionally positive-DEFINITE: required by the inverse-using metrics
# (conditional_evolvability, autonomy). A merely PSD (singular / reduced-rank) G
# makes G⁻¹ undefined, so those metrics must throw rather than silently regularize.
# Uses the scale-free `isposdef` (a Cholesky attempt), so a well-conditioned PD G
# at any scale is accepted and a singular one rejected.
function _check_symmetric_pd_G(G::AbstractMatrix)
    S = _check_symmetric_psd_G(G)
    isposdef(S) ||
        throw(ArgumentError("G must be positive definite for this metric (it inverts G); " *
                            "a singular / reduced-rank G has no conditional evolvability or autonomy"))
    return S
end

function _normalize_beta(beta::AbstractVector, t::Integer)
    length(beta) == t ||
        throw(ArgumentError("beta length ($(length(beta))) must match the number of traits ($t)"))
    b = Vector{Float64}(beta)
    all(isfinite, b) || throw(ArgumentError("beta must contain only finite values"))
    nrm = norm(b)
    nrm > 0 || throw(ArgumentError("beta must be a nonzero direction"))
    return b ./ nrm
end

"""
    evolvability(G, beta)

Hansen & Houle (2008) **evolvability** `e(β) = β̂ᵀ G β̂` — the additive genetic
variance available in the (unit-normalized) selection-gradient direction `β`. `G`
is a genetic covariance matrix (or a multivariate result, from which
`genetic_covariance` is read). PSD-safe (works on a reduced-rank `G`). Along an
eigenvector of `G` it equals that eigenvalue. Descriptive geometry, not a
predicted response; see the module note for caveats.
"""
function evolvability(G, beta)
    S = _check_symmetric_psd_G(_evolvability_G(G))
    b = _normalize_beta(beta, size(S, 1))
    return max(0.0, dot(b, S * b))   # a variance is non-negative; clamp numerical roundoff
end

"""
    conditional_evolvability(G, beta)

Hansen & Houle (2008) **conditional evolvability** `c(β) = 1 / (β̂ᵀ G⁻¹ β̂)` — the
genetic variance available in direction `β` when all other directions are held at
their conditional optima (i.e. under a constraint). Requires `G` positive
DEFINITE (it inverts `G`); a singular / reduced-rank `G` throws. Along an
eigenvector of `G` it equals that eigenvalue, and `c(β) ≤ e(β)` always.
"""
function conditional_evolvability(G, beta)
    S = _check_symmetric_pd_G(_evolvability_G(G))
    b = _normalize_beta(beta, size(S, 1))
    F = cholesky(S)
    return 1.0 / dot(b, F \ b)
end

"""
    respondability(G, beta)

Hansen & Houle (2008) **respondability** `r(β) = ‖G β̂‖` — the magnitude of the
evolutionary response to a unit selection gradient in direction `β`. PSD-safe.
Along an eigenvector of `G` it equals that (non-negative) eigenvalue.
"""
function respondability(G, beta)
    S = _check_symmetric_psd_G(_evolvability_G(G))
    b = _normalize_beta(beta, size(S, 1))
    return norm(S * b)
end

"""
    autonomy(G, beta)

Hansen & Houle (2008) **autonomy** `a(β) = c(β) / e(β) ∈ (0, 1]` — the fraction of
the evolvability in direction `β` that is autonomous of genetic constraint from
other traits. Requires `G` positive definite (via `conditional_evolvability`).
Along an eigenvector of `G` it equals `1`.
"""
function autonomy(G, beta)
    S = _check_symmetric_pd_G(_evolvability_G(G))   # PD required (validated once)
    b = _normalize_beta(beta, size(S, 1))
    e = dot(b, S * b)                # > 0 for a PD G, so no clamp / divide-by-zero
    c = 1.0 / dot(b, cholesky(S) \ b)
    return c / e
end

"""
    variance_along_gradient(G, beta; normalize = true)

Additive genetic variance of the linear index `βᵀ a`, `βᵀ G β`. With
`normalize = true` (default) `β` is scaled to unit length first, so this returns
[`evolvability`](@ref); with `normalize = false` it uses `β` as given (the raw
genetic variance of the index for an arbitrary contrast). PSD-safe.
"""
function variance_along_gradient(G, beta; normalize::Bool = true)
    S = _check_symmetric_psd_G(_evolvability_G(G))
    t = size(S, 1)
    if normalize
        b = _normalize_beta(beta, t)
    else
        length(beta) == t ||
            throw(ArgumentError("beta length ($(length(beta))) must match the number of traits ($t)"))
        b = Vector{Float64}(beta)
        all(isfinite, b) || throw(ArgumentError("beta must contain only finite values"))
    end
    return max(0.0, dot(b, S * b))   # a variance is non-negative; clamp numerical roundoff
end

# Deterministic sign canonicalization: make the largest-magnitude entry of each
# eigenvector positive, so genetic PCs are reproducible across runs/BLAS.
function _sign_canonicalize!(v::AbstractVector)
    k = argmax(abs.(v))
    if v[k] < 0
        v .= .-v
    end
    return v
end

"""
    genetic_pca(G)

Genetic principal-component decomposition of `G`. Returns
`(values, vectors)` with eigenvalues in DESCENDING order (the genetic variances
along the genetic principal axes / "genetic lines of least resistance") and the
corresponding eigenvectors as the columns of `vectors`, each deterministically
sign-canonicalized (largest-magnitude entry positive). PSD-safe. Under repeated
eigenvalues individual PCs are span-ambiguous — do not over-interpret beyond the
leading axis when eigenvalues are near-degenerate.
"""
function genetic_pca(G)
    S = _check_symmetric_psd_G(_evolvability_G(G))
    E = eigen(S)
    order = sortperm(E.values; rev = true)
    values = E.values[order]
    vectors = Matrix{Float64}(E.vectors[:, order])
    for j in axes(vectors, 2)
        _sign_canonicalize!(view(vectors, :, j))
    end
    return (values = values, vectors = vectors)
end

"""
    g_max(G)

Leading genetic principal axis of `G`: returns `(eigenvalue, eigenvector)` for the
largest eigenvalue — `g_max`, the direction of maximum additive genetic variance
("genetic line of least resistance"). The eigenvector is sign-canonicalized.
"""
function g_max(G)
    pca = genetic_pca(G)
    return (eigenvalue = pca.values[1], eigenvector = Vector{Float64}(pca.vectors[:, 1]))
end

"""
    mean_evolvability(G)

Mean (unconditional) evolvability — the average of `e(β)` over uniformly random
unit selection gradients, which has the exact closed form `tr(G) / t` (the mean
eigenvalue of `G`). PSD-safe, deterministic. The population-averaged conditional
evolvability and autonomy (Hansen & Houle "random skewers") have no comparable
simple closed form and are left to future work.
"""
function mean_evolvability(G)
    S = _check_symmetric_psd_G(_evolvability_G(G))
    return tr(S) / size(S, 1)
end
