# Direct same-estimand REML comparator PREP for the SPARSE single-effect AI-REML fitter
# (`fit_ai_reml`) — the F8 comparator leg for the Wave-F production-scale evidence (S6). Builds a
# fresh mid-scale well-structured animal model, fits `fit_ai_reml`, and writes y + the dense
# relationship matrix A + the engine target so R `sommer::mmer` can estimate the same (σ²a, σ²e)
# with its OWN independent REML optimizer → same optimum ⇒ AGREE. This is the DIRECT AI-REML
# comparator (the eigen-thread comparator established sommer≡fit_eigen_reml, and the gate
# established fit_eigen_reml≡fit_ai_reml; this closes sommer≡fit_ai_reml directly). Fresh seed
# 20268400, disjoint from the F5 gate seeds (20268000..20268307).
#
#   julia --project=. comparator/prepare_sommer_aireml.jl

using HSquared
using LinearAlgebra
using SparseArrays
using Random
using Printf

const SEED = 20268400
const N = 2000
const WINDOW = 50                  # well-structured (low fill), where sommer is most robust
const MU, SA, SE = 2.0, 1.0, 1.5
const OUT = joinpath(@__DIR__, "sommer_aireml")

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

    fit = fit_ai_reml(spec; initial = (sigma_a2 = 0.8, sigma_e2 = 0.8))
    sa = fit.variance_components.sigma_a2
    se = fit.variance_components.sigma_e2

    open(joinpath(OUT, "data.csv"), "w") do io
        println(io, "y,animal")
        for a in 1:N
            @printf(io, "%.10f,%d\n", y[a], a)
        end
    end
    open(joinpath(OUT, "A.csv"), "w") do io
        println(io, join(vcat([""], string.(1:N)), ","))
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
    println("Wrote sommer AI-REML packet (seed $SEED, n=$N, window=$WINDOW) to ", OUT)
    @printf("ENGINE TARGET (fit_ai_reml): σ²a=%.6f σ²e=%.6f h²=%.4f (converged=%s, target=%s)\n",
            sa, se, sa / (sa + se), fit.converged, String(fit.target))
end

main()
