# v0.8 S1 — FA calibration diagnosis (design-42)
# OPT-IN, OUT of CI. Does NOT flip V4-FA. Does NOT run a recovery campaign.
#
# Discriminating test: fitted REML loglik vs loglik at TRUE (G, R), jointly
# with min(ψ̂) and cond(Ĝ). Classifies Heywood / optimizer-miss / sampling
# vs a too-tight threshold. DGP is pinned to
# `sim/phase4b_structured_covariance_recovery.jl` (nsire=6, ndam=12,
# noffspring=42, records=3, t=3, K=1, same loadings / uniqueness / R).
#
# Cells (choose one):
#   --cell=d3-fail      banked FA fails 20260616,20260619 (default)
#   --cell=d3-contrast  fails + one banked pass 20260614
#   --cell=d3-panel     full banked FA panel 20260614..20260623
#   --seeds=N[,N...]    override (mutually exclusive with a named panel if set)
#   --mode=fit          fit + classify (default)
#   --mode=truth-only   evaluate truth loglik only (wiring smoke; no fit)
#
# Classification PRE-DECLARED here and in
# docs/dev-log/decisions/2026-09-03-v08-s1-fa-diagnose-predeclare.md
# (design-42 "The one test to run first"):
#   ok_recovery           converged AND rel_g ≤ 0.45 AND rel_r ≤ 0.25
#   heywood_boundary      Δℓ = ℓ_fit − ℓ_truth ≥ −1e-6 AND min(ψ̂) < 1e-4
#   optimizer_miss        Δℓ < −1e-6
#   sampling_vs_threshold Δℓ ≥ −1e-6 AND min(ψ̂) ≥ 1e-4 AND failed G/R
#                         AND max(rel_g/0.45, rel_r/0.25) ≤ 1.5
#   unclassified          else
# heywood_flag is always emitted independently of class.
#
# Run from the repository root:
#   env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
#     julia --project=. sim/v08_fa_s1_diagnose.jl --cell=d3-contrast
#
# Totoro-first for --mode=fit. Laptop is for --mode=truth-only wiring only.

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
const BANKED_FAIL = [20260616, 20260619]
const BANKED_PASS_CONTRAST = [20260614]
const BANKED_PANEL = collect(20260614:20260623)

function _parse_args(args)
    opts = Dict{String,String}()
    for arg in args
        startswith(arg, "--") || throw(ArgumentError("arguments must use --key=value form, got $arg"))
        keyval = split(arg[3:end], "=", limit = 2)
        length(keyval) == 2 || throw(ArgumentError("arguments must use --key=value form, got $arg"))
        opts[keyval[1]] = keyval[2]
    end
    cell = get(opts, "cell", "d3-fail")
    cell in ("d3-fail", "d3-contrast", "d3-panel") ||
        throw(ArgumentError("--cell must be d3-fail, d3-contrast, or d3-panel"))
    mode = Symbol(get(opts, "mode", "fit"))
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
    elseif cell == "d3-fail"
        copy(BANKED_FAIL)
    elseif cell == "d3-contrast"
        vcat(BANKED_FAIL, BANKED_PASS_CONTRAST)
    else
        copy(BANKED_PANEL)
    end
    iterations = parse(Int, get(opts, "iterations", string(DEFAULT_ITERATIONS)))
    iterations > 0 || throw(ArgumentError("--iterations must be positive"))
    out = get(opts, "out", "")
    return (; cell, mode, seeds, iterations, out)
end

# DGP pin: identical to phase4b_structured_covariance_recovery.jl:84-140.
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

function _simulate_fa(seed::Int)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(6, 12, 42)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    t = 3
    loadings = reshape([0.9, 0.55, -0.35], t, 1)
    uniqueness = [0.35, 0.45, 0.55]
    Gtrue = Matrix(factor_analytic_covariance(loadings, uniqueness))
    Rtrue = [0.85 0.18 0.05; 0.18 0.75 -0.08; 0.05 -0.08 0.65]
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
    return (; Y, X, Z, Ainv, Gtrue, Rtrue, loadings, uniqueness, initial, q, t)
end

function _classify(; converged, rel_g, rel_r, dlog, min_psi)
    heywood_flag = min_psi < HEYWOOD_PSI
    ok = converged && rel_g <= THRESHOLD_G && rel_r <= THRESHOLD_R
    class = if ok
        "ok_recovery"
    elseif dlog >= -DLOG_EPS && heywood_flag
        "heywood_boundary"
    elseif dlog < -DLOG_EPS
        "optimizer_miss"
    elseif dlog >= -DLOG_EPS && !heywood_flag &&
            (rel_g > THRESHOLD_G || rel_r > THRESHOLD_R) &&
            max(rel_g / THRESHOLD_G, rel_r / THRESHOLD_R) <= SAMPLING_REL_CAP
        "sampling_vs_threshold"
    else
        "unclassified"
    end
    return class, heywood_flag
