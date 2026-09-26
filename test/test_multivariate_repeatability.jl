# Multivariate animal + permanent environment (hsquared #237).
# Experimental; no covered flip. Reduction and identity anchors, not a
# known-truth recovery gate (tiny n cannot split Va/Vpe tightly).

using HSquared
using LinearAlgebra
using Test

@testset "Multivariate repeatability REML (hsquared #237)" begin
    # Same 4-animal / 2-record fixture as Phase 3 univariate repeatability REML.
    Ainv = pedigree_inverse([1, 2, 3, 4], [0, 0, 1, 1], [0, 0, 2, 2])
    q = 4
    Z = zeros(8, 4)
    for (rec, an) in enumerate([1, 1, 2, 2, 3, 3, 4, 4])
        Z[rec, an] = 1.0
    end
    y = [14.0, 13.0, 6.9, 6.1, 12.1, 11.5, 8.9, 8.5]
    X = ones(8, 1)
    Y1 = reshape(y, 8, 1)
    Y2 = hcat(y, reverse(y) .+ 1.0)

    # t = 1 reduction: G0/P0/R0 recover univariate repeatability VCs.
    uni = fit_repeatability_reml(y, X, Z, Ainv)
    mv1 = fit_multivariate_repeatability_reml(Y1, X, Z, Ainv)
    @test mv1.estimator === :multivariate_repeatability_reml
    @test mv1.genetic_covariance[1, 1] ≈ uni.variance_components.sigma_a2 rtol = 0.08
    @test mv1.permanent_covariance[1, 1] ≈ uni.variance_components.sigma_pe2 atol = 1e-4 rtol = 0.08
    @test mv1.residual_covariance[1, 1] ≈ uni.variance_components.sigma_e2 rtol = 0.08
    @test 0 <= mv1.heritability[1] <= mv1.repeatability[1] + 1e-10
    @test mv1.repeatability[1] <= 1 + 1e-10

    # P0 = 0 identity: PE V equals animal-only V; loglik matches.
    A = inv(Symmetric(Matrix(Float64.(Matrix(Ainv)))))
    yvec, Xfull, Zfull, indiv, N = HSquared._mv_observed(Y2, X, Z, 8, 2, q, 1)
    G0 = [0.8 0.2; 0.2 1.1]
    R0 = [0.7 0.1; 0.1 0.9]
    P0 = [0.5 0.1; 0.1 0.4]
    P0z = zeros(2, 2)
    ll_pe0 = HSquared._mv_pe_reml_loglik_core(yvec, Xfull, Zfull, A, indiv, N, G0, P0z, R0)
    ll_mv = HSquared._mv_reml_loglik_core(yvec, Xfull, Zfull, A, indiv, N, G0, R0)
    @test ll_pe0 ≈ ll_mv atol = 1e-8

    # A ≠ I: folding P0 into G0 is not the same model. PE is not absorbed.
    ll_pe = HSquared._mv_pe_reml_loglik_core(yvec, Xfull, Zfull, A, indiv, N, G0, P0, R0)
    ll_absorbed = HSquared._mv_reml_loglik_core(yvec, Xfull, Zfull, A, indiv, N, G0 .+ P0, R0)
    @test !isapprox(ll_pe, ll_absorbed; atol = 1e-6)
    println("PE_NOT_ABSORBED")

    mv2 = fit_multivariate_repeatability_reml(Y2, X, Z, Ainv)
    @test size(mv2.genetic_covariance) == (2, 2)
    @test size(mv2.permanent_covariance) == (2, 2)
    @test size(mv2.residual_covariance) == (2, 2)
    @test all(diag(mv2.genetic_covariance) .> 0)
    @test all(diag(mv2.permanent_covariance) .>= 0)
    @test all(diag(mv2.residual_covariance) .> 0)
    @test all(0 .<= mv2.heritability .<= 1)
    @test all(0 .<= mv2.repeatability .<= 1)
    @test all(mv2.heritability .<= mv2.repeatability .+ 1e-10)

    vc = variance_components(mv2)
    @test hasproperty(vc, :permanent_covariance)
    @test vc.permanent_covariance ≈ mv2.permanent_covariance
    @test heritability(mv2) ≈ mv2.heritability
    @test size(mv2.permanent_effects.values) == (q, 2)
    @test size(mv2.breeding_values.values) == (q, 2)

    payload = multivariate_repeatability_result_payload(mv2)
    @test payload.target == "multivariate_repeatability_reml"
    @test payload.status == "experimental"
    @test payload.component_names == ["animal", "permanent", "residual"]
    @test payload.component_dimensions.animal == (q, 2)
    @test payload.component_dimensions.permanent == (q, 2)
    @test payload.component_dimensions.residual == (8, 2)
    @test size(payload.genetic_covariance) == (2, 2)
    @test size(payload.permanent_covariance) == (2, 2)
    @test size(payload.residual_covariance) == (2, 2)
    @test length(payload.heritability) == 2
    @test length(payload.repeatability) == 2
    println("G4_PAYLOAD_CONTRACT")

    Ipe = Matrix(1.0I, q, q)
    payload_in = Dict(
        "payload_version" => 2,
        "Y" => Y2,
        "X" => X,
        "method" => "REML",
        "random_effects" => [
            Dict(
                "name" => "animal",
                "type" => "pedigree",
                "relmat_status" => "supplied",
                "relmat_inverse" => Matrix(Ainv),
                "ids" => collect(1:q),
                "Z" => Z,
            ),
            Dict(
                "name" => "permanent",
                "type" => "iid",
                "relmat_status" => "supplied",
                "relmat_inverse" => Ipe,
                "ids" => collect(1:q),
                "Z" => Z,
            ),
        ],
    )
    parsed = parse_payload_v2(payload_in)
    @test parsed.dispatch === :multivariate_repeatability
    @test parsed.is_multivariate
    fit_v2 = fit_payload_v2(payload_in)
    out = result_payload_v2(fit_v2, parsed)
    @test out.target == "multivariate_repeatability_reml"
    @test out.component_names == ["animal", "permanent", "residual"]
end
