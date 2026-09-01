#!/usr/bin/env julia
# comparator/run_targets.jl — A11 skeleton: validate-only harness over 7 targets.
#
# Reads test/fixtures/comparator_targets.toml, runs per-target validate-only
# adapters, and writes comparator/results/manifest.json with explicit statuses.
#
# Usage (from repo root):
#   julia comparator/run_targets.jl
#   julia comparator/run_targets.jl --validate-only
#
# Claim boundary: validate-only mode does not run external comparators or promote
# any validation-status row. It accounts for all 7 targets with 0 silent skips.

using Dates
using TOML

include(joinpath(@__DIR__, "prepare_blupf90_multitrait.jl"))
using .HSquaredBLUPF90MultitraitPacket

const ROOT = normpath(joinpath(@__DIR__, ".."))
const TARGETS_TOML = joinpath(ROOT, "test", "fixtures", "comparator_targets.toml")
const RESULTS_DIR = joinpath(@__DIR__, "results")
const MANIFEST_PATH = joinpath(RESULTS_DIR, "manifest.json")
const R_FIXTURES = normpath(joinpath(ROOT, "..", "hsquared-h2-twin-20260901", "tests", "testthat", "fixtures"))

function parse_cli(args)
    validate_only = true
    for arg in args
        arg == "--validate-only" && continue
        arg == "--run" && (validate_only = false; continue)
        error("unknown argument: $arg (supported: --validate-only, --run)")
    end
    return (; validate_only)
end

function validate_fixture_files(target)
    fixture_dir = joinpath(ROOT, "test", "fixtures", target["fixture"])
    isdir(fixture_dir) || return (status = "gap", detail = "fixture directory missing: $fixture_dir")
    for file in target["required_files"]
        path = joinpath(fixture_dir, file)
        isfile(path) || return (status = "gap", detail = "missing required file: $file")
    end
    return (status = "validated", detail = "fixture files present")
end

function adapter_animal_model_fitted_target(target)
    result = validate_fixture_files(target)
    result.status == "validated" || return result
    return (status = "validated", detail = "fixture validated; same-estimand REML comparator open")
end

function adapter_sire_model_fitted_target(target)
    result = validate_fixture_files(target)
    result.status == "validated" || return result
    r_mirror = joinpath(R_FIXTURES, target["fixture"])
    isdir(r_mirror) || return (
        status = "gap",
        detail = "Julia fixture validated; R fixture mirror missing at $r_mirror",
    )
    return (status = "validated", detail = "Julia fixture validated; R mirror present")
end

function adapter_phase4_multitrait_parity(target)
    result = validate_fixture_files(target)
    result.status == "validated" || return result
    generate_blupf90_multitrait_packet()
    executables = probe_blupf90_executables(("renumf90", "airemlf90", "blupf90"))
    missing = [name for name in ("renumf90", "airemlf90", "blupf90") if isnothing(executables[name])]
    isempty(missing) && return (
        status = "validated",
        detail = "fixture + BLUPF90 packet validated; executables present (opt-in run not executed)",
    )
    return (
        status = "unavailable",
        detail = "fixture + BLUPF90 packet validated; executables missing: $(join(missing, ", "))",
        blupf90 = "unavailable",
        unavailability_note = "docs/dev-log/comparator-runs/2026-09-01-blupf90-tool-unavailability.md",
    )
end

function adapter_genomic_gblup_snpblup_target(target)
    result = validate_fixture_files(target)
    result.status == "validated" || return result
    return (
        status = "validated",
        detail = "fixture validated; internal R consumer only; external genomic comparator open",
    )
end

function adapter_marker_scan_parity(target)
    result = validate_fixture_files(target)
    result.status == "validated" || return result
    return (
        status = "blocked",
        detail = "bridge payload validated; threshold/calibration tooling blocked per PR #83",
    )
end

function adapter_structured_covariance_parity(target)
    result = validate_fixture_files(target)
    result.status == "validated" || return result
    return (
        status = "validated",
        detail = "diagonal bridge payload validated; lowrank/FA blocked pending rotation convention",
    )
end

function adapter_non_gaussian_parity(target)
    result = validate_fixture_files(target)
    result.status == "validated" || return result
    return (
        status = "validated",
        detail = "bridge payload validated; external same-estimand comparator open",
    )
