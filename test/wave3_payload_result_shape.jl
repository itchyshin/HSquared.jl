using HSquared
using Test

# Result wrapping is tested without optimization: these are the NamedTuple
# shapes returned by the existing REML fitters, paired with parsed dimensions.
function _w305_parsed(dispatch, blocks; n = 6, p = 2, method = :REML)
    HSquared.ParsedPayloadV2(dispatch, zeros(n), nothing, ones(n, p), blocks, method, false)
end

const _W305_IDS = ["a", "b"]
const _W305_ANIMAL = (name = "animal", type = "pedigree", ids = _W305_IDS)
const _W305_ENV = (name = "litter", type = "iid", ids = ["L1", "L2"])
const _W305_SITE = (name = "site", type = "iid", ids = ["S1", "S2"])
const _W305_EFFECT = (ids = _W305_IDS, values = [0.2, -0.1])
const _W305_CONVENTION = (
    loglik_convention = :reml_omit_2pi,
    loglik_full_constant_offset = -0.5 * (6 - 2) * log(2π),
    loglik_comparable_across_routes = false,
)

@testset "W3-05 structured dispatch refuses an ML label before fitting" begin
    for (dispatch, blocks) in (
        (:two_effect, [_W305_ANIMAL, _W305_ENV]),
        (:multi_effect, [_W305_ANIMAL, _W305_ENV, _W305_SITE]),
        (:direct_maternal, [(name = "animal", type = "correlated",
                             ids = _W305_IDS, partner_name = "maternal")]),
    )
        parsed = _w305_parsed(dispatch, blocks; method = :ML)
        @test_throws ArgumentError HSquared._dispatch_fit(parsed)
    end
end

@testset "W3-05 two-effect result includes honest model metadata" begin
    parsed = _w305_parsed(:two_effect, [_W305_ANIMAL, _W305_ENV])
    fit = merge((
        variance_components = (sigma1 = 1.0, sigma2 = 0.5, sigma_e2 = 2.0),
        effect1 = _W305_EFFECT,
        effect2 = (ids = _W305_ENV.ids, values = [0.1, 0.2]),
        loglik = -8.0,
        converged = true,
    ), _W305_CONVENTION)
    result = result_payload_v2(fit, parsed)
    @test Set(keys(result)) == Set((:variance_components, :random_effects, :loglik,
                                    :df, :nobs, :diagnostics, :converged))
    @test result.df == 5                    # two fixed + three variance parameters
    @test result.nobs == 6
    @test result.diagnostics.method == :REML
    @test result.diagnostics.optimizer_status == "converged"
    @test result.diagnostics.loglik_convention == :reml_omit_2pi
    @test result.diagnostics.loglik_full_constant_offset ≈ _W305_CONVENTION.loglik_full_constant_offset
    @test result.diagnostics.loglik_comparable_across_routes === false
    @test result.diagnostics.loglik_stochastic === false
    @test_throws ArgumentError result_payload_v2(
        Base.structdiff(fit, _W305_CONVENTION), parsed)
end

@testset "W3-05 multi-effect result distinguishes dense, exact, and stochastic loglik" begin
    parsed = _w305_parsed(:multi_effect, [_W305_ANIMAL, _W305_ENV, _W305_SITE])
    fit = merge((
        variance_components = (sigmas = [1.0, 0.5, 0.25], sigma_e2 = 2.0),
        effects = [_W305_EFFECT, (ids = _W305_ENV.ids, values = [0.1, 0.2]),
                   (ids = _W305_SITE.ids, values = [-0.2, 0.3])],
        loglik = -9.0,
        converged = true,
        boundary = [false, false, false],
    ), _W305_CONVENTION)
    dense = result_payload_v2(fit, parsed)
    @test dense.df == 6                   # two fixed + four variance parameters
    @test dense.nobs == 6
    @test dense.diagnostics.loglik_convention == :reml_omit_2pi
    @test dense.diagnostics.loglik_stochastic === false
    @test dense.diagnostics.loglik_comparable_across_routes === false

    exact_fit = merge(fit, (
        dispatch = :exact, estimator = :sparse_multi_effect_aireml,
        loglik_convention = :reml_full_constant,
        loglik_full_constant_offset = 0.0,
        loglik_comparable_across_routes = true,
    ))
    exact = result_payload_v2(exact_fit, parsed)
    @test exact.diagnostics.loglik_convention == :reml_full_constant
    @test exact.diagnostics.loglik_full_constant_offset == 0.0
    @test exact.diagnostics.loglik_stochastic === false
    @test exact.diagnostics.loglik_comparable_across_routes === true

    mc_fit = merge(exact_fit, (
        dispatch = :matrix_free, estimator = :matrix_free_mc_em_reml,
        loglik_mcse = 0.15,
    ))
    mc = result_payload_v2(mc_fit, parsed)
    @test mc.diagnostics.loglik_convention == :reml_full_constant
    @test mc.diagnostics.loglik_full_constant_offset == 0.0
    @test mc.diagnostics.loglik_stochastic === true
    @test mc.diagnostics.loglik_mcse == 0.15
    @test mc.diagnostics.loglik_comparable_across_routes === false
end

@testset "W3-05 direct-maternal result counts covariance parameters" begin
    block = (name = "animal", type = "correlated", ids = _W305_IDS,
             partner_name = "maternal")
    parsed = _w305_parsed(:direct_maternal, [block])
    fit = (
        variance_components = (
            G_dm = [1.0 0.1; 0.1 0.5], sigma_ad = 1.0,
            sigma_am = 0.5, sigma_dm = 0.1, sigma_e2 = 2.0,
        ),
        direct_effects = _W305_EFFECT,
        maternal_effects = (ids = _W305_IDS, values = [-0.1, 0.2]),
        genetic_correlation = 0.1 / sqrt(0.5),
        loglik = -7.0,
        converged = false,
    )
    result = result_payload_v2(fit, parsed)
    @test result.df == 6                 # two fixed + three G entries + residual
    @test result.nobs == 6
    @test result.diagnostics.method == :REML
    @test result.diagnostics.optimizer_status == "not_converged"
    @test result.diagnostics.loglik_convention == :reml_omit_2pi
    @test result.diagnostics.loglik_full_constant_offset ≈ _W305_CONVENTION.loglik_full_constant_offset
    @test result.diagnostics.loglik_stochastic === false
    @test result.diagnostics.loglik_comparable_across_routes === false
end
