# V8.4 — external same-estimand comparator for the MATRIX-FREE Monte-Carlo REML fit.
#
# The exact multi-effect AI-REML estimator (`fit_multi_effect_reml`) already has a blupf90
# same-estimand comparator (see `prepare_blupf90_neffect.jl` + the V3-NEFFECT-REML covered flip).
# This script validates the DIFFERENT estimator: the matrix-free Monte-Carlo REML fit
# (`fit_multi_effect_mc_reml`), which never forms/factors the coefficient matrix `C` and estimates
# the REML score-trace by Hutchinson stochastic probes. The claim under test: the matrix-free fit
# reaches blupf90's AIREMLF90 optimum WITHIN its Monte-Carlo error band on a shared K=3 fixture.
#
# It reconstructs the SAME deterministic fixture as `prepare_blupf90_neffect.jl` (seed 20260800:
# animal ~ A + env1 ~ I + env2 ~ I, q=860), writes the blupf90 packet, runs renumf90 + blupf90+ if
# the binaries are present in `comparator/bin/`, parses the VC estimates from the blupf90 stdout,
# runs the exact + the matrix-free fits (NSEED seeds x two probe budgets), and writes
# `matfree_blupf90_comparison.csv`.
#
#   julia --project=. comparator/matfree_blupf90_neffect.jl
#
# Binaries + generated packet/logs are git-ignored (see .gitignore); the committed artifacts are this
# script + the recovery-checkpoint that banks the numbers.

using HSquared
using LinearAlgebra
using Random
using Printf
using Statistics

const SEED = 20260800
const MU, SA, SG1, SG2, SE = 2.0, 1.0, 0.5, 0.5, 1.0
const NG1, NG2 = 80, 60
const NSEED = 8
const OUT = joinpath(@__DIR__, "blupf90_neffect")
const BIN = joinpath(@__DIR__, "bin")

function _halfsib_pedigree(nsire, ndam, noffspring)
    sire_ids = ["s$i" for i in 1:nsire]; dam_ids = ["d$i" for i in 1:ndam]; off_ids = ["o$i" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(fill("0", nsire + ndam), [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring])
    dam = vcat(fill("0", nsire + ndam), [dam_ids[((i - 1) % ndam) + 1] for i in 1:noffspring])
    return normalize_pedigree(ids, sire, dam)
end

# reconstruct the deterministic fixture (identical RNG draw order to prepare_blupf90_neffect.jl)
function build_fixture(; nsire = 20, ndam = 40, noffspring = 800)
    rng = MersenneTwister(SEED)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped); q = length(ped.ids)
    A = Matrix(inv(Symmetric(Matrix(Ainv)))); LA = cholesky(Symmetric(A)).L
    u1 = (LA * randn(rng, q)) .* sqrt(SA)
    g1 = [rand(rng, 1:NG1) for _ in 1:q]; ug1 = randn(rng, NG1) .* sqrt(SG1)
    g2 = [rand(rng, 1:NG2) for _ in 1:q]; ug2 = randn(rng, NG2) .* sqrt(SG2)
    e = randn(rng, q) .* sqrt(SE)
    X = ones(q, 1); Z1 = Matrix(1.0I, q, q)
    Zg1 = zeros(q, NG1); for a in 1:q; Zg1[a, g1[a]] = 1.0; end
    Zg2 = zeros(q, NG2); for a in 1:q; Zg2[a, g2[a]] = 1.0; end
    y = MU .+ u1 .+ Zg1 * ug1 .+ Zg2 * ug2 .+ e
    effects = [(Z1, Ainv), (Zg1, Matrix(1.0I, NG1, NG1)), (Zg2, Matrix(1.0I, NG2, NG2))]
    return (; y, X, effects, ped, g1, g2, q)
end

function write_packet(fx)
    mkpath(OUT)
    open(joinpath(OUT, "neffect.dat"), "w") do io
        for a in 1:fx.q
            @printf(io, "%.10f 1 %d %d %d\n", fx.y[a], a, fx.g1[a], fx.g2[a])
        end
    end
    open(joinpath(OUT, "neffect.ped"), "w") do io
        for i in eachindex(fx.ped.ids)
            println(io, join((i, fx.ped.sire[i], fx.ped.dam[i]), " "))
        end
    end
    par = ["DATAFILE", "neffect.dat", "TRAITS", "1", "FIELDS_PASSED TO OUTPUT", "", "WEIGHT(S)", "",
           "RESIDUAL_VARIANCE", "1.0", "EFFECT", "2 cross alpha", "EFFECT", "3 cross alpha",
           "RANDOM", "animal", "FILE", "neffect.ped", "FILE_POS", "1 2 3 0 0", "(CO)VARIANCES", "1.0",
           "EFFECT", "4 cross alpha", "RANDOM", "diagonal", "(CO)VARIANCES", "1.0",
           "EFFECT", "5 cross alpha", "RANDOM", "diagonal", "(CO)VARIANCES", "1.0", "OPTION method VCE"]
    open(joinpath(OUT, "renumf90.par"), "w") do io
        for l in par; println(io, l); end
    end
