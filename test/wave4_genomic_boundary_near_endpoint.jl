using Test, LinearAlgebra, SparseArrays, HSquared

@testset "genomic boundary profile retains a near-endpoint interior optimum" begin
    y = [sqrt(3) / 2, 1 / 2, 0.0]
    X = [0.0; 0.0; 1.0;;]
    Z = sparse(1.0I, 3, 3)
    K = Matrix(Diagonal([1 + 1e8, 1 / 2, 1.0]))
    Q = inv(K)
    ids = ["near$(i)" for i in 1:3]
    provenance = (
        relationship_source = "markers",
        relationship_method = "near_endpoint_test_kernel",
        allele_frequency_source = "deterministic_test",
        ridge = 0.0,
        scale_denominator = 1.0,
        relationship_scale = "K_test",
        id_order_fingerprint = HSquared._genomic_id_order_fingerprint(ids),
        marker_content_fingerprint = repeat("0", 64),
        kernel_fingerprint = HSquared._genomic_matrix_fingerprint("K_lambda", K, ids),
        precision_fingerprint = HSquared._genomic_matrix_fingerprint("Q_lambda", Q, ids),
    )
    spec = animal_model_spec(y, X, Z, Q; ids = ids, method = :REML)
    precheck = HSquared._genomic_boundary_precheck(spec, provenance, K)
    @test precheck.ok
    context = HSquared._genomic_profile_context(precheck)
    @test HSquared._genomic_profile_derivative(context, 0.0) ≈
          (1e8 / 4 + 1 / 8) / 3 rtol = 1e-10
    lower_value = HSquared._genomic_profile_reml(context, 0.0).loglik
    delta_value = HSquared._genomic_profile_reml(context, 1e-6).loglik
    @test (delta_value - lower_value) / 1e-6 / 3 < 0

    profile = HSquared._genomic_boundary_profile(spec, precheck)
    @test profile.status == "boundary_unresolved"
    @test profile.reason == "endpoint_adjacent_candidate_beats_endpoint"

    @test HSquared._genomic_boundary_variances_representable(1.0, 1.0)
    @test !HSquared._genomic_boundary_variances_representable(0.0, 1.0)
    @test !HSquared._genomic_boundary_variances_representable(5e-321, 1.0)
    tie_tol = 3 * 1e-10
    @test HSquared._genomic_endpoint_adjacent_improves(5e-8, tie_tol / 2, 0.0, -1.0)
    @test HSquared._genomic_endpoint_adjacent_improves(1 - 5e-8, tie_tol / 2, -1.0, 0.0)
    @test !HSquared._genomic_endpoint_adjacent_improves(5e-8, 0.0, 0.0, -1.0)
    @test !HSquared._genomic_endpoint_adjacent_improves(0.5, tie_tol / 2, 0.0, -1.0)

    tiny_y = [1e-160, 0.0, 0.0]
    tiny_X = [0.0; 0.0; 1.0;;]
    tiny_K = Matrix(Diagonal([2.0, 3.0, 1.0]))
    tiny_Q = inv(tiny_K)
    tiny_ids = ["tiny$(i)" for i in 1:3]
    tiny_provenance = (
        relationship_source = "markers",
        relationship_method = "underflow_test_kernel",
        allele_frequency_source = "deterministic_test",
        ridge = 0.0,
        scale_denominator = 1.0,
        relationship_scale = "K_test",
        id_order_fingerprint = HSquared._genomic_id_order_fingerprint(tiny_ids),
        marker_content_fingerprint = repeat("1", 64),
        kernel_fingerprint = HSquared._genomic_matrix_fingerprint("K_lambda", tiny_K, tiny_ids),
        precision_fingerprint = HSquared._genomic_matrix_fingerprint("Q_lambda", tiny_Q, tiny_ids),
    )
    tiny_spec = animal_model_spec(tiny_y, tiny_X, Z, tiny_Q; ids = tiny_ids, method = :REML)
    tiny_result = HSquared._fit_ai_reml_genomic_boundary(tiny_spec;
        provenance = tiny_provenance, kernel = tiny_K, iterations = 1)
    @test tiny_result.boundary.status == "boundary_unresolved"
    @test tiny_result.boundary.reason in
          ("interior_profile_variance_unrepresentable", "boundary_variance_unrepresentable")

    derivative_context = (
        eigenvalues = [0.45, 0.8, 1.25, 2.1, 3.0],
        y = [0.7, -1.0, 0.4, 1.3, -0.2],
        X = hcat(ones(5), [-1.0, -0.5, 0.0, 0.5, 1.0]),
        n = 5,
        p = 2,
    )
    delta = 1e-6
    for ratio in (0.0, 1.0)
        endpoint = HSquared._genomic_profile_reml(derivative_context, ratio).loglik
        nearby = HSquared._genomic_profile_reml(
            derivative_context, ratio == 0.0 ? delta : 1.0 - delta).loglik
        finite_difference = ratio == 0.0 ? (nearby - endpoint) / delta / 5 :
                            (endpoint - nearby) / delta / 5
        analytic = HSquared._genomic_profile_derivative(derivative_context, ratio)
        @test analytic ≈ finite_difference atol = 2e-5 rtol = 2e-5
    end

    malformed = (
        merge(provenance, (relationship_source = missing,)),
        merge(provenance, (id_order_fingerprint = missing,)),
        merge(provenance, (precision_fingerprint = missing,)),
        merge(provenance, (kernel_fingerprint = missing,)),
    )
    for bad_provenance in malformed
        result = HSquared._fit_ai_reml_genomic_boundary(spec;
            provenance = bad_provenance, kernel = K)
        @test result.fit === nothing
        @test result.boundary.status == "boundary_unresolved"
    end

    failed_factorization = HSquared._genomic_boundary_numerical_guard(
        () -> throw(PosDefException(1)), nothing, "numerical_factorization_failure")
    @test failed_factorization.ok == false
    @test failed_factorization.result.fit === nothing
    @test failed_factorization.result.boundary.reason == "numerical_factorization_failure"
    @test_throws ArgumentError HSquared._genomic_boundary_numerical_guard(
        () -> throw(ArgumentError("invalid control")), nothing,
        "numerical_factorization_failure")
end
