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

        mktemp() do path, io
            write(io, "abc")
            close(io)
            @test S2.sha256_file(path) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        end

        mktempdir() do outdir
            first = S2.materialize(outdir; root = S2_ROOT)
            first_hashes = Dict(
                name => S2.sha256_file(joinpath(outdir, name))
                for name in S2.ARTIFACT_FILES
            )
            second = S2.materialize(outdir; root = S2_ROOT)
            @test first == second
            @test all(S2.sha256_file(joinpath(outdir, name)) == first_hashes[name] for name in S2.ARTIFACT_FILES)

            verified = S2.verify_materialization(outdir; root = S2_ROOT)
            @test verified.expected_row_count == 22_000
            @test verified.manifest_sha256 == first.manifest_sha256

            manifest = TOML.parsefile(joinpath(outdir, S2.MANIFEST_FILE))
            @test manifest["candidate_head"] == S2.CANDIDATE_HEAD
            @test manifest["a2_manifest_sha256"] == S2.CANDIDATE_MANIFEST_SHA256
            @test manifest["source_sha256"] == S2.sha256_file(joinpath(S2_ROOT, S2.SOURCE_RELATIVE_PATH))
            @test manifest["environment_sha256"] == S2.environment_sha256(S2_ROOT)
            @test manifest["expected_row_count"] == 22_000
            @test occursin("not materialized", manifest["materialization_limit"])

            # `verify_materialization` streams each declaration row against
            # the pure canonical inventory.  This proves all 22,000 planned
            # task identities are represented without retaining a duplicate
            # giant test-side declaration in memory.
            @test verified.verified_task_row_count == manifest["expected_row_count"]

            verify_stdout = IOBuffer()
            redirect_stdout(verify_stdout) do
                S2.main(["--verify", "--out-dir=$(outdir)"])
            end
            receipt = String(take!(verify_stdout))
            @test startswith(receipt, "HSQ09_S2_VERIFY_OK")

            input_path = joinpath(outdir, S2.INPUT_DECLARATION_FILE)
            open(input_path, "a") do io
                write(io, "mutated\n")
            end
            @test_throws ErrorException S2.verify_materialization(outdir; root = S2_ROOT)
        end

        mktempdir() do outdir
            S2.materialize(outdir; root = S2_ROOT)
            manifest_path = joinpath(outdir, S2.MANIFEST_FILE)
            open(manifest_path, "a") do io
                write(io, "# mutated\n")
            end
            @test_throws ErrorException S2.verify_materialization(outdir; root = S2_ROOT)
        end
    end
end

println("S2_MATERIALIZATION_TESTS_OK")
