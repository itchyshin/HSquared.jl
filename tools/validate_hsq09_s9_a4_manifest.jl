#!/usr/bin/env julia

using SHA
using TOML

const A4_JULIA = "4d4a55c14c9234270979a76c53888d65634a6eaf"
const A4_R = "fd2825795d3d481311912d29f3c377f2897d321d"
const OLD_S9 = "dd1bfa77"
const OLD_S9_PATH = "docs/dev-log/evidence/2026-09-07-hsq09-s9-evidence-manifest.toml"
const OLD_S9_SHA = "066a74087dffa0a56e008495345bf0c446455d3cd0c8af04740c3a7b8e2fedd2"
const MANIFEST = joinpath(@__DIR__, "..", "docs", "dev-log", "evidence", "2026-09-09-hsq09-s9-a4-evidence-manifest.toml")

const ALLOWED = Set([
    "docs/dev-log/evidence/2026-09-09-hsq09-s9-a4-evidence-manifest.toml",
    "docs/dev-log/evidence/2026-09-09-hsq09-s9-a4-supersession.md",
    "tools/validate_hsq09_s9_a4_manifest.jl",
    "test/test_hsq09_s9_a4_manifest.jl",
    "docs/dev-log/check-log.d/2026-09-09-s9-a4-evidence-manifest.md",
    "docs/dev-log/after-task/2026-09-09-s9-a4-evidence-manifest.md",
])

const INPUTS = Dict(
    "r_h0_univariate_coverage_flip" => ("r", "docs/design/39-h0-univariate-coverage-flip.md", "H0 protocol"),
    "r_h1_interval_recovery_preregistration" => ("r", "docs/design/34-interval-recovery-pre-registration.md", "H1 protocol"),
    "r_h1_h3_path_pointer" => ("r", "docs/dev-log/recovery-checkpoints/2026-09-03-c1-ext-h1-h3-r-pointer.md", "H1/H3 pointer protocol"),
    "julia_h1_h3_predeclaration" => ("julia", "docs/dev-log/recovery-checkpoints/2026-09-03-c1-ext-h1-h3-ademp-predeclaration.md", "H1/H3 protocol"),
    "julia_phase1_interval_driver" => ("julia", "sim/phase1_interval_coverage_ext.jl", "phase1 interval Julia driver"),
    "julia_phase1_interval_test" => ("julia", "test/test_phase1_interval_coverage_ext.jl", "phase1 interval Julia test"),
    "julia_phase1_interval_sbatch" => ("julia", "sim/drac/phase1_interval_coverage_ext.sbatch", "unarmed phase1 interval sbatch template"),
    "julia_real_data_validation_manifest" => ("julia", "docs/design/real-data-validation-manifest.toml", "Julia real-data validation manifest"),
    "r_phase1_interval_pointer" => ("r", "sim/phase1_interval_coverage_ext.R", "R path-only pointer driver"),
    "r_phase1_interval_pointer_test" => ("r", "tests/testthat/test-c1-ext-h1-h3-harness.R", "R pointer test"),
    "r_real_data_validation_manifest" => ("r", "docs/design/real-data-validation-manifest.toml", "R real-data validation manifest"),
)

fail(message) = error("S9-A4 manifest: " * message)
hashfile(path) = bytes2hex(sha256(read(path)))
git(root, args...) = readchomp(Cmd(["git", "-C", root, args...]))

function exact_keys(table, expected, label)
    table isa AbstractDict || fail("$(label) must be a table")
    Set(String(k) for k in keys(table)) == Set(expected) || fail("$(label) has wrong keys")
end

function exact(value, expected, label)
    value == expected || fail("$(label) must equal $(repr(expected))")
end

function validate_historical(julia_root, table)
    exact_keys(table, ["commit", "manifest_path", "sha256", "status"], "legacy_s9")
    exact(table["commit"], OLD_S9, "legacy_s9.commit")
    exact(table["manifest_path"], OLD_S9_PATH, "legacy_s9.manifest_path")
    exact(table["sha256"], OLD_S9_SHA, "legacy_s9.sha256")
    exact(table["status"], "superseded_for_candidate_pins_only", "legacy_s9.status")
    old_bytes = read(Cmd(["git", "-C", julia_root, "show", "$(OLD_S9):$(OLD_S9_PATH)"]))
    bytes2hex(sha256(old_bytes)) == OLD_S9_SHA || fail("historical S9 manifest bytes differ")
    old = TOML.parse(String(old_bytes))
    all(x === false for x in values(old["authorizations"])) || fail("historical S9 authorizations were changed")
    all(x === false for x in values(old["results"])) || fail("historical S9 results were changed")
end

function validate_inputs(rows, julia_root, r_root)
    rows isa Vector && length(rows) == length(INPUTS) || fail("governed input count differs")
    seen = Set{String}()
    for row in rows
        exact_keys(row, ["id", "repository", "path", "role", "sha256"], "governed input")
        id = row["id"]
        id isa String && !(id in seen) || fail("governed IDs must be unique strings")
        push!(seen, id)
        expected = get(INPUTS, id, nothing)
        expected === nothing && fail("unknown governed input $(id)")
        exact((row["repository"], row["path"], row["role"]), expected, "governed input $(id)")
        root = row["repository"] == "julia" ? julia_root : r_root
        path = joinpath(root, row["path"])
        isfile(path) || fail("governed input missing: $(row["path"])")
        row["sha256"] == hashfile(path) || fail("governed input hash differs: $(id)")
    end
    seen == Set(keys(INPUTS)) || fail("governed input identity set differs")
