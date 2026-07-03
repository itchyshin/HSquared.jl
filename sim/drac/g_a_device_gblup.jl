#!/usr/bin/env julia
# v0.7 / Track B — G-A device-resident GBLUP agreement + benchmark.  OPT-IN, NOT CI.
#
# Validates that the DEVICE-RESIDENT genomic BLUP `gpu_fit_gblup` (the `HSquaredCUDAExt`
# extension) is NUMERICALLY IDENTICAL (to floating-point tolerance) to the CPU pipeline
# `genomic_relationship_matrix` -> `genomic_relationship_inverse` -> `fit_gblup`, then
# benchmarks the END-TO-END GBLUP (G build + ridge inverse + MME solve) CPU vs GPU across
# the genotyped-population size q. The device path keeps G / Ginv / C ON-DEVICE across all
# three stages (only markers up, beta + GEBV down); the benchmark measures that end-to-end.
#
# GPU = acceleration, NOT a new estimand (doc 17 / doc 23 honesty fence). The script
# HARD-FAILS if any CPU<->GPU agreement is violated, so a clean run == agreement holds.
# Float64 throughout (matches the CPU contract). Timings are honest END-TO-END measurements
# including host<->device transfer of the markers + the returned vectors — machine-specific,
# NO competitive claim, NO CI gate. Every number traces to this committed script + the TSV.
# The ALGORITHM is separately CPU-mirror-validated (device assembly reproduces fit_gblup to
# ~1e-15 on CPU) in the v0.7 G-A pre-declaration; this run confirms CUDA numerics agree.
#
# Requires a functional CUDA GPU (errors out otherwise). Run via sim/drac/g_a_*.sbatch on
# any of the GPU clusters (tamia H200 / Killarney / Vulcan H100 / Narval A100).
#
# Usage:  julia --project=. sim/drac/g_a_device_gblup.jl [out.tsv] [q1,q2,...] [m]

using HSquared
using CUDA
using LinearAlgebra, SparseArrays, Printf, Dates, Random, Statistics

CUDA.functional() || error(
    "g_a_device_gblup.jl requires a functional CUDA GPU (CUDA.functional() == false). " *
    "Run on a GPU node with cuda + the bound CUDA.jl depot (see sim/drac/g_a_tamia.sbatch).",
)

# Deterministic biallelic marker matrix (rows = genotyped individuals, cols = markers),
# genotypes in {0,1,2}; allele frequencies in (maf_lo, maf_hi) so no column is monomorphic.
function sim_markers(q::Int, m::Int; seed::Int = 20260702, maf_lo = 0.05, maf_hi = 0.95)
    rng = MersenneTwister(seed)
    p = maf_lo .+ (maf_hi - maf_lo) .* rand(rng, m)
    M = Matrix{Float64}(undef, q, m)
    @inbounds for j in 1:m, i in 1:q
        M[i, j] = (rand(rng) < p[j]) + (rand(rng) < p[j])
    end
    return M
end

# Deterministic phenotypes + a 2-column fixed-effect design; Z = I (each record = one
# genotyped animal, the standard GBLUP layout).
function sim_pheno(q::Int; seed::Int = 20260703)
    rng = MersenneTwister(seed)
    y = 5.0 .+ randn(rng, q)
    X = hcat(ones(q), Float64[i % 2 for i in 1:q])
    Z = sparse(1.0I, q, q)
    return y, X, Z
end

# CPU reference pipeline: G -> ridge inverse -> supplied-variance GBLUP (Henderson MME).
function cpu_gblup(y, X, Z, markers, sa2, se2; ridge, method)
    G = genomic_relationship_matrix(markers; method = method)
    Ginv = genomic_relationship_inverse(G; ridge = ridge)
    res = fit_gblup(y, X, Z, Ginv, sa2, se2)
    return fixed_effects(res), breeding_values(res).values
end

function check(label, a_cpu, a_gpu; rtol = 1e-6, atol = 1e-9)
    d = maximum(abs.(a_gpu .- a_cpu))
    rel = d / max(maximum(abs.(a_cpu)), eps())
    ok = isapprox(a_gpu, a_cpu; rtol = rtol, atol = atol)
    @printf("  %-30s maxΔ=%.3e  relΔ=%.3e  %s\n", label, d, rel, ok ? "OK" : "**MISMATCH**")
    ok || error("CPU↔GPU agreement FAILED for $label (maxΔ=$d, relΔ=$rel)")
    return d
end

