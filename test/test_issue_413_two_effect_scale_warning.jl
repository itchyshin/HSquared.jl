# HSquared.jl #413 — warn when two-effect unit-scale starts meet a far-from-unit y.
# Standalone:
# julia --project=. -e 'include("test/test_issue_413_two_effect_scale_warning.jl")'

using HSquared
using LinearAlgebra
using Logging
using Test

@testset "issue 413 two-effect unit-scale start is warned" begin
    help = read(joinpath(@__DIR__, "..", "src", "likelihood.jl"), String)
    @test occursin("unit-scale start", help)
    @test occursin("HSquared.jl #413", help)
    @test occursin("_TWO_EFFECT_UNIT_START_OFF_SCALE_MSG", help)
    @test occursin("near-zero-h2", HSquared._TWO_EFFECT_UNIT_START_OFF_SCALE_MSG)

    y = [14.0, 13.0, 6.9, 6.1, 12.1, 11.5, 8.9, 8.5]
    y_big = y .* 1000
    y_tiny = y .* 1e-4
    @test !HSquared._two_effect_unit_start_off_scale(y, 1.0, 1.0, 1.0)
    @test HSquared._two_effect_unit_start_off_scale(y_big, 1.0, 1.0, 1.0)
    @test HSquared._two_effect_unit_start_off_scale(y_tiny, 1.0, 1.0, 1.0)
    @test !HSquared._two_effect_unit_start_off_scale(y_big, 1e6, 1e6, 1e6)

    Ainv = pedigree_inverse([1, 2, 3, 4], [0, 0, 1, 1], [0, 0, 2, 2])
    Z = zeros(8, 4)
    for (rec, an) in enumerate([1, 1, 2, 2, 3, 3, 4, 4])
        Z[rec, an] = 1.0
    end
    X = ones(8, 1)
    Z2 = [1.0 0; 1 0; 0 1; 0 1; 1 0; 0 1; 1 0; 0 1]

    @test_logs (:warn, r"unit-scale start") min_level = Logging.Warn begin
        fit_two_effect_reml(y_big, X, Z, Ainv, Z2, Matrix(1.0I, 2, 2); iterations = 1)
    end
    @test_logs min_level = Logging.Warn begin
        fit_two_effect_reml(
            y_big,
            X,
            Z,
            Ainv,
            Z2,
            Matrix(1.0I, 2, 2);
            initial = (sigma1 = 1e6, sigma2 = 1e6, sigma_e2 = 1e6),
            iterations = 1,
        )
    end
end
