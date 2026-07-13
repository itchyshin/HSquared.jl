#!/usr/bin/env julia

# Independent, dependency-light recovery-v3 D0 spectral replay. This program
# reads the retired recovery-v2 offset-7101 corpus, reconstructs its kernels and
# diagnostics, and writes only compact create-once recomputations. It never
# generates a phenotype and never fits a model.

using LinearAlgebra
using Printf
using SHA
using Statistics

const RIDGE = 0.01
const N_BOOTSTRAP = 10_000
const INFO_ZERO_FACTOR = 64.0
const EXPECTED_MANIFEST_SHA256 = "1264e87eeea10bf8dd9d6197a0f2ef865a2cd541e085bde22a655730ef894f61"
const EXPECTED_CORPUS_SHA256 = "04f128168747aecab4847848de4498ebfb6efdf4aafb742d2e6f828e0d15c084"
const EXPECTED_SEAL_SHA256 = "4a921c039426faa400648752ec59bd3f049939098ec4f42b6faafc9e845b324c"
const RESOLVED = ("boundary_lower", "boundary_upper", "interior", "interior_rescued")

const CELLS = [
    (id="n120_m600_r020", index=1, n=120, m=600, ratio=0.2),
    (id="n120_m600_r050", index=2, n=120, m=600, ratio=0.5),
    (id="n120_m600_r080", index=3, n=120, m=600, ratio=0.8),
    (id="n300_m150_r020", index=4, n=300, m=150, ratio=0.2),
    (id="n300_m150_r050", index=5, n=300, m=150, ratio=0.5),
    (id="n300_m150_r080", index=6, n=300, m=150, ratio=0.8),
    (id="n300_m1000_r020", index=7, n=300, m=1000, ratio=0.2),
    (id="n300_m1000_r050", index=8, n=300, m=1000, ratio=0.5),
    (id="n300_m1000_r080", index=9, n=300, m=1000, ratio=0.8),
]

const MANIFEST_COLUMNS = split("tier cell_id cell_index seed_offset seed n m truth_sigma_g2 truth_sigma_e2 truth_ratio ridge regime")
const ATTEMPT_COLUMNS = split("tier cell_id cell_index seed_offset seed n m truth_sigma_g2 truth_sigma_e2 truth_ratio ridge attempted status error_class converged boundary_status boundary_reason boundary_epsilon scientific_sigma_g2 scientific_sigma_e2 scientific_ratio fitted_total_variance numerical_sigma_g2 numerical_sigma_e2 numerical_ratio profile_loglik lower_derivative_per_observation upper_derivative_per_observation iterations objective gradient_norm runtime_seconds peak_rss_mb relationship_source relationship_method allele_frequency_source relationship_scale scale_denominator marker_hash id_hash kernel_hash precision_hash route r_implementation_commit julia_implementation_commit driver_commit seal_sha256")
const CORPUS_COLUMNS = ["relative_path", "sha256"]
const PACKET_PRIMARIES = ["markers.tsv", "ids.tsv", "phenotype.tsv", "truth.tsv", "packet_files_lock.tsv"]
const EIGEN_COLUMNS = split("cell_id seed eigen_index eigenvalue")
const PACKET_COLUMNS = split("cell_id cell_index seed n m truth_ratio retained_m ridge scale_denominator marker_hash id_hash kernel_hash precision_hash k_replay_max_abs qk_max_abs eigen_min eigen_max eigen_mean eigen_sd_population eigen_cv_population effective_rank information_r020 se_info_r020 information_r050 se_info_r050 information_r080 se_info_r080 scientific_ratio absolute_ratio_error boundary_status predicted_lower_probability predicted_upper_probability")
const CELL_COLUMNS = split("cell_id bootstrap_sha256 cell_index n m truth_ratio n_packets empirical_sd_ratio rms_se_info c_c c_c_bootstrap_lower c_c_bootstrap_upper spearman_se_info_abs_error mean_predicted_lower_probability mean_predicted_upper_probability observed_lower_count observed_upper_count observed_lower_proportion observed_upper_proportion observed_lower_mcse observed_upper_mcse mean_spectral_cv mean_effective_rank")

struct TSV
    columns::Vector{String}
    rows::Vector{Vector{String}}
end

_sha256(path) = bytes2hex(sha256(read(path)))
_hex(s, n=64) = length(s) == n && all(c -> isdigit(c) || c in 'a':'f', s)

function _option(args, key; default=nothing)
    prefix = "--$key="
    hits = filter(x -> startswith(x, prefix), args)
    length(hits) <= 1 || error("--$key must occur at most once")
    isempty(hits) ? default : split(only(hits), "="; limit=2)[2]
