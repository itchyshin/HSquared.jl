# v0.8 S2 — single-step n≫6 recovery gate (FROZEN · campaign NOT RUN at freeze)
# OPT-IN, OUT of CI. Does NOT flip V2-SSHINV. Does NOT flip FA. Count stays 7.
#
# Locked by docs/dev-log/recovery-checkpoints/2026-09-03-v08-ss-n-recovery-gate-predeclaration.md
# Cite the git commit that introduced this file + that checkpoint.
# Do not edit gate constants after freeze; a new n / PASS / seed block is a new prereg.
#
# Why this DGP exists: the n=6 AGHmatrix construction smoke (seed 20260903)
# recovered σ²a = 0.076 vs truth 1.0 (converged). Expected unidentified
# (6 animals / 3 genotyped / 2 VCs). Construction AGREE ≠ estimator recovery
# when the true covariance is H with G ≠ A₂₂.
#
# Frozen:
#   pedigree     40 sires / 80 dams / 120 offspring  (n = 240, n² = 57600 ≤ 1e6)
#   genotyped    last generation only (offspring ids "o*"; 120/240 = 50%)
#   G            A₂₂ + 0.05 I   (same estimand as AGHmatrix Hmatrix packet;
#                NOT VanRaden — V2-GRM stays out of this claim)
#   knobs        τ = ω = 1, blend = ridge = 0
#   truth        (σ²a, σ²e, μ) = (1.0, 1.5, 2.0)
#   start        (σ²a, σ²e) = (0.5, 1.0)  — cold, not at truth
#   DGP          u ~ N(0, H σ²a) via chol(H), y = μ + u + e
#   gate seeds   20265000:20265047   (48; unseen at declaration)
#   PASS         48/48 converged AND |bias| ≤ 2·MCSE on σ²a AND σ²e
#                h² is reported, not gated (derived-estimand identity is §3.3)
#
# Modes:
#   --mode=construct     build H only (path / size / G≠A₂₂ check)
#   --mode=smoke         one disjoint seed (default 20264999); NOT a gate
#   --mode=feasibility   3 disjoint seeds 20264990:20264992; NOT a gate
#   --mode=gate          48 locked seeds; the only PASS/FAIL verdict
#
#   env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
#     julia --project=. sim/v08_ss_s2_recovery.jl --mode=smoke

using Dates
using HSquared
using LinearAlgebra
using Printf
using Random
using SparseArrays
using Statistics

const N_SIRE = 40
const N_DAM = 80
const N_OFF = 120
const G_SHIFT = 0.05
const TAU = 1.0
const OMEGA = 1.0
const BLEND = 0.0
const RIDGE = 0.0
const MU = 2.0
const SA = 1.0
const SE = 1.5
const START_SA = 0.5
const START_SE = 1.0
const GATE_SEEDS = collect(20265000:20265047)
const SMOKE_SEED = 20264999
const FEASIBILITY_SEEDS = collect(20264990:20264992)
const N_LOCKED = N_SIRE + N_DAM + N_OFF
const DENSE_FENCE = 1_000_000

function _parse_args(args)
    opts = Dict{String,String}()
    for arg in args
        startswith(arg, "--") || throw(ArgumentError("arguments must use --key=value form, got $arg"))
        keyval = split(arg[3:end], "=", limit = 2)
        length(keyval) == 2 || throw(ArgumentError("arguments must use --key=value form, got $arg"))
        opts[keyval[1]] = keyval[2]
    end
    mode = Symbol(get(opts, "mode", "smoke"))
    mode in (:construct, :smoke, :feasibility, :gate) ||
        throw(ArgumentError("--mode must be construct, smoke, feasibility, or gate"))
    seeds = if haskey(opts, "seeds")
        parsed = Int[]
        for raw in split(opts["seeds"], ",")
            seed_text = strip(raw)
            isempty(seed_text) && throw(ArgumentError("--seeds must not contain empty entries"))
            push!(parsed, parse(Int, seed_text))
        end
        isempty(parsed) && throw(ArgumentError("--seeds must include at least one seed"))
        parsed
    elseif mode === :gate
        copy(GATE_SEEDS)
    elseif mode === :feasibility
        copy(FEASIBILITY_SEEDS)
    elseif mode === :smoke
        [SMOKE_SEED]
    else
        Int[]
    end
    if mode === :gate && seeds != GATE_SEEDS
        # allow a shard of the locked block; refuse any seed outside it
        extras = setdiff(seeds, GATE_SEEDS)
        isempty(extras) || throw(ArgumentError("--mode=gate seeds must be inside 20265000:20265047, got $extras"))
    end
    out = get(opts, "out", "")
    return (; mode, seeds, out)
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

function _genotyped_rows(ped)
    rows = findall(id -> startswith(string(id), "o"), ped.ids)
    isempty(rows) && throw(ErrorException("no offspring ids found after normalize_pedigree"))
    return rows
end

