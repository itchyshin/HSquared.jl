#!/usr/bin/env julia
# EM-REML warm-start (`em_warmup`) measurement.  OPT-IN, NOT CI.
#
# Measures the effect of the opt-in EM-REML warm-start in `fit_ai_reml`: the AI-loop
# iteration count (and convergence) for `em_warmup ∈ {0, 3, 5, 15}` from a GOOD start and a
# deliberately BAD start, on identified gene-dropping fixtures — plus the non-identified #182
# single-step fixture, where the warm-start does NOT achieve convergence (`converged = false`
# either way) and so does not fix the boundary. Honest MEASUREMENT only: NO performance claim,
# NO CI gate. Deterministic (seeded gene-dropping).
#
# Note: the AI step's bad-start non-convergence is FIXTURE-SENSITIVE. This `halfsib_genedrop`
# fixture exhibits it (so the rescue is visible: em=0 leaves a bad start non-converged, em≥3
# converges); the in-suite identified fixture (`test/runtests.jl`) happens to converge even at
# em_warmup=0 from the same bad start (just slower). Both reach the SAME optimum either way.
#
# Usage:  julia --project=. sim/em_warmstart_benchmark.jl

using HSquared, LinearAlgebra, SparseArrays, Random, Printf

# Identified fixture: half-sib pedigree with a genuine additive-genetic signal (gene-dropping,
# σ²a = 1) so the REML optimum is interior (σ²a > 0), not on the σ²→0 boundary.
function halfsib_genedrop(q; seed = 20260623, sa = 1.0, se = 1.0, mu = 5.0)
    nsire = max(2, round(Int, 0.07q)); ndam = max(2, round(Int, 0.21q)); noff = q - nsire - ndam
    sids = ["s$i" for i in 1:nsire]; dids = ["d$i" for i in 1:ndam]; oids = ["o$i" for i in 1:noff]
    ids = vcat(sids, dids, oids)
    sire = vcat(fill("0", nsire + ndam), [sids[((i - 1) % nsire) + 1] for i in 1:noff])
    dam = vcat(fill("0", nsire + ndam), [dids[((i - 1) % ndam) + 1] for i in 1:noff])
    ped = normalize_pedigree(ids, sire, dam); n = length(ped.ids); Ainv = pedigree_inverse(ped)
    rng = MersenneTwister(seed); u = zeros(n)
    @inbounds for i in 1:n
        s = ped.sire[i]; d = ped.dam[i]; pa = s > 0 ? u[s] : 0.0; pb = d > 0 ? u[d] : 0.0
        nk = (s > 0) + (d > 0); msv = nk == 0 ? 1.0 : (nk == 1 ? 0.75 : 0.5)
        u[i] = 0.5 * (pa + pb) + sqrt(sa * msv) * randn(rng)
    end
    y = mu .+ u .+ sqrt(se) .* randn(rng, n)
    return animal_model_spec(y, ones(n, 1), sparse(1.0I, n, n), Ainv; ids = ped.ids, method = :REML)
end

function row(label, spec, init)
    print(rpad(label, 36))
    for ew in (0, 3, 5, 15)
        f = fit_ai_reml(spec; initial = init, em_warmup = ew)
        @printf("%5d%-1s ", f.iterations, f.converged ? " " : "*")
    end
    println()
end

println("# HSquared.jl EM-REML warm-start measurement  (AI-loop iterations; * = NOT converged)")
println("# host=", gethostname(), "  julia=", VERSION)
println("# OPT-IN; NO performance claim, NO CI gate.\n")
@printf("%-36s %-7s %-7s %-7s %-7s\n", "fixture / start", "em=0", "em=3", "em=5", "em=15")

spec_s = halfsib_genedrop(140)
spec_l = halfsib_genedrop(1000)
row("q=140 identified, good (1,1)", spec_s, (sigma_a2 = 1.0, sigma_e2 = 1.0))
row("q=140 identified, BAD (1e4,1e-2)", spec_s, (sigma_a2 = 1e4, sigma_e2 = 1e-2))
row("q=1000 identified, good (1,1)", spec_l, (sigma_a2 = 1.0, sigma_e2 = 1.0))
row("q=1000 identified, BAD (1e4,1e-2)", spec_l, (sigma_a2 = 1e4, sigma_e2 = 1e-2))

sAinv = Matrix(pedigree_inverse([1, 2, 3, 4, 5], [0, 0, 1, 1, 3], [0, 0, 2, 2, 4]))
spec_b = animal_model_spec([10.0, 12, 11, 9, 13], ones(5, 1), Matrix(1.0I, 5, 5), sAinv; method = :REML)
row("#182 single-step (non-identified)", spec_b, (sigma_a2 = 1.0, sigma_e2 = 1.0))

println("\n# Read: on IDENTIFIED fixtures the warm-start reaches the SAME optimum and from a BAD")
println("# start it cuts AI iterations; on the non-identified #182 fixture it does NOT converge")
println("# (all *) and the warm-start does not fix that — converged=false is the honest signal.")
