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
`Λ → ΛQ` for any orthogonal `Q` (`K×K`). So raw loadings do not have a
unique orientation. For full-column-rank `Λ` and `K > 1`, the likelihood is
flat along a continuous rotation orbit of dimension `K(K−1)/2`, and the
unconstrained loading information is singular. For `K = 1` the ambiguity is
the discrete global sign: local loading identification may hold after a sign
choice, but that choice is not a biological axis. Rotation invariance alone
does **not** identify `Ψ` or establish regular inference on `G`. Today
`multivariate_result_payload` rejects `:lowrank`/
`:factor_analytic` and structured SEs are withheld, which blocks the #42 lowrank/fa
bridge exposure.

## Decision

**Adopt convention (a)+(b-invariant): restrict proposed bridge quantities and
inference targets to rotation-invariant covariance quantities; never bridge
raw loadings `Λ`.** An invariant is eligible for estimation, not automatically
identified or inferentially calibrated.

The orientation-free covariance summary is the **eigenstructure of the fitted
`G`** (the Kirkpatrick & Meyer reduced-rank / principal-component representation),
which is rotation-invariant and is already the package's language: `genetic_pca(G)`
and `g_max(G)` (shipped in #55) return the descending, sign-canonicalized
eigenpairs of `G`.

### Candidate quantities (rotation-invariant; identification is conditional)

- `G` itself (`genetic_covariance`), `diag(G)` (per-trait genetic variances),
  total genetic variance `tr(G)`.
- Genetic **eigenvalues** (`genetic_pca(G).values`, descending) = additive genetic
  variance along each genetic principal axis; `g_max` (leading eigenpair).
- Genetic **principal axes** (`genetic_pca(G).vectors`, sign-canonicalized) —
  determined by `G` when the relevant eigenvalues are distinct; repeated
  eigenvalues identify only a subspace.
- Evolvability family (`evolvability`/`conditional_evolvability`/`respondability`/
  `autonomy`/`mean_evolvability`) — already test-pinned rotation-invariant (#55).
- Genetic / residual correlation matrices; per-trait `h²`.
- `Ψ` (uniquenesses, `:factor_analytic` only) is unchanged by a rotation of
  `Λ`, but need not be identifiable from `G`. Fixed `K` and positive
  Ledermann slack alone do not settle this; see the four-trait rank-one
  Jacobian and counterexample in `docs/design/fa-t4k1-identifiability-and-units.md`.
- `rank K`, `genetic_structure`, `n_genetic_params` (a nominal generic
  dimension count for nested-structure LRTs),
  `loglik`.
- Standard errors / intervals on the above covariance quantities require
  local identification, interiority, and a nonsingular information matrix;
  the existing observed-information + delta-method path is validated for the
  unstructured fit and is **not** a structured-fit SE implementation.

### Withheld (rotation-arbitrary / non-estimable)

- Raw loadings `Λ` as an identified biological axis. An eigenbasis display
  `U·√diag(eigenvalues)` represents `G` itself for a low-rank covariance;
  for FA it is **not** the fitted loading matrix because `G` also contains
  `Ψ`. Such a display must be labelled as a covariance reconstruction, never
  bridged as FA loadings or used as comparator loading parity.
- SEs / CIs / tests on raw loading elements as biological axes. A sign or
  rotation constraint can create a local coordinate system, but does not make
  its chosen orientation biologically unique.
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
  "loading uncertainty"; the primary covariance target remains `G`, with
  `Ψ` a separate target only where the decomposition is identifiable.
- The primary covariance estimand is `G`, not an arbitrary orientation of
  `Λ`. The FA decomposition `(ΛΛ′, Ψ)` is a further estimand only where that
  decomposition is identifiable from `G`; `Ψ` is not universally a function
  of `G`. Precedent: **Kirkpatrick & Meyer (2004, *Genetics*)**
  reduced-rank / principal-component estimation of `G` (WOMBAT; ASReml `xfa`), where
  the reported, interpreted object is the eigenstructure of `G`.

## Identification boundary (one line)

> Rotation invariance removes orientation ambiguity; it does not by itself
> identify the FA decomposition or justify covariance, uniqueness, or LRT
> uncertainty. Check the local rank and the model's information separately.

## Cross-lane (gated; AGENTS.md rule 2)

This widens the shared public bridge contract, so it must be ratified jointly
**before any structured-fit field is activated in the R lane**. Coordinate
on **#42 ↔ R #7** (cross-ref #37 em_fa warm-start, #55 evolvability).
The Julia helper `structured_genetic_payload` now exists, but its presence
does not activate an R model specification or establish inference on `Ψ`.

## Consequences / follow-ups

- This 2026-09-27 correction narrows the 2026-06-19 convention's unconditional
  identification and LRT language; it does not authorize R activation or a
  new capability claim. The candidate covariance summaries already exist
  (`genetic_pca`/`g_max`/evolvability from #55;
  `genetic_covariance`/correlations/`h²`/`Ψ` from the multivariate fit).
- Supplies an interpretation constraint for #42 if its cell-specific
  identification, result-parity, and validation gates pass; #55 is already
  aligned. The eigenbasis of full `G` is not fitted FA loadings.
- A future structured-fit SE or LRT claim needs a cell-specific local-rank,
  floor-distance, information, and calibration check before bridge exposure.
