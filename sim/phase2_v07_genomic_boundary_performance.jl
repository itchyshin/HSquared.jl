#!/usr/bin/env julia

using HSquared
using LinearAlgebra
using Optim
using Printf
using SHA
using SparseArrays
using Statistics

# Doc 47 discovery-only performance profiler. This program has no seed generator
# and accepts only the already-open, hash-bound doc-45 discovery corpus. The
# fresh and spent validation corpora are deliberately outside its vocabulary.

const DOC47_PATH = "docs/design/47-v07-genomic-boundary-performance.md"
const DOC47_COMMIT = "457b6baf31951071f9bf7fd153fb3544eb4b227a"
const DOC47_SHA256 = "eea5d7904c66f9e0210668327d9f638a8dd8b3b5975afdf410fe383d7a433ed2"
const DOC47_AMENDMENT_COMMIT = "f6ef321f474fd3d4b9aa5597f9edb58516703fc6"
const DOC47_AMENDMENT_SHA256 = "ebfad48378a646708873e7e5041c68a3ec77b495ffb36bf426c2fb575bddde1f"
const REFERENCE_COMMIT = "ecc058f380be71058c9cfde373c345ab7a2f6aba"
const CANDIDATE_ID = "doc47_boundary_performance_v1"
const SCHEMA_VERSION = "v07-genomic-boundary-performance-v1"
const DISCOVERY_MANIFEST_SHA256 = "c1f5e1a284ed815a4457ac214372fb37382ade07fef3eb4abce331343bdd820a"
const DISCOVERY_ENVIRONMENT_SHA256 = "e8fa53cc1f8eed96a029ad01f6602eb24e9a299d4105f6771eae5a6d010361d0"
const DISCOVERY_CANDIDATE_SEAL_SHA256 = "8a25266b4a89d26e7f26d060efb577c34c1af125c936e39d00175d4b7cb5a12a"
const DISCOVERY_DIGEST = "33c31a474fc2f0e996d3bd6489a53d055cc753727b69f0625fc30811777c7caf"
const RIDGE = 0.01
const REPEATS = 5

const CELLS = [
    (id="n120_m600_r020", n=120, m=600, datasets=24, controls=12),
    (id="n120_m600_r050", n=120, m=600, datasets=4, controls=2),
    (id="n120_m600_r080", n=120, m=600, datasets=16, controls=8),
    (id="n300_m1000_r020", n=300, m=1000, datasets=12, controls=6),
    (id="n300_m1000_r080", n=300, m=1000, datasets=2, controls=1),
]

const IMPLEMENTATIONS = ["default_ai", "reference_boundary", "candidate_boundary"]
const COMPONENTS = [
    "precheck", "ai_fit", "q_to_k", "eigendecomposition", "rotation",
    "grid_401", "refinement", "endpoint_derivatives", "classification",
    "interior_validation_fd", "final_likelihood_and_result_assembly",
    "candidate_total",
]

const MANIFEST_COLUMNS = split("phase cell_id seed role arm_id cap em_warmup start_id n m ridge marker_hash id_hash kernel_hash")
const METADATA_KEYS = split("schema_version phase cell_id seed role n p m ridge marker_hash id_hash kernel_hash doc45_commit doc45_sha256 doc45a_commit doc45a_sha256 doc45b_commit doc45b_sha256 execution_commit")
const PACKET_FILES = ["K.tsv", "X.tsv", "arms.tsv", "metadata.tsv", "y.tsv"]
const RAW_COLUMNS = split("phase cell_id seed role arm_id cap em_warmup start_id start_sigma_g2 start_sigma_e2 converged termination_reason iterations em_steps factorizations step_halvings estimate_sigma_g2 estimate_sigma_e2 estimate_ratio julia_objective ai_score_norm julia_fd_log_gradient_norm last_relative_change smallest_component runtime_seconds peak_rss_mb error_class marker_hash id_hash kernel_hash")
const ORACLE_COLUMNS = vcat(RAW_COLUMNS, split("oracle_class oracle_ratio oracle_sigma_g2 oracle_sigma_e2 oracle_arm_loglik oracle_loglik objective_gap_per_observation oracle_fd_log_gradient_norm lower_derivative_per_observation upper_derivative_per_observation interior_agreement dataset_files_digest"))

const ADMISSION_COLUMNS = split("schema_version cell_id seed role n m marker_hash id_hash kernel_hash precision_hash packet_files_digest oracle_sha256 oracle_class")
const SELECTION_COLUMNS = split("schema_version cell_id seed role repeat_id order_index timed_order implementation_id elapsed_ns allocated_bytes gc_time_ns marker_hash id_hash kernel_hash precision_hash result_digest error_class")
const COMPONENT_COLUMNS = split("schema_version cell_id seed role implementation_id repeat_id timed_order component backend call_count elapsed_ns allocated_bytes gc_time_ns marker_hash id_hash kernel_hash precision_hash result_digest error_class")
const RESULT_FIELDS = split("digest_version status reason converged termination profile_ratio numerical_ratio t_hat profile_loglik d0 d1 sigma_g2 sigma_e2 marker_hash id_hash kernel_hash precision_hash relationship_source relationship_method allele_frequency_source ridge relationship_scale")
const RESULT_COLUMNS = vcat(RESULT_FIELDS, ["result_digest"])
const EQUIVALENCE_COLUMNS = split("schema_version cell_id seed role marker_hash id_hash kernel_hash oracle_class reference_precision_hash candidate_precision_hash reference_relationship_source candidate_relationship_source reference_relationship_method candidate_relationship_method reference_allele_frequency_source candidate_allele_frequency_source reference_ridge candidate_ridge reference_relationship_scale candidate_relationship_scale reference_status candidate_status reference_reason candidate_reason reference_converged candidate_converged reference_termination candidate_termination reference_profile_ratio candidate_profile_ratio reference_numerical_ratio candidate_numerical_ratio reference_t_hat candidate_t_hat reference_profile_loglik candidate_profile_loglik reference_d0 candidate_d0 reference_d1 candidate_d1 reference_sigma_g2 candidate_sigma_g2 reference_sigma_e2 candidate_sigma_e2 max_component_difference profile_loglik_difference_per_observation max_derivative_difference reference_result_digest candidate_result_digest equivalent error_class")
const ADMISSION_ENV_KEYS = split("schema_version candidate_id doc47_original_commit doc47_original_sha256 doc47_amendment_commit doc47_amendment_sha256 reference_commit candidate_commit discovery_manifest_sha256 discovery_digest driver_sha256 host julia_version")
const ATTEMPT_METADATA_KEYS = split("schema_version candidate_id doc47_original_commit doc47_original_sha256 doc47_amendment_commit doc47_amendment_sha256 driver_sha256 implementation_id implementation_commit repeat_id cycle order_index timed_order host julia_version julia_num_threads openblas_num_threads omp_num_threads veclib_maximum_threads")

const ARM_IDS = [
    "C100_E0", "C1000_E0", "C100_E5", "C1000_E5",
    "S050_C100_E0", "S050_C1000_E0", "S050_C100_E5", "S050_C1000_E5",
    "S010_C100_E0", "S010_C1000_E0", "S010_C100_E5", "S010_C1000_E5",
    "S090_C100_E0", "S090_C1000_E0", "S090_C100_E5", "S090_C1000_E5",
]

_opt(args, key, default=nothing) = begin
    prefix = "--$(key)="
    hits = String[]
    for (i, arg) in pairs(args)
        startswith(arg, prefix) && return split(arg, "="; limit=2)[2]
        if arg == "--$(key)"
            i < length(args) || error("--$(key) requires a value")
            startswith(args[i+1], "--") && error("--$(key) requires a value")
            push!(hits, args[i+1])
        end
    end
    length(hits) <= 1 || error("--$(key) may be supplied only once")
    isempty(hits) ? default : only(hits)
end
_required(args, key) = begin
    value = _opt(args, key, nothing)
    value === nothing && error("--$(key) is required")
    value
end
_format(x::AbstractFloat) = isfinite(x) ? @sprintf("%.17g", x) : string(x)
_format(x) = string(x)
_sha256_file(path) = bytes2hex(sha256(read(path)))
_cell(id) = only(filter(c -> c.id == id, CELLS))
_float(x) = parse(Float64, String(x))
_bool(x::Bool) = x
_bool(x) = lowercase(String(x)) == "true"

function _read_table(path, columns)
    lines = readlines(path)
    !isempty(lines) || error("empty table $(path)")
    split(lines[1], '\t'; keepempty=true) == columns || error("schema drift in $(path)")
    rows = [split(line, '\t'; keepempty=true) for line in lines[2:end]]
    all(length(row) == length(columns) for row in rows) || error("field-count drift in $(path)")
    rows
end

function _table_bytes(columns, rows)
    io = IOBuffer()
    println(io, join(columns, '\t'))
    for row in rows
        values = _format.(row)
        all(!occursin(r"[\t\r\n]", value) for value in values) || error("TSV control character")
        println(io, join(values, '\t'))
    end
    take!(io)
end

function _write_table_exclusive(path, columns, rows)
    ispath(path) && error("refusing to overwrite immutable file $(path)")
    mkpath(dirname(path))
    open(path, "w") do io
        write(io, _table_bytes(columns, rows))
    end
end

function _write_sidecar(path)
    _write_table_exclusive(path * ".sha256", ["sha256", "file"],
                           [[_sha256_file(path), basename(path)]])
end

function _validate_sidecar(path)
    sidecar = path * ".sha256"
    rows = _read_table(sidecar, ["sha256", "file"])
    length(rows) == 1 || error("sidecar row-count drift for $(path)")
    rows[1] == [_sha256_file(path), basename(path)] || error("sidecar mismatch for $(path)")
end

function _settings(path)
    Dict(String(r[1]) => String(r[2]) for r in _read_table(path, ["key", "value"]))
end

