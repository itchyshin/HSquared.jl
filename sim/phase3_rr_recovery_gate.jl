using HSquared
using LinearAlgebra
using Printf
using Random
using Statistics

# Pre-declared known-truth K_g recovery gate for the random-regression REML estimator
# (`fit_random_regression_reml`, `src/random_regression.jl:439`) — the doc-16 path-(b)
# substitutable gate candidate for a V3-RR-REML `partial → covered` close, SCOPED TO
# k=2 (the covered aim: the LINEAR reaction norm, intercept + one slope, 2×2 K_g).
# Convention lock: docs/design/22-rr-convention-lock.md.
#
# LOAD-BEARING DGP DESIGN POINT (identifiability of the SLOPE variance K_g[2,2]):
# each animal must carry SEVERAL records at WELL-SPREAD covariate points across
# [-1, 1]. A narrow covariate range (or one record/animal) leaves the slope
# coefficient non-identified — the gate would then fail for the WRONG reason (a bad
# design, not a bad estimator). We give every recorded animal MREC=6 records at
# t = -1, -0.6, -0.2, 0.2, 0.6, 1 (endpoints included, evenly spread), so the
# normalized-Legendre design Φ has full column rank and K_g[2,2] is identified. This
# is the same "catch the confound BEFORE trusting the 48-seed aggregate" discipline
# as the neffect gate's v1→v2 withdrawal.
#
# PRE-DECLARED (see docs/dev-log/recovery-checkpoints/
# 2026-07-01-rr-k2-recovery-gate-predeclaration.md, committed BEFORE this runs):
#   - DGP (k=2 linear reaction norm): a half-sib pedigree q=360 (20 sires × 40 dams
#     × 300 offspring); the 300 OFFSPRING are recorded (parents unrecorded, as usual),
#     each with MREC=6 records at the spread covariate points above (n = 1800 records).
#     n is kept within the dense-oracle scale fence (≲2000 records); 300 half-sib
#     offspring × 6 spread points identify the 2×2 K_g (incl. the slope variance K_g[2,2],
#     which is noisy — 300 animals keeps |bias|/MCSE comfortably < 2 for a fair test).
#     Per-animal coefficient curves vec(a) ~ N(0, A ⊗ K_g) drawn via chol(A)⊗chol(K_g);
#     y_r = μ + φ(t_r)ᵀ a_{animal(r)} + e_r, e_r ~ N(0, σ²e). Truth
#     K_g = [1.0 0.3; 0.3 0.5] (ρ_g = 0.3/√0.5 ≈ 0.4243), σ²e = 1.0, μ = 2.0.
#   - Seeds: 20261000 .. 20261047 (48 cold-start; disjoint from every prior range —
#     two-effect 20260700.., neffect 20260800.., QTL 20260920..; UNSEEN at declaration).
#   - Cold start: `initial = (K_g = I₂, sigma_e2 = 1.0)` — NOT the truth.
#   - PASS criteria (ALL): 48/48 converged AND |bias| ≤ 2·MCSE for EACH of K_g[1,1],
#     K_g[2,2], K_g[1,2], and σ²e. ρ_g = K_g[1,2]/√(K_g[1,1]·K_g[2,2]) is REPORTED
#     (not gated — a ratio of estimates, not an additive component).
#   - Read as: NO DETECTABLE across-seed bias (a low-power non-rejection), never
#     "unbiased". NO post-hoc relaxation. A failure is a banked negative —
#     V3-RR-REML stays partial.
#
#   env OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase3_rr_recovery_gate.jl

const MU = 2.0
const KG = [1.0 0.3; 0.3 0.5]            # truth (2×2 coefficient genetic covariance)
const SE = 1.0
const TPTS = [-1.0, -0.6, -0.2, 0.2, 0.6, 1.0]   # spread covariate points (already in [-1,1])
const MREC = length(TPTS)
const SEEDS = 20261000:20261047

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