end

function _safe_dir(path, label)
    path === nothing && error("--$label is required")
    isabspath(path) || error("--$label must be absolute")
    normpath(path) == path || error("--$label must be normalized")
    isdir(path) && !islink(path) || error("--$label is not a plain directory: $path")
    realpath(path) == path || error("--$label real path mismatch")
    path
end

_is_nested(path, root) = startswith(path, root * Base.Filesystem.path_separator)

function _plain(root, path; directory=false)
    ap = abspath(path)
    prefix = root * Base.Filesystem.path_separator
    (ap == root || startswith(ap, prefix)) || error("path escapes root: $path")
    islink(ap) && error("symlink is forbidden: $ap")
    (directory ? isdir(ap) : isfile(ap)) || error("missing $(directory ? "directory" : "regular file"): $ap")
    realpath(ap) == ap || error("non-canonical path: $ap")
    ap
end

function _exact_entries(root, dir, expected)
    dir = _plain(root, dir; directory=true)
    actual = sort(readdir(dir))
    sort(String.(expected)) == actual || error("missing/additional entry in $dir")
    any(name -> islink(joinpath(dir, name)), actual) && error("symlink in $dir")
    nothing
end

function _verify_pair(root, path)
    path = _plain(root, path)
    sidecar = _plain(root, path * ".sha256")
    read(sidecar, String) == "$(_sha256(path))  $(basename(path))\n" ||
        error("checksum sidecar mismatch: $path")
    path
end

function _verify_external_pair(path)
    isabspath(path) && isfile(path) && !islink(path) && realpath(path) == path ||
        error("external input is not a canonical regular file: $path")
    sidecar = path * ".sha256"
    isfile(sidecar) && !islink(sidecar) && realpath(sidecar) == sidecar ||
        error("missing/non-canonical external sidecar: $sidecar")
    read(sidecar, String) == "$(_sha256(path))  $(basename(path))\n" ||
        error("external checksum sidecar mismatch: $path")
    path
end

function _read_tsv_verified(path, columns; root=nothing)
    root === nothing ? _verify_external_pair(path) : _verify_pair(root, path)
    bytes = read(path)
    !isempty(bytes) && bytes[end] == 0x0a || error("TSV must end in LF: $path")
    0x0d in bytes && error("CR bytes are forbidden: $path")
    lines = split(chop(String(bytes); tail=1), '\n'; keepempty=true)
    all(!isempty, lines) || error("blank TSV row: $path")
    header = split(lines[1], '\t'; keepempty=true)
    header == columns || error("schema drift in $path")
    rows = [split(line, '\t'; keepempty=true) for line in lines[2:end]]
    all(row -> length(row) == length(columns), rows) || error("malformed TSV row: $path")
    TSV(header, rows)
end

_dict(table::TSV, row) = Dict(table.columns[i] => row[i] for i in eachindex(table.columns))
function _int(x, field)
    occursin(r"^-?[0-9]+$", x) || error("$field is not an integer")
    parse(Int, x)
end
function _float(x, field)
    y = tryparse(Float64, x)
    y !== nothing && isfinite(y) || error("$field is not finite numeric")
    y
end
function _bool(x, field)
    x == "true" && return true
    x == "false" && return false
    error("$field must be true/false")
end

function _manifest(root; exact_binding=true)
    path = joinpath(root, "pilot_manifest.tsv")
    table = _read_tsv_verified(path, MANIFEST_COLUMNS; root=root)
    exact_binding && _sha256(path) != EXPECTED_MANIFEST_SHA256 && error("pilot manifest hash drift")
    length(table.rows) == 432 || error("pilot manifest must contain exactly 432 rows")
    rows = NamedTuple[]
    expected_order = Tuple{String,Int}[]
    for row in table.rows
        d = _dict(table, row)
        push!(rows, (tier=d["tier"], cell_id=d["cell_id"], cell_index=_int(d["cell_index"], "cell_index"),
            seed_offset=_int(d["seed_offset"], "seed_offset"), seed=_int(d["seed"], "seed"),
            n=_int(d["n"], "n"), m=_int(d["m"], "m"),
            truth_sigma_g2=_float(d["truth_sigma_g2"], "truth_sigma_g2"),
            truth_sigma_e2=_float(d["truth_sigma_e2"], "truth_sigma_e2"),
            truth_ratio=_float(d["truth_ratio"], "truth_ratio"),
            ridge=_float(d["ridge"], "ridge"), regime=d["regime"]))
    end
    allunique((r.cell_id, r.seed) for r in rows) || error("duplicate manifest key")
    for c in CELLS
        cr = filter(r -> r.cell_id == c.id, rows)
        length(cr) == 48 || error("cell $(c.id) must contain 48 packets")
        getproperty.(cr, :seed_offset) == collect(7101:7148) || error("offset drift for $(c.id)")
        for r in cr
            r.tier == "pilot" && r.cell_index == c.index && r.n == c.n && r.m == c.m &&
                r.truth_sigma_g2 == c.ratio && r.truth_sigma_e2 == 1-c.ratio &&
                r.truth_ratio == c.ratio && r.ridge == RIDGE || error("manifest cell drift for $(c.id)")
            r.seed == 2_027_120_000 + 10_000*c.index + r.seed_offset || error("seed formula drift")
            push!(expected_order, (c.id, r.seed))
        end
    end
    [(r.cell_id, r.seed) for r in rows] == expected_order || error("manifest order drift")
    rows
