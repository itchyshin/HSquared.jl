# v0.8-S1 — fill-reducing-ordering (METIS vs CHOLMOD-AMD) benchmark for the multi-effect MME.
#
# BANKED-NEGATIVE harness. Phase 5 identified the environmental-group-column Cholesky fill-in
# as the K≥2 direct-factorization scale bottleneck and hypothesized a fill-reducing ordering
# (METIS) as the enabler (doc 23, S1). This harness MEASURES whether a METIS nested-dissection
# permutation beats CHOLMOD's default AMD ordering for the multi-effect coefficient matrix `C`
# (the matrix of `_sparse_multi_lhs_rhs`), across q and K, on nnz(L) and factorization time.
#
# STATUS / SCOPE:
#   * OPT-IN, env-gated (`HSQUARED_RUN_S1_ORDER=1`), OUT of CI. MEASUREMENT ONLY.
#   * Metis is a BENCHMARK-ONLY dependency (run this in a throwaway env that has HSquared +
#     Metis). It is DELIBERATELY NOT added to the HSquared.jl Project.toml — banking this
#     negative is the decision NOT to take on a METIS dependency for the default solve path.
#   * Claim + decision rule + scope fence live in the PRE-DECLARED protocol
#     `docs/dev-log/recovery-checkpoints/2026-07-02-v08-s1-ordering-predeclaration.md`
#     (committed BEFORE the run; this file frozen byte-identical). NO claim by the harness.
#   * The decision the run informs: adopt METIS in the sparse multi-effect Cholesky ONLY if
#     it robustly (all tested q, both K) reduces nnz(L) / factorization time vs AMD by a
#     pre-declared margin. If it does not (e.g. worse at large q), it is a BANKED NEGATIVE
#     and AMD is retained — no dependency added.
#
# Setup + run (throwaway env; Metis is benchmark-only):
#   mkdir -p /tmp/s1env && cd /tmp/s1env
#   julia --project=. -e 'using Pkg; Pkg.develop(path="<HSquared.jl>"); Pkg.add("Metis")'
#   HSQUARED_RUN_S1_ORDER=1 OPENBLAS_NUM_THREADS=1 julia --project=. \
#       <HSquared.jl>/sim/v08_s1_ordering_benchmark.jl [out.tsv]
# Overridable via ENV (defaults are the PRE-DECLARED grid):
#   S1_ORDER_SIZES="2000,5000,10000,20000,50000"   S1_ORDER_KS="1,3"   S1_ORDER_TRIALS=3

using HSquared
using LinearAlgebra, SparseArrays, Random, Printf, Dates, Statistics
import HSquared: _sparse_multi_lhs_rhs
using Metis

function halfsib(q::Int)
    nsire = max(2, round(Int, 0.04q)); ndam = max(2, round(Int, 0.08q))
    noff = q - nsire - ndam
    sids = ["s$i" for i in 1:nsire]; dids = ["d$i" for i in 1:ndam]; oids = ["o$i" for i in 1:noff]
    ids = vcat(sids, dids, oids)
    sire = vcat(fill("0", nsire + ndam), [sids[((i - 1) % nsire) + 1] for i in 1:noff])
    dam  = vcat(fill("0", nsire + ndam), [dids[((i - 1) % ndam) + 1]  for i in 1:noff])
    return normalize_pedigree(ids, sire, dam)
end

