using Test, LinearAlgebra, SparseArrays, Random, HSquared
const H = HSquared
message(f) = try
    f(); "no exception"
catch e
    e isa ArgumentError ? sprint(showerror,e) : string(typeof(e),": ",sprint(showerror,e))
end
const na = (estimate=NaN,lower=NaN,upper=NaN,se=NaN,lower_clamped=false,upper_clamped=false,boundary=true)
# A small supplied-variance fixture, with no optimizer or fit.
rng = MersenneTwister(913)
n=48; g1=repeat(1:8,6); g2=repeat(1:6,inner=8)
Z1=sparse(1:n,g1,1.0,n,8); Z2=sparse(1:n,g2,1.0,n,6)
X=ones(n,1); effects=[(Z1,spdiagm(0=>ones(8))),(Z2,spdiagm(0=>ones(6)))]
y=2 .+ 2 .* (Z1*randn(rng,8) .+ Z2*randn(rng,6) .+ randn(rng,n))
@testset "Likelihood uncertainty contracts" begin
    @testset "Unique integer selection" begin
        for idx in ([1,1],Int[],[1.0],[1.5],[true],[0],[3],[big"1e100"])
            for call in (H.multi_effect_sum_ratio_interval,H.multi_effect_uncertainty)
                msg=message(()->call(y,X,effects,[1.0,1.0],1.0;which=idx))
                @test occursin("ArgumentError",msg) && occursin("which",msg)
            end
            @test_throws ArgumentError H._sum_ratio_ci_from_cov(Matrix{Float64}(I,3,3),[1.0,1.0,1.0],idx,2,.95,na)
        end
        theta=[2.0,1.0,3.0]; cov=Matrix{Float64}(I,3,3)
        expected=[3.0,3.0,-3.0]./36
        ci=H._sum_ratio_ci_from_cov(cov,theta,[1,2],2,.95,na)
        @test ci.estimate == .5
        @test ci.se ≈ norm(expected) rtol=1e-14
        @test H._sum_ratio_ci_from_cov(cov,theta,[2,1],2,.95,na) == ci
    end
    @testset "Full denominator with inactive coordinate fixed" begin
        theta=[2.0,1.0,3.0]; ci=H._ratio_delta_ci(Matrix{Float64}(I,3,3),theta,1,.95,.2)
        @test ci.estimate == 1/3
        @test !ci.boundary
        @test ci.se ≈ hypot(4.0,-2.0)/36 rtol=1e-14
        fd=[begin
            lo=copy(theta);hi=copy(theta);lo[k]-=1e-5;hi[k]+=1e-5
            (hi[1]/sum(hi)-lo[1]/sum(lo))/(2e-5)
        end for k in (1,3)]
        @test ci.se ≈ norm(fd) rtol=1e-10
        interior=H._ratio_delta_ci(Matrix{Float64}(I,3,3),theta,1,.95,0.0)
        @test interior.se ≈ norm([4.0,-2.0,-2.0]./36) rtol=1e-14
        exact_zero=H._ratio_delta_ci(Matrix{Float64}(I,3,3),[2.0,0.0,3.0],1,.95,1e-6)
        @test exact_zero.estimate == .4
        @test exact_zero.se ≈ hypot(3.0,-2.0)/25 rtol=1e-14
    end
    @testset "Finite positive FD step before evaluation" begin
        calls=Ref(0);f=t->(calls[]+=1;-sum(abs2,t)/2)
        for step in (0.0,-1e-4,NaN,Inf,-Inf,big"1e-400",big"1e400")
            calls[]=0
            @test_throws ArgumentError H._reml_fd_information(f,[1.0,1.0],step)
            @test calls[] == 0
            for call in (
                ()->H.two_effect_ratio_interval(Float64[],ones(1,1),ones(1,1),ones(1,1),ones(1,1),ones(1,1);fd_step=step),
                ()->H.multi_effect_ratio_interval(Float64[],ones(1,1),[];fd_step=step),
                ()->H.multi_effect_variance_component_covariance(y,X,effects,[1.0,1.0],1.0;fd_step=step),
                ()->H.multi_effect_sum_ratio_interval(y,X,effects,[1.0,1.0],1.0;fd_step=step,boundary_tol=.9),
                ()->H.multi_effect_uncertainty(y,X,effects,[1.0,1.0],1.0;fd_step=step))
                msg=message(call)
                @test occursin("ArgumentError",msg) && occursin("fd_step",msg)
            end
        end
        info=H._reml_fd_information(t->-sum(abs2,t)/2,[1.0,2.0],1e-3)
        @test Matrix(info) ≈ Matrix{Float64}(I,2,2) atol=1e-9
    end
    @testset "Invalid variances cannot become boundary information" begin
        for bad in (NaN,Inf,-Inf,0.0,-1.0,big"-1e-400",big"1e-400",big"1e400")
            for call in (H.multi_effect_variance_component_covariance,H.multi_effect_sum_ratio_interval,H.multi_effect_uncertainty)
                @test occursin("ArgumentError",message(()->call(y,X,effects,[bad,1.0],1.0)))
                @test occursin("sigmas",message(()->call(y,X,effects,[bad,1.0],1.0)))
                @test occursin("ArgumentError",message(()->call(y,X,effects,[1.0,1.0],bad)))
                @test occursin("sigma_e2",message(()->call(y,X,effects,[1.0,1.0],bad)))
            end
        end
        for call in (H.multi_effect_variance_component_covariance,H.multi_effect_sum_ratio_interval,H.multi_effect_uncertainty)
            @test_throws ArgumentError call(y,X,effects,[1.0],1.0)
        end
    end
    @testset "Valid supplied-variance covariance and boundary controls" begin
        cov=H.multi_effect_variance_component_covariance(y,X,effects,[1.0,1.0],1.0)
        @test all(isfinite,cov) && isposdef(cov)
        allout=H.multi_effect_uncertainty(y,X,effects,[1.0,1.0],1.0;which=[2,1])
        single=H.multi_effect_sum_ratio_interval(y,X,effects,[1.0,1.0],1.0;which=[1,2])
        @test allout.covariance == cov
        @test allout.sum_ratio_interval == single
        @test single.estimate ≈ 2/3
        @test all(isfinite,allout.ratio_se)
        @test H.multi_effect_sum_ratio_interval(y,X,effects,[1e-12,1.0],1.0;which=[1,2]).boundary
        @test H._multi_effect_variance_component_covariance(y,X,effects,[1e-12,1.0],1.0;unavailable=:nothing) === nothing
        @test_throws ArgumentError H.multi_effect_variance_component_covariance(y,X,effects,[1e-12,1.0],1.0)
        @test H.multi_effect_sum_ratio_interval(y,X,effects,[1.0,1.0],1.0;boundary_tol=.9).boundary
    end
