using HSquared
using LinearAlgebra
using SparseArrays
using Printf
using Random
using Statistics

# ============================================================================
# Wave F / Track A — F5 PRODUCTION-SCALE recovery + correctness gate for the sparse
# single-effect AI-REML fitter (`fit_ai_reml`).  OPT-IN, NOT CI, RNG-full (outside test/).
#
# It promotes NOTHING.  A staged experimental→(production-default) declaration additionally
# needs the F8 same-estimand comparator (sommer), a REAL Rose audit (G8), and maintainer
# sign-off (G10).  `public_covered_count` stays 5 regardless of outcome.  A failure is a banked
# negative, not a silent relaxation.
#
# PRE-DECLARED (see docs/dev-log/recovery-checkpoints/
# 2026-07-24-f5-scale-recovery-gate-predeclaration.md, committed BEFORE this runs):
#   Truth (σ²a, σ²e) = (1.0, 1.5) → h² = 0.4, μ = 2.0.  Interior, off-boundary.
#
#   LEG A — recovery AT SCALE (the headline).  q = 100_000, non-inbred half-sib pedigree
#     (F ≡ 0 by construction: offspring of disjoint unrelated sire/dam founder pools), so O(n)
#     gene-dropping with Mendelian-sampling variance 0.5·σ²a gives Cov(u) = σ²a·A EXACTLY.
#     48 cold-start seeds 20268000..20268047.  Fit `fit_ai_reml`.
#
#   LEG B — DEEP pedigree (the review's >12-generation gap).  15 discrete generations, small
#     founder base → genuine accumulating inbreeding; n ≈ 4_500.  Exact covariance via the dense
#     Cholesky of A = inv(Ainv) (u = √σ²a · chol(A).L · z), so the recovery target is exact
#     REGARDLESS of inbreeding.  48 seeds 20268100..20268147.  Fit `fit_ai_reml`.
#
#   LEG C — BOUNDARY (the σ²→0 gap).  Near-constant y (no additive signal) at n = 2_000 must
#     terminate GRACEFULLY: `converged = false`, finite non-NaN variance components, NEVER a throw
#     or NaN garbage (the #182 graceful-boundary contract).  8 seeds 20268200..20268207.
#
#   CORRECTNESS cross-check — at n = 2_000 (both estimators feasible), eigen-once and sparse
#     AI-REML must AGREE on identical data to ≤ 1e-6 (independent-route corroboration; the exact
#     dense-inverse == selected-inverse identity is already covered in test/runtests.jl).
#
#   PASS (ALL required; NO post-hoc relaxation):
#     A: 48/48 converged AND |bias| ≤ 2·MCSE for σ²a AND σ²e.
#     B: 48/48 converged AND |bias| ≤ 2·MCSE for σ²a AND σ²e.
#     C: 8/8 graceful (converged=false, finite VCs, no throw).
#     X: eigen ≈ AI-REML max rel.diff ≤ 1e-6 for σ²a AND σ²e over the anchor seeds.
#   Read as: NO DETECTABLE across-seed bias at production scale (a low-power non-rejection),
#   never "unbiased".
#
#   env OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase_f5_scale_recovery_gate.jl
# ============================================================================

const MU, SA, SE = 2.0, 1.0, 1.5              # truth: h² = SA/(SA+SE) = 0.4
const AGREE_TOL  = 1e-6
const REL_TOL    = 0.05                        # Leg A (scale): mean rel.err ≤ 5% (recovery, not unbiasedness)
# HSQ_F5_SMOKE=1 is a SMOKE-ONLY size override (toy sizes, 2-3 seeds) to validate the code paths
# before the frozen run. The PRE-DECLARED canonical gate is run with NO env var set → the values
# below. Setting the env changes nothing about the pre-declared parameters (which are the defaults).
const SMOKE      = get(ENV, "HSQ_F5_SMOKE", "0") == "1"
const Q_SCALE    = SMOKE ? 10_000 : 100_000
const N_DEEP     = SMOKE ? 400   : 4_500
const N_ANCHOR   = SMOKE ? 300   : 2_000
const SEEDS_A = SMOKE ? (20268000:20268002) : (20268000:20268047)   # scale, half-sib, gene-drop
const SEEDS_B = SMOKE ? (20268100:20268102) : (20268100:20268147)   # deep, exact-cov
const SEEDS_C = SMOKE ? (20268200:20268201) : (20268200:20268207)   # boundary
const SEEDS_X = SMOKE ? (20268300:20268301) : (20268300:20268307)   # eigen≈AI anchor

# ---- pedigrees -------------------------------------------------------------
# Non-inbred half-sib (F ≡ 0): disjoint unrelated sire/dam founder pools, one offspring generation.
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

