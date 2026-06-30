using HSquared
using LinearAlgebra
using Printf
using Random
using Statistics

# Pre-declared bias/MCSE recovery gate for the two-effect REML estimator
# (`fit_two_effect_reml`) — the doc-33 path-(b) substitutable gate candidate for a
# V3-TWOEFFECT-REML covered close. Model + DGP are identical to the recovery harness
# `sim/phase3_two_effect_recovery.jl`; this aggregates ACROSS seeds into bias/MCSE.
#
# PRE-DECLARED (see docs/dev-log/recovery-checkpoints/
# 2026-06-30-v3-two-effect-recovery-gate-predeclaration.md, committed BEFORE this runs):
#   - DGP: half-sib q=860 (20 sires, 40 dams, 800 offspring), 80 common-env groups
#     assigned INDEPENDENTLY of the pedigree; truth (σ1²,σ2²,σe²)=(1.0,0.5,1.0), μ=2.0.
#   - Seeds: 20260700 .. 20260747 (48 cold-start; UNSEEN at declaration time).
#   - PASS criteria (ALL): 48/48 converged AND |bias| ≤ 2·MCSE for EACH of σ1², σ2², σe².
#   - Read as: NO DETECTABLE across-seed bias (a low-power non-rejection), never "unbiased".
#   NO post-hoc relaxation. A failure is a banked negative — V3-TWOEFFECT-REML stays partial.
#
#   env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase3_two_effect_bias_mcse.jl

const MU, S1, S2, SE = 2.0, 1.0, 0.5, 1.0
const SEEDS = 20260700:20260747

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

function _fit(seed; nsire = 20, ndam = 40, noffspring = 800, ngroup = 80)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv1 = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv1))))
    q = length(ped.ids)
    LA = cholesky(Symmetric(A)).L
    u1 = (LA * randn(rng, q)) .* sqrt(S1)
    group = [rand(rng, 1:ngroup) for _ in 1:q]
    u2 = randn(rng, ngroup) .* sqrt(S2)
    X = ones(q, 1)
    Z1 = Matrix(1.0I, q, q)
    Z2 = zeros(q, ngroup)
    for a in 1:q
        Z2[a, group[a]] = 1.0
    end
    Ainv2 = Matrix(1.0I, ngroup, ngroup)
    e = randn(rng, q) .* sqrt(SE)
    y = MU .+ u1 .+ Z2 * u2 .+ e
    fit = HSquared.fit_two_effect_reml(y, X, Z1, Ainv1, Z2, Ainv2;
                                       initial = (sigma1 = 1.0, sigma2 = 1.0, sigma_e2 = 1.0))
    return (fit.converged, fit.variance_components.sigma1,
            fit.variance_components.sigma2, fit.variance_components.sigma_e2)
end

function main()
    s1 = Float64[]; s2 = Float64[]; se = Float64[]; nconv = 0
    for seed in SEEDS
        conv, a, b, c = _fit(seed)
        conv && (nconv += 1)
        push!(s1, a); push!(s2, b); push!(se, c)
    end
    n = length(SEEDS)
    report(name, v, truth) = begin
        m = mean(v); bias = m - truth; mcse = std(v) / sqrt(n)
        ok = abs(bias) <= 2 * mcse
        @printf("  %-6s mean=%.4f truth=%.2f bias=%+.4f MCSE=%.4f |bias|/MCSE=%.2f  %s\n",
                name, m, truth, bias, mcse, abs(bias)/mcse, ok ? "PASS" : "FAIL")
        return ok
    end
    println("Two-effect bias/MCSE gate — $n seeds ($(first(SEEDS))..$(last(SEEDS))), converged=$nconv/$n")
    ok1 = report("σ1²", s1, S1)
    ok2 = report("σ2²", s2, S2)
    oke = report("σe²", se, SE)
    gate = (nconv == n) && ok1 && ok2 && oke
    println("GATE: ", gate ? "PASS" : "FAIL",
            "  (converged $(nconv)/$n; |bias|≤2·MCSE on σ1²=$ok1 σ2²=$ok2 σe²=$oke)")
end

main()
