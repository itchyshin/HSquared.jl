# 2026-06-14 Multivariate Recovery Calibration Protocol

## Task Goal

Record the calibration protocol required before the Phase 4 unstructured or
Phase 4B structured recovery harnesses can support a broad multi-seed recovery
claim.

## Active Lenses And Spawned Agents

- Curie/Fisher: simulation target, seed-count gate, and reporting summary.
- Gauss: multivariate REML recovery interpretation.
- Kirkpatrick: structured covariance / factor-analytic boundary.
- Grace: local checks and reproducibility.
- Rose: claim-vs-evidence boundary.
- Spawned agents: none.

## Files Changed

- `docs/dev-log/decisions/2026-06-14-multivariate-recovery-calibration-protocol.md`
- `src/validation_status.jl`
- `test/runtests.jl`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/design/06-public-claims-register.md`
- `docs/src/validation-status.md`
- `docs/src/multivariate-models.md`
- `docs/src/changelog.md`
- `ROADMAP.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.md`
- this report

## What Landed

The new protocol separates seed-list support from actual broad multi-seed
calibration. It requires a pre-run record of commit SHA, Julia/platform, exact
commands, seed list, case list, iteration cap, thresholds, DGP settings, and any
planned parameter-grid variation.

The minimum gate is:

- at least 10 seeds for the unstructured multivariate REML harness;
- at least 10 seeds for each requested structured case;
- default iteration caps unless a different cap is declared before execution;
- no post-hoc seed cherry-picking.

Required reporting now includes pass/converged counts, mean/median/max relative
`G` and `R` errors, a seed-level table, a pass-proportion interval, and all
failed seeds plus raw output.

## Checks Run

- `git diff --check`: passed.
- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: passed.
  - Phase 0 scaffold/validation-status block is now 176 checks.
  - Phase 4B structured covariance testset remains 61 checks.
- `~/.juliaup/bin/julia --project=docs docs/make.jl`: passed.
  - Known caveats remained: 8 docstrings not included in the manual; local
    deployment skipped outside CI; VitePress default config substitutions;
    missing local logo/favicon/package.json substitutions; 4 npm audit
    advisories in generated docs dependencies.

## Public Claim Audit

Allowed:

- the unstructured and structured multivariate recovery harnesses support
  explicit seed lists;
- the repository now records the protocol required before any broad multi-seed
  calibration claim;
- broad multi-seed calibration remains future work.

Blocked:

- no recovery calibration was executed in this slice;
- no CI RNG;
- no R-facing multivariate or covariance-structure syntax;
- no bridge payload or `result_payload()` change;
- no covariance standard errors or likelihood-ratio tests;
- no external comparator parity;
- no status promotion for `V4-MV-REML` or `V4-FA`.

## Tests Of The Tests

`test/runtests.jl` now requires both `V4-MV-REML` and `V4-FA`
validation-status evidence to mention the calibration protocol. The claim
boundaries still require the "not broadly multi-seed calibrated" and
"no R-facing" wording.

## Coordination Notes

No R repository code was edited. This is a Julia-side evidence gate for future
calibration wording only; it does not alter R syntax, R bridge payloads, or the
shared fixture/comparator protocol.

## Known Limitations

- The protocol has not been executed.
- No new simulation seeds were run for this slice.
- No comparator package output was generated.
- No uncertainty interval, covariance SE, or LRT implementation was added.

## Next Actions

1. Execute the protocol as an opt-in run when the branch is ready for the
   longer compute pass.
2. Preserve the seed-level output and pass-proportion interval in the check-log.
3. Keep `V4-MV-REML` and `V4-FA` partial until the evidence is actually
   recorded.
