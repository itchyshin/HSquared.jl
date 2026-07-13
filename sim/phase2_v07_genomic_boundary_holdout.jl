#!/usr/bin/env julia

using HSquared
using LinearAlgebra
using Printf
using SHA
using SparseArrays
using Statistics

# Reuse only the frozen doc-45 data generator, hashes, TSV primitives, and exact
# seed contract.  Its guarded main() does not run when this file includes it.
include(joinpath(@__DIR__, "phase2_v07_genomic_optimizer_localization.jl"))

const BOUNDARY_SCHEMA = "v07-genomic-boundary-holdout-v1"
const BOUNDARY_CANDIDATE = "doc46_boundary_v1"
const DOC46_PATH = "docs/design/46-v07-genomic-boundary-resolution.md"
const DOC46_COMMIT = "fe96a147be23d74c5331eb37cd8b681ecce77be6"
const DOC46_SHA256 = "283ab00bab3da925f0ac2916959efacaa7fb711c5da4dce09dd49ea568eef030"

const JULIA_BOUNDARY_IMPL_COMMIT = "24d4ca9a5dec9225cf25a00f06ab53c56c17f36a"
const R_BOUNDARY_IMPL_COMMIT = "a93047744fe52ff0e1111833afad9f42f55d7848"
const R_ORACLE_SHA256 = "121f0cac1d2ec677ec3eee32ff3049dc477d5e98d2dde1b900460877bbef921f"
const DISCOVERY_MANIFEST_SHA256 = "c1f5e1a284ed815a4457ac214372fb37382ade07fef3eb4abce331343bdd820a"
const DISCOVERY_ENVIRONMENT_SHA256 = "e8fa53cc1f8eed96a029ad01f6602eb24e9a299d4105f6771eae5a6d010361d0"
const DISCOVERY_CANDIDATE_SEAL_SHA256 = "8a25266b4a89d26e7f26d060efb577c34c1af125c936e39d00175d4b7cb5a12a"
const DISCOVERY_DIGEST = "33c31a474fc2f0e996d3bd6489a53d055cc753727b69f0625fc30811777c7caf"
const DISCOVERY_DRIVER_SHA256 = "e03e4f71bf37beec23743b664747ff91ec7116eae825ba46a973dcfac8acfa06"

const BOUNDARY_EPSILON = 1e-7
const GRID_STEP = 0.0025
const REFINEMENT_ABS_TOL = 1e-12
const LIKELIHOOD_TIE_PER_OBS = 1e-10
const DERIVATIVE_DELTA = 1e-6
const KKT_TOL_PER_OBS = 1e-8
const HOLDOUT_SEED_FORMULA = "2027120000+10000*cell_index+5001:5048"

const HOLDOUT_COLUMNS = split("cell_id seed n m ridge")
const FIT_COLUMNS = split("cell_id seed route converged termination_reason iterations sigma_g2 sigma_e2 numerical_ratio profile_ratio profile_t_hat boundary_status boundary_epsilon profile_loglik lower_derivative_per_observation upper_derivative_per_observation objective ai_score_norm fd_log_gradient_norm runtime_seconds marker_hash id_hash kernel_hash")
const BOUNDARY_METADATA_KEYS = split("schema_version candidate_id cell_id seed n p m ridge marker_hash id_hash kernel_hash doc46_commit doc46_sha256 julia_boundary_impl_commit r_boundary_impl_commit discovery_digest discovery_candidate_seal_sha256 candidate_seal_sha256 holdout_manifest_sha256 execution_commit driver_sha256 r_oracle_sha256")
const PACKET_FILES = ["K.tsv", "X.tsv", "fits.tsv", "metadata.tsv", "y.tsv"]
const ORACLE_COLUMNS = split("cell_id seed oracle_class oracle_profile_ratio oracle_t_hat oracle_profile_loglik oracle_lower_derivative_per_observation oracle_upper_derivative_per_observation oracle_sigma_g2_numerical oracle_sigma_e2_numerical")
const RESOLVED_STATUSES = Set(["boundary_lower", "boundary_upper", "interior", "interior_rescued"])
const ALL_STATUSES = union(RESOLVED_STATUSES, Set(["boundary_unresolved"]))

