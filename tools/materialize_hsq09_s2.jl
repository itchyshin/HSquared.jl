#!/usr/bin/env julia
#
# Immutable, pre-run input declaration for the C1-ext H1/H3 confirm campaign.
#
# This tool deliberately calls only the harness's pure cell/inventory helpers.
# It never invokes a `_run_*` function, constructs a phenotype/design/pedigree,
# starts a fit, or submits/contacts a compute target.

module Hsq09S2Materialization

using SHA

const CANDIDATE_HEAD = "7770bf1640aef366970de2d136d19072bfdddcf4"
const CANDIDATE_MANIFEST_SHA256 = "a3d4803f05af9738bc5796b1534bdb3249a263efb6c618cae6088d3f0c7ce221"
const SOURCE_RELATIVE_PATH = "sim/phase1_interval_coverage_ext.jl"
const SBATCH_RELATIVE_PATH = "sim/drac/phase1_interval_coverage_ext.sbatch"
const INPUT_DECLARATION_FILE = "c1-ext-input-declaration.tsv"
const MANIFEST_FILE = "c1-ext-manifest.toml"
const SEAL_FILE = "c1-ext-seal.toml"
const ARTIFACT_FILES = (INPUT_DECLARATION_FILE, MANIFEST_FILE, SEAL_FILE)
const SCHEMA_VERSION = "hsq09-s2-c1-ext-input-materialization-v1"
const MATERIALIZATION_LIMIT = "DGP parameters and scheduled task keys are declared, but phenotype draws, constructed X/Z/Y, pedigree/Ainv, fits, smoke/campaign execution, and retained evidence results are not materialized."

const _loaded_source_root = Ref{Union{Nothing,String}}(nothing)
const _declaration_plan_cache = Dict{Tuple{String,String,String},NamedTuple}()

function sha256_file(path::AbstractString)
    context = SHA.SHA2_256_CTX()
    buffer = Vector{UInt8}(undef, 1 << 20)
    open(path, "r") do io
        while !eof(io)
            nread = readbytes!(io, buffer)
            nread == 0 && break
            SHA.update!(context, view(buffer, 1:nread))
        end
    end
    return bytes2hex(SHA.digest!(context))
end

function _git_bytes(root::AbstractString, spec::AbstractString)
    return open(Cmd(["git", "-C", root, "show", spec])) do io
        read(io)
    end
end

function _candidate_source_sha256(root::AbstractString)
    bytes = _git_bytes(root, "$(CANDIDATE_HEAD):$(SOURCE_RELATIVE_PATH)")
    return bytes2hex(sha256(bytes))
end

function _assert_candidate_source(root::AbstractString)
    source = joinpath(root, SOURCE_RELATIVE_PATH)
    isfile(source) || error("missing C1-ext source $(source)")
    actual = sha256_file(source)
    expected = _candidate_source_sha256(root)
    actual == expected || error("C1-ext source bytes drift from candidate $(CANDIDATE_HEAD)")
    return actual
end

function _environment_descriptor(root::AbstractString)
    rows = String[]
    for relative in ("Project.toml", "Manifest.toml")
        path = joinpath(root, relative)
        if isfile(path)
            push!(rows, "$(relative)\tpresent\t$(sha256_file(path))")
        else
            push!(rows, "$(relative)\tabsent")
        end
    end
    return join(rows, "\n") * "\n"
end

environment_sha256(root::AbstractString) = bytes2hex(sha256(_environment_descriptor(root)))

function _load_c1ext_helpers!(root::AbstractString)
    normalized = abspath(root)
    if _loaded_source_root[] === nothing
        _assert_candidate_source(normalized)
        # The source's sole non-stdlib import is needed by runner bodies, not
        # by the cell/seed/inventory helpers below.  Replacing that one import
        # lets this pre-run declaration remain independent of a fitted-engine
        # environment.  More importantly, include only the source prefix that
        # ends before runner definitions: this materializer cannot call a
        # runner because none is loaded into its module.
        source_path = joinpath(normalized, SOURCE_RELATIVE_PATH)
        source_text = read(source_path, String)
        occursin("using HSquared", source_text) || error("C1-ext source import anchor drift")
        source_text = replace(source_text, "using HSquared" => "# HSquared import intentionally omitted: no runner is invoked"; count = 1)
        runner_marker = findfirst("\n# ---- one-rep runners", source_text)
        runner_marker === nothing && error("C1-ext pure-helper boundary drift")
        pure_source = source_text[firstindex(source_text):prevind(source_text, first(runner_marker))]
        Base.include_string(@__MODULE__, pure_source, source_path)
        _loaded_source_root[] = normalized
    elseif _loaded_source_root[] != normalized
        error("one materializer module may only load one repository root")
    end
    return nothing
