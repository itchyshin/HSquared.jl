# HJ1 — bridge_payload_v2.jl dispatch and relmat tail branches.

using HSquared
using LinearAlgebra
using SparseArrays
using Test

function _ped_block(n = 2)
    return Dict{String, Any}(
        "name" => "animal",
        "type" => "pedigree",
        "relmat_status" => "supplied",
        "relmat_inverse" => sparse(1.0I, n, n),
        "ids" => ["id$i" for i in 1:n],
        "Z" => sparse(1.0I, n, n),
    )
end

function _iid_block(n = 2)
    return Dict{String, Any}(
        "name" => "pe",
        "type" => "iid",
        "relmat_status" => "identity",
        "ids" => ["lvl$i" for i in 1:n],
        "Z" => sparse(1.0I, n, n),
    )
end

function _correlated_block(n = 2)
    return Dict{String, Any}(
        "name" => "dm",
        "type" => "correlated",
        "relmat_status" => "supplied",
        "relmat_inverse" => sparse(1.0I, n, n),
        "ids" => ["id$i" for i in 1:n],
        "Z" => sparse(1.0I, n, n),
        "partner_incidence" => sparse(1.0I, n, n),
    )
end

function _base_payload(blocks; multivariate = false)
    body = Dict{String, Any}(
        "payload_version" => 2,
        "X" => ones(2, 1),
        "method" => "REML",
        "random_effects" => blocks,
    )
    if multivariate
        body["Y"] = [1.0 2.0; 3.0 4.0]
    else
        body["y"] = [1.0, 2.0]
    end
    return body
end

@testset "bridge payload v2 tail guards (HJ1)" begin
    @testset "dispatch rejects unsupported block mixes" begin
        @test_throws ArgumentError parse_payload_v2(_base_payload([
            _correlated_block(), _correlated_block(),
        ]))
        @test_throws ArgumentError parse_payload_v2(_base_payload([
            _correlated_block(), _ped_block(),
        ]))
        mix = _base_payload([_correlated_block(), _iid_block()])
        @test occursin("correlated", sprint(showerror, try
            parse_payload_v2(mix)
        catch e
            e
        end))
        @test_throws ArgumentError parse_payload_v2(Dict(
            "payload_version" => 2, "y" => [1.0], "X" => ones(1, 1),
            "method" => "REML", "random_effects" => [],
        ))
        two_coef = _base_payload([
            _ped_block(),
            Dict(
                "name" => "c1", "type" => "coefcov",
                "relmat_status" => "identity",
                "ids" => ["a", "b"],
                "Z" => sparse(1.0I, 2, 2),
                "basis" => "raw", "order" => 1,
                "Phi" => ones(2, 1), "covariate" => "age",
                "cov_structure" => "unstructured",
            ),
            Dict(
                "name" => "c2", "type" => "coefcov",
                "relmat_status" => "identity",
                "ids" => ["a", "b"],
                "Z" => sparse(1.0I, 2, 2),
                "basis" => "raw", "order" => 1,
                "Phi" => ones(2, 1), "covariate" => "weight",
                "cov_structure" => "unstructured",
            ),
        ])
        @test_throws ArgumentError parse_payload_v2(two_coef)
    end

    @testset "relmat_status supplied and unknown" begin
        bad = copy(_ped_block())
        bad["relmat_status"] = "supplied"
        delete!(bad, "relmat_inverse")
        @test_throws ArgumentError parse_payload_v2(_base_payload([bad]))
        unknown = copy(_ped_block())
        unknown["relmat_status"] = "bogus"
        @test_throws ArgumentError parse_payload_v2(_base_payload([unknown]))
    end

    @testset "pedigree build_in_julia field guards" begin
        block = copy(_ped_block())
        block["relmat_status"] = "build_in_julia"
        ped = Dict("id" => ["a", "b"], "sire" => ["0", "0"], "dam" => ["0", "0"])
        block["pedigree"] = ped
        block["ids"] = ped["id"]
        @test parse_payload_v2(_base_payload([block])).dispatch == :animal
        for field in ("id", "sire", "dam")
            ped = Dict("id" => ["a", "b"], "sire" => ["0", "0"], "dam" => ["0", "0"])
            delete!(ped, field)
            broken = copy(block)
            broken["pedigree"] = ped
            @test_throws ArgumentError parse_payload_v2(_base_payload([broken]))
        end
    end

    @testset "payload_version coercion" begin
        p = _base_payload([_ped_block()])
        p["payload_version"] = 2
        @test parse_payload_v2(p).dispatch == :animal
        p2 = copy(p)
        p2["payload_version"] = 3
        @test_throws ArgumentError parse_payload_v2(p2)
        p2["payload_version"] = true
        @test_throws ArgumentError parse_payload_v2(p2)
        p2["payload_version"] = "2"
        @test_throws ArgumentError parse_payload_v2(p2)
    end
end
