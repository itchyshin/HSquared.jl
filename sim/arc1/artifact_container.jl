# Versioned, sectioned Arc1 artifact container. Julia Serialization is retained
# only inside bounded typed records; event histories are serialized one event
# at a time so the reader never rebuilds the former monolithic object graph.
using Serialization
using SHA

const ARC1_CONTAINER_MAGIC = UInt8[0x41, 0x52, 0x43, 0x31, 0x43, 0x30, 0x30, 0x31]
const ARC1_CONTAINER_VERSION = UInt16(2)
const ARC1_CONTAINER_SCHEMA = "arc1-native-section-v2"

struct Arc1ContainerRef
    id::UInt64
end

const ARC1_CONTAINER_PEDIGREE_FIELD_LAYOUTS = (
    (:ids, :sire, :dam, :order),
    (:ids, :sire, :dam, :original_order),
)
# The closed wire set is implemented below: primitive/exact numeric values,
# tuples, Dicts, standard dense/bit/sparse arrays, Arc1 references, and the
# engine Pedigree record with this exact field list. Other structs fail closed.
const ARC1_CONTAINER_ARTIFACT_SECTIONS = Set((
    "metadata", "data", "design", "profile", "raw_selection", "reference_raw",
    "bootstrap_raw", "prefix_raw", "result", "success", "status", "failure_reason", "result_kind",
    "outer", "seed", "seed_string", "observed_ids", "record_ids",
    "record_animal_ids", "truth", "data_identity_sha256",
    "semantic_data_identity_sha256", "data_identity_method", "elapsed_seconds",
    "execution_identity", "requested_profile_method_version", "rank_candidates",
    "eligible", "both_candidates_available", "selection_status", "selection_reason",
    "selected_rank", "reference_audit", "selection", "candidate_summary",
    "starts_planned", "starts_attempted", "selector_attempts", "guard_results",
    "outer_selection", "bootstrap", "profile_method", "profile_lr_cutoff",
    "profile_intervals", "point_estimates", "profile_method_version",
    "point_fit_status", "point_fit_not_optimal", "point_loglik",
    "max_constrained_loglik", "point_identity", "reference_point_identity",
    "source_identity", "reference_source_identity", "point_fit_diagnostic_identity",
    "target_diagnostics_identity", "v3_profile_evidence_raw", "v3_profile_evidence_summary",
    "error", "references",
    "evidence", "history",
    "history_rows", "summary", "tail_certificate_inputs"))

const ARC1_CONTAINER_SCALAR_TYPES = (Bool, Char, Int8, Int16, Int32, Int64, Int128,
    UInt8, UInt16, UInt32, UInt64, UInt128, Float16, Float32, Float64,
    BigInt, BigFloat, String, Symbol)

function arc1_container_approved_enum_type(T)
    enum_module = parentmodule(T)
    nameof(enum_module) === :TerminationCode || return false
    isdefined(enum_module, :T) && getfield(enum_module, :T) === T || return false
    optim_module = parentmodule(enum_module)
    nameof(optim_module) === :Optim || return false
    return any(loaded_module -> loaded_module === optim_module,
        values(Base.loaded_modules))
end

function arc1_container_validate_artifact_sections(sections)
    unknown = setdiff(Set(String.(keys(sections))), ARC1_CONTAINER_ARTIFACT_SECTIONS)
    isempty(unknown) || throw(ArgumentError(
        "unsupported Arc1 artifact sections: $(join(sort!(collect(unknown)), ", "))"))
    return nothing
end

