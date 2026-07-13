#!/usr/bin/env julia

using HSquared
using LinearAlgebra
using Printf
using Random
using SHA
using Statistics

# v0.7 genomic public-activation recovery campaign (G5 in the cross-twin
# preregistration). Raw one-row-per-seed files are deliberately local-only.
#
# Prepare the immutable pilot manifest:
#   julia --project=. sim/phase2_v07_genomic_activation_recovery.jl \
#     --mode=manifest --tier=pilot --out-dir=/path/to/results
# Run one seed (the Totoro launcher fans these commands out):
#   OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 julia --project=. \
#     sim/phase2_v07_genomic_activation_recovery.jl --mode=run \
#     --tier=pilot --cell=n120_m600_r020 --seed=2027130001 \
#     --out-dir=/path/to/results --resume=true
# Summarize and prepare confirmation manifests when eligible:
#   julia --project=. sim/phase2_v07_genomic_activation_recovery.jl \
#     --mode=summarize --tier=pilot --out-dir=/path/to/results
#
# The driver never launches its own workers. This is intentional: one OS process
# per seed, BLAS=1, is the campaign's preregistered isolation unit.

const RIDGE = 0.01
const PILOT_REPS = 48
const MIN_CONFIRM = 200
const MAX_CONFIRM = 2000
const PILOT_CONVERGENCE_MIN = 0.95
const CONFIRM_CONVERGENCE_MIN = 0.95
const WILSON_LOWER_MIN = 0.90
const Z975 = 1.959963984540054
const RESULT_COLUMNS = [
    "tier", "cell_id", "seed", "n", "m", "truth_sigma_g2", "truth_sigma_e2",
    "truth_ratio", "ridge", "estimate_sigma_g2", "estimate_sigma_e2", "estimate_ratio",
    "converged", "iterations", "objective", "gradient_norm", "runtime_seconds",
    "peak_rss_mb", "marker_hash", "id_hash", "kernel_hash", "error_class",
]

const CELL_SPECS = let rows = NamedTuple[]
    idx = 0
    for (n, m, regime) in ((120, 600, "marker_rich_n120"),
                           (300, 150, "marker_limited"),
                           (300, 1000, "marker_rich_n300")), ratio in (0.2, 0.5, 0.8)
        idx += 1
        push!(rows, (index = idx, id = @sprintf("n%d_m%d_r%03d", n, m, round(Int, 100ratio)),
                     n = n, m = m, ratio = ratio, regime = regime))
    end
    rows
end

_opt(args, key, default = nothing) = begin
    prefix = "--$(key)="
    for arg in args
        startswith(arg, prefix) && return split(arg, "="; limit = 2)[2]
    end
    default
end
_bool(args, key, default) = lowercase(String(_opt(args, key, string(default)))) in ("1", "true", "yes")
_required(args, key) = begin
    value = _opt(args, key, nothing)
    value === nothing && error("--$(key) is required")
    String(value)
end

function _cell(id)
    matches = filter(c -> c.id == id, CELL_SPECS)
    length(matches) == 1 || error("unknown --cell=$(id); expected one of $(join(getproperty.(CELL_SPECS, :id), ", "))")
    only(matches)
end

# Frozen, disjoint seed blocks. Each cell has a private 10,000-seed block;
# pilot occupies offsets 1:48 and confirmation occupies 1001:3000.
_seed_base(cell) = 2_027_120_000 + 10_000 * cell.index
pilot_seeds(cell) = (_seed_base(cell) + 1):(_seed_base(cell) + PILOT_REPS)
confirm_seeds(cell, n) = (_seed_base(cell) + 1001):(_seed_base(cell) + 1000 + n)

function _assert_single_threaded()
    Threads.nthreads() == 1 || error("JULIA_NUM_THREADS must be 1 (got $(Threads.nthreads()))")
    for key in ("OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS", "VECLIB_MAXIMUM_THREADS")
        get(ENV, key, "") == "1" || error("$(key) must be explicitly set to 1")
    end
    BLAS.set_num_threads(1)
end

function _draw_markers(rng, n, m)
    population_maf = 0.05 .+ 0.45 .* rand(rng, m)
    markers = Matrix{Float64}(undef, n, m)
    for j in 1:m, i in 1:n
        p = population_maf[j]
        markers[i, j] = (rand(rng) < p) + (rand(rng) < p)
    end
    # The execution brief freezes removal of realized monomorphic columns.
    keep = [maximum(view(markers, :, j)) != minimum(view(markers, :, j)) for j in 1:m]
    return markers[:, keep], count(keep)
