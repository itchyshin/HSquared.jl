# Average vs observed information for asymptotic standard errors.
#
# Every SE route that a K-effect or univariate REML fit reaches now takes
# `information = :ai | :observed`. The checks are against an INDEPENDENT dense
# computation from the definitions, with V formed explicitly:
#   AI[i,j]  = 1/2 y'P Vi P Vj P y
#   EXP[i,j] = 1/2 tr(P Vi P Vj)
#   OBS      = 2 AI - EXP            (exact for V linear in the components)
# so the AI path must match AI to rounding and the finite-difference observed path
# must match 2 AI - EXP to finite-difference accuracy.
# Standalone:
# julia --project=. -e 'include("test/test_se_information_switch.jl")'

using HSquared
using LinearAlgebra
using Random
using SparseArrays
using Test

function _dense_information(y, X, Vs)
    V = sum(Vs)
    Vi = inv(Symmetric(V))
    P = Vi - Vi * X * inv(Symmetric(X' * Vi * X)) * X' * Vi
    d = length(Vs)
    Py = P * y
    AI = [0.5 * dot(Vs[i] * Py, P * (Vs[j] * Py)) for i in 1:d, j in 1:d]
    EXP = [0.5 * tr(P * Vs[i] * P * Vs[j]) for i in 1:d, j in 1:d]
    return AI, EXP
end

@testset "SE information switch: K-effect (animal + permanent environment)" begin
    rng = MersenneTwister(4242)
    nf, no = 60, 140
    nan = nf + no
    sire = zeros(Int, nan); dam = zeros(Int, nan)
    for k in (nf + 1):nan
        sire[k] = rand(rng, 1:nf)
        dam[k] = rand(rng, 1:nf)
        while dam[k] == sire[k]
            dam[k] = rand(rng, 1:nf)
        end
    end
    Ainv = pedigree_inverse(collect(1:nan), sire, dam)
    A = inv(Matrix(Ainv))
    a = cholesky(Symmetric(A)).L * randn(rng, nan)
    pe = randn(rng, nan) .* sqrt(0.6)
    rec = repeat(1:nan, 3)
    nobs = length(rec)
    y = [1.0 + a[i] + pe[i] + randn(rng) * sqrt(0.8) for i in rec]
    X = hcat(ones(nobs), randn(rng, nobs))
    Z = sparse(1:nobs, rec, 1.0, nobs, nan)
    effs = [(Z, Ainv), (Z, spdiagm(0 => ones(nan)))]

    fit = fit_multi_effect(y, X, effs; method = :auto, verbose = false)
    @test fit.converged
    s = fit.variance_components.sigmas
    se2 = fit.variance_components.sigma_e2

    Zd = Matrix(Z)
    # derivative matrices dV/dθ (not scaled by θ)
    dV = [Zd * A * Zd', Zd * Zd', Matrix(1.0I, nobs, nobs)]
    Vtheta = [s[1] .* dV[1], s[2] .* dV[2], se2 .* dV[3]]
    V = sum(Vtheta)
    Vi = inv(Symmetric(V))
    P = Vi - Vi * X * inv(Symmetric(X' * Vi * X)) * X' * Vi
    Py = P * y
    AI_ref = [0.5 * dot(dV[i] * Py, P * (dV[j] * Py)) for i in 1:3, j in 1:3]
    EXP_ref = [0.5 * tr(P * dV[i] * P * dV[j]) for i in 1:3, j in 1:3]
    OBS_ref = 2 .* AI_ref .- EXP_ref

    cov_ai = multi_effect_variance_component_covariance(y, X, effs, s, se2;
                                                        information = :ai)
    cov_obs = multi_effect_variance_component_covariance(y, X, effs, s, se2;
                                                         information = :observed)
    @test isapprox(inv(cov_ai), AI_ref; rtol = 1e-8)
    @test isapprox(inv(cov_obs), OBS_ref; rtol = 1e-3)

    # Julia default is unchanged (observed), bitwise
    @test multi_effect_variance_component_covariance(y, X, effs, s, se2) == cov_obs

    # every public K-effect product honours the switch and agrees with the covariance
    u_ai = multi_effect_uncertainty(y, X, effs, s, se2; information = :ai)
    @test u_ai.covariance == cov_ai
    @test u_ai.variance_component_se.sigmas ≈ sqrt.(diag(cov_ai)[1:2])
    @test multi_effect_variance_component_standard_errors(
        y, X, effs, s, se2; information = :ai).sigmas == u_ai.variance_component_se.sigmas
    @test multi_effect_ratio_standard_errors(
        y, X, effs, s, se2; information = :ai) == u_ai.ratio_se
    @test multi_effect_sum_ratio_interval(
        y, X, effs, s, se2; information = :ai).se == u_ai.sum_ratio_interval.se
    @test_throws ArgumentError multi_effect_uncertainty(y, X, effs, s, se2;
                                                        information = :expected)
end

@testset "SE information switch: univariate animal model" begin
    rng = MersenneTwister(99)
    nf, no = 80, 320
    nan = nf + no
    sire = zeros(Int, nan); dam = zeros(Int, nan)
    for k in (nf + 1):nan
        sire[k] = rand(rng, 1:nf)
        dam[k] = rand(rng, 1:nf)
        while dam[k] == sire[k]
            dam[k] = rand(rng, 1:nf)
        end
    end
    ped = normalize_pedigree(string.(1:nan),
                             [s == 0 ? "0" : string(s) for s in sire],
                             [d == 0 ? "0" : string(d) for d in dam])
    Ainv = pedigree_inverse(ped)
    A = inv(Matrix(Ainv))
    g = cholesky(Symmetric(A)).L * randn(rng, nan)
    y = 5.0 .+ g .+ randn(rng, nan) .* sqrt(1.2)
    X = ones(nan, 1)
    Z = sparse(1.0I, nan, nan)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    fit = fit_ai_reml(spec)
    @test fit.converged
    sa = fit.variance_components.sigma_a2
    se = fit.variance_components.sigma_e2

    dV = [Matrix(A), Matrix(1.0I, nan, nan)]
    V = sa .* dV[1] .+ se .* dV[2]
    Vi = inv(Symmetric(V))
    P = Vi - Vi * X * inv(Symmetric(X' * Vi * X)) * X' * Vi
    Py = P * y
    AI_ref = [0.5 * dot(dV[i] * Py, P * (dV[j] * Py)) for i in 1:2, j in 1:2]
    EXP_ref = [0.5 * tr(P * dV[i] * P * dV[j]) for i in 1:2, j in 1:2]
    OBS_ref = 2 .* AI_ref .- EXP_ref

    cov_ai = variance_component_covariance(fit)
    cov_obs = variance_component_covariance(fit; information = :observed)
    @test cov_ai == variance_component_covariance(fit; information = :ai)
    @test isapprox(inv(cov_ai), AI_ref; rtol = 1e-8)
    @test isapprox(inv(cov_obs), OBS_ref; rtol = 1e-3)

    @test variance_component_standard_errors(fit; information = :observed).sigma_a2 ≈
          sqrt(cov_obs[1, 1])
    h_obs = heritability_standard_error(fit; information = :observed)
    @test heritability_interval(fit; information = :observed).se == h_obs
    @test variance_component_uncertainty(fit; information = :observed).covariance == cov_obs
    @test h_obs != heritability_standard_error(fit)
    @test_throws ArgumentError variance_component_covariance(fit; information = :fisher)
end
