using HSquared
using LinearAlgebra
using Random

# Deterministic per-record varying-trial Binomial animal-model dataset + the
# engine `fit_laplace_reml` target, serialized for the MCMCglmm agreement
# comparator (`run_mcmcglmm.R`). This directly cross-validates the per-record
# varying-trial path (engine `BinomialVectorResponse`; R activation in
# itchyshin/hsquared#101). Bayesian/MCMC AGREEMENT, not same-estimand REML
# parity. See README.md.
#
# Run from the repository root:
#   PATH="$HOME/.juliaup/bin:$PATH" julia --project=. comparator/binomial_mcmcglmm/generate.jl

const SEED = 20260622
const SIGMA_A2 = 1.0
const MU = 0.0
const NT_RANGE = 1:30   # per-record varying trials (the general cbind GLMM)
const OUTDIR = @__DIR__

_logistic(η) = η >= 0 ? 1.0 / (1.0 + exp(-η)) : (e = exp(η); e / (1.0 + e))
_rand_binom(rng, m, p) = sum(rand(rng) < p ? 1 : 0 for _ in 1:m)

function halfsib_pedigree(nsire, ndam, noffspring)
    sire_ids = ["s$i" for i in 1:nsire]
    dam_ids = ["d$i" for i in 1:ndam]
    off_ids = ["o$i" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(fill("0", nsire + ndam),
                [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring])
    dam = vcat(fill("0", nsire + ndam),
               [dam_ids[((i - 1) % ndam) + 1] for i in 1:noffspring])
    return ids, sire, dam
end

function main()
    rng = MersenneTwister(SEED)
    ids, sire, dam = halfsib_pedigree(15, 30, 300)
    ped = normalize_pedigree(ids, sire, dam)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    LA = cholesky(Symmetric(A)).L
    u = (LA * randn(rng, q)) .* sqrt(SIGMA_A2)                 # ped.ids order
    nt = [rand(rng, NT_RANGE) for _ in 1:q]
    y = Float64[_rand_binom(rng, nt[a], _logistic(MU + u[a])) for a in 1:q]
    X = ones(q, 1)
    Z = Matrix(1.0I, q, q)

    fit = HSquared.fit_laplace_reml(y, X, Z, Ainv; family = :binomial,
                                    n_trials = nt, initial = (sigma_a2 = 1.0,))
    payload = HSquared.nongaussian_result_payload(fit)        # stable bridge contract
    sa2 = payload.variance_components.sigma_a2
    ebv = collect(Float64, fit.breeding_values)               # positional, ped.ids order
    beta = collect(Float64, payload.fixed_effects)
    pids = collect(String, ped.ids)

    # parent lookup keyed by id; founders ("0") -> "NA" for R/nadiv
    pmap = Dict(ids[i] => (sire[i], dam[i]) for i in eachindex(ids))
    na(x) = x == "0" ? "NA" : x

    open(joinpath(OUTDIR, "pedigree.csv"), "w") do io
        println(io, "id,sire,dam")
        for pid in pids
            s, d = pmap[pid]
            println(io, pid, ",", na(s), ",", na(d))
        end
    end
    open(joinpath(OUTDIR, "phenotypes.csv"), "w") do io
        println(io, "id,successes,failures,n_trials")
        for a in 1:q
            yi = Int(round(y[a]))
            println(io, pids[a], ",", yi, ",", nt[a] - yi, ",", nt[a])
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
        println(io, "mean_n_trials,", sum(nt) / q)
        println(io, "sigma_a2_truth,", SIGMA_A2)
        println(io, "mu_truth,", MU)
        println(io, "seed,", SEED)
    end

    println("engine target written to ", OUTDIR)
    println("  sigma_a2 = ", round(sa2, digits = 4), " (truth ", SIGMA_A2, ")")
    println("  intercept = ", round(beta[1], digits = 4), " (truth ", MU, ")")
    println("  q = ", q, ", mean n_trials = ", round(sum(nt) / q, digits = 2),
            ", converged = ", fit.converged)
end

main()
