using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in recovery harness for the Gamma (log-link) JOINT estimator
`fit_laplace_reml(...; family = :gamma)` (v0.6, Phase 5).

Outside `test/` so the package suite stays RNG-free. Simulates a known-truth
A = I animal model with repeated records (so the iid animal variance σ²a is
identified), `y | u ~ Gamma(shape ν, mean = exp(β + u))`, `u ~ N(0, σ²a)`, fits the
joint `(σ²a, ν)` estimator, and reports across-seed bias / Monte-Carlo SE. The gate
is the doc-16 aggregate form: `|bias| ≤ 2·MCSE` for σ²a and ν over the seeds.

Run:  julia --project=. sim/phase6_gamma_recovery.jl [--seeds=N] [--q=N] [--reps=N]
      [--sigma2a=X] [--shape=X] [--beta=X]
"""

# Marsaglia–Tsang Gamma(shape α, scale θ) sampler — dependency-free.
function _rand_gamma(rng, α, θ)
    if α < 1
        return _rand_gamma(rng, α + 1, θ) * rand(rng)^(1 / α)
    end
    d = α - 1 / 3
    c = 1 / sqrt(9d)
    while true
        x = randn(rng)
        v = (1 + c * x)^3
        v <= 0 && continue
        u = rand(rng)
        if log(u) < 0.5 * x^2 + d - d * v + d * log(v)
            return d * v * θ
        end
    end
end

function _parse(args)
    o = Dict{String,String}()
    for a in args
        startswith(a, "--") || throw(ArgumentError("args use --key=value"))
        kv = split(a[3:end], "=", limit = 2); length(kv) == 2 || throw(ArgumentError("bad arg $a"))
        o[kv[1]] = kv[2]
    end
    return (seeds = parse(Int, get(o, "seeds", "48")), q = parse(Int, get(o, "q", "80")),
            reps = parse(Int, get(o, "reps", "4")), sigma2a = parse(Float64, get(o, "sigma2a", "0.35")),
            shape = parse(Float64, get(o, "shape", "3.0")), beta = parse(Float64, get(o, "beta", "0.6")))
end

function _one(seed, p)
    rng = MersenneTwister(seed)
    n = p.q * p.reps
    id = repeat(1:p.q, inner = p.reps)
    u = sqrt(p.sigma2a) .* randn(rng, p.q)
    X = ones(n, 1); Z = zeros(n, p.q); y = zeros(n)
    for i in 1:n
        Z[i, id[i]] = 1.0
        μ = exp(p.beta + u[id[i]])
        y[i] = _rand_gamma(rng, p.shape, μ / p.shape)      # mean = shape·scale = μ
    end
    Ainv = Matrix(1.0I, p.q, p.q)
    f = fit_laplace_reml(y, X, Z, Ainv; family = :gamma, theta_init = p.shape)
    return (f.variance_components.sigma_a2, f.variance_components.shape, f.converged)
end

function main(args = ARGS)
    p = _parse(args)
    @printf("START gamma recovery seeds=%d q=%d reps=%d truth: σ²a=%.3f ν=%.3f β=%.3f\n",
        p.seeds, p.q, p.reps, p.sigma2a, p.shape, p.beta)
    sas = Float64[]; nus = Float64[]; conv = 0
    for s in 1:p.seeds
        sa, nu, c = _one(20260700 + s, p)
        push!(sas, sa); push!(nus, nu); c && (conv += 1)
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
    w2 = report("ν", nus, p.shape)
    @printf("  converged=%d/%d\n", conv, m)
    gate = w1 && w2 && conv == m
    @printf("GATE gamma_recovery within_2mcse_all=%s converged_all=%s gate_pass=%s seeds=%d\n",
        string(w1 && w2), string(conv == m), string(gate), m)
    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
