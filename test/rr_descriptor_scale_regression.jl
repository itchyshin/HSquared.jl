using Test, LinearAlgebra, HSquared

@testset "RR descriptor finite scaling" begin
    @testset "standardization endpoints and caller bounds" begin
        for (lower, upper) in ((-Inf, Inf), (0.0, Inf), (-Inf, 1.0), (NaN, 1.0), (0.0, NaN))
            @test_throws ArgumentError standardize_covariate([0.0, 1.0]; lower=lower, upper=upper)
        end
        for a in ([0.0, Inf], [NaN, 1.0], [0.0, -Inf])
            @test_throws ArgumentError standardize_covariate(a; lower=0.0, upper=1.0)
        end
        for a in ([0.0, 0.5e308, 1e308], [-1e308, 0.0, 1e308], [-floatmax(Float64), 0.0, floatmax(Float64)])
            result = standardize_covariate(a)
            @test all(isfinite, result)
            @test result ≈ [-1.0, 0.0, 1.0]
        end
        @test standardize_covariate([1e308]; lower=-1e308, upper=-9e307) ≈ [39.0]
        @test standardize_covariate([10.0, 20.0, 30.0]) ≈ [-1.0, 0.0, 1.0]
        @test standardize_covariate([2.0, 6.0]; lower=0.0, upper=8.0) ≈ [-0.5, 0.5]
        @test_throws ArgumentError standardize_covariate([5.0, 5.0])
        @test_throws ArgumentError standardize_covariate([0.0, floatmax(Float64)]; lower=0.0, upper=1.0)
    end

    @testset "heritability uses the normalized Legendre variance" begin
        ts = [0.0, 0.5]
        K = reshape([1.6], 1, 1)
        Kbig = reshape([1.6e308], 1, 1)
        # phi0 = sqrt(1/2), so genetic variance is 0.8e308 and h2 is 0.4.
        @test legendre_basis(0.0, 1)[1]^2 ≈ 0.5
        @test rr_genetic_variance(Kbig, [0.0]).values[1] / 1e308 ≈ 0.8
        @test rr_heritability(Kbig, 1.2e308, ts).values ≈ [0.4, 0.4]
        @test rr_heritability(Kbig, [1.2e308, 0.8e308], ts).values ≈ [0.4, 0.5]
        @test rr_heritability(Kbig, 1.2e308, ts).values ≈ rr_heritability(K, 1.2, ts).values
        @test rr_heritability(K, 1.2, ts).values ≈ [0.4, 0.4]
        @test rr_heritability(zeros(1, 1), 1.2, ts).values == [0.0, 0.0]
        @test rr_genetic_variance_plot_data(Kbig, ts; residual=1.2e308).heritability ≈ [0.4, 0.4]
        # The underlying genetic variance exceeds Float64; reject a ratio to infinity.
        @test_throws ArgumentError rr_heritability(Matrix(Diagonal([1e308, 1e308])), 1e308, [1.0])
    end

    @testset "eigenvalue shares preserve finite scale invariance" begin
        ts = [-1.0, 0.0, 1.0]
        for (eigenvalues, expected) in (([1e308, 1e308], [0.5, 0.5]), ([1.2e308, 0.8e308], [0.6, 0.4]))
            K = Matrix(Diagonal(eigenvalues))
            out = rr_eigenfunctions(K, ts)
            @test out.variance_explained ≈ expected
            @test sum(out.variance_explained) ≈ 1.0
            @test all(isfinite, out.variance_explained)
            @test out.variance_explained ≈ rr_eigenfunctions(K / 1e308, ts).variance_explained
            @test rr_eigenfunctions_plot_data(K, ts).variance_explained ≈ expected
        end
        @test rr_eigenfunctions(zeros(2, 2), ts).variance_explained == [0.0, 0.0]
        @test rr_eigenfunctions(Matrix(Diagonal([2.0, 0.0])), ts).variance_explained == [1.0, 0.0]
        @test rr_eigenfunctions(Matrix(Diagonal([0.6, 0.4])), ts).variance_explained ≈ [0.6, 0.4]
    end
end
