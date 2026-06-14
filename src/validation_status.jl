const VALIDATION_STATUS_DATA = (
    (
        "V0-LOAD",
        "package loading",
        "Phase 0",
        "covered",
        "`using HSquared` is covered in the test suite.",
        "none for scaffold loading",
        "Package loads; this is not modelling evidence.",
    ),
    (
        "V1-PED",
        "pedigree normalization",
        "Phase 1",
        "covered",
        "`normalize_pedigree()` tests cover sorting, unknown parents, duplicates, cycles, self-parent, and same-parent failures.",
        "larger pedigree stress tests",
        "Pedigree validation utility only; no fitting claim.",
    ),
    (
        "V1-AINV-TINY",
        "sparse Ainv tiny checks",
        "Phase 1",
        "covered",
        "`pedigree_inverse()` tests cover founder, one-parent, two-parent, out-of-order, inbred, and dense-inverse fixtures.",
        "unknown parent groups and production-scale algorithms",
        "Direct sparse Ainv utility; not a fitted animal model.",
    ),
    (
        "V1-AINV-MRODE9",
        "Mrode9 pedigree inverse comparator",
        "Phase 1",
        "covered_external",
        "R twin optionally compares Julia `pedigree_inverse()` with `nadiv::makeAinv()` for `nadiv::Mrode9` at tolerance 1e-10.",
        "Julia-native bundled fixture intentionally absent to avoid copying optional R package data.",
        "Pedigree inverse agreement only; not fitted Mrode output validation.",
    ),
    (
        "V1-LIK",
        "Gaussian likelihood tiny checks",
        "Phase 1",
        "partial",
        "`gaussian_loglik()` has hand-calculated tiny checks and a Mrode9-shaped supplied-variance fixture with pinned ML/REML likelihood values.",
        "fitted Mrode likelihood targets and external fitted-model comparators",
        "Dense validation evaluator only; not production sparse fitting.",
    ),
    (
        "V1-SPARSE-REML",
        "sparse REML identity",
        "Phase 1",
        "partial",
        "`sparse_reml_loglik()` matches dense REML on tiny fixtures and a Mrode9-shaped supplied-variance fixture using the Henderson MME determinant identity.",
        "sparse optimizer, AI-REML, fitted Mrode likelihood validation, and external comparators",
        "Supplied-variance REML objective only; no variance-component estimation.",
    ),
    (
        "V1-SPARSE-REML-OPT",
        "sparse REML validation optimizer",
        "Phase 1",
        "partial",
        "`fit_sparse_reml()` optimizes the sparse REML objective on tiny fixtures and improves over the supplied starting variances; dense `fit_variance_components(:REML)` and sparse `fit_sparse_reml` recover the same REML optimum (variance components, heritability, log-likelihood, EBVs) on an interior 8-animal fixture, with multi-start and boundary agreement.",
        "AI-REML, fitted Mrode likelihood validation, external fitted-model comparators, production sparse diagnostics, and large sparse fixtures",
        "Experimental REML-only validation optimizer; not AI-REML, not the default fit path, and not production sparse fitting.",
    ),
    (
        "V1-MME",
        "Henderson MME supplied-variance solve",
        "Phase 1",
        "partial",
        "`henderson_mme()` matches the shared R/Julia supplied-variance fixture for Ainv, fixed effects, EBVs, fitted values, and h2; R head ca8bce1 also compares Julia against an independent R MME reference when available; Julia also has a Mrode9-shaped supplied-variance fixture for Ainv, fixed effects, EBVs, fitted values, PEV, reliability, accuracy, and h2.",
        "Mrode fitted-output fixture, external fitted-model comparators, variance-component estimation, and production sparse solve validation",
        "Supplied variance components only; no variance-component estimation or fitted Mrode claim.",
    ),
    (
        "V1-DENSE-OUT",
        "dense output extractors",
        "Phase 1",
        "partial",
        "breeding_values(fit), EBV(fit), BLUP(fit), and fitted_values(fit) are MME-backed at the fit's variance components; heritability, PEV, reliability, and checked accuracy tests match hand checks, MME inverse blocks, and a Mrode9-shaped supplied-variance fixture; variance components, heritability, PEV, reliability, and range-checked accuracy also cover supplied-variance HendersonMMEResult objects.",
        "fitted textbook Mrode outputs, independent accuracy validation, and external comparator checks for fitted outputs",
        "Experimental dense low-level outputs only; accuracy is derived from reliability.",
    ),
    (
        "V1-SELINV-PEV",
        "sparse selected-inversion PEV/reliability",
        "Phase 1",
        "partial",
        "`prediction_error_variance`/`reliability` accept `method = :selinv`, using a Takahashi selected inverse of the sparse Henderson MME coefficient matrix; the selected-inverse diagonal matches the dense MME inverse diagonal to machine precision on the tiny and Mrode9-shaped fixtures. Kernel adapted from DRM.jl (MIT).",
        "production-scale and large-pedigree sparse validation, fitted Mrode outputs, and external comparator checks",
        "Experimental sparse PEV path; exact at the L+Lᵀ pattern (diagonal/PEV exact); the default extractor path remains dense.",
    ),
    (
        "V1-AI-REML",
        "average-information REML estimator",
        "Phase 1",
        "covered",
        "`fit_ai_reml` estimates the two variance components by average-information REML on the sparse MME (score from the Takahashi selected inverse, AI matrix from working-variate re-solves); it recovers the same optimum as the dense/sparse NelderMead optimizers on tiny and simulated fixtures, and its AI matrix matches an independent finite-difference REML Hessian to ~8% (see V1-HERIT-CI). Known-truth recovery is validated externally in the R lane (`hsquared` via the bridge): a replicated DGP study (data-raw/dgp-recovery-study.R) shows near-unbiased recovery of the generating variance components (0 within bias ± 2·MCSE over 120 reps, 100% converged) with EBV accuracy tracking the true breeding values, and the engine recovers the published gryphon birth-weight REML estimate (Wilson et al. 2010) exactly via supplied A_gryphon.",
        "Julia-native recovery and fitted-Mrode fixtures, large-pedigree/boundary hardening, and >2-component generalization",
        "Experimental Gaussian-only REML estimator; the AI form is exact for the Gaussian linear mixed model but not for non-Gaussian/Laplace models (which need observed-information Newton); known-truth recovery and the published-anchor match are validated in the R lane via the bridge.",
    ),
    (
        "V1-MRODE-FIT",
        "fitted animal-model outputs vs a published estimate",
        "Phase 1",
        "covered_external",
        "Validated externally in the R lane (`hsquared` via the bridge): the engine (`fit_sparse_reml` and `fit_ai_reml`) recovers the published gryphon birth-weight REML estimate (Wilson et al. 2010: VA=3.3954, VE=3.8286, h2=0.470) exactly via supplied A_gryphon, within the maintainer-signed-off band (variance components ~1-2% relative, h2 ~0.01-0.02 absolute). The raw gryphon pedigree is pathological (ancestral loops) and the engine correctly rejects it, so the anchor uses the published relationship matrix. Data from CRAN package enhancer.",
        "a Julia-native fitted-output fixture and additional published estimated-VC sources",
        "Fitted animal-model recovery against a published external estimate; validated via the R-lane bridge, not a Julia-native bundled fixture.",
    ),
    (
        "V1-COMPARATORS",
        "external fitted-model comparators",
        "Phase 1",
        "covered_external",
        "Validated externally in the R lane: hsquared's REML estimate agrees with the external sommer package (`mmes`, REML) on the gryphon animal model within the maintainer-signed-off band (variance components ~1-2% relative, h2 ~0.01-0.02 absolute), and the engine reaches the same optimum. The pedigreemm at-least-as-good-by-logLik check remains a one-sided floor only.",
        "ASReml/BLUPF90-family parity, multi-trait comparator coverage, and Julia-native comparator harness",
        "REML variance-component / h2 agreement against one CRAN comparator (sommer) on one anchor; not multi-package or multi-trait parity.",
    ),
    (
        "V1-HERIT-CI",
        "variance-component covariance and heritability interval",
        "Phase 1",
        "partial",
        "`variance_component_covariance` / `variance_component_standard_errors`, `heritability_standard_error`, and `heritability_interval` (logit-delta, always in (0,1)) build on the REML AI matrix; the AI matrix matches an independent finite-difference REML Hessian (~8%), the interval contains the estimate and nests by level, and the Acklam normal quantile matches known z-values, in `test/runtests.jl`.",
        "large-n coverage calibration, profile-likelihood / parametric-bootstrap alternatives, and ML (non-REML) information",
        "Asymptotic, REML-only; unreliable at small n (wide interval, ill-conditioned AI matrix); not a coverage-calibrated interval.",
    ),
    (
        "V2-GRM",
        "genomic relationship matrix (VanRaden G)",
        "Phase 2",
        "partial",
        "`genomic_relationship_matrix` builds VanRaden `G = ZZ'/(2Σp(1-p))` from a 0/1/2 (or dosage) marker matrix; validated on a tiny hand-computed fixture (symmetric, PSD, pinned entries) in `test/runtests.jl`.",
        "GBLUP wiring, single-step, real marker datasets, and external comparator (AGHmatrix/sommer/BLUPF90) checks",
        "Experimental construction utility only; no genomic prediction, fitting, single-step, or marker-effect claim.",
    ),
    (
        "V2-GINV",
        "regularized genomic inverse (Ginv)",
        "Phase 2",
        "partial",
        "`genomic_relationship_inverse(G; ridge)` returns the ridge-regularized dense inverse `inv(G + ridge·I)`; tested for the defining identity `(G + ridge·I)·Ginv ≈ I`, symmetry, a pinned hand inverse at `ridge = 0`, a rank-deficient marker-`G` round-trip, and square/PD/negative-ridge guards in `test/runtests.jl`.",
        "GBLUP wiring into the MME, single-step `A`/`G` blending (`H`-matrix), and external comparator checks",
        "Construction utility only; not wired into model fitting, and no single-step or genomic-prediction claim.",
    ),
    (
        "V2-GBLUP",
        "genomic BLUP supplied-variance solve",
        "Phase 2",
        "partial",
        "`fit_gblup` feeds a genomic `Ginv` into the existing Henderson MME; matches an independent dense MME assembly to ~1e-15 and reproduces pedigree BLUP exactly when `G = A` (~1e-30) in `test/runtests.jl`; genomic reliability/PEV/accuracy reuse the existing extractors with the `diag(inv(Ginv)) = diag(G)+ridge` denominator and selinv PEV matches the dense diagonal (pinned).",
        "real markers→G→GEBV pipeline, sparse/APY `G`, and AGHmatrix/sommer/BLUPF90 comparator parity (genomic REML estimation now covered by `V2-GREML`)",
        "Supplied-variance genomic solve only; no genomic variance-component estimation, no single-step, no external comparator parity.",
    ),
    (
        "V2-SNPBLUP",
        "SNP-BLUP / GBLUP equivalence",
        "Phase 2",
        "partial",
        "`fit_snp_blup` (centered markers, identity prior, `σ²_marker = σ²_g/k`) gives GEBV `= W·â` equal to GBLUP GEBV (via the marginal `V`) to ~1e-15 for `n<m` and `n>m`; `k`, marker effects, and predictions pinned in `test/runtests.jl`.",
        "REML estimation of `σ²_g`, weighted/standardized-marker variants, low-rank Woodbury solve for `m≫n`, and JWAS/sommer/BLUPF90 comparator parity",
        "Supplied-variance VanRaden method-1 marker model only; no variance-component estimation, no external comparator, no weighted/Bayesian marker priors.",
    ),
    (
        "V2-SSHINV",
        "single-step H-inverse construction",
        "Phase 2",
        "partial",
        "internal `_single_step_Hinv` assembles `H⁻¹ = A⁻¹ + scatter(τG⁻¹ − ωA₂₂⁻¹)` on sorted genotyped rows; reduces to `A⁻¹` when `G = A₂₂` (~0), locality and symmetry hold, the `A₂₂⁻¹ ≠ (A⁻¹)[g,g]` distinctness guard (1.833 vs 2.5) is pinned, scattered genotyped rows are covered, and a singular raw `G` throws in `test/runtests.jl`.",
        "comparator-validated blending/tuning defaults (AGHmatrix::Hmatrix / BLUPF90), a Mrode Ch.11 worked H/H⁻¹ fixture, fitting wiring, and sparse/APY scaling",
        "Dense construction utility only; not exported, not wired into fitting, blending/τ/ω defaults not comparator-validated, no single-step prediction claim.",
    ),
    (
        "V2-GREML",
        "genomic REML variance-component estimation",
        "Phase 2",
        "partial",
        "the existing REML optimizers estimate the genomic variance components on a `Ginv` spec: `fit_ai_reml` and `fit_sparse_reml` reach the same optimum (loglik, σ², EBVs) on a genomic fixture, and `fit_gblup` at the estimated components reproduces the REML breeding values, in `test/runtests.jl`; a seeded n=400 simulation recovers σ²g (1.0→0.997) and h² (0.40→0.42) (one-off, not committed to keep the suite RNG-free).",
        "external comparator (sommer/rrBLUP/BLUPF90) VC parity, larger/boundary fixtures, and a committed recovery study",
        "Reuses the Phase-1 REML optimizers on a genomic spec; no external comparator parity and no production sparse-`G` scaling.",
    ),
    (
        "V3-REPEAT",
        "repeatability / permanent-environment supplied-variance solve",
        "Phase 3",
        "partial",
        "`repeatability_mme` solves the two-random-effect (additive + permanent-environment) animal model at supplied variance components; matches an independent marginal-GLS BLUP to ~1e-9 and reduces to the animal model as `sigma_pe2 → 0`, with a pinned repeated-records fixture in `test/runtests.jl`.",
        "the R `permanent()`/repeatability model-spec mapping, multi-effect extractors, and comparator checks (REML estimation now covered by `V3-REPEAT-REML`)",
        "Supplied-variance two-random-effect solve only; no R-facing model-spec, engine-internal.",
    ),
    (
        "V3-REPEAT-REML",
        "repeatability REML variance-component estimation",
        "Phase 3",
        "partial",
        "`fit_repeatability_reml` estimates (σ²a, σ²pe, σ²e) by maximizing the dense two-random-effect REML log-likelihood; the log-likelihood reduces to the animal-model REML up to a constant when σ²pe = 0, its BLUPs match the sparse `repeatability_mme` at a supplied point, and the optimum beats a coarse grid, in `test/runtests.jl`. A seeded n=70 simulation recovers (1.0, 0.6, 1.5) as ≈(0.94, 0.83, 1.48) and t (0.516→0.545) (one-off, not committed to keep the suite RNG-free).",
        "an RNG-based committed recovery harness, repeatability-coefficient / h² intervals, larger/boundary fixtures, and external comparator checks",
        "Dense validation-scale REML over three variance components; no committed recovery test, no uncertainty intervals, no external comparator, no R-facing model-spec.",
    ),
    (
        "V3-TWOEFFECT",
        "general two-random-effect MME (common environment, maternal)",
        "Phase 3",
        "partial",
        "`two_effect_mme` solves a model with two independent random effects (each with its own incidence, relationship inverse, and variance); validated on a common-environment fixture against an independent marginal-GLS BLUP (~1e-9), and `repeatability_mme` is its `Z2=Z1, A2=I` special case (identical BLUPs), in `test/runtests.jl`.",
        "correlated direct–maternal genetic effects (2×2 G), the R `common_env()`/maternal model-spec mapping, and comparator checks (REML estimation now covered by `V3-TWOEFFECT-REML`)",
        "Supplied-variance, two INDEPENDENT random effects only; no correlated maternal genetic, no R-facing model-spec.",
    ),
    (
        "V3-TWOEFFECT-REML",
        "two-effect REML (common-environment / maternal estimation)",
        "Phase 3",
        "partial",
        "`fit_two_effect_reml` estimates (σ1, σ2, σe²) of the general two-effect model by dense REML; it equals `fit_repeatability_reml` in the `Z2=Z1, A2=I` reduction, the loglik reduces to the animal-model REML at σ2=0, and a common-environment fit converges with valid ratios, in `test/runtests.jl`. A seeded common-env sim recovers σc²/σe² well (σa² underestimated on a small confounded design) (one-off).",
        "an RNG-based committed recovery harness, ratio intervals, larger/identifiable designs, and external comparator checks",
        "Dense validation-scale REML; no committed recovery test, no intervals, no correlated maternal genetic, no R-facing model-spec.",
    ),
    (
        "V4-MULTIVARIATE",
        "multivariate (multi-trait) animal model (supplied covariance)",
        "Phase 4",
        "partial",
        "`multivariate_mme` solves the multi-trait animal model at supplied genetic/residual covariance matrices `G0`, `R0` (Kronecker MME: genetic precision `Ainv⊗G0⁻¹`, residual precision block-diagonal over individuals); its β and EBVs match an independent loop-built multivariate MME, an independent marginal-GLS BLUP, the standard univariate animal model in the `t=1` reduction, and t independent single-trait fits when `G0`, `R0` are diagonal — all to a committed 1e-10 tolerance (observed agreement is machine precision, ~1e-14), in `test/runtests.jl`. Unbalanced / missing-trait records (`missing`/`NaN` in `Y`) are handled via per-individual residual precision `inv(R0[S_i,S_i])`, validated against an independent loop-built MME and marginal-GLS BLUP on a missing-data fixture (committed 1e-9, observed ~1e-13), reducing to the balanced path when no records are missing. `genetic_correlation`, `variance_components`, `fixed_effects`, `breeding_values`/`EBV`/`BLUP`, copy-return behavior, and invalid-result guards are tested for multivariate result `NamedTuple`s. Adversarial-review hardening: non-finite observed phenotypes (`Inf`), non-finite `X`/`Z`/`Ainv`, and empty-trait columns are rejected with clear errors (regression-tested).",
        "per-trait fixed-effect and incidence designs, a published Mrode multi-trait fixture, and JWAS/sommer/ASReml-style external comparators (covariance-matrix estimation now covered by `V4-MV-REML`)",
        "Supplied-covariance with a design shared across traits; handles missing-trait records and Julia-side result accessors, but does not estimate G0/R0 and has no R-facing multivariate model-spec or bridge payload change.",
    ),
    (
        "V4-MV-REML",
        "multivariate REML (genetic/residual covariance estimation)",
        "Phase 4",
        "partial",
        "`fit_multivariate_reml` estimates `G0`, `R0` by dense multivariate REML (log-Cholesky-parameterized NelderMead on `V = Z(A⊗G0)Z' + block-diag R`, handling missing records). Correctness is pinned by deterministic checks in `test/runtests.jl`: the `t=1` reduction recovers the univariate REML estimate (`fit_sparse_reml`) to <1% on an interior-optimum fixture; the multivariate REML log-likelihood (`_multivariate_reml_loglik`) equals the univariate `sparse_reml_loglik` exactly at `t=1` (~1e-7) — it is the full REML loglik including the `(N−p')·log(2π)` constant, on the package-wide loglik scale; the fitted optimum beats a coarse `(G0,R0)` grid; the returned EBVs equal `multivariate_mme` at the estimate; and `variance_components`, `fixed_effects`, `heritability`, and `breeding_values`/`EBV`/`BLUP` return the existing result fields through copy-returning Julia accessors. `test/fixtures/phase4_multitrait_parity/` serializes a deterministic two-trait parity fixture (pedigree, phenotypes, Julia REML target `G0`/`R0`, beta, EBVs, h², and loglik) for R-lane comparator work; its README plus `docs/dev-log/decisions/2026-06-14-multitrait-comparator-protocol.md` define the comparator protocol without claiming comparator evidence. CI checks fast self-consistency at the stored target covariances without re-running the optimizer. Opt-in script `sim/phase4_multivariate_reml_recovery.jl` records seeded two-trait known-truth recovery on a repeated-record half-sib design outside CI, accepts `--seed` or explicit `--seeds` lists, and prints summaries (seed 20260616: G relative error 0.174500, R relative error 0.131056, thresholds 0.25/0.20). The multivariate recovery calibration protocol was executed on the predeclared 10-seed unstructured set and did not pass: all 10 fits converged, 6/10 passed, and deterministic failure-mode triage found 3 G-only failures plus 1 G+R failure. A 7-lens adversarial review (each finding verified by running Julia) was run; its confirmed robustness findings — non-finite/empty-trait input guards and the REML loglik constant — are fixed and regression-tested.",
        "standard errors / likelihood-ratio tests for the covariances, a passing or revised broad multi-seed calibration protocol, a published Mrode multi-trait estimate, and JWAS/sommer/ASReml comparator parity",
        "Experimental dense/validation-scale multivariate REML; correctness is self-consistency + univariate-reduction validated and adversarial-reviewed (robustness findings fixed), Julia-side accessors wrap existing fields without widening `result_payload()`, an opt-in seeded recovery harness exists outside CI with explicit seed-list reporting, and a serialized Julia target fixture plus comparator protocol exists for R-lane parity work, but the executed calibration protocol did not pass, recovery is not broadly multi-seed calibrated, and there is no external-comparator parity yet; not the public default and no R-facing model-spec.",
    ),
    (
        "V4-FA",
        "structured multivariate genetic covariance (diag/lowrank/fa)",
        "Phase 4B",
        "partial",
        "`diagonal_covariance`, `lowrank_covariance`, and `factor_analytic_covariance` build `diag(σ²)`, `ΛΛ'`, and `ΛΛ' + Ψ` trait covariance matrices with finiteness/positivity guards. `fit_multivariate_reml(...; genetic_structure = :diagonal | :lowrank | :factor_analytic, rank = K)` reuses the dense multivariate REML core with constrained genetic covariance and unstructured residual covariance. Deterministic checks in `test/runtests.jl` pin constructor identities/guards, structure metadata, `genetic_structure`/`genetic_loadings`/`genetic_uniqueness` copy-returning accessors, returned loglik equality to `_multivariate_reml_loglik`, PSD/PD covariance properties, constrained fits not exceeding the unstructured REML loglik, and deterministic sign-canonicalization of returned loading columns. The rotation-identifiability decision note records sign-only metadata as the current convention and defers rotation/interpretation. Opt-in script `sim/phase4b_structured_covariance_recovery.jl` records seeded low-rank and factor-analytic recovery on a repeated-record half-sib design, accepts explicit `--seeds` lists, and prints per-case summaries; it is not part of CI. The multivariate recovery calibration protocol was executed on predeclared 10-seed structured sets and did not pass: all fits converged, factor-analytic passed 8/10, low-rank passed 9/10, and deterministic failure-mode triage found factor-analytic G-only/G+R failures plus one low-rank R-only failure.",
        "full loading rotation/interpretation convention, covariance SEs or LRTs, published multi-trait fixtures, a passing or revised broad multi-seed calibration protocol, and sommer/ASReml/BLUPF90 comparator parity",
        "Experimental dense/validation-scale engine API only; copy-returning structured-metadata accessors expose existing fields locally; returned loadings are sign-canonicalized under a sign-only convention but not rotation-identified, opt-in recovery evidence is internal and seeded, the executed calibration protocol did not pass, no R-facing covariance-structure syntax, no bridge/result-payload change, no production sparse FA solver, and no external comparator evidence.",
    ),
    (
        "V5-MARKER-FIXED",
        "fixed-effect single-marker scan",
        "Phase 5",
        "partial",
        "`single_marker_scan` residualizes `y` and centered marker dosages against `X`, then returns marker effects, supplied-variance standard errors, Wald z-scores, χ² statistics, approximate two-sided Gaussian/Wald p-values, Bonferroni-adjusted p-values, Benjamini-Hochberg q-values, and fixed-effect known-variance LOD-equivalent scores (`chisq / (2log(10))`). `marker_scan_table` prepares row-aligned scan tables in original scan order, with allele variances, marker-variance contributions, optional total-variance proportions, optional scan variance components / marker groups when present, and optional `HSMarkerMapSpec` / `HSData` chromosome-position alignment by exact marker ID. `marker_effects` prepares sorted top-marker effect summaries with the same marker-metadata alignment. `marker_variance_explained` prepares sorted marker-level variance-contribution summaries as `2p(1-p) * effect^2`, with optional total-variance proportions and the same marker-metadata alignment. `marker_manhattan_data` prepares plot-ready marker IDs, chromosome labels, positions, cumulative plot positions, raw p-values, and `-log10(p)` values from direct scan output without drawing plots; it can also consume already-validated `HSMarkerMapSpec` / `HSData` marker metadata and align chromosome/position values by exact marker ID. `marker_region_data` prepares deterministic one-chromosome or chromosome-window slices from the same row-aligned scan fields, preserving original scan indices and optional marker-variance proportions for future regional plot/fine-mapping front ends without activating them. `marker_significance_summary` reports nominal returned-marker-set raw, Bonferroni, and BH significance flags/counts plus top-marker provenance from the same scan fields. `marker_qq_data` prepares QQ plot data with sorted observed p-values, expected uniform order-statistic p-values, sorted marker IDs, observed/expected `-log10` values, and p-floor display handling. `marker_genomic_inflation` computes a genomic-control-style λGC diagnostic from returned χ² values for fixed, mixed, and LOCO direct scans. Deterministic tests pin hand-computed scan effects (`17/14`, `0.5`), p-values, Bonferroni/BH adjustments, LOD-score identity, scan-table order/variance/proportion/metadata/optional-field behavior, marker-effect summary ordering/top-N/metadata alignment, marker-variance summary identities/top-N/proportions/metadata alignment, marker-significance summary raw/Bonferroni/BH flags/counts/top-marker provenance, Manhattan defaults, chromosome-offset ordering, marker-map-backed metadata alignment, regional marker-window filtering/order/flank/p-floor handling, Manhattan and QQ p-floor handling, QQ order/expected p-values, λGC median-χ² identities, covariate-adjusted scan consistency, default/supplied marker IDs, and guardrails for invalid residual variance, marker metadata lengths/values, duplicate or mismatched marker-map IDs, invalid p-value adjustment inputs, invalid genomic-inflation, marker-significance-summary, marker-scan-table, marker-region, marker-effect-summary, and marker-variance-summary inputs, collinear markers, rank-deficient `X`, row-count mismatch, and malformed QQ inputs. Opt-in script `sim/phase5_marker_scan_recovery.jl` records seeded fixed, supplied-variance mixed, and supplied LOCO marker-signal recovery outside CI; default seed 20260614 passes all three cases with top causal marker `m08`, effect relative errors 0.008513 / 0.000349 / 0.019075, and no calibrated threshold claim.",
        "mixed-model marker scans with relationship correction, LOCO, QTL/eQTL intervals, calibrated mixed-model p-values, calibrated PVE or model R² claims, interval-mapping or mixed-model LOD workflows, actual plotting backends, advanced/correlated-marker multiple-testing workflows, calibrated/correlated-marker genome-wide thresholds, external comparator parity, and R-facing `marker_scan()` syntax",
        "Fixed-effect Gaussian screening utility with row-aligned scan-table, marker-effect, marker-variance-contribution, marker-map-backed Manhattan, regional marker-window data, nominal returned-marker-set significance summary, QQ, and inflation diagnostic helpers only, using supplied residual variance plus approximate Wald p-values, Bonferroni/BH adjustments, LOD-equivalent scores, Manhattan data, regional data, nominal raw/Bonferroni/BH significance counts, QQ data, and a λGC diagnostic over the returned marker set; no gwas_table(), qtl_table(), or eqtl_table() activation, no regional_plot() or fine-mapping activation, no mixed-model GWAS/QTL claim, no calibrated/correlated-marker genome-wide threshold claim, no p-value calibration claim, no calibrated PVE or model R² claim, no R formula term activation, no bridge payload change, and no comparator evidence.",
    ),
    (
        "V5-MARKER-MIXED",
        "supplied-variance mixed-model marker scan",
        "Phase 5",
        "partial",
        "`mixed_model_marker_scan` forms the dense validation-scale marginal covariance `V = sigma_a2 * Z * A * Z' + sigma_e2 * I` from supplied variance components and a supplied relationship precision, then runs a marker-by-marker GLS Wald scan conditional on `X`. It returns marker effects, standard errors, z-scores, χ² statistics, approximate two-sided Gaussian/Wald p-values, Bonferroni/BH adjustments, fixed-effect known-variance LOD-equivalent scores, GLS denominators, marker IDs, allele frequencies, VanRaden scale, supplied variance components, and `target = :mixed_model_marker_scan`. Deterministic tests pin the reduction to `single_marker_scan` when the random-effect design contributes zero covariance, agreement with an independent GLS calculation on a pedigree-covariance fixture, compatibility with marker-scan-table, marker-effect, and marker-variance summaries, Manhattan/QQ plot-data, and inflation diagnostic helpers, and guardrails for variance components, dimensions, positive-definite `Ainv`, rank-deficient `X`, and marker collinearity under the supplied covariance. Opt-in script `sim/phase5_marker_scan_recovery.jl` records seeded supplied-variance mixed marker-signal recovery outside CI on a half-sib simulated random-effect design.",
        "variance-component estimation inside marker scans, LOCO, sparse production marker scans, calibrated mixed-model p-values, calibrated PVE/model R² claims, interval-mapping or mixed-model LOD workflows, advanced/correlated-marker multiple-testing workflows, plotting backends, external comparator parity, and R-facing `marker_scan()` syntax",
        "Dense validation-scale supplied-variance Julia utility only; relationship correction is by the supplied marginal covariance and tested by GLS identities, but there is no variance-component estimation, no LOCO, no p-value calibration claim, no calibrated PVE/model R² claim, no R formula activation, no bridge payload change, and no comparator evidence.",
    ),
    (
        "V5-MARKER-LOCO",
        "leave-one-group-out marker scan construction and selection",
        "Phase 5",
        "partial",
        "`loco_relationship_precisions` constructs dense leave-one-group-out VanRaden relationship precisions from marker groups by dropping each group, building `G` from the remaining markers, and applying the existing ridge-regularized inverse; `loco_mixed_model_marker_scan` then selects the supplied precision by marker group, forms the same dense validation-scale GLS covariance as `mixed_model_marker_scan`, and runs marker-by-marker Wald tests with group-specific relationship correction. Deterministic tests pin the explicit LOCO precision identities, marker-wise agreement with separate `mixed_model_marker_scan` calls using the corresponding constructed or supplied precision, preserve marker-scan-table, marker-effect, and marker-variance summaries, Manhattan/QQ plot-data, and inflation diagnostic helper compatibility, and guard missing groups, marker-group length mismatches, empty precision maps, invalid precision dimensions, invalid LOCO construction inputs, and marker collinearity under the selected covariance. Opt-in script `sim/phase5_marker_scan_recovery.jl` records seeded supplied LOCO marker-signal recovery outside CI using constructed VanRaden-plus-ridge LOCO precisions.",
        "LOCO defaults for a public workflow, marker-scan variance-component estimation, sparse production scans, calibrated mixed-model p-values, calibrated PVE/model R² claims, interval-mapping or mixed-model LOD workflows, plotting backends, external comparator parity, and R-facing `marker_scan()` syntax",
        "Dense validation-scale LOCO construction and supplied-matrix selection helpers only; LOCO precision construction uses VanRaden-plus-ridge identities and the scan uses supplied variance components, but there are no public LOCO defaults, no variance-component estimation, no p-value calibration claim, no calibrated PVE/model R² claim, no R formula activation, no bridge payload change, and no comparator evidence.",
    ),
    (
        "V5-GENOMIC-QTL",
        "genomic, marker, QTL, and eQTL validation",
        "Phase 5",
        "planned",
        "Syntax vocabulary and roadmap docs exist; the direct fixed-effect `single_marker_scan`, supplied-variance GLS `mixed_model_marker_scan`, LOCO construction `loco_relationship_precisions`, and supplied-matrix-selection `loco_mixed_model_marker_scan` utilities are tracked separately.",
        "model-spec contracts, formula-driven mixed-model marker scans, simulations, marker-map validation, public LOCO workflow defaults, genome-wide multiple-testing calibration, calibrated mixed-model p-values, calibrated PVE/model R² claims, interval-mapping or mixed-model LOD workflows, QTL/eQTL intervals, and JWAS/sommer/BLUPF90-style comparators",
        "No broad genomic/QTL/eQTL validation claim; direct Julia marker-screening utilities are experimental and tracked separately.",
    ),
)

