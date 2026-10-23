using Test, HSquared, LinearAlgebra, SparseArrays

@testset "iterative finite arithmetic contracts" begin
    X0=zeros(2,0); Z0=spzeros(2,1); Q=spdiagm(0=>[1.]); effects0=[(Z0,Q)]
    @testset "responses cannot hide behind structural zeros" begin
        for bad in (NaN, Inf, -Inf, big"1e400")
            y=[bad,zero(bad)]
            spec=animal_model_spec(y,X0,Z0,Q)
            for matrix_free in (false,true)
                @test_throws ArgumentError solve_animal_model_pcg(spec,1.,1.;matrix_free=matrix_free)
                @test_throws ArgumentError solve_multi_effect_pcg(y,X0,effects0,[1.],1.;matrix_free=matrix_free)
            end
            @test_throws ArgumentError matrix_free_reml_loglik(y,X0,effects0,[1.],1.;slq_probes=2,slq_steps=2)
            @test_throws ArgumentError matrix_free_reml_information(y,X0,effects0,[1.],1.)
            @test_throws ArgumentError matrix_free_ratio_intervals(y,X0,effects0,[1.],1.)
            @test_throws ArgumentError fit_multi_effect_mc_reml(y,X0,effects0;iterations=1,nprobe=2)
            @test_throws ArgumentError fit_matrix_free_reml(spec;iterations=1,nprobe=2,compute_loglik=false)
        end
    end
    @testset "converted design inputs" begin
        for bad in (NaN, Inf, big"1e400")
            Xbad=reshape([bad,one(bad)],2,1)
            Zbad=reshape([bad,one(bad)],2,1)
            for (X,Z) in ((Xbad,Z0),(X0,Zbad))
                e=[(Z,Q)]
                spec=animal_model_spec(zeros(2),X,Z,Q)
                @test_throws ArgumentError solve_animal_model_pcg(spec,1.,1.;matrix_free=true)
                @test_throws ArgumentError solve_animal_model_pcg(spec,1.,1.;matrix_free=false)
                @test_throws ArgumentError solve_multi_effect_pcg(zeros(2),X,e,[1.],1.)
                @test_throws ArgumentError mc_reml_block_traces(X,e,[1.],1.;nprobe=2)
                @test_throws ArgumentError fit_multi_effect_mc_reml(zeros(2),X,e;iterations=1,nprobe=2)
                @test_throws ArgumentError matrix_free_reml_loglik(zeros(2),X,e,[1.],1.;slq_probes=2,slq_steps=2)
                @test_throws ArgumentError matrix_free_reml_information(zeros(2),X,e,[1.],1.)
            end
        end
    end
    @testset "unrepresentable result fails explicitly" begin
        huge=[1e200,0.]
        @test_throws ArgumentError matrix_free_reml_information(huge,X0,effects0,[1.],1.)
        @test_throws ArgumentError matrix_free_reml_loglik(huge,X0,effects0,[1.],1.;slq_probes=2,slq_steps=2)
        @test_throws ArgumentError HSquared._pcg_solve(identity,[Inf];tol=1e-10,maxiter=2,applyMinv=identity)
        @test_throws ArgumentError HSquared._pcg_solve(identity,[1e200];tol=1e-10,maxiter=1,applyMinv=identity)
    end
    @testset "finite trace mean and unchanged MCSE convention" begin
        for shared in (false,true)
            tr,se=mc_reml_block_traces(X0,effects0,[1.2e308],1.;nprobe=2,shared_probes=shared)
            @test tr ≈ [1.2e308]
            @test se == [0.]
            one_tr,one_se=mc_reml_block_traces(X0,effects0,[1.2],1.;nprobe=1,shared_probes=shared)
            @test one_tr ≈ [1.2]
            @test isnan(only(one_se))
        end
    end
    @testset "scale-safe fitted ratio" begin
        fit=fit_multi_effect_mc_reml([1.2e154,0.],X0,effects0;
            initial=[1.2e308,.8e308],iterations=1,nprobe=2,tol=.2)
        @test fit.converged
        @test only(fit.ratios) ≈ .625
        @test fit.boundary == [false]
        @test fit.trace_mcse == [0.]
        @test fit.trace_evaluation_variance_components == fit.variance_components
        @test all(isfinite,fit.beta) && all(isfinite,fit.effects[1].values)
    end
    @testset "independent ordinary Gaussian controls" begin
        y=[1.,2.]
        @test solve_multi_effect_pcg(y,X0,effects0,[1.],1.).effects[1].values == [0.]
        @test Matrix(matrix_free_reml_information(y,X0,effects0,[1.],1.)) ≈ [0. 0.;0. 2.5]
        @test first(matrix_free_reml_loglik(y,X0,effects0,[1.],1.;slq_probes=2,slq_steps=2)) ≈ -.5*(2log(2pi)+5)
        y4=[1.,-1.,2.,-2.]; X4=ones(4,1); Z4=sparse(1.0I,4,4); Q4=spdiagm(0=>[1.,2.,3.,4.])
        spec=animal_model_spec(y4,X4,Z4,Q4)
        C=[X4'X4 X4'Z4;Z4'X4 Z4'Z4+Q4]
        rhs=vcat(X4'y4,Z4'y4); reference=C\rhs
        for mf in (false,true)
            got=solve_animal_model_pcg(spec,1.,1.;matrix_free=mf)
            @test vcat(got.beta,got.breeding_values.values) ≈ reference
            @test got.converged
        end
        short=solve_animal_model_pcg(spec,1.,1.;maxiter=1,tol=1e-14)
        @test !short.converged
        @test all(isfinite,short.beta) && all(isfinite,short.breeding_values.values)
    end
end
