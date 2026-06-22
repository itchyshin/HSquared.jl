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
    # g_geometry MUST precede rr_eigenfunctions: both carry `eigenvalues` +
    # `variance_explained` + `rotation_invariant`, but only g_geometry is tagged
    # `is_eigenstructure_not_loadings` and only rr_eigenfunctions carries `eigenfunctions`.
    hasproperty(d, :is_eigenstructure_not_loadings) && return :g_geometry
    hasproperty(d, :genetic_correlations) && return :genetic_correlation
    hasproperty(d, :plot_positions) && return :manhattan
    hasproperty(d, :expected_neglog10_p_values) && return :qq
    hasproperty(d, :genetic_variance) && return :rr_variance
    hasproperty(d, :surface) && return :rr_surface
    hasproperty(d, :eigenfunctions) && return :rr_eigenfunctions
    throw(ArgumentError("hsquared_figure: cannot infer the figure kind from this data; pass `kind = :variance_components | :breeding_values | :g_geometry | :genetic_correlation | :manhattan | :qq | :rr_variance | :rr_surface | :rr_eigenfunctions`"))
end

function hsquared_figure(data::NamedTuple; kind::Symbol = _infer_kind(data), kwargs...)
    kind === :variance_components && return _forest(data; kwargs...)
    kind === :breeding_values && return _caterpillar(data; kwargs...)
    kind === :g_geometry && return _scree(data; kwargs...)
    kind === :genetic_correlation && return _heatmap(data; kwargs...)
    kind === :manhattan && return _manhattan(data; kwargs...)
    kind === :qq && return _qq(data; kwargs...)
    kind === :rr_variance && return _reaction_norm(data; kwargs...)
    kind === :rr_surface && return _rr_surface(data; kwargs...)
    kind === :rr_eigenfunctions && return _eigenfunctions(data; kwargs...)
    throw(ArgumentError("hsquared_figure: unknown kind :$kind (supported: :variance_components, :breeding_values, :g_geometry, :genetic_correlation, :manhattan, :qq, :rr_variance, :rr_surface, :rr_eigenfunctions)"))
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

# ── set C: genetic-correlation heatmap ───────────────────────────────────────────
# The rotation-INVARIANT genetic correlation `D⁻¹GD⁻¹` (unit diagonal, off-diagonals
# in [-1,1]) — NEVER raw loadings. Cells involving a low-h² trait are imprecise; if
# heritabilities are supplied the low-h² traits are flagged in the subtitle (the #93
# set-C honest-status behavior). Diverging colormap centred at 0.
function _heatmap(d::NamedTuple; title = "Genetic correlations", low_h2 = 0.1, kwargs...)
    d.rotation_invariant ||
        throw(ArgumentError("genetic_correlation requires the rotation-invariant correlation (D⁻¹GD⁻¹); raw loadings are forbidden by the FA rotation convention"))
    R = Matrix{Float64}(d.genetic_correlations)
    labels = collect(string.(d.traits))
    p = length(labels)
    # flag low OR non-finite h² — a missing/NaN h² is maximally imprecise, so it must
    # be flagged too (NaN < low_h2 is false, which would silently drop it otherwise).
    flagged = d.heritabilities === nothing ? String[] :
        labels[findall(h -> !isfinite(h) || h < low_h2, Float64.(d.heritabilities))]
    caveat = isempty(flagged) ?
        "rotation-invariant D⁻¹GD⁻¹ (unit diagonal); NOT raw loadings" :
        "rotation-invariant D⁻¹GD⁻¹; ⚠ low-h² (<$(low_h2), imprecise) trait(s): $(join(flagged, ", "))"
    fig = Figure()
    ax = Axis(fig[1, 1]; title = title, subtitle = caveat,
              xticks = (collect(1:p), labels), yticks = (collect(1:p), labels),
              yreversed = true, xticklabelrotation = π / 4)
    hm = heatmap!(ax, 1:p, 1:p, R; colormap = :RdBu, colorrange = (-1.0, 1.0))
    for i in 1:p, j in 1:p
        text!(ax, i, j; text = string(round(R[i, j]; digits = 2)),
              align = (:center, :center), fontsize = 10,
              color = abs(R[i, j]) > 0.6 ? :white : :black)
    end
    Colorbar(fig[1, 2], hm; label = "genetic correlation")
    return fig
end

# ── set D: Manhattan (genomic scan) ──────────────────────────────────────────────
# Scatter of cumulative `plot_positions` vs −log10(p), chromosome-coloured, with a
# VISUAL-ONLY Bonferroni guide line. The nominal-p / NOT-genome-wide-calibrated caveat
# (#48) is rendered in the subtitle — mirrors the R `hs_autoplot_manhattan`. λGC is NOT
# computed here; the drawing layer carries no /src numerics.
function _manhattan(d::NamedTuple; title = "Marker scan (Manhattan)", kwargs...)
    x = Float64.(d.plot_positions)
    y = Float64.(d.neglog10_p_values)
    chrom = collect(string.(d.chromosomes))
    uchrom = unique(chrom)                                   # distinct chromosomes, carried order
    palette = [:steelblue, :darkorange]
    cidx = Dict(c => i for (i, c) in enumerate(uchrom))
    colors = [palette[((cidx[c] - 1) % length(palette)) + 1] for c in chrom]
    fig = Figure()
    ax = Axis(fig[1, 1]; title = title,
              subtitle = "nominal Wald p-values, NOT genome-wide calibrated (#48); threshold line is visual guidance only",
              xlabel = "genome position (cumulative)", ylabel = "-log10(p)")
    scatter!(ax, x, y; color = colors, markersize = 6)
    bonf = -log10(0.05 / length(d.p_values))                # VISUAL-ONLY Bonferroni guide
    hlines!(ax, [bonf]; color = :gray, linestyle = :dash)
    text!(ax, minimum(x), bonf; text = " Bonferroni 0.05 (visual only)",
          align = (:left, :bottom), fontsize = 10, color = :gray)
    return fig
