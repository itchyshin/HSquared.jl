#!/usr/bin/env julia
#=
HSquared.jl #366 — sparse K-effect / summed-ratio interval coverage harness.

Predeclaration: docs/design/58-k-effect-coverage-predeclaration.md
Seeds: docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-seeds.txt

Routes: sparse `fit_multi_effect(:auto)` ONLY. No dense arm.
Claim class: bank evidence; directional-conservative ceiling; no covered flip.

Usage (smoke, Totoro ≤16 cores):
  OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
  julia --project=. sim/phase3_k_effect_coverage.jl \
    --mode=smoke --host=Totoro --reps=50 \
    --out=docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-smoke-replicates.tsv \
    --summary=docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-smoke-summary.tsv
=#

using HSquared
using LinearAlgebra
using Printf
using Random
using SparseArrays
using Statistics

const Z95 = 1.959963984540054
const SEED_FILE = joinpath(@__DIR__, "..",
    "docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-seeds.txt")

const CELLS = Dict(
    "interior" => (Va = 0.3, Vpe = 0.2, Ve = 0.5),
    "low_pe" => (Va = 0.3, Vpe = 0.05, Ve = 0.65),
    "near_pe" => (Va = 0.3, Vpe = 0.01, Ve = 0.69),
    "near_va" => (Va = 0.01, Vpe = 0.3, Ve = 0.69),
)

# Aliases expand before the per-cell loop. Comma-separated cells also accepted.
const CELL_ALIASES = Dict(
    "near_boundary" => ["near_pe", "near_va"],
    "main_rest" => ["low_pe", "near_pe", "near_va"],
    "main" => ["interior", "low_pe", "near_pe", "near_va"],
)

function _resolve_cells(spec::AbstractString)
    s = strip(spec)
    haskey(CELL_ALIASES, s) && return copy(CELL_ALIASES[s])
    cells = String.(split(s, ','; keepempty = false))
    isempty(cells) && error("empty --cell=")
    for c in cells
        haskey(CELLS, c) || error("unknown cell=$c; known=$(keys(CELLS)); aliases=$(keys(CELL_ALIASES))")
    end
    return cells
end

const DETAIL_COLS = [
    "cell", "seed", "host", "route", "nsire", "ndam", "noffspring", "records",
    "n_animals", "n_obs",
    "Va_true", "Vpe_true", "Ve_true", "h2_true", "t_true",
    "fit_ok", "fit_converged", "fit_error",
    "Va_hat", "Vpe_hat", "Ve_hat", "h2_hat", "t_hat",
    "se_ok", "se_error", "boundary_h2", "boundary_t",
    "Va_se", "Vpe_se", "Ve_se",
    "Va_lo", "Va_hi", "Vpe_lo", "Vpe_hi", "Ve_lo", "Ve_hi",
    "h2_lo", "h2_hi", "t_lo", "t_hi",
    "cover_Va", "cover_Vpe", "cover_Ve", "cover_h2", "cover_t",
]

function _extract(args, key, default)
    prefix = "--$key="
    for a in args
        startswith(a, prefix) && return String(split(a, "="; limit = 2)[2])
    end
    return default
end

function _load_seeds(path::AbstractString, n::Int)
    seeds = Int[]
    open(path) do io
        for line in eachline(io)
            s = strip(line)
            startswith(s, "#") && continue
            isempty(s) && continue
            push!(seeds, parse(Int, s))
            length(seeds) >= n && break
        end
    end
    length(seeds) < n && error("seed file $path has only $(length(seeds)) seeds; need $n")
    return seeds
end