# Assemble the multi-effect MME coefficient matrix C (same DGP as the Phase 5 / S2 harnesses).
function build_C(q::Int, K::Int; seed = 20260702)
    rng = MersenneTwister(seed)
    ped = halfsib(q); na = length(ped.ids)
    Ainv = pedigree_inverse(ped)
    n = na; X = ones(n, 1)
    Zs = SparseMatrixCSC{Float64,Int}[sparse(1.0I, n, na)]
    Ainvs = SparseMatrixCSC{Float64,Int}[Ainv]
    for k in 2:K
        ng = max(5, q ÷ (10 * k)); Zk = spzeros(n, ng)
        for r in 1:n; Zk[r, rand(rng, 1:ng)] = 1.0; end
        push!(Zs, Zk); push!(Ainvs, sparse(1.0I, ng, ng))
    end
    Xs = sparse(X); Zf = reduce(hcat, Zs); Xt = transpose(Xs); Zft = transpose(Zf)
    yv = zeros(n)
    lhs, _ = _sparse_multi_lhs_rhs(sparse(Xt * Xs), sparse(Xt * Zf), sparse(Zft * Xs),
                                   sparse(Zft * Zf), Vector(Xt * yv), Vector(Zft * yv),
                                   Ainvs, ones(K), 1.0)
    return Symmetric(sparse(lhs))
end

bestof(f, k) = minimum(@elapsed(f()) for _ in 1:k)
envints(k, d) = parse.(Int, split(get(ENV, k, d), ","))
envint(k, d) = parse(Int, get(ENV, k, string(d)))

function main()
    if get(ENV, "HSQUARED_RUN_S1_ORDER", "0") ∉ ("1", "true", "TRUE", "yes")
        @info "v08_s1_ordering_benchmark.jl is opt-in; set HSQUARED_RUN_S1_ORDER=1 to run. No timing performed."
        return
    end
    sizes = envints("S1_ORDER_SIZES", "2000,5000,10000,20000,50000")
    Ks = envints("S1_ORDER_KS", "1,3")
    trials = envint("S1_ORDER_TRIALS", 3)
    out = length(ARGS) >= 1 ? ARGS[1] : "v08_s1_ordering_benchmark.tsv"

    manifest = [
        "# HSquared.jl v0.8-S1 METIS-vs-AMD ordering benchmark (multi-effect MME)  $(Dates.now())",
        "# host=$(gethostname())  julia=$(VERSION)  OPENBLAS_NUM_THREADS=$(get(ENV, "OPENBLAS_NUM_THREADS", "unset"))",
        "# $(BLAS.get_config())",
        "# sizes=$(sizes)  Ks=$(Ks)  trials=$trials",
        "# BANKED-NEGATIVE harness. Metis is BENCHMARK-ONLY (NOT a package dependency). AMD = CHOLMOD default cholesky ordering; METIS = Metis.permutation nested dissection supplied via cholesky(C; perm=...).",
    ]
    for m in manifest; println(m); end
    rows = String[]
    push!(rows, "q\tK\tN\tnnz_C\tnnz_L_amd\tnnz_L_metis\tfill_gain\tt_amd_s\tt_metis_s\tspeed_gain")

    for q in sizes, K in Ks
        C = build_C(q, K); Cl = sparse(C); N = size(Cl, 1)
        Fa = cholesky(C); nLa = nnz(sparse(Fa.L))
        pm, _ = Metis.permutation(Cl); pv = Vector{Int}(pm)
        Fm = cholesky(C; perm = pv); nLm = nnz(sparse(Fm.L))
        cholesky(C); cholesky(C; perm = pv)                  # warm
        ta = bestof(() -> cholesky(C), trials)
        tm = bestof(() -> cholesky(C; perm = pv), trials)
        push!(rows, @sprintf("%d\t%d\t%d\t%d\t%d\t%d\t%.3f\t%.5f\t%.5f\t%.3f",
                             q, K, N, nnz(Cl), nLa, nLm, nLa / nLm, ta, tm, ta / tm))
        @printf("q=%-6d K=%d  AMD nnz(L)=%-11d t=%.4fs | METIS nnz(L)=%-11d t=%.4fs | fill x%.2f speed x%.2f\n",
                q, K, nLa, ta, nLm, tm, nLa / nLm, ta / tm)
        flush(stdout)
    end
    open(out, "w") do io
        for m in manifest; println(io, m); end
        for r in rows; println(io, r); end
    end
    println("\n# wrote ", out)
end

main()
