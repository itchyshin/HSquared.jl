#!/usr/bin/env julia
# ============================================================================
# NOT CI / OPT-IN measurement only. bench/ is a SEPARATE environment
# (bench/Project.toml) from the package -- SelectedInversion.jl is an oracle
# used here, never a package dependency (D-271: it can only ever enter
# HSquared.jl as an optional weak-dependency extension, behind the existing
# fallback, after a measured >= 10x kernel win; never a hard dependency, and
# never in the package Project.toml -- which this script changes nothing in).
#
# Arc S2b (speed2b-20260919): re-measures the S2 selected-inverse arms on
# Szymek's rewritten kernel (origin/main b9f30a64, src/takahashi_selinv.jl
# last touched by 6bb10c97 -- claimed bit-identical output, 6.65x-9.97x
# faster than the kernel S2 measured; THIS FILE'S OWN PROBE at the highest-
# fill Mac fixture found only ~1.65x here -- see the budget note below, the
# claimed range is evidently fixture/clique-width dependent, not universal).
# D-271's decision rule is applied to THIS (new-kernel) number.
#
# Two arms, each split into its two independent calls exactly as the leaf
# ledger (.unlazy/julia-speed-20260919/gates/leaf-S2b.md) asks, so the
# per-call cost of the REAL fit_ai_reml hot path (trace only, every
# iteration) is never hidden inside a combined trace+diag figure:
#
#   (a) the current (post-6bb10c97) kernel, called exactly as fit_ai_reml
#       uses it:
#         a_trace = `HSquared.selinv_trace_against(F, Ainv, nfixed)`
#         a_diag  = `HSquared.takahashi_diag(F)`
#   (c) `SelectedInversion.jl`, split the same way:
#         c_trace = `SelectedInversion.selinv(F; depermute=false)` then
#                   `dot(Z, B_perm)` (Ainv embedded at the random-effect
#                   block and permuted into F's ordering ONCE per fixture --
#                   a `selinv_extract_setup`-style reusable plan -- then
#                   reused, unchanged, across every refactorization of that
#                   fixture)
#         c_diag  = `SelectedInversion.selinv_diag(F)`
#
# Arm (b) (the dependency-free L-hoisting half-step S2 measured) is DROPPED
# here -- Szymek's rewrite of `_selinv_zvals` (dense per-clique block, still
# zero new dependencies) IS that half-step now, measured as arm (a).
#
# No src/ edit: this file changes nothing in src/, sim/, or any Project.toml.
#
# CLI:
#   --gate {agree|record|verdict}
#   --totoro-arm
#   --install-weight
#   --probe-a-q20000-fill150
#   (no args) full grid, writes bench/results/selinv_arms_<harness sha>_t<threads>.tsv
#
# Usage:
#   env JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 \
#       julia --project=bench bench/selinv_arms.jl [--gate ...]
# ============================================================================

using HSquared
using SelectedInversion
using LinearAlgebra
using SparseArrays
using Printf
using Random
using Dates

const CM = SparseArrays.CHOLMOD
const LSS = SparseArrays.LibSuiteSparse

# ---------------------------------------------------------------------------
# CHOLMOD supernodal/simplicial forcing and inspection (public SparseArrays
# stdlib internals; no src/ edit, no new dependency).
# ---------------------------------------------------------------------------

_is_super(F::CM.Factor) = Bool(unsafe_load(F.ptr).is_super)

# mode ∈ (:auto, :simplicial, :supernodal). Affects every subsequent
# cholesky()/cholesky!() call in this process until reset.
function _force_mode!(mode::Symbol)
    common = CM.getcommon(Int64)
    common[].supernodal = mode === :simplicial ? LSS.CHOLMOD_SIMPLICIAL :
                           mode === :supernodal ? LSS.CHOLMOD_SUPERNODAL :
                           LSS.CHOLMOD_AUTO
    return nothing
end

# ---------------------------------------------------------------------------
# Fixtures. F0 adversarial + w4 half-sib generators reproduced (not
# `include`d -- see the S1 harness for why) from sim/drac/f0_adversarial_fill.jl
# and sim/drac/f0_scale_benchmark.jl. Unchanged from the S2 harness: fixture
# generation does not touch the selected-inverse kernel under test, so it
# stays bit-for-bit the same generator S2 used (same seeds).
# ---------------------------------------------------------------------------

function _f0_adversarial_pedigree(q::Int; nfounder_frac::Float64 = 0.005, seed::Int = 20260724)
    rng = MersenneTwister(seed)
    nf = max(4, round(Int, nfounder_frac * q))
    ids = ["a$i" for i in 1:q]
    sire = fill("0", q)
    dam = fill("0", q)
    @inbounds for i in (nf + 1):q
        p = rand(rng, 1:(i - 1))
        m = rand(rng, 1:(i - 1))
        while m == p
            m = rand(rng, 1:(i - 1))
        end
        sire[i] = ids[p]
        dam[i] = ids[m]
    end
    return normalize_pedigree(ids, sire, dam)
end

function _f0_simulate_breeding_values(ped; sigma_a2 = 1.0, sigma_e2 = 1.0, mu = 5.0, seed = 20260724)
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

function f0adv_fixture(q::Int; nfounder_frac::Float64 = 0.005, seed::Int = 20260724)
    ped = _f0_adversarial_pedigree(q; nfounder_frac = nfounder_frac, seed = seed)
    Ainv = pedigree_inverse(ped)
    y = _f0_simulate_breeding_values(ped; seed = seed)
    X = ones(q, 1)
    Z = sparse(1.0 * I, q, q)
    return animal_model_spec(y, X, Z, Ainv; method = :REML)
end

function _mme_fill(spec::AnimalModelSpec)
    lhs, _, _ = HSquared._sparse_mme_system(spec, 1.0, 1.0)
    chf = cholesky(Symmetric(lhs); check = true)
    return nnz(sparse(chf.L)) / size(lhs, 1)
end

