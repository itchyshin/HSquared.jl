using HSquared
using LinearAlgebra
using Random
using SparseArrays
using Test

function _h1t_interior_fixture()
    rng = MersenneTwister(20260701)
    sires = 20
    q = 200
    sire = zeros(Int, sires + q)
    for i in 1:q
        sire[sires + i] = rand(rng, 1:sires)
    end
    Ainv = pedigree_inverse(collect(1:(sires + q)), sire, zeros(Int, sires + q))
    A = inv(Symmetric(Matrix(Ainv)))
    na = size(Ainv, 1)
    g = cholesky(Symmetric(A + 1e-8I)).L * randn(rng, na)
    ngrp = 40
    grp_eff = randn(rng, ngrp) .* sqrt(0.5)
    recs = (sires + 1):(sires + q)
    X = ones(q, 1)
    Z1 = zeros(q, na)
    Z2 = zeros(q, ngrp)
    y = zeros(q)
    for (r, animal) in enumerate(recs)
        Z1[r, animal] = 1.0
        group = rand(rng, 1:ngrp)
        Z2[r, group] = 1.0
        y[r] = 3.0 + g[animal] + grp_eff[group] + randn(rng)
    end
    return (
        y = y,
        X = X,
        Z1 = sparse(Z1),
        Ainv1 = Ainv,
        Z2 = sparse(Z2),
        Ainv2 = sparse(Matrix(1.0I, ngrp, ngrp)),
    )
end

function _h1t_pure_animal_fixture()
    rng = MersenneTwister(2)
    sires = 40
    q = 400
    sire = zeros(Int, sires + q)
    for i in 1:q
        sire[sires + i] = rand(rng, 1:sires)
    end
    Ainv = pedigree_inverse(collect(1:(sires + q)), sire, zeros(Int, sires + q))
    A = inv(Symmetric(Matrix(Ainv)))
    na = size(Ainv, 1)
    g = cholesky(Symmetric(A + 1e-8I)).L * randn(rng, na)
    X = ones(q, 1)
    Z1 = zeros(q, na)
    y = zeros(q)
    for (r, animal) in enumerate((sires + 1):(sires + q))
        Z1[r, animal] = 1.0
        y[r] = 2.0 + g[animal] + randn(rng)
    end
    ngrp = 40
    groups = rand(rng, 1:ngrp, q)
    Z2 = zeros(q, ngrp)
    for r in 1:q
        Z2[r, groups[r]] = 1.0
    end
    return (
        y = y,
        X = X,
        Z1 = sparse(Z1),
        Ainv1 = Ainv,
        Z2 = sparse(Z2),
        Ainv2 = sparse(Matrix(1.0I, ngrp, ngrp)),
    )
end

function _h1t_no_signal_fixture()
    rng = MersenneTwister(99)
    Ainv = pedigree_inverse([1, 2, 3, 4], [0, 0, 1, 1], [0, 0, 2, 2])
    Z1 = zeros(8, 4)
    for (record, animal) in enumerate([1, 1, 2, 2, 3, 3, 4, 4])
        Z1[record, animal] = 1.0
    end
    Z2 = [1.0 0; 1 0; 0 1; 0 1; 1 0; 0 1; 1 0; 0 1]
    return (
        y = randn(rng, 8) .* 0.5 .+ 10.0,
        X = ones(8, 1),
        Z1 = Z1,
        Ainv1 = Ainv,
        Z2 = Z2,
        Ainv2 = Matrix(1.0I, 2, 2),
    )
end

function _h1t_provenance(; derived_seed = 21270914)
    return (
        protocol_id = "H1T-DIAG-S10-FIXED-TINY-01",
        protocol_revision = "1",
        authorization_text = "telemetry-only deterministic local test",
        fresh_worktree_path = "/private/tmp/hsq09-h1t-telemetry-amendment",
        source_commit = repeat("a", 40),
        manifest_hash = repeat("b", 64),
        harness_hash = repeat("c", 64),
        master_seed = 20260903,
        campaign_index = 1,
        cell_index = 1,
        replicate_index = 1,
        derived_seed = derived_seed,
    )
