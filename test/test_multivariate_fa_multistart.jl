using HSquared
using LinearAlgebra
using Random
using Statistics
using Test

function fa_multistart_fixture(seed)
    rng = MersenneTwister(seed)
    ids = collect(1:12)
    sire = [0, 0, 0, 0, 1, 1, 2, 3, 5, 5, 6, 7]
    dam = [0, 0, 0, 0, 2, 3, 3, 4, 6, 7, 8, 9]
    ped = normalize_pedigree(ids, sire, dam)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    Λ = reshape([1.0, 0.8, 0.65, 0.5], 4, 1)
    ψ = [0.35, 0.4, 0.5, 0.45]
    G = Matrix(factor_analytic_covariance(Λ, ψ))
    R = [1.0 0.12 0.0 0.0; 0.12 0.9 0.08 0.0; 0.0 0.08 0.85 0.07; 0.0 0.0 0.07 0.8]
    U = cholesky(Symmetric(A)).L * randn(rng, 12, 4) * transpose(cholesky(Symmetric(G)).L)
    LR = cholesky(Symmetric(R)).L
    Y = Matrix{Float64}(undef, 24, 4)
    Z = zeros(24, 12)
    row = 0
    for animal in 1:12, _ in 1:2
        row += 1
        Z[row, animal] = 1.0
        Y[row, :] .= [0.3, -0.4, 0.5, 1.0] .+ U[animal, :] .+
                     (transpose(randn(rng, 4)) * transpose(LR))[:]
    end
    return (; Y, X = ones(24, 1), Z, Ainv, ids, G, R)
end

include(joinpath(@__DIR__, "test_fa_likelihood_information.jl"))

@testset "multivariate start selection respects convergence" begin
    mixed = [(; objective = 4.0, converged = true, valid = true),
             (; objective = 3.0, converged = false, valid = true)]
    @test HSquared._select_multivariate_fit_attempt(mixed) == 1

    all_unconverged = [(; objective = 4.0, converged = false, valid = true),
                       (; objective = 3.0, converged = false, valid = true)]
    @test HSquared._select_multivariate_fit_attempt(all_unconverged) == 2

    invalid = [(; objective = 1.0, converged = true, valid = false),
               (; objective = 5.0, converged = false, valid = true)]
    @test HSquared._select_multivariate_fit_attempt(invalid) == 2
    @test_throws ArgumentError HSquared._select_multivariate_fit_attempt(
        [(; objective = Inf, converged = true, valid = false)])
end

@testset "FA optimizer maps overflow proposals to an invalid objective" begin
    Y = [0.0 0.4; 1.0 -0.3]
    X = ones(2, 1)
    Z = Matrix{Float64}(I, 2, 2)
    A = Matrix{Float64}(I, 2, 2)
    yvec, Xfull, Zfull, indiv, N = HSquared._mv_observed(Y, X, Z, 2, 2, 2, 1)
    Rparams = HSquared._cov_to_chol_params(Matrix{Float64}(I, 2, 2), 2)
    params = vcat([0.4, -0.6], log.([0.5, 0.7]), Rparams)
    objective = p -> HSquared._mv_reml_objective(
        p, yvec, Xfull, Zfull, A, indiv, N, 2, :factor_analytic, 1, 4)

    @test isfinite(objective(params))
    overflow = copy(params)
    overflow[3] = 1000.0
    @test_throws ArgumentError HSquared._structured_genetic_params_to_cov(
        overflow[1:4], 2, :factor_analytic, 1)
    @test objective(overflow) == Inf
    @test_throws DimensionMismatch objective(params[1:end-1])
    @test_throws DimensionMismatch HSquared._mv_reml_objective(
        params, yvec, Xfull, Zfull, Matrix{Float64}(I, 3, 3), indiv, N,
        2, :factor_analytic, 1, 4)
    residual_overflow = copy(params)
    residual_overflow[end] = 1000.0
    @test !all(isfinite, HSquared._chol_params_to_cov(residual_overflow[5:end], 2))
    @test objective(residual_overflow) == Inf
    residual_underflow = copy(params)
    residual_underflow[5] = -1000.0
    residual_underflow[7] = -1000.0
    collapsed_R0 = HSquared._chol_params_to_cov(residual_underflow[5:end], 2)
    @test iszero(collapsed_R0[1, 1])
    @test iszero(collapsed_R0[2, 2])
    @test !isposdef(Symmetric(collapsed_R0))
    @test objective(residual_underflow) == Inf
    @test HSquared._mv_reml_objective(
        params, fill(NaN, length(yvec)), Xfull, Zfull, A, indiv, N,
        2, :factor_analytic, 1, 4) == Inf
