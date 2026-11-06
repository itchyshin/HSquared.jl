using Test, LinearAlgebra, SparseArrays, SHA, HSquared

const V4 = HSquared
const ARC1_PROFILE_SOURCE = joinpath(@__DIR__, "..", "src", "arc1_profiles.jl")
isdefined(V4, :_arc1_profile_context) || Base.include(V4, ARC1_PROFILE_SOURCE)

@testset "Arc1 profile v4 engine-path tail screen" begin
    @testset "retained paired designs N=$n" for n in (160, 320)
        # Construct the one-intercept, two-record-per-animal design used by
        # the repeatability model. An injected evaluator keeps this bounded;
        # context construction and v4 certification use production code.
        records = 2n
        Z = sparse(1:records, repeat(1:n, inner=2), ones(records), records, n)
        X = ones(records, 1)
        y = [0.4 + 0.15sin(0.17i) + 0.08cos(0.031i) +
             0.2 * (isodd(i) ? 1.0 : -1.0) for i in 1:records]
        Ainv = Matrix{Float64}(I, n, n)
        context = V4._arc1_profile_context(y, X, Z, Ainv)
        @test context.profile_v4_design_data.status == :ok
        point = V4._arc1_profile_reml(context, 0.3, 0.2, 0.5)
        @test point.status == :ok
        state = V4._Arc1ProfileState(merge(context, (; method_version=:arc1_profile_v4)),
            1.0, point.loglik, Dict{Symbol,Dict{Float64,Any}}(),
            Dict{Symbol,Int}(), point.loglik, Any[], :arc1_profile_v4)
        calls = Float64[]
        evaluator = value -> begin
            push!(calls, value)
            (; status=:ok, loglik=point.loglik - 10.0, nuisance_statuses=Any[])
        end
        found = V4._arc1_target_search(state, :residual_variance, 0.5;
            profile_evaluator=evaluator)
        certificate = found.tail_screen.certificate
        @test found.tail_screen.method == :uniform_residual_tail_bound
        @test found.tail_screen.passed && found.tail_screen.cap_reached
        @test certificate.certified
        @test certificate.residual_df == 2n - 1
        @test certificate.determinant == context.profile_v4_design_data.determinant
        @test certificate.design_identity == bytes2hex(sha256(
            reinterpret(UInt8, vec(Matrix{Float64}(context.transformed_design)))))
        @test !isempty(calls)
        @test all(x -> x < certificate.E, calls)
        @test found.tail_screen.cap == certificate.E

        shared_history = Any[]
        evidence_sink = Dict{Symbol,Any}(
            :arc1_profile_v3_evaluations => shared_history,
            :arc1_profile_v4_evaluations => shared_history,
            :v4_tail_certificates => Any[])
        @test_throws InterruptException V4._arc1_target_search(state,
            :residual_variance, 0.5;
            profile_evaluator = _ -> throw(InterruptException()),
            v3_evidence_sink = evidence_sink)
        @test length(evidence_sink[:v4_tail_certificates]) == 1
        retained = only(evidence_sink[:v4_tail_certificates])
        @test retained.target === :residual_variance
        @test retained.certificate === certificate || retained.certificate.certified
    end
end

