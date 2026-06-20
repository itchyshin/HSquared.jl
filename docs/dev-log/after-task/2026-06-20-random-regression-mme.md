# After-task — Supplied-covariance random-regression MME (#54, slice 2) — 2026-06-20

Overnight autonomous run (Ada), continued. Slice 2 of the random regression
capability, from Henderson's vetted design (slice 1 = descriptors, landed earlier).

## Goal

Implement the supplied-covariance random-regression Henderson MME solve —
`random_regression_mme` + `legendre_design` — the function-valued analogue of
`multivariate_mme`.

## What landed

- `legendre_design(ts, order)` (n×k design) and `random_regression_mme(y, X, Phi, Z,
  Ainv, K_g, sigma_e2; ids)` returning per-animal `q×k` coefficient matrices.
- The load-bearing correctness point (Henderson's flagged "classic silent RR bug"):
  the random design is `W = face-splitting(Z, Phi)`, NOT `kron(Z, I_k)`, with
  `kron(Ainv, inv(K_g))` precision in matching animal-outer/coefficient-fastest
  order. Pinned by an INDEPENDENT dense marginal-GLS oracle (asymmetric `K_g`) and
  the degree-0 reduction to `henderson_mme`.

## Local checks

- `Pkg.test()` → exit 0 (RR MME testset 14/14). `docs/make.jl` → exit 0.
- CI on a clean checkout is the authoritative gate (Dropbox caveat).

## Claim boundary

SUPPLIED-covariance, homogeneous-residual, validation-scale — `K_g`/`σ²e` not
estimated (RR REML = slice 3, roadmap note), no R model-spec/bridge, no comparator
evidence. No capability moved to covered.
