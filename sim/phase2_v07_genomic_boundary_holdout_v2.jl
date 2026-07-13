#!/usr/bin/env julia

using HSquared
using LinearAlgebra
using Printf
using SHA
using SparseArrays
using Statistics

# Reuse only the frozen doc-45 data generator, hashes, TSV primitives, and exact
# historical seed contracts. Its guarded main() does not run when this file
# includes it. Fresh holdout seeds are defined separately below so the spent
# v1 block remains immutable.
include(joinpath(@__DIR__, "phase2_v07_genomic_optimizer_localization.jl"))

const BOUNDARY_SCHEMA = "v07-genomic-boundary-holdout-v2"
const BOUNDARY_CANDIDATE = "doc47_boundary_performance_v1"
const DOC46_PATH = "docs/design/46-v07-genomic-boundary-resolution.md"
const DOC46_COMMIT = "fe96a147be23d74c5331eb37cd8b681ecce77be6"
const DOC46_SHA256 = "283ab00bab3da925f0ac2916959efacaa7fb711c5da4dce09dd49ea568eef030"
const DOC47_PATH = "docs/design/47-v07-genomic-boundary-performance.md"
const DOC47_COMMIT = "13eb97c3dfd49b461db04b7b9cc10587c99a5a73"
const DOC47_SHA256 = "400fbae28806443a6962545caf95587178f35ad0e91dd2b562cf88ea61a9b264"

const JULIA_BOUNDARY_IMPL_COMMIT = "fc9d39df650b20aa09d769d9f9528eed1b606f1e"
const REFERENCE_COMMIT = "ecc058f380be71058c9cfde373c345ab7a2f6aba"
const R_BOUNDARY_IMPL_COMMIT = "05ba8aed1c19a7971eeaaf3199fd1afe7d899561"
const R_ORACLE_SHA256 = "9034a3f6983e7db90f7ab26464b626b744b9f7d5e2ae2db54bbc2260241342d7"
const DISCOVERY_MANIFEST_SHA256 = "c1f5e1a284ed815a4457ac214372fb37382ade07fef3eb4abce331343bdd820a"
const DISCOVERY_ADMISSION_SHA256 = "d91a1c7997d43f6d70b4ac0eadda04293c361fc3e9c8599b855663ed413c13ab"
const DISCOVERY_ENVIRONMENT_SHA256 = "5c21efbc0e55d0879b7d1e7a15700f0aeb1b1a9839ed5b416f3ec2e676e30e18"
const DISCOVERY_ADMISSION_LOCK_SHA256 = "d7783c84e0ea8d3824c7c9a98dc8e51daef4bf4caa7e4427d83c5f67d246501b"
const DISCOVERY_EQUIVALENCE_SHA256 = "1e5217d9f12d57ada0e6c9b0b8b66585bf960a6991e897df3361b10eb65caf25"
const DISCOVERY_TIMING_SHA256 = "e1581626c588b6d65240f5a35fbac0ebf4ed442210de15ad2157d29345480101"
const DISCOVERY_SELECTION_SHA256 = "62bd5f2016a00289b66a6d30cbc0ed6b4917d6b561b735c48daedca7a5e548c6"
const DISCOVERY_SUMMARY_LOCK_SHA256 = "d73b73245985617a48cbbdb31ffa8afa65edb01d6cb26a0d862cdcc506a7180a"
const DISCOVERY_RAW_LOCKS_SHA256 = "daa0353237ef00e62c286cb15534a847413f3fe597fdb511aed9f062e035e81a"
const DISCOVERY_DIGEST = "33c31a474fc2f0e996d3bd6489a53d055cc753727b69f0625fc30811777c7caf"
const DISCOVERY_DRIVER_SHA256 = "046eeee7e22032dafd90e0601ac9c688f30f901468e3f7fff269a7bafebc1397"
const LOCALIZATION_DRIVER_SHA256 = "e03e4f71bf37beec23743b664747ff91ec7116eae825ba46a973dcfac8acfa06"
const DISCOVERY_CANDIDATE_COMMIT = JULIA_BOUNDARY_IMPL_COMMIT

const BOUNDARY_EPSILON = 1e-7
const GRID_STEP = 0.0025
const REFINEMENT_ABS_TOL = 1e-12
const LIKELIHOOD_TIE_PER_OBS = 1e-10
const DERIVATIVE_DELTA = 1e-6
const KKT_TOL_PER_OBS = 1e-8
const HOLDOUT_SEED_FORMULA = "2027120000+10000*cell_index+6001:6048"
const QK_IDENTITY_TOL = 1e-10
const PROVENANCE_DOMAIN_HEX = "48537175617265642d70726f76656e616e63652d763100"
const PROVENANCE_ENCODING = "sha256-little-endian-u64-float64-length-framed-utf8-v1"
const RESULT_DIGEST_ENCODING = "sha256-utf8-field-equals-value-newline-float17g-v1"

const HOLDOUT_COLUMNS = split("cell_id seed n m ridge")
const FIT_COLUMNS = split("cell_id seed route timed_order converged termination_reason optimizer_status iterations sigma_g2 sigma_e2 numerical_ratio profile_ratio profile_t_hat boundary_status boundary_epsilon profile_loglik lower_derivative_per_observation upper_derivative_per_observation objective ai_score_norm fd_log_gradient_norm runtime_seconds marker_hash id_hash kernel_hash precision_hash relationship_source relationship_method allele_frequency_source ridge relationship_scale result_digest error_class")
const RESULT_FIELDS = split("digest_version status reason converged termination profile_ratio numerical_ratio t_hat profile_loglik d0 d1 sigma_g2 sigma_e2 marker_hash id_hash kernel_hash precision_hash relationship_source relationship_method allele_frequency_source ridge relationship_scale")
const BOUNDARY_METADATA_KEYS = split("schema_version candidate_id cell_id seed n p m ridge marker_hash id_hash kernel_hash precision_hash relationship_source relationship_method allele_frequency_source relationship_scale doc46_commit doc46_sha256 doc47_commit doc47_sha256 julia_boundary_impl_commit r_boundary_impl_commit discovery_digest discovery_equivalence_sha256 discovery_timing_sha256 discovery_selection_sha256 candidate_seal_sha256 holdout_manifest_sha256 execution_commit driver_sha256 r_oracle_sha256")
const PACKET_FILES = ["K.tsv", "Q.tsv", "X.tsv", "fits.tsv", "ids.tsv", "metadata.tsv", "y.tsv"]
const SEAL_KEYS = split("schema_version candidate_id doc46_commit doc46_sha256 doc47_commit doc47_sha256 reference_commit julia_boundary_impl_commit r_boundary_impl_commit r_execution_commit localization_driver_sha256 performance_driver_sha256 boundary_driver_sha256 launcher_sha256 genomic_source_sha256 r_oracle_sha256 exchange_schema exchange_schema_sha256 profiler_schema profiler_candidate_id packet_file_set provenance_domain_hex provenance_encoding result_digest_encoding id_hash_kind kernel_hash_kind precision_hash_kind qk_identity_tolerance relationship_source relationship_method allele_frequency_source ridge relationship_scale boundary_epsilon grid_step refinement_abs_tol likelihood_tie_per_observation derivative_delta kkt_tolerance_per_observation holdout_seed_formula timing_protocol holdout_p95_rule holdout_runtime_ratio_limit discovery_runtime_ratio_limit discovery_reference_ratio_limit holdout_manifest_sha256 discovery_manifest_sha256 discovery_admission_sha256 discovery_environment_sha256 discovery_admission_lock_sha256 discovery_raw_locks_sha256 discovery_equivalence_sha256 discovery_timing_sha256 discovery_selection_sha256 discovery_summary_lock_sha256 discovery_digest discovery_candidate_commit candidate_implementation_commit julia_driver_commit execution_commit host cpu_model machine kernel arch julia_version r_version project_sha256 manifest_sha256 julia_num_threads openblas_num_threads omp_num_threads veclib_maximum_threads holdout_absent_before_seal spent_offset_block_excluded")
const ORACLE_COLUMNS = split("cell_id seed packet_files_lock_sha256 candidate_seal_sha256 candidate_id doc46_commit doc46_sha256 doc47_commit doc47_sha256 julia_boundary_impl_commit r_boundary_impl_commit r_oracle_sha256 marker_hash id_hash kernel_hash precision_hash default_result_digest candidate_result_digest oracle_class oracle_profile_ratio oracle_t_hat oracle_profile_loglik oracle_lower_derivative_per_observation oracle_upper_derivative_per_observation oracle_sigma_g2_numerical oracle_sigma_e2_numerical")
const ORACLE_BINDING_COLUMNS = ORACLE_COLUMNS[3:18]
const RESOLVED_STATUSES = Set(["boundary_lower", "boundary_upper", "interior", "interior_rescued"])
const ALL_STATUSES = union(RESOLVED_STATUSES, Set(["boundary_unresolved"]))

_bopt(args, key, default=nothing) = _opt(args, key, default)
_breq(args, key) = _required(args, key)
_hex40(x) = occursin(r"^[0-9a-f]{40}$", x)
_hex64(x) = occursin(r"^[0-9a-f]{64}$", x)
_bool_token(x) = lowercase(String(x)) in ("true", "1")
_float(x) = parse(Float64, String(x))
_fresh_holdout_seeds(cell) = (_seed_base(cell)+6001):(_seed_base(cell)+6048)
_timed_order(seed)=isodd(seed) ? "default_ai>boundary_candidate" : "boundary_candidate>default_ai"

function _holdout_manifest_rows()
    rows = Vector{Vector{Any}}()
    for cell in CELLS, seed in _fresh_holdout_seeds(cell)
        push!(rows, Any[cell.id, seed, cell.n, cell.m, RIDGE])
    end
    length(rows) == 240 || error("holdout denominator drift")
    rows
end

function _table_bytes(columns, rows)
    io = IOBuffer()
    println(io, join(columns, '\t'))
    for row in rows
        println(io, join(_format.(row), '\t'))
    end
    take!(io)
end

function _write_bytes_create_once(path, bytes)
    mkpath(dirname(path))
    tmp,io=mktemp(dirname(path))
    try
        write(io,bytes); close(io)
        # A hard-link create is atomic and fails if the destination exists.
        # `mv(...; force=false)` is check-then-rename and can overwrite a
        # destination created between those two operations.
        Base.Filesystem.hardlink(tmp,path)
        rm(tmp;force=true)
    catch
        isopen(io) && close(io)
        ispath(tmp) && rm(tmp;force=true)
        rethrow()
    end
    nothing
end

_write_table_create_once(path,columns,rows)=_write_bytes_create_once(path,_table_bytes(columns,rows))

function _claim_directory_create_once(path)
    claim=path*".claim"
    _write_bytes_create_once(claim,codeunits("v07-create-once-directory-claim-v1\n"))
    claim
end

function _write_sidecar_create_once(path)
    _write_table_create_once(path*".sha256",["sha256","file"],[[_sha256_file(path),basename(path)]])
end

_holdout_manifest_sha256() = bytes2hex(sha256(_table_bytes(HOLDOUT_COLUMNS, _holdout_manifest_rows())))

function _exchange_schema_sha256()
    lines = [
        "schema_version=$(BOUNDARY_SCHEMA)",
        "candidate_id=$(BOUNDARY_CANDIDATE)",
        "holdout_columns=$(join(HOLDOUT_COLUMNS,','))",
        "fit_columns=$(join(FIT_COLUMNS,','))",
        "result_fields=$(join(RESULT_FIELDS,','))",
        "metadata_keys=$(join(BOUNDARY_METADATA_KEYS,','))",
        "packet_files=$(join(PACKET_FILES,','))",
        "oracle_columns=$(join(ORACLE_COLUMNS,','))",
    ]
    bytes2hex(sha256(join(lines,"\n")*"\n"))
end

_driver_root() = readchomp(`git -C $(dirname(@__FILE__)) rev-parse --show-toplevel`)
_candidate_root() = dirname(_active_project())

