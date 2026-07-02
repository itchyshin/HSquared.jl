const PLANNED_GENOMIC_QTL_TERMS = (:genomic, :single_step, :markers, :marker_scan, :qtl_scan)

const PLANNED_QUANTGEN_TERMS = (
    :permanent,
    :common_env,
    :maternal_genetic,
    :maternal_env,
    :paternal_genetic,
    :paternal_env,
    :cytoplasmic,
    :imprinting,
    :dominance,
    :epistasis,
    :relmat,
    :precision,
)

const PLANNED_MODEL_TERMS = (PLANNED_GENOMIC_QTL_TERMS..., PLANNED_QUANTGEN_TERMS...)

const FORMULA_STATUS_TERMS = (
    "animal(1 | id, pedigree = ped)",
    "permanent(1 | id)",
    "common_env(1 | group)",
    "maternal_genetic(1 | dam, pedigree = ped)",
    "maternal_env(1 | dam)",
    "paternal_genetic(1 | sire, pedigree = ped)",
    "paternal_env(1 | sire)",
    "cytoplasmic(1 | maternal_line)",
    "imprinting(1 | id, pedigree = ped, parent = \"maternal\")",
    "dominance(1 | id, pedigree = ped)",
    "epistasis(1 | id, pedigree = ped)",
    "relmat(1 | id, K = K)",
    "precision(1 | id, Q = Q)",
    "genomic(1 | id, Ginv = Ginv)",
    "single_step(1 | id, Hinv = Hinv)",
    "markers(M, model = \"random\")",
    "marker_scan(M, map = marker_map)",
    "qtl_scan(position, genotype_probs = probs)",
    "animal(trait | id, pedigree = ped, cov = us())",
    "animal(trait | id, pedigree = ped, cov = fa(K = 2))",
)

const FORMULA_STATUS_CATEGORIES = (
    "v0.1 animal model",
    fill("standard quantitative genetics", 6)...,
    fill("inheritance and relationship kernels", 6)...,
    fill("genomic and marker models", 5)...,
    fill("multivariate and factor analytic", 2)...,
)

const FORMULA_STATUS_PHASES = (
    "Phase 1",
    fill("Phase 2", 6)...,
    fill("Phase 3+", 6)...,
    fill("Phase 5", 5)...,
    fill("Phase 3-4", 2)...,
)

const FORMULA_STATUS_SYNTAX = (
    "parsed",
    fill("reserved", 17)...,
    fill("planned", 2)...,
)

const FORMULA_STATUS_FITTING = (
    "experimental tiny bridge only",
    fill("not available", 19)...,
)

const FORMULA_STATUS_BEHAVIOR = (
    "Validated by the R parser; default hsquared() stops before general fitting.",
    fill(
        "Exported as an inert marker; hsquared() errors as planned, not implemented.",
        17,
    )...,
    fill(
        "Roadmap syntax; the v0.1 animal() parser rejects trait and cov arguments.",
        2,
    )...,
)

"""
    FormulaStatusRow

Typed grammar-status row returned by [`formula_status`](@ref).

Rows mirror the R twin's `formula_status()` columns: `term`, `category`,
`phase`, `syntax_status`, `fitting_status`, and `current_behavior`.
"""
struct FormulaStatusRow
    term::String
    category::String
    phase::String
    syntax_status::String
    fitting_status::String
    current_behavior::String
end

"""
    FormulaStatus

Container returned by [`formula_status`](@ref).
"""
struct FormulaStatus
    rows::Vector{FormulaStatusRow}
end

Base.length(status::FormulaStatus) = length(status.rows)
Base.firstindex(status::FormulaStatus) = firstindex(status.rows)
Base.lastindex(status::FormulaStatus) = lastindex(status.rows)
Base.getindex(status::FormulaStatus, index::Int) = status.rows[index]
Base.iterate(status::FormulaStatus, state...) = iterate(status.rows, state...)

"""
    formula_status()

Return a diagnostic table of the shared `hsquared` / `HSquared.jl` grammar
status.

This mirrors the R twin's `formula_status()` rows. It is a status diagnostic
only: it does not parse formulas, construct model specs, or enable fitting for
reserved or planned terms.
"""
function formula_status()
    rows = [
        FormulaStatusRow(
            FORMULA_STATUS_TERMS[i],
            FORMULA_STATUS_CATEGORIES[i],
            FORMULA_STATUS_PHASES[i],
            FORMULA_STATUS_SYNTAX[i],
            FORMULA_STATUS_FITTING[i],
            FORMULA_STATUS_BEHAVIOR[i],
        ) for i in eachindex(FORMULA_STATUS_TERMS)
    ]

    return FormulaStatus(rows)
end

"""
    planned_model_terms()

Return the planned model-term names reserved by `HSquared.jl`.

These names mirror the R twin's inert formula markers. They are vocabulary
reservations only; no standard quantitative-genetic extension, parental effect,
inheritance kernel, genomic prediction, marker scan, single-step, QTL/eQTL, or
marker-effect estimation is implemented yet.
"""
planned_model_terms() = PLANNED_MODEL_TERMS

"""
    planned_genomic_qtl_terms()

Return the planned genomic, single-step, marker, and QTL term names.
"""
planned_genomic_qtl_terms() = PLANNED_GENOMIC_QTL_TERMS

