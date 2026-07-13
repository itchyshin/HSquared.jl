#!/usr/bin/env julia

# Independent, read-only recovery-v2 recomputer. It never generates a dataset or
# fits a model. The only write is one create-once Julia summary plus its digest.

using LinearAlgebra
using Printf
using SHA
using Statistics

const SCHEMA = "v07-genomic-recovery-v2"
const RIDGE = 0.01
const BOUNDARY_EPSILON = 1e-7
const BOUNDARY_KKT_TOLERANCE = 1e-8
const Z975 = 1.959963984540054
const MIN_CONFIRM = 200
const MAX_CONFIRM = 2000
const RESOLVED = ("boundary_lower", "boundary_upper", "interior", "interior_rescued")
const STATUS_REASON = Dict(
    "boundary_lower" => "boundary_lower",
    "boundary_upper" => "boundary_upper",
    "interior" => "ai_interior",
    "interior_rescued" => "profile_interior",
)
const R_COMMIT = "10efc7c58e94da230cbb224b8d2f0698e2550665"
const JULIA_SELECTED_COMMIT = "fc9d39df650b20aa09d769d9f9528eed1b606f1e"

const CELLS = [
    (id="n120_m600_r020", index=1, n=120, m=600, ratio=0.2, regime="marker_rich_n120"),
    (id="n120_m600_r050", index=2, n=120, m=600, ratio=0.5, regime="marker_rich_n120"),
    (id="n120_m600_r080", index=3, n=120, m=600, ratio=0.8, regime="marker_rich_n120"),
    (id="n300_m150_r020", index=4, n=300, m=150, ratio=0.2, regime="marker_limited"),
    (id="n300_m150_r050", index=5, n=300, m=150, ratio=0.5, regime="marker_limited"),
    (id="n300_m150_r080", index=6, n=300, m=150, ratio=0.8, regime="marker_limited"),
    (id="n300_m1000_r020", index=7, n=300, m=1000, ratio=0.2, regime="marker_rich_n300"),
    (id="n300_m1000_r050", index=8, n=300, m=1000, ratio=0.5, regime="marker_rich_n300"),
    (id="n300_m1000_r080", index=9, n=300, m=1000, ratio=0.8, regime="marker_rich_n300"),
]

const MANIFEST_COLUMNS = split("tier cell_id cell_index seed_offset seed n m truth_sigma_g2 truth_sigma_e2 truth_ratio ridge regime")
const ATTEMPT_COLUMNS = split("tier cell_id cell_index seed_offset seed n m truth_sigma_g2 truth_sigma_e2 truth_ratio ridge attempted status error_class converged boundary_status boundary_reason boundary_epsilon scientific_sigma_g2 scientific_sigma_e2 scientific_ratio fitted_total_variance numerical_sigma_g2 numerical_sigma_e2 numerical_ratio profile_loglik lower_derivative_per_observation upper_derivative_per_observation iterations objective gradient_norm runtime_seconds peak_rss_mb relationship_source relationship_method allele_frequency_source relationship_scale scale_denominator marker_hash id_hash kernel_hash precision_hash route r_implementation_commit julia_implementation_commit driver_commit seal_sha256")
const SUMMARY_COLUMNS = split("tier cell_id n_expected n_attempted n_converged n_bias_rows n_interior n_interior_rescued n_boundary_lower n_boundary_upper n_unresolved n_error n_resolved_valid convergence_rate wilson_lower wilson_upper target truth mean_estimate bias mcse pilot_sd_upper bias_ci_lower bias_ci_upper margin target_pass required_n_raw required_n cell_status campaign_status failure_classes")
const CORPUS_COLUMNS = ["relative_path", "sha256"]
const REVIEW_COLUMNS = split("schema_version reviewer verdict r_execution_commit julia_execution_commit reviewed_at_utc")
const ADMISSION_COLUMNS = split("schema_version r_execution_commit julia_execution_commit fisher_review_sha256 fisher_review_path grace_review_sha256 grace_review_path rose_review_sha256 rose_review_path reviewed_at_utc")
const PACKET_PRIMARIES = ["markers.tsv", "ids.tsv", "phenotype.tsv", "truth.tsv", "packet_files_lock.tsv"]
const SEAL_KEYS = split("schema_version driver_commit julia_execution_commit r_selected_tree julia_selected_tree driver_sha256 launcher_sha256 doc48_sha256 r_auto_route_commit r_oracle_commit julia_candidate_commit julia_holdout_commit holdout_checkpoint_commit candidate_seal_sha256 holdout_gate_sha256 holdout_timing_sha256 summary_files_lock_sha256 holdout_checkpoint_doc_sha256 holdout_checklog_sha256 r_recomputer_sha256 julia_recomputer_sha256 admission_receipt_sha256 admission_receipt_path output_root driver_root r_root julia_root host cpu_model machine kernel arch julia_version r_version r_libs juliacall_version pkgload_version juliacall_source_commit juliacall_source_archive juliacall_source_archive_sha256 juliacall_installed_tree_sha256 julia_dependency_manifest_sha256 julia_libunwind_sha256 julia_num_threads openblas_num_threads omp_num_threads veclib_maximum_threads seed_formula pilot_offsets confirmation_offsets excluded_offsets ridge relationship_method allele_frequency_source relationship_scale boundary_epsilon boundary_kkt_tolerance resolved_statuses output_absent_before_seal")

struct TSV
    columns::Vector{String}
    rows::Vector{Vector{String}}
end

_hex(s, n) = length(s) == n && all(c -> isdigit(c) || c in 'a':'f', s)
_sha256(path) = bytes2hex(sha256(read(path)))
_key(row) = (row.tier, row.cell_id, row.seed)
_cell(id) = only(filter(c -> c.id == id, CELLS))

function _option(args, key; default=nothing)
    prefix = "--$key="
    hits = filter(x -> startswith(x, prefix), args)
    length(hits) <= 1 || error("--$key must occur at most once")
    isempty(hits) ? default : split(only(hits), "="; limit=2)[2]
end

function _safe_root(path)
    isabspath(path) || error("--out-dir must be absolute")
    normpath(path) == path || error("--out-dir must be normalized")
    islink(path) && error("output root may not be a symlink")
    isdir(path) || error("missing output root: $path")
    realpath(path) == path || error("output root real path mismatch")
    path
end

