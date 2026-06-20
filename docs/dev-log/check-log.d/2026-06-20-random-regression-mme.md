# 2026-06-20 Supplied-covariance random-regression MME (#54, slice 2)

- Goal: slice 2 of the random regression capability (Henderson's design) — the
  supplied-covariance RR Henderson MME solve, building on slice 1's basis +
  descriptors. Still supplied-covariance (REML deferred).
- Lenses: Henderson (MME) + Curie (oracle test); Rose (claim gate).

## What was done

- `src/random_regression.jl` (exported): `legendre_design(ts, order)` (n×k design
  matrix) and `random_regression_mme(y, X, Phi, Z, Ainv, K_g, sigma_e2; ids)` —
  internal `_rr_random_design` builds `W = face-splitting(Z, Phi)` (record `r`
  scatters `Phi[r,:]` into animal `a(r)`'s `k`-column block, NOT `kron(Z, I_k)`);
  genetic precision `kron(Ainv, inv(K_g))` (animal-outer, coefficient-fastest);
  2×2 block solve; returns per-animal `q×k` coefficient matrix.
- Correctness GATE — an INDEPENDENT dense marginal-GLS oracle (`V = W(A⊗K_g)Wᵀ +
  σ²e I`, β + all coefficients to 1e-8, with an asymmetric `K_g` so a wrong
  coefficient ordering fails) + the degree-0 reduction to `henderson_mme` (the
  scalar animal model). Both pass. The oracle's `W` is built independently of
  `_rr_random_design`, so a design/ordering bug cannot pass.
- Tests: "Phase 3 supplied-covariance random-regression MME (#54 slice 2)" (14
  assertions). api.md + capability-status (new row) + V3-RR-DESC updated; roadmap
  note marks slice 2 DONE.

## Commands / results

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed (exit 0)**
  (RR MME testset 14/14; dense-oracle + degree-0 gates green).
- `~/.juliaup/bin/julia --project=docs docs/make.jl` → **passed (exit 0)** (incl. the
  new api.md entries). CI on a clean checkout is the authoritative gate (Dropbox
  caveat).

## Claim boundary

SUPPLIED-covariance, homogeneous-residual, validation-scale — `K_g`/`σ²e` NOT
estimated (RR REML = slice 3), no R model-spec or bridge payload, no external
comparator evidence. No capability moved to covered.
