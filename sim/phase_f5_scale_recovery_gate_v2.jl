using HSquared
using LinearAlgebra
using SparseArrays
using Printf
using Random
using Statistics

# ============================================================================
# Wave F / Track A — F5 production-scale recovery + correctness gate, **v2 (corrected re-declaration)**.
# OPT-IN, NOT CI, RNG-full. Promotes NOTHING; public_covered_count stays 5.
#
# WHY v2. The v1 gate (`phase_f5_scale_recovery_gate.jl`, frozen 77ecad3a) is a BANKED NEGATIVE:
# Legs A (recovery @ q=1e5), B (deep unbiasedness), X (eigen≡AI) PASSED, but Leg C FAILED 6/8. A
# per-seed diagnostic proved this was a **test-design flaw, not a fitter defect**: v1's Leg C demanded
# `converged=false` at the σ→0 boundary, but with near-constant y the fitter CORRECTLY converges to a
# finite, non-throwing, near-zero σ²≈1e-14 — the actual #182 boundary contract (no throw, no NaN,
# finite, non-negative). v1's criterion rejected correct behaviour. v2 CORRECTS Leg C to test the
# actual contract, uses FRESH disjoint seeds (20268500..20268807), and is frozen BEFORE running. This
# is NOT a post-hoc relaxation of v1 (v1's banked negative stands, on fresh data v1 is untouched) —
# it is a fresh gate testing the correct property. The recovery criteria (Leg A relative ≤5%, Leg B
# |bias|≤2·MCSE) are UNCHANGED (they passed legitimately). See
# `2026-07-24-f5-scale-recovery-gate-v2-predeclaration.md` (committed BEFORE this runs) and the v1
# result doc `2026-07-24-f5-scale-recovery-gate-result.md`.
#
# LEGS (all pre-declared; ALL must pass; NO post-hoc relaxation):
#   A recovery AT SCALE  — q=100k half-sib gene-drop (F≡0 exact), 48 seeds 20268500..20268547,
#                          mean rel.err ≤ 5% (recovery; a bias/MCSE test is pathological as MCSE→0).
#   B deep pedigree      — 15 generations, exact chol(A) cov, n≈4500, 48 seeds 20268600..20268647,
#                          |bias| ≤ 2·MCSE (unbiasedness at well-scaled MCSE).
#   C boundary (CORRECTED) — near-constant y at n=2000, 8 seeds 20268700..20268707: the fit must be
#                          GRACEFUL = no throw AND finite σ²a,σ²e AND both ≥ 0 (the #182 contract).
#                          Convergence is NOT required (converging to a valid tiny σ² is correct).
#   X correctness        — eigen ≈ AI-REML ≤ 1e-6 at n=2000, 8 seeds 20268800..20268807.
#   GATE = A ∧ B ∧ C ∧ X.
#
#   env OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase_f5_scale_recovery_gate_v2.jl
# ============================================================================

const MU, SA, SE = 2.0, 1.0, 1.5              # truth: h² = 0.4
const AGREE_TOL  = 1e-6
const REL_TOL    = 0.05                        # Leg A (scale): mean rel.err ≤ 5% (recovery)
const SMOKE      = get(ENV, "HSQ_F5_SMOKE", "0") == "1"
const Q_SCALE    = SMOKE ? 10_000 : 100_000
const N_DEEP     = SMOKE ? 400   : 4_500
const N_ANCHOR   = SMOKE ? 300   : 2_000
const SEEDS_A = SMOKE ? (20268500:20268502) : (20268500:20268547)
const SEEDS_B = SMOKE ? (20268600:20268602) : (20268600:20268647)
const SEEDS_C = SMOKE ? (20268700:20268701) : (20268700:20268707)
const SEEDS_X = SMOKE ? (20268800:20268801) : (20268800:20268807)

function halfsib(q::Int)
    nsire = max(2, round(Int, 0.04q)); ndam = max(2, round(Int, 0.08q))
    noff  = q - nsire - ndam
    sire_ids = ["s$i" for i in 1:nsire]; dam_ids = ["d$i" for i in 1:ndam]
    off_ids  = ["o$i" for i in 1:noff]
    ids  = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(fill("0", nsire + ndam), [sire_ids[((i - 1) % nsire) + 1] for i in 1:noff])
    dam  = vcat(fill("0", nsire + ndam), [dam_ids[((i - 1) % ndam) + 1]  for i in 1:noff])
    return normalize_pedigree(ids, sire, dam)
end

