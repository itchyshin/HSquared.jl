# After-task — v0.6 ordinal JOINT cutpoint estimation (doc-20 Step 1) — 2026-07-01

## Task goal
Phase 1 of the maintainer-authorized 7-hour plan: extend the merged ordinal kernel to JOINT
`(σ²a, cutpoints)` estimation via `fit_laplace_reml(...; family = :ordered_probit)`. Experimental/`partial`;
covered flips remain maintainer-G10.

## Active lenses and spawned agents
Gauss/Fisher (estimator + identifiability) inline; **Rose** (`rose-systems-auditor`) — mandatory audit pending.

## Live phase snapshot
- **As of 2026-07-01 (v0.6 ordinal joint cutpoint estimation; branch `feat/2026-07-01-v06-ordinal-joint-estimation`,
  PR pending; `main` @ `94d20319`).** `fit_laplace_reml(...; family=:ordered_probit)` joint-estimates σ²a +
  the K-1 cutpoints (identified `θ_1=0` + positive-increment reparam; guarded NelderMead with a σ²a safety
  rail). K=2 reduces exactly to `:bernoulli_probit`. `validation_status()` = **50 UNCHANGED** (extends
  V6-ORDINAL); public-covered fitting = 1 UNCHANGED. Honest finding: ≥3-category σ²a weakly identified on
  uninformative data (threshold-model property) — recovery gate (Phase 5) exercises it. NEXT: Phase 2 (Gamma
  joint shape) → Phase 3 (`:symbol` payload) → Phase 4 (comparators, glmmTMB local) → Phase 5 (Totoro gates).

## Files changed
`src/nongaussian.jl` (the `:ordered_probit` fit case + allow-list), `test/runtests.jl` (T1-fit testset),
`src/validation_status.jl` + `docs/design/{capability-status,validation-debt-register}.md` (V6-ORDINAL extended),
this check-log + after-task.

## What changed
The ordinal family gained a joint-estimation fitted path (the doc-20 Step 1 estimator). The kernel and all
other families are untouched. No new status row, no export, no R, no covered claim.

## Checks run and exact outcomes
Smoke: K=2 fit == `:bernoulli_probit` (Δσ²a 1e-7). `Pkg.test()` PASS (T1-fit 10/10, count 50).
`docs/make.jl` exit 0.

## Public claim audit
public-covered fitting = 1 UNCHANGED; validation 50 UNCHANGED. No export/default/R/covered change.

## Tests of the tests
The K=2 fitted reduction compares against the independently-validated `:bernoulli_probit` fit (not the
ordinal path). The K=3 self-consistency check recomputes the marginal at the returned estimate via a
separate call. Structural asserts (ordering, rail-bound) are data-independent.

## Coordination notes
Julia-engine-lane, solo, autonomous. Builds on the merged #212 kernel (now on `main`). No R lane change.

## What did not go smoothly
The initial K≥3 fit ran σ²a → 3.4e11 on an uninformative fixture (Ainv=I, one obs/animal → σ²a confounded
with the fixed probit residual). Diagnosed as a threshold-model identifiability property, not a bug; added a
σ²a safety rail + a structured-pedigree test fixture + an explicit caveat. Honest — the weak identification
is real and documented.

## Known limitations
Laplace-only; internal (not exported / not R-wired); the `:symbol` payload + scale-labelled h² are owed;
≥3-category σ²a weakly identified without informative data (rail-bounded); no comparator or recovery gate yet;
NOT a covered claim.

## Next actions
1. Rose audit. 2. PR staged for review (do not merge unless authorized). 3. Phase 2 (Gamma joint shape).
