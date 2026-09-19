#!/usr/bin/env julia
# ============================================================================
# NOT CI / OPT-IN measurement only.
#
# Per-section profiler for one AI-REML iteration of `fit_ai_reml` (the sparse
# animal-model AI-REML fitter in src/likelihood.jl). This file lives outside
# `test/` and is never run by CI. It changes nothing under src/.
#
# WHAT IT MEASURES, per fixture/pedigree-size rung:
#   (i)  Profile.@profile (stdlib only, no PProf) of the real, unmodified
#        `fit_ai_reml(spec)`, with samples attributed to a section by walking
#        each sampled backtrace from its innermost frame outward and taking
#        the first frame whose function name is one of ours -- reported as a
#        SHARE of total samples per section.
#   (ii) A section-by-section instrumented copy of the loop body at
#        src/likelihood.jl:457-533 (`_fit_ai_reml_diagnostics`), calling the
#        SAME internal HSquared functions in the SAME order, timed with
#        `@timed` (wall + allocated bytes) per section. G1.1 checks this copy
#        is bitwise-equal to a plain `fit_ai_reml` call on the same spec in
#        the same process.
#
# FIXTURES:
#   halfsib -- the w4 half-sib ladder. `_halfsib_pedigree`, `_sizes_for`, and
#     `_make_y_animal_indexed` (reps = 2) below are copied VERBATIM from the
#     READ-ONLY vault file
#       "/Users/z3437171/Dropbox/Github Local/Shinichi/projects/H2-twin/repros/w4-speed-gen-fit.jl"
#     including how that file's main() builds Ainv/X/Z and calls the fit.
#     That vault file is never edited.
#   f0adv -- the F0 adversarial (high-fill, random-mating) pedigree. The
#     `_f0_adversarial_pedigree` / `_f0_simulate_breeding_values` functions
#     below reproduce the `adversarial` / `simulate_y` generator in
#     sim/drac/f0_adversarial_fill.jl (read, not edited or `include`d -- that
#     file unconditionally calls its own `main()` at file scope, so
#     `include`ing it would run its own multi-size benchmark as a side
#     effect). Renamed locally to avoid any symbol collision.
#
# TARGET-FILL, AND A MEASURED FINDING ABOUT IT:
#   `--target-fill F` searches `nfounder_frac` (holding q fixed) for the
#   value whose MME Cholesky fill (`nnz(L)/n`, identical metric to the
#   package's `:auto` router) is closest to F, using only the cheap numeric
#   factorization (no selected inverse) to read fill at each candidate.
#   MEASURED (this file's own probe, q=5000, seed 20260724): fill is NOT
#   monotonic in nfounder_frac -- it is ~20 at frac=0.5, rises to ~103-150 as
#   frac falls through 0.2..0.01, then PLATEAUS at ~150 for frac <~ 0.0008
#   (where `nf = max(4, round(frac*q))` floors at the hard-coded minimum of
#   4 founders and stops changing). So at q=5000 this generator cannot reach
#   fill 471 by varying nfounder_frac alone -- 471 is the historically banked
#   number at q=20,000 at the DEFAULT nfounder_frac=0.005 (fill grows with q,
#   not by shrinking nfounder_frac past its floor; see
#   docs/dev-log/recovery-checkpoints/2026-08-04-f6-matfree-tail-recovery-predeclaration.md,
#   "50->77->149->262->471" as q increases, and
#   docs/design/validation-debt-register.md's "q=20,000 / fill 471"). The
#   search below reports the CLOSEST achievable fill honestly rather than
#   silently substituting a different q; a `--target-fill 471 --q 5000` run
#   measures the ratio at whatever fill it actually reaches and reports a
#   PASS/FAIL on that measured ratio -- exactly the G1.4 contract ("a FAIL
#   here is a finding to report, not a defect to fix").
#
# CLI:
#   --gate {bitwise|pins|tsv|prerun}   run exactly one gate check; prints
#                                      "GATE G1.x PASS" or "GATE G1.x FAIL
#                                      <reason>"; exit 0 on PASS, 1 on FAIL.
#   --fixture {halfsib|f0adv}
#   --q <comma-separated ints>
#   --target-fill <number>            f0adv only
#   (no --gate, no --fixture/--q)     runs the full ladder (halfsib
#                                      q=1000,5000,20000,50000; f0adv q=5000
#                                      at fill ~75, ~150, 471) and writes
#                                      sim/results/ai_reml_sections_<shortsha>.tsv
#   (no --gate, --fixture/--q given)  ad-hoc single-rung run (for smoke
#                                      testing), writes the same TSV path.
#
# Usage:
#   env JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 \
#       julia --project=. sim/profile_ai_reml_sections.jl [--gate ...] [...]
# ============================================================================

