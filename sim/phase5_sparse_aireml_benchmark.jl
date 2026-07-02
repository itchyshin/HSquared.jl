# Phase 5 — sparse-vs-dense AI-REML PERFORMANCE benchmark harness.
#
# Times the SPARSE K-component AI-REML estimator `fit_sparse_multi_effect_aireml`
# against the DENSE `fit_multi_effect_reml` oracle (which forms an n×n `V` and is
# `max_dense_cells`-guarded) across an increasing pedigree/record size `q`.
#
# STATUS / SCOPE (read before citing any number):
#   * OPT-IN, env-gated (`HSQUARED_RUN_SPARSE_BENCH=1`), OUT of the CI test suite.
#   * This harness produces a MEASUREMENT ONLY. The claim it may license, the
#     decision rule, and the honest scope fence live in the PRE-DECLARED protocol
#     `docs/dev-log/recovery-checkpoints/2026-07-02-phase5-sparse-benchmark-predeclaration.md`
#     (committed BEFORE the run; this file is frozen byte-identical against it) and
#     in the post-run checkpoint. NO claim is made by the harness itself.
#   * The comparison is ESTIMATOR-vs-ESTIMATOR end-to-end: the sparse path uses
#     AI/Newton (few iterations, one sparse Cholesky + Takahashi selected inverse
#     per iteration); the dense oracle uses derivative-free `Optim.NelderMead` over
#     K+1 log-variances (many n×n `V` factorizations). The two differ in BOTH the
#     linear algebra AND the optimizer — so iteration/eval counts are recorded for
#     BOTH paths to DISCLOSE that confound. This is NOT an isolated linear-algebra
#     speedup measurement, NOT a GPU/accelerator claim, NOT a production-hardening
#     claim, and NOT an accuracy claim (timing != correctness; the exact reduction
#     to the dense optimum + to `fit_ai_reml` is already gated in `test/runtests.jl`).
#
# TIMING PROTOCOL:
#   * `OPENBLAS_NUM_THREADS=1` + `JULIA_NUM_THREADS=1` (single core; pin BLAS).
#   * Global JIT warm-up (discarded); then per cell a full-size warm-up fit
#     (discarded) followed by `trials` measured fits; report min + median.
#   * `nseeds` deterministic datasets per size (gene-dropped, O(q)); the raw
#     per-(size,K,path,seed,trial) rows are written so any summary stat is
#     reproducible. min-over-trials is robust to co-tenant noise on a shared box;
#     median-over-{seeds,trials} is the headline.
#
# Run (nothing happens unless the gate env var is set):
#   HSQUARED_RUN_SPARSE_BENCH=1 OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
#       julia --project=. sim/phase5_sparse_aireml_benchmark.jl [out.tsv]
# Overridable via ENV:
#   SPARSE_BENCH_OVERLAP_SIZES="200,500,800,1000"   (both paths; dense feasible)
#   SPARSE_BENCH_SPARSE_SIZES="2000,5000,10000,20000,50000"  (sparse only)
#   SPARSE_BENCH_K=3   SPARSE_BENCH_TRIALS=5   SPARSE_BENCH_SEEDS=5
#   SPARSE_BENCH_DENSE_TRIALS=3  SPARSE_BENCH_DENSE_SEEDS=2   (dense is O(n^3)/fit and
#       far more expensive than sparse, so it takes fewer trials/seeds by default;
#       its timing is stable relative to its magnitude. Defaults fall back to the
#       sparse trials/seeds if unset. dense runs on the FIRST dense_seeds datasets,
#       a subset of the sparse seeds, so the cells are paired.)
#   SPARSE_BENCH_DENSE_CAP=4000000

using HSquared
using LinearAlgebra, SparseArrays, Random, Printf, Dates, Statistics

# --- deterministic half-sib pedigree (all q animals phenotyped) -------------
function halfsib(q::Int)
    nsire = max(2, round(Int, 0.04q))
    ndam  = max(2, round(Int, 0.08q))
    noff  = q - nsire - ndam
    sire_ids = ["s$i" for i in 1:nsire]
    dam_ids  = ["d$i" for i in 1:ndam]
    off_ids  = ["o$i" for i in 1:noff]
    ids  = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(fill("0", nsire + ndam), [sire_ids[((i - 1) % nsire) + 1] for i in 1:noff])
    dam  = vcat(fill("0", nsire + ndam), [dam_ids[((i - 1) % ndam) + 1]  for i in 1:noff])
    return normalize_pedigree(ids, sire, dam)
end

# --- gene-dropping (O(q)) additive breeding values --------------------------
function genedrop(ped; sigma_a2 = 1.0, rng = MersenneTwister(0))
    q = length(ped.ids)
    u = zeros(q)
    @inbounds for i in 1:q
        s = ped.sire[i]; d = ped.dam[i]
        pa = s > 0 ? u[s] : 0.0
        pb = d > 0 ? u[d] : 0.0
        nknown = (s > 0) + (d > 0)
        msv = nknown == 0 ? 1.0 : (nknown == 1 ? 0.75 : 0.5)
        u[i] = 0.5 * (pa + pb) + sqrt(sigma_a2 * msv) * randn(rng)
    end
    return u
