using HSquared
using LinearAlgebra
using SparseArrays
using Test

function _dense_relationship_for_test(pedigree)
    n = length(pedigree)
    A = zeros(Float64, n, n)

    for i in 1:n
        sire = pedigree.sire[i]
        dam = pedigree.dam[i]

        for j in 1:(i - 1)
            value = 0.0
            sire == 0 || (value += 0.5 * A[sire, j])
            dam == 0 || (value += 0.5 * A[dam, j])
            A[i, j] = value
            A[j, i] = value
        end

        A[i, i] = sire != 0 && dam != 0 ? 1.0 + 0.5 * A[sire, dam] : 1.0
    end

    return A
end

function _solve_mme_for_test(y, X, Z, Ainv, sigma_a2, sigma_e2)
    yv = Float64.(y)
    Xd = Matrix{Float64}(X)
    Zd = Matrix{Float64}(Z)
    Q = Matrix{Float64}(Ainv)
    n = length(yv)

    Rinv = Matrix{Float64}(I, n, n) / sigma_e2
    Ginv = Q / sigma_a2

    lhs = [
        transpose(Xd) * Rinv * Xd transpose(Xd) * Rinv * Zd
        transpose(Zd) * Rinv * Xd transpose(Zd) * Rinv * Zd + Ginv
    ]
    rhs = [transpose(Xd) * Rinv * yv; transpose(Zd) * Rinv * yv]
    solution = lhs \ rhs

    p = size(Xd, 2)
    return solution[1:p], solution[(p + 1):end]
end

function _mme_inverse_random_block_for_test(X, Z, Ainv, sigma_a2, sigma_e2)
    Xd = Matrix{Float64}(X)
    Zd = Matrix{Float64}(Z)
    Q = Matrix{Float64}(Ainv)
    n = size(Xd, 1)

    Rinv = Matrix{Float64}(I, n, n) / sigma_e2
    Ginv = Q / sigma_a2

    lhs = [
        transpose(Xd) * Rinv * Xd transpose(Xd) * Rinv * Zd
        transpose(Zd) * Rinv * Xd transpose(Zd) * Rinv * Zd + Ginv
    ]
    inverse_lhs = inv(Symmetric(lhs))
    p = size(Xd, 2)
    return inverse_lhs[(p + 1):end, (p + 1):end]
end

@testset "HSquared Phase 0 scaffold" begin
    control = HSControl()

    @test control.backend isa AutoBackend
    @test control.accelerator == :auto
    @test control.precision === Float64
    @test control.save == :minimal
    @test control.save_fitted == false
    @test control.save_residuals == false
    @test control.save_design == false
    @test control.save_factorization == false
    @test control.disk_cache == false

    @test HSControl(backend = :cpu).backend isa CPUBackend
    @test HSControl(backend = "cuda", accelerator = "cuda", precision = Float32, save = "tiny").backend isa CUDABackend

    @test_throws ArgumentError HSControl(backend = :bogus)
    @test_throws ArgumentError HSControl(accelerator = :metal)
    @test_throws ArgumentError HSControl(precision = Float16)
    @test_throws ArgumentError HSControl(save = :everything)

    @test_throws Phase0NotImplementedError hsquared(nothing)
    @test_throws Phase0NotImplementedError fit_animal_model(nothing)
end

@testset "Phase 1 pedigree normalization and Ainv" begin
    ped = normalize_pedigree(
        ["calf", "sire", "dam"],
        ["sire", "0", "0"],
        ["dam", "0", "0"],
    )

    @test ped.ids == ["sire", "dam", "calf"]
    @test ped.sire == [0, 0, 1]
    @test ped.dam == [0, 0, 2]
    @test ped.original_order == [2, 3, 1]

    Ainv = pedigree_inverse(ped)
    @test Ainv isa SparseMatrixCSC{Float64,Int}
    @test Matrix(Ainv) ≈ [
        1.5 0.5 -1.0
        0.5 1.5 -1.0
        -1.0 -1.0 2.0
    ]
    @test Matrix(pedigree_inverse(["calf", "sire", "dam"], ["sire", "0", "0"], ["dam", "0", "0"])) ≈ Matrix(Ainv)

    one_parent = normalize_pedigree(["a", "b"], ["0", "a"], ["0", "0"])
    @test Matrix(pedigree_inverse(one_parent)) ≈ [
        4 / 3 -2 / 3
        -2 / 3 4 / 3
    ]

    inbred = normalize_pedigree(
        ["founder_a", "founder_b", "parent", "offspring"],
        ["0", "0", "founder_a", "founder_a"],
        ["0", "0", "founder_b", "parent"],
    )
    @test inbreeding_coefficients(inbred) ≈ [0.0, 0.0, 0.0, 0.25]
    @test inbreeding_coefficients(
        ["founder_a", "founder_b", "parent", "offspring"],
        ["0", "0", "founder_a", "founder_a"],
        ["0", "0", "founder_b", "parent"],
    ) ≈ [0.0, 0.0, 0.0, 0.25]
    @test Matrix(pedigree_inverse(inbred)) ≈ inv(_dense_relationship_for_test(inbred))

    @test_throws ArgumentError normalize_pedigree(["a", "a"], ["0", "0"], ["0", "0"])
    @test_throws ArgumentError normalize_pedigree(["a"], ["b"], ["0"])
    @test_throws ArgumentError normalize_pedigree(["a"], ["a"], ["0"])
    @test_throws ArgumentError normalize_pedigree(["a", "b"], ["b", "a"], ["0", "0"])
    @test_throws ArgumentError normalize_pedigree(["a", "b"], ["0", "a"], ["0", "a"])
    @test_throws ArgumentError inbreeding_coefficients(ped; max_relationship_cache = 2)