function _write_atomic_packet(final, files)
    ispath(final) && error("refusing to overwrite immutable packet $(final)")
    mkpath(dirname(final))
    tmp = final * ".tmp.$(getpid())"
    ispath(tmp) && error("stale temporary packet $(tmp)")
    mkpath(tmp)
    try
        lockrows = Vector{Vector{Any}}()
        for (name, (columns, rows)) in files
            path = joinpath(tmp, name)
            _write_table_exclusive(path, columns, rows)
            _write_sidecar(path)
            push!(lockrows, Any[name, _sha256_file(path)])
        end
        _write_table_exclusive(joinpath(tmp, "files.sha256.tsv"), ["relative_path", "sha256"], lockrows)
        mv(tmp, final; force=false)
    catch
        isdir(tmp) && rm(tmp; recursive=true)
        rethrow()
    end
end

function _validate_atomic_packet(final, expected_files)
    lock = _read_table(joinpath(final, "files.sha256.tsv"), ["relative_path", "sha256"])
    [String(r[1]) for r in lock] == expected_files || error("attempt packet file-set/order drift")
    expected_actual = sort(vcat(["files.sha256.tsv"], expected_files, [name * ".sha256" for name in expected_files]))
    sort(readdir(final)) == expected_actual || error("attempt packet contains unsealed files")
    for row in lock
        path = joinpath(final, row[1])
        _sha256_file(path) == row[2] || error("attempt packet checksum drift")
        _validate_sidecar(path)
    end
    nothing
end

function _assert_thread_settings(env=ENV)
    Threads.nthreads() == 1 || error("JULIA_NUM_THREADS must be 1")
    for key in ("OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS", "VECLIB_MAXIMUM_THREADS")
        get(env, key, "") == "1" || error("$(key) must be explicitly set to 1")
    end
    BLAS.set_num_threads(1)
end

function _assert_study_environment()
    readchomp(`hostname`) == "totoro" || error("doc47 discovery profiling must run on totoro")
    VERSION == v"1.10.10" || error("doc47 discovery profiling requires Julia 1.10.10")
    _assert_thread_settings()
end

function _active_root()
    project = Base.active_project()
    project === nothing && error("active project required")
    readchomp(`git -C $(dirname(project)) rev-parse --show-toplevel`)
end
_git_head(root) = readchomp(`git -C $root rev-parse HEAD`)
_git_clean(root) = isempty(readchomp(`git -C $root status --porcelain --untracked-files=all`))

function _assert_doc47(root)
    head=_git_head(root)
    success(`git -C $root merge-base --is-ancestor $DOC47_COMMIT $head`)||error("execution does not descend from original doc47 freeze")
    success(`git -C $root merge-base --is-ancestor $DOC47_AMENDMENT_COMMIT $head`)||error("execution does not descend from doc47 Amendment 1")
    _sha256_file(joinpath(root,DOC47_PATH))==DOC47_AMENDMENT_SHA256||error("amended doc47 bytes drift")
    original=read(`git -C $root show $(DOC47_COMMIT):$(DOC47_PATH)`)
    bytes2hex(sha256(original))==DOC47_SHA256||error("original doc47 freeze bytes drift")
    nothing
end

function _assert_project(implementation, expected_commit)
    root = _active_root()
    _git_clean(root) || error("timing project must be clean")
    head = _git_head(root)
    head == expected_commit || error("timing project commit mismatch")
    implementation in IMPLEMENTATIONS || error("unknown implementation")
    implementation in ("default_ai", "reference_boundary") &&
        head != REFERENCE_COMMIT && error("default/reference must use frozen reference commit")
    implementation=="candidate_boundary"&&_assert_doc47(root)
    _assert_thread_settings()
    root, head
end

function _canonical_target(path)
    current=abspath(path)
    suffix=String[]
    while !ispath(current)
        parent=dirname(current)
        parent==current && error("cannot canonicalize path $(path)")
        pushfirst!(suffix,basename(current))
        current=parent
    end
    base=realpath(current)
    isempty(suffix) ? base : normpath(joinpath(base,suffix...))
end

function _assert_external(outdir, roots...)
    out = _canonical_target(outdir)
    for root in roots
        repo = _canonical_target(root)
        (out == repo || startswith(out, repo * Base.Filesystem.path_separator)) &&
            error("output root must be external to repositories")
    end
end

_path_within(path, root) = path == root || startswith(path, root * Base.Filesystem.path_separator)

function _assert_corpus_output_disjoint(outdir, discovery_dir)
    out = _canonical_target(outdir)
    discovery = _canonical_target(discovery_dir)
    (_path_within(out, discovery) || _path_within(discovery, out)) &&
        error("output and frozen discovery corpus must be disjoint")
    nothing
end

function _matrix(path, prefix)
    lines = readlines(path)
    !isempty(lines) || error("empty matrix file")
    header = split(lines[1], '\t'; keepempty=true)
    header[1] == "row" || error("matrix row header drift")
    all(header[j+1] == "$(prefix)$(j)" for j in 1:length(header)-1) || error("matrix column order drift")
    rows = [split(line, '\t'; keepempty=true) for line in lines[2:end]]
    all(length(r) == length(header) for r in rows) || error("matrix field-count drift")
    all(parse(Int, rows[i][1]) == i for i in eachindex(rows)) || error("matrix row order drift")
    reduce(vcat, [permutedims(parse.(Float64, r[2:end])) for r in rows])
end

function _vector(path)
    rows = _read_table(path, ["row", "y"])
    all(parse(Int, rows[i][1]) == i for i in eachindex(rows)) || error("vector row order drift")
    parse.(Float64, getindex.(rows, 2))
end

function _manifest_datasets(discovery_dir)
    manifest_path = joinpath(discovery_dir, "discovery_manifest.tsv")
    _validate_sidecar(manifest_path)
    _sha256_file(manifest_path) == DISCOVERY_MANIFEST_SHA256 || error("discovery manifest digest drift")
    rows = _read_table(manifest_path, MANIFEST_COLUMNS)
    length(rows) == 58 * 16 || error("discovery manifest row denominator drift")
    grouped = Dict{Tuple{String,Int},Vector{Vector{String}}}()
    for row in rows
        d = Dict(MANIFEST_COLUMNS .=> row)
        d["phase"] == "discovery" || error("non-discovery manifest row")
        cell = _cell(d["cell_id"]); seed = parse(Int, d["seed"])
        parse(Int, d["n"]) == cell.n && parse(Int, d["m"]) == cell.m || error("manifest dimension drift")
        parse(Float64, d["ridge"]) == RIDGE || error("manifest ridge drift")
        push!(get!(grouped, (cell.id, seed), Vector{Vector{String}}()), row)
    end
    length(grouped) == 58 || error("discovery dataset denominator drift")
    for ((cell_id, _), grows) in grouped
        length(grows) == 16 || error("manifest arm denominator drift")
        [r[5] for r in grows] == ARM_IDS || error("manifest arm order drift")
        for index in (4, 9, 10, 11, 12, 13, 14)
            length(unique(r[index] for r in grows)) == 1 || error("manifest dataset field drift")
        end
        cell = _cell(cell_id)
        length(grows) == 16 && cell.datasets > 0 || error("unknown discovery cell")
    end
    for cell in CELLS
        sets = [rows for ((id, _), rows) in grouped if id == cell.id]
        length(sets) == cell.datasets || error("$(cell.id) dataset denominator drift")
        count(rows -> rows[1][4] == "control", sets) == cell.controls || error("$(cell.id) control denominator drift")
        count(rows -> rows[1][4] == "failure", sets) == cell.datasets - cell.controls || error("$(cell.id) failure denominator drift")
    end
    grouped
end

function _validate_packet(discovery_dir, cell_id, seed, manifest_rows)
    packet = joinpath(discovery_dir, "datasets", "discovery", cell_id, string(seed))
    isdir(packet) || error("missing discovery packet $(cell_id)/$(seed)")
    actual = sort(readdir(packet))
    actual == sort(vcat(PACKET_FILES, ["files.sha256.tsv"])) || error("discovery packet file-set drift")
    lockpath = joinpath(packet, "files.sha256.tsv")
    lock = _read_table(lockpath, ["relative_path", "sha256"])
    [String(r[1]) for r in lock] == PACKET_FILES || error("discovery packet lock order drift")
    all(_sha256_file(joinpath(packet, r[1])) == r[2] for r in lock) || error("discovery packet checksum drift")
    packet_digest = _sha256_file(lockpath)
    metadata_rows = _read_table(joinpath(packet, "metadata.tsv"), ["key", "value"])
    [String(r[1]) for r in metadata_rows] == METADATA_KEYS || error("discovery metadata key order drift")
    md = Dict(String(r[1]) => String(r[2]) for r in metadata_rows)
    firstrow = Dict(MANIFEST_COLUMNS .=> first(manifest_rows))
    for key in ("phase", "cell_id", "seed", "role", "n", "m", "ridge", "marker_hash", "id_hash", "kernel_hash")
        md[key] == firstrow[key] || error("packet/manifest $(key) drift")
    end
    parse(Int, md["p"]) == 1 || error("discovery fixed-effect dimension drift")
    arms = _read_table(joinpath(packet, "arms.tsv"), RAW_COLUMNS)
    length(arms) == 16 && [r[5] for r in arms] == ARM_IDS || error("packet arm denominator/order drift")
    for row in arms
        d = Dict(RAW_COLUMNS .=> row)
        for key in ("phase", "cell_id", "seed", "role", "marker_hash", "id_hash", "kernel_hash")
            d[key] == md[key] || error("arm/packet $(key) drift")
        end
    end
    y = _vector(joinpath(packet, "y.tsv"))
    X = _matrix(joinpath(packet, "X.tsv"), "x")
    K = _matrix(joinpath(packet, "K.tsv"), "k")
    n = parse(Int, md["n"])
    length(y) == n && size(X) == (n, 1) && size(K) == (n, n) || error("packet dimensions drift")
    all(isfinite, y) && all(isfinite, X) && all(isfinite, K) || error("packet contains nonfinite data")
    isapprox(K, transpose(K); atol=1e-12, rtol=0) || error("packet kernel is asymmetric")
    ids = ["id$(i)" for i in 1:n]
    HSquared._genomic_id_order_fingerprint(ids) == md["id_hash"] || error("packet ID hash drift")
    HSquared._genomic_matrix_fingerprint("K_lambda", K, ids) == md["kernel_hash"] || error("packet kernel hash drift")
    kfactor = cholesky(Symmetric(K); check=true)
    Q = Matrix(kfactor \ Matrix{Float64}(I, n, n)); Q = (Q + transpose(Q)) / 2
    maximum(abs, Q * K - Matrix{Float64}(I, n, n)) <= 1e-8 || error("packet K/Q identity drift")
    precision_hash = HSquared._genomic_matrix_fingerprint("Q_lambda", Q, ids)

    oracle_path = joinpath(discovery_dir, "oracle", "discovery", cell_id, "$(seed).tsv")
    _validate_sidecar(oracle_path)
    oracle = _read_table(oracle_path, ORACLE_COLUMNS)
    length(oracle) == 16 || error("oracle row denominator drift")
    [r[5] for r in oracle] == ARM_IDS || error("oracle arm order drift")
    all(r[1:30] == arms[i] for (i, r) in enumerate(oracle)) || error("oracle changed copied arm row")
    all(r[42] == packet_digest for r in oracle) || error("oracle packet digest drift")
    classes = unique(r[31] for r in oracle)
    length(classes) == 1 || error("oracle class differs by arm")
    oracle_class = only(classes)
    oracle_class in ("interior_oracle", "lower_boundary", "upper_boundary") || error("unresolved/unknown discovery oracle class")
    return (packet=packet, md=md, y=y, X=X, K=K, Q=Q, ids=ids,
            precision_hash=precision_hash, packet_digest=packet_digest,
            oracle_path=oracle_path, oracle_sha256=_sha256_file(oracle_path),
            oracle_class=oracle_class, oracle=oracle)
