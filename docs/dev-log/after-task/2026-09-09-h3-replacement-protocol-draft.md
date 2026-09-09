# After-task — H3 replacement protocol draft

## 1. Goal

Turn the retained sealed-H3 S10 no-go into a reviewable scientific choice
without changing a fixture, source, public contract, compute state, or release
state.

## 2. Implemented

Added one unratified decision draft.  It gives a separate symbolic contract,
identified DGM, interval method, negative control, S10 success rule, and S11
denominator for `r_g` and `r_am`.

## 3a. Decisions and Rejected Alternatives

The replacement draft uses the existing identified repeated-record and
direct–maternal point-recovery structures as candidates.  It does not describe
either as interval evidence.  It rejects retrying the tiny failed S10 cells,
pooling the two estimands, inventing an unreviewed seed, or treating the
authorization for the sealed candidate as authority for a changed fixture.

## 4. Files Touched

- `docs/dev-log/decisions/2026-09-09-h3-replacement-protocol-draft.md`
- `docs/dev-log/after-task/2026-09-09-h3-replacement-protocol-draft.md`

## 5. Checks Run

- Read the current H3 driver, ADEMP predeclaration, direct–maternal recovery
  receipt, sealed S10 receipt, and no-go decision card.
- `git diff --check` passed before recording the decision draft.

## 6. Tests of the Tests

Not applicable: this is source-inert decision documentation.  The protocol
requires future fixture/manifest validation plus explicit negative controls
before a newly authorized S10 can be run.

## 7a. Issue Ledger

- Held: H3 interval formation and calibration for both `r_g` and `r_am`.
- Held: source/fixture/manifest work, replacement S10, S11/DRAC, promotion,
  versioning, tags, registry actions, and release.
- Decision needed: ratify this scientific contract or remove H3 intervals from
  the 0.9.0 target.

## 8. Consistency Audit

The draft agrees with the S10 no-go: zero successful intervals from the sealed
candidate remains retained evidence.  It leaves capability, validation-debt,
and public-claim registers unchanged.  It names `r_g` and `r_am` as distinct
targets with independent denominators.

## 9. What Did Not Go Smoothly

The sealed tiny S10 fixture did not produce eligible intervals, so existing
point-recovery receipts had to be carefully separated from the missing
interval evidence.

## 10. Known Residuals

No new fixture has been materialized, no seeds/cold starts have been sealed,
and no S10 or S11 evidence exists for the proposed replacements.

## 11. Team Learning

Symbolic alignment made the decisive distinction visible: the correlation
formula, incidence structure, and estimator differ between `r_g` and `r_am`.
They cannot share a smoke result or a pooled coverage claim.

## 12. Cross-Product Coverage

This covers only the Julia H3 decision draft.  It does not cover the R twin,
the R bridge or API, non-Gaussian scope, any simulation/fit/DRAC work,
capability promotion, or release.
