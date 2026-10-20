# HSquared.jl #422 — SE / interval must be withheld when the REML information
# matrix is singular (founders-only A = I ridge), not 2e7, 0.0 or a crash.
# Standalone:
# julia --project=. -e 'include("test/test_issue_422_singular_information_se.jl")'

using HSquared
using LinearAlgebra
using Logging
using Random
using SparseArrays
using Test

@testset "issue 422 singular information withholds SE and interval" begin
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
        fit = with_logger(NullLogger()) do
            fit_ai_reml(spec; initial = (sigma_a2 = ini[1], sigma_e2 = ini[2]))
        end
        @test fit.converged
        for fn in (variance_component_covariance, variance_component_standard_errors,
                   heritability_standard_error, heritability_interval)
            err = try
                fn(fit)
                nothing
            catch e
                e
            end
            @test err isa ArgumentError
            @test err isa ArgumentError && occursin("not identified", err.msg)
        end
    end

    # Control: an identified half-sib design still returns finite SEs.
    nsire, per = 20, 8
    m = nsire + nsire * per
    sires = [fill("0", nsire); repeat(string.(1:nsire), inner = per)]
    ped2 = normalize_pedigree(string.(1:m), sires, fill("0", m))
    rng = MersenneTwister(422)
    breeding = randn(rng, nsire)
    y2 = [zeros(nsire); [breeding[s] + 1.5 * randn(rng) for s in 1:nsire for _ in 1:per]]
    spec2 = animal_model_spec(
        y2, ones(m, 1), sparse(1.0I, m, m), pedigree_inverse(ped2);
        ids = ped2.ids, method = :REML,
    )
    fit2 = fit_ai_reml(spec2; initial = (sigma_a2 = 0.5, sigma_e2 = 0.5))
    @test fit2.converged
    @test isfinite(heritability_standard_error(fit2)) && heritability_standard_error(fit2) > 0
    @test all(isfinite, values(variance_component_standard_errors(fit2)))
end