end

@testset "multivariate REML rejects rank-deficient fixed effects" begin
    Y = [0.0 0.4; 1.0 -0.3; 0.5 0.8; -0.6 0.2]
    x = ones(4, 1)
    X = hcat(x, x)
    Z = Matrix{Float64}(I, 4, 4)
    Ainv = Matrix{Float64}(I, 4, 4)
    err = try
        fit_multivariate_reml(Y, X, Z, Ainv;
            genetic_structure = :factor_analytic, rank = 1, iterations = 5)
        nothing
    catch e
        e
    end
    @test err isa ArgumentError
    @test occursin("full column rank", sprint(showerror, err))
end

@testset "FA uses deterministic starts and reports fit limits" begin
    d = fa_multistart_fixture(20260927)
    phen = [var(d.Y[:, k]) for k in 1:4]
    balanced = (
        loadings = reshape(0.5 .* sqrt.(phen), 4, 1),
        uniqueness = 0.5 .* phen,
        R0 = Matrix(Diagonal(0.5 .* phen)),
    )
    common = (; genetic_structure = :factor_analytic, rank = 1, iterations = 10_000,
              ids = d.ids, traits = ["t1", "t2", "t3", "t4"])

    # An empty NamedTuple requests the historical deterministic default as a
    # single user-specified start, without activating automatic multistart.
    default = fit_multivariate_reml(d.Y, d.X, d.Z, d.Ainv;
        common..., initial = NamedTuple())
    alternative = fit_multivariate_reml(d.Y, d.X, d.Z, d.Ainv;
        common..., initial = balanced)
    automatic = fit_multivariate_reml(d.Y, d.X, d.Z, d.Ainv; common...)

    converged_candidates = filter(x -> x.converged, (default, alternative))
    eligible = isempty(converged_candidates) ? (default, alternative) : converged_candidates
    expected = eligible[argmax([x.loglik for x in eligible])]
    @test automatic.loglik ≈ expected.loglik
    @test automatic.genetic_covariance ≈ expected.genetic_covariance
    @test automatic.residual_covariance ≈ expected.residual_covariance
    @test automatic.converged == expected.converged
    @test automatic.iterations == expected.iterations
    @test hasproperty(automatic, :fa_start_diagnostics)
    if hasproperty(automatic, :fa_start_diagnostics)
        diag = automatic.fa_start_diagnostics
        @test diag.strategy == :default_and_balanced
        @test diag.starts_attempted == 2
        @test length(diag.starts) == 2
        @test all(s.valid for s in diag.starts)
        @test diag.selected_start in (:default, :balanced)
        @test diag.g_relative_disagreement > 0.1
        @test diag.r_relative_disagreement > 0.05
        @test diag.objective_range ≈ abs(default.loglik - alternative.loglik)
        @test !diag.better_nonconverged_start
        @test diag.near_uniqueness_floor
        selected = only(filter(s -> s.name == diag.selected_start, diag.starts))
        @test automatic.converged == selected.converged
        @test automatic.iterations == selected.iterations
    end

    # The expected information is evaluated at the returned covariance too.
    # Full natural-coordinate rank does not remove the near-floor constraint
    # concern or certify regular inference.
    A = Matrix(inv(Symmetric(Matrix(d.Ainv))))
    fitted_information = _fa_expected_reml_information(
        A, d.Z, automatic.genetic_loadings, automatic.genetic_uniqueness,
        automatic.residual_covariance)
    fitted_spectrum = eigvals(fitted_information)
    @test all(isfinite, fitted_spectrum)
    @test count(>(1e-8 * maximum(fitted_spectrum)), fitted_spectrum) == 18
    @test automatic.fa_start_diagnostics.near_uniqueness_floor

    bounded = fit_multivariate_reml(d.Y, d.X, d.Z, d.Ainv;
        genetic_structure = :factor_analytic, rank = 1, iterations = 1,
        initial = balanced)
    @test !bounded.converged
    @test bounded.fa_start_diagnostics.starts_attempted == 1
    @test bounded.fa_start_diagnostics.selected_start == :user

    d2 = fa_multistart_fixture(20260928)
    mixed_status = fit_multivariate_reml(d2.Y, d2.X, d2.Z, d2.Ainv; common...)
    @test mixed_status.converged
    @test any(!s.converged for s in mixed_status.fa_start_diagnostics.starts)
    chosen = only(filter(s -> s.name == mixed_status.fa_start_diagnostics.selected_start,
                         mixed_status.fa_start_diagnostics.starts))
    @test mixed_status.converged == chosen.converged
    @test mixed_status.loglik ≈ chosen.loglik
