using DelimitedFiles

include(joinpath(@__DIR__, "..", "sim", "h1two_identified_campaign.jl"))

const H1T_S11_ESTIMANDS = ("ratio1", "ratio2")

_h1t_s11_bool(value::AbstractString) = value == "true" ? true : value == "false" ? false :
    throw(ArgumentError("invalid Boolean field: $(value)"))

function _h1t_s11_parse_float(value::AbstractString)
    parsed = tryparse(Float64, value)
    parsed === nothing && throw(ArgumentError("invalid floating-point field: $(value)"))
    return parsed
end

function _h1t_s11_read_rows(dir::AbstractString)
    isdir(dir) || throw(ArgumentError("receipt directory does not exist: $(dir)"))
    paths = sort(filter(path -> endswith(path, ".tsv"), readdir(dir; join = true)))
    isempty(paths) && throw(ArgumentError("no retained TSV receipts in $(dir)"))
    rows = NamedTuple[]
    for path in paths
        lines = readlines(path)
        !isempty(lines) && lines[1] == join(H1T_S11_RECEIPT_COLUMNS, '\t') ||
            throw(ArgumentError("invalid receipt header: $(path)"))
        length(lines) == 3 || throw(ArgumentError("receipt must retain exactly two rows: $(path)"))
        for line in lines[2:end]
            fields = split(line, '\t'; keepempty = true)
            length(fields) == length(H1T_S11_RECEIPT_COLUMNS) ||
                throw(ArgumentError("wrong field count in $(path)"))
            push!(rows, (
                campaign = fields[1], seed = parse(Int, fields[2]), estimand = fields[3],
                truth = _h1t_s11_parse_float(fields[4]), level = _h1t_s11_parse_float(fields[5]),
                fit_success = _h1t_s11_bool(fields[6]), fit_converged = _h1t_s11_bool(fields[7]),
                interval_success = _h1t_s11_bool(fields[8]), failure_reason = fields[9],
                covered = _h1t_s11_bool(fields[10]), estimate = _h1t_s11_parse_float(fields[11]),
                lower = _h1t_s11_parse_float(fields[12]), upper = _h1t_s11_parse_float(fields[13]),
                se = _h1t_s11_parse_float(fields[14]), boundary = _h1t_s11_bool(fields[15]),
                claim_eligible = _h1t_s11_bool(fields[16]), path = path,
            ))
        end
    end
    return rows
end

function _h1t_s11_validate_row(row, expected_seeds::Set{Int})
    row.campaign == H1T_S11_ID || throw(ArgumentError("wrong campaign id in $(row.path)"))
    row.seed in expected_seeds || throw(ArgumentError("unexpected seed $(row.seed)"))
    row.estimand in H1T_S11_ESTIMANDS || throw(ArgumentError("unexpected estimand $(row.estimand)"))
    row.truth == _h1t_s11_truth(row.estimand) || throw(ArgumentError("wrong truth for $(row.estimand)"))
    row.level == H1T_LEVEL || throw(ArgumentError("wrong confidence level"))
    !row.claim_eligible || throw(ArgumentError("claim_eligible must remain false"))
    if row.interval_success
        row.fit_success && row.fit_converged || throw(ArgumentError("successful interval lacks converged fit"))
        isempty(row.failure_reason) || throw(ArgumentError("successful interval has failure reason"))
        !row.boundary || throw(ArgumentError("successful interval is boundary-flagged"))
        all(isfinite, (row.estimate, row.lower, row.upper, row.se)) ||
            throw(ArgumentError("successful interval has non-finite values"))
        0 < row.lower < row.upper < 1 || throw(ArgumentError("successful interval is not interior"))
        row.covered == (row.lower <= row.truth <= row.upper) ||
            throw(ArgumentError("coverage flag mismatches endpoints"))
    else
        !isempty(row.failure_reason) || throw(ArgumentError("retained failure has blank reason"))
        !row.covered || throw(ArgumentError("failed interval cannot be covered"))
        all(isnan, (row.estimate, row.lower, row.upper, row.se)) ||
            throw(ArgumentError("failed interval must retain NaN numeric fields"))
    end
end

"""Reconcile one receipt per selected seed and return the pooled, evidence-only summary."""
function reconcile_h1t_s11(dir::AbstractString;
                           seeds::Vector{Int} = collect(H1T_S11_SEED_START:H1T_S11_SEED_STOP))
    length(seeds) == length(unique(seeds)) || throw(ArgumentError("duplicate scheduled seeds"))
    expected_seeds = Set(seeds)
    rows = _h1t_s11_read_rows(dir)
    for row in rows
        _h1t_s11_validate_row(row, expected_seeds)
    end
    expected = Set((seed, estimand) for seed in seeds for estimand in H1T_S11_ESTIMANDS)
    observed = Set((row.seed, row.estimand) for row in rows)
    length(observed) == length(rows) || throw(ArgumentError("duplicate retained seed-estimand row"))
    observed == expected || throw(ArgumentError("retained rows do not match the frozen seed inventory"))
    successes = count(row -> row.interval_success, rows)
    covered = count(row -> row.interval_success && row.covered, rows)
    coverage = successes == 0 ? NaN : covered / successes
    return (
        requested_reps = length(seeds),
        expected_rows = length(expected),
        retained_rows = length(rows),
        fit_success = count(row -> row.fit_success, rows),
        fit_converged = count(row -> row.fit_converged, rows),
        interval_success = successes,
        interval_failure = length(rows) - successes,
        covered = covered,
        coverage = coverage,
        mcse = successes == 0 ? NaN : sqrt(coverage * (1 - coverage) / successes),
        claim_eligible = false,
    )
end

function _h1t_s11_cli()
    args = filter(arg -> startswith(arg, "--dir="), ARGS)
    length(args) == 1 && length(ARGS) == 1 || error("supply exactly one --dir=PATH")
    dir = split(only(args), "="; limit = 2)[2]
    summary = reconcile_h1t_s11(dir)
    println("H1T_S11_RECONCILE_OK requested=$(summary.requested_reps) rows=$(summary.retained_rows) interval_success=$(summary.interval_success) covered=$(summary.covered) coverage=$(summary.coverage) mcse=$(summary.mcse) claim_eligible=false")
end

if abspath(PROGRAM_FILE) == @__FILE__
    _h1t_s11_cli()
end
