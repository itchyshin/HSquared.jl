using Test, HSquared, LinearAlgebra

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