end

function _actual_dataset_keys(root)
    isdir(root) || error("missing corpus directory $(root)")
    keys = Tuple{String,Int}[]
    for cell in sort(readdir(root))
        cellpath = joinpath(root, cell)
        isdir(cellpath) || error("non-directory in corpus tree")
        for seed in sort(readdir(cellpath))
            seedpath = joinpath(cellpath, seed)
            isdir(seedpath) || error("non-directory in corpus tree")
            parsed = tryparse(Int, seed); parsed === nothing && error("nonnumeric corpus seed")
            push!(keys, (cell, parsed))
        end
    end
    sort(keys)
end

function _validate_top_artifact(discovery_dir, name, digest)
    path = joinpath(discovery_dir, name)
    _validate_sidecar(path)
    _sha256_file(path) == digest || error("frozen discovery artifact drift: $(name)")
end

function _admission_rows(discovery_dir)
    _validate_top_artifact(discovery_dir, "discovery_manifest.tsv", DISCOVERY_MANIFEST_SHA256)
    _validate_top_artifact(discovery_dir, "environment_manifest.tsv", DISCOVERY_ENVIRONMENT_SHA256)
    _validate_top_artifact(discovery_dir, "candidate_seal.tsv", DISCOVERY_CANDIDATE_SEAL_SHA256)
    seal = _read_table(joinpath(discovery_dir, "candidate_seal.tsv"),
                       ["outcome", "policy_id", "discovery_digest", "execution_commit"])
    length(seal) == 1 && seal[1][1] == "BOUNDARY_POLICY_REQUIRED" && seal[1][3] == DISCOVERY_DIGEST ||
        error("discovery candidate seal drift")
    grouped = _manifest_datasets(discovery_dir)
    dataset_keys = sort(collect(Base.keys(grouped)))
    _actual_dataset_keys(joinpath(discovery_dir, "datasets", "discovery")) == dataset_keys || error("discovery packet set drift")
    oracle_keys = [(cell, parse(Int, splitext(file)[1]))
        for cell in sort(readdir(joinpath(discovery_dir, "oracle", "discovery")))
        for file in sort(readdir(joinpath(discovery_dir, "oracle", "discovery", cell)))
        if endswith(file, ".tsv")]
    sort(oracle_keys) == dataset_keys || error("discovery oracle file set drift")
    oracle_actual = sort([joinpath(cell,file)
        for cell in readdir(joinpath(discovery_dir,"oracle","discovery"))
        for file in readdir(joinpath(discovery_dir,"oracle","discovery",cell))])
    oracle_expected = sort(vcat(
        [joinpath(cell,"$(seed).tsv") for (cell,seed) in dataset_keys],
        [joinpath(cell,"$(seed).tsv.sha256") for (cell,seed) in dataset_keys]))
    oracle_actual == oracle_expected || error("discovery oracle/sidecar set drift")
    rows = Vector{Vector{Any}}()
    digest_paths = String[]
    for (cell, seed) in dataset_keys
        checked = _validate_packet(discovery_dir, cell, seed, grouped[(cell, seed)])
        md = checked.md
        push!(rows, Any[SCHEMA_VERSION, cell, seed, md["role"], md["n"], md["m"],
                        md["marker_hash"], md["id_hash"], md["kernel_hash"], checked.precision_hash,
                        checked.packet_digest, checked.oracle_sha256, checked.oracle_class])
        push!(digest_paths, checked.oracle_path)
        push!(digest_paths, joinpath(checked.packet, "arms.tsv"))
    end
    io = IOBuffer()
    for path in sort(digest_paths)
        print(io, relpath(path, discovery_dir), '\t', _sha256_file(path), '\n')
    end
    bytes2hex(sha256(take!(io))) == DISCOVERY_DIGEST || error("discovery digest recomputation failed")
    length(rows) == 58 || error("admission denominator drift")
    rows
end

function admit_mode(args)
    outdir = abspath(_required(args, "out-dir")); discovery_dir = abspath(_required(args, "discovery-dir"))
    root = _active_root(); _assert_external(outdir, root); _assert_corpus_output_disjoint(outdir, discovery_dir)
    _assert_doc47(root); _git_clean(root) || error("admission project must be clean"); _assert_study_environment()
    candidate_commit = _git_head(root)
    final = joinpath(outdir, "admission")
    if isdir(final)
        _validate_atomic_packet(final, ["discovery_admission.tsv", "environment.tsv"])
        existing=_read_table(joinpath(final,"discovery_admission.tsv"),ADMISSION_COLUMNS)
        existing==[string.(row) for row in _admission_rows(discovery_dir)]||error("admission resume/corpus drift")
        _admission(outdir)
        _admission_environment(outdir)["candidate_commit"]==candidate_commit ||
            error("admission resume candidate commit drift")
        println("resume: discovery admission PASS")
        return
    end
    rows = _admission_rows(discovery_dir)
    envrows = [
        ["schema_version", SCHEMA_VERSION], ["candidate_id", CANDIDATE_ID],
        ["doc47_original_commit", DOC47_COMMIT], ["doc47_original_sha256", DOC47_SHA256],
        ["doc47_amendment_commit", DOC47_AMENDMENT_COMMIT], ["doc47_amendment_sha256", DOC47_AMENDMENT_SHA256],
        ["reference_commit", REFERENCE_COMMIT], ["candidate_commit", candidate_commit],
        ["discovery_manifest_sha256", DISCOVERY_MANIFEST_SHA256],
        ["discovery_digest", DISCOVERY_DIGEST], ["driver_sha256", _sha256_file(@__FILE__)],
        ["host", readchomp(`hostname`)], ["julia_version", string(VERSION)],
    ]
    _write_atomic_packet(final, [
        "discovery_admission.tsv" => (ADMISSION_COLUMNS, rows),
        "environment.tsv" => (["key", "value"], envrows),
    ])
    println("discovery admission PASS: 58 packets and 58 independent-oracle sidecars")
end

function _admission(outdir)
    final = joinpath(outdir, "admission")
    _validate_atomic_packet(final, ["discovery_admission.tsv", "environment.tsv"])
    envrows=_read_table(joinpath(final,"environment.tsv"),["key","value"])
    String.(getindex.(envrows,1))==ADMISSION_ENV_KEYS || error("admission environment key drift")
    env = Dict(String(r[1])=>String(r[2]) for r in envrows)
    expected = Dict("schema_version"=>SCHEMA_VERSION, "candidate_id"=>CANDIDATE_ID,
                    "doc47_original_commit"=>DOC47_COMMIT, "doc47_original_sha256"=>DOC47_SHA256,
                    "doc47_amendment_commit"=>DOC47_AMENDMENT_COMMIT, "doc47_amendment_sha256"=>DOC47_AMENDMENT_SHA256,
                    "reference_commit"=>REFERENCE_COMMIT,
                    "discovery_manifest_sha256"=>DISCOVERY_MANIFEST_SHA256,
                    "discovery_digest"=>DISCOVERY_DIGEST,
                    "driver_sha256"=>_sha256_file(@__FILE__))
    all(get(env, k, "") == v for (k, v) in expected) || error("admission environment drift")
    occursin(r"^[0-9a-f]{40}$", get(env, "candidate_commit", "")) || error("admission candidate commit drift")
    get(env, "host", "") == "totoro" || error("admission host drift")
    get(env, "julia_version", "") == "1.10.10" || error("admission Julia version drift")
    rows = _read_table(joinpath(final, "discovery_admission.tsv"), ADMISSION_COLUMNS)
    length(rows) == 58 || error("admission denominator drift")
    result = Dict{Tuple{String,Int},Dict{String,String}}()
    for row in rows
        d = Dict(String(k)=>String(v) for (k,v) in zip(ADMISSION_COLUMNS,row))
        key = (d["cell_id"], parse(Int,d["seed"])); haskey(result,key) && error("duplicate admission row")
        result[key] = d
    end
    result
end

function _admission_environment(outdir)
    _settings(joinpath(outdir, "admission", "environment.tsv"))
end

