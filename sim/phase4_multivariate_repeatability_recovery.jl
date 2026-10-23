using HSquared
using LinearAlgebra
using Printf
using Random
using Statistics

"""
Known-truth recovery gate for multivariate animal + PE REML (hsquared #237).

Estimates unstructured G0, P0, and R0 with `fit_multivariate_repeatability_reml`.
Does **not** call animal-only `fit_multivariate_reml` for the gated estimates
(that fitter absorbs V_PE into G0). An optional one-seed absorption contrast
prints animal-only G11 vs PE-aware G11 and is not the gate.

Screening tier: across converged seeds, each unique G0 / P0 / R0 element and
per-trait repeatability t_k must satisfy |bias| <= 2 * MCSE. A passing screen
does not flip covered status. Version stays 0.9.0. public_covered_count stays 7.

Default cell (half-sib, 8 sires / 16 dams / 48 offspring, 4 records) is the
local 8-seed screen. Live `randn` streams differ across Julia 1.10 vs 1.13, so
this screen is Julia-version-specific; the in-suite pin is
`test/fixtures/hs237_mv_pe_recovery/Y.csv`. Process exit is 0 iff the
computation finished; GATE_PASS / GATE_FAIL is data, not the exit code.

    julia --project=. sim/phase4_multivariate_repeatability_recovery.jl
    julia --project=. sim/phase4_multivariate_repeatability_recovery.jl --seeds=20260926,20260927
"""

const G0_TRUE = [1.00 0.30; 0.30 0.80]
const P0_TRUE = [0.50 0.10; 0.10 0.40]
const R0_TRUE = [0.80 0.15; 0.15 0.70]

function _halfsib_pedigree(nsire, ndam, noffspring)
    sire_ids = ["s$i" for i in 1:nsire]
    dam_ids = ["d$i" for i in 1:ndam]
    off_ids = ["o$i" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(
        fill("0", nsire + ndam),
        [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring],
    )
    dam = vcat(
        fill("0", nsire + ndam),
        [dam_ids[((i - 1) % ndam) + 1] for i in 1:noffspring],
    )
    return normalize_pedigree(ids, sire, dam)
end

function _extract(args, key, default)
    prefix = "--$key="
    for a in args
        startswith(a, prefix) && return String(split(a, "="; limit = 2)[2])
    end
    return default
end

function _parse_seeds(raw)
    parsed = Int[]
    for token in split(raw, ",")
        text = strip(token)
        isempty(text) && continue
        push!(parsed, parse(Int, text))
    end
    isempty(parsed) && throw(ArgumentError("--seeds must include at least one seed"))
    length(unique(parsed)) == length(parsed) ||
        throw(ArgumentError("--seeds must not contain duplicate entries"))
    return parsed
end

function simulate_mv_pe(seed; nsire, ndam, noffspring, records, G0, P0, R0)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    t = size(G0, 1)
    U = cholesky(Symmetric(A)).L * randn(rng, q, t) * transpose(cholesky(Symmetric(G0)).L)
    PE = randn(rng, q, t) * transpose(cholesky(Symmetric(P0)).L)
    n = q * records
    X = ones(n, 1)
    Z = zeros(n, q)
    Y = zeros(n, t)
    row = 1
    for animal in 1:q, _rep in 1:records
        Z[row, animal] = 1.0
        Y[row, :] .= 2.0 .+ U[animal, :] .+ PE[animal, :] .+
                     (randn(rng, 1, t) * transpose(cholesky(Symmetric(R0)).L))[1, :]
        row += 1
    end
    return Y, X, Z, Ainv
end

function t_true(G0, P0, R0)
    return [(G0[k, k] + P0[k, k]) / (G0[k, k] + P0[k, k] + R0[k, k]) for k in 1:size(G0, 1)]
end

function run_one(seed; nsire, ndam, noffspring, records, iterations)
    Y, X, Z, Ainv = simulate_mv_pe(
        seed;
        nsire = nsire,
        ndam = ndam,
        noffspring = noffspring,
        records = records,
        G0 = G0_TRUE,
        P0 = P0_TRUE,
        R0 = R0_TRUE,
    )
    fit = fit_multivariate_repeatability_reml(
        Y, X, Z, Ainv;
        initial = (G0 = G0_TRUE, P0 = P0_TRUE, R0 = R0_TRUE),
        iterations = iterations,
    )
    fit.estimator === :multivariate_repeatability_reml ||
        error("recovery must use fit_multivariate_repeatability_reml, not animal-only REML")
    return (
        seed = seed,
        converged = fit.converged,
        G = fit.genetic_covariance,
        P = fit.permanent_covariance,
        R = fit.residual_covariance,
        t = fit.repeatability,
    )
end

function _params()
    return [
        ("G11", r -> r.G[1, 1], G0_TRUE[1, 1]),
        ("G21", r -> r.G[2, 1], G0_TRUE[2, 1]),
        ("G22", r -> r.G[2, 2], G0_TRUE[2, 2]),
        ("P11", r -> r.P[1, 1], P0_TRUE[1, 1]),
        ("P21", r -> r.P[2, 1], P0_TRUE[2, 1]),
        ("P22", r -> r.P[2, 2], P0_TRUE[2, 2]),
        ("R11", r -> r.R[1, 1], R0_TRUE[1, 1]),
        ("R21", r -> r.R[2, 1], R0_TRUE[2, 1]),
        ("R22", r -> r.R[2, 2], R0_TRUE[2, 2]),
        ("t1", r -> r.t[1], t_true(G0_TRUE, P0_TRUE, R0_TRUE)[1]),
        ("t2", r -> r.t[2], t_true(G0_TRUE, P0_TRUE, R0_TRUE)[2]),
    ]
end

function print_aggregate(rows)
    ok = [r for r in rows if r.converged]
    m = length(ok)
    println("AGGREGATE Monte Carlo recovery (m = $m converged / $(length(rows)) seeds)")
    println("param  true   mean    bias    MCSE   |bias|<=2MCSE")
    allpass = true
    if m < 2
        println("GATE_FAIL (need at least 2 converged seeds)")
        return false
    end
    for (name, getter, truth) in _params()
        ests = [getter(r) for r in ok]
        mu = mean(ests)
        mcse = std(ests) / sqrt(m)
        bias = mu - truth
        pass = abs(bias) <= 2 * mcse
        allpass = allpass && pass
        @printf("%-4s %6.3f %6.3f %7.3f %7.3f  %s\n",
            name, truth, mu, bias, mcse, pass ? "PASS" : "FAIL")
    end
    println(allpass ? "GATE_PASS" : "GATE_FAIL")
    return allpass
end

function main(args = ARGS)
    seeds = _parse_seeds(_extract(args, "seeds", join(20260926:20260933, ",")))
    nsire = parse(Int, _extract(args, "nsire", "8"))
    ndam = parse(Int, _extract(args, "ndam", "16"))
    noffspring = parse(Int, _extract(args, "noffspring", "48"))
    records = parse(Int, _extract(args, "records", "4"))
    iterations = parse(Int, _extract(args, "iterations", "2000"))
    rows = NamedTuple[]
    for seed in seeds
        row = run_one(
            seed;
            nsire = nsire,
            ndam = ndam,
            noffspring = noffspring,
            records = records,
            iterations = iterations,
        )
        @printf(
            "seed=%d conv=%s G11=%.3f P11=%.3f t1=%.3f\n",
            row.seed, row.converged, row.G[1, 1], row.P[1, 1], row.t[1],
        )
        push!(rows, row)
    end
    print_aggregate(rows)
    return 0
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
