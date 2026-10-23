using Dates
using HSquared
using LinearAlgebra
using Printf
using Random
using SHA
using Sockets
using Statistics

const DEV_SEED = 20261400
const PRIMARY_SEEDS = 20261200:20261399
const ITERATIONS = 5_000
const DLOG_TOL = 1e-6
const REL_G_TOL = 0.45
const REL_R_TOL = 0.25
const PSI_FLOOR = 1e-4
const LEDERMANN_SLACK = (4 - 1)^2 - (4 + 1)

function _parse(args)
    opts = Dict{String,String}()
    for arg in args
        startswith(arg, "--") || error("arguments must use --key=value form: $arg")
        pair = split(arg[3:end], "=", limit = 2)
        length(pair) == 2 || error("arguments must use --key=value form: $arg")
        opts[pair[1]] = pair[2]
    end
    mode = get(opts, "mode", "")
    mode in ("development", "primary") || error("set --mode=development or --mode=primary")
    seeds = if mode == "development"
        parse.(Int, split(get(opts, "seeds", string(DEV_SEED)), ","))
    else
        requested = parse.(Int, split(get(opts, "seeds", join(PRIMARY_SEEDS, ",")), ","))
        requested == collect(PRIMARY_SEEDS) ||
            error("primary mode is frozen to seeds $(first(PRIMARY_SEEDS)):$(last(PRIMARY_SEEDS))")
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
    sire_ids = ["s$(i)" for i in 1:nsire]
    dam_ids = ["d$(i)" for i in 1:ndam]
    offspring_ids = ["o$(i)" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, offspring_ids)
    sire = vcat(fill("0", nsire + ndam),
                 [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring])
    dam = vcat(fill("0", nsire + ndam),
                [dam_ids[((i - 1) % ndam) + 1] for i in 1:noffspring])
    return normalize_pedigree(ids, sire, dam)
end

function _simulate(seed::Int)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(6, 12, 42)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q, t, records_per_animal = length(ped.ids), 4, 3
    loadings = reshape([0.9, 0.55, -0.35, 0.40], t, 1)
    uniqueness = [0.35, 0.45, 0.55, 0.50]
    G = Matrix(factor_analytic_covariance(loadings, uniqueness))
    R = [0.85 0.18 0.05 0.06;
         0.18 0.75 -0.08 0.04;
         0.05 -0.08 0.65 0.03;
         0.06 0.04 0.03 0.70]
    isposdef(Symmetric(G)) || error("G is not positive definite")
    isposdef(Symmetric(R)) || error("R is not positive definite")
    slack = (t - 1)^2 - (t + 1)
    slack == LEDERMANN_SLACK == 4 || error("unexpected Ledermann slack: $slack")

    LA = cholesky(Symmetric(A)).L
    LG = cholesky(Symmetric(G)).L
    LR = cholesky(Symmetric(R)).L
    U = LA * randn(rng, q, t) * transpose(LG)
    n = q * records_per_animal
    X = ones(n, 1)
    Z = zeros(n, q)
    Y = zeros(n, t)
    row = 0
    for animal in 1:q, _ in 1:records_per_animal
        row += 1
        Z[row, animal] = 1.0
        Y[row, :] .= 1.5 .+ U[animal, :] .+
                     (randn(rng, 1, t) * transpose(LR))[1, :]
    end
    return (; Y, X, Z, Ainv, G, R, ids = ped.ids, q, t, n, slack)
end

_relerr(x, truth) = norm(x - truth) / norm(truth)
_tf(x) = x ? "true" : "false"
_num(x) = x === nothing ? "NA" : isfinite(x) ? @sprintf("%.12g", x) : "NA"
_safe(x) = replace(replace(string(x), '\t' => ' '), '\n' => ' ')

function _tree_sha256(root::AbstractString)
    paths = String[]
    for (directory, _, files) in walkdir(root)
        append!(paths, joinpath(directory, file) for file in files)
    end
    sort!(paths)
    io = IOBuffer()
    for path in paths
        write(io, replace(relpath(path, root), '\\' => '/'))
        write(io, UInt8(0))
        write(io, read(path))
        write(io, UInt8(0))
    end
    return bytes2hex(SHA.sha256(take!(io)))
end

function _source_provenance()
    repo_root = dirname(@__DIR__)
    driver_path = joinpath(@__DIR__, basename(@__FILE__))
    return (
        source_tree_sha256 = _tree_sha256(joinpath(repo_root, "src")),
        driver_sha256 = bytes2hex(SHA.sha256(read(driver_path))),
    )
end

_optional_tf(x) = x === nothing ? "NA" : _tf(x)

function _diagnostic_values(diag)
    return (
        objective_range = _num(diag.objective_range),
        uniqueness_floor_distance = _num(diag.uniqueness_floor_distance),
        near_uniqueness_floor = _optional_tf(diag.near_uniqueness_floor),
        g_relative_disagreement = _num(diag.g_relative_disagreement),
        r_relative_disagreement = _num(diag.r_relative_disagreement),
        better_nonconverged_start = _optional_tf(diag.better_nonconverged_start),
    )
end

