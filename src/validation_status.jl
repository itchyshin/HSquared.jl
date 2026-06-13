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
        "`gaussian_loglik()` has hand-calculated tiny checks at supplied variance components.",
        "Mrode likelihood targets and external fitted-model comparators",
        "Dense validation evaluator only; not production sparse fitting.",
    ),
    (
        "V1-SPARSE-REML",
        "sparse REML identity",
        "Phase 1",
        "partial",
        "`sparse_reml_loglik()` matches dense REML on tiny fixtures using the Henderson MME determinant identity.",
        "sparse optimizer, AI-REML, Mrode likelihood validation, and external comparators",
        "Supplied-variance REML objective only; no variance-component estimation.",
    ),
    (
        "V1-MME",
        "Henderson MME supplied-variance solve",
        "Phase 1",
        "partial",
        "`henderson_mme()` matches the shared R/Julia supplied-variance fixture for Ainv, fixed effects, EBVs, fitted values, and h2; R head ca8bce1 also compares Julia against an independent R MME reference when available.",
        "Mrode fitted-output fixture, external fitted-model comparators, variance-component estimation, and production sparse solve validation",
        "Supplied variance components only; no variance-component estimation or fitted Mrode claim.",
    ),
    (
        "V1-DENSE-OUT",
        "dense output extractors",
        "Phase 1",
        "partial",
        "breeding_values(fit), EBV(fit), BLUP(fit), and fitted_values(fit) are MME-backed at the fit's variance components; heritability, PEV, reliability, and checked accuracy tests match hand checks and MME inverse blocks; variance components, heritability, PEV, reliability, and range-checked accuracy also cover supplied-variance HendersonMMEResult objects.",
        "textbook Mrode, independent accuracy validation, and external comparator checks for fitted outputs",
        "Experimental dense low-level outputs only; accuracy is derived from reliability.",
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
