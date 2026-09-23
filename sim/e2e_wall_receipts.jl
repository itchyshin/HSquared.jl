#!/usr/bin/env julia
# ============================================================================
# NOT CI / OPT-IN measurement only.
#
# End-of-arc e2e fit / post-fit wall receipts for HSquared.jl.
# Fills three-package-speed-board.md H² `needs_run` rows on post-#371 tip,
# plus ≥1 multi-effect and ≥1 large-pedigree cell so the board gets ≥5
# attested e2e walls (not kernel-only).
#
# Board cell_ids (primary):
#   hsq-animal-fit-q500 / q2000 / q10000
#   hsq-pev-reliability-q500
# Extra e2e (diversity):
#   hsq-multi-effect-K2-q500
#   hsq-animal-fit-q20000-large
#
# Before/after meaning (column `pair`):
#   historical_vs_now  — 2026-06-20 cpu_fit baseline vs this-run wall
#   dense_vs_selinv    — dense post-fit PEV vs sparse selinv PEV
#   dense_vs_sparse_me — dense NelderMead multi-effect vs sparse AI-REML
#   measured_now       — absolute wall only (no paired before on same host)
#
# Sibling #378 speed12 / projected / phase5 receipts stay banked in
#   sim/results/e2e_wall_receipts_fc3fc938.tsv  (different cell_ids).
# This harness covers board H² cell_ids only (merge resolved add/add vs #378).
#
# Usage (lane / worktree root):
#   env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
#       julia --project=. sim/e2e_wall_receipts.jl [--quick] [--large] [--core]
# ============================================================================

using HSquared
using LinearAlgebra
using SparseArrays
using Printf
using Random
using Dates
using Statistics

# Pin BLAS before any dense path — OpenBLAS dgetrf_parallel/exec_blas_async can
# hang when OPENBLAS_NUM_THREADS=1 is only an env hint and workers still spawn.
BLAS.set_num_threads(1)

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

function gene_drop_y(ped; sigma_a2 = 1.0, sigma_e2 = 1.0, mu = 5.0, seed = 20260923)
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

"""Animal REML spec. Default `y_mode=:genedrop` (recoverable signal, converges).
`:cpu_fit` is the 2026-06-20 deterministic null-ish y (hits σ_a→0 boundary)."""
function animal_spec(nsire, ndam, noff; y_mode::Symbol = :genedrop)
    ped = halfsib_pedigree(nsire, ndam, noff)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    y = y_mode === :cpu_fit ? make_y(q) : gene_drop_y(ped)
    X = ones(q, 1)
    Z = sparse(1.0 * I, q, q)
    return animal_model_spec(y, X, Z, Ainv; method = :REML), q, nnz(Ainv)
end

function multi_effect_case(q::Int, K::Int; seed::Int = 20260702)
    rng = MersenneTwister(seed)
    nsire = max(2, round(Int, 0.04q))
    ndam  = max(2, round(Int, 0.08q))
    noff  = q - nsire - ndam
    ped = halfsib_pedigree(nsire, ndam, noff)
    na = length(ped.ids)
    Ainv = pedigree_inverse(ped)
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

function write_tsv(out, rows, sha, host)
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
end

function print_table(rows)
    @printf("%-36s %-22s %10s %10s %8s %s\n", "cell", "kind", "before", "after", "speedup", "Totoro")
    for r in rows
        b = isnan(r.before_s) ? "—" : @sprintf("%.4f", r.before_s)
        a = isnan(r.after_s) ? "—" : @sprintf("%.4f", r.after_s)
        s = isnan(r.speedup) ? "—" : @sprintf("%.1fx", r.speedup)
        @printf("%-36s %-22s %10s %10s %8s %s\n", r.cell, r.kind, b, a, s, r.totoro)
    end
end

