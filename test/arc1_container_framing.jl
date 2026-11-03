using Test
using SHA
using Serialization
using HSquared

if !isdefined(@__MODULE__, :arc1_write_container_new)
    const ARC1_FRAMING_REPO = normpath(joinpath(@__DIR__, ".."))
    include(joinpath(ARC1_FRAMING_REPO, "sim", "arc1", "engine_io.jl"))
    include(joinpath(ARC1_FRAMING_REPO, "sim", "arc1", "artifact_container.jl"))
end

function _arc1_framing_read_directory(path)
    bytes = read(path)
    io = IOBuffer(bytes)
    read(io, length(ARC1_CONTAINER_MAGIC)) == ARC1_CONTAINER_MAGIC ||
        error("invalid baseline magic")
    arc1_container_read_u16(io) == ARC1_CONTAINER_VERSION ||
        error("invalid baseline version")
    count = Int(arc1_container_read_u16(io))
    entries = NamedTuple[]
    for _ in 1:count
        name, schema = arc1_container_read_string(io), arc1_container_read_string(io)
        offset, len, records = arc1_container_read_u64(io),
            arc1_container_read_u64(io), arc1_container_read_u64(io)
        digest = read(io, 32)
        push!(entries, (; name, schema, offset, length=len, records, digest))
    end
    payloads = [bytes[Int(entry.offset)+1:Int(entry.offset+entry.length)]
        for entry in entries]
    return entries, payloads
end

function _arc1_framing_mutate_directory(path, transform)
    entries, payloads = _arc1_framing_read_directory(path)
    entries = transform(entries)
    offsets = UInt64[entry.offset for entry in entries]
    directory = arc1_container_encode_directory(entries, offsets)
    open(path, "w") do output
        write(output, directory)
        foreach(payload -> write(output, payload), payloads)
    end
    return path
end

function _arc1_framing_rewrite_section(path, section_name, payload_transform)
    entries, payloads = _arc1_framing_read_directory(path)
    for i in eachindex(entries)
        if entries[i].name == section_name
            payloads[i] = payload_transform(payloads[i])
        end
        entries[i] = (; entries[i].name, entries[i].schema,
            entries[i].offset, length=UInt64(length(payloads[i])),
            entries[i].records, digest=SHA.sha256(payloads[i]))
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
    open(path, "w") do output
        write(output, directory)
        foreach(payload -> write(output, payload), payloads)
    end
    return path
end

function _arc1_framing_profile_row()
    return Dict{Symbol,Any}(:target => :heritability, :fixed_value => 0.5,
        :status => :ok, :events => Arc1ContainerRef(UInt64(2)),
        :producer_history => Arc1ContainerRef(UInt64(3)),
        :provenance_failures => Arc1ContainerRef(UInt64(4)),
        :event_lengths => Dict(:events => 1, :producer_history => 0,
            :provenance_failures => 0), :max_valid_loglik => -Inf,
        :max_valid_centered_loglik => -Inf)
end

function _arc1_framing_write_profile_container(path, row, history)
    refs = Dict("evidence.arc1_profile_v3_evaluations" => UInt64(1),
        "evidence.arc1_profile_v4_evaluations" => UInt64(1),
        "evaluation.1.events" => UInt64(2),
        "evaluation.1.producer_history" => UInt64(3),
        "evaluation.1.provenance_failures" => UInt64(4))
    evidence = Dict{Symbol,Any}(
        :arc1_profile_v3_evaluations => Arc1ContainerRef(UInt64(1)),
        :arc1_profile_v4_evaluations => Arc1ContainerRef(UInt64(1)))
    sections = Dict{String,Any}(
        "references" => refs, "evidence" => evidence,
        "history_rows" => Any[row], "history" => history)
    return arc1_write_container_new(path, sections)
end

@testset "Arc1 container framing rejects malformed header and directory" begin
    mktempdir() do directory
        baseline = joinpath(directory, "baseline.arc1c")
        arc1_write_container_new(baseline,
            Dict("alpha" => (; value=1), "beta" => (; value=2)))

        bad_magic = joinpath(directory, "bad-magic.arc1c")
        bad_magic_bytes = read(baseline)
        bad_magic_bytes[1] ⊻= 0x01
        write(bad_magic, bad_magic_bytes)
        @test_throws ArgumentError arc1_read_container(bad_magic)

        zero_sections = joinpath(directory, "zero-sections.arc1c")
        zero_section_bytes = read(baseline)
        section_count_start = length(ARC1_CONTAINER_MAGIC) + 3
        zero_section_bytes[section_count_start:section_count_start+1] .= 0x00
        write(zero_sections, zero_section_bytes)
        @test_throws ArgumentError arc1_read_container(zero_sections)

        bad_schema = cp(baseline, joinpath(directory, "bad-schema.arc1c"))
        _arc1_framing_mutate_directory(bad_schema, entries -> [
            merge(entries[1], (; schema="X" * entries[1].schema[2:end])), entries[2]])
        @test_throws ArgumentError arc1_read_container(bad_schema)

        oversized_records = cp(baseline,
            joinpath(directory, "oversized-record-count.arc1c"))
        _arc1_framing_mutate_directory(oversized_records, entries -> [
            merge(entries[1], (; records=UInt64(typemax(Int)) + UInt64(1))), entries[2]])
        @test_throws ArgumentError arc1_read_container(oversized_records)

        offset_gap = cp(baseline, joinpath(directory, "offset-gap.arc1c"))
        _arc1_framing_mutate_directory(offset_gap, entries -> [
            merge(entries[1], (; offset=entries[1].offset + UInt64(1))), entries[2]])
        @test_throws ArgumentError arc1_read_container(offset_gap)

        history_trailer = joinpath(directory, "history-section-trailer.arc1c")
        row = _arc1_framing_profile_row()
        history = Any[(; row_index=1, field=:events, event_index=1,
            event=(; value=:event))]
        _arc1_framing_write_profile_container(history_trailer, row, history)
        _arc1_framing_rewrite_section(history_trailer, "history",
            payload -> vcat(payload, UInt8[0xff]))
        message = try
            arc1_read_artifact_container(history_trailer)
            nothing
        catch error
            sprint(showerror, error)
        end
        @test message !== nothing
        @test occursin("history section has trailing bytes", something(message, ""))
    end
end
