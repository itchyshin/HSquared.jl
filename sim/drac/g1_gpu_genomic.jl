#!/usr/bin/env julia
# Wave F / Track B — G1 genomic GPU agreement + benchmark.  OPT-IN, NOT CI.
#
# Validates that the GPU VanRaden `G` / `Ginv` (the `HSquaredCUDAExt` extension,
# `gpu_genomic_relationship_matrix` / `gpu_genomic_relationship_inverse`) are NUMERICALLY
# IDENTICAL (to floating-point tolerance) to their CPU twins, then benchmarks the dense
# GEMM (`G`) and Cholesky inverse (`Ginv`) CPU vs GPU across marker count m.
#
# GPU = acceleration, NOT a new estimand (doc 17 honesty fence). The script HARD-FAILS if
# any CPU↔GPU agreement is violated, so a clean run == agreement holds. Float64 throughout
# (matches the CPU contract). Timings are honest END-TO-END measurements including host↔
# device transfer (the functions return CPU arrays) — machine-specific, NO competitive
# claim, NO CI gate. Every number traces to this committed script + the emitted TSV.
#
# Requires a functional CUDA GPU (errors out otherwise). Run on the priority trio
# (tamia/vulcan/killarney) via sim/drac/g1_tamia.sbatch.
#
# Usage:  julia --project=. sim/drac/g1_gpu_genomic.jl [out.tsv] [m1,m2,...] [n]

using HSquared
using CUDA
using LinearAlgebra, Printf, Dates, Random

CUDA.functional() || error(
    "g1_gpu_genomic.jl requires a functional CUDA GPU (CUDA.functional() == false). " *
    "Run on a trio GPU node with cuda + the bound CUDA.jl depot (see sim/drac/g1_tamia.sbatch).",
)

# Deterministic biallelic marker matrix (rows = individuals, cols = markers), genotypes in
# {0,1,2}. Allele frequencies are drawn in (maf_lo, maf_hi) so NO column is monomorphic
# (method = :vanraden2 requires every marker polymorphic). Each genotype is the sum of two
# Bernoulli(p_j) draws (Hardy–Weinberg).
function sim_markers(n::Int, m::Int; seed::Int = 20260623, maf_lo = 0.05, maf_hi = 0.95)
    rng = MersenneTwister(seed)
    p = maf_lo .+ (maf_hi - maf_lo) .* rand(rng, m)
    M = Matrix{Float64}(undef, n, m)
    @inbounds for j in 1:m, i in 1:n
        M[i, j] = (rand(rng) < p[j]) + (rand(rng) < p[j])
    end
    return M
end

# Compare a CPU and GPU result; print maxΔ / relΔ; HARD-FAIL on disagreement.
function check(label, A_cpu, A_gpu; rtol = 1e-6, atol = 1e-9)
    d = maximum(abs.(A_gpu .- A_cpu))
    rel = d / max(maximum(abs.(A_cpu)), eps())
    ok = isapprox(A_gpu, A_cpu; rtol = rtol, atol = atol)
    @printf("  %-26s maxΔ=%.3e  relΔ=%.3e  %s\n", label, d, rel, ok ? "OK" : "**MISMATCH**")
    ok || error("CPU↔GPU agreement FAILED for $label (maxΔ=$d, relΔ=$rel)")
    return (; label, maxabs = d, rel = rel)
end

# ── Agreement: every G variant + the ridge inverse, CPU vs GPU ───────────────────────────
function agreement(; n = 400, m = 2000, ridge = 0.01, seed = 20260623)
    println("# AGREEMENT  n=$n  m=$m  ridge=$ridge")
    markers = sim_markers(n, m; seed = seed)
    for method in (:vanraden1, :vanraden2)
        Gc = genomic_relationship_matrix(markers; method = method)
        Gg = gpu_genomic_relationship_matrix(markers; method = method)
        check("G $method", Gc, Gg)
    end
    w = 0.5 .+ rand(MersenneTwister(seed + 1), m)            # deterministic positive weights
    check(
        "G weighted",
        genomic_relationship_matrix(markers; weights = w),
        gpu_genomic_relationship_matrix(markers; weights = w),
    )
    # Inverse: from the CPU G and from the GPU G (end-to-end GPU vs end-to-end CPU).
    Gc = genomic_relationship_matrix(markers)
    Gg = gpu_genomic_relationship_matrix(markers)
    Ic = genomic_relationship_inverse(Gc; ridge = ridge)
    check("Ginv (from CPU G)", Ic, gpu_genomic_relationship_inverse(Gc; ridge = ridge))
    Ig = gpu_genomic_relationship_inverse(Gg; ridge = ridge)
    check("Ginv (end-to-end GPU)", Ic, Ig)
    # The GPU inverse is a TRUE inverse, not just CPU-matching: (G + ridge·I)·Ginv ≈ I.
    check("(G+rI)·Ginv_gpu ≈ I", Matrix{Float64}(I, n, n), (Gc + ridge * I) * Ig)
    println("# agreement OK\n")
