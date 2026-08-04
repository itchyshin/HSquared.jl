using HSquared
using LinearAlgebra
using SparseArrays
using Printf
using Random
using Statistics

# ============================================================================
# F6 matrix-free MC-EM-REML (`fit_matrix_free_reml`) — stochastic recovery check.
# OPT-IN, NOT CI, RNG-full. Promotes NOTHING; public_covered_count stays 5.
#
# WHY THIS FILE EXISTS. These four checks used to live in test/runtests.jl's F6 testset
# ("fit_matrix_free_reml (F6 matrix-free MC EM-REML) recovers the AI-REML optimum"), built from
# `rng = MersenneTwister(20260728)`. Julia's randn/rand seeded stream is not stable across Julia
# versions (test/runtests.jl documents the same bug class fixed once already, at the
# boundary_fixture note: "randn's seeded stream changed between Julia 1.10 and 1.12"). On Julia
# 1.10 vs 1.12 that rng draws a DIFFERENT pedigree and phenotype, and the harder 1.10 draw needed
# more than 200 EM iterations to reach the fit's convergence tolerance — CI job "Julia 1.10" went
# red (mf.converged=false at the 200-iteration cap, rel.err 5.45% vs the 5e-2 gate) while job
# "Julia 1" (1.12) stayed green (converged in 116 iterations, rel.err 0.79%), even though the
# estimator itself is not broken: it simply needed more iterations on a harder draw. Per the
# established CI-remains-RNG-free policy
# (docs/dev-log/after-task/2026-06-14-phase4b-structured-recovery-harness.md), the stochastic
# recovery claim now lives here, opt-in, out of CI; the structural/deterministic-fixture checks
# (result shape/tags, exact-loglik identity, seed determinism, extractors, the
# compute_loglik=false NaN skip, the REML-only guard, both `target` spellings, and the `:auto`
# opt-in fence) stay in CI, in that same test/runtests.jl testset, on a literal fixture.
#
# Reproduces, on the SAME fixture/seed this file replaces, the four deleted assertions:
#   mf.converged
#   mf.variance_components.sigma_a2 ≈ exact.variance_components.sigma_a2   rtol 5e-2
#   mf.variance_components.sigma_e2 ≈ exact.variance_components.sigma_e2   rtol 5e-2
#   heritability(mf) ≈ heritability(exact)                                 rtol 5e-2
#
#   OPENBLAS_NUM_THREADS=1 julia --project=. sim/f6_matfree_recovery.jl
#   HSQ_F6_SMOKE=1 OPENBLAS_NUM_THREADS=1 julia --project=. sim/f6_matfree_recovery.jl   # quick check
# ============================================================================

const SMOKE = get(ENV, "HSQ_F6_SMOKE", "0") == "1"
const NM = SMOKE ? 60 : 400
const SEED = 20260728
const NPROBE = SMOKE ? 32 : 256
const REL_TOL = 0.05

# IDENTICAL construction to the fixture the CI testset used to build (random-mating → deliberately
# high fill-in), just relocated here verbatim.
function highfill_fixture(nm, seed)
    rng = MersenneTwister(seed)
    sm = zeros(Int, nm); dm = zeros(Int, nm)
    for i in 3:nm
        sm[i] = rand(rng, 1:i-1); dm[i] = rand(rng, 1:i-1)
        while dm[i] == sm[i]; dm[i] = rand(rng, 1:i-1); end
    end
    Am = pedigree_inverse(collect(1:nm), sm, dm)
    um = zeros(nm)
    for i in 1:nm
        (sm[i] == 0 && dm[i] == 0) ? (um[i] = sqrt(0.4) * randn(rng)) :
            (um[i] = 0.5 * (um[sm[i]] + um[dm[i]]) + sqrt(0.2) * randn(rng))
    end
    ym = 10.0 .+ um .+ sqrt(0.6) .* randn(rng, nm)
    Xm = ones(nm, 1); Zm = sparse(1.0I, nm, nm)
    return animal_model_spec(ym, Xm, Zm, Am; ids = 1:nm, method = :REML)
end

