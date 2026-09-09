# After-task — 2026-09-09 S9-A4 source-inert supersession

## 1. Goal

Create the fresh S9-A4 provenance record for the settled A4 R/Julia candidates,
without rewriting historical S9 or starting any compute.

## 2. Implemented

Added a candidate-pinned TOML manifest, a dependency-free Julia validator, a
positive/mutation test, a supersession receipt, and this closeout record.

## 3a. Decisions and Rejected Alternatives

Used a distinct `HSQ09-S9-A4` record rather than re-pinning old S9: the old
Julia basis is not an ancestor of the A4 candidate, and the old R object is not
available in the A4 R checkout. Rejected any smoke or campaign work because the
current authorization remains source-inert only.

## 4. Files Touched

- `docs/dev-log/evidence/2026-09-09-hsq09-s9-a4-evidence-manifest.toml`
- `docs/dev-log/evidence/2026-09-09-hsq09-s9-a4-supersession.md`
- `tools/validate_hsq09_s9_a4_manifest.jl`
- `test/test_hsq09_s9_a4_manifest.jl`
- `docs/dev-log/check-log.d/2026-09-09-s9-a4-evidence-manifest.md`
- this after-task report.

## 5. Checks Run

The focused test passed **3/3** assertions and emitted
`HSQ09_S9_A4_TESTS_OK`. The manifest validator emitted
`HSQ09_S9_A4_MANIFEST_OK`. The root Unlazy ledger passed **3/3** gates; the
leaf recheck passed **2/2** gates.

## 6. Tests of the Tests

The test began red because its validator did not exist. It then rejected five
purposeful mutations: compute authorization, Julia pin, legacy digest, governed
input hash, and an unknown TOML field. The historical-byte gate independently
matched the old manifest SHA-256.

## 7a. Issue Ledger

- Fixed: temporary `/private/tmp` worktrees were purged externally; rehydrated
  the exact pinned Julia/R candidates in durable local scratch.
- Fixed: the initial Unlazy relative paths used the ledger directory; gates now
  declare the repository root explicitly.
- Deferred: S10/S11 and all simulation work, by scope and the planned rest.

## 8. Consistency Audit

Checked all eleven governed inputs, both exact candidate identities, source-only
dirty-path policy, all-false action/result fields, exit-78 refusal state, and
historical S9 content. No public/API/bridge/capability-status surface changed.

## 9. What Did Not Go Smoothly

The shared temporary directory disappeared mid-arc. This was environmental, not
an artifact mutation; the durable worktrees and the focused red-green test
recovered the slice.

## 10. Known Residuals

No coverage, calibration, recovery, comparator agreement, smoke output, remote
execution, public behavior, promotion, or release claim exists. Full package
and documentation suites were not rerun because this is a source-inert
tooling/documentation slice; the dedicated validator/test are the direct oracle.

## 11. Team Learning

For an evidence supersession, preserve the earlier record by digest and Git
object, then pin a fresh record; never mutate history to make a new candidate
look continuous. A stable worktree is required for retained provenance work.

## 12. Cross-Product Coverage

This covers ✓ S9-A4 pins, governed hashes, historical-S9 integrity, and
false-action fields. It does NOT cover ✗ S10/S11, any simulation/DRAC/Totoro
run, numerical claims, R-public activation, capability promotion, versioning,
tags, registry, CI, or release.