function _boundary_execution(driver_root, candidate_root, reference_root)
    abspath(driver_root)==abspath(candidate_root) &&
        error("v2 orchestration and selected-candidate checkouts must be separate")
    _git_clean(driver_root) || error("driver execution requires a clean committed worktree")
    _git_clean(candidate_root) || error("candidate execution requires a clean committed worktree")
    _git_clean(reference_root) || error("reference checkout requires a clean committed worktree")
    _hex40(JULIA_BOUNDARY_IMPL_COMMIT) || error("invalid Julia implementation commit")
    _hex40(R_BOUNDARY_IMPL_COMMIT) || error("invalid R implementation commit")
    driver_head = _git_commit(driver_root)
    candidate_head = _git_commit(candidate_root)
    candidate_head == JULIA_BOUNDARY_IMPL_COMMIT || error("selected candidate checkout commit drift")
    _git_commit(reference_root)==REFERENCE_COMMIT || error("reference checkout commit drift")
    success(`git -C $driver_root merge-base --is-ancestor $DOC46_COMMIT $driver_head`) ||
        error("execution commit does not descend from doc 46")
    success(`git -C $driver_root merge-base --is-ancestor $DOC47_COMMIT $driver_head`) ||
        error("execution commit does not descend from doc 47")
    success(`git -C $driver_root merge-base --is-ancestor $JULIA_BOUNDARY_IMPL_COMMIT $driver_head`) ||
        error("execution commit does not descend from frozen boundary implementation")
    _git_blob_commit(driver_root, DOC46_PATH) == DOC46_COMMIT || error("doc 46 commit drift")
    _sha256_file(joinpath(driver_root, DOC46_PATH)) == DOC46_SHA256 || error("doc 46 bytes drift")
    _git_blob_commit(driver_root, DOC47_PATH) == DOC47_COMMIT || error("doc 47 commit drift")
    _sha256_file(joinpath(driver_root, DOC47_PATH)) == DOC47_SHA256 || error("doc 47 bytes drift")
    _sha256_file(joinpath(candidate_root, "sim/phase2_v07_genomic_optimizer_localization.jl")) == LOCALIZATION_DRIVER_SHA256 ||
        error("frozen localization driver drift")
    _sha256_file(joinpath(driver_root, "sim/phase2_v07_genomic_optimizer_localization.jl")) == LOCALIZATION_DRIVER_SHA256 ||
        error("included localization driver drift")
    _sha256_file(joinpath(candidate_root, "sim/phase2_v07_genomic_boundary_performance.jl")) == DISCOVERY_DRIVER_SHA256 ||
        error("frozen performance driver drift")
    (driver_commit=driver_head, candidate_commit=candidate_head)
end

function _assert_discovery(discovery_dir)
    expected = Dict(
        "admission/discovery_admission.tsv" => DISCOVERY_ADMISSION_SHA256,
        "admission/environment.tsv" => DISCOVERY_ENVIRONMENT_SHA256,
        "admission/files.sha256.tsv" => DISCOVERY_ADMISSION_LOCK_SHA256,
        "summary/equivalence.tsv" => DISCOVERY_EQUIVALENCE_SHA256,
        "summary/timing_by_cell.tsv" => DISCOVERY_TIMING_SHA256,
        "summary/selection_gate.tsv" => DISCOVERY_SELECTION_SHA256,
        "summary/files.sha256.tsv" => DISCOVERY_SUMMARY_LOCK_SHA256,
    )
    for (name, digest) in expected
        path = joinpath(discovery_dir, name)
        isfile(path) || error("missing frozen discovery artifact $(name)")
        _sha256_file(path) == digest || error("frozen discovery artifact drift: $(name)")
    end
    envrows = _read_table(joinpath(discovery_dir, "admission", "environment.tsv"), ["key", "value"])
    env = Dict(String(r[1]) => String(r[2]) for r in envrows)
    env["schema_version"] == "v07-genomic-boundary-performance-v2" || error("discovery schema drift")
    env["candidate_id"] == BOUNDARY_CANDIDATE || error("discovery candidate drift")
    env["candidate_commit"] == DISCOVERY_CANDIDATE_COMMIT || error("discovery candidate commit drift")
    env["discovery_manifest_sha256"] == DISCOVERY_MANIFEST_SHA256 || error("discovery manifest binding drift")
    env["discovery_digest"] == DISCOVERY_DIGEST || error("discovery digest drift")
    env["driver_sha256"] == DISCOVERY_DRIVER_SHA256 || error("discovery driver drift")
    gate = _read_table(joinpath(discovery_dir, "summary", "selection_gate.tsv"),
                       ["outcome", "attempted", "equivalent", "timing_ok", "error_class"])
    length(gate) == 1 || error("discovery gate row-count drift")
    gate[1] == ["PASS", "870", "58", "true", "none"] || error("discovery selection did not pass")
    locks = String[]
    attempts = joinpath(discovery_dir, "attempts")
    for (dir, _, files) in walkdir(attempts), name in files
        name == "files.sha256.tsv" || continue
        path = joinpath(dir, name)
        implementation=basename(dir)
        expected_files=implementation=="default_ai" ? ["selection.tsv","result.tsv","metadata.tsv"] :
            implementation in ("reference_boundary","candidate_boundary") ?
                ["selection.tsv","result.tsv","components.tsv","metadata.tsv"] :
                error("unknown discovery implementation directory")
        members=_read_table(path,["relative_path","sha256"])
        [String(r[1]) for r in members]==expected_files || error("discovery raw-lock member order drift")
        for member in members
            target=joinpath(dir,member[1])
            isfile(target) || error("discovery raw-lock member missing")
            _sha256_file(target)==member[2] || error("discovery raw-lock member digest drift")
            _validate_sidecar(target)
        end
        push!(locks, "$(relpath(path, discovery_dir))\t$(_sha256_file(path))\n")
    end
    length(locks) == 870 || error("discovery raw-lock denominator drift")
    sort!(locks)
    bytes2hex(sha256(join(locks))) == DISCOVERY_RAW_LOCKS_SHA256 || error("discovery raw-lock digest drift")
    nothing
end

function _assert_fresh_seed_contract()
    _assert_seed_contract()
    for cell in CELLS
        fresh = Set(_fresh_holdout_seeds(cell))
        registered = union(Set(_pilot_seeds(cell)), Set(_confirmation_seeds(cell)),
            Set(_holdout_seeds(cell)), Set(FAILURE_SEEDS[cell.id]), Set(_control_seeds(cell)))
        isempty(intersect(fresh, registered)) || error("fresh holdout overlaps a registered seed")
        minimum(fresh) == _seed_base(cell)+6001 && maximum(fresh) == _seed_base(cell)+6048 ||
            error("fresh holdout offset drift")
    end
    nothing
end

function _canonical_existing_or_future(path)
    absolute=abspath(path)
    ispath(absolute) ? realpath(absolute) :
        normpath(joinpath(realpath(dirname(absolute)),basename(absolute)))
end

function _assert_no_holdout(outdir, root)
    out = _canonical_existing_or_future(outdir)
    repo = realpath(root)
    (out == repo || startswith(out, repo * Base.Filesystem.path_separator)) &&
        error("holdout output must be external to the repository")
    ispath(out) && !isempty(readdir(out)) &&
        error("holdout material already exists; candidate is spent or directory is not fresh")
end

_path_overlap(a,b) = a==b || startswith(a,b*Base.Filesystem.path_separator) ||
    startswith(b,a*Base.Filesystem.path_separator)

function _assert_isolated_roots(outdir, roots...)
    canonical=[realpath(r) for r in roots]
    length(unique(canonical))==length(canonical) || error("study roots alias through symlinks")
    out=_canonical_existing_or_future(outdir)
    any(r->_path_overlap(out,r),canonical) && error("holdout output overlaps a study root")
    for i in eachindex(canonical), j in 1:i-1
        _path_overlap(canonical[i],canonical[j]) && error("study roots overlap")
    end
    nothing
end

function _seal_rows(driver_root, candidate_root, execution, r_repo, r_oracle, discovery_dir)
    _assert_fresh_seed_contract()
    _assert_discovery(discovery_dir)
    _git_clean(r_repo) || error("R repository must be clean at candidate sealing")
    r_head = _git_commit(r_repo)
    r_head == R_BOUNDARY_IMPL_COMMIT || error("R repository is not at the exact frozen implementation")
    isfile(r_oracle) || error("independent R oracle is missing")
    startswith(r_oracle, r_repo * Base.Filesystem.path_separator) ||
        error("independent R oracle must be tracked inside the frozen R repository")
    oracle_rel = relpath(r_oracle, r_repo)
    success(`git -C $r_repo ls-files --error-unmatch $oracle_rel`) ||
        error("independent R oracle is not tracked")
    _sha256_file(r_oracle) == R_ORACLE_SHA256 || error("independent R oracle bytes drift")
    project = _active_project()
    manifest = joinpath(dirname(project), "Manifest.toml")
    isfile(manifest) || error("Manifest.toml required")
    _assert_single_threaded()
    [
        ["schema_version", BOUNDARY_SCHEMA],
        ["candidate_id", BOUNDARY_CANDIDATE],
        ["doc46_commit", DOC46_COMMIT],
        ["doc46_sha256", DOC46_SHA256],
        ["doc47_commit", DOC47_COMMIT],
        ["doc47_sha256", DOC47_SHA256],
        ["reference_commit", REFERENCE_COMMIT],
        ["julia_boundary_impl_commit", JULIA_BOUNDARY_IMPL_COMMIT],
        ["r_boundary_impl_commit", R_BOUNDARY_IMPL_COMMIT],
        ["r_execution_commit", r_head],
        ["localization_driver_sha256", LOCALIZATION_DRIVER_SHA256],
        ["performance_driver_sha256", DISCOVERY_DRIVER_SHA256],
        ["boundary_driver_sha256", _sha256_file(@__FILE__)],
        ["launcher_sha256", _sha256_file(joinpath(driver_root,"sim/totoro/v07_genomic_boundary_holdout_v2.sh"))],
        ["genomic_source_sha256", _sha256_file(joinpath(candidate_root,"src/genomic.jl"))],
        ["r_oracle_sha256", R_ORACLE_SHA256],
        ["exchange_schema", BOUNDARY_SCHEMA],
        ["exchange_schema_sha256", _exchange_schema_sha256()],
        ["profiler_schema", "v07-genomic-boundary-performance-v2"],
        ["profiler_candidate_id", BOUNDARY_CANDIDATE],
        ["packet_file_set", join(PACKET_FILES, ",")],
        ["provenance_domain_hex", PROVENANCE_DOMAIN_HEX],
        ["provenance_encoding", PROVENANCE_ENCODING],
        ["result_digest_encoding", RESULT_DIGEST_ENCODING],
        ["id_hash_kind", "id_order"],
        ["kernel_hash_kind", "K_lambda"],
        ["precision_hash_kind", "Q_lambda"],
        ["qk_identity_tolerance", _format(QK_IDENTITY_TOL)],
        ["relationship_source", "markers"],
        ["relationship_method", "vanraden1"],
        ["allele_frequency_source", "sample"],
        ["ridge", _format(RIDGE)],
        ["relationship_scale", "K_lambda"],
        ["boundary_epsilon", _format(BOUNDARY_EPSILON)],
        ["grid_step", _format(GRID_STEP)],
        ["refinement_abs_tol", _format(REFINEMENT_ABS_TOL)],
        ["likelihood_tie_per_observation", _format(LIKELIHOOD_TIE_PER_OBS)],
        ["derivative_delta", _format(DERIVATIVE_DELTA)],
        ["kkt_tolerance_per_observation", _format(KKT_TOL_PER_OBS)],
        ["holdout_seed_formula", HOLDOUT_SEED_FORMULA],
        ["timing_protocol", "fixed_nonholdout_warmup_then_seed_parity_order"],
        ["holdout_p95_rule", "sort(x)[ceil(0.95*48)]"],
        ["holdout_runtime_ratio_limit", "3"],
        ["discovery_runtime_ratio_limit", "2.5"],
        ["discovery_reference_ratio_limit", "1.10"],
        ["holdout_manifest_sha256", _holdout_manifest_sha256()],
        ["discovery_manifest_sha256", DISCOVERY_MANIFEST_SHA256],
        ["discovery_admission_sha256", DISCOVERY_ADMISSION_SHA256],
        ["discovery_environment_sha256", DISCOVERY_ENVIRONMENT_SHA256],
        ["discovery_admission_lock_sha256", DISCOVERY_ADMISSION_LOCK_SHA256],
        ["discovery_raw_locks_sha256", DISCOVERY_RAW_LOCKS_SHA256],
        ["discovery_equivalence_sha256", DISCOVERY_EQUIVALENCE_SHA256],
        ["discovery_timing_sha256", DISCOVERY_TIMING_SHA256],
        ["discovery_selection_sha256", DISCOVERY_SELECTION_SHA256],
        ["discovery_summary_lock_sha256", DISCOVERY_SUMMARY_LOCK_SHA256],
        ["discovery_digest", DISCOVERY_DIGEST],
        ["discovery_candidate_commit", DISCOVERY_CANDIDATE_COMMIT],
        ["candidate_implementation_commit", execution.candidate_commit],
        ["julia_driver_commit", execution.driver_commit],
        ["execution_commit", execution.driver_commit],
        ["host", readchomp(`hostname`)],
        ["cpu_model", isempty(Sys.cpu_info()) ? "unknown" : Sys.cpu_info()[1].model],
        ["machine", Sys.MACHINE],
        ["kernel", string(Sys.KERNEL)],
        ["arch", string(Sys.ARCH)],
        ["julia_version", string(VERSION)],
        ["r_version", first(split(read(`R --version`, String), '\n'))],
        ["project_sha256", _sha256_file(project)],
        ["manifest_sha256", _sha256_file(manifest)],
        ["julia_num_threads", string(Threads.nthreads())],
        ["openblas_num_threads", get(ENV, "OPENBLAS_NUM_THREADS", "")],
        ["omp_num_threads", get(ENV, "OMP_NUM_THREADS", "")],
        ["veclib_maximum_threads", get(ENV, "VECLIB_MAXIMUM_THREADS", "")],
        ["holdout_absent_before_seal", "true"],
        ["spent_offset_block_excluded", "5001:5048"],
    ]
