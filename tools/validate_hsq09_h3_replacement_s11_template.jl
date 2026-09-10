#!/usr/bin/env julia

using SHA
using TOML

const TEMPLATE = joinpath(@__DIR__, "..", "docs", "dev-log", "evidence",
    "2026-09-09-h3-replacement-s11-template.toml")

const DECISION_REQUIRED = "MAINTAINER_DECISION_REQUIRED"
const EXPECTED_TEMPLATE = Dict(
    "id" => "HSQ09-H3-REPLACEMENT-S11-TEMPLATE-01",
    "schema_version" => 1,
    "status" => "unratified_refusal_only",
    "engine_capability_inert" => true,
    "no_pooling" => true,
)
const EXPECTED_CANDIDATE = Dict(
    "s10_closeout_commit" => "93cdc044148ef9f70fa7b03a536d1c44ade05b6b",
    "s10_runner_commit" => "dd7eeb60",
    "fixture_path" => "test/fixtures/h3_replacement_interval/fixture.toml",
    "fixture_sha256" => "8c3ccaf70e005d9b0b7b5e96cf4b3cbaf7b489522b30a37c31dfaf12e1e0c82a",
    "s10_manifest_path" => "docs/dev-log/evidence/2026-09-09-hsq09-h3-replacement-s10-manifest.toml",
    "s10_manifest_sha256" => "5f690a73904b099ef9721ba11d38bf8d9c687c02919c58597695ecc07bc1e9dd",
)
const EXPECTED_RECEIPTS = Dict(
    "rg" => Dict("cell" => "rg", "estimand" => "r_g",
        "receipt_sha256" => "0c6bb55ee0a9c8188f01a0c1fe7f8ae3a2adb45ed4ad478aba24ee439be09ca9",
        "runtime_seconds" => 8.15),
    "ram" => Dict("cell" => "ram", "estimand" => "r_am",
        "receipt_sha256" => "79e657ce01fefa24bb1564ebe2aeb9e2301e31a80ee66e6e6b53ab36c4725a26",
        "runtime_seconds" => 43.26),
)

fail(message) = error("H3 replacement S11 template: " * message)

function exact_keys(table, expected, label)
    table isa AbstractDict || fail("$(label) must be a TOML table")
    Set(String(k) for k in keys(table)) == Set(expected) || fail("$(label) has wrong keys")
end

function exact_table(table, expected, label)
    exact_keys(table, keys(expected), label)
    for (key, value) in expected
        table[key] == value || fail("$(label).$(key) differs")
    end
end

function h3_replacement_s11_template_validate(path::AbstractString = TEMPLATE)
    data = TOML.parsefile(path)
    exact_keys(data, ["template", "candidate", "s10_receipts", "maintainer_fields", "authorizations", "execution"], "root")
    exact_table(data["template"], EXPECTED_TEMPLATE, "template")
    exact_table(data["candidate"], EXPECTED_CANDIDATE, "candidate")
    exact_keys(data["s10_receipts"], ["rg", "ram"], "s10_receipts")
    for (cell, expected) in EXPECTED_RECEIPTS
        exact_table(data["s10_receipts"][cell], expected, "s10_receipts.$(cell)")
    end
    exact_keys(data["maintainer_fields"], ["seed_schedule", "replicates_per_estimand", "interval_success_floor", "mcse_rule", "classification_rule", "compute_route"], "maintainer_fields")
    all(value == DECISION_REQUIRED for value in values(data["maintainer_fields"])) ||
        fail("all maintainer fields must remain undecided")
    exact_keys(data["authorizations"], ["s11", "compute", "promotion", "versioning", "tag", "registry", "release"], "authorizations")
    all(value === false for value in values(data["authorizations"])) ||
        fail("all authorizations must remain false")
    exact_table(data["execution"], Dict("armed" => false, "mode" => "refusal_only", "effective_exit_code" => 78), "execution")
    nothing
end

function h3_replacement_s11_template_mutation_controls(path::AbstractString = TEMPLATE)
    source = read(path, String)
    mutations = [
        ("S11 authorization", replace(source, "s11 = false" => "s11 = true"; count = 1)),
        ("seed schedule", replace(source, "seed_schedule = \"$(DECISION_REQUIRED)\"" => "seed_schedule = \"2026091001:2026093000\""; count = 1)),
        ("replicate count", replace(source, "replicates_per_estimand = \"$(DECISION_REQUIRED)\"" => "replicates_per_estimand = \"2000\""; count = 1)),
        ("receipt identity", replace(source, EXPECTED_RECEIPTS["rg"]["receipt_sha256"] => repeat("0", 64); count = 1)),
        ("unknown section", source * "\n[forbidden]\nvalue = true\n"),
    ]
    for (label, altered) in mutations
        mktempdir() do temp
            altered_path = joinpath(temp, "template.toml")
            write(altered_path, altered)
            rejected = false
            try
                h3_replacement_s11_template_validate(altered_path)
            catch error
                rejected = error isa ErrorException
            end
            rejected || fail("mutation unexpectedly passed: $(label)")
        end
    end
    nothing
end

function h3_replacement_s11_template_main(args = ARGS)
    args == ["--self-test"] || fail("only --self-test is accepted")
    h3_replacement_s11_template_validate()
    println("H3_REPLACEMENT_S11_TEMPLATE_OK")
    h3_replacement_s11_template_mutation_controls()
    println("H3_REPLACEMENT_S11_TEMPLATE_MUTATIONS_OK")
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    h3_replacement_s11_template_main()
end
