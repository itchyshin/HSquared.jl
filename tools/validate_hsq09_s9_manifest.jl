#!/usr/bin/env julia

using SHA
using TOML

const S9_JULIA_BASE_COMMIT = "1dbf8b97a3b28f814e3418239ac1658acbbc19bb"
const S9_R_COMMIT = "e6a1ce4e8a691795487420668b349fb9e2670059"
const S9_MANIFEST_REL = joinpath("docs", "dev-log", "evidence", "2026-09-07-hsq09-s9-evidence-manifest.toml")
const S9_ALLOWED_JULIA_DIRTY = Set([
    S9_MANIFEST_REL,
    joinpath("tools", "validate_hsq09_s9_manifest.jl"),
    joinpath("test", "test_hsq09_s9_manifest.jl"),
])

const S9_EXPECTED_INPUTS = Dict(
    "r_h0_univariate_coverage_flip" => (
        repository = "r",
        path = "docs/design/39-h0-univariate-coverage-flip.md",
        role = "H0 protocol",
    ),
    "r_h1_interval_recovery_preregistration" => (
        repository = "r",
        path = "docs/design/34-interval-recovery-pre-registration.md",
        role = "H1 protocol",
    ),
    "r_h1_h3_path_pointer" => (
        repository = "r",
        path = "docs/dev-log/recovery-checkpoints/2026-09-03-c1-ext-h1-h3-r-pointer.md",
        role = "H1/H3 pointer protocol",
    ),
    "julia_h1_h3_predeclaration" => (
        repository = "julia",
        path = "docs/dev-log/recovery-checkpoints/2026-09-03-c1-ext-h1-h3-ademp-predeclaration.md",
        role = "H1/H3 protocol",
    ),
    "julia_phase1_interval_driver" => (
        repository = "julia",
        path = "sim/phase1_interval_coverage_ext.jl",
        role = "phase1 interval Julia driver",
    ),
    "julia_phase1_interval_test" => (
        repository = "julia",
        path = "test/test_phase1_interval_coverage_ext.jl",
        role = "phase1 interval Julia test",
    ),
    "julia_phase1_interval_sbatch" => (
        repository = "julia",
        path = "sim/drac/phase1_interval_coverage_ext.sbatch",
        role = "unarmed phase1 interval sbatch template",
    ),
    "julia_real_data_validation_manifest" => (
        repository = "julia",
        path = "docs/design/real-data-validation-manifest.toml",
        role = "Julia real-data validation manifest",
    ),
    "r_phase1_interval_pointer" => (
        repository = "r",
        path = "sim/phase1_interval_coverage_ext.R",
        role = "R path-only pointer driver",
    ),
    "r_phase1_interval_pointer_test" => (
        repository = "r",
        path = "tests/testthat/test-c1-ext-h1-h3-harness.R",
        role = "R pointer test",
    ),
    "r_real_data_validation_manifest" => (
        repository = "r",
        path = "docs/design/real-data-validation-manifest.toml",
        role = "R real-data validation manifest",
    ),
)

s9_fail(message::AbstractString) = error("S9 manifest: " * message)

function s9_string_set(value, context::AbstractString)
    value isa Vector || s9_fail("$(context) must be an array")
    all(item -> item isa String, value) || s9_fail("$(context) must contain only strings")
    strings = Set(value)
    length(strings) == length(value) || s9_fail("$(context) must not contain duplicates")
    return strings
end

function s9_table(value, context::AbstractString)
    value isa AbstractDict || s9_fail("$(context) must be a table")
    return value
end

function s9_exact_keys(table::AbstractDict, expected::Set{String}, context::AbstractString)
    observed = Set(String(key) for key in keys(table))
    missing = sort!(collect(setdiff(expected, observed)))
    unexpected = sort!(collect(setdiff(observed, expected)))
    isempty(missing) || s9_fail("$(context) is missing keys: $(join(missing, ", "))")
    isempty(unexpected) || s9_fail("$(context) has unknown keys: $(join(unexpected, ", "))")
    return nothing