end

# Build a K-component case (O(q), scalable to 1e5+): effect 1 = additive
# (A-structured, one level per animal, all phenotyped), effects 2..K = i.i.d.
# environmental groupings assigned INDEPENDENTLY of the pedigree. Truth values
# are irrelevant to timing (both estimators fit the same data → same optimum).
function make_case(q::Int, K::Int; seed::Int,
                   sigma_a2 = 1.0, sigma_e2 = 1.0, sigma_env = 0.5, mu = 5.0)
    rng = MersenneTwister(seed)
    ped = halfsib(q)
    na = length(ped.ids)
    Ainv = pedigree_inverse(ped)                     # sparse, O(q) via Meuwissen–Luo
    u = genedrop(ped; sigma_a2 = sigma_a2, rng = rng)
    n = na                                           # every animal has one record
    X = ones(n, 1)
    y = mu .+ u
    effects = Vector{Tuple{SparseMatrixCSC{Float64,Int},SparseMatrixCSC{Float64,Int}}}()
    Z1 = sparse(1.0I, n, na)                         # record → animal (identity)
    push!(effects, (Z1, Ainv))
    for k in 2:K
        ng = max(5, q ÷ (10 * k))
        Zk = spzeros(n, ng)
        for r in 1:n
            Zk[r, rand(rng, 1:ng)] = 1.0
        end
        envvals = randn(rng, ng) .* sigma_env
        y .+= Zk * envvals
        push!(effects, (Zk, sparse(1.0I, ng, ng)))
    end
    y .+= sqrt(sigma_e2) .* randn(rng, n)
    return (; y, X, effects, na, nnz_add = nnz(Ainv))
end

loadavg1() = isfile("/proc/loadavg") ? parse(Float64, split(read("/proc/loadavg", String))[1]) : NaN

# Time `f` (a zero-arg fit closure): one discarded warm-up, then `trials` timed
# runs. Returns (representative_fit, Vector{wall_s}).
function timed(f, trials::Int)
    fit = f()                                         # full-size warm-up (discarded)
    ts = Float64[]
    for _ in 1:trials
        GC.gc()
        GC.enable(false)                              # keep GC out of the timed region
        try
            push!(ts, @elapsed f())
        finally
            GC.enable(true)
        end
    end
    return fit, ts
end

envint(k, d) = parse(Int, get(ENV, k, string(d)))
envints(k, d) = parse.(Int, split(get(ENV, k, d), ","))

