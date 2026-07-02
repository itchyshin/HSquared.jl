# Prepare a sommer comparator packet for the k=2 random-regression REML estimator
# (`fit_random_regression_reml`, `src/random_regression.jl:439`) — Leg 2 of the
# RR k=2 covered evidence (SAME-ESTIMAND external REML comparator).
#
# Reconstructs the recovery gate's predeclared seed (20261000) EXACTLY — same
# MersenneTwister draw order as `sim/phase3_rr_recovery_gate.jl`'s `_fit`:
#   pedigree → Ainv → A → LA*randn(q,k)*LK' coefficient curves → per-offspring
#   records at the 6 spread covariate points → y — then fits the engine
#   `fit_random_regression_reml` to get the same-estimand REML target (2×2 K_g,
#   σ²e) and writes a CSV data frame + the dense relationship matrix A (with
#   1..q integer row/col names) + the engine target + the engine's evaluated
#   Legendre design (for the LOAD-BEARING normalization check in the R script).
#
#   julia --project=. comparator/prepare_sommer_rr.jl

using HSquared
using LinearAlgebra
using Random
using Printf

# ── EXACT mirror of sim/phase3_rr_recovery_gate.jl constants + DGP ───────────────
const SEED = 20261000
const MU = 2.0
const KG = [1.0 0.3; 0.3 0.5]            # truth (2×2 coefficient genetic covariance)
const SE = 1.0
const TPTS = [-1.0, -0.6, -0.2, 0.2, 0.6, 1.0]   # spread covariate points (already in [-1,1])
const MREC = length(TPTS)
const OUT = joinpath(@__DIR__, "sommer_rr")

function _halfsib_pedigree(nsire, ndam, noffspring)
    sire_ids = ["s$i" for i in 1:nsire]
    dam_ids = ["d$i" for i in 1:ndam]
    off_ids = ["o$i" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(fill("0", nsire + ndam),
                [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring])
    dam = vcat(fill("0", nsire + ndam),
               [dam_ids[((i - 1) % ndam) + 1] for i in 1:noffspring])
    return normalize_pedigree(ids, sire, dam)
end

function main(; nsire = 20, ndam = 40, noffspring = 300)
    mkpath(OUT)
    # --- EXACT reproduction of _fit(SEED) RNG draw order ---
    rng = MersenneTwister(SEED)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    k = size(KG, 1)

    LA = cholesky(Symmetric(A)).L
    LK = cholesky(Symmetric(KG)).L
    acoef = LA * randn(rng, q, k) * transpose(LK)     # q×k per-animal coefficient curves

    idpos = Dict(id => i for (i, id) in enumerate(ped.ids))
    off_rows = [idpos["o$i"] for i in 1:noffspring]

    n = noffspring * MREC
    ts = Vector{Float64}(undef, n)
    Zrows = Vector{Int}(undef, n)                     # record → animal (pedigree row)
    yv = Vector{Float64}(undef, n)
    r = 0
    for oi in 1:noffspring
        arow = off_rows[oi]
        ϕcoef = view(acoef, arow, :)
        for t in TPTS
            r += 1
            ts[r] = t
            Zrows[r] = arow
            ϕ = legendre_basis(t, k)
            yv[r] = MU + dot(ϕ, ϕcoef) + sqrt(SE) * randn(rng)
        end
    end

    Phi = legendre_design(ts, k)                      # n×k normalized-Legendre design
    X = ones(n, 1)
    Z = zeros(n, q)
    @inbounds for i in 1:n
        Z[i, Zrows[i]] = 1.0
    end

    # --- Engine same-estimand REML target (cold start = the gate's cold start) ---
    fit = HSquared.fit_random_regression_reml(yv, X, Phi, Z, Ainv;
                                              initial = (K_g = Matrix(1.0I, k, k), sigma_e2 = 1.0))
    Kg = fit.variance_components.K_g
    se_hat = fit.variance_components.sigma_e2

    # data.csv — one row per record; id = pedigree index 1..q of the recorded animal,
    # t = the covariate point (already in [-1,1], the engine's standardized scale;
    # spans exactly [-1,1] so sommer's leg() internal standardization is the identity).
    open(joinpath(OUT, "rr.csv"), "w") do io
        println(io, "y,id,t")
        for i in 1:n
            @printf(io, "%.10f,%d,%.10f\n", yv[i], Zrows[i], ts[i])
        end
    end

    # A.csv — dense relationship matrix with a header row/col of 1..q integer names
    open(joinpath(OUT, "A.csv"), "w") do io
        println(io, join(vcat([""], string.(1:q)), ","))   # header: ,1,2,...,q
        for i in 1:q
            println(io, join(vcat([string(i)], [@sprintf("%.10g", A[i, j]) for j in 1:q]), ","))
        end
    end

    # engine_target.csv — the 2×2 K_g entries + σ²e (same-estimand REML target)
    open(joinpath(OUT, "engine_target.csv"), "w") do io
        println(io, "quantity,value")
        @printf(io, "Kg_11,%.12g\n", Kg[1, 1])
        @printf(io, "Kg_22,%.12g\n", Kg[2, 2])
        @printf(io, "Kg_12,%.12g\n", Kg[1, 2])
        @printf(io, "sigma_e2,%.12g\n", se_hat)
        @printf(io, "converged,%s\n", fit.converged)
    end

    # engine_legendre.csv — the engine's evaluated normalized-Legendre design at the
    # UNIQUE covariate points, for the LOAD-BEARING normalization check (compare
    # column-by-column to sommer's leg(t,1) basis). φ_n(t) = sqrt((2n+1)/2)·P_n(t).
    t_unique = sort(unique(ts))
    Phi_u = legendre_design(standardize_covariate(t_unique), k)
    open(joinpath(OUT, "engine_legendre.csv"), "w") do io
        println(io, "t,phi0,phi1")
        for i in eachindex(t_unique)
            @printf(io, "%.10f,%.12g,%.12g\n", t_unique[i], Phi_u[i, 1], Phi_u[i, 2])
        end
    end

    println("Wrote sommer RR (k=2) packet to ", OUT)
    @printf("ENGINE TARGET: K_g=[%.6f %.6f; %.6f %.6f]  σe²=%.6f  (converged=%s)\n",
            Kg[1, 1], Kg[1, 2], Kg[1, 2], Kg[2, 2], se_hat, fit.converged)
    @printf("  ρ_g = %.6f (truth %.6f); n=%d records, q=%d animals\n",
            Kg[1, 2] / sqrt(Kg[1, 1] * Kg[2, 2]),
            KG[1, 2] / sqrt(KG[1, 1] * KG[2, 2]), n, q)
end

main()
