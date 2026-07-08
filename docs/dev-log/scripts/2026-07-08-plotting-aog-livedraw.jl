# Live-draw verification driver for the AlgebraOfGraphics plotting layer.
#
# WHY THIS EXISTS. `test/runtests.jl` asserts `isempty(methods(hsquared_figure))` with
# Makie/AoG deliberately kept OUT of the DEFAULT test environment (cost discipline). That
# assertion passes PRECISELY WHEN THE EXTENSION FAILS TO LOAD, so a green `Pkg.test()` is
# zero evidence about the drawing layer. This script is the only thing that verifies it —
# run either by hand, or as the opt-in `plotting` CI job (dispatch CI with
# `run_plotting = true`), which runs this same file. The DEFAULT CI will never tell you.
# Re-run it on any Makie / AlgebraOfGraphics / CairoMakie version bump.
#
# Evidence banked from this driver: docs/dev-log/check-log.d/2026-07-08-plotting-aog.md
#
# USAGE (julia is NOT on PATH in a Claude Code shell; it lives at ~/.juliaup/bin):
#
#     export PATH="$HOME/.juliaup/bin:$PATH"
#     mkdir -p /tmp/aog-livedraw && cd /tmp/aog-livedraw
#     julia --project=. -e 'import Pkg
#         Pkg.develop(path="/path/to/HSquared.jl")
#         Pkg.add(["CairoMakie", "AlgebraOfGraphics"])'
#     julia --project=. /path/to/HSquared.jl/docs/dev-log/scripts/2026-07-08-plotting-aog-livedraw.jl
#
# Exits non-zero on any failed assertion. Writes forest.png / caterpillar.png to the cwd
# BEFORE asserting, so the figures exist even on a failing run — RENDER THEM AND LOOK AT THEM.
# Of the five defect classes this driver was written for, two (the clipped/linked-scale
# cluster, and the flag anchored at the uncrossed end) were found only by looking at the PNG.
# The second of those PASSED an object assertion below: it counted the annotation and never
# asked where it was. Counting is not checking.

using CairoMakie, AlgebraOfGraphics, HSquared
const M = CairoMakie.Makie

import Pkg
Pkg.status(["AlgebraOfGraphics", "Makie", "CairoMakie"])
@info "julia" VERSION

# ── payloads: one per figure kind ────────────────────────────────────────────────
# The forest payload is deliberately adversarial: a NaN whisker (sigma_e2, must draw
# nothing) and an h² whose interval crosses 0 (must be flagged, on the h² panel ONLY).
vc = (term = ["sigma_a2", "sigma_e2", "h2"], estimate = [20.0, 40.0, 0.333],
      lo = [5.0, NaN, -0.05], hi = [35.0, NaN, 0.72],
      panel = ["variance components", "variance components", "heritability"],
      supplied = false, interval_status = "delta")
# CONTROL: h² strictly inside [0,1] — must draw NO annotation. Without this, an
# always-on annotation would pass every assertion made about `vc`.
vc_ctl = (term = ["sigma_a2", "h2"], estimate = [20.0, 0.4], lo = [5.0, 0.2], hi = [35.0, 0.6],
          panel = ["variance components", "heritability"], supplied = false,
          interval_status = "delta")
# The flag must sit at the END that is crossed. `vc` above crosses only `lo`; these cover
# the other two cases. Counting annotations is not enough — a flag anchored at the wrong
# end points the reader at the one boundary the interval respects.
vc_hi = (term = ["h2"], estimate = [0.9], lo = [0.6], hi = [1.05],
         panel = ["heritability"], supplied = false, interval_status = "delta")
vc_both = (term = ["h2"], estimate = [0.5], lo = [-0.1], hi = [1.1],
           panel = ["heritability"], supplied = false, interval_status = "delta")
bv = (value = [0.5, -0.2, 1.3, 0.0], pev = [0.1, 0.2, 0.05, 0.3], pev_scale = "validation")
gg = (is_eigenstructure_not_loadings = true, eigenvalues = [2.0, 1.0],
      variance_explained = [0.667, 0.333], axis_labels = ["PC1", "PC2"])
gc = (traits = ["a", "b"], genetic_correlations = [1.0 0.5; 0.5 1.0],
      heritabilities = [0.3, 0.4], rotation_invariant = true)