end

function _gradient_norm(fit)
    vc = fit.variance_components
    x = log.([vc.sigma_a2, vc.sigma_e2])
    h = 1e-5
    gradient = zeros(2)
    for j in 1:2
        xp = copy(x); xm = copy(x)
        xp[j] += h; xm[j] -= h
        fp = -gaussian_loglik(fit.spec, exp(xp[1]), exp(xp[2]); method = :REML).loglik
        fm = -gaussian_loglik(fit.spec, exp(xm[1]), exp(xm[2]); method = :REML).loglik
        gradient[j] = (fp - fm) / (2h)
    end
    norm(gradient)
end

_clean_error(err) = replace(first(split(sprint(showerror, err), '\n')), '\t' => ' ', '\r' => ' ')
function _error_class(err)
    message = _clean_error(err)
    occursin("all_monomorphic_panel", message) && return "input_all_monomorphic"
    occursin("nonpositive_scale_denominator", message) && return "input_nonpositive_k"
    string(nameof(typeof(err)))
end

function _run_seed(cell, tier, seed)
    sg2, se2 = cell.ratio, 1 - cell.ratio
    start_rss = Sys.maxrss()
    started = time_ns()
    base = Any[tier, cell.id, seed, cell.n, cell.m, sg2, se2, cell.ratio, RIDGE]
    marker_hash = id_hash = kernel_hash = "NA"
    try
        rng = MersenneTwister(seed)
        markers, retained_m = _draw_markers(rng, cell.n, cell.m)
        retained_m > 0 || error("all_monomorphic_panel")
        ids = ["id$(i)" for i in 1:cell.n]
        construction = HSquared._genomic_activation_construction(markers, ids; ridge = RIDGE)
        construction.k > 0 || error("nonpositive_scale_denominator")
        marker_hash = construction.provenance.marker_content_fingerprint
        id_hash = construction.provenance.id_order_fingerprint
        kernel_hash = construction.provenance.kernel_fingerprint
        u = cholesky(Symmetric(construction.K)).L * randn(rng, cell.n) .* sqrt(sg2)
        y = u .+ randn(rng, cell.n) .* sqrt(se2)
        X = ones(cell.n, 1)
        Z = Matrix{Float64}(I, cell.n, cell.n)
        fit = fit_gblup_reml(y, X, Z, construction.Q;
                             initial = (sigma_a2 = 1.0, sigma_e2 = 1.0), ids = ids)
        aghat = fit.variance_components.sigma_a2
        ehat = fit.variance_components.sigma_e2
        ratiohat = aghat / (aghat + ehat)
        finite = all(isfinite, (aghat, ehat, ratiohat))
        converged = fit.converged && finite
        error_class = !fit.converged ? "fit_not_converged" : (!finite ? "nonfinite_estimate" : "none")
        objective = -fit.likelihood.loglik
        gradnorm = finite ? _gradient_norm(fit) : NaN
        elapsed = (time_ns() - started) / 1e9
        rss_mb = max(start_rss, Sys.maxrss()) / 1024^2
        return vcat(base, Any[aghat, ehat, ratiohat, converged, fit.iterations, objective,
                              gradnorm, elapsed, rss_mb, marker_hash, id_hash, kernel_hash,
                              error_class])
    catch err
        elapsed = (time_ns() - started) / 1e9
        rss_mb = max(start_rss, Sys.maxrss()) / 1024^2
        return vcat(base, Any[NaN, NaN, NaN, false, -1, NaN, NaN, elapsed, rss_mb,
                              marker_hash, id_hash, kernel_hash,
                              _error_class(err)])
    end
end

function _expected_provenance(cell, seed)
    rng = MersenneTwister(seed)
    markers, retained_m = _draw_markers(rng, cell.n, cell.m)
    retained_m > 0 || return (marker_hash = "NA", id_hash = "NA", kernel_hash = "NA")
    ids = ["id$(i)" for i in 1:cell.n]
    cm = centered_markers(markers)
    G = (cm.W * transpose(cm.W)) ./ cm.k
    K = Matrix{Float64}(G) + RIDGE * I
    return (
        marker_hash = HSquared._genomic_marker_fingerprint(markers, ids, nothing),
        id_hash = HSquared._genomic_id_order_fingerprint(ids),
        kernel_hash = HSquared._genomic_matrix_fingerprint("K_lambda", K, ids),
    )
