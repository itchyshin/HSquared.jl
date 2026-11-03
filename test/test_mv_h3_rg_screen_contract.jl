using Test
using LinearAlgebra
using SHA
using HSquared
include(joinpath(@__DIR__, "..", "sim", "mv_h3_rg_screen_20261004.jl"))
using .MVH3RGScreen

file_sha(path) = bytes2hex(sha256(read(path)))

function bundle_fixture(root)
    root = realpath(root)
    mkpath(joinpath(root, "sim")); mkpath(joinpath(root, "test")); mkpath(joinpath(root, "src"))
    for path in selected_source_pin_paths()
        rel = relpath(path, normpath(joinpath(@__DIR__, "..")))
        dst = joinpath(root, rel); mkpath(dirname(dst)); cp(path, dst; force = true)
    end
    module_source = joinpath(normpath(joinpath(@__DIR__, "..")), "src", "HSquared.jl")
    cp(module_source, joinpath(root, "src", "HSquared.jl"); force = true)
    write(joinpath(root, "Project.toml"), "name = \"HSquared\"\n")
    write(joinpath(root, "Manifest.toml"), "manifest_format = \"2.0\"\n")
    write(joinpath(root, "src", "likelihood.jl"), "function _standard_normal_quantile end\n")
    executable = joinpath(root, "julia-test-executable")
    write(executable, "synthetic Julia executable identity\n")
    identity = Dict{String,Any}(
        "julia_executable" => realpath(executable),
        "julia_executable_sha256" => file_sha(executable),
        "julia_version" => "1.10.0",
        "hsquared_module_path" => joinpath(root, "src", "HSquared.jl"),
        "hsquared_source_sha256" => file_sha(joinpath(root, "src", "HSquared.jl")),
        "project_path" => joinpath(root, "Project.toml"),
        "active_project" => joinpath(root, "Project.toml"),
        "project_sha256" => file_sha(joinpath(root, "Project.toml")),
        "manifest_sha256" => file_sha(joinpath(root, "Manifest.toml")),
        "julia_threads" => 2, "blas_threads" => 1,
        "julia_threads_env" => "2", "blas_thread_environment" => Dict(
            "OPENBLAS_NUM_THREADS" => "1", "OMP_NUM_THREADS" => "1", "VECLIB_MAXIMUM_THREADS" => "",
            "MKL_NUM_THREADS" => "", "BLIS_NUM_THREADS" => ""),
        "blas_vendor" => "synthetic BLAS",
        "platform" => Dict("machine" => "synthetic", "kernel" => "synthetic", "arch" => "synthetic"))
    repo = normpath(joinpath(@__DIR__, ".."))
    rows = [(path = relpath(path, repo), sha256 = file_sha(joinpath(root, relpath(path, repo))))
            for path in selected_source_pin_paths()]
    bundle = Dict{String,Any}("schema" => "mv-h3-rg-bundle-v1", "source_protocol_admission" => "HOLD",
        "execution_authorized" => false, "source_inventory" => rows, "identity" => identity)
    return bundle, identity
end

function manifest_for(seeds = 1:48)
    cfg = screen_config()
    sources = source_inventory(selected_source_pin_paths())
    return Dict{String,Any}(
        "schema" => "mv-h3-rg-screen-v1",
        "cell_id" => "h3-interior-rg-delta",
        "source_protocol_admission" => "HOLD",
        "config" => cfg,
        "config_sha256" => config_sha256(cfg),
        "source_sha256" => source_inventory_sha256(sources),
        "source_inventory" => sources,
        "seed_inventory" => collect(seeds),
        "attempts" => 48,
    )
end
bad_manifest(m, patch) = validate_manifest(merge(copy(m), patch); test_mode = true)

function simulation_fixture(seed = 1)
    cfg = screen_config()
    E = zeros(cfg.nanimals, cfg.ntraits); E[1, 1] = seed / 100
    e = zeros(cfg.records, cfg.ntraits); e[1, 1] = seed / 100
    return simulate_from_draws(E, e; config = cfg)
end

