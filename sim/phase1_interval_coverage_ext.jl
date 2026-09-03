#!/usr/bin/env julia
#
# C1-ext / design-36 H1 + H3 interval-coverage harness.
#
# NEW driver + NEW TSV. Do NOT edit sim/phase1_small_sample_interval_calibration.jl
# (an in-place method-label change invalidates C1 `--resume`; doc-34 §10 / §12).
#
# Name collision: design-36 H1/H3 = interval-calibration campaigns (this file).
# Julia backlog H1/H3 = non-Gaussian families. This driver is the design-36 meaning.
#
# What this is
#   Coverage driver for already-shipped *delta* intervals on covered-pillar
#   ratios and Fisher-z correlations. Scaffold / smoke / screening only until a
#   NEW predeclaration is evaluated on a confirm-tier array. No covered flip.
#   `public_covered_count` does not move. `point` is maintainer-owned.
#
# What this is not
#   Not a C1 re-run (job 47925485 already confirm-banked).
#   Not a rescue of repeatability `t` (2000-rep recovery was a banked NEGATIVE).
#   Not genomic / FA / single-step / NG interval work.
#   Not a 2000-rep campaign (Totoro 1-task smoke first; DRAC fir later, G0).
#
# Governing rule: hsquared/docs/design/34-interval-recovery-pre-registration.md
# Operational child: docs/dev-log/recovery-checkpoints/2026-09-03-c1-ext-h1-h3-ademp-predeclaration.md
#
# Include-safe: `include`-ing this file defines helpers and does not run `main`.

using HSquared
using LinearAlgebra
using Printf
using Random
using SparseArrays

# ---- Frozen claim-level contract (doc-34 §2–§4; do not relax) ----------------
const EXT_INTERPRETABLE_FRACTION = 0.9
const EXT_CONFIRM_REPS_TARGET = 2000
const EXT_SEED_STRIDE = 40_009          # coprime to C1 offsets; match future sbatch
const EXT_PROMOTABLE_LEVEL = 0.95
const EXT_CAMPAIGNS = (:h1_two, :h1_multi, :h1_t, :h3_rg, :h3_ram)
const EXT_MODES = (:smoke, :screen, :confirm)

const DETAIL_COLUMNS = [
    "campaign",
    "cell_id",
    "seed",
    "rep",
    "estimand",
    "method",
    "design",
    "n_animals",
    "n_obs",
    "truth",
    "level",
    "scope",
    "role",
    "fit_success",
    "fit_converged",
    "interval_success",
    "failure_reason",
    "covered",
    "lower",
    "upper",
    "width",
    "estimate",
    "se",
]

mutable struct ExtSummary
    reps::Int
    fit_success::Int
    interval_success::Int
    covered::Int
    width_sum::Float64
end
ExtSummary() = ExtSummary(0, 0, 0, 0, 0.0)

struct ExtConfig
    mode::Symbol
    reps::Int
    seed::Int
    campaigns::Vector{Symbol}
    levels::Vector{Float64}
    iterations::Int
    output::String
    detail_output::String
    resume::Bool
end

# ---- Symbolic alignment (design-36 §2.2; owed before either harness) ---------
# Per-estimand, no inheritance (doc-34 §4): c² does not inherit h²; r_g does not
# inherit G diagonals; Willham h²_T does not inherit r_am; t does not inherit σ²a.
const SYMBOLIC_ALIGNMENT = [
    # campaign  estimand     interval                          scale      covered_today              role
    (:h1_two,   "ratio1",    "two_effect_ratio_interval",      "logit-delta", "yes (two-effect opt-in)", "covered_pillar_bank"),
    (:h1_two,   "ratio2",    "two_effect_ratio_interval",      "logit-delta", "yes (two-effect opt-in)", "covered_pillar_bank"),
    (:h1_multi, "ratio1",    "multi_effect_ratio_interval",    "logit-delta", "yes (multi-effect opt-in)", "covered_pillar_bank"),
    (:h1_multi, "ratio2",    "multi_effect_ratio_interval",    "logit-delta", "yes (multi-effect opt-in)", "covered_pillar_bank"),
    (:h1_t,     "t",         "repeatability_interval",         "logit-delta", "NO (recovery confirm FAIL)", "characterization_only"),
    (:h3_rg,    "r_g",       "genetic_correlation_interval",   "Fisher-z",  "yes (t=2 MV covered)",   "covered_pillar_bank"),
    (:h3_ram,   "r_am",      "direct_maternal_interval",       "Fisher-z",  "yes (direct-maternal opt-in)", "covered_pillar_bank"),
]

