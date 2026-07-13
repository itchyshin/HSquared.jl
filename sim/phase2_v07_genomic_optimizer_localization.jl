#!/usr/bin/env julia

using HSquared
using LinearAlgebra
using Printf
using Random
using SHA
using SparseArrays
using Statistics

# Doc 45/45a/45b optimizer-localization harness.  It deliberately launches no
# workers and never calls R.  One invocation creates or validates one immutable
# object; the Totoro launcher provides process isolation and the independent R
# oracle consumes the sealed dataset packets.

const RIDGE = 0.01
const DOC45_COMMIT = "e2b4b23957ab4075205a7399214daae186a04bcb"
const DOC45_SHA256 = "4eb8b7012140d6f5f30d7c4cfbaf46f974ef5a3caa7b0c4f14e002ddf8657f50"
const DOC45A_COMMIT = "1ce3720ab31eb2108acd842fdd74f6c1ddbc45ec"
const DOC45A_SHA256 = "f88509b2aa715c5836bbc387284e94e3fcc6904d66ec00290f71b2e099f18182"
const DOC45B_COMMIT = "a4a5e27ae2dbc7e86012aa1f81438ce73ebaf156"
const DOC45B_SHA256 = "75ae42baa13ce5044e95be4d2a4d4a5b71a2eef3b98caa22c57adbad9e46c6a3"
const DOC45B_PATH = "docs/design/45b-v07-genomic-oracle-endpoint-tolerance.md"
const SCHEMA_VERSION = "v07-genomic-localization-exchange-v1"
const CONTROL_SELECTION_SHA256 = "542fa30e307cc21cde85ed65b060832888435dcc018d5dcabf3f1897f3703894"
const ATOMIC_ARM_ORDER_SHA256 = "3999118d103f2eaa81133c4c29f5fd9158a08b42c4ea74b7568d4322b8b08fba"
const POLICY_ORDER_SHA256 = "25a442fb658db9ac98413250bef0b03cdd122ca7f38ceeefcfb2c268f9d59819"
const PILOT_MANIFEST_SHA256 = "7ceaaae2ca0a11e4791367ba0c4311d5474702e41d1d9f0e0efc8f5f86c56e81"
const PILOT_RAW_LOCK_SHA256 = "18c353a4caec204dd65ad526df327bacc495f96b7d86f08641adede09db300ad"

const FINAL_COLUMNS = split("phase cell_id seed role arm_id cap em_warmup start_id start_sigma_g2 start_sigma_e2 converged termination_reason iterations em_steps factorizations step_halvings estimate_sigma_g2 estimate_sigma_e2 estimate_ratio julia_objective ai_score_norm julia_fd_log_gradient_norm last_relative_change smallest_component runtime_seconds peak_rss_mb error_class marker_hash id_hash kernel_hash oracle_class oracle_ratio oracle_sigma_g2 oracle_sigma_e2 oracle_arm_loglik oracle_loglik objective_gap_per_observation oracle_fd_log_gradient_norm lower_derivative_per_observation upper_derivative_per_observation interior_agreement dataset_files_digest")
const RAW_COLUMNS = FINAL_COLUMNS[1:30]
const METADATA_KEYS = split("schema_version phase cell_id seed role n p m ridge marker_hash id_hash kernel_hash doc45_commit doc45_sha256 doc45a_commit doc45a_sha256 doc45b_commit doc45b_sha256 execution_commit")
const MANIFEST_COLUMNS = split("phase cell_id seed role arm_id cap em_warmup start_id n m ridge marker_hash id_hash kernel_hash")
const PILOT_COLUMNS_V2 = split("tier cell_id seed n m truth_sigma_g2 truth_sigma_e2 truth_ratio ridge estimate_sigma_g2 estimate_sigma_e2 estimate_ratio converged iterations objective gradient_norm runtime_seconds peak_rss_mb marker_hash id_hash kernel_hash error_class")
const PILOT_COLUMNS_LEGACY = split("tier cell_id seed n m truth_sigma_g2 truth_sigma_e2 truth_ratio estimate_sigma_g2 estimate_sigma_e2 estimate_ratio converged iterations objective gradient_norm runtime_seconds peak_rss_mb marker_hash id_hash kernel_hash error_class")
const PILOT_MANIFEST_COLUMNS = split("tier cell_id seed n m truth_sigma_g2 truth_sigma_e2 truth_ratio ridge regime")

const PILOT_CELLS = [
    (index=1, id="n120_m600_r020", n=120, m=600, ratio=0.2),
    (index=2, id="n120_m600_r050", n=120, m=600, ratio=0.5),
    (index=3, id="n120_m600_r080", n=120, m=600, ratio=0.8),
    (index=4, id="n300_m150_r020", n=300, m=150, ratio=0.2),
    (index=5, id="n300_m150_r050", n=300, m=150, ratio=0.5),
    (index=6, id="n300_m150_r080", n=300, m=150, ratio=0.8),
    (index=7, id="n300_m1000_r020", n=300, m=1000, ratio=0.2),
    (index=8, id="n300_m1000_r050", n=300, m=1000, ratio=0.5),
    (index=9, id="n300_m1000_r080", n=300, m=1000, ratio=0.8),
]

const CELLS = PILOT_CELLS[[1,2,3,7,9]]

const FAILURE_SEEDS = Dict(
    "n120_m600_r020" => [2027130002, 2027130006, 2027130009, 2027130012, 2027130014, 2027130018,
                          2027130019, 2027130025, 2027130028, 2027130030, 2027130032, 2027130036],
    "n120_m600_r050" => [2027140037, 2027140038],
    "n120_m600_r080" => [2027150011, 2027150013, 2027150016, 2027150020, 2027150022, 2027150039,
                          2027150045, 2027150046],
    "n300_m1000_r020" => [2027190021, 2027190030, 2027190040, 2027190042, 2027190044, 2027190046],
    "n300_m1000_r080" => [2027210013],
)

