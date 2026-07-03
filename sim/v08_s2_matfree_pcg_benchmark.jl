# v0.8-S2 — matrix-free multi-effect PCG vs direct-Cholesky SOLVE benchmark harness.
#
# Times the MATRIX-FREE multi-effect PCG solve (`solve_multi_effect_pcg`, matrix_free=true)
# against the DIRECT sparse-Cholesky solve of the SAME K-INDEPENDENT-effect MME (the
# coefficient matrix of `_sparse_multi_lhs_rhs`), across an increasing pedigree/record size
# `q`. It is the v0.8 follow-up to the Phase 5 sparse-vs-dense AI-REML benchmark: Phase 5
# found the DIRECT multi-effect Cholesky is fill-limited for K≥2 (K=3 ~quadratic; METIS
# measured NOT a robust fix — 3.3× slower than AMD at q=50k, banked negative in v0.8-S1);
# this measures whether a matrix-free iterative solve — which NEVER forms/factors C, so it
# bypasses the fill entirely — stays feasible where the direct solve does not.
#
# STATUS / SCOPE (read before citing any number):
#   * OPT-IN, env-gated (`HSQUARED_RUN_S2_BENCH=1`), OUT of the CI test suite.
#   * MEASUREMENT ONLY. The claim it may license, the decision rule, and the honest scope
#     fence live in the PRE-DECLARED protocol
#     `docs/dev-log/recovery-checkpoints/2026-07-02-v08-s2-matfree-pcg-predeclaration.md`
#     (committed BEFORE the run; this file is frozen byte-identical against it) and the
#     post-run checkpoint. NO claim is made by the harness itself.
#   * This times a single SUPPLIED-VARIANCE SOLVE, not a full REML fit. The matrix-free PCG
#     is iterative (Jacobi-preconditioned; iteration count depends on conditioning); the
#     direct path is an exact factorization. Both solve the SAME SPD system — the harness
#     verifies same-solution per cell and records PCG iterations + relative residual so the
#     iterative-vs-direct difference is disclosed. NOT a GPU claim, NOT a full-fit claim,
#     NOT an accuracy/recovery claim, NOT a portable/absolute performance guarantee.
#   * FLEET USE: the harness is machine-agnostic and writes its host/version manifest, so it
#     is run byte-identical on multiple clusters, each covering a slice of the (K, q) grid.
#     Absolute times are compared WITHIN a cluster only (matrix-free vs direct on the same
#     box); cross-cluster we aggregate only the qualitative feasibility/scaling.
#
# TIMING PROTOCOL:
#   * `OPENBLAS_NUM_THREADS=1` + `JULIA_NUM_THREADS=1` (single core; pin BLAS).
#   * Global JIT warm-up (discarded); then per cell a full-size warm-up of each path
#     (discarded) followed by `trials` measured solves; report min + median.
#   * GC suppressed during each timed call so per-solve allocations don't inject pauses.
#   * `nseeds` deterministic datasets per size (gene-dropped, O(q)); raw per-row TSV.
#
# Run (nothing happens unless the gate env var is set):
#   HSQUARED_RUN_S2_BENCH=1 OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
#       julia --project=. sim/v08_s2_matfree_pcg_benchmark.jl [out.tsv]
# Overridable via ENV (defaults are the PRE-DECLARED grid):
#   S2_BENCH_OVERLAP_SIZES="2000,5000,10000,20000,50000"   (both paths; direct feasible)
#   S2_BENCH_MATFREE_SIZES="100000,200000,500000,1000000"   (matrix-free only; direct capped)
#   S2_BENCH_K=3   S2_BENCH_TRIALS=5   S2_BENCH_SEEDS=5
#   S2_BENCH_DIRECT_TRIALS=3  S2_BENCH_DIRECT_SEEDS=2
#   S2_BENCH_DIRECT_CAP_NNZL=60000000   (skip the direct path if nnz(L) would exceed this)
#   S2_BENCH_PCG_TOL=1e-8   S2_BENCH_PCG_MAXITER=5000

using HSquared
using LinearAlgebra, SparseArrays, Random, Printf, Dates, Statistics
import HSquared: _sparse_multi_lhs_rhs

