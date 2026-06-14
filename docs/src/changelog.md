# Changelog

## Unreleased

- Added pedigree normalization and sparse `Ainv` construction utilities.
- Added low-level animal-model specification validation.
- Added dense Gaussian ML/REML log-likelihood evaluation at supplied variance
  components.
- Added sparse REML log-likelihood evaluation at supplied variance components
  using the Henderson MME determinant identity.
- Added experimental `fit_sparse_reml()` and
  `fit_animal_model(...; target = :sparse_reml)` dispatch for REML-only sparse
  validation optimization.
- Added an experimental sparse prediction-error-variance / reliability path:
  `prediction_error_variance(...; method = :selinv)` and
  `reliability(...; method = :selinv)` use a Takahashi selected inverse of the
  sparse Henderson MME coefficient matrix (kernel adapted from DRM.jl, MIT). The
  default stays `:dense` and matches it to machine precision on tiny fixtures.
- Added an experimental average-information REML estimator: `fit_ai_reml()` and
  `fit_animal_model(...; target = :ai_reml)` estimate the two variance components
  by AI/Newton steps on the sparse Henderson MME (score from the selected
  inverse, AI matrix from working-variate re-solves). Validated to recover the
  same optimum as the NelderMead optimizers; REML-only, Gaussian, experimental.
- Added `genomic_relationship_matrix()` — the VanRaden (2008) genomic
  relationship matrix `G` from a 0/1/2 (or dosage) marker matrix. Construction
  utility only (Phase 2 start); no genomic fitting yet.
- Added `genomic_relationship_inverse()` — the ridge-regularized dense inverse
  `inv(G + ridge·I)` of a genomic relationship matrix, intended for later GBLUP
  use. Construction utility only; not wired into model fitting, and no
  single-step (`H`-matrix) blending.
- Added `fit_gblup()` — genomic BLUP at supplied variance components: feeds a
  genomic `Ginv` into the existing Henderson MME (`Ginv` in the `Ainv` slot).
  Reproduces an independent dense MME and reproduces pedigree BLUP when `G = A`;
  experimental, supplied-variance only, no variance-component estimation, no
  single-step, no external comparator.
- Added `fit_snp_blup()` and `centered_markers()` — SNP-BLUP / RR-BLUP marker
  effects via the existing Henderson MME (`Z = W` centered markers, identity
  prior, `σ²_marker = σ²_g/k`). `gebv = W·â` equals GBLUP to machine precision
  (the GBLUP↔SNP-BLUP equivalence, validated via the marginal `V`); experimental,
  supplied-variance only, unweighted VanRaden method-1.
- Internal: deduped the numerator-relationship recursion into
  `_numerator_relationship(pedigree[, rows])` (one source shared by
  `inbreeding_coefficients` and single-step `A₂₂` construction); removed the
  test-only duplicate. No public API or behavior change.
- Documented and tested genomic reliability/PEV/accuracy: for a GBLUP fit the
  existing extractors use the regularized genomic self-relationship
  `diag(inv(Ginv)) = diag(G) + ridge` as the denominator (the ridge perturbs the
  reported reliability/accuracy), and `method = :selinv` PEV matches the dense
  diagonal. No logic change.
- Added an internal single-step H-inverse construction utility
  `_single_step_Hinv` — `H⁻¹ = A⁻¹ + scatter(τG⁻¹ − ωA₂₂⁻¹)` on the genotyped
  rows (with the subtle `A₂₂⁻¹ = inv(A[g,g])`, not `(A⁻¹)[g,g]`). Property-checked
  (reduction, locality, symmetry, distinctness, scattered rows, singular-`G`
  guard); unexported, not wired into fitting, blending/τ/ω/ridge defaults not
  comparator-validated.
- Validated genomic REML variance-component estimation: the existing REML
  optimizers (`fit_ai_reml`, `fit_sparse_reml`) estimate σ²g/σ²e on a genomic
  `Ginv` spec — AI and NelderMead reach the same optimum and `fit_gblup` at the
  estimate reproduces the REML breeding values. Experimental; no external
  comparator; no new code (reuses the Phase-1 optimizers).
- Added a "Genomic models" documentation page with runnable examples for
  `G`/`Ginv`, GBLUP, genomic REML, SNP-BLUP, and the single-step `H⁻¹` utility,
  and an explicit experimental / not-yet-R-wired / no-external-comparator
  boundary.
- Added experimental heritability uncertainty: `variance_component_covariance`,
  `variance_component_standard_errors`, `heritability_standard_error`, and
  `heritability_interval` — a logit-transform delta interval (always in (0,1))
  built on the REML AI matrix, with a self-contained standard-normal quantile.
  Asymptotic / REML-only; wide and unreliable at small n.