end

const ADAPTERS = Dict(
    "animal_model_fitted_target" => adapter_animal_model_fitted_target,
    "sire_model_fitted_target" => adapter_sire_model_fitted_target,
    "phase4_multitrait_parity" => adapter_phase4_multitrait_parity,
    "genomic_gblup_snpblup_target" => adapter_genomic_gblup_snpblup_target,
    "marker_scan_parity" => adapter_marker_scan_parity,
    "structured_covariance_parity" => adapter_structured_covariance_parity,
    "non_gaussian_parity" => adapter_non_gaussian_parity,
)

function json_string(s)
    replace(string(s), "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n", "\r" => "\\r", "\t" => "\\t")
end

function write_manifest(entries; mode, git_sha = nothing)
    mkpath(RESULTS_DIR)
    open(MANIFEST_PATH, "w") do io
        println(io, "{")
        println(io, "  \"schema_version\": 1,")
        println(io, "  \"generated_at\": \"$(Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS"))\",")
        println(io, "  \"mode\": \"$(json_string(mode))\",")
        git_sha === nothing || println(io, "  \"git_sha\": \"$(json_string(git_sha))\",")
        println(io, "  \"claim_boundary\": \"validate-only harness index; not comparator evidence\",")
        println(io, "  \"targets\": [")
        for (i, entry) in enumerate(entries)
            comma = i == length(entries) ? "" : ","
            println(io, "    {")
            println(io, "      \"id\": \"$(json_string(entry.id))\",")
            println(io, "      \"issue\": $(entry.issue),")
            println(io, "      \"status\": \"$(json_string(entry.status))\",")
            println(io, "      \"detail\": \"$(json_string(entry.detail))\"")
            if entry.blupf90 !== nothing
                println(io, "      ,\"blupf90\": \"$(json_string(entry.blupf90))\"")
            end
            if entry.unavailability_note !== nothing
                println(io, "      ,\"unavailability_note\": \"$(json_string(entry.unavailability_note))\"")
            end
            println(io, "    }$comma")
        end
        println(io, "  ],")
        statuses = [entry.status for entry in entries]
        println(io, "  \"summary\": {")
        println(io, "    \"target_count\": $(length(entries)),")
        println(io, "    \"validated\": $(count(==("validated"), statuses)),")
        println(io, "    \"gap\": $(count(==("gap"), statuses)),")
        println(io, "    \"blocked\": $(count(==("blocked"), statuses)),")
        println(io, "    \"unavailable\": $(count(==("unavailable"), statuses))")
        println(io, "  }")
        println(io, "}")
    end
end

function git_head_sha()
    try
        read(`git -C $ROOT rev-parse --short HEAD`, String) |> strip
    catch
        nothing
    end
end

function run_harness(; validate_only = true)
    manifest = TOML.parsefile(TARGETS_TOML)
    targets = manifest["target"]
    entries = NamedTuple[]
    for target in targets
        id = target["id"]
        haskey(ADAPTERS, id) || error("no adapter registered for target `$id`")
        adapter = ADAPTERS[id]
        result = adapter(target)
        push!(entries, (
            id = id,
            issue = target["issue"],
            status = result.status,
            detail = result.detail,
            blupf90 = get(result, :blupf90, nothing),
            unavailability_note = get(result, :unavailability_note, nothing),
        ))
    end
    mode = validate_only ? "validate-only" : "run"
    write_manifest(entries; mode, git_sha = git_head_sha())
    println("Wrote $(MANIFEST_PATH)")
    for entry in entries
        extra = entry.blupf90 === nothing ? "" : " blupf90=$(entry.blupf90)"
        println("  $(entry.id): $(entry.status)$(extra)")
    end
    any(entry.status == "gap" for entry in entries) && @warn "one or more targets reported gap status"
    return entries
end

function main(args = ARGS)
    opts = parse_cli(args)
    entries = run_harness(; validate_only = opts.validate_only)
    allowed = Set(["validated", "gap", "blocked", "unavailable"])
    all(entry.status in allowed for entry in entries) || error("invalid status emitted")
    length(entries) == 7 || error("expected 7 targets, got $(length(entries))")
    return entries
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
