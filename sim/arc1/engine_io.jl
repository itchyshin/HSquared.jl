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
    if value isa Enum
        # Keep Julia enum identity explicit instead of relying on Integer
        # subtyping or rejecting optimizer-native diagnostic leaves.
        return "{\"__arc1_enum__\":{\"type\":" *
            arc1_json_escape(string(typeof(value))) * ",\"name\":" *
            arc1_json_escape(string(value)) * ",\"value\":" * string(Int(value)) * "}}"
    end
    if value isa Rational
        exact = Rational{BigInt}(value)
        return "{\"__arc1_rational__\":{\"numerator\":" *
            arc1_json_escape(string(numerator(exact))) * ",\"denominator\":" *
            arc1_json_escape(string(denominator(exact))) * ",\"type\":" *
            arc1_json_escape(string(typeof(value))) * "}}"
    end
    if value isa BigFloat
        if !isfinite(value)
            return "{\"__arc1_float__\":" * arc1_json_escape(string(value)) * "}"
        end
        exact = Rational{BigInt}(value)
        return "{\"__arc1_bigfloat__\":{\"numerator\":" *
            arc1_json_escape(string(numerator(exact))) * ",\"denominator\":" *
            arc1_json_escape(string(denominator(exact))) * ",\"precision\":" *
            string(precision(value)) * "}}"
    end
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

"""Project one receipt; a failed projection yields a primitive-only terminal record."""
function arc1_receipt_json(receipt; fallback_fields)
    try
        return arc1_json(receipt), nothing
    catch projection_error
        # This fallback is deliberately assembled only from scalar strings,
        # booleans, and nulls. Do not retry conversion of the failed payload.
        safe_text(value, default="") = value isa AbstractString ? String(value) : default
        safe_optional_text(value) = value isa AbstractString ? String(value) : nothing
        safe_integer(value, default=-1) = value isa Integer && !(value isa Bool) ? Int(value) : default
        preserve_original = Bool(fallback_fields.preserve_original_error)
        projection_message = sprint(showerror, projection_error)
        retention = safe_text(fallback_fields.retention_error)
        retention = isempty(retention) ? projection_message :
            string(retention, "; JSON receipt projection failed: ", projection_message)
        fallback = merge((; schema="arc1-attempt-result-v1", success=false,
            mode=safe_text(fallback_fields.mode, "unknown"),
            outer=safe_integer(fallback_fields.outer),
            seed_string=safe_text(fallback_fields.seed_string),
            status=preserve_original ? safe_text(fallback_fields.status, "error") : "error",
            failure_reason=preserve_original ? safe_text(fallback_fields.failure_reason, projection_message) : projection_message,
            error_type=preserve_original ? safe_text(fallback_fields.error_type, "unknown") : string(typeof(projection_error)),
            requested_profile_method_version=safe_optional_text(fallback_fields.requested_profile_method_version),
            profile_method_version=safe_optional_text(fallback_fields.profile_method_version),
            profile_method_version_mismatch=fallback_fields.profile_method_version_mismatch === true,
            profile_source_identity=safe_optional_text(fallback_fields.profile_source_identity),
            loaded_arc1_source_identity=safe_optional_text(fallback_fields.loaded_arc1_source_identity),
            artifact_path=safe_text(fallback_fields.artifact_path, ""),
            artifact_sha256=safe_optional_text(fallback_fields.artifact_sha256),
            v3_evidence_retention_error=string(retention)),
            (; receipt_projection_error=projection_message))
        return arc1_json(fallback), projection_error
    end
end

"""Write one receipt; if projection fails, emit a primitive-only terminal record."""
function arc1_emit_receipt(receipt; fallback_fields)
    text, projection_error = arc1_receipt_json(receipt; fallback_fields)
    write(stdout, text, '\n')
    return projection_error
end

function arc1_artifact_sha256(path::AbstractString)
    context = SHA.SHA2_256_CTX()
    open(path, "r") do io
        while !eof(io)
            SHA.update!(context, read(io, 1024 * 1024))
        end
    end
    return bytes2hex(SHA.digest!(context))
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
