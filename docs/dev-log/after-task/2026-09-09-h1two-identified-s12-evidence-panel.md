# After-task — 2026-09-09 H1-two identified S12 evidence panel

## 1. Goal

Make the completed, retained S11 two-wave Narval record independently
inspectable without changing an estimator, fixture, public API, capability,
compute plan, or release state.

## 2. Implemented

Curie completed a retention/replay review; Fisher adjudicated the fixed-DGM
interval reading; Rose performed the claim audit. The final records preserve
their bounded verdicts rather than treating a check-log self-attestation as a
review.

- Closed the S11 manifest schema and mutation-tested every governed value plus
  an unknown section.
- Added a deterministic retained-failure reconciliation fixture.
- Added a compact remote-evidence index, separate Fisher/Rose artifacts, and a
  completion panel that states the held boundary and all unpaid release gates.
- Repaired historical-versus-completed check-log wording, the S9/S11
  authorization cross-link, and the two-effect coverage-calibrated-interval
  debt wording.

## 3a. Decisions and Rejected Alternatives

Kept S11 as a fixed-DGM, evidence-only characterization and rejected a pooled
scientific label, calibrated/point claim, cross-DGM transfer, rerun, capability
flip, versioning, tag, registry action, and release. The prior self-attested
reviews were rejected as circular provenance and replaced by separate records.

## 4. Files Touched

The scoped delta is limited to the S11 validator/tests and S11/S12 evidence,
review, decision, check-log, after-task, S9 cross-link, and two-effect debt
records. No `src/`, public API, R bridge, scientific fixture, package-version,
or release file changed.

## 5. Checks Run

- `test/test_h1two_identified_s11_manifest.jl`: 17/17 passed.
- `test/test_reconcile_h1two_identified_s11.jl`: 12/12 passed, including a
  synthetic retained-failure inventory.
- `tools/validate_h1two_identified_s11_manifest.jl --self-test`:
  `H1T_S11_MANIFEST_MUTATIONS_OK`.
- Full `Pkg.test()`: passed after rerunning outside the sandbox; the first
  attempt could not create Julia's per-user `manifest_usage.toml.pid` lock.
- The retention-index TOML parsed successfully.
- Unlazy `S12-GATES.md`: 5/5 met; runnable G0 reverified.
- `git diff --check`: clean; no tag contains `HEAD`; read-only GitHub release
  listing returned no rows.

## 6. Tests of the Tests

The manifest test first failed when an invented section and a false
`calibrated` interpretation were accepted; the validator was then made
closed-schema and the same tests passed. The reconciliation test now directly
injects two retained failure rows and proves they remain in the inventory.

## 7a. Issue Ledger

- Resolved: the manifest previously accepted ungoverned sections and an
  unvalidated calibration interpretation.
- Resolved: the record claimed independent review without a distinct artifact.
- Open: H0/H3, calibration, final R/public parity, comparator scope, and Gate
  B remain unpaid.

## 8. Consistency Audit

The S12 lane held narrow leases for its validator, tests, evidence records,
claim repairs, and closeout files. The Dropbox R checkout was not modified.
The remote Narval project directory remains the authoritative retained store;
the local `/private/tmp` mirror is only a replay convenience.

The only retained interpretation is separate, conditional,
directional-conservative coverage for `ratio1` and `ratio2` at the fixed S9
replacement DGM. The pooled rate is bookkeeping only. No calibrated, point,
pooled, cross-DGM, R-public, capability, version, tag, registry, or release
claim is made.

## 9. What Did Not Go Smoothly

The first full Julia test invocation stopped before tests because the sandbox
forbids Julia's normal usage-lock file. The exact command passed outside the
sandbox. A first aggregate remote-hash shell probe produced no digest, so the
index reports only freshly observed scheduler/inventory counts and the local
mirror's independently computed TSV inventory hash; it does not falsely label
that mirror as authoritative.

## 10. Known Residuals

S11 remains a held, fixed-DGM evidence checkpoint. H0/H3, a completed broad
calibration protocol, R-public/R–Julia parity at the final public contract,
external comparator scope, complete candidate reconciliation, and explicit
maintainer Gate B approval are all still required before a 0.9.0 release
decision. Do not promote or release from this record.

## 11. Team Learning

An all-green scheduler array does not itself establish interval evidence: the
retained interval-success denominator and failure reasons must remain visible.
Likewise, an audit statement inside its own check log is not independent review;
the reviewer record must be a distinct artifact.

## 12. Cross-Product Coverage

This panel covers validator integrity, retained-failure accounting, remote
receipt indexing, and claim-record consistency for S11 only. It does not cover
new estimator behavior, R-facing parity, another scientific fixture, H0/H3,
calibration, comparator evidence, promotion, or release.
