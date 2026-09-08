#!/usr/bin/env julia
#
# Private no-fit input constructor for the S2 screening/C1-ext interval grid.
# It deliberately loads the source prefix before `# ---- one-rep runners` and
# recreates only the DGP portion of each runner.  It never invokes a runner,
# likelihood, fit, or interval constructor.

module Hsq09S2FullInputs

using LinearAlgebra
using Printf
using Random
using SHA
using Serialization
using SparseArrays

const CANDIDATE_HEAD = "7770bf1640aef366970de2d136d19072bfdddcf4"
const DECLARATION_BASE = "53dc9faea16827172579c939dd606b878e162747"
const H1T_PROTOCOL_ID = "H1T-DIAG-S10-FIXED-TINY-01"
const H1T_PROTOCOL_SHA256 = "8bc191bf660c0c26d0e51f0f243502fe601c648f3c97a2047fa2c2b62bc3884f"
const PROBE_TASK_ID = "9ad671a335a065b25e3068546504d0c6ec0c2f6e75a725ca15e192a7c1b70a16"
const PROBE_MANIFEST_SHA256 = "70c95a99c5d27bfaeb4bc677a8d9e24dc8a24e833dd91fbf7125c115204dde0d"
const SOURCE_RELATIVE_PATH = "sim/phase1_interval_coverage_ext.jl"
const RUNNER_MARKER = "\n# ---- one-rep runners"

const _loaded_root = Ref{Union{Nothing,String}}(nothing)

_sha256(bytes) = bytes2hex(sha256(bytes))

function _git_bytes(root::AbstractString, spec::AbstractString)
    return open(Cmd(["git", "-C", root, "show", spec])) do io
        read(io)
    end
end

function _assert_candidate_source!(root::AbstractString)
    path = joinpath(root, SOURCE_RELATIVE_PATH)
    isfile(path) || error("missing candidate source $(SOURCE_RELATIVE_PATH)")
    _sha256(read(path)) == _sha256(_git_bytes(root, "$(CANDIDATE_HEAD):$(SOURCE_RELATIVE_PATH)")) ||
        error("source bytes drift from candidate $(CANDIDATE_HEAD)")
    return path
end

function assert_no_runner_or_fit_source!(text::AbstractString)
    # Candidate metadata records a historical “re-run” in a comment.  Inspect
    # executable line content only, so a prose receipt cannot masquerade as a
    # process call; the tests below exercise each forbidden executable form.
    executable = join((first(split(line, '#'; limit = 2)) for line in split(text, '\n')), "\n")
    forbidden = (
        (r"function\s+_run_", "runner definition"),
        (r"\bfit_[A-Za-z0-9_]*\s*\(", "fit call"),
        (r"\b[A-Za-z0-9_]*likelihood[A-Za-z0-9_]*\s*\(", "likelihood call"),
        (r"\b(?:run|pipeline|Cmd|ssh|sbatch|qsub|srun|submit|connect)\s*\(", "process or remote submission"),
        (r"\b(?:HTTP|Downloads|Sockets)\s*\.", "network access"),
        (r"(?:two_effect_ratio_interval|multi_effect_ratio_interval|repeatability_interval|genetic_correlation_interval|direct_maternal_interval)\s*\(", "interval call"),
    )
    for (pattern, label) in forbidden
        occursin(pattern, executable) && throw(ArgumentError("pure source contains a $(label)"))
    end
    return nothing
end

function pure_source_text(root::AbstractString)
    source = read(_assert_candidate_source!(root), String)
    boundary = findfirst(RUNNER_MARKER, source)
    boundary === nothing && error("pure-source cutoff marker drift")
    pure = source[firstindex(source):prevind(source, first(boundary))]
    assert_no_runner_or_fit_source!(pure)
    # The original file imports all public engine names because its later
    # runners fit models.  The no-fit prefix needs only pedigree primitives.
    return replace(pure, "using HSquared" => "using HSquared: normalize_pedigree, pedigree_inverse"; count = 1)
end

function _load_pure_helpers!(root::AbstractString)
    normalized = abspath(root)
    if _loaded_root[] === nothing
        Base.include_string(@__MODULE__, pure_source_text(normalized), joinpath(normalized, SOURCE_RELATIVE_PATH))
        _loaded_root[] = normalized
    elseif _loaded_root[] != normalized
        error("one full-input module can load only one repository root")
    end
    return nothing
