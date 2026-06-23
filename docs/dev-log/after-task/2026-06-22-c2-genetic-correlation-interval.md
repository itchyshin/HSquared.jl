# After-task — C2 genetic-correlation interval (engine `:delta`) — 2026-06-22

## Task goal

Backlog slice **C2**: a confidence interval for each off-diagonal genetic
correlation of an `:unstructured` multivariate REML fit. NEW EXPORT
`genetic_correlation_interval`. Engine half only — the R bridge/extractor is
cross-lane `[bridge]` and deferred (recorded as a cross-lane note). EXTENDS the
V4-MV-REML row in place; its `covered` status is UNCHANGED.

## Scope decision (time-aware, honest)

The spec asks for both `:delta` and `:profile` methods + a coverage sim + an R
bridge. I shipped the **`:delta`** method fully — it reuses the already-validated
`multivariate_covariance_standard_errors` SE + a Fisher-z transform (low-risk,
exactly cross-checkable) — and made `:profile` throw a clear "follow-up" error.
Rationale: the `:profile` leg is a genuinely complex constrained-REML
reparameterization (the (i,j) correlation pinned, all other (co)variances profiled,
PD-rejection) that rushing under time pressure would risk a subtle bug — the opposite
of "do it well." `:profile`, the coverage harness, and the R bridge are honest
follow-up (stated in the row).

## Active lenses / spawned agents

Lenses: Fisher (the Fisher-z interval + the boundary behaviour), Kirkpatrick
(genetic-correlation framing), Hopper (the cross-lane bridge contract). A real
`rose-systems-auditor` audited the branch → **CLEAN to merge**.

## Files changed (engine half)

- `src/multivariate.jl` — `genetic_correlation_interval(fit, Y, X, Z, Ainv; level,
  method = :delta, pairs, fd_step)`: per-pair tidy vectors `(trait_i, trait_j,
  estimate, lower, upper, lower_clamped, upper_clamped, level, method, converged)` +
  symmetric `lower_matrix`/`upper_matrix` (NaN diagonal + off-pair). Reuses the
  validated SE; Fisher-z transform; `:unstructured` guard; SE-throw → clear
  `ArgumentError`; `:profile` → "follow-up" error.
- `src/HSquared.jl` — export `genetic_correlation_interval`.
- `test/runtests.jl` — "Phase 4 genetic-correlation interval (C2)" testset (16
  assertions) + an `occursin` check on the V4-MV-REML evidence.
- `src/validation_status.jl` — APPENDED a clause to the V4-MV-REML evidence join
  (NO new row; status stays `covered`; count UNCHANGED at 47).
- `docs/design/validation-debt-register.md`, `capability-status.md` — V4-MV-REML
  rows appended. `docs/design/14-program-backlog.md` — C2 🟡 (engine `:delta` half).

## Checks run and exact outcomes

- C2 testset (`Pkg.test()`, 16 assertions): one pair (i=2,j=1) with
  `estimate ≈ rg[2,1]`, `lower < estimate < upper`, endpoints in (−1,1); level/method
  fields; clamp flags false; symmetric matrices with NaN diagonal/off-pair; **exact
  cross-check** `ci.lower/upper == tanh(atanh(rg) ± z·se_z)` from the validated SE path
  (rtol 1e-8, proves reuse); level-nesting (0.99 ⊃ 0.90); guards (`:profile` follow-up
  error, structured-fit rejection, level∉(0,1)); boundary (n=8 single-record → SE path
  throws → `:delta` throws, no fabricated whisker). **All pass.**
- Full `Pkg.test()` (thread-capped): **"Testing HSquared tests passed"** (exit 0).
- `julia --project=docs docs/make.jl` (thread-capped): **exit 0** (no dead links).
- Real `rose-systems-auditor`: **CLEAN to merge** — confirmed V4-MV-REML stays
  `covered` (count unchanged, all pinned substrings preserved), the interval is fenced
  as partial/Wald/not-coverage-calibrated across all four surfaces, reuse-not-rederive
  proven, boundary throws / NaN not fabricated, `:profile` + R bridge honestly deferred.

## Public claim audit (Rose)

- V4-MV-REML stays `covered` (point estimate); the interval does NOT extend it.
  `validation_status()` count UNCHANGED (47); nothing promoted.
- The delta CI is honestly a Wald approximation, NOT coverage-calibrated, on all
  surfaces. `:profile`, the coverage harness, and the R bridge are listed as follow-up.
- No fabricated whiskers (boundary throws; off-pair/diagonal entries NaN).

## Cross-lane note (R bridge — NOT edited here)

The R twin (`hsquared`) bridge for C2 is deferred: `julia-bridge.R` would pull the
engine's `lower_matrix`/`upper_matrix` (NaN survives the round-trip), the normalizer
would attach `genetic_correlation_interval`, and `extractors.R` + `NAMESPACE` would add
the S3 generic mirroring `covariance_standard_errors`. Engine return fields for the
bridge: `lower_matrix`, `upper_matrix`, `level`, `method`. `[JL]` lane did not edit the
R repo (AGENTS.md rule 2).

## Known limitations

- `:delta` only (`:profile` follow-up); Wald / Fisher-z, NOT coverage-calibrated; no
  coverage sim yet; `:unstructured` only; no R bridge. Boundary (rg→±1) yields a clear
  error, not an interval.

## Next actions

1. Commit, PR, merge on green CI (pre-authorized).
2. Then **C6** (parametric-bootstrap VC CI, extends V1-HERIT-CI).
3. Then **J1** (haplodiploid — LANDMINE; derive convention + Mendel/Falconer sign-off
   FIRST; may land as "derived + spec'd, awaiting ratification").
