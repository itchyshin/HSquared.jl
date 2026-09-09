# After-task — H3 sealed smoke inputs

## 1. Goal

Prepare exact locally verifiable bytes for a future separately authorized H3
Totoro smoke.

## 2. Implemented

Created and verified a complete Git bundle plus a sealed copy of the ignored
Julia lockfile; recorded all hashes.

## 3a. Decisions and Rejected Alternatives

No branch pull or remote checkout was used.  The sealed bundle is the only
prepared code input; transfer remains a later decision.

## 4. Files Touched

- `docs/dev-log/evidence/2026-09-09-h3-sealed-smoke-inputs.md`
- `docs/dev-log/check-log.d/2026-09-09-h3-sealed-smoke-inputs.md`
- `docs/dev-log/after-task/2026-09-09-h3-sealed-smoke-inputs.md`

## 5. Checks Run

`git bundle verify` passed and all three SHA-256 values were measured.

## 6. Tests of the Tests

Bundle verification independently proved the bundle’s complete history and
HEAD; SHA-256 checks bind the bytes intended for later transfer.

## 7a. Issue Ledger

The sealed files are local-only.  H3 smoke authorization remains absent.

## 8. Consistency Audit

The bundle contains the driver matching the H3 candidate receipt; the lock and
driver hashes match the pinned records.

## 9. What Did Not Go Smoothly

The ignored lockfile cannot travel inside a Git bundle, so it is explicitly
sealed as a separate named input.

## 10. Known Residuals

No remote hash verification, precompile, or numerical output exists.

## 11. Team Learning

An ignored lockfile must be named and hashed independently or an “exact
candidate” transfer is not actually reproducible.

## 12. Cross-Product Coverage

This receipt covers local H3 smoke inputs only.  It does NOT cover remote
installation, the R twin, H3 computation, DRAC, promotion, versioning, tags,
registry actions, or release.