end

function seal_mode(args)
    driver_root = _driver_root()
    candidate_root = _candidate_root()
    reference_root = abspath(_breq(args,"reference-root"))
    execution = _boundary_execution(driver_root, candidate_root, reference_root)
    outdir = abspath(_breq(args, "out-dir"))
    discovery_dir = abspath(_breq(args, "discovery-dir"))
    r_repo = abspath(_breq(args, "r-repo"))
    r_oracle = abspath(_breq(args, "r-oracle"))
    _assert_isolated_roots(outdir,driver_root,candidate_root,reference_root,r_repo,discovery_dir)
    _assert_no_holdout(outdir, driver_root)
    _assert_no_holdout(outdir, candidate_root)
    rows = _seal_rows(driver_root,candidate_root,execution,r_repo,r_oracle,discovery_dir)
    [String(r[1]) for r in rows]==SEAL_KEYS || error("seal writer key order/set drift")
    mkpath(outdir)
    path = joinpath(outdir, "candidate_seal.tsv")
    _write_table_create_once(path, ["key", "value"], rows)
    _write_sidecar_create_once(path)
    println("sealed candidate before holdout materialization: $(_sha256_file(path))")
end

function _parse_seal_rows(rows)
    [String(r[1]) for r in rows] == SEAL_KEYS || error("candidate seal key order/set drift")
    settings=Dict(String(r[1])=>String(r[2]) for r in rows)
    length(settings)==length(SEAL_KEYS) || error("candidate seal has duplicate keys")
    settings
end

function _candidate_settings(outdir)
    path = joinpath(outdir, "candidate_seal.tsv")
    _validate_sidecar(path)
    rows = _read_table(path, ["key", "value"])
    settings = _parse_seal_rows(rows)
    project=_active_project(); manifest=joinpath(dirname(project),"Manifest.toml")
    expected = Dict(
        "schema_version" => BOUNDARY_SCHEMA,
        "candidate_id" => BOUNDARY_CANDIDATE,
        "doc46_commit" => DOC46_COMMIT,
        "doc46_sha256" => DOC46_SHA256,
        "doc47_commit" => DOC47_COMMIT,
        "doc47_sha256" => DOC47_SHA256,
        "reference_commit" => REFERENCE_COMMIT,
        "julia_boundary_impl_commit" => JULIA_BOUNDARY_IMPL_COMMIT,
        "r_boundary_impl_commit" => R_BOUNDARY_IMPL_COMMIT,
        "r_execution_commit" => R_BOUNDARY_IMPL_COMMIT,
        "localization_driver_sha256" => LOCALIZATION_DRIVER_SHA256,
        "performance_driver_sha256" => DISCOVERY_DRIVER_SHA256,
        "boundary_driver_sha256" => _sha256_file(@__FILE__),
        "launcher_sha256" => _sha256_file(joinpath(_driver_root(),"sim/totoro/v07_genomic_boundary_holdout_v2.sh")),
        "genomic_source_sha256" => _sha256_file(joinpath(_candidate_root(),"src/genomic.jl")),
        "r_oracle_sha256" => R_ORACLE_SHA256,
        "exchange_schema" => BOUNDARY_SCHEMA,
        "exchange_schema_sha256" => _exchange_schema_sha256(),
        "profiler_schema" => "v07-genomic-boundary-performance-v2",
        "profiler_candidate_id" => BOUNDARY_CANDIDATE,
        "packet_file_set" => join(PACKET_FILES, ","),
        "provenance_domain_hex" => PROVENANCE_DOMAIN_HEX,
        "provenance_encoding" => PROVENANCE_ENCODING,
        "result_digest_encoding" => RESULT_DIGEST_ENCODING,
        "id_hash_kind" => "id_order",
        "kernel_hash_kind" => "K_lambda",
        "precision_hash_kind" => "Q_lambda",
        "qk_identity_tolerance" => _format(QK_IDENTITY_TOL),
        "relationship_source" => "markers",
        "relationship_method" => "vanraden1",
        "allele_frequency_source" => "sample",
        "ridge" => _format(RIDGE),
        "relationship_scale" => "K_lambda",
        "boundary_epsilon" => _format(BOUNDARY_EPSILON),
        "grid_step" => _format(GRID_STEP),
        "refinement_abs_tol" => _format(REFINEMENT_ABS_TOL),
        "likelihood_tie_per_observation" => _format(LIKELIHOOD_TIE_PER_OBS),
        "derivative_delta" => _format(DERIVATIVE_DELTA),
        "kkt_tolerance_per_observation" => _format(KKT_TOL_PER_OBS),
        "holdout_seed_formula" => HOLDOUT_SEED_FORMULA,
        "holdout_manifest_sha256" => _holdout_manifest_sha256(),
        "timing_protocol" => "fixed_nonholdout_warmup_then_seed_parity_order",
        "holdout_p95_rule" => "sort(x)[ceil(0.95*48)]",
        "holdout_runtime_ratio_limit" => "3",
        "discovery_runtime_ratio_limit" => "2.5",
        "discovery_reference_ratio_limit" => "1.10",
        "discovery_manifest_sha256" => DISCOVERY_MANIFEST_SHA256,
        "discovery_admission_sha256" => DISCOVERY_ADMISSION_SHA256,
        "discovery_environment_sha256" => DISCOVERY_ENVIRONMENT_SHA256,
        "discovery_admission_lock_sha256" => DISCOVERY_ADMISSION_LOCK_SHA256,
        "discovery_raw_locks_sha256" => DISCOVERY_RAW_LOCKS_SHA256,
        "discovery_equivalence_sha256" => DISCOVERY_EQUIVALENCE_SHA256,
        "discovery_timing_sha256" => DISCOVERY_TIMING_SHA256,
        "discovery_selection_sha256" => DISCOVERY_SELECTION_SHA256,
        "discovery_summary_lock_sha256" => DISCOVERY_SUMMARY_LOCK_SHA256,
        "discovery_candidate_commit" => DISCOVERY_CANDIDATE_COMMIT,
        "discovery_digest" => DISCOVERY_DIGEST,
        "candidate_implementation_commit" => JULIA_BOUNDARY_IMPL_COMMIT,
        "host" => readchomp(`hostname`),
        "cpu_model" => isempty(Sys.cpu_info()) ? "unknown" : Sys.cpu_info()[1].model,
        "machine" => Sys.MACHINE,
        "kernel" => string(Sys.KERNEL),
        "arch" => string(Sys.ARCH),
        "julia_version" => string(VERSION),
        "r_version" => first(split(read(`R --version`,String),'\n')),
        "project_sha256" => _sha256_file(project),
        "manifest_sha256" => _sha256_file(manifest),
        "julia_num_threads" => string(Threads.nthreads()),
        "openblas_num_threads" => get(ENV,"OPENBLAS_NUM_THREADS",""),
        "omp_num_threads" => get(ENV,"OMP_NUM_THREADS",""),
        "veclib_maximum_threads" => get(ENV,"VECLIB_MAXIMUM_THREADS",""),
        "holdout_absent_before_seal" => "true",
        "spent_offset_block_excluded" => "5001:5048",
    )
    all(get(settings, k, "") == v for (k, v) in expected) || error("candidate seal drift")
    get(settings,"candidate_implementation_commit","")==JULIA_BOUNDARY_IMPL_COMMIT ||
        error("sealed candidate implementation drift")
    get(settings,"julia_driver_commit","")==get(settings,"execution_commit","") ||
        error("sealed Julia driver/execution commit drift")
    _git_commit(_candidate_root())==JULIA_BOUNDARY_IMPL_COMMIT || error("active candidate checkout drift")
    _git_commit(_driver_root())==settings["julia_driver_commit"] || error("active Julia driver checkout drift")
    _sha256_file(@__FILE__)==settings["boundary_driver_sha256"] || error("active Julia driver bytes drift")
    _git_clean(_candidate_root()) || error("candidate checkout became dirty after seal")
    _git_clean(_driver_root()) || error("driver checkout became dirty after seal")
    _assert_single_threaded()
    settings
end

function manifest_mode(args)
    outdir = abspath(_breq(args, "out-dir"))
    settings = _candidate_settings(outdir)
    path = joinpath(outdir, "holdout_manifest.tsv")
    bytes = _table_bytes(HOLDOUT_COLUMNS, _holdout_manifest_rows())
    bytes2hex(sha256(bytes)) == settings["holdout_manifest_sha256"] || error("manifest preimage drift")
    if isfile(path)
        _validate_sidecar(path)
        _sha256_file(path) == settings["holdout_manifest_sha256"] || error("existing manifest drift")
        println("resume: holdout manifest already sealed")
        return
    end
    _write_table_create_once(path, HOLDOUT_COLUMNS, _holdout_manifest_rows())
    _sha256_file(path) == settings["holdout_manifest_sha256"] || error("written manifest digest drift")
    _write_sidecar_create_once(path)
    println("wrote sealed 240-row holdout manifest")
end

function _manifest(outdir)
    settings = _candidate_settings(outdir)
    path = joinpath(outdir, "holdout_manifest.tsv")
    _validate_sidecar(path)
    _sha256_file(path) == settings["holdout_manifest_sha256"] || error("holdout manifest drift")
    rows = _read_table(path, HOLDOUT_COLUMNS)
    length(rows) == 240 || error("holdout denominator drift")
    out = Dict{Tuple{String,Int},NamedTuple}()
    for row in rows
        cell = _cell(row[1]); seed = parse(Int, row[2])
        seed in _fresh_holdout_seeds(cell) || error("non-frozen fresh holdout seed")
        parse(Int, row[3]) == cell.n && parse(Int, row[4]) == cell.m || error("manifest dimension drift")
        parse(Float64, row[5]) == RIDGE || error("manifest ridge drift")
        key = (cell.id, seed); haskey(out, key) && error("duplicate holdout dataset")
        out[key] = (cell=cell, seed=seed)
    end
    out
end

_attempt_path(outdir,cell,seed)=joinpath(outdir,"attempts",cell,"$(seed).tsv")

function _attempt_row(settings,cell,seed)
    order=_timed_order(seed)
    [[cell.id,seed,order,settings["candidate_seal_sha256"],settings["candidate_implementation_commit"],
      settings["julia_driver_commit"],"attempted"]]
end

const ATTEMPT_COLUMNS=split("cell_id seed timed_order candidate_seal_sha256 candidate_implementation_commit julia_driver_commit state")

