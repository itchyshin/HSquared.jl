# After-Task Report: R-lane Mrode multivariate anchor sync

## Live Phase Snapshot

As of this report, the slice starts from Julia `main` `ad7848c` after #137
closed the multivariate SE/LRT issue ledger. Covered public status is unchanged:
v0.1 univariate Gaussian animal-model support only. `V4-MV-REML` remains
`partial`.

## 1. Goal

Sync Julia's V4 multivariate validation ledger with newer R-lane evidence: a
published Mrode Example 5.1 supplied-covariance BLUP/MME anchor and a
`MCMCglmm` Bayesian agreement probe.

## 2. Implemented

- Updated `validation_status()` and its tests so `V4-MV-REML` now records:
  `hsquared` `6a1065e` for the Mrode Example 5.1 supplied-covariance anchor,
  and `hsquared` `dbf97a7` for the `MCMCglmm` agreement probe.
- Removed the stale "published Mrode multi-trait estimate" blocker from the
  V4 REML missing field while keeping the second same-estimand comparator
  blocker.
- Updated capability, validation-debt, public-claims, and Documenter source
  wording to match.
- Recorded the cross-lane boundary in the coordination board and check-log.

## 3a. Decisions and Rejected Alternatives

- Treated Mrode Example 5.1 as supplied-covariance BLUP/MME evidence, not REML
  covariance-estimation validation by itself.
- Treated `MCMCglmm` as Bayesian agreement evidence only. It does not satisfy
  the same-estimand REML comparator gate.
- Did not promote `V4-MV-REML` to covered. The recovery gate still needs an
  accepted/broadened declaration, and a second same-estimand comparator remains
  absent.

## 4. Files Touched

- `src/validation_status.jl`
- `test/runtests.jl`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/src/validation-status.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-mrode-multivariate-anchor-sync.md`
- `docs/dev-log/after-task/2026-06-21-mrode-multivariate-anchor-sync.md`

## 5. Checks Run

- `git -C /Users/z3437171/Dropbox/Github\ Local/hsquared log --oneline --grep='Mrode multivariate' --all`
  — confirmed R evidence commit `6a1065e`.
- `git -C /Users/z3437171/Dropbox/Github\ Local/hsquared log --oneline --grep='MCMCglmm' --all`
  — confirmed R evidence commit `dbf97a7`.
- `gh issue view 41 --comments --json number,title,state,body,comments,url,labels`
  — confirmed the R lane still frames covered promotion as Julia-gated and
  still needs another same-estimand comparator.
- `gh issue view 49 --comments --json number,title,state,body,comments,url,labels`
  — confirmed the `sommer` leg is recorded and BLUPF90/ASReml/DMU/WOMBAT-style
  same-estimand evidence remains open.
- `julia --project=. -e 'using Pkg; Pkg.test()'` — first run failed one
  status-string assertion after boundary wording dropped "comparator protocol";
  restored the phrase.
- `julia --project=. -e 'using Pkg; Pkg.test()'` — passed.
- `julia --project=docs docs/make.jl` — passed with existing local warnings
  for omitted internal docstrings, skipped deployment detection, substituted
  Vitepress defaults, missing logo/favicon, and npm audit output.
- `git diff --check` — passed.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-mrode-multivariate-anchor-sync.md`
  — passed.
- `rg -n "no published/textbook multivariate target|no published multi-trait fixture|published Mrode multi-trait estimate" src docs/design docs/src README.md ROADMAP.md test comparator`
  — only the intentional negative assertion in `test/runtests.jl` remains.

## 6. Tests of the Tests

`test/runtests.jl` now pins the new evidence strings (`Mrode Example 5.1`,
`hsquared` `6a1065e`, `MCMCglmm`, `hsquared` `dbf97a7`) and also pins the
negative boundary: the missing field must not still list the published Mrode
multi-trait target as absent, while it must still require a second
same-estimand REML comparator.

## 7a. Issue Ledger

- #41 remains open: the promotion gate still needs recovery-gate acceptance or
  broadening and another same-estimand comparator.
- #49 remains open: the second same-estimand comparator is still absent.
- No R issue or file was changed from this Julia lane.

## 8. Consistency Audit

- Checked `src/validation_status.jl`, `test/runtests.jl`,
  `docs/design/capability-status.md`,
  `docs/design/validation-debt-register.md`,
  `docs/design/06-public-claims-register.md`, and
  `docs/src/validation-status.md`.
- Searched for stale current-status wording that said the multivariate published
  target was absent. Historical after-task files were left untouched as
  time-stamped snapshots.

## 9. What Did Not Go Smoothly

The first test run caught a drift between the updated claim-boundary wording and
the existing test guard: the phrase "comparator protocol" had been dropped from
the boundary. The fix restored the phrase rather than weakening the test.

## 10. Known Residuals

- `V4-MV-REML` remains `partial`.
- `MCMCglmm` is not same-estimand REML parity.
- BLUPF90/AIREMLF90 remains preflight-only until an executable-backed run is
  recorded.
- No public/default R multivariate model-spec or covered-status promotion
  follows from this slice.

## 11. Team Learning

When the R lane produces new evidence after a Julia target has landed, mirror
the exact evidence class, not just the direction of travel. A published
supplied-covariance MME target can close one blocker while leaving the REML
comparator and calibration gates open.
