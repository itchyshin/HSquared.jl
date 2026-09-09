using Test

include(joinpath(@__DIR__, "..", "sim", "h1two_identified_campaign.jl"))

@testset "identified H1-two S11 campaign receipt" begin
    @test H1T_S11_REPS == 2000
    @test H1T_S11_SEED_START == 202609100001
    @test H1T_S11_SEED_START + H1T_S11_REPS - 1 == 202609102000

    rows = h1two_identified_campaign_rep(H1T_S11_SEED_START)
    @test length(rows) == 2
    @test Set(getfield.(rows, :estimand)) == Set(("ratio1", "ratio2"))
    @test all(row -> row.seed == H1T_S11_SEED_START, rows)
    @test all(row -> row.claim_eligible === false, rows)
    @test all(row -> row.fit_success, rows)
    @test all(row -> row.fit_converged, rows)
    @test all(row -> row.interval_success, rows)
    @test all(row -> isfinite(row.lower) && isfinite(row.upper) && 0 < row.lower < row.upper < 1, rows)

    @test_throws ArgumentError h1two_identified_campaign_rep(H1T_S11_SEED_START - 1)
    @test_throws ArgumentError h1two_identified_campaign_rep(H1T_S11_SEED_START + H1T_S11_REPS)

    mktempdir() do dir
        path = write_h1two_identified_campaign_receipt(joinpath(dir, "rep.tsv");
                                                        seed = H1T_S11_SEED_START)
        lines = readlines(path)
        @test lines[1] == join(H1T_S11_RECEIPT_COLUMNS, '\t')
        @test length(lines) == 3
        @test all(occursin("\tfalse", line) for line in lines[2:3])
    end
end

println("H1T_IDENTIFIED_S11_TESTS_OK")