end

@testset "Phase 1 HSData ID container" begin
    phenotypes = (
        id = ["animal_1", "animal_1", "animal_2"],
        y = [1.0, 1.5, 2.0],
    )
    pedigree = normalize_pedigree(
        ["founder", "animal_1", "animal_2"],
        ["0", "founder", "founder"],
        ["0", "0", "0"],
    )
    genotypes = [
        0.0 1.0
        1.0 0.0
        2.0 2.0
    ]
    expression = (
        id = ["animal_2", "animal_4"],
        gene_a = [4.0, 5.0],
    )

    data = HSData(
        phenotypes;
        id = :id,
        pedigree = pedigree,
        genotypes = genotypes,
        genotype_ids = ["animal_1", "animal_3", "founder"],
        expression = expression,
        expression_id = :id,
    )

    @test data isa HSData
    @test data.pedigree === pedigree
    @test id_map(data) isa HSDataIDMap
    @test id_map(data).phenotype_ids == ["animal_1", "animal_2"]
    @test id_map(data).pedigree_ids == pedigree.ids
    @test id_map(data).genotype_ids == ["animal_1", "animal_3", "founder"]
    @test id_map(data).expression_ids == ["animal_2", "animal_4"]
    @test id_map(data).phenotypes_without_pedigree == []
    @test id_map(data).phenotypes_without_genotypes == ["animal_2"]
    @test id_map(data).phenotypes_without_expression == ["animal_1"]
    @test id_map(data).genotypes_without_phenotypes == ["animal_3", "founder"]
    @test id_map(data).expression_without_phenotypes == ["animal_4"]

    raw_pedigree = (
        id = ["animal_1", "animal_2", "founder"],
        sire = ["founder", "founder", "0"],
        dam = ["0", "0", "0"],
    )
    raw_data = HSData(phenotypes; pedigree = raw_pedigree)
    @test id_map(raw_data).pedigree_ids == ["animal_1", "animal_2", "founder"]

    @test_throws ArgumentError HSData((id = ["animal_1", missing], y = [1.0, 2.0]))
    @test_throws ArgumentError HSData(phenotypes; pedigree = (id = ["animal_1"],))
    @test_throws ArgumentError HSData(phenotypes; genotypes = genotypes)
    @test_throws ArgumentError HSData(phenotypes; genotypes = genotypes, genotype_ids = ["a"])
    @test_throws ArgumentError HSData(phenotypes; genotypes = genotypes, genotype_ids = ["a", "a", "b"])
    @test_throws ArgumentError HSData(; phenotypes = (animal = ["a"], y = [1.0]))
end

