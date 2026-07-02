# Prepare a sommer comparator packet for the direct–maternal 2×2 G_dm REML estimator
# (`fit_direct_maternal_reml`, `src/likelihood.jl:1311`) — Leg 2 of the
# V4-DIRECT-MATERNAL covered evidence (SAME-ESTIMAND external REML comparator).
#
# Reconstructs the recovery gate's predeclared seed (20264000) EXACTLY — same
# MersenneTwister draw order as `sim/phase4_direct_maternal_recovery_gate.jl`'s `_fit`:
#   pedigree (deterministic, dam_own_records=true) → Ainv → A → LA*randn(q,2)*LG'
#   → per-record y = μ + a_d[animal(r)] + a_m[dam(r)] + e_r
#   — then fits the engine `fit_direct_maternal_reml` to get the same-estimand REML
#   target (σ²_ad, σ²_am, σ_dm, σ²e) and writes:
#     sommer_dm/dm.csv       — y, own animal id (integer 1..q), dam id (integer 1..q)
#     sommer_dm/A.csv        — dense A with integer 1..q header
#     sommer_dm/engine_target.csv — σ²_ad, σ²_am, σ_dm, σ²e, converged flag
#     sommer_dm/pedigree.csv — id, sire, dam (integer codes 1..q, 0=unknown) for A rebuild
#
# COLUMN-CHECK NOTE for the R script: the two random columns in dm.csv are named
# `animal` (own animal row index, 1..q) and `dam_id` (dam's row index, 1..q). Both
# must be mapped to factor levels with the SAME 1..q label set (the pedigree rows)
# so that the two vsm() incidence matrices share the same q columns — a required
# precondition for covm().
#
#   julia --project=. comparator/prepare_sommer_dm.jl

using HSquared
using LinearAlgebra
using Random
using Printf

# ── EXACT mirror of sim/phase4_direct_maternal_recovery_gate.jl constants + DGP ──
const SEED = 20264000
const MU = 2.0
const S_AD = 1.0
const S_AM = 0.5
const R_AM = -0.3
const S_DM = R_AM * sqrt(S_AD * S_AM)
const G_TRUTH = [S_AD S_DM; S_DM S_AM]
const SE = 1.0

const ND = 30; const NS = 6; const NOFF = 8; const NGEN = 4
const MIN_OFFSPRING = 5

const OUT = joinpath(@__DIR__, "sommer_dm")

# ── exact copy of build_maternal_pedigree from the gate script ──────────────────
function build_maternal_pedigree(; nd = ND, ns = NS, noff = NOFF, ngen = NGEN,
                                   dam_own_records = true)
    ids = String[]; sirev = String[]; damv = String[]; sex = Char[]
    dam_of = Dict{String,String}()
    function add!(id, s, d, x)
        push!(ids, id); push!(sirev, s); push!(damv, d); push!(sex, x); dam_of[id] = d
    end
    fsires = ["fs$i" for i in 1:ns]
    fdams  = ["fd$i" for i in 1:nd]
    for s in fsires; add!(s, "0", "0", 'M'); end
    for d in fdams;  add!(d, "0", "0", 'F'); end

    born = String[]
    counter = 0
    prev_dams = fdams; prev_sires = fsires
    for g in 1:ngen
        thisF = String[]; thisM = String[]
        for (j, dam) in enumerate(prev_dams)
            sire = prev_sires[((j - 1) % length(prev_sires)) + 1]
            for k in 1:noff
                counter += 1
                oid = "g$(g)_$(counter)"
                x = isodd(k) ? 'F' : 'M'
                add!(oid, sire, dam, x)
                push!(born, oid)
                x == 'F' ? push!(thisF, oid) : push!(thisM, oid)
            end
        end
        prev_dams  = thisF[1:nd]
        prev_sires = thisM[1:ns]
    end

    off_count = Dict{String,Int}()
    for oid in born; d = dam_of[oid]; off_count[d] = get(off_count, d, 0) + 1; end
    recorded = dam_own_records ? born :
               [oid for oid in born if get(off_count, oid, 0) == 0]
    ident = [id for id in recorded if get(off_count, id, 0) >= MIN_OFFSPRING]
    return (ids = ids, sire = sirev, dam = damv, dam_of = dam_of,
            recorded = recorded, ident_dams = ident)
end

