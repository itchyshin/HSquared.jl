# 2026-06-19 Evolvability / G-matrix geometry (#55)

- Goal: deliver the planned innovation feature #55 — Julia-native Hansen & Houle
  (2008) evolvability metrics + genetic principal axes on a genetic covariance
  `G`. A clean SOLO, rotation-INVARIANT win (operates on `G`, not the loadings),
  so it is NOT blocked by the FA rotation convention that gates the structured
  bridge payload / structured SEs.
- Lenses: Kirkpatrick (G-matrix / evolvability), Noether + Gauss (math/numerics),
  Rose (claim gate). Spec authored by the Kirkpatrick lens; adversarial review run
  as a workflow.

## What was done

- New `src/evolvability.jl` (exported): `evolvability(G, β)`,
  `conditional_evolvability(G, β)`, `respondability(G, β)`, `autonomy(G, β)`,
  `variance_along_gradient(G, β; normalize)`, `genetic_pca(G)`, `g_max(G)`,
  `mean_evolvability(G)`. Each accepts a matrix or a multivariate result (reads
  `genetic_covariance`). Guards: `_check_symmetric_psd_G` (PSD-safe metrics) and
  `_check_symmetric_pd_G` (inverse-using `conditional_evolvability`/`autonomy`
  throw on a singular `G`); `_normalize_beta` (unit direction).
- `include("evolvability.jl")` after `multivariate.jl`; 8 exports added.
- Tests (`test/runtests.jl`, "Phase 4B evolvability / G-matrix geometry (#55)",
  61 assertions): diagonal-`G` identities, isotropic `G = cI` degeneracy,
  `[3 1; 1 3]` eigenstructure (e/c/r = eigenvalue along eigenvectors;
  `genetic_pca`/`g_max` recover descending sign-canonicalized eigenpairs),
  `mean_evolvability = tr(G)/t`, `c ≤ e`, EXPLICIT rotation-invariance
  `lowrank_covariance(L)` vs `lowrank_covariance(L*Q)`, NamedTuple convenience,
  and the full guard set (non-symmetric/non-square/indefinite/β-mismatch/zero-β,
  and singular-`G` → conditional/autonomy throw).
- Rows: capability-status (new "Evolvability / G-matrix geometry" row);
  validation-debt `V4-EVOLVE`; `validation_status()` `V4-EVOLVE` row (inserted in
  the V4 cluster so `validation[end]` stays `V6-LAPLACE`); count assertion 33 → 34.

## Commands / results

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed (exit 0)**
  (evolvability testset 61/61; re-run green after the `validation_status` row +
  count bump).
- `~/.juliaup/bin/julia --project=docs docs/make.jl` → **passed (exit 0)** (incl.
  the new `api.md` entries for the 8 exports).
- Adversarial 3-lens review (Kirkpatrick / Gauss / Rose): Kirkpatrick + Rose
  **pass_with_nits**, Gauss **concerns** (no blocker). All addressed before merge:
  - Gauss (should_fix): the PSD/PD guards used ABSOLUTE thresholds (scale-blind) —
    a large-variance `G` could pass with a meaningfully-negative eigenvalue, and a
    small-scale well-conditioned PD `G` was wrongly rejected. Now: scale-RELATIVE
    symmetry/PSD tolerances, scale-free `isposdef` for the PD guard, and the scalar
    variance metrics clamped at 0. New tests: large-scale indefinite throws,
    tiny-scale PD accepted, numerically-PSD returns clamped ≥ 0.
  - Kirkpatrick (should_fix): the 8 exports were missing from `docs/src/api.md`
    (`warnonly=true` masked it) — added.
  - Kirkpatrick (nits): `autonomy` validated `G` twice → refactored to validate
    once; matrix-of-gradients overload + mean respondability noted as deferred in
    the `V4-EVOLVE` debt row; PSD-tolerance behavior documented in the module note.

## Claim boundary

Descriptive G-matrix geometry only. Rotation-invariant (functions of `G`, not the
loadings). NOT a selection-response prediction and NOT a fitting/estimation claim;
metrics on an estimated `G` inherit `fit_multivariate_reml`'s caveats. No external
(evolqg / Hansen worked-example) comparator yet. No capability moved to covered.