using HSquared
using LinearAlgebra
using SparseArrays
using Printf
using Random
using Dates
using Profile

# ---------------------------------------------------------------------------
# Fixture 1: w4 half-sib ladder -- verbatim copy (see header) from the
# READ-ONLY vault file projects/H2-twin/repros/w4-speed-gen-fit.jl.
# ---------------------------------------------------------------------------

function _halfsib_pedigree(nsire, ndam, noffspring)
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

function _sizes_for(q)
    nsire = max(2, round(Int, q * 0.05))
    ndam  = max(4, round(Int, q * 0.10))
    noff  = q - nsire - ndam
    return nsire, ndam, noff
end

_animal_effect(i) = 0.30 * sin(i * 0.37)
_residual_noise(i, rep) = 0.05 * cos(i * 1.30 + rep * 2.10)

function _make_y_animal_indexed(qtot, reps)
    y = Vector{Float64}(undef, qtot * reps)
    for rep in 1:reps, i in 1:qtot
        y[(rep - 1) * qtot + i] = 5.0 + _animal_effect(i) + _residual_noise(i, rep)
    end
    return y
end

# Reproduces w4-speed-gen-fit.jl's main(): Ainv from the half-sib pedigree,
# X = intercept only, Z = vcat(I_q, I_q) (animal-indexed, 2 reps, no dense A).
function halfsib_fixture(q::Int; reps::Int = 2)
    nsire, ndam, noffspring = _sizes_for(q)
    ped  = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped)
    qtot = length(ped.ids)
    y = _make_y_animal_indexed(qtot, reps)
    X = ones(qtot * reps, 1)
    I_q = sparse(1.0 * I, qtot, qtot)
    Z = vcat(I_q, I_q)
    return animal_model_spec(y, X, Z, Ainv; method = :REML)
end

# ---------------------------------------------------------------------------
# Fixture 2: F0 adversarial high-fill pedigree -- reproduces (renamed, not
# `include`d -- see header) the generator in sim/drac/f0_adversarial_fill.jl.
# ---------------------------------------------------------------------------

function _f0_adversarial_pedigree(q::Int; nfounder_frac::Float64 = 0.005, seed::Int = 20260724)
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
    ped  = _f0_adversarial_pedigree(q; nfounder_frac = nfounder_frac, seed = seed)
    Ainv = pedigree_inverse(ped)
    y = _f0_simulate_breeding_values(ped; seed = seed)
    X = ones(q, 1)
    Z = sparse(1.0 * I, q, q)
    return animal_model_spec(y, X, Z, Ainv; method = :REML)
end

# Fill = nnz(L)/n of the (variance-independent) MME Cholesky -- identical to
# the metric the package's `:auto` router uses. Only the numeric
# factorization is needed to read it (no selected inverse), so this is cheap
# even at high fill.
function _mme_fill(spec::AnimalModelSpec)
    lhs, _, _ = HSquared._sparse_mme_system(spec, 1.0, 1.0)
    chf = cholesky(Symmetric(lhs); check = true)
    return nnz(sparse(chf.L)) / size(lhs, 1)
end

# Coarse-to-... actually a single log-spaced sweep: fill is NOT monotonic in
# nfounder_frac (measured; see header), so a bisection would be unsound. This
# evaluates a fixed candidate grid and returns whichever candidate's fill is
# closest to `target_fill`, honestly, even when that is far from the target
# (e.g. target 471 at q=5000 -- see header note).
function find_nfounder_frac_for_fill(q::Int, target_fill::Real; seed::Int = 20260724)
    floor_frac = 4.0 / q
    candidates = sort(unique(vcat(
        floor_frac,
        [floor_frac * m for m in (2, 4, 8, 16, 32, 64)],
        [0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.3, 0.5, 0.7],
    )))
    filter!(f -> 0 < f <= 1, candidates)
    best_frac, best_fill, best_err = candidates[1], NaN, Inf
    for frac in candidates
        spec = f0adv_fixture(q; nfounder_frac = frac, seed = seed)
        fill = _mme_fill(spec)
        err = abs(fill - target_fill)
        if err < best_err
            best_frac, best_fill, best_err = frac, fill, err
        end
    end
    return best_frac, best_fill
end