end

@testset "Gaussian FA fit transforms with trait units away from the floor" begin
    rng = MersenneTwister(20260929)
    n, records, t = 40, 5, 4
    ids = collect(1:n)
    ped = normalize_pedigree(ids, zeros(Int, n), zeros(Int, n))
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    loadings = reshape([1.4, 0.9, 0.7, 0.5], t, 1)
    uniqueness = [0.8, 0.7, 0.9, 0.8]
    G = Matrix(factor_analytic_covariance(loadings, uniqueness))
    R = [1.0 0.12 0.0 0.0; 0.12 0.9 0.08 0.0; 0.0 0.08 0.85 0.07; 0.0 0.0 0.07 0.8]
    U = cholesky(Symmetric(A)).L * randn(rng, n, t) * transpose(cholesky(Symmetric(G)).L)
    LR = cholesky(Symmetric(R)).L
    N = n * records
    Y = Matrix{Float64}(undef, N, t)
    Z = zeros(N, n)
    row = 0
    for animal in 1:n, _ in 1:records
        row += 1
        Z[row, animal] = 1.0
        Y[row, :] .= [0.3, -0.4, 0.5, 1.0] .+ U[animal, :] .+
                     (transpose(randn(rng, t)) * transpose(LR))[:]
    end
    X = ones(N, 1)
    initial = (; loadings, uniqueness, R0 = R)
    common = (; genetic_structure = :factor_analytic, rank = 1,
              iterations = 10_000, ids, traits = ["t1", "t2", "t3", "t4"])
    original = fit_multivariate_reml(Y, X, Z, Ainv; common..., initial)

    scales = [2.0, 0.5, 1.5, 0.8]
    D = Diagonal(scales)
    scaled_initial = (; loadings = D * loadings,
                      uniqueness = scales .^ 2 .* uniqueness,
                      R0 = D * R * D)
    scaled = fit_multivariate_reml(Y * D, X, Z, Ainv;
        common..., initial = scaled_initial)

    # Fixed-covariance REML is an independent exact unit-change check.
    direct = HSquared._multivariate_reml_loglik(Y, X, Z, Ainv, G, R)
    direct_scaled = HSquared._multivariate_reml_loglik(
        Y * D, X, Z, Ainv, D * G * D, D * R * D)
    @test direct_scaled ≈ direct - (N - size(X, 2)) * sum(log, scales) atol = 1e-8

    @test original.converged && scaled.converged
    @test minimum(original.genetic_uniqueness) > 0.01
    @test minimum(scaled.genetic_uniqueness) > 0.01
    @test scaled.genetic_covariance ≈ D * original.genetic_covariance * D rtol = 2e-3
    @test scaled.residual_covariance ≈ D * original.residual_covariance * D rtol = 2e-3
    @test scaled.genetic_uniqueness ≈ scales .^ 2 .* original.genetic_uniqueness rtol = 2e-3
    @test scaled.loglik ≈ original.loglik - (N - size(X, 2)) * sum(log, scales) atol = 2e-3

    permutation = [3, 1, 4, 2]
    permuted_initial = (; loadings = loadings[permutation, :],
                        uniqueness = uniqueness[permutation],
                        R0 = R[permutation, permutation])
    permuted_common = merge(common, (; traits = common.traits[permutation]))
    permuted = fit_multivariate_reml(Y[:, permutation], X, Z, Ainv;
        permuted_common..., initial = permuted_initial)

    @test permuted.converged == original.converged
    @test permuted.traits == original.traits[permutation]
    @test permuted.loglik ≈ original.loglik atol = 2e-3
    @test permuted.genetic_covariance ≈ original.genetic_covariance[permutation, permutation] rtol = 2e-3
    @test permuted.residual_covariance ≈ original.residual_covariance[permutation, permutation] rtol = 2e-3
    @test permuted.genetic_uniqueness ≈ original.genetic_uniqueness[permutation] rtol = 2e-3
    @test permuted.heritability ≈ original.heritability[permutation] rtol = 2e-3
    @test permuted.beta ≈ original.beta[:, permutation] rtol = 2e-3 atol = 1e-5
    @test permuted.breeding_values.ids == original.breeding_values.ids
    @test permuted.breeding_values.traits == original.breeding_values.traits[permutation]
    @test permuted.breeding_values.values ≈ original.breeding_values.values[:, permutation] rtol = 2e-3 atol = 1e-5
end