const ATOMIC_ARMS = [
    (arm_id="C100_E0", cap=100, em_warmup=0, start_id="current"),
    (arm_id="C1000_E0", cap=1000, em_warmup=0, start_id="current"),
    (arm_id="C100_E5", cap=100, em_warmup=5, start_id="current"),
    (arm_id="C1000_E5", cap=1000, em_warmup=5, start_id="current"),
    (arm_id="S050_C100_E0", cap=100, em_warmup=0, start_id="r050"),
    (arm_id="S050_C1000_E0", cap=1000, em_warmup=0, start_id="r050"),
    (arm_id="S050_C100_E5", cap=100, em_warmup=5, start_id="r050"),
    (arm_id="S050_C1000_E5", cap=1000, em_warmup=5, start_id="r050"),
    (arm_id="S010_C100_E0", cap=100, em_warmup=0, start_id="r010"),
    (arm_id="S010_C1000_E0", cap=1000, em_warmup=0, start_id="r010"),
    (arm_id="S010_C100_E5", cap=100, em_warmup=5, start_id="r010"),
    (arm_id="S010_C1000_E5", cap=1000, em_warmup=5, start_id="r010"),
    (arm_id="S090_C100_E0", cap=100, em_warmup=0, start_id="r090"),
    (arm_id="S090_C1000_E0", cap=1000, em_warmup=0, start_id="r090"),
    (arm_id="S090_C100_E5", cap=100, em_warmup=5, start_id="r090"),
    (arm_id="S090_C1000_E5", cap=1000, em_warmup=5, start_id="r090"),
]

const POLICY_ORDER = let rows = NamedTuple[]
    for (prefix, starts) in (("C", ["current"]), ("S050", ["r050"]),
                             ("S010", ["r010"]), ("S090", ["r090"]),
                             ("M", ["r050", "r010", "r090"]))
        for (cap, em) in ((100,0), (1000,0), (100,5), (1000,5))
            id = prefix == "C" ? "C$(cap)_E$(em)" : "$(prefix)_C$(cap)_E$(em)"
            push!(rows, (id=id, cap=cap, em_warmup=em, starts=starts))
        end
    end
    rows
end

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
_bool(args, key, default=true) = lowercase(String(_opt(args, key, string(default)))) in ("1", "true", "yes")
_format(x::AbstractFloat) = isfinite(x) ? @sprintf("%.17g", x) : string(x)
_format(x) = string(x)
_sha256_file(path) = bytes2hex(sha256(read(path)))

function _cell(id)
    matches = filter(c -> c.id == id, CELLS)
    length(matches) == 1 || error("unknown cell $(id)")
    only(matches)
end

function _pilot_cell(id)
    matches = filter(c -> c.id == id, PILOT_CELLS)
    length(matches) == 1 || error("unknown pilot cell $(id)")
    only(matches)
end

_seed_base(cell) = 2_027_120_000 + 10_000 * cell.index
_pilot_seeds(cell) = (_seed_base(cell)+1):(_seed_base(cell)+48)
_holdout_seeds(cell) = (_seed_base(cell)+5001):(_seed_base(cell)+5048)
_confirmation_seeds(cell) = (_seed_base(cell)+1001):(_seed_base(cell)+3000)

function _control_seeds(cell)
    failed = Set(FAILURE_SEEDS[cell.id])
    converged = filter(seed -> !(seed in failed), collect(_pilot_seeds(cell)))
    sort!(converged; by=seed -> bytes2hex(sha256("$(cell.id)|$(seed)")))
    converged[1:length(failed)]
end

function _arm(id)
    matches = filter(a -> a.arm_id == id, ATOMIC_ARMS)
    length(matches) == 1 || error("unknown atomic arm $(id)")
    only(matches)
end

function _arm_for(cap, em_warmup, start_id)
    matches = filter(a -> a.cap == cap && a.em_warmup == em_warmup &&
                          a.start_id == start_id, ATOMIC_ARMS)
    length(matches) == 1 || error("unknown atomic arm tuple ($(cap), $(em_warmup), $(start_id))")
    only(matches)
end

function _assert_seed_contract()
    all(length(FAILURE_SEEDS[c.id]) == length(_control_seeds(c)) for c in CELLS) ||
        error("discovery failure/control imbalance")
    sum(length, values(FAILURE_SEEDS)) == 29 || error("frozen failure count drift")
    control_text=join(["$(c.id):$(join(_control_seeds(c),","))" for c in CELLS],"|")
    bytes2hex(sha256(control_text))==CONTROL_SELECTION_SHA256 || error("control selection/order drift")
    bytes2hex(sha256(join(getproperty.(ATOMIC_ARMS,:arm_id),"|")))==ATOMIC_ARM_ORDER_SHA256 || error("atomic arm order drift")
    bytes2hex(sha256(join(getproperty.(POLICY_ORDER,:id),"|")))==POLICY_ORDER_SHA256 || error("candidate policy order drift")
    for cell in CELLS
        discovery = union(Set(FAILURE_SEEDS[cell.id]), Set(_control_seeds(cell)))
        holdout = Set(_holdout_seeds(cell))
        isempty(intersect(discovery, holdout)) || error("discovery/holdout overlap")
        isempty(intersect(Set(_pilot_seeds(cell)), holdout)) || error("pilot/holdout overlap")
        isempty(intersect(Set(_confirmation_seeds(cell)), holdout)) || error("confirmation/holdout overlap")
    end
end

function _assert_single_threaded()
    Threads.nthreads() == 1 || error("JULIA_NUM_THREADS must be 1")
    for key in ("OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS", "VECLIB_MAXIMUM_THREADS")
        get(ENV, key, "") == "1" || error("$(key) must be explicitly set to 1")
    end
    BLAS.set_num_threads(1)
end

function _active_project()
    project = Base.active_project()
    project === nothing && error("active Julia project required")
    project
end

function _git_root()
    project = _active_project()
    readchomp(`git -C $(dirname(project)) rev-parse --show-toplevel`)
end
_git_commit(root) = readchomp(`git -C $root rev-parse HEAD`)
_git_clean(root) = isempty(readchomp(`git -C $root status --porcelain --untracked-files=all`))

function _git_blob_commit(root, path)
    readchomp(`git -C $root log -1 --format=%H -- $path`)
end

