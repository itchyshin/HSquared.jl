# After-task — v0.6 Gamma JOINT (σ²a, shape) estimation — 2026-07-01

## Task goal
Phase 2 of the 7-hour plan: extend the merged Gamma kernel to JOINT `(σ²a, shape ν)` estimation via
`fit_laplace_reml(...; family = :gamma)`. Experimental/`partial`; covered flips remain maintainer-G10.

## Active lenses and spawned agents
Gauss/Fisher inline; **Rose** (`rose-systems-auditor`) — mandatory audit pending.

## Live phase snapshot
- **As of 2026-07-01 (v0.6 Gamma joint shape estimation; branch `feat/2026-07-01-v06-gamma-joint-estimation`,
  PR pending; `main` @ `94d20319`).** `fit_laplace_reml(...; family=:gamma)` joint-estimates σ²a + the
  shape ν (NelderMead over `(log σ²a, log ν)`, `:nbinom` shape). `validation_status()` = **50 UNCHANGED**
  (extends V6-GAMMA); public-covered fitting = 1 UNCHANGED. Gamma is well identified (continuous, no rail
  needed). NEXT: Phase 3 (`:symbol` payload) → Phase 4 (glmmTMB comparator, local) → Phase 5 (Totoro gates).

## Files changed
`src/nongaussian.jl` (`:gamma` fit case + allow-list), `test/runtests.jl` (T-Gamma-fit testset),
`src/validation_status.jl` + `docs/design/{capability-status,validation-debt-register}.md` (V6-GAMMA extended),
this check-log + after-task.

## What changed
The Gamma family gained a joint-estimation fitted path (doc-20-analogous Step for Gamma). Kernel + other
families untouched. No new status row, no export, no R, no covered claim.

## Checks run and exact outcomes
Smoke (signal fixture): σ²a=0.213, ν=21.4, converged, self-consistent. `Pkg.test()` PASS (T-Gamma-fit 6/6,
count 50). `docs/make.jl` exit 0.

## Public claim audit
public-covered fitting = 1 UNCHANGED; validation 50 UNCHANGED. No export/default/R/covered change.

## Tests of the tests
Self-consistency recomputes the marginal at the returned estimate separately. The optimum-beats-off-optimum
check uses an independent marginal eval. The genetic-signal fixture makes σ²a meaningfully positive (a
signal-less fixture correctly yields σ²a≈0).

## Coordination notes
Julia-engine-lane, solo, autonomous. Builds on the merged #214 kernel. No R lane change. Independent of the
Phase 1 (#215) branch.

## What did not go smoothly
Nothing notable — the `:nbinom` joint pattern transferred cleanly (Gamma is well identified on continuous
data, unlike the ordinal threshold's weak σ²a identification).

## Known limitations
Laplace-only; internal (not exported / not R-wired); the `:symbol` payload + scale-labelled h² owed; the
glmmTMB comparator run (Phase 4) + recovery gate (Phase 5) owed; NOT a covered claim.

## Next actions
1. Rose audit. 2. PR staged. 3. Phase 3 (`:symbol` payload wiring for both families).
