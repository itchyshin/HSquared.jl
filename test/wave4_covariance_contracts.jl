using Test
using LinearAlgebra
using HSquared

@testset "Scale-relative G covariance contracts" begin
    for scale in (1e-10, 1.0, 1e10)
        invalid = scale .* [1.0 2.0; 2.0 1.0]
        valid = scale .* [1.0 1.0; 1.0 1.0]
        @test_throws ArgumentError genetic_correlation(invalid)
        @test_throws ArgumentError genetic_correlation_plot_data(invalid)
        @test_throws ArgumentError genetic_pca(invalid)
        @test genetic_correlation(valid)[1, 2] ≈ 1.0
        @test minimum(genetic_pca(valid).values) >= -1e-8 * scale
    end
    # A global covariance scale cannot protect correlations when trait units differ.
    unequal_units = [1e-20 1.0; 1.0 1e10]
    @test_throws ArgumentError genetic_correlation(unequal_units)
    @test_throws ArgumentError genetic_correlation_plot_data(unequal_units)
    @test_throws ArgumentError genetic_pca(unequal_units)
    valid_unequal_units = [1e-20 5e-6; 5e-6 1e10]
    @test genetic_correlation(valid_unequal_units)[1, 2] ≈ 0.5
    @test minimum(genetic_pca(valid_unequal_units).values) >= 0
    @test genetic_pca(zeros(2, 2)).values == zeros(2)
    @test minimum(genetic_pca([1.0 0.0; 0.0 -1e-12]).values) == 0.0
end

@testset "Animal-only covariance uncertainty rejects repeatability" begin
    repeatability = (
        genetic_structure = :unstructured,
        genetic_covariance = Matrix{Float64}(I, 2, 2),
        permanent_covariance = Matrix{Float64}(I, 2, 2),
        residual_covariance = Matrix{Float64}(I, 2, 2),
        genetic_correlation = Matrix{Float64}(I, 2, 2),
        converged = true,
    )
    Y = [1.0 2.0; 2.0 3.0]
    X = ones(2, 1)
    Z = Matrix{Float64}(I, 2, 2)
    Ainv = Matrix{Float64}(I, 2, 2)
    @test_throws ArgumentError multivariate_covariance_standard_errors(repeatability, Y, X, Z, Ainv)
    @test_throws ArgumentError genetic_correlation_interval(repeatability, Y, X, Z, Ainv)
end