function _assert_frozen_execution(root)
    _git_clean(root) || error("execution requires a clean committed worktree")
    head = _git_commit(root)
    success(`git -C $root merge-base --is-ancestor $DOC45_COMMIT $head`) || error("execution commit does not descend from doc 45")
    success(`git -C $root merge-base --is-ancestor $DOC45A_COMMIT $head`) || error("execution commit does not descend from doc 45a")
    success(`git -C $root merge-base --is-ancestor $DOC45B_COMMIT $head`) || error("execution commit does not descend from doc 45b")
    _sha256_file(joinpath(root, "docs/design/45-v07-genomic-optimizer-localization.md")) == DOC45_SHA256 || error("doc 45 bytes changed")
    _sha256_file(joinpath(root, "docs/design/45a-v07-genomic-optimizer-exchange-schema.md")) == DOC45A_SHA256 || error("doc 45a bytes changed")
    doc45b = joinpath(root, DOC45B_PATH)
    isfile(doc45b) || error("missing frozen doc 45b")
    _git_blob_commit(root, DOC45B_PATH) == DOC45B_COMMIT || error("doc 45b commit drift")
    _sha256_file(doc45b) == DOC45B_SHA256 || error("doc 45b bytes changed")
    return (execution_commit=head, doc45b_commit=DOC45B_COMMIT, doc45b_sha256=DOC45B_SHA256)
end

function _assert_external_empty(outdir, root)
    out = abspath(outdir); repo = abspath(root)
    (out == repo || startswith(out, repo * Base.Filesystem.path_separator)) &&
        error("output directory must be external to the repository")
    ispath(out) && !isempty(readdir(out)) && error("output directory must be empty")
end

function _draw_markers(rng, n, m)
    maf = 0.05 .+ 0.45 .* rand(rng, m)
    M = Matrix{Float64}(undef, n, m)
    for j in 1:m, i in 1:n
        M[i,j] = (rand(rng) < maf[j]) + (rand(rng) < maf[j])
    end
    keep = [maximum(view(M,:,j)) != minimum(view(M,:,j)) for j in 1:m]
    M[:,keep]
end

function _dataset(cell, seed)
    rng = MersenneTwister(seed)
    M = _draw_markers(rng, cell.n, cell.m)
    isempty(M) && error("realized marker panel is monomorphic")
    ids = ["id$(i)" for i in 1:cell.n]
    construction = HSquared._genomic_activation_construction(M, ids; ridge=RIDGE)
    u = cholesky(Symmetric(construction.K)).L * randn(rng, cell.n) .* sqrt(cell.ratio)
    y = u .+ randn(rng, cell.n) .* sqrt(1-cell.ratio)
    X = ones(cell.n, 1)
    return (y=y, X=X, K=construction.K, Q=construction.Q, ids=ids,
            marker_hash=construction.provenance.marker_content_fingerprint,
            id_hash=construction.provenance.id_order_fingerprint,
            kernel_hash=construction.provenance.kernel_fingerprint)
end

function _scaled_start(data, r0)
    residual = data.y - data.X * (data.X \ data.y)
    sy2 = dot(residual, residual) / (length(data.y)-size(data.X,2))
    d = mean(diag(data.K))
    t0 = sy2 / (r0*d + (1-r0))
    (sigma_a2=r0*t0, sigma_e2=(1-r0)*t0)
end

function _start(data, id)
    id == "current" && return (sigma_a2=1.0, sigma_e2=1.0)
    id == "r010" && return _scaled_start(data, 0.1)
    id == "r050" && return _scaled_start(data, 0.5)
    id == "r090" && return _scaled_start(data, 0.9)
    error("truth-blind start label required")
end

function _julia_fd_gradient(fit)
    vc = fit.variance_components
    x = log.([vc.sigma_a2, vc.sigma_e2]); h = 1e-5; g = zeros(2)
    for j in 1:2
        xp=copy(x); xm=copy(x); xp[j]+=h; xm[j]-=h
        fp=gaussian_loglik(fit.spec, exp(xp[1]), exp(xp[2]); method=:REML).loglik
        fm=gaussian_loglik(fit.spec, exp(xm[1]), exp(xm[2]); method=:REML).loglik
        g[j]=(fp-fm)/(2h)
    end
    norm(g)/length(fit.spec.y)
end

function _write_table_exclusive(path, columns, rows)
    ispath(path) && error("refusing to overwrite immutable file $(path)")
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, join(columns, '\t'))
        for row in rows; println(io, join(_format.(row), '\t')); end
    end
end

function _write_sidecar(path)
    side = path * ".sha256"
    _write_table_exclusive(side, ["sha256", "file"], [[_sha256_file(path), basename(path)]])
end

function _validate_sidecar(path)
    side=path*".sha256"; isfile(side) || error("missing checksum sidecar $(side)")
    lines=readlines(side); length(lines)==2 || error("malformed checksum sidecar")
    f=split(lines[2], '\t'); length(f)==2 && f[1]==_sha256_file(path) && f[2]==basename(path) || error("checksum mismatch for $(path)")
end

function _read_table(path, columns)
    lines=readlines(path); !isempty(lines) || error("empty table $(path)")
    split(lines[1], '\t'; keepempty=true)==columns || error("schema drift in $(path)")
    rows=[split(line, '\t'; keepempty=true) for line in lines[2:end]]
    all(length(row)==length(columns) for row in rows) || error("field-count drift in $(path)")
    rows
end

function _pilot_row(pilot_dir, cell, seed)
    path=joinpath(pilot_dir, "raw", "pilot", cell.id, "$(seed).tsv")
    lines=readlines(path); length(lines)==2 || error("malformed original pilot row")
    header=String.(split(lines[1], '\t'; keepempty=true))
    header in (PILOT_COLUMNS_V2,PILOT_COLUMNS_LEGACY) ||
        error("original pilot schema drift")
    row=split(lines[2], '\t'; keepempty=true)
    length(row)==length(header) || error("original pilot field-count drift")
    Dict(header .=> row)
end