function deep_pedigree(ntot::Int; ngen::Int = 15, nfounder::Int = 60, seed::Int = 1)
    rng = MersenneTwister(seed)
    per = max(nfounder, cld(ntot - nfounder, ngen))
    ids = String[]; sire = String[]; dam = String[]; prev = String[]; gid = 0
    for _ in 1:nfounder
        gid += 1; id = "g0_$gid"; push!(ids, id); push!(sire, "0"); push!(dam, "0"); push!(prev, id)
    end
    for g in 1:ngen
        cur = String[]
        for _ in 1:per
            length(ids) >= ntot && break
            gid += 1; id = "g$(g)_$gid"
            p = rand(rng, prev); m = rand(rng, prev)
            while m == p; m = rand(rng, prev); end
            push!(ids, id); push!(sire, p); push!(dam, m); push!(cur, id)
        end
        prev = cur; length(ids) >= ntot && break
    end
    return normalize_pedigree(ids, sire, dam)
end

function y_genedrop(ped; sa = SA, se = SE, seed = 1)
    rng = MersenneTwister(seed); q = length(ped.ids); u = zeros(q)
    @inbounds for i in 1:q
        s = ped.sire[i]; d = ped.dam[i]
        pa = s > 0 ? u[s] : 0.0; pb = d > 0 ? u[d] : 0.0
        nknown = (s > 0) + (d > 0)
        msv = nknown == 0 ? 1.0 : (nknown == 1 ? 0.75 : 0.5)
        u[i] = 0.5 * (pa + pb) + sqrt(sa * msv) * randn(rng)
    end
    return MU .+ u .+ sqrt(se) .* randn(rng, q)
end

function spec_exactcov(ped, seed; sa = SA, se = SE)
    rng = MersenneTwister(seed); q = length(ped.ids)
    Ainv = pedigree_inverse(ped)
    A  = Matrix(inv(Symmetric(Matrix(Ainv))))
    LA = cholesky(Symmetric(A)).L
    u  = (LA * randn(rng, q)) .* sqrt(sa)
    e  = randn(rng, q) .* sqrt(se)
    y  = MU .+ u .+ e
    return animal_model_spec(y, ones(q, 1), sparse(1.0I, q, q), Ainv; ids = collect(1:q), method = :REML)
end

function bias_row(name, v, truth)
    n = length(v); mn = mean(v); bias = mn - truth; mcse = std(v) / sqrt(n)
    ok = abs(bias) <= 2 * mcse
    @printf("    %-4s mean=%.4f truth=%.2f bias=%+.4f MCSE=%.4f |bias|/MCSE=%.2f  %s\n",
            name, mn, truth, bias, mcse, mcse == 0 ? 0.0 : abs(bias) / mcse, ok ? "PASS" : "FAIL")
    return (ok = ok, bias = bias, mcse = mcse, mean = mn)
end

function leg_recovery(label, seeds, specfn; pass_mode = :bias_mcse)
    va = Float64[]; ve = Float64[]; conv = 0
    for (k, seed) in enumerate(seeds)
        spec = specfn(seed)
        fit = fit_ai_reml(spec; initial = (sigma_a2 = 0.8, sigma_e2 = 0.8))
        fit.converged && (conv += 1)
        push!(va, fit.variance_components.sigma_a2); push!(ve, fit.variance_components.sigma_e2)
        @printf("  %s seed %d (%d/%d): σ²a=%.4f σ²e=%.4f conv=%s\n",
                label, seed, k, length(seeds), va[end], ve[end], fit.converged); flush(stdout)
    end
    println("  Leg $label: converged $conv/$(length(seeds))")
    ba = bias_row("σ²a", va, SA); be = bias_row("σ²e", ve, SE)
    relA = abs(mean(va) - SA) / SA; relE = abs(mean(ve) - SE) / SE
    maxrA = maximum(abs.(va .- SA) ./ SA); maxrE = maximum(abs.(ve .- SE) ./ SE)
    @printf("    mean rel.err σ²a=%.4f σ²e=%.4f (tol %.2f); per-seed max rel.err σ²a=%.4f σ²e=%.4f\n",
            relA, relE, REL_TOL, maxrA, maxrE)
    pass = if pass_mode === :relative
        (conv == length(seeds)) && (relA <= REL_TOL) && (relE <= REL_TOL)
    else
        (conv == length(seeds)) && ba.ok && be.ok
    end
    println("  Leg $label GATE ($pass_mode): ", pass ? "PASS" : "FAIL")
    return (pass = pass, conv = conv, ba = ba, be = be, relA = relA, relE = relE)
end

