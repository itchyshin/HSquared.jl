# After-task — 2026-09-07 S8 Julia NG-1 claim reconciliation

**Scope:** documentation-only reconciliation from base
`946c597a6180620ece585aa583e8e07d5cb1fe01`.  The product change is three
ledger rows; this report and its paired check-log shard are the provenance
receipt.  No executable source, test, API, or public-release surface changed.

**Active lens:** independent Rose claim review (one correction, then final
**CLEAN**).  The assigned S8 documentation lane owned the three ledger rows;
Rose reviewed them independently and made no edits.

## 1. Goal

Make the existing Julia NG-1 scale-summary evidence legible and consistent in
the public-claims, capability-status, and validation-debt ledgers, without
turning that documentation reconciliation into a new capability, promotion, or
validation claim.

## 2. Implemented

Added one aligned NG-1 row to each of the three ledger sources.  Each records
the existing engine-only `nongaussian_scale_summary` contract as **partial
(experimental; not covered)**, retains the focused Gate-A test and S7
cross-twin parity reference `e6a1ce4`, and states its negative space: no
public-R promotion and no non-Gaussian REML, calibration, coverage,
comparator, or fitted-behavior claim.

The S8 functional change is exactly these three documentation rows.  This
after-task report and the paired check-log shard record their evidence; no
production implementation, test source, export, or generated documentation
source was added or changed for S8.  The documentation build's generated,
timestamp-only `docs/src/validation-status.md` noise was restored and is not
part of the S8 diff.

## 3a. Decisions and Rejected Alternatives

Kept one narrow engine-contract statement rather than relabelling the existing
helper as a public R feature or a fitted non-Gaussian result.  Rejected a
status promotion, covered-count change, version or release wording, new API
wording, and any claim about calibration, coverage, comparator agreement, or
fitted behavior.

An independent Rose review required a correction to the initial
claim-surface wording.  That correction was applied before closeout; the
post-correction scope-specific verdict was **CLEAN**.  The correction is
evidence of editorial scrutiny, not new numerical or behavioral evidence.

## 4. Files Touched

- `docs/design/06-public-claims-register.md` — one NG-1 ledger row.
- `docs/design/capability-status.md` — one NG-1 ledger row.
- `docs/design/validation-debt-register.md` — one `V6-NG-1` ledger row.
- `docs/dev-log/after-task/2026-09-07-s8-julia-ng1-claim-reconciliation.md`
  — this receipt.
- `docs/dev-log/check-log.d/2026-09-07-s8-julia-ng1-claim-reconciliation.md`
  — paired check-log shard.

No `src/`, `test/`, `Project.toml`, tracked `Manifest.toml`, export, or R-twin
file belongs to this S8 change.  A local ignored manifest was instantiated only
to make the pre-existing focused test runnable and produced no tracked diff.

## 5. Checks Run

- Initial focused invocation,
  `~/.juliaup/bin/julia --project=. test/gate_a_nongaussian.jl`, stopped before
  testing because this fresh worktree lacked the git-ignored `Manifest.toml`.
  This was an **environmental setup failure**, not a Gate-A contract-test
  failure.
- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.instantiate()'` completed
  locally to materialize that ignored environment; it left **no tracked diff**.
- Re-running the focused test,
  `~/.juliaup/bin/julia --project=. test/gate_a_nongaussian.jl`, **passed** with
  marker `HSQ09_NG_GATEA_TESTS_OK`.
- `~/.juliaup/bin/julia --project=docs docs/make.jl` **passed**; the retained
  shell marker is `S8_DOCS_BUILD_OK`.  Its output contained the existing 43
  unincluded-docstring warnings.  They were counted and retained as pre-existing
  documentation noise, not claimed as fixed or newly introduced by S8.
- Independent Rose review required one correction and the final re-review was
  **CLEAN**.

No full package suite, CI run, comparator run, calibration/coverage run, or
compute campaign is claimed by this receipt.

## 6. Tests of the Tests

S8 changed no executable code or test, so it adds no new mutation test.  The
focused marker demonstrates that the already-existing Gate-A contract test ran
after the environment was made runnable; it does not independently validate the
new prose.  The independent Rose correction is the editorial negative control:
the first claim wording was not accepted, the correction was made, and only the
post-correction surface received the final **CLEAN** verdict.

The documentation build verifies that the reconciled sources build locally, but
the 43 inherited unincluded-docstring warnings are not treated as passing
evidence for the NG-1 claim.

## 7a. Issue Ledger

- **Resolved:** the NG-1 scale-summary contract now has synchronized,
  narrow-status ledger entries in all three required Julia claim surfaces.
- **Resolved:** an independent Rose wording correction was applied before the
  final **CLEAN** review.
- **Environmental note:** a fresh worktree's absent ignored `Manifest.toml`
  initially prevented the focused test from starting; local instantiation
  resolved setup only and did not alter tracked content.
- **Deferred:** every G6–G10 action; any R bridge/API work; new fitting,
  calibration, coverage, comparator, or recovery evidence; CI; release,
  versioning, tagging, registry, deployment, and compute work.

## 8. Consistency Audit

The three new rows were read together against the existing Gate-A after-task
and check-log receipts.  They agree on the engine-only scope, the admissible
Poisson/Binomial contract, the Bernoulli-as-Binomial(1) normalization, the
defined/undefined scale boundaries, retained Gate-A/S7 evidence, and the
`partial (experimental; not covered)` status.

They also agree on what remains absent: no non-Gaussian REML label, no public-R
promotion, and no numerical-evidence claim.  `docs/src/validation-status.md`
had only generated timestamp noise during the documentation build; that noise
was restored and is not part of the three-row S8 claim diff.

## 9. What Did Not Go Smoothly

The first focused test invocation could not start because this worktree did not
have its ignored `Manifest.toml`.  Local `Pkg.instantiate()` repaired that
environmental precondition without a tracked diff.  The successful
documentation build also emitted 43 pre-existing unincluded-docstring warnings;
they remain a documented residual rather than being silently attributed to, or
resolved by, S8.

## 10. Known Residuals

This receipt records wording and local evidence reconciliation only.  It does
not establish a new API, R route, fitted behavior, numerical calibration,
coverage property, external comparator agreement, recovery result, CI status,
version, count, or release state.

**It does NOT authorize G6–G10, release, or compute.**

## 11. Team Learning

For a documentation-only claim reconciliation, keep behavioral evidence and
editorial evidence separate: the focused marker confirms the pre-existing
contract test ran, while an independent Rose review is needed to test whether
the prose overreaches.  When a fresh Julia worktree lacks an ignored manifest,
record that inability to start separately from the eventual test result and
record whether instantiation changes tracked state.

The existing Gate-A receipts supplied the technical context for this narrow
closeout.  No durable-memory update or Golden-Set mutation was authorized by
this receipt-only lane.

## 12. Cross-Product Coverage

Covers ✓ the three Julia ledger rows, their mutual claim boundary, the local
focused Gate-A test execution marker after environment setup, the local
documentation build marker, and the independent Rose wording correction plus
final **CLEAN** audit.

It does NOT cover ✗ G6–G10; any R API or bridge change; new Julia API or export;
fitted behavior; recovery; calibration; interval or coverage evidence; external
comparators; capability promotion; covered/public counts; versioning; CI;
release, registry, deployment, or tagging; or any Totoro/DRAC/local compute
campaign.  In particular, this documentation receipt does NOT authorize
G6–G10, release, or compute.