function arc1_container_validate_supported_type(T; path="root")
    T === Any && return nothing
    T === Nothing && return nothing
    T === Missing && return nothing
    if T isa Union
        for member in Base.uniontypes(T)
            arc1_container_validate_supported_type(member; path)
        end
        return nothing
    end
    # NamedTuple types may be abstract because their value tuple is omitted or
    # contains abstract field types. The value-level validator below visits each
    # concrete value and validates every field before it is written.
    T <: NamedTuple && return nothing
    T in ARC1_CONTAINER_SCALAR_TYPES && return nothing
    if T <: Enum
        arc1_container_approved_enum_type(T) || throw(ArgumentError(
            "unsupported Arc1 container type $(T) at $(path)"))
    elseif T <: Rational
        isconcretetype(T) && T.parameters[1] in ARC1_CONTAINER_SCALAR_TYPES ||
            throw(ArgumentError("unsupported Arc1 container type $(T) at $(path)"))
    elseif T <: Complex
        isconcretetype(T) && T.parameters[1] in ARC1_CONTAINER_SCALAR_TYPES ||
            throw(ArgumentError("unsupported Arc1 container type $(T) at $(path)"))
    elseif T === Arc1ContainerRef
        fieldtypes(T) === (UInt64,) || throw(ArgumentError(
            "unsupported Arc1 container type $(T) at $(path)"))
    elseif T <: Tuple
        isconcretetype(T) || throw(ArgumentError(
            "unsupported Arc1 container type $(T) at $(path)"))
        for (index, field_type) in pairs(fieldtypes(T))
            arc1_container_validate_supported_type(field_type;
                path=string(path, "[", index, "]"))
        end
    elseif T <: Dict
        isconcretetype(T) || throw(ArgumentError(
            "unsupported Arc1 container type $(T) at $(path)"))
        arc1_container_validate_supported_type(keytype(T); path=string(path, ".<key>"))
        arc1_container_validate_supported_type(valtype(T); path=string(path, ".<value>"))
    elseif T <: Array
        isconcretetype(T) && 1 <= T.parameters[2] <= 2 || throw(ArgumentError(
            "unsupported Arc1 container type or dimensions $(T) at $(path)"))
        arc1_container_validate_supported_type(eltype(T); path=string(path, "[]"))
    elseif T <: BitArray
        isconcretetype(T) && 1 <= T.parameters[1] <= 2 || throw(ArgumentError(
            "unsupported Arc1 container type or dimensions $(T) at $(path)"))
    elseif nameof(T) === :SparseMatrixCSC && nameof(parentmodule(T)) === :SparseArrays
        isconcretetype(T) || throw(ArgumentError(
            "unsupported Arc1 container type $(T) at $(path)"))
        T.parameters[2] in (Int32, Int64) || throw(ArgumentError(
            "unsupported Arc1 container sparse index type $(T.parameters[2]) at $(path)"))
        arc1_container_validate_supported_type(eltype(T); path=string(path, "[]"))
    elseif T <: Pair
        isconcretetype(T) || throw(ArgumentError(
            "unsupported Arc1 container type $(T) at $(path)"))
        for (index, field_type) in pairs(fieldtypes(T))
            arc1_container_validate_supported_type(field_type;
                path=string(path, "[", index, "]"))
        end
    elseif nameof(T) === :Pedigree && nameof(parentmodule(T)) === :HSquared &&
           fieldnames(T) in ARC1_CONTAINER_PEDIGREE_FIELD_LAYOUTS
        pedigree_fields = fieldnames(T)
        for (index, field_type) in pairs(fieldtypes(T))
            arc1_container_validate_supported_type(field_type;
                path=string(path, ".", pedigree_fields[index]))
        end
    else
        throw(ArgumentError("unsupported Arc1 container type $(T) at $(path)"))
    end
    return nothing
end

function arc1_container_validate_supported(value; path="root", seen=IdDict{Any,Nothing}())
    value === nothing && return nothing
    value === missing && return nothing
    arc1_container_validate_supported_type(typeof(value); path)
    typeof(value) in ARC1_CONTAINER_SCALAR_TYPES && return nothing
    if value isa Enum
        T = typeof(value)
        arc1_container_approved_enum_type(T) && value in instances(T) ||
            throw(ArgumentError("unsupported Arc1 enum value $(T) at $(path)"))
        return nothing
    elseif value isa Rational
        typeof(value).parameters[1] in ARC1_CONTAINER_SCALAR_TYPES ||
            throw(ArgumentError("unsupported Arc1 rational type $(typeof(value)) at $(path)"))
        return nothing
    elseif value isa Complex
        typeof(value).parameters[1] in ARC1_CONTAINER_SCALAR_TYPES ||
            throw(ArgumentError("unsupported Arc1 complex type $(typeof(value)) at $(path)"))
        arc1_container_validate_supported(real(value); path=string(path, ".real"), seen)
        arc1_container_validate_supported(imag(value); path=string(path, ".imag"), seen)
        return nothing
    end
    if value isa Arc1ContainerRef
        arc1_container_validate_supported(value.id; path=string(path, ".id"), seen)
        return nothing
    end

    T = typeof(value)
    if ismutabletype(T)
        haskey(seen, value) && return nothing
        seen[value] = nothing
    end
    if value isa NamedTuple
        for key in keys(value)
            arc1_container_validate_supported(getproperty(value, key);
                path=string(path, ".", key), seen)
        end
    elseif value isa Tuple
        for (index, item) in pairs(value)
            arc1_container_validate_supported(item;
                path=string(path, "[", index, "]"), seen)
        end
    elseif value isa Dict
        for (key, item) in pairs(value)
            arc1_container_validate_supported(key; path=string(path, ".<key>"), seen)
            arc1_container_validate_supported(item;
                path=string(path, "[", repr(key), "]"), seen)
        end
    elseif value isa AbstractArray &&
           (T <: Array || T <: BitArray ||
            (nameof(T) === :SparseMatrixCSC && nameof(parentmodule(T)) === :SparseArrays))
        for index in eachindex(value)
            arc1_container_validate_supported(value[index];
                path=string(path, "[", index, "]"), seen)
        end
    elseif value isa Pair
        arc1_container_validate_supported(first(value); path=string(path, ".first"), seen)
        arc1_container_validate_supported(last(value); path=string(path, ".second"), seen)
    elseif nameof(T) === :Pedigree && nameof(parentmodule(T)) === :HSquared &&
           fieldnames(T) in ARC1_CONTAINER_PEDIGREE_FIELD_LAYOUTS
        for field in fieldnames(T)
            arc1_container_validate_supported(getfield(value, field);
                path=string(path, ".", field), seen)
        end
    else
        throw(ArgumentError("unsupported Arc1 container value type $(T) at $(path)"))
    end
    return nothing
