# Thin-coverage pins for three small exported builders: `diagonal_covariance`,
# `g_max` (via `genetic_pca` / `_check_symmetric_psd_G`) and `legendre_design`.
# Test-only: no src change. Behaviour pinned here is the CURRENT contract.

# Gauss-Legendre nodes/weights from first principles (Golub-Welsch): eigenvalues of
# the Jacobi matrix with off-diagonals n/sqrt(4n^2-1); weights = 2 * (first
# eigenvector component)^2. Exact for polynomial degree <= 2m - 1.
function _gl_nodes_weights(m::Integer)
    off = [n / sqrt(4n^2 - 1) for n in 1:(m - 1)]
    E = eigen(SymTridiagonal(zeros(m), off))
    return E.values, 2 .* E.vectors[1, :] .^ 2
end

# Fixed orthogonal matrix (product of two plane rotations), so fixtures are exact-ish
# and reproducible without an RNG.
function _fixed_orthogonal4()
    function rot(i, j, θ)
        R = Matrix{Float64}(I, 4, 4)
        R[i, i] = cos(θ); R[j, j] = cos(θ)
        R[i, j] = -sin(θ); R[j, i] = sin(θ)
        return R
    end
    return rot(1, 2, 0.6) * rot(2, 3, -0.9) * rot(3, 4, 1.1) * rot(1, 4, 0.3)
end

