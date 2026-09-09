using TOML

const HSQ09_H3_G0_MANIFEST = normpath(joinpath(@__DIR__, "..", "docs", "dev-log", "evidence",
                                                "2026-09-09-h3-g0-prerun-manifest.toml"))
const HSQ09_H3_G0_EXPECTED = Dict(
    ("manifest", "id") => "HSQ09-H3-G0-PRERUN-01",
    ("manifest", "kind") => "unarmed_h3_prerun_card",
    ("manifest", "engine_capability_inert") => true,
    ("candidate", "julia_commit") => "82f836f368e37cf75609f721f7a03bde3113e10b",
    ("candidate", "driver_sha256") => "6c1b74cc207247241e395bd78143c07f01b0091682d3049e57bfdbb1a8d0401d",
    ("candidate", "sbatch_template_sha256") => "660208954d881076e6a848a2729e0ee992bac9f65243fc572d62ee5737f6ab17",
    ("candidate", "predeclaration_sha256") => "0c8a6b27e08fcae25be1f5051066c80c34fcc561cc4ffc955800161cb216922e",
    ("candidate", "environment_manifest_sha256") => "a3d4803f05af9738bc5796b1534bdb3249a263efb6c618cae6088d3f0c7ce221",
    ("h3_rg", "estimand") => "r_g",
    ("h3_rg", "interval") => "genetic_correlation_interval",
    ("h3_rg", "scale") => "Fisher-z",
    ("h3_ram", "estimand") => "r_am",
    ("h3_ram", "interval") => "direct_maternal_interval",
    ("h3_ram", "scale") => "Fisher-z",
    ("proposed_smoke", "target") => "Totoro",
    ("proposed_smoke", "mode") => "smoke",
    ("proposed_smoke", "campaigns") => ["h3_rg", "h3_ram"],
    ("proposed_smoke", "reps") => 1,
    ("proposed_smoke", "seed") => 20260903,
    ("proposed_smoke", "julia_threads") => 1,
    ("proposed_smoke", "openblas_threads") => 1,
    ("proposed_smoke", "claim") => "PATH_ONLY",
    ("proposed_confirm", "target") => "DRAC",
    ("proposed_confirm", "mode") => "confirm",
    ("proposed_confirm", "reps_per_cell") => 2000,
    ("proposed_confirm", "retention") => "one retained row per estimand, cell, seed; failures remain in interval_success accounting",
    ("authorizations", "h3_ratification") => false,
    ("authorizations", "totoro_smoke") => false,
    ("authorizations", "drac_confirm") => false,
    ("authorizations", "compute") => false,
    ("authorizations", "promotion") => false,
    ("authorizations", "versioning") => false,
    ("authorizations", "tag") => false,
    ("authorizations", "registry") => false,
    ("authorizations", "release") => false,
)
const HSQ09_H3_G0_SCHEMA = Dict(
    "manifest" => Set(["id", "kind", "engine_capability_inert"]),
    "candidate" => Set(["julia_commit", "driver_sha256", "sbatch_template_sha256", "predeclaration_sha256", "environment_manifest_sha256"]),
    "h3_rg" => Set(["estimand", "interval", "scale", "smoke_cell", "confirm_cell", "boundary"]),
    "h3_ram" => Set(["estimand", "interval", "scale", "smoke_cell", "confirm_cell", "boundary"]),
    "proposed_smoke" => Set(["target", "mode", "campaigns", "reps", "seed", "julia_threads", "openblas_threads", "claim"]),
    "proposed_confirm" => Set(["target", "mode", "reps_per_cell", "retention"]),
    "authorizations" => Set(["h3_ratification", "totoro_smoke", "drac_confirm", "compute", "promotion", "versioning", "tag", "registry", "release"]),
)

function _hsq09_h3_g0_validate(path::AbstractString)
    parsed = TOML.parsefile(path)
    Set(keys(parsed)) == Set(keys(HSQ09_H3_G0_SCHEMA)) || error("H3 G0 manifest sections are not closed")
    for (section, keys_expected) in HSQ09_H3_G0_SCHEMA
        Set(keys(parsed[section])) == keys_expected || error("H3 G0 manifest keys are not closed in $(section)")
    end
    for ((section, key), expected) in HSQ09_H3_G0_EXPECTED
        get(parsed[section], key, nothing) == expected || error("H3 G0 manifest mismatch at $(section).$(key)")
    end
    return parsed
end

"""Parse and validate the unarmed H3 G0 pre-run manifest."""
hsq09_h3_g0_manifest() = _hsq09_h3_g0_validate(HSQ09_H3_G0_MANIFEST)

function hsq09_h3_g0_manifest_self_test()
    hsq09_h3_g0_manifest()
    source = read(HSQ09_H3_G0_MANIFEST, String)
    mktempdir() do dir
        for ((_, key), expected) in HSQ09_H3_G0_EXPECTED
            from = "$(key) = $(repr(expected))"
            to = "$(key) = \"__MUTATED__\""
            path = joinpath(dir, "mutation.toml")
            write(path, replace(source, from => to; count = 1))
            try
                _hsq09_h3_g0_validate(path)
                error("mutation $(key) was accepted")
            catch err
                occursin("was accepted", sprint(showerror, err)) && rethrow()
            end
        end
        path = joinpath(dir, "unknown.toml")
        write(path, source * "\n[unreviewed]\nclaim = \"not-governed\"\n")
        try
            _hsq09_h3_g0_validate(path)
            error("unknown section was accepted")
        catch err
            occursin("was accepted", sprint(showerror, err)) && rethrow()
        end
    end
    return true
end

if abspath(PROGRAM_FILE) == @__FILE__
    hsq09_h3_g0_manifest_self_test()
    println("HSQ09_H3_G0_MANIFEST_OK")
    println("HSQ09_H3_G0_MANIFEST_MUTATIONS_OK")
end