@testset "Arc1 profile v4 bounded controls" begin
    @testset "v4 dispatches centered positive-bound mismatch through continuation and corner" begin
        n = 8
        records_count = 2n
        Z = sparse(1:records_count, repeat(1:n, inner=2), ones(records_count),
            records_count, n)
        X = ones(records_count, 1)
        y = [0.4 + 0.15sin(0.17i) + 0.08cos(0.031i) for i in 1:records_count]
        context = V4._arc1_profile_context(y, X, Z, Matrix{Float64}(I, n, n))
        ve = 0.5
        shared_winner_score = V4._arc1_profile_centered_loglik_at(context,
            [0.0, 0.0, ve], ve).loglik
        contact_value = 2.0^-40
        bfgs_calls = Ref(0)
        continuation_calls = Ref(0)

        function candidate_record(base, free, components; converged, hit_bound)
            contacts = hit_bound ? [(component = 1, side = :lower,
                value = contact_value, log_value = log(contact_value))] : Any[]
            return (loglik = -10.0, max_valid_loglik = -10.0,
                centered_loglik = -10.0, max_valid_centered_loglik = -10.0,
                centering_ve = ve, components, converged,
                optimizer_converged = true, optimizer_status = "converged",
                termination_code = V4.Optim.TerminationCode.NoObjectiveChange,
                analytic_gradient_valid = true, line_search_failed = false,
                gradient_norm = 0.0, iterations = 5, free_indices = copy(free),
                finite_difference_errors = hit_bound ? Dict(1 => Inf, 2 => 0.0) :
                    Dict(1 => 0.0, 2 => 0.0), hit_bound,
                hit_bound_components = contacts)
        end
        function controlled_bfgs(ctx, base, free, start, scale)
            bfgs_calls[] += 1
            if bfgs_calls[] <= 2
                return candidate_record(base, free,
                    [contact_value, 0.75, ve]; converged = false, hit_bound = true)
            end
            return candidate_record(base, free, [0.5, 0.5, ve];
                converged = true, hit_bound = false)
        end
        function controlled_scalar(ctx, make_components, scale; held_zero_component,
                kwargs...)
            value = held_zero_component == 1 ? 0.75 : 0.5
            components = make_components(value)
            face_score = held_zero_component == 1 ? -9.0 : -10.5
            return (status = :ok, value, loglik = -10.0,
                max_valid_loglik = -10.0, components, centered_loglik = face_score,
                max_valid_centered_loglik = face_score, centering_ve = ve,
                converged = true, gradient_norm = 0.0, optimizer_status = "converged",
                hit_bound = false, candidates = Any[])
        end
        function initial_certificate(args...; kwargs...)
            if haskey(kwargs, :centered_loglik_at) &&
               kwargs[:centered_loglik_at] !== nothing
                kwargs[:centered_loglik_at]([contact_value, 0.75, ve])
                kwargs[:centered_loglik_at]([2contact_value, 0.7, ve])
            end
            (status = :face_likelihood_mismatch, zero_indices = [1],
             likelihood_spread_centered = 1.0, centered_active = true,
             centering_ve = ve,
             observations = Any[(kind = :centered, value = -10.1,
                 status = :returned, evaluation_valid = true, centering_ve = ve)])
        end
        function controlled_continuation(ctx, base, free, start, scale, allowance)
            continuation_calls[] += 1
            components = copy(base)
            components[only(free)] = contact_value
            return (loglik = -10.0, max_valid_loglik = -10.0,
                centered_loglik = -10.0, max_valid_centered_loglik = -10.0,
                centering_ve = ve, components, converged = false,
                optimizer_converged = true, optimizer_status = "converged",
                termination_code = V4.Optim.TerminationCode.GradientNorm,
                analytic_gradient_valid = true, line_search_failed = false,
                gradient_norm = 0.0, iterations = 1, free_indices = copy(free),
                finite_difference_errors = Dict(only(free) => Inf), hit_bound = true,
                hit_bound_components = [(component = only(free), side = :lower,
                    value = contact_value, log_value = log(contact_value))])
        end
        function run_version(version)
            bfgs_calls[] = 0
            continuation_calls[] = 0
            V4._arc1_raw_nuisance(context, :residual_variance, ve, 1.0;
                method_version = version, bfgs_runner = controlled_bfgs,
                scalar_profile_runner = controlled_scalar,
                certificate_runner = initial_certificate,
                refinement_runner = controlled_continuation,
                loglik_runner = (ctx, components) -> (-10.0, :ok),
                gradient_runner = (ctx, components; free_indices = 1:3) ->
                    (loglik = -10.0, component_gradient = [1e-5, 1e-5, 0.0],
                     log_gradient = zeros(length(free_indices))))
        end
        result = run_version(:arc1_profile_v4)

        @test bfgs_calls[] == length(V4._ARC1_START_MULTIPLIERS)^2
        @test continuation_calls[] > 0
        summary = only(result.nuisance_statuses)
        first_candidate_history = only(filter(h -> h.candidate_id == 1,
            summary.v4_candidate_histories))
        second_candidate_history = only(filter(h -> h.candidate_id == 2,
            summary.v4_candidate_histories))
        callback_history = filter(event -> event[:kind] === :centered,
            first_candidate_history.observations)
        @test length(callback_history) >= 2
        @test all(event -> event[:owner] === :candidate && event[:candidate_id] == 1,
            callback_history)
        @test length(unique(event[:source_id] for event in callback_history)) ==
            length(callback_history)
        candidate_corner_callbacks = filter(first_candidate_history.observations) do event
            label = get(event, :label, nothing)
            label === :returned_terminal_centered ||
                (label isa Symbol && startswith(String(label), "fd") &&
                 endswith(String(label), "_centered"))
        end
        @test any(event -> get(event, :label, nothing) ===
            :returned_terminal_centered, candidate_corner_callbacks)
        @test any(event -> begin
            label = get(event, :label, nothing)
            label isa Symbol && startswith(String(label), "fd") &&
                endswith(String(label), "_centered")
        end, candidate_corner_callbacks)
        @test all(event -> event[:owner] === :candidate &&
            event[:candidate_id] == 1, candidate_corner_callbacks)
        @test all(event -> any(record -> record.value == event[:value],
            first_candidate_history.comparison_records), candidate_corner_callbacks)
        producer_history = filter(item -> item.path ==
            "candidate[1].initial_certificate.observations[1]",
            first_candidate_history.producer_history)
        @test length(producer_history) == 1
        @test only(producer_history).owner === :candidate
        @test only(producer_history).candidate_id == 1
        @test any(record -> record.value == -10.1,
            first_candidate_history.comparison_records)
        @test !any(record -> record.value == shared_winner_score,
            first_candidate_history.comparison_records)
        @test !any(event -> get(event, :value, missing) == shared_winner_score,
            first_candidate_history.observations)
        @test !any(item -> V4._arc1_profile_v3_has(item.record, :owner) &&
            V4._arc1_profile_v3_get(item.record, :owner) === :shared,
            first_candidate_history.producer_history)
        @test any(record -> record.source_id ==
            (:exact_zero_intersection, :residual_variance, ve) &&
            record.value == shared_winner_score,
            summary.v4_shared_history)
        @test summary.best_certified.producer_source_id ==
            (:exact_zero_intersection, :residual_variance, ve)
        for history in (first_candidate_history, second_candidate_history)
            @test all(event -> event[:owner] === :candidate &&
                event[:candidate_id] == history.candidate_id, history.observations)
            @test all(item -> item.owner === :candidate &&
                item.candidate_id == history.candidate_id, history.producer_history)
            @test !any(item -> V4._arc1_profile_v3_has(item.record, :owner) &&
                V4._arc1_profile_v3_get(item.record, :owner) === :shared,
                history.producer_history)
            @test !any(record -> record.value == shared_winner_score,
                history.comparison_records)
        end
        first_sources = Set(event[:source_id] for event in first_candidate_history.observations)
        second_sources = Set(event[:source_id] for event in second_candidate_history.observations)
        @test isempty(intersect(first_sources, second_sources))
        # Candidate-route terminal and finite-difference observations remain
        # comparison evidence even when the corner certificate is refused.
        @test summary.unresolved_competitor
        @test any(x -> hasproperty(x, :double_zero_corner_certificate) &&
            x.double_zero_corner_certificate.status != :resolved_double_zero_corner,
            summary.lower_bound_resolutions)
        @test any(x -> hasproperty(x, :double_zero_corner_certificate),
            summary.lower_bound_resolutions)
        legacy_v1 = run_version(:arc1_profile_v1)
        @test continuation_calls[] == 0
        @test only(legacy_v1.nuisance_statuses).method_version == :arc1_profile_v1
        legacy_v2 = run_version(:arc1_profile_v2)
        @test continuation_calls[] > 0
        @test !any(x -> hasproperty(x, :double_zero_corner_certificate),
            only(legacy_v2.nuisance_statuses).lower_bound_resolutions)
        legacy_v3 = run_version(:arc1_profile_v3)
        @test continuation_calls[] > 0
        @test any(x -> hasproperty(x, :double_zero_corner_certificate),
            only(legacy_v3.nuisance_statuses).lower_bound_resolutions)
    end

    @testset "determinant identity, reparameterisation, and likelihood convention" begin
        H = hcat(fill(2.5, 7), collect(-2.0:4.0))
        D = Diagonal([0.7, 1.1, 2.0, 0.9, 1.7, 0.8, 1.4])
        C = nullspace(H')
        lhs = det(D) * det(H' * (D \ H))
        rhs = det(H' * H) * det(C' * D * C)
        @test lhs ≈ rhs rtol = 2e-12

        B = [2.0 0.3; 0.1 1.5]
        H2 = H * B
        shift = log(abs(det(B)))
        @test logdet(H2' * H2) - logdet(H' * H) ≈ 2shift atol = 2e-13
        reml_design_term(Hx) = -0.5 * logdet(Hx' * (D \ Hx))
        @test reml_design_term(H2) - reml_design_term(H) ≈ -shift atol = 2e-13
        ν = size(H, 1) - size(H, 2)
        omitted = -4.25
        full = omitted - ν * log(2π) / 2
        bound_omit = -0.5 * (ν * log(1.3) + logdet(H' * H))
        bound_full = bound_omit - ν * log(2π) / 2
        @test full - omitted ≈ bound_full - bound_omit atol = 1e-14
    end

    @testset "exact Gram determinant and conservative directed rounding" begin
        H = hcat(fill(1.75, 8), collect(-1.0:6.0))
        point = -12.0
        design_data = V4._arc1_profile_v4_design_certificate_data(H)
        @test isimmutable(design_data)
        @test design_data.reason === nothing
        boundary = V4._arc1_profile_v4_tail_boundary(H, point;
            normalization_convention = :omit_2pi, design_data)
        @test boundary isa Float64 && boundary > 0
        cert = V4._arc1_profile_v4_tail_certificate(H, boundary, point;
            normalization_convention = :omit_2pi, design_data)
        @test cert.status == :excluded_tail
        @test cert.certified
        @test cert.gap_lower > 1e-8
        @test cert.determinant isa Rational{BigInt}
        @test cert.determinant_identity ==
            :detD_detHinvDH_equals_detHtH_detCtDC
        @test cert.rounding_contract == (rational_numerator = :down,
            rational_denominator = :up, rational_division = :down,
            determinant_log = :down,
            boundary_variance_log = :down, residual_df_product_and_sum = :down,
            upper_bound_negation_and_product = :up,
            threshold_subtraction = :down, gap_subtraction = :down)
        @test cert.boundary_rounding_contract == (reference_threshold = :down,
            log_determinant_lower = :down, log_boundary_numerator = :up,
            residual_df_division = :up, exponential = :up,
            float_conversion = :nearest_then_nextfloat)
        @test cert.separation_tolerance == 1e-8
        @test cert.certified == (cert.gap_lower > BigFloat(cert.separation_tolerance))
        @test cert.point_loglik == point
        @test cert.cutoff == V4._ARC1_PROFILE_CUTOFF_95
        replayed_bounds = setprecision(BigFloat, cert.precision) do
            determinant_lower = setrounding(BigFloat, RoundDown) do
                log(V4._arc1_profile_v4_rational_lower(cert.determinant))
            end
            boundary_variance_lower = setrounding(BigFloat, RoundDown) do
                log(BigFloat(cert.E))
            end
            inside_lower = setrounding(BigFloat, RoundDown) do
                BigFloat(cert.residual_df) * boundary_variance_lower + determinant_lower
            end
            upper = setrounding(BigFloat, RoundUp) do
                -BigFloat(0.5) * inside_lower
            end
            threshold = setrounding(BigFloat, RoundDown) do
                BigFloat(cert.point_loglik) - BigFloat(cert.cutoff) / BigFloat(2)
            end
            gap = setrounding(BigFloat, RoundDown) do
                threshold - upper
            end
            (upper, threshold, gap)
        end
        @test replayed_bounds == (cert.upper_bound, cert.threshold_lower, cert.gap_lower)
        @test V4._arc1_profile_v4_tail_certificate(H, boundary, point;
            normalization_convention = :full_2pi).reason ==
            :likelihood_convention_mismatch
        @test V4._arc1_profile_v4_tail_boundary(H, point;
            normalization_convention = :full_2pi, design_data) === nothing
        @test V4._arc1_profile_v4_tail_certificate(H, boundary, point;
            design_data = V4._arc1_profile_v4_design_certificate_data(
                hcat(ones(8), collect(2.0:9.0))),
            normalization_convention = :omit_2pi).reason == :design_context_mismatch
        @test V4._arc1_profile_v4_tail_certificate(H, boundary, point;
            design_data = merge(design_data, (; determinant = 1 // 1)),
            normalization_convention = :omit_2pi).reason == :design_context_mismatch
        @test V4._arc1_profile_v4_tail_certificate(H, boundary, point;
            design_data = merge(design_data, (; determinant = big(1) // big(1))),
            normalization_convention = :omit_2pi).reason == :design_context_mismatch

        duplicated = hcat(ones(8), ones(8))
        @test V4._arc1_profile_v4_tail_certificate(duplicated, 1.0, point;
            normalization_convention = :omit_2pi).reason ==
            :gram_rank_failure
        @test V4._arc1_profile_v4_tail_certificate(H, 0.0, point;
            normalization_convention = :omit_2pi).reason ==
            :nonpositive_tail_boundary
        @test V4._arc1_profile_v4_tail_certificate(H, 1, point;
            normalization_convention = :omit_2pi).reason ==
            :nonpositive_tail_boundary
        @test V4._arc1_profile_v4_tail_certificate(H, BigFloat(1), point;
            normalization_convention = :omit_2pi).reason ==
            :nonpositive_tail_boundary
        @test V4._arc1_profile_v4_tail_certificate(H, 1.0, BigFloat(point);
            normalization_convention = :omit_2pi).reason ==
            :invalid_reference_likelihood
        @test V4._arc1_profile_v4_tail_certificate(H, 1.0, point;
            cutoff = BigFloat(V4._ARC1_PROFILE_CUTOFF_95),
            normalization_convention = :omit_2pi).reason == :invalid_cutoff
        @test V4._arc1_profile_v4_tail_boundary(H, BigFloat(point);
            normalization_convention = :omit_2pi) === nothing
        @test V4._arc1_profile_v4_tail_boundary(H, point;
            cutoff = BigFloat(V4._ARC1_PROFILE_CUTOFF_95),
            normalization_convention = :omit_2pi) === nothing
        @test V4._arc1_profile_v4_tail_certificate(ones(2, 2), 1.0, point;
            normalization_convention = :omit_2pi).reason ==
            :design_size_unsupported
        @test V4._arc1_profile_v4_tail_certificate(Float32.(H), 1.0, point;
            normalization_convention = :omit_2pi).reason ==
            :design_must_be_float64
        @test V4._arc1_profile_v4_tail_certificate([1.0 Inf; 2.0 3.0; 1.0 4.0],
            1.0, point; normalization_convention = :omit_2pi).reason ==
            :nonfinite_design
        @test V4._arc1_profile_v4_tail_certificate(H, 1.0, point;
            eigenvalue_contributions = [-1.0],
            normalization_convention = :omit_2pi).reason == :invalid_eigenvalue_contributions
        @test V4._arc1_profile_v4_tail_certificate(H, 1.0, point;
            variance_coefficients = (1.0, -1.0),
            normalization_convention = :omit_2pi).reason == :invalid_variance_coefficients

        determinant = V4._arc1_profile_v4_exact_det(
            Matrix{Rational{BigInt}}(undef, 0, 0))
        @test determinant == 1
        ν = size(H, 1) - size(H, 2)
        t = point - V4._ARC1_PROFILE_CUTOFF_95 / 2
        logdet = log(Float64(V4._arc1_profile_v4_exact_det(
            Matrix{Rational{BigInt}}(undef, 0, 0))))
        @test isfinite(logdet) # guard the fixture arithmetic path itself
        gram = Matrix{Rational{BigInt}}(undef, size(H, 1), size(H, 2))
        for j in axes(H, 2), i in axes(H, 1)
            gram[i, j] = Rational{BigInt}(H[i, j])
        end
        gram_det = V4._arc1_profile_v4_exact_det(gram' * gram)
        equality_E = exp((-2t - log(Float64(gram_det))) / ν)
        equality = V4._arc1_profile_v4_tail_certificate(H, equality_E, point;
            normalization_convention = :omit_2pi)
        @test !equality.certified

        # Both the reference and bound shift by -ν log(2π)/2 when moving
        # from OMIT_2PI to the full Gaussian convention.
        full_reference = point - ν * log(2π) / 2
        full_bound = Float64(cert.upper_bound) - ν * log(2π) / 2
        @test (full_reference - V4._ARC1_PROFILE_CUTOFF_95 / 2) - full_bound ≈
            Float64(cert.gap_lower) atol = 1e-12
    end

    @testset "bounded tail classifies arbitrary later islands" begin
        H = hcat(ones(8), collect(1.0:8.0))
        cert = V4._arc1_profile_v4_tail_certificate(H,
            V4._arc1_profile_v4_tail_boundary(H, -12.0;
                normalization_convention = :omit_2pi), -12.0;
            normalization_convention = :omit_2pi,
            design_data = V4._arc1_profile_v4_design_certificate_data(H))
        calls = Float64[]
        profile(value) = begin
            push!(calls, Float64(value))
            value < cert.E ? -1.0 : error("certified tail must not call the objective")
        end
        @test V4._arc1_profile_v4_tail_membership(cert, cert.E) == :outside_by_bound
        @test V4._arc1_profile_v4_tail_membership(cert, 4cert.E) == :outside_by_bound
        @test V4._arc1_profile_v4_tail_membership(cert, prevfloat(cert.E)) == :evaluate_profile
        @test V4._arc1_profile_v4_tail_membership(cert, Float32(cert.E)) == :evaluate_profile
        @test V4._arc1_profile_v4_tail_membership(cert, BigFloat(cert.E)) == :evaluate_profile
        @test profile(prevfloat(cert.E)) == -1.0
        @test length(calls) == 1
    end

    @testset "retained scalar extraction contract" begin
        H = hcat(fill(1.25, 10), collect(-4.0:5.0))
        point, cutoff = -38.5, V4._ARC1_PROFILE_CUTOFF_95
        identity = bytes2hex(sha256(reinterpret(UInt8, vec(H))))
        cert = V4._arc1_profile_v4_tail_certificate(H,
            V4._arc1_profile_v4_tail_boundary(H, point; cutoff,
                normalization_convention = :omit_2pi,
                design_data = V4._arc1_profile_v4_design_certificate_data(H)), point;
            cutoff, normalization_convention = :omit_2pi,
            design_data = V4._arc1_profile_v4_design_certificate_data(H))
        @test length(identity) == 64
        @test cert.design_identity == identity
        @test cert.convention == :omit_2pi
        @test cert.residual_df == size(H, 1) - size(H, 2)
        @test isfinite(cert.threshold_lower) && isfinite(cert.upper_bound)
        @test V4._arc1_profile_v4_tail_boundary(H, point; cutoff,
            normalization_convention = :omit_2pi) > 0
    end

    @testset "candidate-owned history keeps callback and probe maxima" begin
        records = Any[
            (owner = :candidate, candidate_id = 4, source_id = :callback,
             value = -101.9919, evaluation_valid = true, centering_ve = 5.0,
             status = :returned),
            (owner = :candidate, candidate_id = 4, source_id = :probe,
             value = -101.9798, evaluation_valid = true, centering_ve = 5.0,
             status = :returned),
            (owner = :shared, source_id = :certified_winner,
             value = -101.9798, evaluation_valid = true, centering_ve = 5.0,
             status = :ok)]
        history = V4._arc1_profile_v4_candidate_history(records, 4, -101.9798,
            5.0)
        @test history.max_valid_centered_loglik == -101.9798
        @test history.unresolved # candidate callback/probe tie still counts

        inferior = filter(r -> r.owner === :candidate, records)
        shared_winner_only = V4._arc1_profile_v4_candidate_history(
            vcat(inferior[1:1], [records[end]]), 4, -101.9798, 5.0;
            certified_shared_solutions=[(source_id=:certified_winner, status=:ok,
                converged=true, value=-101.9798)])
        @test !shared_winner_only.unresolved

        uncertified_winner = V4._arc1_profile_v4_candidate_history(
            [merge(records[end], (; status = :nuisance_unresolved))], 4,
            -101.9798, 5.0)
        wrong_winner_reference = V4._arc1_profile_v4_candidate_history(
            [merge(records[end], (; value = -101.0))], 4, -101.9798, 5.0)
        @test uncertified_winner.unresolved
        @test wrong_winner_reference.unresolved

        wrong_status = V4._arc1_profile_v4_candidate_history(records, 4, -101.9798,
            5.0; certified_shared_solutions=[(source_id=:certified_winner,
                status=:returned, converged=true, value=-101.9798)])
        wrong_value = V4._arc1_profile_v4_candidate_history(records, 4, -101.9798,
            5.0; certified_shared_solutions=[(source_id=:certified_winner,
                status=:ok, converged=true, value=-102.0)])
        @test wrong_status.unresolved
        @test wrong_value.unresolved
        @test any(f -> f.reason == :certified_shared_solution_mismatch,
            wrong_status.failures)
        @test any(f -> f.reason == :certified_shared_solution_mismatch,
            wrong_value.failures)

        returned_record = [merge(records[end], (; status = :returned))]
        returned_certificate = (source_id = records[end].source_id, status = :returned,
            converged = true, value = -101.9798)
        refused_returned_certificate = V4._arc1_profile_v4_candidate_history(
            returned_record, :shared, -101.9798, 5.0;
            certified_shared_solutions=[returned_certificate])
        @test refused_returned_certificate.unresolved
        @test any(f -> f.reason == :certified_shared_solution_mismatch,
            refused_returned_certificate.failures)
        wrong_bound_type = V4._arc1_profile_v4_candidate_history(records, 4,
            -101.9798, BigFloat(5.0))
        @test wrong_bound_type.unresolved
    end

    @testset "certified exact-zero co-winners are not unresolved competitors" begin
        best = -101.9798
        face = (:exact_zero_face, 2, :residual_variance, 5.0)
        corner = (:exact_zero_intersection, :residual_variance, 5.0)
        records = Any[
            (owner = :shared, source_id = face, value = best,
             evaluation_valid = true, centering_ve = 5.0, status = :ok),
            (owner = :shared, source_id = corner, value = best,
             evaluation_valid = true, centering_ve = 5.0, status = :ok),
        ]
        certificates = [
            (source_id = face, status = :ok, converged = true, value = best),
            (source_id = corner, status = :ok, converged = true, value = best),
        ]
        tied = V4._arc1_profile_v4_candidate_history(records, :shared, best, 5.0;
            certified_shared_solutions = certificates)
        @test !tied.unresolved
        @test isempty(tied.failures)

        reordered = V4._arc1_profile_v4_candidate_history(reverse(records), :shared,
            best, 5.0; certified_shared_solutions=reverse(certificates))
        @test !reordered.unresolved

        inside_delta = 0.5e-8
        inside = V4._arc1_profile_v4_candidate_history(
            [(owner = :shared, source_id = face, value = best - inside_delta,
              evaluation_valid = true, centering_ve = 5.0, status = :ok)],
            :shared, best, 5.0;
            certified_shared_solutions=[(source_id = face, status = :ok,
                converged = true, value = best - inside_delta)])
        @test !inside.unresolved

        outside_delta = 1.01e-8
        outside = V4._arc1_profile_v4_candidate_history(
            [(owner = :shared, source_id = face, value = best - outside_delta,
              evaluation_valid = true, centering_ve = 5.0, status = :ok)],
            :shared, best, 5.0;
            certified_shared_solutions=[(source_id = face, status = :ok,
                converged = true, value = best - outside_delta)])
        @test outside.unresolved
        @test any(f -> f.reason == :certified_shared_solution_mismatch,
            outside.failures)

        candidate_tie = V4._arc1_profile_v4_candidate_history(
            vcat(records, [(owner = :candidate, candidate_id = 4,
                source_id = :candidate_fit, value = best, evaluation_valid = true,
                centering_ve = 5.0, status = :returned)]), 4, best, 5.0;
            certified_shared_solutions=certificates)
        @test candidate_tie.unresolved

        bad_status = merge(certificates[2], (; status = :nuisance_unresolved))
        refused_status = V4._arc1_profile_v4_candidate_history(records, :shared,
            best, 5.0; certified_shared_solutions=[certificates[1], bad_status])
        @test refused_status.unresolved
        @test any(f -> f.reason == :certified_shared_solution_mismatch,
            refused_status.failures)

        unconverged = merge(certificates[2], (; converged = false))
        refused_unconverged = V4._arc1_profile_v4_candidate_history(records, :shared,
            best, 5.0; certified_shared_solutions=[certificates[1], unconverged])
        @test refused_unconverged.unresolved
        @test any(f -> f.reason == :certified_shared_solution_mismatch,
            refused_unconverged.failures)

        missing_convergence = (source_id=certificates[2].source_id,
            status=certificates[2].status, value=certificates[2].value)
        refused_missing_convergence = V4._arc1_profile_v4_candidate_history(records,
            :shared, best, 5.0;
            certified_shared_solutions=[certificates[1], missing_convergence])
        @test refused_missing_convergence.unresolved
        @test any(f -> f.reason == :certified_shared_solution_mismatch,
            refused_missing_convergence.failures)

        bad_value = merge(certificates[2], (; value = best + 1e-4))
        refused_value = V4._arc1_profile_v4_candidate_history(records, :shared,
            best, 5.0; certified_shared_solutions=[certificates[1], bad_value])
        @test refused_value.unresolved
        @test any(f -> f.reason == :certified_shared_solution_mismatch,
            refused_value.failures)

        nonfinite = merge(certificates[2], (; value = NaN))
        refused_nonfinite = V4._arc1_profile_v4_candidate_history(records, :shared,
            best, 5.0; certified_shared_solutions=[certificates[1], nonfinite])
        @test refused_nonfinite.unresolved

        borrowed_source = (:exact_zero_face, 2, :residual_variance, 6.0)
        borrowed_record = [(owner = :shared, source_id = borrowed_source,
            value = best, evaluation_valid = true, centering_ve = 5.0, status = :ok)]
        refused_borrowed = V4._arc1_profile_v4_candidate_history(borrowed_record,
            :shared, best, 5.0; certified_shared_solutions=certificates)
        @test refused_borrowed.unresolved
    end

    @testset "raw nuisance exact-zero-face winner retains producer identity" begin
        n = 8
        records_count = 2n
        Z = sparse(1:records_count, repeat(1:n, inner=2), ones(records_count),
            records_count, n)
        X = ones(records_count, 1)
        y = [0.4 + 0.15sin(0.17i) + 0.08cos(0.031i) +
             0.2 * (isodd(i) ? 1.0 : -1.0) for i in 1:records_count]
        context = V4._arc1_profile_context(y, X, Z, Matrix{Float64}(I, n, n))
        ve = 0.5
        zero_intersection = [0.0, 0.0, ve]
        base_score = V4._arc1_profile_centered_loglik_at(context,
            zero_intersection, ve).loglik

        controlled_bfgs(ctx, base, free, start, scale) = begin
            values = copy(base)
            values[free] .= start
            score = base_score - 1.0
            (loglik = 1.0e8, max_valid_loglik = 1.0e8,
             centered_loglik = score, max_valid_centered_loglik = score,
             centering_ve = ve, components = values, converged = true,
             gradient_norm = 0.0, optimizer_status = "controlled",
             hit_bound = false)
        end
        controlled_scalar(ctx, make_components, scale; held_zero_component,
                kwargs...) = begin
            values = make_components(0.75)
            score = held_zero_component == 1 ? base_score + 1.0 : base_score - 0.5
            (loglik = 1.0e8, max_valid_loglik = 1.0e8, status = :ok,
             value = 0.75, centered_active = true, centered_loglik = score,
             max_valid_centered_loglik = score, centering_ve = ve,
             candidates = Any[],
             physical_zero_endpoint_certificate = (status = :not_attempted,))
        end
        controlled_gradient(ctx, values; free_indices = collect(1:3)) =
            (component_gradient = zeros(3), log_gradient = zeros(length(free_indices)),
             loglik = 1.0e8)
        raw = V4._arc1_raw_nuisance(context, :residual_variance, ve, 1.0;
            method_version = :arc1_profile_v4, bfgs_runner = controlled_bfgs,
            scalar_profile_runner = controlled_scalar,
            loglik_runner = (ctx, values) -> (1.0e8, :ok),
            gradient_runner = controlled_gradient)
        summary = only(raw.nuisance_statuses)
        @test raw.status == :ok
        @test summary.best_certified.components == [0.0, 0.75, ve]
        @test summary.v4_shared_history_summary.unresolved == false
        winner = only(filter(r -> r.source_id ==
            (:exact_zero_face, 1, :residual_variance, ve), summary.v4_shared_history))
        @test winner.status == :ok
        @test winner.value == raw.centered_loglik

        intersection_scalar(ctx, make_components, scale; kwargs...) = begin
            values = make_components(0.75)
            score = base_score - 0.5
            (loglik = 1.0e8, max_valid_loglik = 1.0e8, status = :ok,
             value = 0.75, centered_active = true, centered_loglik = score,
             max_valid_centered_loglik = score, centering_ve = ve,
             candidates = Any[],
             physical_zero_endpoint_certificate = (status = :not_attempted,))
        end
        intersection_raw = V4._arc1_raw_nuisance(context, :residual_variance, ve, 1.0;
            method_version = :arc1_profile_v4, bfgs_runner = controlled_bfgs,
            scalar_profile_runner = intersection_scalar,
            loglik_runner = (ctx, values) -> (1.0e8, :ok),
            gradient_runner = controlled_gradient)
        intersection_summary = only(intersection_raw.nuisance_statuses)
        @test intersection_raw.status == :ok
        @test intersection_summary.best_certified.components == zero_intersection
        @test intersection_summary.v4_shared_history_summary.unresolved == false
        intersection_winner = only(filter(r -> r.source_id ==
            (:exact_zero_intersection, :residual_variance, ve),
            intersection_summary.v4_shared_history))
        @test intersection_winner.status == :ok
        @test intersection_summary.best_certified.producer_source_id ==
            intersection_winner.source_id
    end

    @testset "v4 zero-target reduced models preserve Va and Vpe boundaries" begin
        n = 8
        records_count = 2n
        Z = sparse(1:records_count, repeat(1:n, inner=2), ones(records_count),
            records_count, n)
        X = ones(records_count, 1)
        y = [0.2 + 0.11sin(0.13i) + 0.09cos(0.037i) for i in 1:records_count]
        context = V4._arc1_profile_context(y, X, Z, Matrix{Float64}(I, n, n))
        candidate_bases = Vector{Vector{Float64}}()
        reduced_models = Any[]
        objective_calls = Any[]
        reduced_boundary = V4._arc1_profile_reml(context, 0.0, 0.0, 0.4)
        singular_corner = V4._arc1_profile_reml(context, 0.0, 0.0, 0.0)
        @test reduced_boundary.status == :ok
        @test isfinite(reduced_boundary.loglik)
        @test singular_corner.status == :singular_proposal
        @test singular_corner.loglik == -Inf

        synthetic_loglik(ctx, components) = begin
            values = Float64.(components)
            status = values[3] == 0.0 ? :singular_proposal : :ok
            push!(objective_calls, (components = copy(values), status))
            status == :ok ? (-10.0 - sum(values), status) : (-Inf, status)
        end
        controlled_bfgs(ctx, base, free, start, scale) = begin
            push!(candidate_bases, copy(base))
            components = copy(base)
            components[free] .= start
            (loglik = -9.0, max_valid_loglik = -9.0,
             components, converged = true, gradient_norm = 0.0,
             optimizer_status = "controlled", hit_bound = false)
        end
        controlled_scalar(ctx, make_components, scale; target_component,
                held_zero_component, physical_zero_component, kwargs...) = begin
            values = make_components(0.4)
            intersection = make_components(0.0)
            ll, ll_status = synthetic_loglik(ctx, values)
            face_status = ll_status == :singular_proposal ?
                :singular_proposal : :nuisance_unresolved
            push!(reduced_models, (target_component, held_zero_component,
                physical_zero_component, values, intersection, ll_status, face_status))
            (loglik = ll, max_valid_loglik = ll, status = face_status,
             value = 0.4, candidates = Any[],
             physical_zero_endpoint_certificate = (status = :not_attempted,))
        end
        controlled_gradient(ctx, values; free_indices = collect(1:3)) =
            (component_gradient = zeros(3),
             log_gradient = zeros(length(free_indices)), loglik = -10.0)

        for (target, target_index) in ((:additive_variance, 1),
                                       (:permanent_environment_variance, 2))
            empty!(candidate_bases)
            empty!(reduced_models)
            empty!(objective_calls)
            raw = V4._arc1_raw_nuisance(context, target, 0.0, 1.0;
                method_version = :arc1_profile_v4,
                bfgs_runner = controlled_bfgs,
                scalar_profile_runner = controlled_scalar,
                loglik_runner = synthetic_loglik,
                gradient_runner = controlled_gradient)

            @test !isempty(raw.nuisance_statuses)
            @test !isempty(candidate_bases)
            @test all(base -> base[target_index] == 0.0, candidate_bases)
            @test length(reduced_models) == 2
            for (target_component, held_zero, physical_zero, values,
                    intersection, likelihood_status, face_status) in reduced_models
                @test target_component == target_index
                @test target_component != held_zero
                @test target_component != physical_zero
                @test values[target_component] == 0.0
                @test values[held_zero] == 0.0
                @test values[physical_zero] == 0.4
                @test intersection == zeros(3)
                @test intersection[target_component] == 0.0
                @test likelihood_status in (:ok, :singular_proposal)
                @test face_status in (:nuisance_unresolved, :singular_proposal)
            end
            @test any(call -> call.components == zeros(3) &&
                call.status == :singular_proposal, objective_calls)
        end
    end

    @testset "v4 noncentered route retains historical full-likelihood competitors" begin
        n = 8
        records_count = 2n
        Z = sparse(1:records_count, repeat(1:n, inner=2), ones(records_count),
            records_count, n)
        X = ones(records_count, 1)
        y = [0.2 + 0.11sin(0.13i) + 0.09cos(0.037i) for i in 1:records_count]
        context = V4._arc1_profile_context(y, X, Z, Matrix{Float64}(I, n, n))
        controlled_bfgs(ctx, base, free, start, scale) = begin
            values = copy(base)
            values[free] .= start
            (loglik = -10.0, max_valid_loglik = -9.0,
             components = values, converged = true, gradient_norm = 0.0,
             optimizer_status = "controlled", hit_bound = false)
        end
        controlled_scalar(ctx, make_components, scale; kwargs...) =
            (loglik = -10.0, max_valid_loglik = -9.0, status = :ok,
             value = 0.75, candidates = Any[],
             physical_zero_endpoint_certificate = (status = :not_attempted,))
        controlled_gradient(ctx, values; free_indices = collect(1:3)) =
            (component_gradient = zeros(3), log_gradient = zeros(length(free_indices)),
             loglik = -10.0)
        raw = V4._arc1_raw_nuisance(context, :additive_variance, 0.5, 1.0;
            method_version = :arc1_profile_v4, bfgs_runner = controlled_bfgs,
            scalar_profile_runner = controlled_scalar,
            loglik_runner = (ctx, values) -> (-10.0, :ok),
            gradient_runner = controlled_gradient)
        summary = only(raw.nuisance_statuses)
        @test summary.historical_full_competitor
        @test raw.status == :nuisance_unresolved
    end

    @testset "v4 likelihood history through profile evaluator and target search" begin
        cutoff = V4._ARC1_PROFILE_CUTOFF_95
        point_loglik = -10.0
        terminal_loglik = -11.0
        tiny_data = (y = [-1.0, -0.2, 0.4, 0.8], X = ones(4, 1))

        function run_case(case)
            state = V4._Arc1ProfileState(tiny_data, 1.0, point_loglik,
                Dict{Symbol,Dict{Float64,Any}}(), Dict{Symbol,Int}(),
                point_loglik, Any[], :arc1_profile_v4)
            audits = Any[]
            evaluator = function (x)
                records = if case === :candidate_history
                    Any[
                        (owner = :candidate, candidate_id = 4, source_id = :callback,
                         value = -10.4, evaluation_valid = true, centering_ve = 5.0,
                         status = :returned),
                        (owner = :candidate, candidate_id = 4, source_id = :probe,
                         value = -10.2, evaluation_valid = true, centering_ve = 5.0,
                         status = :returned)]
                elseif case === :shared_tie
                    Any[(owner = :shared, source_id = :unresolved_face,
                         value = terminal_loglik, evaluation_valid = true,
                         centering_ve = 5.0, status = :ok)]
                else
                    Any[(owner = :candidate, candidate_id = 4, source_id = :callback,
                         value = -12.0, evaluation_valid = true, centering_ve = 5.0,
                         status = :returned),
                        (owner = :shared, source_id = :certified_winner,
                         value = terminal_loglik, evaluation_valid = true,
                         centering_ve = 5.0, status = :ok)]
                end
                certified_shared_solutions = case === :shared_winner ?
                    [(source_id=:certified_winner, status=:ok, converged=true,
                        value=terminal_loglik)] : Any[]
                history = V4._arc1_profile_v4_candidate_history(records, 4,
                    terminal_loglik, 5.0;
                    certified_shared_solutions)
                push!(audits, history)
                history.unresolved && return (; status = :nuisance_unresolved,
                    loglik = terminal_loglik, nuisance_statuses = history.failures)
                score = (x - 0.5)^2 - 0.01
                loglik = point_loglik - (cutoff + score) / 2
                return (; status = :ok, loglik, nuisance_statuses = Any[])
            end
            result = V4._arc1_target_search(state, :heritability, 0.5;
                profile_evaluator = evaluator)
            return result, audits
        end

        candidate_result, candidate_audits = run_case(:candidate_history)
        @test !isempty(candidate_audits)
        @test all(h -> h.unresolved && h.own_competitor, candidate_audits)
        @test all(h -> h.max_valid_centered_loglik == -10.2, candidate_audits)
        @test candidate_result.search_status == :nuisance_unresolved
        @test !candidate_result.formed

        shared_tie_result, shared_tie_audits = run_case(:shared_tie)
        @test !isempty(shared_tie_audits)
        @test all(h -> h.unresolved, shared_tie_audits)
        @test all(h -> any(f -> f.reason == :unresolved_shared_competitor,
            h.failures), shared_tie_audits)
        @test shared_tie_result.search_status == :nuisance_unresolved
        @test !shared_tie_result.formed

        winner_result, winner_audits = run_case(:shared_winner)
        @test !isempty(winner_audits)
        @test all(h -> !h.unresolved && !h.own_competitor, winner_audits)
        @test winner_result.search_status == :finite_grid_resolved
        @test winner_result.formed
        @test length(winner_result.segments) == 1
    end

    @testset "recursive evidence rejects missing owner and candidate identity" begin
        full = Ref(-Inf)
        centered = Ref(-Inf)
        sink = Dict{Symbol,Any}(:events => Any[], :producer_history => Any[],
            :provenance_failures => Any[], :max_valid_loglik => -Inf,
            :max_valid_centered_loglik => -Inf)
        @test_nowarn V4._arc1_profile_v3_history!(full, centered,
            (owner = missing, candidate_id = 1, kind = :centered, value = 5.0,
             status = :returned, evaluation_valid = true, centering_ve = 5.0),
            5.0; sink_record = sink)
        @test !isempty(sink[:provenance_failures])
        empty!(sink[:provenance_failures])
        @test_nowarn V4._arc1_profile_v3_history!(full, centered,
            (owner = :candidate, candidate_id = missing, kind = :centered,
             value = 5.0, status = :returned, evaluation_valid = true,
             centering_ve = 5.0), 5.0; sink_record = sink)
        @test !isempty(sink[:provenance_failures])
    end

    @testset "history counterexamples and search composition" begin
        best = -100.0
        function history(records; certified_source_ids = Symbol[])
            certificates = [(source_id=id, status=:ok, converged=true, value=best)
                for id in certified_source_ids]
            V4._arc1_profile_v4_candidate_history(records, 4, best, 5.0;
                certified_shared_solutions=certificates)
        end
        own(value; tag = 5.0, status = :returned) =
            (owner = :candidate, candidate_id = 4, source_id = :own,
             value, evaluation_valid = true, centering_ve = tag, status)
        shared(value; id = :other, status = :ok) =
            (owner = :shared, source_id = id, value, evaluation_valid = true,
             centering_ve = 5.0, status)
        @test history([own(-99.0)]).unresolved # superior callback despite lower terminal
        @test history([own(best)]).unresolved  # own tie
        @test history([shared(best)]).unresolved # unresolved shared face tie
        @test history([(value = best, evaluation_valid = true,
            centering_ve = 5.0, status = :returned)]).unresolved # unknown owner
        @test history([own(best; tag = 6.0)]).unresolved # borrowed/wrong centering tag
        @test history([shared(best; id = :winner)]).unresolved
        @test !history([shared(best; id = :winner)];
            certified_source_ids=[:winner]).unresolved
        @test history([(owner = :shared, value = best, evaluation_valid = true,
            centering_ve = 5.0, status = :ok)]).unresolved # missing shared identity
        @test history([shared(best; status = :unresolved)]).unresolved
        @test history([merge(own(best), (; centering_ve = missing))]).unresolved
        @test history([merge(own(best), (; owner = missing))]).unresolved
        @test history([merge(own(best), (; candidate_id = missing))]).unresolved
        @test history([merge(own(best), (; status = missing))]).unresolved
        @test history([(value = best, evaluation_valid = true,
            centering_ve = 5.0, status = :returned)]).unresolved # absent owner
        @test history([(owner = :candidate, source_id = :own, value = best,
            evaluation_valid = true, centering_ve = 5.0, status = :returned)]).unresolved # absent candidate id
        @test history([(owner = :candidate, candidate_id = 4, source_id = :own,
            value = best, evaluation_valid = true, centering_ve = 5.0)]).unresolved # absent status
        @test history([(owner = :shared, source_id = :other, value = best,
            evaluation_valid = true, centering_ve = 5.0)]).unresolved # absent shared status
        @test history([merge(shared(best), (; centering_ve = missing))]).unresolved
        @test history([merge(shared(best), (; owner = missing))]).unresolved
        @test history([merge(shared(best), (; source_id = missing))]).unresolved
        @test history([merge(shared(best), (; status = missing))]).unresolved

        # A bound endpoint does not erase an unresolved interior comparison.
        endpoint = [0.0, 1.0, 2.0]
        unresolved_scan = V4._arc1_segments_from_scores(endpoint,
            [-1.0, NaN, Inf], x -> error("interior unresolved score is retained");
            tolerance = 1e-6)
        @test unresolved_scan.status == :unresolved_search
        @test isempty(unresolved_scan.segments)
        # Two resolved interior regions remain separate when a bound supplies
        # only the final outside endpoint.
        resolved_scan = V4._arc1_segments_from_scores([0.0, 1.0, 2.0, 3.0, 4.0],
            [-1.0, 1.0, -1.0, 1.0, Inf], x -> 1.0; tolerance = 1e-6)
        @test resolved_scan.status == :ok
        @test length(resolved_scan.segments) == 2
        @test V4._ARC1_PROFILE_METHOD_VERSION == :arc1_profile_v1
        @test V4._ARC1_PROFILE_METHOD_VERSIONS ==
            (:arc1_profile_v1, :arc1_profile_v2, :arc1_profile_v3, :arc1_profile_v4)
    end
end
