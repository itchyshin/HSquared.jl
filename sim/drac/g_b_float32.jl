#!/usr/bin/env julia
# v0.7 / Track B — G-B Float32 (mixed-precision) genomic-relationship accuracy + speedup.
# OPT-IN, NOT CI. Requires a functional CUDA GPU.
#
# Characterizes the OPT-IN `precision = Float32` path of `gpu_genomic_relationship_matrix`
# (HSquaredCUDAExt). Three things, on-device:
#   (1) HARD GATE — precision = Float64 GPU `G` still matches the CPU `genomic_relationship_matrix`
#       to BLAS round-off (~1e-12). The Float32 kwarg must NOT change the Float64 contract.
#   (2) ACCURACY FENCE — precision = Float32 GPU `G` vs the Float64 GPU `G`: the GEMM-round-off
#       entry error (max abs, max rel, mean rel) AND the downstream GEBV impact (feed both G into
#       fit_gblup, compare the genomic breeding values). Characterized for BOTH GPU math modes:
#       the cluster DEFAULT (TF32 tensor cores on Ampere/Hopper — the fast, lower-precision Float32
#       matmul) and PEDANTIC (true IEEE Float32). Honest: Float32 is a SPEED-vs-ACCURACY trade, NOT
#       more accurate; this quantifies the trade — it is NOT a hard gate.
#   (3) BENCHMARK — the `G = W·Wᵀ/k` build time, Float64 vs Float32, across the marker count m
#       (the O(n²·m) GEMM is where the precision matters), reporting the speedup.
#
# GPU = acceleration, NOT a new estimand (doc 17 / doc 23 honesty fence): the centering/validation
# is the validated CPU `centered_markers` verbatim, only the GEMM precision changes; the return is
# always Matrix{Float64}. Timings are honest machine-specific measurements incl. H2D transfer, NO
# competitive claim, NO CI gate. Every number traces to this committed script + the TSV.
# Predeclaration: docs/dev-log/recovery-checkpoints/2026-07-03-v07-gb-float32-predeclaration.md
#
# Usage:  julia --project=. sim/drac/g_b_float32.jl [out.tsv] [m1,m2,...] [n]

using HSquared
using CUDA
using LinearAlgebra, SparseArrays, Printf, Dates, Random

CUDA.functional() || error(
    "g_b_float32.jl requires a functional CUDA GPU (CUDA.functional() == false). " *
    "Run on a GPU node with cuda + the bound CUDA.jl depot (see sim/drac/g_b_tamia.sbatch).",
)

# Deterministic biallelic markers (rows = individuals, cols = markers), genotypes in {0,1,2}.
function sim_markers(n::Int, m::Int; seed::Int = 20260703, maf_lo = 0.05, maf_hi = 0.95)
    rng = MersenneTwister(seed)
    p = maf_lo .+ (maf_hi - maf_lo) .* rand(rng, m)
    M = Matrix{Float64}(undef, n, m)
    @inbounds for j in 1:m, i in 1:n
        M[i, j] = (rand(rng) < p[j]) + (rand(rng) < p[j])
    end
    return M
end

# Set the GPU Float32 matmul math mode; return a label. Robust across CUDA.jl versions.
function set_mode!(mode::Symbol)
    try
        if mode === :pedantic
            CUDA.math_mode!(CUDA.PEDANTIC_MATH)
            return "pedantic_fp32"
        else
            CUDA.math_mode!(CUDA.DEFAULT_MATH)
            return "default"
        end
    catch err
        @warn "could not set math mode $mode ($err); using whatever is current"
        return "unknown($mode)"
    end
end

# entry-level error of G32 vs G64, and the downstream GEBV impact via fit_gblup.
function accuracy(n, m, G64, G32; ridge = 0.01)
    d = abs.(G32 .- G64)
    rel = d ./ max.(abs.(G64), 1e-12)
    maxabs = maximum(d); maxrel = maximum(rel); meanrel = sum(rel) / length(rel)
    # downstream GEBV: same phenotypes/design, both regularized inverses
    rng = MersenneTwister(20260707)
    y = 5.0 .+ randn(rng, n); X = ones(n, 1); Z = sparse(1.0I, n, n)
    Ginv64 = genomic_relationship_inverse(G64; ridge = ridge)
    Ginv32 = genomic_relationship_inverse(G32; ridge = ridge)
    g64 = breeding_values(fit_gblup(y, X, Z, Ginv64, 1.0, 1.0)).values
    g32 = breeding_values(fit_gblup(y, X, Z, Ginv32, 1.0, 1.0)).values
    gebv_maxabs = maximum(abs.(g32 .- g64))
    gebv_rel_l2 = norm(g32 .- g64) / norm(g64)
    return (; maxabs, maxrel, meanrel, gebv_maxabs, gebv_rel_l2)