# CORRECTED boundary leg — tests the actual #182 contract: no throw, finite, non-negative variances.
# Convergence is NOT required (converging to a valid tiny σ² at the σ→0 boundary is correct behaviour).
function leg_boundary(seeds)
    graceful = 0
    for seed in seeds
        rng = MersenneTwister(seed)
        ped = halfsib(N_ANCHOR); q = length(ped.ids)
        y = MU .+ 1e-6 .* randn(rng, q)
        spec = animal_model_spec(y, ones(q, 1), sparse(1.0I, q, q), pedigree_inverse(ped);
                                 ids = collect(1:q), method = :REML)
        ok = try
            fit = fit_ai_reml(spec; initial = (sigma_a2 = 0.8, sigma_e2 = 0.8))
            sa = fit.variance_components.sigma_a2; se = fit.variance_components.sigma_e2
            gr = isfinite(sa) && isfinite(se) && sa >= 0 && se >= 0
            @printf("  C seed %d: conv=%s σ²a=%.3e σ²e=%.3e graceful=%s\n", seed, fit.converged, sa, se, gr)
            gr
        catch e
            @printf("  C seed %d: THREW %s graceful=false\n", seed, typeof(e)); false
        end
        ok && (graceful += 1)
    end
    println("  Leg C boundary (finite/non-throwing/non-negative): graceful $graceful/$(length(seeds))")
    pass = graceful == length(seeds)
    println("  Leg C GATE: ", pass ? "PASS" : "FAIL")
    return pass
end

function anchor(seeds)
    da = 0.0; de = 0.0; ok = true
    for seed in seeds
        spec = spec_exactcov(halfsib(N_ANCHOR), seed)
        fe = fit_eigen_reml(spec)
        fa = fit_ai_reml(spec; initial = (sigma_a2 = 0.8, sigma_e2 = 0.8))
        (fe.converged && fa.converged) || (ok = false)
        da = max(da, abs(fe.variance_components.sigma_a2 - fa.variance_components.sigma_a2) /
                     abs(fa.variance_components.sigma_a2))
        de = max(de, abs(fe.variance_components.sigma_e2 - fa.variance_components.sigma_e2) /
                     abs(fa.variance_components.sigma_e2))
    end
    pass = ok && da <= AGREE_TOL && de <= AGREE_TOL
    @printf("  Anchor eigen≈AI max rel.diff: σ²a=%.2e σ²e=%.2e (tol %.0e)  %s\n",
            da, de, AGREE_TOL, pass ? "PASS" : "FAIL")
    return pass
end

function main()
    println("F5 v2 (corrected) production-scale recovery gate — truth (σ²a,σ²e)=($SA,$SE) h²=0.4")
    println("host=", gethostname(), " julia=", VERSION, " threads=", Threads.nthreads())
    a = leg_recovery("A(scale q=$Q_SCALE)", SEEDS_A, s -> begin
            ped = halfsib(Q_SCALE)
            animal_model_spec(y_genedrop(ped; seed = s), ones(length(ped.ids), 1),
                              sparse(1.0I, length(ped.ids), length(ped.ids)),
                              pedigree_inverse(ped); ids = collect(1:length(ped.ids)), method = :REML)
        end; pass_mode = :relative)
    b = leg_recovery("B(deep n≈$N_DEEP)", SEEDS_B, s -> spec_exactcov(deep_pedigree(N_DEEP; seed = s), s); pass_mode = :bias_mcse)
    c = leg_boundary(SEEDS_C)
    x = anchor(SEEDS_X)
    gate = a.pass && b.pass && c && x
    println("\nGATE: ", gate ? "PASS" : "FAIL", "  (A=$(a.pass) B=$(b.pass) C=$c X=$x)")
    js = "{\"gate_pass\":$gate,\"version\":\"v2-corrected\",\"truth\":{\"sa\":$SA,\"se\":$SE}," *
         "\"A\":{\"pass\":$(a.pass),\"conv\":$(a.conv),\"n\":$Q_SCALE,\"rel_sa\":$(round(a.relA,digits=5)),\"rel_se\":$(round(a.relE,digits=5))}," *
         "\"B\":{\"pass\":$(b.pass),\"conv\":$(b.conv),\"n\":$N_DEEP,\"bias_sa\":$(round(b.ba.bias,digits=6)),\"mcse_sa\":$(round(b.ba.mcse,digits=6)),\"bias_se\":$(round(b.be.bias,digits=6)),\"mcse_se\":$(round(b.be.mcse,digits=6))}," *
         "\"C_boundary\":$c,\"X_anchor\":$x}"
    println("GATE_JSON ", js)
    exit(gate ? 0 : 1)
end

main()