function _validate_pilot_source(pilot_dir)
    manifest=joinpath(pilot_dir,"pilot_manifest.tsv")
    lock=joinpath(pilot_dir,"campaign_raw_sha256.tsv")
    _sha256_file(manifest)==PILOT_MANIFEST_SHA256 ||
        error("original pilot manifest digest mismatch")
    _sha256_file(lock)==PILOT_RAW_LOCK_SHA256 ||
        error("original pilot raw-lock digest mismatch")
    mrows=_read_table(manifest,PILOT_MANIFEST_COLUMNS)
    length(mrows)==9*48 || error("original pilot manifest denominator drift")
    lrows=_read_table(lock,["path","sha256"])
    length(lrows)==9*48 || error("original pilot raw-lock denominator drift")
    expected_paths=sort([String(r[1]) for r in lrows])
    actual_paths=String[]
    rawroot=joinpath(pilot_dir,"raw","pilot")
    for (directory,_,names) in walkdir(rawroot), name in names
        endswith(name,".tsv") || continue
        push!(actual_paths,relpath(joinpath(directory,name),pilot_dir))
    end
    sort!(actual_paths)
    actual_paths==expected_paths || error("original pilot raw file-set drift")
    for row in lrows
        _sha256_file(joinpath(pilot_dir,row[1]))==row[2] ||
            error("original pilot raw hash mismatch: $(row[1])")
    end
    for row in mrows
        d=Dict(PILOT_MANIFEST_COLUMNS .=> row)
        cell=_pilot_cell(d["cell_id"]); seed=parse(Int,d["seed"])
        d["tier"]=="pilot" && seed in _pilot_seeds(cell) &&
            parse(Int,d["n"])==cell.n && parse(Int,d["m"])==cell.m &&
            parse(Float64,d["ridge"])==RIDGE ||
            error("original pilot manifest scientific drift")
    end
    nothing
end

function _discovery_datasets(pilot_dir)
    rows=NamedTuple[]
    for cell in CELLS
        for (role,seeds) in (("failure",FAILURE_SEEDS[cell.id]), ("control",_control_seeds(cell)))
            for seed in seeds
                p=_pilot_row(pilot_dir,cell,seed)
                (lowercase(p["converged"])=="true") == (role=="control") || error("original pilot role mismatch $(cell.id) $(seed)")
                data=_dataset(cell,seed)
                p["marker_hash"]==data.marker_hash && p["id_hash"]==data.id_hash && p["kernel_hash"]==data.kernel_hash || error("original pilot provenance mismatch $(cell.id) $(seed)")
                push!(rows,(cell=cell,seed=seed,role=role,data=data))
            end
        end
    end
    rows
end

function _manifest_rows_discovery(pilot_dir)
    rows=Vector{Vector{Any}}()
    for ds in _discovery_datasets(pilot_dir), arm in ATOMIC_ARMS
        push!(rows,Any["discovery",ds.cell.id,ds.seed,ds.role,arm.arm_id,arm.cap,arm.em_warmup,
                       arm.start_id,ds.cell.n,ds.cell.m,RIDGE,ds.data.marker_hash,ds.data.id_hash,ds.data.kernel_hash])
    end
    rows
end

function _settings(path)
    rows=_read_table(path,["key","value"])
    Dict(r[1]=>r[2] for r in rows)
end

function _environment_rows(root, frozen, discovery_sha)
    project=_active_project(); manifest=joinpath(dirname(project),"Manifest.toml")
    isfile(manifest) || error("Manifest.toml required")
    r_version=first(split(read(`R --version`,String),'\n'))
    [["schema_version",SCHEMA_VERSION], ["execution_commit",frozen.execution_commit],
     ["doc45_commit",DOC45_COMMIT], ["doc45_sha256",DOC45_SHA256],
     ["doc45a_commit",DOC45A_COMMIT], ["doc45a_sha256",DOC45A_SHA256],
     ["doc45b_commit",frozen.doc45b_commit], ["doc45b_sha256",frozen.doc45b_sha256],
     ["driver_sha256",_sha256_file(@__FILE__)], ["project_sha256",_sha256_file(project)],
     ["manifest_sha256",_sha256_file(manifest)], ["discovery_manifest_sha256",discovery_sha],
     ["git_root",root], ["host",readchomp(`hostname`)], ["julia_version",string(VERSION)],
     ["r_version",r_version], ["ridge",string(RIDGE)]]
end

function manifest_discovery(args)
    root=_git_root(); frozen=_assert_frozen_execution(root); _assert_seed_contract()
    outdir=abspath(_required(args,"out-dir")); pilot_dir=abspath(_required(args,"pilot-dir"))
    _validate_pilot_source(pilot_dir)
    _assert_external_empty(outdir,root); mkpath(outdir)
    path=joinpath(outdir,"discovery_manifest.tsv")
    _write_table_exclusive(path,MANIFEST_COLUMNS,_manifest_rows_discovery(pilot_dir)); _write_sidecar(path)
    env=joinpath(outdir,"environment_manifest.tsv")
    _write_table_exclusive(env,["key","value"],_environment_rows(root,frozen,_sha256_file(path))); _write_sidecar(env)
    println("wrote discovery manifest rows=$(length(_read_table(path,MANIFEST_COLUMNS)))")
end

function _candidate_seal(outdir)
    path=joinpath(outdir,"candidate_seal.tsv"); _validate_sidecar(path)
    rows=_read_table(path,["outcome","policy_id","discovery_digest","execution_commit"])
    length(rows)==1 || error("candidate seal must have one row")
    (outcome=rows[1][1],policy_id=rows[1][2],discovery_digest=rows[1][3],execution_commit=rows[1][4])
end

function _policy(id)
    matches=filter(p->p.id==id,POLICY_ORDER); length(matches)==1 || error("unknown sealed policy $(id)"); only(matches)
end

function _manifest_rows_holdout(outdir)
    seal=_candidate_seal(outdir); seal.outcome=="POLICY_SELECTED" || error("holdout is sealed for a negative discovery outcome")
    policy=_policy(seal.policy_id)
    arm_specs=NamedTuple[]
    push!(arm_specs,_arm("C100_E0"))
    for start in policy.starts
        push!(arm_specs,_arm_for(policy.cap, policy.em_warmup, start))
    end
    unique!(arm_specs)
    rows=Vector{Vector{Any}}()
    for cell in CELLS, seed in _holdout_seeds(cell)
        data=_dataset(cell,seed)
        for arm in arm_specs
            push!(rows,Any["holdout",cell.id,seed,"holdout",arm.arm_id,arm.cap,arm.em_warmup,arm.start_id,
                           cell.n,cell.m,RIDGE,data.marker_hash,data.id_hash,data.kernel_hash])
        end
    end
    rows
end

