using HSquared
using LinearAlgebra
using Printf
using Random

"""
C8 multivariate-REML recovery RE-SEED driver (500 seeds/cell).

DO NOT MUTATE the committed harness. This is a NEW driver that *reuses*
`sim/phase4_multivariate_reml_recovery.jl` by `include`-ing it (its `main` does NOT
run on include because of the `PROGRAM_FILE == @__FILE__` guard, so the DGP,
fitter call, thresholds, EBV accuracy, and covariance-parameter definitions stay
byte-identical to the committed C8 harness). It adds the things the pre-registered,
higher-rep recovery campaign needs and the committed harness lacks:

  1. A per-(cell, seed) results TSV (append + flush per seed) so the raw draws are
     banked, not only the printed aggregate. Each array task writes its OWN file,
     so the concurrent tasks never contend for one handle.
  2. `--resume=true`: skip seeds already present for this cell and recompute the
     aggregate over the union, so a timed-out array task resumes with no re-fitting.
     A DGP / fit-config / label mismatch against the existing TSV is a HARD ERROR,
     not a silent merge (the programme gotcha: changing cells/labels/records
     invalidates a resume). The guard checks design, records, cold_start, the
     iteration budget, thresholds, and G0/R0 — not only design + G0/R0.
  3. Exit-code honesty: the gate PASS/FAIL is DATA (printed on the GATE line and in
     the TSV), NOT the process exit code. This driver exits 0 iff the computation
     completed; it exits non-zero ONLY on a genuine error. The committed harness
     `exit(1)`s on gate-fail, which forces the sbatch to `|| true` and thereby hides
     real crashes (SLURM COMPLETED != Julia succeeded). Removing that conflation is
     what lets the sbatch do a REAL exit-code check.
  4. Convergence handling the frozen aggregate lacks. The committed `_print_aggregate`
     has NO convergence filter, so a non-converged (or clamped) fit pollutes the bias/
     MCSE. This driver (a) writes a per-seed `converged` column, (b) wraps each fit in
     a try/catch so one throwing seed neither aborts the 500-seed cell nor defeats
     resume (the failed seed is banked as a non-converged row so it is skipped on
     restart and counts against the convergence rate), and (c) reports the PRE-DECLARED
     campaign metric for the boundary cells: recovery bias CONDITIONAL ON CONVERGENCE
     (non-converged excluded) plus the per-cell convergence rate. The unfiltered
     frozen-harness aggregate is also printed for transparency.

Usage (one cell per SLURM array task):

    julia --project=. sim/phase4_v5_mv_recovery_reseed.jl \\
        --seeds=20270001,...,20270500 \\
        --g11=1.0 --g12=0.7948 --g22=0.7 --r11=0.8 --r12=0.2 --r22=0.55 \\
        --nsire=8 --ndam=16 --noffspring=56 --records=1 \\
        --cold-start=true --gate=aggregate --cell=rg_095_rec1 \\
        --out=sim/drac/results/w1_v5/reseed_rg_095_rec1.tsv --resume=true

All DGP/design/seed flags are parsed by the committed harness's `_parse_args`
(unknown flags such as --out/--resume are stored but ignored there); this driver
reads --out and --resume from the raw ARGS itself.
"""

include(joinpath(@__DIR__, "phase4_multivariate_reml_recovery.jl"))

# Schema (21 cols). NEW file + NEW dir, so there is no committed TSV to invalidate.
# `cold_start` and `max_iters` are added over the base draft so the resume guard can
# hard-error on a fit-config drift (records/cold_start/iteration-budget), not only a
# DGP drift. `iterations` is the REALIZED count (varies per seed); `max_iters` is the
# BUDGET (constant per cell) — the two are distinct and both are stored.
const RESEED_COLUMNS = [
    "cell", "seed", "design", "records", "cold_start", "max_iters",
    "traits", "animals", "observations", "converged", "iterations",
    "rel_g", "rel_r", "threshold_g", "threshold_r", "pass",
    "g_hat", "r_hat", "g_true", "r_true", "ebv_acc",
]

# Column-major flatten of a matrix (round-trips through reshape) or a vector, each
# entry at 10 significant figures — ample for the aggregate bias/MCSE (4 decimals).
# NaN/Inf placeholders from a thrown fit round-trip through @sprintf/parse cleanly.
_vecjoin(M::AbstractMatrix) = join((@sprintf("%.10g", x) for x in vec(Matrix(M))), ";")
_vecjoin(v::AbstractVector) = join((@sprintf("%.10g", x) for x in v), ";")

