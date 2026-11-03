# HSquared.jl #340 (follow-on to #331) -- characterise the rotational flat
# direction of `:lowrank` / `:factor_analytic` loadings. TEST-ONLY: the
# optimiser still searches the raw loading vector; whether to constrain
# Lambda (e.g. lower-triangular) is an open design decision. These tests pin
# the facts that decision depends on. Standalone:
# julia --project=. -e 'include("test/test_issue_340_lowrank_rotation.jl")'

using HSquared
using LinearAlgebra
using Random
using Test

@testset "issue 340 lowrank rotational indeterminacy" begin
    t, K = 3, 2
    q = 24
    ids = ["a$i" for i in 1:q]
    # six founders, then each animal has two distinct earlier parents
    sire = [i <= 6 ? "0" : "a$(i - 6)" for i in 1:q]
    dam = [i <= 6 ? "0" : "a$(i - 5)" for i in 1:q]
    ped = normalize_pedigree(ids, sire, dam)
    Ainv = pedigree_inverse(ped)
    A = inv(Symmetric(Matrix(Ainv)))

    # Simulate from a rank-2 G with a fixed seed.
    rng = MersenneTwister(340)
    Lambda_true = [1.0 0.0; 0.6 0.8; 0.3 -0.7]
    G_true = Lambda_true * Lambda_true'
    R_true = Diagonal([0.8, 0.9, 1.0])
    CA = cholesky(Symmetric(A)).L
    U = CA * randn(rng, q, K) * Lambda_true'   # q x t, cov = A (x) G
    reps = 2
    rows = repeat(1:q, inner = reps)
    n = length(rows)
    Z = zeros(n, q)
    for (r, i) in enumerate(rows)
        Z[r, i] = 1.0
    end
    X = ones(n, 1)
    Y = U[rows, :] .+ randn(rng, n, t) * sqrt.(R_true)

    yvec, Xfull, Zfull, indiv, N = HSquared._mv_observed(Y, X, Z, n, t, q, 1)
    ngen_raw = t * K
    R0 = Matrix(R_true)
    rparams = HSquared._cov_to_chol_params(R0, t)
    negloglik(L) = HSquared._mv_reml_objective(
        vcat(vec(L), rparams), yvec, Xfull, Zfull, A, indiv, N, t,
        :lowrank, K, ngen_raw)

    @testset "(a) loglik and G invariant under Lambda -> Lambda Q" begin
        L0 = [0.9 0.1; 0.5 0.7; 0.4 -0.5]
        base = negloglik(L0)
        @test isfinite(base)
        Grot = HSquared.lowrank_covariance(L0)
        qrng = MersenneTwister(1)
        nonflat = 0
        for _ in 1:5
            Q = Matrix(qr(randn(qrng, K, K)).Q)
            @test Q' * Q ≈ I atol = 1e-12
            LQ = L0 * Q
            if maximum(abs, LQ - L0) > 1e-3
                nonflat += 1
            end
            @test abs(negloglik(LQ) - base) < 1e-10
            @test maximum(abs, HSquared.lowrank_covariance(LQ) - Grot) < 1e-10
        end
        @test nonflat >= 3   # the rotations genuinely move the raw loadings
    end

    @testset "(b) fitted G and loglik agree across starts; raw loadings differ" begin
        starts = [
            [0.9 0.1; 0.5 0.7; 0.4 -0.5],
            [0.1 0.9; 0.7 -0.5; -0.5 0.4],
            [0.7 0.7; -0.6 0.5; 0.2 0.6],
        ]
        fits = [fit_multivariate_reml(Y, X, Z, Ainv; genetic_structure = :lowrank, rank = K,
                                      initial = (loadings = L0, R0 = R0), iterations = 4000)
                for L0 in starts]
        @test all(f -> isfinite(f.loglik), fits)
        ll = [f.loglik for f in fits]
        relG = maximum(norm(f.genetic_covariance - fits[1].genetic_covariance) /
                       norm(fits[1].genetic_covariance) for f in fits)
        relLL = (maximum(ll) - minimum(ll)) / abs(maximum(ll))
        @info "issue 340 (b) observed" converged = [f.converged for f in fits] relG relLL
        @test relLL < 1e-4
        @test relG < 1e-3   # observed ~5e-5; Nelder-Mead tolerance, loosened for cross-version margin
        relL = maximum(norm(f.genetic_loadings - fits[1].genetic_loadings) for f in fits[2:end])
        @test relL > 1e-3   # raw loadings differ: the flat direction is present
    end

    @testset "(c) covariance_structure_lrt df uses _mv_nparams" begin
        for (s, r, extra) in ((:lowrank, 2, 0), (:factor_analytic, 1, t), (:factor_analytic, 2, t))
            by_hand_g = t * r - r * (r - 1) ÷ 2 + extra
            fake = (genetic_covariance = Matrix{Float64}(I, t, t), genetic_structure = s,
                    genetic_rank = r, loglik = -100.0, converged = true)
            full = (genetic_covariance = Matrix{Float64}(I, t, t), genetic_structure = :unstructured,
                    genetic_rank = 0, loglik = -95.0, converged = true)
            if by_hand_g < t * (t + 1) ÷ 2
                lrt = covariance_structure_lrt(fake, full)
                @test lrt.df == t * (t + 1) ÷ 2 - by_hand_g
                @test lrt.df == HSquared._mv_nparams(full) - HSquared._mv_nparams(fake)
            else
                @test_throws ArgumentError covariance_structure_lrt(fake, full)
            end
            @test HSquared._mv_nparams(fake) == by_hand_g + t * (t + 1) ÷ 2
        end
    end

    @testset "(d) optimiser vector length vs _mv_nparams (pinned discrepancy)" begin
        L0 = [0.9 0.1; 0.5 0.7; 0.4 -0.5]
        for (s, extra) in ((:lowrank, 0), (:factor_analytic, t))
            ngen = t * K + extra
            optimiser_len = ngen + t * (t + 1) ÷ 2
            fake = (genetic_covariance = Matrix{Float64}(I, t, t), genetic_structure = s,
                    genetic_rank = K, loglik = -1.0, converged = true)
            nominal = HSquared._mv_nparams(fake)
            # observed (t = 3, K = 2, R0 term of 6 included): lowrank 12 vs 11,
            # factor_analytic 15 vs 14
            @test optimiser_len == (s == :lowrank ? 12 : 15)
            @test nominal == (s == :lowrank ? 11 : 14)
            @test optimiser_len - nominal == K * (K - 1) ÷ 2
        end
        # the objective rejects a vector of the nominal (reduced) length
        @test_throws DimensionMismatch HSquared._mv_reml_objective(
            zeros(11), yvec, Xfull, Zfull, A, indiv, N, t, :lowrank, K, ngen_raw)
    end
end
