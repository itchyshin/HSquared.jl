#!/usr/bin/env julia
#
# C1 univariate interval-coverage RE-RUN driver (bootstrap arm ON, n_boot=199).
#
# NEW driver — does NOT mutate sim/phase1_small_sample_interval_calibration.jl.
# It `include`s that harness READ-ONLY (so method labels, seed formula, and the
# replicate/summary schema stay byte-identical) and calls its `main` with the
# FROZEN, pre-registered C1 re-run grid. Only per-task knobs are configurable, so
# the scientific grid cannot drift task-to-task and pooling stays clean.
#
# Pre-registration (frozen below; committed BEFORE any sbatch, R4 discipline):
#   designs = tiny:4:8:24 (q=36), small:8:16:96 (q=120)   -- the small-sample n-ladder
#   h2      = 0.1, 0.3, 0.5, 0.7    -- 0.1 is the h2->0 boundary rung (null-approaching;
#                                      literal h2=0 is rejected upstream by main(), and the
#                                      delta/heritability estimand is degenerate at sigma_a2=0)
#   levels  = 0.9, 0.95   -- 0.90 is DESCRIPTIVE-ONLY per the pre-registration (doc 34); the
#                            summary keeps the `level` column so 0.95 and 0.90 stay separable
#                            at adjudication.
#   nboot   = 199   (bootstrap arm ON)  ;  bootstrap = true
#   estimators emitted per estimand (BOTH h2 AND sigma_a2):
#       delta        -> *_delta_z
#       profile      -> *_profile_chisq
#       bootstrap    -> *_bootstrap_percentile
#       satterthwaite-> sigma_a2_satterthwaite_chisq_probe   (sigma_a2-only)
#     (the two t-df probes *_delta_t_{residual,family}_df_probe ride along as
#      CHARACTERIZATION-ONLY columns; they are the committed schema, never a claim.)
#
# SEED DISCIPLINE (the fix vs the prior array). The harness rep seed is
#     config.seed + 1_000_003*design_index + 10_007*h2_index + rep
# so WITHIN a cell (design_index, h2_index fixed) tasks differ ONLY by config.seed.
# If per-task master seeds are spaced <= --reps, the tasks' rep streams OVERLAP:
# with the prior `base + task` spacing (1), 20 tasks x 100 reps collapsed to ~119
# DISTINCT datasets/cell (20 x 50 -> ~69), silently duplicating datasets and
# understating MCSE ~4x. That fixes the WITHIN-cell distinctness but is not enough:
# a stride that ALIASES with the harness offset constants makes the SAME rep_seed
# value land in DIFFERENT cells (cross-cell dataset sharing). At stride=1000,
# 10_007 = 10*1000 + 7, so task t in one h2 cell shares 93/100 datasets with task
# t-10 in the ADJACENT h2 cell (verified: 5580 shared seeds, 10420/16000 distinct
# across the grid). The sbatch therefore uses STRIDE=40_009, which is coprime to
# both 10_007 and 1_000_003 AND keeps every h2 offset (<=30_021) below one stride
# and every design offset (~1e6) beyond 19 strides -> 0 cross-cell sharing,
# 16000/16000 distinct, a true 2000 DISTINCT rep_seeds per cell (95% coverage MCSE
# ~ sqrt(0.95*0.05/2000) ~ 0.0049, as pre-registered).
#
# This driver enforces the coupling defensively: it refuses --reps >= the sbatch's
# documented seed stride, so a stray reps bump cannot re-open the within-cell overlap.
#
# POST-RUN ANNOTATION (this driver, after main() returns; harness untouched). The
# harness summary already carries RAW COUNTS per cell (reps, fit_success,
# interval_success, covered) so downstream pooling is
#     coverage = sum(covered)/sum(interval_success),
#     MC-SE    = sqrt(c(1-c)/sum(interval_success)).
# On top of that this driver:
#   (1) RESTORES the non-interpretable convention: it appends a `non_interpretable`
#       column flagging any cell with interval_success < 0.9*reps (the prior C1
#       sbatch documented this convention; it is re-attached here IN the per-task
#       summary output so a downstream reader sees it without re-deriving it).
#   (2) Emits two greppable stdout lines the sbatch smoke gate keys on: a `diag`
#       line (grid totals) and a `probe` line (the interior sanity cell
#       h2/h2_delta_z/small/h2=0.5/level=0.95). These make the smoke gate
#       FAILURE-SENSITIVE (an all-fit-fail run has total interval_success = 0).

include(joinpath(@__DIR__, "phase1_small_sample_interval_calibration.jl"))