function _reseed_extract(args, key, default)
    prefix = "--$key="
    for a in args
        if startswith(a, prefix)
            return String(split(a, "="; limit = 2)[2])
        end
    end
    return default
end

function _design_label(p)
    return p.design == "fullsib" ?
        @sprintf("fullsib:%d:%d", p.npair, p.noffspring_per_pair) :
        @sprintf("halfsib:%d:%d:%d", p.nsire, p.ndam, p.noffspring)
end

# A synthetic result for a fit that THREW: same field names/shape as `_run` returns,
# with NaN estimates and converged=false. gtrue/rtrue are the (finite) TRUE matrices
# so the resume DGP-equality guard still passes for this banked row; g_hat/r_hat/EBV
# are NaN so the convergence-conditional and finite-only aggregates correctly drop it.
function _failed_result(seed, p)
    t = size(p.g0, 1)
    return (
        seed = seed,
        observations = 0,
        animals = 0,
        traits = t,
        records_per_animal = p.records,
        converged = false,
        iterations = 0,
        rel_g = NaN,
        rel_r = NaN,
        threshold_g = p.threshold_g,
        threshold_r = p.threshold_r,
        genetic_covariance = fill(NaN, t, t),
        residual_covariance = fill(NaN, t, t),
        gtrue = p.g0,
        rtrue = p.r0,
        ebv_accuracy = fill(NaN, t),
        pass = false,
    )
end

function _reseed_row(cell, design_label, cold_start, max_iters, result)
    return [
        cell,
        string(result.seed),
        design_label,
        string(result.records_per_animal),
        string(cold_start),
        string(max_iters),
        string(result.traits),
        string(result.animals),
        string(result.observations),
        string(result.converged),
        string(result.iterations),
        @sprintf("%.10g", result.rel_g),
        @sprintf("%.10g", result.rel_r),
        @sprintf("%.10g", result.threshold_g),
        @sprintf("%.10g", result.threshold_r),
        string(result.pass),
        _vecjoin(result.genetic_covariance),
        _vecjoin(result.residual_covariance),
        _vecjoin(result.gtrue),
        _vecjoin(result.rtrue),
        _vecjoin(result.ebv_accuracy),
    ]
end

function _parse_mat(s, t)
    vals = parse.(Float64, split(s, ';'))
    length(vals) == t * t ||
        error("expected $(t * t) matrix entries, got $(length(vals)) in `$s`")
    return reshape(vals, t, t)
end

# Read prior rows for THIS cell only, keyed by seed, and reconstruct the full result
# NamedTuple the reporters read. Any header / column-count / label / DGP-truth / fit-
# config mismatch is a HARD ERROR so a stale or re-configured TSV can never be silently
# merged. The base draft checked only design + G0/R0; this also checks records,
# cold_start, the iteration budget, and thresholds — the knobs that (respectively)
# change the estimand, the fit path, the convergence set, and the pass/Wilson report.
function _read_reseed_tsv(path, cell, p, design_label)
    got = Dict{Int,Any}()
    (isfile(path) && filesize(path) > 0) || return got
    open(path, "r") do io
        header = readline(io)
        header == join(RESEED_COLUMNS, '\t') ||
            error("resume: TSV header does not match current schema: $path")
        for line in eachline(io)
            isempty(strip(line)) && continue
            parts = split(line, '\t')
            length(parts) == length(RESEED_COLUMNS) ||
                error("resume: malformed row (want $(length(RESEED_COLUMNS)) cols): $line")
            parts[1] == cell || continue
            parts[3] == design_label ||
                error("resume: design mismatch for cell=$cell: TSV=$(parts[3]) current=$design_label — use a fresh --out")
            parse(Int, parts[4]) == p.records ||
                error("resume: records mismatch for cell=$cell: TSV=$(parts[4]) current=$(p.records) — a same-named cell with different records CANNOT merge; use a fresh --out")
            parse(Bool, parts[5]) == p.cold_start ||
                error("resume: cold_start mismatch for cell=$cell: TSV=$(parts[5]) current=$(p.cold_start) — use a fresh --out")
            parse(Int, parts[6]) == p.iterations ||
                error("resume: iteration-budget mismatch for cell=$cell: TSV=$(parts[6]) current=$(p.iterations) — use a fresh --out")
            t = parse(Int, parts[7])
            t == size(p.g0, 1) ||
                error("resume: trait-count mismatch for cell=$cell: TSV=$t current=$(size(p.g0, 1)) — use a fresh --out")
            (parse(Float64, parts[14]) ≈ p.threshold_g && parse(Float64, parts[15]) ≈ p.threshold_r) ||
                error("resume: threshold mismatch for cell=$cell — TSV=($(parts[14]),$(parts[15])) current=($(p.threshold_g),$(p.threshold_r)); use a fresh --out")
            gtrue = _parse_mat(parts[19], t)
            rtrue = _parse_mat(parts[20], t)
            (gtrue ≈ p.g0 && rtrue ≈ p.r0) ||
                error("resume: DGP truth mismatch for cell=$cell — TSV G0/R0 differ from current --gNN/--rNN; use a fresh --out")
            seed = parse(Int, parts[2])
            got[seed] = (
                seed = seed,
                observations = parse(Int, parts[9]),
                animals = parse(Int, parts[8]),
                traits = t,
                records_per_animal = parse(Int, parts[4]),
                converged = parse(Bool, parts[10]),
                iterations = parse(Int, parts[11]),
                rel_g = parse(Float64, parts[12]),
                rel_r = parse(Float64, parts[13]),
                threshold_g = parse(Float64, parts[14]),
                threshold_r = parse(Float64, parts[15]),
                genetic_covariance = _parse_mat(parts[17], t),
                residual_covariance = _parse_mat(parts[18], t),
                gtrue = gtrue,
                rtrue = rtrue,
                ebv_accuracy = parse.(Float64, split(parts[21], ';')),
                pass = parse(Bool, parts[16]),
            )
        end
    end
    return got