function _load_admitted(discovery_dir, admitted)
    grouped = _manifest_datasets(discovery_dir)
    key = (admitted["cell_id"], parse(Int, admitted["seed"]))
    haskey(grouped, key) || error("admitted dataset missing from frozen manifest")
    checked = _validate_packet(discovery_dir, key[1], key[2], grouped[key])
    for field in ("role", "marker_hash", "id_hash", "kernel_hash", "precision_hash", "packet_files_digest", "oracle_sha256", "oracle_class")
        actual = field == "packet_files_digest" ? checked.packet_digest :
                 field == "oracle_sha256" ? checked.oracle_sha256 :
                 field == "oracle_class" ? checked.oracle_class :
                 field == "precision_hash" ? checked.precision_hash : checked.md[field]
        admitted[field] == actual || error("admitted $(field) drift")
    end
    checked
end

function _provenance(data)
    (relationship_source="markers", id_order_fingerprint=data.md["id_hash"],
     precision_fingerprint=data.precision_hash, kernel_fingerprint=data.md["kernel_hash"])
end

function _spec(data)
    animal_model_spec(data.y, data.X, sparse(1.0I, length(data.y), length(data.y)), data.Q;
                      ids=data.ids, method=:REML)
end

function _warm_timing(implementation)
    values=repeat(collect(range(0.25,4.0;length=20));inner=2)
    n=length(values); ids=["doc47_warm_$(i)" for i in 1:n]
    y=[(isodd(i) ? -1.0 : 1.0)*values[i]^0.3 for i in 1:n]
    X=ones(n,1); K=Matrix(Diagonal(values)); Q=Matrix(Diagonal(1.0 ./ values))
    spec = animal_model_spec(y, X, sparse(1.0I,n,n), Q; ids=ids, method=:REML)
    provenance = (relationship_source="markers",
        id_order_fingerprint=HSquared._genomic_id_order_fingerprint(ids),
        precision_fingerprint=HSquared._genomic_matrix_fingerprint("Q_lambda", Q, ids),
        kernel_fingerprint=HSquared._genomic_matrix_fingerprint("K_lambda",K,ids))
    fit_ai_reml(spec)
    boundary=HSquared._fit_ai_reml_genomic_boundary(spec; provenance=provenance,kernel=K)
    boundary_impl=implementation=="candidate_boundary" ? "candidate_boundary" : "reference_boundary"
    context=(cell_id="compile_warmup",seed=0,role="warmup",implementation=boundary_impl,
             repeat=0,timed_order="compile_warmup",marker_hash="warmup",
             id_hash=provenance.id_order_fingerprint,kernel_hash="warmup",
             precision_hash=provenance.precision_fingerprint,result_digest=repeat("0",64),
             error_class="none")
    dummy=(ok=true,value=boundary,error_class="none",elapsed_ns=0,allocated_bytes=0,gc_time_ns=0)
    _profile_components(spec,provenance,K,boundary,dummy,context,repeat("0",64))
    nothing
end

function _measure(f)
    timed = @timed try
        (ok=true, value=f(), error_class="none")
    catch err
        msg = replace(first(split(sprint(showerror, err), '\n')), r"[\t\r\n]" => " ")
        (ok=false, value=nothing, error_class=string(nameof(typeof(err)), ":", msg))
    end
    (ok=timed.value.ok, value=timed.value.value, error_class=timed.value.error_class,
     elapsed_ns=max(0,round(Int,timed.time*1e9)), allocated_bytes=max(0,Int(timed.bytes)),
     gc_time_ns=max(0,round(Int,timed.gctime*1e9)))
end

function _error_class(err; prefix="")
    msg=replace(first(split(sprint(showerror,err),'\n')),r"[\t\r\n]"=>" ")
    prefix*string(nameof(typeof(err)),":",msg)
end

_canon_float(x) = x === nothing ? "NA" : (isfinite(Float64(x)) ? @sprintf("%.17g", Float64(x)) : "NA")
_canon_bool(x) = x === nothing ? "NA" : (Bool(x) ? "true" : "false")

function _result_record(implementation, result, data; error_class="none")
    marker_hash=data.md["marker_hash"]; id_hash=data.md["id_hash"]; kernel_hash=data.md["kernel_hash"]
    base = Dict{String,String}(
        "marker_hash"=>marker_hash, "id_hash"=>id_hash, "kernel_hash"=>kernel_hash,
        "precision_hash"=>data.precision_hash, "relationship_source"=>"markers",
        "relationship_method"=>"vanraden1", "allele_frequency_source"=>"sample",
        "ridge"=>@sprintf("%.17g", RIDGE), "relationship_scale"=>"K_lambda")
    if result === nothing
        merge!(base, Dict("digest_version"=>implementation=="default_ai" ? "default_ai_result_v1" : "scientific_result_v1",
            "status"=>"exception", "reason"=>error_class, "converged"=>"false", "termination"=>"exception",
            "profile_ratio"=>"NA", "numerical_ratio"=>"NA", "t_hat"=>"NA", "profile_loglik"=>"NA",
            "d0"=>"NA", "d1"=>"NA", "sigma_g2"=>"NA", "sigma_e2"=>"NA"))
    elseif implementation == "default_ai"
        vc=result.variance_components; ratio=vc.sigma_a2/(vc.sigma_a2+vc.sigma_e2)
        merge!(base, Dict("digest_version"=>"default_ai_result_v1", "status"=>String(result.optimizer_status),
            "reason"=>String(result.optimizer_status), "converged"=>_canon_bool(result.converged),
            "termination"=>String(result.optimizer_status), "profile_ratio"=>"NA",
            "numerical_ratio"=>_canon_float(ratio), "t_hat"=>"NA", "profile_loglik"=>"NA",
            "d0"=>"NA", "d1"=>"NA", "sigma_g2"=>_canon_float(vc.sigma_a2),
            "sigma_e2"=>_canon_float(vc.sigma_e2)))
    else
        boundary=result.boundary; fit=result.fit
        vc=fit === nothing ? nothing : fit.variance_components
        numerical=vc === nothing ? nothing : vc.sigma_a2/(vc.sigma_a2+vc.sigma_e2)
        t_hat=(vc === nothing || boundary.status=="boundary_unresolved") ? nothing : vc.sigma_a2+vc.sigma_e2
        merge!(base, Dict("digest_version"=>"scientific_result_v1", "status"=>String(boundary.status),
            "reason"=>String(boundary.reason), "converged"=>_canon_bool(fit===nothing ? false : fit.converged),
            "termination"=>fit===nothing ? "boundary_unresolved" : String(fit.optimizer_status),
            "profile_ratio"=>_canon_float(boundary.profile_ratio), "numerical_ratio"=>_canon_float(numerical),
            "t_hat"=>_canon_float(t_hat), "profile_loglik"=>_canon_float(boundary.profile_loglik),
            "d0"=>_canon_float(boundary.lower_derivative_per_observation),
            "d1"=>_canon_float(boundary.upper_derivative_per_observation),
            "sigma_g2"=>_canon_float(vc===nothing ? nothing : vc.sigma_a2),
            "sigma_e2"=>_canon_float(vc===nothing ? nothing : vc.sigma_e2)))
    end
    io=IOBuffer()
    for field in RESULT_FIELDS
        value=get(base,field,nothing); value===nothing && error("missing result digest field $(field)")
        occursin(r"[\t\r\n]",value) && error("result digest control character")
        print(io,field,'=',value,'\n')
    end
    digest=bytes2hex(sha256(take!(io))); base["result_digest"]=digest
    base
end

function _production(implementation, spec, provenance, K)
    implementation == "default_ai" && return fit_ai_reml(spec)
    implementation in ("reference_boundary", "candidate_boundary") || error("unknown implementation")
    HSquared._fit_ai_reml_genomic_boundary(spec; provenance=provenance, kernel=K)
end

function _component_row(context, component, backend, calls, measured, digest; error_class=measured.error_class)
    Any[SCHEMA_VERSION, context.cell_id, context.seed, context.role, context.implementation,
        context.repeat, context.timed_order, component, backend, calls, measured.elapsed_ns,
        measured.allocated_bytes, measured.gc_time_ns, context.marker_hash, context.id_hash,
        context.kernel_hash, context.precision_hash, digest, error_class]
end

_zero_measure()=(ok=true,value=nothing,error_class="none",elapsed_ns=0,allocated_bytes=0,gc_time_ns=0)

function _error_component_rows(context,digest,error_class,selection_stats)
    failed_context=merge(context,(result_digest=digest,error_class=error_class))
    zero=_zero_measure()
    rows=[_component_row(failed_context,component,"not_run",0,zero,digest;error_class=error_class)
          for component in COMPONENTS[1:end-1]]
    push!(rows,_component_row(failed_context,"candidate_total","production_wrapper",1,
        selection_stats,digest;error_class=error_class))
    rows
end