end

function _confirmation_inventory(root::AbstractString)
    _load_c1ext_helpers!(root)
    config = Base.invokelatest(ExtConfig,
        :confirm,
        EXT_CONFIRM_REPS_TARGET,
        20260903,
        collect(EXT_CAMPAIGNS),
        [EXT_PROMOTABLE_LEVEL],
        200,
        "",
        "",
        false,
    )
    return Base.invokelatest(_canonical_task_inventory, config), config
end

function _value_token(value)
    if value isa AbstractFloat
        return Base.invokelatest(_hash_float64, Float64(value))
    elseif value isa Bool
        return value ? "true" : "false"
    end
    return string(value)
end

function _cell_declaration(cell)
    names = sort!(collect(fieldnames(typeof(cell))); by = string)
    return join((string(name, "=", _value_token(getproperty(cell, name))) for name in names), ";")
end

function _expected_key_token(entry)
    key = entry.expected_key
    return join((key[1], key[2], key[3], key[4], Base.invokelatest(_hash_float64, key[5]), string(key[6]), string(key[7])), "|")
end

function _task_id(entry)
    preimage = join((
        string(entry.campaign), string(entry.campaign_index), string(entry.cell_index),
        entry.cell_id, entry.cell_label, entry.scope, Base.invokelatest(_hash_float64, entry.level),
        string(entry.rep), string(entry.seed), entry.estimand, entry.method,
        _expected_key_token(entry),
    ), "\t")
    return bytes2hex(sha256(preimage))
end

const DECLARATION_COLUMNS = (
    "task_id", "campaign", "campaign_index", "cell_index", "cell_id", "cell_label",
    "scope", "dgp_parameter_declaration", "level_f64", "rep", "seed", "estimand",
    "method", "expected_retained_key",
)

function _declaration_plan(root::AbstractString)
    entries, config = _confirmation_inventory(root)
    cells = Dict{Tuple{Symbol,Int},Any}()
    for campaign in EXT_CAMPAIGNS
        for (cell_index, cell) in pairs(Base.invokelatest(_campaign_cells, campaign, config.mode))
            cells[(campaign, cell_index)] = cell
        end
    end
    ordered_entries = sort(collect(entries); by = entry -> (
        entry.campaign_index, entry.cell_index, entry.level, entry.rep, entry.estimand, entry.method,
    ))
    return (entries = ordered_entries, cells = cells)
end

function _declaration_row(plan, entry)
    cell = plan.cells[(entry.campaign, entry.cell_index)]
    return join((
        _task_id(entry), string(entry.campaign), string(entry.campaign_index), string(entry.cell_index),
        entry.cell_id, entry.cell_label, entry.scope, _cell_declaration(cell), Base.invokelatest(_hash_float64, entry.level),
        string(entry.rep), string(entry.seed), entry.estimand, entry.method, _expected_key_token(entry),
    ), '\t')
end

function _write_hashed_line!(io, context, line::AbstractString)
    write(io, line, '\n')
    SHA.update!(context, Vector{UInt8}(codeunits(line)))
    SHA.update!(context, UInt8['\n'])
    return nothing
end

function _write_declaration(path::AbstractString, plan)
    context = SHA.SHA2_256_CTX()
    count = 0
    # `staging` is a fresh mktempdir, so ordinary write mode cannot overwrite
    # an existing immutable artifact. Julia 1.10 has no string mode "x".
    open(path, "w") do io
        _write_hashed_line!(io, context, join(DECLARATION_COLUMNS, '\t'))
        for entry in plan.entries
            _write_hashed_line!(io, context, _declaration_row(plan, entry))
            count += 1
        end
    end
    return (sha256 = bytes2hex(SHA.digest!(context)), row_count = count)
end

