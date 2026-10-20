# HSquared.jl #422 -- withhold SEs and intervals when the REML information
# matrix is singular (founders-only A = I, Z = I: Va and Ve not separately identified).
# Standalone:
# julia --project=. -e 'include("test/test_issue_422_singular_information.jl")'

using HSquared
using LinearAlgebra
using Random
using SparseArrays
using Test

@testset "issue 422 singular information withholds SE and interval" begin
    n = 30
    ids = string.(1:n)
    ped = normalize_pedigree(ids, fill("0", n), fill("0", n))
    Ainv = pedigree_inverse(ped)
    y = [1.622, 3.04, 1.928, 1.91, 0.916, 2.399, 1.219, 0.641, 1.14, 2.198, 2.954, 2.712,
         2.797, 1.513, 1.487, 4.829, 3.032, 2.472, 2.986, 4.373, 1.927, 0.055, 3.354, 1.418,
         2.145, 2.403, 1.675, 2.589, 0.944, 2.258]
    X = hcat(ones(n), Float64.(repeat([0, 1], n ÷ 2)))
    Z = sparse(1.0I, n, n)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    fits = Base.CoreLogging.with_logger(Base.CoreLogging.NullLogger()) do
        [fit_ai_reml(spec; initial = (sigma_a2 = a, sigma_e2 = e))
         for (a, e) in ((1.0, 1.0), (0.5, 0.5), (0.2, 0.8))]
    end
    for f in fits
        @test f.converged
        @test_throws ArgumentError variance_component_covariance(f)
        @test_throws ArgumentError variance_component_standard_errors(f)
        @test_throws ArgumentError heritability_standard_error(f)
        @test_throws ArgumentError heritability_interval(f)
    end
    err = try
        heritability_standard_error(fits[1]); nothing
    catch e
        e
    end
    @test occursin("singular", err.msg)

    # Control: an identified half-sib pedigree still returns finite positive SEs.
    ns, nd, k = 10, 10, 8
    m = ns + nd + nd * k
    sire = vcat(fill("0", ns + nd), [string(1 + (j - 1) % ns) for j in 1:nd for _ in 1:k])
    dam = vcat(fill("0", ns + nd), [string(ns + j) for j in 1:nd for _ in 1:k])
    ped2 = normalize_pedigree(string.(1:m), sire, dam)
    Ainv2 = pedigree_inverse(ped2)
    rng = MersenneTwister(1)
    L = cholesky(Symmetric(Matrix(inv(Matrix(Ainv2))))).L
    y2 = 1.0 .+ L * randn(rng, m) .* sqrt(0.5) .+ randn(rng, m) .* sqrt(0.5)
    spec2 = animal_model_spec(y2, reshape(ones(m), m, 1), sparse(1.0I, m, m), Ainv2;
                              ids = ped2.ids, method = :REML)
    f2 = fit_ai_reml(spec2; initial = (sigma_a2 = 0.5, sigma_e2 = 0.5))
    @test f2.converged
    se = heritability_standard_error(f2)
    @test isfinite(se) && se > 0
    @test all(isfinite, values(variance_component_standard_errors(f2)))
end
