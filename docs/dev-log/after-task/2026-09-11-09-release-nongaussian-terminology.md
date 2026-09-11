# After-task — 0.9 candidate non-Gaussian terminology repair (2026-09-11)

## 1. Goal

Repair the public Julia candidate's misleading non-Gaussian `REML` wording without changing an estimator, fixture, payload, API, version, release state, or compute plan.

## 2. Implemented

Isolated worktree branch `codex/hsq09-release-julia-20260911`, starting at `649ab8ba`; repair committed as `c5303d75`. The public status-table heading and tail boundary now distinguish the actual non-Gaussian objectives from the Gaussian exact-REML reduction.

## 3a. Decisions and Rejected Alternatives

Retained the exported historical function names rather than making an API rename. Rejected any model, bridge, fixture, family, calibration, default-routing, or status change: the task is honest terminology only.

## 4. Files Touched

- `docs/design/capability-status.md`: names the fitted non-Gaussian route as Laplace-marginal/variational and says explicitly that non-Gaussian objectives are not REML/AI-REML; exported historical API names remain unchanged.
- `test/runtests.jl`: pins that reader-facing wording.

## 5. Checks Run

- Red test: the new assertion failed against the prior `Laplace/VA REML` heading and `REML-style` claim.
- `/Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: pass, including Phase 0 scaffold 420/420 and the complete package suite.
- `/Users/z3437171/.juliaup/bin/julia --project=docs docs/make.jl`: pass; local Documenter build completed. Existing undocumented-docstring warnings remain warnings only.
- Unlazy G5 direct wording oracle: pass (`JULIA_NONGAUSSIAN_CLAIM_WORDING_OK`).

## 6. Tests of the Tests

The permanent test identifies the one status-table row rather than matching the whole document, then requires the corrected objective description, the explicit `not REML/AI-REML` boundary, and absence of `REML-style`. It failed before the documentation edit and passed afterward.

## 7a. Issue Ledger

- Resolved: public status row described a non-Gaussian route as `Laplace/VA REML` and `REML-style`.
- Held: R default-genomic routing has conflicting governing records; it is not altered by this Julia repair.
- Open: fresh independent frozen-artifact review of final exact R and Julia candidates.

## 8. Consistency Audit

The correction distinguishes the Gaussian exact-REML reduction from the non-Gaussian Laplace marginal-likelihood / variational-ELBO objectives. It does not promote any status, add a family, widen the bridge, or claim calibration, comparator parity, default routing, or release eligibility.

## 9. What Did Not Go Smoothly

The first sandboxed Julia invocation could not write Julia's manifest-usage lock; the identical normal test was then run with the required local cache access. Unlazy's environment-bound approval records also exposed a volatile tool PATH, so G5 was verified under a fixed minimal PATH.

## 10. Known Residuals

This is terminology hardening only. The source candidate is not independently re-audited after this commit, and no release action is authorized or performed. The retained R archive `c7a707…` predates this Julia-only commit and is unaffected.

## 11. Team Learning

No new agent was dispatched for this documentation-only repair. The prior independent Rose frozen-artifact review identified the wording defect; its broader release verdict remains blocked until every independent gate is re-run on the final frozen artifacts. Public method names can remain stable while the scientific objective is corrected explicitly beside them.

## 12. Cross-Product Coverage

The Julia candidate is repaired and verified locally. The R twin was not edited. A separate signed R commit authorizes default genomic routing while the original 0.9 programme says to defer it; that authority conflict remains explicitly held for maintainer reconciliation. This slice covers the Julia public capability-status row and its regression test; it does NOT cover R source or documentation, bridge payloads, API renaming, non-Gaussian calibration, H0/H1/H3 evidence, default routing, CRAN artifacts, release gating, tags, merges, registries, or publication.

## Next Action

Obtain a maintainer decision reconciling whether default genomic routing is active for 0.9.0. Then rebuild/verify the final R artifact if needed and request a fresh independent frozen-artifact audit of both exact candidate commits before any Gate B action.