end

_format(x::AbstractFloat) = isfinite(x) ? @sprintf("%.17g", x) : string(x)
_format(x) = string(x)

function _result_path(outdir, tier, cell, seed)
    joinpath(outdir, "raw", tier, cell, string(seed) * ".tsv")
end

function _write_atomic(path, row)
    mkpath(dirname(path))
    tmp = path * ".tmp.$(getpid())"
    open(tmp, "w") do io
        println(io, join(RESULT_COLUMNS, '\t'))
        println(io, join(_format.(row), '\t'))
    end
    mv(tmp, path; force = true)
end

function _valid_existing(path, tier, cell, seed)
    isfile(path) || return false
    lines = readlines(path)
    length(lines) == 2 || return false
    split(lines[1], '\t') == RESULT_COLUMNS || return false
    row = split(lines[2], '\t')
    length(row) == length(RESULT_COLUMNS) || return false
    row[1] == tier && row[2] == cell && tryparse(Int, row[3]) == seed
end

_sha256_file(path) = bytes2hex(sha256(read(path)))

function _settings(path)
    isfile(path) || error("missing $(path)")
    Dict(begin
        parts = split(line, "="; limit=2)
        length(parts) == 2 || error("malformed setting in $(path)")
        parts[1] => parts[2]
    end for line in eachline(path) if occursin('=', line))
end

function _git_root()
    project = Base.active_project()
    project === nothing && error("an active Julia project is required")
    try
        readchomp(`git -C $(dirname(project)) rev-parse --show-toplevel`)
    catch
        error("campaign must run from a git checkout")
    end
end

_git_commit(root) = readchomp(`git -C $root rev-parse HEAD`)
_git_clean(root) = isempty(readchomp(`git -C $root status --porcelain --untracked-files=all`))

function _project_paths()
    project = Base.active_project()
    project === nothing && error("an active Julia project is required")
    manifest = joinpath(dirname(project), "Manifest.toml")
    isfile(project) || error("active Project.toml is missing: $(project)")
    isfile(manifest) || error("Manifest.toml is required to freeze the campaign environment")
    abspath(project), abspath(manifest)
end


function _read_manifest(path)
    isfile(path) || error("missing campaign manifest $(path)")
    lines = readlines(path)
    isempty(lines) && error("empty campaign manifest $(path)")
    split(lines[1], '\t') == MANIFEST_COLUMNS || error("manifest schema drift in $(path)")
    rows = Dict{Tuple{String,String,Int},NamedTuple}()
    for line in lines[2:end]
        f = split(line, '\t')
        length(f) == length(MANIFEST_COLUMNS) || error("malformed manifest row in $(path)")
        row = (tier=f[1], cell_id=f[2], seed=parse(Int,f[3]), n=parse(Int,f[4]), m=parse(Int,f[5]),
               truth_sigma_g2=parse(Float64,f[6]), truth_sigma_e2=parse(Float64,f[7]),
               truth_ratio=parse(Float64,f[8]), ridge=parse(Float64,f[9]), regime=f[10])
        key = (row.tier, row.cell_id, row.seed)
        haskey(rows, key) && error("duplicate manifest row $(key)")
        cell = _cell(row.cell_id)
        row.n == cell.n && row.m == cell.m && row.truth_sigma_g2 == cell.ratio &&
            row.truth_sigma_e2 == 1-cell.ratio && row.truth_ratio == cell.ratio &&
            row.ridge == RIDGE && row.regime == cell.regime ||
            error("manifest row disagrees with frozen cell $(key)")
        push!(rows, key => row)
    end
    rows
end

function _validate_sha_sidecar(path)
    sidecar = path * ".sha256"
    isfile(sidecar) || error("missing checksum sidecar $(sidecar)")
    fields = split(strip(read(sidecar, String)))
    length(fields) >= 1 || error("malformed checksum sidecar $(sidecar)")
    fields[1] == _sha256_file(path) || error("checksum mismatch for $(path)")
end