@testset "Phase 1 sparse CSC bridge marshalling" begin
    Z = sparse(
        [1, 3, 2, 4],
        [1, 1, 3, 3],
        [1.0, 2.0, 3.0, 4.0],
        4,
        3,
    )

    from_r_slots = sparse_csc_matrix(
        size(Z, 1),
        size(Z, 2),
        Z.colptr .- 1,
        Z.rowval .- 1,
        Z.nzval,
    )
    @test from_r_slots isa SparseMatrixCSC{Float64,Int}
    @test from_r_slots == Z

    from_julia_slots = sparse_csc_matrix(
        size(Z, 1),
        size(Z, 2),
        Z.colptr,
        Z.rowval,
        Z.nzval;
        index_base = :one,
    )
    @test from_julia_slots == Z
    @test sparse_csc_matrix(4, 3, Z.colptr .- 1, Z.rowval .- 1, Z.nzval; index_base = "r") == Z
    @test sparse_csc_matrix(4, 3, Z.colptr, Z.rowval, Z.nzval; index_base = "julia") == Z

    y = [1.0, 2.0, 3.0, 4.0]
    X = ones(4, 1)
    Ainv = sparse(I, 3, 3)
    fit_from_slots = fit_animal_model(
        y,
        X,
        from_r_slots,
        Ainv;
        ids = ["a", "b", "c"],
        method = :ML,
        initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
        iterations = 25,
    )
    fit_from_sparse = fit_animal_model(
        y,
        X,
        Z,
        Ainv;
        ids = ["a", "b", "c"],
        method = :ML,
        initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
        iterations = 25,
    )
    @test fit_from_slots.likelihood.loglik ≈ fit_from_sparse.likelihood.loglik

    @test_throws ArgumentError sparse_csc_matrix(0, 3, Z.colptr .- 1, Z.rowval .- 1, Z.nzval)
    @test_throws ArgumentError sparse_csc_matrix(4, 0, Z.colptr .- 1, Z.rowval .- 1, Z.nzval)
    @test_throws ArgumentError sparse_csc_matrix(4, 3, [0, 2], Z.rowval .- 1, Z.nzval)
    @test_throws ArgumentError sparse_csc_matrix(4, 3, [1, 2, 3, 5], Z.rowval .- 1, Z.nzval)
    @test_throws ArgumentError sparse_csc_matrix(4, 3, [0, 3, 2, 4], Z.rowval .- 1, Z.nzval)
    @test_throws ArgumentError sparse_csc_matrix(4, 3, Z.colptr .- 1, [0, 4, 1, 3], Z.nzval)
    @test_throws ArgumentError sparse_csc_matrix(4, 3, Z.colptr .- 1, [2, 0, 1, 3], Z.nzval)
    @test_throws ArgumentError sparse_csc_matrix(4, 3, Z.colptr .- 1, Z.rowval .- 1, Z.nzval[1:3])
    @test_throws ArgumentError sparse_csc_matrix(4, 3, Z.colptr .- 1, Z.rowval .- 1, Z.nzval; index_base = :two)
end

@testset "Phase 1 animal model spec validation" begin
    y = [1.0, 2.0, 3.0]
    X = [1.0 0.0; 1.0 1.0; 1.0 2.0]
    Z = sparse(I, 3, 3)
    Ainv = sparse(I, 3, 3)

    spec = animal_model_spec(y, X, Z, Ainv; ids = ["a", "b", "c"], method = "reml")

    @test spec.y === y
    @test spec.X === X
    @test spec.Z === Z
    @test spec.Ainv === Ainv
    @test spec.ids == ["a", "b", "c"]
    @test spec.family isa GaussianFamily
    @test spec.method == :REML

    ml_spec = animal_model_spec(y, X, Z, Ainv; method = :ml)
    @test ml_spec.ids == [1, 2, 3]
    @test ml_spec.method == :ML

    @test_throws ArgumentError animal_model_spec(y, X[1:2, :], Z, Ainv)
    @test_throws ArgumentError animal_model_spec(y, X, Z[1:2, :], Ainv)
    @test_throws ArgumentError animal_model_spec(y, X, Z[:, 1:2], Ainv)
    @test_throws ArgumentError animal_model_spec(y, X, Z, sparse(ones(2, 3)))
    @test_throws ArgumentError animal_model_spec(y, X, Z, Ainv; ids = ["a", "b"])
    @test_throws ArgumentError animal_model_spec(y, X, Z, Ainv; family = :gaussian)
    @test_throws ArgumentError animal_model_spec(y, X, Z, Ainv; method = :AI_REML)
end