function find_nfounder_frac_for_fill(q::Int, target_fill::Real; seed::Int = 20260724)
    floor_frac = 4.0 / q
    candidates = sort(unique(vcat(
        floor_frac, [floor_frac * m for m in (2, 4, 8, 16, 32, 64)],
        [0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.3, 0.5, 0.7],
    )))
    filter!(f -> 0 < f <= 1, candidates)
    best_frac, best_fill, best_err = candidates[1], NaN, Inf
    for frac in candidates
        fill = _mme_fill(f0adv_fixture(q; nfounder_frac = frac, seed = seed))
        err = abs(fill - target_fill)
        if err < best_err
            best_frac, best_fill, best_err = frac, fill, err
        end
    end
    return best_frac, best_fill
end

# Benign half-sib generator (sim/drac/f0_scale_benchmark.jl's `halfsib`/
# `simulate_y`, reproduced): fill barely rises with q (AMD-near-optimal).
function _f0_scale_pedigree(q::Int)
    nsire = max(2, round(Int, 0.04q))
    ndam = max(2, round(Int, 0.08q))
    noff = q - nsire - ndam
    sire_ids = ["s$i" for i in 1:nsire]
    dam_ids = ["d$i" for i in 1:ndam]
    off_ids = ["o$i" for i in 1:noff]
    ids = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(fill("0", nsire + ndam), [sire_ids[((i - 1) % nsire) + 1] for i in 1:noff])
    dam = vcat(fill("0", nsire + ndam), [dam_ids[((i - 1) % ndam) + 1] for i in 1:noff])
    return normalize_pedigree(ids, sire, dam)
end

function f0scale_fixture(q::Int)
    ped = _f0_scale_pedigree(q)
    Ainv = pedigree_inverse(ped)
    y = _f0_simulate_breeding_values(ped; seed = 20260623)
    X = ones(q, 1)
    Z = sparse(1.0 * I, q, q)
    return animal_model_spec(y, X, Z, Ainv; method = :REML)
end

# Near-boundary sigma_a2 -> 0 fixture: a half-sib pedigree with a CONSTANT y
# (no genetic signal, test/runtests.jl's own boundary-contract pattern scaled
# up to a real sparse factor) at a tiny sigma_a2, mirroring the MME an
# AI-REML iteration sees while walking toward the sigma_a2 -> 0 boundary.
function boundary_fixture(q::Int = 2000)
    ped = _f0_scale_pedigree(q)
    Ainv = pedigree_inverse(ped)
    y = fill(5.0, q)
    X = ones(q, 1)
    Z = sparse(1.0 * I, q, q)
    return animal_model_spec(y, X, Z, Ainv; method = :REML)
end

# Deterministic small SPD sparse matrix (no RNG; same technique
# SelectedInversion.jl's own precompile workload uses) for the dense-inv pins.
function spd_fixture(n::Int; entries_per_row::Int = 6)
    I_idx = Int[]; J_idx = Int[]; V = Float64[]
    for i in 1:n, k in 0:(entries_per_row - 1)
        j = mod(i + k * 7 + k^2, n) + 1
        push!(I_idx, i); push!(J_idx, j); push!(V, 1.0 + mod(i * 3 + j * 5, 10) / 10.0)
    end
    A = sparse(I_idx, J_idx, V, n, n)
    return A * A' + 5.0 * I
end

# ---------------------------------------------------------------------------
# Arm (c) support: build the permuted Ainv "B_perm" ONCE per fixture (its
# pattern/permutation is invariant across numeric refactorizations of the
# same symbolic factor), reused across every repeat -- the
# selinv_extract_setup-style reusable plan the ledger asks for.
# ---------------------------------------------------------------------------

function build_B_perm(F::CM.Factor{Float64}, Ainv::SparseMatrixCSC, n::Int, nfixed::Integer)
    I_idx = Int[]; J_idx = Int[]; V = Float64[]
    rows = rowvals(Ainv); vals = nonzeros(Ainv)
    for jcol in 1:size(Ainv, 2)
        for k in nzrange(Ainv, jcol)
            push!(I_idx, nfixed + rows[k]); push!(J_idx, nfixed + jcol); push!(V, vals[k])
        end
    end
    B_full = sparse(I_idx, J_idx, V, n, n)
    p = F.p
    return B_full[p, p]
end

# ---------------------------------------------------------------------------
# One timed call per (arm, quantity). Each returns (value, wall_seconds, bytes).
# ---------------------------------------------------------------------------

function pass_a_trace(F::CM.Factor{Float64}, Ainv::SparseMatrixCSC, nfixed::Integer)
    stats = @timed HSquared.selinv_trace_against(F, Ainv, nfixed)
    return stats.value, stats.time, stats.bytes
end

function pass_a_diag(F::CM.Factor{Float64})
    stats = @timed HSquared.takahashi_diag(F)
    return stats.value, stats.time, stats.bytes
end

function pass_c_trace(F::CM.Factor{Float64}, B_perm::SparseMatrixCSC)
    stats = @timed begin
        Zp = SelectedInversion.selinv(F; depermute = false)
        LinearAlgebra.dot(Zp.Z, B_perm)
    end
    return stats.value, stats.time, stats.bytes
end

function pass_c_diag(F::CM.Factor{Float64})
    stats = @timed SelectedInversion.selinv_diag(F)
    return stats.value, stats.time, stats.bytes
end

# ---------------------------------------------------------------------------
# Fixture spec -> (spec, nfixed, Ainv) plus a spec->fixture-name registry used
# by the record/agree gates.
# ---------------------------------------------------------------------------

const MAIN_FIXTURES = Dict{String,Function}(
    "f0adv_q20000_fill75" => () -> f0adv_fixture(20_000; nfounder_frac = find_nfounder_frac_for_fill(20_000, 75.0)[1]),
    "f0adv_q20000_fill150" => () -> f0adv_fixture(20_000; nfounder_frac = find_nfounder_frac_for_fill(20_000, 150.0)[1]),
    "f0adv_q50000_fill75" => () -> f0adv_fixture(50_000; nfounder_frac = find_nfounder_frac_for_fill(50_000, 75.0)[1]),
    "f0scale_q20000" => () -> f0scale_fixture(20_000),
    "boundary_q2000" => () -> boundary_fixture(2000),
)

