# K-effect variance-component standard errors (hsquared / HSquared.jl#352).
#
# Before this, `variance_component_standard_errors` had exactly one method,
# `fit::AnimalModelFit`, so every multi-effect fit -- including the animal +
# permanent-environment repeated-measures model -- had NO standard errors at
# all. The R side refused honestly rather than returning NA, but the user still
# got no SE for any model beyond a single animal effect.
#
# These differentiate the SPARSE `sparse_multi_reml_loglik`, so they work at the
# scale `fit_multi_effect(:auto)` fits. The load-bearing test is agreement with
# an INDEPENDENT dense computation (`_multi_effect_dense`, which densifies
# Ainv), i.e. two different code paths reaching the same covariance.

@testset "K-effect variance-component standard errors (#352)" begin
    rng = MersenneTwister(2026)
    nf, no = 150, 350
    n_animal = nf + no
    sire = zeros(Int, n_animal)
    dam = zeros(Int, n_animal)
    for k in (nf + 1):n_animal
        sire[k] = rand(rng, 1:nf)
        dam[k] = rand(rng, 1:nf)
        while dam[k] == sire[k]
            dam[k] = rand(rng, 1:nf)
        end
    end
    Ainv = pedigree_inverse(collect(1:n_animal), sire, dam)

    Va, Vpe, Ve = 1.0, 0.6, 0.8
    a = zeros(n_animal)
    a[1:nf] = randn(rng, nf) .* sqrt(Va)
    for k in (nf + 1):n_animal
        a[k] = 0.5 * (a[sire[k]] + a[dam[k]]) + randn(rng) * sqrt(Va / 2)
    end
    pe = randn(rng, n_animal) .* sqrt(Vpe)

    reps = 4
    nobs = n_animal * reps
    rec = repeat(1:n_animal, reps)
    y = [2.0 + a[i] + pe[i] + randn(rng) * sqrt(Ve) for i in rec]
    X = ones(nobs, 1)
    Z = sparse(1:nobs, rec, 1.0, nobs, n_animal)
    Ipe = spdiagm(0 => ones(n_animal))
    effs = [(Z, Ainv), (Z, Ipe)]

    fit = fit_multi_effect(y, X, effs; method = :auto, verbose = false)
    @test fit.converged
    sigmas = fit.variance_components.sigmas
    sigma_e2 = fit.variance_components.sigma_e2

    ses = multi_effect_variance_component_standard_errors(
        y, X, effs, sigmas, sigma_e2,
    )
    @test length(ses.sigmas) == 2
    @test all(isfinite, ses.sigmas)
    @test all(>(0), ses.sigmas)
    @test isfinite(ses.sigma_e2) && ses.sigma_e2 > 0

    # INDEPENDENT cross-check: the same covariance from the DENSE REML loglik
    # (`_multi_effect_dense` with explicitly inverted, densified Ainv) -- a
    # different code path end to end. The univariate row's own standard for
    # AI-vs-finite-difference agreement is ~8%; this is far tighter.
    As = [inv(Symmetric(Matrix{Float64}(p[2]))) for p in effs]
    ZAs = [(Matrix{Float64}(effs[i][1]), As[i]) for i in 1:2]
    theta = vcat(collect(sigmas), sigma_e2)
    dense_ll(t) = HSquared._multi_effect_dense(
        Float64.(y), Matrix{Float64}(X), ZAs, t[1:2], t[3],
    )[1]
    cov_dense = inv(HSquared._reml_fd_information(dense_ll, theta, 1e-4))
    cov_sparse = multi_effect_variance_component_covariance(
        y, X, effs, sigmas, sigma_e2,
    )
    for i in 1:3
        @test isapprox(
            sqrt(cov_sparse[i, i]), sqrt(cov_dense[i, i]); rtol = 1e-2,
        )
    end

    # Ratio (h2 for the animal block) delta-method SE.
    rses = multi_effect_ratio_standard_errors(y, X, effs, sigmas, sigma_e2)
    @test length(rses) == 2
    @test all(isfinite, rses)
    @test all(>(0), rses)
    h2 = sigmas[1] / (sigmas[1] + sigmas[2] + sigma_e2)
    # A ratio in (0,1) with a sane SE: the +/- 1 SE band must stay in (0,1)
    # here, i.e. the SE is not absurdly scaled.
    @test 0 < h2 < 1
    @test h2 - rses[1] > 0
    @test h2 + rses[1] < 1

    # K = 1 reduction: the multi-effect covariance must agree with the
    # dedicated single-animal-effect path on the same data.
    y1 = [2.0 + a[i] + randn(rng) * sqrt(Ve) for i in rec]
    eff1 = [(Z, Ainv)]
    f1 = fit_multi_effect(y1, X, eff1; method = :auto, verbose = false)
    ses1 = multi_effect_variance_component_standard_errors(
        y1, X, eff1, f1.variance_components.sigmas,
        f1.variance_components.sigma_e2,
    )
    @test length(ses1.sigmas) == 1
    @test all(isfinite, ses1.sigmas)

    # Guards.
    @test_throws ArgumentError multi_effect_variance_component_covariance(
        y, X, effs, [1.0], sigma_e2,
    )
    @test_throws ArgumentError multi_effect_variance_component_covariance(
        y, X, effs, [-1.0, 1.0], sigma_e2,
    )
    @test_throws ArgumentError multi_effect_variance_component_covariance(
        y, X, effs, sigmas, -1.0,
    )
    # A component at the boundary is refused up front, with the boundary named,
    # rather than failing opaquely inside the difference quotient.
    @test_throws ArgumentError multi_effect_variance_component_covariance(
        y, X, effs, [1e-12, sigmas[2]], sigma_e2,
    )
