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

Planned maternal-genetic model term.

Mirrors the R `maternal_genetic()` formula marker. This function is
intentionally not implemented yet.
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