end

function s9_exact(table::AbstractDict, key::String, expected, context::AbstractString)
    actual = get(table, key, nothing)
    actual == expected || s9_fail("$(context).$(key) must equal $(repr(expected))")
    return nothing
end

function s9_false(table::AbstractDict, key::String, context::AbstractString)
    get(table, key, nothing) === false || s9_fail("$(context).$(key) must be false")
    return nothing
end

function s9_validate_schema(manifest::AbstractDict)
    s9_exact_keys(manifest, Set([
        "manifest", "repositories", "contract", "conditional_coverage",
        "authorizations", "results", "sbatch_template", "exclusions", "protocols", "inputs",
    ]), "manifest")

    metadata = s9_table(manifest["manifest"], "manifest.manifest")
    s9_exact_keys(metadata, Set(["id", "schema_version", "source_inert"]), "manifest.manifest")
    s9_exact(metadata, "id", "HSQ09-S9", "manifest.manifest")
    s9_exact(metadata, "schema_version", 1, "manifest.manifest")
    metadata["source_inert"] === true || s9_fail("manifest.manifest.source_inert must be true")

    repositories = s9_table(manifest["repositories"], "manifest.repositories")
    s9_exact_keys(repositories, Set(["julia", "r"]), "manifest.repositories")
    julia = s9_table(repositories["julia"], "manifest.repositories.julia")
    s9_exact_keys(julia, Set(["base_commit", "allowed_dirty_paths"]), "manifest.repositories.julia")
    s9_exact(julia, "base_commit", S9_JULIA_BASE_COMMIT, "manifest.repositories.julia")
    s9_string_set(julia["allowed_dirty_paths"], "manifest.repositories.julia.allowed_dirty_paths") == S9_ALLOWED_JULIA_DIRTY ||
        s9_fail("manifest.repositories.julia.allowed_dirty_paths must name only the S9 artifacts")

    r = s9_table(repositories["r"], "manifest.repositories.r")
    s9_exact_keys(r, Set(["commit", "root_env"]), "manifest.repositories.r")
    s9_exact(r, "commit", S9_R_COMMIT, "manifest.repositories.r")
    s9_exact(r, "root_env", "HSQ09_S9_R_ROOT", "manifest.repositories.r")

    contract = s9_table(manifest["contract"], "manifest.contract")
    s9_exact_keys(contract, Set([
        "master_seed", "seed_stride", "screen_reps_per_cell",
        "confirm_interpretable_reps_target", "confirm_target_status",
        "nominal_level", "coverage_denominator", "claim_eligible", "gate",
        "recorded_counters",
    ]), "manifest.contract")
    s9_exact(contract, "master_seed", 20260903, "manifest.contract")
    s9_exact(contract, "seed_stride", 40009, "manifest.contract")
    s9_exact(contract, "screen_reps_per_cell", 48, "manifest.contract")
    s9_exact(contract, "confirm_interpretable_reps_target", 2000, "manifest.contract")
    s9_exact(contract, "confirm_target_status", "retained_intended_target_not_run", "manifest.contract")
    s9_exact(contract, "nominal_level", 0.95, "manifest.contract")
    s9_exact(contract, "coverage_denominator", "interval_success", "manifest.contract")
    s9_false(contract, "claim_eligible", "manifest.contract")
    s9_exact(contract, "gate", "PATH_ONLY", "manifest.contract")
    contract["recorded_counters"] == [
        "reps", "fit_success", "fit_converged", "interval_success", "covered", "failure_reason",
    ] || s9_fail("manifest.contract.recorded_counters must preserve the inert C1-ext counters")

    conditional = s9_table(manifest["conditional_coverage"], "manifest.conditional_coverage")
    s9_exact_keys(conditional, Set([
        "denominator_symbol", "denominator", "not_convergence", "interpretable_if", "pooling",
        "observed_coverage", "observed_mcse", "nominal_mcse", "nominal_mcse_status",
        "nominal_band", "nominal_band_status", "level_090_status",
    ]), "manifest.conditional_coverage")
    s9_exact(conditional, "denominator_symbol", "I", "manifest.conditional_coverage")
    s9_exact(conditional, "denominator", "interval_success", "manifest.conditional_coverage")
    conditional["not_convergence"] === true || s9_fail("manifest.conditional_coverage.not_convergence must be true")
    s9_exact(conditional, "interpretable_if", "I >= 0.9 * reps", "manifest.conditional_coverage")
    s9_exact(conditional, "pooling", "sum(covered) / sum(I)", "manifest.conditional_coverage")
    s9_exact(conditional, "observed_coverage", "C / I", "manifest.conditional_coverage")
    s9_exact(conditional, "observed_mcse", "sqrt((C / I) * (1 - C / I) / I)", "manifest.conditional_coverage")
    s9_exact(conditional, "nominal_mcse", "sqrt(0.95 * 0.05 / I)", "manifest.conditional_coverage")
    s9_exact(conditional, "nominal_mcse_status", "descriptive_only", "manifest.conditional_coverage")
    s9_exact(conditional, "nominal_band", "0.95 +/- 2 * observed_MCSE", "manifest.conditional_coverage")
    s9_exact(conditional, "nominal_band_status", "heuristic_not_calibration_proof", "manifest.conditional_coverage")
    s9_exact(conditional, "level_090_status", "descriptive_only", "manifest.conditional_coverage")

    authorizations = s9_table(manifest["authorizations"], "manifest.authorizations")
    authorization_keys = Set([
        "compute", "smoke", "screen", "confirm", "campaign", "promotion", "release",
        "public_count", "version", "h0_ratification", "h1_h3_coverage_claim", "outcomes_import",
    ])
    s9_exact_keys(authorizations, authorization_keys, "manifest.authorizations")
    for key in authorization_keys
        s9_false(authorizations, key, "manifest.authorizations")
    end

    results = s9_table(manifest["results"], "manifest.results")
    result_keys = Set(["results_imported", "result_values_present", "outcomes_imported"])
    s9_exact_keys(results, result_keys, "manifest.results")
    for key in result_keys
        s9_false(results, key, "manifest.results")
    end

    sbatch_template = s9_table(manifest["sbatch_template"], "manifest.sbatch_template")
    s9_exact_keys(sbatch_template, Set(["armed", "effective_exit_code", "execution"]), "manifest.sbatch_template")
    s9_false(sbatch_template, "armed", "manifest.sbatch_template")
    s9_exact(sbatch_template, "effective_exit_code", 78, "manifest.sbatch_template")
    s9_exact(sbatch_template, "execution", "refusal_only", "manifest.sbatch_template")

    exclusions = s9_table(manifest["exclusions"], "manifest.exclusions")
    exclusion_keys = Set([
        "h0_ratification", "h1_h3_coverage_claim", "promotion", "release",
        "public_count", "version", "outcomes_import", "new_c1_tsv_mutation",
    ])
    s9_exact_keys(exclusions, exclusion_keys, "manifest.exclusions")
    for key in exclusion_keys
        s9_false(exclusions, key, "manifest.exclusions")
    end

    protocols = s9_table(manifest["protocols"], "manifest.protocols")
    s9_exact_keys(protocols, Set(["h0", "h1", "h3"]), "manifest.protocols")
    h0 = s9_table(protocols["h0"], "manifest.protocols.h0")
    s9_exact_keys(h0, Set(["record", "governed_input", "s9_ratification_authorized", "status", "outcomes_imported"]), "manifest.protocols.h0")
    s9_exact(h0, "record", "H0", "manifest.protocols.h0")
    s9_exact(h0, "governed_input", "r_h0_univariate_coverage_flip", "manifest.protocols.h0")
    s9_false(h0, "s9_ratification_authorized", "manifest.protocols.h0")
    s9_exact(h0, "status", "not_adjudicated_by_s9", "manifest.protocols.h0")
    s9_false(h0, "outcomes_imported", "manifest.protocols.h0")

    h1 = s9_table(protocols["h1"], "manifest.protocols.h1")
    s9_exact_keys(h1, Set(["record", "governed_input", "coverage_claim", "outcomes_imported", "h1_t_status"]), "manifest.protocols.h1")
    s9_exact(h1, "record", "H1", "manifest.protocols.h1")
    s9_exact(h1, "governed_input", "r_h1_interval_recovery_preregistration", "manifest.protocols.h1")
    s9_false(h1, "coverage_claim", "manifest.protocols.h1")
    s9_false(h1, "outcomes_imported", "manifest.protocols.h1")
    s9_exact(h1, "h1_t_status", "characterization_only_banked_recovery_failure_no_rescue", "manifest.protocols.h1")

    h3 = s9_table(protocols["h3"], "manifest.protocols.h3")
    s9_exact_keys(h3, Set(["record", "governed_input", "coverage_claim", "initialization", "outcomes_imported"]), "manifest.protocols.h3")
    s9_exact(h3, "record", "H3", "manifest.protocols.h3")
    s9_exact(h3, "governed_input", "julia_h1_h3_predeclaration", "manifest.protocols.h3")
    s9_false(h3, "coverage_claim", "manifest.protocols.h3")
    s9_exact(h3, "initialization", "generating_G0_R0", "manifest.protocols.h3")
    s9_false(h3, "outcomes_imported", "manifest.protocols.h3")

    inputs = manifest["inputs"]
    inputs isa Vector || s9_fail("manifest.inputs must be an array of tables")
    length(inputs) == length(S9_EXPECTED_INPUTS) || s9_fail("manifest.inputs must contain every governed input exactly once")
    entries = Dict{String, AbstractDict}()
    for (index, value) in enumerate(inputs)
        entry = s9_table(value, "manifest.inputs[$(index)]")
        s9_exact_keys(entry, Set(["id", "repository", "path", "role", "sha256"]), "manifest.inputs[$(index)]")
        all(entry[key] isa String for key in ("id", "repository", "path", "role", "sha256")) ||
            s9_fail("manifest.inputs[$(index)] values must be strings")
        identifier = entry["id"]
        haskey(entries, identifier) && s9_fail("manifest.inputs repeats $(repr(identifier))")
        expected = get(S9_EXPECTED_INPUTS, identifier, nothing)
        expected === nothing && s9_fail("manifest.inputs has unknown governed input $(repr(identifier))")
        s9_exact(entry, "repository", expected.repository, "manifest.inputs[$(index)]")
        s9_exact(entry, "path", expected.path, "manifest.inputs[$(index)]")
        s9_exact(entry, "role", expected.role, "manifest.inputs[$(index)]")
        occursin(r"^[0-9a-f]{64}$", entry["sha256"]) || s9_fail("manifest.inputs[$(index)].sha256 must be lowercase SHA-256")
        entries[identifier] = entry
    end
    Set(keys(entries)) == Set(keys(S9_EXPECTED_INPUTS)) || s9_fail("manifest.inputs does not match the governed-input set")
    return entries
