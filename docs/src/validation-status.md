# Validation Status

`validation_status()` exposes the current validation ladder as typed Julia
rows. It is a diagnostic table, not a comparator runner and not a fitting
helper.

```@example validation_status
using HSquared

status = validation_status()
length(status)
```

```@example validation_status
[row.id => row.status for row in status]
```

## Current Rows

| id | capability | phase | status | claim boundary |
| :--- | :--- | :--- | :--- | :--- |
| `V0-LOAD` | package loading | Phase 0 | covered | Package loads; this is not modelling evidence. |
| `V1-PED` | pedigree normalization | Phase 1 | covered | Pedigree validation utility only; no fitting claim. |
| `V1-AINV-TINY` | sparse Ainv tiny checks | Phase 1 | covered | Direct sparse Ainv utility; not a fitted animal model. |
| `V1-AINV-MRODE9` | Mrode9 pedigree inverse comparator | Phase 1 | covered_external | Pedigree inverse agreement only; not fitted Mrode output validation. |
| `V1-LIK` | Gaussian likelihood tiny checks | Phase 1 | partial | Dense validation evaluator only; not production sparse fitting. |
| `V1-SPARSE-REML` | sparse REML identity | Phase 1 | partial | Supplied-variance REML objective only; no variance-component estimation. |
| `V1-SPARSE-REML-OPT` | sparse REML validation optimizer | Phase 1 | partial | Experimental REML-only validation optimizer; not AI-REML, not the default fit path, and not production sparse fitting. |
| `V1-MME` | Henderson MME supplied-variance solve | Phase 1 | partial | Supplied variance components plus one cross-estimator JWAS agreement probe; no same-estimand REML parity or fitted Mrode claim. |
| `V1-DENSE-OUT` | dense output extractors | Phase 1 | partial | Experimental dense low-level outputs only; accuracy is derived from reliability. |
| `V1-SELINV-PEV` | sparse selected-inversion PEV/reliability | Phase 1 | partial | Experimental sparse PEV path; exact at the L+L^T pattern (diagonal/PEV exact); the default extractor path remains dense. |
| `V1-AI-REML` | average-information REML estimator | Phase 1 | covered | Experimental Gaussian-only REML estimator; the AI form is exact for the Gaussian linear mixed model but not for non-Gaussian/Laplace models (which need observed-information Newton); known-truth recovery and the published-anchor match are validated in the R lane via the bridge. |
| `V1-MRODE-FIT` | fitted animal-model outputs vs a published estimate | Phase 1 | covered_external | Fitted animal-model recovery against a published external estimate; validated via the R-lane bridge, not a Julia-native bundled fixture. |
| `V1-COMPARATORS` | external fitted-model comparators | Phase 1 | covered_external | REML variance-component / h2 agreement against one CRAN comparator (sommer) on one anchor; not multi-package or multi-trait parity. |
| `V1-HERIT-CI` | variance-component covariance and heritability interval | Phase 1 | partial | Asymptotic, REML-only; unreliable at small n (wide interval, ill-conditioned AI matrix); not a coverage-calibrated interval. |
| `V2-GRM` | genomic relationship matrix (VanRaden G) | Phase 2 | partial | Experimental construction utility only; no genomic prediction, fitting, single-step, or marker-effect claim. |
| `V2-GINV` | regularized genomic inverse (Ginv) | Phase 2 | partial | Construction utility only; not wired into model fitting, and no single-step or genomic-prediction claim. |
| `V2-GBLUP` | genomic BLUP supplied-variance solve | Phase 2 | partial | Supplied-variance genomic solve only; no genomic variance-component estimation, no single-step, no external comparator parity. |
| `V2-SNPBLUP` | SNP-BLUP / GBLUP equivalence | Phase 2 | partial | Supplied-variance VanRaden method-1 marker model only; no variance-component estimation, no external comparator, no weighted/Bayesian marker priors. |
| `V2-SSHINV` | single-step H-inverse construction | Phase 2 | partial | Dense validation-scale single-step and supplied-Gamma H^Gamma primitives; dense-H oracle round-trip and nonzero-Gamma REML bridge payload/diagnostics smoke are tested; Gamma and blending controls are inputs, not estimated or comparator-validated; no external-comparator or covered single-step prediction claim. |
| `V2-GREML` | genomic REML variance-component estimation | Phase 2 | partial | Reuses the Phase-1 REML optimizers on a genomic spec; no external comparator parity and no production sparse-G scaling. |
| `V3-REPEAT` | repeatability / permanent-environment supplied-variance solve | Phase 3 | partial | Supplied-variance two-random-effect solve only; no R-facing model-spec, engine-internal. |
| `V3-REPEAT-REML` | repeatability REML variance-component estimation | Phase 3 | partial | Dense validation-scale REML over three variance components; no committed recovery test, no uncertainty intervals, no external comparator, no R-facing model-spec. |
| `V3-TWOEFFECT` | general two-random-effect MME (common environment, maternal) | Phase 3 | partial | Supplied-variance, two INDEPENDENT random effects only; no correlated maternal genetic, no R-facing model-spec. |
| `V3-TWOEFFECT-REML` | two-effect REML (common-environment / maternal estimation) | Phase 3 | partial | Dense validation-scale REML; no committed recovery test, no intervals, no correlated maternal genetic, no R-facing model-spec. |
| `V4-MULTIVARIATE` | multivariate (multi-trait) animal model (supplied covariance) | Phase 4 | partial | Supplied-covariance with a design shared across traits; handles missing-trait records and copy-returning Julia-side accessors over existing fields, but does not estimate G0/R0 and has no R-facing multivariate model-spec or bridge payload change. |
| `V4-MV-REML` | multivariate REML (genetic/residual covariance estimation) | Phase 4 | partial | Experimental dense/validation-scale multivariate REML; correctness is self-consistency + univariate-reduction validated and adversarial-reviewed (robustness findings fixed), copy-returning Julia accessors wrap existing fields without widening `result_payload()`, opt-in Julia and R-lane cold-start recovery studies show no detectable bias at validation scale, and a serialized Julia target fixture plus comparator protocol now has one reproduced external `sommer` 4.4.5 comparator leg plus a tested BLUPF90 preflight harness; still partial because the executed per-seed calibration protocol did not pass, recovery is not coverage-calibrated, and comparator evidence is still one fixture/package with no executed second-comparator run; not the public default, with R-facing opt-in multivariate bridge semantics still gated for public covered status. |
| `V4-FA` | structured multivariate genetic covariance (diag/lowrank/fa) | Phase 4B | partial | Experimental dense/validation-scale engine API only; copy-returning structured-metadata accessors expose existing fields locally; returned loadings are sign-canonicalized under a sign-only convention but not rotation-identified; the opt-in recovery harness accepts explicit seed lists and remains outside CI; the recovery calibration protocol was executed and did not pass (factor-analytic 8/10 with G-only/G+R failures, low-rank 9/10 with 1 R-only failure, all fits converged); no R-facing covariance-structure syntax, no bridge/result-payload change, no production sparse FA solver, no broad multi-seed calibration, and no external comparator evidence. |
| `V5-MARKER-FIXED` | fixed-effect single-marker scan | Phase 5 | partial | Fixed-effect Gaussian screening utility with row-aligned scan-table, GWAS/QTL/eQTL labelled table wrappers, marker-effect, marker-variance-contribution, marker-map-backed Manhattan, regional marker-window, nominal returned-marker-set significance summary, QQ, inflation diagnostic helpers, and opt-in marker-scan recovery smoke outside CI only, using supplied residual variance plus approximate Wald p-values, Bonferroni/BH adjustments, LOD-equivalent scores, Manhattan data, regional data, nominal raw/Bonferroni/BH significance counts, QQ data, and a lambda_GC diagnostic over the returned marker set; gwas_table(), qtl_table(), and eqtl_table() wrappers only label already-computed direct scan tables and do not run GWAS/QTL/eQTL workflows; no regional_plot() or fine-mapping activation, no formula-driven mixed-model GWAS/QTL claim, no expression-wide eQTL claim, no calibrated/correlated-marker genome-wide threshold claim, no p-value calibration claim, no calibrated PVE/model R² claim, no R formula term activation, no bridge payload change, and no comparator evidence. |
| `V5-MARKER-MIXED` | supplied-variance mixed-model marker scan | Phase 5 | partial | Dense validation-scale supplied-variance Julia utility only; relationship correction is by the supplied marginal covariance and tested by GLS identities plus opt-in marker-scan recovery smoke outside CI, but there is no variance-component estimation, no LOCO public workflow, no p-value calibration claim, no calibrated PVE/model R² claim, no R formula activation, no bridge payload change, and no comparator evidence. |
| `V5-MARKER-LOCO` | leave-one-group-out marker scan construction and selection | Phase 5 | partial | Dense validation-scale LOCO construction and supplied-matrix selection helpers only; LOCO precision construction uses VanRaden-plus-ridge identities and the scan uses supplied variance components, with opt-in marker-scan recovery smoke outside CI, but there are no public LOCO defaults, no variance-component estimation, no p-value calibration claim, no calibrated PVE/model R² claim, no R formula activation, no bridge payload change, and no comparator evidence. |
| `V5-GENOMIC-QTL` | genomic, marker, QTL, and eQTL validation | Phase 5 | planned | Broad genomic/QTL/eQTL validation remains planned; the direct marker-screening utilities are tracked separately in `V5-MARKER-FIXED`, `V5-MARKER-MIXED`, and `V5-MARKER-LOCO`. |