end

function arc1_container_write_u16(io, value::Integer)
    0 <= value <= typemax(UInt16) || throw(ArgumentError("container UInt16 overflow"))
    write(io, htol(UInt16(value)))
end

function arc1_container_write_u64(io, value::Integer)
    0 <= value <= typemax(UInt64) || throw(ArgumentError("container UInt64 overflow"))
    write(io, htol(UInt64(value)))
end

arc1_container_read_u16(io) = ltoh(read(io, UInt16))
arc1_container_read_u64(io) = ltoh(read(io, UInt64))

function arc1_container_write_string(io, value::AbstractString)
    bytes = codeunits(value)
    arc1_container_write_u16(io, length(bytes))
    write(io, bytes)
end

function arc1_container_read_string(io)
    n = Int(arc1_container_read_u16(io))
    return String(read(io, n))
end

"""Record IDs from the original object graph before any container projection."""
function arc1_container_reference_table(value)
    evidence = if value isa AbstractDict
        get(value, "evidence", get(value, :evidence, nothing))
    elseif hasproperty(value, :v3_profile_evidence)
        value.v3_profile_evidence
    else
        nothing
    end
    ids = Dict{UInt64,UInt64}()
    paths = Dict{String,UInt64}()
    nextid = UInt64(1)
    register(path, object) = begin
        object === nothing && return
        oid = objectid(object)
        id = get(ids, oid, nothing)
        if id === nothing
            id = nextid
            nextid += UInt64(1)
            ids[oid] = id
        end
        paths[path] = id
    end
    if evidence isa AbstractDict
        register("evidence", evidence)
        has3 = haskey(evidence, :arc1_profile_v3_evaluations) || haskey(evidence, "arc1_profile_v3_evaluations")
        has4 = haskey(evidence, :arc1_profile_v4_evaluations) || haskey(evidence, "arc1_profile_v4_evaluations")
        if has3 && has4
            v3 = get(evidence, :arc1_profile_v3_evaluations,
                get(evidence, "arc1_profile_v3_evaluations", nothing))
            v4 = get(evidence, :arc1_profile_v4_evaluations,
                get(evidence, "arc1_profile_v4_evaluations", nothing))
            v3 === v4 || throw(ArgumentError("original v3/v4 profile histories are not the same object"))
            register("evidence.arc1_profile_v3_evaluations", v3)
            register("evidence.arc1_profile_v4_evaluations", v4)
        elseif has3 || has4
            # An interrupted pre-entry state must retain absent keys. Do not
            # manufacture the other alias to make a normalized representation.
            key = has3 ? :arc1_profile_v3_evaluations : :arc1_profile_v4_evaluations
            string_key = String(key)
            register("evidence." * string_key,
                get(evidence, key, get(evidence, string_key, nothing)))
        end
        history = get(evidence, :arc1_profile_v3_evaluations,
            get(evidence, "arc1_profile_v3_evaluations",
                get(evidence, :arc1_profile_v4_evaluations,
                    get(evidence, "arc1_profile_v4_evaluations", nothing))))
        if history isa AbstractVector
            for (row_index, row) in pairs(history)
                row isa AbstractDict || continue
                for field in (:events, :producer_history, :provenance_failures)
                    haskey(row, field) || continue
                    value = row[field]
                    value === nothing || register("evaluation.$row_index.$field", value)
                end
            end
        end
    end
    if value isa AbstractDict
        for path in ("history", "history_alias")
            haskey(value, path) && register(path, value[path])
        end
    end
    return Dict(k => v for (k, v) in paths)
end

function arc1_container_stage_section(directory, name::String, value)
    arc1_container_validate_supported(value; path=name)
    path = joinpath(directory, "section-" * name)
    records = UInt64(1)
    open(path, "w") do io
        if name == "history" && value isa AbstractVector
            records = UInt64(length(value))
            for item in value
                bytes = let buffer = IOBuffer()
                    serialize(buffer, item)
                    take!(buffer)
                end
                arc1_container_write_u64(io, length(bytes))
                write(io, bytes)
            end
        else
            serialize(io, value)
        end
        flush(io)
    end
    digest_context = SHA.SHA2_256_CTX()
    open(path, "r") do input
        while !eof(input)
            SHA.update!(digest_context, read(input, 1024 * 1024))
        end
    end
    return (name=name, schema=string(ARC1_CONTAINER_SCHEMA, ":", name), path=path,
        length=UInt64(filesize(path)), records, digest=SHA.digest!(digest_context))
end

function arc1_container_encode_directory(entries, offsets)
    io = IOBuffer()
    write(io, ARC1_CONTAINER_MAGIC)
    arc1_container_write_u16(io, ARC1_CONTAINER_VERSION)
    arc1_container_write_u16(io, length(entries))
    for (entry, offset) in zip(entries, offsets)
        arc1_container_write_string(io, entry.name)
        arc1_container_write_string(io, entry.schema)
        arc1_container_write_u64(io, offset)
        arc1_container_write_u64(io, entry.length)
        arc1_container_write_u64(io, entry.records)
        write(io, entry.digest)
    end
    return take!(io)
