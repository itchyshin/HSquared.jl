using HSquared
using LinearAlgebra
using SparseArrays
using Printf
using Random
using Statistics
using Dates

# ============================================================================
# S5 -- `fit_matrix_free_reml` tail-scale known-truth recovery gate.
# OPT-IN, NOT CI, RNG-full. Promotes NOTHING; public_covered_count stays 5.
#
# Implements, EXACTLY, the specification in:
#   docs/dev-log/recovery-checkpoints/2026-08-04-f6-matfree-tail-recovery-predeclaration.md
# That document's own banner: STATUS: DRAFT -- NOT FROZEN at the time this script was written.
# S8 (Totoro/DRAC access) must be granted AND the predeclaration text frozen at a committed commit
# hash BEFORE the FULL gate is ever run against this script. Writing this script is not freezing
# it; do not run the 48+8-seed campaign until that separate freeze step has happened.
#
# WHAT THIS TESTS. `fit_matrix_free_reml` (src/iterative_solve.jl:1010) is the K=1 face of the
# matrix-free Monte-Carlo EM-REML estimator (matrix-free PCG solves + a Hutchinson stochastic
# score trace; the MME coefficient matrix C is never assembled or factorized). It exists for the
# regime F0 measured infeasible for the exact fitter -- high fill-in AND n past the dense-eigen
# cap (n > 20,000) -- and has NEVER been measured there against a KNOWN truth (every existing leg
# compares it to another ESTIMATOR, never to truth, in this regime). This gate adds that evidence.
#
# TWO legs (ALL pass criteria required; NO post-hoc relaxation --
# docs/dev-log/decisions/2026-06-14-calibration-failure-response):
#
#   Leg A (PRIMARY) -- tail-scale recovery: q=25,000 high-fill `adversarial()` pedigree, 48 seeds.
#     THREE-WAY per-fit outcome classification:
#       (a) CONVERGED      -- fit.converged == true
#       (b) CAP_EXHAUSTED   -- graceful (no throw; finite, >=0 sigma), not converged,
#                              fit.iterations == 200 EXACTLY (the pre-declared cap)
#       (c) NON_GRACEFUL    -- threw, or non-finite/negative sigma_a2 or sigma_e2
#     A1 (PRIMARY): mean rel.err vs truth over graceful=(a)∪(b) <= 5% each component.
#     A2: bucket-(c) rate = 0/48.  A3: bucket-(b) rate <= 4/48.
#     Leg A GATE = A1 ∧ A2 ∧ A3.
#
#   Leg X -- estimator-agreement anchor: q=2,000 (N_ANCHOR), SAME high-fill generator, 8 seeds.
#     fit_ai_reml (exact) vs fit_matrix_free_reml (nprobe=64, gating) on the SAME dataset per
#     seed; mean |signed relative difference| (matrix_free-exact)/exact over the 8 seeds <=
#     AGREE_TOL_MC=0.05, both components. Informational-only nprobe=256 arm on the same 8
#     datasets (does not gate). Leg X GATE = that single mean-|reldiff| <= 0.05 condition.
#
#   Overall GATE = Leg A ∧ Leg X.
#
# A FOURTH, TAXONOMY-UNANTICIPATED case is explicitly checked for and reported: a graceful
# (finite, non-negative, no throw), non-converged fit whose `iterations` is NOT exactly the cap
# (200). This is traceable to `fit_multi_effect_mc_reml`'s early-break branch
# (`(all(>(0), newsig) && newe > 0) || break`, src/iterative_solve.jl) firing before the
# iteration cap is reached while leaving `converged = false`. Per the predeclaration this must be
# "logged as an anomaly, not silently folded into (b)": tagged here as `ANOMALY_ITER_MISMATCH`,
# excluded from the a/b/c bucket counts (hence from A1/A2/A3), and printed/recorded loudly. The
# predeclaration states no gating consequence for this bucket; none is invented here -- see the
# accompanying reply for this flagged as owed a maintainer decision.
#
# SMOKE (HSQ_S5_SMOKE=1): Q_TAIL_SMOKE=10,000, 3 Leg-A seeds, N_ANCHOR unchanged=2,000, 2 Leg-X
# seeds. PLUMBING CHECK ONLY, mirroring sim/f6_matfree_recovery.jl's smoke discipline: the real
# A1/A2/A3/Leg-X thresholds are computed and printed for eyeballing but are NOT the SMOKE gate --
# they were calibrated for n=48/n=8 via rule-of-three reasoning that does not transfer to n=3/n=2,
# and asserting them as a real verdict at shrunken n is exactly the bug already found and fixed in
# the sibling driver (a boundary/degenerate case silently misread as a real FAIL or PASS). SMOKE's
# own gate is "did every attempted fit return finite, in-range output, with at least one graceful
# success" -- proving the harness runs end-to-end, not that recovery or agreement holds.
#
#   env HSQ_S5_SMOKE=1 OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase_s5_matfree_tail_recovery_gate.jl smoke_s5.tsv
#   env OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase_s5_matfree_tail_recovery_gate.jl s5_recovery.tsv
# ============================================================================