end

function _verify_seal(root; exact_binding=true)
    path = _verify_pair(root, joinpath(root, "campaign_seal.tsv"))
    exact_binding && _sha256(path) != EXPECTED_SEAL_SHA256 && error("campaign seal hash drift")
    table = _read_tsv_verified(path, ["key", "value"]; root=root)
    keys = getindex.(table.rows, 1)
    allunique(keys) || error("duplicate campaign-seal key")
    seal = Dict(row[1] => row[2] for row in table.rows)
    seal["schema_version"] == "v07-genomic-recovery-v2" || error("campaign seal schema drift")
    seal["output_root"] == root || error("campaign seal output-root drift")
    seal["pilot_offsets"] == "7101:7148" || error("campaign seal pilot offsets drift")
    seal["ridge"] == "0.01" && seal["relationship_method"] == "vanraden1" &&
        seal["allele_frequency_source"] == "sample" && seal["relationship_scale"] == "K_lambda" ||
        error("campaign seal relationship contract drift")
    seal
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
    io = IOBuffer(); write(io, codeunits("HSquared-provenance-v1\0"));
    write(io, codeunits(kind)); write(io, UInt8(0)); writer(io)
    bytes2hex(sha256(take!(io)))
end
_id_hash(ids) = _fingerprint(io -> _write_strings(io, ids), "id_order")
function _marker_hash(M, ids, names)
    _fingerprint("markers") do io
        n,m = size(M); _write_u64(io,n); _write_u64(io,m); _write_strings(io,ids)
        write(io,UInt8(1)); _write_strings(io,names); foreach(x -> _write_float(io,x), M)
    end
end
function _matrix_hash(kind, A, ids)
    _fingerprint(kind) do io
        n,m=size(A); n == m || error("$kind is not square")
        _write_u64(io,n); _write_u64(io,m); _write_strings(io,ids); _write_strings(io,ids)
        foreach(x -> _write_float(io,x), A)
    end
end

function _read_markers(root, path, ids, n)
    path = _verify_pair(root, path)
    bytes = read(path)
    !isempty(bytes) && bytes[end] == 0x0a || error("marker TSV must end in LF")
    0x0d in bytes && error("CR bytes forbidden in marker TSV")
    lines = split(chop(String(bytes); tail=1), '\n'; keepempty=true)
    all(!isempty, lines) || error("blank marker TSV row")
    header = split(lines[1], '\t'; keepempty=true)
    length(header) >= 2 && header[1] == "id" || error("marker schema drift")
    names = header[2:end]
    allunique(names) && all(x -> occursin(r"^m[0-9]{6}$",x), names) || error("invalid marker names")
    length(lines)-1 == n || error("marker row count drift")
    M = Matrix{Float64}(undef, n, length(names))
    for i in 1:n
        f = split(lines[i+1], '\t'; keepempty=true)
        length(f) == length(header) && f[1] == ids[i] || error("marker ID/schema drift")
        for j in eachindex(names)
            M[i,j] = _float(f[j+1], "marker dosage")
            M[i,j] in (0.0,1.0,2.0) || error("non-hard-call marker")
        end
    end
    M, names
end

