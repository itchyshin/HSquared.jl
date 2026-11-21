using HSquared
using LinearAlgebra
using Random
using Statistics
using Test

# Twin AE design (400 pairs, MZ block relationship 1, DZ 0.5; 1e-6 ridge makes
# the MZ blocks invertible), the shape of the mets::twinbmi case in #504.
function _issue_504_twin_spec(seed)
    rng = MersenneTwister(seed)
    npairs = 400
    n = 2npairs
    A = zeros(n, n)
    y = zeros(n)
    for p in 1:npairs
        r = 2p - 1
        rho = p <= 200 ? 1.0 : 0.5
        A[r, r] = A[r + 1, r + 1] = 1.0
        A[r, r + 1] = A[r + 1, r] = rho
        g1 = sqrt(0.0108) * randn(rng)
        g2 = rho * g1 + sqrt(0.0108 * (1 - rho^2)) * randn(rng)
        y[r] = 3.2 + g1 + sqrt(0.0054) * randn(rng)
        y[r + 1] = 3.2 + g2 + sqrt(0.0054) * randn(rng)
    end
    age = randn(rng, n)
    sex = Float64.(rand(rng, Bool, n))
    X = [ones(n) age sex]
    y .+= 0.01 .* age
    Ainv = inv(A + 1e-6I)
    return animal_model_spec(y, X, Matrix{Float64}(I, n, n), Ainv; method = :REML), var(y)
end

# Regression: the converged flag must not depend on the start when every start
# reaches the same interior REML point (HSquared.jl #504).
@testset "issue 504: fit_ai_reml converged is start-independent" begin
    spec, vy = _issue_504_twin_spec(504)
    starts = [(sigma_a2 = a * vy, sigma_e2 = (1 - a) * vy) for a in (0.5, 0.2, 0.8, 0.35, 0.65)]
    fits = [fit_ai_reml(spec; initial = st) for st in starts]
    @test all(f -> abs(f.likelihood.loglik - fits[1].likelihood.loglik) < 1e-6, fits)
    @test all(f -> isapprox(f.variance_components.sigma_a2, fits[1].variance_components.sigma_a2; rtol = 1e-4), fits)
    @test all(f -> f.converged && f.optimizer_status == "converged", fits)
end