function fit_fixture(; converged = true, loglik = -100.0, estimate = 0.4,
                     residual_covariance = [0.8 0.2; 0.2 0.55])
    return (converged = converged, loglik = loglik,
            genetic_covariance = [1.0 estimate * sqrt(0.7); estimate * sqrt(0.7) 0.7],
            residual_covariance = residual_covariance,
            genetic_correlation = [1.0 estimate; estimate 1.0],
            residual_correlation = [1.0 residual_covariance[1, 2] / sqrt(residual_covariance[1, 1] * residual_covariance[2, 2]);
                residual_covariance[2, 1] / sqrt(residual_covariance[1, 1] * residual_covariance[2, 2]) 1.0])
end

function fit_payload_fixture(fit = fit_fixture())
    return (converged = fit.converged, loglik = fit.loglik,
            genetic_covariance = copy(fit.genetic_covariance),
            residual_covariance = copy(fit.residual_covariance),
            genetic_correlation = copy(fit.genetic_correlation),
            residual_correlation = copy(fit.residual_correlation),
            sha256 = MVH3RGScreen.fit_evidence_sha256(fit))
end

function interval_fixture(; estimate = 0.4, lower = 0.2, upper = 0.5,
                          pair = (2, 1), level = 0.95, method = :delta,
                          converged = true, clamped = false)
    return (trait_i = [pair[1]], trait_j = [pair[2]], estimate = [estimate],
            lower = [lower], upper = [upper], lower_clamped = [clamped],
            upper_clamped = [false], level = level, method = method, converged = converged)
end

function ledger_interval(prov; estimate = 0.4, lower = 0.4, upper = 0.45, pair = (2, 1))
    fit = fit_fixture(estimate = estimate)
    return (estimate = estimate, lower = lower, upper = upper, pair = pair,
            level = 0.95, method = :delta, converged = true, fit_loglik = -100.0,
            fit_estimate = estimate, lower_clamped = false, upper_clamped = false,
            fit_genetic_covariance = fit.genetic_covariance,
            fit_residual_covariance = fit.residual_covariance,
            fit_genetic_correlation = fit.genetic_correlation,
            fit_residual_correlation = fit.residual_correlation,
            fit_sha256 = MVH3RGScreen.fit_evidence_sha256(fit), provenance = prov)
end