@testset "g_max / legendre_design / diagonal_covariance builders" begin
    @testset "g_max: repeated leading eigenvalue" begin
        Q = _fixed_orthogonal4()
        # Double leading eigenvalue 3 (eigenspace = span(Q[:,1], Q[:,2])).
        G = Symmetric(Q * Diagonal([3.0, 3.0, 1.0, 0.5]) * Q')
        gm = g_max(G)
        @test gm.eigenvalue ≈ 3.0 atol = 1e-12
        @test norm(gm.eigenvector) ≈ 1.0 atol = 1e-12
        # Element of the leading eigenspace: G v = 3 v, equivalently its projection
        # onto span(Q[:,1:2]) keeps the whole unit norm.
        @test norm(G * gm.eigenvector - 3.0 .* gm.eigenvector) < 1e-10
        @test norm(Q[:, 1:2]' * gm.eigenvector) ≈ 1.0 atol = 1e-10
        @test abs(dot(gm.eigenvector, Q[:, 3])) < 1e-10
        @test abs(dot(gm.eigenvector, Q[:, 4])) < 1e-10
        # Deterministic across repeated calls (bitwise identical), inside the
        # degenerate eigenspace too.
        calls = [g_max(G) for _ in 1:10]
        @test all(c -> c.eigenvector == calls[1].eigenvector, calls)
        @test all(c -> c.eigenvalue == calls[1].eigenvalue, calls)
        # Canonical sign: largest-magnitude entry positive.
        @test gm.eigenvector[argmax(abs.(gm.eigenvector))] > 0

        # Triple leading eigenvalue; scaled identity (every direction is leading).
        G3 = Symmetric(Q * Diagonal([5.0, 5.0, 5.0, 2.0]) * Q')
        gm3 = g_max(G3)
        @test gm3.eigenvalue ≈ 5.0 atol = 1e-12
        @test norm(gm3.eigenvector) ≈ 1.0 atol = 1e-12
        @test abs(dot(gm3.eigenvector, Q[:, 4])) < 1e-10
        gi = g_max(Matrix(2.0I, 3, 3))
        @test gi.eigenvalue ≈ 2.0
        @test norm(gi.eigenvector) ≈ 1.0 atol = 1e-12
        @test all(_ -> g_max(Matrix(2.0I, 3, 3)).eigenvector == gi.eigenvector, 1:10)

        # genetic_pca agrees: values descending, repeated pair reported twice.
        pca = genetic_pca(G)
        @test pca.values ≈ [3.0, 3.0, 1.0, 0.5] atol = 1e-12
        @test pca.vectors[:, 1] == gm.eigenvector
    end

    @testset "g_max: sign canonicalization under orthogonal sign flip" begin
        G = [4.0 1.0 0.5; 1.0 3.0 -0.7; 0.5 -0.7 2.0]   # distinct eigenvalues, no |v_i| ties
        gm = g_max(G)
        for signs in ([1.0, -1.0, 1.0], [-1.0, 1.0, 1.0], [1.0, 1.0, -1.0],
                      [-1.0, -1.0, 1.0], [-1.0, -1.0, -1.0])
            D = Diagonal(signs)                 # orthogonal sign flip
            gf = g_max(D * G * D)
            @test gf.eigenvalue ≈ gm.eigenvalue atol = 1e-12
            # Same axis mapped through the flip (D v), re-canonicalized so the
            # largest-magnitude entry is positive.
            expected = D * gm.eigenvector
            expected[argmax(abs.(expected))] < 0 && (expected = -expected)
            @test abs.(gf.eigenvector) ≈ abs.(gm.eigenvector) atol = 1e-10
            @test gf.eigenvector[argmax(abs.(gf.eigenvector))] > 0
            @test gf.eigenvector ≈ expected atol = 1e-10
        end
        @test g_max(G).eigenvector == gm.eigenvector
    end

    @testset "g_max: 1x1, singular PSD, input types" begin
        g1 = g_max([2.5;;])
        @test g1.eigenvalue == 2.5
        @test g1.eigenvector == [1.0]
        g0 = g_max([0.0;;])                       # admissible zero-variance 1x1 G
        @test g0.eigenvalue == 0.0
        @test norm(g0.eigenvector) ≈ 1.0
        gint = g_max([3 0; 0 1])                  # integer input
        @test gint.eigenvalue ≈ 3.0
        @test gint.eigenvector isa Vector{Float64}
        @test gint.eigenvector ≈ [1.0, 0.0]

        v = [1.0, -2.0, 2.0]
        Gs = v * v'                                # rank-1 PSD (singular)
        gs = g_max(Gs)
        @test gs.eigenvalue ≈ 9.0 atol = 1e-12
        @test norm(gs.eigenvector) ≈ 1.0 atol = 1e-12
        @test abs(dot(gs.eigenvector, v ./ 3)) ≈ 1.0 atol = 1e-12
        @test genetic_pca(Gs).values[2:3] ≈ [0.0, 0.0] atol = 1e-10
        @test all(>=(0), genetic_pca(Gs).values)  # PSD-safe clamp

        # Singular PSD with a zero-variance trait (zero row/column) is admissible.
        Gz = [4.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 0.0]
        gz = g_max(Gz)
        @test gz.eigenvalue ≈ 4.0
        @test gz.eigenvector ≈ [1.0, 0.0, 0.0] atol = 1e-12

        # NamedTuple convenience path.
        @test g_max((genetic_covariance = [4.0 0.0; 0.0 1.0],)).eigenvalue ≈ 4.0
    end

    @testset "g_max / genetic_pca: ArgumentError contract" begin
        for f in (g_max, genetic_pca)
            @test_throws ArgumentError f([1.0 2.0; 3.0 4.0])        # non-symmetric
            @test_throws ArgumentError f([1.0 0.5; 0.0 1.0])        # non-symmetric, PD diagonal
            @test_throws ArgumentError f([-1.0 0.0; 0.0 -2.0])      # negative definite
            @test_throws ArgumentError f([1.0 0.0; 0.0 -1.0])       # indefinite
            @test_throws ArgumentError f([-1.0;;])                  # negative 1x1
            @test_throws ArgumentError f(ones(2, 3))                # non-square
            @test_throws ArgumentError f(zeros(0, 0))               # empty
            @test_throws ArgumentError f([1.0 NaN; NaN 1.0])        # non-finite
            @test_throws ArgumentError f([Inf 0.0; 0.0 1.0])
            @test_throws ArgumentError f([1.0 2.0; 2.0 1.0])        # symmetric, indefinite
            @test_throws ArgumentError f([0.0 1.0; 1.0 0.0])        # zero-variance traits with covariance
        end
        # Exactly singular PSD is admitted; a meaningfully negative eigenvalue
        # (det < 0 here) is refused.
        @test g_max([1.0 1.0; 1.0 1.0]).eigenvalue ≈ 2.0
        @test_throws ArgumentError g_max([1.0 1.0; 1.0 0.9])
    end

    @testset "legendre_design" begin
        ts = [-1.0, -0.5, 0.0, 0.25, 1.0]
        for order in 1:6
            Φ = legendre_design(ts, order)
            @test size(Φ) == (length(ts), order)
            @test Φ isa Matrix{Float64}
            for i in eachindex(ts)
                @test Φ[i, :] == legendre_basis(ts[i], order)   # row i == legendre_basis
            end
        end
        # order = 1: a single constant column sqrt(1/2).
        Φ1 = legendre_design(ts, 1)
        @test size(Φ1) == (5, 1)
        @test all(==(sqrt(0.5)), Φ1[:, 1])
        # Empty covariate vector gives an empty n x order design.
        @test size(legendre_design(Float64[], 3)) == (0, 3)
        # Integer-valued covariates are accepted.
        @test legendre_design([-1, 0, 1], 2) ≈ legendre_design([-1.0, 0.0, 1.0], 2)

        # Guards.
        @test_throws ArgumentError legendre_design([0.0, 1.1], 3)
        @test_throws ArgumentError legendre_design([-1.0001, 0.0], 3)
        @test_throws ArgumentError legendre_design([2.0], 1)
        @test_throws ArgumentError legendre_design([0.0, NaN], 2)
        @test_throws ArgumentError legendre_design([0.0, Inf], 2)
        @test_throws ArgumentError legendre_design([0.0], 0)
        @test_throws ArgumentError legendre_design([0.0], -2)
        @test_throws ArgumentError legendre_basis(1.5, 2)
        @test_throws ArgumentError legendre_basis(0.0, 0)
        # Endpoint roundoff tolerance (1e-10) is accepted and clamped.
        @test legendre_design([1.0 + 1e-11], 3) ≈ legendre_design([1.0], 3)

        # Orthonormality on [-1, 1] under 200-point Gauss-Legendre (exact to degree 399).
        x, w = _gl_nodes_weights(200)
        @test sum(w) ≈ 2.0 atol = 1e-12
        @test sum(w .* x .^ 2) ≈ 2 / 3 atol = 1e-12          # quadrature sanity
        for order in (1, 2, 4, 6, 8)
            Φ = legendre_design(x, order)
            M = Φ' * Diagonal(w) * Φ                           # M[j,k] = ∫ φ_j φ_k
            @test maximum(abs.(M - I)) < 1e-8
        end

        # Independent fine-trapezoid cross-check (looser, different quadrature).
        xt = collect(range(-1.0, 1.0; length = 20001))
        wt = fill(step(range(-1.0, 1.0; length = 20001)), length(xt))
        wt[1] /= 2; wt[end] /= 2
        Φt = legendre_design(xt, 5)
        @test maximum(abs.(Φt' * Diagonal(wt) * Φt - I)) < 1e-6
    end

    @testset "diagonal_covariance" begin
        D = diagonal_covariance([1.0, 2.0, 3.0])
        @test D isa Matrix{Float64}
        @test D == [1.0 0.0 0.0; 0.0 2.0 0.0; 0.0 0.0 3.0]

        # Tuple, range and integer inputs all return a plain Matrix{Float64}.
        for input in ((1.0, 2.0, 3.0), (1, 2, 3), 1:3, [1, 2, 3], Float32[1, 2, 3],
                      [1//1, 2//1, 3//1])
            Di = diagonal_covariance(input)
            @test typeof(Di) === Matrix{Float64}
            @test Di == D
        end
        @test diagonal_covariance([4])[1, 1] === 4.0
        @test typeof(diagonal_covariance([4])) === Matrix{Float64}
        @test size(diagonal_covariance([2.5])) == (1, 1)

        # Not a Diagonal/Symmetric wrapper: off-diagonals are real stored zeros.
        @test !(D isa Diagonal) && !(D isa Symmetric)
        D[1, 2] = 0.5                                        # mutable, independent storage
        @test diagonal_covariance([1.0, 2.0, 3.0])[1, 2] == 0.0

        # Guards.
        @test_throws ArgumentError diagonal_covariance(Float64[])
        @test_throws ArgumentError diagonal_covariance(())
        @test_throws ArgumentError diagonal_covariance(1:0)
        @test_throws ArgumentError diagonal_covariance([1.0, NaN])
        @test_throws ArgumentError diagonal_covariance([Inf, 1.0])
        @test_throws ArgumentError diagonal_covariance([1.0, -Inf])
        @test_throws ArgumentError diagonal_covariance([1.0, -2.0])
        @test_throws ArgumentError diagonal_covariance((1.0, -0.0))
        @test_throws ArgumentError diagonal_covariance(0:2)
        @test_throws ArgumentError diagonal_covariance([-1])
    end
end
