# HSquared.jl #422 -- withhold SEs when the REML information matrix is singular.
# Standalone:
# julia --project=. -e 'include("test/test_issue_422_singular_information_se.jl")'

using HSquared
using LinearAlgebra
using Random
using SparseArrays
using Test

@testset "issue 422 singular information refuses SEs" begin
    n = 30
    ids = string.(1:n)
    ped = normalize_pedigree(ids, fill("0", n), fill("0", n))
    Ainv = pedigree_inverse(ped)
    y = [1.622, 3.04, 1.928, 1.91, 0.916, 2.399, 1.219, 0.641, 1.14, 2.198,
         2.954, 2.712, 2.797, 1.513, 1.487, 4.829, 3.032, 2.472, 2.986, 4.373,
         1.927, 0.055, 3.354, 1.418, 2.145, 2.403, 1.675, 2.589, 0.944, 2.258]
    X = hcat(ones(n), Float64.(repeat([0, 1], n ÷ 2)))
    Z = sparse(1.0I, n, n)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)

    for ini in [(1.0, 1.0), (0.5, 0.5), (0.2, 0.8)]
        fit = Base.CoreLogging.with_logger(Base.CoreLogging.NullLogger()) do
            fit_ai_reml(spec; initial = (sigma_a2 = ini[1], sigma_e2 = ini[2]))
        end
        @test fit.converged
        @test_throws ArgumentError variance_component_covariance(fit)
        @test_throws ArgumentError variance_component_standard_errors(fit)
        @test_throws ArgumentError heritability_standard_error(fit)
        @test_throws ArgumentError heritability_interval(fit)
    end

    # Identified design (half-sib families): SEs are still returned.
    nsire, nper = 20, 10
    m = nsire * nper
    sires = [string("s", i) for i in 1:nsire]
    off = [string("o", i) for i in 1:m]
    pid = vcat(sires, off)
    sire = vcat(fill("0", nsire), repeat(sires, inner = nper))
    dam = fill("0", nsire + m)
    ped2 = normalize_pedigree(pid, sire, dam)
    A2inv = pedigree_inverse(ped2)
    q = nsire + m
    # two records per offspring so that the residual is identified
    rng = MersenneTwister(422)
    breeding = vcat(0.7 .* randn(rng, nsire), zeros(m))
    for i in 1:m
        breeding[nsire + i] = 0.5 * breeding[(i - 1) ÷ nper + 1] + sqrt(0.75) * 0.7 * randn(rng)
    end
    animal_of = repeat(nsire + 1:q, inner = 2)
    y2 = breeding[animal_of] .+ randn(rng, 2m)
    Z2 = sparse(1:2m, animal_of, 1.0, 2m, q)
    spec2 = animal_model_spec(y2, ones(2m, 1), Z2, A2inv; ids = ped2.ids, method = :REML)
    fit2 = fit_ai_reml(spec2; initial = (sigma_a2 = 0.2, sigma_e2 = 0.3))
    @test fit2.converged
    se = heritability_standard_error(fit2)
    @test isfinite(se) && se > 0
end