function _fresh_dataset(settings,manifest,cell,seed;generator=_dataset)
    get(settings,"holdout_absent_before_seal","")=="true" || error("fresh data requested without sealed absence proof")
    get(settings,"spent_offset_block_excluded","")=="5001:5048" || error("spent-block exclusion missing")
    haskey(manifest,(cell.id,seed)) || error("fresh data requested outside sealed manifest")
    seed in _fresh_holdout_seeds(cell) || error("fresh data seed offset drift")
    generator(cell,seed)
end

function _validate_attempt_ledger(outdir,settings,cell,seed)
    path=_attempt_path(outdir,cell.id,seed); _validate_sidecar(path)
    read(path)==_table_bytes(ATTEMPT_COLUMNS,_attempt_row(settings,cell,seed)) || error("attempt ledger drift")
    nothing
end

function _assert_exact_campaign_sets(outdir,manifest)
    expected=sort([joinpath(cell, string(seed)) for ((cell,seed),_) in manifest])
    expected_files=sort(vcat([path*".tsv" for path in expected],
        [path*".tsv.sha256" for path in expected]))
    attempts_root=joinpath(outdir,"attempts")
    actual_attempts=String[]
    isdir(attempts_root) && for (dir,_,files) in walkdir(attempts_root),name in files
        push!(actual_attempts,relpath(joinpath(dir,name),attempts_root))
    end
    sort!(actual_attempts); actual_attempts==expected_files || error("attempt ledger set/denominator drift")
    packets_root=joinpath(outdir,"packets")
    actual_packets=String[]
    isdir(packets_root) && for (dir,subdirs,_) in walkdir(packets_root)
        isempty(subdirs) && push!(actual_packets,relpath(dir,packets_root))
    end
    sort!(actual_packets); actual_packets==expected || error("packet set/denominator drift")
    expected_packet_claims=sort([path*".claim" for path in expected])
    packet_external_files=String[]
    if isdir(packets_root)
        for (dir,_,files) in walkdir(packets_root),name in files
            relative=relpath(joinpath(dir,name),packets_root)
            inside_packet=any(path->_path_overlap(relative,path) && relative!=path,expected)
            inside_packet || push!(packet_external_files,relative)
        end
    end
    sort!(packet_external_files)
    packet_external_files==expected_packet_claims || error("packet claim/external-file set drift")
    oracle_root=joinpath(outdir,"oracle")
    actual_oracles=String[]
    isdir(oracle_root) && for (dir,_,files) in walkdir(oracle_root),name in files
        push!(actual_oracles,relpath(joinpath(dir,name),oracle_root))
    end
    sort!(actual_oracles); actual_oracles==expected_files || error("oracle set/denominator drift")
    nothing
end

_canon_result_float(x) = x === nothing ? "NA" : (isfinite(Float64(x)) ? @sprintf("%.17g", Float64(x)) : "NA")
_canon_result_bool(x) = x === nothing ? "NA" : (Bool(x) ? "true" : "false")

function _result_digest(record)
    io=IOBuffer()
    for field in RESULT_FIELDS
        value=get(record,field,nothing); value===nothing && error("missing result digest field $(field)")
        occursin(r"[\t\r\n]",value) && error("result digest control character")
        print(io,field,'=',value,'\n')
    end
    bytes2hex(sha256(take!(io)))
end

function _result_record_holdout(route, result, hashes;error_class="none")
    base = Dict{String,String}(
        "marker_hash"=>hashes.marker_hash, "id_hash"=>hashes.id_hash,
        "kernel_hash"=>hashes.kernel_hash, "precision_hash"=>hashes.precision_hash,
        "relationship_source"=>"markers", "relationship_method"=>"vanraden1",
        "allele_frequency_source"=>"sample", "ridge"=>@sprintf("%.17g", RIDGE),
        "relationship_scale"=>"K_lambda")
    if result === nothing
        merge!(base,Dict("digest_version"=>route=="default_ai" ? "default_ai_result_v1" : "scientific_result_v1",
            "status"=>"exception","reason"=>error_class,"converged"=>"false","termination"=>"exception",
            "profile_ratio"=>"NA","numerical_ratio"=>"NA","t_hat"=>"NA","profile_loglik"=>"NA",
            "d0"=>"NA","d1"=>"NA","sigma_g2"=>"NA","sigma_e2"=>"NA"))
    elseif route == "default_ai"
        vc=result.variance_components; ratio=vc.sigma_a2/(vc.sigma_a2+vc.sigma_e2)
        merge!(base, Dict("digest_version"=>"default_ai_result_v1",
            "status"=>String(result.optimizer_status), "reason"=>String(result.optimizer_status),
            "converged"=>_canon_result_bool(result.converged),
            "termination"=>String(result.optimizer_status), "profile_ratio"=>"NA",
            "numerical_ratio"=>_canon_result_float(ratio), "t_hat"=>"NA",
            "profile_loglik"=>"NA", "d0"=>"NA", "d1"=>"NA",
            "sigma_g2"=>_canon_result_float(vc.sigma_a2),
            "sigma_e2"=>_canon_result_float(vc.sigma_e2)))
    else
        boundary=result.boundary; fit=result.fit
        vc=fit === nothing ? nothing : fit.variance_components
        t_hat=(vc === nothing || boundary.status=="boundary_unresolved") ? nothing : vc.sigma_a2+vc.sigma_e2
        merge!(base, Dict("digest_version"=>"scientific_result_v1",
            "status"=>String(boundary.status), "reason"=>String(boundary.reason),
            "converged"=>_canon_result_bool(fit===nothing ? false : fit.converged),
            "termination"=>fit===nothing ? "boundary_unresolved" : String(fit.optimizer_status),
            "profile_ratio"=>_canon_result_float(boundary.profile_ratio),
            "numerical_ratio"=>_canon_result_float(boundary.numerical_ratio),
            "t_hat"=>_canon_result_float(t_hat),
            "profile_loglik"=>_canon_result_float(boundary.profile_loglik),
            "d0"=>_canon_result_float(boundary.lower_derivative_per_observation),
            "d1"=>_canon_result_float(boundary.upper_derivative_per_observation),
            "sigma_g2"=>_canon_result_float(vc===nothing ? nothing : vc.sigma_a2),
            "sigma_e2"=>_canon_result_float(vc===nothing ? nothing : vc.sigma_e2)))
    end
    base["result_digest"]=_result_digest(base)
    base
end

const FAILED_SCIENTIFIC_FIELDS=("sigma_g2","sigma_e2","numerical_ratio","profile_ratio",
    "profile_t_hat","profile_loglik","lower_derivative_per_observation",
    "upper_derivative_per_observation","objective","ai_score_norm","fd_log_gradient_norm")

function _validate_failed_fit_row(f)
    f["error_class"]=="none" && return nothing
    f["optimizer_status"]=="exception" && f["boundary_status"]=="exception" &&
        !_bool_token(f["converged"]) || error("failed fit row semantic drift")
    f["termination_reason"]==f["error_class"] || error("failed fit reason/error-class drift")
    all(isnan(_float(f[k])) for k in FAILED_SCIENTIFIC_FIELDS) ||
        error("failed fit row retained scientific values")
    nothing
end

function _validate_fit_status_contract(f)
    f["error_class"]!="none" && return _validate_failed_fit_row(f)
    route=f["route"]
    if route=="default_ai"
        f["boundary_status"]=="not_classified" || error("default route classification drift")
        f["optimizer_status"] in ("converged","not_converged") || error("default optimizer status drift")
        f["termination_reason"]==f["optimizer_status"] || error("default termination/status drift")
        _bool_token(f["converged"])==(f["optimizer_status"]=="converged") ||
            error("default convergence/status drift")
        return nothing
    end
    route=="boundary_candidate" || error("unknown fit route")
    status=f["boundary_status"]
    expected = status=="boundary_lower" || status=="boundary_upper" ?
        (status,status,true) : status=="interior" ?
        ("ai_interior","converged",true) : status=="interior_rescued" ?
        ("profile_interior","interior_rescued",true) : status=="boundary_unresolved" ?
        (nothing,"boundary_unresolved",false) : error("candidate boundary status drift")
    if expected[1]===nothing
        !isempty(f["termination_reason"]) || error("unresolved reason is empty")
    else
        f["termination_reason"]==expected[1] || error("candidate termination reason drift")
    end
    f["optimizer_status"]==expected[2] || error("candidate optimizer status drift")
    _bool_token(f["converged"])==expected[3] || error("candidate convergence/status drift")
    nothing
end

function _fit_row(cell, seed, route, timed_order, result, runtime, hashes; error_class="none")
    record = _result_record_holdout(route, result, hashes;error_class=error_class)
    provenance = Any[hashes.precision_hash, "markers", "vanraden1", "sample", RIDGE,
                     "K_lambda", record["result_digest"]]
    if result===nothing
        return Any[cell.id,seed,route,timed_order,false,error_class,"exception",0,
            NaN,NaN,NaN,NaN,NaN,"exception",BOUNDARY_EPSILON,NaN,NaN,NaN,NaN,NaN,NaN,
            runtime,hashes.marker_hash,hashes.id_hash,hashes.kernel_hash,provenance...,error_class]
    end
    if route == "default_ai"
        fit = result
        vc = fit.variance_components
        ratio = vc.sigma_a2 / (vc.sigma_a2 + vc.sigma_e2)
        return Any[cell.id, seed, route, timed_order, fit.converged, fit.optimizer_status, fit.optimizer_status, fit.iterations,
            vc.sigma_a2, vc.sigma_e2, ratio, NaN, NaN, "not_classified", BOUNDARY_EPSILON,
            NaN, NaN, NaN, fit.likelihood.loglik, NaN, _julia_fd_gradient(fit), runtime,
            hashes.marker_hash, hashes.id_hash, hashes.kernel_hash, provenance..., error_class]
    end
    fit = result.fit; boundary = result.boundary
    status = String(boundary.status)
    status in ALL_STATUSES || error("unknown boundary status")
    if fit === nothing
        status == "boundary_unresolved" || error("resolved boundary result is missing its fit")
        return Any[cell.id, seed, route, timed_order, false, String(boundary.reason), "boundary_unresolved", 0,
            NaN, NaN, NaN, NaN, NaN, status, boundary.boundary_epsilon,
            NaN, NaN, NaN, NaN, NaN, NaN, runtime,
            hashes.marker_hash, hashes.id_hash, hashes.kernel_hash, provenance..., error_class]
    end
    vc = fit.variance_components
    numerical_ratio = boundary.numerical_ratio === nothing ? NaN : boundary.numerical_ratio
    profile_ratio = boundary.profile_ratio === nothing ? NaN : boundary.profile_ratio
    profile_t_hat = status in RESOLVED_STATUSES ? vc.sigma_a2 + vc.sigma_e2 : NaN
    profile_loglik = boundary.profile_loglik === nothing ? NaN : boundary.profile_loglik
    d0 = boundary.lower_derivative_per_observation === nothing ? NaN : boundary.lower_derivative_per_observation
    d1 = boundary.upper_derivative_per_observation === nothing ? NaN : boundary.upper_derivative_per_observation
    diag = result.ai_diagnostics
    # The independent reader requires a finite diagnostic for every resolved
    # candidate.  At an endpoint this is descriptive only; validity is decided
    # by the frozen profile derivatives and KKT rule, not this interior score.
    fd = _julia_fd_gradient(fit)
    Any[cell.id, seed, route, timed_order, fit.converged, String(boundary.reason), fit.optimizer_status, fit.iterations,
        vc.sigma_a2, vc.sigma_e2, numerical_ratio, profile_ratio, profile_t_hat, status,
        boundary.boundary_epsilon, profile_loglik, d0, d1, fit.likelihood.loglik,
        diag.ai_score_norm, fd, runtime, hashes.marker_hash, hashes.id_hash, hashes.kernel_hash,
        provenance..., error_class]
end

# Each holdout dataset runs in a fresh Julia process, so timing either method
# before compilation would measure JIT latency rather than the frozen methods.
# This deterministic fixture is not generated by any discovery or holdout seed;
# its values are discarded.  Timed method order is then balanced by seed parity.
function _warm_boundary_timing()
    n = 7
    ids = ["compile_warmup_$(i)" for i in 1:n]
    y = [-1.3, 0.2, 0.9, -0.4, 1.7, -0.8, 0.5]
    X = ones(n, 1)
    Q = Matrix{Float64}(I, n, n)
    spec = animal_model_spec(y, X, sparse(1.0I, n, n), Q; ids=ids, method=:REML)
    provenance = (
        relationship_source = "supplied_Ginv",
        id_order_fingerprint = HSquared._genomic_id_order_fingerprint(ids),
        precision_fingerprint = HSquared._genomic_matrix_fingerprint("Q_lambda", Q, ids),
    )
    fit_ai_reml(spec)
    HSquared._fit_ai_reml_genomic_boundary(spec; provenance=provenance)
    nothing