# ---------------------------------------------------------------------------
# Environment / header info
# ---------------------------------------------------------------------------

# The commit that last touched THIS file, not whatever HEAD happens to be at
# run time. Using `git rev-parse --short HEAD` here would rename (and orphan)
# the banked ladder TSV every time an unrelated commit lands (e.g. a
# checkpoint.md update) even though the harness itself did not change.
function _harness_commit_sha()
    try
        sha = strip(read(`git log -1 --format=%h -- $(@__FILE__)`, String))
        return isempty(sha) ? "uncommitted" : sha
    catch
        return "unknown"
    end
end

function ladder_tsv_path()
    outdir = joinpath(@__DIR__, "results")
    mkpath(outdir)
    return joinpath(outdir, "ai_reml_sections_$(_harness_commit_sha()).tsv")
end

# Ad-hoc single-rung smoke runs (no --gate, --fixture/--q given) write here,
# NOT to `ladder_tsv_path()` -- that path is the banked full-ladder deliverable
# and must never be clobbered by a one-rung smoke invocation.
function smoke_tsv_path()
    outdir = joinpath(@__DIR__, "results")
    mkpath(outdir)
    return joinpath(outdir, "ai_reml_sections_$(_harness_commit_sha())_smoke.tsv")
end

function _cpu_model()
    try
        info = Sys.cpu_info()
        return isempty(info) ? "unknown" : info[1].model
    catch
        return "unknown"
    end
end

function _header_lines()
    return [
        "# HSquared.jl AI-REML per-section profiler  $(Dates.now())",
        "# git_sha=$(_harness_commit_sha())  julia=$(VERSION)  os=$(Sys.KERNEL) $(Sys.MACHINE)",
        "# blas=$(BLAS.get_config())",
        "# JULIA_NUM_THREADS=$(Threads.nthreads())  OPENBLAS_NUM_THREADS=$(get(ENV, "OPENBLAS_NUM_THREADS", "unset"))",
        "# cpu=$(_cpu_model())",
        "# NOT CI / OPT-IN measurement only. No performance claim, no regression gate.",
    ]
end

# ---------------------------------------------------------------------------
# (ii) Instrumented per-section copy of the loop body at
# src/likelihood.jl:457-533 (`_fit_ai_reml_diagnostics`). Calls the SAME
# internal HSquared functions in the SAME order. `em_warmup` is not
# reproduced here (default 0 in fit_ai_reml; this harness never passes it).
# ---------------------------------------------------------------------------