end

function _prepare_reseed_tsv(path; resume)
    mkpath(dirname(path))
    if !resume || !isfile(path) || filesize(path) == 0
        open(path, "w") do io
            println(io, join(RESEED_COLUMNS, '\t'))
        end
    end
    return path
end

function _append_reseed_row!(path, row)
    open(path, "a") do io
        println(io, join(row, '\t'))
        flush(io)
    end
    return path
end

_finite_estimates(r) =
    all(isfinite, r.genetic_covariance) && all(isfinite, r.residual_covariance)

# Convergence-conditional Monte Carlo recovery — the PRE-DECLARED campaign metric for
# the boundary cells (report bias EXCLUDING non-converged; report the convergence rate).
# The per-parameter |bias| <= 2*MCSE definition is REUSED verbatim from the committed
# harness (`_covariance_params`, `_wilson` are in scope via include); only the sample
# set differs — converged, finite-estimate seeds. Returns the aggregate gate (all
# parameters within band) or `missing` when fewer than 2 converged seeds exist.
function _print_aggregate_converged(results)
    m_all = length(results)
    conv = [r for r in results if r.converged && _finite_estimates(r)]
    m = length(conv)
    n_threw = count(r -> !_finite_estimates(r), results)
    lo, hi = _wilson(m, m_all)
    @printf("CONVERGENCE cell converged=%d/%d rate=%.4f Wilson95%%=[%.4f, %.4f] threw=%d\n",
        m, m_all, m_all == 0 ? 0.0 : m / m_all, lo, hi, n_threw)
    if m < 2
        println("CONV-AGGREGATE: fewer than 2 converged seeds — bias/MCSE not computed for this cell.")
        return missing
    end
    within_count = 0
    params = _covariance_params(length(conv[1].ebv_accuracy))
    println("CONV-AGGREGATE Monte Carlo recovery, CONDITIONAL ON CONVERGENCE (m = $m of $m_all seeds)")
    println("  param    true     mean      bias     MCSE   |bias|<=2MCSE")
    for (name, getter, truthgetter) in params
        ests = [getter(r) for r in conv]
        truth = truthgetter(conv[1])
        mean_est = sum(ests) / m
        sd = sqrt(sum(abs2, ests .- mean_est) / (m - 1))
        mcse = sd / sqrt(m)
        bias = mean_est - truth
        within = abs(bias) <= 2 * mcse
        within && (within_count += 1)
        @printf("  %-7s %7.4f %8.4f %9.4f %8.4f   %s\n",
            name, truth, mean_est, bias, mcse, within ? "yes" : "NO")
    end
    nt = length(conv[1].ebv_accuracy)
    for j in 1:nt
        accs = [r.ebv_accuracy[j] for r in conv]
        mean_acc = sum(accs) / m
        sd_acc = sqrt(sum(abs2, accs .- mean_acc) / (m - 1))
        @printf("  EBV accuracy trait %d (converged): mean=%.4f sd=%.4f\n", j, mean_acc, sd_acc)
    end
    return within_count == length(params)
end

