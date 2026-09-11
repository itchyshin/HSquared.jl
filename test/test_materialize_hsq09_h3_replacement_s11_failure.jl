using Test

include(joinpath(@__DIR__, "..", "sim", "hsq09_h3_replacement_s11.jl"))
const FAILURE_TOOL = joinpath(@__DIR__, "..", "tools", "materialize_hsq09_h3_replacement_s11_failure.jl")

@testset "H3 S11 external scheduler-failure materialization" begin
    @test isdefined(@__MODULE__, :write_h3_replacement_s11_external_failure_receipt)
    isdefined(@__MODULE__, :write_h3_replacement_s11_external_failure_receipt) || return
    mktempdir() do dir
        receipt = joinpath(dir, "rep-202609120490.tsv")
        @test write_h3_replacement_s11_external_failure_receipt(
            receipt;
            cell="ram",
            seed=202609120490,
            failure_reason="scheduler_sigbus_nc10901",
        ) == receipt
        lines = readlines(receipt)
        @test length(lines) == 2
        fields = split(lines[2], '\t')
        @test fields[1] == H3_S11_ID
        @test fields[2] == "202609120490"
        @test fields[3] == "r_am"
        @test fields[6:12] == ["false", "false", "scheduler_sigbus_nc10901", "false", "NaN", "NaN", "NaN"]
        @test_throws ArgumentError write_h3_replacement_s11_external_failure_receipt(
            receipt;
            cell="ram",
            seed=202609120490,
            failure_reason="scheduler_sigbus_nc10901",
        )
        @test_throws ArgumentError write_h3_replacement_s11_external_failure_receipt(
            joinpath(dir, "bad-seed.tsv");
            cell="ram",
            seed=202609130001,
            failure_reason="scheduler_sigbus_nc10901",
        )
        @test_throws ArgumentError write_h3_replacement_s11_external_failure_receipt(
            joinpath(dir, "empty-reason.tsv");
            cell="ram",
            seed=202609120491,
            failure_reason="",
        )
    end
end

@testset "H3 S11 external scheduler-failure CLI" begin
    @test isfile(FAILURE_TOOL)
    isfile(FAILURE_TOOL) || return
    mktempdir() do dir
        receipt = joinpath(dir, "rep-202609120490.tsv")
        output = read(`$(Base.julia_cmd()) --project=$(joinpath(@__DIR__, "..")) $FAILURE_TOOL --cell=ram --seed=202609120490 --failure-reason=scheduler_sigbus_nc10901 --out=$receipt`, String)
        @test occursin("H3_REPLACEMENT_S11_EXTERNAL_FAILURE_RETAINED cell=ram seed=202609120490", output)
        @test isfile(receipt)
    end
end

println("H3_REPLACEMENT_S11_FAILURE_MATERIALIZATION_TESTS_OK")