## Boundary

`covered_external` means the evidence is recorded in the R twin or another
external validation path and is not independently bundled as Julia test data.
For example, the Mrode9 row records the R twin's optional `nadiv::Mrode9` /
`nadiv::makeAinv()` comparison against Julia `pedigree_inverse()`.

That evidence covers pedigree inverse agreement only. It does not cover fitted
Mrode variance components, EBVs, heritability, reliability, PEV, accuracy, or
external ASReml/BLUPF90/DMU/WOMBAT/sommer/MCMCglmm fitted-model parity.

The `V1-MME` row records the shared supplied-variance Henderson MME fixture
mirrored from the R twin at head `ca8bce1`. The fixture pins the pedigree
inverse, fixed effects, EBVs, fitted values, and simple `h2 = 0.6` for supplied
variance components `sigma_a2 = 1.2` and `sigma_e2 = 0.8`. It is still not
variance-component estimation, AI-REML, fitted Mrode validation, or fitted
comparator parity.

Julia also bundles a Mrode9-shaped supplied-variance fixture using the 12-animal
`nadiv::Mrode9` pedigree structure. It pins `Ainv`, ML/REML likelihood values,
fixed effects, EBVs, fitted values, PEV, reliability, derived accuracy, and
`h2` at supplied variance components. This strengthens the supplied-variance
equation and extractor checks, but it is still not fitted Mrode output
validation, variance-component estimation, AI-REML, or external fitted-model
parity.