mh = (marker_ids = ["m1", "m2", "m3"], chromosomes = ["1", "1", "2"], positions = [1.0, 2.0, 1.0],
      plot_positions = [1.0, 2.0, 3.0], p_values = [0.5, 0.001, 0.2],
      neglog10_p_values = [0.3, 3.0, 0.7])
qq = (expected_neglog10_p_values = [0.1, 0.5, 1.0], observed_neglog10_p_values = [0.2, 0.6, 1.4])
rv = (covariate = [0.0, 1.0, 2.0], genetic_variance = [1.0, 1.2, 1.5], heritability = nothing,
      supplied = true)
rs = (covariate = [0.0, 1.0], surface = [1.0 0.5; 0.5 1.0], is_correlation = true, supplied = true)
re = (covariate = [0.0, 1.0], eigenvalues = [2.0, 0.5], eigenfunctions = [1.0 0.2; 0.3 0.9],
      variance_explained = [0.8, 0.2], rotation_invariant = true, supplied = true)

const KINDS = [:variance_components => vc, :breeding_values => bv, :g_geometry => gg,
               :genetic_correlation => gc, :manhattan => mh, :qq => qq,
               :rr_variance => rv, :rr_surface => rs, :rr_eigenfunctions => re]

axes_of(fig) = [a for a in fig.content if a isa M.Axis]
nplots(ax, T) = count(p -> p isa T, ax.scene.plots)

function nine_kinds()
    ok = 0
    for (k, p) in KINDS
        explicit = hsquared_figure(p; kind = k) isa M.Figure
        inferred = hsquared_figure(p) isa M.Figure          # `kind` inferred from fields
        @assert explicit "kind=$k did not draw a Makie.Figure (explicit)"
        @assert inferred "kind=$k did not draw a Makie.Figure (inferred)"
        ok += 1
    end
    @info "nine-kind draw" result = "$ok/9 (explicit + inferred)"
    @assert ok == 9
end

