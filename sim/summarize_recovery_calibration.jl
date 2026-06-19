module RecoveryCalibrationSummary

export RecoveryLogRow, case_summaries, markdown_summary, parse_recovery_log,
    parse_recovery_logs, failure_mode, failure_mode_counts

struct RecoveryLogRow
    case::String
    seed::Int
    observations::Int
    animals::Int
    traits::Int
    records_per_animal::Int
    converged::Bool
    iterations::Int
    rel_g::Float64
    threshold_g::Float64
    rel_r::Float64
    threshold_r::Float64
    pass::Bool
end

struct _PartialRecoveryLogRow
    case::String
    seed::Int
    observations::Int
    animals::Int
    traits::Int
    records_per_animal::Int
    pass::Bool
end

function _parse_bool(text)
    text == "true" && return true
    text == "false" && return false
    throw(ArgumentError("expected true/false, got $text"))
end

function parse_recovery_log(path::AbstractString)
    rows = RecoveryLogRow[]
    partial = nothing
    converged = nothing
    iterations = nothing
    rel_g = nothing
    threshold_g = nothing

    for line in eachline(path)
        header = match(r"^\[(PASS|FAIL)\] ([a-z_]+) seed=(\d+) observations=(\d+) animals=(\d+) traits=(\d+) records_per_animal=(\d+)", line)
        if header !== nothing
            partial === nothing ||
                throw(ArgumentError("found a new row before completing previous row in $path"))
            partial = _PartialRecoveryLogRow(
                header.captures[2],
                parse(Int, header.captures[3]),
                parse(Int, header.captures[4]),
                parse(Int, header.captures[5]),
                parse(Int, header.captures[6]),
                parse(Int, header.captures[7]),
                header.captures[1] == "PASS",
            )
            continue
        end

        convergence = match(r"^\s+converged=(true|false) iterations=(\d+)", line)
        if convergence !== nothing
            partial === nothing &&
                throw(ArgumentError("found convergence line before row header in $path"))
            converged = _parse_bool(convergence.captures[1])
            iterations = parse(Int, convergence.captures[2])
            continue
        end

        genetic = match(r"^\s+relative_error_G=([0-9.]+) threshold=([0-9.]+)", line)
        if genetic !== nothing
            partial === nothing &&
                throw(ArgumentError("found G-error line before row header in $path"))
            rel_g = parse(Float64, genetic.captures[1])
            threshold_g = parse(Float64, genetic.captures[2])
            continue
        end

        residual = match(r"^\s+relative_error_R=([0-9.]+) threshold=([0-9.]+)", line)
        if residual !== nothing
            partial === nothing &&
                throw(ArgumentError("found R-error line before row header in $path"))
            converged === nothing && throw(ArgumentError("missing convergence line before R-error in $path"))
            rel_g === nothing && throw(ArgumentError("missing G-error line before R-error in $path"))
            rel_r = parse(Float64, residual.captures[1])
            threshold_r = parse(Float64, residual.captures[2])
            push!(rows, RecoveryLogRow(
                partial.case,
                partial.seed,
                partial.observations,
                partial.animals,
                partial.traits,
                partial.records_per_animal,
                converged,
                iterations,
                rel_g,
                threshold_g,
                rel_r,
                threshold_r,
                partial.pass,
            ))
            partial = nothing
            converged = nothing
            iterations = nothing
            rel_g = nothing
            threshold_g = nothing
            continue
        end
    end

    partial === nothing || throw(ArgumentError("incomplete final row in $path"))
    return rows
end

parse_recovery_logs(paths) = reduce(vcat, (parse_recovery_log(path) for path in paths); init = RecoveryLogRow[])

function _mean(values)
    collected = collect(values)
    return sum(collected) / length(collected)
end

function _median(values)
    sorted = sort(collect(values))
    n = length(sorted)
    isodd(n) && return sorted[(n + 1) ÷ 2]
    return (sorted[n ÷ 2] + sorted[n ÷ 2 + 1]) / 2
end

function _wilson_interval(k, n; z = 1.959963984540054)
    p = k / n
    denominator = 1 + z^2 / n
    center = (p + z^2 / (2n)) / denominator
    half_width = z * sqrt(p * (1 - p) / n + z^2 / (4n^2)) / denominator
    return max(0.0, center - half_width), min(1.0, center + half_width)
end