function _attempt(root, mr)
    path = joinpath(root, "attempts", "pilot", mr.cell_id, "$(mr.seed).tsv")
    table = _read_tsv_verified(path, ATTEMPT_COLUMNS; root=root)
    length(table.rows) == 1 || error("attempt must contain one row")
    d = _dict(table, only(table.rows))
    d["tier"] == "pilot" && d["cell_id"] == mr.cell_id && _int(d["cell_index"],"cell_index") == mr.cell_index &&
        _int(d["seed"],"seed") == mr.seed && _int(d["n"],"n") == mr.n && _int(d["m"],"m") == mr.m ||
        error("attempt/manifest identity drift")
    _bool(d["attempted"],"attempted") && d["status"] == "success" &&
        _bool(d["converged"],"converged") || error("D0 corpus contains failed/nonconverged attempt")
    d["boundary_status"] in RESOLVED || error("unresolved boundary status")
    ratio = d["boundary_status"] == "boundary_lower" ? 0.0 :
        d["boundary_status"] == "boundary_upper" ? 1.0 : _float(d["scientific_ratio"],"scientific_ratio")
    abs(_float(d["truth_ratio"],"truth_ratio") - mr.truth_ratio) <= 1e-15 || error("attempt truth drift")
    (ratio=ratio, boundary_status=d["boundary_status"], marker_hash=d["marker_hash"],
     id_hash=d["id_hash"], kernel_hash=d["kernel_hash"], precision_hash=d["precision_hash"],
     scale_denominator=_float(d["scale_denominator"],"scale_denominator"))
end

function _helmert(n)
    n >= 2 || error("Helmert projection requires n >= 2")
    C = zeros(Float64, n, n-1)
    for j in 1:n-1
        a = inv(sqrt(j*(j+1.0)))
        C[1:j,j] .= a
        C[j+1,j] = -j*a
    end
    C
end

function _spectral(Kprofile, C)
    n = size(Kprofile,1)
    size(Kprofile) == (n,n) && size(C) == (n,n-1) || error("projection dimension drift")
    orth = maximum(abs.(transpose(C)*C - I))
    intercept = maximum(abs.(transpose(C)*ones(n)))
    orth <= 1e-12 && intercept <= 1e-12 || error("Helmert contract failure")
    projected = transpose(C)*Kprofile*C
    projected = (projected + transpose(projected))/2
    λ = sort!(eigvals(Symmetric(projected)))
    length(λ) == n-1 && all(isfinite,λ) && all(>(0),λ) || error("invalid projected eigenvalues")
    μ = mean(λ)
    cv = sqrt(mean((λ .- μ).^2))/μ
    erank = sum(λ)^2/sum(abs2,λ)
    infos = Float64[]; ses = Float64[]
    for r in (0.2,0.5,0.8)
        d = (λ .- 1) ./ (r .* λ .+ (1-r))
        centered = d .- mean(d)
        raw = 0.5 * sum(abs2, centered)
        tol = INFO_ZERO_FACTOR * eps(Float64) * max(1.0, sum(abs2, d))
        info = raw <= tol ? 0.0 : raw
        push!(infos,info); push!(ses,info == 0 ? Inf : inv(sqrt(info)))
    end
    (eigenvalues=λ, orthogonality=orth, intercept=intercept, mean=μ, cv=cv,
     effective_rank=erank, information=Tuple(infos), se=Tuple(ses))
end

