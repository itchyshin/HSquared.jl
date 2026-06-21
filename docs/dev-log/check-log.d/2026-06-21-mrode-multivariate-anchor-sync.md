# 2026-06-21 R-lane Mrode multivariate anchor sync

- Goal: reconcile Julia's V4 multivariate validation ledger with later R-lane
  evidence without promoting `V4-MV-REML` beyond `partial`.
- Lenses: Ada + Shannon (cross-lane sync), Curie + Fisher + Mrode (validation
  evidence), Rose (claim boundary), Grace (checks).

## Evidence consumed

- R lane `hsquared` commit `6a1065e` / PR #37: Mrode Example 5.1
  supplied-covariance multivariate BLUP/MME anchor. The R after-task report
  records fixed effects and animal BLUPs at supplied `G0`/`R0`, printed-digit
  tolerances, and a perturbation guard.
- R lane `hsquared` commit `dbf97a7`: `MCMCglmm` 2.36 Bayesian agreement probe
  against the shared `phase4_multitrait_parity` target. The serialized target
  lies inside 95% HPD intervals, but this is not a same-estimand REML
  comparator.
- Existing Julia evidence remains unchanged: one reproduced same-estimand
  `sommer` 4.4.5 comparator leg, R/J cold-start recovery evidence, covariance
  SE/LRT support, and BLUPF90 preflight without executable output evidence.

## Files changed

- `src/validation_status.jl`
- `test/runtests.jl`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/src/validation-status.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-mrode-multivariate-anchor-sync.md`
- `docs/dev-log/after-task/2026-06-21-mrode-multivariate-anchor-sync.md`

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'` — first run failed one
  status-string assertion after the boundary wording dropped "comparator
  protocol"; restored the phrase in `src/validation_status.jl`.
- `julia --project=. -e 'using Pkg; Pkg.test()'` — passed.
- `julia --project=docs docs/make.jl` — passed with existing local warnings:
  omitted internal docstrings, skipped deployment detection, substituted
  Vitepress defaults, missing logo/favicon, and npm audit output.
- `git diff --check` — passed.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-mrode-multivariate-anchor-sync.md`
  — passed.
- `rg -n "no published/textbook multivariate target|no published multi-trait fixture|published Mrode multi-trait estimate" src docs/design docs/src README.md ROADMAP.md test comparator`
  — only the intentional negative assertion in `test/runtests.jl` remains.

## Claim boundary

The published/textbook target blocker is no longer listed for the supplied-
covariance multivariate equations because the R lane now records Mrode Example
5.1. `V4-MV-REML` remains `partial`: the recovery gate still needs acceptance
or broadening, and a second independent same-estimand REML comparator
(BLUPF90/AIREMLF90, ASReml, DMU/WOMBAT, or accepted equivalent) is still absent.
`MCMCglmm` is Bayesian agreement evidence only.