# ---- Frozen pre-registration -------------------------------------------------
const C1_RERUN_DESIGNS     = "tiny:4:8:24,small:8:16:96"
const C1_RERUN_H2          = "0.1,0.3,0.5,0.7"
const C1_RERUN_LEVELS      = "0.9,0.95"
const C1_RERUN_NBOOT       = "199"
const C1_RERUN_SEED_STRIDE = 40_009                    # MUST match the sbatch task-seed spacing
const C1_RERUN_ALLOWED     = ("seed", "reps", "out", "detail-out", "resume")

# Interior sanity cell the smoke gate keys on. Best-case leg: interior h2, largest
# design (small = 8+16+96 = 120 animals = q=120), shipped delta interval, 95% level.
# A correctly-wired run covers ~nominally here; a gross wiring bug (truth mismatch,
# crossed interval) or an all-fit-fail run drives coverage to ~0 / interval_success 0.
const C1_PROBE_TARGET = "h2"
const C1_PROBE_METHOD = "h2_delta_z"
const C1_PROBE_DESIGN = "small"
const C1_PROBE_H2     = 0.5
const C1_PROBE_LEVEL  = 0.95

# Non-interpretable convention (restored): a cell is NON_INTERPRETABLE when fewer
# than 90% of its replicates produced a usable interval.
const C1_INTERPRETABLE_FRACTION = 0.9

function _c1_rerun_usage()
    return """
    C1 univariate interval-coverage RE-RUN (bootstrap ON, n_boot=199, 2000 reps/cell target).

    FROZEN grid (NOT overridable): designs=$(C1_RERUN_DESIGNS)  h2=$(C1_RERUN_H2)
                                   levels=$(C1_RERUN_LEVELS)  nboot=$(C1_RERUN_NBOOT)  bootstrap=true

    Per-task options (the ONLY accepted flags):
      --seed=N          REQUIRED. Master seed for THIS task. Tasks MUST be spaced by
                        more than --reps (see header); the sbatch uses stride $(C1_RERUN_SEED_STRIDE).
      --reps=N          Replicates for THIS task (default 100; 20 tasks x 100 = 2000/cell).
                        Must be < $(C1_RERUN_SEED_STRIDE) so task rep-streams stay disjoint.
      --out=PATH        REQUIRED. Per-task summary TSV (a NEW file; never a committed TSV).
                        On return this file gains a `non_interpretable` column.
      --detail-out=PATH Per-task resumable replicate TSV (default: OUT with -replicates.tsv).
      --resume=BOOL     Reuse THIS task's completed replicate rows (default true).
    """
end

function _c1_rerun_parse(args)
    opts = Dict{String,String}()
    for arg in args
        (arg == "-h" || arg == "--help") && (print(_c1_rerun_usage()); exit(0))
        startswith(arg, "--") || error("unexpected argument $(arg)\n" * _c1_rerun_usage())
        kv = split(arg[3:end], "=", limit = 2)
        length(kv) == 2 || error("expected --key=value, got $(arg)")
        key = String(kv[1])
        key in C1_RERUN_ALLOWED || error(
            "flag --$(key) is not accepted: the C1 re-run grid is FROZEN " *
            "(designs/h2/levels/nboot/bootstrap are fixed in this driver).\n" *
            _c1_rerun_usage(),
        )
        opts[key] = String(kv[2])
    end
    haskey(opts, "seed") ||
        error("--seed is REQUIRED (per-task master seed).\n" * _c1_rerun_usage())
    haskey(opts, "out") ||
        error("--out is REQUIRED (per-task NEW summary TSV).\n" * _c1_rerun_usage())
    reps = parse(Int, get(opts, "reps", "100"))
    reps > 0 || error("--reps must be positive")
    reps < C1_RERUN_SEED_STRIDE || error(
        "--reps=$(reps) must be < the seed stride ($(C1_RERUN_SEED_STRIDE)); larger reps " *
        "would overlap task rep-streams (see the SEED DISCIPLINE note in this driver).",
    )
    return opts
end

# ---- Post-run summary annotation + smoke-gate probe --------------------------

# Split a TSV line, keeping empty trailing fields (matches the harness writer).
_c1_split_tsv(line::AbstractString) = split(line, '\t'; keepempty = true)

