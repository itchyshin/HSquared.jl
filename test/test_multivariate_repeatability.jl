# Multivariate animal + permanent environment (hsquared #237).
# Experimental; no covered flip. Reduction and identity anchors, not a
# known-truth recovery gate (tiny n cannot split Va/Vpe tightly).

using DelimitedFiles: readdlm
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
                "relmat_status" => "identity",
                "ids" => collect(1:q),
                "Z" => Z,
            ),
        ],
    )
    parsed = parse_payload_v2(payload_in)
    @test parsed.dispatch === :multivariate_repeatability
    @test parsed.is_multivariate

    payload_ml = deepcopy(payload_in)
    payload_ml["method"] = "ML"
    @test_throws ArgumentError fit_payload_v2(payload_ml)

    payload_bad_pe = deepcopy(payload_in)
    bad_pe_Z = copy(Z)
    bad_pe_Z[1, 1] = 0.0
    bad_pe_Z[1, 2] = 1.0
    payload_bad_pe["random_effects"][2]["Z"] = bad_pe_Z
    @test_throws ArgumentError parse_payload_v2(payload_bad_pe)

    payload_bad_ids = deepcopy(payload_in)
    payload_bad_ids["random_effects"][2]["ids"] = reverse(collect(1:q))
    @test_throws ArgumentError parse_payload_v2(payload_bad_ids)

    fit_v2 = fit_payload_v2(payload_in)
    out = result_payload_v2(fit_v2, parsed)
    @test out.target == "multivariate_repeatability_reml"
    @test out.component_names == ["animal", "permanent", "residual"]
    @test out.traits == fit_v2.traits
    @test hasproperty(out, :variance_components)
    @test hasproperty(out.variance_components, :residual)
    @test length(out.variance_components.blocks) == 2
    @test out.variance_components.blocks[1].name == "animal"
    @test out.variance_components.blocks[2].name == "permanent"
    @test out.variance_components.blocks[1].variance ≈ fit_v2.genetic_covariance
    @test out.variance_components.blocks[2].variance ≈ fit_v2.permanent_covariance
    @test out.variance_components.residual ≈ fit_v2.residual_covariance
    @test [effect.name for effect in out.random_effects] == ["animal", "permanent"]
    @test out.random_effects[1].ids == fit_v2.breeding_values.ids
    @test out.random_effects[1].values ≈ fit_v2.breeding_values.values
    @test out.random_effects[2].ids == fit_v2.permanent_effects.ids
    @test out.random_effects[2].values ≈ fit_v2.permanent_effects.values
    @test size(out.random_effects[1].values) == (q, length(out.traits))
    @test size(out.random_effects[2].values) == (q, length(out.traits))
    @test size(out.variance_components.residual) == (length(out.traits), length(out.traits))
    @test out.nobs == length(Y2)
    @test out.df == 2 + 3 * 3
    @test out.diagnostics.method === :REML
    @test out.diagnostics.loglik_convention === :reml_full_constant

    payload_custom_names = deepcopy(payload_in)
    payload_custom_names["random_effects"][1]["name"] = "dam"
    payload_custom_names["random_effects"][2]["name"] = "plot"
    parsed_custom_names = parse_payload_v2(payload_custom_names)
    fit_custom_names = fit_payload_v2(payload_custom_names)
    out_custom_names = result_payload_v2(fit_custom_names, parsed_custom_names)
    @test out_custom_names.component_names == ["dam", "plot", "residual"]
    @test [effect.name for effect in out_custom_names.random_effects] == ["dam", "plot"]
end

@testset "optimizer Cholesky covariance proposals reject underflow and overflow" begin
    params = HSquared._cov_to_chol_params(Matrix{Float64}(I, 2, 2), 2)
    @test HSquared._try_chol_params_to_cov(params, 2) ≈ Matrix{Float64}(I, 2, 2)

    underflow = copy(params)
    underflow[1] = -1000.0
    underflow[3] = -1000.0
    collapsed = HSquared._chol_params_to_cov(underflow, 2)
    @test iszero(collapsed[1, 1])
    @test iszero(collapsed[2, 2])
    @test HSquared._try_chol_params_to_cov(underflow, 2) === nothing

    overflow = copy(params)
    overflow[1] = 1000.0
    @test HSquared._try_chol_params_to_cov(overflow, 2) === nothing
end

@testset "optimizer log-variance proposals reject underflow and overflow" begin
    @test HSquared._try_positive_exp([0.0, log(2.0)]) ≈ [1.0, 2.0]
    @test HSquared._try_positive_exp([-1000.0]) === nothing
    @test HSquared._try_positive_exp([1000.0]) === nothing

    X = ones(2, 1)
    Z = Matrix{Float64}(I, 2, 2)
    Ainv = Matrix{Float64}(I, 2, 2)
    y = [1.0, 2.0]
    @test_throws ArgumentError fit_repeatability_reml(
        y, X, Z, Ainv; initial = (sigma_a2 = 1.0, sigma_pe2 = 1.0, sigma_e2 = Inf))
    @test_throws ArgumentError fit_two_effect_reml(
        y, X, Z, Ainv, Z, Ainv; initial = (sigma1 = 1.0, sigma2 = 1.0, sigma_e2 = Inf))
    @test_throws ArgumentError fit_multi_effect_reml(
        y, X, [(Z, Ainv)]; initial = [Inf, 1.0])
    @test_throws ArgumentError fit_direct_maternal_reml(
        y, X, Z, Z, Ainv; initial = (G_dm = Matrix{Float64}(I, 2, 2), sigma_e2 = Inf))
