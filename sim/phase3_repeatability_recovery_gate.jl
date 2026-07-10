using HSquared
using LinearAlgebra
using Printf
using Random
using Statistics

# ============================================================================
# Pre-declared repeatability (permanent-environment) recovery SCREEN — 48 seeds.
#
# Estimator: `fit_repeatability_reml` (V3-REPEAT-REML, partial; src/likelihood.jl).
# Model:  y_ij = mu + a_i + pe_i + e_ij  with REPEATED records per individual,
#           a  ~ N(0, sigma_a2 * A_ped)   (additive, pedigree-structured)
#           pe ~ N(0, sigma_pe2 * I)      (permanent environment, per individual)
#           e  ~ N(0, sigma_e2 * I)       (residual, per record).
#
# GOVERNING PRE-REGISTRATION: R-repo docs/design/34-interval-recovery-pre-registration.md
# (committed 2026-07-10, honesty anchor; this campaign is named PENDING in §10, and is a
# SCREENING-tier recovery gate under §5 + §11).
#
# WHAT IS GATED (and what is NOT) — the load-bearing honesty stance (doc-34 §10):
#   * GATED: the IDENTIFIABLE repeatability summary  t = (sigma_a2 + sigma_pe2)/total.
#     Recovery gate (doc-34 §5): across CONVERGED seeds, bias = mean(t_hat - t_true),
#     MC-SE = sd(t_hat)/sqrt(m); the cell PASSES iff  |bias(t)| <= 2*MC-SE.
#   * CHARACTERIZED-ONLY (NOT gated at any validation scale): the sigma_a2-vs-sigma_pe2
#     SPLIT and h2 = sigma_a2/total. The split is weakly identified even at large n
#     (doc-34 §10, from the 2026-06-18 identifiability finding); it is pre-declared
#     experimental-only. This driver REPORTS its bias descriptively and does NOT let it
#     enter the gate. A clean 48-seed screen does NOT overturn that stance.
#
# SCREENING TIER (doc-34 §11): 48 seeds establish DIRECTION only. A clean screen
# schedules a ~2000-rep CONFIRM tier; it can NEVER set a claim level, move
# public_covered_count, or promote partial->covered on its own. A public move needs the
# 2000-rep confirm + a real Rose audit + the maintainer's per-move G10 (non-delegable).
#
# COVERED-ELIGIBILITY (doc-34 §5): a passing INTERIOR cell -> covered-eligible (subject to
# the confirm tier above); a failing cell -> banked-negative (recorded, reusable). R9: a
# failure inside an already-covered scope is STOP-and-ask, not a banked negative. This
# estimator is `partial` (no covered scope yet), so no cell here is under R9.
#
# CELLS (see the sbatch table): a well-powered INTERIOR cell (gated), a records-per-
# individual IDENTIFIABILITY LADDER (pe — and therefore t — is UNIDENTIFIED at 1 record/
# ind and becomes identified at >=2; the ladder is expected to show t recoverable at
# records>=2 while the a/pe SPLIT stays weak), a reduced-n_ind rung (the split degrades
# with fewer pedigree contrasts while t holds), and a sigma_pe2 = 0 NULL cell (t reduces
# to h2). The records=1 rung is a CHARACTERIZATION boundary (t not point-identified there),
# tagged scope=boundary_rec1: its "fail" is the expected identifiability floor, never a
# claim-killer and never promoting (doc-34 §8 discipline).
#
# ENGINEERING (doc-34 §5, §12; the C8 re-seed gotchas):
#   * NEW driver + NEW per-cell TSV — never mutate a committed harness/TSV.
#   * Aggregate CONDITIONAL ON CONVERGENCE; report the per-cell convergence rate.
#   * INTERPRETABILITY FLOOR (doc-34 §2): a cell whose convergence rate < 0.9 is
#     NON-INTERPRETABLE — the gate is NOT evaluable and it can NEVER emit an eligible
#     (COVERED-ELIGIBLE) verdict, no matter where the bias lands (matches supplied-K).
#   * Per-seed try/catch: one throwing seed is banked as a non-converged row, never
#     aborts the cell, and is skipped on resume.
#   * The gate PASS/FAIL is DATA (GATE line + TSV), NOT the process exit code. This driver
#     exits 0 iff the computation completed; a non-zero exit is a GENUINE crash so the
#     sbatch can trust it (SLURM COMPLETED != Julia succeeded).
#
# WHY THIS FILE DOES NOT `include()` A COMMITTED PHASE-3 HARNESS: the closest committed
# harnesses (sim/phase3_two_effect_bias_mcse.jl, sim/phase3_two_effect_recovery.jl) end
# in a BARE `main()` with NO `if abspath(PROGRAM_FILE) == @__FILE__` guard, so `include`-ing
# either would EXECUTE its own 48-seed run on load. There is no committed repeatability
# harness to reuse (the n=70 one-off was never committed, to keep the suite RNG-free). This
# driver therefore depends on the committed ENGINE read-only — `HSquared.fit_repeatability_reml`,
# whose interface was confirmed by reading src/likelihood.jl — and reproduces the tiny
# shared `_halfsib_pedigree` helper verbatim, exactly as every phase-3 harness already does.
#
# One same-estimand comparator (out of lane, run separately by the R lane): sommer
# `animal + ide(id)` on a matched dataset.
#
# Usage (one cell per SLURM array task; see sim/drac/phase3_repeatability_gate.sbatch):
#   env OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase3_repeatability_recovery_gate.jl \
#     --cell=wellpowered --scope=interior \
#     --nsire=20 --ndam=40 --noffspring=800 --records=4 \
#     --sigma-a2=1.0 --sigma-pe2=0.6 --sigma-e2=1.5 --mu=2.0 \
#     --seeds=20265000,...,20265047 \
#     --out=sim/drac/results/rr_repeat/rr_wellpowered.tsv --resume=true
# ============================================================================

