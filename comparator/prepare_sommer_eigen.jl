# Prepare a sommer comparator packet for the eigen-once single-effect REML estimator
# (`fit_eigen_reml`, V1-EIGEN-REML G11 comparator leg). Reconstructs the recovery gate's Arm-WS
# first predeclared seed (20267000) EXACTLY (same RNG draw order as
# `sim/phase_eigen_reml_recovery_gate.jl`'s `_make_spec`), fits the engine to get the same-estimand
# REML target (σ²a, σ²e), and writes a CSV data frame + the dense relationship matrix `A`
# (1-based integer row/col names) so R `sommer::mmer` can estimate the same components via
# `vsr(animal, Gu = A)`. sommer runs its OWN independent REML optimizer → same optimum ⇒ AGREE.
#
#   julia --project=. comparator/prepare_sommer_eigen.jl

using HSquared
using LinearAlgebra
using SparseArrays
using Random
using Printf

const SEED = 20267000          # gate Arm WS first seed (window = 50)
const N = 1000
const WINDOW = 50
const MU, SA, SE = 2.0, 1.0, 1.5
const OUT = joinpath(@__DIR__, "sommer_eigen")

# Byte-identical reconstruction of the gate's _make_spec(N, SEED; window=WINDOW, sa=SA, se=SE):
# pedigree draws, then A = inv(Ainv), then u = √SA·chol(A).L·z, then e, then y = μ + u + e.
function main()
    mkpath(OUT)
    rng = MersenneTwister(SEED)
    s = zeros(Int, N); d = zeros(Int, N)
    for i in 3:N
        lo = WINDOW > 0 ? max(1, i - WINDOW) : 1
        s[i] = rand(rng, lo:i-1); d[i] = rand(rng, lo:i-1)
        while d[i] == s[i]; d[i] = rand(rng, lo:i-1); end
    end
    Ainv = pedigree_inverse(collect(1:N), s, d)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    LA = cholesky(Symmetric(A)).L
    u = (LA * randn(rng, N)) .* sqrt(SA)
    e = randn(rng, N) .* sqrt(SE)
    y = MU .+ u .+ e
    spec = animal_model_spec(y, ones(N, 1), sparse(1.0I, N, N), Ainv; ids = collect(1:N), method = :REML)

    fit = fit_eigen_reml(spec)
    sa = fit.variance_components.sigma_a2
    se = fit.variance_components.sigma_e2

    open(joinpath(OUT, "eigen.csv"), "w") do io
        println(io, "y,animal")
        for a in 1:N
            @printf(io, "%.10f,%d\n", y[a], a)
        end
    end
    open(joinpath(OUT, "A.csv"), "w") do io
        println(io, join(vcat([""], string.(1:N)), ","))          # header: ,1,2,...,N
        for i in 1:N
            println(io, join(vcat([string(i)], [@sprintf("%.10g", A[i, j]) for j in 1:N]), ","))
        end
    end
    open(joinpath(OUT, "engine_target.csv"), "w") do io
        println(io, "quantity,value")
        @printf(io, "sigma_a2,%.12g\n", sa)
        @printf(io, "sigma_e2,%.12g\n", se)
        @printf(io, "converged,%s\n", fit.converged)
        @printf(io, "target,%s\n", String(fit.target))
    end
    println("Wrote sommer eigen packet (seed $SEED, n=$N, window=$WINDOW) to ", OUT)
    @printf("ENGINE TARGET (fit_eigen_reml): σ²a=%.6f σ²e=%.6f h²=%.4f (converged=%s, target=%s)\n",
            sa, se, sa / (sa + se), fit.converged, String(fit.target))
end

main()
