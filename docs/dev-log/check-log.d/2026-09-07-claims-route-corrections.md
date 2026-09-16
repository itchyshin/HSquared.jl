# 2026-09-07 — route-specific public-claim corrections

- Scope: local-only correction of the Julia website's bridge, grammar, and
  generated validation-status wording after the Rose cross-twin review F4. No
  estimator, API, status symbol, row count, public-covered count, version,
  rebase, push, merge, or deployment changed.
- Replaced the broad bridge-family rows with separate route cells for narrow
  genomic GREML, SNP-BLUP, ordinary H/Hinv, supplied-Γ/HΓ, t=2 multivariate,
  and the narrow FA S4 engine cell. The matrix now distinguishes engine scope,
  R route, fixture/parity evidence, and remaining production/comparator debt.
- Marked the grammar's reserved and roadmap spellings as Julia-local diagnostic
  API. They no longer assert that `hsquared()` errors on a live R route; the
  two genomic rows retain their explicitly scoped R route facts.
- Updated `V2-GREML` at its source and regenerated
  `docs/src/validation-status.md`: its engine claim remains supplied-`Ginv`,
  validation-scale, and opt-in, while the separately validated narrow R GREML
  route is default-routed and covered at validation scale. SNP-BLUP,
  single-step, intervals, production robustness, and G construction are still
  outside that R-route statement.

| Check | Result | Retained evidence |
| --- | --- | --- |
| Source status generator | PASS; 56 rows | `/private/tmp/hsq-web-20260907-julia-claims-status-generator.log` |
| Targeted source contract | PASS; V2-GREML `covered`, 56 validation rows, 20 grammar rows | `/private/tmp/hsq-web-20260907-julia-claims-source-smoke.log` |
| Documenter/VitePress build | PASS; local output `docs/build/1` | `/private/tmp/hsq-web-20260907-julia-claims-documenter.log` |
| Superseded-phrase scan | PASS; zero matches in the four corrected claim surfaces | command recorded in this task's terminal receipt |

This does NOT cover a new bridge parity fixture, fitted same-estimand
single-step comparator, production sparse fitting, interval calibration, or
any R-package implementation change.