_bopt(args, key, default=nothing) = _opt(args, key, default)
_breq(args, key) = _required(args, key)
_hex40(x) = occursin(r"^[0-9a-f]{40}$", x)
_hex64(x) = occursin(r"^[0-9a-f]{64}$", x)
_bool_token(x) = lowercase(String(x)) in ("true", "1")
_float(x) = parse(Float64, String(x))

function _holdout_manifest_rows()
    rows = Vector{Vector{Any}}()
    for cell in CELLS, seed in _holdout_seeds(cell)
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

_holdout_manifest_sha256() = bytes2hex(sha256(_table_bytes(HOLDOUT_COLUMNS, _holdout_manifest_rows())))

function _boundary_execution(root)
    _git_clean(root) || error("execution requires a clean committed worktree")
    _hex40(JULIA_BOUNDARY_IMPL_COMMIT) || error("invalid Julia implementation commit")
    _hex40(R_BOUNDARY_IMPL_COMMIT) || error("invalid R implementation commit")
    head = _git_commit(root)
    success(`git -C $root merge-base --is-ancestor $DOC46_COMMIT $head`) ||
        error("execution commit does not descend from doc 46")
    success(`git -C $root merge-base --is-ancestor $JULIA_BOUNDARY_IMPL_COMMIT $head`) ||
        error("execution commit does not descend from frozen boundary implementation")
    _git_blob_commit(root, DOC46_PATH) == DOC46_COMMIT || error("doc 46 commit drift")
    _sha256_file(joinpath(root, DOC46_PATH)) == DOC46_SHA256 || error("doc 46 bytes drift")
    _sha256_file(joinpath(root, "sim/phase2_v07_genomic_optimizer_localization.jl")) == DISCOVERY_DRIVER_SHA256 ||
        error("frozen discovery driver drift")
    head
end

function _assert_discovery(discovery_dir)
    expected = Dict(
        "discovery_manifest.tsv" => DISCOVERY_MANIFEST_SHA256,
        "environment_manifest.tsv" => DISCOVERY_ENVIRONMENT_SHA256,
        "candidate_seal.tsv" => DISCOVERY_CANDIDATE_SEAL_SHA256,
    )
    for (name, digest) in expected
        path = joinpath(discovery_dir, name)
        isfile(path) || error("missing frozen discovery artifact $(name)")
        _sha256_file(path) == digest || error("frozen discovery artifact drift: $(name)")
    end
    rows = _read_table(joinpath(discovery_dir, "candidate_seal.tsv"),
                       ["outcome", "policy_id", "discovery_digest", "execution_commit"])
    length(rows) == 1 || error("discovery seal row-count drift")
    rows[1][1] == "BOUNDARY_POLICY_REQUIRED" || error("wrong discovery outcome")
    rows[1][3] == DISCOVERY_DIGEST || error("discovery digest drift")
    nothing
end

function _assert_no_holdout(outdir)
    if ispath(outdir)
        forbidden = filter(name -> name != ".DS_Store", readdir(outdir))
        isempty(forbidden) || error("holdout material already exists; candidate is spent or directory is not fresh")
    end
end