end

# run renumf90 + blupf90+ if the binaries are present; parse σa²/σg1²/σg2²/σe² from the blupf90 stdout
function run_blupf90()
    rn = joinpath(BIN, "renumf90"); bl = joinpath(BIN, "blupf90+")
    (isfile(rn) && isfile(bl)) || return nothing
    cp(rn, joinpath(OUT, "renumf90"); force = true); cp(bl, joinpath(OUT, "blupf90+"); force = true)
    chmod(joinpath(OUT, "renumf90"), 0o755); chmod(joinpath(OUT, "blupf90+"), 0o755)
    cd(OUT) do
        run(pipeline(`sh -c 'echo renumf90.par | ./renumf90'`; stdout = "renum.log", stderr = "renum.log"))
        run(pipeline(`sh -c 'echo renf90.par | ./blupf90+'`; stdout = "blup.log", stderr = "blup.log"))
    end
    log = read(joinpath(OUT, "blup.log"), String)
    lines = split(log, '\n')
    genetic = Float64[]; resid = NaN
    for (i, ln) in enumerate(lines)
        if occursin("Genetic variance(s) for effect", ln) && i < length(lines)
            v = tryparse(Float64, strip(lines[i + 1])); v !== nothing && push!(genetic, v)
        elseif occursin("Residual variance(s)", ln) && i < length(lines)
            v = tryparse(Float64, strip(lines[i + 1])); v !== nothing && (resid = v)
        end
    end
    length(genetic) == 3 && !isnan(resid) || return nothing
    return vcat(genetic, resid)   # [σa², σg1², σg2², σe²]
end

function main()
    fx = build_fixture()
    write_packet(fx)

    exact = fit_multi_effect_reml(fx.y, fx.X, fx.effects; initial = [1.0, 1.0, 1.0, 1.0])
    ex = vcat(exact.variance_components.sigmas, exact.variance_components.sigma_e2)

    blup = run_blupf90()
    if blup === nothing
        @warn "blupf90 binaries not found in $BIN — using the committed-checkpoint estimates"
        blup = [1.0175, 0.38014, 0.50136, 0.96387]   # from the 2026-07-03 committed run
    end

    labels = ["sigma_a2", "sigma_g1_2", "sigma_g2_2", "sigma_e2"]
    @printf("exact engine : σa²=%.5f σg1²=%.5f σg2²=%.5f σe²=%.5f\n", ex...)
    @printf("blupf90+ 2.60: σa²=%.5f σg1²=%.5f σg2²=%.5f σe²=%.5f\n", blup...)
    @printf("exact-vs-blupf90 max abs diff = %.2e\n", maximum(abs.(ex .- blup)))

    rows = ["estimator,nprobe,seed_or_stat,sigma_a2,sigma_g1_2,sigma_g2_2,sigma_e2"]
    push!(rows, @sprintf("exact,,point,%.8f,%.8f,%.8f,%.8f", ex...))
    push!(rows, @sprintf("blupf90,,point,%.6f,%.6f,%.6f,%.6f", blup...))

    for nprobe in (128, 512)
        ests = Vector{Vector{Float64}}()
        for sd in 1:NSEED
            f = fit_multi_effect_mc_reml(fx.y, fx.X, fx.effects; nprobe = nprobe, seed = sd,
                                         shared_probes = true, tol = 1e-4, initial = [1.0, 1.0, 1.0, 1.0])
            v = vcat(f.variance_components.sigmas, f.variance_components.sigma_e2)
            push!(ests, v)
            push!(rows, @sprintf("matfree,%d,seed%d,%.8f,%.8f,%.8f,%.8f", nprobe, sd, v...))
        end
        M = reduce(hcat, ests); mn = vec(mean(M, dims = 2)); sd = vec(std(M, dims = 2))
        push!(rows, @sprintf("matfree,%d,mean,%.8f,%.8f,%.8f,%.8f", nprobe, mn...))
        push!(rows, @sprintf("matfree,%d,sd,%.8f,%.8f,%.8f,%.8f", nprobe, sd...))
        @printf("\n--- matrix-free nprobe=%d (%d seeds) vs blupf90 ---\n", nprobe, NSEED)
        for i in 1:4
            gap = abs(mn[i] - blup[i]); nsd = sd[i] > 0 ? gap / sd[i] : 0.0
            @printf("  %-11s matfree=%.5f±%.5f  blupf90=%.5f  |gap|=%.5f (%.2f·SD)\n",
                    labels[i], mn[i], sd[i], blup[i], gap, nsd)
        end
        @printf("  max rel |matfree_mean - blupf90| = %.4f\n", maximum(abs.(mn .- blup) ./ blup))
    end

    open(joinpath(OUT, "matfree_blupf90_comparison.csv"), "w") do io
        for r in rows; println(io, r); end
    end
    println("\nWrote ", joinpath(OUT, "matfree_blupf90_comparison.csv"))
end

main()
