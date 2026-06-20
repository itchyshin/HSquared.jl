# 2026-06-20 Random-regression covariance-function descriptors (#54, slice 1)

- Goal: start the planned random regression / reaction-norm capability (#54) with a
  bounded, descriptive, supplied-covariance first slice — the function-valued
  analogue of the evolvability descriptors, mirroring how the multivariate lane
  began (descriptors on a supplied G before any estimation).
- Lenses: Henderson + Falconer + Curie scoped it (parallel design workflow; the two
  returned designs converged on the supplied-covariance-first approach). Falconer's
  descriptive slice chosen as slice 1; Henderson's MME = slice 2 (design note).

## What was done

- New `src/random_regression.jl` (exported): `legendre_basis(t, order)` (normalized
  Legendre, orthonormal on `[-1,1]`), `standardize_covariate(a; lower, upper)`, and
  supplied-`K_g` descriptors `rr_genetic_variance`, `rr_genetic_covariance_surface`,
  `rr_genetic_correlation_surface` (reuses `genetic_correlation`), `rr_heritability`
  (supplied scalar or per-point residual). Included after `evolvability.jl`; reuses
  the `_check_symmetric_psd_G` guard.
- Tests (`test/runtests.jl`, "Phase 3 random-regression covariance-function
  descriptors (#54)", 31 assertions): `φ` closed forms at `t = -1,0,1`, trapezoid
  orthonormality, `standardize_covariate` endpoints, the documented Kirkpatrick/Meyer
  fixture numbers (`v_g ≈ [0.8431, 0.4597, 0.625, 0.9309, 2.6569]`, `ρ_g(-1,+1) ≈
  0.167`, `h² ≈ [0.678, …, 0.869]`), `v_g == diag(surface)`, `K_g = I ⇒ v_g = ‖φ‖²`,
  PSD inheritance, correlation diagonal = 1 / equals `genetic_correlation`,
  heteroscedastic-residual `h²`, and the guard set.
- api.md entries for the 6 new exports (cross-`@ref`s resolve). capability-status +
  validation-debt `V3-RR-DESC` rows. Design note with the slice roadmap.

## Commands / results

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed (exit 0)**
  (RR testset 31/31; the convention-lock fixture numbers match the DOCUMENTED
  ASReml/WOMBAT normalized-Legendre convention — convention-identity only, NOT a
  numerical comparator run, which stays deferred per V3-RR-DESC).
- `~/.juliaup/bin/julia --project=docs docs/make.jl` → **passed (exit 0)** (incl.
  the new api.md entries). NOTE: CI on a clean checkout is the authoritative gate
  (Dropbox can transiently desync the working tree).

## Claim boundary

DESCRIPTIVE, supplied-covariance only — `K_g` is NOT estimated, NO mixed-model
equations, NO selection-response claim, NO R model-spec or bridge payload. The
RR MME solve, REML, eigen-function decomposition, and external comparator are
deferred (see the design note). No capability moved to covered.
