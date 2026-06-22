# After-task report — V4-MV-REML promoted partial → covered (substitutable gate)

Date: 2026-06-22. Lane: Julia engine (`HSquared.jl`), one-owner consolidation.
Branch `mv-reml-promotion` (merged `HSquared.jl#161`, merge commit `964448a5`).
Active lenses: Fisher (inference), Curie (recovery), Mrode (canon), Rose
(claim-vs-evidence). **Spawned subagents: Rose (`rose-systems-auditor`) — a real
adversarial audit, not a review perspective.**

## 1. Goal

Promote `V4-MV-REML` (multivariate unstructured REML `G0`/`R0` estimation) from
`partial → covered` (experimental, validation-scale, opt-in; NOT the public
default), honestly, on the doc-33 substitutable gate.

## 2. Implemented

- Pre-registered the substitutable gate + a bias/MCSE recovery gate (decision note,
  `a7b1f9ad`) BEFORE running.
- Ran a fresh 48-seed cold-start recovery (checkpoint, `24ee2d9c`) → PASSED all 4
  pre-declared criteria.
- Real Rose audit → PROMOTE-WITH-CHANGES; applied B1 (sommer data-raw/CI-diagonal
  honesty) + B2 (scrub "unbiased", de-conflate the 48-seed Julia vs 100-rep R legs).
- Flipped status `partial → covered` in `validation_status.jl` +
  `validation-debt-register.md`; updated `runtests.jl`.
- Recorded the doc-33 Outcome (`hsquared#109`).

## 3a. Decisions and Rejected Alternatives

- **Substitutable gate** (doc-33): one same-estimand REML (`sommer`) + a passing
  pre-declared recovery gate, instead of requiring a 2nd licensed-binary REML
  comparator (no free CRAN alternative exists). Kept the same-estimand-REML KIND
  requirement (Bayesian agreement does NOT substitute).
- **Path (b)** recovery gate (bias/MCSE) using the existing harness with more seeds,
  pre-declared to respect the 2026-06-14 no-post-hoc-relaxation rule.
- **Rejected:** post-hoc relaxation of the failed per-seed gate (forbidden);
  promoting without a fresh pre-declared run; flipping to covered without Rose + the
  maintainer's sign-off.
- B1 via honest **reword** (option b) now; the in-suite unstructured-`sommer` test
  (option a) is a recorded fast-follow.

## 4. Files Touched

- `HSquared.jl`: `docs/dev-log/decisions/2026-06-22-mv-reml-substitutable-gate.md`
  (new), `docs/dev-log/recovery-checkpoints/2026-06-22-mv-reml-predeclared-48seed.md`
  (new), `src/validation_status.jl` (V4-MV-REML row), `test/runtests.jl`,
  `docs/design/validation-debt-register.md`, this report.
- `hsquared`: `docs/design/33-v4-multivariate-promotion-gate-review.md` (Outcome +
  de-conflation).

## 5. Checks Run

- Pre-declared recovery: 48-seed cold-start, thread-capped → PASSED (48/48 converged;
  all six `|bias| ≤ 2·MCSE`; EBV 0.893/0.906; G-MCSE ≤ 0.045). Log
  `/tmp/mvreml_recovery_48.log`.
- `Pkg.test()` (thread-capped): green (all V4-MV-REML row assertions + 4 new covered
  checks).
- CI on `#161`: all checks SUCCESS. `#109` R-CMD-check SUCCESS.

## 6. Tests of the Tests

- Updated the status assertion to `"covered"` + added `occursin` checks for
  "pre-declared", "48-seed cold-start", "opt-in", "deep-inbreeding" — these would
  fail if the covered scope/caveats were dropped.
- Preserved all prior tested debt phrases ("did not pass", "no executed second
  same-estimand comparator run", "BLUPF90 is preflighted but not executed", …):
  covered does NOT erase the debt.

## 7a. Issue Ledger

- `V4-MV-REML`: partial → covered (experimental/opt-in/validation-scale). `#10` (MV
  comparator/recovery gates) substantially addressed; the 2nd-comparator debt
  remains open. Cross-lane `JL#61`.

## 8. Consistency Audit

- `validation_status.jl` + `validation-debt-register.md` + doc-33 + the unified board
  all reflect covered with the honest scope. **Public-default covered count
  unchanged (1 = v0.1 Gaussian)**; Julia validation covered 7 → 8. R capability-status
  consistency note added (R public multivariate stays opt-in experimental).

## 9. What Did Not Go Smoothly

- macOS BSD `seq` emitted scientific-notation seeds → harness arg-parse threw (zero
  fits, pre-registration intact); fixed with `seq -f "%.0f"`.
- A background-task "exit 0" was the bash wrapper's final `grep`, not Julia (which
  exits 1 on the per-seed gate) — read the aggregate block, not the exit code.

## 10. Known Residuals

- `G[1,1]` −5.7% (1.57·MCSE) — finite-sample REML behaviour, within the gate, honestly
  scoped (never "unbiased").
- Fast-follows: in-suite unstructured-`sommer` test; BLUPF90 2nd comparator;
  broader-DGP recovery (full-sib / larger-n / 3+ traits); deep-inbreeding boundary.
- R-facing multivariate bridge semantics remain opt-in experimental (not public).

## 11. Team Learning

Pre-registration (commit the gate before results) + a real Rose audit is the honest
path to a covered promotion: it converts a "6/10 failed" optics problem into a
defensible bias/MCSE claim **without** post-hoc relaxation. Rose's git-timestamp
verification and the B1 data-raw/CI-gap catch were load-bearing — the gate cannot
lean on a `.Rbuildignore`d artifact.
