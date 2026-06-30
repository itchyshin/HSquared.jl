using HSquared
using LinearAlgebra
using Printf
using Random
using Statistics

# Pre-declared bias/MCSE recovery gate for the genomic REML estimator
# (`fit_gblup_reml`) — the doc-33 path-(b) substitutable gate candidate for a
# V2-GREML covered close. Pairs with the executed BLUPF90 same-estimand comparator
# (docs/dev-log/recovery-checkpoints/2026-06-30-v2-genomic-blupf90-comparator.md, PR #200).
# This aggregates ACROSS seeds into bias/MCSE (cf. sim/phase3_two_effect_bias_mcse.jl).
#
# PRE-DECLARED (see docs/dev-log/recovery-checkpoints/
# 2026-06-30-v2-genomic-recovery-gate-predeclaration.md, committed BEFORE this runs):
#   - DGP: N=300 individuals, M=1000 biallelic markers (allele freq ~ U(0.1,0.9), drawn
#     fresh per seed → G varies across seeds). VanRaden G (method 1); K = G + ridge·I
#     (ridge=0.01); Ginv = inv(K). Breeding values u ~ N(0, K·σ²g) drawn with chol(K),
#     so the supplied Ginv is EXACTLY the model covariance and σ²g is the exact estimand.
#     This tests the REML ESTIMATOR on a supplied genomic precision matrix; the marker→G
#     construction / ridge realism is V2-GRM, deliberately OUT of scope here.
#   - Truth (σ²g, σ²e) = (0.6, 0.4), μ = 2.0, h² = 0.6.
#   - Seeds: 20260800 .. 20260847 (48 cold-start; UNSEEN at declaration; disjoint from the
#     comparator seed 20260630 and the two-effect gate's 20260700..20260747).
#   - PASS (ALL): 48/48 converged AND |bias| ≤ 2·MCSE for EACH of σ²g, σ²e, h².
#   Read as: NO DETECTABLE across-seed bias (a low-power non-rejection), never "unbiased".
#   NO post-hoc relaxation. A failure is a banked negative — V2-GREML stays partial.
#
#   env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase2_genomic_reml_recovery.jl

const MU, SG2, SE2 = 2.0, 0.6, 0.4
const N, M, RIDGE = 300, 1000, 0.01
const SEEDS = 20260800:20260847

function _fit(seed)
    rng = MersenneTwister(seed)
    p = [0.1 + 0.8 * rand(rng) for _ in 1:M]
    markers = Float64[(rand(rng) < p[j]) + (rand(rng) < p[j]) for i in 1:N, j in 1:M]
    G = genomic_relationship_matrix(markers)                      # VanRaden method 1
    K = Symmetric(Matrix(G) + RIDGE * I)                          # the model covariance
    Ginv = Matrix(genomic_relationship_inverse(G; ridge = RIDGE)) # = inv(K)
    u = cholesky(K).L * randn(rng, N) .* sqrt(SG2)
    e = randn(rng, N) .* sqrt(SE2)
    y = MU .+ u .+ e
    fit = fit_gblup_reml(y, ones(N, 1), Matrix(1.0I, N, N), Ginv)
    vc = fit.variance_components
    h2 = vc.sigma_a2 / (vc.sigma_a2 + vc.sigma_e2)
    return (fit.converged, vc.sigma_a2, vc.sigma_e2, h2)
end

function main()
    sg = Float64[]; se = Float64[]; h2v = Float64[]; nconv = 0
    for seed in SEEDS
        conv, a, c, h = _fit(seed)
        conv && (nconv += 1)
        push!(sg, a); push!(se, c); push!(h2v, h)
    end
    n = length(SEEDS)
    report(name, v, truth) = begin
        m = mean(v); bias = m - truth; mcse = std(v) / sqrt(n)
        ok = abs(bias) <= 2 * mcse
        @printf("  %-4s mean=%.4f truth=%.2f bias=%+.4f MCSE=%.4f |bias|/MCSE=%.2f  %s\n",
                name, m, truth, bias, mcse, abs(bias) / mcse, ok ? "PASS" : "FAIL")
        return ok
    end
    println("Genomic GREML bias/MCSE gate — $n seeds ($(first(SEEDS))..$(last(SEEDS))), converged=$nconv/$n")
    okg = report("σ²g", sg, SG2)
    oke = report("σ²e", se, SE2)
    okh = report("h²", h2v, SG2 / (SG2 + SE2))
    gate = (nconv == n) && okg && oke && okh
    println("GATE: ", gate ? "PASS" : "FAIL",
            "  (converged $nconv/$n; |bias|≤2·MCSE on σ²g=$okg σ²e=$oke h²=$okh)")
end

main()
