# exact_G_estimated_vc_comparator.jl — S0b recipe scaffold (NOT LAUNCHED)
#
# Purpose: export the engine's exact VanRaden-1 G (and optional K_lambda) so a
# same-estimand estimated-VC comparator (sommer primary, rrBLUP secondary) can
# share one hashed matrix with HSquared.jl REML.
#
# HONESTY:
#   - NOT a covered flip. Count stays 6 until design-41 §3 + Rose + #7.
#   - NOT the 2026-06-22 supplied-variance comparator.
#   - NOT D1 / quarantine / ASReml.
#   - Do not run validation-scale legs from this file until Fisher ratifies
#     tolerances in docs/design/52-v07-exact-G-comparator-recipe.md and a
#     named Totoro (or DRAC) job is approved (D-139).
#
# Tiny smoke (laptop OK):
#   julia --project=. sim/recipes/exact_G_estimated_vc_comparator.jl
#
# Validation-scale one-shot: Totoro preferred (owner #9). Prefer ControlMaster
# socket; else queue DRAC array scripts without interactive Duo.

using Dates
using LinearAlgebra
using Random
using SHA
using SparseArrays
using HSquared

const RECIPE_ID = "0.7-S0b-exact-G-estimated-VC"
const RIDGE_DEFAULT = 0.01

"""
    vanraden1_G(markers; ridge=0.0) -> NamedTuple

Build VanRaden method-1 `G = WW'/k` with sample allele frequencies.
When `ridge > 0`, also return `K = G + ridge*I` (design-51 / design-44 scale).
"""
function vanraden1_G(markers::AbstractMatrix{<:Real}; ridge::Real = 0.0)
    n, m = size(markers)
    n >= 2 || throw(ArgumentError("need n >= 2 genotyped rows"))
    m >= 1 || throw(ArgumentError("need ≥1 marker"))
    p = vec(sum(markers; dims = 1)) ./ (2n)
    W = Matrix{Float64}(markers) .- (2 .* p')
    k = 2 * sum(p .* (1 .- p))
    k > 0 || throw(ArgumentError("VanRaden k must be > 0"))
    G = (W * W') ./ k
    G = Symmetric(0.5 .* (G .+ G'))
    K = ridge > 0 ? Symmetric(Matrix(G) .+ Float64(ridge) .* I(n)) : G
    return (; G = Matrix(G), K = Matrix(K), p, k, ridge = Float64(ridge), n, m)
end

function matrix_sha256(A::AbstractMatrix{<:Real})
    bytes = reinterpret(UInt8, vec(Float64.(A)))
    return bytes2hex(sha256(bytes))
end

function write_matrix_csv(path::AbstractString, A::AbstractMatrix; ids = nothing)
    open(path, "w") do io
        if ids === nothing
            println(io, join(["c$j" for j in 1:size(A, 2)], ","))
            for i in 1:size(A, 1)
                println(io, join(string.(A[i, :]), ","))
            end
        else
            println(io, join(["id"; ids], ","))
            for (i, id) in enumerate(ids)
                println(io, join([string(id); string.(A[i, :])], ","))
            end
        end
    end
    return path
end

"""
Tiny deterministic smoke: build G/K_lambda, hash, and fit engine REML on K^{-1}.
Does **not** call sommer/rrBLUP (those live on R/Totoro hosts).
"""
function smoke_exact_G_export(; n = 12, m = 40, seed = 20260902, ridge = RIDGE_DEFAULT)
    rng = MersenneTwister(seed)
    markers = rand(rng, 0:2, n, m) .* 1.0
    ids = ["i$i" for i in 1:n]
    built = vanraden1_G(markers; ridge = ridge)
    # Prefer engine constructors when available (parity with production path).
    G_engine = genomic_relationship_matrix(markers)
    Q = genomic_relationship_inverse(G_engine; ridge = ridge)
    @assert size(G_engine) == (n, n)
    X = ones(n, 1)
    Z = sparse(1.0I, n, n)
    # Known-signal DGP on genomic scale (smoke only; not a recovery gate).
    u = cholesky(Symmetric(Matrix(G_engine) .+ 1e-8 .* I(n))).L * randn(rng, n)
    y = sqrt(0.6) .* u .+ sqrt(0.4) .* randn(rng, n)
    fit = fit_gblup_reml(y, X, Z, Q; ids = ids,
                         initial = (sigma_a2 = 0.6, sigma_e2 = 0.4))
    rG = heritability(fit)
    meta = Dict(
        "recipe_id" => RECIPE_ID,
        "seed" => seed,
        "n" => n,
        "m" => m,
        "ridge" => ridge,
        "k" => built.k,
        "G_sha256" => matrix_sha256(Matrix(G_engine)),
        "K_sha256" => matrix_sha256(built.K),
        "sigma_a2" => fit.variance_components.sigma_a2,
        "sigma_e2" => fit.variance_components.sigma_e2,
        "genomic_variance_ratio_numeric" => rG,
        "converged" => fit.converged,
        "note" => "numeric ratio only on engine; R labels genomic_variance_ratio (N2)",
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
    )
    return (; built, G_engine, Q, fit, meta)
end

if abspath(PROGRAM_FILE) == @__FILE__
    result = smoke_exact_G_export()
    println("RECIPE_SMOKE ", RECIPE_ID)
    for (k, v) in sort(collect(result.meta); by = first)
        println(k, "=", v)
    end
    println("STATUS=smoke_ok NOT_LAUNCHED_COMPARATOR")
end
