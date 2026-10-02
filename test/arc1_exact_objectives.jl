using LinearAlgebra
using Random
using Test
using HSquared

# This milestone is intentionally loaded directly until the parent integrates
# it into HSquared.jl and the package test runner.
Base.include(HSquared, joinpath(@__DIR__, "..", "src", "arc1_fa.jl"))

function _arc1_test_case(; correlated_residual = true)
    rng = MersenneTwister(41027)
    n, p, t = 6, 2, 4
    F = [1.0 0.0; 0.2 0.7; -0.4 0.5; 1.1 -0.3; -0.8 0.4; 0.6 1.2]
    B = F * transpose(F) + Diagonal([0.15, 0.35, 0.1, 0.25, 0.4, 0.2])
    X = hcat(ones(n), [-0.9, -0.4, 0.1, 0.35, 0.8, 1.2])
    λ = [-0.48, 0.32, -0.21, 0.57]
    ψ = [0.31, 0.43, 0.28, 0.52]
    G = λ * transpose(λ) + Diagonal(ψ)
    R = correlated_residual ?
        [0.82 0.11 -0.03 0.02; 0.11 0.91 0.08 -0.04;
         -0.03 0.08 0.75 0.1; 0.02 -0.04 0.1 0.88] :
        Matrix(Diagonal([0.82, 0.91, 0.75, 0.88]))
    μ = X * [0.7 -0.3 0.2 1.1; -0.25 0.4 0.65 -0.5]
    V = kron(B, G) + kron(Matrix{Float64}(I, n, n), R)
    Y = μ + reshape(cholesky(Symmetric(V)).L * randn(rng, n * t), t, n)'
    (; Y, X, B, G, R, λ)
end

function _arc1_test_chol_params(R)
    L = Matrix(cholesky(Symmetric(R)).L)
    out = Float64[]
    for j in axes(L, 2), i in j:size(L, 1)
        push!(out, i == j ? log(L[i, j]) : L[i, j])
    end
    out
end

function _arc1_test_params(k, λ, ψ, R)
    genetic = k == 0 ? log.(ψ .- HSquared.FA_UNIQUENESS_FLOOR) :
              vcat(λ, log.(ψ .- HSquared.FA_UNIQUENESS_FLOOR))
    vcat(genetic, _arc1_test_chol_params(R))
end

# Independent dense oracle in trait-major order: vec(Y), G⊗B + R⊗I,
# and I₄⊗X. It uses dense GLS and never calls the spectral or model helpers.
function _arc1_test_dense_oracle(Y, X, B, G, R)
    n, t = size(Y)
    y = vec(Y)
    V = kron(G, B) + kron(R, Matrix{Float64}(I, n, n))
    Xfull = kron(Matrix{Float64}(I, t, t), X)
    F = cholesky(Symmetric(V); check = true)
    ViX = F \ Xfull
    C = cholesky(Symmetric(transpose(Xfull) * ViX); check = true)
    β = C \ (transpose(Xfull) * (F \ y))
    e = y - Xfull * β
    ll = -0.5 * ((length(y) - size(Xfull, 2)) * log(2π) +
                 logdet(F) + logdet(C) + dot(e, F \ e))
    (; loglik = ll, beta = β)
end

function _arc1_test_central_gradient(f, x, h)
    g = similar(x)
    for j in eachindex(x)
        xp, xm = copy(x), copy(x)
        xp[j] += h
        xm[j] -= h
        g[j] = (f(xp) - f(xm)) / (2h)
    end
    g
end

