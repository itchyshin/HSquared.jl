#!/usr/bin/env julia
# ============================================================================
# PORT PROVENANCE — campaign branch claude/lane-h2-twin-20260901 (2026-09-02)
#   Source branch : refs/heads/codex/2026-07-13-v07-performance-localization
#   Source tip    : 853bcc12a25dee4445374754b048662576df2fef (2026-08-04)
#   Introducing   : 29d04a1d9abf649eb33981cacccd65643999a449 (2026-07-28)
#   Blob SHA      : 8a5a44da6adcb8e15dfbff83d2bb328f6644e631
#   Method        : read-only git-show from foreign lane; foreign files NOT edited.
#   STATUS        : PORTED, NOT RUN. Does not execute S6 Leg E/W; does not lift
#                   Rose ASReml wall-clock fences; public_covered_count stays 5.
# ============================================================================
# ASReml-R same-estimand REML comparator for the F6 matrix-free fitter — PREPARER.
#
# WHAT THIS IS. `fit_matrix_free_reml` (V1-MATFREE-REML) is currently validated only against
# `fit_ai_reml`. That is agreement with ANOTHER ESTIMATOR of ours, not with an independent
# implementation. This packet lets ASReml-R — an independent same-estimand REML lineage —
# estimate the SAME variance components on the SAME data, which is the external-comparator leg
# G11 asks for directly (`docs/design/16-promotion-gate-predicates.md:31-35`: a same-estimand
# external comparator, KIND fixed REML-vs-REML). NOT via the substitutability rule — that supplies
# a SECOND lineage on top of an existing leg, and this is the first.
#
# SCOPE: this fixture is q=2000 / fill ~75, BELOW the measured crossover of 150 — i.e. the regime
# where the exact path still wins. It validates the ESTIMAND, not the high-fill tail the
# matrix-free fitter exists for; an at-scale comparator leg remains owed.
#
# WHAT THIS IS NOT — READ BEFORE ADDING ANYTHING. This is an ESTIMAND comparison only. It
# deliberately records NO ASReml timings, so no performance reading can be taken from it. The
# standing ASReml honesty fence (§4 of
# `docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-findings.md`) is explicit that no
# head-to-head performance comparison against ASReml has ever been run here, and that the
# defensible claims are about our own internal ratios only. Timing ASReml would be a separate,
# separately pre-declared exercise with its own fencing. Do not add a stopwatch to this file.
#
# WHY A STOCHASTIC ESTIMATOR NEEDS A DIFFERENT COMPARISON. `fit_ai_reml` is deterministic, so it
# is compared to ASReml by a tight relative difference. `fit_matrix_free_reml` is NOT — its fixed
# point is the exact optimum perturbed by Monte-Carlo error (∝ 1/√nprobe). Comparing one draw to
# ASReml by a tight tolerance would be meaningless. Instead, following the existing precedent in
# `comparator/matfree_blupf90_neffect.jl`, this runs NSEED seeds at two probe budgets and reports
# the across-seed MEAN ± SD, with the gap to ASReml expressed in UNITS OF SD.
#
# Usage:  julia --project=. comparator/prepare_asreml_matfree.jl
# Then:   Rscript comparator/run_asreml_matfree.R

using HSquared
using LinearAlgebra, SparseArrays, Printf, Random, Statistics

const OUT = joinpath(@__DIR__, "asreml_matfree")

const Q         = 2_000            # high-fill regime, small enough that all three fits are quick
const NFOUNDER  = 0.005
const DATASEED  = 20269000         # fresh block, disjoint from every prior gate/comparator seed
const NSEED     = 8                # probe seeds for the stochastic arm
const NPROBES   = (128, 512)       # two budgets: the MC error must visibly shrink with nprobe
const MU, SA, SE = 5.0, 1.0, 1.0

# Small-founder RANDOM-mating pedigree — the high-fill structure F0 identified as the regime the
# matrix-free fitter exists for. Same generator as `sim/matrix_free_crossover_benchmark.jl` and
# `sim/drac/f0_adversarial_fill.jl`, so fill figures are directly comparable.
function adversarial(q::Int; nfounder_frac::Float64 = NFOUNDER, seed::Int = DATASEED)
    rng = MersenneTwister(seed)
    nf = max(4, round(Int, nfounder_frac * q))
    ids = ["a$i" for i in 1:q]
    sire = fill("0", q); dam = fill("0", q)
    @inbounds for i in (nf + 1):q
        p = rand(rng, 1:(i - 1)); m = rand(rng, 1:(i - 1))
        while m == p; m = rand(rng, 1:(i - 1)); end
        sire[i] = ids[p]; dam[i] = ids[m]
    end
    return normalize_pedigree(ids, sire, dam)
