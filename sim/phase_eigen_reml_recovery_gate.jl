using HSquared
using LinearAlgebra
using SparseArrays
using Printf
using Random
using Statistics

# Pre-declared bias/MCSE recovery gate for the one-factorization eigen single-effect REML
# estimator (`fit_eigen_reml`, EMMA/GEMMA canonical transform) — the doc-33 path-(b) / doc-16
# substitutable G11 recovery leg for a POSSIBLE V1-EIGEN-REML experimental→covered close. It
# promotes NOTHING on its own: covered additionally needs the same-estimand external REML
# comparator (sommer), a real Rose audit (G8), and maintainer sign-off (G10). Deliberately
# outside test/ so the suite stays RNG-free.
#
# WHY TWO ARMS. `fit_eigen_reml` is fill-in-INDEPENDENT and exists to win on HIGH-FILL,
# moderate-n, Z=I pedigrees (dense O(n^3), no selected inverse). A recovery gate must therefore
# show recovery IN that regime, not only where `:auto` would instead pick sparse AI-REML. So the
# gate has two pre-declared pedigree arms built by the SAME builder as the routing test
# (test/runtests.jl), parameterized by `window`:
#   * Arm WS (well-structured): window=50  → low fill (nnz(L)/n ≈ 17-19; :auto → sparse AI-REML)
#   * Arm HF (high-fill):       window=0   → high fill (nnz(L)/n ≥ 76;  :auto → eigen-once)
# In BOTH arms the gate fits eigen-once AND sparse AI-REML on identical data and checks (a) eigen
# recovers the known truth and (b) eigen ≈ AI-REML per seed (the substitutability corroboration).
#
# PRE-DECLARED (see docs/dev-log/recovery-checkpoints/
# 2026-07-24-eigen-reml-recovery-gate-predeclaration.md, committed BEFORE this runs):
#   - DGP (single-effect Gaussian animal model, Z = I_n, one record per animal): breeding values
#     drawn with EXACT covariance σ²a·A via u = √σ²a · chol(A).L · z (A = inv(Ainv)); residual
#     e ~ N(0, σ²e·I); y = μ + u + e. truth (σ²a, σ²e) = (1.0, 1.5) → h² = 0.4, μ = 2.0, n = 1000.
#     Interior, off-boundary (no σ→0). Pedigree per the `window` builder above.
#   - Seeds: Arm WS 20267000..20267047, Arm HF 20267100..20267147 (48 cold-start each, disjoint
#     from each other and from all prior gates; UNSEEN at declaration time).
#   - PASS criteria (ALL required; NO post-hoc relaxation), for EACH arm:
#       1. eigen: 48/48 converged
#       2. AI-REML: 48/48 converged   (so the agreement below is over the full 48)
#       3. |bias| ≤ 2·MCSE for eigen σ²a AND eigen σ²e   (bias = mean − truth; MCSE = sd/√48)
#       4. max over seeds of eigen-vs-AI-REML rel. diff ≤ 1e-6 for σ²a AND σ²e
#     Overall GATE = (Arm WS PASS) AND (Arm HF PASS).
#   - Read as: NO DETECTABLE across-seed bias (a low-power non-rejection), never "unbiased".
#     A failure is a banked negative — V1-EIGEN-REML stays partial, public_covered_count stays 5.
#
#   env OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase_eigen_reml_recovery_gate.jl

const MU, SA, SE = 2.0, 1.0, 1.5           # truth: h² = SA/(SA+SE) = 0.4
const N = 1000
const AGREE_TOL = 1e-6
const SEEDS_WS = 20267000:20267047         # well-structured arm (window = 50)
const SEEDS_HF = 20267100:20267147         # high-fill arm       (window = 0)
const WINDOW_WS = 50
const WINDOW_HF = 0

# Build a single-effect Z=I animal-model spec with KNOWN truth (σ²a, σ²e). `window` controls
# pedigree bandwidth (fill-in), matching the routing test's `_ped`. Exact σ²a·A covariance via
# the dense Cholesky of A = inv(Ainv), so the recovery target is exact regardless of inbreeding.
function _make_spec(n, seed; window, sa, se)
    rng = MersenneTwister(seed)
    s = zeros(Int, n); d = zeros(Int, n)
    for i in 3:n
        lo = window > 0 ? max(1, i - window) : 1
        s[i] = rand(rng, lo:i-1); d[i] = rand(rng, lo:i-1)
        while d[i] == s[i]; d[i] = rand(rng, lo:i-1); end
    end
    Ainv = pedigree_inverse(collect(1:n), s, d)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    LA = cholesky(Symmetric(A)).L
    u = (LA * randn(rng, n)) .* sqrt(sa)          # Cov(u) = sa · A  (exact)
    e = randn(rng, n) .* sqrt(se)
    y = MU .+ u .+ e
    return animal_model_spec(y, ones(n, 1), sparse(1.0I, n, n), Ainv;
                             ids = collect(1:n), method = :REML)
