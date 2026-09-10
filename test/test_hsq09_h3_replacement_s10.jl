using Test

const H3_REPLACEMENT_S10_VALIDATOR = joinpath(@__DIR__, "..", "tools",
    "validate_hsq09_h3_replacement_s10.jl")

@testset "H3 replacement S10 contract" begin
    @test isfile(H3_REPLACEMENT_S10_VALIDATOR)
    include(H3_REPLACEMENT_S10_VALIDATOR)
    material = h3_replacement_s10_manifest()

    @test material["manifest"]["id"] == "HSQ09-H3-REPLACEMENT-S10-01"
    @test material["manifest"]["source_inert"] === true
    @test material["manifest"]["path_only"] === true
    @test material["authorization"]["s10"] === true
    @test all(material["authorization"][key] === false for key in
        ("s11", "promotion", "versioning", "tag", "registry", "release"))

    for (cell, seed, animals, records, iterations) in
            (("rg", 2026090901, 80, 240, 5000), ("ram", 2026090902, 996, 960, 200))
        spec = h3_replacement_s10_cell(cell)
        @test spec["seed"] == seed
        @test spec["animals"] == animals
        @test spec["records"] == records
        @test spec["iterations"] == iterations
        @test spec["threads"] == 1
        @test spec["path_only"] === true
        @test h3_replacement_s10_dry_run(cell)["cell"] == cell
    end
    @test_throws ArgumentError h3_replacement_s10_cell("h3_rg")
    @test h3_replacement_s10_mutation_test()
end

@testset "H3 replacement S10 Totoro launcher" begin
    launcher = joinpath(@__DIR__, "..", "tools", "run_hsq09_h3_replacement_s10_totoro.sh")
    @test isfile(launcher)
    source = read(launcher, String)
    @test occursin("JULIA_NUM_THREADS", source)
    @test occursin("OPENBLAS_NUM_THREADS", source)
    @test occursin("--validate-receipt", source)
    @test occursin("H3_REPLACEMENT_S10_FAILURE_RETAINED", source)
    @test occursin("--dry-run", source)
    @test !occursin("phase1_interval_coverage_ext", source)
    @test !occursin("h3_rg,h3_ram", source)
end

println("H3_REPLACEMENT_S10_TESTS_OK")