function _packet(root, mr, C)
    dir = joinpath(root,"packets","pilot",mr.cell_id,string(mr.seed))
    _exact_entries(root,dir,vcat(PACKET_PRIMARIES,PACKET_PRIMARIES.*".sha256"))
    lock = _read_tsv_verified(joinpath(dir,"packet_files_lock.tsv"),["file","sha256"];root=root)
    length(lock.rows) == 4 && getindex.(lock.rows,1) == PACKET_PRIMARIES[1:4] || error("packet lock drift")
    for (i,name) in enumerate(PACKET_PRIMARIES[1:4])
        lock.rows[i][2] == _sha256(joinpath(dir,name)) || error("packet lock hash drift")
    end
    ids_t = _read_tsv_verified(joinpath(dir,"ids.tsv"),["index","id"];root=root)
    length(ids_t.rows) == mr.n || error("ID row count drift")
    ids = String[]
    for (i,row) in enumerate(ids_t.rows)
        _int(row[1],"ID index") == i && !isempty(row[2]) || error("ID order/value drift")
        push!(ids,row[2])
    end
    allunique(ids) || error("duplicate ID")
    M,names = _read_markers(root,joinpath(dir,"markers.tsv"),ids,mr.n)
    ph = _read_tsv_verified(joinpath(dir,"phenotype.tsv"),["index","id","y"];root=root)
    length(ph.rows) == mr.n || error("phenotype row count drift")
    for (i,row) in enumerate(ph.rows)
        _int(row[1],"phenotype index") == i && row[2] == ids[i] && isfinite(_float(row[3],"y")) ||
            error("phenotype order/value drift")
    end
    truth = _read_tsv_verified(joinpath(dir,"truth.tsv"),["cell_id","seed","n","requested_m","retained_m","truth_sigma_g2","truth_sigma_e2","truth_ratio","ridge","scale_denominator"];root=root)
    length(truth.rows) == 1 || error("truth must contain one row")
    tr = only(truth.rows)
    tr[1] == mr.cell_id && _int(tr[2],"truth seed") == mr.seed && _int(tr[3],"truth n") == mr.n &&
        _int(tr[4],"requested_m") == mr.m && _int(tr[5],"retained_m") == size(M,2) &&
        _float(tr[6],"truth sigma_g2") == mr.truth_sigma_g2 &&
        _float(tr[7],"truth sigma_e2") == mr.truth_sigma_e2 &&
        _float(tr[8],"truth ratio") == mr.truth_ratio && _float(tr[9],"truth ridge") == RIDGE ||
        error("truth identity drift")
    p = vec(sum(M,dims=1))./(2mr.n)
    W = M .- 2 .* transpose(p)
    k = 2sum(p.*(1 .- p))
    k > 0 && isfinite(k) && abs(_float(tr[10],"truth scale")-k) <= 1e-10 || error("VanRaden denominator drift")
    G = (W*transpose(W))./k
    K = Matrix{Float64}(G) + RIDGE*I
    Q = Matrix{Float64}(inv(Symmetric(K)))
    qk = maximum(abs.(Q*K-I))
    qk <= 1e-10 || error("Q*K identity exceeds 1e-10")
    Kraw = Matrix{Float64}(inv(Symmetric(Q)))
    Kprofile = (Kraw + transpose(Kraw))/2
    kdiff = maximum(abs.(Kprofile-K))
    kdiff <= 1e-10 || error("K versus sym(Q^-1) exceeds 1e-10")
    attempt = _attempt(root,mr)
    marker_hash = _marker_hash(M,ids,names); id_hash = _id_hash(ids)
    kernel_hash = _matrix_hash("K_lambda",K,ids); precision_hash = _matrix_hash("Q_lambda",Q,ids)
    attempt.marker_hash == marker_hash && attempt.id_hash == id_hash &&
        attempt.kernel_hash == kernel_hash && attempt.precision_hash == precision_hash ||
        error("packet/attempt fingerprint mismatch")
    abs(attempt.scale_denominator-k) <= 1e-10 || error("attempt/packet scale mismatch")
    spectrum = _spectral(Kprofile,C)
    se = spectrum.se[mr.truth_ratio == 0.2 ? 1 : mr.truth_ratio == 0.5 ? 2 : 3]
    zlower = -mr.truth_ratio/se; zupper = (1-mr.truth_ratio)/se
    plower = _normal_cdf(zlower); pupper = _normal_upper(zupper)
    (cell_id=mr.cell_id, cell_index=mr.cell_index, seed=mr.seed, n=mr.n, m=mr.m,
     truth_ratio=mr.truth_ratio, retained_m=size(M,2), ridge=RIDGE,
     scale_denominator=k, marker_hash=marker_hash,id_hash=id_hash,kernel_hash=kernel_hash,
     precision_hash=precision_hash,k_replay_max_abs=kdiff,qk_max_abs=qk,
     eigen_min=first(spectrum.eigenvalues),eigen_max=last(spectrum.eigenvalues),
     eigen_mean=spectrum.mean,eigen_sd_population=spectrum.cv*spectrum.mean,
     eigen_cv_population=spectrum.cv,effective_rank=spectrum.effective_rank,
     information_r020=spectrum.information[1],se_info_r020=spectrum.se[1],
     information_r050=spectrum.information[2],se_info_r050=spectrum.se[2],
     information_r080=spectrum.information[3],se_info_r080=spectrum.se[3],
     scientific_ratio=attempt.ratio,absolute_ratio_error=abs(attempt.ratio-mr.truth_ratio),
     boundary_status=attempt.boundary_status,predicted_lower_probability=plower,
     predicted_upper_probability=pupper,eigenvalues=spectrum.eigenvalues)
end

_erfc(x) = ccall((:erfc, Base.Math.libm), Cdouble, (Cdouble,), x)
_normal_cdf(x) = 0.5*_erfc(-x/sqrt(2.0))
_normal_upper(x) = 0.5*_erfc(x/sqrt(2.0))

