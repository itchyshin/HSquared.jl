using Test, HSquared, LinearAlgebra
const H = HSquared
function fixture(family; va=1.0, ve=1.0, shape=2.0, cuts=[-1.0,1.0], nt=nothing, beta=[0.0], converged=true)
    vc = family === :gaussian ? (sigma_a2=va,sigma_e2=ve) : family === :gamma ?
        (sigma_a2=va,shape=shape) : family === :ordered_probit ?
        (sigma_a2=va,cutpoints=cuts) : (sigma_a2=va,)
    H.NonGaussianFit(vc,-1.0,beta,zeros(2),[1,2],converged,family,:laplace,nt,nothing,false,nothing)
end
@testset "H2 descriptor contract" begin
    @testset "Gaussian conditional and ordinary controls" begin
        h=H.nongaussian_heritability(1.0,0.0,H.GaussianResponse(1.0))
        @test h.h2_latent == h.h2_observation == .5
        @test h.latent_total_variance == 2.0
        @test_throws ArgumentError H.nongaussian_heritability(1.0,0.0,H.GaussianResponse(1.0);predictor_variance=8.0)
        @test_throws ArgumentError H.nongaussian_heritability(fixture(:gaussian);predictor_variance=8.0)
        @test_throws ArgumentError H.nongaussian_heritability(1.0,0.0,H.GaussianResponse(1.0);predictor_variance=big"1e-400")
        @test_throws ArgumentError H.nongaussian_heritability(fixture(:gaussian);predictor_variance=big"1e-400")
        @test H.nongaussian_heritability(2.0,0.0,H.GaussianResponse(3.0)).h2_observation == .4
        @test H.nongaussian_heritability(1.0,20.0,H.GaussianResponse(1.0)).h2_observation == .5
    end
    @testset "Original and converted domains" begin
        bad=(-.5,big"-1e-400",NaN,Inf,-Inf,big"1e400")
        for x in bad
            @test_throws ArgumentError H.nongaussian_heritability(x,0.0,H.PoissonResponse())
            @test_throws ArgumentError H.nongaussian_heritability(fixture(:poisson;va=x))
            @test_throws ArgumentError H.nongaussian_heritability(1.0,0.0,H.PoissonResponse();predictor_variance=x)
            @test_throws ArgumentError H.nongaussian_heritability(fixture(:poisson);predictor_variance=x)
        end
        for x in (NaN,Inf,-Inf,big"1e400")
            @test_throws ArgumentError H.nongaussian_heritability(1.0,x,H.PoissonResponse())
            @test_throws ArgumentError H.nongaussian_heritability(fixture(:poisson);mu=x)
        end
        @test_throws ArgumentError H.nongaussian_heritability(fixture(:poisson;beta=[Inf]))
        @test_throws ArgumentError H.nongaussian_heritability(floatmax(Float64),0.0,H.PoissonResponse();predictor_variance=floatmax(Float64))
        @test_throws ArgumentError H.nongaussian_heritability(fixture(:gaussian;va=floatmax(Float64),ve=floatmax(Float64)))
        @test isfinite(H.nongaussian_heritability(floatmax(Float64),0.0,H.GaussianResponse(1.0)).h2_latent)
        @test H.nongaussian_heritability(big"1e-400",0.0,H.GaussianResponse(1.0)).h2_observation == 0.0
        for field in (0.0,-1.0,Inf,NaN,big"1e400",big"1e-400")
            @test_throws ArgumentError H.nongaussian_heritability(fixture(:gaussian;ve=field))
            @test_throws ArgumentError H.nongaussian_heritability(fixture(:gamma;shape=field))
        end
        for cuts in (Float64[],[NaN],[Inf],[1.0,1.0],[1.0,-1.0],[big"1e400"],[big"1.0",big"1.000000000000000000000000000000000000000000001"])
            @test_throws ArgumentError H.nongaussian_heritability(fixture(:ordered_probit;cuts=cuts))
        end
    end
    @testset "Common trial normalization and varying fence" begin
        scalar=H.nongaussian_heritability(fixture(:binomial;nt=5))
        vector=H.nongaussian_heritability(fixture(:binomial;nt=[5,5]))
        @test scalar.h2_observation ≈ .5040211874317815 atol=1e-14
        @test vector == scalar
        @test H.nongaussian_heritability(fixture(:binomial;nt=[2,3]);n_trials=[5,5]) == scalar
        @test H.nongaussian_heritability(fixture(:binomial;nt=[5,5]);n_trials=5.0) == scalar
        @test H.nongaussian_heritability(fixture(:binomial;nt=[1,1])) == H.nongaussian_heritability(fixture(:binomial;nt=1))
        @test H.nongaussian_heritability(fixture(:binomial;nt=[typemax(Int),typemax(Int)])) == H.nongaussian_heritability(fixture(:binomial;nt=typemax(Int)))
        varying=H.nongaussian_heritability(fixture(:binomial;nt=[5,6]))
        @test isfinite(varying.h2_latent) && isnan(varying.h2_observation)
        @test occursin("varying",varying.caveat)
        for nt in (Int[],[0,0],[-1,2],[1.5,2.0],[NaN],[Inf],[big"1e400"],0,-1,1.5,NaN,Inf,big"1e400",nothing)
            @test_throws ArgumentError H.nongaussian_heritability(fixture(:binomial);n_trials=nt)
        end
        @test_throws ArgumentError H.nongaussian_heritability(fixture(:binomial;nt=[5,6],va=-1.0))
        @test_throws ArgumentError H.nongaussian_heritability(fixture(:binomial;nt=[5,6]);predictor_variance=Inf)
    end
    @testset "Projection limits and formula preservation" begin
        for fam in (H.GaussianResponse(1.0),H.PoissonResponse(),H.BernoulliResponse(),H.BernoulliProbitResponse(),H.GammaResponse(2.0))
            @test H.nongaussian_heritability(0.0,0.0,fam).h2_observation == 0.0
            @test H.nongaussian_heritability(0.0,1000.0,fam).h2_observation == 0.0
        end
        @test isnan(H.nongaussian_heritability(0.0,0.0,H.PoissonResponse()).h2_latent)
        @test all(iszero,H.nongaussian_heritability(0.0,1000.0,H.OrderedProbitResponse([-1.0,1.0])).h2_observation_by_category)
        for va in (.2,1.0), vf in (0.0,.5), mu in (0.0,1.2)
            v=va+vf; lambda=exp(mu+v/2)
            po=H.nongaussian_heritability(va,mu,H.PoissonResponse();predictor_variance=vf)
            @test po.h2_observation ≈ va/(expm1(v)+1/lambda) rtol=1e-13
            @test po.latent_total_variance == v
            for shape in (1.0,2.0)
                ga=H.nongaussian_heritability(va,mu,H.GammaResponse(shape);predictor_variance=vf)
                @test ga.h2_observation ≈ va/(exp(v)*(1+1/shape)-1) rtol=1e-13
                @test ga.h2_latent ≈ va/(v+H._trigamma(shape)) rtol=1e-13
                @test ga.h2_observation ≈ H.nongaussian_heritability(va,4.2,H.GammaResponse(shape);predictor_variance=vf).h2_observation rtol=1e-13
            end
        end
        # Independent 64-node oracle at one ordinary positive fixed-spread point.
        k=64
        eig=eigen(SymTridiagonal(zeros(k),[sqrt(j/2) for j in 1:k-1]))
        weights=eig.vectors[1,:].^2
        eta=.3 .+ sqrt(2*.8).*eig.values
        probabilities=1 ./ (1 .+ exp.(-eta))
        mean_p=sum(weights.*probabilities)
        derivative=sum(weights.*probabilities.*(1 .- probabilities))
        variance_p=sum(weights.*probabilities.^2)-mean_p^2
        logit=H.nongaussian_heritability(.5,.3,H.BinomialResponse(5);predictor_variance=.3)
        @test logit.h2_observation ≈ .5*derivative^2/(variance_p+derivative/5) rtol=1e-3
        @test logit.h2_latent ≈ .5/(.8+pi^2/3) rtol=1e-14
        @test_throws ArgumentError H.nongaussian_heritability(fixture(:poisson;converged=false))
        @test_throws ArgumentError H.nongaussian_heritability(fixture(:poisson;beta=[0.0,1.0]))
        @test_throws ArgumentError H.nongaussian_heritability(1.0,0.0,H.NegativeBinomialResponse(2.0))
        @test_throws ArgumentError H._nongaussian_h2_core(:poisson,-1.0,0.0,NaN,1,0.0,true)
    end
end
