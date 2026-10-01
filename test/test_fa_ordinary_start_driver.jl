module FaOrdinaryStartDriverTests

using Test

include(joinpath(@__DIR__, "..", "sim", "fa_ordinary_start_recovery_20260928.jl"))

@testset "FA ordinary-start driver retains nullable diagnostics" begin
    one_valid_start = (
        objective_range = nothing,
        uniqueness_floor_distance = 0.25,
        near_uniqueness_floor = false,
        g_relative_disagreement = nothing,
        r_relative_disagreement = nothing,
        better_nonconverged_start = false,
    )

    diagnostics = _diagnostic_values(one_valid_start)
    @test diagnostics.objective_range == "NA"
    @test diagnostics.uniqueness_floor_distance == "0.25"
    @test diagnostics.near_uniqueness_floor == "false"
    @test diagnostics.g_relative_disagreement == "NA"
    @test diagnostics.r_relative_disagreement == "NA"
    @test diagnostics.better_nonconverged_start == "false"
end

@testset "FA ordinary-start driver labels source and driver hashes" begin
    provenance = _source_provenance()
    @test occursin(r"^[0-9a-f]{64}$", provenance.source_tree_sha256)
    @test occursin(r"^[0-9a-f]{64}$", provenance.driver_sha256)
    @test provenance.source_tree_sha256 == _tree_sha256(
        joinpath(dirname(@__DIR__), "src"))
    @test provenance.driver_sha256 == bytes2hex(SHA.sha256(
        read(joinpath(dirname(@__DIR__), "sim", "fa_ordinary_start_recovery_20260928.jl"))))
end

@testset "FA ordinary-start driver retains simulation failures" begin
    row = _fit_seed(20261400, "primary";
        simulate = _ -> error("synthetic simulation failure"))

    @test length(row) == 23
    @test row[3] == "exception"
    @test row[5] == "false"
    @test row[17] == "NA"
    @test row[22] == "NA"
    @test occursin("synthetic simulation failure", row[23])
end

end
