using Test, HSquared, LinearAlgebra, SparseArrays

function _likelihood_guard_fixtures(y=[1.,2.,3.], X=ones(3,1), Z=sparse(1.0I,3,3), Q=spdiagm(0=>[1.,2.,4.]))
    spec=animal_model_spec(y,X,Z,Q;ids=["a","b","c"])
    routes = [
        ()->gaussian_loglik(spec,1.,1.),
        ()->sparse_reml_loglik(spec,1.,1.),
        ()->henderson_mme(spec,1.,1.),
        ()->fit_variance_components(spec;iterations=1),
        ()->fit_sparse_reml(spec;iterations=1),
        ()->fit_ai_reml(spec;iterations=1),
        ()->two_effect_mme(y,X,Z,Q,Z,sparse(1.0I,3,3),1.,1.,1.),
        ()->multi_effect_mme(y,X,[(Z,Q)],[1.],1.),
        ()->sparse_multi_reml_loglik(y,X,[(Z,Q)],[1.],1.),
        ()->fit_two_effect_reml(y,X,Z,Q,Z,sparse(1.0I,3,3);iterations=1),
        ()->fit_multi_effect_reml(y,X,[(Z,Q)];iterations=1),
        ()->fit_sparse_multi_effect_aireml(y,X,[(Z,Q)];iterations=1),
        ()->fit_direct_maternal_reml(y,X,Z,Z,Q;iterations=1),
        ()->fit_repeatability_reml(y,X,Z,Q;iterations=1),
    ]
    return routes
end