# NOTE: "fill150" is a legacy S2 NAME, not the achieved fill -- the S9
# verifier flagged that names are not fills; the S2 fixture's ACHIEVED fill
# is ~213.7 (find_nfounder_frac_for_fill picks the closest candidate frac to
# the *target* 150, and 213.7 is the closest this pedigree generator gets).
# Kept unrenamed here for continuity with the old-kernel TSV this arc
# compares against; the printed `fill` column always carries the true
# achieved value.
const HIGHEST_FILL_FIXTURE = "f0adv_q20000_fill150"

# BUDGET (measured, this arc's own probe): ONE arm-a pass (trace+diag,
# combined) at f0adv_q20000_fill150 (achieved fill ~213.7) costs ~144s on the
# NEW kernel -- an honest ~1.65x over the OLD kernel's 236.9s at the SAME
# fixture, well short of the 6.65x-9.97x Szymek's own file-header comment
# claims for "n=2,000-30,000" more generally. At ~144s/call (split roughly
# evenly between a_trace and a_diag, each independently re-running
# `_selinv_zvals`), a full reps=3-with-warm-up grid (4 calls/quantity) would
# cost this ONE fixture alone ~4*72*2 =~ 576s. f0adv_q50000_fill75 (old
# kernel 199.5s combined) is comparably expensive. Both, plus the
# forced-simplicial extra rung at the SAME highest-fill fixture, therefore
# run at `reps=1` (still WITH one warm-up per quantity -- an improvement
# over S2's own reps=1/no-warm-up economy, which the S9 verifier flagged)
# to keep the whole Mac grid under ~25 minutes. f0adv_q20000_fill75 (old
# kernel only 10.6s combined) stays cheap enough for the full reps=3.
const REDUCED_REPS_FIXTURES = Set(["f0adv_q20000_fill150", "f0adv_q50000_fill75"])

const REPS = 3
const REDUCED_REPS = 1

function _median(xs::Vector{Float64})
    return sort(xs)[cld(length(xs), 2)]
end

# ---------------------------------------------------------------------------
# Per-fixture measurement at fixed OPENBLAS_NUM_THREADS (assumed already set
# by the caller via ENV before this Julia process started -- BLAS thread
# count cannot be changed reliably mid-process for every backend, so each
# threads value is a SEPARATE `julia` invocation; see run_grid's caller).
# Every quantity (T_fact, a_trace, a_diag, c_trace, c_diag) gets its own
# ONE warm-up call before the timed `reps` repeats -- unconditionally, even
# when `reps == 1` (the S9-flagged gap in S2 was the missing warm-up, not
# the rep count alone).
# ---------------------------------------------------------------------------

function measure_fixture(spec::AnimalModelSpec; sigma_a2 = 1.0, sigma_e2 = 1.0,
                          reps::Int = REPS, force_mode::Symbol = :auto,
                          int32_ainv::Bool = false)
    Ainv0 = sparse(Float64.(spec.Ainv))
    Ainv = int32_ainv ? SparseMatrixCSC{Float64,Int32}(Ainv0) : Ainv0
    nfixed = size(spec.X, 2)
    n = size(spec.X, 2) + size(spec.Z, 2)

    _force_mode!(force_mode)
    lhs, _, _ = HSquared._sparse_mme_system(spec, sigma_a2, sigma_e2)
    lhs_sym = Symmetric(lhs)

    GC.gc()
    F = cholesky(lhs_sym; check = true)
    is_super = _is_super(F)
    nnzC = nnz(lhs) # upper+lower as stored; informational
    nnzL = nnz(sparse(F.L))
    fill = nnzL / n
    idx_eltype = eltype(rowvals(Ainv))

    # T_fact: numeric refactorization reusing symbolic analysis (cholesky!),
    # median of `reps` after one warm-up.
    cholesky!(F, lhs_sym; check = true)
    fact_times = Float64[]
    for _ in 1:max(reps, 1)
        stats = @timed cholesky!(F, lhs_sym; check = true)
        push!(fact_times, stats.time)
    end
    T_fact = _median(fact_times)

    # Arm (a): a_trace and a_diag, each its own warm-up + reps repeats.
    pass_a_trace(F, Ainv, nfixed)
    at_times = Float64[]; trace_a = nothing
    for _ in 1:max(reps, 1)
        v, wall, _ = pass_a_trace(F, Ainv, nfixed)
        trace_a = v
        push!(at_times, wall)
    end
    T_a_trace = _median(at_times)

    pass_a_diag(F)
    ad_times = Float64[]; diag_a = nothing
    for _ in 1:max(reps, 1)
        v, wall, _ = pass_a_diag(F)
        diag_a = v
        push!(ad_times, wall)
    end
    T_a_diag = _median(ad_times)

    # Arm (c): build B_perm once, then warm-up + reps repeats per quantity.
    B_perm = build_B_perm(F, Ainv, n, nfixed)

    pass_c_trace(F, B_perm)
    ct_times = Float64[]; trace_c = nothing
    for _ in 1:max(reps, 1)
        v, wall, _ = pass_c_trace(F, B_perm)
        trace_c = v
        push!(ct_times, wall)
    end
    T_c_trace = _median(ct_times)

    pass_c_diag(F)
    cd_times = Float64[]; diag_c = nothing
    for _ in 1:max(reps, 1)
        v, wall, _ = pass_c_diag(F)
        diag_c = v
        push!(cd_times, wall)
    end
    T_c_diag = _median(cd_times)

    err_trace_c = abs(trace_c - trace_a) / max(abs(trace_a), eps())
    err_diag_c = maximum(abs.(diag_c .- diag_a)) / max(maximum(abs.(diag_a)), eps())
    err_c = max(err_trace_c, err_diag_c)

    _force_mode!(:auto)

    return (
        q = n, nfixed = nfixed, nnz_C = nnzC, nnz_L = nnzL, fill = fill,
        is_super = is_super, index_eltype = idx_eltype,
        T_fact = T_fact,
        T_a_trace = T_a_trace, T_a_diag = T_a_diag,
        T_c_trace = T_c_trace, T_c_diag = T_c_diag,
        S_c_trace = T_a_trace / T_c_trace, S_c_diag = T_a_diag / T_c_diag,
        R_c_trace = T_c_trace / T_fact,
        err_c = err_c,
        trace_a = trace_a, trace_c = trace_c, diag_a = diag_a, diag_c = diag_c,
    )
