# v0.8-S2-FIT — recovery gate + scale feasibility for the matrix-free Monte-Carlo EM-REML fit
# `fit_multi_effect_mc_reml`. OPT-IN (env-gated), OUT of CI. TWO modes:
#
#   HSQUARED_RUN_S2FIT=recovery  — a PRE-DECLARED 48-seed bias/MCSE recovery gate THROUGH the
#       matrix-free MC-EM fit, on a KNOWN-truth K=3 DGP (animal-A gene-dropped + 2 environmental
#       factors independent of the pedigree). Per seed it also fits the EXACT
#       fit_sparse_multi_effect_aireml as the reference, so the write-up can show the MC fit
#       does not distort the estimate relative to the exact estimator. Pass/fail criterion +
#       decision rule live in the PRE-DECLARATION (committed BEFORE the run; this file frozen
#       byte-identical against it).
#
#   HSQUARED_RUN_S2FIT=scale     — FIT feasibility timing at increasing q (does the matrix-free
#       FIT stay feasible — converges, bounded wall-clock — where the direct AI-REML is
#       fill-limited? extends the S2 SOLVE feasibility to the FIT). Machine-specific; 1 seed/q.
#
# Neither mode makes a claim; the pre-declaration + post-run checkpoint do.
#
# Run:
#   HSQUARED_RUN_S2FIT=recovery OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
#       julia --project=. sim/v08_s2fit_recovery_scale.jl recovery.tsv
#   HSQUARED_RUN_S2FIT=scale    OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
#       julia --project=. sim/v08_s2fit_recovery_scale.jl scale.tsv
# ENV overrides (defaults are the PRE-DECLARED values):
#   S2FIT_Q=960  S2FIT_NSEEDS=48  S2FIT_NPROBE=200  S2FIT_BASESEED=20260800
#   S2FIT_TRUTH="1.0,0.5,0.5,1.0"  (σ²a, σ²_e1, σ²_e2, σ²e)
#   S2FIT_SCALE_SIZES="10000,50000,100000,200000"  S2FIT_SCALE_NPROBE=48

using HSquared
using LinearAlgebra, SparseArrays, Random, Printf, Dates, Statistics
import HSquared: fit_multi_effect_mc_reml

function halfsib(q::Int)
    nsire = max(2, round(Int, 0.04q)); ndam = max(2, round(Int, 0.08q)); noff = q - nsire - ndam
    sids = ["s$i" for i in 1:nsire]; dids = ["d$i" for i in 1:ndam]; oids = ["o$i" for i in 1:noff]
    normalize_pedigree(vcat(sids, dids, oids),
        vcat(fill("0", nsire + ndam), [sids[((i - 1) % nsire) + 1] for i in 1:noff]),
        vcat(fill("0", nsire + ndam), [dids[((i - 1) % ndam) + 1] for i in 1:noff]))
end
function genedrop(ped, s2a, rng)
    q = length(ped.ids); u = zeros(q)
    @inbounds for i in 1:q
        s = ped.sire[i]; d = ped.dam[i]; pa = s > 0 ? u[s] : 0.0; pb = d > 0 ? u[d] : 0.0
        nk = (s > 0) + (d > 0); msv = nk == 0 ? 1.0 : (nk == 1 ? 0.75 : 0.5)
        u[i] = 0.5 * (pa + pb) + sqrt(s2a * msv) * randn(rng)
    end
    u
