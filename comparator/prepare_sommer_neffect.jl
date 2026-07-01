# Prepare a sommer comparator packet for the arbitrary-N (K=3) independent-effect
# REML estimator (`fit_multi_effect_reml`): animal additive (~A) + env1 (~I) + env2 (~I).
# Reconstructs the recovery gate's first predeclared seed (20260800) EXACTLY (same RNG
# draw order as `sim/phase3_neffect_recovery_gate.jl`), fits the engine to get the
# same-estimand REML target, and writes a CSV data frame + the dense relationship matrix
# `A` (with 1-based integer row/col names) so R `sommer::mmer` can estimate the same
# (σa², σg1², σg2², σe²) via `vsr(animal, Gu = A) + vsr(g1) + vsr(g2)`.
#
#   julia --project=. comparator/prepare_sommer_neffect.jl

using HSquared
using LinearAlgebra
using Random
using Printf
using DelimitedFiles

const SEED = 20260800
const MU, SA, SG1, SG2, SE = 2.0, 1.0, 0.5, 0.5, 1.0
const NG1, NG2 = 80, 60
const OUT = joinpath(@__DIR__, "sommer_neffect")

function _halfsib_pedigree(nsire, ndam, noffspring)
    sire_ids = ["s$i" for i in 1:nsire]
    dam_ids = ["d$i" for i in 1:ndam]
    off_ids = ["o$i" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(fill("0", nsire + ndam),
                [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring])
    dam = vcat(fill("0", nsire + ndam),
               [dam_ids[((i - 1) % ndam) + 1] for i in 1:noffspring])
    return normalize_pedigree(ids, sire, dam)
end

function main(; nsire = 20, ndam = 40, noffspring = 800)
    mkpath(OUT)
    rng = MersenneTwister(SEED)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    LA = cholesky(Symmetric(A)).L
    u1 = (LA * randn(rng, q)) .* sqrt(SA)
    g1 = [rand(rng, 1:NG1) for _ in 1:q]
    ug1 = randn(rng, NG1) .* sqrt(SG1)
    g2 = [rand(rng, 1:NG2) for _ in 1:q]
    ug2 = randn(rng, NG2) .* sqrt(SG2)
    e = randn(rng, q) .* sqrt(SE)
    X = ones(q, 1)
    Z1 = Matrix(1.0I, q, q)
    Zg1 = zeros(q, NG1); for a in 1:q; Zg1[a, g1[a]] = 1.0; end
    Zg2 = zeros(q, NG2); for a in 1:q; Zg2[a, g2[a]] = 1.0; end
    y = MU .+ u1 .+ Zg1 * ug1 .+ Zg2 * ug2 .+ e

    fit = HSquared.fit_multi_effect_reml(y, X, [(Z1, Ainv), (Zg1, Matrix(1.0I, NG1, NG1)),
                                               (Zg2, Matrix(1.0I, NG2, NG2))];
                                         initial = [1.0, 1.0, 1.0, 1.0])
    s = fit.variance_components.sigmas
    sa, sg1v, sg2v, se = s[1], s[2], s[3], fit.variance_components.sigma_e2

    # data.csv — records = all q animals; animal code = pedigree index 1..q
    open(joinpath(OUT, "neffect.csv"), "w") do io
        println(io, "y,animal,g1,g2")
        for a in 1:q
            @printf(io, "%.10f,%d,%d,%d\n", y[a], a, g1[a], g2[a])
        end
    end
    # A.csv — dense relationship matrix with a header row/col of 1..q integer names
    open(joinpath(OUT, "A.csv"), "w") do io
        println(io, join(vcat([""], string.(1:q)), ","))   # header: ,1,2,...,q
        for i in 1:q
            println(io, join(vcat([string(i)], [@sprintf("%.10g", A[i, j]) for j in 1:q]), ","))
        end
    end
    open(joinpath(OUT, "engine_target.csv"), "w") do io
        println(io, "quantity,value")
        @printf(io, "sigma_a2,%.12g\n", sa)
        @printf(io, "sigma_g1_2,%.12g\n", sg1v)
        @printf(io, "sigma_g2_2,%.12g\n", sg2v)
        @printf(io, "sigma_e2,%.12g\n", se)
        @printf(io, "converged,%s\n", fit.converged)
    end
    println("Wrote sommer N-effect packet to ", OUT)
    @printf("ENGINE TARGET: σa²=%.6f σg1²=%.6f σg2²=%.6f σe²=%.6f (converged=%s)\n",
            sa, sg1v, sg2v, se, fit.converged)
end

main()