const SMOKE       = get(ENV, "HSQ_S5_SMOKE", "0") == "1"
const MU, SA, SE   = 5.0, 1.0, 1.0                 # truth: h² = 0.5, interior/off-boundary
const Q_TAIL       = SMOKE ? 10_000 : 25_000
const N_ANCHOR     = 2_000                         # unchanged in SMOKE (locked design)
const REL_TOL      = 0.05                          # A1: mean rel.err vs truth, both components
const AGREE_TOL_MC = 0.05                          # Leg X: mean |rel diff| vs exact, both components
const ITER_CAP     = 200                           # pre-declared cap = function default; NOT raised
const NPROBE_GATE  = 64                            # fit_matrix_free_reml's own default; NOT tuned
const NPROBE_INFO  = 256                           # informational-only add-on arm (Leg X only)
const CAPRESET_ITERS = 1_000                       # informational-only re-fit cap for bucket (b)
const A3_MAX_CAP_EXHAUSTED = 4                     # Leg A: <= 4/48 (~8.3%)
const MC_OFFSET    = 500_000                       # mc_probe_seed = dgp_seed + MC_OFFSET

const SEEDS_A = SMOKE ? (20269500:20269502) : (20269500:20269547)   # 48 full / 3 smoke
const SEEDS_X = SMOKE ? (20269200:20269201) : (20269200:20269207)   #  8 full / 2 smoke

# ---------------------------------------------------------------------------
# DGP -- IDENTICAL copy of sim/drac/f0_adversarial_fill.jl:33-66. Per-script duplication is the
# established convention in this repo (sim/ scripts are standalone programs; they do not
# `include` each other). Do not edit these two functions independently of that source.
# ---------------------------------------------------------------------------

# High-fill pedigree: a small founder base + RANDOM mating -- each non-founder draws 2 distinct
# parents uniformly from ALL earlier individuals. This is the fitter's target regime.
function adversarial(q::Int; nfounder_frac::Float64 = 0.005, seed::Int = 20260724)
    rng = MersenneTwister(seed)
    nf  = max(4, round(Int, nfounder_frac * q))
    ids  = ["a$i" for i in 1:q]
    sire = fill("0", q)
    dam  = fill("0", q)
    @inbounds for i in (nf + 1):q
        p = rand(rng, 1:(i - 1))
        m = rand(rng, 1:(i - 1))
        while m == p
            m = rand(rng, 1:(i - 1))
        end
        sire[i] = ids[p]
        dam[i]  = ids[m]
    end
    return normalize_pedigree(ids, sire, dam)
end

# Gene-dropping (O(q)) breeding values down the topologically-sorted pedigree.
function simulate_y(ped; sigma_a2 = 1.0, sigma_e2 = 1.0, mu = 5.0, seed = 20260724)
    rng = MersenneTwister(seed)
    q = length(ped.ids)
    u = zeros(q)
    @inbounds for i in 1:q
        s = ped.sire[i]; d = ped.dam[i]
        pa = s > 0 ? u[s] : 0.0
        pb = d > 0 ? u[d] : 0.0
        nknown = (s > 0) + (d > 0)
        msv = nknown == 0 ? 1.0 : (nknown == 1 ? 0.75 : 0.5)
        u[i] = 0.5 * (pa + pb) + sqrt(sigma_a2 * msv) * randn(rng)
    end
    return mu .+ u .+ sqrt(sigma_e2) .* randn(rng, q)
end

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Fill = nnz(L)/n of the (variance-independent) MME Cholesky -- IDENTICAL metric/approach to
# sim/drac/f0_adversarial_fill.jl:78-81 and the `:auto` router's own metric.
function measure_fill(spec, q::Int)
    lhs, _, _ = HSquared._sparse_mme_system(spec, 1.0, 1.0)
    chf = cholesky(Symmetric(lhs); check = true)
    return nnz(sparse(chf.L)) / q
end

# Three(+one)-way outcome classification for one fit_matrix_free_reml attempt, exactly per the
# predeclaration's Leg A taxonomy (also reused for both Leg X nprobe arms, per the "record
# fit.iterations for every attempted fit (Leg A AND Leg X, both nprobe arms)" requirement).
#   (a) CONVERGED         -- fit.converged == true (independently re-checked for gracefulness)
#   (b) CAP_EXHAUSTED       -- graceful, not converged, iterations == cap EXACTLY
#   (c) NON_GRACEFUL        -- threw, OR non-finite/negative sigma_a2/sigma_e2
#   ANOMALY_ITER_MISMATCH   -- graceful, not converged, iterations != cap -- see file header;
#                              NOT one of the predeclaration's three named buckets.
# All other keywords (tol, pcg_tol, pcg_maxiter, shared_probes, compute_loglik) are left at
# fit_matrix_free_reml's own defaults throughout -- "no tuning to pass".
function classify_matfree(spec, mc_seed::Integer; nprobe::Integer, cap::Integer = ITER_CAP)
    sa2 = NaN; se2 = NaN; converged = false; iters = -1; threw = false
    try
        fit = fit_matrix_free_reml(spec; nprobe = nprobe,
                                    initial = (sigma_a2 = 0.8, sigma_e2 = 0.8),
                                    seed = mc_seed)
        converged = fit.converged
        iters = fit.iterations
        sa2 = fit.variance_components.sigma_a2
        se2 = fit.variance_components.sigma_e2
    catch
        threw = true
    end
    graceful = !threw && isfinite(sa2) && isfinite(se2) && sa2 >= 0 && se2 >= 0
    outcome = if threw || !graceful
        :NON_GRACEFUL
    elseif converged
        :CONVERGED
    elseif iters == cap
        :CAP_EXHAUSTED
    else
        :ANOMALY_ITER_MISMATCH
    end
    return (outcome = outcome, converged = converged, iterations = iters,
            sigma_a2 = sa2, sigma_e2 = se2, threw = threw)
