using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in recovery harness for the ordered-probit JOINT estimator
`fit_laplace_reml(...; family = :ordered_probit)` (v0.6, Phase 5).

Outside `test/` so the package suite stays RNG-free. Simulates a known-truth A = I
animal model with repeated records (so the ≥3-category σ²a — weakly identified on
small data, cf. the Phase 1 caveat — IS identified), in the ENGINE parameterization:
latent `l = β + u + e`, `u ~ N(0, σ²a)`, `e ~ N(0,1)`; category `y = 1 + Σ_k 1[l > θ_k]`
with cutpoints `θ = [0, θ_2]` (θ_1 = 0 fixed). Recovers `(σ²a, θ_2, β)` and reports
across-seed bias / MCSE. Gate (doc-16 aggregate): `|bias| ≤ 2·MCSE` for σ²a, θ_2, β.

Run:  julia --project=. sim/phase6_ordinal_recovery.jl [--seeds=N] [--q=N] [--reps=N]
      [--sigma2a=X] [--theta2=X] [--beta=X]
"""

function _parse(args)
    o = Dict{String,String}()
    for a in args
        startswith(a, "--") || throw(ArgumentError("args use --key=value"))
        kv = split(a[3:end], "=", limit = 2); length(kv) == 2 || throw(ArgumentError("bad arg $a"))
        o[kv[1]] = kv[2]
    end
    return (seeds = parse(Int, get(o, "seeds", "48")), q = parse(Int, get(o, "q", "120")),
            reps = parse(Int, get(o, "reps", "4")), sigma2a = parse(Float64, get(o, "sigma2a", "0.5")),
            theta2 = parse(Float64, get(o, "theta2", "1.2")), beta = parse(Float64, get(o, "beta", "0.3")))
end

function _one(seed, p)
    rng = MersenneTwister(seed)
    n = p.q * p.reps
    id = repeat(1:p.q, inner = p.reps)
    u = sqrt(p.sigma2a) .* randn(rng, p.q)
    X = ones(n, 1); Z = zeros(n, p.q); y = zeros(n)
    for i in 1:n
        Z[i, id[i]] = 1.0
        l = p.beta + u[id[i]] + randn(rng)         # latent liability, e ~ N(0,1)
        y[i] = 1.0 + (l > 0.0) + (l > p.theta2)     # K = 3 categories (θ_1 = 0, θ_2)
    end
    Ainv = Matrix(1.0I, p.q, p.q)
    f = fit_laplace_reml(y, X, Z, Ainv; family = :ordered_probit, initial = (sigma_a2 = p.sigma2a,))
    return (f.variance_components.sigma_a2, f.variance_components.cutpoints[2], f.beta[1], f.converged)
end

function main(args = ARGS)
    p = _parse(args)
    @printf("START ordinal recovery seeds=%d q=%d reps=%d truth: σ²a=%.3f θ_2=%.3f β=%.3f\n",
        p.seeds, p.q, p.reps, p.sigma2a, p.theta2, p.beta)
    sas = Float64[]; t2s = Float64[]; bs = Float64[]; conv = 0
    for s in 1:p.seeds
        sa, t2, b, c = _one(20260700 + s, p)
        push!(sas, sa); push!(t2s, t2); push!(bs, b); c && (conv += 1)
    end
    m = length(sas)
    report(name, est, truth) = begin
        mean = sum(est) / m
        sd = sqrt(sum(abs2, est .- mean) / (m - 1)); mcse = sd / sqrt(m)
        bias = mean - truth; within = abs(bias) <= 2 * mcse
        @printf("  %-6s true=%.4f mean=%.4f bias=%+.4f MCSE=%.4f |bias|<=2MCSE=%s\n",
            name, truth, mean, bias, mcse, within ? "yes" : "NO")
        within
    end
    println("AGGREGATE recovery (m = $m)")
    w1 = report("σ²a", sas, p.sigma2a)
    w2 = report("θ_2", t2s, p.theta2)
    w3 = report("β", bs, p.beta)
    @printf("  converged=%d/%d\n", conv, m)
    gate = w1 && w2 && w3 && conv == m
    @printf("GATE ordinal_recovery within_2mcse_all=%s converged_all=%s gate_pass=%s seeds=%d\n",
        string(w1 && w2 && w3), string(conv == m), string(gate), m)
    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
