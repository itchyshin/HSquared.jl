using HSquared
using LinearAlgebra
using Random

# Deterministic Poisson (log-link) animal-model dataset + the engine
# `fit_laplace_reml` target, serialized for the MCMCglmm agreement comparator
# (`run_mcmcglmm.R`). Bayesian/MCMC AGREEMENT, not same-estimand REML parity.
# See README.md. Mirrors comparator/binomial_mcmcglmm/.
#
# Run from the repository root:
#   PATH="$HOME/.juliaup/bin:$PATH" julia --project=. comparator/poisson_mcmcglmm/generate.jl

const SEED = 20260622
const SIGMA_A2 = 1.0
const MU = 0.0
const OUTDIR = @__DIR__

_rand_pois(rng, lam) = begin
    lam <= 0 && return 0
    L = exp(-lam)
    k = 0
    p = 1.0
    while true
        k += 1
        p *= rand(rng)
        p <= L && return k - 1
    end
end

function main()
    rng = MersenneTwister(SEED)
    sire_ids = ["s$i" for i in 1:15]
    dam_ids = ["d$i" for i in 1:30]
    off_ids = ["o$i" for i in 1:300]
    src_ids = vcat(sire_ids, dam_ids, off_ids)
    src_sire = vcat(fill("0", 45), [sire_ids[((i - 1) % 15) + 1] for i in 1:300])
    src_dam = vcat(fill("0", 45), [dam_ids[((i - 1) % 30) + 1] for i in 1:300])
    ped = normalize_pedigree(src_ids, src_sire, src_dam)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    u = (cholesky(Symmetric(A)).L * randn(rng, q)) .* sqrt(SIGMA_A2)  # ped.ids order
    y = Float64[_rand_pois(rng, exp(MU + u[a])) for a in 1:q]
    X = ones(q, 1)
    Z = Matrix(1.0I, q, q)

    fit = HSquared.fit_laplace_reml(y, X, Z, Ainv; family = :poisson,
                                    initial = (sigma_a2 = 1.0,))
    payload = HSquared.nongaussian_result_payload(fit)
    sa2 = payload.variance_components.sigma_a2
    ebv = collect(Float64, fit.breeding_values)   # positional, ped.ids order
    beta = collect(Float64, payload.fixed_effects)
    pids = collect(String, ped.ids)

    pmap = Dict(src_ids[i] => (src_sire[i], src_dam[i]) for i in eachindex(src_ids))
    na(x) = x == "0" ? "NA" : x

    open(joinpath(OUTDIR, "pedigree.csv"), "w") do io
        println(io, "id,sire,dam")
        for pid in pids
            s, d = pmap[pid]
            println(io, pid, ",", na(s), ",", na(d))
        end
    end
    open(joinpath(OUTDIR, "phenotypes.csv"), "w") do io
        println(io, "id,count")
        for a in 1:q
            println(io, pids[a], ",", Int(round(y[a])))
        end
    end
    open(joinpath(OUTDIR, "engine_target.csv"), "w") do io
        println(io, "id,ebv,u_true")
        for a in 1:q
            println(io, pids[a], ",", ebv[a], ",", u[a])
        end
    end
    open(joinpath(OUTDIR, "engine_summary.csv"), "w") do io
        println(io, "field,value")
        println(io, "sigma_a2,", sa2)
        println(io, "intercept,", beta[1])
        println(io, "converged,", payload.converged)
        println(io, "q,", q)
        println(io, "mean_count,", sum(y) / q)
        println(io, "sigma_a2_truth,", SIGMA_A2)
        println(io, "mu_truth,", MU)
        println(io, "seed,", SEED)
    end

    println("engine target written to ", OUTDIR)
    println("  sigma_a2 = ", round(sa2, digits = 4), " (truth ", SIGMA_A2, ")")
    println("  intercept = ", round(beta[1], digits = 4), " (truth ", MU, ")")
    println("  q = ", q, ", mean count = ", round(sum(y) / q, digits = 2),
            ", converged = ", payload.converged)
end

main()