end

# ── Benchmark: CPU vs GPU, G build (GEMM, scales with m) + Ginv (Cholesky, scales with n) ─
function bench(n::Int, m::Int; seed = 20260623, ridge = 0.01)
    markers = sim_markers(n, m; seed = seed)
    genomic_relationship_matrix(markers)                    # warm-up (discard)
    gpu_genomic_relationship_matrix(markers)                # warm-up: JIT + CUBLAS init
    GC.gc()
    tc = @elapsed Gc = genomic_relationship_matrix(markers)
    tg = @elapsed Gg = gpu_genomic_relationship_matrix(markers)
    dG = maximum(abs.(Gg .- Gc))
    genomic_relationship_inverse(Gc; ridge = ridge)         # warm-up
    gpu_genomic_relationship_inverse(Gc; ridge = ridge)     # warm-up: CUSOLVER init
    GC.gc()
    tic = @elapsed Ic = genomic_relationship_inverse(Gc; ridge = ridge)
    tig = @elapsed Ig = gpu_genomic_relationship_inverse(Gc; ridge = ridge)
    dI = maximum(abs.(Ig .- Ic))
    return (; n, m, tc, tg, tic, tig, dG, dI)
end

function main()
    out = length(ARGS) >= 1 ? ARGS[1] : "g1_gpu_genomic.tsv"
    ms = length(ARGS) >= 2 ? parse.(Int, split(ARGS[2], ",")) : [2_000, 5_000, 10_000, 20_000]
    n = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 4_000
    dev = CUDA.device()
    println("# HSquared.jl Wave-F G1 genomic GPU agreement + benchmark  ", Dates.now())
    println("# host=", gethostname(), "  julia=", VERSION)
    println("# GPU=", CUDA.name(dev), "  CUDA=", CUDA.runtime_version(),
            "  totalmem=", round(CUDA.totalmem(dev) / 2^30; digits = 1), " GiB")
    println("# Float64; timings END-TO-END incl. H2D/D2H transfer; OPT-IN, NO CI gate, NO competitive claim.\n")

    agreement()

    println("# BENCHMARK  n=$n  (G build scales with m; Ginv scales with n)")
    rows = NamedTuple[]
    for m in ms
        @printf("# benchmarking n=%d m=%d ...\n", n, m); flush(stdout)
        push!(rows, bench(n, m))
    end
    @printf("\n%-7s %-8s %10s %10s %9s %10s %10s %9s %10s %10s\n",
            "n", "m", "cpuG_s", "gpuG_s", "G_x", "cpuInv_s", "gpuInv_s", "Inv_x", "maxΔG", "maxΔGinv")
    for r in rows
        @printf("%-7d %-8d %10.4f %10.4f %9.2f %10.4f %10.4f %9.2f %10.2e %10.2e\n",
                r.n, r.m, r.tc, r.tg, r.tc / r.tg, r.tic, r.tig, r.tic / r.tig, r.dG, r.dI)
    end
    open(out, "w") do io
        println(io, "n\tm\tcpu_build_s\tgpu_build_s\tbuild_speedup\tcpu_inv_s\tgpu_inv_s\tinv_speedup\tmaxabs_G\tmaxabs_Ginv\tgpu\thost\tjulia")
        for r in rows
            @printf(io, "%d\t%d\t%.5f\t%.5f\t%.3f\t%.5f\t%.5f\t%.3f\t%.3e\t%.3e\t%s\t%s\t%s\n",
                    r.n, r.m, r.tc, r.tg, r.tc / r.tg, r.tic, r.tig, r.tic / r.tig,
                    r.dG, r.dI, CUDA.name(dev), gethostname(), VERSION)
        end
    end
    println("\n# wrote ", out)
end

main()