end

@testset "multivariate genetic covariance candidates preserve correlation contract" begin
    @test HSquared._mv_genetic_covariance_admissible(Matrix{Float64}(I, 2, 2), :unstructured)
    @test !HSquared._mv_genetic_covariance_admissible([1.0 0.0; 0.0 0.0], :diagonal)
    @test HSquared._mv_genetic_covariance_admissible([1.0 1.0; 1.0 1.0], :lowrank)
    @test !HSquared._mv_genetic_covariance_admissible([1.0 1.0; 1.0 1.0], :unstructured)

    Y = [0.0 0.4; 1.0 -0.3]
    X = ones(2, 1)
    Z = Matrix{Float64}(I, 2, 2)
    A = Matrix{Float64}(I, 2, 2)
    yvec, Xfull, Zfull, indiv, N = HSquared._mv_observed(Y, X, Z, 2, 2, 2, 1)
    params = vcat(HSquared._cov_to_chol_params(A, 2), HSquared._cov_to_chol_params(A, 2))
    objective = p -> HSquared._mv_reml_objective(
        p, yvec, Xfull, Zfull, A, indiv, N, 2, :unstructured, 2, 3)
    @test isfinite(objective(params))
    genetic_underflow = copy(params)
    genetic_underflow[1] = -1000.0
    genetic_underflow[3] = -1000.0
    @test objective(genetic_underflow) == Inf
end

# Known-truth G0 and P0 recovery (hsquared #237). Y is the Julia 1.10 pin in
# test/fixtures/hs237_mv_pe_recovery/Y.csv — Julia 1.13 changed randn() and
# MersenneTwister(Int) uniforms, so a live seed is not a pin. The multi-seed
# |bias|<=2*MCSE screen lives in
# sim/phase4_multivariate_repeatability_recovery.jl (GATE_PASS/FAIL is data).
const _HS237_Y_PATH = joinpath(@__DIR__, "fixtures", "hs237_mv_pe_recovery", "Y.csv")
const _HS237_Y_SUM = 1110.1019795549014

function _hs237_halfsib(nsire, ndam, noffspring)
    sire_ids = ["s$i" for i in 1:nsire]
    dam_ids = ["d$i" for i in 1:ndam]
    off_ids = ["o$i" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(
        fill("0", nsire + ndam),
        [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring],
    )
    dam = vcat(
        fill("0", nsire + ndam),
        [dam_ids[((i - 1) % ndam) + 1] for i in 1:noffspring],
    )
    return normalize_pedigree(ids, sire, dam)
end

function _hs237_fixture()
    G0 = [1.00 0.30; 0.30 0.80]
    P0 = [0.50 0.10; 0.10 0.40]
    R0 = [0.80 0.15; 0.15 0.70]
    raw, _hdr = readdlm(_HS237_Y_PATH, ','; header = true)
    Y = Float64.(raw)
    size(Y) == (288, 2) || error("hs237 Y fixture must be 288×2, got $(size(Y))")
    isapprox(sum(Y), _HS237_Y_SUM; atol = 1e-8) ||
        error("hs237 Y fixture checksum mismatch: $(sum(Y))")
    ped = _hs237_halfsib(8, 16, 48)
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    records = 4
    n = q * records
    n == size(Y, 1) || error("hs237 Y rows must match pedigree × records")
    X = ones(n, 1)
    Z = zeros(n, q)
    row = 1
    for animal in 1:q, _rep in 1:records
        Z[row, animal] = 1.0
        row += 1
    end
    return Y, X, Z, Ainv, G0, P0, R0
end

@testset "Multivariate repeatability known-truth recovery (hsquared #237)" begin
    Y, X, Z, Ainv, G0, P0, R0 = _hs237_fixture()
    pe = fit_multivariate_repeatability_reml(
        Y, X, Z, Ainv;
        initial = (G0 = G0, P0 = P0, R0 = R0),
    )
    @test pe.estimator === :multivariate_repeatability_reml
    @test pe.converged
    ttrue = [(G0[k, k] + P0[k, k]) / (G0[k, k] + P0[k, k] + R0[k, k]) for k in 1:2]
    @test pe.repeatability[1] ≈ ttrue[1] atol = 0.12
    @test pe.genetic_covariance[1, 1] ≈ G0[1, 1] atol = 0.25
    @test pe.permanent_covariance[1, 1] ≈ P0[1, 1] atol = 0.25
    @test pe.residual_covariance[1, 1] ≈ R0[1, 1] rtol = 0.15
    println("G0_P0_RECOVERY_PINNED")

    absorbed = fit_multivariate_reml(Y, X, Z, Ainv)
    @test absorbed.genetic_covariance[1, 1] > pe.genetic_covariance[1, 1]
    @test abs(pe.genetic_covariance[1, 1] - G0[1, 1]) <
          abs(absorbed.genetic_covariance[1, 1] - G0[1, 1])
    println("PE_AWARE_NOT_ABSORBED")
end
