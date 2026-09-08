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
    @test any(
        row -> row[1] === :h1_multi && row[2] == "ratio3" &&
               row[3] == "multi_effect_ratio_interval" &&
               row[6] == "covered_pillar_bank",
        SYMBOLIC_ALIGNMENT,
    )

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

    @test EXT_CAMPAIGN_INDEX == Dict(
        :h1_two => 1,
        :h1_multi => 2,
        :h1_t => 3,
        :h3_rg => 4,
        :h3_ram => 5,
    )
    @test_throws ErrorException _campaign_seed(cfg, :h1_nbinom, 1, 1)

    # Mutation control: a reordered mapping, a request-order index, or a changed
    # fixed index changes this exact seed.  The campaign's identity, rather than
    # its position in a CLI request, determines its random stream.
    expected_h3_rg_seed = _rep_seed(20260903, 4, 2, 3)
    full = _parse_args(["--seed=20260903", "--campaigns=h1_two,h1_multi,h1_t,h3_rg,h3_ram"])
    reordered = _parse_args(["--seed=20260903", "--campaigns=h3_rg,h1_two"])
    subset = _parse_args(["--seed=20260903", "--campaigns=h3_rg"])
    @test _campaign_seed(full, :h3_rg, 2, 3) == expected_h3_rg_seed
    @test _campaign_seed(reordered, :h3_rg, 2, 3) == expected_h3_rg_seed
    @test _campaign_seed(subset, :h3_rg, 2, 3) == expected_h3_rg_seed

    @test length(_h1_two_cells(:smoke)) == 1
    @test all(c.scope == "interior" for c in _h1_two_cells(:smoke))
    @test any(c.scope == "boundary" for c in _h1_two_cells(:confirm))
    @test all(c.scope == "characterization_not_covered" for c in _h1_t_cells(:smoke))
    @test _h1_multi_cells(:smoke)[1].k == 2
    @test _h1_multi_cells(:confirm)[1].k == 3

    # The retained-evidence inventory is a pre-execution, canonical manifest:
    # task identities do not follow the CLI campaign order.
    inventory_cfg = _parse_args([
        "--mode=confirm",
        "--reps=2",
        "--seed=20260903",
        "--levels=0.90,0.95",
    ])
    inventory = _canonical_task_inventory(inventory_cfg)
    @test Set(entry.campaign for entry in inventory) == Set(EXT_CAMPAIGNS)
    @test any(entry -> entry.campaign === :h1_multi && entry.estimand == "ratio3", inventory)
    @test all(entry -> entry.rep_start == 1 && entry.rep_end == 2 && entry.reps == 2, inventory)
    @test all(entry -> entry.expected_key[1] == string(entry.campaign), inventory)

    repeat_inventory = _canonical_task_inventory(inventory_cfg)
    @test _inventory_digest(inventory) == _inventory_digest(repeat_inventory)
    @test _canonical_inventory_serialization(inventory) ==
          _canonical_inventory_serialization(repeat_inventory)
    @test _inventory_digest(reverse(inventory)) == _inventory_digest(inventory)
    @test occursin(r"^[0-9a-f]{64}$", _inventory_digest(inventory))

    # Display labels intentionally use compact formatting.  Hash material must
    # preserve the exact Float64 level, including values with the same label.
    near_level_a = _canonical_task_inventory(_parse_args([
        "--mode=smoke", "--reps=1", "--seed=20260903",
        "--campaigns=h3_rg", "--levels=0.95",
    ]))
    near_level_b = _canonical_task_inventory(_parse_args([
        "--mode=smoke", "--reps=1", "--seed=20260903",
        "--campaigns=h3_rg", "--levels=0.950000001",
    ]))
    @test near_level_a[1].cell_id == near_level_b[1].cell_id
    @test _canonical_inventory_serialization(near_level_a) !=
          _canonical_inventory_serialization(near_level_b)
    @test _inventory_digest(near_level_a) != _inventory_digest(near_level_b)

    reordered_inventory = _canonical_task_inventory(_parse_args([
        "--mode=confirm",
        "--reps=2",
        "--seed=20260903",
        "--levels=0.95,0.90",
        "--campaigns=h3_rg,h1_two,h3_ram,h1_t,h1_multi",
    ]))
    subset_inventory = _canonical_task_inventory(_parse_args([
        "--mode=confirm",
        "--reps=2",
        "--seed=20260903",
        "--levels=0.90,0.95",
        "--campaigns=h3_rg",
    ]))
    h3_full = only(filter(entry -> entry.campaign === :h3_rg && entry.cell_index == 1 &&
                                      entry.level == 0.9 && entry.rep == 1, inventory))
    h3_reordered = only(filter(entry -> entry.campaign === :h3_rg && entry.cell_index == 1 &&
                                           entry.level == 0.9 && entry.rep == 1, reordered_inventory))
    h3_subset = only(filter(entry -> entry.campaign === :h3_rg && entry.cell_index == 1 &&
                                        entry.level == 0.9 && entry.rep == 1, subset_inventory))
    @test h3_full.expected_key == h3_reordered.expected_key == h3_subset.expected_key

    mutated = collect(inventory)
    mutated[1] = merge(mutated[1], (scope = "mutated_scope",))
    @test _inventory_digest(mutated) != _inventory_digest(inventory)

    same_campaign = filter(entry -> entry.campaign === :h1_two, inventory)
    @test length(unique(entry.expected_key for entry in same_campaign)) == length(same_campaign)
    @test any(entry -> entry.rep == 1, same_campaign) && any(entry -> entry.rep == 2, same_campaign)
    @test any(entry -> entry.cell_index == 1, same_campaign) && any(entry -> entry.cell_index == 2, same_campaign)
    @test any(entry -> entry.level == 0.9, same_campaign) && any(entry -> entry.level == 0.95, same_campaign)
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