function _validate_environment(outdir)
    root=_git_root(); frozen=_assert_frozen_execution(root)
    env=joinpath(outdir,"environment_manifest.tsv"); _validate_sidecar(env); s=_settings(env)
    checks=Dict("schema_version"=>SCHEMA_VERSION,"execution_commit"=>frozen.execution_commit,
      "doc45_commit"=>DOC45_COMMIT,"doc45_sha256"=>DOC45_SHA256,"doc45a_commit"=>DOC45A_COMMIT,
      "doc45a_sha256"=>DOC45A_SHA256,"doc45b_commit"=>frozen.doc45b_commit,"doc45b_sha256"=>frozen.doc45b_sha256,
      "driver_sha256"=>_sha256_file(@__FILE__),"ridge"=>string(RIDGE))
    all(get(s,k,"")==v for (k,v) in checks) || error("frozen environment mismatch")
    d=joinpath(outdir,"discovery_manifest.tsv"); _validate_sidecar(d)
    get(s,"discovery_manifest_sha256","")==_sha256_file(d) || error("discovery manifest digest mismatch")
    s
end

function manifest_holdout(args)
    outdir=abspath(_required(args,"out-dir")); _validate_environment(outdir)
    path=joinpath(outdir,"holdout_manifest.tsv")
    _write_table_exclusive(path,MANIFEST_COLUMNS,_manifest_rows_holdout(outdir)); _write_sidecar(path)
    println("wrote holdout manifest")
end

function _manifest(outdir,phase)
    _validate_environment(outdir)
    if phase == "holdout"
        seal = _candidate_seal(outdir)
        seal.outcome == "POLICY_SELECTED" || error("holdout cannot be read before a positive candidate seal")
    end
    path=joinpath(outdir,"$(phase)_manifest.tsv"); _validate_sidecar(path)
    rows=_read_table(path,MANIFEST_COLUMNS)
    result=Dict{Tuple{String,Int,String},Dict{SubString{String},SubString{String}}}()
    for r in rows
        d=Dict(MANIFEST_COLUMNS .=> r); cell=_cell(d["cell_id"]); seed=parse(Int,d["seed"]); arm=_arm(d["arm_id"])
        d["phase"]==phase && parse(Int,d["n"])==cell.n && parse(Int,d["m"])==cell.m && parse(Float64,d["ridge"])==RIDGE || error("manifest scientific field drift")
        parse(Int,d["cap"])==arm.cap && parse(Int,d["em_warmup"])==arm.em_warmup && d["start_id"]==arm.start_id || error("manifest arm-label drift")
        if phase=="discovery"
            expected_role=seed in FAILURE_SEEDS[cell.id] ? "failure" : seed in _control_seeds(cell) ? "control" : ""
            d["role"]==expected_role || error("manifest discovery role/seed drift")
        else
            d["role"]=="holdout" && seed in _holdout_seeds(cell) || error("manifest holdout role/seed drift")
        end
        key=(String(d["cell_id"]),seed,String(d["arm_id"])); haskey(result,key) && error("duplicate manifest arm $(key)")
        result[key]=d
    end
    phase=="discovery" && length(result)!=58*16 && error("discovery manifest denominator drift")
    result
end

function _raw_path(outdir,phase,cell,seed,arm)
    joinpath(outdir,"raw",phase,cell,string(seed),"$(arm).tsv")
end

function _validate_raw(row,mr)
    length(row)==length(RAW_COLUMNS) || error("raw result field count drift")
    d=Dict(RAW_COLUMNS .=> row)
    for k in ("phase","cell_id","seed","role","arm_id","cap","em_warmup","start_id","marker_hash","id_hash","kernel_hash")
        d[k]==mr[k] || error("raw result disagrees with manifest field $(k)")
    end
    d["termination_reason"] in ("score_tolerance","relative_change_tolerance","iteration_limit","nonfinite_ai_step","step_halving_exhausted","exception") || error("unknown termination reason")
    lowercase(d["converged"]) in ("true","false") || error("invalid convergence flag")
    cap=parse(Int,d["cap"]); em_requested=parse(Int,d["em_warmup"]); iterations=parse(Int,d["iterations"])
    em_steps=parse(Int,d["em_steps"]); factorizations=parse(Int,d["factorizations"]); halvings=parse(Int,d["step_halvings"])
    0<=em_steps<=em_requested && factorizations>=max(0,iterations)+em_steps && halvings>=0 || error("impossible optimizer counters")
    all(isfinite(parse(Float64,d[k])) for k in ("start_sigma_g2","start_sigma_e2")) || error("nonfinite start")
    if d["termination_reason"]=="iteration_limit"
        iterations==cap || error("iteration-limit row stopped before its cap")
    elseif d["termination_reason"]!="exception"
        all(isfinite(parse(Float64,d[k])) for k in ("estimate_sigma_g2","estimate_sigma_e2","estimate_ratio","julia_objective","ai_score_norm","julia_fd_log_gradient_norm","smallest_component")) || error("nonfinite successful fit field")
    end
    isfinite(parse(Float64,d["runtime_seconds"])) || error("nonfinite runtime")
    row
end

function _read_raw(path,mr)
    _validate_sidecar(path)
    rows=_read_table(path,RAW_COLUMNS); length(rows)==1 || error("raw arm file must contain one row")
    _validate_raw(only(rows),mr)
end

function _run_atomic(mr)
    cell=_cell(mr["cell_id"]); seed=parse(Int,mr["seed"]); data=_dataset(cell,seed); arm=_arm(mr["arm_id"])
    data.marker_hash==mr["marker_hash"] && data.id_hash==mr["id_hash"] && data.kernel_hash==mr["kernel_hash"] || error("dataset provenance mismatch")
    initial=_start(data,arm.start_id); start_rss=Sys.maxrss(); started=time_ns()
    base=Any[mr["phase"],cell.id,seed,mr["role"],arm.arm_id,arm.cap,arm.em_warmup,arm.start_id,initial.sigma_a2,initial.sigma_e2]
    try
        spec=animal_model_spec(data.y,data.X,sparse(1.0I,cell.n,cell.n),data.Q;ids=data.ids,method=:REML)
        result=HSquared._fit_ai_reml_diagnostics(spec;initial=initial,iterations=arm.cap,em_warmup=arm.em_warmup)
        fit=result.fit; diag=result.diagnostics; vc=fit.variance_components; ratio=vc.sigma_a2/(vc.sigma_a2+vc.sigma_e2)
        elapsed=(time_ns()-started)/1e9; rss=max(start_rss,Sys.maxrss())/1024^2
        return vcat(base,Any[fit.converged,diag.termination_reason,fit.iterations,diag.em_steps,diag.factorizations,
          diag.step_halvings,vc.sigma_a2,vc.sigma_e2,ratio,-fit.likelihood.loglik,diag.ai_score_norm,
          _julia_fd_gradient(fit),diag.last_relative_change,min(vc.sigma_a2,vc.sigma_e2),elapsed,rss,
          fit.converged ? "none" : "fit_not_converged",data.marker_hash,data.id_hash,data.kernel_hash])
    catch err
        elapsed=(time_ns()-started)/1e9; rss=max(start_rss,Sys.maxrss())/1024^2
        msg=replace(first(split(sprint(showerror,err),'\n')),'\t'=>' ')
        return vcat(base,Any[false,"exception",-1,0,0,0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,elapsed,rss,
          string(nameof(typeof(err)),":",msg),data.marker_hash,data.id_hash,data.kernel_hash])
    end