function _seal_rows(root, execution_commit, r_repo, r_oracle, discovery_dir)
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
        ["julia_boundary_impl_commit", JULIA_BOUNDARY_IMPL_COMMIT],
        ["r_boundary_impl_commit", R_BOUNDARY_IMPL_COMMIT],
        ["r_execution_commit", r_head],
        ["localization_driver_sha256", DISCOVERY_DRIVER_SHA256],
        ["boundary_driver_sha256", _sha256_file(@__FILE__)],
        ["r_oracle_sha256", R_ORACLE_SHA256],
        ["exchange_schema", BOUNDARY_SCHEMA],
        ["boundary_epsilon", _format(BOUNDARY_EPSILON)],
        ["grid_step", _format(GRID_STEP)],
        ["refinement_abs_tol", _format(REFINEMENT_ABS_TOL)],
        ["likelihood_tie_per_observation", _format(LIKELIHOOD_TIE_PER_OBS)],
        ["derivative_delta", _format(DERIVATIVE_DELTA)],
        ["kkt_tolerance_per_observation", _format(KKT_TOL_PER_OBS)],
        ["holdout_seed_formula", HOLDOUT_SEED_FORMULA],
        ["timing_protocol", "fixed_nonholdout_warmup_then_seed_parity_order"],
        ["holdout_manifest_sha256", _holdout_manifest_sha256()],
        ["discovery_manifest_sha256", DISCOVERY_MANIFEST_SHA256],
        ["discovery_environment_sha256", DISCOVERY_ENVIRONMENT_SHA256],
        ["discovery_candidate_seal_sha256", DISCOVERY_CANDIDATE_SEAL_SHA256],
        ["discovery_digest", DISCOVERY_DIGEST],
        ["execution_commit", execution_commit],
        ["host", readchomp(`hostname`)],
        ["julia_version", string(VERSION)],
        ["r_version", first(split(read(`R --version`, String), '\n'))],
        ["project_sha256", _sha256_file(project)],
        ["manifest_sha256", _sha256_file(manifest)],
        ["julia_num_threads", string(Threads.nthreads())],
        ["openblas_num_threads", get(ENV, "OPENBLAS_NUM_THREADS", "")],
        ["omp_num_threads", get(ENV, "OMP_NUM_THREADS", "")],
        ["veclib_maximum_threads", get(ENV, "VECLIB_MAXIMUM_THREADS", "")],
        ["holdout_absent_before_seal", "true"],
    ]
end

function seal_mode(args)
    root = _git_root()
    execution_commit = _boundary_execution(root)
    outdir = abspath(_breq(args, "out-dir"))
    discovery_dir = abspath(_breq(args, "discovery-dir"))
    r_repo = abspath(_breq(args, "r-repo"))
    r_oracle = abspath(_breq(args, "r-oracle"))
    _assert_no_holdout(outdir)
    rows = _seal_rows(root, execution_commit, r_repo, r_oracle, discovery_dir)
    mkpath(outdir)
    path = joinpath(outdir, "candidate_seal.tsv")
    _write_table_exclusive(path, ["key", "value"], rows)
    _write_sidecar(path)
    println("sealed candidate before holdout materialization: $(_sha256_file(path))")
end

function _candidate_settings(outdir)
    path = joinpath(outdir, "candidate_seal.tsv")
    _validate_sidecar(path)
    rows = _read_table(path, ["key", "value"])
    settings = Dict(String(r[1]) => String(r[2]) for r in rows)
    expected = Dict(
        "schema_version" => BOUNDARY_SCHEMA,
        "candidate_id" => BOUNDARY_CANDIDATE,
        "doc46_commit" => DOC46_COMMIT,
        "doc46_sha256" => DOC46_SHA256,
        "julia_boundary_impl_commit" => JULIA_BOUNDARY_IMPL_COMMIT,
        "r_boundary_impl_commit" => R_BOUNDARY_IMPL_COMMIT,
        "holdout_manifest_sha256" => _holdout_manifest_sha256(),
        "timing_protocol" => "fixed_nonholdout_warmup_then_seed_parity_order",
        "discovery_candidate_seal_sha256" => DISCOVERY_CANDIDATE_SEAL_SHA256,
        "discovery_digest" => DISCOVERY_DIGEST,
        "holdout_absent_before_seal" => "true",
    )
    all(get(settings, k, "") == v for (k, v) in expected) || error("candidate seal drift")
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
    _write_table_exclusive(path, HOLDOUT_COLUMNS, _holdout_manifest_rows())
    _sha256_file(path) == settings["holdout_manifest_sha256"] || error("written manifest digest drift")
    _write_sidecar(path)
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
        seed in _holdout_seeds(cell) || error("non-frozen holdout seed")
        parse(Int, row[3]) == cell.n && parse(Int, row[4]) == cell.m || error("manifest dimension drift")
        parse(Float64, row[5]) == RIDGE || error("manifest ridge drift")
        key = (cell.id, seed); haskey(out, key) && error("duplicate holdout dataset")
        out[key] = (cell=cell, seed=seed)
    end
    out
