#!/usr/bin/env julia
# comparator/run_targets.jl — A11: validate-only harness over the 7 comparator targets.
#
# Reads test/fixtures/comparator_targets.toml, validates each target's fixture
# (presence AND parseable, finite content), digests the fixture bytes, carries
# the TOML's honesty metadata through, and writes
# comparator/results/manifest.json.
#
# Usage (from repo root):
#   julia comparator/run_targets.jl                 # validate-only (default)
#   julia comparator/run_targets.jl --validate-only
#   julia comparator/run_targets.jl --strict        # nonzero exit if any gap
#   julia comparator/run_targets.jl --no-write      # print, do not write manifest
#
# Claim boundary: this harness runs NO external comparator and promotes NO
# validation-status row. It answers two questions honestly — is each fixture
# intact, and what evidence does each target actually have — and it accounts for
# all 7 targets with 0 silent skips. `--run` is deliberately refused: no external
# runner is wired into the unified harness (see comparator/README.md for the
# per-model opt-in runners).

using Dates
using SHA
using TOML

include(joinpath(@__DIR__, "prepare_blupf90_multitrait.jl"))
using .HSquaredBLUPF90MultitraitPacket

const ROOT = normpath(joinpath(@__DIR__, ".."))
const TARGETS_TOML = joinpath(ROOT, "test", "fixtures", "comparator_targets.toml")
const RESULTS_DIR = joinpath(@__DIR__, "results")
const MANIFEST_PATH = joinpath(RESULTS_DIR, "manifest.json")

const TARGET_COUNT = 7
const ALLOWED_STATUSES = ("validated", "gap", "blocked", "unavailable")

# An external same-estimand comparator is either absent, present as a single
# disclosed leg, or unavailable because the tool could not be obtained. No target
# currently reaches "complete"; the tier exists so the manifest can say that
# rather than imply it.
const EXTERNAL_TIER = Dict(
    "julia_target" => "none",
    "julia_target_r_consumed" => "none",
    "julia_target_external_one_leg" => "one_leg",
    "bridge_payload_fixture" => "none",
)

const BLUPF90_EXECUTABLES = ("renumf90", "airemlf90", "blupf90")

# --- CLI -------------------------------------------------------------------

function parse_cli(args)
    strict = false
    write_manifest_file = true
    for arg in args
        if arg == "--validate-only"
            continue
        elseif arg == "--strict"
            strict = true
        elseif arg == "--no-write"
            write_manifest_file = false
        elseif arg == "--run"
            error(
                "`--run` is refused: no external comparator runner is wired into the " *
                "unified harness. Use the per-model opt-in runners " *
                "(comparator/run_jwas_animal_model.jl, comparator/run_blupf90_multitrait.jl), " *
                "which gate on their own environment variables.",
            )
        else
            error("unknown argument: $arg (supported: --validate-only, --strict, --no-write)")
        end
    end
    return (; strict, write_manifest_file)
end

# --- fixture validation ----------------------------------------------------

"""
    validate_csv(path)

Return `nothing` when the CSV is well formed, or a string describing the first
defect. Checks a header, at least one data row, a constant column count, and
that every numeric-looking cell is finite. A fixture that has rotted into `NaN`
or a ragged row is a gap, not a validated target.
"""
function validate_csv(path)
    lines = filter(!isempty, strip.(readlines(path)))
    length(lines) >= 2 || return "fewer than 2 non-empty lines (header + data)"

    header = split(lines[1], ',')
    ncol = length(header)
    ncol >= 2 || return "header has $ncol column(s); expected at least 2"
    any(isempty, strip.(header)) && return "header has an empty column name"

    for (i, line) in enumerate(lines[2:end])
        cells = split(line, ',')
        length(cells) == ncol ||
            return "row $(i + 1) has $(length(cells)) cell(s); header has $ncol"
        for cell in cells
            value = tryparse(Float64, strip(cell))
            value === nothing && continue
            isfinite(value) || return "row $(i + 1) holds a non-finite value: $(strip(cell))"
        end
    end
    return nothing
