# Small stdlib-only JSON writer for the Arc1 Python transport. The serialized
# Julia artifact remains the lossless authority; tagged values here prevent
# non-finite numbers and `missing` from being confused with `nothing`.
function arc1_json_escape(value::AbstractString)
    io = IOBuffer()
    write(io, '"')
    for c in value
        if c == '"' || c == '\\'
            write(io, '\\', c)
        elseif c == '\n'
            write(io, "\\n")
        elseif c == '\r'
            write(io, "\\r")
        elseif c == '\t'
            write(io, "\\t")
        elseif Int(c) < 0x20
            print(io, "\\u", string(Int(c), base=16, pad=4))
        else
            write(io, c)
        end
    end
    write(io, '"')
    return String(take!(io))
end

function arc1_json(value)
    value === nothing && return "null"
    value === missing && return "{\"__arc1_type__\":\"missing\"}"
    value isa Bool && return value ? "true" : "false"
    value isa Integer && return string(value) # UInt64 stays an exact decimal token.
    value isa AbstractFloat && return isfinite(value) ? string(value) :
        "{\"__arc1_float__\":" * arc1_json_escape(string(value)) * "}"
    value isa AbstractString && return arc1_json_escape(value)
    value isa Symbol && return arc1_json_escape(String(value))
    if value isa NamedTuple
        return arc1_json(Dict(string(k) => v for (k, v) in pairs(value)))
    elseif value isa AbstractDict
        entries = [arc1_json_escape(string(k)) * ":" * arc1_json(v)
                   for (k, v) in sort(collect(pairs(value)); by=p -> string(first(p)))]
        return "{" * join(entries, ",") * "}"
    elseif value isa Tuple
        return "[" * join((arc1_json(v) for v in value), ",") * "]"
    elseif value isa AbstractArray
        if ndims(value) <= 1
            return "[" * join((arc1_json(v) for v in value), ",") * "]"
        end
        data = "[" * join((arc1_json(v) for v in value), ",") * "]"
        dims = arc1_json(collect(size(value)))
        return "{\"__arc1_array__\":true,\"dims\":" * dims *
               ",\"layout\":\"julia_column_major\",\"data\":" * data * "}"
    end
    throw(ArgumentError("unsupported Arc1 JSON transport value $(typeof(value)); retain it in the Julia artifact"))
end

function arc1_artifact_sha256(path::AbstractString)
    return bytes2hex(sha256(read(path)))
end

function arc1_serialize_new(path::AbstractString, value)
    ispath(path) && throw(ArgumentError("refusing to replace existing Arc1 artifact: $path"))
    mkpath(dirname(path))
    temp, io = mktemp(dirname(path); cleanup=false)
    try
        serialize(io, value)
        flush(io)
        close(io)
        mv(temp, path; force=false)
    catch
        isopen(io) && close(io)
        ispath(temp) && rm(temp; force=true)
        rethrow()
    end
    return arc1_artifact_sha256(path)
end

function arc1_write_text_new(path::AbstractString, value::AbstractString)
    ispath(path) && throw(ArgumentError("refusing to replace existing Arc1 summary: $path"))
    mkpath(dirname(path))
    temp, io = mktemp(dirname(path); cleanup=false)
    try
        write(io, value)
        flush(io)
        close(io)
        mv(temp, path; force=false)
    catch
        isopen(io) && close(io)
        ispath(temp) && rm(temp; force=true)
        rethrow()
    end
    return bytes2hex(sha256(read(path)))
end
