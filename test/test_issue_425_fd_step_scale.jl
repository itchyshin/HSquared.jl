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

@testset "multivariate log-Cholesky steps are response-scale invariant (#425)" begin
    fd_step = 1e-4
    t = 2
    G = [3e-7 1e-7; 1e-7 5e-7]
    R = [2e-7 0.0; 0.0 4e-7]
    theta = vcat(HSquared._cov_to_chol_params(G, t), HSquared._cov_to_chol_params(R, t))
    h = HSquared._mv_logchol_component_steps(theta, t, fd_step)

    # Off-diagonal G is a raw Cholesky entry in sqrt(variance) units. The old
    # absolute h = 1e-4 was a third of this coordinate; the relative step is not.
    @test h[2] ≈ fd_step * abs(theta[2])
    @test h[2] < 1e-4

    # Log-diagonal steps stay fd_step: d log L = dL / L is already unit-free.
    @test h[1] ≈ fd_step
    @test h[3] ≈ fd_step

    # A zero residual covariance still needs a finite L-scale floor.
    @test h[5] > 0

    scale = 1e6
    theta_s = vcat(
        HSquared._cov_to_chol_params(scale .* G, t),
        HSquared._cov_to_chol_params(scale .* R, t),
    )
    h_s = HSquared._mv_logchol_component_steps(theta_s, t, fd_step)
    @test h_s[2] ≈ sqrt(scale) * h[2]
    @test h_s[5] ≈ sqrt(scale) * h[5]
    @test h_s[1] ≈ h[1]
    @test h_s[3] ≈ h[3]

    @test HSquared._fd_hessian(z -> -sum(abs2, z) / 2, [1.0, 2.0]; h = [1e-4, 2e-4]) ≈
        [-1.0 0.0; 0.0 -1.0] atol = 1e-7
end