# The stage adapter below mirrors the frozen reference wrapper using named
# package-private kernels. Keeping all source mapping here makes later candidate
# wiring a single, reviewable boundary; selection always times the production
# wrapper above, never this diagnostic reconstruction.
function _profile_components(spec, provenance, K, production, selection_stats, context, digest)
    rows=Vector{Vector{Any}}()
    pre=_measure(() -> HSquared._genomic_boundary_precheck(spec,provenance,K)); pre.ok || error(pre.error_class)
    push!(rows,_component_row(context,"precheck","sparse_mme",1,pre,digest)); pre.value.ok || error("profile precheck failed")
    ai=_measure(() -> HSquared._fit_ai_reml_diagnostics(spec; initial=(sigma_a2=1.0,sigma_e2=1.0),iterations=100,tol=1e-8,em_warmup=0)); ai.ok || error(ai.error_class)
    push!(rows,_component_row(context,"ai_fit","sparse_mme",1,ai,digest))
    qk=_measure() do
        n=length(pre.value.y); out=Matrix(pre.value.qfactor \ Matrix{Float64}(I,n,n)); (out+transpose(out))/2
    end
    qk.ok || error(qk.error_class); push!(rows,_component_row(context,"q_to_k","dense",1,qk,digest))
    eig=_measure(() -> eigen(Symmetric(qk.value))); eig.ok || error(eig.error_class)
    push!(rows,_component_row(context,"eigendecomposition","dense_eigen",1,eig,digest))
    rot=_measure() do
        vt=transpose(eig.value.vectors)
        (eigenvalues=eig.value.values,y=vt*pre.value.y,X=vt*pre.value.X,n=length(pre.value.y),p=size(pre.value.X,2))
    end
    rot.ok || error(rot.error_class); push!(rows,_component_row(context,"rotation","dense_eigen",1,rot,digest))
    grid=collect(0.0:0.0025:1.0)
    gridm=_measure(() -> [HSquared._genomic_profile_reml(rot.value,r) for r in grid]); gridm.ok || error(gridm.error_class)
    length(gridm.value)==401 && all(!isnothing,gridm.value) || error("profile grid drift")
    push!(rows,_component_row(context,"grid_401","eigen_context",401,gridm,digest))
    values=getproperty.(gridm.value,:loglik); index=argmax(view(values,2:400))+1
    lower_r,upper_r=grid[index-1],grid[index+1]
    refine_calls=Ref(0)
    refine=_measure() do
        optimized=optimize(lower_r,upper_r;abs_tol=1e-12) do r
            refine_calls[]+=1
            -something(HSquared._genomic_profile_reml(rot.value,r),(loglik=-Inf,)).loglik
        end
        refine_calls[]+=1
        exact=HSquared._genomic_profile_reml(rot.value,Optim.minimizer(optimized))
        (optimized=optimized,exact=exact)
    end
    refine.ok || error(refine.error_class); push!(rows,_component_row(context,"refinement","eigen_context",refine_calls[],refine,digest))
    accepted=HSquared._genomic_refinement_accepted(Optim.converged(refine.value.optimized),Optim.minimizer(refine.value.optimized),Optim.minimum(refine.value.optimized),lower_r,upper_r,values[index],length(spec.y))
    accepted || error("diagnostic refinement disagrees with production contract")
    interior_r=Optim.minimizer(refine.value.optimized); interior_part=refine.value.exact
    distinct=1e-7 < interior_r < 1-1e-7
    if !distinct; interior_r=grid[index]; interior_part=gridm.value[index]; end
    deriv=_measure() do
        dl=HSquared._genomic_profile_reml(rot.value,1e-6); du=HSquared._genomic_profile_reml(rot.value,1-1e-6)
        (d0=(dl.loglik-gridm.value[1].loglik)/1e-6/length(spec.y),
         d1=(gridm.value[end].loglik-du.loglik)/1e-6/length(spec.y))
    end
    deriv.ok || error(deriv.error_class); push!(rows,_component_row(context,"endpoint_derivatives","eigen_context",2,deriv,digest))
    classm=_measure(() -> HSquared._genomic_boundary_classify_candidates(gridm.value[1].loglik,interior_part.loglik,gridm.value[end].loglik,distinct,deriv.value.d0,deriv.value.d1,length(spec.y)))
    classm.ok || error(classm.error_class); push!(rows,_component_row(context,"classification","scalar",1,classm,digest))
    expected=classm.value.status=="interior_profile" ? Set(["interior","interior_rescued"]) : Set([String(classm.value.status)])
    String(production.boundary.status) in expected || error("diagnostic/production classification drift")
    abs(production.boundary.lower_derivative_per_observation-deriv.value.d0)<=1e-12 && abs(production.boundary.upper_derivative_per_observation-deriv.value.d1)<=1e-12 || error("diagnostic derivative drift")

    fd_calls=0; ai_ok=false
    candidate_eigen = context.implementation=="candidate_boundary"
    candidate_eigen && !isdefined(HSquared,:_genomic_eigen_fd_log_gradient_norm) &&
        error("candidate eigen validator hook is missing")
    gradient_norm(components...) = candidate_eigen ?
        HSquared._genomic_eigen_fd_log_gradient_norm(rot.value,components...) :
        HSquared._genomic_fd_log_gradient_norm(spec,components...)
    fdm = if classm.value.status=="interior_profile"
        _measure() do
            oracle=(interior_r*interior_part.t_hat,(1-interior_r)*interior_part.t_hat)
            avc=ai.value.fit.variance_components; acomp=(avc.sigma_a2,avc.sigma_e2)
            component_ok=all(abs(a-b)<=1e-8+1e-5abs(b) for (a,b) in zip(acomp,oracle))
            ratio=acomp[1]/sum(acomp); ratio_ok=abs(ratio-interior_r)<=1e-8+1e-5abs(interior_r)
            objective_ok=abs(ai.value.fit.likelihood.loglik-interior_part.loglik)/length(spec.y)<=1e-8
            gradient_ok=gradient_norm(acomp...)<=1e-8; fd_calls+=4
            ai_ok=ai.value.fit.converged&&component_ok&&ratio_ok&&objective_ok&&gradient_ok
            if !ai_ok
                gradient_norm(oracle...)<=1e-8; fd_calls+=4
            end
            ai_ok
        end
    else
        _zero_measure()
    end
    fd_backend=fd_calls==0 ? "none" : candidate_eigen ? "eigen_context" : "sparse_mme"
    fdm.ok || error(fdm.error_class); push!(rows,_component_row(context,"interior_validation_fd",fd_backend,fd_calls,fdm,digest))
    final_calls=(classm.value.status=="interior_profile" && fdm.value===true) ? 0 : 1
    finalm = if final_calls==0
        _zero_measure()
    else
        _measure() do
            ratio=classm.value.status=="boundary_lower" ? 1e-7 : classm.value.status=="boundary_upper" ? 1-1e-7 : interior_r
            exact=classm.value.status=="boundary_lower" ? gridm.value[1] : classm.value.status=="boundary_upper" ? gridm.value[end] : interior_part
            likelihood=sparse_reml_loglik(spec,ratio*exact.t_hat,(1-ratio)*exact.t_hat)
            likelihood===nothing&&error("final likelihood evaluation failed")
            abs(likelihood.loglik-production.fit.likelihood.loglik)/length(spec.y)<=1e-8 || error("final likelihood parity drift")
            old=production.fit
            fit=HSquared.AnimalModelFit(spec,likelihood,old.variance_components,old.converged,
                old.optimizer_status,old.iterations,old.target,old.dense_validation_path,
                old.sparse_mme_path,old.variance_components_source)
            (fit=fit,boundary=production.boundary,ai_diagnostics=production.ai_diagnostics)
        end
    end
    finalm.ok || error(finalm.error_class)
    final_backend=final_calls==0 ? "none" : "sparse_mme"
    push!(rows,_component_row(context,"final_likelihood_and_result_assembly",final_backend,final_calls,finalm,digest))
    total=(ok=true,value=production,error_class=selection_stats.error_class,elapsed_ns=selection_stats.elapsed_ns,
           allocated_bytes=selection_stats.allocated_bytes,gc_time_ns=selection_stats.gc_time_ns)
    push!(rows,_component_row(context,"candidate_total","production_wrapper",1,total,digest))
    validation_result=Dict("status"=>String(production.boundary.status))
    _validate_component_rows(rows,context;result=validation_result,selection_stats=selection_stats)
    rows
end

function _validate_component_rows(rows,context; result=nothing, selection_stats=nothing)
    length(rows)==length(COMPONENTS) || error("component denominator drift")
    [String(r[8]) for r in rows]==COMPONENTS || error("component order/name drift")
    all(parse(Int,string(r[10]))>=0 && parse(Int,string(r[11]))>=0 && parse(Int,string(r[12]))>=0 && parse(Int,string(r[13]))>=0 for r in rows) || error("negative component metric")
    all(String(r[1])==SCHEMA_VERSION && String(r[2])==context.cell_id &&
        string(r[3])==string(context.seed) && String(r[4])==context.role &&
        String(r[5])==context.implementation && string(r[6])==string(context.repeat) &&
        String(r[7])==context.timed_order && String(r[14])==context.marker_hash &&
        String(r[15])==context.id_hash && String(r[16])==context.kernel_hash &&
        String(r[17])==context.precision_hash && String(r[18])==context.result_digest
        for r in rows) || error("component identity/provenance drift")
    if context.error_class != "none"
        all(String(r[9])=="not_run" && parse(Int,string(r[10]))==0 &&
            parse(Int,string(r[11]))==0 && parse(Int,string(r[12]))==0 &&
            parse(Int,string(r[13]))==0 && String(r[19])==context.error_class for r in rows[1:end-1]) ||
            error("failed-attempt component encoding drift")
        last=rows[end]
        String(last[9])=="production_wrapper" && parse(Int,string(last[10]))==1 &&
            String(last[19])==context.error_class || error("failed-attempt candidate_total drift")
        selection_stats===nothing && error("failed-attempt validation requires selection metrics")
        string.(last[11:13])==string.([selection_stats.elapsed_ns,selection_stats.allocated_bytes,
            selection_stats.gc_time_ns]) || error("failed candidate_total/selection metric drift")
        return nothing
    end
    all(String(r[19])=="none" for r in rows) || error("successful component error-class drift")
    calls=parse.(Int,string.(getindex.(rows,10)))
    calls[1:5]==[1,1,1,1,1] || error("pre-profile call-count drift")
    calls[6]==401 || error("grid_401 call-count drift")
    calls[7]>0 || error("refinement call-count drift")
    calls[8:9]==[2,1] || error("derivative/classification call-count drift")
    result===nothing && error("successful component validation requires result")
    expected_fd=result["status"]=="interior" ? 4 : result["status"]=="interior_rescued" ? 8 : 0
    calls[10]==expected_fd || error("finite-difference call-count drift")
    expected_final=result["status"]=="interior" ? 0 : 1
    calls[11:12]==[expected_final,1] || error("final/total call-count drift")
    expected_backends=["sparse_mme","sparse_mme","dense","dense_eigen","dense_eigen",
        "eigen_context","eigen_context","eigen_context","scalar",
        expected_fd==0 ? "none" : context.implementation=="candidate_boundary" ? "eigen_context" : "sparse_mme",
        expected_final==0 ? "none" : "sparse_mme","production_wrapper"]
    String.(getindex.(rows,9))==expected_backends || error("component backend drift")
    if selection_stats !== nothing
        string.(rows[end][11:13])==string.([selection_stats.elapsed_ns,
            selection_stats.allocated_bytes,selection_stats.gc_time_ns]) ||
            error("candidate_total/selection metric drift")
    end
    nothing
