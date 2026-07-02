# Phase 5 (P5.1) — MEASURE-FIRST timing scaffold for the sparse K-component AI-REML
# estimator `fit_sparse_multi_effect_aireml` vs the dense oracle `fit_multi_effect_reml`.
#
# STATUS: SCAFFOLD ONLY. This script is OPT-IN (env-gated), OUT of the CI test suite,
# and its output is NOT wired to any status row. NO PERFORMANCE OR SCALE CLAIM is made
# anywhere in the package on the basis of this script. A real performance claim would
# require a SEPARATE, PRE-DECLARED benchmark protocol (fixed designs, warmup-excluded
# timing, repeated trials, a machine/version manifest, and a Rose audit) — that
# benchmark evidence is OWED. This scaffold only exercises both code paths across a few
# increasing sizes so that, when the benchmark is designed, the harness already exists.
#
# What IS validated (in test/runtests.jl, deterministically): the sparse estimator
# reduces EXACTLY to the dense `fit_multi_effect_reml` optimum (K=2, K=3) and to
# `fit_ai_reml` (K=1). That is a CORRECTNESS gate, not a speed gate.
#
# Run (nothing happens unless the gate env var is set):
#   HSQUARED_RUN_SPARSE_BENCH=1 OPENBLAS_NUM_THREADS=1 julia --project=. \
#       sim/phase5_sparse_aireml_benchmark.jl
# Optional: SPARSE_BENCH_SIZES="200,500,1000,2000"  SPARSE_BENCH_K=3

using HSquared
using LinearAlgebra, SparseArrays, Random, Printf

if get(ENV, "HSQUARED_RUN_SPARSE_BENCH", "0") ∉ ("1", "true", "TRUE", "yes")
    @info "phase5_sparse_aireml_benchmark.jl is opt-in; set HSQUARED_RUN_SPARSE_BENCH=1 to run. No timing performed."
else
    SIZES = parse.(Int, split(get(ENV, "SPARSE_BENCH_SIZES", "200,500,1000"), ","))
    KEFF = parse(Int, get(ENV, "SPARSE_BENCH_K", "3"))   # number of random effects
    # dense oracle needs n*n + q*q ≤ this many cells; skipped above it
    DENSE_CELL_CAP = 4_000_000

    # Build a half-sib pedigree (nsire sires + q offspring) plus KEFF random effects:
    # effect 1 = additive (A-structured, one level per animal), effects 2..K = i.i.d.
    # environmental groupings assigned INDEPENDENTLY of the pedigree.
    function make_case(q::Int, K::Int; seed::Int = 20260702)
        rng = MersenneTwister(seed)
        nsire = max(10, q ÷ 20)
        sires = zeros(Int, nsire + q)
        for i in 1:q
            sires[nsire + i] = rand(rng, 1:nsire)
        end
        Ainv = pedigree_inverse(collect(1:(nsire + q)), sires, zeros(Int, nsire + q))
        na = size(Ainv, 1)
        recs = (nsire + 1):(nsire + q)
        n = q
        X = ones(n, 1)
        effects = Vector{Tuple{SparseMatrixCSC{Float64,Int},SparseMatrixCSC{Float64,Int}}}()
        # effect 1: additive
        Z1 = spzeros(n, na)
        for (r, an) in enumerate(recs); Z1[r, an] = 1.0; end
        push!(effects, (Z1, sparse(Matrix(Ainv))))
        # effects 2..K: i.i.d. environmental groupings
        groupsizes = Int[]
        Zenv = Vector{SparseMatrixCSC{Float64,Int}}()
        for k in 2:K
            ng = max(5, q ÷ (10 * k))
            Zk = spzeros(n, ng)
            for r in 1:n; Zk[r, rand(rng, 1:ng)] = 1.0; end
            push!(effects, (Zk, sparse(Matrix(1.0I, ng, ng))))
            push!(groupsizes, ng)
        end
        # phenotype: additive + environmental + residual (truth is irrelevant to timing)
        A = inv(Symmetric(Matrix(Ainv) + 1e-8I))
        g = cholesky(Symmetric(A + 1e-8I)).L * randn(rng, na)
        y = 3.0 .+ [g[an] for an in recs] .+ randn(rng, n)
        for k in 2:K
            ng = groupsizes[k - 1]
            envvals = randn(rng, ng) .* 0.5
            Zk = effects[k][1]
            y .+= Zk * envvals
        end
        return y, X, effects, na
    end

    @printf("%-8s %-6s %-10s %-14s %-14s %-10s\n", "q", "K", "n", "sparse_s", "dense_s", "note")
    println("-"^70)
    for q in SIZES
        y, X, effects, na = make_case(q, KEFF)
        n = length(y)
        # warmup (exclude compilation) on a tiny slice of the same code path
        fit_sparse_multi_effect_aireml(y[1:min(n, 40)], X[1:min(n, 40), :],
            [(eff[1][1:min(n, 40), :], eff[2]) for eff in effects]; iterations = 3)
        t_sparse = @elapsed fit_sparse_multi_effect_aireml(y, X, effects; em_warmup = 3)
        dense_cells = n * n + maximum(size(e[2], 1) for e in effects)^2
        if dense_cells <= DENSE_CELL_CAP
            effd = [(Matrix(e[1]), Matrix(e[2])) for e in effects]
            fit_multi_effect_reml(y[1:min(n, 40)], X[1:min(n, 40), :],
                [(ed[1][1:min(n, 40), :], ed[2]) for ed in effd]; iterations = 3,
                max_dense_cells = DENSE_CELL_CAP)
            t_dense = @elapsed fit_multi_effect_reml(y, X, effd; max_dense_cells = DENSE_CELL_CAP)
            @printf("%-8d %-6d %-10d %-14.4f %-14.4f %-10s\n", q, KEFF, n, t_sparse, t_dense, "")
        else
            @printf("%-8d %-6d %-10d %-14.4f %-14s %-10s\n", q, KEFF, n, t_sparse, "skip", "dense>cap")
        end
    end
    println("\nSCAFFOLD ONLY — NO performance claim. Benchmark evidence is OWED (see header).")
end
