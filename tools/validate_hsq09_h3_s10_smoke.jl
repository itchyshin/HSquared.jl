#!/usr/bin/env julia
#
# H3-only S10 smoke receipt validator. It is deterministic and source-inert:
# it reads a completed driver receipt, never starts a fit or remote action, and
# accepts no claim-eligible result.

include(joinpath(@__DIR__, "..", "sim", "phase1_interval_coverage_ext.jl"))

const H3_S10_SUMMARY_COLUMNS = (
    "campaign", "estimand", "method", "design", "truth", "level", "scope", "role",
    "reps", "fit_success", "interval_success", "covered",
    "coverage", "mcse_observed", "mcse_nominal", "mean_width",
    "non_interpretable", "claim_eligible",
)

function _h3_s10_summary_key(row)
    return (row.campaign, row.estimand, row.method, row.design,
            row.truth, row.level, row.scope, row.role)
end

function _h3_s10_parse_summary(path::AbstractString)
    isfile(path) || error("H3 S10 summary file is missing: $(path)")
    filesize(path) > 0 || error("H3 S10 summary file is empty: $(path)")
    rows = Dict{Any,Any}()
    open(path, "r") do io
        header = readline(io)
        header == join(H3_S10_SUMMARY_COLUMNS, '\t') ||
            error("H3 S10 summary header does not match the frozen schema: $(path)")
        for (line_number, line) in enumerate(eachline(io))
            isempty(strip(line)) && continue
            parts = split(line, '\t'; keepempty = true)
            length(parts) == length(H3_S10_SUMMARY_COLUMNS) ||
                error("H3 S10 summary row $(line_number + 1) has wrong column count")
            context = "H3 S10 summary row $(line_number + 1)"
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
            key = _h3_s10_summary_key(row)
            haskey(rows, key) && error("duplicate H3 S10 summary key: $(repr(key))")
            rows[key] = row
        end
    end
    isempty(rows) && error("H3 S10 summary contains no retained rows")
    return rows
end

function _h3_s10_same_float(observed::Float64, expected::Float64)
    return (isnan(observed) && isnan(expected)) ||
           isapprox(observed, expected; rtol = 5e-8, atol = 5e-9)
end

function _h3_s10_validate_summary_rows(actual, expected)
    Set(keys(actual)) == Set(keys(expected)) || error(
        "H3 S10 summary keys do not reconcile to retained detail rows",
    )
    for (key, aggregate) in expected
        got = actual[key]
        n = aggregate.interval_success
        coverage = n > 0 ? aggregate.covered / n : NaN
        wanted = (
            reps = aggregate.reps,
            fit_success = aggregate.fit_success,
            interval_success = aggregate.interval_success,
            covered = aggregate.covered,
            coverage = coverage,
            mcse_observed = n > 0 ? sqrt(max(coverage * (1 - coverage), 0) / n) : NaN,
            mcse_nominal = n > 0 ? sqrt(H3_S10_LEVEL * (1 - H3_S10_LEVEL) / n) : NaN,
            mean_width = n > 0 ? aggregate.width_sum / n : NaN,
            non_interpretable = aggregate.interval_success < EXT_INTERPRETABLE_FRACTION * aggregate.reps,
        )
        for field in (:reps, :fit_success, :interval_success, :covered, :non_interpretable)
            getproperty(got, field) == getproperty(wanted, field) ||
                error("H3 S10 summary $(repr(key)) disagrees on $(field)")
        end
        got.claim_eligible === false ||
            error("H3 S10 smoke summary must be PATH_ONLY (claim_eligible=false)")
        for field in (:coverage, :mcse_observed, :mcse_nominal, :mean_width)
            _h3_s10_same_float(getproperty(got, field), getproperty(wanted, field)) ||
                error("H3 S10 summary $(repr(key)) disagrees on $(field)")
        end
    end
    return nothing
end

const H3_S10_CAMPAIGNS = [:h3_rg, :h3_ram]
const H3_S10_SEED = 20260903
const H3_S10_LEVEL = 0.95

function h3_s10_smoke_config()
    return _parse_args([
        "--mode=smoke",
        "--reps=1",
        "--seed=$(H3_S10_SEED)",
        "--campaigns=h3_rg,h3_ram",
        "--levels=$(H3_S10_LEVEL)",
        "--resume=false",
    ])
end

function _h3_s10_require(condition::Bool, label::AbstractString)
    condition || error("H3 S10 smoke receipt rejected: $(label)")
    return nothing
end

