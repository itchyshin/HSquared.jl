# Prepare a BLUPF90 GREML comparator packet for genomic REML (`fit_gblup_reml`).
#
# Same-estimand isolation: the engine builds VanRaden G and its regularized inverse
# Ginv; BLUPF90 is given the SAME Ginv via RANDOM_TYPE user_file, so the comparison
# is purely "REML on the same G" (it does NOT re-derive G — that isolates the REML
# estimator from G-construction conventions). blupf90+ starts from NEUTRAL values.
#
#   julia --project=. comparator/prepare_blupf90_genomic.jl

using HSquared
using LinearAlgebra
using Random
using Printf
using SHA

const SEED = 20260630
const N, M = 300, 1000
const MU, SG2, SE2 = 2.0, 0.6, 0.4
const OUT = joinpath(@__DIR__, "blupf90_genomic")

function main()
    mkpath(OUT)
    rng = MersenneTwister(SEED)
    p = [0.1 + 0.8 * rand(rng) for _ in 1:M]
    markers = Float64[ (rand(rng) < p[j]) + (rand(rng) < p[j]) for i in 1:N, j in 1:M ]
    ids = string.(1:N)
    marker_names = ["m$(j)" for j in 1:M]
    construction = HSquared._genomic_activation_construction(
        markers, ids; marker_names = marker_names, ridge = 0.01,
    )
    Ginv = construction.Q
    u = cholesky(Symmetric(construction.K)).L * randn(rng, N) .* sqrt(SG2)
    e = randn(rng, N) .* sqrt(SE2)
    y = MU .+ u .+ e

    fit = fit_gblup_reml(y, ones(N, 1), Matrix(1.0I, N, N), Ginv)
    vc = fit.variance_components

    # data: y intercept animal_code(1..N)
    open(joinpath(OUT, "genomic.dat"), "w") do io
        for i in 1:N
            @printf(io, "%.10f 1 %d\n", y[i], i)
        end
    end
    # Ginv as BLUPF90 user_file upper triangle: i j value (1-indexed, i<=j).
    # Write every entry at 17 significant digits so parsing round-trips Float64;
    # no thresholding may silently change the supplied precision.
    open(joinpath(OUT, "ginv.txt"), "w") do io
        for i in 1:N, j in i:N
            v = Ginv[i, j]
            @printf(io, "%d %d %.17g\n", i, j, v)
        end
    end
    # engine target
    open(joinpath(OUT, "engine_target.csv"), "w") do io
        println(io, "quantity,value")
        @printf(io, "sigma_a2,%.12g\n", vc.sigma_a2)
        @printf(io, "sigma_e2,%.12g\n", vc.sigma_e2)
        @printf(io, "h2,%.12g\n", vc.sigma_a2 / (vc.sigma_a2 + vc.sigma_e2))
        @printf(io, "converged,%s\n", fit.converged)
    end
    provenance = construction.provenance
    open(joinpath(OUT, "provenance.csv"), "w") do io
        println(io, "field,value")
        for field in keys(provenance)
            @printf(io, "%s,%s\n", String(field), string(getfield(provenance, field)))
        end
    end
    # renf90.par — direct (no renumf90), user_file Ginv, NEUTRAL starts
    par = [
        "DATAFILE", "genomic.dat",
        "NUMBER_OF_TRAITS", "1",
        "NUMBER_OF_EFFECTS", "2",
        "OBSERVATION(S)", "1",
        "WEIGHT(S)", "",
        "EFFECTS: POSITIONS_IN_DATAFILE NUMBER_OF_LEVELS TYPE_OF_EFFECT",
        "2 1 cross",
        @sprintf("3 %d cross", N),
        "RANDOM_RESIDUAL VALUES", "1.0",   # neutral start
        "RANDOM_GROUP", "2",
        "RANDOM_TYPE", "user_file",
        "FILE", "ginv.txt",
        "(CO)VARIANCES", "1.0",            # neutral start
        "OPTION method VCE",
    ]
    open(joinpath(OUT, "renf90.par"), "w") do io
        for l in par; println(io, l); end
    end

    open(joinpath(OUT, "input_sha256.csv"), "w") do io
        println(io, "file,sha256")
        for file in ("genomic.dat", "ginv.txt", "renf90.par", "engine_target.csv", "provenance.csv")
            digest = bytes2hex(SHA.sha256(read(joinpath(OUT, file))))
            println(io, file, ",", digest)
        end
    end

    println("Wrote genomic BLUPF90 packet to ", OUT)
    println("N=$N M=$M converged=$(fit.converged)")
    @printf("ENGINE TARGET: sigma_a2=%.6f  sigma_e2=%.6f  h2=%.4f\n",
            vc.sigma_a2, vc.sigma_e2, vc.sigma_a2 / (vc.sigma_a2 + vc.sigma_e2))
end

main()
