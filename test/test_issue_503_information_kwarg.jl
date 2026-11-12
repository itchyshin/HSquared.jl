using HSquared
using LinearAlgebra
using Test

function _issue_503_tiny_animal_fit()
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
    return fit
end

# Regression: String `information` must raise ArgumentError, not TypeError (HSquared.jl #503).
@testset "issue 503: information kwarg type validation" begin
    fit = _issue_503_tiny_animal_fit()

    @test_throws ArgumentError variance_component_covariance(fit; information = "observed")
    @test_throws ArgumentError variance_component_standard_errors(fit; information = "ai")
    @test_throws ArgumentError heritability_standard_error(fit; information = "observed")
    @test_throws ArgumentError variance_component_uncertainty(fit; information = "observed")
    @test_throws ArgumentError heritability_interval(fit; information = "observed")
    @test_throws ArgumentError variance_components_plot_data(fit; information = "observed")
end

@testset "issue 503: variance_components_plot_data honours information switch" begin
    fit = _issue_503_tiny_animal_fit()

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
    @test pd_ai.hi[1] ≈ vc.sigma_a2 + z * se_ai.sigma_a2
    @test isfinite(se_obs.sigma_a2) && isfinite(se_ai.sigma_a2)
    @test se_obs.sigma_a2 != se_ai.sigma_a2
    @test pd_obs.lo[1] != pd_ai.lo[1]
    @test pd_obs.hi[1] != pd_ai.hi[1]
end

@testset "issue 503: forwarded uncertainty honours information switch" begin
    fit = _issue_503_tiny_animal_fit()

    cov_ai = variance_component_covariance(fit; information = :ai)
    cov_obs = variance_component_covariance(fit; information = :observed)
    @test cov_ai != cov_obs

    se_ai = variance_component_standard_errors(fit; information = :ai)
    se_obs = variance_component_standard_errors(fit; information = :observed)
    @test isfinite(se_ai.sigma_a2) && isfinite(se_obs.sigma_a2)
    @test isfinite(se_ai.sigma_e2) && isfinite(se_obs.sigma_e2)
    @test se_ai.sigma_a2 != se_obs.sigma_a2
    @test se_ai.sigma_e2 != se_obs.sigma_e2

    h_ai = heritability_standard_error(fit; information = :ai)
    h_obs = heritability_standard_error(fit; information = :observed)
    @test isfinite(h_ai) && isfinite(h_obs)
    @test h_ai != h_obs

    ci_ai = heritability_interval(fit; information = :ai)
    ci_obs = heritability_interval(fit; information = :observed)
    @test isfinite(ci_ai.se) && isfinite(ci_obs.se)
    @test ci_ai.se != ci_obs.se
    @test ci_ai.lower != ci_obs.lower || ci_ai.upper != ci_obs.upper

    u_ai = variance_component_uncertainty(fit; information = :ai)
    u_obs = variance_component_uncertainty(fit; information = :observed)
    @test u_ai.covariance != u_obs.covariance
    @test u_ai.standard_errors.sigma_a2 != u_obs.standard_errors.sigma_a2
    @test u_ai.heritability_standard_error != u_obs.heritability_standard_error
    @test u_ai.heritability_interval.se != u_obs.heritability_interval.se
end
