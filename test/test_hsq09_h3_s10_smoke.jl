using Test
using TOML

const H3_S10_VALIDATOR = joinpath(@__DIR__, "..", "tools", "validate_hsq09_h3_s10_smoke.jl")

if !isfile(H3_S10_VALIDATOR)
    @testset "H3 S10 smoke validator" begin
        @test false
    end
else
    include(H3_S10_VALIDATOR)

    function _h3_s10_row(entry; fit_converged = true, interval_success = true,
                         claim_eligible = false, lower = -0.55, upper = 0.15,
                         estimate = -0.20)
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
            n_obs = 24,
            truth = -0.20,
            level = entry.level,
            scope = entry.scope,
            role = "covered_pillar_bank",
            fit_success = true,
            fit_converged = fit_converged,
            interval_success = interval_success,
            failure_reason = failed ? "synthetic_interval_failure" : "",
            covered = interval_success,
            lower = failed ? NaN : lower,
            upper = failed ? NaN : upper,
            width = failed ? NaN : upper - lower,
            estimate = estimate,
            se = entry.method == "rg_fisher_z" ? NaN : 0.10,
        )
    end

    function _h3_s10_write_fixture(dir; rows = nothing, corrupt_summary = nothing)
        cfg = h3_s10_smoke_config()
        entries = _canonical_task_inventory(cfg)
        fixture_rows = isnothing(rows) ? [_h3_s10_row(entry) for entry in entries] : rows
        detail = joinpath(dir, "detail.tsv")
        summary = joinpath(dir, "summary.tsv")
        _prepare_detail_output(detail; resume = false)
        _write_detail_rows!(detail, fixture_rows)
        records = _records_for_summary(_read_detail_records(detail), cfg)
        _write_summary(summary, _summaries_from_records(records))
        isnothing(corrupt_summary) || corrupt_summary(summary)
        return detail, summary, cfg
    end

    @testset "H3 S10 smoke validator" begin
        mktempdir() do dir
            detail, summary, cfg = _h3_s10_write_fixture(dir)
            result = validate_h3_s10_smoke(detail, summary; config = cfg)
            @test result.rows == 2
            @test result.summary_rows == 2
            @test result.claim_eligible === false
        end

        mktempdir() do dir
            cfg = h3_s10_smoke_config()
            entries = _canonical_task_inventory(cfg)
            rows = [_h3_s10_row(entry) for entry in entries]
            rows[1] = _h3_s10_row(entries[1]; fit_converged = false, interval_success = false)
            detail, summary, _ = _h3_s10_write_fixture(dir; rows = rows)
            @test_throws ErrorException validate_h3_s10_smoke(detail, summary; config = cfg)
        end

        mktempdir() do dir
            cfg = h3_s10_smoke_config()
            entries = _canonical_task_inventory(cfg)
            rows = [_h3_s10_row(entry) for entry in entries]
            rows[2] = _h3_s10_row(entries[2]; lower = -1.0)
            detail, summary, _ = _h3_s10_write_fixture(dir; rows = rows)
            @test_throws ErrorException validate_h3_s10_smoke(detail, summary; config = cfg)
        end

        mktempdir() do dir
            detail, summary, cfg = _h3_s10_write_fixture(dir; corrupt_summary = path -> begin
                text = read(path, String)
                write(path, replace(text, "\tfalse\n" => "\ttrue\n"; count = 1))
            end)
            @test_throws ErrorException validate_h3_s10_smoke(detail, summary; config = cfg)
        end
    end

    @testset "H3 S10 launcher contract" begin
        launcher_path = joinpath(@__DIR__, "..", "tools", "run_hsq09_h3_s10_totoro.sh")
        @test isfile(launcher_path)
        if isfile(launcher_path)
            launcher = read(launcher_path, String)
            @test occursin("HSQ09_H3_S10_ARMED", launcher)
            @test occursin("readonly S10_ENGINE_SHA=\"82f836f368e37cf75609f721f7a03bde3113e10b\"", launcher)
            @test occursin("readonly S10_EXPECTED_DRIVER_SHA256=\"6c1b74cc207247241e395bd78143c07f01b0091682d3049e57bfdbb1a8d0401d\"", launcher)
            @test occursin("readonly S10_EXPECTED_MANIFEST_SHA256=\"a3d4803f05af9738bc5796b1534bdb3249a263efb6c618cae6088d3f0c7ce221\"", launcher)
            @test !occursin("HSQ09_H3_S10_EXPECTED_DRIVER_SHA256", launcher)
            @test occursin(raw"git diff --quiet \"$S10_ENGINE_SHA\" -- src", launcher)
            @test occursin("--campaigns=h3_rg,h3_ram", launcher)
            @test occursin("JULIA_NUM_THREADS", launcher)
            @test occursin("OPENBLAS_NUM_THREADS", launcher)
            @test occursin("HSQ09_H3_S10_JULIA_BIN", launcher)
            @test occursin("mktemp -d", launcher)
            @test occursin(raw"mv \"$STAGE_DIR\" \"$FINAL_DIR\"", launcher)
            @test occursin("validate_hsq09_h3_s10_smoke.jl", launcher)
            @test occursin("S10_FAILURE_RETAINED", launcher)
        end
    end

    @testset "H3 S10 authorization manifest" begin
        manifest_path = joinpath(@__DIR__, "..", "docs", "dev-log", "evidence", "2026-09-09-hsq09-h3-s10-manifest.toml")
        @test isfile(manifest_path)
        if isfile(manifest_path)
            data = TOML.parsefile(manifest_path)
            @test data["candidate"]["engine_commit"] == "82f836f368e37cf75609f721f7a03bde3113e10b"
            @test data["candidate"]["driver_sha256"] == "6c1b74cc207247241e395bd78143c07f01b0091682d3049e57bfdbb1a8d0401d"
            @test data["run"]["campaigns"] == ["h3_rg", "h3_ram"]
            @test data["run"]["reps"] == 1
            @test data["run"]["seed"] == 20260903
            @test data["authorizations"]["h3_ratification"] === true
            @test data["authorizations"]["s10_compute"] === true
            @test data["authorizations"]["s11_if_measured_estimate_exceeds_30_minutes"] === true
            @test data["authorizations"]["promotion"] === false
            @test data["authorizations"]["release"] === false
        end
    end
end

println("H3_S10_SMOKE_VALIDATOR_TESTS_OK")