end

function _fit_row(cell, seed, route, result, runtime, hashes)
    if route == "default_ai"
        fit = result
        vc = fit.variance_components
        ratio = vc.sigma_a2 / (vc.sigma_a2 + vc.sigma_e2)
        return Any[cell.id, seed, route, fit.converged, fit.optimizer_status, fit.iterations,
            vc.sigma_a2, vc.sigma_e2, ratio, NaN, NaN, "not_classified", BOUNDARY_EPSILON,
            NaN, NaN, NaN, fit.likelihood.loglik, NaN, _julia_fd_gradient(fit), runtime,
            hashes.marker_hash, hashes.id_hash, hashes.kernel_hash]
    end
    fit = result.fit; boundary = result.boundary
    status = String(boundary.status)
    status in ALL_STATUSES || error("unknown boundary status")
    if fit === nothing
        status == "boundary_unresolved" || error("resolved boundary result is missing its fit")
        return Any[cell.id, seed, route, false, String(boundary.reason), 0,
            NaN, NaN, NaN, NaN, NaN, status, boundary.boundary_epsilon,
            NaN, NaN, NaN, NaN, NaN, NaN, runtime,
            hashes.marker_hash, hashes.id_hash, hashes.kernel_hash]
    end
    vc = fit.variance_components
    numerical_ratio = vc.sigma_a2 / (vc.sigma_a2 + vc.sigma_e2)
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
    Any[cell.id, seed, route, fit.converged, String(boundary.reason), fit.iterations,
        vc.sigma_a2, vc.sigma_e2, numerical_ratio, profile_ratio, profile_t_hat, status,
        boundary.boundary_epsilon, profile_loglik, d0, d1, fit.likelihood.loglik,
        diag.ai_score_norm, fd, runtime, hashes.marker_hash, hashes.id_hash, hashes.kernel_hash]
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

