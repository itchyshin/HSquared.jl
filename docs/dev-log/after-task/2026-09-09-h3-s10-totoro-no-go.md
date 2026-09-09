# After-task — H3 S10 Totoro PATH_ONLY no-go

## 1. Goal

Run the expressly authorized single-thread H3 PATH_ONLY smoke for the sealed
`r_g` and `r_am` candidate, retain every outcome, and decide only whether S11
could proceed.

## 2. Implemented

Added a source-inert S10 manifest, validator, mutation-tested launcher, and
focused test.  The launcher now requires an explicit Julia executable when
`julia` is absent from `PATH`.  It then ran exactly one actual H3 smoke on a
fresh hash-verified Totoro checkout and retained its rejected result directory.

## 3a. Decisions and Rejected Alternatives

The first technical attempt did not start Julia (`exit 127`) and is retained
separately.  Its zero-fit receipt justified a launcher-only repair, not any
scientific-fixture or source change.  The repaired run is the one actual smoke.
No rerun, fixture adjustment, S11 submission, promotion, or release was taken:
the sealed S10 validator rejected both cells.

## 4. Files Touched

- `tools/run_hsq09_h3_s10_totoro.sh`
- `tools/validate_hsq09_h3_s10_smoke.jl`
- `test/test_hsq09_h3_s10_smoke.jl`
- `docs/dev-log/evidence/2026-09-09-hsq09-h3-s10-manifest.toml`
- `docs/dev-log/check-log.d/2026-09-09-h3-s10-totoro-no-go.md`
- `docs/dev-log/after-task/2026-09-09-h3-s10-totoro-no-go.md`
- `docs/dev-log/coordination-board.md`

## 5. Checks Run

- H3 S9-A4 prerequisite validator: `HSQ09_S9_A4_MANIFEST_OK`.
- Focused H3 S10 test: 32/32 pass after the explicit-Julia repair; launcher
  shell syntax and `git diff --check` passed.
- Full Julia `Pkg.test()` returned exit success in the local package lane; its
  verbose terminal capture was truncated, so no count is claimed here.
- Totoro bundle and `Manifest.toml` SHA-256 values matched locally and remotely;
  isolated `Pkg.instantiate()`/`Pkg.precompile()` completed.
- The one actual S10 driver ran in 12.04 s, but the validator failed because
  `r_g` was non-converged and `r_am` had non-positive-definite information.

## 6. Tests of the Tests

The new launcher-contract assertion initially failed before the explicit Julia
route was implemented and then passed.  The existing validator mutation test
rejects an altered `claim_eligible` field.  The real retained driver rows then
exercised the validator's non-convergence rejection, independently of the unit
test.

## 7a. Issue Ledger

- Fixed: Totoro's Julia executable is not on `PATH`; the source-inert launcher
  now accepts `HSQ09_H3_S10_JULIA_BIN` and refuses an unavailable executable.
- Deferred: H3 `r_g` smoke convergence and `r_am` positive-definite information.
  They require a new scientific decision/fixture amendment before any rerun.
- Held: S11, all promotion fields, versioning, tagging, registry work, and release.

## 8. Consistency Audit

The launcher still locks the original H3 engine SHA, driver digest, and ignored
lockfile digest, and checks no `src/` difference from the sealed candidate.
The driver command names only `h3_rg,h3_ram`; its validator requires a finite,
strictly interior interval for each.  Capability and validation-debt rows were
read but left unchanged because no H3 scientific claim was earned.

## 9. What Did Not Go Smoothly

The original launcher assumed `julia` was on Totoro's `PATH`, despite the
recorded absolute Julia installation.  That produced a retained zero-fit
technical failure.  After the tested launcher correction, the actual smoke
exposed the scientific no-go rather than a platform problem.

## 10. Known Residuals

The smoke is not an interval-calibration result: it has zero successful
intervals.  The supplied S10 authorization does not determine a replacement H3
fixture or authorize a rerun.  The R twin, public contract, and release state
remain untested and unchanged by this S10 result.

## 11. Team Learning

Memory receipt: the live HSquared instructions, Unlazy gates, and compute
routing controlled this run; the explicit maintainer authorization and sealed
repository records, rather than inferred status, controlled scope.

Golden Set: not in scope; this was a source-inert launcher/evidence slice, with
focused validator and mutation tests used instead.

A host precompile proves that an absolute Julia binary works; it does not prove
that a shell-launched driver will find `julia`.  Governed launchers must validate
the exact executable they will invoke.

## 12. Cross-Product Coverage

This covers one Julia-engine H3 PATH_ONLY attempt for the sealed `r_g` and
`r_am` fixture, its exact bytes, one-thread resource receipt, and retained
failure accounting.  It does NOT cover a changed H3 fixture, any retry, H3
calibration or coverage, S11/DRAC, the R bridge or public API, non-Gaussian
behaviour, capability promotion, versioning, tags, registry actions, or release.