# --- deterministic half-sib pedigree (all q animals phenotyped) — same DGP as Phase 5 -----
function halfsib(q::Int)
    nsire = max(2, round(Int, 0.04q)); ndam = max(2, round(Int, 0.08q))
    noff = q - nsire - ndam
    sire_ids = ["s$i" for i in 1:nsire]; dam_ids = ["d$i" for i in 1:ndam]
    off_ids = ["o$i" for i in 1:noff]
    ids = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(fill("0", nsire + ndam), [sire_ids[((i - 1) % nsire) + 1] for i in 1:noff])
    dam  = vcat(fill("0", nsire + ndam), [dam_ids[((i - 1) % ndam) + 1]  for i in 1:noff])
    return normalize_pedigree(ids, sire, dam)
end

function genedrop(ped; sigma_a2 = 1.0, rng = MersenneTwister(0))
    q = length(ped.ids); u = zeros(q)
    @inbounds for i in 1:q
        s = ped.sire[i]; d = ped.dam[i]
        pa = s > 0 ? u[s] : 0.0; pb = d > 0 ? u[d] : 0.0
        nknown = (s > 0) + (d > 0)
        msv = nknown == 0 ? 1.0 : (nknown == 1 ? 0.75 : 0.5)
        u[i] = 0.5 * (pa + pb) + sqrt(sigma_a2 * msv) * randn(rng)
    end
    return u
end

# K-component INDEPENDENT-effect case (O(q)): effect 1 = additive (A-structured, all
# phenotyped); effects 2..K = i.i.d. environmental groupings assigned INDEPENDENTLY of the
# pedigree — identical structure to the Phase 5 harness so the two benchmarks are comparable.
function make_case(q::Int, K::Int; seed::Int, sigma_a2 = 1.0, sigma_e2 = 1.0, sigma_env = 0.5, mu = 5.0)
    rng = MersenneTwister(seed)
    ped = halfsib(q); na = length(ped.ids)
    Ainv = pedigree_inverse(ped)
    u = genedrop(ped; sigma_a2 = sigma_a2, rng = rng)
    n = na; X = ones(n, 1); y = mu .+ u
    effects = Vector{Tuple{SparseMatrixCSC{Float64,Int},SparseMatrixCSC{Float64,Int}}}()
    Z1 = sparse(1.0I, n, na); push!(effects, (Z1, Ainv))
    for k in 2:K
        ng = max(5, q ÷ (10 * k)); Zk = spzeros(n, ng)
        for r in 1:n; Zk[r, rand(rng, 1:ng)] = 1.0; end
        envvals = randn(rng, ng) .* sigma_env
        y .+= Zk * envvals
        push!(effects, (Zk, sparse(1.0I, ng, ng)))
    end
    y .+= sqrt(sigma_e2) .* randn(rng, n)
    return (; y, X, effects, na)
end

# Direct sparse-Cholesky solve of the SAME multi-effect MME (the reference the matrix-free
# path must match). Returns (solution, nnzL, converged) — converged is always true for a PD
# factorization; recorded for symmetry with the PCG path.
function direct_solve(c, sigmas, sigma_e2)
    Xs = sparse(Float64.(c.X)); yv = Float64.(c.y)
    Zs = [e[1] for e in c.effects]; Ainvs = [e[2] for e in c.effects]
    Zf = reduce(hcat, Zs); Xt = transpose(Xs); Zft = transpose(Zf)
    XtX = sparse(Xt * Xs); XtZ = sparse(Xt * Zf); ZtX = sparse(Zft * Xs); ZtZ = sparse(Zft * Zf)
    Xty = Vector(Xt * yv); Zty = Vector(Zft * yv)
    lhs, rhs = _sparse_multi_lhs_rhs(XtX, XtZ, ZtX, ZtZ, Xty, Zty, Ainvs, sigmas, sigma_e2)
    F = cholesky(Symmetric(lhs); check = true)
    sol = F \ rhs
    return sol, nnz(sparse(F.L)), true
end

# Predicted nnz(L) proxy: run a symbolic factorization at a size to decide the direct cap.
function direct_nnzL(c, sigmas, sigma_e2)
    Xs = sparse(Float64.(c.X)); Zs = [e[1] for e in c.effects]; Ainvs = [e[2] for e in c.effects]
    Zf = reduce(hcat, Zs); Xt = transpose(Xs); Zft = transpose(Zf)
    lhs, _ = _sparse_multi_lhs_rhs(sparse(Xt * Xs), sparse(Xt * Zf), sparse(Zft * Xs),
                                   sparse(Zft * Zf), Vector(Xt * Float64.(c.y)),
                                   Vector(Zft * Float64.(c.y)), Ainvs, sigmas, sigma_e2)
    F = cholesky(Symmetric(lhs); check = true)
    return nnz(sparse(F.L))
