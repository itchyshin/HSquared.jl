# test_214_217_dense_cells.jl -- engine half of hsquared#214 / #217
#
# #214: the R default animal() route reaches `_check_dense_validation_size`
# via `fit_animal_model` -> `fit_variance_components`, but the effective cap
# was invisible from R (no lever, and the error text did not name the cap).
# #217: `fit_repeatability_reml` builds a dense n x n marginal via
# `inv(Symmetric(Matrix{Float64}(Ainv)))` with NO guard at all, so it never
# rejects an over-cap fit before paying the O(n^3) dense inverse.
#
# Fix pinned here: a `max_dense_cells` kwarg on `fit_repeatability_reml`
# (guard placed before the dense inverse), and a generalized
# `_check_dense_validation_size(nobs, nanimals, max_dense_cells)` that the
# `AnimalModelSpec` method now calls. `fit_variance_components`,
# `gaussian_loglik`, and `bootstrap_variance_component_interval` already
# accepted the kwarg; this file pins that they still do, and pins the new
# error text naming the effective cap.
#
# Fixture: 20 unrelated "animals" (Ainv = I), one observation per animal
# (nobs = 20), so nobs^2 + nanimals^2 = 800 -- small enough to fit in
# milliseconds under the real default cap (1_000_000), but easily over a
# tiny test cap (50). Deterministic y (no RNG), so the test is reproducible
# without a seed.

using HSquared
using LinearAlgebra
using Test

@testset "214/217: max_dense_cells kwarg on the dense-validation fitters" begin
    n = 20
    Ainv = Matrix(1.0I, n, n)
    X = ones(n, 1)
    Z = Matrix(1.0I, n, n)
    y = collect(1.0:n) .+ 0.1 .* sin.(1.0:n)
    spec = HSquared.animal_model_spec(y, X, Z, Ainv; method = :REML)
    expected_cells = n * n + n * n  # 800

    function _throws_with_message(f)
        try
            f()
            return false, ""
        catch e
            return e isa ArgumentError, sprint(showerror, e)
        end
    end

    @testset "fit_repeatability_reml rejects an over-cap fit before the dense inverse" begin
        threw, msg = _throws_with_message() do
            fit_repeatability_reml(y, X, Z, Ainv; max_dense_cells = 50)
        end
        @test threw
        @test occursin("max_dense_cells = 50", msg)
        @test occursin(string(expected_cells), msg)
    end

    @testset "fit_repeatability_reml runs at the default cap" begin
        fit = fit_repeatability_reml(y, X, Z, Ainv; iterations = 20)
        @test fit.variance_components.sigma_a2 > 0
        @test fit.variance_components.sigma_pe2 > 0
        @test fit.variance_components.sigma_e2 > 0
    end

    @testset "fit_variance_components: same guard, generalized" begin
        @test_throws ArgumentError fit_variance_components(spec; max_dense_cells = 50)
        fit = fit_variance_components(spec; max_dense_cells = 10_000)
        @test fit.variance_components.sigma_a2 > 0
    end

    @testset "gaussian_loglik and bootstrap_variance_component_interval accept max_dense_cells (smoke)" begin
        @test_nowarn gaussian_loglik(spec, 1.0, 1.0; max_dense_cells = 10_000)
        @test_throws ArgumentError gaussian_loglik(spec, 1.0, 1.0; max_dense_cells = 50)

        fit = fit_variance_components(spec)
        @test_nowarn bootstrap_variance_component_interval(fit; n_boot = 2, max_dense_cells = 10_000)
    end
end