"""
    ValidationStatusRow

Typed validation-status row returned by [`validation_status`](@ref).

Each row records the validation item, current evidence, missing evidence, and
the allowed public-claim boundary.
"""
struct ValidationStatusRow
    id::String
    capability::String
    phase::String
    status::String
    evidence::String
    missing::String
    claim_boundary::String
end

"""
    ValidationStatus

Container returned by [`validation_status`](@ref).
"""
struct ValidationStatus
    rows::Vector{ValidationStatusRow}
end

Base.length(status::ValidationStatus) = length(status.rows)
Base.firstindex(status::ValidationStatus) = firstindex(status.rows)
Base.lastindex(status::ValidationStatus) = lastindex(status.rows)
Base.getindex(status::ValidationStatus, index::Int) = status.rows[index]
Base.iterate(status::ValidationStatus, state...) = iterate(status.rows, state...)

"""
    validation_status()

Return the current validation-evidence ladder for `HSquared.jl`.

This is a diagnostic table only. It does not run comparator packages, fit
models, or promote any planned capability.
"""
function validation_status()
    rows = [
        ValidationStatusRow(id, capability, phase, status, evidence, missing, claim_boundary) for
        (id, capability, phase, status, evidence, missing, claim_boundary) in VALIDATION_STATUS_DATA
    ]

    return ValidationStatus(rows)
end