- Added `repeatability_mme()` — the first Phase-3 slice: a supplied-variance
  Henderson solve of the two-random-effect repeatability / permanent-environment
  animal model (additive `a` + permanent-environment `pe`) via a block-diagonal
  relationship precision. Matches an independent marginal-GLS BLUP and reduces to
  the animal model as `σ²pe → 0`. Experimental, supplied-variance only — no REML
  estimation of the three components, no R-facing model-spec yet.
- Added `fit_repeatability_reml()` — REML estimation of (σ²a, σ²pe, σ²e) for the
  repeatability / permanent-environment model (dense two-random-effect REML
  loglik + NelderMead), returning the repeatability coefficient `t` and `h²`.
  Deterministic checks (loglik reduces to the animal-model REML at σ²pe=0; BLUPs
  match `repeatability_mme`; optimum beats a grid) + a one-off seeded recovery.
  Experimental, dense/validation-scale, REML-only; no committed recovery test
  (suite kept RNG-free), no intervals, no R-facing model-spec.
- Added `two_effect_mme()` — the general supplied-variance kernel for two
  independent random effects (each with its own incidence, relationship inverse,
  and variance), covering common-environment and maternal-environment models;
  `repeatability_mme` is now its `Z2=Z1, A2=I` special case. Validated against an
  independent marginal-GLS BLUP. Experimental; no correlated direct–maternal
  genetic, no estimation, no R-facing model-spec.
- Added `fit_two_effect_reml()` — REML estimation of the two-effect-model
  variances (common-environment `c²`, maternal variance, etc.) via the dense
  two-effect REML loglik; `fit_repeatability_reml` is the `Z2=Z1, A2=I` reduction.
  Experimental, dense/validation-scale, REML-only; no committed recovery test, no
  intervals, no R-facing model-spec.
- Added a "Standard QG models" documentation page with runnable examples for
  repeatability (MME + REML, repeatability coefficient), common-environment, and
  maternal-environment models, with the experimental / not-yet-R-wired boundary.
- Validation status (v0.1 gate): corrected the `V1-AI-REML` evidence to cite the
  committed finite-difference REML Hessian check (`V1-HERIT-CI`) instead of an
  uncommitted "250-animal observed-information" claim, and recorded the R-lane
  external validation — `V1-MRODE-FIT` and `V1-COMPARATORS` move to
  `covered_external` (the engine recovers the published gryphon REML estimate,
  Wilson 2010 h²=0.470, via supplied `A_gryphon`, and agrees with sommer, within
  the maintainer-signed-off band). Status rows + tests only; no engine change.
- Reconciled `ROADMAP.md` with merged reality: Phases 1-3 engine utilities
  (genomic prediction, single-step `H`-inverse, AI-REML, the Takahashi selected
  inverse, repeatability / two-effect models) are now listed as landed
  experimental, validation-scale utilities instead of "not implemented".
- Added `multivariate_mme()` — the first Phase-4 (multivariate Gaussian) slice: a
  supplied-covariance Henderson solve of the balanced multi-trait animal model
  (Kronecker MME with genetic precision `Ainv⊗G0⁻¹` and residual `I⊗R0⁻¹`),
  returning per-trait fixed effects and EBVs. Validated against an independent
  loop-built MME, an independent marginal-GLS BLUP, the univariate animal model
  at `t=1`, and `t` independent single-trait fits at diagonal `G0`/`R0`.
  Experimental, dense/validation-scale; balanced data with a shared design only;
  no `G0`/`R0` estimation, no missing records, no R-facing model-spec.
- Added `genetic_correlation()` — converts a covariance matrix (e.g. `G0`, `R0`)
  to the corresponding correlation matrix; also extracts the genetic correlation
  from a `multivariate_mme` result.
- Extended `multivariate_mme()` to **unbalanced / missing-trait records**: a
  `missing` or `NaN` entry in `Y` marks an unobserved trait, handled via the
  per-individual residual precision `inv(R0[Sᵢ, Sᵢ])`; balanced data reduces to
  the previous fast path. Validated against an independent loop-built MME and a
  marginal-GLS BLUP with per-individual residual blocks.
- Added `fit_multivariate_reml()` — estimates the multi-trait genetic/residual
  covariances `G0`, `R0` by dense REML (log-Cholesky-parameterized Nelder–Mead;
  handles missing records), returning the estimates, correlations, per-trait
  heritabilities, and breeding values at the estimate. Validated by the `t = 1`
  reduction to the univariate REML (the loglik equals `sparse_reml_loglik`
  exactly), grid-beating, and EBV consistency with `multivariate_mme`.
  Experimental, dense/validation-scale; opt-in seeded recovery exists outside
  CI, but is not multi-seed calibrated and has no external-comparator parity
  yet.