end

function run_mode(args)
    _assert_single_threaded(); outdir=abspath(_required(args,"out-dir")); phase=String(_required(args,"phase"))
    phase in ("discovery","holdout") || error("invalid phase")
    cell=String(_required(args,"cell")); seed=parse(Int,_required(args,"seed")); arm=String(_required(args,"arm"))
    manifest=_manifest(outdir,phase); key=(cell,seed,arm); haskey(manifest,key) || error("arm absent from immutable manifest")
    path=_raw_path(outdir,phase,cell,seed,arm)
    if isfile(path) && _bool(args,"resume",true)
        _read_raw(path,manifest[key]); println("resume: $(path)"); return
    end
    row=_run_atomic(manifest[key]); tmp=path*".tmp.$(getpid())"; mkpath(dirname(path))
    _write_table_exclusive(tmp,RAW_COLUMNS,[row]); mv(tmp,path;force=false); _write_sidecar(path)
    println("wrote $(path)")
end

function _dataset_manifest_rows(manifest,cell,seed)
    order = Dict(a.arm_id => i for (i, a) in enumerate(ATOMIC_ARMS))
    sort([mr for ((c,s,_),mr) in manifest if c==cell && s==seed];
         by=mr->order[String(mr["arm_id"])])
end

function dataset_mode(args)
    outdir=abspath(_required(args,"out-dir")); phase=String(_required(args,"phase")); cellid=String(_required(args,"cell")); seed=parse(Int,_required(args,"seed"))
    manifest=_manifest(outdir,phase); mrows=_dataset_manifest_rows(manifest,cellid,seed); !isempty(mrows) || error("dataset absent from manifest")
    rawrows=Vector{Vector{String}}()
    for mr in mrows; push!(rawrows,_read_raw(_raw_path(outdir,phase,cellid,seed,mr["arm_id"]),mr)); end
    cell=_cell(cellid); data=_dataset(cell,seed); role=only(unique(mr["role"] for mr in mrows)); env=_settings(joinpath(outdir,"environment_manifest.tsv"))
    final=joinpath(outdir,"datasets",phase,cellid,string(seed)); ispath(final) && error("dataset packet already exists")
    tmp=final*".tmp.$(getpid())"; mkpath(tmp)
    _write_table_exclusive(joinpath(tmp,"y.tsv"),["row","y"],
                           [[i,data.y[i]] for i in eachindex(data.y)])
    _write_table_exclusive(joinpath(tmp,"X.tsv"),
                           vcat("row",["x$(i)" for i in axes(data.X,2)]),
                           [vcat(i,collect(r)) for (i,r) in enumerate(eachrow(data.X))])
    _write_table_exclusive(joinpath(tmp,"K.tsv"),
                           vcat("row",["k$(i)" for i in axes(data.K,2)]),
                           [vcat(i,collect(r)) for (i,r) in enumerate(eachrow(data.K))])
    metadata=Dict("schema_version"=>SCHEMA_VERSION,"phase"=>phase,"cell_id"=>cellid,"seed"=>string(seed),"role"=>role,
      "n"=>string(cell.n),"p"=>string(size(data.X,2)),"m"=>string(cell.m),"ridge"=>string(RIDGE),
      "marker_hash"=>data.marker_hash,"id_hash"=>data.id_hash,"kernel_hash"=>data.kernel_hash,
      "doc45_commit"=>DOC45_COMMIT,"doc45_sha256"=>DOC45_SHA256,"doc45a_commit"=>DOC45A_COMMIT,
      "doc45a_sha256"=>DOC45A_SHA256,"doc45b_commit"=>env["doc45b_commit"],"doc45b_sha256"=>env["doc45b_sha256"],
      "execution_commit"=>env["execution_commit"])
    _write_table_exclusive(joinpath(tmp,"metadata.tsv"),["key","value"],[[k,metadata[k]] for k in METADATA_KEYS])
    _write_table_exclusive(joinpath(tmp,"arms.tsv"),RAW_COLUMNS,rawrows)
    files=["K.tsv","X.tsv","arms.tsv","metadata.tsv","y.tsv"]
    _write_table_exclusive(joinpath(tmp,"files.sha256.tsv"),["relative_path","sha256"],
                           [[f,_sha256_file(joinpath(tmp,f))] for f in files])
    mkpath(dirname(final)); mv(tmp,final;force=false); println("sealed $(final)")
end

function _validate_packet(outdir,phase,cell,seed)
    dir=joinpath(outdir,"datasets",phase,cell,string(seed)); rows=_read_table(joinpath(dir,"files.sha256.tsv"),["relative_path","sha256"])
    [r[1] for r in rows]==["K.tsv","X.tsv","arms.tsv","metadata.tsv","y.tsv"] || error("packet file-set/order drift")
    all(_sha256_file(joinpath(dir,r[1]))==r[2] for r in rows) || error("packet checksum mismatch")
    (_sha256_file(joinpath(dir,"files.sha256.tsv")),dir)
end

function _oracle_rows(outdir,phase,cell,seed,manifest)
    digest,packet=_validate_packet(outdir,phase,cell,seed); path=joinpath(outdir,"oracle",phase,cell,"$(seed).tsv")
    _validate_sidecar(path); rows=_read_table(path,FINAL_COLUMNS); raw=_read_table(joinpath(packet,"arms.tsv"),RAW_COLUMNS)
    length(rows)==length(raw) || error("oracle/raw arm count mismatch")
    for i in eachindex(rows)
        rows[i][1:30]==raw[i] || error("oracle changed/reordered copied raw fields")
        rows[i][42]==digest || error("oracle dataset digest mismatch")
    end
    present=Set(k[3] for k in keys(manifest) if k[1]==cell && k[2]==seed)
    expected=[a.arm_id for a in ATOMIC_ARMS if a.arm_id in present]
    [r[5] for r in rows]==expected || error("oracle arm set/order mismatch")
    rows