end

loadavg1() = isfile("/proc/loadavg") ? parse(Float64, split(read("/proc/loadavg", String))[1]) : NaN

function timed(f, trials::Int)
    f()                                             # warm-up (discarded)
    ts = Float64[]; allocs = 0
    for i in 1:trials
        GC.gc(); GC.enable(false)
        try
            local a0 = Base.gc_num().allocd
            push!(ts, @elapsed f())
            allocs = max(allocs, Base.gc_num().allocd - a0)
        finally
            GC.enable(true)
        end
    end
    return ts, allocs
end

envint(k, d) = parse(Int, get(ENV, k, string(d)))
envints(k, d) = parse.(Int, split(get(ENV, k, d), ","))
envfloat(k, d) = parse(Float64, get(ENV, k, string(d)))

function main()
    if get(ENV, "HSQUARED_RUN_S2_BENCH", "0") ∉ ("1", "true", "TRUE", "yes")
        @info "v08_s2_matfree_pcg_benchmark.jl is opt-in; set HSQUARED_RUN_S2_BENCH=1 to run. No timing performed."
        return
    end
    overlap = envints("S2_BENCH_OVERLAP_SIZES", "2000,5000,10000,20000,50000")
    matfree = envints("S2_BENCH_MATFREE_SIZES", "100000,200000,500000,1000000")
    K = envint("S2_BENCH_K", 3)
    trials = envint("S2_BENCH_TRIALS", 5)
    nseeds = envint("S2_BENCH_SEEDS", 5)
    direct_trials = envint("S2_BENCH_DIRECT_TRIALS", 3)
    direct_seeds = min(envint("S2_BENCH_DIRECT_SEEDS", 2), nseeds)
    direct_cap = envint("S2_BENCH_DIRECT_CAP_NNZL", 60_000_000)
    pcg_tol = envfloat("S2_BENCH_PCG_TOL", 1e-8)
    pcg_maxiter = envint("S2_BENCH_PCG_MAXITER", 5000)
    out = length(ARGS) >= 1 ? ARGS[1] : "v08_s2_matfree_pcg_benchmark.tsv"
    base_seed = 20260702
    sigma_a2 = 1.0; sigma_e2 = 1.0; sigma_env = 0.5
    sigmas = vcat(sigma_a2, fill(sigma_env, K - 1))       # supplied VCs (truth); K components

    manifest = [
        "# HSquared.jl v0.8-S2 matrix-free-PCG vs direct-Cholesky multi-effect SOLVE benchmark  $(Dates.now())",
        "# host=$(gethostname())  julia=$(VERSION)  JULIA_NUM_THREADS=$(Threads.nthreads())  OPENBLAS_NUM_THREADS=$(get(ENV, "OPENBLAS_NUM_THREADS", "unset"))",
        "# $(BLAS.get_config())",
        "# K=$K  trials=$trials  nseeds=$nseeds  direct_trials=$direct_trials  direct_seeds=$direct_seeds  direct_cap_nnzL=$direct_cap  pcg_tol=$pcg_tol  pcg_maxiter=$pcg_maxiter  base_seed=$base_seed",
        "# overlap_sizes(both paths)=$(overlap)  matfree_only_sizes=$(matfree)  supplied_sigmas=$(sigmas)  sigma_e2=$sigma_e2",
        "# loadavg1_at_start=$(loadavg1())  free_mem_GB=$(round(Sys.free_memory() / 2^30, digits = 1))  total_mem_GB=$(round(Sys.total_memory() / 2^30, digits = 1))",
        "# SOLVE-only (supplied variances), NOT a full REML fit. matrix-free PCG is Jacobi-preconditioned iterative; direct is exact Cholesky. same-solution + PCG iters/relres recorded per row. OPT-IN measurement; claim+decision-rule+scope in the pre-declaration.",
    ]
    for m in manifest; println(m); end

    rows = String[]
    push!(rows, "size_q\tK\tn\tpath\tseed\ttrial\twall_s\tpcg_iters\tpcg_relres\tconverged\tnnz_L_direct\tmax_alloc_bytes\tsame_sol_maxabs\tloadavg1")

    # global JIT warm-up (tiny; discarded)
    let c = make_case(2000, K; seed = base_seed)
        solve_multi_effect_pcg(c.y, c.X, c.effects, sigmas, sigma_e2; tol = pcg_tol, maxiter = pcg_maxiter)
        direct_solve(c, sigmas, sigma_e2)
    end

    summary = NamedTuple[]
    for size_q in vcat(overlap, matfree)
        smins = Float64[]; smeds = Float64[]; dmins = Float64[]; dmeds = Float64[]
        piters = Int[]; nnzls = Int[]; same_max = 0.0; anyconv = true
        for s in 0:(nseeds - 1)
            seed = base_seed + s
            c = make_case(size_q, K; seed = seed)
            # matrix-free PCG (the scale path)
            pfit = solve_multi_effect_pcg(c.y, c.X, c.effects, sigmas, sigma_e2; tol = pcg_tol, maxiter = pcg_maxiter)
            pts, palloc = timed(() -> solve_multi_effect_pcg(c.y, c.X, c.effects, sigmas, sigma_e2; tol = pcg_tol, maxiter = pcg_maxiter), trials)
            anyconv &= pfit.converged
            push!(smins, minimum(pts)); push!(smeds, median(pts)); push!(piters, pfit.iterations)
            # DIRECT (reference) — only on the overlap grid, only within the nnz(L) cap, only on the first direct_seeds
            do_direct = size_q in overlap && s < direct_seeds
            nnzL = -1; ssame = -1.0; dnote = ", direct=skip"
            if do_direct
                nnzL = direct_nnzL(c, sigmas, sigma_e2)
                if nnzL <= direct_cap
                    dsol, _, _ = direct_solve(c, sigmas, sigma_e2)
                    dts, _ = timed(() -> direct_solve(c, sigmas, sigma_e2), direct_trials)
                    # same solution: compare the full [β; u] vectors
                    pvec = vcat(pfit.beta, reduce(vcat, [e.values for e in pfit.effects]))
                    ssame = maximum(abs.(pvec .- dsol))
                    same_max = max(same_max, ssame)
                    push!(dmins, minimum(dts)); push!(dmeds, median(dts)); push!(nnzls, nnzL)
                    dnote = @sprintf(", direct min=%.4fs nnzL=%d same=%.2e", minimum(dts), nnzL, ssame)
                else
                    dnote = @sprintf(", direct=cap-excluded nnzL=%d>%d", nnzL, direct_cap)
                end
            end
            for (t, w) in enumerate(pts)
                push!(rows, @sprintf("%d\t%d\t%d\t%s\t%d\t%d\t%.6f\t%d\t%.3e\t%s\t%d\t%d\t%.3e\t%.2f",
                    size_q, K, length(c.y), "matfree_pcg", seed, t, w, pfit.iterations, pfit.relative_residual,
                    pfit.converged, nnzL, palloc, ssame, loadavg1()))
            end
            @printf("# q=%d seed=%d matfree min=%.4fs iters=%d relres=%.1e conv=%s%s\n",
                    size_q, seed, minimum(pts), pfit.iterations, pfit.relative_residual, pfit.converged, dnote)
            flush(stdout)
        end
        push!(summary, (; size_q,
            mf_min = minimum(smins), mf_med = median(smeds), mf_iters = round(Int, median(piters)),
            mf_converged = anyconv,
            direct_min = isempty(dmins) ? NaN : minimum(dmins),
            direct_med = isempty(dmeds) ? NaN : median(dmeds),
            nnzL = isempty(nnzls) ? -1 : round(Int, median(nnzls)),
            same_maxabs = same_max))
    end

    println("\n# SUMMARY (min over trials, median over seeds)")
    @printf("%-8s %-11s %-11s %-8s %-6s %-12s %-12s %-12s\n",
            "q", "mf_min", "mf_med", "mf_iters", "conv", "direct_min", "nnz_L", "same_maxabs")
    for r in summary
        @printf("%-8d %-11.4f %-11.4f %-8d %-6s %-12s %-12s %-12.2e\n",
                r.size_q, r.mf_min, r.mf_med, r.mf_iters, r.mf_converged,
                isnan(r.direct_min) ? "skip" : @sprintf("%.4f", r.direct_min),
                r.nnzL < 0 ? "-" : string(r.nnzL), r.same_maxabs)
    end

    push!(rows, "# loadavg1_at_end=$(loadavg1())")
    open(out, "w") do io
        for m in manifest; println(io, m); end
        for r in rows; println(io, r); end
    end
    println("\n# wrote ", out)
end

main()