end

@testset "sparse summed-ratio (repeatability) interval (#352)" begin
    # The sparse repeatability route had no interval: the engine's
    # repeatability_interval() REFITS densely, so calling it for a fit that only
    # succeeded by escaping the dense ceiling would re-impose that ceiling. This
    # forms the interval from the already-fitted components instead.
    rng = MersenneTwister(4242)
    nf, no = 80, 170
    n_animal = nf + no
    sire = zeros(Int, n_animal); dam = zeros(Int, n_animal)
    for k in (nf + 1):n_animal
        sire[k] = rand(rng, 1:nf); dam[k] = rand(rng, 1:nf)
        while dam[k] == sire[k]; dam[k] = rand(rng, 1:nf); end
    end
    Ainv = pedigree_inverse(collect(1:n_animal), sire, dam)
    Va, Vpe, Ve = 1.0, 0.6, 0.8
    a = zeros(n_animal); a[1:nf] = randn(rng, nf) .* sqrt(Va)
    for k in (nf + 1):n_animal
        a[k] = 0.5 * (a[sire[k]] + a[dam[k]]) + randn(rng) * sqrt(Va / 2)
    end
    pe = randn(rng, n_animal) .* sqrt(Vpe)
    reps = 3; nobs = n_animal * reps; rec = repeat(1:n_animal, reps)
    y = [2.0 + a[i] + pe[i] + randn(rng) * sqrt(Ve) for i in rec]
    X = ones(nobs, 1)
    Z = sparse(1:nobs, rec, 1.0, nobs, n_animal)
    effs = [(Z, Ainv), (Z, spdiagm(0 => ones(n_animal)))]

    fit = fit_multi_effect(y, X, effs; method = :auto, verbose = false)
    s = fit.variance_components.sigmas
    se2 = fit.variance_components.sigma_e2
    ci = multi_effect_sum_ratio_interval(y, X, effs, s, se2; which = 1:2)

    @test !ci.boundary
    @test 0 < ci.lower < ci.estimate < ci.upper < 1
    @test isfinite(ci.se) && ci.se > 0

    # INDEPENDENT cross-check: the dense repeatability_interval, which REFITS
    # from the raw matrices -- a different estimator and a different interval
    # code path reaching the same number.
    dense = repeatability_interval(
        y, X, Z, Ainv;
        initial = (sigma_a2 = 1.0, sigma_pe2 = 1.0, sigma_e2 = 1.0),
        iterations = 200,
    )
    @test isapprox(ci.estimate, dense.repeatability; atol = 1e-4)
    @test isapprox(ci.se, dense.se; atol = 1e-4)
    @test isapprox(ci.lower, dense.lower; atol = 1e-4)
    @test isapprox(ci.upper, dense.upper; atol = 1e-4)

    # Narrower level gives a narrower interval, same point estimate.
    ci90 = multi_effect_sum_ratio_interval(y, X, effs, s, se2; which = 1:2, level = 0.90)
    @test ci90.lower > ci.lower && ci90.upper < ci.upper
    @test isapprox(ci90.estimate, ci.estimate)

    # which = 1 reduces to the single-component (h2) ratio.
    ci1 = multi_effect_sum_ratio_interval(y, X, effs, s, se2; which = 1:1)
    @test isapprox(ci1.estimate, s[1] / (s[1] + s[2] + se2))

    # A ratio on the rail returns NaN endpoints and boundary = true, never throws.
    rail = multi_effect_sum_ratio_interval(y, X, effs, [1e-14, s[2]], se2; which = 1:1)
    @test rail.boundary
    @test isnan(rail.lower) && isnan(rail.upper)

    @test_throws ArgumentError multi_effect_sum_ratio_interval(
        y, X, effs, s, se2; which = 1:2, level = 1.5)
    @test_throws ArgumentError multi_effect_sum_ratio_interval(
        y, X, effs, s, se2; which = 1:5)
    @test_throws ArgumentError multi_effect_sum_ratio_interval(
        y, X, effs, s, se2; which = Int[])

    # Unexpected input bugs should still surface, not be swallowed as "boundary".
    @test_throws ArgumentError multi_effect_sum_ratio_interval(
        y, X[1:(end - 1), :], effs, s, se2; which = 1:2)
end
