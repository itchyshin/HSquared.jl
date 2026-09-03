# v0.8 S2 — FA recovery-gate prereg (FROZEN · NOT RUN as a campaign)
# OPT-IN, OUT of CI. Does NOT flip V4-FA. Does NOT launch S3/S4.
#
# Locked by docs/dev-log/decisions/2026-09-03-v08-s2-fa-recovery-gate-prereg.md
# Cite the git commit that introduced this file + that decision.
#
# Why this DGP exists: S1 (t=3 K=1, ledermann_slack=0) classified 8/10
# ok_recovery on the OLD G/R-only gates, but heywood_flag was true on 7/10
# including 5 of those 8 "passes". Those old gates accept collapsed
# uniqueness. Design-42 start-sensitivity is REFUTED (0 optimizer_miss).
#
# S2 therefore freezes:
#   1. Gate DGP with ledermann_slack > 0: t=4 K=1
#      slack = (t-K)^2 - (t+K) = 9 - 5 = 4
#      (t=5 K=2 also has slack>0 but changes rank; rejected for this gate)
#   2. A seed PASSES only if ALL hold:
#        converged AND rel_g ≤ 0.45 AND rel_r ≤ 0.25 AND min(ψ̂) ≥ 1e-4
#        AND the cell's ledermann_slack > 0
#   Saturated t=3 K=1 remains a Heywood diagnostic cell, never the
#   covered-flip gate.
#
# Cells:
#   --cell=d4-k1            GATE DGP (default). t=4 K=1, slack=4
#   --cell=d3-diagnostic    S1 DGP. t=3 K=1, slack=0. NOT a gate pass cell
#   --mode=truth-only       construct DGP + truth loglik (laptop OK)
#   --mode=fit              fit + classify (Totoro-first; do not run S4 yet)
#   --seeds=N[,N...]        override
#
# Default S4 seed list (FROZEN, not comparable to Phase 4B numbers):
#   20260914:20260923
#
# Run from the repository root:
#   env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
#     julia --project=. sim/v08_fa_s2_prereg.jl --mode=truth-only --seeds=20260914

using Dates
using HSquared
using LinearAlgebra
using Printf
using Random

const DLOG_EPS = 1e-6
const HEYWOOD_PSI = 1e-4
const THRESHOLD_G = 0.45
const THRESHOLD_R = 0.25
const SAMPLING_REL_CAP = 1.5
const DEFAULT_ITERATIONS = 5000
const GATE_SEEDS = collect(20260914:20260923)

function _ledermann_slack(t::Int, K::Int)
    return (t - K)^2 - (t + K)
end

function _parse_args(args)
    opts = Dict{String,String}()
    for arg in args
        startswith(arg, "--") || throw(ArgumentError("arguments must use --key=value form, got $arg"))
        keyval = split(arg[3:end], "=", limit = 2)
        length(keyval) == 2 || throw(ArgumentError("arguments must use --key=value form, got $arg"))
        opts[keyval[1]] = keyval[2]
    end
    cell = get(opts, "cell", "d4-k1")
    cell in ("d4-k1", "d3-diagnostic") ||
        throw(ArgumentError("--cell must be d4-k1 or d3-diagnostic"))
    mode = Symbol(get(opts, "mode", "truth-only"))
    mode in (:fit, Symbol("truth-only")) ||
        throw(ArgumentError("--mode must be fit or truth-only"))
    seeds = if haskey(opts, "seeds")
        parsed = Int[]
        for raw in split(opts["seeds"], ",")
            seed_text = strip(raw)
            isempty(seed_text) && throw(ArgumentError("--seeds must not contain empty entries"))
            push!(parsed, parse(Int, seed_text))
        end
        isempty(parsed) && throw(ArgumentError("--seeds must include at least one seed"))
        parsed
    else
        copy(GATE_SEEDS)
    end
    iterations = parse(Int, get(opts, "iterations", string(DEFAULT_ITERATIONS)))
    iterations > 0 || throw(ArgumentError("--iterations must be positive"))
    out = get(opts, "out", "")
    return (; cell, mode, seeds, iterations, out)
