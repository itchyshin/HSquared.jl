using Dates
using HSquared
using LinearAlgebra
using Printf
using Random
using Sockets

const DEV_SEED = 20261699
const PRIMARY_SEEDS = 20261600:20261649
const OUTER_ITERATIONS = 1_000
const REL_G_TOL = 0.45
const MEAN_ABS_COR_TOL = 0.25
const SYMMETRY_RTOL = 1e-10
const PSD_RTOL = 1e-8
const MIN_SUCCESSES = 45

function _rand_poisson(rng, λ)
    L = exp(-λ)
    k = 0
    p = 1.0
    while true
        k += 1
        p *= rand(rng)
        p <= L && return k - 1
    end
end

function _parse(args)
    opts = Dict{String,String}()
    for arg in args
        startswith(arg, "--") || error("arguments must use --key=value form: $arg")
        pair = split(arg[3:end], "=", limit = 2)
        length(pair) == 2 || error("arguments must use --key=value form: $arg")
        opts[pair[1]] = pair[2]
    end
    mode = get(opts, "mode", "")
    mode in ("development", "primary", "replay") ||
        error("set --mode=development, --mode=primary, or --mode=replay")
    seeds = if mode == "development"
        parse.(Int, split(get(opts, "seeds", string(DEV_SEED)), ","))
    else
        requested = parse.(Int, split(get(opts, "seeds", join(PRIMARY_SEEDS, ",")), ","))
        requested == collect(PRIMARY_SEEDS) ||
            error("$mode mode is frozen to seeds $(first(PRIMARY_SEEDS)):$(last(PRIMARY_SEEDS))")
        requested
    end
    mode == "development" && any(in(PRIMARY_SEEDS), seeds) &&
        error("development seed overlaps the frozen primary stream")
    isempty(seeds) && error("at least one seed is required")
    out = get(opts, "out", "")
    isempty(out) && error("set --out=PATH explicitly")
    return (; mode, seeds, out)
end

function _halfsib_pedigree(nsire, ndam, noffspring)
    sire_ids = ["s$i" for i in 1:nsire]
    dam_ids = ["d$i" for i in 1:ndam]
    offspring_ids = ["o$i" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, offspring_ids)
    sire = vcat(fill("0", nsire + ndam),
                [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring])
    dam = vcat(fill("0", nsire + ndam),
               [dam_ids[((i - 1) % ndam) + 1] for i in 1:noffspring])
    return normalize_pedigree(ids, sire, dam)
end

function _simulate(seed::Int)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(10, 20, 90)
    Ainv = Matrix(pedigree_inverse(ped))
    A = Matrix(inv(Symmetric(Ainv)))
    q, T, K = length(ped.ids), 3, 2
    Λ = [1.0 0.0; 0.5 0.8; 0.3 0.9]
    β = ones(T)
    G = Λ * transpose(Λ)
    LA = cholesky(Symmetric(A)).L
    factors = hcat((LA * randn(rng, q) for _ in 1:K)...)
    η = ones(q) * transpose(β) + factors * transpose(Λ)
    Y = Matrix{Float64}(undef, q, T)
    for i in 1:q, t in 1:T
        λ = exp(η[i, t])
        isfinite(λ) && λ > 0 || error("non-finite Poisson mean at animal $i, trait $t")
        Y[i, t] = Float64(_rand_poisson(rng, λ))
    end
    return (; Y, Ainv, G, ids = ped.ids, q, T, K, Λ, β)
end

_num(x) = isfinite(x) ? @sprintf("%.12g", x) : "NA"
_tf(x) = x ? "true" : "false"
_safe(x) = replace(replace(string(x), '\t' => ' '), '\n' => ' ')

function _mean_abs_cor_error(Ghat, Gtrue)
    chat = HSquared.genetic_correlation(Ghat)
    ctrue = HSquared.genetic_correlation(Gtrue)
    T = size(Gtrue, 1)
    return sum(abs(chat[i, j] - ctrue[i, j]) for i in 1:T for j in (i + 1):T) /
           (T * (T - 1) / 2)
end

