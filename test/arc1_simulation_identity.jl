using Test
using SHA

@testset "Arc1 Julia source and environment provenance adversaries" begin
    mktempdir(prefix="arc1-identity-fixture-") do temp
        root = joinpath(temp, "fake-hsquared")
        mkpath(joinpath(root, "src"))
        write(joinpath(root, "Project.toml"), """
        name = "HSquared"
        uuid = "a0667dea-0f38-44e8-9150-4fda00624eac"
        version = "0.1.0"
        """)
        write(joinpath(root, "Manifest.toml"), """
        julia_version = "$(VERSION)"
        manifest_format = "2.0"
        project_hash = "0000000000000000000000000000000000000000"
        """)
        engine_path = joinpath(root, "src", "HSquared.jl")
        write(engine_path, "module HSquared\nconst load_marker = :original\nend\n")
        helper = joinpath(@__DIR__, "..", "sim", "arc1", "execution_identity.jl")
        script = joinpath(temp, "adversary.jl")
        write(script, raw"""
        using Test, SHA
        include(ARGS[2])
        source_root = ARGS[1]
        hashfile(path) = bytes2hex(sha256(read(path)))
        engine_hashes = Dict("src/HSquared.jl" => hashfile(joinpath(source_root, "src", "HSquared.jl")))
        environment_hashes = Dict("Project.toml" => hashfile(joinpath(source_root, "Project.toml")),
                                  "Manifest.toml" => hashfile(joinpath(source_root, "Manifest.toml")))
        loaded = arc1_load_admitted_engine(source_root, engine_hashes, environment_hashes)
        identity = arc1_execution_identity(loaded, engine_hashes, environment_hashes)
        @test identity.engine_package_uuid == "a0667dea-0f38-44e8-9150-4fda00624eac"
        @test identity.environment_sha256 == environment_hashes
        @test identity.active_project == joinpath(realpath(source_root), "Project.toml")
        @test identity.dependency_environment_verified
        @test_throws ErrorException arc1_load_admitted_engine(source_root, engine_hashes, environment_hashes)

        wrong_environment = copy(environment_hashes)
        wrong_environment["Manifest.toml"] = repeat("0", 64)
        @test_throws ErrorException arc1_execution_identity(loaded, engine_hashes, wrong_environment)

        # Simulate a stale loaded module with freshly edited bytes on disk.
        open(joinpath(source_root, "src", "HSquared.jl"), "a") do stream
            write(stream, "# changed after module load\n")
        end
        @test_throws ErrorException arc1_execution_identity(loaded, engine_hashes, environment_hashes)
        """)
        depot = joinpath(temp, "depot")
        mkpath(depot)
        depot_path = string(depot, Sys.iswindows() ? ';' : ':', first(DEPOT_PATH))
        command = addenv(`$(Base.julia_cmd()) --startup-file=no --threads=1 --project=$root $script $root $helper`,
                         "JULIA_DEPOT_PATH" => depot_path)
        output = read(command, String)
        @test isempty(output)
    end
end
