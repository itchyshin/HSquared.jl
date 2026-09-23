#!/usr/bin/env julia
# ============================================================================
# NOT CI / OPT-IN measurement only.
#
# End-of-arc e2e wall receipts for HSquared.jl speed12 lane.
# Converts kernel-bench wins (SelectedInversion vs Takahashi) into attested
# fit / post-fit walls across kinds, and banks SHA-keyed TSV receipts.
#
# Before/after meaning (column `pair`):
#   historical_vs_now  — June-2026 cpu_fit baseline vs this-run wall
#   dense_vs_selinv    — dense post-fit PEV vs sparse selinv PEV
#   kernel_a_vs_c      — Takahashi (arm a) vs SelectedInversion (arm c)
#   dense_vs_sparse_me — dense NelderMead multi-effect vs sparse AI-REML
#   projected_selinv   — measured e2e fit wall + S1 selinv share × S2 S_c
#
# Usage (lane root):
#   env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
#       julia --project=. sim/e2e_wall_receipts.jl
# ============================================================================

using HSquared
using LinearAlgebra
using SparseArrays
using Printf
using Random
using Dates
using Statistics

const N_REP = 3

function git_sha()
    try
        return strip(read(`git rev-parse --short=8 HEAD`, String))
    catch
        return "unknown"
    end
end

function median_wall(f, n = N_REP)
    f()  # warm-up
    ts = Float64[]
    for _ in 1:n
        GC.gc()
        push!(ts, @elapsed f())
    end
    return median(ts), minimum(ts)
end

function halfsib_pedigree(nsire, ndam, noffspring)
    sire_ids = ["s$(i)" for i in 1:nsire]
    dam_ids  = ["d$(i)" for i in 1:ndam]
    off_ids  = ["o$(i)" for i in 1:noffspring]
    ids  = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(fill("0", nsire + ndam),
                [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring])
    dam  = vcat(fill("0", nsire + ndam),
                [dam_ids[((i - 1) % ndam) + 1]  for i in 1:noffspring])
    return normalize_pedigree(ids, sire, dam)
end

function make_y(q)
    return [5.0 + 0.3 * Float64(i % 7) + 0.1 * sin(i * 0.17) for i in 1:q]
end

function animal_spec(nsire, ndam, noff)
    ped = halfsib_pedigree(nsire, ndam, noff)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    y = make_y(q)
    X = ones(q, 1)
    Z = sparse(1.0 * I, q, q)
    return animal_model_spec(y, X, Z, Ainv; method = :REML), q, nnz(Ainv)
end

function f0_adversarial_pedigree(q::Int; nfounder_frac::Float64 = 0.005, seed::Int = 20260724)
    rng = MersenneTwister(seed)
    nf  = max(4, round(Int, nfounder_frac * q))
    ids  = ["a$i" for i in 1:q]
    sire = fill("0", q)
    dam  = fill("0", q)
    @inbounds for i in (nf + 1):q
        p = rand(rng, 1:(i - 1))
        m = rand(rng, 1:(i - 1))
        while m == p
            m = rand(rng, 1:(i - 1))
        end
        sire[i] = ids[p]
        dam[i]  = ids[m]
    end
    return normalize_pedigree(ids, sire, dam)
end

function f0_simulate_y(ped; sigma_a2 = 1.0, sigma_e2 = 1.0, mu = 5.0, seed = 20260724)
    rng = MersenneTwister(seed)
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
    return mu .+ u .+ sqrt(sigma_e2) .* randn(rng, q)
end

function f0adv_spec(q; nfounder_frac = 0.005)
    ped = f0_adversarial_pedigree(q; nfounder_frac = nfounder_frac)
    Ainv = pedigree_inverse(ped)
    y = f0_simulate_y(ped)
    X = ones(q, 1)
    Z = sparse(1.0 * I, q, q)
    return animal_model_spec(y, X, Z, Ainv; method = :REML)
end

