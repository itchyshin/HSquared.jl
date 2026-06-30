# PLINK max(T) genome-wide significance comparator for HSquared.jl's permutation
# genome-wide p-value (`genome_wide_pvalue`) — the V5 NEEDS-EXTERNAL leg.
#
# Same-method external comparator: PLINK 1.9 `--assoc --mperm N` runs a max(T)
# permutation genome-wide test (EMP2 = family-wise add-one empirical p,
# `(1 + #{perm max ≥ obs})/(N+1)`), the SAME max-statistic permutation estimand as
# `genome_wide_pvalue` against the HSquared permutation null. PLINK uses an
# INDEPENDENT implementation: an estimated-residual-variance OLS regression
# statistic (vs HSquared's supplied-known-variance χ²) and its OWN RNG / permutation
# scheme. Agreement is therefore a genuine cross-implementation check, not a tautology.
#
# This script (following the BLUPF90 comparator pattern in this directory):
#   1. simulates NULL-DGP-plus-planted-QTL datasets spanning β = 0 (null) → 0.8 (strong);
#   2. runs the HSquared scan + residual-permutation max(T) null + add-one genome-wide p;
#   3. writes PLINK .ped/.map per config (dosage 0/1/2 → "1 1"/"1 2"/"2 2", quantitative
#      phenotype in column 6);
#   4. if ENV["PLINK"] points to a plink binary, runs `--assoc --mperm` and parses EMP2
#      + the per-marker .qassoc statistic, then writes `plink_threshold/comparison.tsv`
#      and a per-marker-agreement summary.
#
# Reproduce (the PLINK binary is NOT vendored — download PLINK 1.9 from
# https://www.cog-genomics.org/plink/1.9/ ; tested with v1.90b7.2, 11 Dec 2023):
#   PLINK=/path/to/plink JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
#     julia --project=. comparator/prepare_plink_threshold.jl

using HSquared
using Random, Statistics, Printf

const REPO = normpath(joinpath(@__DIR__, ".."))
include(joinpath(REPO, "sim", "phase5_threshold_calibration.jl"))  # _simulate_markers

const OUTDIR = joinpath(@__DIR__, "plink_threshold")
const NPERM = 2000

function simulate(seed; n = 300, m = 200, beta = 0.0, causal_idx = 100)
    rng = MersenneTwister(seed)
    markers = _simulate_markers(rng, n, m)
    X = ones(n, 1)
    g = markers[:, causal_idx]
    y = 2.0 .+ beta .* (g .- mean(g)) .+ randn(rng, n)   # σ²e = 1
    return (markers = markers, X = X, y = y, n = n, m = m, causal_idx = causal_idx)
end

function our_side(d; nperm = NPERM)
    scan = single_marker_scan(d.y, d.X, d.markers; sigma_e2 = 1.0)
    obs_max = HSquared._scan_max_statistic(scan; statistic = :chisq)
    betaX = d.X \ d.y
    fitted = d.X * betaX
    resid = d.y .- fitted
    null_max = Vector{Float64}(undef, nperm)
    rng = MersenneTwister(hash((:perm, d.n, d.m)))
    for i in 1:nperm
        yp = fitted .+ resid[randperm(rng, d.n)]
        sc = single_marker_scan(yp, d.X, d.markers; sigma_e2 = 1.0)
        null_max[i] = HSquared._scan_max_statistic(sc; statistic = :chisq)
    end
    top_idx = argmax(scan.chisq)
    return (obs_max = obs_max, gw_p = genome_wide_pvalue(obs_max, null_max),
            top_idx = top_idx, top_p = scan.p_values[top_idx],
            chisq = collect(scan.chisq), pvals = collect(scan.p_values))
end

function write_plink(d, tag)
    mkpath(OUTDIR)
    open(joinpath(OUTDIR, "$(tag).map"), "w") do io
        for j in 1:d.m
            println(io, "1\tmarker_$(j)\t0\t$(j * 1000)")
        end
    end
    open(joinpath(OUTDIR, "$(tag).ped"), "w") do io
        for i in 1:d.n
            geno = String[]
            for j in 1:d.m
                dsg = d.markers[i, j]
                push!(geno, dsg == 0 ? "1 1" : dsg == 1 ? "1 2" : "2 2")
            end
            println(io, "fam$(i)\tid$(i)\t0\t0\t0\t$(d.y[i])\t", join(geno, " "))
        end
    end
