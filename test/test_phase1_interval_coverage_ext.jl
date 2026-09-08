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

    # Retained rows are evidence records, not a best-effort cache.  Validate
    # each record before a summary can see it, and reconcile row sequences
    # before a Dict could conceal a duplicate key.
    retained_cfg = _parse_args([
        "--mode=smoke", "--reps=1", "--seed=20260903",
        "--campaigns=h3_rg", "--levels=0.95",
    ])
    retained_entry = only(_canonical_task_inventory(retained_cfg))
    valid_row = _detail_row(
        campaign = retained_entry.campaign,
        cell_id = retained_entry.cell_id,
        seed = retained_entry.seed,
        rep = retained_entry.rep,
        estimand = retained_entry.estimand,
        method = retained_entry.method,
        design = retained_entry.cell_label,
        n_animals = 12,
        n_obs = 12,
        truth = 0.25,
        level = retained_entry.level,
        scope = retained_entry.scope,
        role = "covered_pillar_bank",
        fit_success = true,
        fit_converged = true,
        interval_success = true,
        failure_reason = "",
        covered = true,
        lower = 0.10,
        upper = 0.40,
        width = 0.30,
        estimate = 0.25,
        se = 0.10,
    )
    @test _validate_detail_row(valid_row) === valid_row
    reconciled = _reconcile_detail_rows([valid_row], retained_cfg)
    @test reconciled isa Dict
    @test reconciled[_detail_key(valid_row)] === valid_row
    @test length(_records_for_summary(reconciled, retained_cfg)) == 1
    normal_runner_records = Dict{Any,Any}()
    @test _insert_detail_record!(normal_runner_records, valid_row) === valid_row
    @test_throws ErrorException _insert_detail_record!(normal_runner_records, valid_row)

    # The shipped Fisher-z r_g runner deliberately has no scalar standard
    # error, while delta-ratio records do.  Preserve that narrow shape rather
    # than weakening successful-interval validation for every method.
    h3_rg_no_scalar_se = merge(valid_row, (se = NaN,))
    @test _validate_detail_row(h3_rg_no_scalar_se) === h3_rg_no_scalar_se
    @test_throws ErrorException _validate_detail_row(merge(h3_rg_no_scalar_se, (
        campaign = "h1_two",
        estimand = "ratio1",
        method = "ratio_delta_z",
    )))

    # Mutation controls: permissive booleans, logically inconsistent success
    # flags, blank failed-interval reasons, duplicate keys, and inventory drift
    # must all stop before pooling or resume can hide them.
    @test_throws ErrorException _parse_detail_bool("yes", "covered")
    @test_throws ErrorException _validate_detail_row(merge(valid_row, (
        interval_success = false,
        covered = true,
        failure_reason = "interval_failed",
        lower = NaN,
        upper = NaN,
        width = NaN,
    )))
    failed_row = merge(valid_row, (
        interval_success = false,
        covered = false,
        failure_reason = "interval_failed",
        lower = NaN,
        upper = NaN,
        width = NaN,
    ))
    @test_throws ErrorException _validate_detail_row(merge(failed_row, (failure_reason = "",)))
    @test_throws ErrorException _validate_detail_row(merge(failed_row, (lower = 0.10,)))
    @test_throws ErrorException _validate_detail_row(merge(valid_row, (width = 0.20,)))
    @test_throws ErrorException _validate_detail_row(merge(valid_row, (covered = false,)))
    @test_throws ErrorException _reconcile_detail_rows([valid_row, valid_row], retained_cfg)
    @test_throws ErrorException _reconcile_detail_rows(NamedTuple[], retained_cfg)
    @test_throws ErrorException _reconcile_detail_rows([
        merge(valid_row, (cell_id = "unexpected-cell",)),
    ], retained_cfg)
    # This is the normal summary-boundary helper, not merely the reconciler:
    # completed inventory is mandatory before a summary can be written.
    @test_throws ErrorException _records_for_summary(Dict{Any,Any}(), retained_cfg)
    unexpected_records = Dict{Any,Any}()
    unexpected_row = merge(valid_row, (cell_id = "unexpected-cell",))
    unexpected_records[_detail_key(unexpected_row)] = unexpected_row
    @test_throws ErrorException _records_for_summary(unexpected_records, retained_cfg)

    mktempdir() do dir
        detail_path = joinpath(dir, "detail.tsv")
        _prepare_detail_output(detail_path; resume = false)
        _write_detail_rows!(detail_path, [valid_row, valid_row])
        @test_throws ErrorException _read_detail_records(detail_path)

        malformed_path = joinpath(dir, "malformed-bool.tsv")
        _prepare_detail_output(malformed_path; resume = false)
        fields = [_format_value(getproperty(valid_row, Symbol(col))) for col in DETAIL_COLUMNS]
        fields[18] = "yes"
        open(malformed_path, "a") do io
            println(io, join(fields, '\t'))
        end
        @test_throws ErrorException _read_detail_records(malformed_path)
    end

    # The release-facing classification must remain a pure adjudication of
    # retained pooled counts.  It is deliberately unable to promote a claim.
    calibration_band = (lower_band = 0.93, upper_band = 0.97)
    complete_summary(; scheduled_reps = 100, interval_success = 100,
                     covered = 95, role = "covered_pillar_bank",
                     evidence_missing = false, immutable_failure = false) = (
        scheduled_reps = scheduled_reps,
        interval_success = interval_success,
        covered = covered,
        role = role,
        evidence_missing = evidence_missing,
        immutable_failure = immutable_failure,
    )
    result = _adjudicate_h1h3(complete_summary(); calibration_band...)
    @test result.verdict === :calibrated_candidate
    @test result.promotable === false
    @test result.coverage == 0.95

    @test _adjudicate_h1h3(complete_summary(immutable_failure = true);
                           calibration_band...).verdict === :hold
    @test _adjudicate_h1h3(complete_summary(evidence_missing = true);
                           calibration_band...).verdict === :hold
    @test _adjudicate_h1h3(complete_summary(interval_success = 89, covered = 85);
                           calibration_band...).verdict === :hold
    @test _adjudicate_h1h3(complete_summary(role = "characterization_only");
                           calibration_band...).verdict === :characterization_only
    @test _adjudicate_h1h3(complete_summary(covered = 100);
                           calibration_band...).verdict === :hold
    @test _adjudicate_h1h3(complete_summary(covered = 89);
                           calibration_band...).verdict === :experimental
    @test _adjudicate_h1h3(complete_summary(covered = 90);
                           calibration_band...).verdict === :experimental
    @test _adjudicate_h1h3(complete_summary(covered = 93);
                           calibration_band...).verdict === :experimental
    @test _adjudicate_h1h3(complete_summary(covered = 97);
                           calibration_band...).verdict === :directional_conservative
    @test _adjudicate_h1h3(complete_summary(covered = 98);
                           calibration_band...).verdict === :directional_conservative

    # A supplied per-task rate cannot replace the pooled numerator/denominator:
    # mean(0/1, 100/100) is 0.5, but retained pooled coverage is 100/101.
    pooled = _adjudicate_h1h3((;
        scheduled_reps = 101,
        interval_success = 101,
        covered = 100,
        role = "covered_pillar_bank",
        evidence_missing = false,
        immutable_failure = false,
        per_task_rate = 0.5,
    ); calibration_band...)
    @test pooled.coverage == 100 / 101
    @test pooled.verdict === :directional_conservative
    @test pooled.promotable === false

    @test_throws ErrorException _adjudicate_h1h3((;
        scheduled_reps = 100,
        interval_success = 100,
        covered = missing,
        role = "covered_pillar_bank",
        evidence_missing = false,
        immutable_failure = false,
    ); calibration_band...)
    @test_throws ErrorException _adjudicate_h1h3((;
        scheduled_reps = 100,
        interval_success = 101,
        covered = 100,
        role = "covered_pillar_bank",
        evidence_missing = false,
        immutable_failure = false,
    ); calibration_band...)
    # Bool is an Integer subtype in Julia, but never a valid retained count.
    @test_throws ErrorException _adjudicate_h1h3(complete_summary(
        scheduled_reps = true, interval_success = 1, covered = 1,
    ); calibration_band...)
    @test_throws ErrorException _adjudicate_h1h3(complete_summary(
        interval_success = true, covered = 1,
    ); calibration_band...)
    @test_throws ErrorException _adjudicate_h1h3(complete_summary(
        covered = true,
    ); calibration_band...)

    # The standalone validator is deliberately self-contained: its success
    # receipt is available without entering `main()` or starting a fit.
    tool = joinpath(@__DIR__, "..", "tools", "validate_hsq09_h1h3_evidence.jl")
    julia = joinpath(Sys.BINDIR, Base.julia_exename())
    tool_output = read(`$julia --project=$(joinpath(@__DIR__, "..")) $tool --self-test`, String)
    @test tool_output == "A2_EVIDENCE_INFRA_TESTS_OK\nA2_MUTATION_CONTROLS_OK\n"
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
