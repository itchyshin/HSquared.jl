using HSquared

# Focused, deterministic Gate A engine oracle.  This is deliberately not a
# recovery/coverage experiment: it checks only the admitted scale arithmetic
# and undefined-value contract used by the R bridge.
poisson = HSquared.nongaussian_scale_summary(:poisson, 0.8; mu = 0.2)
@assert isnan(poisson.h2_latent)
@assert isfinite(poisson.h2_observation)

latent_only = HSquared.nongaussian_scale_summary(
    :binomial, 0.8; predictor_variance = 0.2
)
@assert isfinite(latent_only.h2_latent)
@assert isnan(latent_only.h2_observation)

constant = HSquared.nongaussian_scale_summary(
    :binomial, 0.8; mu = 0.2, n_trials = 5, predictor_variance = 0.2
)
@assert isfinite(constant.h2_latent) && isfinite(constant.h2_observation)

varying = HSquared.nongaussian_scale_summary(
    :binomial, 0.8; mu = 0.2, n_trials = [1, 5, 8]
)
@assert isfinite(varying.h2_latent)
@assert isnan(varying.h2_observation)
@assert occursin("not silently averaged", varying.caveat)

println("HSQ09_JULIA_NONGAUSSIAN_PASS")