function main()
    args = Set(String.(ARGS))
    do_quick = "--quick" in args || isempty(ARGS) || "--core" in args
    do_large = "--large" in args || isempty(ARGS) || "--core" in args
    # --quick alone: board needs_run + multi-effect only (no q10k/q20k)
    if "--quick" in args && !("--large" in args) && !("--core" in args)
        do_large = false
    end
    if "--large" in args && !("--quick" in args) && !("--core" in args)
        do_quick = false
    end

    sha = git_sha()
    host = gethostname()
    on_totoro = occursin("totoro", lowercase(host))
    totoro_flag = on_totoro ? "Y" : "N"
    out = "sim/results/e2e_wall_receipts_$(sha).tsv"
    mkpath("sim/results")
    rows = NamedTuple[]

    println("# HSquared.jl e2e wall receipts  $(Dates.now())")
    println("# git_sha=$sha  julia=$(VERSION)  host=$host")
    println("# $(BLAS.get_config())")
    println("# JULIA_NUM_THREADS=$(Threads.nthreads())  OPENBLAS_NUM_THREADS=$(get(ENV, "OPENBLAS_NUM_THREADS", "unset"))")
    println("# NOT CI / OPT-IN. No public performance claim.")
    println("# modes: quick=$(do_quick) large=$(do_large)")

    if do_quick
        # Board animal fit cells: gene-drop y (June cpu_fit y is near-null boundary
        # and hits iteration_limit — not a fair e2e fit wall). Soft-compare to
        # June walls only as context in the note, pair = measured_now / soft_hist.
        ladder = [
            (nsire=20, ndam=40, noff=440, hist=0.0230, cell="hsq-animal-fit-q500"),
            (nsire=80, ndam=160, noff=1760, hist=0.0840, cell="hsq-animal-fit-q2000"),
        ]
        for cfg in ladder
            @printf("  %s ...\n", cfg.cell); flush(stdout)
            spec, q, nnzA = animal_spec(cfg.nsire, cfg.ndam, cfg.noff)
            fit0 = fit_ai_reml(spec)
            med, mn = median_wall(() -> fit_ai_reml(spec))
            push_row!(rows;
                cell = cfg.cell,
                kind = "animal_REML",
                pair = "measured_now",
                before_s = cfg.hist,
                after_s = med,
                speedup = cfg.hist / med,
                host = host, totoro = totoro_flag, sha = sha,
                note = "after=gene-drop halfsib post-#371 median-of-$(N_REP) conv=$(fit0.converged) iters=$(fit0.iterations) min=$(round(mn; digits=4)) q=$(q) nnzA=$(nnzA); before=2026-06-20 cpu_fit wall (DIFFERENT y=deterministic near-null — soft context only, not same-DGP)")
        end

        @printf("  hsq-pev-reliability-q500 ...\n"); flush(stdout)
        begin
            spec, q, _ = animal_spec(20, 40, 440)
            fit = fit_ai_reml(spec)
            @printf("    fit conv=%s iters=%s\n", fit.converged, fit.iterations); flush(stdout)
            @printf("    selinv PEV ...\n"); flush(stdout)
            med_s, _ = median_wall(() -> prediction_error_variance(fit; method = :selinv))
            # Dense MME inv deadlocks OpenBLAS dgetrf_parallel/exec_blas_async on this
            # host under OPENBLAS_NUM_THREADS=1. Pair against the banked 2026-06-20
            # dense wall (same q500 halfsib scale) — matches speed12 TSV honesty.
            med_d = 0.0125
            push_row!(rows;
                cell = "hsq-pev-reliability-q500",
                kind = "post_fit_uncertainty",
                pair = "dense_vs_selinv",
                before_s = med_d,
                after_s = med_s,
                speedup = med_d / med_s,
                host = host, totoro = totoro_flag, sha = sha,
                note = "before=dense PEV banked 2026-06-20 cpu_fit 0.0125s (live dense skipped: OpenBLAS hang); after=selinv median-of-$(N_REP); gene-drop fit conv=$(fit.converged)")
        end

        @printf("  hsq-multi-effect-K2-q500 ...\n"); flush(stdout)
        begin
            y, X, effects = multi_effect_case(500, 2)
            med_sp, _ = median_wall(() -> fit_sparse_multi_effect_aireml(y, X, effects; em_warmup = 0))
            # dense NelderMead: 1 timed rep after warm-up (can be slow)
            fit_multi_effect_reml(y, X, effects; max_dense_cells = 4_000_000)
            GC.gc()
            med_dn = @elapsed fit_multi_effect_reml(y, X, effects; max_dense_cells = 4_000_000)
            push_row!(rows;
                cell = "hsq-multi-effect-K2-q500",
                kind = "multi_effect",
                pair = "dense_vs_sparse_me",
                before_s = med_dn,
                after_s = med_sp,
                speedup = med_dn / med_sp,
                host = host, totoro = totoro_flag, sha = sha,
                note = "before=dense NelderMead (1 timed rep); after=sparse AI-REML median-of-$(N_REP); estimator confound disclosed")
        end
    end

    if do_large
        @printf("  hsq-animal-fit-q10000 ...\n"); flush(stdout)
        begin
            spec, q, nnzA = animal_spec(400, 800, 8800)
            fit0 = fit_ai_reml(spec)
            med, mn = median_wall(() -> fit_ai_reml(spec))
            push_row!(rows;
                cell = "hsq-animal-fit-q10000",
                kind = "animal_REML",
                pair = "measured_now",
                before_s = NaN,
                after_s = med,
                speedup = NaN,
                host = host, totoro = totoro_flag, sha = sha,
                note = "gene-drop halfsib post-#371; conv=$(fit0.converged) iters=$(fit0.iterations); q=$(q) nnzA=$(nnzA) min=$(round(mn; digits=4)); June q8k hist=0.3340s different DGP")
        end

        @printf("  hsq-animal-fit-q20000-large ...\n"); flush(stdout)
        begin
            nsire = max(2, round(Int, 20000 * 0.05))
            ndam  = max(4, round(Int, 20000 * 0.10))
            noff  = 20000 - nsire - ndam
            spec, q, nnzA = animal_spec(nsire, ndam, noff)
            fit0 = fit_ai_reml(spec)
            med, mn = median_wall(() -> fit_ai_reml(spec))
            push_row!(rows;
                cell = "hsq-animal-fit-q20000-large",
                kind = "large_pedigree",
                pair = "measured_now",
                before_s = NaN,
                after_s = med,
                speedup = NaN,
                host = host, totoro = totoro_flag, sha = sha,
                note = "gene-drop halfsib large e2e; conv=$(fit0.converged) iters=$(fit0.iterations); nnzA=$(nnzA) min=$(round(mn; digits=4))")
        end
    end

    write_tsv(out, rows, sha, host)
    println()
    println("Wrote $out  ($(length(rows)) cells)")
    println()
    print_table(rows)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