end

function s9_git_output(root::AbstractString, arguments::Vararg{AbstractString}; allow_failure::Bool = false)
    command_parts = String["git", "-C", String(root)]
    append!(command_parts, String.(collect(arguments)))
    command = Cmd(command_parts)
    try
        return chomp(read(allow_failure ? ignorestatus(command) : command, String))
    catch error
        s9_fail("git command failed for $(repr(root)): $(sprint(showerror, error))")
    end
end

function s9_git_root(root::AbstractString, label::AbstractString)
    isdir(root) || s9_fail("$(label) root is absent: $(repr(root))")
    reported = s9_git_output(root, "rev-parse", "--show-toplevel")
    isdir(reported) || s9_fail("$(label) git root is absent")
    realpath(root) == realpath(reported) || s9_fail("$(label) root must be the checkout root")
    return realpath(reported)
end

function s9_julia_root(manifest_path::AbstractString)
    isfile(manifest_path) || s9_fail("manifest is absent: $(repr(manifest_path))")
    manifest_directory = dirname(abspath(manifest_path))
    isdir(manifest_directory) || s9_fail("Julia manifest directory is absent")
    root = s9_git_output(manifest_directory, "rev-parse", "--show-toplevel")
    isdir(root) || s9_fail("Julia git root is absent")
    root = realpath(root)
    expected_path = joinpath(root, S9_MANIFEST_REL)
    realpath(manifest_path) == realpath(expected_path) || s9_fail("manifest must be at $(S9_MANIFEST_REL)")
    return root