end

# ---------------------------------------------------------------------------
# Header / environment info
# ---------------------------------------------------------------------------

# Totoro receives an rsync of this worktree WITHOUT .git (see the ROLE's own
# sync step), so `git log` there always fails. `bench/GIT_SHAS.txt` (written
# by `_write_git_shas_cache` on the Mac, where .git IS present, and synced
# alongside the rest of bench/) is the fallback read on any host where the
# live git query fails, so the Totoro run still prints/asserts the same shas
# instead of silently degrading to "unknown".
function _cached_git_shas()
    path = joinpath(@__DIR__, "GIT_SHAS.txt")
    isfile(path) || return Dict{String,String}()
    d = Dict{String,String}()
    for line in readlines(path)
        parts = split(line, "="; limit = 2)
        length(parts) == 2 && (d[parts[1]] = parts[2])
    end
    return d
end

function _harness_commit_sha()
    try
        sha = strip(read(`git log -1 --format=%h -- $(@__FILE__)`, String))
        isempty(sha) && error("empty git log (uncommitted)")
        return sha
    catch
        return get(_cached_git_shas(), "harness_sha", "unknown")
    end
end

function _kernel_commit_sha()
    try
        path = joinpath(@__DIR__, "..", "src", "takahashi_selinv.jl")
        sha = strip(read(`git log -1 --format=%H -- $(path)`, String))
        isempty(sha) && error("empty git log")
        return sha
    catch
        return get(_cached_git_shas(), "kernel_sha", "unknown")
    end
end

# Run on the Mac (where .git exists) after committing bench/selinv_arms.jl,
# so the cache reflects the FINAL harness commit. Call via:
#   julia --project=bench -e 'include("bench/selinv_arms.jl")' --write-git-shas
# (invoked from the CLI branch below) then rsync bench/GIT_SHAS.txt to Totoro.
function _write_git_shas_cache()
    path = joinpath(@__DIR__, "GIT_SHAS.txt")
    open(path, "w") do io
        println(io, "harness_sha=$(_harness_commit_sha())")
        println(io, "kernel_sha=$(_kernel_commit_sha())")
    end
    println("wrote ", path)
    return path
end

function _cpu_model()
    try
        info = Sys.cpu_info()
        return isempty(info) ? "unknown" : info[1].model
    catch
        return "unknown"
    end
end

function _manifest_diff_lines()
    lines = String[]
    try
        manifest = joinpath(@__DIR__, "Manifest.toml")
        txt = read(manifest, String)
        pkgs = String[]
        for m in eachmatch(r"\[\[deps\.([A-Za-z0-9_]+)\]\]", txt)
            push!(pkgs, m.captures[1])
        end
        pkgs = sort(unique(pkgs))
        jlls = filter(p -> endswith(p, "_jll"), pkgs)
        root_deps = Set(["LinearAlgebra", "Optim", "Random", "SHA", "SparseArrays"])
        added = filter(p -> !(p in root_deps) && p != "HSquared", pkgs)
        push!(lines, "# bench Manifest: $(length(pkgs)) packages total, $(length(added)) added vs the package env's 5 direct deps (this is the BENCH env's own resolution cost, NOT the package-env install weight -- see the install-weight line below for G2b.3's actual quantity)")
        push!(lines, "# bench Manifest _jll packages: $(join(jlls, ", "))")
        push!(lines, "# bench Manifest added (non-stdlib, non-root-dep): $(join(added, ", "))")
    catch e
        push!(lines, "# bench Manifest diff: could not compute ($(sprint(showerror, e)))")
    end
    return lines
end

# G2b.3's "exact install weight of adding SelectedInversion to a COPY of the
# PACKAGE env" (not this bench Manifest, which resolves 55+ transitive deps
# because Optim pulls in ForwardDiff/NLSolversBase/etc -- that count is the
# Manifest-vs-Project error the S9 verifier caught for S2, and this file
# must not repeat it). Measured separately (see `measure_install_weight`,
# `--install-weight`) because it does a real `Pkg.add` + precompile -- too
# slow to redo on every gate invocation, so it is cached to a small file and
# read back here.
function _install_weight_lines()
    path = joinpath(@__DIR__, "results", "install_weight_b9f30a64.txt")
    if isfile(path)
        cached_lines = split(strip(read(path, String)), "\n")
        return vcat("# install weight (package env + SelectedInversion, measured separately via --install-weight):",
                    ["#   $(l)" for l in cached_lines])
    else
        return ["# install weight: NOT YET MEASURED (run `julia --project=bench bench/selinv_arms.jl --install-weight` first)"]
    end
end

