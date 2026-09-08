using SHA
using Test

const S9_JULIA_SHA = "1dbf8b97a3b28f814e3418239ac1658acbbc19bb"
const S9_R_SHA = "e6a1ce4e8a691795487420668b349fb9e2670059"
const S9_ROOT = normpath(joinpath(@__DIR__, ".."))
const S9_MANIFEST_REL = joinpath("docs", "dev-log", "evidence", "2026-09-07-hsq09-s9-evidence-manifest.toml")
const S9_VALIDATOR_REL = joinpath("tools", "validate_hsq09_s9_manifest.jl")
const S9_TEST_REL = joinpath("test", "test_hsq09_s9_manifest.jl")
const S9_ARTIFACTS = (S9_MANIFEST_REL, S9_VALIDATOR_REL, S9_TEST_REL)

function s9_clone_at(source::AbstractString, destination::AbstractString, sha::AbstractString)
    run(`git clone --quiet --no-hardlinks $source $destination`)
    run(`git -C $destination checkout --quiet $sha`)
    return destination
end

function s9_install_artifacts!(destination::AbstractString)
    for relative in S9_ARTIFACTS
        target = joinpath(destination, relative)
        mkpath(dirname(target))
        cp(joinpath(S9_ROOT, relative), target; force = true)
    end
    return destination
end

function s9_julia_copy(parent::AbstractString, label::AbstractString)
    destination = joinpath(parent, label)
    s9_clone_at(S9_ROOT, destination, S9_JULIA_SHA)
    return s9_install_artifacts!(destination)
end

function s9_commit_s9_artifacts!(root::AbstractString)
    run(`git -C $root add -- $S9_MANIFEST_REL $S9_VALIDATOR_REL $S9_TEST_REL`)
    run(`git -C $root -c user.name=hsq09-s9-test -c user.email=hsq09-s9@example.invalid commit --quiet -m s9-descendant`)
    return root
end

function s9_make_wrong_base!(root::AbstractString)
    tree = readchomp(`git -C $root write-tree`)
    commit = readchomp(`git -C $root -c user.name=hsq09-s9-test -c user.email=hsq09-s9@example.invalid commit-tree $tree`)
    run(`git -C $root checkout --quiet --detach $commit`)
    return root
end

function s9_replace_once!(path::AbstractString, before::AbstractString, after::AbstractString)
    original = read(path, String)
    revised = replace(original, before => after; count = 1)
    revised == original && error("test fixture did not contain expected text: $(repr(before))")
    write(path, revised)
    return nothing
end

function s9_sha256(path::AbstractString)
    return bytes2hex(sha256(read(path)))
end

function s9_invoke(julia_root::AbstractString; r_root::Union{Nothing, AbstractString})
    validator = joinpath(julia_root, S9_VALIDATOR_REL)
    manifest = joinpath(julia_root, S9_MANIFEST_REL)
    environment = Dict{String, String}(ENV)
    if isnothing(r_root)
        pop!(environment, "HSQ09_S9_R_ROOT", nothing)
    else
        environment["HSQ09_S9_R_ROOT"] = r_root
    end
    output = IOBuffer()
    command = `$(Base.julia_cmd()) --startup-file=no $validator $manifest --assert-inert`
    process = run(pipeline(setenv(command, environment), stdout = output, stderr = output); wait = false)
    wait(process)
    return process.exitcode, String(take!(output))
end

function s9_expect_rejected(label::AbstractString, julia_root::AbstractString; r_root::Union{Nothing, AbstractString})
    code, output = s9_invoke(julia_root; r_root = r_root)
    @test code != 0
    @test !occursin("S9_MANIFEST_PAIR_OK", output)
    return output
end

