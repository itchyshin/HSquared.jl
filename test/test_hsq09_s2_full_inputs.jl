# Test-first contract for the private, no-fit S2 screening/C1-ext input seal.

using Test

const S2_FULL_TOOL = joinpath(@__DIR__, "..", "tools", "materialize_hsq09_s2_full_inputs.jl")

@testset "0.9 S2 full deterministic screening/C1-ext inputs" begin
    @test isfile(S2_FULL_TOOL)
    if isfile(S2_FULL_TOOL)
        include(S2_FULL_TOOL)
        M = Hsq09S2FullInputs
        root = normpath(joinpath(@__DIR__, ".."))

        @test M.CANDIDATE_HEAD == "7770bf1640aef366970de2d136d19072bfdddcf4"
        @test M.DECLARATION_BASE == "53dc9faea16827172579c939dd606b878e162747"
        @test M.H1T_PROTOCOL_ID == "H1T-DIAG-S10-FIXED-TINY-01"
        @test M.H1T_PROTOCOL_SHA256 == "8bc191bf660c0c26d0e51f0f243502fe601c648f3c97a2047fa2c2b62bc3884f"
        @test M.h1t_materialization_status() == :held_missing_immutable_bytes
        @test all(entry -> entry.campaign != :H1T, M.screening_confirmation_plans(root).confirm.entries)

        plans = M.screening_confirmation_plans(root)
        @test propertynames(plans) == (:screen, :confirm)
        @test length(plans.screen.entries) == 384
        @test length(plans.confirm.entries) == 22_000
        @test all(entry -> entry.mode in (:screen, :confirm), vcat(plans.screen.entries, plans.confirm.entries))

        probe = M.resolve_probe_task(root, "9ad671a335a065b25e3068546504d0c6ec0c2f6e75a725ca15e192a7c1b70a16")
        @test probe.mode == :confirm
        @test probe.entry.campaign == :h1_two
        @test probe.entry.estimand == "ratio1"

        bundle = M.build_input_bundle(root, probe.entry)
        @test propertynames(bundle) == (:metadata, :phenotype, :X, :incidence, :pedigree, :relationship, :truth)
        @test size(bundle.phenotype, 1) == size(bundle.X, 1)
        @test all(isfinite, bundle.phenotype)
        @test size(bundle.X, 2) == 1
        @test !isempty(bundle.pedigree.ids)
        @test bundle.relationship.kind == :pedigree_inverse_construction
        @test all(isfinite, values(bundle.truth))

        @test M.assert_no_runner_or_fit_source!(M.pure_source_text(root)) === nothing
        @test_throws ArgumentError M.assert_no_runner_or_fit_source!("function _run_h1_two() end")
        @test_throws ArgumentError M.assert_no_runner_or_fit_source!("fit_two_effect_reml(y)")
        @test_throws ArgumentError M.assert_no_runner_or_fit_source!("run(Cmd([\"sbatch\"]))")
        @test_throws ArgumentError M.assert_no_runner_or_fit_source!("x = gaussian_likelihood(y)")
        @test_throws ArgumentError M.assert_no_runner_or_fit_source!("HTTP.get(\"https://example.invalid\")")
        @test_throws ArgumentError M.materialize_h1t_without_immutable_bytes()

        probe_dir = mktempdir()
        probe_result = M.materialize_probe(root, probe_dir)
        @test probe_result.task_id == "9ad671a335a065b25e3068546504d0c6ec0c2f6e75a725ca15e192a7c1b70a16"
        @test probe_result.mode == :confirm
        @test probe_result.file_count == 8
        @test probe_result.bytes > 0
        @test probe_result.manifest_hash == M.PROBE_MANIFEST_SHA256
        @test isfile(joinpath(probe_result.path, "manifest.tsv"))
        @test M.verify_input_bundle(probe_result.path; expected_manifest_hash = M.PROBE_MANIFEST_SHA256) === nothing
        @test_throws ArgumentError M.materialize_probe(root, probe_dir; task_id = "substitute")
        @test_throws ArgumentError M.materialize_probe(root, probe_dir)

        repeat_dir = mktempdir()
        repeat_result = M.materialize_probe(root, repeat_dir)
        @test read(joinpath(probe_result.path, "manifest.tsv"), String) ==
              read(joinpath(repeat_result.path, "manifest.tsv"), String)

        open(joinpath(probe_result.path, "unexpected.bin"), "w") do io
            write(io, "unexpected")
        end
        @test_throws ErrorException M.verify_input_bundle(probe_result.path; expected_manifest_hash = M.PROBE_MANIFEST_SHA256)

        phenotype_path = joinpath(repeat_result.path, "phenotype.bin")
        phenotype_bytes = read(phenotype_path)
        phenotype_bytes[1] = xor(phenotype_bytes[1], 0x01)
        write(phenotype_path, phenotype_bytes)
        @test_throws ErrorException M.verify_input_bundle(repeat_result.path; expected_manifest_hash = M.PROBE_MANIFEST_SHA256)

        manifest_dir = mktempdir()
        manifest_result = M.materialize_probe(root, manifest_dir)
        manifest_path = joinpath(manifest_result.path, "manifest.tsv")
        write(manifest_path, read(manifest_path, String) * "tamper\n")
        @test_throws ErrorException M.verify_input_bundle(manifest_result.path; expected_manifest_hash = M.PROBE_MANIFEST_SHA256)

        @test M.parse_cli_args(["--probe-task", M.PROBE_TASK_ID]) ==
              (action = :probe, task_id = M.PROBE_TASK_ID)
        @test_throws ArgumentError M.parse_cli_args(["--probe-task", "substitute"])
        @test_throws ArgumentError M.parse_cli_args(String[])
    end
end

println("S2_FULL_INPUT_TESTS_OK")