end

function verify_mode(args)
    outdir=abspath(_required(args,"out-dir")); phase=String(_required(args,"phase"))
    phase in ("discovery","holdout") || error("invalid phase")
    cell=String(_required(args,"cell")); seed=parse(Int,_required(args,"seed"))
    manifest=_manifest(outdir,phase)
    rows=_oracle_rows(outdir,phase,cell,seed,manifest)
    println("verified $(length(rows)) oracle rows for $(phase)/$(cell)/$(seed)")
end

_asdict(row)=Dict(FINAL_COLUMNS .=> row)
_parsebool(x)=lowercase(x)=="true"

function _policy_winner(rows,policy)
    candidates=[_asdict(r) for r in rows if parse(Int,r[6])==policy.cap && parse(Int,r[7])==policy.em_warmup && r[8] in policy.starts]
    length(candidates)==length(policy.starts) || error("policy atomic attempt missing")
    order=Dict(s=>i for (i,s) in enumerate(policy.starts))
    n=_cell(first(candidates)["cell_id"]).n
    sort!(candidates;by=d->begin
        objective=tryparse(Float64,d["julia_objective"])
        (objective===nothing || !isfinite(objective) ? Inf : objective, order[d["start_id"]])
    end)
    # Ties use the frozen start order, not floating-point sort accidents.
    best=first(candidates)
    isfinite(parse(Float64,best["julia_objective"])) || return best
    tied=filter(d->abs(parse(Float64,d["julia_objective"])-parse(Float64,best["julia_objective"]))/n<=1e-10,candidates)
    sort!(tied;by=d->order[d["start_id"]]); first(tied)
end

function _discovery_digest(outdir,oracle_sets)
    io=IOBuffer()
    for path in sort(vcat([joinpath(outdir,"oracle","discovery",c,"$(s).tsv") for (c,s) in keys(oracle_sets)],
                          [joinpath(outdir,"datasets","discovery",c,string(s),"arms.tsv") for (c,s) in keys(oracle_sets)]))
        print(io,relpath(path,outdir),'\t',_sha256_file(path),'\n')
    end
    bytes2hex(sha256(take!(io)))
end

function summarize_discovery(outdir,manifest)
    datasets=sort(unique((k[1],k[2]) for k in keys(manifest)))
    oracle=Dict(ds=>_oracle_rows(outdir,"discovery",ds[1],ds[2],manifest) for ds in datasets)
    classes=Dict(ds=>only(unique(r[31] for r in oracle[ds])) for ds in datasets)
    any(v=="oracle_unresolved" for v in values(classes)) && return _seal_negative(outdir,"NO_POLICY_SELECTED",_discovery_digest(outdir,oracle))
    if any(classes[ds] in ("lower_boundary","upper_boundary") && manifest[(ds[1],ds[2],first(k[3] for k in keys(manifest) if k[1]==ds[1]&&k[2]==ds[2]))]["role"]=="failure" for ds in datasets)
        return _seal_negative(outdir,"BOUNDARY_POLICY_REQUIRED",_discovery_digest(outdir,oracle))
    end
    selected=""
    policy_summary=Vector{Vector{Any}}()
    for policy in POLICY_ORDER
        winners=Dict(ds=>_policy_winner(oracle[ds],policy) for ds in datasets)
        valid=all(classes[ds]=="interior_oracle" && _parsebool(winners[ds]["interior_agreement"]) for ds in datasets)
        attempts=[_asdict(r) for ds in datasets for r in oracle[ds]
                  if parse(Int,r[6])==policy.cap && parse(Int,r[7])==policy.em_warmup && r[8] in policy.starts]
        total_factorizations=sum(parse(Int,d["factorizations"]) for d in attempts)
        total_runtime=sum(parse(Float64,d["runtime_seconds"]) for d in attempts)
        push!(policy_summary,Any[policy.id,valid,count(ds->_parsebool(winners[ds]["interior_agreement"]),datasets),
                                length(datasets),total_factorizations,total_runtime])
        valid && isempty(selected) && (selected=policy.id)
    end
    _write_table_exclusive(joinpath(outdir,"discovery_policy_summary.tsv"),
      ["policy_id","eligible","n_agree","n_datasets","total_factorizations","total_runtime_seconds"],policy_summary)
    digest=_discovery_digest(outdir,oracle)
    isempty(selected) ? _seal_negative(outdir,"NO_POLICY_SELECTED",digest) : _write_candidate_seal(outdir,"POLICY_SELECTED",selected,digest)
end

function _write_candidate_seal(outdir,outcome,policy,digest)
    env=_settings(joinpath(outdir,"environment_manifest.tsv")); path=joinpath(outdir,"candidate_seal.tsv")
    _write_table_exclusive(path,["outcome","policy_id","discovery_digest","execution_commit"],[[outcome,policy,digest,env["execution_commit"]]]); _write_sidecar(path)
    println("$(outcome) $(policy)")
end
_seal_negative(outdir,outcome,digest)=_write_candidate_seal(outdir,outcome,"NA",digest)

function _binomial_upper(w,n,p)
    w==0 && return 1.0
    logchoose=sum(log(i) for i in (n-w+1):n)-sum(log(i) for i in 1:w)
    term=exp(logchoose+w*log(p)+(n-w)*log1p(-p)); total=term
    for k in w:(n-1)
        term *= (n-k)/(k+1)*p/(1-p)
        total += term
    end
    total
end

function _cp_lower(w,n)
    w==0 && return 0.0
    lo=0.0; hi=1.0
    for _ in 1:100
        mid=(lo+hi)/2
        _binomial_upper(w,n,mid)>0.05 ? (hi=mid) : (lo=mid)
    end
    (lo+hi)/2
end

function _p95(x)
    y=sort(x); y[clamp(ceil(Int,0.95length(y)),1,length(y))]
end

