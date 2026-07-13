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
    "truth_ratio", "estimate_sigma_g2", "estimate_sigma_e2", "estimate_ratio",
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
    base = Any[tier, cell.id, seed, cell.n, cell.m, sg2, se2, cell.ratio]
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

function _validate_campaign_manifest(outdir)
    path = joinpath(outdir, "environment_manifest.txt")
    isfile(path) || error("missing environment_manifest.txt; run --mode=manifest first")
    settings = Dict(begin
        parts = split(line, "="; limit=2)
        parts[1] => parts[2]
    end for line in eachline(path) if occursin('=', line))
    expected = get(settings, "driver_sha256", "")
    observed = bytes2hex(sha256(read(@__FILE__)))
    expected == observed || error("driver changed since manifest creation; use a fresh out-dir")
end

function run_mode(args)
    _assert_single_threaded()
    tier = String(_opt(args, "tier", "pilot"))
    tier in ("pilot", "confirm") || error("--tier must be pilot or confirm")
    cell = _cell(_required(args, "cell"))
    seed = parse(Int, _required(args, "seed"))
    allowed = tier == "pilot" ? (seed in pilot_seeds(cell)) :
              (seed in confirm_seeds(cell, MAX_CONFIRM))
    allowed || error("seed $(seed) is outside the frozen $(tier) block for $(cell.id)")
    outdir = abspath(_required(args, "out-dir"))
    _validate_campaign_manifest(outdir)
    path = _result_path(outdir, tier, cell.id, seed)
    if _bool(args, "resume", true) && _valid_existing(path, tier, cell.id, seed)
        println("resume: already complete $(path)")
        return
    end
    row = _run_seed(cell, tier, seed)
    _write_atomic(path, row)
    println("wrote $(path) converged=$(row[12]) error_class=$(row[end])")
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

function manifest_mode(args)
    tier = String(_opt(args, "tier", "pilot"))
    tier == "pilot" || error("confirmation manifests are generated from pilot summaries")
    outdir = abspath(_required(args, "out-dir"))
    for cell in CELL_SPECS
        isempty(intersect(Set(pilot_seeds(cell)), Set(confirm_seeds(cell, MAX_CONFIRM)))) ||
            error("pilot/confirmation seed overlap for $(cell.id)")
    end
    path = joinpath(outdir, "pilot_manifest.tsv")
    _write_table(path, MANIFEST_COLUMNS, _manifest_rows("pilot"))
    manifest_sha256 = bytes2hex(sha256(read(path)))
    driver_sha256 = bytes2hex(sha256(read(@__FILE__)))
    git_commit = try readchomp(`git rev-parse HEAD`) catch; "unknown" end
    open(joinpath(outdir, "environment_manifest.txt"), "w") do io
        println(io, "campaign=v07_genomic_activation_recovery")
        println(io, "julia=$(VERSION)")
        println(io, "hsquared_project=$(Base.active_project())")
        println(io, "ridge=$(RIDGE)")
        println(io, "pilot_reps=$(PILOT_REPS)")
        println(io, "git_commit=$(git_commit)")
        println(io, "driver_sha256=$(driver_sha256)")
        println(io, "pilot_manifest_sha256=$(manifest_sha256)")
    end
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

function _read_results(outdir, tier)
    root = joinpath(outdir, "raw", tier)
    isdir(root) || return NamedTuple[]
    rows = NamedTuple[]
    for (directory, _, names) in walkdir(root)
        for file in sort(joinpath.(directory, filter(name -> endswith(name, ".tsv"), names)))
            lines=readlines(file); length(lines)==2 || error("malformed result file $(file)")
            split(lines[1],'\t')==RESULT_COLUMNS || error("schema drift in $(file)")
            f=split(lines[2],'\t'); length(f)==length(RESULT_COLUMNS) || error("malformed row in $(file)")
            push!(rows, (tier=f[1], cell_id=f[2], seed=parse(Int,f[3]), n=parse(Int,f[4]), m=parse(Int,f[5]),
                truth_sigma_g2=parse(Float64,f[6]), truth_sigma_e2=parse(Float64,f[7]), truth_ratio=parse(Float64,f[8]),
                estimate_sigma_g2=parse(Float64,f[9]), estimate_sigma_e2=parse(Float64,f[10]), estimate_ratio=parse(Float64,f[11]),
                converged=lowercase(f[12])=="true", error_class=f[21]))
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
    "mcse","bias_ci_lower","bias_ci_upper","margin","target_pass","required_n_raw","required_n",
    "cell_status","failure_classes"]

function summarize_mode(args)
    tier=String(_opt(args,"tier","pilot")); tier in ("pilot","confirm") || error("invalid tier")
    outdir=abspath(_required(args,"out-dir"))
    rows=_read_results(outdir,tier)
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
                raw=ceil(Int,(Z975*sdv/(margin/2))^2); rawmax=max(rawmax,raw)
                push!(target_stats,(name,truth,margin,mn,bias,mcse,NaN,NaN,false,raw))
            elseif tier=="confirm" && isfinite(mcse) && length(vals)>1
                critical=_tquantile(0.975,length(vals)-1); lo=bias-critical*mcse; hi=bias+critical*mcse
                pass=lo > -margin && hi < margin
                push!(target_stats,(name,truth,margin,mn,bias,mcse,lo,hi,pass,0))
            else
                push!(target_stats,(name,truth,margin,mn,bias,mcse,NaN,NaN,false,0))
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
            all(s[9] for s in target_stats) && rate >= CONFIRM_CONVERGENCE_MIN && wl >= WILSON_LOWER_MIN ? "PASS" : "FAIL"
        end
        for s in target_stats
            push!(summary,Any[tier,cell.id,expected,natt,nconv,length(eligible),rate,wl,wu,s[1],s[2],s[4],s[5],s[6],s[7],s[8],s[3],s[9],s[10],clamped,status,failures])
        end
    end
    out=joinpath(outdir,"$(tier)_summary.tsv"); _write_table(out,SUMMARY_COLUMNS,summary)
    if tier=="pilot"
        mf=joinpath(outdir,"confirmation_manifest.tsv")
        _write_table(mf,MANIFEST_COLUMNS,_manifest_rows("confirm";confirm_sizes=confirm_sizes))
        open(mf * ".sha256", "w") do io
            println(io, bytes2hex(sha256(read(mf))), "  confirmation_manifest.tsv")
        end
        println("wrote $(mf) eligible_cells=$(length(confirm_sizes))/9")
    end
    println("wrote $(out)")
end

function main(args=ARGS)
    mode=String(_opt(args,"mode","run"))
    mode=="run" ? run_mode(args) : mode=="manifest" ? manifest_mode(args) :
        mode=="summarize" ? summarize_mode(args) : error("--mode must be run, manifest, or summarize")
end

abspath(PROGRAM_FILE) == abspath(@__FILE__) && main()