function instrumented_ai_reml(spec::AnimalModelSpec;
                               initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
                               iterations::Integer = 100,
                               tol::Real = 1e-8)
    sigma_a2, sigma_e2 = HSquared._coerce_initial_variances(initial)
    X = Float64.(spec.X)
    Z = sparse(Float64.(spec.Z))
    Ainv = sparse(Float64.(spec.Ainv))
    y = Float64.(spec.y)
    nfixed = size(X, 2)
    nrandom = size(Z, 2)
    nobs = length(y)

    rows = NamedTuple[]   # (iteration, section, wall_s, bytes)
    fill = NaN
    converged = false
    iters = 0
    for it in 1:iterations
        iters = it
        iter_t0 = time_ns()

        stats = @timed begin
            lhs, rhs, _ = HSquared._sparse_mme_system(spec, sigma_a2, sigma_e2)
        end
        push!(rows, (iteration = it, section = "mme_assembly", wall_s = stats.time, bytes = stats.bytes))

        stats = @timed cholesky(Symmetric(lhs); check = true)
        factor = stats.value
        push!(rows, (iteration = it, section = "cholmod_factor", wall_s = stats.time, bytes = stats.bytes))
        it == 1 && (fill = nnz(sparse(factor.L)) / size(lhs, 1))

        # mme_solve: the sparse solve plus the (O(n), negligible-cost)
        # BLUP/residual extraction that immediately follows it in the source
        # loop -- folded in here so no untimed algebra sits between sections
        # (kept the G1.3 5% section-sum-vs-total check honest at microsecond
        # scale; verified not to change control flow or final results).
        stats = @timed begin
            solution = factor \ rhs
            beta = solution[1:nfixed]
            u = solution[(nfixed + 1):end]
            e = y .- X * beta .- Z * u
        end
        push!(rows, (iteration = it, section = "mme_solve", wall_s = stats.time, bytes = stats.bytes))

        # selinv: the Takahashi trace plus the (O(nnz), negligible-cost) REML
        # score built from it, for the same reason as above.
        stats = @timed begin
            trace_AC = HSquared.selinv_trace_against(factor, Ainv, nfixed)
            uAu = dot(u, Ainv * u)
            score_a = -0.5 / sigma_a2^2 * (nrandom * sigma_a2 - trace_AC - uAu)
            score_e = -0.5 / sigma_e2^2 *
                      (sigma_e2 * (nobs - nfixed - nrandom + trace_AC / sigma_a2) - dot(e, e))
            hypot(score_a, score_e)
        end
        ai_score_norm = stats.value
        push!(rows, (iteration = it, section = "selinv", wall_s = stats.time, bytes = stats.bytes))

        if ai_score_norm < tol
            converged = true
            push!(rows, (iteration = it, section = "iteration_total",
                         wall_s = (time_ns() - iter_t0) / 1e9, bytes = 0))
            break
        end

        # ai_step: the two working-variate re-solves, the AI/Newton step, and
        # its step-halving loop (same reasoning: step-halving is O(1) --
        # halving a length-2 vector -- so moving it inside the timed block
        # cannot materially change either its own cost or, since a NaN/Inf
        # step still fails the `isfinite` check below exactly as before, the
        # fit's final results).
        stats = @timed begin
            wa = (Z * u) ./ sigma_a2
            we = e ./ sigma_e2
            Pwa = HSquared._reml_project(factor, X, Z, wa, sigma_e2, nfixed)
            Pwe = HSquared._reml_project(factor, X, Z, we, sigma_e2, nfixed)
            information = 0.5 .* [dot(wa, Pwa) dot(wa, Pwe); dot(we, Pwa) dot(we, Pwe)]
            step0 = HSquared._ai_newton_step(information, [score_a, score_e])
            a_new0 = sigma_a2 + step0[1]
            e_new0 = sigma_e2 + step0[2]
            halvings0 = 0
            while (a_new0 <= 0 || e_new0 <= 0) && halvings0 < 60
                step0 = step0 ./ 2
                a_new0 = sigma_a2 + step0[1]
                e_new0 = sigma_e2 + step0[2]
                halvings0 += 1
            end
            (step0, a_new0, e_new0)
        end
        step, a_new, e_new = stats.value
        push!(rows, (iteration = it, section = "ai_step", wall_s = stats.time, bytes = stats.bytes))

        iter_wall = (time_ns() - iter_t0) / 1e9
        push!(rows, (iteration = it, section = "iteration_total", wall_s = iter_wall, bytes = 0))

        if !all(isfinite, step)
            break
        end
        if !(a_new > 0 && e_new > 0)
            break
        end
        rel_change = max(abs(a_new - sigma_a2) / sigma_a2, abs(e_new - sigma_e2) / sigma_e2)
        sigma_a2, sigma_e2 = a_new, e_new
        if rel_change < tol
            converged = true
            break
        end
    end
    return (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2, iterations = iters,
            converged = converged, fill = fill, rows = rows)
end

# ---------------------------------------------------------------------------
# (i) Profile.@profile share attribution: for each sampled backtrace, walk
# from the innermost frame outward and assign the sample to the first frame
# whose function name is one of ours; unmatched samples go to "other". This
# is a leaf-nearest-known-caller attribution -- it avoids double counting a
# parent+child pair, at the cost of occasionally attributing a tiny nested
# call (e.g. the 2x2 solve inside `_ai_newton_step`) to whichever named
# function is nearest on the stack rather than perfectly to that innermost
# call; negligible given the relative costs at these fixture sizes.
# ---------------------------------------------------------------------------

const _PROFILE_FUNC_CATEGORY = Dict{Symbol,String}(
    :selinv_trace_against => "selinv",
    :_sparse_mme_system   => "mme_assembly",
    :_reml_project        => "ai_step",
    :_ai_newton_step      => "ai_step",
    :cholesky             => "cholmod_factor",
    :cholesky!            => "cholmod_factor",
    Symbol("\\")          => "mme_solve",
    :ldiv!                => "mme_solve",
)