function _validate_campaign_manifest(outdir, tier)
    envpath = joinpath(outdir, "environment_manifest.txt")
    _validate_sha_sidecar(envpath)
    settings = _settings(envpath)
    root = _git_root()
    _git_clean(root) || error("git worktree is not clean; campaign state is not frozen")
    project, manifest = _project_paths()
    checks = Dict(
        "campaign" => "v07_genomic_activation_recovery",
        "julia" => string(VERSION),
        "hsquared_project" => project,
        "ridge" => string(RIDGE),
        "pilot_reps" => string(PILOT_REPS),
        "git_root" => root,
        "git_commit" => _git_commit(root),
        "driver_sha256" => _sha256_file(@__FILE__),
        "project_sha256" => _sha256_file(project),
        "manifest_sha256" => _sha256_file(manifest),
    )
    for (key, observed) in checks
        get(settings, key, "") == observed || error("campaign environment mismatch for $(key); use a fresh out-dir")
    end
    pilot = joinpath(outdir, "pilot_manifest.tsv")
    get(settings, "pilot_manifest_sha256", "") == _sha256_file(pilot) ||
        error("pilot manifest checksum mismatch")
    path = tier == "pilot" ? pilot : joinpath(outdir, "confirmation_manifest.tsv")
    tier == "confirm" && _validate_sha_sidecar(path)
    rows = _read_manifest(path)
    all(first(key) == tier for key in keys(rows)) || error("$(tier) manifest contains another tier")
    rows
end

function run_mode(args)
    _assert_single_threaded()
    tier = String(_opt(args, "tier", "pilot"))
    tier in ("pilot", "confirm") || error("--tier must be pilot or confirm")
    cell = _cell(_required(args, "cell"))
    seed = parse(Int, _required(args, "seed"))
    outdir = abspath(_required(args, "out-dir"))
    manifest = _validate_campaign_manifest(outdir, tier)
    key = (tier, cell.id, seed)
    haskey(manifest, key) || error("seed $(seed) is not in the immutable $(tier) manifest for $(cell.id)")
    path = _result_path(outdir, tier, cell.id, seed)
    if _bool(args, "resume", true) && _valid_existing(path, tier, cell.id, seed)
        row = _read_result_file(path)
        _validate_result_row(row, manifest, path)
        println("resume: already complete $(path)")
        return
    end
    row = _run_seed(cell, tier, seed)
    _write_atomic(path, row)
    println("wrote $(path) converged=$(row[13]) error_class=$(row[end])")
end

const MANIFEST_COLUMNS = ["tier", "cell_id", "seed", "n", "m", "truth_sigma_g2",
                          "truth_sigma_e2", "truth_ratio", "ridge", "regime"]

function _manifest_rows(tier; confirm_sizes = Dict{String,Int}())
    rows = Vector{Vector{Any}}()
    for cell in CELL_SPECS
        seeds = tier == "pilot" ? pilot_seeds(cell) : confirm_seeds(cell, get(confirm_sizes, cell.id, 0))
        for seed in seeds
            push!(rows, Any[tier, cell.id, seed, cell.n, cell.m, cell.ratio, 1-cell.ratio,
                            cell.ratio, RIDGE, cell.regime])
        end
    end
    rows
end

function _write_table(path, columns, rows)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, join(columns, '\t'))
        for row in rows
            println(io, join(_format.(row), '\t'))
        end
    end
end

function _write_table_exclusive(path, columns, rows)
    ispath(path) && error("refusing to overwrite immutable file $(path); use a fresh out-dir")
    _write_table(path, columns, rows)
end

function _write_sha_sidecar(path)
    sidecar = path * ".sha256"
    ispath(sidecar) && error("refusing to overwrite immutable file $(sidecar)")
    open(sidecar, "w") do io
        println(io, _sha256_file(path), "  ", basename(path))
    end
end

