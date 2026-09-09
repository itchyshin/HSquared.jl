#!/usr/bin/env julia
#
# Deterministic S10 receipt validator.  It validates a completed smoke output
# but never starts a fit, opens a remote connection, or authorizes a claim.

include(joinpath(@__DIR__, "..", "sim", "phase1_interval_coverage_ext.jl"))

const S10_SUMMARY_COLUMNS = (
    "campaign", "estimand", "method", "design", "truth", "level", "scope", "role",
    "reps", "fit_success", "interval_success", "covered",
    "coverage", "mcse_observed", "mcse_nominal", "mean_width",
    "non_interpretable", "claim_eligible",
)

_s10_assert(condition::Bool, label::AbstractString) =
    condition || error("S10 smoke receipt rejected: $(label)")

_s10_smoke_config() = _parse_args(String[])

function _s10_summary_key(row)
    return (row.campaign, row.estimand, row.method, row.design,
            row.truth, row.level, row.scope, row.role)
end

function _s10_parse_summary(path::AbstractString)
    isfile(path) || error("S10 summary file is missing: $(path)")
    filesize(path) > 0 || error("S10 summary file is empty: $(path)")
    rows = Dict{Any,Any}()
    open(path, "r") do io
        eof(io) && error("S10 summary file is empty: $(path)")
        header = readline(io)
        header == join(S10_SUMMARY_COLUMNS, '\t') ||
            error("S10 summary header does not match the frozen schema: $(path)")
        for (line_number, line) in enumerate(eachline(io))
            isempty(strip(line)) && continue
            parts = split(line, '\t'; keepempty = true)
            length(parts) == length(S10_SUMMARY_COLUMNS) ||
                error("S10 summary row $(line_number + 1) has wrong column count")
            context = "S10 summary row $(line_number + 1)"
            row = (
                campaign = String(parts[1]), estimand = String(parts[2]),
                method = String(parts[3]), design = String(parts[4]),
                truth = parse(Float64, parts[5]), level = parse(Float64, parts[6]),
                scope = String(parts[7]), role = String(parts[8]),
                reps = parse(Int, parts[9]), fit_success = parse(Int, parts[10]),
                interval_success = parse(Int, parts[11]), covered = parse(Int, parts[12]),
                coverage = parse(Float64, parts[13]),
                mcse_observed = parse(Float64, parts[14]),
                mcse_nominal = parse(Float64, parts[15]), mean_width = parse(Float64, parts[16]),
                non_interpretable = _parse_detail_bool(parts[17], "$(context) non_interpretable"),
                claim_eligible = _parse_detail_bool(parts[18], "$(context) claim_eligible"),
            )
            key = _s10_summary_key(row)
            haskey(rows, key) && error("duplicate S10 summary key: $(repr(key))")
            rows[key] = row
        end
    end
    isempty(rows) && error("S10 summary contains no retained rows")
    return rows
end

function _s10_expected_summary_row(key, summary)
    campaign, estimand, method, design, truth, level, scope, role = key
    n = summary.interval_success
    coverage = n > 0 ? summary.covered / n : NaN
    return (
        campaign = campaign, estimand = estimand, method = method, design = design,
        truth = truth, level = level, scope = scope, role = role,
        reps = summary.reps, fit_success = summary.fit_success,
        interval_success = summary.interval_success, covered = summary.covered,
        coverage = coverage,
        mcse_observed = n > 0 ? sqrt(max(coverage * (1 - coverage), 0) / n) : NaN,
        mcse_nominal = n > 0 ? sqrt(level * (1 - level) / n) : NaN,
        mean_width = n > 0 ? summary.width_sum / n : NaN,
        non_interpretable = summary.interval_success < EXT_INTERPRETABLE_FRACTION * summary.reps,
        claim_eligible = false,
    )
end

function _s10_same_float(observed::Float64, expected::Float64)
    return (isnan(observed) && isnan(expected)) ||
        # The retained schema deliberately uses the driver's %.8g formatter.
        # Accept that bounded representation error, but not a changed result.
        isapprox(observed, expected; rtol = 5e-8, atol = 5e-9)
end

