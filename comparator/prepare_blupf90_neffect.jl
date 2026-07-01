# Prepare a BLUPF90 comparator packet for the arbitrary-N (K=3) independent-effect
# REML estimator (`fit_multi_effect_reml`): animal additive (~A) + environment 1 (~I) +
# environment 2 (~I), the same non-confounded DGP as the recovery gate
# (`sim/phase3_neffect_recovery_gate.jl`). Reconstructs the gate's first predeclared seed
# (20260800, records = all q animals) EXACTLY (same RNG draw order), fits the engine to get
# the same-estimand REML target, and writes whitespace BLUPF90 inputs + a renumf90.par
# (three cross effects; animal ~ A via FILE ped; env1 + env2 ~ diagonal, NEUTRAL 1.0
# starts for isolation) so blupf90+ AIREMLF90 can estimate (σa², σg1², σg2², σe²).
#
#   julia --project=. comparator/prepare_blupf90_neffect.jl

using HSquared
using LinearAlgebra
using Random
using Printf

const SEED = 20260800
const MU, SA, SG1, SG2, SE = 2.0, 1.0, 0.5, 0.5, 1.0
const NG1, NG2 = 80, 60
const OUT = joinpath(@__DIR__, "blupf90_neffect")

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
    sa, sg1, sg2, se = s[1], s[2], s[3], fit.variance_components.sigma_e2

    # data.dat: y intercept animal_code group1 group2  (records = all q animals)
    open(joinpath(OUT, "neffect.dat"), "w") do io
        for a in 1:q
            @printf(io, "%.10f 1 %d %d %d\n", y[a], a, g1[a], g2[a])
        end
    end
    open(joinpath(OUT, "neffect.ped"), "w") do io
        for i in eachindex(ped.ids)
            println(io, join((i, ped.sire[i], ped.dam[i]), " "))
        end
    end
    open(joinpath(OUT, "engine_target.csv"), "w") do io
        println(io, "quantity,value")
        @printf(io, "sigma_a2,%.12g\n", sa)
        @printf(io, "sigma_g1_2,%.12g\n", sg1)
        @printf(io, "sigma_g2_2,%.12g\n", sg2)
        @printf(io, "sigma_e2,%.12g\n", se)
        @printf(io, "converged,%s\n", fit.converged)
    end
    # renumf90.par — animal (field 3) ~ A; env1 (field 4) ~ diagonal; env2 (field 5) ~
    # diagonal. NEUTRAL 1.0 starts (isolation: blupf90 finds the optimum unaided).
    par = [
        "DATAFILE", "neffect.dat",
        "TRAITS", "1",
        "FIELDS_PASSED TO OUTPUT", "",
        "WEIGHT(S)", "",
        "RESIDUAL_VARIANCE", "1.0",
        "EFFECT", "2 cross alpha",
        "EFFECT", "3 cross alpha",
        "RANDOM", "animal",
        "FILE", "neffect.ped",
        "FILE_POS", "1 2 3 0 0",
        "(CO)VARIANCES", "1.0",
        "EFFECT", "4 cross alpha",
        "RANDOM", "diagonal",
        "(CO)VARIANCES", "1.0",
        "EFFECT", "5 cross alpha",
        "RANDOM", "diagonal",
        "(CO)VARIANCES", "1.0",
        "OPTION method VCE",
    ]
    open(joinpath(OUT, "renumf90.par"), "w") do io
        for l in par; println(io, l); end
    end

    println("Wrote N-effect (K=3) BLUPF90 packet to ", OUT)
    println("records=$q, ngroup1=$NG1, ngroup2=$NG2; converged=$(fit.converged)")
    @printf("ENGINE TARGET: σa²=%.6f σg1²=%.6f σg2²=%.6f σe²=%.6f\n", sa, sg1, sg2, se)
end

main()
