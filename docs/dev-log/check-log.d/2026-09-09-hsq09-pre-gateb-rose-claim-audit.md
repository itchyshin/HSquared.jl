# Pre-Gate-B Rose-style public-claim audit — CLEAN WITH LIMITATIONS

## Scope

Read the isolated current Julia candidate's `README.md`, `ROADMAP.md`, public
claims register, capability ledger, validation-debt register, and programme
reconciliation; then read the isolated R candidate's `README.md`,
`DESCRIPTION`, `NEWS.md`, and reader-facing `current-limits` / `model-status`
vignettes.  Searched their release, coverage, calibration, H3, and three-field
wording.  This is an evidence/claim audit only; no public content was changed.

## Verdict

**CLEAN WITH LIMITATIONS.**  No inspected public surface says that 0.9.0 is
released, that the private three-field route is covered, or that H3 `r_g`/
`r_am` intervals are calibrated.  The public state is consistently
experimental 0.8.0 with R-public covered count 7.

## Evidence checked

- Julia README and ROADMAP say experimental 0.8.0, not production/not
  registered, and preserve the 0.9 release hold.
- R README, DESCRIPTION, NEWS, and reader-facing vignettes say experimental
  0.8.0, seven R-public covered routes, 0.9 not released, and no nominal
  interval-coverage calibration.
- The A3 three-field wording restricts the route to intercept-only
  Poisson/Binomial, retains experimental/partial status, names the
  varying-trial literal `NaN` instead of averaging it, and disclaims
  calibration, comparator, promotion, default, and release claims.
- The older NG-1 design page is potentially easy to misread because it records
  historical freeze/nod phrases; its current A3 reconciliation and explicit
  scope fence say those phrases do not unlock a covered flip, public count,
  version bump, or release.
- The programme receipt keeps H3 at no-go/held after zero eligible S10
  intervals and records current private S3 bridge evidence separately from
  public/G10 signing.

## Limitations and remaining gates

This is a source-tree audit of isolated, unintegrated candidates, not a hosted
site review, CI receipt, independently staffed completion panel, or Gate B.
It cannot convert normal tests, private bridge transport, H1
directional-conservative evidence, or the H3 no-go into release eligibility.
H3 must be scientifically ratified for a replacement fixture or removed from
the 0.9 target before a final Rose completion audit and explicit maintainer
release decision can occur.