end

# This is an existing deterministic unit control, frozen after materialization
# by the telemetry-only amendment.  It is deliberately not the historical S10
# h1_two input, whose exact arrays are unavailable and must not be regenerated
# under this authorization.
const _H1T_INTERIOR_FINGERPRINTS = (
    y = "e62f41d7cb9c56d618852e6b42f0fb42ae1b583e23757cc7da152d0f5dcea6c3",
    X = "5574de578f3435522929d26c20561ac42b8a4cf07b4535cdfb625270bc8f8929",
    Z1 = "be3add43ed481de496207b03ad105baceec7d833f8fe9e531b88168776be43c9",
    Ainv1 = "f164accfd7b7679886bc9954b66940b61c7d980bc30405c7e1387b4b0fdff1eb",
    Z2 = "3fd6088b97a6bd39bcd0eda7ee6a2264682f3a2e483e0b07b1c6328003db4f40",
    Ainv2 = "d273769e52e6dfde8da78b2a4e8fea6db8d5cb2ea91a00ccec004d5e66e22b29",
)

function _h1t_without(nt::NamedTuple, field::Symbol)
    kept = Tuple(name for name in propertynames(nt) if name != field)
    return NamedTuple{kept}(Tuple(getproperty(nt, name) for name in kept))
end

function _h1t_snapshot(fixture; expected_input_hashes, provenance, kwargs...)
    return HSquared._two_effect_diagnostic_snapshot(
        fixture.y,
        fixture.X,
        fixture.Z1,
        fixture.Ainv1,
        fixture.Z2,
        fixture.Ainv2;
        expected_input_hashes = expected_input_hashes,
        provenance = provenance,
        kwargs...,
    )
end