function _write_inventory_stream_row!(context, entry)
    key = entry.expected_key
    row = join((
        string(entry.campaign), string(entry.campaign_index), string(entry.cell_index),
        entry.cell_id, entry.cell_label, entry.scope, Base.invokelatest(_hash_float64, entry.level),
        string(entry.rep_start), string(entry.rep_end), string(entry.reps), string(entry.rep),
        string(entry.seed), entry.estimand, entry.method,
        string(key[1]), key[2], key[3], key[4], Base.invokelatest(_hash_float64, key[5]),
        string(key[6]), string(key[7]),
    ), '\t')
    SHA.update!(context, Vector{UInt8}(codeunits(row)))
    SHA.update!(context, UInt8['\n'])
    return nothing
end

function _inventory_stream_sha256(entries)
    context = SHA.SHA2_256_CTX()
    for entry in entries
        _write_inventory_stream_row!(context, entry)
    end
    return bytes2hex(SHA.digest!(context))
end

function _toml_quote(value::AbstractString)
    return "\"" * replace(value, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n") * "\""
end

function _candidate_plan(root::AbstractString)
    normalized_root = abspath(root)
    source_sha256 = _assert_candidate_source(normalized_root)
    manifest_lock = joinpath(normalized_root, "Manifest.toml")
    isfile(manifest_lock) || error("missing A2 Manifest.toml lock")
    sha256_file(manifest_lock) == CANDIDATE_MANIFEST_SHA256 ||
        error("A2 Manifest.toml lock drift")
    environment = environment_sha256(normalized_root)
    cache_key = (normalized_root, source_sha256, environment)
    haskey(_declaration_plan_cache, cache_key) && return _declaration_plan_cache[cache_key]
    plan = _declaration_plan(normalized_root)
    inventory_stream_sha256 = _inventory_stream_sha256(plan.entries)
    candidate = (
        root = normalized_root,
        source_sha256 = source_sha256,
        environment_sha256 = environment,
        environment_descriptor = _environment_descriptor(normalized_root),
        sbatch_template_sha256 = sha256_file(joinpath(normalized_root, SBATCH_RELATIVE_PATH)),
        inventory_stream_sha256 = inventory_stream_sha256,
        expected_row_count = length(plan.entries),
        plan = plan,
    )
    _declaration_plan_cache[cache_key] = candidate
    return candidate
end

function _manifest_bytes(candidate, input_sha256::AbstractString)
    return join((
        "schema_version = $(_toml_quote(SCHEMA_VERSION))",
        "candidate_head = $(_toml_quote(CANDIDATE_HEAD))",
        "source_path = $(_toml_quote(SOURCE_RELATIVE_PATH))",
        "source_sha256 = $(_toml_quote(candidate.source_sha256))",
        "sbatch_template_path = $(_toml_quote(SBATCH_RELATIVE_PATH))",
        "sbatch_template_sha256 = $(_toml_quote(candidate.sbatch_template_sha256))",
        "a2_manifest_sha256 = $(_toml_quote(CANDIDATE_MANIFEST_SHA256))",
        "environment_sha256 = $(_toml_quote(candidate.environment_sha256))",
        "environment_descriptor = $(_toml_quote(candidate.environment_descriptor))",
        "inventory_stream_sha256 = $(_toml_quote(candidate.inventory_stream_sha256))",
        "input_declaration_file = $(_toml_quote(INPUT_DECLARATION_FILE))",
        "input_declaration_sha256 = $(_toml_quote(input_sha256))",
        "expected_row_count = $(candidate.expected_row_count)",
        "manifest_digest_file = $(_toml_quote(SEAL_FILE))",
        "materialization_limit = $(_toml_quote(MATERIALIZATION_LIMIT))",
        "",
    ), "\n")
end

function _seal_bytes(manifest_sha256::AbstractString, input_sha256::AbstractString)
    return join((
        "schema_version = $(_toml_quote(SCHEMA_VERSION))",
        "manifest_file = $(_toml_quote(MANIFEST_FILE))",
        "manifest_digest_sha256 = $(_toml_quote(manifest_sha256))",
        "input_declaration_file = $(_toml_quote(INPUT_DECLARATION_FILE))",
        "input_declaration_sha256 = $(_toml_quote(input_sha256))",
        "",
    ), "\n")
end

function _artifact_path(outdir::AbstractString, name::AbstractString)
    return joinpath(outdir, name)
end

function _assert_exact_artifact_set(outdir::AbstractString)
    isdir(outdir) || error("materialization directory is absent: $(outdir)")
    observed = sort(readdir(outdir))
    expected = sort(collect(ARTIFACT_FILES))
    observed == expected || error("materialization file set drift: expected $(join(expected, ", "))")
end

function verify_materialization(outdir::AbstractString; root::AbstractString = normpath(joinpath(@__DIR__, "..")))
    _assert_exact_artifact_set(outdir)
    candidate = _candidate_plan(abspath(root))
    manifest_path = _artifact_path(outdir, MANIFEST_FILE)
    input_path = _artifact_path(outdir, INPUT_DECLARATION_FILE)
    manifest = read(manifest_path, String)
    input_sha256 = sha256_file(input_path)
    expected_manifest = _manifest_bytes(candidate, input_sha256)
    manifest == expected_manifest || error("immutable S2 artifact digest/content drift: $(MANIFEST_FILE)")
    manifest_sha256 = bytes2hex(sha256(Vector{UInt8}(codeunits(manifest))))
    seal = read(_artifact_path(outdir, SEAL_FILE), String)
    seal == _seal_bytes(manifest_sha256, input_sha256) ||
        error("immutable S2 artifact digest/content drift: $(SEAL_FILE)")

    verified_task_row_count = 0
    open(input_path, "r") do io
        readline(io) == join(DECLARATION_COLUMNS, '\t') || error("input declaration header drift")
        for entry in candidate.plan.entries
            eof(io) && error("input declaration ended before expected task rows")
            readline(io) == _declaration_row(candidate.plan, entry) ||
                error("input declaration task row drift")
            verified_task_row_count += 1
        end
        eof(io) || error("input declaration has unexpected task rows")
    end
    return (
        manifest_sha256 = manifest_sha256,
        expected_row_count = candidate.expected_row_count,
        verified_task_row_count = verified_task_row_count,
    )
end

function materialize(outdir::AbstractString = normpath(joinpath(@__DIR__, "..", "sim", "fixtures", "hsq09-s2"));
                     root::AbstractString = normpath(joinpath(@__DIR__, "..")))
    root = abspath(root)
    outdir = abspath(outdir)
    if isdir(outdir) && !isempty(readdir(outdir))
        return verify_materialization(outdir; root = root)
    end
    candidate = _candidate_plan(root)
    parent = dirname(outdir)
    isdir(parent) || error("materialization parent is absent: $(parent)")
    staging = mktempdir(parent; prefix = ".hsq09-s2-staging-")
    declaration = _write_declaration(_artifact_path(staging, INPUT_DECLARATION_FILE), candidate.plan)
    declaration.row_count == candidate.expected_row_count || error("input declaration row-count drift")
    manifest = _manifest_bytes(candidate, declaration.sha256)
    manifest_sha256 = bytes2hex(sha256(Vector{UInt8}(codeunits(manifest))))
    open(_artifact_path(staging, MANIFEST_FILE), "w") do io
        write(io, manifest)
    end
    open(_artifact_path(staging, SEAL_FILE), "w") do io
        write(io, _seal_bytes(manifest_sha256, declaration.sha256))
    end
    if isdir(outdir)
        for name in ARTIFACT_FILES
            mv(_artifact_path(staging, name), _artifact_path(outdir, name); force = false)
        end
        rm(staging)
    else
        mv(staging, outdir; force = false)
    end
    return verify_materialization(outdir; root = root)
end

function _parse_cli(args)
    verify = false
    outdir = normpath(joinpath(@__DIR__, "..", "sim", "fixtures", "hsq09-s2"))
    for arg in args
        arg == "--verify" && (verify = true; continue)
        startswith(arg, "--out-dir=") || error("expected --verify or --out-dir=PATH, got $(arg)")
        outdir = arg[length("--out-dir=") + 1:end]
    end
    return (verify = verify, outdir = outdir)
end

function main(args = ARGS)
    config = _parse_cli(args)
    receipt = config.verify ? verify_materialization(config.outdir) : materialize(config.outdir)
    token = config.verify ? "HSQ09_S2_VERIFY_OK" : "HSQ09_S2_MATERIALIZED"
    println("$(token) manifest_sha256=$(receipt.manifest_sha256) expected_row_count=$(receipt.expected_row_count)")
    return receipt
end

end # module Hsq09S2Materialization

if abspath(PROGRAM_FILE) == @__FILE__
    Hsq09S2Materialization.main()
end