end

# Load exactly the candidate-bound source prefix while this module is defined.
# Later constructors then compile in the same world age as the pure helpers;
# no runner body is present in this module.
const _DEFAULT_ROOT = normpath(joinpath(@__DIR__, ".."))
_load_pure_helpers!(_DEFAULT_ROOT)

_h1t_status_message() = "historical S10 arrays are unavailable; protocol SHA alone is not input bytes"
h1t_materialization_status() = :held_missing_immutable_bytes
materialize_h1t_without_immutable_bytes() = throw(ArgumentError(_h1t_status_message()))

function _entry_with_cell(mode::Symbol, entry)
    cell = _campaign_cells(entry.campaign, mode)[entry.cell_index]
    return merge(entry, (mode = mode, cell = cell))
end

function _plan(root::AbstractString, mode::Symbol, reps::Int)
    _load_pure_helpers!(root)
    config = ExtConfig(mode, reps, 20260903, collect(EXT_CAMPAIGNS), [EXT_PROMOTABLE_LEVEL], 200, "", "", false)
    raw = _canonical_task_inventory(config)
    entries = [_entry_with_cell(mode, entry) for entry in raw]
    return (config = config, entries = entries)
end

function screening_confirmation_plans(root::AbstractString)
    return (screen = _plan(root, :screen, 48), confirm = _plan(root, :confirm, 2000))
end

function _value_token(value)
    value isa AbstractFloat && return Base.invokelatest(_hash_float64, Float64(value))
    value isa Bool && return value ? "true" : "false"
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

# A scheduled interval row is not necessarily a unique input draw: estimands
# and methods can share the same campaign/cell/seed DGP.  The remote array is
# deliberately keyed to this raw bundle identity, never to a retained-result
# row, so it cannot silently repeat identical input construction.
function raw_task_sort_key(entry)
    return (entry.campaign_index, entry.cell_index, entry.seed, string(entry.campaign), entry.cell_id)
end

_raw_bundle_key(entry) = (entry.mode, entry.campaign, entry.campaign_index, entry.cell_index, entry.cell_id, entry.seed)

function raw_bundle_id(entry)
    preimage = join((
        CANDIDATE_HEAD,
        string(entry.mode), string(entry.campaign), string(entry.campaign_index), string(entry.cell_index),
        entry.cell_id, _cell_declaration(entry.cell), string(entry.seed),
    ), "\t")
    return _sha256(preimage)
end

function raw_task_plan(root::AbstractString)
    plans = screening_confirmation_plans(root)
    representatives = Dict{Tuple{Symbol,Symbol,Int,Int,String,Int},Any}()
    for entry in vcat(plans.screen.entries, plans.confirm.entries)
        key = _raw_bundle_key(entry)
        if haskey(representatives, key)
            raw_bundle_id(representatives[key]) == raw_bundle_id(entry) ||
                error("raw input identity drift for duplicated scheduled key")
        else
            representatives[key] = entry
        end
    end
    entries = sort!(collect(values(representatives)); by = raw_task_sort_key)
    ids = raw_bundle_id.(entries)
    length(unique(ids)) == length(ids) || error("raw bundle identifier collision")
    return (entries = entries, count = length(entries))
end

function resolve_raw_task(root::AbstractString, index::Integer)
    plan = raw_task_plan(root)
    1 <= index <= plan.count || throw(ArgumentError("raw task index $(index) is outside 1:$(plan.count)"))
    entry = plan.entries[index]
    return (index = Int(index), task_id = raw_bundle_id(entry), entry = entry, count = plan.count)
end

const RAW_TASK_MANIFEST_HEADER = "index\ttask_id\tcampaign\tcampaign_index\tcell_index\tcell_id\tseed"

function _raw_task_manifest_bytes(root::AbstractString)
    plan = raw_task_plan(root)
    rows = String[RAW_TASK_MANIFEST_HEADER]
    for (index, entry) in enumerate(plan.entries)
        push!(rows, join((string(index), raw_bundle_id(entry), string(entry.campaign),
                          string(entry.campaign_index), string(entry.cell_index),
                          entry.cell_id, string(entry.seed)), '\t'))
    end
    return join(rows, "\n") * "\n"