end

function _attempt_path(outdir,cell,seed,repeat,implementation)
    joinpath(outdir,"attempts",cell,string(seed),"repeat$(repeat)",implementation)
end

function run_mode(args)
    outdir=abspath(_required(args,"out-dir")); discovery_dir=abspath(_required(args,"discovery-dir"))
    implementation=String(_required(args,"implementation")); expected_commit=String(_required(args,"expected-commit"))
    root,head=_assert_project(implementation,expected_commit); _assert_external(outdir,root)
    _assert_corpus_output_disjoint(outdir, discovery_dir); _assert_study_environment()
    admission=_admission(outdir); cell_id=String(_required(args,"cell")); seed=parse(Int,_required(args,"seed"))
    admission_env=_admission_environment(outdir)
    implementation=="candidate_boundary" && expected_commit!=admission_env["candidate_commit"] &&
        error("candidate attempt commit differs from immutable admission")
    key=(cell_id,seed); haskey(admission,key) || error("dataset absent from immutable admission")
    admitted=admission[key]; role=String(_required(args,"role")); admitted["role"]==role || error("role drift")
    repeat=parse(Int,_required(args,"repeat")); repeat in 1:REPEATS || error("repeat outside 1:5")
    cycle=parse(Int,_required(args,"cycle")); cycle==mod(seed+repeat,3) || error("Latin cycle drift")
    order_index=parse(Int,_required(args,"order-index")); timed_order=String(_required(args,"timed-order"))
    expected_order=_latin_order(seed,repeat); timed_order==join(expected_order,">") || error("timed order drift")
    expected_order[order_index]==implementation || error("order index drift")
    final=_attempt_path(outdir,cell_id,seed,repeat,implementation)
    expected_files=implementation=="default_ai" ? ["selection.tsv","result.tsv","metadata.tsv"] : ["selection.tsv","result.tsv","components.tsv","metadata.tsv"]
    if isdir(final)
        _validate_attempt(final,implementation,admitted,repeat;
            expected_candidate_commit=admission_env["candidate_commit"])
        println("resume: $(final)"); return
    end
    data=_load_admitted(discovery_dir,admitted); spec=_spec(data); provenance=_provenance(data)
    _warm_timing(implementation); GC.gc()
    measured=_measure(() -> _production(implementation,spec,provenance,data.K))
    result=_result_record(implementation,measured.value,data;error_class=measured.error_class)
    digest=result["result_digest"]
    attempt_error=measured.error_class
    components=nothing
    if implementation!="default_ai"
        context=(cell_id=cell_id,seed=seed,role=role,implementation=implementation,repeat=repeat,
                 timed_order=timed_order,marker_hash=admitted["marker_hash"],id_hash=admitted["id_hash"],
                 kernel_hash=admitted["kernel_hash"],precision_hash=admitted["precision_hash"],
                 result_digest=digest,error_class="none")
        if measured.ok
            try
                components=_profile_components(spec,provenance,data.K,measured.value,measured,context,digest)
            catch err
                attempt_error=_error_class(err;prefix="profiler:")
                components=_error_component_rows(context,digest,attempt_error,measured)
            end
        else
            components=_error_component_rows(context,digest,attempt_error,measured)
        end
    end
    selection=Any[SCHEMA_VERSION,cell_id,seed,role,repeat,order_index,timed_order,implementation,
                  measured.elapsed_ns,measured.allocated_bytes,measured.gc_time_ns,admitted["marker_hash"],
                  admitted["id_hash"],admitted["kernel_hash"],admitted["precision_hash"],digest,attempt_error]
    files=Pair{String,Any}[
        "selection.tsv"=>(SELECTION_COLUMNS,[selection]),
        "result.tsv"=>(RESULT_COLUMNS,[[result[c] for c in RESULT_COLUMNS]]),
    ]
    implementation!="default_ai" && push!(files,"components.tsv"=>(COMPONENT_COLUMNS,components))
    metadata=[
        ["schema_version",SCHEMA_VERSION],["candidate_id",CANDIDATE_ID],["doc47_original_commit",DOC47_COMMIT],
        ["doc47_original_sha256",DOC47_SHA256],["doc47_amendment_commit",DOC47_AMENDMENT_COMMIT],
        ["doc47_amendment_sha256",DOC47_AMENDMENT_SHA256],["driver_sha256",_sha256_file(@__FILE__)],
        ["implementation_id",implementation],["implementation_commit",head],["repeat_id",string(repeat)],
        ["cycle",string(cycle)],["order_index",string(order_index)],["timed_order",timed_order],
        ["host",readchomp(`hostname`)],["julia_version",string(VERSION)],["julia_num_threads",string(Threads.nthreads())],
        ["openblas_num_threads",get(ENV,"OPENBLAS_NUM_THREADS","")],["omp_num_threads",get(ENV,"OMP_NUM_THREADS","")],
        ["veclib_maximum_threads",get(ENV,"VECLIB_MAXIMUM_THREADS","")],
    ]
    push!(files,"metadata.tsv"=>(["key","value"],metadata))
    _write_atomic_packet(final,files); _validate_atomic_packet(final,expected_files)
    println("wrote $(implementation) $(cell_id)/$(seed) repeat=$(repeat) order=$(order_index)")
end

function _latin_order(seed,repeat)
    cycle=mod(seed+repeat,3)
    cycle==0 ? IMPLEMENTATIONS : cycle==1 ? ["reference_boundary","candidate_boundary","default_ai"] : ["candidate_boundary","default_ai","reference_boundary"]
end

function _result_dict(path)
    rows=_read_table(path,RESULT_COLUMNS); length(rows)==1 || error("result row denominator drift")
    d=Dict(String(k)=>String(v) for (k,v) in zip(RESULT_COLUMNS,only(rows)))
    rebuilt=Dict(k=>d[k] for k in RESULT_FIELDS); io=IOBuffer()
    for field in RESULT_FIELDS; print(io,field,'=',rebuilt[field],'\n'); end
    bytes2hex(sha256(take!(io)))==d["result_digest"] || error("scientific result digest drift")
    d
end

_maybe(d,k)=d[k]=="NA" ? nothing : parse(Float64,d[k])
_maxdiff(xs)=isempty(xs) ? 0.0 : maximum(xs)

function _record_scale_consistent(record)
    sigma_g2=_maybe(record,"sigma_g2"); sigma_e2=_maybe(record,"sigma_e2")
    t_hat=_maybe(record,"t_hat"); numerical=_maybe(record,"numerical_ratio")
    any(isnothing,(sigma_g2,sigma_e2,t_hat,numerical)) && return false
    total=sigma_g2+sigma_e2
    isfinite(total) && total>0 || return false
    abs(t_hat-total)<=1e-12+1e-12abs(total) || return false
    abs(numerical-sigma_g2/total)<=1e-12 || return false
    if record["status"]=="boundary_lower"
        _maybe(record,"profile_ratio")==0.0 && numerical==1e-7 || return false
    elseif record["status"]=="boundary_upper"
        _maybe(record,"profile_ratio")==1.0 && numerical==1-1e-7 || return false
    end
    true
end

function _equivalence_tolerance(status,field,reference)
    endpoint=status in ("boundary_lower","boundary_upper")
    endpoint && field in ("profile_ratio","numerical_ratio") ? 0.0 :
    endpoint && field in ("sigma_g2","sigma_e2") ? 1e-8+1e-7abs(reference) :
    1e-8+1e-5abs(reference)
end