function forest_invariants()
    fig = hsquared_figure(vc; kind = :variance_components)
    axs = axes_of(fig)
    @assert length(axs) == 2 "expected 2 facet axes, got $(length(axs))"

    # Facet ORDER: sort(unique(panels)) => "heritability" first. A re-ordering would
    # silently swap the panels' ticks and annotations; the shape guard cannot see it.
    t1, l1 = axs[1].yticks[]
    t2, l2 = axs[2].yticks[]
    @assert collect(l1) == ["h2"] "axis[1] should be the h² facet, got $(collect(l1))"
    @assert collect(l2) == ["sigma_e2", "sigma_a2"] "axis[2] ticks wrong: $(collect(l2))"
    @assert collect(t1) == [1.0] && collect(t2) == [2.0, 3.0]

    for (i, ax) in enumerate(axs)
        # ONE marker layer: AoG's `visual(Scatter, …)`. A manual re-scatter reads 2.
        @assert nplots(ax, M.Scatter) == 1 "axis[$i] double-draws markers"
        # NaN whisker on sigma_e2 must draw NOTHING (raw, never fabricated).
        @assert nplots(ax, M.Lines) == 1 "axis[$i] whisker count wrong"
        # Title/subtitle are FIGURE-level; `axis=(…)` would stamp them on every facet.
        @assert String(ax.title[]) == "" "axis[$i] has a per-facet title"
        @assert String(ax.ylabel[]) == "" "axis[$i] leaks the mapped variable as ylabel"
        # Whiskers and the zero line sit BEHIND the markers.
        for p in ax.scene.plots
            (p isa M.Lines || p isa M.LineSegments) || continue
            @assert p.transformation.translation[][3] == -1.0 "axis[$i] layer not behind markers"
        end
    end

    # The [0,1] boundary flag is h²-panel ONLY. A variance whisker crossing 0 is expected
    # and honest — flagging it would be the bug.
    @assert nplots(axs[1], M.Text) == 1 "h² panel missing the [0,1] boundary flag"
    @assert nplots(axs[2], M.Text) == 0 "variance panel must NOT be flagged"

    # CONTROL: h² strictly inside [0,1] draws no annotation at all.
    ctl = axes_of(hsquared_figure(vc_ctl; kind = :variance_components))
    @assert sum(ax -> nplots(ax, M.Text), ctl) == 0 "annotation fired on the control payload"

    # PLACEMENT: the flag must sit at the crossed END, not merely exist. Counting Text
    # plots cannot see a flag anchored at `hi` for a `lo <= 0` crossing — it renders on
    # the side the interval respects, with the headroom bump on the wrong side too.
    # (x, y, halign). The ROW matters too: a flag at the right x on the wrong row still
    # mislabels which term crosses the boundary, and counting Text plots cannot see that.
    flags(ax) = [(p[1][][1][1], p[1][][1][2], p.align[][1]) for p in ax.scene.plots if p isa M.Text]

    lo_only = flags(axs[1])                                   # vc: lo = -0.05, hi = 0.72
    @assert length(lo_only) == 1
    @assert lo_only[1][1] ≈ -0.05 "lo-crossing flag anchored at $(lo_only[1][1]), not lo"
    @assert lo_only[1][2] ≈ 1.0 "lo-crossing flag on row $(lo_only[1][2]), not the h² row"
    @assert lo_only[1][3] === :right "lo-crossing flag must be right-aligned"
    @assert axs[1].finallimits[].origin[1] < -0.05 "no left headroom: the lo flag clips"

    hi_ax = only(axes_of(hsquared_figure(vc_hi; kind = :variance_components)))
    hi_only = flags(hi_ax)                                    # vc_hi: lo = 0.6, hi = 1.05
    @assert length(hi_only) == 1
    @assert hi_only[1][1] ≈ 1.05 "hi-crossing flag anchored at $(hi_only[1][1]), not hi"
    @assert hi_only[1][2] ≈ 1.0 "hi-crossing flag on row $(hi_only[1][2]), not the h² row"
    @assert hi_only[1][3] === :left "hi-crossing flag must be left-aligned"
    lim = hi_ax.finallimits[]
    @assert lim.origin[1] + lim.widths[1] > 1.05 "no right headroom: the hi flag clips"

    both_ax = only(axes_of(hsquared_figure(vc_both; kind = :variance_components)))
    both = sort(flags(both_ax); by = first)                   # vc_both: crosses BOTH ends
    @assert length(both) == 2 "an interval crossing both ends must be flagged twice"
    @assert both[1][1] ≈ -0.1 && both[1][3] === :right "both-ends: lo flag wrong"
    @assert both[2][1] ≈ 1.1 && both[2][3] === :left "both-ends: hi flag wrong"
    @assert both[1][2] ≈ 1.0 && both[2][2] ≈ 1.0 "both-ends: flags not on the h² row"
    bl = both_ax.finallimits[]
    @assert bl.origin[1] < -0.1 && bl.origin[1] + bl.widths[1] > 1.1 "both-ends: headroom missing"

    @info "forest invariants" facet_order = "ok" single_marker_layer = "ok" nan_whisker = "ok" z_order = "ok" boundary_h2_only = "ok" control = "ok" flag_placement = "ok (lo / hi / both)"
end

function caterpillar_invariants()
    fig = hsquared_figure(bv; kind = :breeding_values)
    ax = only(axes_of(fig))
    @assert nplots(ax, M.Scatter) == 1 "caterpillar double-draws markers"
    @assert nplots(ax, M.Lines) == length(bv.value) "one whisker per animal expected"
    for p in ax.scene.plots
        (p isa M.Lines || p isa M.LineSegments) || continue
        @assert p.transformation.translation[][3] == -1.0 "caterpillar layer not behind markers"
    end
    @info "caterpillar invariants" single_marker_layer = "ok" whiskers = "ok" z_order = "ok"
end

function rasterize()
    save("forest.png", hsquared_figure(vc; kind = :variance_components))
    save("caterpillar.png", hsquared_figure(bv; kind = :breeding_values))
    @info "rasterized" forest = filesize("forest.png") caterpillar = filesize("caterpillar.png")
end

# `rasterize()` runs BEFORE the invariants, not after. The figures are the evidence a human
# reads on a FAILING run — two of the five defect classes were caught by looking at them and
# by nothing else. Assert-then-rasterize exits on the first bad assertion with no PNG written,
# so the CI job's `if: always()` artifact upload would have nothing to upload precisely when
# it matters. Draw first, then assert.
nine_kinds()
rasterize()
forest_invariants()
caterpillar_invariants()
@warn "Object assertions are NOT visual verification. OPEN forest.png AND caterpillar.png."
@info "ALL LIVE-DRAW CHECKS PASSED"