"""
    planned_quantgen_terms()

Return the planned standard quantitative-genetic, parental, inheritance, and
custom-kernel term names.
"""
planned_quantgen_terms() = PLANNED_QUANTGEN_TERMS

function _planned_model_term_error(name::Symbol)
    throw(
        ArgumentError(
            "`$(name)()` is planned, not implemented. " *
            "This reserves HSquared.jl vocabulary for later model specifications; " *
            "no standard quantitative-genetic extension, parental effect, inheritance kernel, " *
            "genomic prediction, marker scan, single-step, QTL/eQTL, or marker-effect estimation is available yet.",
        ),
    )
end

"""
    genomic(args...; kwargs...)

Planned genomic relationship model term.

Mirrors the R `genomic()` formula marker. This function is intentionally
not implemented yet.
"""
genomic(args...; kwargs...) = _planned_model_term_error(:genomic)

"""
    single_step(args...; kwargs...)

Planned single-step pedigree/genomic relationship model term.

Mirrors the R `single_step()` formula marker. This function is intentionally
not implemented yet.
"""
single_step(args...; kwargs...) = _planned_model_term_error(:single_step)

"""
    markers(args...; kwargs...)

Planned marker-effect model term.

Mirrors the R `markers()` formula marker. This function is intentionally
not implemented yet.
"""
markers(args...; kwargs...) = _planned_model_term_error(:markers)

"""
    marker_scan(args...; kwargs...)

Planned marker-scan / GWAS model term.

Mirrors the R `marker_scan()` formula marker. This function is intentionally
not implemented yet.
"""
marker_scan(args...; kwargs...) = _planned_model_term_error(:marker_scan)

"""
    qtl_scan(args...; kwargs...)

Planned QTL interval-scan model term.

Mirrors the R `qtl_scan()` formula marker. This function is intentionally
not implemented yet.
"""
qtl_scan(args...; kwargs...) = _planned_model_term_error(:qtl_scan)

"""
    permanent(args...; kwargs...)

Planned permanent-environment model term.

Mirrors the R `permanent()` formula marker. This function is intentionally
not implemented yet.
"""
permanent(args...; kwargs...) = _planned_model_term_error(:permanent)

"""
    common_env(args...; kwargs...)

Planned common-environment model term.

Mirrors the R `common_env()` formula marker. This function is intentionally
not implemented yet.
"""
common_env(args...; kwargs...) = _planned_model_term_error(:common_env)

"""
    maternal_genetic(args...; kwargs...)

Planned maternal-genetic model term (engine-internal formula marker).

Mirrors the R `maternal_genetic()` formula marker. This stub is intentionally
not implemented as a standalone engine path. Note: the correlated 2×2 direct–
maternal capability IS covered at validation scale (opt-in) via
`fit_direct_maternal_reml` / R `target="direct_maternal"` — this stub is only
the engine-internal formula-reservation marker, not the fitting entry point.
"""
maternal_genetic(args...; kwargs...) = _planned_model_term_error(:maternal_genetic)

"""
    maternal_env(args...; kwargs...)

Planned maternal-environment model term.

Mirrors the R `maternal_env()` formula marker. This function is intentionally
not implemented yet.
"""
maternal_env(args...; kwargs...) = _planned_model_term_error(:maternal_env)

"""
    paternal_genetic(args...; kwargs...)

Planned paternal-genetic model term.

Mirrors the R `paternal_genetic()` formula marker. This function is
intentionally not implemented yet.
"""
paternal_genetic(args...; kwargs...) = _planned_model_term_error(:paternal_genetic)

"""
    paternal_env(args...; kwargs...)

Planned paternal-environment model term.

Mirrors the R `paternal_env()` formula marker. This function is intentionally
not implemented yet.
"""
paternal_env(args...; kwargs...) = _planned_model_term_error(:paternal_env)

"""
    cytoplasmic(args...; kwargs...)

Planned cytoplasmic-inheritance model term.

Mirrors the R `cytoplasmic()` formula marker. This function is intentionally
not implemented yet.
"""
cytoplasmic(args...; kwargs...) = _planned_model_term_error(:cytoplasmic)

"""
    imprinting(args...; kwargs...)

Planned parent-of-origin / imprinting model term.

Mirrors the R `imprinting()` formula marker. This function is intentionally
not implemented yet.
"""
imprinting(args...; kwargs...) = _planned_model_term_error(:imprinting)

"""
    dominance(args...; kwargs...)

Planned dominance relationship model term.

Mirrors the R `dominance()` formula marker. This function is intentionally
not implemented yet.
"""
dominance(args...; kwargs...) = _planned_model_term_error(:dominance)

"""
    epistasis(args...; kwargs...)

Planned epistatic relationship model term.

Mirrors the R `epistasis()` formula marker. This function is intentionally
not implemented yet.
"""
epistasis(args...; kwargs...) = _planned_model_term_error(:epistasis)

"""
    relmat(args...; kwargs...)

Planned custom relationship-matrix model term.

Mirrors the R `relmat()` formula marker. This function is intentionally
not implemented yet.
"""
relmat(args...; kwargs...) = _planned_model_term_error(:relmat)

"""
    precision(args...; kwargs...)

Planned custom precision-matrix model term.

Mirrors the R `precision()` formula marker. This function is intentionally
not implemented yet.
"""
precision(args...; kwargs...) = _planned_model_term_error(:precision)