function profile_section_shares(spec::AnimalModelSpec; target_profiled_s::Real = 0.5, max_reps::Int = 200)
    fit_ai_reml(spec)   # JIT warm-up, discarded
    t_single = @elapsed fit_ai_reml(spec)
    reps = t_single > 0 ? clamp(ceil(Int, target_profiled_s / t_single), 1, max_reps) : 1

    Profile.clear()
    Profile.@profile for _ in 1:reps
        fit_ai_reml(spec)
    end
    data = Profile.fetch()

    counts = Dict{String,Int}()
    n_samples = 0
    i = 1
    while i <= length(data)
        if data[i] == 0
            i += 1
            continue
        end
        j = i
        while j <= length(data) && data[j] != 0
            j += 1
        end
        bt = @view data[i:(j - 1)]
        n_samples += 1
        cat = "other"
        for ip in bt
            frames = StackTraces.lookup(ip)
            matched = false
            for fr in frames
                name = get(_PROFILE_FUNC_CATEGORY, fr.func, nothing)
                if name !== nothing
                    cat = name
                    matched = true
                    break
                end
            end
            matched && break
        end
        counts[cat] = get(counts, cat, 0) + 1
        i = j
    end
    shares = Dict(k => v / max(n_samples, 1) for (k, v) in counts)
    return shares, n_samples, reps
end

# ---------------------------------------------------------------------------
# TSV writer: one row per (fixture, q, fill, iteration, section, method).
# `method` distinguishes the two measurements in the header (see top of
# file): "instrumented" rows carry real per-section wall_s/bytes and an
# "iteration_total" pseudo-section used by gate G1.3's 5% self-consistency
# check; "profile" rows carry the Profile.@profile share re-expressed as
# wall_s = share * (reps-averaged single-fit wall), with bytes = NaN (the
# stdlib profiler does not report per-sample allocation).
# ---------------------------------------------------------------------------

function write_tsv(io::IO, all_rows)
    println(io, join(_header_lines(), "\n"))
    println(io, join(
        ["fixture", "q", "fill", "iteration", "section", "method", "wall_s", "bytes", "factorizations"],
        "\t"))
    for r in all_rows
        @printf(io, "%s\t%d\t%.3f\t%d\t%s\t%s\t%.6f\t%s\t%d\n",
                r.fixture, r.q, r.fill, r.iteration, r.section, r.method,
                r.wall_s, isnan(r.bytes) ? "NaN" : @sprintf("%d", r.bytes), r.factorizations)
    end
end

function _rows_for_fixture(fixture::String, q::Int, spec::AnimalModelSpec)
    diag = HSquared._fit_ai_reml_diagnostics(spec)
    factorizations = diag.diagnostics.factorizations

    inst = instrumented_ai_reml(spec)
    rows = NamedTuple[]
    for r in inst.rows
        push!(rows, (fixture = fixture, q = q, fill = inst.fill, iteration = r.iteration,
                     section = r.section, method = "instrumented",
                     wall_s = r.wall_s, bytes = Float64(r.bytes), factorizations = factorizations))
    end

    fit_ai_reml(spec)   # warm-up before the timed single-fit wall used to scale profile shares
    t_fit = @elapsed fit_ai_reml(spec)
    shares, n_samples, reps = profile_section_shares(spec)
    for (section, share) in shares
        push!(rows, (fixture = fixture, q = q, fill = inst.fill, iteration = 0,
                     section = section, method = "profile",
                     wall_s = share * t_fit, bytes = NaN, factorizations = factorizations))
    end
    return rows, inst, shares, n_samples
end

function _top3_share_line(fixture, q, fill, shares)
    ranked = sort(collect(shares); by = last, rev = true)
    top = ranked[1:min(3, length(ranked))]
    parts = [@sprintf("%s=%.1f%%", k, 100v) for (k, v) in top]
    label = fixture == "f0adv" ? @sprintf("%s q=%d fill~%.0f", fixture, q, fill) :
                                  @sprintf("%s q=%d", fixture, q)
    return label * ": " * join(parts, " ")
end

# ---------------------------------------------------------------------------
# Gates
# ---------------------------------------------------------------------------

function gate_bitwise(q::Int)
    spec = halfsib_fixture(q)
    fit_ai_reml(spec)          # warm-up
    fit = fit_ai_reml(spec)
    inst = instrumented_ai_reml(spec)
    diag = HSquared._fit_ai_reml_diagnostics(spec)

    checks = [
        ("sigma_a2", inst.sigma_a2 === fit.variance_components.sigma_a2),
        ("sigma_e2", inst.sigma_e2 === fit.variance_components.sigma_e2),
        ("iterations", inst.iterations == fit.iterations),
        ("converged", inst.converged == fit.converged),
        ("factorizations", inst.iterations == diag.diagnostics.factorizations),
    ]
    loglik_inst = sparse_reml_loglik(spec, inst.sigma_a2, inst.sigma_e2).loglik
    push!(checks, ("loglik", loglik_inst === fit.likelihood.loglik))

    failed = [name for (name, ok) in checks if !ok]
    if isempty(failed)
        println("GATE G1.1 PASS")
        return 0
    else
        println("GATE G1.1 FAIL mismatch in: ", join(failed, ", "))
        return 1
    end
