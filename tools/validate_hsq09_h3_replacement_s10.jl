#!/usr/bin/env julia
# Deterministic validator for the sealed H3 replacement S10 infrastructure.
# It never starts a fit, a remote action, or a retry.

using SHA
using TOML

const H3R_S10_ROOT = normpath(joinpath(@__DIR__, ".."))
const H3R_S10_MANIFEST = joinpath(H3R_S10_ROOT, "docs", "dev-log", "evidence",
    "2026-09-09-hsq09-h3-replacement-s10-manifest.toml")
const H3R_S10_FIXTURE = joinpath(H3R_S10_ROOT, "test", "fixtures",
    "h3_replacement_interval", "fixture.toml")
const H3R_S10_S2_MANIFEST = joinpath(H3R_S10_ROOT, "docs", "dev-log", "evidence",
    "2026-09-09-h3-replacement-s2-manifest.toml")
const H3R_S10_RUNNER = joinpath(H3R_S10_ROOT, "sim", "hsq09_h3_replacement_s10.jl")
const H3R_S10_LAUNCHER = joinpath(H3R_S10_ROOT, "tools", "run_hsq09_h3_replacement_s10_totoro.sh")
const H3R_S10_LOCK = joinpath(H3R_S10_ROOT, "Manifest.toml")

include(H3R_S10_RUNNER)

_sha256(path::AbstractString) = bytes2hex(sha256(read(path)))

const H3R_S10_REQUIRED = Dict(
    "manifest" => Set(["id", "kind", "source_inert", "path_only", "no_pooling"]),
    "candidate" => Set(["materialization_commit", "fixture_path", "fixture_sha256",
        "materialization_manifest_path", "materialization_manifest_sha256", "runner_path",
        "runner_sha256", "launcher_path", "launcher_sha256", "manifest_lock_path", "manifest_lock_sha256"]),
    "authorization" => Set(["s10", "compute", "s11", "promotion", "versioning", "tag", "registry", "release"]),
    "rg" => Set(["estimand", "seed", "animals", "records", "iterations", "threads", "path_only", "initializer"]),
    "ram" => Set(["estimand", "seed", "animals", "records", "iterations", "threads", "path_only", "initializer"]),
)

function _require(x::Bool, msg::AbstractString)
    x || error("H3 replacement S10 rejected: $(msg)")
    return nothing
end

function _validate_manifest(path::AbstractString = H3R_S10_MANIFEST;
                            fixture_path::AbstractString = H3R_S10_FIXTURE,
                            materialization_manifest_path::AbstractString = H3R_S10_S2_MANIFEST,
                            runner_path::AbstractString = H3R_S10_RUNNER,
                            launcher_path::AbstractString = H3R_S10_LAUNCHER,
                            lock_path::AbstractString = H3R_S10_LOCK)
    data = TOML.parsefile(path)
    _require(Set(keys(data)) == Set(keys(H3R_S10_REQUIRED)), "manifest sections are not closed")
    for (section, fields) in H3R_S10_REQUIRED
        _require(Set(keys(data[section])) == fields, "keys are not closed in $(section)")
    end
    _require(data["manifest"]["id"] == "HSQ09-H3-REPLACEMENT-S10-01", "wrong id")
    _require(data["manifest"]["source_inert"] === true && data["manifest"]["path_only"] === true && data["manifest"]["no_pooling"] === true,
        "source-inert PATH_ONLY no-pooling controls changed")
    _require(data["candidate"]["materialization_commit"] == "46232fbc", "wrong materialization commit")
    _require(data["candidate"]["fixture_path"] == "test/fixtures/h3_replacement_interval/fixture.toml", "fixture path changed")
    _require(data["candidate"]["runner_path"] == "sim/hsq09_h3_replacement_s10.jl", "runner path changed")
    _require(data["candidate"]["launcher_path"] == "tools/run_hsq09_h3_replacement_s10_totoro.sh", "launcher path changed")
    _require(data["candidate"]["manifest_lock_path"] == "Manifest.toml", "lock path changed")
    _require(_sha256(fixture_path) == data["candidate"]["fixture_sha256"], "fixture digest mismatch")
    _require(_sha256(materialization_manifest_path) == data["candidate"]["materialization_manifest_sha256"], "materialization manifest digest mismatch")
    _require(_sha256(runner_path) == data["candidate"]["runner_sha256"], "runner digest mismatch")
    _require(_sha256(launcher_path) == data["candidate"]["launcher_sha256"], "launcher digest mismatch")
    _require(_sha256(lock_path) == data["candidate"]["manifest_lock_sha256"], "lock digest mismatch")
    auth = data["authorization"]
    _require(auth["s10"] === true && auth["compute"] === true, "S10 authorization absent")
    _require(all(auth[key] === false for key in ("s11", "promotion", "versioning", "tag", "registry", "release")),
        "a downstream action is improperly authorized")
    for (cell, seed, animals, records, iterations, init) in (
            ("rg", 2026090901, 80, 240, 5000, "phenotypic_scale_default; initial=nothing"),
            ("ram", 2026090902, 996, 960, 200, "G_dm=I2; sigma_e2=1.0; initial is not truth"))
        row = data[cell]
        _require(row["estimand"] == (cell == "rg" ? "r_g" : "r_am"), "wrong $(cell) estimand")
        _require(row["seed"] == seed && row["animals"] == animals && row["records"] == records && row["iterations"] == iterations,
            "wrong fixed $(cell) parameters")
        _require(row["threads"] == 1 && row["path_only"] === true && row["initializer"] == init,
            "wrong $(cell) execution constraints")
    end
    return data