function reseed_main(args = ARGS)
    p = _parse_args(args)
    out = _reseed_extract(args, "out", "")
    isempty(out) && error("--out=<path> is required (per-cell results TSV)")
    resume = _reseed_extract(args, "resume", "true") in ("true", "1", "")
    design_label = _design_label(p)

    @printf("START reseed cell=%s out=%s resume=%s seeds=%d (%s, gate=%s)\n",
        p.cell, out, resume, length(p.seeds),
        p.cold_start ? "cold-start" : "warm-start",
        p.gate_aggregate ? "aggregate" : "per-seed")
    println("  G0 = ", round.(p.g0; digits = 4), "  R0 = ", round.(p.r0; digits = 4),
        "  design = ", design_label, "  records = ", p.records,
        "  max_iters = ", p.iterations)
    flush(stdout)

    existing = resume ? _read_reseed_tsv(out, p.cell, p, design_label) : Dict{Int,Any}()
    _prepare_reseed_tsv(out; resume = resume)
    @printf("  resume: %d of %d declared seeds already present in TSV\n",
        count(s -> haskey(existing, s), p.seeds), length(p.seeds))
    flush(stdout)

    results = Any[]
    n_new = 0
    n_threw = 0
    for seed in p.seeds
        if haskey(existing, seed)
            push!(results, existing[seed])
            continue
        end
        config = MultivariateRecoveryConfig(seed, p.nsire, p.ndam, p.noffspring,
            p.records, p.iterations, p.threshold_g, p.threshold_r, p.cold_start,
            p.g0, p.r0, p.cell, p.gate_aggregate, p.max_cond,
            p.design, p.npair, p.noffspring_per_pair)
        # Per-seed try/catch: a single throwing fit (most likely at the extreme-r_g,
        # single-record boundary) is banked as a non-converged row, not allowed to abort
        # the cell. Banking it means resume skips it AND the sbatch row-count check still
        # reaches NSEEDS; it is excluded from the convergence-conditional aggregate and
        # counts against the convergence rate.
        result = try
            _run(config)
        catch err
            n_threw += 1
            @printf("  SEED-ERROR cell=%s seed=%d: %s\n",
                p.cell, seed, sprint(showerror, err))
            flush(stdout)
            _failed_result(seed, p)
        end
        _append_reseed_row!(out, _reseed_row(p.cell, design_label, p.cold_start, p.iterations, result))
        push!(results, result)
        n_new += 1
        if n_new % 25 == 0
            @printf("  ... %d new seeds fitted (cell=%s, threw=%d)\n", n_new, p.cell, n_threw)
            flush(stdout)
        end
    end

    # UNFILTERED view (frozen-harness metric): computed over seeds that produced a
    # finite fit (a thrown seed has NaN estimates and is dropped so it cannot poison the
    # mean). Includes NON-converged fits — that is exactly what the convergence filter
    # below removes, and printing both makes the filter's effect auditable.
    finite = [r for r in results if _finite_estimates(r)]
    println("---- UNFILTERED (frozen-harness metric; includes non-converged fits, drops thrown seeds) ----")
    isempty(finite) || _print_summary(finite)
    length(finite) >= 2 && _print_aggregate(finite)

    # CONVERGENCE-CONDITIONAL view — the pre-declared gate for this campaign.
    println("---- CONVERGENCE-CONDITIONAL (pre-declared campaign gate; boundary cells characterize, never promote) ----")
    agg_conv = _print_aggregate_converged(results)

    n_conv = count(r -> r.converged && _finite_estimates(r), results)
    per_seed_pass = all(r.pass for r in results)
    gate_str = agg_conv === missing ? "na" : string(agg_conv)
    @printf("GATE cell=%s mode=aggregate-conditional-on-convergence within_2mcse=%s per_seed_all_pass=%s converged=%d/%d gate_pass=%s seeds=%d\n",
        p.cell, gate_str, string(per_seed_pass),
        n_conv, length(results), gate_str, length(results))
    # The exit code is INDEPENDENT of the gate: gate result lives on the GATE line and
    # in the TSV. Non-zero exit => genuine failure, so the sbatch can trust it. A gate
    # FAIL (or a boundary cell that under-recovers) is DATA, not a process error.
    @printf("RUN_COMPLETE cell=%s out=%s seeds_expected=%d seeds_in_result=%d new_fits=%d threw=%d converged=%d gate_pass=%s\n",
        p.cell, out, length(p.seeds), length(results), n_new, n_threw, n_conv, gate_str)
    flush(stdout)
    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    reseed_main()
end