function manifest_mode(args)
    tier = String(_opt(args, "tier", "pilot"))
    tier == "pilot" || error("confirmation manifests are generated from pilot summaries")
    outdir = abspath(_required(args, "out-dir"))
    mkpath(outdir)
    isempty(readdir(outdir)) || error("campaign out-dir must be empty: $(outdir)")
    root = _git_root()
    _git_clean(root) || error("git worktree is not clean; commit or remove changes before freezing the campaign")
    project, manifest = _project_paths()
    for cell in CELL_SPECS
        isempty(intersect(Set(pilot_seeds(cell)), Set(confirm_seeds(cell, MAX_CONFIRM)))) ||
            error("pilot/confirmation seed overlap for $(cell.id)")
    end
    path = joinpath(outdir, "pilot_manifest.tsv")
    _write_table_exclusive(path, MANIFEST_COLUMNS, _manifest_rows("pilot"))
    manifest_sha256 = _sha256_file(path)
    driver_sha256 = _sha256_file(@__FILE__)
    git_commit = _git_commit(root)
    envpath = joinpath(outdir, "environment_manifest.txt")
    open(envpath, "w") do io
        println(io, "campaign=v07_genomic_activation_recovery")
        println(io, "julia=$(VERSION)")
        println(io, "hsquared_project=$(project)")
        println(io, "ridge=$(RIDGE)")
        println(io, "pilot_reps=$(PILOT_REPS)")
        println(io, "git_root=$(root)")
        println(io, "git_commit=$(git_commit)")
        println(io, "driver_sha256=$(driver_sha256)")
        println(io, "project_sha256=$(_sha256_file(project))")
        println(io, "manifest_sha256=$(_sha256_file(manifest))")
        println(io, "pilot_manifest_sha256=$(manifest_sha256)")
    end
    _write_sha_sidecar(envpath)
    println("wrote $(path) rows=$(length(CELL_SPECS) * PILOT_REPS)")
end

# Dependency-free special-function routines used to make the preregistered
# confirmation t critical values reproducible in Julia.
# Lanczos log-gamma for the positive arguments used by the beta function.
function _loggamma(z)
    coefficients = (0.99999999999980993, 676.5203681218851, -1259.1392167224028,
                    771.32342877765313, -176.61502916214059, 12.507343278686905,
                    -0.13857109526572012, 9.984369578019572e-6, 1.5056327351493116e-7)
    z < 0.5 && return log(pi) - log(sinpi(z)) - _loggamma(1-z)
    x=coefficients[1]; zm1=z-1
    for i in 2:length(coefficients); x += coefficients[i]/(zm1+i-1); end
    t=zm1+7.5
    0.5log(2pi)+(zm1+0.5)*log(t)-t+log(x)
end

function _betacf(a,b,x)
    qab=a+b; qap=a+1; qam=a-1; c=1.0; d=1-qab*x/qap
    abs(d)<floatmin(Float64) && (d=floatmin(Float64)); d=1/d; h=d
    for m in 1:10000
        m2=2m; aa=m*(b-m)*x/((qam+m2)*(a+m2)); d=1+aa*d
        abs(d)<floatmin(Float64) && (d=floatmin(Float64)); c=1+aa/c
        abs(c)<floatmin(Float64) && (c=floatmin(Float64)); d=1/d; h*=d*c
        aa=-(a+m)*(qab+m)*x/((a+m2)*(qap+m2)); d=1+aa*d
        abs(d)<floatmin(Float64) && (d=floatmin(Float64)); c=1+aa/c
        abs(c)<floatmin(Float64) && (c=floatmin(Float64)); d=1/d; del=d*c; h*=del
        abs(del-1)<2e-15 && break
    end
    h
end

function _ibeta(a,b,x)
    x <= 0 && return 0.0; x >= 1 && return 1.0
    bt=exp(_loggamma(a+b)-_loggamma(a)-_loggamma(b)+a*log(x)+b*log1p(-x))
    x < (a+1)/(a+b+2) ? bt*_betacf(a,b,x)/a : 1-bt*_betacf(b,a,1-x)/b
end

_tcdf(t, df) = t == 0 ? 0.5 : (t > 0 ? 1-0.5*_ibeta(df/2, 0.5, df/(df+t*t)) :
                                            0.5*_ibeta(df/2, 0.5, df/(df+t*t)))
function _tquantile(p, df)
    lo, hi = -1.0, 1.0
    while _tcdf(lo,df)>p; lo*=2; end
    while _tcdf(hi,df)<p; hi*=2; end
    for _ in 1:120
        mid=(lo+hi)/2; _tcdf(mid,df)<p ? (lo=mid) : (hi=mid)
    end
    (lo+hi)/2
end

