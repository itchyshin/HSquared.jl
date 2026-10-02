using SHA
using LinearAlgebra
using Pkg
using UUIDs

const ARC1_HSQUARED_UUID = UUID("a0667dea-0f38-44e8-9150-4fda00624eac")

struct Arc1LoadedEngine
    module_object::Module
    source_root::String
    source_sha256_at_load::Dict{String,String}
    environment_sha256_at_load::Dict{String,String}
    active_project::String
    loaded_dependencies::Vector{Dict{String,Any}}
end

function _arc1_sha256(path::AbstractString)
    return bytes2hex(sha256(read(path)))
end

function _arc1_snapshot(root::AbstractString, hashes::Dict{String,String})
    source = realpath(root)
    actual = Dict{String,String}()
    for relative in sort(collect(keys(hashes)))
        startswith(relative, "src/") || error("engine source identity paths must start with src/")
        full = realpath(joinpath(source, relative))
        rel = relpath(full, source)
        (rel == ".." || startswith(rel, "../")) && error("source path escaped admitted root")
        actual[relative] = _arc1_sha256(full)
    end
    return actual
end

function _arc1_environment_snapshot(root::AbstractString)
    source = realpath(root)
    paths = Dict("Project.toml" => realpath(joinpath(source, "Project.toml")),
                 "Manifest.toml" => realpath(joinpath(source, "Manifest.toml")))
    return Dict(name => _arc1_sha256(path) for (name, path) in paths)
end

function _arc1_loaded_dependencies()
    package_info = Pkg.dependencies()
    records = Dict{String,Any}[]
    for (pkgid, mod) in Base.loaded_modules
        pkgid.uuid == ARC1_HSQUARED_UUID && continue
        pkgid.name in ("Base", "Core", "Main") && continue
        info = get(package_info, pkgid.uuid, nothing)
        if info === nothing
            path = pathof(mod)
            path !== nothing && startswith(realpath(path), realpath(Sys.STDLIB)) && continue
            error("loaded dependency $(pkgid.name) ($(pkgid.uuid)) is absent from active Manifest.toml")
        end
        push!(records, Dict{String,Any}("name" => pkgid.name,
                                         "uuid" => string(pkgid.uuid),
                                         "version" => (info.version === nothing ? "" : string(info.version)),
                                         "tree_hash" => (info.tree_hash === nothing ? "" : string(info.tree_hash)),
                                         "source" => string(info.source)))
    end
    sort!(records; by=x -> (x["name"], x["uuid"]))
    return records
end

"""Load HSquared in this fresh Julia process while pinning bytes around the load.

Call this before any `using HSquared`. It activates the supplied immutable source
tree, rejects a preloaded HSquared module, hashes engine and environment files
before and after package loading, and returns the load-time proof used below.
"""
function arc1_load_admitted_engine(source_root::AbstractString,
                                   expected_engine_sha256::Dict{String,String},
                                   expected_environment_sha256::Dict{String,String})
    source = realpath(source_root)
    any(pkgid.uuid == ARC1_HSQUARED_UUID for (pkgid, _) in Base.loaded_modules) &&
        error("HSquared was already loaded; Arc1 execution requires a fresh Julia process")
    expected_environment_sha256 == Dict("Project.toml" => get(expected_environment_sha256, "Project.toml", ""),
                                         "Manifest.toml" => get(expected_environment_sha256, "Manifest.toml", "")) ||
        error("expected environment identity must pin exactly Project.toml and Manifest.toml")
    before_engine = _arc1_snapshot(source, expected_engine_sha256)
    before_environment = _arc1_environment_snapshot(source)
    before_engine == expected_engine_sha256 || error("source bytes differ from admitted engine identity before load")
    before_environment == expected_environment_sha256 || error("Project/Manifest bytes differ from admitted environment before load")
    Pkg.activate(source; io=devnull)
    active = realpath(Base.active_project())
    active == realpath(joinpath(source, "Project.toml")) || error("active Julia project is not the admitted source root")
    engine = Base.require(Base.PkgId(ARC1_HSQUARED_UUID, "HSquared"))
    engine isa Module && nameof(engine) === :HSquared || error("loaded package identity is not module HSquared")
    pathof(engine) !== nothing && realpath(pathof(engine)) == realpath(joinpath(source, "src", "HSquared.jl")) ||
        error("loaded HSquared module path differs from admitted source root")
    after_engine = _arc1_snapshot(source, expected_engine_sha256)
    after_environment = _arc1_environment_snapshot(source)
    after_engine == before_engine || error("engine source changed during package load")
    after_environment == before_environment || error("Project/Manifest changed during package load")
    return Arc1LoadedEngine(engine, source, before_engine, before_environment, active,
                            _arc1_loaded_dependencies())
end

"""Build runtime identity only if load-time and fresh disk snapshots still match admission."""
function arc1_execution_identity(loaded::Arc1LoadedEngine,
                                 expected_engine_sha256::Dict{String,String},
                                 expected_environment_sha256::Dict{String,String};
                                 blas_environment=get(ENV, "OPENBLAS_NUM_THREADS", ""))
    loaded.source_sha256_at_load == expected_engine_sha256 ||
        error("loaded module source identity differs from admitted expected hashes")
    loaded.environment_sha256_at_load == expected_environment_sha256 ||
        error("loaded module environment identity differs from admitted expected hashes")
    live_engine = _arc1_snapshot(loaded.source_root, expected_engine_sha256)
    live_environment = _arc1_environment_snapshot(loaded.source_root)
    live_engine == loaded.source_sha256_at_load || error("engine source changed after module load")
    live_environment == loaded.environment_sha256_at_load || error("Project/Manifest changed after module load")
    loaded.active_project == realpath(Base.active_project()) || error("active project changed after engine load")
    live_dependencies = _arc1_loaded_dependencies()
    live_dependencies == loaded.loaded_dependencies || error("loaded dependency identities changed after engine load")
    pkgid = only([(id, mod) for (id, mod) in Base.loaded_modules if mod === loaded.module_object])[1]
    return (; engine_package_uuid=string(pkgid.uuid), engine_module_path=realpath(pathof(loaded.module_object)),
            loaded_module_names=[string(nameof(loaded.module_object))],
            source_sha256_at_load=copy(loaded.source_sha256_at_load),
            source_sha256_after_load=live_engine,
            loaded_engine_source_sha256=live_engine,
            environment_sha256=live_environment, active_project=loaded.active_project,
            loaded_dependencies=live_dependencies, dependency_environment_verified=true,
            julia_version=string(VERSION), julia_threads=Threads.nthreads(),
            blas_runtime_threads=BLAS.get_num_threads(), blas_vendor=string(BLAS.vendor()),
            thread_environment=(; JULIA_NUM_THREADS=get(ENV, "JULIA_NUM_THREADS", ""),
                                 OPENBLAS_NUM_THREADS=string(blas_environment)))
end