function _equivalence(admitted,reference,candidate,oracle,n)
    exact_fields=("status","reason","converged","termination","marker_hash","id_hash","kernel_hash","precision_hash",
                  "relationship_source","relationship_method","allele_frequency_source","ridge","relationship_scale")
    exact_ok=all(reference[k]==candidate[k] for k in exact_fields)
    diffs=Float64[]
    for field in ("sigma_g2","sigma_e2")
        a=_maybe(reference,field); b=_maybe(candidate,field)
        (a===nothing)==(b===nothing) || (exact_ok=false)
        a===nothing || push!(diffs,abs(a-b))
    end
    max_component=_maxdiff(diffs)
    llr=_maybe(reference,"profile_loglik"); llc=_maybe(candidate,"profile_loglik")
    ll_diff=(llr===nothing||llc===nothing) ? Inf : abs(llr-llc)/n
    derivdiff=_maxdiff([abs(_maybe(reference,k)-_maybe(candidate,k)) for k in ("d0","d1") if _maybe(reference,k)!==nothing&&_maybe(candidate,k)!==nothing])
    numeric_ok=_record_scale_consistent(reference)&&_record_scale_consistent(candidate)
    for field in ("profile_ratio","numerical_ratio","sigma_g2","sigma_e2")
        a=_maybe(reference,field); b=_maybe(candidate,field)
        if (a===nothing)!=(b===nothing); numeric_ok=false
        elseif a!==nothing
            tol=_equivalence_tolerance(reference["status"],field,a)
            abs(a-b)<=tol || (numeric_ok=false)
        end
    end
    for field in ("t_hat",)
        a=_maybe(reference,field); b=_maybe(candidate,field)
        if (a===nothing)!=(b===nothing); numeric_ok=false
        elseif a!==nothing; abs(a-b)<=1e-8+1e-7abs(a)||(numeric_ok=false); end
    end
    ll_diff<=1e-8 || (numeric_ok=false); derivdiff<=1e-8 || (numeric_ok=false)
    reference["status"]=="interior" && max_component>1e-10 && (numeric_ok=false)
    oracle_class=admitted["oracle_class"]
    expected_status=oracle_class=="interior_oracle" ? Set(["interior","interior_rescued"]) :
                    oracle_class=="lower_boundary" ? Set(["boundary_lower"]) : Set(["boundary_upper"])
    oracle_ok=reference["status"] in expected_status
    orow=Dict(ORACLE_COLUMNS .=> first(oracle))
    if oracle_class=="interior_oracle"
        for (field,okey) in (("profile_ratio","oracle_ratio"),("sigma_g2","oracle_sigma_g2"),("sigma_e2","oracle_sigma_e2"))
            a=_maybe(reference,field); o=parse(Float64,orow[okey]); a!==nothing&&abs(a-o)<=1e-8+1e-5abs(o)||(oracle_ok=false)
        end
    else
        expected_ratio=oracle_class=="lower_boundary" ? 0.0 : 1.0
        _maybe(reference,"profile_ratio")==expected_ratio || (oracle_ok=false)
        ot=parse(Float64,orow["oracle_sigma_g2"])+parse(Float64,orow["oracle_sigma_e2"])
        rt=_maybe(reference,"t_hat"); rt!==nothing&&abs(rt-ot)<=1e-8+1e-7abs(ot)||(oracle_ok=false)
    end
    rll=_maybe(reference,"profile_loglik"); oll=parse(Float64,orow["oracle_loglik"])
    rll!==nothing&&abs(rll-oll)/n<=1e-8||(oracle_ok=false)
    for (field,okey) in (("d0","lower_derivative_per_observation"),("d1","upper_derivative_per_observation"))
        a=_maybe(reference,field); o=parse(Float64,orow[okey]); a!==nothing&&abs(a-o)<=1e-8||(oracle_ok=false)
    end
    equivalent=exact_ok&&numeric_ok&&oracle_ok
    values=Any[SCHEMA_VERSION,admitted["cell_id"],admitted["seed"],admitted["role"],admitted["marker_hash"],admitted["id_hash"],admitted["kernel_hash"],oracle_class,
        reference["precision_hash"],candidate["precision_hash"],reference["relationship_source"],candidate["relationship_source"],reference["relationship_method"],candidate["relationship_method"],
        reference["allele_frequency_source"],candidate["allele_frequency_source"],reference["ridge"],candidate["ridge"],reference["relationship_scale"],candidate["relationship_scale"],
        reference["status"],candidate["status"],reference["reason"],candidate["reason"],reference["converged"],candidate["converged"],reference["termination"],candidate["termination"],
        reference["profile_ratio"],candidate["profile_ratio"],reference["numerical_ratio"],candidate["numerical_ratio"],reference["t_hat"],candidate["t_hat"],
        reference["profile_loglik"],candidate["profile_loglik"],reference["d0"],candidate["d0"],reference["d1"],candidate["d1"],reference["sigma_g2"],candidate["sigma_g2"],reference["sigma_e2"],candidate["sigma_e2"],
        max_component,ll_diff,derivdiff,reference["result_digest"],candidate["result_digest"],equivalent,equivalent ? "none" : "equivalence_failure"]
    values
end

function _p95(x)
    isempty(x)&&error("empty p95 denominator"); sort(x)[ceil(Int,0.95length(x))]
end

function _validate_attempt(final,implementation,admitted,repeat; expected_candidate_commit=nothing)
    files=implementation=="default_ai" ? ["selection.tsv","result.tsv","metadata.tsv"] : ["selection.tsv","result.tsv","components.tsv","metadata.tsv"]
    _validate_atomic_packet(final,files)
    metadata_rows=_read_table(joinpath(final,"metadata.tsv"),["key","value"])
    String.(getindex.(metadata_rows,1))==ATTEMPT_METADATA_KEYS || error("attempt metadata key drift")
    metadata=Dict(String(r[1])=>String(r[2]) for r in metadata_rows)
    expected_metadata=Dict("schema_version"=>SCHEMA_VERSION,"candidate_id"=>CANDIDATE_ID,
        "doc47_original_commit"=>DOC47_COMMIT,"doc47_original_sha256"=>DOC47_SHA256,
        "doc47_amendment_commit"=>DOC47_AMENDMENT_COMMIT,"doc47_amendment_sha256"=>DOC47_AMENDMENT_SHA256,
        "driver_sha256"=>_sha256_file(@__FILE__),"implementation_id"=>implementation,
        "repeat_id"=>string(repeat),"host"=>"totoro","julia_version"=>"1.10.10","julia_num_threads"=>"1","openblas_num_threads"=>"1",
        "omp_num_threads"=>"1","veclib_maximum_threads"=>"1")
    all(get(metadata,k,"")==v for (k,v) in expected_metadata)||error("attempt metadata drift")
    implementation in ("default_ai","reference_boundary")&&metadata["implementation_commit"]!=REFERENCE_COMMIT&&error("reference implementation commit drift")
    if implementation=="candidate_boundary"
        expected_candidate_commit===nothing && error("candidate validation requires immutable commit")
        metadata["implementation_commit"]==expected_candidate_commit || error("candidate implementation commit drift")
    end
    occursin(r"^[0-9a-f]{40}$",metadata["implementation_commit"])||error("implementation commit width drift")
    srows=_read_table(joinpath(final,"selection.tsv"),SELECTION_COLUMNS); length(srows)==1||error("selection row denominator drift")
    s=Dict(String(k)=>String(v) for (k,v) in zip(SELECTION_COLUMNS,only(srows)))
    for field in ("cell_id","seed","role","marker_hash","id_hash","kernel_hash","precision_hash")
        s[field]==admitted[field]||error("selection/admission $(field) drift")
    end
    parse(Int,s["repeat_id"])==repeat&&s["implementation_id"]==implementation||error("selection attempt identity drift")
    order=_latin_order(parse(Int,s["seed"]),repeat); s["timed_order"]==join(order,">")||error("selection Latin order drift")
    parse(Int,s["order_index"])==findfirst(==(implementation),order)||error("selection order index drift")
    metadata["cycle"]==string(mod(parse(Int,s["seed"])+repeat,3)) || error("attempt cycle metadata drift")
    metadata["order_index"]==s["order_index"] || error("attempt order-index metadata drift")
    metadata["timed_order"]==s["timed_order"] || error("attempt timed-order metadata drift")
    all(parse(Int,s[k])>=0 for k in ("elapsed_ns","allocated_bytes","gc_time_ns"))||error("negative selection metric")
    result=_result_dict(joinpath(final,"result.tsv")); result["result_digest"]==s["result_digest"]||error("selection/result digest drift")
    expected_result=Dict("marker_hash"=>admitted["marker_hash"],"id_hash"=>admitted["id_hash"],
        "kernel_hash"=>admitted["kernel_hash"],"precision_hash"=>admitted["precision_hash"],
        "relationship_source"=>"markers","relationship_method"=>"vanraden1",
        "allele_frequency_source"=>"sample","ridge"=>@sprintf("%.17g",RIDGE),
        "relationship_scale"=>"K_lambda")
    all(result[k]==v for (k,v) in expected_result) || error("result/admission provenance drift")
    if implementation!="default_ai"
        rows=_read_table(joinpath(final,"components.tsv"),COMPONENT_COLUMNS)
        context=(cell_id=s["cell_id"],seed=parse(Int,s["seed"]),role=s["role"],implementation=implementation,
            repeat=repeat,timed_order=s["timed_order"],marker_hash=s["marker_hash"],id_hash=s["id_hash"],
            kernel_hash=s["kernel_hash"],precision_hash=s["precision_hash"],result_digest=s["result_digest"],
            error_class=s["error_class"])
        stats=(elapsed_ns=parse(Int,s["elapsed_ns"]),allocated_bytes=parse(Int,s["allocated_bytes"]),
               gc_time_ns=parse(Int,s["gc_time_ns"]))
        _validate_component_rows(rows,context;result=result,selection_stats=stats)
    end
    s,result
end

function _summary_context(outdir,discovery_dir)
    root=_active_root(); _git_clean(root)||error("summary project must be clean")
    _assert_doc47(root); _assert_external(outdir,root); _assert_corpus_output_disjoint(outdir,discovery_dir)
    _assert_study_environment()
    env=_admission_environment(outdir)
    _git_head(root)==env["candidate_commit"]||error("summary checkout differs from immutable candidate")
    env["candidate_commit"]
end

function _compute_summary(outdir,discovery_dir,admission,candidate_commit)
    selection=Dict{Tuple{String,Int,Int,String},Dict{String,String}}(); results=Dict{Tuple{String,Int,Int,String},Dict{String,String}}()
    for ((cell,seed),admitted) in sort(collect(admission);by=first), repeat in 1:REPEATS, implementation in IMPLEMENTATIONS
        path=_attempt_path(outdir,cell,seed,repeat,implementation)
        s,r=_validate_attempt(path,implementation,admitted,repeat;
            expected_candidate_commit=candidate_commit)
        key=(cell,seed,repeat,implementation); selection[key]=s; results[key]=r
    end
    length(selection)==58*5*3||error("selection attempt denominator drift")
    candidate_commits=Set(_settings(joinpath(_attempt_path(outdir,cell,seed,repeat,"candidate_boundary"),"metadata.tsv"))["implementation_commit"]
        for ((cell,seed),_) in admission for repeat in 1:REPEATS)
    candidate_commits==Set([candidate_commit])||error("candidate implementation changed during discovery timing")
    equivalence=Vector{Vector{Any}}()
    for ((cell,seed),admitted) in sort(collect(admission);by=first)
        for impl in IMPLEMENTATIONS
            length(unique(results[(cell,seed,r,impl)]["result_digest"] for r in 1:REPEATS))==1||error("scientific result changed across timing repeats")
        end
        checked=_load_admitted(discovery_dir,admitted)
        push!(equivalence,_equivalence(admitted,results[(cell,seed,1,"reference_boundary")],results[(cell,seed,1,"candidate_boundary")],checked.oracle,length(checked.y)))
    end
    n_equiv=count(r->_bool(r[end-1]),equivalence)
    timing_rows=Vector{Vector{Any}}(); timing_ok=true
    for cell in CELLS, scope in ("controls","all")
        datasets=[(c,s) for ((c,s),a) in admission if c==cell.id&&(scope=="all"||a["role"]=="control")]
        expected=scope=="all" ? cell.datasets : cell.controls
        length(datasets)==expected||error("$(cell.id) $(scope) denominator drift")
        medians=Dict{String,Vector{Float64}}(impl=>Float64[] for impl in IMPLEMENTATIONS)
        for (c,s) in datasets, impl in IMPLEMENTATIONS
            times=[parse(Float64,selection[(c,s,r,impl)]["elapsed_ns"]) for r in 1:REPEATS]
            push!(medians[impl],median(times))
        end
        p=Dict(impl=>_p95(medians[impl]) for impl in IMPLEMENTATIONS)
        cd=p["candidate_boundary"]/p["default_ai"]; cr=p["candidate_boundary"]/p["reference_boundary"]
        passed=scope=="controls" ? cd<=2.5 : cd<=2.5&&cr<=1.10
        timing_ok&=passed
        push!(timing_rows,Any[cell.id,scope,expected,p["default_ai"],p["reference_boundary"],p["candidate_boundary"],cd,cr,passed])
    end
    all_none=all(s["error_class"]=="none" for s in values(selection)); passed=n_equiv==58&&timing_ok&&all_none
    gate_error=!all_none ? "attempt_error" : n_equiv!=58 ? "equivalence_failure" : !timing_ok ? "timing_failure" : "none"
    gate=[[passed ? "PASS" : "FAIL",length(selection),n_equiv,timing_ok,gate_error]]
    (equivalence=equivalence,timing_rows=timing_rows,gate=gate,passed=passed)
