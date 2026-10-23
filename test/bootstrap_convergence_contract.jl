using Test
using HSquared

@testset "bootstrap refit convergence contract" begin
    interior = (variance_components = (sigma_a2 = 0.8, sigma_e2 = 1.2),)
    good = merge(interior, (converged = true,))
    stalled = merge(interior, (converged = false,))
    boundary = (converged = true, variance_components = (sigma_a2 = 0.0, sigma_e2 = 1.2))
    invalid = (converged = true, variance_components = (sigma_a2 = NaN, sigma_e2 = 1.2))

    @test HSquared._bootstrap_usable_refit(good)
    @test !HSquared._bootstrap_usable_refit(stalled)
    @test !HSquared._bootstrap_usable_refit(boundary)
    @test !HSquared._bootstrap_usable_refit(invalid)
end
