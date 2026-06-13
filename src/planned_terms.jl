const PLANNED_MODEL_TERMS = (:genomic, :single_step, :markers, :marker_scan, :qtl_scan)

"""
    planned_model_terms()

Return the planned genomic and QTL model-term names reserved by `HSquared.jl`.

These names mirror the R twin's inert formula markers. They are vocabulary
reservations only; no genomic prediction, marker scan, single-step, QTL/eQTL,
or marker-effect estimation is implemented yet.
"""
planned_model_terms() = PLANNED_MODEL_TERMS

function _planned_model_term_error(name::Symbol)
    throw(
        ArgumentError(
            "`$(name)()` is planned, not implemented. " *
            "This reserves HSquared.jl vocabulary for later genomic/QTL model specifications; " *
            "no genomic prediction, marker scan, single-step, QTL/eQTL, or marker-effect estimation is available yet.",
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