end

@testset "Derived component step precedes rail returns" begin
 effects=[(ones(1,1),ones(1,1)),(ones(1,1),ones(1,1))]
 y=[1.0];X=ones(1,1)
 for (theta,step) in (([2.0,2.0,1.0],floatmax(Float64)),(fill(1e-4,3),nextfloat(0.0)))
  for tol in (.9,1e-6)
   call=()->H.multi_effect_sum_ratio_interval(y,X,effects,theta[1:2],theta[3];fd_step=step,boundary_tol=tol)
   @test_throws ArgumentError call()
   @test occursin("fd_step",message(call))
  end
  call=()->H._multi_effect_variance_component_covariance(y,X,effects,theta[1:2],theta[3];fd_step=step,unavailable=:nothing)
  @test_throws ArgumentError call()
  @test occursin("fd_step",message(call))
  call=()->H.multi_effect_uncertainty(y,X,effects,theta[1:2],theta[3];fd_step=step,boundary_tol=.9)
  @test_throws ArgumentError call()
  @test occursin("fd_step",message(call))
  count=Ref(0);f=t->(count[]+=1;-sum(abs2,t)/2)
  @test_throws ArgumentError H._reml_fd_information(f,theta,step)
  @test count[] == 0
 end
 # A finite positive component step preserves both ordinary and near-zero rails.
 @test H.multi_effect_sum_ratio_interval(y,X,effects,[2.0,2.0],1.0;boundary_tol=.9).boundary
 @test H.multi_effect_sum_ratio_interval(y,X,effects,[1e-12,1.0],1.0;which=[1],boundary_tol=.9).boundary
end