end
# K=3 known-truth case: effect1 additive (A), effects 2,3 pedigree-independent env factors.
function sim_case(q::Int, truth; seed::Int)
    rng = MersenneTwister(seed); ped = halfsib(q); na = length(ped.ids); Ainv = pedigree_inverse(ped)
    u = genedrop(ped, truth[1], rng); n = na; X = ones(n, 1); y = 5.0 .+ u
    effects = Tuple{SparseMatrixCSC{Float64,Int},SparseMatrixCSC{Float64,Int}}[(sparse(1.0I, n, na), Ainv)]
    for (k, s2) in enumerate((truth[2], truth[3]))
        ng = max(5, q ÷ (10 * (k + 1))); Zk = spzeros(n, ng)
        for r in 1:n; Zk[r, rand(rng, 1:ng)] = 1.0; end
        y .+= Zk * (randn(rng, ng) .* sqrt(s2)); push!(effects, (Zk, sparse(1.0I, ng, ng)))
    end
    y .+= sqrt(truth[4]) .* randn(rng, n); return y, X, effects
end
loadavg1() = isfile("/proc/loadavg") ? parse(Float64, split(read("/proc/loadavg", String))[1]) : NaN
envint(k, d) = parse(Int, get(ENV, k, string(d)))
envints(k, d) = parse.(Int, split(get(ENV, k, d), ","))
envfloats(k, d) = parse.(Float64, split(get(ENV, k, d), ","))

function run_recovery(out)
    q = envint("S2FIT_Q", 960); nseeds = envint("S2FIT_NSEEDS", 48)
    nprobe = envint("S2FIT_NPROBE", 200); base = envint("S2FIT_BASESEED", 20260800)
    truth = envfloats("S2FIT_TRUTH", "1.0,0.5,0.5,1.0")
    labels = ["sigma_a2", "sigma_e1", "sigma_e2", "sigma_e"]
    manifest = [
        "# HSquared.jl v0.8-S2-FIT matrix-free MC-EM-REML RECOVERY gate  $(Dates.now())",
        "# host=$(gethostname())  julia=$(VERSION)  OPENBLAS_NUM_THREADS=$(get(ENV,"OPENBLAS_NUM_THREADS","unset"))",
        "# q=$q  nseeds=$nseeds  nprobe=$nprobe  base_seed=$base  truth=$(truth)  K=3 (animal-A + 2 pedigree-independent env factors)",
        "# PRIMARY criterion (pre-declared): all seeds converged AND max over seeds of |MC - EXACT|/EXACT <= mcvx_tol -- i.e. the matrix-free MC fit REPRODUCES the exact AI-REML fit (the covered V3-NEFFECT-REML estimator) on the same data; the MC approximation must not distort the estimate. SECONDARY (informational): |mean bias vs truth| <= 2*MCSE per component -- a joint estimator+DGP property the EXACT fit shares (its own small-sample recovery is the covered V3-NEFFECT-REML gate, NOT re-litigated here).",
    ]
    mcvx_tol = parse(Float64, get(ENV, "S2FIT_MCVX_TOL", "0.05"))
    for m in manifest; println(m); end
    rows = String[]; push!(rows, "seed\tconverged\tmc_sa2\tmc_se1\tmc_se2\tmc_se\tex_sa2\tex_se1\tex_se2\tex_se\tmax_mc_vs_ex_reldiff")
    MC = zeros(nseeds, 4); EX = zeros(nseeds, 4); conv = falses(nseeds); mvx = zeros(nseeds)
    for s in 1:nseeds
        y, X, effects = sim_case(q, truth; seed = base + s)
        ex = fit_sparse_multi_effect_aireml(y, X, effects; em_warmup = 0)
        exv = vcat(ex.variance_components.sigmas, ex.variance_components.sigma_e2)
        f = fit_multi_effect_mc_reml(y, X, effects; nprobe = nprobe, seed = base + 100000 + s)
        mcv = vcat(f.variance_components.sigmas, f.variance_components.sigma_e2)
        MC[s, :] = mcv; EX[s, :] = exv; conv[s] = f.converged
        mvx[s] = maximum(abs.(mcv .- exv) ./ exv)
        push!(rows, @sprintf("%d\t%s\t%.5f\t%.5f\t%.5f\t%.5f\t%.5f\t%.5f\t%.5f\t%.5f\t%.4e",
            base + s, f.converged, mcv..., exv..., mvx[s]))
        @printf("# seed %d conv=%s MC=%s EX=%s mc_vs_ex=%.2e\n", base+s, f.converged,
                string(round.(mcv, digits=3)), string(round.(exv, digits=3)), mvx[s]); flush(stdout)
    end
    println("\n# RESULT (mean over $nseeds seeds)")
    println("# [SECONDARY, informational] component  truth   mc_mean   bias     MCSE     |bias|/MCSE  ex_mean")
    for j in 1:4
        m = mean(MC[:, j]); mcse = std(MC[:, j]) / sqrt(nseeds); bias = m - truth[j]
        ratio = abs(bias) / mcse
        @printf("# %-9s %-7.3f %-9.4f %-8.4f %-8.4f %-11.3f %.4f\n",
                labels[j], truth[j], m, bias, mcse, ratio, mean(EX[:, j]))
    end
    # PRIMARY (pre-declared) gate: MC reproduces EXACT + all converged.
    gate = all(conv) && maximum(mvx) <= mcvx_tol
    @printf("# all_converged=%s  max_mc_vs_ex_reldiff=%.3e  mcvx_tol=%.3f  GATE=%s\n",
            all(conv), maximum(mvx), mcvx_tol, gate ? "PASS" : "FAIL")
    open(out, "w") do io; for m in manifest; println(io, m); end; for r in rows; println(io, r); end; end
    println("# wrote ", out)
