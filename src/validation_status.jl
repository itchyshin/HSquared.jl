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
        "partial",
        "`fit_ai_reml` estimates the two variance components by average-information REML on the sparse MME (score from the Takahashi selected inverse, AI matrix from working-variate re-solves); it recovers the same optimum as the dense/sparse NelderMead optimizers on tiny + simulated fixtures, and its AI matrix matches the observed information (ratio ~0.99) on a 250-animal simulation.",
        "external comparator checks, Mrode fitted validation, large-pedigree/boundary hardening, and >2-component generalization",
        "Experimental Gaussian-only REML estimator; the AI form is exact for the Gaussian linear mixed model but not for non-Gaussian/Laplace models (which need observed-information Newton); not the public default.",
    ),
    (
        "V1-MRODE-FIT",
        "fitted Mrode animal-model outputs",
        "Phase 1",
        "planned",
        "No source-recorded fitted response, estimator target, variance components, EBVs, or h2 fixture yet.",
        "response data, fixed effects, estimator target, expected variance components, EBVs, h2, comparator versions, and tolerances",
        "Fitted Mrode validation is not covered.",
    ),
    (
        "V1-COMPARATORS",
        "external fitted-model comparators",
        "Phase 1",
        "planned",
        "No ASReml, BLUPF90, DMU, WOMBAT, sommer, or MCMCglmm fitted-output comparison yet.",
        "comparator package versions, matching estimands, seeds if applicable, and tolerances",
        "No fitted comparator parity claim.",
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
        "V5-GENOMIC-QTL",
        "genomic, marker, QTL, and eQTL validation",
        "Phase 5",
        "planned",
        "Only syntax vocabulary and roadmap docs exist.",
        "model-spec contracts, simulations, marker-map validation, multiple-testing checks, and JWAS/sommer/BLUPF90-style comparators",
        "No genomic prediction, marker scan, QTL, or eQTL support.",
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
