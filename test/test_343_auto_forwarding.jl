# test_343_auto_forwarding.jl — follow-on to hsquared#212 / #337
#
# Defect: `_dispatch_fit`'s `:multi_effect` arm forwards `initial`/`iterations` to the
# dense fitter (`scale_method = :dense`) but silently drops both on the opt-in
# `scale_method = :auto` route, even though `fit_multi_effect` forwards `kwargs...` to
# both of its branches (`fit_sparse_multi_effect_aireml` and `fit_multi_effect_mc_reml`,
# both of which accept `initial`/`iterations`). PR #337 fixed the misleading comment but
# left this forwarding gap out of scope.
# Issue: https://github.com/itchyshin/HSquared.jl/issues/343
#
# This file is TDD red-first: on the pre-fix engine, (a) still passes (the default call
# never used the kwargs) but (b) fails because the `:auto` probe is silently identical
# to the default fit.
#
# CONTRACT-ONLY: reuses existing estimators; no covered-status change.

using HSquared
using Test
using LinearAlgebra
using SparseArrays

@testset "#343 engine controls: initial/iterations on the :multi_effect :auto path" begin
    # Shared small pedigree fixture (same shape as the #212 payload-v2 testset) so the
    # sparse AI-REML `:auto` path runs in well under a second.
    ped_ids  = [1, 2, 3, 4]
    ped_sire = [0, 0, 1, 1]
    ped_dam  = [0, 0, 2, 2]
    Ainv_direct = pedigree_inverse(ped_ids, ped_sire, ped_dam)

    Z_animal = zeros(8, 4)
    for (rec, an) in enumerate([1, 1, 2, 2, 3, 3, 4, 4]); Z_animal[rec, an] = 1.0; end
    y_obs = [14.0, 13.0, 6.9, 6.1, 12.1, 11.5, 8.9, 8.5]
    X_int = ones(8, 1)
    pedigree_rows = Dict("id" => ped_ids, "sire" => ped_sire, "dam" => ped_dam)

    Z_g1 = [1.0 0; 1 0; 0 1; 0 1; 1 0; 0 1; 1 0; 0 1]
    Z_g2 = [1.0 0; 0 1; 1 0; 0 1; 1 0; 0 1; 0 1; 1 0]
    payload_three = Dict(
        "payload_version" => 2,
        "y" => y_obs,
        "X" => X_int,
        "random_effects" => [
            Dict("name" => "animal", "type" => "pedigree",
                 "Z" => Z_animal, "relmat_status" => "build_in_julia",
                 "pedigree" => pedigree_rows, "ids" => ped_ids),
            Dict("name" => "litter",  "type" => "iid",
                 "Z" => Z_g1, "relmat_status" => "identity", "ids" => [1, 2]),
            Dict("name" => "pen",     "type" => "iid",
                 "Z" => Z_g2, "relmat_status" => "identity", "ids" => [1, 2]),
        ],
    )

    I2 = Matrix(I, 2, 2)
    effects_direct = [(Z_animal, Matrix(Ainv_direct)), (Z_g1, I2), (Z_g2, I2)]
    per_block_ids = [ped_ids, [1, 2], [1, 2]]

    # -----------------------------------------------------------------------
    # (a) default call unchanged: fit_payload_v2(...; scale_method = :auto) with no
    # initial/iterations kwargs stays byte-identical to a direct fit_multi_effect(...;
    # method = :auto) call with its own defaults.
    # -----------------------------------------------------------------------
    @testset "(a) default :auto call unchanged" begin
        fit_default = fit_payload_v2(payload_three; scale_method = :auto)
        fit_ref = fit_multi_effect(y_obs, X_int, effects_direct; method = :auto,
                                   ids = per_block_ids, compute_loglik = true, verbose = false)

        sig_default = vcat(fit_default.variance_components.sigmas, fit_default.variance_components.sigma_e2)
        sig_ref = vcat(fit_ref.variance_components.sigmas, fit_ref.variance_components.sigma_e2)
        @test maximum(abs.(sig_default .- sig_ref)) < 1e-10
    end

    # -----------------------------------------------------------------------
    # (b) initial/iterations forwarded on the :auto path: an extreme initial + a single
    # iteration must move the result away from the well-converged default, and must
    # match a direct fit_multi_effect(...; method = :auto, initial = ..., iterations = 1)
    # call exactly (the stronger parity check).
    # -----------------------------------------------------------------------
    @testset "(b) initial/iterations forwarded on the :auto path" begin
        extreme_initial = [500.0, 500.0, 500.0, 500.0]  # K=3 effects + residual

        fit_default = fit_payload_v2(payload_three; scale_method = :auto)
        fit_probe = fit_payload_v2(payload_three; scale_method = :auto,
                                   initial = extreme_initial, iterations = 1)

        sig_default = vcat(fit_default.variance_components.sigmas, fit_default.variance_components.sigma_e2)
        sig_probe = vcat(fit_probe.variance_components.sigmas, fit_probe.variance_components.sigma_e2)
        max_rel_diff = maximum(abs.(sig_probe .- sig_default) ./ max.(abs.(sig_default), 1e-8))
        @test max_rel_diff > 0.0

        fit_direct = fit_multi_effect(y_obs, X_int, effects_direct; method = :auto,
                                      ids = per_block_ids, compute_loglik = true, verbose = false,
                                      initial = extreme_initial, iterations = 1)
        sig_direct = vcat(fit_direct.variance_components.sigmas, fit_direct.variance_components.sigma_e2)
        @test maximum(abs.(sig_probe .- sig_direct)) < 1e-10
    end
end