function _usage()
    return """
    C1-ext H1/H3 interval coverage harness (doc-34 §10). NEW driver + NEW TSV.

    Modes:
      --mode=smoke    DEFAULT. Tiny interior cells, 1 rep. Path proof only.
      --mode=screen   Small designs; --reps default 48. Direction only; cannot set a claim.
      --mode=confirm  Frozen confirm grid. Still needs --reps/--seed. Does NOT flip covered.

    Options:
      --reps=N              Replicates per cell (smoke default 1; screen default 48).
      --seed=N              Master seed (default 20260903). Future arrays use stride $(EXT_SEED_STRIDE).
      --campaigns=LIST      Subset of h1_two,h1_multi,h1_t,h3_rg,h3_ram (default: all).
      --levels=LIST         Nominal levels (default 0.95). 0.90 is descriptive-only.
      --iterations=N        REML iteration cap (smoke default 80; else 200).
      --out=PATH            Summary TSV (NEW file; never a committed C1 TSV).
      --detail-out=PATH     Replicate TSV (default: OUT with -replicates.tsv).
      --resume=true|false   Reuse completed detail rows (default true).
      --smoke=true|false    Alias for --mode=smoke when true.

    Gates are PREDECLARED, not evaluated as a claim by this process:
      denominator = interval_success; interpretable iff interval_success ≥ 0.9·reps;
      0.95 ± 2·MC-SE band; over-cover → directional-conservative never point;
      per estimand, no inheritance; coverage=1.000 is a red flag.
      Repeatability t is characterization_only (do not rescue; do not promote).

    Pooling (doc-34 §12): coverage = Σ covered / Σ interval_success across tasks.
    Never average per-task coverage.

    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. \\
      sim/phase1_interval_coverage_ext.jl --mode=smoke
    """
end

function _parse_bool(value::AbstractString)
    lower = lowercase(value)
    lower in ("true", "yes", "1") && return true
    lower in ("false", "no", "0") && return false
    error("expected boolean value, got $(value)")
end

function _parse_float_list(value::AbstractString)
    vals = Float64[]
    for item in split(value, ",")
        stripped = strip(item)
        isempty(stripped) && continue
        push!(vals, parse(Float64, stripped))
    end
    isempty(vals) && error("empty numeric list")
    return vals
end

function _parse_campaigns(value::AbstractString)
    out = Symbol[]
    for item in split(value, ",")
        stripped = Symbol(strip(item))
        stripped in EXT_CAMPAIGNS || error("unknown campaign $(stripped); expected $(join(EXT_CAMPAIGNS, ","))")
        push!(out, stripped)
    end
    isempty(out) && error("empty campaign list")
    return unique(out)
end

function _default_detail_output(output::AbstractString)
    if endswith(output, ".tsv")
        return output[1:(lastindex(output) - 4)] * "-replicates.tsv"
    end
    return output * "-replicates.tsv"
end

function _parse_args(args)
    opts = Dict{String,String}()
    for arg in args
        arg in ("-h", "--help") && (print(_usage()); exit(0))
        startswith(arg, "--") || error("unexpected argument $(arg)")
        pieces = split(arg[3:end], "=", limit = 2)
        length(pieces) == 2 || error("expected --key=value, got $(arg)")
        opts[pieces[1]] = pieces[2]
    end

    smoke_alias = haskey(opts, "smoke") && _parse_bool(opts["smoke"])
    mode = Symbol(get(opts, "mode", smoke_alias ? "smoke" : "smoke"))
    mode in EXT_MODES || error("--mode must be smoke, screen, or confirm")
    campaigns = haskey(opts, "campaigns") ? _parse_campaigns(opts["campaigns"]) : collect(EXT_CAMPAIGNS)
    default_reps = mode === :smoke ? 1 : (mode === :screen ? 48 : 100)
    default_iters = mode === :smoke ? 80 : 200
    output = get(
        opts,
        "out",
        joinpath(@__DIR__, "..", "tmp", "c1ext-$(mode).tsv"),
    )
    return ExtConfig(
        mode,
        parse(Int, get(opts, "reps", string(default_reps))),
        parse(Int, get(opts, "seed", "20260903")),
        campaigns,
        _parse_float_list(get(opts, "levels", "0.95")),
        parse(Int, get(opts, "iterations", string(default_iters))),
        output,
        get(opts, "detail-out", _default_detail_output(output)),
        _parse_bool(get(opts, "resume", "true")),
    )
end

function _format_float(x::Float64)
    return @sprintf("%.8g", x)
end

function _format_value(x::Bool)
    return x ? "true" : "false"
end
function _format_value(x::Integer)
    return string(x)
