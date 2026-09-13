# test_212_engine_controls.jl — hsquared#212 engine half
#
# Defect: documented `engine_control$initial` / `$iterations` are silently dropped
# for payload-v2 `:multi_effect` and `:direct_maternal` dispatch (both hardcode the
# engine call with no `initial`/`iterations`), and `iterations` is dropped for
# `fit_single_step_reml` / `fit_metafounder_single_step_reml` (no formal parameter,
# structurally unreachable down to `fit_gblup_reml` -> `fit_ai_reml`).
# Issue: https://github.com/itchyshin/hsquared/issues/212
#
# This file is TDD red-first: on the pre-fix engine it fails with a MethodError
# (fit_payload_v2 does not accept initial=/iterations=) for (a), and with silently
# unchanged fits for (b)/(c) once the kwargs exist structurally but are not threaded.
#
# CONTRACT-ONLY: reuses existing estimators; no covered-status change.

using HSquared
using Test
using LinearAlgebra
using SparseArrays

@testset "hsquared#212 engine controls: initial/iterations threading" begin
    # Shared small pedigree fixture (same as the P0.3 payload-v2 testset).
    ped_ids  = [1, 2, 3, 4]
    ped_sire = [0, 0, 1, 1]
    ped_dam  = [0, 0, 2, 2]
    Ainv_direct = pedigree_inverse(ped_ids, ped_sire, ped_dam)

    Z_animal = zeros(8, 4)
    for (rec, an) in enumerate([1, 1, 2, 2, 3, 3, 4, 4]); Z_animal[rec, an] = 1.0; end
    y_obs = [14.0, 13.0, 6.9, 6.1, 12.1, 11.5, 8.9, 8.5]
    X_int = ones(8, 1)
    pedigree_rows = Dict("id" => ped_ids, "sire" => ped_sire, "dam" => ped_dam)

    # -----------------------------------------------------------------------
    # (a) :multi_effect — initial/iterations must reach fit_multi_effect_reml
    # -----------------------------------------------------------------------
    @testset "(a) multi_effect payload honours initial/iterations" begin
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

        fit_default = fit_payload_v2(payload_three)

        # Extreme initial + a single iteration: if honoured, must move far from
        # the well-converged default. If ignored, identical to fit_default.
        extreme_initial = [500.0, 500.0, 500.0, 500.0]  # K=2 effects + residual
        fit_probe = fit_payload_v2(payload_three; initial = extreme_initial, iterations = 1)

        sig_default = vcat(fit_default.variance_components.sigmas, fit_default.variance_components.sigma_e2)
        sig_probe = vcat(fit_probe.variance_components.sigmas, fit_probe.variance_components.sigma_e2)
        max_rel_diff = maximum(abs.(sig_probe .- sig_default) ./ max.(abs.(sig_default), 1e-8))
        @test max_rel_diff > 0.0

        # Default call (no kwargs) stays byte-identical to the pre-fix behaviour:
        # fit_multi_effect_reml with its own defaults (initial=nothing -> zeros(K+1), iterations=200).
        I2 = Matrix(I, 2, 2)
        fit_ref = fit_multi_effect_reml(y_obs, X_int,
                                        [(Z_animal, Matrix(Ainv_direct)), (Z_g1, I2), (Z_g2, I2)])
        @test fit_default.variance_components.sigmas == fit_ref.variance_components.sigmas
        @test fit_default.variance_components.sigma_e2 == fit_ref.variance_components.sigma_e2
    end

    # -----------------------------------------------------------------------
    # (b) :direct_maternal — initial/iterations must reach fit_direct_maternal_reml
    # -----------------------------------------------------------------------
    @testset "(b) direct_maternal payload honours initial/iterations" begin
        Zd = Z_animal
        Zm = zeros(8, 4)
        for (rec, dm) in enumerate([1, 2, 1, 2, 1, 2, 1, 2]); Zm[rec, dm] = 1.0; end

        payload_dm = Dict(
            "payload_version" => 2,
            "y" => y_obs,
            "X" => X_int,
            "random_effects" => [
                Dict(
                    "name"              => "animal",
                    "type"              => "correlated",
                    "Z"                 => Zd,
                    "relmat_status"     => "build_in_julia",
                    "pedigree"          => pedigree_rows,
                    "ids"               => ped_ids,
                    "partner_incidence" => Zm,
                    "partner_name"      => "maternal",
                ),
            ],
        )

        fit_default = fit_payload_v2(payload_dm)

        extreme_initial = (G_dm = [500.0 0.0; 0.0 500.0], sigma_e2 = 500.0)
        fit_probe = fit_payload_v2(payload_dm; initial = extreme_initial, iterations = 1)

        vc_default = fit_default.variance_components
        vc_probe = fit_probe.variance_components
        default_vec = [vc_default.sigma_ad, vc_default.sigma_am, vc_default.sigma_dm, vc_default.sigma_e2]
        probe_vec = [vc_probe.sigma_ad, vc_probe.sigma_am, vc_probe.sigma_dm, vc_probe.sigma_e2]
        max_rel_diff = maximum(abs.(probe_vec .- default_vec) ./ max.(abs.(default_vec), 1e-8))
        @test max_rel_diff > 0.0

        # Default call (no kwargs) stays byte-identical to fit_direct_maternal_reml's own defaults.
        fit_ref = fit_direct_maternal_reml(y_obs, X_int, Zd, Zm, Matrix(Ainv_direct))
        @test fit_default.variance_components.sigma_ad == fit_ref.variance_components.sigma_ad
        @test fit_default.variance_components.sigma_am == fit_ref.variance_components.sigma_am
        @test fit_default.variance_components.sigma_e2 == fit_ref.variance_components.sigma_e2
    end

    # -----------------------------------------------------------------------
    # (c) fit_single_step_reml — iterations must reach fit_gblup_reml -> fit_ai_reml
    # -----------------------------------------------------------------------
    @testset "(c) fit_single_step_reml honours iterations" begin
        A = inv(Symmetric(Matrix(Ainv_direct)))
        G = A[3:4, 3:4]  # G = A22 reduction: genotyped rows 3,4
        genotyped_rows = [3, 4]

        fit_default = fit_single_step_reml(y_obs, X_int, Z_animal, Matrix(Ainv_direct), A, G, genotyped_rows)
        fit_one_iter = fit_single_step_reml(y_obs, X_int, Z_animal, Matrix(Ainv_direct), A, G, genotyped_rows;
                                            initial = (sigma_a2 = 1.0e6, sigma_e2 = 1.0e6), iterations = 1)

        @test fit_one_iter.converged == false
        vc_default = fit_default.variance_components
        vc_one = fit_one_iter.variance_components
        max_rel_diff = max(
            abs(vc_one.sigma_a2 - vc_default.sigma_a2) / max(abs(vc_default.sigma_a2), 1e-8),
            abs(vc_one.sigma_e2 - vc_default.sigma_e2) / max(abs(vc_default.sigma_e2), 1e-8),
        )
        @test max_rel_diff > 0.0

        # Default call unchanged: byte-identical to calling fit_gblup_reml directly with
        # fit_single_step_reml's own default target (:ai_reml) and no iterations override.
        Hinv = single_step_inverse(Matrix(Ainv_direct), A, G, genotyped_rows)
        fit_ref = fit_gblup_reml(y_obs, X_int, Z_animal, Hinv)
        @test fit_default.variance_components.sigma_a2 == fit_ref.variance_components.sigma_a2
        @test fit_default.variance_components.sigma_e2 == fit_ref.variance_components.sigma_e2
    end

    # -----------------------------------------------------------------------
    # (d) fit_metafounder_single_step_reml — iterations must reach fit_gblup_reml -> fit_ai_reml
    # -----------------------------------------------------------------------
    @testset "(d) fit_metafounder_single_step_reml honours iterations" begin
        ped = normalize_pedigree(ped_ids, ped_sire, ped_dam)
        group_of = [1, 1, 1, 1]  # single metafounder group, Gamma = 0 -> classical reduction
        Gamma = zeros(1, 1)
        A = inv(Symmetric(Matrix(Ainv_direct)))
        G = A[3:4, 3:4]
        genotyped_rows = [3, 4]

        fit_default = fit_metafounder_single_step_reml(y_obs, X_int, Z_animal, ped, group_of, Gamma, G, genotyped_rows)
        fit_one_iter = fit_metafounder_single_step_reml(y_obs, X_int, Z_animal, ped, group_of, Gamma, G, genotyped_rows;
                                                         initial = (sigma_a2 = 1.0e6, sigma_e2 = 1.0e6), iterations = 1)

        @test fit_one_iter.converged == false
        vc_default = fit_default.variance_components
        vc_one = fit_one_iter.variance_components
        max_rel_diff = max(
            abs(vc_one.sigma_a2 - vc_default.sigma_a2) / max(abs(vc_default.sigma_a2), 1e-8),
            abs(vc_one.sigma_e2 - vc_default.sigma_e2) / max(abs(vc_default.sigma_e2), 1e-8),
        )
        @test max_rel_diff > 0.0

        # Default call unchanged: byte-identical to calling fit_metafounder_single_step_reml
        # with no iterations override (already true by construction; this pins it against
        # future kwarg-threading regressions).
        fit_ref = fit_metafounder_single_step_reml(y_obs, X_int, Z_animal, ped, group_of, Gamma, G, genotyped_rows)
        @test fit_default.variance_components.sigma_a2 == fit_ref.variance_components.sigma_a2
        @test fit_default.variance_components.sigma_e2 == fit_ref.variance_components.sigma_e2
    end
end
