using HSquared
using Test

# Gate A: a deliberately focused contract test for the bridge-ready scale summary.
# It runs independently during red/green work and is included from runtests.jl once
# the helper exists.

let
    V_A = 0.8
    V_fixed = 0.2
    μ = 0.3

    # The two scales remain explicit rather than collapsing to a misleading scalar.
    poisson = HSquared.nongaussian_scale_summary(:poisson, V_A;
                                                 mu = μ, predictor_variance = V_fixed)
    required = (:family, :sigma_a2, :mu, :h2_latent, :h2_observation,
                :var_link, :var_distribution, :information_limited, :caveat,
                :scale, :estimate, :primary, :interpretation)
    @test all(name in propertynames(poisson) for name in required)
    @test !(:method in propertynames(poisson))
    @test poisson.family === :poisson
    @test poisson.scale === (:latent, :observation)
    @test poisson.estimate === (poisson.h2_latent, poisson.h2_observation)
    @test poisson.primary === (false, true)
    @test isnan(poisson.h2_latent)
    @test isfinite(poisson.h2_observation)
    @test occursin("conditional", lowercase(poisson.interpretation)) == false
    @test occursin("marginal", lowercase(poisson.interpretation))
    @test occursin("predictor_variance", poisson.interpretation)

    conditional = HSquared.nongaussian_scale_summary(:binomial, V_A; mu = μ, n_trials = 5)
    @test conditional.family === :binomial
    @test conditional.scale === (:latent, :observation)
    @test conditional.estimate === (conditional.h2_latent, conditional.h2_observation)
    @test conditional.primary === (true, false)
    @test conditional.h2_latent ≈ V_A / (V_A + π^2 / 3) atol = 1e-12
    @test isfinite(conditional.h2_observation)
    @test occursin("conditional", lowercase(conditional.interpretation))
    @test !conditional.information_limited
    @test HSquared.nongaussian_scale_summary(:binomial, V_A; mu = μ, n_trials = 1).information_limited

    # A valid common denominator is still required when only the latent scale is asked for.
    latent_only = HSquared.nongaussian_scale_summary(:binomial, V_A; n_trials = 5)
    @test latent_only.mu === nothing
    @test isfinite(latent_only.h2_latent)
    @test isnan(latent_only.h2_observation)

    # Scalar and constant-vector denominators have the same common-trial summary.
    constant_trials = HSquared.nongaussian_scale_summary(:binomial, V_A;
                                                          mu = μ, n_trials = [5, 5, 5])
    @test constant_trials.h2_latent ≈ conditional.h2_latent atol = 1e-12
    @test constant_trials.h2_observation ≈ conditional.h2_observation atol = 1e-12
    @test !constant_trials.information_limited

    # A genuinely varying vector is never averaged; validate it before the mu=nothing return.
    varying = HSquared.nongaussian_scale_summary(:binomial, V_A;
                                                  mu = μ, n_trials = [2, 5, 10])
    @test isfinite(varying.h2_latent)
    @test isnan(varying.h2_observation)
    @test occursin("varying", lowercase(varying.caveat))
    varying_latent_only = HSquared.nongaussian_scale_summary(:binomial, V_A;
                                                              n_trials = [2, 5, 10])
    @test isfinite(varying_latent_only.h2_latent)
    @test isnan(varying_latent_only.h2_observation)
    @test occursin("varying", lowercase(varying_latent_only.caveat))

    # Bernoulli is Binomial(1): explicit one-trial input is fine, any other denominator is not.
    bernoulli = HSquared.nongaussian_scale_summary(:bernoulli, V_A; mu = μ, n_trials = [1, 1])
    @test bernoulli.primary === (true, false)
    @test bernoulli.information_limited
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:bernoulli, V_A; mu = μ, n_trials = 2)
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:bernoulli, V_A; mu = μ, n_trials = [1, 2])

    # Family, convergence, variance, and trial guards are API contract rather than silent coercions.
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:gaussian, V_A; mu = μ)
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:poisson, V_A; mu = μ, n_trials = 1)
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:binomial, V_A; mu = μ)
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:binomial, V_A; mu = μ, n_trials = Int[])
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:binomial, V_A; mu = μ, n_trials = [2, 0])
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:binomial, V_A; mu = μ, n_trials = [2, 1.5])
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:binomial, V_A; mu = μ, n_trials = [2, NaN])
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:binomial, V_A; mu = μ, n_trials = Inf)
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:binomial, V_A; mu = μ, n_trials = 0)
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:binomial, V_A; mu = μ, n_trials = 2, converged = false)
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:poisson, -0.1; mu = μ)
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:poisson, NaN; mu = μ)
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:poisson, Inf; mu = μ)
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:poisson, V_A; mu = μ, predictor_variance = -0.1)
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:poisson, V_A; mu = μ, predictor_variance = Inf)
    @test_throws ArgumentError HSquared.nongaussian_scale_summary(:poisson, floatmax(Float64);
                                                                   mu = μ, predictor_variance = floatmax(Float64))

    # Extreme but finite means must not trigger Inf/Inf (Poisson) or 0/0 (logit) NaN.
    po_extreme = HSquared.nongaussian_scale_summary(:poisson, V_A; mu = 1_000.0)
    @test isfinite(po_extreme.h2_observation)
    @test 0.0 <= po_extreme.h2_observation <= 1.0
    logit_hi = HSquared.nongaussian_scale_summary(:binomial, V_A; mu = 1_000.0, n_trials = 5)
    logit_lo = HSquared.nongaussian_scale_summary(:binomial, V_A; mu = -1_000.0, n_trials = 5)
    @test isfinite(logit_hi.h2_observation)
    @test isfinite(logit_lo.h2_observation)
    @test 0.0 <= logit_hi.h2_observation <= 1.0
    @test 0.0 <= logit_lo.h2_observation <= 1.0
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    println("HSQ09_NG_GATEA_TESTS_OK")
end