function _header_lines()
    sv_version = try
        string(pkgversion(SelectedInversion))
    catch
        "unknown"
    end
    ss_jll_version = try
        string(pkgversion(SparseArrays.LibSuiteSparse))
    catch
        "unknown"
    end
    lines = [
        "# HSquared.jl selected-inverse arm bench (arc S2b, re-based on Szymek's kernel)  $(Dates.now())",
        "# harness_git_sha=$(_harness_commit_sha())  kernel_git_sha=$(_kernel_commit_sha())  julia=$(VERSION)  os=$(Sys.KERNEL) $(Sys.MACHINE)",
        "# blas=$(BLAS.get_config())",
        "# JULIA_NUM_THREADS=$(Threads.nthreads())  OPENBLAS_NUM_THREADS=$(get(ENV, "OPENBLAS_NUM_THREADS", "unset"))",
        "# cpu=$(_cpu_model())",
        "# SelectedInversion=$(sv_version)  SuiteSparse(LibSuiteSparse module)=$(ss_jll_version)",
        "# NOT CI / OPT-IN measurement only. No performance claim, no regression gate.",
    ]
    append!(lines, _manifest_diff_lines())
    append!(lines, [replace(l, "\n" => " / ") for l in _install_weight_lines()])
    return lines
end

function write_tsv(io::IO, rows)
    println(io, join(_header_lines(), "\n"))
    cols = ["fixture", "threads", "forced_mode", "q", "nfixed", "nnz_C", "nnz_L", "fill",
            "is_super", "index_eltype", "T_fact",
            "T_a_trace", "T_a_diag", "T_c_trace", "T_c_diag",
            "S_c_trace", "S_c_diag", "R_c_trace", "err_c"]
    println(io, join(cols, "\t"))
    for r in rows
        @printf(io, "%s\t%d\t%s\t%d\t%d\t%d\t%d\t%.3f\t%s\t%s\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.2f\t%.2f\t%.4f\t%.3e\n",
                r.fixture, r.threads, r.forced_mode, r.q, r.nfixed, r.nnz_C, r.nnz_L, r.fill,
                r.is_super, r.index_eltype, r.T_fact,
                r.T_a_trace, r.T_a_diag, r.T_c_trace, r.T_c_diag,
                r.S_c_trace, r.S_c_diag, r.R_c_trace, r.err_c)
    end
end

# ---------------------------------------------------------------------------
# G2b.1 precondition check (also asserted by the ledger's own CHECK line via
# git diff, outside this file) -- fail loudly rather than silently measuring
# the wrong kernel if this file is ever run against a stale checkout.
# ---------------------------------------------------------------------------

const EXPECTED_KERNEL_SHA = "6bb10c97ea82cfa492dfe454912dfa9c9176dce3"

function _assert_kernel_sha!()
    sha = _kernel_commit_sha()
    sha == EXPECTED_KERNEL_SHA ||
        error("G2b.1 precondition failed: src/takahashi_selinv.jl last commit is $(sha), expected $(EXPECTED_KERNEL_SHA) (6bb10c97)")
    return sha
end

# ---------------------------------------------------------------------------
# Gates
# ---------------------------------------------------------------------------

function gate_agree()
    _assert_kernel_sha!()
    # The three expensive f0adv q=20000/50000 high-fill rungs are stood in
    # for by a small f0adv fixture of the SAME generator/algorithm: arm
    # agreement is a deterministic-math property of the recursion, not
    # scale-dependent (unchanged rationale from the S2 harness's gate_agree).
    gate_fixtures = Dict{String,Function}(
        "f0adv_q1000_standin_for_the_three_expensive_rungs" => () -> f0adv_fixture(1_000),
        "f0scale_q20000" => () -> f0scale_fixture(20_000),
        "boundary_q2000" => () -> boundary_fixture(2000),
    )
    bad = String[]
    for (name, build) in gate_fixtures
        spec = build()
        for mode in (:auto, :simplicial)
            local res
            try
                res = measure_fixture(spec; reps = 1, force_mode = mode)
            catch e
                push!(bad, "$name mode=$mode errored: $(sprint(showerror, e))")
                continue
            end
            res.err_c > 1e-10 && push!(bad, "$name mode=$mode err_c=$(res.err_c)")
        end
    end
    if isempty(bad)
        println("GATE G2b.2 PASS")
        return 0
    else
        println("GATE G2b.2 FAIL ", join(bad, "; "))
        return 1
    end
end

const REQUIRED_RECORD_COLS = ["fixture", "threads", "q", "nfixed", "nnz_C", "nnz_L", "fill",
                               "is_super", "index_eltype", "T_fact",
                               "T_a_trace", "T_a_diag", "T_c_trace", "T_c_diag",
                               "S_c_trace", "S_c_diag", "R_c_trace", "err_c"]

# Verify (never regenerate if present -- a gate that silently re-runs the
# grid on every invocation would waste the compute the first `run_grid()`
# call already spent, e.g. under a `--reverify`-style re-check).
function _verify_grid_tsv(path::AbstractString)
    isfile(path) || return (false, "file does not exist: $(path)")
    lines = filter(l -> !isempty(l) && !startswith(l, "#"), readlines(path))
    isempty(lines) && return (false, "no data rows")
    header = split(lines[1], "\t")
    missing_cols = filter(c -> !(c in header), REQUIRED_RECORD_COLS)
    isempty(missing_cols) || return (false, "missing columns: $(missing_cols)")
    length(lines) < 2 && return (false, "header only, no data rows")
    return (true, "$(length(lines) - 1) rows, all required columns present")
end

function gate_record()
    _assert_kernel_sha!()
    threads = parse(Int, get(ENV, "OPENBLAS_NUM_THREADS", "1"))
    outfile = joinpath(@__DIR__, "results", "selinv_arms_$(_harness_commit_sha())_t$(threads).tsv")
    isfile(outfile) || run_grid()
    ok, detail = _verify_grid_tsv(outfile)
    if ok
        println("GATE G2b.3 PASS ", detail)
        println("  verified ", outfile)
        return 0
    else
        println("GATE G2b.3 FAIL ", detail)
        return 1
    end
end

# ---------------------------------------------------------------------------
# D-271 verdict (G2b.5) -- read every quantity from recorded files, never
# type a number by hand.
# ---------------------------------------------------------------------------

function _read_tsv_rows(path::AbstractString)
    lines = filter(l -> !isempty(l) && !startswith(l, "#"), readlines(path))
    header = split(lines[1], "\t")
    rows = NamedTuple[]
    for line in lines[2:end]
        fields = split(line, "\t")
        nt = (; (Symbol(h) => f for (h, f) in zip(header, fields))...)
        push!(rows, nt)
    end
    return rows
