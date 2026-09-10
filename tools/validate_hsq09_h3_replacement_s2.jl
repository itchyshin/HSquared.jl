using SHA
using TOML

const H3_REPLACEMENT_S2_ROOT = normpath(joinpath(@__DIR__, ".."))
const H3_REPLACEMENT_S2_MANIFEST = joinpath(H3_REPLACEMENT_S2_ROOT, "docs", "dev-log", "evidence",
    "2026-09-09-h3-replacement-s2-manifest.toml")
const H3_REPLACEMENT_S2_FIXTURE = joinpath(H3_REPLACEMENT_S2_ROOT, "test", "fixtures",
    "h3_replacement_interval", "fixture.toml")
const H3_REPLACEMENT_S2_DRIVER = joinpath(H3_REPLACEMENT_S2_ROOT, "sim",
    "h3_replacement_interval_fixture.jl")
const H3_REPLACEMENT_S2_TEST = joinpath(H3_REPLACEMENT_S2_ROOT, "test",
    "test_hsq09_h3_replacement_s2.jl")
const H3_REPLACEMENT_S2_LOCK = joinpath(H3_REPLACEMENT_S2_ROOT, "Manifest.toml")

const H3_REPLACEMENT_S2_SCHEMA = Dict(
    "manifest" => Set(["id", "kind", "source_inert", "compute_permitted"]),
    "candidate" => Set(["base_commit", "julia_executable", "fixture_path", "fixture_sha256",
        "driver_path", "driver_sha256", "test_path", "test_sha256", "manifest_lock_path", "manifest_lock_sha256"]),
    "rg" => Set(["estimand", "animals", "records", "seed", "iterations", "fit", "interval", "method", "level", "initializer"]),
    "ram" => Set(["estimand", "animals", "records", "seed", "iterations", "fit", "interval", "method", "level", "initializer"]),
    "negative_controls" => Set(["rg", "ram", "no_pooling"]),
    "authorizations" => Set(["s10", "s11", "compute", "promotion", "versioning", "tag", "registry", "release"]),
)

const H3_REPLACEMENT_S2_EXPECTED = Dict(
    ("manifest", "id") => "HSQ09-H3-REPLACEMENT-S2-01",
    ("manifest", "kind") => "ratified_h3_fixture_materialization",
    ("manifest", "source_inert") => true,
    ("manifest", "compute_permitted") => false,
    ("candidate", "base_commit") => "df704655208dccef859229832738e60f8a6d96c3",
    ("candidate", "julia_executable") => "/Users/z3437171/.juliaup/bin/julia",
    ("candidate", "fixture_path") => "test/fixtures/h3_replacement_interval/fixture.toml",
    ("candidate", "fixture_sha256") => "8c3ccaf70e005d9b0b7b5e96cf4b3cbaf7b489522b30a37c31dfaf12e1e0c82a",
    ("candidate", "driver_path") => "sim/h3_replacement_interval_fixture.jl",
    ("candidate", "driver_sha256") => "617d0b90c9eddb612567d544d6c6f5068b8187dbc55f792b63edb09b1b442d67",
    ("candidate", "test_path") => "test/test_hsq09_h3_replacement_s2.jl",
    ("candidate", "test_sha256") => "12ab13fbf772139bf85f0e90e2d9a41676d5eb4325d45775c67fa95a5200b4f5",
    ("candidate", "manifest_lock_path") => "Manifest.toml",
    ("candidate", "manifest_lock_sha256") => "a3d4803f05af9738bc5796b1534bdb3249a263efb6c618cae6088d3f0c7ce221",
    ("rg", "estimand") => "r_g", ("rg", "animals") => 80, ("rg", "records") => 240,
    ("rg", "seed") => 2026090901, ("rg", "iterations") => 5000,
    ("rg", "fit") => "fit_multivariate_reml", ("rg", "interval") => "genetic_correlation_interval",
    ("rg", "method") => "delta", ("rg", "level") => 0.95,
    ("rg", "initializer") => "phenotypic_scale_default; initial=nothing",
    ("ram", "estimand") => "r_am", ("ram", "animals") => 996, ("ram", "records") => 960,
    ("ram", "seed") => 2026090902, ("ram", "iterations") => 200,
    ("ram", "fit") => "fit_direct_maternal_reml", ("ram", "interval") => "direct_maternal_interval",
    ("ram", "method") => "fisher_z", ("ram", "level") => 0.95,
    ("ram", "initializer") => "G_dm=I2; sigma_e2=1.0; initial is not truth",
    ("negative_controls", "rg") => "G12=0.9; non_interpretable; excluded",
    ("negative_controls", "ram") => "dam_own_records=false; retained separately; excluded",
    ("negative_controls", "no_pooling") => true,
    ("authorizations", "s10") => false, ("authorizations", "s11") => false,
    ("authorizations", "compute") => false, ("authorizations", "promotion") => false,
    ("authorizations", "versioning") => false, ("authorizations", "tag") => false,
    ("authorizations", "registry") => false, ("authorizations", "release") => false,
)

