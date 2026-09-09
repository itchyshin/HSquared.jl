using Test

include(joinpath(@__DIR__, "..", "tools", "validate_hsq09_s10_smoke.jl"))

function _s10_fixture_row(entry; interval_success = true, fit_converged = true)
    role = entry.campaign === :h1_t ? "characterization_only" : "covered_pillar_bank"
    failed = !interval_success
    return _detail_row(
        campaign = entry.campaign,
        cell_id = entry.cell_id,
        seed = entry.seed,
        rep = entry.rep,
        estimand = entry.estimand,
        method = entry.method,
        design = entry.cell_label,
        n_animals = 12,
        n_obs = 12,
        truth = 0.25,
        level = entry.level,
        scope = entry.scope,
        role = role,
        fit_success = true,
        fit_converged = fit_converged,
        interval_success = interval_success,
        failure_reason = failed ? "synthetic_interval_failure" : "",
        covered = interval_success,
        lower = failed ? NaN : 0.10,
        upper = failed ? NaN : 0.40,
        width = failed ? NaN : 0.30,
        estimate = 0.25,
        se = entry.method == "rg_fisher_z" ? NaN : 0.10,
    )
end

function _s10_write_fixture(dir; rows = nothing, corrupt_summary = nothing,
                            corrupt_detail = nothing)
    cfg = _s10_smoke_config()
    fixture_rows = isnothing(rows) ? [_s10_fixture_row(entry) for entry in _canonical_task_inventory(cfg)] : rows
    detail = joinpath(dir, "detail.tsv")
    summary = joinpath(dir, "summary.tsv")
    _prepare_detail_output(detail; resume = false)
    _write_detail_rows!(detail, fixture_rows)
    records = _records_for_summary(_read_detail_records(detail), cfg)
    _write_summary(summary, _summaries_from_records(records))
    isnothing(corrupt_summary) || corrupt_summary(summary)
    isnothing(corrupt_detail) || corrupt_detail(detail)
    return detail, summary, cfg
end

@testset "S10 smoke receipt validator" begin
    mktempdir() do dir
        detail, summary, cfg = _s10_write_fixture(dir)
        result = validate_s10_smoke(detail, summary; config = cfg)
        @test result.rows == 7
        @test result.summary_rows == 7
        @test result.claim_eligible === false
    end

    mktempdir() do dir
        detail, summary, cfg = _s10_write_fixture(dir; corrupt_summary = path -> begin
            text = read(path, String)
            write(path, replace(text, "\tfalse\n" => "\ttrue\n"; count = 1))
        end)
        @test_throws ErrorException validate_s10_smoke(detail, summary; config = cfg)
    end

    mktempdir() do dir
        cfg = _s10_smoke_config()
        rows = [_s10_fixture_row(entry) for entry in _canonical_task_inventory(cfg)]
        i = findfirst(row -> row.campaign == "h1_two" && row.estimand == "ratio1", rows)
        rows[i] = _s10_fixture_row(_canonical_task_inventory(cfg)[i]; interval_success = false)
        detail, summary, _ = _s10_write_fixture(dir; rows = rows)
        @test_throws ErrorException validate_s10_smoke(detail, summary; config = cfg)
    end

    mktempdir() do dir
        detail, summary, cfg = _s10_write_fixture(dir; corrupt_detail = path -> begin
            text = read(path, String)
            write(path, replace(text, "\ttrue\ttrue\ttrue\t" => "\ttrue\tyes\ttrue\t"; count = 1))
        end)
        @test_throws ErrorException validate_s10_smoke(detail, summary; config = cfg)
    end

    mktempdir() do dir
        detail, summary, cfg = _s10_write_fixture(dir)
        lines = split(read(detail, String), '\n'; keepempty = false)
        write(detail, join(lines[1:end-1], "\n") * "\n")
        @test_throws ErrorException validate_s10_smoke(detail, summary; config = cfg)
    end

    launcher = read(joinpath(@__DIR__, "..", "tools", "run_hsq09_s10_totoro.sh"), String)
    @test occursin("HSQ09_S10_ARMED", launcher)
    @test occursin("S10_TIMEOUT_SECONDS=1470", launcher)
    @test occursin("mktemp -d", launcher)
    @test occursin(raw"mv \"$STAGE_DIR\" \"$FINAL_DIR\"", launcher)
    @test occursin(raw"sha256sum \"$STAGE_DIR/detail.tsv\"", launcher)
    @test occursin(raw"--validate \"$STAGE_DIR/detail.tsv\"", launcher)
    @test occursin(raw"--out=\"$STAGE_DIR/summary.tsv\"", launcher)
    @test !occursin(raw"--output=\"$STAGE_DIR/summary.tsv\"", launcher)
end

println("S10_SMOKE_VALIDATOR_TESTS_OK")
