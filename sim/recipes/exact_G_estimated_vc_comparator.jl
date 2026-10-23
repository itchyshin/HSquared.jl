# exact_G_estimated_vc_comparator.jl — S0b recipe (Fisher tols ratified 2026-09-02)
#
# Purpose: export the engine's exact VanRaden-1 G and K_lambda so a
# same-estimand estimated-VC comparator (sommer primary, rrBLUP secondary) can
# share one hashed matrix with HSquared.jl REML.
#
# HONESTY:
#   - NOT a covered flip. Count stays 6 until design-41 §3 + Rose + #7.
#   - NOT the 2026-06-22 supplied-variance comparator.
#   - NOT D1 / quarantine / ASReml.
#   - Shared kernel is K_lambda = G + 0.01 I (design-51 / design-52).
#
# Tiny smoke (laptop OK):
#   julia --project=. sim/recipes/exact_G_estimated_vc_comparator.jl
#
# Validation-scale export (Totoro one-shot):
#   JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. \
#     sim/recipes/exact_G_estimated_vc_comparator.jl --mode=export \
#     --out=sim/recipes/exact_G_packet
#   Rscript sim/recipes/run_exact_G_estimated_vc.R sim/recipes/exact_G_packet

using Dates
using LinearAlgebra
using Random
using SHA
using SparseArrays
using HSquared

const RECIPE_ID = "0.7-S0b-exact-G-estimated-VC"
const RIDGE_DEFAULT = 0.01
const VAL_N = 300
const VAL_M = 1000
const VAL_SEED = 202609022
const VAL_SG2 = 0.6
const VAL_SE2 = 0.4
const VAL_MU = 2.0
const TOL_REL_VC = 0.02
const TOL_ABS_RG = 0.02