end

function gate_verdict()
    _assert_kernel_sha!()
    mac_path = joinpath(@__DIR__, "results", "selinv_arms_$(_harness_commit_sha())_t1.tsv")
    results_dir = joinpath(@__DIR__, "results")
    totoro_files = filter(f -> occursin("totoro_q20000_fill", f), readdir(results_dir))
    if !isfile(mac_path)
        println("GATE G2b.5 FAIL Mac record TSV not found at $(mac_path); run --gate record first")
        return 1
    end
    if isempty(totoro_files)
        println("GATE G2b.5 FAIL no Totoro result TSV found in bench/results/")
        return 1
    end
    totoro_path = joinpath(results_dir, last(sort(totoro_files)))

    totoro_rows = _read_tsv_rows(totoro_path)
    tr = totoro_rows[1]
    S_c_trace = parse(Float64, tr.S_c_trace)
    err_c_totoro = parse(Float64, tr.err_c)

    mac_rows = _read_tsv_rows(mac_path)
    max_err_c_mac = maximum(parse(Float64, r.err_c) for r in mac_rows)
    overall_err = max(err_c_totoro, max_err_c_mac)

    install_path = joinpath(results_dir, "install_weight_b9f30a64.txt")
    packages_added = nothing
    new_jll = nothing
    if isfile(install_path)
        txt = read(install_path, String)
        m1 = match(r"packages_added=(\d+)", txt)
        m2 = match(r"new_jll=(\d+)", txt)
        packages_added = m1 === nothing ? nothing : parse(Int, m1.captures[1])
        new_jll = m2 === nothing ? nothing : parse(Int, m2.captures[1])
    end

    # G_fit: projected whole-fit gain from S1's selected-inverse share
    # (0.993, per this arc's own ROLE brief citing S1/S9's recorded number).
    # This share is a FIXED, externally-supplied input (this bench file never
    # runs fit_ai_reml end-to-end), so G_fit here is AGENT-INFERRED from
    # Amdahl's law: G_fit = 1 / ((1 - share) + share / S_c_trace).
    share = 0.993
    G_fit = isnan(S_c_trace) ? NaN : 1.0 / ((1.0 - share) + share / S_c_trace)

    println("D-271 verdict inputs (each beside its threshold):")
    @printf("  S_c_trace (Totoro, fill~471/474)        = %.2f    threshold >= 10\n", S_c_trace)
    @printf("  err_c (max over Mac grid + Totoro)       = %.3e threshold <= 1e-10\n", overall_err)
    println("  packages_added                           = ", packages_added === nothing ? "UNKNOWN (run --install-weight)" : packages_added, "       threshold <= 2")
    println("  new_jll                                  = ", new_jll === nothing ? "UNKNOWN (run --install-weight)" : new_jll, "       threshold == 0")
    @printf("  G_fit (AGENT-INFERRED, Amdahl, share=%.3f) = %.2f     threshold >= 2\n", share, G_fit)

    ok_S = !isnan(S_c_trace) && S_c_trace >= 10
    ok_err = overall_err <= 1e-10
    ok_pkg = packages_added !== nothing && packages_added <= 2
    ok_jll = new_jll !== nothing && new_jll == 0
    ok_fit = !isnan(G_fit) && G_fit >= 2

    tier = (ok_S && ok_err && ok_pkg && ok_jll && ok_fit) ?
        "optional extension" : "keep ours (Szymek's kernel) and close #353 with the number"

    println()
    println("D-271 VERDICT: tier = \"$(tier)\"")
    println("  S_c_trace>=10: $(ok_S)  err_c<=1e-10: $(ok_err)  packages_added<=2: $(ok_pkg)  new_jll==0: $(ok_jll)  G_fit>=2: $(ok_fit)")

    if packages_added === nothing || new_jll === nothing
        println("GATE G2b.5 FAIL install weight not measured (run --install-weight first)")
        return 1
    end
    println("GATE G2b.5 PASS")
    return 0
end

# ---------------------------------------------------------------------------
# Full grid
# ---------------------------------------------------------------------------

function run_grid()
    _assert_kernel_sha!()
    threads = parse(Int, get(ENV, "OPENBLAS_NUM_THREADS", "1"))
    rows = NamedTuple[]

    for (name, build) in MAIN_FIXTURES
        reps = name in REDUCED_REPS_FIXTURES ? REDUCED_REPS : REPS
        spec = build()
        @printf("measuring %-24s threads=%d reps=%d %s...\n", name, threads, reps,
                reps < REPS ? "(economy: reps=$(reps), still warmed-up -- see REDUCED_REPS_FIXTURES budget note) " : ""); flush(stdout)
        res = measure_fixture(spec; reps = reps)
        push!(rows, merge((fixture = name, threads = threads, forced_mode = "auto"), res))
    end

    # Forced-simplicial extra arm at the highest-fill Mac fixture -- itself
    # one of the reduced-reps fixtures, so the same economy applies.
    spec_hi = MAIN_FIXTURES[HIGHEST_FILL_FIXTURE]()
    res_simpl = measure_fixture(spec_hi; reps = REDUCED_REPS, force_mode = :simplicial)
    push!(rows, merge((fixture = HIGHEST_FILL_FIXTURE * "_forced_simplicial", threads = threads,
                        forced_mode = "simplicial(economy reps=$(REDUCED_REPS))"), res_simpl))

    # Dense-inv pins, both is_super branches -- cheap regardless of threads.
    for n in (50, 500)
        spec_n = animal_model_spec(ones(n), ones(n, 1), sparse(1.0I, n, n), spd_fixture(n); method = :REML)
        for mode in (:supernodal, :simplicial)
            res_n = measure_fixture(spec_n; reps = REPS, force_mode = mode, sigma_a2 = 1.0, sigma_e2 = 1.0)
            push!(rows, merge((fixture = "dense_pin_n$(n)", threads = threads, forced_mode = string(mode)), res_n))
        end
    end

    outfile = joinpath(@__DIR__, "results", "selinv_arms_$(_harness_commit_sha())_t$(threads).tsv")
    mkpath(dirname(outfile))
    open(outfile, "w") do io
        write_tsv(io, rows)
    end
    println("\nwrote ", outfile)
    return outfile, rows