# Regularized lower incomplete gamma and chi-square quantile for the frozen
# one-sided upper confidence bound on the pilot SD.
function _gamma_p(a, x)
    a > 0 && x >= 0 || throw(ArgumentError("gamma arguments must satisfy a>0 and x>=0"))
    x == 0 && return 0.0
    if x < a + 1
        ap = a
        term = sum = 1 / a
        for _ in 1:10000
            ap += 1
            term *= x / ap
            sum += term
            abs(term) <= abs(sum) * 2e-15 && break
        end
        return sum * exp(-x + a * log(x) - _loggamma(a))
    end
    b = x + 1 - a
    c = 1 / floatmin(Float64)
    d = 1 / b
    h = d
    for i in 1:10000
        an = -i * (i - a)
        b += 2
        d = an * d + b
        abs(d) < floatmin(Float64) && (d = floatmin(Float64))
        c = b + an / c
        abs(c) < floatmin(Float64) && (c = floatmin(Float64))
        d = 1 / d
        delta = d * c
        h *= delta
        abs(delta - 1) <= 2e-15 && break
    end
    q = exp(-x + a * log(x) - _loggamma(a)) * h
    1 - q
end

_chisq_cdf(x, df) = _gamma_p(df / 2, x / 2)
function _chisq_quantile(p, df)
    0 < p < 1 || throw(ArgumentError("chi-square probability must lie in (0,1)"))
    df > 0 || throw(ArgumentError("chi-square df must be positive"))
    lo, hi = 0.0, max(1.0, Float64(df))
    while _chisq_cdf(hi, df) < p
        hi *= 2
    end
    for _ in 1:140
        mid = (lo + hi) / 2
        _chisq_cdf(mid, df) < p ? (lo = mid) : (hi = mid)
    end
    (lo + hi) / 2
end

_pilot_sd_upper(s, n) = n > 1 ? s * sqrt((n - 1) / _chisq_quantile(0.05, n - 1)) : NaN

function _read_result_file(file)
    lines=readlines(file); length(lines)==2 || error("malformed result file $(file)")
    split(lines[1],'\t')==RESULT_COLUMNS || error("schema drift in $(file)")
    f=split(lines[2],'\t'); length(f)==length(RESULT_COLUMNS) || error("malformed row in $(file)")
    return (tier=f[1], cell_id=f[2], seed=parse(Int,f[3]), n=parse(Int,f[4]), m=parse(Int,f[5]),
        truth_sigma_g2=parse(Float64,f[6]), truth_sigma_e2=parse(Float64,f[7]), truth_ratio=parse(Float64,f[8]),
        ridge=parse(Float64,f[9]), estimate_sigma_g2=parse(Float64,f[10]), estimate_sigma_e2=parse(Float64,f[11]),
        estimate_ratio=parse(Float64,f[12]), converged=lowercase(f[13])=="true", iterations=parse(Int,f[14]),
        objective=parse(Float64,f[15]), gradient_norm=parse(Float64,f[16]), runtime_seconds=parse(Float64,f[17]),
        peak_rss_mb=parse(Float64,f[18]), marker_hash=f[19], id_hash=f[20], kernel_hash=f[21], error_class=f[22])
end

function _validate_result_row(row, manifest, file)
    key = (row.tier, row.cell_id, row.seed)
    haskey(manifest, key) || error("result row is absent from immutable manifest: $(key)")
    mr = manifest[key]
    row.n == mr.n && row.m == mr.m && row.truth_sigma_g2 == mr.truth_sigma_g2 &&
        row.truth_sigma_e2 == mr.truth_sigma_e2 && row.truth_ratio == mr.truth_ratio &&
        row.ridge == mr.ridge || error("result row disagrees with manifest: $(key)")
    rel = splitpath(relpath(file, dirname(dirname(dirname(file)))))
    length(rel) == 3 && rel[1] == row.tier && rel[2] == row.cell_id &&
        rel[3] == string(row.seed) * ".tsv" || error("result path disagrees with row identity: $(file)")
    expected = _expected_provenance(_cell(row.cell_id), row.seed)
    row.marker_hash == expected.marker_hash || error("marker fingerprint mismatch: $(key)")
    row.id_hash == expected.id_hash || error("ID-order fingerprint mismatch: $(key)")
    row.kernel_hash == expected.kernel_hash || error("kernel fingerprint mismatch: $(key)")
    row
end

function _read_results(outdir, tier, manifest)
    root = joinpath(outdir, "raw", tier)
    isdir(root) || return NamedTuple[]
    rows = NamedTuple[]
    for (directory, _, names) in walkdir(root)
        for file in sort(joinpath.(directory, filter(name -> endswith(name, ".tsv"), names)))
            row = _read_result_file(file)
            push!(rows, _validate_result_row(row, manifest, file))
        end
    end
    rows
