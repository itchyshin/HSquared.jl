# After-task — A2 deterministic H1/H3 evidence infrastructure

**Date:** 2026-09-08
**Lane:** isolated Julia worktree `codex/hsq09-s2-evidence-infra`
**Goal:** close the authorized deterministic infrastructure only; do not fit,
run S10/S11, change the R bridge or public API, promote capability, or release.

## Active lenses and agents

The recorded A2 independent specification and code-quality reviews were
accepted. No new public claim was made in this closure pass.

## Files changed

The pre-existing A2 implementation is confined to
`sim/phase1_interval_coverage_ext.jl`,
`test/test_phase1_interval_coverage_ext.jl`, and
`tools/validate_hsq09_h1h3_evidence.jl`. This closure pass changed only the
ignored private Unlazy ledger and adds this factual receipt plus log entries.

## Checks run

- Focused deterministic harness: 95/95 assertions passed.
- Validator self-test printed `A2_EVIDENCE_INFRA_TESTS_OK` and
  `A2_MUTATION_CONTROLS_OK`.
- Full local `Pkg.test()` exited 0 and ended `Testing HSquared tests passed`.
- Unlazy fresh re-verification reran all three oracles with a 300-second
  per-check limit and reported 5/5 gates met.

## Public-claim audit

No `partial` or `planned` state was flipped. This is private deterministic
measurement/adjudication infrastructure, not calibration evidence and not a
claim that any H1/H3 interval is calibrated, directional-conservative, or
release-ready.

## Tests of the tests

The validator's deliberate mutations cover identity, hashes, duplicate rows,
Boolean counts, ranges, reconciliation, and H1-t non-promotion. The first
Unlazy re-verification intentionally exposed two weak ledger expectations and
an insufficient 120-second timeout; expectations were tightened to match
success-only output and the re-run used 300 seconds. No scientific test or
implementation was relaxed.

## Coordination

The A2 path lease was held only for its deterministic files, private ledger,
and this receipt/log update, then released. A separate S2 materialization lane
owns the full-input tool; this lane did not modify it.

## What did not go smoothly

The original table-formatted test output did not match a literal `EXPECT:`
string, and the package suite exceeds Unlazy's default 120-second cap. Both
were ledger defects, now visible and corrected before closure.

## Known limitations

No fixed scientific fixture was changed. No smoke, campaign, Totoro, or DRAC
compute occurred. No R bridge/public surface/version/tag/registry action is
authorized by A2.

## Next actions

Use this deterministic infrastructure only with the separately ratified S2
manifest and an approved compute pre-run. The materializer ownership conflict
must be explicitly resolved before an array runner is edited or submitted.