function _s10_validate_summary_rows(actual, expected)
    Set(keys(actual)) == Set(keys(expected)) || error(
        "S10 summary keys do not reconcile to retained detail rows",
    )
    for (key, aggregate) in expected
        got = actual[key]
        want = _s10_expected_summary_row(key, aggregate)
        for field in (:reps, :fit_success, :interval_success, :covered, :non_interpretable)
            getproperty(got, field) == getproperty(want, field) ||
                error("S10 summary $(repr(key)) disagrees on $(field)")
        end
        got.claim_eligible === false ||
            error("S10 smoke summary must be PATH_ONLY (claim_eligible=false)")
        for field in (:coverage, :mcse_observed, :mcse_nominal, :mean_width)
            _s10_same_float(getproperty(got, field), getproperty(want, field)) ||
                error("S10 summary $(repr(key)) disagrees on $(field)")
        end
    end
    return nothing
end

function validate_s10_smoke(detail_path::AbstractString, summary_path::AbstractString;
                            config = _s10_smoke_config())
    config.mode === :smoke || error("S10 validator accepts only smoke-mode output")
    isfile(detail_path) || error("S10 detail file is missing: $(detail_path)")
    filesize(detail_path) > 0 || error("S10 detail file is empty: $(detail_path)")
    records = _records_for_summary(_read_detail_records(detail_path), config)
    expected = _summaries_from_records(records)
    actual = _s10_parse_summary(summary_path)
    _s10_validate_summary_rows(actual, expected)

    sentinel = [row for row in values(records) if
        row.campaign == "h1_two" && row.estimand == "ratio1" &&
        row.level == 0.95 && row.scope == "interior"
    ]
    length(sentinel) == 1 || error("S10 H1-two interior ratio1 sentinel is absent or duplicated")
    only(sentinel).interval_success ||
        error("S10 H1-two interior ratio1 sentinel has no successful interval")
    all(row -> row.claim_eligible === false, values(actual)) ||
        error("S10 smoke output contains a claim-eligible row")

    return (
        rows = length(records),
        summary_rows = length(actual),
        fit_converged_rows = count(row -> row.fit_converged, values(records)),
        claim_eligible = false,
    )
end

function _s10_self_test()
    cfg = _s10_smoke_config()
    entries = _canonical_task_inventory(cfg)
    mktempdir() do dir
        rows = Any[]
        for entry in entries
            role = entry.campaign === :h1_t ? "characterization_only" : "covered_pillar_bank"
            push!(rows, _detail_row(
                campaign = entry.campaign, cell_id = entry.cell_id, seed = entry.seed, rep = entry.rep,
                estimand = entry.estimand, method = entry.method, design = entry.cell_label,
                n_animals = 12, n_obs = 12, truth = 0.25, level = entry.level,
                scope = entry.scope, role = role, fit_success = true, fit_converged = true,
                interval_success = true, failure_reason = "", covered = true,
                lower = 0.10, upper = 0.40, width = 0.30, estimate = 0.25,
                se = entry.method == "rg_fisher_z" ? NaN : 0.10,
            ))
        end
        detail = joinpath(dir, "detail.tsv")
        summary = joinpath(dir, "summary.tsv")
        _prepare_detail_output(detail; resume = false)
        _write_detail_rows!(detail, rows)
        records = _records_for_summary(_read_detail_records(detail), cfg)
        _write_summary(summary, _summaries_from_records(records))
        result = validate_s10_smoke(detail, summary; config = cfg)
        _s10_assert(result.rows == 7, "positive fixture row count")

        text = read(summary, String)
        write(summary, replace(text, "\tfalse\n" => "\ttrue\n"; count = 1))
        try
            validate_s10_smoke(detail, summary; config = cfg)
        catch err
            err isa ErrorException || rethrow()
            return nothing
        end
        error("S10 mutation accepted claim eligibility")
    end
    return nothing
end

function main(args = ARGS)
    if args == ["--self-test"]
        _s10_self_test()
        println("S10_SMOKE_INFRA_TESTS_OK")
        println("S10_SMOKE_INFRA_MUTATION_CONTROLS_OK")
    elseif length(args) == 3 && args[1] == "--validate"
        result = validate_s10_smoke(args[2], args[3])
        println("S10_SMOKE_RECEIPT_OK rows=$(result.rows) summary_rows=$(result.summary_rows) fit_converged_rows=$(result.fit_converged_rows) claim_eligible=false")
    else
        error("usage: --self-test | --validate DETAIL.tsv SUMMARY.tsv; this tool never starts compute")
    end
    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