end

function _halfsib_pedigree(nsire, ndam, noffspring)
    sire_ids = ["s$(i)" for i in 1:nsire]
    dam_ids = ["d$(i)" for i in 1:ndam]
    offspring_ids = ["o$(i)" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, offspring_ids)
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

# Gate DGP: Phase 4B pedigree/records, one extra trait, K stays 1.
# First three loadings / uniqueness / R-block copy S1 exactly.
function _simulate_d4_k1(seed::Int)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(6, 12, 42)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    t = 4
    K = 1
    loadings = reshape([0.9, 0.55, -0.35, 0.40], t, K)
    uniqueness = [0.35, 0.45, 0.55, 0.50]
    Gtrue = Matrix(factor_analytic_covariance(loadings, uniqueness))
    Rtrue = [
        0.85  0.18  0.05  0.06
        0.18  0.75 -0.08  0.04
        0.05 -0.08  0.65  0.03
        0.06  0.04  0.03  0.70
    ]
    isposdef(Symmetric(Gtrue)) || error("d4-k1 Gtrue is not PD")
    isposdef(Symmetric(Rtrue)) || error("d4-k1 Rtrue is not PD")
    slack = _ledermann_slack(t, K)
    slack == 4 || error("d4-k1 ledermann_slack must be 4, got $slack")
    LA = cholesky(Symmetric(A)).L
    LG = cholesky(Symmetric(Gtrue)).L
    LR = cholesky(Symmetric(Rtrue)).L
    U = LA * randn(rng, q, t) * transpose(LG)
    records_per_animal = 3
    n = q * records_per_animal
    X = ones(n, 1)
    Z = zeros(n, q)
    Y = zeros(n, t)
    row = 1
    for animal in 1:q, _rep in 1:records_per_animal
        Z[row, animal] = 1.0
        Y[row, :] .= 1.5 .+ U[animal, :] .+
                     (randn(rng, 1, t) * transpose(LR))[1, :]
        row += 1
    end
    initial = (loadings = 0.7 .* loadings, uniqueness = 1.3 .* uniqueness, R0 = 1.2 .* Rtrue)
    return (; Y, X, Z, Ainv, Gtrue, Rtrue, loadings, uniqueness, initial, q, t, K, slack)
end

# S1 DGP, diagnostic only. Never a covered-flip pass cell.
function _simulate_d3_diagnostic(seed::Int)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(6, 12, 42)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    t = 3
    K = 1
    loadings = reshape([0.9, 0.55, -0.35], t, K)
    uniqueness = [0.35, 0.45, 0.55]
    Gtrue = Matrix(factor_analytic_covariance(loadings, uniqueness))
    Rtrue = [0.85 0.18 0.05; 0.18 0.75 -0.08; 0.05 -0.08 0.65]
    slack = _ledermann_slack(t, K)
    slack == 0 || error("d3-diagnostic ledermann_slack must be 0, got $slack")
    LA = cholesky(Symmetric(A)).L
    LG = cholesky(Symmetric(Gtrue)).L
    LR = cholesky(Symmetric(Rtrue)).L
    U = LA * randn(rng, q, t) * transpose(LG)
    records_per_animal = 3
    n = q * records_per_animal
    X = ones(n, 1)
    Z = zeros(n, q)
    Y = zeros(n, t)
    row = 1
    for animal in 1:q, _rep in 1:records_per_animal
        Z[row, animal] = 1.0
        Y[row, :] .= 1.5 .+ U[animal, :] .+
                     (randn(rng, 1, t) * transpose(LR))[1, :]
        row += 1
    end
    initial = (loadings = 0.7 .* loadings, uniqueness = 1.3 .* uniqueness, R0 = 1.2 .* Rtrue)
    return (; Y, X, Z, Ainv, Gtrue, Rtrue, loadings, uniqueness, initial, q, t, K, slack)
end