end

# ---------------------------------------------------------------------------
# Totoro arm (G2b.4): the banked fill-471/474 point. F0 adversarial at
# q=20000 with the DEFAULT nfounder_frac=0.005 (NOT a fill search -- 0.005 is
# the historically banked value). One process, one thread
# (OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1, set by the caller via ENV
# before this process starts). Arms a and c only, split into trace/diag, each
# timed TWICE after one warm-up.
# ---------------------------------------------------------------------------

function totoro_arm()
    _assert_kernel_sha!()
    spec = f0adv_fixture(20_000; nfounder_frac = 0.005)
    Ainv = sparse(Float64.(spec.Ainv))
    nfixed = size(spec.X, 2)
    n = size(spec.X, 2) + size(spec.Z, 2)

    lhs, _, _ = HSquared._sparse_mme_system(spec, 1.0, 1.0)
    lhs_sym = Symmetric(lhs)
    GC.gc()
    F = cholesky(lhs_sym; check = true)
    is_super = _is_super(F)
    nnzC = nnz(lhs)
    nnzL = nnz(sparse(F.L))
    fill = nnzL / n
    idx_eltype = eltype(rowvals(Ainv))
    @printf("f0adv q=20000 nfounder_frac=0.005 (banked point): is_super=%s nnz(L)=%d fill=%.3f\n",
            is_super, nnzL, fill)
    flush(stdout)

    # T_fact: median of 3 numeric refactorizations reusing symbolic analysis.
    cholesky!(F, lhs_sym; check = true)  # warm-up
    fact_times = Float64[]
    for _ in 1:3
        stats = @timed cholesky!(F, lhs_sym; check = true)
        push!(fact_times, stats.time)
    end
    T_fact = _median(fact_times)

    B_perm = build_B_perm(F, Ainv, n, nfixed)

    # Each quantity: one warm-up, then 2 timed repeats.
    pass_a_trace(F, Ainv, nfixed)
    ta1, wat1, bat1 = pass_a_trace(F, Ainv, nfixed)
    ta2, wat2, bat2 = pass_a_trace(F, Ainv, nfixed)
    @printf("a_trace rep1: %.4f s (%d bytes)   rep2: %.4f s (%d bytes)\n", wat1, bat1, wat2, bat2)
    flush(stdout)

    pass_a_diag(F)
    da1, wad1, bad1 = pass_a_diag(F)
    da2, wad2, bad2 = pass_a_diag(F)
    @printf("a_diag  rep1: %.4f s (%d bytes)   rep2: %.4f s (%d bytes)\n", wad1, bad1, wad2, bad2)
    flush(stdout)

    pass_c_trace(F, B_perm)
    tc1, wct1, bct1 = pass_c_trace(F, B_perm)
    tc2, wct2, bct2 = pass_c_trace(F, B_perm)
    @printf("c_trace rep1: %.4f s (%d bytes)   rep2: %.4f s (%d bytes)\n", wct1, bct1, wct2, bct2)
    flush(stdout)

    pass_c_diag(F)
    dc1, wcd1, bcd1 = pass_c_diag(F)
    dc2, wcd2, bcd2 = pass_c_diag(F)
    @printf("c_diag  rep1: %.4f s (%d bytes)   rep2: %.4f s (%d bytes)\n", wcd1, bcd1, wcd2, bcd2)
    flush(stdout)

    T_a_trace = _median([wat1, wat2]); T_a_diag = _median([wad1, wad2])
    T_c_trace = _median([wct1, wct2]); T_c_diag = _median([wcd1, wcd2])
    err_trace_c = abs(tc2 - ta2) / max(abs(ta2), eps())
    err_diag_c = maximum(abs.(dc2 .- da2)) / max(maximum(abs.(da2)), eps())
    err_c = max(err_trace_c, err_diag_c)
    S_c_trace = T_a_trace / T_c_trace
    S_c_diag = T_a_diag / T_c_diag
    R_c_trace = T_c_trace / T_fact

    outdir = joinpath(@__DIR__, "results")
    mkpath(outdir)
    outfile = joinpath(outdir, "selinv_arms_$(_harness_commit_sha())_totoro_q20000_fill474.tsv")
    open(outfile, "w") do io
        println(io, join(_header_lines(), "\n"))
        println(io, "# Totoro arm (G2b.4): host=$(gethostname())")
        cols = ["fixture", "threads", "q", "nfixed", "nnz_C", "nnz_L", "fill", "is_super",
                "index_eltype", "T_fact",
                "T_a_trace_rep1", "T_a_trace_rep2", "T_a_diag_rep1", "T_a_diag_rep2",
                "T_c_trace_rep1", "T_c_trace_rep2", "T_c_diag_rep1", "T_c_diag_rep2",
                "S_c_trace", "S_c_diag", "R_c_trace", "err_c"]
        println(io, join(cols, "\t"))
        @printf(io, "%s\t%d\t%d\t%d\t%d\t%d\t%.3f\t%s\t%s\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.2f\t%.2f\t%.4f\t%.3e\n",
                "f0adv_q20000_fill474_totoro", 1, n, nfixed, nnzC, nnzL, fill, is_super, idx_eltype,
                T_fact, wat1, wat2, wad1, wad2, wct1, wct2, wcd1, wcd2,
                S_c_trace, S_c_diag, R_c_trace, err_c)
    end
    @printf("\nTOTORO ARM DONE: T_fact=%.4fs T_a_trace=%.4fs T_a_diag=%.4fs T_c_trace=%.4fs T_c_diag=%.4fs S_c_trace=%.2f S_c_diag=%.2f R_c_trace=%.4f err_c=%.3e\n",
            T_fact, T_a_trace, T_a_diag, T_c_trace, T_c_diag, S_c_trace, S_c_diag, R_c_trace, err_c)
    println("wrote ", outfile)
    return outfile
