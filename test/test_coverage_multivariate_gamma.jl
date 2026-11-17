# HJ1 — multivariate.jl incomplete-gamma and chi-square tail branches.

using HSquared
using Test

@testset "multivariate gamma/chisq helpers (HJ1)" begin
    H = HSquared
    @testset "_reg_gamma_p_series vs _reg_gamma_q_cf" begin
        a, x_small = 0.5, 0.2
        p = H._reg_gamma_p_series(a, x_small)
        @test 0 < p < 1
        a2, x_large = 3.0, 10.0
        q = H._reg_gamma_q_cf(a2, x_large)
        @test 0 < q < 1
        @test p + H._reg_gamma_q_cf(a, x_small) ≈ 1.0 rtol = 1e-6
    end

    @testset "_chisq_sf endpoint branches" begin
        @test H._chisq_sf(0.0, 2.0) == 1.0
        @test H._chisq_sf(Inf, 2.0) == 0.0
        @test H._chisq_sf(3.0, 2.0) ≈ exp(-1.5) atol = 1e-12
        small = H._chisq_sf(0.5, 10.0)
        large = H._chisq_sf(25.0, 10.0)
        @test small > large > 0
        @test_throws ArgumentError H._chisq_sf(1.0, 0.0)
        @test_throws ArgumentError H._chisq_sf(NaN, 2.0)
    end
end
