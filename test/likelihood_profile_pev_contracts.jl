using Test, HSquared, LinearAlgebra, SparseArrays

@testset "likelihood profile PEV and scalar contracts" begin
    @testset "profile finite bracket" begin
        f(x) = 10(x - 0.5)^2 - 0.4
        @test HSquared._profile_root(f, 0.0, 0.5) ≈ 0.3 atol=1e-8
        @test HSquared._profile_root(f, 1.0, 0.5) ≈ 0.7 atol=1e-8
        @test HSquared._profile_root(x -> -1.0, 1.0, 0.5) == 1.0
        @test HSquared._profile_root(x -> x - 1, 1.0, 0.5) == 1.0
        for bad in (NaN, Inf, -Inf)
            @test_throws ArgumentError HSquared._profile_root(x -> bad, 1.0, 0.5)
            @test_throws ArgumentError HSquared._profile_root(x -> x == 0.5 ? -1.0 : bad, 1.0, 0.5)
            @test_throws ArgumentError HSquared._profile_root(x -> x == 0.5 ? -1.0 : x == 1.0 ? 1.0 : bad, 1.0, 0.5)
            @test_throws ArgumentError HSquared._profile_root(f, bad, 0.5)
            @test_throws ArgumentError HSquared._profile_root(f, 1.0, bad)
        end
        @test_throws ArgumentError HSquared._profile_root(x -> x + 1, 1.0, 0.5)
        @test_throws ArgumentError HSquared._profile_root(x -> x - 0.5, 1.0, 0.5)
        # Large coordinates must not overflow the midpoint.
        @test HSquared._profile_root(x -> x / 1e308 - 1.2, 1.6e308, 1e308) ≈ 1.2e308 rtol=1e-8
    end
    ids = ["a", "b", "c"]
    spec = animal_model_spec([1., 2., 3.], ones(3, 1), sparse(I, 3, 3),
                             spdiagm(0 => [1., 2., 4.]); ids=ids,
                             relationship_diag=[1., .5, .25])
    ll = GaussianLikelihoodResult(-1., [0.], 1., 1., :REML, 3, 1)
    mkfit(a, e; spec=spec) = AnimalModelFit(spec, ll, (sigma_a2=Float64(a), sigma_e2=Float64(e)),
                                          true, "constructed_nofit", 0)
    @testset "Gaussian h2 arithmetic" begin
        for (a, e, truth) in ((1., 1., .5), (1.2e308, .8e308, .6),
                              (0., 1., 0.), (1., 0., 1.),
                              (nextfloat(0.), nextfloat(0.), .5))
            fit = mkfit(a, e)
            @test heritability(fit) ≈ truth
            mme = HendersonMMEResult(spec, [0.], BreedingValues(copy(ids), zeros(3)), a, e)
            @test heritability(mme) ≈ truth
        end
        for (a, e) in ((0.,0.), (-1.,2.), (Inf,1.), (1.,NaN))
            @test_throws ArgumentError heritability(mkfit(a,e))
        end
    end
    @testset "reused PEV alignment and domain" begin
        fit = mkfit(1.,1.)
        rr = reliability(fit; pev=(ids=reverse(ids), values=[.1,.2,.3]))
        @test rr.ids == reverse(ids)
        @test rr.values ≈ [.6,.6,.7]
        @test reliability(fit; pev=(ids=ids, values=[2.,0.,0.])).values[1] == -1
        for vals in ([-.1,.2,.3], [Inf,.2,.3], [NaN,.2,.3], [.1,.2])
            @test_throws ArgumentError reliability(fit; pev=(ids=ids, values=vals))
        end
        for badids in (["a","b","x"], ["a","a","c"], ["a","b"])
            @test_throws ArgumentError reliability(fit; pev=(ids=badids, values=[.1,.2,.3]))
        end
        for a in (0., -1., Inf, NaN)
            @test_throws ArgumentError reliability(mkfit(a,1.); pev=(ids=ids,values=zeros(3)))
        end
        for (a,d,p) in ((1e308,2.,1e308), (1e-308,1e-308,0.),
                        (1e-308,1e308,.5), (1e308,1e-308,.5),
                        (nextfloat(0.),1.,nextfloat(0.)))
            spec_d = animal_model_spec(spec.y,spec.X,spec.Z,spec.Ainv; ids=ids,
                                       relationship_diag=fill(d,3))
            got = reliability(mkfit(a,1.;spec=spec_d); pev=(ids=ids, values=fill(p,3)))
            truth = Float64(1 - BigFloat(p)/(BigFloat(a)*BigFloat(d)))
            @test got.values ≈ fill(truth,3) atol=2eps()
        end
        tiny_spec = animal_model_spec(spec.y,spec.X,spec.Z,spec.Ainv; ids=ids,
                                      relationship_diag=fill(nextfloat(0.),3))
        @test_throws ArgumentError reliability(mkfit(nextfloat(0.),1.;spec=tiny_spec);
                                               pev=(ids=ids,values=ones(3)))
    end
    @testset "bootstrap converted acceptance" begin
        refit(a,e; converged=true) = (converged=converged,
                                      variance_components=(sigma_a2=a,sigma_e2=e))
        @test HSquared._bootstrap_usable_refit(refit(.8,1.2))
        @test HSquared._bootstrap_usable_refit(refit(1.2e308,.8e308))
        @test !HSquared._bootstrap_usable_refit(refit(.8,1.2;converged=false))
        for a in (0.,-1.,NaN,Inf,big"1e400",big"1e-400")
            @test !HSquared._bootstrap_usable_refit(refit(a,1.))
            @test !HSquared._bootstrap_usable_refit(refit(1.,a))
        end
    end
end
