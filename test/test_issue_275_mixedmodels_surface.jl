# HSquared.jl #275 - MixedModels.jl as a Julia-native benchmark lane.
#
# The MixedModels leg itself is opt-in (HSQUARED_RUN_MIXEDMODELS=true, separate
# environment in comparator/mixedmodels_lmm/). What the suite checks without it:
# the shared-surface generator is deterministic, the engine matches an independent
# closed-form REML oracle on the surface, and the agreement arithmetic refuses to
# call non-converged or out-of-tolerance fits agreement.
# Standalone:
# julia --project=. -e 'include("test/test_issue_275_mixedmodels_surface.jl")'

using HSquared
using Test

include(joinpath(@__DIR__, "..", "comparator", "mixedmodels_lmm", "lmm_surface.jl"))
using .HSquaredMixedModelsSurface

@testset "HSquared.jl #275 MixedModels.jl shared LMM surface" begin
    @testset "scenarios are predeclared, deterministic and on the shared surface" begin
        @test length(SCENARIOS) >= 4
        @test allunique(sc.name for sc in SCENARIOS)
        @test allunique(sc.seed for sc in SCENARIOS)
        # Surface limit: only iid random intercepts (one factor or two crossed).
        @test all(length(sc.ngroups) in (1, 2) for sc in SCENARIOS)
        @test all(length(sc.sigmas) == length(sc.ngroups) for sc in SCENARIOS)
        sc = SCENARIOS[2]
        a = simulate_lmm(sc)
        b = simulate_lmm(sc)
        @test a.y == b.y
        @test a.X == b.X
        @test a.groups == b.groups
        @test size(a.X) == (sc.n, length(sc.beta))
        @test all(maximum(g) <= m for (g, m) in zip(a.groups, sc.ngroups))
        # Intercept-only scenario really drops the covariate.
        @test size(simulate_lmm(SCENARIOS[1]).X, 2) == 1
    end

    @testset "the opt-in gate is off unless explicitly requested" begin
        withenv("HSQUARED_RUN_MIXEDMODELS" => nothing) do
            @test !mixedmodels_lane_enabled()
        end
        withenv("HSQUARED_RUN_MIXEDMODELS" => "1") do
            @test !mixedmodels_lane_enabled()
        end
        withenv("HSQUARED_RUN_MIXEDMODELS" => "true") do
            @test mixedmodels_lane_enabled()
        end
    end

    @testset "engine matches the closed-form ANOVA REML oracle (no MixedModels needed)" begin
        sc = SCENARIOS[1]
        @test sc.balanced
        d = simulate_lmm(sc)
        oracle = anova_oracle_one_way(d.y, d.groups[1])
        fit = engine_lmm_fit(d)
        @test fit.converged
        @test fit.sigmas[1] ≈ oracle.sigma_g2 rtol = 1e-6
        @test fit.sigma_e2 ≈ oracle.sigma_e2 rtol = 1e-6
        @test fit.beta[1] ≈ oracle.beta0 rtol = 1e-9
        # Oracle refuses designs it does not cover rather than answer wrongly.
        @test_throws ArgumentError anova_oracle_one_way(d.y[1:end-1], d.groups[1][1:end-1])
    end

    @testset "agreement arithmetic" begin
        fit = (sigmas = [0.64, 0.25], sigma_e2 = 1.0, beta = [2.0, 0.5], converged = true)
        same = compare_lmm(fit, fit)
        @test same.agree
        @test same.both_converged
        @test length(same.rows) == 2 + 1 + 2
        @test all(r.reldiff == 0 for r in same.rows)

        off = merge(fit, (sigmas = [0.64 * 1.01, 0.25],))
        res = compare_lmm(fit, off)
        @test !res.agree
        @test res.both_converged
        @test count(r -> !r.pass, res.rows) == 1
        @test only(r for r in res.rows if !r.pass).quantity == "sigma_g1_2"

        # Within tolerance passes; the tolerance is an argument, not a hidden constant.
        near = merge(fit, (sigma_e2 = 1.0 + 1e-5,))
        @test compare_lmm(fit, near).agree
        @test !compare_lmm(fit, near; rtol_var = 1e-7).agree

        # Non-converged on either side is never agreement, even with identical numbers.
        nc = merge(fit, (converged = false,))
        @test !compare_lmm(fit, nc).agree
        @test !compare_lmm(nc, fit).agree
        @test !compare_lmm(fit, nc).both_converged

        # Mismatched shapes are an error, not a silent truncation.
        @test_throws ArgumentError compare_lmm(fit, merge(fit, (sigmas = [0.64],)))
        @test_throws ArgumentError compare_lmm(fit, merge(fit, (beta = [2.0],)))
    end
end
