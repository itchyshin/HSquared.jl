using Test, HSquared, LinearAlgebra, SparseArrays

# #408: variance_component_uncertainty returns the variance-component covariance,
# its standard errors, the h2 standard error and the logit-delta h2 interval from
# ONE average-information matrix, bit-identical to the three standalone calls
# the R bridge makes today (each of which builds and factorises its own matrix).
@testset "issue 408: variance_component_uncertainty from one information matrix" begin
    ids = string.(1:12)
    sire = ["0", "0", "0", "0", "1", "1", "2", "2", "3", "3", "5", "5"]
    dam = ["0", "0", "0", "0", "2", "3", "4", "4", "4", "2", "6", "7"]
    ped = normalize_pedigree(ids, sire, dam)
    Ainv = pedigree_inverse(ped)
    n = 12
    y = [2.1, 3.4, 2.8, 3.9, 2.5, 3.1, 4.2, 3.6, 2.2, 3.0, 4.4, 3.3]
    X = ones(n, 1)
    Z = Matrix{Float64}(I, n, n)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    fit = fit_ai_reml(spec)
    @test fit.converged

    calls = Ref(0)
    builder = fitted -> begin
        calls[] += 1
        variance_component_covariance(fitted)
    end
    unc = HSquared._variance_component_uncertainty(fit, 0.95, builder)
    @test calls[] == 1

    @test unc.covariance == variance_component_covariance(fit)
    @test unc.standard_errors == variance_component_standard_errors(fit)
    @test unc.heritability_standard_error == heritability_standard_error(fit)
    @test unc.heritability_interval == heritability_interval(fit)

    # The public entry point agrees, and honours `level`.
    pub = variance_component_uncertainty(fit)
    @test pub == unc
    narrow = variance_component_uncertainty(fit; level = 0.80)
    @test narrow.heritability_interval == heritability_interval(fit; level = 0.80)
    @test narrow.heritability_interval.level == 0.80

    # Level guard, as in the standalone interval (the converged-fit guard is #437's).
    @test_throws ArgumentError variance_component_uncertainty(fit; level = 1.5)
end

@testset "uncertainty bundle rejects invalid fits before boundary covariance" begin
    y = [1.0, 2.0, 3.0]
    X = ones(3, 1)
    Z = sparse(1.0I, 3, 3)
    precision = spdiagm(0 => [1.0, 2.0, 4.0])
    reml = animal_model_spec(y, X, Z, precision; method = :REML)
    ml = animal_model_spec(y, X, Z, precision; method = :ML)
    ridge = animal_model_spec(y, X, Z, sparse(1.0I, 3, 3); method = :REML)
    likelihood = GaussianLikelihoodResult(-1.0, [0.0], 1.0, 1.0, :REML, 3, 1)
    makefit(spec, a, e; converged = true) = AnimalModelFit(
        spec, likelihood, (sigma_a2 = a, sigma_e2 = e), converged, "test", 0)
    @test_throws ArgumentError variance_component_uncertainty(makefit(reml, 1.0, 1.0; converged = false))
    @test_throws ArgumentError variance_component_uncertainty(makefit(ml, 1.0, 1.0))
    @test_throws ArgumentError variance_component_uncertainty(makefit(ridge, 1.0, 1.0))

    boundary = makefit(reml, 1.0, eps() / 4)
    @test heritability(boundary) == 1.0
    calls = Ref(0)
    builder = fit -> (calls[] += 1; variance_component_covariance(fit))
    @test_throws ArgumentError HSquared._variance_component_uncertainty(boundary, 0.95, builder)
    @test calls[] == 0
    for boundary_fit in (boundary, makefit(reml, 0.0, 1.0), makefit(reml, 1.0, 0.0))
        err = try
            variance_component_uncertainty(boundary_fit)
            nothing
        catch caught
            caught
        end
        @test err isa ArgumentError
        @test occursin("boundary", sprint(showerror, err))
    end
end