end

# Empty/singleton-safe mean/bias/MCSE/rel.err report (mean()/std() already return NaN, not throw,
# on empty/singleton Float64 vectors in this Julia -- guarded explicitly anyway for clarity).
function bias_row(name, v::Vector{Float64}, truth::Float64)
    n = length(v)
    mn = isempty(v) ? NaN : mean(v)
    bias = mn - truth
    mcse = n > 1 ? std(v) / sqrt(n) : NaN
    relerr = abs(bias) / abs(truth)
    @printf("    %-10s n=%-3d mean=%.4f truth=%.2f bias=%+.4f MCSE=%.4f rel.err=%.4f\n",
            name, n, mn, truth, bias, mcse, relerr)
    return (n = n, mean = mn, bias = bias, mcse = mcse, relerr = relerr)
end

# min/median/max, empty-safe (minimum/maximum/median all throw ArgumentError/MethodError on an
# empty collection; mean/std do not, but are guarded above too).
function mmm(v::Vector{<:Real})
    isempty(v) ? (NaN, NaN, NaN) : (Float64(minimum(v)), Float64(median(v)), Float64(maximum(v)))
end

# ---------------------------------------------------------------------------
# Leg A -- tail-scale recovery (PRIMARY)
# ---------------------------------------------------------------------------

