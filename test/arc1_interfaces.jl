using Test
using HSquared

@testset "Arc1 interface boundaries" begin
    @test_throws ArgumentError arc1_profile_repeatability(
        [1.0, 2.0], ones(2, 1), ones(2, 1),
        normalize_pedigree(["a", "b"], ["0", "0"], ["0", "0"]);
        ids = ["wrong", "ids"])
    method_ped = normalize_pedigree(["a"], ["0"], ["0"])
    @test_throws ArgumentError arc1_profile_repeatability(
        [1.0, 2.0], ones(2, 1), ones(2, 1), method_ped;
        method = :arc1_profile_v2)

    @test HSquared._arc1_profile_method_version("arc1_profile_v1") === :arc1_profile_v1
    @test HSquared._arc1_profile_method_version("arc1_profile_v2") === :arc1_profile_v2
    @test HSquared._arc1_profile_method_version("arc1_profile_v3") === :arc1_profile_v3
    @test_throws ArgumentError HSquared._arc1_profile_method_version(:arc1_profile_v2)
    @test_throws ArgumentError arc1_profile_repeatability(
        [1.0, 2.0], ones(2, 1), ones(2, 1), method_ped;
        method="arc1_profile_v1", v3_evidence_sink=Dict{Symbol,Any}())
    @test_throws ArgumentError arc1_profile_repeatability(
        [1.0, 2.0], ones(2, 1), ones(2, 1), method_ped;
        method="arc1_profile_v3", v3_evidence_sink=Dict{Symbol,Int}())
    preflight_sink = Dict{Symbol,Any}()
    @test_throws ArgumentError arc1_profile_repeatability(
        [1.0, 2.0], ones(2, 1), ones(2, 1), method_ped;
        ids=["wrong"], method="arc1_profile_v3", v3_evidence_sink=preflight_sink)
    @test preflight_sink[:requested_method_version] == "arc1_profile_v3"
    @test !haskey(preflight_sink, :actual_method_version)

    fake = (method = "arc1_profile_v1", method_version = :arc1_profile_v1,
        source_identity = "same",
        reference_source_identity = "same",
        point_identity = "fit-1", reference_point_identity = "fit-1",
        # Faithful `_arc1_point_fit` result: the selected candidate retains
        # `components`, while the public profile wrapper materializes the fit.
        point_fit = (components = [0.2, 0.2, 0.6], loglik = -12.0,
                     optimizer_status = "line_search_failed", optimizer_converged = false,
                     converged = false, stopped_by = :line_search_failure,
                     line_search_failed = true, iterations = 17,
                     finite_difference_status = :failed, finite_difference_steps = (1e-4, 1e-5),
                     max_valid_loglik = -11.9, hit_bound_components = [2]),
        point_estimates = (heritability = 0.2,),
        targets = Dict(:heritability => (confidence_set = [(0.1, 0.8)],
            status = :finite_grid_resolved, formed = true)))
    rows = arc1_confint(fake)
    fake_v3 = merge(fake, (method = "arc1_profile_v3",
                           method_version = :arc1_profile_v3))
    @test length(arc1_confint(fake_v3)) == 1
    @test_throws ArgumentError arc1_confint(merge(fake_v3,
        (method_version = :arc1_profile_v2,)))
    missing_v3_identity = Base.structdiff(fake_v3, NamedTuple{(:method_version,)}((:arc1_profile_v3,)))
    @test_throws ArgumentError arc1_confint(missing_v3_identity)
    fake_v2 = merge(fake, (method = "arc1_profile_v2",
                           method_version = :arc1_profile_v2))
    @test length(arc1_confint(fake_v2)) == 1
    @test_throws ArgumentError arc1_confint(merge(fake_v2,
        (method_version = :arc1_profile_v1,)))
    @test_throws ArgumentError arc1_confint(merge(fake_v2,
        (method = "arc1_profile_v3",)))
    @test HSquared._arc1_interface_variance_components(fake.point_fit) ==
          (sigma_a2 = 0.2, sigma_pe2 = 0.2, sigma_e2 = 0.6)
    tiny_ped = normalize_pedigree(["a", "b", "c", "d"], fill("0", 4), fill("0", 4))
    tiny_y = [0.4, 0.7, -0.1, 0.2, 1.0, 1.2, -0.6, -0.2]
    tiny_X = ones(8, 1)
    tiny_Z = zeros(8, 4)
    for animal in 1:4, record in 1:2
        tiny_Z[2animal - 2 + record, animal] = 1.0
    end
    evaluated = HSquared._arc1_materialize_point_fit(tiny_y, tiny_X, tiny_Z,
        pedigree_inverse(tiny_ped), fake.point_fit)
    @test evaluated.status == :reevaluated
    evaluated_point = evaluated.fit
    @test evaluated_point.variance_components ==
          (sigma_a2 = 0.2, sigma_pe2 = 0.2, sigma_e2 = 0.6)
    @test isfinite(evaluated_point.loglik)
    @test evaluated_point.optimizer_candidate === fake.point_fit
    @test evaluated_point.optimizer_iterations == 17
    @test evaluated_point.optimizer_status == "line_search_failed"
    @test !evaluated_point.optimizer_candidate.optimizer_converged
    @test evaluated_point.optimizer_candidate.stopped_by == :line_search_failure
    @test evaluated_point.optimizer_candidate.line_search_failed
    @test evaluated_point.optimizer_candidate.finite_difference_status == :failed
    @test evaluated_point.optimizer_candidate.max_valid_loglik == -11.9
    failed_materialization = HSquared._arc1_materialize_point_fit(tiny_y, tiny_X, tiny_Z,
        pedigree_inverse(tiny_ped), merge(fake.point_fit, (; components=[0.2, 0.2, 0.0])))
    @test failed_materialization.fit === nothing
    @test failed_materialization.status == :reevaluation_failed
    @test failed_materialization.candidate.components == [0.2, 0.2, 0.0]
    @test failed_materialization.reason !== nothing
    wrapper_result = merge(fake, (; point_fit=evaluated_point,
        point_estimates=(heritability=0.2,)))
    @test arc1_confint(wrapper_result)[1].estimate == 0.2
    unavailable_point = merge(fake, (; point_fit=nothing, point_estimates=nothing,
        point_identity=nothing, reference_point_identity=nothing,
        targets=Dict(:heritability => (confidence_set=nothing, status=:point_fit_unconverged,
                                       formed=false))))
    unavailable_row = only(arc1_confint(unavailable_point))
    @test !unavailable_row.formed
    @test ismissing(unavailable_row.estimate)
    @test length(rows) == 1
    @test rows[1].estimand == "heritability"
    @test rows[1].estimate == 0.2
    @test (rows[1].lower, rows[1].upper, rows[1].formed) == (0.1, 0.8, true)

    disconnected = merge(fake, (targets = Dict(:heritability =>
        (confidence_set = [(0.1, 0.3), (0.6, 0.8)], status = :finite_grid_resolved,
         formed = true)),))
    disconnected_rows = arc1_confint(disconnected)
    @test length(disconnected_rows) == 2
    @test [r.segment for r in disconnected_rows] == [1, 2]
    @test [(r.lower, r.upper) for r in disconnected_rows] == [(0.1, 0.3), (0.6, 0.8)]

    refused_with_segments = merge(fake, (targets = Dict(:heritability =>
        (confidence_set = [(0.1, 0.8)], status = :nuisance_unresolved,
         formed = false)),))
    refused_rows = arc1_confint(refused_with_segments)
    @test length(refused_rows) == 1
    @test !refused_rows[1].formed
    @test ismissing(refused_rows[1].lower) && ismissing(refused_rows[1].upper)

    refused_empty = merge(fake, (targets = Dict(:heritability =>
        (confidence_set = Tuple{Float64,Float64}[], status = :nuisance_unresolved,
         formed = false)),))
    refused_empty_row = only(arc1_confint(refused_empty))
    @test !refused_empty_row.formed
    @test ismissing(refused_empty_row.lower) && ismissing(refused_empty_row.upper)

    formed_without_set = merge(fake, (targets = Dict(:heritability =>
        (confidence_set = nothing, status = :finite_grid_resolved, formed = true)),))
    inconsistent_row = only(arc1_confint(formed_without_set))
    @test !inconsistent_row.formed
    @test ismissing(inconsistent_row.lower) && ismissing(inconsistent_row.upper)
    @test inconsistent_row.status == "inconsistent_formed_state"

    wrong_point = merge(fake, (point_estimates = (heritability = 0.4,),))
    @test_throws ArgumentError arc1_confint(wrong_point)

    inconsistent = merge(fake, (targets = Dict(:heritability =>
        (confidence_set = [(0.1, 0.8)], status = :finite_grid_resolved,
         formed = true)), point_identity = "fit-2"))
    @test_throws ArgumentError arc1_confint(inconsistent)

    mismatched = merge(fake, (reference_source_identity = "different",))
    @test_throws ArgumentError arc1_confint(mismatched)
end