end

function _write_matrix(path, A, prefix)
    columns = vcat(["row"], ["$(prefix)$(j)" for j in axes(A, 2)])
    rows = [vcat(Any[i], Any[A[i, j] for j in axes(A, 2)]) for i in axes(A, 1)]
    _write_table_exclusive(path, columns, rows)
end

function _read_matrix_v2(path, prefix, n)
    columns = vcat(["row"], ["$(prefix)$(j)" for j in 1:n])
    rows = _read_table(path, columns)
    length(rows) == n || error("matrix row-count drift: $(basename(path))")
    A = Matrix{Float64}(undef, n, n)
    for i in 1:n
        parse(Int, rows[i][1]) == i || error("matrix row index drift: $(basename(path))")
        for j in 1:n
            A[i,j] = parse(Float64, rows[i][j+1])
        end
    end
    all(isfinite, A) || error("matrix contains nonfinite values: $(basename(path))")
    A
end

function _read_rect_matrix_v2(path,prefix,n,p)
    columns=vcat(["row"],["$(prefix)$(j)" for j in 1:p])
    rows=_read_table(path,columns); length(rows)==n || error("matrix row-count drift: $(basename(path))")
    A=Matrix{Float64}(undef,n,p)
    for i in 1:n
        parse(Int,rows[i][1])==i || error("matrix row index drift: $(basename(path))")
        for j in 1:p; A[i,j]=parse(Float64,rows[i][j+1]); end
    end
    all(isfinite,A) || error("matrix contains nonfinite values: $(basename(path))")
    A
end

_qk_identity_ok(K,Q) = size(K)==size(Q) && size(K,1)==size(K,2) &&
    maximum(abs.(Q*K-I))<=QK_IDENTITY_TOL

function _digest_record_from_fit(fit)
    route=fit["route"]
    default=route=="default_ai"
    route in ("default_ai","boundary_candidate") || error("unknown fit route")
    val(key)=begin
        x=_float(fit[key]); isfinite(x) ? _canon_result_float(x) : "NA"
    end
    record=Dict{String,String}(
        "digest_version"=>default ? "default_ai_result_v1" : "scientific_result_v1",
        "status"=>default ? fit["optimizer_status"] : fit["boundary_status"],
        "reason"=>fit["termination_reason"],
        "converged"=>_bool_token(fit["converged"]) ? "true" : "false",
        "termination"=>fit["optimizer_status"],
        "profile_ratio"=>val("profile_ratio"), "numerical_ratio"=>val("numerical_ratio"),
        "t_hat"=>val("profile_t_hat"), "profile_loglik"=>val("profile_loglik"),
        "d0"=>val("lower_derivative_per_observation"),
        "d1"=>val("upper_derivative_per_observation"),
        "sigma_g2"=>val("sigma_g2"), "sigma_e2"=>val("sigma_e2"),
        "marker_hash"=>fit["marker_hash"], "id_hash"=>fit["id_hash"],
        "kernel_hash"=>fit["kernel_hash"], "precision_hash"=>fit["precision_hash"],
        "relationship_source"=>fit["relationship_source"],
        "relationship_method"=>fit["relationship_method"],
        "allele_frequency_source"=>fit["allele_frequency_source"],
        "ridge"=>val("ridge"), "relationship_scale"=>fit["relationship_scale"])
    _result_digest(record)
end

function _validate_packet(packet, settings, manifest_sha;expected=nothing)
    lock = joinpath(packet, "files.sha256.tsv")
    rows = _read_table(lock, ["relative_path", "sha256"])
    [String(r[1]) for r in rows] == PACKET_FILES || error("packet file set/order drift")
    for row in rows
        path = joinpath(packet, row[1]); isfile(path) || error("missing packet file")
        _sha256_file(path) == row[2] || error("packet checksum drift")
        _validate_sidecar(path)
    end
    _validate_sidecar(lock)
    actual = sort(readdir(packet))
    expected_actual=sort(vcat(PACKET_FILES,[name*".sha256" for name in PACKET_FILES],
        ["files.sha256.tsv","files.sha256.tsv.sha256"]))
    actual == expected_actual || error("packet contains unsealed files")
    metadata = _read_table(joinpath(packet, "metadata.tsv"), ["key", "value"])
    [String(r[1]) for r in metadata] == BOUNDARY_METADATA_KEYS || error("metadata key order drift")
    md = Dict(String(r[1]) => String(r[2]) for r in metadata)
    md["schema_version"] == BOUNDARY_SCHEMA && md["candidate_id"] == BOUNDARY_CANDIDATE || error("packet schema drift")
    md["doc47_commit"] == DOC47_COMMIT && md["doc47_sha256"] == DOC47_SHA256 || error("packet doc47 drift")
    md["julia_boundary_impl_commit"] == JULIA_BOUNDARY_IMPL_COMMIT || error("packet Julia implementation drift")
    md["r_boundary_impl_commit"] == R_BOUNDARY_IMPL_COMMIT || error("packet R implementation drift")
    md["candidate_seal_sha256"] == settings["candidate_seal_sha256"] || error("packet candidate seal drift")
    md["holdout_manifest_sha256"] == manifest_sha || error("packet manifest drift")
    all(_hex64(md[k]) for k in ("marker_hash", "id_hash", "kernel_hash", "precision_hash", "doc46_sha256", "doc47_sha256",
        "discovery_digest", "discovery_equivalence_sha256", "discovery_timing_sha256", "discovery_selection_sha256", "candidate_seal_sha256",
        "holdout_manifest_sha256", "driver_sha256", "r_oracle_sha256")) || error("packet hash width drift")
    all(_hex40(md[k]) for k in ("doc46_commit", "doc47_commit", "julia_boundary_impl_commit",
        "r_boundary_impl_commit", "execution_commit")) || error("packet commit width drift")
    md["relationship_source"]=="markers" && md["relationship_method"]=="vanraden1" &&
        md["allele_frequency_source"]=="sample" && md["relationship_scale"]=="K_lambda" ||
        error("packet relationship provenance drift")
    _float(md["ridge"])==RIDGE || error("packet ridge drift")
    n=parse(Int,md["n"])
    p=parse(Int,md["p"])
    if expected!==nothing
        md["cell_id"]==expected.cell.id && parse(Int,md["seed"])==expected.seed ||
            error("packet/manifest identity drift")
        n==expected.cell.n && parse(Int,md["m"])==expected.cell.m || error("packet/manifest dimension drift")
        basename(packet)==string(expected.seed) && basename(dirname(packet))==expected.cell.id ||
            error("packet filesystem transplant detected")
    end
    idsrows=_read_table(joinpath(packet,"ids.tsv"),["row","id"])
    length(idsrows)==n || error("ID row-count drift")
    ids=String[]
    for i in 1:n
        parse(Int,idsrows[i][1])==i || error("ID row index drift")
        push!(ids,String(idsrows[i][2]))
    end
    length(unique(ids))==n || error("packet IDs are not unique")
    yrows=_read_table(joinpath(packet,"y.tsv"),["row","y"])
    length(yrows)==n || error("response row-count drift")
    y=Float64[]
    for i in 1:n
        parse(Int,yrows[i][1])==i || error("response row index drift")
        push!(y,parse(Float64,yrows[i][2]))
    end
    all(isfinite,y) || error("response contains nonfinite values")
    X=_read_rect_matrix_v2(joinpath(packet,"X.tsv"),"x",n,p)
    rank(X)==p || error("packet fixed-effect design is rank deficient")
    K=_read_matrix_v2(joinpath(packet,"K.tsv"),"k",n)
    Q=_read_matrix_v2(joinpath(packet,"Q.tsv"),"q",n)
    issymmetric(K) && issymmetric(Q) || error("packet K/Q symmetry drift")
    isposdef(cholesky(Symmetric(K);check=false)) && isposdef(cholesky(Symmetric(Q);check=false)) ||
        error("packet K/Q positive-definiteness drift")
    HSquared._genomic_id_order_fingerprint(ids)==md["id_hash"] || error("recomputed ID hash drift")
    HSquared._genomic_matrix_fingerprint("K_lambda",K,ids)==md["kernel_hash"] || error("recomputed kernel hash drift")
    HSquared._genomic_matrix_fingerprint("Q_lambda",Q,ids)==md["precision_hash"] || error("recomputed precision hash drift")
    _qk_identity_ok(K,Q) || error("Q*K identity drift")
    fitrows = _read_table(joinpath(packet, "fits.tsv"), FIT_COLUMNS)
    length(fitrows) == 2 || error("packet fit denominator drift")
    [String(r[3]) for r in fitrows] == ["default_ai", "boundary_candidate"] || error("fit route order drift")
    fits = _fit_dict.(fitrows)
    expected_order=_timed_order(parse(Int,md["seed"]))
    all(f["timed_order"]==expected_order for f in fits) || error("fit timing order drift")
    all(isfinite(_float(f["runtime_seconds"])) && _float(f["runtime_seconds"])>=0 for f in fits) ||
        error("fit runtime is negative or nonfinite")
    all(f["cell_id"] == md["cell_id"] && f["seed"] == md["seed"] &&
        f["marker_hash"] == md["marker_hash"] && f["id_hash"] == md["id_hash"] &&
        f["kernel_hash"] == md["kernel_hash"] && f["precision_hash"]==md["precision_hash"] &&
        f["relationship_source"]==md["relationship_source"] &&
        f["relationship_method"]==md["relationship_method"] &&
        f["allele_frequency_source"]==md["allele_frequency_source"] &&
        f["relationship_scale"]==md["relationship_scale"] && _float(f["ridge"])==RIDGE
        for f in fits) || error("fit/metadata provenance drift")
    all(_hex64(f["result_digest"]) && _digest_record_from_fit(f)==f["result_digest"] for f in fits) ||
        error("fit scientific-result digest drift")
    foreach(_validate_fit_status_contract,fits)
    if fits[1]["error_class"]=="none"
        fits[1]["boundary_status"] == "not_classified" || error("default route was classified")
        all(isnan(_float(fits[1][k])) for k in ("profile_ratio", "profile_t_hat", "profile_loglik",
            "lower_derivative_per_observation", "upper_derivative_per_observation")) || error("default profile fields must be missing")
    end
    status = fits[2]["boundary_status"]
    fits[2]["error_class"]!="none" && return nothing
    status in ALL_STATUSES || error("candidate boundary status drift")
    if status == "boundary_unresolved"
        !_bool_token(fits[2]["converged"]) || error("unresolved candidate cannot converge")
    else
        _bool_token(fits[2]["converged"]) || error("resolved candidate must converge")
        all(isfinite(_float(fits[2][k])) for k in ("sigma_g2", "sigma_e2", "numerical_ratio",
            "profile_ratio", "profile_t_hat", "boundary_epsilon", "profile_loglik",
            "lower_derivative_per_observation", "upper_derivative_per_observation", "objective",
            "ai_score_norm", "fd_log_gradient_norm", "runtime_seconds")) || error("resolved candidate has nonfinite fields")
        _float(fits[2]["boundary_epsilon"]) == BOUNDARY_EPSILON || error("candidate epsilon drift")
        if status == "boundary_lower"
            _float(fits[2]["profile_ratio"]) == 0.0 &&
                _float(fits[2]["numerical_ratio"]) == BOUNDARY_EPSILON || error("lower boundary ratio drift")
        elseif status == "boundary_upper"
            _float(fits[2]["profile_ratio"]) == 1.0 &&
                _float(fits[2]["numerical_ratio"]) == (1-BOUNDARY_EPSILON) || error("upper boundary ratio drift")
        end
    end
    nothing
end

