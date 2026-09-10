#!/usr/bin/env julia
# Retained H3 S11 driver. One invocation produces exactly one estimand/seed row.

using TOML

const H3_S11_ROOT = normpath(joinpath(@__DIR__, ".."))
include(joinpath(H3_S11_ROOT, "sim", "hsq09_h3_replacement_s10.jl"))

const H3_S11_ID = "HSQ09-H3-REPLACEMENT-S11-01"
const H3_S11_RANGES = Dict("rg" => 202609110001:202609112000,
                           "ram" => 202609120001:202609122000)
const H3_S11_COLUMNS = ("campaign", "seed", "estimand", "truth", "level",
    "fit_converged", "interval_success", "failure_reason", "covered",
    "estimate", "lower", "upper", "method", "endpoint_scale", "claim_eligible")

function _h3_s11_failtext(err)
    replace(sprint(showerror, err), '\t' => ' ', '\n' => ' ')
end

function _h3_s11_valid(receipt)
    get(receipt, "interval_success", false) === true &&
        all(isfinite, (receipt["lower"], receipt["estimate"], receipt["upper"])) &&
        -1 < receipt["lower"] < receipt["estimate"] < receipt["upper"] < 1
end

function h3_replacement_s11_rep(cell::AbstractString, seed::Integer)
    haskey(H3_S11_RANGES, cell) || throw(ArgumentError("cell must be rg or ram"))
    seed in H3_S11_RANGES[cell] || throw(ArgumentError("seed is outside frozen $(cell) S11 range"))
    spec = h3_replacement_s10_cell(cell)
    spec["seed"] = seed
    receipt = try
        cell == "rg" ? _run_rg(spec) : _run_ram(spec)
    catch err
        base = _receipt_base(spec)
        merge!(base, Dict{String,Any}("fit_converged" => false,
            "interval_success" => false, "lower" => NaN, "estimate" => NaN,
            "upper" => NaN, "failure_reason" => _h3_s11_failtext(err)))
        base
    end
    valid = _h3_s11_valid(receipt)
    reason = valid ? "" : get(receipt, "failure_reason", "invalid_interval")
    isempty(reason) && (reason = "invalid_interval")
    return (campaign=H3_S11_ID, seed=seed, estimand=receipt["estimand"], truth=spec["truth"],
        level=spec["level"], fit_converged=get(receipt, "fit_converged", false),
        interval_success=valid, failure_reason=valid ? "" : reason,
        covered=valid && receipt["lower"] <= spec["truth"] <= receipt["upper"],
        estimate=valid ? receipt["estimate"] : NaN, lower=valid ? receipt["lower"] : NaN,
        upper=valid ? receipt["upper"] : NaN, method=get(receipt, "method", ""),
        endpoint_scale=get(receipt, "endpoint_scale", ""), claim_eligible=false)
end

function write_h3_replacement_s11_receipt(path::AbstractString; cell::AbstractString, seed::Integer)
    ispath(path) && throw(ArgumentError("refusing to overwrite retained receipt: $(path)"))
    row = h3_replacement_s11_rep(cell, seed)
    mkpath(dirname(path)); temp = tempname(dirname(path))
    try
        open(temp, "w") do io
            println(io, join(H3_S11_COLUMNS, '\t'))
            println(io, join((getproperty(row, Symbol(col)) for col in H3_S11_COLUMNS), '\t'))
        end
        mv(temp, path)
    finally
        ispath(temp) && rm(temp; force=true)
    end
    path
end

function _h3_s11_main(args=ARGS)
    length(args) == 3 || error("use --cell=rg|ram --seed=INTEGER --out=PATH")
    options = Dict(split(arg[3:end], "=", limit=2) for arg in args if startswith(arg, "--") && occursin('=', arg))
    length(options) == 3 && Set(keys(options)) == Set(["cell", "seed", "out"]) || error("invalid options")
    seed = parse(Int, options["seed"])
    path = write_h3_replacement_s11_receipt(options["out"]; cell=options["cell"], seed=seed)
    cell = options["cell"]
    println("H3_REPLACEMENT_S11_RETAINED cell=$(cell) seed=$(seed) path=$(path) claim_eligible=false")
end

if abspath(PROGRAM_FILE) == @__FILE__
    _h3_s11_main()
end
