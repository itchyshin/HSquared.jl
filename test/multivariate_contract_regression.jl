using Test, HSquared, LinearAlgebra
@testset "Multivariate bounded contracts" begin
@testset "Multivariate finite construction" begin
    for build in (L->lowrank_covariance(L),L->factor_analytic_covariance(L,ones(2)))
        @test_throws ArgumentError build(fill(1e308,2,1))
        @test_throws ArgumentError build(fill(NaN,2,1))
        @test all(isfinite,build([1.;2.;;]))
    end
    @test_throws ArgumentError factor_analytic_covariance(fill(1e154,2,1),fill(1e308,2))
    @test lowrank_covariance([1.;2.;;]) ≈ [1. 2.;2. 4.]
    @test factor_analytic_covariance([1.;2.;;],[.2,.3]) ≈ [1.2 2.;2. 4.3]
end
@testset "Multivariate finite-difference controls" begin
    bad=(0.,-1e-4,NaN,Inf,big"1e-1000",big"1e1000",1e-200,1e200)
    for h in bad
        visits=Ref(0)
        f=x->(visits[]+=1; -sum(abs2,x)/2)
        g=x->(visits[]+=1;[x[1]^2,x[1]+2x[2]])
        @test_throws ArgumentError HSquared._fd_hessian(f,[1.,2.];h=h)
        @test visits[]==0
        @test_throws ArgumentError HSquared._fd_jacobian(g,[1.,2.];h=h)
        @test visits[]==0
    end
    @test HSquared._fd_hessian(x->-sum(abs2,x)/2,[1.,2.]) ≈ -Matrix{Float64}(I,2,2) atol=1e-7
    @test HSquared._fd_jacobian(x->[x[1]^2,x[1]+2x[2]],[1.,2.]) ≈ [2. 0.;1. 2.] atol=1e-9
end
@testset "LRT input and tail limits" begin
    for ll in (NaN,Inf,-Inf,big"1e1000",-big"1e1000")
        @test_throws ArgumentError nested_lrt(ll,0.;df=1)
        @test_throws ArgumentError nested_lrt(0.,ll;df=1)
    end
    @test HSquared._chisq_sf(Inf,1)==0.
    @test HSquared._chisq_sf(-Inf,1)==1.
    @test_throws ArgumentError HSquared._chisq_sf(NaN,1)
    @test HSquared._chisq_sf(4.,2) ≈ exp(-2.) atol=1e-13
    @test nested_lrt(-1e308,1e308;df=1).pvalue==0.
    @test nested_lrt(-1e308,1e308;df=1,boundary_df=1).pvalue==0.
    @test nested_lrt(-1e308,1e308;df=2,boundary_df=2).pvalue==0.
    @test nested_lrt(0.,-1e308;df=1).pvalue==1.
    @test nested_lrt(-100.,-97.;df=2).pvalue ≈ exp(-3.) atol=1e-13
    @test nested_lrt(0.,2.;df=1,boundary_df=1).pvalue ≈ .5nested_lrt(0.,2.;df=1).pvalue
end
@testset "Unavailable inference at unconverged points" begin
    fake=(genetic_structure=:unstructured,converged=false)
    @test_throws ArgumentError multivariate_covariance_standard_errors(fake,nothing,nothing,nothing,nothing)
    @test_throws ArgumentError genetic_correlation_interval(fake,nothing,nothing,nothing,nothing)
end
@testset "Early multivariate labels and rank" begin
    Y=[1. 2.;3. 4.;2. 5.]; X=ones(3,1); Z=[1. 0.;0. 1.;1. 0.]; Q=Matrix{Float64}(I,2,2)
    for (ids,traits,field) in ((["a","a"],["x","y"],"ids"),(["a","b"],["x","x"],"traits"),([missing,"b"],["x","y"],"ids"),(["a","b"],[" ","y"],"traits"),([1,"1"],["x","y"],"ids"),([nothing,"b"],["x","y"],"ids"),(["a"," a "],["x","y"],"ids"))
        @test_throws ArgumentError multivariate_mme(Y,X,Z,Q,Q,Q;ids=ids,traits=traits)
        # Invalid data sentinel establishes that label validation precedes numerical work.
        for fitfun in (fit_multivariate_reml,fit_multivariate_repeatability_reml)
            err=try fitfun(Y,X,Z,fill(NaN,2,2);ids=ids,traits=traits);nothing catch e;e end
            @test err isa ArgumentError
            @test occursin(field,sprint(showerror,err))
        end
    end
    r=multivariate_mme(Y,X,Z,Q,Q,Q;ids=["a","b"],traits=["x","y"])
    @test r.breeding_values.ids==["a","b"]
    @test r.traits==["x","y"]
    @test r.beta ≈ [15/7 26/7] atol=1e-12
    @test_throws ArgumentError multivariate_mme(Y,hcat(X,X),Z,Q,Q,Q)
    @test_throws ArgumentError fit_multivariate_repeatability_reml(Y,hcat(X,X),Z,Q)
    @test_throws ArgumentError fit_multivariate_reml(Y,Matrix{Float64}(I,3,3),Z,Q)
    @test_throws ArgumentError fit_multivariate_repeatability_reml(Y,Matrix{Float64}(I,3,3),Z,Q)
end

end