end

file_digest(path) = bytes2hex(sha256(read(path)))

"""
    validate_fixture(target)

Presence plus content validation over a target's `required_files`, returning a
per-file digest table and a rollup digest over the sorted (name, digest) pairs.
"""
function validate_fixture(target)
    fixture_dir = joinpath(ROOT, "test", "fixtures", target["fixture"])
    isdir(fixture_dir) ||
        return (ok = false, detail = "fixture directory missing: $fixture_dir", digests = Pair{String,String}[], digest = "")

    digests = Pair{String,String}[]
    for file in target["required_files"]
        path = joinpath(fixture_dir, file)
        isfile(path) ||
            return (ok = false, detail = "missing required file: $file", digests = digests, digest = "")
        filesize(path) > 0 ||
            return (ok = false, detail = "required file is empty: $file", digests = digests, digest = "")

        if endswith(file, ".csv")
            defect = validate_csv(path)
            defect === nothing ||
                return (ok = false, detail = "malformed fixture CSV $file: $defect", digests = digests, digest = "")
        end
        push!(digests, file => file_digest(path))
    end

    sorted = sort(digests; by = first)
    rollup = bytes2hex(sha256(join(("$(k):$(v)" for (k, v) in sorted), "\n")))
    n = length(digests)
    return (
        ok = true,
        detail = "$n required file(s) present, parseable, and finite",
        digests = sorted,
        digest = rollup,
    )
end

# --- cross-lane mirror parity ----------------------------------------------
#
# The R twin mirrors these fixtures and freezes their bytes in
# tests/fixtures/comparator_fixture_shas.csv. Comparing that freeze against the
# Julia fixtures' own digests is a real cross-lane check that needs no external
# tool: if the two lanes have drifted, every downstream parity test is comparing
# different data and quietly agreeing about it.

"""
    resolve_r_lane()

Locate the `hsquared` R checkout, or `nothing`. `HSQUARED_R_ROOT` wins; otherwise
a sibling `hsquared` directory, then any sibling `hsquared-*` worktree. The
sibling name must not be hard-coded to one lane's worktree — that reads as a
mirror gap when it is only a path miss.
"""
function resolve_r_lane()
    if haskey(ENV, "HSQUARED_R_ROOT")
        root = ENV["HSQUARED_R_ROOT"]
        return isdir(joinpath(root, "tests", "testthat")) ? root : nothing
    end
    parent = normpath(joinpath(ROOT, ".."))
    isdir(parent) || return nothing
    candidates = String[joinpath(parent, "hsquared")]
    for entry in sort(readdir(parent))
        startswith(entry, "hsquared-") && push!(candidates, joinpath(parent, entry))
    end
    for candidate in candidates
        isdir(joinpath(candidate, "tests", "testthat")) && return candidate
    end
    return nothing
end

const R_LANE = resolve_r_lane()

function r_frozen_digests(r_lane)
    path = joinpath(r_lane, "tests", "fixtures", "comparator_fixture_shas.csv")
    isfile(path) || return nothing
    frozen = Dict{String,Dict{String,String}}()
    lines = filter(!isempty, strip.(readlines(path)))
    for line in lines[2:end]
        cells = split(line, ',')
        length(cells) == 3 || continue
        target, file, sha = strip.(cells)
        get!(frozen, target, Dict{String,String}())[file] = sha
    end
    return frozen
end

const R_FROZEN = R_LANE === nothing ? nothing : r_frozen_digests(R_LANE)

