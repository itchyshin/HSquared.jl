# 0.8 S3 — uniqueness-interior bound + Ledermann covered-flip refuse.
# NOT a covered flip. Does not reopen the S2 DGP. Does not run S4.

using HSquared
using LinearAlgebra
using Test

@testset "0.8 S3 FA uniqueness-interior bound (not a covered flip)" begin
    @testset "Ledermann slack and covered-flip refuse" begin
        @test ledermann_slack(4, 1) == 4
        @test ledermann_slack(3, 1) == 0
        @test ledermann_slack(5, 2) == 2
        @test ledermann_slack(2, 1) == -2
        @test fa_covered_flip_cell(4, 1)
        @test !fa_covered_flip_cell(3, 1)
        @test !fa_covered_flip_cell(2, 1)
        @test require_fa_covered_flip_cell(4, 1) == 4
        @test_throws ArgumentError require_fa_covered_flip_cell(3, 1)
        @test_throws ArgumentError require_fa_covered_flip_cell(2, 1)
        @test_throws ArgumentError ledermann_slack(0, 1)
        @test_throws ArgumentError ledermann_slack(3, 0)
        @test_throws ArgumentError ledermann_slack(2, 3)
        err = try
            require_fa_covered_flip_cell(3, 1)
            ""
        catch e
            e isa ArgumentError ? e.msg : string(e)
        end
        @test occursin("not a covered-flip cell", err)
        @test occursin("t=4 K=1", err)
    end

    @testset "Unconstrained uniqueness never drops below the floor" begin
        θ = [-40.0, -1.0, 0.0]
        ψ = HSquared._fa_uniqueness_from_unconstrained(θ)
        @test all(ψ .>= FA_UNIQUENESS_FLOOR)
        @test ψ[1] ≈ FA_UNIQUENESS_FLOOR atol = 1e-12
        @test ψ[3] ≈ FA_UNIQUENESS_FLOOR + 1.0
        interior = [0.35, 0.45, 0.55, 0.50]
        θ2 = HSquared._fa_uniqueness_to_unconstrained(interior)
        @test HSquared._fa_uniqueness_from_unconstrained(θ2) ≈ interior
        @test_throws ArgumentError HSquared._fa_uniqueness_to_unconstrained([1e-4, 0.2])
        @test_throws ArgumentError HSquared._fa_uniqueness_to_unconstrained([1e-5, 0.2])
        params = vcat([0.5, -0.3], [-40.0, -40.0])
        _, _, ψhat = HSquared._structured_genetic_params_to_cov(params, 2, :factor_analytic, 1)
        @test all(ψhat .>= FA_UNIQUENESS_FLOOR)
        @test minimum(ψhat) ≈ FA_UNIQUENESS_FLOOR atol = 1e-12
    end

    @testset "Fitted FA uniqueness stays at or above the floor" begin
        ped = normalize_pedigree(
            ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
            ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
            ["0", "0", "a2", "a2", "0", "0", "a4", "a6"],
        )
        Ainv = pedigree_inverse(ped)
        y1 = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
        Y2 = hcat(y1, reverse(y1))
        X = ones(8, 1)
        Z = Matrix(1.0I, 8, 8)
        fa = fit_multivariate_reml(
            Y2, X, Z, Ainv;
            genetic_structure = :factor_analytic,
            rank = 1,
            initial = (
                loadings = reshape([0.5, -0.3], 2, 1),
                uniqueness = [2e-4, 2e-4],
                R0 = [1.0 0.0; 0.0 1.0],
            ),
        )
        @test all(fa.genetic_uniqueness .>= FA_UNIQUENESS_FLOOR)
        @test fa.genetic_covariance ≈
            factor_analytic_covariance(fa.genetic_loadings, fa.genetic_uniqueness) atol = 1e-8
        @test_throws ArgumentError fit_multivariate_reml(
            Y2, X, Z, Ainv;
            genetic_structure = :factor_analytic,
            rank = 1,
            initial = (
                loadings = reshape([0.5, -0.3], 2, 1),
                uniqueness = [1e-4, 0.2],
                R0 = [1.0 0.0; 0.0 1.0],
            ),
        )
        @test_throws ArgumentError fit_multivariate_reml(
            Y2, X, Z, Ainv;
            genetic_structure = :factor_analytic,
            rank = 1,
            initial = (
                loadings = reshape([0.5, -0.3], 2, 1),
                uniqueness = [1e-5, 0.2],
                R0 = [1.0 0.0; 0.0 1.0],
            ),
        )
    end
end
