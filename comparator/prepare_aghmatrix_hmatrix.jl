# v0.8 S1 — single-step H / H⁻¹ packet for AGHmatrix::Hmatrix
# OPT-IN, OUT of CI. Does NOT flip V2-SSHINV. Not a Mrode Ch.11 numerical anchor.
#
# Serializes a tiny half-sib fixture (same 6-id pedigree as the FA-lane S0
# construction probe) plus the engine `single_step_inverse` target so
# `run_aghmatrix_hmatrix.R` can compare inv(AGHmatrix::Hmatrix(...)) to H⁻¹.
# Also dumps one supplied-H recovery smoke (not a predeclared gate).
#
#   julia --project=. comparator/prepare_aghmatrix_hmatrix.jl

using Dates
using HSquared
using LinearAlgebra
using Printf
using Random
using SparseArrays

const OUT = joinpath(@__DIR__, "aghmatrix_hmatrix")
const IDS = ["s1", "d1", "d2", "o1", "o2", "o3"]
const SIRE = ["0", "0", "0", "s1", "s1", "s1"]
const DAM = ["0", "0", "0", "d1", "d1", "d2"]
const G_ROWS = [4, 5, 6]          # offspring treated as genotyped
const G_SHIFT = 0.05
const TAU = 1.0
const OMEGA = 1.0
const BLEND = 0.0
const RIDGE = 0.0
const SMOKE_SEED = 20260903
const SA = 1.0
const SE = 1.5

function _write_labeled_matrix(path, M, ids)
    open(path, "w") do io
        println(io, join(vcat([""], ids), ","))
        for i in eachindex(ids)
            println(io, join(vcat([ids[i]], [@sprintf("%.12g", M[i, j]) for j in eachindex(ids)]), ","))
        end
    end
end

function main()
    mkpath(OUT)
    ped = normalize_pedigree(IDS, SIRE, DAM)
    Ainv = Matrix(pedigree_inverse(ped))
    A = Matrix(additive_relationship(ped))
    A22 = A[G_ROWS, G_ROWS]
    G = A22 + G_SHIFT * I
    Hinv = single_step_inverse(Ainv, A, G, G_ROWS; tau = TAU, omega = OMEGA,
                               blend_weight = BLEND, ridge = RIDGE)
    H = Matrix(inv(Symmetric(Hinv)))
    reduce_resid = maximum(abs.(single_step_inverse(Ainv, A, A22, G_ROWS) .- Ainv))

    _write_labeled_matrix(joinpath(OUT, "A.csv"), A, IDS)
    _write_labeled_matrix(joinpath(OUT, "G.csv"), G, IDS[G_ROWS])
    _write_labeled_matrix(joinpath(OUT, "engine_hinv.csv"), Hinv, IDS)
    _write_labeled_matrix(joinpath(OUT, "engine_H.csv"), H, IDS)

    open(joinpath(OUT, "metadata.csv"), "w") do io
        println(io, "key,value")
        println(io, "n,", length(IDS))
        println(io, "genotyped,", join(IDS[G_ROWS], ";"))
        println(io, "genotyped_rows,", join(G_ROWS, ";"))
        @printf(io, "g_shift,%.12g\n", G_SHIFT)
        @printf(io, "tau,%.12g\n", TAU)
        @printf(io, "omega,%.12g\n", OMEGA)
        @printf(io, "blend_weight,%.12g\n", BLEND)
        @printf(io, "ridge,%.12g\n", RIDGE)
        @printf(io, "G_eq_A22_maxabs_Hinv_minus_Ainv,%.12g\n", reduce_resid)
        println(io, "mrode_ch11_anchor,NO_ANCHOR")
        println(io, "aghmatrix_method,Martini")
        println(io, "not_a_covered_flip,true")
    end

    # One-seed supplied-H recovery smoke (not a gate; not a flip).
    rng = MersenneTwister(SMOKE_SEED)
    n = length(IDS)
    X = ones(n, 1)
    Z = sparse(1.0I, n, n)
    LH = cholesky(Symmetric(H)).L
    y = 2.0 .+ (LH * randn(rng, n)) .* sqrt(SA) .+ randn(rng, n) .* sqrt(SE)
    fit = fit_single_step_reml(y, X, Z, Ainv, A, G, G_ROWS;
                               tau = TAU, omega = OMEGA, blend_weight = BLEND,
                               ridge = RIDGE, ids = IDS)
    sa = fit.variance_components.sigma_a2
    se = fit.variance_components.sigma_e2
    open(joinpath(OUT, "engine_recovery_smoke.csv"), "w") do io
        println(io, "quantity,value")
        @printf(io, "seed,%d\n", SMOKE_SEED)
        @printf(io, "truth_sigma_a2,%.12g\n", SA)
        @printf(io, "truth_sigma_e2,%.12g\n", SE)
        @printf(io, "fit_sigma_a2,%.12g\n", sa)
        @printf(io, "fit_sigma_e2,%.12g\n", se)
        println(io, "converged,", fit.converged)
        println(io, "n,", n)
        println(io, "note,one-seed smoke on n=6; NOT a predeclared recovery gate")
    end

    println("# HSquared.jl v0.8 S1 AGHmatrix Hmatrix packet  $(Dates.now())")
    println("# host=$(gethostname())  julia=$(VERSION)")
    println("# NOT a covered flip. Mrode Ch.11 = explicit NO-ANCHOR.")
    @printf("# G=A22 reduction max|Hinv-Ainv|=%.3e\n", reduce_resid)
    @printf("# recovery smoke n=%d seed=%d σ²a=%.4f (truth %.2f) σ²e=%.4f (truth %.2f) conv=%s\n",
            n, SMOKE_SEED, sa, SA, se, SE, string(fit.converged))
    println("Wrote ", OUT)
    reduce_resid <= 1e-10 || exit(1)
    return nothing
end

main()