function multi_effect_case(q::Int, K::Int; seed::Int = 20260702)
    rng = MersenneTwister(seed)
    nsire = max(2, round(Int, 0.04q))
    ndam  = max(2, round(Int, 0.08q))
    noff  = q - nsire - ndam
    ped = halfsib_pedigree(nsire, ndam, noff)
    na = length(ped.ids)
    Ainv = pedigree_inverse(ped)
    # gene-drop
    u = zeros(na)
    @inbounds for i in 1:na
        s = ped.sire[i]; d = ped.dam[i]
        pa = s > 0 ? u[s] : 0.0
        pb = d > 0 ? u[d] : 0.0
        nknown = (s > 0) + (d > 0)
        msv = nknown == 0 ? 1.0 : (nknown == 1 ? 0.75 : 0.5)
        u[i] = 0.5 * (pa + pb) + sqrt(1.0 * msv) * randn(rng)
    end
    n = na
    X = ones(n, 1)
    y = 5.0 .+ u
    effects = Tuple{SparseMatrixCSC{Float64,Int},SparseMatrixCSC{Float64,Int}}[]
    push!(effects, (sparse(1.0I, n, na), Ainv))
    for k in 2:K
        ng = max(5, q ÷ (10 * k))
        Zk = spzeros(n, ng)
        for r in 1:n
            Zk[r, rand(rng, 1:ng)] = 1.0
        end
        y .+= Zk * (randn(rng, ng) .* 0.5)
        push!(effects, (Zk, sparse(1.0I, ng, ng)))
    end
    y .+= randn(rng, n)
    return y, X, effects
end

function push_row!(rows; cell, kind, pair, before_s, after_s, speedup, host, totoro,
                   sha, note)
    push!(rows, (
        cell = cell, kind = kind, pair = pair,
        before_s = before_s, after_s = after_s, speedup = speedup,
        host = host, totoro = totoro, sha = sha, note = note,
    ))
end