function _validate_packet(packet, settings, manifest_sha)
    lock = joinpath(packet, "files.sha256.tsv")
    rows = _read_table(lock, ["relative_path", "sha256"])
    [String(r[1]) for r in rows] == PACKET_FILES || error("packet file set/order drift")
    for row in rows
        path = joinpath(packet, row[1]); isfile(path) || error("missing packet file")
        _sha256_file(path) == row[2] || error("packet checksum drift")
    end
    actual = sort(readdir(packet))
    actual == sort(vcat(PACKET_FILES, ["files.sha256.tsv"])) || error("packet contains unsealed files")
    metadata = _read_table(joinpath(packet, "metadata.tsv"), ["key", "value"])
    [String(r[1]) for r in metadata] == BOUNDARY_METADATA_KEYS || error("metadata key order drift")
    md = Dict(String(r[1]) => String(r[2]) for r in metadata)
    md["schema_version"] == BOUNDARY_SCHEMA && md["candidate_id"] == BOUNDARY_CANDIDATE || error("packet schema drift")
    md["candidate_seal_sha256"] == settings["candidate_seal_sha256"] || error("packet candidate seal drift")
    md["holdout_manifest_sha256"] == manifest_sha || error("packet manifest drift")
    all(_hex64(md[k]) for k in ("marker_hash", "id_hash", "kernel_hash", "doc46_sha256",
        "discovery_digest", "discovery_candidate_seal_sha256", "candidate_seal_sha256",
        "holdout_manifest_sha256", "driver_sha256", "r_oracle_sha256")) || error("packet hash width drift")
    all(_hex40(md[k]) for k in ("doc46_commit", "julia_boundary_impl_commit",
        "r_boundary_impl_commit", "execution_commit")) || error("packet commit width drift")
    fitrows = _read_table(joinpath(packet, "fits.tsv"), FIT_COLUMNS)
    length(fitrows) == 2 || error("packet fit denominator drift")
    [String(r[3]) for r in fitrows] == ["default_ai", "boundary_candidate"] || error("fit route order drift")
    fits = _fit_dict.(fitrows)
    all(f["cell_id"] == md["cell_id"] && f["seed"] == md["seed"] &&
        f["marker_hash"] == md["marker_hash"] && f["id_hash"] == md["id_hash"] &&
        f["kernel_hash"] == md["kernel_hash"] for f in fits) || error("fit/metadata provenance drift")
    fits[1]["boundary_status"] == "not_classified" || error("default route was classified")
    all(isnan(_float(fits[1][k])) for k in ("profile_ratio", "profile_t_hat", "profile_loglik",
        "lower_derivative_per_observation", "upper_derivative_per_observation")) || error("default profile fields must be missing")
    status = fits[2]["boundary_status"]
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
                abs(_float(fits[2]["numerical_ratio"]) - BOUNDARY_EPSILON) <= 1e-15 || error("lower boundary ratio drift")
        elseif status == "boundary_upper"
            _float(fits[2]["profile_ratio"]) == 1.0 &&
                abs(_float(fits[2]["numerical_ratio"]) - (1-BOUNDARY_EPSILON)) <= 1e-15 || error("upper boundary ratio drift")
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
    manifest_sha = settings["holdout_manifest_sha256"]
    settings["candidate_seal_sha256"] = _sha256_file(joinpath(outdir, "candidate_seal.tsv"))
    if isdir(final)
        _validate_packet(final, settings, manifest_sha)
        println("resume: sealed packet $(cell.id)/$(seed)")
        return
    end
    # An interrupted attempt may leave only an unsealed temporary sibling.
    # It is safe to discard because the candidate, seed, and code are already
    # sealed and the retry cannot adapt to the unseen partial values.
    parent = dirname(final)
    if isdir(parent)
        for name in readdir(parent)
            startswith(name, basename(final) * ".tmp.") && rm(joinpath(parent, name); recursive=true)
        end
    end
    data = _dataset(cell, seed)
    spec = animal_model_spec(data.y, data.X, sparse(1.0I, cell.n, cell.n), data.Q;
                             ids=data.ids, method=:REML)
    provenance = (relationship_source="markers", id_order_fingerprint=data.id_hash,
                  precision_fingerprint=HSquared._genomic_matrix_fingerprint("Q_lambda", Matrix(data.Q), data.ids),
                  kernel_fingerprint=data.kernel_hash)
    _warm_boundary_timing()
    if isodd(seed)
        started = time_ns(); default = fit_ai_reml(spec); default_runtime = (time_ns() - started) / 1e9
        started = time_ns()
        candidate = HSquared._fit_ai_reml_genomic_boundary(spec; provenance=provenance, kernel=data.K)
        candidate_runtime = (time_ns() - started) / 1e9
    else
        started = time_ns()
        candidate = HSquared._fit_ai_reml_genomic_boundary(spec; provenance=provenance, kernel=data.K)
        candidate_runtime = (time_ns() - started) / 1e9
        started = time_ns(); default = fit_ai_reml(spec); default_runtime = (time_ns() - started) / 1e9
    end
    hashes = (marker_hash=data.marker_hash, id_hash=data.id_hash, kernel_hash=data.kernel_hash)
    fitrows = [_fit_row(cell, seed, "default_ai", default, default_runtime, hashes),
               _fit_row(cell, seed, "boundary_candidate", candidate, candidate_runtime, hashes)]
    tmp = final * ".tmp.$(getpid())"
    ispath(tmp) && error("stale packet temporary directory")
    mkpath(tmp)
    try
        _write_table_exclusive(joinpath(tmp, "y.tsv"), ["row", "y"], [[i, data.y[i]] for i in eachindex(data.y)])
        _write_matrix(joinpath(tmp, "X.tsv"), data.X, "x")
        _write_matrix(joinpath(tmp, "K.tsv"), data.K, "k")
        _write_table_exclusive(joinpath(tmp, "fits.tsv"), FIT_COLUMNS, fitrows)
        values = [BOUNDARY_SCHEMA, BOUNDARY_CANDIDATE, cell.id, seed, cell.n, size(data.X,2), cell.m,
                  RIDGE, data.marker_hash, data.id_hash, data.kernel_hash, DOC46_COMMIT, DOC46_SHA256,
                  JULIA_BOUNDARY_IMPL_COMMIT, R_BOUNDARY_IMPL_COMMIT, DISCOVERY_DIGEST,
                  DISCOVERY_CANDIDATE_SEAL_SHA256, settings["candidate_seal_sha256"], manifest_sha,
                  settings["execution_commit"], settings["boundary_driver_sha256"], settings["r_oracle_sha256"]]
        _write_table_exclusive(joinpath(tmp, "metadata.tsv"), ["key", "value"], [[k,v] for (k,v) in zip(BOUNDARY_METADATA_KEYS, values)])
        lockrows = [[name, _sha256_file(joinpath(tmp, name))] for name in PACKET_FILES]
        _write_table_exclusive(joinpath(tmp, "files.sha256.tsv"), ["relative_path", "sha256"], lockrows)
        mkpath(dirname(final)); mv(tmp, final; force=false)
    catch
        isdir(tmp) && rm(tmp; recursive=true)
        rethrow()
    end
    _validate_packet(final, settings, manifest_sha)
    println("sealed packet $(cell.id)/$(seed)")
