# After-task: exact-current Gaussian FA review

## 1. Goal

Update A2 with exact-current Julia FA source review and same-model REML
comparison, correcting stale source attribution without promoting FA.

## 2. Implemented

Recorded conditional current-source dispositions, an independently fitted
same-model R/Julia comparison, the earlier-review snapshot correction, and a
fitted trait-permutation test reviewed on its exact hash. A2 remains open.

Active lenses: Kirkpatrick reviewed the G-matrix contract; Noether reviewed
the covariance map and estimand; Rose audited claims and evidence. All three
reviews were read-only and tied to the exact source hash in the receipt.

## 3a. Decisions and Rejected Alternatives

- Kept the T=4, K=1 FA capability bounded and experimental/partial at the
  public R route.
- Treated the near-floor same-model agreement as one numerical comparison,
  not recovery or uniqueness-identification evidence.
- Did not run the held 200-seed study, estimated at about 8.1 hours.
- Made no release, submission, merge, tag, or GPU changes.

## 4. Files Touched

- `GATES.md`
- `docs/dev-log/source-review/2026-09-29-supplemental-panel-findings.md`
- `docs/dev-log/source-review/2026-09-29-fa-exact-current-review.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-09-29-fa-exact-current-review.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-09-29-fa-exact-current-review.md`
- `test/test_multivariate_fa_multistart.jl`

## 5. Checks Run

- Exact-source focused Julia tests: 91 assertions passed across the FA
  uniqueness map and multistart, optimizer, unit, and permutation tests.
- Independent R 4.6.0 BFGS fit: converged; 1.033 seconds.
- HSquared.jl Julia 1.10.0 Nelder-Mead fit: converged; 5,500 iterations,
  2.565 seconds after package load.
- Maximum absolute R/Julia covariance differences: `7.2491e-6` for G and
  `1.5804e-5` for R. Cross-evaluations reproduce each objective to printed
  precision.
- The updated multistart file passed 62/62 assertions, including 11 fitted
  trait-permutation checks. Kirkpatrick and Noether passed the exact test
  hash's mapping review.
- `git diff --check` passed; the after-task structure check passed; prose
  checks returned zero findings. The full after-task command exits nonzero
  at its acceptance-ledger stage because A2, E1, V3, and other programme
  ledgers remain open. This receipt records that active state rather than
  marking those gates abandoned.

## 6. Tests of the Tests

The uniqueness test differentiates the production loading/log-uniqueness
map and detects rank 8 at a generic point versus rank 7 at the sparse-loading
counterexample. Fit tests separately exercise optimizer guards, start
selection, scale transformation, and diagnostics. The same-model comparison
constructs REML independently in base R and uses a matching pedigree, fixed
trait intercepts, covariance structures, floor, and REML constant. These
checks do not estimate recovery frequency or likelihood information. The
trait-order test maps response, starts, and labels together, then checks fitted
covariances and trait effects under one seeded interior fixture.

## 7a. Issue Ledger

- Corrected: previous supplemental note called the `a28d88...` review
  current even though current source is `fc41...`.
- Added: exact-current Kirkpatrick and Noether dispositions and Rose audit.
- Added: same-model R/Julia comparison on the current source hash.
- Closed: fitted trait-order mapping for one seeded T4K1 fixture.
- Open: routine-start recovery, likelihood information, broader trait-order
  coverage, held multi-seed run, and remaining source spans.

## 8. Consistency Audit

The current source remains `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670`.
The capability and validation-debt rows remain unchanged. The current fit's
two floor-adjacent uniqueness estimates and all inference limits are stated
in the receipt. A2, E1, and V3 remain open.

## 9. What Did Not Go Smoothly

The source review ledger mixed multiple dirty-tree snapshots. Exact byte
hashes exposed that the earlier conditional review was not pinned to the
current FA source. A fresh read-only panel review and current-source comparator
were needed before recording current evidence.

## 10. Known Residuals

One truth-informed fixture does not establish routine-start recovery, a
population recovery rate, local likelihood information, genetic/residual
separation, uniqueness identification, uncertainty calibration, or general
R-Julia parity. Two fitted uniqueness estimates were within `5.1e-6` of the
absolute floor.
The held 200-seed study still requires Shinichi's approval.

## 11. Team Learning

Dirty worktrees require source hashes on both review claims and fit receipts.
A successful same-model comparison can validate objective/implementation
agreement on one cell while simultaneously exposing a boundary solution that
must remain visible in the interpretation.

## 12. Cross-Product Coverage

This slice covers Julia T=4, K=1 FA source evidence and review records. It does NOT cover the R bridge, capability promotion, A2/E1/V3 completion, GPU work, or submission, merge, or tag.
