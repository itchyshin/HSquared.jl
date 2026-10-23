using Test, HSquared, LinearAlgebra

# #408: variance_components_plot_data builds the REML information matrix once
# (it used to build it for the variance-component SEs and again for the h2
# interval), with bit-identical output.
@testset "issue 408: plot data reuses one information matrix" begin
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

    # Count the per-call covariance builder locally. The production likelihood
    # path must not carry a mutable global counter just for this assertion.
    covariance_calls = Ref(0)
    covariance_builder = fitted -> begin
        covariance_calls[] += 1
        variance_component_covariance(fitted)
    end
    pd = HSquared._variance_components_plot_data(fit, 0.95, covariance_builder)
    @test covariance_calls[] == 1

    # Same numbers as the standalone extractors.
    se = variance_component_standard_errors(fit)
    ci = heritability_interval(fit)
    z = HSquared._standard_normal_quantile(0.975)
    vc = variance_components(fit)
    @test pd.lo[1] == vc.sigma_a2 - z * se.sigma_a2
    @test pd.hi[2] == vc.sigma_e2 + z * se.sigma_e2
    @test pd.lo[3] == ci.lower
    @test pd.hi[3] == ci.upper
    @test pd.interval_reason == ["ok", "ok", "ok"]
end
