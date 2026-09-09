# Retained S11 campaign for the ratified identified H1-two geometry.
#
# This is deliberately separate from `h1two_identified_calibration.jl`: S10 is
# one fixed-seed path fixture, whereas S11 varies only the predeclared fresh
# seed block and retains both successful and failed ratio rows.  It does not
# decide calibration or promote any public capability.

include(joinpath(@__DIR__, "h1two_identified_calibration.jl"))

const H1T_S11_ID = "HSQ09-H1T-IDENTIFIED-S11-01"
const H1T_S11_SEED_START = 202609100001
const H1T_S11_REPS = 2000
const H1T_S11_SEED_STOP = H1T_S11_SEED_START + H1T_S11_REPS - 1
const H1T_S11_RECEIPT_COLUMNS = (
    "campaign", "seed", "estimand", "truth", "level", "fit_success",
    "fit_converged", "interval_success", "failure_reason", "covered",
    "estimate", "lower", "upper", "se", "boundary", "claim_eligible",
)

_h1t_s11_truth(name::AbstractString) = name == "ratio1" ?
    H1T_TRUTH.sigma1 / (H1T_TRUTH.sigma1 + H1T_TRUTH.sigma2 + H1T_TRUTH.sigma_e2) :
    H1T_TRUTH.sigma2 / (H1T_TRUTH.sigma1 + H1T_TRUTH.sigma2 + H1T_TRUTH.sigma_e2)

function _h1t_s11_failure_reason(err)
    text = sprint(showerror, err)
    return replace(text, '\t' => ' ', '\n' => ' ')
end

function _h1t_s11_data(seed::Integer)
    rng = MersenneTwister(seed)
    sire = zeros(Int, H1T_SIRES + H1T_OFFSPRING)
    for i in 1:H1T_OFFSPRING
        sire[H1T_SIRES + i] = rand(rng, 1:H1T_SIRES)
    end
    Ainv = pedigree_inverse(collect(1:(H1T_SIRES + H1T_OFFSPRING)), sire,
                            zeros(Int, H1T_SIRES + H1T_OFFSPRING))
    A = inv(Symmetric(Matrix(Ainv)))
    n_animals = size(A, 1)
    genetic = cholesky(Symmetric(A + 1e-8I)).L * randn(rng, n_animals)
    group_effect = randn(rng, H1T_GROUPS) .* sqrt(H1T_TRUTH.sigma2)
    records = (H1T_SIRES + 1):(H1T_SIRES + H1T_OFFSPRING)
    n = length(records)
    X = ones(n, 1)
    Z1 = zeros(n, n_animals)
    Z2 = zeros(n, H1T_GROUPS)
    y = zeros(n)
    for (row, animal) in enumerate(records)
        Z1[row, animal] = 1.0
        group = rand(rng, 1:H1T_GROUPS)  # intentionally independent of pedigree
        Z2[row, group] = 1.0
        y[row] = 3.0 + genetic[animal] + group_effect[group] + randn(rng)
    end
    return y, X, sparse(Z1), Ainv, sparse(Z2), sparse(Matrix(1.0I, H1T_GROUPS, H1T_GROUPS))
end

function _h1t_s11_row(seed::Integer, name::String, interval, fit_success::Bool,
                      fit_converged::Bool, failure_reason::String)
    truth = _h1t_s11_truth(name)
    valid = fit_success && fit_converged && !interval.boundary &&
            isfinite(interval.estimate) && isfinite(interval.lower) &&
            isfinite(interval.upper) && isfinite(interval.se) &&
            0 < interval.lower < interval.upper < 1
    reason = valid ? "" : (isempty(failure_reason) ? "invalid_or_boundary_interval" : failure_reason)
    return (
        campaign = H1T_S11_ID,
        seed = seed,
        estimand = name,
        truth = truth,
        level = H1T_LEVEL,
        fit_success = fit_success,
        fit_converged = fit_converged,
        interval_success = valid,
        failure_reason = reason,
        covered = valid && interval.lower <= truth <= interval.upper,
        estimate = valid ? interval.estimate : NaN,
        lower = valid ? interval.lower : NaN,
        upper = valid ? interval.upper : NaN,
        se = valid ? interval.se : NaN,
        boundary = valid ? interval.boundary : true,
        claim_eligible = false,
    )
end

function _h1t_s11_failed_rows(seed::Integer, reason::String)
    na_interval = (estimate = NaN, lower = NaN, upper = NaN, se = NaN, boundary = true)
    return [_h1t_s11_row(seed, name, na_interval, false, false, reason)
            for name in ("ratio1", "ratio2")]
end

"""Run one predeclared fresh seed and return both retained ratio rows."""
function h1two_identified_campaign_rep(seed::Integer)
    H1T_S11_SEED_START <= seed <= H1T_S11_SEED_STOP ||
        throw(ArgumentError("seed must be in the frozen S11 range $(H1T_S11_SEED_START):$(H1T_S11_SEED_STOP)"))
    try
        y, X, Z1, Ainv1, Z2, Ainv2 = _h1t_s11_data(seed)
        interval = two_effect_ratio_interval(y, X, Z1, Ainv1, Z2, Ainv2; level = H1T_LEVEL)
        return [_h1t_s11_row(seed, "ratio1", interval.ratio1, true, interval.converged, ""),
                _h1t_s11_row(seed, "ratio2", interval.ratio2, true, interval.converged, "")]
    catch err
        return _h1t_s11_failed_rows(seed, _h1t_s11_failure_reason(err))
    end
end

function _h1t_s11_write_row(io, row)
    values = (row.campaign, row.seed, row.estimand, row.truth, row.level,
              row.fit_success, row.fit_converged, row.interval_success,
              row.failure_reason, row.covered, row.estimate, row.lower,
              row.upper, row.se, row.boundary, row.claim_eligible)
    println(io, join(values, '\t'))
end

"""Write one unique receipt atomically; existing retained receipts are never overwritten."""
function write_h1two_identified_campaign_receipt(path::AbstractString; seed::Integer)
    ispath(path) && throw(ArgumentError("refusing to overwrite retained receipt: $(path)"))
    mkpath(dirname(path))
    tmp = tempname(dirname(path))
    try
        open(tmp, "w") do io
            println(io, join(H1T_S11_RECEIPT_COLUMNS, '\t'))
            for row in h1two_identified_campaign_rep(seed)
                _h1t_s11_write_row(io, row)
            end
        end
        mv(tmp, path)
    finally
        ispath(tmp) && rm(tmp; force = true)
    end
    return path
end

function _h1t_s11_cli()
    seed_args = filter(arg -> startswith(arg, "--seed="), ARGS)
    out_args = filter(arg -> startswith(arg, "--out="), ARGS)
    length(seed_args) == 1 || error("supply exactly one --seed=INTEGER")
    length(out_args) == 1 || error("supply exactly one --out=PATH")
    length(ARGS) == 2 || error("only --seed=INTEGER and --out=PATH are supported")
    seed = parse(Int, split(only(seed_args), "="; limit = 2)[2])
    out = split(only(out_args), "="; limit = 2)[2]
    path = write_h1two_identified_campaign_receipt(out; seed = seed)
    println("H1T_IDENTIFIED_S11_RETAINED seed=$(seed) path=$(path) claim_eligible=false")
end

if abspath(PROGRAM_FILE) == @__FILE__
    _h1t_s11_cli()
end