end

# Run one arm over its seed range; return the per-seed vectors and convergence counts.
function _run_arm(seeds, window)
    ea = Float64[]; ee = Float64[]        # eigen σ²a, σ²e
    aa = Float64[]; ae = Float64[]        # AI-REML σ²a, σ²e
    econv = 0; aconv = 0
    da = 0.0; de = 0.0                    # max rel. diff eigen-vs-AI over converged seeds
    for seed in seeds
        spec = _make_spec(N, seed; window = window, sa = SA, se = SE)
        fe = fit_eigen_reml(spec)
        fa = fit_ai_reml(spec; initial = (sigma_a2 = 0.8, sigma_e2 = 0.8))
        fe.converged && (econv += 1)
        fa.converged && (aconv += 1)
        push!(ea, fe.variance_components.sigma_a2); push!(ee, fe.variance_components.sigma_e2)
        push!(aa, fa.variance_components.sigma_a2); push!(ae, fa.variance_components.sigma_e2)
        if fe.converged && fa.converged
            da = max(da, abs(fe.variance_components.sigma_a2 - fa.variance_components.sigma_a2) /
                         abs(fa.variance_components.sigma_a2))
            de = max(de, abs(fe.variance_components.sigma_e2 - fa.variance_components.sigma_e2) /
                         abs(fa.variance_components.sigma_e2))
        end
    end
    return (ea = ea, ee = ee, aa = aa, ae = ae, econv = econv, aconv = aconv, da = da, de = de)
end

# One bias/MCSE row on eigen's estimates; returns (ok, bias, mcse, mean).
function _bias_row(name, v, truth, n)
    mn = mean(v); bias = mn - truth; mcse = std(v) / sqrt(n)
    ok = abs(bias) <= 2 * mcse
    @printf("    %-5s mean=%.4f truth=%.2f bias=%+.4f MCSE=%.4f |bias|/MCSE=%.2f  %s\n",
            name, mn, truth, bias, mcse, mcse == 0 ? 0.0 : abs(bias) / mcse, ok ? "PASS" : "FAIL")
    return (ok = ok, bias = bias, mcse = mcse, mean = mn)
end

function _report_arm(label, seeds, r)
    n = length(seeds)
    println("  Arm $label ($(first(seeds))..$(last(seeds)), n=$N): ",
            "eigen converged $(r.econv)/$n, AI-REML converged $(r.aconv)/$n")
    ba = _bias_row("σ²a", r.ea, SA, n)
    be = _bias_row("σ²e", r.ee, SE, n)
    agree_ok = (r.da <= AGREE_TOL) && (r.de <= AGREE_TOL)
    @printf("    eigen≈AI-REML max rel.diff: σ²a=%.2e σ²e=%.2e  (tol %.0e)  %s\n",
            r.da, r.de, AGREE_TOL, agree_ok ? "PASS" : "FAIL")
    arm_pass = (r.econv == n) && (r.aconv == n) && ba.ok && be.ok && agree_ok
    println("    Arm $label GATE: ", arm_pass ? "PASS" : "FAIL")
    return (pass = arm_pass, ba = ba, be = be, agree_ok = agree_ok)
end

function main()
    println("Eigen single-effect REML bias/MCSE recovery gate — truth (σ²a,σ²e)=($SA,$SE) h²=0.4")
    rws = _run_arm(SEEDS_WS, WINDOW_WS)
    rhf = _run_arm(SEEDS_HF, WINDOW_HF)
    aws = _report_arm("WS", SEEDS_WS, rws)
    ahf = _report_arm("HF", SEEDS_HF, rhf)
    gate = aws.pass && ahf.pass
    println("GATE: ", gate ? "PASS" : "FAIL", "  (WS=$(aws.pass) HF=$(ahf.pass))")
    armjson(lbl, seeds, r, a) =
        "\"$lbl\":{\"pass\":$(a.pass),\"eigen_converged\":$(r.econv),\"ai_converged\":$(r.aconv)," *
        "\"n\":$(length(seeds)),\"sa\":{\"bias\":$(round(a.ba.bias,digits=6)),\"mcse\":$(round(a.ba.mcse,digits=6)),\"mean\":$(round(a.ba.mean,digits=6))}," *
        "\"se\":{\"bias\":$(round(a.be.bias,digits=6)),\"mcse\":$(round(a.be.mcse,digits=6)),\"mean\":$(round(a.be.mean,digits=6))}," *
        "\"max_reldiff_sa\":$(round(r.da,sigdigits=3)),\"max_reldiff_se\":$(round(r.de,sigdigits=3))}"
    js = "{\"gate_pass\":$gate,\"truth\":{\"sa\":$SA,\"se\":$SE},\"arms\":{" *
         armjson("WS", SEEDS_WS, rws, aws) * "," * armjson("HF", SEEDS_HF, rhf, ahf) * "}}"
    println("GATE_JSON ", js)
    exit(gate ? 0 : 1)
end

main()
