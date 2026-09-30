using Test,HSquared,LinearAlgebra,SparseArrays

@testset "legacy sparse validator and canonical computational buffers" begin
    for p in (0,1)
        y=Float32[1,2,4]; X=ones(Float32,3,p); Z=sparse(1.0f0I,3,3); Q=spdiagm(0=>Float32[1,2,4])
        original=animal_model_spec(y,X,Z,Q;relationship_diag=[1.,.5,.25])
        snapshots=(copy(y),copy(X),copy(Z),copy(Q),copy(original.ids),copy(original.relationship_diag))
        legacy,factor=HSquared._validated_sparse_relationship_spec(original)
        computational,_=HSquared._likelihood_validated_spec(original)
        @test legacy===original
        @test (original.y,original.X,original.Z,original.Ainv,original.ids,original.relationship_diag)==snapshots
        @test legacy.relationship_diag===original.relationship_diag
        @test HSquared._relationship_diag(legacy,:auto)===original.relationship_diag
        @test isfinite(logdet(factor))
        @test computational!==original
        @test eltype(computational.y)==Float64
        @test all(m->issparse(m) && eltype(m)==Float64,(computational.X,computational.Z,computational.Ainv))
        @test computational.y==Float64.(original.y)
        @test computational.X==sparse(Float64.(original.X))
        @test computational.Z==sparse(Float64.(original.Z))
        @test computational.Ainv==sparse(Float64.(original.Ainv))
        @test sparse_reml_loglik(legacy,.8,1.2).loglik≈sparse_reml_loglik(computational,.8,1.2).loglik
        @test fit_sparse_reml(original;iterations=1).spec===original
        @test fit_ai_reml(original;iterations=1).spec===original
    end
    y=[1.,2.,4.]; X=ones(3,1); Z=sparse(1.0I,3,3); Q=spdiagm(0=>[1.,2.,4.])
    asym=sparse([1. eps() 0.;0. 2. 0.;0. 0. 4.]); canonical=.5asym+.5asym'
    original=animal_model_spec(y,X,Z,asym;relationship_diag=[1.,.5,.25])
    legacy,_=HSquared._validated_sparse_relationship_spec(original)
    computational,_=HSquared._likelihood_validated_spec(original)
    @test legacy!==original
    @test legacy.Ainv==computational.Ainv==canonical
    @test legacy.relationship_diag===nothing
    @test original.Ainv==asym && original.relationship_diag==[1.,.5,.25]
    for bad in (animal_model_spec([Inf,2.,4.],X,Z,Q),
                animal_model_spec([big"1e400",2.,4.],X,Z,Q),
                animal_model_spec(y,ones(3,2),Z,Q),
                animal_model_spec(y,[1. NaN;1. 0.;1. 1.],Z,Q),
                animal_model_spec(y,X,sparse([Inf 0. 0.;0. 1. 0.;0. 0. 1.]),Q),
                animal_model_spec(y,X,Z,spdiagm(0=>[-.1,2.,4.])))
        @test_throws ArgumentError HSquared._validated_sparse_relationship_spec(bad)
        @test_throws ArgumentError HSquared._likelihood_validated_spec(bad)
    end
end