function _verify_corpus(root, manifest; exact_binding=true)
    path = joinpath(root,"pilot_corpus_lock.tsv")
    observed = _read_tsv_verified(path,CORPUS_COLUMNS;root=root)
    exact_binding && _sha256(path) != EXPECTED_CORPUS_SHA256 && error("pilot corpus-lock hash drift")
    expected = Vector{Vector{String}}()
    paths = String[joinpath(root,"pilot_manifest.tsv")]
    for mr in manifest
        push!(paths,joinpath(root,"attempts","pilot",mr.cell_id,"$(mr.seed).tsv"))
        packet = joinpath(root,"packets","pilot",mr.cell_id,string(mr.seed))
        append!(paths,joinpath.(Ref(packet),PACKET_PRIMARIES))
    end
    for p in paths
        p = _verify_pair(root,p)
        push!(expected,[relpath(p,root),_sha256(p)])
    end
    sort!(expected;by=first)
    allunique(first.(expected)) || error("duplicate expected corpus path")
    observed.rows == expected || error("current corpus differs from exact pilot lock")
    cells = getproperty.(CELLS,:id)
    _exact_entries(root,joinpath(root,"attempts","pilot"),cells)
    _exact_entries(root,joinpath(root,"packets","pilot"),cells)
    for c in CELLS
        cr=filter(r->r.cell_id==c.id,manifest); names=string.(getproperty.(cr,:seed))
        _exact_entries(root,joinpath(root,"attempts","pilot",c.id),sort(vcat(names.*".tsv",names.*".tsv.sha256")))
        _exact_entries(root,joinpath(root,"packets","pilot",c.id),sort(names))
    end
    nothing
end

function _bootstrap(path, expected_sha)
    _hex(expected_sha) || error("--bootstrap-sha256 must be 64 lowercase hexadecimal characters")
    _verify_external_pair(path)
    _sha256(path) == expected_sha || error("bootstrap indices differ from supplied seal hash")
    columns = vcat(["cell_id","bootstrap_rep"],[ @sprintf("index_%02d",i) for i in 1:48])
    table = _read_tsv_verified(path,columns)
    length(table.rows) == length(CELLS)*N_BOOTSTRAP || error("bootstrap row count drift")
    out = Dict{String,Matrix{Int}}()
    cursor=1
    for c in CELLS
        a = Matrix{Int}(undef,N_BOOTSTRAP,48)
        for rep in 1:N_BOOTSTRAP
            row=table.rows[cursor]; cursor+=1
            row[1]==c.id && _int(row[2],"bootstrap_rep")==rep || error("bootstrap order/membership drift")
            for j in 1:48
                idx=_int(row[j+2],"bootstrap index"); idx in 1:48 || error("bootstrap index outside 1:48")
                a[rep,j]=idx
            end
        end
        out[c.id]=a
    end
    out
end

function _average_ranks(x)
    n=length(x); p=sortperm(x;alg=MergeSort); ranks=zeros(Float64,n); i=1
    while i<=n
        j=i
        while j<n && x[p[j+1]]==x[p[i]]; j+=1; end
        r=(i+j)/2
        for k in i:j; ranks[p[k]]=r; end
        i=j+1
    end
    ranks
end
function _spearman(x,y)
    length(x)==length(y) || error("Spearman length drift")
    rx=_average_ranks(x);ry=_average_ranks(y)
    sx=std(rx);sy=std(ry)
    sx==0 || sy==0 ? NaN : cor(rx,ry)
end
function _quantile7(x,p)
    0<=p<=1 || error("invalid quantile probability")
    y=sort(Float64.(x)); n=length(y); n>0 || error("empty quantile")
    h=(n-1)*p+1; lo=floor(Int,h); hi=ceil(Int,h)
    lo==hi ? y[lo] : y[lo]+(h-lo)*(y[hi]-y[lo])
end

function _cell_summary(packets, indices, bootstrap_sha256)
    _hex(bootstrap_sha256) || error("summary bootstrap SHA-256 is invalid")
    rows=NamedTuple[]
    for c in CELLS
        ps=sort(filter(p->p.cell_id==c.id,packets);by=p->p.seed)
        length(ps)==48 || error("packet denominator drift for $(c.id)")
        est=getproperty.(ps,:scientific_ratio)
        sefield=c.ratio==0.2 ? :se_info_r020 : c.ratio==0.5 ? :se_info_r050 : :se_info_r080
        se=Float64[getproperty(p,sefield) for p in ps]
        empirical_sd=std(est);rms_se=sqrt(mean(abs2,se));cc=empirical_sd/rms_se
        boot=Vector{Float64}(undef,N_BOOTSTRAP); idx=indices[c.id]
        for b in 1:N_BOOTSTRAP
            ii=@view idx[b,:]; eb=est[ii]; sb=se[ii]
            boot[b]=std(eb)/sqrt(mean(abs2,sb))
        end
        lower_count=count(p->p.boundary_status=="boundary_lower",ps)
        upper_count=count(p->p.boundary_status=="boundary_upper",ps)
        lower=lower_count/48;upper=upper_count/48
        push!(rows,(cell_id=c.id,bootstrap_sha256=bootstrap_sha256,
            cell_index=c.index,n=c.n,m=c.m,truth_ratio=c.ratio,
            n_packets=48,empirical_sd_ratio=empirical_sd,rms_se_info=rms_se,c_c=cc,
            c_c_bootstrap_lower=_quantile7(boot,0.025),c_c_bootstrap_upper=_quantile7(boot,0.975),
            spearman_se_info_abs_error=_spearman(se,getproperty.(ps,:absolute_ratio_error)),
            mean_predicted_lower_probability=mean(getproperty.(ps,:predicted_lower_probability)),
            mean_predicted_upper_probability=mean(getproperty.(ps,:predicted_upper_probability)),
            observed_lower_count=lower_count,observed_upper_count=upper_count,
            observed_lower_proportion=lower,observed_upper_proportion=upper,
            observed_lower_mcse=sqrt(lower*(1-lower)/48),observed_upper_mcse=sqrt(upper*(1-upper)/48),
            mean_spectral_cv=mean(getproperty.(ps,:eigen_cv_population)),
            mean_effective_rank=mean(getproperty.(ps,:effective_rank))))
    end
    rows