function main()
    if get(ENV, "HSQUARED_RUN_SPARSE_BENCH", "0") ∉ ("1", "true", "TRUE", "yes")
        @info "phase5_sparse_aireml_benchmark.jl is opt-in; set HSQUARED_RUN_SPARSE_BENCH=1 to run. No timing performed."
        return
    end
    overlap = envints("SPARSE_BENCH_OVERLAP_SIZES", "200,500,800,1000")
    sparseonly = envints("SPARSE_BENCH_SPARSE_SIZES", "2000,5000,10000,20000,50000")
    K = envint("SPARSE_BENCH_K", 3)
    trials = envint("SPARSE_BENCH_TRIALS", 5)
    nseeds = envint("SPARSE_BENCH_SEEDS", 5)
    dense_trials = envint("SPARSE_BENCH_DENSE_TRIALS", trials)
    dense_seeds = min(envint("SPARSE_BENCH_DENSE_SEEDS", nseeds), nseeds)
    dense_cap = envint("SPARSE_BENCH_DENSE_CAP", 4_000_000)
    out = length(ARGS) >= 1 ? ARGS[1] : "phase5_sparse_aireml_benchmark.tsv"
    base_seed = 20260702

    manifest = [
        "# HSquared.jl Phase 5 sparse-vs-dense AI-REML benchmark  $(Dates.now())",
        "# host=$(gethostname())  julia=$(VERSION)  JULIA_NUM_THREADS=$(Threads.nthreads())  OPENBLAS_NUM_THREADS=$(get(ENV, "OPENBLAS_NUM_THREADS", "unset"))",
        "# $(BLAS.get_config())",
        "# K=$K  trials=$trials  nseeds=$nseeds  dense_trials=$dense_trials  dense_seeds=$dense_seeds  dense_cap=$dense_cap  base_seed=$base_seed",
        "# overlap_sizes(both paths)=$(overlap)  sparse_only_sizes=$(sparseonly)",
        "# loadavg1_at_start=$(loadavg1())  free_mem_GB=$(round(Sys.free_memory() / 2^30, digits = 1))  total_mem_GB=$(round(Sys.total_memory() / 2^30, digits = 1))",
        "# convergence: sparse stops on norm(score)<tol OR relative-VC-change<tol (cap 100 iters); dense NelderMead is iteration-capped (200) — both `converged` flags + iteration/f_calls counts are recorded per row.",
        "# OPT-IN measurement; claim + decision rule + scope fence in the pre-declaration. estimator-vs-estimator; iteration counts disclose the AI-Newton-vs-NelderMead confound.",
    ]
    for m in manifest; println(m); end

    rows = String[]
    push!(rows, "size_q\tK\tn\tna\tnnz_add\tpath\tseed\ttrial\twall_s\titerations\tf_calls\tconverged\tloglik\tsigma_a\tsigma_e\tsigmas_all\tloadavg1")

    # global JIT warm-up (tiny; discarded)
    let c = make_case(200, K; seed = base_seed)
        fit_sparse_multi_effect_aireml(c.y, c.X, c.effects; em_warmup = 0)
        fit_multi_effect_reml(c.y, c.X, c.effects; max_dense_cells = dense_cap)
    end

    function record!(size_q, path, seed, fit, ts, c; f_calls = -1)
        vc = fit.variance_components
        sig_a = vc.sigmas[1]; sig_e = vc.sigma_e2
        sigmas_all = join((@sprintf("%.6f", s) for s in vc.sigmas), "|")   # all K components
        for (t, w) in enumerate(ts)
            push!(rows, @sprintf("%d\t%d\t%d\t%d\t%d\t%s\t%d\t%d\t%.6f\t%d\t%d\t%s\t%.6f\t%.6f\t%.6f\t%s\t%.2f",
                size_q, K, length(c.y), c.na, c.nnz_add, path, seed, t, w,
                fit.iterations, f_calls, fit.converged, fit.loglik, sig_a, sig_e, sigmas_all, loadavg1()))
        end
        return minimum(ts), median(ts)
    end

    summary = NamedTuple[]
    for size_q in vcat(overlap, sparseonly)
        do_dense = size_q in overlap && size_q * size_q <= dense_cap
        smins = Float64[]; smeds = Float64[]; dmins = Float64[]; dmeds = Float64[]
        siters = Int[]; diters = Int[]; dfcalls = Int[]
        for s in 0:(nseeds - 1)
            seed = base_seed + s
            c = make_case(size_q, K; seed = seed)
            # sparse (em_warmup=0 to match the dense cold NelderMead start)
            sfit, sts = timed(() -> fit_sparse_multi_effect_aireml(c.y, c.X, c.effects; em_warmup = 0), trials)
            mn, md = record!(size_q, "sparse", seed, sfit, sts, c)
            push!(smins, mn); push!(smeds, md); push!(siters, sfit.iterations)
            dense_note = ", dense=skip"
            if do_dense && s < dense_seeds
                dfit, dts = timed(() -> fit_multi_effect_reml(c.y, c.X, c.effects; max_dense_cells = dense_cap), dense_trials)
                mn2, md2 = record!(size_q, "dense", seed, dfit, dts, c; f_calls = dfit.f_calls)
                push!(dmins, mn2); push!(dmeds, md2); push!(diters, dfit.iterations); push!(dfcalls, dfit.f_calls)
                dense_note = @sprintf(", dense min=%.4fs conv=%s", minimum(dts), dfit.converged)
            end
            @printf("# q=%d seed=%d done (sparse min=%.4fs%s)\n", size_q, seed, minimum(sts), dense_note); flush(stdout)
        end
        push!(summary, (; size_q,
            sparse_min = minimum(smins), sparse_med = median(smeds), sparse_iters = round(Int, median(siters)),
            dense_min = isempty(dmins) ? NaN : minimum(dmins),
            dense_med = isempty(dmeds) ? NaN : median(dmeds),
            dense_iters = isempty(diters) ? -1 : round(Int, median(diters)),
            dense_fcalls = isempty(dfcalls) ? -1 : round(Int, median(dfcalls))))
    end

    println("\n# SUMMARY (min over trials, median over seeds; iterations = median)")
    @printf("%-8s %-12s %-12s %-8s %-12s %-12s %-8s %-8s\n",
            "q", "sparse_min", "sparse_med", "sp_it", "dense_min", "dense_med", "d_it", "d_fcall")
    for r in summary
        @printf("%-8d %-12.4f %-12.4f %-8d %-12s %-12s %-8s %-8s\n",
                r.size_q, r.sparse_min, r.sparse_med, r.sparse_iters,
                isnan(r.dense_min) ? "skip" : @sprintf("%.4f", r.dense_min),
                isnan(r.dense_med) ? "skip" : @sprintf("%.4f", r.dense_med),
                r.dense_iters < 0 ? "-" : string(r.dense_iters),
                r.dense_fcalls < 0 ? "-" : string(r.dense_fcalls))
    end

    push!(rows, "# loadavg1_at_end=$(loadavg1())")
    open(out, "w") do io
        for m in manifest; println(io, m); end
        for r in rows; println(io, r); end
    end
    println("\n# wrote ", out)
end

main()