@testset "Phase 1 Gaussian likelihood evaluation" begin
    y = [1.0, 2.0, 3.0]
    X = ones(3, 1)
    Z = sparse(I, 3, 3)
    Ainv = sparse(I, 3, 3)
    spec = animal_model_spec(y, X, Z, Ainv)

    ml = gaussian_loglik(spec, 1.0, 1.0; method = :ML)
    @test ml.method == :ML
    @test ml.beta ≈ [2.0]
    @test ml.sigma_a2 == 1.0
    @test ml.sigma_e2 == 1.0
    @test ml.nobs == 3
    @test ml.nfixed == 1
    @test ml.loglik ≈ -0.5 * (3 * log(2 * pi) + 3 * log(2.0) + 1.0)

    reml = gaussian_loglik(spec, 1.0, 1.0)
    @test reml.method == :REML
    @test reml.beta ≈ [2.0]
    @test reml.loglik ≈ -0.5 * (2 * log(2 * pi) + 3 * log(2.0) + log(1.5) + 1.0)

    @test_throws ArgumentError gaussian_loglik(spec, 0.0, 1.0)
    @test_throws ArgumentError gaussian_loglik(spec, 1.0, -1.0)
    @test_throws ArgumentError gaussian_loglik(spec, 1.0, 1.0; method = :AI_REML)
    saturated = animal_model_spec(y, Matrix(I, 3, 3), Z, Ainv)
    @test_throws ArgumentError gaussian_loglik(saturated, 1.0, 1.0)
end

@testset "Phase 1 dense variance component fitting" begin
    ids = ["sire", "dam", "calf"]
    ped = normalize_pedigree(ids, ["0", "0", "sire"], ["0", "0", "dam"])
    Ainv = pedigree_inverse(ped)
    y = [1.0, 2.5, 4.0]
    X = ones(3, 1)
    Z = sparse(I, 3, 3)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :ML)

    start = gaussian_loglik(spec, 1.0, 1.0; method = :ML)
    fit = fit_variance_components(spec; initial = (sigma_a2 = 0.5, sigma_e2 = 0.5), method = :ML)

    @test fit isa AnimalModelFit
    @test fit.spec === spec
    @test fit.likelihood.method == :ML
    @test fit.likelihood.loglik >= start.loglik
    @test fit.variance_components.sigma_a2 > 0
    @test fit.variance_components.sigma_e2 > 0
    @test fit.iterations > 0
    @test fit.optimizer_status in ("converged", "not_converged")

    fit2 = fit_animal_model(spec; initial = [1.0, 1.0], iterations = 100)
    @test fit2 isa AnimalModelFit
    @test_throws ArgumentError fit_variance_components(spec; initial = (sigma_a2 = 1.0,))
    @test_throws ArgumentError fit_variance_components(spec; initial = [1.0])
    @test_throws ArgumentError fit_variance_components(spec; initial = (sigma_a2 = -1.0, sigma_e2 = 1.0))
end

@testset "Phase 1 dense fit extractors" begin
    y = [1.0, 2.0, 3.0]
    X = ones(3, 1)
    Z = sparse(I, 3, 3)
    Ainv = sparse(I, 3, 3)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ["a", "b", "c"], method = :ML)
    likelihood = gaussian_loglik(spec, 1.0, 1.0; method = :ML)
    fit = AnimalModelFit(
        spec,
        likelihood,
        (sigma_a2 = 1.0, sigma_e2 = 1.0),
        true,
        "test",
        0,
    )

    vc = variance_components(fit)
    @test vc.sigma_a2 == 1.0
    @test vc.sigma_e2 == 1.0
    @test fixed_effects(fit) ≈ [2.0]

    ebv = breeding_values(fit)
    @test ebv isa BreedingValues
    @test ebv.ids == ["a", "b", "c"]
    @test ebv.values ≈ [-0.5, 0.0, 0.5]

    @test fitted_values(fit) ≈ [1.5, 2.0, 2.5]
    @test fitted_values(fit; include_random = false) ≈ [2.0, 2.0, 2.0]
    @test heritability(fit) ≈ 0.5
    @test prediction_error_variance(fit).ids == ["a", "b", "c"]
    @test prediction_error_variance(fit).values ≈ diag(_mme_inverse_random_block_for_test(X, Z, Ainv, 1.0, 1.0))
    @test reliability(fit).ids == ["a", "b", "c"]
    @test reliability(fit).values ≈ 1 .- prediction_error_variance(fit).values

    payload = result_payload(fit)
    @test propertynames(payload) == (
        :variance_components,
        :heritability,
        :breeding_values,
        :fixed_effects,
        :random_effects,
        :loglik,
        :df,
        :nobs,
        :predictions,
        :diagnostics,
        :converged,
    )
    @test payload.variance_components == vc
    @test payload.heritability ≈ 0.5
    @test payload.breeding_values.ids == ["a", "b", "c"]
    @test payload.breeding_values.values ≈ [-0.5, 0.0, 0.5]
    @test payload.fixed_effects ≈ [2.0]
    @test payload.random_effects.animal.values ≈ payload.breeding_values.values
    @test payload.loglik == likelihood.loglik
    @test payload.df == 3
    @test payload.nobs == 3
    @test payload.predictions ≈ [1.5, 2.0, 2.5]
    @test payload.diagnostics.converged == true
    @test payload.diagnostics.optimizer_status == "test"
    @test payload.diagnostics.method == :ML
    @test payload.diagnostics.dense_validation_path == true
    @test payload.converged == true