function run_mode_boundary(args)
    outdir = abspath(_breq(args, "out-dir")); settings = _candidate_settings(outdir)
    manifest = _manifest(outdir)
    cell_id = String(_breq(args, "cell")); seed = parse(Int, _breq(args, "seed"))
    haskey(manifest, (cell_id, seed)) || error("dataset is absent from frozen holdout manifest")
    cell = manifest[(cell_id, seed)].cell
    final = joinpath(outdir, "packets", cell.id, string(seed))
    claim=final*".claim"
    manifest_sha = settings["holdout_manifest_sha256"]
    settings["candidate_seal_sha256"] = _sha256_file(joinpath(outdir, "candidate_seal.tsv"))
    if isdir(final)
        isfile(claim) || error("sealed packet is missing its create-once claim")
        _validate_attempt_ledger(outdir,settings,cell,seed)
        _validate_packet(final, settings, manifest_sha;expected=manifest[(cell_id,seed)])
        println("resume: sealed packet $(cell.id)/$(seed)")
        return
    end
    attempt=_attempt_path(outdir,cell.id,seed)
    ispath(claim) && error("prior failed/interrupted packet claim is immutable")
    if ispath(attempt) || ispath(attempt*".sha256")
        _validate_attempt_ledger(outdir,settings,cell,seed)
        error("prior failed/interrupted attempt is immutable and cannot be replaced")
    end
    _write_table_create_once(attempt,ATTEMPT_COLUMNS,_attempt_row(settings,cell,seed))
    _write_sidecar_create_once(attempt)
    _claim_directory_create_once(final)
    # An interrupted attempt may leave only an unsealed temporary sibling.
    # It is safe to discard because the candidate, seed, and code are already
    # sealed and the retry cannot adapt to the unseen partial values.
    parent = dirname(final)
    if isdir(parent)
        for name in readdir(parent)
            startswith(name, basename(final) * ".tmp.") && rm(joinpath(parent, name); recursive=true)
        end
    end
    _warm_boundary_timing()
    data = _fresh_dataset(settings,manifest,cell,seed)
    precision_hash = HSquared._genomic_matrix_fingerprint("Q_lambda", Matrix(data.Q), data.ids)
    spec = animal_model_spec(data.y, data.X, sparse(1.0I, cell.n, cell.n), data.Q;
                             ids=data.ids, method=:REML)
    provenance = (relationship_source="markers", id_order_fingerprint=data.id_hash,
                  precision_fingerprint=HSquared._genomic_matrix_fingerprint("Q_lambda", Matrix(data.Q), data.ids),
                  kernel_fingerprint=data.kernel_hash)
    timed_order=_timed_order(seed)
    timed_attempt(f)=begin
        started=time_ns()
        try
            value=f(); (result=value,runtime=(time_ns()-started)/1e9,error_class="none")
        catch err
            msg=replace(first(split(sprint(showerror,err),'\n')),r"[\t\r\n]"=>" ")
            (result=nothing,runtime=(time_ns()-started)/1e9,
             error_class=string(nameof(typeof(err)),":",msg))
        end
    end
    if isodd(seed)
        default_attempt=timed_attempt(() -> fit_ai_reml(spec))
        candidate_attempt=timed_attempt(() -> HSquared._fit_ai_reml_genomic_boundary(spec; provenance=provenance,kernel=data.K))
    else
        candidate_attempt=timed_attempt(() -> HSquared._fit_ai_reml_genomic_boundary(spec; provenance=provenance,kernel=data.K))
        default_attempt=timed_attempt(() -> fit_ai_reml(spec))
    end
    hashes = (marker_hash=data.marker_hash, id_hash=data.id_hash,
              kernel_hash=data.kernel_hash, precision_hash=precision_hash)
    fitrows = [_fit_row(cell,seed,"default_ai",timed_order,default_attempt.result,
                        default_attempt.runtime,hashes;error_class=default_attempt.error_class),
               _fit_row(cell,seed,"boundary_candidate",timed_order,candidate_attempt.result,
                        candidate_attempt.runtime,hashes;error_class=candidate_attempt.error_class)]
    tmp = final * ".tmp.$(getpid())"
    ispath(tmp) && error("stale packet temporary directory")
    mkpath(tmp)
    try
        _write_table_exclusive(joinpath(tmp, "y.tsv"), ["row", "y"], [[i, data.y[i]] for i in eachindex(data.y)])
        _write_table_exclusive(joinpath(tmp, "ids.tsv"), ["row", "id"], [[i, data.ids[i]] for i in eachindex(data.ids)])
        _write_matrix(joinpath(tmp, "X.tsv"), data.X, "x")
        _write_matrix(joinpath(tmp, "K.tsv"), data.K, "k")
        _write_matrix(joinpath(tmp, "Q.tsv"), data.Q, "q")
        _write_table_exclusive(joinpath(tmp, "fits.tsv"), FIT_COLUMNS, fitrows)
        values = [BOUNDARY_SCHEMA, BOUNDARY_CANDIDATE, cell.id, seed, cell.n, size(data.X,2), cell.m,
                  RIDGE, data.marker_hash, data.id_hash, data.kernel_hash, precision_hash,
                  "markers", "vanraden1", "sample", "K_lambda",
                  DOC46_COMMIT, DOC46_SHA256, DOC47_COMMIT, DOC47_SHA256,
                  JULIA_BOUNDARY_IMPL_COMMIT, R_BOUNDARY_IMPL_COMMIT, DISCOVERY_DIGEST,
                  DISCOVERY_EQUIVALENCE_SHA256, DISCOVERY_TIMING_SHA256, DISCOVERY_SELECTION_SHA256,
                  settings["candidate_seal_sha256"], manifest_sha,
                  settings["execution_commit"], settings["boundary_driver_sha256"], settings["r_oracle_sha256"]]
        length(values)==length(BOUNDARY_METADATA_KEYS) || error("packet metadata value-count drift")
        _write_table_exclusive(joinpath(tmp, "metadata.tsv"), ["key", "value"], [[k,v] for (k,v) in zip(BOUNDARY_METADATA_KEYS, values)])
        for name in PACKET_FILES
            _write_sidecar_create_once(joinpath(tmp,name))
        end
        lockrows = [[name, _sha256_file(joinpath(tmp, name))] for name in PACKET_FILES]
        _write_table_exclusive(joinpath(tmp, "files.sha256.tsv"), ["relative_path", "sha256"], lockrows)
        _write_sidecar_create_once(joinpath(tmp,"files.sha256.tsv"))
        ispath(final) && error("claimed packet destination was materialized unexpectedly")
        mkpath(dirname(final)); mv(tmp, final; force=false)
    catch
        isdir(tmp) && rm(tmp; recursive=true)
        rethrow()
    end
    _validate_packet(final, settings, manifest_sha;expected=manifest[(cell_id,seed)])
    println("sealed packet $(cell.id)/$(seed)")
end

function _oracle_path(outdir, cell, seed)
    joinpath(outdir, "oracle", cell, "$(seed).tsv")
end

function _assert_oracle_bindings(actual,expected)
    Set(keys(expected))==Set(ORACLE_BINDING_COLUMNS) || error("internal oracle binding schema drift")
    for key in ORACLE_BINDING_COLUMNS
        actual[key]==expected[key] || error("oracle cross-binding drift: $(key)")
    end
    nothing
end

function _read_oracle(outdir, cell, seed, settings, packet, fits)
    path = _oracle_path(outdir, cell, seed)
    _validate_sidecar(path)
    rows = _read_table(path, ORACLE_COLUMNS)
    length(rows) == 1 || error("oracle row-count drift")
    d = Dict(String(k) => String(v) for (k,v) in zip(ORACLE_COLUMNS, only(rows)))
    d["cell_id"] == cell && parse(Int, d["seed"]) == seed || error("oracle identity drift")
    d["oracle_class"] in ("interior_oracle", "boundary_lower", "boundary_upper", "oracle_unresolved") || error("oracle class drift")
    metadata=_read_table(joinpath(packet,"metadata.tsv"),["key","value"])
    [String(r[1]) for r in metadata]==BOUNDARY_METADATA_KEYS || error("oracle packet metadata key drift")
    md=Dict(String(r[1])=>String(r[2]) for r in metadata)
    expected=Dict(
        "packet_files_lock_sha256"=>_sha256_file(joinpath(packet,"files.sha256.tsv")),
        "candidate_seal_sha256"=>settings["candidate_seal_sha256"],
        "candidate_id"=>BOUNDARY_CANDIDATE,
        "doc46_commit"=>DOC46_COMMIT,"doc46_sha256"=>DOC46_SHA256,
        "doc47_commit"=>DOC47_COMMIT,"doc47_sha256"=>DOC47_SHA256,
        "julia_boundary_impl_commit"=>JULIA_BOUNDARY_IMPL_COMMIT,
        "r_boundary_impl_commit"=>R_BOUNDARY_IMPL_COMMIT,
        "r_oracle_sha256"=>R_ORACLE_SHA256,
        "marker_hash"=>md["marker_hash"],"id_hash"=>md["id_hash"],
        "kernel_hash"=>md["kernel_hash"],"precision_hash"=>md["precision_hash"],
        "default_result_digest"=>fits[1]["result_digest"],
        "candidate_result_digest"=>fits[2]["result_digest"])
    _assert_oracle_bindings(d,expected)
    d
end

function _fit_dict(row)
    Dict(String(k) => String(v) for (k,v) in zip(FIT_COLUMNS, row))
end

function _interior_valid(fit, oracle, n)
    oracle["oracle_class"] == "interior_oracle" || return false
    _bool_token(fit["converged"]) || return false
    fit["boundary_status"] in ("interior", "interior_rescued", "not_classified") || return false
    sg = _float(fit["sigma_g2"]); se = _float(fit["sigma_e2"])
    osg = _float(oracle["oracle_sigma_g2_numerical"]); ose = _float(oracle["oracle_sigma_e2_numerical"])
    ratio = _float(fit["numerical_ratio"]); oratio = _float(oracle["oracle_profile_ratio"])
    profile_ok = fit["boundary_status"] == "not_classified" ||
        (abs(_float(fit["profile_ratio"])-oratio) <= 1e-8 + 1e-5abs(oratio) &&
         abs(_float(fit["profile_loglik"])-_float(oracle["oracle_profile_loglik"]))/n <= 1e-8)
    profile_ok && abs(sg-osg) <= 1e-8 + 1e-5abs(osg) && abs(se-ose) <= 1e-8 + 1e-5abs(ose) &&
        abs(ratio-oratio) <= 1e-8 + 1e-5abs(oratio) &&
        abs(_float(fit["objective"])-_float(oracle["oracle_profile_loglik"]))/n <= 1e-8 &&
        _float(fit["fd_log_gradient_norm"]) <= 1e-8
end

function _candidate_valid(candidate, oracle, n)
    cls = oracle["oracle_class"]
    cls == "oracle_unresolved" && return false
    status = candidate["boundary_status"]
    if cls == "interior_oracle"
        return status in ("interior", "interior_rescued") && _interior_valid(candidate, oracle, n)
    end
    status == cls || return false
    _bool_token(candidate["converged"]) || return false
    ratio = _float(candidate["profile_ratio"]); expected_ratio = cls == "boundary_lower" ? 0.0 : 1.0
    ratio == expected_ratio || return false
    expected_numerical = cls == "boundary_lower" ? BOUNDARY_EPSILON : 1-BOUNDARY_EPSILON
    _float(candidate["numerical_ratio"]) == expected_numerical || return false
    ot = _float(oracle["oracle_t_hat"]); ct = _float(candidate["profile_t_hat"])
    osg = _float(oracle["oracle_sigma_g2_numerical"]); ose = _float(oracle["oracle_sigma_e2_numerical"])
    sg = _float(candidate["sigma_g2"]); se = _float(candidate["sigma_e2"])
    tol(x) = 1e-8 + 1e-7abs(x)
    abs(ct-ot) <= tol(ot) && abs(sg-osg) <= tol(osg) && abs(se-ose) <= tol(ose) &&
        abs(_float(candidate["lower_derivative_per_observation"])-_float(oracle["oracle_lower_derivative_per_observation"])) <= 1e-8 &&
        abs(_float(candidate["upper_derivative_per_observation"])-_float(oracle["oracle_upper_derivative_per_observation"])) <= 1e-8 &&
        abs(_float(candidate["profile_loglik"])-_float(oracle["oracle_profile_loglik"]))/n <= 1e-8