function _halfsib_pedigree(nsire, ndam, noffspring)
    sire_ids = ["s$i" for i in 1:nsire]
    dam_ids = ["d$i" for i in 1:ndam]
    off_ids = ["o$i" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(fill("0", nsire + ndam),
                [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring])
    dam = vcat(fill("0", nsire + ndam),
               [dam_ids[((i - 1) % ndam) + 1] for i in 1:noffspring])
    return normalize_pedigree(ids, sire, dam)
end

function _simulate_and_fit(seed::Int; nsire, ndam, noffspring, records, Va, Vpe, Ve, mu)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    LA = cholesky(Symmetric(A)).L
    a_full = (LA * randn(rng, q)) .* sqrt(Va)

    idpos = Dict(id => i for (i, id) in enumerate(ped.ids))
    off_rows = [idpos["o$i"] for i in 1:noffspring]
    n = noffspring * records
    y = Vector{Float64}(undef, n)
    Zrows = Vector{Int}(undef, n)
    r = 0
    for oi in 1:noffspring
        arow = off_rows[oi]
        pe = sqrt(Vpe) * randn(rng)
        for _ in 1:records
            r += 1
            Zrows[r] = arow
            y[r] = mu + a_full[arow] + pe + sqrt(Ve) * randn(rng)
        end
    end
    X = ones(n, 1)
    Z = sparse(1:n, Zrows, 1.0, n, q)
    Ipe = spdiagm(0 => ones(q))
    effs = [(Z, Ainv), (Z, Ipe)]

    fit = fit_multi_effect(y, X, effs; method = :auto, verbose = false)
    return (; y, X, effs, fit, n_animals = q, n_obs = n)
end

_nan_row() = fill("", length(DETAIL_COLS))

function _bool01(x)::String
    x === missing && return "NA"
    x === nothing && return "NA"
    x isa Bool && return x ? "1" : "0"
    return string(x)
end

function _cover_wald(hat, se, truth)
    (!isfinite(hat) || !isfinite(se) || se <= 0) && return missing
    lo = hat - Z95 * se
    hi = hat + Z95 * se
    return lo <= truth <= hi
end

function _cover_ci(lo, hi, truth)
    (!isfinite(lo) || !isfinite(hi)) && return missing
    return lo <= truth <= hi
end

"""Logit-scale Wald CI matching `_sum_ratio_ci_from_cov` / single-component sum-ratio.
Uses the same z as Wald VC intervals (level fixed at 0.95 in this harness)."""
function _logit_ci(ratio::Float64, se::Float64; boundary_tol::Float64 = 1e-6)
    na = (lower = NaN, upper = NaN, boundary = true)
    (ratio > boundary_tol && ratio < 1 - boundary_tol) || return na
    (isfinite(se) && se > 0) || return na
    eta = log(ratio / (1 - ratio))
    se_eta = se / (ratio * (1 - ratio))
    lower = 1 / (1 + exp(-(eta - Z95 * se_eta)))
    upper = 1 / (1 + exp(-(eta + Z95 * se_eta)))
    return (lower = lower, upper = upper, boundary = false)
end

function _one_replicate(seed::Int, cell::String, host::String;
                       nsire, ndam, noffspring, records, mu)
    truth = CELLS[cell]
    total = truth.Va + truth.Vpe + truth.Ve
    h2_true = truth.Va / total
    t_true = (truth.Va + truth.Vpe) / total

    row = Dict{String,String}(c => "" for c in DETAIL_COLS)
    row["cell"] = cell
    row["seed"] = string(seed)
    row["host"] = host
    row["route"] = "sparse_auto"
    row["nsire"] = string(nsire)
    row["ndam"] = string(ndam)
    row["noffspring"] = string(noffspring)
    row["records"] = string(records)
    row["Va_true"] = @sprintf("%.10g", truth.Va)
    row["Vpe_true"] = @sprintf("%.10g", truth.Vpe)
    row["Ve_true"] = @sprintf("%.10g", truth.Ve)
    row["h2_true"] = @sprintf("%.10g", h2_true)
    row["t_true"] = @sprintf("%.10g", t_true)

    local sim
    try
        sim = _simulate_and_fit(seed; nsire, ndam, noffspring, records,
                                Va = truth.Va, Vpe = truth.Vpe, Ve = truth.Ve, mu = mu)
        row["fit_ok"] = "1"
        row["fit_converged"] = sim.fit.converged ? "1" : "0"
        row["fit_error"] = ""
    catch err
        row["fit_ok"] = "0"
        row["fit_converged"] = "0"
        row["fit_error"] = replace(sprint(showerror, err), r"[\t\n\r]" => " ")
        row["n_animals"] = string(nsire + ndam + noffspring)
        row["n_obs"] = string(noffspring * records)
        for k in ("cover_Va", "cover_Vpe", "cover_Ve", "cover_h2", "cover_t")
            row[k] = "NA"
        end
        return [row[c] for c in DETAIL_COLS]
    end

    row["n_animals"] = string(sim.n_animals)
    row["n_obs"] = string(sim.n_obs)
    vc = sim.fit.variance_components
    Va_hat = Float64(vc.sigmas[1])
    Vpe_hat = Float64(vc.sigmas[2])
    Ve_hat = Float64(vc.sigma_e2)
    h2_hat = Va_hat / (Va_hat + Vpe_hat + Ve_hat)
    t_hat = (Va_hat + Vpe_hat) / (Va_hat + Vpe_hat + Ve_hat)
    row["Va_hat"] = @sprintf("%.10g", Va_hat)
    row["Vpe_hat"] = @sprintf("%.10g", Vpe_hat)
    row["Ve_hat"] = @sprintf("%.10g", Ve_hat)
    row["h2_hat"] = @sprintf("%.10g", h2_hat)
    row["t_hat"] = @sprintf("%.10g", t_hat)

    if !sim.fit.converged
        row["se_ok"] = "0"
        row["se_error"] = "fit_not_converged"
        for k in ("cover_Va", "cover_Vpe", "cover_Ve", "cover_h2", "cover_t")
            row[k] = "NA"
        end
        return [row[c] for c in DETAIL_COLS]
    end

    try
        # One covariance → VC SEs, ratio SEs, and summed-ratio (t) interval.
        unc = multi_effect_uncertainty(
            sim.y, sim.X, sim.effs, vc.sigmas, vc.sigma_e2;
            which = 1:2, level = 0.95,
        )
        ses = unc.variance_component_se
        ci_h2 = _logit_ci(h2_hat, Float64(unc.ratio_se[1]))
        ci_t = unc.sum_ratio_interval

        row["se_ok"] = "1"
        row["se_error"] = ""
        row["boundary_h2"] = ci_h2.boundary ? "1" : "0"
        row["boundary_t"] = ci_t.boundary ? "1" : "0"
        row["Va_se"] = @sprintf("%.10g", ses.sigmas[1])
        row["Vpe_se"] = @sprintf("%.10g", ses.sigmas[2])
        row["Ve_se"] = @sprintf("%.10g", ses.sigma_e2)
        row["Va_lo"] = @sprintf("%.10g", Va_hat - Z95 * ses.sigmas[1])
        row["Va_hi"] = @sprintf("%.10g", Va_hat + Z95 * ses.sigmas[1])
        row["Vpe_lo"] = @sprintf("%.10g", Vpe_hat - Z95 * ses.sigmas[2])
        row["Vpe_hi"] = @sprintf("%.10g", Vpe_hat + Z95 * ses.sigmas[2])
        row["Ve_lo"] = @sprintf("%.10g", Ve_hat - Z95 * ses.sigma_e2)
        row["Ve_hi"] = @sprintf("%.10g", Ve_hat + Z95 * ses.sigma_e2)
        row["h2_lo"] = @sprintf("%.10g", ci_h2.lower)
        row["h2_hi"] = @sprintf("%.10g", ci_h2.upper)
        row["t_lo"] = @sprintf("%.10g", ci_t.lower)
        row["t_hi"] = @sprintf("%.10g", ci_t.upper)

        row["cover_Va"] = _bool01(_cover_wald(Va_hat, ses.sigmas[1], truth.Va))
        row["cover_Vpe"] = _bool01(_cover_wald(Vpe_hat, ses.sigmas[2], truth.Vpe))
        row["cover_Ve"] = _bool01(_cover_wald(Ve_hat, ses.sigma_e2, truth.Ve))
        row["cover_h2"] = ci_h2.boundary ? "NA" : _bool01(_cover_ci(ci_h2.lower, ci_h2.upper, h2_true))
        row["cover_t"] = ci_t.boundary ? "NA" : _bool01(_cover_ci(ci_t.lower, ci_t.upper, t_true))
    catch err
        row["se_ok"] = "0"
        row["se_error"] = replace(sprint(showerror, err), r"[\t\n\r]" => " ")
        for k in ("cover_Va", "cover_Vpe", "cover_Ve", "cover_h2", "cover_t")
            row[k] = "NA"
        end
    end
    return [row[c] for c in DETAIL_COLS]
end

function _write_header!(path)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, join(DETAIL_COLS, '\t'))
    end
