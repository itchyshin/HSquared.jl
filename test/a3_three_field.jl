using Test
using HSquared

_fit(; family::Symbol = :poisson, n_trials = nothing, beta = [0.3],
     ids = ["a", "b"], breeding_values = [0.0, 0.0], converged::Bool = true) =
    HSquared.NonGaussianFit(
        (sigma_a2 = 0.4,),
        -12.5,
        beta,
        breeding_values,
        ids,
        converged,
        family,
        :laplace,
        n_trials,
        nothing,
    )

@testset "A3 three-field private Julia envelope" begin
    @testset "Poisson supplies the ratified conditional fields" begin
        result = HSquared.nongaussian_three_field_payload(_fit())

        @test result.schema == "nongaussian_three_field_v09"
        @test result.family == "poisson"
        @test result.method == "laplace"
        @test result.loglik == -12.5
        @test result.components == (V_A = 0.4, V_RE = 0.0, V_O = 0.0)
        @test result.fixed_effects == (names = ["(Intercept)"], values = [0.3])
        @test result.h2_latent == 1.0
        @test result.h2_liability === nothing
        @test result.h2_observation ==
              0.4 / (expm1(0.4) + exp(-(0.3 + 0.4 / 2)))
        @test result.h2_observation_undefined_reason === nothing
        @test result.n_trials === nothing
        @test result.converged === true
        @test result.breeding_ids == ["a", "b"]
        @test result.breeding_values == [0.0, 0.0]
    end

    @testset "convergence is explicit and rejected before h2 construction" begin
        @test HSquared.nongaussian_three_field_payload(_fit()).converged === true

        err = try
            HSquared.nongaussian_three_field_payload(
                _fit(converged = false, beta = [NaN]),
            )
            nothing
        catch caught
            caught
        end
        @test err isa ArgumentError
        @test sprint(showerror, err) ==
              "ArgumentError: nongaussian_three_field_payload refuses a non-converged fit (converged = false)"
    end

    @testset "logit fields retain literal NaN and exact reason" begin
        bernoulli = HSquared.nongaussian_three_field_payload(
            _fit(family = :bernoulli),
        )
        binomial = HSquared.nongaussian_three_field_payload(
            _fit(family = :binomial, n_trials = [2, 3]); response_length = 2,
        )
        scalar_binomial = HSquared.nongaussian_three_field_payload(
            _fit(family = :binomial, n_trials = 3),
        )
        expected_liability = 0.4 / (0.4 + pi^2 / 3)

        for result in (bernoulli, binomial, scalar_binomial)
            @test result.h2_latent == 1.0
            @test result.h2_liability == expected_liability
            @test isnan(result.h2_observation)
            @test result.h2_observation_undefined_reason == "not_yet_ratified"
        end
        @test bernoulli.n_trials === nothing
        @test binomial.n_trials == [2, 3]
        @test scalar_binomial.n_trials === 3
    end

    @testset "contract mutations are rejected at construction" begin
        @test_throws ArgumentError HSquared.nongaussian_three_field_payload(
            _fit(family = :gaussian),
        )
        @test_throws ArgumentError HSquared.nongaussian_three_field_payload(
            _fit(beta = [0.3, -0.2]),
        )
        @test_throws ArgumentError HSquared.nongaussian_three_field_payload(
            _fit(); predictor_variance = 0.01,
        )
        @test_throws ArgumentError HSquared.nongaussian_three_field_payload(
            _fit(family = :bernoulli, n_trials = 1),
        )
        @test_throws ArgumentError HSquared.nongaussian_three_field_payload(
            _fit(family = :binomial, n_trials = 1),
        )
        @test_throws ArgumentError HSquared.nongaussian_three_field_payload(
            _fit(family = :binomial, n_trials = [2]); response_length = 2,
        )
        @test_throws ArgumentError HSquared.nongaussian_three_field_payload(
            _fit(family = :binomial, n_trials = [2, 3]),
        )
        @test_throws ArgumentError HSquared.nongaussian_three_field_payload(
            _fit(family = :binomial, n_trials = [1, 1]); response_length = 2,
        )
    end

    @testset "legacy payload remains a separate compatibility control" begin
        legacy = HSquared.nongaussian_result_payload(_fit())

        @test legacy.target == "nongaussian_reml"
        @test !hasproperty(legacy, :schema)
        @test !hasproperty(legacy, :h2_latent)
    end
end
