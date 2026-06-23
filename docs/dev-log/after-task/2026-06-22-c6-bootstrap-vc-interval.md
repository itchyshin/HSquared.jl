# After-task — C6 parametric-bootstrap variance-component interval — 2026-06-22

## Task goal

Backlog slice **C6**: a parametric-bootstrap percentile CI for `σ²a`, `σ²e`, and
`h²` of a fitted univariate Gaussian REML animal model — the cross-check the
V1-HERIT-CI debt explicitly names. NEW EXPORT `bootstrap_variance_component_interval`.
`[JL]` engine-only; EXTENDS V1-HERIT-CI in place (stays `partial`).

## Active lenses / spawned agents

Lenses: Fisher (the bootstrap estimand + the n_converged honesty hinge), Gauss (the
dense simulate-at-fit idiom + the percentile contract), Grace (the `Random` [deps]
addition). A real `rose-systems-auditor` audited the branch before merge.

## What I did + a spec gap I corrected

- `bootstrap_variance_component_interval(fit; level, n_boot, estimator, rng,
  max_dense_cells)` in `src/likelihood.jl`: simulate Gaussian `y*` at the fitted
  `(β, σ²a, σ²e)` over the supplied relationship (`a* = chol(inv(Ainv)).L·randn·√σ²a`,
  `e* = randn·√σ²e`), refit each replicate with the same REML estimator
  (`:sparse_reml`/`:ai_reml`), percentile endpoints via the in-package type-7
  `_empirical_upper_quantile` (no `Statistics`/`Distributions` dependency). A
  replicate whose refit throws (`PosDefException`) or returns a non-finite/boundary
  variance is DROPPED and counted in `n_converged` (surfaced, not hidden).
  Deterministic via a fixed-seed `rng` keyword; dense path guarded by
  `_check_dense_validation_size`.
- **Spec gap corrected:** the spec's DEPENDENCIES line was empty, but `Random` was
  only a TEST dependency — the engine could not reference `MersenneTwister`/
  `randn(rng,…)`. I promoted `Random` (a stdlib, low-cost) to `[deps]` (and removed it
  from the test extras — it can't be in both), and `using Random` in `HSquared.jl`.

## Files changed

- `Project.toml` — `Random` moved from test extras to `[deps]`.
- `src/HSquared.jl` — `using Random`; export `bootstrap_variance_component_interval`.
- `src/likelihood.jl` — the new function.
- `test/runtests.jl` — "Phase 1 parametric-bootstrap variance-component interval (C6)"
  testset + an `occursin` check on the V1-HERIT-CI evidence.
- `src/validation_status.jl` — V1-HERIT-CI evidence APPENDED (bootstrap clause), the
  "missing" updated (the bare "parametric-bootstrap alternative" replaced by the
  three-method coverage-calibration item), claim_boundary updated; status stays
  `partial`, count UNCHANGED at 47. NOTE: held apart from C5's genomic edit — appended,
  not clobbered.
- `docs/design/validation-debt-register.md` — V1-HERIT-CI mirror appended.
  `docs/design/14-program-backlog.md` — C6 ✅.

## Checks run and exact outcomes

- C6 testset (`Pkg.test()`): point passthrough; bracketing (`≤` — the tiny-n REML
  surface is flat) + non-degeneracy + h² CI in (0,1); `n_converged` accounting
  (length(replicates) == n_converged); determinism (same seed → byte-identical CIs +
  replicates; different seed → different draws); level-monotone nesting (same seed,
  wider percentile); `:ai_reml` path brackets; the percentile contract
  (endpoints == `_empirical_upper_quantile` at (1±level)/2); guards (level∉(0,1),
  n_boot≤0, bad estimator, non-REML fit). **All pass.**
- Full `Pkg.test()` (thread-capped, with the `Random` dep resolved): **"Testing
  HSquared tests passed"** (exit 0; 2 test-side assertions fixed first — the h² CI
  closed-[0,1] boundary case and the `(1-level)/2`-vs-`0.025` Float64 percentile form).
- `julia --project=docs docs/make.jl` (thread-capped): **exit 0** (no dead links).
- Real `rose-systems-auditor` over the branch: **PROMOTE-WITH-CHANGES → addressed**.
  Confirmed: V1-HERIT-CI stays `partial` (count unchanged at 47), the C5 genomic edit
  was preserved (appended, not clobbered — all C5 + delta/profile substrings intact),
  the `n_converged` honesty hinge surfaces dropped refits, determinism + the exact
  `(1±level)/2` percentile contract hold, and the `Random` [deps] promotion is correct
  and minimal. Required change APPLIED: a docstring referenced a not-yet-written sim
  (`sim/phase1_bootstrap_vc_interval.jl`); replaced with the honest "deferred follow-up"
  framing the rest of the slice uses.

## Public claim audit (Rose)

- V1-HERIT-CI stays `partial`; `validation_status()` count UNCHANGED (47); nothing
  promoted. The C5 genomic edit was preserved (appended, not clobbered).
- The bootstrap is honestly the CROSS-CHECK the debt names, NOT evidence that the
  delta/profile intervals are correct; its OWN coverage is NOT calibrated. `n_converged`
  surfaces dropped/non-converged refits. Percentile-only (BCa out of scope).
- `Random` is a stdlib `[deps]` addition (deterministic seedable RNG) — recorded.

## What did not go smoothly

- The `Random`-not-a-dep spec gap (above). Promoting a stdlib to `[deps]` re-resolves
  the Manifest; handled in the test run.
- The n=8 fixture's flat REML surface means bootstrap brackets use `≤` (an endpoint may
  sit at the estimate) — honest, not a fabricated strict interval.

## Known limitations

- Univariate Gaussian REML only (multivariate/non-Gaussian bootstrap = separate
  slices); dense/validation-scale (forms inv(Ainv)+chol(A), guarded); PERCENTILE only
  (no BCa); coverage NOT calibrated (an opt-in coverage sim is deferred follow-up); no
  R bridge (engine-internal, not surfaced through hs_control).

## Next actions

1. Confirm full `Pkg.test()` + `docs/make.jl` green; fill the two pending outcomes.
2. Real `rose-systems-auditor`; commit, PR, merge on green CI.
3. Then **J1** (haplodiploid — LANDMINE): DERIVE the diploidized convention +
   Mendel/Falconer sign-off FIRST; land as "derived + spec'd, awaiting ratification"
   rather than merging code without sign-off.
