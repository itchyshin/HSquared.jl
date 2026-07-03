#!/usr/bin/env julia
# v0.7 / Track B — G-C large / realistic-panel genomic-G benchmark + device-memory profile.
# OPT-IN, NOT CI. Requires a functional CUDA GPU.
#
# The G-A/G-B runs used modest panels (n≤4000, m≤80k). G-C benchmarks `gpu_genomic_relationship_matrix`
# at REALISTIC genomic-panel dimensions — n = 10k–20k genotyped individuals × m = 50k–300k SNPs
# (typical of a genotyping array / imputed panel; a LARGE SIMULATED panel, not a specific real
# dataset) — and profiles the device memory, since at scale the n×m marker matrix `W` (n·m·8 bytes,
# Float64) dominates GPU memory, not the n×n `G` (n²·8). Reports, per (n, m):
#   - a CPU↔GPU Float64 AGREEMENT sanity check at the smallest size (HARD gate, ~1e-12);
#   - the GPU `G`-build time (Float64 and the opt-in Float32), and the Float32 speedup;
#   - the measured peak device allocation (`CUDA.@allocated`) vs the theoretical W + G bytes.
#
# GPU = acceleration, NOT a new estimand (centering/validation = the CPU `centered_markers` verbatim;
# return always Matrix{Float64}). Machine-specific timings, NO competitive claim, NO CI gate.
# Predeclaration: docs/dev-log/recovery-checkpoints/2026-07-03-v07-gc-realpanel-predeclaration.md
#
# Usage:  julia --project=. sim/drac/g_c_realpanel.jl [out.tsv]   ("n,m" pairs are hard-coded below)

using HSquared
using CUDA
using LinearAlgebra, Printf, Dates, Random

CUDA.functional() || error("g_c_realpanel.jl requires a functional CUDA GPU (CUDA.functional() == false).")

function sim_markers(n::Int, m::Int; seed::Int = 20260703, maf_lo = 0.05, maf_hi = 0.95)
    rng = MersenneTwister(seed)
    p = maf_lo .+ (maf_hi - maf_lo) .* rand(rng, m)
    M = Matrix{Float64}(undef, n, m)
    @inbounds for j in 1:m, i in 1:n
        M[i, j] = (rand(rng) < p[j]) + (rand(rng) < p[j])
    end
    return M
end

# (n, m) at realistic genomic-panel scale; sized so W = n*m*8 bytes fits an 80 GB H100 with headroom.
const CELLS = [(10_000, 50_000), (10_000, 100_000), (10_000, 200_000),
               (20_000, 50_000), (20_000, 100_000), (10_000, 300_000)]

function main()
    out = length(ARGS) >= 1 ? ARGS[1] : "g_c_realpanel.tsv"
    dev = CUDA.device()
    totgib = CUDA.totalmem(dev) / 2^30
    println("# HSquared.jl v0.7 G-C real/large-panel genomic-G benchmark + memory  ", Dates.now())
    println("# host=", gethostname(), "  julia=", VERSION)
    println("# GPU=", CUDA.name(dev), "  CUDA=", CUDA.runtime_version(), "  totalmem=", round(totgib; digits = 1), " GiB")
    println("# LARGE SIMULATED panel (not a specific real dataset); return always Matrix{Float64}; OPT-IN, NO CI, NO competitive claim.\n")

    # (1) HARD AGREEMENT gate at the smallest cell: GPU Float64 G == CPU G to BLAS round-off.
    ng, mg = 4_000, 20_000
    println("# AGREEMENT gate  n=$ng m=$mg (CPU reference feasible)")
    Mg = sim_markers(ng, mg)
    Gcpu = genomic_relationship_matrix(Mg; method = :vanraden1)
    Ggpu = gpu_genomic_relationship_matrix(Mg; method = :vanraden1, precision = Float64)
    ga = maximum(abs.(Ggpu .- Gcpu))
    @printf("  max|GPU_f64 - CPU| = %.3e  %s\n\n", ga, ga < 1e-10 ? "OK" : "**FAIL**")
    ga < 1e-10 || error("GPU Float64 G disagrees with CPU (max abs $ga)")

    @printf("%-8s %-8s %10s %10s %10s %9s %12s %12s %10s\n",
            "n", "m", "f64_s", "f32_s", "speedup", "GPUmem%", "W_GiB", "G_GiB", "alloc_GiB")
    rows = NamedTuple[]
    for (n, m) in CELLS
        W_gib = n * m * 8 / 2^30
        G_gib = n * n * 8 / 2^30
        if (W_gib + 3 * G_gib) > 0.85 * totgib
            @printf("%-8d %-8d  SKIP (W %.1f + G headroom > 85%% of %.0f GiB)\n", n, m, W_gib, totgib)
            continue
        end
        M = sim_markers(n, m)
        gpu_genomic_relationship_matrix(M; precision = Float64)   # warm-up (JIT + CUBLAS)
        CUDA.synchronize(); GC.gc(); CUDA.reclaim()
        alloc = CUDA.@allocated (G64 = gpu_genomic_relationship_matrix(M; precision = Float64))
        t64 = CUDA.@elapsed gpu_genomic_relationship_matrix(M; precision = Float64)
        t32 = CUDA.@elapsed gpu_genomic_relationship_matrix(M; precision = Float32)
        mempct = 100 * (W_gib + G_gib) / totgib
        @printf("%-8d %-8d %10.4f %10.4f %10.2f %8.1f %12.2f %12.2f %10.2f\n",
                n, m, t64, t32, t64 / t32, mempct, W_gib, G_gib, alloc / 2^30)
        push!(rows, (; n, m, t64, t32, speedup = t64 / t32, W_gib, G_gib, alloc_gib = alloc / 2^30))
    end

    open(out, "w") do io
        println(io, "n\tm\tf64_s\tf32_s\tspeedup\tW_GiB\tG_GiB\talloc_GiB\tgpu\thost\tjulia\tagree_f64")
        for r in rows
            @printf(io, "%d\t%d\t%.5f\t%.5f\t%.3f\t%.3f\t%.3f\t%.3f\t%s\t%s\t%s\t%.3e\n",
                    r.n, r.m, r.t64, r.t32, r.speedup, r.W_gib, r.G_gib, r.alloc_gib,
                    CUDA.name(dev), gethostname(), VERSION, ga)
        end
    end
    println("\n# wrote ", out)
end

main()