function _plain(root, path; directory=false)
    ap = abspath(path)
    prefix = root * Base.Filesystem.path_separator
    (ap == root || startswith(ap, prefix)) || error("path escapes output root: $path")
    islink(ap) && error("symlink is forbidden: $ap")
    (directory ? isdir(ap) : isfile(ap)) || error("missing $(directory ? "directory" : "regular file"): $ap")
    realpath(ap) == ap || error("non-canonical path: $ap")
    ap
end

function _exact_entries(root, dir, expected)
    dir = _plain(root, dir; directory=true)
    actual = sort(readdir(dir))
    sort(String.(expected)) == actual || error("missing/additional entry in $dir")
    for name in actual
        islink(joinpath(dir, name)) && error("symlink is forbidden: $(joinpath(dir, name))")
    end
    nothing
end

function _verify_pair(root, path)
    path = _plain(root, path)
    sidecar = _plain(root, path * ".sha256")
    expected = "$(_sha256(path))  $(basename(path))\n"
    read(sidecar, String) == expected || error("checksum sidecar mismatch: $path")
    path
end

function _read_tsv(root, path, columns)
    path = _verify_pair(root, path)
    bytes = read(path)
    !isempty(bytes) && bytes[end] == 0x0a || error("TSV must end in LF: $path")
    0x0d in bytes && error("CR bytes are forbidden in TSV: $path")
    text = String(bytes)
    lines = split(chop(text; tail=1), '\n'; keepempty=true)
    !isempty(lines) && !isempty(lines[end]) || error("blank TSV row: $path")
    header = split(lines[1], '\t'; keepempty=true)
    header == columns || error("schema drift in $path")
    rows = Vector{Vector{String}}()
    for line in lines[2:end]
        fields = split(line, '\t'; keepempty=true)
        length(fields) == length(columns) || error("malformed TSV row in $path")
        push!(rows, fields)
    end
    TSV(header, rows)
end

function _read_external_tsv(path, columns)
    isabspath(path) && isfile(path) && !islink(path) && realpath(path) == path ||
        error("external receipt path is not canonical: $path")
    sidecar = path * ".sha256"
    isfile(sidecar) && !islink(sidecar) && realpath(sidecar) == sidecar ||
        error("external receipt sidecar is not canonical: $sidecar")
    read(sidecar, String) == "$(_sha256(path))  $(basename(path))\n" ||
        error("external receipt checksum mismatch: $path")
    bytes = read(path)
    !isempty(bytes) && bytes[end] == 0x0a || error("external receipt must end in LF: $path")
    0x0d in bytes && error("CR bytes are forbidden in external receipt: $path")
    lines = split(chop(String(bytes); tail=1), '\n'; keepempty=true)
    header = split(lines[1], '\t'; keepempty=true)
    header == columns || error("external receipt schema drift: $path")
    rows = [split(line, '\t'; keepempty=true) for line in lines[2:end]]
    all(length(row) == length(columns) for row in rows) || error("malformed external receipt row: $path")
    TSV(header, rows)
end

function _dict(table::TSV, row::Vector{String})
    Dict(table.columns[i] => row[i] for i in eachindex(table.columns))
end

function _int(x, field)
    occursin(r"^-?[0-9]+$", x) || error("$field is not an integer")
    parse(Int, x)
end
function _float(x, field; missing=false)
    if x in ("NA", "NaN")
        missing || error("$field may not be missing")
        return NaN
    end
    y = tryparse(Float64, x)
    y === nothing && error("$field is not numeric")
    y
end
function _bool(x, field)
    x == "true" && return true
    x == "false" && return false
    error("$field must be true/false")
end

