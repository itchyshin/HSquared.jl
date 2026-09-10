# After-task — H3 replacement S11 decision template

## 1. Goal

Prepare an authorization-ready, engine-/capability-inert S11 decision template from the
successful replacement H3 S10 receipts, without choosing scientific campaign
parameters or starting compute.

## 2. Implemented

Added a closed-schema refusal-only template, its validator, mutation controls,
a registered focused test, and a maintainer-facing decision record. The template
binds the separate `r_g` and `r_am` S10 receipt digests and runtimes.

## 3a. Decisions and Rejected Alternatives

Rejected inventing fresh seeds, a replicate count, an interval-success floor,
an MCSE/classification rule, a compute route, or an S11 authorization. Rejected
pooling the two H3 estimands. The only valid current state is
`unratified_refusal_only`.

## 4. Files Touched

- `docs/dev-log/evidence/2026-09-09-h3-replacement-s11-template.toml`
- `tools/validate_hsq09_h3_replacement_s11_template.jl`
- `test/test_hsq09_h3_replacement_s11_template.jl` and `test/runtests.jl`
- decision, check-log, coordination, and this after-task record
- ignored `.unlazy/hsq-09/` planning/gate ledger

## 5. Checks Run

Baseline `Pkg.test()` and the post-change registered full `Pkg.test()` both
exited successfully. The focused test failed first because the template and
validator were absent, then passed 6/6 after implementation. The validator
self-test rejected five defined mutations. `git diff --check` passed.

## 6. Tests of the Tests

The initial focused test failed on two absent artifacts. The final mutation
controls reject an armed S11 flag, invented seed schedule, invented replicate
count, altered retained-receipt identity, and an undeclared TOML section.

## 7a. Issue Ledger

No issue was opened or closed. The missing item is a maintainer decision, not a
software defect.

## 8. Consistency Audit

No engine source, public API, R bridge, fixture, capability-status row,
validation-debt row, version, tag, registry, or release state changed. The
template preserves `r_g`/`r_am` separation and all action flags remain false.

## 9. What Did Not Go Smoothly

The first baseline `Pkg.test()` attempt was blocked before tests began because
the sandbox denied Julia's normal `~/.julia/logs/manifest_usage.toml.pid` lock.
The unchanged command passed once normal local Julia-cache access was allowed;
this was environmental rather than a package failure. The generic after-task
wrapper cannot locate `node` on this host and therefore labels the ignored
ledger unknown; the dedicated absolute-path Unlazy parser reports all five
gates met, and the direct commands were re-run as recorded above.

## 10. Known Residuals

This is not a scientific S11 protocol: it intentionally leaves seed schedule,
replicate count, denominator floor, MCSE/classification rule, and compute route
unresolved. It is neither coverage evidence nor authorization to submit a job.

## 11. Team Learning

An authorization-ready template should bind proven receipt provenance while
making undecided scientific parameters mechanically impossible to mistake for
ratified defaults.

## 12. Cross-Product Coverage

This covers the Julia-only provenance and refusal boundary for a future H3 S11
decision. It does not cover an S11 campaign, H0/H1/H3 calibration, external
comparison, R-public parity, promotion, versioning, tags, registry, or release.