function leg_a()
    n = length(SEEDS_A)
    println("\n=== Leg A: tail-scale recovery (PRIMARY) -- q=$Q_TAIL, high fill, $n seed(s) ===")

    outcomes = Vector{Symbol}(undef, n)
    itersv   = Vector{Int}(undef, n)
    sa2v     = Vector{Float64}(undef, n)
    se2v     = Vector{Float64}(undef, n)
    fillv    = Vector{Float64}(undef, n)
    wallv    = Vector{Float64}(undef, n)
    cr_sa2   = fill(NaN, n)
    cr_se2   = fill(NaN, n)
    cr_conv  = fill(false, n)
    cr_done  = falses(n)
    rows     = String[]

    for (k, dgp_seed) in enumerate(SEEDS_A)
        mc_seed = dgp_seed + MC_OFFSET

        ped  = adversarial(Q_TAIL; seed = dgp_seed)
        q    = length(ped.ids)
        y    = simulate_y(ped; sigma_a2 = SA, sigma_e2 = SE, mu = MU, seed = dgp_seed)
        Ainv = pedigree_inverse(ped)
        spec = animal_model_spec(y, ones(q, 1), sparse(1.0I, q, q), Ainv; method = :REML)

        fillv[k] = measure_fill(spec, q)

        t0 = time()
        cls = classify_matfree(spec, mc_seed; nprobe = NPROBE_GATE)
        wallv[k] = time() - t0

        outcomes[k] = cls.outcome; itersv[k] = cls.iterations
        sa2v[k] = cls.sigma_a2; se2v[k] = cls.sigma_e2

        rel_sa = abs(cls.sigma_a2 - SA) / SA
        rel_se = abs(cls.sigma_e2 - SE) / SE

        @printf("  A %2d/%2d dgp=%d mc=%d outcome=%-22s conv=%-5s iters=%3d sigma_a2=%.4f sigma_e2=%.4f fill=%.1f wall=%.2fs\n",
                k, n, dgp_seed, mc_seed, cls.outcome, cls.converged, cls.iterations,
                cls.sigma_a2, cls.sigma_e2, fillv[k], wallv[k])
        flush(stdout)

        if cls.outcome === :ANOMALY_ITER_MISMATCH
            println("    *** ANOMALY_ITER_MISMATCH: graceful, converged=false, iterations=$(cls.iterations) != cap=$ITER_CAP.")
            println("        Third failure mechanism per predeclaration -- NOT folded into CAP_EXHAUSTED, excluded from A1/A2/A3.")
        end

        if cls.outcome === :CAP_EXHAUSTED
            cr_done[k] = true
            try
                fit1000 = fit_matrix_free_reml(spec; nprobe = NPROBE_GATE,
                                                initial = (sigma_a2 = 0.8, sigma_e2 = 0.8),
                                                seed = mc_seed, iterations = CAPRESET_ITERS)
                cr_sa2[k] = fit1000.variance_components.sigma_a2
                cr_se2[k] = fit1000.variance_components.sigma_e2
                cr_conv[k] = fit1000.converged
                @printf("    capreset(iterations=%d) [informational, non-gating]: conv=%s sigma_a2=%.4f sigma_e2=%.4f\n",
                        CAPRESET_ITERS, fit1000.converged, cr_sa2[k], cr_se2[k])
            catch err
                @printf("    capreset(iterations=%d): THREW %s -- recorded as NaN/false\n", CAPRESET_ITERS, typeof(err))
            end
        end

        capreset_field = cr_done[k] ? @sprintf("%.6f\t%.6f\t%s", cr_sa2[k], cr_se2[k], cr_conv[k]) : "\t\t"
        row = @sprintf("%d\t%d\t%d\t%s\t%s\t%d\t%.6f\t%.6f\t%.6f\t%.6f\t%.3f\t%.3f\t",
                        k, dgp_seed, mc_seed, cls.outcome, cls.converged, cls.iterations,
                        cls.sigma_a2, cls.sigma_e2, rel_sa, rel_se, fillv[k], wallv[k])
        push!(rows, row * capreset_field)
    end

    n_converged     = count(o -> o === :CONVERGED, outcomes)
    n_cap_exhausted = count(o -> o === :CAP_EXHAUSTED, outcomes)
    n_non_graceful  = count(o -> o === :NON_GRACEFUL, outcomes)
    n_anomaly       = count(o -> o === :ANOMALY_ITER_MISMATCH, outcomes)

    graceful_idx  = findall(o -> o === :CONVERGED || o === :CAP_EXHAUSTED, outcomes)
    converged_idx = findall(o -> o === :CONVERGED, outcomes)

    println("\n  bucket counts: CONVERGED=$n_converged  CAP_EXHAUSTED=$n_cap_exhausted  NON_GRACEFUL=$n_non_graceful  ANOMALY_ITER_MISMATCH=$n_anomaly  (of $n)")

    println("  [A1 graceful=(a)∪(b) subset, n=$(length(graceful_idx))]")
    ba = bias_row("sigma_a2", sa2v[graceful_idx], SA)
    be = bias_row("sigma_e2", se2v[graceful_idx], SE)

    println("  [A1 converged-only (a) subset, n=$(length(converged_idx)) -- INFORMATIONAL, not gating]")
    bac = bias_row("sigma_a2", sa2v[converged_idx], SA)
    bec = bias_row("sigma_e2", se2v[converged_idx], SE)

    pass_A1 = !isempty(graceful_idx) && ba.relerr <= REL_TOL && be.relerr <= REL_TOL
    pass_A2 = n_non_graceful == 0
    pass_A3 = n_cap_exhausted <= A3_MAX_CAP_EXHAUSTED
    real_pass = pass_A1 && pass_A2 && pass_A3

    @printf("  A1 mean rel.err (graceful, PRIMARY): sigma_a2=%.4f sigma_e2=%.4f (tol %.2f)  %s\n",
            ba.relerr, be.relerr, REL_TOL, pass_A1 ? "PASS" : "FAIL")
    @printf("  A2 non-graceful rate: %d/%d (bound 0)  %s\n", n_non_graceful, n, pass_A2 ? "PASS" : "FAIL")
    @printf("  A3 cap-exhaustion rate: %d/%d (bound <= %d)  %s\n", n_cap_exhausted, n, A3_MAX_CAP_EXHAUSTED, pass_A3 ? "PASS" : "FAIL")
    if n_anomaly > 0
        println("  *** $n_anomaly seed(s) landed in ANOMALY_ITER_MISMATCH -- excluded from A1/A2/A3 above.")
        println("      The predeclaration states no gating consequence for this bucket; none is invented here.")
    end

    iters_for_dist = itersv[findall(x -> x != -1, itersv)]   # exclude literal throws (no iterations returned)
    (imin, imed, imax) = mmm(iters_for_dist)
    @printf("  iterations distribution (attempted, non-throw, n=%d): min=%.0f median=%.1f max=%.0f (cap=%d)\n",
            length(iters_for_dist), imin, imed, imax, ITER_CAP)

    fill_mean = isempty(fillv) ? NaN : mean(fillv)
    (fmin, _, fmax) = mmm(fillv)
    @printf("  fill (nnz(L)/n) across seeds: mean=%.1f min=%.1f max=%.1f\n", fill_mean, fmin, fmax)

    plumbing_ok = all(isfinite, fillv) && all(>(0), fillv) && !isempty(graceful_idx)
    pass = SMOKE ? plumbing_ok : real_pass
    if SMOKE
        @printf("  Leg A [SMOKE -- PLUMBING CHECK ONLY, NOT the pre-declared verdict]: finite positive fill + >=1 graceful fit: %s\n",
                plumbing_ok ? "PASS" : "FAIL")
        println("    (A1/A2/A3 above are informational only at n=$n; the pre-declared bounds were calibrated for n=48 via rule-of-three reasoning that does not transfer here.)")
    else
        println("  Leg A GATE (A1 ∧ A2 ∧ A3): ", real_pass ? "PASS" : "FAIL")
    end

    header = "seed\tdgp_seed\tmc_seed\toutcome\tconverged\titerations\tsigma_a2\tsigma_e2\trel_err_sa2\trel_err_se2\tfill\twall_s\tcapreset_iterations1000_sigma_a2\tcapreset_iterations1000_sigma_e2\tcapreset_iterations1000_converged"

    return (pass = pass, pass_A1 = pass_A1, pass_A2 = pass_A2, pass_A3 = pass_A3,
            n = n, n_converged = n_converged, n_cap_exhausted = n_cap_exhausted,
            n_non_graceful = n_non_graceful, n_anomaly = n_anomaly,
            rel_sa = ba.relerr, rel_se = be.relerr,
            rel_sa_converged_only = bac.relerr, rel_se_converged_only = bec.relerr,
            bias_sa = ba.bias, mcse_sa = ba.mcse, bias_se = be.bias, mcse_se = be.mcse,
            q = Q_TAIL, fill_measured = fill_mean,
            iters_min = imin, iters_median = imed, iters_max = imax,
            header = header, rows = rows)
end

