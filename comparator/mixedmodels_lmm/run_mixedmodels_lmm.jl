# MixedModels.jl comparator lane (HSquared.jl #275): same-estimand REML agreement and wall
# time on the shared Gaussian LMM surface (see lmm_surface.jl for the surface and its limits).
#
#   julia +1.12 --project=comparator/mixedmodels_lmm -e 'using Pkg; Pkg.instantiate()'
#   OPENBLAS_NUM_THREADS=1 HSQUARED_RUN_MIXEDMODELS=true \
#     julia +1.12 --project=comparator/mixedmodels_lmm comparator/mixedmodels_lmm/run_mixedmodels_lmm.jl \
#     [--reps 3] [--scenarios name1,name2] [--rtol-var 1e-3] [--rtol-beta 1e-6]
#
# Without HSQUARED_RUN_MIXEDMODELS=true this prints a skip notice and exits 0 BEFORE
# MixedModels is imported. MixedModels is never a dependency of HSquared.jl.
#
# This reports agreement and wall time. It is not a claim of superiority, not a speed
# claim beyond the printed machine/versions/threads, and not a replacement for the sommer
# agreement gate. It moves no capability row to `covered`.

include(joinpath(@__DIR__, "lmm_surface.jl"))
using .HSquaredMixedModelsSurface

if !mixedmodels_lane_enabled()
    println("MixedModels.jl comparator: SKIPPED (set HSQUARED_RUN_MIXEDMODELS=true to run).")
    exit(0)
end

using MixedModels
using DataFrames
using Statistics
using Dates
using Printf
using LinearAlgebra

function _arg(name, default)
    i = findfirst(==(name), ARGS)
    return i === nothing ? default : ARGS[i + 1]
end

const REPS = parse(Int, _arg("--reps", "3"))
const RTOL_VAR = parse(Float64, _arg("--rtol-var", "1e-3"))
const RTOL_BETA = parse(Float64, _arg("--rtol-beta", "1e-6"))
const WANT = let s = _arg("--scenarios", "")
    isempty(s) ? Symbol[] : Symbol.(split(s, ","))
end

function mixedmodels_lmm_fit(d::LMMData)
    t0 = time_ns()
    n = length(d.y)
    K = length(d.groups)
    ncov = size(d.X, 2) - 1
    df = DataFrame(y = d.y)
    ncov == 1 && (df.x = d.X[:, 2])
    for k in 1:K
        df[!, Symbol("g", k)] = string.("a", d.groups[k])
    end
    f = if K == 1 && ncov == 0
        @formula(y ~ 1 + (1 | g1))
    elseif K == 1 && ncov == 1
        @formula(y ~ 1 + x + (1 | g1))
    elseif K == 2 && ncov == 1
        @formula(y ~ 1 + x + (1 | g1) + (1 | g2))
    else
        error("no MixedModels formula wired for K=$K, ncov=$ncov")
    end
    m = fit(MixedModel, f, df; REML = true, progress = false)
    seconds = (time_ns() - t0) / 1e9
    sig = [first(values(m.σs[Symbol("g", k)]))^2 for k in 1:K]
    rv = m.optsum.returnvalue
    return (sigmas = sig, sigma_e2 = m.σ^2, beta = collect(Float64, fixef(m)),
            converged = rv in (:FTOL_REACHED, :XTOL_REACHED, :SUCCESS, :STOPVAL_REACHED),
            returnvalue = rv, singular = issingular(m),
            feval = m.optsum.feval, seconds = seconds)
end

function _gitrev()
    try
        return strip(read(setenv(`git rev-parse --short HEAD`; dir = @__DIR__), String))
    catch
        return "unknown"
    end
end

