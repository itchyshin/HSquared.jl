using Test

include(joinpath(@__DIR__, "..", "tools", "reconcile_h1two_identified_s11.jl"))

@testset "identified H1-two S11 retained reconciliation" begin
    seeds = H1T_S11_SEED_START:(H1T_S11_SEED_START + 1)
    mktempdir() do dir
        for seed in seeds
            write_h1two_identified_campaign_receipt(joinpath(dir, "rep-$(seed).tsv"); seed = seed)
        end
        summary = reconcile_h1t_s11(dir; seeds = collect(seeds))
        @test summary.requested_reps == 2
        @test summary.retained_rows == 4
        @test summary.expected_rows == 4
        @test summary.fit_success <= summary.requested_reps * 2
        @test summary.interval_success <= summary.fit_success
        @test !summary.claim_eligible
        @test 0 <= summary.coverage <= 1 || isnan(summary.coverage)

        cp(joinpath(dir, "rep-$(first(seeds)).tsv"), joinpath(dir, "duplicate.tsv"))
        @test_throws ArgumentError reconcile_h1t_s11(dir; seeds = collect(seeds))
    end
end

println("H1T_S11_RECONCILE_TESTS_OK")