@testset "likelihood input and result boundaries" begin
    @testset "malformed model inputs reject before fitting" begin
        for routes in (_likelihood_guard_fixtures([Inf,2.,3.]),
                       _likelihood_guard_fixtures([BigFloat("1e10000"),2,3]),
                       _likelihood_guard_fixtures([1.,2.,3.], [1. NaN;1. 0.;1. 1.]),
                       _likelihood_guard_fixtures([1.,2.,3.], ones(3,2)),
                       _likelihood_guard_fixtures([1.,2.,3.],ones(3,1),sparse([Inf 0 0;0 1 0;0 0 1])),
                       _likelihood_guard_fixtures([1.,2.,3.],ones(3,1),sparse(1.0I,3,3),spdiagm(0=>[-.1,2.,4.])),
                       _likelihood_guard_fixtures([1.,2.,3.],ones(3,1),sparse(1.0I,3,3),sparse([1. .4 0;.1 2 0;0 0 4.])))
            for call in routes
                @test_throws ArgumentError call()
            end
        end
    end
    y=[1.,2.,3.]; X=ones(3,1); Z=sparse(1.0I,3,3); Q=spdiagm(0=>[1.,2.,4.])
    spec=animal_model_spec(y,X,Z,Q)
    @testset "supplied finite positive representable variance domain" begin
        for s in (Inf,NaN,0.,-1.,BigFloat("1e-10000"),BigFloat("1e10000"))
            @test_throws ArgumentError gaussian_loglik(spec,s,1.)
            @test_throws ArgumentError gaussian_loglik(spec,1.,s)
            @test_throws ArgumentError henderson_mme(spec,s,1.)
            @test_throws ArgumentError two_effect_mme(y,X,Z,Q,Z,Z,s,1.,1.)
            @test_throws ArgumentError multi_effect_mme(y,X,[(Z,Q)],[s],1.)
            @test_throws ArgumentError sparse_multi_reml_loglik(y,X,[(Z,Q)],[s],1.)
        end
    end
    @testset "precision representability is specific to MME paths" begin
        @test isfinite(gaussian_loglik(spec,1e-320,1.).loglik)
        @test_throws ArgumentError henderson_mme(spec,1e-320,1.)
        @test_throws ArgumentError multi_effect_mme(y,X,[(Z,Q)],[1e-320],1.)
        @test_throws ArgumentError sparse_multi_reml_loglik(y,X,[(Z,Q)],[1e-320],1.)
    end
    @testset "starts controls and IDs" begin
        for s in (Inf,NaN,BigFloat("1e-10000"),BigFloat("1e10000"))
            @test_throws ArgumentError fit_variance_components(spec;initial=(s,1.),iterations=1)
            @test_throws ArgumentError fit_two_effect_reml(y,X,Z,Q,Z,Z;initial=(sigma1=s,sigma2=1.,sigma_e2=1.),iterations=1)
            @test_throws ArgumentError fit_multi_effect_reml(y,X,[(Z,Q)];initial=[s,1.],iterations=1)
            @test_throws ArgumentError fit_repeatability_reml(y,X,Z,Q;initial=(sigma_a2=s,sigma_pe2=1.,sigma_e2=1.),iterations=1)
        end
        for call in (
            ()->fit_variance_components(spec;iterations=0),
            ()->fit_two_effect_reml(y,X,Z,Q,Z,Z;iterations=0),
            ()->fit_multi_effect_reml(y,X,[(Z,Q)];iterations=0),
            ()->fit_direct_maternal_reml(y,X,Z,Z,Q;iterations=0),
            ()->fit_repeatability_reml(y,X,Z,Q;iterations=0),
            ()->multi_effect_mme(y,X,[(Z,Q)],[1.],1.;ids=[["a","a","c"]]),
            ()->fit_multi_effect_reml(y,X,[(Z,Q)];iterations=1,ids=[["a","a","c"]]),
            ()->fit_multi_effect_reml(y,X,[(Z,Q)];iterations=1,ids=[["a"]]),
            ()->fit_multi_effect_reml(y,X,[(Z,Q)];iterations=1,ids=[]),
            ()->fit_sparse_multi_effect_aireml(y,X,[(Z,Q)];iterations=1,ids=[["a","a","c"]]),
            ()->two_effect_mme(y,X,Z,Q,Z,Z,1.,1.,1.;ids1=["a","a","c"]),
            ()->fit_direct_maternal_reml(y,X,Z,Z,Q;iterations=1,ids=["a"]),
            ()->fit_direct_maternal_reml(y,X,Z,Z,Q;iterations=1,initial=7),
            ()->fit_direct_maternal_reml(y,X,Z,Z,Q;iterations=1,initial=(other=1.,)),
            ()->fit_direct_maternal_reml(y,X,Z,Z,Q;iterations=1,initial=(G_dm=[1. .4;.1 1.],sigma_e2=1.)),
        )
            @test_throws ArgumentError call()
        end
    end
    @testset "finite model can exceed arithmetic range" begin
        extreme=animal_model_spec([1e308,-1e308,0.],X,Z,Q)
        @test_throws ArgumentError gaussian_loglik(extreme,1.,1.)
        @test_throws ArgumentError sparse_reml_loglik(extreme,1.,1.)
        @test_throws ArgumentError sparse_multi_reml_loglik([1e308,-1e308,0.],X,[(Z,Q)],[1.],1.)
    end
    @testset "finite fitting failures and model-method metadata" begin
        extreme=animal_model_spec([1e308,-1e308,0.],X,Z,Q)
        @test_throws ArgumentError fit_variance_components(extreme;iterations=1)
        @test_throws ArgumentError fit_sparse_reml(extreme;iterations=1)
        mlfit=fit_variance_components(spec;method=:ML,iterations=1)
        @test mlfit.spec.method==mlfit.likelihood.method==:ML
        @test isfinite(mlfit.likelihood.loglik)
    end
    @testset "supplied solve permits saturated full-rank fixed design" begin
        saturated=animal_model_spec(y,Matrix(1.0I,3,3),Z,Q)
        solved=henderson_mme(saturated,.8,1.2)
        @test solved.beta ≈ y atol=1e-12
        @test solved.animal_effects.values ≈ zeros(3) atol=1e-12
        @test solved.spec.method==:REML
    end
    @testset "valid calculations and p0 remain supported" begin
        for fixed in (X,zeros(3,0),hcat(ones(3),[0.,1.,-1.]))
            sp=animal_model_spec(y,fixed,Z,Q)
            dense=gaussian_loglik(sp,.8,1.2)
            sparse_ll=sparse_reml_loglik(sp,.8,1.2)
            @test dense.loglik ≈ sparse_ll.loglik atol=1e-12
            if size(fixed,2)==0
                marginal=[2.,1.6,1.4]
                oracle=-.5*(3log(2pi)+sum(log,marginal)+sum(y.^2 ./ marginal))
                @test dense.loglik ≈ oracle atol=1e-12
            end
            @test dense.beta ≈ sparse_ll.beta atol=1e-12
            mme=henderson_mme(sp,.8,1.2)
            k=multi_effect_mme(y,fixed,[(Z,Q)],[.8],1.2)
            @test mme.beta ≈ k.beta atol=1e-12
            @test mme.animal_effects.values ≈ k.effects[1].values atol=1e-12
            kl=sparse_multi_reml_loglik(y,fixed,[(Z,Q)],[.8],1.2)
            @test kl[1] ≈ dense.loglik atol=1e-12
            @test kl[3][1] ≈ mme.animal_effects.values atol=1e-12
        end
        fit=fit_sparse_reml(spec;iterations=1)
        @test isfinite(fit.likelihood.loglik)
        @test all(isfinite,fit.likelihood.beta)
        @test !fit.converged
        @test fit.optimizer_status=="not_converged"
    end
end
