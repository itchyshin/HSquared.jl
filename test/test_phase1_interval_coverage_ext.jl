# Thin scaffold test for C1-ext / H1+H3. Not included from runtests.jl
# (keeps the CI suite RNG-free and avoids touching the shared 10k-line file).
#
#   julia --project=. -e 'using Test; include("test/test_phase1_interval_coverage_ext.jl")'
#
# Optional 1-rep path smoke (not a claim; may take ~1 min):
#   HSQUARED_C1EXT_SMOKE=1 julia --project=. -e 'using Test; include("test/test_phase1_interval_coverage_ext.jl")'

using Test

include(joinpath(@__DIR__, "..", "sim", "phase1_interval_coverage_ext.jl"))

@testset "C1-ext H1/H3 harness scaffold" begin
    @test EXT_INTERPRETABLE_FRACTION == 0.9
    @test EXT_CONFIRM_REPS_TARGET == 2000
    @test EXT_SEED_STRIDE == 40_009
    @test EXT_PROMOTABLE_LEVEL == 0.95
    @test Set(EXT_CAMPAIGNS) == Set((:h1_two, :h1_multi, :h1_t, :h3_rg, :h3_ram))

    roles = Dict(row[2] => row[6] for row in SYMBOLIC_ALIGNMENT)
    @test roles["t"] == "characterization_only"
    @test roles["ratio1"] == "covered_pillar_bank"
    @test roles["r_g"] == "covered_pillar_bank"
    @test roles["r_am"] == "covered_pillar_bank"
    @test all(row[1] in EXT_CAMPAIGNS for row in SYMBOLIC_ALIGNMENT)

    cfg = _parse_args(String[])
    @test cfg.mode === :smoke
    @test cfg.reps == 1
    @test cfg.seed == 20260903
    @test cfg.campaigns == collect(EXT_CAMPAIGNS)
    @test cfg.levels == [0.95]
    @test occursin("c1ext-smoke.tsv", cfg.output)

    cfg2 = _parse_args(["--mode=screen", "--campaigns=h1_two,h3_rg", "--reps=10"])
    @test cfg2.mode === :screen
    @test cfg2.reps == 10
    @test cfg2.campaigns == [:h1_two, :h3_rg]

    @test_throws ErrorException _parse_args(["--campaigns=h1_nbinom"])
    @test_throws ErrorException _parse_args(["--mode=promote"])

    s1 = _rep_seed(20260903, 1, 1, 1)
    s2 = _rep_seed(20260903, 1, 1, 2)
    @test s1 != s2
    @test abs(s2 - s1) < EXT_SEED_STRIDE

    @test length(_h1_two_cells(:smoke)) == 1
    @test all(c.scope == "interior" for c in _h1_two_cells(:smoke))
    @test any(c.scope == "boundary" for c in _h1_two_cells(:confirm))
    @test all(c.scope == "characterization_not_covered" for c in _h1_t_cells(:smoke))
    @test _h1_multi_cells(:smoke)[1].k == 2
    @test _h1_multi_cells(:confirm)[1].k == 3
end

if get(ENV, "HSQUARED_C1EXT_SMOKE", "0") == "1"
    @testset "C1-ext smoke path (not a claim)" begin
        mktempdir() do dir
            out = joinpath(dir, "c1ext-smoke.tsv")
            path = main([
                "--mode=smoke",
                "--reps=1",
                "--seed=20260903",
                "--campaigns=h1_two,h1_multi",
                "--out=$(out)",
                "--resume=false",
            ])
            @test isfile(path)
            header = readline(path)
            @test occursin("non_interpretable", header)
            @test occursin("claim_eligible", header)
            body = read(path, String)
            @test occursin("false", body)  # claim_eligible stays false
            @test occursin("h1_two", body)
        end
    end
end
