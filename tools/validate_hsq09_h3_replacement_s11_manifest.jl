#!/usr/bin/env julia
using SHA, TOML

const H3_S11_MANIFEST = joinpath(@__DIR__, "..", "docs", "dev-log", "evidence", "2026-09-10-h3-replacement-s11-manifest.toml")
const H3_S11_EXPECTED = Dict(
    ("manifest", "id") => "HSQ09-H3-REPLACEMENT-S11-01", ("manifest", "schema_version") => 1,
    ("manifest", "status") => "ratified_pending_prerun", ("manifest", "engine_capability_inert") => true,
    ("manifest", "no_pooling") => true, ("candidate", "s10_closeout_commit") => "93cdc044148ef9f70fa7b03a536d1c44ade05b6b",
    ("candidate", "template_commit") => "9e226a08", ("candidate", "fixture_sha256") => "8c3ccaf70e005d9b0b7b5e96cf4b3cbaf7b489522b30a37c31dfaf12e1e0c82a",
    ("candidate", "s10_manifest_sha256") => "5f690a73904b099ef9721ba11d38bf8d9c687c02919c58597695ecc07bc1e9dd",
    ("candidate", "rg_s10_receipt_sha256") => "0c6bb55ee0a9c8188f01a0c1fe7f8ae3a2adb45ed4ad478aba24ee439be09ca9",
    ("candidate", "ram_s10_receipt_sha256") => "79e657ce01fefa24bb1564ebe2aeb9e2301e31a80ee66e6e6b53ab36c4725a26",
    ("classification", "coverage_denominator") => "interval_success", ("classification", "mcse") => "sqrt(coverage * (1 - coverage) / interval_success)",
    ("classification", "band") => "nominal_0.95_plus_or_minus_2_mcse", ("classification", "separate_per_estimand") => true,
    ("compute", "route") => "narval", ("compute", "account") => "def-snakagaw_cpu", ("compute", "partition") => "cpubase_bycore_b1",
    ("compute", "cpus_per_task") => 1, ("compute", "threads") => 1, ("compute", "array_cap") => 100,
    ("compute", "pre_run_array") => "1-1%1", ("compute", "campaign_array") => "1-2000%100",
    ("retention", "one_task_per_seed") => true, ("retention", "retain_successes_and_failures") => true,
    ("retention", "atomic_non_overwrite") => true, ("retention", "claim_eligible") => false,
    ("governed_inputs", "driver_sha256") => "1c9ea950a7113a968b03e369a35657ff9e4968786536c34a1cc73d5fa91c845d",
    ("governed_inputs", "sbatch_sha256") => "1dce3d43aa865f52c2df24f8527615b89fc245c759a5149da5718020b7ed66f6",
    ("governed_inputs", "lock_sha256") => "a3d4803f05af9738bc5796b1534bdb3249a263efb6c618cae6088d3f0c7ce221",
    ("authorizations", "s11") => true, ("authorizations", "compute") => true,
    ("authorizations", "promotion") => false, ("authorizations", "versioning") => false,
    ("authorizations", "tag") => false, ("authorizations", "registry") => false, ("authorizations", "release") => false)
const H3_S11_SCHEMA = Dict("manifest" => ["id","schema_version","status","engine_capability_inert","no_pooling"],
    "candidate" => ["s10_closeout_commit","template_commit","fixture_sha256","s10_manifest_sha256","rg_s10_receipt_sha256","ram_s10_receipt_sha256"],
    "estimands" => ["rg","ram"], "classification" => ["coverage_denominator","mcse","band","separate_per_estimand"],
    "compute" => ["route","account","partition","cpus_per_task","threads","array_cap","pre_run_array","campaign_array"],
    "retention" => ["one_task_per_seed","retain_successes_and_failures","atomic_non_overwrite","claim_eligible"],
    "governed_inputs" => ["driver_sha256","sbatch_sha256","lock_sha256"], "authorizations" => ["s11","compute","promotion","versioning","tag","registry","release"])
const H3_S11_EST_SCHEMA = ["estimand","seed_start","seed_stop","replicates","interval_success_floor"]

function h3_replacement_s11_manifest_validate(path=H3_S11_MANIFEST)
    data=TOML.parsefile(path); Set(keys(data)) == Set(keys(H3_S11_SCHEMA)) || error("H3 S11 manifest sections are not closed")
    for (section, keys_) in H3_S11_SCHEMA
        Set(keys(data[section])) == Set(keys_) || error("H3 S11 manifest keys are not closed in $(section)")
    end
    for ((section,key), value) in H3_S11_EXPECTED
        data[section][key] == value || error("H3 S11 manifest mismatch at $(section).$(key)")
    end
    for (cell, start, stop, estimand) in (("rg",202609110001,202609112000,"r_g"), ("ram",202609120001,202609122000,"r_am"))
        value=data["estimands"][cell]; Set(keys(value)) == Set(H3_S11_EST_SCHEMA) || error("H3 S11 estimand schema is not closed")
        value["estimand"] == estimand && value["seed_start"] == start && value["seed_stop"] == stop && value["replicates"] == 2000 && value["interval_success_floor"] == 1800 || error("H3 S11 estimand differs")
        stop - start + 1 == 2000 || error("H3 S11 seed range is not contiguous")
    end
    isempty(intersect(202609110001:202609112000, 202609120001:202609122000)) || error("H3 S11 ranges overlap")
    root=normpath(joinpath(@__DIR__, "..")); for (file,key) in (("sim/hsq09_h3_replacement_s11.jl","driver_sha256"),("sim/drac/hsq09_h3_replacement_s11.sbatch","sbatch_sha256"))
        bytes2hex(sha256(read(joinpath(root,file)))) == data["governed_inputs"][key] || error("H3 S11 governed input hash mismatch")
    end
    bytes2hex(sha256(read(joinpath(root,"Manifest.toml")))) == data["governed_inputs"]["lock_sha256"] || error("H3 S11 lock hash mismatch")
    nothing
end

function h3_replacement_s11_manifest_mutation_controls(path=H3_S11_MANIFEST)
    source=read(path,String)
    for (_, altered) in [("authorization",replace(source,"release = false"=>"release = true";count=1)), ("range",replace(source,"seed_start = 202609110001"=>"seed_start = 202609110002";count=1)), ("floor",replace(source,"interval_success_floor = 1800"=>"interval_success_floor = 1799";count=1)), ("cap",replace(source,"array_cap = 100"=>"array_cap = 101";count=1)), ("extra",source*"\n[forbidden]\nx = 1\n")]
        mktempdir() do dir
            p=joinpath(dir,"manifest.toml"); write(p,altered); rejected=false
            try h3_replacement_s11_manifest_validate(p) catch; rejected=true end
            rejected || error("H3 S11 mutation passed")
        end
    end
    nothing
end

if abspath(PROGRAM_FILE)==@__FILE__
    ARGS == ["--self-test"] || error("only --self-test is accepted")
    h3_replacement_s11_manifest_validate(); println("H3_REPLACEMENT_S11_MANIFEST_OK")
    h3_replacement_s11_manifest_mutation_controls(); println("H3_REPLACEMENT_S11_MANIFEST_MUTATIONS_OK")
end
