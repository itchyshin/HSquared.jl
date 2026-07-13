# Deterministic v0.7 genomic public-activation target (doc 44).
# Run from the repository root:
#
#   julia --project=. test/fixtures/genomic_public_activation_target/generate.jl

using HSquared
using LinearAlgebra
using Printf
using Random
using SparseArrays

const DIR = @__DIR__
const SEED = 20270701
const N = 120
const MCOUNT = 600
const RIDGE = 0.01

fmt(x) = @sprintf("%.17g", x)

function write_csv(path, rows)
    open(path, "w") do io
        for row in rows
            println(io, join(row, ","))
        end
    end
end

function main()
    rng = MersenneTwister(SEED)
    ids = [@sprintf("g%03d", i) for i in 1:N]
    marker_names = [@sprintf("m%04d", j) for j in 1:MCOUNT]
    population_maf = 0.05 .+ 0.45 .* rand(rng, MCOUNT)
    markers = Float64[
        (rand(rng) < population_maf[j]) + (rand(rng) < population_maf[j])
        for i in 1:N, j in 1:MCOUNT
    ]
    construction = HSquared._genomic_activation_construction(
        markers, ids; marker_names = marker_names, ridge = RIDGE,
    )

    # Ninety phenotyped individuals, the first thirty measured twice, and thirty additional
    # genotyped individuals without records. The second fixed column is record-level and nonconstant.
    record_rows = vcat(collect(1:90), collect(1:30))
    record_ids = ids[record_rows]
    x = collect(range(-1.0, 1.0; length = length(record_rows)))
    X = hcat(ones(length(record_rows)), x)
    Z = sparse(1:length(record_rows), record_rows, 1.0, length(record_rows), N)
    beta = [2.0, 0.4]
    sigma_g2 = 0.5
    sigma_e2 = 0.5
    u = cholesky(Symmetric(construction.K)).L * randn(rng, N) .* sqrt(sigma_g2)
    y = X * beta + Z * u + randn(rng, length(record_rows)) .* sqrt(sigma_e2)
    fit = fit_gblup_reml(y, X, Z, construction.Q; ids = ids)
    fit.converged || error("fixture fit did not converge")
    vc = fit.variance_components
    ratio = vc.sigma_a2 / (vc.sigma_a2 + vc.sigma_e2)

    write_csv(
        joinpath(DIR, "markers.csv"),
        vcat([["id"; marker_names]],
             [[ids[i]; [fmt(markers[i, j]) for j in 1:MCOUNT]] for i in 1:N]),
    )
    write_csv(
        joinpath(DIR, "phenotypes.csv"),
        vcat([["record", "id", "x", "y"]],
             [[string(r), record_ids[r], fmt(x[r]), fmt(y[r])] for r in eachindex(y)]),
    )

    open(joinpath(DIR, "expected_construction.csv"), "w") do io
        println(io, "quantity,row,column,value")
        @printf(io, "k,0,0,%s\n", fmt(construction.k))
        for j in 1:MCOUNT
            @printf(io, "p,%d,0,%s\n", j, fmt(construction.p[j]))
        end
        for (name, value) in (("W", construction.W), ("G", construction.G),
                              ("K", construction.K), ("Q", construction.Q))
            for i in axes(value, 1), j in axes(value, 2)
                @printf(io, "%s,%d,%d,%s\n", name, i, j, fmt(value[i, j]))
            end
        end
    end

    provenance = construction.provenance
    open(joinpath(DIR, "expected_fit.csv"), "w") do io
        println(io, "quantity,id,value")
        @printf(io, "seed,,%d\n", SEED)
        @printf(io, "ridge,,%s\n", fmt(RIDGE))
        @printf(io, "n_genotyped,,%d\n", N)
        @printf(io, "n_markers,,%d\n", MCOUNT)
        @printf(io, "n_records,,%d\n", length(y))
        @printf(io, "sigma_g2,,%s\n", fmt(vc.sigma_a2))
        @printf(io, "sigma_e2,,%s\n", fmt(vc.sigma_e2))
        @printf(io, "genomic_variance_ratio,,%s\n", fmt(ratio))
        @printf(io, "loglik,,%s\n", fmt(fit.likelihood.loglik))
        @printf(io, "converged,,%s\n", fit.converged)
        @printf(io, "id_order_fingerprint,,%s\n", provenance.id_order_fingerprint)
        @printf(io, "marker_content_fingerprint,,%s\n", provenance.marker_content_fingerprint)
        @printf(io, "kernel_fingerprint,,%s\n", provenance.kernel_fingerprint)
        @printf(io, "precision_fingerprint,,%s\n", provenance.precision_fingerprint)
        for j in eachindex(fit.likelihood.beta)
            @printf(io, "beta,%d,%s\n", j, fmt(fit.likelihood.beta[j]))
        end
        for (id, value) in zip(ids, breeding_values(fit).values)
            @printf(io, "gebv,%s,%s\n", id, fmt(value))
        end
    end
end

main()