function case_summaries(rows)
    cases = unique(row.case for row in rows)
    summaries = Dict{String,NamedTuple}()
    for case in cases
        case_rows = filter(row -> row.case == case, rows)
        n = length(case_rows)
        passed = count(row -> row.pass, case_rows)
        converged = count(row -> row.converged, case_rows)
        wilson = _wilson_interval(passed, n)
        summaries[case] = (
            seeds = n,
            converged = converged,
            passed = passed,
            pass_proportion = passed / n,
            wilson_low = wilson[1],
            wilson_high = wilson[2],
            mean_g = _mean(row.rel_g for row in case_rows),
            median_g = _median(row.rel_g for row in case_rows),
            max_g = maximum(row.rel_g for row in case_rows),
            mean_r = _mean(row.rel_r for row in case_rows),
            median_r = _median(row.rel_r for row in case_rows),
            max_r = maximum(row.rel_r for row in case_rows),
        )
    end
    return summaries
end

function failure_mode(row::RecoveryLogRow)
    row.pass && return "pass"
    g_failed = row.rel_g > row.threshold_g
    r_failed = row.rel_r > row.threshold_r
    g_failed && r_failed && return "G+R"
    g_failed && return "G"
    r_failed && return "R"
    return "reported-fail"
end

function failure_mode_counts(rows)
    cases = unique(row.case for row in rows)
    counts = Dict{String,NamedTuple}()
    for case in cases
        failed = filter(row -> row.case == case && !row.pass, rows)
        counts[case] = (
            total = length(failed),
            g_only = count(row -> failure_mode(row) == "G", failed),
            r_only = count(row -> failure_mode(row) == "R", failed),
            both = count(row -> failure_mode(row) == "G+R", failed),
            reported_fail = count(row -> failure_mode(row) == "reported-fail", failed),
        )
    end
    return counts
end

function _fmt(x::Real)
    rounded = floor(Float64(x) * 1_000_000 + 0.5) / 1_000_000
    text = string(rounded)
    if !occursin(".", text)
        text *= "."
    end
    decimals = ncodeunits(split(text, ".")[2])
    return text * repeat("0", max(0, 6 - decimals))
end

function markdown_summary(rows)
    summaries = case_summaries(rows)
    lines = String[]
    push!(lines, "# Recovery Calibration Summary")
    push!(lines, "")
    push!(lines, "| case | seeds | converged | passed | pass proportion | Wilson 95% interval | mean G error | median G error | max G error | mean R error | median R error | max R error |")
    push!(lines, "| --- | ---: | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |")
    for case in sort(collect(keys(summaries)))
        row = summaries[case]
        push!(lines, "| $case | $(row.seeds) | $(row.converged) | $(row.passed) | $(_fmt(row.pass_proportion)) | $(_fmt(row.wilson_low))-$(_fmt(row.wilson_high)) | $(_fmt(row.mean_g)) | $(_fmt(row.median_g)) | $(_fmt(row.max_g)) | $(_fmt(row.mean_r)) | $(_fmt(row.median_r)) | $(_fmt(row.max_r)) |")
    end
    push!(lines, "")
    push!(lines, "## Failure Modes")
    push!(lines, "")
    push!(lines, "| case | failed seeds | G only | R only | G+R | reported fail |")
    push!(lines, "| --- | ---: | ---: | ---: | ---: | ---: |")
    counts = failure_mode_counts(rows)
    for case in sort(collect(keys(counts)))
        row = counts[case]
        push!(lines, "| $case | $(row.total) | $(row.g_only) | $(row.r_only) | $(row.both) | $(row.reported_fail) |")
    end
    push!(lines, "")
    push!(lines, "## Failed Seeds")
    push!(lines, "")
    for case in sort(unique(row.case for row in rows))
        failed = filter(row -> row.case == case && !row.pass, rows)
        value = isempty(failed) ? "none" :
            join([
                "$(row.seed) ($(failure_mode(row)); G=$(_fmt(row.rel_g)), R=$(_fmt(row.rel_r)))"
                for row in failed
            ], "; ")
        push!(lines, "- $case: $value")
    end
    return join(lines, "\n")
end

function main(args = ARGS)
    isempty(args) && throw(ArgumentError("usage: summarize_recovery_calibration.jl LOG [LOG ...]"))
    print(markdown_summary(parse_recovery_logs(args)))
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    RecoveryCalibrationSummary.main()
end
