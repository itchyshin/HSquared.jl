using HSquared
using LinearAlgebra
using Random
using Test

# Independent balanced-data Gaussian REML oracle. The cell (animal i, trait j)
# occupies row (i-1)T+j, so traits vary fastest. Neither the marginal covariance
# nor the REML projection uses HSquared's internal builders.
function _fa_independent_dense_reml(Y, X, A, G, R)
    n, T = size(Y)
    p = size(X, 2)
    order = [i + (j - 1) * n for i in 1:n for j in 1:T]
    y = vec(Y)[order]
    D = zeros(n * T, p * T)
    V = zeros(n * T, n * T)
    for i in 1:n, j in 1:T
        row = (i - 1) * T + j
        for c in 1:p
            D[row, (c - 1) * T + j] = X[i, c]
        end
        for k in 1:n, l in 1:T
            col = (k - 1) * T + l
            V[row, col] = A[i, k] * G[j, l] + (i == k ? R[j, l] : 0.0)
        end
    end

    F = cholesky(Symmetric(V))
    yw = F.L \ y
    Dw = F.L \ D
    C = cholesky(Symmetric(transpose(Dw) * Dw))
    beta = C \ (transpose(Dw) * yw)
    rw = yw - Dw * beta
    logdet_V = 2sum(log, diag(F.L))
    logdet_DtViD = 2sum(log, diag(C.L))
    loglik = -0.5 * ((length(y) - size(D, 2)) * log(2π) +
                     logdet_V + logdet_DtViD + dot(rw, rw))
    return (loglik = loglik, y = y, V = V)
end

@testset "Independent dense T=4 K=1 FA REML oracle" begin
    # Four-animal pedigree: founders 1,2; 3=(1,2); 4=(1,3).
    # The 1.25 diagonal for animal 4 includes its inbreeding coefficient.
    A = [1.0 0.0 0.5 0.75;
         0.0 1.0 0.5 0.25;
         0.5 0.5 1.0 0.75;
         0.75 0.25 0.75 1.25]
    Ainv = inv(Symmetric(A))
    X = ones(4, 1)
    Z = Matrix{Float64}(I, 4, 4)
    λ = [0.9, -0.5, 0.7, 0.4]
    ψ = [0.35, 0.55, 0.45, 0.65]
    G = λ * transpose(λ) + Diagonal(ψ)
    R = [0.9 0.12 0.04 -0.03;
         0.12 1.1 -0.07 0.08;
         0.04 -0.07 0.8 0.11;
         -0.03 0.08 0.11 1.2]

    rng = MersenneTwister(20260927)
    U = cholesky(Symmetric(A)).L * randn(rng, 4, 4) *
        transpose(cholesky(Symmetric(Matrix(G))).L)
    E = randn(rng, 4, 4) * transpose(cholesky(Symmetric(R)).L)
    Y = repeat(reshape([1.0, 2.0, -0.5, 0.8], 1, 4), 4, 1) + U + E

    reference = _fa_independent_dense_reml(Y, X, A, G, R)
    @test reference.y[1:4] == vec(Y[1, :])
    @test reference.y[5:8] == vec(Y[2, :])
    @test reference.V[1, 6] ≈ A[1, 2] * G[1, 2] atol = 1e-12
    @test reference.V[1, 2] ≈ A[1, 1] * G[1, 2] + R[1, 2] atol = 1e-12
    observed = HSquared._multivariate_reml_loglik(Y, X, Z, Ainv, G, R)
    @test isapprox(observed, reference.loglik; rtol = 1e-10, atol = 1e-10)

    λ2 = [0.4, -0.8, 0.3, 1.0]
    ψ2 = [0.7, 0.3, 0.8, 0.4]
    G2 = λ2 * transpose(λ2) + Diagonal(ψ2)
    R2 = R + 0.2I
    reference2 = _fa_independent_dense_reml(Y, X, A, G2, R2)
    observed2 = HSquared._multivariate_reml_loglik(Y, X, Z, Ainv, G2, R2)
    @test abs(reference2.loglik - reference.loglik) > 1e-3
    @test isapprox(observed2, reference2.loglik; rtol = 1e-10, atol = 1e-10)
end