# Read the summary the harness just wrote, append a `non_interpretable` column,
# rewrite the file ATOMICALLY (temp + rename), and emit the diag + probe stdout
# lines the sbatch smoke gate greps. Returns nothing; never raises on a benign
# empty file (the sbatch asserts on file contents independently).
function _c1_rerun_annotate_and_probe(summary_path::AbstractString)
    isfile(summary_path) || (println("C1-RERUN diag: ERROR summary_missing path=$(summary_path)"); return nothing)
    lines = readlines(summary_path)
    isempty(lines) && (println("C1-RERUN diag: ERROR summary_empty path=$(summary_path)"); return nothing)

    header = _c1_split_tsv(lines[1])
    colidx = Dict{String,Int}(String(name) => i for (i, name) in enumerate(header))
    for required in ("reps", "interval_success", "covered", "target", "method", "design", "h2_true", "level", "n_animals")
        haskey(colidx, required) ||
            error("summary header missing required column `$(required)`: $(summary_path)")
    end
    i_reps, i_isucc, i_cov = colidx["reps"], colidx["interval_success"], colidx["covered"]
    i_tgt, i_mth, i_dsg = colidx["target"], colidx["method"], colidx["design"]
    i_h2, i_lvl, i_nan = colidx["h2_true"], colidx["level"], colidx["n_animals"]

    total_reps = 0
    total_isucc = 0
    total_cov = 0
    nonint_cells = 0
    data_cells = 0
    # probe accumulators (defaults => a missing probe row fails the sbatch gate)
    probe_found = false
    probe_reps = 0
    probe_isucc = 0
    probe_cov = 0
    probe_nanimals = "NA"

    out = IOBuffer()
    println(out, join(header, '\t') * "\tnon_interpretable")
    for line in lines[2:end]
        isempty(strip(line)) && continue
        parts = _c1_split_tsv(line)
        length(parts) == length(header) || error(
            "summary row has $(length(parts)) fields, expected $(length(header)): $(summary_path)",
        )
        reps = parse(Int, parts[i_reps])
        isucc = parse(Int, parts[i_isucc])
        cov = parse(Int, parts[i_cov])
        interpretable = isucc >= C1_INTERPRETABLE_FRACTION * reps
        flag = interpretable ? "ok" : "NON_INTERPRETABLE"
        println(out, line * "\t" * flag)

        total_reps += reps
        total_isucc += isucc
        total_cov += cov
        data_cells += 1
        interpretable || (nonint_cells += 1)

        if !probe_found &&
           String(parts[i_tgt]) == C1_PROBE_TARGET &&
           String(parts[i_mth]) == C1_PROBE_METHOD &&
           String(parts[i_dsg]) == C1_PROBE_DESIGN &&
           isapprox(parse(Float64, parts[i_h2]), C1_PROBE_H2; atol = 1e-9) &&
           isapprox(parse(Float64, parts[i_lvl]), C1_PROBE_LEVEL; atol = 1e-9)
            probe_found = true
            probe_reps = reps
            probe_isucc = isucc
            probe_cov = cov
            probe_nanimals = String(parts[i_nan])
        end
    end

    # Atomic rewrite so a crash mid-write can never leave a half-annotated summary.
    tmp = summary_path * ".tmp"
    open(tmp, "w") do io
        write(io, take!(out))
    end
    mv(tmp, summary_path; force = true)

    probe_coverage = probe_isucc > 0 ? probe_cov / probe_isucc : NaN

    # Greppable, single-line, space-separated key=value diagnostics for the sbatch gate.
    println(
        "C1-RERUN diag: data_cells=$(data_cells) total_reps=$(total_reps) ",
        "total_interval_success=$(total_isucc) total_covered=$(total_cov) ",
        "non_interpretable_cells=$(nonint_cells)",
    )
    println(
        "C1-RERUN probe: target=$(C1_PROBE_TARGET) method=$(C1_PROBE_METHOD) ",
        "design=$(C1_PROBE_DESIGN) n_animals=$(probe_nanimals) h2=$(C1_PROBE_H2) level=$(C1_PROBE_LEVEL) ",
        "found=$(probe_found ? 1 : 0) reps=$(probe_reps) interval_success=$(probe_isucc) ",
        "covered=$(probe_cov) coverage=$(isnan(probe_coverage) ? "NaN" : @sprintf("%.6f", probe_coverage))",
    )
    return nothing
end

function _c1_rerun_main(args = ARGS)
    opts = _c1_rerun_parse(args)
    summary_path = opts["out"]
    forwarded = String[
        "--designs=$(C1_RERUN_DESIGNS)",
        "--h2=$(C1_RERUN_H2)",
        "--levels=$(C1_RERUN_LEVELS)",
        "--nboot=$(C1_RERUN_NBOOT)",
        "--bootstrap=true",
        "--seed=$(opts["seed"])",
        "--reps=$(get(opts, "reps", "100"))",
        "--out=$(summary_path)",
        "--resume=$(get(opts, "resume", "true"))",
    ]
    haskey(opts, "detail-out") && push!(forwarded, "--detail-out=$(opts["detail-out"])")
    println("C1-RERUN driver -> harness args: ", join(forwarded, " "))
    result = main(forwarded)
    # Annotate + probe AFTER main() has fully written the summary (harness truncates
    # and rewrites config.output each run, so re-annotation is idempotent on resume).
    _c1_rerun_annotate_and_probe(summary_path)
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    _c1_rerun_main()
end
