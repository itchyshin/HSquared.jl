using Test

include(joinpath(@__DIR__, "..", "tools", "validate_h1two_identified_s11_manifest.jl"))

@testset "identified H1-two S11 manifest" begin
    manifest = h1t_s11_manifest()
    @test manifest["manifest"]["id"] == "HSQ09-H1T-IDENTIFIED-S11-01"
    @test manifest["candidate"]["julia_commit"] == "36ae0691c9e4d30dda8947e162716ebaf30de762"
    @test manifest["fixture"]["seed_start"] == 202609100001
    @test manifest["fixture"]["reps"] == 2000
    @test manifest["fixture"]["sires"] == 20
    @test manifest["fixture"]["offspring"] == 200
    @test manifest["fixture"]["groups"] == 40
    @test manifest["routing"]["array_tasks"] == 2000
    @test manifest["routing"]["cpus_per_task"] == 1
    @test manifest["authorization"]["s11_campaign"] === true
    @test manifest["authorization"]["promotion"] === false
    @test manifest["authorization"]["release"] === false
    @test h1t_s11_manifest_self_test()
end

println("H1T_S11_MANIFEST_TESTS_OK")
