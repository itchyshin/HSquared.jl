## 1. Goal

Materialize the ratified H3 `r_g` and `r_am` interval-evidence fixture, manifest, validator, and deterministic local tests without S10/S11 compute or a public-surface change.

## 2. Implemented

Created one closed, source-inert fixture with two separately specified cells, a closed evidence manifest, a SHA-256 validator, and a normal-test include. The fixture pins the identified designs, distinct seeds, exact initializers, and non-pooled negative controls. It performs no fit.

## 3a. Decisions and Rejected Alternatives

Used the established 80-animal three-record `r_g` DGP rather than the retained failed tiny S10 cell. Used the 996-animal confound-broken `r_am` DGP rather than its failed tiny maternal cell. The `r_g` cold start is explicitly `initial=nothing`; the `r_am` start is the existing neutral `G_dm=I2`, `sigma_e2=1.0`, not a truth-valued initializer. No S10 fit, alternative seed, retry, R/bridge edit, promotion, or release action was taken.

## 4. Files Touched

- `.git/info/exclude` (local-only `.unlazy/` exclusion)
- `.unlazy/hsq-09/PLAN.md`, `GATES.md`, and `gates/leaf-s15-h3-materialization.md`
- `Manifest.toml` (copied unchanged from the sealed H3 candidate; ignored)
- `test/fixtures/h3_replacement_interval/fixture.toml`
- `sim/h3_replacement_interval_fixture.jl`
- `tools/validate_hsq09_h3_replacement_s2.jl`
- `test/test_hsq09_h3_replacement_s2.jl` and `test/runtests.jl`
- `docs/dev-log/evidence/2026-09-09-h3-replacement-s2-manifest.toml`
- `docs/dev-log/decisions/2026-09-09-h3-replacement-protocol-draft.md`
- `docs/dev-log/check-log.d/2026-09-09-h3-replacement-s2-materialization.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-09-09-h3-replacement-s2-materialization.md`

## 5. Checks Run

- Test-first run failed as expected because the validator did not yet exist.
- A second test-first run failed as expected because the governed-input mutation control did not yet exist.
- Focused test: `16/16` passed.
- Validator `--validate`: emitted both H3 replacement fixture and manifest success markers.
- Validator `--self-test`: emitted the mutation-control success marker.
- Single-threaded `Pkg.test()`: completed successfully, including the new normal-test include.
- `git diff --check` passed before the full package verification run.

## 6. Tests of the Tests

The initial focused test failed on the absent validator, then passed after its implementation. The added mutation-control test failed on the absent helper, then passed after implementation. The final self-test rejects every governed manifest field, an unknown section, and mutated fixture, driver, focused-test, or lockfile bytes.

## 7a. Issue Ledger

- Fixed locally: the worktree did not inherit the ignored `Manifest.toml`; the exact sealed lockfile was copied and its SHA-256 matched the source candidate.
- Deferred deliberately: any fit, S10 result, S11 routing, or calibration claim.
- Tooling defect observed: the generic closeout helper resolves output relative to its own Shinichi checkout, not the supplied H3 worktree. The accidental template was not used for this report.

## 8. Consistency Audit

The retained S10 no-go, H3 replacement decision record, existing multivariate cold-start recovery harness, and direct-maternal confound-breaking recovery harness were inspected. `src/`, public API, R bridge, capability-status rows, validation-debt rows, package version, and release records were not changed. The normal test runner now includes the new source-inert focused test.

## 9. What Did Not Go Smoothly

`node` was absent from the shell PATH, so Unlazy parsing initially failed. The locally bundled Node runtime was found and used. The generic closeout helper also wrote a template to an unrelated Shinichi checkout because it anchors paths to its own installation; the correct report was written directly in this isolated worktree.

## 10. Known Residuals

No S10 run has used either new seed, so neither cell has a convergence or interval receipt. The selected seeds are frozen only in this candidate materialization and still require review in a separate S10 authorization. No coverage, calibration classification, R-twin parity, public claim, or release eligibility has been established.

## 11. Team Learning

Memory receipt: the H3 decision record, `hsquared-rehydrate`, validation-canon, Unlazy, and the cross-repo guards shaped the work. The retrieved project dossier reinforced the R-public/Julia-engine boundary; direct source records decided the exact fixture choices.

Golden Set: not in scope. This was a source-inert preparation slice; the relevant protection is the deterministic validator plus its mutation controls.

No durable-memory file was changed because the maintainer did not request a memory update.

## 12. Cross-Product Coverage

This covers ✓ a Julia-only, locally sealed fixture specification for the two separate H3 interval cells; ✓ a copied exact environment lock; ✓ deterministic manifest validation; ✓ negative mutation controls; and ✓ normal-test inclusion.

It does NOT cover ✗ either actual H3 fit or interval; ✗ S10/S11, Totoro, DRAC, or remote compute; ✗ calibration or coverage; ✗ the R twin, bridge, or public API; ✗ any capability/status flip; ✗ versioning, integration, tags, registry action, or release.