end

function _oracle_path(outdir, cell, seed)
    joinpath(outdir, "oracle", cell, "$(seed).tsv")
end

function _read_oracle(outdir, cell, seed)
    path = _oracle_path(outdir, cell, seed)
    _validate_sidecar(path)
    rows = _read_table(path, ORACLE_COLUMNS)
    length(rows) == 1 || error("oracle row-count drift")
    d = Dict(String(k) => String(v) for (k,v) in zip(ORACLE_COLUMNS, only(rows)))
    d["cell_id"] == cell && parse(Int, d["seed"]) == seed || error("oracle identity drift")
    d["oracle_class"] in ("interior_oracle", "boundary_lower", "boundary_upper", "oracle_unresolved") || error("oracle class drift")
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
    abs(_float(candidate["numerical_ratio"]) - expected_numerical) <= 1e-15 || return false
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

function summarize_mode_boundary(args)
    outdir = abspath(_breq(args, "out-dir")); settings = _candidate_settings(outdir)
    pair = joinpath(outdir, "summary", "holdout_pairs.tsv")
    gate = joinpath(outdir, "summary", "holdout_gate.tsv")
    if isfile(pair) || isfile(gate)
        isfile(pair) && isfile(gate) || error("partial summary exists")
        _validate_sidecar(pair); _validate_sidecar(gate)
        rows = _read_table(gate, split("outcome attempted wins losses discordant cp_lower net_gain unresolved candidate_invalid unchanged_interior_errors rates_ok runtime_ok"))
        length(rows) == 1 || error("summary gate row-count drift")
        println(rows[1][1] == "PASS" ? "resume: BOUNDARY_HOLDOUT_PASS" : "resume: BOUNDARY_HOLDOUT_FAIL")
        return
    end
    manifest = _manifest(outdir); details = Vector{Vector{Any}}(); runtime_rows = Dict{String,String}[]
    cell_interior = Dict(c.id => Bool[] for c in CELLS)
    W = 0; L = 0; unresolved = 0; status_errors = 0; unchanged_errors = 0
    for ((cell_id, seed), entry) in sort(collect(manifest); by=x -> x[1])
        packet = joinpath(outdir, "packets", cell_id, string(seed))
        settings["candidate_seal_sha256"] = _sha256_file(joinpath(outdir, "candidate_seal.tsv"))
        _validate_packet(packet, settings, settings["holdout_manifest_sha256"])
        fitrows = _read_table(joinpath(packet, "fits.tsv"), FIT_COLUMNS)
        default = _fit_dict(fitrows[1]); candidate = _fit_dict(fitrows[2]); oracle = _read_oracle(outdir, cell_id, seed)
        n = entry.cell.n; dv = _interior_valid(default, oracle, n); cv = _candidate_valid(candidate, oracle, n)
        oracle["oracle_class"] == "oracle_unresolved" && (unresolved += 1)
        !cv && (status_errors += 1)
        if oracle["oracle_class"] == "interior_oracle"
            push!(cell_interior[cell_id], cv)
            if candidate["boundary_status"] == "interior"
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
    runtime_ok = all(candidate_p95[c.id] <= 3default_p95[c.id] for c in CELLS)
    pass = unresolved == 0 && status_errors == 0 && unchanged_errors == 0 && L == 0 && discord > 0 && cp > 0.5 && rates_ok && runtime_ok
    summary_dir = joinpath(outdir, "summary"); mkpath(summary_dir)
    _write_table_exclusive(pair, split("cell_id seed oracle_class default_status candidate_status default_valid candidate_valid win loss"), details); _write_sidecar(pair)
    _write_table_exclusive(gate, split("outcome attempted wins losses discordant cp_lower net_gain unresolved candidate_invalid unchanged_interior_errors rates_ok runtime_ok"),
        [[pass ? "PASS" : "FAIL", 240, W, L, discord, cp, (W-L)/240, unresolved, status_errors, unchanged_errors, rates_ok, runtime_ok]]); _write_sidecar(gate)
    println(pass ? "BOUNDARY_HOLDOUT_PASS" : "BOUNDARY_HOLDOUT_FAIL")
