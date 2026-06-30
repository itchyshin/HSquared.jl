# Prepare a BLUPF90 comparator packet for the two-effect REML estimator
# (`fit_two_effect_reml`): animal additive (~A) + common-environment group (~I).
#
# Reconstructs ONE deterministic dataset (the recovery harness's first predeclared
# seed), fits the engine to get the same-estimand REML target, and writes
# whitespace BLUPF90 inputs + a CORRECT renumf90.par (keyword/value on separate
# lines; `cross alpha`; FILE_POS; a 2nd diagonal RANDOM effect) so blupf90+ can
# estimate (sigma1^2, sigma2^2, sigma_e2) on the same data.
#
#   julia --project=. comparator/prepare_blupf90_two_effect.jl

using HSquared
using LinearAlgebra
using Random
using Printf

const SEED = 20260618
const MU, S1, S2, SE = 2.0, 1.0, 0.5, 1.0
const OUT = joinpath(@__DIR__, "blupf90_two_effect")

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

function main(; nsire = 20, ndam = 40, noffspring = 800, ngroup = 80)
    mkpath(OUT)
    rng = MersenneTwister(SEED)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv1 = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv1))))
    q = length(ped.ids)
    LA = cholesky(Symmetric(A)).L
    u1 = (LA * randn(rng, q)) .* sqrt(S1)
    group = [rand(rng, 1:ngroup) for _ in 1:q]
    u2 = randn(rng, ngroup) .* sqrt(S2)
    X = ones(q, 1)
    Z1 = Matrix(1.0I, q, q)
    Z2 = zeros(q, ngroup)
    for a in 1:q
        Z2[a, group[a]] = 1.0
    end
    Ainv2 = Matrix(1.0I, ngroup, ngroup)
    e = randn(rng, q) .* sqrt(SE)
    y = MU .+ u1 .+ Z2 * u2 .+ e

    fit = HSquared.fit_two_effect_reml(y, X, Z1, Ainv1, Z2, Ainv2;
                                       initial = (sigma1 = 1.0, sigma2 = 1.0, sigma_e2 = 1.0))
    vc = fit.variance_components

    # `ped.sire`/`ped.dam` are already integer-coded (0 = unknown, else 1-based index
    # into ped.ids) — i.e. exactly the animal code we use (pedigree order = i).

    # data.dat: y intercept animal_code group_code
    open(joinpath(OUT, "two_effect.dat"), "w") do io
        for a in 1:q
            @printf(io, "%.10f 1 %d %d\n", y[a], a, group[a])
        end
    end
    # pedigree: animal sire dam (integer-coded)
    open(joinpath(OUT, "two_effect.ped"), "w") do io
        for i in eachindex(ped.ids)
            println(io, join((i, ped.sire[i], ped.dam[i]), " "))
        end
    end
    # engine target
    open(joinpath(OUT, "engine_target.csv"), "w") do io
        println(io, "quantity,value")
        @printf(io, "sigma1_2,%.12g\n", vc.sigma1)
        @printf(io, "sigma2_2,%.12g\n", vc.sigma2)
        @printf(io, "sigma_e2,%.12g\n", vc.sigma_e2)
        @printf(io, "converged,%s\n", fit.converged)
    end
    # renumf90.par — CORRECT format (animal ~ A; group ~ diagonal I)
    par = [
        "DATAFILE", "two_effect.dat",
        "TRAITS", "1",
        "FIELDS_PASSED TO OUTPUT", "",
        "WEIGHT(S)", "",
        "RESIDUAL_VARIANCE", @sprintf("%.10f", vc.sigma_e2),
        "EFFECT", "2 cross alpha",
        "EFFECT", "3 cross alpha",
        "RANDOM", "animal",
        "FILE", "two_effect.ped",
        "FILE_POS", "1 2 3 0 0",
        "(CO)VARIANCES", @sprintf("%.10f", vc.sigma1),
        "EFFECT", "4 cross alpha",
        "RANDOM", "diagonal",
        "(CO)VARIANCES", @sprintf("%.10f", vc.sigma2),
        "OPTION method VCE",
    ]
    open(joinpath(OUT, "renumf90.par"), "w") do io
        for l in par; println(io, l); end
    end

    println("Wrote two-effect BLUPF90 packet to ", OUT)
    println("q=$q records, ngroup=$ngroup; converged=$(fit.converged)")
    @printf("ENGINE TARGET: sigma1^2=%.6f  sigma2^2=%.6f  sigma_e2=%.6f\n", vc.sigma1, vc.sigma2, vc.sigma_e2)
end

main()