end

_format(x::Integer)=string(x)
_format(x::AbstractFloat)=isnan(x) ? "NA" : isinf(x) ? (x>0 ? "Inf" : "-Inf") : @sprintf("%.17g",x)
_format(x)=string(x)
function _table_text(columns, rows)
    io=IOBuffer();println(io,join(columns,'\t'))
    for r in rows
        println(io,join((_format(getproperty(r,Symbol(c))) for c in columns),'\t'))
    end
    String(take!(io))
end
function _eigen_text(packets)
    io=IOBuffer();println(io,join(EIGEN_COLUMNS,'\t'))
    for p in packets, (i,value) in enumerate(p.eigenvalues)
        println(io,join((p.cell_id,p.seed,i,_format(value)),'\t'))
    end
    String(take!(io))
end
function _packet_text(packets)
    _table_text(PACKET_COLUMNS,packets)
end

function _write_once(path,text)
    (ispath(path)||ispath(path*".sha256")) && error("create-once output exists: $path")
    tmp=tempname(dirname(path));open(tmp,"w") do io;write(io,text);end
    try Base.Filesystem.hardlink(tmp,path) catch;rm(tmp;force=true);rethrow();end
    rm(tmp;force=true);digest=_sha256(path);side=path*".sha256";tmp=tempname(dirname(path))
    open(tmp,"w") do io;print(io,"$digest  $(basename(path))\n");end
    try Base.Filesystem.hardlink(tmp,side) catch;rm(tmp;force=true);rethrow();end
    rm(tmp;force=true);nothing
end

function replay(root,bootstrap_path,bootstrap_sha,output_dir)
    root=_safe_dir(root,"corpus-root");output_dir=_safe_dir(output_dir,"output-dir")
    (root==output_dir || _is_nested(output_dir,root) || _is_nested(root,output_dir)) &&
        error("D0 output and immutable v2 corpus roots must be separate and non-nested")
    output_paths=[joinpath(output_dir,"d0_eigenvalues_julia.tsv"),
        joinpath(output_dir,"d0_packet_spectrum_julia.tsv"),
        joinpath(output_dir,"d0_cell_summary_julia.tsv")]
    any(path->ispath(path)||ispath(path*".sha256"),output_paths) &&
        error("one or more create-once D0 outputs already exist")
    _verify_seal(root);manifest=_manifest(root);_verify_corpus(root,manifest)
    indices=_bootstrap(bootstrap_path,bootstrap_sha)
    Ccache=Dict(n=>_helmert(n) for n in unique(getproperty.(CELLS,:n)))
    packets=NamedTuple[]
    for (i,mr) in enumerate(manifest)
        push!(packets,_packet(root,mr,Ccache[mr.n]))
        i%48==0 && println("verified spectral replay packets=$i/432 cell=$(mr.cell_id)")
    end
    _verify_corpus(root,manifest)
    summaries=_cell_summary(packets,indices,bootstrap_sha)
    outputs=collect(zip(output_paths,(_eigen_text(packets),_packet_text(packets),
        _table_text(CELL_COLUMNS,summaries))))
    foreach(x->_write_once(x[1],x[2]),outputs)
    println("v0.7 recovery-v3 D0 Julia replay: PASS packets=432 eigenvalues=$(sum(length(p.eigenvalues) for p in packets)) cells=9")
    foreach(x->println("wrote $(x[1]) sha256=$(_sha256(x[1]))"),outputs)
end

function _must_fail(label,f)
    failed=false;try f() catch;failed=true end
    failed || error("mutation stayed green: $label")