end

@testset "Phase 1 bridge payload fit target" begin
    payload_pedigree_id = ["sire", "dam", "calf"]
    payload_pedigree_sire = ["0", "0", "sire"]
    payload_pedigree_dam = ["0", "0", "dam"]
    payload_sire_index = [0, 0, 1]
    payload_dam_index = [0, 0, 2]
    payload_original_order = [1, 2, 3]
    ids = payload_pedigree_id

    ped = normalize_pedigree(payload_pedigree_id, payload_pedigree_sire, payload_pedigree_dam)
    @test ped.ids == ids
    @test ped.sire == payload_sire_index
    @test ped.dam == payload_dam_index
    @test ped.original_order == payload_original_order

    y = [1.0, 2.5, 4.0]
    X = ones(3, 1)
    Z = sparse(I, 3, 3)
    Ainv = pedigree_inverse(ped)

    @test size(Z) == (length(y), length(ids))
    @test size(Ainv) == (length(ids), length(ids))

    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :ML)
    spec_fit = fit_animal_model(spec; initial = (sigma_a2 = 0.8, sigma_e2 = 0.4))
    payload_fit = fit_animal_model(
        y,
        X,
        Z,
        Ainv;
        ids = ped.ids,
        method = :ML,
        initial = (sigma_a2 = 0.8, sigma_e2 = 0.4),
    )

    @test payload_fit isa AnimalModelFit
    @test payload_fit.spec.ids == spec.ids
    @test payload_fit.spec.method == :ML
    @test payload_fit.likelihood.loglik ≈ spec_fit.likelihood.loglik
    @test payload_fit.variance_components.sigma_a2 ≈ spec_fit.variance_components.sigma_a2
    @test payload_fit.variance_components.sigma_e2 ≈ spec_fit.variance_components.sigma_e2
    @test breeding_values(payload_fit).ids == ped.ids

    @test_throws ArgumentError fit_animal_model(y[1:2], X, Z, Ainv; ids = ped.ids)
    @test_throws ArgumentError fit_animal_model(y, X, Z, Ainv; ids = ["a"], method = :ML)
end

@testset "Phase 1 Henderson MME validation fixture" begin
    ids = ["founder_a", "founder_b", "animal_1", "animal_2", "animal_3"]
    ped = normalize_pedigree(
        ids,
        ["0", "0", "founder_a", "founder_a", "animal_1"],
        ["0", "0", "founder_b", "founder_b", "animal_2"],
    )
    Ainv = pedigree_inverse(ped)

    y = [3.2, 4.1, 5.4, 5.9]
    X = [
        1.0 0.0
        1.0 1.0
        1.0 0.0
        1.0 1.0
    ]
    Z = sparse(
        [1, 2, 3, 4],
        [3, 4, 5, 5],
        ones(4),
        4,
        5,
    )
    sigma_a2 = 1.2
    sigma_e2 = 0.8

    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :ML)
    likelihood = gaussian_loglik(spec, sigma_a2, sigma_e2; method = :ML)
    fit = AnimalModelFit(
        spec,
        likelihood,
        (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2),
        true,
        "mme_fixture",
        0,
    )

    expected_beta, expected_u = _solve_mme_for_test(y, X, Z, Ainv, sigma_a2, sigma_e2)

    @test fixed_effects(fit) ≈ expected_beta
    @test breeding_values(fit).ids == ped.ids
    @test breeding_values(fit).values ≈ expected_u
    @test fitted_values(fit) ≈ vec(Matrix(X) * expected_beta + Matrix(Z) * expected_u)
    @test heritability(fit) ≈ sigma_a2 / (sigma_a2 + sigma_e2)

    expected_pev = diag(_mme_inverse_random_block_for_test(X, Z, Ainv, sigma_a2, sigma_e2))
    relationship = inv(Symmetric(Matrix(Ainv)))
    expected_reliability = 1 .- expected_pev ./ (sigma_a2 .* diag(relationship))

    @test prediction_error_variance(fit).ids == ped.ids
    @test prediction_error_variance(fit).values ≈ expected_pev
    @test reliability(fit).ids == ped.ids
    @test reliability(fit).values ≈ expected_reliability
end