end

function _header()
    return join([
        "seed", "mode", "converged", "iterations", "rel_g", "rel_r",
        "loglik_fit", "loglik_truth", "dlog_fit_minus_truth",
        "min_psi_hat", "psi1", "psi2", "psi3",
        "cond_Ghat", "min_eig_Ghat", "ledermann_slack",
        "heywood_flag", "class", "seconds",
    ], "\t")
end

function _run_seed(seed::Int; mode::Symbol, iterations::Int)
    sim = _simulate_fa(seed)
    loglik_truth = HSquared._multivariate_reml_loglik(sim.Y, sim.X, sim.Z, sim.Ainv, sim.Gtrue, sim.Rtrue)
    t = sim.t
    K = 1
    ledermann_slack = (t - K)^2 - (t + K)
    if mode == Symbol("truth-only")
        return (
            seed = seed,
            mode = "truth-only",
            converged = missing,
            iterations = 0,
            rel_g = NaN,
            rel_r = NaN,
            loglik_fit = NaN,
            loglik_truth = loglik_truth,
            dlog = NaN,
            min_psi = NaN,
            psi = (NaN, NaN, NaN),
            cond_G = NaN,
            min_eig = NaN,
            ledermann_slack = ledermann_slack,
            heywood_flag = missing,
            class = "truth_only",
            seconds = 0.0,
        )
    end
    t0 = time()
    fit = fit_multivariate_reml(
        sim.Y, sim.X, sim.Z, sim.Ainv;
        genetic_structure = :factor_analytic,
        rank = 1,
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
    class, heywood_flag = _classify(;
        converged = fit.converged,
        rel_g = rel_g,
        rel_r = rel_r,
        dlog = dlog,
        min_psi = min_psi,
    )
    return (
        seed = seed,
        mode = "fit",
        converged = fit.converged,
        iterations = fit.iterations,
        rel_g = rel_g,
        rel_r = rel_r,
        loglik_fit = fit.loglik,
        loglik_truth = loglik_truth,
        dlog = dlog,
        min_psi = min_psi,
        psi = (psi[1], psi[2], psi[3]),
        cond_G = cond(Symmetric(Ghat)),
        min_eig = minimum(ev),
        ledermann_slack = ledermann_slack,
        heywood_flag = heywood_flag,
        class = class,
        seconds = seconds,
    )
end

function _row(r)
    conv = r.converged === missing ? "NA" : string(r.converged)
    hey = r.heywood_flag === missing ? "NA" : string(r.heywood_flag)
    return join([
        string(r.seed),
        r.mode,
        conv,
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
        @sprintf("%.6e", r.cond_G),
        @sprintf("%.8e", r.min_eig),
        string(r.ledermann_slack),
        hey,
        r.class,
        @sprintf("%.3f", r.seconds),
    ], "\t")
end

function main(args = ARGS)
    cfg = _parse_args(args)
    println("# HSquared.jl v0.8 S1 FA diagnose (design-42)  $(Dates.now())")
    println("# host=$(gethostname())  julia=$(VERSION)")
    println("# cell=$(cfg.cell)  mode=$(cfg.mode)  seeds=$(cfg.seeds)  iterations=$(cfg.iterations)")
    println("# DGP pin: phase4b FA (6/12/42 × 3 records; t=3 K=1; Ledermann-saturated)")
    println("# class rules: DLOG_EPS=$DLOG_EPS HEYWOOD_PSI=$HEYWOOD_PSI THRESHOLD_G=$THRESHOLD_G THRESHOLD_R=$THRESHOLD_R SAMPLING_REL_CAP=$SAMPLING_REL_CAP")
    println("# NOT a covered flip. NOT a recovery campaign. WOMBAT not required for this cell.")
    println(_header())
    flush(stdout)
    rows = String[_header()]
    classes = String[]
    for seed in cfg.seeds
        r = _run_seed(seed; mode = cfg.mode, iterations = cfg.iterations)
        line = _row(r)
        println(line)
        flush(stdout)
        push!(rows, line)
        push!(classes, r.class)
    end
    if !isempty(cfg.out)
        open(cfg.out, "w") do io
            println(io, "# HSquared.jl v0.8 S1 FA diagnose  $(Dates.now())")
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
    return nothing
end

main()
