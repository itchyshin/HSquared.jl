using TOML

const H1T_S11_MANIFEST_PATH = normpath(joinpath(@__DIR__, "..", "docs", "dev-log", "evidence",
                                                 "2026-09-09-h1two-identified-s11-manifest.toml"))
const H1T_S11_EXPECTED = Dict(
    ("manifest", "id") => "HSQ09-H1T-IDENTIFIED-S11-01",
    ("candidate", "julia_commit") => "36ae0691c9e4d30dda8947e162716ebaf30de762",
    ("candidate", "r_commit") => "fd2825795d3d481311912d29f3c377f2897d321d",
    ("candidate", "project_toml_sha256") => "5681beadea6d197720629a2d3e01a00bf9c4cf7098f77e4e27595c4700af67cc",
    ("candidate", "runtime_manifest_sha256") => "a3d4803f05af9738bc5796b1534bdb3249a263efb6c618cae6088d3f0c7ce221",
    ("candidate", "driver_sha256") => "111aadbfb81f235bfda8ca976ec1cef84e2e61aa9bb3348a6be9df31fffc63c0",
    ("candidate", "sbatch_sha256") => "1284f1058734d034453deff44d8fc34495cf65d2de61eed31464ea492cdaa7da",
    ("fixture", "seed_start") => 202609100001,
    ("fixture", "seed_stop") => 202609102000,
    ("fixture", "reps") => 2000,
    ("fixture", "sires") => 20,
    ("fixture", "offspring") => 200,
    ("fixture", "groups") => 40,
    ("fixture", "truth_sigma1") => 1.0,
    ("fixture", "truth_sigma2") => 0.5,
    ("fixture", "truth_sigma_e2") => 1.0,
    ("fixture", "intercept") => 3.0,
    ("fixture", "level") => 0.95,
    ("fixture", "group_assignment") => "independent_of_pedigree",
    ("retention", "rows_per_seed") => 2,
    ("retention", "claim_eligible") => false,
    ("routing", "cluster") => "narval",
    ("routing", "account") => "def-snakagaw_cpu",
    ("routing", "partition") => "cpubase_bycore_b1",
    ("routing", "project_dir") => "/project/6098264/snakagaw/hsq09-h1t-identified-s11-36ae0691",
    ("routing", "array_tasks") => 2000,
    ("routing", "array_max_concurrent") => 100,
    ("routing", "task_unit") => "one_seed",
    ("routing", "cpus_per_task") => 1,
    ("routing", "julia_threads") => 1,
    ("routing", "openblas_threads") => 1,
    ("routing", "time_limit") => "00:05:00",
    ("routing", "memory") => "2G",
    ("authorization", "s11_campaign") => true,
    ("authorization", "promotion") => false,
    ("authorization", "versioning") => false,
    ("authorization", "tag") => false,
    ("authorization", "registry") => false,
    ("authorization", "release") => false,
    ("interpretation", "status") => "evidence_only",
    ("interpretation", "no_public_capability_change") => true,
)

function _h1t_s11_validate(path::AbstractString)
    parsed = TOML.parsefile(path)
    for ((section, key), expected) in H1T_S11_EXPECTED
        get(get(parsed, section, Dict{String, Any}()), key, nothing) == expected ||
            error("S11 manifest mismatch at $(section).$(key)")
    end
    get(parsed["fixture"], "seed_stop", 0) ==
        get(parsed["fixture"], "seed_start", 0) + get(parsed["fixture"], "reps", 0) - 1 ||
        error("S11 seed range is not contiguous")
    get(parsed["retention"], "estimands", String[]) == ["ratio1", "ratio2"] ||
        error("S11 estimands must be exactly ratio1 and ratio2")
    occursin("never_average", get(parsed["retention"], "pooling", "")) ||
        error("S11 pooling rule must prohibit task-rate averaging")
    return parsed
end

"""Parse and validate the authoritative S11 manifest."""
h1t_s11_manifest() = _h1t_s11_validate(H1T_S11_MANIFEST_PATH)

function h1t_s11_manifest_self_test()
    h1t_s11_manifest()
    source = read(H1T_S11_MANIFEST_PATH, String)
    mutations = (
        ("reps = 2000", "reps = 1999"),
        ("cpus_per_task = 1", "cpus_per_task = 2"),
        ("s11_campaign = true", "s11_campaign = false"),
        ("promotion = false", "promotion = true"),
        ("groups = 40", "groups = 39"),
        ("claim_eligible = false", "claim_eligible = true"),
    )
    mktempdir() do dir
        for (from, to) in mutations
            path = joinpath(dir, "mutation.toml")
            write(path, replace(source, from => to; count = 1))
            try
                _h1t_s11_validate(path)
                error("mutation $(from) was accepted")
            catch err
                occursin("was accepted", sprint(showerror, err)) && rethrow()
            end
        end
    end
    return true
end

if abspath(PROGRAM_FILE) == @__FILE__
    h1t_s11_manifest_self_test()
    println("H1T_S11_MANIFEST_OK")
    println("H1T_S11_MANIFEST_MUTATIONS_OK")
end