end

function arc1_container_deserialize_exact(io::IO)
    value = deserialize(io)
    eof(io) || throw(ArgumentError("serialized Arc1 section has trailing bytes"))
    arc1_container_validate_supported(value)
    return value
end

function arc1_write_container_new(path::AbstractString, sections::AbstractDict;
        publication_hook=(stage, name) -> nothing)
    ispath(path) && throw(ArgumentError("refusing to replace existing Arc1 container: $path"))
    mkpath(dirname(path))
    pairs = sort!(collect(sections); by=first)
    names = String[first(pair) for pair in pairs]
    issorted(names) && length(unique(names)) == length(names) ||
        throw(ArgumentError("container section names must be unique and sorted"))
    mktempdir(dirname(path); prefix=".arc1-container-") do staging
        entries = NamedTuple[]
        for (name, value) in pairs
            entry = arc1_container_stage_section(staging, String(name), value)
            push!(entries, entry)
            publication_hook(:section_staged, entry.name)
        end
        offsets = zeros(UInt64, length(entries))
        directory = UInt8[]
        for _ in 1:4
            directory = arc1_container_encode_directory(entries, offsets)
            offset = UInt64(length(directory))
            for i in eachindex(entries)
                offsets[i] = offset
                offset += entries[i].length
            end
        end
        directory = arc1_container_encode_directory(entries, offsets)
        temp, io = mktemp(dirname(path); cleanup=false)
        try
            write(io, directory)
            publication_hook(:directory_written, nothing)
            for entry in entries
                open(entry.path, "r") do source
                    while !eof(source)
                        write(io, read(source, 1024 * 1024))
                    end
                end
                publication_hook(:section_published, entry.name)
            end
            flush(io)
            close(io)
            publication_hook(:before_publish, nothing)
            mv(temp, path; force=false)
        catch
            isopen(io) && close(io)
            ispath(temp) && rm(temp; force=true)
            rethrow()
        end
    end
    return arc1_artifact_sha256(path)
end

function arc1_read_container(path::AbstractString)
    open(path, "r") do io
        read(io, length(ARC1_CONTAINER_MAGIC)) == ARC1_CONTAINER_MAGIC ||
            throw(ArgumentError("Arc1 container magic differs"))
        arc1_container_read_u16(io) == ARC1_CONTAINER_VERSION ||
            throw(ArgumentError("unsupported Arc1 container version"))
        n = Int(arc1_container_read_u16(io))
        n > 0 || throw(ArgumentError("Arc1 container has no sections"))
        entries = NamedTuple[]
        seen = Set{String}()
        previous_name = nothing
        for _ in 1:n
            name = arc1_container_read_string(io)
            schema = arc1_container_read_string(io)
            offset, len, records = arc1_container_read_u64(io), arc1_container_read_u64(io),
                arc1_container_read_u64(io)
            digest = read(io, 32)
            name in seen && throw(ArgumentError("duplicate Arc1 container section"))
            push!(seen, name)
            schema == string(ARC1_CONTAINER_SCHEMA, ":", name) ||
                throw(ArgumentError("unknown Arc1 container section schema"))
            previous_name === nothing || previous_name < name ||
                throw(ArgumentError("container sections are reordered"))
            previous_name = name
            records <= typemax(Int) || throw(ArgumentError("container record count is too large"))
            push!(entries, (; name, schema, offset, len, records, digest))
        end
        directory_end = position(io)
        expected_offset = UInt64(directory_end)
        for entry in entries
            entry.offset == expected_offset || throw(ArgumentError("container sections are reordered or overlap"))
            entry.name == "history" || entry.records == 1 ||
                throw(ArgumentError("non-history Arc1 section record count must equal one"))
            expected_offset += entry.len
        end
        filesize(path) == expected_offset || throw(ArgumentError("container is truncated or has trailing bytes"))
        output = Dict{String,Any}()
        mktempdir() do staging
            for (index, entry) in pairs(entries)
                seek(io, entry.offset)
                context = SHA.SHA2_256_CTX()
                temp_path = joinpath(staging, "decode-" * string(index))
                open(temp_path, "w") do target
                    remaining = Int(entry.len)
                    while remaining > 0
                        chunk = read(io, min(remaining, 1024 * 1024))
                        isempty(chunk) && throw(ArgumentError("truncated Arc1 container section"))
                        SHA.update!(context, chunk)
                        write(target, chunk)
                        remaining -= length(chunk)
                    end
                end
                SHA.digest!(context) == entry.digest ||
                    throw(ArgumentError("container section digest differs: $(entry.name)"))
                if entry.name == "history"
                    history = Any[]
                    open(temp_path, "r") do records_io
                        for _ in 1:Int(entry.records)
                            record_size = Int(arc1_container_read_u64(records_io))
                            record_size >= 0 || throw(ArgumentError("negative Arc1 history record size"))
                            record_bytes = read(records_io, record_size)
                            length(record_bytes) == record_size || throw(ArgumentError(
                                "Arc1 history event record is truncated"))
                            push!(history, arc1_container_deserialize_exact(IOBuffer(record_bytes)))
                        end
                        eof(records_io) || throw(ArgumentError("history section has trailing bytes"))
                    end
                    output[entry.name] = history
                else
                    output[entry.name] = open(temp_path, "r") do section_io
                        arc1_container_deserialize_exact(section_io)
                    end
                end
            end
        end
        return output
    end
