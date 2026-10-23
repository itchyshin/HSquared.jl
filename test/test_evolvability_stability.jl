@testset "G-metric conditioning and extreme scales" begin
    θ = 0.371
    Q = [cos(θ) -sin(θ); sin(θ) cos(θ)]
    Gill = Q * Diagonal([1.0, 1e-14]) * Q'
    βill = Q[:, 2]

    # Inverse metrics reject matrices whose condition makes their Float64
    # directional summaries numerically unreliable.
    @test_throws ArgumentError conditional_evolvability(Gill, βill)
    @test_throws ArgumentError autonomy(Gill, βill)

    Gbase = [4.0 1.0; 1.0 3.0]
    βref = [2.0, 1.0]
    for βextreme in ([1.7e308, 8.5e307], [1e-320, 5e-321])
        @test evolvability(Gbase, βextreme) ≈ evolvability(Gbase, βref) rtol = 1e-12
        @test respondability(Gbase, βextreme) ≈ respondability(Gbase, βref) rtol = 1e-12
        @test conditional_evolvability(Gbase, βextreme) ≈ conditional_evolvability(Gbase, βref) rtol = 1e-12
        @test autonomy(Gbase, βextreme) ≈ autonomy(Gbase, βref) rtol = 1e-12
    end

    β = [1.0, 2.0]
    cbase = conditional_evolvability(Gbase, β)
    abase = autonomy(Gbase, β)
    for scale in (1e-250, 1e300)
        Gscaled = scale .* Gbase
        @test conditional_evolvability(Gscaled, β) / scale ≈ cbase rtol = 1e-12
        @test autonomy(Gscaled, β) ≈ abase rtol = 1e-12
    end

    # These results are representable even though summing the raw diagonal or
    # eigenvalues first would overflow.
    Glarge = Matrix(Diagonal([1.5e308, 1.5e308]))
    @test isfinite(mean_evolvability(Glarge))
    @test mean_evolvability(Glarge) ≈ 1.5e308 rtol = 1e-12

    Gplot = Matrix(Diagonal([9e307, 9e307]))
    @test genetic_pca_plot_data(Gplot).variance_explained ≈ [0.5, 0.5]

    # Reject a finite covariance whose leading eigenvalue is not representable.
    Goverflow = fill(1.7e308, 2, 2)
    @test_throws ArgumentError genetic_pca(Goverflow)
end
