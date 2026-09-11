using Test
using HSquared

_a4_fit(; family::Symbol = :bernoulli, n_trials = nothing, beta = [0.3]) =
    HSquared.NonGaussianFit(
        (sigma_a2 = 0.4,),
        -12.5,
        beta,
        [0.0, 0.0],
        ["a", "b"],
        true,
        family,
        :laplace,
        n_trials,
        nothing,
    )

@testset "A4-1 Binomial-logit observation-scale payload" begin
    bernoulli = HSquared.nongaussian_three_field_payload(_a4_fit())
    binomial = HSquared.nongaussian_three_field_payload(
        _a4_fit(family = :binomial, n_trials = 3),
    )
    common_vector = HSquared.nongaussian_three_field_payload(
        _a4_fit(family = :binomial, n_trials = [3, 3]); response_length = 2,
    )
    all_one_vector = try
        HSquared.nongaussian_three_field_payload(
            _a4_fit(family = :binomial, n_trials = [1, 1]); response_length = 2,
        )
    catch caught
        caught
    end

    for result in (bernoulli, binomial)
        @test isfinite(result.h2_observation)
        @test 0.0 < result.h2_observation < 1.0
        @test result.h2_observation_undefined_reason === nothing
    end
    @test bernoulli.h2_observation ≈ 0.08251105919157474 atol = 1e-12
    @test binomial.h2_observation ≈ 0.21227333326532113 atol = 1e-12
    @test common_vector.h2_observation ≈ binomial.h2_observation atol = 1e-12
    @test common_vector.h2_observation_undefined_reason === nothing
    @test all_one_vector isa NamedTuple
    @test all_one_vector.h2_observation ≈ bernoulli.h2_observation atol = 1e-12
    @test all_one_vector.h2_observation_undefined_reason === nothing
    @test bernoulli.h2_observation != binomial.h2_observation

    # Negative control: neither a changing vector nor its order can be silently
    # collapsed into a scalar-trial observation-scale estimand.
    for trials in ([2, 3], [3, 2], [2, 20])
        varying = HSquared.nongaussian_three_field_payload(
            _a4_fit(family = :binomial, n_trials = trials);
            response_length = length(trials),
        )
        @test isnan(varying.h2_observation)
        @test varying.h2_observation_undefined_reason ==
              "varying_trials_no_scalar_estimand"
        @test varying.n_trials == trials
    end
end

println("A4_BINOMIAL_OBSERVATION_SCALE_OK")