end

function write_raw_task_manifest(path::AbstractString; root::AbstractString = _DEFAULT_ROOT)
    ispath(path) && throw(ArgumentError("immutable raw task manifest already exists"))
    parent = dirname(path)
    isdir(parent) || throw(ArgumentError("raw task manifest parent is absent"))
    bytes = _raw_task_manifest_bytes(root)
    staging = mktempdir(parent; prefix = ".raw-task-manifest-")
    staged = joinpath(staging, basename(path))
    completed = false
    try
        open(staged, "w") do io
            write(io, bytes)
        end
        mv(staged, path; force = false)
        completed = true
    finally
        !completed && ispath(staged) && rm(staged; force = true)
        ispath(staging) && rm(staging; recursive = true, force = true)
    end
    return (path = path, sha256 = _sha256_file(path), task_count = raw_task_plan(root).count)
end

function verify_raw_task_manifest(path::AbstractString; root::AbstractString = _DEFAULT_ROOT)
    isfile(path) || throw(ArgumentError("raw task manifest is absent"))
    expected = _raw_task_manifest_bytes(root)
    actual = read(path, String)
    actual == expected || error("raw task manifest content drift")
    return (path = path, sha256 = _sha256_file(path), task_count = raw_task_plan(root).count)
end

function task_id(entry)
    preimage = join((
        string(entry.campaign), string(entry.campaign_index), string(entry.cell_index),
        entry.cell_id, entry.cell_label, entry.scope, Base.invokelatest(_hash_float64, entry.level),
        string(entry.rep), string(entry.seed), entry.estimand, entry.method,
        _expected_key_token(entry),
    ), "\t")
    return _sha256(preimage)
end

function resolve_probe_task(root::AbstractString, requested::AbstractString)
    requested == PROBE_TASK_ID || throw(ArgumentError("probe task substitution is forbidden"))
    for entry in screening_confirmation_plans(root).confirm.entries
        task_id(entry) == requested && return (mode = entry.mode, entry = entry)
    end
    error("the fixed probe task is absent from the candidate confirmation inventory")
end

_pedigree_record(ped) = (ids = copy(ped.ids), sire = copy(ped.sire), dam = copy(ped.dam))
_relationship_record(ped) = (kind = :pedigree_inverse_construction, source = :pedigree, dimension = length(ped.ids))

function _bundle_h1_two(cell, seed)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(cell.nsire, cell.ndam, cell.noffspring)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    u1 = (_chol_A(Ainv) * randn(rng, q)) .* sqrt(cell.s1)
    Z2, _ = _group_incidence(rng, q, cell.ngroup)
    u2 = randn(rng, cell.ngroup) .* sqrt(cell.s2)
    y = 2.0 .+ u1 .+ Z2 * u2 .+ randn(rng, q) .* sqrt(cell.se)
    return (
        phenotype = y,
        X = ones(q, 1),
        incidence = (Z1 = sparse(Matrix(1.0I, q, q)), Z2 = sparse(Z2), group_precision = :identity),
        pedigree = _pedigree_record(ped), relationship = _relationship_record(ped),
        truth = (ratio1 = cell.s1 / (cell.s1 + cell.s2 + cell.se), ratio2 = cell.s2 / (cell.s1 + cell.s2 + cell.se)),
    )
end

function _bundle_h1_multi(cell, seed)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(cell.nsire, cell.ndam, cell.noffspring)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    ua = (_chol_A(Ainv) * randn(rng, q)) .* sqrt(cell.sa)
    Zg1, _ = _group_incidence(rng, q, cell.ng1)
    ug1 = randn(rng, cell.ng1) .* sqrt(cell.sg1)
    y = 2.0 .+ ua .+ Zg1 * ug1
    sigmas = Float64[cell.sa, cell.sg1]
    incidence = (Z1 = sparse(Matrix(1.0I, q, q)), Zg1 = sparse(Zg1), group1_precision = :identity)
    if cell.k == 3
        Zg2, _ = _group_incidence(rng, q, cell.ng2)
        y .+= Zg2 * (randn(rng, cell.ng2) .* sqrt(cell.sg2))
        push!(sigmas, cell.sg2)
        incidence = merge(incidence, (Zg2 = sparse(Zg2), group2_precision = :identity))
    end
    y .+= randn(rng, q) .* sqrt(cell.se)
    total = sum(sigmas) + cell.se
    truths = NamedTuple{Tuple(Symbol("ratio$(i)") for i in eachindex(sigmas))}(Tuple(sigmas ./ total))
    return (phenotype = y, X = ones(q, 1), incidence = incidence,
            pedigree = _pedigree_record(ped), relationship = _relationship_record(ped), truth = truths)