function main()
    host = gethostname()
    rev = _gitrev()
    mmver = string(pkgversion(MixedModels))
    println("MixedModels.jl comparator lane (HSquared.jl #275)")
    println("host=$host julia=$VERSION MixedModels=$mmver HSquared@$rev ",
            "julia_threads=$(Threads.nthreads()) blas_threads=$(BLAS.get_num_threads())")
    println("tolerances: variance rtol=$RTOL_VAR, fixed-effect rtol=$RTOL_BETA; reps=$REPS")

    scs = isempty(WANT) ? SCENARIOS : filter(sc -> sc.name in WANT, SCENARIOS)
    isempty(scs) && error("no scenario matched --scenarios")

    # Warm-up on a small design so compile time is in neither engine's timing.
    warm = simulate_lmm(SCENARIOS[2])
    engine_lmm_fit(warm); mixedmodels_lmm_fit(warm)

    outdir = joinpath(@__DIR__, "..", "results")
    mkpath(outdir)
    stem = joinpath(outdir, "mixedmodels_lmm_$(rev)_$(host)")
    agree_rows = String["scenario\tquantity\thsquared\tmixedmodels\tabsdiff\treldiff\ttol\tpass"]
    time_rows = String["scenario\tn\tngroups\thsquared_median_s\thsquared_min_s\tmixedmodels_median_s\tmixedmodels_min_s\tratio_hs_over_mm\thsquared_iter\tmixedmodels_feval\thsquared_converged\tmixedmodels_converged\tmixedmodels_singular\tagree"]
    all_ok = true
    for sc in scs
        d = simulate_lmm(sc)
        eng = [engine_lmm_fit(d) for _ in 1:REPS]
        mm = [mixedmodels_lmm_fit(d) for _ in 1:REPS]
        e1, m1 = eng[1], mm[1]
        cmp = compare_lmm(e1, m1; rtol_var = RTOL_VAR, rtol_beta = RTOL_BETA)
        all_ok &= cmp.agree
        es = [r.seconds for r in eng]; ms = [r.seconds for r in mm]
        @printf("\n[%s] n=%d groups=%s  HSquared median %.3fs (min %.3fs, %d iter)  MixedModels median %.3fs (min %.3fs, %d feval)  ratio HS/MM %.2f  agree=%s\n",
                sc.name, sc.n, string(sc.ngroups), median(es), minimum(es), e1.iterations,
                median(ms), minimum(ms), m1.feval, median(es) / median(ms), cmp.agree)
        for r in cmp.rows
            @printf("  %-14s HSquared %-14.8g MixedModels %-14.8g reldiff %.2e (tol %.0e) %s\n",
                    r.quantity, r.engine, r.other, r.reldiff, r.tol, r.pass ? "ok" : "FAIL")
            push!(agree_rows, join([sc.name, r.quantity, @sprintf("%.12g", r.engine),
                @sprintf("%.12g", r.other), @sprintf("%.3e", r.absdiff),
                @sprintf("%.3e", r.reldiff), @sprintf("%.0e", r.tol), r.pass], "\t"))
        end
        m1.singular && println("  note: MixedModels reports a singular fit (a variance at the boundary).")
        push!(time_rows, join([sc.name, sc.n, join(sc.ngroups, "x"),
            @sprintf("%.4f", median(es)), @sprintf("%.4f", minimum(es)),
            @sprintf("%.4f", median(ms)), @sprintf("%.4f", minimum(ms)),
            @sprintf("%.3f", median(es) / median(ms)), e1.iterations, m1.feval,
            e1.converged, m1.converged, m1.singular, cmp.agree], "\t"))
    end
    write(stem * "_agreement.tsv", join(agree_rows, "\n") * "\n")
    write(stem * "_timing.tsv", join(time_rows, "\n") * "\n")
    open(stem * "_provenance.txt", "w") do io
        println(io, "date=", Dates.now(), " host=", host, " julia=", VERSION,
                " MixedModels=", mmver, " HSquared_rev=", rev,
                " julia_threads=", Threads.nthreads(), " blas_threads=", BLAS.get_num_threads(),
                " reps=", REPS, " rtol_var=", RTOL_VAR, " rtol_beta=", RTOL_BETA)
    end
    println("\nWrote ", stem, "_{agreement,timing}.tsv and _provenance.txt")
    println(all_ok ? "ALL SCENARIOS AGREE within the predeclared tolerances (agreement, not parity)." :
                     "AT LEAST ONE SCENARIO DID NOT AGREE: do not summarize this lane as agreement.")
    return all_ok
end

main() || exit(1)
