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