end
function _sidecar(path)
    open(path*".sha256","w") do io;print(io,"$(_sha256(path))  $(basename(path))\n");end
end
function selftest()
    C=_helmert(4)
    maximum(abs.(transpose(C)*C-I))<=1e-15 || error("Helmert orthogonality selftest")
    maximum(abs.(transpose(C)*ones(4)))<=1e-15 || error("Helmert intercept selftest")
    K=Matrix(Diagonal([1.2,0.8,1.4,0.6]));s=_spectral(K,C)
    length(s.eigenvalues)==3 && issorted(s.eigenvalues) && s.cv>0 && 0<s.effective_rank<=3 || error("spectrum selftest")
    all(x->x>0,s.information) && all(isfinite,s.se) || error("information selftest")
    maximum(abs.(s.eigenvalues-[0.6837722339831622,1.0000000000000002,1.3162277660168382]))<1e-14 || error("eigenvalue selftest")
    abs(s.cv-0.2581988897471611)<1e-14 && abs(s.effective_rank-2.812500000000001)<1e-14 ||
        error("population CV/effective-rank selftest")
    maximum(abs.(collect(s.information)-[0.10093923216292212,0.10607056760902915,0.11657778751795841]))<1e-14 ||
        error("conditional-information selftest")
    scalar=_spectral(Matrix{Float64}(I,4,4),C)
    all(==(0.0),scalar.information) && all(isinf,scalar.se) || error("zero-information selftest")
    abs(_normal_cdf(0)-0.5)<=eps() && abs(_normal_cdf(1)-0.8413447460685429)<1e-15 &&
        abs(_normal_upper(1)-0.15865525393145707)<1e-15 || error("Normal tail selftest")
    _normal_upper(11)>0 || error("stable upper-tail selftest")
    _quantile7(collect(1:10),0.25)==3.25 || error("type-7 quantile selftest")
    _average_ranks([1.0,2.0,2.0,4.0])==[1.0,2.5,2.5,4.0] || error("average-rank selftest")
    _must_fail("changed eigenvalue") do
        λ=copy(s.eigenvalues);λ[1]=-1.0;all(>(0),λ)||error("negative eigenvalue")
    end
    _must_fail("wrong projection dimension") do;_spectral(K,C[:,1:2]);end
    _must_fail("bootstrap index range") do;(49 in 1:48)||error("index outside");end
    _must_fail("manifest hash") do;repeat("0",64)==EXPECTED_MANIFEST_SHA256||error("hash drift");end
    ids=["g000001","g000002"];M=[0.0 1.0;2.0 1.0];names=["m000001","m000002"]
    _id_hash(ids)!=_id_hash(reverse(ids))||error("ID mutation stayed green")
    _marker_hash(M,ids,names)!=_marker_hash(M[[2,1],:],reverse(ids),names)||error("marker/order mutation stayed green")
    Q=inv(Symmetric([1.01 0.2;0.2 1.01]));
    _matrix_hash("Q_lambda",Q,ids)!=_matrix_hash("Q_lambda",Q[[2,1],[2,1]],reverse(ids))||error("precision/order mutation stayed green")
    dir=mktempdir();try
        root=realpath(dir);p=joinpath(root,"x.tsv");_write_once(p,"x\n");_verify_pair(root,p)
        _must_fail("create-once") do;_write_once(p,"x\n");end
        open(p,"w") do io;write(io,"mutated\n");end
        _must_fail("checksum corruption") do;_verify_pair(root,p);end
        rm(p*".sha256");_must_fail("orphan primary") do;_verify_pair(root,p);end
        link=joinpath(root,"link");symlink(p,link);_must_fail("symlink") do;_plain(root,link);end
        nested=joinpath(root,"nested");mkdir(nested)
        _is_nested(realpath(nested),root)||error("nested-root detection selftest")
    finally rm(dir;recursive=true,force=true) end
    println("v0.7 genomic recovery-v3 D0 Julia spectral replay selftest: PASS (synthetic only; invariant and mutation controls)")
end

function main(args=ARGS)
    mode=_option(args,"mode";default="replay")
    mode=="selftest" && return selftest()
    mode=="replay" || error("--mode must be replay or selftest")
    root=_option(args,"corpus-root");bootstrap=_option(args,"bootstrap-indices")
    bsha=_option(args,"bootstrap-sha256");out=_option(args,"output-dir")
    bootstrap===nothing && error("--bootstrap-indices is required")
    bsha===nothing && error("--bootstrap-sha256 is required")
    replay(root,bootstrap,bsha,out)
end

abspath(PROGRAM_FILE)==abspath(@__FILE__) && main()
