using Test
using HSquared

@testset "sweep dense-cell guard and damped variational Newton" begin
    Y = [1.0 2.0; 3.0 4.0]
    X = ones(2, 1)
    Z = [1.0 0.0; 0.0 1.0]
    Ainv = [1.0 0.0; 0.0 1.0]

    @testset "multivariate dense fitters honour max_dense_cells" begin
        for fitter in (fit_multivariate_reml, fit_multivariate_repeatability_reml)
            err = try
                fitter(Y, X, Z, Ainv; max_dense_cells = 1)
                nothing
            catch e
                e
            end
            @test err isa ArgumentError
            @test occursin("max_dense_cells", sprint(showerror, err))
            @test occursin("dense covariance/relationship cells", sprint(showerror, err))
        end
    end

    @testset "variational Newton step backtracks from a zero start" begin
        # Mean count 150 from a zero start. An undamped Newton step on the
        # log link overshoots, then walks back by about one unit per
        # iteration, so 30 iterations cannot reach the mode. The damped
        # step does. This is the reproduction sketched on HSquared.jl#442.
        y = [150.0]
        X1 = ones(1, 1)
        Z1 = ones(1, 1)
        Ai = ones(1, 1)
        fit = HSquared.variational_marginal_loglik(
            y, X1, Z1, Ai, 1.0, HSquared.PoissonResponse(); maxiter = 30,
        )
        @test fit.converged
        @test isfinite(fit.elbo)
        @test isfinite(fit.beta[1])
    end
end