end

function arc1_container_object(container::AbstractDict, first_path::String, second_path::String)
    refs = get(container, "references", Dict{String,UInt64}())
    haskey(refs, first_path) && haskey(refs, second_path) && refs[first_path] == refs[second_path] ||
        throw(ArgumentError("container reference table does not preserve object identity"))
    if first_path == "history" && second_path == "history_alias"
        return container["history"]
    end
    throw(ArgumentError("container object reference path is not materialized"))
end

function arc1_container_history_id(refs, key)
    return get(refs, "evidence." * String(key), nothing)
end

function arc1_container_validate_reference_categories(refs)
    refs isa AbstractDict || throw(ArgumentError("container reference table is malformed"))
    categories = Dict{UInt64,Symbol}()
    for (path_value, id_value) in pairs(refs)
        path = String(path_value)
        category = if path == "evidence"
            :evidence
        elseif startswith(path, "evidence.arc1_profile_") && endswith(path, "_evaluations")
            :history
        elseif startswith(path, "evaluation.")
            :event
        else
            continue
        end
        id = UInt64(id_value)
        previous = get(categories, id, nothing)
        previous === nothing || previous == category || throw(ArgumentError(
            "container object ID crosses semantic categories"))
        categories[id] = category
    end
    return nothing
end

function arc1_container_strip_history(evidence, refs)
    evidence isa AbstractDict || return evidence
    stripped = copy(evidence)
    for key in (:arc1_profile_v3_evaluations, :arc1_profile_v4_evaluations)
        haskey(stripped, key) || continue
        id = arc1_container_history_id(refs, key)
        id === nothing && throw(ArgumentError("profile history has no recorded object identity"))
        stripped[key] = Arc1ContainerRef(id)
    end
    return stripped
end

const ARC1_CONTAINER_EVENT_FIELDS = (:events, :producer_history, :provenance_failures)
const ARC1_CONTAINER_PROFILE_ROW_REQUIRED_FIELDS = Set((:target, :fixed_value, :status,
    :events, :producer_history, :provenance_failures, :max_valid_loglik,
    :max_valid_centered_loglik))
const ARC1_CONTAINER_PROFILE_ROW_ALLOWED_FIELDS = union(
    ARC1_CONTAINER_PROFILE_ROW_REQUIRED_FIELDS, Set((:original_native,
        :returned_native, :initial_certificate, :intersection, :event_lengths)))

function arc1_container_validate_history_record(record, required_fields, label)
    fields = if record isa NamedTuple
        Set(keys(record))
    elseif record isa AbstractDict && all(key -> key isa Symbol, keys(record))
        Set(keys(record))
    else
        throw(ArgumentError("profile history $(label) entry must be a symbol-keyed record"))
    end
    fields == required_fields || throw(ArgumentError(
        "profile history $(label) entry fields are invalid"))
    getfield_or_key(record, field) = record isa NamedTuple ?
        getproperty(record, field) : record[field]
    return getfield_or_key
end

const ARC1_CONTAINER_PRODUCER_HISTORY_FIELDS = Set((:path, :owner,
    :candidate_id, :source_id, :record))
const ARC1_CONTAINER_PROVENANCE_FAILURE_FIELDS = Set((:path, :field,
    :reason, :value, :tag, :expected_ve))