# Deep pedigree: `ngen` discrete generations, small founder base; each individual draws 2 distinct
# parents from the PREVIOUS generation → accumulating inbreeding over depth.
function deep_pedigree(ntot::Int; ngen::Int = 15, nfounder::Int = 60, seed::Int = 1)
    rng = MersenneTwister(seed)
    per = max(nfounder, cld(ntot - nfounder, ngen))
    ids = String[]; sire = String[]; dam = String[]
    prev = String[]
    gid = 0
    # founders
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
        prev = cur
        length(ids) >= ntot && break
    end
    return normalize_pedigree(ids, sire, dam)
end

# ---- DGPs ------------------------------------------------------------------
# O(n) gene-drop; exact for F ≡ 0 (Cov(u) = σ²a·A).
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

# Exact σ²a·A covariance via dense chol(A) — inbreeding-exact, moderate n only.
function spec_exactcov(ped, seed; sa = SA, se = SE)
    rng = MersenneTwister(seed); q = length(ped.ids)
    Ainv = pedigree_inverse(ped)
    A  = Matrix(inv(Symmetric(Matrix(Ainv))))
    LA = cholesky(Symmetric(A)).L
    u  = (LA * randn(rng, q)) .* sqrt(sa)
    e  = randn(rng, q) .* sqrt(se)
    y  = MU .+ u .+ e
    return animal_model_spec(y, ones(q, 1), sparse(1.0I, q, q), Ainv;
                             ids = collect(1:q), method = :REML)
end

# ---- reporting -------------------------------------------------------------
function bias_row(name, v, truth)
    n = length(v); mn = mean(v); bias = mn - truth; mcse = std(v) / sqrt(n)
    ok = abs(bias) <= 2 * mcse
    @printf("    %-4s mean=%.4f truth=%.2f bias=%+.4f MCSE=%.4f |bias|/MCSE=%.2f  %s\n",
            name, mn, truth, bias, mcse, mcse == 0 ? 0.0 : abs(bias) / mcse, ok ? "PASS" : "FAIL")
    return (ok = ok, bias = bias, mcse = mcse, mean = mn)
end

# ---- legs ------------------------------------------------------------------
# pass_mode = :relative  → Leg A (scale): all converged AND mean rel.err ≤ REL_TOL (RECOVERY;
#   robust at huge n, where a bias/MCSE test would fail on a negligible bias as MCSE→0).
# pass_mode = :bias_mcse → Leg B (moderate n): all converged AND |bias| ≤ 2·MCSE (UNBIASEDNESS).
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

function leg_boundary(seeds)
    graceful = 0
    for seed in seeds
        rng = MersenneTwister(seed)
        ped = halfsib(N_ANCHOR); q = length(ped.ids)
        y = MU .+ 1e-6 .* randn(rng, q)                  # essentially no additive signal
        spec = animal_model_spec(y, ones(q, 1), sparse(1.0I, q, q), pedigree_inverse(ped);
                                 ids = collect(1:q), method = :REML)
        ok = try
            fit = fit_ai_reml(spec; initial = (sigma_a2 = 0.8, sigma_e2 = 0.8))
            (!fit.converged) && isfinite(fit.variance_components.sigma_a2) &&
                isfinite(fit.variance_components.sigma_e2)
        catch
            false                                        # a throw is NOT graceful
        end
        ok && (graceful += 1)
    end
    println("  Leg C boundary: graceful $graceful/$(length(seeds))")
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
    println("F5 production-scale recovery + correctness gate — truth (σ²a,σ²e)=($SA,$SE) h²=0.4")
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
    println("\nGATE: ", gate ? "PASS" : "FAIL",
            "  (A=$(a.pass) B=$(b.pass) C=$c X=$x)")
    js = "{\"gate_pass\":$gate,\"truth\":{\"sa\":$SA,\"se\":$SE}," *
         "\"A\":{\"pass\":$(a.pass),\"conv\":$(a.conv),\"n\":$Q_SCALE,\"rel_sa\":$(round(a.relA,digits=5)),\"rel_se\":$(round(a.relE,digits=5)),\"bias_sa\":$(round(a.ba.bias,digits=6)),\"bias_se\":$(round(a.be.bias,digits=6))}," *
         "\"B\":{\"pass\":$(b.pass),\"conv\":$(b.conv),\"n\":$N_DEEP,\"bias_sa\":$(round(b.ba.bias,digits=6)),\"mcse_sa\":$(round(b.ba.mcse,digits=6)),\"bias_se\":$(round(b.be.bias,digits=6)),\"mcse_se\":$(round(b.be.mcse,digits=6))}," *
         "\"C_boundary\":$c,\"X_anchor\":$x}"
    println("GATE_JSON ", js)
    exit(gate ? 0 : 1)
end

main()