end

function s9_relative_file(root::AbstractString, relative::AbstractString, label::AbstractString)
    isabspath(relative) && s9_fail("$(label) path must be relative")
    occursin('\0', relative) && s9_fail("$(label) path contains a NUL byte")
    candidate = normpath(joinpath(root, relative))
    relative_candidate = relpath(candidate, root)
    (relative_candidate == "." || startswith(relative_candidate, "..")) && s9_fail("$(label) path escapes its repository root")
    isfile(candidate) || s9_fail("$(label) input is absent: $(repr(relative))")
    islink(candidate) && s9_fail("$(label) input must not be a symlink")
    real_candidate = realpath(candidate)
    real_relative = relpath(real_candidate, realpath(root))
    (real_relative == "." || startswith(real_relative, "..")) && s9_fail("$(label) input resolves outside its repository root")
    return candidate
end

function s9_validate_commit(root::AbstractString, expected::AbstractString, label::AbstractString)
    observed = s9_git_output(root, "rev-parse", "HEAD")
    observed == expected || s9_fail("$(label) commit must be $(expected), found $(observed)")
    return nothing
end

function s9_validate_julia_descendant(root::AbstractString)
    head = s9_git_output(root, "rev-parse", "HEAD")
    base = s9_git_output(root, "merge-base", S9_JULIA_BASE_COMMIT, head; allow_failure = true)
    base == S9_JULIA_BASE_COMMIT ||
        s9_fail("Julia HEAD must descend from S8 base $(S9_JULIA_BASE_COMMIT), found $(head)")
    return nothing