function arc1_container_validate_profile_row(row)
    row isa AbstractDict || throw(ArgumentError("profile history row is not a dictionary"))
    all(key -> key isa Symbol, keys(row)) || throw(ArgumentError(
        "profile history row keys must be symbols"))
    fields = Set(keys(row))
    isempty(setdiff(fields, ARC1_CONTAINER_PROFILE_ROW_ALLOWED_FIELDS)) ||
        throw(ArgumentError("profile history row has unsupported fields"))
    issubset(ARC1_CONTAINER_PROFILE_ROW_REQUIRED_FIELDS, fields) ||
        throw(ArgumentError("profile history row lacks required fields"))
    row[:target] isa Symbol && row[:target] in (:additive_variance,
        :permanent_environment_variance, :residual_variance, :heritability,
        :repeatability) || throw(ArgumentError("profile history row target is invalid"))
    row[:fixed_value] isa Real && !(row[:fixed_value] isa Bool) ||
        throw(ArgumentError("profile history row fixed_value must be real"))
    row[:status] isa Symbol || throw(ArgumentError(
        "profile history row status must be a symbol"))
    for field in (:events, :producer_history, :provenance_failures)
        row[field] isa AbstractVector || row[field] isa Arc1ContainerRef ||
            throw(ArgumentError("profile history row $(field) must be a vector or reference"))
    end
    producer_items = row[:producer_history] isa Arc1ContainerRef ? () :
        row[:producer_history]
    for item in producer_items
        getvalue = arc1_container_validate_history_record(item,
            ARC1_CONTAINER_PRODUCER_HISTORY_FIELDS, :producer_history)
        path, owner = getvalue(item, :path), getvalue(item, :owner)
        candidate_id, source_id, record = getvalue(item, :candidate_id),
            getvalue(item, :source_id), getvalue(item, :record)
        owner_valid = owner in (:candidate, :shared, nothing)
        candidate_id_valid = owner === :candidate ?
            (candidate_id isa Integer && !(candidate_id isa Bool) && candidate_id > 0) :
            candidate_id === nothing
        source_id_valid = source_id isa Tuple && length(source_id) == 5 &&
            source_id[1] === :producer_record && source_id[2] === owner &&
            isequal(source_id[3], candidate_id) && isequal(source_id[4], path) &&
            source_id[5] isa Int && source_id[5] > 0
        path isa AbstractString && !isempty(path) && owner_valid &&
            candidate_id_valid && source_id_valid &&
            (record isa NamedTuple || record isa AbstractDict) ||
            throw(ArgumentError("profile history producer_history entry values are invalid"))
    end
    failure_items = row[:provenance_failures] isa Arc1ContainerRef ? () :
        row[:provenance_failures]
    for item in failure_items
        getvalue = arc1_container_validate_history_record(item,
            ARC1_CONTAINER_PROVENANCE_FAILURE_FIELDS, :provenance_failures)
        path, field = getvalue(item, :path), getvalue(item, :field)
        reason, expected_ve = getvalue(item, :reason), getvalue(item, :expected_ve)
        path isa AbstractString && field isa Symbol && reason isa Symbol &&
            expected_ve isa Real && !(expected_ve isa Bool) ||
            throw(ArgumentError("profile history provenance_failures entry values are invalid"))
    end
    for field in (:max_valid_loglik, :max_valid_centered_loglik)
        row[field] isa Real && !(row[field] isa Bool) ||
            throw(ArgumentError("profile history row $(field) must be real"))
    end
    if haskey(row, :event_lengths)
        lengths = row[:event_lengths]
        lengths isa AbstractDict && all(key isa Symbol && value isa Int && value >= 0
            for (key, value) in lengths) || throw(ArgumentError(
                "profile history row event_lengths must map symbols to nonnegative Int values"))
    end
    return nothing
end

function arc1_container_pack_evaluations(history, refs)
    history isa AbstractVector || return nothing, nothing
    rows = Any[]
    events = Any[]
    for (row_index, original) in pairs(history)
        arc1_container_validate_profile_row(original)
        row = copy(original)
        event_lengths = Dict{Symbol,Int}()
        for key in ARC1_CONTAINER_EVENT_FIELDS
            haskey(row, key) || continue
            values = row[key]
            values isa AbstractVector || throw(ArgumentError("profile history event field is not a vector"))
            event_lengths[key] = length(values)
            id = get(refs, "evaluation.$row_index.$key", nothing)
            id === nothing && throw(ArgumentError("profile history event array lacks an original object ID"))
            row[key] = Arc1ContainerRef(id)
            for (event_index, event) in pairs(values)
                push!(events, (; row_index=Int(row_index), field=key,
                    event_index=Int(event_index), event))
            end
        end
        isempty(event_lengths) || (row[:event_lengths] = event_lengths)
        push!(rows, row)
    end
    return rows, events
end