end

function _bundle_h1_t(cell, seed)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(cell.nsire, cell.ndam, cell.noffspring)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    ua = (_chol_A(Ainv) * randn(rng, q)) .* sqrt(cell.sa)
    pe = randn(rng, q) .* sqrt(cell.spe)
    n = q * cell.records
    Z = zeros(n, q); y = Vector{Float64}(undef, n); row = 1
    for animal in 1:q, _ in 1:cell.records
        Z[row, animal] = 1.0
        y[row] = 2.0 + ua[animal] + pe[animal] + randn(rng) * sqrt(cell.se)
        row += 1
    end
    return (phenotype = y, X = ones(n, 1), incidence = (Z = sparse(Z),),
            pedigree = _pedigree_record(ped), relationship = _relationship_record(ped),
            truth = (t = (cell.sa + cell.spe) / (cell.sa + cell.spe + cell.se),))
end

function _bundle_h3_rg(cell, seed)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(cell.nsire, cell.ndam, cell.noffspring)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    Gtrue = [cell.g11 cell.g12; cell.g12 cell.g22]
    Rtrue = [cell.r11 cell.r12; cell.r12 cell.r22]
    U = _chol_A(Ainv) * randn(rng, q, 2) * transpose(cholesky(Symmetric(Gtrue)).L)
    n = q * cell.records
    Z = zeros(n, q); Y = zeros(n, 2); row = 1
    LR = cholesky(Symmetric(Rtrue)).L
    for animal in 1:q, _ in 1:cell.records
        Z[row, animal] = 1.0
        Y[row, :] .= 2.0 .+ U[animal, :] .+ (randn(rng, 1, 2) * transpose(LR))[1, :]
        row += 1
    end
    return (phenotype = Y, X = ones(n, 1), incidence = (Z = sparse(Z),),
            pedigree = _pedigree_record(ped), relationship = _relationship_record(ped),
            truth = (r_g = cell.g12 / sqrt(cell.g11 * cell.g22),))
end

function _bundle_h3_ram(cell, seed)
    raw = _maternal_pedigree(; nd = cell.nd, ns = cell.ns, noff = cell.noff, ngen = cell.ngen)
    ped = raw.ped
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    A = Symmetric(Matrix(inv(Symmetric(Matrix(Ainv)))))
    sdm = cell.ram * sqrt(cell.sad * cell.sam)
    G = [cell.sad sdm; sdm cell.sam]
    rng = MersenneTwister(seed)
    acoef = cholesky(A).L * randn(rng, q, 2) * transpose(cholesky(Symmetric(G)).L)
    n = length(raw.recorded)
    Zd = zeros(n, q); Zm = zeros(n, q); y = Vector{Float64}(undef, n)
    for (i, id) in enumerate(raw.recorded)
        ai = raw.idset[id]; di = raw.idset[raw.dam_of[id]]
        Zd[i, ai] = 1.0; Zm[i, di] = 1.0
        y[i] = 2.0 + acoef[ai, 1] + acoef[di, 2] + randn(rng) * sqrt(cell.se)
    end
    return (phenotype = y, X = ones(n, 1), incidence = (Zd = sparse(Zd), Zm = sparse(Zm)),
            pedigree = _pedigree_record(ped), relationship = _relationship_record(ped), truth = (r_am = cell.ram,))
end

function build_input_bundle(root::AbstractString, entry)
    _load_pure_helpers!(root)
    raw = if entry.campaign === :h1_two
        _bundle_h1_two(entry.cell, entry.seed)
    elseif entry.campaign === :h1_multi
        _bundle_h1_multi(entry.cell, entry.seed)
    elseif entry.campaign === :h1_t
        _bundle_h1_t(entry.cell, entry.seed)
    elseif entry.campaign === :h3_rg
        _bundle_h3_rg(entry.cell, entry.seed)
    elseif entry.campaign === :h3_ram
        _bundle_h3_ram(entry.cell, entry.seed)
    else
        error("unknown campaign $(entry.campaign)")
    end
    metadata = (candidate_head = CANDIDATE_HEAD, declaration_base = DECLARATION_BASE,
                mode = entry.mode, campaign = entry.campaign, cell_id = entry.cell_id,
                seed = entry.seed, representative_task_id = task_id(entry))
    return (metadata = metadata, raw...)