function agreement(; q = 400, m = 2000, ridge = 0.01, sa2 = 1.0, se2 = 1.0)
    println("# AGREEMENT  q=$q  m=$m  ridge=$ridge  sa2=$sa2  se2=$se2")
    markers = sim_markers(q, m); y, X, Z = sim_pheno(q)
    for method in (:vanraden1, :vanraden2)
        bc, uc = cpu_gblup(y, X, Z, markers, sa2, se2; ridge = ridge, method = method)
        g = gpu_fit_gblup(y, X, Z, markers, sa2, se2; ridge = ridge, method = method)
        check("beta $method", bc, g.beta)
        check("gebv $method", uc, g.breeding_values.values)
    end
    # weighted VanRaden-1
    w = 0.5 .+ rand(MersenneTwister(9), m)
    bcw, ucw = let
        G = genomic_relationship_matrix(markers; weights = w)
        res = fit_gblup(y, X, Z, genomic_relationship_inverse(G; ridge = ridge), sa2, se2)
        fixed_effects(res), breeding_values(res).values
    end
    gw = gpu_fit_gblup(y, X, Z, markers, sa2, se2; ridge = ridge, weights = w)
    check("beta weighted", bcw, gw.beta)
    check("gebv weighted", ucw, gw.breeding_values.values)
    println("# agreement OK\n")
end

function bench(q::Int, m::Int; seed = 20260702, ridge = 0.01, sa2 = 1.0, se2 = 1.0)
    markers = sim_markers(q, m; seed = seed); y, X, Z = sim_pheno(q)
    cpu_gblup(y, X, Z, markers, sa2, se2; ridge = ridge, method = :vanraden1)  # warm-up
    gpu_fit_gblup(y, X, Z, markers, sa2, se2; ridge = ridge)                    # warm-up (JIT + CUBLAS/CUSOLVER)
    GC.gc()
    tc = @elapsed bc, uc = cpu_gblup(y, X, Z, markers, sa2, se2; ridge = ridge, method = :vanraden1)
    tg = @elapsed g = gpu_fit_gblup(y, X, Z, markers, sa2, se2; ridge = ridge)
    db = maximum(abs.(g.beta .- bc)); du = maximum(abs.(g.breeding_values.values .- uc))
    return (; q, m, tc, tg, db, du)
end

function main()
    out = length(ARGS) >= 1 ? ARGS[1] : "g_a_device_gblup.tsv"
    qs = length(ARGS) >= 2 ? parse.(Int, split(ARGS[2], ",")) : [2_000, 4_000, 8_000, 16_000]
    m = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 5_000
    dev = CUDA.device()
    println("# HSquared.jl v0.7 G-A device-resident GBLUP agreement + benchmark  ", Dates.now())
    println("# host=", gethostname(), "  julia=", VERSION)
    println("# GPU=", CUDA.name(dev), "  CUDA=", CUDA.runtime_version(),
            "  totalmem=", round(CUDA.totalmem(dev) / 2^30; digits = 1), " GiB")
    println("# Float64; end-to-end (G build + ridge inverse + MME solve) incl. H2D/D2H; OPT-IN, NO CI, NO competitive claim.\n")

    agreement()

    println("# BENCHMARK  m=$m markers  (q = genotyped population; end-to-end GBLUP scales ~O(q³) dense)")
    rows = NamedTuple[]
    for q in qs
        @printf("# benchmarking q=%d m=%d ...\n", q, m); flush(stdout)
        push!(rows, bench(q, m))
    end
    @printf("\n%-8s %-8s %11s %11s %9s %11s %11s\n", "q", "m", "cpu_s", "gpu_s", "speedup", "maxΔbeta", "maxΔgebv")
    for r in rows
        @printf("%-8d %-8d %11.4f %11.4f %9.2f %11.2e %11.2e\n", r.q, r.m, r.tc, r.tg, r.tc / r.tg, r.db, r.du)
    end
    open(out, "w") do io
        println(io, "q\tm\tcpu_s\tgpu_s\tspeedup\tmaxabs_beta\tmaxabs_gebv\tgpu\thost\tjulia")
        for r in rows
            @printf(io, "%d\t%d\t%.5f\t%.5f\t%.3f\t%.3e\t%.3e\t%s\t%s\t%s\n",
                    r.q, r.m, r.tc, r.tg, r.tc / r.tg, r.db, r.du, CUDA.name(dev), gethostname(), VERSION)
        end
    end
    println("\n# wrote ", out)
end

main()
