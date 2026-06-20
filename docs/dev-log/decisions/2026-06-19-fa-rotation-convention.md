# Decision — Factor-analytic / low-rank loading rotation & interpretation convention

Date: 2026-06-19. Lane: Julia engine (`HSquared.jl`). Ratified by: Ada
(integrator), from a converged two-lens proposal (Fisher — inference/
identifiability; Kirkpatrick — factor-analytic / reduced-rank genetic covariance).
Supersedes the deferral in
`docs/dev-log/decisions/2026-06-14-loading-rotation-identifiability.md`.

Status: **decided (engine convention).** Bridging any structured-fit quantity is
**gated on joint R-lane ratification** (AGENTS.md rule 2) — see "Cross-lane".

## Problem

`fit_multivariate_reml(...; genetic_structure = :lowrank | :factor_analytic,
rank = K)` returns genetic loadings `Λ`. The genetic covariance
`G = ΛΛ′` (`:lowrank`) or `G = ΛΛ′ + Ψ` (`:factor_analytic`) is **invariant** under
`Λ → ΛQ` for any orthogonal `Q` (`K×K`). So the raw loadings are
**rotation-nonidentified**: the likelihood is exactly flat along the rotation
orbit, the observed information for the loading parameters is singular (null space
of dimension `K(K−1)/2`), and individual loadings have **no finite asymptotic
standard error**. Today `multivariate_result_payload` rejects `:lowrank`/
`:factor_analytic` and structured SEs are withheld, which blocks the #42 lowrank/fa
bridge exposure.

## Decision

**Adopt convention (a)+(b-invariant): bridge and do inference ONLY on
rotation-invariant functionals of `G`; never bridge raw loadings `Λ`.**

The reported "what the loadings point at" is the **eigenstructure of the fitted
`G`** (the Kirkpatrick & Meyer reduced-rank / principal-component representation),
which is rotation-invariant and is already the package's language: `genetic_pca(G)`
and `g_max(G)` (shipped in #55) return the descending, sign-canonicalized
eigenpairs of `G`.

### Exposable (rotation-invariant; identified)

- `G` itself (`genetic_covariance`), `diag(G)` (per-trait genetic variances),
  total genetic variance `tr(G)`.
- Genetic **eigenvalues** (`genetic_pca(G).values`, descending) = additive genetic
  variance along each genetic principal axis; `g_max` (leading eigenpair).
- Genetic **principal axes** (`genetic_pca(G).vectors`, sign-canonicalized) — the
  rotation-invariant "loadings on the principal axes".
- Evolvability family (`evolvability`/`conditional_evolvability`/`respondability`/
  `autonomy`/`mean_evolvability`) — already test-pinned rotation-invariant (#55).
- Genetic / residual correlation matrices; per-trait `h²`.
- `Ψ` (uniquenesses, `:factor_analytic` only — identified given fixed rank `K`).
- `rank K`, `genetic_structure`, `n_genetic_params` (for nested-structure LRTs),
  `loglik`.
- Standard errors / intervals **only** on the above invariants (G elements, `h²`,
  correlations, eigenvalues) via the existing observed-information + delta-method
  path used for the unstructured fit.

### Withheld (rotation-arbitrary / non-estimable)

- Raw loadings `Λ` as an identified estimate (only ever as an explicitly-flagged,
  rotation-arbitrary, point-estimate-only reconstruction `Λ = U·√Λ_eig` for display
  / comparator alignment — never across the bridge as biological axes).
- SEs / CIs / tests on any loading element `Λ[i,k]`.
- SEs / CIs on any individual eigenvector / genetic principal **direction** —
  especially under near-degenerate eigenvalues, where the axis is span-ambiguous
  and any nominal direction SE diverges (`genetic_pca` already warns).
- "this factor loads on traits X, Y" interpretive claims as if a factor were
  identified; varimax/oblimin/target-rotated loadings as identified or
  comparator-parity quantities.

## Why (not the alternatives)

- **(c) varimax/oblimin** replaces one arbitrary `Q` with another
  (criterion-dependent) and is scale-sensitive — strictly worse for honesty.
- **(d) lower-triangular / positive-diagonal (Anderson–Rubin/Cholesky)** pins a
  unique representative and even admits SEs on its free elements, but those SEs
  describe an arbitrary anchoring (trait order / anchor trait) routinely misread as
  "loading uncertainty"; the identified content is still only `G` and its invariants.
- The estimand is `G` (and, for FA, the pair (column-space of `Λ`, `Ψ`)), not `Λ`.
  Every reported number and every SE should be a function of `G` that is constant on
  the rotation orbit. Precedent: **Kirkpatrick & Meyer (2004, *Genetics*)**
  reduced-rank / principal-component estimation of `G` (WOMBAT; ASReml `xfa`), where
  the reported, interpreted object is the eigenstructure of `G`.

## Identifiability guarantee (one line)

> We do inference on `G` and its rotation-invariant functions; loadings and
> individual genetic axes are reported as point estimates only and carry no
> uncertainty quantification.

## Cross-lane (gated; AGENTS.md rule 2)

This widens the shared bridge contract, so it must be ratified jointly **before any
structured-fit field is bridged**. Coordinate on **#42 ↔ R #7** (cross-ref #37
em_fa warm-start, #55 evolvability — already landed). Proposed engine change once
ratified: widen `multivariate_result_payload` to ACCEPT `:lowrank`/
`:factor_analytic` and expose the **eigenbasis + invariants** above (NOT loadings).
Holding the engine change until the R lane acks on #61/#42.

## Consequences / follow-ups

- No code change in this slice — it records the convention. The exposable
  invariants already exist (`genetic_pca`/`g_max`/evolvability from #55;
  `genetic_covariance`/correlations/`h²`/`Ψ` from the multivariate fit).
- Unblocks #42 (lowrank/fa exposure, via the eigenbasis) and #55 (already aligned).
- Next engine step (post-ratification): the eigenbasis bridge payload + structured-
  fit SEs on invariants only.