end

function _wilson(k,n)
    n==0 && return (NaN,NaN)
    phat=k/n; den=1+Z975^2/n; center=(phat+Z975^2/(2n))/den
    half=Z975*sqrt(phat*(1-phat)/n+Z975^2/(4n^2))/den
    (center-half,center+half)
end

const SUMMARY_COLUMNS = ["tier","cell_id","n_expected","n_attempted","n_converged","n_bias_rows",
    "convergence_rate","wilson_lower","wilson_upper","target","truth","mean_estimate","bias",
    "mcse","pilot_sd_upper","bias_ci_lower","bias_ci_upper","margin","target_pass","required_n_raw","required_n",
    "cell_status","failure_classes"]

function summarize_mode(args)
    tier=String(_opt(args,"tier","pilot")); tier in ("pilot","confirm") || error("invalid tier")
    outdir=abspath(_required(args,"out-dir"))
    manifest=_validate_campaign_manifest(outdir,tier)
    rows=_read_results(outdir,tier,manifest)
    seen=Set{Tuple{String,Int}}()
    for r in rows
        key=(r.cell_id,r.seed); key in seen && error("duplicate seed $(key)"); push!(seen,key)
    end
    summary=Vector{Vector{Any}}(); confirm_sizes=Dict{String,Int}()
    for cell in CELL_SPECS
        cr=filter(r->r.cell_id==cell.id,rows)
        expected = tier=="pilot" ? PILOT_REPS : begin
            mf=joinpath(outdir,"confirmation_manifest.tsv")
            isfile(mf) || error("confirmation_manifest.tsv is required")
            count(line->startswith(line,"confirm\t$(cell.id)\t"),eachline(mf))
        end
        eligible=filter(r->r.converged && all(isfinite,(r.estimate_sigma_g2,r.estimate_sigma_e2,r.estimate_ratio)),cr)
        nconv=length(eligible); natt=length(cr); rate=natt==0 ? NaN : nconv/natt; wl,wu=_wilson(nconv,natt)
        failures=join(["$(x)=$(count(r->r.error_class==x,cr))" for x in sort(unique(getproperty.(cr,:error_class)))],";")
        targets=(("sigma_g2",:estimate_sigma_g2,cell.ratio,0.05cell.ratio),
                 ("sigma_e2",:estimate_sigma_e2,1-cell.ratio,0.05(1-cell.ratio)),
                 ("ratio",:estimate_ratio,cell.ratio,0.02))
        rawmax=0
        target_stats=[]
        for (name,field,truth,margin) in targets
            vals=Float64[getproperty(r,field) for r in eligible]
            mn=isempty(vals) ? NaN : mean(vals); bias=mn-truth
            sdv=length(vals)>1 ? std(vals) : NaN; mcse=isfinite(sdv) ? sdv/sqrt(length(vals)) : NaN
            if tier=="pilot" && isfinite(sdv) && length(vals)>1
                sd_upper=_pilot_sd_upper(sdv,length(vals))
                raw=ceil(Int,(Z975*sd_upper/(margin/2))^2); rawmax=max(rawmax,raw)
                push!(target_stats,(name,truth,margin,mn,bias,mcse,sd_upper,NaN,NaN,false,raw))
            elseif tier=="confirm" && isfinite(mcse) && length(vals)>1
                critical=_tquantile(0.975,length(vals)-1); lo=bias-critical*mcse; hi=bias+critical*mcse
                pass=lo > -margin && hi < margin
                push!(target_stats,(name,truth,margin,mn,bias,mcse,NaN,lo,hi,pass,0))
            else
                push!(target_stats,(name,truth,margin,mn,bias,mcse,NaN,NaN,NaN,false,0))
            end
        end
        required=max(MIN_CONFIRM,rawmax); clamped=min(required,MAX_CONFIRM)
        status = if natt != expected
            "INCOMPLETE"
        elseif tier=="confirm" && expected==0
            "NOT_SCHEDULED"
        elseif tier=="pilot" && rate < PILOT_CONVERGENCE_MIN
            "STOP_LOW_PILOT_CONVERGENCE"
        elseif tier=="pilot" && required > MAX_CONFIRM
            "PRECISION_BLOCKER"
        elseif tier=="pilot"
            confirm_sizes[cell.id]=clamped; "CONFIRMATION_ELIGIBLE"
        else
            all(s[10] for s in target_stats) && rate >= CONFIRM_CONVERGENCE_MIN && wl >= WILSON_LOWER_MIN ? "PASS" : "FAIL"
        end
        for s in target_stats
            push!(summary,Any[tier,cell.id,expected,natt,nconv,length(eligible),rate,wl,wu,
                              s[1],s[2],s[4],s[5],s[6],s[7],s[8],s[9],s[3],s[10],s[11],clamped,status,failures])
        end
    end
    out=joinpath(outdir,"$(tier)_summary.tsv"); _write_table_exclusive(out,SUMMARY_COLUMNS,summary)
    if tier=="pilot"
        mf=joinpath(outdir,"confirmation_manifest.tsv")
        _write_table_exclusive(mf,MANIFEST_COLUMNS,_manifest_rows("confirm";confirm_sizes=confirm_sizes))
        _write_sha_sidecar(mf)
        println("wrote $(mf) eligible_cells=$(length(confirm_sizes))/9")
    end
    println("wrote $(out)")