# ── exact copy of build_context from the gate script ────────────────────────────
function build_context(; nd = ND, ns = NS, noff = NOFF, ngen = NGEN,
                         dam_own_records = true)
    raw = build_maternal_pedigree(; nd, ns, noff, ngen, dam_own_records)
    ped = normalize_pedigree(raw.ids, raw.sire, raw.dam)
    idset = Dict(id => i for (i, id) in enumerate(ped.ids))
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    LA = Matrix(cholesky(Symmetric(A)).L)
    animal_rows = [idset[id]           for id in raw.recorded]
    dam_rows    = [idset[raw.dam_of[id]] for id in raw.recorded]
    return (ped = ped, idset = idset, Ainv = Ainv, A = A, LA = LA, q = q,
            animal_rows = animal_rows, dam_rows = dam_rows,
            n = length(raw.recorded), n_ident = length(raw.ident_dams))
end

function main()
    mkpath(OUT)

    # --- EXACT reproduction of _fit(SEED, ctx) RNG draw order ---
    ctx = build_context(; dam_own_records = true)
    rng = MersenneTwister(SEED)
    q = ctx.q
    LG = Matrix(cholesky(Symmetric(G_TRUTH)).L)
    acoef = ctx.LA * randn(rng, q, 2) * transpose(LG)   # q×2: [:,1]=a_d, [:,2]=a_m
    a_d = acoef[:, 1]; a_m = acoef[:, 2]
    n = ctx.n
    Zd = zeros(n, q); Zm = zeros(n, q); y = Vector{Float64}(undef, n)
    for r in 1:n
        ia = ctx.animal_rows[r]; idm = ctx.dam_rows[r]
        Zd[r, ia] = 1.0; Zm[r, idm] = 1.0
        y[r] = MU + a_d[ia] + a_m[idm] + sqrt(SE) * randn(rng)
    end
    X = ones(n, 1)

    # --- Engine same-estimand REML target (cold start = the gate's cold start) ---
    fit = fit_direct_maternal_reml(y, X, Zd, Zm, ctx.Ainv;
        initial = (G_dm = Matrix(1.0I, 2, 2), sigma_e2 = 1.0),
        iterations = 200, ids = ctx.ped.ids)
    vc = fit.variance_components

    # dm.csv — one row per record; animal = own animal pedigree row (1..q),
    # dam_id = dam's pedigree row (1..q). Both columns use integer codes into the
    # SAME pedigree position set so that the sommer incidence matrices share q columns.
    open(joinpath(OUT, "dm.csv"), "w") do io
        println(io, "y,animal,dam_id")
        for r in 1:n
            @printf(io, "%.10f,%d,%d\n", y[r], ctx.animal_rows[r], ctx.dam_rows[r])
        end
    end

    # A.csv — dense relationship matrix with a header row/col of 1..q integer names
    A = ctx.A
    open(joinpath(OUT, "A.csv"), "w") do io
        println(io, join(vcat([""], string.(1:q)), ","))
        for i in 1:q
            println(io, join(vcat([string(i)], [@sprintf("%.10g", A[i, j]) for j in 1:q]), ","))
        end
    end

    # engine_target.csv — the 2×2 G_dm entries + σ²e (same-estimand REML target)
    open(joinpath(OUT, "engine_target.csv"), "w") do io
        println(io, "quantity,value")
        @printf(io, "sigma_ad,%.12g\n", vc.sigma_ad)
        @printf(io, "sigma_am,%.12g\n", vc.sigma_am)
        @printf(io, "sigma_dm,%.12g\n", vc.sigma_dm)
        @printf(io, "sigma_e2,%.12g\n", vc.sigma_e2)
        @printf(io, "r_am,%.12g\n", fit.genetic_correlation)
        @printf(io, "converged,%s\n", fit.converged)
    end

    # pedigree.csv — integer-coded pedigree (for any cross-check A rebuild in R);
    # sire/dam = 0 for founders (unknown). After normalize_pedigree, ped.sire and
    # ped.dam are already integer indices (0 = unknown), so emit them directly.
    open(joinpath(OUT, "pedigree.csv"), "w") do io
        println(io, "id,sire,dam")
        ped = ctx.ped
        for i in 1:length(ped.ids)
            println(io, "$i,$(ped.sire[i]),$(ped.dam[i])")
        end
    end

    println("Wrote sommer DM packet to ", OUT)
    @printf("ENGINE TARGET: σ²_ad=%.6f  σ²_am=%.6f  σ_dm=%.6f  σ²e=%.6f  r_am=%.6f  (converged=%s)\n",
            vc.sigma_ad, vc.sigma_am, vc.sigma_dm, vc.sigma_e2,
            fit.genetic_correlation, fit.converged)
    @printf("  Truth: σ²_ad=%.4f σ²_am=%.4f σ_dm=%.5f σ²e=%.4f r_am=%.4f\n",
            S_AD, S_AM, S_DM, SE, R_AM)
    @printf("  n=%d records, q=%d animals\n", n, q)
end

main()