end

function _must_fail_boundary(label, f)
    failed = false
    try f() catch; failed = true end
    failed || error("negative control stayed green: $(label)")
end

function selftest_mode_boundary()
    _assert_seed_contract()
    length(_holdout_manifest_rows()) == 240 || error("holdout denominator drift")
    length(unique((r[1], r[2]) for r in _holdout_manifest_rows())) == 240 || error("duplicate holdout seed")
    _hex40(DOC46_COMMIT) || error("doc commit width drift")
    all(_hex64, (DOC46_SHA256, DISCOVERY_MANIFEST_SHA256, DISCOVERY_ENVIRONMENT_SHA256,
                      DISCOVERY_CANDIDATE_SEAL_SHA256, DISCOVERY_DIGEST, DISCOVERY_DRIVER_SHA256,
                      R_ORACLE_SHA256)) || error("digest width drift")
    rows = _holdout_manifest_rows(); bytes = _table_bytes(HOLDOUT_COLUMNS, rows)
    bytes2hex(sha256(bytes)) == _holdout_manifest_sha256() || error("manifest determinism drift")
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
    mktempdir() do dir
        _must_fail_boundary("holdout before seal") do
            _candidate_settings(dir)
        end
        mkpath(joinpath(dir, "packets"))
        _must_fail_boundary("pre-existing holdout at seal") do
            _assert_no_holdout(dir)
        end
    end
    _hex40(JULIA_BOUNDARY_IMPL_COMMIT) || error("implementation binding drift")
    _hex40(R_BOUNDARY_IMPL_COMMIT) || error("R implementation binding drift")
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