end

function gate_pins(qs::Vector{Int})
    banked = Dict(1000 => 0.149778, 5000 => 0.098201, 20000 => 0.132360, 50000 => 0.103807)
    mismatches = String[]
    for q in qs
        spec = halfsib_fixture(q)
        fit = fit_ai_reml(spec)
        got = round(fit.variance_components.sigma_a2; digits = 6)
        want = get(banked, q, nothing)
        if want === nothing
            push!(mismatches, "q=$q has no banked pin")
        elseif got != want
            push!(mismatches, @sprintf("q=%d got %.6f want %.6f", q, got, want))
        end
    end
    if isempty(mismatches)
        println("GATE G1.2 PASS")
        return 0
    else
        println("GATE G1.2 FAIL ", join(mismatches, "; "))
        return 1
    end
end

# ---------------------------------------------------------------------------
# TSV reader/verifier for gate G1.3. Read-only against the banked ladder file
# -- gate_tsv() below must never regenerate/overwrite an existing TSV, only
# verify it (and create it via run_ladder() the one time none exists yet).
# ---------------------------------------------------------------------------

function _read_tsv_rows(path::AbstractString)
    lines = readlines(path)
    data_lines = filter(l -> !isempty(l) && !startswith(l, "#"), lines)
    isempty(data_lines) && return NamedTuple[]
    header = split(data_lines[1], "\t")
    rows = NamedTuple[]
    for line in data_lines[2:end]
        fields = split(line, "\t")
        length(fields) == length(header) || continue
        d = Dict(zip(header, fields))
        push!(rows, (
            fixture = d["fixture"],
            q = parse(Int, d["q"]),
            fill = parse(Float64, d["fill"]),
            iteration = parse(Int, d["iteration"]),
            section = d["section"],
            method = d["method"],
            wall_s = parse(Float64, d["wall_s"]),
            bytes = d["bytes"] == "NaN" ? NaN : parse(Float64, d["bytes"]),
            factorizations = parse(Int, d["factorizations"]),
        ))
    end
    return rows
end

# The full ladder's six rungs: halfsib q=1000/5000/20000/50000 (fill ~4 for
# this pedigree shape) and f0adv q=5000 at the two DISTINCT achieved fills
# (~74 and ~150 -- the target-471 rung collapses onto the ~150 rung; see the
# file header's target-fill note, and G1.4's measured finding).
const _REQUIRED_LADDER_RUNGS = Set([
    ("halfsib", 1000, 4), ("halfsib", 5000, 4), ("halfsib", 20000, 4), ("halfsib", 50000, 4),
    ("f0adv", 5000, 74), ("f0adv", 5000, 150),
])

function _verify_ladder_tsv(path::AbstractString)
    isfile(path) || return (false, "file does not exist: $(path)")
    rows = _read_tsv_rows(path)
    isempty(rows) && return (false, "no data rows")

    if any(r -> !isfinite(r.wall_s) || r.wall_s < 0, rows)
        return (false, "NaN/Inf or negative wall_s present")
    end
    if any(r -> r.method == "instrumented" && !isfinite(r.bytes), rows)
        return (false, "NaN/Inf bytes on an instrumented row")
    end

    # One row per (fixture, q, fill, iteration, section) -- literal G1.3
    # requirement. Two different f0adv --target-fill values can resolve to
    # the identical achieved fill (measured; run_ladder() dedupes for this),
    # so a duplicate key here is a real defect, not an artifact of rounding.
    seen = Set{Tuple{String,Int,Float64,Int,String,String}}()
    for r in rows
        key = (r.fixture, r.q, r.fill, r.iteration, r.section, r.method)
        key in seen && return (false, "duplicate row for (fixture,q,fill,iteration,section,method)=$(key)")
        push!(seen, key)
    end

    rung_key(r) = (r.fixture, r.q, round(Int, r.fill))
    rungs = Set(rung_key(r) for r in rows if r.method == "instrumented")
    missing_rungs = setdiff(_REQUIRED_LADDER_RUNGS, rungs)
    isempty(missing_rungs) || return (false, "missing rungs: $(collect(missing_rungs))")

    # 5% self-consistency per (rung, iteration): sum of instrumented section
    # walls vs. that iteration's own "iteration_total" wall.
    by_group = Dict{Tuple{String,Int,Int,Int},Vector{NamedTuple}}()
    for r in rows
        r.method == "instrumented" || continue
        key = (r.fixture, r.q, round(Int, r.fill), r.iteration)
        push!(get!(by_group, key, NamedTuple[]), r)
    end
    bad = String[]
    for (key, rs) in by_group
        total_row = filter(r -> r.section == "iteration_total", rs)
        isempty(total_row) && continue
        total = total_row[1].wall_s
        total <= 0 && continue
        section_sum = sum(r.wall_s for r in rs if r.section != "iteration_total")
        rel = abs(section_sum - total) / total
        rel > 0.05 && push!(bad, @sprintf("%s q=%d fill~%d iter=%d rel=%.3f", key[1], key[2], key[3], key[4], rel))
    end
    isempty(bad) || return (false, "section-sum vs iteration-total mismatch: " * join(bad, "; "))

    return (true, "$(length(rungs)) rungs, $(length(rows)) rows")