@testset "ARC1 exact FA spectral objectives and analytic gradients" begin
    @testset "raw REML identity against independent dense trait-major GLS" begin
        d = _arc1_test_case()
        for k in 0:1, correlated in (false, true)
            case = correlated ? d : _arc1_test_case(correlated_residual = false)
            ψ = [0.31, 0.43, 0.28, 0.52]
            λ = case.λ
            G = k == 0 ? Matrix(Diagonal(ψ)) : λ * transpose(λ) + Diagonal(ψ)
            params = _arc1_test_params(k, λ, ψ, case.R)
            out = HSquared._arc1_fa_exact_objective_gradient(
                params, case.Y, case.X, case.B, k)
            oracle = _arc1_test_dense_oracle(case.Y, case.X, case.B, G, case.R)
            @test out.status == :ok
            @test out.loglik ≈ oracle.loglik atol = 1e-8 rtol = 0
            @test out.raw_objective ≈ -oracle.loglik atol = 1e-8 rtol = 0
            @test out.objective ≈ -oracle.loglik / (4size(case.Y, 1) - 4size(case.X, 2)) atol = 1e-8 rtol = 0
            n = size(case.Y, 1)
            Z = Matrix{Float64}(I, n, n)
            yrec, Xrec, Zrec, indiv, N = HSquared._mv_observed(
                case.Y, case.X, Z, n, 4, n, size(case.X, 2))
            core_ll = HSquared._mv_reml_loglik_core(
                yrec, Xrec, Zrec, case.B, indiv, N, G, case.R)
            core_beta, _ = HSquared._mv_gls_blup(
                yrec, Xrec, Zrec, case.B, indiv, N, G, case.R,
                4, size(case.X, 2), n)
            @test out.loglik ≈ core_ll atol = 1e-8 rtol = 0
            @test out.fixed_effects ≈ core_beta atol = 1e-8 rtol = 0
            @test out.fixed_effects ≈ reshape(oracle.beta, size(case.X, 2), 4) atol = 1e-8 rtol = 0
        end
    end

    @testset "every analytic score component matches step-swept differences" begin
        d = _arc1_test_case()
        for k in 0:1, correlated in (false, true), near_floor in (false, true)
            case = correlated ? d : _arc1_test_case(correlated_residual = false)
            ψ = near_floor ? [HSquared.FA_UNIQUENESS_FLOOR + 2e-4,
                             0.43, 0.28, 0.52] : [0.31, 0.43, 0.28, 0.52]
            λ = k == 1 ? [-0.48, 0.32, -0.21, 0.57] : [0.0, 0.0, 0.0, 0.0]
            p = _arc1_test_params(k, λ, ψ, case.R)
            out = HSquared._arc1_fa_exact_objective_gradient(
                p, case.Y, case.X, case.B, k)
            f = x -> HSquared._arc1_fa_exact_objective_gradient(
                x, case.Y, case.X, case.B, k).objective
            for h in (2e-4, 5e-5, 1e-5)
                gfd = _arc1_test_central_gradient(f, p, h)
                @test out.gradient ≈ gfd atol = 2e-6 rtol = 2e-5
            end
        end
    end

    @testset "raw negative loading, K1 zero-loading boundary, and basis invariance" begin
        d = _arc1_test_case()
        ψ0 = [0.31, 0.43, 0.28, 0.52]
        rpar = _arc1_test_chol_params(d.R)
        p0 = vcat(log.(ψ0 .- HSquared.FA_UNIQUENESS_FLOOR), rpar)
        p1 = vcat(zeros(4), log.(ψ0 .- HSquared.FA_UNIQUENESS_FLOOR), rpar)
        o0 = HSquared._arc1_fa_exact_objective_gradient(p0, d.Y, d.X, d.B, 0)
        o1 = HSquared._arc1_fa_exact_objective_gradient(p1, d.Y, d.X, d.B, 1)
        @test o1.objective ≈ o0.objective atol = 1e-10 rtol = 0
        @test o1.gradient[1:4] ≈ zeros(4) atol = 1e-10 rtol = 0

        # The ordinary fixture's largest absolute loading pivot is positive.
        # Pair it with its exact sign reversal to exercise the raw-parameter
        # derivative through the sign-canonicalization branch used elsewhere.
        λplus = d.λ
        λminus = -d.λ
        pplus = _arc1_test_params(1, λplus, ψ0, d.R)
        pminus = _arc1_test_params(1, λminus, ψ0, d.R)
        plus = HSquared._arc1_fa_exact_objective_gradient(
            pplus, d.Y, d.X, d.B, 1)
        minus = HSquared._arc1_fa_exact_objective_gradient(
            pminus, d.Y, d.X, d.B, 1)
        @test plus.objective ≈ minus.objective atol = 1e-12 rtol = 0
        @test minus.gradient[1:4] ≈ -plus.gradient[1:4] atol = 1e-11 rtol = 0
        @test minus.gradient[5:end] ≈ plus.gradient[5:end] atol = 1e-11 rtol = 0
        fminus = x -> HSquared._arc1_fa_exact_objective_gradient(
            x, d.Y, d.X, d.B, 1).objective
        for h in (2e-4, 5e-5, 1e-5)
            @test minus.gradient ≈ _arc1_test_central_gradient(fminus, pminus, h) atol = 2e-6 rtol = 2e-5
        end

        k = 1
        p = _arc1_test_params(k, d.λ, ψ0, d.R)
        dB = eigen(Symmetric(d.B))
        base = HSquared._arc1_fa_exact_from_eigen(p, d.Y, d.X,
                                                   dB.values, dB.vectors, k)
        n = size(d.B, 1)
        perm = reverse(1:n)
        signs = Diagonal([isodd(i) ? -1.0 : 1.0 for i in 1:n])
        U1 = dB.vectors[:, perm] * signs
        alt1 = HSquared._arc1_fa_exact_from_eigen(
            p, d.Y, d.X, dB.values[perm], U1, k)
        @test alt1.objective ≈ base.objective atol = 1e-10 rtol = 0
        @test alt1.gradient ≈ base.gradient atol = 1e-9 rtol = 0

        # Replace B by one with an exactly repeated eigenspace and rotate only
        # within that space. The decomposition represents the same covariance.
        U = Matrix(qr(randn(MersenneTwister(722), n, n)).Q)
        vals = [0.4, 0.4, 0.8, 1.1, 1.6, 2.0]
        B = U * Diagonal(vals) * transpose(U)
        repeated = eigen(Symmetric(B))
        θ = 0.37
        Q2 = [cos(θ) -sin(θ); sin(θ) cos(θ)]
        Urot = copy(repeated.vectors)
        Urot[:, 1:2] = Urot[:, 1:2] * Q2
        a = HSquared._arc1_fa_exact_from_eigen(p, d.Y, d.X,
                                               repeated.values, repeated.vectors, k)
        b = HSquared._arc1_fa_exact_from_eigen(p, d.Y, d.X,
                                               repeated.values, Urot, k)
        @test b.objective ≈ a.objective atol = 1e-9 rtol = 0
        @test b.gradient ≈ a.gradient atol = 1e-8 rtol = 0
    end

    @testset "invalid covariance proposals fail closed" begin
        d = _arc1_test_case()
        p = _arc1_test_params(1, d.λ, [0.31, 0.43, 0.28, 0.52], d.R)
        valid = HSquared._arc1_fa_exact_objective_gradient(p, d.Y, d.X, d.B, 1)
        @test valid.status == :ok
        @test HSquared._arc1_fa_exact_objective_gradient(
            p[1:end-1], d.Y, d.X, d.B, 1).status == :invalid_proposal
        pnan = copy(p); pnan[1] = NaN
        @test HSquared._arc1_fa_exact_objective_gradient(
            pnan, d.Y, d.X, d.B, 1).status == :invalid_proposal
        psing = copy(p); psing[end-9] = -1000.0
        @test HSquared._arc1_fa_exact_objective_gradient(
            psing, d.Y, d.X, d.B, 1).status == :invalid_proposal
        Bindef = copy(d.B); Bindef[1, 1] -= 100.0
        @test HSquared._arc1_fa_exact_objective_gradient(
            p, d.Y, d.X, Bindef, 1).status == :invalid_proposal
        Xsing = hcat(d.X[:, 1], d.X[:, 1])
        @test HSquared._arc1_fa_exact_objective_gradient(
            p, d.Y, Xsing, d.B, 1).status == :invalid_proposal
    end
end

println("ARC1_OBJECTIVES_PASS")