end

function _must_fail(f, label)
    failed = false
    try
        f()
    catch
        failed = true
    end
    failed || error("negative control stayed green: $(label)")
end

function selftest_mode()
    abs(_tquantile(0.975, 47) - 2.0117405137297655) < 1e-12 || error("t quantile self-test failed")
    abs(_chisq_quantile(0.05, 47) - 32.2676215299732) < 1e-10 || error("chi-square quantile self-test failed")
    abs(_pilot_sd_upper(1.0, 48) - 1.206883783222356) < 1e-12 || error("pilot SD upper-bound self-test failed")
    cell = CELL_SPECS[1]
    seed = first(pilot_seeds(cell))
    provenance = _expected_provenance(cell, seed)
    mr = (tier="pilot", cell_id=cell.id, seed=seed, n=cell.n, m=cell.m,
          truth_sigma_g2=cell.ratio, truth_sigma_e2=1-cell.ratio,
          truth_ratio=cell.ratio, ridge=RIDGE, regime=cell.regime)
    manifest = Dict(("pilot", cell.id, seed) => mr)
    row = (tier="pilot", cell_id=cell.id, seed=seed, n=cell.n, m=cell.m,
           truth_sigma_g2=cell.ratio, truth_sigma_e2=1-cell.ratio,
           truth_ratio=cell.ratio, ridge=RIDGE,
           estimate_sigma_g2=NaN, estimate_sigma_e2=NaN, estimate_ratio=NaN,
           converged=false, iterations=-1, objective=NaN, gradient_norm=NaN,
           runtime_seconds=0.0, peak_rss_mb=0.0,
           marker_hash=provenance.marker_hash, id_hash=provenance.id_hash,
           kernel_hash=provenance.kernel_hash, error_class="test")
    path = joinpath("/tmp", "raw", "pilot", cell.id, string(seed) * ".tsv")
    _validate_result_row(row, manifest, path)
    _must_fail("truth") do
        _validate_result_row(merge(row, (truth_ratio=row.truth_ratio + 0.01,)), manifest, path)
    end
    _must_fail("ridge") do
        _validate_result_row(merge(row, (ridge=0.02,)), manifest, path)
    end
    _must_fail("marker fingerprint") do
        _validate_result_row(merge(row, (marker_hash="mutated",)), manifest, path)
    end
    _must_fail("ID order fingerprint") do
        _validate_result_row(merge(row, (id_hash="mutated",)), manifest, path)
    end
    _must_fail("kernel fingerprint") do
        _validate_result_row(merge(row, (kernel_hash="mutated",)), manifest, path)
    end
    _must_fail("cell label") do
        _validate_result_row(merge(row, (cell_id=CELL_SPECS[2].id,)), manifest, path)
    end
    println("selftest: PASS")
end

function main(args=ARGS)
    mode=String(_opt(args,"mode","run"))
    mode=="run" ? run_mode(args) : mode=="manifest" ? manifest_mode(args) :
        mode=="summarize" ? summarize_mode(args) : mode=="selftest" ? selftest_mode() :
        error("--mode must be run, manifest, summarize, or selftest")
end

abspath(PROGRAM_FILE) == abspath(@__FILE__) && main()