end

function gate_tsv()
    path = ladder_tsv_path()
    isfile(path) || run_ladder()   # create the ladder TSV only if none exists yet

    ok, detail = _verify_ladder_tsv(path)
    if ok
        println("GATE G1.3 PASS ", detail)
        println("  verified ", path)
        return 0
    else
        println("GATE G1.3 FAIL ", detail)
        return 1
    end
end

function gate_prerun(q::Int, target_fill::Real)
    frac, achieved_fill = find_nfounder_frac_for_fill(q, target_fill)
    spec = f0adv_fixture(q; nfounder_frac = frac)

    lhs, _, _ = HSquared._sparse_mme_system(spec, 1.0, 1.0)
    t_factor = @elapsed (factor = cholesky(Symmetric(lhs); check = true))
    nfixed = size(spec.X, 2)
    Ainv = sparse(Float64.(spec.Ainv))
    t_selinv = @elapsed HSquared.selinv_trace_against(factor, Ainv, nfixed)

    ratio = t_selinv / max(t_factor, eps())
    gap_note = abs(achieved_fill - target_fill) > 0.15 * target_fill ?
        @sprintf(" [target fill %.0f NOT reachable at q=%d by varying nfounder_frac; closest achieved fill=%.1f at nfounder_frac=%.6g -- see file header]",
                 target_fill, q, achieved_fill, frac) : ""
    detail = @sprintf("t_factor=%.4fs t_selinv=%.4fs ratio=%.1f achieved_fill=%.1f%s",
                       t_factor, t_selinv, ratio, achieved_fill, gap_note)

    if ratio >= 100
        println("GATE G1.4 PASS ", detail)
        return 0
    else
        println("GATE G1.4 FAIL ratio $(round(ratio, digits=1)) < 100; ", detail)
        return 1
    end
end

# ---------------------------------------------------------------------------
# Full ladder / ad-hoc run
# ---------------------------------------------------------------------------

function run_ladder(; halfsib_qs::Vector{Int} = [1000, 5000, 20000, 50000],
                     f0adv_q::Int = 5000, f0adv_targets::Vector{Float64} = [75.0, 150.0, 471.0])
    all_rows = NamedTuple[]
    share_lines = String[]

    for q in halfsib_qs
        spec = halfsib_fixture(q)
        rows, inst, shares, n_samples = _rows_for_fixture("halfsib", q, spec)
        append!(all_rows, rows)
        push!(share_lines, _top3_share_line("halfsib", q, inst.fill, shares))
        @printf("halfsib q=%-6d sigma_a2=%.6f converged=%s iters=%d fill=%.1f (n_profile_samples=%d)\n",
                q, inst.sigma_a2, inst.converged, inst.iterations, inst.fill, n_samples)
    end

    # Two or more targets can resolve to the identical nfounder_frac (measured:
    # 150 and 471 both land on the same closest-achievable fill at q=5000 --
    # see the file header). Running the identical deterministic fixture twice
    # would duplicate every (fixture,q,fill,iteration,section) row in the TSV,
    # so skip a target once its achieved fill matches one already run.
    seen_fill_buckets = Set{Int}()
    for target in f0adv_targets
        frac, achieved_fill = find_nfounder_frac_for_fill(f0adv_q, target)
        fill_bucket = round(Int, achieved_fill)
        if fill_bucket in seen_fill_buckets
            @printf("f0adv  q=%-6d target_fill=%-6.0f achieved_fill=%-7.1f  [skipped: duplicate of an already-run rung]\n",
                    f0adv_q, target, achieved_fill)
            continue
        end
        push!(seen_fill_buckets, fill_bucket)
        spec = f0adv_fixture(f0adv_q; nfounder_frac = frac)
        rows, inst, shares, n_samples = _rows_for_fixture("f0adv", f0adv_q, spec)
        append!(all_rows, rows)
        push!(share_lines, _top3_share_line("f0adv", f0adv_q, inst.fill, shares))
        gap = abs(achieved_fill - target) > 0.15 * target ? "  [target $(target) not reached]" : ""
        @printf("f0adv  q=%-6d target_fill=%-6.0f achieved_fill=%-7.1f sigma_a2=%.6f converged=%s%s\n",
                f0adv_q, target, achieved_fill, inst.sigma_a2, inst.converged, gap)
    end

    outfile = ladder_tsv_path()
    open(outfile, "w") do io
        write_tsv(io, all_rows)
    end
    @printf("\npeak RSS: %.1f MB\n", Sys.maxrss() / 2^20)
    println("wrote ", outfile)
    println()
    println("Section-share table (top 3 per rung):")
    for line in share_lines
        println("  ", line)
    end
    return outfile