end

function s9_status_paths(root::AbstractString, label::AbstractString)
    output = s9_git_output(root, "status", "--porcelain=v1", "--untracked-files=all")
    isempty(output) && return String[]
    paths = String[]
    for line in split(output, '\n'; keepempty = false)
        ncodeunits(line) >= 4 || s9_fail("$(label) has malformed git status")
        path = strip(line[4:end])
        isempty(path) && s9_fail("$(label) has malformed git status path")
        occursin(" -> ", path) && s9_fail("$(label) has a rename/copy status, which is not allowed")
        push!(paths, path)
    end
    return paths
end

function s9_validate_julia_state(root::AbstractString)
    unexpected = setdiff(Set(s9_status_paths(root, "Julia")), S9_ALLOWED_JULIA_DIRTY)
    isempty(unexpected) || s9_fail("Julia checkout is dirty outside S9 artifacts: $(join(sort!(collect(unexpected)), ", "))")
    return nothing
end

function s9_validate_r_root(manifest::AbstractDict)
    root_name = manifest["repositories"]["r"]["root_env"]
    root = strip(get(ENV, root_name, ""))
    isempty(root) && s9_fail("R root environment $(root_name) is absent")
    checkout = s9_git_root(root, "R")
    s9_validate_commit(checkout, S9_R_COMMIT, "R")
    isempty(s9_status_paths(checkout, "R")) || s9_fail("R checkout must be clean")
    return checkout
