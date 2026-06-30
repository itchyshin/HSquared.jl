using Statistics
using Printf

# Pre-declared genome-wide threshold CALIBRATION gate for the permutation-null QTL
# threshold (`genome_wide_threshold_from_null` over `single_marker_scan`) — the
# substitutable-gate candidate for a V5 "calibrated genome-wide threshold" covered
# claim (the #48 gate that holds the R `gwas()` significance wording). Reuses the
# existing calibration harness verbatim and adds a fixed PASS verdict.
#
# PRE-DECLARED (see docs/dev-log/recovery-checkpoints/
# 2026-06-30-v5-qtl-threshold-gate-predeclaration.md, committed BEFORE this runs):
#   - DGP: NULL (no marker signal). n=300 records, m=200 correlated markers (LD via
#     shared latent factors + allele-freq gradient — `_simulate_markers`), intercept-only
#     X, σ²e=1. Per seed: an LD-aware permutation null (nperm=2000, residual permutation)
#     → the (1−α) genome-wide chi-square threshold; then type1_reps=1000 INDEPENDENT
#     no-signal scans on the SAME panel give the empirical type-I (fraction exceeding it).
#   - α = 0.05. Seeds 20260900..20260919 (20 cold-start; UNSEEN at declaration).
#   - PASS (ALL): 20/20 runs complete AND |mean(empirical_type1) − α| ≤ 2·MCSE, where
#     MCSE = sd(per-seed empirical_type1)/√20. TWO-SIDED calibration (type-I ≈ α, not
#     just ≤ α): a CALIBRATED threshold, neither anti-conservative nor over-conservative.
#   Read as: NO DETECTABLE mis-calibration of the permutation threshold at α (low-power
#   non-rejection), never "exactly calibrated". NO post-hoc relaxation. A FAIL — especially
#   anti-conservative type-I > α from the finite-nperm quantile — is a banked NEGATIVE
#   (the permutation threshold needs more permutations or a conservative correction; the
#   V5 covered claim does NOT proceed and the R `gwas()` wording stays held).
#
#   env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase5_qtl_threshold_gate.jl

include("phase5_threshold_calibration.jl")   # run_threshold_calibration (no auto-main when included)

const ALPHA = 0.05
const SEEDS = 20260900:20260919
const N, M, NPERM, T1REPS = 300, 200, 2000, 1000

function main_gate()
    results = [run_threshold_calibration(s; n = N, m = M, nperm = NPERM, alpha = ALPHA,
                                         type1_reps = T1REPS, type1_marker_mode = :fixed)
               for s in SEEDS]
    t1 = [r.empirical_type1 for r in results]
    nseed = length(t1)
    m = mean(t1); mcse = std(t1) / sqrt(nseed)
    bias = m - ALPHA
    n_below_bonf = count(r -> r.threshold_less_than_bonferroni, results)
    ok = abs(bias) <= 2 * mcse
    println("QTL genome-wide threshold calibration gate — $nseed seeds ($(first(SEEDS))..$(last(SEEDS)))")
    @printf("  n=%d markers=%d nperm=%d type1_reps=%d  α=%.3f\n", N, M, NPERM, T1REPS, ALPHA)
    @printf("  empirical type-I: mean=%.4f  target=%.3f  bias=%+.4f  MCSE=%.4f  |bias|/MCSE=%.2f\n",
            m, ALPHA, bias, mcse, abs(bias) / mcse)
    @printf("  per-seed type-I range=[%.4f, %.4f];  perm<Bonferroni in %d/%d seeds\n",
            minimum(t1), maximum(t1), n_below_bonf, nseed)
    println("GATE: ", ok ? "PASS" : "FAIL",
            "  (|mean type-I − α| ≤ 2·MCSE = $(round(2*mcse, digits=4)); ",
            bias > 0 ? "anti-conservative" : "conservative", " direction)")
    return ok
end

main_gate()
