module HSquaredBLUPF90MultitraitPacket

# Prepare an opt-in BLUPF90/RENUMF90 starter packet for the Phase 4
# multivariate REML fixture.
#
# This script does NOT run BLUPF90, RENUMF90, or AIREMLF90. It only rewrites the
# committed CSV fixture into whitespace-delimited files plus a conservative
# starter renumf90.par template so an external comparator lane can run the same
# two-trait animal-model estimand when BLUPF90 executables are available. The
# generated BLUPF90-consumed files use numeric animal codes; the original IDs are
# preserved in a companion map for result alignment.
#
# Run from the repo root:
#
#   julia comparator/prepare_blupf90_multitrait.jl

using DelimitedFiles
using Printf

export BLUPF90_EXECUTABLES,
    generate_blupf90_multitrait_packet,
    probe_blupf90_executables,
    validate_blupf90_multitrait_packet

const ROOT = normpath(joinpath(@__DIR__, ".."))
const FIXTURE = joinpath(ROOT, "test", "fixtures", "phase4_multitrait_parity")
const OUT = joinpath(@__DIR__, "blupf90_multitrait")
const BLUPF90_EXECUTABLES = ("renumf90", "airemlf90", "blupf90", "remlf90", "gibbsf90")

function _read_csv(path)
    readdlm(path, ','; header = true)
end

function _write_lines(path, lines)
    open(path, "w") do io
        for line in lines
            println(io, line)
        end
    end
end

function _id_map(ids)
    return Dict(string(ids[i]) => i for i in eachindex(ids))
end

function _mapped_parent(parent, map)
    id = string(parent)
    return id == "0" ? 0 : map[id]
end

function _named_matrix(path)
    data, _ = _read_csv(path)
    names = string.(data[:, 1])
    values = Matrix{Float64}(undef, size(data, 1), size(data, 2) - 1)
    for i in axes(values, 1), j in axes(values, 2)
        values[i, j] = parse(Float64, string(data[i, j + 1]))
    end
    return names, values
end

function _read_numeric_lines(path)
    lines = filter(!isempty, strip.(readlines(path)))
    isempty(lines) && error("empty generated file: $path")
    any(startswith(line, "#") for line in lines) &&
        error("generated BLUPF90 data files must not contain comment lines: $path")
    return lines
end

function _parse_generated_matrix(path)
    lines = _read_numeric_lines(path)
    rows = split.(lines)
    widths = unique(length.(rows))
    length(widths) == 1 || error("ragged whitespace table: $path")
    return rows
end

function generate_blupf90_multitrait_packet(; fixture = FIXTURE, out = OUT)
    mkpath(out)

    ped, _ = _read_csv(joinpath(fixture, "pedigree.csv"))
    pheno, _ = _read_csv(joinpath(fixture, "phenotypes.csv"))
    _, G0 = _named_matrix(joinpath(fixture, "expected_genetic_covariance.csv"))
    _, R0 = _named_matrix(joinpath(fixture, "expected_residual_covariance.csv"))

    ped_ids = string.(ped[:, 1])
    map = _id_map(ped_ids)

    data_lines = String[]
    for i in axes(pheno, 1)
        animal = string(pheno[i, 2])
        haskey(map, animal) || error("phenotype animal `$animal` is absent from pedigree")
        row = (
            pheno[i, 4],
            pheno[i, 5],
            1,
            pheno[i, 3],
            map[animal],
        )
        push!(data_lines, join(string.(row), " "))
    end
    _write_lines(joinpath(out, "blupf90_multitrait.dat"), data_lines)

    ped_lines = String[]
    for i in axes(ped, 1)
        animal = map[string(ped[i, 1])]
        sire = _mapped_parent(ped[i, 2], map)
        dam = _mapped_parent(ped[i, 3], map)
        push!(ped_lines, join(string.((animal, sire, dam)), " "))
    end
    _write_lines(joinpath(out, "blupf90_multitrait.ped"), ped_lines)

    map_lines = ["animal,code"]
    for id in ped_ids
        push!(map_lines, string(id, ",", map[id]))
    end
    _write_lines(joinpath(out, "animal_id_map.csv"), map_lines)

    target_lines = String["quantity,row,column,value"]
    for i in 1:2, j in 1:2
        push!(target_lines, @sprintf("G0,trait%d,trait%d,%.15g", i, j, G0[i, j]))
    end
    for i in 1:2, j in 1:2
        push!(target_lines, @sprintf("R0,trait%d,trait%d,%.15g", i, j, R0[i, j]))
    end
    _write_lines(joinpath(out, "hsquared_targets.csv"), target_lines)

    renum_lines = [
        "DATAFILE blupf90_multitrait.dat",
        "TRAITS",
        "1 2",
        "FIELDS_PASSED TO OUTPUT",
        "3 4 5",
        "RESIDUAL_VARIANCE",
        @sprintf("%.15g %.15g", R0[1, 1], R0[1, 2]),
        @sprintf("%.15g %.15g", R0[2, 1], R0[2, 2]),
        "EFFECT",
        "3 3 cross numer",
        "EFFECT",
        "4 4 cov",
        "EFFECT",
        "5 5 cross numer",
        "RANDOM",
        "animal",
        "FILE",
        "blupf90_multitrait.ped",
        "(CO)VARIANCES",
        @sprintf("%.15g %.15g", G0[1, 1], G0[1, 2]),
        @sprintf("%.15g %.15g", G0[2, 1], G0[2, 2]),
        "OPTION method VCE",
    ]
    _write_lines(joinpath(out, "renumf90.par"), renum_lines)

    return validate_blupf90_multitrait_packet(; fixture, out)