function main()
    println("F6 matrix-free MC-EM-REML recovery check — nm=$NM nprobe=$NPROBE seed=$SEED smoke=$SMOKE")
    println("host=", gethostname(), " julia=", VERSION, " threads=", Threads.nthreads())
    specm = highfill_fixture(NM, SEED)
    exact = fit_ai_reml(specm)
    mf = fit_matrix_free_reml(specm; nprobe = NPROBE, seed = SEED)

    # A relative error is MEANINGLESS when the exact estimate sits on the zero boundary: the
    # denominator collapses. Measured on Totoro 2026-08-04 at the smoke size nm=60, the exact fit
    # returns sigma_a2 = 0 and the naive ratio reports rel_a ≈ 4e4 — a number that says nothing
    # about the matrix-free fitter. Report NaN + ANOMALY instead of a spurious FAIL.
    # "On the boundary" must be judged RELATIVE to trait scale, not absolutely: at nm=60 the exact
    # fit returns sigma_a2 = 4e-5 against sigma_e2 = 0.70 — numerically nonzero, statistically zero,
    # and an absolute 1e-8 cutoff would miss it and print rel.err = 980 as if it meant something.
    total_var = exact.variance_components.sigma_a2 + exact.variance_components.sigma_e2
    on_boundary(e) = abs(e) <= 1e-4 * max(total_var, eps())
    safe_rel(m, e) = on_boundary(e) ? NaN : abs(m - e) / abs(e)
    rel_a  = safe_rel(mf.variance_components.sigma_a2, exact.variance_components.sigma_a2)
    rel_e  = safe_rel(mf.variance_components.sigma_e2, exact.variance_components.sigma_e2)
    rel_h2 = safe_rel(heritability(mf), heritability(exact))
    degenerate = isnan(rel_a) || isnan(rel_e) || isnan(rel_h2)

    ok_conv = mf.converged
    ok_a = !isnan(rel_a) && rel_a <= REL_TOL
    ok_e = !isnan(rel_e) && rel_e <= REL_TOL
    ok_h2 = !isnan(rel_h2) && rel_h2 <= REL_TOL

    # SMOKE is a PLUMBING check ONLY, matching this repo's smoke discipline: it proves the driver
    # deploys, runs end-to-end, and returns finite output at a shrunken size. It deliberately does
    # NOT assert recovery — the shrunken fixture is not the one this file exists to check, and it
    # can land on the variance boundary (it does, at nm=60). A smoke that always reports FAIL
    # trains its reader to ignore it.
    plumbing_ok = all(isfinite, (exact.variance_components.sigma_a2, exact.variance_components.sigma_e2,
                                 mf.variance_components.sigma_a2, mf.variance_components.sigma_e2))
    gate = SMOKE ? plumbing_ok : (ok_conv && ok_a && ok_e && ok_h2)

    @printf("  exact:  sigma_a2=%.4f sigma_e2=%.4f h2=%.4f converged=%s iterations=%d\n",
            exact.variance_components.sigma_a2, exact.variance_components.sigma_e2,
            heritability(exact), exact.converged, exact.iterations)
    @printf("  mf   :  sigma_a2=%.4f sigma_e2=%.4f h2=%.4f converged=%s iterations=%d\n",
            mf.variance_components.sigma_a2, mf.variance_components.sigma_e2,
            heritability(mf), mf.converged, mf.iterations)
    @printf("  rel.err sigma_a2=%.4f sigma_e2=%.4f h2=%.4f (tol %.2f)\n", rel_a, rel_e, rel_h2, REL_TOL)
    if degenerate
        println("  ANOMALY: the EXACT fit is on the variance boundary (sigma_a2 or h2 ~ 0), so a")
        println("           relative error is undefined. Reported as NaN, not as a recovery FAIL —")
        println("           this says nothing about the matrix-free fitter.")
    end
    if SMOKE
        println("  SMOKE = PLUMBING ONLY — recovery is deliberately NOT asserted at this size.")
        println("  finite output from both fitters: ", plumbing_ok ? "PASS" : "FAIL")
    else
        println("  converged:                    ", ok_conv ? "PASS" : "FAIL")
        println("  sigma_a2 rtol<=$(REL_TOL):        ", ok_a ? "PASS" : (isnan(rel_a) ? "ANOMALY" : "FAIL"))
        println("  sigma_e2 rtol<=$(REL_TOL):        ", ok_e ? "PASS" : (isnan(rel_e) ? "ANOMALY" : "FAIL"))
        println("  heritability rtol<=$(REL_TOL):    ", ok_h2 ? "PASS" : (isnan(rel_h2) ? "ANOMALY" : "FAIL"))
    end
    println("\nGATE: ", gate ? "PASS" : "FAIL",
            SMOKE ? "  (plumbing only)" :
                    "  (converged=$ok_conv sigma_a2=$ok_a sigma_e2=$ok_e h2=$ok_h2 degenerate=$degenerate)")

    header = "nm\tnprobe\tseed\tconverged\tsigma_a2_exact\tsigma_a2_mf\trel_a\tsigma_e2_exact\tsigma_e2_mf\trel_e\th2_exact\th2_mf\trel_h2\tgate"
    row = @sprintf("%d\t%d\t%d\t%s\t%.5f\t%.5f\t%.5f\t%.5f\t%.5f\t%.5f\t%.5f\t%.5f\t%.5f\t%s",
        NM, NPROBE, SEED, mf.converged, exact.variance_components.sigma_a2, mf.variance_components.sigma_a2,
        rel_a, exact.variance_components.sigma_e2, mf.variance_components.sigma_e2, rel_e,
        heritability(exact), heritability(mf), rel_h2, gate)
    println("\n", header)
    println(row)
    exit(gate ? 0 : 1)
end

main()