end

function simulate_y(ped; sigma_a2 = SA, sigma_e2 = SE, mu = MU, seed = DATASEED)
    rng = MersenneTwister(seed)
    q = length(ped.ids); u = zeros(q)
    @inbounds for i in 1:q
        s = ped.sire[i]; d = ped.dam[i]
        pa = s > 0 ? u[s] : 0.0; pb = d > 0 ? u[d] : 0.0
        nknown = (s > 0) + (d > 0)
        msv = nknown == 0 ? 1.0 : (nknown == 1 ? 0.75 : 0.5)
        u[i] = 0.5 * (pa + pb) + sqrt(sigma_a2 * msv) * randn(rng)
    end
    return mu .+ u .+ sqrt(sigma_e2) .* randn(rng, q)
end

mkpath(OUT)
ped = adversarial(Q)
q = length(ped.ids)
Ainv = pedigree_inverse(ped)
y = simulate_y(ped); X = ones(q, 1); Z = sparse(1.0 * I, q, q)
spec = animal_model_spec(y, X, Z, Ainv; method = :REML)

lhs, _, _ = HSquared._sparse_mme_system(spec, 1.0, 1.0)
fill_ratio = nnz(sparse(cholesky(Symmetric(lhs); check = true).L)) / q

# --- data.csv: phenotypes, 1-based integer animal codes matching the pedigree ---
open(joinpath(OUT, "data.csv"), "w") do io
    println(io, "y,animal")
    for a in 1:q
        @printf(io, "%.10f,%d\n", y[a], a)
    end
end

# --- pedigree.csv: ASReml builds its OWN A-inverse from this via ainverse(). Supplying the
# PEDIGREE rather than our Ainv makes the relationship construction an independent check too —
# if our Henderson Ainv were wrong, handing it over would hide exactly that error.
# `normalize_pedigree` has already topologically sorted parents before progeny, which ainverse()
# requires; unknown parents are 0. ---
open(joinpath(OUT, "pedigree.csv"), "w") do io
    println(io, "animal,sire,dam")
    for i in 1:q
        @printf(io, "%d,%d,%d\n", i, ped.sire[i], ped.dam[i])
    end
end

# --- the engine estimates ASReml will be compared against ---
exact = fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
ev = exact.variance_components
@printf("exact fit_ai_reml       : sa2=%.8f se2=%.8f converged=%s\n",
        ev.sigma_a2, ev.sigma_e2, exact.converged)

rows = String[]
push!(rows, @sprintf("exact,,point,%.10f,%.10f,%.10f", ev.sigma_a2, ev.sigma_e2, NaN))
for np in NPROBES
    sa = Float64[]; se = Float64[]
    for s in 1:NSEED
        mf = fit_matrix_free_reml(spec; nprobe = np, seed = DATASEED + s)
        push!(sa, mf.variance_components.sigma_a2)
        push!(se, mf.variance_components.sigma_e2)
    end
    @printf("matrix-free nprobe=%-4d : sa2=%.8f±%.8f se2=%.8f±%.8f (%d seeds)\n",
            np, mean(sa), std(sa), mean(se), std(se), NSEED)
    push!(rows, @sprintf("matfree,%d,mean,%.10f,%.10f,%.10f", np, mean(sa), mean(se), NaN))
    push!(rows, @sprintf("matfree,%d,sd,%.10f,%.10f,%.10f", np, std(sa), std(se), NaN))
end

open(joinpath(OUT, "engine_target.csv"), "w") do io
    println(io, "estimator,nprobe,stat,sigma_a2,sigma_e2,unused")
    for r in rows
        println(io, r)
    end
end

open(joinpath(OUT, "meta.csv"), "w") do io
    println(io, "key,value")
    for (k, v) in ("q" => q, "fill_nnzL_over_n" => fill_ratio, "data_seed" => DATASEED,
                   "nseed" => NSEED, "truth_sigma_a2" => SA, "truth_sigma_e2" => SE,
                   "julia" => string(VERSION), "host" => gethostname())
        println(io, k, ",", v)
    end
end

@printf("\nwrote %s  (q=%d, fill nnz(L)/n=%.1f)\n", OUT, q, fill_ratio)
println("next: Rscript comparator/run_asreml_matfree.R")
