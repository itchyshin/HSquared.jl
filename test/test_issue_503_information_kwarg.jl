using HSquared
using LinearAlgebra
using Test

# Regression: String `information` must raise ArgumentError, not TypeError (HSquared.jl #503).
@testset "issue 503: information kwarg type validation" begin
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

    @test_throws ArgumentError variance_component_covariance(fit; information = "observed")
    @test_throws ArgumentError variance_component_standard_errors(fit; information = "ai")
    @test_throws ArgumentError heritability_standard_error(fit; information = "observed")
    @test_throws ArgumentError variance_component_uncertainty(fit; information = "observed")
    @test_throws ArgumentError heritability_interval(fit; information = "observed")
    @test_throws ArgumentError variance_components_plot_data(fit; information = "observed")
end

@testset "issue 503: variance_components_plot_data honours information switch" begin
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

    level = 0.95
    z = HSquared._standard_normal_quantile((1 + level) / 2)
    vc = variance_components(fit)
    se_obs = variance_component_standard_errors(fit; information = :observed)
    pd_obs = variance_components_plot_data(fit; level = level, information = :observed)
    @test pd_obs.lo[1] ≈ vc.sigma_a2 - z * se_obs.sigma_a2
    @test pd_obs.hi[1] ≈ vc.sigma_a2 + z * se_obs.sigma_a2

    se_ai = variance_component_standard_errors(fit; information = :ai)
    pd_ai = variance_components_plot_data(fit; level = level, information = :ai)
    @test pd_ai.lo[1] ≈ vc.sigma_a2 - z * se_ai.sigma_a2
    @test pd_obs.lo[1] != pd_ai.lo[1] || se_obs.sigma_a2 != se_ai.sigma_a2
end