function _classify(; converged, rel_g, rel_r, dlog, min_psi, ledermann_slack)
    heywood_flag = min_psi < HEYWOOD_PSI
    old_gr_ok = converged && rel_g <= THRESHOLD_G && rel_r <= THRESHOLD_R
    gate_ok = old_gr_ok && !heywood_flag && ledermann_slack > 0
    class = if gate_ok
        "ok_recovery"
    elseif old_gr_ok && heywood_flag
        # Explicit: the Phase 4B / S1 G/R gates would have accepted this seed.
        "heywood_accepted_by_old_gr"
    elseif dlog >= -DLOG_EPS && heywood_flag
        "heywood_boundary"
    elseif dlog < -DLOG_EPS
        "optimizer_miss"
    elseif ledermann_slack <= 0 && old_gr_ok && !heywood_flag
        "diagnostic_saturated"
    elseif dlog >= -DLOG_EPS && !heywood_flag &&
            (rel_g > THRESHOLD_G || rel_r > THRESHOLD_R) &&
            max(rel_g / THRESHOLD_G, rel_r / THRESHOLD_R) <= SAMPLING_REL_CAP
        "sampling_vs_threshold"
    else
        "unclassified"
    end
    return class, heywood_flag, old_gr_ok
end

function _header()
    return join([
        "seed", "cell", "mode", "t", "K", "ledermann_slack",
        "converged", "iterations", "rel_g", "rel_r",
        "loglik_fit", "loglik_truth", "dlog_fit_minus_truth",
        "min_psi_hat", "psi1", "psi2", "psi3", "psi4",
        "cond_Ghat", "min_eig_Ghat",
        "heywood_flag", "old_gr_ok", "class", "seconds",
    ], "\t")
end

function _pad_psi(psi::AbstractVector)
    vals = Vector{Float64}(undef, 4)
    fill!(vals, NaN)
    n = min(length(psi), 4)
    vals[1:n] .= Float64.(psi[1:n])
    return (vals[1], vals[2], vals[3], vals[4])
end

function _run_seed(seed::Int; cell::String, mode::Symbol, iterations::Int)
    sim = cell == "d4-k1" ? _simulate_d4_k1(seed) : _simulate_d3_diagnostic(seed)
    loglik_truth = HSquared._multivariate_reml_loglik(sim.Y, sim.X, sim.Z, sim.Ainv, sim.Gtrue, sim.Rtrue)
    if mode == Symbol("truth-only")
        return (
            seed = seed,
            cell = cell,
            mode = "truth-only",
            t = sim.t,
            K = sim.K,
            ledermann_slack = sim.slack,
            converged = missing,
            iterations = 0,
            rel_g = NaN,
            rel_r = NaN,
            loglik_fit = NaN,
            loglik_truth = loglik_truth,
            dlog = NaN,
            min_psi = NaN,
            psi = (NaN, NaN, NaN, NaN),
            cond_G = NaN,
            min_eig = NaN,
            heywood_flag = missing,
            old_gr_ok = missing,
            class = "truth_only",
            seconds = 0.0,
        )
    end
    t0 = time()
    fit = fit_multivariate_reml(
        sim.Y, sim.X, sim.Z, sim.Ainv;
        genetic_structure = :factor_analytic,
        rank = sim.K,
        initial = sim.initial,
        iterations = iterations,
    )
    seconds = time() - t0
    psi = collect(Float64.(fit.genetic_uniqueness))
    min_psi = minimum(psi)
    Ghat = Matrix(fit.genetic_covariance)
    rel_g = norm(Ghat - sim.Gtrue) / norm(sim.Gtrue)
    rel_r = norm(Matrix(fit.residual_covariance) - sim.Rtrue) / norm(sim.Rtrue)
    dlog = fit.loglik - loglik_truth
    ev = eigvals(Symmetric(Ghat))
    class, heywood_flag, old_gr_ok = _classify(;
        converged = fit.converged,
        rel_g = rel_g,
        rel_r = rel_r,
        dlog = dlog,
        min_psi = min_psi,
        ledermann_slack = sim.slack,
    )
    return (
        seed = seed,
        cell = cell,
        mode = "fit",
        t = sim.t,
        K = sim.K,
        ledermann_slack = sim.slack,
        converged = fit.converged,
        iterations = fit.iterations,
        rel_g = rel_g,
        rel_r = rel_r,
        loglik_fit = fit.loglik,
        loglik_truth = loglik_truth,
        dlog = dlog,
        min_psi = min_psi,
        psi = _pad_psi(psi),
        cond_G = cond(Symmetric(Ghat)),
        min_eig = minimum(ev),
        heywood_flag = heywood_flag,
        old_gr_ok = old_gr_ok,
        class = class,
        seconds = seconds,
    )