end

_formatted_rows(rows)=[_format.(row) for row in rows]

function _validate_summary(final,summary)
    _validate_atomic_packet(final,["equivalence.tsv","timing_by_cell.tsv","selection_gate.tsv"])
    timing_columns=split("cell_id scope n_datasets default_p95_ns reference_p95_ns candidate_p95_ns candidate_default_ratio candidate_reference_ratio pass")
    gate_columns=["outcome","attempted","equivalent","timing_ok","error_class"]
    _read_table(joinpath(final,"equivalence.tsv"),EQUIVALENCE_COLUMNS)==_formatted_rows(summary.equivalence)||error("summary equivalence semantic drift")
    _read_table(joinpath(final,"timing_by_cell.tsv"),timing_columns)==_formatted_rows(summary.timing_rows)||error("summary timing semantic drift")
    _read_table(joinpath(final,"selection_gate.tsv"),gate_columns)==_formatted_rows(summary.gate)||error("summary gate semantic drift")
    nothing
end

function summarize_mode(args)
    outdir=abspath(_required(args,"out-dir")); discovery_dir=abspath(_required(args,"discovery-dir"))
    candidate_commit=_summary_context(outdir,discovery_dir)
    admission=_admission(outdir); final=joinpath(outdir,"summary")
    summary=_compute_summary(outdir,discovery_dir,admission,candidate_commit)
    if isdir(final)
        _validate_summary(final,summary)
        println("resume: "*(summary.passed ? "PASS" : "FAIL")); return
    end
    _write_atomic_packet(final,[
        "equivalence.tsv"=>(EQUIVALENCE_COLUMNS,summary.equivalence),
        "timing_by_cell.tsv"=>(split("cell_id scope n_datasets default_p95_ns reference_p95_ns candidate_p95_ns candidate_default_ratio candidate_reference_ratio pass"),summary.timing_rows),
        "selection_gate.tsv"=>(["outcome","attempted","equivalent","timing_ok","error_class"],summary.gate),
    ])
    println(summary.passed ? "DISCOVERY_SELECTION_PASS" : "DISCOVERY_SELECTION_FAIL")
end

function validate_mode(args)
    outdir=abspath(_required(args,"out-dir")); discovery_dir=abspath(_required(args,"discovery-dir"))
    candidate_commit=_summary_context(outdir,discovery_dir)
    admission=_admission(outdir); length(admission)==58||error("admission denominator drift")
    for ((cell,seed),admitted) in admission
        _load_admitted(discovery_dir,admitted)
        for repeat in 1:REPEATS, implementation in IMPLEMENTATIONS
            _validate_attempt(_attempt_path(outdir,cell,seed,repeat,implementation),implementation,admitted,repeat;
                expected_candidate_commit=candidate_commit)
        end
    end
    summary=_compute_summary(outdir,discovery_dir,admission,candidate_commit)
    _validate_summary(joinpath(outdir,"summary"),summary)
    println("discovery profiler validation PASS")
end

function _must_fail(label,f)
    failed=false; try f() catch; failed=true end
    failed||error("negative control stayed green: $(label)")
end

function selftest_mode()
    length(COMPONENTS)==12&&COMPONENTS[6]=="grid_401"&&COMPONENTS[end]=="candidate_total"||error("component vocabulary drift")
    for seed in (1,2,3), repeat in 1:REPEATS
        order=_latin_order(seed,repeat); length(order)==3&&Set(order)==Set(IMPLEMENTATIONS)||error("Latin order drift")
        mod(seed+repeat,3)==0&&order!=IMPLEMENTATIONS&&error("Latin cycle-0 drift")
    end
    _p95(collect(1:20))==19||error("nearest-rank p95 drift")
    median([100.0,1,2,3,4])==3||error("median rule drift")
    _bool(true)&&!_bool(false)&&_bool("true")&&!_bool("false")||error("boolean coercion drift")
    base=Dict{String,String}(field=>"NA" for field in RESULT_FIELDS)
    base["digest_version"]="scientific_result_v1"; base["status"]="interior"
    digest(d)=begin io=IOBuffer(); for f in RESULT_FIELDS; print(io,f,'=',d[f],'\n'); end; bytes2hex(sha256(take!(io))) end
    digest(base)==digest(copy(base))||error("result digest nondeterminism")
    changed=copy(base); changed["status"]="boundary_lower"; digest(base)!=digest(changed)||error("result mutation stayed green")
    context=(cell_id="c",seed=1,role="control",implementation="candidate_boundary",repeat=1,timed_order=join(_latin_order(1,1),">"),marker_hash="m",id_hash="i",kernel_hash="k",precision_hash="q",result_digest="d",error_class="none")
    z=_zero_measure(); rows=[_component_row(context,c,"none",c=="grid_401" ? 401 : c=="interior_validation_fd" ? 4 : 1,z,"d") for c in COMPONENTS]
    rows[1][9]="sparse_mme"; rows[2][9]="sparse_mme"; rows[3][9]="dense"
    rows[4][9]="dense_eigen"; rows[5][9]="dense_eigen"; rows[6][9]="eigen_context"
    rows[7][9]="eigen_context"; rows[8][9]="eigen_context"; rows[8][10]=2; rows[9][9]="scalar"
    rows[10][9]="eigen_context"; rows[11][9]="none"; rows[11][10]=0; rows[12][9]="production_wrapper"
    _validate_component_rows(rows,context;result=Dict("status"=>"interior"),selection_stats=z)
    _must_fail("grid count mutation") do
        bad=deepcopy(rows)
        bad[6][10]=400
        _validate_component_rows(bad,context;result=Dict("status"=>"interior"),selection_stats=z)
    end
    _must_fail("component deletion") do
        _validate_component_rows(rows[1:end-1],context;result=Dict("status"=>"interior"),selection_stats=z)
    end
    _must_fail("negative allocation") do
        bad=deepcopy(rows)
        bad[1][12]=-1
        _validate_component_rows(bad,context;result=Dict("status"=>"interior"),selection_stats=z)
    end
    _must_fail("component backend mutation") do
        bad=deepcopy(rows); bad[8][9]="wrong_backend"
        _validate_component_rows(bad,context;result=Dict("status"=>"interior"),selection_stats=z)
    end
    _must_fail("component role mutation") do
        bad=deepcopy(rows); bad[8][4]="wrong_role"
        _validate_component_rows(bad,context;result=Dict("status"=>"interior"),selection_stats=z)
    end
    _must_fail("component call-count mutation") do
        bad=deepcopy(rows); bad[8][10]=999
        _validate_component_rows(bad,context;result=Dict("status"=>"interior"),selection_stats=z)
    end
    failed_context=merge(context,(error_class="synthetic_failure",))
    failed_stats=(ok=false,value=nothing,error_class="synthetic_failure",elapsed_ns=123456,
        allocated_bytes=789,gc_time_ns=12)
    failed_rows=_error_component_rows(failed_context,"d","synthetic_failure",failed_stats)
    _validate_component_rows(failed_rows,failed_context;selection_stats=failed_stats)
    _must_fail("failed candidate_total mutation") do
        bad=deepcopy(failed_rows); bad[end][11]=0
        _validate_component_rows(bad,failed_context;selection_stats=failed_stats)
    end
    _must_fail("ordering mutation") do
        expected=_latin_order(7,2); mutated=reverse(expected); join(mutated,">")==join(expected,">")||error("ordering red")
    end
    mktempdir() do dir
        corpus=joinpath(dir,"corpus"); mkpath(corpus)
        alias=joinpath(dir,"alias"); symlink(corpus,alias)
        _must_fail("symlink corpus/output overlap") do
            _assert_corpus_output_disjoint(joinpath(alias,"out"),corpus)
        end
        final=joinpath(dir,"packet")
        _write_atomic_packet(final,["row.tsv"=>(["x"],[[1]])]); _validate_atomic_packet(final,["row.tsv"])
        _must_fail("create-once overwrite") do
            _write_atomic_packet(final,["row.tsv"=>(["x"],[[1]])])
        end
        open(joinpath(final,"row.tsv"),"a") do io; println(io,"2") end
        _must_fail("checksum mutation") do
            _validate_atomic_packet(final,["row.tsv"])
        end
    end
    sum(c.datasets for c in CELLS)==58&&sum(c.controls for c in CELLS)==29||error("discovery denominators drift")
    println("doc47 profiler selftest: PASS")
end

function main(args=ARGS)
    mode=String(_opt(args,"mode","selftest"))
    mode=="admit" ? admit_mode(args) :
    mode=="run" ? run_mode(args) :
    mode=="summarize" ? summarize_mode(args) :
    mode=="validate" ? validate_mode(args) :
    mode=="selftest" ? selftest_mode() :
    error("mode must be admit, run, summarize, validate, or selftest")
end

abspath(PROGRAM_FILE)==abspath(@__FILE__)&&main()
