using LinearAlgebra
using HSquared
using Test

# Standalone scratch execution sets this path to the frozen repository helper.
# Once integrated beside the helper, no environment override is needed. The
# helper is already loaded when this file follows the existing FA test path.
if !isdefined(@__MODULE__, :_fa_expected_reml_information)
    include(get(ENV, "HSQUARED_FA_INFORMATION_HELPER",
                joinpath(@__DIR__, "test_fa_likelihood_information.jl")))
end

function _fa_weak_direction_scales(loadings, uniqueness)
    d = diag(Matrix(factor_analytic_covariance(loadings, uniqueness)))
    return vcat(sqrt.(d), d,
                [sqrt(d[i] * d[j]) for j in 1:4 for i in 1:j])
end

function _fa_standardized_direction(loadings, uniqueness, direction)
    w = direction ./ _fa_weak_direction_scales(loadings, uniqueness)
    return w / norm(w)
end

@testset "T4 K1 FA expected information detects a weak natural direction" begin
    ped = normalize_pedigree(collect(1:12),
        [0, 0, 0, 0, 1, 1, 2, 3, 5, 5, 6, 7],
        [0, 0, 0, 0, 2, 3, 3, 4, 6, 7, 8, 9])
    A = Matrix(inv(Symmetric(Matrix(pedigree_inverse(ped)))))
    Z = zeros(24, 12)
    for animal in 1:12, record in (2animal - 1):(2animal)
        Z[record, animal] = 1.0
    end
    psi = [0.35, 0.4, 0.5, 0.45]
    R = [1.0 0.12 0.0 0.0; 0.12 0.9 0.08 0.0;
         0.0 0.08 0.85 0.07; 0.0 0.0 0.07 0.8]

    # Coordinate order: lambda[1:4], psi[1:4], upper vech(R)[1:10].
    # At lambda=(1,1,0,0), d(lambda*lambda') cancels diag(dpsi).
    direction = vcat([1.0, -1.0, 0.0, 0.0], [-2.0, 2.0, 0.0, 0.0], zeros(10))
    lambda0 = reshape([1.0, 1.0, 0.0, 0.0], 4, 1)
    info0 = _fa_expected_reml_information(A, Z, lambda0, psi, R)
    spectrum0 = eigvals(info0)
    maxeig0 = maximum(spectrum0)
    w0 = _fa_standardized_direction(lambda0, psi, direction)
    null_residual = norm(info0 * w0) / opnorm(info0)
    @test length(spectrum0) == 18
    @test all(isfinite, spectrum0)
    @test minimum(spectrum0) >= -1e-10 * maxeig0
    @test count(>(1e-8 * maxeig0), spectrum0) == 17
    @test null_residual <= 1e-8

    # Scientific negative control: an incorrect cancellation must be detected.
    # A conventional green suite asserts rejection of this deliberately wrong
    # direction, so the suite does not ship an intentional failing assertion.
    wrong_direction = copy(direction)
    wrong_direction[5] = -1.0
    wrong_w = _fa_standardized_direction(lambda0, psi, wrong_direction)
    wrong_null_residual = norm(info0 * wrong_w) / opnorm(info0)
    @test wrong_null_residual > 1e-8
    @test wrong_null_residual > 100 * max(null_residual, eps(Float64))

    trait_scales = [2.0, 0.5, 1.5, 0.8]
    D = Diagonal(trait_scales)
    permutation = [3, 1, 4, 2]
    quadratics = Dict{Float64, Float64}()
    for epsilon in (0.0, 0.01, 0.001)
        lambda = reshape([1.0, 1.0, epsilon, epsilon], 4, 1)
        info = _fa_expected_reml_information(A, Z, lambda, psi, R)
        spectrum = eigvals(info)
        w = _fa_standardized_direction(lambda, psi, direction)
        quadratic = dot(w, info * w)
        quadratics[epsilon] = quadratic
        @test all(isfinite, spectrum)
        @test minimum(spectrum) >= -1e-10 * maximum(spectrum)
        if epsilon > 0
            @test isfinite(quadratic) && quadratic > 0
        end

        # Positive unit changes map natural directions as well as covariances.
        scaled_lambda = D * lambda
        scaled_psi = trait_scales .^ 2 .* psi
        scaled_direction = vcat(trait_scales .* direction[1:4],
                                trait_scales .^ 2 .* direction[5:8], zeros(10))
        scaled_info = _fa_expected_reml_information(
            A, Z, scaled_lambda, scaled_psi, D * R * D)
        scaled_w = _fa_standardized_direction(scaled_lambda, scaled_psi, scaled_direction)
        @test eigvals(scaled_info) ≈ spectrum rtol = 1e-7 atol = 1e-10 * maximum(spectrum)
        @test scaled_w ≈ w rtol = 1e-12 atol = 1e-12
        # The absolute tolerance handles the exact-null case. Positive weak
        # directions receive a relative comparison below as a stronger check.
        @test dot(scaled_w, scaled_info * scaled_w) ≈ quadratic rtol = 1e-7 atol = 1e-10 * maximum(spectrum)

        permuted_lambda = lambda[permutation, :]
        permuted_psi = psi[permutation]
        permuted_direction = vcat(direction[permutation], direction[4 .+ permutation], zeros(10))
        permuted_info = _fa_expected_reml_information(
            A, Z, permuted_lambda, permuted_psi, R[permutation, permutation])
        permuted_w = _fa_standardized_direction(permuted_lambda, permuted_psi, permuted_direction)
        @test eigvals(permuted_info) ≈ spectrum rtol = 1e-7 atol = 1e-10 * maximum(spectrum)
        @test dot(permuted_w, permuted_info * permuted_w) ≈ quadratic rtol = 1e-7 atol = 1e-10 * maximum(spectrum)
        if epsilon > 0
            @test dot(scaled_w, scaled_info * scaled_w) ≈ quadratic rtol = 1e-7 atol = 0
            @test dot(permuted_w, permuted_info * permuted_w) ≈ quadratic rtol = 1e-7 atol = 0
        end
        @info "FA weak-direction diagnostic" epsilon rank=count(>(1e-8 * maximum(spectrum)), spectrum) eigen_ratio=minimum(spectrum)/maximum(spectrum) directional_information=quadratic
    end

    # The covariance derivative is O(epsilon), hence information is O(epsilon^2).
    # Allow a tenfold decrease; exact factor 100 is not required at finite epsilon.
    @test quadratics[0.001] < quadratics[0.01] / 10
    # Negative control: reversing the perturbation must fail the same oracle.
    @test !(quadratics[0.01] < quadratics[0.001] / 10)
    @info "FA weak-direction control diagnostics" null_residual wrong_null_residual contraction_ratio=quadratics[0.001]/quadratics[0.01]
end