# Per-(cell, seed) schema. NEW file + NEW dir => there is no committed TSV to invalidate.
# Design + truth are stored on every row so `--resume` can HARD-ERROR on a config drift
# (a same-named cell run with different design/truth CANNOT silently merge).
const RR_COLUMNS = [
    "cell", "seed", "scope", "nsire", "ndam", "noffspring", "records", "mu",
    "animals", "observations", "converged",
    "sigma_a2", "sigma_pe2", "sigma_e2", "t", "h2",
    "sigma_a2_true", "sigma_pe2_true", "sigma_e2_true", "t_true", "h2_true",
]

# Interpretability floor (doc-34 §2): a cell whose CONVERGENCE RATE falls below this is
# NON-INTERPRETABLE — the gate is NOT evaluable and the cell can NEVER emit an eligible
# (COVERED-ELIGIBLE) verdict, regardless of where the bias lands. Matches the supplied-K
# screen; the 48-seed run is DIRECTION-only either way (§11).
const MIN_CONV_RATE = 0.9

# Reproduced verbatim from the committed phase-3 harnesses (each keeps its own copy).
function _halfsib_pedigree(nsire, ndam, noffspring)
    sire_ids = ["s$i" for i in 1:nsire]
    dam_ids = ["d$i" for i in 1:ndam]
    off_ids = ["o$i" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(fill("0", nsire + ndam),
                [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring])
    dam = vcat(fill("0", nsire + ndam),
               [dam_ids[((i - 1) % ndam) + 1] for i in 1:noffspring])
    return normalize_pedigree(ids, sire, dam)
end

# ---- arg parsing -----------------------------------------------------------
function _extract(args, key, default)
    prefix = "--$key="
    for a in args
        startswith(a, prefix) && return String(split(a, "="; limit = 2)[2])
    end
    return default
end

struct RRParams
    cell::String
    scope::String
    nsire::Int
    ndam::Int
    noffspring::Int
    records::Int
    sigma_a2::Float64
    sigma_pe2::Float64
    sigma_e2::Float64
    mu::Float64
    seeds::Vector{Int}
    out::String
    resume::Bool
end

function _parse_params(args)
    seeds_raw = _extract(args, "seeds", "")
    isempty(seeds_raw) && error("--seeds=<comma-separated ints> is required")
    seeds = parse.(Int, split(seeds_raw, ","))
    out = _extract(args, "out", "")
    isempty(out) && error("--out=<path> is required (per-cell results TSV)")
    return RRParams(
        _extract(args, "cell", "cell"),
        _extract(args, "scope", "interior"),
        parse(Int, _extract(args, "nsire", "20")),
        parse(Int, _extract(args, "ndam", "40")),
        parse(Int, _extract(args, "noffspring", "800")),
        parse(Int, _extract(args, "records", "4")),
        parse(Float64, _extract(args, "sigma-a2", "1.0")),
        parse(Float64, _extract(args, "sigma-pe2", "0.6")),
        parse(Float64, _extract(args, "sigma-e2", "1.5")),
        parse(Float64, _extract(args, "mu", "2.0")),
        seeds,
        out,
        _extract(args, "resume", "true") in ("true", "1", ""),
    )
end

_truth(p) = begin
    total = p.sigma_a2 + p.sigma_pe2 + p.sigma_e2
    (sigma_a2 = p.sigma_a2, sigma_pe2 = p.sigma_pe2, sigma_e2 = p.sigma_e2,
     t = (p.sigma_a2 + p.sigma_pe2) / total, h2 = p.sigma_a2 / total)
end

# ---- one seed: simulate repeated records, fit REML -------------------------
function _fit_seed(p::RRParams, seed::Int)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(p.nsire, p.ndam, p.noffspring)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    LA = cholesky(Symmetric(A)).L
    # Correlated breeding values for ALL pedigree rows (parents included, so the
    # additive covariance A_ij is realized among the recorded half-sib offspring).
    a_full = (LA * randn(rng, q)) .* sqrt(p.sigma_a2)

    idpos = Dict(id => i for (i, id) in enumerate(ped.ids))
    off_rows = [idpos["o$i"] for i in 1:p.noffspring]  # only offspring are recorded

    n = p.noffspring * p.records
    y = Vector{Float64}(undef, n)
    Zrows = Vector{Int}(undef, n)   # record -> pedigree row of its animal
    r = 0
    for oi in 1:p.noffspring
        arow = off_rows[oi]
        # ONE permanent-environment draw per individual (0 when sigma_pe2 == 0, the
        # NULL cell); repeated records SHARE it, which is what separates pe from e.
        pe = sqrt(p.sigma_pe2) * randn(rng)
        for _ in 1:p.records
            r += 1
            Zrows[r] = arow
            y[r] = p.mu + a_full[arow] + pe + sqrt(p.sigma_e2) * randn(rng)
        end
    end

    X = ones(n, 1)
    Z = zeros(n, q)
    @inbounds for i in 1:n
        Z[i, Zrows[i]] = 1.0
    end

    # Cold start (1,1,1) — NOT the truth (1.0, 0.6, 1.5).
    fit = HSquared.fit_repeatability_reml(y, X, Z, Ainv;
        initial = (sigma_a2 = 1.0, sigma_pe2 = 1.0, sigma_e2 = 1.0),
        iterations = 200)
    vc = fit.variance_components
    return (seed = seed, animals = q, observations = n, converged = fit.converged,
        sigma_a2 = vc.sigma_a2, sigma_pe2 = vc.sigma_pe2, sigma_e2 = vc.sigma_e2,
        t = fit.repeatability, h2 = fit.heritability)
end

# A synthetic row for a seed whose fit THREW: converged=false, NaN estimates, but the
# design/truth fields are the (finite) real ones so the resume equality-guard still
# passes for this banked row and the convergence-conditional aggregate drops it.
function _failed_seed(p::RRParams, seed::Int)
    q = p.nsire + p.ndam + p.noffspring
    return (seed = seed, animals = q, observations = p.noffspring * p.records,
        converged = false, sigma_a2 = NaN, sigma_pe2 = NaN, sigma_e2 = NaN,
        t = NaN, h2 = NaN)
end

# ---- TSV I/O + resume ------------------------------------------------------
function _row(p::RRParams, tr, res)
    return [
        p.cell, string(res.seed), p.scope,
        string(p.nsire), string(p.ndam), string(p.noffspring),
        string(p.records), @sprintf("%.10g", p.mu),
        string(res.animals), string(res.observations), string(res.converged),
        @sprintf("%.10g", res.sigma_a2), @sprintf("%.10g", res.sigma_pe2),
        @sprintf("%.10g", res.sigma_e2), @sprintf("%.10g", res.t), @sprintf("%.10g", res.h2),
        @sprintf("%.10g", tr.sigma_a2), @sprintf("%.10g", tr.sigma_pe2),
        @sprintf("%.10g", tr.sigma_e2), @sprintf("%.10g", tr.t), @sprintf("%.10g", tr.h2),
    ]
end

function _prepare_tsv(path; resume)
    mkpath(dirname(path))
    if !resume || !isfile(path) || filesize(path) == 0
        open(io -> println(io, join(RR_COLUMNS, '\t')), path, "w")
    end
    return path
end

function _append_row!(path, row)
    open(path, "a") do io
        println(io, join(row, '\t'))
        flush(io)
    end
    return path
end

# Read prior rows for THIS cell only, keyed by seed. A header / column-count / design /
# truth mismatch is a HARD ERROR (a stale or re-configured TSV can never silently merge).
function _read_tsv(path, p::RRParams, tr)
    got = Dict{Int,Any}()
    (isfile(path) && filesize(path) > 0) || return got
    open(path, "r") do io
        header = readline(io)
        header == join(RR_COLUMNS, '\t') ||
            error("resume: TSV header does not match current schema: $path")
        for line in eachline(io)
            isempty(strip(line)) && continue
            parts = split(line, '\t')
            length(parts) == length(RR_COLUMNS) ||
                error("resume: malformed row (want $(length(RR_COLUMNS)) cols): $line")
            parts[1] == p.cell || continue
            parts[3] == p.scope ||
                error("resume: scope mismatch cell=$(p.cell): TSV=$(parts[3]) current=$(p.scope) — use a fresh --out")
            (parse(Int, parts[4]) == p.nsire && parse(Int, parts[5]) == p.ndam &&
             parse(Int, parts[6]) == p.noffspring && parse(Int, parts[7]) == p.records) ||
                error("resume: design mismatch cell=$(p.cell) — TSV nsire/ndam/noff/records=($(parts[4]),$(parts[5]),$(parts[6]),$(parts[7])) current=($(p.nsire),$(p.ndam),$(p.noffspring),$(p.records)); use a fresh --out")
            parse(Float64, parts[8]) ≈ p.mu ||
                error("resume: mu mismatch cell=$(p.cell) — TSV mu=$(parts[8]) current=$(p.mu); use a fresh --out")
            (parse(Float64, parts[17]) ≈ tr.sigma_a2 && parse(Float64, parts[18]) ≈ tr.sigma_pe2 &&
             parse(Float64, parts[19]) ≈ tr.sigma_e2) ||
                error("resume: DGP truth mismatch cell=$(p.cell) — TSV differs from current --sigma-*; use a fresh --out")
            seed = parse(Int, parts[2])
            got[seed] = (seed = seed, animals = parse(Int, parts[9]),
                observations = parse(Int, parts[10]), converged = parse(Bool, parts[11]),
                sigma_a2 = parse(Float64, parts[12]), sigma_pe2 = parse(Float64, parts[13]),
                sigma_e2 = parse(Float64, parts[14]), t = parse(Float64, parts[15]),
                h2 = parse(Float64, parts[16]))
        end
    end
    return got
end

# ---- aggregate + gate (CONDITIONAL ON CONVERGENCE) -------------------------
_round5(x) = isfinite(x) ? round(x, digits = 5) : x

function _aggregate(results, tr, p::RRParams)
    m_all = length(results)
    conv = [r for r in results if r.converged && isfinite(r.t)]
    m = length(conv)
    n_threw = count(r -> !isfinite(r.t), results)
    rate = m_all == 0 ? 0.0 : m / m_all
    @printf("CONVERGENCE cell=%s scope=%s converged=%d/%d rate=%.4f threw=%d\n",
        p.cell, p.scope, m, m_all, rate, n_threw)

    stat(vals, truth) = begin
        mn = mean(vals); b = mn - truth; se = std(vals) / sqrt(length(vals))
        (mean = mn, bias = b, mcse = se, ratio = abs(b) / max(se, eps()))
    end

    # INTERPRETABILITY FLOOR (doc-34 §2): below a 0.9 convergence rate (or with <2 converged
    # seeds, where MC-SE is not computable) the cell is NON-INTERPRETABLE — the gate is NOT
    # evaluable and it can NEVER emit an eligible (COVERED-ELIGIBLE) verdict, whatever the bias.
    interpretable = m >= 2 && rate >= MIN_CONV_RATE
    if !interpretable
        reason = m < 2 ?
            "fewer than 2 converged seeds — bias/MC-SE not computable" :
            @sprintf("convergence rate %.4f < interpretability floor %.2f", rate, MIN_CONV_RATE)
        println("NON-INTERPRETABLE cell=$(p.cell) scope=$(p.scope): $(reason) — gate NOT evaluable; a cell below the floor can never emit an eligible (COVERED-ELIGIBLE) verdict (doc-34 §2).")
        @printf("GATE cell=%s scope=%s estimand=t gate_pass=na evaluable=false interpretable=false conv_rate=%.4f floor=%.2f converged=%d/%d screening_only=true\n",
            p.cell, p.scope, rate, MIN_CONV_RATE, m, m_all)
        return (gate_pass = false, evaluable = false, interpretable = false, rate = rate,
            m = m, m_all = m_all,
            t = missing, ca = missing, cpe = missing, ce = missing, ch2 = missing)
    end

    # GATED estimand — the identifiable repeatability t.
    t = stat([r.t for r in conv], tr.t)
    t_within = abs(t.bias) <= 2 * t.mcse
    println("---- GATED (doc-34 §5: cell passes iff |bias| <= 2*MC-SE) ----")
    @printf("  %-9s (GATED)             mean=%.4f truth=%.4f bias=%+.4f MC-SE=%.4f |bias|/MC-SE=%.2f  %s\n",
        "t", t.mean, tr.t, t.bias, t.mcse, t.ratio, t_within ? "within" : "OUTSIDE")

    # CHARACTERIZED-ONLY — reported, NEVER gated (doc-34 §10 pre-commitment).
    ca = stat([r.sigma_a2 for r in conv], tr.sigma_a2)
    cpe = stat([r.sigma_pe2 for r in conv], tr.sigma_pe2)
    ce = stat([r.sigma_e2 for r in conv], tr.sigma_e2)
    ch2 = stat([r.h2 for r in conv], tr.h2)
    println("---- CHARACTERIZED-ONLY (split + h2 are experimental-only; NOT gated at any scale) ----")
    for (name, s, truth) in (("sigma_a2", ca, tr.sigma_a2), ("sigma_pe2", cpe, tr.sigma_pe2),
                             ("sigma_e2", ce, tr.sigma_e2), ("h2", ch2, tr.h2))
        @printf("  %-9s (characterized-only) mean=%.4f truth=%.4f bias=%+.4f MC-SE=%.4f |bias|/MC-SE=%.2f\n",
            name, s.mean, truth, s.bias, s.mcse, s.ratio)
    end

    # ONLY t gates (doc-34 §5 with a single pre-declared gated parameter).
    gate_pass = t_within
    scope_note = p.scope == "boundary_rec1" ?
        "  (boundary_rec1: pe — and thus t — is not point-identified at 1 record/ind; a 'fail' here is the expected identifiability FLOOR, characterization not promotion)" :
        (p.scope == "null" ? "  (null cell: sigma_pe2=0 truth; t reduces to h2)" :
         (p.scope == "ladder" ? "  (ladder rung: characterizes the identifiability schedule; interior only if records>=2)" : ""))
    @printf("GATE cell=%s scope=%s estimand=t gate_pass=%s evaluable=true interpretable=true conv_rate=%.4f bias=%+.5f mcse=%.5f within_2mcse=%s converged=%d/%d screening_only=true%s\n",
        p.cell, p.scope, string(gate_pass), rate, t.bias, t.mcse, string(t_within), m, m_all, scope_note)

    return (gate_pass = gate_pass, evaluable = true, interpretable = true, rate = rate,
        m = m, m_all = m_all,
        t = t, ca = ca, cpe = cpe, ce = ce, ch2 = ch2)
end

function _gate_json(p, agg)
    if !agg.evaluable
        return "{\"cell\":\"$(p.cell)\",\"scope\":\"$(p.scope)\",\"gate_pass\":\"na\",\"evaluable\":false," *
            "\"interpretable\":$(agg.interpretable),\"conv_rate\":$(_round5(agg.rate)),\"conv_floor\":$(MIN_CONV_RATE)," *
            "\"converged\":$(agg.m),\"seeds\":$(agg.m_all),\"screening_only\":true}"
    end
    pj(s) = "{\"bias\":$(_round5(s.bias)),\"mcse\":$(_round5(s.mcse)),\"mean\":$(_round5(s.mean))}"
    return "{\"cell\":\"$(p.cell)\",\"scope\":\"$(p.scope)\",\"gate_pass\":$(agg.gate_pass)," *
        "\"evaluable\":true,\"interpretable\":true,\"conv_rate\":$(_round5(agg.rate)),\"conv_floor\":$(MIN_CONV_RATE)," *
        "\"converged\":$(agg.m),\"seeds\":$(agg.m_all),\"screening_only\":true," *
        "\"gated\":{\"t\":$(pj(agg.t))}," *
        "\"characterized_only\":{\"sigma_a2\":$(pj(agg.ca)),\"sigma_pe2\":$(pj(agg.cpe))," *
        "\"sigma_e2\":$(pj(agg.ce)),\"h2\":$(pj(agg.ch2))}}"
end

# ---- main (ONE cell per invocation) ----------------------------------------
function rr_main(args = ARGS)
    p = _parse_params(args)
    tr = _truth(p)

    @printf("START repeatability-screen cell=%s scope=%s out=%s resume=%s seeds=%d\n",
        p.cell, p.scope, p.out, p.resume, length(p.seeds))
    @printf("  DGP: half-sib %d/%d/%d, %d record(s)/offspring, n=%d records; truth (sigma_a2,sigma_pe2,sigma_e2)=(%.3f,%.3f,%.3f), mu=%.2f\n",
        p.nsire, p.ndam, p.noffspring, p.records, p.noffspring * p.records,
        p.sigma_a2, p.sigma_pe2, p.sigma_e2, p.mu)
    @printf("  GATED: t_true=%.4f (identifiable summary). CHARACTERIZED-ONLY: h2_true=%.4f + the sigma_a2/sigma_pe2 split.\n",
        tr.t, tr.h2)
    flush(stdout)

    existing = p.resume ? _read_tsv(p.out, p, tr) : Dict{Int,Any}()
    _prepare_tsv(p.out; resume = p.resume)
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
        # Per-seed try/catch: a single throwing fit (most likely at the records=1 /
        # sigma_pe2=0 identifiability boundary) is banked as a non-converged row, never
        # aborts the cell. Banking it means resume skips it AND the sbatch row-count check
        # still reaches NSEEDS; it is excluded from the convergence-conditional aggregate
        # and counts against the convergence rate.
        res = try
            _fit_seed(p, seed)
        catch err
            n_threw += 1
            @printf("  SEED-ERROR cell=%s seed=%d: %s\n", p.cell, seed, sprint(showerror, err))
            flush(stdout)
            _failed_seed(p, seed)
        end
        _append_row!(p.out, _row(p, tr, res))
        push!(results, res)
        n_new += 1
        if n_new % 8 == 0
            @printf("  ... %d new seeds fitted (cell=%s, threw=%d)\n", n_new, p.cell, n_threw)
            flush(stdout)
        end
    end

    agg = _aggregate(results, tr, p)
    n_conv = count(r -> r.converged && isfinite(r.t), results)
    gate_str = agg.evaluable ? string(agg.gate_pass) : "na"
    println("GATE_JSON ", _gate_json(p, agg))
    # SCREENING reminder printed next to the result so a reader can never mistake a clean
    # screen for a promotion (doc-34 §11).
    println("NOTE screening tier — 48 seeds establish DIRECTION only; a clean screen schedules a ~2000-rep CONFIRM + Rose audit + maintainer G10 before any covered/public move.")
    # RUN_COMPLETE sentinel — the sbatch asserts its presence. The exit code is INDEPENDENT
    # of the gate: gate result lives on the GATE line and in the TSV. Non-zero exit => a
    # genuine crash, so the sbatch can trust it.
    @printf("RUN_COMPLETE cell=%s out=%s seeds_expected=%d seeds_in_result=%d new_fits=%d threw=%d converged=%d gate_pass=%s\n",
        p.cell, p.out, length(p.seeds), length(results), n_new, n_threw, n_conv, gate_str)
    flush(stdout)
    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    rr_main()
end