end

# ---------------------------------------------------------------------------
# Install weight (G2b.3): measured on a COPY of the PACKAGE env (root
# Project.toml + Manifest.toml of THIS worktree), never the bench env (whose
# Manifest resolves Optim's ~55 transitive deps and would overstate the
# weight -- the exact Manifest-vs-Project error the S9 verifier caught for
# S2). Adds `SelectedInversion` at the version this bench pins and reports
# packages added by name, new `_jll`s, and precompile seconds.
# ---------------------------------------------------------------------------

function measure_install_weight(; selinv_version::AbstractString = "0.2.1")
    root = normpath(joinpath(@__DIR__, ".."))
    tmp = mktempdir()
    cp(joinpath(root, "Project.toml"), joinpath(tmp, "Project.toml"))
    manifest_src = joinpath(root, "Manifest.toml")
    isfile(manifest_src) && cp(manifest_src, joinpath(tmp, "Manifest.toml"))
    # The root Project.toml declares HSquared itself (name/uuid/version), so
    # Pkg treats this activated environment as THAT package -- it requires
    # src/HSquared.jl to exist (and precompiles it) even though this
    # measurement only cares about SelectedInversion's added weight. Copy the
    # real src/ tree (read-only copy; nothing here writes to it).
    cp(joinpath(root, "src"), joinpath(tmp, "src"))

    script = """
    import Pkg
    Pkg.activate($(repr(tmp)))
    Pkg.instantiate()
    before = Set(keys(Pkg.dependencies()))
    Pkg.add(Pkg.PackageSpec(name = "SelectedInversion", version = $(repr(selinv_version))))
    t = @elapsed Pkg.precompile()
    after = Pkg.dependencies()
    added = [v.name for (u, v) in after if !(u in before)]
    jlls = filter(n -> endswith(n, "_jll"), added)
    println("PRECOMPILE_SECONDS=", t)
    println("PACKAGES_ADDED_NAMES=", join(sort(added), ","))
    println("PACKAGES_ADDED=", length(added))
    println("NEW_JLL_NAMES=", join(sort(jlls), ","))
    println("NEW_JLL=", length(jlls))
    """
    julia_exe = joinpath(Sys.BINDIR, Base.julia_exename())
    out = read(`$(julia_exe) -e $(script)`, String)
    println(out)

    m_sec = match(r"PRECOMPILE_SECONDS=([0-9.eE+-]+)", out)
    m_pkg = match(r"PACKAGES_ADDED=(\d+)", out)
    m_pkgnames = match(r"PACKAGES_ADDED_NAMES=(.*)", out)
    m_jll = match(r"NEW_JLL=(\d+)", out)
    m_jllnames = match(r"NEW_JLL_NAMES=(.*)", out)

    outpath = joinpath(@__DIR__, "results", "install_weight_b9f30a64.txt")
    mkpath(dirname(outpath))
    open(outpath, "w") do io
        println(io, "packages_added=$(m_pkg.captures[1]) ($(m_pkgnames.captures[1]))")
        println(io, "new_jll=$(m_jll.captures[1]) ($(m_jllnames.captures[1]))")
        println(io, "precompile_seconds=$(m_sec.captures[1])")
        println(io, "measured_on_copy_of=$(root)/Project.toml+Manifest.toml  selinv_version=$(selinv_version)")
    end
    println("wrote ", outpath)
    return outpath
end

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

function main(args)
    gate = length(args) >= 2 && args[1] == "--gate" ? args[2] : nothing
    if gate == "agree"
        return gate_agree()
    elseif gate == "record"
        return gate_record()
    elseif gate == "verdict"
        return gate_verdict()
    elseif gate !== nothing
        error("unknown --gate $(gate)")
    end

    if length(args) >= 1 && args[1] == "--totoro-arm"
        totoro_arm()
        return 0
    end

    if length(args) >= 1 && args[1] == "--install-weight"
        measure_install_weight()
        return 0
    end

    if length(args) >= 1 && args[1] == "--write-git-shas"
        _write_git_shas_cache()
        return 0
    end

    if length(args) >= 1 && args[1] == "--probe-a-q20000-fill150"
        spec = MAIN_FIXTURES["f0adv_q20000_fill150"]()
        Ainv = sparse(Float64.(spec.Ainv))
        nfixed = size(spec.X, 2)
        lhs, _, _ = HSquared._sparse_mme_system(spec, 1.0, 1.0)
        GC.gc()
        F = cholesky(Symmetric(lhs); check = true)
        n = size(lhs, 1)
        @printf("q=20000 fill150(name); achieved fill=%.1f: is_super=%s nnz(L)=%d\n", nnz(sparse(F.L)) / n, _is_super(F), nnz(sparse(F.L)))
        HSquared.selinv_trace_against(F, Ainv, nfixed)  # warm-up
        HSquared.takahashi_diag(F)
        t = @elapsed begin
            HSquared.selinv_trace_against(F, Ainv, nfixed)
            HSquared.takahashi_diag(F)
        end
        @printf("ONE arm-a pass (trace+diag) at q=20000 fill150(name): %.4f s\n", t)

        B_perm = build_B_perm(F, Ainv, n, nfixed)
        SelectedInversion.selinv(F; depermute = false)  # warm-up
        SelectedInversion.selinv_diag(F)
        tc = @elapsed begin
            Zp = SelectedInversion.selinv(F; depermute = false)
            LinearAlgebra.dot(Zp.Z, B_perm)
            SelectedInversion.selinv_diag(F)
        end
        @printf("ONE arm-c pass (trace+diag) at q=20000 fill150(name): %.4f s\n", tc)
        return 0
    end

    run_grid()
    return 0
end

exit(main(ARGS))
