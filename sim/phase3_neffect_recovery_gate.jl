using HSquared
using LinearAlgebra
using Printf
using Random
using Statistics

# Pre-declared bias/MCSE recovery gate for the arbitrary-N independent-random-effect
# REML estimator (`fit_multi_effect_reml`) — the doc-33 path-(b) substitutable gate for a
# V3-NEFFECT-REML covered close (ultraplan Phase 2). Extends the two-effect gate
# (`sim/phase3_two_effect_bias_mcse.jl`) to K=3 NON-CONFOUNDED effects.
#
# PRE-DECLARED (see docs/dev-log/recovery-checkpoints/
# 2026-07-01-neffect-recovery-gate-predeclaration.md, committed BEFORE this runs):
#   - DGP (K=3, all identifiable, non-confounded): records = 800 offspring of a half-sib
#     pedigree (20 sires × 40 dams × 800 offspring, q=860).
#       * animal additive:      u_a ~ N(0, σ_a²·A)         (A-structured, via the pedigree)
#       * maternal-environment: u_m ~ N(0, σ_m²·I_40)      (dam-level, dam-replicated)
#       * contemporary group:   u_c ~ N(0, σ_c²·I_80)      (80 groups, drawn INDEPENDENTLY
#                                                            of the pedigree — the non-
#                                                            confounding device)
#       * residual:             e   ~ N(0, σ_e²·I)
#     truth (σ_a²,σ_m²,σ_c²,σ_e²)=(1.0,0.5,0.5,1.0), μ=2.0.
#   - Seeds: 20260800 .. 20260847 (48 cold-start; UNSEEN at declaration time).
#   - PASS criteria (ALL): 48/48 converged AND |bias| ≤ 2·MCSE for EACH of σ_a²,σ_m²,σ_c²,σ_e².
#   - Read as: NO DETECTABLE across-seed bias (a low-power non-rejection), never "unbiased".
#   NO post-hoc relaxation. A failure is a banked negative — V3-NEFFECT-REML stays partial.
#
#   env OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase3_neffect_recovery_gate.jl

const MU, SA, SM, SC, SE = 2.0, 1.0, 0.5, 0.5, 1.0
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

function _fit(seed; nsire = 20, ndam = 40, noffspring = 800, ngroup = 80)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    LA = cholesky(Symmetric(A)).L
    ua = (LA * randn(rng, q)) .* sqrt(SA)          # animal additive BVs (length q)
    um = randn(rng, ndam) .* sqrt(SM)              # maternal-environment (40)
    uc = randn(rng, ngroup) .* sqrt(SC)            # contemporary group (80)

    idpos = Dict(id => k for (k, id) in enumerate(ped.ids))
    Za = zeros(noffspring, q)                       # record -> animal (offspring only)
    Zm = zeros(noffspring, ndam)                    # record -> dam maternal-env
    Zc = zeros(noffspring, ngroup)                  # record -> contemporary group
    for i in 1:noffspring
        Za[i, idpos["o$i"]] = 1.0
        Zm[i, ((i - 1) % ndam) + 1] = 1.0
        Zc[i, rand(rng, 1:ngroup)] = 1.0
    end
    X = ones(noffspring, 1)
    e = randn(rng, noffspring) .* sqrt(SE)
    y = MU .+ Za * ua .+ Zm * um .+ Zc * uc .+ e

    Im = Matrix(1.0I, ndam, ndam)
    Ic = Matrix(1.0I, ngroup, ngroup)
    fit = HSquared.fit_multi_effect_reml(y, X, [(Za, Ainv), (Zm, Im), (Zc, Ic)];
                                         initial = [1.0, 1.0, 1.0, 1.0])
    s = fit.variance_components.sigmas
    return (fit.converged, s[1], s[2], s[3], fit.variance_components.sigma_e2)
end

function main()
    sa = Float64[]; sm = Float64[]; sc = Float64[]; se = Float64[]; nconv = 0
    for seed in SEEDS
        conv, a, m, c, r = _fit(seed)
        conv && (nconv += 1)
        push!(sa, a); push!(sm, m); push!(sc, c); push!(se, r)
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
    okm = report("σm²", sm, SM)
    okc = report("σc²", sc, SC)
    oke = report("σe²", se, SE)
    gate = (nconv == n) && oka && okm && okc && oke
    println("GATE: ", gate ? "PASS" : "FAIL",
            "  (converged $(nconv)/$n; |bias|≤2·MCSE σa²=$oka σm²=$okm σc²=$okc σe²=$oke)")
    js = "{\"gate_pass\":$(gate),\"seeds\":$n,\"converged\":$nconv,\"params\":{" *
         join(["\"$(r[1])\":{\"bias\":$(round(r[3],digits=5)),\"mcse\":$(round(r[4],digits=5)),\"mean\":$(round(r[5],digits=5))}" for r in results], ",") * "}}"
    println("GATE_JSON ", js)
    exit(gate ? 0 : 1)
end

main()
