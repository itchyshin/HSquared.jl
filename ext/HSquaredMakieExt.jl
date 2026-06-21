module HSquaredMakieExt

# Makie drawing extension for HSquared's backend-free `*_plot_data` preparers. Loads
# only when a Makie backend is in scope (`using CairoMakie` / `GLMakie`). It draws the
# figures with the R-twin's honest-status behaviors baked in (issue #93): the caveat is
# rendered ON the figure (subtitle), whiskers are never clamped, the g-geometry view is
# a scree (never a loadings biplot), and a non-PD G suppresses %-variance labels.

using HSquared
using Makie
import HSquared: hsquared_figure

function _infer_kind(d::NamedTuple)
    (hasproperty(d, :term) && hasproperty(d, :panel)) && return :variance_components
    hasproperty(d, :pev_scale) && return :breeding_values
    hasproperty(d, :is_eigenstructure_not_loadings) && return :g_geometry
    throw(ArgumentError("hsquared_figure: cannot infer the figure kind from this data; pass `kind = :variance_components | :breeding_values | :g_geometry`"))
end

function hsquared_figure(data::NamedTuple; kind::Symbol = _infer_kind(data), kwargs...)
    kind === :variance_components && return _forest(data; kwargs...)
    kind === :breeding_values && return _caterpillar(data; kwargs...)
    kind === :g_geometry && return _scree(data; kwargs...)
    throw(ArgumentError("hsquared_figure: unknown kind :$kind (supported: :variance_components, :breeding_values, :g_geometry)"))
end

# ── set B: variance-component + heritability forest ──────────────────────────────
# RAW whiskers (never clamped); the [0,1] crossing is annotated on the h² panel ONLY
# (a variance-component whisker crossing 0 is expected/honest, not flagged); NaN → no
# whisker; the supplied/estimated honest-status hinge goes in the subtitle.
function _forest(d::NamedTuple; title = "Variance components & heritability", kwargs...)
    n = length(d.term)
    ys = collect(Float64.(n:-1:1))
    caveat = d.supplied ? "supplied (descriptive)" :
        "estimated; $(d.interval_status) intervals (NOT coverage-calibrated)"
    fig = Figure()
    ax = Axis(fig[1, 1]; title = title, subtitle = caveat, xlabel = "estimate",
              yticks = (ys, collect(string.(d.term))))
    for i in 1:n
        (isfinite(d.lo[i]) && isfinite(d.hi[i])) || continue   # no fabricated whisker
        lines!(ax, [d.lo[i], d.hi[i]], [ys[i], ys[i]]; color = :black)
    end
    scatter!(ax, Float64.(d.estimate), ys; markersize = 11, color = :black)
    vlines!(ax, [0.0]; color = :gray, linestyle = :dash)
    for i in 1:n
        d.panel[i] == "heritability" || continue   # boundary flag is h²-panel only
        if isfinite(d.lo[i]) && isfinite(d.hi[i]) && (d.lo[i] <= 0.0 || d.hi[i] >= 1.0)
            text!(ax, d.hi[i], ys[i]; text = " [0,1] boundary", align = (:left, :center),
                  fontsize = 10, color = :red)
        end
    end
    return fig
end

# ── set B: EBV caterpillar ───────────────────────────────────────────────────────
# Sorted EBV ± √PEV; the validation-scale PEV caveat goes in the subtitle.
function _caterpillar(d::NamedTuple; title = "Estimated breeding values", kwargs...)
    perm = sortperm(Float64.(d.value))
    v = Float64.(d.value)[perm]
    se = sqrt.(max.(Float64.(d.pev)[perm], 0.0))
    xs = collect(1:length(v))
    caveat = d.pev_scale == "validation" ?
        "EBV ± √PEV — PEV is VALIDATION-scale (dense inv(Ainv)), not a production reliability claim" :
        "EBV ± √PEV"
    fig = Figure()
    ax = Axis(fig[1, 1]; title = title, subtitle = caveat, xlabel = "rank (sorted)", ylabel = "EBV")
    for i in eachindex(xs)
        lines!(ax, [xs[i], xs[i]], [v[i] - se[i], v[i] + se[i]]; color = (:black, 0.4))
    end
    scatter!(ax, xs, v; markersize = 6, color = :black)
    hlines!(ax, [0.0]; color = :gray, linestyle = :dash)
    return fig
end

# ── set C: G-geometry scree ──────────────────────────────────────────────────────
# Eigenvalue SCREE only — NEVER a loadings biplot (the FA rotation convention). On a
# non-PD G (a negative eigenvalue) the bar is drawn but %-variance labels are suppressed
# (a ">100% share" is the trap).
function _scree(d::NamedTuple; title = "Genetic eigenstructure (scree)", kwargs...)
    d.is_eigenstructure_not_loadings ||
        throw(ArgumentError("g_geometry requires rotation-invariant eigenstructure; a loadings biplot is forbidden by the FA rotation convention"))
    λ = Float64.(d.eigenvalues)
    k = length(λ)
    nonpd = any(λ .< -1e-10)
    caveat = nonpd ?
        "rotation-invariant eigenvalues — G is NON-positive-definite (negative eigenvalue); %-variance labels suppressed" :
        "rotation-invariant eigenvalues (scree, NOT a loadings biplot)"
    fig = Figure()
    ax = Axis(fig[1, 1]; title = title, subtitle = caveat, xlabel = "genetic axis",
              ylabel = "eigenvalue", xticks = (collect(1:k), collect(string.(d.axis_labels))))
    barplot!(ax, collect(1:k), λ; color = :steelblue)
    if !nonpd && hasproperty(d, :variance_explained)
        ve = Float64.(d.variance_explained)
        for i in 1:k
            text!(ax, i, λ[i]; text = string(round(100 * ve[i]; digits = 1), "%"),
                  align = (:center, :bottom), fontsize = 10)
        end
    end
    return fig
end

end # module