The opt-in JWAS runner now executes outside CI from the separate
`comparator/` environment. On 2026-06-21, JWAS 2.3.6 ran the serialized
single-trait fitted target as a Bayesian/MCMC model (`chain_length = 50000`,
`burnin = 10000`, seed `20260620`) and aligned all 20 animal EBVs against the
REML target (`cor = 0.999`, max absolute difference `0.1103`). This is an
agreement probe only. JWAS and REML are different estimators, so the row remains
`partial` pending same-estimand fitted-output comparator evidence.

The Phase 4 multivariate rows are Julia-engine rows only. The accessor helpers
wrap existing result fields locally and do not change the R bridge payload. The
unstructured REML row now has opt-in Julia and R-lane cold-start recovery
evidence with no detectable bias at validation scale, plus one reproduced
external `sommer` 4.4.5 comparator leg on the serialized two-trait target
fixture. This is still one fixture/package, not multi-package parity; ASReml,
BLUPF90, JWAS, or equivalent same-estimand parity remains open. The
BLUPF90/AIREMLF90 packet has a tested preflight and skip-safe opt-in runner, but
that is setup hygiene only until an executable run and aligned estimates are
recorded. The
structured covariance row covers diag/low-rank/factor-analytic engine metadata,
local copy-returning metadata accessors, and opt-in recovery checks with
explicit seed-list reporting. The rotation-identifiability decision note records
sign-only metadata as the current convention. The multivariate recovery
calibration protocol was executed and did not pass under the predeclared
thresholds. Deterministic log triage now records whether failed seeds exceeded
G-only, R-only, or both thresholds, but broad multi-seed calibration remains
validation debt; full
rotation and interpretation remain validation debt.
