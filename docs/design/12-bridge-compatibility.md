# Bridge Compatibility Matrix (R `hsquared` ⇄ Julia `HSquared.jl`)

Adopted 2026-06-19 (DRM.jl/drmTMB pattern). The R package owns the user language;
this engine owns correctness. The bridge is a **versioned parity contract**: the R
side pins a tested engine version, and parity tests run against serialized engine
target fixtures (not against live re-fits).

## Discipline

- **Boring payload only.** Strings / dicts / plain arrays / column tables cross
  the boundary. `HSquared.jl` structs never cross — R reads `result_payload(fit)`
  and the documented extractor fields, not Julia objects.
- **Pin + regenerate.** The R repo pins a known-good `HSquared.jl` version for
  bridge tests. A breaking engine change to the payload/result shape requires a
  minor-version bump here and regenerated R fixtures.
- **Parity fixtures.** Each bridged capability serializes a deterministic target
  under `test/fixtures/<capability>_parity/` (inputs + engine outputs) so R-side
  parity tests are hermetic and need no live Julia in CI.

## Result-shape contract

The stable surface is `result_payload(fit)` plus the exported extractors. See
`docs/design/03-engine-contract.md` for the field list; this page tracks which
engine version each R surface is validated against.

## Matrix

| Capability | Engine status | Bridge target | R surface | Engine ver. tested | Parity fixture |
| --- | --- | --- | --- | --- | --- |
| Gaussian animal model (v0.1) | covered | `fit_animal_model`/`fit_ai_reml` | `hsquared()` default | (current `main`) | existing v0.1 |
| Genomic GBLUP/SNP-BLUP/single-step | experimental | `genomic`/`single_step`/`snp_blup` | opt-in `target=` | current `main` | `genomic_gblup_snpblup_target` for GBLUP/SNP-BLUP only; single-step still pending |
| Supplied-Γ metafounder single-step | experimental | `metafounder_single_step` (candidate: `metafounder_single_step_inverse` / `fit_metafounder_single_step[_reml]`) | planned R metafounder/single-step payload | current `main` | nonzero-Γ REML payload smoke |
| Unstructured multivariate | experimental | `multivariate` | opt-in `target=` | current `main` | phase4_multitrait_parity |
| Structured covariance (FA/low-rank) | experimental | #42 | (R #42 / #15) | — | planned (#42) |
| PEV / reliability standard fields | experimental | `result_payload(::AnimalModelFit)` | `hs_julia_id_values()` top-level fields (R #21) | current `main` | standard payload tests (`:selinv` vs dense parity) |
| Non-Gaussian Laplace/VA | experimental | `nongaussian_result_payload` | opt-in `target = "nongaussian"` bridge + result normalizer tests banked; per-record varying-trial activation planned (#18) | current `main` | `non_gaussian_parity` |
| Post-fit marker scans | experimental | `marker_scan_result_payload` | R `gwas(fit, markers)` (#23) | current `main` | `marker_scan_parity` |

Rows update as each BT2 bridge target lands its engine-side payload + fixture.
The metafounder single-step row is engine-side only: `Γ`, `group_of`,
`G`, and `genotyped_rows` are plain payload candidates. The current Julia
fixture proves that a nonzero-`Γ` REML fit travels through the standard
`AnimalModelFit` result payload, `fit_diagnostics()`, PEV, and reliability
extractors without a special H^Γ extractor branch. No R formula syntax or live
R bridge fixture is claimed until the R twin ratifies the shape and tests it.

The PEV/reliability row is a standard fitted `AnimalModelFit` payload surface,
not a production large-pedigree reliability claim. The fields are
`prediction_error_variance = (ids, values)` and `reliability = (ids, values)`,
computed once through the `:selinv` selected-inversion path and parity-tested
against the dense MME diagonal on validation-scale fixtures. Supplied-variance
`HendersonMMEResult` bridge paths may still use explicit extractors rather than
`result_payload()`.

The non-Gaussian row is a Julia-side payload target with R-side normalizer
consumption now banked. The `non_gaussian_parity` fixture serializes Poisson
Laplace and per-record Binomial variational `NonGaussianFit` payloads, and
hsquared PR #95 (`05fbdd3`) consumes them in Julia-free normalizer tests while
preserving method aliases and scalar/vector `n_trials` fields. hsquared PR #96
(`e7c7a4a`) corrects the R status: an opt-in non-Gaussian bridge already exists
through `target = "nongaussian"` for `poisson(log)` and `binomial(logit)`
including binary Bernoulli, common-trial `cbind(successes, failures)`
Binomial, LA/VA marginal control, no-heritability result normalization, and
live bridge tests when Julia is available. The remaining bridge gap is narrower:
per-record varying-trial formula/bridge activation plus broader
validation/comparator/calibration depth. There is still no threshold/probit
comparator evidence, interval calibration, public default, or covered status.