end

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

function _parse_args(args)
    opts = Dict{String,String}()
    i = 1
    while i <= length(args)
        a = args[i]
        if startswith(a, "--")
            key = a[3:end]
            if i < length(args) && !startswith(args[i + 1], "--")
                opts[key] = args[i + 1]
                i += 2
            else
                opts[key] = "true"
                i += 1
            end
        else
            i += 1
        end
    end
    return opts
end

function main(args)
    opts = _parse_args(args)
    gate = get(opts, "gate", nothing)
    fixture = get(opts, "fixture", nothing)
    qs = haskey(opts, "q") ? parse.(Int, split(opts["q"], ",")) : nothing
    target_fill = haskey(opts, "target-fill") ? parse(Float64, opts["target-fill"]) : nothing

    if gate == "bitwise"
        q = qs === nothing ? 5000 : qs[1]
        fixture == "f0adv" && error("gate bitwise is defined for --fixture halfsib")
        return gate_bitwise(q)
    elseif gate == "pins"
        return gate_pins(qs === nothing ? [1000, 5000, 20000, 50000] : qs)
    elseif gate == "tsv"
        return gate_tsv()
    elseif gate == "prerun"
        q = qs === nothing ? 5000 : qs[1]
        target_fill === nothing && error("gate prerun requires --target-fill")
        return gate_prerun(q, target_fill)
    elseif gate !== nothing
        error("unknown --gate $(gate)")
    end

    # No --gate: full ladder, or an ad-hoc single-rung run when
    # --fixture/--q are given (used for smoke testing before the full run).
    if fixture !== nothing || qs !== nothing
        fixture = fixture === nothing ? "halfsib" : fixture
        q = qs === nothing ? 1000 : qs[1]
        if fixture == "halfsib"
            spec = halfsib_fixture(q)
            rows, inst, shares, n_samples = _rows_for_fixture("halfsib", q, spec)
            outfile = smoke_tsv_path()
            open(outfile, "w") do io
                write_tsv(io, rows)
            end
            @printf("halfsib q=%-6d sigma_a2=%.6f sigma_e2=%.6f converged=%s iters=%d fill=%.1f\n",
                    q, inst.sigma_a2, inst.sigma_e2, inst.converged, inst.iterations, inst.fill)
            println(_top3_share_line("halfsib", q, inst.fill, shares))
            println("wrote ", outfile)
        else
            target = target_fill === nothing ? 150.0 : target_fill
            frac, achieved_fill = find_nfounder_frac_for_fill(q, target)
            spec = f0adv_fixture(q; nfounder_frac = frac)
            rows, inst, shares, n_samples = _rows_for_fixture("f0adv", q, spec)
            outfile = smoke_tsv_path()
            open(outfile, "w") do io
                write_tsv(io, rows)
            end
            @printf("f0adv q=%-6d target_fill=%.0f achieved_fill=%.1f sigma_a2=%.6f converged=%s\n",
                    q, target, achieved_fill, inst.sigma_a2, inst.converged)
            println(_top3_share_line("f0adv", q, inst.fill, shares))
            println("wrote ", outfile)
        end
        return 0
    end

    run_ladder()
    return 0
end

exit(main(ARGS))