function _fit_seed(seed::Int, mode::String; simulate = _simulate)
    fit_start_time = nothing
    try
        sim = simulate(seed)
        truth_loglik = HSquared._multivariate_reml_loglik(
            sim.Y, sim.X, sim.Z, sim.Ainv, sim.G, sim.R)
        fit_start_time = time()
        # `initial` is deliberately omitted: this is the public ordinary-start path.
        fit = fit_multivariate_reml(
            sim.Y, sim.X, sim.Z, sim.Ainv;
            genetic_structure = :factor_analytic,
            rank = 1,
            iterations = ITERATIONS,
            ids = sim.ids,
            traits = ["t1", "t2", "t3", "t4"],
        )
        elapsed = time() - fit_start_time
        Ghat = Matrix(fit.genetic_covariance)
        Rhat = Matrix(fit.residual_covariance)
        psi = Float64.(fit.genetic_uniqueness)
        finite = isfinite(fit.loglik) && all(isfinite, Ghat) && all(isfinite, Rhat) &&
                 length(psi) == 4 && all(isfinite, psi)
        rel_g = finite ? _relerr(Ghat, sim.G) : NaN
        rel_r = finite ? _relerr(Rhat, sim.R) : NaN
        dlog = isfinite(fit.loglik) ? fit.loglik - truth_loglik : NaN
        diag = fit.fa_start_diagnostics
        diag_values = _diagnostic_values(diag)
        per_start = join((string(s.name, ":", s.valid, ":", s.converged, ":", s.iterations)
                          for s in diag.starts), ";")
        recovered = fit.converged && finite && rel_g <= REL_G_TOL && rel_r <= REL_R_TOL &&
                    minimum(psi) >= PSI_FLOOR && dlog >= -DLOG_TOL && sim.slack > 0
        class = recovered ? "recovered" : !fit.converged ? "nonconverged" :
                !finite ? "nonfinite" : minimum(psi) < PSI_FLOOR ? "uniqueness_floor" :
                rel_g > REL_G_TOL ? "G_error" : rel_r > REL_R_TOL ? "R_error" :
                dlog < -DLOG_TOL ? "below_truth_objective" : "other_failure"
        return (seed, mode, "ok", _tf(fit.converged), _tf(recovered), class,
                _num(rel_g), _num(rel_r), _num(dlog), _num(minimum(psi)),
                string(fit.iterations), string(diag.strategy), string(diag.starts_attempted),
                string(diag.selected_start), diag_values.objective_range,
                diag_values.uniqueness_floor_distance,
                diag_values.near_uniqueness_floor,
                diag_values.g_relative_disagreement,
                diag_values.r_relative_disagreement,
                diag_values.better_nonconverged_start, per_start,
                _num(elapsed), "")
    catch err
        elapsed = fit_start_time === nothing ? NaN : time() - fit_start_time
        return (seed, mode, "exception", "false", "false", "exception",
                "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA",
                "NA", "NA", "NA", "NA", "NA", "NA", _num(elapsed),
                _safe(sprint(showerror, err)))
    end
end

function _wilson(phat, n; z = 1.959963984540054)
    denom = 1 + z^2 / n
    center = (phat + z^2 / (2n)) / denom
    half = z * sqrt(phat * (1 - phat) / n + z^2 / (4n^2)) / denom
    return center - half, center + half
end

function main(args = ARGS)
    if get(ENV, "HSQUARED_RUN_FA_ORDINARY_START", "0") != "1"
        @info "opt-in only; set HSQUARED_RUN_FA_ORDINARY_START=1 to run"
        return
    end
    opts = _parse(args)
    mkpath(dirname(abspath(opts.out)))
    provenance = _source_provenance()
    manifest = [
        "# ordinary-start FA recovery; mode=$(opts.mode); timestamp=$(Dates.now())",
        "# source_tree_sha256=$(provenance.source_tree_sha256); driver_sha256=$(provenance.driver_sha256); host=$(gethostname())",
        "# julia=$(VERSION); threads=$(Threads.nthreads()); BLAS_threads=$(BLAS.get_num_threads())",
        "# seeds=$(first(opts.seeds)):$(last(opts.seeds)); attempts=$(length(opts.seeds)); iterations=$(ITERATIONS)",
        "# DGP: 60 pedigree animals (6 sires,12 dams,42 offspring), 3 records each, T=4,K=1, complete; slack=$(LEDERMANN_SLACK)",
        "# no initial supplied; criteria: conv, finite, relG<=$(REL_G_TOL), relR<=$(REL_R_TOL), minPsi>=$(PSI_FLOOR), dlog>=-$(DLOG_TOL), slack>0",
        "# thresholds reused from frozen S2 as conservative diagnostics; not a validated ordinary-start accuracy bar",
    ]
    header = "seed\tmode\tfit_status\tconverged\trecovered\tclass\trel_G\trel_R\tdlog\tmin_psi\titerations\tstrategy\tstarts_attempted\tselected_start\tobjective_range\tuniqueness_floor_distance\tnear_uniqueness_floor\tg_relative_disagreement\tr_relative_disagreement\tbetter_nonconverged_start\tper_start\tseconds\terror"
    open(opts.out, "w") do io
        foreach(line -> println(io, line), manifest)
        println(io, header)
        recovered = 0
        for seed in opts.seeds
            row = _fit_seed(seed, opts.mode)
            println(io, join(row, '\t'))
            flush(io)
            recovered += row[5] == "true"
            @printf("seed=%d class=%s recovered=%s seconds=%s\n", row[1], row[6], row[5], row[22])
        end
        if opts.mode == "primary"
            n = length(opts.seeds)
            phat = recovered / n
            mcse = sqrt(phat * (1 - phat) / n)
            lo, hi = _wilson(phat, n)
            println(io, "# summary n=$n recovered=$recovered rate=$(_num(phat)) mcse=$(_num(mcse)) wilson95=[$(_num(lo)),$(_num(hi))]")
            @printf("SUMMARY n=%d recovered=%d rate=%.6f MCSE=%.6f Wilson95=[%.6f, %.6f]\n",
                    n, recovered, phat, mcse, lo, hi)
        end
    end
    println("WROTE ", abspath(opts.out))
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
