using Test,HSquared,LinearAlgebra,SparseArrays

@testset "likelihood result specification identity" begin
    y=[1.,2.5,4.]; X=ones(3,1); Z=sparse(1.0I,3,3); Q=spdiagm(0=>[1.,2.,4.])
    routes=[s->fit_variance_components(s;iterations=1),
            s->fit_sparse_reml(s;iterations=1),
            s->fit_ai_reml(s;iterations=1),
            s->henderson_mme(s,.8,1.2)]
    @testset "same numerical model preserves original identity and inputs" begin
        for route in routes
            spec=animal_model_spec(copy(y),copy(X),copy(Z),copy(Q);ids=["a","b","c"],relationship_diag=[1.,.5,.25])
            before=(copy(spec.y),copy(spec.X),copy(spec.Z),copy(spec.Ainv),copy(spec.ids),copy(spec.relationship_diag))
            result=route(spec)
            @test result.spec===spec
            @test (spec.y,spec.X,spec.Z,spec.Ainv,spec.ids,spec.relationship_diag)==before
            @test result.spec.relationship_diag===spec.relationship_diag
            @test all(isfinite,fixed_effects(result))
        end
        ml=animal_model_spec(y,X,Z,Q;method=:ML)
        @test fit_variance_components(ml;iterations=1).spec===ml
        @test fit_animal_model(ml;iterations=1).spec===ml
        reml=animal_model_spec(y,X,Z,Q)
        @test fit_animal_model(reml;target=:sparse_reml,iterations=1).spec===reml
        @test fit_animal_model(reml;target=:ai_reml,iterations=1).spec===reml
        @test fit_animal_model(reml;target=:henderson_mme,variance_components=(sigma_a2=.8,sigma_e2=1.2)).spec===reml
    end
    @testset "canonical and method changes retain computational model" begin
        asym=sparse([1. 1e-14 0.;0. 2. 0.;0. 0. 4.]); canonical=.5asym+.5asym'
        for route in routes
            original=animal_model_spec(y,X,Z,copy(asym);ids=["a","b","c"],relationship_diag=[1.,.5,.25])
            reference=animal_model_spec(y,X,Z,canonical;ids=["a","b","c"])
            result=route(original); expected=route(reference)
            @test result.spec!==original
            @test result.spec.Ainv==canonical
            @test result.spec.relationship_diag===nothing
            @test original.Ainv==asym
            @test original.relationship_diag==[1.,.5,.25]
            @test fixed_effects(result)≈fixed_effects(expected)
            if result isa AnimalModelFit
                @test result.likelihood.loglik≈expected.likelihood.loglik
            else
                @test result.animal_effects.values≈expected.animal_effects.values
            end
        end
        original=animal_model_spec(y,X,Z,Q;method=:REML)
        changed=fit_variance_components(original;method=:ML,iterations=1)
        @test changed.spec!==original
        @test changed.spec.method==changed.likelihood.method==:ML
        @test original.method==:REML
    end
    @testset "guards remain before fitting" begin
        for bad in (animal_model_spec([NaN,2.,3.],X,Z,Q),
                    animal_model_spec(y,ones(3,2),Z,Q),
                    animal_model_spec(y,X,Z,spdiagm(0=>[-.1,2.,4.])))
            for route in routes
                @test_throws ArgumentError route(bad)
            end
        end
    end
end