end

function _append!(path, row)
    open(path, "a") do io
        println(io, join(row, '\t'))
        flush(io)
    end
end

function _summarize(detail_path::AbstractString, summary_path::AbstractString, host::String)
    lines = readlines(detail_path)
    length(lines) < 2 && error("no replicate rows in $detail_path")
    header = split(lines[1], '\t')
    idx = Dict(h => i for (i, h) in enumerate(header))
    targets = ["Va", "Vpe", "Ve", "h2", "t"]
    cover_cols = Dict(t => "cover_$t" for t in targets)

    by_cell = Dict{String,Vector{Vector{String}}}()
    for line in lines[2:end]
        parts = split(line, '\t')
        cell = parts[idx["cell"]]
        push!(get!(by_cell, cell, Vector{Vector{String}}()), parts)
    end

    mkpath(dirname(summary_path))
    open(summary_path, "w") do io
        println(io, join([
            "cell", "host", "route", "N", "fit_ok", "fit_converged", "se_ok",
            "target", "n_eval", "n_cover", "coverage", "mcse", "n_refuse", "refusal_rate",
            "claim_class",
        ], '\t'))
        for (cell, rows) in sort(collect(by_cell); by = first)
            N = length(rows)
            fit_ok = count(r -> r[idx["fit_ok"]] == "1", rows)
            fit_conv = count(r -> r[idx["fit_converged"]] == "1", rows)
            se_ok = count(r -> r[idx["se_ok"]] == "1", rows)
            for t in targets
                col = cover_cols[t]
                vals = [r[idx[col]] for r in rows]
                n_eval = count(v -> v == "0" || v == "1", vals)
                n_cover = count(v -> v == "1", vals)
                n_refuse = N - n_eval
                cov = n_eval > 0 ? n_cover / n_eval : NaN
                mcse = (n_eval > 0 && isfinite(cov)) ? sqrt(cov * (1 - cov) / n_eval) : NaN
                refusal = n_refuse / N
                println(io, join([
                    cell, host, "sparse_auto", string(N),
                    string(fit_ok), string(fit_conv), string(se_ok),
                    t, string(n_eval), string(n_cover),
                    isnan(cov) ? "NA" : @sprintf("%.6f", cov),
                    isnan(mcse) ? "NA" : @sprintf("%.6f", mcse),
                    string(n_refuse), @sprintf("%.6f", refusal),
                    "directional-conservative-bank",
                ], '\t'))
            end
        end
    end