end

function _p95_by_cell(rows, column)
    result = Dict{String,Float64}()
    for cell in CELLS
        x = [_float(r[column]) for r in rows if r["cell_id"] == cell.id]
        length(x) == 48 || error("runtime denominator drift")
        result[cell.id] = _p95(x)
    end
    result
end

_runtime_gate(default_values,candidate_values)=length(default_values)==48 &&
    length(candidate_values)==48 && all(x->isfinite(x)&&x>=0,default_values) &&
    all(x->isfinite(x)&&x>=0,candidate_values) && _p95(candidate_values)<=3*_p95(default_values)

function _write_or_validate_summary(outdir,tables)
    summary_dir=joinpath(outdir,"summary")
    claim=summary_dir*".claim"
    names=[first(t) for t in tables]
    expected_actual=sort(vcat(names,[n*".sha256" for n in names],
        ["files.sha256.tsv","files.sha256.tsv.sha256"]))
    if isdir(summary_dir)
        isfile(claim) || error("summary is missing its create-once claim")
        sort(readdir(summary_dir))==expected_actual || error("stale/partial summary file set")
        for (name,columns,rows) in tables
            path=joinpath(summary_dir,name); _validate_sidecar(path)
            read(path)==_table_bytes(columns,rows) || error("stale summary semantic drift: $(name)")
        end
        lock=joinpath(summary_dir,"files.sha256.tsv"); _validate_sidecar(lock)
        expected_lock=[[name,_sha256_file(joinpath(summary_dir,name))] for name in names]
        read(lock)==_table_bytes(["relative_path","sha256"],expected_lock) || error("summary lock drift")
        return :validated
    end
    ispath(claim) && error("prior failed/interrupted summary claim is immutable")
    _claim_directory_create_once(summary_dir)
    staging=summary_dir*".tmp.$(getpid())"
    ispath(staging) && error("stale summary staging directory")
    mkpath(staging)
    try
        for (name,columns,rows) in tables
            path=joinpath(staging,name)
            _write_table_create_once(path,columns,rows); _write_sidecar_create_once(path)
        end
        lock=joinpath(staging,"files.sha256.tsv")
        _write_table_create_once(lock,["relative_path","sha256"],
            [[name,_sha256_file(joinpath(staging,name))] for name in names])
        _write_sidecar_create_once(lock)
        ispath(summary_dir) && error("claimed summary destination was materialized unexpectedly")
        mv(staging,summary_dir;force=false)
    catch
        isdir(staging) && rm(staging;recursive=true)
        rethrow()
    end
    :written
end

function summarize_mode_boundary(args)
    outdir = abspath(_breq(args, "out-dir")); settings = _candidate_settings(outdir)
    manifest = _manifest(outdir); _assert_exact_campaign_sets(outdir,manifest)
    details = Vector{Vector{Any}}(); runtime_rows = Dict{String,String}[]
    cell_interior = Dict(c.id => Bool[] for c in CELLS)
    W = 0; L = 0; unresolved = 0; status_errors = 0; unchanged_errors = 0
    for ((cell_id, seed), entry) in sort(collect(manifest); by=x -> x[1])
        packet = joinpath(outdir, "packets", cell_id, string(seed))
        settings["candidate_seal_sha256"] = _sha256_file(joinpath(outdir, "candidate_seal.tsv"))
        _validate_attempt_ledger(outdir,settings,entry.cell,seed)
        _validate_packet(packet,settings,settings["holdout_manifest_sha256"];expected=entry)
        fitrows = _read_table(joinpath(packet, "fits.tsv"), FIT_COLUMNS)
        default = _fit_dict(fitrows[1]); candidate = _fit_dict(fitrows[2]);
        oracle = _read_oracle(outdir, cell_id, seed, settings, packet, (default,candidate))
        n = entry.cell.n; dv = _interior_valid(default, oracle, n); cv = _candidate_valid(candidate, oracle, n)
        oracle["oracle_class"] == "oracle_unresolved" && (unresolved += 1)
        !cv && (status_errors += 1)
        if oracle["oracle_class"] == "interior_oracle"
            push!(cell_interior[cell_id], cv)
            if dv && candidate["boundary_status"] in ("interior","interior_rescued")
                abs(_float(candidate["sigma_g2"])-_float(default["sigma_g2"])) <= 1e-10 &&
                abs(_float(candidate["sigma_e2"])-_float(default["sigma_e2"])) <= 1e-10 || (unchanged_errors += 1)
            end
        end
        win = cv && !dv; loss = dv && !cv; W += win; L += loss
        push!(details, Any[cell_id, seed, oracle["oracle_class"], default["boundary_status"], candidate["boundary_status"], dv, cv, win, loss])
        push!(runtime_rows, Dict("cell_id"=>cell_id, "default"=>default["runtime_seconds"], "candidate"=>candidate["runtime_seconds"]))
    end
    length(details) == 240 || error("summary denominator drift")
    discord = W + L; cp = discord == 0 ? 0.0 : _cp_lower(W, discord)
    rates_ok = all(!isempty(v) && count(identity, v)/length(v) >= 0.95 for v in values(cell_interior))
    default_p95 = _p95_by_cell(runtime_rows, "default"); candidate_p95 = _p95_by_cell(runtime_rows, "candidate")
    runtime_ok = all(begin
        d=[_float(r["default"]) for r in runtime_rows if r["cell_id"]==c.id]
        q=[_float(r["candidate"]) for r in runtime_rows if r["cell_id"]==c.id]
        _runtime_gate(d,q)
    end for c in CELLS)
    timing_rows = [[c.id,48,default_p95[c.id],candidate_p95[c.id],
                    candidate_p95[c.id]/default_p95[c.id],candidate_p95[c.id]<=3default_p95[c.id]]
                   for c in CELLS]
    pass = unresolved == 0 && status_errors == 0 && unchanged_errors == 0 && L == 0 && discord > 0 && cp > 0.5 && rates_ok && runtime_ok
    pair_columns=split("cell_id seed oracle_class default_status candidate_status default_valid candidate_valid win loss")
    timing_columns=split("cell_id n_datasets default_p95_seconds candidate_p95_seconds candidate_default_ratio pass")
    gate_columns=split("outcome attempted wins losses discordant cp_lower net_gain unresolved candidate_invalid unchanged_interior_errors rates_ok runtime_ok")
    gate_rows=[[pass ? "PASS" : "FAIL",240,W,L,discord,cp,(W-L)/240,unresolved,status_errors,unchanged_errors,rates_ok,runtime_ok]]
    state=_write_or_validate_summary(outdir,[
        ("holdout_pairs.tsv",pair_columns,details),
        ("holdout_timing.tsv",timing_columns,timing_rows),
        ("holdout_gate.tsv",gate_columns,gate_rows)])
    println(state==:validated ? (pass ? "resume: BOUNDARY_HOLDOUT_PASS" : "resume: BOUNDARY_HOLDOUT_FAIL") :
        (pass ? "BOUNDARY_HOLDOUT_PASS" : "BOUNDARY_HOLDOUT_FAIL"))
end

function _must_fail_boundary(label, f)
    failed = false
    try f() catch; failed = true end
    failed || error("negative control stayed green: $(label)")
end