"""
    check_r_mirror(target, fixture)

Compare the Julia fixture digests against the R lane's frozen SHA-256 table.
Returns `(state, detail)` where `state` is one of `"agree"`, `"drift"`,
`"absent"`, or `"uncheckable"` — the last meaning the R checkout or its freeze
file was not found, which is not evidence either way.
"""
function check_r_mirror(target, fixture)
    R_LANE === nothing && return ("uncheckable", "R lane checkout not found (set HSQUARED_R_ROOT)")
    R_FROZEN === nothing &&
        return ("uncheckable", "R lane found but tests/fixtures/comparator_fixture_shas.csv is missing")

    frozen = get(R_FROZEN, target["fixture"], nothing)
    frozen === nothing && return ("absent", "R lane freezes no bytes for this fixture")

    ours = Dict(fixture.digests)
    shared = sort(collect(intersect(keys(ours), keys(frozen))))
    isempty(shared) &&
        return ("absent", "R lane freeze names no file this fixture requires")

    drifted = [file for file in shared if ours[file] != frozen[file]]
    isempty(drifted) ||
        return ("drift", "cross-lane byte drift on: $(join(drifted, ", "))")
    return ("agree", "$(length(shared)) mirrored file(s) byte-identical to the R lane freeze")
end

# --- per-target adapters ---------------------------------------------------
#
# Each adapter starts from the shared fixture validation and then adds only what
# is specific to that target: a cross-lane mirror check, an executable probe, or
# a known blocker. None of them run an external comparator.

function adapter_animal_model_fitted_target(target, fixture)
    return (status = "validated", detail = "$(fixture.detail); same-estimand REML fitted-output comparator open")
end

function adapter_sire_model_fitted_target(target, fixture)
    # The sire target is the one target the R lane has never mirrored, so an
    # absent mirror is a tracked gap here rather than a neutral observation.
    #
    # The boundary is DOCUMENTED as of 2026-09-01 (see `boundary_note` below), and the verdict
    # stays `gap` anyway. Documenting a boundary and discharging a debt are different acts:
    # reporting `validated` here would assert cross-lane agreement nobody has measured, and
    # `--strict` should still refuse. Whether to build the mirror or make the Julia-only
    # boundary permanent is an open owner decision, not the harness's to assume.
    state, detail = check_r_mirror(target, fixture)
    state == "absent" && return (
        status = "gap",
        detail = "$(fixture.detail); R lane has not mirrored this fixture ($detail) — " *
                 "DOCUMENTED Julia-only boundary, not a silent gap",
        boundary_note = "docs/dev-log/comparator-runs/2026-09-01-sire-julia-only-boundary.md",
    )
    return (
        status = "validated",
        detail = "$(fixture.detail); same-estimand REML sire comparator open",
    )
end

function adapter_phase4_multitrait_parity(target, fixture)
    generate_blupf90_multitrait_packet()
    executables = probe_blupf90_executables(BLUPF90_EXECUTABLES)
    absent = [name for name in BLUPF90_EXECUTABLES if isnothing(executables[name])]
    isempty(absent) && return (
        status = "validated",
        detail = "$(fixture.detail); BLUPF90 packet built; executables present (opt-in run NOT executed)",
        blupf90 = "present",
    )
    return (
        status = "unavailable",
        detail = "$(fixture.detail); BLUPF90 packet built; executables missing: $(join(absent, ", "))",
        blupf90 = "unavailable",
        unavailability_note = "docs/dev-log/comparator-runs/2026-09-01-blupf90-tool-unavailability.md",
    )
end

function adapter_genomic_gblup_snpblup_target(target, fixture)
    return (
        status = "validated",
        detail = "$(fixture.detail); R internal consumer only; external genomic comparator open",
    )
end

function adapter_marker_scan_parity(target, fixture)
    return (
        status = "blocked",
        detail = "$(fixture.detail); threshold/calibration tooling blocked per hsquared PR #83",
    )
end

function adapter_structured_covariance_parity(target, fixture)
    return (
        status = "validated",
        detail = "$(fixture.detail); diagonal payload only; lowrank/FA blocked pending rotation convention",
    )
end

