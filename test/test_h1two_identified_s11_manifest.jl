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
    @test manifest["routing"]["cluster"] == "narval"
    @test manifest["routing"]["project_dir"] == "/project/6098264/snakagaw/hsq09-h1t-identified-s11-36ae0691"
    @test manifest["authorization"]["s11_campaign"] === true
    @test manifest["authorization"]["promotion"] === false
    @test manifest["authorization"]["release"] === false
    @test h1t_s11_manifest_self_test()

    source = read(H1T_S11_MANIFEST_PATH, String)
    mktempdir() do dir
        unknown_key = joinpath(dir, "unknown-key.toml")
        write(unknown_key, source * "\n[unreviewed]\nclaim = \"not-governed\"\n")
        @test_throws ErrorException _h1t_s11_validate(unknown_key)

        changed_interpretation = joinpath(dir, "changed-interpretation.toml")
        write(changed_interpretation,
              replace(source,
                      "calibration_decision = \"deferred_to_Fisher_Rose_and_maintainer\"" =>
                      "calibration_decision = \"calibrated\""; count = 1))
        @test_throws ErrorException _h1t_s11_validate(changed_interpretation)
    end
end

println("H1T_S11_MANIFEST_TESTS_OK")