- Added `test/fixtures/phase4_multitrait_parity/`, a deterministic two-trait
  CSV fixture for R-lane sommer/ASReml/BLUPF90 parity work. It records a Julia
  REML target (`G0`, `R0`, beta, EBVs, h², and loglik) and CI checks fast
  self-consistency at the stored target covariances. It is not external
  comparator evidence.
- Added opt-in `sim/phase4_multivariate_reml_recovery.jl` for seeded two-trait
  known-truth recovery of the unstructured multivariate REML estimator outside
  CI. Default seed `20260616` passed with relative errors `G = 0.174500` and
  `R = 0.131056` against thresholds `0.25` and `0.20`. This is internal
  recovery evidence, not multi-seed calibration or external comparator parity.
- Updated the validation-status documentation table to include the current
  Phase 2, Phase 3, Phase 4, and Phase 4B validation rows and their claim
  boundaries.
- Hardened the multivariate engine after a 7-lens adversarial review (each finding
  verified by running Julia): `multivariate_mme` / `fit_multivariate_reml` now
  reject non-finite observed phenotypes (`Inf` — only `missing`/`NaN` mark an
  unobserved trait), non-finite `X`/`Z`/`Ainv`, and empty-trait columns with clear
  errors (previously a silent all-NaN result or an opaque `SingularException`); and
  `fit_multivariate_reml`'s `loglik` is now the **full** REML log-likelihood
  including the `(N−p')·log(2π)` constant, on the same scale as the other loglik
  functions (safe for LRT/AIC). Regression-tested.
- Added Phase-4B structured genetic covariance support for the dense multivariate
  REML engine: `diagonal_covariance()`, `lowrank_covariance()`, and
  `factor_analytic_covariance()` build `diag(σ²)`, `ΛΛ'`, and `ΛΛ' + Ψ`, and
  `fit_multivariate_reml(...; genetic_structure = :diagonal | :lowrank |
  :factor_analytic, rank = K)` estimates constrained genetic covariance
  structures while keeping residual `R0` unstructured. Validated by deterministic
  constructor identities, structure metadata, loglik equality to the existing
  evaluator, PSD/PD covariance checks, constrained loglik ≤ the unstructured
  fit, and deterministic sign-canonicalization of returned loading columns.
  Experimental, dense/validation-scale; no R-facing covariance-structure syntax,
  bridge change, loading rotation/identifiability convention, or external
  comparator yet.
- Added opt-in Phase-4B recovery harness
  `sim/phase4b_structured_covariance_recovery.jl` for seeded low-rank and
  factor-analytic covariance recovery outside CI. This strengthens internal
  recovery evidence but does not add R-facing syntax, bridge payload fields, or
  external comparator parity.
- Added a "Multivariate models" documentation page with a runnable balanced
  two-trait example and the experimental / not-yet-R-wired boundary.
- Expanded planned backend marker/control vocabulary to include threaded CPU,
  AMDGPU, Metal, and oneAPI markers alongside CPU, CUDA, and auto metadata.
- Added `backend_info()` typed status diagnostics for planned backend rows with
  execution marked unavailable.
- Added planned genomic/QTL model-term vocabulary reservations:
  `genomic()`, `single_step()`, `markers()`, `marker_scan()`, and `qtl_scan()`.
- Added planned standard quantitative-genetic model-term vocabulary
  reservations: `permanent()`, `common_env()`, `maternal_genetic()`,
  `maternal_env()`, `paternal_genetic()`, `paternal_env()`, `cytoplasmic()`,
  `imprinting()`, `dominance()`, `epistasis()`, `relmat()`, and
  `HSquared.precision()` in direct Julia code.
- Added a Documenter model-spec grammar page mirroring the R twin's status
  separation for parsed, reserved, and planned syntax.
- Added `formula_status()` grammar diagnostics and a Documenter status table
  mirroring the R twin's parsed/reserved/planned grammar rows.
- Added `validation_status()` diagnostics for covered, external, partial, and
  planned validation rows.
- Added `max_dense_cells` guards for the temporary dense validation path.
- Added experimental dense variance-component optimization for validated
  low-level animal-model specs.
- Added experimental low-level variance-component, fixed-effect, EBV/BLUP,
  fitted-value, and heritability extractors for the dense spec path.
- Switched `breeding_values(fit)` to the Henderson MME solve at the fit's
  variance components.
