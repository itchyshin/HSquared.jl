# V8.4 AT-SCALE — external same-estimand comparator for the matrix-free fit at a LARGER q than the
# validation-scale estimand leg (comparator/matfree_blupf90_neffect.jl, q=860).
#
# HONEST framing of "at-scale": the matrix-free fit's raison d'être is q where the EXACT/direct path
# is INFEASIBLE (K≥2 fill-limited past ~50k). But blupf90 (and any external REML tool) forms the MME
# too, so it ALSO cannot run there. There is therefore NO q where (exact infeasible) AND (external
# tool feasible) — the exact-infeasible regime has no external oracle BY CONSTRUCTION. This leg runs
# the SAME 3 estimators — blupf90 AIREMLF90 (external), fit_sparse_multi_effect_aireml (EXACT sparse
# engine), fit_multi_effect_mc_reml (matrix-free) — at a substantially larger q (default q≈4060, ~5×
# the estimand leg) where all three estimators still run, and shows all three agree. Beyond blupf90's ceiling, the matrix-free path's validation rests on: this larger-scale
# external agreement + the internal exact-agreement (matrix-free == exact sparse) + the pre-declared
# 48-seed recovery gate.
#
#   julia --project=. comparator/matfree_blupf90_atscale.jl [noffspring]
#
# Binaries + generated packet are git-ignored; committed artifacts are this script + the checkpoint.

using HSquared
using LinearAlgebra
using Random
using Printf
using Statistics

const SEED = 20260800
const MU, SA, SG1, SG2, SE = 2.0, 1.0, 0.5, 0.5, 1.0
const NG1, NG2 = 80, 60
const NSEED = 6
const OUT = joinpath(@__DIR__, "blupf90_atscale")
const BIN = joinpath(@__DIR__, "bin")

function _halfsib_pedigree(nsire, ndam, noffspring)
    sire_ids = ["s$i" for i in 1:nsire]; dam_ids = ["d$i" for i in 1:ndam]; off_ids = ["o$i" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(fill("0", nsire + ndam), [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring])
    dam = vcat(fill("0", nsire + ndam), [dam_ids[((i - 1) % ndam) + 1] for i in 1:noffspring])
    return normalize_pedigree(ids, sire, dam)
end

function build_fixture(noffspring)
    rng = MersenneTwister(SEED)
    ped = _halfsib_pedigree(20, 40, noffspring)
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
        for a in 1:fx.q; @printf(io, "%.10f 1 %d %d %d\n", fx.y[a], a, fx.g1[a], fx.g2[a]); end
    end
    open(joinpath(OUT, "neffect.ped"), "w") do io
        for i in eachindex(fx.ped.ids); println(io, join((i, fx.ped.sire[i], fx.ped.dam[i]), " ")); end
    end
    par = ["DATAFILE", "neffect.dat", "TRAITS", "1", "FIELDS_PASSED TO OUTPUT", "", "WEIGHT(S)", "",
           "RESIDUAL_VARIANCE", "1.0", "EFFECT", "2 cross alpha", "EFFECT", "3 cross alpha",
           "RANDOM", "animal", "FILE", "neffect.ped", "FILE_POS", "1 2 3 0 0", "(CO)VARIANCES", "1.0",
           "EFFECT", "4 cross alpha", "RANDOM", "diagonal", "(CO)VARIANCES", "1.0",
           "EFFECT", "5 cross alpha", "RANDOM", "diagonal", "(CO)VARIANCES", "1.0", "OPTION method VCE"]
    open(joinpath(OUT, "renumf90.par"), "w") do io; for l in par; println(io, l); end; end
end

function run_blupf90()
    rn = joinpath(BIN, "renumf90"); bl = joinpath(BIN, "blupf90+")
    (isfile(rn) && isfile(bl)) || return nothing
    cp(rn, joinpath(OUT, "renumf90"); force = true); cp(bl, joinpath(OUT, "blupf90+"); force = true)
    chmod(joinpath(OUT, "renumf90"), 0o755); chmod(joinpath(OUT, "blupf90+"), 0o755)
    cd(OUT) do
        run(pipeline(`sh -c 'echo renumf90.par | ./renumf90'`; stdout = "renum.log", stderr = "renum.log"))
        run(pipeline(`sh -c 'echo renf90.par | ./blupf90+'`; stdout = "blup.log", stderr = "blup.log"))
    end
    lines = split(read(joinpath(OUT, "blup.log"), String), '\n')
    genetic = Float64[]; resid = NaN
    for (i, ln) in enumerate(lines)
        if occursin("Genetic variance(s) for effect", ln) && i < length(lines)
            v = tryparse(Float64, strip(lines[i + 1])); v !== nothing && push!(genetic, v)
        elseif occursin("Residual variance(s)", ln) && i < length(lines)
            v = tryparse(Float64, strip(lines[i + 1])); v !== nothing && (resid = v)
        end
    end
    length(genetic) == 3 && !isnan(resid) || return nothing
    return vcat(genetic, resid)
end

function main()
    noff = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 4000
    fx = build_fixture(noff)
    @printf("# AT-SCALE comparator  q=%d  (noffspring=%d, K=3)\n", fx.q, noff)
    write_packet(fx)

    tex = @elapsed exact = fit_sparse_multi_effect_aireml(fx.y, fx.X, fx.effects; initial = [1.0, 1.0, 1.0, 1.0])
    ex = vcat(exact.variance_components.sigmas, exact.variance_components.sigma_e2)

    blup = run_blupf90()
    blup === nothing && (@warn "blupf90 not found in $BIN"; blup = fill(NaN, 4))

    labels = ["sigma_a2", "sigma_g1_2", "sigma_g2_2", "sigma_e2"]
    @printf("exact sparse (%.1fs): σa²=%.5f σg1²=%.5f σg2²=%.5f σe²=%.5f\n", tex, ex...)
    @printf("blupf90+ 2.60       : σa²=%.5f σg1²=%.5f σg2²=%.5f σe²=%.5f\n", blup...)
    @printf("exact-vs-blupf90 max abs diff = %.2e\n", maximum(abs.(ex .- blup)))

    for nprobe in (128, 256)
        ests = Vector{Vector{Float64}}()
        for sd in 1:NSEED
            f = fit_multi_effect_mc_reml(fx.y, fx.X, fx.effects; nprobe = nprobe, seed = sd,
                                         shared_probes = true, tol = 1e-4, initial = [1.0, 1.0, 1.0, 1.0])
            push!(ests, vcat(f.variance_components.sigmas, f.variance_components.sigma_e2))
        end
        M = reduce(hcat, ests); mn = vec(mean(M, dims = 2)); sd = vec(std(M, dims = 2))
        @printf("\n--- matrix-free nprobe=%d (%d seeds), q=%d ---\n", nprobe, NSEED, fx.q)
        for i in 1:4
            gapb = abs(mn[i] - blup[i]); gape = abs(mn[i] - ex[i])
            @printf("  %-11s matfree=%.5f±%.5f  exact=%.5f  blupf90=%.5f  |Δblup|=%.5f |Δexact|=%.5f\n",
                    labels[i], mn[i], sd[i], ex[i], blup[i], gapb, gape)
        end
        @printf("  max rel |matfree_mean - blupf90| = %.4f ; - exact = %.4f\n",
                maximum(abs.(mn .- blup) ./ blup), maximum(abs.(mn .- ex) ./ ex))
    end
end

main()