@testset "H3 rg screen contract" begin
    @testset "fixed proposed cell, non-executing include, no truth starts" begin
        cfg = screen_config()
        @test cfg.nsire == 8 && cfg.ndam == 16 && cfg.noffspring == 96
        @test cfg.nanimals == 120 && cfg.records == 240 && cfg.ntraits == 2
        @test cfg.mean == [2.0, 2.0]
        @test cfg.G ≈ [1.0 0.35; 0.35 0.7]
        @test cfg.true_rg ≈ 0.35 / sqrt(0.7)
        @test cfg.true_rg ≈ 0.4183300132670378
        @test cfg.R ≈ [0.8 0.2; 0.2 0.55]
        @test cfg.pe === nothing && cfg.missingness == 0
        @test cfg.genetic_structure == :unstructured
        @test cfg.initial === nothing && cfg.iterations == 5000
        @test cfg.interval_method == :delta && cfg.interval_level == 0.95
        @test cfg.interval_pair == (2, 1)
        layout = pedigree_layout(cfg)
        @test layout.ids[1:8] == ["s$i" for i in 1:8]
        @test layout.ids[9:24] == ["d$i" for i in 1:16]
        @test layout.ids[25:end] == ["o$i" for i in 1:96]
        @test layout.sire[25] == "s1" && layout.dam[25] == "d1"
        @test layout.sire[end] == "s8" && layout.dam[end] == "d16"
        @test record_layout(layout)[1:6] == ["s1", "s1", "s2", "s2", "s3", "s3"]
        @test validate_simulation_data(simulation_fixture())
        bad = merge(simulation_fixture(), (X = zeros(240, 1),))
        @test_throws ArgumentError validate_simulation_data(bad)
        badY = copy(simulation_fixture().Y); badY[1, 1] = NaN
        @test_throws ArgumentError validate_simulation_data(merge(simulation_fixture(), (Y = badY,)))
        badZ = copy(simulation_fixture().Z); badZ[2, 1] = 0; badZ[2, 2] = 1
        @test_throws ArgumentError validate_simulation_data(merge(simulation_fixture(), (Z = badZ,)))
        @test_throws ArgumentError validate_simulation_data(merge(simulation_fixture(),
            (Ainv = Matrix{Float64}(I, 120, 120),)))
        E = zeros(cfg.nanimals, cfg.ntraits); E[1, 1] = 1.25
        e = zeros(cfg.records, cfg.ntraits); e[1, 2] = -0.75
        generated = simulate_from_draws(E, e)
        @test generated.draws_sha256 == simulate_from_draws(E, e).draws_sha256
        A = Matrix(inv(Symmetric(expected_relationship_inverse(cfg))))
        @test A[25, 33] ≈ 0.25 # same sire, different dams
        @test A[25, 41] ≈ 0.5  # same sire and dam
        @test A[25, 26] ≈ 0.0  # unrelated offspring
        U = cholesky(Symmetric(A)).L * E * transpose(cholesky(Symmetric(cfg.G)).L)
        LR = cholesky(Symmetric(cfg.R)).L
        @test generated.Y[1, :] ≈ cfg.mean .+ U[1, :] .+ LR * e[1, :]
        @test generated.Y[2, :] ≈ cfg.mean .+ U[1, :] .+ LR * e[2, :]
        @test generated.Z[1, 1] == generated.Z[2, 1] == 1
        @test all(generated.X .== 1)
        tampered = copy(generated.Y); tampered[1, 1] += 1
        @test_throws ArgumentError validate_simulation_data(merge(generated, (Y = tampered,)))
        @test !isdefined(MVH3RGScreen, :last_run)
    end

    @testset "manifest validation fails closed" begin
        m = manifest_for()
        validated = validate_manifest(m; test_mode = true)
        @test validated.attempts == 48
        @test !validated.allocation_verified && !validated.freshness_verified
        @test validated.external_fresh_process_verification_required
        @test !validated.execution_admission_eligible
        @test_throws ArgumentError bad_manifest(m, Dict("attempts" => 47))
        @test_throws ArgumentError bad_manifest(m, Dict("seed_inventory" => vcat(collect(1:47), 47)))
        @test_throws ArgumentError bad_manifest(m, Dict("seed_inventory" => collect(1:47)))
        @test_throws ArgumentError bad_manifest(m, Dict("seed_inventory" => vcat(collect(1:48), 49)))
        @test_throws ArgumentError bad_manifest(m, Dict("config_sha256" => repeat("b", 64)))
        @test_throws ArgumentError bad_manifest(m, Dict("source_sha256" => "unverified"))
        @test_throws ArgumentError bad_manifest(m, Dict("source_sha256" => repeat("b", 64)))
        incomplete_sources = filter(row -> !endswith(row.path, "test_mv_h3_rg_screen_contract.jl"), m["source_inventory"])
        @test_throws ArgumentError bad_manifest(m, Dict("source_inventory" => incomplete_sources,
            "source_sha256" => source_inventory_sha256(incomplete_sources)))
        @test_throws ArgumentError bad_manifest(m, Dict("source_protocol_admission" => "ADMITTED"))
    end

    @testset "source checksums are explicit and verifiable" begin
        mktemp() do path, io
            write(io, "frozen input\n"); close(io)
            pin = source_inventory([path])
            @test verify_source_inventory(pin)
            write(path, "changed input\n")
            @test_throws ArgumentError verify_source_inventory(pin)
        end
    end

    @testset "versioned screen and timing allocation contracts" begin
        screen = Dict("schema" => "mv-h3-rg-run-v1", "kind" => "screen", "attempts" => 48,
            "seed_inventory" => collect(1:48), "source_protocol_admission" => "HOLD",
            "execution_authorized" => false)
        @test validate_run_manifest(screen).execution_enabled === false
        screen_status = validate_run_manifest(screen)
        @test !screen_status.allocation_verified && !screen_status.freshness_verified
        @test screen_status.external_fresh_process_verification_required
        @test !screen_status.execution_admission_eligible
        @test_throws ArgumentError validate_run_manifest(merge(screen, Dict("seed_inventory" => Any[true; collect(2:48)])))
        @test_throws ArgumentError validate_run_manifest(merge(screen, Dict("attempts" => 47)))
        @test_throws ArgumentError validate_run_manifest(merge(screen, Dict("seed_inventory" => collect(1:47))))
        timing = Dict("schema" => "mv-h3-rg-run-v1", "kind" => "timing", "attempts" => 3,
            "max_attempt_seconds" => 600, "max_total_seconds" => 1800,
            "source_protocol_admission" => "HOLD", "execution_authorized" => false)
        @test validate_run_manifest(timing).seeds === nothing
        timing_status = validate_run_manifest(timing)
        @test !timing_status.allocation_verified && !timing_status.freshness_verified
        @test timing_status.external_fresh_process_verification_required
        @test !timing_status.execution_admission_eligible
        @test_throws ArgumentError validate_run_manifest(merge(timing, Dict("attempts" => 2)))
        @test_throws ArgumentError validate_run_manifest(merge(timing, Dict("max_attempt_seconds" => 601)))
        @test_throws ArgumentError validate_run_manifest(merge(timing, Dict("max_total_seconds" => 1801)))
        for invalid in (true, false, 0, -1, NaN, Inf)
            @test_throws ArgumentError validate_run_manifest(merge(timing, Dict("max_attempt_seconds" => invalid)))
            @test_throws ArgumentError validate_run_manifest(merge(timing, Dict("max_total_seconds" => invalid)))
        end
        @test_throws ArgumentError validate_run_manifest(merge(timing, Dict("max_total_seconds" => 1799)))
        @test_throws ArgumentError validate_run_manifest(merge(timing, Dict("seed_inventory" => [1, 2, 3])))
        seed_pin = bytes2hex(sha256("1\n2\n3"))
        admitted_timing = merge(timing, Dict("seed_inventory" => [1, 2, 3],
            "seed_allocation_admission" => "ADMITTED", "seed_allocation_sha256" => seed_pin))
        @test validate_run_manifest(admitted_timing).seeds == [1, 2, 3]
        @test_throws ArgumentError validate_run_manifest(merge(admitted_timing,
            Dict("seed_inventory" => [1, 1, 3])))
        @test_throws ArgumentError validate_run_manifest(merge(admitted_timing,
            Dict("seed_inventory" => [1, 2, 4])))
        @test_throws ArgumentError validate_run_manifest(merge(timing, Dict("execution_authorized" => true)))
    end

    @testset "bundle verifier binds source and runtime identity without execution" begin
        ordered = Dict{String,Any}("outer" => "first", "nested" => Dict{String,Any}("x" => 1, "y" => 2))
        reversed = Dict{String,Any}(); reversed["nested"] = Dict{String,Any}("y" => 2, "x" => 1); reversed["outer"] = "first"
        @test canonical_identity_sha256(ordered) == canonical_identity_sha256(reversed)
        changed_identity = deepcopy(reversed); changed_identity["nested"]["x"] = 9
        @test canonical_identity_sha256(ordered) != canonical_identity_sha256(changed_identity)
        mktempdir() do root
            bundle, identity = bundle_fixture(root)
            receipt = MVH3RGScreen._verify_bundle(root, bundle, identity)
            @test receipt["selected_pins_verified"] === true
            @test receipt["source_pin_scope"] == "selected_file_pin_set_not_complete_loaded_code_closure"
            @test receipt["loaded_code_identity_verified"] === false
            @test receipt["dependency_resolution_verified"] === false
            @test receipt["allocation_verified"] === false
            @test receipt["freshness_verified"] === false
            @test receipt["external_fresh_process_immutable_bundle_verification_required"] === true
            @test receipt["execution_admission_eligible"] === false
            @test receipt["execution_performed"] === false
            @test receipt["source_count"] == length(selected_source_pin_paths())
            @test length(receipt["identity_sha256"]) == 64
            omitted_before = file_sha(joinpath(root, "src", "likelihood.jl"))
            write(joinpath(root, "src", "likelihood.jl"), "mutated omitted source\n")
            omitted_after_receipt = MVH3RGScreen._verify_bundle(root, bundle, identity)
            @test omitted_before != file_sha(joinpath(root, "src", "likelihood.jl"))
            @test omitted_after_receipt["loaded_code_identity_verified"] === false
            @test omitted_after_receipt["selected_pins_verified"] === true
            identity_keys = collect(keys(identity))
            for key in identity_keys
                changed = deepcopy(identity)
                value = changed[key]
                changed[key] = value isa Integer ? value + 1 : value isa AbstractDict ?
                    merge(value, Dict("mutated" => true)) : string(value, "-mutated")
                @test_throws ArgumentError MVH3RGScreen._verify_bundle(root, merge(copy(bundle), Dict("identity" => identity)), changed)
            end
            inconsistent = deepcopy(identity)
            inconsistent["julia_threads"] = 8
            @test_throws ArgumentError MVH3RGScreen._verify_bundle(root,
                merge(copy(bundle), Dict("identity" => inconsistent)), inconsistent)
            inconsistent_blas = deepcopy(identity)
            inconsistent_blas["blas_threads"] = 2
            @test_throws ArgumentError MVH3RGScreen._verify_bundle(root,
                merge(copy(bundle), Dict("identity" => inconsistent_blas)), inconsistent_blas)
            changed_source = deepcopy(bundle)
            changed_source["source_inventory"][1] = merge(changed_source["source_inventory"][1],
                (sha256 = repeat("0", 64),))
            @test_throws ArgumentError MVH3RGScreen._verify_bundle(root, changed_source, identity)
            missing_source = deepcopy(bundle); pop!(missing_source["source_inventory"])
            @test_throws ArgumentError MVH3RGScreen._verify_bundle(root, missing_source, identity)
            duplicate_source = deepcopy(bundle); push!(duplicate_source["source_inventory"], duplicate_source["source_inventory"][1])
            @test_throws ArgumentError MVH3RGScreen._verify_bundle(root, duplicate_source, identity)
            actual_source = joinpath(root, bundle["source_inventory"][1].path)
            write(actual_source, "mutated source bytes\n")
            @test_throws ArgumentError MVH3RGScreen._verify_bundle(root, bundle, identity)
            bundle, identity = bundle_fixture(root)
            write(identity["julia_executable"], "mutated executable bytes\n")
            @test_throws ArgumentError MVH3RGScreen._verify_bundle(root, bundle, identity)
            bundle, identity = bundle_fixture(root)
            write(identity["hsquared_module_path"], "mutated HSquared bytes\n")
            @test_throws ArgumentError MVH3RGScreen._verify_bundle(root, bundle, identity)
            bundle, identity = bundle_fixture(root)
            changed_project = deepcopy(bundle); write(joinpath(root, "Project.toml"), "changed\n")
            @test_throws ArgumentError MVH3RGScreen._verify_bundle(root, changed_project, identity)
            bundle, identity = bundle_fixture(root)
            changed_manifest = deepcopy(bundle); write(joinpath(root, "Manifest.toml"), "changed\n")
            @test_throws ArgumentError MVH3RGScreen._verify_bundle(root, changed_manifest, identity)
            @test_throws ArgumentError MVH3RGScreen._verify_bundle(root, merge(copy(bundle), Dict("execution_authorized" => true)), identity)
        end
        repo = normpath(joinpath(@__DIR__, ".."))
        runtime = runtime_identity(repo)
        rows = [(path = relpath(path, repo), sha256 = file_sha(path)) for path in selected_source_pin_paths(repo)]
        live_bundle = Dict("schema" => "mv-h3-rg-bundle-v1", "source_protocol_admission" => "HOLD",
            "execution_authorized" => false, "source_inventory" => rows, "identity" => runtime)
        receipt = verify_bundle(repo, live_bundle)
        @test receipt["selected_pins_verified"] === true && receipt["execution_performed"] === false
        @test runtime["julia_version"] == string(VERSION)
        @test runtime["active_project"] == realpath(joinpath(repo, "Project.toml"))
    end

    @testset "separate stages retain each attempted failure" begin
        m = manifest_for()
        seed_by_Y = IdDict{Any,Int}()
        simulation_by_Y = IdDict{Any,Any}()
        sims = simulate_stage(m; simulate = seed -> begin
            seed == 4 && error("simulation failure")
            sim = simulation_fixture(seed); seed_by_Y[sim.Y] = seed; simulation_by_Y[sim.Y] = sim; sim
        end, test_mode = true)
        @test length(sims) == 48
        @test sims[4].status == :simulation_failed
        cfg = screen_config()
        altered_fit_config = merge(cfg, (initial = (G0 = cfg.G, R0 = cfg.R),))
        fit_override_called = Ref(false)
        @test_throws ArgumentError fit_stage(sims; config = altered_fit_config,
            fit = (args...; kwargs...) -> (fit_override_called[] = true; fit_fixture()))
        @test !fit_override_called[]
        fit_calls = Ref(0)
        fits = fit_stage(sims; fit = (Y, X, Z, Ainv; genetic_structure, initial, iterations, ids, traits) -> begin
            fit_calls[] += 1
            @test genetic_structure == :unstructured && initial === nothing && iterations == 5000
            @test size(Y) == (240, 2) && size(X) == (240, 1) && size(Z) == (240, 120)
            @test Ainv ≈ expected_relationship_inverse() && ids == pedigree_layout().ids
            @test traits == ["trait1", "trait2"]
            seed = seed_by_Y[Y]
            sim = simulation_by_Y[Y]
            @test Y === sim.Y && X === sim.X && Z === sim.Z && Ainv === sim.Ainv
            seed == 2 ? error("fit failure") :
                seed == 6 ? fit_fixture(converged = false) :
                seed == 7 ? fit_fixture(loglik = NaN) :
            seed == 8 ? fit_fixture(estimate = NaN) :
                seed == 11 ? fit_fixture(residual_covariance = [1.0 2.0; 2.0 1.0]) :
                merge(fit_fixture(), (screen_seed = seed,))
        end)
        @test length(fits) == 48
        @test fit_calls[] == 47
        @test fits[2].status == :fit_failed
        @test fits[6].status == :fit_failed && occursin("did not converge", fits[6].error)
        @test fits[7].status == :fit_failed && occursin("non-finite", fits[7].error)
        @test fits[8].status == :fit_failed && occursin("finite", fits[8].error)
        @test fits[11].status == :fit_failed
        @test occursin("positive definite", fits[11].error)
        @test all(fits[s].rejected_fit_diagnostic !== nothing for s in (6, 7, 8, 11))
        @test all(length(fits[s].rejected_fit_diagnostic.sha256) == 64 for s in (6, 7, 8, 11))
        @test occursin("NaN", fits[7].rejected_fit_diagnostic.rendered)
        @test occursin("2.0", fits[11].rejected_fit_diagnostic.rendered)
        @test fits[2].rejected_fit_diagnostic === nothing
        @test fits[1].fit_payload.sha256 == MVH3RGScreen.fit_evidence_sha256(fits[1].value)
        interval_calls = Ref(0)
        intervals = interval_stage(fits; interval = (fit, Y, X, Z, Ainv; method, level, pairs) -> begin
            interval_calls[] += 1
            @test method == :delta && level == 0.95 && pairs == [(2, 1)]
            @test size(Y) == (240, 2) && size(X) == (240, 1) && size(Z) == (240, 120)
            sim = simulation_by_Y[Y]
            @test Y === sim.Y && X === sim.X && Z === sim.Z && Ainv === sim.Ainv
            seed = fit.screen_seed
            seed == 3 ? error("unavailable delta SE") :
                seed == 9 ? interval_fixture(lower = 0.39, upper = 0.41) :
                seed == 10 ? interval_fixture(pair = (1, 2)) : interval_fixture()
        end)
        @test length(intervals) == 48
        @test interval_calls[] == 42
        @test intervals[2].status == :fit_failed
        @test intervals[3].status == :interval_failed
        @test intervals[4].status == :simulation_failed
        @test intervals[6].status == :fit_failed
        @test intervals[7].status == :fit_failed
        @test intervals[8].status == :fit_failed
        @test intervals[11].status == :fit_failed
        @test intervals[3].fit_payload.sha256 == fits[3].fit_payload.sha256
        @test intervals[3].rejected_fit_diagnostic === nothing
        @test intervals[6].rejected_fit_diagnostic.sha256 == fits[6].rejected_fit_diagnostic.sha256
        @test intervals[9].status == :formed
        @test intervals[9].interval.upper < screen_config().true_rg
        @test intervals[10].status == :interval_failed
        @test intervals[1].status == :formed
        altered_interval_config = merge(screen_config(), (interval_level = 0.90,))
        interval_override_called = Ref(false)
        @test_throws ArgumentError interval_stage(fits; config = altered_interval_config,
            interval = (args...; kwargs...) -> (interval_override_called[] = true; interval_fixture()))
        @test !interval_override_called[]
        summary = summarize_attempts(m, intervals)
        @test summary.N == 48 && summary.F == 42 && summary.I == 40 && summary.C == 39
        @test summary.F_over_N ≈ 42 / 48
        @test summary.I_over_N ≈ 40 / 48
        @test summary.C_over_N ≈ 39 / 48
        @test summary.C_over_I ≈ 39 / 40
        @test length(summary.input_sha256_by_seed) == 48
        @test summary.input_sha256_by_seed[4] === nothing
        @test all(s -> length(summary.input_sha256_by_seed[s]) == 64, setdiff(1:48, [4]))
    end

    @testset "summary rejects incomplete, duplicate, and foreign attempts" begin
        m = manifest_for(); validated = validate_manifest(m; test_mode = true)
        prov = (config_sha256 = validated.config_sha256, source_sha256 = validated.source_sha256,
                seed_inventory_sha256 = validated.seed_inventory_sha256,
                input_sha256 = repeat("c", 64))
        function ledger(nformed; first_interval = nothing)
            [(seed = s, stage = :interval, status = s <= nformed ? :formed : :not_interpretable,
              fit_payload = fit_payload_fixture(),
              interval = s <= nformed ? (s == 1 && first_interval !== nothing ?
                  ledger_interval(prov; estimate = first_interval.estimate[1],
                      lower = first_interval.lower[1], upper = first_interval.upper[1]) :
                  ledger_interval(prov)) : nothing,
              provenance = prov) for s in 1:48]
        end
        records = ledger(44)
        summary = summarize_attempts(m, records)
        @test summary.N == 48 && summary.F == 48 && summary.I == 44 && summary.C == 44
        @test summary.F_over_N == 1.0
        @test summary.I_over_N ≈ 44 / 48
        @test summary.C_over_N ≈ 44 / 48
        @test summary.C_over_I == 1.0
        @test summary.claim_eligible == false
        @test summary.interpretability_floor_met
        @test !summarize_attempts(m, ledger(43)).interpretability_floor_met
        distinguish = ledger(44; first_interval = interval_fixture(lower = 0.39, upper = 0.41))
        distinguish_summary = summarize_attempts(m, distinguish)
        @test distinguish_summary.C == 43
        @test distinguish_summary.C_over_I ≈ 43 / 44
        @test length(summary.config_sha256) == 64
        @test length(summary.source_sha256) == 64
        @test length(summary.seed_inventory_sha256) == 64
        @test_throws ArgumentError summarize_attempts(m, records[1:47])
        @test_throws ArgumentError summarize_attempts(m, vcat(records[1:47], records[47]))
        @test_throws ArgumentError summarize_attempts(m, vcat(records[1:47], [(seed = 49, stage = :interval, status = :formed, interval = records[end].interval, provenance = prov)]))
        @test_throws ArgumentError summarize_attempts(m, vcat([(seed = 1, stage = :interval, status = :formed,
            interval = merge(records[1].interval, (lower = -1.0,)), fit_payload = records[1].fit_payload,
            provenance = prov)], records[2:end]))
        @test_throws ArgumentError summarize_attempts(m, vcat([(seed = 1, stage = :interval, status = :formed,
            interval = merge(records[1].interval, (pair = (1, 2),)), fit_payload = records[1].fit_payload,
            provenance = prov)], records[2:end]))
        @test_throws ArgumentError summarize_attempts(m, vcat([(seed = 1, stage = :interval, status = :formed,
            interval = merge(records[1].interval, (estimate = 0.3,)), fit_payload = records[1].fit_payload,
            provenance = prov)], records[2:end]))
        @test_throws ArgumentError summarize_attempts(m, vcat([(seed = 1, stage = :interval, status = :formed,
            interval = merge(records[1].interval, (level = 0.9,)), fit_payload = records[1].fit_payload,
            provenance = prov)], records[2:end]))
        @test_throws ArgumentError summarize_attempts(m, vcat([(seed = 1, stage = :interval, status = :formed,
            interval = merge(records[1].interval, (method = :profile,)), fit_payload = records[1].fit_payload,
            provenance = prov)], records[2:end]))
        @test_throws ArgumentError summarize_attempts(m, vcat([(seed = 1, stage = :interval, status = :formed,
            interval = merge(records[1].interval, (upper = 1.0,)), fit_payload = records[1].fit_payload,
            provenance = prov)], records[2:end]))
        @test_throws ArgumentError summarize_attempts(m, vcat([(seed = 1, stage = :interval, status = :formed,
            interval = merge(records[1].interval, (lower = 0.8, upper = 0.9)), fit_payload = records[1].fit_payload,
            provenance = prov)], records[2:end]))
        @test_throws ArgumentError summarize_attempts(m, vcat([(seed = 1, stage = :interval, status = :formed,
            interval = merge(records[1].interval, (lower_clamped = true,)), fit_payload = records[1].fit_payload,
            provenance = prov)], records[2:end]))
        @test_throws ArgumentError summarize_attempts(m, vcat([(seed = 1, stage = :interval, status = :formed,
            interval = merge(records[1].interval, (fit_sha256 = repeat("0", 64),)),
            fit_payload = records[1].fit_payload, provenance = prov)], records[2:end]))
        @test_throws ArgumentError summarize_attempts(m, vcat([(seed = 1, stage = :interval, status = :interval_failed,
            interval = nothing, provenance = prov)], records[2:end]))
        @test_throws ArgumentError summarize_attempts(m, vcat([(seed = 1, stage = :interval, status = :interval_failed,
            interval = nothing, fit_payload = merge(records[1].fit_payload, (loglik = -99.0,)),
            provenance = prov)], records[2:end]))
        @test_throws ArgumentError MVH3RGScreen._adapt_interval(interval_fixture(estimate = 0.3),
            fit_fixture(), screen_config(), prov)
        @test_throws ArgumentError MVH3RGScreen._adapt_interval(interval_fixture(upper = 1.0),
            fit_fixture(), screen_config(), prov)
        @test_throws ArgumentError MVH3RGScreen._adapt_interval(interval_fixture(clamped = true),
            fit_fixture(), screen_config(), prov)
        @test_throws ArgumentError MVH3RGScreen._adapt_interval(interval_fixture(level = 0.9),
            fit_fixture(), screen_config(), prov)
        @test_throws ArgumentError MVH3RGScreen._adapt_interval(interval_fixture(method = :profile),
            fit_fixture(), screen_config(), prov)
        @test_throws ArgumentError MVH3RGScreen._adapt_interval(interval_fixture(converged = false),
            fit_fixture(), screen_config(), prov)
        @test_throws ArgumentError summarize_attempts(m, records; truth_rg = 0.35)
        empty_intervals = [(seed = s, stage = :interval, status = :interval_failed, interval = nothing,
            fit_payload = fit_payload_fixture(), provenance = prov) for s in 1:48]
        @test ismissing(summarize_attempts(m, empty_intervals).C_over_I)
    end
end