end

function _fmt_missing_bool(x)
    return x === missing ? "NA" : string(x)
end

function _row(r)
    return join([
        string(r.seed),
        r.cell,
        r.mode,
        string(r.t),
        string(r.K),
        string(r.ledermann_slack),
        _fmt_missing_bool(r.converged),
        string(r.iterations),
        @sprintf("%.8f", r.rel_g),
        @sprintf("%.8f", r.rel_r),
        @sprintf("%.8f", r.loglik_fit),
        @sprintf("%.8f", r.loglik_truth),
        @sprintf("%.8f", r.dlog),
        @sprintf("%.8e", r.min_psi),
        @sprintf("%.8e", r.psi[1]),
        @sprintf("%.8e", r.psi[2]),
        @sprintf("%.8e", r.psi[3]),
        @sprintf("%.8e", r.psi[4]),
        @sprintf("%.6e", r.cond_G),
        @sprintf("%.8e", r.min_eig),
        _fmt_missing_bool(r.heywood_flag),
        _fmt_missing_bool(r.old_gr_ok),
        r.class,
        @sprintf("%.3f", r.seconds),
    ], "\t")
end

function main(args = ARGS)
    cfg = _parse_args(args)
    println("# HSquared.jl v0.8 S2 FA recovery-gate prereg  $(Dates.now())")
    println("# host=$(gethostname())  julia=$(VERSION)")
    println("# FROZEN. NOT a covered flip. NOT an S3/S4 campaign.")
    println("# cell=$(cfg.cell)  mode=$(cfg.mode)  seeds=$(cfg.seeds)  iterations=$(cfg.iterations)")
    println("# GATE DGP: t=4 K=1 ledermann_slack=4; uniqueness floor min(psi-hat) >= $HEYWOOD_PSI")
    println("# OLD G/R gates (rel_g<=$THRESHOLD_G, rel_r<=$THRESHOLD_R) ACCEPT collapsed uniqueness — S1 proved this.")
    println("# class ok_recovery now requires uniqueness interior AND slack>0.")
    println("# class rules: DLOG_EPS=$DLOG_EPS HEYWOOD_PSI=$HEYWOOD_PSI THRESHOLD_G=$THRESHOLD_G THRESHOLD_R=$THRESHOLD_R")
    println(_header())
    flush(stdout)
    rows = String[_header()]
    classes = String[]
    slacks = Int[]
    for seed in cfg.seeds
        r = _run_seed(seed; cell = cfg.cell, mode = cfg.mode, iterations = cfg.iterations)
        line = _row(r)
        println(line)
        flush(stdout)
        push!(rows, line)
        push!(classes, r.class)
        push!(slacks, r.ledermann_slack)
    end
    if !isempty(cfg.out)
        open(cfg.out, "w") do io
            println(io, "# HSquared.jl v0.8 S2 FA recovery-gate prereg  $(Dates.now())")
            println(io, "# cell=$(cfg.cell) mode=$(cfg.mode) seeds=$(cfg.seeds)")
            for line in rows
                println(io, line)
            end
        end
        println("# wrote $(cfg.out)")
    end
    println("# CLASS_COUNTS")
    for c in unique(classes)
        @printf("#   %s\t%d\n", c, count(==(c), classes))
    end
    println("# LEDERMANN_SLACK unique=$(unique(slacks))")
    return nothing
end

main()