function arc1_container_restore_evaluations(rows, event_stream, refs)
    rows isa AbstractVector || throw(ArgumentError("profile history row section is malformed"))
    event_stream isa AbstractVector || throw(ArgumentError("profile event stream section is malformed"))
    grouped = Dict{Tuple{Int,Symbol},Vector{Any}}()
    for record in event_stream
        record isa NamedTuple && propertynames(record) ===
            (:row_index, :field, :event_index, :event) || throw(ArgumentError(
                "profile event stream record fields differ"))
        record.row_index isa Int && record.row_index > 0 &&
            record.event_index isa Int && record.event_index > 0 || throw(ArgumentError(
                "profile event row and index must be positive Int values"))
        record.row_index <= length(rows) || throw(ArgumentError(
            "profile event row index is out of range"))
        record.field isa Symbol && record.field in ARC1_CONTAINER_EVENT_FIELDS ||
            throw(ArgumentError("profile event field is unsupported"))
        key = (record.row_index, record.field)
        values = get!(grouped, key, Any[])
        record.event_index == length(values) + 1 ||
            throw(ArgumentError("profile event stream is reordered or has a gap"))
        push!(values, record.event)
    end
    restored = Any[]
    values_by_id = Dict{UInt64,Vector{Any}}()
    for (row_index, original) in pairs(rows)
        arc1_container_validate_profile_row(original)
        row = copy(original)
        event_fields = Set(key for key in ARC1_CONTAINER_EVENT_FIELDS if haskey(row, key))
        expected_lengths = if isempty(event_fields)
            haskey(row, :event_lengths) && throw(ArgumentError(
                "profile history row has event lengths without event fields"))
            Dict{Symbol,Int}()
        else
            lengths = get(row, :event_lengths, nothing)
            lengths isa AbstractDict || throw(ArgumentError(
                "profile history row lacks expected event lengths"))
            Set(Symbol(key) for key in keys(lengths)) == event_fields || throw(ArgumentError(
                "profile history expected event-length fields differ"))
            parsed = Dict{Symbol,Int}()
            for (field, count) in pairs(lengths)
                count isa Integer && !(count isa Bool) && 0 <= count <= typemax(Int) ||
                    throw(ArgumentError("profile history expected event length is invalid"))
                parsed[Symbol(field)] = Int(count)
            end
            pop!(row, :event_lengths)
            parsed
        end
        for key in ARC1_CONTAINER_EVENT_FIELDS
            haskey(row, key) || continue
            marker = row[key]
            marker isa Arc1ContainerRef || throw(ArgumentError("profile event field lacks an object reference"))
            expected = get(refs, "evaluation.$row_index.$key", nothing)
            marker.id == expected || throw(ArgumentError("profile event field reference ID differs"))
            values = get(grouped, (Int(row_index), key), Any[])
            length(values) == expected_lengths[key] || throw(ArgumentError(
                "profile event count differs from the retained expected length"))
            if haskey(values_by_id, marker.id)
                isequal(values_by_id[marker.id], values) || throw(ArgumentError(
                    "one profile event object ID names conflicting decoded values"))
                row[key] = values_by_id[marker.id]
            else
                values_by_id[marker.id] = values
                row[key] = values
            end
        end
        arc1_container_validate_profile_row(row)
        push!(restored, row)
    end
    allowed = Set((Int(i), key) for (i, row) in pairs(rows)
        for key in ARC1_CONTAINER_EVENT_FIELDS if haskey(row, key))
    all(key in allowed for key in keys(grouped)) ||
        throw(ArgumentError("profile event stream includes an unknown row/field"))
    return restored
end

function arc1_container_restore_history(evidence, history, refs)
    evidence isa AbstractDict || return evidence
    restored = copy(evidence)
    for key in (:arc1_profile_v3_evaluations, :arc1_profile_v4_evaluations)
        haskey(restored, key) || continue
        value = restored[key]
        value isa Arc1ContainerRef || throw(ArgumentError(
            "stored profile history must contain only an object reference"))
        expected = arc1_container_history_id(refs, key)
        expected === nothing && throw(ArgumentError("profile history reference ID is absent"))
        value.id == expected || throw(ArgumentError("profile history reference ID differs"))
        history === nothing || (restored[key] = history)
    end
    if haskey(restored, :arc1_profile_v3_evaluations) &&
       haskey(restored, :arc1_profile_v4_evaluations)
        v3_id = arc1_container_history_id(refs, :arc1_profile_v3_evaluations)
        v4_id = arc1_container_history_id(refs, :arc1_profile_v4_evaluations)
        v3_id == v4_id || throw(ArgumentError(
            "stored v3/v4 profile history references do not share an object ID"))
    end
    if haskey(restored, :arc1_profile_v3_evaluations) &&
       haskey(restored, :arc1_profile_v4_evaluations)
        restored[:arc1_profile_v3_evaluations] === restored[:arc1_profile_v4_evaluations] ||
            throw(ArgumentError("restored v3/v4 profile aliases do not share object identity"))
    end
    return restored
end