end

function main()
    out = length(ARGS) >= 1 ? ARGS[1] : "g_b_float32.tsv"
    ms = length(ARGS) >= 2 ? parse.(Int, split(ARGS[2], ",")) : [2_000, 5_000, 10_000, 20_000, 40_000]
    n = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 2_000
    dev = CUDA.device()
    println("# HSquared.jl v0.7 G-B Float32 genomic accuracy + speedup  ", Dates.now())
    println("# host=", gethostname(), "  julia=", VERSION)
    println("# GPU=", CUDA.name(dev), "  CUDA=", CUDA.runtime_version(),
            "  totalmem=", round(CUDA.totalmem(dev) / 2^30; digits = 1), " GiB")
    println("# n=", n, " individuals; return is always Matrix{Float64}; OPT-IN, NO CI, NO competitive claim.\n")

    # (1) HARD GATE: precision=Float64 GPU G == CPU G (the precision kwarg didn't break Float64)
    println("# GATE: precision=Float64 GPU G vs CPU genomic_relationship_matrix")
    Mg = sim_markers(n, 5_000)
    Gcpu = genomic_relationship_matrix(Mg; method = :vanraden1)
    Ggpu64 = gpu_genomic_relationship_matrix(Mg; method = :vanraden1, precision = Float64)
    gate = maximum(abs.(Ggpu64 .- Gcpu))
    @printf("  max|GPU_f64 - CPU| = %.3e  %s\n", gate, gate < 1e-10 ? "OK" : "**FAIL**")
    gate < 1e-10 || error("Float64 GPU G no longer matches CPU (max abs $gate) — precision kwarg broke the contract")
    println()

    rows = NamedTuple[]
    for modesym in (:default, :pedantic)
        label = set_mode!(modesym)
        println("# ACCURACY + BENCHMARK  math_mode=", label)
        @printf("%-8s %-14s %12s %12s %12s %12s %12s %10s %10s %8s\n",
                "m", "mode", "maxabs_G", "maxrel_G", "meanrel_G", "gebv_maxabs", "gebv_relL2",
                "f64_s", "f32_s", "speedup")
        for m in ms
            M = sim_markers(n, m)
            # warm-up (JIT + CUBLAS)
            gpu_genomic_relationship_matrix(M; precision = Float64)
            gpu_genomic_relationship_matrix(M; precision = Float32)
            CUDA.synchronize(); GC.gc()
            t64 = CUDA.@elapsed G64 = gpu_genomic_relationship_matrix(M; precision = Float64)
            t32 = CUDA.@elapsed G32 = gpu_genomic_relationship_matrix(M; precision = Float32)
            acc = accuracy(n, m, G64, G32)
            @printf("%-8d %-14s %12.3e %12.3e %12.3e %12.3e %12.3e %10.4f %10.4f %8.2f\n",
                    m, label, acc.maxabs, acc.maxrel, acc.meanrel, acc.gebv_maxabs, acc.gebv_rel_l2,
                    t64, t32, t64 / t32)
            push!(rows, (; m, mode = label, acc.maxabs, acc.maxrel, acc.meanrel,
                         acc.gebv_maxabs, acc.gebv_rel_l2, t64, t32, speedup = t64 / t32))
        end
        println()
    end

    open(out, "w") do io
        println(io, "m\tmode\tmaxabs_G\tmaxrel_G\tmeanrel_G\tgebv_maxabs\tgebv_relL2\tf64_s\tf32_s\tspeedup\tgpu\thost\tjulia\tgate_f64_vs_cpu")
        for r in rows
            @printf(io, "%d\t%s\t%.5e\t%.5e\t%.5e\t%.5e\t%.5e\t%.6f\t%.6f\t%.3f\t%s\t%s\t%s\t%.3e\n",
                    r.m, r.mode, r.maxabs, r.maxrel, r.meanrel, r.gebv_maxabs, r.gebv_rel_l2,
                    r.t64, r.t32, r.speedup, CUDA.name(dev), gethostname(), VERSION, gate)
        end
    end
    println("# wrote ", out)
end

main()
