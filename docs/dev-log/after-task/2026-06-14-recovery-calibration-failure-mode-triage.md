# 2026-06-14 Recovery Calibration Failure-Mode Triage

## Task Goal

Classify the failed seeds from the predeclared multivariate recovery calibration
run by which threshold failed, using only committed logs and without rerunning
any stochastic simulation.

## Active Lenses And Spawned Agents

- Curie/Fisher: negative simulation evidence and threshold interpretation.
- Rose: claim-vs-evidence boundary.
- Grace: reproducible tooling and audit trail.
- Spawned agents: none.

## Files Changed

- `sim/summarize_recovery_calibration.jl`
- `test/runtests.jl`
- `src/validation_status.jl`
- `docs/dev-log/recovery-checkpoints/2026-06-14-multivariate-recovery-calibration-failure-modes.md`
- `docs/dev-log/recovery-checkpoints/2026-06-14-multivariate-recovery-calibration-summary.md`
- `docs/dev-log/decisions/2026-06-14-calibration-failure-response.md`
- `docs/src/validation-status.md`
- `docs/src/multivariate-models.md`
- `docs/src/changelog.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/design/06-public-claims-register.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- this report

## What Landed

`sim/summarize_recovery_calibration.jl` now classifies failed seeds as `G`,
`R`, `G+R`, or `reported-fail`. Tests parse the committed raw logs and pin the
failure-mode counts.

Failure-mode result:

- unstructured: 3 G-only failures and 1 G+R failure;
- factor-analytic: 1 G-only failure and 1 G+R failure;
- low-rank: 1 R-only failure.

## Public Claim Audit

Allowed:

- the failed calibration run has deterministic failure-mode triage;
- future revised plans can use those modes to predeclare a better diagnostic or
  DGP.

Blocked:

- no broad multi-seed calibration claim;
- no threshold relaxation after seeing results;
- no dropped failed seeds;
- no status promotion;
- no R-facing syntax;
- no bridge payload or `result_payload()` change;
- no comparator parity claim.

## Checks

- `git diff --check`: passed.
- Throttled `~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`: passed.
  - Recovery calibration log summarizer testset is now 21 checks.
  - Phase 0 scaffold/validation-status block is now 186 checks.
  - Phase 4B structured covariance testset remains 61 checks.
- Throttled `~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`: passed.
  - Known caveats remained: 8 docstrings not included in the manual; local
    deployment skipped outside CI; VitePress default config substitutions;
    missing local logo/favicon/package.json substitutions; 4 npm audit
    advisories in generated docs dependencies.
