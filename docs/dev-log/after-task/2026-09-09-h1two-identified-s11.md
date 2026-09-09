# After-task — 2026-09-09 H1-two identified S11 retained Narval campaign

## 1. Goal

Run the maintainer-authorized, fixed-fixture S11 campaign as two sequential
Narval scheduler waves, retain every result and failure, and characterize the
two prespecified interval ratios without promoting any capability or release.

## 2. Implemented

Executed the sealed `HSQ09-H1T-IDENTIFIED-S11-01` driver in disjoint waves:
job `2734452` for seeds 1–1000 and job `2740214` for seeds 1001–2000. The
remote project directory retains one atomic two-row TSV receipt, SHA-256
sidecar, stdout log, and stderr log for each of the 2,000 seeds. The evidence
record now contains exact scheduler accounting, hash validation, reconciliation,
and its interpretation boundary.

## 3a. Decisions and Rejected Alternatives

Used the maintainer-authorized two-wave routing after the original one-array
submission was rejected by Narval's live 1,000 submitted-job limit. Rejected
any rerun, replacement of the 50 invalid/boundary interval rows, pooled
scientific label, capability flip, versioning, tag, registry action, or release.
The distinct `988eec…` S10 Totoro no-go is retained as a separate candidate and
is not rewritten as a result of this later `36ae…` campaign.

## 4. Files Touched

- `docs/dev-log/check-log.d/2026-09-09-h1two-identified-s11.md`
- `docs/dev-log/coordination-board.md`
- this report.

No engine, public API, R bridge, fixture, package version, capability-status,
or validation-debt row changed.

## 5. Checks Run

- Narval wave accounting: 1,000 `COMPLETED` / `0:0` tasks for each job.
- Remote receipt-sidecar SHA-256 verification: 2,000/2,000 passed.
- Local retrieved receipt-sidecar verification: 2,000/2,000 passed after
  mapping only the frozen Narval absolute directory prefix in the sidecar path.
- Local reconciliation: `requested=2000`, `rows=4000`,
  `interval_success=3950`, `covered=3833`, `coverage=0.970379746835443`,
  `mcse=0.00269753257002308`, and `claim_eligible=false`.
- S11 manifest validator and mutation test: passed before submission; fresh
  closeout re-verification is recorded in the local Unlazy ledger.
- Full `Pkg.test()`: exit 0, including Aqua and all registered HSquared
  package testsets.

## 6. Tests of the Tests

The S11 validator's deterministic positive and mutation suite covers the
manifest pins, false promotion/release fields, fixed seed range, driver/sbatch
hashes, retained row contract, and corrupt/absent governed values. Retention is
also independently checked by (a) remote sidecars, (b) locally copied sidecars,
and (c) the reconciler's exact seed × estimand inventory rather than a scheduler
success count alone.

## 7a. Issue Ledger

- Resolved routing constraint: Narval refused the original `1-2000%100` array
  because the account has a 1,000 submitted-job limit; the explicit two-wave
  amendment preserved one task per seed and the sealed inputs.
- Retained statistical failures: 48 ratio1 and 2 ratio2 rows are
  `invalid_or_boundary_interval`; none was removed or replaced.
- Open scientific boundary: only the identified H1-two DGM is characterized;
  no claim transfers to a new fixture, family, scale, or public surface.

## 8. Consistency Audit

The candidate commit, driver, fixture, 2,000-seed window, two ratio estimands,
and all-false promotion fields match the sealed manifest. Fisher's independent
review permits only a separate `directional-conservative` description for each
ratio (not their pooled bookkeeping rate). Rose independently found the retained
data-integrity chain complete and required the held state: the pooled rate is
above the available A2 `[0.93, 0.97]` calibrated-candidate band, and the
manifest remains `claim_eligible = false`.

## 9. What Did Not Go Smoothly

The initial single-array scheduler submission was not accepted because its task
count exceeded the account's live submitted-job limit. This was a routing
constraint, not a scientific failure. The two exact subsequent waves were
authorized separately; no wider array or alternative fixture was used.

The generic after-task checker validated this report's structure but could not
find Node to inspect the ignored Unlazy ledger. Its warning is not used as gate
evidence: the ledger was explicitly re-run with the project gate checker and
reported all six gates met.

## 10. Known Residuals

This is one fixed-DGM characterization, not calibrated interval evidence,
external-comparator evidence, R-public validation, a capability promotion, or
a release packet. The remote Narval directory is the durable retained evidence;
the local `/private/tmp` copy is a convenience mirror and is not the sole
record. S10/S11 work does not assign 0.10 or authorize 0.9.0 release actions.

## 11. Team Learning

The retained denominator must be read as a scientific result, not hidden behind
scheduler success: all 2,000 tasks can exit successfully while an interval can
properly be non-interpretable. When a cluster's submission limit splits an
approved array, a sequential amendment can preserve the original protocol only
if its ranges, inputs, and retention rules remain fixed.

## 12. Cross-Product Coverage

This covers ✓ two-wave S11 routing, task/receipt retention, hash integrity,
fixed-fixture reconciliation, and the constrained per-ratio characterization.
It does NOT cover ✗ calibration, H0/H3, another DGM, R↔Julia public parity,
external comparator evidence, capability promotion, versioning, tags, registry,
or release.