end

function s9_validate_hashes(entries::Dict{String, AbstractDict}, julia_root::AbstractString, r_root::AbstractString)
    paths = Dict{String, String}()
    for identifier in sort!(collect(keys(entries)))
        entry = entries[identifier]
        root = entry["repository"] == "julia" ? julia_root : r_root
        path = s9_relative_file(root, entry["path"], identifier)
        observed = bytes2hex(sha256(read(path)))
        observed == entry["sha256"] || s9_fail("$(identifier) SHA-256 does not match manifest")
        paths[identifier] = path
    end
    return paths
end

function s9_require_text(path::AbstractString, needle::AbstractString, label::AbstractString)
    occursin(needle, read(path, String)) || s9_fail("$(label) is missing required inert contract text $(repr(needle))")
    return nothing
end

function s9_validate_unarmed_sbatch(path::AbstractString)
    text = read(path, String)
    s9_require_text(path, "# NOT ARMED", "unarmed sbatch template")
    s9_require_text(path, "seed stride = 40009", "unarmed sbatch template")
    s9_require_text(path, "20 tasks × 100 = 2000/cell target", "unarmed sbatch template")
    active = String[]
    for line in split(text, '\n')
        stripped = strip(line)
        isempty(stripped) || startswith(stripped, "#") || push!(active, stripped)
    end
    active == [
        "set -euo pipefail",
        "echo \"REFUSING: this sbatch is NOT ARMED (2026-09-03 C1-ext scaffold).\"",
        "echo \"See docs/dev-log/recovery-checkpoints/2026-09-03-c1-ext-h1-h3-ademp-predeclaration.md\"",
        "exit 78",
    ] || s9_fail("unarmed sbatch template must have only refusal echoes followed by effective exit 78")
    return nothing
end

