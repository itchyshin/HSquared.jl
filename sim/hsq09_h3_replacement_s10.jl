#!/usr/bin/env julia
#
# One-cell H3 replacement S10 driver.  It is source-inert: only the sealed
# fixture and existing public engine functions determine a fit.  It never
# pools cells, retries a seed, starts remote work, or makes a capability claim.

using HSquared
using LinearAlgebra
using Random
using TOML

const H3R_S10_ROOT = normpath(joinpath(@__DIR__, ".."))
const H3R_S10_FIXTURE = joinpath(H3R_S10_ROOT, "test", "fixtures",
    "h3_replacement_interval", "fixture.toml")

# Include-safe deterministic DGP builders.  Their PROGRAM_FILE guards prevent
# their recovery campaigns from executing here.
include(joinpath(H3R_S10_ROOT, "sim", "phase4_multivariate_reml_recovery.jl"))
include(joinpath(H3R_S10_ROOT, "sim", "phase4_direct_maternal_recovery_gate.jl"))

_bool(x::Bool) = x
_bool(x) = error("expected boolean, got $(repr(x))")

function h3_replacement_s10_cell(cell::AbstractString)
    fixture = TOML.parsefile(H3R_S10_FIXTURE)
    key = cell == "rg" ? "rg" : cell == "ram" ? "ram" :
        throw(ArgumentError("cell must be `rg` or `ram`, got $(repr(cell))"))
    value = Dict{String,Any}(fixture[key])
    value["cell"] = key
    value["threads"] = 1
    value["path_only"] = true
    return value
end

function h3_replacement_s10_dry_run(cell::AbstractString)
    spec = h3_replacement_s10_cell(cell)
    return Dict(
        "cell" => spec["cell"], "seed" => spec["seed"],
        "animals" => spec["animals"], "records" => spec["records"],
        "iterations" => spec["iterations"], "threads" => 1,
        "path_only" => true, "source_inert" => true,
    )
end

_errtext(err) = replace(sprint(showerror, err), '\n' => " | ")

function _receipt_base(spec)
    return Dict{String,Any}(
        "schema" => "HSQ09-H3-REPLACEMENT-S10-RECEIPT-01",
        "cell" => spec["cell"], "estimand" => spec["estimand"],
        "seed" => spec["seed"], "animals" => spec["animals"],
        "records" => spec["records"], "iterations" => spec["iterations"],
        "level" => spec["level"], "fit" => spec["fit"],
        "interval" => spec["interval"], "path_only" => true,
        "claim_eligible" => false, "s11_authorized" => false,
        "promotion_authorized" => false, "release_authorized" => false,
    )
end

function _interior(lo, est, hi)
    all(isfinite, (lo, est, hi)) && -1.0 < lo < est < hi < 1.0
end

function _run_rg(spec)
    config = MultivariateRecoveryConfig(
        spec["seed"], spec["sires"], spec["dams"], spec["offspring"],
        spec["records_per_animal"], spec["iterations"], Inf, Inf, true,
        [spec["g11"] spec["g12"]; spec["g12"] spec["g22"]],
        [spec["r11"] spec["r12"]; spec["r12"] spec["r22"]],
        "HSQ09-H3-rg", false, 1.0e6, "halfsib", 0, 0,
    )
    Y, X, Z, Ainv, _, _, _ = _simulate_repeated_records(config)
    fit = fit_multivariate_reml(Y, X, Z, Ainv; initial = nothing,
        iterations = spec["iterations"])
    ci = genetic_correlation_interval(fit, Y, X, Z, Ainv;
        level = spec["level"], method = :delta, pairs = [(2, 1)])
    length(ci.estimate) == 1 || error("r_g interval did not return exactly one pair")
    lo, est, hi = ci.lower[1], ci.estimate[1], ci.upper[1]
    receipt = _receipt_base(spec)
    merge!(receipt, Dict{String,Any}(
        "fit_converged" => fit.converged,
        "interval_converged" => ci.converged[1],
        "interval_success" => _interior(lo, est, hi) && fit.converged && ci.converged[1],
        "method" => "delta", "endpoint_scale" => "fisher_z",
        "pair" => "2,1", "lower" => lo, "estimate" => est, "upper" => hi,
        "lower_clamped" => ci.lower_clamped[1], "upper_clamped" => ci.upper_clamped[1],
        "truth_contained" => lo <= spec["truth"] <= hi,
        "failure_reason" => "",
    ))
    return receipt
end