end

h3_replacement_s10_manifest() = _validate_manifest()

function h3_replacement_s10_mutation_test()
    _validate_manifest()
    source = read(H3R_S10_MANIFEST, String)
    mktempdir() do dir
        for (needle, replacement, label) in (("s11 = false", "s11 = true", "s11"),
                ("seed = 2026090901", "seed = 2026090999", "rg-seed"),
                ("threads = 1", "threads = 2", "threads"),
                ("path_only = true", "path_only = false", "path-only"))
            mutated = joinpath(dir, "$(label).toml")
            write(mutated, replace(source, needle => replacement; count = 1))
            rejected = false
            try
                _validate_manifest(mutated)
            catch
                rejected = true
            end
            rejected || error("manifest mutation $(label) was accepted")
        end
        for (path, label, kw) in ((H3R_S10_FIXTURE, "fixture", :fixture_path),
                (H3R_S10_RUNNER, "runner", :runner_path), (H3R_S10_LAUNCHER, "launcher", :launcher_path),
                (H3R_S10_LOCK, "lock", :lock_path))
            altered = joinpath(dir, "$(label).txt")
            write(altered, read(path, String) * "\n# mutation $(label)\n")
            rejected = false
            try
                _validate_manifest(H3R_S10_MANIFEST; (kw => altered)...)
            catch
                rejected = true
            end
            rejected || error("governed $(label) mutation was accepted")
        end
    end
    return true
end

function _validate_receipt(path::AbstractString, cell::String)
    data = TOML.parsefile(path)
    _require(data["schema"] == "HSQ09-H3-REPLACEMENT-S10-RECEIPT-01", "wrong receipt schema")
    _require(data["cell"] == cell, "wrong receipt cell")
    _require(data["path_only"] === true && data["claim_eligible"] === false && data["s11_authorized"] === false &&
        data["promotion_authorized"] === false && data["release_authorized"] === false, "receipt widened scope")
    expected = h3_replacement_s10_cell(cell)
    for key in ("seed", "animals", "records", "iterations", "level", "fit", "interval")
        _require(data[key] == expected[key], "receipt $(cell) mismatches $(key)")
    end
    if data["interval_success"] === true
        _require(data["fit_converged"] === true && data["interval_converged"] === true, "successful receipt lacks convergence")
        _require(-1.0 < data["lower"] < data["estimate"] < data["upper"] < 1.0, "successful receipt is not strictly interior")
    else
        _require(!isempty(data["failure_reason"]), "failed receipt lacks reason")
    end
    return nothing
end

function validate_h3_replacement_s10_receipts(rg_path::AbstractString, ram_path::AbstractString)
    _validate_manifest()
    _validate_receipt(rg_path, "rg")
    _validate_receipt(ram_path, "ram")
    return nothing
end

function main(args = ARGS)
    if args == ["--validate"]
        _validate_manifest()
        println("H3_REPLACEMENT_S10_MANIFEST_OK")
    elseif length(args) == 3 && args[1] == "--validate-receipts"
        validate_h3_replacement_s10_receipts(args[2], args[3])
        println("H3_REPLACEMENT_S10_RECEIPTS_OK")
    elseif length(args) == 3 && args[1] == "--validate-receipt" && args[2] in ("rg", "ram")
        _validate_manifest()
        _validate_receipt(args[3], args[2])
        println("H3_REPLACEMENT_S10_RECEIPT_OK cell=$(args[2])")
    else
        error("usage: --validate | --validate-receipt rg|ram RECEIPT.toml | --validate-receipts RG.toml RAM.toml; this validator never starts a fit")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