function _read_seal(root)
    table = _read_tsv(root, joinpath(root, "campaign_seal.tsv"), ["key", "value"])
    length(table.rows) == length(SEAL_KEYS) || error("seal row count drift")
    keys = getindex.(table.rows, 1)
    keys == SEAL_KEYS && allunique(keys) || error("seal key/order drift")
    seal = Dict(r[1] => r[2] for r in table.rows)
    seal["schema_version"] == SCHEMA || error("seal schema drift")
    seal["r_auto_route_commit"] == R_COMMIT || error("R implementation binding drift")
    seal["julia_candidate_commit"] == JULIA_SELECTED_COMMIT || error("selected Julia implementation drift")
    seal["ridge"] == "0.01" || error("seal ridge drift")
    seal["relationship_method"] == "vanraden1" || error("seal relationship method drift")
    seal["allele_frequency_source"] == "sample" || error("seal frequency-source drift")
    seal["relationship_scale"] == "K_lambda" || error("seal relationship scale drift")
    seal["boundary_kkt_tolerance"] == "1e-08" || error("seal boundary KKT tolerance drift")
    seal["resolved_statuses"] == join(RESOLVED, ',') || error("seal resolved-status drift")
    seal["juliacall_version"] == "0.17.6" || error("seal JuliaCall version drift")
    seal["pkgload_version"] == "1.5.1" || error("seal pkgload version drift")
    seal["r_libs"] == "/home/snakagaw/R/v07-lib:/home/snakagaw/R/lib" ||
        error("seal R library path drift")
    seal["juliacall_source_commit"] == "947d1f3aaba5fec0f5cf61394869a5a47ffa7551" ||
        error("seal JuliaCall source commit drift")
    seal["juliacall_source_archive"] == "/home/snakagaw/R/v07-lib/sources/JuliaCall-947d1f3aaba5fec0f5cf61394869a5a47ffa7551.tar.gz" ||
        error("seal JuliaCall source archive drift")
    seal["juliacall_source_archive_sha256"] == "50b64935587342774bb2ee0ebba258af57e161579f858d7de3429034e18756c3" ||
        error("seal JuliaCall source archive hash drift")
    seal["juliacall_installed_tree_sha256"] == "811147c85b18af7319084714698f474c7b404d8ba20c0796acfce85c60c7f692" ||
        error("seal JuliaCall installed tree hash drift")
    seal["julia_dependency_manifest_sha256"] == "773b0b30edc7c6c799947fda10b24386f2d1b364448df82736b5d0ef909f74dc" ||
        error("seal Julia dependency manifest hash drift")
    seal["julia_libunwind_sha256"] == "a88a96958909da84881a565c8ea219535425db20a184b09d25968e45212ced94" ||
        error("seal Julia libunwind hash drift")
    seal["pilot_offsets"] == "7101:7148" || error("seal pilot offsets drift")
    seal["confirmation_offsets"] == "8001:10000" || error("seal confirmation offsets drift")
    seal["excluded_offsets"] == "1:48,1001:3000,5001:5048,6001:6048,7001:7048" ||
        error("seal excluded offsets drift")
    seal["output_root"] == root || error("output root differs from seal")
    for key in ("driver_commit", "julia_execution_commit", "r_selected_tree", "julia_selected_tree")
        _hex(seal[key], 40) || error("invalid $key in seal")
    end
    for key in ("driver_sha256", "launcher_sha256", "doc48_sha256", "r_recomputer_sha256",
                "julia_recomputer_sha256", "admission_receipt_sha256")
        _hex(seal[key], 64) || error("invalid/unsealed $key")
    end
    admission=seal["admission_receipt_path"]
    isabspath(admission)&&isfile(admission)&&!islink(admission)&&realpath(admission)==admission||
        error("execution admission receipt path is not canonical")
    _sha256(admission)==seal["admission_receipt_sha256"]||error("execution admission receipt differs from seal")
    atable = _read_external_tsv(admission, ADMISSION_COLUMNS)
    length(atable.rows) == 1 || error("execution admission must contain one row")
    a = _dict(atable, only(atable.rows))
    a["schema_version"] == "v07-genomic-recovery-v2-admission-2" || error("admission schema drift")
    a["r_execution_commit"] == seal["driver_commit"] &&
        a["julia_execution_commit"] == seal["julia_execution_commit"] ||
        error("admission execution-commit drift")
    occursin(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$", a["reviewed_at_utc"]) ||
        error("admission review time drift")
    for (key, label) in (("fisher", "Fisher"), ("grace", "Grace"), ("rose", "Rose"))
        path = a["$(key)_review_path"]
        _hex(a["$(key)_review_sha256"], 64) && _sha256(path) == a["$(key)_review_sha256"] ||
            error("$label review hash drift")
        rtable = _read_external_tsv(path, REVIEW_COLUMNS)
        length(rtable.rows) == 1 || error("$label review must contain one row")
        review = _dict(rtable, only(rtable.rows))
        review["schema_version"] == "v07-genomic-recovery-v2-review-1" &&
            review["reviewer"] == label && review["verdict"] == "CLEAN" &&
            review["r_execution_commit"] == seal["driver_commit"] &&
            review["julia_execution_commit"] == seal["julia_execution_commit"] &&
            occursin(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$", review["reviewed_at_utc"]) ||
            error("$label review does not attest CLEAN for sealed commits")
    end
    _sha256(abspath(@__FILE__)) == seal["julia_recomputer_sha256"] || error("Julia recomputer differs from seal")
    realpath(dirname(dirname(abspath(@__FILE__)))) == seal["julia_root"] || error("Julia recomputer checkout path differs from seal")
    seal
end

function _manifest_row(d)
    (tier=d["tier"], cell_id=d["cell_id"], cell_index=_int(d["cell_index"], "cell_index"),
     seed_offset=_int(d["seed_offset"], "seed_offset"), seed=_int(d["seed"], "seed"),
     n=_int(d["n"], "n"), m=_int(d["m"], "m"),
     truth_sigma_g2=_float(d["truth_sigma_g2"], "truth_sigma_g2"),
     truth_sigma_e2=_float(d["truth_sigma_e2"], "truth_sigma_e2"),
     truth_ratio=_float(d["truth_ratio"], "truth_ratio"), ridge=_float(d["ridge"], "ridge"),
     regime=d["regime"])
end

function _read_manifest(root, tier)
    tier in ("pilot", "confirm") || error("tier must be pilot or confirm")
    table = _read_tsv(root, joinpath(root, "$(tier)_manifest.tsv"), MANIFEST_COLUMNS)
    rows = [_manifest_row(_dict(table, r)) for r in table.rows]
    keys = _key.(rows)
    allunique(keys) || error("duplicate manifest key")
    expected_order = Tuple{String,Int}[]
    for c in CELLS
        cr = filter(r -> r.cell_id == c.id, rows)
        !isempty(cr) || error("manifest omits cell $(c.id)")
        offsets = getproperty.(cr, :seed_offset)
        if tier == "pilot"
            offsets == collect(7101:7148) || error("pilot membership/order drift for $(c.id)")
        else
            length(cr) in MIN_CONFIRM:MAX_CONFIRM || error("confirmation size outside 200:2000")
            offsets == collect(8001:(8000 + length(cr))) || error("confirmation prefix drift for $(c.id)")
        end
        for r in cr
            r.tier == tier && r.cell_index == c.index && r.n == c.n && r.m == c.m &&
                r.truth_sigma_g2 == c.ratio && r.truth_sigma_e2 == 1-c.ratio &&
                r.truth_ratio == c.ratio && r.ridge == RIDGE && r.regime == c.regime ||
                error("manifest/cell mismatch for $(_key(r))")
            r.seed == 2_027_120_000 + 10_000*c.index + r.seed_offset || error("seed formula drift")
            push!(expected_order, (c.id, r.seed))
        end
    end
    [(r.cell_id, r.seed) for r in rows] == expected_order || error("manifest row order drift")
    rows
end

function _attempt_row(d)
    numeric = k -> _float(d[k], k; missing=true)
    (tier=d["tier"], cell_id=d["cell_id"], cell_index=_int(d["cell_index"], "cell_index"),
     seed_offset=_int(d["seed_offset"], "seed_offset"), seed=_int(d["seed"], "seed"),
     n=_int(d["n"], "n"), m=_int(d["m"], "m"), truth_sigma_g2=numeric("truth_sigma_g2"),
     truth_sigma_e2=numeric("truth_sigma_e2"), truth_ratio=numeric("truth_ratio"), ridge=numeric("ridge"),
     attempted=_bool(d["attempted"], "attempted"), status=d["status"], error_class=d["error_class"],
     converged=_bool(d["converged"], "converged"), boundary_status=d["boundary_status"],
     boundary_reason=d["boundary_reason"], boundary_epsilon=numeric("boundary_epsilon"),
     scientific_sigma_g2=numeric("scientific_sigma_g2"), scientific_sigma_e2=numeric("scientific_sigma_e2"),
     scientific_ratio=numeric("scientific_ratio"), fitted_total_variance=numeric("fitted_total_variance"),
     numerical_sigma_g2=numeric("numerical_sigma_g2"), numerical_sigma_e2=numeric("numerical_sigma_e2"),
     numerical_ratio=numeric("numerical_ratio"), profile_loglik=numeric("profile_loglik"),
     lower_derivative=numeric("lower_derivative_per_observation"), upper_derivative=numeric("upper_derivative_per_observation"),
     iterations=numeric("iterations"), objective=numeric("objective"), gradient_norm=numeric("gradient_norm"),
     runtime_seconds=numeric("runtime_seconds"), peak_rss_mb=numeric("peak_rss_mb"),
     relationship_source=d["relationship_source"],
     relationship_method=d["relationship_method"], allele_frequency_source=d["allele_frequency_source"],
     relationship_scale=d["relationship_scale"], scale_denominator=numeric("scale_denominator"),
     marker_hash=d["marker_hash"], id_hash=d["id_hash"], kernel_hash=d["kernel_hash"],
     precision_hash=d["precision_hash"], route=d["route"], r_commit=d["r_implementation_commit"],
     julia_commit=d["julia_implementation_commit"], driver_commit=d["driver_commit"], seal_sha256=d["seal_sha256"])
end

function _write_u64(io, x::Integer)
    x >= 0 || error("negative canonical integer")
    write(io, htol(UInt64(x)))
end
function _write_string(io, x::String)
    b = codeunits(x); _write_u64(io, length(b)); write(io, b)
end
function _write_strings(io, xs)
    _write_u64(io, length(xs)); foreach(x -> _write_string(io, String(x)), xs)
end
function _write_float(io, value)
    x = Float64(value); isfinite(x) || error("nonfinite canonical value")
    x == 0.0 && (x = 0.0)
    _write_u64(io, reinterpret(UInt64, x))
end
function _fingerprint(writer, kind)
    io=IOBuffer(); write(io, codeunits("HSquared-provenance-v1\0")); write(io, codeunits(kind)); write(io, UInt8(0))
    writer(io); bytes2hex(sha256(take!(io)))
end
_id_hash(ids) = _fingerprint("id_order") do io; _write_strings(io, ids); end
function _marker_hash(M, ids, names)
    _fingerprint("markers") do io
        n,m=size(M); _write_u64(io,n); _write_u64(io,m); _write_strings(io,ids)
        write(io,UInt8(1)); _write_strings(io,names)
        foreach(x -> _write_float(io,x), M)
    end
end
function _matrix_hash(kind,A,ids)
    _fingerprint(kind) do io
        n,m=size(A); n==m || error("$kind is not square")
        _write_u64(io,n); _write_u64(io,m); _write_strings(io,ids); _write_strings(io,ids)
        foreach(x -> _write_float(io,x), A)
    end
end

function _packet_audit(root, tier, mr)
    dir = joinpath(root,"packets",tier,mr.cell_id,string(mr.seed))
    primary = PACKET_PRIMARIES
    _exact_entries(root,dir,vcat(primary,primary.*".sha256"))
    lock = _read_tsv(root,joinpath(dir,"packet_files_lock.tsv"),["file","sha256"])
    length(lock.rows)==4 || error("packet lock row count drift")
    getindex.(lock.rows,1)==primary[1:4] || error("packet lock order drift")
    for (i,name) in enumerate(primary[1:4])
        lock.rows[i][2] == _sha256(joinpath(dir,name)) || error("packet lock hash mismatch")
    end
    ids_t=_read_tsv(root,joinpath(dir,"ids.tsv"),["index","id"])
    length(ids_t.rows)==mr.n || error("ID packet row count drift")
    ids=String[]
    for (i,r) in enumerate(ids_t.rows)
        _int(r[1],"id index")==i || error("ID index/order drift"); !isempty(r[2]) || error("empty ID"); push!(ids,r[2])
    end
    allunique(ids) || error("duplicate packet ID")
    # Read the dynamic, named-marker schema after verifying its sealed pair.
    marker_path=_verify_pair(root,joinpath(dir,"markers.tsv")); marker_bytes=read(marker_path)
    !isempty(marker_bytes) && marker_bytes[end]==0x0a || error("marker TSV must end in LF")
    0x0d in marker_bytes && error("CR bytes are forbidden in marker TSV")
    text=String(marker_bytes); lines=split(chop(text;tail=1),'\n';keepempty=true)
    all(x->!isempty(x),lines) || error("blank marker TSV row")
    header=split(lines[1],'\t';keepempty=true); length(header)>=2 && header[1]=="id" || error("marker packet schema drift")
    names=header[2:end]
    allunique(names) && all(x->occursin(r"^m[0-9]{6}$",x),names) || error("invalid marker names")
    length(lines)-1==mr.n || error("marker row count drift")
    M=Matrix{Float64}(undef,mr.n,length(names))
    for i in 1:mr.n
        f=split(lines[i+1],'\t';keepempty=true); length(f)==length(header) || error("malformed marker row")
        f[1]==ids[i] || error("marker ID order drift")
        for j in eachindex(names)
            M[i,j]=_float(f[j+1],"marker dosage"); M[i,j] in (0.0,1.0,2.0) || error("non-hard-call marker")
        end
    end
    ph=_read_tsv(root,joinpath(dir,"phenotype.tsv"),["index","id","y"])
    length(ph.rows)==mr.n || error("phenotype row count drift")
    for (i,r) in enumerate(ph.rows)
        _int(r[1],"phenotype index")==i && r[2]==ids[i] && isfinite(_float(r[3],"y")) || error("phenotype order/value drift")
    end
    truth=_read_tsv(root,joinpath(dir,"truth.tsv"),["cell_id","seed","n","requested_m","retained_m","truth_sigma_g2","truth_sigma_e2","truth_ratio","ridge","scale_denominator"])
    length(truth.rows)==1 || error("truth packet row count drift"); tr=truth.rows[1]
    tr[1]==mr.cell_id && _int(tr[2],"truth seed")==mr.seed && _int(tr[3],"truth n")==mr.n &&
        _int(tr[4],"requested_m")==mr.m && _int(tr[5],"retained_m")==size(M,2) &&
        _float(tr[6],"truth sigma_g2")==mr.truth_sigma_g2 && _float(tr[7],"truth sigma_e2")==mr.truth_sigma_e2 &&
        _float(tr[8],"truth ratio")==mr.truth_ratio && _float(tr[9],"truth ridge")==RIDGE || error("truth packet identity drift")
    p=vec(sum(M,dims=1))./(2mr.n); W=M .- 2 .* transpose(p); k=2sum(p.*(1 .- p))
    k>0 && isfinite(k) || error("invalid VanRaden denominator")
    abs(_float(tr[10],"truth k")-k)<=1e-10 || error("truth scale denominator drift")
    G=(W*transpose(W))./k; K=Matrix{Float64}(G)+RIDGE*I; Q=Matrix{Float64}(inv(Symmetric(K)))
    maximum(abs.(Q*K-I))<=1e-10 || error("recomputed Q*K identity exceeds 1e-10")
    (k=k, marker_hash=_marker_hash(M,ids,names), id_hash=_id_hash(ids),
     kernel_hash=_matrix_hash("K_lambda",K,ids), precision_hash=_matrix_hash("Q_lambda",Q,ids))
end

function _validate_attempt(ar,mr,audit,seal,seal_hash)
    _key(ar)==_key(mr) || error("attempt/manifest key mismatch")
    for f in (:cell_index,:seed_offset,:n,:m,:truth_sigma_g2,:truth_sigma_e2,:truth_ratio,:ridge)
        getproperty(ar,f)==getproperty(mr,f) || error("attempt/manifest mismatch in $f")
    end
    ar.attempted || error("attempted must be true")
    isfinite(ar.runtime_seconds) && ar.runtime_seconds>=0 || error("invalid runtime")
    ar.driver_commit==seal["driver_commit"] && ar.seal_sha256==seal_hash || error("attempt seal/driver binding drift")
    ar.r_commit==R_COMMIT && ar.julia_commit==JULIA_SELECTED_COMMIT && ar.route=="ordinary_auto_genomic" || error("attempt implementation/route drift")
    ar.status in ("success","fit_error") || error("unknown attempt status")
    good=ar.status=="success"
    good==ar.converged || error("status/convergence mismatch")
    (good ? ar.error_class=="none" : ar.error_class!="none") || error("status/failure mismatch")
    if good
        ar.boundary_status in RESOLVED || error("successful unresolved boundary")
        ar.boundary_reason==STATUS_REASON[ar.boundary_status] || error("boundary status/reason mismatch")
        ar.boundary_epsilon==BOUNDARY_EPSILON || error("boundary epsilon drift")
        all(isfinite,(ar.scientific_sigma_g2,ar.scientific_sigma_e2,ar.scientific_ratio,
            ar.numerical_sigma_g2,ar.numerical_sigma_e2,ar.profile_loglik,ar.lower_derivative,ar.upper_derivative)) || error("nonfinite successful evidence")
        ratio = ar.boundary_status=="boundary_lower" ? 0.0 : ar.boundary_status=="boundary_upper" ? 1.0 : ar.scientific_ratio
        total = ar.numerical_sigma_g2 + ar.numerical_sigma_e2
        total>=0 && abs(total-ar.fitted_total_variance)<=1e-12 || error("fitted total is not numerical sg+se")
        total>0 && abs(ar.numerical_ratio-ar.numerical_sigma_g2/total)<=1e-12 || error("numerical ratio/component drift")
        ar.boundary_status=="boundary_lower" && ar.numerical_ratio!=BOUNDARY_EPSILON && error("lower endpoint numerical ratio drift")
        ar.boundary_status=="boundary_upper" && ar.numerical_ratio!=1-BOUNDARY_EPSILON && error("upper endpoint numerical ratio drift")
        ar.boundary_status in ("interior", "interior_rescued") && !(0 < ar.scientific_ratio < 1) &&
            error("interior scientific ratio is not strictly inside (0,1)")
        ar.boundary_status=="boundary_lower" && ar.lower_derivative>BOUNDARY_KKT_TOLERANCE &&
            error("lower-boundary KKT derivative sign drift")
        ar.boundary_status=="boundary_upper" && ar.upper_derivative < -BOUNDARY_KKT_TOLERANCE &&
            error("upper-boundary KKT derivative sign drift")
        ar.boundary_status in ("interior", "interior_rescued") &&
            !(ar.lower_derivative>BOUNDARY_KKT_TOLERANCE && ar.upper_derivative < -BOUNDARY_KKT_TOLERANCE) &&
            error("interior KKT derivative signs drift")
        all(x -> isnan(x) || isfinite(x), (ar.iterations, ar.objective, ar.gradient_norm, ar.peak_rss_mb)) ||
            error("retained diagnostic is infinite")
        abs(ar.scientific_ratio-ratio)<=1e-12 && abs(ar.scientific_sigma_g2-ratio*total)<=1e-12 &&
            abs(ar.scientific_sigma_e2-(1-ratio)*total)<=1e-12 || error("scientific endpoint derivation drift")
        ar.relationship_source=="markers" && ar.relationship_method=="vanraden1" &&
            ar.allele_frequency_source=="sample" && ar.relationship_scale=="K_lambda" || error("relationship provenance drift")
        abs(ar.scale_denominator-audit.k)<=1e-10 || error("attempt scale denominator drift")
        ar.marker_hash==audit.marker_hash && ar.id_hash==audit.id_hash && ar.kernel_hash==audit.kernel_hash &&
            ar.precision_hash==audit.precision_hash || error("independent fingerprint reconstruction mismatch")
        return merge(ar,(derived_sigma_g2=ratio*total,derived_sigma_e2=(1-ratio)*total,derived_ratio=ratio,resolved_valid=true))
    end
    if ar.boundary_status=="boundary_unresolved"
        ar.error_class=="boundary_unresolved" || error("unresolved status/failure-class mismatch")
        ar.boundary_reason!="NA" || error("unresolved boundary lacks reason")
    end
    merge(ar,(derived_sigma_g2=NaN,derived_sigma_e2=NaN,derived_ratio=NaN,resolved_valid=false))
end

function _corpus_entries(root, tier, manifest)
    paths = String[joinpath(root, "$(tier)_manifest.tsv")]
    for row in manifest
        push!(paths, joinpath(root, "attempts", tier, row.cell_id, "$(row.seed).tsv"))
        packet_root = joinpath(root, "packets", tier, row.cell_id, string(row.seed))
        append!(paths, joinpath.(Ref(packet_root), PACKET_PRIMARIES))
    end
    rows = Vector{Vector{String}}()
    for path in paths
        verified = _verify_pair(root, path)
        push!(rows, [relpath(verified, root), _sha256(verified)])
    end
    sort!(rows; by=first)
    allunique(first.(rows)) || error("duplicate corpus path")
    TSV(CORPUS_COLUMNS, rows)
end

function _verify_corpus_lock(root, tier, manifest)
    observed = _read_tsv(root, joinpath(root, "$(tier)_corpus_lock.tsv"), CORPUS_COLUMNS)
    expected = _corpus_entries(root, tier, manifest)
    observed.rows == expected.rows || error("current corpus differs from sealed lock")
    nothing
end

function _load_attempts(root,tier,manifest,seal)
    cells=unique(getproperty.(manifest,:cell_id)); _exact_entries(root,joinpath(root,"attempts",tier),cells)
    _exact_entries(root,joinpath(root,"packets",tier),cells)
    seal_hash=_sha256(joinpath(root,"campaign_seal.tsv")); out=NamedTuple[]
    for cell in cells
        mr=filter(r->r.cell_id==cell,manifest); names=string.(getproperty.(mr,:seed))
        _exact_entries(root,joinpath(root,"attempts",tier,cell),sort(vcat(names.*".tsv",names.*".tsv.sha256")))
        _exact_entries(root,joinpath(root,"packets",tier,cell),sort(names))
        for row in mr
            path=joinpath(root,"attempts",tier,cell,"$(row.seed).tsv")
            t=_read_tsv(root,path,ATTEMPT_COLUMNS); length(t.rows)==1 || error("attempt file must have one row")
            ar=_attempt_row(_dict(t,t.rows[1])); audit=_packet_audit(root,tier,row)
            push!(out,_validate_attempt(ar,row,audit,seal,seal_hash))
        end
    end
    length(out)==length(manifest) && allunique(_key.(out)) || error("attempt denominator/duplicate drift")
    out
end

# Dependency-free distribution quantiles, independently evaluated from the R harness.
function _loggamma(z)
    c=(0.99999999999980993,676.5203681218851,-1259.1392167224028,771.32342877765313,-176.61502916214059,12.507343278686905,-0.13857109526572012,9.984369578019572e-6,1.5056327351493116e-7)
    z<0.5 && return log(pi)-log(sinpi(z))-_loggamma(1-z)
    x=c[1]; q=z-1; for i in 2:length(c); x+=c[i]/(q+i-1); end; t=q+7.5
    0.5log(2pi)+(q+0.5)*log(t)-t+log(x)
end
function _betacf(a,b,x)
    qab=a+b;qap=a+1;qam=a-1;c=1.0;d=1-qab*x/qap;abs(d)<floatmin(Float64)&&(d=floatmin(Float64));d=1/d;h=d
    for m in 1:10000
        m2=2m;aa=m*(b-m)*x/((qam+m2)*(a+m2));d=1+aa*d;abs(d)<floatmin(Float64)&&(d=floatmin(Float64));c=1+aa/c;abs(c)<floatmin(Float64)&&(c=floatmin(Float64));d=1/d;h*=d*c
        aa=-(a+m)*(qab+m)*x/((a+m2)*(qap+m2));d=1+aa*d;abs(d)<floatmin(Float64)&&(d=floatmin(Float64));c=1+aa/c;abs(c)<floatmin(Float64)&&(c=floatmin(Float64));d=1/d;del=d*c;h*=del;abs(del-1)<2e-15&&break
    end;h
end
function _ibeta(a,b,x)
    x<=0&&return 0.0;x>=1&&return 1.0;bt=exp(_loggamma(a+b)-_loggamma(a)-_loggamma(b)+a*log(x)+b*log1p(-x))
    x<(a+1)/(a+b+2) ? bt*_betacf(a,b,x)/a : 1-bt*_betacf(b,a,1-x)/b
end
_tcdf(t,df)=t==0 ? 0.5 : t>0 ? 1-0.5*_ibeta(df/2,0.5,df/(df+t*t)) : 0.5*_ibeta(df/2,0.5,df/(df+t*t))
function _tquantile(p,df)
    lo,hi=-1.0,1.0;while _tcdf(lo,df)>p;lo*=2;end;while _tcdf(hi,df)<p;hi*=2;end
    for _ in 1:120;mid=(lo+hi)/2;_tcdf(mid,df)<p ? (lo=mid) : (hi=mid);end;(lo+hi)/2
end
function _gamma_p(a,x)
    x==0&&return 0.0
    if x<a+1
        ap=a;term=sum=1/a;for _ in 1:10000;ap+=1;term*=x/ap;sum+=term;abs(term)<=abs(sum)*2e-15&&break;end
        return sum*exp(-x+a*log(x)-_loggamma(a))
    end
    b=x+1-a;c=1/floatmin(Float64);d=1/b;h=d
    for i in 1:10000;an=-i*(i-a);b+=2;d=an*d+b;abs(d)<floatmin(Float64)&&(d=floatmin(Float64));c=b+an/c;abs(c)<floatmin(Float64)&&(c=floatmin(Float64));d=1/d;delta=d*c;h*=delta;abs(delta-1)<=2e-15&&break;end
    1-exp(-x+a*log(x)-_loggamma(a))*h
end
_chisq_cdf(x,df)=_gamma_p(df/2,x/2)
function _chisq_quantile(p,df)
    lo=0.0;hi=max(1.0,Float64(df));while _chisq_cdf(hi,df)<p;hi*=2;end
    for _ in 1:140;mid=(lo+hi)/2;_chisq_cdf(mid,df)<p ? (lo=mid) : (hi=mid);end;(lo+hi)/2
end
_pilot_sd_upper(s,n)=s*sqrt((n-1)/_chisq_quantile(0.05,n-1))
function _wilson(k,n)
    p=k/n;den=1+Z975^2/n;center=(p+Z975^2/(2n))/den;half=Z975*sqrt(p*(1-p)/n+Z975^2/(4n^2))/den
    center-half,center+half
end

function _summarize(attempts,manifest,tier)
    rows=NamedTuple[]; statuses=Dict{String,String}()
    for cell in CELLS
        cr=filter(r->r.cell_id==cell.id,attempts); cm=filter(r->r.cell_id==cell.id,manifest)
        natt=length(cm); nresolved=count(r->r.resolved_valid,cr); nconv=nresolved
        counts=Dict(s=>count(r->r.resolved_valid&&r.boundary_status==s,cr) for s in RESOLVED)
        nunresolved=count(r->!r.resolved_valid&&r.boundary_status=="boundary_unresolved",cr)
        nerror=count(r->!r.resolved_valid&&r.boundary_status!="boundary_unresolved",cr)
        sum(values(counts))+nunresolved+nerror==natt || error("status-count partition drift")
        rate=nconv/natt;wl,wu=_wilson(nconv,natt)
        classes=join(["$x=$(count(r->r.error_class==x,cr))" for x in sort(unique(getproperty.(cr,:error_class)))],";")
        specs=(("sigma_g2",:derived_sigma_g2,cell.ratio,0.05cell.ratio),("sigma_e2",:derived_sigma_e2,1-cell.ratio,0.05(1-cell.ratio)),("ratio",:derived_ratio,cell.ratio,0.02))
        stats=NamedTuple[]
        for (target,field,truth,margin) in specs
            vals=Float64[getproperty(r,field) for r in cr if r.resolved_valid]
            mn=length(vals)>=2 ? mean(vals) : NaN; bias=mn-truth; sdv=length(vals)>=2 ? std(vals) : NaN; mcse=sdv/sqrt(length(vals))
            if tier=="pilot" && isfinite(sdv)
                su=_pilot_sd_upper(sdv,length(vals));raw=ceil(Int,(Z975*su/(margin/2))^2);push!(stats,(target=target,truth=truth,mean=mn,bias=bias,mcse=mcse,su=su,lo=NaN,hi=NaN,pass=false,raw=raw,margin=margin))
            elseif tier=="confirm" && isfinite(mcse)
                q=_tquantile(0.975,length(vals)-1);lo=bias-q*mcse;hi=bias+q*mcse;push!(stats,(target=target,truth=truth,mean=mn,bias=bias,mcse=mcse,su=NaN,lo=lo,hi=hi,pass=lo>-margin&&hi<margin,raw=0,margin=margin))
            else
                push!(stats,(target=target,truth=truth,mean=mn,bias=bias,mcse=mcse,su=NaN,lo=NaN,hi=NaN,pass=false,raw=typemax(Int),margin=margin))
            end
        end
        rawmax=maximum(s.raw for s in stats);required=rawmax==typemax(Int) ? Inf : max(MIN_CONFIRM,rawmax)
        status=tier=="pilot" ? (nconv<46 ? "STOP_LOW_PILOT_CONVERGENCE" : required>MAX_CONFIRM ? "PRECISION_BLOCKER" : "CONFIRMATION_ELIGIBLE") :
            (all(s.pass for s in stats)&&rate>=0.95&&wl>=0.90 ? "PASS" : "FAIL")
        statuses[cell.id]=status
        common=(tier=tier,cell_id=cell.id,n_expected=natt,n_attempted=natt,n_converged=nconv,n_bias_rows=nconv,n_interior=counts["interior"],n_interior_rescued=counts["interior_rescued"],n_boundary_lower=counts["boundary_lower"],n_boundary_upper=counts["boundary_upper"],n_unresolved=nunresolved,n_error=nerror,n_resolved_valid=nresolved,convergence_rate=rate,wilson_lower=wl,wilson_upper=wu)
        for s in stats;push!(rows,merge(common,(target=s.target,truth=s.truth,mean_estimate=s.mean,bias=s.bias,mcse=s.mcse,pilot_sd_upper=s.su,bias_ci_lower=s.lo,bias_ci_upper=s.hi,margin=s.margin,target_pass=s.pass,required_n_raw=s.raw==typemax(Int) ? Inf : s.raw,required_n=required,cell_status=status,campaign_status="PENDING",failure_classes=classes)));end
    end
    campaign=tier=="pilot" ? (any(==("STOP_LOW_PILOT_CONVERGENCE"),values(statuses)) ? "STOP_LOW_PILOT_CONVERGENCE" : any(==("PRECISION_BLOCKER"),values(statuses)) ? "PRECISION_BLOCKER" : "CONFIRMATION_ELIGIBLE") : (all(==("PASS"),values(statuses)) ? "PASS" : "FAIL")
    [merge(r,(campaign_status=campaign,)) for r in rows]
end

_format(x::Bool)=x ? "true" : "false"
_format(x::Integer)=string(x)
_format(x::AbstractFloat)=isnan(x) ? "NA" : isinf(x) ? (x>0 ? "Inf" : "-Inf") : @sprintf("%.17g",x)
_format(x)=string(x)
function _summary_text(rows)
    io=IOBuffer();println(io,join(SUMMARY_COLUMNS,'\t'))
    for r in rows;println(io,join((_format(getproperty(r,Symbol(c))) for c in SUMMARY_COLUMNS),'\t'));end
    String(take!(io))
end
function _write_once(path,text)
    (ispath(path)||ispath(path*".sha256"))&&error("create-once summary exists: $path")
    tmp=tempname(dirname(path));open(tmp,"w") do io;write(io,text);end
    try Base.Filesystem.hardlink(tmp,path) catch;rm(tmp;force=true);rethrow();end;rm(tmp;force=true)
    digest=_sha256(path);side=path*".sha256";tmp=tempname(dirname(path));open(tmp,"w") do io;print(io,"$digest  $(basename(path))\n");end
    try Base.Filesystem.hardlink(tmp,side) catch;rm(tmp;force=true);rethrow();end;rm(tmp;force=true);nothing
end

function recompute(outdir,tier)
    root=_safe_root(outdir);seal=_read_seal(root);manifest=_read_manifest(root,tier)
    _verify_corpus_lock(root,tier,manifest)
    attempts=_load_attempts(root,tier,manifest,seal)
    _verify_corpus_lock(root,tier,manifest)
    rows=_summarize(attempts,manifest,tier);length(rows)==27||error("summary must have 27 rows")
    path=joinpath(root,"$(tier)_summary_julia.tsv");_write_once(path,_summary_text(rows));println("wrote $path rows=27 campaign_status=$(rows[1].campaign_status)")
end

function _must_fail(label,f)
    failed=false;try f() catch;failed=true end;failed||error("mutation stayed green: $label")
end
function selftest()
    abs(_tquantile(0.975,47)-2.0117405137297655)<1e-12||error("t quantile selftest")
    abs(_chisq_quantile(0.05,47)-32.2676215299732)<1e-10||error("chi-square quantile selftest")
    abs(_pilot_sd_upper(1.0,48)-1.206883783222356)<1e-12||error("upper SD selftest")
    wl,wu=_wilson(46,48);abs(wl-0.8602434412954456)<1e-12||error("Wilson selftest");wl<wu||error("Wilson ordering")
    ids=["g000001","g000002"];M=[0.0 1.0;2.0 1.0];names=["m000001","m000002"]
    _id_hash(ids)!=_id_hash(reverse(ids))||error("ID mutation stayed green")
    _marker_hash(M,ids,names)!=_marker_hash(copy(M).+[0.0 0.0;0.0 1.0],ids,names)||error("estimate/marker mutation stayed green")
    K=[1.01 0.2;0.2 1.01];Q=inv(Symmetric(K));maximum(abs.(Q*K-I))<=1e-10||error("QK selftest")
    _matrix_hash("K_lambda",K,ids)!=_matrix_hash("K_lambda",K[[2,1],[2,1]],reverse(ids))||error("matrix ID mutation stayed green")
    mr=(tier="pilot",cell_id="synthetic",cell_index=1,seed_offset=17,seed=123,n=2,m=2,
        truth_sigma_g2=0.5,truth_sigma_e2=0.5,truth_ratio=0.5,ridge=RIDGE,regime="synthetic")
    audit=(k=1.0,marker_hash=_marker_hash(M,ids,names),id_hash=_id_hash(ids),
        kernel_hash=_matrix_hash("K_lambda",K,ids),precision_hash=_matrix_hash("Q_lambda",Q,ids))
    sealhash=repeat("a",64);seal=Dict("driver_commit"=>repeat("b",40))
    ar=(tier="pilot",cell_id="synthetic",cell_index=1,seed_offset=17,seed=123,n=2,m=2,
        truth_sigma_g2=0.5,truth_sigma_e2=0.5,truth_ratio=0.5,ridge=RIDGE,attempted=true,
        status="success",error_class="none",converged=true,boundary_status="interior",
        boundary_reason="ai_interior",boundary_epsilon=BOUNDARY_EPSILON,
        scientific_sigma_g2=0.5,scientific_sigma_e2=0.5,scientific_ratio=0.5,fitted_total_variance=1.0,
        numerical_sigma_g2=0.5,numerical_sigma_e2=0.5,numerical_ratio=0.5,profile_loglik=-1.0,
        lower_derivative=0.1,upper_derivative=-0.1,iterations=8.0,objective=1.0,
        gradient_norm=1e-9,runtime_seconds=0.1,peak_rss_mb=100.0,
        relationship_source="markers",relationship_method="vanraden1",allele_frequency_source="sample",
        relationship_scale="K_lambda",scale_denominator=1.0,marker_hash=audit.marker_hash,
        id_hash=audit.id_hash,kernel_hash=audit.kernel_hash,precision_hash=audit.precision_hash,
        route="ordinary_auto_genomic",r_commit=R_COMMIT,julia_commit=JULIA_SELECTED_COMMIT,
        driver_commit=seal["driver_commit"],seal_sha256=sealhash)
    _validate_attempt(ar,mr,audit,seal,sealhash).resolved_valid || error("baseline attempt invalid")
    for (label,mutation) in (
        ("estimate",merge(ar,(scientific_sigma_g2=0.51,))),
        ("truth",merge(ar,(truth_ratio=0.6,))),
        ("seed",merge(ar,(seed=124,))),
        ("cell label",merge(ar,(cell_id="mutated",))),
        ("ridge",merge(ar,(ridge=0.02,))),
        ("fingerprint",merge(ar,(id_hash=repeat("0",64),))),
        ("attempt status",merge(ar,(status="fit_error",))),
        ("boundary reason",merge(ar,(boundary_reason="profile_interior",))),
        ("interior lower KKT sign",merge(ar,(lower_derivative=-1.0,))),
        ("interior upper KKT sign",merge(ar,(upper_derivative=1.0,))),
        ("tier membership",merge(ar,(tier="confirm",))))
        _must_fail(label) do;_validate_attempt(mutation,mr,audit,seal,sealhash);end
    end
    dir=mktempdir();try
        root=realpath(dir);path=joinpath(root,"x.tsv");_write_once(path,"x\n");_must_fail("create-once contender") do;_write_once(path,"x\n");end
        contested=joinpath(root,"contested.tsv")
        cmd=`$(Base.julia_cmd()) --startup-file=no $(abspath(@__FILE__)) --mode=claim-once --path=$contested`
        p1=run(ignorestatus(cmd);wait=false);p2=run(ignorestatus(cmd);wait=false);wait(p1);wait(p2)
        count(success,(p1,p2))==1||error("concurrent create-once test did not produce exactly one winner")
        _verify_pair(root,contested)
        review=joinpath(root,"review.tsv")
        review_text=join(REVIEW_COLUMNS,'\t')*"\n"*
            "v07-genomic-recovery-v2-review-1\tFisher\tCLEAN\t$(repeat("a",40))\t$(repeat("b",40))\t2026-07-13T20:00:00Z\n"
        _write_once(review,review_text)
        length(_read_external_tsv(review,REVIEW_COLUMNS).rows)==1||error("external review receipt selftest")
        open(review,"w") do io;write(io,"mutated\n");end
        _must_fail("mutated external review") do;_read_external_tsv(review,REVIEW_COLUMNS);end
        _verify_pair(root,path);open(path,"w") do io;write(io,"y\n");end;_must_fail("checksum corruption") do;_verify_pair(root,path);end
        rm(path*".sha256");_must_fail("orphan primary") do;_verify_pair(root,path);end
        link=joinpath(dir,"link");symlink(path,link);_must_fail("symlink") do;_plain(root,link);end
        _must_fail("additional output") do;_exact_entries(root,dir,["x.tsv","link"]);end
    finally rm(dir;recursive=true,force=true) end
    # Pure mutation controls for categorical/integer decisions and retained rows.
    keys=[("pilot","c",1),("pilot","c",2)];allunique(keys)||error("baseline duplicate")
    _must_fail("duplicate attempt") do;allunique([keys[1],keys[1]])||error("duplicate");end
    _must_fail("missing retained failure") do;Set(keys[1:1])==Set(keys)||error("missing");end
    _must_fail("seed membership") do;(7101 in 8001:10000)||error("tier membership");end
    println("v0.7 genomic recovery-v2 Julia recomputer selftest: PASS (synthetic only)")
end

function main(args=ARGS)
    mode=_option(args,"mode";default="recompute")
    mode=="selftest"&&return selftest()
    if mode=="claim-once"
        path=_option(args,"path");path===nothing&&error("--path is required")
        return _write_once(path,"claim\n")
    end
    mode=="recompute"||error("--mode must be recompute, selftest, or claim-once")
    out=_option(args,"out-dir");tier=_option(args,"tier");out===nothing&&error("--out-dir is required");tier===nothing&&error("--tier is required")
    recompute(out,tier)
end

abspath(PROGRAM_FILE)==abspath(@__FILE__)&&main()
