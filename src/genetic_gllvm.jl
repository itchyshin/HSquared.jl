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
