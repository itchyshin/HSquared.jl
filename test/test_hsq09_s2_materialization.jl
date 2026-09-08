# 0.9 S2 immutable C1-ext input materialization.
#
# Standalone by design: this never enters a C1-ext runner or starts a fit.
# Run with:
#   julia --project=. -e 'using Test; include("test/test_hsq09_s2_materialization.jl")'

using Test
using TOML

const S2_ROOT = normpath(joinpath(@__DIR__, ".."))
const S2_TOOL = joinpath(S2_ROOT, "tools", "materialize_hsq09_s2.jl")

@testset "0.9 S2 immutable C1-ext input materialization" begin
    # This is intentionally the RED assertion.  It must fail before the
    # materializer exists, rather than treating a missing fixture as a pass.
    @test isfile(S2_TOOL)

    if isfile(S2_TOOL)
        include(S2_TOOL)
        S2 = Hsq09S2Materialization

        # RED control for the candidate-byte binding introduced after the
        # first materialization review. Do not run fixture work until it exists.
        @test isdefined(S2, :assert_candidate_file)

        if isdefined(S2, :assert_candidate_file)
            mktemp() do path, io
                write(io, "abc")
                close(io)
                @test S2.sha256_file(path) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
            end

            @test S2.assert_candidate_file(S2_ROOT, "Project.toml") ==
                  S2.sha256_file(joinpath(S2_ROOT, "Project.toml"))
            @test S2.assert_candidate_file(S2_ROOT, S2.SBATCH_RELATIVE_PATH) ==
                  S2.sha256_file(joinpath(S2_ROOT, S2.SBATCH_RELATIVE_PATH))
            @test S2.candidate_path_absent(S2_ROOT, "Manifest.toml")

            for relative in ("Project.toml", S2.SBATCH_RELATIVE_PATH, "Manifest.toml")
                mktemp() do path, io
                    write(io, read(joinpath(S2_ROOT, relative)))
                    close(io)
                    open(path, "a") do mutation
                        write(mutation, "\n# mutation\n")
                    end
                    expected = S2.sha256_file(joinpath(S2_ROOT, relative))
                    @test_throws ErrorException S2.assert_candidate_digest(path, expected, relative)
                end
            end

            # Exercise the production candidate-file path, not only its
            # digest comparator: the temporary root carries this worktree's
            # gitdir pointer, but every candidate-bound input is copied and
            # then independently mutated.
            candidate_files = (S2.SOURCE_RELATIVE_PATH, "Project.toml", S2.SBATCH_RELATIVE_PATH)
            for mutated_relative in candidate_files
                mktempdir() do copied_root
                    write(joinpath(copied_root, ".git"), read(joinpath(S2_ROOT, ".git")))
                    for relative in candidate_files
                        target = joinpath(copied_root, relative)
                        mkpath(dirname(target))
                        write(target, read(joinpath(S2_ROOT, relative)))
                    end
                    open(joinpath(copied_root, mutated_relative), "a") do mutation
                        write(mutation, "\n# copied-root mutation\n")
                    end
                    @test_throws ErrorException S2.assert_candidate_file(copied_root, mutated_relative)
                end
            end

            mktempdir() do parent
                outdir = joinpath(parent, "sealed")
                first = S2.materialize(outdir; root = S2_ROOT)
                first_hashes = Dict(
                    name => S2.sha256_file(joinpath(outdir, name))
                    for name in S2.ARTIFACT_FILES
                )
                second_outdir = joinpath(parent, "sealed-repeat")
                second = S2.materialize(second_outdir; root = S2_ROOT)
                @test first == second
                @test all(
                    S2.sha256_file(joinpath(second_outdir, name)) == first_hashes[name]
                    for name in S2.ARTIFACT_FILES
                )

                verified = S2.verify_materialization(outdir; root = S2_ROOT)
                @test verified.expected_row_count == 22_000
                @test verified.manifest_sha256 == first.manifest_sha256

                manifest = TOML.parsefile(joinpath(outdir, S2.MANIFEST_FILE))
                @test manifest["candidate_head"] == S2.CANDIDATE_HEAD
                @test manifest["source_sha256"] == S2.sha256_file(joinpath(S2_ROOT, S2.SOURCE_RELATIVE_PATH))
                @test manifest["candidate_project_sha256"] == S2.sha256_file(joinpath(S2_ROOT, "Project.toml"))
                @test manifest["sbatch_template_sha256"] == S2.sha256_file(joinpath(S2_ROOT, S2.SBATCH_RELATIVE_PATH))
                @test manifest["environment_sha256"] == S2.environment_sha256(S2_ROOT)
                @test manifest["expected_row_count"] == 22_000
                @test manifest["environment_lock_kind"] == "external_a2_environment_lock"
                @test manifest["environment_lock_sha256"] == S2.CANDIDATE_MANIFEST_SHA256
                @test manifest["environment_lock_source_worktree"] == "hsq09-s2-materialization"
                @test occursin("not materialized", manifest["materialization_limit"])

                # `verify_materialization` streams each declaration row against
                # the pure canonical inventory.  This proves all 22,000 planned
                # task identities are represented without retaining a duplicate
                # giant test-side declaration in memory.
                @test verified.verified_task_row_count == manifest["expected_row_count"]

                # Julia 1.10-safe direct CLI contract: inspect `main`'s return
                # instead of redirecting stdout to an IOBuffer.
                receipt = S2.main(["--verify", "--out-dir=$(outdir)"])
                @test receipt.manifest_sha256 == first.manifest_sha256
                @test receipt.expected_row_count == 22_000

                input_path = joinpath(outdir, S2.INPUT_DECLARATION_FILE)
                open(input_path, "a") do io
                    write(io, "mutated\n")
                end
                @test_throws ErrorException S2.verify_materialization(outdir; root = S2_ROOT)
            end

            mktempdir() do outdir
                @test_throws ErrorException S2.materialize(outdir; root = S2_ROOT)
                @test isempty(readdir(outdir))
            end

            mktempdir() do outdir
                partial = joinpath(outdir, "partial-publication")
                mkpath(partial)
                sentinel = joinpath(partial, "partial.tsv")
                write(sentinel, "incomplete\n")
                @test_throws ErrorException S2.materialize(partial; root = S2_ROOT)
                @test read(sentinel, String) == "incomplete\n"
            end

            mktempdir() do parent
                outdir = joinpath(parent, "sealed")
                S2.materialize(outdir; root = S2_ROOT)
                manifest_path = joinpath(outdir, S2.MANIFEST_FILE)
                open(manifest_path, "a") do io
                    write(io, "# mutated\n")
                end
                @test_throws ErrorException S2.verify_materialization(outdir; root = S2_ROOT)
            end

            mktempdir() do parent
                outdir = joinpath(parent, "sealed")
                S2.materialize(outdir; root = S2_ROOT)
                seal_path = joinpath(outdir, S2.SEAL_FILE)
                open(seal_path, "a") do io
                    write(io, "# mutated\n")
                end
                @test_throws ErrorException S2.verify_materialization(outdir; root = S2_ROOT)
            end
        end
    end
end

println("S2_MATERIALIZATION_TESTS_OK")
