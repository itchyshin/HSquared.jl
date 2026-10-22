# Option / field / guard coverage for genetic_gllvm_gaussian_mme (#50 slice 2).
# Test-only: pins current behaviour of the supplied-covariance Gaussian latent solve.

@testset "genetic_gllvm_gaussian_mme options, fields and guards (#50)" begin
    ped_ids = [1, 2, 3, 4]
    Ainv = pedigree_inverse(ped_ids, [0, 0, 1, 1], [0, 0, 2, 2])
    n = 4; t = 2
    Z = Matrix(1.0I, n, n)
    X = ones(n, 1)
    Y = [10.0 50.0; 12.0 47.0; 9.0 53.0; 11.0 49.0]
    R0 = [2.0 0.3; 0.3 1.0]
    Λ1 = reshape([0.8, 0.5], 2, 1)
    Ψ = [0.3, 0.5]
    Λ2 = [1.2 0.2; 0.3 1.1]
    solve(args...; kw...) = genetic_gllvm_gaussian_mme(Y, X, Z, Ainv, args...; kw...)

    @testset "returned fields and shapes" begin
        g = solve(Λ1, R0; uniqueness = Ψ)
        G = factor_analytic_covariance(Λ1, Ψ)
        @test g.n_latent_factors == size(Λ1, 2) == 1
        @test size(g.beta) == (1, t)
        @test size(g.breeding_values.values) == (n, t)
        @test size(g.genetic_covariance) == (t, t)
        @test size(g.residual_covariance) == (t, t)
        @test size(g.genetic_correlation) == (t, t)
        @test size(g.residual_correlation) == (t, t)
        @test g.residual_covariance ≈ R0
        @test g.genetic_correlation ≈ G ./ sqrt.(diag(G) * diag(G)')
        @test g.residual_correlation ≈ R0 ./ sqrt.(diag(R0) * diag(R0)')
        @test g.traits == [1, 2]
        @test g.breeding_values.traits == g.traits
        ls = g.latent_structure
        @test ls.genetic_covariance ≈ G
        @test ls.n_latent_factors == ls.rank == 1
        @test size(ls.genetic_correlation) == (t, t)
        @test length(ls.communality) == t
        @test length(ls.genetic_variances) == t
    end

    @testset "communality" begin
        g = solve(Λ1, R0; uniqueness = Ψ)
        G = factor_analytic_covariance(Λ1, Ψ)
        @test g.latent_structure.communality ≈ (diag(G) .- Ψ) ./ diag(G)
        @test all(0 .< g.latent_structure.communality .< 1)
        # no uniqueness and K >= T: the latent part is the whole genetic variance
        g2 = solve(Λ2, R0)
        @test g2.latent_structure.communality ≈ ones(t)
        @test g2.n_latent_factors == 2
    end

    @testset "ids keyword" begin
        g0 = solve(Λ2, R0)
        @test g0.breeding_values.ids == [1, 2, 3, 4]
        lab = ["a", "b", "c", "d"]
        gl = solve(Λ2, R0; ids = lab)
        @test gl.breeding_values.ids == lab
        @test gl.breeding_values.values ≈ g0.breeding_values.values
        @test gl.beta ≈ g0.beta
        @test_throws ArgumentError solve(Λ2, R0; ids = ["a", "b", "c"])        # wrong length
        @test_throws ArgumentError solve(Λ2, R0; ids = ["a", "b", "c", "c"])   # duplicates
        @test_throws ArgumentError solve(Λ2, R0; ids = ["a", "b", "c", " "])   # empty label
    end

    @testset "uniqueness guards" begin
        @test_throws ArgumentError solve(Λ1, R0; uniqueness = [0.0, 0.5])
        @test_throws ArgumentError solve(Λ1, R0; uniqueness = [0.3, -0.5])
        @test_throws ArgumentError solve(Λ1, R0; uniqueness = [0.3, NaN])
        @test_throws ArgumentError solve(Λ1, R0; uniqueness = [0.3])           # too short
        @test_throws Exception solve(Λ1, R0; uniqueness = [0.3, missing])      # missing entry
    end

    @testset "R0 guards" begin
        @test_throws ArgumentError solve(Λ2, [1.0 2.0; 2.0 1.0])               # not PD
        @test_throws ArgumentError solve(Λ2, [2.0 0.3; 0.9 1.0])               # not symmetric
        @test_throws ArgumentError solve(Λ2, [2.0 0.3; 0.3 NaN])
        @test_throws ArgumentError solve(Λ2, Matrix(1.0I, 3, 3))               # wrong size
    end

    @testset "dimension mismatches and non-finite loadings" begin
        @test_throws ArgumentError solve(ones(3, 2), R0)                       # loadings rows != Y columns
        @test_throws ArgumentError solve(reshape([1.0, 1.0, 1.0], 3, 1), R0; uniqueness = [0.1, 0.1, 0.1])
        @test_throws ArgumentError genetic_gllvm_gaussian_mme(Y, X, ones(n, 3), Ainv, Λ2, R0)       # Z cols != Ainv
        @test_throws ArgumentError genetic_gllvm_gaussian_mme(Y, ones(n - 1, 1), Z, Ainv, Λ2, R0)   # X rows != Y rows
        @test_throws ArgumentError genetic_gllvm_gaussian_mme(Y, X, Z[1:3, :], Ainv, Λ2, R0)        # Z rows != Y rows
        @test_throws ArgumentError solve([NaN 0.2; 0.3 1.1], R0)
        @test_throws ArgumentError solve([Inf 0.2; 0.3 1.1], R0)
        @test_throws ArgumentError solve(Λ2, R0; uniqueness = [0.3, 0.5, 0.1])  # Ψ longer than T
    end

    @testset "column sign flip leaves the solve unchanged" begin
        base = solve(Λ2, R0)
        flipped = solve(Λ2 * Diagonal([1.0, -1.0]), R0)
        @test flipped.genetic_covariance ≈ base.genetic_covariance
        @test flipped.beta ≈ base.beta
        @test flipped.breeding_values.values ≈ base.breeding_values.values
        @test flipped.latent_structure.communality ≈ base.latent_structure.communality
        fa = solve(Λ1, R0; uniqueness = Ψ)
        fa_flip = solve(-Λ1, R0; uniqueness = Ψ)
        @test fa_flip.genetic_covariance ≈ fa.genetic_covariance
        @test fa_flip.beta ≈ fa.beta
        @test fa_flip.breeding_values.values ≈ fa.breeding_values.values
    end
end