function selftest_mode_boundary()
    _assert_fresh_seed_contract()
    length(_holdout_manifest_rows()) == 240 || error("holdout denominator drift")
    length(unique((r[1], r[2]) for r in _holdout_manifest_rows())) == 240 || error("duplicate holdout seed")
    all(_hex40, (DOC46_COMMIT,DOC47_COMMIT,JULIA_BOUNDARY_IMPL_COMMIT,R_BOUNDARY_IMPL_COMMIT)) ||
        error("commit width drift")
    all(_hex64, (DOC46_SHA256,DOC47_SHA256,DISCOVERY_MANIFEST_SHA256,
        DISCOVERY_ADMISSION_SHA256,DISCOVERY_ENVIRONMENT_SHA256,DISCOVERY_ADMISSION_LOCK_SHA256,
        DISCOVERY_RAW_LOCKS_SHA256,DISCOVERY_EQUIVALENCE_SHA256,DISCOVERY_TIMING_SHA256,
        DISCOVERY_SELECTION_SHA256,DISCOVERY_SUMMARY_LOCK_SHA256,DISCOVERY_DIGEST,
        DISCOVERY_DRIVER_SHA256,LOCALIZATION_DRIVER_SHA256,R_ORACLE_SHA256)) || error("digest width drift")
    rows = _holdout_manifest_rows(); bytes = _table_bytes(HOLDOUT_COLUMNS, rows)
    bytes2hex(sha256(bytes)) == _holdout_manifest_sha256() || error("manifest determinism drift")
    length(ORACLE_COLUMNS)==26 || error("cross-twin oracle schema width drift")
    _hex64(_exchange_schema_sha256()) || error("exchange schema digest drift")
    binding_fixture=Dict(k=>k for k in ORACLE_BINDING_COLUMNS)
    _assert_oracle_bindings(binding_fixture,binding_fixture)
    mutated_binding=copy(binding_fixture); mutated_binding["candidate_result_digest"]="mutated"
    _must_fail_boundary("oracle result-digest transplant") do
        _assert_oracle_bindings(mutated_binding,binding_fixture)
    end
    seal_fixture=[[k,"x"] for k in SEAL_KEYS]
    length(_parse_seal_rows(seal_fixture))==length(SEAL_KEYS) || error("valid seal keys rejected")
    reordered=copy(seal_fixture); reordered[1],reordered[2]=reordered[2],reordered[1]
    _must_fail_boundary("reordered seal keys") do
        _parse_seal_rows(reordered)
    end
    _must_fail_boundary("extra seal key") do
        _parse_seal_rows(vcat(seal_fixture,[["extra","x"]]))
    end
    duplicated=copy(seal_fixture); duplicated[2]=duplicated[1]
    _must_fail_boundary("duplicate seal key") do
        _parse_seal_rows(duplicated)
    end
    generated=Ref(false); fake_generator=(cell,seed)->(generated[]=true;:ok)
    _must_fail_boundary("pre-seal fresh generator tripwire") do
        _fresh_dataset(Dict{String,String}(),Dict{Tuple{String,Int},NamedTuple}(),CELLS[1],first(_fresh_holdout_seeds(CELLS[1]));generator=fake_generator)
    end
    !generated[] || error("pre-seal generator was invoked")
    fresh_seed=first(_fresh_holdout_seeds(CELLS[1]))
    fake_manifest=Dict((CELLS[1].id,fresh_seed)=>(cell=CELLS[1],seed=fresh_seed))
    _fresh_dataset(Dict("holdout_absent_before_seal"=>"true","spent_offset_block_excluded"=>"5001:5048"),
        fake_manifest,CELLS[1],fresh_seed;generator=fake_generator)==:ok || error("sealed generator rejected")
    generated[] || error("sealed generator was not invoked")
    _p95(collect(1.0:48.0))==46.0 || error("p95 index drift")
    _runtime_gate(fill(1.0,48),fill(3.0,48)) || error("runtime equality boundary rejected")
    _runtime_gate(fill(1.0,48),vcat(fill(1.0,45),fill(3.0001,3))) && error("slow p95 mutation stayed green")
    _runtime_gate(fill(1.0,48),vcat(fill(1.0,47),[-1.0])) && error("negative timing stayed green")
    _runtime_gate(fill(1.0,48),vcat(fill(1.0,47),[NaN])) && error("nonfinite timing stayed green")
    _timed_order(fresh_seed)=="default_ai>boundary_candidate" || error("odd-seed order parity drift")
    _timed_order(fresh_seed+1)=="boundary_candidate>default_ai" || error("even-seed order parity drift")
    failed=Dict{String,String}("error_class"=>"ErrorException:synthetic",
        "termination_reason"=>"ErrorException:synthetic","optimizer_status"=>"exception",
        "boundary_status"=>"exception","converged"=>"false")
    for field in FAILED_SCIENTIFIC_FIELDS; failed[field]="NaN"; end
    _validate_failed_fit_row(failed)
    for field in ("lower_derivative_per_observation","upper_derivative_per_observation")
        mutated=copy(failed); mutated[field]="0"
        _must_fail_boundary("failed-row retained $(field)") do
            _validate_failed_fit_row(mutated)
        end
    end
    mutated_reason=copy(failed); mutated_reason["termination_reason"]="different"
    _must_fail_boundary("failed-row reason mutation") do
        _validate_failed_fit_row(mutated_reason)
    end
    default_status=Dict("error_class"=>"none","route"=>"default_ai",
        "boundary_status"=>"not_classified","optimizer_status"=>"converged",
        "termination_reason"=>"converged","converged"=>"true")
    _validate_fit_status_contract(default_status)
    mutated_default=copy(default_status); mutated_default["termination_reason"]="mutated"
    _must_fail_boundary("default termination mutation") do
        _validate_fit_status_contract(mutated_default)
    end
    candidate_status=Dict("error_class"=>"none","route"=>"boundary_candidate",
        "boundary_status"=>"boundary_lower","optimizer_status"=>"boundary_lower",
        "termination_reason"=>"boundary_lower","converged"=>"true")
    _validate_fit_status_contract(candidate_status)
    for field in ("termination_reason","optimizer_status")
        mutated=copy(candidate_status); mutated[field]="mutated"
        _must_fail_boundary("resolved candidate $(field) mutation") do
            _validate_fit_status_contract(mutated)
        end
    end
    oracle = Dict("oracle_class"=>"boundary_lower", "oracle_profile_ratio"=>"0", "oracle_t_hat"=>"2",
        "oracle_profile_loglik"=>"-10", "oracle_lower_derivative_per_observation"=>"-0.1",
        "oracle_upper_derivative_per_observation"=>"-0.2", "oracle_sigma_g2_numerical"=>"2e-7",
        "oracle_sigma_e2_numerical"=>"1.9999998")
    candidate = Dict("boundary_status"=>"boundary_lower", "converged"=>"true", "profile_ratio"=>"0",
        "numerical_ratio"=>"1e-7", "profile_t_hat"=>"2", "sigma_g2"=>"2e-7", "sigma_e2"=>"1.9999998",
        "lower_derivative_per_observation"=>"-0.1", "upper_derivative_per_observation"=>"-0.2",
        "profile_loglik"=>"-10")
    _candidate_valid(candidate, oracle, 120) || error("valid boundary rejected")
    for (field, value) in (("boundary_status","boundary_upper"), ("profile_ratio","1"),
                           ("lower_derivative_per_observation","0.1"), ("profile_t_hat","2.1"),
                           ("profile_loglik","-10.1"))
        mutated = copy(candidate); mutated[field] = value
        _candidate_valid(mutated, oracle, 120) && error("mutation stayed green: $(field)")
    end
    for adjacent in (prevfloat(BOUNDARY_EPSILON),nextfloat(BOUNDARY_EPSILON))
        mutated=copy(candidate); mutated["numerical_ratio"]=@sprintf("%.17g",adjacent)
        _candidate_valid(mutated,oracle,120) && error("adjacent lower endpoint stayed green")
    end
    upper_oracle=copy(oracle); upper_oracle["oracle_class"]="boundary_upper";
    upper_oracle["oracle_profile_ratio"]="1"; upper_oracle["oracle_sigma_g2_numerical"]="1.9999998";
    upper_oracle["oracle_sigma_e2_numerical"]="2e-7"
    upper=copy(candidate); upper["boundary_status"]="boundary_upper"; upper["profile_ratio"]="1";
    upper["numerical_ratio"]=@sprintf("%.17g",1-BOUNDARY_EPSILON);
    upper["sigma_g2"]="1.9999998"; upper["sigma_e2"]="2e-7"
    _candidate_valid(upper,upper_oracle,120) || error("valid upper boundary rejected")
    for adjacent in (prevfloat(1-BOUNDARY_EPSILON),nextfloat(1-BOUNDARY_EPSILON))
        mutated=copy(upper); mutated["numerical_ratio"]=@sprintf("%.17g",adjacent)
        _candidate_valid(mutated,upper_oracle,120) && error("adjacent upper endpoint stayed green")
    end
    mock_hashes=(marker_hash=repeat("1",64),id_hash=repeat("2",64),
        kernel_hash=repeat("3",64),precision_hash=repeat("4",64))
    lower_total=1.2178803835870546
    lower_fit=(variance_components=(sigma_a2=BOUNDARY_EPSILON*lower_total,
        sigma_e2=(1-BOUNDARY_EPSILON)*lower_total),converged=true,
        optimizer_status="boundary_lower")
    lower_boundary=(status="boundary_lower",reason="boundary_lower",profile_ratio=0.0,
        numerical_ratio=BOUNDARY_EPSILON,profile_loglik=-1.0,
        lower_derivative_per_observation=-0.1,upper_derivative_per_observation=-0.2)
    lower_record=_result_record_holdout("boundary_candidate",(fit=lower_fit,boundary=lower_boundary),mock_hashes)
    lower_record["numerical_ratio"]==@sprintf("%.17g",BOUNDARY_EPSILON) ||
        error("canonical lower serialization drift")
    derived_lower=lower_fit.variance_components.sigma_a2/
        (lower_fit.variance_components.sigma_a2+lower_fit.variance_components.sigma_e2)
    derived_lower!=BOUNDARY_EPSILON || error("lower roundoff fixture collapsed")
    mutated_record=copy(lower_record); mutated_record["numerical_ratio"]=@sprintf("%.17g",derived_lower)
    _result_digest(mutated_record)!=lower_record["result_digest"] ||
        error("component-derived lower result digest stayed green")
    upper_total=1.0597902687089635
    upper_fit=(variance_components=(sigma_a2=(1-BOUNDARY_EPSILON)*upper_total,
        sigma_e2=BOUNDARY_EPSILON*upper_total),converged=true,optimizer_status="boundary_upper")
    upper_boundary=(status="boundary_upper",reason="boundary_upper",profile_ratio=1.0,
        numerical_ratio=1-BOUNDARY_EPSILON,profile_loglik=-1.0,
        lower_derivative_per_observation=0.1,upper_derivative_per_observation=0.2)
    upper_record=_result_record_holdout("boundary_candidate",(fit=upper_fit,boundary=upper_boundary),mock_hashes)
    upper_record["numerical_ratio"]==@sprintf("%.17g",1-BOUNDARY_EPSILON) ||
        error("canonical upper serialization drift")
    derived_upper=upper_fit.variance_components.sigma_a2/
        (upper_fit.variance_components.sigma_a2+upper_fit.variance_components.sigma_e2)
    derived_upper!=(1-BOUNDARY_EPSILON) || error("upper roundoff fixture collapsed")
    mutated_record=copy(upper_record); mutated_record["numerical_ratio"]=@sprintf("%.17g",derived_upper)
    _result_digest(mutated_record)!=upper_record["result_digest"] ||
        error("component-derived upper result digest stayed green")
    K=[1.1 0.2;0.2 0.9]; Q=inv(K)
    _qk_identity_ok(K,Q) || error("valid Q*K identity rejected")
    Qbad=copy(Q); Qbad[1,1]+=2QK_IDENTITY_TOL
    _qk_identity_ok(K,Qbad) && error("Q*K tolerance mutation stayed green")
    ids=["a","b"]
    HSquared._genomic_id_order_fingerprint(ids)!=HSquared._genomic_id_order_fingerprint(reverse(ids)) ||
        error("ID-order mutation stayed green")
    HSquared._genomic_matrix_fingerprint("K_lambda",K,ids)!=
        HSquared._genomic_matrix_fingerprint("K_lambda",K[[2,1],[2,1]],reverse(ids)) ||
        error("matrix/order mutation stayed green")
    warm_ids=["warm$(i)" for i in 1:7]; warm_Q=Matrix{Float64}(I,7,7); warm_K=copy(warm_Q)
    warm_y=[-1.3,0.2,0.9,-0.4,1.7,-0.8,0.5]; warm_X=ones(7,1)
    warm_spec=animal_model_spec(warm_y,warm_X,sparse(1.0I,7,7),warm_Q;ids=warm_ids,method=:REML)
    warm_hashes=(marker_hash=repeat("a",64),
        id_hash=HSquared._genomic_id_order_fingerprint(warm_ids),
        kernel_hash=HSquared._genomic_matrix_fingerprint("K_lambda",warm_K,warm_ids),
        precision_hash=HSquared._genomic_matrix_fingerprint("Q_lambda",warm_Q,warm_ids))
    warm_provenance=(relationship_source="markers",id_order_fingerprint=warm_hashes.id_hash,
        precision_fingerprint=warm_hashes.precision_hash,kernel_fingerprint=warm_hashes.kernel_hash)
    warm_default=fit_ai_reml(warm_spec)
    warm_candidate=HSquared._fit_ai_reml_genomic_boundary(warm_spec;provenance=warm_provenance,kernel=warm_K)
    warm_cell=(id="warm",)
    warm_rows=[_fit_row(warm_cell,0,"default_ai",_timed_order(0),warm_default,0.1,warm_hashes),
        _fit_row(warm_cell,0,"boundary_candidate",_timed_order(0),warm_candidate,0.2,warm_hashes)]
    all(length(r)==length(FIT_COLUMNS) for r in warm_rows) || error("v2 fit row width drift")
    all(begin f=_fit_dict(string.(r)); _digest_record_from_fit(f)==f["result_digest"] end for r in warm_rows) ||
        error("v2 fit row digest is not reflexive")
    mktempdir() do dir
        _must_fail_boundary("holdout before seal") do
            _candidate_settings(dir)
        end
        mkpath(joinpath(dir, "packets"))
        _must_fail_boundary("pre-existing holdout at seal") do
            _assert_no_holdout(dir,_driver_root())
        end
        path=joinpath(dir,"create-once.tsv")
        _write_table_create_once(path,["x"],[[1]])
        _must_fail_boundary("create-once overwrite") do
            _write_table_create_once(path,["x"],[[2]])
        end
        target=joinpath(dir,"symlink-target"); mkpath(target)
        linked=joinpath(dir,"symlink-output"); symlink(target,linked)
        _must_fail_boundary("existing output symlink aliases study root") do
            _assert_isolated_roots(linked,target)
        end
        campaign=joinpath(dir,"campaign")
        synthetic_manifest=Dict((CELLS[1].id,fresh_seed)=>(cell=CELLS[1],seed=fresh_seed))
        attempt_path=_attempt_path(campaign,CELLS[1].id,fresh_seed)
        _write_table_create_once(attempt_path,["x"],[[1]]); _write_sidecar_create_once(attempt_path)
        packet_path=joinpath(campaign,"packets",CELLS[1].id,string(fresh_seed))
        _claim_directory_create_once(packet_path); mkpath(packet_path)
        oracle_path=_oracle_path(campaign,CELLS[1].id,fresh_seed)
        _write_table_create_once(oracle_path,["x"],[[1]]); _write_sidecar_create_once(oracle_path)
        _assert_exact_campaign_sets(campaign,synthetic_manifest)
        _write_bytes_create_once(oracle_path*".orphan",codeunits("orphan\n"))
        _must_fail_boundary("orphan oracle sidecar/extra file") do
            _assert_exact_campaign_sets(campaign,synthetic_manifest)
        end
        summary_root=joinpath(dir,"summary-test")
        tables=[("holdout_pairs.tsv",["x"],[[1]]),("holdout_timing.tsv",["x"],[[2]]),
            ("holdout_gate.tsv",["x"],[[3]])]
        _write_or_validate_summary(summary_root,tables)==:written || error("summary atomic write failed")
        _write_or_validate_summary(summary_root,tables)==:validated || error("summary recomputation failed")
        open(joinpath(summary_root,"summary","holdout_gate.tsv"),"a") do io; write(io,"4\n"); end
        _must_fail_boundary("stale summary reuse") do
            _write_or_validate_summary(summary_root,tables)
        end
    end
    println("boundary holdout selftest: PASS")
end

function main_boundary(args=ARGS)
    mode = String(_bopt(args, "mode", "selftest"))
    mode == "seal" ? seal_mode(args) :
    mode == "manifest" ? manifest_mode(args) :
    mode == "run" ? run_mode_boundary(args) :
    mode == "summarize" ? summarize_mode_boundary(args) :
    mode == "selftest" ? selftest_mode_boundary() :
    error("mode must be seal, manifest, run, summarize, or selftest")
end

abspath(PROGRAM_FILE) == abspath(@__FILE__) && main_boundary()
