#!/usr/bin/env julia
include(joinpath(@__DIR__, "..", "sim", "hsq09_h3_replacement_s11.jl"))

function _h3_s11_bool(x::AbstractString)
    x == "true" && return true
    x == "false" && return false
    throw(ArgumentError("invalid Boolean $(repr(x))"))
end

function _h3_s11_rows(dir::AbstractString)
    paths = sort(filter(path -> endswith(path, ".tsv"), readdir(dir; join=true)))
    rows = NamedTuple[]
    for path in paths
        lines = readlines(path); !isempty(lines) && split(first(lines), '\t') == collect(H3_S11_COLUMNS) || error("bad header: $(path)")
        length(lines) == 2 || error("exactly one retained row required: $(path)")
        values = split(lines[2], '\t'); length(values) == length(H3_S11_COLUMNS) || error("bad row: $(path)")
        push!(rows, (path=path, campaign=values[1], seed=parse(Int, values[2]), estimand=values[3],
            truth=parse(Float64, values[4]), level=parse(Float64, values[5]), fit_converged=_h3_s11_bool(values[6]),
            interval_success=_h3_s11_bool(values[7]), failure_reason=values[8], covered=_h3_s11_bool(values[9]),
            estimate=parse(Float64, values[10]), lower=parse(Float64, values[11]), upper=parse(Float64, values[12]),
            method=values[13], endpoint_scale=values[14], claim_eligible=_h3_s11_bool(values[15])))
    end
    rows
end

function h3_replacement_s11_reconcile(dir::AbstractString; cell::AbstractString, task_start::Integer=1,
    task_end::Integer=length(H3_S11_RANGES[cell]))
    haskey(H3_S11_RANGES, cell) || error("bad cell")
    all_seeds = collect(H3_S11_RANGES[cell])
    1 <= task_start <= task_end <= length(all_seeds) || error("task range is outside the ratified cell range")
    seeds = all_seeds[task_start:task_end]
    complete_cell = task_start == 1 && task_end == length(all_seeds)
    rows = _h3_s11_rows(dir); estimand = cell == "rg" ? "r_g" : cell == "ram" ? "r_am" : error("bad cell")
    length(rows) == length(seeds) || error("retained row count differs from requested denominator")
    Set(row.seed for row in rows) == Set(seeds) || error("missing, duplicate, or extra seed")
    all(row -> row.campaign == H3_S11_ID && row.estimand == estimand && !row.claim_eligible, rows) || error("wrong campaign, estimand, or eligibility")
    successes = count(row -> row.interval_success, rows)
    complete_cell && successes < 1800 && error("interval-success floor not met")
    all(row -> row.interval_success || (!row.covered && !isempty(row.failure_reason)), rows) || error("failure retention is incomplete")
    covered = count(row -> row.interval_success && row.covered, rows)
    coverage = successes == 0 ? NaN : covered / successes
    mcse = successes == 0 ? NaN : sqrt(coverage * (1 - coverage) / successes)
    band = 2mcse
    classification = !complete_cell ? :partial_wave : coverage > .95 + band ? :directional_conservative : coverage < .95 - band ? :undercoverage_hold : :calibrated_candidate
    (cell=cell, requested=length(seeds), retained=length(rows), interval_success=successes, covered=covered,
     coverage=coverage, mcse=mcse, complete_cell=complete_cell, classification=classification, claim_eligible=false)
end

function _h3_s11_reconcile_main(args=ARGS)
    opts=Dict(split(arg[3:end], "=", limit=2) for arg in args)
    all(key -> haskey(opts, key), ("cell", "receipts")) || error("use --cell=rg|ram --receipts=DIR [--task-start=N --task-end=N]")
    has_start = haskey(opts, "task-start"); has_end = haskey(opts, "task-end")
    has_start == has_end || error("task-start and task-end must be supplied together")
    task_start = has_start ? parse(Int, opts["task-start"]) : 1
    task_end = has_end ? parse(Int, opts["task-end"]) : length(H3_S11_RANGES[opts["cell"]])
    result=h3_replacement_s11_reconcile(opts["receipts"]; cell=opts["cell"], task_start=task_start, task_end=task_end)
    println("H3_REPLACEMENT_S11_RECONCILE_OK cell=$(result.cell) requested=$(result.requested) retained=$(result.retained) interval_success=$(result.interval_success) coverage=$(result.coverage) mcse=$(result.mcse) complete_cell=$(result.complete_cell) classification=$(result.classification) claim_eligible=false")
end

if abspath(PROGRAM_FILE) == @__FILE__; _h3_s11_reconcile_main(); end
