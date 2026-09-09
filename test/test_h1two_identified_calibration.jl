using Test

include(joinpath(@__DIR__, "..", "sim", "h1two_identified_calibration.jl"))

@testset "ratified identified H1-two fixture" begin
    @test H1T_SEED == 20260701
    @test H1T_SIRES == 20
    @test H1T_OFFSPRING == 200
    @test H1T_GROUPS == 40
    @test H1T_TRUTH == (sigma1 = 1.0, sigma2 = 0.5, sigma_e2 = 1.0)

    result = h1two_identified_fixture()
    @test result.fit.converged
    for interval in (result.interval.ratio1, result.interval.ratio2)
        @test interval.boundary === false
        @test isfinite(interval.lower) && isfinite(interval.upper) && isfinite(interval.se)
        @test 0 < interval.lower < interval.estimate < interval.upper < 1
    end

    @test_throws ArgumentError h1two_identified_fixture(; seed = 1)
    @test_throws ArgumentError h1two_identified_fixture(; groups = 39)

    mktempdir() do dir
        path = write_h1two_identified_receipt(joinpath(dir, "receipt.tsv"))
        lines = readlines(path)
        @test lines[1] == join(H1T_RECEIPT_COLUMNS, '\t')
        @test length(lines) == 3
        @test all(occursin("\tfalse", line) for line in lines[2:3])
    end
end

println("H1T_IDENTIFIED_TESTS_OK")