end

function validate_worktrees(julia_root, r_root)
    success(Cmd(["git", "-C", julia_root, "merge-base", "--is-ancestor", A4_JULIA, "HEAD"])) ||
        fail("Julia HEAD must descend from the A4 pin")
    for row in filter(!isempty, split(git(julia_root, "status", "--porcelain", "--untracked-files=all"), '\n'))
        length(row) >= 4 || fail("unparseable Julia status")
        strip(row[4:end]) in ALLOWED || fail("source-inert state forbids dirty Julia path $(strip(row[4:end]))")
    end
    git(r_root, "rev-parse", "HEAD") == A4_R || fail("R HEAD must equal its A4 pin")
    isempty(git(r_root, "status", "--porcelain")) || fail("R candidate must be clean")
end

function s9_a4_validate(manifest_path::AbstractString = MANIFEST;
                         r_root = get(ENV, "HSQ09_S9_A4_R_ROOT", nothing),
                         assert_inert::Bool = false,
                         julia_root::AbstractString = normpath(joinpath(@__DIR__, "..")))
    r_root isa AbstractString && isdir(r_root) || fail("HSQ09_S9_A4_R_ROOT must name the clean exact R candidate")
    data = TOML.parsefile(manifest_path)
    exact_keys(data, ["manifest", "repositories", "legacy_s9", "contract", "authorizations", "results", "sbatch_template", "inputs"], "manifest")
    exact_keys(data["manifest"], ["id", "schema_version", "source_inert"], "manifest metadata")
    exact(data["manifest"]["id"], "HSQ09-S9-A4", "manifest.id")
    exact(data["manifest"]["schema_version"], 1, "manifest.schema_version")
    exact(data["manifest"]["source_inert"], true, "manifest.source_inert")
    exact_keys(data["repositories"], ["julia", "r"], "repositories")
    exact_keys(data["repositories"]["julia"], ["base_commit", "allowed_dirty_paths"], "repositories.julia")
    exact(data["repositories"]["julia"]["base_commit"], A4_JULIA, "repositories.julia.base_commit")
    Set(data["repositories"]["julia"]["allowed_dirty_paths"]) == ALLOWED || fail("allowed dirty paths differ")
    exact_keys(data["repositories"]["r"], ["commit", "root_env"], "repositories.r")
    exact(data["repositories"]["r"]["commit"], A4_R, "repositories.r.commit")
    exact(data["repositories"]["r"]["root_env"], "HSQ09_S9_A4_R_ROOT", "repositories.r.root_env")
    exact(data["contract"]["claim_eligible"], false, "contract.claim_eligible")
    exact(data["contract"]["gate"], "PATH_ONLY", "contract.gate")
    exact(data["contract"]["coverage_denominator"], "interval_success", "contract.coverage_denominator")
    all(v === false for v in values(data["authorizations"])) || fail("all authorizations must be false")
    all(v === false for v in values(data["results"])) || fail("all results fields must be false")
    exact(data["sbatch_template"]["armed"], false, "sbatch_template.armed")
    exact(data["sbatch_template"]["effective_exit_code"], 78, "sbatch_template.effective_exit_code")
    exact(data["sbatch_template"]["execution"], "refusal_only", "sbatch_template.execution")
    validate_historical(julia_root, data["legacy_s9"])
    validate_inputs(data["inputs"], julia_root, r_root)
    assert_inert && validate_worktrees(julia_root, r_root)
    nothing
end

function s9_a4_mutation_controls(manifest_path::AbstractString; r_root::AbstractString)
    source = read(manifest_path, String)
    mutations = [
        ("compute", replace(source, "compute = false" => "compute = true"; count = 1)),
        ("julia pin", replace(source, A4_JULIA => repeat("0", 40); count = 1)),
        ("legacy digest", replace(source, OLD_S9_SHA => repeat("0", 64); count = 1)),
        ("input hash", replace(source, "d6a8d307881b58e44b024562232b6dd638e4feaae4785aa99ea6897a79973002" => repeat("f", 64); count = 1)),
        ("unknown field", source * "\n[forbidden]\nvalue = true\n"),
    ]
    for (label, altered) in mutations
        mktempdir() do temp
            path = joinpath(temp, "manifest.toml")
            write(path, altered)
            rejected = false
            try
                s9_a4_validate(path; r_root = r_root)
            catch error
                rejected = error isa ErrorException
            end
            rejected || fail("mutation unexpectedly passed: $(label)")
        end
    end
    nothing
end

function s9_a4_main(args = ARGS)
    all(arg == "--assert-inert" for arg in args) || fail("only --assert-inert is accepted")
    s9_a4_validate(; assert_inert = "--assert-inert" in args)
    println("HSQ09_S9_A4_MANIFEST_OK")
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    s9_a4_main()
end