end

function run_scale(out)
    sizes = envints("S2FIT_SCALE_SIZES", "10000,50000,100000,200000")
    nprobe = envint("S2FIT_SCALE_NPROBE", 48)
    truth = envfloats("S2FIT_TRUTH", "1.0,0.5,0.5,1.0"); base = envint("S2FIT_BASESEED", 20260800)
    manifest = [
        "# HSquared.jl v0.8-S2-FIT matrix-free MC-EM-REML SCALE feasibility  $(Dates.now())",
        "# host=$(gethostname())  julia=$(VERSION)  OPENBLAS_NUM_THREADS=$(get(ENV,"OPENBLAS_NUM_THREADS","unset"))",
        "# sizes=$(sizes)  nprobe=$nprobe  truth=$(truth)  K=3  1 seed/size. FIT feasibility (converges, bounded wall-clock).",
    ]
    for m in manifest; println(m); end
    rows = String[]; push!(rows, "q\tn\tnprobe\tconverged\tem_iters\twall_s\tsigma_a2\tsigma_e\tloadavg1")
    for q in sizes
        y, X, effects = sim_case(q, truth; seed = base + 1)
        fit_multi_effect_mc_reml(y, X, effects; nprobe = 4, iterations = 2)  # warm-up (discard)
        t = @elapsed f = fit_multi_effect_mc_reml(y, X, effects; nprobe = nprobe, seed = base + 1)
        push!(rows, @sprintf("%d\t%d\t%d\t%s\t%d\t%.3f\t%.5f\t%.5f\t%.2f",
            q, length(y), nprobe, f.converged, f.iterations, t,
            f.variance_components.sigmas[1], f.variance_components.sigma_e2, loadavg1()))
        @printf("# q=%d conv=%s em_iters=%d wall=%.1fs sa2=%.4f\n", q, f.converged, f.iterations, t,
                f.variance_components.sigmas[1]); flush(stdout)
    end
    open(out, "w") do io; for m in manifest; println(io, m); end; for r in rows; println(io, r); end; end
    println("# wrote ", out)
end

function main()
    mode = get(ENV, "HSQUARED_RUN_S2FIT", "")
    out = length(ARGS) >= 1 ? ARGS[1] : "v08_s2fit_$(mode).tsv"
    if mode == "recovery"; run_recovery(out)
    elseif mode == "scale"; run_scale(out)
    else; @info "v08_s2fit_recovery_scale.jl is opt-in; set HSQUARED_RUN_S2FIT=recovery|scale."; end
end
main()