function _h3_s10_is_interior_correlation(row)
    return isfinite(row.lower) && isfinite(row.upper) && isfinite(row.estimate) &&
           -1.0 < row.lower < row.upper < 1.0 && -1.0 < row.estimate < 1.0
end

function validate_h3_s10_smoke(detail_path::AbstractString, summary_path::AbstractString;
                               config = h3_s10_smoke_config())
    _h3_s10_require(config.mode === :smoke, "mode must be smoke")
    _h3_s10_require(config.reps == 1, "reps must equal one")
    _h3_s10_require(config.seed == H3_S10_SEED, "seed differs from the sealed smoke")
    _h3_s10_require(config.campaigns == H3_S10_CAMPAIGNS, "campaigns differ from H3-only smoke")
    _h3_s10_require(config.levels == [H3_S10_LEVEL], "level differs from the sealed smoke")

    records = _records_for_summary(_read_detail_records(detail_path), config)
    actual = _h3_s10_parse_summary(summary_path)
    _h3_s10_validate_summary_rows(actual, _summaries_from_records(records))
    _h3_s10_require(length(records) == 2, "expected exactly two retained detail rows")
    _h3_s10_require(length(actual) == 2, "expected exactly two reconciled summary rows")

    seen = Set{String}()
    for row in values(records)
        _h3_s10_require(row.campaign in ("h3_rg", "h3_ram"), "unexpected campaign $(row.campaign)")
        _h3_s10_require(row.estimand in ("r_g", "r_am"), "unexpected estimand $(row.estimand)")
        push!(seen, row.campaign)
        _h3_s10_require(row.fit_success, "$(row.campaign) fit failed: $(row.failure_reason)")
        _h3_s10_require(row.fit_converged, "$(row.campaign) fit did not converge: $(row.failure_reason)")
        _h3_s10_require(row.interval_success, "$(row.campaign) interval failed: $(row.failure_reason)")
        _h3_s10_require(_h3_s10_is_interior_correlation(row),
            "$(row.campaign) interval is not finite and strictly inside (-1, 1)")
    end
    _h3_s10_require(seen == Set(["h3_rg", "h3_ram"]), "H3 campaign set is incomplete")
    all(row -> row.claim_eligible === false, values(actual)) ||
        error("H3 S10 smoke output contains claim-eligible result")

    return (rows = length(records), summary_rows = length(actual), claim_eligible = false)
end

function h3_s10_self_test()
    cfg = h3_s10_smoke_config()
    entries = _canonical_task_inventory(cfg)
    mktempdir() do dir
        rows = [_detail_row(
            campaign = entry.campaign, cell_id = entry.cell_id, seed = entry.seed, rep = entry.rep,
            estimand = entry.estimand, method = entry.method, design = entry.cell_label,
            n_animals = 12, n_obs = 24, truth = -0.2, level = entry.level,
            scope = entry.scope, role = "covered_pillar_bank", fit_success = true,
            fit_converged = true, interval_success = true, failure_reason = "", covered = true,
            lower = -0.55, upper = 0.15, width = 0.70, estimate = -0.2,
            se = entry.method == "rg_fisher_z" ? NaN : 0.10,
        ) for entry in entries]
        detail = joinpath(dir, "detail.tsv")
        summary = joinpath(dir, "summary.tsv")
        _prepare_detail_output(detail; resume = false)
        _write_detail_rows!(detail, rows)
        _write_summary(summary, _summaries_from_records(_read_detail_records(detail)))
        validate_h3_s10_smoke(detail, summary; config = cfg)

        bad = replace(read(summary, String), "\tfalse\n" => "\ttrue\n"; count = 1)
        write(summary, bad)
        rejected = false
        try
            validate_h3_s10_smoke(detail, summary; config = cfg)
        catch err
            rejected = err isa ErrorException
        end
        rejected || error("H3 S10 mutation unexpectedly accepted claim eligibility")
    end
    return nothing
end

function main(args = ARGS)
    if args == ["--self-test"]
        h3_s10_self_test()
        println("H3_S10_SMOKE_INFRA_TESTS_OK")
        println("H3_S10_SMOKE_INFRA_MUTATION_CONTROLS_OK")
    elseif length(args) == 3 && args[1] == "--validate"
        result = validate_h3_s10_smoke(args[2], args[3])
        println("H3_S10_SMOKE_RECEIPT_OK rows=$(result.rows) summary_rows=$(result.summary_rows) claim_eligible=false")
    else
        error("usage: --self-test | --validate DETAIL.tsv SUMMARY.tsv; this tool never starts compute")
    end
    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