end

const BUNDLE_COMPONENTS = (:metadata, :phenotype, :X, :incidence, :pedigree, :relationship, :truth)

function _sha256_file(path::AbstractString)
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

function _serialize_component(path::AbstractString, value)
    open(path, "w") do io
        serialize(io, value)
    end
    return (sha256 = _sha256_file(path), bytes = filesize(path))
end

function _write_manifest(path::AbstractString, rows)
    open(path, "w") do io
        write(io, "file\tsha256\tbytes\n")
        for row in rows
            write(io, row.file, '\t', row.sha256, '\t', string(row.bytes), '\n')
        end
    end
    return (sha256 = _sha256_file(path), bytes = filesize(path))
end

function _staging_directory(output_root::AbstractString)
    mkpath(output_root)
    return mktempdir(output_root; prefix = ".staging-")
end

function _write_bundle(staging::AbstractString, bundle)
    rows = NamedTuple[]
    for component in BUNDLE_COMPONENTS
        file = string(component, ".bin")
        receipt = _serialize_component(joinpath(staging, file), getproperty(bundle, component))
        push!(rows, (file = file, sha256 = receipt.sha256, bytes = receipt.bytes))
    end
    manifest = _write_manifest(joinpath(staging, "manifest.tsv"), rows)
    return (component_rows = rows, manifest = manifest)
end

function verify_input_bundle(path::AbstractString; expected_manifest_hash::Union{Nothing,AbstractString} = nothing)
    manifest = joinpath(path, "manifest.tsv")
    isfile(manifest) || error("input bundle lacks manifest.tsv")
    expected_files = Set(["manifest.tsv"; (string(component, ".bin") for component in BUNDLE_COMPONENTS)...])
    Set(readdir(path)) == expected_files || error("input bundle file set drift")
    expected_manifest_hash === nothing ||
        _sha256_file(manifest) == expected_manifest_hash || error("input bundle manifest hash drift")
    lines = readlines(manifest)
    !isempty(lines) && lines[1] == "file\tsha256\tbytes" || error("invalid input bundle manifest header")
    length(lines) == length(BUNDLE_COMPONENTS) + 1 || error("invalid input bundle component count")
    observed = Set{String}()
    for line in lines[2:end]
        fields = split(line, '\t')
        length(fields) == 3 || error("invalid input bundle manifest row")
        file, expected_hash, expected_bytes = fields
        file in observed && error("duplicate input bundle component $(file)")
        push!(observed, file)
        component = joinpath(path, file)
        isfile(component) || error("missing input component $(file)")
        _sha256_file(component) == expected_hash || error("input component hash drift $(file)")
        filesize(component) == parse(Int, expected_bytes) || error("input component byte-count drift $(file)")
    end
    expected = Set(string(component, ".bin") for component in BUNDLE_COMPONENTS)
    observed == expected || error("input bundle component set drift")
    return nothing
end

function materialize_probe(root::AbstractString, output_root::AbstractString; task_id::AbstractString = PROBE_TASK_ID)
    task_id == PROBE_TASK_ID || throw(ArgumentError("probe task substitution is forbidden"))
    probe = resolve_probe_task(root, task_id)
    target = joinpath(output_root, task_id)
    ispath(target) && throw(ArgumentError("immutable probe target already exists"))
    staging = _staging_directory(output_root)
    completed = false
    started = time_ns()
    try
        bundle = build_input_bundle(root, probe.entry)
        receipts = _write_bundle(staging, bundle)
        verify_input_bundle(staging; expected_manifest_hash = PROBE_MANIFEST_SHA256)
        mv(staging, target)
        completed = true
        elapsed_seconds = (time_ns() - started) / 1e9
        bytes = sum(row.bytes for row in receipts.component_rows) + receipts.manifest.bytes
        return (task_id = task_id, mode = probe.mode, path = target,
                elapsed_seconds = elapsed_seconds, bytes = bytes,
                file_count = length(receipts.component_rows) + 1,
                manifest_hash = receipts.manifest.sha256)
    finally
        !completed && ispath(staging) && rm(staging; recursive = true, force = true)
    end
