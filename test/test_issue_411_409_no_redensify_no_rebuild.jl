# HSquared.jl #411 and #409.
# #411: a refitting dense *_interval call forms each dense A = inv(Ainv) once
# (in the fit) and reuses it for the finite-difference information, instead of
# inverting Ainv a second time.
# #409: the profile intervals keep one MME workspace (cross products, pattern and
# symbolic factorisation) per interval instead of assembling the MME from scratch
# at every evaluation.
# Reference values were recorded from main (8f58b13a) before the change.
# Standalone: julia --project=. test/test_issue_411_409_no_redensify_no_rebuild.jl

using HSquared
using LinearAlgebra
using Random
using SparseArrays
using Test

isdefined(@__MODULE__, :_issue411_repeatability_fixture) ||
    include(joinpath(@__DIR__, "test_issue_411_interval_from_fit.jl"))

function _issue411_inverse_count(f)
    counter = HSquared._DENSE_RELATIONSHIP_INVERSES
    before = counter[]
    value = f()
    return value, counter[] - before
end

@testset "#411: refitting intervals invert each Ainv once" begin
    y, X, Z, Ainv = _issue411_repeatability_fixture()
    r, k = _issue411_inverse_count(() -> repeatability_interval(y, X, Z, Ainv; iterations = 2000))
    @test k == 1
    fit = fit_repeatability_reml(y, X, Z, Ainv; iterations = 2000)
    @test r == repeatability_interval(fit, y, X, Z, Ainv)

    y2, X2, Z1, A1, Z2, A2 = _issue411_two_effect_fixture()
    r2, k2 = _issue411_inverse_count(() -> two_effect_ratio_interval(y2, X2, Z1, A1, Z2, A2))
    @test k2 == 2
    fit2 = fit_two_effect_reml(y2, X2, Z1, A1, Z2, A2)
    @test r2 == two_effect_ratio_interval(fit2, y2, X2, Z1, A1, Z2, A2)

    effects = [(Z1, A1), (Z2, A2)]
    rm, km = _issue411_inverse_count(() -> multi_effect_ratio_interval(y2, X2, effects))
    @test km == 2
    # K = 2 reduction: same estimand and information as the two-effect path.
    # rtol = 1e-3: the two paths are separate REML fits, each stopping at its own
    # convergence tolerance (on main 8f58b13a they differ by about 2e-5 relative),
    # so this checks the same estimand, not bitwise agreement.
    @test rm.ratios[1].lower ≈ r2.ratio1.lower rtol = 1e-3
    @test rm.ratios[2].upper ≈ r2.ratio2.upper rtol = 1e-3

    rng = MersenneTwister(7)
    Zm = Z[:, randperm(rng, size(Ainv, 1))]
    rd, kd = _issue411_inverse_count(() -> direct_maternal_interval(y, X, Z, Zm, Ainv))
    @test kd == 1
    fitd = fit_direct_maternal_reml(y, X, Z, Zm, Ainv)
    @test rd == direct_maternal_interval(fitd, y, X, Z, Zm, Ainv)
end

@testset "#409: profile intervals do not rebuild the MME per evaluation" begin
    nanim = 120
    ids = ["a$i" for i in 1:nanim]
    sire = [i <= 10 ? "0" : "a$(1 + i % 5)" for i in 1:nanim]
    dam = [i <= 10 ? "0" : "a$(6 + i % 5)" for i in 1:nanim]
    ped = normalize_pedigree(ids, sire, dam)
    Ainv = pedigree_inverse(ped)
    a = cholesky(Symmetric(Matrix(Ainv))).L \ [sin(1.3 * i) for i in 1:nanim]
    y = 10 .+ 1.2 .* a .+ [1.4 * cos(2.1 * i + 0.3) for i in 1:nanim]
    spec = animal_model_spec(y, ones(nanim, 1), sparse(1.0I, nanim, nanim), Ainv;
                             ids = ped.ids, method = :REML)
    fit = fit_sparse_reml(spec)

    assemblies = HSquared._SPARSE_MME_ASSEMBLIES
    evals = HSquared._SPARSE_REML_EVALS
    assemblies[] = 0; evals[] = 0
    v = variance_component_interval(fit)
    @test evals[] > 100            # the inner search still runs ...
    @test assemblies[] <= 1        # ... on one workspace, not ~2000 fresh MMEs
    @test v.lower ≈ 0.27537247800893666 atol = 1e-8
    @test v.upper ≈ 2.2347502463905724 atol = 1e-8
    @test !v.lower_clamped && !v.upper_clamped

    assemblies[] = 0
    h = heritability_interval(fit; method = :profile)
    @test assemblies[] <= 1
    @test h.lower ≈ 0.15389657583498323 atol = 1e-8
    @test h.upper ≈ 0.7888320549602477 atol = 1e-8

    # The profile itself is unchanged at fixed sigma_a2.
    for (s, ref) in ((0.3, -204.5595597255197), (1.0, -202.9115235837914),
                     (2.5, -205.5376595330543))
        @test HSquared._profile_reml_loglik_sigma_a2(spec, s) ≈ ref atol = 1e-9
    end
    # A workspace evaluation equals the public evaluator at the same point.
    ctx = HSquared._profile_reml_context(spec)
    @test HSquared._profile_reml_eval(ctx, 0.8, 1.1).loglik ≈
          sparse_reml_loglik(spec, 0.8, 1.1).loglik rtol = 1e-12
end