function _ram_data(spec)
    ctx = build_context(; nd = spec["dams"], ns = spec["sires"],
        noff = spec["offspring_per_dam"], ngen = spec["generations"],
        dam_own_records = true)
    ctx.q == spec["animals"] || error("r_am animal count differs from fixture")
    ctx.n == spec["records"] || error("r_am record count differs from fixture")
    rng = MersenneTwister(spec["seed"])
    G = [spec["sigma_ad2"] spec["sigma_dm"]; spec["sigma_dm"] spec["sigma_am2"]]
    acoef = ctx.LA * randn(rng, ctx.q, 2) * transpose(cholesky(Symmetric(G)).L)
    Zd = zeros(ctx.n, ctx.q); Zm = zeros(ctx.n, ctx.q); y = Vector{Float64}(undef, ctx.n)
    for r in 1:ctx.n
        ia, idm = ctx.animal_rows[r], ctx.dam_rows[r]
        Zd[r, ia] = 1.0; Zm[r, idm] = 1.0
        y[r] = MU + acoef[ia, 1] + acoef[idm, 2] + sqrt(spec["sigma_e2"]) * randn(rng)
    end
    return y, ones(ctx.n, 1), Zd, Zm, ctx
end

function _run_ram(spec)
    y, X, Zd, Zm, ctx = _ram_data(spec)
    ci = direct_maternal_interval(y, X, Zd, Zm, ctx.Ainv;
        level = spec["level"], initial = (G_dm = Matrix(1.0I, 2, 2), sigma_e2 = 1.0),
        iterations = spec["iterations"], ids = ctx.ped.ids)
    r = ci.genetic_correlation
    lo, est, hi = r.lower, r.estimate, r.upper
    receipt = _receipt_base(spec)
    merge!(receipt, Dict{String,Any}(
        "fit_converged" => ci.converged,
        "interval_converged" => ci.information_posdef,
        "interval_success" => _interior(lo, est, hi) && ci.converged && ci.information_posdef &&
            isfinite(r.se) && r.se > 0,
        "method" => "fisher_z", "endpoint_scale" => "fisher_z",
        "lower" => lo, "estimate" => est, "upper" => hi, "se" => r.se,
        "information_posdef" => ci.information_posdef,
        "truth_contained" => lo <= spec["truth"] <= hi,
        "failure_reason" => "",
    ))
    return receipt
end

function h3_replacement_s10_run(cell::AbstractString)
    spec = h3_replacement_s10_cell(cell)
    try
        return cell == "rg" ? _run_rg(spec) : _run_ram(spec)
    catch err
        receipt = _receipt_base(spec)
        merge!(receipt, Dict{String,Any}(
            "fit_converged" => false, "interval_converged" => false,
            "interval_success" => false, "lower" => NaN, "estimate" => NaN,
            "upper" => NaN, "failure_reason" => _errtext(err),
        ))
        return receipt
    end
end

function _parse_cli(args)
    length(args) in (1, 2) || error("usage: --dry-run --cell=rg|ram | --cell=rg|ram --out=RECEIPT.toml")
    opts = Dict{String,String}()
    for arg in args
        startswith(arg, "--") || error("options must begin --")
        pair = split(arg[3:end], "=", limit = 2)
        if length(pair) == 1
            pair[1] == "dry-run" || error("unknown flag $(arg)")
            opts[pair[1]] = "true"
        else
            opts[pair[1]] = pair[2]
        end
    end
    haskey(opts, "cell") || error("--cell is required")
    return opts
end

function main(args = ARGS)
    opts = _parse_cli(args)
    cell = opts["cell"]
    if get(opts, "dry-run", "false") == "true"
        length(opts) == 2 || error("--dry-run accepts only --cell")
        h3_replacement_s10_dry_run(cell)
        println("H3_REPLACEMENT_S10_DRY_RUN_OK cell=$(cell) threads=1 path_only=true")
        return nothing
    end
    haskey(opts, "out") && length(opts) == 2 || error("--out is required for an actual S10 cell")
    out = abspath(opts["out"])
    ispath(out) && error("refusing to overwrite receipt $(out)")
    mkpath(dirname(out))
    receipt = h3_replacement_s10_run(cell)
    open(out, "w") do io
        TOML.print(io, receipt; sorted = true)
    end
    interval_success = receipt["interval_success"]
    println("H3_REPLACEMENT_S10_DRIVER_OK cell=$(cell) interval_success=$(interval_success) path_only=true")
    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