end

function materialize_raw_task(root::AbstractString, output_root::AbstractString, index::Integer;
                              task_manifest::AbstractString)
    verify_raw_task_manifest(task_manifest; root = root)
    task = resolve_raw_task(root, index)
    target = joinpath(output_root, task.task_id)
    if ispath(target)
        verify_input_bundle(target)
        return (index = task.index, task_id = task.task_id, path = target,
                elapsed_seconds = 0.0,
                bytes = sum(filesize(joinpath(target, file)) for file in readdir(target)),
                file_count = length(readdir(target)), manifest_hash = _sha256_file(joinpath(target, "manifest.tsv")))
    end
    staging = _staging_directory(output_root)
    completed = false
    started = time_ns()
    try
        bundle = build_input_bundle(root, task.entry)
        receipts = _write_bundle(staging, bundle)
        verify_input_bundle(staging)
        mv(staging, target; force = false)
        completed = true
        return (index = task.index, task_id = task.task_id, path = target,
                elapsed_seconds = (time_ns() - started) / 1e9,
                bytes = sum(row.bytes for row in receipts.component_rows) + receipts.manifest.bytes,
                file_count = length(receipts.component_rows) + 1,
                manifest_hash = receipts.manifest.sha256)
    finally
        !completed && ispath(staging) && rm(staging; recursive = true, force = true)
    end
end

function parse_cli_args(args::Vector{String})
    if length(args) == 2 && args[1] == "--probe-task"
        args[2] == PROBE_TASK_ID || throw(ArgumentError("probe task substitution is forbidden"))
        return (action = :probe, task_id = args[2])
    end
    if length(args) == 6 && args[1] == "--task-index" && args[3] == "--task-manifest" && args[5] == "--output-root"
        index = tryparse(Int, args[2])
        index === nothing && throw(ArgumentError("raw task index must be an integer"))
        index >= 1 || throw(ArgumentError("raw task index must be positive"))
        isempty(args[4]) && throw(ArgumentError("raw task manifest path is empty"))
        isempty(args[6]) && throw(ArgumentError("raw task output root is empty"))
        return (action = :task, index = index, task_manifest = args[4], output_root = args[6])
    end
    throw(ArgumentError("expected --probe-task <fixed-task-id> or --task-index <positive-int> --task-manifest <path> --output-root <path>"))
end

function main(args::Vector{String} = ARGS; root::AbstractString = _DEFAULT_ROOT)
    parsed = parse_cli_args(args)
    if parsed.action === :probe
        output_root = joinpath(root, "sim", "fixtures", "hsq09-s2-full", "probe")
        target = joinpath(output_root, parsed.task_id)
        result = if ispath(target)
            verify_input_bundle(target; expected_manifest_hash = PROBE_MANIFEST_SHA256)
            (task_id = parsed.task_id, mode = :confirm, path = target,
             elapsed_seconds = 0.0, bytes = sum(filesize(joinpath(target, file)) for file in readdir(target)),
             file_count = length(readdir(target)), manifest_hash = _sha256_file(joinpath(target, "manifest.tsv")))
        else
            materialize_probe(root, output_root; task_id = parsed.task_id)
        end
        println("S2_FULL_INPUT_PROBE_OK task_id=$(result.task_id) elapsed_seconds=$(result.elapsed_seconds) bytes=$(result.bytes) file_count=$(result.file_count) manifest_sha256=$(result.manifest_hash)")
        return result
    end
    result = materialize_raw_task(root, parsed.output_root, parsed.index; task_manifest = parsed.task_manifest)
    println("S2_FULL_INPUT_TASK_OK index=$(result.index) task_id=$(result.task_id) elapsed_seconds=$(result.elapsed_seconds) bytes=$(result.bytes) file_count=$(result.file_count) manifest_sha256=$(result.manifest_hash)")
    return result
end

end # module Hsq09S2FullInputs

if abspath(PROGRAM_FILE) == @__FILE__
    Hsq09S2FullInputs.main()
end