end

# ── set D: QQ plot ───────────────────────────────────────────────────────────────
# Observed vs expected −log10(p) with the y=x uniform-null line. λGC is INTENTIONALLY
# NOT annotated: the qq preparer carries no χ², and recomputing genomic inflation in the
# drawing layer would both duplicate /src numerics and risk an uncalibrated diagnostic
# being read as calibrated. Mirrors the R `hs_autoplot_qq`.
function _qq(d::NamedTuple; title = "Marker scan (QQ)", kwargs...)
    ex = Float64.(d.expected_neglog10_p_values)
    ob = Float64.(d.observed_neglog10_p_values)
    fig = Figure()
    ax = Axis(fig[1, 1]; title = title,
              subtitle = "nominal Wald p-values, NOT genome-wide calibrated (#48); y=x is the uniform null",
              xlabel = "expected -log10(p)", ylabel = "observed -log10(p)")
    scatter!(ax, ex, ob; markersize = 6, color = :black)
    ablines!(ax, [0.0], [1.0]; color = :gray, linestyle = :dash)   # y = x null
    return fig
end

# ── set A (RR): reaction-norm genetic-variance trajectory ────────────────────────
# v_g(t), plus the h²(t) trajectory ONLY when a residual was supplied (else a single
# panel + a "no residual" note). The supplied-K_g-descriptive + h²-can-overstate-without-
# a-PE-term caveat is in the subtitle — mirrors the R `hs_autoplot_reaction_norm`.
function _reaction_norm(d::NamedTuple; title = "Random-regression genetic variance", kwargs...)
    t = Float64.(d.covariate)
    vg = Float64.(d.genetic_variance)
    has_h2 = d.heritability !== nothing
    caveat = "supplied-K_g descriptive (not REML, not phenotypic)" *
             (has_h2 ? "; h²(t) can overstate without a permanent-environment term" :
                       "; no residual supplied → no h²(t)")
    fig = Figure()
    if has_h2
        ax1 = Axis(fig[1, 1]; title = title, subtitle = caveat, ylabel = "genetic variance v_g(t)")
        lines!(ax1, t, vg; color = :steelblue)
        scatter!(ax1, t, vg; color = :steelblue, markersize = 6)
        ax2 = Axis(fig[2, 1]; xlabel = "covariate t", ylabel = "h²(t)")
        h2 = Float64.(d.heritability)
        lines!(ax2, t, h2; color = :darkorange)
        scatter!(ax2, t, h2; color = :darkorange, markersize = 6)
    else
        ax1 = Axis(fig[1, 1]; title = title, subtitle = caveat,
                   xlabel = "covariate t", ylabel = "genetic variance v_g(t)")
        lines!(ax1, t, vg; color = :steelblue)
        scatter!(ax1, t, vg; color = :steelblue, markersize = 6)
    end
    return fig
end

# ── set A (RR): covariance / correlation surface heatmap ─────────────────────────
# Diverging RdBu centred at 0. The correlation surface is bounded [-1,1] (fixed
# colorrange); the covariance surface uses a data-driven symmetric-about-0 range
# (a fixed (-1,1) would clip a covariance). supplied-K_g descriptive, rotation-invariant.
function _rr_surface(d::NamedTuple; title = "Random-regression genetic surface", kwargs...)
    t = Float64.(d.covariate)
    S = Matrix{Float64}(d.surface)
    if d.is_correlation
        crange = (-1.0, 1.0); cblabel = "genetic correlation"
    else
        M = maximum(abs, S); M = M == 0 ? 1.0 : M           # symmetric-about-0, no clip
        crange = (-M, M); cblabel = "genetic covariance"
    end
    fig = Figure()
    ax = Axis(fig[1, 1]; title = title,
              subtitle = "supplied-K_g descriptive; rotation-invariant; genetic, not phenotypic",
              xlabel = "covariate t", ylabel = "covariate t")
    hm = heatmap!(ax, t, t, S; colormap = :RdBu, colorrange = crange)
    Colorbar(fig[1, 2], hm; label = cblabel)
    return fig
end

# ── set A (RR): covariance-function eigenfunctions ───────────────────────────────
# One line per eigenfunction (column of `eigenfunctions`) vs covariate; the legend
# carries each axis's variance-explained share. Rotation-invariant; signs are arbitrary
# and the span is ambiguous under repeated eigenvalues — stated in the subtitle.
function _eigenfunctions(d::NamedTuple; title = "Random-regression eigenfunctions", kwargs...)
    t = Float64.(d.covariate)
    Φ = Matrix{Float64}(d.eigenfunctions)
    ve = Float64.(d.variance_explained)
    fig = Figure()
    ax = Axis(fig[1, 1]; title = title,
              subtitle = "rotation-invariant covariance-function eigenfunctions; supplied-K_g descriptive; signs arbitrary; span-ambiguous under repeated eigenvalues",
              xlabel = "covariate t", ylabel = "eigenfunction value")
    for j in 1:size(Φ, 2)
        lines!(ax, t, Φ[:, j]; label = "ψ_$(j) ($(round(100 * ve[j]; digits = 1))%)")
    end
    axislegend(ax)
    return fig
end

end # module