"""
    vanraden1_G(markers; ridge=0.0) -> NamedTuple

Build VanRaden method-1 `G = WW'/k` with sample allele frequencies.
When `ridge > 0`, also return `K = G + ridge*I` (design-51 / design-44 scale).
"""
function vanraden1_G(markers::AbstractMatrix{<:Real}; ridge::Real = 0.0)
    n, m = size(markers)
    n >= 2 || throw(ArgumentError("need n >= 2 genotyped rows"))
    m >= 1 || throw(ArgumentError("need ≥1 marker"))
    p = vec(sum(markers; dims = 1)) ./ (2n)
    W = Matrix{Float64}(markers) .- (2 .* p')
    k = 2 * sum(p .* (1 .- p))
    k > 0 || throw(ArgumentError("VanRaden k must be > 0"))
    G = (W * W') ./ k
    G = Symmetric(0.5 .* (G .+ G'))
    K = ridge > 0 ? Symmetric(Matrix(G) .+ Float64(ridge) .* I(n)) : G
    return (; G = Matrix(G), K = Matrix(K), p, k, ridge = Float64(ridge), n, m)
end

function matrix_sha256(A::AbstractMatrix{<:Real})
    bytes = reinterpret(UInt8, vec(Float64.(A)))
    return bytes2hex(sha256(bytes))
end

function write_matrix_csv(path::AbstractString, A::AbstractMatrix; ids = nothing)
    open(path, "w") do io
        if ids === nothing
            println(io, join(["c$j" for j in 1:size(A, 2)], ","))
            for i in 1:size(A, 1)
                println(io, join(string.(A[i, :]), ","))
            end
        else
            println(io, join(["id"; ids], ","))
            for (i, id) in enumerate(ids)
                println(io, join([string(id); string.(A[i, :])], ","))
            end
        end
    end
    return path
end

function _opt(args, key, default = nothing)
    prefix = "--$(key)="
    for arg in args
        startswith(arg, prefix) && return split(arg, "="; limit = 2)[2]
    end
    return default
end

"""
Tiny deterministic smoke: build G/K_lambda, hash, and fit engine REML on K^{-1}.
Does **not** call sommer/rrBLUP (those live on R/Totoro hosts).
"""
function smoke_exact_G_export(; n = 12, m = 40, seed = 20260902, ridge = RIDGE_DEFAULT)
    rng = MersenneTwister(seed)
    markers = rand(rng, 0:2, n, m) .* 1.0
    ids = ["i$i" for i in 1:n]
    built = vanraden1_G(markers; ridge = ridge)
    G_engine = genomic_relationship_matrix(markers)
    Q = genomic_relationship_inverse(G_engine; ridge = ridge)
    @assert size(G_engine) == (n, n)
    X = ones(n, 1)
    Z = sparse(1.0I, n, n)
    u = cholesky(Symmetric(Matrix(G_engine) .+ 1e-8 .* I(n))).L * randn(rng, n)
    y = sqrt(0.6) .* u .+ sqrt(0.4) .* randn(rng, n)
    fit = fit_gblup_reml(y, X, Z, Q; ids = ids,
                         initial = (sigma_a2 = 0.6, sigma_e2 = 0.4))
    rG = heritability(fit)
    meta = Dict(
        "recipe_id" => RECIPE_ID,
        "seed" => seed,
        "n" => n,
        "m" => m,
        "ridge" => ridge,
        "k" => built.k,
        "G_sha256" => matrix_sha256(Matrix(G_engine)),
        "K_sha256" => matrix_sha256(built.K),
        "sigma_a2" => fit.variance_components.sigma_a2,
        "sigma_e2" => fit.variance_components.sigma_e2,
        "genomic_variance_ratio_numeric" => rG,
        "converged" => fit.converged,
        "note" => "numeric ratio only on engine; R labels genomic_variance_ratio (N2)",
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
    )
    return (; built, G_engine, Q, fit, meta)
end

"""
Validation-scale packet for the Totoro estimated-VC one-shot (design-52).
DGP matches `sim/phase2_genomic_reml_recovery.jl` (chol(K) · truth), new seed.
"""
function export_validation_packet(
    outdir::AbstractString;
    n::Int = VAL_N,
    m::Int = VAL_M,
    seed::Int = VAL_SEED,
    ridge::Real = RIDGE_DEFAULT,
)
    mkpath(outdir)
    rng = MersenneTwister(seed)
    p = [0.1 + 0.8 * rand(rng) for _ in 1:m]
    markers = Float64[(rand(rng) < p[j]) + (rand(rng) < p[j]) for i in 1:n, j in 1:m]
    ids = ["i$i" for i in 1:n]
    G = Matrix(genomic_relationship_matrix(markers))
    K = Matrix(Symmetric(G .+ Float64(ridge) .* I(n)))
    Q = Matrix(genomic_relationship_inverse(G; ridge = ridge))
    u = cholesky(Symmetric(K)).L * randn(rng, n) .* sqrt(VAL_SG2)
    e = randn(rng, n) .* sqrt(VAL_SE2)
    y = VAL_MU .+ u .+ e
    X = ones(n, 1)
    Z = sparse(1.0I, n, n)
    t0 = time()
    fit = fit_gblup_reml(y, X, Z, Q; ids = ids)
    engine_s = time() - t0
    vc = fit.variance_components
    rG = vc.sigma_a2 / (vc.sigma_a2 + vc.sigma_e2)
    gebv = breeding_values(fit).values
    phen_path = joinpath(outdir, "phen.csv")
    open(phen_path, "w") do io
        println(io, "id,y")
        for i in 1:n
            println(io, ids[i], ",", y[i])
        end
    end
    write_matrix_csv(joinpath(outdir, "G.csv"), G; ids = ids)
    write_matrix_csv(joinpath(outdir, "K.csv"), K; ids = ids)
    open(joinpath(outdir, "engine_target.csv"), "w") do io
        println(io, "quantity,value")
        println(io, "sigma_g2,", vc.sigma_a2)
        println(io, "sigma_e2,", vc.sigma_e2)
        println(io, "r_G,", rG)
        println(io, "converged,", Int(fit.converged))
        println(io, "engine_seconds,", engine_s)
    end
    open(joinpath(outdir, "engine_gebv.csv"), "w") do io
        println(io, "id,gebv")
        for i in 1:n
            println(io, ids[i], ",", gebv[i])
        end
    end
    meta_path = joinpath(outdir, "meta.csv")
    open(meta_path, "w") do io
        println(io, "key,value")
        pairs = [
            "recipe_id" => RECIPE_ID,
            "seed" => string(seed),
            "n" => string(n),
            "m" => string(m),
            "ridge" => string(ridge),
            "truth_sigma_g2" => string(VAL_SG2),
            "truth_sigma_e2" => string(VAL_SE2),
            "truth_r_G" => string(VAL_SG2 / (VAL_SG2 + VAL_SE2)),
            "tol_rel_vc" => string(TOL_REL_VC),
            "tol_abs_rG" => string(TOL_ABS_RG),
            "G_sha256" => matrix_sha256(G),
            "K_sha256" => matrix_sha256(K),
            "kernel" => "K_lambda",
            "note" => "PASS is vs sommer on shared K_lambda, not vs truth",
            "timestamp_utc" => string(Dates.now(Dates.UTC)),
        ]
        for (k, v) in pairs
            println(io, k, ",", v)
        end
    end
    println("EXPORT ", RECIPE_ID)
    println("outdir=", outdir)
    println("n=", n, " m=", m, " seed=", seed)
    println("engine_converged=", fit.converged)
    println("engine_sigma_g2=", vc.sigma_a2)
    println("engine_sigma_e2=", vc.sigma_e2)
    println("engine_r_G=", rG)
    println("engine_seconds=", engine_s)
    println("G_sha256=", matrix_sha256(G))
    println("K_sha256=", matrix_sha256(K))
    return (; outdir, fit, G, K)
end

if abspath(PROGRAM_FILE) == @__FILE__
    mode = something(_opt(ARGS, "mode", "smoke"), "smoke")
    if mode == "smoke"
        result = smoke_exact_G_export()
        println("RECIPE_SMOKE ", RECIPE_ID)
        for (k, v) in sort(collect(result.meta); by = first)
            println(k, "=", v)
        end
        println("STATUS=smoke_ok NOT_LAUNCHED_COMPARATOR")
    elseif mode == "export"
        out = something(_opt(ARGS, "out", joinpath(@__DIR__, "exact_G_packet")),
                        joinpath(@__DIR__, "exact_G_packet"))
        export_validation_packet(out)
        println("STATUS=export_ok RUN_R_NEXT")
    else
        error("unknown --mode=$(mode); expected smoke or export")
    end
end
