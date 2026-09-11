# Bridge Compatibility Matrix (R `hsquared` ⇄ Julia `HSquared.jl`)

Adopted 2026-06-19 (DRM.jl/drmTMB pattern). The R package owns the user language;
this engine owns correctness. The bridge is a **versioned parity contract**: the R
side pins a tested engine version, and parity tests run against serialized engine
target fixtures (not against live re-fits).

> **Record status (2026-09-07):** The later website and named
> honesty-documentation milestone is complete, but it did not authorize a
> package number, tag, registration, release, or bridge promotion. Experimental
> **0.8.0** / public count **7** remain pinned. The corresponding public-source
> record is
> [`2026-09-07-documentation-milestone-release-boundary.md`](../dev-log/decisions/2026-09-07-documentation-milestone-release-boundary.md).

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
| Gaussian animal model (v0.1) | covered | `fit_animal_model`/`fit_ai_reml` | R-public `hsquared()` default | current `main` | existing v0.1 |
| Narrow genomic GREML | covered at validation scale | `genomic` | R-public explicit `target = "genomic"` route; count contribution is recorded in the R ledger | current `main` | genomic GREML target and route fixtures |
| SNP-BLUP | partial | `snp_blup` | opt-in target; not a default or a genomic-wide promotion | current `main` | `genomic_gblup_snpblup_target` |
| Ordinary single-step H/Hinv | engine-covered narrow cell | `single_step` | R supplied/constructed routes remain opt-in partial; Hinv-cell parity is not fitted ssGBLUP parity | current `main` | Hinv-cell parity; fitted comparator still owed |
| Supplied-Γ / HΓ single-step | experimental | `metafounder_single_step` / `fit_metafounder_single_step[_reml]` | live R bridge partial; no general R formula activation implied | current `main` | nonzero-Γ REML payload smoke |
| Unstructured t=2 multivariate | covered at validation scale | `multivariate` | R-public default `cbind()` route; engine evidence remains route-scoped | current `main` | `phase4_multitrait_parity` |
| Structured covariance (FA/low-rank) | engine-covered FA S4 cell only | rotation-free `:diagonal` payload; FA/low-rank loading payload absent | R `cov = fa` grammar and lowrank/FA payload planned | current `main` | `structured_covariance_parity` only for rotation-free metadata |
| PEV / reliability standard fields | experimental | `result_payload(::AnimalModelFit)` | `hs_julia_id_values()` top-level fields (R #21) | current `main` | standard payload tests (`:selinv` vs dense parity) |
| Non-Gaussian Laplace/VA | experimental | `nongaussian_result_payload` | opt-in `target = "nongaussian"` bridge + result normalizer tests banked; per-record varying-trial activation planned (#18) | current `main` | `non_gaussian_parity` |
| Post-fit marker scans | experimental | `marker_scan_result_payload` | R `gwas(fit, markers)` (#23) | current `main` | `marker_scan_parity` |

Rows update by estimand and route rather than by a broad model family. The
metafounder and HΓ bridge entries are live partial surfaces: `Γ`, `group_of`,
`G`, and `genotyped_rows` remain plain payload data, and the Julia fixture
proves a nonzero-`Γ` REML fit travels through the standard `AnimalModelFit`
payload, diagnostics, PEV, and reliability extractors without a special HΓ
extractor branch. That partial bridge does not itself create a general R formula
or production single-step fitting claim.

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

## Production fences (0.9 preparation; no status change)

This is a routing fence, not a reset of existing bridge work. A payload or
fixture that is already live remains available at its recorded scope; it does
not make a production-scale fitting claim.

| Route | What remains true | What this fence prevents |
| --- | --- | --- |
| Standard Gaussian payload | The current `result_payload(::AnimalModelFit)` route, sparse `Z` CSC marshalling, and the opt-in supplied-variance Henderson MME route remain their separately tested surfaces. | Calling a validation-scale payload, MME solve, or sparse marshalling proof a production sparse REML/ML fit. |
| AI-REML and multi-effect routes | Existing Julia fitting targets retain their documented route-specific evidence; the R default and opt-in targets are not silently collapsed into one new route. | Replacing or downgrading an existing sparse/AI-REML or `payload_v2` route merely because a later production bridge is planned. |
| `payload_v2` | The versioned plain-data contract and its fixtures remain the compatibility mechanism; fields are added only with matching R normalization and parity evidence. | Passing Julia structs, raw factor loadings, or undocumented fields across the boundary. |
| Factor-analytic structure | The covered engine S4 cell is a Julia-only, validation-scale result. The rotation-free `:diagonal` metadata route is distinct from FA/low-rank loadings. | Presenting an R `cov = fa` grammar, loadings payload, structured-fit SEs, or calibrated intervals before those have their own evidence. |
| Single-step H/Hinv | `AGHmatrix::Hmatrix` is construction evidence for `H`/`Hinv`; a fitted same-estimand comparator remains separate debt. R `single_step()` remains opt-in partial. | Treating H/Hinv construction agreement as fitted ssGBLUP parity, or opening the ordinary R route. |

The durable evidence for each route is the relevant validation and capability
row in this repository, plus the version-pinned R fixture named in the matrix
above. No private scratch location is a bridge source of truth.