# ---------------------------------------------------------------------------
# Leg X -- estimator-agreement anchor
# ---------------------------------------------------------------------------

function leg_x()
    n = length(SEEDS_X)
    println("\n=== Leg X: estimator-agreement anchor -- q=$N_ANCHOR, high fill, $n seed(s) ===")

    outcomes64  = Vector{Symbol}(undef, n)
    outcomes256 = Vector{Symbol}(undef, n)
    iters64     = Vector{Int}(undef, n)
    iters256    = Vector{Int}(undef, n)
    ex_sa2v    = Vector{Float64}(undef, n); ex_se2v    = Vector{Float64}(undef, n)
    mf64_sa2v  = Vector{Float64}(undef, n); mf64_se2v  = Vector{Float64}(undef, n)
    mf256_sa2v = Vector{Float64}(undef, n); mf256_se2v = Vector{Float64}(undef, n)
    rd64_sa  = Vector{Float64}(undef, n); rd64_se  = Vector{Float64}(undef, n)
    rd256_sa = Vector{Float64}(undef, n); rd256_se = Vector{Float64}(undef, n)
    rows = String[]

    for (k, dgp_seed) in enumerate(SEEDS_X)
        # SAME mc seed reused for the nprobe=64 and nprobe=256 arms: the predeclaration's Seeds
        # section pre-declares exactly ONE MC-probe formula for Leg X (DGP+500,000); reusing it
        # for both arms isolates the effect of nprobe alone (see reply for this interpretation).
        mc_seed = dgp_seed + MC_OFFSET

        ped  = adversarial(N_ANCHOR; seed = dgp_seed)
        q    = length(ped.ids)
        y    = simulate_y(ped; sigma_a2 = SA, sigma_e2 = SE, mu = MU, seed = dgp_seed)
        Ainv = pedigree_inverse(ped)
        spec = animal_model_spec(y, ones(q, 1), sparse(1.0I, q, q), Ainv; method = :REML)

        exact = fit_ai_reml(spec; initial = (sigma_a2 = 0.8, sigma_e2 = 0.8))
        ex_sa2v[k] = exact.variance_components.sigma_a2
        ex_se2v[k] = exact.variance_components.sigma_e2

        cls64  = classify_matfree(spec, mc_seed; nprobe = NPROBE_GATE)
        cls256 = classify_matfree(spec, mc_seed; nprobe = NPROBE_INFO)
        outcomes64[k]  = cls64.outcome;  iters64[k]  = cls64.iterations
        outcomes256[k] = cls256.outcome; iters256[k] = cls256.iterations
        mf64_sa2v[k]  = cls64.sigma_a2;  mf64_se2v[k]  = cls64.sigma_e2
        mf256_sa2v[k] = cls256.sigma_a2; mf256_se2v[k] = cls256.sigma_e2

        # Boundary-safe SIGNED relative difference: (matrix_free - exact)/exact. "On the boundary"
        # is judged RELATIVE TO TRAIT SCALE (total_var), not absolutely -- reused verbatim from
        # sim/f6_matfree_recovery.jl's on_boundary/safe_rel pattern (2026-08-04 fix for exactly
        # this failure mode: a near-zero comparator collapses the denominator into a garbage
        # number, e.g. measured rel.err=980 there). ALSO guarded here against a non-graceful
        # matrix-free NUMERATOR, which that upstream pattern does not need to cover (its numerator
        # is always graceful by fixture construction; here it can be NON_GRACEFUL by definition).
        total_var = ex_sa2v[k] + ex_se2v[k]
        on_boundary(e) = abs(e) <= 1e-4 * max(total_var, eps())
        safe_rel(outcome, m, e) = (outcome === :NON_GRACEFUL || on_boundary(e)) ? NaN : (m - e) / e

        rd64_sa[k]  = safe_rel(cls64.outcome, cls64.sigma_a2, ex_sa2v[k])
        rd64_se[k]  = safe_rel(cls64.outcome, cls64.sigma_e2, ex_se2v[k])
        rd256_sa[k] = safe_rel(cls256.outcome, cls256.sigma_a2, ex_sa2v[k])
        rd256_se[k] = safe_rel(cls256.outcome, cls256.sigma_e2, ex_se2v[k])

        @printf("  X %d/%d dgp=%d mc=%d  exact sigma_a2=%.4f sigma_e2=%.4f | mf64 outcome=%s sigma_a2=%.4f sigma_e2=%.4f | mf256 outcome=%s sigma_a2=%.4f sigma_e2=%.4f\n",
                k, n, dgp_seed, mc_seed, ex_sa2v[k], ex_se2v[k],
                cls64.outcome, cls64.sigma_a2, cls64.sigma_e2,
                cls256.outcome, cls256.sigma_a2, cls256.sigma_e2)
        anomaly_note = (isnan(rd64_sa[k]) || isnan(rd64_se[k])) ?
            "  [ANOMALY: exact estimate on variance boundary, or mf64 non-graceful -- NaN, not a FAIL]" : ""
        @printf("      reldiff64: sa2=%.4f se2=%.4f | reldiff256: sa2=%.4f se2=%.4f%s\n",
                rd64_sa[k], rd64_se[k], rd256_sa[k], rd256_se[k], anomaly_note)
        flush(stdout)

        row = @sprintf("%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f",
                        k, dgp_seed, mc_seed, mc_seed, cls64.outcome, cls256.outcome,
                        cls64.iterations, cls256.iterations,
                        ex_sa2v[k], ex_se2v[k], cls64.sigma_a2, cls64.sigma_e2,
                        cls256.sigma_a2, cls256.sigma_e2,
                        rd64_sa[k], rd64_se[k], rd256_sa[k], rd256_se[k])
        push!(rows, row)
    end

    function summarize(rd)
        valid = filter(x -> !isnan(x), rd)
        (mean_abs = isempty(valid) ? NaN : mean(abs.(valid)),
         sd = length(valid) > 1 ? std(valid) : NaN,
         max_abs = isempty(valid) ? NaN : maximum(abs.(valid)),
         n_used = length(valid), n_excluded = length(rd) - length(valid))
    end

    s64_sa  = summarize(rd64_sa);  s64_se  = summarize(rd64_se)
    s256_sa = summarize(rd256_sa); s256_se = summarize(rd256_se)

    println("\n  [nprobe=$NPROBE_GATE, GATING] reldiff summary (mean of |.|, over n_used non-anomalous seeds):")
    @printf("    sigma_a2: mean|.|=%.4f sd=%.4f max|.|=%.4f  (n_used=%d, excluded=%d)\n",
            s64_sa.mean_abs, s64_sa.sd, s64_sa.max_abs, s64_sa.n_used, s64_sa.n_excluded)
    @printf("    sigma_e2: mean|.|=%.4f sd=%.4f max|.|=%.4f  (n_used=%d, excluded=%d)\n",
            s64_se.mean_abs, s64_se.sd, s64_se.max_abs, s64_se.n_used, s64_se.n_excluded)
    println("  [nprobe=$NPROBE_INFO, INFORMATIONAL ONLY -- does not gate] reldiff summary:")
    @printf("    sigma_a2: mean|.|=%.4f (n_used=%d, excluded=%d)\n", s256_sa.mean_abs, s256_sa.n_used, s256_sa.n_excluded)
    @printf("    sigma_e2: mean|.|=%.4f (n_used=%d, excluded=%d)\n", s256_se.mean_abs, s256_se.n_used, s256_se.n_excluded)

    real_pass = !isnan(s64_sa.mean_abs) && !isnan(s64_se.mean_abs) &&
                s64_sa.mean_abs <= AGREE_TOL_MC && s64_se.mean_abs <= AGREE_TOL_MC

    (imin64, imed64, imax64)    = mmm(iters64[findall(x -> x != -1, iters64)])
    (imin256, imed256, imax256) = mmm(iters256[findall(x -> x != -1, iters256)])
    @printf("  iterations distribution nprobe=%d  (n=%d): min=%.0f median=%.1f max=%.0f\n", NPROBE_GATE, n, imin64, imed64, imax64)
    @printf("  iterations distribution nprobe=%d (n=%d): min=%.0f median=%.1f max=%.0f\n", NPROBE_INFO, n, imin256, imed256, imax256)

    n_ng64  = count(o -> o === :NON_GRACEFUL, outcomes64)
    n_ng256 = count(o -> o === :NON_GRACEFUL, outcomes256)
    n_an64  = count(o -> o === :ANOMALY_ITER_MISMATCH, outcomes64)
    n_an256 = count(o -> o === :ANOMALY_ITER_MISMATCH, outcomes256)
    if n_ng64 + n_an64 + n_ng256 + n_an256 > 0
        println("  note: nprobe=$NPROBE_GATE non-CONVERGED/CAP_EXHAUSTED -- NON_GRACEFUL=$n_ng64 ANOMALY=$n_an64; nprobe=$NPROBE_INFO -- NON_GRACEFUL=$n_ng256 ANOMALY=$n_an256 (these seeds' reldiff is NaN/excluded above, never silently averaged in)")
    end

    plumbing_ok = all(isfinite, ex_sa2v) && all(isfinite, ex_se2v) && (s64_sa.n_used > 0) && (s64_se.n_used > 0)
    pass = SMOKE ? plumbing_ok : real_pass
    if SMOKE
        @printf("  Leg X [SMOKE -- PLUMBING CHECK ONLY, NOT the pre-declared verdict]: finite exact fits + >=1 usable reldiff each component: %s\n",
                plumbing_ok ? "PASS" : "FAIL")
        println("    (AGREE_TOL_MC comparison above is informational only at n=$n.)")
    else
        println("  Leg X GATE (mean|reldiff| <= $AGREE_TOL_MC at nprobe=$NPROBE_GATE, both components): ", real_pass ? "PASS" : "FAIL")
    end

    header = "seed\tdgp_seed\tmc_seed64\tmc_seed256\toutcome64\toutcome256\titerations64\titerations256\tex_sa2\tex_se2\tmf64_sa2\tmf64_se2\tmf256_sa2\tmf256_se2\treldiff64_sa2\treldiff64_se2\treldiff256_sa2\treldiff256_se2"

    return (pass = pass, n = n, nprobe = NPROBE_GATE,
            mean_reldiff_sa = s64_sa.mean_abs, mean_reldiff_se = s64_se.mean_abs,
            sd_reldiff_sa = s64_sa.sd, sd_reldiff_se = s64_se.sd,
            max_reldiff_sa = s64_sa.max_abs, max_reldiff_se = s64_se.max_abs,
            nprobe256_mean_reldiff_sa = s256_sa.mean_abs, nprobe256_mean_reldiff_se = s256_se.mean_abs,
            iters_min = imin64, iters_median = imed64, iters_max = imax64,
            nprobe256_iters_min = imin256, nprobe256_iters_median = imed256, nprobe256_iters_max = imax256,
            header = header, rows = rows)