@testset "H1T telemetry-only diagnostic helper" begin
    interior = _h1t_interior_fixture()
    expected = HSquared._h1t_input_fingerprints(
        interior.y, interior.X, interior.Z1, interior.Ainv1, interior.Z2, interior.Ainv2,
    )
    provenance = _h1t_provenance()

    @test expected == _H1T_INTERIOR_FINGERPRINTS
    repeat_interior = _h1t_interior_fixture()
    @test HSquared._h1t_input_fingerprints(
        repeat_interior.y,
        repeat_interior.X,
        repeat_interior.Z1,
        repeat_interior.Ainv1,
        repeat_interior.Z2,
        repeat_interior.Ainv2,
    ) == _H1T_INTERIOR_FINGERPRINTS

    direct_fit = fit_two_effect_reml(
        interior.y, interior.X, interior.Z1, interior.Ainv1, interior.Z2, interior.Ainv2,
    )
    direct_interval = two_effect_ratio_interval(
        interior.y, interior.X, interior.Z1, interior.Ainv1, interior.Z2, interior.Ainv2,
    )
    snapshot = _h1t_snapshot(interior; expected_input_hashes = expected, provenance = provenance)

    @test propertynames(direct_fit) == (
        :variance_components, :ratio1, :ratio2, :beta, :effect1, :effect2, :loglik, :converged,
    )
    @test propertynames(direct_interval) == (:ratio1, :ratio2, :level, :converged)
    @test isequal(direct_fit, snapshot.public.fit)
    @test isequal(direct_interval, snapshot.public.interval)
    @test snapshot.fit.requested_iterations == 200
    @test snapshot.fit.fit_returned
    @test snapshot.fit.fit_converged == direct_fit.converged
    @test !isempty(snapshot.fit.optimizer.termination_status)
    @test !isempty(snapshot.fit.optimizer.termination_message)
    @test snapshot.information.finite
    @test snapshot.information.full_pd
    @test all(row -> row.primary_terminal == :finite_ordered_interval, snapshot.ratios)
    @test all(row -> row.finite_ordered_interval, snapshot.ratios)
    @test snapshot.claim_eligible === false
    @test HSquared._h1t_validate_diagnostic_snapshot(snapshot) === nothing

    # These are the ratified H1 numeric controls on the existing deterministic
    # interior test materialization.  They do not generate or rerun S10.
    h1_controls = (
        level = 0.95,
        which = :both,
        initial = (sigma1 = 1.0, sigma2 = 1.0, sigma_e2 = 1.0),
        iterations = 80,
        fd_step = 1e-4,
        boundary_tol = 1e-6,
    )
    h1_direct_fit = fit_two_effect_reml(
        interior.y, interior.X, interior.Z1, interior.Ainv1, interior.Z2, interior.Ainv2;
        initial = h1_controls.initial,
        iterations = h1_controls.iterations,
    )
    h1_direct_interval = two_effect_ratio_interval(
        interior.y, interior.X, interior.Z1, interior.Ainv1, interior.Z2, interior.Ainv2;
        h1_controls...,
    )
    h1_snapshot = _h1t_snapshot(
        interior;
        expected_input_hashes = _H1T_INTERIOR_FINGERPRINTS,
        provenance = provenance,
        h1_controls...,
    )
    @test isequal(h1_direct_fit, h1_snapshot.public.fit)
    @test isequal(h1_direct_interval, h1_snapshot.public.interval)
    @test h1_snapshot.controls == h1_controls
    @test h1_snapshot.fit.optimizer.requested_iterations == 80

    ci90 = two_effect_ratio_interval(
        interior.y, interior.X, interior.Z1, interior.Ainv1, interior.Z2, interior.Ainv2;
        level = 0.90,
    )
    ci99 = two_effect_ratio_interval(
        interior.y, interior.X, interior.Z1, interior.Ainv1, interior.Z2, interior.Ainv2;
        level = 0.99,
    )
    @test ci99.ratio1.lower < ci90.ratio1.lower
    @test ci99.ratio1.upper > ci90.ratio1.upper
    @test ci99.ratio2.lower < ci90.ratio2.lower
    @test ci99.ratio2.upper > ci90.ratio2.upper

    pure_animal = _h1t_pure_animal_fixture()
    pure_expected = HSquared._h1t_input_fingerprints(
        pure_animal.y, pure_animal.X, pure_animal.Z1, pure_animal.Ainv1,
        pure_animal.Z2, pure_animal.Ainv2,
    )
    pure_snapshot = _h1t_snapshot(
        pure_animal; expected_input_hashes = pure_expected, provenance = provenance,
    )
    @test pure_snapshot.ratios[1].finite_ordered_interval
    @test pure_snapshot.ratios[2].primary_terminal == :own_numerator_boundary
    @test pure_snapshot.public.interval.ratio2.boundary
    @test isnan(pure_snapshot.public.interval.ratio2.lower)
    @test HSquared._h1t_validate_diagnostic_snapshot(pure_snapshot) === nothing

    no_signal = _h1t_no_signal_fixture()
    no_signal_expected = HSquared._h1t_input_fingerprints(
        no_signal.y, no_signal.X, no_signal.Z1, no_signal.Ainv1, no_signal.Z2, no_signal.Ainv2,
    )
    no_signal_snapshot = _h1t_snapshot(
        no_signal; expected_input_hashes = no_signal_expected, provenance = provenance,
    )
    @test all(row -> row.primary_terminal == :own_numerator_boundary, no_signal_snapshot.ratios)
    @test all(row -> isnan(row.lower) && isnan(row.upper), no_signal_snapshot.ratios)
    @test HSquared._h1t_validate_diagnostic_snapshot(no_signal_snapshot) === nothing

    malformed = _h1t_snapshot(
        (; interior..., Z2 = interior.Z2[:, 1:1]);
        expected_input_hashes = expected,
        provenance = provenance,
    )
    @test malformed.input.status == :input_setup_error
    @test all(row -> row.primary_terminal == :input_setup_error, malformed.ratios)

    mismatch = _h1t_snapshot(
        interior;
        expected_input_hashes = merge(expected, (y = repeat("0", 64),)),
        provenance = provenance,
    )
    @test mismatch.input.status == :provenance_mismatch
    @test all(row -> row.primary_terminal == :provenance_mismatch, mismatch.ratios)

    degenerate_raw_fit = (
        variance_components = (sigma1 = 1.0, sigma2 = 1.0, sigma_e2 = -2.0),
        ratio1 = Inf,
        ratio2 = Inf,
        loglik = -12.0,
        converged = false,
    )
    degenerate_fit = HSquared._h1t_fit_telemetry(
        degenerate_raw_fit,
        HSquared._h1t_empty_fit_telemetry(h1_controls.iterations).optimizer,
        h1_controls.iterations,
        h1_controls.boundary_tol,
    )
    degenerate = HSquared._h1t_failure_snapshot(
        provenance,
        snapshot.input,
        h1_controls,
        :denominator_degenerate;
        fit = degenerate_fit,
    )
    @test degenerate.fit.variance_components == (sigma1 = 1.0, sigma2 = 1.0, sigma_e2 = -2.0)
    @test degenerate.fit.total == 0.0
    @test isnan(degenerate.fit.ratio1)
    @test isnan(degenerate.fit.ratio2)
    @test all(isnan, (
        degenerate.fit.shares.sigma1,
        degenerate.fit.shares.sigma2,
        degenerate.fit.shares.sigma_e2,
    ))
    @test !degenerate.information.attempted
    @test all(isnan, degenerate.information.actual_steps)
    @test isempty(degenerate.information.evaluations)
    @test all(isnan, degenerate.information.eigenvalues)
    @test all(row -> row.primary_terminal == :denominator_degenerate &&
                          row.denominator_degenerate && !row.fd_attempted,
              degenerate.ratios)

    fd_trace = Dict{Symbol,Any}(:actual_steps => [1e-4, 1e-4, 1e-4])
    fd_error = try
        HSquared._h1t_fd_evaluation(
            _ -> error("injected FD failure"),
            [0.1, 0.2, 0.3],
            1,
            1,
            :plus_plus,
            fd_trace,
        )
        nothing
    catch err
        err
    end
    @test fd_error isa ErrorException
    @test length(fd_trace[:fd_evaluations]) == 1
    @test fd_trace[:fd_evaluations][1].finite === false
    @test fd_trace[:fd_evaluations][1].error_type == "ErrorException"
    @test fd_trace[:fd_evaluations][1].error_message == "injected FD failure"
    partial_information = HSquared._h1t_partial_information_summary(
        fd_trace,
        h1_controls.fd_step,
        fd_error,
    )
    partial_fd = HSquared._h1t_failure_snapshot(
        provenance,
        snapshot.input,
        h1_controls,
        HSquared._h1t_interval_failure_terminal(Dict(:stage => :fd_information));
        fit = snapshot.fit,
        information = partial_information,
        error = fd_error,
    )
    @test partial_fd.information.attempted
    @test partial_fd.information.actual_steps == [1e-4, 1e-4, 1e-4]
    @test length(partial_fd.information.evaluations) == 1
    @test partial_fd.information.evaluations[1].error_type == "ErrorException"
    @test partial_fd.information.evaluations[1].error_message == "injected FD failure"
    @test partial_fd.information.error_type == "ErrorException"
    @test partial_fd.information.error_message == "injected FD failure"
    @test all(row -> row.primary_terminal == :fd_evaluation_error_or_nonfinite &&
                          row.fd_attempted,
              partial_fd.ratios)

    stage_trace = Dict{Symbol,Any}(:stage => :fd_information)
    @test HSquared._h1t_interval_failure_terminal(stage_trace) ==
          :fd_evaluation_error_or_nonfinite
    @test HSquared._h1t_mark_delta_stage!(stage_trace) === nothing
    @test stage_trace[:stage] == :delta
    @test HSquared._h1t_interval_failure_terminal(stage_trace) ==
          :delta_nonfinite_or_invalid
    delta_trace = Dict{Symbol,Any}(
        :actual_steps => [1e-4, 1e-4, 1e-4],
        :fd_evaluations => NamedTuple[],
        :information_matrix => Matrix(1.0I, 3, 3),
    )
    partial_delta = HSquared._h1t_failure_snapshot(
        provenance,
        snapshot.input,
        h1_controls,
        HSquared._h1t_interval_failure_terminal(stage_trace);
        fit = snapshot.fit,
        information = HSquared._h1t_information_summary(delta_trace, h1_controls.fd_step),
        error = ErrorException("injected delta failure"),
    )
    @test partial_delta.information.attempted
    @test partial_delta.information.full_pd
    @test partial_delta.information.error_type == ""
    @test all(row -> row.primary_terminal == :delta_nonfinite_or_invalid &&
                          row.fd_attempted,
              partial_delta.ratios)

    @test_throws ArgumentError HSquared._h1t_validate_diagnostic_snapshot(
        merge(snapshot, (provenance = _h1t_provenance(derived_seed = 21270915),)),
    )
    @test_throws ArgumentError HSquared._h1t_validate_diagnostic_snapshot(
        merge(snapshot, (input = merge(snapshot.input, (
            fingerprints = merge(snapshot.input.fingerprints, (y = repeat("0", 64),)),
        )),)),
    )
    @test_throws ArgumentError HSquared._h1t_validate_diagnostic_snapshot(
        merge(snapshot, (ratios = (snapshot.ratios[1],),)),
    )
    @test_throws ArgumentError HSquared._h1t_validate_diagnostic_snapshot(
        merge(snapshot, (ratios = (snapshot.ratios[1], snapshot.ratios[1]),)),
    )
    @test_throws ArgumentError HSquared._h1t_validate_diagnostic_snapshot(
        merge(snapshot, (fit = merge(snapshot.fit, (
            optimizer = _h1t_without(snapshot.fit.optimizer, :termination_message),
        )),)),
    )

    nan_info = copy(snapshot.information.matrix)
    nan_info[1, 1] = NaN
    @test_throws ArgumentError HSquared._h1t_validate_diagnostic_snapshot(
        merge(snapshot, (information = merge(snapshot.information, (
            matrix = nan_info,
            finite = true,
            full_pd = true,
        )),)),
    )

    nonpd_info = copy(snapshot.information.matrix)
    nonpd_info[1, 1] = -abs(nonpd_info[1, 1]) - 1.0
    @test_throws ArgumentError HSquared._h1t_validate_diagnostic_snapshot(
        merge(snapshot, (information = merge(snapshot.information, (
            matrix = nonpd_info,
            finite = true,
            full_pd = true,
        )),)),
    )
    @test_throws ArgumentError HSquared._h1t_validate_diagnostic_snapshot(
        merge(snapshot, (
            information = merge(snapshot.information, (
                matrix = nonpd_info,
                finite = true,
                full_pd = false,
            )),
            ratios = (
                merge(snapshot.ratios[1], (kept_pd = true,)),
                merge(snapshot.ratios[2], (kept_pd = true,)),
            ),
        )),
    )

    boundary_mislabeled = merge(pure_snapshot.ratios[2], (
        public_boundary = false,
        own_numerator_boundary = false,
    ))
    @test_throws ArgumentError HSquared._h1t_validate_diagnostic_snapshot(
        merge(pure_snapshot, (ratios = (pure_snapshot.ratios[1], boundary_mislabeled),)),
    )
    @test_throws ArgumentError HSquared._h1t_validate_diagnostic_snapshot(
        merge(snapshot, (claim_eligible = true,)),
    )

    @test !(:_two_effect_diagnostic_snapshot in names(HSquared))
end

println("H1T_PARITY_OK")
println("H1T_MUTATION_OK")
println("H1T_TELEMETRY_SCHEMA_OK")
println("H1T_PUBLIC_API_FROZEN_OK")
println("H1T_TELEMETRY_TESTS_OK")