"""Split an executor artifact into independently checked native sections."""
function arc1_write_artifact_container_new(path::AbstractString, artifact)
    refs = arc1_container_reference_table(artifact)
    evidence = hasproperty(artifact, :v3_profile_evidence) ? artifact.v3_profile_evidence : nothing
    history = nothing
    if evidence isa AbstractDict
        history = get(evidence, :arc1_profile_v3_evaluations,
            get(evidence, :arc1_profile_v4_evaluations, nothing))
        history isa AbstractVector || (history = nothing)
    end
    history_rows, event_stream = history === nothing ? (nothing, nothing) :
        arc1_container_pack_evaluations(history, refs)
    fields = Dict{Symbol,Any}()
    for name in propertynames(artifact)
        name in (:metadata, :result, :profile, :data, :design, :v3_profile_evidence,
                 :receipt_summary) && continue
        fields[name] = getproperty(artifact, name)
    end
    hasproperty(artifact, :metadata) && (fields[:metadata] = artifact.metadata)
    hasproperty(artifact, :data) && (fields[:data] = artifact.data)
    hasproperty(artifact, :design) && (fields[:design] = artifact.design)
    hasproperty(artifact, :profile) && (fields[:profile] = artifact.profile)
    certificates_present = evidence isa AbstractDict && haskey(evidence, :v4_tail_certificates)
    certificates = certificates_present ? evidence[:v4_tail_certificates] : nothing
    evidence_without_certificates = if evidence isa AbstractDict
        copied = copy(evidence)
        pop!(copied, :v4_tail_certificates, nothing)
        copied
    else
        evidence
    end
    stripped_evidence = arc1_container_strip_history(evidence_without_certificates, refs)
    result = hasproperty(artifact, :result) ? artifact.result : nothing
    if result !== nothing && hasproperty(result, :v3_profile_evidence) &&
       result.v3_profile_evidence !== nothing
        result.v3_profile_evidence === evidence || throw(ArgumentError(
            "raw result does not reference the original evidence object"))
        result = merge(result, (; v3_profile_evidence=Arc1ContainerRef(refs["evidence"])))
    end
    summary = hasproperty(artifact, :receipt_summary) ? artifact.receipt_summary : nothing
    if summary !== nothing && hasproperty(summary, :v3_profile_evidence) &&
       summary.v3_profile_evidence !== nothing
        summary.v3_profile_evidence === evidence || throw(ArgumentError(
            "embedded summary does not reference the original evidence object"))
        summary = merge(summary, (; v3_profile_evidence=Arc1ContainerRef(refs["evidence"])))
    end
    sections = Dict{String,Any}("references" => refs)
    for (name, value) in fields
        sections[String(name)] = value
    end
    hasproperty(artifact, :result) && (sections["result"] = result)
    hasproperty(artifact, :receipt_summary) && (sections["summary"] = summary)
    evidence === nothing || (sections["evidence"] = stripped_evidence)
    certificates_present && (sections["tail_certificate_inputs"] = certificates)
    history_rows === nothing || (sections["history_rows"] = history_rows)
    event_stream === nothing || (sections["history"] = event_stream)
    arc1_container_validate_artifact_sections(sections)
    return arc1_write_container_new(path, sections)
end

function arc1_read_artifact_container(path::AbstractString)
    sections = arc1_read_container(path)
    arc1_container_validate_artifact_sections(sections)
    refs = get(sections, "references", Dict{String,UInt64}())
    arc1_container_validate_reference_categories(refs)
    evidence = get(sections, "evidence", nothing)
    reserved = Set(("references", "evidence", "history", "history_rows",
        "result", "summary", "tail_certificate_inputs"))
    fields = Dict{Symbol,Any}(Symbol(key) => value for (key, value) in sections
        if !(key in reserved))
    history = get(sections, "history", nothing)
    evidence = arc1_container_restore_history(evidence, nothing, refs)
    if evidence !== nothing && (haskey(evidence, :arc1_profile_v3_evaluations) ||
                                haskey(evidence, :arc1_profile_v4_evaluations))
        rows = get(sections, "history_rows", nothing)
        events = get(sections, "history", nothing)
        evaluations = arc1_container_restore_evaluations(rows, events, refs)
        for key in (:arc1_profile_v3_evaluations, :arc1_profile_v4_evaluations)
            haskey(evidence, key) && (evidence[key] = evaluations)
        end
        haskey(evidence, :arc1_profile_v3_evaluations) && haskey(evidence, :arc1_profile_v4_evaluations) &&
            evidence[:arc1_profile_v3_evaluations] === evidence[:arc1_profile_v4_evaluations] ||
                throw(ArgumentError("container did not restore the original v3/v4 history alias"))
    end
    has_certificate_section = haskey(sections, "tail_certificate_inputs")
    if evidence isa AbstractDict && haskey(evidence, :v4_tail_certificates)
        throw(ArgumentError("profile tail certificates must come only from the separate certificate section"))
    end
    has_certificate_section && !(evidence isa AbstractDict) && throw(ArgumentError(
        "separate profile certificate section requires a profile evidence section"))
    has_certificate_section && (evidence[:v4_tail_certificates] = sections["tail_certificate_inputs"])
    if evidence !== nothing
        fields[:v3_profile_evidence] = evidence
    end
    result = get(sections, "result", nothing)
    if result !== nothing && hasproperty(result, :v3_profile_evidence) &&
       result.v3_profile_evidence !== nothing
        marker = result.v3_profile_evidence
        marker isa Arc1ContainerRef && marker.id == get(refs, "evidence", nothing) ||
            throw(ArgumentError("raw result evidence reference ID differs"))
        result = merge(result, (; v3_profile_evidence=evidence))
    end
    result !== nothing && (fields[:result] = result)
    summary = get(sections, "summary", nothing)
    if summary !== nothing && hasproperty(summary, :v3_profile_evidence) &&
       summary.v3_profile_evidence !== nothing
        marker = summary.v3_profile_evidence
        marker isa Arc1ContainerRef && marker.id == get(refs, "evidence", nothing) ||
            throw(ArgumentError("embedded summary evidence reference ID differs"))
        summary = merge(summary, (; v3_profile_evidence=evidence))
    end
    summary !== nothing && (fields[:receipt_summary] = summary)
    return (; (key => value for (key, value) in fields)...)
end