@testset "HSQ09 S9 source-inert evidence manifest" begin
    manifest = joinpath(S9_ROOT, S9_MANIFEST_REL)
    validator = joinpath(S9_ROOT, S9_VALIDATOR_REL)

    # RED before the manifest/validator exist; the remaining assertions describe
    # their intended behavior once the implementation is present.
    @test isfile(manifest)
    @test isfile(validator)

    if isfile(manifest) && isfile(validator)
        @test occursin("base_commit = \"$(S9_JULIA_SHA)\"", read(manifest, String))
        @test !occursin("\nratified =", read(manifest, String))
        r_root = get(ENV, "HSQ09_S9_R_ROOT", "")
        @test !isempty(r_root)
        @test isdir(r_root)
        @test readchomp(`git -C $r_root rev-parse HEAD`) == S9_R_SHA

        mktempdir() do temporary
            baseline = s9_julia_copy(temporary, "baseline")
            code, output = s9_invoke(baseline; r_root = r_root)
            @test code == 0
            @test occursin("S9_MANIFEST_PAIR_OK", output)
            @test occursin("S9_INERT_OK", output)

            descendant = s9_julia_copy(temporary, "committed-descendant")
            s9_commit_s9_artifacts!(descendant)
            descendant_code, descendant_output = s9_invoke(descendant; r_root = r_root)
            @test descendant_code == 0
            @test occursin("S9_MANIFEST_PAIR_OK", descendant_output)

            wrong_base = s9_julia_copy(temporary, "wrong-base")
            s9_make_wrong_base!(wrong_base)
            s9_expect_rejected("Julia checkout with wrong base", wrong_base; r_root = r_root)

            seed = s9_julia_copy(temporary, "seed")
            s9_replace_once!(joinpath(seed, S9_MANIFEST_REL), "master_seed = 20260903", "master_seed = 1")
            s9_expect_rejected("seed", seed; r_root = r_root)

            denominator = s9_julia_copy(temporary, "denominator")
            s9_replace_once!(joinpath(denominator, S9_MANIFEST_REL), "coverage_denominator = \"interval_success\"", "coverage_denominator = \"reps\"")
            s9_expect_rejected("denominator", denominator; r_root = r_root)

            eligibility = s9_julia_copy(temporary, "eligibility")
            s9_replace_once!(joinpath(eligibility, S9_MANIFEST_REL), "claim_eligible = false", "claim_eligible = true")
            s9_expect_rejected("eligibility", eligibility; r_root = r_root)

            h0_authorization = s9_julia_copy(temporary, "h0-authorization")
            s9_replace_once!(joinpath(h0_authorization, S9_MANIFEST_REL), "s9_ratification_authorized = false", "s9_ratification_authorized = true")
            s9_expect_rejected("S9 H0 ratification authorization", h0_authorization; r_root = r_root)

            julia_sha = s9_julia_copy(temporary, "julia-sha")
            s9_replace_once!(joinpath(julia_sha, S9_MANIFEST_REL), S9_JULIA_SHA, "0000000000000000000000000000000000000000")
            s9_expect_rejected("julia SHA", julia_sha; r_root = r_root)

            r_sha = s9_julia_copy(temporary, "r-sha")
            s9_replace_once!(joinpath(r_sha, S9_MANIFEST_REL), S9_R_SHA, "0000000000000000000000000000000000000000")
            s9_expect_rejected("R SHA", r_sha; r_root = r_root)

            hash_control = s9_julia_copy(temporary, "hash")
            s9_replace_once!(joinpath(hash_control, S9_MANIFEST_REL), "60225d56dffffec004f2985d67134938ea8b7469ce9508d901135ec858c5afe5", "0000000000000000000000000000000000000000000000000000000000000000")
            s9_expect_rejected("governed-input hash", hash_control; r_root = r_root)

            unarmed = s9_julia_copy(temporary, "unarmed")
            sbatch = joinpath(unarmed, "sim", "drac", "phase1_interval_coverage_ext.sbatch")
            old_sbatch_hash = s9_sha256(sbatch)
            s9_replace_once!(sbatch, "exit 78", "exit 0")
            new_sbatch_hash = s9_sha256(sbatch)
            s9_replace_once!(joinpath(unarmed, S9_MANIFEST_REL), old_sbatch_hash, new_sbatch_hash)
            unarmed_output = s9_expect_rejected("unarmed sbatch template", unarmed; r_root = r_root)
            @test occursin("exit 78", unarmed_output)

            unknown_result = s9_julia_copy(temporary, "unknown-result")
            s9_replace_once!(joinpath(unknown_result, S9_MANIFEST_REL), "result_values_present = false", "result_values_present = false\nunexpected_result = 0.95")
            s9_expect_rejected("unknown result field", unknown_result; r_root = r_root)

            absent_r = s9_julia_copy(temporary, "absent-r")
            s9_expect_rejected("absent R root", absent_r; r_root = nothing)

            wrong_r = s9_julia_copy(temporary, "wrong-r")
            s9_expect_rejected("wrong R root", wrong_r; r_root = wrong_r)

            dirty_r = s9_julia_copy(temporary, "dirty-r-julia")
            dirty_r_root = joinpath(temporary, "dirty-r-root")
            s9_clone_at(r_root, dirty_r_root, S9_R_SHA)
            write(joinpath(dirty_r_root, ".hsq09-s9-dirty-control"), "dirty\n")
            s9_expect_rejected("dirty R root", dirty_r; r_root = dirty_r_root)

            println("S9_NEGATIVE_CONTROLS_OK")
        end
    end
end