end

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

function main()
    outpath = length(ARGS) >= 1 ? ARGS[1] : "s5_matfree_tail_recovery.tsv"

    println("HSquared.jl S5 matrix-free tail-scale known-truth recovery gate  ", Dates.now())
    println("host=", gethostname(), " julia=", VERSION, " threads=", Threads.nthreads(),
            " OPENBLAS_NUM_THREADS=", get(ENV, "OPENBLAS_NUM_THREADS", "unset"), " SMOKE=", SMOKE)
    println("truth: mu=$MU sigma_a2=$SA sigma_e2=$SE (h2=0.5)  Q_TAIL=$Q_TAIL  N_ANCHOR=$N_ANCHOR  iterations_cap=$ITER_CAP")
    println("Leg A seeds (dgp): $(first(SEEDS_A)):$(last(SEEDS_A))  n=$(length(SEEDS_A))")
    println("Leg X seeds (dgp): $(first(SEEDS_X)):$(last(SEEDS_X))  n=$(length(SEEDS_X))")

    a = leg_a()
    x = leg_x()

    gate = a.pass && x.pass
    println("\nOVERALL GATE: ", gate ? "PASS" : "FAIL", "  (LegA=$(a.pass) LegX=$(x.pass))",
            SMOKE ? "  [SMOKE -- plumbing check only, NOT the pre-declared 48+8-seed verdict]" : "")

    truth_json = "{\"mu\":$MU,\"sa\":$SA,\"se\":$SE}"
    a_json = "{\"pass\":$(a.pass),\"pass_A1\":$(a.pass_A1),\"pass_A2\":$(a.pass_A2),\"pass_A3\":$(a.pass_A3)," *
             "\"n_converged\":$(a.n_converged),\"n_cap_exhausted\":$(a.n_cap_exhausted),\"n_non_graceful\":$(a.n_non_graceful)," *
             "\"n_anomaly_iter_mismatch\":$(a.n_anomaly)," *
             "\"rel_sa\":$(round(a.rel_sa,digits=6)),\"rel_se\":$(round(a.rel_se,digits=6))," *
             "\"rel_sa_converged_only\":$(round(a.rel_sa_converged_only,digits=6)),\"rel_se_converged_only\":$(round(a.rel_se_converged_only,digits=6))," *
             "\"bias_sa\":$(round(a.bias_sa,digits=6)),\"mcse_sa\":$(round(a.mcse_sa,digits=6))," *
             "\"bias_se\":$(round(a.bias_se,digits=6)),\"mcse_se\":$(round(a.mcse_se,digits=6))," *
             "\"q\":$(a.q),\"fill_measured\":$(round(a.fill_measured,digits=2))," *
             "\"iters_min\":$(a.iters_min),\"iters_median\":$(a.iters_median),\"iters_max\":$(a.iters_max)}"
    x_json = "{\"pass\":$(x.pass),\"n\":$(x.n),\"nprobe\":$(x.nprobe)," *
             "\"mean_reldiff_sa\":$(round(x.mean_reldiff_sa,digits=6)),\"mean_reldiff_se\":$(round(x.mean_reldiff_se,digits=6))," *
             "\"sd_reldiff_sa\":$(round(x.sd_reldiff_sa,digits=6)),\"sd_reldiff_se\":$(round(x.sd_reldiff_se,digits=6))," *
             "\"max_reldiff_sa\":$(round(x.max_reldiff_sa,digits=6)),\"max_reldiff_se\":$(round(x.max_reldiff_se,digits=6))," *
             "\"nprobe256_mean_reldiff_sa\":$(round(x.nprobe256_mean_reldiff_sa,digits=6)),\"nprobe256_mean_reldiff_se\":$(round(x.nprobe256_mean_reldiff_se,digits=6))," *
             "\"iters_min\":$(x.iters_min),\"iters_median\":$(x.iters_median),\"iters_max\":$(x.iters_max)," *
             "\"nprobe256_iters_min\":$(x.nprobe256_iters_min),\"nprobe256_iters_median\":$(x.nprobe256_iters_median),\"nprobe256_iters_max\":$(x.nprobe256_iters_max)}"

    gate_json = "{\"gate_pass\":$gate,\"version\":\"s5-draft-v2\",\"smoke\":$SMOKE,\"truth\":$truth_json,\"iterations_cap\":$ITER_CAP,\"A\":$a_json,\"X\":$x_json}"
    println("GATE_JSON ", gate_json)

    manifest = String[
        "# HSquared.jl S5 matrix-free tail-scale known-truth recovery gate  $(Dates.now())",
        "# host=$(gethostname())  julia=$(VERSION)  threads=$(Threads.nthreads())  OPENBLAS_NUM_THREADS=$(get(ENV,"OPENBLAS_NUM_THREADS","unset"))  SMOKE=$SMOKE",
        "# julia=VERSION is load-bearing, not decorative: a MersenneTwister stream is not assumed portable across Julia versions for this fixture (Slice-B finding).",
        "# Q_TAIL=$Q_TAIL  N_ANCHOR=$N_ANCHOR  iterations_cap=$ITER_CAP  nprobe_gate=$NPROBE_GATE  nprobe_info=$NPROBE_INFO  capreset_iterations=$CAPRESET_ITERS",
        "# Leg A seeds: dgp=$(first(SEEDS_A)):$(last(SEEDS_A)) (n=$(length(SEEDS_A)))  mc=dgp+$MC_OFFSET",
        "# Leg X seeds: dgp=$(first(SEEDS_X)):$(last(SEEDS_X)) (n=$(length(SEEDS_X)))  mc=dgp+$MC_OFFSET (SAME mc seed reused for nprobe=64 and nprobe=256 arms)",
        "# truth: mu=$MU sigma_a2=$SA sigma_e2=$SE (h2=0.5, interior/off-boundary)",
        "# PRIMARY (Leg A, pre-declared, GATE=A1∧A2∧A3): A1 mean rel.err vs truth over graceful=(CONVERGED∪CAP_EXHAUSTED) seeds <= $REL_TOL each component; A2 NON_GRACEFUL count = 0 (bound calibrated for the full n=48 run); A3 CAP_EXHAUSTED count <= $A3_MAX_CAP_EXHAUSTED (bound calibrated for the full n=48 run). This run's actual n=$(length(SEEDS_A)).",
        "# SECONDARY/informational (Leg A): bias, MCSE, converged-only-subset A1, iterations-to-outcome min/median/max, capreset(iterations=$CAPRESET_ITERS) re-fit for CAP_EXHAUSTED seeds, ANOMALY_ITER_MISMATCH count (unanticipated third failure mechanism, no gating consequence declared in the predeclaration).",
        "# PRIMARY (Leg X, pre-declared, GATE): mean |signed relative difference| (matrix_free-exact)/exact across $(length(SEEDS_X)) seeds <= AGREE_TOL_MC=$AGREE_TOL_MC for sigma_a2 AND sigma_e2, at nprobe=$NPROBE_GATE (the untested function default).",
        "# SECONDARY/informational (Leg X): SD and max of |relative difference|; nprobe=$NPROBE_INFO arm's mean |relative difference| (does NOT gate); iterations-to-outcome distribution both arms.",
        "# Overall GATE = Leg A ∧ Leg X. PASS discharges validation-debt-register.md:57 item (1) for V1-MATFREE-REML and narrows item (3) at q=$Q_TAIL only. Promotes NOTHING: public_covered_count stays 5 regardless of outcome.",
        SMOKE ? "# *** THIS IS A SMOKE RUN: shrunken n, PLUMBING CHECK ONLY. NOT the pre-declared 48+8-seed evidence. gate_pass above reflects plumbing, not the real A1/A2/A3/Leg-X thresholds. ***" : "# FULL pre-declared run.",
    ]

    open(outpath, "w") do io
        for m in manifest
            println(io, m)
        end
        println(io, "#")
        println(io, "# ---- Leg A ----")
        println(io, a.header)
        for r in a.rows
            println(io, r)
        end
        println(io, "#")
        println(io, "# ---- Leg X ----")
        println(io, x.header)
        for r in x.rows
            println(io, r)
        end
        println(io, "#")
        println(io, "# ---- summary ----")
        @printf(io, "# Leg A: n_converged=%d n_cap_exhausted=%d n_non_graceful=%d n_anomaly_iter_mismatch=%d (of %d)\n",
                a.n_converged, a.n_cap_exhausted, a.n_non_graceful, a.n_anomaly, a.n)
        @printf(io, "# Leg A: A1 rel.err sigma_a2=%.6f sigma_e2=%.6f (converged-only: sigma_a2=%.6f sigma_e2=%.6f)  pass_A1=%s pass_A2=%s pass_A3=%s\n",
                a.rel_sa, a.rel_se, a.rel_sa_converged_only, a.rel_se_converged_only, a.pass_A1, a.pass_A2, a.pass_A3)
        @printf(io, "# Leg A: iterations min=%.0f median=%.1f max=%.0f (cap=%d); fill_measured(mean)=%.2f\n",
                a.iters_min, a.iters_median, a.iters_max, ITER_CAP, a.fill_measured)
        @printf(io, "# Leg X: mean|reldiff| nprobe=%d sigma_a2=%.6f sigma_e2=%.6f (sd sa2=%.6f se2=%.6f; max sa2=%.6f se2=%.6f)\n",
                x.nprobe, x.mean_reldiff_sa, x.mean_reldiff_se, x.sd_reldiff_sa, x.sd_reldiff_se, x.max_reldiff_sa, x.max_reldiff_se)
        @printf(io, "# Leg X: nprobe=%d informational mean|reldiff| sigma_a2=%.6f sigma_e2=%.6f\n",
                NPROBE_INFO, x.nprobe256_mean_reldiff_sa, x.nprobe256_mean_reldiff_se)
        @printf(io, "# Leg X: iterations nprobe=64 min=%.0f median=%.1f max=%.0f; nprobe=256 min=%.0f median=%.1f max=%.0f\n",
                x.iters_min, x.iters_median, x.iters_max, x.nprobe256_iters_min, x.nprobe256_iters_median, x.nprobe256_iters_max)
        println(io, "# GATE_JSON ", gate_json)
    end
    println("\nwrote ", outpath)

    exit(gate ? 0 : 1)
end

main()
