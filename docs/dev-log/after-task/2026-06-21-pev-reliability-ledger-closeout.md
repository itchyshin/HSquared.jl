# After-Task Report: PEV/Reliability Payload Ledger Closeout

## Live Phase Snapshot

As of this report, the slice starts from Julia `main` `008ea4d` after the
genomic GBLUP/SNP-BLUP comparator target fixture. No open Julia PRs were present
at slice start. The R lane handled the paired R #21 mirror and merged hsquared
PR #73 at `adc2e63`, closing R issue #21 with the same no-promotion boundary.
Covered public status is unchanged: v0.1 univariate Gaussian animal-model
support only. This slice does not promote any validation row to covered.

## 1. Goal

Close the Julia-side #43 ledger drift after `result_payload(::AnimalModelFit)`
already gained standard `prediction_error_variance` and `reliability` fields.
The goal was to align current docs/status surfaces without widening claims or
touching the R repository.

## 2. Implemented

- Confirmed the implementation path in `src/likelihood.jl`: `result_payload(fit)`
  computes PEV once with `method = :selinv`, returns
  `prediction_error_variance = (ids, values)`, and reuses that PEV for
  `reliability = (ids, values)`.
- Confirmed existing tests pin the payload field order, field shape, selected-
  inverse values, and dense parity on validation-scale fixtures.
- Updated the engine contract, bridge compatibility matrix, roadmap,
  Documenter quickstart/roadmap pages, public claims register, capability
  status, v0.1 contract, and coordination board.
- Added this after-task report and a per-slice check-log note.

## 3a. Decisions and Rejected Alternatives

- Did not add duplicate tests, because the existing payload tests already pin
  the field order, `(ids, values)` shape, selected-inverse path, and dense
  parity.
- Did not alter historical check-log/changelog snapshots that accurately record
  earlier states of the bridge.
- Did not claim production reliability. The standard payload is still a
  validation-scale bridge surface, and the reliability denominator still has
  production-path work outstanding.
- Did not touch `hsquared`; the R twin owns the paired R #21 surface.

## 4. Files Touched

- `ROADMAP.md`
- `docs/design/01-v0.1-contract.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/12-bridge-compatibility.md`
- `docs/design/capability-status.md`
- `docs/src/quickstart.md`
- `docs/src/roadmap.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-pev-reliability-ledger-closeout.md`
- `docs/dev-log/after-task/2026-06-21-pev-reliability-ledger-closeout.md`

## 5. Checks Run

- `julia --project=. -e 'using Pkg; Pkg.test()'` — passed.
- `julia --project=docs docs/make.jl` — passed with existing local warnings for
  skipped deployment detection, substituted Vitepress defaults, missing
  logo/favicon, and npm audit output.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-pev-reliability-ledger-closeout.md`
  — passed.
- `git diff --check` — passed.

## 6. Tests of the Tests

Existing tests reject any removal or reordering of the standard payload fields
through the `propertynames(payload)` tuple. They also compare
`payload.prediction_error_variance.values` to `prediction_error_variance(fit;
method = :selinv)` and to the dense inverse values, and compare
`payload.reliability.values` to `reliability(fit; method = :selinv)`.

## 7a. Issue Ledger

- #43: this branch completes the Julia-owned status/contract closeout for
  standard PEV/reliability fields in fitted `AnimalModelFit` payloads.
- R lane: no R files were touched. The R twin merged hsquared PR #73 at
  `adc2e63` and closed R issue #21. After this PR lands, the paired
  PEV/reliability standard-field ledger is banked on both twins.

## 8. Consistency Audit

- Searched current docs/status surfaces for obsolete "compact base payload"
  phrasing around PEV/reliability.
- Kept multivariate `result_payload()` wording separate; this slice does not
  add multivariate PEV/reliability fields.
- Kept supplied-variance `HendersonMMEResult` bridge behavior separate from
  fitted `AnimalModelFit` payload behavior.

## 9. What Did Not Go Smoothly

The stale wording was spread across several layers because it reflected a true
earlier bridge state. The fix required distinguishing historical snapshots from
current source-of-truth docs.

## 10. Known Residuals

- No production large-pedigree reliability claim.
- No multivariate per-trait PEV/reliability payload.
- No new external comparator evidence.
- No fitted capability promotion, even though the paired R #21 issue-map row is
  now closed on the R side.

## 11. Team Learning

When a field moves from bridge enrichment into the standard payload, the
compatibility matrix, engine contract, quickstart, roadmap, and claims register
all need to move together. Otherwise the implementation is right but the
project memory keeps reopening the same issue.