function s9_validate_source_contract(paths::Dict{String, String})
    s9_require_text(paths["r_h0_univariate_coverage_flip"], "# 39 — H0", "H0 protocol")
    s9_require_text(paths["r_h1_interval_recovery_preregistration"], "denominator is `interval_success`, NOT", "H1 protocol")
    s9_require_text(paths["r_h1_interval_recovery_preregistration"], "interval_success ≥ 0.9 · reps", "H1 protocol")
    s9_require_text(paths["r_h1_interval_recovery_preregistration"], "coverage = Σ covered / Σ interval_success", "H1 protocol")
    s9_require_text(paths["r_h1_interval_recovery_preregistration"], "m_eff = interval_success", "H1 protocol")
    s9_require_text(paths["r_h1_h3_path_pointer"], "This file does not ratify H0 Layer B.", "H1/H3 R pointer")
    s9_require_text(paths["r_h1_h3_path_pointer"], "claim_eligible = false", "H1/H3 R pointer")
    s9_require_text(paths["r_h1_h3_path_pointer"], "GATE PATH_ONLY", "H1/H3 R pointer")

    predeclaration = paths["julia_h1_h3_predeclaration"]
    s9_require_text(predeclaration, "Master seed default `20260903`", "Julia H1/H3 protocol")
    s9_require_text(predeclaration, "Future fir array stride: **40_009**", "Julia H1/H3 protocol")
    s9_require_text(predeclaration, "Screening: 48 reps/cell", "Julia H1/H3 protocol")
    s9_require_text(predeclaration, "Confirm: ~2000 interpretable reps/cell", "Julia H1/H3 protocol")
    s9_require_text(predeclaration, "Coverage denominator: `interval_success`, not `reps`", "Julia H1/H3 protocol")
    s9_require_text(predeclaration, "`claim_eligible` column is hard-false", "Julia H1/H3 protocol")
    s9_require_text(predeclaration, "`GATE PATH_ONLY`", "Julia H1/H3 protocol")
    s9_require_text(predeclaration, "0.90 if emitted is **descriptive-only**", "Julia H1/H3 protocol")
    s9_require_text(predeclaration, "`h1_t` cannot become a covered-pillar claim", "Julia H1/H3 protocol")
    s9_require_text(predeclaration, "NEW TSV only", "Julia H1/H3 protocol")
    s9_require_text(predeclaration, "does **not** mutate the C1", "Julia H1/H3 protocol")

    driver = paths["julia_phase1_interval_driver"]
    s9_require_text(driver, "const EXT_CONFIRM_REPS_TARGET = 2000", "Julia interval driver")
    s9_require_text(driver, "const EXT_SEED_STRIDE = 40_009", "Julia interval driver")
    s9_require_text(driver, "parse(Int, get(opts, \"seed\", \"20260903\"))", "Julia interval driver")
    s9_require_text(driver, "claim_eligible = false", "Julia interval driver")
    s9_require_text(driver, "initial = (G0 = Gtrue, R0 = Rtrue)", "Julia H3 initialization")
    for counter in ("reps", "fit_success", "fit_converged", "interval_success", "covered", "failure_reason")
        s9_require_text(driver, "\"$(counter)\"", "Julia interval driver counters")
    end

    test = paths["julia_phase1_interval_test"]
    s9_require_text(test, "@test EXT_CONFIRM_REPS_TARGET == 2000", "Julia interval test")
    s9_require_text(test, "@test EXT_SEED_STRIDE == 40_009", "Julia interval test")

    s9_validate_unarmed_sbatch(paths["julia_phase1_interval_sbatch"])

    r_pointer = paths["r_phase1_interval_pointer"]
    s9_require_text(r_pointer, "EXT_CONFIRM_REPS_TARGET <- 2000L", "R pointer driver")
    s9_require_text(r_pointer, "EXT_SEED_STRIDE <- 40009L", "R pointer driver")
    s9_require_text(r_pointer, "claim_eligible = FALSE", "R pointer driver")
    s9_require_text(r_pointer, "GATE PATH_ONLY", "R pointer driver")

    r_test = paths["r_phase1_interval_pointer_test"]
    s9_require_text(r_test, "expect_equal(EXT_CONFIRM_REPS_TARGET, 2000L)", "R pointer test")
    s9_require_text(r_test, "expect_equal(EXT_SEED_STRIDE, 40009L)", "R pointer test")
    return nothing
end

function s9_parse_cli(arguments::Vector{String})
    manifest_path = nothing
    assert_inert = false
    for argument in arguments
        if argument == "--assert-inert"
            assert_inert && s9_fail("--assert-inert was repeated")
            assert_inert = true
        elseif startswith(argument, "-")
            s9_fail("unknown option $(repr(argument))")
        elseif isnothing(manifest_path)
            manifest_path = argument
        else
            s9_fail("only one manifest path is accepted")
        end
    end
    isnothing(manifest_path) && s9_fail("usage: validate_hsq09_s9_manifest.jl MANIFEST [--assert-inert]")
    return manifest_path::String, assert_inert
end

function s9_validate(manifest_path::AbstractString)
    manifest = TOML.parsefile(manifest_path)
    entries = s9_validate_schema(manifest)
    julia_root = s9_julia_root(manifest_path)
    s9_validate_julia_descendant(julia_root)
    r_root = s9_validate_r_root(manifest)
    paths = s9_validate_hashes(entries, julia_root, r_root)
    s9_validate_source_contract(paths)
    s9_validate_julia_state(julia_root)
    return nothing
end

function s9_main(arguments::Vector{String} = ARGS)
    manifest_path, assert_inert = s9_parse_cli(arguments)
    s9_validate(manifest_path)
    println("S9_MANIFEST_PAIR_OK")
    assert_inert && println("S9_INERT_OK")
    return nothing
end

function s9_cli()
    try
        s9_main()
        return 0
    catch error
        println(stderr, "S9_MANIFEST_INVALID: ", sprint(showerror, error))
        return 1
    end
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    exit(s9_cli())
end
