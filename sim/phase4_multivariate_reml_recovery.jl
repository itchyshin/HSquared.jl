using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in recovery harness for Phase 4 unstructured multivariate REML.

This script is deliberately outside `test/` so the package test suite remains
RNG-free. It simulates a repeated-record half-sib design with two correlated
traits, fits the unstructured multivariate REML estimator, and checks that the
estimated genetic and residual covariance matrices recover the generating
matrices within loose, version-robust bounds.

Run from the repository root:

    julia --project=. sim/phase4_multivariate_reml_recovery.jl

On interactive machines, prefer throttling Julia/BLAS/OpenMP threads and using
lower process priority:

    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 julia --project=. sim/phase4_multivariate_reml_recovery.jl

Optional arguments:

    --seed=N
    --seeds=N[,N...]
    --iterations=N
    --threshold-g=X
    --threshold-r=X
    --cold-start=true

Use `--seed` for a single historical-style run and `--seeds` for an explicit
seed list. The options are mutually exclusive. By default the optimizer is
warm-started at the true `G0`/`R0` (characterising sampling behaviour in the
basin around truth); `--cold-start=true` instead uses the fitter's
phenotypic-scale default start, testing whether the optimizer finds that basin
without help.
"""

struct MultivariateRecoveryConfig
    seed::Int
    nsire::Int
    ndam::Int
    noffspring::Int
    records_per_animal::Int
    iterations::Int
    threshold_g::Float64
    threshold_r::Float64
    cold_start::Bool
    g0::Matrix{Float64}
    r0::Matrix{Float64}
    cell::String
    gate_aggregate::Bool
    max_cond::Float64
end

function _parse_args(args)
    opts = Dict{String,String}()
    for arg in args
        startswith(arg, "--") || throw(ArgumentError("arguments must use --key=value form, got $arg"))
        keyval = split(arg[3:end], "=", limit = 2)
        length(keyval) == 2 || throw(ArgumentError("arguments must use --key=value form, got $arg"))
        opts[keyval[1]] = keyval[2]
    end

    haskey(opts, "seed") && haskey(opts, "seeds") &&
        throw(ArgumentError("use either --seed or --seeds, not both"))
    seeds = if haskey(opts, "seeds")
        parsed = Int[]
        for raw_seed in split(opts["seeds"], ",")
            seed_text = strip(raw_seed)
            isempty(seed_text) && throw(ArgumentError("--seeds must not contain empty entries"))
            push!(parsed, parse(Int, seed_text))
        end
        isempty(parsed) && throw(ArgumentError("--seeds must include at least one seed"))
        length(unique(parsed)) == length(parsed) ||
            throw(ArgumentError("--seeds must not contain duplicate entries"))
        parsed
    else
        [parse(Int, get(opts, "seed", "20260616"))]
    end
    iterations = parse(Int, get(opts, "iterations", "5000"))
    iterations > 0 || throw(ArgumentError("--iterations must be positive"))
    threshold_g = parse(Float64, get(opts, "threshold-g", "0.25"))
    threshold_r = parse(Float64, get(opts, "threshold-r", "0.20"))
    threshold_g > 0 || throw(ArgumentError("--threshold-g must be positive"))
    threshold_r > 0 || throw(ArgumentError("--threshold-r must be positive"))
    cold_raw = get(opts, "cold-start", "false")
    cold_start = cold_raw in ("true", "1", "")
    cold_start || cold_raw == "false" ||
        throw(ArgumentError("--cold-start takes no value or true/false, got $cold_raw"))
    # S2: DGP cell (defaults reproduce the legacy hardcoded cell) + design + gate mode,
    # so a SLURM array can sweep a pre-declared {r_g, h2-balance, size, records} factorial.
    nsire = parse(Int, get(opts, "nsire", "8"))
    ndam = parse(Int, get(opts, "ndam", "16"))
    noffspring = parse(Int, get(opts, "noffspring", "56"))
    records = parse(Int, get(opts, "records", "3"))
    g11 = parse(Float64, get(opts, "g11", "1.0"))
    g12 = parse(Float64, get(opts, "g12", "0.35"))
    g22 = parse(Float64, get(opts, "g22", "0.7"))
    r11 = parse(Float64, get(opts, "r11", "0.8"))
    r12 = parse(Float64, get(opts, "r12", "0.2"))
    r22 = parse(Float64, get(opts, "r22", "0.55"))
    g0 = [g11 g12; g12 g22]
    r0 = [r11 r12; r12 r22]
    cell = get(opts, "cell", "default")
    gate_raw = get(opts, "gate", "aggregate")
    gate_raw in ("aggregate", "per-seed") ||
        throw(ArgumentError("--gate must be aggregate or per-seed, got $gate_raw"))
    max_cond = parse(Float64, get(opts, "max-cond", "1.0e6"))
    return (seeds = seeds, nsire = nsire, ndam = ndam, noffspring = noffspring,
            records = records, iterations = iterations, threshold_g = threshold_g,
            threshold_r = threshold_r, cold_start = cold_start, g0 = g0, r0 = r0,
            cell = cell, gate_aggregate = (gate_raw == "aggregate"), max_cond = max_cond)
end

function _halfsib_pedigree(nsire, ndam, noffspring)
    sire_ids = ["s$(i)" for i in 1:nsire]
    dam_ids = ["d$(i)" for i in 1:ndam]
    offspring_ids = ["o$(i)" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, offspring_ids)
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

# Full-sib design: `npair` distinct sire×dam pairs, each producing
# `noffspring_per_pair` full-sib offspring (BOTH parents known). Higher relatedness
# than the half-sib design (shared sire AND dam → A = 0.5 within a family), so it is
# the EASIER identifiability regime — a pass closes the design owed item but is not a
# stress test (the 3-trait cell is the substantive test).
function _fullsib_pedigree(npair, noffspring_per_pair)
    sire_ids = ["s$(i)" for i in 1:npair]
    dam_ids = ["d$(i)" for i in 1:npair]
    noff = npair * noffspring_per_pair
    offspring_ids = ["o$(i)" for i in 1:noff]
    ids = vcat(sire_ids, dam_ids, offspring_ids)
    # offspring k belongs to family ((k-1) ÷ noffspring_per_pair) + 1
    sire = vcat(
        fill("0", 2 * npair),
        [sire_ids[((k - 1) ÷ noffspring_per_pair) + 1] for k in 1:noff],
    )
    dam = vcat(
        fill("0", 2 * npair),
        [dam_ids[((k - 1) ÷ noffspring_per_pair) + 1] for k in 1:noff],
    )
    return normalize_pedigree(ids, sire, dam)
end

function _simulate_repeated_records(config::MultivariateRecoveryConfig)
    rng = MersenneTwister(config.seed)
    ped = _halfsib_pedigree(config.nsire, config.ndam, config.noffspring)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    t = 2

    Gtrue = config.g0
    Rtrue = config.r0
    # S2: reject degenerate / near-singular DGP cells (the out-of-scope vacuous-pass trap,
    # Rose) — the dense A=inv(Ainv)+Cholesky simulation must stay well-conditioned.
    isposdef(Symmetric(Gtrue)) || throw(ArgumentError("G0 must be positive definite, got $Gtrue"))
    isposdef(Symmetric(Rtrue)) || throw(ArgumentError("R0 must be positive definite, got $Rtrue"))
    cond(Symmetric(Gtrue)) <= config.max_cond ||
        throw(ArgumentError("cond(G0)=$(round(cond(Symmetric(Gtrue)); digits=1)) exceeds --max-cond=$(config.max_cond) (near-singular cell is out of scope)"))
    LA = cholesky(Symmetric(A)).L
    LG = cholesky(Symmetric(Gtrue)).L
    LR = cholesky(Symmetric(Rtrue)).L

    U = LA * randn(rng, q, t) * transpose(LG)
    n = q * config.records_per_animal
    X = ones(n, 1)
    Z = zeros(n, q)
    Y = zeros(n, t)
    row = 1
    for animal in 1:q, _rep in 1:config.records_per_animal
        Z[row, animal] = 1.0
        Y[row, :] .= 2.0 .+ U[animal, :] .+
                     (randn(rng, 1, t) * transpose(LR))[1, :]
        row += 1
    end

    return Y, X, Z, Ainv, Gtrue, Rtrue, U
end

# Pearson correlation (manual, to keep the harness dependency-free).
function _pearson(a, b)
    ma = sum(a) / length(a)
    mb = sum(b) / length(b)
    num = sum((a .- ma) .* (b .- mb))
    den = sqrt(sum(abs2, a .- ma) * sum(abs2, b .- mb))
    return den == 0 ? 0.0 : num / den
end

function _run(config::MultivariateRecoveryConfig)
    Y, X, Z, Ainv, Gtrue, Rtrue, Utrue = _simulate_repeated_records(config)
    # Warm-start at truth (default) characterises sampling behaviour in the basin
    # around truth; cold-start (no `initial`) uses the fitter's phenotypic-scale
    # default and tests whether the optimizer FINDS that basin without help.
    fit = if config.cold_start
        fit_multivariate_reml(Y, X, Z, Ainv; iterations = config.iterations)
    else
        fit_multivariate_reml(Y, X, Z, Ainv;
            initial = (G0 = Gtrue, R0 = Rtrue), iterations = config.iterations)
    end
    rel_g = norm(fit.genetic_covariance - Gtrue) / norm(Gtrue)
    rel_r = norm(fit.residual_covariance - Rtrue) / norm(Rtrue)
    pass = fit.converged && rel_g <= config.threshold_g && rel_r <= config.threshold_r
    # EBV accuracy: correlation of the estimated breeding values with the true
    # simulated breeding values, per trait (animal order matches the pedigree).
    ebv = fit.breeding_values.values   # q × t
    ebv_accuracy = [_pearson(view(ebv, :, j), view(Utrue, :, j)) for j in 1:size(Utrue, 2)]
    return (
        seed = config.seed,
        observations = size(Y, 1),
        animals = size(Z, 2),
        traits = size(Y, 2),
        records_per_animal = config.records_per_animal,
        converged = fit.converged,
        iterations = fit.iterations,
        rel_g = rel_g,
        rel_r = rel_r,
        threshold_g = config.threshold_g,
        threshold_r = config.threshold_r,
        genetic_covariance = fit.genetic_covariance,
        residual_covariance = fit.residual_covariance,
        gtrue = Gtrue,
        rtrue = Rtrue,
        ebv_accuracy = ebv_accuracy,
        pass = pass,
    )
end

function _print_result(result)
    status = result.pass ? "PASS" : "FAIL"
    @printf("[%s] unstructured seed=%d observations=%d animals=%d traits=%d records_per_animal=%d\n",
        status, result.seed, result.observations, result.animals,
        result.traits, result.records_per_animal)
    @printf("  converged=%s iterations=%d\n", result.converged, result.iterations)
    @printf("  relative_error_G=%.6f threshold=%.3f\n", result.rel_g, result.threshold_g)
    @printf("  relative_error_R=%.6f threshold=%.3f\n", result.rel_r, result.threshold_r)
    println("  estimated_G =")
    show(stdout, "text/plain", round.(result.genetic_covariance; digits = 3))
    println()
    println("  estimated_R =")
    show(stdout, "text/plain", round.(result.residual_covariance; digits = 3))
    println("\n")
end

function _print_summary(results)
    pass_count = count(result -> result.pass, results)
    max_rel_g = maximum(result.rel_g for result in results)
    max_rel_r = maximum(result.rel_r for result in results)
    @printf("SUMMARY seeds=%d passed=%d max_relative_error_G=%.6f max_relative_error_R=%.6f\n",
        length(results), pass_count, max_rel_g, max_rel_r)
end

# Wilson score interval for a binomial proportion (z = 1.96, dependency-free).
function _wilson(k, n; z = 1.96)
    n == 0 && return (0.0, 0.0)
    p = k / n
    denom = 1 + z^2 / n
    center = (p + z^2 / (2n)) / denom
    half = z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / denom
    return (max(0.0, center - half), min(1.0, center + half))
end

# Across-seed Monte Carlo recovery report: per-parameter mean estimate, bias,
# Monte Carlo standard error (MCSE = sd / sqrt(m)), and whether the bias is within
# ±2·MCSE (i.e. consistent with an unbiased estimator at this seed count); per-trait
# EBV accuracy; convergence count; and a Wilson 95% CI on the pass proportion.
function _print_aggregate(results)
    m = length(results)
    m >= 2 || return missing
    within_count = 0
    params = (
        ("G[1,1]", r -> r.genetic_covariance[1, 1], r -> r.gtrue[1, 1]),
        ("G[1,2]", r -> r.genetic_covariance[1, 2], r -> r.gtrue[1, 2]),
        ("G[2,2]", r -> r.genetic_covariance[2, 2], r -> r.gtrue[2, 2]),
        ("R[1,1]", r -> r.residual_covariance[1, 1], r -> r.rtrue[1, 1]),
        ("R[1,2]", r -> r.residual_covariance[1, 2], r -> r.rtrue[1, 2]),
        ("R[2,2]", r -> r.residual_covariance[2, 2], r -> r.rtrue[2, 2]),
    )
    println("AGGREGATE Monte Carlo recovery (m = $m seeds)")
    println("  param    true     mean      bias     MCSE   |bias|<=2MCSE")
    for (name, getter, truthgetter) in params
        ests = [getter(r) for r in results]
        truth = truthgetter(results[1])
        mean_est = sum(ests) / m
        sd = sqrt(sum(abs2, ests .- mean_est) / (m - 1))
        mcse = sd / sqrt(m)
        bias = mean_est - truth
        within = abs(bias) <= 2 * mcse
        within && (within_count += 1)
        @printf("  %-7s %7.4f %8.4f %9.4f %8.4f   %s\n",
            name, truth, mean_est, bias, mcse, within ? "yes" : "NO")
    end
    nt = length(results[1].ebv_accuracy)
    for j in 1:nt
        accs = [r.ebv_accuracy[j] for r in results]
        mean_acc = sum(accs) / m
        sd_acc = sqrt(sum(abs2, accs .- mean_acc) / (m - 1))
        @printf("  EBV accuracy trait %d: mean=%.4f sd=%.4f (corr of EBV-hat with true BV)\n",
            j, mean_acc, sd_acc)
    end
    conv = count(r -> r.converged, results)
    passes = count(r -> r.pass, results)
    lo, hi = _wilson(passes, m)
    @printf("  converged=%d/%d  passed=%d/%d  pass-rate=%.3f  Wilson95%%=[%.3f, %.3f]\n",
        conv, m, passes, m, passes / m, lo, hi)
    return within_count == length(params)
end

function main(args = ARGS)
    p = _parse_args(args)
    @printf("START multivariate REML recovery cell=%s (%s)\n",
        p.cell, p.cold_start ? "COLD-START (default init)" : "warm-start at truth")
    @printf("CELL %s nsire=%d ndam=%d noffspring=%d records=%d G0=[%.4f %.4f; %.4f %.4f] R0=[%.4f %.4f; %.4f %.4f] seeds=%d\n",
        p.cell, p.nsire, p.ndam, p.noffspring, p.records,
        p.g0[1, 1], p.g0[1, 2], p.g0[2, 1], p.g0[2, 2],
        p.r0[1, 1], p.r0[1, 2], p.r0[2, 1], p.r0[2, 2], length(p.seeds))
    results = Any[]
    for seed in p.seeds
        result = _run(MultivariateRecoveryConfig(seed, p.nsire, p.ndam, p.noffspring,
            p.records, p.iterations, p.threshold_g, p.threshold_r, p.cold_start,
            p.g0, p.r0, p.cell, p.gate_aggregate, p.max_cond))
        _print_result(result)
        push!(results, result)
        flush(stdout)
    end
    _print_summary(results)
    agg = _print_aggregate(results)
    # S2: the AUTHORITATIVE gate is the aggregate bias/MCSE block (doc-33), NOT the
    # per-seed Frobenius pass (which trips exit(1) on a single noisy seed). Emit a
    # machine-readable GATE line for ingestion; exit reflects the chosen gate.
    per_seed_pass = all(result.pass for result in results)
    gate_pass = p.gate_aggregate ? (agg === missing ? per_seed_pass : agg) : per_seed_pass
    @printf("GATE cell=%s mode=%s aggregate_within_2mcse=%s per_seed_all_pass=%s gate_pass=%s seeds=%d\n",
        p.cell, p.gate_aggregate ? "aggregate" : "per-seed",
        agg === missing ? "na" : string(agg), string(per_seed_pass), string(gate_pass), length(p.seeds))
    gate_pass || exit(1)
    return nothing
end

# Run only when invoked as a script (`julia sim/phase4_..._recovery.jl ...`); an
# `include` (e.g. from the self-test) brings the helpers into scope without running.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
