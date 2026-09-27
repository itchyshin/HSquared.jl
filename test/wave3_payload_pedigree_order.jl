using Test
using LinearAlgebra
using HSquared

@testset "payload-v2 pedigree precision follows block ID order" begin
    pedigree = Dict(
        "id" => ["calf", "sire", "dam"],
        "sire" => ["sire", "0", "0"],
        "dam" => ["dam", "0", "0"],
    )
    ids = ["calf", "sire", "dam"]
    Z = Matrix{Float64}(I, 3, 3)
    block = Dict(
        "name" => "animal", "type" => "pedigree", "Z" => Z,
        "relmat_status" => "build_in_julia", "pedigree" => pedigree,
        "ids" => ids,
    )
    payload = Dict("payload_version" => 2, "y" => [1.0, 2.0, 3.0],
                   "X" => ones(3, 1), "random_effects" => [block])

    parsed = parse_payload_v2(payload)
    animal = only(parsed.blocks)
    normalized = normalize_pedigree(pedigree["id"], pedigree["sire"], pedigree["dam"])
    permutation = [findfirst(==(id), normalized.ids) for id in ids]
    A_oracle = inv(Matrix(pedigree_inverse(normalized)))[permutation, permutation]

    @test animal.ids == ids
    @test Z * inv(Matrix(animal.relmat_inverse)) * Z' ≈ Z * A_oracle * Z'
    @test animal.relationship_diag ≈ diag(A_oracle)

    sorted_block = copy(block)
    sorted_block["ids"] = normalized.ids
    sorted = copy(payload)
    sorted["random_effects"] = [sorted_block]
    sorted_animal = only(parse_payload_v2(sorted).blocks)
    @test Matrix(sorted_animal.relmat_inverse) ≈ Matrix(pedigree_inverse(normalized))

    for bad_ids in (["calf", "sire", "other"], ["calf", "sire", "sire"])
        bad_block = copy(block)
        bad_block["ids"] = bad_ids
        bad = copy(payload)
        bad["random_effects"] = [bad_block]
        @test_throws ArgumentError parse_payload_v2(bad)
    end

    legacy = Dict("y" => payload["y"], "X" => payload["X"], "Z" => Z,
                  "pedigree" => pedigree, "ids" => ids,
                  "metadata" => Dict("ainv_status" => "build_in_julia"))
    legacy_animal = only(parse_payload_v2(legacy).blocks)
    @test Z * inv(Matrix(legacy_animal.relmat_inverse)) * Z' ≈ Z * A_oracle * Z'

    legacy_without_ids = copy(legacy)
    delete!(legacy_without_ids, "ids")
    inferred = only(parse_payload_v2(legacy_without_ids).blocks)
    @test inferred.ids == ids
    @test Matrix(inferred.relmat_inverse) ≈ Matrix(legacy_animal.relmat_inverse)
end

@testset "legacy maternal alias preserves pedigree labels" begin
    pedigree = Dict(
        "id" => ["offspring", "p", "q", "parent"],
        "sire" => ["p", "0", "0", "p"],
        "dam" => ["parent", "0", "0", "q"],
    )
    ids = pedigree["id"]
    Z = Matrix{Float64}(I, 4, 4)
    payload = Dict("y" => [1.0, 2.0, 3.0, 4.0], "X" => ones(4, 1),
                   "Z" => Z, "Z2" => Z, "pedigree" => pedigree, "ids" => ids,
                   "effect2" => Dict("relationship" => "pedigree", "group" => "maternal",
                                     "levels" => ids),
                   "metadata" => Dict("ainv_status" => "build_in_julia"))

    parsed = parse_payload_v2(payload)
    @test parsed.dispatch == :two_effect
    @test parsed.blocks[2].ids == ids
    @test Matrix(parsed.blocks[2].relmat_inverse) == Matrix(parsed.blocks[1].relmat_inverse)
    @test parsed.blocks[2].relationship_diag == parsed.blocks[1].relationship_diag

    ids2 = ["parent", "offspring", "q", "p"]
    payload["ids2"] = ids2
    reordered = parse_payload_v2(payload).blocks
    order = [findfirst(==(id), ids) for id in ids2]
    @test reordered[2].ids == ids2
    @test Matrix(reordered[2].relmat_inverse) ≈
          Matrix(reordered[1].relmat_inverse)[order, order]
    @test reordered[2].relationship_diag == reordered[1].relationship_diag[order]
    @test reordered[2].relationship_diag[2] ≈ 1.25

    for bad_ids in (["parent", "offspring", "p", "p"],
                    ["parent", "offspring", "q", "other"])
        bad = copy(payload)
        bad["ids2"] = bad_ids
        @test_throws ArgumentError parse_payload_v2(bad)
    end

    supplied = copy(payload)
    supplied["metadata"] = Dict("ainv_status" => "supplied")
    supplied["Ainv"] = reordered[1].relmat_inverse
    supplied_blocks = parse_payload_v2(supplied).blocks
    @test Matrix(supplied_blocks[1].relmat_inverse) == Matrix(supplied["Ainv"])
    @test Matrix(supplied_blocks[2].relmat_inverse) ≈ Matrix(supplied["Ainv"])[order, order]
    @test supplied_blocks[1].relationship_diag === nothing
    @test supplied_blocks[2].relationship_diag === nothing

    iid = copy(payload)
    iid["effect2"] = Dict("relationship" => "identity", "group" => "litter")
    delete!(iid, "ids2")
    iid_block = parse_payload_v2(iid).blocks[2]
    @test iid_block.ids == collect(1:4)
    @test Matrix(iid_block.relmat_inverse) == Matrix{Float64}(I, 4, 4)
end

@testset "single iid block cannot become an animal model" begin
    payload = Dict("payload_version" => 2, "y" => [1.0, 2.0],
                   "X" => ones(2, 1), "random_effects" => [Dict(
                       "name" => "litter", "type" => "iid",
                       "Z" => Matrix{Float64}(I, 2, 2),
                       "relmat_status" => "identity", "ids" => ["a", "b"],
                   )])
    error = try
        parse_payload_v2(payload)
        nothing
    catch err
        err
    end
    @test error isa ArgumentError
    @test occursin("single-block animal dispatch requires a pedigree block", sprint(showerror, error))
end

@testset "payload-v2 pedigree self-relationships follow block ID order" begin
    pedigree = Dict(
        "id" => ["offspring", "p", "q", "parent"],
        "sire" => ["p", "0", "0", "p"],
        "dam" => ["parent", "0", "0", "q"],
    )
    ids = pedigree["id"]
    block = Dict(
        "name" => "animal", "type" => "pedigree",
        "Z" => Matrix{Float64}(I, 4, 4),
        "relmat_status" => "build_in_julia", "pedigree" => pedigree,
        "ids" => ids,
    )
    payload = Dict("payload_version" => 2, "y" => ones(4),
                   "X" => ones(4, 1), "random_effects" => [block])
    animal = only(parse_payload_v2(payload).blocks)
    normalized = normalize_pedigree(pedigree["id"], pedigree["sire"], pedigree["dam"])
    order = [findfirst(==(id), normalized.ids) for id in ids]
    A_oracle = inv(Matrix(pedigree_inverse(normalized)))[order, order]

    @test animal.relationship_diag ≈ diag(A_oracle)
    @test animal.relationship_diag[1] ≈ 1.25
end
