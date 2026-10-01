using LinearAlgebra
using HSquared
using Test

function _fa_expected_reml_information(A, Z, loadings, uniqueness, R)
    n, q = size(Z)
    t = length(uniqueness)
    G = Matrix(factor_analytic_covariance(loadings, uniqueness))
    K = Z * A * transpose(Z)
    V = kron(K, G) + kron(Matrix{Float64}(I, n, n), R)
    Xfull = zeros(n * t, t)
    for record in 1:n, trait in 1:t
        Xfull[(record - 1) * t + trait, trait] = 1.0
    end
    Vi = inv(Symmetric(V))
    XtViX = transpose(Xfull) * Vi * Xfull
    P = Vi - Vi * Xfull * (XtViX \ (transpose(Xfull) * Vi))

    derivatives = Matrix{Float64}[]
    λ = vec(loadings)
    for k in eachindex(λ)
        e = zeros(t)
        e[k] = 1.0
        dG = e * transpose(λ) + λ * transpose(e)
        push!(derivatives, kron(K, dG))
    end
    for k in 1:t
        dG = zeros(t, t)
        dG[k, k] = 1.0
        push!(derivatives, kron(K, dG))
    end
    for j in 1:t, i in 1:j
        dR = zeros(t, t)
        dR[i, j] = 1.0
        dR[j, i] = 1.0
        push!(derivatives, kron(Matrix{Float64}(I, n, n), dR))
    end

    info = zeros(length(derivatives), length(derivatives))
    for a in eachindex(derivatives), b in 1:a
        value = 0.5 * tr(P * derivatives[a] * P * derivatives[b])
        info[a, b] = info[b, a] = value
    end
    gdiag = diag(G)
    scales = vcat(sqrt.(gdiag), gdiag,
                  [sqrt(gdiag[i] * gdiag[j]) for j in 1:t for i in 1:j])
    scale_matrix = Diagonal(scales)
    return Symmetric(scale_matrix * info * scale_matrix)
end

@testset "FA fitted likelihood separates G and R only when the design permits" begin
    ids = collect(1:12)
    ped = normalize_pedigree(ids,
        [0, 0, 0, 0, 1, 1, 2, 3, 5, 5, 6, 7],
        [0, 0, 0, 0, 2, 3, 3, 4, 6, 7, 8, 9])
    A = Matrix(inv(Symmetric(Matrix(pedigree_inverse(ped)))))
    Z = zeros(24, 12)
    for animal in 1:12, record in (2animal - 1):(2animal)
        Z[record, animal] = 1.0
    end
    λ = reshape([1.0, 0.8, 0.65, 0.5], 4, 1)
    ψ = [0.35, 0.4, 0.5, 0.45]
    R = [1.0 0.12 0.0 0.0; 0.12 0.9 0.08 0.0;
         0.0 0.08 0.85 0.07; 0.0 0.0 0.07 0.8]
    repeated = _fa_expected_reml_information(A, Z, λ, ψ, R)
    repeated_values = eigvals(repeated)
    @test length(repeated_values) == 18
    @test minimum(repeated_values) / maximum(repeated_values) > 1e-8

    trait_scales = [2.0, 0.5, 1.5, 0.8]
    D = Diagonal(trait_scales)
    scaled = _fa_expected_reml_information(
        A, Z, D * λ, trait_scales .^ 2 .* ψ, D * R * D)
    @test eigvals(scaled) ≈ repeated_values rtol = 1e-7

    # With one record per unrelated animal, intercept projection leaves an
    # identity relationship operator. G and R then enter only through G + R.
    n, t = 8, 4
    unrelated_A = Matrix{Float64}(I, n, n)
    one_record_Z = Matrix{Float64}(I, n, n)
    collapsed = _fa_expected_reml_information(
        unrelated_A, one_record_Z, λ, ψ, R)
    collapsed_values = eigvals(collapsed)
    @test count(>(1e-8 * maximum(collapsed_values)), collapsed_values) == 10
end
