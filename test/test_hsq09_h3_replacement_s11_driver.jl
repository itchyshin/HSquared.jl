using Test

@testset "H3 S11 driver loads without executing a fit" begin
    include(joinpath(@__DIR__, "..", "sim", "hsq09_h3_replacement_s11.jl"))
    @test H3_S11_ID == "HSQ09-H3-REPLACEMENT-S11-01"
    @test length(H3_S11_RANGES["rg"]) == 2000
    @test length(H3_S11_RANGES["ram"]) == 2000
end

println("H3_REPLACEMENT_S11_DRIVER_TESTS_OK")