function adapter_non_gaussian_parity(target, fixture)
    return (
        status = "validated",
        detail = "$(fixture.detail); external same-estimand comparator open",
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

# --- JSON emitter (stdlib only) --------------------------------------------

json_escape(s) =
    replace(string(s), "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n", "\r" => "\\r", "\t" => "\\t")

json_value(x::AbstractString) = "\"$(json_escape(x))\""
json_value(x::Integer) = string(x)
json_value(x::Bool) = x ? "true" : "false"
json_value(::Nothing) = "null"
json_value(x::AbstractVector) = "[" * join(json_value.(x), ", ") * "]"

"""
    json_object(pairs; indent)

Emit an object from ordered `name => value` pairs, dropping `nothing` values so
an absent field is absent rather than `null`. Nested objects are passed in
pre-rendered as strings via `RawJSON`.
"""
struct RawJSON
    text::String
end
json_value(x::RawJSON) = x.text

function json_object(pairs::Vector{<:Pair}; indent::Int = 0)
    pad = " "^indent
    inner = " "^(indent + 2)
    kept = [p for p in pairs if last(p) !== nothing]
    isempty(kept) && return "{}"
    body = join(("$(inner)\"$(json_escape(first(p)))\": $(json_value(last(p)))" for p in kept), ",\n")
    return "{\n$body\n$pad}"
end

function target_json(entry; indent)
    digest_pairs = Pair{String,Any}[file => digest for (file, digest) in entry.file_digests]
    pairs = Pair{String,Any}[
        "id" => entry.id,
        "issue" => entry.issue,
        "status" => entry.status,
        "capability_rows" => entry.capability_rows,
        "evidence_type" => entry.evidence_type,
        "external_comparator" => entry.external_comparator,
        "required_comparator" => entry.required_comparator,
        "fixture_digest" => isempty(entry.fixture_digest) ? nothing : entry.fixture_digest,
        "r_mirror" => entry.r_mirror,
        "r_mirror_detail" => entry.r_mirror_detail,
        "detail" => entry.detail,
        "boundary" => entry.boundary,
        "blupf90" => entry.blupf90,
        "unavailability_note" => entry.unavailability_note,
        "boundary_note" => entry.boundary_note,
        "file_digests" => isempty(digest_pairs) ? nothing :
                          RawJSON(json_object(digest_pairs; indent = indent + 2)),
    ]
    return json_object(pairs; indent)
end

function summary_json(entries; indent)
    statuses = [entry.status for entry in entries]
    tiers = [entry.external_comparator for entry in entries]
    mirrors = [entry.r_mirror for entry in entries]
    pairs = Pair{String,Any}[
        "target_count" => length(entries),
        "validated" => count(==("validated"), statuses),
        "gap" => count(==("gap"), statuses),
        "blocked" => count(==("blocked"), statuses),
        "unavailable" => count(==("unavailable"), statuses),
        "external_comparator_complete" => count(==("complete"), tiers),
        "external_comparator_one_leg" => count(==("one_leg"), tiers),
        "external_comparator_none" => count(==("none"), tiers),
        "r_mirror_agree" => count(==("agree"), mirrors),
        "r_mirror_drift" => count(==("drift"), mirrors),
        "r_mirror_absent" => count(==("absent"), mirrors),
        "r_mirror_uncheckable" => count(==("uncheckable"), mirrors),
    ]
    return json_object(pairs; indent)
end

function render_manifest(entries; mode, git_sha)
    target_bodies = join((target_json(e; indent = 4) for e in entries), ",\n    ")
    pairs = Pair{String,Any}[
        "schema_version" => 2,
        "generated_at" => Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS"),
        "mode" => mode,
        "git_sha" => git_sha,
        "claim_boundary" =>
            "Validate-only fixture-integrity and evidence index. NOT comparator evidence: " *
            "no external comparator was run and no validation-status row is promoted.",
        "targets" => RawJSON("[\n    $target_bodies\n  ]"),
        "summary" => RawJSON(summary_json(entries; indent = 2)),
    ]
    return json_object(pairs; indent = 0) * "\n"
end

# --- harness ---------------------------------------------------------------

function git_head_sha()
    try
        strip(read(`git -C $ROOT rev-parse --short HEAD`, String))
    catch
        nothing
    end
end

function run_harness(; write_manifest_file::Bool = true, verbose::Bool = true)
    manifest = TOML.parsefile(TARGETS_TOML)
    targets = manifest["target"]
    entries = NamedTuple[]

    for target in targets
        id = target["id"]
        haskey(ADAPTERS, id) || error("no adapter registered for target `$id`")

        fixture = validate_fixture(target)
        evidence_type = target["evidence_type"]
        haskey(EXTERNAL_TIER, evidence_type) ||
            error("unclassified evidence_type `$evidence_type` for target `$id`")

        mirror_state, mirror_detail =
            fixture.ok ? check_r_mirror(target, fixture) : ("uncheckable", "fixture did not validate")

        result = if !fixture.ok
            (status = "gap", detail = fixture.detail)
        elseif mirror_state == "drift"
            # Two lanes comparing different bytes will agree about the wrong
            # thing, so drift outranks whatever the adapter would have said.
            (status = "gap", detail = "$(fixture.detail); $mirror_detail")
        else
            ADAPTERS[id](target, fixture)
        end

        push!(
            entries,
            (
                id = id,
                issue = target["issue"],
                status = result.status,
                detail = result.detail,
                r_mirror = mirror_state,
                r_mirror_detail = mirror_detail,
                capability_rows = String.(target["capability_rows"]),
                evidence_type = evidence_type,
                external_comparator = EXTERNAL_TIER[evidence_type],
                required_comparator = target["required_comparator"],
                boundary = target["boundary"],
                fixture_digest = fixture.digest,
                file_digests = fixture.digests,
                blupf90 = get(result, :blupf90, nothing),
                unavailability_note = get(result, :unavailability_note, nothing),
                boundary_note = get(result, :boundary_note, nothing),
            ),
        )
    end

    text = render_manifest(entries; mode = "validate-only", git_sha = git_head_sha())
    if write_manifest_file
        mkpath(RESULTS_DIR)
        open(MANIFEST_PATH, "w") do io
            print(io, text)
        end
        verbose && println("Wrote $(MANIFEST_PATH)")
    end

    if verbose
        for entry in entries
            extra = entry.blupf90 === nothing ? "" : " blupf90=$(entry.blupf90)"
            println(
                "  $(entry.id): $(entry.status) " *
                "[external=$(entry.external_comparator) r_mirror=$(entry.r_mirror)]$extra",
            )
        end
        tiers = [e.external_comparator for e in entries]
        mirrors = [e.r_mirror for e in entries]
        println(
            "  -- $(length(entries)) targets; external same-estimand comparator: " *
            "$(count(==("complete"), tiers)) complete, $(count(==("one_leg"), tiers)) one disclosed leg, " *
            "$(count(==("none"), tiers)) none",
        )
        println(
            "  -- cross-lane fixture bytes: $(count(==("agree"), mirrors)) agree, " *
            "$(count(==("drift"), mirrors)) drift, $(count(==("absent"), mirrors)) not mirrored, " *
            "$(count(==("uncheckable"), mirrors)) uncheckable" *
            (R_LANE === nothing ? "" : " (R lane: $(R_LANE))"),
        )
    end

    return (entries = entries, manifest_text = text)
end

function main(args = ARGS)
    opts = parse_cli(args)
    out = run_harness(; write_manifest_file = opts.write_manifest_file)
    entries = out.entries

    all(entry.status in ALLOWED_STATUSES for entry in entries) || error("invalid status emitted")
    length(entries) == TARGET_COUNT ||
        error("expected $TARGET_COUNT targets, got $(length(entries))")

    gaps = [entry.id for entry in entries if entry.status == "gap"]
    if !isempty(gaps)
        opts.strict && error("gap status on: $(join(gaps, ", "))")
        @warn "gap status reported" targets = gaps
    end
    return entries
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