- Switched `fitted_values(fit)` to the same Henderson MME solve at the fit's
  variance components.
- Added experimental dense prediction-error-variance and reliability extractors
  for the dense spec path.
- Extended validation-scale prediction-error-variance and reliability
  extractors to supplied-variance `HendersonMMEResult` objects.
- Extended supplied-variance `variance_components()` and `heritability()`
  extractors to `HendersonMMEResult` objects.
- Added `EBV()` and `BLUP()` aliases for `breeding_values()`, plus
  `accuracy()` as a checked square-root transformation of reliability.
- Added `fit_diagnostics()` as metadata-only extraction for low-level
  `AnimalModelFit` and supplied-variance `HendersonMMEResult` objects.
- Added experimental direct payload `fit_animal_model(y, X, Z, Ainv; ...)`
  target for bridge-shaped inputs.
- Added explicit `fit_animal_model(...; target = :henderson_mme,
  variance_components = ...)` dispatch for supplied-variance Henderson MME
  solving.
- Added `henderson_mme()` for sparse Henderson mixed-model-equation solving at
  supplied variance components.
- Added a shared R/Julia Henderson mixed-model-equation validation fixture for
  the supplied-variance output path.
- Added `result_payload()` with field names aligned to the R `hsquared_fit`
  extractor contract.
- Added `HSData`, `HSDataIDMap`, and `id_map()` as an in-memory mirror of the R
  `hs_data()` input-container contract.
- Added `HSData` marker-map metadata validation and genotype-marker alignment
  checks.
- Added `data_status(::HSData)` diagnostics mirroring the R twin's
  `data_status()` surface for component presence, ID-overlap counts, pedigree
  status, genotype status, marker-alignment status, expression status,
  annotation-feature status, and environment-key status. Diagnostic only; no
  bridge payload, raw-pedigree Ainv construction, genotype parsing,
  relationship construction, annotation or environment covariate joins,
  automatic expression-feature joins, environmental model terms, marker scan,
  genomic fitting, eQTL/omics fitting, or QTL/eQTL claim.
- Recorded the R twin's `hs_data()` genotype-status diagnostics from
  `hsquared` head `f067cd9` and mirrored them in Julia `HSData` as metadata
  diagnostics only.
- Recorded the R twin's `hs_data()` expression-status diagnostics from
  `hsquared` head `06cdf59` and mirrored them in Julia `HSData` as metadata
  diagnostics only.
- Recorded the R twin's `hs_data()` annotation-feature diagnostics from
  `hsquared` head `87888d9` and mirrored them in Julia `HSData` as metadata
  diagnostics only.
- Recorded the R twin's `hs_data()` environment-key diagnostics from
  `hsquared` head `e7fbb31` and mirrored them in Julia `HSData` as metadata
  diagnostics only.
- Added `sparse_csc_matrix()` for R `Matrix::dgCMatrix` slot marshalling.
- Recorded the R twin's PEV/reliability bridge extractor contract while keeping
  Julia `result_payload()` fields unchanged.
- Recorded the R twin's tiny/local bridge enrichment of PEV/reliability from
  exported Julia extractors, still without widening base `result_payload()`.
- Recorded the R twin's supplied-variance `target = "henderson_mme"`
  enrichment from `prediction_error_variance(mme)` and `reliability(mme)`,
  still without widening base `result_payload()`.
- Recorded the R twin's opt-in supplied-variance Henderson MME bridge target,
  with explicit no-log-likelihood/no-variance-estimation boundary.
- Recorded the R twin's sparse `Z` bridge marshalling handoff.
- Recorded the R twin's optional `nadiv::Mrode9` pedigree-Ainv comparator
  evidence.
- Recorded the R twin's `model_spec()` preview surface for the v0.1
  formula-to-bridge payload.
- Recorded the R twin's `hs_data()` parser integration for the v0.1
  formula-to-bridge payload without changing the Julia payload shape.
- Recorded the R twin's `animal(1 | id)` shorthand for
  `data = hs_data(..., pedigree = ped)` as R-side formula ergonomics only; the
  explicit `animal(1 | id, pedigree = ped)` contract and Julia payload shape
  are unchanged.
- Added DocumenterVitepress documentation scaffold.
- Added audience and comparator programme notes.
- Added genomics/QTL/eQTL/GLLVM/GPU/HPC strategic roadmap.
- Added a backend and algorithm roadmap page for CPU, threads, CUDA, AMDGPU,
  Metal, oneAPI, AI-REML, Takahashi selected inversion, Woodbury paths, APY,
  and claim gates.
- Kept high-level fitting entry points as honest placeholders.