function main()
    sha = git_sha()
    host = gethostname()
    out = "sim/results/e2e_wall_receipts_$(sha).tsv"
    rows = NamedTuple[]

    println("# HSquared.jl e2e wall receipts  $(Dates.now())")
    println("# git_sha=$sha  julia=$(VERSION)  host=$host")
    println("# $(BLAS.get_config())")
    println("# JULIA_NUM_THREADS=$(Threads.nthreads())  OPENBLAS_NUM_THREADS=$(get(ENV, "OPENBLAS_NUM_THREADS", "unset"))")
    println("# NOT CI / OPT-IN. No public performance claim.")

    # --- live: animal REML halfsib ladder (vs June-2026 banked) -------------
    hist = Dict(
        500  => (nsire=20, ndam=40, noff=440, before=0.0230),
        2000 => (nsire=80, ndam=160, noff=1760, before=0.0840),
        8000 => (nsire=320, ndam=640, noff=7040, before=0.3340),
    )
    for (q_target, cfg) in sort(collect(hist); by = first)
        @printf("  animal REML halfsib ~q=%d ...\n", q_target); flush(stdout)
        spec, q, nnzA = animal_spec(cfg.nsire, cfg.ndam, cfg.noff)
        med, mn = median_wall(() -> fit_ai_reml(spec))
        push_row!(rows;
            cell = "animal_reml_halfsib_q$(q)",
            kind = "animal_REML",
            pair = "historical_vs_now",
            before_s = cfg.before,
            after_s = med,
            speedup = cfg.before / med,
            host = host, totoro = "N", sha = sha,
            note = "before=2026-06-20 cpu_fit baseline Mac; after=this run median-of-$(N_REP) min=$(round(mn; digits=4)) nnzA=$(nnzA)")
    end

    # --- live: post-fit uncertainty dense vs selinv -------------------------
    @printf("  post-fit PEV q≈500 (selinv live; dense=banked hist)...\n"); flush(stdout)
    begin
        spec, q, _ = animal_spec(20, 40, 440)
        fit = fit_ai_reml(spec)
        med_s, _ = median_wall(() -> prediction_error_variance(fit; method = :selinv))
        # dense PEV banked 2026-06-20 at q≈500 = 0.0125s (avoid re-compiling dense path here)
        med_d = 0.0125
        push_row!(rows;
            cell = "postfit_pev_q$(q)",
            kind = "post_fit_uncertainty",
            pair = "dense_vs_selinv",
            before_s = med_d,
            after_s = med_s,
            speedup = med_d / med_s,
            host = host, totoro = "N", sha = sha,
            note = "before=dense PEV banked 2026-06-20 0.0125s; after=selinv PEV this-run")
        push_row!(rows;
            cell = "postfit_pev_q$(q)_selinv_vs_hist",
            kind = "post_fit_uncertainty",
            pair = "historical_vs_now",
            before_s = 0.0002,  # selinv hist
            after_s = med_s,
            speedup = 0.0002 / med_s,
            host = host, totoro = "N", sha = sha,
            note = "selinv PEV: before=2026-06-20 0.0002s; after=this-run (machine/noise; not a win claim)")
    end

    # --- live: multi-effect K=2 small + K=3 modest --------------------------
    for (q, K) in ((500, 2), (1000, 3))
        @printf("  multi-effect K=%d q=%d ...\n", K, q); flush(stdout)
        y, X, effects = multi_effect_case(q, K)
        med_sp, _ = median_wall(() -> fit_sparse_multi_effect_aireml(y, X, effects; em_warmup = 0))
        # dense only at q<=500 for wall budget
        push_row!(rows;
            cell = "multi_effect_K$(K)_q$(q)_sparse_mac",
            kind = "multi_effect",
            pair = "measured_after_only",
            before_s = NaN,
            after_s = med_sp,
            speedup = NaN,
            host = host, totoro = "N", sha = sha,
            note = "sparse AI-REML Mac live; dense paired walls banked on Totoro phase5")
    end

    # --- large benign pedigree: S1 banked (q=20k live segfaulted CHOLMOD once) -
    @printf("  animal REML halfsib q=20000 (S1 banked)...\n"); flush(stdout)
    begin
        # S1: iter_tot median 0.0085s × 15 iters
        med = 15 * 0.0085
        push_row!(rows;
            cell = "animal_reml_halfsib_q20000_large",
            kind = "large_pedigree",
            pair = "measured_now",
            before_s = med,
            after_s = med,
            speedup = 1.0,
            host = "Apple M1 Ultra", totoro = "N", sha = "c8cf8e05",
            note = "S1 banked: iter_tot×n_iter on benign halfsib; selinv~12% share; SelectedInversion NOT a win (S2 S_c≪1 on benign). Live q=20k fit segfaulted once in this session — banked instrumented proxy used instead.")
    end

    # --- live: high-fill e2e + projected SelectedInversion win --------------
    @printf("  animal REML f0adv q=5000 fill~150 (S1×S2 projection)...\n"); flush(stdout)
    begin
        # S1 instrumented: iter_tot median 5.5896s × 5 iters ≈ e2e proxy on Mac
        # (full fit wall ≈ n_iter × iter_total; S1 recorded 5 iterations at this fixture)
        n_iter = 5
        iter_tot = 5.5896
        med = n_iter * iter_tot
        share = 0.993
        S_c = 284.39
        proj = med * (1 - share) + med * share / S_c
        push_row!(rows;
            cell = "animal_reml_f0adv_q5000_fill150_projected",
            kind = "animal_REML",
            pair = "projected_selinv",
            before_s = med,
            after_s = proj,
            speedup = med / proj,
            host = "Apple M1 Ultra", totoro = "N", sha = "c8cf8e05×9be11566",
            note = "before=S1 iter_tot×n_iter (5.5896×5); after=selinv section replaced by SelectedInversion at S_c=284 from S2. NOT a wired e2e fit; src/ unchanged.")
    end

    # --- banked: sparse selinv kernel (from S2 TSVs) ------------------------
    push_row!(rows;
        cell = "selinv_kernel_mac_f0adv_q20k_fill150",
        kind = "sparse_selinv",
        pair = "kernel_a_vs_c",
        before_s = 236.894,
        after_s = 0.8330,
        speedup = 284.39,
        host = "Apple M1 Ultra", totoro = "N", sha = "9be11566",
        note = "bench/results/selinv_arms_9be11566_t1.tsv; arm a=Takahashi+diag, arm c=SelectedInversion")
    push_row!(rows;
        cell = "selinv_kernel_totoro_f0adv_q20k_fill471",
        kind = "sparse_selinv",
        pair = "kernel_a_vs_c",
        before_s = 1211.638,
        after_s = 4.0304,
        speedup = 300.62,
        host = "AMD EPYC 9655", totoro = "Y", sha = "b68bde5a",
        note = "bench/results/selinv_arms_b68bde5a_totoro_q20000_fill471.tsv")
    # projected whole-fit at Totoro fill471: nearly all wall is selinv
    push_row!(rows;
        cell = "animal_reml_f0adv_q20k_fill471_projected",
        kind = "large_pedigree",
        pair = "projected_selinv",
        before_s = 1211.638,  # one selinv pass ≈ one iter; full fit = iters × this
        after_s = 4.0304,
        speedup = 300.62,
        host = "AMD EPYC 9655", totoro = "Y", sha = "b68bde5a",
        note = "PROXY: one AI-REML selinv pass (trace+diag), not full multi-iter fit; S1 says selinv≈99% of iter at high fill so whole-fit speedup ≈ S_c")

    # --- banked: Totoro phase5 multi-effect / large scale -------------------
    # medians from phase5_sparse_benchmark_K3.tsv / K1.tsv (host=totoro)
    push_row!(rows;
        cell = "multi_effect_K3_q1000_totoro",
        kind = "multi_effect",
        pair = "dense_vs_sparse_me",
        before_s = 26.9279,
        after_s = 0.0409,
        speedup = 26.9279 / 0.0409,
        host = "totoro", totoro = "Y", sha = "phase5-2026-07-02",
        note = "sim/phase5_sparse_benchmark_K3.tsv medians; estimator confound disclosed")
    push_row!(rows;
        cell = "multi_effect_K3_q5000_totoro_sparse",
        kind = "multi_effect",
        pair = "measured_after_only",
        before_s = NaN,
        after_s = 1.8326,
        speedup = NaN,
        host = "totoro", totoro = "Y", sha = "phase5-2026-07-02",
        note = "K3 sparse only (dense infeasible); phase5_sparse_benchmark_K3.tsv")
    push_row!(rows;
        cell = "large_pedigree_K1_q50000_totoro",
        kind = "large_pedigree",
        pair = "measured_after_only",
        before_s = NaN,
        after_s = 0.3011,
        speedup = NaN,
        host = "totoro", totoro = "Y", sha = "phase5-2026-07-02",
        note = "K1=animal sparse AI-REML; phase5_sparse_benchmark_K1.tsv median")
    push_row!(rows;
        cell = "large_pedigree_K1_q20000_totoro",
        kind = "large_pedigree",
        pair = "measured_after_only",
        before_s = NaN,
        after_s = 0.0859,
        speedup = NaN,
        host = "totoro", totoro = "Y", sha = "phase5-2026-07-02",
        note = "K1 sparse; phase5_sparse_benchmark_K1.tsv median")

    # write TSV
    open(out, "w") do io
        println(io, "# HSquared.jl e2e wall receipts  $(Dates.now())")
        println(io, "# git_sha=$sha  julia=$(VERSION)  host=$host")
        println(io, "# $(BLAS.get_config())")
        println(io, "# JULIA_NUM_THREADS=$(Threads.nthreads())  OPENBLAS_NUM_THREADS=$(get(ENV, "OPENBLAS_NUM_THREADS", "unset"))")
        println(io, "# NOT CI / OPT-IN. No public performance claim. R twin: no parallel wall-receipt harness.")
        println(io, "cell\tkind\tpair\tbefore_s\tafter_s\tspeedup\thost\ttotoro\tsha\tnote")
        for r in rows
            b = isnan(r.before_s) ? "" : @sprintf("%.6f", r.before_s)
            a = isnan(r.after_s) ? "" : @sprintf("%.6f", r.after_s)
            s = isnan(r.speedup) ? "" : @sprintf("%.3f", r.speedup)
            note = replace(r.note, '\t' => ' ', '\n' => ' ')
            println(io, "$(r.cell)\t$(r.kind)\t$(r.pair)\t$b\t$a\t$s\t$(r.host)\t$(r.totoro)\t$(r.sha)\t$note")
        end
    end

    println()
    println("Wrote $out  ($(length(rows)) cells)")
    println()
    @printf("%-42s %-22s %10s %10s %8s %s\n", "cell", "kind", "before", "after", "speedup", "Totoro")
    for r in rows
        b = isnan(r.before_s) ? "—" : @sprintf("%.4f", r.before_s)
        a = isnan(r.after_s) ? "—" : @sprintf("%.4f", r.after_s)
        s = isnan(r.speedup) ? "—" : @sprintf("%.1fx", r.speedup)
        @printf("%-42s %-22s %10s %10s %8s %s\n", r.cell, r.kind, b, a, s, r.totoro)
    end
end

main()
