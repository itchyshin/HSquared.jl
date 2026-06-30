# Diagnostic isolating WHY the production REUSE calibration gate
# (sim/phase5_qtl_production_calibration.jl) is mildly anti-conservative at 50 seeds.
#
#   REUSE   = build ONE permutation null from a calibration phenotype, apply it to many
#             fresh phenotypes (what the type-I calibration harness does for efficiency).
#   REBUILD = for EACH fresh phenotype, build its OWN permutation null — the EXACT add-one
#             test, as real `gwas()` use does (conservative ≤ α by Phipson–Smyth).
#
# Confirms the production FAIL is a SIMULATION null-reuse artifact, NOT a flaw in the
# per-dataset add-one rule. Totoro run (n=600, m=300, 12 seeds, nperm=400, K=300):
#   REUSE   mean type-I = 0.0642
#   REBUILD mean type-I = 0.0478   (reuse − rebuild = +0.0164)
#
#   NWORKERS=12 OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase5_reuse_vs_rebuild_diagnostic.jl

using Distributed
using Statistics, Printf

const NWORKERS = parse(Int, get(ENV, "NWORKERS", "12"))
const REPO = normpath(joinpath(@__DIR__, ".."))
if nprocs() <= NWORKERS
    addprocs(NWORKERS - nprocs() + 1; exeflags = "--project=$(REPO)")
end

@everywhere begin
    using HSquared, Random, Statistics
    ENV["OPENBLAS_NUM_THREADS"] = "1"
    include(joinpath(@__DIR__, "phase5_threshold_calibration.jl"))  # _simulate_markers
    _smax(y, X, M) = HSquared._scan_max_statistic(single_marker_scan(y, X, M; sigma_e2 = 1.0); statistic = :chisq)

    function reuse_vs_rebuild(seed; n = 600, m = 300, nperm = 400, K = 300, alpha = 0.05)
        rng = MersenneTwister(seed)
        X = ones(n, 1)
        markers = _simulate_markers(rng, n, m)
        y0 = X * [2.0] .+ randn(rng, n)
        b0 = X \ y0; f0 = X * b0; r0 = y0 .- f0
        null_reuse = [_smax(f0 .+ r0[randperm(rng, n)], X, markers) for _ in 1:nperm]
        rej_reuse = 0; rej_rebuild = 0
        for _ in 1:K
            yrep = X * [2.0] .+ randn(rng, n)
            mc = _smax(yrep, X, markers)
            genome_wide_pvalue(mc, null_reuse) <= alpha && (rej_reuse += 1)
            brep = X \ yrep; frep = X * brep; rrep = yrep .- frep
            null_rb = [_smax(frep .+ rrep[randperm(rng, n)], X, markers) for _ in 1:nperm]
            genome_wide_pvalue(mc, null_rb) <= alpha && (rej_rebuild += 1)
        end
        return (seed = seed, t1_reuse = rej_reuse / K, t1_rebuild = rej_rebuild / K)
    end
end

const SEEDS = 20262000:20262011

function main()
    res = pmap(reuse_vs_rebuild, collect(SEEDS))
    mr = [r.t1_reuse for r in res]; mb = [r.t1_rebuild for r in res]
    open(joinpath(@__DIR__, "..", "sim", "phase5_reuse_vs_rebuild_diagnostic.tsv"), "w") do io
        println(io, "seed\tt1_reuse\tt1_rebuild")
        for r in res
            @printf(io, "%d\t%.6f\t%.6f\n", r.seed, r.t1_reuse, r.t1_rebuild)
        end
    end
    @printf("REUSE   mean type-I = %.4f  (range [%.4f, %.4f], MCSE %.4f)\n",
            mean(mr), minimum(mr), maximum(mr), std(mr) / sqrt(length(mr)))
    @printf("REBUILD mean type-I = %.4f  (range [%.4f, %.4f], MCSE %.4f)\n",
            mean(mb), minimum(mb), maximum(mb), std(mb) / sqrt(length(mb)))
    @printf("reuse − rebuild = %+.4f  (positive ⇒ the reuse shortcut is the anti-conservatism source)\n",
            mean(mr) - mean(mb))
    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
