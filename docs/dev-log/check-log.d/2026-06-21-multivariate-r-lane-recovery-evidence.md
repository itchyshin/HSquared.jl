# 2026-06-21 Multivariate REML R-lane recovery evidence mirror (V4-MV-REML)

- Goal: mirror the R-lane 100-rep cold-start known-truth multivariate recovery
  evidence into the Julia validation ledgers without promoting `V4-MV-REML`.
- Lenses: Ada + Shannon (cross-lane coordination), Curie + Fisher + Mrode
  (validation evidence), Rose (claim boundary), Grace (checks).

## Evidence Source

Read-only sibling R repo evidence:

- `/Users/z3437171/Dropbox/Github Local/hsquared/data-raw/multivariate-recovery-study.R`
- R-lane issue/coordination notes for `hsquared#10` and `HSquared.jl#41/#49`

The study was not rerun in this Julia slice. It is recorded as R-lane evidence
because the local R environment reported by R2 no longer has every optional
package needed for a fresh rerun (`nadiv` absent in that lane), while the script
contains a committed result block.

## Recorded Result

- Design: 420 animals, two traits, one record per animal.
- Start: cold `G0 = R0 = diag(2)`, not truth.
- Replicates: 100/100 converged.
- Bias/MCSE gate: all 9 reported targets had 0 inside bias +/- 2*MCSE:
  six G0/R0 entries, genetic correlation `rg`, and two `h2` values.
- EBV accuracy: trait 1 = 0.790, trait 2 = 0.742.

## Claim Boundary

This corroborates the Julia 12-seed bias/MCSE and cold-start evidence with
tighter MCSE. It is validation-scale recovery evidence, not external
multi-package parity and not a coverage-calibrated public claim.

`V4-MV-REML` remains `partial`. Remaining blockers include a published Mrode
multi-trait estimate or equivalent textbook target, plus another independent
comparator leg beyond the one reproduced `sommer` fixture run.

## Local Repo Checks

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` — passed.
- `~/.juliaup/bin/julia --project=docs docs/make.jl` — passed. Existing-style
  local-build warnings were observed for undocumented docstrings, missing local
  Vitepress logo/favicon assets, skipped deployment detection, and npm audit
  output.
- `git diff --check` — passed.
