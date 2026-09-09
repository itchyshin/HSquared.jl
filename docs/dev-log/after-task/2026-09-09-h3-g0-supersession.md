# After-task — H3 G0 candidate supersession

## 1. Goal

Update the unarmed H3 packet to the tested candidate and lockfile without
authorizing any scientific action.

## 2. Implemented

Pinned the updated commit, driver hash, and environment-manifest hash in the
closed H3 G0 manifest and decision card.

## 3a. Decisions and Rejected Alternatives

The prior hash record was not retained as current because it predated the
convergence-accounting repair.  Authorization fields were deliberately not
changed.

## 4. Files Touched

- `docs/dev-log/decisions/2026-09-09-h3-g0-prerun-card.md`
- `docs/dev-log/evidence/2026-09-09-h3-g0-prerun-manifest.toml`
- `tools/validate_hsq09_h3_g0_manifest.jl`
- `docs/dev-log/check-log.d/2026-09-09-h3-g0-supersession.md`
- `docs/dev-log/after-task/2026-09-09-h3-g0-supersession.md`

## 5. Checks Run

The focused H3 G0 manifest test and validator mutation self-test passed after
the update.

## 6. Tests of the Tests

The validator mutates each governed value, including the new lock hash, and
rejects unknown manifest sections.

## 7a. Issue Ledger

H3 remains unratified for compute; no smoke or campaign receipt exists.

## 8. Consistency Audit

Decision card, manifest, validator, and current file hashes agree.  Every
authorization field is false.

## 9. What Did Not Go Smoothly

The prior packet was internally consistent but became stale after a validity
fix, demonstrating why frozen hashes must be superseded rather than narrated.

## 10. Known Residuals

No scientific H3 evidence, R parity, promotion, or release has been supplied.

## 11. Team Learning

The governed environment lock belongs beside candidate and driver hashes, not
as an unrecorded local prerequisite.

## 12. Cross-Product Coverage

This supersession covers the Julia H3 pre-run packet only.  It does NOT cover
the R twin, H3 numerical evidence, DRAC, promotion, versioning, tags,
registry actions, or release.