end

function validate_blupf90_multitrait_packet(; fixture = FIXTURE, out = OUT)
    ped, _ = _read_csv(joinpath(fixture, "pedigree.csv"))
    pheno, _ = _read_csv(joinpath(fixture, "phenotypes.csv"))
    _, expected_G0 = _named_matrix(joinpath(fixture, "expected_genetic_covariance.csv"))
    _, expected_R0 = _named_matrix(joinpath(fixture, "expected_residual_covariance.csv"))

    data_rows = _parse_generated_matrix(joinpath(out, "blupf90_multitrait.dat"))
    ped_rows = _parse_generated_matrix(joinpath(out, "blupf90_multitrait.ped"))
    map_data, map_header = _read_csv(joinpath(out, "animal_id_map.csv"))
    map_header == ["animal" "code"] || error("animal_id_map.csv has unexpected header")
    length(data_rows) == size(pheno, 1) ||
        error("BLUPF90 data row count does not match fixture phenotypes")
    length(ped_rows) == size(ped, 1) ||
        error("BLUPF90 pedigree row count does not match fixture pedigree")
    all(length(row) == 5 for row in data_rows) ||
        error("BLUPF90 data rows must be trait1 trait2 intercept x animal_code")
    all(length(row) == 3 for row in ped_rows) ||
        error("BLUPF90 pedigree rows must be animal_code sire_code dam_code")
    all(row[3] == "1" for row in data_rows) ||
        error("BLUPF90 data intercept column must be all ones")
    all(!isnothing(tryparse(Float64, value)) for row in data_rows for value in row) ||
        error("BLUPF90 data rows must be numeric")
    all(!isnothing(tryparse(Int, value)) for row in ped_rows for value in row) ||
        error("BLUPF90 pedigree rows must use integer-coded IDs")
    size(map_data, 1) == size(ped, 1) ||
        error("animal ID map row count does not match fixture pedigree")
    Set(string.(map_data[:, 1])) == Set(string.(ped[:, 1])) ||
        error("animal ID map does not match pedigree IDs")

    target_data, _ = _read_csv(joinpath(out, "hsquared_targets.csv"))
    target_values = Dict{Tuple{String, Int, Int}, Float64}()
    for i in axes(target_data, 1)
        quantity = string(target_data[i, 1])
        row = parse(Int, replace(string(target_data[i, 2]), "trait" => ""))
        col = parse(Int, replace(string(target_data[i, 3]), "trait" => ""))
        target_values[(quantity, row, col)] = parse(Float64, string(target_data[i, 4]))
    end
    for i in 1:2, j in 1:2
        target_values[("G0", i, j)] == expected_G0[i, j] ||
            error("G0 target mismatch at ($i, $j)")
        target_values[("R0", i, j)] == expected_R0[i, j] ||
            error("R0 target mismatch at ($i, $j)")
    end

    renum = readlines(joinpath(out, "renumf90.par"))
    any(isempty(strip(line)) for line in renum) &&
        error("renumf90.par should avoid blank records in the starter template")
    any(startswith(strip(line), "#") for line in renum) &&
        error("renumf90.par should avoid comment records in the starter template")
    required = [
        "DATAFILE blupf90_multitrait.dat",
        "TRAITS",
        "RESIDUAL_VARIANCE",
        "EFFECT",
        "RANDOM",
        "animal",
        "FILE",
        "blupf90_multitrait.ped",
        "(CO)VARIANCES",
        "OPTION method VCE",
    ]
    for token in required
        token in renum || error("renumf90.par missing required record: $token")
    end

    return (
        output_dir = out,
        n_records = size(pheno, 1),
        n_pedigree = size(ped, 1),
        G0 = expected_G0,
        R0 = expected_R0,
    )
end

function probe_blupf90_executables(names = BLUPF90_EXECUTABLES)
    return Dict(name => Sys.which(name) for name in names)
end

function main()
    packet = generate_blupf90_multitrait_packet()
    executables = probe_blupf90_executables()

    println("Wrote BLUPF90 starter packet to ", packet.output_dir)
    println("Validated packet: $(packet.n_records) phenotype rows, $(packet.n_pedigree) pedigree rows.")
    println("BLUPF90-family executable probe:")
    for name in BLUPF90_EXECUTABLES
        path = executables[name]
        println("  ", rpad(name, 10), isnothing(path) ? "not found" : path)
    end
    println("Next manual steps, if renumf90 and airemlf90 are on PATH:")
    println("  cd ", packet.output_dir)
    println("  renumf90 renumf90.par")
    println("  airemlf90 renf90.par")
    println("Compare resulting G0/R0/beta/solutions to hsquared_targets.csv and the fixture expected_*.csv files.")
    return packet
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    HSquaredBLUPF90MultitraitPacket.main()
end