function _fit(seed; nsire = 20, ndam = 40, noffspring = 300)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    k = size(KG, 1)

    # Per-animal coefficient curves vec(a) ~ N(0, A ⊗ K_g): a[i,:] = Φ-coefficients.
    # Draw as chol(A) · Ξ · chol(K_g)' with Ξ a q×k iid-normal matrix, so
    # Cov(vec(a)) = (chol(K_g) ⊗ chol(A))(chol(K_g) ⊗ chol(A))' = K_g ⊗ A (animal-inner
    # here; the mapping to records below is animal-specific so the ordering is internal).
    LA = cholesky(Symmetric(A)).L
    LK = cholesky(Symmetric(KG)).L
    acoef = LA * randn(rng, q, k) * transpose(LK)     # q×k per-animal coefficient curves

    # Records: only the noffspring OFFSPRING are recorded, each at all MREC covariate
    # points. Offspring occupy pedigree rows (nsire+ndam+1):q after normalization? Not
    # guaranteed — resolve offspring row indices by id.
    idpos = Dict(id => i for (i, id) in enumerate(ped.ids))
    off_rows = [idpos["o$i"] for i in 1:noffspring]

    n = noffspring * MREC
    ts = Vector{Float64}(undef, n)
    Zrows = Vector{Int}(undef, n)                     # record → animal (pedigree row)
    yv = Vector{Float64}(undef, n)
    r = 0
    for oi in 1:noffspring
        arow = off_rows[oi]
        ϕcoef = view(acoef, arow, :)
        for t in TPTS
            r += 1
            ts[r] = t
            Zrows[r] = arow
            ϕ = legendre_basis(t, k)
            yv[r] = MU + dot(ϕ, ϕcoef) + sqrt(SE) * randn(rng)
        end
    end

    Phi = legendre_design(ts, k)                      # n×k normalized-Legendre design
    X = ones(n, 1)
    Z = zeros(n, q)
    @inbounds for i in 1:n
        Z[i, Zrows[i]] = 1.0
    end

    fit = HSquared.fit_random_regression_reml(yv, X, Phi, Z, Ainv;
                                              initial = (K_g = Matrix(1.0I, k, k), sigma_e2 = 1.0))
    Kg = fit.variance_components.K_g
    return (fit.converged, Kg[1, 1], Kg[2, 2], Kg[1, 2], fit.variance_components.sigma_e2)
end

function main()
    k11 = Float64[]; k22 = Float64[]; k12 = Float64[]; se = Float64[]; nconv = 0
    for seed in SEEDS
        conv, a, b, c, r = _fit(seed)
        conv && (nconv += 1)
        push!(k11, a); push!(k22, b); push!(k12, c); push!(se, r)
    end
    n = length(SEEDS)
    results = Tuple{String,Bool,Float64,Float64,Float64}[]
    report(name, v, truth) = begin
        mn = mean(v); bias = mn - truth; mcse = std(v) / sqrt(n)
        ok = abs(bias) <= 2 * mcse
        @printf("  %-10s mean=%.4f truth=%.4f bias=%+.4f MCSE=%.4f |bias|/MCSE=%.2f  %s\n",
                name, mn, truth, bias, mcse, abs(bias) / mcse, ok ? "PASS" : "FAIL")
        push!(results, (name, ok, bias, mcse, mn))
        return ok
    end
    # Reported (not gated): genetic correlation ρ_g per seed, then summarized.
    rho = k12 ./ sqrt.(max.(k11, eps()) .* max.(k22, eps()))
    truth_rho = KG[1, 2] / sqrt(KG[1, 1] * KG[2, 2])

    println("RR k=2 K_g bias/MCSE gate — $n seeds ($(first(SEEDS))..$(last(SEEDS))), converged=$nconv/$n")
    println("  DGP: half-sib q=360, 300 offspring × $MREC records at t=$(TPTS) (n=$(300*MREC))")
    ok11 = report("K_g[1,1]", k11, KG[1, 1])
    ok22 = report("K_g[2,2]", k22, KG[2, 2])
    ok12 = report("K_g[1,2]", k12, KG[1, 2])
    oke  = report("σe²", se, SE)
    @printf("  %-10s mean=%.4f truth=%.4f  (REPORTED, not gated)\n", "ρ_g", mean(rho), truth_rho)
    gate = (nconv == n) && ok11 && ok22 && ok12 && oke
    println("GATE: ", gate ? "PASS" : "FAIL",
            "  (converged $(nconv)/$n; |bias|≤2·MCSE K11=$ok11 K22=$ok22 K12=$ok12 σe²=$oke)")
    js = "{\"gate_pass\":$(gate),\"seeds\":$n,\"converged\":$nconv,\"rho_g_mean\":$(round(mean(rho),digits=5)),\"rho_g_truth\":$(round(truth_rho,digits=5)),\"params\":{" *
         join(["\"$(r[1])\":{\"bias\":$(round(r[3],digits=5)),\"mcse\":$(round(r[4],digits=5)),\"mean\":$(round(r[5],digits=5))}" for r in results], ",") * "}}"
    println("GATE_JSON ", js)
    exit(gate ? 0 : 1)
end

main()
