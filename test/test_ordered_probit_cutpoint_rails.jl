using HSquared
using LinearAlgebra
using Test

@testset "ordered-probit cutpoint-increment rails" begin
    # Category 3 is absent, so the likelihood drives the increment between the
    # second and third cutpoints toward zero (delta -> -Inf) without a rail.
    y = Float64[1, 2, 4, 1, 2, 4, 1, 2, 4, 1, 2, 4]
    X = ones(length(y), 1)
    Z = Matrix{Float64}(I, length(y), length(y))
    Ainv = Matrix{Float64}(I, length(y), length(y))

    fit = fit_laplace_reml(
        y,
        X,
        Z,
        Ainv;
        family = :ordered_probit,
        iterations = 500,
    )

    increments = diff(fit.variance_components.cutpoints)
    delta = log.(increments)
    @test all(isfinite, delta)
    @test all(abs.(delta) .<= 8.0 + 1e-6)
    @test any(abs.(delta) .>= 8.0 - 1e-3)
    @test fit.boundary
end