end

# PLINK .qassoc → Dict(marker => (T, P)); .qassoc.mperm → Dict(marker => EMP2)
function read_qassoc(path)
    d = Dict{String,Tuple{Float64,Float64}}()
    for (k, ln) in enumerate(eachline(path))
        k == 1 && continue
        f = split(strip(ln))
        length(f) >= 9 || continue
        t = tryparse(Float64, f[8]); p = tryparse(Float64, f[9])
        (t === nothing || p === nothing) && continue
        d[f[2]] = (t, p)
    end
    return d
end

function read_mperm(path)
    d = Dict{String,Float64}()
    for (k, ln) in enumerate(eachline(path))
        k == 1 && continue
        f = split(strip(ln))
        length(f) >= 4 || continue
        e2 = tryparse(Float64, f[4])
        e2 === nothing && continue
        d[f[2]] = e2
    end
    return d
end

const CONFIGS = [
    (seed = 20260980, beta = 0.0,  tag = "cfg_null"),
    (seed = 20260981, beta = 0.25, tag = "cfg_weak"),
    (seed = 20260982, beta = 0.40, tag = "cfg_mod"),
    (seed = 20260983, beta = 0.60, tag = "cfg_strong"),
    (seed = 20260984, beta = 0.80, tag = "cfg_vstrong"),
]

function main()
    mkpath(OUTDIR)
    plink = get(ENV, "PLINK", "")
    rows = NamedTuple[]
    permarker = NamedTuple[]
    for c in CONFIGS
        d = simulate(c.seed; beta = c.beta)
        o = our_side(d)
        write_plink(d, c.tag)
        plink_top = ""; plink_emp2 = NaN; r_chi = NaN
        if !isempty(plink)
            run(pipeline(`$plink --file $(joinpath(OUTDIR, c.tag)) --assoc --mperm $NPERM
                          --seed 42 --allow-no-sex --out $(joinpath(OUTDIR, c.tag))`;
                         stdout = devnull, stderr = devnull))
            mperm = read_mperm(joinpath(OUTDIR, "$(c.tag).qassoc.mperm"))
            qassoc = read_qassoc(joinpath(OUTDIR, "$(c.tag).qassoc"))
            plink_top, plink_emp2 = reduce((a, b) -> a[2] <= b[2] ? a : b, collect(mperm))
            ours_chi = Float64[]; plink_t2 = Float64[]
            for j in 1:length(o.chisq)
                mk = "marker_$(j)"
                haskey(qassoc, mk) || continue
                push!(ours_chi, o.chisq[j]); push!(plink_t2, qassoc[mk][1]^2)
            end
            r_chi = cor(ours_chi, plink_t2)
        end
        push!(rows, (tag = c.tag, beta = c.beta, our_top = "marker_$(o.top_idx)",
                     our_gw_p = o.gw_p, plink_top = plink_top, plink_emp2 = plink_emp2,
                     same_top = plink_top == "marker_$(o.top_idx)"))
        push!(permarker, (tag = c.tag, cor_chisq = r_chi))
        @printf("%-12s β=%.2f  our_top=marker_%-3d our_gw_p=%.4f  plink_top=%-10s plink_EMP2=%.4f  same_top=%s  cor(χ²,T²)=%.5f\n",
                c.tag, c.beta, o.top_idx, o.gw_p, plink_top, plink_emp2,
                plink_top == "marker_$(o.top_idx)", r_chi)
    end
    open(joinpath(OUTDIR, "comparison.tsv"), "w") do io
        println(io, "config\tbeta\tour_top\tour_gw_addone_p\tplink_top\tplink_emp2\tsame_top\tcor_permarker_chisq")
        for (r, pm) in zip(rows, permarker)
            @printf(io, "%s\t%.2f\t%s\t%.6f\t%s\t%.6f\t%s\t%.6f\n",
                    r.tag, r.beta, r.our_top, r.our_gw_p, r.plink_top, r.plink_emp2,
                    r.same_top, pm.cor_chisq)
        end
    end
    isempty(plink) && @warn "ENV[\"PLINK\"] not set — wrote .ped/.map + our-side only; set PLINK to a plink 1.9 binary to run the comparator."
    println("\nwrote: ", joinpath(OUTDIR, "comparison.tsv"))
    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