function _locked_design()
    N_LOCKED^2 <= DENSE_FENCE ||
        throw(ErrorException("locked n=$(N_LOCKED) violates dense fence n² ≤ $(DENSE_FENCE)"))
    ped = _halfsib_pedigree(N_SIRE, N_DAM, N_OFF)
    n = length(ped.ids)
    n == N_LOCKED || throw(ErrorException("pedigree length $n ≠ locked n $N_LOCKED"))
    g_rows = _genotyped_rows(ped)
    length(g_rows) == N_OFF ||
        throw(ErrorException("genotyped $(length(g_rows)) ≠ locked last-gen $N_OFF"))
    Ainv = Matrix(pedigree_inverse(ped))
    A = Matrix(additive_relationship(ped))
    A22 = A[g_rows, g_rows]
    G = A22 + G_SHIFT * I
    g_gap = maximum(abs.(G .- A22))
    g_gap >= G_SHIFT - 1e-12 ||
        throw(ErrorException("G collapsed onto A₂₂; gap=$g_gap"))
    Hinv = single_step_inverse(Ainv, A, G, g_rows; tau = TAU, omega = OMEGA,
                               blend_weight = BLEND, ridge = RIDGE)
    H = Matrix(inv(Symmetric(Hinv)))
    return (; ped, n, g_rows, Ainv, A, G, Hinv, H, g_gap)
end

function _fit_one(design, seed::Int)
    rng = MersenneTwister(seed)
    n = design.n
    X = ones(n, 1)
    Z = sparse(1.0I, n, n)
    u = cholesky(Symmetric(design.H)).L * randn(rng, n) .* sqrt(SA)
    e = randn(rng, n) .* sqrt(SE)
    y = MU .+ u .+ e
    fit = fit_single_step_reml(y, X, Z, design.Ainv, design.A, design.G, design.g_rows;
                               tau = TAU, omega = OMEGA, blend_weight = BLEND,
                               ridge = RIDGE, initial = (sigma_a2 = START_SA, sigma_e2 = START_SE),
                               ids = design.ped.ids)
    vc = fit.variance_components
    h2 = vc.sigma_a2 / (vc.sigma_a2 + vc.sigma_e2)
    return (seed, fit.converged, vc.sigma_a2, vc.sigma_e2, h2)
end

function _report(name, v, truth)
    n = length(v)
    m = mean(v)
    bias = m - truth
    if n < 2
        @printf("  %-4s mean=%.4f truth=%.2f bias=%+.4f MCSE=n<2  (not scored)\n",
                name, m, truth, bias)
        return false
    end
    mcse = std(v) / sqrt(n)
    ratio = mcse == 0 ? Inf : abs(bias) / mcse
    ok = abs(bias) <= 2 * mcse
    @printf("  %-4s mean=%.4f truth=%.2f bias=%+.4f MCSE=%.4f |bias|/MCSE=%.2f  %s\n",
            name, m, truth, bias, mcse, ratio, ok ? "PASS" : "FAIL")
    return ok
end

function _write_rows(path, rows)
    isempty(path) && return
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "seed\tconverged\tsigma_a2\tsigma_e2\th2\tmode_note")
        for (seed, conv, sa, se, h2, note) in rows
            @printf(io, "%d\t%s\t%.12g\t%.12g\t%.12g\t%s\n",
                    seed, conv, sa, se, h2, note)
        end
    end
    println("Wrote ", path)
end

function main(args = ARGS)
    opts = _parse_args(args)
    println("# HSquared.jl v0.8 SS n≫6 recovery gate  $(Dates.now())")
    println("# host=$(gethostname())  julia=$(VERSION)")
    println("# NOT a covered flip. V2-SSHINV stays partial. Count stays 7.")
    @printf("# locked n=%d (sire=%d dam=%d off=%d) G=A22+%.2f I τ=ω=1 blend=ridge=0\n",
            N_LOCKED, N_SIRE, N_DAM, N_OFF, G_SHIFT)
    println("# truth (σ²a, σ²e, μ)=($(SA), $(SE), $(MU)); start=($(START_SA), $(START_SE))")
    println("# mode=$(opts.mode)")

    design = _locked_design()
    @printf("# constructed n=%d n_geno=%d max|G-A22|=%.4f cond(H)=%.3e\n",
            design.n, length(design.g_rows), design.g_gap, cond(Symmetric(design.H)))

    if opts.mode === :construct
        println("CONSTRUCT: path ok (no fit)")
        return 0
    end

    note = opts.mode === :gate ? "gate" : string(opts.mode) * "_not_gate"
    rows = Tuple{Int,Bool,Float64,Float64,Float64,String}[]
    sa = Float64[]
    se = Float64[]
    h2v = Float64[]
    nconv = 0
    for seed in opts.seeds
        s, conv, a, e, h = _fit_one(design, seed)
        conv && (nconv += 1)
        push!(sa, a)
        push!(se, e)
        push!(h2v, h)
        push!(rows, (s, conv, a, e, h, note))
        @printf("  seed=%d conv=%s σ²a=%.4f σ²e=%.4f h²=%.4f\n", s, conv, a, e, h)
    end
    _write_rows(opts.out, rows)

    n = length(opts.seeds)
    println("Single-step REML $(opts.mode) — $n seed(s), converged=$nconv/$n")
    okg = _report("σ²a", sa, SA)
    oke = _report("σ²e", se, SE)
    _report("h²", h2v, SA / (SA + SE))
    if opts.mode === :gate && opts.seeds == GATE_SEEDS
        gate = (nconv == n) && okg && oke
        println("GATE: ", gate ? "PASS" : "FAIL",
                "  (converged $nconv/$n; |bias|≤2·MCSE on σ²a=$okg σ²e=$oke; h² reported-not-gated)")
        println("Read as no detectable across-seed bias, never unbiased. No covered flip.")
        return gate ? 0 : 2
    else
        println("NOT A GATE. mode=$(opts.mode). Do not treat this printout as PASS/FAIL.")
        return 0
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main())
end
