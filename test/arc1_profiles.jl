using Test, HSquared, LinearAlgebra, SparseArrays

# The production module include is owned by the integration lane. This test is
# therefore runnable against the frozen source without changing src/HSquared.jl.
const ARC1_SOURCE = joinpath(@__DIR__, "..", "src", "arc1_profiles.jl")
if !isfile(ARC1_SOURCE)
    @testset "Arc1 profile source is present" begin
        @test isfile(ARC1_SOURCE)
    end
else
    isdefined(HSquared, :_arc1_profile_context) || Base.include(HSquared, ARC1_SOURCE)
const H = HSquared

function _arc1_test_data()
    na = 6
    n = 2na
    z = sparse(1:n, repeat(1:na, inner = 2), ones(n), n, na)
    A = Matrix{Float64}(I, na, na)
    for i in 2:na
        A[i, i - 1] = A[i - 1, i] = 0.16
    end
    Ainv = inv(A)
    X = hcat(ones(n), collect(range(-1.0, 1.0; length = n)))
    y = [0.4 + 0.2 * i + 0.1 * sin(1.7i) + 0.3 * (-1)^i for i in 1:n]
    return y, X, z, Ainv, A
end

function _arc1_dense_reml_oracle(y, X, Z, A, Va, Vpe, Ve)
    V = Va .* (Z * A * Z') + Vpe .* (Z * Z') + Ve .* Matrix{Float64}(I, length(y), length(y))
    F = cholesky(Symmetric(Matrix(V)); check = true)
    ViX = F \ X
    Viy = F \ y
    C = Symmetric(X' * ViX)
    FC = cholesky(C; check = true)
    beta = FC \ (X' * Viy)
    residual = y - X * beta
    q = dot(residual, F \ residual)
    logdet_v = 2sum(log, diag(F.L))
    logdet_c = 2sum(log, diag(FC.L))
    n, p = length(y), size(X, 2)
    return -0.5 * (logdet_v + logdet_c + q)
end

@testset "Arc1 repeatability profile exact objective" begin
    y, X, Z, Ainv, A = _arc1_test_data()
    context = H._arc1_profile_context(y, X, Z, Ainv)

    @testset "positive components agree with independent dense REML oracle" begin
        for (Va, Vpe, Ve) in ((0.3, 0.2, 0.5), (1.1, 0.05, 0.7))
            got = H._arc1_profile_reml(context, Va, Vpe, Ve)
            expected = _arc1_dense_reml_oracle(y, X, Z, A, Va, Vpe, Ve)
            @test got.status == :ok
            @test got.loglik ≈ expected atol = 1e-10
            @test got.loglik_convention == :reml_omit_2pi
            @test !got.loglik_comparable_across_routes
        end
    end

    @testset "exact additive and permanent zero faces remain evaluable" begin
        for (Va, Vpe, Ve) in ((0.0, 0.4, 0.6), (0.3, 0.0, 0.7), (0.0, 0.0, 1.0))
            got = H._arc1_profile_reml(context, Va, Vpe, Ve)
            expected = _arc1_dense_reml_oracle(y, X, Z, A, Va, Vpe, Ve)
            @test got.status == :ok
            @test got.loglik ≈ expected atol = 1e-10
        end
    end

    @testset "unphenotyped ancestors retain full-pedigree covariance marginal" begin
        n_animal, n_observed = 8, 6
        A_full = Matrix{Float64}(I, n_animal, n_animal) .+ 0.08
        A_observed = A_full[3:end, 3:end]
        n = 2n_observed
        Xfull = hcat(ones(n), collect(range(-1.0, 1.0; length = n)))
        yfull = [0.2 * i + 0.15 * cos(0.9i) for i in 1:n]
        observed_index = repeat(3:n_animal, inner = 2)
        Zfull = sparse(1:n, observed_index, ones(n), n, n_animal)
        Zobserved = sparse(1:n, repeat(1:n_observed, inner = 2), ones(n), n, n_observed)
        full_context = try
            H._arc1_profile_context(yfull, Xfull, Zfull, inv(A_full))
        catch
            nothing
        end
        @test full_context !== nothing
        if full_context !== nothing
            observed_context = H._arc1_profile_context(
                yfull, Xfull, Zobserved, inv(A_observed))
            full_fit = H._arc1_profile_reml(full_context, 0.3, 0.2, 0.5)
            observed_fit = H._arc1_profile_reml(observed_context, 0.3, 0.2, 0.5)
            @test full_fit.status == observed_fit.status == :ok
            @test full_fit.loglik ≈ observed_fit.loglik atol = 1e-10
        end
    end

    @testset "zero residual variance reports a singular proposal" begin
        got = H._arc1_profile_reml(context, 0.3, 0.2, 0.0)
        @test got.status == :singular_proposal
        @test !isfinite(got.loglik)
    end

    @testset "analytic total-scale profile and ratio parameterizations" begin
        proportions = (0.3, 0.2, 0.5)
        scale = H._arc1_profile_scale(context, proportions)
        V0 = proportions[1] .* (Z * A * Z') + proportions[2] .* (Z * Z') +
             proportions[3] .* Matrix{Float64}(I, length(y), length(y))
        F0 = cholesky(Symmetric(Matrix(V0)); check = true)
        ViX0, Viy0 = F0 \ X, F0 \ y
        P_y = Viy0 - ViX0 * ((X' * ViX0) \ (X' * Viy0))
        @test scale ≈ dot(y, P_y) / (length(y) - size(X, 2)) rtol = 1e-10
        h = H._arc1_components_at_ratio(:heritability, 0.25, 1.7, 0.4)
        t = H._arc1_components_at_ratio(:repeatability, 0.65, 1.7, 0.3)
        @test h == (sigma_a2 = 1.7 * 0.25,
                    sigma_pe2 = 1.7 * 0.75 * 0.4,
                    sigma_e2 = 1.7 * 0.75 * 0.6)
        @test t == (sigma_a2 = 1.7 * 0.65 * 0.3,
                    sigma_pe2 = 1.7 * 0.65 * 0.7,
                    sigma_e2 = 1.7 * 0.35)
        @test h.sigma_a2 / sum(values(h)) ≈ 0.25
        @test (t.sigma_a2 + t.sigma_pe2) / sum(values(t)) ≈ 0.65
    end

    @testset "profile likelihood is stable to large fixed-effect shifts" begin
        proportions = (0.3, 0.2, 0.5)
        shift = X * [1.0e7, -2.0e7]
        shifted_y = y + shift
        base_fit = H._arc1_profile_reml(context, proportions...)
        shifted_context = H._arc1_profile_context(shifted_y, X, Z, Ainv)
        shifted_fit = H._arc1_profile_reml(shifted_context, proportions...)
        base_scale = H._arc1_profile_scale(context, proportions)
        shifted_scale = H._arc1_profile_scale(shifted_context, proportions)
        base_components = H._arc1_components_at_ratio(:heritability, 0.25, base_scale, 0.4)
        shifted_components = H._arc1_components_at_ratio(:heritability, 0.25, shifted_scale, 0.4)

        @test shifted_fit.loglik ≈ base_fit.loglik atol = 1e-6
        @test shifted_scale ≈ base_scale atol = 1e-7
        @test shifted_components.sigma_a2 ≈ base_components.sigma_a2 atol = 1e-7
        @test shifted_components.sigma_pe2 ≈ base_components.sigma_pe2 atol = 1e-7
        @test shifted_components.sigma_e2 ≈ base_components.sigma_e2 atol = 1e-7
    end
end
end