end

function main(args)
    mode = _extract(args, "mode", "smoke")
    host = _extract(args, "host", "local")
    reps = parse(Int, _extract(args, "reps", mode == "smoke" ? "50" : "500"))
    cell = _extract(args, "cell", "interior")
    nsire = parse(Int, _extract(args, "nsire", "15"))
    ndam = parse(Int, _extract(args, "ndam", "30"))
    noffspring = parse(Int, _extract(args, "noffspring", "200"))
    records = parse(Int, _extract(args, "records", "2"))
    mu = parse(Float64, _extract(args, "mu", "2.0"))
    out = _extract(args, "out",
        "docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-smoke-replicates.tsv")
    summary = _extract(args, "summary",
        "docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-smoke-summary.tsv")
    seed_file = _extract(args, "seeds-file", SEED_FILE)
    resume = _extract(args, "resume", "true") in ("true", "1", "")

    cells = _resolve_cells(cell)
    mode == "smoke" && cells != ["interior"] &&
        @warn "smoke predeclaration uses interior only; running cells=$(join(cells, ',')) anyway"

    seeds = _load_seeds(seed_file, reps)
    if !(resume && isfile(out) && filesize(out) > 0)
        _write_header!(out)
    end

    @printf("K-effect coverage #366 mode=%s host=%s cells=%s reps=%d design=%d/%d/%d×%d\n",
            mode, host, join(cells, ","), reps, nsire, ndam, noffspring, records)
    @printf("seed file=%s out=%s\n", seed_file, out)

    for cell_name in cells
        done = Set{Int}()
        if resume && isfile(out) && filesize(out) > 0
            open(out) do io
                cols = split(readline(io), '\t')
                si = findfirst(==("seed"), cols)
                ci = findfirst(==("cell"), cols)
                (si === nothing || ci === nothing) && error("detail TSV missing seed/cell columns: $out")
                for line in eachline(io)
                    parts = split(line, '\t')
                    length(parts) < max(si, ci) && continue
                    parts[ci] == cell_name || continue
                    push!(done, parse(Int, parts[si]))
                end
            end
        end

        @printf("--- cell=%s (%d seeds done / %d)\n", cell_name, length(done), reps)
        for (i, seed) in enumerate(seeds)
            if seed in done
                @printf("[%s %d/%d] seed=%d SKIP (resume)\n", cell_name, i, reps, seed)
                continue
            end
            t0 = time()
            row = _one_replicate(seed, cell_name, host; nsire, ndam, noffspring, records, mu)
            _append!(out, row)
            @printf("[%s %d/%d] seed=%d fit=%s se=%s cover_t=%s (%.1fs)\n",
                    cell_name, i, reps, seed, row[findfirst(==("fit_ok"), DETAIL_COLS)],
                    row[findfirst(==("se_ok"), DETAIL_COLS)],
                    row[findfirst(==("cover_t"), DETAIL_COLS)], time() - t0)
        end
    end

    _summarize(out, summary, host)
    @printf("Wrote summary %s\n", summary)
    return 0
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main(ARGS))
end
