using HSquared
using LinearAlgebra
using Printf
using Random
using Statistics

# Pre-declared bias/MCSE recovery gate for the arbitrary-N independent-random-effect
# REML estimator (`fit_multi_effect_reml`) — the doc-33 path-(b) substitutable gate for a
# V3-NEFFECT-REML covered close (ultraplan Phase 2). K=3 NON-CONFOUNDED effects.
#
# NOTE (design integrity): a first predeclaration (v1, 2026-07-01) used a dam-level
# "maternal-environment" third effect, but a pre-run single-seed diagnostic showed it was
# CONFOUNDED with the additive relationship (in the half-sib layout dam-mates are FULL
# SIBS, so a dam-level effect aliases the full-sib additive covariance; σm² collapsed to
# ~0). v1 was WITHDRAWN (not relaxed). This v2 uses the proven non-confounding device from
# the two-effect gate — environmental factors assigned INDEPENDENTLY of the pedigree —
# DOUBLED to three identifiable effects. See the predeclaration doc.
#
# PRE-DECLARED (see docs/dev-log/recovery-checkpoints/
# 2026-07-01-neffect-recovery-gate-predeclaration.md, committed BEFORE this runs):
#   - DGP (K=3, all identifiable, non-confounded): records = all q=860 animals of a
#     half-sib pedigree (20 sires × 40 dams × 800 offspring), Z1 = I_q.
#       * animal additive:  u_a  ~ N(0, σ_a²·A)        (A-structured, via the pedigree)
#       * environment 1:    u_g1 ~ N(0, σ_g1²·I_80)    (80 levels, assigned INDEPENDENTLY
#                                                        of the pedigree)
#       * environment 2:    u_g2 ~ N(0, σ_g2²·I_60)    (60 levels, assigned INDEPENDENTLY
#                                                        of the pedigree AND of env 1)
#       * residual:         e    ~ N(0, σ_e²·I)
#     truth (σ_a²,σ_g1²,σ_g2²,σ_e²)=(1.0,0.5,0.5,1.0), μ=2.0.
#   - Seeds: 20260800 .. 20260847 (48 cold-start; UNSEEN at declaration time).
#   - PASS criteria (ALL): 48/48 converged AND |bias| ≤ 2·MCSE for EACH of σ_a²,σ_g1²,σ_g2²,σ_e².
#   - Read as: NO DETECTABLE across-seed bias (a low-power non-rejection), never "unbiased".
#   NO post-hoc relaxation. A failure is a banked negative — V3-NEFFECT-REML stays partial.
#
#   env OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase3_neffect_recovery_gate.jl

const MU, SA, SG1, SG2, SE = 2.0, 1.0, 0.5, 0.5, 1.0
const NG1, NG2 = 80, 60
const SEEDS = 20260800:20260847

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

function _fit(seed; nsire = 20, ndam = 40, noffspring = 800)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    LA = cholesky(Symmetric(A)).L
    u1 = (LA * randn(rng, q)) .* sqrt(SA)
    g1 = [rand(rng, 1:NG1) for _ in 1:q]
    ug1 = randn(rng, NG1) .* sqrt(SG1)
    g2 = [rand(rng, 1:NG2) for _ in 1:q]
    ug2 = randn(rng, NG2) .* sqrt(SG2)
    e = randn(rng, q) .* sqrt(SE)
    X = ones(q, 1)
    Z1 = Matrix(1.0I, q, q)
    Zg1 = zeros(q, NG1); for a in 1:q; Zg1[a, g1[a]] = 1.0; end
    Zg2 = zeros(q, NG2); for a in 1:q; Zg2[a, g2[a]] = 1.0; end
    y = MU .+ u1 .+ Zg1 * ug1 .+ Zg2 * ug2 .+ e
    I1 = Matrix(1.0I, NG1, NG1); I2 = Matrix(1.0I, NG2, NG2)
    fit = HSquared.fit_multi_effect_reml(y, X, [(Z1, Ainv), (Zg1, I1), (Zg2, I2)];
                                         initial = [1.0, 1.0, 1.0, 1.0])
    s = fit.variance_components.sigmas
    return (fit.converged, s[1], s[2], s[3], fit.variance_components.sigma_e2)
end

function main()
    sa = Float64[]; sg1 = Float64[]; sg2 = Float64[]; se = Float64[]; nconv = 0
    for seed in SEEDS
        conv, a, b, c, r = _fit(seed)
        conv && (nconv += 1)
        push!(sa, a); push!(sg1, b); push!(sg2, c); push!(se, r)
    end
    n = length(SEEDS)
    results = Tuple{String,Bool,Float64,Float64,Float64}[]
    report(name, v, truth) = begin
        mn = mean(v); bias = mn - truth; mcse = std(v) / sqrt(n)
        ok = abs(bias) <= 2 * mcse
        @printf("  %-6s mean=%.4f truth=%.2f bias=%+.4f MCSE=%.4f |bias|/MCSE=%.2f  %s\n",
                name, mn, truth, bias, mcse, abs(bias) / mcse, ok ? "PASS" : "FAIL")
        push!(results, (name, ok, bias, mcse, mn))
        return ok
    end
    println("N-effect (K=3) bias/MCSE gate — $n seeds ($(first(SEEDS))..$(last(SEEDS))), converged=$nconv/$n")
    oka = report("σa²", sa, SA)
    ok1 = report("σg1²", sg1, SG1)
    ok2 = report("σg2²", sg2, SG2)
    oke = report("σe²", se, SE)
    gate = (nconv == n) && oka && ok1 && ok2 && oke
    println("GATE: ", gate ? "PASS" : "FAIL",
            "  (converged $(nconv)/$n; |bias|≤2·MCSE σa²=$oka σg1²=$ok1 σg2²=$ok2 σe²=$oke)")
    js = "{\"gate_pass\":$(gate),\"seeds\":$n,\"converged\":$nconv,\"params\":{" *
         join(["\"$(r[1])\":{\"bias\":$(round(r[3],digits=5)),\"mcse\":$(round(r[4],digits=5)),\"mean\":$(round(r[5],digits=5))}" for r in results], ",") * "}}"
    println("GATE_JSON ", js)
    exit(gate ? 0 : 1)
end

main()
