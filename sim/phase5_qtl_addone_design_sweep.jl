using HSquared
using Statistics
using Printf
using Random

# Pre-declared BROADER-DESIGN robustness sweep for the conservative add-one
# genome-wide threshold rule (`genome_wide_pvalue`). The single-design add-one gate
# (#203, `sim/phase5_qtl_addone_gate.jl`) established type-I control at ONE design
# (n=300, m=200). This sweep tests the SAME one-sided-upper (not-anti-conservative)
# criterion across a GRID of (n, m) designs, addressing the "one design point"
# limitation the #203 after-task recorded. Reuses `run_addone_calibration` verbatim.
#
# PRE-DECLARED (see docs/dev-log/recovery-checkpoints/
# 2026-06-30-v5-qtl-addone-design-sweep-predeclaration.md, committed BEFORE this runs):
#   - DGP: same NULL marker DGP (`_simulate_markers`: LD via shared latent factors +
#     allele-freq gradient), intercept-only X, σ²e=1, nperm=2000, type1_reps=1000, α=0.05.
#   - DESIGN GRID: (n, m) ∈ {(200, 100), (300, 200), (500, 300)} — three points
#     spanning small/medium/larger n and marker count, each with its own m/n ratio.
#   - SEEDS: 10 cold seeds per design, UNSEEN at declaration —
#       (200,100): 20260940..20260949
#       (300,200): 20260950..20260959
#       (500,300): 20260960..20260969
#   - PASS (ALL design points required): for each design, 10/10 runs complete AND
#     `mean(empirical_type1) − α ≤ 2·MCSE` (MCSE = sd(per-seed type-I)/√10). ONE-SIDED
#     UPPER, identical to #203 and justified identically (the add-one rule is a valid
#     exact permutation test controlling type-I at ≤ α by construction; the gate tests
#     only that it does not VIOLATE the level). The overall verdict is PASS iff ALL
#     three design points pass. Criterion fixed BEFORE the run; no post-hoc relaxation.
#   Read as: NO DETECTABLE type-I inflation of the add-one rule across this design grid.
#   A FAIL at any design would be a banked NEGATIVE (and a surprise — non-exchangeable
#   nulls at that design); the V5 covered claim would NOT proceed and `gwas()` stays held.
#
#   env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase5_qtl_addone_design_sweep.jl

include("phase5_qtl_addone_gate.jl")   # run_addone_calibration (no auto-main when included)

const SWEEP_ALPHA = 0.05
const SWEEP_NPERM = 2000
const SWEEP_T1REPS = 1000
# (n, m, seeds) per design point
const DESIGNS = (
    (n = 200, m = 100, seeds = 20260940:20260949),
    (n = 300, m = 200, seeds = 20260950:20260959),
    (n = 500, m = 300, seeds = 20260960:20260969),
)

function run_design_point(d)
    results = [run_addone_calibration(s; n = d.n, m = d.m, nperm = SWEEP_NPERM,
                                      alpha = SWEEP_ALPHA, type1_reps = SWEEP_T1REPS)
               for s in d.seeds]
    t1 = [r.empirical_type1 for r in results]
    nseed = length(t1)
    mt1 = mean(t1)
    mcse = std(t1) / sqrt(nseed)
    excess = mt1 - SWEEP_ALPHA
    completed = nseed == length(d.seeds)
    not_inflated = excess <= 2 * mcse
    pass = completed && not_inflated
    return (n = d.n, m = d.m, nseed = nseed, mean_t1 = mt1, excess = excess,
            mcse = mcse, lo = minimum(t1), hi = maximum(t1), pass = pass)
end

function main_sweep()
    @printf("Add-one genome-wide threshold — BROADER-DESIGN robustness sweep (α=%.3f, nperm=%d, type1_reps=%d)\n",
            SWEEP_ALPHA, SWEEP_NPERM, SWEEP_T1REPS)
    rows = [run_design_point(d) for d in DESIGNS]
    for r in rows
        @printf("  (n=%3d, m=%3d) seeds=%d  mean type-I=%.4f  excess=%+.4f  2·MCSE=%.4f  range=[%.4f,%.4f]  %s\n",
                r.n, r.m, r.nseed, r.mean_t1, r.excess, 2 * r.mcse, r.lo, r.hi,
                r.pass ? "PASS" : "FAIL")
    end
    all_pass = all(r.pass for r in rows)
    @printf("GATE: %s  (all %d design points not-anti-conservative: %s)\n",
            all_pass ? "PASS" : "FAIL", length(rows), all_pass ? "true" : "false")
    return all_pass
end

if abspath(PROGRAM_FILE) == @__FILE__
    ok = main_sweep()
    exit(ok ? 0 : 1)
end