function summarize_holdout(outdir,manifest)
    seal=_candidate_seal(outdir); seal.outcome=="POLICY_SELECTED" || error("no positive sealed candidate")
    policy=_policy(seal.policy_id); datasets=sort(unique((k[1],k[2]) for k in keys(manifest)))
    W=L=0; losses=0; unresolved=false; boundary=false; candidate_times=Float64[]; default_times=Float64[]; cell_valid=Dict(c.id=>Int[] for c in CELLS)
    details=Vector{Vector{Any}}()
    for ds in datasets
        rows=_oracle_rows(outdir,"holdout",ds[1],ds[2],manifest); dicts=Dict(r[5]=>_asdict(r) for r in rows)
        default=dicts["C100_E0"]; candidate=_policy_winner(rows,policy); cls=default["oracle_class"]
        unresolved |= cls=="oracle_unresolved"; boundary |= cls in ("lower_boundary","upper_boundary")
        dv=cls=="interior_oracle" && _parsebool(default["interior_agreement"]); cv=cls=="interior_oracle" && _parsebool(candidate["interior_agreement"])
        W += cv&&!dv; L += dv&&!cv; losses += dv&&!cv
        cls=="interior_oracle" && push!(cell_valid[ds[1]],cv ? 1 : 0)
        push!(default_times,parse(Float64,default["runtime_seconds"]))
        cattempts=[_asdict(r) for r in rows if parse(Int,r[6])==policy.cap && parse(Int,r[7])==policy.em_warmup && r[8] in policy.starts]
        push!(candidate_times,sum(parse(Float64,d["runtime_seconds"]) for d in cattempts))
        push!(details,Any[ds[1],ds[2],cls,dv,cv,cv&&!dv,dv&&!cv])
    end
    _write_table_exclusive(joinpath(outdir,"holdout_pair_summary.tsv"),["cell_id","seed","oracle_class","default_valid","candidate_valid","win","loss"],details)
    rates_ok=all(!isempty(v) && sum(v)/length(v)>=0.95 for v in values(cell_valid)); discord=W+L; cp=discord==0 ? 0.0 : _cp_lower(W,discord)
    runtime_ok=_p95(candidate_times)<=3*_p95(default_times)
    pass=!unresolved && !boundary && losses==0 && discord>0 && cp>0.5 && rates_ok && runtime_ok
    _write_table_exclusive(joinpath(outdir,"holdout_gate.tsv"),["outcome","wins","losses","discordant","cp_lower","net_gain","rates_ok","runtime_ok"],
      [[pass ? "PASS" : "FAIL",W,L,discord,cp,(W-L)/240,rates_ok,runtime_ok]])
    println(pass ? "HOLDOUT_PASS" : "HOLDOUT_FAIL")
end

function summarize_mode(args)
    outdir=abspath(_required(args,"out-dir")); phase=String(_required(args,"phase")); manifest=_manifest(outdir,phase)
    phase=="discovery" ? summarize_discovery(outdir,manifest) : phase=="holdout" ? summarize_holdout(outdir,manifest) : error("invalid phase")
end

function _must_fail(label,f)
    failed=false; try f() catch; failed=true end
    failed || error("negative control stayed green: $(label)")
end

function selftest_mode()
    _assert_seed_contract(); length(ATOMIC_ARMS)==16 || error("atomic arm count drift"); length(POLICY_ORDER)==20 || error("policy order drift")
    _opt(["--phase=discovery"],"phase")=="discovery" || error("equals-form parser drift")
    _opt(["--phase","holdout"],"phase")=="holdout" || error("split-form parser drift")
    _required(["--phase","holdout"],"phase")=="holdout" || error("required parser drift")
    _must_fail("missing split-form value") do
        _opt(["--phase"],"phase")
    end
    first(getproperty.(POLICY_ORDER,:id))=="C100_E0" && last(getproperty.(POLICY_ORDER,:id))=="M_C1000_E5" || error("policy order endpoints drift")
    length(unique(getproperty.(ATOMIC_ARMS,:arm_id)))==16 || error("duplicate arm IDs")
    sample=Dict(MANIFEST_COLUMNS .=> ["discovery","n120_m600_r020","2027130002","failure","C100_E0","100","0","current","120","600","0.01","m","i","k"])
    raw=["discovery","n120_m600_r020","2027130002","failure","C100_E0","100","0","current","1","1"]
    append!(raw,["false","iteration_limit","100","0","100","0","1","1","0.5","10","1","1","0.1","1","1","1","fit_not_converged","m","i","k"])
    _validate_raw(raw,sample)
    _must_fail("termination mutation") do
        _validate_raw(vcat(raw[1:11],["invented"],raw[13:end]),sample)
    end
    _must_fail("seed mutation") do
        _validate_raw(vcat(raw[1:2],["9"],raw[4:end]),sample)
    end
    _must_fail("hash mutation") do
        _validate_raw(vcat(raw[1:27],["bad"],raw[29:end]),sample)
    end
    mktempdir() do dir
        path=joinpath(dir,"row.tsv")
        _write_table_exclusive(path,RAW_COLUMNS,[raw]); _write_sidecar(path); _validate_sidecar(path)
        _must_fail("create-once overwrite") do
            _write_table_exclusive(path,RAW_COLUMNS,[raw])
        end
        open(path,"a") do io; println(io,"mutated objective") end
        _must_fail("objective/checksum mutation") do
            _validate_sidecar(path)
        end
        _must_fail("holdout before candidate seal") do
            _candidate_seal(dir)
        end
    end
    abs(_cp_lower(20,20)-0.8608916593)<1e-8 || error("Clopper-Pearson selftest failed")
    println("selftest: PASS")
end

function main(args=ARGS)
    mode=String(_opt(args,"mode","run"))
    if mode=="manifest"
        phase=String(_required(args,"phase")); phase=="discovery" ? manifest_discovery(args) : phase=="holdout" ? manifest_holdout(args) : error("invalid phase")
    elseif mode=="run"; run_mode(args)
    elseif mode=="dataset"; dataset_mode(args)
    elseif mode=="verify"; verify_mode(args)
    elseif mode=="summarize"; summarize_mode(args)
    elseif mode=="selftest"; selftest_mode()
    else error("mode must be manifest, run, dataset, verify, summarize, or selftest")
    end
end

abspath(PROGRAM_FILE)==abspath(@__FILE__) && main()
