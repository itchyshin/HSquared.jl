# Pre-declared PRODUCTION-SCALE type-I gate for the EXACT per-dataset add-one rule —
# the constructive follow-up to the REUSE-shortcut NEGATIVE
# (sim/phase5_qtl_production_calibration.jl FAILED at 50 seeds because it reuses ONE
# permutation null across fresh phenotypes; the Totoro reuse_vs_rebuild diagnostic showed
# REUSE 0.0642 vs REBUILD 0.0478). This gate runs the procedure REAL `gwas()` uses: for
# EACH type-I replicate, build its OWN permutation null (the exact add-one test). The
# Phipson–Smyth construction guarantees type-I ≤ α; this confirms it EMPIRICALLY at
# realistic (n, m) scale (doc-18's owed "realistic-design calibration that controls
# genome-wide type-I error", for the exact rule).
#
# Parallel: Julia Distributed pmap over (design, seed) cells, ≤ NWORKERS, BLAS pinned to 1.
#
# PRE-DECLARED (see docs/dev-log/recovery-checkpoints/
# 2026-06-30-v5-qtl-rebuild-production-gate-predeclaration.md, committed BEFORE this runs):
#   - DGP: NULL, correlated markers (`_simulate_markers`), intercept-only X, σ²e=1, α=0.05.
#   - Per replicate: build a FRESH residual-permutation null (nperm=500) from THAT
#     replicate's phenotype, then add-one `genome_wide_pvalue ≤ α`. type1_reps=K=120.
#   - DESIGNS (realistic): (n, m) ∈ {(500, 2000), (1000, 5000)}, 20 cold seeds each:
#       (500, 2000):  20263000..20263019
#       (1000, 5000): 20263020..20263039
#   - PASS (ALL designs): all cells complete AND `mean(type1) − α ≤ 2·MCSE` (one-sided
#     upper, not anti-conservative). EXPECTED to pass (the exact rule is ≤ α by
#     construction); a FAIL would itself be a banked NEGATIVE. Criterion fixed BEFORE run.
#
#   NWORKERS=40 OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase5_qtl_rebuild_production_gate.jl

using Distributed
using Statistics, Printf

const NWORKERS = parse(Int, get(ENV, "NWORKERS", "40"))
const REPO = normpath(joinpath(@__DIR__, ".."))
if nprocs() <= NWORKERS
    addprocs(NWORKERS - nprocs() + 1; exeflags = "--project=$(REPO)")
end

@everywhere begin
    using HSquared, Random, Statistics
    ENV["OPENBLAS_NUM_THREADS"] = "1"
    include(joinpath(@__DIR__, "phase5_threshold_calibration.jl"))  # _simulate_markers
    _smax(y, X, M) = HSquared._scan_max_statistic(single_marker_scan(y, X, M; sigma_e2 = 1.0); statistic = :chisq)

    # EXACT per-dataset add-one rule: fresh null per replicate (what real gwas() does).
    function rebuild_cell(n, m, seed; nperm = 500, alpha = 0.05, type1_reps = 120)
        rng = MersenneTwister(seed)
        X = ones(n, 1)
        markers = _simulate_markers(rng, n, m)
        reject = 0
        for _ in 1:type1_reps
            y = X * [2.0] .+ randn(rng, n)                 # fresh NULL phenotype
            mc = _smax(y, X, markers)
            b = X \ y; f = X * b; r = y .- f
            null_rb = [_smax(f .+ r[randperm(rng, n)], X, markers) for _ in 1:nperm]
            genome_wide_pvalue(mc, null_rb) <= alpha && (reject += 1)
        end
        return (n = n, m = m, seed = seed, type1 = reject / type1_reps)
    end
end

const ALPHA = 0.05
const DESIGNS = (
    (n = 500,  m = 2000, seeds = 20263000:20263019),
    (n = 1000, m = 5000, seeds = 20263020:20263039),
)

function main()
    cells = [(d.n, d.m, s) for d in DESIGNS for s in d.seeds]
    @printf("REBUILD (exact-rule) production gate: %d cells over %d workers (α=%.3f)\n",
            length(cells), nworkers(), ALPHA)
    t0 = time()
    results = pmap(c -> rebuild_cell(c[1], c[2], c[3]), cells)
    @printf("all cells done in %.1f min\n", (time() - t0) / 60)
    open(joinpath(@__DIR__, "..", "sim", "phase5_rebuild_production_gate.tsv"), "w") do io
        println(io, "n\tm\tseed\ttype1")
        for r in results
            @printf(io, "%d\t%d\t%d\t%.6f\n", r.n, r.m, r.seed, r.type1)
        end
    end
    all_pass = true
    for d in DESIGNS
        t1 = [r.type1 for r in results if r.n == d.n && r.m == d.m]
        nseed = length(t1); mt1 = mean(t1); mcse = std(t1) / sqrt(nseed); excess = mt1 - ALPHA
        pass = (nseed == length(d.seeds)) && (excess <= 2 * mcse)
        all_pass &= pass
        @printf("  (n=%4d, m=%5d) seeds=%d  mean type-I=%.4f  excess=%+.4f  2·MCSE=%.4f  range=[%.4f,%.4f]  %s\n",
                d.n, d.m, nseed, mt1, excess, 2 * mcse, minimum(t1), maximum(t1), pass ? "PASS" : "FAIL")
    end
    @printf("GATE: %s  (exact per-dataset add-one rule controls type-I at realistic scale: %s)\n",
            all_pass ? "PASS" : "FAIL", all_pass ? "true" : "false")
    return all_pass
end

if abspath(PROGRAM_FILE) == @__FILE__
    ok = main()
    exit(ok ? 0 : 1)
end