_sha256(path::AbstractString) = bytes2hex(sha256(read(path)))

function _h3_replacement_s2_validate(path::AbstractString = H3_REPLACEMENT_S2_MANIFEST;
                                     fixture_path::AbstractString = H3_REPLACEMENT_S2_FIXTURE,
                                     driver_path::AbstractString = H3_REPLACEMENT_S2_DRIVER,
                                     test_path::AbstractString = H3_REPLACEMENT_S2_TEST,
                                     lock_path::AbstractString = H3_REPLACEMENT_S2_LOCK)
    parsed = TOML.parsefile(path)
    Set(keys(parsed)) == Set(keys(H3_REPLACEMENT_S2_SCHEMA)) || error("H3 replacement S2 sections are not closed")
    for (section, expected_keys) in H3_REPLACEMENT_S2_SCHEMA
        Set(keys(parsed[section])) == expected_keys || error("H3 replacement S2 keys are not closed in $(section)")
    end
    for ((section, key), expected) in H3_REPLACEMENT_S2_EXPECTED
        get(parsed[section], key, nothing) == expected || error("H3 replacement S2 mismatch at $(section).$(key)")
    end
    _sha256(fixture_path) == parsed["candidate"]["fixture_sha256"] || error("H3 replacement S2 fixture digest mismatch")
    _sha256(driver_path) == parsed["candidate"]["driver_sha256"] || error("H3 replacement S2 driver digest mismatch")
    _sha256(test_path) == parsed["candidate"]["test_sha256"] || error("H3 replacement S2 test digest mismatch")
    _sha256(lock_path) == parsed["candidate"]["manifest_lock_sha256"] || error("H3 replacement S2 lock digest mismatch")
    return parsed
end

"""Read and validate the sealed, source-inert H3 replacement materialization."""
h3_replacement_s2_manifest() = _h3_replacement_s2_validate()

function h3_replacement_s2_fixture_mutation_test()
    mktempdir() do dir
        fixture = joinpath(dir, "fixture.toml")
        driver = joinpath(dir, "driver.jl")
        test = joinpath(dir, "test.jl")
        lock = joinpath(dir, "Manifest.toml")
        write(fixture, replace(read(H3_REPLACEMENT_S2_FIXTURE, String),
            "seed = 2026090901" => "seed = 2026090999"; count = 1))
        write(driver, read(H3_REPLACEMENT_S2_DRIVER, String) * "\n# mutation\n")
        write(test, read(H3_REPLACEMENT_S2_TEST, String) * "\n# mutation\n")
        write(lock, "not the sealed environment\n")
        for changed in ((fixture_path = fixture,), (driver_path = driver,), (test_path = test,), (lock_path = lock,))
            try
                _h3_replacement_s2_validate(H3_REPLACEMENT_S2_MANIFEST; changed...)
                error("governed input mutation was accepted")
            catch err
                occursin("was accepted", sprint(showerror, err)) && rethrow()
            end
        end
    end
    return true
end

function h3_replacement_s2_self_test()
    h3_replacement_s2_manifest()
    h3_replacement_s2_fixture_mutation_test()
    source = read(H3_REPLACEMENT_S2_MANIFEST, String)
    mktempdir() do dir
        for ((_, key), expected) in H3_REPLACEMENT_S2_EXPECTED
            from = "$(key) = $(repr(expected))"
            to = "$(key) = \"__MUTATED__\""
            mutated = joinpath(dir, "$(key).toml")
            write(mutated, replace(source, from => to; count = 1))
            try
                _h3_replacement_s2_validate(mutated)
                error("mutation $(key) was accepted")
            catch err
                occursin("was accepted", sprint(showerror, err)) && rethrow()
            end
        end
        unknown = joinpath(dir, "unknown.toml")
        write(unknown, source * "\n[unreviewed]\nclaim = \"not-governed\"\n")
        try
            _h3_replacement_s2_validate(unknown)
            error("unknown section was accepted")
        catch err
            occursin("was accepted", sprint(showerror, err)) && rethrow()
        end
    end
    return true
end

function main(args = ARGS)
    if args == ["--validate"]
        h3_replacement_s2_manifest()
        println("H3_REPLACEMENT_S2_FIXTURE_OK")
        println("H3_REPLACEMENT_S2_MANIFEST_OK")
    elseif args == ["--self-test"]
        h3_replacement_s2_self_test()
        println("H3_REPLACEMENT_S2_MUTATION_CONTROLS_OK")
    else
        error("usage: --validate | --self-test; this validator never starts a fit or remote action")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
