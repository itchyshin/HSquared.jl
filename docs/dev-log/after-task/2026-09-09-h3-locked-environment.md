# After-task — H3 locked environment

## 1. Goal

Make the isolated H3 candidate locally reproducible without changing science or
authorizing compute.

## 2. Implemented

Materialized `Manifest.toml`, instantiated it, and recorded its provenance and
hash.

## 3a. Decisions and Rejected Alternatives

The compatible sibling lock was independently checked before reuse; no fresh
unbounded dependency resolution was requested.

## 4. Files Touched

- `Manifest.toml`
- `docs/dev-log/evidence/2026-09-09-h3-locked-environment.md`
- `docs/dev-log/check-log.d/2026-09-09-h3-locked-environment.md`
- `docs/dev-log/after-task/2026-09-09-h3-locked-environment.md`

## 5. Checks Run

`Pkg.instantiate()` precompiled HSquared; focused scaffold **102/102** and
ordinary `Pkg.test()` both passed.

## 6. Tests of the Tests

The focused scaffold includes mutation controls for retained H1/H3 evidence;
the package suite is an independent ordinary regression check.

## 7a. Issue Ledger

The lock is local-only and still needs an explicit H3 smoke authorization
before it may be used for compute.

## 8. Consistency Audit

The manifest SHA is pinned in the superseding unarmed H3 decision manifest.

## 9. What Did Not Go Smoothly

The initial candidate lacked a lockfile, preventing exact-head package tests.

## 10. Known Residuals

The lock does NOT cover scientific H3 evidence, R parity, or release.

## 11. Team Learning

An isolated candidate needs a lockfile before a green local package test can
mean reproducible verification.

## 12. Cross-Product Coverage

This receipt covers only Julia dependency reproducibility.  It does NOT cover
the R twin, H3 scientific computation, DRAC, capability promotion, or release.
