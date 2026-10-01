using Test, HSquared, LinearAlgebra, SparseArrays

@testset "independent supplied-variance controls" begin
    y = [1.,2.,3.]; X = ones(3,1); Z = sparse(I,3,3)
    Q = spdiagm(0 => [1.,2.,4.]); ids = ["a","b","c"]
    spec = animal_model_spec(y,X,Z,Q;ids=ids)
    ll = GaussianLikelihoodResult(-1.,[0.],1.,1.,:REML,3,1)
    fit = AnimalModelFit(spec,ll,(sigma_a2=1.,sigma_e2=1.),true,"constructed_nofit",0)
    mme = HendersonMMEResult(spec,[0.],BreedingValues(copy(ids),zeros(3)),1.,1.)
    # Independent coefficient inverse, without calling the package's PEV assembly.
    C = [3. 1. 1. 1.; 1. 2. 0. 0.; 1. 0. 3. 0.; 1. 0. 0. 5.]
    expected_pev = diag(inv(C))[2:4]
    expected_rel = 1 .- expected_pev ./ [1.,.5,.25]
    for object in (fit,mme), method in (:dense,:selinv,:auto)
        @test prediction_error_variance(object;method=method).values ≈ expected_pev
        @test reliability(object;method=method).values ≈ expected_rel
    end
    # Arithmetic oracle uses 256-bit operands; no sum/product in binary64.
    for a in (1e-300, 1., 1e300), d in (1e-300, 1., 1e300)
        p = Float64(BigFloat(a)*BigFloat(d)/4)
        if isfinite(p) && p > 0
            sd = animal_model_spec(y,X,Z,Q;ids=ids,relationship_diag=fill(d,3))
            f = AnimalModelFit(sd,ll,(sigma_a2=a,sigma_e2=1.),true,"constructed_nofit",0)
            r = reliability(f;pev=(ids=ids,values=fill(p,3))).values
            @test r ≈ fill(Float64(1-BigFloat(p)/(BigFloat(a)*BigFloat(d))),3)
        end
    end
    @test HSquared._gaussian_variance_fraction(1.2e308,.8e308) ≈ Float64(big(3)/5)
    @test HSquared._gaussian_variance_fraction(big"1.2",big".8") ≈ .6
    @test_throws ArgumentError HSquared._gaussian_variance_fraction(big"1e400",1.)
    @test_throws ArgumentError HSquared._profile_root(x -> x == 0 ? -1. : 1., 1e308, 0.)
end
