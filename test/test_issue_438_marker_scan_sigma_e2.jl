# HSquared.jl #438 — marker scans must not silently treat residual variance as 1.0.
# Standalone: julia --project=. -e 'include("test/test_issue_438_marker_scan_sigma_e2.jl")'

using HSquared
using LinearAlgebra
using Random
using Test

function _scan_fixture()
    y = [10.0, 20.0, 40.0, 20.0, 30.0]
    X = ones(5, 1)
    M = [
        0.0 0.0
        1.0 0.0
        2.0 1.0
        0.0 2.0
        1.0 2.0
    ]
    return y, X, M
end

function _null_residual_mean_square(y, X)
    yv = Float64.(y)
    Xmat = Matrix{Float64}(X)
    n, p = size(Xmat)
    XtX = Symmetric(transpose(Xmat) * Xmat)
    y_resid = yv - Xmat * (XtX \ (transpose(Xmat) * yv))
    return dot(y_resid, y_resid) / (n - p)
end

@testset "marker scan residual scale (HSquared.jl #438)" begin
    y, X, M = _scan_fixture()
    expected_rms = _null_residual_mean_square(y, X)
    @test expected_rms ≈ 130.0 atol = 1e-12
    @test expected_rms != 1.0

    @testset "omitted sigma_e2 uses the null residual mean square" begin
        scan = single_marker_scan(y, X, M; marker_ids = ["m1", "m2"])
        @test scan.sigma_e2_source === :estimated
        @test scan.sigma_e2_used ≈ expected_rms atol = 1e-12
        @test scan.standard_errors ≈ sqrt.(scan.sigma_e2_used ./ scan.denominators) atol = 1e-12

        silent_unit = single_marker_scan(y, X, M; sigma_e2 = 1.0, marker_ids = ["m1", "m2"])
        @test silent_unit.sigma_e2_source === :supplied
        @test silent_unit.sigma_e2_used == 1.0
        @test scan.effects ≈ silent_unit.effects atol = 1e-12
        @test scan.standard_errors ≈ silent_unit.standard_errors .* sqrt(expected_rms) atol = 1e-12
        @test scan.z_scores ≈ silent_unit.z_scores ./ sqrt(expected_rms) atol = 1e-12
        @test all(scan.p_values .> silent_unit.p_values)
    end

    @testset "supplied sigma_e2 is used and labelled" begin
        scan = single_marker_scan(y, X, M; sigma_e2 = 25.0, marker_ids = ["m1", "m2"])
        @test scan.sigma_e2_source === :supplied
        @test scan.sigma_e2_used == 25.0
        @test scan.standard_errors ≈ sqrt.(25.0 ./ scan.denominators) atol = 1e-12
    end

    @testset "genome_wide_marker_scan forwards the resolved scale" begin
        scan = genome_wide_marker_scan(
            y,
            X,
            M;
            n_permutations = 2,
            marker_ids = ["m1", "m2"],
            rng = MersenneTwister(438),
        )
        base = single_marker_scan(y, X, M; marker_ids = ["m1", "m2"])
        @test scan.sigma_e2_source === :estimated
        @test scan.sigma_e2_used ≈ base.sigma_e2_used atol = 1e-12
        @test scan.standard_errors ≈ base.standard_errors atol = 1e-12
        @test scan.p_values ≈ base.p_values atol = 1e-12

        supplied = genome_wide_marker_scan(
            y,
            X,
            M;
            n_permutations = 2,
            sigma_e2 = 25.0,
            marker_ids = ["m1", "m2"],
            rng = MersenneTwister(438),
        )
        @test supplied.sigma_e2_source === :supplied
        @test supplied.sigma_e2_used == 25.0
        @test supplied.standard_errors ≈ sqrt.(25.0 ./ supplied.denominators) atol = 1e-12
    end

    @testset "invalid supplied residual variance still errors" begin
        @test_throws ArgumentError single_marker_scan(y, X, M; sigma_e2 = 0.0)
        @test_throws ArgumentError single_marker_scan(y, X, M; sigma_e2 = -1.0)
        @test_throws ArgumentError genome_wide_marker_scan(y, X, M; n_permutations = 1, sigma_e2 = -1.0)
    end
end
