using Test, HSquared, LinearAlgebra

# #410: multivariate_covariance_standard_errors must invert Ainv once, not once
# per finite-difference evaluation, and keep the SEs bit-identical.
@testset "issue 410: multivariate SE hoists dense A" begin
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = pedigree_inverse(ped)
    y1 = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    y2 = [2.2, 2.8, 3.1, 3.0, 3.6, 2.1, 2.7, 4.1]
    reps = 3
    rows = reduce(vcat, [fill(i, reps) for i in 1:8])
    Z = zeros(length(rows), 8); for (k, i) in enumerate(rows); Z[k, i] = 1.0; end
    X = ones(length(rows), 1)
    off1 = [0.0, 0.3, -0.3]; off2 = [0.2, -0.2, 0.0]
    Y = hcat([y1[i] + off1[r] for i in 1:8 for r in 1:reps],
             [y2[i] + off2[r] for i in 1:8 for r in 1:reps])
    fit = fit_multivariate_reml(Y, X, Z, Ainv)
    @test fit.converged

    # Oracle: the pre-fix closure, which rebuilds A on every evaluation.
    t = 2; ng = t * (t + 1) ÷ 2
    G0 = Matrix(Float64.(Matrix(fit.genetic_covariance)))
    R0 = Matrix(Float64.(Matrix(fit.residual_covariance)))
    phat = vcat(HSquared._cov_to_chol_params(G0, t), HSquared._cov_to_chol_params(R0, t))
    old_loglik(θ) = HSquared._multivariate_reml_loglik(Y, X, Z, Ainv,
        HSquared._chol_params_to_cov(@view(θ[1:ng]), t),
        HSquared._chol_params_to_cov(@view(θ[ng + 1:end]), t))
    hs = HSquared._mv_logchol_component_steps(phat, t, 1e-4)
    HSquared._MV_DENSE_A_CALLS[] = 0
    H_old = -HSquared._fd_hessian(old_loglik, phat; h = hs)
    @test HSquared._MV_DENSE_A_CALLS[] == 2 * length(phat)^2 + 1 == 73
    Hsym_old = Symmetric((H_old + transpose(H_old)) / 2)
    J = HSquared._fd_jacobian(θ -> HSquared._mv_quantities(θ, t, ng), phat; h = hs)
    se_old = sqrt.(max.(diag(J * inv(Hsym_old) * transpose(J)), 0.0))

    HSquared._MV_DENSE_A_CALLS[] = 0
    se = multivariate_covariance_standard_errors(fit, Y, X, Z, Ainv)
    @test HSquared._MV_DENSE_A_CALLS[] == 1

    @test se.information == Matrix(Hsym_old)
    @test se.genetic_covariance[1, 1] == se_old[1]
    @test se.genetic_covariance[2, 1] == se_old[2]
    @test se.genetic_covariance[2, 2] == se_old[3]
    @test se.residual_covariance[1, 1] == se_old[4]
    @test se.residual_covariance[2, 2] == se_old[6]
    @test se.genetic_correlation[2, 1] == se_old[7]
    @test se.heritability == se_old[9:10]
end
