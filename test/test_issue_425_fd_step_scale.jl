# HSquared.jl #425 — finite-difference component steps must scale with the
# variance-component vector, not with an absolute floor in response units.
# Standalone: julia --project=. -e 'include("test/test_issue_425_fd_step_scale.jl")'

using HSquared
using Test

@testset "finite-difference steps are response-scale invariant (#425)" begin
    fd_step = 1e-4
    theta = [3e-7, 5e-7, 2e-7]
    h = HSquared._uncertainty_component_steps(theta, fd_step)

    @test h ≈ fd_step .* theta
    @test all(theta .- 2 .* h .> 0)

    scale = 1e6
    @test HSquared._uncertainty_component_steps(scale .* theta, fd_step) ≈ scale .* h

    # A zero covariance coordinate still needs a finite perturbation. Its floor
    # is relative to the other covariance parameters, so it scales with them.
    covariance_theta = [0.3, 0.4, 0.0, 0.5]
    covariance_h = HSquared._uncertainty_component_steps(covariance_theta, fd_step)
    @test covariance_h[3] > 0
    @test HSquared._uncertainty_component_steps(
        scale .* covariance_theta, fd_step,
    ) ≈ scale .* covariance_h

    # A component that is tiny relative to the model scale remains a boundary.
    boundary_theta = [1e-12, 1.0, 1.0]
    boundary_h = HSquared._uncertainty_component_steps(boundary_theta, fd_step)
    @test !all(boundary_theta .- 2 .* boundary_h .> 0)
end