end
function _format_value(x::AbstractFloat)
    return isnan(x) ? "NaN" : _format_float(Float64(x))
end
function _format_value(x)
    return string(x)
end

function _rep_seed(master::Int, campaign_index::Int, cell_index::Int, rep::Int)
    return master + 1_000_003 * campaign_index + 10_007 * cell_index + rep
end

function _halfsib_pedigree(nsire, ndam, noffspring)
    sire_ids = ["s$i" for i in 1:nsire]
    dam_ids = ["d$i" for i in 1:ndam]
    off_ids = ["o$i" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(
        fill("0", nsire + ndam),
        [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring],
    )
    dam = vcat(
        fill("0", nsire + ndam),
        [dam_ids[((i - 1) % ndam) + 1] for i in 1:noffspring],
    )
    return normalize_pedigree(ids, sire, dam)
end

function _chol_A(Ainv)
    A = Symmetric((Matrix(inv(Symmetric(Matrix(Ainv)))) +
                   Matrix(inv(Symmetric(Matrix(Ainv))))') ./ 2)
    return cholesky(A).L
end

function _group_incidence(rng, q, ngroup)
    group = [rand(rng, 1:ngroup) for _ in 1:q]
    Z = zeros(q, ngroup)
    for a in 1:q
        Z[a, group[a]] = 1.0
    end
    return Z, Matrix(1.0I, ngroup, ngroup)
end

# Tiny multi-generation maternal pedigree (path-proof). Confirm uses the n=960
# recovery design (ND=30, NS=6, NOFF=8, NGEN=4) — not this smoke layout.
function _maternal_pedigree(; nd, ns, noff, ngen)
    ids = String[]
    sirev = String[]
    damv = String[]
    dam_of = Dict{String,String}()
    function add!(id, s, d)
        push!(ids, id)
        push!(sirev, s)
        push!(damv, d)
        dam_of[id] = d
    end
    fsires = ["fs$i" for i in 1:ns]
    fdams = ["fd$i" for i in 1:nd]
    for s in fsires
        add!(s, "0", "0")
    end
    for d in fdams
        add!(d, "0", "0")
    end
    born = String[]
    counter = 0
    prev_dams = fdams
    prev_sires = fsires
    for g in 1:ngen
        thisF = String[]
        thisM = String[]
        for (j, dam) in enumerate(prev_dams)
            sire = prev_sires[((j - 1) % length(prev_sires)) + 1]
            for k in 1:noff
                counter += 1
                oid = "g$(g)_$(counter)"
                add!(oid, sire, dam)
                push!(born, oid)
                isodd(k) ? push!(thisF, oid) : push!(thisM, oid)
            end
        end
        length(thisF) >= nd || error("maternal gen $g: only $(length(thisF)) females")
        length(thisM) >= ns || error("maternal gen $g: only $(length(thisM)) males")
        prev_dams = thisF[1:nd]
        prev_sires = thisM[1:ns]
    end
    ped = normalize_pedigree(ids, sirev, damv)
    idset = Dict(id => i for (i, id) in enumerate(ped.ids))
    return (ped = ped, recorded = born, dam_of = dam_of, idset = idset)
end

function _safe_call(f)
    try
        return (true, f(), "")
    catch err
        return (false, nothing, sprint(showerror, err))
    end
end

function _interval_ok(lower, upper)
    return isfinite(lower) && isfinite(upper) && upper >= lower
end

function _detail_row(; campaign, cell_id, seed, rep, estimand, method, design,
                     n_animals, n_obs, truth, level, scope, role,
                     fit_success, fit_converged, interval_success, failure_reason,
                     covered, lower, upper, width, estimate, se)
    return (
        campaign = String(campaign),
        cell_id = cell_id,
        seed = seed,
        rep = rep,
        estimand = estimand,
        method = method,
        design = design,
        n_animals = n_animals,
        n_obs = n_obs,
        truth = truth,
        level = level,
        scope = scope,
        role = role,
        fit_success = fit_success,
        fit_converged = fit_converged,
        interval_success = interval_success,
        failure_reason = failure_reason,
        covered = covered,
        lower = lower,
        upper = upper,
        width = width,
        estimate = estimate,
        se = se,
    )
end

function _record_ci(campaign, cell_id, seed, rep, estimand, method, design,
                    n_animals, n_obs, truth, level, scope, role,
                    fit_ok, fit_converged, lower, upper, estimate, se, failure)
    ok = fit_ok && _interval_ok(lower, upper)
    covered = ok && lower <= truth <= upper
    return _detail_row(;
        campaign, cell_id, seed, rep, estimand, method, design,
        n_animals, n_obs, truth, level, scope, role,
        fit_success = fit_ok,
        fit_converged = fit_converged,
        interval_success = ok,
        failure_reason = ok ? "" : (isempty(failure) ? "interval_failed" : failure),
        covered = covered,
        lower = ok ? lower : NaN,
        upper = ok ? upper : NaN,
        width = ok ? upper - lower : NaN,
        estimate = estimate,
        se = se,
    )
end

# ---- campaign cells ----------------------------------------------------------
function _h1_two_cells(mode::Symbol)
    if mode === :smoke
        return [(label = "tiny", nsire = 3, ndam = 4, noffspring = 12, ngroup = 4,
                 s1 = 1.0, s2 = 0.5, se = 1.0, scope = "interior")]
    end
    cells = [(label = "small", nsire = 8, ndam = 16, noffspring = 96, ngroup = 16,
              s1 = 1.0, s2 = 0.5, se = 1.0, scope = "interior")]
    if mode === :confirm
        push!(cells, (label = "small", nsire = 8, ndam = 16, noffspring = 96, ngroup = 16,
                      s1 = 1.0, s2 = 0.05, se = 1.0, scope = "boundary"))
    end
    return cells
end

function _h1_multi_cells(mode::Symbol)
    if mode === :smoke
        return [(label = "tiny", nsire = 3, ndam = 4, noffspring = 12, ng1 = 4, ng2 = 0,
                 sa = 1.0, sg1 = 0.5, sg2 = 0.0, se = 1.0, k = 2, scope = "interior")]
    end
    return [(label = "small", nsire = 8, ndam = 16, noffspring = 96, ng1 = 12, ng2 = 10,
             sa = 1.0, sg1 = 0.5, sg2 = 0.5, se = 1.0, k = 3, scope = "interior")]
end

function _h1_t_cells(mode::Symbol)
    rec = mode === :smoke ? 2 : 4
    nsire = mode === :smoke ? 3 : 8
    ndam = mode === :smoke ? 4 : 16
    noff = mode === :smoke ? 12 : 96
    return [(label = mode === :smoke ? "tiny" : "small",
             nsire = nsire, ndam = ndam, noffspring = noff, records = rec,
             sa = 1.0, spe = 0.6, se = 1.5, scope = "characterization_not_covered")]
end

function _h3_rg_cells(mode::Symbol)
    if mode === :smoke
        return [(label = "tiny", nsire = 3, ndam = 4, noffspring = 12, records = 2,
                 g11 = 1.0, g12 = 0.35, g22 = 0.7, r11 = 0.8, r12 = 0.2, r22 = 0.55,
                 scope = "interior")]
    end
    cells = [(label = "small", nsire = 8, ndam = 16, noffspring = 96, records = 2,
              g11 = 1.0, g12 = 0.35, g22 = 0.7, r11 = 0.8, r12 = 0.2, r22 = 0.55,
              scope = "interior")]
    if mode === :confirm
        # |r|→0.9 is characterization; SE-path throws → NON-INTERPRETABLE, not a whisker.
        push!(cells, (label = "small", nsire = 8, ndam = 16, noffspring = 96, records = 2,
                      g11 = 1.0, g12 = 0.9, g22 = 1.0, r11 = 0.8, r12 = 0.2, r22 = 0.55,
                      scope = "boundary"))
    end
    return cells
end

function _h3_ram_cells(mode::Symbol)
    if mode === :smoke
        return [(label = "tiny_maternal", nd = 3, ns = 2, noff = 4, ngen = 2,
                 sad = 1.0, sam = 0.5, ram = -0.3, se = 1.0, scope = "interior")]
    end
    # Confirm design matches the covered recovery gate (n=960). Smoke must not use it.
    return [(label = "confirm_maternal", nd = 30, ns = 6, noff = 8, ngen = 4,
             sad = 1.0, sam = 0.5, ram = -0.3, se = 1.0, scope = "interior")]
end

# ---- one-rep runners ---------------------------------------------------------
function _run_h1_two(cell, seed, level, iterations)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(cell.nsire, cell.ndam, cell.noffspring)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    LA = _chol_A(Ainv)
    u1 = (LA * randn(rng, q)) .* sqrt(cell.s1)
    Z2, Ainv2 = _group_incidence(rng, q, cell.ngroup)
    u2 = randn(rng, cell.ngroup) .* sqrt(cell.s2)
    y = 2.0 .+ u1 .+ Z2 * u2 .+ randn(rng, q) .* sqrt(cell.se)
    X = ones(q, 1)
    Z1 = Matrix(1.0I, q, q)
    total = cell.s1 + cell.s2 + cell.se
    truth1 = cell.s1 / total
    truth2 = cell.s2 / total
    ok, ci, err = _safe_call() do
        two_effect_ratio_interval(y, X, Z1, Ainv, Z2, Ainv2;
                                  level = level, iterations = iterations)
    end
    rows = []
    if !ok || ci === nothing
        for (name, truth) in (("ratio1", truth1), ("ratio2", truth2))
            push!(rows, _record_ci(:h1_two, "", seed, 0, name, "ratio_delta_z",
                                   cell.label, q, q, truth, level, cell.scope,
                                   "covered_pillar_bank", false, false,
                                   NaN, NaN, NaN, NaN, err))
        end
        return rows
    end
    for (name, piece, truth) in (("ratio1", ci.ratio1, truth1), ("ratio2", ci.ratio2, truth2))
        push!(rows, _record_ci(:h1_two, "", seed, 0, name, "ratio_delta_z",
                               cell.label, q, q, truth, level, cell.scope,
                               "covered_pillar_bank", true, ci.converged,
                               piece.lower, piece.upper, piece.estimate, piece.se, ""))
    end
    return rows
end

function _run_h1_multi(cell, seed, level, iterations)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(cell.nsire, cell.ndam, cell.noffspring)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    LA = _chol_A(Ainv)
    ua = (LA * randn(rng, q)) .* sqrt(cell.sa)
    X = ones(q, 1)
    Z1 = Matrix(1.0I, q, q)
    Zg1, I1 = _group_incidence(rng, q, cell.ng1)
    ug1 = randn(rng, cell.ng1) .* sqrt(cell.sg1)
    y = 2.0 .+ ua .+ Zg1 * ug1
    effects = Any[(Z1, Ainv), (Zg1, I1)]
    truths = Float64[cell.sa, cell.sg1]
    sigmas = [cell.sa, cell.sg1]
    if cell.k == 3
        Zg2, I2 = _group_incidence(rng, q, cell.ng2)
        ug2 = randn(rng, cell.ng2) .* sqrt(cell.sg2)
        y = y .+ Zg2 * ug2
        push!(effects, (Zg2, I2))
        push!(truths, cell.sg2)
        push!(sigmas, cell.sg2)
    end
    y = y .+ randn(rng, q) .* sqrt(cell.se)
    total = sum(sigmas) + cell.se
    truths ./= total
    ok, ci, err = _safe_call() do
        multi_effect_ratio_interval(y, X, effects; level = level, iterations = iterations)
    end
    rows = []
    names = cell.k == 3 ? ("ratio1", "ratio2", "ratio3") : ("ratio1", "ratio2")
    if !ok || ci === nothing
        for (i, name) in enumerate(names)
            push!(rows, _record_ci(:h1_multi, "", seed, 0, name, "ratio_delta_z",
                                   cell.label, q, q, truths[i], level, cell.scope,
                                   "covered_pillar_bank", false, false,
                                   NaN, NaN, NaN, NaN, err))
        end
        return rows
    end
    for (i, name) in enumerate(names)
        piece = ci.ratios[i]
        push!(rows, _record_ci(:h1_multi, "", seed, 0, name, "ratio_delta_z",
                               cell.label, q, q, truths[i], level, cell.scope,
                               "covered_pillar_bank", true, ci.converged,
                               piece.lower, piece.upper, piece.estimate, piece.se, ""))
    end
    return rows
end

function _run_h1_t(cell, seed, level, iterations)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(cell.nsire, cell.ndam, cell.noffspring)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    LA = _chol_A(Ainv)
    ua = (LA * randn(rng, q)) .* sqrt(cell.sa)
    pe = randn(rng, q) .* sqrt(cell.spe)
    n = q * cell.records
    X = ones(n, 1)
    Z = zeros(n, q)
    y = Vector{Float64}(undef, n)
    row = 1
    for animal in 1:q, _ in 1:cell.records
        Z[row, animal] = 1.0
        y[row] = 2.0 + ua[animal] + pe[animal] + randn(rng) * sqrt(cell.se)
        row += 1
    end
    t_true = (cell.sa + cell.spe) / (cell.sa + cell.spe + cell.se)
    ok, ci, err = _safe_call() do
        repeatability_interval(y, X, Z, Ainv; level = level, iterations = iterations)
    end
    if !ok || ci === nothing
        return [_record_ci(:h1_t, "", seed, 0, "t", "t_delta_z",
                           cell.label, q, n, t_true, level, cell.scope,
                           "characterization_only", false, false,
                           NaN, NaN, NaN, NaN, err)]
    end
    return [_record_ci(:h1_t, "", seed, 0, "t", "t_delta_z",
                       cell.label, q, n, t_true, level, cell.scope,
                       "characterization_only", true, true,
                       ci.lower, ci.upper, ci.repeatability, ci.se, "")]
end

function _run_h3_rg(cell, seed, level, iterations)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(cell.nsire, cell.ndam, cell.noffspring)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    Gtrue = [cell.g11 cell.g12; cell.g12 cell.g22]
    Rtrue = [cell.r11 cell.r12; cell.r12 cell.r22]
    LA = _chol_A(Ainv)
    LG = cholesky(Symmetric(Gtrue)).L
    LR = cholesky(Symmetric(Rtrue)).L
    U = LA * randn(rng, q, 2) * transpose(LG)
    n = q * cell.records
    X = ones(n, 1)
    Z = zeros(n, q)
    Y = zeros(n, 2)
    row = 1
    for animal in 1:q, _ in 1:cell.records
        Z[row, animal] = 1.0
        Y[row, :] .= 2.0 .+ U[animal, :] .+ (randn(rng, 1, 2) * transpose(LR))[1, :]
        row += 1
    end
    r_true = cell.g12 / sqrt(cell.g11 * cell.g22)
    ok, ci, err = _safe_call() do
        fit = fit_multivariate_reml(Y, X, Z, Ainv;
                                    initial = (G0 = Gtrue, R0 = Rtrue),
                                    iterations = iterations)
        genetic_correlation_interval(fit, Y, X, Z, Ainv; level = level, method = :delta)
    end
    if !ok || ci === nothing
        return [_record_ci(:h3_rg, "", seed, 0, "r_g", "rg_fisher_z",
                           cell.label, q, n, r_true, level, cell.scope,
                           "covered_pillar_bank", false, false,
                           NaN, NaN, NaN, NaN, err)]
    end
    return [_record_ci(:h3_rg, "", seed, 0, "r_g", "rg_fisher_z",
                       cell.label, q, n, r_true, level, cell.scope,
                       "covered_pillar_bank", true, ci.converged,
                       ci.lower[1], ci.upper[1], ci.estimate[1], NaN, "")]
end

function _run_h3_ram(cell, seed, level, iterations)
    raw = _maternal_pedigree(; nd = cell.nd, ns = cell.ns, noff = cell.noff, ngen = cell.ngen)
    ped = raw.ped
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    A = Symmetric(Matrix(inv(Symmetric(Matrix(Ainv)))))
    LA = cholesky(A).L
    sdm = cell.ram * sqrt(cell.sad * cell.sam)
    G = [cell.sad sdm; sdm cell.sam]
    rng = MersenneTwister(seed)
    acoef = LA * randn(rng, q, 2) * transpose(cholesky(Symmetric(G)).L)
    n = length(raw.recorded)
    Zd = zeros(n, q)
    Zm = zeros(n, q)
    y = Vector{Float64}(undef, n)
    for (i, id) in enumerate(raw.recorded)
        ai = raw.idset[id]
        di = raw.idset[raw.dam_of[id]]
        Zd[i, ai] = 1.0
        Zm[i, di] = 1.0
        y[i] = 2.0 + acoef[ai, 1] + acoef[di, 2] + randn(rng) * sqrt(cell.se)
    end
    X = ones(n, 1)
    ok, ci, err = _safe_call() do
        direct_maternal_interval(y, X, Zd, Zm, Ainv; level = level, iterations = iterations)
    end
    if !ok || ci === nothing
        return [_record_ci(:h3_ram, "", seed, 0, "r_am", "ram_fisher_z",
                           cell.label, q, n, cell.ram, level, cell.scope,
                           "covered_pillar_bank", false, false,
                           NaN, NaN, NaN, NaN, err)]
    end
    r = ci.genetic_correlation
    return [_record_ci(:h3_ram, "", seed, 0, "r_am", "ram_fisher_z",
                       cell.label, q, n, cell.ram, level, cell.scope,
                       "covered_pillar_bank", true, true,
                       r.lower, r.upper, r.estimate, r.se, "")]
end

# ---- I/O ---------------------------------------------------------------------
function _detail_key(row)
    return (row.campaign, row.cell_id, row.estimand, row.method, row.level, row.rep, row.seed)
end

function _parse_detail_bool(s)
    return lowercase(strip(s)) in ("true", "1", "yes")
end

function _parse_detail_record(parts)
    length(parts) == length(DETAIL_COLUMNS) || error("detail row has $(length(parts)) fields")
    return (
        campaign = String(parts[1]),
        cell_id = String(parts[2]),
        seed = parse(Int, parts[3]),
        rep = parse(Int, parts[4]),
        estimand = String(parts[5]),
        method = String(parts[6]),
        design = String(parts[7]),
        n_animals = parse(Int, parts[8]),
        n_obs = parse(Int, parts[9]),
        truth = parse(Float64, parts[10]),
        level = parse(Float64, parts[11]),
        scope = String(parts[12]),
        role = String(parts[13]),
        fit_success = _parse_detail_bool(parts[14]),
        fit_converged = _parse_detail_bool(parts[15]),
        interval_success = _parse_detail_bool(parts[16]),
        failure_reason = String(parts[17]),
        covered = _parse_detail_bool(parts[18]),
        lower = parse(Float64, parts[19]),
        upper = parse(Float64, parts[20]),
        width = parse(Float64, parts[21]),
        estimate = parse(Float64, parts[22]),
        se = parse(Float64, parts[23]),
    )
end

function _read_detail_records(path::AbstractString)
    records = Dict{Any,Any}()
    isfile(path) || return records
    open(path, "r") do io
        header = readline(io)
        header == join(DETAIL_COLUMNS, '\t') ||
            error("detail header does not match C1-ext schema: $(path)")
        for line in eachline(io)
            isempty(strip(line)) && continue
            row = _parse_detail_record(split(line, '\t'; keepempty = true))
            records[_detail_key(row)] = row
        end
    end
    return records
end

function _prepare_detail_output(path::AbstractString; resume::Bool)
    mkpath(dirname(path))
    if !resume || !isfile(path) || filesize(path) == 0
        open(path, "w") do io
            println(io, join(DETAIL_COLUMNS, '\t'))
        end
    end
    return path
end

function _write_detail_rows!(path::AbstractString, rows)
    isempty(rows) && return path
    open(path, "a") do io
        for row in rows
            println(io, join([_format_value(getproperty(row, Symbol(col))) for col in DETAIL_COLUMNS], '\t'))
        end
        flush(io)
    end
    return path
end

function _summaries_from_records(records)
    summaries = Dict{Any,ExtSummary}()
    for row in values(records)
        key = (row.campaign, row.estimand, row.method, row.design, row.truth, row.level, row.scope, row.role)
        s = get!(summaries, key, ExtSummary())
        s.reps += 1
        s.fit_success += row.fit_success ? 1 : 0
        s.interval_success += row.interval_success ? 1 : 0
        s.covered += row.covered ? 1 : 0
        if row.interval_success && isfinite(row.width)
            s.width_sum += row.width
        end
    end
    return summaries
end

function _write_summary(path::AbstractString, summaries)
    mkpath(dirname(path))
    rows = sort(collect(summaries); by = pair -> string(pair[1]))
    open(path, "w") do io
        println(io, join([
            "campaign", "estimand", "method", "design", "truth", "level", "scope", "role",
            "reps", "fit_success", "interval_success", "covered",
            "coverage", "mcse_observed", "mcse_nominal", "mean_width",
            "non_interpretable", "claim_eligible",
        ], '\t'))
        for ((campaign, estimand, method, design, truth, level, scope, role), s) in rows
            n = s.interval_success
            coverage = n > 0 ? s.covered / n : NaN
            mcse_obs = n > 0 ? sqrt(max(coverage * (1 - coverage), 0) / n) : NaN
            mcse_nom = n > 0 ? sqrt(level * (1 - level) / n) : NaN
            mean_w = n > 0 ? s.width_sum / n : NaN
            non_int = s.interval_success < EXT_INTERPRETABLE_FRACTION * s.reps
            # Screening/smoke can never set a claim. Confirm still needs Fisher + Rose + G10.
            claim_eligible = false
            println(io, join([
                campaign, estimand, method, design, _format_float(truth), _format_float(level),
                scope, role, string(s.reps), string(s.fit_success), string(s.interval_success),
                string(s.covered), _format_value(coverage), _format_value(mcse_obs),
                _format_value(mcse_nom), _format_value(mean_w),
                non_int ? "true" : "false",
                claim_eligible ? "true" : "false",
            ], '\t'))
        end
    end
    return path
end

function _print_symbolic_table()
    println("SYMBOLIC_ALIGNMENT (design-36 §2.2; doc-34 §4 no-inheritance)")
    println("campaign\testimand\tinterval\tscale\tcovered_today\trole")
    for row in SYMBOLIC_ALIGNMENT
        println(join(row, '\t'))
    end
    println("NOTE h1_t recovery confirm is a banked NEGATIVE — characterization only; do not rescue.")
    return nothing
end

function _stamp_cell!(row, cell_id, rep)
    return merge(row, (cell_id = cell_id, rep = rep))
end

function _run_campaign!(records, config, campaign, campaign_index)
    cells = if campaign === :h1_two
        _h1_two_cells(config.mode)
    elseif campaign === :h1_multi
        _h1_multi_cells(config.mode)
    elseif campaign === :h1_t
        _h1_t_cells(config.mode)
    elseif campaign === :h3_rg
        _h3_rg_cells(config.mode)
    elseif campaign === :h3_ram
        _h3_ram_cells(config.mode)
    else
        error("unknown campaign $campaign")
    end
    runner = Dict(
        :h1_two => _run_h1_two,
        :h1_multi => _run_h1_multi,
        :h1_t => _run_h1_t,
        :h3_rg => _run_h3_rg,
        :h3_ram => _run_h3_ram,
    )[campaign]
    new_rows = Any[]
    for (cell_index, cell) in pairs(cells)
        for level in config.levels
            for rep in 1:config.reps
                seed = _rep_seed(config.seed, campaign_index, cell_index, rep)
                cell_id = string(campaign, "|", cell.label, "|scope=", cell.scope, "|level=", _format_float(level))
                probe = _detail_row(;
                    campaign = campaign, cell_id = cell_id, seed = seed, rep = rep,
                    estimand = "_probe", method = "_probe", design = cell.label,
                    n_animals = 0, n_obs = 0, truth = 0.0, level = level,
                    scope = cell.scope, role = "n/a",
                    fit_success = false, fit_converged = false,
                    interval_success = false, failure_reason = "",
                    covered = false, lower = NaN, upper = NaN, width = NaN,
                    estimate = NaN, se = NaN,
                )
                # Resume key is per (campaign, cell, estimand, method, level, rep, seed).
                # Skip the whole rep when any real estimand row already exists.
                already = any(r -> r.campaign == String(campaign) && r.cell_id == cell_id &&
                                  r.rep == rep && r.seed == seed && r.estimand != "_probe",
                              values(records))
                already && continue
                produced = runner(cell, seed, level, config.iterations)
                for row in produced
                    stamped = _stamp_cell!(row, cell_id, rep)
                    records[_detail_key(stamped)] = stamped
                    push!(new_rows, stamped)
                end
                _ = probe
            end
        end
    end
    return new_rows
end

function main(args = ARGS)
    config = _parse_args(args)
    config.reps > 0 || error("--reps must be positive")
    config.iterations > 0 || error("--iterations must be positive")
    all(0 .< config.levels .< 1) || error("--levels must be in (0, 1)")
    config.mode === :confirm && config.reps >= EXT_SEED_STRIDE &&
        error("--reps must be < seed stride $(EXT_SEED_STRIDE)")

    println("C1EXT mode=", config.mode, " reps=", config.reps, " seed=", config.seed)
    println("campaigns=", join(config.campaigns, ","), " levels=", join(config.levels, ","))
    println("CLAIM_ELIGIBLE=false  (scaffold/smoke/screen never assigns a claim level)")
    println("COVERED_FLIP=false  public_covered_count unchanged")
    _print_symbolic_table()

    records = config.resume ? _read_detail_records(config.detail_output) : Dict{Any,Any}()
    _prepare_detail_output(config.detail_output; resume = config.resume)
    for (i, campaign) in enumerate(config.campaigns)
        rows = _run_campaign!(records, config, campaign, i)
        _write_detail_rows!(config.detail_output, rows)
    end
    summaries = _summaries_from_records(records)
    path = _write_summary(config.output, summaries)
    println("wrote ", path)
    println("detail_out=", config.detail_output)

    total_int = sum(s.interval_success for s in values(summaries); init = 0)
    total_rep = sum(s.reps for s in values(summaries); init = 0)
    println("diag\treps=", total_rep, "\tinterval_success=", total_int,
            "\tcampaigns=", length(config.campaigns))
    # Failure-sensitive smoke probe: H1 two-effect interior ratio1 if present.
    probe = nothing
    for ((campaign, estimand, method, _, _, level, scope, _), s) in summaries
        if campaign == "h1_two" && estimand == "ratio1" && method == "ratio_delta_z" &&
           level == EXT_PROMOTABLE_LEVEL && scope == "interior"
            probe = s
            break
        end
    end
    if probe === nothing
        println("probe\tMISSING")
    else
        cov = probe.interval_success > 0 ? probe.covered / probe.interval_success : NaN
        println("probe\th1_two/ratio1/ratio_delta_z\tinterval_success=", probe.interval_success,
                "\tcoverage=", _format_value(cov))
    end
    println("GATE\tPATH_ONLY\tmode=", config.mode,
            "\tnote=not_a_claim; confirm_tier_not_run; t_not_promotable")
    return path
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
