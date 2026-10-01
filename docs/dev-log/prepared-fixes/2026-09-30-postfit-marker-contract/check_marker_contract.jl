using HSquared, Test, LinearAlgebra, SparseArrays, Statistics
ped = normalize_pedigree(["a1","a2","a3","a4","a5","a6"], ["0","0","a1","a1","a2","a2"], ["0","0","a2","a2","0","0"])
Ainv = pedigree_inverse(ped)
y = [2.0,3.0,2.5,3.5,4.0,1.5]; X = ones(6,1); Z = sparse(1.0I,6,6)
spec = animal_model_spec(y,X,Z,Ainv; ids=ped.ids,method=:REML); lik=gaussian_loglik(spec,1.2,0.8;method=:REML)
fit=AnimalModelFit(spec,lik,(sigma_a2=1.2,sigma_e2=0.8),true,"supplied",0)
markers=Float64[0 1 2;1 1 0;2 0 1;0 2 1;1 0 2;2 1 0]
unresolved=AnimalModelFit(spec,lik,(sigma_a2=1.2,sigma_e2=0.8),false,"supplied",0)
for scan in (mixed_model_marker_scan,single_marker_scan)
  e=try scan(unresolved,markers); nothing catch x; x end
  @test e isa ArgumentError && occursin("fit must have converged",sprint(showerror,e))
end
se=0.8; W=markers .- mean(markers;dims=1); XtX=X'X; yr=y-X*(XtX\(X'y)); eff=Float64[]; ses=Float64[]; ds=Float64[]
for j in axes(W,2)
 w=W[:,j]; wr=w-X*(XtX\(X'w)); d=dot(wr,wr); push!(ds,d); push!(eff,dot(wr,yr)/d); push!(ses,sqrt(se/d))
end
m=mixed_model_marker_scan(y,X,Z,Ainv,markers,0.0,se)
l=loco_mixed_model_marker_scan(y,X,Z,Dict("chr1"=>Matrix{Float64}(I,6,6)),fill("chr1",3),markers,0.0,se)
for a in (m,l)
 @test a.effects ≈ eff atol=1e-12 rtol=1e-12
 @test a.standard_errors ≈ ses atol=1e-12 rtol=1e-12
 @test a.z_scores ≈ eff./ses atol=1e-12 rtol=1e-12
 @test a.denominators.*se ≈ ds atol=1e-12 rtol=1e-12
end
for a in (-eps(),NaN,Inf)
 @test_throws ArgumentError mixed_model_marker_scan(y,X,Z,Ainv,markers,a,1.0)
 @test_throws ArgumentError loco_mixed_model_marker_scan(y,X,Z,Dict("chr1"=>Matrix{Float64}(I,6,6)),fill("chr1",3),markers,a,1.0)
end
@testset "negative additive variance underflow rejection" begin
    negative_tiny = -BigFloat(10)^(-1000)
    @test negative_tiny < 0 && iszero(Float64(negative_tiny)) && signbit(Float64(negative_tiny))
    for scan in (mixed_model_marker_scan, loco_mixed_model_marker_scan)
        e = try
            scan === mixed_model_marker_scan ?
                scan(y,X,Z,Ainv,markers,negative_tiny,1.0) :
                scan(y,X,Z,Dict("chr1"=>Matrix{Float64}(I,6,6)),fill("chr1",3),markers,negative_tiny,1.0)
            nothing
        catch x
            x
        end
        @test e isa ArgumentError
    end
end
println("marker contract checks passed")