function _fit_seed(seed::Int, mode::String)
    total_start = time()
    try
        sim = _simulate(seed)
        fit_start = time()
        # `initial` is deliberately omitted to match the ordinary R opt-in route.
        fit = HSquared.fit_gllvm_laplace_reml(
            sim.Y, sim.Ainv, HSquared.PoissonResponse();
            rank = 2,
            structure = :lowrank,
            X = ones(sim.q, 1),
            iterations = OUTER_ITERATIONS,
        )
        fit_seconds = time() - fit_start
        Ghat = Matrix(fit.genetic_covariance)
        U = Matrix(fit.breeding_values)
        shape_ok = size(Ghat) == (3, 3) && size(U) == (sim.q, 3)
        finite = shape_ok && isfinite(fit.loglik) && all(isfinite, Ghat) && all(isfinite, U)
        if finite
            sym_error = norm(Ghat - transpose(Ghat), Inf)
            sym_limit = SYMMETRY_RTOL * max(1.0, norm(Ghat, Inf))
            Gsym = Symmetric((Ghat + transpose(Ghat)) / 2)
            min_eigenvalue = minimum(eigvals(Gsym))
            psd_limit = -PSD_RTOL * max(1.0, opnorm(Matrix(Gsym), 2))
            rel_G = norm(Ghat - sim.G) / norm(sim.G)
            mean_abs_cor_error = _mean_abs_cor_error(Ghat, sim.G)
        else
            sym_error = min_eigenvalue = rel_G = mean_abs_cor_error = NaN
            sym_limit = psd_limit = NaN
        end
        symmetry_ok = finite && sym_error <= sym_limit
        psd_ok = finite && min_eigenvalue >= psd_limit
        converged = fit.optimizer_converged && fit.mode_converged && fit.converged &&
                    fit.mode_stop_reason == :converged
        recovered = converged && finite && symmetry_ok && psd_ok &&
                    rel_G <= REL_G_TOL && mean_abs_cor_error <= MEAN_ABS_COR_TOL
        class = recovered ? "recovered" : !converged ? "nonconverged" : !shape_ok ? "shape" :
                !finite ? "nonfinite" : !symmetry_ok ? "covariance_symmetry" : !psd_ok ?
                "covariance_psd" : rel_G > REL_G_TOL ? "G_error" :
                mean_abs_cor_error > MEAN_ABS_COR_TOL ? "correlation_error" : "other_failure"
        total_seconds = time() - total_start
        return (seed, mode, "ok", _tf(fit.optimizer_converged), _tf(fit.mode_converged),
                _tf(converged), _tf(recovered), class, _num(rel_G),
                _num(mean_abs_cor_error), _num(sym_error), _num(sym_limit),
                _num(min_eigenvalue), _num(psd_limit), string(fit.iterations),
                string(fit.mode_iterations), String(fit.mode_stop_reason),
                _num(fit.mode_gradient_norm), _num(fit.loglik), _num(fit_seconds),
                _num(total_seconds), "", _num(Ghat[1, 1]), _num(Ghat[1, 2]),
                _num(Ghat[1, 3]), _num(Ghat[2, 2]), _num(Ghat[2, 3]), _num(Ghat[3, 3]))
    catch err
        total_seconds = time() - total_start
        return (seed, mode, "exception", "false", "false", "false", "false", "exception",
                "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "exception",
                "NA", "NA", "NA", _num(total_seconds), _safe(sprint(showerror, err)),
                "NA", "NA", "NA", "NA", "NA", "NA")
    end
end

function _wilson(phat, n; z = 1.959963984540054)
    denom = 1 + z^2 / n
    center = (phat + z^2 / (2n)) / denom
    half = z * sqrt(phat * (1 - phat) / n + z^2 / (4n^2)) / denom
    return center - half, center + half
end

function main(args = ARGS)
    if get(ENV, "HSQUARED_RUN_GLLVM_ORDINARY_START", "0") != "1"
        @info "opt-in only; set HSQUARED_RUN_GLLVM_ORDINARY_START=1 to run"
        return
    end
    Threads.nthreads() <= 4 || error("use at most 4 Julia threads")
    BLAS.set_num_threads(1)
    opts = _parse(args)
    mkpath(dirname(abspath(opts.out)))
    manifest = [
        "# genetic GLLVM ordinary-start recovery; mode=$(opts.mode); timestamp=$(Dates.now())",
        "# source_sha=$(get(ENV, "HSQUARED_SOURCE_SHA", "unset")); driver_sha=$(get(ENV, "HSQUARED_DRIVER_SHA", "unset")); host=$(gethostname())",
        "# julia=$(VERSION); threads=$(Threads.nthreads()); BLAS_threads=$(BLAS.get_num_threads())",
        "# seeds=$(first(opts.seeds)):$(last(opts.seeds)); attempts=$(length(opts.seeds)); outer_iterations=$(OUTER_ITERATIONS); inner_maxiter=200",
        "# DGP: 120 pedigree animals (10 sires,20 dams,90 offspring), one row per animal, T=3,K=2, complete; Poisson-log; beta=1 per trait",
        "# initial omitted; default single Nelder-Mead start; success requires outer+inner convergence, finite link modes, symmetric PSD G, relG<=$(REL_G_TOL), mean_abs_corr<=$(MEAN_ABS_COR_TOL)",
    ]
    header = "seed\tmode\tfit_status\toptimizer_converged\tmode_converged\tconverged\trecovered\tclass\trel_G\tmean_abs_cor_error\tsymmetry_error\tsymmetry_limit\tmin_eigenvalue\tpsd_limit\touter_iterations\tinner_iterations\tinner_stop_reason\tinner_gradient_norm\tloglik\tfit_seconds\ttotal_seconds\terror\tG11\tG12\tG13\tG22\tG23\tG33"
    open(opts.out, "w") do io
        foreach(line -> println(io, line), manifest)
        println(io, header)
        recovered = 0
        classes = Dict{String,Int}()
        total_seconds = 0.0
        for seed in opts.seeds
            row = _fit_seed(seed, opts.mode)
            println(io, join(row, '\t'))
            flush(io)
            recovered += row[7] == "true"
            classes[row[8]] = get(classes, row[8], 0) + 1
            total_seconds += tryparse(Float64, row[21]) === nothing ? 0.0 : parse(Float64, row[21])
            @printf("seed=%d class=%s recovered=%s fit_seconds=%s\n", row[1], row[8], row[7], row[20])
        end
        if opts.mode in ("primary", "replay")
            n = length(opts.seeds)
            phat = recovered / n
            mcse = sqrt(phat * (1 - phat) / n)
            lo, hi = _wilson(phat, n)
            counts = join(("$k=$v" for (k, v) in sort(collect(classes))), ",")
            println(io, "# summary n=$n recovered=$recovered rate=$(_num(phat)) mcse=$(_num(mcse)) wilson95=[$(_num(lo)),$(_num(hi))] failures=$counts total_seconds=$(_num(total_seconds))")
            @printf("SUMMARY n=%d recovered=%d minimum=%d rate=%.6f MCSE=%.6f Wilson95=[%.6f, %.6f] classes=%s total_seconds=%.2f\n",
                    n, recovered, MIN_SUCCESSES, phat, mcse, lo, hi, counts, total_seconds)
        end
    end
    println("WROTE ", abspath(opts.out))
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
